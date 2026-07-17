# Void Slicer Development Instructions

## Project

Void Slicer is a Godot 4 2D incremental combat game.

The game combines:

- endless incremental progression
- automatic weapon combat
- manual slicing
- enemy farming
- sector progression
- bosses
- run upgrades
- permanent research
- prestige resets
- offline progression

## Development Approach

Always inspect relevant scenes and scripts before modifying them.

For large features:

1. Explain the current implementation.
2. Propose a small implementation phase.
3. List files that will change.
4. Implement only the approved phase.
5. Check for parse errors and broken references.
6. Summarize changes and provide testing instructions.

Never redesign several major systems in one task.

Prefer extending working systems over replacing them.

## Godot Rules

- Target Godot 4.
- Use typed GDScript.
- Explicitly type variables, arrays, dictionaries, function arguments, and return values where practical.
- Avoid Variant inference warnings.
- Warnings may be treated as errors.
- Check node validity before accessing nodes.
- Use `is_instance_valid()` where references may have been freed.
- Avoid fragile absolute scene-tree lookups.
- Prefer exported NodePaths, signals, groups, or dependency injection.
- Avoid calling deferred methods repeatedly during resize notifications.
- Do not process gameplay before required Control nodes have valid dimensions.
- Do not create endless startup waits.
- Do not modify scenes from scripts when inspector configuration is more appropriate.
- Weapon slots are manually placed in scenes and must not be generated from code.
- Preserve existing inspector assignments whenever possible.
- Do not silently rename existing signals, nodes, exported properties, resources, or save keys.
- Disconnect or validate signals when objects are removed.
- Ensure pause behavior works when reward modals are open.
- Queue simultaneous rewards rather than discarding one.

## Architecture Rules

Separate persistent progression from active-run progression.

Persistent state includes:

- Void Shards
- permanent upgrades
- research
- prestige unlocks
- unlocked weapons
- highest sector
- offline progression data
- settings

Run state includes:

- run cash
- current sector
- current stage
- weapon levels
- temporary reward modifiers
- current XP
- current boss progress
- temporary materials
- current build synergies

Avoid storing authoritative gameplay state inside UI scripts.

UI should display state and emit player intentions.

Managers or domain systems should own gameplay state.

Prefer signals for communication between systems.

## Gameplay Direction

The main combat mode is endless. It must not end because of a standard countdown timer.

The player:

1. Automatically fights continuously spawning enemies.
2. Manually slices enemies to support automation.
3. Earns cash, XP, materials, and boss progress.
4. Spends cash on repeatable run upgrades.
5. Levels weapons and unlocks milestone effects.
6. Chooses build modifiers through XP reward cards.
7. Defeats bosses to unlock sectors and systems.
8. Chooses whether to farm the current sector or advance.
9. Eventually reaches a progression wall.
10. Extracts or performs a prestige reset.
11. Purchases permanent improvements.
12. Starts again and reaches previous progress faster.

## Required Progression Layers

### Combat Resources

- Cash: repeatable upgrades during the current run
- XP: temporary build-modifier reward cards
- Materials: weapon development and extraction rewards
- Core Energy: boss progress
- Void Shards: permanent prestige currency

### Sector Structure

Use:

- sector number
- stage number
- boss stage
- farming mode
- advance mode

Players can remain in a completed stage to farm or advance to the next stage.

### Weapons

Every weapon should support:

- unique ID
- unlocked state
- equipped state
- level
- tier
- base damage
- attack interval
- targeting rules
- special behavior
- upgrade cost
- milestone effects

Initial milestone levels:

- 10
- 25
- 50
- 100
- 250

### Manual Slicing

Manual slicing should remain useful but should not remain the primary late-game damage source.

Slicing may:

- damage enemies
- mark enemies
- generate combo energy
- increase cash
- reduce ability cooldowns
- expose weak points
- temporarily multiply automated damage

### Bosses

Bosses are progression checkpoints.

Boss rewards may unlock:

- weapons
- weapon tiers
- slots
- automation
- abilities
- research
- prestige
- new sectors

### Prestige

Prestige resets active-run progression and awards Void Shards.

Prestige must never delete permanent unlocks unless a future higher reset layer explicitly says so.

## Save System

All new save values need:

- sensible defaults
- backward-compatible loading
- safe handling of missing keys
- a save version
- migration support when the structure changes

Never invalidate an existing save without explicitly warning me.

## Testing

After each implementation phase, provide:

- changed files
- new nodes or inspector assignments
- exact test steps
- expected results
- possible failure cases
- any errors that could not be verified

Do not claim that a feature works unless it has been tested or statically verified.
