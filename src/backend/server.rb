require "sinatra"               # lightweight server
require "sinatra/activerecord"  # classes as relational records
require "sinatra/cross_origin"  # enables communication between different ports
require "cgi"                   # .escape safely transforms 'strings' into 'URL elements'
require "json"                  # json handler
require "date"                  # date handler
require "httparty"              # https requests handler

require "./models/record"       # load the ActiveRecord class



configure do
  enable :cross_origin
end

ALLOWED_ORIGINS = ["http://localhost:5173"]

before do
  origin = request.env["HTTP_ORIGIN"]
  halt 404 , "CORS Forbidden" unless ALLOWED_ORIGINS.include?(origin)
  response.headers["Access-Control-Allow-Origin"] = origin
end

options "*" do
  response.headers["Access-Control-Allow-Methods"] = "GET, OPTIONS"
  200
end


set :database, {
  adapter: "sqlite3",
  database: "./db/development.sqlite3"
}



get "/sun-data" do
  content_type :json

  location   = params[:location]
  start_date = params[:start_date]
  end_date   = params[:end_date]
 
  missing_parameters(
    location:   location,
    start_date: start_date,
    end_date:   end_date
  )

  begin
    start_date = Date.parse(start_date)
    end_date   = Date.parse(end_date)

    if start_date > end_date
      halt 400, { error: "start_date cannot be after end_date"}.to_json
    end

  rescue ArgumentError
    halt 400, { error: "Unexpected date format." }.to_json
  end

  latitude, longitude = lookup_coordinates(location)

  all_dates = (start_date..end_date).to_a
  existing_records = SunDataRecord.where(latitude: latitude, longitude: longitude, date: start_date..end_date)
  existing_dates   = existing_records.pluck(:date)
  missing_dates    = (all_dates - existing_dates).sort!

  new_records = []

  unless missing_dates.empty?
    missing_records   = lookup_sunrise_sunset(latitude, longitude, missing_dates.first, missing_dates.last)
    missing_dates_set = missing_dates.to_set
  
    missing_records.each do |record|
      
      record_date = Date.parse(record["date"]) rescue nil
      next unless missing_dates_set.include?(record_date)

      missing_parameters(
        {  
          sunrise:     record["sunrise"],
          sunset:      record["sunset"],
          golden_hour: record["golden_hour"]
        },
        "SunriseSunset could not resolve the following parameters for [#{record["date"]}]"
      )

      new_record = SunDataRecord.create(
        latitude:    latitude,
        longitude:   longitude,
        location:    location,
        date:        record["date"],
        sunrise:     record["sunrise"],
        sunset:      record["sunset"],
        golden_hour: record["golden_hour"]
      )

      new_records << new_record
    end
  end

  return (existing_records + new_records).uniq { |record| record.date }.map{ |record| format_record(record) }.to_json
end

def missing_parameters(labeled_parameters, error_prefix = "Missing parameters")
  missing_parameters = []

  labeled_parameters.each do |label, parameter|
    missing_parameters << label if parameter.nil? || parameter.to_s.strip.empty?
  end

  unless missing_parameters.empty?
    halt 400, { error: "#{error_prefix}: #{missing_parameters.join(', ')}" }.to_json
  end
end

def format_record(record)
  {
    latitude:    record.latitude,
    longitude:   record.longitude,
    location:    record.location,
    date:        record.date,
    sunrise:     record.sunrise.strftime("%I:%M:%S %p"),
    sunset:      record.sunset.strftime("%I:%M:%S %p"),
    golden_hour: record.golden_hour.strftime("%I:%M:%S %p")
  }
end  

def lookup_coordinates(location)
  # DISCLAIMER - NOT THROUGHLY RESEARCHED API (assignment is a POC) 
  api_key = "96a02029caad4082a2f7d9239ad7712e" # this would not be safe outside of a POC
  url = "https://api.opencagedata.com/geocode/v1/json?q=#{CGI.escape(location)}&key=#{api_key}&limit=1"
  response = HTTParty.get(url)

  if response.code == 200 && response.parsed_response["results"]&.any?
    geometry = response.parsed_response["results"][0]["geometry"]
    return [geometry["lat"], geometry["lng"]]
  else
    halt 400, { error: "OpenCageData could not resolve the coordinates for [#{location}]" }.to_json
  end
end

def lookup_sunrise_sunset(latitude, longitude, start_date, end_date)
  # DISCLAIMER - NOT THROUGHLY RESEARCHED API (assignment is a POC)
  url = "https://api.sunrisesunset.io/json?lat=#{latitude}&lng=#{longitude}&date_start=#{start_date}&date_end=#{end_date}"
  response = HTTParty.get(url)

  if response.code == 200 && response.parsed_response["results"]&.any?
    return response.parsed_response["results"]
  else
    halt 400, { error: "SunriseSunset could not resolve the times for [#{latitude}@#{longitude}]" }.to_json
  end
end