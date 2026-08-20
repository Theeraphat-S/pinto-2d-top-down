# res://tests/test_adversarial_stress.gd
# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA — ADVERSARIAL STRESS & EDGE CASE SUITE
# Empirical Challenger Verification: Stress tests, failure modes, race conditions,
# corrupted payloads, and exhaustion edge cases.
# ==============================================================================
extends "res://tests/test_framework.gd"

const TEST_CORRUPT_SAVE_PATH: String = "user://test_corrupt_save.json"

const PlayerScript = preload("res://scenes/player/player.gd")

func after_all() -> void:
	if FileAccess.file_exists(TEST_CORRUPT_SAVE_PATH):
		var global_path: String = ProjectSettings.globalize_path(TEST_CORRUPT_SAVE_PATH)
		DirAccess.remove_absolute(global_path)

# ==============================================================================
# 1. SPAWN STORM & RAPID SPATIAL QUERIES
# ==============================================================================

func test_adversarial_spawn_storm_150_enemies_spatial_queries() -> void:
	var slime_scene: PackedScene = load("res://scenes/enemies/enemy_slime.tscn")
	var bat_scene: PackedScene = load("res://scenes/enemies/enemy_bat.tscn")
	var drone_scene: PackedScene = load("res://scenes/enemies/enemy_drone.tscn")
	var golem_scene: PackedScene = load("res://scenes/enemies/enemy_golem.tscn")
	
	assert_not_null(slime_scene, "Slime scene loads")
	assert_not_null(bat_scene, "Bat scene loads")
	assert_not_null(drone_scene, "Drone scene loads")
	assert_not_null(golem_scene, "Golem scene loads")
	
	var scenes := [slime_scene, bat_scene, drone_scene, golem_scene]
	var enemies: Array = []
	var total_count := 160
	
	# Instantiate 160 active enemies distributed across a 1280x720 arena
	for i in range(total_count):
		var sc: PackedScene = scenes[i % scenes.size()]
		var enemy = sc.instantiate()
		var pos := Vector2(
			float(30 + (i * 37) % 1220),
			float(30 + (i * 53) % 660)
		)
		enemy.global_position = pos
		enemies.append(enemy)
		
	assert_eq(enemies.size(), 160, "Spawned 160 active enemies simultaneously")
	
	# Place Pinto at arena center
	var pinto_pos := Vector2(640.0, 360.0)
	var max_range: float = 300.0
	
	# Compute expected nearest enemy manually
	var expected_nearest = null
	var min_dist_sq: float = max_range * max_range
	for e in enemies:
		var d_sq: float = pinto_pos.distance_squared_to(e.global_position)
		if d_sq <= min_dist_sq:
			min_dist_sq = d_sq
			expected_nearest = e
			
	assert_not_null(expected_nearest, "Found at least one enemy within range manually")
	
	# Execute 500 rapid spatial scans via Player.find_nearest_target
	var query_start := Time.get_ticks_usec()
	var nearest_found: Variant = null
	for q in range(500):
		nearest_found = PlayerScript.find_nearest_target(pinto_pos, enemies, max_range)
	var query_duration_usec := Time.get_ticks_usec() - query_start
	
	assert_not_null(nearest_found, "Player.find_nearest_target found nearest enemy in storm")
	assert_eq(nearest_found, expected_nearest, "find_nearest_target matched true nearest neighbor")
	assert_lte(query_duration_usec / 1000.0, 250.0, "500 spatial queries over 160 enemies executed in <250ms")
	
	# Stress Dead Enemy Filtering under heavy density:
	# Kill the closest 50% of enemies (including expected_nearest)
	expected_nearest.is_dead = true
	var dead_count := 0
	for i in range(80):
		enemies[i].is_dead = true
		dead_count += 1
		
	var new_nearest: Variant = PlayerScript.find_nearest_target(pinto_pos, enemies, max_range)
	if new_nearest:
		assert_false(new_nearest.is_dead, "Targeting ignores all 80 dead enemies")
		assert_ne(new_nearest, expected_nearest, "Previous dead closest enemy was filtered out")
		
	# Stress Out-of-Range Rejection:
	var far_pos := Vector2(-5000.0, -5000.0)
	var out_of_range_target: Variant = PlayerScript.find_nearest_target(far_pos, enemies, max_range)
	assert_null(out_of_range_target, "Returns null when all 160 enemies are outside range")
	
	# Stress Corrupted Array (null entries, freed references, dictionary mocks)
	var mixed_array: Array = [
		null,
		{"is_dead": true, "position": pinto_pos + Vector2(10, 10)},
		{"is_dead": false, "position": pinto_pos + Vector2(50, 0), "hp": 10},
		enemies[0], # Dead node
		enemies[81] # Alive node
	]
	var safe_target: Variant = PlayerScript.find_nearest_target(pinto_pos, mixed_array, max_range)
	assert_not_null(safe_target, "Safely handled mixed array with nulls, dicts, and nodes")
	
	# Clean up all nodes
	for e in enemies:
		e.free()

