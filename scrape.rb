require 'nokogiri'
require 'httparty'
require 'pg'
require_relative 'processor'

begin
    Processor.processing()

	page      = HTTParty.get('http://www.espn.com/nba/player/gamelog/_/id/3059318/joel-embiid')
	columns   = Nokogiri::HTML(page).css('.tablehead tr:nth-child(2) td')
	rando     = rand(3..20)
	last_game = Nokogiri::HTML(page).css('.tablehead tr:nth-child(' + rando.to_s + ') td')
	stats     = {}

	columns.each_with_index do |value, index|
		stats[value.text] = last_game[index].children.text
	end

	stats.keys.each do |key|
		case key
		when "DATE"
			stats["GAME_DATE"] = stats[key]
			stats.delete(key)
		when "FGM-FGA"
			stats["FGM_FMA"] = stats[key]
			stats.delete(key)
		when "FG%"
			stats["FG_PRCT"] = stats[key]
			stats.delete(key)
		when "3PM-3PA"
			stats["THREE_PM_PA"] = stats[key]
			stats.delete(key)
		when "3P%"
			stats["THREE_PRCT"] = stats[key]
			stats.delete(key)
		when "FTM-FTA"
			stats["FTM_FTA" ] = stats[key]
			stats.delete(key)
		when "FT%"
			stats["FT_PRCT"] = stats[key]
			stats.delete(key)
		end
	end

	stats = Hash[ stats.map { |k, v| [k.to_sym, v] } ]
	# puts
	# puts stats.inspect
	# puts

	database_local = JSON.parse(File.read('./database_local.json'))
	pg = PG::Connection.open(:dbname   => database_local['database'],
	                         :host     => database_local['dataserver'],
	                         :user     => database_local['username'],
	                         :password => database_local['password']
	                        )

	def insert_stats(stats)
		"INSERT INTO game_log (
			game_date,
			opp,
			score,
	        min,
	        fgm_fga,
	        fg_prct,
	        three_pm_pa,
	        three_prct,
	        ftm_fta,
	        ft_prct,
	        reb,
	        ast,
	        blk,
	        stl,
	        pf,
	        turnovers,
	        pts,
	        updated_at,
	        created_at        
		) VALUES (
			\'#{stats[:GAME_DATE]}\',
			\'#{stats[:OPP]}\',
			\'#{stats[:SCORE]}\',
			\'#{stats[:MIN]}\',
			\'#{stats[:FGM_FMA]}\',
			\'#{stats[:FG_PRCT]}\',
			\'#{stats[:THREE_PM_PA]}\',
			\'#{stats[:THREE_PRCT]}\',
			\'#{stats[:FTM_FTA]}\',
			\'#{stats[:FT_PRCT]}\',
			\'#{stats[:REB]}\',
			\'#{stats[:AST]}\',
			\'#{stats[:BLK]}\',
			\'#{stats[:STL]}\',
			\'#{stats[:PF]}\',
			\'#{stats[:TO]}\',
			\'#{stats[:PTS]}\',
			NOW(),
			NOW()
		);"
	end
	pg.exec insert_stats(stats)

	def count
		"SELECT count(*) FROM game_log;"
	end

	anyong = pg.exec count()
	puts "Total Records: " + anyong[0]["count"].to_s
	puts

	def records
		"SELECT * FROM game_log ORDER BY created_at DESC LIMIT 1;"
	end

	anyong = pg.exec records()
	puts "GAME LOG:"
	anyong.each do |rec|
		puts rec['game_date'] + " " + rec['opp'] + " => RESULT: " + rec['score']
		puts rec['pts'] + " points on " + rec['fgm_fga'] + " (" + rec['fg_prct'] + ") shooting."
		puts "Rebounds: " + rec['reb']
		puts "Blocks: " + rec['blk']
		puts "Assists: " + rec['ast']
		puts "Steals: " + rec['stl']
		puts
	end

	sleep 300
end while 1 == 1
