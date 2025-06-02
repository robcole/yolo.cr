require "../models/*"
require "./logger"

module GameServer
  class MessageHandler
    def initialize(@player_manager : PlayerManager, @game_state : GameState)
    end

    def broadcast_message(message : PlayerActionMessage, exclude_uuid : String? = nil)
      @player_manager.players.each do |uuid, socket|
        next if uuid == exclude_uuid
        send_safe(socket, message, uuid)
      end
    end

    def send_message_to_player(uuid : String, message : Message)
      @player_manager.players[uuid]?.try(&.send(message.to_json))
    end

    def handle_message(uuid : String, message_json : String)
      message = Message.from_json(message_json)
      route_message(uuid, message)
    rescue ex
      handle_invalid_message(uuid, message_json)
    end

    private def send_safe(socket : HTTP::WebSocket, message : PlayerActionMessage, uuid : String)
      socket.send(message.to_json)
    rescue
      @player_manager.remove_player(uuid)
    end

    private def route_message(uuid : String, message : Message)
      case message
      when CommandMessage    then handle_command_message(uuid, message)
      when ConnectionMessage then nil
      else                        send_error(uuid, "Unknown message type")
      end
    end

    private def handle_command_message(uuid : String, message : CommandMessage)
      player_name = get_player_name(uuid)
      Logger.log_command(uuid, player_name, format_command(message))
      CommandProcessor.new(@player_manager, @game_state, self).process(uuid, message)
    end

    private def handle_invalid_message(uuid : String, message_json : String)
      Logger.log_command(uuid, "Unknown", "Invalid JSON: #{message_json}")
      send_error(uuid, "Invalid message format")
    end

    private def get_player_name(uuid : String) : String
      @player_manager.player_names[uuid]? || @game_state.players[uuid]?.try(&.name) || "Unknown"
    end

    private def format_command(message : CommandMessage) : String
      "#{message.command} #{message.arguments}".strip
    end

    private def send_error(uuid : String, error : String)
      send_message_to_player(uuid, ErrorMessage.new(error))
    end
  end
end
