require 'dotenv/load'

namespace :scrape do
  desc 'Tipping off the scraping process...'

  task :tip_off do
    ruby 'scrape.rb' + ' ' + ENV['ANYONG']
  end

end