# http://blog.alexellis.io/5-things-docker-rpi/
# https://github.com/resin-io/Hello-Ruby

FROM hypriot/rpi-ruby:latest

RUN apt-get update

RUN mkdir -p /opt/embiid21_stats_scrape
WORKDIR /opt/embiid21_stats_scrape

COPY Gemfile* /opt/embiid21_stats_scrape/
RUN gem install bundler

COPY . /opt/embiid21_stats_scrape/

EXPOSE 2121

CMD ["bash"]