require 'mysql'
require 'dotenv'
Dotenv.load


def sendjson
#return  "train data is empty"
#target_file = nil
begin

  connection = Mysql::new(ENV['HOST'], ENV['USER'], ENV['DBPASS'], ENV['DBNAME'])
  # connection = Mysql::new('us-cdbr-iron-east-01.cleardb.net','b0698739e99dce','1d8ff7e9','heroku_2ea8db531cf81ea')
  connection.charset="utf8"

  statement = connection.prepare("SELECT json_table.json_tablecol From json_table
  ORDER BY datetime DESC LIMIT 1")
  json_data = statement.execute().fetch[0]
rescue
  connection.close()
end
 return json_data
#return "train data is empty"
#Dir.chdir('tmp') do |path|
#  sample = Dir.glob("*")
#  json_files = Dir.glob("*.json")
##p "json_length=#{json_files}"
#p "========================heyx! you are sendjson =================================="
#p "aaaaaaaaaaa#{sample}"
#    date_list =json_files.map do |jsonfile|
#      date_list.max.to_s + ".json"
#      p "json=#{jsonfile}"
#      target_file =date_list.max.to_s + ".json"
#  end
#end
#
#File.open("tmp/"+target_file,"r") do |f|
#  return f.read
#end

end
