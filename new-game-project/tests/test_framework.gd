# res://tests/test_framework.gd
# Zero-dependency, headless test assertion framework for Godot 4.7.2
class_name TestSuite
extends RefCounted

var suite_name: String = "TestSuite"
var current_test_name: String = ""
var passed_count: int = 0
var failed_count: int = 0
var total_assertions: int = 0

var current_test_assertions: int = 0
var current_test_errors: Array[String] = []
var test_results: Array[Dictionary] = []

func _init(p_suite_name: String = "") -> void:
	if p_suite_name != "":
		suite_name = p_suite_name
	else:
		suite_name = get_script().resource_path.get_file().get_basename()

# Lifecycle methods (override in subclasses)
func before_all() -> void:
	pass

func before_each() -> void:
	pass

func after_each() -> void:
	pass

func after_all() -> void:
	pass

# --- Assertion Library ---

func assert_true(condition: bool, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	if not condition:
		var err_msg = "Expected TRUE, got FALSE"
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

func assert_false(condition: bool, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	if condition:
		var err_msg = "Expected FALSE, got TRUE"
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

func assert_eq(actual: Variant, expected: Variant, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	if actual != expected:
		var err_msg = "Expected '%s' (type %s), got '%s' (type %s)" % [
			str(expected), type_string(typeof(expected)),
			str(actual), type_string(typeof(actual))
		]
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

func assert_ne(actual: Variant, expected: Variant, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	if actual == expected:
		var err_msg = "Expected value NOT equal to '%s', but values matched" % [str(expected)]
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

func assert_almost_eq(actual: Variant, expected: Variant, tolerance: float = 0.001, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	var is_close: bool = false
	
	if typeof(actual) == TYPE_FLOAT or typeof(actual) == TYPE_INT:
		is_close = abs(float(actual) - float(expected)) <= tolerance
	elif typeof(actual) == TYPE_VECTOR2 and typeof(expected) == TYPE_VECTOR2:
		is_close = (actual as Vector2).distance_to(expected as Vector2) <= tolerance
	elif typeof(actual) == TYPE_VECTOR3 and typeof(expected) == TYPE_VECTOR3:
		is_close = (actual as Vector3).distance_to(expected as Vector3) <= tolerance
	else:
		is_close = (actual == expected)
		
	if not is_close:
		var err_msg = "Expected '%s' ≈ '%s' (tolerance ±%s), diff=%s" % [
			str(actual), str(expected), str(tolerance),
			str(abs(float(actual) - float(expected)) if (typeof(actual) == TYPE_FLOAT or typeof(actual) == TYPE_INT) else str(actual.distance_to(expected)))
		]
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

func assert_gt(actual: Variant, expected: Variant, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	if not (actual > expected):
		var err_msg = "Expected '%s' > '%s'" % [str(actual), str(expected)]
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

func assert_gte(actual: Variant, expected: Variant, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	if not (actual >= expected):
		var err_msg = "Expected '%s' >= '%s'" % [str(actual), str(expected)]
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

func assert_lt(actual: Variant, expected: Variant, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	if not (actual < expected):
		var err_msg = "Expected '%s' < '%s'" % [str(actual), str(expected)]
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

func assert_lte(actual: Variant, expected: Variant, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	if not (actual <= expected):
		var err_msg = "Expected '%s' <= '%s'" % [str(actual), str(expected)]
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

func assert_null(actual: Variant, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	if actual != null:
		var err_msg = "Expected null, got '%s'" % [str(actual)]
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

func assert_not_null(actual: Variant, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	if actual == null:
		var err_msg = "Expected non-null value, got null"
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

func assert_has(container: Variant, key_or_item: Variant, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	var has_item: bool = false
	if typeof(container) == TYPE_DICTIONARY:
		has_item = (container as Dictionary).has(key_or_item)
	elif typeof(container) == TYPE_ARRAY:
		has_item = (container as Array).has(key_or_item)
	elif typeof(container) == TYPE_STRING:
		has_item = (container as String).contains(str(key_or_item))
	
	if not has_item:
		var err_msg = "Expected container to contain '%s'" % [str(key_or_item)]
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

func assert_array_size(arr: Array, expected_size: int, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	if arr.size() != expected_size:
		var err_msg = "Expected Array size %d, got %d" % [expected_size, arr.size()]
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

func assert_in_range(value: float, min_val: float, max_val: float, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	if value < min_val or value > max_val:
		var err_msg = "Expected value %s to be within [%s, %s]" % [str(value), str(min_val), str(max_val)]
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

func assert_has_str(haystack: String, needle: String, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	if not haystack.contains(needle):
		var err_msg = "Expected string '%s' to contain '%s'" % [haystack, needle]
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

# --- Signal Assertion Helper ---
func assert_signal_emitted(emitter: Object, signal_name: String, action: Callable, message: String = "") -> bool:
	total_assertions += 1
	current_test_assertions += 1
	if emitter == null or not emitter.has_signal(signal_name):
		var err_msg = "Emitter does not possess signal '%s'" % [signal_name]
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	
	var emitted_box := [false]
	var listener = func(_a=null, _b=null, _c=null, _d=null, _e=null):
		emitted_box[0] = true
	
	emitter.connect(signal_name, listener, CONNECT_ONE_SHOT)
	action.call()
	
	if not emitted_box[0]:
		if emitter.is_connected(signal_name, listener):
			emitter.disconnect(signal_name, listener)
		var err_msg = "Signal '%s' was NOT emitted during action" % [signal_name]
		if message != "":
			err_msg += " (" + message + ")"
		current_test_errors.append(err_msg)
		return false
	return true

# --- Execution Engine ---

func run_all_tests() -> Dictionary:
	passed_count = 0
	failed_count = 0
	total_assertions = 0
	test_results.clear()
	
	before_all()
	
	var methods := get_method_list()
	var test_method_names: Array[String] = []
	for m in methods:
		var m_name: String = m.get("name", "")
		if m_name.begins_with("test_"):
			test_method_names.append(m_name)
	
	# Stable sort for deterministic test execution order
	test_method_names.sort()
	
	for method_name in test_method_names:
		current_test_name = method_name
		current_test_assertions = 0
		current_test_errors.clear()
		
		before_each()
		
		# Call test method
		call(method_name)
		
		after_each()
		
		var test_passed: bool = (current_test_errors.size() == 0)
		if test_passed:
			passed_count += 1
		else:
			failed_count += 1
			
		test_results.append({
			"test": method_name,
			"passed": test_passed,
			"assertions": current_test_assertions,
			"errors": current_test_errors.duplicate()
		})
	
	after_all()
	
	return {
		"suite": suite_name,
		"passed": passed_count,
		"failed": failed_count,
		"total_tests": test_method_names.size(),
		"total_assertions": total_assertions,
		"results": test_results
	}
