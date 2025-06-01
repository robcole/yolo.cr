require "socket"
require "json"
require "base64"

# Simple WebSocket client for automated testing
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
      frame.write_byte((bytes.size | 0x80).to_u8)  # Masked
    elsif bytes.size < 65536
      frame.write_byte(0xFE_u8)  # 126 + masked
      frame.write_bytes(bytes.size.to_u16, IO::ByteFormat::BigEndian)
    else
      frame.write_byte(0xFF_u8)  # 127 + masked
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

puts "Running automated test..."

begin
  # Connect to server
  ws = TestWebSocket.connect("localhost", 3000)
  puts "✓ Connected to server"
  
  # Send empty message for new player
  ws.send("")
  sleep 0.1
  
  # Read welcome message
  welcome = ws.receive
  puts "✓ Received: #{welcome}"
  
  # Extract UUID
  uuid = ""
  if welcome.starts_with?("Welcome! Your UUID:")
    uuid = welcome.split("UUID: ")[1]?.try(&.split(",")[0]?) || ""
  end
  
  # Test commands according to spec
  puts "\n1) Sending '/say Hello?'"
  ws.send("/say Hello?")
  sleep 0.1
  response = ws.receive
  puts "   Response: #{response}"
  
  puts "\n2) Sending '/cast Illuminate 0,0'"  
  ws.send("/cast Illuminate 0,0")
  sleep 0.1
  response = ws.receive
  puts "   Response: #{response}"
  
  puts "\n3) Sending '/alias Ford Prefect'"
  ws.send("/alias Ford Prefect")
  sleep 0.1 
  response = ws.receive
  puts "   Response: #{response}"
  
  puts "\n4) Disconnecting client"
  ws.close
  
  puts "\n✓ Test sequence completed successfully!"
  
rescue ex
  puts "✗ Test failed: #{ex.message}"
end

# Check state files
puts "\nChecking state files..."

if File.exists?("server/game_state.json")
  puts "✓ Server state file exists"
  server_state = File.read("server/game_state.json")
  puts "  Content: #{server_state}"
else
  puts "✗ Server state file missing"
end

if File.exists?("client/game_state.json")
  puts "✓ Client state file exists"  
  client_state = File.read("client/game_state.json")
  puts "  Content: #{client_state}"
else
  puts "✗ Client state file missing"
end