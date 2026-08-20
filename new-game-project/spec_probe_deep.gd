extends SceneTree

# Deep probe script for Godot 4.7.2 Environment and 2D Systems

func _init() -> void:
	print("--- BEGIN DEEP SPEC PROBE ---")
	
	# Probe 1: Engine Details
	var version_info = Engine.get_version_info()
	print("[PROBE 1] Engine Version: ", version_info.string, " (Major: ", version_info.major, ", Minor: ", version_info.minor, ", Patch: ", version_info.patch, ", Status: ", version_info.status, ")")
	
	# Probe 2: InputMap dynamic action registration
	if not InputMap.has_action("move_left"):
		InputMap.add_action("move_left")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_A
		InputMap.action_add_event("move_left", ev)
	if not InputMap.has_action("move_right"):
		InputMap.add_action("move_right")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_D
		InputMap.action_add_event("move_right", ev)
	if not InputMap.has_action("move_up"):
		InputMap.add_action("move_up")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_W
		InputMap.action_add_event("move_up", ev)
	if not InputMap.has_action("move_down"):
		InputMap.add_action("move_down")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_S
		InputMap.action_add_event("move_down", ev)
	print("[PROBE 2] InputMap actions registered: ", InputMap.has_action("move_left"), InputMap.has_action("move_right"), InputMap.has_action("move_up"), InputMap.has_action("move_down"))

	# Probe 3: CharacterBody2D floating top-down physics
	var player_body := CharacterBody2D.new()
	player_body.name = "PintoPlayer"
	player_body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	player_body.position = Vector2(100, 100)
	player_body.velocity = Vector2(150, -150)
	var col_shape := CollisionShape2D.new()
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = 12.0
	col_shape.shape = circle_shape
	player_body.add_child(col_shape)
	root.add_child(player_body)
	print("[PROBE 3] CharacterBody2D added to root. Position=", player_body.position, " Velocity=", player_body.velocity, " MotionMode=", player_body.motion_mode)

	# Probe 4: TileMapLayer vs TileMap
	var tml := TileMapLayer.new()
	tml.name = "ArenaBackground"
	tml.y_sort_enabled = true
	tml.tile_set = TileSet.new()
	tml.tile_set.tile_size = Vector2i(16, 16)
	root.add_child(tml)
	print("[PROBE 4] TileMapLayer created: tile_size=", tml.tile_set.tile_size, " y_sort=", tml.y_sort_enabled)

	# Probe 5: Area2D Triggers & Layers
	var hitbox := Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 1 << 0 # Layer 1: Player
	hitbox.collision_mask = 1 << 1  # Layer 2: Enemy
	hitbox.monitoring = true
	hitbox.monitorable = true
	var hurt_shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(24, 24)
	hurt_shape.shape = rect_shape
	hitbox.add_child(hurt_shape)
	root.add_child(hitbox)
	print("[PROBE 5] Area2D configured: layer=", hitbox.collision_layer, " mask=", hitbox.collision_mask, " monitoring=", hitbox.monitoring)

	# Probe 6: Pause handling & CanvasLayer
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HUDLayer"
	hud_layer.layer = 1
	var upgrade_layer := CanvasLayer.new()
	upgrade_layer.name = "UpgradeCardPopup"
	upgrade_layer.layer = 10
	upgrade_layer.process_mode = Node.PROCESS_MODE_ALWAYS # Keeps working while paused
	
	var label := Label.new()
	label.text = "Wave 1 - HP: 100/100 - Level: 1"
	hud_layer.add_child(label)
	
	var btn := Button.new()
	btn.text = "Upgrade: Attack Speed +20%"
	upgrade_layer.add_child(btn)
	
	root.add_child(hud_layer)
	root.add_child(upgrade_layer)
	print("[PROBE 6] CanvasLayers configured. HUD layer=", hud_layer.layer, " Upgrade layer=", upgrade_layer.layer, " Upgrade process_mode=", upgrade_layer.process_mode)

	# Probe 7: Audio synthesis capabilities
	var audio_player := AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.05
	audio_player.stream = generator
	root.add_child(audio_player)
	print("[PROBE 7] AudioStreamGenerator created with mix_rate=", generator.mix_rate, " buffer_length=", generator.buffer_length)

	# Probe 8: Roguelite Stat / Level Formula Calculations
	var xp_for_level = func(lvl: int) -> int:
		return int(10 + pow(lvl - 1, 1.5) * 15)
	
	var xp_table := []
	for lvl in range(1, 11):
		xp_table.append("Lvl %d: %d XP" % [lvl, xp_for_level.call(lvl)])
	print("[PROBE 8] Roguelite XP Threshold Curve sample: ", ", ".join(PackedStringArray(xp_table)))

	# Probe 9: Persistence (High Score & Best Time)
	var save_file_path := "user://test_pinto_save.json"
	var global_save_path := ProjectSettings.globalize_path(save_file_path)
	var test_data := {
		"high_score": 4500,
		"best_survival_time": 420.75,
		"waves_cleared": 5,
		"upgrades_unlocked": ["atk_speed_1", "multishot_1", "bullet_pierce_1"]
	}
	var f := FileAccess.open(save_file_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(test_data, "\t"))
		f.close()
		
		var f_read := FileAccess.open(save_file_path, FileAccess.READ)
		var content := f_read.get_as_text()
		f_read.close()
		var parsed_dict = JSON.parse_string(content)
		print("[PROBE 9] Persistence save/load roundtrip OK. High score=", parsed_dict.get("high_score"), " Best time=", parsed_dict.get("best_survival_time"), " Upgrades=", parsed_dict.get("upgrades_unlocked"))
		DirAccess.remove_absolute(global_save_path)
	else:
		printerr("[PROBE 9 FAIL] Could not open save file at ", save_file_path)

	# Clean up nodes
	player_body.free()
	tml.free()
	hitbox.free()
	hud_layer.free()
	upgrade_layer.free()
	audio_player.free()

	print("--- ALL DEEP PROBES COMPLETED SUCCESSFULLY ---")
	quit(0)
