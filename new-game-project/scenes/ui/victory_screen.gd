class_name VictoryScreen
extends CanvasLayer

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - VICTORY MODAL
# Triggered when Wave 5 is cleared and Boss is defeated. Displays run stats and persistence.
# ==============================================================================

signal victory_shown()
signal restart_requested()
signal quit_requested()

@onready var score_value: Label = $DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/ScoreValue
@onready var time_value: Label = $DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/TimeValue
@onready var kills_value: Label = $DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/KillsValue
@onready var best_value: Label = $DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/BestValue
@onready var new_record_badge: Label = $DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/NewRecordBadge
@onready var play_again_btn: Button = $DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/ButtonContainer/PlayAgainButton
@onready var quit_btn: Button = $DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/ButtonContainer/QuitButton
@onready var sfx_player: AudioStreamPlayer = $VictorySFX

var _is_displayed: bool = false

func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_ensure_nodes()
	_connect_signals()

func _ensure_nodes() -> void:
	if not score_value:
		score_value = get_node_or_null("DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/ScoreValue") as Label
	if not time_value:
		time_value = get_node_or_null("DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/TimeValue") as Label
	if not kills_value:
		kills_value = get_node_or_null("DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/KillsValue") as Label
	if not best_value:
		best_value = get_node_or_null("DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsGrid/BestValue") as Label
	if not new_record_badge:
		new_record_badge = get_node_or_null("DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/NewRecordBadge") as Label
	if not play_again_btn:
		play_again_btn = get_node_or_null("DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/ButtonContainer/PlayAgainButton") as Button
	if not quit_btn:
		quit_btn = get_node_or_null("DimOverlay/CenterContainer/ModalPanel/MarginContainer/VBoxContainer/ButtonContainer/QuitButton") as Button
	if not sfx_player:
		sfx_player = get_node_or_null("VictorySFX") as AudioStreamPlayer

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
	if bus and not bus.is_connected("game_won", Callable(self, "_on_game_won")):
		bus.game_won.connect(_on_game_won)
		
	if play_again_btn:
		if not play_again_btn.pressed.is_connected(Callable(self, "_on_play_again_pressed")):
			play_again_btn.pressed.connect(_on_play_again_pressed)
	if quit_btn:
		if not quit_btn.pressed.is_connected(Callable(self, "_on_quit_pressed")):
			quit_btn.pressed.connect(_on_quit_pressed)

func show_victory() -> void:
	_ensure_nodes()
	_is_displayed = true
	var gs = _get_game_state()
	var sm = _get_save_manager()
	
	var final_score: int = gs.score if gs else 0
	var final_time: float = gs.elapsed_time if gs else 0.0
	var final_kills: int = gs.enemies_killed if gs else 0
	var prev_high_score: int = sm.high_score if sm else 0
	var is_new_record: bool = final_score > prev_high_score
	
	if sm:
		sm.record_run_result(final_score, final_time, true, final_kills, 5)
		
	if score_value:
		score_value.text = format_number(final_score)
	if time_value:
		time_value.text = format_timer(final_time)
	if kills_value:
		kills_value.text = format_number(final_kills)
	if best_value:
		var best_score = maxi(final_score, prev_high_score)
		best_value.text = format_number(best_score)
	if new_record_badge:
		new_record_badge.visible = is_new_record
		
	visible = true
	if is_inside_tree() and get_tree():
		get_tree().paused = true
		
	if sfx_player and is_inside_tree():
		sfx_player.play()
		
	if play_again_btn and is_inside_tree():
		play_again_btn.grab_focus()
		
	victory_shown.emit()

func _on_game_won() -> void:
	show_victory()

func _on_play_again_pressed() -> void:
	restart_requested.emit()
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
	var mins: int = int(float(total_sec) / 60.0)
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
