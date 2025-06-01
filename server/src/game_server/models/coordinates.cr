require "json"

module GameServer
  struct Coordinates
    include JSON::Serializable

    getter x : Int32
    getter y : Int32

    def initialize(@x : Int32, @y : Int32)
    end

    def to_s(io)
      io << "[#{@x}, #{@y}]"
    end
  end
end
