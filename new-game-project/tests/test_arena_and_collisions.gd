# res://tests/test_arena_and_collisions.gd
# R4: 1280x720 Enclosed Arena Bounds, Collision Layer Matrix, Prop Variations, and Y-Sorting Depth Origin Alignment Tests
extends "res://tests/test_framework.gd"

const PropScript = preload("res://scenes/world/prop.gd")

const ARENA_WIDTH: float = 1280.0
const ARENA_HEIGHT: float = 720.0
const BORDER_MARGIN: float = 32.0

const BOUND_MIN_X: float = 32.0
const BOUND_MAX_X: float = 1248.0 # 1280 - 32
const BOUND_MIN_Y: float = 32.0
const BOUND_MAX_Y: float = 688.0  # 720 - 32

# Collision Layer bitmasks (1-based layers in Godot)
const LAYER_WORLD: int = 1 << 0             # Layer 1
const LAYER_PLAYER: int = 1 << 1            # Layer 2
const LAYER_ENEMIES: int = 1 << 2           # Layer 3
const LAYER_PLAYER_PROJECTILES: int = 1 << 3 # Layer 4
const LAYER_ENEMY_PROJECTILES: int = 1 << 4  # Layer 5
const LAYER_PICKUPS: int = 1 << 5           # Layer 6
const LAYER_PLAYER_MAGNET: int = 1 << 6     # Layer 7
const LAYER_HURTBOXES: int = 1 << 7         # Layer 8

# Helper to clamp entity inside arena boundaries
func clamp_to_arena_bounds(pos: Vector2, margin: float = BORDER_MARGIN) -> Vector2:
	return Vector2(
		clampf(pos.x, margin, ARENA_WIDTH - margin),
		clampf(pos.y, margin, ARENA_HEIGHT - margin)
	)

# --- Test Cases ---

func test_arena_dimensions_and_bounds() -> void:
	assert_eq(ARENA_WIDTH, 1280.0, "Arena width is 1280px")
	assert_eq(ARENA_HEIGHT, 720.0, "Arena height is 720px")
	
	# Verify playable area bounds with 32px borders
	assert_almost_eq(BOUND_MIN_X, 32.0, 0.001, "Min X is 32px")
	assert_almost_eq(BOUND_MAX_X, 1248.0, 0.001, "Max X is 1248px")
	assert_almost_eq(BOUND_MIN_Y, 32.0, 0.001, "Min Y is 32px")
	assert_almost_eq(BOUND_MAX_Y, 688.0, 0.001, "Max Y is 688px")

func test_boundary_clamping_behavior() -> void:
	# Inside point remains unchanged
	var center := Vector2(640, 360)
	assert_eq(clamp_to_arena_bounds(center), center, "Center position unchanged")
	
	# Outside points are clamped to borders
	var left_out := Vector2(-50, 360)
	var right_out := Vector2(1400, 360)
	var top_out := Vector2(640, -20)
	var bottom_out := Vector2(640, 800)
	var corner_out := Vector2(-100, -100)
	
	assert_eq(clamp_to_arena_bounds(left_out), Vector2(BOUND_MIN_X, 360), "Left clamped to 32px")
	assert_eq(clamp_to_arena_bounds(right_out), Vector2(BOUND_MAX_X, 360), "Right clamped to 1248px")
	assert_eq(clamp_to_arena_bounds(top_out), Vector2(640, BOUND_MIN_Y), "Top clamped to 32px")
	assert_eq(clamp_to_arena_bounds(bottom_out), Vector2(640, BOUND_MAX_Y), "Bottom clamped to 688px")
	assert_eq(clamp_to_arena_bounds(corner_out), Vector2(BOUND_MIN_X, BOUND_MIN_Y), "Corner clamped to (32, 32)")

func test_collision_layer_matrix() -> void:
	# Check bitmask powers of 2
	assert_eq(LAYER_WORLD, 1, "World is Layer 1 (bit 0 = 1)")
	assert_eq(LAYER_PLAYER, 2, "Player is Layer 2 (bit 1 = 2)")
	assert_eq(LAYER_ENEMIES, 4, "Enemies is Layer 3 (bit 2 = 4)")
	assert_eq(LAYER_PLAYER_PROJECTILES, 8, "Player Projectiles is Layer 4 (bit 3 = 8)")
	assert_eq(LAYER_ENEMY_PROJECTILES, 16, "Enemy Projectiles is Layer 5 (bit 4 = 16)")
	assert_eq(LAYER_PICKUPS, 32, "Pickups is Layer 6 (bit 5 = 32)")
	assert_eq(LAYER_PLAYER_MAGNET, 64, "Player Magnet is Layer 7 (bit 6 = 64)")
	assert_eq(LAYER_HURTBOXES, 128, "Hurtboxes is Layer 8 (bit 7 = 128)")

