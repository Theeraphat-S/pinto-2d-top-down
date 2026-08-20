# res://tests/test_m7_empirical_challenger.gd
# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA — M7 EMPIRICAL CHALLENGER STRESS SUITE
# Rigorous empirical stress harness covering:
# 1. AudioManager polyphonic channel exhaustion (50 simultaneous SFX requests)
# 2. BGM ducking and restoration under rapid pause/unpause & level-up/select cycles
# 3. Procedural chiptune synthesis byte-buffer validation for all 10 audio items
# 4. Input map device 0 and keycode verification for WASD, Arrows, Pause, Select
# 5. Spawner rapid wave escalation, out-of-bounds clamping, and enemy mix budget
# 6. Spawner-to-HUD signal dispatch, wave counters, and Wave 5 Boss lifecycle
# ==============================================================================
extends "res://tests/test_framework.gd"

const AudioManagerScript = preload("res://autoload/audio_manager.gd")
const EventBusScript = preload("res://autoload/event_bus.gd")
const SpawnerScript = preload("res://scenes/world/spawner.gd")
const HUDScript = preload("res://scenes/ui/hud.gd")

var audio_mgr: Node = null

func before_each() -> void:
	if audio_mgr:
		audio_mgr.free()
	audio_mgr = AudioManagerScript.new()
	audio_mgr._ready()

func after_each() -> void:
	if audio_mgr:
		audio_mgr.free()
		audio_mgr = null

# ==============================================================================
# 1. AUDIOMANAGER POLYPHONIC EXHAUSTION STRESS (50 SIMULTANEOUS SFX REQUESTS)
# ==============================================================================

func test_audio_manager_polyphonic_exhaustion_50_requests() -> void:
	assert_not_null(audio_mgr, "AudioManager instance is valid")
	assert_eq(audio_mgr._sfx_pool.size(), 10, "SFX pool size is exactly 10")
	
	var sound_types := ["shoot", "hit", "enemy_death", "xp_gem", "player_hurt"]
	var returned_players: Array[AudioStreamPlayer] = []
	
	# Dispatch 50 simultaneous SFX requests in rapid succession
	for i in range(50):
		var snd: String = sound_types[i % sound_types.size()]
		var pitch := randf_range(0.8, 1.2)
		var vol_db := randf_range(-6.0, 2.0)
		var p: AudioStreamPlayer = audio_mgr.play_sfx(snd, pitch, vol_db)
		assert_not_null(p, "Request #%d for sound '%s' returned a valid player" % [i + 1, snd])
		assert_not_null(p.stream, "Request #%d player has assigned stream" % [i + 1])
		assert_almost_eq(p.pitch_scale, pitch, 0.001, "Request #%d player has correct pitch scale" % [i + 1])
		returned_players.append(p)
		
	assert_eq(returned_players.size(), 50, "All 50 SFX requests processed successfully")
	
	# Verify round-robin pool index wrapped around properly (50 % 10 == 0)
	assert_eq(audio_mgr._sfx_pool_index, 0, "SFX pool index properly wrapped around after 50 requests")
	
	# Verify all players in the pool are members of the 10-channel pool
	for p in returned_players:
		assert_true(audio_mgr._sfx_pool.has(p), "Returned player belongs to internal pool")
		
	# Verify player channels remain stable and no memory leaks / crashes
	for i in range(10):
		var pool_player: AudioStreamPlayer = audio_mgr._sfx_pool[i]
		assert_eq(pool_player.name, "SFXPlayer_%d" % i, "Pool player %d intact" % i)

# ==============================================================================
# 2. BGM DUCKING & RESTORATION UNDER RAPID PAUSE/UNPAUSE CYCLES
# ==============================================================================

