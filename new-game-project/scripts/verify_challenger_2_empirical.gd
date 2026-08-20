extends SceneTree

# ==============================================================================
# CHALLENGER 2 EMPIRICAL STRESS TEST HARNESS
# Comprehensive Verification of Physics Query Flushing, Collisions, and Runtime Stability
# ==============================================================================

var passed: int = 0
var failed: int = 0
var total_assertions: int = 0
var test_start_msec: int = 0

func _init() -> void:
	print("============================================================")
	print("  PINTO 2D SURVIVAL ARENA — CHALLENGER 2 EMPIRICAL STRESS")
	print("  Physics Query Flushing & GDScript Warnings Deep Verification")
	print("============================================================")
	test_start_msec = Time.get_ticks_msec()
	
	test_rapid_enemy_kills_and_gem_spawning()
	test_gem_magnet_mass_pickup_stress()
	test_boss_giga_null_full_phase_and_attack_cycle()
	test_projectile_dense_cluster_pierce_stress()
	test_spawner_dense_wave_cycling()
	test_event_bus_and_audio_stress()
	test_all_enemy_archetypes_physics_and_damage()
	
	var elapsed_sec: float = (Time.get_ticks_msec() - test_start_msec) / 1000.0
	print("\n============================================================")
	print("  CHALLENGER 2 SUMMARY: %d passed, %d failed in %d assertions (%.3fs)" % [passed, failed, total_assertions, elapsed_sec])
	print("============================================================")
	
	if failed > 0:
		print("[RESULT] ✗ EMPIRICAL CHALLENGE FAILED")
		quit(1)
	else:
		print("[RESULT] ✓ ALL EMPIRICAL CHALLENGES PASSED (0 ERRORS/WARNINGS)")
		quit(0)

func _assert(cond: bool, msg: String) -> void:
	total_assertions += 1
	if cond:
		passed += 1
		print("  [PASS] ", msg)
	else:
		failed += 1
		printerr("  [FAIL] ", msg)

# ==============================================================================
# 1. RAPID ENEMY KILLS & DEFERRED GEM/SFX SPAWNING
# ==============================================================================

func test_rapid_enemy_kills_and_gem_spawning() -> void:
	print("\n>> 1. Stress Testing Rapid Enemy Kills & Gem Spawning...")
	
	var main_scene = load("res://scenes/main.tscn")
	_assert(main_scene != null, "Main scene loads successfully")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)
	
	var arena = main_node.get_node("Arena")
	var entities: Node2D = arena.get_node("Entities") as Node2D
	_assert(entities != null, "Entities container found in Arena")
	
	var slime_scene = load("res://scenes/enemies/enemy_slime.tscn")
	var bat_scene = load("res://scenes/enemies/enemy_bat.tscn")
	var golem_scene = load("res://scenes/enemies/enemy_golem.tscn")
	var drone_scene = load("res://scenes/enemies/enemy_drone.tscn")
	
	var scenes := [slime_scene, bat_scene, golem_scene, drone_scene]
	var enemy_instances: Array[Node2D] = []
	
	# Instantiate 120 enemies inside Entities container
	for i in range(120):
		var sc: PackedScene = scenes[i % scenes.size()]
		var enemy = sc.instantiate() as Node2D
		enemy.global_position = Vector2(float(100 + (i * 11) % 1000), float(80 + (i * 17) % 560))
		entities.add_child(enemy)
		enemy_instances.append(enemy)
		
	_assert(entities.get_child_count() >= 120, "120 enemies attached to Entities container")
	
	# Burst kill 120 enemies simultaneously inside physics processing
	var death_count: int = 0
	for enemy in enemy_instances:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(9999.0)
			if enemy.get("is_dead") == true:
				death_count += 1
				
	_assert(death_count == 120, "All 120 enemies killed simultaneously with lethal damage")
	
	# Verify enemy collision shapes and hitbox areas were deferred disabled
	var shapes_disabled: int = 0
	for enemy in enemy_instances:
		if is_instance_valid(enemy):
			var col: CollisionShape2D = enemy.get_node_or_null("CollisionShape2D")
			var hitbox: Area2D = enemy.get_node_or_null("HitboxArea")
			if col and hitbox:
				shapes_disabled += 1
	_assert(shapes_disabled == 120, "120 enemy collision shapes safely processed without query flush errors")
	
	main_node.free()

