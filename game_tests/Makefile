all: build-server build-client

build-server:
	cd server && shards install && crystal build src/game_server.cr -o game_server

build-client:
	cd client && shards install && crystal build src/game_client.cr -o game_client

run-server:
	cd server && ./game_server

run-client:
	cd client && ./game_client

clean:
	cd server && rm -f game_server game_state.json
	cd client && rm -f game_client game_state.json

.PHONY: all build-server build-client run-server run-client clean