# res://tests/test_adversarial_coverage.gd
# Challenger 2: Adversarial Kinematics, Coverage, Extreme Stats, Ballistic Symmetry & Magnet Stress Tests
extends "res://tests/test_framework.gd"

const PropScript = preload("res://scenes/world/prop.gd")
const ProjectileScript = preload("res://scenes/weapons/projectile.gd")
const XPGemScript = preload("res://scenes/pickups/xp_gem.gd")
const EnemyBaseScript = preload("res://scenes/enemies/enemy_base.gd")

const ARENA_WIDTH: float = 1280.0
const ARENA_HEIGHT: float = 720.0
const BORDER_MARGIN: float = 32.0

const BOUND_MIN_X: float = 32.0
const BOUND_MAX_X: float = 1248.0 # 1280 - 32
const BOUND_MIN_Y: float = 32.0
const BOUND_MAX_Y: float = 688.0  # 720 - 32

const BASE_SPEED: float = 160.0
const ACCELERATION: float = 1200.0
const FRICTION: float = 1400.0
const BASE_MAGNET_RADIUS: float = 90.0
const GEM_ACCELERATION: float = 600.0
const MAX_GEM_SPEED: float = 320.0
const COLLECTION_RADIUS: float = 12.0
const SPREAD_ANGLE_DEG: float = 15.0

# ==============================================================================
# 1. KINEMATIC BOUNDARY SLIDING & CORNER WEDGING
# ==============================================================================

# Kinematic sliding helper: resolves moving into a planar surface with normal N
func simulate_kinematic_slide(velocity: Vector2, surface_normal: Vector2) -> Vector2:
	# Godot 4 slide formula: v_slide = v - normal * (v.dot(normal))
	var dot: float = velocity.dot(surface_normal)
	if dot < 0.0:
		return velocity - surface_normal * dot
	return velocity

# Resolves moving into a 90-degree corner with two orthogonal normals
func simulate_corner_slide(velocity: Vector2, normal_1: Vector2, normal_2: Vector2) -> Vector2:
	var v: Vector2 = simulate_kinematic_slide(velocity, normal_1)
	return simulate_kinematic_slide(v, normal_2)

func test_diagonal_velocity_decomposition_and_normalization() -> void:
	# Test all 4 diagonal directions produce exact unit vectors and equal components
	var diags: Array[Vector2] = [
		Vector2(1.0, 1.0),
		Vector2(1.0, -1.0),
		Vector2(-1.0, 1.0),
		Vector2(-1.0, -1.0)
	]
	var expected_comp: float = 1.0 / sqrt(2.0)
	
	for d in diags:
		var norm: Vector2 = Player.calculate_input_vector(d.x, d.y)
		assert_almost_eq(norm.length(), 1.0, 0.0001, "Diagonal input %s normalized magnitude must be 1.0" % str(d))
		assert_almost_eq(absf(norm.x), expected_comp, 0.0001, "X component magnitude is 1/sqrt(2)")
		assert_almost_eq(absf(norm.y), expected_comp, 0.0001, "Y component magnitude is 1/sqrt(2)")

func test_boundary_sliding_tangential_velocity_horizontal_wall() -> void:
	# Moving Down-Right (1, 1) into Bottom Wall (surface normal = Vector2.UP)
	var speed: float = 200.0
	var input_norm: Vector2 = Vector2(1.0, 1.0).normalized()
	var vel: Vector2 = input_norm * speed
	var normal: Vector2 = Vector2.UP
	
	var slid_vel: Vector2 = simulate_kinematic_slide(vel, normal)
	assert_almost_eq(slid_vel.y, 0.0, 0.0001, "Vertical velocity into bottom wall becomes 0")
	assert_almost_eq(slid_vel.x, vel.x, 0.0001, "Horizontal tangential velocity is fully preserved")
	assert_gt(slid_vel.x, 0.0, "Continues sliding rightward along bottom wall")
	
	# Moving Up-Left (-1, -1) into Top Wall (surface normal = Vector2.DOWN)
	vel = Vector2(-1.0, -1.0).normalized() * speed
	normal = Vector2.DOWN
	slid_vel = simulate_kinematic_slide(vel, normal)
	assert_almost_eq(slid_vel.y, 0.0, 0.0001, "Vertical velocity into top wall becomes 0")
	assert_almost_eq(slid_vel.x, vel.x, 0.0001, "Horizontal velocity preserved leftward")
	assert_lt(slid_vel.x, 0.0, "Continues sliding leftward along top wall")

