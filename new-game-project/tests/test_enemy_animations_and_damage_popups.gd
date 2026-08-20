# res://tests/test_enemy_animations_and_damage_popups.gd
# Test Suite for R1 (Enemy Sprite Animation) and R2 (Floating Damage Numbers)
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

const EXPECTED_TEXTURE_SIZES := {
	"base": Vector2(128, 32),
	"slime": Vector2(128, 32),
	"bat": Vector2(128, 32),
	"drone": Vector2(128, 32),
	"golem": Vector2(192, 48),
	"boss": Vector2(320, 80)
}

# ==============================================================================
# R1: ENEMY SPRITE ANIMATION & HFRAMES SPECIFICATION TESTS
# ==============================================================================

func test_all_enemy_scenes_sprite_hframes_and_textures() -> void:
	for key in ENEMY_SCENE_PATHS:
		var scene_path: String = ENEMY_SCENE_PATHS[key]
		assert_true(ResourceLoader.exists(scene_path), "[%s] Scene file exists: %s" % [key, scene_path])
		
		var scene: PackedScene = load(scene_path) as PackedScene
		assert_not_null(scene, "[%s] Scene loads successfully" % key)
		
		var entity: Node = scene.instantiate()
		assert_not_null(entity, "[%s] Scene instantiates successfully" % key)
		assert_true(entity.has_node("Sprite2D"), "[%s] Contains Sprite2D child node" % key)
		
		var sprite: Sprite2D = entity.get_node("Sprite2D") as Sprite2D
		assert_eq(sprite.hframes, 4, "[%s] Sprite2D hframes is 4" % key)
		assert_eq(sprite.vframes, 1, "[%s] Sprite2D vframes is 1" % key)
		assert_not_null(sprite.texture, "[%s] Sprite2D texture resource assigned" % key)
		
		var expected_size: Vector2 = EXPECTED_TEXTURE_SIZES[key]
		assert_eq(sprite.texture.get_size(), expected_size, "[%s] Texture dimensions match %s" % [key, str(expected_size)])
		
		entity.free()

func test_enemy_animation_fps_defaults_and_overrides() -> void:
	var base_enemy = EnemyBaseScript.new()
	assert_almost_eq(base_enemy.animation_fps, 7.0, 0.01, "EnemyBase default animation_fps is 7.0")
	base_enemy.free()
	
	var slime = EnemySlimeScript.new()
	assert_almost_eq(slime.animation_fps, 7.0, 0.01, "Slime animation_fps is 7.0")
	slime.free()
	
	var bat = EnemyBatScript.new()
	assert_almost_eq(bat.animation_fps, 8.0, 0.01, "Bat animation_fps is 8.0 (fast wing flaps)")
	bat.free()
	
	var drone = EnemyDroneScript.new()
	assert_almost_eq(drone.animation_fps, 6.0, 0.01, "Drone animation_fps is 6.0 (hover pulse)")
	drone.free()
	
	var golem = EnemyGolemScript.new()
	assert_almost_eq(golem.animation_fps, 6.0, 0.01, "Golem animation_fps is 6.0 (heavy steps)")
	golem.free()
	
	var boss = BossGigaNullScript.new()
	assert_almost_eq(boss.animation_fps, 7.0, 0.01, "Boss Phase 1 animation_fps is 7.0")
	boss._enter_phase(2)
	assert_almost_eq(boss.animation_fps, 9.0, 0.01, "Boss Phase 2 animation_fps is 9.0")
	boss._enter_phase(3)
	assert_almost_eq(boss.animation_fps, 12.0, 0.01, "Boss Phase 3 animation_fps is 12.0")
	boss.free()

