"""Verify exported package identity, architecture, permissions and signature."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import zipfile

apk = Path(sys.argv[1])
sdk = Path(os.environ["ANDROID_HOME"]) / "build-tools/35.0.0"
badging = subprocess.check_output([str(sdk / "aapt"), "dump", "badging", str(apk)], text=True)
permissions = subprocess.check_output([str(sdk / "aapt"), "dump", "permissions", str(apk)], text=True)
assert "name='com.willbright.clawlab'" in badging, "Unexpected package identity"
assert "sdkVersion:'24'" in badging, "Unexpected minimum SDK"
assert "targetSdkVersion:'35'" in badging, "Unexpected target SDK"
assert "native-code: 'arm64-v8a'" in badging, "Unexpected CPU architecture"
assert "android.permission.INTERNET" not in permissions, "Offline build has network permission"
assert "android.permission.RECORD_AUDIO" not in permissions, "Unexpected microphone permission"
assert "android.permission.READ_EXTERNAL_STORAGE" not in permissions, "Unexpected storage permission"
with zipfile.ZipFile(apk) as archive:
    names = archive.namelist()
    assert "lib/arm64-v8a/libgodot_android.so" in names
    assert "assets/THIRD_PARTY_NOTICES.txt" in names, "Missing engine licenses"
    assert not any(name.startswith(("assets/tests/", "assets/qa/", "assets/ci/")) for name in names), "Development files leaked into APK"
    assert archive.testzip() is None, "APK archive CRC failed"
signature = subprocess.check_output([str(sdk / "apksigner"), "verify", "--verbose", str(apk)], text=True)
assert "Verified using v2 scheme (APK Signature Scheme v2): true" in signature
report = {"file": apk.name, "size_bytes": apk.stat().st_size, "sha256": hashlib.sha256(apk.read_bytes()).hexdigest(),
          "package": "com.willbright.clawlab", "minimum_android_api": 24, "target_android_api": 35,
          "architecture": "arm64-v8a", "network_permission": False, "signature_verified": True,
          "build_type": "release template, preview signing certificate", "device_tested": False}
(apk.parent / "build-manifest.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report, indent=2))
