extends Node

# ==============================================================================
# MILESTONE M1 VERIFICATION TEST SUITE
# Validates asset generation, Autoload Singletons, contracts, and persistence.
# ==============================================================================

var _failures: int = 0
var _passes: int = 0

func _ready() -> void:
	print("==================================================")
	print("RUNNING MILESTONE M1 VERIFICATION SUITE")
	print("==================================================")
	
	_test_assets_exist_and_load()
	_test_event_bus_signals()
	_test_game_state_logic()
	_test_upgrade_catalog_logic()
	_test_save_manager_persistence()
	
	print("==================================================")
	print("M1 VERIFICATION SUMMARY: %d passed, %d failed." % [_passes, _failures])
	print("==================================================")
	
	if _failures == 0:
		print(">> ALL MILESTONE M1 VERIFICATIONS PASSED!")
		get_tree().quit(0)
	else:
		printerr(">> M1 VERIFICATION FAILED WITH %d ERRORS!" % _failures)
		get_tree().quit(1)

func _assert(condition: bool, test_name: String, details: String = "") -> void:
	if condition:
		_passes += 1
		print("  [PASS] ", test_name)
	else:
		_failures += 1
		printerr("  [FAIL] ", test_name, " - ", details)

# ==============================================================================
# 1. ASSET INTEGRITY TESTS
# ==============================================================================

func _test_assets_exist_and_load() -> void:
	print("\n--- 1. Testing Assets Existence & Image Dimensions ---")
	
	var asset_checks := [
		{"path": "res://assets/sprites/pinto_spritesheet.png", "w": 256, "h": 128},
		{"path": "res://assets/sprites/enemies/slime.png", "w": 128, "h": 32},
		{"path": "res://assets/sprites/enemies/bat.png", "w": 128, "h": 32},
		{"path": "res://assets/sprites/enemies/drone.png", "w": 128, "h": 32},
		{"path": "res://assets/sprites/enemies/golem.png", "w": 192, "h": 48},
		{"path": "res://assets/sprites/enemies/boss_giga_null.png", "w": 320, "h": 80},
		{"path": "res://assets/sprites/projectiles/bullet.png", "w": 16, "h": 16},
		{"path": "res://assets/sprites/projectiles/energy_orb.png", "w": 16, "h": 16},
		{"path": "res://assets/sprites/projectiles/laser.png", "w": 32, "h": 8},
		{"path": "res://assets/sprites/pickups/xp_small.png", "w": 12, "h": 12},
		{"path": "res://assets/sprites/pickups/xp_med.png", "w": 14, "h": 14},
		{"path": "res://assets/sprites/pickups/xp_large.png", "w": 16, "h": 16},
		{"path": "res://assets/tilesets/arena_tileset.png", "w": 256, "h": 128},
		{"path": "res://assets/tilesets/props.png", "w": 128, "h": 64},
		{"path": "res://assets/ui/card_background.png", "w": 120, "h": 180}
	]
	
	for check in asset_checks:
		var p: String = check["path"]
		var img := Image.new()
		var err := img.load(ProjectSettings.globalize_path(p))
		_assert(err == OK, "Image loads: " + p, "Error: " + str(err))
		if err == OK:
			_assert(img.get_width() == check["w"] and img.get_height() == check["h"],
				"Dimensions match: " + p,
				"Expected: %dx%d, Got: %dx%d" % [check["w"], check["h"], img.get_width(), img.get_height()])
				
	# Check 10 Upgrade Icons
	var icon_names: Array[String] = [
		"icon_damage.png", "icon_attack_speed.png", "icon_move_speed.png",
		"icon_max_hp.png", "icon_multishot.png", "icon_pierce.png",
		"icon_range.png", "icon_magnet.png", "icon_regen.png", "icon_crit.png"
	]
	for icon: String in icon_names:
		var p: String = "res://assets/ui/icons/" + icon
		var img := Image.new()
		var err := img.load(ProjectSettings.globalize_path(p))
		_assert(err == OK and img.get_width() == 32 and img.get_height() == 32,
			"Icon valid (32x32): " + icon, "Path: " + p)
			
	# Check 7 SFX WAV files
	var sfx_names: Array[String] = [
		"shoot.wav", "hit.wav", "explosion.wav", "gem_pickup.wav",
		"levelup.wav", "game_over.wav", "victory.wav"
	]
	for sfx: String in sfx_names:
		var p: String = "res://assets/sfx/" + sfx
		var global_p := ProjectSettings.globalize_path(p)
		_assert(FileAccess.file_exists(global_p), "SFX file exists: " + sfx)
		var file := FileAccess.open(global_p, FileAccess.READ)
		if file:
			var magic := file.get_buffer(4).get_string_from_ascii()
			_assert(magic == "RIFF", "SFX WAV has valid RIFF header: " + sfx, "Got: " + magic)
			file.close()

