require 'nokogiri'
require 'httparty'
require 'json'

# stamp    = Time.new.strftime('%Y%m%d%H%M')
# log_file = File.open("./logger/log_#{stamp}.txt", "w")
# $stdout  = log_file

begin
    loop do
        page = HTTParty.get('http://www.espn.com/nba/player/gamelog/_/id/3032978/dario-saric')

        columns   = Nokogiri::HTML(page).css('.tablehead tr:nth-child(2) td')
        last_game = Nokogiri::HTML(page).css('.tablehead tr:nth-child(3) td')

        # puts last_game.inspect
        stats = {}

        columns.each_with_index do |value, index|
            stats[value.text] = last_game[index].children.text
        end

        # columns = ["DATE", "OPP", "SCORE", "MIN", "FGM-FGA", "FG%", "3PM-3PA", "3P%", "FTM-FTA", "FT%", "REB", "AST", "BLK", "STL", "PTS"]

        stats.keys.each do |key|
        case key
            when "DATE"
                stats["GAME_DATE"] = stats[key]
                stats.delete(key)
            when "FGM-FGA"
                stats["FGM_FGA"] = stats[key]
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

        # stats = Hash[ stats.map { |k, v| [k.to_s, v] } ]
        puts
        puts "READY FOR UPLOAD"
        puts stats.inspect
        puts

        # stats.each do |st|
            # puts st.inspect
        # end

        response = HTTParty.post('http://localhost:2121/site/upload_stats', {
            :body => stats.to_json,
            :headers => { 'Content-Type' => 'application/json' }
        })

        # puts response.inspect
        puts

        sleep(60)
    end
rescue StandardError => e
  # log_file.close
end

