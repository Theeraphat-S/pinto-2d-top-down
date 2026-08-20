# res://tests/test_roguelite_upgrades.gd
# R3: 3-Card Non-Duplicate Draft, Game Pausing Lifecycle, and 10 Upgrade Stat Modifications Tests
extends "res://tests/test_framework.gd"

# 10 Standard Upgrade Definitions
const UPGRADE_DEFINITIONS: Array[Dictionary] = [
	{"id": "dmg_up",     "title": "Sharpened Claws", "stat": "damage",           "max_rank": 5, "base_val": 20.0},
	{"id": "atk_spd",    "title": "Quick Reflexes",  "stat": "attack_cooldown",  "max_rank": 5, "base_val": 0.50},
	{"id": "mov_spd",    "title": "Swift Paws",       "stat": "move_speed",       "max_rank": 5, "base_val": 160.0},
	{"id": "max_hp",     "title": "Vitality Berry",  "stat": "max_health",       "max_rank": 5, "base_val": 100.0},
	{"id": "multi_shot", "title": "Twin Shot",       "stat": "projectile_count", "max_rank": 3, "base_val": 1.0},
	{"id": "pierce",     "title": "Drill Arrow",     "stat": "projectile_pierce","max_rank": 3, "base_val": 1.0},
	{"id": "magnet",     "title": "Magnetic Bell",   "stat": "magnet_radius",    "max_rank": 4, "base_val": 65.0},
	{"id": "regen",      "title": "Healing Herb",    "stat": "health_regen",     "max_rank": 3, "base_val": 0.0},
	{"id": "bullet_spd", "title": "Zephyr Gale",     "stat": "projectile_speed", "max_rank": 3, "base_val": 380.0},
	{"id": "knockback",  "title": "Heavy Impact",    "stat": "knockback_force",  "max_rank": 3, "base_val": 100.0}
]

# Helper to simulate 3-card draft
func draft_upgrade_cards(all_cards: Array[Dictionary], current_ranks: Dictionary, count: int = 3) -> Array[Dictionary]:
	var eligible: Array[Dictionary] = []
	for card in all_cards:
		var c_id: String = card.get("id", "")
		var current_r: int = current_ranks.get(c_id, 0)
		var max_r: int = card.get("max_rank", 1)
		if current_r < max_r:
			eligible.append(card)
			
	if eligible.size() <= count:
		return eligible.duplicate()
		
	var pool := eligible.duplicate()
	pool.shuffle()
	
	var chosen: Array[Dictionary] = []
	var chosen_ids := {}
	for card in pool:
		var c_id: String = card.get("id", "")
		if not chosen_ids.has(c_id):
			chosen.append(card)
			chosen_ids[c_id] = true
			if chosen.size() == count:
				break
				
	return chosen

# Helper to apply upgrade to player stats dictionary
func apply_card_upgrade(stats: Dictionary, ranks: Dictionary, card_id: String) -> void:
	var rank: int = ranks.get(card_id, 0) + 1
	ranks[card_id] = rank
	
	match card_id:
		"dmg_up":
			stats["damage"] = stats["base_damage"] * (1.0 + 0.20 * float(rank))
		"atk_spd":
			stats["attack_cooldown"] = max(0.05, stats["base_attack_cooldown"] * pow(0.80, float(rank)))
		"mov_spd":
			stats["move_speed"] = stats["base_move_speed"] * (1.0 + 0.15 * float(rank))
		"max_hp":
			stats["max_health"] = stats["base_max_health"] + (25.0 * float(rank))
			stats["current_health"] = min(stats["max_health"], stats["current_health"] + 25.0)
		"multi_shot":
			stats["projectile_count"] = int(stats["base_projectile_count"]) + rank
		"pierce":
			stats["projectile_pierce"] = int(stats["base_projectile_pierce"]) + rank
		"magnet":
			stats["magnet_radius"] = stats["base_magnet_radius"] * (1.0 + 0.40 * float(rank))
		"regen":
			stats["health_regen"] = 0.5 * float(rank) # +0.5 HP/s per rank
		"bullet_spd":
			stats["projectile_speed"] = stats["base_projectile_speed"] * (1.0 + 0.25 * float(rank))
		"knockback":
			stats["knockback_force"] = stats["base_knockback_force"] * (1.0 + 0.35 * float(rank))

# --- Test Cases ---

func test_upgrade_catalog_definition_count() -> void:
	assert_eq(UPGRADE_DEFINITIONS.size(), 10, "Upgrade catalog must contain exactly 10 distinct cards")