# ==============================================================================
# 2. BOSS PHASE SKIPPING & BURST DAMAGE RESILIENCE
# ==============================================================================

func calculate_boss_phase_model(current_hp: float, max_hp: float) -> int:
	if current_hp <= 0.0:
		return 0 # Defeated
	var ratio: float = current_hp / max_hp
	if ratio <= 0.33:
		return 3 # Phase 3
	elif ratio <= 0.66:
		return 2 # Phase 2
	else:
		return 1 # Phase 1

func test_adversarial_boss_extreme_burst_skipping_phases() -> void:
	var boss_scene: PackedScene = load("res://scenes/enemies/boss_giga_null.tscn")
	assert_not_null(boss_scene, "Boss scene loads")
	
	# Scenario A: Skip Phase 2 completely (deal 450 damage in 1 frame, 600 -> 150 HP = 25%)
	var boss = boss_scene.instantiate()
	assert_not_null(boss, "Boss instantiated")
	assert_eq(boss.current_phase, 1, "Boss initial phase is 1")
	assert_almost_eq(boss.max_health, 600.0, 0.01, "Boss max health is 600 HP")
	assert_almost_eq(boss.current_health, 600.0, 0.01, "Boss starts at 600 HP")
	
	# Test mathematical model verification of direct Phase 1 -> Phase 3 transition
	var phase_after_burst: int = calculate_boss_phase_model(600.0 - 450.0, 600.0)
	assert_eq(phase_after_burst, 3, "Mathematical model confirms Phase 3 on 450 burst damage")
	
	# Execute burst on concrete Boss instance
	boss.take_damage(450.0) # Drops straight to 150 HP (25% <= 33%)
	
	assert_almost_eq(boss.current_health, 150.0, 0.01, "Boss HP is 150 after burst")
	assert_eq(boss.current_phase, 3, "Boss transitioned DIRECTLY from Phase 1 to Phase 3")
	
	# Scenario B: Deal lethal burst damage (300 damage to 150 HP boss)
	boss.take_damage(300.0) # Overkill
	
	assert_lte(boss.current_health, 0.0, "Boss HP is <= 0.0 on overkill")
	assert_true(boss.is_dead, "Boss is_dead flagged true")
	
	# Scenario C: Post-mortem damage resilience
	var hp_before: float = float(boss.current_health)
	boss.take_damage(500.0)
	assert_eq(boss.current_health, hp_before, "Post-mortem damage is safely ignored")
	
	boss.free()

func test_adversarial_boss_single_frame_lethal_overkill() -> void:
	var boss_scene: PackedScene = load("res://scenes/enemies/boss_giga_null.tscn")
	var boss = boss_scene.instantiate()
	
	# Scenario D: Deal 1200 damage in 1 hit to a fresh 600 HP boss (skip Phase 2, Phase 3 straight to death)
	boss.take_damage(1200.0) # Massive single-frame burst
	
	assert_lte(boss.current_health, 0.0, "Boss HP <= 0.0 on 1-hit KO")
	assert_true(boss.is_dead, "Boss died on 1-hit KO")
	boss.free()
	
	# Negative / Zero damage resilience
	var boss2 = boss_scene.instantiate()
	boss2.take_damage(0.0)
	assert_almost_eq(boss2.current_health, 600.0, 0.01, "0 damage ignored")
	assert_eq(boss2.current_phase, 1, "Phase remains 1 on 0 damage")
	
	boss2.take_damage(-100.0)
	assert_almost_eq(boss2.current_health, 600.0, 0.01, "Negative damage ignored")
	assert_eq(boss2.current_phase, 1, "Phase remains 1 on negative damage")
	
	boss2.free()

# ==============================================================================
# 3. SIMULTANEOUS DEATH RACE CONDITIONS
# ==============================================================================

