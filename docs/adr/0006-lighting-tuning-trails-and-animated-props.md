# 6. Procedural Lighting Falloff, Line2D Ribbon Trails, and Decoupled Prop Animation

**Context & Decision**:
Integrating dynamic 2D lighting and combat trails risked performance degradation and headless test runner incompatibilities if implemented with heavy texture assets or unbounded particle systems. We decided to implement procedural `GradientTexture2D` radial falloff textures for all `PointLight2D` nodes, set the arena ambient modulate to Dark Slate-Navy (`#454d66`) with `WorldEnvironment` additive CanvasItem glow, render bullet tracers via lightweight 5-point `Line2D` fading ribbons, and encapsulate ambient prop animations (LED flickers, monitor scanlines, crystal pulses) strictly within visual presentation layers without modifying collision shapes.

**Consequences**:
- **Benefits**: Ensures consistent 60 FPS rendering under heavy combat conditions (multishot + swarms), avoids texture loading race conditions in headless test environments, and creates clean, cohesive cybernetic visual polish.
- **Constraints**: Point lights must not exceed a moderate radius (120–180px) to prevent excessive canvas item overdraw. Ribbon trail points must clear immediately upon projectile reuse or queue_free to avoid spatial interpolation artifacts.
