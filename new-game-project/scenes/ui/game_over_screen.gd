class_name GameOverScreen
extends CanvasLayer

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - GAME OVER MODAL
# Triggered when player health reaches 0. Displays survival stats and persistence.
# ==============================================================================

signal game_over_shown()
signal retry_requested()
signal quit_requested()

@onready var wave_value: Label = $DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/WaveValue
@onready var time_value: Label = $DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/TimeValue
@onready var score_value: Label = $DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/ScoreValue
@onready var kills_value: Label = $DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/KillsValue
@onready var best_value: Label = $DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/BestValue
@onready var retry_btn: Button = $DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/ButtonContainer/RetryButton
@onready var quit_btn: Button = $DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/ButtonContainer/QuitButton
@onready var sfx_player: AudioStreamPlayer = $GameOverSFX

var _is_displayed: bool = false

func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_ensure_nodes()
	_connect_signals()

func _ensure_nodes() -> void:
	if not wave_value:
		wave_value = get_node_or_null("DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/WaveValue") as Label
	if not time_value:
		time_value = get_node_or_null("DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/TimeValue") as Label
	if not score_value:
		score_value = get_node_or_null("DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/ScoreValue") as Label
	if not kills_value:
		kills_value = get_node_or_null("DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/KillsValue") as Label
	if not best_value:
		best_value = get_node_or_null("DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/BestValue") as Label
	if not retry_btn:
		retry_btn = get_node_or_null("DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/ButtonContainer/RetryButton") as Button
	if not quit_btn:
		quit_btn = get_node_or_null("DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/ButtonContainer/QuitButton") as Button
	if not sfx_player:
		sfx_player = get_node_or_null("GameOverSFX") as AudioStreamPlayer

func _get_game_state() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root.has_node("GameState"):
		return get_tree().root.get_node("GameState")
	return null

func _get_save_manager() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root.has_node("SaveManager"):
		return get_tree().root.get_node("SaveManager")
	return null

func _get_event_bus() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root.has_node("EventBus"):
		return get_tree().root.get_node("EventBus")
	return null

func _connect_signals() -> void:
	var bus = _get_event_bus()
	if bus:
		if not bus.is_connected("game_lost", Callable(self, "_on_game_lost")):
			bus.game_lost.connect(_on_game_lost)
		if not bus.is_connected("player_died", Callable(self, "_on_player_died")):
			bus.player_died.connect(_on_player_died)
			
	if retry_btn:
		if not retry_btn.pressed.is_connected(Callable(self, "_on_retry_pressed")):
			retry_btn.pressed.connect(_on_retry_pressed)
	if quit_btn:
		if not quit_btn.pressed.is_connected(Callable(self, "_on_quit_pressed")):
			quit_btn.pressed.connect(_on_quit_pressed)

func show_game_over() -> void:
	if _is_displayed:
		return
	_is_displayed = true
	_ensure_nodes()
	
	var gs = _get_game_state()
	var sm = _get_save_manager()
	
	var final_wave: int = gs.current_wave if gs else 1
	var final_score: int = gs.score if gs else 0
	var final_time: float = gs.elapsed_time if gs else 0.0
	var final_kills: int = gs.enemies_killed if gs else 0
	var prev_high_score: int = sm.high_score if sm else 0
	
	if sm:
		sm.record_run_result(final_score, final_time, false, final_kills, final_wave)
		
	if wave_value:
		wave_value.text = "WAVE %d" % final_wave
	if time_value:
		time_value.text = format_timer(final_time)
	if score_value:
		score_value.text = format_number(final_score)
	if kills_value:
		kills_value.text = format_number(final_kills)
	if best_value:
		var best_score = maxi(final_score, prev_high_score)
		best_value.text = format_number(best_score)
		
	visible = true
	if is_inside_tree() and get_tree():
		get_tree().paused = true
		
	if sfx_player and is_inside_tree():
		sfx_player.play()
		
	if retry_btn and is_inside_tree():
		retry_btn.grab_focus()
		
	game_over_shown.emit()

func _on_game_lost() -> void:
	show_game_over()

func _on_player_died() -> void:
	show_game_over()

func _on_retry_pressed() -> void:
	retry_requested.emit()
	if is_inside_tree() and get_tree():
		get_tree().paused = false
		var gs = _get_game_state()
		if gs:
			gs.reset_run()
		get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	quit_requested.emit()
	if is_inside_tree() and get_tree():
		get_tree().quit()

func format_timer(seconds: float) -> String:
	var total_sec: int = int(floor(max(0.0, seconds)))
	var mins: int = total_sec / 60
	var secs: int = total_sec % 60
	return "%02d:%02d" % [mins, secs]

func format_number(num: int) -> String:
	var s = str(num)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0 and s[i - 1] != '-':
			result = "," + result
	return result
