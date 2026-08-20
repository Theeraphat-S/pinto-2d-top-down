extends Node

@warning_ignore("unused_signal")

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - GLOBAL EVENT BUS
# Centralized, decoupled signal routing for all gameplay subsystems.
# ==============================================================================

# Player & Health Signals
signal player_health_changed(current_hp: float, max_hp: float)
signal player_healed(current_hp: float, max_hp: float)
signal player_died()

# Progression & XP Signals
signal xp_collected(amount: int, current_xp: int, xp_required: int, current_level: int)
signal level_up_triggered(new_level: int, offered_cards: Array)
signal upgrade_selected(card_id: String)

# Wave & Combat Signals
signal wave_started(wave_number: int, duration_seconds: float)
signal wave_completed(wave_number: int)
signal enemy_killed(enemy_type: String, score_value: int)
signal enemy_hit(enemy: Node2D, damage: float)
signal projectile_fired(position: Vector2, direction: Vector2)

# Boss Signals
signal boss_spawned(boss_node: Node2D)
signal boss_hp_changed(current_hp: float, max_hp: float)
signal boss_phase_changed(new_phase: int)
signal boss_defeated()

# Game Lifecycle Signals
signal score_updated(new_score: int)
signal game_won()
signal game_lost()
signal game_restarted()
