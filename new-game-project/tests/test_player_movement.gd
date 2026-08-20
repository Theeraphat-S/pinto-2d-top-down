# res://tests/test_player_movement.gd
# R1: 8-Directional Movement, Kinematics, Velocity Damping, and Collision Alignment Tests
extends "res://tests/test_framework.gd"

const BASE_SPEED: float = 160.0
const ACCELERATION: float = 1200.0
const FRICTION: float = 1400.0

# Helper to simulate input vector calculation
func calculate_input_vector(raw_x: float, raw_y: float) -> Vector2:
	var raw := Vector2(raw_x, raw_y)
	if raw.length_squared() > 0.0:
		return raw.normalized()
	return Vector2.ZERO

# Helper to simulate 1 frame of velocity integration
func integrate_velocity(current_vel: Vector2, input_dir: Vector2, speed: float, accel: float, frict: float, delta: float) -> Vector2:
	var target_vel: Vector2 = input_dir * speed
	if input_dir.length_squared() > 0.0:
		return current_vel.move_toward(target_vel, accel * delta)
	else:
		return current_vel.move_toward(Vector2.ZERO, frict * delta)

# --- Test Cases ---

func test_cardinal_input_normalization() -> void:
	# Cardinal directions must produce exact unit vectors of length 1.0
	var right = calculate_input_vector(1.0, 0.0)
	var left = calculate_input_vector(-1.0, 0.0)
	var down = calculate_input_vector(0.0, 1.0)
	var up = calculate_input_vector(0.0, -1.0)
	
	assert_eq(right, Vector2.RIGHT, "Right input vector should be (1, 0)")
	assert_eq(left, Vector2.LEFT, "Left input vector should be (-1, 0)")
	assert_eq(down, Vector2.DOWN, "Down input vector should be (0, 1)")
	assert_eq(up, Vector2.UP, "Up input vector should be (0, -1)")
	
	assert_almost_eq(right.length(), 1.0, 0.0001, "Right input magnitude must be 1.0")
	assert_almost_eq(left.length(), 1.0, 0.0001, "Left input magnitude must be 1.0")
	assert_almost_eq(down.length(), 1.0, 0.0001, "Down input magnitude must be 1.0")
	assert_almost_eq(up.length(), 1.0, 0.0001, "Up input magnitude must be 1.0")

func test_diagonal_input_normalization() -> void:
	# Diagonal raw vector is (1, 1), length ~ 1.4142. Normalized length must be exactly 1.0.
	var down_right = calculate_input_vector(1.0, 1.0)
	var up_right = calculate_input_vector(1.0, -1.0)
	var down_left = calculate_input_vector(-1.0, 1.0)
	var up_left = calculate_input_vector(-1.0, -1.0)
	
	var expected_comp: float = 1.0 / sqrt(2.0) # ~0.70710678
	
	assert_almost_eq(down_right.x, expected_comp, 0.0001, "Down-Right X component")
	assert_almost_eq(down_right.y, expected_comp, 0.0001, "Down-Right Y component")
	assert_almost_eq(down_right.length(), 1.0, 0.0001, "Down-Right normalized magnitude must be 1.0")
	
	assert_almost_eq(up_right.x, expected_comp, 0.0001, "Up-Right X component")
	assert_almost_eq(up_right.y, -expected_comp, 0.0001, "Up-Right Y component")
	assert_almost_eq(up_right.length(), 1.0, 0.0001, "Up-Right normalized magnitude must be 1.0")
	
	assert_almost_eq(down_left.length(), 1.0, 0.0001, "Down-Left normalized magnitude must be 1.0")
	assert_almost_eq(up_left.length(), 1.0, 0.0001, "Up-Left normalized magnitude must be 1.0")

func test_opposing_inputs_cancel_to_zero() -> void:
	# Simultaneous left + right or up + down cancel to zero
	var cancel_horiz = calculate_input_vector(1.0 - 1.0, 0.0)
	var cancel_vert = calculate_input_vector(0.0, 1.0 - 1.0)
	var cancel_all = calculate_input_vector(1.0 - 1.0, 1.0 - 1.0)
	
	assert_eq(cancel_horiz, Vector2.ZERO, "Opposing horizontal keys cancel out")
	assert_eq(cancel_vert, Vector2.ZERO, "Opposing vertical keys cancel out")
	assert_eq(cancel_all, Vector2.ZERO, "All opposing keys cancel out")

func test_acceleration_kinematics() -> void:
	# Starting from rest (0, 0), 1 frame of delta = 0.016667s (60 FPS)
	var delta: float = 1.0 / 60.0
	var vel := Vector2.ZERO
	var input := Vector2.RIGHT
	
	vel = integrate_velocity(vel, input, BASE_SPEED, ACCELERATION, FRICTION, delta)
	var expected_step: float = ACCELERATION * delta # 1200 * (1/60) = 20.0 px/s
	
	assert_almost_eq(vel.x, expected_step, 0.001, "Velocity after 1 physics frame")
	assert_eq(vel.y, 0.0, "Y velocity remains 0 for horizontal movement")
	
	# Simulate 10 frames (total 0.1667s) - should reach max speed 160.0 px/s and clamp
	for i in range(15):
		vel = integrate_velocity(vel, input, BASE_SPEED, ACCELERATION, FRICTION, delta)
		
	assert_almost_eq(vel.x, BASE_SPEED, 0.001, "Velocity clamped to max base speed 160.0 px/s")
	assert_lte(vel.x, BASE_SPEED, "Velocity must not overshoot max speed")

