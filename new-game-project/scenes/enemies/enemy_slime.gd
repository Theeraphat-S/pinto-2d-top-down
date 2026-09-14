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
	shadow_offset = Vector2(0, 5)
	shadow_radius = Vector2(9.0, 3.5)

var slime_light: PointLight2D = null

func _ready() -> void:
	super._ready()
	if not is_elite:
		slime_light = _create_point_light("SlimeLight", Color(0.2, 1.8, 0.4, 1.0), 0.35, 0.5)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_dead:
		if sprite:
			var hop := sin(_anim_timer * animation_fps * PI)
			sprite.scale = Vector2(1.0 - hop * 0.08, 1.0 + hop * 0.12)
		if slime_light and is_instance_valid(slime_light):
			slime_light.energy = 0.35 + 0.1 * sin(_anim_timer * 6.0)
