# Pinto 2D Top-Down Survival Arena — Test Infrastructure Specification

## Overview
The testing infrastructure for Pinto 2D Top-Down Survival Arena is a zero-dependency, headless test framework and test runner built specifically for Godot 4.7.2.

It requires no external plugins or editor addons, executing standalone via Godot CLI `--headless` mode, producing human-readable structured output with line-by-line assertions and terminating with strict non-zero exit codes on failure (`quit(0)` on pass, `quit(1)` on failure).

---

## Directory Structure
```
new-game-project/tests/
├── test_framework.gd             # Base TestSuite class with rich assertion library & lifecycle hooks
├── test_runner.gd                # SceneTree test runner discovering & executing all test suites
├── test_player_movement.gd       # R1: 8-dir movement, floating kinematics, damping, speed clamping
├── test_player_combat.gd         # R1: Auto-targeting nearest enemy, ballistics, multi-shot spread, pierce
├── test_waves_and_enemies.gd     # R2: 5 escalating waves schedule/mix, 4 enemy archetypes, Boss 3-phase state machine
├── test_xp_and_magnet.gd         # R2: Tiered XP gem values, magnet physics acceleration, quadratic curve XP_req(L)
├── test_roguelite_upgrades.gd    # R3: 3-card random non-duplicate draft, pause mode, 10 upgrade stat modifications
├── test_arena_and_collisions.gd  # R4: 1280x720 enclosed bounds, collision layer matrix, Y-sorting depth anchors
└── test_hud_and_persistence.gd   # R5: Real-time HUD formatting, win/loss triggers, save/load roundtrips & error recovery
```

---

## Assertion Library (`res://tests/test_framework.gd`)
The `TestSuite` base class provides the following assertions:

| Method | Description |
|---|---|
| `assert_true(condition, msg)` | Asserts that condition evaluates to `true` |
| `assert_false(condition, msg)` | Asserts that condition evaluates to `false` |
| `assert_eq(actual, expected, msg)` | Asserts strict equality between two values |
| `assert_ne(actual, expected, msg)` | Asserts inequality between two values |
| `assert_almost_eq(actual, expected, tol, msg)` | Asserts numerical or vector closeness within tolerance |
| `assert_gt(actual, expected, msg)` | Asserts `actual > expected` |
| `assert_gte(actual, expected, msg)` | Asserts `actual >= expected` |
| `assert_lt(actual, expected, msg)` | Asserts `actual < expected` |
| `assert_lte(actual, expected, msg)` | Asserts `actual <= expected` |
| `assert_null(actual, msg)` | Asserts value is `null` |
| `assert_not_null(actual, msg)` | Asserts value is non-null |
| `assert_has(container, key_or_item, msg)` | Asserts Dictionary/Array/String contains item |
| `assert_array_size(arr, size, msg)` | Asserts Array has expected size |
| `assert_in_range(val, min, max, msg)` | Asserts float is in range `[min, max]` |
| `assert_signal_emitted(emitter, signal, action, msg)` | Connects listener, runs action, asserts emission |

### Test Lifecycle
Each test suite can override standard lifecycle methods:
- `before_all()`: Runs once before any tests in the suite.
- `before_each()`: Runs before each `test_*()` method.
- `after_each()`: Runs after each `test_*()` method.
- `after_all()`: Runs once after all tests in the suite have executed (e.g. for cleaning up temporary files).

---

## Test Execution Command
To run all test suites headlessly:

```powershell
& "C:\Users\ovens\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path "c:/Work/game/pinto-2d-top-down/new-game-project" -s res://tests/test_runner.gd
```

---

## CI / Automated Pipeline Exit Codes
- `0`: All test suites executed and all assertions passed.
- `1`: One or more assertions failed or a test suite failed to load/compile.
