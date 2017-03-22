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

begin
	# TODO: chron (every morning, mult times, from 7am - 11am or similar)
    loop do
    	log.info output.start
    	log.info output.new_line

        # page      = HTTParty.get('http://www.espn.com/nba/player/gamelog/_/id/3059318/joel-embiid')
        page      = HTTParty.get('http://www.espn.com/nba/player/gamelog/_/id/3032978/dario-saric')
        columns   = Nokogiri::HTML(page).css('.tablehead tr:nth-child(2) td')
        last_game = Nokogiri::HTML(page).css('.tablehead tr:nth-child(3) td')

        # TODO: validations
        # is the page http 200
        # are the columns populated and matched?
        # is there data present for the last game
        # does the score category contain a W/L, indicating the game stat log is complete?
        # heroku app => have we already scraped and uploaded this data?
        # log.info "DATA VALIDATION: " valid_data.inspect
    	# log.info output.new_line

        stats = {}

        columns.each_with_index do |value, index|
            stats[value.text] = last_game[index].children.text
        end

		valid_data = true
        	
		log.info "SCRAPED STATS INCOMING/RAW"
        stats.keys.each_with_index do |key, index|
        	log.info key.inspect + " => " + stats[key].inspect

        	if key == valid.columns(index)
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
		    else
		    	valid_data = false
		    	break
		    end
        end
    	log.info output.new_line

        if valid_data
	        log.info "SCRAPED STATS READY FOR UPLOAD"

	        stats.each do |st|
	        	log.info st.inspect
	        end
	    	log.info output.new_line

	        # response = HTTParty.post('http://localhost:2121/site/upload_stats', {
	        response = HTTParty.post('http://embiid21.herokuapp.com/site/upload_stats', {
	            :body => stats.to_json,
	            :headers => { 'Content-Type' => 'application/json' }
	        })

	        log.info response.inspect
    		log.info output.new_line
	    else
	    	log.error "DATA INVALID: %p" % stats.inspect
    		log.error output.new_line
	    end

	   	# TODO: email update
        sleep(60 * 30)
    	
    	log.info output.end
    	log.info output.new_line
    end
rescue StandardError => error
	log.error error.inspect
    log.error output.new_line

	sleep(60 * 5)
	retry
end