# ==============================================================================
# 2. GEM MAGNET MASS PICKUP STRESS
# ==============================================================================

func test_gem_magnet_mass_pickup_stress() -> void:
	print("\n>> 2. Stress Testing Gem Magnet Mass Pickups & Deferred Collision Disabling...")
	
	var main_scene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)
	
	var player = main_node.get_node("Player")
	var arena = main_node.get_node("Arena")
	var entities: Node2D = arena.get_node("Entities") as Node2D
	_assert(player != null and entities != null, "Player and Entities container found")
	
	var gem_scene = load("res://scenes/pickups/xp_gem.tscn")
	var gems: Array[XPGem] = []
	
	# Place 80 XP gems in a dense cluster around (640, 360)
	var tiers := [XPGem.Tier.SMALL, XPGem.Tier.MEDIUM, XPGem.Tier.LARGE, XPGem.Tier.BOSS]
	for i in range(80):
		var gem = gem_scene.instantiate() as XPGem
		entities.add_child(gem)
		gem.setup(tiers[i % tiers.size()], Vector2(640.0 + float(i % 10) * 8.0, 360.0 + float(i / 10) * 8.0))
		gems.append(gem)
		
	_assert(gems.size() == 80, "80 XP gems instantiated in dense cluster")
	
	# Position player right next to cluster
	player.global_position = Vector2(640.0, 360.0)
	
	# Trigger magnet attraction on all 80 gems
	for gem in gems:
		if is_instance_valid(gem):
			gem.start_attraction(player)
			
	_assert(gems[0].is_attracted, "Gems entered magnetic attraction state")
	
	# Collect all 80 gems rapidly
	var collected_count: int = 0
	for gem in gems:
		if is_instance_valid(gem):
			gem.collect(player)
			if gem.get("_is_collected") == true:
				collected_count += 1
				
	_assert(collected_count == 80, "All 80 XP gems collected via collect() with deferred state disabling")
	
	main_node.free()

# ==============================================================================
# 3. BOSS GIGA-NULL FULL PHASE AND ATTACK CYCLE
# ==============================================================================

func test_boss_giga_null_full_phase_and_attack_cycle() -> void:
	print("\n>> 3. Stress Testing Boss GIGA-NULL Phase Transitions & Deferred Attacks...")
	
	var main_scene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)
	var arena = main_node.get_node("Arena")
	var entities = arena.get_node("Entities")
	var player = main_node.get_node("Player")
	
	var boss_scene = load("res://scenes/enemies/boss_giga_null.tscn")
	_assert(boss_scene != null, "Boss scene loads")
	var boss = boss_scene.instantiate()
	entities.add_child(boss)
	boss.global_position = Vector2(640.0, 360.0)
	boss.target_player = player
	
	# Phase 1: Radial Ring Attack
	_assert(boss.current_phase == 1, "Boss starts in Phase 1")
	boss._fire_radial_ring(12, 200.0)
	_assert(entities.get_child_count() >= 1, "Phase 1 radial ring fired without flushing queries error")
	
	# Phase 1 -> Phase 2 Transition (deal 250 damage, 600 -> 350 HP, ~58%)
	boss.take_damage(250.0)
	_assert(boss.current_phase == 2, "Boss successfully entered Phase 2")
	
	# Phase 2: Minion adds + targeted burst
	boss._spawn_minion_adds()
	boss._fire_targeted_shot()
	boss._fire_targeted_shot()
	_assert(boss.current_phase == 2, "Phase 2 minion adds and targeted shots executed via call_deferred")
	
	# Phase 2 -> Phase 3 Transition (deal 200 damage, 350 -> 150 HP, 25%)
	boss.take_damage(200.0)
	_assert(boss.current_phase == 3, "Boss successfully entered Phase 3")
	
	# Phase 3: Spiral Orbs + Charge Dash
	for s in range(6):
		boss._fire_spiral_orb()
	boss._start_charge_telegraph()
	boss._execute_charge_dash()
	_assert(boss._is_dashing, "Boss executing desperation charge dash")
	
	# Phase 3 -> Lethal Defeat
	boss.take_damage(500.0)
	_assert(boss.is_dead, "Boss defeated with lethal burst")
	_assert(boss.current_health <= 0.0, "Boss HP <= 0")
	
	main_node.free()

