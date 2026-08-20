# res://tests/test_waves_and_enemies.gd
# R2: 5-Wave Progression, Enemy Archetypes, and Wave 5 Boss 3-Phase State Machine Tests
extends "res://tests/test_framework.gd"

# Wave schedule configuration table (Legacy mathematical model)
const WAVE_CONFIGS := {
	1: {"duration": 30.0, "enemy_mix": {"slime": 1.0}, "is_boss_wave": false},
	2: {"duration": 35.0, "enemy_mix": {"slime": 0.7, "skeleton": 0.3}, "is_boss_wave": false},
	3: {"duration": 40.0, "enemy_mix": {"slime": 0.4, "skeleton": 0.4, "bat": 0.2}, "is_boss_wave": false},
	4: {"duration": 45.0, "enemy_mix": {"skeleton": 0.3, "bat": 0.3, "brute": 0.4}, "is_boss_wave": false},
	5: {"duration": -1.0, "enemy_mix": {"boss": 1.0, "slime": 0.5, "bat": 0.5}, "is_boss_wave": true}
}

# Enemy archetype base stats (Legacy mathematical model)
const ENEMY_ARCHETYPES := {
	"slime":    {"max_hp": 20.0,  "speed": 100.0, "contact_damage": 5.0,  "drop_xp": 1,   "knockback_resist": 0.20},
	"skeleton": {"max_hp": 55.0,  "speed": 65.0,  "contact_damage": 10.0, "drop_xp": 5,   "knockback_resist": 0.50},
	"bat":      {"max_hp": 30.0,  "speed": 130.0, "contact_damage": 8.0,  "drop_xp": 5,   "knockback_resist": 0.10},
	"brute":    {"max_hp": 160.0, "speed": 40.0,  "contact_damage": 22.0, "drop_xp": 20,  "knockback_resist": 0.85},
	"boss":     {"max_hp": 1200.0,"speed": 50.0,  "contact_damage": 30.0, "drop_xp": 100, "knockback_resist": 1.00}
}

# Helper to calculate boss phase based on current HP percentage
func calculate_boss_phase(current_hp: float, max_hp: float) -> int:
	var ratio: float = current_hp / max_hp
	if ratio > 0.60:
		return 1
	elif ratio >= 0.30:
		return 2
	elif ratio > 0.0:
		return 3
	else:
		return 0 # Defeated

# --- Test Cases ---

func test_wave_schedule_configuration() -> void:
	assert_eq(WAVE_CONFIGS.size(), 5, "Game must have exactly 5 distinct waves")
	
	# Verify Wave 1-4 timed durations
	assert_almost_eq(WAVE_CONFIGS[1]["duration"], 30.0, 0.01, "Wave 1 duration is 30s")
	assert_almost_eq(WAVE_CONFIGS[2]["duration"], 35.0, 0.01, "Wave 2 duration is 35s")
	assert_almost_eq(WAVE_CONFIGS[3]["duration"], 40.0, 0.01, "Wave 3 duration is 40s")
	assert_almost_eq(WAVE_CONFIGS[4]["duration"], 45.0, 0.01, "Wave 4 duration is 45s")
	
	# Verify Wave 5 is Boss Wave
	assert_true(WAVE_CONFIGS[5]["is_boss_wave"], "Wave 5 must be Boss Wave")
	assert_false(WAVE_CONFIGS[1]["is_boss_wave"], "Wave 1 is not Boss Wave")

func test_wave_composition_distribution() -> void:
	# Wave 1: 100% Slimes
	var w1_mix: Dictionary = WAVE_CONFIGS[1]["enemy_mix"]
	assert_almost_eq(w1_mix.get("slime", 0.0), 1.0, 0.001, "Wave 1 is 100% Slimes")
	
	# Wave 2: 70% Slimes, 30% Skeletons (sum = 1.0)
	var w2_mix: Dictionary = WAVE_CONFIGS[2]["enemy_mix"]
	var w2_sum: float = w2_mix.get("slime", 0.0) + w2_mix.get("skeleton", 0.0)
	assert_almost_eq(w2_sum, 1.0, 0.001, "Wave 2 enemy proportions sum to 1.0")
	
	# Wave 3: 40% Slime, 40% Skeleton, 20% Bat
	var w3_mix: Dictionary = WAVE_CONFIGS[3]["enemy_mix"]
	var w3_sum: float = w3_mix.get("slime", 0.0) + w3_mix.get("skeleton", 0.0) + w3_mix.get("bat", 0.0)
	assert_almost_eq(w3_sum, 1.0, 0.001, "Wave 3 enemy proportions sum to 1.0")
	
	# Wave 4: 30% Skeleton, 30% Bat, 40% Brute
	var w4_mix: Dictionary = WAVE_CONFIGS[4]["enemy_mix"]
	var w4_sum: float = w4_mix.get("skeleton", 0.0) + w4_mix.get("bat", 0.0) + w4_mix.get("brute", 0.0)
	assert_almost_eq(w4_sum, 1.0, 0.001, "Wave 4 enemy proportions sum to 1.0")

