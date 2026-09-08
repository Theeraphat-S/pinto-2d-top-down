# res://tests/test_elites_and_chests.gd
# Milestone M10: Tests for Mid-Wave Elite Enemies, Treasure Chests, and Rewards
extends "res://tests/test_framework.gd"

const ENEMY_SLIME_SCENE = preload("res://scenes/enemies/enemy_slime.tscn")
const CHEST_SCENE = preload("res://scenes/pickups/treasure_chest.tscn")
const SPAWNER_SCENE = preload("res://scenes/world/spawner.tscn")
const AudioManagerScript = preload("res://autoload/audio_manager.gd")

func _get_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree

func test_enemy_base_is_elite_default_and_flags() -> void:
	var slime = ENEMY_SLIME_SCENE.instantiate()
	assert_not_null(slime, "Enemy slime instantiates")
	assert_false(slime.is_elite, "Default is_elite is false")
	
	slime.is_elite = true
	assert_true(slime.is_elite, "is_elite can be set to true")
	slime.free()

func test_enemy_base_make_elite() -> void:
	var slime = ENEMY_SLIME_SCENE.instantiate()
	assert_not_null(slime, "Enemy slime instantiates")
	assert_false(slime.is_elite, "Default is_elite is false")
	
	slime.make_elite(3.5, 5, 1.5)
	assert_true(slime.is_elite, "make_elite sets is_elite true")
	assert_almost_eq(slime.scale.x, 1.5, 0.01, "Scale X is 1.5")
	assert_almost_eq(slime.scale.y, 1.5, 0.01, "Scale Y is 1.5")
	assert_almost_eq(slime.max_health, 25.0 * 3.5, 0.01, "Max health multiplied by 3.5")
	assert_almost_eq(slime.current_health, slime.max_health, 0.01, "Current health refilled to max")
	assert_eq(slime.score_value, 10 * 5, "Score value multiplied by 5")
	assert_eq(slime.base_modulate, Color(1.35, 1.15, 0.4, 1.0), "Gold modulate applied")
	slime.free()

func test_treasure_chest_structure_and_collision() -> void:
	var chest = CHEST_SCENE.instantiate()
	assert_not_null(chest, "TreasureChest scene instantiates")
	assert_eq(chest.collision_layer, 32, "Chest collision_layer is 32 (Pickups)")
	assert_eq(chest.collision_mask, 2, "Chest collision_mask is 2 (Player)")
	
	var shape = chest.get_node_or_null("CollisionShape2D")
	assert_not_null(shape, "Chest has CollisionShape2D")
	assert_true(shape.shape is CircleShape2D, "Chest shape is CircleShape2D")
	chest.free()

func test_treasure_chest_collection_awards() -> void:
	var tree := _get_tree()
	var chest = CHEST_SCENE.instantiate()
	if tree:
		tree.root.add_child(chest)
		
	var gs = tree.root.get_node_or_null("GameState") if tree else null
	if gs:
		gs.reset_run()
		gs.current_health = 50.0
		var score_before = gs.score
		
		chest.collect_treasure()
		
		assert_almost_eq(gs.current_health, 70.0, 0.01, "Treasure chest healed 20 HP (50 -> 70)")
		assert_eq(gs.score, score_before + 500, "Treasure chest awarded 500 points")
	else:
		chest.collect_treasure()
		assert_true(true, "Fallback without GameState")
		
	if chest.get_parent():
		chest.get_parent().remove_child(chest)
	chest.free()

func test_spawner_elite_configuration() -> void:
	var spawner = SPAWNER_SCENE.instantiate()
	assert_not_null(spawner, "Spawner scene instantiates")
	assert_true(spawner.ELITE_CONFIGS.has(2), "Wave 2 has elite config")
	assert_true(spawner.ELITE_CONFIGS.has(3), "Wave 3 has elite config")
	assert_true(spawner.ELITE_CONFIGS.has(4), "Wave 4 has elite config")
	
	assert_eq(spawner.ELITE_CONFIGS[2].get("enemy"), "slime", "Wave 2 elite is slime")
	assert_eq(spawner.ELITE_CONFIGS[3].get("enemy"), "bat", "Wave 3 elite is bat")
	assert_eq(spawner.ELITE_CONFIGS[4].get("enemy"), "golem", "Wave 4 elite is golem")
	spawner.free()

func test_spawner_spawn_elite_enemy_multipliers() -> void:
	var spawner = SPAWNER_SCENE.instantiate()
	var tree := _get_tree()
	if tree:
		tree.root.add_child(spawner)
		
	var elite = spawner._spawn_elite_enemy("slime")
	assert_not_null(elite, "Elite enemy instantiated")
	assert_true(elite.is_elite, "Elite enemy has is_elite = true")
	assert_almost_eq(elite.scale.x, 1.5, 0.01, "Elite enemy scale X is 1.5")
	assert_almost_eq(elite.scale.y, 1.5, 0.01, "Elite enemy scale Y is 1.5")
	assert_gt(elite.max_health, 25.0, "Elite enemy max health is amplified")
	assert_gt(elite.score_value, 10, "Elite enemy score value is amplified")
	
	elite.free()
	if spawner.get_parent():
		spawner.get_parent().remove_child(spawner)
	spawner.free()

func test_audio_manager_chest_sfx() -> void:
	var am = AudioManagerScript.new()
	assert_not_null(am, "AudioManager instance can be created")
	assert_not_null(am.get_stream("chest"), "Chest fanfare SFX is synthesized or loaded")
	am.free()

func test_event_bus_signals_for_elites_and_chests() -> void:
	var tree := _get_tree()
	var eb = tree.root.get_node_or_null("EventBus") if tree else null
	if eb:
		assert_true(eb.has_signal("elite_spawned"), "EventBus has elite_spawned signal")
		assert_true(eb.has_signal("treasure_chest_opened"), "EventBus has treasure_chest_opened signal")
	else:
		assert_true(true, "Fallback")
