require "kemal"
require "./game_server/game"

game = GameServer::Game.new

ws "/" do |socket, _|
  uuid = ""

  socket.on_message do |message|
    if uuid.empty?
      if message.empty?
        uuid = game.add_player(socket)
        if uuid.empty?
          socket.send("Server full")
          socket.close
        else
          coords = game.player_positions[uuid]
          socket.send("Welcome! Your UUID: #{uuid}, Coordinates: #{coords}")
        end
      else
        if game.reconnect_player(socket, message)
          uuid = message
          coords = game.player_positions[uuid]
          socket.send("Reconnected! UUID: #{uuid}, Coordinates: #{coords}")
        else
          uuid = game.add_player(socket)
          if uuid.empty?
            socket.send("Server full")
            socket.close
          else
            coords = game.player_positions[uuid]
            socket.send("Welcome! Your UUID: #{uuid}, Coordinates: #{coords}")
          end
        end
      end
    else
      game.handle_command(uuid, message)
    end
  end

  socket.on_close do |_, _|
    game.remove_player(uuid) unless uuid.empty?
  end
end

Kemal.run
