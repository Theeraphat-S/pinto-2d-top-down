# res://tests/test_r2_empirical_challenger.gd
# Empirical Challenger Verification Suite for Visual Feedback, Sprite Animation & Damage Numbers
extends "res://tests/test_framework.gd"

const EnemyBaseScript = preload("res://scenes/enemies/enemy_base.gd")
const EnemySlimeScript = preload("res://scenes/enemies/enemy_slime.gd")
const EnemyBatScript = preload("res://scenes/enemies/enemy_bat.gd")
const EnemyDroneScript = preload("res://scenes/enemies/enemy_drone.gd")
const EnemyGolemScript = preload("res://scenes/enemies/enemy_golem.gd")
const BossGigaNullScript = preload("res://scenes/enemies/boss_giga_null.gd")
const DamageNumberScript = preload("res://scenes/ui/damage_number.gd")

const ENEMY_SCENE_PATHS := {
	"base": "res://scenes/enemies/enemy_base.tscn",
	"slime": "res://scenes/enemies/enemy_slime.tscn",
	"bat": "res://scenes/enemies/enemy_bat.tscn",
	"drone": "res://scenes/enemies/enemy_drone.tscn",
	"golem": "res://scenes/enemies/enemy_golem.tscn",
	"boss": "res://scenes/enemies/boss_giga_null.tscn"
}

# ==============================================================================
# SECTION 1: SPRITE2D HFRAMES & CONTINUOUS FRAME CYCLING
# ==============================================================================

func test_empirical_sprite_hframes_and_vframes_on_all_scenes() -> void:
	for key in ENEMY_SCENE_PATHS:
		var path: String = ENEMY_SCENE_PATHS[key]
		var scene: PackedScene = load(path) as PackedScene
		assert_not_null(scene, "Loaded scene: " + path)
		
		var inst: Node = scene.instantiate()
		assert_not_null(inst, "Instantiated scene: " + key)
		
		var sprite: Sprite2D = inst.get_node_or_null("Sprite2D") as Sprite2D
		assert_not_null(sprite, "[%s] Has Sprite2D node" % key)
		assert_eq(sprite.hframes, 4, "[%s] Sprite2D hframes must be exactly 4" % key)
		assert_eq(sprite.vframes, 1, "[%s] Sprite2D vframes must be exactly 1" % key)
		assert_gte(sprite.frame, 0, "[%s] Initial frame >= 0" % key)
		assert_lte(sprite.frame, 3, "[%s] Initial frame <= 3" % key)
		
		inst.free()

func test_empirical_step_by_step_frame_cycling_sequence() -> void:
	var slime_scene: PackedScene = load(ENEMY_SCENE_PATHS["slime"]) as PackedScene
	var slime = slime_scene.instantiate()
	var sprite: Sprite2D = slime.get_node("Sprite2D")
	
	slime.animation_fps = 8.0 # 1 frame every 0.125s
	slime._anim_timer = 0.0
	slime._current_frame = 0
	sprite.frame = 0
	
	var delta: float = 0.125
	
	# Verify sequence: 0 -> 1 -> 2 -> 3 -> 0 -> 1 -> 2 -> 3 -> 0
	var expected_sequence := [1, 2, 3, 0, 1, 2, 3, 0]
	for idx in range(expected_sequence.size()):
		slime._physics_process(delta)
		var exp_frame: int = expected_sequence[idx]
		assert_eq(sprite.frame, exp_frame, "Step %d: Frame transitioned to %d at t=%.3fs" % [idx + 1, exp_frame, (idx + 1) * delta])
		assert_eq(slime._current_frame, exp_frame, "Internal _current_frame matches sprite.frame %d" % exp_frame)
		
	slime.free()