# ==============================================================================
# 2. EVENT BUS TESTS
# ==============================================================================

func _test_event_bus_signals() -> void:
	print("\n--- 2. Testing EventBus Singleton Signals ---")
	
	_assert(EventBus != null, "EventBus singleton is initialized")
	
	var required_signals: Array[String] = [
		"player_health_changed", "player_died", "player_healed",
		"xp_collected", "level_up_triggered", "upgrade_selected",
		"wave_started", "wave_completed",
		"enemy_killed", "enemy_hit", "projectile_fired",
		"boss_spawned", "boss_hp_changed", "boss_phase_changed", "boss_defeated",
		"score_updated", "game_won", "game_lost", "game_restarted"
	]
	
	for sig_name in required_signals:
		_assert(EventBus.has_signal(sig_name), "EventBus has signal: " + sig_name)
		
	# Test signal emission and reception
	var test_received := [false]
	var test_callback := func(current: float, max_h: float):
		test_received[0] = true
	EventBus.player_health_changed.connect(test_callback)
	EventBus.player_health_changed.emit(75.0, 100.0)
	EventBus.player_health_changed.disconnect(test_callback)
	_assert(test_received[0], "EventBus signal emission and reception works")

# ==============================================================================
# 3. GAME STATE TESTS
# ==============================================================================

func _test_game_state_logic() -> void:
	print("\n--- 3. Testing GameState Singleton Logic ---")
	
	_assert(GameState != null, "GameState singleton is initialized")
	
	GameState.reset_run()
	_assert(GameState.current_wave == 1, "Initial wave is 1")
	_assert(GameState.score == 0, "Initial score is 0")
	_assert(GameState.enemies_killed == 0, "Initial kills is 0")
	_assert(GameState.current_level == 1, "Initial level is 1")
	_assert(GameState.current_health == 100.0, "Initial health is 100.0")
	_assert(GameState.max_health == 100.0, "Initial max health is 100.0")
	
	# Test XP Level formula
	_assert(GameState.get_xp_required_for_level(1) == 10, "XP req Level 1 -> 2 is 10")
	_assert(GameState.get_xp_required_for_level(2) == 30, "XP req Level 2 -> 3 is 30")
	_assert(GameState.get_xp_required_for_level(3) == 60, "XP req Level 3 -> 4 is 60")
	_assert(GameState.get_xp_required_for_level(4) == 100, "XP req Level 4 -> 5 is 100")
	_assert(GameState.get_xp_required_for_level(5) == 150, "XP req Level 5 -> 6 is 150")
	
	# Test XP Collection & Level up trigger
	var level_up_count := [0]
	var level_up_cb := func(new_lvl: int, cards: Array):
		level_up_count[0] += 1
	EventBus.level_up_triggered.connect(level_up_cb)
	
	GameState.add_xp(5)
	_assert(GameState.current_xp == 5 and GameState.current_level == 1, "XP accumulated without leveling")
	GameState.add_xp(5) # reaches 10 -> level 2
	_assert(GameState.current_level == 2, "Level reached 2 after 10 XP")
	_assert(level_up_count[0] == 1, "level_up_triggered signal fired exactly once")
	EventBus.level_up_triggered.disconnect(level_up_cb)
	
	# Test Damage and Healing
	GameState.take_damage(30.0)
	_assert(GameState.current_health == 70.0, "Health reduced to 70.0 after 30 damage")
	GameState.heal(15.0)
	_assert(GameState.current_health == 85.0, "Health restored to 85.0 after 15 heal")
	GameState.heal(50.0)
	_assert(GameState.current_health == 100.0, "Health capped at max_health")
	
	# Test Score and Kills
	GameState.record_kill("slime", 25)
	_assert(GameState.enemies_killed == 1, "Kills incremented to 1")
	_assert(GameState.score == 25, "Score incremented to 25")

