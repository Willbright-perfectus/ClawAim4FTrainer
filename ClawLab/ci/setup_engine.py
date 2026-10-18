"""Pinned Linux Godot editor and Android template for GitHub Actions.

Fetches only the required Android entry from the official template archive.
Both extracted APK template and editor archive must match recorded SHA-256.
"""
import hashlib
import io
import os
from pathlib import Path
import time
import urllib.request
import zipfile

VERSION = "4.5.1-stable"
EDITOR_HASH = "02ec53d1cc7dbb9cc6355393c61b9ab43d1244751a124f10248a4802830788cd"
TEMPLATE_HASH = "5c65ea869de294d14738371089b38d2ccf6a101e904e79a1df9f9db37b237711"
BASE = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}/"

def request(url, headers=None):
    for attempt in range(3):
        try:
            return urllib.request.urlopen(urllib.request.Request(url, headers=headers or {}), timeout=180)
        except (OSError, urllib.error.URLError):
            if attempt == 2:
                raise
            time.sleep(attempt + 1)

class RemoteZip(io.RawIOBase):
    def __init__(self, url):
        with request(url, {"Range": "bytes=0-0"}) as response:
            if response.status != 206:
                raise RuntimeError("Template host did not honor HTTP Range")
            self.url = response.geturl()
            self.length = int(response.headers["Content-Range"].split("/")[-1])
        self.position = 0

    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.position

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else self.length + offset
        return self.position

    def read(self, count=-1):
        if count < 0: count = self.length - self.position
        if count == 0: return b""
        with request(self.url, {"Range": f"bytes={self.position}-{self.position + count - 1}"}) as response:
            if response.status != 206:
                raise RuntimeError("Template host stopped honoring HTTP Range")
            data = response.read()
        if len(data) != count:
            raise IOError("Incomplete range download")
        self.position += len(data)
        return data

def verified(data, expected):
    if hashlib.sha256(data).hexdigest() != expected:
        raise RuntimeError("Downloaded engine file failed its SHA-256 check")
    return data

def main():
    directory = Path(os.environ.get("RUNNER_TEMP", "/tmp")) / "clawlab-godot"
    directory.mkdir(parents=True, exist_ok=True)
    editor_name = f"Godot_v{VERSION}_linux.x86_64"
    editor = directory / "godot"
    if not editor.exists():
        with request(BASE + editor_name + ".zip") as response:
            payload = verified(response.read(), EDITOR_HASH)
        with zipfile.ZipFile(io.BytesIO(payload)) as archive:
            editor.write_bytes(archive.read(editor_name))
        editor.chmod(0o755)
    data_root = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share")))
    templates = data_root / "godot/export_templates/4.5.1.stable"
    templates.mkdir(parents=True, exist_ok=True)
    template = templates / "android_release.apk"
    if not template.exists() or hashlib.sha256(template.read_bytes()).hexdigest() != TEMPLATE_HASH:
        with zipfile.ZipFile(RemoteZip(BASE + f"Godot_v{VERSION}_export_templates.tpz")) as archive:
            template.write_bytes(verified(archive.read("templates/android_release.apk"), TEMPLATE_HASH))
            (templates / "version.txt").write_bytes(archive.read("templates/version.txt"))
    if "GITHUB_PATH" in os.environ:
        with open(os.environ["GITHUB_PATH"], "a") as file:
            file.write(str(directory) + "\n")
    print(f"Godot {VERSION} ready: {editor}")

if __name__ == "__main__":
    main()
