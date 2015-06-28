require 'mysql'
require 'httpclient'
require 'json'
require 'dotenv'
Dotenv.load
# require 'rack/env'
# use Rack::Env unless ENV['RACK_ENV'] == 'production'

#メトロのロケーション情報を受け取って、odpt:railway、odpt:railDirection、odpt:delay、odpt:startingStation、odpt:terminalStation
#odpt:fromStation、odpt:toStationのハッシュの配列を返す。
def get_trainlocation
  m_metro_station_name ||= {}
  count = 0

  #変換リスト(暫定)
  line_id_h ={30 => "odpt.Railway:TokyoMetro.Ginza",
    40 => "odpt.Railway:TokyoMetro.Marunouchi",
    45 =>  "odpt.Railway:TokyoMetro.MarunouchiBranch",
    20 => "odpt.Railway:TokyoMetro.Hibiya",
    50 => "odpt.Railway:TokyoMetro.Tozai",
    90 => "odpt.Railway:TokyoMetro.Chiyoda",
    80 => "odpt.Railway:TokyoMetro.Yurakucho",
    110 => "odpt.Railway:TokyoMetro.Hanzomon",
    70 => "odpt.Railway:TokyoMetro.Namboku",
    130 => "odpt.Railway:TokyoMetro.Fukutoshin"
  }

  line_h = {"odpt.Railway:TokyoMetro.Ginza" => 30,
    "odpt.Railway:TokyoMetro.Marunouchi" => 40,
    "odpt.Railway:TokyoMetro.MarunouchiBranch" => 45,
    "odpt.Railway:TokyoMetro.Hibiya" => 20,
    "odpt.Railway:TokyoMetro.Tozai" => 50,
    "odpt.Railway:TokyoMetro.Chiyoda" => 90,
    "odpt.Railway:TokyoMetro.Yurakucho" => 80,
    "odpt.Railway:TokyoMetro.Hanzomon" => 110,
    "odpt.Railway:TokyoMetro.Namboku" => 70,
    "odpt.Railway:TokyoMetro.Fukutoshin" => 130
  }

  connection = Mysql::new(ENV['HOST'], ENV['USER'], ENV['DBPASS'], ENV['DBNAME'])
  connection.charset = 'utf8'
  http_client = HTTPClient.new
  response = http_client.get ENV['DATAPOINTS_URL'],
  { "rdf:type"=>"odpt:Train",
    "acl:consumerKey"=>ENV['ACCESS_TOKEN'] }

  http_client2 = HTTPClient.new
  response2 = http_client2.get ENV['DATAPOINTS_URL'],
  { "rdf:type"=>"odpt:Railway",
    "acl:consumerKey"=>ENV['ACCESS_TOKEN'] }
  metrolocation = []

  return "train data is empty" if response.body == "[]"

  if response.body == "Your request rate is too high"
    sleep 0.1
    get_trainlocation
  elsif response2.body == "Your request rate is too high"
    sleep 0.1
    get_trainlocation
  else

  JSON.parse(response.body).each do |data|
    begin
      startingStation_line_id_list = []
      terminalStation_line_id_list = []
      if data["odpt:railway"] =~ /Marunouchi/
        statement = connection.prepare("SELECT latlngtable.line_id From latlngtable
          INNER JOIN station_table on latlngtable.station = station_table.station_id
          INNER JOIN metro_station_table on station_table.station_name = metro_station_table.station_name
          WHERE metro_station_table.metro_station_name = ?")
        statement.execute(data["odpt:startingStation"]).each do |s|
          startingStation_line_id_list << s[0]
        end

        statement = connection.prepare("SELECT latlngtable.line_id From latlngtable
          INNER JOIN station_table on latlngtable.station = station_table.station_id
          INNER JOIN metro_station_table on station_table.station_name = metro_station_table.station_name
          WHERE metro_station_table.metro_station_name = ?")
        statement.execute(data["odpt:terminalStation"]).each do |s|
          terminalStation_line_id_list << s[0]
        end
      end

      tmp_h = {}
      tmp_h["dc:date"] = data["dc:date"]
      tmp_h["@id"] = data["@id"].scan(/_.*/)
      tmp_h["dpt:railway"] = data["odpt:railway"]
      tmp_h["odpt:railDirection"] = data["odpt:railDirection"]
      tmp_h["odpt:startingStation"] = data["odpt:startingStation"]
      tmp_h["odpt:terminalStation"] = data["odpt:terminalStation"]
      tmp_h["odpt:fromStation"] = data["odpt:fromStation"]
      tmp_h["odpt:toStation"] = data["odpt:toStation"]
      tmp_h["line"] = line_h[data["odpt:railway"]]
      tmp_h["odpt:delay"] = data["odpt:delay"]
      tmp_h["odpt:trainType"] = data["odpt:trainType"]


      if startingStation_line_id_list.include?(40) && terminalStation_line_id_list.include?(40)
        tmp_h["line"] = 40
      elsif startingStation_line_id_list.include?(45) && terminalStation_line_id_list.include?(45)
        tmp_h["line"] = 45
      elsif startingStation_line_id_list.include?(46) && terminalStation_line_id_list.include?(46)
        tmp_h["line"] = 46
      elsif startingStation_line_id_list.include?(47) && terminalStation_line_id_list.include?(47)
        tmp_h["line"] = 47
      end

      statement = connection.prepare("SELECT raildirection_ja,direction From raildirection_table
        WHERE raildirection = ? AND line_id = ?")
      tmp_direction_inf = statement.execute(tmp_h["odpt:railDirection"],tmp_h["line"]).fetch
      tmp_h["railDirection4display"] = tmp_direction_inf[0].encode("UTF-8")
      tmp_h["direction"] = tmp_direction_inf[1]

      #北綾瀬→綾瀬行き専用
      tmp_h["direction"] = "backward" if (tmp_h["line"] == 90 && data["odpt:startingStation"] == "odpt.Station:TokyoMetro.Chiyoda.Ayase")

      #池袋→中野坂上専用
      tmp_h["direction"] = "backward" if (tmp_h["line"] == 40) && (data["odpt:startingStation"] == "odpt.Station:TokyoMetro.Marunouchi.Ikebukuro") && (tmp_h["odpt:railDirection"] == "odpt.RailDirection:TokyoMetro.NakanoSakaue")

      #荻窪→中野坂上専用
      tmp_h["direction"] = "forward" if (tmp_h["line"] == 40) && (data["odpt:startingStation"] == "odpt.Station:TokyoMetro.Marunouchi.Ogikubo") && (tmp_h["odpt:railDirection"] == "odpt.RailDirection:TokyoMetro.NakanoSakaue")

      JSON.parse(response2.body).each do |data2|
        if data2["owl:sameAs"] =~ /Marunouchi/
          case data["odpt:fromStation"]
          #data2は本線と支線で2つの駅間テーブルを持っているのでここで選別するdataのrailwayでは支線を指定できないため。
          when /.*NakanoSakaue/
            tmp_h["odpt:railDirection"] == "odpt.RailDirection:TokyoMetro.NakanoSakaue"
            if (tmp_h["odpt:railDirection"] =~ /Honancho/)
              if (data2["owl:sameAs"] =~ /\.MarunouchiBranch$/)
              else
                next
              end
            elsif (data2["owl:sameAs"] =~ /\.Marunouchi$/)
            else
              next
            end
          when /\.Marunouchi\./
            if data2["owl:sameAs"] =~ /\.Marunouchi$/
            else
              next
            end
          when /\.MarunouchiBranch\./
            if (data2["owl:sameAs"] =~ /\.MarunouchiBranch$/)
            else
              next
            end
          else #whenのelse
            next
          end
        else #129Lのelse
          if data2["owl:sameAs"] != line_id_h[line_h[data["odpt:railway"]]]
            next
          end
        end

        statement = connection.prepare("SELECT t1.station_name,t2.station_name From metro_station_table AS t1
          INNER JOIN metro_station_table AS t2 WHERE t1.metro_station_name = ? AND t2.metro_station_name = ? AND t1.line_id = ?")
        tmp_toStn_list = statement.execute(tmp_h["odpt:fromStation"],tmp_h["odpt:fromStation"],tmp_h["line"])

        if (m_metro_station_name[tmp_h["odpt:fromStation"]] == nil) || (m_metro_station_name[tmp_h["odpt:terminalStation"]] == nil)
          tmp_toStn_list = statement.execute(tmp_h["odpt:fromStation"],tmp_h["odpt:terminalStation"],tmp_h["line"]).fetch
          tmp_h["fromStation4display"] = tmp_toStn_list[0]
          m_metro_station_name[tmp_h["odpt:fromStation"]] = tmp_h["fromStation4display"]
          tmp_h["terminalStation4display"] = tmp_toStn_list[1]
          m_metro_station_name[tmp_h["odpt:terminalStation"]] = tmp_h["terminalStation4display"]
        else
          tmp_h["fromStation4display"] = m_metro_station_name[tmp_h["odpt:fromStation"]]
          tmp_h["terminalStation4display"] = m_metro_station_name[tmp_h["odpt:terminalStation"]]
        end

        #中間地点までの分岐
        if data["odpt:toStation"] == nil
          if tmp_h["line"] == 50 || tmp_h["line"] == 130
            if (tmp_h["odpt:trainType"] == "odpt.TrainType:TokyoMetro.CommuterRapid") || (tmp_h["odpt:trainType"] == "odpt.TrainType:TokyoMetro.CommuterExpress")
            #通勤急行の場合
              if tmp_h["direction"] == "forward"
                statement = connection.prepare("SELECT t1.next_metro_station_name_at_commute_express,t2.station_name From metro_station_table AS t1
                  INNER JOIN metro_station_table AS t2 on t1.next_metro_station_name_at_commute_express = t2.metro_station_name
                  WHERE t1.metro_station_name = ? AND t1.line_id = ?")
              else
                statement = connection.prepare("SELECT t1.previous_metro_station_name_at_commute_express,t2.station_name From metro_station_table AS t1
                  INNER JOIN metro_station_table AS t2 on t1.previous_metro_station_name_at_commute_express = t2.metro_station_name
                  WHERE t1.metro_station_name = ? AND t1.line_id = ?")
              end
              tmp_odpt_to_station = statement.execute(tmp_h["odpt:fromStation"],tmp_h["line"]).fetch
              tmp_h["odpt:toStation"] = tmp_odpt_to_station[0]
              tmp_h["toStation4display"] = tmp_odpt_to_station[1]
            elsif (tmp_h["odpt:trainType"] == "odpt.TrainType:TokyoMetro.Rapid") || (tmp_h["odpt:trainType"] == "odpt.TrainType:TokyoMetro.Express")
            #快速の場合
              if tmp_h["direction"] == "forward"
                statement = connection.prepare("SELECT t1.next_metro_station_name_at_express,t2.station_name From metro_station_table AS t1
                  INNER JOIN metro_station_table AS t2 on t1.next_metro_station_name_at_express = t2.metro_station_name
                  WHERE t1.metro_station_name = ? AND t1.line_id = ?")
              else
                statement = connection.prepare("SELECT t1.previous_metro_station_name_at_express,t2.station_name From metro_station_table AS t1
                  INNER JOIN metro_station_table AS t2 on t1.previous_metro_station_name_at_express = t2.metro_station_name
                  WHERE t1.metro_station_name = ? AND t1.line_id = ?")
              end
              tmp_odpt_to_station = statement.execute(tmp_h["odpt:fromStation"],tmp_h["line"]).fetch
              tmp_h["odpt:toStation"] = tmp_odpt_to_station[0]
              tmp_h["toStation4display"] = tmp_odpt_to_station[1]
            elsif (tmp_h["odpt:trainType"] == "odpt.TrainType:TokyoMetro.HolidayExpress")
            #土休急行の場合
              if tmp_h["direction"] == "forward"
                statement = connection.prepare("SELECT t1.next_metro_station_name_at_express_on_weekend,t2.station_name From metro_station_table AS t1
                  INNER JOIN metro_station_table AS t2 on t1.next_metro_station_name_at_express_on_weekend = t2.metro_station_name
                  WHERE t1.metro_station_name = ? AND t1.line_id = ?")
              else
                statement = connection.prepare("SELECT t1.previous_metro_station_name_at_express_on_weekend,t2.station_name From metro_station_table AS t1
                  INNER JOIN metro_station_table AS t2 on t1.previous_metro_station_name_at_express_on_weekend = t2.metro_station_name
                  WHERE t1.metro_station_name = ? AND t1.line_id = ?")
              end
              tmp_odpt_to_station = statement.execute(tmp_h["odpt:fromStation"],tmp_h["line"]).fetch
              tmp_h["odpt:toStation"] = tmp_odpt_to_station[0]
              tmp_h["toStation4display"] = tmp_odpt_to_station[1]
            else
            #各駅停車の場合
              if tmp_h["direction"] == "forward"
                statement = connection.prepare("SELECT t1.next_metro_station_name_at_local,t2.station_name From metro_station_table AS t1
                  INNER JOIN metro_station_table AS t2 on t1.next_metro_station_name_at_local = t2.metro_station_name
                  WHERE t1.metro_station_name = ? AND t1.line_id = ?")
              else
                statement = connection.prepare("SELECT t1.previous_metro_station_name_at_local,t2.station_name From metro_station_table AS t1
                  INNER JOIN metro_station_table AS t2 on t1.previous_metro_station_name_at_local = t2.metro_station_name
                  WHERE t1.metro_station_name = ? AND t1.line_id = ?")
              end
              tmp_odpt_to_station = statement.execute(tmp_h["odpt:fromStation"],tmp_h["line"]).fetch
              tmp_h["odpt:toStation"] = tmp_odpt_to_station[0]
              tmp_h["toStation4display"] = tmp_odpt_to_station[1]
            end
          else #179Lへのelse(東西と副都心以外は全部各駅停車)
          #東西線と副都心線以外の場合
            if tmp_h["direction"] == "forward"
              statement = connection.prepare("SELECT t1.next_metro_station_name_at_local,t2.station_name From metro_station_table AS t1
                INNER JOIN metro_station_table AS t2 on t1.next_metro_station_name_at_local = t2.metro_station_name
                WHERE t1.metro_station_name = ? AND t1.line_id = ?")
            else
              statement = connection.prepare("SELECT t1.previous_metro_station_name_at_local,t2.station_name From metro_station_table AS t1
                INNER JOIN metro_station_table AS t2 on t1.previous_metro_station_name_at_local = t2.metro_station_name
                WHERE t1.metro_station_name = ? AND t1.line_id = ?")
            end
            tmp_odpt_to_station = statement.execute(tmp_h["odpt:fromStation"],tmp_h["line"]).fetch
            tmp_h["odpt:toStation"] = tmp_odpt_to_station[0]
            tmp_h["toStation4display"] = tmp_odpt_to_station[1]
          end
          statement = connection.prepare("SELECT latlngtable.distance,latlngtable.latlng_number From latlngtable
            INNER JOIN station_table on latlngtable.station = station_table.station_id
            INNER JOIN metro_station_table on station_table.station_name = metro_station_table.station_name
            WHERE latlngtable.line_id = ? AND metro_station_table.metro_station_name = ?")
          tmp_offset_coordinate =  statement.execute(tmp_h["line"],tmp_h["odpt:fromStation"]).fetch
          offset_list = tmp_offset_coordinate[0]
          coordinate = tmp_offset_coordinate[1]-1

          data2["odpt:travelTime"].each do |h|
            if h["odpt:fromStation"] =~ /NakanoSakaue/ && tmp_h["odpt:fromStation"] =~ /NakanoSakaue/
              if h["odpt:toStation"] == tmp_h["odpt:toStation"]
                tmp_h["travelTime"] = h["odpt:necessaryTime"]
                break
              end
            end

            if h["odpt:toStation"] =~ /NakanoSakaue/ && tmp_h["odpt:toStation"] =~ /NakanoSakaue/
              if h["odpt:fromStation"] == tmp_h["odpt:fromStation"]
                tmp_h["travelTime"] = h["odpt:necessaryTime"]
                break
              end
            end

            if tmp_h["odpt:trainType"] != "odpt.TrainType:TokyoMetro.HolidayExpress"
              if tmp_h["odpt:fromStation"] == "odpt.Station:TokyoMetro.Fukutoshin.Shibuya" && tmp_h["odpt:toStation"] == "odpt.Station:TokyoMetro.Fukutoshin.Ikebukuro"
                tmp_h["travelTime"] = 5
                break
              end

              if tmp_h["odpt:fromStation"] == "odpt.Station:TokyoMetro.Fukutoshin.Ikebukuro" && tmp_h["odpt:toStation"] == "odpt.Station:TokyoMetro.Fukutoshin.Shibuya"
                tmp_h["travelTime"] = 5
                break
              end
            end

            if (h["odpt:fromStation"] == tmp_h["odpt:fromStation"]) && (h["odpt:toStation"] == tmp_h["odpt:toStation"])
              tmp_h["travelTime"] = h["odpt:necessaryTime"]
              break
            end
          end #262Lのdata2.eachに対するend

          if tmp_h["direction"] == "forward"
            statement = connection.prepare("SELECT latlngtable.distance From latlngtable
              INNER JOIN station_table on latlngtable.station = station_table.station_id
              INNER JOIN metro_station_table on station_table.station_name = metro_station_table.station_name
              WHERE latlngtable.line_id = ? AND metro_station_table.metro_station_name = ?")
          elsif tmp_h["direction"] == "backward"
            statement = connection.prepare("SELECT latlngtable.distance_reverse From latlngtable
              INNER JOIN station_table on latlngtable.station = station_table.station_id
              INNER JOIN metro_station_table on station_table.station_name = metro_station_table.station_name
              WHERE latlngtable.line_id = ? AND metro_station_table.metro_station_name = ?")
          end
          from_stn_dist = statement.execute(tmp_h["line"],tmp_h["odpt:fromStation"]).fetch[0]

          if tmp_h["direction"] == "forward"
            statement = connection.prepare("SELECT latlngtable.distance From latlngtable
              INNER JOIN station_table on latlngtable.station = station_table.station_id
              INNER JOIN metro_station_table on station_table.station_name = metro_station_table.station_name
              WHERE latlngtable.line_id = ? AND metro_station_table.metro_station_name = ?")
          elsif tmp_h["direction"] == "backward"
            statement = connection.prepare("SELECT latlngtable.distance_reverse From latlngtable
              INNER JOIN station_table on latlngtable.station = station_table.station_id
              INNER JOIN metro_station_table on station_table.station_name = metro_station_table.station_name
              WHERE latlngtable.line_id = ? AND metro_station_table.metro_station_name = ?")
          end
          tmp_to_stn_dist = statement.execute(tmp_h["line"],tmp_h["odpt:toStation"]).fetch
            if tmp_to_stn_dist != nil
              to_stn_dist = tmp_to_stn_dist[0]
            else
              to_stn_dist = statement.execute(tmp_h["line"],tmp_h["odpt:fromStation"]).fetch[0]
            end

            statement = connection.prepare("SELECT MAX(distance) FROM latlngtable
              WHERE latlngtable.line_id = ?")
            last_stn_dist = statement.execute(tmp_h["line"]).fetch[0]

            if  to_stn_dist-from_stn_dist == 0
              tmp_h["totalTraveltime"] = 0
            else
              tmp_speed = (to_stn_dist-from_stn_dist)/tmp_h["travelTime"]
              tmp_h["totalTraveltime"] =  (last_stn_dist-to_stn_dist) / tmp_speed
            end

            statement = connection.prepare("SELECT station_name From metro_station_table
              WHERE metro_station_name = ?")

            tmp_h["odpt:toStation"] = nil
        else #177Lのif文へのelse
        #中間地点？
          statement = connection.prepare("SELECT metro_station_table.station_name From metro_station_table
            WHERE metro_station_table.metro_station_name = ?")
          if m_metro_station_name[tmp_h["odpt:toStation"]] == nil
            tmp_h["toStation4display"] = statement.execute(tmp_h["odpt:toStation"]).fetch[0].encode("UTF-8")
            m_metro_station_name[tmp_h["odpt:toStation"]] = tmp_h["toStation4display"]
          else
            tmp_h["toStation4display"] = m_metro_station_name[tmp_h["odpt:toStation"]]
          end

          statement = connection.prepare("SELECT DISTINCT latlngtable.latlng_number From latlngtable
            INNER JOIN station_table on latlngtable.station = station_table.station_id
            INNER JOIN metro_station_table on station_table.station_name = metro_station_table.station_name
            WHERE latlngtable.line_id = ? AND (metro_station_table.metro_station_name = ?
            OR metro_station_table.metro_station_name = ?);")
          tmp_middle_latlngnumber = 0
          statement.execute(tmp_h["line"],tmp_h["odpt:fromStation"],tmp_h["odpt:toStation"]).each do |s|
            tmp_middle_latlngnumber += s[0].to_f
          end
          middle_latlngnumber =(tmp_middle_latlngnumber/2).to_i

          statement = connection.prepare("SELECT distance From latlngtable
            WHERE line_id = ? AND latlng_number = ?")
          offset_list = statement.execute(tmp_h["line"],middle_latlngnumber).fetch[0]
          coordinate = middle_latlngnumber-1

          data2["odpt:travelTime"].each do |h|
            if h["odpt:fromStation"] =~ /NakanoSakaue/ && tmp_h["odpt:fromStation"] =~ /NakanoSakaue/
              if h["odpt:toStation"] == tmp_h["odpt:toStation"]
                tmp_h["travelTime"] = h["odpt:necessaryTime"]
                break
              end
            end

            if h["odpt:toStation"] =~ /NakanoSakaue/ && tmp_h["odpt:toStation"] =~ /NakanoSakaue/
              if h["odpt:fromStation"] == tmp_h["odpt:fromStation"]
                tmp_h["travelTime"] = h["odpt:necessaryTime"]
                break
              end
            end

            if tmp_h["odpt:trainType"] != "odpt.TrainType:TokyoMetro.HolidayExpress"
              if tmp_h["odpt:fromStation"] == "odpt.Station:TokyoMetro.Fukutoshin.Shibuya" && tmp_h["odpt:toStation"] == "odpt.Station:TokyoMetro.Fukutoshin.Ikebukuro"
                tmp_h["travelTime"] = 5
                break
              end

              if tmp_h["odpt:fromStation"] == "odpt.Station:TokyoMetro.Fukutoshin.Ikebukuro" && tmp_h["odpt:toStation"] == "odpt.Station:TokyoMetro.Fukutoshin.Shibuya"
                tmp_h["travelTime"] = 5
                break
              end
            end

            if (h["odpt:fromStation"] == tmp_h["odpt:fromStation"]) && (h["odpt:toStation"] == tmp_h["odpt:toStation"])
              tmp_h["travelTime"] = h["odpt:necessaryTime"]
              break
            end
          end #366Lのdata2.eachに対するend

          from_stn_dist =0
          to_stn_dist =0
          last_stn_dist = 0

          if tmp_h["direction"] == "forward"
            statement = connection.prepare("SELECT latlngtable.distance From latlngtable
              INNER JOIN station_table on latlngtable.station = station_table.station_id
              INNER JOIN metro_station_table on station_table.station_name = metro_station_table.station_name
              WHERE latlngtable.line_id = ? AND metro_station_table.metro_station_name = ?")
          elsif tmp_h["direction"] == "backward"
            statement = connection.prepare("SELECT latlngtable.distance_reverse From latlngtable
              INNER JOIN station_table on latlngtable.station = station_table.station_id
              INNER JOIN metro_station_table on station_table.station_name = metro_station_table.station_name
              WHERE latlngtable.line_id = ? AND metro_station_table.metro_station_name = ?")
          end
            from_stn_dist = statement.execute(tmp_h["line"],tmp_h["odpt:fromStation"]).fetch[0]

            if tmp_h["direction"] == "forward"
              statement = connection.prepare("SELECT latlngtable.distance From latlngtable
                INNER JOIN station_table on latlngtable.station = station_table.station_id
                INNER JOIN metro_station_table on station_table.station_name = metro_station_table.station_name
                WHERE latlngtable.line_id = ? AND metro_station_table.metro_station_name = ?")
            elsif tmp_h["direction"] == "backward"
              statement = connection.prepare("SELECT latlngtable.distance_reverse From latlngtable
                INNER JOIN station_table on latlngtable.station = station_table.station_id
                INNER JOIN metro_station_table on station_table.station_name = metro_station_table.station_name
                WHERE latlngtable.line_id = ? AND metro_station_table.metro_station_name = ?")
            end
            to_stn_dist = statement.execute(tmp_h["line"],tmp_h["odpt:toStation"]).fetch[0]

            statement = connection.prepare("SELECT MAX(distance) FROM latlngtable
              WHERE latlngtable.line_id = ?")
            last_stn_dist = statement.execute(tmp_h["line"]).fetch[0]

            tmp_speed = (to_stn_dist-from_stn_dist)/tmp_h["travelTime"]

            tmp_h["totalTraveltime"] =  (last_stn_dist-(to_stn_dist+from_stn_dist)/2) / tmp_speed
          end

          statement = connection.prepare("SELECT distance From latlngtable WHERE line_id = ? ORDER BY latlng_number DESC")
          length = statement.execute(tmp_h["line"]).fetch[0]

          begin
            tmp_h["offset"] = ((offset_list/(length))*100).to_s + '%'
            tmp_h["coordinateNum"] = coordinate
          rescue NoMethodError
            tmp_h["offset"] = '0%'
            tmp_h["coordinateNum"] = 0
          end

         if tmp_h["odpt:toStation"] == nil
           tmp_h["offset"] = 0
	 else
	   tmp_h["offset"] = 0.5
	 end	  

          statement = connection.prepare("SELECT latlng_number From latlngtable WHERE line_id = ? ORDER BY latlng_number DESC")
          tmp_h["allCoordinateNum"] = statement.execute(tmp_h["line"]).fetch[0]-1

          metrolocation << tmp_h
        end #177Lのif文へのend
      rescue => exc
        count = count + 1
        p tmp_h
        p exc
        p $@
        next
      end #129Lのjson.parse(data2)へのend
    end #67Lのbeginへのend
  end #66Lのjson.parse(data)へのend
  connection.close()
  p "skip:#{count}times"
  return metrolocation
end

#p get_trainlocation().to_json
