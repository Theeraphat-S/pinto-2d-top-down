@tool
class_name Arena
extends Node2D

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - ARENA WORLD & BOUNDARIES (Milestone M3)
# 1280x720 Enclosed cyber-circuit arena with TileMapLayer, StaticBody2D boundaries,
# obstacle props, Y-sorting containers, and spatial spawn helpers.
# ==============================================================================

const ARENA_WIDTH: float = 1280.0
const ARENA_HEIGHT: float = 720.0
const BORDER_MARGIN: float = 32.0
const TILE_SIZE: int = 32
const TILE_COLS: int = 40 # 1280 / 32
const TILE_ROWS: int = 23 # ceil(720 / 32) = 23 (736px, covering 720px)

const TILESET_PATH: String = "res://assets/tilesets/arena_tileset.png"
const LAYER_WORLD: int = 1 # Collision Layer 1 (World/Obstacles)

@onready var tilemap_layer: TileMapLayer = $TileMapLayer
@onready var walls: StaticBody2D = $Walls
@onready var props: Node2D = $Props
@onready var entities: Node2D = $Entities

func _init() -> void:
	y_sort_enabled = true

func _enter_tree() -> void:
	y_sort_enabled = true
	_ensure_hierarchy()
	_setup_walls_collision()
	_setup_tilemap()

func _ready() -> void:
	y_sort_enabled = true
	_ensure_hierarchy()
	_setup_walls_collision()
	_setup_tilemap()

func _ensure_hierarchy() -> void:
	if has_node("TileMapLayer"):
		tilemap_layer = get_node("TileMapLayer")
	else:
		var tml := TileMapLayer.new()
		tml.name = "TileMapLayer"
		tml.z_index = -10
		add_child(tml)
		tilemap_layer = tml
		
	if has_node("Walls"):
		walls = get_node("Walls")
		walls.collision_layer = LAYER_WORLD
		walls.collision_mask = 0
	else:
		var w := StaticBody2D.new()
		w.name = "Walls"
		w.collision_layer = LAYER_WORLD
		w.collision_mask = 0
		add_child(w)
		walls = w
		
	if has_node("Props"):
		props = get_node("Props")
		props.y_sort_enabled = true
	else:
		var p := Node2D.new()
		p.name = "Props"
		p.y_sort_enabled = true
		add_child(p)
		props = p
		
	if has_node("Entities"):
		entities = get_node("Entities")
		entities.y_sort_enabled = true
	else:
		var e := Node2D.new()
		e.name = "Entities"
		e.y_sort_enabled = true
		add_child(e)
		entities = e

func _setup_walls_collision() -> void:
	if walls == null:
		if has_node("Walls"):
			walls = get_node("Walls")
		else:
			return
			
	walls.collision_layer = LAYER_WORLD
	walls.collision_mask = 0
	
	# If collision shapes already exist, ensure layer is set and return
	if walls.get_child_count() >= 4:
		return
		
	# Clear any old children
	for c in walls.get_children():
		c.queue_free()
		
	# Top Wall: Y <= 32 (Centered at 640, 16, size 1280x32)
	_add_wall_shape("TopWall", Vector2(ARENA_WIDTH * 0.5, BORDER_MARGIN * 0.5), Vector2(ARENA_WIDTH, BORDER_MARGIN))
	# Bottom Wall: Y >= 688 (Centered at 640, 704, size 1280x32)
	_add_wall_shape("BottomWall", Vector2(ARENA_WIDTH * 0.5, ARENA_HEIGHT - BORDER_MARGIN * 0.5), Vector2(ARENA_WIDTH, BORDER_MARGIN))
	# Left Wall: X <= 32 (Centered at 16, 360, size 32x720)
	_add_wall_shape("LeftWall", Vector2(BORDER_MARGIN * 0.5, ARENA_HEIGHT * 0.5), Vector2(BORDER_MARGIN, ARENA_HEIGHT))
	# Right Wall: X >= 1248 (Centered at 1264, 360, size 32x720)
	_add_wall_shape("RightWall", Vector2(ARENA_WIDTH - BORDER_MARGIN * 0.5, ARENA_HEIGHT * 0.5), Vector2(BORDER_MARGIN, ARENA_HEIGHT))

func _add_wall_shape(shape_name: String, center: Vector2, size: Vector2) -> void:
	var col := CollisionShape2D.new()
	col.name = shape_name
	col.position = center
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	walls.add_child(col)

func _setup_tilemap() -> void:
	if tilemap_layer == null:
		if has_node("TileMapLayer"):
			tilemap_layer = get_node("TileMapLayer")
		else:
			return
		
	if tilemap_layer.tile_set == null:
		tilemap_layer.tile_set = _create_arena_tileset()
		
	if tilemap_layer.get_used_cells().is_empty():
		_populate_arena_cells()

