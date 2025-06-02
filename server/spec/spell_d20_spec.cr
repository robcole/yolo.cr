require "./spec_helper"

describe "D20 Spell System" do
  describe "CoordinateAttributes" do
    it "initializes with default zero values" do
      attrs = GameServer::CoordinateAttributes.new
      attrs.luminosity.should eq(0)
      attrs.constitution.should eq(0)
      attrs.health.should eq(0)
      attrs.intelligence.should eq(0)
      attrs.speed.should eq(0)
    end

    it "initializes with custom values" do
      attrs = GameServer::CoordinateAttributes.new(
        luminosity: 10,
        constitution: 15,
        health: 20,
        intelligence: 12,
        speed: 8
      )
      attrs.luminosity.should eq(10)
      attrs.constitution.should eq(15)
      attrs.health.should eq(20)
      attrs.intelligence.should eq(12)
      attrs.speed.should eq(8)
    end

    it "applies positive attribute changes correctly" do
      initial_attrs = GameServer::CoordinateAttributes.new(
        luminosity: 5,
        constitution: 10,
        health: 15,
        intelligence: 8,
        speed: 12
      )

      changes = GameServer::AttributeChanges.new(
        luminosity: 3,
        constitution: 5,
        health: 2,
        intelligence: 7,
        speed: 1
      )

      new_attrs = initial_attrs.apply_changes(changes)
      new_attrs.luminosity.should eq(8)
      new_attrs.constitution.should eq(15)
      new_attrs.health.should eq(17)
      new_attrs.intelligence.should eq(15)
      new_attrs.speed.should eq(13)
    end

    it "prevents negative attributes by capping at zero" do
      initial_attrs = GameServer::CoordinateAttributes.new(
        luminosity: 5,
        constitution: 3,
        health: 8,
        intelligence: 2,
        speed: 6
      )

      changes = GameServer::AttributeChanges.new(
        luminosity: -10,
        constitution: -5,
        health: -15,
        intelligence: -1,
        speed: -2
      )

      new_attrs = initial_attrs.apply_changes(changes)
      new_attrs.luminosity.should eq(0)
      new_attrs.constitution.should eq(0)
      new_attrs.health.should eq(0)
      new_attrs.intelligence.should eq(1)
      new_attrs.speed.should eq(4)
    end
  end

  describe "SpellFactory D20 mechanics" do
    it "creates spell effects with D20 dice rolls" do
      effect = GameServer::SpellFactory.create_effect("fireball")

      effect.dice_roll.should be >= 1
      effect.dice_roll.should be <= 20
      effect.type.should eq("Damage")
      effect.amount.should be < 0 # Fireball causes damage (negative amount)
    end

    it "creates different effects for different spells" do
      shield_effect = GameServer::SpellFactory.create_effect("shield")
      illuminate_effect = GameServer::SpellFactory.create_effect("illuminate")
      fireball_effect = GameServer::SpellFactory.create_effect("fireball")

      shield_effect.type.should eq("Protection")
      illuminate_effect.type.should eq("Light")
      fireball_effect.type.should eq("Damage")

      # Each should have different attribute effects
      shield_effect.attribute_changes.constitution.should be > 0
      shield_effect.attribute_changes.health.should be > 0

      illuminate_effect.attribute_changes.luminosity.should be > 0
      illuminate_effect.attribute_changes.intelligence.should be >= 0

      fireball_effect.attribute_changes.health.should be < 0
      fireball_effect.attribute_changes.constitution.should be <= 0
    end

    it "creates consistent effects for unknown spells" do
      unknown_effect = GameServer::SpellFactory.create_effect("unknown_spell")

      unknown_effect.type.should eq("Unknown")
      unknown_effect.amount.should eq(0)
      unknown_effect.attribute_changes.luminosity.should eq(0)
      unknown_effect.attribute_changes.constitution.should eq(0)
      unknown_effect.attribute_changes.health.should eq(0)
      unknown_effect.attribute_changes.intelligence.should eq(0)
      unknown_effect.attribute_changes.speed.should eq(0)
    end

    it "generates variable effects based on dice rolls" do
      # Test multiple rolls to ensure variability
      effects = Array(GameServer::SpellEffect).new
      20.times do
        effects << GameServer::SpellFactory.create_effect("shield")
      end

      # Should have different dice rolls
      dice_rolls = effects.map(&.dice_roll).uniq
      dice_rolls.size.should be > 1

      # Should have different amounts based on different rolls
      amounts = effects.map(&.amount).uniq
      amounts.size.should be > 1
    end
  end

  describe "Spell attribute effects" do
    it "shield spell increases constitution and health" do
      effect = GameServer::SpellFactory.create_effect("shield")

      effect.attribute_changes.constitution.should be > 0
      effect.attribute_changes.health.should be > 0
      effect.attribute_changes.luminosity.should eq(0)
      effect.attribute_changes.intelligence.should eq(0)
      effect.attribute_changes.speed.should eq(0)
    end

    it "illuminate spell increases luminosity and intelligence" do
      effect = GameServer::SpellFactory.create_effect("illuminate")

      effect.attribute_changes.luminosity.should be > 0
      effect.attribute_changes.intelligence.should be >= 0
      effect.attribute_changes.constitution.should eq(0)
      effect.attribute_changes.health.should eq(0)
      effect.attribute_changes.speed.should eq(0)
    end

    it "fireball spell damages health and constitution but may increase speed" do
      effect = GameServer::SpellFactory.create_effect("fireball")

      effect.attribute_changes.health.should be < 0
      effect.attribute_changes.constitution.should be <= 0
      effect.attribute_changes.speed.should be >= 0 # Fight or flight response
      effect.attribute_changes.luminosity.should eq(0)
      effect.attribute_changes.intelligence.should eq(0)
    end

    it "haste spell increases speed but costs constitution" do
      effect = GameServer::SpellFactory.create_effect("haste")

      effect.attribute_changes.speed.should be > 0
      effect.attribute_changes.constitution.should be <= 0
      effect.attribute_changes.health.should eq(0)
      effect.attribute_changes.luminosity.should eq(0)
      effect.attribute_changes.intelligence.should eq(0)
    end

    it "wisdom spell increases intelligence" do
      effect = GameServer::SpellFactory.create_effect("wisdom")

      effect.attribute_changes.intelligence.should be > 0
      effect.attribute_changes.constitution.should eq(0)
      effect.attribute_changes.health.should eq(0)
      effect.attribute_changes.luminosity.should eq(0)
      effect.attribute_changes.speed.should eq(0)
    end
  end

  describe "GameState coordinate attribute tracking" do
    it "initializes with empty coordinate attributes" do
      game_state = GameServer::GameState.new
      attrs = game_state.get_coordinate_attributes(0, 0)

      attrs.luminosity.should eq(0)
      attrs.constitution.should eq(0)
      attrs.health.should eq(0)
      attrs.intelligence.should eq(0)
      attrs.speed.should eq(0)
    end

    it "stores and retrieves coordinate attributes" do
      game_state = GameServer::GameState.new
      test_attrs = GameServer::CoordinateAttributes.new(
        luminosity: 15,
        constitution: 20,
        health: 25,
        intelligence: 18,
        speed: 12
      )

      game_state.set_coordinate_attributes(10, -5, test_attrs)
      retrieved_attrs = game_state.get_coordinate_attributes(10, -5)

      retrieved_attrs.luminosity.should eq(15)
      retrieved_attrs.constitution.should eq(20)
      retrieved_attrs.health.should eq(25)
      retrieved_attrs.intelligence.should eq(18)
      retrieved_attrs.speed.should eq(12)
    end

    it "handles different coordinates independently" do
      game_state = GameServer::GameState.new

      attrs1 = GameServer::CoordinateAttributes.new(luminosity: 10, health: 15)
      attrs2 = GameServer::CoordinateAttributes.new(constitution: 8, intelligence: 12)

      game_state.set_coordinate_attributes(0, 0, attrs1)
      game_state.set_coordinate_attributes(5, 10, attrs2)

      retrieved1 = game_state.get_coordinate_attributes(0, 0)
      retrieved2 = game_state.get_coordinate_attributes(5, 10)

      retrieved1.luminosity.should eq(10)
      retrieved1.health.should eq(15)
      retrieved1.constitution.should eq(0)

      retrieved2.constitution.should eq(8)
      retrieved2.intelligence.should eq(12)
      retrieved2.luminosity.should eq(0)
    end
  end

  describe "Integration: Spell casting affects coordinate attributes" do
    it "applies spell effects to coordinate attributes" do
      game_state = GameServer::GameState.new

      # Start with some base attributes
      initial_attrs = GameServer::CoordinateAttributes.new(
        luminosity: 5,
        constitution: 10,
        health: 15,
        intelligence: 8,
        speed: 6
      )
      game_state.set_coordinate_attributes(0, 0, initial_attrs)

      # Cast a shield spell
      shield_effect = GameServer::SpellFactory.create_effect("shield")
      spell = GameServer::Spell.new("player1", "shield", shield_effect)

      # Apply the spell effect
      current_attrs = game_state.get_coordinate_attributes(0, 0)
      new_attrs = current_attrs.apply_changes(shield_effect.attribute_changes)
      game_state.set_coordinate_attributes(0, 0, new_attrs)

      # Verify the changes
      final_attrs = game_state.get_coordinate_attributes(0, 0)
      final_attrs.constitution.should be > initial_attrs.constitution
      final_attrs.health.should be > initial_attrs.health
      final_attrs.luminosity.should eq(initial_attrs.luminosity) # Unchanged
    end

    it "accumulates multiple spell effects on the same coordinate" do
      game_state = GameServer::GameState.new

      # Cast illuminate spell
      illuminate_effect = GameServer::SpellFactory.create_effect("illuminate")
      current_attrs = game_state.get_coordinate_attributes(5, 5)
      new_attrs = current_attrs.apply_changes(illuminate_effect.attribute_changes)
      game_state.set_coordinate_attributes(5, 5, new_attrs)

      after_illuminate = game_state.get_coordinate_attributes(5, 5)

      # Cast wisdom spell on same coordinate
      wisdom_effect = GameServer::SpellFactory.create_effect("wisdom")
      current_attrs = game_state.get_coordinate_attributes(5, 5)
      final_attrs = current_attrs.apply_changes(wisdom_effect.attribute_changes)
      game_state.set_coordinate_attributes(5, 5, final_attrs)

      final_result = game_state.get_coordinate_attributes(5, 5)

      # Should have accumulated both effects
      final_result.luminosity.should eq(after_illuminate.luminosity)      # From illuminate
      final_result.intelligence.should be > after_illuminate.intelligence # From both spells
    end
  end
end
