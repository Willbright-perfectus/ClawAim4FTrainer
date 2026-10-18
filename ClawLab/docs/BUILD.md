# Building and continuing development

## GitHub Actions

The repository-level `.github/workflows/clawlab-android.yml` builds the new app in `ClawLab/`. It is independent of the older zipped Java project and its workflow.

The workflow runs on pull requests or pushes touching the new project, and can be launched manually once it is on the default branch. It installs the pinned Godot editor/template, verifies their SHA-256 hashes, imports resources, runs behavioral tests, runs graphical touch/UI tests, exports an ARM64 APK, verifies signing/permissions and uploads an artifact. The workflow token has read-only repository permissions. No production signing secrets are required for this preview.

To get an APK, open the relevant **Actions → ClawLab Android** run and download `ClawLab-Android-preview`. A green run is build/test evidence, not proof of sustained device performance. Build diagnostics and test reports are uploaded separately.

## Local Android export

1. Install **Godot 4.5.1 standard** and its matching export templates.
2. Install **OpenJDK 17**, Android platform tools and **build tools 35.0.0**. The supplied non-Gradle template targets API 35 and requires API 24 or newer. An NDK/CMake compiler toolchain is not needed for this template-based APK export.
3. In Godot’s Editor Settings, set **Export → Android → Java SDK Path** and **Android SDK Path**. On Linux CI, `JAVA_HOME=… ANDROID_HOME=… python3 ci/configure_android.py` does this.
4. Generate a local preview key (keep it outside source control):

```sh
keytool -genkeypair -keystore /your/private/path/preview.keystore \
  -storepass android -keypass android -alias androiddebugkey \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname 'CN=ClawLab Preview,O=ClawLab,C=TZ'
```

5. Set the environment and export. On Windows, use the equivalent PowerShell environment assignment or fill the Release keystore fields in Godot’s export dialog.

```sh
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/your/private/path/preview.keystore
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=androiddebugkey
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=android
mkdir -p build
godot --headless --path . --export-release Android \
  build/ClawLab-0.1.0-android-arm64.apk
ANDROID_HOME=/your/android/sdk python3 ci/verify_apk.py \
  build/ClawLab-0.1.0-android-arm64.apk
```

The engine uses a release template, signed with a testing certificate. Do not publish the preview certificate as a production identity. Preserve one owner-controlled release key before shipping updates to customers or an app store. No keystore, APK, SDK, engine binary or local user profile belongs in this source repository.

## Tests and visual capture

```sh
godot --headless --editor --path . --import --quit
XDG_DATA_HOME=/tmp/clawlab-tests CLAWLAB_TEST_REPORT="$PWD/qa/test-results.json" \
  godot --headless --path . --fixed-fps 120 res://tests/test_runner.tscn
python3 ci/check_log.py qa/test.log  # when output is captured to this file

# Use a real display or Xvfb; headless mode does not dispatch OS window input.
CLAWLAB_UI_REPORT="$PWD/qa/ui-results.json" xvfb-run -a \
  godot --path . --audio-driver Dummy --fixed-fps 120 res://tests/ui_runner.tscn

# Captures the menu, settings, range and HUD editor to PNG.
CLAWLAB_CAPTURE_DIR=/tmp/clawlab-screens xvfb-run -a \
  godot --path . --audio-driver Dummy -- --test-ui
```

The integration tests require an isolated `XDG_DATA_HOME` because they intentionally corrupt a test settings file to verify backup recovery. Graphical captures are debugging tools and are not included in the Android export.

## Stability design

- Fixed 120 Hz character/projectile simulation, independently configurable rendering cap.
- Segment sweeps for fast projectiles and a capsule with real stance clearance.
- Bounded pools: 64 projectiles, 160 impact markers, at most 8 practice equipment objects, 64 touch markers and 100 history entries.
- No network requests or runtime third-party SDKs; no Android Internet permission.
- Per-touch ownership and reference-counted held buttons; cancellation releases all actions on pause/focus loss.
- Weapon timing is simulated in seconds, with bounded catch-up firing after a delayed frame.
- Debounced settings writes, numeric validation, versioned JSON and atomic file replacement with a previous-save backup.
- Simple geometry, no shadow maps, no downloaded textures or imported character rigs.

Avoid adding unbounded decals, per-frame file writes, runtime asset loads in the firing loop, or user values that bypass `Schema.sanitize()`. Profile metrics should remain tied to their full saved configuration. Changes to calibration units need a schema-version migration.
