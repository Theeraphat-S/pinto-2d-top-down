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

**ProceduralJuice**:
Code-driven dynamic sprite scaling (squash and stretch), recoil kickbacks, and sinusoidal bobbing that inject visceral physical weight into 2D sprites.
_Avoid_: Jiggle, wobble, ragdoll

**PointLightAura**:
A 2D radial gradient light source attached to entities or props that softly illuminates surrounding arena tiles and interacts with the ambient darkness.
_Avoid_: Glow circle, halo, lamp

**HDRGlow**:
High-dynamic-range post-processing bloom applied to emissive pixel colors (> 1.0 energy) via WorldEnvironment to create vibrant neon energy effects.
_Avoid_: Blur filter, flare, brightness

**MuzzleFlash**:
A transient bright visual and light impulse spawned at Pinto's firing origin during projectile discharge.
_Avoid_: Gun flare, spark pop

**ImpactSparks**:
A brief directional pixel particle burst spawned at the exact collision point when a projectile strikes an enemy.
_Avoid_: Hit splat, blood burst

**AnimatedProp**:
An interactive environmental obstacle that features cyclical lighting, monitor scanlines, or pulsing energy cores without altering static physical boundaries.
_Avoid_: Dynamic obstacle, destructible object

**AuraRing**:
A rotating, pulsing neon ground decal rendered beneath Elite enemies or high-tier pickups to clearly establish priority threat identification.
_Avoid_: Target circle, selection ring

**RibbonTrail**:
A short, fading line geometry drawn behind high-velocity projectiles to visually convey trajectory and speed.
_Avoid_: Motion blur, bullet tail

**DustBurst**:
A transient cluster of tiny directional pixel dust particles spawned at ground level when executing high-acceleration movement or dashing.
_Avoid_: Dirt puff, smoke cloud

**HealthCatchupBar**:
A delayed secondary visual layer behind the primary health gauge that interpolates downward after damage to clearly communicate lost health.
_Avoid_: Ghost bar, damage trace

**DashReadyRing**:
A subtle circular HUD/character reticle that illuminates when Pinto's evasive dash has fully recovered from cooldown.
_Avoid_: Cooldown circle, stamina meter

**LowHealthVignette**:
A pulsating peripheral red screen-edge effect that activates when Pinto's health drops below a critical threshold (25%).
_Avoid_: Red screen, bloody border, death warning

**AttackTelegraph**:
A transient translucent vector or area marker projected onto the arena before an attack executes to provide fair reaction opportunity.
_Avoid_: Aim line, cheat ray, target pointer

**PhaseShockwave**:
An expanding energetic ring emitted by Boss Giga Null upon health phase transitions that visually punctuates combat escalation.
_Avoid_: Explosion circle, ring wave

**DropShadow**:
A low-opacity ground-projected elliptical decal anchored at an entity's ground contact plane that visually communicates elevation and spatial depth.
_Avoid_: Footprint, floor circle, silhouette

**EmissiveCore**:
A high-intensity neon element or micro-light on a cyber entity that pulses with archetype-specific color and triggers HDR bloom.
_Avoid_: Light bulb, neon spot, eye flare