func test_audio_manager_rapid_bgm_ducking_and_restoration_50_cycles() -> void:
	audio_mgr.play_bgm("bgm")
	assert_true(audio_mgr.is_bgm_playing(), "BGM is active before stress test")
	
	var initial_vol_db: float = audio_mgr._bgm_player.volume_db
	assert_almost_eq(initial_vol_db, -6.0, 0.01, "Initial BGM volume is -6.0 dB")
	
	# Stress test 50 rapid cycles of ducking and restoring
	for cycle in range(50):
		# Duck BGM (e.g. pause / level-up modal)
		var duck_amount := -12.0
		audio_mgr.duck_bgm(duck_amount)
		assert_true(audio_mgr._is_bgm_ducked, "Cycle #%d: BGM is ducked" % [cycle + 1])
		assert_almost_eq(audio_mgr._bgm_player.volume_db, initial_vol_db + duck_amount, 0.01,
			"Cycle #%d: BGM volume dropped to ducked level" % [cycle + 1])
		
		# Restore BGM (e.g. unpause / upgrade selected)
		audio_mgr.restore_bgm()
		assert_false(audio_mgr._is_bgm_ducked, "Cycle #%d: BGM duck flag cleared" % [cycle + 1])
		assert_almost_eq(audio_mgr._bgm_player.volume_db, initial_vol_db, 0.01,
			"Cycle #%d: BGM volume restored to initial dB" % [cycle + 1])
			
	# Stress test rapid consecutive ducks without un-ducking (idempotency check)
	audio_mgr.duck_bgm(-10.0)
	audio_mgr.duck_bgm(-15.0)
	assert_true(audio_mgr._is_bgm_ducked, "Idempotent duck retains ducked state")
	assert_almost_eq(audio_mgr._bgm_player.volume_db, initial_vol_db - 15.0, 0.01, "Latest duck dB applied")
	
	audio_mgr.restore_bgm()
	audio_mgr.restore_bgm() # Idempotent restore
	assert_false(audio_mgr._is_bgm_ducked, "Idempotent restore leaves duck flag false")
	assert_almost_eq(audio_mgr._bgm_player.volume_db, initial_vol_db, 0.01, "Volume cleanly restored")

# ==============================================================================
# 3. PROCEDURAL CHIPTUNE SYNTHESIS BYTE BUFFER VERIFICATION (ALL 10 ITEMS)
# ==============================================================================

func test_audio_manager_procedural_synthesis_all_10_items_buffer_verification() -> void:
	var items := [
		{"key": "shoot", "is_bgm": false, "min_dur": 0.05, "max_dur": 0.30},
		{"key": "hit", "is_bgm": false, "min_dur": 0.05, "max_dur": 0.30},
		{"key": "enemy_death", "is_bgm": false, "min_dur": 0.15, "max_dur": 0.60},
		{"key": "xp_gem", "is_bgm": false, "min_dur": 0.08, "max_dur": 0.40},
		{"key": "levelup", "is_bgm": false, "min_dur": 0.50, "max_dur": 2.00},
		{"key": "player_hurt", "is_bgm": false, "min_dur": 0.10, "max_dur": 0.50},
		{"key": "boss_alarm", "is_bgm": false, "min_dur": 0.80, "max_dur": 2.50},
		{"key": "victory", "is_bgm": false, "min_dur": 0.80, "max_dur": 3.00},
		{"key": "game_over", "is_bgm": false, "min_dur": 0.80, "max_dur": 3.00},
		{"key": "bgm", "is_bgm": true, "min_dur": 4.00, "max_dur": 15.00}
	]
	
	for item in items:
		var key: String = item["key"]
		var is_bgm: bool = item["is_bgm"]
		var min_dur: float = item["min_dur"]
		var max_dur: float = item["max_dur"]
		
		# Force procedural synthesis directly
		var wav: AudioStreamWAV = audio_mgr._synthesize_sound(key)
		assert_not_null(wav, "Synthesized sound '%s' is not null" % key)
		assert_eq(wav.format, AudioStreamWAV.FORMAT_16_BITS, "'%s' format is 16-bit PCM" % key)
		assert_eq(wav.mix_rate, 44100, "'%s' mix rate is 44100 Hz" % key)
		assert_false(wav.stereo, "'%s' is mono" % key)
		
		var raw_bytes: PackedByteArray = wav.data
		assert_gt(raw_bytes.size(), 0, "'%s' raw byte data is non-empty" % key)
		assert_eq(raw_bytes.size() % 2, 0, "'%s' raw byte size is even (16-bit aligned)" % key)
		
		var sample_count: int = int(float(raw_bytes.size()) / 2.0)
		var duration_sec: float = float(sample_count) / 44100.0
		assert_gte(duration_sec, min_dur, "'%s' duration (%.2fs) >= min_dur (%.2fs)" % [key, duration_sec, min_dur])
		assert_lte(duration_sec, max_dur, "'%s' duration (%.2fs) <= max_dur (%.2fs)" % [key, duration_sec, max_dur])
		
		# Inspect raw 16-bit PCM samples across buffer
		var min_sample: int = 32767
		var max_sample: int = -32768
		var non_zero_count: int = 0
		var sum_sq: float = 0.0
		
		# Check step for performance: check every 4th sample
		var step := 4
		for s_idx in range(0, sample_count, step):
			var sample_val: int = raw_bytes.decode_s16(s_idx * 2)
			if sample_val < min_sample:
				min_sample = sample_val
			if sample_val > max_sample:
				max_sample = sample_val
			if sample_val != 0:
				non_zero_count += 1
			var normalized := float(sample_val) / 32768.0
			sum_sq += normalized * normalized
			
		var inspected_count: int = int(float(sample_count + step - 1) / float(step))
		assert_gt(non_zero_count, int(float(inspected_count) / 10.0), "'%s' contains active audio data (not silence)" % key)
		assert_gte(min_sample, -32768, "'%s' min PCM sample >= -32768" % key)
		assert_lte(max_sample, 32767, "'%s' max PCM sample <= 32767" % key)
		
		var rms: float = sqrt(sum_sq / float(inspected_count))
		assert_gt(rms, 0.01, "'%s' RMS amplitude (%.3f) > 0.01 threshold" % [key, rms])
		
		# Check looping configuration
		if is_bgm:
			assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD, "BGM loop mode is LOOP_FORWARD")
			assert_eq(wav.loop_begin, 0, "BGM loop begin is 0")
			assert_eq(wav.loop_end, sample_count, "BGM loop end matches sample count")
		else:
			assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_DISABLED, "'%s' SFX loop mode is LOOP_DISABLED" % key)

