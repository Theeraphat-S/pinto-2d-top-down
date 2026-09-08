class_name ThunderStrike
extends WeaponBase

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - THUNDER STRIKE WEAPON SUBSYSTEM (ADR 0001)
# Periodically discharges targeted lightning bolts from above on nearby enemies.
# Conforms to standardized WeaponBase contract.
# ==============================================================================

var strike_interval: float = 1.8
var strike_count: int = 1
var range_radius: float = 240.0
var aoe_radius: float = 28.0

var _timer: float = 0.0
var _active_bolts: Array[Dictionary] = [] # {points: Array[Vector2], alpha: float}

func _init() -> void:
	weapon_id = "weapon_thunder"
	weapon_name = "Thunder Strike"
	max_rank = 3
	base_damage = 35.0
	base_cooldown = 1.8

func _ready() -> void:
	z_index = 20
	_update_stats_for_rank()

func _on_rank_changed() -> void:
	_update_stats_for_rank()

func _update_stats_for_rank() -> void:
	match rank:
		1:
			strike_interval = 1.8
			base_cooldown = 1.8
			strike_count = 1
			base_damage = 35.0
		2:
			strike_interval = 1.5
			base_cooldown = 1.5
			strike_count = 2
			base_damage = 48.0
		3:
			strike_interval = 1.2
			base_cooldown = 1.2
			strike_count = 3
			base_damage = 65.0

func tick(delta: float) -> void:
	_timer += delta
	var effective_interval := get_effective_cooldown()
	
	if _timer >= effective_interval:
		_timer = 0.0
		fire()
		
	# Fade active visual bolts
	if not _active_bolts.is_empty():
		var remaining: Array[Dictionary] = []
		for bolt in _active_bolts:
			bolt.alpha -= delta * 5.0
			if bolt.alpha > 0.0:
				remaining.append(bolt)
		_active_bolts = remaining
		queue_redraw()

func fire() -> void:
	_discharge_lightning()

func get_stats() -> Dictionary:
	var s := super.get_stats()
	s["strike_count"] = strike_count
	s["strike_interval"] = strike_interval
	s["range_radius"] = range_radius
	s["aoe_radius"] = aoe_radius
	return s

func _discharge_lightning() -> void:
	if not is_inside_tree():
		return
		
	var enemies := get_tree().get_nodes_in_group("enemies")
	var valid_targets: Array[Node2D] = []
	var max_dist_sq := range_radius * range_radius
	
	for e in enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion():
			continue
		if e is Node2D:
			if "is_dead" in e and e.is_dead:
				continue
			if "current_health" in e and e.current_health <= 0:
				continue
			if global_position.distance_squared_to(e.global_position) <= max_dist_sq:
				valid_targets.append(e)
				
	if valid_targets.is_empty():
		return
		
	valid_targets.shuffle()
	var targets_to_hit := mini(strike_count, valid_targets.size())
	var final_dmg := get_effective_damage()
	
	for i in range(targets_to_hit):
		var target := valid_targets[i]
		if not is_instance_valid(target):
			continue
			
		var strike_pos := target.global_position
		_create_visual_bolt(strike_pos)
		_apply_aoe_damage(strike_pos, final_dmg)
		
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_thunder"):
		am.play_thunder()
		
	if event_bus:
		event_bus.screen_shake_requested.emit(0.25, 0.18)

func _apply_aoe_damage(center: Vector2, dmg: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var aoe_sq := aoe_radius * aoe_radius
	
	for e in enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion():
			continue
		if e is Node2D and e.has_method("take_damage"):
			if "is_dead" in e and e.is_dead:
				continue
			if center.distance_squared_to(e.global_position) <= aoe_sq:
				var crit_rate: float = game_state.crit_chance if game_state else 0.05
				var is_crit: bool = (randf() < crit_rate)
				var crit_mult: float = (game_state.crit_multiplier if game_state else 1.5) if is_crit else 1.0
				var dmg_with_crit: float = dmg * crit_mult
				e.take_damage(dmg_with_crit, is_crit)

func _create_visual_bolt(target_pos: Vector2) -> void:
	# Local coordinates relative to self
	var local_end := to_local(target_pos)
	var local_start := local_end + Vector2(randf_range(-16.0, 16.0), -190.0)
	
	var points: Array[Vector2] = [local_start]
	var segments := 5
	for s in range(1, segments):
		var prog := float(s) / float(segments)
		var base_p := local_start.lerp(local_end, prog)
		var jitter := Vector2(randf_range(-14.0, 14.0), randf_range(-4.0, 4.0))
		points.append(base_p + jitter)
	points.append(local_end)
	
	_active_bolts.append({
		"points": points,
		"alpha": 1.0
	})
	queue_redraw()

func _draw() -> void:
	for bolt in _active_bolts:
		var pts: Array[Vector2] = bolt.points
		var a: float = bolt.alpha
		if pts.size() < 2:
			continue
		for i in range(pts.size() - 1):
			# Outer thick glow
			draw_line(pts[i], pts[i+1], Color(0.2, 0.8, 1.0, a * 0.5), 5.0)
			# Core sharp bolt
			draw_line(pts[i], pts[i+1], Color(1.0, 1.0, 1.0, a * 0.95), 2.0)