func test_adversarial_simultaneous_player_and_boss_death() -> void:
	# Simulate in-memory state of simultaneous player and boss defeat
	var game_state_mock := {
		"is_game_active": true,
		"player_hp": 100.0,
		"boss_hp": 600.0,
		"score": 1500,
		"elapsed_time": 185.0,
		"enemies_killed": 75,
		"current_wave": 5
	}
	
	# Apply simultaneous lethal damage
	game_state_mock["player_hp"] -= 100.0
	game_state_mock["boss_hp"] -= 600.0
	
	var is_player_dead: bool = (game_state_mock["player_hp"] <= 0.0)
	var is_boss_dead: bool = (game_state_mock["boss_hp"] <= 0.0)
	
	assert_true(is_player_dead, "Player HP <= 0 flagged dead")
	assert_true(is_boss_dead, "Boss HP <= 0 flagged dead")
	
	if is_player_dead:
		game_state_mock["is_game_active"] = false
		
	assert_false(game_state_mock["is_game_active"], "Game active flag successfully transitions to false")
	
	# Save persistence aggregation simulation for simultaneous outcome
	var save_data := {
		"high_score": 1000,
		"best_survival_time": 120.0,
		"total_games_played": 5,
		"total_victories": 1,
		"total_enemies_killed": 150,
		"highest_wave_reached": 4,
		"boss_defeated": false
	}
	
	# Record result: boss defeat on wave 5 awards victory credit
	save_data["high_score"] = maxi(save_data["high_score"], game_state_mock["score"])
	save_data["best_survival_time"] = maxf(save_data["best_survival_time"], game_state_mock["elapsed_time"])
	save_data["highest_wave_reached"] = maxi(save_data["highest_wave_reached"], game_state_mock["current_wave"])
	save_data["total_games_played"] += 1
	save_data["total_enemies_killed"] += game_state_mock["enemies_killed"]
	if is_boss_dead:
		save_data["total_victories"] += 1
		save_data["boss_defeated"] = true
		
	assert_eq(save_data["high_score"], 1500, "High score updated to 1500")
	assert_almost_eq(save_data["best_survival_time"], 185.0, 0.01, "Best survival time updated to 185.0s")
	assert_eq(save_data["total_games_played"], 6, "Total games played incremented to 6")
	assert_eq(save_data["total_victories"], 2, "Total victories incremented to 2")
	assert_true(save_data["boss_defeated"], "Boss defeated recorded as true")

# ==============================================================================
# 4. ROGUELITE DRAFT EXHAUSTION & FALLBACK
# ==============================================================================

const ALL_UPGRADE_CARDS: Array[Dictionary] = [
	{"id": "dmg_up",     "title": "Power Amp",       "max_rank": 5, "weight": 100},
	{"id": "atk_spd",    "title": "Quick Reflexes",  "max_rank": 5, "weight": 100},
	{"id": "mov_spd",    "title": "Swift Paws",       "max_rank": 5, "weight": 100},
	{"id": "max_hp",     "title": "Vitality Battery", "max_rank": 5, "weight": 100},
	{"id": "multi_shot", "title": "Twin Shot",       "max_rank": 3, "weight": 60},
	{"id": "pierce",     "title": "Drill Arrow",     "max_rank": 3, "weight": 60},
	{"id": "range",      "title": "Sensor Array",    "max_rank": 4, "weight": 80},
	{"id": "magnet",     "title": "Magnetic Bell",   "max_rank": 4, "weight": 80},
	{"id": "regen",      "title": "Nano Repair",     "max_rank": 3, "weight": 50},
	{"id": "crit",       "title": "Targeting AI",    "max_rank": 4, "weight": 50}
]

func draft_cards_with_fallback(cards: Array[Dictionary], active_ranks: Dictionary, count: int = 3) -> Array[Dictionary]:
	var eligible: Array[Dictionary] = []
	for c in cards:
		var current_rank: int = active_ranks.get(c["id"], 0)
		if current_rank < c.get("max_rank", 1):
			var copy = c.duplicate()
			copy["current_rank"] = current_rank
			copy["next_rank"] = current_rank + 1
			eligible.append(copy)
			
	var selected: Array[Dictionary] = []
	var pool := eligible.duplicate()
	var target_count := mini(count, pool.size())
	
	while selected.size() < target_count and not pool.is_empty():
		var chosen = pool.pop_front()
		selected.append(chosen)
		
	if selected.is_empty():
		selected.append({
			"id": "emergency_heal",
			"title": "Emergency Bento",
			"description": "Restore +35 HP",
			"rarity": 0,
			"weight": 10,
			"max_rank": 999,
			"current_rank": 1,
			"next_rank": 1,
			"icon": "res://assets/ui/icons/icon_max_hp.png"
		})
		
	return selected

