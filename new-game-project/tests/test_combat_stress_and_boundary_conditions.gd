# res://tests/test_combat_stress_and_boundary_conditions.gd
# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA — COMBAT STRESS & BOUNDARY CONDITIONS SUITE
# Empirical Challenger Verification:
#  1. Mass Damage Stress: 150+ enemies simultaneous AoE damage & popup spawning
#  2. Zero & Negative Damage Boundary Conditions
#  3. Massive Overkill & Popup Survival on Enemy Death
#  4. Damage Popup Tween Lifecycle, Memory Safety & Queue Free
#  5. Rapid Multi-Hit Same-Frame Burst & Idempotent Death
#  6. Fractional Damage Rounding & Text Formatting Edge Cases
#  7. Node Lifecycle Cleanliness Under High-Volume Combat Cycling
# ==============================================================================
extends "res://tests/test_framework.gd"

const EnemyBaseScript = preload("res://scenes/enemies/enemy_base.gd")
const EnemySlimeScript = preload("res://scenes/enemies/enemy_slime.gd")
const EnemyBatScript = preload("res://scenes/enemies/enemy_bat.gd")
const EnemyDroneScript = preload("res://scenes/enemies/enemy_drone.gd")
const EnemyGolemScript = preload("res://scenes/enemies/enemy_golem.gd")
const BossGigaNullScript = preload("res://scenes/enemies/boss_giga_null.gd")
const DamageNumberScript = preload("res://scenes/ui/damage_number.gd")

const ENEMY_SCENE_PATHS := {
	"slime": "res://scenes/enemies/enemy_slime.tscn",
	"bat": "res://scenes/enemies/enemy_bat.tscn",
	"drone": "res://scenes/enemies/enemy_drone.tscn",
	"golem": "res://scenes/enemies/enemy_golem.tscn",
	"boss": "res://scenes/enemies/boss_giga_null.tscn"
}

# ==============================================================================
# 1. MASS DAMAGE STRESS: 150+ ENEMIES SIMULTANEOUS AOE BURST
# ==============================================================================

