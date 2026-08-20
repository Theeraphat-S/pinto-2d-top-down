# Project: Pinto 2D Top-Down Survival Arena

## Architecture
Pinto 2D Top-Down Survival Arena is built in Godot 4.7.2 using a clean component-based 2D architecture adhering to Catlike Coding True Top-Down 2D principles.

### Engine Configuration
- **Resolution**: 640x360 base viewport with integer scaling (`canvas_items`, `integer`)
- **Rendering**: Nearest-neighbor texture filtering (`default_texture_filter=0`), pixel transform snapping (`snap_2d_transforms_to_pixel=true`)
- **Physics**: 2D Floating motion mode (`MOTION_MODE_FLOATING`), Y-sorted entity rendering (`y_sort_enabled=true`), foot-level collision shapes

### Collision Layer Matrix (2D Physics)
- **Layer 1 (World/Obstacles)**: Arena boundaries, solid obstacles, rocks, props
- **Layer 2 (Player)**: Pinto CharacterBody2D
- **Layer 3 (Enemies)**: Enemy CharacterBody2D / Area2D
- **Layer 4 (Player Projectiles)**: Projectiles fired by Pinto
- **Layer 5 (Enemy Projectiles)**: Projectiles fired by Boss/Enemies
- **Layer 6 (Pickups/XP Gems)**: Collectible XP gems and powerups
- **Layer 7 (Player Magnet Area)**: Attraction trigger radius around Pinto
- **Layer 8 (Hurtboxes/Hitboxes)**: Detection areas for melee contact damage

### Autoload Singletons
1. `EventBus` (`res://autoload/event_bus.gd`): Global decoupled signal routing for health changes, wave events, level-ups, card drafts, boss triggers, and game over/victory.
2. `GameState` (`res://autoload/game_state.gd`): In-memory runtime state for score, kills, elapsed time, current wave, player stats, active upgrades.
3. `SaveManager` (`res://autoload/save_manager.gd`): Persistent storage for high score, best survival time, run history to `user://save_data.json`.
4. `UpgradeCatalog` (`res://autoload/upgrade_catalog.gd`): Repository of all 10+ upgrade card definitions, rarities, weights, and stat application callbacks.

---

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Pixel Art Asset Pipeline | Procedural & textured pixel art generation for Pinto, 4 enemies, Boss, tileset, props, XP gems, UI cards | M1 | Survey |
| 2 | EventBus Global Routing | Centralized signal dispatch for all game events | M1 | Survey |
| 3 | GameState Management | Runtime state tracking (score, kills, wave, stats) | M1 | Survey |
| 4 | SaveManager Persistence | JSON save/load system for high score and best survival time | M1, M5 | R5 |
| 5 | UpgradeCatalog Definitions | 10+ upgrade cards with distinct stat modifiers and weights | M1, M5 | R3 |
| 6 | 8-Directional Movement | Responsive WASD/Arrow input with acceleration and friction damping | M2 | R1 |
| 7 | Floating Kinematics | Normalized velocity vector avoiding diagonal speed boost | M2 | R1 |
| 8 | Pinto Spritesheet & Animations | Idle, walk (down/up/side), hurt, death faithful to reference | M2 | R1 |
| 9 | Auto-Attack Nearest Enemy | Dynamic nearest-neighbor spatial scan within weapon range | M2 | R1 |
| 10 | Projectile Ballistics | Linear velocity, lifetime timeout, impact handling | M2 | R1 |
| 11 | Multi-Shot & Spread | Symmetrical angular distribution for multiple projectiles | M2 | R1, R3 |
| 12 | Bullet Pierce | Projectile penetration counter before despawning | M2 | R3 |
| 13 | TileMapLayer Arena | 1280x720 enclosed cyber-circuit arena with autotiling | M3 | R4 |
| 14 | Boundary & Obstacle Collisions | Physics collision borders and obstacle colliders | M3 | R4 |
| 15 | Y-Sorting & Depth Ordering | Dynamic Z-indexing with foot-level pivot anchors | M3 | R4 |
| 16 | Contact Drop Shadows | Soft oval shadows anchoring entities to ground plane | M3 | R4 |
| 17 | Decorative Arena Props | Pillar, computer terminal, energy crystal props with collisions | M3 | R4 |
| 18 | Enemy Archetype: Glitch Slime | Swarm melee chaser, low HP, fast spawn rate | M4 | R2 |
| 19 | Enemy Archetype: Cyber Bat | Fast flyer, erratic flanking zig-zag motion | M4 | R2 |
| 20 | Enemy Archetype: CRT Drone | Ranged shooter, keeps distance and fires energy orbs | M4 | R2 |
| 21 | Enemy Archetype: Megabyte Golem | Tanky bruiser, high HP, heavy contact damage | M4 | R2 |
| 22 | 5-Wave Escalating Spawner | Time/budget-based wave escalation with distinct enemy mixes | M4 | R2 |
| 23 | Wave 5 Boss: GIGA-NULL | 3-phase climax boss (Radial burst, Minions+Volley, Dash+Spiral) | M4 | R2 |
| 24 | XP Gem Drop System | Enemies drop tiered XP gems upon death (Small, Medium, Large) | M4 | R2 |
| 25 | Magnetic Attraction Physics | Exponential acceleration towards player once within magnet radius | M4 | R2 |
| 26 | Quadratic XP Level Curve | Threshold formula XP_req(L) = floor(10 + (L-1)*15 + (L-1)^2*5) | M5 | R3 |
| 27 | 3-Card Upgrade Modal | Interactive pause-mode draft presenting 3 distinct random cards | M5 | R3 |
| 28 | 10 Stat Upgrade Cards | Damage, Attack Speed, Move Speed, Max HP, Projectiles, Pierce, Range, Magnet, Regen, Crit | M5 | R3 |
| 29 | Real-Time HUD | Health bar, XP bar, Level counter, Wave counter, Timer, Score | M5 | R5 |
| 30 | Victory Screen Modal | Wave 5 clear banner, run stats, high score update, Restart/Quit | M5 | R5 |
| 31 | Game Over Screen Modal | 0 HP defeat screen, survival time, retry option, persistence sync | M5 | R5 |
| 32 | High Score & Time Persistence | Automatic save/load to user://save_data.json with error recovery | M5 | R5 |
| 33 | Headless Test Framework | Zero-dependency assertion engine (test_framework.gd) | M_E2E | R6 |
| 34 | Headless Test Runner CLI | CLI executable test suite (test_runner.gd) running all tests | M_E2E | R6 |
| 35 | E2E Suite: Player & Combat | Automated headless tests for R1 movement, kinematics, auto-target, projectiles | M_E2E | R6 |
| 36 | E2E Suite: Waves, Enemies & Boss | Automated headless tests for R2 wave progression, enemy stats, boss phases, gems | M_E2E | R6 |
| 37 | E2E Suite: Roguelite & Upgrades | Automated headless tests for R3 XP curve, 3-card draft, stat modifications | M_E2E | R6 |
| 38 | E2E Suite: Arena & Collisions | Automated headless tests for R4 bounds, obstacle collisions, Y-sorting | M_E2E | R6 |
| 39 | E2E Suite: HUD & Save Persistence | Automated headless tests for R5 save/load roundtrips, score tracking, win/loss triggers | M_E2E | R6 |

