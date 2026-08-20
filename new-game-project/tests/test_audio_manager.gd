# res://tests/test_audio_manager.gd
# R4: Retro Chiptune Audio & SFX System Unit and Integration Tests
extends "res://tests/test_framework.gd"

const AudioManagerScript = preload("res://autoload/audio_manager.gd")
const EventBusScript = preload("res://autoload/event_bus.gd")

var audio_mgr: Node = null

func before_all() -> void:
	audio_mgr = AudioManagerScript.new()
	audio_mgr._ready()

func after_all() -> void:
	if audio_mgr:
		audio_mgr.free()
		audio_mgr = null

func before_each() -> void:
	if audio_mgr:
		audio_mgr.set_muted(false)
		audio_mgr.set_sfx_volume(1.0)
		audio_mgr.set_bgm_volume(1.0)
		audio_mgr.restore_bgm()

func test_audio_manager_singleton_and_tree_structure() -> void:
	assert_not_null(audio_mgr, "AudioManager instance is valid")
	assert_eq(audio_mgr.process_mode, Node.PROCESS_MODE_ALWAYS, "AudioManager process_mode is ALWAYS")
	
	var bgm_player: AudioStreamPlayer = audio_mgr.get_node_or_null("BGMPlayer") as AudioStreamPlayer
	assert_not_null(bgm_player, "BGMPlayer node exists")
	assert_eq(bgm_player.process_mode, Node.PROCESS_MODE_ALWAYS, "BGMPlayer process_mode is ALWAYS")
	assert_eq(bgm_player.bus, "Master", "BGMPlayer bus is Master")
	
	var ui_sfx_player: AudioStreamPlayer = audio_mgr.get_node_or_null("UISFXPlayer") as AudioStreamPlayer
	assert_not_null(ui_sfx_player, "UISFXPlayer node exists")
	assert_eq(ui_sfx_player.process_mode, Node.PROCESS_MODE_ALWAYS, "UISFXPlayer process_mode is ALWAYS")
	
	# Verify polyphonic SFX pool
	var pool_size: int = 0
	for child in audio_mgr.get_children():
		if child.name.begins_with("SFXPlayer_"):
			pool_size += 1
	assert_gte(pool_size, 8, "SFX pool contains at least 8 channels (found %d)" % pool_size)

func test_audio_stream_loading_and_fallback_for_all_10_sounds() -> void:
	var required_sounds := [
		"shoot",
		"hit",
		"enemy_death",
		"xp_gem",
		"levelup",
		"player_hurt",
		"boss_alarm",
		"victory",
		"game_over",
		"bgm"
	]
	
	for snd in required_sounds:
		var stream: AudioStream = audio_mgr.get_stream(snd)
		assert_not_null(stream, "Audio stream for '%s' is loaded/synthesized" % snd)
		assert_true(stream is AudioStreamWAV, "Audio stream for '%s' is AudioStreamWAV" % snd)
		var wav := stream as AudioStreamWAV
		assert_gt(wav.data.size(), 0, "WAV data for '%s' has non-zero byte size" % snd)

func test_audio_stream_aliases() -> void:
	var exp_stream: AudioStream = audio_mgr.get_stream("explosion")
	var death_stream: AudioStream = audio_mgr.get_stream("enemy_death")
	assert_eq(exp_stream, death_stream, "explosion and enemy_death resolve to same stream")
	
	var gem_stream: AudioStream = audio_mgr.get_stream("gem_pickup")
	var xp_stream: AudioStream = audio_mgr.get_stream("xp_gem")
	assert_eq(gem_stream, xp_stream, "gem_pickup and xp_gem resolve to same stream")
	
	var retro_bgm: AudioStream = audio_mgr.get_stream("retro_bgm")
	var bgm: AudioStream = audio_mgr.get_stream("bgm")
	assert_eq(retro_bgm, bgm, "retro_bgm and bgm resolve to same stream")

func test_procedural_chiptune_synthesis_engine() -> void:
	var dummy_samples := PackedFloat32Array([0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5])
	var wav: AudioStreamWAV = AudioManagerScript.create_wav_from_samples(dummy_samples, 44100, true)
	
	assert_not_null(wav, "create_wav_from_samples returns AudioStreamWAV")
	assert_eq(wav.format, AudioStreamWAV.FORMAT_16_BITS, "WAV format is 16-bit PCM")
	assert_eq(wav.mix_rate, 44100, "WAV mix rate is 44100 Hz")
	assert_false(wav.stereo, "WAV is mono")
	assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD, "Looping WAV has LOOP_FORWARD")
	assert_eq(wav.data.size(), dummy_samples.size() * 2, "WAV byte size is 16 bytes for 8 samples")

