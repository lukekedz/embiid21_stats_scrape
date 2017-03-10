build:
	@docker build -t embiid21 .

db:
	@docker run --name postgres -h localhost -p 5432 -e POSTGRES_DATABASE=embiid21 -e POSTGRES_USER=embiid21 -e POSTGRES_PASSWORD=Processing76! -d postgres

# cli
# docker run --rm --link postgres --name embiid21 -p 2121:2121 -v $(pwd):/opt/embiid21_stats_scrape -it embiid21
# container cli
# ruby create_game_log.rb
# ruby scrape.rb

pg:
	@docker exec -it postgres psql -U embiid21