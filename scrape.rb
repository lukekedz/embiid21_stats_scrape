require 'logger'
require 'httparty'
require 'nokogiri'
require 'json'

require_relative 'prettify_log_output'
require_relative 'validation'

stamp     = Time.new.strftime('%Y%m%d%H%M')
log       = Logger.new("./logger/log_#{stamp}.txt", 10, 1024000)
log.level = Logger::INFO
output    = PrettifyLogOutput.new
valid     = Validation.new

validations = {}

begin
	# TODO: cron (every morning, mult times, from 7am - 11am or similar)
    loop do
    	log.info output.start
    	log.info output.new_line

        # espn_page             = HTTParty.get('http://www.espn.com/nba/player/gamelog/_/id/3059318/joel-embiid')
        espn_page               = HTTParty.get('http://www.espn.com/nba/player/gamelog/_/id/3032978/dario-saric')
        validations[:espn_page] = valid.page(log, espn_page.code)

        columns               = Nokogiri::HTML(espn_page).css('.tablehead tr:nth-child(2) td')
        validations[:columns] = valid.columns(log, columns)

        last_game_in_espn_log       = Nokogiri::HTML(espn_page).css('.tablehead tr:nth-child(3) td')
        validations[:game_complete] = valid.game_complete(log, last_game_in_espn_log)

		# TODO: could store this value within cron job
        # last_stat_record                 = HTTParty.get('http://localhost:2121/site/last_stat_record')
        last_stat_record                 = HTTParty.post('http://embiid21.herokuapp.com/site/last_game')
        validations[:stats_not_uploaded] = valid.stats_not_uploaded(log, last_game_in_espn_log, last_stat_record)

    	upload_data = []
    	validations.each { |k,v| upload_data.push v }

		# TODO: condense into one line iteration combined w/ below conditional 'all?'
    	log.info output.new_line
    	log.info "VALIDATIONS: " + validations.inspect
    	log.info "UPLOAD? " + upload_data.inspect
    	log.info output.new_line

    	if upload_data.all?
	        stats = {}

	        columns.each_with_index do |value, index|
	            stats[value.text] = last_game_in_espn_log[index].children.text
	        end
	        	
			log.info "SCRAPED STATS INCOMING/RAW"
	        stats.keys.each_with_index do |key, index|
	        	log.info key.inspect + " => " + stats[key].inspect

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

	    	log.info output.new_line
	        log.info "SCRAPED STATS READY FOR UPLOAD"
	        stats.each { |st| log.info st.inspect }
	    	log.info output.new_line

	        # response = HTTParty.post('http://localhost:2121/site/upload_stats', {
	        response = HTTParty.post('http://embiid21.herokuapp.com/site/upload_stats', {
	            :body => stats.to_json,
	            :headers => { 'Content-Type' => 'application/json' }
	        })

	        log.info response.inspect
    		log.info output.new_line
    	end
    	
    	log.info output.end
    	log.info output.new_line

    	# TODO: email update
    	sleep(60 * 30)
    end
rescue StandardError => error
	log.error error.inspect
    log.error output.new_line

	sleep(60 * 30)
	retry
end

