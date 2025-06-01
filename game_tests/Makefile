all: build-server build-client

build-server:
	cd ../server && shards install && crystal build src/game_server.cr -o game_server

build-client:
	cd ../client && shards install && crystal build src/game_client.cr -o game_client

lint:
	cd ../server && ./bin/ameba src/
	cd ../client && ./bin/ameba src/

format:
	cd ../server && crystal tool format src/
	cd ../client && crystal tool format src/

run-server:
	cd ../server && ./game_server

run-client:
	cd ../client && ./game_client

clean:
	cd ../server && rm -f game_server game_state.json
	cd ../client && rm -f game_client game_state.json

# Docker targets
docker-build:
	cd .. && docker compose build game-server

docker-run:
	cd .. && docker compose up game-server

docker-dev:
	cd .. && docker compose --profile dev up dev-server

docker-test:
	cd .. && docker compose --profile test run --rm quick-test

docker-lint:
	cd .. && docker compose --profile test run --rm lint-check

docker-integration:
	cd .. && docker compose --profile test run --rm integration-test

docker-clean:
	cd .. && docker compose down --volumes --remove-orphans
	cd .. && docker system prune -f

# Combined targets
docker-all: docker-build docker-test docker-lint

.PHONY: all build-server build-client lint format run-server run-client clean docker-build docker-run docker-dev docker-test docker-lint docker-integration docker-clean docker-all