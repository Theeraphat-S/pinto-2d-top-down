class_name EnemyGolem
extends "res://scenes/enemies/enemy_base.gd"

# ==============================================================================
# MEGABYTE GOLEM (Enemy Archetype)
# Heavy tank bruiser, massive health pool, heavy contact damage, high knockback resist.
# HP 120, Speed 50, Contact Damage 25, Drops 1 Large XP Gem (20 XP)
# ==============================================================================

func _init() -> void:
	super._init()
	enemy_type = "golem"
	max_health = 120.0
	current_health = 120.0
	move_speed = 50.0
	contact_damage = 25.0
	score_value = 50
	drop_gem_tier = 2 # Large (20 XP)
	drop_gem_count = 1
	knockback_resistance = 0.85
	animation_fps = 6.0

func _ready() -> void:
	super._ready()
