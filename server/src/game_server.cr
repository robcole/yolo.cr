require "kemal"
require "json"
require "uuid"

module GameServer
  struct Coordinates
    include JSON::Serializable
    
    getter x : Int32
    getter y : Int32
    
    def initialize(@x : Int32, @y : Int32)
    end
    
    def to_s(io)
      io << "[#{@x}, #{@y}]"
    end
  end
  
  struct SpellEffect
    include JSON::Serializable
    
    getter type : String
    getter amount : Int32
    
    def initialize(@type : String, @amount : Int32)
    end
  end
  
  struct Spell
    include JSON::Serializable
    
    getter cast_by : String
    getter spell_name : String
    getter effect : SpellEffect
    
    def initialize(@cast_by : String, @spell_name : String, @effect : SpellEffect)
    end
  end
  
  struct CoordinateLog
    include JSON::Serializable
    
    getter coordinates : Array(Int32)
    getter player : String?
    getter spells_cast : Array(Spell)
    
    def initialize(@coordinates : Array(Int32), @player : String? = nil, @spells_cast = [] of Spell)
    end
  end
  
  struct Player
    include JSON::Serializable
    
    getter name : String
    
    def initialize(@name : String)
    end
  end
  
  struct GameState
    include JSON::Serializable
    
    getter log : Array(CoordinateLog)
    getter players : Hash(String, Player)
    
    def initialize(@log = [] of CoordinateLog, @players = {} of String => Player)
    end
  end
  
  class Game
    GRID_SIZE = 512
    MAX_PLAYERS = 512
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
      
      # Log connection
      timestamp = Time.local.to_s("%Y-%m-%d %H:%M:%S")
      puts "[#{timestamp}] Client connected - UUID: #{uuid}"
      
      # Assign random coordinates within the grid
      x = Random.rand(GRID_SIZE) - (GRID_SIZE // 2)
      y = Random.rand(GRID_SIZE) - (GRID_SIZE // 2)
      coords = Coordinates.new(x, y)
      @player_positions[uuid] = coords
      
      # Add player to game log if not already present
      coord_array = [coords.x, coords.y]
      existing_log = @game_state.log.find { |log| log.coordinates == coord_array }
      if existing_log.nil?
        @game_state.log << CoordinateLog.new(coord_array, uuid)
      else
        # Update existing log entry to set player
        index = @game_state.log.index!(existing_log)
        @game_state.log[index] = CoordinateLog.new(coord_array, uuid, existing_log.spells_cast)
      end
      
      save_game_state
      uuid
    end
    
    def reconnect_player(socket : HTTP::WebSocket, uuid : String) : Bool
      return false unless @game_state.players.has_key?(uuid)
      
      @players[uuid] = socket
      
      # Log reconnection
      timestamp = Time.local.to_s("%Y-%m-%d %H:%M:%S")
      player_name = @game_state.players[uuid]?.try(&.name) || "Unknown"
      puts "[#{timestamp}] Client reconnected - UUID: #{uuid}, Name: #{player_name}"
      
      # Find existing position or assign new one
      existing_log = @game_state.log.find { |log| log.player == uuid }
      if existing_log
        coords = Coordinates.new(existing_log.coordinates[0], existing_log.coordinates[1])
        @player_positions[uuid] = coords
      else
        # Assign new coordinates if not found
        x = Random.rand(GRID_SIZE) - (GRID_SIZE // 2)
        y = Random.rand(GRID_SIZE) - (GRID_SIZE // 2)
        coords = Coordinates.new(x, y)
        @player_positions[uuid] = coords
        
        coord_array = [coords.x, coords.y]
        @game_state.log << CoordinateLog.new(coord_array, uuid)
      end
      
      save_game_state
      true
    end
    
    def remove_player(uuid : String)
      # Log disconnection
      timestamp = Time.local.to_s("%Y-%m-%d %H:%M:%S")
      player_name = @player_names[uuid]? || @game_state.players[uuid]?.try(&.name) || "Unknown"
      puts "[#{timestamp}] Client disconnected - UUID: #{uuid}, Name: #{player_name}"
      
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
          # Remove disconnected player
          remove_player(uuid)
        end
      end
    end
    
    def cast_spell(caster_uuid : String, spell_name : String, coordinates : Coordinates)
      coord_array = [coordinates.x, coordinates.y]
      
      # Create spell effect (simplified for this example)
      effect = case spell_name.downcase
               when "shield"
                 SpellEffect.new("IncreaseHealth", 42)
               when "illuminate"
                 SpellEffect.new("Light", 10)
               when "fireball"
                 SpellEffect.new("Damage", 25)
               else
                 SpellEffect.new("Unknown", 0)
               end
      
      spell = Spell.new(caster_uuid, spell_name, effect)
      
      # Find or create coordinate log entry
      existing_log = @game_state.log.find { |log| log.coordinates == coord_array }
      if existing_log
        index = @game_state.log.index!(existing_log)
        new_spells = existing_log.spells_cast + [spell]
        @game_state.log[index] = CoordinateLog.new(coord_array, existing_log.player, new_spells)
      else
        @game_state.log << CoordinateLog.new(coord_array, nil, [spell])
      end
      
      save_game_state
    end
    
    def handle_command(uuid : String, command : String)
      parts = command.split(" ", 2)
      cmd = parts[0]?.try(&.downcase)
      args = parts[1]?
      
      # Log command execution
      timestamp = Time.local.to_s("%Y-%m-%d %H:%M:%S")
      player_name = @player_names[uuid]? || @game_state.players[uuid]?.try(&.name) || "Unknown"
      puts "[#{timestamp}] Command executed - UUID: #{uuid}, Name: #{player_name}, Command: #{command}"
      
      case cmd
      when "/alias"
        if args && !args.empty?
          set_player_name(uuid, args)
          player_name = @player_names[uuid]? || uuid
          broadcast_message("#{player_name} changed their name to #{args}")
        end
      when "/say"
        if args && !args.empty?
          player_name = @player_names[uuid]? || uuid
          broadcast_message("#{player_name}: #{args}")
        end
      when "/cast"
        if args && !args.empty?
          spell_parts = args.split(" ", 2)
          spell_name = spell_parts[0]?
          coords_str = spell_parts[1]?
          
          if spell_name && coords_str
            coords_parts = coords_str.split(",")
            if coords_parts.size == 2
              begin
                x = coords_parts[0].strip.to_i
                y = coords_parts[1].strip.to_i
                coordinates = Coordinates.new(x, y)
                cast_spell(uuid, spell_name, coordinates)
                player_name = @player_names[uuid]? || uuid
                broadcast_message("#{player_name} cast #{spell_name} at #{coordinates}")
              rescue
                # Invalid coordinates
                begin
                  @players[uuid].send("Invalid coordinates")
                rescue
                  remove_player(uuid)
                end
              end
            end
          end
        end
      when "/witness"
        begin
          @players[uuid].send(@game_state.to_pretty_json)
        rescue
          remove_player(uuid)
        end
      end
    end
  end
end

game = GameServer::Game.new

ws "/" do |socket, context|
  uuid = ""
  
  socket.on_message do |message|
    if uuid.empty?
      # First message should contain UUID for reconnection or be empty for new player
      if message.empty?
        uuid = game.add_player(socket)
        if uuid.empty?
          socket.send("Server full")
          socket.close
        else
          coords = game.player_positions[uuid]
          socket.send("Welcome! Your UUID: #{uuid}, Coordinates: #{coords}")
        end
      else
        # Try to reconnect with provided UUID
        if game.reconnect_player(socket, message)
          uuid = message
          coords = game.player_positions[uuid]
          socket.send("Reconnected! UUID: #{uuid}, Coordinates: #{coords}")
        else
          # Invalid UUID, treat as new player
          uuid = game.add_player(socket)
          if uuid.empty?
            socket.send("Server full")
            socket.close
          else
            coords = game.player_positions[uuid]
            socket.send("Welcome! Your UUID: #{uuid}, Coordinates: #{coords}")
          end
        end
      end
    else
      # Handle game commands
      game.handle_command(uuid, message)
    end
  end
  
  socket.on_close do |code, message|
    game.remove_player(uuid) unless uuid.empty?
  end
end

Kemal.run