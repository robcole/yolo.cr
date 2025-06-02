require "../models/spell"
require "../models/spell_definition"
require "file"

module GameServer
  module SpellFactory
    FIXTURES_PATH = File.join(__DIR__, "../../../fixtures/spells.json")

    @@spell_definitions = {} of String => SpellDefinition

    private def self.roll_d20 : Int32
      Random.rand(1..20)
    end

    private def self.load_spell_definitions
      return unless @@spell_definitions.empty?
      content = File.read(FIXTURES_PATH)
      spell_book = SpellBookDefinition.from_json(content)
      spell_book.spells.each do |name, config|
        definition = SpellDefinition.new(
          name: config.name,
          type: config.type,
          effect_type: config.effect_type,
          description: config.description,
          calculation: config.calculation,
          amount_calculation: config.amount_calculation
        )
        @@spell_definitions[name.downcase] = definition
      end
    end

    private def self.get_spell_definition(spell_name : String) : SpellDefinition?
      load_spell_definitions
      @@spell_definitions[spell_name.downcase]?
    end

    private def self.calculate_effect(spell_name : String, dice_roll : Int32) : {String, Int32, AttributeChanges}
      definition = get_spell_definition(spell_name)
      return unknown_effect unless definition
      process_spell_definition(definition, dice_roll)
    end

    private def self.process_spell_definition(definition : SpellDefinition, dice_roll : Int32) : {String, Int32, AttributeChanges}
      changes = calculate_attribute_changes(definition, dice_roll)
      amount = calculate_total_amount(definition, changes, dice_roll)
      {definition.effect_type, amount, changes}
    end

    private def self.calculate_attribute_changes(definition : SpellDefinition, dice_roll : Int32) : AttributeChanges
      constitution = evaluate_calculation(definition.calculation["constitution"]?, dice_roll)
      health = evaluate_calculation(definition.calculation["health"]?, dice_roll)
      intelligence = evaluate_calculation(definition.calculation["intelligence"]?, dice_roll)
      luminosity = evaluate_calculation(definition.calculation["luminosity"]?, dice_roll)
      speed = evaluate_calculation(definition.calculation["speed"]?, dice_roll)
      AttributeChanges.new(constitution, health, intelligence, luminosity, speed)
    end

    private def self.evaluate_calculation(formula : String?, dice_roll : Int32) : Int32
      return 0 unless formula
      evaluate_formula(formula, dice_roll)
    end

    private def self.evaluate_formula(formula : String, dice_roll : Int32) : Int32
      expression = formula.gsub("dice_roll", dice_roll.to_s)

      if expression.starts_with?("-") && expression.includes?('(')
        if match = expression.match(/^-\((.+)\)$/)
          inner_expression = match[1]
          inner_expression = handle_min_function(inner_expression)
          inner_expression = handle_max_function(inner_expression)
          inner_result = evaluate_arithmetic(inner_expression)
          result = -inner_result
          return Math.max(-20, Math.min(20, result))
        end
      end

      expression = handle_min_function(expression)
      expression = handle_max_function(expression)
      result = evaluate_arithmetic(expression)
      Math.max(-20, Math.min(20, result))
    end

    private def self.handle_min_function(expression : String) : String
      while match = expression.match(/min\((\d+),\s*([^)]+)\)/)
        limit = match[1].to_i
        value_expr = match[2]
        value = evaluate_arithmetic(value_expr)
        result = Math.min(limit, value)
        expression = expression.sub(match[0], result.to_s)
      end
      expression
    end

    private def self.handle_max_function(expression : String) : String
      while match = expression.match(/max\((\d+),\s*([^)]+)\)/)
        limit = match[1].to_i
        value_expr = match[2]
        value = evaluate_arithmetic(value_expr)
        result = Math.max(limit, value)
        expression = expression.sub(match[0], result.to_s)
      end
      expression
    end

    private def self.evaluate_arithmetic(expression : String) : Int32
      expression = expression.strip

      if expression.match(/^-?\d+$/)
        return expression.to_i
      end

      if expression.includes?("//")
        parts = expression.split("//", 2)
        left = evaluate_arithmetic(parts[0].strip)
        right = evaluate_arithmetic(parts[1].strip)
        return left // right
      end

      if expression.includes?("*") && !expression.includes?("//")
        parts = expression.split("*", 2)
        left = evaluate_arithmetic(parts[0].strip)
        right = evaluate_arithmetic(parts[1].strip)
        return left * right
      end

      handle_addition_subtraction(expression)
    end

    private def self.handle_addition_subtraction(expression : String) : Int32
      expression = expression.strip
      return 0 if expression.empty?
      return expression.to_i if simple_number?(expression)

      parse_addition_subtraction(expression)
    end

    private def self.simple_number?(expression : String) : Bool
      !expression.includes?('+') && expression.count('-') <= 1
    end

    private def self.parse_addition_subtraction(expression : String) : Int32
      result = 0
      current_number = ""
      current_operator = "+"
      full_expression = expression + "+"

      full_expression.each_char do |char|
        if char == '+' || char == '-'
          result = apply_operation(result, current_number, current_operator)
          current_number = ""
          current_operator = char.to_s
        else
          current_number += char unless char.whitespace?
        end
      end

      result
    end

    private def self.apply_operation(result : Int32, number_str : String, operator : String) : Int32
      return result if number_str.strip == ""
      number = number_str.strip.to_i
      operator == "+" ? result + number : result - number
    end

    private def self.calculate_total_amount(definition : SpellDefinition, changes : AttributeChanges, dice_roll : Int32) : Int32
      formula = definition.amount_calculation

      formula = formula.gsub("constitution", changes.constitution.to_s)
      formula = formula.gsub("health", changes.health.to_s)
      formula = formula.gsub("intelligence", changes.intelligence.to_s)
      formula = formula.gsub("luminosity", changes.luminosity.to_s)
      formula = formula.gsub("speed", changes.speed.to_s)
      formula = formula.gsub("dice_roll", dice_roll.to_s)

      evaluate_arithmetic(formula)
    end

    private def self.unknown_effect
      changes = AttributeChanges.new
      {"Unknown", 0, changes}
    end

    def self.create_effect(spell_name : String) : SpellEffect
      dice_roll = roll_d20
      effect_type, amount, attribute_changes = calculate_effect(spell_name, dice_roll)
      SpellEffect.new(effect_type, amount, dice_roll, attribute_changes)
    end
  end
end
