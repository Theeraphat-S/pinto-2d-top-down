class_name EnemyDrone
extends "res://scenes/enemies/enemy_base.gd"

# ==============================================================================
# CRT DRONE (Enemy Archetype)
# Ranged standoff shooter, keeps 180px distance, fires energy orb projectile every 2.0s.
# HP 40, Speed 70, Contact Damage 5, Drops 1 Medium XP Gem (5 XP)
# ==============================================================================

const PROJECTILE_SCENE = preload("res://scenes/weapons/enemy_projectile.tscn")

@export var shoot_interval: float = 2.0
@export var standoff_distance: float = 180.0
@export var projectile_speed: float = 200.0
@export var projectile_damage: float = 8.0

var _shoot_timer: float = 0.0
var _strafe_sign: float = 1.0

func _init() -> void:
	super._init()
	enemy_type = "drone"
	max_health = 40.0
	current_health = 40.0
	move_speed = 70.0
	contact_damage = 5.0
	score_value = 25
	drop_gem_tier = 1 # Medium (5 XP)
	drop_gem_count = 1
	knockback_resistance = 0.30
	animation_fps = 6.0

func _ready() -> void:
	super._ready()
	_shoot_timer = randf_range(0.5, shoot_interval) # Offset initial shot
	_strafe_sign = 1.0 if randf() > 0.5 else -1.0

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Process shooting timer
	_process_shooting(delta)
	
	super._physics_process(delta)

func _get_movement_direction(_delta: float) -> Vector2:
	if target_player == null or not is_instance_valid(target_player):
		return Vector2.ZERO
		
	var diff := target_player.global_position - global_position
	var dist := diff.length()
	if dist == 0.0:
		return Vector2.ZERO
		
	var to_player := diff / dist
	var margin := 25.0
	
	if dist > standoff_distance + margin:
		# Advance toward player
		return to_player
	elif dist < standoff_distance - margin:
		# Retreat away from player
		return -to_player
	else:
		# Orbit / strafe tangentially around player
		var tangent := Vector2(-to_player.y, to_player.x) * _strafe_sign
		return tangent.normalized()

func _process_shooting(delta: float) -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
		
	_shoot_timer += delta
	if _shoot_timer >= shoot_interval:
		_shoot_timer = 0.0
		_fire_projectile()

func _fire_projectile() -> void:
	if target_player == null or not is_instance_valid(target_player) or PROJECTILE_SCENE == null:
		return
		
	var spawn_container := _get_spawn_container()
	if spawn_container == null:
		return
		
	var proj: Node = PROJECTILE_SCENE.instantiate()
	if proj:
		var dir := (target_player.global_position - global_position).normalized()
		if dir.length_squared() == 0.0:
			dir = Vector2.RIGHT
		if proj.has_method("init"):
			proj.init(global_position, dir, projectile_damage, projectile_speed)
		elif proj is Node2D:
			proj.global_position = global_position
		spawn_container.call_deferred("add_child", proj)