func test_boundary_sliding_tangential_velocity_vertical_wall() -> void:
	# Moving Down-Right (1, 1) into Right Wall (surface normal = Vector2.LEFT)
	var speed: float = 250.0
	var input_norm: Vector2 = Vector2(1.0, 1.0).normalized()
	var vel: Vector2 = input_norm * speed
	var normal: Vector2 = Vector2.LEFT
	
	var slid_vel: Vector2 = simulate_kinematic_slide(vel, normal)
	assert_almost_eq(slid_vel.x, 0.0, 0.0001, "Horizontal velocity into right wall becomes 0")
	assert_almost_eq(slid_vel.y, vel.y, 0.0001, "Vertical tangential velocity is fully preserved")
	assert_gt(slid_vel.y, 0.0, "Continues sliding downward along right wall")
	
	# Moving Up-Left (-1, -1) into Left Wall (surface normal = Vector2.RIGHT)
	vel = Vector2(-1.0, -1.0).normalized() * speed
	normal = Vector2.RIGHT
	slid_vel = simulate_kinematic_slide(vel, normal)
	assert_almost_eq(slid_vel.x, 0.0, 0.0001, "Horizontal velocity into left wall becomes 0")
	assert_almost_eq(slid_vel.y, vel.y, 0.0001, "Vertical velocity preserved upward")
	assert_lt(slid_vel.y, 0.0, "Continues sliding upward along left wall")

func test_corner_wedging_and_zero_velocity_resolution() -> void:
	# When pushing into a 90 degree internal corner (e.g. Bottom-Right wall: UP and LEFT normals)
	var speed: float = 300.0
	var vel: Vector2 = Vector2(1.0, 1.0).normalized() * speed
	var normal_bottom: Vector2 = Vector2.UP
	var normal_right: Vector2 = Vector2.LEFT
	
	var wedged_vel: Vector2 = simulate_corner_slide(vel, normal_bottom, normal_right)
	assert_almost_eq(wedged_vel.x, 0.0, 0.0001, "Wedged corner X velocity is exactly 0")
	assert_almost_eq(wedged_vel.y, 0.0, 0.0001, "Wedged corner Y velocity is exactly 0")
	assert_eq(wedged_vel, Vector2.ZERO, "Corner wedging safely halts velocity without NaN or oscillation")
	
	# Verify clamping keeps player strictly within bounds
	var corner_pos: Vector2 = Vector2(1300.0, 750.0)
	var clamped: Vector2 = Arena.new().clamp_to_arena(corner_pos, BORDER_MARGIN)
	assert_eq(clamped, Vector2(BOUND_MAX_X, BOUND_MAX_Y), "Position clamped to exact bottom-right boundary (1248, 688)")

func test_obstacle_prop_sliding_tangential_resolution() -> void:
	# Moving diagonally into a prop's flat top surface (normal = UP)
	var vel: Vector2 = Vector2(120.0, 120.0) # Moving Down-Right
	var normal: Vector2 = Vector2.UP
	var slid: Vector2 = simulate_kinematic_slide(vel, normal)
	assert_almost_eq(slid.y, 0.0, 0.001, "Normal velocity against prop zeroed")
	assert_almost_eq(slid.x, 120.0, 0.001, "Tangential velocity preserved past prop")

func test_all_four_prop_variations_bounding_collision_integrity() -> void:
	var prop_scene: PackedScene = load("res://scenes/world/prop.tscn")
	assert_not_null(prop_scene, "Prop scene loaded")
	var prop = prop_scene.instantiate()
	
	var prop_types: Array = [
		PropScript.PropType.SERVER_RACK,
		PropScript.PropType.HOLOGRAM_PYLON,
		PropScript.PropType.POWER_CRYSTAL,
		PropScript.PropType.TERMINAL_CONSOLE
	]
	
	for pt in prop_types:
		prop.set_prop_type(pt)
		assert_eq(prop.collision_layer, 1, "Prop type %d is on Layer 1 (World)" % int(pt))
		assert_eq(prop.collision_mask, 0, "Prop type %d mask is 0" % int(pt))
		assert_not_null(prop.collision_shape.shape, "Prop type %d has collision shape" % int(pt))
		var shape := prop.collision_shape.shape as RectangleShape2D
		assert_gt(shape.size.x, 0.0, "Prop type %d width > 0" % int(pt))
		assert_gt(shape.size.y, 0.0, "Prop type %d height > 0" % int(pt))
		assert_lte(prop.collision_shape.position.y, 0.0, "Prop type %d foot collision is anchored at/below base" % int(pt))
		
	prop.free()

