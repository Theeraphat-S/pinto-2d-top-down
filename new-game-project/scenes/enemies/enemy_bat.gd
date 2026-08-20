class_name EnemyBat
extends "res://scenes/enemies/enemy_base.gd"

# ==============================================================================
# CYBER BAT (Enemy Archetype)
# Fast flyer, erratic zig-zag / sine lateral flanking motion.
# HP 15, Speed 150, Contact Damage 8, Drops 1 Small XP Gem (1 XP)
# ==============================================================================

@export var wave_frequency: float = 6.0
@export var wave_amplitude: float = 0.7

var _flight_time: float = 0.0

func _init() -> void:
	super._init()
	enemy_type = "bat"
	max_health = 15.0
	current_health = 15.0
	move_speed = 150.0
	contact_damage = 8.0
	score_value = 15
	drop_gem_tier = 0 # Small (1 XP)
	drop_gem_count = 1
	knockback_resistance = 0.10

func _ready() -> void:
	super._ready()
	# Randomize flight phase offset so swarms don't oscillate synchronously
	_flight_time = randf_range(0.0, 2.0 * PI)

func _get_movement_direction(delta: float) -> Vector2:
	if target_player == null or not is_instance_valid(target_player):
		return Vector2.ZERO
		
	_flight_time += delta
	var to_player := target_player.global_position - global_position
	if to_player.length_squared() == 0.0:
		return Vector2.ZERO
		
	var forward := to_player.normalized()
	# Perpendicular lateral vector (counter-clockwise 90 deg)
	var lateral := Vector2(-forward.y, forward.x)
	
	# Sine oscillation
	var lateral_offset := sin(_flight_time * wave_frequency) * wave_amplitude
	var combined_dir := (forward + lateral * lateral_offset).normalized()
	
	return combined_dir