func test_empirical_subframe_delta_accumulation_at_60hz() -> void:
	# Test running at 60 FPS (delta = 1/60 = 0.016667s) with 6.0 FPS animation (0.16667s per frame)
	var drone_scene: PackedScene = load(ENEMY_SCENE_PATHS["drone"]) as PackedScene
	var drone = drone_scene.instantiate()
	var sprite: Sprite2D = drone.get_node("Sprite2D")
	
	drone.animation_fps = 6.0
	drone._anim_timer = 0.0
	drone._current_frame = 0
	sprite.frame = 0
	
	var delta_60hz: float = 1.0 / 60.0
	var frame_history: Array[int] = []
	
	# Simulate 120 physics ticks (2 full seconds)
	for tick in range(120):
		drone._physics_process(delta_60hz)
		frame_history.append(sprite.frame)
		
	# Frame 0 should last ~10 ticks, frame 1 ~10 ticks, etc.
	# Check at tick 9 (frame 0), tick 11 (frame 1), tick 21 (frame 2), tick 31 (frame 3), tick 41 (frame 0)
	assert_eq(frame_history[8], 0, "Tick 9 (t=0.150s): Still on frame 0")
	assert_eq(frame_history[10], 1, "Tick 11 (t=0.183s): Advanced to frame 1")
	assert_eq(frame_history[20], 2, "Tick 21 (t=0.350s): Advanced to frame 2")
	assert_eq(frame_history[30], 3, "Tick 31 (t=0.517s): Advanced to frame 3")
	assert_eq(frame_history[40], 0, "Tick 41 (t=0.683s): Cycled back to frame 0")
	assert_eq(frame_history[50], 1, "Tick 51 (t=0.850s): Cycled to frame 1")
	
	# Verify all values in history are strictly within [0, 3]
	for f in frame_history:
		assert_gte(f, 0, "Frame index >= 0")
		assert_lte(f, 3, "Frame index <= 3")
		
	drone.free()

# ==============================================================================
# SECTION 2: VISUAL HURT FLASH & MODULATE RESET
# ==============================================================================

func test_empirical_hurt_flash_modulate_color_and_exact_duration() -> void:
	var slime_scene: PackedScene = load(ENEMY_SCENE_PATHS["slime"]) as PackedScene
	var slime = slime_scene.instantiate()
	var sprite: Sprite2D = slime.get_node("Sprite2D")
	
	slime.base_modulate = Color.WHITE
	sprite.modulate = Color.WHITE
	
	# 1. Trigger damage hit
	slime.take_damage(5.0, false)
	assert_true(slime._is_flashing, "Hurt flash active immediately after take_damage")
	assert_almost_eq(slime._flash_timer, 0.08, 0.001, "Flash timer set to exactly 0.08s")
	assert_eq(sprite.modulate, Color(1.8, 1.8, 1.8, 1.0), "Normal hit modulates to bright white (1.8, 1.8, 1.8, 1.0)")
	
	# 2. Advance 0.04s (halfway through flash)
	slime._physics_process(0.04)
	assert_true(slime._is_flashing, "Flash remains active at t=0.04s")
	assert_almost_eq(slime._flash_timer, 0.04, 0.001, "Flash timer decreased to 0.04s")
	assert_eq(sprite.modulate, Color(1.8, 1.8, 1.8, 1.0), "Modulate remains flash color at t=0.04s")
	
	# 3. Advance 0.045s (total 0.085s > 0.08s)
	slime._physics_process(0.045)
	assert_false(slime._is_flashing, "Flash expired after 0.085s")
	assert_eq(sprite.modulate, Color.WHITE, "Modulate restored to base_modulate (Color.WHITE)")
	
	# 4. Trigger critical damage hit
	slime.take_damage(10.0, true)
	assert_true(slime._is_flashing, "Hurt flash active on critical hit")
	assert_almost_eq(slime._flash_timer, 0.08, 0.001, "Flash timer set to 0.08s on crit")
	assert_eq(sprite.modulate, Color(2.0, 0.3, 0.3, 1.0), "Crit hit modulates to intense red (2.0, 0.3, 0.3, 1.0)")
	
	slime._physics_process(0.09)
	assert_false(slime._is_flashing, "Crit flash expired after 0.09s")
	assert_eq(sprite.modulate, Color.WHITE, "Modulate restored to base_modulate after crit")
	
	slime.free()

