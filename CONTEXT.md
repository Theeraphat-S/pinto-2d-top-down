# Domain Context

## Language

**Pinto**:
The player-controlled cyber hero character moving in 8 directions with auto-targeting projectile combat and an XP magnet perimeter.
_Avoid_: Avatar, hero, champion

**Wave**:
A discrete time-bounded survival phase (Waves 1–5) with escalating spawn rates, enemy archetypes, and culminating in the Giga Null boss encounter.
_Avoid_: Stage, level, round

**EnemyArchetype**:
A categorized hostile entity with distinct AI kinematics, health pool, attack behavior, and dropped XP value (Slime, Bat, Drone, Golem, Boss).
_Avoid_: Mob, monster, creep

**XPGem**:
A collectible dropped by defeated enemies that is drawn to Pinto by magnetic pull and accumulates progression towards level-ups.
_Avoid_: Orb, coin, crystal

**UpgradeCard**:
A drafted card offered in sets of 3 upon leveling up that grants permanent additive or multiplicative stat buffs for the active run.
_Avoid_: Perk, item, powerup

**DamagePopup**:
A floating, animated visual number displayed above an entity upon taking damage, styled differently for normal and critical hits.
_Avoid_: Combat text, damage label

**Dash**:
An evasive high-speed impulse maneuver executed by Pinto that grants brief invulnerability and requires cooldown recovery.
_Avoid_: Blink, teleport, sprint

**WeaponSlot**:
An active offensive subsystem attached to Pinto that executes independent automated attack cycles alongside the primary blaster.
_Avoid_: Gun, secondary attack, weapon inventory

**EliteEnemy**:
A high-threat variant of a standard enemy archetype with an illuminated visual aura, enlarged scale, magnified health pool, and guaranteed treasure drop.
_Avoid_: Mini-boss, champion, star mob

**TreasureChest**:
A reward container dropped upon the defeat of an EliteEnemy that immediately awards drafted upgrade cards and score bonuses.
_Avoid_: Loot box, crate, supply drop

**ScreenShake**:
A procedural camera displacement impulse triggered by heavy impacts, explosions, or critical strikes that decays exponentially over time.
_Avoid_: Camera wobble, jitter, quake

**OrbitingPlasma**:
A defensive weapon subsystem that continuously rotates energy orbs in an orbital trajectory around Pinto to damage contacting enemies.
_Avoid_: Shield ring, rotating balls, satellites

**ThunderStrike**:
An offensive weapon subsystem that periodically discharges targeted lightning bolts from above onto hostile entities within detection range.
_Avoid_: Zap, spark, shock spell

**AfterimageTrail**:
A rapid succession of fading visual ghost sprites spawned along Pinto's trajectory during an active dash maneuver.
_Avoid_: Blur, shadow, trail effect

**HitStop**:
A micro-freeze frame deceleration (e.g. 0.03s time dilation) triggered upon critical hits or boss impacts to convey mechanical weight.
_Avoid_: Lag, stutter, pause
