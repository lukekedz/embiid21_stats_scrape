require 'logger'
require 'httparty'
require 'nokogiri'
require 'json'

stamp     = Time.new.strftime('%Y%m%d%H%M')
log       = Logger.new("./logger/log_#{stamp}.txt", 5) # saves past 5 logs
log.level = Logger::INFO

begin
    loop do
    	log.info Time.now

        page = HTTParty.get('http://www.espn.com/nba/player/gamelog/_/id/3032978/dario-saric')

        columns   = Nokogiri::HTML(page).css('.tablehead tr:nth-child(2) td')
        last_game = Nokogiri::HTML(page).css('.tablehead tr:nth-child(3) td')

        stats = {}

        columns.each_with_index do |value, index|
            stats[value.text] = last_game[index].children.text
        end

        stats.keys.each do |key|
        case key
            when 'DATE'
                stats['GAME_DATE'] = stats[key]
                stats.delete(key)
            when 'FGM-FGA'
                stats['FGM_FGA'] = stats[key]
                stats.delete(key)
            when 'FG%'
                stats['FG_PRCT'] = stats[key]
                stats.delete(key)
            when '3PM-3PA'
                stats['THREE_M_A'] = stats[key]
                stats.delete(key)
            when '3P%'
                stats['THREE_PRCT'] = stats[key]
                stats.delete(key)
            when 'FTM-FTA'
                stats['FTM_FTA' ] = stats[key]
                stats.delete(key)
            when 'FT%'
                stats['FT_PRCT'] = stats[key]
                stats.delete(key)
            end
        end

		# manually escaping potentially malicious data
        log.info("SCRAPED STATS READY FOR UPLOAD: %p" % stats.inspect)

        response = HTTParty.post('http://localhost:2121/site/upload_stats', {
        # response = HTTParty.post('http://embiid21.herokuapp.com/site/upload_stats', {
            :body => stats.to_json,
            :headers => { 'Content-Type' => 'application/json' }
        })

        log.info response.inspect

        sleep(60 * 5)
    end
rescue StandardError => error
	log.error error.inspect
	retry
end

