class_name EnemySlime
extends "res://scenes/enemies/enemy_base.gd"

# ==============================================================================
# GLITCH SLIME (Enemy Archetype)
# Swarm melee chaser, HP 25, Speed 85, Contact Damage 10, Drops 1 Small XP Gem (1 XP)
# ==============================================================================

func _init() -> void:
	super._init()
	enemy_type = "slime"
	max_health = 25.0
	current_health = 25.0
	move_speed = 85.0
	contact_damage = 10.0
	score_value = 10
	drop_gem_tier = 0 # Small (1 XP)
	drop_gem_count = 1
	knockback_resistance = 0.20
	animation_fps = 7.0

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_dead and sprite:
		var hop := sin(_anim_timer * animation_fps * PI)
		sprite.scale = Vector2(1.0 - hop * 0.08, 1.0 + hop * 0.12)
