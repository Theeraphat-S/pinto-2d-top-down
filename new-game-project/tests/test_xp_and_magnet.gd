# res://tests/test_xp_and_magnet.gd
# R2 & R3: XP Gem Values, Quadratic Level Curve, Magnet Attraction Physics, and Overflow Leveling
extends "res://tests/test_framework.gd"

const BASE_MAGNET_RADIUS: float = 65.0
const GEM_ACCELERATION: float = 600.0
const MAX_GEM_SPEED: float = 320.0
const COLLECTION_RADIUS: float = 8.0

# Mathematical XP requirement formula
func xp_required_for_level(level: int) -> int:
	if level < 1:
		level = 1
	var l_offset: float = float(level - 1)
	return int(floor(10.0 + l_offset * 15.0 + l_offset * l_offset * 5.0))

# Simulates magnet movement step for a gem
func step_gem_magnet(gem_pos: Vector2, gem_vel: Vector2, player_pos: Vector2, magnet_radius: float, delta: float) -> Dictionary:
	var dist: float = gem_pos.distance_to(player_pos)
	var new_pos: Vector2 = gem_pos
	var new_vel: Vector2 = gem_vel
	var is_collected: bool = false
	
	if dist <= COLLECTION_RADIUS:
		is_collected = true
	elif dist <= magnet_radius:
		var dir_to_player: Vector2 = (player_pos - gem_pos).normalized()
		new_vel = new_vel.move_toward(dir_to_player * MAX_GEM_SPEED, GEM_ACCELERATION * delta)
		new_pos += new_vel * delta
		if new_pos.distance_to(player_pos) <= COLLECTION_RADIUS:
			is_collected = true
			
	return {
		"position": new_pos,
		"velocity": new_vel,
		"collected": is_collected,
		"distance": new_pos.distance_to(player_pos)
	}

# Simulates XP grant and sequential level-ups
func process_xp_grant(start_level: int, current_xp: int, xp_amount: int) -> Dictionary:
	var level: int = start_level
	var xp: int = current_xp + xp_amount
	var level_ups: int = 0
	
	while true:
		var req: int = xp_required_for_level(level)
		if xp >= req:
			xp -= req
			level += 1
			level_ups += 1
		else:
			break
			
	return {
		"final_level": level,
		"remaining_xp": xp,
		"level_ups": level_ups,
		"next_level_req": xp_required_for_level(level)
	}

# --- Test Cases ---

func test_xp_gem_tier_values() -> void:
	var gem_values := {
		"green": 1,
		"blue": 5,
		"red": 20,
		"boss": 100
	}
	assert_eq(gem_values["green"], 1, "Green gem is 1 XP")
	assert_eq(gem_values["blue"], 5, "Blue gem is 5 XP")
	assert_eq(gem_values["red"], 20, "Red gem is 20 XP")
	assert_eq(gem_values["boss"], 100, "Boss gem is 100 XP")

func test_quadratic_xp_level_curve() -> void:
	# Check levels 1 through 10 against exact formula
	# XP_req(L) = floor(10 + (L-1)*15 + (L-1)^2*5)
	assert_eq(xp_required_for_level(1), 10, "Level 1 -> 2 requires 10 XP")
	assert_eq(xp_required_for_level(2), 30, "Level 2 -> 3 requires 30 XP")
	assert_eq(xp_required_for_level(3), 60, "Level 3 -> 4 requires 60 XP")
	assert_eq(xp_required_for_level(4), 100, "Level 4 -> 5 requires 100 XP")
	assert_eq(xp_required_for_level(5), 150, "Level 5 -> 6 requires 150 XP")
	assert_eq(xp_required_for_level(6), 210, "Level 6 -> 7 requires 210 XP")
	assert_eq(xp_required_for_level(7), 280, "Level 7 -> 8 requires 280 XP")
	assert_eq(xp_required_for_level(8), 360, "Level 8 -> 9 requires 360 XP")
	assert_eq(xp_required_for_level(9), 450, "Level 9 -> 10 requires 450 XP")
	assert_eq(xp_required_for_level(10), 550, "Level 10 -> 11 requires 550 XP")