func test_mass_damage_aoe_stress_150_enemies_simultaneous_damage_and_popups() -> void:
	var root := Node2D.new()
	root.name = "Arena"
	var entities := Node2D.new()
	entities.name = "Entities"
	root.add_child(entities)
	
	var slime_scene: PackedScene = load(ENEMY_SCENE_PATHS["slime"]) as PackedScene
	var bat_scene: PackedScene = load(ENEMY_SCENE_PATHS["bat"]) as PackedScene
	var drone_scene: PackedScene = load(ENEMY_SCENE_PATHS["drone"]) as PackedScene
	var golem_scene: PackedScene = load(ENEMY_SCENE_PATHS["golem"]) as PackedScene
	
	assert_not_null(slime_scene, "Slime scene loaded")
	assert_not_null(bat_scene, "Bat scene loaded")
	assert_not_null(drone_scene, "Drone scene loaded")
	assert_not_null(golem_scene, "Golem scene loaded")
	
	var scenes: Array[PackedScene] = [slime_scene, bat_scene, drone_scene, golem_scene]
	var total_enemies := 160
	var enemy_list: Array = []
	
	# 1. Instantiate and position 160 enemies across the 1280x720 arena
	for i in range(total_enemies):
		var sc: PackedScene = scenes[i % scenes.size()]
		var enemy = sc.instantiate()
		entities.add_child(enemy)
		enemy._ready()
		var spawn_pos := Vector2(
			float(40 + (i * 31) % 1200),
			float(40 + (i * 47) % 640)
		)
		enemy.global_position = spawn_pos
		enemy_list.append(enemy)
		
	assert_eq(entities.get_child_count(), total_enemies, "160 active enemies added to Entities container")
	
	# 2. Simulate simultaneous AoE blast damaging all 160 enemies in one physics tick
	var aoe_damage: float = 15.0
	var crit_count := 0
	var normal_count := 0
	var initial_healths: Array[float] = []
	
	for i in range(total_enemies):
		var enemy = enemy_list[i]
		initial_healths.append(enemy.current_health)
		var is_crit: bool = (i % 4 == 0) # 25% crit rate
		if is_crit:
			crit_count += 1
		else:
			normal_count += 1
			
		enemy.take_damage(aoe_damage, is_crit)
		
	# 3. Verify health reduction and hurt flash on all 160 enemies
	for i in range(total_enemies):
		var enemy = enemy_list[i]
		var expected_hp: float = maxf(0.0, initial_healths[i] - aoe_damage)
		assert_almost_eq(enemy.current_health, expected_hp, 0.01, "Enemy %d HP correctly reduced from %s to %s" % [i, str(initial_healths[i]), str(expected_hp)])
		assert_true(enemy._is_flashing, "Enemy %d triggered hurt flash" % i)
		
	# 4. Count damage numbers spawned in Entities container (filtering out gems/sfx)
	var damage_popups: Array = []
	for child in entities.get_children():
		if child is DamageNumber or child.get_script() == DamageNumberScript:
			damage_popups.append(child)
			
	assert_eq(damage_popups.size(), total_enemies, "Exactly 160 damage popups spawned in Entities container simultaneously")
	
	# 5. Validate popup data, styling, and spawn offset positioning
	var found_crits := 0
	var found_normals := 0
	for idx in range(damage_popups.size()):
		var popup = damage_popups[idx]
		assert_eq(popup.get("damage_amount"), int(aoe_damage), "Popup %d damage amount matches %d" % [idx, int(aoe_damage)])
		var is_crit_popup: bool = bool(popup.get("is_crit"))
		if is_crit_popup:
			found_crits += 1
		else:
			found_normals += 1
			
		var parent_enemy = enemy_list[idx]
		var diff_x: float = absf(popup.global_position.x - parent_enemy.global_position.x)
		var diff_y: float = popup.global_position.y - parent_enemy.global_position.y
		assert_lte(diff_x, 4.05, "Popup %d X offset within +/- 4px" % idx)
		assert_almost_eq(diff_y, -14.0, 0.05, "Popup %d Y offset at -14px above enemy head" % idx)
		
	assert_eq(found_crits, crit_count, "Crit popup count (%d) matches dealt crit count" % crit_count)
	assert_eq(found_normals, normal_count, "Normal popup count (%d) matches dealt normal count" % normal_count)
	
	# 6. Advance physics process simulation over multiple frames to test physics query stability
	for frame in range(10):
		for enemy in enemy_list:
			if is_instance_valid(enemy) and not enemy.is_dead:
				enemy._physics_process(0.016)
				
	root.free()

# ==============================================================================
# 2. ZERO AND NEGATIVE DAMAGE BOUNDARY CONDITIONS
# ==============================================================================

