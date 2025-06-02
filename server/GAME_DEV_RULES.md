# Game Development Rules

This document outlines the core rules and constraints that govern game mechanics in the spell casting system.

## Spell System Rules

### Maximum Attribute Impact Rule

**CRITICAL RULE: The maximum impact a single spell can have on any coordinate's attribute is ±20 points.**

This rule is enforced through the use of `min()` and `max()` functions in spell calculations:

- **Positive effects**: Use `min(20, calculation)` to cap benefits at +20
- **Negative effects**: Use `-min(20, calculation)` to cap damage at -20
- **Formula evaluation**: All spell formulas are automatically clamped to the range [-20, +20]

#### Examples:

```json
{
  "wisdom": {
    "calculation": {
      "intelligence": "min(20, dice_roll * 2)"
    }
  },
  "fireball": {
    "calculation": {
      "health": "-min(20, dice_roll + 5)"
    }
  }
}
```

#### Rationale:

1. **Game Balance**: Prevents any single spell from having overwhelming impact
2. **Predictable Scaling**: Players can understand maximum possible effects
3. **Strategic Depth**: Encourages multiple spell combinations rather than relying on single powerful effects
4. **Coordinate Progression**: Ensures steady, manageable progression of coordinate attributes

### D20 Dice Roll System

- All spells use a 20-sided die (D20) for randomness
- Dice rolls range from 1 to 20 (inclusive)
- The same dice roll is used for all calculations within a single spell cast
- Dice rolls happen in real-time when spells are cast, not when loaded from JSON

### Spell Formula Evaluation

The spell system supports complex mathematical formulas:

- **Basic arithmetic**: `+`, `-`, `*`, `//` (integer division)
- **Min/Max functions**: `min(limit, value)`, `max(limit, value)`
- **Dice roll substitution**: `dice_roll` is replaced with actual roll value
- **Attribute references**: Used in `amount_calculation` formulas

### Attribute System

Coordinates can have five attributes:

1. **Constitution**: Physical resilience and defensive capability
2. **Health**: Life force and vitality
3. **Intelligence**: Mental acuity and magical aptitude  
4. **Luminosity**: Light generation and visibility
5. **Speed**: Movement and reaction time

### Spell Categories

#### Positive Spells
Beneficial effects that increase attributes:
- `wisdom`, `heal`, `shield`, `brighten`, `haste`, `strengthen`
- `energize`, `enlighten`, `glowup`, `illuminate`

#### Negative Spells  
Harmful effects that decrease attributes:
- `fireball`, `curse`, `poison`, `darken`, `slow`, `weaken`
- `blind`, `confuse`, `drain`, `exhaust`

### JSON Configuration Rules

- All spells must be defined in `/server/fixtures/spells.json`
- Spells are keyed by name in a single `"spells"` object
- Each spell must include: `name`, `type`, `effect_type`, `description`, `calculation`, `amount_calculation`
- Calculations use string formulas that are evaluated at runtime
- The ±20 limit is enforced during formula evaluation, not in JSON

### Testing Requirements

- All spells must be tested for the ±20 maximum impact rule
- Spell calculations must be verified against their JSON definitions
- Edge cases (minimum/maximum dice rolls) must be tested
- Formula evaluation correctness must be validated

## Implementation Notes

### Code Enforcement

The ±20 rule is enforced in the `SpellFactory.evaluate_formula()` method:

```crystal
result = evaluate_arithmetic(expression)
Math.max(-20, Math.min(20, result))
```

This ensures that regardless of dice roll or formula complexity, no single attribute change exceeds the ±20 limit.

### Backward Compatibility

Any changes to these rules must:

1. Maintain the ±20 maximum impact constraint
2. Preserve existing spell behavior within the constraint
3. Update tests to verify new rule compliance
4. Document the change in this file

## Version History

- **v1.0** (Initial): Established ±20 maximum attribute impact rule
- **v1.0** (Initial): Defined D20 dice roll system with JSON configuration
- **v1.0** (Initial): Implemented complex formula evaluation with min/max functions