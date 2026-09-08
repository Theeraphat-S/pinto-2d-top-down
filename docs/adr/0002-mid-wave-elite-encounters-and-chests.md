# 2. Mid-Wave Elite Encounters and Treasure Chest Drops

**Context & Decision**:
The game previously featured uniform time-based wave escalations without mid-wave pacing climaxes. We decided to introduce deterministic Elite Enemy spawns at the midpoint of Waves 2 (Elite Slime), 3 (Elite Bat), and 4 (Elite Golem) possessing an amplified visual aura, 3-4x health, and increased movement aggression. Defeating an Elite Enemy drops a persistent Treasure Chest that Pinto can collect to open an immediate reward event granting a drafted upgrade card, healing, and bonus score.

**Consequences**:
- **Benefits**: Punctuate wave survivals with thrilling mini-boss targets, creating high-risk / high-reward tactical moments where players must redirect focus from kiting fodder.
- **Constraints**: The Spawner must track midpoint timestamps and guarantee exactly one Elite spawn per designated wave. The Treasure Chest interaction must safely handle game pause states and ensure memory cleanup upon pickup.
