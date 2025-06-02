#!/usr/bin/env crystal

# Test script to validate the game system
require "json"

puts "Testing Game System..."

# Check if server executable exists
unless File.exists?("server/game_server")
  puts "ERROR: Server executable not found. Run 'make build-server' first."
  exit 1
end

# Check if client executable exists
unless File.exists?("client/game_client")
  puts "ERROR: Client executable not found. Run 'make build-client' first."
  exit 1
end

puts "✓ Both executables found"

# Clean up any existing state files
File.delete("server/game_state.json") if File.exists?("server/game_state.json")
File.delete("client/game_state.json") if File.exists?("client/game_state.json")

puts "✓ Cleaned up existing state files"

puts "\nTo test the system manually:"
puts "1. Start server: cd server && ./game_server"
puts "2. In another terminal, start client: cd client && ./game_client"
puts "3. Run the following commands in the client:"
puts "   /say Hello?"
puts "   /cast Illuminate 0,0"
puts "   /alias Ford Prefect"
puts "   /quit"
puts "4. Stop the server (Ctrl+C)"
puts "5. Check that both state files were created with correct data"

puts "\nAlternatively, use the automated test below..."
