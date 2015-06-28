require 'sinatra'
require 'sinatra/reloader' if development?
set :server, 'webrick' if development?#開発環境のみ？httprequestとメソッド名が競合するっぽい？
require 'json'

require './get_station_icons'
require './getlatlngs'
require './send_json'
require './gettrain_inf'

require 'rack/env' if development?
use Rack::Env unless ENV['RACK_ENV'] == 'production'

get '/' do
  erb :index
end

get '/getlatlngs/:line_id' do
  content_type :json
  getlatlngs111(params[:line_id].to_i).to_json
end

get '/sendjson' do
#  return "train data is empty".to_json
  p 0
  trains = sendjson()
  return trains.to_json if trains == "train data is empty"
  i = 0
  while trains == []
    trains =sendjson()
    i += 1;
  end
  p i
  trains
end

get '/gettraininf' do
  p 0
  trains = get_trainlocation()
  return trains.to_json if trains == "train data is empty"
  i = 0
  while trains == []
    trains = get_trainlocation()
    i += 1;
  end
  p i
  trains.to_json
end

get '/gettraininf/:line_id' do
  trains = get_trainlocation(params[:line_id].to_i)
  i = 0
  while trains == []
    trains = get_trainlocation(params[:line_id].to_i)
    i += 1;
  end
  p "#{params[:line_id]}:#{i}"
  trains.to_json
end

get '/getstationicons' do
  get_station_icons.to_json
end
