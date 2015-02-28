require 'mysql'
require 'json'

def get_station_icons
    connection = Mysql::new(ENV['HOST'],ENV['USER'],ENV['DBPASS'],ENV['DBNAME'])
    connection.charset = 'utf8'
	line_list = [20,30,40,45,50,70,80,90,110,130]
    icon_list = []
    line_list.each do |line_id|
	statement = connection.prepare("
		SELECT latlngtable.lat,
			   latlngtable.lng,
			   metro_station_table.station_icon_name,
			   metro_station_table.station_name,
			   line_table.line_name_ja,
			   latlngtable.line_id,
			   station_table.station_url
		From line_table
		INNER JOIN latlngtable on line_table.line_id = latlngtable.line_id
        INNER JOIN station_table on latlngtable.station = station_table.station_id
        INNER JOIN metro_station_table on station_table.station_name = metro_station_table.station_name
        Where metro_station_table.line_id = ? AND latlngtable.line_id = ?;
        ")

        statement.execute(line_id,line_id).each do |icon_data|
          icon_list << icon_data
        end
     end
     connection.close
     icon_list
end

#puts get_station_icons

#f = open("train_icon.txt","w")
#f.puts(get_station_icons.to_json)
#f.close
