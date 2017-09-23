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
valid     = Validation.new(log, output)
retries   = 0

validations = {
	:espn_page        => false,
	:upload_stats     => true,
	:last_stat_record => nil
}

begin
	log.info output.start
	log.info output.new_line

	# WORKFLOW 1: loop until espn gamelog page successfully captured
	until validations[:espn_page] == true
    # espn_page               = HTTParty.get('http://www.espn.com/nba/player/gamelog/_/id/3032978/dario-saric')
    espn_page               = HTTParty.get('http://www.espn.com/nba/player/gamelog/_/id/3059318/joel-embiid')
    validations[:espn_page] = valid.page?(espn_page.code)

		# sleep(60 * 1)
	end

	# WORKFLOW 2: ensure data/columns are as expected
  columns               = Nokogiri::HTML(espn_page).css('.tablehead tr:nth-child(2) td')
  validations[:columns] = valid.columns?(columns)

  if validations[:columns] == false
    raise "column mismatch!"
  end

  # TODO: validation on data... this variable used below in WORKFLOW 4b.
  # WORKFLOW 3: if :game_complete == false, player's game is in progress
  last_game_in_espn_log       = Nokogiri::HTML(espn_page).css('.tablehead tr:nth-child(3) td')
  validations[:game_complete] = valid.game_complete?(last_game_in_espn_log)

	log.info "VALIDATIONS BEFORE WORKFLOW 3: " + validations.inspect
	log.info output.new_line

	if validations[:game_complete] == true
    stats = {}
    columns.each_with_index do |value, index|
      stats[value.text] = last_game_in_espn_log[index].children.text
    end
        	
		log.info "SCRAPED STATS INCOMING/RAW"
    stats.keys.each_with_index do |key, index|
      log.info key.inspect + " => " + stats[key].inspect

    	# converting scrape categories to ActiveRecord/Ruby friendly names
    	case key
      when 'DATE'
        stats['GAME_DATE']  = stats[key]
        stats.delete(key)
      when 'FGM-FGA'
        stats['FGM_FGA']    = stats[key]
        stats.delete(key)
      when 'FG%'
        stats['FG_PRCT']    = stats[key]
        stats.delete(key)
      when '3PM-3PA'
        stats['THREE_M_A']  = stats[key]
        stats.delete(key)
      when '3P%'
        stats['THREE_PRCT'] = stats[key]
        stats.delete(key)
      when 'FTM-FTA'
        stats['FTM_FTA' ]   = stats[key]
        stats.delete(key)
      when 'FT%'
        stats['FT_PRCT']    = stats[key]
        stats.delete(key)
      end
    end

    log.info "SCRAPED STATS READY FOR UPLOAD"
    stats.each { |st| log.info st.inspect }
  	log.info output.new_line

  	# WORKFLOW 4: loop until freshly scraped stats are uploaded to site 
  	# WORKFLOW 4: or verified as already uploaded (no new game the night before)
   	until validations[:upload_stats] == false

   		# TODO: if it is game 1 of the NBA season, there will be no stat record!
   		# WORKFLOW 4a: loop until site successfully returns last record
   		until validations[:last_stat_record] != nil
  			# validations[:last_stat_record] = HTTParty.get('http://localhost:2121/site/last_stat_record', :body => { :secret => ARGV[0] })
  			validations[:last_stat_record] = HTTParty.get('http://embiid21.herokuapp.com/site/last_stat_record', :body => { :secret => ARGV[0] })

  			log.info "LAST STAT RECORD"
  			log.info validations[:last_stat_record].inspect
  		  log.info output.new_line

  		  # sleep(60 * 1)
  	  end
  		
  		# WORKFLOW 4b: default status is TRUE/proceed to upload
  		# WORKFLOW 4b: if the stats have already been uploaded, boolean will flip to FALSE
  		validations[:upload_stats] = valid.upload_stats?(last_game_in_espn_log, validations[:last_stat_record])

  		log.info "VALIDATIONS in WORKFLOW 4: " + validations.inspect
  		log.info output.new_line

      # WORKFLOW 4b: boolean remains TRUE/proceed to upload
      if validations[:upload_stats] == true

        # response = HTTParty.post('http://localhost:2121/site/upload_stats', {
        # response = HTTParty.post('http://embiid21.herokuapp.com/site/upload_stats', {
        #     :body => stats.to_json,
        #     :headers => { 'Content-Type' => 'application/json' },
        #     :body => { :secret => ARGV[0] }
        # })

        # TODO: error response (non 200 code) from Rails Heroku app
        # log.info "UPLOAD_STATS RESPONSE: " + response.inspect
        # log.info "RESPONSE STATUS CODE: " + response.code.inspect
        # log.info output.new_line

        # WORKFLOW 4c: upload successful, job is done
        # if response.code == 200 then validations[:upload_stats] = false end
        validations[:upload_stats] = false

  		  log.info "VALIDATIONS after WORKFLOW 4c: " + validations.inspect
  		  log.info output.new_line
   		end

      # sleep(60 * 1)
		end
  end
	
	log.info output.end
	log.info output.run_time
	log.info output.new_line

  system "echo 'Here is your daily stat scrape.' | mail -s 'Raspi: Embiid Stat Scrape' embiidfeed@gmail.com -A /home/pi/Desktop/embiid21_stats_scrape/logger/log_#{stamp}.txt"
rescue StandardError => error
	log.error "ERROR!"
	log.error error.inspect
  log.error output.new_line

	# sleep(60 * 5)

  if retries == 3
    system "echo 'Error when processing stat scrape.' | mail -s 'ERROR! Embiid Stat Scrape' embiidfeed@gmail.com -A /home/pi/Desktop/embiid21_stats_scrape/logger/log_#{stamp}.txt"
  else
    retries += 1
    retry
  end
end