# ==============================================================================
# 4. INPUT MAPPING & DEVICE 0 VERIFICATION
# ==============================================================================

func test_input_mapping_device_and_keycodes() -> void:
	# Parse project.godot input mapping configuration
	var config := ConfigFile.new()
	var err := config.load("res://project.godot")
	assert_eq(err, OK, "project.godot loaded successfully")
	
	var required_actions := ["move_left", "move_right", "move_up", "move_down", "pause", "select"]
	for action in required_actions:
		assert_true(config.has_section_key("input", action), "Input action '%s' exists in project.godot" % action)
		var action_data = config.get_value("input", action)
		assert_true(typeof(action_data) == TYPE_DICTIONARY, "Action '%s' data is a dictionary" % action)
		var events: Array = action_data.get("events", [])
		assert_gt(events.size(), 0, "Action '%s' has registered events" % action)
		
		for ev in events:
			if ev is InputEventKey:
				assert_eq(ev.device, 0, "Action '%s' key event has device == 0 (fixed from 16)" % action)
				assert_false(ev.echo, "Action '%s' key event echo is false" % action)
				
	# Check specific physical key mappings
	var left_events: Array = config.get_value("input", "move_left").get("events", [])
	var left_keys: Array[int] = []
	for ev in left_events:
		if ev is InputEventKey:
			left_keys.append(ev.physical_keycode)
	assert_has(left_keys, KEY_A, "move_left contains KEY_A (65)")
	assert_has(left_keys, KEY_LEFT, "move_left contains KEY_LEFT (4194319)")
	
	var right_events: Array = config.get_value("input", "move_right").get("events", [])
	var right_keys: Array[int] = []
	for ev in right_events:
		if ev is InputEventKey:
			right_keys.append(ev.physical_keycode)
	assert_has(right_keys, KEY_D, "move_right contains KEY_D (68)")
	assert_has(right_keys, KEY_RIGHT, "move_right contains KEY_RIGHT (4194321)")

	var up_events: Array = config.get_value("input", "move_up").get("events", [])
	var up_keys: Array[int] = []
	for ev in up_events:
		if ev is InputEventKey:
			up_keys.append(ev.physical_keycode)
	assert_has(up_keys, KEY_W, "move_up contains KEY_W (87)")
	assert_has(up_keys, KEY_UP, "move_up contains KEY_UP (4194320)")

	var down_events: Array = config.get_value("input", "move_down").get("events", [])
	var down_keys: Array[int] = []
	for ev in down_events:
		if ev is InputEventKey:
			down_keys.append(ev.physical_keycode)
	assert_has(down_keys, KEY_S, "move_down contains KEY_S (83)")
	assert_has(down_keys, KEY_DOWN, "move_down contains KEY_DOWN (4194322)")

