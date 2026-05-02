# Operation Cat-mosphere Project Guide

## Tech Stack
- **Engine:** Godot 4.x (Latest Stable)
- **Language:** GDScript
- **Architecture:** Node-based Composition, Signal-driven communication

## Project Structure
- `res://scenes/`: UI, Level, Tower, Enemy, Hero, Projectile scenes
- `res://scripts/`: Common and entity scripts (Autoloads included)
- `res://assets/`: Sprites, audio, font resources
- `res://resources/`: EnemyData, TowerData custom Resource files (.tres)

## Coding Guidelines
- **Naming:**
  - Nodes: PascalCase (e.g. `TowerBase`)
  - Variables/Functions: snake_case (e.g. `target_enemy`, `_on_area_entered`)
  - Constants: SCREAMING_SNAKE_CASE (e.g. `MAX_HEALTH`)
- **Patterns:**
  - Prefer component (Node) composition over inheritance
  - Use Signals for parent-child communication to reduce coupling
  - Use type hints actively (`var speed: float = 10.0`)

## Harness Rules
1. **Node Path:** Prefer `@onready var` with `%UniqueName` over `get_node()`
2. **Resource:** Tower/Enemy stats must be managed as `.tres` files (Resource) for data/logic separation
3. **Performance:** Use Timer/Signal instead of heavy computation in `_process` for large enemy counts

## Autoloads
- `GameManager` — Game phase (DAY/NIGHT/DAWN), base HP, stage management
- `ResourceManager` — Scrap/Essence/Catnip economy
- `DamageCalculator` — 3-type damage multiplier matrix with reflection
- `SfxManager` — Audio pool (placeholder)

## Key Design Reference
- See `Operation_Cat-mosphere.md` (PRD v2.0) for all game design specs
- 3 attack types: LOW_TECH / HI_TECH / MYSTIC
- 3 defense types: NORMAL / MIRROR / STEEL_CAN
- Modular tower stacking: max 5 floors, +15% range/floor, +5% crit/floor