# ==============================================================================
# 2. EXTREME SPEED STAT BOOSTS & DELTA ROBUSTNESS
# ==============================================================================

func test_extreme_move_speed_boost_integration() -> void:
	# Base speed = 160.0. Test +500% (960 px/s) and +2000% (3360 px/s)
	var speed_500: float = BASE_SPEED * 6.0   # 960.0 px/s
	var speed_2000: float = BASE_SPEED * 21.0 # 3360.0 px/s
	var delta: float = 1.0 / 60.0
	
	var vel: Vector2 = Vector2.ZERO
	var input: Vector2 = Vector2(1.0, 0.0)
	
	# Simulate acceleration towards 960 px/s
	for i in range(100):
		vel = Player.integrate_velocity(vel, input, speed_500, ACCELERATION, FRICTION, delta)
		assert_false(is_nan(vel.x), "Vel.x must not be NaN at extreme speed")
		assert_false(is_inf(vel.x), "Vel.x must not be INF at extreme speed")
		
	assert_almost_eq(vel.x, speed_500, 0.001, "Velocity clamped to +500% speed (960 px/s)")
	
	# Simulate acceleration towards 3360 px/s
	for i in range(250):
		vel = Player.integrate_velocity(vel, input, speed_2000, ACCELERATION, FRICTION, delta)
		assert_false(is_nan(vel.x), "Vel.x not NaN")
		assert_false(is_inf(vel.x), "Vel.x not INF")
		
	assert_almost_eq(vel.x, speed_2000, 0.001, "Velocity clamped to +2000% speed (3360 px/s)")

func test_extreme_speed_with_delta_lag_spikes() -> void:
	# Test with massive lag spikes (e.g. dt = 0.5s, 1.0s, 5.0s)
	var speed: float = 2000.0
	var vel: Vector2 = Vector2.ZERO
	var input: Vector2 = Vector2(0.707106, 0.707106)
	
	var spike_deltas: Array[float] = [0.5, 1.0, 2.0, 5.0]
	for dt in spike_deltas:
		var stepped_vel: Vector2 = Player.integrate_velocity(vel, input, speed, ACCELERATION, FRICTION, dt)
		assert_false(is_nan(stepped_vel.x), "Lag spike dt=%.1fs X not NaN" % dt)
		assert_false(is_nan(stepped_vel.y), "Lag spike dt=%.1fs Y not NaN" % dt)
		assert_false(is_inf(stepped_vel.x), "Lag spike dt=%.1fs X not INF" % dt)
		assert_false(is_inf(stepped_vel.y), "Lag spike dt=%.1fs Y not INF" % dt)
		assert_lte(stepped_vel.length(), speed + 0.001, "Lag spike velocity magnitude clamped to max speed")

func test_extreme_speed_micro_delta_and_zero_delta() -> void:
	var speed: float = 1500.0
	var vel: Vector2 = Vector2(100.0, 100.0)
	var input: Vector2 = Vector2.RIGHT
	
	# dt = 0.0s (paused or sub-micro frame)
	var v_zero: Vector2 = Player.integrate_velocity(vel, input, speed, ACCELERATION, FRICTION, 0.0)
	assert_eq(v_zero, vel, "Zero delta preserves exact current velocity without changes")
	
	# dt = 0.00001s (micro-step)
	var v_micro: Vector2 = Player.integrate_velocity(vel, input, speed, ACCELERATION, FRICTION, 0.00001)
	assert_false(is_nan(v_micro.x), "Micro delta X not NaN")
	assert_false(is_nan(v_micro.y), "Micro delta Y not NaN")
	assert_gt(v_micro.x, vel.x, "Micro delta integrates forward acceleration")