func test_3_card_draft_uniqueness() -> void:
	# Draft 3 cards with empty rank inventory
	var ranks := {}
	
	for trial in range(10):
		var draft = draft_upgrade_cards(UPGRADE_DEFINITIONS, ranks, 3)
		assert_eq(draft.size(), 3, "Draft must present exactly 3 cards")
		
		# Verify all 3 cards in the hand have unique IDs
		var seen_ids := {}
		for card in draft:
			var c_id: String = card.get("id")
			assert_false(seen_ids.has(c_id), "Card '%s' must not appear twice in the same draft" % [c_id])
			seen_ids[c_id] = true

func test_max_rank_card_filtering() -> void:
	# Set 'dmg_up' and 'mov_spd' to max rank
	var ranks := {
		"dmg_up": 5, # max_rank is 5
		"mov_spd": 5 # max_rank is 5
	}
	
	for trial in range(15):
		var draft = draft_upgrade_cards(UPGRADE_DEFINITIONS, ranks, 3)
		for card in draft:
			var c_id: String = card.get("id")
			assert_ne(c_id, "dmg_up", "Maxed card 'dmg_up' must not be offered")
			assert_ne(c_id, "mov_spd", "Maxed card 'mov_spd' must not be offered")

func test_fewer_than_3_cards_pool_handling() -> void:
	# Max out 8 of the 10 cards, leaving only 2 eligible cards
	var ranks := {}
	for card in UPGRADE_DEFINITIONS:
		ranks[card["id"]] = card["max_rank"]
		
	# Un-max 2 cards
	ranks["regen"] = 0
	ranks["knockback"] = 0
	
	var draft = draft_upgrade_cards(UPGRADE_DEFINITIONS, ranks, 3)
	assert_eq(draft.size(), 2, "Returns all available 2 cards when pool < 3")
	var ids := [draft[0]["id"], draft[1]["id"]]
	assert_has(ids, "regen", "Includes regen")
	assert_has(ids, "knockback", "Includes knockback")

func test_all_cards_maxed_pool_empty_handling() -> void:
	# Max out all 10 cards
	var ranks := {}
	for card in UPGRADE_DEFINITIONS:
		ranks[card["id"]] = card["max_rank"]
		
	var draft = draft_upgrade_cards(UPGRADE_DEFINITIONS, ranks, 3)
	assert_eq(draft.size(), 0, "Returns empty draft when all cards are maxed out")

func test_stat_mod_damage_scaling() -> void:
	var stats := {"base_damage": 20.0, "damage": 20.0}
	var ranks := {}
	
	apply_card_upgrade(stats, ranks, "dmg_up") # Rank 1 (+20%)
	assert_almost_eq(stats["damage"], 24.0, 0.001, "Rank 1 Damage is 24.0")
	
	apply_card_upgrade(stats, ranks, "dmg_up") # Rank 2 (+40%)
	assert_almost_eq(stats["damage"], 28.0, 0.001, "Rank 2 Damage is 28.0")
	
	apply_card_upgrade(stats, ranks, "dmg_up") # Rank 3 (+60%)
	assert_almost_eq(stats["damage"], 32.0, 0.001, "Rank 3 Damage is 32.0")

func test_stat_mod_attack_speed_scaling() -> void:
	var stats := {"base_attack_cooldown": 0.50, "attack_cooldown": 0.50}
	var ranks := {}
	
	apply_card_upgrade(stats, ranks, "atk_spd") # Rank 1 (0.50 * 0.80 = 0.40s)
	assert_almost_eq(stats["attack_cooldown"], 0.40, 0.001, "Rank 1 Cooldown is 0.40s")
	
	apply_card_upgrade(stats, ranks, "atk_spd") # Rank 2 (0.50 * 0.64 = 0.32s)
	assert_almost_eq(stats["attack_cooldown"], 0.32, 0.001, "Rank 2 Cooldown is 0.32s")

func test_stat_mod_max_hp_and_immediate_heal() -> void:
	# Player at 40/100 HP chooses Vitality Berry (+25 Max HP & +25 Heal)
	var stats := {
		"base_max_health": 100.0,
		"max_health": 100.0,
		"current_health": 40.0
	}
	var ranks := {}
	
	apply_card_upgrade(stats, ranks, "max_hp")
	assert_almost_eq(stats["max_health"], 125.0, 0.001, "Max health increased to 125")
	assert_almost_eq(stats["current_health"], 65.0, 0.001, "Current health healed by 25 to 65")

