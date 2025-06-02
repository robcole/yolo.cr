require "../models/*"
require "../commands/*"
require "../managers/*"
require "./logger"

module GameServer
  class SpellCaster
    def initialize(@player_manager : PlayerManager, @game_state : GameState, @message_handler : MessageHandler)
    end

    def cast(uuid : String, args : String)
      spell_name, coordinates = parse_cast_command(args)
      return send_error(uuid, "Invalid coordinates") unless coordinates
      execute_spell(uuid, spell_name, coordinates)
    end

    private def parse_cast_command(args : String) : {String, Coordinates?}
      parts = args.split(" ", 2)
      spell_name = parts[0]? || ""
      coordinates = parse_coordinates(parts[1]?)
      {spell_name, coordinates}
    end

    private def parse_coordinates(coords_str : String?) : Coordinates?
      return nil unless coords_str
      parts = coords_str.split(",")
      return nil unless parts.size == 2
      create_coordinates_from_parts(parts)
    end

    private def create_coordinates_from_parts(parts : Array(String)) : Coordinates?
      x = parts[0].strip.to_i?
      y = parts[1].strip.to_i?
      return nil unless x && y
      Coordinates.new(x, y)
    end

    private def execute_spell(uuid : String, spell_name : String, coordinates : Coordinates)
      cast_spell_at_coordinates(uuid, spell_name, coordinates)
      broadcast_spell_cast(uuid, spell_name, coordinates)
    end

    private def cast_spell_at_coordinates(uuid : String, spell_name : String, coordinates : Coordinates)
      effect = SpellFactory.create_effect(spell_name)
      spell = Spell.new(uuid, spell_name, effect)
      update_coordinate_attributes(coordinates, effect)
      add_spell_to_log(coordinates, spell)
      GameStateManager.save(@game_state)
    end

    private def update_coordinate_attributes(coordinates : Coordinates, effect : SpellEffect)
      current_attrs = @game_state.get_coordinate_attributes(coordinates.x, coordinates.y)
      new_attrs = current_attrs.apply_changes(effect.attribute_changes)
      @game_state.set_coordinate_attributes(coordinates.x, coordinates.y, new_attrs)
    end

    private def add_spell_to_log(coordinates : Coordinates, spell : Spell)
      coord_array = [coordinates.x, coordinates.y]
      log_manager = GameLogManager.new(@game_state)
      log_manager.add_spell_to_log(coord_array, spell)
      log_spell_effects(spell.cast_by, spell.spell_name, coordinates, spell.effect)
    end

    private def log_spell_effects(uuid : String, spell_name : String, coordinates : Coordinates, effect : SpellEffect)
      coord_str = "(#{coordinates.x},#{coordinates.y})"
      attrs = @game_state.get_coordinate_attributes(coordinates.x, coordinates.y)
      log_msg = "#{spell_name} at #{coord_str} - Roll: #{effect.dice_roll}, New attributes: #{attrs}"
      Logger.log_command(uuid, "SPELL_ATTRIBUTES", log_msg)
    end

    private def broadcast_spell_cast(uuid : String, spell_name : String, coordinates : Coordinates)
      player_name = @player_manager.player_names[uuid]? || uuid
      message = "#{player_name} cast #{spell_name} at #{coordinates}"
      @message_handler.broadcast_message(PlayerActionMessage.new(message))
    end

    private def send_error(uuid : String, error : String)
      @message_handler.send_message_to_player(uuid, ErrorMessage.new(error))
    end
  end
end