func test_enemy_frame_animation_cycling_modulo_4() -> void:
	var slime_scene: PackedScene = load(ENEMY_SCENE_PATHS["slime"]) as PackedScene
	var slime = slime_scene.instantiate()
	var sprite: Sprite2D = slime.get_node("Sprite2D")
	
	# Manually reset to frame 0 and anim_timer 0 for deterministic sequence verification
	slime._current_frame = 0
	slime._anim_timer = 0.0
	slime.animation_fps = 8.0 # 0.125s per frame
	sprite.frame = 0
	
	var delta: float = 0.125
	# Step 1: 0 -> 1
	slime._physics_process(delta)
	assert_eq(sprite.frame, 1, "Frame advances to 1 after 0.125s at 8 FPS")
	
	# Step 2: 1 -> 2
	slime._physics_process(delta)
	assert_eq(sprite.frame, 2, "Frame advances to 2 after 0.250s")
	
	# Step 3: 2 -> 3
	slime._physics_process(delta)
	assert_eq(sprite.frame, 3, "Frame advances to 3 after 0.375s")
	
	# Step 4: 3 -> 0 (modulo wrap)
	slime._physics_process(delta)
	assert_eq(sprite.frame, 0, "Frame cycles back to 0 after 0.500s")
	
	# 40 continuous steps (5 full seconds)
	for step in range(40):
		slime._physics_process(delta)
		var expected: int = (step + 1) % 4
		assert_eq(sprite.frame, expected, "Continuous cycle step %d matches expected frame %d" % [step, expected])
		assert_gte(sprite.frame, 0, "Frame index >= 0")
		assert_lte(sprite.frame, 3, "Frame index <= 3")
		
	slime.free()

func test_enemy_swarm_desynchronization_on_ready() -> void:
	var slime_scene: PackedScene = load(ENEMY_SCENE_PATHS["slime"]) as PackedScene
	var root := Node2D.new()
	var frames_seen := {}
	var timers_seen := []
	
	for i in range(20):
		var enemy = slime_scene.instantiate()
		root.add_child(enemy)
		enemy._ready()
		frames_seen[enemy._current_frame] = true
		timers_seen.append(enemy._anim_timer)
		
	# With 20 instances and randi() % 4, we expect multiple distinct frames and varied timer offsets
	assert_gt(frames_seen.size(), 1, "Swarm desynchronization creates varied initial frames across instances")
	
	var min_timer: float = timers_seen[0]
	var max_timer: float = timers_seen[0]
	for t in timers_seen:
		if t < min_timer:
			min_timer = t
		if t > max_timer:
			max_timer = t
	assert_gt(max_timer - min_timer, 0.05, "Swarm instances have distinct randomized animation timer offsets")
	
	root.free()

func test_enemy_horizontal_flip_facing_isolation() -> void:
	var bat_scene: PackedScene = load(ENEMY_SCENE_PATHS["bat"]) as PackedScene
	var bat = bat_scene.instantiate()
	var sprite: Sprite2D = bat.get_node("Sprite2D")
	
	bat.knockback_velocity = Vector2(-80.0, 0.0)
	bat._physics_process(0.016)
	assert_true(sprite.flip_h, "Moving left sets sprite.flip_h to true")
	
	bat.knockback_velocity = Vector2(80.0, 0.0)
	bat._physics_process(0.016)
	assert_false(sprite.flip_h, "Moving right sets sprite.flip_h to false")
	
	bat.free()

func test_enemy_hurt_flash_modulate_and_timing() -> void:
	var golem_scene: PackedScene = load(ENEMY_SCENE_PATHS["golem"]) as PackedScene
	var golem = golem_scene.instantiate()
	var sprite: Sprite2D = golem.get_node("Sprite2D")
	
	# Normal damage flash
	golem.take_damage(10.0, false)
	assert_true(golem._is_flashing, "Hurt flash active on normal damage")
	assert_almost_eq(golem._flash_timer, 0.08, 0.001, "Flash timer initialized to 0.08s")
	assert_eq(sprite.modulate, Color(1.8, 1.8, 1.8, 1.0), "Normal damage modulates bright white")
	
	# Tick partially through flash
	golem._physics_process(0.04)
	assert_true(golem._is_flashing, "Flash still active at 0.04s")
	
	# Tick past 0.08s
	golem._physics_process(0.05)
	assert_false(golem._is_flashing, "Flash expires after 0.08s")
	assert_eq(sprite.modulate, Color.WHITE, "Sprite modulate restored to base_modulate (Color.WHITE)")
	
	# Critical damage flash
	golem.take_damage(20.0, true)
	assert_true(golem._is_flashing, "Hurt flash active on crit damage")
	assert_eq(sprite.modulate, Color(2.0, 0.3, 0.3, 1.0), "Crit damage modulates intense red")
	
	golem.free()

