require "http/web_socket"
require "json"

module GameClient
  struct ClientState
    include JSON::Serializable

    getter uuid : String?
    getter name : String?

    def initialize(@uuid : String? = nil, @name : String? = nil)
    end
  end

  class Client
    STATE_FILE = "game_state.json"

    getter state : ClientState
    getter socket : HTTP::WebSocket?
    getter? connected : Bool

    def initialize
      @state = load_state
      @socket = nil
      @connected = false
    end

    def load_state : ClientState
      if File.exists?(STATE_FILE)
        content = File.read(STATE_FILE)
        ClientState.from_json(content)
      else
        ClientState.new
      end
    end

    def save_state
      File.write(STATE_FILE, @state.to_json)
    end

    def connect(server_url : String = "ws://localhost:3000")
      @socket = HTTP::WebSocket.new(URI.parse(server_url))
      @connected = true

      socket = @socket
      return unless socket

      socket.on_message do |message|
        handle_server_message(message)
      end

      socket.on_close do |_, reason|
        @connected = false
        puts "Connection closed: #{reason}"
      end

      # Send UUID for reconnection if we have one
      if uuid = @state.uuid
        socket.send(uuid)
      else
        socket.send("")
      end

      puts "Connected to server..."
    rescue ex
      puts "Failed to connect to server: #{ex.message}"
      @connected = false
    end

    def handle_server_message(message : String)
      puts "DEBUG: Received message: '#{message}'" if message && !message.empty?

      if message.starts_with?("Welcome! Your UUID:")
        # Parse UUID from welcome message
        uuid_part = message.split("UUID: ")[1]?.try(&.split(",")[0]?)
        if uuid_part
          @state = ClientState.new(uuid_part, @state.name)
          save_state
          puts message
        end
      elsif message.starts_with?("Reconnected! UUID:")
        puts message
      elsif message.starts_with?("{") && message.includes?("\"log\"")
        # This looks like JSON from /witness command - format it nicely
        begin
          json = JSON.parse(message)
          puts "\n" + "="*50
          puts "GAME LOG (from /witness command)"
          puts "="*50
          puts json.to_pretty_json
          puts "="*50 + "\n"
        rescue
          puts "Received game log: #{message}"
        end
      else
        puts message
      end
    end

    def send_command(command : String)
      return unless @connected

      socket = @socket
      return unless socket

      socket.send(command)
    rescue
      @connected = false
      puts "Connection lost"
    end

    def run
      connect

      return unless @connected

      # Run the WebSocket in a fiber
      spawn do
        socket = @socket
        socket.try(&.run) if @connected
      end

      # Wait for initial connection response
      sleep 0.5.seconds

      puts "\nGame Client Connected!"
      puts "Available commands:"
      puts "  /alias <name> - Set your player name"
      puts "  /say <message> - Say something to other players"
      puts "  /cast <spell> <x,y> - Cast a spell at coordinates"
      puts "  /witness - Get complete game log"
      puts "  /quit - Disconnect and quit"
      puts ""

      loop do
        print "> "
        input = gets
        break unless input

        command = input.strip
        next if command.empty?

        if command == "/quit"
          disconnect
          break
        elsif command.starts_with?("/alias ")
          name = command.split(" ", 2)[1]?
          if name
            @state = ClientState.new(@state.uuid, name)
            save_state
            send_command(command)
          end
        else
          send_command(command)
        end
      end
    end

    def disconnect
      socket = @socket
      socket.try(&.close) if @connected
      @connected = false
      puts "Disconnected from server"
    end
  end
end

# Handle Ctrl+C gracefully
Signal::INT.trap do
  puts "\nShutting down..."
  exit 0
end

client = GameClient::Client.new
client.run