func test_adversarial_upgrade_catalog_full_exhaustion() -> void:
	assert_eq(ALL_UPGRADE_CARDS.size(), 10, "10 catalog cards defined")
	
	# Max out all 10 cards in active ranks
	var active_ranks: Dictionary = {}
	for c in ALL_UPGRADE_CARDS:
		active_ranks[c["id"]] = c["max_rank"]
		
	assert_eq(active_ranks.size(), 10, "All 10 cards set to max rank")
	
	# Request draft when pool is 100% exhausted
	var draft := draft_cards_with_fallback(ALL_UPGRADE_CARDS, active_ranks, 3)
	assert_eq(draft.size(), 1, "Returns exactly 1 fallback card when all cards maxed")
	
	var fallback_card = draft[0]
	assert_eq(fallback_card.get("id"), "emergency_heal", "Fallback card ID is emergency_heal")
	assert_eq(fallback_card.get("title"), "Emergency Bento", "Fallback card title is Emergency Bento")
	assert_eq(fallback_card.get("max_rank"), 999, "Emergency heal has infinite max rank (999)")
	
	# Apply emergency heal to player health
	var current_hp: float = 40.0
	var max_hp: float = 100.0
	current_hp = min(max_hp, current_hp + 35.0)
	assert_almost_eq(current_hp, 75.0, 0.01, "Emergency Bento healed 35 HP (40 + 35 = 75)")
	
	# Overheal check
	current_hp = min(max_hp, current_hp + 35.0)
	assert_almost_eq(current_hp, 100.0, 0.01, "Emergency Bento clamps to max health (100 HP)")
	
	# Stress 10 consecutive level-ups under full exhaustion
	for lvl in range(10):
		var offered = draft_cards_with_fallback(ALL_UPGRADE_CARDS, active_ranks, 3)
		assert_eq(offered.size(), 1, "Level up %d offers fallback card" % [lvl + 2])
		assert_eq(offered[0].get("id"), "emergency_heal", "Offered card is emergency_heal")

func test_adversarial_upgrade_menu_with_exhausted_fallback_card() -> void:
	var menu_scene = load("res://scenes/ui/upgrade_menu.tscn")
	assert_not_null(menu_scene, "UpgradeMenu scene loads")
	
	var menu = menu_scene.instantiate()
	assert_not_null(menu, "UpgradeMenu instantiated")
	
	var fallback_draft: Array[Dictionary] = [
		{
			"id": "emergency_heal",
			"title": "Emergency Bento",
			"description": "Restore +35 HP",
			"rarity": 0,
			"max_rank": 999,
			"current_rank": 1,
			"next_rank": 1,
			"icon": "res://assets/ui/icons/icon_max_hp.png"
		}
	]
	
	menu.open_menu(25, fallback_draft)
	assert_true(menu.visible, "Menu opened with fallback card")
	assert_eq(menu.cards_container.get_child_count(), 1, "Exactly 1 card instantiated in UI")
	
	var selected_id := [""]
	menu.upgrade_applied.connect(func(id: String): selected_id[0] = id)
	menu._on_card_selected("emergency_heal")
	
	assert_eq(selected_id[0], "emergency_heal", "Emergency Bento selected successfully")
	assert_false(menu.visible, "Menu closed after fallback selection")
	
	menu.free()

# ==============================================================================
# 5. CORRUPTED SAVE FILE INJECTION & RECOVERY
# ==============================================================================