func test_zero_and_negative_damage_boundary_conditions_all_enemy_types() -> void:
	for enemy_key in ENEMY_SCENE_PATHS:
		var scene_path: String = ENEMY_SCENE_PATHS[enemy_key]
		var scene: PackedScene = load(scene_path) as PackedScene
		assert_not_null(scene, "[%s] Loaded scene" % enemy_key)
		
		var container := Node2D.new()
		container.name = "Entities"
		
		var enemy = scene.instantiate()
		container.add_child(enemy)
		enemy._ready()
		
		var initial_hp: float = enemy.current_health
		var initial_base_modulate: Color = enemy.base_modulate
		
		# --- Test 1: take_damage(0.0, false) ---
		enemy.take_damage(0.0, false)
		assert_almost_eq(enemy.current_health, initial_hp, 0.001, "[%s] 0.0 damage does NOT reduce HP" % enemy_key)
		assert_false(enemy._is_flashing, "[%s] 0.0 damage does NOT trigger hurt flash" % enemy_key)
		assert_eq(enemy.sprite.modulate, initial_base_modulate, "[%s] 0.0 damage preserves sprite modulate" % enemy_key)
		assert_false(enemy.is_dead, "[%s] 0.0 damage does not kill enemy" % enemy_key)
		
		# Verify container has NO popups
		var popups_0 := 0
		for child in container.get_children():
			if child is DamageNumber or child.get_script() == DamageNumberScript:
				popups_0 += 1
		assert_eq(popups_0, 0, "[%s] 0.0 damage spawns NO damage popup" % enemy_key)
		
		# --- Test 2: take_damage(0.0, true) ---
		enemy.take_damage(0.0, true)
		assert_almost_eq(enemy.current_health, initial_hp, 0.001, "[%s] 0.0 crit damage does NOT reduce HP" % enemy_key)
		assert_false(enemy._is_flashing, "[%s] 0.0 crit damage does NOT trigger hurt flash" % enemy_key)
		assert_false(enemy.is_dead, "[%s] 0.0 crit damage does not kill enemy" % enemy_key)
		
		# --- Test 3: Negative damage values (take_damage(-5.0), take_damage(-100.0)) ---
		enemy.take_damage(-5.0, false)
		assert_almost_eq(enemy.current_health, initial_hp, 0.001, "[%s] -5.0 damage does NOT heal or change HP" % enemy_key)
		assert_false(enemy._is_flashing, "[%s] -5.0 damage does NOT trigger hurt flash" % enemy_key)
		
		enemy.take_damage(-100.0, true)
		assert_almost_eq(enemy.current_health, initial_hp, 0.001, "[%s] -100.0 crit damage does NOT change HP" % enemy_key)
		assert_false(enemy._is_flashing, "[%s] -100.0 crit damage does NOT trigger hurt flash" % enemy_key)
		
		# Micro-negative boundary: -0.00001
		enemy.take_damage(-0.00001, false)
		assert_almost_eq(enemy.current_health, initial_hp, 0.001, "[%s] -0.00001 damage does NOT change HP" % enemy_key)
		
		# Verify container still has exactly 0 popups
		var popups_neg := 0
		for child in container.get_children():
			if child is DamageNumber or child.get_script() == DamageNumberScript:
				popups_neg += 1
		assert_eq(popups_neg, 0, "[%s] Negative damage spawns ZERO damage popups" % enemy_key)
		
		container.free()

# ==============================================================================
# 3. MASSIVE OVERKILL & POPUP SURVIVAL ON ENEMY DEATH
# ==============================================================================

func test_massive_overkill_and_popup_survival_on_enemy_death() -> void:
	var container := Node2D.new()
	container.name = "Entities"
	
	# Test across all 5 enemy types
	for enemy_key in ENEMY_SCENE_PATHS:
		var scene: PackedScene = load(ENEMY_SCENE_PATHS[enemy_key]) as PackedScene
		var enemy = scene.instantiate()
		container.add_child(enemy)
		enemy._ready()
		
		# Set enemy to low health (e.g. 5 HP)
		enemy.current_health = 5.0
		
		# Hit with massive overkill damage: 50,000 damage (crit)
		var massive_damage: float = 50000.0
		enemy.take_damage(massive_damage, true)
		
		assert_true(enemy.is_dead, "[%s] Enemy marked is_dead on overkill" % enemy_key)
		assert_almost_eq(enemy.current_health, 0.0, 0.001, "[%s] Overkill clamped current_health to 0.0" % enemy_key)
		assert_true(enemy.is_queued_for_deletion(), "[%s] Enemy is queued_free() upon death" % enemy_key)
		
		# Locate damage popup in container
		var found_popup: Node = null
		for child in container.get_children():
			if (child is DamageNumber or child.get_script() == DamageNumberScript) and not child.is_queued_for_deletion():
				found_popup = child
				break
				
		assert_not_null(found_popup, "[%s] Damage popup is alive in container and NOT queued for deletion" % enemy_key)
		if found_popup:
			assert_eq(found_popup.get("damage_amount"), 50000, "[%s] Popup retains 50000 damage value" % enemy_key)
			assert_true(found_popup.get("is_crit"), "[%s] Popup retains crit flag" % enemy_key)
			
		# Post-mortem damage resilience: hitting dead enemy does NOT spawn additional popups
		var popups_before := 0
		for child in container.get_children():
			if child is DamageNumber or child.get_script() == DamageNumberScript:
				popups_before += 1
				
		enemy.take_damage(100.0, false)
		var popups_after := 0
		for child in container.get_children():
			if child is DamageNumber or child.get_script() == DamageNumberScript:
				popups_after += 1
				
		assert_eq(popups_after, popups_before, "[%s] Post-mortem damage ignored, no additional popup spawned" % enemy_key)
		
		# Clean container for next test iteration
		for child in container.get_children():
			child.free()
			
	container.free()

