extends Node

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - UPGRADE CATALOG SINGLETON
# Defines all 10 upgrade card definitions, weighted drafting, and stat modifiers.
# ==============================================================================

# Rarity Constants
enum Rarity { COMMON = 0, RARE = 1, EPIC = 2, LEGENDARY = 3 }

var _cards: Dictionary = {}

var game_state: Node:
	get:
		if is_inside_tree() and get_tree() and get_tree().root.has_node("GameState"):
			return get_tree().root.get_node("GameState")
		return null

var event_bus: Node:
	get:
		if is_inside_tree() and get_tree() and get_tree().root.has_node("EventBus"):
			return get_tree().root.get_node("EventBus")
		return null

func _ready() -> void:
	_register_all_cards()

func _register_all_cards() -> void:
	_cards.clear()
	
	_add_card({
		"id": "dmg_up",
		"title": "Power Amp",
		"description": "+20% Attack Damage",
		"rarity": Rarity.COMMON,
		"weight": 100,
		"max_rank": 5,
		"icon": "res://assets/ui/icons/icon_damage.png",
		"apply_fn": Callable(self, "_apply_dmg_up")
	})
	
	_add_card({
		"id": "atk_spd",
		"title": "Quick Reflexes",
		"description": "+20% Attack Speed (-20% Cooldown)",
		"rarity": Rarity.COMMON,
		"weight": 100,
		"max_rank": 5,
		"icon": "res://assets/ui/icons/icon_attack_speed.png",
		"apply_fn": Callable(self, "_apply_atk_spd")
	})
	
	_add_card({
		"id": "mov_spd",
		"title": "Swift Paws",
		"description": "+15% Movement Speed",
		"rarity": Rarity.COMMON,
		"weight": 100,
		"max_rank": 5,
		"icon": "res://assets/ui/icons/icon_move_speed.png",
		"apply_fn": Callable(self, "_apply_mov_spd")
	})
	
	_add_card({
		"id": "max_hp",
		"title": "Vitality Battery",
		"description": "+25 Max HP & Heal +25 HP",
		"rarity": Rarity.COMMON,
		"weight": 100,
		"max_rank": 5,
		"icon": "res://assets/ui/icons/icon_max_hp.png",
		"apply_fn": Callable(self, "_apply_max_hp")
	})
	
	_add_card({
		"id": "multi_shot",
		"title": "Twin Shot",
		"description": "+1 Projectile per volley",
		"rarity": Rarity.RARE,
		"weight": 60,
		"max_rank": 3,
		"icon": "res://assets/ui/icons/icon_multishot.png",
		"apply_fn": Callable(self, "_apply_multi_shot")
	})
	
	_add_card({
		"id": "pierce",
		"title": "Drill Arrow",
		"description": "+1 Projectile Pierce",
		"rarity": Rarity.RARE,
		"weight": 60,
		"max_rank": 3,
		"icon": "res://assets/ui/icons/icon_pierce.png",
		"apply_fn": Callable(self, "_apply_pierce")
	})
	
	_add_card({
		"id": "range",
		"title": "Sensor Array",
		"description": "+25% Attack & Target Range",
		"rarity": Rarity.COMMON,
		"weight": 80,
		"max_rank": 4,
		"icon": "res://assets/ui/icons/icon_range.png",
		"apply_fn": Callable(self, "_apply_range")
	})
	
	_add_card({
		"id": "magnet",
		"title": "Magnetic Bell",
		"description": "+40% XP Gem Magnet Radius",
		"rarity": Rarity.COMMON,
		"weight": 80,
		"max_rank": 4,
		"icon": "res://assets/ui/icons/icon_magnet.png",
		"apply_fn": Callable(self, "_apply_magnet")
	})
	
	_add_card({
		"id": "regen",
		"title": "Nano Repair",
		"description": "+1.0 HP/sec Health Regen",
		"rarity": Rarity.RARE,
		"weight": 50,
		"max_rank": 3,
		"icon": "res://assets/ui/icons/icon_regen.png",
		"apply_fn": Callable(self, "_apply_regen")
	})
	
	_add_card({
		"id": "crit",
		"title": "Targeting AI",
		"description": "+10% Crit Chance & +0.25x Crit Multiplier",
		"rarity": Rarity.RARE,
		"weight": 50,
		"max_rank": 4,
		"icon": "res://assets/ui/icons/icon_crit.png",
		"apply_fn": Callable(self, "_apply_crit")
	})
	
	_add_card({
		"id": "weapon_plasma",
		"title": "Orbiting Plasma",
		"description": "Summon rotating plasma spheres to damage contacting foes",
		"rarity": Rarity.RARE,
		"weight": 55,
		"max_rank": 3,
		"icon": "res://assets/ui/icons/icon_multishot.png",
		"apply_fn": Callable(self, "_apply_weapon_plasma")
	})
	
	_add_card({
		"id": "weapon_thunder",
		"title": "Thunder Strike",
		"description": "Call down lightning bolts on nearby enemies periodically",
		"rarity": Rarity.RARE,
		"weight": 55,
		"max_rank": 3,
		"icon": "res://assets/ui/icons/icon_attack_speed.png",
		"apply_fn": Callable(self, "_apply_weapon_thunder")
	})

