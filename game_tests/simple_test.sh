#!/bin/bash

# Simple test script using the built client
cd /Users/robcole/dev/crystal-lang-test/kemal

echo "Testing game system..."

# Clean up any existing state files
rm -f server/game_state.json client/game_state.json

echo "Starting client test session..."
cd client

# Create input commands for the client
echo "" > test_input.txt          # Empty initial message for new player
echo "/say Hello?" >> test_input.txt
echo "/cast Illuminate 0,0" >> test_input.txt  
echo "/alias Ford Prefect" >> test_input.txt
echo "/quit" >> test_input.txt

echo "Sending test commands to client..."
timeout 10s ./game_client < test_input.txt

echo "Checking results..."

cd ..

if [ -f "server/game_state.json" ]; then
    echo "✓ Server state file created:"
    cat server/game_state.json | jq . 2>/dev/null || cat server/game_state.json
else
    echo "✗ Server state file missing"
fi

if [ -f "client/game_state.json" ]; then
    echo "✓ Client state file created:"
    cat client/game_state.json | jq . 2>/dev/null || cat client/game_state.json  
else
    echo "✗ Client state file missing"
fi

# Clean up
rm -f client/test_input.txt