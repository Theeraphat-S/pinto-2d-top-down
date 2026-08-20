class_name BossGigaNull
extends "res://scenes/enemies/enemy_base.gd"

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - WAVE 5 BOSS: GIGA-NULL (Milestone M4)
# 3-Phase State Machine:
#  - Phase 1 (HP > 66%): Radial 8-orb ring bursts every 2.5s while pursuing player
#  - Phase 2 (33% < HP <= 66%): Enraged speed, minion add spawns every 5s, 3 rapid targeted bursts
#  - Phase 3 (HP <= 33%): Desperation charge dashes & 12-orb spiral bullet hell stream
# Emits boss_phase_changed, boss_hp_changed, boss_defeated, game_won. Drops 5 Large XP gems.
# ==============================================================================

const PROJECTILE_PATH: String = "res://scenes/weapons/enemy_projectile.tscn"
const SLIME_PATH: String = "res://scenes/enemies/enemy_slime.tscn"
const DRONE_PATH: String = "res://scenes/enemies/enemy_drone.tscn"
const BAT_PATH: String = "res://scenes/enemies/enemy_bat.tscn"

var current_phase: int = 1

# Phase 1 Timers
var _p1_ring_timer: float = 0.0
const P1_RING_INTERVAL: float = 2.5

# Phase 2 Timers & State
var _p2_minion_timer: float = 0.0
const P2_MINION_INTERVAL: float = 5.0
var _p2_burst_timer: float = 0.0
const P2_BURST_INTERVAL: float = 3.0
var _p2_burst_shots_left: int = 0
var _p2_shot_subtimer: float = 0.0

# Phase 3 Timers & State
var _p3_dash_timer: float = 0.0
const P3_DASH_INTERVAL: float = 4.5
var _is_dashing: bool = false
var _is_charging: bool = false
var _dash_subtimer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO
var _p3_spiral_timer: float = 0.0
var _p3_spiral_angle: float = 0.0
var _p3_spiral_shots_left: int = 0
var _p3_spiral_subtimer: float = 0.0

@onready var health_bar: ProgressBar = $HealthBar
@onready var phase_label: Label = $HealthBar/PhaseLabel

func _init() -> void:
	super._init()
	enemy_type = "boss"
	max_health = 600.0
	current_health = 600.0
	move_speed = 60.0
	contact_damage = 30.0
	score_value = 500
	drop_gem_tier = 2 # Large (20 XP each)
	drop_gem_count = 5 # 5 x 20 XP = 100 XP total
	knockback_resistance = 1.0 # Immune to knockback

func _ready() -> void:
	super._ready()
	add_to_group("boss")
	current_health = max_health
	current_phase = 1
	
	_update_health_bar()
	
	if event_bus:
		event_bus.boss_spawned.emit(self)
		event_bus.boss_hp_changed.emit(current_health, max_health)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Process phase-specific attack behaviors
	match current_phase:
		1:
			_process_phase_1(delta)
		2:
			_process_phase_2(delta)
		3:
			_process_phase_3(delta)
			
	# Move and slide
	super._physics_process(delta)

func _get_movement_direction(delta: float) -> Vector2:
	if is_dead:
		return Vector2.ZERO
		
	if current_phase == 3 and _is_dashing:
		return _dash_dir
	elif current_phase == 3 and _is_charging:
		return Vector2.ZERO
		
	return super._get_movement_direction(delta)

# ==============================================================================
# PHASE 1 BEHAVIOR: Pursuit + 8-Orb Radial Ring Bursts
# ==============================================================================

func _process_phase_1(delta: float) -> void:
	move_speed = 60.0
	_p1_ring_timer += delta
	if _p1_ring_timer >= P1_RING_INTERVAL:
		_p1_ring_timer = 0.0
		_fire_radial_ring(8, 180.0)

func _fire_radial_ring(count: int, proj_speed: float, base_angle: float = 0.0) -> void:
	var container := _get_spawn_container()
	if container == null:
		return
		
	var proj_scene: PackedScene = load(PROJECTILE_PATH) as PackedScene
	if proj_scene == null:
		return
		
	var angle_step := TAU / float(count)
	for i in range(count):
		var angle := base_angle + float(i) * angle_step
		var dir := Vector2.RIGHT.rotated(angle)
		var proj: Node = proj_scene.instantiate()
		if proj:
			if proj.has_method("init"):
				proj.init(global_position, dir, 8.0, proj_speed)
			elif proj is Node2D:
				proj.global_position = global_position
			container.call_deferred("add_child", proj)

# ==============================================================================
# PHASE 2 BEHAVIOR: Enraged Speed + Minion Adds + 3 Rapid Targeted Bursts
# ==============================================================================

func _process_phase_2(delta: float) -> void:
	move_speed = 90.0
	
	# 1. Minion adds
	_p2_minion_timer += delta
	if _p2_minion_timer >= P2_MINION_INTERVAL:
		_p2_minion_timer = 0.0
		_spawn_minion_adds()
		
	# 2. Targeted 3-shot burst
	_p2_burst_timer += delta
	if _p2_burst_timer >= P2_BURST_INTERVAL and _p2_burst_shots_left <= 0:
		_p2_burst_timer = 0.0
		_p2_burst_shots_left = 3
		_p2_shot_subtimer = 0.0
		
	if _p2_burst_shots_left > 0:
		_p2_shot_subtimer += delta
		if _p2_shot_subtimer >= 0.18:
			_p2_shot_subtimer = 0.0
			_p2_burst_shots_left -= 1
			_fire_targeted_shot()