func test_player_and_projectile_mask_interaction() -> void:
	# Player Projectiles must collide with Enemies (Layer 3) and World (Layer 1)
	var proj_mask: int = LAYER_ENEMIES | LAYER_WORLD
	assert_true((proj_mask & LAYER_ENEMIES) != 0, "Projectile hits Enemies")
	assert_true((proj_mask & LAYER_WORLD) != 0, "Projectile hits World walls")
	assert_false((proj_mask & LAYER_PLAYER) != 0, "Projectile ignores Player")
	
	# Magnet Area must detect Pickups (Layer 6)
	var magnet_mask: int = LAYER_PICKUPS
	assert_true((magnet_mask & LAYER_PICKUPS) != 0, "Magnet detects Pickups")
	assert_false((magnet_mask & LAYER_ENEMIES) != 0, "Magnet ignores Enemies")

func test_y_sort_depth_ordering_logic() -> void:
	# In Godot Y-sorting, entities with higher global_position.y render in front of those with lower y
	var entity_a := {"name": "Pinto_Ahead", "pos": Vector2(200, 300)}
	var entity_b := {"name": "Tree_Behind", "pos": Vector2(200, 200)}
	var entity_c := {"name": "Slime_Front", "pos": Vector2(200, 350)}
	
	var entities := [entity_a, entity_b, entity_c]
	entities.sort_custom(func(x, y): return x["pos"].y < y["pos"].y)
	
	assert_eq(entities[0]["name"], "Tree_Behind", "Tree at Y=200 renders first (behind)")
	assert_eq(entities[1]["name"], "Pinto_Ahead", "Pinto at Y=300 renders second (in front of tree)")
	assert_eq(entities[2]["name"], "Slime_Front", "Slime at Y=350 renders last (in front of Pinto)")

func test_y_sort_node_properties() -> void:
	var world_node := Node2D.new()
	world_node.y_sort_enabled = true
	assert_true(world_node.y_sort_enabled, "World Node2D has y_sort_enabled set to true")
	
	var player_node := CharacterBody2D.new()
	player_node.position = Vector2(100, 150)
	world_node.add_child(player_node)
	
	assert_eq(player_node.position.y, 150.0, "Player position set correctly in Y-sorted container")
	
	world_node.free()

func test_obstacle_static_collision_configuration() -> void:
	var obstacle := StaticBody2D.new()
	obstacle.collision_layer = LAYER_WORLD
	obstacle.collision_mask = 0
	
	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(32, 32)
	col.shape = box
	obstacle.add_child(col)
	
	assert_eq(obstacle.collision_layer, LAYER_WORLD, "Static obstacle is on World layer")
	assert_almost_eq((col.shape as RectangleShape2D).size.x, 32.0, 0.001, "Obstacle size 32x32")
	
	obstacle.free()

func test_arena_scene_instantiation_and_structure() -> void:
	var arena_scene: PackedScene = load("res://scenes/world/arena.tscn")
	assert_not_null(arena_scene, "res://scenes/world/arena.tscn loads successfully")
	
	var arena: Node2D = arena_scene.instantiate() as Node2D
	assert_not_null(arena, "Arena scene instantiated")
	assert_true(arena.y_sort_enabled, "Arena root y_sort_enabled is true")
	
	# Verify required child containers
	assert_true(arena.has_node("TileMapLayer"), "Arena contains TileMapLayer child")
	assert_true(arena.has_node("Walls"), "Arena contains Walls child")
	assert_true(arena.has_node("Props"), "Arena contains Props child")
	assert_true(arena.has_node("Entities"), "Arena contains Entities child")
	
	var props_node: Node2D = arena.get_node("Props") as Node2D
	assert_true(props_node.y_sort_enabled, "Props container has y_sort_enabled set to true")
	
	var entities_node: Node2D = arena.get_node("Entities") as Node2D
	assert_true(entities_node.y_sort_enabled, "Entities container has y_sort_enabled set to true")
	
	var walls_node: StaticBody2D = arena.get_node("Walls") as StaticBody2D
	assert_eq(walls_node.collision_layer, LAYER_WORLD, "Walls are on Layer 1 (World)")
	assert_eq(walls_node.collision_mask, 0, "Walls collision mask is 0")
	assert_true(walls_node.get_child_count() >= 4, "Walls contains 4 perimeter collision shapes")
	
	arena.free()

