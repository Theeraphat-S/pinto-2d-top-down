class_name Spawner
extends Node2D

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - 5-WAVE ESCALATING SPAWNER (Milestone M4)
# Manages escalating enemy waves, viewport-aware spawn positioning,
# wave timer countdowns, and Wave 5 Boss encounter integration.
# ==============================================================================

const ENEMY_PATHS := {
	"slime": "res://scenes/enemies/enemy_slime.tscn",
	"bat": "res://scenes/enemies/enemy_bat.tscn",
	"drone": "res://scenes/enemies/enemy_drone.tscn",
	"golem": "res://scenes/enemies/enemy_golem.tscn",
	"boss": "res://scenes/enemies/boss_giga_null.tscn"
}

const WAVE_CONFIGS := {
	1: {
		"duration": 30.0,
		"spawn_interval": 1.5,
		"mix": {"slime": 1.0},
		"is_boss_wave": false
	},
	2: {
		"duration": 35.0,
		"spawn_interval": 1.2,
		"mix": {"slime": 0.6, "bat": 0.4},
		"is_boss_wave": false
	},
	3: {
		"duration": 40.0,
		"spawn_interval": 1.0,
		"mix": {"slime": 0.4, "bat": 0.3, "drone": 0.3},
		"is_boss_wave": false
	},
	4: {
		"duration": 45.0,
		"spawn_interval": 0.8,
		"mix": {"slime": 0.25, "bat": 0.25, "drone": 0.25, "golem": 0.25},
		"is_boss_wave": false
	},
	5: {
		"duration": -1.0, # Indefinite until Boss is defeated
		"spawn_interval": 3.0,
		"mix": {"slime": 0.5, "bat": 0.3, "drone": 0.2},
		"is_boss_wave": true
	}
}

@export var is_active: bool = true
@export var current_wave: int = 1

var wave_time_remaining: float = 30.0
var _spawn_timer: float = 0.0
var _boss_instance: Node2D = null
var _is_boss_defeated: bool = false
var _wave_in_progress: bool = false

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

func _ready() -> void:
	_connect_event_bus()
	if is_active:
		start_spawner()

func _connect_event_bus() -> void:
	if event_bus:
		if not event_bus.boss_defeated.is_connected(_on_boss_defeated):
			event_bus.boss_defeated.connect(_on_boss_defeated)

func start_spawner() -> void:
	current_wave = 1
	_start_wave(current_wave)

func set_wave(wave_num: int) -> void:
	current_wave = clamp(wave_num, 1, 5)
	_start_wave(current_wave)

func _start_wave(wave_num: int) -> void:
	current_wave = wave_num
	_wave_in_progress = true
	_spawn_timer = 0.0
	
	if game_state:
		game_state.current_wave = current_wave
		
	var config: Dictionary = WAVE_CONFIGS.get(current_wave, WAVE_CONFIGS[1])
	wave_time_remaining = config.get("duration", 30.0)
	
	if event_bus:
		event_bus.wave_started.emit(current_wave, wave_time_remaining)
		
	if config.get("is_boss_wave", false):
		_spawn_boss()

func _process(delta: float) -> void:
	if not is_active or not _wave_in_progress:
		return
		
	var config: Dictionary = WAVE_CONFIGS.get(current_wave, WAVE_CONFIGS[1])
	var is_boss_wave: bool = config.get("is_boss_wave", false)
	
	# 1. Wave Timer Countdown (Waves 1-4)
	if not is_boss_wave:
		if wave_time_remaining > 0.0:
			wave_time_remaining -= delta
			if wave_time_remaining <= 0.0:
				wave_time_remaining = 0.0
				_complete_current_wave()
				return
				
	# 2. Periodic Enemy Spawning
	var interval: float = config.get("spawn_interval", 1.5)
	_spawn_timer += delta
	if _spawn_timer >= interval:
		_spawn_timer = 0.0
		_spawn_wave_enemy(config)

func _complete_current_wave() -> void:
	if event_bus:
		event_bus.wave_completed.emit(current_wave)
		
	if current_wave < 5:
		current_wave += 1
		_start_wave(current_wave)
	else:
		_wave_in_progress = false

