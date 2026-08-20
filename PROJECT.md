# Project: Pinto 2D Top-Down Survival Arena

## Architecture
- **Engine**: Godot 4.7.2 (GDScript 2.0)
- **Base Viewport**: 640 x 360 (16:9 pixel-art native)
- **Display Stretch**: mode="canvas_items", aspect="keep", window_override=1280x720 (2x integer scale)
- **World & Arena Dimensions**: 1280 x 720 (Camera2D zoom=1.0x centered on player, clamped [0, 0, 1280, 720])
- **Sprite Animation Architecture**: Sprite2D with `hframes = 4`, animated frame cycling (6-8 FPS) via timer-driven frame index in `_physics_process()`. Swarm desynchronization via randomized initial timer/frame.
- **Visual Feedback Architecture**: Modulate hurt flash (white/red, 0.08s duration) restoring `base_modulate` (preserving Boss phase tints).
- **Floating Damage Popup Architecture**: `Node2D` + `Label` at `scenes/ui/damage_number.tscn` (`z_index = 50`), instantiated in `EnemyBase.take_damage()`, added to `_get_spawn_container()` via `call_deferred("add_child", popup)`, animated via SceneTree Tween (20px rise, 1.2->1.0 scale pop, 0.5s alpha fadeout, `queue_free()`).
- **Physics Space Management**: Deferred node insertion (`call_deferred("add_child", ...)`) and deferred collision/monitoring mutation (`set_deferred(...)`) during space query flushes.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Resolution & Stretch Settings | Set viewport 640x360, canvas_items, keep aspect, 1280x720 window override | M1 | User Request R1 (Done) |
| 2 | Camera2D Zoom & Arena Clamping | Zoom Vector2(1.0, 1.0), centered on player, limits [0, 0, 1280, 720], no black borders | M1 | User Request R1 (Done) |
| 3 | HUD UI Anchoring & Scaling | Ensure HUD and modal UI scale and anchor correctly to screen edges at 640x360 | M1 | User Request R1 (Done) |
| 4 | Physics Query Flushing - XP Gems & Enemy Base | Use call_deferred to add gems and sfx, set_deferred for collision/monitoring | M2 | User Request R2 (Done) |
| 5 | Physics Query Flushing - Boss, Projectiles & Pickups | Defer add_child and collision disables across boss, projectiles, drones, spawner | M2 | User Request R2 (Done) |
| 6 | GDScript Warnings - EventBus Unused Signals | Add @warning_ignore("unused_signal") to autoload/event_bus.gd | M3 | User Request R3 (Done) |
| 7 | GDScript Warnings - Unused Parameters | Prefix unused parameters with underscore (_max_hp, _score_val) | M3 | User Request R3 (Done) |
| 8 | GDScript Warnings - Integer Divisions & Unused Loop Var | Convert int/int division to float division and rename loop index _i | M3 | User Request R3 (Done) |
| 9 | Headless Test Suite Verification | Run all 12 test suites headlessly, verify 100% pass with exit code 0 | M4 | User Request R4 (Done) |
| 10 | Git Commit & Push to origin/main | Commit all verified changes and push cleanly to origin/main | M4 | User Request R4 (Done) |
| 11 | Enemy Sprite2D Configuration | Configure Sprite2D hframes = 4 in enemy_base.tscn, enemy_slime.tscn, enemy_bat.tscn, enemy_drone.tscn, enemy_golem.tscn, boss_giga_null.tscn | M5 | User Request R1 (2026-08-20T08:24:04Z) |
| 12 | Enemy Frame Animation Cycling | Animate frame cycling (6-8 FPS) across all 4 enemies and Boss in _physics_process | M5 | User Request R1 (2026-08-20T08:24:04Z) |
| 13 | Hurt Flash & Phase Modulate | Modulate white/red for 0.08s on hit, preserving Boss phase tints with base_modulate | M5 | User Request R1 (2026-08-20T08:24:04Z) |
| 14 | Floating Damage Number Scene | Create scenes/ui/damage_number.tscn and damage_number.gd with tween float/scale/fade | M6 | User Request R2 (2026-08-20T08:24:04Z) |
| 15 | Damage Number Spawning Integration | Spawn popup in EnemyBase.take_damage at global_position + randf offset, add to spawn container | M6 | User Request R2 (2026-08-20T08:24:04Z) |
| 16 | Test Suite Enhancement | Write comprehensive unit and integration tests for animations & damage numbers | M7 | User Request R3 (2026-08-20T08:24:04Z) |
| 17 | Verification & Git Push | Run 100% headless tests, commit and push to GitHub origin/main | M7 | User Request R3 (2026-08-20T08:24:04Z) |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Resolution, Viewport & Camera Setup | project.godot, scenes/main.tscn, scenes/main.gd | none | DONE |
| M2 | Physics Query Flushing Fix | scenes/enemies/enemy_base.gd, xp_gem.gd, boss_giga_null.gd, projectile.gd | none | DONE |
| M3 | GDScript Warnings Cleanup | autoload/event_bus.gd, autoload/audio_manager.gd, autoload/game_state.gd | none | DONE |
| M4 | Initial Verification & Push | Run test runner, git push origin/main | M1, M2, M3 | DONE |
| M5 | Enemy Sprite Animation (R1) | enemy_base.tscn, enemy_slime.tscn, enemy_bat.tscn, enemy_drone.tscn, enemy_golem.tscn, boss_giga_null.tscn, enemy_base.gd, boss_giga_null.gd, enemy_*.gd | M1-M4 | IN_PROGRESS |
| M6 | Floating Damage Numbers (R2) | scenes/ui/damage_number.tscn, scenes/ui/damage_number.gd, enemy_base.gd | M5 | IN_PROGRESS |
| M7 | Test Suite & Git Push (R3) | tests/test_enemy_animations_and_damage_popups.gd, test_runner.gd, git push | M5, M6 | PLANNED |

## Code Layout
- `new-game-project/scenes/enemies/`:
  - `enemy_base.tscn`, `enemy_base.gd`
  - `enemy_slime.tscn`, `enemy_slime.gd`
  - `enemy_bat.tscn`, `enemy_bat.gd`
  - `enemy_drone.tscn`, `enemy_drone.gd`
  - `enemy_golem.tscn`, `enemy_golem.gd`
- `new-game-project/scenes/boss/` (or `scenes/enemies/`):
  - `boss_giga_null.tscn`, `boss_giga_null.gd`
- `new-game-project/scenes/ui/`:
  - `damage_number.tscn`, `damage_number.gd`
- `new-game-project/tests/`:
  - `test_runner.gd`, `test_framework.gd`, all test suites

## Interface Contracts
- **Damage Popup Contract**:
  - `DamageNumber.init(amount: float, is_crit: bool, spawn_pos: Vector2) -> void`
  - Normal text: White (`#FFFFFF`), outline 2px black, scale 1.2 -> 1.0, float up 20px, 0.5s duration.
  - Crit text: Gold (`#FFD733`), outline 3px black, scale 1.4 -> 1.0, float up 20px, 0.5s duration.
  - Attaches to `_get_spawn_container()` via `container.call_deferred("add_child", popup)` (immune to enemy queue_free).
- **Enemy Animation Contract**:
  - `Sprite2D.hframes = 4` across all 5 enemy scenes.
  - Frame rate: 6.0 to 8.0 FPS (customizable via `@export var animation_fps: float`).
  - Cycling via `sprite.frame = (_current_frame + 1) % sprite.hframes` in `_physics_process()`.
  - Hurt flash sets `_flash_timer = 0.08` and resets to `base_modulate`.
