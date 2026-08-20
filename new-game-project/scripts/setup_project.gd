@tool
extends SceneTree

func _init() -> void:
	print("[SetupProject] Configuring project settings and input actions...")
	
	ProjectSettings.set_setting("application/config/name", "Pinto 2D Top-Down Survival Arena")
	
	# Autoloads
	ProjectSettings.set_setting("autoload/EventBus", "*res://autoload/event_bus.gd")
	ProjectSettings.set_setting("autoload/GameState", "*res://autoload/game_state.gd")
	ProjectSettings.set_setting("autoload/SaveManager", "*res://autoload/save_manager.gd")
	ProjectSettings.set_setting("autoload/UpgradeCatalog", "*res://autoload/upgrade_catalog.gd")
	
	# Inputs
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("move_down", [KEY_S, KEY_DOWN])
	_add_action("pause", [KEY_ESCAPE, KEY_P])
	_add_action("select", [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER])
	
	# Rendering & Display
	ProjectSettings.set_setting("display/window/size/viewport_width", 640)
	ProjectSettings.set_setting("display/window/size/viewport_height", 360)
	ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
	ProjectSettings.set_setting("display/window/stretch/aspect", "expand")
	ProjectSettings.set_setting("display/window/stretch/scale_mode", "integer")
	ProjectSettings.set_setting("rendering/textures/canvas_textures/default_texture_filter", 0)
	ProjectSettings.set_setting("rendering/2d/snap/snap_2d_transforms_to_pixel", true)
	
	var err := ProjectSettings.save()
	if err == OK:
		print("[SetupProject] Project settings saved successfully!")
	else:
		printerr("[SetupProject] Error saving project settings: ", err)
		
	quit(0)

func _add_action(action_name: String, keycodes: Array) -> void:
	var events := []
	for k in keycodes:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		events.append(ev)
	ProjectSettings.set_setting("input/" + action_name, {
		"deadzone": 0.5,
		"events": events
	})
