# http://github.com/javan/whenever
# https://github.com/mojombo/chronic

set :chronic_options, :hours24 => true

every 1.day, :at => '06:00' do
  rake "scrape:tip_off"
end
