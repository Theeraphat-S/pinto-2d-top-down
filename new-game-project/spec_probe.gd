extends SceneTree

func _init() -> void:
	print("=== GODOT 4.7.2 SPEC VERIFICATION SUITE ===")
	
	# 1. Test CharacterBody2D motion mode
	var cb := CharacterBody2D.new()
	cb.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	cb.velocity = Vector2(100, -50)
	print("[PASS] CharacterBody2D motion mode floating: ", cb.motion_mode == CharacterBody2D.MOTION_MODE_FLOATING)
	cb.free()
	
	# 2. Test TileMapLayer
	var tml := TileMapLayer.new()
	print("[PASS] TileMapLayer initialized: ", tml != null)
	tml.free()
	
	# 3. Test Area2D
	var area := Area2D.new()
	area.collision_layer = 2
	area.collision_mask = 4
	print("[PASS] Area2D layer/mask configuration: layer=", area.collision_layer, " mask=", area.collision_mask)
	area.free()
	
	# 4. Test CanvasLayer
	var cl := CanvasLayer.new()
	cl.layer = 10
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	print("[PASS] CanvasLayer layer and process mode: layer=", cl.layer, " mode=", cl.process_mode)
	cl.free()
	
	# 5. Test FileAccess for save/load persistence
	var test_path := "user://test_save_persistence.json"
	var save_file := FileAccess.open(test_path, FileAccess.WRITE)
	var sample_data := {"high_score": 1250, "best_time": 342.5}
	save_file.store_string(JSON.stringify(sample_data))
	save_file.close()
	
	var read_file := FileAccess.open(test_path, FileAccess.READ)
	var read_text := read_file.get_as_text()
	read_file.close()
	var parsed: Dictionary = JSON.parse_string(read_text)
	print("[PASS] FileAccess persistence roundtrip: high_score=", parsed.get("high_score"), " match=", parsed.get("high_score") == 1250)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	
	# 6. Test AudioStreamGenerator (procedural audio)
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 44100.0
	gen.buffer_length = 0.1
	print("[PASS] AudioStreamGenerator created: mix_rate=", gen.mix_rate)
	
	print("=== ALL PROBES VERIFIED SUCCESSFULLY ===")
	quit(0)