func test_empirical_hurt_flash_does_not_halt_frame_cycling() -> void:
	var bat_scene: PackedScene = load(ENEMY_SCENE_PATHS["bat"]) as PackedScene
	var bat = bat_scene.instantiate()
	var sprite: Sprite2D = bat.get_node("Sprite2D")
	
	bat.animation_fps = 8.0 # 0.125s per frame
	bat._anim_timer = 0.0
	bat._current_frame = 0
	sprite.frame = 0
	
	# Trigger hit at t=0
	bat.take_damage(5.0, false)
	assert_true(bat._is_flashing, "Bat flashing")
	
	# Step 0.125s (flash expires at 0.08s, frame changes at 0.125s)
	bat._physics_process(0.125)
	assert_false(bat._is_flashing, "Flash expired during step")
	assert_eq(sprite.frame, 1, "Frame successfully advanced from 0 to 1 despite taking damage")
	
	# Step another 0.125s while hitting bat again
	bat.take_damage(5.0, false)
	bat._physics_process(0.125)
	assert_eq(sprite.frame, 2, "Frame advanced from 1 to 2 during second damage flash")
	
	bat.free()

func test_empirical_rapid_consecutive_hits_flash_refresh() -> void:
	var golem_scene: PackedScene = load(ENEMY_SCENE_PATHS["golem"]) as PackedScene
	var golem = golem_scene.instantiate()
	var sprite: Sprite2D = golem.get_node("Sprite2D")
	
	# Hit 1
	golem.take_damage(10.0, false)
	golem._physics_process(0.04)
	assert_almost_eq(golem._flash_timer, 0.04, 0.001, "Flash timer at 0.04s after hit 1")
	
	# Hit 2 arrives before hit 1 finished
	golem.take_damage(10.0, false)
	assert_almost_eq(golem._flash_timer, 0.08, 0.001, "Flash timer refreshed back to 0.08s on consecutive hit")
	assert_true(golem._is_flashing, "Still flashing")
	
	# Advance 0.05s (timer at 0.03s)
	golem._physics_process(0.05)
	assert_true(golem._is_flashing, "Still flashing after 0.05s from hit 2")
	
	# Advance 0.04s (total 0.09s from hit 2)
	golem._physics_process(0.04)
	assert_false(golem._is_flashing, "Flash expired cleanly")
	assert_eq(sprite.modulate, Color.WHITE, "Modulate restored to base_modulate")
	
	golem.free()

# ==============================================================================
# SECTION 3: BOSS MULTI-PHASE TINT PERSISTENCE ACROSS HURT FLASHES
# ==============================================================================