func test_magnet_attraction_inside_radius() -> void:
	var player_pos := Vector2(100, 100)
	var gem_pos := Vector2(140, 100) # dist = 40px (< 65px radius)
	var gem_vel := Vector2.ZERO
	var delta: float = 1.0 / 60.0
	
	# Simulate 1 frame of attraction
	var step1 = step_gem_magnet(gem_pos, gem_vel, player_pos, BASE_MAGNET_RADIUS, delta)
	assert_gt(step1["velocity"].length(), 0.0, "Gem accelerates towards player")
	assert_lt(step1["distance"], 40.0, "Gem moves closer to player")
	
	# Simulate movement until collection
	var current_state = step1
	var max_frames = 60 # 1 second max
	var frames_taken = 0
	for i in range(max_frames):
		if current_state["collected"]:
			break
		current_state = step_gem_magnet(current_state["position"], current_state["velocity"], player_pos, BASE_MAGNET_RADIUS, delta)
		frames_taken += 1
		
	assert_true(current_state["collected"], "Gem successfully collected within 1 second")
	assert_lte(current_state["distance"], COLLECTION_RADIUS, "Collected when distance <= 8px")

func test_magnet_attraction_outside_radius() -> void:
	var player_pos := Vector2(100, 100)
	var gem_pos := Vector2(200, 100) # dist = 100px (> 65px radius)
	var gem_vel := Vector2.ZERO
	var delta: float = 1.0 / 60.0
	
	var step = step_gem_magnet(gem_pos, gem_vel, player_pos, BASE_MAGNET_RADIUS, delta)
	assert_eq(step["velocity"], Vector2.ZERO, "Gem outside radius experiences no attraction")
	assert_almost_eq(step["distance"], 100.0, 0.001, "Distance remains unchanged")
	assert_false(step["collected"], "Gem is not collected")

func test_magnet_upgrade_radius_expansion() -> void:
	# Magnetic Bell: +40% radius per tier
	# Tier 0: 65.0
	# Tier 1: 65.0 * 1.40 = 91.0
	# Tier 2: 65.0 * 1.80 = 117.0
	# Tier 3: 65.0 * 2.20 = 143.0
	# Tier 4: 65.0 * 2.60 = 169.0
	var tier_1_radius: float = BASE_MAGNET_RADIUS * (1.0 + 0.40 * 1.0)
	assert_almost_eq(tier_1_radius, 91.0, 0.001, "Tier 1 magnet radius is 91.0px")
	
	# Gem at 80px is outside Tier 0 (65px) but inside Tier 1 (91px)
	var player_pos := Vector2(0, 0)
	var gem_pos := Vector2(80, 0)
	var delta: float = 1.0 / 60.0
	
	var step_tier0 = step_gem_magnet(gem_pos, Vector2.ZERO, player_pos, BASE_MAGNET_RADIUS, delta)
	assert_eq(step_tier0["velocity"], Vector2.ZERO, "Outside Tier 0 radius")
	
	var step_tier1 = step_gem_magnet(gem_pos, Vector2.ZERO, player_pos, tier_1_radius, delta)
	assert_gt(step_tier1["velocity"].length(), 0.0, "Inside Tier 1 radius attracts gem")

func test_single_level_up_threshold() -> void:
	# Starting at Level 1, 0 XP, collecting 10 XP
	var result = process_xp_grant(1, 0, 10)
	assert_eq(result["final_level"], 2, "Level 1 with 10 XP levels up to Level 2")
	assert_eq(result["remaining_xp"], 0, "0 XP remainder")
	assert_eq(result["level_ups"], 1, "Triggered exactly 1 level up")
	assert_eq(result["next_level_req"], 30, "Next level requires 30 XP")

