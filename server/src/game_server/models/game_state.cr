require "json"
require "./spell"
require "./coordinate_attributes"
require "./player"

module GameServer
  struct CoordinateLog
    include JSON::Serializable

    getter coordinates : Array(Int32)
    getter player : String?
    getter spells_cast : Array(Spell)
    getter attributes : CoordinateAttributes

    def initialize(@coordinates : Array(Int32),
                   @player : String? = nil,
                   @spells_cast = [] of Spell,
                   @attributes : CoordinateAttributes = CoordinateAttributes.new)
      @attributes = attributes
    end

    # Apply a spell effect to this coordinate's attributes
    def apply_spell_effect(spell : Spell) : CoordinateLog
      new_attributes = @attributes.apply_changes(spell.effect.attribute_changes)
      new_spells = @spells_cast + [spell]

      CoordinateLog.new(@coordinates, @player, new_spells, new_attributes)
    end
  end

  struct GameState
    include JSON::Serializable

    getter log : Array(CoordinateLog)
    getter players : Hash(String, Player)
    getter coordinate_attributes : Hash(String, CoordinateAttributes)

    def initialize(@log = [] of CoordinateLog,
                   @players = {} of String => Player,
                   @coordinate_attributes = {} of String => CoordinateAttributes)
    end

    # Get coordinate key for hash lookup
    def self.coordinate_key(x : Int32, y : Int32) : String
      "#{x},#{y}"
    end

    # Get attributes for a coordinate
    def get_coordinate_attributes(x : Int32, y : Int32) : CoordinateAttributes
      key = GameState.coordinate_key(x, y)
      @coordinate_attributes[key]? || CoordinateAttributes.new
    end

    # Update attributes for a coordinate
    def set_coordinate_attributes(x : Int32, y : Int32, attributes : CoordinateAttributes)
      key = GameState.coordinate_key(x, y)
      @coordinate_attributes[key] = attributes
    end
  end
end
