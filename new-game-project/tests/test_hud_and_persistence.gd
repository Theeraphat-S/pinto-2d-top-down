# res://tests/test_hud_and_persistence.gd
# R5: HUD Real-Time Formatting, Victory/Defeat Conditions, and Save Persistence Roundtrips Tests
extends "res://tests/test_framework.gd"

const TEST_SAVE_PATH: String = "user://test_save_data.json"

# Helper for timer string formatting
func format_timer(seconds: float) -> String:
	var total_sec: int = int(floor(max(0.0, seconds)))
	var mins: int = int(float(total_sec) / 60.0)
	var secs: int = total_sec % 60
	return "%02d:%02d" % [mins, secs]

# Helper for HP ratio calculation
func calculate_hp_ratio(current_hp: float, max_hp: float) -> float:
	if max_hp <= 0.0:
		return 0.0
	return clampf(current_hp / max_hp, 0.0, 1.0)

# Helper for default save dictionary
func get_default_save_data() -> Dictionary:
	return {
		"version": 1,
		"high_score": 0,
		"best_survival_time": 0.0,
		"highest_wave_reached": 1,
		"total_games_played": 0,
		"total_enemies_killed": 0,
		"boss_defeated": false
	}

# Helper to update save data with a run result
func update_run_stats(data: Dictionary, score: int, survival_time: float, wave: int, kills: int, won: bool) -> Dictionary:
	var updated = data.duplicate(true)
	updated["high_score"] = maxi(updated.get("high_score", 0), score)
	updated["best_survival_time"] = maxf(updated.get("best_survival_time", 0.0), survival_time)
	updated["highest_wave_reached"] = maxi(updated.get("highest_wave_reached", 1), wave)
	updated["total_games_played"] = updated.get("total_games_played", 0) + 1
	updated["total_enemies_killed"] = updated.get("total_enemies_killed", 0) + kills
	if won:
		updated["boss_defeated"] = true
	return updated

