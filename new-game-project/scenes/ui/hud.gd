class_name GameHUD
extends CanvasLayer

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - IN-GAME REAL-TIME HUD
# Displays player HP, XP/Level, Wave timer, Score, Kills, High Score, and Boss HP.
# ==============================================================================

@export var max_waves: int = 5

@onready var hp_bar: ProgressBar = $MarginContainer/TopLeft/HealthSection/HPBar
@onready var hp_label: Label = $MarginContainer/TopLeft/HealthSection/HPLabel
@onready var xp_bar: ProgressBar = $MarginContainer/TopLeft/XPSection/XPBar
@onready var xp_label: Label = $MarginContainer/TopLeft/XPSection/XPLabel
@onready var level_badge: Label = $MarginContainer/TopLeft/XPSection/LevelBadge/LevelText

@onready var wave_label: Label = $MarginContainer/TopCenter/WaveLabel
@onready var timer_label: Label = $MarginContainer/TopCenter/TimerLabel

@onready var boss_container: VBoxContainer = $MarginContainer/TopCenter/BossContainer
@onready var boss_title: Label = $MarginContainer/TopCenter/BossContainer/BossTitle
@onready var boss_bar: ProgressBar = $MarginContainer/TopCenter/BossContainer/BossBar
@onready var boss_hp_label: Label = $MarginContainer/TopCenter/BossContainer/BossHPLabel

@onready var score_label: Label = $MarginContainer/TopRight/ScoreLabel
@onready var kills_label: Label = $MarginContainer/TopRight/KillsLabel
@onready var best_label: Label = $MarginContainer/TopRight/BestLabel

var current_wave: int = 1
var wave_time_remaining: float = 30.0
var boss_active: bool = false

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_nodes()
	_connect_event_bus()
	_initialize_ui()

func _ensure_nodes() -> void:
	if not hp_bar:
		hp_bar = get_node_or_null("MarginContainer/TopLeft/HealthSection/HPBar") as ProgressBar
	if not hp_label:
		hp_label = get_node_or_null("MarginContainer/TopLeft/HealthSection/HPLabel") as Label
	if not xp_bar:
		xp_bar = get_node_or_null("MarginContainer/TopLeft/XPSection/XPBar") as ProgressBar
	if not xp_label:
		xp_label = get_node_or_null("MarginContainer/TopLeft/XPSection/XPLabel") as Label
	if not level_badge:
		level_badge = get_node_or_null("MarginContainer/TopLeft/XPSection/LevelBadge/LevelText") as Label
	if not wave_label:
		wave_label = get_node_or_null("MarginContainer/TopCenter/WaveLabel") as Label
	if not timer_label:
		timer_label = get_node_or_null("MarginContainer/TopCenter/TimerLabel") as Label
	if not boss_container:
		boss_container = get_node_or_null("MarginContainer/TopCenter/BossContainer") as VBoxContainer
	if not boss_title:
		boss_title = get_node_or_null("MarginContainer/TopCenter/BossContainer/BossTitle") as Label
	if not boss_bar:
		boss_bar = get_node_or_null("MarginContainer/TopCenter/BossContainer/BossBar") as ProgressBar
	if not boss_hp_label:
		boss_hp_label = get_node_or_null("MarginContainer/TopCenter/BossContainer/BossHPLabel") as Label
	if not score_label:
		score_label = get_node_or_null("MarginContainer/TopRight/ScoreLabel") as Label
	if not kills_label:
		kills_label = get_node_or_null("MarginContainer/TopRight/KillsLabel") as Label
	if not best_label:
		best_label = get_node_or_null("MarginContainer/TopRight/BestLabel") as Label

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

func _connect_event_bus() -> void:
	var bus = _get_event_bus()
	if not bus:
		return
		
	if not bus.is_connected("player_health_changed", Callable(self, "_on_player_health_changed")):
		bus.player_health_changed.connect(_on_player_health_changed)
	if not bus.is_connected("xp_collected", Callable(self, "_on_xp_collected")):
		bus.xp_collected.connect(_on_xp_collected)
	if not bus.is_connected("level_up_triggered", Callable(self, "_on_level_up_triggered")):
		bus.level_up_triggered.connect(_on_level_up_triggered)
	if not bus.is_connected("wave_started", Callable(self, "_on_wave_started")):
		bus.wave_started.connect(_on_wave_started)
	if not bus.is_connected("wave_completed", Callable(self, "_on_wave_completed")):
		bus.wave_completed.connect(_on_wave_completed)
	if not bus.is_connected("score_updated", Callable(self, "_on_score_updated")):
		bus.score_updated.connect(_on_score_updated)
	if not bus.is_connected("enemy_killed", Callable(self, "_on_enemy_killed")):
		bus.enemy_killed.connect(_on_enemy_killed)
	if not bus.is_connected("boss_spawned", Callable(self, "_on_boss_spawned")):
		bus.boss_spawned.connect(_on_boss_spawned)
	if not bus.is_connected("boss_hp_changed", Callable(self, "_on_boss_hp_changed")):
		bus.boss_hp_changed.connect(_on_boss_hp_changed)
	if not bus.is_connected("boss_defeated", Callable(self, "_on_boss_defeated")):
		bus.boss_defeated.connect(_on_boss_defeated)