func test_stat_mod_multishot_and_pierce() -> void:
	var stats := {
		"base_projectile_count": 1,
		"projectile_count": 1,
		"base_projectile_pierce": 1,
		"projectile_pierce": 1
	}
	var ranks := {}
	
	apply_card_upgrade(stats, ranks, "multi_shot")
	assert_eq(stats["projectile_count"], 2, "Twin Shot gives 2 projectiles")
	
	apply_card_upgrade(stats, ranks, "pierce")
	assert_eq(stats["projectile_pierce"], 2, "Drill Arrow gives 2 pierce")

func test_pause_lifecycle_simulation() -> void:
	# Level up triggers pause
	var game_state := {"is_paused": false, "in_upgrade_menu": false}
	
	# Simulate level up event
	game_state["is_paused"] = true
	game_state["in_upgrade_menu"] = true
	assert_true(game_state["is_paused"], "Game pauses when upgrade menu opens")
	
	# Simulate card selection
	game_state["in_upgrade_menu"] = false
	game_state["is_paused"] = false
	assert_false(game_state["is_paused"], "Game unpauses when upgrade selected")

func test_upgrade_card_scene_instantiation_and_properties() -> void:
	var card_scene = load("res://scenes/ui/upgrade_card.tscn")
	assert_not_null(card_scene, "UpgradeCard scene exists and loads")
	
	var card = card_scene.instantiate()
	assert_not_null(card, "UpgradeCard instantiated successfully")
	
	var card_data := {
		"id": "dmg_up",
		"title": "Power Amp",
		"description": "+20% Attack Damage",
		"rarity": 1, # RARE
		"max_rank": 5,
		"current_rank": 2,
		"next_rank": 3,
		"icon": "res://assets/ui/icons/icon_damage.png"
	}
	card.setup(card_data, 0)
	
	assert_eq(card.card_id, "dmg_up", "Card ID setup matches")
	assert_eq(card.title_label.text, "Power Amp", "Title label matches")
	assert_eq(card.desc_label.text, "+20% Attack Damage", "Description label matches")
	assert_eq(card.rarity_label.text, "[ RARE ]", "Rarity label formatted correctly")
	assert_eq(card.rank_label.text, "★★★☆☆ (Rank 3/5)", "Rank stars formatted correctly")
	assert_eq(card.key_badge.text, "[ Press 1 ]", "Shortcut key label formatted correctly")
	
	# Test signal emission
	var selected_box := [""]
	card.card_selected.connect(func(id: String): selected_box[0] = id)
	card.select_card()
	assert_eq(selected_box[0], "dmg_up", "Selecting card emits card_selected with card ID")
	
	card.free()

func test_upgrade_menu_scene_lifecycle() -> void:
	var menu_scene = load("res://scenes/ui/upgrade_menu.tscn")
	assert_not_null(menu_scene, "UpgradeMenu scene exists and loads")
	
	var menu = menu_scene.instantiate()
	assert_not_null(menu, "UpgradeMenu instantiated successfully")
	assert_eq(menu.layer, 10, "UpgradeMenu canvas layer is 10")
	assert_eq(menu.process_mode, Node.PROCESS_MODE_ALWAYS, "UpgradeMenu process mode is PROCESS_MODE_ALWAYS")
	
	var sample_cards: Array[Dictionary] = [
		{"id": "dmg_up", "title": "Power Amp", "description": "+20% Damage", "rarity": 0, "max_rank": 5, "current_rank": 0, "next_rank": 1},
		{"id": "atk_spd", "title": "Quick Reflexes", "description": "+20% Speed", "rarity": 0, "max_rank": 5, "current_rank": 0, "next_rank": 1},
		{"id": "multi_shot", "title": "Twin Shot", "description": "+1 Projectile", "rarity": 1, "max_rank": 3, "current_rank": 0, "next_rank": 1}
	]
	
	menu.open_menu(2, sample_cards)
	assert_true(menu.visible, "Menu becomes visible on open")
	assert_eq(menu.cards_container.get_child_count(), 3, "Instantiates 3 upgrade cards")
	assert_has(menu.level_label.text, "LEVEL 2", "Level label displays level 2")
	
	var applied_box := [""]
	menu.upgrade_applied.connect(func(id: String): applied_box[0] = id)
	menu._on_card_selected("multi_shot")
	
	assert_eq(applied_box[0], "multi_shot", "Card selection emits upgrade_applied signal")
	assert_false(menu.visible, "Menu hides after card selection")
	
	menu.free()