func test_boss_phase_modulate_restoration_after_hurt_flash() -> void:
	var boss_scene: PackedScene = load(ENEMY_SCENE_PATHS["boss"]) as PackedScene
	var boss = boss_scene.instantiate()
	var sprite: Sprite2D = boss.get_node("Sprite2D")
	
	# Phase 1: White
	assert_eq(boss.base_modulate, Color.WHITE, "Boss Phase 1 base_modulate is Color.WHITE")
	
	# Enter Phase 2
	boss._enter_phase(2)
	assert_eq(boss.base_modulate, Color(1.3, 0.8, 0.8, 1.0), "Boss Phase 2 base_modulate is light red tint")
	assert_eq(sprite.modulate, Color(1.3, 0.8, 0.8, 1.0), "Sprite immediately takes Phase 2 modulate")
	
	# Take damage in Phase 2
	boss.take_damage(15.0, false)
	assert_true(boss._is_flashing, "Boss flashing after hit")
	assert_eq(sprite.modulate, Color(1.8, 1.8, 1.8, 1.0), "Hurt flash overrides phase modulate during flash")
	
	# Finish flash in Phase 2
	boss._physics_process(0.09)
	assert_false(boss._is_flashing, "Flash finished")
	assert_eq(sprite.modulate, Color(1.3, 0.8, 0.8, 1.0), "Modulate successfully restored to Phase 2 base_modulate")
	
	# Enter Phase 3
	boss._enter_phase(3)
	assert_eq(boss.base_modulate, Color(1.5, 0.5, 0.5, 1.0), "Boss Phase 3 base_modulate is deep red tint")
	assert_eq(sprite.modulate, Color(1.5, 0.5, 0.5, 1.0), "Sprite immediately takes Phase 3 modulate")
	
	# Take damage in Phase 3
	boss.take_damage(15.0, false)
	assert_true(boss._is_flashing, "Boss flashing after hit in Phase 3")
	boss._physics_process(0.09)
	assert_false(boss._is_flashing, "Flash finished in Phase 3")
	assert_eq(sprite.modulate, Color(1.5, 0.5, 0.5, 1.0), "Modulate successfully restored to Phase 3 base_modulate")
	
	boss.free()

# ==============================================================================
# R2: FLOATING DAMAGE NUMBERS SPECIFICATION TESTS
# ==============================================================================

func test_damage_number_scene_structure_and_nodes() -> void:
	var dmg_path: String = "res://scenes/ui/damage_number.tscn"
	assert_true(ResourceLoader.exists(dmg_path), "DamageNumber scene file exists: %s" % dmg_path)
	
	var scene: PackedScene = load(dmg_path) as PackedScene
	assert_not_null(scene, "DamageNumber scene loaded")
	
	var instance: Node = scene.instantiate()
	assert_not_null(instance, "DamageNumber instantiated")
	assert_true(instance is Node2D, "DamageNumber root is Node2D")
	assert_eq(instance.get("z_index"), 50, "DamageNumber z_index is 50 for elevated visibility")
	assert_true(instance.has_node("Label"), "DamageNumber has child Label")
	
	var label: Label = instance.get_node("Label") as Label
	assert_eq(label.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER, "Label is horizontally centered")
	assert_eq(label.vertical_alignment, VERTICAL_ALIGNMENT_CENTER, "Label is vertically centered")
	assert_eq(label.get_theme_constant("outline_size"), 2, "Label has 2px default outline")
	assert_eq(label.get_theme_font_size("font_size"), 10, "Label font size is 10px")
	
	assert_true(instance.has_method("setup"), "DamageNumber implements setup()")
	assert_true(instance.has_method("init"), "DamageNumber implements init() alias")
	
	instance.free()

