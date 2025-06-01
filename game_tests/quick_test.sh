#!/bin/bash

# Quick test script to verify the game server and client work
echo "🎮 Testing yolo.cr WebSocket Game Server..."
echo

# Check if binaries exist
if [ ! -f ../server/game_server ]; then
    echo "❌ Server binary not found. Run 'make build-server' first."
    exit 1
fi

if [ ! -f ../client/game_client ]; then
    echo "❌ Client binary not found. Run 'make build-client' first."
    exit 1
fi

echo "✅ Binaries found"

# Start server in background
echo "🚀 Starting server..."
cd ../server
./game_server &
SERVER_PID=$!
cd ../game_tests

# Wait for server to start
sleep 2

echo "🔌 Testing server connectivity..."
curl -s http://localhost:3000 > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Server is running and responsive"
else
    echo "❌ Server not responding"
    kill $SERVER_PID 2>/dev/null
    exit 1
fi

# Clean up
echo "🛑 Stopping server..."
kill $SERVER_PID 2>/dev/null
wait $SERVER_PID 2>/dev/null

echo "✅ Quick test completed successfully!"
echo
echo "To run the full game:"
echo "1. Start server: cd ../server && ./game_server"
echo "2. Start client: cd ../client && ./game_client"
echo "3. Use commands: say, cast, alias, witness, quit"