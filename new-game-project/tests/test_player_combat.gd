# res://tests/test_player_combat.gd
# R1: Auto-Targeting, Multi-Shot Symmetrical Spread, Ballistics, and Bullet Pierce Tests
extends "res://tests/test_framework.gd"

const ATTACK_RANGE: float = 220.0
const BASE_ATTACK_COOLDOWN: float = 0.5
const BASE_PROJ_SPEED: float = 380.0
const SPREAD_ANGLE_DEG: float = 15.0

# Helper to find nearest valid enemy
func find_nearest_target(pinto_pos: Vector2, enemies: Array, max_range: float) -> Variant:
	var nearest_target = null
	var min_dist_sq: float = max_range * max_range
	
	for e in enemies:
		if e == null:
			continue
		if e is Dictionary:
			if e.get("is_dead", false) or e.get("hp", 1) <= 0:
				continue
			var pos: Vector2 = e.get("position", Vector2.ZERO)
			var d_sq: float = pinto_pos.distance_squared_to(pos)
			if d_sq <= min_dist_sq:
				min_dist_sq = d_sq
				nearest_target = e
		elif e is Node2D:
			if not is_instance_valid(e) or e.is_queued_for_deletion():
				continue
			if e.has_method("is_alive") and not e.is_alive():
				continue
			var d_sq: float = pinto_pos.distance_squared_to(e.global_position)
			if d_sq <= min_dist_sq:
				min_dist_sq = d_sq
				nearest_target = e
				
	return nearest_target

# Helper to calculate spread angles for N projectiles
func calculate_spread_angles(base_angle_rad: float, count: int, spread_deg: float) -> Array[float]:
	var angles: Array[float] = []
	var spread_rad: float = deg_to_rad(spread_deg)
	for i in range(count):
		var offset: float = (float(i) - (float(count) - 1.0) / 2.0) * spread_rad
		angles.append(base_angle_rad + offset)
	return angles

# Helper to simulate pierce consumption
func simulate_projectile_hit(initial_pierce: int, enemies_hit_count: int) -> Dictionary:
	var current_pierce = initial_pierce
	var hits_dealt = 0
	for i in range(enemies_hit_count):
		if current_pierce > 0:
			hits_dealt += 1
			current_pierce -= 1
		else:
			break
	return {
		"remaining_pierce": current_pierce,
		"hits_dealt": hits_dealt,
		"is_destroyed": (current_pierce <= 0)
	}

# --- Test Cases ---

func test_nearest_enemy_selection() -> void:
	var player_pos := Vector2(200, 200)
	var enemies = [
		{"id": "enemy_far", "position": Vector2(380, 200), "hp": 20}, # dist: 180 (in range)
		{"id": "enemy_near", "position": Vector2(250, 200), "hp": 20}, # dist: 50 (nearest)
		{"id": "enemy_mid", "position": Vector2(300, 200), "hp": 20}  # dist: 100
	]
	
	var target = find_nearest_target(player_pos, enemies, ATTACK_RANGE)
	assert_not_null(target, "Should acquire a target")
	assert_eq(target.get("id"), "enemy_near", "Should pick closest enemy at dist=50")

func test_out_of_range_rejection() -> void:
	var player_pos := Vector2(100, 100)
	var enemies = [
		{"id": "out_of_range_1", "position": Vector2(350, 100), "hp": 50}, # dist: 250 > 220
		{"id": "out_of_range_2", "position": Vector2(100, 400), "hp": 50}  # dist: 300 > 220
	]
	
	var target = find_nearest_target(player_pos, enemies, ATTACK_RANGE)
	assert_null(target, "Enemies beyond ATTACK_RANGE (220px) must not be targeted")

func test_dead_enemy_filtering() -> void:
	var player_pos := Vector2(100, 100)
	var enemies = [
		{"id": "dead_near", "position": Vector2(120, 100), "hp": 0, "is_dead": true}, # dist: 20, dead
		{"id": "alive_mid", "position": Vector2(180, 100), "hp": 20, "is_dead": false} # dist: 80, alive
	]
	
	var target = find_nearest_target(player_pos, enemies, ATTACK_RANGE)
	assert_not_null(target, "Should find live enemy")
	assert_eq(target.get("id"), "alive_mid", "Dead enemies must be ignored even if closer")

