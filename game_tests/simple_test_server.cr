require "kemal"
require "json"

# Simple test server to debug the issue
ws "/" do |socket|
  puts "New connection established"
  socket.send "Welcome! Your UUID: test-uuid-123, Coordinates: [0, 0]"

  socket.on_message do |message|
    puts "Received: #{message}"

    if message.starts_with?("/witness")
      test_log = {
        "log" => [
          {
            "coordinates" => [0, 0],
            "player"      => "test-uuid-123",
            "spells_cast" => [
              {
                "cast_by"    => "test-uuid-123",
                "spell_name" => "Shield",
                "effect"     => {
                  "type"   => "IncreaseHealth",
                  "amount" => 42,
                },
              },
            ],
          },
        ],
        "players" => {
          "test-uuid-123" => {
            "name" => "Test Player",
          },
        },
      }
      socket.send test_log.to_json
    elsif message.starts_with?("/say")
      socket.send "Test Player: #{message[5..-1]}"
    elsif message.starts_with?("/cast")
      socket.send "Test Player cast spell"
    elsif message.starts_with?("/alias")
      socket.send "Test Player changed name"
    else
      socket.send "Echo: #{message}"
    end
  end

  socket.on_close do |code, message|
    puts "Connection closed: #{code} - #{message}"
  end
end

Kemal.run
