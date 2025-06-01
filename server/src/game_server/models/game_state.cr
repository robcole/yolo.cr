require "json"
require "./spell"

module GameServer
  struct CoordinateLog
    include JSON::Serializable

    getter coordinates : Array(Int32)
    getter player : String?
    getter spells_cast : Array(Spell)

    def initialize(@coordinates : Array(Int32), @player : String? = nil, @spells_cast = [] of Spell)
    end
  end

  struct GameState
    include JSON::Serializable

    getter log : Array(CoordinateLog)
    getter players : Hash(String, Player)

    def initialize(@log = [] of CoordinateLog, @players = {} of String => Player)
    end
  end
end
