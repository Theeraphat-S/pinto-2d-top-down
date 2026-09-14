# res://tests/test_visual_juice_and_lighting.gd
# Milestone M11: Tests for Cyber-Neon Visuals, 2D Lighting, Procedural Juice, and VFX
extends "res://tests/test_framework.gd"

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")
const PROJECTILE_SCENE = preload("res://scenes/weapons/projectile.tscn")
const ARENA_SCENE = preload("res://scenes/world/arena.tscn")
const MAIN_SCENE = preload("res://scenes/main.tscn")
const PROP_SCENE = preload("res://scenes/world/prop.tscn")
const SLIME_SCENE = preload("res://scenes/enemies/enemy_slime.tscn")
const BOSS_SCENE = preload("res://scenes/enemies/boss_giga_null.tscn")
const HUD_SCENE = preload("res://scenes/ui/hud.tscn")
const PropScript = preload("res://scenes/world/prop.gd")

func test_radial_light_resource_exists_and_properties() -> void:
	var light_res = load("res://assets/sprites/radial_light.tres")
	assert_not_null(light_res, "Radial light resource exists")
	assert_true(light_res is GradientTexture2D, "Resource is GradientTexture2D")
	var grad_tex := light_res as GradientTexture2D
	assert_eq(grad_tex.width, 128, "Width is 128px")
	assert_eq(grad_tex.height, 128, "Height is 128px")
	assert_eq(grad_tex.fill, GradientTexture2D.FILL_RADIAL, "Fill mode is FILL_RADIAL")

func test_arena_canvas_modulate_color() -> void:
	var arena = ARENA_SCENE.instantiate()
	assert_not_null(arena, "Arena instantiates")
	assert_true(arena.has_node("CanvasModulate"), "Arena contains CanvasModulate")
	var cm = arena.get_node("CanvasModulate") as CanvasModulate
	assert_not_null(cm, "CanvasModulate node valid")
	assert_almost_eq(cm.color.r, 0.27, 0.05, "Modulate R is dark slate-navy (~0.27)")
	assert_almost_eq(cm.color.g, 0.30, 0.05, "Modulate G is dark slate-navy (~0.30)")
	assert_almost_eq(cm.color.b, 0.40, 0.05, "Modulate B is dark slate-navy (~0.40)")
	arena.free()

func test_main_world_environment_glow() -> void:
	var main = MAIN_SCENE.instantiate()
	assert_not_null(main, "Main scene instantiates")
	assert_true(main.has_node("WorldEnvironment"), "Main scene contains WorldEnvironment")
	var we = main.get_node("WorldEnvironment") as WorldEnvironment
	assert_not_null(we, "WorldEnvironment valid")
	assert_not_null(we.environment, "Environment resource assigned")
	assert_true(we.environment.glow_enabled, "Glow is enabled")
	assert_almost_eq(we.environment.glow_hdr_threshold, 1.0, 0.01, "Glow HDR threshold is 1.0")
	main.free()

func test_player_light_aura_and_procedural_properties() -> void:
	var player = PLAYER_SCENE.instantiate()
	assert_not_null(player, "Player instantiates")
	assert_true(player.has_node("LightAura"), "Player contains LightAura node")
	var aura = player.get_node("LightAura") as PointLight2D
	assert_not_null(aura, "LightAura is PointLight2D")
	assert_gt(aura.energy, 0.5, "LightAura energy > 0.5")
	assert_not_null(aura.texture, "LightAura has texture")
	
	# Check initial procedural variables
	assert_almost_eq(player._recoil_offset.x, 0.0, 0.001, "Initial recoil X is 0")
	assert_almost_eq(player._recoil_offset.y, 0.0, 0.001, "Initial recoil Y is 0")
	player.free()

