# 4. Programmatic Chiptune Audio Synthesis and Phased Implementation

**Context & Decision**:
New combat features (Dash, Orbiting Plasma, Thunder Strike, Treasure Chest fanfare) require audio feedback that matches the existing 16-bit retro aesthetic. Rather than sourcing external binary WAV dependencies, we decided to programmatically generate synthetic 16-bit PCM waveform streams within `audio_manager.gd` (or dedicated procedural audio generators) and deliver the upgrades across 3 progressive phases: Phase 1 (Mobility & Juice), Phase 2 (Modular Weapons), and Phase 3 (Elite Encounters & Chest Rewards).

**Consequences**:
- **Benefits**: Zero external binary dependencies, consistent retro auditory aesthetic, reproducible builds, and seamless headless testing compatibility without missing asset errors.
- **Constraints**: Procedural wave generation must run during initialization (`_ready()`) or cache byte streams to avoid runtime frame rate stutters.
