FROM ruby:latest

RUN mkdir -p /opt/embiid21_stats_scrape
WORKDIR /opt/embiid21_stats_scrape

COPY Gemfile* /opt/embiid21_stats_scrape/
RUN bundle install

COPY . /opt/embiid21_stats_scrape/

EXPOSE 2121

CMD ["bash"]