---

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M_E2E | E2E Testing Suite Track | Design test framework, test runner, and comprehensive Tiers 1-4 test suites (covering R1-R6) | none | DONE |
| M1 | Core Framework & Asset Pipeline | Generate/bake pixel art assets for Pinto, 4 enemies, Boss, tileset, UI; Implement Autoloads (EventBus, GameState, SaveManager, UpgradeCatalog) | none | DONE |
| M2 | Player Character "Pinto" & Combat System | Pinto CharacterBody2D, WASD kinematics, animations, auto-targeting nearest enemy, projectile ballistics, multi-shot & pierce | M1 | DONE |
| M3 | TileMap Arena, Props & World Collision | 1280x720 enclosed arena, TileMapLayer terrain, decorative props, boundary colliders, Y-sorting depth, drop shadows | M1 | DONE |
| M4 | Enemies, 5 Waves, Boss & XP Magnetics | 4 enemy archetypes, 5-wave budget spawner, 3-phase Wave 5 Boss ("GIGA-NULL"), XP gems & magnet attraction | M1, M2, M3 | DONE |
| M5 | Roguelite Upgrades, HUD & Game Lifecycle | Quadratic XP leveling, 3-card upgrade draft modal, 10 upgrade cards, real-time HUD, Victory/Game Over modals, save persistence | M1, M2, M4 | DONE |
| M6 | Final Integration & Test Pass (Tiers 1-5) | 100% E2E test pass (Tiers 1-4) + Tier 5 Adversarial Coverage Hardening + Forensic Audit PASS | M_E2E, M5 | DONE |

---

## Interface Contracts

### 1. `EventBus` (`res://autoload/event_bus.gd`)
```gdscript
signal player_health_changed(current_hp: float, max_hp: float)
signal player_died()
signal xp_collected(amount: int, current_xp: int, xp_required: int, current_level: int)
signal level_up_triggered(new_level: int, offered_cards: Array)
signal upgrade_selected(card_id: String)
signal wave_started(wave_number: int, duration_seconds: float)
signal wave_completed(wave_number: int)
signal boss_spawned(boss_node: Node2D)
signal boss_defeated()
signal enemy_killed(enemy_type: String, score_value: int)
signal game_won()
signal game_lost()
signal score_updated(new_score: int)
```

