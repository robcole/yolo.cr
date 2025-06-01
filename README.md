# WebSocket Game Chat Server

A complete websocket-based game chat server implementation using Crystal and Kemal with JSON-based communication.

## 🎮 Game Overview

This is a real-time multiplayer game server that supports:

- **512x512 Grid System**: Coordinates from (-256, -256) to (255, 255)
- **JSON WebSocket Communication**: Type-safe, structured messaging
- **UUID-based Players**: Unique identification with reconnection support
- **Persistent Game State**: JSON-based state that survives server restarts
- **Spell Casting System**: Cast spells with different effects at specific coordinates
- **Multi-player Support**: Up to 512 concurrent players
- **Docker Support**: Containerized builds and testing without Crystal installation
- **CI/CD Integration**: Automated testing and linting with GitHub Actions

## 📁 Project Structure

```
yolo.cr/
├── .github/workflows/           # CI/CD automation
│   ├── ci.yml                   # Linting and basic tests using Docker
│   └── integration-test.yml     # End-to-end JSON message tests using Docker
├── Dockerfile                   # Multi-stage Crystal build container
├── docker-compose.yml           # Container orchestration for development and testing
├── README.md                    # This file
├── CLAUDE.md                    # Project instructions
├── server/                      # Game server implementation
│   ├── src/
│   │   ├── game_server.cr       # Main WebSocket routing
│   │   └── game_server/
│   │       ├── models/          # Data structures
│   │       │   ├── coordinates.cr
│   │       │   ├── spell.cr
│   │       │   ├── player.cr
│   │       │   ├── game_state.cr
│   │       │   └── messages.cr  # JSON message types
│   │       ├── commands/
│   │       │   └── spell_factory.cr
│   │       ├── handlers/
│   │       │   └── logger.cr    # Centralized logging
│   │       └── game.cr          # Main game logic
│   ├── game_server              # Compiled server executable
│   ├── shard.yml                # Server dependencies
│   └── bin/ameba                # Linter executable
├── client/                      # Game client implementation
│   ├── src/
│   │   ├── game_client.cr       # Main client logic
│   │   └── game_client/
│   │       └── messages.cr      # JSON message types
│   ├── game_client              # Compiled client executable
│   ├── shard.yml                # Client dependencies
│   └── bin/ameba                # Linter executable
└── game_tests/                  # Test files and utilities
    ├── Makefile                 # Build automation (Native + Docker targets)
    ├── quick_test.sh            # Fast connectivity test
    └── *.cr                     # Various test scripts
```

## 🚀 Quick Start

### Option 1: Docker (Recommended)

```bash
# Build and run with Docker
cd game_tests
make docker-build               # Build Docker image with precompiled binaries
make docker-run                 # Start server in Docker container

# Or run all tests
make docker-all                 # Build, test, and lint using Docker
```

### Option 2: Native Crystal

```bash
# Traditional Crystal build
cd game_tests
make all                        # Builds both server and client

# Start the server
cd server
./game_server                   # Starts server on localhost:3000

# Connect a client
cd client
./game_client                   # Connects to the server
```

## 🎯 Available Commands

Once connected to the server, players can use these commands (no slash prefix needed):

- **`say <message>`** - Broadcast a message to all players
- **`cast <spell> <x,y>`** - Cast a spell at specific coordinates
- **`alias <name>`** - Set your player name
- **`witness`** - Get the complete game log in structured JSON format
- **`quit`** - Disconnect from the server

### Example Session

```
> say Hello everyone!
> cast Fireball 10,20
> alias Ford Prefect  
> witness
> quit
```

## 🔧 JSON Message Architecture

All communication uses structured JSON messages with type discrimination:

### Server → Client Messages

- **WelcomeMessage**: Initial connection with UUID and coordinates
- **ReconnectedMessage**: Successful reconnection confirmation
- **ErrorMessage**: Error notifications
- **PlayerActionMessage**: Broadcast player actions (say, cast, alias)
- **GameLogMessage**: Complete game state (from witness command)

### Client → Server Messages

- **ConnectionMessage**: Initial connection (with optional UUID for reconnection)
- **CommandMessage**: Game commands with arguments

### Example JSON Messages

