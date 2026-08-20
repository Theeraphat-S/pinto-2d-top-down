extends Node

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - M2 VERIFICATION SUITE
# Headless integration verification for Player Character and Combat System.
# ==============================================================================

const PlayerScript = preload("res://scenes/player/player.gd")
const ProjectileScript = preload("res://scenes/weapons/projectile.gd")

var passed_count: int = 0
var failed_count: int = 0

func _ready() -> void:
	print("\n============================================================")
	print("   PINTO 2D SURVIVAL ARENA — M2 VERIFICATION SUITE")
	print("============================================================\n")
	
	_run_all_tests()
	
	print("\n============================================================")
	print("   M2 VERIFICATION SUMMARY: %d passed, %d failed." % [passed_count, failed_count])
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
		printerr("  [FAIL] ", message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		passed_count += 1
		print("  [PASS] %s (got: %s)" % [message, str(actual)])
	else:
		failed_count += 1
		printerr("  [FAIL] %s (expected: %s, got: %s)" % [message, str(expected), str(actual)])

func _assert_almost_eq(actual: float, expected: float, tol: float = 0.001, message: String = "") -> void:
	if absf(actual - expected) <= tol:
		passed_count += 1
		print("  [PASS] %s (got: %f, expected: %f)" % [message, actual, expected])
	else:
		failed_count += 1
		printerr("  [FAIL] %s (expected: %f, got: %f, diff: %f)" % [message, expected, actual, absf(actual - expected)])

func _run_all_tests() -> void:
	test_player_scene_structure()
	test_player_sprite_frames()
	test_player_kinematics_and_movement()
	test_projectile_scene_structure()
	test_projectile_ballistics_and_pierce()
	test_auto_attack_targeting_and_spread()
	test_magnet_area_and_radius_sync()
	test_damage_and_death_lifecycle()

# ==============================================================================
# TEST 1: PLAYER SCENE STRUCTURE & PROPERTIES
# ==============================================================================

func test_player_scene_structure() -> void:
	print("\n>> Testing Player Scene Structure & Node Hierarchy...")
	var player_scene = load("res://scenes/player/player.tscn")
	_assert(player_scene != null, "player.tscn loads successfully")
	
	var player = player_scene.instantiate() as CharacterBody2D
	_assert(player != null, "player.tscn instantiates as CharacterBody2D")
	_assert_eq(player.motion_mode, CharacterBody2D.MOTION_MODE_FLOATING, "Player motion_mode is MOTION_MODE_FLOATING")
	_assert_eq(player.collision_layer, 2, "Player collision_layer is Layer 2 (bitmask 2)")
	_assert_eq(player.collision_mask, 1, "Player collision_mask is Layer 1 (bitmask 1)")
	_assert(player.y_sort_enabled, "Player y_sort_enabled is true")
	
	# Verify collision shape
	var col_shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D")
	_assert(col_shape != null, "CollisionShape2D child exists")
	_assert(col_shape.shape is CircleShape2D, "Collision shape is CircleShape2D")
	_assert_almost_eq((col_shape.shape as CircleShape2D).radius, 6.0, 0.01, "Foot collision radius is 6.0")
	_assert_eq(col_shape.position, Vector2(0, 6), "Foot collision offset is (0, 6)")
	
	# Verify magnet area
	var magnet_area: Area2D = player.get_node_or_null("MagnetArea")
	_assert(magnet_area != null, "MagnetArea child exists")
	_assert_eq(magnet_area.collision_layer, 64, "MagnetArea collision_layer is Layer 7 (bitmask 64)")
	_assert_eq(magnet_area.collision_mask, 32, "MagnetArea collision_mask is Layer 6 (bitmask 32)")
	
	player.free()

# ==============================================================================
# TEST 2: SPRITE FRAMES RESOURCE & ANIMATIONS
# ==============================================================================

func test_player_sprite_frames() -> void:
	print("\n>> Testing SpriteFrames Resource & Animations...")
	var frames = load("res://scenes/player/pinto_frames.tres") as SpriteFrames
	_assert(frames != null, "pinto_frames.tres loads successfully")
	
	var required_anims = ["idle", "walk_down", "walk_up", "walk_side", "hurt", "death", "attack", "victory"]
	for anim in required_anims:
		_assert(frames.has_animation(anim), "SpriteFrames has animation: " + anim)
		_assert(frames.get_frame_count(anim) > 0, "Animation '%s' has %d frames" % [anim, frames.get_frame_count(anim)])
		
	_assert_eq(frames.get_frame_count("idle"), 4, "Idle has 4 frames")
	_assert_eq(frames.get_frame_count("walk_down"), 4, "Walk Down has 4 frames")
	_assert_eq(frames.get_frame_count("walk_up"), 4, "Walk Up has 4 frames")
	_assert_eq(frames.get_frame_count("walk_side"), 4, "Walk Side has 4 frames")
	_assert_eq(frames.get_frame_count("hurt"), 2, "Hurt has 2 frames")
	_assert_eq(frames.get_frame_count("death"), 6, "Death has 6 frames")
	_assert_eq(frames.get_frame_count("attack"), 2, "Attack has 2 frames")
	_assert_eq(frames.get_frame_count("victory"), 6, "Victory has 6 frames")

# ==============================================================================
# TEST 3: PLAYER KINEMATICS & MOVEMENT
# ==============================================================================

func test_player_kinematics_and_movement() -> void:
	print("\n>> Testing Kinematics & Velocity Integration...")
	var delta: float = 1.0 / 60.0
	var vel := Vector2.ZERO
	var input: Vector2 = PlayerScript.calculate_input_vector(1.0, 0.0)
	
	_assert_eq(input, Vector2.RIGHT, "Right input vector normalized")
	
	# 1 frame acceleration
	vel = PlayerScript.integrate_velocity(vel, input, 160.0, 1200.0, 1400.0, delta)
	_assert_almost_eq(vel.x, 20.0, 0.01, "Velocity after 1 frame (1200 * 1/60 = 20.0)")
	
	# Full acceleration to max speed
	for i in range(15):
		vel = PlayerScript.integrate_velocity(vel, input, 160.0, 1200.0, 1400.0, delta)
	_assert_almost_eq(vel.x, 160.0, 0.01, "Velocity clamped to max move speed 160.0")
	
	# Friction deceleration to stop
	for i in range(10):
		vel = PlayerScript.integrate_velocity(vel, Vector2.ZERO, 160.0, 1200.0, 1400.0, delta)
	_assert_eq(vel, Vector2.ZERO, "Velocity decelerates to complete stop (0, 0)")

# ==============================================================================
# TEST 4: PROJECTILE SCENE STRUCTURE & PROPERTIES
# ==============================================================================

func test_projectile_scene_structure() -> void:
	print("\n>> Testing Projectile Scene Structure & Properties...")
	var proj_scene = load("res://scenes/weapons/projectile.tscn")
	_assert(proj_scene != null, "projectile.tscn loads successfully")
	
	var proj = proj_scene.instantiate() as Area2D
	_assert(proj != null, "projectile.tscn instantiates as Area2D")
	
	# Layer 4 (8), Mask Layer 1 + Layer 3 (1 + 4 = 5)
	_assert_eq(proj.collision_layer, 8, "Projectile collision_layer is Layer 4 (bitmask 8)")
	_assert((proj.collision_mask & 4) != 0, "Projectile collision_mask includes Layer 3 (Enemies)")
	_assert((proj.collision_mask & 1) != 0, "Projectile collision_mask includes Layer 1 (World)")
	_assert_eq(proj.collision_mask & 2, 0, "Projectile does NOT collide with Layer 2 (Player)")
	
	_assert_almost_eq(proj.get("lifetime"), 3.0, 0.01, "Projectile lifetime default is 3.0s")
	
	var sprite = proj.get_node_or_null("Sprite2D")
	_assert(sprite != null, "Projectile Sprite2D child exists")
	_assert(sprite.texture != null, "Projectile Sprite2D has texture")
	
	proj.free()

# ==============================================================================
# TEST 5: PROJECTILE BALLISTICS, PIERCE & CRIT
# ==============================================================================

# Dummy Enemy class for combat test verification
class MockEnemy extends CharacterBody2D:
	var current_health: float = 50.0
	var max_health: float = 50.0
	var is_dead: bool = false
	var hits_received: int = 0
	var crits_received: int = 0
	var total_damage_taken: float = 0.0
	
	func is_alive() -> bool:
		return not is_dead and current_health > 0.0
		
	func take_damage(amount: float, is_crit: bool = false) -> void:
		hits_received += 1
		if is_crit:
			crits_received += 1
		total_damage_taken += amount
		current_health -= amount
		if current_health <= 0.0:
			is_dead = true

func test_projectile_ballistics_and_pierce() -> void:
	print("\n>> Testing Projectile Ballistics, Pierce & Damage Dealing...")
	var proj_scene = load("res://scenes/weapons/projectile.tscn")
	
	var proj = proj_scene.instantiate() as Area2D
	add_child(proj)
	proj.init(Vector2(100, 100), Vector2.RIGHT, 25.0, 400.0, 2, 0.0, 1.5)
	
	_assert_eq(proj.get("direction"), Vector2.RIGHT, "Projectile direction initialized to RIGHT")
	_assert_almost_eq(proj.get("damage"), 25.0, 0.01, "Projectile damage is 25.0")
	_assert_almost_eq(proj.get("speed"), 400.0, 0.01, "Projectile speed is 400.0")
	_assert_eq(proj.get("pierce"), 2, "Projectile pierce initialized to 2")
	
	# Simulate 1 frame of physics motion
	var delta: float = 1.0 / 60.0
	proj._physics_process(delta)
	_assert_almost_eq(proj.global_position.x, 100.0 + (400.0 * delta), 0.1, "Projectile moved linearly along X axis")
	
	# Enemy 1 Hit
	var enemy1 := MockEnemy.new()
	add_child(enemy1)
	enemy1.global_position = proj.global_position
	
	proj._handle_target_hit(enemy1)
	_assert_eq(enemy1.hits_received, 1, "Enemy 1 received 1 hit")
	_assert_almost_eq(enemy1.total_damage_taken, 25.0, 0.01, "Enemy 1 took 25.0 damage")
	_assert_eq(proj.get("pierce"), 1, "Pierce decremented to 1")
	_assert(not proj.is_queued_for_deletion(), "Projectile still alive after 1 hit (pierce = 2)")
	
	# Repeated hit on same enemy should be ignored
	proj._handle_target_hit(enemy1)
	_assert_eq(enemy1.hits_received, 1, "Enemy 1 not damaged twice by same projectile")
	_assert_eq(proj.get("pierce"), 1, "Pierce not consumed on duplicate hit")
	
	# Enemy 2 Hit (pierce limit reached)
	var enemy2 := MockEnemy.new()
	add_child(enemy2)
	enemy2.global_position = proj.global_position
	
	proj._handle_target_hit(enemy2)
	_assert_eq(enemy2.hits_received, 1, "Enemy 2 received 1 hit")
	_assert_eq(proj.get("pierce"), 0, "Pierce reduced to 0")
	_assert(proj.is_queued_for_deletion(), "Projectile queued for deletion after consuming all pierce")
	
	enemy1.free()
	enemy2.free()
	proj.free()

# ==============================================================================
# TEST 6: AUTO-ATTACK TARGETING & SPREAD
# ==============================================================================

func test_auto_attack_targeting_and_spread() -> void:
	print("\n>> Testing Auto-Attack Targeting & Symmetrical Multi-Shot Spread...")
	var player_pos := Vector2(200, 200)
	
	# Test Spread Angles
	var single_angles: Array[float] = PlayerScript.calculate_spread_angles(0.0, 1, 15.0)
	_assert_eq(single_angles.size(), 1, "1 projectile produces 1 angle")
	_assert_almost_eq(single_angles[0], 0.0, 0.001, "Single angle is base angle 0.0")
	
	var triple_angles: Array[float] = PlayerScript.calculate_spread_angles(0.0, 3, 15.0)
	_assert_eq(triple_angles.size(), 3, "3 projectiles produce 3 angles")
	_assert_almost_eq(rad_to_deg(triple_angles[0]), -15.0, 0.001, "Left angle is -15 deg")
	_assert_almost_eq(rad_to_deg(triple_angles[1]), 0.0, 0.001, "Center angle is 0 deg")
	_assert_almost_eq(rad_to_deg(triple_angles[2]), 15.0, 0.001, "Right angle is +15 deg")
	
	# Test Nearest Enemy Selection
	var enemies = [
		{"id": "e_far", "position": Vector2(400, 200), "hp": 20}, # dist: 200 (in range)
		{"id": "e_nearest", "position": Vector2(240, 200), "hp": 20}, # dist: 40 (nearest)
		{"id": "e_out", "position": Vector2(500, 200), "hp": 20}, # dist: 300 (out of range)
		{"id": "e_dead", "position": Vector2(210, 200), "hp": 0, "is_dead": true} # dist: 10 (dead)
	]
	
	var nearest: Variant = PlayerScript.find_nearest_target(player_pos, enemies, 220.0)
	_assert(nearest != null, "Target acquired")
	_assert_eq(nearest.get("id"), "e_nearest", "Correctly selected alive nearest enemy within range")

# ==============================================================================
# TEST 7: MAGNET AREA & RADIUS SYNC
# ==============================================================================

func test_magnet_area_and_radius_sync() -> void:
	print("\n>> Testing Magnet Area & Radius Synchronization...")
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate() as CharacterBody2D
	add_child(player)
	
	GameState.magnet_radius = 90.0
	player._update_magnet_radius()
	var magnet_circle := player.magnet_shape.shape as CircleShape2D
	_assert_almost_eq(magnet_circle.radius, 90.0, 0.01, "Magnet radius matches GameState (90.0)")
	
	# Upgrade magnet radius to 126.0 (+40%)
	GameState.magnet_radius = 126.0
	player._update_magnet_radius()
	_assert_almost_eq(magnet_circle.radius, 126.0, 0.01, "Magnet radius dynamically updated to 126.0")
	
	# Reset
	GameState.magnet_radius = 90.0
	player.free()

# ==============================================================================
# TEST 8: DAMAGE, FLASH & DEATH LIFECYCLE
# ==============================================================================

func test_damage_and_death_lifecycle() -> void:
	print("\n>> Testing Damage, Invulnerability Flash & Death Lifecycle...")
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate() as CharacterBody2D
	add_child(player)
	
	GameState.reset_run()
	_assert_almost_eq(GameState.current_health, 100.0, 0.01, "GameState starts with 100 HP")
	_assert(player.is_alive(), "Player starts alive")
	_assert(not player.is_dead, "Player is_dead is false")
	
	# Take 30 damage
	player.take_damage(30.0)
	_assert_almost_eq(GameState.current_health, 70.0, 0.01, "Health reduced to 70.0")
	_assert(player.is_invulnerable, "Player entered invulnerable state")
	_assert(player._is_flashing, "Damage flash active")
	
	# Simulate 0.5s to clear invulnerability
	player._update_timers(0.5)
	_assert(not player.is_invulnerable, "Invulnerability cleared after duration")
	_assert(not player._is_flashing, "Damage flash reverted")
	
	# Deal fatal damage (80 HP > 70 HP remaining)
	player.take_damage(80.0)
	_assert_almost_eq(GameState.current_health, 0.0, 0.01, "Health reduced to 0.0")
	_assert(player.is_dead, "Player is_dead is true")
	_assert(not player.is_alive(), "is_alive() returns false")
	_assert_eq(player.animated_sprite.animation, "death", "Player plays death animation")
	
	# Subsequent damage ignored
	player.take_damage(50.0)
	_assert_almost_eq(GameState.current_health, 0.0, 0.01, "Dead player ignores further damage")
	
	player.free()
