require 'mysql'

def getlatlngs111(line_id)
  connection = Mysql::new(ENV['HOST'], ENV['USER'], ENV['DBPASS'], ENV['DBNAME'])
  connection.charset = 'utf8'
  statement = connection.prepare("SELECT lat, lng From latlngtable WHERE line_id = ? ORDER BY latlng_number")
  latlngs = []
  statement.execute(line_id).each do |latlng|
    latlngs << [latlng[0], latlng[1]]
  end
  connection.close()
  return latlngs
end
