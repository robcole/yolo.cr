require "../models/spell"

module GameServer
  module SpellFactory
    private def self.roll_d20 : Int32
      Random.rand(1..20)
    end

    private def self.calculate_effect(spell_name : String, dice_roll : Int32) : {String, Int32, AttributeChanges}
      spell_type = spell_name.downcase
      positive_effect(spell_type, dice_roll) || negative_effect(spell_type, dice_roll) || unknown_effect
    end

    private def self.positive_effect(spell_name : String, dice_roll : Int32) : {String, Int32, AttributeChanges}?
      basic_positive_effect(spell_name, dice_roll) || advanced_positive_effect(spell_name, dice_roll)
    end

    private def self.negative_effect(spell_name : String, dice_roll : Int32) : {String, Int32, AttributeChanges}?
      basic_negative_effect(spell_name, dice_roll) || advanced_negative_effect(spell_name, dice_roll)
    end

    private def self.basic_positive_effect(spell_name : String, dice_roll : Int32) : {String, Int32, AttributeChanges}?
      case spell_name
      when "shield"     then shield_effect(dice_roll)
      when "illuminate" then illuminate_effect(dice_roll)
      when "haste"      then haste_effect(dice_roll)
      when "wisdom"     then wisdom_effect(dice_roll)
      when "heal"       then heal_effect(dice_roll)
      else                   nil
      end
    end

    private def self.advanced_positive_effect(spell_name : String, dice_roll : Int32) : {String, Int32, AttributeChanges}?
      case spell_name
      when "strengthen" then strengthen_effect(dice_roll)
      when "brighten"   then brighten_effect(dice_roll)
      when "energize"   then energize_effect(dice_roll)
      when "enlighten"  then enlighten_effect(dice_roll)
      when "glowup"     then glowup_effect(dice_roll)
      else                   nil
      end
    end

    private def self.basic_negative_effect(spell_name : String, dice_roll : Int32) : {String, Int32, AttributeChanges}?
      case spell_name
      when "fireball" then fireball_effect(dice_roll)
      when "curse"    then curse_effect(dice_roll)
      when "drain"    then drain_effect(dice_roll)
      when "blind"    then blind_effect(dice_roll)
      when "poison"   then poison_effect(dice_roll)
      else                 nil
      end
    end

    private def self.advanced_negative_effect(spell_name : String, dice_roll : Int32) : {String, Int32, AttributeChanges}?
      case spell_name
      when "weaken"  then weaken_effect(dice_roll)
      when "slow"    then slow_effect(dice_roll)
      when "confuse" then confuse_effect(dice_roll)
      when "darken"  then darken_effect(dice_roll)
      when "exhaust" then exhaust_effect(dice_roll)
      else                nil
      end
    end

    private def self.shield_effect(dice_roll : Int32)
      boost = dice_roll
      changes = AttributeChanges.new(constitution: boost, health: boost)
      {"Protection", boost * 2, changes}
    end

    private def self.illuminate_effect(dice_roll : Int32)
      lum_boost = dice_roll + 5
      int_boost = dice_roll // 2
      changes = AttributeChanges.new(intelligence: int_boost, luminosity: lum_boost)
      {"Light", lum_boost, changes}
    end

    private def self.haste_effect(dice_roll : Int32)
      boost = dice_roll + 10
      changes = AttributeChanges.new(speed: boost)
      {"Speed", boost, changes}
    end

    private def self.wisdom_effect(dice_roll : Int32)
      boost = dice_roll * 2
      changes = AttributeChanges.new(intelligence: boost)
      {"Knowledge", boost, changes}
    end

    private def self.heal_effect(dice_roll : Int32)
      boost = dice_roll * 3
      changes = AttributeChanges.new(health: boost)
      {"Healing", boost, changes}
    end

    private def self.strengthen_effect(dice_roll : Int32)
      boost = dice_roll + 8
      changes = AttributeChanges.new(constitution: boost)
      {"Strength", boost, changes}
    end

    private def self.brighten_effect(dice_roll : Int32)
      boost = dice_roll * 2
      changes = AttributeChanges.new(luminosity: boost)
      {"Brightness", boost, changes}
    end

    private def self.energize_effect(dice_roll : Int32)
      speed_boost = dice_roll
      health_boost = dice_roll // 2
      changes = AttributeChanges.new(health: health_boost, speed: speed_boost)
      {"Energy", speed_boost + health_boost, changes}
    end

    private def self.enlighten_effect(dice_roll : Int32)
      boost = dice_roll
      changes = AttributeChanges.new(intelligence: boost, luminosity: boost)
      {"Enlightenment", boost * 2, changes}
    end

    private def self.glowup_effect(dice_roll : Int32)
      boost = dice_roll
      changes = AttributeChanges.new(health: boost, intelligence: boost)
      {"Enhancement", boost * 2, changes}
    end

    private def self.fireball_effect(dice_roll : Int32)
      health_dmg = -(dice_roll + 5)
      con_dmg = -(dice_roll // 2)
      changes = AttributeChanges.new(constitution: con_dmg, health: health_dmg)
      {"Damage", health_dmg + con_dmg, changes}
    end

    private def self.curse_effect(dice_roll : Int32)
      damage = -(Math.max(1, dice_roll // 4))
      changes = AttributeChanges.new(constitution: damage, health: damage, intelligence: damage, luminosity: damage, speed: damage)
      {"Curse", damage * 5, changes}
    end

    private def self.drain_effect(dice_roll : Int32)
      damage = -dice_roll
      changes = AttributeChanges.new(constitution: damage, speed: damage)
      {"Drain", damage * 2, changes}
    end

    private def self.blind_effect(dice_roll : Int32)
      lum_dmg = -(dice_roll * 2)
      int_dmg = -dice_roll
      changes = AttributeChanges.new(intelligence: int_dmg, luminosity: lum_dmg)
      {"Blindness", lum_dmg + int_dmg, changes}
    end

    private def self.poison_effect(dice_roll : Int32)
      damage = -(dice_roll * 2)
      changes = AttributeChanges.new(health: damage)
      {"Poison", damage, changes}
    end

    private def self.weaken_effect(dice_roll : Int32)
      damage = -(dice_roll + 8)
      changes = AttributeChanges.new(constitution: damage)
      {"Weakness", damage, changes}
    end

    private def self.slow_effect(dice_roll : Int32)
      damage = -(dice_roll + 10)
      changes = AttributeChanges.new(speed: damage)
      {"Slowness", damage, changes}
    end

    private def self.confuse_effect(dice_roll : Int32)
      int_dmg = -dice_roll
      con_dmg = -(dice_roll // 2)
      changes = AttributeChanges.new(constitution: con_dmg, intelligence: int_dmg)
      {"Confusion", int_dmg + con_dmg, changes}
    end

    private def self.darken_effect(dice_roll : Int32)
      damage = -(dice_roll * 3)
      changes = AttributeChanges.new(luminosity: damage)
      {"Darkness", damage, changes}
    end

    private def self.exhaust_effect(dice_roll : Int32)
      damage = -dice_roll
      changes = AttributeChanges.new(health: damage, speed: damage)
      {"Exhaustion", damage * 2, changes}
    end

    private def self.unknown_effect
      changes = AttributeChanges.new
      {"Unknown", 0, changes}
    end

    def self.create_effect(spell_name : String) : SpellEffect
      dice_roll = roll_d20
      effect_type, amount, attribute_changes = calculate_effect(spell_name, dice_roll)
      SpellEffect.new(effect_type, amount, dice_roll, attribute_changes)
    end
  end
end