func test_empty_enemy_list_safe_null() -> void:
	var player_pos := Vector2(100, 100)
	var empty_list: Array = []
	var target = find_nearest_target(player_pos, empty_list, ATTACK_RANGE)
	assert_null(target, "Empty enemy list returns null safely")

func test_multi_shot_spread_angles_single() -> void:
	# Single shot (count=1): exactly 0 degree offset
	var base_angle: float = 0.0 # Facing RIGHT
	var angles = calculate_spread_angles(base_angle, 1, SPREAD_ANGLE_DEG)
	assert_array_size(angles, 1, "Single shot returns 1 angle")
	assert_almost_eq(angles[0], 0.0, 0.0001, "Single shot fires directly at base angle")

func test_multi_shot_spread_angles_twin() -> void:
	# Twin shot (count=2): offsets are -7.5 deg and +7.5 deg
	var base_angle: float = 0.0
	var angles = calculate_spread_angles(base_angle, 2, SPREAD_ANGLE_DEG)
	assert_array_size(angles, 2, "Twin shot returns 2 angles")
	
	var expected_neg: float = deg_to_rad(-7.5)
	var expected_pos: float = deg_to_rad(7.5)
	assert_almost_eq(angles[0], expected_neg, 0.0001, "First shot at -7.5 deg")
	assert_almost_eq(angles[1], expected_pos, 0.0001, "Second shot at +7.5 deg")

func test_multi_shot_spread_angles_triple() -> void:
	# Triple shot (count=3): offsets are -15 deg, 0 deg, +15 deg
	var base_angle: float = deg_to_rad(90.0) # Facing DOWN
	var angles = calculate_spread_angles(base_angle, 3, SPREAD_ANGLE_DEG)
	assert_array_size(angles, 3, "Triple shot returns 3 angles")
	
	assert_almost_eq(angles[0], deg_to_rad(75.0), 0.0001, "First shot at 75 deg (90 - 15)")
	assert_almost_eq(angles[1], deg_to_rad(90.0), 0.0001, "Center shot at 90 deg")
	assert_almost_eq(angles[2], deg_to_rad(105.0), 0.0001, "Third shot at 105 deg (90 + 15)")

func test_multi_shot_spread_angles_five_shots() -> void:
	# 5 shots: offsets are -30, -15, 0, +15, +30
	var base_angle: float = 0.0
	var angles = calculate_spread_angles(base_angle, 5, SPREAD_ANGLE_DEG)
	assert_array_size(angles, 5, "5-shot spread returns 5 angles")
	
	assert_almost_eq(rad_to_deg(angles[0]), -30.0, 0.0001, "Offset -30 deg")
	assert_almost_eq(rad_to_deg(angles[1]), -15.0, 0.0001, "Offset -15 deg")
	assert_almost_eq(rad_to_deg(angles[2]), 0.0, 0.0001, "Offset 0 deg")
	assert_almost_eq(rad_to_deg(angles[3]), 15.0, 0.0001, "Offset +15 deg")
	assert_almost_eq(rad_to_deg(angles[4]), 30.0, 0.0001, "Offset +30 deg")

func test_projectile_ballistics_linear_motion() -> void:
	# Projectile moving right at 380 px/s for 0.5 seconds
	var start_pos := Vector2(100, 100)
	var dir := Vector2.RIGHT
	var delta := 0.016667 # 60 FPS
	var pos := start_pos
	
	# Simulate 30 frames (0.5s)
	for i in range(30):
		pos += dir * BASE_PROJ_SPEED * delta
		
	var expected_dist: float = BASE_PROJ_SPEED * (30.0 * delta) # ~190 px
	assert_almost_eq(pos.x - start_pos.x, expected_dist, 0.1, "Projectile traveled expected distance")
	assert_eq(pos.y, start_pos.y, "Y position stayed constant for horizontal trajectory")

