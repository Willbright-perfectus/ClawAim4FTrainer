# Changes

## 0.2.0 — 2026-10-18

- Faster movement: default 1.25× pace, stronger acceleration, shorter stick travel and quicker crouch/prone/lean/mantle transitions. Pace and all timings remain editable.
- Reload countdown and progress ring inside the reload HUD button.
- Actual M14/pistol switching, separate editable pistol properties and starting-weapon selection. Pistol fires one shot per press, has unlimited ammo, never reloads and uses 1× iron sights. Rifle ammo persists across switching.
- M14 optic selector in Weapon settings, visible scope model and ADS reticle/mask, 1×/2×/3×/4×/6×/8× support and current zoom on the scope button.
- Separate Swipe, Camera and Fire sensitivity categories, independent firing hip/ADS/scope gains and optional gyro/view settings.
- Touch gesture ownership and momentum for sidebar/settings scrolling; vertical swipes cancel button activation and sidebar position survives page changes.
- Player-only front and side range barriers block jumping/crawling/vaulting into the dummy bay while allowing bullets through. Movement-course checkpoints stay in the movement bay.
- Version 1 profile migration preserves HUD/custom values and initializes fire sensitivity from previous camera values. Projectile damage/gravity are captured at launch so switching cannot alter an in-flight bullet.
- 68 simulation/storage checks and 13 graphical touch/menu checks pass. Physical-phone feel, performance and exact game calibration still require testing.

## 0.1.0 — 2026-10-18

First standalone 3D preview: configurable M14-style gun simulation, ten drills, four-finger HUD, collision-aware movement, profile editing/import/export, results history, Android export and automated validation. Includes an explicit evidence/calibration guide for values that cannot be derived exactly from the game screenshots.