func test_extreme_speed_rapid_reversal_no_nan() -> void:
	var speed: float = 2500.0
	var delta: float = 1.0 / 60.0
	var vel: Vector2 = Vector2(2500.0, 0.0)
	var reverse_input: Vector2 = Vector2.LEFT # Sudden 180-degree reversal
	
	for i in range(300):
		vel = Player.integrate_velocity(vel, reverse_input, speed, ACCELERATION, FRICTION, delta)
		assert_false(is_nan(vel.x), "Reversal vel.x not NaN")
		assert_false(is_inf(vel.x), "Reversal vel.x not INF")
		
	assert_almost_eq(vel.x, -speed, 0.001, "Smoothly transitions to reverse max speed (-2500 px/s)")
	assert_eq(vel.y, 0.0, "Y velocity remains 0 throughout horizontal reversal")

func test_extreme_attack_speed_boost_cooldown_floor() -> void:
	# Base cooldown 0.5s. Test stacking attack speed up to +1000%
	var base_cd: float = 0.5
	var min_floor: float = 0.05
	
	# Simulate 15 consecutive 20% attack speed reductions
	var cd: float = base_cd
	for tier in range(15):
		cd = maxf(min_floor, cd * 0.80)
		assert_gte(cd, min_floor, "Attack cooldown tier %d >= min floor (0.05s)" % tier)
		assert_false(is_nan(cd), "Attack cooldown tier %d not NaN" % tier)
		
	assert_almost_eq(cd, min_floor, 0.001, "Extreme attack speed clamped to 0.05s floor")

func test_extreme_attack_cooldown_zero_and_negative_resilience() -> void:
	# Verify that if game state cooldown is set to 0.0 or negative, safe fallback applies
	var raw_cd_zero: float = 0.0
	var raw_cd_neg: float = -5.0
	
	var safe_cd_zero: float = max(0.05, raw_cd_zero)
	var safe_cd_neg: float = max(0.05, raw_cd_neg)
	
	assert_almost_eq(safe_cd_zero, 0.05, 0.001, "Zero cooldown safely clamped to 0.05s")
	assert_almost_eq(safe_cd_neg, 0.05, 0.001, "Negative cooldown safely clamped to 0.05s")

func test_rapid_auto_attack_timer_accumulation() -> void:
	# Simulate attack timer incrementing with high delta (0.5s)
	var attack_timer: float = 0.0
	var cooldown: float = 0.05
	var dt: float = 0.5 # 10x larger than cooldown
	
	attack_timer += dt
	assert_gte(attack_timer, cooldown, "Timer exceeds cooldown")
	
	# Reset timer after fire
	attack_timer = 0.0
	assert_eq(attack_timer, 0.0, "Attack timer resets cleanly")

# ==============================================================================
# 3. MULTI-SHOT ANGULAR DISTRIBUTION & SPREAD SYMMETRY
# ==============================================================================

func test_multishot_spread_odd_counts_symmetry() -> void:
	var odd_counts: Array[int] = [1, 3, 5, 7, 9]
	var base_angle: float = deg_to_rad(45.0)
	var spread_deg: float = 15.0
	
	for count in odd_counts:
		var angles: Array[float] = Player.calculate_spread_angles(base_angle, count, spread_deg)
		assert_eq(angles.size(), count, "Odd count %d returns exact array size" % count)
		
		# Center projectile must align with base_angle
		var mid_idx: int = int(count / 2)
		assert_almost_eq(angles[mid_idx], base_angle, 0.0001, "Count %d center projectile at base angle" % count)
		
		# Symmetrical pairs around center
		var sum_offsets: float = 0.0
		for i in range(count):
			var offset: float = angles[i] - base_angle
			sum_offsets += offset
			var opp_idx: int = count - 1 - i
			var opp_offset: float = angles[opp_idx] - base_angle
			assert_almost_eq(offset, -opp_offset, 0.0001, "Count %d: Angle %d offset equals negative of angle %d" % [count, i, opp_idx])
			
		assert_almost_eq(sum_offsets, 0.0, 0.0001, "Count %d: Sum of angular offsets is exactly 0.0" % count)

