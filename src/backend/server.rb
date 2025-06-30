require 'sinatra'               # lightweight server
require 'sinatra/activerecord'  # classes as relational records -- @ telmo - cool, figured there could be something like this but did not expected it to be so defined
require 'json'                  # json handler
require 'date'                  # date handler
require 'httparty'              # https requests handler -- @ telmo - was expecting something more formal...

require './models/record'       # load the ActiveRecord class

set :database, {
  adapter: "sqlite3",
  database: "./db/sunrise.sqlite3"
}

get '/sun-data' do
  content_type :json

  location   = params[:location]
  start_date = params[:start_date]
  end_date   = params[:end_date]
 
  # @ telmo - Ruby makes sure the programmer knows the method returns a boolean by sufixing it with '?', interesting...
  missing_parameters = []
  missing_parameters << "location"   if location.nil?
  missing_parameters << "start_date" if start_date.nil?
  missing_parameters << "end_date"   if end_date.nil?
  
  # @ telmo - 'unless' is elegant but unfamiliar to me
  unless missing_parameters.empty?
    status 400
    return { error: "Missing parameters: #{missing_parameters.join(', ')}" }.to_json
  end

  # @ telmo - essentially a try ... catch ... in Ruby
  begin
    start_date = Date.parse(start_date)
    end_date   = Date.parse(end_date)
    
    if start_date > end_date
      status 400
      return { error: "start_date cannot be after end_date"}.to_json 
    end
  rescue ArgumentError
    status 400
    return { error: "Unexpected date format." }.to_json
  end

  records = []

  # @ telmo - ranges through dates (inclusive) in an elegant manner...
  # @ telmo - also do |date| ... is essentially date => ... i.e., nameless functions with parameters 
  (start_date..end_date).each do |date|
    record = Record.find_by(location: location, date: date)

    unless record
      latitude, longitude = lookup_coordinates(location)

      # @ telmo - API seems to be working good enough
      url = "https://api.sunrisesunset.io/json?lat=#{latitude}&lng=#{longitude}&date=#{date}"
      response = HTTParty.get(url)

      if response.code == 200 && response.parsed_response["results"]
        data = response.parsed_response["results"]
        
        # @ telmo - literal strings are not implicitly casted as symbols, though that maybe it could...
        record = Record.create(
          location: location,
          date: date,
          sunrise: data["sunrise"],
          sunset: data["sunset"],
          golden_hour: data["golden_hour"]
        )
      else
        next # @ telmo - unfold this into a proper exception
      end
    end
    
    records << {
      location: record.location,
      date: record.date,
      sunrise: record.sunrise,
      sunset: record.sunset,
      golden_hour: record.golden_hour
    }
  end

  results.to_json
end

# @ telmo - swap this for a proper API
def lookup_coordinates(location)
  case location.downcase
  when "lisbon"
    [38.7169, -9.1399]
  when "berlin"
    [52.52, 13.405]
  else
    [0, 0]
  end
end