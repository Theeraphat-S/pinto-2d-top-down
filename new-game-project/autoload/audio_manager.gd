extends Node

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - RETRO CHIPTUNE AUDIO MANAGER
# Centralized polyphonic audio engine, dedicated BGM/UI channels, EventBus hooks,
# and procedural 16-bit PCM retro chiptune waveform synthesis.
# ==============================================================================

const SFX_POOL_SIZE: int = 10
const DEFAULT_BGM_DB: float = -6.0
const SAMPLE_RATE: int = 44100

# Volume & Mute State
var _sfx_volume: float = 1.0 # 0.0 to 1.0 linear
var _bgm_volume: float = 1.0 # 0.0 to 1.0 linear
var _is_muted: bool = false
var _is_bgm_ducked: bool = false
var _is_bgm_playing: bool = false
var _bgm_duck_db: float = -10.0

# Audio Players
var _bgm_player: AudioStreamPlayer
var _ui_sfx_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0

# Cached Audio Streams
var _audio_cache: Dictionary = {}

# Entity Health Tracking for Hurt Audio
var _prev_player_health: float = 100.0

# Audio File Mapping
const SOUND_PATHS: Dictionary = {
	"shoot": "res://assets/sfx/shoot.wav",
	"hit": "res://assets/sfx/hit.wav",
	"enemy_death": "res://assets/sfx/explosion.wav",
	"explosion": "res://assets/sfx/explosion.wav",
	"xp_gem": "res://assets/sfx/gem_pickup.wav",
	"gem_pickup": "res://assets/sfx/gem_pickup.wav",
	"levelup": "res://assets/sfx/levelup.wav",
	"player_hurt": "res://assets/sfx/player_hurt.wav",
	"boss_alarm": "res://assets/sfx/boss_alarm.wav",
	"victory": "res://assets/sfx/victory.wav",
	"game_over": "res://assets/sfx/game_over.wav",
	"bgm": "res://assets/sfx/bgm.wav",
	"retro_bgm": "res://assets/sfx/bgm.wav"
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()
	_preload_or_synthesize_all()
	_connect_event_bus()
	
	# Start retro BGM if game is starting
	play_bgm("bgm")

# ==============================================================================
# 1. PLAYER & CHANNEL INITIALIZATION
# ==============================================================================

func _setup_audio_players() -> void:
	# 1. Dedicated BGM Player
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = "Master"
	_bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_bgm_player.volume_db = DEFAULT_BGM_DB
	add_child(_bgm_player)
	
	# 2. Dedicated UI SFX Player (plays during pause menus)
	_ui_sfx_player = AudioStreamPlayer.new()
	_ui_sfx_player.name = "UISFXPlayer"
	_ui_sfx_player.bus = "Master"
	_ui_sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui_sfx_player)
	
	# 3. Polyphonic SFX Pool (10 channels)
	_sfx_pool.clear()
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = "Master"
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(player)
		_sfx_pool.append(player)

# ==============================================================================
# 2. EVENTBUS SIGNAL INTEGRATION
# ==============================================================================

func _connect_event_bus() -> void:
	if not is_inside_tree():
		return
	var eb = get_node_or_null("/root/EventBus")
	if eb:
		connect_to_event_bus(eb)

