require "json"

module GameServer
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
end
