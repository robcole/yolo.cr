#!/usr/bin/env python3

import asyncio
import websockets
import json

async def test_server():
    uri = "ws://localhost:3000"
    
    try:
        async with websockets.connect(uri) as websocket:
            print("✅ Connected to server")
            
            # Send empty message for new player
            await websocket.send("")
            
            # Wait for welcome message
            welcome = await websocket.recv()
            print(f"📨 Received: {welcome}")
            
            # Extract UUID if present
            uuid = ""
            if "UUID:" in welcome:
                uuid = welcome.split("UUID: ")[1].split(",")[0]
                print(f"🔑 UUID: {uuid}")
            
            # Test commands
            print("\n📤 Testing /say command")
            await websocket.send("/say Hello from Python test!")
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=1.0)
                print(f"📨 Response: {response}")
            except asyncio.TimeoutError:
                print("⏰ No response received")
            
            print("\n📤 Testing /cast command")
            await websocket.send("/cast Fireball 10,20")
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=1.0)
                print(f"📨 Response: {response}")
            except asyncio.TimeoutError:
                print("⏰ No response received")
                
            print("\n📤 Testing /alias command")
            await websocket.send("/alias Python Tester")
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=1.0)
                print(f"📨 Response: {response}")
            except asyncio.TimeoutError:
                print("⏰ No response received")
            
            print("\n📤 Testing /witness command")
            await websocket.send("/witness")
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                print(f"📨 Game log received:")
                # Try to format as JSON
                try:
                    game_log = json.loads(response)
                    print(json.dumps(game_log, indent=2))
                except:
                    print(response)
            except asyncio.TimeoutError:
                print("⏰ No game log received")
            
            print("\n🔌 Closing connection")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_server())