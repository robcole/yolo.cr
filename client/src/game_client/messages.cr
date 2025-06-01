require "json"

module GameClient
  # Base message type for all communications
  abstract struct Message
    include JSON::Serializable
    use_json_discriminator "type", {
      welcome:       WelcomeMessage,
      reconnected:   ReconnectedMessage,
      error:         ErrorMessage,
      player_action: PlayerActionMessage,
      game_log:      GameLogMessage,
      connection:    ConnectionMessage,
      command:       CommandMessage,
    }
  end

  # Server -> Client Messages
  struct WelcomeMessage < Message
    getter uuid : String
    getter coordinates : Array(Int32)

    def initialize(@uuid : String, @coordinates : Array(Int32))
      @type = "welcome"
    end
  end

  struct ReconnectedMessage < Message
    getter uuid : String
    getter coordinates : Array(Int32)

    def initialize(@uuid : String, @coordinates : Array(Int32))
      @type = "reconnected"
    end
  end

  struct ErrorMessage < Message
    getter message : String

    def initialize(@message : String)
      @type = "error"
    end
  end

  struct PlayerActionMessage < Message
    getter message : String

    def initialize(@message : String)
      @type = "player_action"
    end
  end

  # Simplified game log structures for client
  struct Spell
    include JSON::Serializable
    getter cast_by : String
    getter spell_name : String
    getter effect : SpellEffect

    def initialize(@cast_by : String, @spell_name : String, @effect : SpellEffect)
    end
  end

  struct SpellEffect
    include JSON::Serializable
    getter type : String
    getter amount : Int32

    def initialize(@type : String, @amount : Int32)
    end
  end

  struct CoordinateLog
    include JSON::Serializable
    getter coordinates : Array(Int32)
    getter player : String?
    getter spells_cast : Array(Spell)

    def initialize(@coordinates : Array(Int32), @player : String? = nil, @spells_cast = [] of Spell)
    end
  end

  struct Player
    include JSON::Serializable
    getter name : String

    def initialize(@name : String)
    end
  end

  struct GameLogMessage < Message
    getter log : Array(CoordinateLog)
    getter players : Hash(String, Player)

    def initialize(@log : Array(CoordinateLog), @players : Hash(String, Player))
      @type = "game_log"
    end
  end

  # Client -> Server Messages
  struct ConnectionMessage < Message
    getter uuid : String?

    def initialize(@uuid : String? = nil)
      @type = "connection"
    end
  end

  struct CommandMessage < Message
    getter command : String
    getter arguments : String?

    def initialize(@command : String, @arguments : String? = nil)
      @type = "command"
    end
  end
end
