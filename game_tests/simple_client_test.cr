require "socket"
require "json"

# Very simple WebSocket test client
def websocket_handshake(socket, host, port)
  # Basic WebSocket handshake
  key = "dGhlIHNhbXBsZSBub25jZQ=="
  
  request = String.build do |str|
    str << "GET / HTTP/1.1\r\n"
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
  
  puts "Handshake response:"
  puts response
  response.includes?("101 Switching Protocols")
end

# Simple WebSocket frame encoding (text frame only)
def encode_frame(payload : String)
  bytes = payload.to_slice
  frame = IO::Memory.new
  
  # Text frame with FIN bit set
  frame.write_byte(0x81_u8)
  
  # Payload length (masked)
  if bytes.size < 126
    frame.write_byte((bytes.size | 0x80).to_u8)
  else
    puts "Payload too large for simple implementation"
    return Bytes.new(0)
  end
  
  # Masking key (simple for testing)
  mask = Bytes[0x12, 0x34, 0x56, 0x78]
  frame.write(mask)
  
  # Masked payload
  bytes.each_with_index do |byte, i|
    frame.write_byte((byte ^ mask[i % 4]).to_u8)
  end
  
  frame.to_slice
end

# Simple WebSocket frame decoding
def decode_frame(socket)
  first_byte = socket.read_byte || return ""
  second_byte = socket.read_byte || return ""
  
  payload_len = second_byte & 0x7F
  
  if payload_len >= 126
    puts "Complex payload length not supported"
    return ""
  end
  
  payload = Bytes.new(payload_len)
  socket.read_fully(payload)
  
  String.new(payload)
end

begin
  puts "Connecting to server..."
  socket = TCPSocket.new("localhost", 3000)
  
  if websocket_handshake(socket, "localhost", 3000)
    puts "✅ WebSocket handshake successful"
    
    # Test receiving welcome message
    puts "\n📨 Waiting for welcome message..."
    welcome = decode_frame(socket)
    puts "Received: #{welcome}"
    
    # Send empty message for new player
    puts "\n📤 Sending empty message for new player..."
    socket.write(encode_frame(""))
    
    # Send test commands
    sleep 0.5
    
    puts "\n📤 Sending /say command..."
    socket.write(encode_frame("/say Hello from simple client!"))
    response = decode_frame(socket)
    puts "Response: #{response}"
    
    sleep 0.5
    
    puts "\n📤 Sending /witness command..."
    socket.write(encode_frame("/witness"))
    response = decode_frame(socket)
    puts "Game log response:"
    
    # Try to format as JSON
    if response.starts_with?("{")
      begin
        json = JSON.parse(response)
        puts json.to_pretty_json
      rescue
        puts response
      end
    else
      puts response
    end
    
  else
    puts "❌ WebSocket handshake failed"
  end
  
  socket.close
  
rescue ex
  puts "❌ Error: #{ex.message}"
end