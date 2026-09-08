# 3. Decoupled EventBus-Driven Screen Shake and Juice Architecture

**Context & Decision**:
Combat feedback lacked tangible physical weight: entities despawned without particle bursts, impacts caused no camera trauma, and critical hits felt identical to regular strikes. We decided to implement an event-driven ScreenShake subsystem integrated into `Camera2D` via an `EventBus.screen_shake_requested(intensity, duration)` signal, a lightweight `CPUParticles2D` pixel-burst pool for enemy defeats and dash bursts, and a micro-pause `HitStop` on critical hits.

**Consequences**:
- **Benefits**: Combat feedback feels punchy and visceral without coupling damage receivers directly to the scene camera. `CPUParticles2D` ensures universal rendering compatibility across all hardware and headless testing runners without shader compilation overhead.
- **Constraints**: Camera shake must respect arena limits and not breach the clamping bounds established in Milestone M1. HitStop time-scale adjustments must be strictly temporary (<= 0.04s) to avoid disrupting physics integration or audio clocks.
