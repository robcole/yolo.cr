require "json"
require "./coordinate_attributes"

module GameServer
  struct SpellEffect
    include JSON::Serializable

    getter type : String
    getter amount : Int32
    getter dice_roll : Int32
    getter attribute_changes : AttributeChanges

    def initialize(@type : String, @amount : Int32, @dice_roll : Int32, @attribute_changes : AttributeChanges)
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
end