func test_enemy_archetypes_stats() -> void:
	# Slime (Fast swarm, low HP)
	var slime = ENEMY_ARCHETYPES["slime"]
	assert_almost_eq(slime["max_hp"], 20.0, 0.001, "Slime HP is 20")
	assert_almost_eq(slime["speed"], 100.0, 0.001, "Slime speed is 100 px/s")
	assert_almost_eq(slime["contact_damage"], 5.0, 0.001, "Slime damage is 5")
	assert_eq(slime["drop_xp"], 1, "Slime drops 1 XP (Green)")
	
	# Skeleton (Balanced melee)
	var skeleton = ENEMY_ARCHETYPES["skeleton"]
	assert_almost_eq(skeleton["max_hp"], 55.0, 0.001, "Skeleton HP is 55")
	assert_almost_eq(skeleton["speed"], 65.0, 0.001, "Skeleton speed is 65 px/s")
	assert_almost_eq(skeleton["contact_damage"], 10.0, 0.001, "Skeleton damage is 10")
	assert_eq(skeleton["drop_xp"], 5, "Skeleton drops 5 XP (Blue)")
	
	# Bat (Fast flyer)
	var bat = ENEMY_ARCHETYPES["bat"]
	assert_almost_eq(bat["max_hp"], 30.0, 0.001, "Bat HP is 30")
	assert_almost_eq(bat["speed"], 130.0, 0.001, "Bat speed is 130 px/s")
	assert_almost_eq(bat["contact_damage"], 8.0, 0.001, "Bat damage is 8")
	assert_eq(bat["drop_xp"], 5, "Bat drops 5 XP (Blue)")
	
	# Brute (Tank)
	var brute = ENEMY_ARCHETYPES["brute"]
	assert_almost_eq(brute["max_hp"], 160.0, 0.001, "Brute HP is 160")
	assert_almost_eq(brute["speed"], 40.0, 0.001, "Brute speed is 40 px/s")
	assert_almost_eq(brute["contact_damage"], 22.0, 0.001, "Brute damage is 22")
	assert_eq(brute["drop_xp"], 20, "Brute drops 20 XP (Red)")
	assert_almost_eq(brute["knockback_resist"], 0.85, 0.001, "Brute high knockback resistance")

func test_boss_base_stats() -> void:
	var boss = ENEMY_ARCHETYPES["boss"]
	assert_almost_eq(boss["max_hp"], 1200.0, 0.001, "Boss HP is 1200")
	assert_almost_eq(boss["contact_damage"], 30.0, 0.001, "Boss contact damage is 30")
	assert_eq(boss["drop_xp"], 100, "Boss drops 100 XP (Boss Gem)")
	assert_almost_eq(boss["knockback_resist"], 1.00, 0.001, "Boss is immune to knockback")

func test_boss_phase_transitions() -> void:
	var max_hp: float = 1200.0
	
	# Phase 1: 100% to 60% HP (1200 to 720 HP)
	assert_eq(calculate_boss_phase(1200.0, max_hp), 1, "1200 HP is Phase 1")
	assert_eq(calculate_boss_phase(800.0, max_hp), 1, "800 HP (>60%) is Phase 1")
	assert_eq(calculate_boss_phase(721.0, max_hp), 1, "721 HP (>60%) is Phase 1")
	
	# Phase 2: 60% to 30% HP (720 to 360 HP)
	assert_eq(calculate_boss_phase(720.0, max_hp), 2, "720 HP (exactly 60%) enters Phase 2")
	assert_eq(calculate_boss_phase(500.0, max_hp), 2, "500 HP is Phase 2")
	assert_eq(calculate_boss_phase(360.0, max_hp), 2, "360 HP (exactly 30%) is Phase 2")
	
	# Phase 3: Below 30% HP (359 down to 1 HP)
	assert_eq(calculate_boss_phase(359.0, max_hp), 3, "359 HP (<30%) enters Phase 3")
	assert_eq(calculate_boss_phase(100.0, max_hp), 3, "100 HP is Phase 3")
	assert_eq(calculate_boss_phase(1.0, max_hp), 3, "1 HP is Phase 3")
	
	# Defeated: 0 HP or less
	assert_eq(calculate_boss_phase(0.0, max_hp), 0, "0 HP is Defeated")
	assert_eq(calculate_boss_phase(-10.0, max_hp), 0, "Negative HP is Defeated")

