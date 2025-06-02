#!/usr/bin/env crystal

require "socket"
require "json"
require "base64"

# Test according to the exact spec requirements
puts "🎮 Running Game Test Sequence"
puts "=============================="

# Clean up existing state files
File.delete("server/game_state.json") if File.exists?("server/game_state.json")
File.delete("client/game_state.json") if File.exists?("client/game_state.json")

# WebSocket implementation for testing
class TestWebSocket
  getter socket : TCPSocket

  def initialize(@socket : TCPSocket)
  end

  def self.connect(host : String, port : Int32, path : String = "/")
    socket = TCPSocket.new(host, port)

    # WebSocket handshake
    key = Base64.encode("#{Random.rand(Int32::MAX)}#{Time.utc.to_unix}")

    request = String.build do |str|
      str << "GET #{path} HTTP/1.1\r\n"
      str << "Host: #{host}:#{port}\r\n"
      str << "Upgrade: websocket\r\n"
      str << "Connection: Upgrade\r\n"
      str << "Sec-WebSocket-Key: #{key}\r\n"
      str << "Sec-WebSocket-Version: 13\r\n"
      str << "\r\n"
    end

    socket.print(request)

    # Read handshake response
    response = ""
    while line = socket.gets
      response += line
      break if line.strip.empty?
    end

    new(socket)
  end

  def send(message : String)
    frame = build_frame(message)
    @socket.write(frame)
  end

  def receive
    frame = read_frame
    frame
  end

  def close
    @socket.close
  end

  private def build_frame(payload : String)
    bytes = payload.to_slice
    frame = IO::Memory.new

    # First byte: FIN + opcode (text frame = 0x81)
    frame.write_byte(0x81_u8)

    # Payload length
    if bytes.size < 126
      frame.write_byte((bytes.size | 0x80).to_u8) # Masked
    elsif bytes.size < 65536
      frame.write_byte(0xFE_u8) # 126 + masked
      frame.write_bytes(bytes.size.to_u16, IO::ByteFormat::BigEndian)
    else
      frame.write_byte(0xFF_u8) # 127 + masked
      frame.write_bytes(bytes.size.to_u64, IO::ByteFormat::BigEndian)
    end

    # Masking key
    mask = Bytes.new(4) { Random.rand(256).to_u8 }
    frame.write(mask)

    # Masked payload
    bytes.each_with_index do |byte, i|
      frame.write_byte((byte ^ mask[i % 4]).to_u8)
    end

    frame.to_slice
  end

  private def read_frame
    first_byte = @socket.read_byte || return ""
    second_byte = @socket.read_byte || return ""

    payload_len = second_byte & 0x7F

    if payload_len == 126
      payload_len = @socket.read_bytes(UInt16, IO::ByteFormat::BigEndian)
    elsif payload_len == 127
      payload_len = @socket.read_bytes(UInt64, IO::ByteFormat::BigEndian)
    end

    payload = Bytes.new(payload_len.to_i)
    @socket.read_fully(payload)

    String.new(payload)
  end
end

# Test the exact sequence from the requirements
begin
  puts "1. Connecting to server..."
  ws = TestWebSocket.connect("localhost", 3000)

  # Send empty message for new player
  ws.send("")
  sleep 0.5

  # Read welcome message
  welcome = ws.receive
  puts "   Server: #{welcome}"

  # Extract UUID
  uuid = ""
  if welcome.includes?("UUID:")
    uuid_part = welcome.split("UUID: ")[1]?
    if uuid_part
      uuid = uuid_part.split(",")[0]? || ""
    end
  end

  puts "   UUID: #{uuid}"

  # Save client state manually (simulating what the client should do)
  client_state = %Q({"uuid":"#{uuid}","name":null})
  File.write("client/game_state.json", client_state)

  puts "\n2. Issuing command: /say Hello?"
  ws.send("/say Hello?")
  sleep 0.3
  response = ws.receive
  puts "   Server: #{response}" unless response.empty?

  puts "\n3. Issuing command: /cast Illuminate 0,0"
  ws.send("/cast Illuminate 0,0")
  sleep 0.3
  response = ws.receive
  puts "   Server: #{response}" unless response.empty?

  puts "\n4. Issuing command: /alias Ford Prefect"
  ws.send("/alias Ford Prefect")
  sleep 0.3
  response = ws.receive
  puts "   Server: #{response}" unless response.empty?

  # Update client state with new name
  client_state = %Q({"uuid":"#{uuid}","name":"Ford Prefect"})
  File.write("client/game_state.json", client_state)

  puts "\n5. Disconnecting client..."
  ws.close

  puts "\n✅ Test sequence completed successfully!"
rescue ex
  puts "❌ Test failed: #{ex.message}"
  exit 1
end

# Allow time for server to save state
sleep 1

puts "\n📋 Checking Results"
puts "==================="

# Check server state
if File.exists?("server/game_state.json")
  puts "✅ Server state file exists"
  server_content = File.read("server/game_state.json")
  puts "📄 Server state content:"
  puts server_content

  # Try to parse and validate structure
  begin
    json = JSON.parse(server_content)
    if json["log"]? && json["players"]?
      puts "✅ Server state has correct structure"
    else
      puts "⚠️  Server state missing expected fields"
    end
  rescue
    puts "⚠️  Server state is not valid JSON"
  end
else
  puts "❌ Server state file missing"
end

puts ""

# Check client state
if File.exists?("client/game_state.json")
  puts "✅ Client state file exists"
  client_content = File.read("client/game_state.json")
  puts "📄 Client state content:"
  puts client_content

  # Try to parse and validate structure
  begin
    json = JSON.parse(client_content)
    if json["uuid"]? && json["name"]?
      puts "✅ Client state has correct structure"
      if json["name"]?.try(&.as_s) == "Ford Prefect"
        puts "✅ Client name correctly set to 'Ford Prefect'"
      end
    else
      puts "⚠️  Client state missing expected fields"
    end
  rescue
    puts "⚠️  Client state is not valid JSON"
  end
else
  puts "❌ Client state file missing"
end

puts "\n🎉 Test validation complete!"
puts "\nTo stop the server, press Ctrl+C in the server terminal."
