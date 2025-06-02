require "../models/*"

module GameServer
  class GameLogManager
    def initialize(@game_state : GameState)
    end

    def add_player_to_log(uuid : String, coords : Coordinates)
      coord_array = [coords.x, coords.y]
      existing_log = find_log_entry(coord_array)
      update_or_create_log_entry(coord_array, uuid, existing_log)
    end

    def restore_player_position(uuid : String, player_manager : PlayerManager)
      existing_log = find_player_log(uuid)
      coords = existing_log ? extract_coordinates(existing_log) : player_manager.generate_random_coordinates
      player_manager.player_positions[uuid] = coords
      add_player_to_log(uuid, coords) unless existing_log
    end

    def add_spell_to_log(coord_array : Array(Int32), spell : Spell)
      existing_log = find_log_entry(coord_array)
      current_attrs = @game_state.get_coordinate_attributes(coord_array[0], coord_array[1])
      update_spell_log(coord_array, spell, existing_log, current_attrs)
    end

    private def find_log_entry(coord_array : Array(Int32)) : CoordinateLog?
      @game_state.log.find { |log| log.coordinates == coord_array }
    end

    private def find_player_log(uuid : String) : CoordinateLog?
      @game_state.log.find { |log| log.player == uuid }
    end

    private def update_or_create_log_entry(coord_array : Array(Int32), uuid : String, existing_log : CoordinateLog?)
      if existing_log
        update_existing_log_entry(coord_array, uuid, existing_log)
      else
        create_new_log_entry(coord_array, uuid)
      end
    end

    private def update_existing_log_entry(coord_array : Array(Int32), uuid : String, existing_log : CoordinateLog)
      index = @game_state.log.index!(existing_log)
      @game_state.log[index] = CoordinateLog.new(coord_array, uuid, existing_log.spells_cast, existing_log.attributes)
    end

    private def create_new_log_entry(coord_array : Array(Int32), uuid : String)
      @game_state.log << CoordinateLog.new(coord_array, uuid)
    end

    private def extract_coordinates(log_entry : CoordinateLog) : Coordinates
      Coordinates.new(log_entry.coordinates[0], log_entry.coordinates[1])
    end

    private def update_spell_log(coord_array : Array(Int32), spell : Spell, existing_log : CoordinateLog?, current_attrs : CoordinateAttributes)
      if existing_log
        update_existing_spell_log(coord_array, spell, existing_log, current_attrs)
      else
        create_new_spell_log(coord_array, spell, current_attrs)
      end
    end

    private def update_existing_spell_log(coord_array : Array(Int32), spell : Spell, existing_log : CoordinateLog, current_attrs : CoordinateAttributes)
      index = @game_state.log.index!(existing_log)
      new_spells = existing_log.spells_cast + [spell]
      @game_state.log[index] = CoordinateLog.new(coord_array, existing_log.player, new_spells, current_attrs)
    end

    private def create_new_spell_log(coord_array : Array(Int32), spell : Spell, current_attrs : CoordinateAttributes)
      @game_state.log << CoordinateLog.new(coord_array, nil, [spell], current_attrs)
    end
  end
end
