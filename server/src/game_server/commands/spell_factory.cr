require "../models/spell"

module GameServer
  module SpellFactory
    def self.create_effect(spell_name : String) : SpellEffect
      case spell_name.downcase
      when "shield"
        SpellEffect.new("IncreaseHealth", 42)
      when "illuminate"
        SpellEffect.new("Light", 10)
      when "fireball"
        SpellEffect.new("Damage", 25)
      else
        SpellEffect.new("Unknown", 0)
      end
    end
  end
end
