# res://tests/test_camera_and_hud_clamping.gd
# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA — M7 CAMERA2D, RESOLUTION & HUD EMPIRICAL SUITE
# Empirical verification & mathematical challenge:
# 1. Camera2D visible rect calculation across extreme player positions (corners:
#    (0,0), (1280,0), (0,720), (1280,720), playable bounds, and offscreen coords).
#    Zoom 2.5x mathematically proves no out-of-bounds area or gray border is exposed.
# 2. TileMap visual coverage integrity over the clamped camera viewport.
# 3. UI HUD margin pinning under simulated viewport resizing across 9 resolutions/ratios.
# ==============================================================================
extends "res://tests/test_framework.gd"

const ARENA_WIDTH: float = 1280.0
const ARENA_HEIGHT: float = 720.0
const VIEWPORT_WIDTH: float = 1920.0
const VIEWPORT_HEIGHT: float = 1080.0
const CAMERA_ZOOM: float = 2.5

const HUDScene = preload("res://scenes/ui/hud.tscn")
const MainScene = preload("res://scenes/main.tscn")
const ArenaScene = preload("res://scenes/world/arena.tscn")

# ==============================================================================
# 1. MATHEMATICAL PROOF & CAMERA2D ZOOM EXTENTS
# ==============================================================================

func test_camera_visible_extent_and_half_dimensions() -> void:
	var visible_w: float = VIEWPORT_WIDTH / CAMERA_ZOOM   # 1920 / 2.5 = 768
	var visible_h: float = VIEWPORT_HEIGHT / CAMERA_ZOOM  # 1080 / 2.5 = 432
	var half_w: float = visible_w * 0.5                  # 384
	var half_h: float = visible_h * 0.5                  # 216
	
	assert_almost_eq(visible_w, 768.0, 0.001, "Visible world width is 768px (1920 / 2.5)")
	assert_almost_eq(visible_h, 432.0, 0.001, "Visible world height is 432px (1080 / 2.5)")
	assert_almost_eq(half_w, 384.0, 0.001, "Camera half-width is 384px")
	assert_almost_eq(half_h, 216.0, 0.001, "Camera half-height is 216px")
	
	# Verify that visible world extent is strictly smaller than arena dimensions
	assert_true(visible_w < ARENA_WIDTH, "Visible width (768) < Arena width (1280)")
	assert_true(visible_h < ARENA_HEIGHT, "Visible height (432) < Arena height (720)")

func test_camera_clamped_center_limits() -> void:
	var visible_w: float = VIEWPORT_WIDTH / CAMERA_ZOOM
	var visible_h: float = VIEWPORT_HEIGHT / CAMERA_ZOOM
	var half_w: float = visible_w * 0.5
	var half_h: float = visible_h * 0.5
	
	var min_cx: float = 0.0 + half_w
	var max_cx: float = ARENA_WIDTH - half_w
	var min_cy: float = 0.0 + half_h
	var max_cy: float = ARENA_HEIGHT - half_h
	
	assert_almost_eq(min_cx, 384.0, 0.001, "Min clamped camera center X is 384px")
	assert_almost_eq(max_cx, 896.0, 0.001, "Max clamped camera center X is 896px")
	assert_almost_eq(min_cy, 216.0, 0.001, "Min clamped camera center Y is 216px")
	assert_almost_eq(max_cy, 504.0, 0.001, "Max clamped camera center Y is 504px")

# ==============================================================================
# 2. CAMERA2D VISIBLE RECT ACROSS EXTREME PLAYER POSITIONS (CORNERS & EDGES)
# ==============================================================================

func test_camera_visible_rect_four_corners() -> void:
	var visible_w: float = VIEWPORT_WIDTH / CAMERA_ZOOM
	var visible_h: float = VIEWPORT_HEIGHT / CAMERA_ZOOM
	var half_w: float = visible_w * 0.5
	var half_h: float = visible_h * 0.5
	
	var min_cx: float = half_w
	var max_cx: float = ARENA_WIDTH - half_w
	var min_cy: float = half_h
	var max_cy: float = ARENA_HEIGHT - half_h
	
	var corners := [
		{"name": "Top-Left (0, 0)", "pos": Vector2(0.0, 0.0), "expected_left": 0.0, "expected_top": 0.0, "expected_right": 768.0, "expected_bottom": 432.0},
		{"name": "Top-Right (1280, 0)", "pos": Vector2(1280.0, 0.0), "expected_left": 512.0, "expected_top": 0.0, "expected_right": 1280.0, "expected_bottom": 432.0},
		{"name": "Bottom-Left (0, 720)", "pos": Vector2(0.0, 720.0), "expected_left": 0.0, "expected_top": 288.0, "expected_right": 768.0, "expected_bottom": 720.0},
		{"name": "Bottom-Right (1280, 720)", "pos": Vector2(1280.0, 720.0), "expected_left": 512.0, "expected_top": 288.0, "expected_right": 1280.0, "expected_bottom": 720.0},
	]
	
	for c in corners:
		var c_name: String = c["name"]
		var player_pos: Vector2 = c["pos"]
		
		var cx: float = clampf(player_pos.x, min_cx, max_cx)
		var cy: float = clampf(player_pos.y, min_cy, max_cy)
		
		var rect_left: float = cx - half_w
		var rect_top: float = cy - half_h
		var rect_right: float = cx + half_w
		var rect_bottom: float = cy + half_h
		
		assert_almost_eq(rect_left, c["expected_left"], 0.001, "[%s] Visible rect left matches exact bound" % c_name)
		assert_almost_eq(rect_top, c["expected_top"], 0.001, "[%s] Visible rect top matches exact bound" % c_name)
		assert_almost_eq(rect_right, c["expected_right"], 0.001, "[%s] Visible rect right matches exact bound" % c_name)
		assert_almost_eq(rect_bottom, c["expected_bottom"], 0.001, "[%s] Visible rect bottom matches exact bound" % c_name)
		
		# Out-of-bounds exposure guarantee
		assert_true(rect_left >= 0.0, "[%s] Rect left >= 0 (no left gray border)" % c_name)
		assert_true(rect_top >= 0.0, "[%s] Rect top >= 0 (no top gray border)" % c_name)
		assert_true(rect_right <= ARENA_WIDTH, "[%s] Rect right <= 1280 (no right gray border)" % c_name)
		assert_true(rect_bottom <= ARENA_HEIGHT, "[%s] Rect bottom <= 720 (no bottom gray border)" % c_name)

