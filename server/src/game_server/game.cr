require "./models/*"
require "./managers/*"
require "./handlers/*"

module GameServer
  class Game
    getter player_manager : PlayerManager
    getter game_state : GameState
    getter message_handler : MessageHandler
    getter log_manager : GameLogManager

    def initialize
      @game_state = GameStateManager.load
      @player_manager = PlayerManager.new
      @message_handler = MessageHandler.new(@player_manager, @game_state)
      @log_manager = GameLogManager.new(@game_state)
    end

    def add_player(socket : HTTP::WebSocket) : String
      uuid = @player_manager.add_player(socket)
      return uuid if uuid.empty?
      add_player_to_game(uuid)
      uuid
    end

    def reconnect_player(socket : HTTP::WebSocket, uuid : String) : Bool
      success = @player_manager.reconnect_player(socket, uuid, @game_state)
      restore_player_position(uuid) if success
      save_game_state if success
      success
    end

    def remove_player(uuid : String)
      @player_manager.remove_player(uuid)
    end

    def broadcast_message(message : PlayerActionMessage, exclude_uuid : String? = nil)
      @message_handler.broadcast_message(message, exclude_uuid)
    end

    def send_message_to_player(uuid : String, message : Message)
      @message_handler.send_message_to_player(uuid, message)
    end

    def handle_message(uuid : String, message_json : String)
      @message_handler.handle_message(uuid, message_json)
    end

    private def add_player_to_game(uuid : String)
      coords = @player_manager.player_positions[uuid]
      @log_manager.add_player_to_log(uuid, coords)
      save_game_state
    end

    private def restore_player_position(uuid : String)
      @log_manager.restore_player_position(uuid, @player_manager)
    end

    private def save_game_state
      GameStateManager.save(@game_state)
    end
  end
end
