class Validation

	def page?(log, code)
		log.info __method__
		log.info code.inspect

		code == 200 ? true : false
	end

	def columns?(log, columns)
		log.info __method__
		log.info columns.inspect

		valid_columns = ['DATE',    'OPP', 'SCORE',   'MIN', 
			             'FGM-FGA', 'FG%', '3PM-3PA', '3P%', 
			             'FTM-FTA', 'FT%', 'REB',     'AST', 
			             'BLK',     'STL', 'PF',      'TO',  
			             'PTS'
			          	]

        columns.each_with_index do |value, index|
			if value.text != valid_columns[index]
				return false
			end
		end

		true
	end

	def game_complete?(log, last_game_in_espn_log)
		log.info __method__
		log.info last_game_in_espn_log.inspect

		outcome = last_game_in_espn_log[2].children.text[0]

		outcome == "W" || outcome == "L" ? true : false
	end
	
	def upload_stats?(log, last_game_in_espn_log, last_stat_record)
		log.info __method__
		log.info last_game_in_espn_log.inspect
		log.info last_stat_record.inspect

		last_game_date   = last_game_in_espn_log[0].children.text
		last_record_date = last_stat_record.parsed_response["game_date"]

		# if no match, then TRUE/proceed to upload new record
		last_game_date == last_record_date ? false : true
	end
	
end
