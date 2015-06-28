require "fileutils"
require './gettrain_inf'

def rotate_traininf
#  if FileTest::directory?("tmp/traininf/filename") == false
#p "_77777777777777777777777777777777"
#    Dir::mkdir("tmp/traininf")
#    Dir::mkdir("tmp/traininf/filename")
#    p "88888888888888888888888888888888888888"
#  end
begin
  time_to_json = Time.now.strftime("%Y-%m-%d %H:%M:%S")
  connection = Mysql::new(ENV['HOST'], ENV['USER'], ENV['DBPASS'], ENV['DBNAME'])
  # connection = Mysql::new('us-cdbr-iron-east-01.cleardb.net','b0698739e99dce','1d8ff7e9','heroku_2ea8db531cf81ea')
  connection.charset="utf8"

  statement = connection.prepare("SELECT COUNT(datetime) FROM json_table");
  if statement.execute().fetch[0] > 2
    statement = connection.prepare("DELETE FROM json_table ORDER BY datetime LIMIT 1");
    statement.execute()
  end
  statement = connection.prepare("INSERT INTO json_table (json_tablecol,datetime)
  values(?, ?)")
  statement.execute(get_trainlocation.to_json,time_to_json)
#  statement.execute("train data is empty".to_json,time_to_json)
#  get_trainlocation.to_json
rescue
  connection.close()
end
#  statement = connection.prepare("SELECT json_table.json_tablecol From json_table
#  ORDER BY datetime DESC LIMIT 1")
#  p statement.execute().fetch[0]

#  filepath_to_write = 'tmp/filename_to_write.txt'
#  filepath_to_read = 'tmp/filename_to_read.txt'
#
#      time_to_json = Time.now.strftime("%Y%m%d%H%M%S")
#      json_file_name = time_to_json + '.json'
#  #    full_path_to_json = 'tmp/traininf/' + json_file_name
#    full_path_to_json = 'tmp/' + json_file_name
#
#
#      File.open(full_path_to_json, 'w') do |json|
#  p "hey! you are 4 =================================="
#  p full_path_to_json
#        json.puts(get_trainlocation)
#        #ファイル処理
#  #      filepath_to_write = 'tmp/traininf/filename/filename_to_write.txt'
#
#        File.open(filepath_to_write, 'w') do |f|
#          f.puts json_file_name
#          p json_file_name
#          sleep 2
#        end
#        FileUtils.cp(filepath_to_write, filepath_to_read)
#      end
#
#
#
#
#
#
#  p Dir.pwd
#  p Dir.glob("*")
##  Dir.chdir('tmp/traininf/filename') do |path|
#  Dir.chdir('tmp') do |path|
#    p Dir.pwd
#     p Dir.glob("*")
#    File.open('filename_to_read.txt', 'r') do |json|
#      p "hey! you are 000 =================================="
#      p json.gets
#    end
#  end
#  p "you are here ========="
##  filepath_to_write = 'tmp/traininf/filename/filename_to_write.txt'
##  filepath_to_read = 'tmp/traininf/filename/filename_to_read.txt'
#  filepath_to_write = 'tmp/filename_to_write.txt'
#  filepath_to_read = 'tmp/filename_to_read.txt'
#  begin
#    #jsonファイルが5個以上あるときは一番古いものを削除する
##    Dir.chdir('tmp/traininf') do |path|
#    Dir.chdir('tmp') do |path|
#p "hey! you are 1 =================================="
#
#      json_files = Dir.glob("*.json")
#p "json_length=#{json_files}"
#      if json_files.length >= 5
#p "hey! you are 2 =================================="
#        date_list =json_files.map do |jsonfile|
#          p "json=#{jsonfile}"
#
#p "hey! you are 3 =================================="
#          jsonfile.match(/\d*/)[0].to_i
#        end
#        File.delete(date_list.min.to_s + ".json")
#      end
#    end
#
#    #sleep 100
#
##    time_to_json = Time.now.strftime("%Y%m%d%H%M%S")
##    json_file_name = time_to_json + '.json'
###    full_path_to_json = 'tmp/traininf/' + json_file_name
##  full_path_to_json = 'tmp/' + json_file_name
#
##    File.open(full_path_to_json, 'w') do |json|
##p "hey! you are 4 =================================="
##p full_path_to_json
##      json.puts(get_trainlocation.to_json)
##      #ファイル処理
###      filepath_to_write = 'tmp/traininf/filename/filename_to_write.txt'
##
##      File.open(filepath_to_write, 'w') do |f|
##        f.puts json_file_name
##        p json_file_name
##        sleep 2
##      end
##      FileUtils.cp(filepath_to_write, filepath_to_read)
##    end
#
#  File.open(filepath_to_write, 'r') do |json|
#    p "hey! you are 5 =================================="
#    p json.gets
#  end
#  File.open(filepath_to_read, 'r') do |json|
#    p "hey! you are 6 =================================="
#    p json.gets
#  end
#
##  Dir.chdir('tmp/traininf/filename') do |path|
#  Dir.chdir('tmp') do |path|
#
#  p Dir.pwd
#     p Dir.glob("*")
#    File.open('filename_to_read.txt', 'r') do |json|
#      p "hey! you are 111 =================================="
#      p json.gets
#    end
#  end
#
#
#  rescue => exc
#    p "error@rotate_traininf"
#    p exc
#    p $@
#  end
end


module Clockwork
  handler do |job|
    rotate_traininf
  end
  every(45.seconds, 'frequent.job')
end
