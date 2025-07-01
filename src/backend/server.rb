require 'sinatra'               # lightweight server
require 'sinatra/activerecord'  # classes as relational records
require 'sinatra/cross_origin'  # enables communication between different ports
require 'cgi'                   # .escape safely transforms 'strings' into 'URL elements'
require 'json'                  # json handler
require 'date'                  # date handler
require 'httparty'              # https requests handler

require './models/record'       # load the ActiveRecord class



configure do
  enable :cross_origin
end

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

options "*" do
  response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "Content-Type"
  200
end


set :database, {
  adapter: "sqlite3",
  database: "./db/sunrise.sqlite3"
}


get '/sun-data' do
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

  records = []
 
  (start_date..end_date).each do |date|
    record = SunsetSunriseRecords.find_by(location: location.downcase, date: date)

    unless record
      latitude, longitude = lookup_coordinates(location)

      data = lookup_sunrise_sunset(latitude, longitude, date)

      missing_parameters(
        {  
          sunrise: data["sunrise"],
          sunset:  data["sunset"],
          golden_hour: data["golden_hour"]
        },
        "SunriseSunset could not resolve the following parameteres"
      )

      record = SunsetSunriseRecords.create(
        location: location.downcase,
        date: date,
        sunrise: data["sunrise"],
        sunset: data["sunset"],
        golden_hour: data["golden_hour"]
      )
    end
  
    records << record
  end

  records.to_json
end

def missing_parameters(labeled_parameters, error_prefix = "Missing parameters")
  missing_parameters = []

  labeled_parameters.each do |label, parameter|
    missing_parameters << label if parameter.nil? || parameter.strip.empty?
  end

  unless missing_parameters.empty?
    halt 400, { error: "#{error_prefix}: #{missing_parameters.join(', ')}" }.to_json
  end
end

def lookup_sunrise_sunset(latitude, longitude, date)
  # DISCLAIMER - NOT THROUGHLY RESEARCHED API (assagniment is a POC)
  url = "https://api.sunrisesunset.io/json?lat=#{latitude}&lng=#{longitude}&date=#{date}"
  response = HTTParty.get(url)

  if response.code == 200 && response.parsed_response["results"]&.any?
    data = response.parsed_response["results"]
  else
    halt 400, { error: "SunriseSunset could not resolve the times for [#{latitude}@#{longitude}]" }.to_json
  end
end

def lookup_coordinates(location)
  # DISCLAIMER - NOT THROUGHLY RESEARCHED API (assagniment is a POC) 
  api_key = "96a02029caad4082a2f7d9239ad7712e" # this would not be safe outside of a POC
  url = "https://api.opencagedata.com/geocode/v1/json?q=#{CGI.escape(location)}&key=#{api_key}&limit=1"
  response = HTTParty.get(url)

  if response.code == 200 && response.parsed_response["results"]&.any?
    geometry = response.parsed_response["results"][0]["geometry"]
    [geometry["lat"], geometry["lng"]]
  else
    halt 400, { error: "OpenCageData could not resolve the coordinates for [#{location}]" }.to_json
  end
end