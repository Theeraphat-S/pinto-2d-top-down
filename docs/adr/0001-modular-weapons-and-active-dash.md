# 1. Modular Weapon Subsystems and Active Dash Mechanic

**Context & Decision**:
Pinto originally possessed a monolithic auto-attack system hardcoded directly in `player.gd` firing a single straight projectile, with no active movement actions beyond 8-directional walking. We decided to decouple weapon behaviors into dedicated modular weapon components attached as children under a WeaponManager or weapon slots on Pinto, and introduce an active Dash mechanic bound to `ui_accept` / Spacebar with invulnerability frames and cooldown management. This architecture enables independent weapon cooldowns, autonomous targeting routines (e.g. orbiters, area strikes), and gives the player active counterplay against dense swarms.

**Consequences**:
- **Benefits**: Enables seamless addition of diverse weapon archetypes (Orbiting Shield, Lightning Aura, Boomerang Blades) without bloating `player.gd`. Player survivability and skill ceiling increase via responsive dodging.
- **Constraints**: Weapons must follow a standardized interface contract (`tick(delta)`, `fire()`, `get_stats()`) and receive stat modifiers from `GameState`. Existing tests for player shooting must maintain backwards compatibility with the primary blaster.
