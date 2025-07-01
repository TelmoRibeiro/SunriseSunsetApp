require 'sinatra'               # lightweight server
require 'sinatra/activerecord'  # classes as relational records -- @ telmo - cool, figured there could be something like this but did not expected it to be so defined
require 'sinatra/cross_origin'  # enables communication between different ports
require 'json'                  # json handler
require 'date'                  # date handler
require 'httparty'              # https requests handler -- @ telmo - was expecting something more formal...

require './models/record'       # load the ActiveRecord class

require 'cgi'                   # .escape safely transforms 'strings' into 'URL elements'

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
 
  parameters_instantiated(location, start_date, end_date)

  start_date, end_date = parsed_dates(start_date, end_date)

  records = []

  # @ telmo - ranges through dates (inclusive) in an elegant manner...
  # @ telmo - also do |date| ... is essentially date => ... i.e., nameless functions with parameters 
  (start_date..end_date).each do |date|
    record = SunsetSunriseRecords.find_by(location: location.downcase, date: date)

    unless record
      latitude, longitude = lookup_coordinates(location)

      data = lookup_sunrise_sunset(latitude, longitude, date)

      # @ telmo - literal strings are not implicitly casted as symbols, though that maybe it could...
      if data["sunrise"] && data["sunset"] && data["golden_hour"]
        record = SunsetSunriseRecords.create(
          location: location.downcase,
          date: date,
          sunrise: data["sunrise"],
          sunset: data["sunset"],
          golden_hour: data["golden_hour"]
        )
      else
        puts "Incomplete data for #{date}."
      end   
    end
    
    if record
      records << {
        location: record.location,
        date: record.date,
        sunrise: record.sunrise,
        sunset: record.sunset,
        golden_hour: record.golden_hour
      }
    end 
  end

  records.to_json
end

def parameters_instantiated(location, start_date, end_date)
  # @ telmo - Ruby makes sure the programmer knows the method returns a boolean by sufixing it with '?', interesting...
  missing_parameters = []
  missing_parameters << "location"   if location.nil?
  missing_parameters << "start_date" if start_date.nil?
  missing_parameters << "end_date"   if end_date.nil?
  
  # @ telmo - 'unless' is elegant but unfamiliar to me
  unless missing_parameters.empty?
    halt 400, { error: "Missing parameters: #{missing_parameters.join(', ')}" }.to_json
  end
end

def parsed_dates(start_date, end_date)  
  # @ telmo - essentially a try ... catch ... in Ruby
  begin
    parsed_start_date = Date.parse(start_date)
    parsed_end_date   = Date.parse(end_date)

    if parsed_start_date > parsed_end_date
      halt 400, { error: "start_date cannot be after end_date"}.to_json 
    end

  rescue ArgumentError
    halt 400, { error: "Unexpected date format." }.to_json
  end

  [parsed_start_date, parsed_end_date]
end

def lookup_sunrise_sunset(latitude, longitude, date)
  # DISCLAIMER - NOT THROUGHLY RESEARCHED API (assagniment is a POC)
  url = "https://api.sunrisesunset.io/json?lat=#{latitude}&lng=#{longitude}&date=#{date}"
  response = HTTParty.get(url)

  if response.code == 200 && response.parsed_response["results"]
    data = response.parsed_response["results"]
  else
    puts "sunrisesunset failed for #{latitude}@#{longitude} with code [#{response.code}]"
    {}
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
    puts "opencagedata failed for #{location} with code [#{response.code}]"
    [0, 0]
  end
end