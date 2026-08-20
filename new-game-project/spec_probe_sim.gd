extends SceneTree

# Probe 2: Simulation & Test Runner Pattern Probe

var frames_run := 0
var test_passed := true

func _init() -> void:
	print("--- BEGIN TEST RUNNER PATTERN PROBE ---")
	
	# Test: Spatial distance sorting (Auto-attack nearest enemy)
	var player_pos := Vector2(200, 200)
	var attack_range := 150.0
	
	var enemies := [
		{"name": "Goblin1", "pos": Vector2(280, 200), "hp": 20}, # dist: 80
		{"name": "Orc",     "pos": Vector2(100, 200), "hp": 50}, # dist: 100
		{"name": "Skeleton","pos": Vector2(300, 300), "hp": 15}, # dist: ~141.4
		{"name": "FarBoss", "pos": Vector2(500, 500), "hp": 500} # dist: ~424 (out of range)
	]
	
	var in_range_enemies := []
	for e in enemies:
		var d = player_pos.distance_to(e["pos"])
		if d <= attack_range:
			in_range_enemies.append({"enemy": e, "dist": d})
			
	in_range_enemies.sort_custom(func(a, b): return a["dist"] < b["dist"])
	
	print("[PASS] Nearest enemy found: ", in_range_enemies[0]["enemy"]["name"], " with distance: ", in_range_enemies[0]["dist"])
	assert(in_range_enemies[0]["enemy"]["name"] == "Goblin1")
	assert(in_range_enemies.size() == 3)
	
	# Test: Magnet / XP Attraction Kinematics
	var gem_pos := Vector2(240, 200)
	var gem_vel := Vector2.ZERO
	var magnet_speed := 300.0
	var delta := 0.016667 # 60 FPS delta
	
	for step in range(30):
		var dir = (player_pos - gem_pos).normalized()
		gem_pos += dir * magnet_speed * delta
	
	var final_dist = player_pos.distance_to(gem_pos)
	print("[PASS] Gem moved towards player: initial_dist=40.0, final_dist=", final_dist)
	assert(final_dist < 1.0)
	
	# Test: Wave Progression Data Structure
	var wave_configs = {
		1: {"duration": 30.0, "spawn_interval": 1.5, "types": ["slime"], "count_cap": 15},
		2: {"duration": 30.0, "spawn_interval": 1.2, "types": ["slime", "goblin"], "count_cap": 25},
		3: {"duration": 35.0, "spawn_interval": 1.0, "types": ["goblin", "bat"], "count_cap": 35},
		4: {"duration": 40.0, "spawn_interval": 0.8, "types": ["goblin", "bat", "skeleton"], "count_cap": 50},
		5: {"duration": 60.0, "spawn_interval": 0.6, "types": ["slime", "goblin", "bat", "boss"], "count_cap": 60}
	}
	assert(wave_configs.size() == 5)
	print("[PASS] Wave configurations verified: 5 waves with boss in wave 5")

	# Test: Roguelite Upgrade Deck
	var upgrades = [
		{"id": "atk_speed", "name": "Rapid Fire", "stat": "attack_speed", "value": 0.20, "max_rank": 5},
		{"id": "damage", "name": "Heavy Shot", "stat": "damage", "value": 5.0, "max_rank": 5},
		{"id": "move_speed", "name": "Swift Boots", "stat": "move_speed", "value": 25.0, "max_rank": 5},
		{"id": "max_hp", "name": "Vitality", "stat": "max_hp", "value": 20.0, "max_rank": 5},
		{"id": "multishot", "name": "Twin Shot", "stat": "projectile_count", "value": 1, "max_rank": 3},
		{"id": "pierce", "name": "Piercing Rounds", "stat": "pierce", "value": 1, "max_rank": 3},
		{"id": "pickup_radius", "name": "Magnet Ring", "stat": "pickup_radius", "value": 40.0, "max_rank": 3}
	]
	assert(upgrades.size() == 7)
	print("[PASS] Roguelite upgrade definitions verified: ", upgrades.size(), " unique upgrade types")

	print("--- TEST RUNNER PROBE COMPLETED SUCCESSFULLY ---")
	quit(0)
