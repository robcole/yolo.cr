require "uuid"
require "../models/*"
require "../handlers/*"

module GameServer
  class PlayerManager
    GRID_SIZE   = 512
    MAX_PLAYERS = 512

    getter players : Hash(String, HTTP::WebSocket)
    getter player_positions : Hash(String, Coordinates)
    getter player_names : Hash(String, String)

    def initialize
      @players = {} of String => HTTP::WebSocket
      @player_positions = {} of String => Coordinates
      @player_names = {} of String => String
    end

    def add_player(socket : HTTP::WebSocket) : String
      return "" if at_capacity?
      uuid = create_new_player(socket)
      uuid
    end

    def reconnect_player(socket : HTTP::WebSocket, uuid : String, game_state : GameState) : Bool
      return false unless game_state.players.has_key?(uuid)
      restore_connection(socket, uuid, game_state)
      true
    end

    def remove_player(uuid : String)
      log_disconnection(uuid)
      cleanup_player_data(uuid)
    end

    def set_player_name(uuid : String, name : String, game_state : GameState)
      @player_names[uuid] = name
      game_state.players[uuid] = Player.new(name)
    end

    def generate_random_coordinates : Coordinates
      x = Random.rand(GRID_SIZE) - (GRID_SIZE // 2)
      y = Random.rand(GRID_SIZE) - (GRID_SIZE // 2)
      Coordinates.new(x, y)
    end

    private def at_capacity?
      @players.size >= MAX_PLAYERS
    end

    private def create_new_player(socket : HTTP::WebSocket)
      uuid = UUID.random.to_s
      @players[uuid] = socket
      Logger.log_connection(uuid)
      coords = generate_random_coordinates
      @player_positions[uuid] = coords
      uuid
    end

    private def restore_connection(socket : HTTP::WebSocket, uuid : String, game_state : GameState)
      @players[uuid] = socket
      player_name = game_state.players[uuid]?.try(&.name) || "Unknown"
      Logger.log_reconnection(uuid, player_name)
    end

    private def log_disconnection(uuid : String)
      player_name = get_player_display_name(uuid)
      Logger.log_disconnection(uuid, player_name)
    end

    private def get_player_display_name(uuid : String) : String
      @player_names[uuid]? || "Unknown"
    end

    private def cleanup_player_data(uuid : String)
      @players.delete(uuid)
      @player_positions.delete(uuid)
    end
  end
end