func connect_to_event_bus(eb: Object) -> void:
	if not eb:
		return
		
	if eb.has_signal("projectile_fired") and not eb.projectile_fired.is_connected(_on_projectile_fired):
		eb.projectile_fired.connect(_on_projectile_fired)
	if eb.has_signal("enemy_hit") and not eb.enemy_hit.is_connected(_on_enemy_hit):
		eb.enemy_hit.connect(_on_enemy_hit)
	if eb.has_signal("enemy_killed") and not eb.enemy_killed.is_connected(_on_enemy_killed):
		eb.enemy_killed.connect(_on_enemy_killed)
	if eb.has_signal("xp_collected") and not eb.xp_collected.is_connected(_on_xp_collected):
		eb.xp_collected.connect(_on_xp_collected)
	if eb.has_signal("level_up_triggered") and not eb.level_up_triggered.is_connected(_on_level_up_triggered):
		eb.level_up_triggered.connect(_on_level_up_triggered)
	if eb.has_signal("upgrade_selected") and not eb.upgrade_selected.is_connected(_on_upgrade_selected):
		eb.upgrade_selected.connect(_on_upgrade_selected)
	if eb.has_signal("player_health_changed") and not eb.player_health_changed.is_connected(_on_player_health_changed):
		eb.player_health_changed.connect(_on_player_health_changed)
	if eb.has_signal("player_died") and not eb.player_died.is_connected(_on_player_died):
		eb.player_died.connect(_on_player_died)
	if eb.has_signal("boss_spawned") and not eb.boss_spawned.is_connected(_on_boss_spawned):
		eb.boss_spawned.connect(_on_boss_spawned)
	if eb.has_signal("game_won") and not eb.game_won.is_connected(_on_game_won):
		eb.game_won.connect(_on_game_won)
	if eb.has_signal("game_lost") and not eb.game_lost.is_connected(_on_game_lost):
		eb.game_lost.connect(_on_game_lost)
	if eb.has_signal("wave_started") and not eb.wave_started.is_connected(_on_wave_started):
		eb.wave_started.connect(_on_wave_started)
	if eb.has_signal("game_restarted") and not eb.game_restarted.is_connected(_on_game_restarted):
		eb.game_restarted.connect(_on_game_restarted)

func _on_projectile_fired(_position: Vector2, _direction: Vector2) -> void:
	play_shoot()

func _on_enemy_hit(_enemy: Node2D, _damage: float) -> void:
	play_hit()

func _on_enemy_killed(enemy_type: String, _score: int) -> void:
	play_enemy_death(enemy_type)

func _on_xp_collected(_amount: int, _current_xp: int, _xp_req: int, _level: int) -> void:
	play_xp_gem()

func _on_level_up_triggered(_new_level: int, _cards: Array) -> void:
	duck_bgm(-12.0)
	play_levelup()

func _on_upgrade_selected(_card_id: String) -> void:
	play_ui_select()
	restore_bgm()

func _on_player_health_changed(current_hp: float, _max_hp: float) -> void:
	if current_hp < _prev_player_health and current_hp > 0.0:
		play_player_hurt()
	_prev_player_health = current_hp

func _on_player_died() -> void:
	stop_bgm()
	play_game_over()

func _on_game_lost() -> void:
	stop_bgm()
	play_game_over()

func _on_boss_spawned(_boss: Node2D) -> void:
	play_boss_alarm()

func _on_game_won() -> void:
	stop_bgm()
	play_victory()

func _on_wave_started(_wave: int, _duration: float) -> void:
	if not is_bgm_playing():
		play_bgm("bgm")

func _on_game_restarted() -> void:
	_prev_player_health = 100.0
	restore_bgm()
	play_bgm("bgm")

# ==============================================================================
# 3. PUBLIC PLAYBACK API
# ==============================================================================