func test_bgm_looping_and_ducking_controls() -> void:
	var bgm_stream: AudioStreamWAV = audio_mgr.get_stream("bgm") as AudioStreamWAV
	assert_not_null(bgm_stream, "BGM stream is valid")
	assert_eq(bgm_stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "BGM stream loop_mode is LOOP_FORWARD")
	
	audio_mgr.play_bgm("bgm")
	assert_true(audio_mgr.is_bgm_playing(), "BGM is playing after play_bgm()")
	
	# Duck BGM
	audio_mgr.duck_bgm(-12.0)
	assert_true(audio_mgr._is_bgm_ducked, "BGM duck flag is true")
	
	# Restore BGM
	audio_mgr.restore_bgm()
	assert_false(audio_mgr._is_bgm_ducked, "BGM duck flag is false after restore")
	
	# Stop BGM
	audio_mgr.stop_bgm()
	assert_false(audio_mgr.is_bgm_playing(), "BGM is stopped after stop_bgm()")

func test_sfx_pool_dispatch_and_convenience_methods() -> void:
	var p1 = audio_mgr.play_sfx("shoot", 1.0, -2.0)
	assert_not_null(p1, "play_sfx('shoot') returns player node")
	assert_eq(p1.stream, audio_mgr.get_stream("shoot"), "Player has shoot stream assigned")
	
	var p2 = audio_mgr.play_sfx("hit", 1.1, 0.0)
	assert_not_null(p2, "play_sfx('hit') returns player node")
	assert_eq(p2.stream, audio_mgr.get_stream("hit"), "Player has hit stream assigned")
	
	var p_ui = audio_mgr.play_ui_sfx("levelup", 1.0, 2.0)
	assert_not_null(p_ui, "play_ui_sfx('levelup') returns UI player node")
	assert_eq(p_ui.name, "UISFXPlayer", "Returned player is UISFXPlayer")

func test_volume_and_mute_controls() -> void:
	audio_mgr.set_sfx_volume(0.6)
	assert_almost_eq(audio_mgr.get_sfx_volume(), 0.6, 0.001, "SFX volume set to 0.6")
	
	audio_mgr.set_bgm_volume(0.4)
	assert_almost_eq(audio_mgr.get_bgm_volume(), 0.4, 0.001, "BGM volume set to 0.4")
	
	# Clamp testing
	audio_mgr.set_sfx_volume(-0.5)
	assert_almost_eq(audio_mgr.get_sfx_volume(), 0.0, 0.001, "Negative SFX volume clamped to 0.0")
	
	audio_mgr.set_bgm_volume(2.5)
	assert_almost_eq(audio_mgr.get_bgm_volume(), 1.0, 0.001, "Over 1.0 BGM volume clamped to 1.0")
	
	# Mute testing
	audio_mgr.set_muted(true)
	assert_true(audio_mgr.is_muted(), "Mute flag is true")
	
	audio_mgr.set_muted(false)
	assert_false(audio_mgr.is_muted(), "Mute flag is false")

func test_event_bus_signal_routing_and_handlers() -> void:
	# Test direct handler dispatch for all game events
	audio_mgr._on_projectile_fired(Vector2(100, 100), Vector2.RIGHT)
	audio_mgr._on_enemy_hit(null, 20.0)
	audio_mgr._on_enemy_killed("slime", 50)
	audio_mgr._on_xp_collected(5, 15, 30, 1)
	
	audio_mgr._on_level_up_triggered(2, [])
	assert_true(audio_mgr._is_bgm_ducked, "Level up triggers BGM ducking")
	
	audio_mgr._on_upgrade_selected("dmg_up")
	assert_false(audio_mgr._is_bgm_ducked, "Upgrade selection restores BGM")
	
	# Hurt sound on HP drop
	audio_mgr._prev_player_health = 100.0
	audio_mgr._on_player_health_changed(75.0, 100.0)
	assert_almost_eq(audio_mgr._prev_player_health, 75.0, 0.001, "Player health tracked on damage")
	
	# Heal should not trigger hurt
	audio_mgr._on_player_health_changed(90.0, 100.0)
	assert_almost_eq(audio_mgr._prev_player_health, 90.0, 0.001, "Player health tracked on heal")
	
	audio_mgr._on_boss_spawned(null)
	audio_mgr.play_bgm("bgm")
	assert_true(audio_mgr.is_bgm_playing(), "BGM is playing")
	
	audio_mgr._on_game_lost()
	assert_false(audio_mgr.is_bgm_playing(), "Game lost stops BGM")
	
	audio_mgr._on_game_restarted()
	assert_true(audio_mgr.is_bgm_playing(), "Game restart resumes BGM")

func test_event_bus_signal_subscription_wiring() -> void:
	var eb: Node = EventBusScript.new()
	audio_mgr.connect_to_event_bus(eb)
	
	audio_mgr.restore_bgm()
	assert_false(audio_mgr._is_bgm_ducked, "BGM not ducked initially")
	
	eb.level_up_triggered.emit(2, [])
	assert_true(audio_mgr._is_bgm_ducked, "EventBus level_up_triggered signal successfully ducks BGM")
	
	eb.upgrade_selected.emit("dmg_up")
	assert_false(audio_mgr._is_bgm_ducked, "EventBus upgrade_selected signal successfully restores BGM")
	
	audio_mgr.play_bgm("bgm")
	assert_true(audio_mgr.is_bgm_playing(), "BGM is playing")
	
	eb.game_lost.emit()
	assert_false(audio_mgr.is_bgm_playing(), "EventBus game_lost signal successfully stops BGM")
	
	eb.free()
