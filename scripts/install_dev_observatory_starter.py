#!/usr/bin/env python3
from pathlib import Path
from datetime import datetime
import shutil
import sys

REPO = Path.cwd()
PROJECT = REPO / "custodian" / "project.godot"
AUTOLOAD_LINE = 'DevObservatory="*res://game/systems/debug/dev_observatory.gd"'

def fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)

def inject_autoload() -> None:
    if not PROJECT.exists():
        fail(f"Missing {PROJECT}")

    text = PROJECT.read_text(encoding="utf-8")

    if 'DevObservatory="' in text and AUTOLOAD_LINE not in text:
        fail("DevObservatory autoload already exists at a different path. Inspect custodian/project.godot before changing it.")

    if AUTOLOAD_LINE in text:
        print("DevObservatory autoload already present.")
        return

    backup = PROJECT.with_suffix(f".godot.bak_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
    shutil.copy2(PROJECT, backup)
    print(f"Backed up project.godot to {backup}")

    if "[autoload]" not in text:
        text += "\n[autoload]\n\n" + AUTOLOAD_LINE + "\n"
    else:
        lines = text.splitlines()
        out = []
        inserted = False
        for line in lines:
            out.append(line)
            if line.strip() == "[autoload]":
                out.append("")
                out.append(AUTOLOAD_LINE)
                inserted = True
        if not inserted:
            fail("Failed to inject autoload.")
        text = "\n".join(out) + "\n"

    PROJECT.write_text(text, encoding="utf-8")
    print("Injected DevObservatory autoload.")

def main() -> None:
    inject_autoload()
    print("Now launch Godot and press F9.")

if __name__ == "__main__":
    main()
