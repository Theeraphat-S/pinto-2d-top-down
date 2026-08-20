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

func _ready() -> void:
	_initialize_game()
	_configure_camera()

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
		
	camera.zoom = Vector2(2.5, 2.5)
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		# Only toggle manual pause if no modal is currently displayed
		var modal_open = (upgrade_menu and upgrade_menu.visible) or \
						 (victory_screen and victory_screen.visible) or \
						 (game_over_screen and game_over_screen.visible)
		if not modal_open:
			get_tree().paused = not get_tree().paused
			get_viewport().set_input_as_handled()