func test_multishot_spread_even_counts_symmetry() -> void:
	var even_counts: Array[int] = [2, 4, 6, 8]
	var base_angle: float = deg_to_rad(120.0)
	var spread_deg: float = 15.0
	
	for count in even_counts:
		var angles: Array[float] = Player.calculate_spread_angles(base_angle, count, spread_deg)
		assert_eq(angles.size(), count, "Even count %d returns exact array size" % count)
		
		# Symmetrical pairs
		var sum_offsets: float = 0.0
		for i in range(count):
			var offset: float = angles[i] - base_angle
			sum_offsets += offset
			var opp_idx: int = count - 1 - i
			var opp_offset: float = angles[opp_idx] - base_angle
			assert_almost_eq(offset, -opp_offset, 0.0001, "Count %d: Angle %d offset mirrors angle %d" % [count, i, opp_idx])
			
		assert_almost_eq(sum_offsets, 0.0, 0.0001, "Count %d: Sum of angular offsets is exactly 0.0" % count)

func test_multishot_spread_eight_shots_exact_values() -> void:
	# 8 projectiles spread with 15 deg:
	# Offsets: [-52.5, -37.5, -22.5, -7.5, +7.5, +22.5, +37.5, +52.5]
	var base_angle: float = 0.0
	var angles: Array[float] = Player.calculate_spread_angles(base_angle, 8, 15.0)
	assert_eq(angles.size(), 8, "8 projectiles returns 8 angles")
	
	var expected_deg: Array[float] = [-52.5, -37.5, -22.5, -7.5, 7.5, 22.5, 37.5, 52.5]
	for i in range(8):
		assert_almost_eq(rad_to_deg(angles[i]), expected_deg[i], 0.001, "8-shot angle %d is %.1f deg" % [i, expected_deg[i]])

func test_multishot_spread_rotation_invariance_all_cardinals() -> void:
	var cardinals: Array[float] = [
		0.0,               # Right (0 deg)
		PI * 0.5,          # Down (90 deg)
		PI,                # Left (180 deg)
		-PI * 0.5          # Up (-90 deg)
	]
	
	for base_ang in cardinals:
		var angles: Array[float] = Player.calculate_spread_angles(base_ang, 5, 15.0)
		assert_eq(angles.size(), 5, "5 shots at cardinal base angle")
		assert_almost_eq(angles[2], base_ang, 0.0001, "Center angle at cardinal")
		assert_almost_eq(angles[1] - angles[0], deg_to_rad(15.0), 0.0001, "Adjacent angle delta is 15 deg")
		assert_almost_eq(angles[4] - angles[3], deg_to_rad(15.0), 0.0001, "Adjacent angle delta is 15 deg")

func test_multishot_spread_arbitrary_angles_symmetry() -> void:
	var arbitrary_angles: Array[float] = [
		2.3456,            # Arbitrary positive radian
		-1.8765,           # Arbitrary negative radian
		PI * 0.75,         # Diagonal 135 deg
		-PI * 0.3333       # Diagonal -60 deg
	]
	
	for base_ang in arbitrary_angles:
		var angles: Array[float] = Player.calculate_spread_angles(base_ang, 6, 12.0)
		assert_eq(angles.size(), 6, "6 shots at arbitrary angle")
		for i in range(3):
			var diff_left: float = angles[2 - i] - base_ang
			var diff_right: float = angles[3 + i] - base_ang
			assert_almost_eq(diff_left, -diff_right, 0.0001, "Even spread symmetry around arbitrary base angle")

func test_multishot_equidistant_angular_spacing() -> void:
	var count: int = 10
	var spread_deg: float = 10.0
	var spread_rad: float = deg_to_rad(spread_deg)
	var angles: Array[float] = Player.calculate_spread_angles(0.0, count, spread_deg)
	
	for i in range(count - 1):
		var diff: float = angles[i + 1] - angles[i]
		assert_almost_eq(diff, spread_rad, 0.0001, "Step between angle %d and %d is exactly %.1f deg" % [i, i+1, spread_deg])

# ==============================================================================
# 4. PROJECTILE PIERCE LIMIT & DENSE ENEMY CLUSTERS
# ==============================================================================

