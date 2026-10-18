# Evidence and implementation decisions

Research and screenshot transcription: 18 October 2026. This document separates observed values from engineering assumptions. Public patch notes describe behavior but do not expose a complete movement or weapon simulation.

## Primary sources

1. User-provided Delta Force Mobile settings, HUD and M14 screenshots (`1000248693.jpg`–`1000248715.jpg`, with gaps). The original images are not included in the repository.
2. [Garena: War Ablaze season preview, 20 September 2025](https://deltaforce.garena.com/en/news/announcement/W9PGYU). The mobile section describes combined crouch/prone behavior (tap versus hold) and movement-related fixes. It does not provide gravity, air acceleration or a recoil sequence.
3. [Garena: Ahsarah update notes](https://deltaforce.garena.com/en/news/all/VPYSUD). Platform and mode distinctions matter: console sensitivity information must not be treated as the mobile sensitivity scale.
4. [Garena: gameplay update](https://deltaforce.garena.com/en/news/announcement/V6J38U). Movement can differ with mode, equipment and operator mechanics. This trainer models a configurable baseline character rather than every operator.
5. [Godot 4.5 CharacterBody3D](https://docs.godotengine.org/en/4.5/classes/class_characterbody3d.html). Used for character motion and floor/wall collision.
6. [Godot 4.5 Android export](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_android.html). Godot 4.5.1, Java 17 and Android build tools 35 underpin the tested export.
7. [Android: slow sessions](https://developer.android.com/topic/performance/issues/slow-session). Real device frame pacing and sustained performance must be measured; a chosen FPS limit alone is not a stability result.

## Screenshot values used directly

| Setting/property | Preset value | Implementation |
| --- | --- | --- |
| Device/grip | Redmi Note 14 Pro Plus; four fingers; no gyro | Four independent action/aim contacts, editable positions; gyro off |
| Camera FOV | 94 | Treated as **horizontal** FOV; exact game convention requires calibration |
| Aim assist | Off | Trainer slowdown disabled |
| ADS / lean | Hold / Hold | Separate captured touch contacts |
| Lean auto ADS / ADS auto lean | On / On | Lean requests ADS; explicit ADS restores last lean direction |
| Sensitivity transition | Instant | Switch sensitivity on requested ADS state |
| Camera turning on action buttons | Jump and equipment enabled; fire, scope/ADS, lean, crouch, prone disabled | Per-action camera turning; blank-area aim contact has priority |
| Mode-dependent quick ADS | Operations off, Warfare on | Separate mode settings |
| Sprint cancels ADS / reload cancels ADS | On / Off | State transitions; fire interrupts sprint |
| Reload cancellation | Hybrid | Fire or reload button can cancel |
| Breath hold | Automatic in ADS | Duration and recoil modifier are configurable |
| Combined crouch/prone | Off | Can be enabled as tap crouch/hold prone |
| Chest / head / abdomen / limb damage | 39 / 74 / 35 / 15 | Separate target hit zones |
| Range / penetration | 52 m / 41 | First falloff distance; simplified, explicitly separate trainer armor model |
| Rate / magazine / selector | 727 RPM / 30 / Auto or Single | Also supports configurable burst |
| Velocity | 680 m/s | Swept segment collision; no high-speed endpoint-only hit test |
| ADS / sprint-to-fire | 308 ms / 184 ms | Timed transitions |
| Walk / sprint / ADS movement | 3.32 / 5.9 / 1.9 m/s | Physical movement speeds |
| Tactical / empty reload | 2.70 / 3.11 s | Separate reload timings |
| Holster / switch | 0.43 / 0.50 s | Combined simulated switch delay |
| Vertical / horizontal recoil multipliers | 0.52 / 0.68 | Applied to an editable approximate recoil curve, in Auto and Single/Burst |
| Firing stability | 0.82 | Scales horizontal recoil variation in the trainer |
| Breath sway / duration / recoil modifier | 0.33° / 24.17 s / 0.91 | Configurable sway and breath model |
| Flinch / movement stability / sight stability | 0.80 / 0.93 / 0.74 | Incoming-hit kick, movement sway and cosmetic weapon shake |
| Hip spread / maximum | 3.46° / 8.58° | Treated as cone half-angle; the screenshot’s angle convention is unverified |

The screenshot’s control/handling/stability/accuracy bars (57/54/58/28) are aggregated ratings. They are not equations and are not independently converted into physical parameters. Sound range (600 m) does not affect offline target scoring. Values for an unmodified gun should not replace this attachment-specific M14 preset without an explicit new profile.

## Approximations you can change

| Model | Starting assumption | How to improve it |
| --- | --- | --- |
| Touch sensitivity | 240° hip and 135° ADS per full-width swipe | Match a measured turn in Calibration; do not paste the game’s numeric slider value |
| Recoil | Vertical base kick 0.58°; horizontal sinusoid 0.24°; random 0.08° | Compare controlled bursts on a wall at equal distance/FOV |
| Jump | 0.75 m height, 18 m/s² gravity, 0.25 s cooldown | Measure jump apex and airtime; tune height and gravity independently |
| Movement | 22 m/s² acceleration, 0.18 air-control fraction | Compare start/stop and airborne steering at equal frame rate |
| Crouch / prone | 1.65 / 0.75 m/s; 0.20 / 0.38 s camera transitions | Measure stance timing and timed travel |
| Lean | 0.23 m offset, 9° roll, 0.13 s transition | Compare visual displacement and timing near cover |
| Mantle | 1.25 m maximum obstacle, 0.60 s traversal | Compare known-height obstacles; camera collision is checked |
| Warfare dive | Sprint + prone, 1.15 speed multiplier | Approximate trajectory; not verified against game footage |
| Stamina | Editable fractional consumption and recovery | Match repeated sprint/jump behavior from a controlled recording |
| Armor | Reduction = clamp((armor − penetration)/100, 0, 0.8) | Trainer-only scoring model; no claim of Delta Force armor-class accuracy |
| Aim slowdown | Angular proximity to a target, optional multiplier | Default off; not a reproduction of the game’s aim assist |

Inference: an independent trainer can reproduce the relevant **control structure** and expose tunable response parameters. These sources are insufficient to claim numerically identical physics, recoil or input latency. Game updates may change the reference behavior; preserve versioned profiles and measure again after meaningful changes.
