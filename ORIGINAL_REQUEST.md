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
