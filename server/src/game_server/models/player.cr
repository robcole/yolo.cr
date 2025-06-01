require "json"

module GameServer
  struct Player
    include JSON::Serializable

    getter name : String

    def initialize(@name : String)
    end
  end
end