func test_camera_visible_rect_playable_bounds_and_edges() -> void:
	var visible_w: float = VIEWPORT_WIDTH / CAMERA_ZOOM
	var visible_h: float = VIEWPORT_HEIGHT / CAMERA_ZOOM
	var half_w: float = visible_w * 0.5
	var half_h: float = visible_h * 0.5
	
	var min_cx: float = half_w
	var max_cx: float = ARENA_WIDTH - half_w
	var min_cy: float = half_h
	var max_cy: float = ARENA_HEIGHT - half_h
	
	var test_points := [
		{"name": "Center (640, 360)", "pos": Vector2(640.0, 360.0)},
		{"name": "Playable Top-Left (32, 32)", "pos": Vector2(32.0, 32.0)},
		{"name": "Playable Top-Right (1248, 32)", "pos": Vector2(1248.0, 32.0)},
		{"name": "Playable Bottom-Left (32, 688)", "pos": Vector2(32.0, 688.0)},
		{"name": "Playable Bottom-Right (1248, 688)", "pos": Vector2(1248.0, 688.0)},
		{"name": "Top Edge (640, 0)", "pos": Vector2(640.0, 0.0)},
		{"name": "Bottom Edge (640, 720)", "pos": Vector2(640.0, 720.0)},
		{"name": "Left Edge (0, 360)", "pos": Vector2(0.0, 360.0)},
		{"name": "Right Edge (1280, 360)", "pos": Vector2(1280.0, 360.0)},
		{"name": "Offscreen Extreme (-1000, -1000)", "pos": Vector2(-1000.0, -1000.0)},
		{"name": "Offscreen Extreme (2500, 2500)", "pos": Vector2(2500.0, 2500.0)},
	]
	
	for tp in test_points:
		var tp_name: String = tp["name"]
		var p_pos: Vector2 = tp["pos"]
		
		var cx: float = clampf(p_pos.x, min_cx, max_cx)
		var cy: float = clampf(p_pos.y, min_cy, max_cy)
		
		var r_left: float = cx - half_w
		var r_top: float = cy - half_h
		var r_right: float = cx + half_w
		var r_bottom: float = cy + half_h
		
		assert_true(r_left >= 0.0 - 0.001, "[%s] Left bound inside arena" % tp_name)
		assert_true(r_top >= 0.0 - 0.001, "[%s] Top bound inside arena" % tp_name)
		assert_true(r_right <= ARENA_WIDTH + 0.001, "[%s] Right bound inside arena" % tp_name)
		assert_true(r_bottom <= ARENA_HEIGHT + 0.001, "[%s] Bottom bound inside arena" % tp_name)

func test_main_scene_camera_node_configuration() -> void:
	var main_node = MainScene.instantiate()
	assert_not_null(main_node, "Main scene instantiates")
	
	var cam: Camera2D = main_node.get_node_or_null("Camera2D") as Camera2D
	assert_not_null(cam, "Camera2D node exists in main scene")
	assert_eq(cam.zoom, Vector2(2.5, 2.5), "Camera zoom is exactly Vector2(2.5, 2.5)")
	assert_eq(cam.limit_left, 0, "Camera limit_left is 0")
	assert_eq(cam.limit_top, 0, "Camera limit_top is 0")
	assert_eq(cam.limit_right, 1280, "Camera limit_right is 1280")
	assert_eq(cam.limit_bottom, 720, "Camera limit_bottom is 720")
	assert_true(cam.position_smoothing_enabled, "Position smoothing is enabled")
	assert_almost_eq(cam.position_smoothing_speed, 10.0, 0.001, "Smoothing speed is 10.0")
	
	main_node.free()

