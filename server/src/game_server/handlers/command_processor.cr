require "../models/*"
require "../commands/*"
require "../managers/*"

module GameServer
  class CommandProcessor
    def initialize(@player_manager : PlayerManager, @game_state : GameState, @message_handler : MessageHandler)
    end

    def process(uuid : String, message : CommandMessage)
      case message.command.downcase
      when "alias"   then handle_alias(uuid, message.arguments)
      when "say"     then handle_say(uuid, message.arguments)
      when "cast"    then handle_cast(uuid, message.arguments)
      when "witness" then handle_witness(uuid)
      else                handle_unknown(uuid, message.command)
      end
    end

    private def handle_alias(uuid : String, args : String?)
      return if args.nil? || args.empty?
      set_alias_and_broadcast(uuid, args)
    end

    private def handle_say(uuid : String, args : String?)
      return if args.nil? || args.empty?
      broadcast_player_message(uuid, args)
    end

    private def handle_cast(uuid : String, args : String?)
      return if args.nil? || args.empty?
      SpellCaster.new(@player_manager, @game_state, @message_handler).cast(uuid, args)
    end

    private def handle_witness(uuid : String)
      game_log = GameLogMessage.new(@game_state.log, @game_state.players)
      @message_handler.send_message_to_player(uuid, game_log)
    end

    private def handle_unknown(uuid : String, command : String)
      @message_handler.send_message_to_player(uuid, ErrorMessage.new("Unknown command: #{command}"))
    end

    private def set_alias_and_broadcast(uuid : String, name : String)
      @player_manager.set_player_name(uuid, name, @game_state)
      player_name = @player_manager.player_names[uuid]? || uuid
      @message_handler.broadcast_message(PlayerActionMessage.new("#{player_name} changed their name to #{name}"))
    end

    private def broadcast_player_message(uuid : String, message : String)
      player_name = @player_manager.player_names[uuid]? || uuid
      @message_handler.broadcast_message(PlayerActionMessage.new("#{player_name}: #{message}"))
    end
  end
end
