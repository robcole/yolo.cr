require "../models/spell"

module GameServer
  module SpellFactory
    # Roll a D20 die (1-20)
    private def self.roll_d20 : Int32
      Random.rand(1..20)
    end

    # Calculate spell effect and coordinate attribute changes based on D20 roll
    private def self.calculate_effect(spell_name : String, dice_roll : Int32) : {String, Int32, AttributeChanges}
      case spell_name.downcase
      when "shield"
        # Shield: Increases constitution and health based on roll
        constitution_boost = dice_roll
        health_boost = dice_roll * 2
        amount = constitution_boost + health_boost
        changes = AttributeChanges.new(constitution: constitution_boost, health: health_boost)
        {"Protection", amount, changes}
      when "illuminate"
        # Illuminate: Increases luminosity and intelligence based on roll
        luminosity_boost = dice_roll + 5
        intelligence_boost = dice_roll // 2
        amount = luminosity_boost
        changes = AttributeChanges.new(luminosity: luminosity_boost, intelligence: intelligence_boost)
        {"Light", amount, changes}
      when "fireball"
        # Fireball: Damages health and constitution, but increases speed (fight or flight)
        health_damage = -(dice_roll + 10)
        constitution_damage = -(dice_roll // 2)
        speed_boost = dice_roll // 4
        amount = -(health_damage.abs + constitution_damage.abs)
        changes = AttributeChanges.new(health: health_damage, constitution: constitution_damage, speed: speed_boost)
        {"Damage", amount, changes}
      when "haste"
        # Haste: Increases speed and reduces constitution (burning energy)
        speed_boost = dice_roll + 10
        constitution_cost = -(dice_roll // 3)
        amount = speed_boost
        changes = AttributeChanges.new(speed: speed_boost, constitution: constitution_cost)
        {"Speed", amount, changes}
      when "wisdom"
        # Wisdom: Increases intelligence significantly
        intelligence_boost = dice_roll * 2
        amount = intelligence_boost
        changes = AttributeChanges.new(intelligence: intelligence_boost)
        {"Knowledge", amount, changes}
      else
        changes = AttributeChanges.new
        {"Unknown", 0, changes}
      end
    end

    def self.create_effect(spell_name : String) : SpellEffect
      dice_roll = roll_d20
      effect_type, amount, attribute_changes = calculate_effect(spell_name, dice_roll)

      SpellEffect.new(effect_type, amount, dice_roll, attribute_changes)
    end
  end
end
