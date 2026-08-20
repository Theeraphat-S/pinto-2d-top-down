class_name Player
extends CharacterBody2D

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - PINTO PLAYER CHARACTER
# 8-Directional kinematics, AnimatedSprite2D states, auto-targeting weapon system,
# XP magnet area, and damage/death handling.
# ==============================================================================

const PROJECTILE_SCENE = preload("res://scenes/weapons/projectile.tscn")
const PROJECTILE_SCRIPT = preload("res://scenes/weapons/projectile.gd")
const PINTO_FRAMES = preload("res://scenes/player/pinto_frames.tres")

const ACCELERATION: float = 1200.0
const FRICTION: float = 1400.0
const SPREAD_ANGLE_DEG: float = 15.0
const INVULNERABILITY_DURATION: float = 0.4

# State variables
var is_dead: bool = false
var is_invulnerable: bool = false
var _last_hp: float = 100.0
var _invulnerability_timer: float = 0.0
var _attack_timer: float = 0.0
var _flash_timer: float = 0.0
var _is_flashing: bool = false

# Child node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var magnet_area: Area2D = $MagnetArea
@onready var magnet_shape: CollisionShape2D = $MagnetArea/MagnetCollisionShape
@onready var shoot_sfx: AudioStreamPlayer2D = $ShootSFX
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSFX

# Autoload accessors with safe fallback
var game_state: Node:
	get:
		if is_inside_tree() and get_tree() and get_tree().root.has_node("GameState"):
			return get_tree().root.get_node("GameState")
		return null

var event_bus: Node:
	get:
		if is_inside_tree() and get_tree() and get_tree().root.has_node("EventBus"):
			return get_tree().root.get_node("EventBus")
		return null

func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	y_sort_enabled = true
	_last_hp = game_state.current_health if game_state else 100.0
	
	# Layer 2 (Player = 2), Mask Layer 1 (World = 1)
	collision_layer = 2
	collision_mask = 1
	
	if animated_sprite and PINTO_FRAMES:
		animated_sprite.sprite_frames = PINTO_FRAMES
		animated_sprite.play("idle")
		
	_update_magnet_radius()
	_connect_events()