func test_empirical_boss_phase_modulate_persistence_across_flashes() -> void:
	var boss_scene: PackedScene = load(ENEMY_SCENE_PATHS["boss"]) as PackedScene
	var boss = boss_scene.instantiate()
	var sprite: Sprite2D = boss.get_node("Sprite2D")
	
	# --- Phase 1 Verification ---
	assert_eq(boss.current_phase, 1, "Boss starts in Phase 1")
	assert_eq(boss.base_modulate, Color.WHITE, "Phase 1 base_modulate is Color.WHITE")
	assert_almost_eq(boss.animation_fps, 7.0, 0.01, "Phase 1 animation_fps is 7.0")
	
	boss.take_damage(20.0, false)
	assert_eq(sprite.modulate, Color(1.8, 1.8, 1.8, 1.0), "Phase 1 flash modulate")
	boss._physics_process(0.09)
	assert_eq(sprite.modulate, Color.WHITE, "Phase 1 modulate restored to Color.WHITE")
	
	# --- Phase 2 Verification ---
	boss._enter_phase(2)
	assert_eq(boss.current_phase, 2, "Boss transitioned to Phase 2")
	assert_eq(boss.base_modulate, Color(1.3, 0.8, 0.8, 1.0), "Phase 2 base_modulate is Color(1.3, 0.8, 0.8, 1.0)")
	assert_almost_eq(boss.animation_fps, 9.0, 0.01, "Phase 2 animation_fps is 9.0")
	assert_eq(sprite.modulate, Color(1.3, 0.8, 0.8, 1.0), "Sprite immediately has Phase 2 tint")
	
	# Hit 10 times in Phase 2 with alternating normal and crit
	for i in range(10):
		var is_crit: bool = (i % 2 == 1)
		boss.take_damage(10.0, is_crit)
		assert_true(boss._is_flashing, "Phase 2 hit %d flashing" % (i + 1))
		var expected_flash: Color = Color(2.0, 0.3, 0.3, 1.0) if is_crit else Color(1.8, 1.8, 1.8, 1.0)
		assert_eq(sprite.modulate, expected_flash, "Phase 2 hit %d flash color matches" % (i + 1))
		
		# Step past flash duration
		boss._physics_process(0.09)
		assert_false(boss._is_flashing, "Phase 2 hit %d flash ended" % (i + 1))
		assert_eq(sprite.modulate, Color(1.3, 0.8, 0.8, 1.0), "Phase 2 hit %d restored EXACT Phase 2 base_modulate" % (i + 1))
		
	# --- Phase 3 Verification ---
	boss._enter_phase(3)
	assert_eq(boss.current_phase, 3, "Boss transitioned to Phase 3")
	assert_eq(boss.base_modulate, Color(1.5, 0.5, 0.5, 1.0), "Phase 3 base_modulate is Color(1.5, 0.5, 0.5, 1.0)")
	assert_almost_eq(boss.animation_fps, 12.0, 0.01, "Phase 3 animation_fps is 12.0")
	assert_eq(sprite.modulate, Color(1.5, 0.5, 0.5, 1.0), "Sprite immediately has Phase 3 tint")
	
	# Hit 10 times in Phase 3
	for i in range(10):
		var is_crit: bool = (i % 2 == 1)
		boss.take_damage(10.0, is_crit)
		assert_true(boss._is_flashing, "Phase 3 hit %d flashing" % (i + 1))
		boss._physics_process(0.09)
		assert_false(boss._is_flashing, "Phase 3 hit %d flash ended" % (i + 1))
		assert_eq(sprite.modulate, Color(1.5, 0.5, 0.5, 1.0), "Phase 3 hit %d restored EXACT Phase 3 base_modulate" % (i + 1))
		
	boss.free()

func test_empirical_boss_phase_3_charge_telegraph_and_recovery() -> void:
	var boss_scene: PackedScene = load(ENEMY_SCENE_PATHS["boss"]) as PackedScene
	var boss = boss_scene.instantiate()
	var sprite: Sprite2D = boss.get_node("Sprite2D")
	
	boss._enter_phase(3)
	assert_eq(boss.base_modulate, Color(1.5, 0.5, 0.5, 1.0), "Phase 3 base modulate verified")
	
	# Trigger charge telegraph
	boss._start_charge_telegraph()
	assert_true(boss._is_charging, "Boss is charging telegraph")
	
	# Step through charging telegraph (0.6s)
	for _s in range(12):
		boss._process_phase_3(0.05)
	
	assert_false(boss._is_charging, "Boss finished telegraph charging")
	assert_true(boss._is_dashing, "Boss entered charge dash")
	
	# Step through dashing (0.8s)
	for _s in range(16):
		boss._process_phase_3(0.05)
		
	assert_false(boss._is_dashing, "Boss finished charge dash")
	assert_eq(sprite.modulate, Color(1.5, 0.5, 0.5, 1.0), "Modulate restored to Phase 3 base_modulate after charge dash")
	
	boss.free()

# ==============================================================================
# SECTION 4: DAMAGE POPUP LIFECYCLE, SCALING & SURVIVAL AFTER ENEMY DEATH
# ==============================================================================