func _add_card(card: Dictionary) -> void:
	_cards[card.id] = card

func get_card(card_id: String) -> Dictionary:
	if _cards.has(card_id):
		return _cards[card_id]
	return {}

func get_all_cards() -> Array:
	return _cards.values()

# ==============================================================================
# WEIGHTED RANDOM DRAFT SELECTION (NON-DUPLICATE)
# ==============================================================================

func get_random_upgrade_cards(count: int = 3) -> Array[Dictionary]:
	var eligible: Array[Dictionary] = []
	
	for card in _cards.values():
		var current_rank: int = 0
		if game_state and game_state.active_upgrades.has(card.id):
			current_rank = game_state.active_upgrades[card.id]
			
		if current_rank < card.max_rank:
			var card_copy: Dictionary = card.duplicate()
			card_copy["current_rank"] = current_rank
			card_copy["next_rank"] = current_rank + 1
			eligible.append(card_copy)
			
	var selected: Array[Dictionary] = []
	var pool := eligible.duplicate()
	var target_count := mini(count, pool.size())
	
	while selected.size() < target_count and not pool.is_empty():
		# Calculate total weight
		var total_weight: int = 0
		for c in pool:
			total_weight += int(c.get("weight", 50))
			
		var roll := randi_range(1, total_weight)
		var cumulative := 0
		var chosen_idx := -1
		
		for i in range(pool.size()):
			cumulative += int(pool[i].get("weight", 50))
			if roll <= cumulative:
				chosen_idx = i
				break
				
		if chosen_idx >= 0 and chosen_idx < pool.size():
			selected.append(pool[chosen_idx])
			pool.remove_at(chosen_idx)
			
	# If no upgrades left at all, offer fallback emergency heal
	if selected.is_empty():
		selected.append({
			"id": "emergency_heal",
			"title": "Emergency Bento",
			"description": "Restore +35 HP",
			"rarity": Rarity.COMMON,
			"weight": 10,
			"max_rank": 999,
			"current_rank": 1,
			"next_rank": 1,
			"icon": "res://assets/ui/icons/icon_max_hp.png",
			"apply_fn": Callable(self, "_apply_emergency_heal")
		})
		
	return selected

# ==============================================================================
# CARD APPLICATION CALLBACKS
# ==============================================================================

func apply_card(card_id: String) -> void:
	if _cards.has(card_id):
		var card: Dictionary = _cards[card_id]
		if card.has("apply_fn") and card.apply_fn.is_valid():
			card.apply_fn.call()
		if event_bus:
			event_bus.upgrade_selected.emit(card_id)
	elif card_id == "emergency_heal":
		_apply_emergency_heal()
		if event_bus:
			event_bus.upgrade_selected.emit(card_id)

func _apply_dmg_up() -> void:
	if game_state:
		game_state.attack_damage += game_state.BASE_ATTACK_DAMAGE * 0.20

func _apply_atk_spd() -> void:
	if game_state:
		# Reduce interval (increase attacks/sec) by 20%
		game_state.attack_cooldown = maxf(0.08, game_state.attack_cooldown * 0.80)

func _apply_mov_spd() -> void:
	if game_state:
		game_state.move_speed += game_state.BASE_MOVE_SPEED * 0.15

func _apply_max_hp() -> void:
	if game_state:
		game_state.max_health += 25.0
		game_state.heal(25.0)

func _apply_multi_shot() -> void:
	if game_state:
		game_state.projectile_count += 1

func _apply_pierce() -> void:
	if game_state:
		game_state.projectile_pierce += 1

func _apply_range() -> void:
	if game_state:
		game_state.attack_range += game_state.BASE_ATTACK_RANGE * 0.25

func _apply_magnet() -> void:
	if game_state:
		game_state.magnet_radius += game_state.BASE_MAGNET_RADIUS * 0.40

func _apply_regen() -> void:
	if game_state:
		game_state.health_regen += 1.0

func _apply_crit() -> void:
	if game_state:
		game_state.crit_chance += 0.10
		game_state.crit_multiplier += 0.25

func _apply_emergency_heal() -> void:
	if game_state:
		game_state.heal(35.0)

func _apply_weapon_plasma() -> void:
	pass

func _apply_weapon_thunder() -> void:
	pass