### 2. `GameState` (`res://autoload/game_state.gd`)
```gdscript
var current_wave: int = 1
var score: int = 0
var enemies_killed: int = 0
var elapsed_time: float = 0.0
var is_game_active: bool = false
var is_paused: bool = false

# Pinto Runtime Stats (base + upgrades)
var max_health: float = 100.0
var current_health: float = 100.0
var move_speed: float = 160.0
var attack_damage: float = 20.0
var attack_cooldown: float = 0.5 # attacks per second = 1/attack_cooldown
var attack_range: float = 220.0
var projectile_count: int = 1
var projectile_pierce: int = 1
var projectile_speed: float = 380.0
var magnet_radius: float = 90.0
var health_regen: float = 0.0 # HP per second
var crit_chance: float = 0.05 # 5% base crit
var crit_multiplier: float = 1.5

func reset_run() -> void
func add_xp(amount: int) -> void
func apply_upgrade(card_id: String) -> void
func take_damage(amount: float) -> void
func heal(amount: float) -> void
```

### 3. `SaveManager` (`res://autoload/save_manager.gd`)
```gdscript
const SAVE_PATH: String = "user://save_data.json"
var high_score: int = 0
var best_survival_time: float = 0.0
var total_games_played: int = 0
var total_victories: int = 0

func load_game() -> bool
func save_game() -> bool
func record_run_result(final_score: int, survival_time: float, won: bool) -> void
```

### 4. `UpgradeCatalog` (`res://autoload/upgrade_catalog.gd`)
```gdscript
# Card schema: { id: String, title: String, description: String, rarity: int, max_rank: int, apply_fn: Callable }
func get_random_upgrade_cards(count: int = 3) -> Array[Dictionary]
func apply_card(card_id: String) -> void
```

---

## Code Layout
```
new-game-project/
├── project.godot
├── autoload/
│   ├── event_bus.gd
│   ├── game_state.gd
│   ├── save_manager.gd
│   └── upgrade_catalog.gd
├── assets/
│   ├── sprites/
│   │   ├── pinto_spritesheet.png
│   │   ├── enemies/ (slime, bat, drone, golem, boss_giga_null)
│   │   ├── projectiles/ (bullet, laser, energy_orb)
│   │   └── pickups/ (xp_small, xp_med, xp_large)
│   ├── tilesets/
│   │   ├── arena_tileset.png
│   │   └── props.png
│   ├── ui/
│   │   ├── card_background.png
│   │   └── icons/ (10 upgrade icons)
│   └── sfx/ (shoot, hit, explosion, gem_pickup, levelup, game_over, victory)
├── scenes/
│   ├── main.tscn (Main Game Loop Scene)
│   ├── main.gd
│   ├── player/
│   │   ├── player.tscn
│   │   ├── player.gd
│   │   └── pinto_frames.tres
│   ├── weapons/
│   │   ├── projectile.tscn
│   │   ├── projectile.gd
│   │   ├── enemy_projectile.tscn
│   │   └── enemy_projectile.gd
│   ├── enemies/
│   │   ├── enemy_base.tscn
│   │   ├── enemy_base.gd
│   │   ├── enemy_slime.tscn
│   │   ├── enemy_slime.gd
│   │   ├── enemy_bat.tscn
│   │   ├── enemy_bat.gd
│   │   ├── enemy_drone.tscn
│   │   ├── enemy_drone.gd
│   │   ├── enemy_golem.tscn
│   │   ├── enemy_golem.gd
│   │   ├── boss_giga_null.tscn
│   │   └── boss_giga_null.gd
│   ├── pickups/
│   │   ├── xp_gem.tscn
│   │   └── xp_gem.gd
│   ├── world/
│   │   ├── arena.tscn
│   │   ├── arena.gd
│   │   ├── prop.tscn
│   │   ├── prop.gd
│   │   ├── spawner.tscn
│   │   └── spawner.gd
│   └── ui/
│       ├── hud.tscn
│       ├── hud.gd
│       ├── upgrade_menu.tscn
│       ├── upgrade_menu.gd
│       ├── upgrade_card.tscn
│       ├── upgrade_card.gd
│       ├── victory_screen.tscn
│       ├── victory_screen.gd
│       ├── game_over_screen.tscn
│       └── game_over_screen.gd
├── scripts/
│   └── asset_generator.gd (Headless Pixel Art Asset Generator)
└── tests/
    ├── test_framework.gd (Zero-dependency Assertion Engine)
    ├── test_runner.gd (Headless CLI Test Suite Runner)
    ├── test_player_movement.gd (R1 Movement & Kinematics)
    ├── test_player_combat.gd (R1 Auto-Targeting, Projectiles, Multi-shot)
    ├── test_waves_and_enemies.gd (R2 Wave Progression, Enemy Stats, Boss)
    ├── test_xp_and_magnet.gd (R2 XP Drops, Magnetics, Quadratic Curve)
    ├── test_roguelite_upgrades.gd (R3 3-Card Draft, Stat Modifiers)
    ├── test_arena_and_collisions.gd (R4 Arena Bounds, Obstacles, Y-sorting)
    ├── test_hud_and_persistence.gd (R5 Save/Load, Modals, Scoring)
    ├── test_adversarial_coverage.gd (Tier 5 Kinematics & Coverage Stress)
    └── test_adversarial_stress.gd (Tier 5 Edge Case & Stress Testing)
```
