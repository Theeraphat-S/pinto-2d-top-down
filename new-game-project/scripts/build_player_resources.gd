@tool
extends SceneTree

# Builds the SpriteFrames resource for Pinto and saves it to res://scenes/player/pinto_frames.tres

func _init() -> void:
	print("[BuildPlayerResources] Generating pinto_frames.tres...")
	var dir := ProjectSettings.globalize_path("res://scenes/player")
	DirAccess.make_dir_recursive_absolute(dir)
	
	var tex: Texture2D = load("res://assets/sprites/pinto_spritesheet.png")
	if tex == null:
		push_error("Failed to load pinto_spritesheet.png")
		quit(1)
		return
		
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
		
	var anim_defs := {
		"idle": { "rects": [Rect2(0, 0, 32, 32), Rect2(32, 0, 32, 32), Rect2(64, 0, 32, 32), Rect2(96, 0, 32, 32)], "fps": 6.0, "loop": true },
		"walk_down": { "rects": [Rect2(128, 0, 32, 32), Rect2(160, 0, 32, 32), Rect2(192, 0, 32, 32), Rect2(224, 0, 32, 32)], "fps": 8.0, "loop": true },
		"walk_up": { "rects": [Rect2(0, 32, 32, 32), Rect2(32, 32, 32, 32), Rect2(64, 32, 32, 32), Rect2(96, 32, 32, 32)], "fps": 8.0, "loop": true },
		"walk_side": { "rects": [Rect2(128, 32, 32, 32), Rect2(160, 32, 32, 32), Rect2(192, 32, 32, 32), Rect2(224, 32, 32, 32)], "fps": 8.0, "loop": true },
		"hurt": { "rects": [Rect2(0, 64, 32, 32), Rect2(32, 64, 32, 32)], "fps": 8.0, "loop": false },
		"death": { "rects": [Rect2(64, 64, 32, 32), Rect2(96, 64, 32, 32), Rect2(128, 64, 32, 32), Rect2(160, 64, 32, 32), Rect2(192, 64, 32, 32), Rect2(224, 64, 32, 32)], "fps": 6.0, "loop": false },
		"attack": { "rects": [Rect2(0, 96, 32, 32), Rect2(32, 96, 32, 32)], "fps": 10.0, "loop": false },
		"victory": { "rects": [Rect2(64, 96, 32, 32), Rect2(96, 96, 32, 32), Rect2(128, 96, 32, 32), Rect2(160, 96, 32, 32), Rect2(192, 96, 32, 32), Rect2(224, 96, 32, 32)], "fps": 8.0, "loop": true },
	}
	
	for anim_name in anim_defs.keys():
		var def: Dictionary = anim_defs[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, def["fps"])
		frames.set_animation_loop(anim_name, def["loop"])
		
		for r in def["rects"]:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = r
			frames.add_frame(anim_name, atlas)
			
	var err := ResourceSaver.save(frames, "res://scenes/player/pinto_frames.tres")
	if err != OK:
		push_error("Error saving pinto_frames.tres: " + str(err))
		quit(1)
		return
		
	print("[BuildPlayerResources] Successfully saved res://scenes/player/pinto_frames.tres")
	quit(0)
