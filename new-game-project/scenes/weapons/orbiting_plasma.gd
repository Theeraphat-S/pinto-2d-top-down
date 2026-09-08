class_name OrbitingPlasma
extends Node2D

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - ORBITING PLASMA WEAPON SUBSYSTEM
# 2 to 4 plasma orbs rotating around Pinto, dealing contact damage & knockback.
# ==============================================================================

@export var rank: int = 1:
	set(val):
		rank = clampi(val, 1, 3)
		_update_stats_for_rank()

var orb_count: int = 2
var radius: float = 46.0
var rotation_speed: float = 2.8 # rad / sec
var base_damage: float = 14.0

var _current_angle: float = 0.0
var _hit_cooldowns: Dictionary = {} # enemy (Node/int) -> time remaining
var _orbs: Array[Area2D] = []

var game_state: Node:
	get:
		if is_inside_tree() and get_tree() and get_tree().root.has_node("GameState"):
			return get_tree().root.get_node("GameState")
		return null

func _ready() -> void:
	z_index = 10
	_update_stats_for_rank()
	_rebuild_orbs()

func _update_stats_for_rank() -> void:
	match rank:
		1:
			orb_count = 2
			base_damage = 14.0
			rotation_speed = 2.8
			radius = 44.0
		2:
			orb_count = 3
			base_damage = 18.0
			rotation_speed = 3.4
			radius = 48.0
		3:
			orb_count = 4
			base_damage = 24.0
			rotation_speed = 4.0
			radius = 52.0
	if is_inside_tree():
		_rebuild_orbs()

func _rebuild_orbs() -> void:
	for orb in _orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	_orbs.clear()
	
	for i in range(orb_count):
		var area := Area2D.new()
		area.name = "OrbArea_%d" % i
		area.collision_layer = 0
		area.collision_mask = 4 # Enemies collision layer
		area.monitoring = true
		area.monitorable = false
		
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 8.0
		shape.shape = circle
		area.add_child(shape)
		
		add_child(area)
		_orbs.append(area)

func _physics_process(delta: float) -> void:
	_current_angle = fmod(_current_angle + rotation_speed * delta, TAU)
	
	# Clean up hit cooldowns
	var to_remove: Array = []
	for k in _hit_cooldowns.keys():
		_hit_cooldowns[k] -= delta
		if _hit_cooldowns[k] <= 0.0:
			to_remove.append(k)
	for k in to_remove:
		_hit_cooldowns.erase(k)
		
	# Position orbs and check contact
	var step := TAU / float(max(1, orb_count))
	for i in range(_orbs.size()):
		var orb := _orbs[i]
		if not is_instance_valid(orb):
			continue
			
		var angle := _current_angle + float(i) * step
		var orb_offset := Vector2(cos(angle), sin(angle)) * radius
		orb.position = orb_offset
		
		var bodies := orb.get_overlapping_bodies()
		for body in bodies:
			_try_damage_target(body, orb.global_position)
			
	queue_redraw()

func _try_damage_target(target: Node, orb_pos: Vector2) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return
		
	var enemy_node: Node = target
	if not enemy_node.has_method("take_damage"):
		if target.get_parent() and target.get_parent().has_method("take_damage"):
			enemy_node = target.get_parent()
			
	if not enemy_node.has_method("take_damage"):
		return
		
	var instance_id = enemy_node.get_instance_id()
	if _hit_cooldowns.has(instance_id):
		return
		
	# Apply damage
	var dmg_mult: float = (game_state.attack_damage / 20.0) if game_state else 1.0
	var final_dmg: float = base_damage * dmg_mult
	
	enemy_node.take_damage(final_dmg, false)
	_hit_cooldowns[instance_id] = 0.35 # Cooldown per enemy in seconds
	
	# Apply slight outward knockback
	if enemy_node.has_method("apply_knockback"):
		var knock_dir: Vector2 = (enemy_node.global_position - global_position).normalized()
		enemy_node.apply_knockback(knock_dir, 120.0)
		
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_plasma"):
		am.play_plasma()

func _draw() -> void:
	var step := TAU / float(max(1, orb_count))
	for i in range(orb_count):
		var angle := _current_angle + float(i) * step
		var p := Vector2(cos(angle), sin(angle)) * radius
		# Outer glow
		draw_circle(p, 8.0, Color(0.1, 0.75, 1.0, 0.45))
		# Core bright orb
		draw_circle(p, 5.0, Color(0.85, 0.98, 1.0, 0.95))