func _connect_events() -> void:
	if event_bus:
		if not event_bus.player_died.is_connected(_on_player_died):
			event_bus.player_died.connect(_on_player_died)
		if not event_bus.player_health_changed.is_connected(_on_player_health_changed):
			event_bus.player_health_changed.connect(_on_player_health_changed)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		move_and_slide()
		return
		
	# 1. Kinematic 8-Directional Movement
	var input_vector := _get_input_vector()
	var current_speed: float = game_state.move_speed if game_state else 160.0
	var target_velocity := input_vector * current_speed
	
	if input_vector.length_squared() > 0.0:
		velocity = velocity.move_toward(target_velocity, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	move_and_slide()
	
	# 2. Sprite Animation Selection
	_update_animation(input_vector)
	
	# 3. Invulnerability and Damage Flash Timers
	_update_timers(delta)
	
	# 4. Auto-Attack Weapon System
	_process_auto_attack(delta)
	
	# 5. Magnet Area Radius Sync
	_update_magnet_radius()

# ==============================================================================
# INPUT & KINEMATICS
# ==============================================================================

func _get_input_vector() -> Vector2:
	var raw := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if raw.length_squared() > 0.0:
		return raw.normalized()
	return Vector2.ZERO

static func calculate_input_vector(raw_x: float, raw_y: float) -> Vector2:
	var raw := Vector2(raw_x, raw_y)
	if raw.length_squared() > 0.0:
		return raw.normalized()
	return Vector2.ZERO

static func integrate_velocity(current_vel: Vector2, input_dir: Vector2, speed: float, accel: float, frict: float, delta: float) -> Vector2:
	var target_vel: Vector2 = input_dir * speed
	if input_dir.length_squared() > 0.0:
		return current_vel.move_toward(target_vel, accel * delta)
	else:
		return current_vel.move_toward(Vector2.ZERO, frict * delta)

# ==============================================================================
# ANIMATION STATE MACHINE
# ==============================================================================

func _update_animation(_input_vector: Vector2) -> void:
	if animated_sprite == null:
		return
		
	if is_dead:
		if animated_sprite.animation != "death":
			animated_sprite.play("death")
		return
		
	if _is_flashing:
		# Keep current hurt or move animation while flashing
		pass
		
	if velocity.length_squared() > 10.0:
		if absf(velocity.y) > absf(velocity.x):
			if velocity.y > 0.0:
				animated_sprite.play("walk_down")
			else:
				animated_sprite.play("walk_up")
		else:
			animated_sprite.play("walk_side")
			animated_sprite.flip_h = (velocity.x < 0.0)
	else:
		animated_sprite.play("idle")

# ==============================================================================
# AUTO-ATTACK WEAPON SYSTEM
# ==============================================================================

func _process_auto_attack(delta: float) -> void:
	if not game_state or not game_state.is_game_active or game_state.is_paused:
		return
		
	_attack_timer += delta
	var cooldown: float = max(0.05, game_state.attack_cooldown if game_state else 0.5)
	var max_range: float = game_state.attack_range if game_state else 220.0
	
	if _attack_timer >= cooldown:
		var target: Variant = find_nearest_target(global_position, get_tree().get_nodes_in_group("enemies"), max_range)
		if target:
			_fire_projectiles(target)
			_attack_timer = 0.0

func _fire_projectiles(target: Variant) -> void:
	var target_pos: Vector2 = Vector2.ZERO
	if target is Node2D:
		target_pos = target.global_position
	elif target is Dictionary:
		target_pos = target.get("position", Vector2.ZERO)
	else:
		return
		
	var dir_to_target: Vector2 = (target_pos - global_position).normalized()
	if dir_to_target.length_squared() == 0.0:
		dir_to_target = Vector2.RIGHT
		
	var base_angle: float = dir_to_target.angle()
	var count: int = max(1, game_state.projectile_count if game_state else 1)
	var angles: Array[float] = calculate_spread_angles(base_angle, count, SPREAD_ANGLE_DEG)
	
	var spawn_parent: Node = get_parent() if get_parent() else (get_tree().root if get_tree() else null)
	if spawn_parent == null:
		return
		
	for angle in angles:
		var proj_dir: Vector2 = Vector2.RIGHT.rotated(angle)
		var proj: Node = PROJECTILE_SCENE.instantiate()
		if proj:
			if proj.has_method("init"):
				proj.init(
					global_position,
					proj_dir,
					game_state.attack_damage if game_state else 20.0,
					game_state.projectile_speed if game_state else 380.0,
					game_state.projectile_pierce if game_state else 1,
					game_state.crit_chance if game_state else 0.05,
					game_state.crit_multiplier if game_state else 1.5
				)
			elif proj is Node2D:
				proj.global_position = global_position
			spawn_parent.call_deferred("add_child", proj)
			
	# SFX and Global Event
	if shoot_sfx and shoot_sfx.stream:
		shoot_sfx.play()
	elif has_node("ShootSFX"):
		$ShootSFX.play()
		
	if event_bus:
		event_bus.projectile_fired.emit(global_position, dir_to_target)

static func calculate_spread_angles(base_angle_rad: float, count: int, spread_deg: float = 15.0) -> Array[float]:
	var angles: Array[float] = []
	var spread_rad: float = deg_to_rad(spread_deg)
	for i in range(count):
		var offset: float = (float(i) - (float(count) - 1.0) / 2.0) * spread_rad
		angles.append(base_angle_rad + offset)
	return angles

static func find_nearest_target(pinto_pos: Vector2, enemies: Array, max_range: float) -> Variant:
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
			if "is_dead" in e and e.is_dead:
				continue
			if "current_health" in e and e.current_health <= 0:
				continue
			var d_sq: float = pinto_pos.distance_squared_to(e.global_position)
			if d_sq <= min_dist_sq:
				min_dist_sq = d_sq
				nearest_target = e
				
	return nearest_target

# ==============================================================================
# MAGNET AREA SYNC
# ==============================================================================

func _update_magnet_radius() -> void:
	if magnet_shape and magnet_shape.shape is CircleShape2D:
		var target_rad: float = game_state.magnet_radius if game_state else 90.0
		var circle := magnet_shape.shape as CircleShape2D
		if not is_equal_approx(circle.radius, target_rad):
			circle.radius = target_rad

# ==============================================================================
# DAMAGE, FLASH & DEATH HANDLING
# ==============================================================================

func take_damage(amount: float) -> void:
	if is_dead or is_invulnerable or amount <= 0.0:
		return
		
	_start_hurt_effects()
	if game_state:
		game_state.take_damage(amount)

func _start_hurt_effects() -> void:
	is_invulnerable = true
	_invulnerability_timer = INVULNERABILITY_DURATION
	_is_flashing = true
	_flash_timer = 0.15
	
	if animated_sprite:
		animated_sprite.modulate = Color(1.0, 0.4, 0.4, 0.9)
		
	if hurt_sfx and hurt_sfx.stream:
		hurt_sfx.play()

func _update_timers(delta: float) -> void:
	if is_invulnerable:
		_invulnerability_timer -= delta
		if _invulnerability_timer <= 0.0:
			is_invulnerable = false
			
	if _is_flashing:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_is_flashing = false
			if animated_sprite:
				animated_sprite.modulate = Color.WHITE

func _on_player_health_changed(current_hp: float, _max_hp: float) -> void:
	if current_hp <= 0.0:
		_handle_death()
	elif current_hp < _last_hp and not is_invulnerable:
		_start_hurt_effects()
	_last_hp = current_hp

func _on_player_died() -> void:
	_handle_death()

func _handle_death() -> void:
	if is_dead:
		return
	is_dead = true
	is_invulnerable = false
	_is_flashing = false
	velocity = Vector2.ZERO
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
		animated_sprite.play("death")
	# Disable collisions on death
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

func is_alive() -> bool:
	return not is_dead and (game_state.current_health > 0.0 if game_state else true)