func test_arena_helper_methods() -> void:
	var arena_scene: PackedScene = load("res://scenes/world/arena.tscn")
	var arena = arena_scene.instantiate()
	
	# Bounds
	var bounds: Rect2 = arena.get_arena_bounds()
	assert_eq(bounds.position, Vector2.ZERO, "Arena bounds origin at (0, 0)")
	assert_eq(bounds.size, Vector2(1280.0, 720.0), "Arena bounds size is 1280x720")
	
	var playable_bounds: Rect2 = arena.get_playable_bounds()
	assert_eq(playable_bounds.position, Vector2(32.0, 32.0), "Playable bounds origin at (32, 32)")
	assert_eq(playable_bounds.size, Vector2(1216.0, 656.0), "Playable bounds size is 1216x656")
	
	# Clamping
	assert_eq(arena.clamp_to_arena(Vector2(640, 360)), Vector2(640, 360), "Center unchanged")
	assert_eq(arena.clamp_to_arena(Vector2(-50, 360)), Vector2(32, 360), "Left clamped")
	assert_eq(arena.clamp_to_arena(Vector2(1500, 360)), Vector2(1248, 360), "Right clamped")
	assert_eq(arena.clamp_to_arena(Vector2(640, -100)), Vector2(640, 32), "Top clamped")
	assert_eq(arena.clamp_to_arena(Vector2(640, 999)), Vector2(640, 688), "Bottom clamped")
	
	arena.free()

func test_arena_spawn_point_outside_viewport() -> void:
	var arena_scene: PackedScene = load("res://scenes/world/arena.tscn")
	var arena = arena_scene.instantiate()
	
	var bounds: Rect2 = arena.get_arena_bounds()
	var player_pos := Vector2(640.0, 360.0)
	var viewport_size := Vector2(640.0, 360.0)
	var vp_rect := Rect2(player_pos.x - viewport_size.x * 0.5, player_pos.y - viewport_size.y * 0.5, viewport_size.x, viewport_size.y)
	
	for i in range(25):
		var spawn_pt: Vector2 = arena.get_random_spawn_point_outside_viewport(player_pos, viewport_size, 32.0)
		assert_true(bounds.has_point(spawn_pt), "Spawn point %s is within arena bounds" % [str(spawn_pt)])
		var outside: bool = (spawn_pt.x < vp_rect.position.x or spawn_pt.x > vp_rect.end.x or spawn_pt.y < vp_rect.position.y or spawn_pt.y > vp_rect.end.y)
		assert_true(outside, "Spawn point %s is outside player viewport" % [str(spawn_pt)])
		
	arena.free()

func test_prop_scene_variations_and_collisions() -> void:
	var prop_scene: PackedScene = load("res://scenes/world/prop.tscn")
	assert_not_null(prop_scene, "res://scenes/world/prop.tscn loads successfully")
	
	var prop = prop_scene.instantiate()
	assert_not_null(prop, "Prop instantiated")
	assert_eq(prop.collision_layer, LAYER_WORLD, "Prop collision layer is Layer 1 (World)")
	assert_eq(prop.collision_mask, 0, "Prop collision mask is 0")
	assert_true(prop.y_sort_enabled, "Prop y_sort_enabled is true")
	
	# Test Server Rack (0)
	prop.set_prop_type(PropScript.PropType.SERVER_RACK)
	assert_eq(prop.sprite.region_rect, Rect2(0, 16, 32, 48), "Server rack region rect 32x48")
	var rack_shape: RectangleShape2D = prop.collision_shape.shape as RectangleShape2D
	assert_eq(rack_shape.size, Vector2(28, 14), "Server rack collision shape size")
	assert_eq(prop.collision_shape.position, Vector2(0, -7), "Server rack foot collision offset")
	
	# Test Hologram Pylon (1)
	prop.set_prop_type(PropScript.PropType.HOLOGRAM_PYLON)
	assert_eq(prop.sprite.region_rect, Rect2(36, 16, 16, 48), "Hologram pylon region rect 16x48")
	var pylon_shape: RectangleShape2D = prop.collision_shape.shape as RectangleShape2D
	assert_eq(pylon_shape.size, Vector2(14, 12), "Hologram pylon collision shape size")
	
	# Test Power Crystal (2)
	prop.set_prop_type(PropScript.PropType.POWER_CRYSTAL)
	assert_eq(prop.sprite.region_rect, Rect2(56, 32, 32, 32), "Power crystal region rect 32x32")
	var crystal_shape: RectangleShape2D = prop.collision_shape.shape as RectangleShape2D
	assert_eq(crystal_shape.size, Vector2(24, 12), "Power crystal collision shape size")
	
	# Test Terminal Console (3)
	prop.set_prop_type(PropScript.PropType.TERMINAL_CONSOLE)
	assert_eq(prop.sprite.region_rect, Rect2(92, 32, 32, 32), "Terminal console region rect 32x32")
	var term_shape: RectangleShape2D = prop.collision_shape.shape as RectangleShape2D
	assert_eq(term_shape.size, Vector2(26, 12), "Terminal console collision shape size")
	
	prop.free()

func test_arena_entity_management() -> void:
	var arena_scene: PackedScene = load("res://scenes/world/arena.tscn")
	var arena = arena_scene.instantiate()
	
	var dummy := Node2D.new()
	dummy.name = "PintoPlayer"
	arena.add_entity(dummy)
	
	var entities: Array[Node] = arena.get_entities()
	assert_true(entities.has(dummy), "Dummy player node registered in arena entities container")
	
	arena.free()