func test_damage_number_text_formatting_and_crit_styling() -> void:
	var scene: PackedScene = load("res://scenes/ui/damage_number.tscn") as PackedScene
	
	# Normal damage formatting
	var dmg1 = scene.instantiate()
	dmg1.setup(25.0, false)
	var label1: Label = dmg1.get_node("Label") as Label
	assert_eq(label1.text, "25", "Standard integer damage 25.0 formats to '25'")
	assert_eq(label1.get_theme_color("font_color"), Color(1.0, 1.0, 1.0, 1.0), "Normal damage has white font color")
	assert_eq(label1.get_theme_constant("outline_size"), 2, "Normal damage has 2px outline")
	dmg1.free()
	
	# Rounded float formatting
	var dmg2 = scene.instantiate()
	dmg2.setup(14.8, false)
	var label2: Label = dmg2.get_node("Label") as Label
	assert_eq(label2.text, "15", "Damage 14.8 rounds up to integer '15'")
	dmg2.free()
	
	# Critical hit styling
	var dmg3 = scene.instantiate()
	dmg3.setup(50.0, true)
	var label3: Label = dmg3.get_node("Label") as Label
	assert_eq(label3.text, "50", "Crit damage 50.0 formats to '50'")
	assert_eq(label3.get_theme_color("font_color"), Color(1.0, 0.85, 0.2, 1.0), "Crit damage has gold font color")
	assert_eq(label3.get_theme_constant("outline_size"), 3, "Crit damage has thicker 3px outline")
	dmg3.free()

func test_damage_number_flexible_setup_signatures() -> void:
	var scene: PackedScene = load("res://scenes/ui/damage_number.tscn") as PackedScene
	
	# Signature 1: setup(amount, is_crit, start_pos)
	var dmg1 = scene.instantiate()
	dmg1.setup(30.0, true, Vector2(100.0, 200.0))
	assert_eq(dmg1.damage_amount, 30, "Signature 1 damage is 30")
	assert_true(dmg1.is_crit, "Signature 1 is_crit is true")
	assert_eq(dmg1.global_position, Vector2(100.0, 200.0), "Signature 1 global_position set")
	dmg1.free()
	
	# Signature 2: setup(amount, start_pos, is_crit)
	var dmg2 = scene.instantiate()
	dmg2.setup(45.0, Vector2(150.0, 250.0), true)
	assert_eq(dmg2.damage_amount, 45, "Signature 2 damage is 45")
	assert_true(dmg2.is_crit, "Signature 2 is_crit is true")
	assert_eq(dmg2.global_position, Vector2(150.0, 250.0), "Signature 2 global_position set")
	dmg2.free()
	
	# Signature 3: init alias
	var dmg3 = scene.instantiate()
	dmg3.init(60.0, false, Vector2(50.0, 50.0))
	assert_eq(dmg3.damage_amount, 60, "Init alias damage is 60")
	assert_false(dmg3.is_crit, "Init alias is_crit is false")
	assert_eq(dmg3.global_position, Vector2(50.0, 50.0), "Init alias global_position set")
	dmg3.free()

func test_damage_number_tween_and_lifecycle_properties() -> void:
	var scene: PackedScene = load("res://scenes/ui/damage_number.tscn") as PackedScene
	var dmg = scene.instantiate()
	
	assert_almost_eq(dmg.float_distance, 20.0, 0.01, "Damage popup float distance is 20px")
	assert_almost_eq(dmg.duration, 0.5, 0.01, "Damage popup duration is 0.5s")
	
	dmg.free()

