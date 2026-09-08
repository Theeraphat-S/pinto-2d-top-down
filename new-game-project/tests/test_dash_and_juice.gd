# res://tests/test_dash_and_juice.gd
# Milestone M8: Tests for Active Dash, Invulnerability, Screen Shake & Particle Juice
extends "res://tests/test_framework.gd"

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")
const DEATH_BURST_SCENE = preload("res://scenes/effects/death_burst.tscn")
const AudioManagerScript = preload("res://autoload/audio_manager.gd")
const EventBusScript = preload("res://autoload/event_bus.gd")

func _get_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree

func test_event_bus_signals_exist() -> void:
	var tree := _get_tree()
	var eb: Node = null
	if tree and tree.root.has_node("EventBus"):
		eb = tree.root.get_node("EventBus")
	else:
		eb = EventBusScript.new()
		
	assert_not_null(eb, "EventBus instance must exist")
	assert_true(eb.has_signal("player_dashed"), "EventBus has player_dashed signal")
	assert_true(eb.has_signal("screen_shake_requested"), "EventBus has screen_shake_requested signal")
	assert_true(eb.has_signal("hit_stop_requested"), "EventBus has hit_stop_requested signal")
	
	if not (tree and tree.root.has_node("EventBus")):
		eb.free()

func test_dash_initial_state() -> void:
	var player = PLAYER_SCENE.instantiate()
	assert_not_null(player, "Player scene must instantiate")
	assert_false(player.is_dashing, "Player is not dashing initially")
	assert_true(player.can_dash(), "Player can dash initially")
	assert_almost_eq(player.dash_cooldown_timer, 0.0, 0.001, "Cooldown timer starts at 0")
	assert_almost_eq(player.get_dash_cooldown_progress(), 0.0, 0.001, "Cooldown progress is 0.0")
	player.free()

func test_start_dash_activation() -> void:
	var player = PLAYER_SCENE.instantiate()
	var tree := _get_tree()
	if tree:
		tree.root.add_child(player)
	
	player.start_dash(Vector2.RIGHT)
	assert_true(player.is_dashing, "Player is_dashing is true after start_dash")
	assert_true(player.is_invulnerable, "Player is_invulnerable is true during dash")
	assert_almost_eq(player.dash_timer, player.DASH_DURATION, 0.01, "Dash timer initialized to duration")
	assert_almost_eq(player.dash_cooldown_timer, player.DASH_COOLDOWN, 0.01, "Dash cooldown initialized to cooldown")
	assert_false(player.can_dash(), "Player cannot dash again while already dashing")
	
	if player.get_parent():
		player.get_parent().remove_child(player)
	player.free()

func test_dash_invulnerability_against_damage() -> void:
	var player = PLAYER_SCENE.instantiate()
	var tree := _get_tree()
	if tree:
		tree.root.add_child(player)
	
	var gs = tree.root.get_node_or_null("GameState") if tree else null
	if gs:
		gs.reset_run()
		var start_hp = gs.current_health
		player.start_dash(Vector2.LEFT)
		player.take_damage(30.0)
		assert_eq(gs.current_health, start_hp, "Player takes zero damage during dash invulnerability")
	else:
		player.start_dash(Vector2.LEFT)
		assert_true(player.is_dashing, "Player is dashing")
		
	if player.get_parent():
		player.get_parent().remove_child(player)
	player.free()

func test_dash_cooldown_decay_and_progress() -> void:
	var player = PLAYER_SCENE.instantiate()
	var tree := _get_tree()
	if tree:
		tree.root.add_child(player)
	
	player.start_dash(Vector2.DOWN)
	var prog = player.get_dash_cooldown_progress()
	assert_gte(prog, 0.95, "Cooldown progress is nearly 1.0 immediately after dash")
	
	# Simulate 1.0s delta
	player.dash_cooldown_timer = maxf(0.0, player.dash_cooldown_timer - 1.0)
	var prog_after = player.get_dash_cooldown_progress()
	assert_lt(prog_after, prog, "Cooldown progress decreases after time elapsed")
	
	if player.get_parent():
		player.get_parent().remove_child(player)
	player.free()

func test_audio_manager_dash_sfx() -> void:
	var am = AudioManagerScript.new()
	assert_not_null(am, "AudioManager instance can be created")
	var stream = am.get_stream("dash")
	assert_not_null(stream, "Dash sound stream must be synthesized or loaded")
	am.free()

func test_death_burst_scene_structure() -> void:
	var burst = DEATH_BURST_SCENE.instantiate()
	assert_not_null(burst, "DeathBurst scene must instantiate")
	assert_true(burst is CPUParticles2D, "DeathBurst must be a CPUParticles2D")
	assert_true(burst.one_shot, "DeathBurst must be one_shot")
	assert_almost_eq(burst.explosiveness, 1.0, 0.001, "DeathBurst explosiveness is 1.0")
	burst.free()