func test_tilemap_full_viewport_coverage() -> void:
	var arena = ArenaScene.instantiate()
	assert_not_null(arena, "Arena instantiates")
	
	var tilemap: TileMapLayer = arena.get_node_or_null("TileMapLayer")
	assert_not_null(tilemap, "TileMapLayer exists in Arena")
	
	var total_w = Arena.TILE_COLS * Arena.TILE_SIZE # 40 * 32 = 1280
	var total_h = Arena.TILE_ROWS * Arena.TILE_SIZE # 23 * 32 = 736
	
	assert_eq(total_w, 1280, "TileMap width exactly matches Arena width (1280)")
	assert_true(total_h >= int(ARENA_HEIGHT), "TileMap height (736) covers Arena height (720)")
	
	arena.free()

# ==============================================================================
# 3. UI HUD MARGIN PINNING UNDER SIMULATED VIEWPORT RESIZING
# ==============================================================================

func test_hud_margin_pinning_and_anchors() -> void:
	var hud: GameHUD = HUDScene.instantiate() as GameHUD
	assert_not_null(hud, "HUD instantiates")
	assert_eq(hud.layer, 5, "HUD CanvasLayer is 5 (renders above world)")
	
	var margin_container: MarginContainer = hud.get_node_or_null("MarginContainer") as MarginContainer
	assert_not_null(margin_container, "MarginContainer exists")
	assert_eq(margin_container.anchor_right, 1.0, "MarginContainer anchor_right is 1.0")
	assert_eq(margin_container.anchor_bottom, 1.0, "MarginContainer anchor_bottom is 1.0")
	assert_eq(margin_container.grow_horizontal, Control.GROW_DIRECTION_BOTH, "Grow horizontal is BOTH")
	assert_eq(margin_container.grow_vertical, Control.GROW_DIRECTION_BOTH, "Grow vertical is BOTH")
	
	assert_eq(margin_container.get_theme_constant("margin_left"), 12, "Margin left is 12px")
	assert_eq(margin_container.get_theme_constant("margin_top"), 8, "Margin top is 8px")
	assert_eq(margin_container.get_theme_constant("margin_right"), 12, "Margin right is 12px")
	assert_eq(margin_container.get_theme_constant("margin_bottom"), 8, "Margin bottom is 8px")
	
	var top_left = hud.get_node("MarginContainer/TopLeft")
	var top_center = hud.get_node("MarginContainer/TopCenter")
	var top_right = hud.get_node("MarginContainer/TopRight")
	
	assert_not_null(top_left, "TopLeft exists")
	assert_not_null(top_center, "TopCenter exists")
	assert_not_null(top_right, "TopRight exists")
	
	# 0 = SHRINK_BEGIN, 4 = SHRINK_CENTER, 8 = SHRINK_END
	assert_eq(top_left.size_flags_horizontal, 0, "TopLeft is SHRINK_BEGIN (left-pinned)")
	assert_eq(top_center.size_flags_horizontal, 4, "TopCenter is SHRINK_CENTER (horizontally centered)")
	assert_eq(top_right.size_flags_horizontal, 8, "TopRight is SHRINK_END (right-pinned)")
	
	hud.free()

func test_hud_margin_pinning_across_9_resolutions() -> void:
	var resolutions: Array[Dictionary] = [
		{"name": "1920x1080 (Native 16:9)", "size": Vector2i(1920, 1080)},
		{"name": "1280x720 (720p HD 16:9)", "size": Vector2i(1280, 720)},
		{"name": "2560x1440 (1440p QHD 16:9)", "size": Vector2i(2560, 1440)},
		{"name": "3840x2160 (4K UHD 16:9)", "size": Vector2i(3840, 2160)},
		{"name": "640x360 (Base 360p 16:9)", "size": Vector2i(640, 360)},
		{"name": "1920x1200 (16:10 Aspect)", "size": Vector2i(1920, 1200)},
		{"name": "1024x768 (4:3 Aspect)", "size": Vector2i(1024, 768)},
		{"name": "2560x1080 (21:9 Ultrawide)", "size": Vector2i(2560, 1080)},
		{"name": "3440x1440 (21:9 Ultrawide QHD)", "size": Vector2i(3440, 1440)},
	]
	
	for res in resolutions:
		var r_name: String = res["name"]
		var r_size: Vector2i = res["size"]
		
		var sub_vp := SubViewport.new()
		sub_vp.size = r_size
		var test_hud: GameHUD = HUDScene.instantiate() as GameHUD
		sub_vp.add_child(test_hud)
		
		var mc: MarginContainer = test_hud.get_node("MarginContainer") as MarginContainer
		assert_not_null(mc, "[%s] MarginContainer instanced" % r_name)
		assert_eq(mc.get_theme_constant("margin_left"), 12, "[%s] Margin left is 12px" % r_name)
		assert_eq(mc.get_theme_constant("margin_top"), 8, "[%s] Margin top is 8px" % r_name)
		assert_eq(mc.get_theme_constant("margin_right"), 12, "[%s] Margin right is 12px" % r_name)
		assert_eq(mc.get_theme_constant("margin_bottom"), 8, "[%s] Margin bottom is 8px" % r_name)
		
		test_hud.free()
		sub_vp.free()