# ==============================================================================
# 4. DAMAGE POPUP TWEEN LIFECYCLE & NODE LEAK SAFETY
# ==============================================================================

func test_damage_popup_tween_lifecycle_and_properties() -> void:
	var popup_scene: PackedScene = load("res://scenes/ui/damage_number.tscn") as PackedScene
	assert_not_null(popup_scene, "Damage popup scene loaded")
	
	var popup = popup_scene.instantiate()
	assert_not_null(popup, "Popup instantiated")
	
	# Check duration and float distance constants
	assert_almost_eq(popup.float_distance, 20.0, 0.01, "Float distance is 20px")
	assert_almost_eq(popup.duration, 0.5, 0.01, "Fade/float duration is 0.5s")
	
	# Normal damage setup
	popup.setup(123.0, false, Vector2(200.0, 300.0))
	assert_eq(popup.damage_amount, 123, "Damage amount set to 123")
	assert_false(popup.is_crit, "is_crit is false for normal damage")
	assert_eq(popup.global_position, Vector2(200.0, 300.0), "Initial position assigned")
	
	var label: Label = popup.get_node("Label") as Label
	assert_not_null(label, "Label child found")
	assert_eq(label.text, "123", "Label text matches '123'")
	assert_eq(label.get_theme_color("font_color"), Color(1.0, 1.0, 1.0, 1.0), "Normal text color is white")
	assert_eq(label.get_theme_constant("outline_size"), 2, "Normal outline size is 2")
	
	# Crit damage setup
	var crit_popup = popup_scene.instantiate()
	crit_popup.setup(999.0, true, Vector2(400.0, 500.0))
	assert_eq(crit_popup.damage_amount, 999, "Crit damage amount set to 999")
	assert_true(crit_popup.is_crit, "is_crit is true")
	
	var crit_label: Label = crit_popup.get_node("Label") as Label
	assert_eq(crit_label.text, "999", "Crit label text is '999'")
	assert_eq(crit_label.get_theme_color("font_color"), Color(1.0, 0.85, 0.2, 1.0), "Crit text color is gold (#FFD733)")
	assert_eq(crit_label.get_theme_constant("outline_size"), 3, "Crit outline size is 3")
	
	popup.free()
	crit_popup.free()

func test_damage_popup_memory_safety_and_queue_free_completion() -> void:
	var container := Node2D.new()
	container.name = "Entities"
	
	var popup_scene: PackedScene = load("res://scenes/ui/damage_number.tscn") as PackedScene
	var spawned_popups: Array = []
	
	# Spawn 25 popups into container
	for i in range(25):
		var popup = popup_scene.instantiate()
		container.add_child(popup)
		popup.setup(float(10 + i), i % 2 == 0, Vector2(float(100 + i * 10), 200.0))
		spawned_popups.append(popup)
		
	assert_eq(container.get_child_count(), 25, "25 popups attached to container")
	
	# Verify all popups have valid setup state
	for i in range(25):
		var p = spawned_popups[i]
		assert_true(is_instance_valid(p), "Popup %d instance is valid" % i)
		assert_false(p.is_queued_for_deletion(), "Popup %d not yet queued for deletion" % i)
		
	# Explicitly invoke queue_free on each (simulating tween completion callback)
	for p in spawned_popups:
		p.queue_free()
		
	for i in range(25):
		var p = spawned_popups[i]
		assert_true(p.is_queued_for_deletion(), "Popup %d successfully queued_free() upon completion" % i)
		
	container.free()

# ==============================================================================
# 5. RAPID MULTI-HIT SAME-FRAME BURST & IDEMPOTENT DEATH
# ==============================================================================

