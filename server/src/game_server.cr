require "kemal"
require "./game_server/game"

game = GameServer::Game.new

get "/" do
  "OK"
end

ws "/" do |socket, _|
  uuid = ""

  socket.on_message do |message|
    if uuid.empty?
      # Handle initial connection
      begin
        conn_message = GameServer::Message.from_json(message)
        case conn_message
        when GameServer::ConnectionMessage
          if reconnect_uuid = conn_message.uuid
            if game.reconnect_player(socket, reconnect_uuid)
              uuid = reconnect_uuid
              coords = game.player_manager.player_positions[uuid]
              response = GameServer::ReconnectedMessage.new(uuid, [coords.x, coords.y])
              socket.send(response.to_json)
            else
              # Invalid UUID, treat as new player
              uuid = game.add_player(socket)
              if uuid.empty?
                error = GameServer::ErrorMessage.new("Server full")
                socket.send(error.to_json)
                socket.close
              else
                coords = game.player_manager.player_positions[uuid]
                response = GameServer::WelcomeMessage.new(uuid, [coords.x, coords.y])
                socket.send(response.to_json)
              end
            end
          else
            # New player
            uuid = game.add_player(socket)
            if uuid.empty?
              error = GameServer::ErrorMessage.new("Server full")
              socket.send(error.to_json)
              socket.close
            else
              coords = game.player_manager.player_positions[uuid]
              response = GameServer::WelcomeMessage.new(uuid, [coords.x, coords.y])
              socket.send(response.to_json)
            end
          end
        else
          error = GameServer::ErrorMessage.new("Expected connection message")
          socket.send(error.to_json)
          socket.close
        end
      rescue
        error = GameServer::ErrorMessage.new("Invalid connection message format")
        socket.send(error.to_json)
        socket.close
      end
    else
      # Handle game messages
      game.handle_message(uuid, message)
    end
  end

  socket.on_close do |_, _|
    game.remove_player(uuid) unless uuid.empty?
  end
end

Kemal.run