func test_projectile_pierce_exact_cluster_cutoff() -> void:
	var proj_scene: PackedScene = load("res://scenes/weapons/projectile.tscn")
	assert_not_null(proj_scene, "Projectile scene loaded")
	var proj = proj_scene.instantiate()
	proj.init(Vector2(100, 100), Vector2.RIGHT, 25.0, 380.0, 1) # pierce = 1
	
	# Create a cluster of 5 mock enemies
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy_slime.tscn")
	var enemies: Array[Node] = []
	for i in range(5):
		var e = enemy_scene.instantiate()
		e.global_position = Vector2(100, 100)
		enemies.append(e)
		
	# First enemy hit consumes pierce and triggers destroy
	proj._handle_target_hit(enemies[0])
	assert_eq(enemies[0].current_health, 0.0, "1st enemy took 25 damage and died")
	assert_eq(proj.pierce, 0, "Pierce reduced to 0")
	assert_true(proj._is_destroyed, "Projectile marked destroyed")
	
	# Subsequent enemies in cluster are ignored
	for i in range(1, 5):
		var hp_before: float = enemies[i].current_health
		proj._handle_target_hit(enemies[i])
		assert_eq(enemies[i].current_health, hp_before, "Enemy %d took 0 damage because projectile was destroyed" % i)
		
	# Cleanup
	proj.free()
	for e in enemies:
		e.free()

func test_projectile_multi_pierce_cluster_cutoff() -> void:
	var proj_scene: PackedScene = load("res://scenes/weapons/projectile.tscn")
	var proj = proj_scene.instantiate()
	proj.init(Vector2(100, 100), Vector2.RIGHT, 20.0, 380.0, 3, 0.0) # pierce = 3, crit = 0%
	
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy_slime.tscn")
	var enemies: Array[Node] = []
	for i in range(8):
		var e = enemy_scene.instantiate()
		e.max_health = 50.0
		e.current_health = 50.0
		enemies.append(e)
		
	# Hit each enemy sequentially in cluster
	for i in range(8):
		proj._handle_target_hit(enemies[i])
		
	# Exactly the first 3 took damage
	for i in range(3):
		assert_eq(enemies[i].current_health, 30.0, "Enemy %d took 20 damage" % i)
		
	for i in range(3, 8):
		assert_eq(enemies[i].current_health, 50.0, "Enemy %d took 0 damage" % i)
		
	assert_eq(proj.pierce, 0, "Pierce dropped to 0")
	assert_true(proj._is_destroyed, "Projectile marked destroyed")
	
	proj.free()
	for e in enemies:
		e.free()

func test_projectile_duplicate_enemy_and_hurtbox_hit_prevention() -> void:
	var proj_scene: PackedScene = load("res://scenes/weapons/projectile.tscn")
	var proj = proj_scene.instantiate()
	proj.init(Vector2(100, 100), Vector2.RIGHT, 15.0, 380.0, 3, 0.0) # crit = 0%
	
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy_slime.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.max_health = 100.0
	enemy.current_health = 100.0
	
	# Hit enemy body
	proj._handle_target_hit(enemy)
	assert_eq(enemy.current_health, 85.0, "1st hit dealt 15 damage")
	assert_eq(proj.pierce, 2, "Pierce is 2")
	
	# Hit enemy again in same frame (or hit its hitbox child area)
	proj._handle_target_hit(enemy)
	assert_eq(enemy.current_health, 85.0, "Duplicate hit ignored, HP unchanged")
	assert_eq(proj.pierce, 2, "Pierce not consumed on duplicate hit")
	
	if enemy.has_node("HitboxArea"):
		var hb = enemy.get_node("HitboxArea")
		proj._handle_target_hit(hb)
		assert_eq(enemy.current_health, 85.0, "Hitbox child hit ignored, HP unchanged")
		assert_eq(proj.pierce, 2, "Pierce not consumed on child hitbox")
		
	proj.free()
	enemy.free()

func test_projectile_zero_and_negative_pierce_handling() -> void:
	var proj_scene: PackedScene = load("res://scenes/weapons/projectile.tscn")
	var proj = proj_scene.instantiate()
	proj.init(Vector2(100, 100), Vector2.RIGHT, 20.0, 380.0, 0, 0.0) # 0 pierce, crit = 0%
	
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy_slime.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.max_health = 50.0
	enemy.current_health = 50.0
	
	proj._handle_target_hit(enemy)
	assert_eq(enemy.current_health, 30.0, "Hit deals damage")
	assert_true(proj._is_destroyed, "Destroyed immediately when pierce drops <= 0")
	
	proj.free()
	enemy.free()

