# Project: Pinto 2D Top-Down Survival Arena - Resolution & Runtime Fixes

## Architecture
- **Engine**: Godot 4.7.2 (GDScript 2.0)
- **Base Viewport**: 640 x 360 (16:9 pixel-art native)
- **Display Stretch**: mode="canvas_items", aspect="keep", window_override=1280x720 (2x integer scale)
- **World & Arena Dimensions**: 1280 x 720 (Camera2D zoom=1.0x centered on player, clamped [0, 0, 1280, 720])
- **Physics Space Management**: Deferred node insertion (`call_deferred("add_child", ...)`) and deferred collision/monitoring mutation (`set_deferred(...)`) during space query flushes.
- **Signal & Event Bus Architecture**: Centralized `EventBus` autoload with `@warning_ignore("unused_signal")`.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Resolution & Stretch Settings | Set viewport 640x360, canvas_items, keep aspect, 1280x720 window override | M1 | Survey / User Request §1 |
| 2 | Camera2D Zoom & Arena Clamping | Zoom Vector2(1.0, 1.0), centered on player, limits [0, 0, 1280, 720], no black borders | M1 | Survey / User Request §1 |
| 3 | HUD UI Anchoring & Scaling | Ensure HUD and modal UI scale and anchor correctly to screen edges at 640x360 | M1 | Survey / User Request §1 |
| 4 | Physics Query Flushing - XP Gems & Enemy Base | Use call_deferred to add gems and sfx, set_deferred for collision/monitoring | M2 | Survey / User Request §2 |
| 5 | Physics Query Flushing - Boss, Projectiles & Pickups | Defer add_child and collision disables across boss, projectiles, drones, spawner | M2 | Survey / User Request §2 |
| 6 | GDScript Warnings - EventBus Unused Signals | Add @warning_ignore("unused_signal") to autoload/event_bus.gd | M3 | Survey / User Request §3 |
| 7 | GDScript Warnings - Unused Parameters | Prefix unused parameters with underscore (_max_hp, _score_val) | M3 | Survey / User Request §3 |
| 8 | GDScript Warnings - Integer Divisions & Unused Loop Var | Convert int/int division to float division and rename loop index _i | M3 | Survey / User Request §3 |
| 9 | Headless Test Suite Verification | Run all 12 test suites headlessly, verify 100% pass with exit code 0 | M4 | Survey / User Request §4 |
| 10 | Git Commit & Push to origin/main | Commit all verified changes and push cleanly to origin/main | M4 | Survey / User Request §4 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Resolution, Viewport & Camera Setup | project.godot, scenes/main.tscn, scenes/main.gd, test zoom/resolution assertions | none | DONE |
| M2 | Physics Query Flushing Fix | scenes/enemies/enemy_base.gd, xp_gem.gd, boss_giga_null.gd, projectile.gd, enemy_projectile.gd, player.gd, enemy_drone.gd, spawner.gd | none | DONE |
| M3 | GDScript Warnings Cleanup | autoload/event_bus.gd, autoload/audio_manager.gd, autoload/game_state.gd, scenes/ui/*.gd, tests/*.gd | none | DONE |
| M4 | Verification & Git Push | Run headless test runner (12 suites, 144 tests), verify 100% pass, git push origin/main | M1, M2, M3 | IN_PROGRESS |

## Code Layout
- `new-game-project/project.godot`: Display / window resolution settings
- `new-game-project/autoload/`: `event_bus.gd`, `audio_manager.gd`, `game_state.gd`
- `new-game-project/scenes/enemies/`: `enemy_base.gd`, `boss_giga_null.gd`, `enemy_drone.gd`
- `new-game-project/scenes/pickups/`: `xp_gem.gd`
- `new-game-project/scenes/weapons/`: `projectile.gd`, `enemy_projectile.gd`
- `new-game-project/scenes/player/`: `player.gd`, `player.tscn`
- `new-game-project/scenes/world/`: `arena.gd`, `spawner.gd`
- `new-game-project/scenes/ui/`: `hud.gd`, `game_over_screen.gd`, `victory_screen.gd`, `upgrade_menu.gd`
- `new-game-project/scenes/`: `main.tscn`, `main.gd`
- `new-game-project/tests/`: `test_runner.gd`, `test_framework.gd`, all 12 test suites

## Interface Contracts
- **Camera2D Contract**: Zoom = Vector2(1.0, 1.0), position tracks Player, limit_left=0, limit_top=0, limit_right=1280, limit_bottom=720.
- **Node Spawning Contract**: All runtime dynamic nodes created during physics callbacks (`take_damage`, `die`, `collect`, `_on_area_entered`, `_on_body_entered`) must be initialized with their properties/positions FIRST, then added to tree via `container.call_deferred("add_child", node)`.
- **Collision Deactivation Contract**: Physics shapes and area monitors must be disabled using `.set_deferred("disabled", true)`, `.set_deferred("monitoring", false)`, `.set_deferred("monitorable", false)`.
