require "json"

module GameServer
  struct CoordinateAttributes
    include JSON::Serializable

    getter constitution : Int32
    getter health : Int32
    getter intelligence : Int32
    getter luminosity : Int32
    getter speed : Int32

    def initialize(@constitution : Int32 = 0,
                   @health : Int32 = 0,
                   @intelligence : Int32 = 0,
                   @luminosity : Int32 = 0,
                   @speed : Int32 = 0)
    end

    # Apply attribute changes from spell effects
    def apply_changes(changes : AttributeChanges) : CoordinateAttributes
      CoordinateAttributes.new(
        constitution: Math.max(0, @constitution + changes.constitution),
        health: Math.max(0, @health + changes.health),
        intelligence: Math.max(0, @intelligence + changes.intelligence),
        luminosity: Math.max(0, @luminosity + changes.luminosity),
        speed: Math.max(0, @speed + changes.speed)
      )
    end

    def to_s(io)
      attributes = "Constitution: #{@constitution}, Health: #{@health}, Intelligence: #{@intelligence}, " +
                   "Luminosity: #{@luminosity}, Speed: #{@speed}"
      io << attributes
    end
  end

  struct AttributeChanges
    include JSON::Serializable

    getter constitution : Int32
    getter health : Int32
    getter intelligence : Int32
    getter luminosity : Int32
    getter speed : Int32

    def initialize(@constitution : Int32 = 0,
                   @health : Int32 = 0,
                   @intelligence : Int32 = 0,
                   @luminosity : Int32 = 0,
                   @speed : Int32 = 0)
    end
  end
end