func test_player_recoil_decay_and_movement_bob() -> void:
	var player = PLAYER_SCENE.instantiate()
	player._ready()
	
	# Simulate recoil impulse
	player._recoil_offset = Vector2(-2.5, 0.0)
	assert_almost_eq(player._recoil_offset.x, -2.5, 0.001, "Recoil offset set")
	
	# Run _update_animation with delta to decay recoil
	player._update_animation(Vector2.ZERO, 0.1)
	assert_gt(player._recoil_offset.x, -2.5, "Recoil decaying toward 0")
	
	# Run several steps to return to zero
	for i in range(10):
		player._update_animation(Vector2.ZERO, 0.1)
	assert_almost_eq(player._recoil_offset.x, 0.0, 0.01, "Recoil fully restored to 0")
	player.free()

func test_projectile_trail_setup_and_properties() -> void:
	var proj = PROJECTILE_SCENE.instantiate()
	proj._ready()
	assert_not_null(proj.trail, "Projectile creates trail Line2D")
	assert_true(proj.trail.top_level, "Trail has top_level true for global drawing")
	assert_gt(proj.trail.width, 1.0, "Trail has width > 1.0")
	assert_not_null(proj.trail.gradient, "Trail has gradient")
	assert_eq(proj.MAX_TRAIL_POINTS, 5, "MAX_TRAIL_POINTS is 5 per spec")
	
	# Simulate movement and destroy
	proj._physics_process(0.1)
	assert_gt(proj._trail_points.size(), 0, "Trail points accumulated")
	proj._destroy()
	assert_eq(proj._trail_points.size(), 0, "Trail points cleared on destroy")
	assert_false(proj.trail.visible, "Trail hidden on destroy")
	proj.free()

func test_prop_light_setup_all_types() -> void:
	var prop = PROP_SCENE.instantiate()
	prop._ready()
	assert_not_null(prop.prop_light, "Prop has prop_light PointLight2D")
	
	var prop_types: Array = [
		PropScript.PropType.SERVER_RACK,
		PropScript.PropType.HOLOGRAM_PYLON,
		PropScript.PropType.POWER_CRYSTAL,
		PropScript.PropType.TERMINAL_CONSOLE
	]
	
	for pt in prop_types:
		prop.set_prop_type(pt)
		assert_not_null(prop.prop_light.texture, "Prop type %d light has texture" % int(pt))
		assert_gt(prop.prop_light.energy, 0.1, "Prop type %d light energy > 0.1" % int(pt))
	prop.free()

func test_elite_light_and_aura() -> void:
	var slime = SLIME_SCENE.instantiate()
	slime._ready()
	assert_false(slime.has_node("EliteLight"), "Non-elite has no EliteLight")
	
	slime.make_elite(3.5, 5, 1.5)
	assert_true(slime.has_node("EliteLight"), "Elite enemy creates EliteLight PointLight2D")
	var light = slime.get_node("EliteLight") as PointLight2D
	assert_gt(light.energy, 0.5, "EliteLight energy > 0.5")
	assert_almost_eq(light.color.r, 1.5, 0.1, "EliteLight is golden HDR (>1.0)")
	slime.free()

func test_boss_light_and_shockwave_properties() -> void:
	var boss = BOSS_SCENE.instantiate()
	boss._ready()
	assert_true(boss.has_node("BossLight"), "Boss has BossLight PointLight2D")
	assert_almost_eq(boss._shockwave_alpha, 0.0, 0.001, "Initial shockwave alpha is 0")
	assert_almost_eq(boss.P3_CHARGE_TELEGRAPH_DURATION, 0.4, 0.05, "Charge telegraph within 0.35-0.45s")
	
	# Simulate charge state and verify phase transition resets it
	boss._is_charging = true
	boss._dash_subtimer = 0.3
	boss._enter_phase(2)
	assert_false(boss._is_charging, "Phase transition cleanly resets charging state")
	assert_almost_eq(boss._dash_subtimer, 0.0, 0.001, "Dash subtimer reset to 0")
	assert_gt(boss._shockwave_alpha, 0.5, "Phase transition triggers shockwave alpha > 0.5")
	assert_gt(boss._shockwave_radius, 10.0, "Shockwave radius initialized > 10.0")
	boss.free()