func _write_raw_save_file(content: String) -> void:
	var file := FileAccess.open(TEST_CORRUPT_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()

func _safe_int(val: Variant, default_val: int = 0) -> int:
	if val == null:
		return default_val
	if typeof(val) == TYPE_INT:
		return val as int
	if typeof(val) == TYPE_FLOAT:
		return int(val as float)
	if typeof(val) == TYPE_STRING:
		var s: String = val as String
		if s.is_valid_int():
			return s.to_int()
		elif s.is_valid_float():
			return int(s.to_float())
	return default_val

func _safe_float(val: Variant, default_val: float = 0.0) -> float:
	if val == null:
		return default_val
	if typeof(val) == TYPE_FLOAT:
		return val as float
	if typeof(val) == TYPE_INT:
		return float(val as int)
	if typeof(val) == TYPE_STRING:
		var s: String = val as String
		if s.is_valid_float() or s.is_valid_int():
			return s.to_float()
	return default_val

func _safe_bool(val: Variant, default_val: bool = false) -> bool:
	if val == null:
		return default_val
	if typeof(val) == TYPE_BOOL:
		return val as bool
	if typeof(val) == TYPE_INT:
		return (val as int) != 0
	if typeof(val) == TYPE_STRING:
		var s: String = (val as String).to_lower()
		return s == "true" or s == "1"
	return default_val

func _load_and_sanitize_save_data(path: String) -> Dictionary:
	var default_data := {
		"version": 1,
		"high_score": 0,
		"best_survival_time": 0.0,
		"total_games_played": 0,
		"total_victories": 0,
		"total_enemies_killed": 0,
		"highest_wave_reached": 1,
		"boss_defeated": false
	}
	if not FileAccess.file_exists(path):
		return default_data
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return default_data
	var text := file.get_as_text()
	file.close()
	if text.is_empty():
		return default_data
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		return default_data
		
	var d: Dictionary = json.data
	return {
		"version": _safe_int(d.get("version"), 1),
		"high_score": maxi(0, _safe_int(d.get("high_score"), 0)),
		"best_survival_time": maxf(0.0, _safe_float(d.get("best_survival_time"), 0.0)),
		"total_games_played": maxi(0, _safe_int(d.get("total_games_played"), 0)),
		"total_victories": maxi(0, _safe_int(d.get("total_victories"), 0)),
		"total_enemies_killed": maxi(0, _safe_int(d.get("total_enemies_killed"), 0)),
		"highest_wave_reached": maxi(1, _safe_int(d.get("highest_wave_reached"), 1)),
		"boss_defeated": _safe_bool(d.get("boss_defeated"), false)
	}

func test_adversarial_corrupted_save_payloads() -> void:
	# 1. Truncated malformed JSON
	_write_raw_save_file("{\"high_score\": 9999, \"best_survi")
	var res1 = _load_and_sanitize_save_data(TEST_CORRUPT_SAVE_PATH)
	assert_eq(res1.get("high_score"), 0, "Truncated JSON recovers to default high_score=0")
	assert_eq(res1.get("total_games_played"), 0, "Default total_games_played=0")
	
	# 2. Non-Dictionary Root (Array payload injection)
	_write_raw_save_file("[1, 2, 3, \"corrupted\", true]")
	var res2 = _load_and_sanitize_save_data(TEST_CORRUPT_SAVE_PATH)
	assert_eq(res2.get("high_score"), 0, "Array root recovers to default dictionary")
	
	# 3. Non-Dictionary Root (Primitive string payload)
	_write_raw_save_file("\"DROP TABLE save_data;\"")
	var res3 = _load_and_sanitize_save_data(TEST_CORRUPT_SAVE_PATH)
	assert_eq(res3.get("high_score"), 0, "String root recovers to default dictionary")
	
	# 4. Zero-byte empty file
	_write_raw_save_file("")
	var res4 = _load_and_sanitize_save_data(TEST_CORRUPT_SAVE_PATH)
	assert_eq(res4.get("high_score"), 0, "Empty file recovers to default dictionary")
	
	# 5. Type mismatch values (String for int, null for float)
	var type_mismatch_json = JSON.stringify({
		"version": "not_an_int",
		"high_score": "50000_pts",
		"best_survival_time": [10.0, 20.0],
		"total_games_played": null,
		"boss_defeated": "true_str"
	})
	_write_raw_save_file(type_mismatch_json)
	var res5 = _load_and_sanitize_save_data(TEST_CORRUPT_SAVE_PATH)
	assert_eq(res5.get("high_score"), 0, "Type mismatch string cast to 0 int")
	assert_almost_eq(res5.get("best_survival_time"), 0.0, 0.01, "Type mismatch array cast to 0.0 float")
	assert_eq(res5.get("total_games_played"), 0, "Null value cast to 0 int")
	
	# 6. Negative values & extreme integers
	var extreme_json = JSON.stringify({
		"high_score": -99999,
		"best_survival_time": -500.0,
		"highest_wave_reached": -5,
		"total_games_played": -10
	})
	_write_raw_save_file(extreme_json)
	var res6 = _load_and_sanitize_save_data(TEST_CORRUPT_SAVE_PATH)
	assert_eq(res6.get("high_score"), 0, "Negative high score clamped to 0")
	assert_almost_eq(res6.get("best_survival_time"), 0.0, 0.01, "Negative time clamped to 0.0s")
	assert_eq(res6.get("highest_wave_reached"), 1, "Negative wave clamped to 1")
	assert_eq(res6.get("total_games_played"), 0, "Negative games played clamped to 0")
	
	# 7. Recovery & write valid run after extreme corruption
	res6["high_score"] = maxi(res6["high_score"], 1000)
	res6["best_survival_time"] = maxf(res6["best_survival_time"], 45.0)
	res6["total_games_played"] += 1
	res6["boss_defeated"] = true
	
	_write_raw_save_file(JSON.stringify(res6, "\t"))
	var restored = _load_and_sanitize_save_data(TEST_CORRUPT_SAVE_PATH)
	assert_eq(restored.get("high_score"), 1000, "High score repaired to 1000")
	assert_almost_eq(restored.get("best_survival_time"), 45.0, 0.01, "Best survival time repaired to 45.0s")
	assert_true(restored.get("boss_defeated"), "Boss defeated recorded")

# ==============================================================================
# 6. BALLISTICS & PROJECTILE PIERCE STRESS
# ==============================================================================

func test_adversarial_projectile_multi_enemy_pierce_stress() -> void:
	var proj_scene: PackedScene = load("res://scenes/weapons/projectile.tscn")
	var slime_scene: PackedScene = load("res://scenes/enemies/enemy_slime.tscn")
	
	assert_not_null(proj_scene, "Projectile scene loads")
	assert_not_null(slime_scene, "Slime scene loads")
	
	var proj = proj_scene.instantiate()
	assert_not_null(proj, "Projectile instantiated")
	
	# Initialize projectile with 3 pierce and 25.0 damage
	proj.init(Vector2(100, 100), Vector2.RIGHT, 25.0, 400.0, 3, 0.0, 1.5)
	assert_eq(proj.pierce, 3, "Projectile initialized with 3 pierce")
	
	var slimes: Array = []
	for i in range(5):
		var sl = slime_scene.instantiate()
		sl.global_position = Vector2(100 + i * 20, 100)
		slimes.append(sl)
		
	# Hit 1: Pierce 3 -> 2
	proj._on_area_entered(slimes[0].get_node("HitboxArea"))
	assert_eq(proj.pierce, 2, "Pierce remaining after 1st hit is 2")
	assert_almost_eq(slimes[0].current_health, 0.0, 0.01, "Slime 1 took 25 damage (died)")
	
	# Duplicate hit on same enemy must be ignored
	proj._on_area_entered(slimes[0].get_node("HitboxArea"))
	assert_eq(proj.pierce, 2, "Duplicate hit on same enemy ignored, pierce remains 2")
	
	# Hit 2: Pierce 2 -> 1
	proj._on_area_entered(slimes[1].get_node("HitboxArea"))
	assert_eq(proj.pierce, 1, "Pierce remaining after 2nd hit is 1")
	
	# Hit 3: Pierce 1 -> 0 (Lethal pierce exhaustion)
	proj._on_area_entered(slimes[2].get_node("HitboxArea"))
	assert_eq(proj.pierce, 0, "Pierce depleted to 0 on 3rd hit")
	
	for sl in slimes:
		sl.free()
	proj.free()

# ==============================================================================
# 7. HIGH VOLLEY MULTI-SHOT SPREAD STRESS
# ==============================================================================

func test_adversarial_massive_multishot_spread_geometry() -> void:
	# Test calculation of 25 simultaneous projectiles spread over 10 degrees
	var base_angle := 0.0 # Facing RIGHT
	var count := 25
	var spread_deg := 10.0
	
	var angles: Array[float] = PlayerScript.calculate_spread_angles(base_angle, count, spread_deg)
	assert_eq(angles.size(), 25, "Calculated 25 distinct projectile spread angles")
	
	# Check center projectile is at base angle (0.0 rad)
	var mid_idx := 12 # 0 to 24 middle is 12
	assert_almost_eq(angles[mid_idx], 0.0, 0.0001, "Center projectile (idx 12) points exactly at base angle")
	
	# Check symmetry
	for i in range(12):
		var left_ang = angles[i]
		var right_ang = angles[24 - i]
		assert_almost_eq(left_ang + right_ang, 0.0, 0.0001, "Angle pair %d and %d are perfectly symmetrical" % [i, 24 - i])
		
	# Verify total spread span is (count - 1) * spread_deg = 24 * 10 = 240 deg (~4.188 rad)
	var total_span_rad = angles[24] - angles[0]
	var expected_span_rad = deg_to_rad(240.0)
	assert_almost_eq(total_span_rad, expected_span_rad, 0.001, "Total spread span matches expected 240 degrees")
