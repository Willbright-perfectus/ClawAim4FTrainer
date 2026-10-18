# ClawLab

An offline, landscape Android aim and finger-coordination trainer built with **Godot 4.5.1**. It starts from Willbright’s M14 screenshots and a four-finger, no-gyro control profile, with editable weapon behavior, sensitivity, HUD and movement physics.

**Version 0.2.0 is a playable preview.** Automated checks and a signed APK are provided. Sustained performance on the Redmi Note 14 Pro Plus and exact Delta Force equivalence have not been verified. This is an independent app, not an Aimlabs or Delta Force product.

## New in 0.2.0

- Faster default movement with adjustable 1.25× pace and quicker stance/lean response.
- Reload countdown and progress ring inside the reload button.
- Switch between the M14 and a single-shot training pistol with unlimited ammo and no reload. Both have separately editable gun properties.
- Choose 2×, 3×, 4×, 6× or 8× M14 optics (1× also available); scoped ADS now has a visible reticle/view.
- Separate Swipe, Camera and Fire sensitivity categories, including per-scope firing sensitivity.
- Reliable touch swipes through sidebar/settings and a barrier keeping the player out of the dummy bay.

## What you can do

- Train in ten modes: Free Range, Tracking, Flicks, Switching, Strafe & Track, Peek & Clear, Finger Flow, Movement Course, Recoil Board and Calibration.
- Move, aim, ADS and fire with separate simultaneous fingers. Configure hold, press or hybrid ADS/lean, button camera turning, combined crouch/prone, quick ADS and release-fire.
- Move, resize, hide and change the opacity of 18 HUD controls. Coordinates are normalized to your screen.
- Change damage zones, fire rate, projectile speed/gravity, recoil, spread, reload/ADS/switch timings, sway, breath holding and hit flinch.
- Practise collision-aware jumping, crouching, prone, leaning, sprinting, silent walking, stamina, mantling and a Warfare-style dive.
- Save named profiles; copy/paste complete JSON profiles between devices; inspect the latest 100 sessions with their original settings.
- Select 30/60/90/120 FPS limits and rendering resolution. Counters show observed frame time.

## Start on Android

1. Download the `ClawLab-0.2.0-android-arm64.apk` preview from the accompanying deliverable or a successful **ClawLab Android** Actions run.
2. Open the APK on an **ARM64 Android 7.0+** phone and allow that installer when Android asks. The package is `com.willbright.clawlab`; it installs alongside the older ClawAim app.
3. Open **HUD editor** and position the controls for your grip. The framed area represents the whole phone display. Drag a control; adjust size/opacity/visibility; select **Save layout**.
4. Start **Calibration** and match your game’s horizontal FOV and measured swipe turn. Then enter **Free Range** before timed drills.
5. Keep the initial **60 FPS** limit until a sustained session on your phone stays smooth. Raising the limit does not guarantee the hardware can deliver it.

The directly supplied 0.2.0 APK uses the same preview certificate as the directly supplied 0.1.0 APK, so install it as an update without uninstalling; saved profiles/HUD migrate automatically. The preview certificate is for testing. CI creates a fresh preview key for each run. To switch between differently signed builds, export your profile JSON first, uninstall the older preview, then install the new one. A production release needs one owner-controlled signing key retained for future updates.

## Run from source

Download the **standard Godot 4.5.1 editor** from [Godot](https://godotengine.org/download/archive/4.5.1-stable/), import this folder’s `project.godot`, and press F6/F5 as appropriate (F5 starts the app). No plugins, paid assets, accounts or C# toolchain are required.

For desktop testing: **F1** captures the mouse; **WASD** moves; **Shift** toggles sprint; **Space** jumps; **C/Z** crouch/prone; **Q/E** lean; **R** reloads; **right mouse** ADS; **left mouse** fires; **Esc** pauses. On mobile, touch input is primary.

```sh
# Linux/macOS headless integration tests; use isolated app data.
XDG_DATA_HOME=/tmp/clawlab-tests godot --headless --path . \
  --fixed-fps 120 res://tests/test_runner.tscn
```

See [BUILD.md](docs/BUILD.md) for Android exports and the GitHub workflow; [CALIBRATION.md](docs/CALIBRATION.md) for matching your game; [RESEARCH.md](docs/RESEARCH.md) for source evidence and approximations; [VALIDATION.md](docs/VALIDATION.md) for completed checks and remaining device work.

## Fidelity limits

The screenshot preset is **a starting profile, not an exact game simulator**. Delta Force’s sensitivity scale, recoil sequence, movement curves, armor classes and several physics constants are not available from these screenshots or the cited official notes. All invented physical constants are labeled as approximations in the app. Full inventory/map interaction, swimming, parachuting, operator abilities and multiplayer are not implemented. Gun sound propagation and aggregated stat-bar ratings do not drive this trainer’s physics. Equipment throws remain timing/coordination exercises. The M14 and pistol are functional weapons; a full inventory/loadout system is not implemented.

## Layout

| Path | Purpose |
| --- | --- |
| `scripts/main.gd` | Menu, settings forms, HUD editor, pause, profiles, results |
| `scripts/config_schema.gd` | Defaults, bounded values, schema/version validation |
| `scripts/profile_store.gd` | Atomic local saves, backup recovery, session history |
| `scripts/touch_scroll.gd` | Touch gesture ownership, cancellation and menu scrolling |
| `scripts/touch_hud.gd` | Per-finger ownership, input cancellation, drawing |
| `scripts/player.gd` | Character collision, stances, aiming and weapon state |
| `scripts/arena.gd` | Drills, room, bounded projectile/impact pools, metrics |
| `scripts/target.gd` | Target movement, hit zones, health and respawn |
| `tests/` | Behavioral integration tests, including real event dispatch |
| `ci/` | Pinned tooling, Android configuration and APK validation |

All room geometry, HUD icons, target models and sound effects in this project are procedural/original. No Delta Force or Aimlabs assets, code, branding or extracted game data are bundled. Godot and its dependencies retain their own licenses, included in `THIRD_PARTY_NOTICES.txt` and the app’s About screen.