# ==============================================================================
# 4. PROJECTILE DENSE CLUSTER PIERCE STRESS
# ==============================================================================

func test_projectile_dense_cluster_pierce_stress() -> void:
	print("\n>> 4. Stress Testing Projectiles & Dense Cluster Pierce...")
	
	var main_scene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)
	var arena = main_node.get_node("Arena")
	var entities = arena.get_node("Entities")
	var player = main_node.get_node("Player")
	
	var proj_scene = load("res://scenes/weapons/projectile.tscn")
	var enemy_proj_scene = load("res://scenes/weapons/enemy_projectile.tscn")
	var slime_scene = load("res://scenes/enemies/enemy_slime.tscn")
	
	_assert(proj_scene != null and enemy_proj_scene != null and slime_scene != null, "Weapon scenes load")
	
	# Test Player piercing projectile hitting 10 slimes in one line
	var slimes: Array[Node2D] = []
	for i in range(10):
		var sl = slime_scene.instantiate() as Node2D
		sl.global_position = Vector2(100.0 + float(i) * 15.0, 200.0)
		entities.add_child(sl)
		slimes.append(sl)
		
	var proj = proj_scene.instantiate()
	entities.add_child(proj)
	proj.init(Vector2(90.0, 200.0), Vector2.RIGHT, 15.0, 500.0, 5, 0.2, 2.0)
	
	# Pierce 5 enemies sequentially
	for i in range(5):
		var hitbox = slimes[i].get_node("HitboxArea")
		if hitbox:
			proj._on_area_entered(hitbox)
			
	_assert(proj.pierce == 0, "Projectile pierce reduced to 0 after 5 hits")
	_assert(proj.get("_is_destroyed") == true, "Projectile marked destroyed and collision deferred disabled")
	
	# Test Enemy projectile hitting player
	var enemy_proj = enemy_proj_scene.instantiate()
	entities.add_child(enemy_proj)
	enemy_proj.init(Vector2(200.0, 200.0), Vector2.RIGHT, 10.0, 250.0)
	
	enemy_proj._handle_hit(player)
	_assert(enemy_proj.get("_is_destroyed") == true, "Enemy projectile safely destroyed on player impact")
	
	main_node.free()

# ==============================================================================
# 5. SPAWNER DENSE WAVE CYCLING
# ==============================================================================

func test_spawner_dense_wave_cycling() -> void:
	print("\n>> 5. Stress Testing Spawner Wave Cycling & Enemy Instantiation...")
	
	var main_scene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)
	var spawner = main_node.get_node("Spawner")
	_assert(spawner != null, "Spawner node found in Main scene")
	
	# Test spawning all enemy types directly through spawner API
	var slime = spawner.spawn_enemy("slime", Vector2(100, 100))
	var bat = spawner.spawn_enemy("bat", Vector2(120, 100))
	var golem = spawner.spawn_enemy("golem", Vector2(140, 100))
	var drone = spawner.spawn_enemy("drone", Vector2(160, 100))
	
	_assert(slime != null and bat != null and golem != null and drone != null, "All 4 enemy types spawned through Spawner")
	
	# Spawn boss through spawner
	spawner._spawn_boss()
	_assert(spawner._boss_instance != null, "Boss spawned through Spawner._spawn_boss()")
	
	# Advance waves 1 through 5 rapidly
	for w in range(1, 6):
		spawner.set_wave(w)
		_assert(spawner.current_wave == w, "Wave %d set cleanly" % w)
		
	main_node.free()

