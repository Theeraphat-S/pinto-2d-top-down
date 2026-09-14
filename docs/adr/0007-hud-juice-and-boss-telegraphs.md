# 7. Real-Time HUD Juice, Dash Indicators, and Boss Telegraph Architecture

**Context & Decision**:
Player survivability feedback and boss encounter clarity were hindered by instantaneous UI updates without damage decay, opaque dash cooldowns requiring guesswork, and abrupt boss attacks lacking visual warnings. We decided to implement a dual-layer HealthCatchupBar, an ambient DashReadyRing indicator beneath Pinto, a low-health edge vignette pulse, and an attack telegraphing system featuring directional laser aim indicators and energetic phase transition shockwaves for Boss Giga Null.

**Consequences**:
- **Benefits**: Significantly improves player tactical decision-making, mechanical readability, and boss battle spectacle without altering core game mechanics or DPS numbers.
- **Constraints**: Attack telegraphs must have a fixed brief window (0.35–0.45s) to preserve boss encounter challenge and pace. Telegraph visual nodes must be cleaned up reliably if the boss transitions phase or is defeated mid-telegraph.
