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
	shadow_offset = Vector2(0, 11)
	shadow_radius = Vector2(15.0, 5.5)
	shadow_color = Color(0.0, 0.0, 0.0, 0.40)

func _ready() -> void:
	super._ready()
	_setup_golem_light()

func _setup_golem_light() -> void:
	if has_node("GolemLight") or is_elite:
		return
	var pl := PointLight2D.new()
	pl.name = "GolemLight"
	pl.texture = RADIAL_LIGHT_TEX
	pl.color = Color(1.8, 0.8, 0.1, 1.0)
	pl.energy = 0.50
	pl.texture_scale = 0.85
	add_child(pl)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_dead and sprite:
		var stomp := sin(_anim_timer * animation_fps * PI)
		sprite.scale = Vector2(1.0 + stomp * 0.05, 1.0 - stomp * 0.04)