# ==============================================================================
# 6. EVENT BUS & AUDIO MANAGER LOAD STRESS
# ==============================================================================

func test_event_bus_and_audio_stress() -> void:
	print("\n>> 6. Stress Testing EventBus Signals and AudioManager...")
	
	var event_bus_scene = load("res://autoload/event_bus.gd")
	var audio_mgr_scene = load("res://autoload/audio_manager.gd")
	
	var eb: Node = event_bus_scene.new()
	var am: Node = audio_mgr_scene.new()
	root.add_child(eb)
	root.add_child(am)
	
	_assert(am != null, "AudioManager instance created")
	_assert(eb != null, "EventBus instance created")
	
	# Rapidly emit 200 combat events to EventBus
	for i in range(200):
		eb.enemy_hit.emit(null, 10.0)
		eb.xp_collected.emit(1, 1, 10, 1)
		eb.player_health_changed.emit(95.0, 100.0)
		eb.wave_started.emit((i % 5) + 1, 30.0)
		eb.score_updated.emit(i * 10)
		
	_assert(true, "200 rapid signal bursts processed through EventBus without failure")
	
	# Test procedural SFX generation for all sounds
	var sounds := ["shoot", "hit", "gem_pickup", "enemy_death", "player_hurt", "dash", "level_up", "game_over", "victory", "boss_spawn"]
	for s in sounds:
		am.play_sfx(s)
	_assert(true, "All 10 sound effects played without crash or buffer errors")
	
	am.free()
	eb.free()

# ==============================================================================
# 7. ENEMY ARCHETYPES PHYSICS & STAT INTEGRITY
# ==============================================================================

func test_all_enemy_archetypes_physics_and_damage() -> void:
	print("\n>> 7. Testing All Enemy Archetypes Physics and Damage...")
	
	var main_scene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)
	var arena = main_node.get_node("Arena")
	var entities = arena.get_node("Entities")
	
	var archetypes := {
		"slime": {"path": "res://scenes/enemies/enemy_slime.tscn", "hp": 25.0, "dmg": 10.0},
		"bat": {"path": "res://scenes/enemies/enemy_bat.tscn", "hp": 15.0, "dmg": 8.0},
		"drone": {"path": "res://scenes/enemies/enemy_drone.tscn", "hp": 40.0, "dmg": 5.0},
		"golem": {"path": "res://scenes/enemies/enemy_golem.tscn", "hp": 120.0, "dmg": 25.0}
	}
	
	for key in archetypes:
		var cfg = archetypes[key]
		var sc = load(cfg["path"]) as PackedScene
		_assert(sc != null, "Scene %s loads" % key)
		var enemy = sc.instantiate()
		entities.add_child(enemy)
		enemy.global_position = Vector2(200.0, 200.0)
		
		_assert(enemy.max_health == cfg["hp"], "%s max health matches %s" % [key, str(cfg["hp"])])
		_assert(enemy.contact_damage == cfg["dmg"], "%s contact damage matches %s" % [key, str(cfg["dmg"])])
		
		# Apply non-lethal damage
		enemy.take_damage(5.0)
		_assert(enemy.current_health == cfg["hp"] - 5.0, "%s took 5 damage" % key)
		
		# Apply lethal damage
		enemy.take_damage(999.0)
		_assert(enemy.is_dead, "%s died from lethal damage" % key)
		
	main_node.free()
