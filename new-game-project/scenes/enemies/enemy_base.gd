class_name EnemyBase
extends CharacterBody2D

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - ENEMY BASE CLASS (Milestone M4 / R1 & R2)
# True top-down floating kinematics, foot collision, contact damage hurtbox,
# sprite animation cycling, damage flash, knockback resistance, floating damage
# numbers, XP gem drop generation & EventBus dispatch.
# ==============================================================================

const XP_GEM_PATH: String = "res://scenes/pickups/xp_gem.tscn"

@export var enemy_type: String = "base"
@export var max_health: float = 25.0:
	set(val):
		max_health = val
		current_health = val
@export var move_speed: float = 85.0
@export var contact_damage: float = 10.0
@export var score_value: int = 10
@export var drop_gem_tier: int = 0 # 0=Small (1XP), 1=Med (5XP), 2=Large (20XP), 3=Boss (100XP)
@export var drop_gem_count: int = 1
@export var knockback_resistance: float = 0.20
@export var contact_cooldown: float = 0.5
@export var animation_fps: float = 7.0

var current_health: float = 25.0
var is_dead: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var target_player: Node2D = null

var base_modulate: Color = Color.WHITE
var _anim_timer: float = 0.0
var _current_frame: int = 0
var _contact_timer: float = 0.0
var _flash_timer: float = 0.0
var _is_flashing: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox_area: Area2D = $HitboxArea
@onready var death_sfx: AudioStreamPlayer2D = $DeathSFX

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

func _ensure_nodes() -> void:
	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if hitbox_area == null:
		hitbox_area = get_node_or_null("HitboxArea") as Area2D
	if death_sfx == null:
		death_sfx = get_node_or_null("DeathSFX") as AudioStreamPlayer2D

func _init() -> void:
	add_to_group("enemies")
	y_sort_enabled = true
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	current_health = max_health
	_anim_timer = randf_range(0.0, 1.0)
	_current_frame = randi() % 4

func _ready() -> void:
	add_to_group("enemies")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	y_sort_enabled = true
	
	# Layer 3 (Enemies = 4), Mask Layer 1 (World = 1) + Layer 2 (Player = 2) + Layer 3 (Enemies = 4) = 7
	collision_layer = 4
	collision_mask = 7
	
	current_health = max_health
	
	_ensure_nodes()
	if sprite:
		var max_f: int = sprite.hframes if sprite.hframes > 0 else 4
		_current_frame = randi() % max_f
		sprite.frame = _current_frame
		sprite.modulate = base_modulate
	
	if hitbox_area:
		if not hitbox_area.body_entered.is_connected(_on_hitbox_body_entered):
			hitbox_area.body_entered.connect(_on_hitbox_body_entered)
			
	_find_player()

func _find_player() -> void:
	if is_inside_tree():
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0 and is_instance_valid(players[0]):
			target_player = players[0]

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	_ensure_nodes()
	
	# 1. Update timers and animation
	_update_timers(delta)
	_update_animation(delta)
	
	# 2. Acquire / validate player target
	if target_player == null or not is_instance_valid(target_player):
		_find_player()
		
	# 3. Calculate movement direction
	var move_dir := _get_movement_direction(delta)
	
	# 4. Integrate velocity with knockback damping
	if knockback_velocity.length_squared() > 1.0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1000.0 * delta)
	else:
		knockback_velocity = Vector2.ZERO
		
	if target_player != null and is_instance_valid(target_player):
		velocity = move_dir * move_speed + knockback_velocity
	elif knockback_velocity != Vector2.ZERO:
		velocity = knockback_velocity
		
	if is_inside_tree():
		move_and_slide()
	
	# 5. Flip sprite facing direction
	if sprite and absf(velocity.x) > 5.0:
		sprite.flip_h = (velocity.x < 0.0)
		
	# 6. Apply continuous contact damage if overlapping player
	_check_contact_damage()

func _update_animation(delta: float) -> void:
	_ensure_nodes()
	if sprite == null or sprite.hframes <= 1 or animation_fps <= 0.0:
		return
		
	_anim_timer += delta
	var frame_interval: float = 1.0 / animation_fps
	if _anim_timer >= frame_interval:
		_anim_timer = fmod(_anim_timer, frame_interval)
		_current_frame = (_current_frame + 1) % sprite.hframes
		sprite.frame = _current_frame

func _get_movement_direction(_delta: float) -> Vector2:
	if target_player == null or not is_instance_valid(target_player):
		return Vector2.ZERO
		
	var diff := target_player.global_position - global_position
	if diff.length_squared() > 0.0:
		return diff.normalized()
	return Vector2.ZERO

func _update_timers(delta: float) -> void:
	if _contact_timer > 0.0:
		_contact_timer -= delta
		
	if _is_flashing:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_is_flashing = false
			_ensure_nodes()
			if sprite:
				sprite.modulate = base_modulate

