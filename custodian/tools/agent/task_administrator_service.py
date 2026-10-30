#!/usr/bin/env python3
"""Install or remove the disabled-by-default per-user observer service."""
import argparse
import os
import subprocess
import sys
from pathlib import Path

from task_administrator import common_dir

UNIT = "custodian-task-administrator.service"


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    ins = sub.add_parser("install"); ins.add_argument("--enable", action="store_true")
    sub.add_parser("uninstall")
    args = parser.parse_args(argv)
    repo = Path.cwd().resolve()
    if os.name != "posix" or not os.environ.get("XDG_RUNTIME_DIR"):
        parser.error("a logged-in systemd user session is required")
    unit_dir = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "systemd/user"
    target = unit_dir / UNIT
    if args.action == "install":
        template = Path(__file__).with_name("task_administrator.service.in").read_text(encoding="utf-8")
        contents = template.replace("@REPO@", str(repo)).replace("@COMMON_DIR@", str(common_dir(repo)))
        unit_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
        if target.exists() and target.read_text(encoding="utf-8") != contents:
            parser.error(f"refusing to overwrite a different unit: {target}")
        target.write_text(contents, encoding="utf-8"); target.chmod(0o600)
        subprocess.run(["systemctl", "--user", "daemon-reload"], check=True)
        if args.enable:
            subprocess.run(["systemctl", "--user", "enable", "--now", UNIT], check=True)
            print("installed and explicitly enabled")
        else:
            print("installed disabled; use --enable only after explicit operator choice")
    else:
        if target.is_symlink():
            parser.error("refusing to remove a symlink unit")
        if target.exists():
            current = target.read_text(encoding="utf-8")
            if "task_administrator.py run" not in current or str(repo) not in current:
                parser.error("refusing to remove a unit not owned by this repository")
        subprocess.run(["systemctl", "--user", "disable", "--now", UNIT], check=False)
        if target.exists(): target.unlink()
        subprocess.run(["systemctl", "--user", "daemon-reload"], check=True)
        print("removed this repository's user unit")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
