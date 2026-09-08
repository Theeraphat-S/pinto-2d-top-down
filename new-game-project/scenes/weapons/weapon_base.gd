class_name WeaponBase
extends Node2D

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - STANDARDIZED WEAPON BASE CLASS (ADR 0001)
# Standard interface contract for all modular weapons:
# - tick(delta: float) -> void
# - fire() -> void
# - get_stats() -> Dictionary
# - Automatic GameState stat scaling & EventBus integration.
# ==============================================================================

@export var weapon_id: String = ""
@export var weapon_name: String = ""
@export var rank: int = 1:
	set(val):
		rank = clampi(val, 1, max_rank)
		_on_rank_changed()

@export var max_rank: int = 3
@export var base_damage: float = 10.0
@export var base_cooldown: float = 1.0

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

func _physics_process(delta: float) -> void:
	tick(delta)

# --- Standard Interface Contract (ADR 0001) ---

func tick(_delta: float) -> void:
	pass

func fire() -> void:
	pass

func get_stats() -> Dictionary:
	return {
		"weapon_id": weapon_id,
		"weapon_name": weapon_name,
		"rank": rank,
		"max_rank": max_rank,
		"base_damage": base_damage,
		"effective_damage": get_effective_damage(),
		"base_cooldown": base_cooldown,
		"effective_cooldown": get_effective_cooldown()
	}

# --- Shared Stat Scaling Utilities ---

func get_damage_multiplier() -> float:
	if game_state and "attack_damage" in game_state and "BASE_ATTACK_DAMAGE" in game_state:
		return game_state.attack_damage / game_state.BASE_ATTACK_DAMAGE
	return 1.0

func get_effective_damage() -> float:
	return base_damage * get_damage_multiplier()

func get_cooldown_multiplier() -> float:
	if game_state and "attack_cooldown" in game_state and "BASE_ATTACK_COOLDOWN" in game_state:
		return game_state.attack_cooldown / game_state.BASE_ATTACK_COOLDOWN
	return 1.0

func get_effective_cooldown() -> float:
	return maxf(0.05, base_cooldown * get_cooldown_multiplier())

func _on_rank_changed() -> void:
	pass