func play_sfx(sound_name: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> AudioStreamPlayer:
	if _sfx_pool.is_empty():
		return null
		
	var stream := get_stream(sound_name)
	if not stream:
		return null
		
	var player := _get_next_sfx_player()
	player.stream = stream
	player.pitch_scale = pitch_scale
	
	if _is_muted or _sfx_volume <= 0.001:
		player.volume_db = -80.0
	else:
		player.volume_db = volume_db + linear_to_db(_sfx_volume)
		
	if player.is_inside_tree():
		player.play()
	return player

func play_ui_sfx(sound_name: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> AudioStreamPlayer:
	if not _ui_sfx_player:
		return null
	var stream := get_stream(sound_name)
	if not stream:
		return null
	_ui_sfx_player.stream = stream
	_ui_sfx_player.pitch_scale = pitch_scale
	if _is_muted or _sfx_volume <= 0.001:
		_ui_sfx_player.volume_db = -80.0
	else:
		_ui_sfx_player.volume_db = volume_db + linear_to_db(_sfx_volume)
	if _ui_sfx_player.is_inside_tree():
		_ui_sfx_player.play()
	return _ui_sfx_player

func play_bgm(bgm_name: String = "bgm", volume_db: float = DEFAULT_BGM_DB) -> void:
	if not _bgm_player:
		return
	var stream := get_stream(bgm_name)
	if not stream:
		return
		
	if _bgm_player.stream != stream or not _is_bgm_playing:
		_bgm_player.stream = stream
		_update_bgm_volume(volume_db)
		_is_bgm_playing = true
		if _bgm_player.is_inside_tree():
			_bgm_player.play()

func stop_bgm() -> void:
	_is_bgm_playing = false
	if _bgm_player and _bgm_player.is_inside_tree():
		_bgm_player.stop()

func is_bgm_playing() -> bool:
	if _bgm_player and _bgm_player.is_inside_tree():
		return _bgm_player.playing
	return _is_bgm_playing

func duck_bgm(db_drop: float = -10.0) -> void:
	_is_bgm_ducked = true
	_bgm_duck_db = db_drop
	_update_bgm_volume()

func restore_bgm() -> void:
	_is_bgm_ducked = false
	_update_bgm_volume()

func set_sfx_volume(linear_val: float) -> void:
	_sfx_volume = clampf(linear_val, 0.0, 1.0)
	_update_all_volumes()

func set_bgm_volume(linear_val: float) -> void:
	_bgm_volume = clampf(linear_val, 0.0, 1.0)
	_update_bgm_volume()

func set_muted(muted: bool) -> void:
	_is_muted = muted
	_update_all_volumes()

func is_muted() -> bool:
	return _is_muted

func get_sfx_volume() -> float:
	return _sfx_volume

func get_bgm_volume() -> float:
	return _bgm_volume

# --- Quick Convenience Callbacks ---

func play_shoot() -> void:
	var pitch := randf_range(0.95, 1.05)
	play_sfx("shoot", pitch, -2.0)

func play_hit() -> void:
	var pitch := randf_range(0.92, 1.08)
	play_sfx("hit", pitch, 0.0)

func play_enemy_death(_enemy_type: String = "") -> void:
	var pitch := randf_range(0.90, 1.10)
	play_sfx("enemy_death", pitch, 1.0)

func play_xp_gem() -> void:
	var pitch := randf_range(0.96, 1.04)
	play_sfx("xp_gem", pitch, -3.0)

func play_levelup() -> void:
	play_ui_sfx("levelup", 1.0, 2.0)

func play_player_hurt() -> void:
	var pitch := randf_range(0.95, 1.05)
	play_sfx("player_hurt", pitch, 2.0)

func play_boss_alarm() -> void:
	play_ui_sfx("boss_alarm", 1.0, 1.0)

func play_victory() -> void:
	play_ui_sfx("victory", 1.0, 2.0)

func play_game_over() -> void:
	play_ui_sfx("game_over", 1.0, 2.0)

func play_ui_select() -> void:
	play_ui_sfx("xp_gem", 1.2, 0.0)

# ==============================================================================
# 4. INTERNAL CHANNEL MANAGEMENT
# ==============================================================================

func _get_next_sfx_player() -> AudioStreamPlayer:
	# First search for any player that is currently not playing
	for p in _sfx_pool:
		if not p.playing:
			return p
	# If all are busy, cycle through round-robin to steal the oldest
	var p = _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % _sfx_pool.size()
	return p

func _update_all_volumes() -> void:
	_update_bgm_volume()
	for p in _sfx_pool:
		if _is_muted or _sfx_volume <= 0.001:
			p.volume_db = -80.0
		else:
			p.volume_db = linear_to_db(_sfx_volume)

func _update_bgm_volume(base_db: float = DEFAULT_BGM_DB) -> void:
	if not _bgm_player:
		return
	if _is_muted or _bgm_volume <= 0.001:
		_bgm_player.volume_db = -80.0
	else:
		var duck := _bgm_duck_db if _is_bgm_ducked else 0.0
		_bgm_player.volume_db = base_db + linear_to_db(_bgm_volume) + duck

# ==============================================================================
# 5. AUDIO STREAM RESOURCE RETRIEVAL & SYNTHESIS FALLBACK
# ==============================================================================

func get_stream(sound_name: String) -> AudioStream:
	var key := sound_name.to_lower()
	if _audio_cache.has(key):
		return _audio_cache[key]
		
	var path: String = SOUND_PATHS.get(key, "")
	var stream: AudioStream = null
	
	# 1. Try loading pre-baked WAV asset
	if path != "" and ResourceLoader.exists(path):
		stream = load(path) as AudioStream
		
	# 2. If missing or null, synthesize procedurally
	if stream == null:
		stream = _synthesize_sound(key)
		
	# Configure loop forward if stream is BGM
	if stream is AudioStreamWAV and (key == "bgm" or key == "retro_bgm"):
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.data.size() / 2.0)
		
	if stream:
		_audio_cache[key] = stream
		# Also alias alternative keys
		if key == "shoot": _audio_cache["shoot"] = stream
		elif key == "hit": _audio_cache["hit"] = stream
		elif key == "enemy_death" or key == "explosion":
			_audio_cache["enemy_death"] = stream
			_audio_cache["explosion"] = stream
		elif key == "xp_gem" or key == "gem_pickup":
			_audio_cache["xp_gem"] = stream
			_audio_cache["gem_pickup"] = stream
		elif key == "bgm" or key == "retro_bgm":
			_audio_cache["bgm"] = stream
			_audio_cache["retro_bgm"] = stream
			
	return stream

func _preload_or_synthesize_all() -> void:
	for name_key in SOUND_PATHS.keys():
		get_stream(name_key)

# ==============================================================================
# 6. PROCEDURAL 16-BIT PCM CHIPTUNE SYNTHESIS ENGINE
# ==============================================================================

static func create_wav_from_samples(samples: PackedFloat32Array, sample_rate: int = SAMPLE_RATE, loop: bool = false) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	
	var num_samples := samples.size()
	var byte_data := PackedByteArray()
	byte_data.resize(num_samples * 2)
	for i in range(num_samples):
		var s := clampf(samples[i], -1.0, 1.0)
		var pcm := int(round(s * 32767.0))
		byte_data.encode_s16(i * 2, pcm)
		
	wav.data = byte_data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = num_samples
	else:
		wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav

static func _square_wave(phase: float, duty: float = 0.5) -> float:
	return 1.0 if fmod(phase / TAU, 1.0) < duty else -1.0

static func _saw_wave(phase: float) -> float:
	return 2.0 * fmod(phase / TAU, 1.0) - 1.0

static func _triangle_wave(phase: float) -> float:
	var t := fmod(phase / TAU, 1.0)
	return (4.0 * t - 1.0) if t < 0.5 else (3.0 - 4.0 * t)

func _synthesize_sound(key: String) -> AudioStreamWAV:
	match key:
		"shoot":
			return create_wav_from_samples(_synth_shoot(), SAMPLE_RATE, false)
		"hit":
			return create_wav_from_samples(_synth_hit(), SAMPLE_RATE, false)
		"enemy_death", "explosion":
			return create_wav_from_samples(_synth_explosion(), SAMPLE_RATE, false)
		"xp_gem", "gem_pickup":
			return create_wav_from_samples(_synth_gem_pickup(), SAMPLE_RATE, false)
		"levelup":
			return create_wav_from_samples(_synth_levelup(), SAMPLE_RATE, false)
		"player_hurt":
			return create_wav_from_samples(_synth_player_hurt(), SAMPLE_RATE, false)
		"boss_alarm":
			return create_wav_from_samples(_synth_boss_alarm(), SAMPLE_RATE, false)
		"game_over":
			return create_wav_from_samples(_synth_game_over(), SAMPLE_RATE, false)
		"victory":
			return create_wav_from_samples(_synth_victory(), SAMPLE_RATE, false)
		"bgm", "retro_bgm":
			return create_wav_from_samples(_synth_retro_bgm(), SAMPLE_RATE, true)
		_:
			return create_wav_from_samples(_synth_shoot(), SAMPLE_RATE, false)

func _synth_shoot() -> PackedFloat32Array:
	var duration := 0.10
	var count := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var freq := lerpf(920.0, 220.0, progress)
		phase += freq * (TAU / float(SAMPLE_RATE))
		var env := (1.0 - progress) * (1.0 - progress)
		samples[i] = _square_wave(phase, 0.5) * env * 0.65
	return samples

func _synth_hit() -> PackedFloat32Array:
	var duration := 0.08
	var count := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var freq := lerpf(180.0, 50.0, progress)
		phase += freq * (TAU / float(SAMPLE_RATE))
		var noise := randf_range(-1.0, 1.0)
		var env := 1.0 - progress
		var sq := _square_wave(phase, 0.5)
		samples[i] = (sq * 0.45 + noise * 0.55) * env * 0.75
	return samples

func _synth_explosion() -> PackedFloat32Array:
	var duration := 0.30
	var count := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var freq := lerpf(300.0, 35.0, progress)
		phase += freq * (TAU / float(SAMPLE_RATE))
		var noise := randf_range(-1.0, 1.0)
		var env := (1.0 - progress) * (1.0 - progress)
		var sq := _square_wave(phase, 0.5)
		samples[i] = (sq * 0.4 + noise * 0.6) * env * 0.85
	return samples

func _synth_gem_pickup() -> PackedFloat32Array:
	var duration := 0.15
	var count := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var notes := [1046.50, 1318.51, 1567.98] # C6, E6, G6
	var note_dur := duration / float(notes.size())
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var note_idx := clampi(int(t / note_dur), 0, notes.size() - 1)
		var note_t := fmod(t, note_dur)
		var note_progress := note_t / note_dur
		var env := (1.0 - note_progress * 0.8)
		var freq: float = notes[note_idx]
		phase += freq * (TAU / float(SAMPLE_RATE))
		samples[i] = _square_wave(phase, 0.25) * env * 0.65
	return samples

func _synth_levelup() -> PackedFloat32Array:
	var duration := 0.90
	var count := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var melody := [523.25, 659.25, 783.99, 1046.50] # C5, E5, G5, C6
	var step_dur := 0.14
	var sustain_start := step_dur * float(melody.size())
	var phase1 := 0.0
	var phase2 := 0.0
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var freq1 := 1046.50
		var freq2 := 783.99
		var env := 1.0
		if t < sustain_start:
			var note_idx := clampi(int(t / step_dur), 0, melody.size() - 1)
			freq1 = melody[note_idx]
			freq2 = freq1 * 0.75
			var note_t := fmod(t, step_dur)
			env = 1.0 - (note_t / step_dur) * 0.3
		else:
			var sustain_t := t - sustain_start
			var sustain_len := duration - sustain_start
			env = 1.0 - (sustain_t / sustain_len)
			var vib := sin(sustain_t * 6.0 * TAU) * 8.0
			freq1 = 1046.50 + vib
			freq2 = 1318.51 + vib
		phase1 += freq1 * (TAU / float(SAMPLE_RATE))
		phase2 += freq2 * (TAU / float(SAMPLE_RATE))
		var v1 := _square_wave(phase1, 0.25)
		var v2 := _square_wave(phase2, 0.5)
		samples[i] = (v1 * 0.45 + v2 * 0.35) * env * 0.75
	return samples

func _synth_player_hurt() -> PackedFloat32Array:
	var duration := 0.18
	var count := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var freq := lerpf(120.0, 50.0, progress)
		var buzz := sin(t * 40.0 * TAU) * 15.0
		phase += (freq + buzz) * (TAU / float(SAMPLE_RATE))
		var noise := randf_range(-1.0, 1.0)
		var env := (1.0 - progress) * (1.0 - progress)
		var saw := _saw_wave(phase)
		samples[i] = (saw * 0.6 + noise * 0.4) * env * 0.8
	return samples

func _synth_boss_alarm() -> PackedFloat32Array:
	var duration := 1.40
	var count := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var lfo := _square_wave(t * 8.0 * TAU, 0.5)
		var freq := 660.0 if lfo > 0.0 else 440.0
		phase += freq * (TAU / float(SAMPLE_RATE))
		var env := 1.0 - (t / duration) * 0.2
		var sq := _square_wave(phase, 0.35)
		samples[i] = sq * env * 0.7
	return samples

func _synth_game_over() -> PackedFloat32Array:
	var duration := 1.40
	var count := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var notes := [392.00, 311.13, 261.63, 196.00] # G4, Eb4, C4, G3
	var note_dur := duration / float(notes.size())
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var note_idx := clampi(int(t / note_dur), 0, notes.size() - 1)
		var note_t := fmod(t, note_dur)
		var env := 1.0 - (note_t / note_dur) * 0.5
		if note_idx == notes.size() - 1:
			env = 1.0 - (note_t / note_dur) * 0.8
		var freq: float = notes[note_idx]
		var vib := sin(t * 5.0 * TAU) * 3.0
		phase += (freq + vib) * (TAU / float(SAMPLE_RATE))
		var tri := _triangle_wave(phase)
		var sq := _square_wave(phase, 0.5)
		samples[i] = (tri * 0.6 + sq * 0.3) * env * 0.75
	return samples

func _synth_victory() -> PackedFloat32Array:
	var duration := 1.50
	var count := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var melody := [523.25, 659.25, 783.99, 987.77, 1046.50, 1318.51] # C5, E5, G5, B5, C6, E6
	var step_dur := 0.14
	var sustain_start := step_dur * float(melody.size())
	var phase1 := 0.0
	var phase2 := 0.0
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var freq1 := 1046.50
		var freq2 := 1567.98
		var env := 1.0
		if t < sustain_start:
			var note_idx := clampi(int(t / step_dur), 0, melody.size() - 1)
			freq1 = melody[note_idx]
			freq2 = freq1 * 1.5
			var note_t := fmod(t, step_dur)
			env = 1.0 - (note_t / step_dur) * 0.25
		else:
			var sustain_t := t - sustain_start
			var sustain_len := duration - sustain_start
			env = 1.0 - (sustain_t / sustain_len) * 0.8
			var vib := sin(sustain_t * 6.0 * TAU) * 6.0
			freq1 = 1046.50 + vib
			freq2 = 1567.98 + vib
		phase1 += freq1 * (TAU / float(SAMPLE_RATE))
		phase2 += freq2 * (TAU / float(SAMPLE_RATE))
		var v1 := _square_wave(phase1, 0.25)
		var v2 := _square_wave(phase2, 0.5)
		samples[i] = (v1 * 0.45 + v2 * 0.35) * env * 0.75
	return samples

func _synth_retro_bgm() -> PackedFloat32Array:
	var duration := 7.5
	var count := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var beat_dur := 60.0 / 128.0
	var sixteenth_dur := beat_dur / 4.0
	var eighth_dur := beat_dur / 2.0
	var bar_dur := beat_dur * 4.0
	
	var bass_bar1 := [110.00, 110.00, 130.81, 110.00, 164.81, 110.00, 130.81, 164.81]
	var bass_bar2 := [87.31, 87.31, 110.00, 87.31, 130.81, 87.31, 110.00, 130.81]
	var bass_bar3 := [73.42, 73.42, 87.31, 73.42, 110.00, 73.42, 87.31, 110.00]
	var bass_bar4 := [82.41, 82.41, 103.83, 82.41, 123.47, 82.41, 103.83, 123.47]
	
	var arp_bar1 := [440.0, 523.25, 659.25, 880.0, 440.0, 523.25, 659.25, 880.0, 440.0, 523.25, 659.25, 880.0, 659.25, 523.25, 440.0, 523.25]
	var arp_bar2 := [349.23, 440.0, 523.25, 698.46, 349.23, 440.0, 523.25, 698.46, 349.23, 440.0, 523.25, 698.46, 523.25, 440.0, 349.23, 440.0]
	var arp_bar3 := [293.66, 349.23, 440.0, 587.33, 293.66, 349.23, 440.0, 587.33, 293.66, 349.23, 440.0, 587.33, 440.0, 349.23, 293.66, 349.23]
	var arp_bar4 := [329.63, 415.30, 493.88, 659.25, 329.63, 415.30, 493.88, 659.25, 329.63, 415.30, 493.88, 659.25, 493.88, 415.30, 329.63, 415.30]
	
	var bass_phase := 0.0
	var arp_phase := 0.0
	var kick_phase := 0.0
	
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var current_bar := clampi(int(t / bar_dur), 0, 3)
		var bar_t := fmod(t, bar_dur)
		
		var bass_note_idx := clampi(int(bar_t / eighth_dur), 0, 7)
		var bass_t := fmod(bar_t, eighth_dur)
		var bass_env := (1.0 - (bass_t / eighth_dur) * 0.7)
		var bass_freq := 110.0
		match current_bar:
			0: bass_freq = bass_bar1[bass_note_idx]
			1: bass_freq = bass_bar2[bass_note_idx]
			2: bass_freq = bass_bar3[bass_note_idx]
			3: bass_freq = bass_bar4[bass_note_idx]
		bass_phase += bass_freq * (TAU / float(SAMPLE_RATE))
		var bass_sample := _square_wave(bass_phase, 0.5) * bass_env * 0.35
		
		var arp_note_idx := clampi(int(bar_t / sixteenth_dur), 0, 15)
		var arp_t := fmod(bar_t, sixteenth_dur)
		var arp_env := (1.0 - (arp_t / sixteenth_dur) * 0.6)
		var arp_freq := 440.0
		match current_bar:
			0: arp_freq = arp_bar1[arp_note_idx]
			1: arp_freq = arp_bar2[arp_note_idx]
			2: arp_freq = arp_bar3[arp_note_idx]
			3: arp_freq = arp_bar4[arp_note_idx]
		arp_phase += arp_freq * (TAU / float(SAMPLE_RATE))
		var arp_sample := _square_wave(arp_phase, 0.25) * arp_env * 0.22
		
		var drum_sample := 0.0
		var beat_idx := int(bar_t / beat_dur) % 4
		var beat_t := fmod(bar_t, beat_dur)
		
		if (beat_idx == 0 or beat_idx == 2) and beat_t < 0.12:
			var kick_prog := beat_t / 0.12
			var kick_freq := lerpf(120.0, 40.0, kick_prog)
			kick_phase += kick_freq * (TAU / float(SAMPLE_RATE))
			var kick_env := (1.0 - kick_prog) * (1.0 - kick_prog)
			drum_sample += sin(kick_phase) * kick_env * 0.4
			
		if (beat_idx == 1 or beat_idx == 3) and beat_t < 0.15:
			var snare_prog := beat_t / 0.15
			var snare_env := (1.0 - snare_prog) * (1.0 - snare_prog)
			var snare_noise := randf_range(-1.0, 1.0)
			drum_sample += snare_noise * snare_env * 0.25
			
		var hat_t := fmod(bar_t, eighth_dur)
		if hat_t < 0.04:
			var hat_prog := hat_t / 0.04
			var hat_env := 1.0 - hat_prog
			var hat_noise := randf_range(-1.0, 1.0)
			drum_sample += hat_noise * hat_env * 0.12
			
		samples[i] = clampf(bass_sample + arp_sample + drum_sample, -1.0, 1.0)
		
	return samples
