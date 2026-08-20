# Original User Request

## 2026-08-20T07:59:10Z

Fix the Catlike Coding True Top-Down 2D resolution setup and runtime errors in Pinto 2D Top-Down Survival Arena in Godot 4:

1. Resolution & Viewport (Fix black box around arena):
- In project.godot: Set viewport_width = 640, viewport_height = 360, stretch/mode = "canvas_items", stretch/aspect = "keep" or "expand", window_width_override = 1280, window_height_override = 720.
- In Camera2D: Set zoom = Vector2(1.0, 1.0) (or 1.25x), centered on Pinto with limits [0, 0, 1280, 720]. Because base viewport is 640x360, the camera view fits inside the 1280x720 arena and fills 100% of the screen without any black padding/borders!
- Ensure all HUD UI elements scale and anchor correctly to screen edges.

2. Fix Physics Query Flushing Error:
- In scenes/enemies/enemy_base.gd (and boss_giga_null.gd / xp_gem.gd): Fix line 218 "_spawn_xp_gems(): Can't change this state while flushing queries". Use call_deferred to add gems to the scene tree and defer collision/monitoring disable calls.

3. Fix all 31 GDScript Warnings:
- Add @warning_ignore("unused_signal") to autoload/event_bus.gd.
- Prefix unused parameters with underscore (_max_hp, _score_val).
- Fix integer divisions to float divisions.

4. Run all headless test suites, verify 100% pass, and git push to GitHub origin/main.
