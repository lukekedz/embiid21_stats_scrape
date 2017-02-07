require 'nokogiri'
require 'httparty'
require 'pg'

page = HTTParty.get('http://www.espn.com/nba/player/gamelog/_/id/3059318/joel-embiid')

columns   = Nokogiri::HTML(page).css('.tablehead tr:nth-child(2) td')
last_game = Nokogiri::HTML(page).css('.tablehead tr:nth-child(3) td')

stats = {}

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
puts
puts stats.inspect
puts

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
# pg.exec insert_stats(stats)

def records
	"SELECT * FROM game_log;"
end

anyong = pg.exec records()
puts "GAME LOG:"
anyong.each do |rec|
	puts rec['game_date'] + " " + rec['opp'] + " => RESULT: " + rec['score']
	puts "Points: " + rec['pts']
	puts "Rebounds: " + rec['reb']
	puts
end