# ==============================================================================
# 5. SPAWNER RAPID WAVE TRANSITIONS & CLAMPING STRESS
# ==============================================================================

func test_spawner_rapid_wave_transitions_and_clamping() -> void:
	var spawner := SpawnerScript.new()
	spawner.is_active = false
	
	# Test initial state
	assert_eq(spawner.get_current_wave(), 1, "Spawner defaults to Wave 1")
	
	# Rapid wave transitions 1 through 5
	for w in range(1, 6):
		spawner.set_wave(w)
		assert_eq(spawner.get_current_wave(), w, "Spawner correctly transitioned to Wave %d" % w)
		var config: Dictionary = spawner.get_wave_configs().get(w, {})
		assert_gt(config.size(), 0, "Wave %d configuration exists" % w)
		
	# Out-of-bounds boundary clamping stress
	spawner.set_wave(0)
	assert_eq(spawner.get_current_wave(), 1, "Wave 0 clamped to Wave 1")
	
	spawner.set_wave(-10)
	assert_eq(spawner.get_current_wave(), 1, "Negative wave clamped to Wave 1")
	
	spawner.set_wave(6)
	assert_eq(spawner.get_current_wave(), 5, "Wave 6 clamped to Wave 5")
	
	spawner.set_wave(999)
	assert_eq(spawner.get_current_wave(), 5, "Wave 999 clamped to Wave 5")
	
	spawner.free()

# ==============================================================================
# 6. SPAWNER TO HUD SIGNAL DISPATCH & BOSS LIFECYCLE
# ==============================================================================

func test_spawner_to_hud_signal_dispatch_and_boss_lifecycle() -> void:
	var hud_scene = load("res://scenes/ui/hud.tscn")
	assert_not_null(hud_scene, "HUD scene loaded")
	
	var hud = hud_scene.instantiate()
	assert_not_null(hud, "HUD instantiated")
	
	# Test Wave Signal Dispatch updates
	for w in range(1, 6):
		hud._on_wave_started(w, 30.0 + float(w) * 5.0)
		assert_eq(hud.current_wave, w, "HUD current_wave updated to %d" % w)
		assert_eq(hud.wave_label.text, "WAVE %d/5" % w, "HUD label reflects WAVE %d/5" % w)
		assert_eq(hud.timer_label.text, hud.format_timer(30.0 + float(w) * 5.0), "HUD timer label updated")
		
	# Test Boss Lifecycle Dispatch
	assert_false(hud.boss_active, "Boss active flag false initially")
	assert_false(hud.boss_container.visible, "Boss bar container hidden initially")
	
	# Simulate boss spawned
	var mock_boss := Node2D.new()
	mock_boss.set("boss_name", "GIGA-NULL")
	mock_boss.set("max_health", 1000.0)
	hud._on_boss_spawned(mock_boss)
	
	assert_true(hud.boss_active, "Boss active flag true after spawn")
	assert_true(hud.boss_container.visible, "Boss container visible after spawn")
	assert_has_str(hud.boss_title.text, "GIGA-NULL", "Boss title shows GIGA-NULL")
	assert_eq(hud.boss_bar.max_value, 1000.0, "Boss bar max_value is 1000")
	assert_eq(hud.boss_bar.value, 1000.0, "Boss bar value is 1000")
	
	# Simulate Boss taking damage in Phase 2 and Phase 3
	hud._on_boss_hp_changed(600.0, 1000.0)
	assert_eq(hud.boss_bar.value, 600.0, "Boss bar reflects 600 HP")
	assert_has_str(hud.boss_hp_label.text, "60%", "Boss HP percentage reflects 60%")
	
	hud._on_boss_hp_changed(150.0, 1000.0)
	assert_eq(hud.boss_bar.value, 150.0, "Boss bar reflects 150 HP")
	assert_has_str(hud.boss_hp_label.text, "15%", "Boss HP percentage reflects 15%")
	
	# Simulate Boss Defeat
	hud._on_boss_defeated()
	assert_false(hud.boss_active, "Boss active flag false after defeat")
	assert_false(hud.boss_container.visible, "Boss container hidden after defeat")
	
	mock_boss.free()
	hud.free()