func test_enemy_take_damage_spawns_damage_number_in_container() -> void:
	var container := Node2D.new()
	container.name = "Entities"
	
	var slime_scene: PackedScene = load(ENEMY_SCENE_PATHS["slime"]) as PackedScene
	var slime = slime_scene.instantiate()
	container.add_child(slime)
	slime.global_position = Vector2(400.0, 300.0)
	
	# Deal damage
	slime.take_damage(20.0, false)
	
	# Locate damage number in container
	var found_dmg: Node2D = null
	for child in container.get_children():
		if child.get_script() == DamageNumberScript or child.has_method("setup"):
			found_dmg = child as Node2D
			break
			
	assert_not_null(found_dmg, "DamageNumber instantiated and attached to Entities container")
	if found_dmg:
		assert_eq(found_dmg.get("damage_amount"), 20, "Spawned popup records 20 damage")
		assert_in_range(found_dmg.global_position.x, 400.0 - 5.0, 400.0 + 5.0, "Popup spawned near enemy X")
		assert_in_range(found_dmg.global_position.y, 300.0 - 15.0, 300.0 - 13.0, "Popup spawned above enemy head Y (-14px)")
		
	container.free()

func test_damage_number_survives_enemy_death() -> void:
	var container := Node2D.new()
	container.name = "Entities"
	
	var bat_scene: PackedScene = load(ENEMY_SCENE_PATHS["bat"]) as PackedScene
	var bat = bat_scene.instantiate()
	container.add_child(bat)
	bat.current_health = 10.0
	
	# Fatal blow
	bat.take_damage(50.0, true)
	assert_true(bat.is_dead, "Bat is flagged dead")
	
	# Check damage popup is still alive in container
	var found_dmg: Node = null
	for child in container.get_children():
		if child.get_script() == DamageNumberScript or child.has_method("setup"):
			found_dmg = child
			break
			
	assert_not_null(found_dmg, "DamageNumber survives lethal enemy death")
	if found_dmg:
		assert_false(found_dmg.is_queued_for_deletion(), "DamageNumber is not freed when enemy is freed")
		assert_eq(found_dmg.get("damage_amount"), 50, "Lethal damage number matches dealt amount")
		assert_true(found_dmg.get("is_crit"), "Lethal crit flag preserved")
		
	container.free()

func test_boss_take_damage_spawns_damage_numbers() -> void:
	var container := Node2D.new()
	container.name = "Entities"
	
	var boss_scene: PackedScene = load(ENEMY_SCENE_PATHS["boss"]) as PackedScene
	var boss = boss_scene.instantiate()
	container.add_child(boss)
	boss.global_position = Vector2(640.0, 360.0)
	
	boss.take_damage(100.0, true)
	
	var found_dmg: Node = null
	for child in container.get_children():
		if child.get_script() == DamageNumberScript or child.has_method("setup"):
			found_dmg = child
			break
			
	assert_not_null(found_dmg, "Damage number spawned on Boss hit")
	if found_dmg:
		assert_eq(found_dmg.get("damage_amount"), 100, "Boss damage number is 100")
		assert_true(found_dmg.get("is_crit"), "Boss crit flag registered")
		
	container.free()

func test_take_damage_without_scene_tree_resilience() -> void:
	var offline_slime = EnemySlimeScript.new()
	offline_slime.take_damage(10.0, false)
	assert_almost_eq(offline_slime.current_health, 15.0, 0.01, "Offline enemy takes damage safely without crashing")
	offline_slime.free()
	
	var offline_golem = EnemyGolemScript.new()
	offline_golem.take_damage(30.0, true)
	assert_almost_eq(offline_golem.current_health, 90.0, 0.01, "Offline golem takes damage safely")
	offline_golem.free()

func test_take_damage_health_clamping_to_zero() -> void:
	var slime = EnemySlimeScript.new()
	slime.take_damage(999.0, false)
	assert_almost_eq(slime.current_health, 0.0, 0.001, "Current health clamped to 0.0 on overkill damage")
	slime.free()
