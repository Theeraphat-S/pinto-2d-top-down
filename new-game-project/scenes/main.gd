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

func _initialize_game() -> void:
	if get_tree():
		get_tree().paused = false
		
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.reset_run()
		
	# Place player at arena center
	if player:
		player.global_position = Vector2(640.0, 360.0)
		if camera:
			camera.global_position = player.global_position

func _configure_camera() -> void:
	if not camera:
		return
		
	camera.zoom = Vector2(1.0, 1.0)
	# Clamping camera limits to arena bounds (1280x720)
	if arena and arena.has_method("get_arena_bounds"):
		var bounds: Rect2 = arena.get_arena_bounds()
		camera.limit_left = int(bounds.position.x)
		camera.limit_top = int(bounds.position.y)
		camera.limit_right = int(bounds.position.x + bounds.size.x)
		camera.limit_bottom = int(bounds.position.y + bounds.size.y)
	else:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = 1280
		camera.limit_bottom = 720
		
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0

func _physics_process(_delta: float) -> void:
	if player and is_instance_valid(player) and camera:
		camera.global_position = player.global_position

func _process(delta: float) -> void:
	if _trauma > 0.0 and camera:
		_trauma = maxf(0.0, _trauma - delta * _shake_decay)
		var shake_amount := pow(_trauma, _trauma_power) * _max_shake_offset
		var raw_offset := Vector2(
			randf_range(-1.0, 1.0) * shake_amount,
			randf_range(-1.0, 1.0) * shake_amount
		)
		var bounds := Rect2(0.0, 0.0, 1280.0, 720.0)
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
	if event.is_action_pressed("pause"):
		# Only toggle manual pause if no modal is currently displayed
		var modal_open = (upgrade_menu and upgrade_menu.visible) or \
						 (victory_screen and victory_screen.visible) or \
						 (game_over_screen and game_over_screen.visible)
		if not modal_open:
			get_tree().paused = not get_tree().paused
			get_viewport().set_input_as_handled()