# ==============================================================================
# 7. VOLUME SCALING & MUTING UNDER DUCKING COMBINATIONS
# ==============================================================================

func test_audio_manager_volume_scaling_under_duck_and_mute() -> void:
	audio_mgr.play_bgm("bgm")
	
	# Test muted state overrides all volume adjustments
	audio_mgr.set_muted(true)
	assert_true(audio_mgr.is_muted(), "Mute flag is true")
	assert_almost_eq(audio_mgr._bgm_player.volume_db, -80.0, 0.01, "Muted BGM is -80 dB")
	
	for p in audio_mgr._sfx_pool:
		assert_almost_eq(p.volume_db, -80.0, 0.01, "Muted SFX player is -80 dB")
		
	# Unmute restores baseline
	audio_mgr.set_muted(false)
	assert_false(audio_mgr.is_muted(), "Mute flag is false")
	assert_almost_eq(audio_mgr._bgm_player.volume_db, -6.0, 0.01, "Unmuted BGM returns to -6 dB")
	
	# Volume scaling: 50% linear (-6.02 dB)
	audio_mgr.set_bgm_volume(0.5)
	var expected_db := -6.0 + linear_to_db(0.5)
	assert_almost_eq(audio_mgr._bgm_player.volume_db, expected_db, 0.01, "50% BGM volume calculated accurately")
	
	# 50% linear + Ducking (-10 dB)
	audio_mgr.duck_bgm(-10.0)
	assert_almost_eq(audio_mgr._bgm_player.volume_db, expected_db - 10.0, 0.01, "Ducked 50% BGM combines linearly")
	
	audio_mgr.restore_bgm()
	assert_almost_eq(audio_mgr._bgm_player.volume_db, expected_db, 0.01, "Restored 50% BGM returns to expected dB")

# ==============================================================================
# 8. SPAWNER ENEMY MIX BUDGET & DISTRIBUTION
# ==============================================================================

func test_spawner_enemy_mix_budget_and_distribution() -> void:
	var spawner := SpawnerScript.new()
	var configs: Dictionary = spawner.get_wave_configs()
	
	# Check Wave 1: 100% slime
	var w1_mix: Dictionary = configs[1]["mix"]
	assert_almost_eq(w1_mix.get("slime", 0.0), 1.0, 0.001, "Wave 1 is 100% slime")
	
	# Check Wave 2: 60% slime, 40% bat
	var w2_mix: Dictionary = configs[2]["mix"]
	assert_almost_eq(w2_mix.get("slime", 0.0), 0.6, 0.001, "Wave 2 has 60% slime")
	assert_almost_eq(w2_mix.get("bat", 0.0), 0.4, 0.001, "Wave 2 has 40% bat")
	
	# Check Wave 3: 40% slime, 30% bat, 30% drone
	var w3_mix: Dictionary = configs[3]["mix"]
	assert_almost_eq(w3_mix.get("slime", 0.0), 0.4, 0.001, "Wave 3 has 40% slime")
	assert_almost_eq(w3_mix.get("bat", 0.0), 0.3, 0.001, "Wave 3 has 30% bat")
	assert_almost_eq(w3_mix.get("drone", 0.0), 0.3, 0.001, "Wave 3 has 30% drone")
	
	# Check Wave 4: 25% each across all 4 regular enemies
	var w4_mix: Dictionary = configs[4]["mix"]
	assert_almost_eq(w4_mix.get("slime", 0.0), 0.25, 0.001, "Wave 4 has 25% slime")
	assert_almost_eq(w4_mix.get("bat", 0.0), 0.25, 0.001, "Wave 4 has 25% bat")
	assert_almost_eq(w4_mix.get("drone", 0.0), 0.25, 0.001, "Wave 4 has 25% drone")
	assert_almost_eq(w4_mix.get("golem", 0.0), 0.25, 0.001, "Wave 4 has 25% golem")
	
	# Check Wave 5: is_boss_wave == true
	assert_true(configs[5]["is_boss_wave"], "Wave 5 is flagged as boss wave")
	
	spawner.free()