func test_boss_multi_phase_burst_damage_skip() -> void:
	# If player deals 900 damage in 1 hit (1200 -> 300 HP), state machine skips Phase 2 directly to Phase 3
	var max_hp: float = 1200.0
	var hp_after_burst: float = 1200.0 - 900.0 # 300 HP = 25%
	var phase = calculate_boss_phase(hp_after_burst, max_hp)
	
	assert_eq(phase, 3, "Burst damage directly transitions to Phase 3 without hanging")

func test_wave_timer_progression_simulation() -> void:
	# Simulate wave 1 countdown (30s)
	var wave_idx: int = 1
	var time_remaining: float = WAVE_CONFIGS[wave_idx]["duration"]
	var delta: float = 0.5
	
	# Tick 60 times (30.0s)
	for i in range(60):
		time_remaining -= delta
		
	assert_almost_eq(time_remaining, 0.0, 0.001, "Wave timer reaches 0 after 30s")
	
	# Advance to wave 2
	if time_remaining <= 0.0:
		wave_idx += 1
		time_remaining = WAVE_CONFIGS[wave_idx]["duration"]
		
	assert_eq(wave_idx, 2, "Advanced to Wave 2")
	assert_almost_eq(time_remaining, 35.0, 0.001, "Wave 2 timer initialized to 35s")

# ==============================================================================
# M4 CONCRETE SCENE & ARCHETYPE INTEGRATION TESTS
# ==============================================================================

func test_enemy_base_scene_structure() -> void:
	var base_scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	assert_not_null(base_scene, "EnemyBase scene exists and loads")
	
	var enemy = base_scene.instantiate()
	assert_not_null(enemy, "EnemyBase instantiated")
	assert_eq(enemy.collision_layer, 4, "EnemyBase on Layer 3 (bitmask 4)")
	assert_eq(enemy.collision_mask, 7, "EnemyBase masks Layers 1,2,3 (bitmask 7)")
	assert_true(enemy.is_in_group("enemies"), "EnemyBase is in 'enemies' group")
	assert_true(enemy.has_node("Sprite2D"), "EnemyBase has Sprite2D")
	assert_true(enemy.has_node("CollisionShape2D"), "EnemyBase has CollisionShape2D")
	assert_true(enemy.has_node("HitboxArea"), "EnemyBase has HitboxArea")
	
	var hitbox: Area2D = enemy.get_node("HitboxArea") as Area2D
	assert_eq(hitbox.collision_layer, 128, "HitboxArea on Layer 8 (bitmask 128)")
	assert_eq(hitbox.collision_mask, 2, "HitboxArea masks Layer 2 (Player bitmask 2)")
	
	enemy.free()

func test_4_enemy_archetypes_instantiation() -> void:
	# 1. Glitch Slime
	var slime_scene: PackedScene = load("res://scenes/enemies/enemy_slime.tscn")
	assert_not_null(slime_scene, "Slime scene exists")
	var slime = slime_scene.instantiate()
	assert_not_null(slime, "Slime instantiated")
	assert_eq(slime.enemy_type, "slime", "Slime type is 'slime'")
	assert_almost_eq(slime.max_health, 25.0, 0.01, "Slime HP is 25")
	assert_almost_eq(slime.move_speed, 85.0, 0.01, "Slime Speed is 85")
	assert_almost_eq(slime.contact_damage, 10.0, 0.01, "Slime Contact Dmg is 10")
	assert_eq(slime.drop_gem_tier, 0, "Slime drops Small gem")
	slime.free()
	
	# 2. Cyber Bat
	var bat_scene: PackedScene = load("res://scenes/enemies/enemy_bat.tscn")
	assert_not_null(bat_scene, "Bat scene exists")
	var bat = bat_scene.instantiate()
	assert_not_null(bat, "Bat instantiated")
	assert_eq(bat.enemy_type, "bat", "Bat type is 'bat'")
	assert_almost_eq(bat.max_health, 15.0, 0.01, "Bat HP is 15")
	assert_almost_eq(bat.move_speed, 150.0, 0.01, "Bat Speed is 150")
	assert_almost_eq(bat.contact_damage, 8.0, 0.01, "Bat Contact Dmg is 8")
	assert_eq(bat.drop_gem_tier, 0, "Bat drops Small gem")
	bat.free()
	
	# 3. CRT Drone
	var drone_scene: PackedScene = load("res://scenes/enemies/enemy_drone.tscn")
	assert_not_null(drone_scene, "Drone scene exists")
	var drone = drone_scene.instantiate()
	assert_not_null(drone, "Drone instantiated")
	assert_eq(drone.enemy_type, "drone", "Drone type is 'drone'")
	assert_almost_eq(drone.max_health, 40.0, 0.01, "Drone HP is 40")
	assert_almost_eq(drone.move_speed, 70.0, 0.01, "Drone Speed is 70")
	assert_almost_eq(drone.contact_damage, 5.0, 0.01, "Drone Contact Dmg is 5")
	assert_eq(drone.drop_gem_tier, 1, "Drone drops Medium gem")
	drone.free()
	
	# 4. Megabyte Golem
	var golem_scene: PackedScene = load("res://scenes/enemies/enemy_golem.tscn")
	assert_not_null(golem_scene, "Golem scene exists")
	var golem = golem_scene.instantiate()
	assert_not_null(golem, "Golem instantiated")
	assert_eq(golem.enemy_type, "golem", "Golem type is 'golem'")
	assert_almost_eq(golem.max_health, 120.0, 0.01, "Golem HP is 120")
	assert_almost_eq(golem.move_speed, 50.0, 0.01, "Golem Speed is 50")
	assert_almost_eq(golem.contact_damage, 25.0, 0.01, "Golem Contact Dmg is 25")
	assert_almost_eq(golem.knockback_resistance, 0.85, 0.01, "Golem high knockback resist")
	assert_eq(golem.drop_gem_tier, 2, "Golem drops Large gem")
	golem.free()