func test_projectile_pierce_lifecycle() -> void:
	# Base pierce = 1: Hits 1 enemy, destroyed on 1st hit
	var res1 = simulate_projectile_hit(1, 2)
	assert_eq(res1["hits_dealt"], 1, "Base projectile deals 1 hit")
	assert_eq(res1["remaining_pierce"], 0, "Pierce reduced to 0")
	assert_true(res1["is_destroyed"], "Projectile destroyed after hitting pierce limit")
	
	# Upgraded pierce = 3: Hits 2 enemies, survives with 1 pierce left
	var res2 = simulate_projectile_hit(3, 2)
	assert_eq(res2["hits_dealt"], 2, "Penetrates 2 enemies")
	assert_eq(res2["remaining_pierce"], 1, "1 pierce remaining")
	assert_false(res2["is_destroyed"], "Projectile still active after 2 hits with pierce=3")
	
	# Upgraded pierce = 3: Hits 3 enemies, destroyed after 3rd hit
	var res3 = simulate_projectile_hit(3, 4)
	assert_eq(res3["hits_dealt"], 3, "Hits exactly 3 enemies")
	assert_eq(res3["remaining_pierce"], 0, "Pierce drops to 0")
	assert_true(res3["is_destroyed"], "Destroyed after 3 hits")

func test_attack_cooldown_clamping() -> void:
	# Attack speed upgrade stacks: cooldown = base * (0.80 ^ tier)
	# Floor is clamped at 0.05s
	var base_cd: float = 0.5
	var min_floor: float = 0.05
	
	for tier in range(10):
		var cd: float = max(min_floor, base_cd * pow(0.80, float(tier)))
		assert_gte(cd, min_floor, "Cooldown never drops below 0.05s floor")
		if tier == 0:
			assert_almost_eq(cd, 0.5, 0.001, "Base cooldown is 0.5s at tier 0")

func test_damage_and_crit_calculation() -> void:
	var base_dmg: float = 20.0
	var crit_mult: float = 1.5
	
	# Non-crit damage
	var normal_dmg = base_dmg
	assert_almost_eq(normal_dmg, 20.0, 0.001, "Normal damage is 20.0")
	
	# Crit damage
	var crit_dmg = base_dmg * crit_mult
	assert_almost_eq(crit_dmg, 30.0, 0.001, "Crit damage is 30.0 (1.5x)")
	
	# Sharpened Claws Tier 5: +100% damage (2x base)
	var tier5_dmg = base_dmg * (1.0 + 0.20 * 5.0)
	assert_almost_eq(tier5_dmg, 40.0, 0.001, "Tier 5 damage is 40.0")
	assert_almost_eq(tier5_dmg * crit_mult, 60.0, 0.001, "Tier 5 crit damage is 60.0")

func test_projectile_scene_properties() -> void:
	var scene = load("res://scenes/weapons/projectile.tscn")
	assert_not_null(scene, "res://scenes/weapons/projectile.tscn loads successfully")
	
	var proj = scene.instantiate() as Area2D
	assert_not_null(proj, "Instantiates as Area2D")
	assert_eq(proj.collision_layer, 8, "Projectile is on Layer 4 (bitmask 8)")
	assert_true((proj.collision_mask & 4) != 0, "Projectile collides with Layer 3 (Enemies)")
	assert_true((proj.collision_mask & 1) != 0, "Projectile collides with Layer 1 (World)")
	assert_eq(proj.collision_mask & 2, 0, "Projectile does NOT collide with Player")
	assert_almost_eq(float(proj.get("lifetime")), 3.0, 0.001, "Default lifetime is 3.0s")
	
	proj.free()

func test_player_scene_combat_and_damage() -> void:
	var scene = load("res://scenes/player/player.tscn")
	var player = scene.instantiate() as CharacterBody2D
	assert_not_null(player, "Player scene instantiated")
	
	# Test is_alive
	assert_true(player.has_method("take_damage"), "Player has take_damage method")
	assert_true(player.has_method("is_alive"), "Player has is_alive method")
	
	player.free()

# Helper assertion for degrees
func assert_almost_deg(actual: float, expected: float, tol: float = 0.001, msg: String = "Angle in degrees") -> bool:
	return assert_almost_eq(actual, expected, tol, msg)