func _initialize_ui() -> void:
	var gs = _get_game_state()
	var sm = _get_save_manager()
	
	if gs:
		update_health(gs.current_health, gs.max_health)
		update_xp(gs.current_xp, gs.xp_required, gs.current_level)
		update_wave(gs.current_wave)
		update_score(gs.score)
		update_kills(gs.enemies_killed)
	else:
		update_health(100.0, 100.0)
		update_xp(0, 10, 1)
		update_wave(1)
		update_score(0)
		update_kills(0)
		
	if sm:
		update_high_score(sm.high_score)
	else:
		update_high_score(0)
		
	hide_boss_bar()

func _process(delta: float) -> void:
	var gs = _get_game_state()
	if gs and gs.is_game_active and not gs.is_paused:
		# If boss is active, timer shows total survival time; otherwise countdown
		if boss_active:
			if timer_label:
				timer_label.text = format_timer(gs.elapsed_time)
		else:
			wave_time_remaining = maxf(0.0, wave_time_remaining - delta)
			if timer_label:
				timer_label.text = format_timer(wave_time_remaining)
				
		# Update dynamic displays
		if kills_label:
			kills_label.text = "KILLS: %d" % gs.enemies_killed
		if score_label:
			score_label.text = "SCORE: %s" % format_number(gs.score)

func update_health(cur_hp: float, max_hp: float) -> void:
	_ensure_nodes()
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = clampf(cur_hp, 0.0, max_hp)
	if hp_label:
		hp_label.text = "%d / %d" % [int(ceil(max(0.0, cur_hp))), int(max_hp)]

func update_xp(cur_xp: int, req_xp: int, lvl: int) -> void:
	_ensure_nodes()
	if xp_bar:
		xp_bar.max_value = max(1, req_xp)
		xp_bar.value = clamp(cur_xp, 0, req_xp)
	if xp_label:
		xp_label.text = "%d / %d XP" % [cur_xp, req_xp]
	if level_badge:
		level_badge.text = "LV.%d" % lvl

func update_wave(wave_num: int) -> void:
	_ensure_nodes()
	current_wave = wave_num
	if wave_label:
		wave_label.text = "WAVE %d/%d" % [current_wave, max_waves]

func update_score(new_score: int) -> void:
	_ensure_nodes()
	if score_label:
		score_label.text = "SCORE: %s" % format_number(new_score)
	var sm = _get_save_manager()
	if sm and new_score > sm.high_score:
		update_high_score(new_score)

func update_kills(total_kills: int) -> void:
	_ensure_nodes()
	if kills_label:
		kills_label.text = "KILLS: %d" % total_kills

func update_high_score(high_score: int) -> void:
	_ensure_nodes()
	if best_label:
		best_label.text = "BEST: %s" % format_number(high_score)

# ==============================================================================
# BOSS HEALTH BAR CONTROLS
# ==============================================================================

func show_boss_bar(title: String = "GIGA-NULL", max_hp: float = 1000.0) -> void:
	_ensure_nodes()
	boss_active = true
	if boss_container:
		boss_container.visible = true
	if boss_title:
		boss_title.text = "★ BOSS: %s ★" % title
	if boss_bar:
		boss_bar.max_value = max_hp
		boss_bar.value = max_hp
	if boss_hp_label:
		boss_hp_label.text = "%d / %d (100%%)" % [int(max_hp), int(max_hp)]

func update_boss_bar(cur_hp: float, max_hp: float) -> void:
	_ensure_nodes()
	if boss_bar:
		boss_bar.max_value = max_hp
		boss_bar.value = clampf(cur_hp, 0.0, max_hp)
	if boss_hp_label:
		var pct = int((clampf(cur_hp, 0.0, max_hp) / max(1.0, max_hp)) * 100.0)
		boss_hp_label.text = "%d / %d (%d%%)" % [int(ceil(max(0.0, cur_hp))), int(max_hp), pct]

func hide_boss_bar() -> void:
	_ensure_nodes()
	boss_active = false
	if boss_container:
		boss_container.visible = false

# ==============================================================================
# EVENT BUS SIGNAL HANDLERS
# ==============================================================================

func _on_player_health_changed(current_hp: float, max_hp: float) -> void:
	update_health(current_hp, max_hp)

func _on_xp_collected(_amt: int, current_xp: int, xp_req: int, current_lvl: int) -> void:
	update_xp(current_xp, xp_req, current_lvl)

func _on_level_up_triggered(new_lvl: int, _cards: Array) -> void:
	var gs = _get_game_state()
	var req = gs.xp_required if gs else 10
	var cur = gs.current_xp if gs else 0
	update_xp(cur, req, new_lvl)

func _on_wave_started(wave_num: int, duration_seconds: float) -> void:
	update_wave(wave_num)
	wave_time_remaining = duration_seconds
	if timer_label:
		timer_label.text = format_timer(wave_time_remaining)

func _on_wave_completed(wave_num: int) -> void:
	update_wave(min(wave_num + 1, max_waves))

func _on_score_updated(new_score: int) -> void:
	update_score(new_score)

func _on_enemy_killed(_type: String, _score_val: int) -> void:
	var gs = _get_game_state()
	if gs:
		update_kills(gs.enemies_killed)

func _on_boss_spawned(boss_node: Node2D) -> void:
	var b_name = "GIGA-NULL"
	var b_hp = 1000.0
	if boss_node and "boss_name" in boss_node:
		b_name = boss_node.boss_name
	if boss_node and "max_health" in boss_node:
		b_hp = boss_node.max_health
	show_boss_bar(b_name, b_hp)

func _on_boss_hp_changed(current_hp: float, max_hp: float) -> void:
	update_boss_bar(current_hp, max_hp)

func _on_boss_defeated() -> void:
	hide_boss_bar()

# ==============================================================================
# FORMATTING UTILITIES
# ==============================================================================

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