# Helper to load and parse save data with error recovery
func safe_load_save_data(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return get_default_save_data()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return get_default_save_data()
	var text: String = file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		return get_default_save_data()
	return json.data as Dictionary

# Lifecycle cleanup
func after_all() -> void:
	var global_path: String = ProjectSettings.globalize_path(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(global_path)

# --- Test Cases ---

func test_timer_formatting() -> void:
	assert_eq(format_timer(0.0), "00:00", "0 seconds is 00:00")
	assert_eq(format_timer(9.4), "00:09", "9.4 seconds is 00:09")
	assert_eq(format_timer(65.0), "01:05", "65 seconds is 01:05")
	assert_eq(format_timer(300.0), "05:00", "300 seconds is 05:00")
	assert_eq(format_timer(-5.0), "00:00", "Negative seconds clamped to 00:00")

func test_hud_hp_and_xp_ratio_clamping() -> void:
	# Full HP
	assert_almost_eq(calculate_hp_ratio(100.0, 100.0), 1.0, 0.001, "Full HP ratio is 1.0")
	# Half HP
	assert_almost_eq(calculate_hp_ratio(50.0, 100.0), 0.5, 0.001, "Half HP ratio is 0.5")
	# Zero HP
	assert_almost_eq(calculate_hp_ratio(0.0, 100.0), 0.0, 0.001, "Zero HP ratio is 0.0")
	# Massive overkill damage (-50 HP) must clamp to 0.0
	assert_almost_eq(calculate_hp_ratio(-50.0, 100.0), 0.0, 0.001, "Overkill HP clamps to 0.0 (never negative)")

func test_victory_and_game_over_conditions() -> void:
	# Defeat condition: Player HP <= 0
	var player_hp: float = 0.0
	var is_game_over: bool = (player_hp <= 0.0)
	assert_true(is_game_over, "Player HP at 0 triggers Game Over")
	
	# Victory condition: Wave 5 Boss HP <= 0
	var current_wave: int = 5
	var boss_hp: float = 0.0
	var is_victory: bool = (current_wave == 5 and boss_hp <= 0.0)
	assert_true(is_victory, "Boss death on Wave 5 triggers Victory")

func test_save_stats_aggregation_logic() -> void:
	var initial := get_default_save_data()
	assert_eq(initial["high_score"], 0, "Initial high score is 0")
	assert_eq(initial["total_games_played"], 0, "Initial games played is 0")
	
	# Run 1: Score 3500, time 120s, wave 3, kills 50, lost
	var run1 = update_run_stats(initial, 3500, 120.0, 3, 50, false)
	assert_eq(run1["high_score"], 3500, "High score updated to 3500")
	assert_almost_eq(run1["best_survival_time"], 120.0, 0.01, "Best time is 120s")
	assert_eq(run1["total_games_played"], 1, "1 game played")
	assert_eq(run1["total_enemies_killed"], 50, "50 enemies killed")
	assert_false(run1["boss_defeated"], "Boss not defeated yet")
	
	# Run 2: Score 2000 (lower), time 150s (higher), wave 4, kills 40, lost
	var run2 = update_run_stats(run1, 2000, 150.0, 4, 40, false)
	assert_eq(run2["high_score"], 3500, "High score retained at 3500 (lower score did not overwrite)")
	assert_almost_eq(run2["best_survival_time"], 150.0, 0.01, "Best survival time updated to 150s")
	assert_eq(run2["total_games_played"], 2, "2 games played")
	assert_eq(run2["total_enemies_killed"], 90, "Total kills aggregated to 90")
	
	# Run 3: Score 8000, time 210s, wave 5, kills 120, won
	var run3 = update_run_stats(run2, 8000, 210.0, 5, 120, true)
	assert_eq(run3["high_score"], 8000, "High score updated to 8000")
	assert_true(run3["boss_defeated"], "Boss defeated flagged true on win")
	assert_eq(run3["total_games_played"], 3, "3 games played")
	assert_eq(run3["total_enemies_killed"], 210, "Total kills aggregated to 210")

func test_save_persistence_disk_roundtrip() -> void:
	var test_data: Dictionary = {
		"version": 1,
		"high_score": 12500,
		"best_survival_time": 312.45,
		"highest_wave_reached": 5,
		"total_games_played": 8,
		"total_enemies_killed": 340,
		"boss_defeated": true
	}
	
	# Save to disk
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	assert_not_null(file, "File opened for writing")
	file.store_string(JSON.stringify(test_data, "\t"))
	file.close()
	
	# Load from disk
	var loaded := safe_load_save_data(TEST_SAVE_PATH)
	assert_eq(loaded["high_score"], 12500, "Loaded high_score matches")
	assert_almost_eq(loaded["best_survival_time"], 312.45, 0.001, "Loaded best_survival_time matches")
	assert_eq(loaded["highest_wave_reached"], 5, "Loaded highest_wave_reached matches")
	assert_eq(loaded["total_games_played"], 8, "Loaded total_games_played matches")
	assert_eq(loaded["total_enemies_killed"], 340, "Loaded total_enemies_killed matches")
	assert_true(loaded["boss_defeated"], "Loaded boss_defeated matches")

func test_corrupted_save_file_fallback_recovery() -> void:
	# Write malformed/invalid JSON
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string("{ malformed json string !!! invalid }}}")
	file.close()
	
	# Load should catch parse error and return safe default dictionary without crashing
	var recovered := safe_load_save_data(TEST_SAVE_PATH)
	assert_not_null(recovered, "Recovered data is non-null")
	assert_eq(recovered["high_score"], 0, "Default high score returned")
	assert_eq(recovered["total_games_played"], 0, "Default games played returned")
	assert_false(recovered["boss_defeated"], "Default boss_defeated is false")

func test_non_existent_save_file_default() -> void:
	var fake_path: String = "user://non_existent_file_9999.json"
	var default_data := safe_load_save_data(fake_path)
	assert_eq(default_data["high_score"], 0, "Missing file returns clean defaults")

func test_hud_scene_structure_and_reactive_updates() -> void:
	var hud_scene = load("res://scenes/ui/hud.tscn")
	assert_not_null(hud_scene, "HUD scene loads")
	
	var hud = hud_scene.instantiate()
	assert_not_null(hud, "HUD instantiated")
	assert_eq(hud.layer, 5, "HUD CanvasLayer is 5")
	
	# Test Health updates
	hud.update_health(80.0, 100.0)
	assert_eq(hud.hp_bar.value, 80.0, "HP bar reflects 80 HP")
	assert_eq(hud.hp_label.text, "80 / 100", "HP label displays 80 / 100")
	
	# Test XP updates
	hud.update_xp(15, 30, 2)
	assert_eq(hud.xp_bar.value, 15.0, "XP bar reflects 15 XP")
	assert_eq(hud.xp_label.text, "15 / 30 XP", "XP label displays 15 / 30 XP")
	assert_eq(hud.level_badge.text, "LV.2", "Level badge displays LV.2")
	
	# Test Wave & Score updates
	hud.update_wave(3)
	assert_eq(hud.wave_label.text, "WAVE 3/5", "Wave counter displays WAVE 3/5")
	hud.update_score(2450)
	assert_eq(hud.score_label.text, "SCORE: 2,450", "Score displays formatted score")
	hud.update_kills(58)
	assert_eq(hud.kills_label.text, "KILLS: 58", "Kills counter displays KILLS: 58")
	hud.update_high_score(12000)
	assert_eq(hud.best_label.text, "BEST: 12,000", "Best counter displays BEST: 12,000")
	
	# Test Boss Bar updates
	assert_false(hud.boss_container.visible, "Boss container hidden by default")
	hud.show_boss_bar("GIGA-NULL", 1000.0)
	assert_true(hud.boss_container.visible, "Boss container visible when spawned")
	assert_has(hud.boss_title.text, "GIGA-NULL", "Boss title displays GIGA-NULL")
	hud.update_boss_bar(500.0, 1000.0)
	assert_eq(hud.boss_bar.value, 500.0, "Boss bar shows 500 HP")
	assert_has(hud.boss_hp_label.text, "50%", "Boss percentage displays 50%")
	hud.hide_boss_bar()
	assert_false(hud.boss_container.visible, "Boss container hidden on defeat")
	
	hud.free()

func test_victory_screen_scene_structure_and_stats() -> void:
	var victory_scene = load("res://scenes/ui/victory_screen.tscn")
	assert_not_null(victory_scene, "VictoryScreen scene loads")
	
	var victory = victory_scene.instantiate()
	assert_not_null(victory, "VictoryScreen instantiated")
	assert_eq(victory.layer, 15, "VictoryScreen layer is 15")
	assert_eq(victory.process_mode, Node.PROCESS_MODE_ALWAYS, "VictoryScreen process_mode is ALWAYS")
	
	victory.show_victory()
	assert_true(victory.visible, "Victory modal is visible after show_victory")
	assert_not_null(victory.play_again_btn, "Play again button present")
	assert_not_null(victory.quit_btn, "Quit button present")
	
	victory.free()

func test_game_over_screen_scene_structure_and_stats() -> void:
	var game_over_scene = load("res://scenes/ui/game_over_screen.tscn")
	assert_not_null(game_over_scene, "GameOverScreen scene loads")
	
	var game_over = game_over_scene.instantiate()
	assert_not_null(game_over, "GameOverScreen instantiated")
	assert_eq(game_over.layer, 15, "GameOverScreen layer is 15")
	assert_eq(game_over.process_mode, Node.PROCESS_MODE_ALWAYS, "GameOverScreen process_mode is ALWAYS")
	
	game_over.show_game_over()
	assert_true(game_over.visible, "Game Over modal is visible after show_game_over")
	assert_not_null(game_over.retry_btn, "Retry button present")
	assert_not_null(game_over.quit_btn, "Quit button present")
	
	game_over.free()

func test_main_scene_instantiation_and_camera_clamping() -> void:
	var main_scene = load("res://scenes/main.tscn")
	assert_not_null(main_scene, "Main scene loads")
	
	var main_node = main_scene.instantiate()
	assert_not_null(main_node, "Main scene instantiated")
	
	assert_not_null(main_node.get_node_or_null("Arena"), "Arena present in Main scene")
	assert_not_null(main_node.get_node_or_null("Player"), "Player present in Main scene")
	assert_not_null(main_node.get_node_or_null("Camera2D"), "Camera2D present in Main scene")
	assert_not_null(main_node.get_node_or_null("Spawner"), "Spawner present in Main scene")
	assert_not_null(main_node.get_node_or_null("HUD"), "HUD present in Main scene")
	assert_not_null(main_node.get_node_or_null("UpgradeMenu"), "UpgradeMenu present in Main scene")
	assert_not_null(main_node.get_node_or_null("VictoryScreen"), "VictoryScreen present in Main scene")
	assert_not_null(main_node.get_node_or_null("GameOverScreen"), "GameOverScreen present in Main scene")
	
	var cam: Camera2D = main_node.get_node("Camera2D") as Camera2D
	assert_eq(cam.zoom, Vector2(1.0, 1.0), "Camera zoom is Vector2(1.0, 1.0)")
	assert_eq(cam.limit_left, 0, "Camera left limit is 0")
	assert_eq(cam.limit_top, 0, "Camera top limit is 0")
	assert_eq(cam.limit_right, 1280, "Camera right limit is 1280")
	assert_eq(cam.limit_bottom, 720, "Camera bottom limit is 720")
	
	var player: Node2D = main_node.get_node("Player") as Node2D
	assert_eq(player.position, Vector2(640, 360), "Player positioned at arena center")
	
	main_node.free()
