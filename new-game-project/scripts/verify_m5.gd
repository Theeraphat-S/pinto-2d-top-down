extends SceneTree

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - M5 VERIFICATION SUITE
# Comprehensive verification for Roguelite Upgrades, HUD & Game Lifecycle.
# ==============================================================================

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	print("\n============================================================")
	print("   PINTO 2D SURVIVAL ARENA — M5 VERIFICATION SUITE")
	print("============================================================\n")
	
	_run_all_tests()
	
	print("\n============================================================")
	print("   M5 VERIFICATION SUMMARY: %d passed, %d failed." % [passed_count, failed_count])
	print("============================================================\n")
	
	if failed_count > 0:
		quit(1)
	else:
		quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		passed_count += 1
		print("  [PASS] ", message)
	else:
		failed_count += 1
		printerr("  [FAIL] ", message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		passed_count += 1
		print("  [PASS] %s (got: %s)" % [message, str(actual)])
	else:
		failed_count += 1
		printerr("  [FAIL] %s (expected: %s, got: %s)" % [message, str(expected), str(actual)])

func _assert_almost_eq(actual: float, expected: float, tol: float = 0.001, message: String = "") -> void:
	if absf(actual - expected) <= tol:
		passed_count += 1
		print("  [PASS] %s (got: %f, expected: %f)" % [message, actual, expected])
	else:
		failed_count += 1
		printerr("  [FAIL] %s (expected: %f, got: %f, diff: %f)" % [message, expected, actual, absf(actual - expected)])

func _run_all_tests() -> void:
	test_upgrade_card_scene()
	test_upgrade_menu_scene()
	test_hud_scene()
	test_victory_screen_scene()
	test_game_over_screen_scene()
	test_main_scene()
	test_save_manager_integration()

func test_upgrade_card_scene() -> void:
	print(">> Testing UpgradeCard Component...")
	var scene = load("res://scenes/ui/upgrade_card.tscn")
	_assert(scene != null, "UpgradeCard scene resource loaded")
	
	var card = scene.instantiate()
	_assert(card != null, "UpgradeCard instantiated")
	
	var card_data = {
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
	_assert_eq(card.card_id, "dmg_up", "Card ID setup correctly")
	_assert_eq(card.title_label.text, "Power Amp", "Title label displays Power Amp")
	_assert_eq(card.desc_label.text, "+20% Attack Damage", "Description label displays correct text")
	_assert_eq(card.rarity_label.text, "[ RARE ]", "Rarity label displays [ RARE ]")
	_assert_eq(card.rank_label.text, "★★★☆☆ (Rank 3/5)", "Rank stars display ★★★☆☆ (Rank 3/5)")
	_assert_eq(card.key_badge.text, "[ Press 1 ]", "Key badge displays [ Press 1 ]")
	
	var selected_box := [""]
	card.card_selected.connect(func(id: String): selected_box[0] = id)
	card.select_card()
	_assert_eq(selected_box[0], "dmg_up", "Card selection emits card_selected with card ID")
	
	card.free()

func test_upgrade_menu_scene() -> void:
	print(">> Testing UpgradeMenu Modal...")
	var scene = load("res://scenes/ui/upgrade_menu.tscn")
	_assert(scene != null, "UpgradeMenu scene resource loaded")
	
	var menu = scene.instantiate()
	_assert(menu != null, "UpgradeMenu instantiated")
	_assert_eq(menu.layer, 10, "UpgradeMenu layer is 10")
	_assert_eq(menu.process_mode, Node.PROCESS_MODE_ALWAYS, "UpgradeMenu process mode is ALWAYS")
	
	var sample_cards = [
		{"id": "dmg_up", "title": "Power Amp", "description": "+20% Damage", "rarity": 0, "max_rank": 5, "current_rank": 0, "next_rank": 1},
		{"id": "atk_spd", "title": "Quick Reflexes", "description": "+20% Speed", "rarity": 0, "max_rank": 5, "current_rank": 0, "next_rank": 1},
		{"id": "multi_shot", "title": "Twin Shot", "description": "+1 Projectile", "rarity": 1, "max_rank": 3, "current_rank": 0, "next_rank": 1}
	]
	menu.open_menu(2, sample_cards)
	_assert(menu.visible, "Menu becomes visible on open")
	_assert_eq(menu.cards_container.get_child_count(), 3, "3 upgrade cards instantiated")
	_assert(menu.level_label.text.contains("LEVEL 2"), "Level label displays LEVEL 2")
	
	var applied_box := [""]
	menu.upgrade_applied.connect(func(id: String): applied_box[0] = id)
	menu._on_card_selected("multi_shot")
	_assert_eq(applied_box[0], "multi_shot", "Upgrade applied signal emitted on card selection")
	_assert(!menu.visible, "Menu hidden after card selection")
	
	menu.free()

func test_hud_scene() -> void:
	print(">> Testing GameHUD...")
	var scene = load("res://scenes/ui/hud.tscn")
	_assert(scene != null, "HUD scene resource loaded")
	
	var hud = scene.instantiate()
	_assert(hud != null, "HUD instantiated")
	_assert_eq(hud.layer, 5, "HUD layer is 5")
	
	hud.update_health(85.0, 100.0)
	_assert_almost_eq(hud.hp_bar.value, 85.0, 0.01, "Health bar value is 85")
	_assert_eq(hud.hp_label.text, "85 / 100", "Health label is 85 / 100")
	
	hud.update_xp(25, 50, 3)
	_assert_eq(hud.xp_bar.value, 25.0, "XP bar value is 25")
	_assert_eq(hud.xp_label.text, "25 / 50 XP", "XP label is 25 / 50 XP")
	_assert_eq(hud.level_badge.text, "LV.3", "Level badge is LV.3")
	
	hud.update_wave(4)
	_assert_eq(hud.wave_label.text, "WAVE 4/5", "Wave label is WAVE 4/5")
	
	hud.update_score(3400)
	_assert_eq(hud.score_label.text, "SCORE: 3,400", "Score label formatted to 3,400")
	
	hud.update_kills(64)
	_assert_eq(hud.kills_label.text, "KILLS: 64", "Kills label is KILLS: 64")
	
	hud.update_high_score(15000)
	_assert_eq(hud.best_label.text, "BEST: 15,000", "Best label is BEST: 15,000")
	
	hud.show_boss_bar("GIGA-NULL", 2000.0)
	_assert(hud.boss_container.visible, "Boss container visible on boss spawn")
	hud.update_boss_bar(1000.0, 2000.0)
	_assert_almost_eq(hud.boss_bar.value, 1000.0, 0.01, "Boss bar shows 1000 HP")
	_assert(hud.boss_hp_label.text.contains("50%"), "Boss HP percentage is 50%")
	hud.hide_boss_bar()
	_assert(!hud.boss_container.visible, "Boss container hidden on defeat")
	
	hud.free()

func test_victory_screen_scene() -> void:
	print(">> Testing VictoryScreen Modal...")
	var scene = load("res://scenes/ui/victory_screen.tscn")
	_assert(scene != null, "VictoryScreen scene loaded")
	
	var victory = scene.instantiate()
	_assert(victory != null, "VictoryScreen instantiated")
	_assert_eq(victory.layer, 15, "VictoryScreen layer is 15")
	_assert_eq(victory.process_mode, Node.PROCESS_MODE_ALWAYS, "VictoryScreen process_mode is ALWAYS")
	
	victory.show_victory()
	_assert(victory.visible, "Victory modal visible after show_victory")
	_assert(victory.play_again_btn != null, "Play again button present")
	_assert(victory.quit_btn != null, "Quit button present")
	
	victory.free()

func test_game_over_screen_scene() -> void:
	print(">> Testing GameOverScreen Modal...")
	var scene = load("res://scenes/ui/game_over_screen.tscn")
	_assert(scene != null, "GameOverScreen scene loaded")
	
	var game_over = scene.instantiate()
	_assert(game_over != null, "GameOverScreen instantiated")
	_assert_eq(game_over.layer, 15, "GameOverScreen layer is 15")
	_assert_eq(game_over.process_mode, Node.PROCESS_MODE_ALWAYS, "GameOverScreen process_mode is ALWAYS")
	
	game_over.show_game_over()
	_assert(game_over.visible, "Game Over modal visible after show_game_over")
	_assert(game_over.retry_btn != null, "Retry button present")
	_assert(game_over.quit_btn != null, "Quit button present")
	
	game_over.free()

func test_main_scene() -> void:
	print(">> Testing Main Scene Orchestration...")
	var scene = load("res://scenes/main.tscn")
	_assert(scene != null, "Main scene loaded")
	
	var main_node = scene.instantiate()
	_assert(main_node != null, "Main scene instantiated")
	
	_assert(main_node.has_node("Arena"), "Arena in main scene")
	_assert(main_node.has_node("Player"), "Player in main scene")
	_assert(main_node.has_node("Camera2D"), "Camera2D in main scene")
	_assert(main_node.has_node("HUD"), "HUD in main scene")
	_assert(main_node.has_node("UpgradeMenu"), "UpgradeMenu in main scene")
	_assert(main_node.has_node("VictoryScreen"), "VictoryScreen in main scene")
	_assert(main_node.has_node("GameOverScreen"), "GameOverScreen in main scene")
	
	var cam: Camera2D = main_node.get_node("Camera2D") as Camera2D
	_assert_eq(cam.limit_left, 0, "Camera left limit is 0")
	_assert_eq(cam.limit_top, 0, "Camera top limit is 0")
	_assert_eq(cam.limit_right, 1280, "Camera right limit is 1280")
	_assert_eq(cam.limit_bottom, 720, "Camera bottom limit is 720")
	
	var player = main_node.get_node("Player")
	_assert_eq(player.position, Vector2(640, 360), "Player positioned at arena center (640, 360)")
	
	main_node.free()

func test_save_manager_integration() -> void:
	print(">> Testing SaveManager Roundtrip & Stats Aggregation...")
	var sm = root.get_node_or_null("SaveManager") if root else null
	if not sm:
		print("  [SKIP] SaveManager singleton not active in standalone unit run")
		return
		
	var initial_high = sm.high_score
	sm.record_run_result(initial_high + 500, 180.0, true, 45, 5)
	_assert_eq(sm.high_score, initial_high + 500, "SaveManager high score updated")
	_assert(sm.boss_defeated, "SaveManager boss_defeated flag true after victory")
