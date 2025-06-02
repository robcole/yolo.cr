require "socket"
require "json"

# Simple test specifically for /witness command
def websocket_handshake(socket, host, port)
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

  response.includes?("101 Switching Protocols")
end

def encode_frame(payload : String)
  bytes = payload.to_slice
  frame = IO::Memory.new

  frame.write_byte(0x81_u8)

  if bytes.size < 126
    frame.write_byte((bytes.size | 0x80).to_u8)
  else
    puts "Payload too large"
    return Bytes.new(0)
  end

  mask = Bytes[0x12, 0x34, 0x56, 0x78]
  frame.write(mask)

  bytes.each_with_index do |byte, i|
    frame.write_byte((byte ^ mask[i % 4]).to_u8)
  end

  frame.to_slice
end

def decode_frame(socket)
  first_byte = socket.read_byte || return ""
  second_byte = socket.read_byte || return ""

  payload_len = (second_byte & 0x7F).to_i

  if payload_len == 126
    # Read 16-bit length
    len_bytes = Bytes.new(2)
    socket.read_fully(len_bytes)
    payload_len = (len_bytes[0].to_u16 << 8) | len_bytes[1].to_u16
  elsif payload_len == 127
    # Read 64-bit length (simplified - just read 8 bytes and use last 4)
    len_bytes = Bytes.new(8)
    socket.read_fully(len_bytes)
    payload_len = (len_bytes[4].to_u32 << 24) | (len_bytes[5].to_u32 << 16) | (len_bytes[6].to_u32 << 8) | len_bytes[7].to_u32
  end

  puts "DEBUG: Payload length: #{payload_len}"

  payload = Bytes.new(payload_len)
  socket.read_fully(payload)

  String.new(payload)
end

begin
  puts "Testing /witness command specifically..."
  socket = TCPSocket.new("localhost", 3000)

  if websocket_handshake(socket, "localhost", 3000)
    puts "✅ Connected successfully"

    # Send initial empty message first (as expected by the full server)
    puts "📤 Sending initial empty message..."
    socket.write(encode_frame(""))

    # Read welcome message
    welcome = decode_frame(socket)
    puts "Welcome: #{welcome}"

    # Send some commands to establish game state
    puts "\n📤 Sending /say command to create activity..."
    socket.write(encode_frame("/say Testing the system"))
    response1 = decode_frame(socket)
    puts "Response: #{response1}"

    puts "\n📤 Sending /cast command..."
    socket.write(encode_frame("/cast Fireball 5,10"))
    response2 = decode_frame(socket)
    puts "Response: #{response2}"

    puts "\n📤 Sending /alias command..."
    socket.write(encode_frame("/alias Test Player"))
    response3 = decode_frame(socket)
    puts "Response: #{response3}"

    # Now send /witness command
    puts "\n📤 Sending /witness command..."
    socket.write(encode_frame("/witness"))

    # Read response
    response = decode_frame(socket)
    puts "\n📋 /witness response:"

    if response.starts_with?("{") && response.includes?("log")
      puts "✅ Received JSON game log!"
      puts "="*60
      begin
        json = JSON.parse(response)
        puts json.to_pretty_json
      rescue ex
        puts "JSON parse error: #{ex.message}"
        puts "Raw response: #{response}"
      end
      puts "="*60
    else
      puts "⚠️  Response doesn't look like game log JSON:"
      puts response
    end
  else
    puts "❌ WebSocket handshake failed"
  end

  socket.close
rescue ex
  puts "❌ Error: #{ex.message}"
end