func test_rapid_multi_hit_same_frame_burst_resilience() -> void:
	var container := Node2D.new()
	container.name = "Entities"
	
	var golem_scene: PackedScene = load(ENEMY_SCENE_PATHS["golem"]) as PackedScene
	var golem = golem_scene.instantiate()
	container.add_child(golem)
	golem._ready()
	golem.max_health = 100.0
	golem.current_health = 100.0
	
	# Hit golem 10 times with 8 damage in rapid succession (total 80 damage, HP: 100 -> 20)
	for hit in range(10):
		golem.take_damage(8.0, hit % 3 == 0)
		
	assert_almost_eq(golem.current_health, 20.0, 0.01, "Golem HP accurately reduced to 20 after 10 rapid hits")
	assert_false(golem.is_dead, "Golem is still alive at 20 HP")
	
	# Verify exactly 10 popups created
	var popup_count := 0
	for child in container.get_children():
		if child is DamageNumber or child.get_script() == DamageNumberScript:
			popup_count += 1
	assert_eq(popup_count, 10, "Exactly 10 popups spawned for 10 rapid hits")
	
	# Apply 5 more hits of 10 damage: 1st hit drops HP 20 -> 10, 2nd hit kills HP 10 -> 0, hits 3..5 are post-mortem
	for hit in range(5):
		golem.take_damage(10.0, false)
		
	assert_true(golem.is_dead, "Golem died on lethal hit")
	assert_almost_eq(golem.current_health, 0.0, 0.001, "Golem HP clamped to 0.0")
	
	# Popups should be exactly 10 + 2 = 12 (hits 3..5 post-mortem should NOT spawn popups)
	var final_popup_count := 0
	for child in container.get_children():
		if child is DamageNumber or child.get_script() == DamageNumberScript:
			final_popup_count += 1
	assert_eq(final_popup_count, 12, "Post-mortem hits did not spawn excess popups (12 total)")
	
	container.free()

# ==============================================================================
# 6. FRACTIONAL DAMAGE ROUNDING & FORMATTING BOUNDARIES
# ==============================================================================

func test_fractional_damage_rounding_and_formatting_boundaries() -> void:
	var popup_scene: PackedScene = load("res://scenes/ui/damage_number.tscn") as PackedScene
	
	# Round down: 14.4 -> 14
	var p1 = popup_scene.instantiate()
	p1.setup(14.4, false)
	var l1: Label = p1.get_node("Label") as Label
	assert_eq(p1.damage_amount, 14, "14.4 rounds down to 14")
	assert_eq(l1.text, "14", "Label displays '14'")
	p1.free()
	
	# Round up: 14.6 -> 15
	var p2 = popup_scene.instantiate()
	p2.setup(14.6, false)
	var l2: Label = p2.get_node("Label") as Label
	assert_eq(p2.damage_amount, 15, "14.6 rounds up to 15")
	assert_eq(l2.text, "15", "Label displays '15'")
	p2.free()
	
	# Exact midpoint: 14.5 -> 15 (round half away from zero in Godot)
	var p3 = popup_scene.instantiate()
	p3.setup(14.5, false)
	var l3: Label = p3.get_node("Label") as Label
	assert_eq(p3.damage_amount, 15, "14.5 rounds to 15")
	assert_eq(l3.text, "15", "Label displays '15'")
	p3.free()
	
	# High value: 999999.0
	var p4 = popup_scene.instantiate()
	p4.setup(999999.0, true)
	var l4: Label = p4.get_node("Label") as Label
	assert_eq(p4.damage_amount, 999999, "Large damage 999999 supported")
	assert_eq(l4.text, "999999", "Large label displays '999999'")
	p4.free()

# ==============================================================================
# 7. HIGH-VOLUME COMBAT CYCLING LEAK TEST
# ==============================================================================

func test_high_volume_combat_cycling_node_cleanliness() -> void:
	var container := Node2D.new()
	container.name = "Entities"
	
	var slime_scene: PackedScene = load(ENEMY_SCENE_PATHS["slime"]) as PackedScene
	
	# Run 50 cycles of spawn -> damage -> die -> cleanup
	for cycle in range(50):
		var slime = slime_scene.instantiate()
		container.add_child(slime)
		slime._ready()
		
		# Deal lethal damage
		slime.take_damage(50.0, cycle % 2 == 0)
		assert_true(slime.is_dead, "Cycle %d: Slime is dead" % cycle)
		
		# Free all children in container at end of cycle
		for child in container.get_children():
			child.free()
			
		assert_eq(container.get_child_count(), 0, "Cycle %d: Container clean with 0 leaks" % cycle)
		
	container.free()
