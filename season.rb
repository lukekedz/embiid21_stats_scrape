require 'logger'
require 'httparty'
require 'nokogiri'
require 'json'

seasons_stats = HTTParty.get('http://www.espn.com/nba/player/stats/_/id/3059318/joel-embiid')

columns = Nokogiri::HTML(seasons_stats).css('.tablehead tr:nth-child(2) td')
average = Nokogiri::HTML(seasons_stats).css('.tablehead tr:nth-child(4) td')

stats = {}
columns.each_with_index do |value, index|
  stats[value.text] = average[index].children.text
end
      
puts "SEASON AVERAGES"
stats.keys.each_with_index do |key, index|
  puts key.inspect + " => " + stats[key].inspect

  # converting scrape categories to ActiveRecord/Ruby friendly names
  case key
  when 'SEASON'
    stats['YEAR']       = stats[key]
    stats.delete(key)
  when 'MINS'
    stats['MIN']        = stats[key]
    stats.delete(key)
  when 'FGM-A'
    stats['FGM_FGA']    = stats[key]
    stats.delete(key)
  when 'FG%'
    stats['FG_PRCT']    = stats[key]
    stats.delete(key)
  when '3PM-A'
    stats['THREE_M_A']  = stats[key]
    stats.delete(key)
  when '3P%'
    stats['THREE_PRCT'] = stats[key]
    stats.delete(key)
  when 'FTM-A'
    stats['FTM_FTA']   = stats[key]
    stats.delete(key)
  when 'FT%'
    stats['FT_PRCT']    = stats[key]
    stats.delete(key)
  end
end
puts

puts "SCRAPED STATS READY FOR UPLOAD"
stats.each { |st| puts st.inspect }

stats['secret'] = ARGV[0]

response = HTTParty.post('http://embiid21.herokuapp.com/site/upload_averages', {
    :body => stats.to_json,
    :headers => { 'Content-Type' => 'application/json' },
})

puts response.inspect