# 8. Enemy Cyber-Neon Visual Overhaul and Spatial Depth Architecture

**Context & Decision**:
Enemy entities (Glitch Slime, Cyber Bat, CRT Drone, Megabyte Golem, and Boss Giga-Null) previously used low-detail placeholder sprites (7–10 flat colors) without ground drop shadows or cybernetic emissive accents, resulting in flat visual presentation and weak spatial height readability in the arena. We decided to execute a full Cyber-Neon visual overhaul while strictly retaining the 4-frame horizontal spritesheet architecture (`hframes = 4`) and native resolution bounds (32x32, 48x48, 80x80) across all archetypes, integrating procedural ground drop shadows (`_draw` elliptical projection) anchored to foot positions with flight elevation offsets, and archetype-specific emissive neon cores that synergize with WorldEnvironment HDR bloom.

**Consequences**:
- **Benefits**: Substantially elevates visual fidelity, silhouette readability, and top-down depth perception (especially for flying bats and hovering drones) while maintaining 100% backward compatibility with all 19 automated test suites.
- **Constraints**: Drop shadows must be drawn on the ground plane below character bodies to avoid obscuring animated sprites. Emissive cores must use vibrant high-energy palettes and selective micro-lights to prevent frame-rate degradation during dense high-wave swarm encounters.