```json
// Welcome message from server
{
  "type": "welcome",
  "uuid": "3164b377-e413-4ccd-97e4-3787d32bb9df",
  "coordinates": [106, -125]
}

// Command message from client
{
  "type": "command",
  "command": "say",
  "arguments": "Hello everyone!"
}

// Player action broadcast
{
  "type": "player_action",
  "message": "Ford Prefect: Hello everyone!"
}
```

## 🧙‍♂️ Spell System

Different spells have different effects:

- **Illuminate** - Creates light (effect: Light, amount: 10)
- **Fireball** - Deals damage (effect: Damage, amount: 25) 
- **Shield** - Increases health (effect: IncreaseHealth, amount: 42)

## 🧪 Development & Testing

### Docker Commands (Recommended)

```bash
cd game_tests

# Build and test with Docker (no Crystal installation needed)
make docker-build       # Build Docker image with precompiled binaries
make docker-test        # Run connectivity tests using Docker
make docker-lint        # Run ameba linting using Docker
make docker-integration # Run full integration tests using Docker
make docker-all         # Build + test + lint using Docker

# Development with hot reload
make docker-dev         # Start development server with live reloading

# Cleanup
make docker-clean       # Remove Docker containers and images
```

### Native Crystal Commands

```bash
cd game_tests

make all           # Build both server and client
make lint          # Run ameba linter on both projects
make format        # Run Crystal formatter on both projects
make clean         # Clean binaries and state files
```

### Quick Testing

```bash
cd game_tests
./quick_test.sh    # Fast connectivity and basic functionality test
```

### Continuous Integration

The project includes GitHub Actions workflows that automatically:

- **Docker-based CI**: Uses precompiled binaries in containers (no Crystal setup required)
- **Lint Code**: Run ameba on all source files using Docker
- **Build Test**: Ensure both server and client compile using Docker
- **Integration Test**: End-to-end JSON message communication testing using Docker

## 📊 Game State Persistence

### Server State (`server/game_state.json`)

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

```json
{
  "uuid": "3164b377-e413-4ccd-97e4-3787d32bb9df",
  "name": "Ford Prefect"
}
```

## ✅ System Verification

**🎮 Core Features:**
- ✅ JSON-based WebSocket communication with type safety
- ✅ Player UUID assignment and coordinate tracking
- ✅ Real-time command processing with structured messages
- ✅ Game state persistence across server restarts
- ✅ Multi-player support with concurrent connections
- ✅ Comprehensive server logging (connections, commands, disconnections)

**🎯 All Commands Working:**
- ✅ `say` - Message broadcasting via JSON
- ✅ `cast` - Spell casting with coordinate targeting
- ✅ `alias` - Player name changes
- ✅ `witness` - Complete game log in structured JSON

**🔧 Code Quality:**
- ✅ Ameba linting (zero violations)
- ✅ Crystal formatting standards
- ✅ Modular architecture with separated concerns
- ✅ Type-safe JSON message handling
- ✅ Comprehensive error handling

**🚀 CI/CD:**
- ✅ Automated testing on every push
- ✅ Code quality enforcement
- ✅ Integration testing for JSON communication
- ✅ Multi-platform compatibility

## 🔧 Technical Details

**Built with:**
- **Crystal Language** (1.16.3+) - Fast, type-safe systems programming
- **Kemal Framework** - Lightweight web framework with WebSocket support
- **JSON with Discriminators** - Type-safe message serialization
- **Ameba** - Crystal linter for code quality
- **GitHub Actions** - CI/CD automation

**Architecture Highlights:**
- **Modular Design**: Separated models, commands, and handlers
- **Type Safety**: JSON discriminator pattern for message types
- **Error Resilience**: Graceful handling of malformed messages
- **Concurrent Processing**: Multi-player support with WebSocket concurrency
- **State Persistence**: Automatic JSON state file management
- **Development Friendly**: Comprehensive linting and formatting tools

## 🏆 Production Ready

This WebSocket game server is production-ready with:

- **Comprehensive Testing**: Unit tests, integration tests, and CI/CD
- **Code Quality**: Strict linting and formatting standards
- **Documentation**: Complete API and architecture documentation
- **Error Handling**: Robust error recovery and logging
- **Performance**: Optimized Crystal binaries with minimal overhead
- **Maintainability**: Clean, modular architecture with separated concerns

The server successfully handles JSON-based real-time communication for multiplayer gaming scenarios with full state persistence and player management.