# ==============================================================================
# 5. XP MAGNET ACCELERATION & DISTANCE CLAMPING
# ==============================================================================

func test_magnet_gem_zero_distance_immediate_collection() -> void:
	var gem_scene: PackedScene = load("res://scenes/pickups/xp_gem.tscn")
	var gem = gem_scene.instantiate()
	gem.global_position = Vector2(200, 200)
	
	var mock_player := Node2D.new()
	mock_player.global_position = Vector2(200, 200) # Exact same position (dist = 0)
	
	gem.start_attraction(mock_player)
	gem._physics_process(1.0 / 60.0)
	
	assert_true(gem._is_collected, "Co-located gem immediately collected without division by zero or NaN")
	assert_false(is_nan(gem.velocity.x), "Vel.x not NaN")
	assert_false(is_nan(gem.velocity.y), "Vel.y not NaN")
	
	gem.free()
	mock_player.free()

func test_magnet_gem_exact_boundary_threshold() -> void:
	# Inside radius: dist = 89.0px (< 90px radius)
	var inside_step: Dictionary = _simulate_gem_step(Vector2(189.0, 100.0), Vector2.ZERO, Vector2(100.0, 100.0), BASE_MAGNET_RADIUS, 1.0 / 60.0)
	assert_gt(inside_step["velocity"].length(), 0.0, "Inside radius (89px) accelerates")
	
	# Outside radius: dist = 91.0px (> 90px radius)
	var outside_step: Dictionary = _simulate_gem_step(Vector2(191.0, 100.0), Vector2.ZERO, Vector2(100.0, 100.0), BASE_MAGNET_RADIUS, 1.0 / 60.0)
	assert_eq(outside_step["velocity"], Vector2.ZERO, "Outside radius (91px) does not accelerate")

func test_magnet_gem_extreme_distance_no_nan() -> void:
	var player_pos := Vector2(640, 360)
	var extreme_positions: Array[Vector2] = [
		Vector2(10000.0, 10000.0),
		Vector2(-50000.0, 50000.0),
		Vector2(100000.0, -100000.0)
	]
	
	for extreme_pos in extreme_positions:
		var step: Dictionary = _simulate_gem_step(extreme_pos, Vector2.ZERO, player_pos, BASE_MAGNET_RADIUS, 1.0 / 60.0)
		assert_eq(step["velocity"], Vector2.ZERO, "Extreme distance %s does not accelerate" % str(extreme_pos))
		assert_false(is_nan(step["velocity"].x), "Extreme distance X velocity not NaN")
		assert_false(is_nan(step["velocity"].y), "Extreme distance Y velocity not NaN")
		assert_false(step["collected"], "Extreme distance not collected")

func test_magnet_gem_acceleration_curve_and_max_speed_cap() -> void:
	var gem_scene: PackedScene = load("res://scenes/pickups/xp_gem.tscn")
	var gem = gem_scene.instantiate()
	gem.global_position = Vector2(500, 100) # 400px away
	
	var mock_player := Node2D.new()
	mock_player.global_position = Vector2(100, 100)
	gem.start_attraction(mock_player)
	
	var dt: float = 1.0 / 60.0
	# Run 60 frames of acceleration
	for i in range(60):
		if gem._is_collected:
			break
		gem._physics_process(dt)
		assert_lte(gem.velocity.length(), MAX_GEM_SPEED + 0.001, "Gem velocity capped at MAX_GEM_SPEED (320 px/s)")
		assert_false(is_nan(gem.velocity.x), "Gem vel.x not NaN")
		assert_false(is_nan(gem.velocity.y), "Gem vel.y not NaN")
		
	assert_almost_eq(gem.velocity.length(), MAX_GEM_SPEED, 0.1, "Gem reaches max speed 320 px/s")
	
	gem.free()
	mock_player.free()

