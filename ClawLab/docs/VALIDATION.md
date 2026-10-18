# Validation record

## Completed in the build environment

- **48/48 simulation/storage checks and 5/5 graphical touch/UI checks passed**, with no script/runtime errors in their logs.
- Godot 4.5.1 imported and ran the project.
- Behavioral checks cover malformed profiles, backup recovery, hit-zone damage, projectile falloff, jump apex/landing, prone collision, ceiling clearance, mantle clearance/traversal, independent multi-touch ownership, cancel/release handling, configured fire rate, ammunition/reload timing, release-fire/quick ADS, high-speed swept hits, pause/resume, all ten drill startups and bounded sustained-fire pools.
- Rendered menu, settings, training range and HUD editor screenshots were inspected at 1440×648 using Mesa software OpenGL. This caught and corrected wrapped sidebar branding and inaccessible HUD-editor controls.
- APK validation checks package identity, ARM64 contents, API levels, absence of network/microphone/storage permissions, excluded development resources, bundled engine licenses, archive integrity and signature verification.

Machine-readable results are in `qa/test-results.json` and `qa/ui-results.json`; `build-manifest.json` accompanies the APK. GitHub Actions generates fresh reports for each build. Software-rendered desktop FPS is not a phone benchmark.

## Required before calling it a stable phone release

These checks have **not** been completed on physical Android hardware:

| Check | Device procedure | Acceptance target |
| --- | --- | --- |
| Sustained rendering | Run Tracking and Strafe & Track for 20 minutes at 60 FPS | No crashes; record actual frame times, battery and temperature; no sustained thermal slowdown |
| Four-finger touch | Hold move + fire + ADS; aim with fourth contact; slide fingers off controls | Actions stay independent, no stuck inputs or gesture interference |
| OS interruptions | Background/restore, notification shade, lock/unlock, incoming call | Session pauses, all held actions release, safe resume |
| Screen/grip fit | Check cutout, navigation gestures, touch zones and keyboard in landscape | Settings and HUD remain reachable; no clipped controls |
| Input feel | Compare calibrated swipes and ADS at matching FPS | Repeatable turn angles; quantify latency separately |
| Physics fidelity | Record known-distance movement, jumps, leans and mantles in both apps | Tune approximate parameters and record residual differences |
| Long-term saving | Save many named profiles and 100 sessions; restart app | Valid saved data and bounded history; no perceptible menu stalls |
| Device diversity | Test at least one lower-tier ARM64 device and one different Android/GPU family | Stable 30/60 FPS fallback, readable UI, no rendering faults |
| Release/update | Use a persistent owner-held signing key, test an in-place update | Profiles/history survive an upgrade |

An Android emulator can help with lifecycle regressions, but it does not establish four-finger ergonomics, gyro mapping, input latency or thermal performance on a Redmi Note 14 Pro Plus. This build should not be advertised as matching Aimlabs 2.0’s production stability or Delta Force’s exact physics until those measurements exist.