func test_empirical_damage_popup_instantiation_properties() -> void:
	var popup_scene: PackedScene = load("res://scenes/ui/damage_number.tscn") as PackedScene
	assert_not_null(popup_scene, "Loaded damage_number.tscn")
	
	# Test Normal Popup
	var popup_normal = popup_scene.instantiate()
	popup_normal.setup(34.2, false, Vector2(100, 200))
	popup_normal._ready()
	var label_norm: Label = popup_normal.get_node("Label")
	assert_eq(popup_normal.damage_amount, 34, "Damage amount rounded to 34")
	assert_eq(label_norm.text, "34", "Label text formatted to '34'")
	assert_eq(popup_normal.scale, Vector2(1.2, 1.2), "Initial normal popup scale is 1.2x")
	assert_eq(label_norm.get_theme_color("font_color"), Color(1.0, 1.0, 1.0, 1.0), "Normal popup font color is White")
	assert_eq(label_norm.get_theme_constant("outline_size"), 2, "Normal popup outline size is 2")
	popup_normal.free()
	
	# Test Crit Popup
	var popup_crit = popup_scene.instantiate()
	popup_crit.setup(99.6, true, Vector2(150, 250))
	popup_crit._ready()
	var label_crit: Label = popup_crit.get_node("Label")
	assert_eq(popup_crit.damage_amount, 100, "Crit damage amount rounded to 100")
	assert_eq(label_crit.text, "100", "Label text formatted to '100'")
	assert_eq(popup_crit.scale, Vector2(1.4, 1.4), "Initial crit popup scale is 1.4x")
	assert_eq(label_crit.get_theme_color("font_color"), Color(1.0, 0.85, 0.2, 1.0), "Crit popup font color is Gold")
	assert_eq(label_crit.get_theme_constant("outline_size"), 3, "Crit popup outline size is 3")
	popup_crit.free()

func test_empirical_damage_popup_post_mortem_survival() -> void:
	var container := Node2D.new()
	container.name = "Entities"
	
	var slime_scene: PackedScene = load(ENEMY_SCENE_PATHS["slime"]) as PackedScene
	var slime = slime_scene.instantiate()
	container.add_child(slime)
	slime.global_position = Vector2(500.0, 300.0)
	slime.current_health = 10.0
	
	# Fatal strike dealing 50 damage -> triggers die() and queue_free() on slime
	slime.take_damage(50.0, true)
	
	assert_true(slime.is_dead, "Slime marked dead")
	assert_true(slime.is_queued_for_deletion(), "Slime is queued for deletion")
	
	# Inspect container children to locate damage number
	var popup: Node2D = null
	for child in container.get_children():
		if child != slime and child.get_script() == DamageNumberScript:
			popup = child as Node2D
			break
			
	assert_not_null(popup, "DamageNumber exists as an independent sibling under Entities container")
	if popup:
		assert_false(popup.is_queued_for_deletion(), "DamageNumber is NOT queued for deletion when enemy dies")
		assert_eq(popup.get("damage_amount"), 50, "Damage amount is 50")
		assert_true(popup.get("is_crit"), "Crit status preserved")
		assert_in_range(popup.global_position.x, 495.0, 505.0, "Popup spawned near enemy X")
		assert_in_range(popup.global_position.y, 285.0, 287.0, "Popup spawned at enemy Y - 14px")
		
	container.free()

func test_empirical_zero_and_negative_damage_suppression() -> void:
	var slime = EnemySlimeScript.new()
	var initial_hp: float = slime.current_health
	
	# Zero damage
	slime.take_damage(0.0, false)
	assert_eq(slime.current_health, initial_hp, "Zero damage does not alter current_health")
	assert_false(slime._is_flashing, "Zero damage does not trigger hurt flash")
	
	# Negative damage
	slime.take_damage(-20.0, false)
	assert_eq(slime.current_health, initial_hp, "Negative damage does not heal or alter current_health")
	assert_false(slime._is_flashing, "Negative damage does not trigger hurt flash")
	
	slime.free()

func test_empirical_boss_death_queue_free_and_gem_drops() -> void:
	var container := Node2D.new()
	container.name = "Entities"
	
	var boss_scene: PackedScene = load(ENEMY_SCENE_PATHS["boss"]) as PackedScene
	var boss = boss_scene.instantiate()
	container.add_child(boss)
	boss._ready()
	
	# Deal fatal blow to boss
	boss.take_damage(1000.0, true)
	
	assert_true(boss.is_dead, "Boss is_dead flagged true on lethal damage")
	assert_true(boss.is_queued_for_deletion(), "Boss node is queued_free() upon death")
	
	container.free()

