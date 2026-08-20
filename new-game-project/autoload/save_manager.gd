extends Node

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - SAVE MANAGER SINGLETON
# Handles persistence of high scores, best survival times, and run statistics.
# Uses JSON storage at user://save_data.json with robust error recovery.
# ==============================================================================

const SAVE_PATH: String = "user://save_data.json"

var high_score: int = 0
var best_survival_time: float = 0.0
var total_games_played: int = 0
var total_victories: int = 0
var total_enemies_killed: int = 0
var highest_wave_reached: int = 1
var boss_defeated: bool = false

func _ready() -> void:
	load_game()
	_connect_event_bus()

func _connect_event_bus() -> void:
	if not EventBus.is_connected("game_won", Callable(self, "_on_game_won")):
		EventBus.game_won.connect(_on_game_won)
	if not EventBus.is_connected("game_lost", Callable(self, "_on_game_lost")):
		EventBus.game_lost.connect(_on_game_lost)

func get_default_data() -> Dictionary:
	return {
		"version": 1,
		"high_score": 0,
		"best_survival_time": 0.0,
		"total_games_played": 0,
		"total_victories": 0,
		"total_enemies_killed": 0,
		"highest_wave_reached": 1,
		"boss_defeated": false
	}

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		_apply_dict(get_default_data())
		return true

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_warning("[SaveManager] Unable to open save file for reading. Initializing defaults.")
		_apply_dict(get_default_data())
		return false

	var content := file.get_as_text()
	file.close()

	if content.is_empty():
		push_warning("[SaveManager] Save file is empty. Initializing defaults.")
		_apply_dict(get_default_data())
		return false

	var json := JSON.new()
	var err := json.parse(content)
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_warning("[SaveManager] Save file corrupted or invalid JSON. Recovering with default data.")
		_apply_dict(get_default_data())
		return false

	var dict: Dictionary = json.data
	_apply_dict(dict)
	return true

func save_game() -> bool:
	var dict := {
		"version": 1,
		"high_score": high_score,
		"best_survival_time": best_survival_time,
		"total_games_played": total_games_played,
		"total_victories": total_victories,
		"total_enemies_killed": total_enemies_killed,
		"highest_wave_reached": highest_wave_reached,
		"boss_defeated": boss_defeated
	}

	var json_str := JSON.stringify(dict, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("[SaveManager] Failed to open save file for writing: " + SAVE_PATH)
		return false

	file.store_string(json_str)
	file.close()
	return true

func record_run_result(final_score: int, survival_time: float, won: bool, kills: int = 0, wave: int = 1) -> void:
	high_score = maxi(high_score, final_score)
	best_survival_time = maxf(best_survival_time, survival_time)
	highest_wave_reached = maxi(highest_wave_reached, wave)
	total_games_played += 1
	total_enemies_killed += kills
	if won:
		total_victories += 1
		boss_defeated = true
	save_game()

func reset_save_data() -> void:
	_apply_dict(get_default_data())
	save_game()

func _apply_dict(dict: Dictionary) -> void:
	high_score = int(dict.get("high_score", 0))
	best_survival_time = float(dict.get("best_survival_time", 0.0))
	total_games_played = int(dict.get("total_games_played", 0))
	total_victories = int(dict.get("total_victories", 0))
	total_enemies_killed = int(dict.get("total_enemies_killed", 0))
	highest_wave_reached = int(dict.get("highest_wave_reached", 1))
	boss_defeated = bool(dict.get("boss_defeated", false))

func _on_game_won() -> void:
	if GameState:
		record_run_result(GameState.score, GameState.elapsed_time, true, GameState.enemies_killed, GameState.current_wave)

func _on_game_lost() -> void:
	if GameState:
		record_run_result(GameState.score, GameState.elapsed_time, false, GameState.enemies_killed, GameState.current_wave)