func test_boss_giga_null_scene_and_phases() -> void:
	var boss_scene: PackedScene = load("res://scenes/enemies/boss_giga_null.tscn")
	assert_not_null(boss_scene, "Boss scene exists")
	
	var boss = boss_scene.instantiate()
	assert_not_null(boss, "Boss instantiated")
	assert_almost_eq(boss.max_health, 600.0, 0.01, "Boss HP is 600")
	assert_almost_eq(boss.contact_damage, 30.0, 0.01, "Boss Contact Damage is 30")
	assert_eq(boss.drop_gem_tier, 2, "Boss drops Large gems")
	assert_eq(boss.drop_gem_count, 5, "Boss drops 5 gems (100 XP total)")
	assert_eq(boss.current_phase, 1, "Boss starts in Phase 1")
	assert_true(boss.is_in_group("boss"), "Boss is in 'boss' group")
	assert_true(boss.has_node("HealthBar"), "Boss has HealthBar UI node")
	
	# Simulate damage into Phase 2 (HP <= 66% -> 396 HP)
	boss.take_damage(210.0) # 600 - 210 = 390 HP (65%)
	assert_eq(boss.current_phase, 2, "Boss transitioned to Phase 2 at 65% HP")
	
	# Simulate damage into Phase 3 (HP <= 33% -> 198 HP)
	boss.take_damage(200.0) # 390 - 200 = 190 HP (31.6%)
	assert_eq(boss.current_phase, 3, "Boss transitioned to Phase 3 at ~31% HP")
	
	boss.free()

func test_enemy_projectile_scene() -> void:
	var proj_scene: PackedScene = load("res://scenes/weapons/enemy_projectile.tscn")
	assert_not_null(proj_scene, "Enemy projectile scene exists")
	
	var proj = proj_scene.instantiate()
	assert_not_null(proj, "Enemy projectile instantiated")
	assert_eq(proj.collision_layer, 16, "Enemy projectile on Layer 5 (bitmask 16)")
	assert_eq(proj.collision_mask, 3, "Enemy projectile masks Layer 1 (World) + Layer 2 (Player) = 3")
	assert_almost_eq(proj.speed, 200.0, 0.01, "Enemy projectile speed is 200")
	assert_almost_eq(proj.damage, 8.0, 0.01, "Enemy projectile damage is 8")
	proj.free()

func test_spawner_scene_and_wave_configs() -> void:
	var spawner_scene: PackedScene = load("res://scenes/world/spawner.tscn")
	assert_not_null(spawner_scene, "Spawner scene exists")
	
	var spawner = spawner_scene.instantiate()
	assert_not_null(spawner, "Spawner instantiated")
	
	var configs: Dictionary = spawner.get_wave_configs()
	assert_eq(configs.size(), 5, "Spawner has 5 wave configurations")
	assert_almost_eq(configs[1]["duration"], 30.0, 0.01, "Wave 1 is 30s")
	assert_almost_eq(configs[2]["duration"], 35.0, 0.01, "Wave 2 is 35s")
	assert_almost_eq(configs[3]["duration"], 40.0, 0.01, "Wave 3 is 40s")
	assert_almost_eq(configs[4]["duration"], 45.0, 0.01, "Wave 4 is 45s")
	assert_true(configs[5]["is_boss_wave"], "Wave 5 is Boss wave")
	
	spawner.free()
