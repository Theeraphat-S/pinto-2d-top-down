# Original User Request

## Initial Request — 2026-08-20T06:35:31Z

Build a 2D pixel-art Top-Down Survival Arena game in Godot 4 starring "Pinto", where the player survives 5 escalating waves of enemies, automatically attacks nearest monsters, collects XP gems, chooses rogue-lite upgrades on level-up, and faces a wave 5 boss to achieve victory.
Integrity mode: demo

References & Assets:
- Design & Architecture Principles: https://catlikecoding.com/godot/true-top-down-2d/
- Asset Source Guidelines: Free 2D top-down pixel art assets (https://itch.io/game-assets/free/tag-top-down)
- Character Reference: Pinto (C:/Users/ovens/.gemini/antigravity/brain/bcebcb01-de2b-4fdb-9b39-90824309df79/.user_uploaded/media_1787206952726.jpg)

### Requirements:
1. R1. Player Character & Movement (Pinto): 8-directional movement, responsive velocity, obstacle collision, pixel art sprites for Pinto (idle, walk/run, hurt/death) faithful to character reference, auto-attack targeting nearest enemy within range at configurable fire rate.
2. R2. Enemy Spawning & Wave Progression: 5 distinct waves of increasing difficulty, multiple enemy types (distinct speeds, health, contact damage), Wave 5 Boss encounter, XP gem drops with collection range and attraction/magnet mechanics.
3. R3. Roguelite Upgrade System: Level-up triggered by XP threshold, interactive 3-card upgrade selection menu that pauses gameplay, stat enhancements (Attack Speed, Damage, Move Speed, Max HP, Additional Projectiles/Multi-shot, Bullet Pierce, etc.).
4. R4. Arena Map & Visuals: Enclosed top-down 2D TileMap arena with boundaries, decorative props, clear collisions, pixel-perfect top-down visual styling adhering to Godot 4 2D standards.
5. R5. HUD, UI & Progression Persistence: Real-time Health bar, Wave counter, Wave timer, Level, XP bar, Victory screen (Wave 5 clear), Game Over screen (0 HP), High score & best survival time tracking and persistence across restarts.
6. R6. Automated Verification Suite: Headless Godot test scripts running and validating player movement, auto-attack targeting, damage calculation, XP collection / level-up, wave transitions, and save/load persistence.

## Follow-up — 2026-08-20T07:34:42Z

Refactor and polish the Pinto 2D Top-Down Survival Arena in Godot 4: fix resolution scaling and Camera2D zoom (2.5x following Pinto smoothly with crisp pixel art and no gray borders), fix keyboard input mapping in project.godot (change device 16 to 0 for WASD/Arrow keys), integrate enemy spawner node into main scene so monster waves and boss spawn properly, and implement complete 8-bit/16-bit chiptune sound effects and retro background music.

Working directory: c:/Work/game/pinto-2d-top-down/new-game-project
Integrity mode: demo

## Requirements

### R1. Resolution, Scaling & Camera Zoom
- Configure viewport and stretch mode (`canvas_items`, `aspect="keep"`, base viewport 640x360 or 1920x1080 with 2.5x camera zoom) to render pixel art cleanly at native monitor aspect ratios without gray borders.
- Camera2D centered on Pinto with smooth tracking, bounded within arena borders.
- UI HUD elements properly anchored to screen edges and scaled for readability.

### R2. Keyboard Input & Player Controls
- Fix `project.godot` input map actions (`move_left`, `move_right`, `move_up`, `move_down`, `pause`, `select`) by ensuring `device: 0` (or `device: -1`) is configured for all keyboard events.
- Ensure WASD and Arrow keys drive responsive 8-directional movement and auto-attack fires at active enemies.

### R3. Spawner & Main Scene Integration
- Instance `spawner.tscn` in `main.tscn` and ensure it connects to `GameState` and `EventBus` so monster waves (1-5) and Boss encounter start immediately on game launch.

### R4. Retro Chiptune Audio & SFX System
- Add an `AudioManager` autoload playing chiptune 8-bit/16-bit sound effects (Pinto shoot, projectile hit, enemy death, XP gem pickup, level-up fanfares, player hurt, boss alarm, victory, game over) and looping background music.

### R5. Verification & GitHub Sync
- Run headless tests and standalone scene tests to ensure zero regressions.
- Stage, commit, and push updated files to GitHub repository.

## Acceptance Criteria

### Camera & Display
- [ ] Game renders cleanly in full window without empty gray background padding.
- [ ] Camera smoothly tracks Pinto with ~2.5x zoom so pixel details and arena surroundings are clearly visible.
- [ ] UI HUD stretches and aligns cleanly across window resize.

### Controls & Gameplay Loop
- [ ] Pressing WASD or Arrow keys moves Pinto in all 8 directions.
- [ ] Enemies automatically spawn in waves 1 to 5; Pinto's auto-attack automatically targets and shoots at them.
- [ ] Defeating enemies drops XP gems, picking them up levels up Pinto and presents 3 upgrade cards.

### Audio & Tests
- [ ] Audio system plays SFX on shooting, hit, XP pickup, level-up, and death, with looping BGM.
- [ ] All automated tests pass with 0 failures.
- [ ] Git commit and push succeeds.