func _spawn_wave_enemy(config: Dictionary) -> void:
	var mix: Dictionary = config.get("mix", {"slime": 1.0})
	var enemy_type := _select_random_enemy_type(mix)
	if enemy_type.is_empty():
		return
		
	spawn_enemy(enemy_type)

func _select_random_enemy_type(mix: Dictionary) -> String:
	var roll := randf()
	var cumulative := 0.0
	for enemy_type in mix.keys():
		cumulative += float(mix[enemy_type])
		if roll <= cumulative:
			return enemy_type
	# Fallback to first entry
	if mix.keys().size() > 0:
		return mix.keys()[0]
	return "slime"

func spawn_enemy(enemy_type: String, custom_pos: Vector2 = Vector2.ZERO) -> Node2D:
	if not ENEMY_PATHS.has(enemy_type):
		push_warning("[Spawner] Unknown enemy type: " + enemy_type)
		return null
		
	var enemy_scene: PackedScene = load(ENEMY_PATHS[enemy_type]) as PackedScene
	if enemy_scene == null:
		return null
		
	var enemy: Node = enemy_scene.instantiate()
	if enemy == null:
		return null
		
	var spawn_pos: Vector2 = custom_pos
	if spawn_pos == Vector2.ZERO:
		spawn_pos = _get_outside_viewport_spawn_pos()
		
	if enemy is Node2D:
		enemy.global_position = spawn_pos
		
	var container := _get_entities_container()
	if container:
		container.call_deferred("add_child", enemy)
	else:
		call_deferred("add_child", enemy)
		
	return enemy as Node2D

func _spawn_boss() -> void:
	if _boss_instance != null and is_instance_valid(_boss_instance):
		return
		
	var container := _get_entities_container()
	if container == null:
		return
		
	var boss_scene: PackedScene = load(ENEMY_PATHS["boss"]) as PackedScene
	if boss_scene == null:
		return
		
	var boss: Node = boss_scene.instantiate()
	if boss:
		_boss_instance = boss as Node2D
		
		# Place boss at top or center-top of arena
		var arena := _get_arena()
		if arena and arena.has_method("get_playable_bounds"):
			var bounds: Rect2 = arena.get_playable_bounds()
			_boss_instance.global_position = bounds.position + Vector2(bounds.size.x * 0.5, 80.0)
		else:
			_boss_instance.global_position = Vector2(640.0, 160.0)
			
		container.call_deferred("add_child", boss)
			
		if event_bus:
			event_bus.boss_spawned.emit(_boss_instance)

func _on_boss_defeated() -> void:
	_is_boss_defeated = true
	if current_wave == 5:
		_complete_current_wave()

func _get_outside_viewport_spawn_pos() -> Vector2:
	var player_pos := Vector2(640.0, 360.0)
	if is_inside_tree():
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0 and is_instance_valid(players[0]) and players[0] is Node2D:
			player_pos = players[0].global_position
			
	var arena := _get_arena()
	if arena and arena.has_method("get_random_spawn_point_outside_viewport"):
		return arena.get_random_spawn_point_outside_viewport(player_pos)
		
	# Fallback spawn position outside 640x360 box centered on player
	var angle := randf_range(0.0, TAU)
	var dist := randf_range(380.0, 480.0)
	return player_pos + Vector2.RIGHT.rotated(angle) * dist

func _get_arena() -> Node:
	if not is_inside_tree():
		return null
	var p: Node = get_parent()
	while p != null:
		if p is Arena or p.name == "Arena":
			return p
		p = p.get_parent()
	return get_tree().root.find_child("Arena", true, false)

func _get_entities_container() -> Node:
	var arena := _get_arena()
	if arena and arena.has_node("Entities"):
		return arena.get_node("Entities")
	elif arena:
		return arena
	return get_parent() if get_parent() else self

func get_wave_configs() -> Dictionary:
	return WAVE_CONFIGS

func get_time_remaining() -> float:
	return wave_time_remaining

func get_current_wave() -> int:
	return current_wave
