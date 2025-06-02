require "json"
require "colorize"
require "../models/*"

module GameServer
  class GameStateManager
    GAME_STATE_FILE = "game_state.json"

    def self.load : GameState
      return GameState.new unless File.exists?(GAME_STATE_FILE)
      load_from_file
    end

    def self.save(game_state : GameState)
      File.write(GAME_STATE_FILE, game_state.to_json)
    end

    private def self.load_from_file : GameState
      content = File.read(GAME_STATE_FILE)
      GameState.from_json(content)
    rescue ex : JSON::SerializableError
      handle_corrupt_file
      GameState.new
    end

    private def self.handle_corrupt_file
      File.delete(GAME_STATE_FILE)
      puts "🚨 DEBUG: Incompatible game state format detected!".colorize(:red).bold
      puts "🗑️ Old file deleted, starting fresh...".colorize(:green)
    end
  end
end
