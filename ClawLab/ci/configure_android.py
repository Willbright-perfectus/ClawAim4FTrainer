"""Set Godot's per-user Android SDK paths; never write signing keys to source."""
import os
from pathlib import Path

config = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "godot"
config.mkdir(parents=True, exist_ok=True)
java = os.environ["JAVA_HOME"]
android = os.environ["ANDROID_HOME"]
def gd_string(value):
    return '"' + value.replace('\\', '/').replace('"', '\\"') + '"'
settings = config / "editor_settings-4.5.tres"
text = settings.read_text() if settings.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
lines = [line for line in text.splitlines() if not line.startswith(("export/android/java_sdk_path", "export/android/android_sdk_path"))]
lines += ["export/android/java_sdk_path = " + gd_string(java), "export/android/android_sdk_path = " + gd_string(android)]
settings.write_text("\n".join(lines) + "\n")
print("Configured Godot Android SDK paths.")