# ==============================================================================
# 4. UPGRADE CATALOG TESTS
# ==============================================================================

func _test_upgrade_catalog_logic() -> void:
	print("\n--- 4. Testing UpgradeCatalog Singleton ---")
	
	_assert(UpgradeCatalog != null, "UpgradeCatalog singleton is initialized")
	
	var all_cards := UpgradeCatalog.get_all_cards()
	_assert(all_cards.size() >= 10, "UpgradeCatalog contains at least 10 cards", "Got: " + str(all_cards.size()))
	
	var draft := UpgradeCatalog.get_random_upgrade_cards(3)
	_assert(draft.size() == 3, "Draft returned 3 cards")
	_assert(draft[0].id != draft[1].id and draft[1].id != draft[2].id and draft[0].id != draft[2].id,
		"Draft cards are unique (no duplicates in 3-card draft)")
		
	# Test applying an upgrade
	GameState.reset_run()
	var base_dmg: float = GameState.attack_damage
	UpgradeCatalog.apply_card("dmg_up")
	_assert(GameState.attack_damage > base_dmg, "Applying dmg_up increases attack damage")
	_assert(is_equal_approx(GameState.attack_damage, base_dmg + base_dmg * 0.20),
		"dmg_up increases damage by exactly 20%")
		
	var base_max_hp: float = GameState.max_health
	UpgradeCatalog.apply_card("max_hp")
	_assert(GameState.max_health == base_max_hp + 25.0, "Applying max_hp increases max HP by 25")

# ==============================================================================
# 5. SAVE MANAGER PERSISTENCE TESTS
# ==============================================================================

func _test_save_manager_persistence() -> void:
	print("\n--- 5. Testing SaveManager Persistence & Recovery ---")
	
	_assert(SaveManager != null, "SaveManager singleton is initialized")
	
	SaveManager.reset_save_data()
	_assert(SaveManager.high_score == 0, "High score reset to 0")
	
	# Test saving and loading
	SaveManager.record_run_result(5000, 120.5, true, 42, 5)
	_assert(SaveManager.high_score == 5000, "High score updated to 5000")
	_assert(SaveManager.best_survival_time == 120.5, "Best survival time updated to 120.5")
	_assert(SaveManager.total_victories == 1, "Total victories updated to 1")
	_assert(SaveManager.boss_defeated == true, "Boss defeated flag updated to true")
	
	# Reload from disk
	SaveManager.load_game()
	_assert(SaveManager.high_score == 5000, "High score loaded from disk correctly")
	
	# Lower score should not overwrite high score
	SaveManager.record_run_result(2000, 60.0, false, 10, 2)
	_assert(SaveManager.high_score == 5000, "High score retained after lower score run")
	_assert(SaveManager.total_games_played == 2, "Total games played incremented to 2")
	
	# Corrupted JSON recovery test
	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string("{ INVALID JSON CORRUPTED DATA !!! }")
		file.close()
		
	var loaded_cleanly := SaveManager.load_game()
	_assert(loaded_cleanly == false, "Load caught corrupted file and returned false")
	_assert(SaveManager.high_score == 0, "SaveManager safely fell back to default state without crashing")
