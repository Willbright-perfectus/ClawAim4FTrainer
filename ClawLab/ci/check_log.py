"""Godot can exit zero after a script error; enforce a clean script log."""
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text(errors="replace")
errors = re.findall(r"^.*(?:SCRIPT ERROR:|^ERROR:|^FAIL ).*$", text, re.MULTILINE)
if errors:
    print("\n".join(errors))
    raise SystemExit(1)
print("No script/runtime errors in", sys.argv[1])