func take_damage(amount: float, is_crit: bool = false) -> void:
	if is_dead or amount <= 0.0:
		return
		
	current_health = maxf(0.0, current_health - amount)
	_flash_sprite(is_crit)
	_spawn_damage_number(amount, is_crit)
	
	if current_health <= 0.0:
		die()

func _spawn_damage_number(amount: float, is_crit: bool = false) -> void:
	if amount <= 0.0:
		return
		
	var container := _get_spawn_container()
	if container == null:
		return
		
	var scene: PackedScene = load("res://scenes/ui/damage_number.tscn") as PackedScene
	if scene == null:
		return
		
	var popup: Node = scene.instantiate()
	if popup:
		var offset := Vector2(randf_range(-4.0, 4.0), -14.0)
		var spawn_pos := global_position + offset
		if popup is Node2D:
			popup.global_position = spawn_pos
		if popup.has_method("setup"):
			popup.setup(amount, is_crit, spawn_pos)
		if container.is_inside_tree():
			container.call_deferred("add_child", popup)
		else:
			container.add_child(popup)

func apply_knockback(dir: Vector2, force: float) -> void:
	if is_dead or knockback_resistance >= 1.0:
		return
	var effective_force := force * (1.0 - clampf(knockback_resistance, 0.0, 1.0))
	knockback_velocity += dir.normalized() * effective_force

func _flash_sprite(is_crit: bool = false) -> void:
	_is_flashing = true
	_flash_timer = 0.08
	_ensure_nodes()
	if sprite:
		if is_crit:
			sprite.modulate = Color(2.0, 0.3, 0.3, 1.0) # Intense crit red
		else:
			sprite.modulate = Color(1.8, 1.8, 1.8, 1.0) # Bright damage flash

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.is_in_group("player") or body.name == "Player":
		_apply_contact_damage_to(body)

func _check_contact_damage() -> void:
	if is_dead or _contact_timer > 0.0 or hitbox_area == null:
		return
		
	var overlapping := hitbox_area.get_overlapping_bodies()
	for body in overlapping:
		if body.is_in_group("player") or body.name == "Player":
			_apply_contact_damage_to(body)
			break

func _apply_contact_damage_to(player_body: Node2D) -> void:
	if _contact_timer > 0.0 or is_dead:
		return
		
	if player_body.has_method("take_damage"):
		player_body.take_damage(contact_damage)
		_contact_timer = contact_cooldown

func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	_ensure_nodes()
	# Disable collisions immediately
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if hitbox_area:
		hitbox_area.set_deferred("monitoring", false)
		hitbox_area.set_deferred("monitorable", false)
		
	# Spawn XP gems
	_spawn_xp_gems()
	
	# Award Score and record kill
	if game_state:
		game_state.record_kill(enemy_type, score_value)
	elif event_bus:
		event_bus.enemy_killed.emit(enemy_type, score_value)
		
	# Play SFX
	_play_death_sfx()
	
	queue_free()

func _spawn_xp_gems() -> void:
	var container: Node = _get_spawn_container()
	if container == null:
		return
		
	var gem_scene: PackedScene = load(XP_GEM_PATH) as PackedScene
	if gem_scene == null:
		return
		
	for _i in range(drop_gem_count):
		var gem: Node = gem_scene.instantiate()
		if gem:
			var offset := Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)) if drop_gem_count > 1 else Vector2.ZERO
			var drop_pos := global_position + offset
			if gem.has_method("setup"):
				gem.setup(drop_gem_tier, drop_pos)
			elif gem is Node2D:
				gem.global_position = drop_pos
			if container.is_inside_tree():
				container.call_deferred("add_child", gem)
			else:
				container.add_child(gem)

func _get_spawn_container() -> Node:
	var p: Node = get_parent()
	if p != null:
		return p
		
	if not is_inside_tree():
		return null
		
	# Check for Arena in tree
	var arena := get_tree().root.find_child("Arena", true, false)
	if arena and arena.has_node("Entities"):
		return arena.get_node("Entities")
	elif arena:
		return arena
		
	return get_tree().root

func _play_death_sfx() -> void:
	var stream: AudioStream = preload("res://assets/sfx/hit.wav")
	var container := _get_spawn_container()
	if stream and container:
		var sfx := AudioStreamPlayer2D.new()
		sfx.stream = stream
		sfx.global_position = global_position
		if container.is_inside_tree():
			container.call_deferred("add_child", sfx)
		else:
			container.add_child(sfx)
		sfx.tree_entered.connect(func():
			sfx.play()
			sfx.finished.connect(sfx.queue_free)
		)

func is_alive() -> bool:
	return not is_dead and current_health > 0.0