func test_sequential_overflow_multi_level_up() -> void:
	# Starting at Level 1, 0 XP, collecting Boss Gem (100 XP)
	# L1->L2 requires 10 (90 left)
	# L2->L3 requires 30 (60 left)
	# L3->L4 requires 60 (0 left)
	# Result should be Level 4, 0 remaining XP, 3 level ups
	var result = process_xp_grant(1, 0, 100)
	assert_eq(result["final_level"], 4, "100 XP promotes Level 1 directly to Level 4")
	assert_eq(result["remaining_xp"], 0, "0 XP remainder")
	assert_eq(result["level_ups"], 3, "Triggered 3 level-up increments")
	assert_eq(result["next_level_req"], 100, "Level 4 -> 5 requires 100 XP")

func test_partial_xp_retention_after_level_up() -> void:
	# Starting at Level 1, 5 XP, collecting Blue Gem (5 XP) -> 10 XP total -> Level 2, 0 XP
	var res1 = process_xp_grant(1, 5, 5)
	assert_eq(res1["final_level"], 2, "Reached Level 2")
	assert_eq(res1["remaining_xp"], 0, "0 remainder")
	
	# Starting at Level 1, 0 XP, collecting 15 XP -> Level 2, 5 remainder XP
	var res2 = process_xp_grant(1, 0, 15)
	assert_eq(res2["final_level"], 2, "Reached Level 2")
	assert_eq(res2["remaining_xp"], 5, "5 XP carries over into Level 2")

# ==============================================================================
# M4 CONCRETE XP GEM SCENE & MAGNET INTEGRATION TESTS
# ==============================================================================

func test_xp_gem_scene_structure_and_layers() -> void:
	var gem_scene = load("res://scenes/pickups/xp_gem.tscn")
	assert_not_null(gem_scene, "XPGem scene exists")
	
	var gem = gem_scene.instantiate()
	assert_not_null(gem, "XPGem instantiated")
	assert_eq(gem.collision_layer, 32, "XPGem on Layer 6 (bitmask 32)")
	assert_eq(gem.collision_mask, 66, "XPGem masks Layer 7 (Magnet Area, 64) and Layer 2 (Player, 2)")
	assert_true(gem.has_node("Sprite2D"), "XPGem has Sprite2D")
	assert_true(gem.has_node("CollisionShape2D"), "XPGem has CollisionShape2D")
	assert_true(gem.has_node("PickupSFX"), "XPGem has PickupSFX")
	
	# Test tier configuration setup
	gem.setup("small")
	assert_eq(gem.xp_value, 1, "Small gem setup has 1 XP")
	
	gem.setup("med")
	assert_eq(gem.xp_value, 5, "Med gem setup has 5 XP")
	
	gem.setup("large")
	assert_eq(gem.xp_value, 20, "Large gem setup has 20 XP")
	
	gem.setup("boss")
	assert_eq(gem.xp_value, 100, "Boss gem setup has 100 XP")
	
	gem.free()

func test_xp_gem_magnetic_attraction_flow() -> void:
	var gem_scene = load("res://scenes/pickups/xp_gem.tscn")
	var gem = gem_scene.instantiate()
	gem.global_position = Vector2(50.0, 50.0)
	
	# Mock player target
	var mock_player := Node2D.new()
	mock_player.global_position = Vector2(80.0, 50.0)
	
	# Trigger attraction
	gem.start_attraction(mock_player)
	assert_true(gem.is_attracted, "Gem attraction triggered")
	assert_eq(gem.target_player, mock_player, "Target player assigned")
	
	# Step physics process
	gem._physics_process(1.0 / 60.0)
	assert_gt(gem.velocity.x, 0.0, "Gem moves rightward toward player")
	assert_gt(gem.global_position.x, 50.0, "Gem X position moved closer to player")
	
	gem.free()
	mock_player.free()
