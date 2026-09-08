# res://tests/test_modular_weapons.gd
# Milestone M9: Tests for Orbiting Plasma, Thunder Strike, and Modular Weapon Subsystems
extends "res://tests/test_framework.gd"

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")
const PLASMA_SCENE = preload("res://scenes/weapons/orbiting_plasma.tscn")
const THUNDER_SCENE = preload("res://scenes/weapons/thunder_strike.tscn")
const UpgradeCatalogScript = preload("res://autoload/upgrade_catalog.gd")
const AudioManagerScript = preload("res://autoload/audio_manager.gd")

func _get_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree

func test_orbiting_plasma_instantiation_and_ranks() -> void:
	var plasma = PLASMA_SCENE.instantiate()
	assert_not_null(plasma, "OrbitingPlasma scene instantiates")
	assert_eq(plasma.rank, 1, "Initial rank is 1")
	assert_eq(plasma.orb_count, 2, "Rank 1 has 2 orbs")
	assert_almost_eq(plasma.base_damage, 14.0, 0.01, "Rank 1 damage is 14.0")
	
	plasma.rank = 2
	assert_eq(plasma.orb_count, 3, "Rank 2 has 3 orbs")
	assert_almost_eq(plasma.base_damage, 18.0, 0.01, "Rank 2 damage is 18.0")
	
	plasma.rank = 3
	assert_eq(plasma.orb_count, 4, "Rank 3 has 4 orbs")
	assert_almost_eq(plasma.base_damage, 24.0, 0.01, "Rank 3 damage is 24.0")
	
	plasma.free()

func test_thunder_strike_instantiation_and_ranks() -> void:
	var thunder = THUNDER_SCENE.instantiate()
	assert_not_null(thunder, "ThunderStrike scene instantiates")
	assert_eq(thunder.rank, 1, "Initial rank is 1")
	assert_eq(thunder.strike_count, 1, "Rank 1 has 1 strike")
	assert_almost_eq(thunder.strike_interval, 1.8, 0.01, "Rank 1 interval is 1.8s")
	assert_almost_eq(thunder.base_damage, 35.0, 0.01, "Rank 1 damage is 35.0")
	
	thunder.rank = 2
	assert_eq(thunder.strike_count, 2, "Rank 2 has 2 strikes")
	assert_almost_eq(thunder.strike_interval, 1.5, 0.01, "Rank 2 interval is 1.5s")
	assert_almost_eq(thunder.base_damage, 48.0, 0.01, "Rank 2 damage is 48.0")
	
	thunder.rank = 3
	assert_eq(thunder.strike_count, 3, "Rank 3 has 3 strikes")
	assert_almost_eq(thunder.strike_interval, 1.2, 0.01, "Rank 3 interval is 1.2s")
	assert_almost_eq(thunder.base_damage, 65.0, 0.01, "Rank 3 damage is 65.0")
	
	thunder.free()

func test_player_weapon_equip_and_upgrade() -> void:
	var player = PLAYER_SCENE.instantiate()
	var tree := _get_tree()
	if tree:
		tree.root.add_child(player)
		
	assert_eq(player.equipped_weapons.size(), 0, "No modular weapons equipped initially")
	
	# Equip Orbiting Plasma
	var w1 = player.equip_or_upgrade_weapon("weapon_plasma")
	assert_not_null(w1, "Plasma weapon mounted")
	assert_true(player.equipped_weapons.has("weapon_plasma"), "Equipped weapons has weapon_plasma")
	assert_eq(w1.rank, 1, "Equipped weapon is rank 1")
	
	# Upgrade Orbiting Plasma to rank 2
	var w1_up = player.equip_or_upgrade_weapon("weapon_plasma")
	assert_eq(w1_up.rank, 2, "Upgraded weapon is now rank 2")
	
	# Equip Thunder Strike
	var w2 = player.equip_or_upgrade_weapon("weapon_thunder")
	assert_not_null(w2, "Thunder weapon mounted")
	assert_true(player.equipped_weapons.has("weapon_thunder"), "Equipped weapons has weapon_thunder")
	assert_eq(player.equipped_weapons.size(), 2, "Pinto holds 2 concurrent modular weapons")
	
	if player.get_parent():
		player.get_parent().remove_child(player)
	player.free()

func test_upgrade_catalog_weapon_definitions() -> void:
	var tree := _get_tree()
	var catalog: Node = null
	var should_free := false
	if tree and tree.root.has_node("UpgradeCatalog"):
		catalog = tree.root.get_node("UpgradeCatalog")
	else:
		catalog = UpgradeCatalogScript.new()
		catalog._ready()
		should_free = true
	
	var plasma_card = catalog.get_card("weapon_plasma")
	assert_not_null(plasma_card, "weapon_plasma card exists in catalog")
	assert_eq(plasma_card.get("id"), "weapon_plasma", "ID matches")
	assert_eq(plasma_card.get("max_rank"), 3, "Max rank is 3")
	
	var thunder_card = catalog.get_card("weapon_thunder")
	assert_not_null(thunder_card, "weapon_thunder card exists in catalog")
	assert_eq(thunder_card.get("id"), "weapon_thunder", "ID matches")
	assert_eq(thunder_card.get("max_rank"), 3, "Max rank is 3")
	
	if should_free and catalog:
		catalog.free()

func test_audio_manager_weapon_sfx() -> void:
	var am = AudioManagerScript.new()
	assert_not_null(am, "AudioManager instance can be created")
	assert_not_null(am.get_stream("plasma"), "Plasma hum SFX is synthesized or loaded")
	assert_not_null(am.get_stream("thunder"), "Thunder strike SFX is synthesized or loaded")
	am.free()
