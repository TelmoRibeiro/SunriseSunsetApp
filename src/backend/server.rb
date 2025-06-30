require 'sinatra'
require 'sinatra/activerecord'
require 'json'
require './models/record'
# @ telmo - `require` works like the standard `import`

set :database, {
  adapter: "sqlite3",
  database: "./database/sunrise.sqlite3"
}

get '/' do
  content_type :json
  { message: "Hello World!" }.to_json
end

get '/hello' do
  content_type :json
  { message: "Hello Back!" }.to_json
end

get '/helloself' do
  name = params[:name] || "stranger"
  content_type :json
  { message: "Hello #{name}!" }.to_json
end

# @ telmo - get $Path where $Path is the path for the request
# @ telmo - apprantely, keeping the various requests isolated is more sinatra-idiomatic