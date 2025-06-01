require "uuid"
require "json"
require "./models/*"
require "./commands/*"
require "./handlers/*"

module GameServer
  class Game
    GRID_SIZE       = 512
    MAX_PLAYERS     = 512
    GAME_STATE_FILE = "game_state.json"

    getter players : Hash(String, HTTP::WebSocket)
    getter player_positions : Hash(String, Coordinates)
    getter player_names : Hash(String, String)
    getter game_state : GameState

    def initialize
      @players = {} of String => HTTP::WebSocket
      @player_positions = {} of String => Coordinates
      @player_names = {} of String => String
      @game_state = load_game_state
    end

    def load_game_state : GameState
      if File.exists?(GAME_STATE_FILE)
        content = File.read(GAME_STATE_FILE)
        GameState.from_json(content)
      else
        GameState.new
      end
    end

    def save_game_state
      File.write(GAME_STATE_FILE, @game_state.to_json)
    end

    def add_player(socket : HTTP::WebSocket) : String
      return "" if @players.size >= MAX_PLAYERS

      uuid = UUID.random.to_s
      @players[uuid] = socket

      Logger.log_connection(uuid)

      coords = generate_random_coordinates
      @player_positions[uuid] = coords
      add_player_to_log(uuid, coords)
      save_game_state
      uuid
    end

    def reconnect_player(socket : HTTP::WebSocket, uuid : String) : Bool
      return false unless @game_state.players.has_key?(uuid)

      @players[uuid] = socket

      player_name = @game_state.players[uuid]?.try(&.name) || "Unknown"
      Logger.log_reconnection(uuid, player_name)

      restore_player_position(uuid)
      save_game_state
      true
    end

    def remove_player(uuid : String)
      player_name = @player_names[uuid]? || @game_state.players[uuid]?.try(&.name) || "Unknown"
      Logger.log_disconnection(uuid, player_name)

      @players.delete(uuid)
      @player_positions.delete(uuid)
    end

    def set_player_name(uuid : String, name : String)
      @player_names[uuid] = name
      @game_state.players[uuid] = Player.new(name)
      save_game_state
    end

    def broadcast_message(message : String, exclude_uuid : String? = nil)
      @players.each do |uuid, socket|
        next if uuid == exclude_uuid
        begin
          socket.send(message)
        rescue
          remove_player(uuid)
        end
      end
    end

    def cast_spell(caster_uuid : String, spell_name : String, coordinates : Coordinates)
      coord_array = [coordinates.x, coordinates.y]
      effect = SpellFactory.create_effect(spell_name)
      spell = Spell.new(caster_uuid, spell_name, effect)

      add_spell_to_log(coord_array, spell)
      save_game_state
    end

    def handle_command(uuid : String, command : String)
      parts = command.split(" ", 2)
      cmd = parts[0]?.try(&.downcase)
      args = parts[1]?

      player_name = @player_names[uuid]? || @game_state.players[uuid]?.try(&.name) || "Unknown"
      Logger.log_command(uuid, player_name, command)

      case cmd
      when "/alias"
        handle_alias_command(uuid, args)
      when "/say"
        handle_say_command(uuid, args)
      when "/cast"
        handle_cast_command(uuid, args)
      when "/witness"
        handle_witness_command(uuid)
      end
    end

    private def generate_random_coordinates : Coordinates
      x = Random.rand(GRID_SIZE) - (GRID_SIZE // 2)
      y = Random.rand(GRID_SIZE) - (GRID_SIZE // 2)
      Coordinates.new(x, y)
    end

    private def add_player_to_log(uuid : String, coords : Coordinates)
      coord_array = [coords.x, coords.y]
      existing_log = @game_state.log.find { |log| log.coordinates == coord_array }
      if existing_log.nil?
        @game_state.log << CoordinateLog.new(coord_array, uuid)
      else
        index = @game_state.log.index!(existing_log)
        @game_state.log[index] = CoordinateLog.new(coord_array, uuid, existing_log.spells_cast)
      end
    end

    private def restore_player_position(uuid : String)
      existing_log = @game_state.log.find { |log| log.player == uuid }
      if existing_log
        coords = Coordinates.new(existing_log.coordinates[0], existing_log.coordinates[1])
        @player_positions[uuid] = coords
      else
        coords = generate_random_coordinates
        @player_positions[uuid] = coords
        add_player_to_log(uuid, coords)
      end
    end

    private def add_spell_to_log(coord_array : Array(Int32), spell : Spell)
      existing_log = @game_state.log.find { |log| log.coordinates == coord_array }
      if existing_log
        index = @game_state.log.index!(existing_log)
        new_spells = existing_log.spells_cast + [spell]
        @game_state.log[index] = CoordinateLog.new(coord_array, existing_log.player, new_spells)
      else
        @game_state.log << CoordinateLog.new(coord_array, nil, [spell])
      end
    end

    private def handle_alias_command(uuid : String, args : String?)
      return if args.nil? || args.empty?

      set_player_name(uuid, args)
      player_name = @player_names[uuid]? || uuid
      broadcast_message("#{player_name} changed their name to #{args}")
    end

    private def handle_say_command(uuid : String, args : String?)
      return if args.nil? || args.empty?

      player_name = @player_names[uuid]? || uuid
      broadcast_message("#{player_name}: #{args}")
    end

    private def handle_cast_command(uuid : String, args : String?)
      return if args.nil? || args.empty?

      spell_parts = args.split(" ", 2)
      spell_name = spell_parts[0]?
      coords_str = spell_parts[1]?

      return unless spell_name && coords_str

      coords_parts = coords_str.split(",")
      return unless coords_parts.size == 2

      x = coords_parts[0].strip.to_i?
      y = coords_parts[1].strip.to_i?

      if x && y
        coordinates = Coordinates.new(x, y)
        cast_spell(uuid, spell_name, coordinates)
        player_name = @player_names[uuid]? || uuid
        broadcast_message("#{player_name} cast #{spell_name} at #{coordinates}")
      else
        @players[uuid]?.try(&.send("Invalid coordinates"))
      end
    end

    private def handle_witness_command(uuid : String)
      @players[uuid]?.try(&.send(@game_state.to_pretty_json))
    end
  end
end
