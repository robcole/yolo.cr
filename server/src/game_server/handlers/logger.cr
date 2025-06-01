module GameServer
  module Logger
    def self.log_connection(uuid : String)
      timestamp = Time.local.to_s("%Y-%m-%d %H:%M:%S")
      puts "[#{timestamp}] Client connected - UUID: #{uuid}"
    end

    def self.log_reconnection(uuid : String, player_name : String)
      timestamp = Time.local.to_s("%Y-%m-%d %H:%M:%S")
      puts "[#{timestamp}] Client reconnected - UUID: #{uuid}, Name: #{player_name}"
    end

    def self.log_disconnection(uuid : String, player_name : String)
      timestamp = Time.local.to_s("%Y-%m-%d %H:%M:%S")
      puts "[#{timestamp}] Client disconnected - UUID: #{uuid}, Name: #{player_name}"
    end

    def self.log_command(uuid : String, player_name : String, command : String)
      timestamp = Time.local.to_s("%Y-%m-%d %H:%M:%S")
      puts "[#{timestamp}] Command executed - UUID: #{uuid}, Name: #{player_name}, Command: #{command}"
    end
  end
end