func _spawn_minion_adds() -> void:
	var container := _get_spawn_container()
	if container == null:
		return
		
	var slime_scene: PackedScene = load(SLIME_PATH) as PackedScene
	var drone_scene: PackedScene = load(DRONE_PATH) as PackedScene
	
	var spawn_count := randi_range(2, 3)
	for i in range(spawn_count):
		var minion_scene = slime_scene if (i % 2 == 0) else drone_scene
		if minion_scene:
			var minion: Node = minion_scene.instantiate()
			if minion:
				var offset := Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0))
				if minion is Node2D:
					minion.global_position = global_position + offset
				container.call_deferred("add_child", minion)

func _fire_targeted_shot() -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
		
	var container := _get_spawn_container()
	if container == null:
		return
		
	var proj_scene: PackedScene = load(PROJECTILE_PATH) as PackedScene
	if proj_scene == null:
		return
		
	var proj: Node = proj_scene.instantiate()
	if proj:
		var dir := (target_player.global_position - global_position).normalized()
		if dir.length_squared() == 0.0:
			dir = Vector2.RIGHT
		if proj.has_method("init"):
			proj.init(global_position, dir, 10.0, 240.0)
		elif proj is Node2D:
			proj.global_position = global_position
		container.call_deferred("add_child", proj)

# ==============================================================================
# PHASE 3 BEHAVIOR: Desperation Charge Dash + Rotating Spiral Bullet Hell
# ==============================================================================

func _process_phase_3(delta: float) -> void:
	# 1. Charge Dash State Machine
	if not _is_dashing and not _is_charging:
		move_speed = 110.0
		_p3_dash_timer += delta
		if _p3_dash_timer >= P3_DASH_INTERVAL:
			_p3_dash_timer = 0.0
			_start_charge_telegraph()
	elif _is_charging:
		_dash_subtimer += delta
		# Visual telegraph shake/flash
		if sprite:
			sprite.modulate = Color(2.5, 0.4, 0.4, 1.0) if int(_dash_subtimer * 20.0) % 2 == 0 else Color.WHITE
		if _dash_subtimer >= 0.6:
			_execute_charge_dash()
	elif _is_dashing:
		move_speed = 320.0
		_dash_subtimer += delta
		if _dash_subtimer >= 0.8:
			_is_dashing = false
			move_speed = 110.0
			if sprite:
				sprite.modulate = Color.WHITE
				
	# 2. Spiral Bullet Hell Stream (12 orbs)
	_p3_spiral_timer += delta
	if _p3_spiral_timer >= 3.5 and _p3_spiral_shots_left <= 0:
		_p3_spiral_timer = 0.0
		_p3_spiral_shots_left = 12
		_p3_spiral_subtimer = 0.0
		
	if _p3_spiral_shots_left > 0:
		_p3_spiral_subtimer += delta
		if _p3_spiral_subtimer >= 0.12:
			_p3_spiral_subtimer = 0.0
			_p3_spiral_shots_left -= 1
			_fire_spiral_orb()

func _start_charge_telegraph() -> void:
	if target_player != null and is_instance_valid(target_player):
		_dash_dir = (target_player.global_position - global_position).normalized()
	else:
		_dash_dir = Vector2.RIGHT
	_is_charging = true
	_dash_subtimer = 0.0

func _execute_charge_dash() -> void:
	_is_charging = false
	_is_dashing = true
	_dash_subtimer = 0.0

func _fire_spiral_orb() -> void:
	var container := _get_spawn_container()
	if container == null:
		return
		
	var proj_scene: PackedScene = load(PROJECTILE_PATH) as PackedScene
	if proj_scene == null:
		return
		
	_p3_spiral_angle += 0.52 # ~30 degrees per shot
	var dir := Vector2.RIGHT.rotated(_p3_spiral_angle)
	var proj: Node = proj_scene.instantiate()
	if proj:
		if proj.has_method("init"):
			proj.init(global_position, dir, 8.0, 190.0)
		elif proj is Node2D:
			proj.global_position = global_position
		container.call_deferred("add_child", proj)

# ==============================================================================
# DAMAGE & PHASE TRANSITIONS
# ==============================================================================

func take_damage(amount: float, is_crit: bool = false) -> void:
	if is_dead or amount <= 0.0:
		return
		
	super.take_damage(amount, is_crit)
	_update_health_bar()
	
	if event_bus:
		event_bus.boss_hp_changed.emit(current_health, max_health)
		
	if current_health <= 0.0:
		return
		
	var ratio := current_health / max_health
	if ratio <= 0.33:
		if current_phase < 3:
			_enter_phase(3)
	elif ratio <= 0.66:
		if current_phase < 2:
			_enter_phase(2)

func _enter_phase(new_phase: int) -> void:
	if current_phase == new_phase:
		return
	current_phase = new_phase
	
	if phase_label:
		phase_label.text = "PHASE " + str(current_phase)
		
	if event_bus:
		event_bus.boss_phase_changed.emit(current_phase)
		
	# Phase transition effects
	if sprite:
		match current_phase:
			2:
				sprite.modulate = Color(1.3, 0.8, 0.8, 1.0)
			3:
				sprite.modulate = Color(1.5, 0.5, 0.5, 1.0)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	if event_bus:
		event_bus.boss_hp_changed.emit(0.0, max_health)
		event_bus.boss_phase_changed.emit(0)
		event_bus.boss_defeated.emit()
		event_bus.game_won.emit()
		
	# Dramatic explosion SFX
	var stream: AudioStream = preload("res://assets/sfx/explosion.wav")
	var container := _get_spawn_container()
	if stream and container:
		var sfx := AudioStreamPlayer2D.new()
		sfx.stream = stream
		sfx.global_position = global_position
		container.call_deferred("add_child", sfx)
		sfx.tree_entered.connect(func():
			sfx.play()
			sfx.finished.connect(sfx.queue_free)
		)
		
	super.die()
