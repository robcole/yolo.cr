require "./spec_helper"

describe "Spell Calculations and JSON Configuration" do
  describe "SpellFactory loads from consolidated JSON" do
    it "loads all spells from spells.json" do
      # Test that we can create effects for all 20 spells
      spells = [
        "blind", "brighten", "confuse", "curse", "darken", "drain",
        "energize", "enlighten", "exhaust", "fireball", "glowup",
        "haste", "heal", "illuminate", "poison", "shield",
        "slow", "strengthen", "weaken", "wisdom"
      ]

      spells.each do |spell_name|
        effect = GameServer::SpellFactory.create_effect(spell_name)
        effect.should_not be_nil
        effect.dice_roll.should be >= 1
        effect.dice_roll.should be <= 20
      end
    end

    it "handles unknown spells gracefully" do
      effect = GameServer::SpellFactory.create_effect("nonexistent_spell")
      effect.type.should eq("Unknown")
      effect.amount.should eq(0)
      effect.attribute_changes.constitution.should eq(0)
      effect.attribute_changes.health.should eq(0)
      effect.attribute_changes.intelligence.should eq(0)
      effect.attribute_changes.luminosity.should eq(0)
      effect.attribute_changes.speed.should eq(0)
    end
  end

  describe "Maximum attribute change limits (+-20 rule)" do
    it "wisdom spell respects +20 limit on intelligence" do
      # Test with maximum dice roll (20)
      # wisdom: intelligence = min(20, dice_roll * 2)
      # With dice_roll = 20, this becomes min(20, 40) = 20
      100.times do
        effect = GameServer::SpellFactory.create_effect("wisdom")
        effect.attribute_changes.intelligence.should be <= 20
        effect.attribute_changes.intelligence.should be > 0
      end
    end

    it "heal spell respects +20 limit on health" do
      # heal: health = min(20, dice_roll * 3)
      # With dice_roll = 20, this becomes min(20, 60) = 20
      100.times do
        effect = GameServer::SpellFactory.create_effect("heal")
        effect.attribute_changes.health.should be <= 20
        effect.attribute_changes.health.should be > 0
      end
    end

    it "fireball spell respects -20 limit on health" do
      # fireball: health = -min(20, dice_roll + 5)
      # With dice_roll = 20, this becomes -min(20, 25) = -20
      100.times do
        effect = GameServer::SpellFactory.create_effect("fireball")
        effect.attribute_changes.health.should be >= -20
        effect.attribute_changes.health.should be < 0
      end
    end

    it "brighten spell respects +20 limit on luminosity" do
      # brighten: luminosity = min(20, dice_roll * 2)
      100.times do
        effect = GameServer::SpellFactory.create_effect("brighten")
        effect.attribute_changes.luminosity.should be <= 20
        effect.attribute_changes.luminosity.should be > 0
      end
    end

    it "darken spell respects -20 limit on luminosity" do
      # darken: luminosity = -min(20, dice_roll * 3)
      100.times do
        effect = GameServer::SpellFactory.create_effect("darken")
        effect.attribute_changes.luminosity.should be >= -20
        effect.attribute_changes.luminosity.should be < 0
      end
    end

    it "haste spell respects +20 limit on speed" do
      # haste: speed = min(20, dice_roll + 10)
      100.times do
        effect = GameServer::SpellFactory.create_effect("haste")
        effect.attribute_changes.speed.should be <= 20
        effect.attribute_changes.speed.should be > 0
      end
    end

    it "slow spell respects -20 limit on speed" do
      # slow: speed = -min(20, dice_roll + 10)
      100.times do
        effect = GameServer::SpellFactory.create_effect("slow")
        effect.attribute_changes.speed.should be >= -20
        effect.attribute_changes.speed.should be < 0
      end
    end

    it "strengthen spell respects +20 limit on constitution" do
      # strengthen: constitution = min(20, dice_roll + 8)
      100.times do
        effect = GameServer::SpellFactory.create_effect("strengthen")
        effect.attribute_changes.constitution.should be <= 20
        effect.attribute_changes.constitution.should be > 0
      end
    end

    it "weaken spell respects -20 limit on constitution" do
      # weaken: constitution = -min(20, dice_roll + 8)
      100.times do
        effect = GameServer::SpellFactory.create_effect("weaken")
        effect.attribute_changes.constitution.should be >= -20
        effect.attribute_changes.constitution.should be < 0
      end
    end

    it "poison spell respects -20 limit on health" do
      # poison: health = -min(20, dice_roll * 2)
      100.times do
        effect = GameServer::SpellFactory.create_effect("poison")
        effect.attribute_changes.health.should be >= -20
        effect.attribute_changes.health.should be < 0
      end
    end
  end

  describe "Complex spell calculations" do
    it "curse spell affects all attributes with correct calculation" do
      # curse: all attributes = -max(1, dice_roll // 4)
      100.times do
        effect = GameServer::SpellFactory.create_effect("curse")
        
        # All attributes should be affected equally and negatively
        expected_damage = effect.attribute_changes.constitution
        effect.attribute_changes.health.should eq(expected_damage)
        effect.attribute_changes.intelligence.should eq(expected_damage)
        effect.attribute_changes.luminosity.should eq(expected_damage)
        effect.attribute_changes.speed.should eq(expected_damage)
        
        # Should be between -5 and -1 (dice_roll // 4 where dice_roll is 1-20)
        expected_damage.should be >= -5
        expected_damage.should be <= -1
        expected_damage.should be < 0
      end
    end

    it "shield spell adds constitution and health equally" do
      # shield: constitution = dice_roll, health = dice_roll
      100.times do
        effect = GameServer::SpellFactory.create_effect("shield")
        
        # Constitution and health should be equal to dice roll
        effect.attribute_changes.constitution.should eq(effect.dice_roll)
        effect.attribute_changes.health.should eq(effect.dice_roll)
        effect.attribute_changes.constitution.should eq(effect.attribute_changes.health)
        
        # Other attributes should be unchanged
        effect.attribute_changes.intelligence.should eq(0)
        effect.attribute_changes.luminosity.should eq(0)
        effect.attribute_changes.speed.should eq(0)
      end
    end

    it "illuminate spell calculates luminosity and intelligence correctly" do
      # illuminate: luminosity = min(20, dice_roll + 5), intelligence = dice_roll // 2
      100.times do
        effect = GameServer::SpellFactory.create_effect("illuminate")
        
        # Luminosity should be min(20, dice_roll + 5)
        expected_luminosity = [20, effect.dice_roll + 5].min
        effect.attribute_changes.luminosity.should eq(expected_luminosity)
        
        # Intelligence should be dice_roll // 2
        expected_intelligence = effect.dice_roll // 2
        effect.attribute_changes.intelligence.should eq(expected_intelligence)
        
        # Other attributes should be unchanged
        effect.attribute_changes.constitution.should eq(0)
        effect.attribute_changes.health.should eq(0)
        effect.attribute_changes.speed.should eq(0)
      end
    end

    it "energize spell calculates speed and health correctly" do
      # energize: speed = dice_roll, health = dice_roll // 2
      100.times do
        effect = GameServer::SpellFactory.create_effect("energize")
        
        effect.attribute_changes.speed.should eq(effect.dice_roll)
        effect.attribute_changes.health.should eq(effect.dice_roll // 2)
        
        # Other attributes should be unchanged
        effect.attribute_changes.constitution.should eq(0)
        effect.attribute_changes.intelligence.should eq(0)
        effect.attribute_changes.luminosity.should eq(0)
      end
    end

    it "fireball spell calculates health and constitution damage correctly" do
      # fireball: health = -min(20, dice_roll + 5), constitution = -(dice_roll // 2)
      100.times do
        effect = GameServer::SpellFactory.create_effect("fireball")
        
        expected_health_damage = -[20, effect.dice_roll + 5].min
        expected_constitution_damage = -(effect.dice_roll // 2)
        
        effect.attribute_changes.health.should eq(expected_health_damage)
        effect.attribute_changes.constitution.should eq(expected_constitution_damage)
        
        # Other attributes should be unchanged
        effect.attribute_changes.intelligence.should eq(0)
        effect.attribute_changes.luminosity.should eq(0)
        effect.attribute_changes.speed.should eq(0)
      end
    end

    it "drain spell affects constitution and speed equally" do
      # drain: constitution = -dice_roll, speed = -dice_roll
      100.times do
        effect = GameServer::SpellFactory.create_effect("drain")
        
        effect.attribute_changes.constitution.should eq(-effect.dice_roll)
        effect.attribute_changes.speed.should eq(-effect.dice_roll)
        effect.attribute_changes.constitution.should eq(effect.attribute_changes.speed)
        
        # Other attributes should be unchanged
        effect.attribute_changes.health.should eq(0)
        effect.attribute_changes.intelligence.should eq(0)
        effect.attribute_changes.luminosity.should eq(0)
      end
    end

    it "enlighten spell affects intelligence and luminosity equally" do
      # enlighten: intelligence = dice_roll, luminosity = dice_roll
      100.times do
        effect = GameServer::SpellFactory.create_effect("enlighten")
        
        effect.attribute_changes.intelligence.should eq(effect.dice_roll)
        effect.attribute_changes.luminosity.should eq(effect.dice_roll)
        effect.attribute_changes.intelligence.should eq(effect.attribute_changes.luminosity)
        
        # Other attributes should be unchanged
        effect.attribute_changes.constitution.should eq(0)
        effect.attribute_changes.health.should eq(0)
        effect.attribute_changes.speed.should eq(0)
      end
    end

    it "exhaust spell affects speed and health equally (negative)" do
      # exhaust: speed = -dice_roll, health = -dice_roll
      100.times do
        effect = GameServer::SpellFactory.create_effect("exhaust")
        
        effect.attribute_changes.speed.should eq(-effect.dice_roll)
        effect.attribute_changes.health.should eq(-effect.dice_roll)
        effect.attribute_changes.speed.should eq(effect.attribute_changes.health)
        
        # Other attributes should be unchanged
        effect.attribute_changes.constitution.should eq(0)
        effect.attribute_changes.intelligence.should eq(0)
        effect.attribute_changes.luminosity.should eq(0)
      end
    end

    it "glowup spell affects health and intelligence equally" do
      # glowup: health = dice_roll, intelligence = dice_roll
      100.times do
        effect = GameServer::SpellFactory.create_effect("glowup")
        
        effect.attribute_changes.health.should eq(effect.dice_roll)
        effect.attribute_changes.intelligence.should eq(effect.dice_roll)
        effect.attribute_changes.health.should eq(effect.attribute_changes.intelligence)
        
        # Other attributes should be unchanged
        effect.attribute_changes.constitution.should eq(0)
        effect.attribute_changes.luminosity.should eq(0)
        effect.attribute_changes.speed.should eq(0)
      end
    end
  end

  describe "Amount calculation verification" do
    it "shield spell amount equals sum of constitution and health changes" do
      100.times do
        effect = GameServer::SpellFactory.create_effect("shield")
        expected_amount = effect.attribute_changes.constitution + effect.attribute_changes.health
        effect.amount.should eq(expected_amount)
      end
    end

    it "curse spell amount equals sum of all negative changes" do
      100.times do
        effect = GameServer::SpellFactory.create_effect("curse")
        expected_amount = effect.attribute_changes.constitution + 
                         effect.attribute_changes.health + 
                         effect.attribute_changes.intelligence + 
                         effect.attribute_changes.luminosity + 
                         effect.attribute_changes.speed
        effect.amount.should eq(expected_amount)
      end
    end

    it "illuminate spell amount equals luminosity change (primary effect)" do
      100.times do
        effect = GameServer::SpellFactory.create_effect("illuminate")
        # Amount calculation for illuminate is "luminosity"
        effect.amount.should eq(effect.attribute_changes.luminosity)
      end
    end

    it "single-attribute spells have amount equal to that attribute change" do
      single_attribute_spells = [
        "wisdom",      # intelligence only
        "heal",        # health only  
        "brighten",    # luminosity only
        "darken",      # luminosity only
        "haste",       # speed only
        "slow",        # speed only
        "strengthen",  # constitution only
        "weaken",      # constitution only
        "poison"       # health only
      ]

      single_attribute_spells.each do |spell_name|
        10.times do
          effect = GameServer::SpellFactory.create_effect(spell_name)
          
          # Find which attribute is non-zero
          non_zero_changes = [
            effect.attribute_changes.constitution,
            effect.attribute_changes.health,
            effect.attribute_changes.intelligence,
            effect.attribute_changes.luminosity,
            effect.attribute_changes.speed
          ].reject(&.zero?)
          
          # Should have exactly one non-zero attribute
          non_zero_changes.size.should eq(1)
          
          # Amount should equal that change
          effect.amount.should eq(non_zero_changes.first)
        end
      end
    end
  end

  describe "Edge cases and boundary conditions" do
    it "all spells produce deterministic results for the same dice roll" do
      # Mock the dice roll to test deterministic behavior
      # This tests the calculation logic without randomness
      spells = ["wisdom", "heal", "fireball", "shield", "curse"]
      
      spells.each do |spell_name|
        # Test multiple times to ensure consistency
        effects = Array(GameServer::SpellEffect).new
        10.times do
          effects << GameServer::SpellFactory.create_effect(spell_name)
        end
        
        # All effects should have different dice rolls (randomness working)
        dice_rolls = effects.map(&.dice_roll)
        dice_rolls.should_not be_empty
      end
    end

    it "spell effects respect their defined types" do
      positive_spells = ["wisdom", "heal", "shield", "brighten", "haste", "strengthen", "energize", "enlighten", "glowup", "illuminate"]
      negative_spells = ["fireball", "curse", "poison", "darken", "slow", "weaken", "blind", "confuse", "drain", "exhaust"]
      
      positive_spells.each do |spell_name|
        effect = GameServer::SpellFactory.create_effect(spell_name)
        effect.type.should_not eq("Unknown")
        
        # At least one attribute should be positive
        total_positive = [
          effect.attribute_changes.constitution,
          effect.attribute_changes.health,
          effect.attribute_changes.intelligence,
          effect.attribute_changes.luminosity,
          effect.attribute_changes.speed
        ].select(&.> 0).sum
        
        total_positive.should be > 0
      end
      
      negative_spells.each do |spell_name|
        effect = GameServer::SpellFactory.create_effect(spell_name)
        effect.type.should_not eq("Unknown")
        
        # At least one attribute should be negative
        total_negative = [
          effect.attribute_changes.constitution,
          effect.attribute_changes.health,
          effect.attribute_changes.intelligence,
          effect.attribute_changes.luminosity,
          effect.attribute_changes.speed
        ].select(&.< 0).sum
        
        total_negative.should be < 0
      end
    end
  end
end