func test_hud_vignette_and_damage_flash_state() -> void:
	var hud = HUD_SCENE.instantiate()
	hud._ready()
	
	# Verify dual-layer HealthCatchupBar existence
	assert_not_null(hud.hp_catchup_bar, "Dual-layer HealthCatchupBar created")
	assert_true(hud.hp_catchup_bar.show_behind_parent, "Catchup bar renders behind parent")
	
	# Normal health > 25%: low health false
	hud.update_health(100.0, 100.0)
	assert_false(hud._is_low_health, "100 HP is not low health")
	assert_almost_eq(hud.hp_catchup_bar.value, 100.0, 0.01, "Catchup bar value is 100")
	
	# Low health <= 25%: low health true
	hud.update_health(20.0, 100.0)
	assert_true(hud._is_low_health, "20 HP is low health (<= 25%)")
	
	# Dead (0 HP): low health vignette turns off
	hud.update_health(0.0, 100.0)
	assert_false(hud._is_low_health, "0 HP (dead) is not low health")
	hud.free()

func test_enemy_drop_shadows_and_micro_lights() -> void:
	var slime_scene: PackedScene = load("res://scenes/enemies/enemy_slime.tscn")
	var bat_scene: PackedScene = load("res://scenes/enemies/enemy_bat.tscn")
	var drone_scene: PackedScene = load("res://scenes/enemies/enemy_drone.tscn")
	var golem_scene: PackedScene = load("res://scenes/enemies/enemy_golem.tscn")
	var boss_scene: PackedScene = load("res://scenes/enemies/boss_giga_null.tscn")
	
	# 1. Slime Shadow
	var slime = slime_scene.instantiate() as EnemyBase
	slime._ready()
	assert_true(slime.show_shadow, "Slime has show_shadow true")
	assert_eq(slime._shadow_points.size(), 12, "Slime has 12 shadow polygon points")
	assert_gt(slime.shadow_radius.x, 0.0, "Slime shadow_radius.x > 0")
	slime.free()
	
	# 2. Bat Shadow & Elevation
	var bat = bat_scene.instantiate() as EnemyBase
	bat._ready()
	assert_true(bat.show_shadow, "Bat has show_shadow true")
	assert_eq(bat._shadow_points.size(), 12, "Bat has 12 shadow polygon points")
	bat._physics_process(0.016)
	assert_lt(bat.sprite.position.y, 0.0, "Bat sprite has negative y elevation offset (flight)")
	bat.free()
	
	# 3. Drone Shadow, Elevation & Micro-Light
	var drone = drone_scene.instantiate() as EnemyBase
	drone._ready()
	assert_true(drone.show_shadow, "Drone has show_shadow true")
	assert_eq(drone._shadow_points.size(), 12, "Drone has 12 shadow polygon points")
	assert_true(drone.has_node("DroneLight"), "Drone has DroneLight PointLight2D")
	var d_light = drone.get_node("DroneLight") as PointLight2D
	assert_gt(d_light.color.b, 1.0, "Drone light has HDR cyan glow")
	drone.free()
	
	# 4. Golem Shadow & Micro-Light
	var golem = golem_scene.instantiate() as EnemyBase
	golem._ready()
	assert_true(golem.show_shadow, "Golem has show_shadow true")
	assert_eq(golem._shadow_points.size(), 12, "Golem has 12 shadow polygon points")
	assert_true(golem.has_node("GolemLight"), "Golem has GolemLight PointLight2D")
	var g_light = golem.get_node("GolemLight") as PointLight2D
	assert_gt(g_light.color.r, 1.0, "Golem light has HDR amber glow")
	golem.free()
	
	# 5. Boss Shadow
	var boss = boss_scene.instantiate() as EnemyBase
	boss._ready()
	assert_true(boss.show_shadow, "Boss has show_shadow true")
	assert_eq(boss._shadow_points.size(), 12, "Boss has 12 shadow polygon points")
	assert_gt(boss.shadow_radius.x, 20.0, "Boss shadow radius is large")
	boss.free()

