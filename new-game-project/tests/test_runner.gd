# res://tests/test_runner.gd
# Headless SceneTree Test Runner CLI for Godot 4.7.2
extends SceneTree

const SUITE_PATHS: Array[String] = [
	"res://tests/test_player_movement.gd",
	"res://tests/test_player_combat.gd",
	"res://tests/test_waves_and_enemies.gd",
	"res://tests/test_xp_and_magnet.gd",
	"res://tests/test_roguelite_upgrades.gd",
	"res://tests/test_arena_and_collisions.gd",
	"res://tests/test_hud_and_persistence.gd",
	"res://tests/test_audio_manager.gd",
	"res://tests/test_m7_empirical_challenger.gd",
	"res://tests/test_r2_empirical_challenger.gd",
	"res://tests/test_camera_and_hud_clamping.gd",
	"res://tests/test_adversarial_stress.gd",
	"res://tests/test_adversarial_coverage.gd",
	"res://tests/test_enemy_animations_and_damage_popups.gd",
	"res://tests/test_combat_stress_and_boundary_conditions.gd"
]

func _init() -> void:
	print("============================================================")
	print("   PINTO 2D SURVIVAL ARENA — HEADLESS E2E TEST RUNNER")
	print("   Engine: Godot ", Engine.get_version_info().string)
	print("============================================================")
	
	var start_time_msec := Time.get_ticks_msec()
	
	var total_suites: int = 0
	var passed_suites: int = 0
	var failed_suites: int = 0
	
	var total_tests: int = 0
	var total_passed_tests: int = 0
	var total_failed_tests: int = 0
	var total_assertions: int = 0
	
	var failed_details: Array[Dictionary] = []
	
	for suite_path in SUITE_PATHS:
		if not ResourceLoader.exists(suite_path):
			printerr("[ERROR] Test suite file does not exist: ", suite_path)
			failed_suites += 1
			total_failed_tests += 1
			failed_details.append({
				"suite": suite_path,
				"test": "LOAD_ERROR",
				"errors": ["File not found: " + suite_path]
			})
			continue
			
		var script_res: GDScript = load(suite_path) as GDScript
		if script_res == null or not script_res.can_instantiate():
			printerr("[ERROR] Failed to load or compile GDScript: ", suite_path)
			failed_suites += 1
			total_failed_tests += 1
			failed_details.append({
				"suite": suite_path,
				"test": "LOAD_ERROR",
				"errors": ["Script compilation/load failure: " + suite_path]
			})
			continue
			
		var suite_instance = script_res.new()
		if not suite_instance.has_method("run_all_tests"):
			printerr("[ERROR] Test suite does not extend TestSuite or implement run_all_tests(): ", suite_path)
			failed_suites += 1
			total_failed_tests += 1
			continue
			
		total_suites += 1
		var suite_name: String = suite_path.get_file().get_basename()
		print("\n>> RUNNING SUITE: %s (%s)" % [suite_name, suite_path])
		
		var suite_report: Dictionary = suite_instance.run_all_tests()
		var suite_passed_tests: int = suite_report.get("passed", 0)
		var suite_failed_tests: int = suite_report.get("failed", 0)
		var suite_total_tests: int = suite_report.get("total_tests", 0)
		var suite_assertions: int = suite_report.get("total_assertions", 0)
		
		total_tests += suite_total_tests
		total_passed_tests += suite_passed_tests
		total_failed_tests += suite_failed_tests
		total_assertions += suite_assertions
		
		var results: Array = suite_report.get("results", [])
		for res in results:
			var test_name: String = res.get("test", "")
			var test_passed: bool = res.get("passed", false)
			var assertions_in_test: int = res.get("assertions", 0)
			var errors: Array = res.get("errors", [])
			
			if test_passed:
				print("  [PASS] %s (%d assertions)" % [test_name, assertions_in_test])
			else:
				print("  [FAIL] %s (%d assertions)" % [test_name, assertions_in_test])
				for err in errors:
					print("         └─ " + str(err))
				failed_details.append({
					"suite": suite_name,
					"test": test_name,
					"errors": errors
				})
		
		if suite_failed_tests == 0:
			passed_suites += 1
			print("✓ SUITE PASSED: %s (%d/%d tests, %d assertions)" % [suite_name, suite_passed_tests, suite_total_tests, suite_assertions])
		else:
			failed_suites += 1
			print("✗ SUITE FAILED: %s (%d passed, %d failed)" % [suite_name, suite_passed_tests, suite_failed_tests])
	
	var elapsed_sec: float = (Time.get_ticks_msec() - start_time_msec) / 1000.0
	
	print("\n============================================================")
	print("                    TEST RUN SUMMARY                        ")
	print("============================================================")
	print("  Execution Time   : %.3f s" % [elapsed_sec])
	print("  Test Suites      : %d Total (%d Passed, %d Failed)" % [total_suites, passed_suites, failed_suites])
	print("  Test Cases       : %d Total (%d Passed, %d Failed)" % [total_tests, total_passed_tests, total_failed_tests])
	print("  Total Assertions : %d" % [total_assertions])
	
	if total_failed_tests > 0:
		print("\n------------------------------------------------------------")
		print("  FAILURES (%d):" % [total_failed_tests])
		for fail in failed_details:
			print("  - [%s] %s" % [fail.get("suite"), fail.get("test")])
			for err in fail.get("errors", []):
				print("      └─ %s" % [str(err)])
		print("------------------------------------------------------------")
		print("\n[RESULT] ✗ TEST RUN FAILED.")
		quit(1)
	else:
		print("\n[RESULT] ✓ ALL %d TESTS IN %d SUITES PASSED SUCCESSFULLY!" % [total_tests, total_suites])
		quit(0)
