# 5. Cyber-Neon Visuals, Dynamic 2D Lighting, and Procedural Juice Architecture

**Context & Decision**:
The game's visual presentation was static and flat: Pinto and enemies lacked dynamic kinetic feedback during movement and attacks, projectiles lacked visual weight and impact trails, and the arena lacked atmospheric depth and illumination contrast. We decided to retain the native 640x360 pixel grid (32x32/48x48 sprites) while implementing a Cyber-Neon visual architecture combining procedural squash-and-stretch kinematics on child sprite nodes, dynamic 2D lighting (`PointLight2D`) paired with atmospheric `CanvasModulate` and `WorldEnvironment` HDR glow, animated environment props, and a cyber combat VFX suite (muzzle flashes, projectile trails, and directional impact sparks).

**Consequences**:
- **Benefits**: Greatly elevates game feel, visual punch, and readability without breaking native 640x360 integer scaling, physics collision boundaries, or existing test suites.
- **Constraints**: Procedural squash-and-stretch must strictly manipulate the visual `sprite.scale` (or offset) rather than the root `CharacterBody2D.scale` to prevent physics bounding box deformation or collision query flushes. Dynamic lights must use lightweight procedural radial textures to ensure seamless execution in both graphical and headless CI environments.