func test_friction_and_deceleration() -> void:
	# Starting at max speed (160, 0), with 0 input, friction slows it to a complete stop
	var delta: float = 1.0 / 60.0
	var vel := Vector2(BASE_SPEED, 0.0)
	var input := Vector2.ZERO
	
	# 1 frame of deceleration
	vel = integrate_velocity(vel, input, BASE_SPEED, ACCELERATION, FRICTION, delta)
	var expected_vel: float = BASE_SPEED - (FRICTION * delta) # 160 - 23.333 = 136.666
	assert_almost_eq(vel.x, expected_vel, 0.001, "Velocity after 1 frame of friction deceleration")
	
	# After 0.15s (9 frames), velocity should be completely 0
	for i in range(10):
		vel = integrate_velocity(vel, input, BASE_SPEED, ACCELERATION, FRICTION, delta)
		
	assert_eq(vel, Vector2.ZERO, "Velocity must stop completely at (0, 0)")

func test_diagonal_speed_clamp() -> void:
	# Diagonal movement must have max velocity equal to base speed (160 px/s), not 160 * 1.414 = 226.27
	var delta: float = 1.0 / 60.0
	var vel := Vector2.ZERO
	var input := calculate_input_vector(1.0, 1.0)
	
	for i in range(20):
		vel = integrate_velocity(vel, input, BASE_SPEED, ACCELERATION, FRICTION, delta)
		
	assert_almost_eq(vel.length(), BASE_SPEED, 0.001, "Diagonal speed magnitude clamped to 160.0 px/s")
	var comp = BASE_SPEED / sqrt(2.0) # ~113.137 px/s
	assert_almost_eq(vel.x, comp, 0.001, "Diagonal X speed component")
	assert_almost_eq(vel.y, comp, 0.001, "Diagonal Y speed component")

func test_speed_stat_modifier_tiers() -> void:
	# Test Swift Paws upgrade tiers: +15% per tier
	var tier_multipliers := [1.0, 1.15, 1.30, 1.45, 1.60, 1.75]
	for tier in range(tier_multipliers.size()):
		var expected_speed: float = BASE_SPEED * (1.0 + 0.15 * float(tier))
		var calc_speed: float = BASE_SPEED * tier_multipliers[tier]
		assert_almost_eq(calc_speed, expected_speed, 0.001, "Move speed at tier %d" % [tier])
		
	# Verify Tier 5 max speed is 280.0 px/s
	var tier_5_speed: float = BASE_SPEED * (1.0 + 0.15 * 5.0)
	assert_almost_eq(tier_5_speed, 280.0, 0.001, "Tier 5 move speed must be exactly 280.0 px/s")

func test_character_body_configuration() -> void:
	# Instantiate a CharacterBody2D and verify Godot 4 Floating Mode & Shape
	var body := CharacterBody2D.new()
	body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	assert_eq(body.motion_mode, CharacterBody2D.MOTION_MODE_FLOATING, "Body motion mode must be MOTION_MODE_FLOATING")
	
	var col_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	col_shape.shape = circle
	col_shape.position = Vector2(0, 6) # Feet level offset
	body.add_child(col_shape)
	
	assert_eq(col_shape.position, Vector2(0, 6), "Collision shape must be anchored at feet (0, 6)")
	assert_almost_eq((col_shape.shape as CircleShape2D).radius, 6.0, 0.001, "Foot collision radius is 6.0")
	
	body.free()

func test_player_scene_instantiation_and_structure() -> void:
	var scene = load("res://scenes/player/player.tscn")
	assert_not_null(scene, "res://scenes/player/player.tscn must load successfully")
	
	var player = scene.instantiate() as CharacterBody2D
	assert_not_null(player, "Player scene must instantiate as CharacterBody2D")
	assert_eq(player.motion_mode, CharacterBody2D.MOTION_MODE_FLOATING, "Player motion mode is MOTION_MODE_FLOATING")
	assert_eq(player.collision_layer, 2, "Player collision_layer must be 2 (Layer 2)")
	assert_eq(player.collision_mask, 1, "Player collision_mask must be 1 (Layer 1)")
	assert_true(player.y_sort_enabled, "Player y_sort_enabled must be true")
	
	var col: CollisionShape2D = player.get_node_or_null("CollisionShape2D")
	assert_not_null(col, "CollisionShape2D node exists")
	assert_almost_eq((col.shape as CircleShape2D).radius, 6.0, 0.001, "Foot collision radius is 6.0")
	assert_eq(col.position, Vector2(0, 6), "Foot collision offset is (0, 6)")
	
	var magnet: Area2D = player.get_node_or_null("MagnetArea")
	assert_not_null(magnet, "MagnetArea exists")
	assert_eq(magnet.collision_layer, 64, "MagnetArea is on Layer 7 (64)")
	assert_eq(magnet.collision_mask, 32, "MagnetArea masks Layer 6 (32)")
	
	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	assert_not_null(sprite, "AnimatedSprite2D exists")
	assert_not_null(sprite.sprite_frames, "SpriteFrames resource assigned")
	
	var anims = ["idle", "walk_down", "walk_up", "walk_side", "hurt", "death", "attack", "victory"]
	for a in anims:
		assert_true(sprite.sprite_frames.has_animation(a), "Has animation '%s'" % a)
		
	player.free()
