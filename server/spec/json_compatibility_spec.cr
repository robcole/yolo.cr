require "./spec_helper"

describe "JSON Format Handling" do
  describe "Current JSON format loading" do
    it "loads current format JSON with all D20 fields" do
      fixture_path = File.expand_path("fixtures/spell_effect_d20.json", __DIR__)
      current_json = File.read(fixture_path)

      effect = GameServer::SpellEffect.from_json(current_json)
      effect.type.should eq("Damage")
      effect.amount.should eq(25)
      effect.dice_roll.should eq(15)
      effect.attribute_changes.health.should eq(-5)
    end

    it "loads current format CoordinateLog with attributes" do
      fixture_path = File.expand_path("fixtures/coordinate_log_with_attributes.json", __DIR__)
      current_json = File.read(fixture_path)

      log = GameServer::CoordinateLog.from_json(current_json)
      log.coordinates.should eq([42, 42])
      log.attributes.luminosity.should eq(10)
      log.attributes.constitution.should eq(15)
      log.attributes.health.should eq(20)
      log.attributes.intelligence.should eq(12)
      log.attributes.speed.should eq(8)
    end
  end
end
