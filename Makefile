# launch: docker run --rm --link postgres --name embiid21 -p 2121:2121 -v $(pwd):/opt/embiid21_stats_scrape -it embiid21

db:
	@docker run --name postgres -h localhost -p 5432 -e POSTGRES_DATABASE=embiid21 -e POSTGRES_USER=embiid21 -e POSTGRES_PASSWORD=Processing76! -d postgres

# has to run once the coantiner is up ?
# gamelog:
	# ruby ./create_game_log.rb

# not working
# have to update the docker port when launcing new instances
# console:
	# @psql -h localhost -p 32770 -d embiid21 -U embiid21 