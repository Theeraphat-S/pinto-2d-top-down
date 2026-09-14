class_name MainGame
extends Node2D

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - MAIN GAME LOOP CONTROLLER
# Orchestrates Arena, Player, Camera, Spawner, HUD, and Lifecycle Modals.
# ==============================================================================

@onready var arena: Node2D = $Arena
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var upgrade_menu: CanvasLayer = $UpgradeMenu
@onready var victory_screen: CanvasLayer = $VictoryScreen
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var spawner: Node2D = get_node_or_null("Spawner")

var _trauma: float = 0.0
var _trauma_power: float = 2.0
var _max_shake_offset: float = 12.0
var _shake_decay: float = 3.2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_initialize_game()
	_configure_camera()
	_connect_event_bus()

func _connect_event_bus() -> void:
	var eb = get_node_or_null("/root/EventBus")
	if eb:
		if not eb.screen_shake_requested.is_connected(_on_screen_shake_requested):
			eb.screen_shake_requested.connect(_on_screen_shake_requested)
		if not eb.hit_stop_requested.is_connected(_on_hit_stop_requested):
			eb.hit_stop_requested.connect(_on_hit_stop_requested)
		if eb.has_signal("wave_started") and not eb.wave_started.is_connected(_on_wave_started):
			eb.wave_started.connect(_on_wave_started)
		if eb.has_signal("boss_defeated") and not eb.boss_defeated.is_connected(_on_boss_defeated):
			eb.boss_defeated.connect(_on_boss_defeated)

func _initialize_game() -> void:
	if get_tree():
		get_tree().paused = false
		
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.reset_run()
		
	# Place player at arena center (1280, 720)
	if player:
		var center_pos := Vector2(1280.0, 720.0)
		if arena and arena.has_method("get_arena_bounds"):
			center_pos = arena.get_arena_bounds().get_center()
		player.global_position = center_pos
		if camera:
			camera.global_position = player.global_position
			
	# Restore saved fullscreen display mode preference
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("apply_display_mode"):
		sm.apply_display_mode()

func _configure_camera() -> void:
	if not camera:
		return
		
	camera.zoom = Vector2(1.0, 1.0)
	# Clamping camera limits to arena bounds (2560x1440)
	if arena and arena.has_method("get_arena_bounds"):
		var bounds: Rect2 = arena.get_arena_bounds()
		camera.limit_left = int(bounds.position.x)
		camera.limit_top = int(bounds.position.y)
		camera.limit_right = int(bounds.position.x + bounds.size.x)
		camera.limit_bottom = int(bounds.position.y + bounds.size.y)
	else:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = 2560
		camera.limit_bottom = 1440
		
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0

func _physics_process(_delta: float) -> void:
	if get_tree() and get_tree().paused:
		return
	if player and is_instance_valid(player) and camera:
		camera.global_position = player.global_position

func _process(delta: float) -> void:
	if get_tree() and get_tree().paused:
		return
	if _trauma > 0.0 and camera:
		_trauma = maxf(0.0, _trauma - delta * _shake_decay)
		var shake_amount := pow(_trauma, _trauma_power) * _max_shake_offset
		var raw_offset := Vector2(
			randf_range(-1.0, 1.0) * shake_amount,
			randf_range(-1.0, 1.0) * shake_amount
		)
		var bounds := Rect2(0.0, 0.0, 2560.0, 1440.0)
		if arena and arena.has_method("get_arena_bounds"):
			bounds = arena.get_arena_bounds()
		var vp_rect := get_viewport_rect()
		var zoom_val: Vector2 = camera.zoom if (camera.zoom.x > 0.0 and camera.zoom.y > 0.0) else Vector2.ONE
		var half_vp := (vp_rect.size / zoom_val) * 0.5
		var desired_pos := camera.global_position + raw_offset
		var clamped_pos := Vector2(
			clampf(desired_pos.x, bounds.position.x + half_vp.x, maxf(bounds.position.x + half_vp.x, bounds.end.x - half_vp.x)),
			clampf(desired_pos.y, bounds.position.y + half_vp.y, maxf(bounds.position.y + half_vp.y, bounds.end.y - half_vp.y))
		)
		camera.offset = clamped_pos - camera.global_position
	elif camera and camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

func _on_screen_shake_requested(trauma_intensity: float, _duration: float) -> void:
	_trauma = clampf(_trauma + trauma_intensity, 0.0, 1.0)

func _tween_camera_zoom(target_zoom: Vector2, duration: float) -> void:
	if not camera:
		return
	var tween := create_tween()
	tween.tween_property(camera, "zoom", target_zoom, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_wave_started(wave_num: int, _duration: float) -> void:
	if wave_num == 5:
		_tween_camera_zoom(Vector2(0.85, 0.85), 2.5)
	elif camera and camera.zoom != Vector2(1.0, 1.0):
		_tween_camera_zoom(Vector2(1.0, 1.0), 1.0)

func _on_boss_defeated() -> void:
	_tween_camera_zoom(Vector2(1.0, 1.0), 2.0)

func _on_hit_stop_requested(duration: float) -> void:
	if duration <= 0.0 or not is_inside_tree() or get_tree() == null:
		return
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.05
	var timer := get_tree().create_timer(duration, true, false, true)
	await timer.timeout
	Engine.time_scale = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.alt_pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER)):
			toggle_fullscreen()
			get_viewport().set_input_as_handled()
			return
			
	if event.is_action_pressed("pause"):
		# Only toggle manual pause if no modal is currently displayed
		var modal_open = (upgrade_menu and upgrade_menu.visible) or \
						 (victory_screen and victory_screen.visible) or \
						 (game_over_screen and game_over_screen.visible)
		if not modal_open:
			get_tree().paused = not get_tree().paused
			get_viewport().set_input_as_handled()

func toggle_fullscreen() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("toggle_fullscreen"):
		sm.toggle_fullscreen()
	else:
		var current_mode := DisplayServer.window_get_mode()
		var to_fullscreen: bool = (current_mode != DisplayServer.WINDOW_MODE_FULLSCREEN and current_mode != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if to_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
