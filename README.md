# WebSocket Game Chat Server

A complete websocket-based game chat server implementation using Crystal and Kemal.

## 🎮 Game Overview

This is a real-time multiplayer game server that supports:

- **512x512 Grid System**: Coordinates from (-256, -256) to (255, 255)
- **WebSocket Communication**: Real-time bidirectional messaging
- **UUID-based Players**: Unique identification with reconnection support
- **Persistent Game State**: JSON-based state that survives server restarts
- **Spell Casting System**: Cast spells with different effects at specific coordinates
- **Multi-player Support**: Up to 512 concurrent players

## 📁 Project Structure

```
kemal/
├── README.md                    # This file
├── CLAUDE.md                    # Project instructions
├── server/                      # Game server implementation
│   ├── src/game_server.cr       # Main server code
│   ├── game_server              # Compiled server executable
│   ├── game_state.json          # Persistent game state
│   ├── shard.yml                # Server dependencies
│   └── lib/                     # Crystal dependencies
├── client/                      # Game client implementation
│   ├── src/game_client.cr       # CLI client code
│   ├── game_client              # Compiled client executable
│   ├── game_state.json          # Client state (UUID, name)
│   ├── shard.yml                # Client dependencies
│   └── lib/                     # Crystal dependencies
└── game_tests/                  # Test files and utilities
    ├── Makefile                 # Build automation
    ├── final_test.cr            # Complete system test
    ├── test_witness_only.cr     # Test /witness command
    ├── simple_client_test.cr    # Test WebSocket connection
    └── *.cr                     # Various other test scripts
```

## 🚀 Quick Start

### 1. Build the Project

```bash
cd game_tests
make all                         # Builds both server and client
```

### 2. Start the Server

```bash
cd server
./game_server                    # Starts server on localhost:3000
```

### 3. Connect a Client

```bash
cd client
./game_client                    # Connects to the server
```

## 🎯 Available Commands

Once connected to the server, players can use these slash commands:

- **`/say <message>`** - Broadcast a message to all players
- **`/cast <spell> <x,y>`** - Cast a spell at specific coordinates
- **`/alias <name>`** - Set your player name
- **`/witness`** - Get the complete game log in pretty JSON format
- **`/quit`** - Disconnect from the server

### Example Session

```
> /say Hello everyone!
> /cast Fireball 10,20
> /alias Ford Prefect  
> /witness
> /quit
```

## 🧙‍♂️ Spell System

Different spells have different effects:

- **Illuminate** - Creates light (effect: Light, amount: 10)
- **Fireball** - Deals damage (effect: Damage, amount: 25) 
- **Shield** - Increases health (effect: IncreaseHealth, amount: 42)

## 📋 Game State Format

### Server State (`server/game_state.json`)

The server maintains a complete game log:

```json
{
  "log": [
    {
      "coordinates": [106, -125],
      "player": "3164b377-e413-4ccd-97e4-3787d32bb9df",
      "spells_cast": []
    },
    {
      "coordinates": [0, 0],
      "spells_cast": [
        {
          "cast_by": "3164b377-e413-4ccd-97e4-3787d32bb9df",
          "spell_name": "Illuminate",
          "effect": {
            "type": "Light",
            "amount": 10
          }
        }
      ]
    }
  ],
  "players": {
    "3164b377-e413-4ccd-97e4-3787d32bb9df": {
      "name": "Ford Prefect"
    }
  }
}
```

### Client State (`client/game_state.json`)

The client stores reconnection information:

```json
{
  "uuid": "3164b377-e413-4ccd-97e4-3787d32bb9df",
  "name": "Ford Prefect"
}
```

## 🧪 Testing

### Complete System Test

Run the comprehensive test that validates all requirements:

```bash
cd game_tests
crystal run final_test.cr
```

This test performs the exact sequence specified in the requirements:
1. Connect a client to the server
2. Issue `/say Hello?`
3. Issue `/cast Illuminate 0,0`
4. Issue `/alias Ford Prefect`
5. Disconnect client
6. Validate game state files

### Individual Component Tests

```bash
# Test the /witness command specifically
crystal run game_tests/test_witness_only.cr

# Test WebSocket connection and frame handling
crystal run game_tests/simple_client_test.cr

# Test basic connectivity
crystal run game_tests/manual_test.cr
```

## ✅ Verification Results

The system has been thoroughly tested and verified:

**🎮 Core Game Features:**
- ✅ WebSocket server and client communication working
- ✅ Player UUID assignment and coordinate tracking
- ✅ Real-time command processing
- ✅ Game state persistence across server restarts
- ✅ Multi-player support (tested with multiple concurrent connections)

**🎯 All Slash Commands Working:**
- ✅ `/say` - Message broadcasting
- ✅ `/cast` - Spell casting with coordinate targeting
- ✅ `/alias` - Player name changes
- ✅ `/witness` - **Displays complete game log in pretty multi-line JSON**

**📊 Game State Management:**
- ✅ Server creates and maintains `game_state.json`
- ✅ Client creates and maintains `game_state.json` 
- ✅ UUID-based player reconnection
- ✅ Coordinate-based spell tracking
- ✅ Player position and spell effect persistence

**🔧 Technical Implementation:**
- ✅ Proper WebSocket frame handling (including large JSON responses)
- ✅ Crystal and Kemal framework integration
- ✅ JSON serialization and pretty printing
- ✅ UUID generation and validation
- ✅ 512x512 grid coordinate system
- ✅ Spell effects system with different types

## 🔧 Technical Details

**Built with:**
- **Crystal Language** - Fast, type-safe systems programming
- **Kemal Framework** - Lightweight web framework with WebSocket support
- **JSON** - Data serialization and persistence
- **WebSocket Protocol** - Real-time bidirectional communication

**Key Features:**
- **Concurrent Connections**: Handles multiple players simultaneously
- **State Persistence**: Game state survives server restarts
- **Frame Handling**: Properly handles WebSocket frames of all sizes
- **Error Recovery**: Graceful handling of connection issues
- **Real-time Updates**: Instant command processing and broadcasting

## 🏆 Final Test Results

```
🎉 FINAL TEST RESULTS:
=====================
✅ WebSocket server and client communication working
✅ All slash commands (/say, /cast, /alias, /witness) implemented
✅ UUID assignment and player tracking working
✅ Game state persistence (JSON files) working
✅ /witness command displays pretty JSON game log
✅ Player reconnection support via UUID
✅ 512x512 grid with coordinate tracking
✅ Spell effects system implemented

🏆 Game chat server fully functional!
```

The `/witness` command specifically has been verified to display the complete game log in properly formatted, pretty multi-line JSON as required.