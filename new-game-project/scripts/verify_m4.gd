extends Node

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - M4 VERIFICATION SUITE
# Headless integration verification for Enemies, Waves, Boss & XP Magnetics.
# ==============================================================================

var passed_count: int = 0
var failed_count: int = 0

func _ready() -> void:
	print("\n============================================================")
	print("   PINTO 2D SURVIVAL ARENA — M4 VERIFICATION SUITE")
	print("============================================================\n")
	
	_run_all_tests()
	
	print("\n============================================================")
	print("   M4 VERIFICATION SUMMARY: %d passed, %d failed." % [passed_count, failed_count])
	print("============================================================\n")
	
	if failed_count > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		passed_count += 1
		print("  [PASS] ", message)
	else:
		failed_count += 1
		printerr("  [FAIL] >>> ", message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		passed_count += 1
		print("  [PASS] %s (got: %s)" % [message, str(actual)])
	else:
		failed_count += 1
		printerr("  [FAIL] %s (expected: %s, got: %s)" % [message, str(expected), str(actual)])

func _assert_almost_eq(actual: float, expected: float, tol: float = 0.01, message: String = "") -> void:
	if absf(actual - expected) <= tol:
		passed_count += 1
		print("  [PASS] %s (got: %f, expected: %f)" % [message, actual, expected])
	else:
		failed_count += 1
		printerr("  [FAIL] %s (expected: %f, got: %f, diff: %f)" % [message, expected, actual, absf(actual - expected)])

func _run_all_tests() -> void:
	test_enemy_base_scene()
	test_enemy_slime_archetype()
	test_enemy_bat_archetype()
	test_enemy_drone_archetype()
	test_enemy_golem_archetype()
	test_boss_giga_null_lifecycle_and_phases()
	test_enemy_projectile_scene()
	test_xp_gem_tiers_and_magnetics()
	test_wave_spawner_lifecycle()

# ==============================================================================
# TEST 1: ENEMY BASE SCENE & COLLISION CONFIGURATION
# ==============================================================================

func test_enemy_base_scene() -> void:
	print("\n>> Testing Enemy Base Scene & Physics Matrix...")
	var scene = load("res://scenes/enemies/enemy_base.tscn")
	_assert(scene != null, "enemy_base.tscn loads successfully")
	
	var enemy = scene.instantiate()
	_assert(enemy != null, "enemy_base.tscn instantiates")
	_assert_eq(enemy.motion_mode, CharacterBody2D.MOTION_MODE_FLOATING, "Enemy motion_mode is FLOATING")
	_assert(enemy.y_sort_enabled, "Enemy y_sort_enabled is true")
	_assert_eq(enemy.collision_layer, 4, "Enemy collision_layer is Layer 3 (bitmask 4)")
	_assert_eq(enemy.collision_mask, 7, "Enemy collision_mask is Layers 1,2,3 (bitmask 7)")
	_assert(enemy.is_in_group("enemies"), "Enemy is in 'enemies' group")
	
	var hitbox = enemy.get_node_or_null("HitboxArea")
	_assert(hitbox != null, "HitboxArea child exists")
	_assert_eq(hitbox.collision_layer, 128, "HitboxArea collision_layer is Layer 8 (bitmask 128)")
	_assert_eq(hitbox.collision_mask, 2, "HitboxArea collision_mask is Layer 2 (Player)")
	
	# Test take_damage and sprite flash
	enemy.take_damage(10.0)
	_assert_almost_eq(enemy.current_health, 15.0, 0.01, "Damage reduces health from 25 to 15")
	_assert(enemy._is_flashing, "Sprite flashes on damage")
	
	# Test knockback application
	enemy.apply_knockback(Vector2.RIGHT, 100.0)
	_assert(enemy.knockback_velocity.x > 0.0, "Knockback velocity applied in given direction")
	
	enemy.free()

# ==============================================================================
# TEST 2: GLITCH SLIME ARCHETYPE
# ==============================================================================

func test_enemy_slime_archetype() -> void:
	print("\n>> Testing Glitch Slime Archetype...")
	var scene = load("res://scenes/enemies/enemy_slime.tscn")
	_assert(scene != null, "enemy_slime.tscn loads successfully")
	
	var slime = scene.instantiate()
	_assert(slime != null, "enemy_slime.tscn instantiates")
	_assert_eq(slime.enemy_type, "slime", "Enemy type is 'slime'")
	_assert_almost_eq(slime.max_health, 25.0, 0.01, "Slime HP is 25.0")
	_assert_almost_eq(slime.move_speed, 85.0, 0.01, "Slime move speed is 85.0")
	_assert_almost_eq(slime.contact_damage, 10.0, 0.01, "Slime contact damage is 10.0")
	_assert_eq(slime.drop_gem_tier, 0, "Slime drops Small XP gem (Tier 0)")
	_assert_eq(slime.drop_gem_count, 1, "Slime drops 1 gem")
	
	slime.free()

# ==============================================================================
# TEST 3: CYBER BAT ARCHETYPE & ZIG-ZAG MOTION
# ==============================================================================

func test_enemy_bat_archetype() -> void:
	print("\n>> Testing Cyber Bat Archetype & Zig-Zag Flanking...")
	var scene = load("res://scenes/enemies/enemy_bat.tscn")
	_assert(scene != null, "enemy_bat.tscn loads successfully")
	
	var bat = scene.instantiate()
	_assert(bat != null, "enemy_bat.tscn instantiates")
	_assert_eq(bat.enemy_type, "bat", "Enemy type is 'bat'")
	_assert_almost_eq(bat.max_health, 15.0, 0.01, "Bat HP is 15.0")
	_assert_almost_eq(bat.move_speed, 150.0, 0.01, "Bat move speed is 150.0")
	_assert_almost_eq(bat.contact_damage, 8.0, 0.01, "Bat contact damage is 8.0")
	_assert_eq(bat.drop_gem_tier, 0, "Bat drops Small XP gem (Tier 0)")
	
	# Test lateral oscillation calculation
	var mock_player := Node2D.new()
	mock_player.global_position = Vector2(200.0, 100.0)
	bat.global_position = Vector2(100.0, 100.0) # Player is directly to the right
	bat.target_player = mock_player
	
	var dir1 = bat._get_movement_direction(0.1)
	_assert(dir1.length_squared() > 0.9, "Movement direction vector is normalized")
	_assert(dir1.x > 0.0, "Bat moves generally rightward towards player")
	
	mock_player.free()
	bat.free()

# ==============================================================================
# TEST 4: CRT DRONE ARCHETYPE & STANDOFF DISTANCE
# ==============================================================================

func test_enemy_drone_archetype() -> void:
	print("\n>> Testing CRT Drone Archetype & Standoff Shooting...")
	var scene = load("res://scenes/enemies/enemy_drone.tscn")
	_assert(scene != null, "enemy_drone.tscn loads successfully")
	
	var drone = scene.instantiate()
	_assert(drone != null, "enemy_drone.tscn instantiates")
	_assert_eq(drone.enemy_type, "drone", "Enemy type is 'drone'")
	_assert_almost_eq(drone.max_health, 40.0, 0.01, "Drone HP is 40.0")
	_assert_almost_eq(drone.move_speed, 70.0, 0.01, "Drone move speed is 70.0")
	_assert_almost_eq(drone.contact_damage, 5.0, 0.01, "Drone contact damage is 5.0")
	_assert_eq(drone.drop_gem_tier, 1, "Drone drops Medium XP gem (Tier 1)")
	_assert_almost_eq(drone.standoff_distance, 180.0, 0.01, "Drone standoff distance is 180px")
	_assert_almost_eq(drone.shoot_interval, 2.0, 0.01, "Drone shoot interval is 2.0s")
	
	# Test standoff retreat behavior when too close (e.g. 80px < 155px)
	var mock_player := Node2D.new()
	mock_player.global_position = Vector2(180.0, 100.0)
	drone.global_position = Vector2(100.0, 100.0) # dist = 80px
	drone.target_player = mock_player
	
	var retreat_dir = drone._get_movement_direction(0.1)
	_assert(retreat_dir.x < 0.0, "Drone retreats away from player when closer than standoff distance")
	
	mock_player.free()
	drone.free()

# ==============================================================================
# TEST 5: MEGABYTE GOLEM ARCHETYPE & KNOCKBACK RESIST
# ==============================================================================

func test_enemy_golem_archetype() -> void:
	print("\n>> Testing Megabyte Golem Archetype & Knockback Resistance...")
	var scene = load("res://scenes/enemies/enemy_golem.tscn")
	_assert(scene != null, "enemy_golem.tscn loads successfully")
	
	var golem = scene.instantiate()
	_assert(golem != null, "enemy_golem.tscn instantiates")
	_assert_eq(golem.enemy_type, "golem", "Enemy type is 'golem'")
	_assert_almost_eq(golem.max_health, 120.0, 0.01, "Golem HP is 120.0")
	_assert_almost_eq(golem.move_speed, 50.0, 0.01, "Golem move speed is 50.0")
	_assert_almost_eq(golem.contact_damage, 25.0, 0.01, "Golem contact damage is 25.0")
	_assert_almost_eq(golem.knockback_resistance, 0.85, 0.01, "Golem knockback resistance is 0.85 (85%)")
	_assert_eq(golem.drop_gem_tier, 2, "Golem drops Large XP gem (Tier 2)")
	
	# Test knockback reduction: 100 force * (1 - 0.85) = 15 effective force
	golem.apply_knockback(Vector2.RIGHT, 100.0)
	_assert_almost_eq(golem.knockback_velocity.x, 15.0, 0.1, "Knockback velocity dampened to 15.0 px/s")
	
	golem.free()

# ==============================================================================
# TEST 6: BOSS GIGA-NULL LIFECYCLE & 3-PHASE TRANSITIONS
# ==============================================================================

func test_boss_giga_null_lifecycle_and_phases() -> void:
	print("\n>> Testing Boss GIGA-NULL 3-Phase State Machine...")
	var scene = load("res://scenes/enemies/boss_giga_null.tscn")
	_assert(scene != null, "boss_giga_null.tscn loads successfully")
	
	var boss = scene.instantiate()
	_assert(boss != null, "boss_giga_null.tscn instantiates")
	_assert_almost_eq(boss.max_health, 600.0, 0.01, "Boss max HP is 600.0")
	_assert_almost_eq(boss.contact_damage, 30.0, 0.01, "Boss contact damage is 30.0")
	_assert_almost_eq(boss.knockback_resistance, 1.0, 0.01, "Boss is immune to knockback (1.0)")
	_assert_eq(boss.drop_gem_count, 5, "Boss drops 5 Large XP gems (100 XP total)")
	_assert_eq(boss.current_phase, 1, "Boss initializes in Phase 1")
	_assert_almost_eq(boss.move_speed, 60.0, 0.01, "Boss Phase 1 speed is 60.0")
	
	# Damage into Phase 2: HP > 33% and <= 66% (390 HP = 65%)
	boss.take_damage(210.0)
	_assert_almost_eq(boss.current_health, 390.0, 0.01, "Boss HP reduced to 390.0")
	_assert_eq(boss.current_phase, 2, "Boss transitioned to Phase 2 at 65% HP")
	boss._process_phase_2(0.1)
	_assert_almost_eq(boss.move_speed, 90.0, 0.01, "Boss Phase 2 enraged speed boost to 90.0")
	
	# Damage into Phase 3: HP <= 33% (190 HP = 31.6%)
	boss.take_damage(200.0)
	_assert_almost_eq(boss.current_health, 190.0, 0.01, "Boss HP reduced to 190.0")
	_assert_eq(boss.current_phase, 3, "Boss transitioned to Phase 3 desperation mode at 31.6% HP")
	
	boss.free()

# ==============================================================================
# TEST 7: ENEMY PROJECTILE
# ==============================================================================

func test_enemy_projectile_scene() -> void:
	print("\n>> Testing Enemy Projectile Physics & Layer Matrix...")
	var scene = load("res://scenes/weapons/enemy_projectile.tscn")
	_assert(scene != null, "enemy_projectile.tscn loads successfully")
	
	var proj = scene.instantiate()
	_assert(proj != null, "enemy_projectile.tscn instantiates")
	_assert_eq(proj.collision_layer, 16, "Enemy projectile on Layer 5 (bitmask 16)")
	_assert_eq(proj.collision_mask, 3, "Enemy projectile masks Layer 1 (World) + Layer 2 (Player) = 3")
	_assert_almost_eq(proj.speed, 200.0, 0.01, "Enemy projectile speed is 200.0")
	_assert_almost_eq(proj.damage, 8.0, 0.01, "Enemy projectile damage is 8.0")
	
	proj.free()

# ==============================================================================
# TEST 8: XP GEM SYSTEM & MAGNETIC ATTRACTION
# ==============================================================================

func test_xp_gem_tiers_and_magnetics() -> void:
	print("\n>> Testing XP Gem System & Magnetic Attraction Physics...")
	var scene = load("res://scenes/pickups/xp_gem.tscn")
	_assert(scene != null, "xp_gem.tscn loads successfully")
	
	var gem = scene.instantiate()
	_assert(gem != null, "xp_gem.tscn instantiates")
	_assert_eq(gem.collision_layer, 32, "XP Gem collision_layer is Layer 6 (bitmask 32)")
	_assert_eq(gem.collision_mask, 66, "XP Gem collision_mask is Layer 7 (Magnet, 64) + Layer 2 (Player, 2)")
	
	# Verify Tiers
	gem.setup(0) # Small
	_assert_eq(gem.xp_value, 1, "Small Gem is 1 XP")
	
	gem.setup(1) # Medium
	_assert_eq(gem.xp_value, 5, "Medium Gem is 5 XP")
	
	gem.setup(2) # Large
	_assert_eq(gem.xp_value, 20, "Large Gem is 20 XP")
	
	gem.setup(3) # Boss
	_assert_eq(gem.xp_value, 100, "Boss Gem is 100 XP")
	
	# Test Magnetic Pull
	var mock_player := Node2D.new()
	mock_player.global_position = Vector2(100.0, 100.0)
	gem.global_position = Vector2(70.0, 100.0)
	gem.start_attraction(mock_player)
	_assert(gem.is_attracted, "Gem attraction triggered")
	
	gem._physics_process(1.0 / 60.0)
	_assert(gem.velocity.x > 0.0, "Gem accelerates rightward towards player")
	
	mock_player.free()
	gem.free()

# ==============================================================================
# TEST 9: WAVE SPAWNER LIFECYCLE & 5 WAVES
# ==============================================================================

func test_wave_spawner_lifecycle() -> void:
	print("\n>> Testing 5-Wave Escalating Spawner Lifecycle...")
	var scene = load("res://scenes/world/spawner.tscn")
	_assert(scene != null, "spawner.tscn loads successfully")
	
	var spawner = scene.instantiate()
	_assert(spawner != null, "spawner.tscn instantiates")
	
	var configs: Dictionary = spawner.get_wave_configs()
	_assert_eq(configs.size(), 5, "Spawner contains 5 wave configs")
	_assert_almost_eq(configs[1]["duration"], 30.0, 0.01, "Wave 1 duration is 30s")
	_assert_almost_eq(configs[2]["duration"], 35.0, 0.01, "Wave 2 duration is 35s")
	_assert_almost_eq(configs[3]["duration"], 40.0, 0.01, "Wave 3 duration is 40s")
	_assert_almost_eq(configs[4]["duration"], 45.0, 0.01, "Wave 4 duration is 45s")
	_assert(configs[5]["is_boss_wave"], "Wave 5 is flagged as boss wave")
	
	spawner.free()