func _create_arena_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	var tex: Texture2D = load(TILESET_PATH)
	if tex == null:
		push_warning("[Arena] Could not load tileset texture at: " + TILESET_PATH)
		return ts
		
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# Create all 8x4 tiles in atlas
	for y in range(4):
		for x in range(8):
			source.create_tile(Vector2i(x, y))
			
	ts.add_source(source, 0)
	return ts

func _populate_arena_cells() -> void:
	if tilemap_layer == null or tilemap_layer.tile_set == null:
		return
		
	for gx in range(TILE_COLS):
		for gy in range(TILE_ROWS):
			var atlas_coord: Vector2i
			
			if gy == 0:
				# Top Wall Cap (Row 1 of atlas)
				atlas_coord = Vector2i(gx % 8, 1)
			elif gy == TILE_ROWS - 1:
				# Bottom Wall Bulkhead (Row 2 of atlas)
				atlas_coord = Vector2i(gx % 8, 2)
			elif gx == 0 or gx == TILE_COLS - 1:
				# Side Wall Bulkheads (Row 2 of atlas)
				atlas_coord = Vector2i(gy % 8, 2)
			elif gx == 1 or gx == TILE_COLS - 2 or gy == 1 or gy == TILE_ROWS - 2:
				# Border Glow / Perimeter Floor (Row 3 of atlas)
				atlas_coord = Vector2i((gx + gy) % 8, 3)
			else:
				# Interior Cyber Floor Patterns (Row 0 of atlas)
				var pattern_val := (gx * 7 + gy * 13) % 100
				if pattern_val < 60:
					atlas_coord = Vector2i(0, 0) # Slate grid
				elif pattern_val < 80:
					atlas_coord = Vector2i(1, 0) # Single circuit trace
				elif pattern_val < 92:
					atlas_coord = Vector2i(2, 0) # Dual circuit node
				else:
					atlas_coord = Vector2i(3, 0) # Caution hatch
					
			tilemap_layer.set_cell(Vector2i(gx, gy), 0, atlas_coord)

# ==============================================================================
# PUBLIC ARENA API & SPATIAL HELPERS
# ==============================================================================

func get_arena_bounds() -> Rect2:
	return Rect2(0.0, 0.0, ARENA_WIDTH, ARENA_HEIGHT)

func get_playable_bounds() -> Rect2:
	return Rect2(BORDER_MARGIN, BORDER_MARGIN, ARENA_WIDTH - 2.0 * BORDER_MARGIN, ARENA_HEIGHT - 2.0 * BORDER_MARGIN)

func clamp_to_arena(pos: Vector2, margin: float = BORDER_MARGIN) -> Vector2:
	return Vector2(
		clampf(pos.x, margin, ARENA_WIDTH - margin),
		clampf(pos.y, margin, ARENA_HEIGHT - margin)
	)

func get_random_spawn_point_outside_viewport(player_pos: Vector2, viewport_size: Vector2 = Vector2(640.0, 360.0), margin: float = 48.0) -> Vector2:
	var min_x := margin
	var max_x := ARENA_WIDTH - margin
	var min_y := margin
	var max_y := ARENA_HEIGHT - margin
	
	var half_vw := viewport_size.x * 0.5
	var half_vh := viewport_size.y * 0.5
	var vp_rect := Rect2(player_pos.x - half_vw, player_pos.y - half_vh, viewport_size.x, viewport_size.y)
	
	# Try random sampling within playable arena bounds
	for _attempt in range(30):
		var rx := randf_range(min_x, max_x)
		var ry := randf_range(min_y, max_y)
		var candidate := Vector2(rx, ry)
		if not vp_rect.has_point(candidate):
			return candidate
			
	# Fallback: Pick a perimeter location relative to player viewport
	var side := randi() % 4
	var fallback_pos := Vector2.ZERO
	match side:
		0: # Top
			fallback_pos = Vector2(randf_range(min_x, max_x), player_pos.y - half_vh - 40.0)
		1: # Bottom
			fallback_pos = Vector2(randf_range(min_x, max_x), player_pos.y + half_vh + 40.0)
		2: # Left
			fallback_pos = Vector2(player_pos.x - half_vw - 40.0, randf_range(min_y, max_y))
		3: # Right
			fallback_pos = Vector2(player_pos.x + half_vw + 40.0, randf_range(min_y, max_y))
			
	return clamp_to_arena(fallback_pos, margin)

func add_entity(entity_node: Node2D) -> void:
	_ensure_hierarchy()
	if entities != null and entity_node != null:
		entities.add_child(entity_node)

func get_entities() -> Array[Node]:
	_ensure_hierarchy()
	if entities != null:
		return entities.get_children()
	return []
