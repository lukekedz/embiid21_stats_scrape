FROM ruby:latest

RUN echo "America/New_York" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

RUN mkdir -p /opt/embiid21_stats_scrape
WORKDIR /opt/embiid21_stats_scrape

COPY Gemfile* /opt/embiid21_stats_scrape/
RUN bundle install

COPY . /opt/embiid21_stats_scrape/

EXPOSE 2121

CMD ["bash"]