extends Node

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - GAME STATE SINGLETON
# Manages in-memory runtime game state, player stats, XP/level curves, and scoring.
# ==============================================================================

# Runtime Game Progression
var current_wave: int = 1
var score: int = 0
var enemies_killed: int = 0
var elapsed_time: float = 0.0
var is_game_active: bool = false
var is_paused: bool = false

# Pinto Runtime Stats (Base values)
const BASE_MAX_HEALTH: float = 100.0
const BASE_MOVE_SPEED: float = 160.0
const BASE_ATTACK_DAMAGE: float = 20.0
const BASE_ATTACK_COOLDOWN: float = 0.5 # interval in seconds
const BASE_ATTACK_RANGE: float = 220.0
const BASE_PROJECTILE_COUNT: int = 1
const BASE_PROJECTILE_PIERCE: int = 1
const BASE_PROJECTILE_SPEED: float = 380.0
const BASE_MAGNET_RADIUS: float = 90.0
const BASE_HEALTH_REGEN: float = 0.0
const BASE_CRIT_CHANCE: float = 0.05
const BASE_CRIT_MULTIPLIER: float = 1.5

# Active Dynamic Stats
var max_health: float = 100.0
var current_health: float = 100.0
var move_speed: float = 160.0
var attack_damage: float = 20.0
var attack_cooldown: float = 0.5
var attack_range: float = 220.0
var projectile_count: int = 1
var projectile_pierce: int = 1
var projectile_speed: float = 380.0
var magnet_radius: float = 90.0
var health_regen: float = 0.0
var crit_chance: float = 0.05
var crit_multiplier: float = 1.5

# Level & XP Tracking
var current_level: int = 1
var current_xp: int = 0
var xp_required: int = 10
var active_upgrades: Dictionary = {} # card_id (String) -> rank (int)

func _ready() -> void:
	reset_run()
	_connect_event_bus()

func _connect_event_bus() -> void:
	if not EventBus.is_connected("enemy_killed", Callable(self, "_on_enemy_killed")):
		EventBus.enemy_killed.connect(_on_enemy_killed)
	if not EventBus.is_connected("upgrade_selected", Callable(self, "_on_upgrade_selected")):
		EventBus.upgrade_selected.connect(_on_upgrade_selected)

func _process(delta: float) -> void:
	if is_game_active and not is_paused:
		elapsed_time += delta
		
		# Passive Health Regeneration
		if health_regen > 0.0 and current_health < max_health and current_health > 0.0:
			heal(health_regen * delta)

# ==============================================================================
# XP & LEVEL CURVE FORMULA
# Formula: floor(10 + (L-1)*15 + (L-1)^2 * 5)
# ==============================================================================

func get_xp_required_for_level(level: int) -> int:
	var l_offset: float = float(max(1, level) - 1)
	return int(floor(10.0 + l_offset * 15.0 + (l_offset * l_offset) * 5.0))

func reset_run() -> void:
	current_wave = 1
	score = 0
	enemies_killed = 0
	elapsed_time = 0.0
	is_game_active = true
	is_paused = false
	
	max_health = BASE_MAX_HEALTH
	current_health = max_health
	move_speed = BASE_MOVE_SPEED
	attack_damage = BASE_ATTACK_DAMAGE
	attack_cooldown = BASE_ATTACK_COOLDOWN
	attack_range = BASE_ATTACK_RANGE
	projectile_count = BASE_PROJECTILE_COUNT
	projectile_pierce = BASE_PROJECTILE_PIERCE
	projectile_speed = BASE_PROJECTILE_SPEED
	magnet_radius = BASE_MAGNET_RADIUS
	health_regen = BASE_HEALTH_REGEN
	crit_chance = BASE_CRIT_CHANCE
	crit_multiplier = BASE_CRIT_MULTIPLIER
	
	current_level = 1
	current_xp = 0
	xp_required = get_xp_required_for_level(1)
	active_upgrades.clear()
	
	EventBus.player_health_changed.emit(current_health, max_health)
	EventBus.score_updated.emit(score)

func add_xp(amount: int) -> void:
	if amount <= 0 or not is_game_active:
		return
		
	current_xp += amount
	EventBus.xp_collected.emit(amount, current_xp, xp_required, current_level)
	
	while current_xp >= xp_required:
		current_xp -= xp_required
		current_level += 1
		xp_required = get_xp_required_for_level(current_level)
		
		var offered_cards: Array = []
		if UpgradeCatalog:
			offered_cards = UpgradeCatalog.get_random_upgrade_cards(3)
			
		EventBus.level_up_triggered.emit(current_level, offered_cards)

func take_damage(amount: float) -> void:
	if not is_game_active or current_health <= 0.0 or amount <= 0.0:
		return
		
	current_health = max(0.0, current_health - amount)
	EventBus.player_health_changed.emit(current_health, max_health)
	
	if current_health <= 0.0:
		is_game_active = false
		EventBus.player_died.emit()
		EventBus.game_lost.emit()

func heal(amount: float) -> void:
	if current_health <= 0.0 or amount <= 0.0:
		return
		
	current_health = min(max_health, current_health + amount)
	EventBus.player_health_changed.emit(current_health, max_health)
	EventBus.player_healed.emit(current_health, max_health)

func add_score(amount: int) -> void:
	if amount <= 0:
		return
	score += amount
	EventBus.score_updated.emit(score)

func record_kill(enemy_type: String = "", score_val: int = 10) -> void:
	enemies_killed += 1
	add_score(score_val)
	EventBus.enemy_killed.emit(enemy_type, score_val)

func apply_upgrade(card_id: String) -> void:
	if UpgradeCatalog:
		UpgradeCatalog.apply_card(card_id)

func _on_enemy_killed(_enemy_type: String, _score_val: int) -> void:
	# Avoid double counting if record_kill was used directly
	pass

func _on_upgrade_selected(card_id: String) -> void:
	if not active_upgrades.has(card_id):
		active_upgrades[card_id] = 1
	else:
		active_upgrades[card_id] += 1