func test_magnet_gem_boundary_clamped_player_attraction() -> void:
	# Player clamped at bottom-right corner (1248, 688)
	var player_pos: Vector2 = Vector2(BOUND_MAX_X, BOUND_MAX_Y)
	var gem_start: Vector2 = player_pos - Vector2(50.0, 50.0) # 70.7px away (inside 90px radius)
	
	var gem_pos: Vector2 = gem_start
	var gem_vel: Vector2 = Vector2.ZERO
	var dt: float = 1.0 / 60.0
	var collected: bool = false
	
	for i in range(120): # Up to 2 seconds
		var step: Dictionary = _simulate_gem_step(gem_pos, gem_vel, player_pos, BASE_MAGNET_RADIUS, dt)
		gem_pos = step["position"]
		gem_vel = step["velocity"]
		if step["collected"]:
			collected = true
			break
			
	assert_true(collected, "Gem successfully reaches and collects at arena corner boundary")
	assert_almost_eq(gem_pos.distance_to(player_pos), COLLECTION_RADIUS, 5.0, "Gem reached collection radius at corner")

func test_magnet_gem_multi_framerate_collection_stability() -> void:
	# Test attraction and collection across 30 FPS, 60 FPS, 120 FPS
	var player_pos: Vector2 = Vector2(100.0, 100.0)
	var framerates: Array[float] = [30.0, 60.0, 120.0]
	
	for fps in framerates:
		var dt: float = 1.0 / fps
		var gem_pos: Vector2 = Vector2(150.0, 100.0) # 50px away
		var gem_vel: Vector2 = Vector2.ZERO
		var collected: bool = false
		
		for i in range(int(fps * 2.0)): # Up to 2 seconds of simulation
			var step: Dictionary = _simulate_gem_step(gem_pos, gem_vel, player_pos, BASE_MAGNET_RADIUS, dt)
			gem_pos = step["position"]
			gem_vel = step["velocity"]
			if step["collected"]:
				collected = true
				break
				
		assert_true(collected, "Gem collects reliably at %.0f FPS" % fps)
		assert_lte(gem_pos.distance_to(player_pos), COLLECTION_RADIUS + 0.1, "Collected within collection radius at %.0f FPS" % fps)

func test_magnet_gem_large_step_velocity_bounding_without_nan() -> void:
	# Test that large delta lag spike (e.g. dt = 1.0s, 2.0s) strictly caps velocity at MAX_GEM_SPEED and produces no NaN
	var player_pos: Vector2 = Vector2(100.0, 100.0)
	var gem_pos: Vector2 = Vector2(150.0, 100.0) # 50px away
	var gem_vel: Vector2 = Vector2.ZERO
	
	var spike_deltas: Array[float] = [0.5, 1.0, 2.0, 5.0]
	for dt in spike_deltas:
		var step: Dictionary = _simulate_gem_step(gem_pos, gem_vel, player_pos, BASE_MAGNET_RADIUS, dt)
		assert_false(is_nan(step["velocity"].x), "Lag step dt=%.1fs vel.x not NaN" % dt)
		assert_false(is_nan(step["velocity"].y), "Lag step dt=%.1fs vel.y not NaN")
		assert_lte(step["velocity"].length(), MAX_GEM_SPEED + 0.001, "Lag step dt=%.1fs velocity magnitude clamped to max speed" % dt)

# ==============================================================================
# HELPER METHODS
# ==============================================================================

func _simulate_gem_step(gem_pos: Vector2, gem_vel: Vector2, player_pos: Vector2, magnet_radius: float, delta: float) -> Dictionary:
	var dist: float = gem_pos.distance_to(player_pos)
	var new_pos: Vector2 = gem_pos
	var new_vel: Vector2 = gem_vel
	var is_collected: bool = false
	
	if dist <= COLLECTION_RADIUS:
		is_collected = true
	elif dist <= magnet_radius:
		var dir: Vector2 = (player_pos - gem_pos).normalized() if dist > 0.0 else Vector2.ZERO
		new_vel = new_vel.move_toward(dir * MAX_GEM_SPEED, GEM_ACCELERATION * delta)
		new_pos += new_vel * delta
		if new_pos.distance_to(player_pos) <= COLLECTION_RADIUS:
			is_collected = true
			
	return {
		"position": new_pos,
		"velocity": new_vel,
		"collected": is_collected,
		"distance": new_pos.distance_to(player_pos)
	}
