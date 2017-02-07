db:
	@docker run --name postgres -h localhost -p 5432 -e POSTGRES_DATABASE=embiid21 -e POSTGRES_USER=embiid21 -e POSTGRES_PASSWORD=Processing76! -d postgres

gamelog:
	ruby ./create_game_log.rb

# have to update the docker port when launcing new instances
console:
	@psql -h localhost -p 32770 -d embiid21 -U embiid21 