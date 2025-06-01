require "socket"

# Simple test to verify server connection
begin
  socket = TCPSocket.new("localhost", 3000)
  puts "✓ Server is accepting connections on port 3000"
  socket.close
rescue
  puts "✗ Cannot connect to server on port 3000"
  exit 1
end

puts "\nTo test manually:"
puts "1. In a new terminal, run: cd client && ./game_client"
puts "2. Try these commands:"
puts "   /say Hello?"
puts "   /cast Illuminate 0,0"
puts "   /alias Ford Prefect"
puts "   /quit"

puts "\nAfter testing, check these files:"
puts "- server/game_state.json (should contain game log)"
puts "- client/game_state.json (should contain player UUID and name)"