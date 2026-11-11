#!/usr/bin/python3
"""Small, fail-closed entrypoint for the disposable proof service."""

from __future__ import annotations

import os
import errno
import json
import ipaddress
import pwd
import socket
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

WORKER_NAME = "custodian-worker"
VALIDATOR = "/usr/local/libexec/custodian-worker/validate_worker_isolation.py"
PROBE_CONFIG = Path("/var/lib/custodian-worker/probe.json")
DENIED_ERRNOS = {errno.EACCES, errno.EPERM, errno.EHOSTUNREACH, errno.ENETUNREACH, errno.ETIMEDOUT}
WORKER_ENV = {
    "PATH": "/usr/bin:/bin",
    "LANG": "C.UTF-8",
    "HOME": "/var/lib/custodian-worker/home",
    "CODEX_HOME": "/var/lib/custodian-worker/codex-home",
    "TMPDIR": "/var/lib/custodian-worker/tmp",
    "GIT_CONFIG_NOSYSTEM": "1",
    "GIT_CONFIG_GLOBAL": "/dev/null",
    "GIT_TERMINAL_PROMPT": "0",
    "GIT_ASKPASS": "/usr/bin/false",
    "GIT_LFS_SKIP_SMUDGE": "1",
}


def valid_instance(value: str) -> bool:
    return value == "proof"


def worker_environment(credentials_directory: str | None = None) -> dict[str, str]:
    """Return a fixed environment; forward only systemd's credential directory pointer."""
    environment = dict(WORKER_ENV)
    if credentials_directory is not None:
        environment["CREDENTIALS_DIRECTORY"] = credentials_directory
    return environment


def systemd_credentials_directory() -> str:
    value = os.environ.get("CREDENTIALS_DIRECTORY", "")
    path = Path(value)
    if (not value or not path.is_absolute() or ".." in path.parts or str(path) != value or
            path.is_symlink() or not path.is_dir() or path.stat().st_mode & 0o022):
        raise RuntimeError("systemd credential directory is missing or unsafe")
    return value


def isolation_preflight() -> tuple[bool, dict[str, object]]:
    """Prove denial from this process boundary before any workload is launched."""
    if PROBE_CONFIG.is_symlink():
        raise RuntimeError("probe config must not be a symlink")
    stat = PROBE_CONFIG.stat(follow_symlinks=False)
    if not PROBE_CONFIG.is_file() or stat.st_uid != 0 or stat.st_mode & 0o022:
        raise RuntimeError("probe config must be a root-owned, non-writable regular file")
    config = json.loads(PROBE_CONFIG.read_text())
    if config.get("schema") != "custodian.worker_probe_config.v1" or not isinstance(config.get("targets"), list):
        raise RuntimeError("probe config failed schema validation")
    targets = config["targets"]
    required = {"chrome_cdp_ipv4_9223", "other_ipv4_loopback", "ipv6_loopback"}
    if not required.issubset({item.get("name") for item in targets if isinstance(item, dict)}):
        raise RuntimeError("probe config omits a required loopback target")
    if not any(item.get("name", "").startswith("lan_ipv4_") and
               ipaddress.ip_address(item.get("host", "0.0.0.0")).is_private for item in targets):
        raise RuntimeError("probe config omits a private LAN destination")
    properties = config.get("unit_properties", {})
    required_denials = {"127.0.0.0/8", "10.0.0.0/8", "100.64.0.0/10", "169.254.0.0/16",
                        "172.16.0.0/12", "192.168.0.0/16", "::1/128", "fe80::/10", "fc00::/7"}
    if (properties.get("User") != WORKER_NAME or properties.get("IPAddressAllow", "").strip() or
            not required_denials.issubset(set(properties.get("IPAddressDeny", "").split()))):
        raise RuntimeError("effective systemd identity or address-deny policy is incomplete")
    cgroup = Path("/proc/self/cgroup").read_text().strip()
    if "custodian-worker@proof.service" not in cgroup:
        raise RuntimeError("launcher is outside the expected systemd service cgroup")
    base = {"pid": os.getpid(), "uid": os.geteuid(), "cgroup": cgroup,
            "effective_unit_properties": config.get("unit_properties", {})}
    records = []
    for target in targets:
        started = datetime.now(timezone.utc).isoformat()
        before = time.monotonic()
        family = socket.AF_INET6 if ":" in target["host"] else socket.AF_INET
        try:
            with socket.socket(family, socket.SOCK_STREAM) as sock:
                sock.settimeout(1.5)
                sock.connect((target["host"], int(target["port"])))
            result = {"blocked": False, "error": None}
        except OSError as exc:
            result = {"blocked": exc.errno in DENIED_ERRNOS or isinstance(exc, TimeoutError),
                      "errno": errno.errorcode.get(exc.errno, "ETIMEDOUT" if exc.errno is None else str(exc.errno)),
                      "error": type(exc).__name__}
        records.append({**base, "name": target["name"], "destination": f"{target['host']}:{target['port']}",
                        "started_utc": started, "finished_utc": datetime.now(timezone.utc).isoformat(),
                        "timeout_seconds": 1.5, "duration_seconds": round(time.monotonic() - before, 4), **result})
    passed = all(item["blocked"] for item in records)
    report = {"schema": "custodian.worker_isolation_preflight.v1", "run_id": config["run_id"],
              "timestamp_utc": datetime.now(timezone.utc).isoformat(), "pass": passed,
              "process": base, "probes": records, "positive_controls": config.get("positive_controls", []),
              "preflight_only": config.get("preflight_only") is True,
              "lfs_only": config.get("lfs_only") is True,
              "model_only": config.get("model_only") is True}
    result_path = Path(WORKER_ENV["TMPDIR"]) / f"isolation-preflight-{config['run_id']}.json"
    fd = os.open(result_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0), 0o600)
    with os.fdopen(fd, "w") as stream:
        json.dump(report, stream, sort_keys=True)
        stream.write("\n")
    return passed, report


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    if len(args) != 1 or not valid_instance(args[0]):
        print("custodian-worker-launch: only the fixed 'proof' instance is allowed", file=sys.stderr)
        return 64
    if os.geteuid() == 0:
        print("custodian-worker-launch: refusing to run as root", file=sys.stderr)
        return 77
    try:
        account = pwd.getpwuid(os.geteuid())
    except KeyError:
        print("custodian-worker-launch: effective uid has no passwd entry", file=sys.stderr)
        return 77
    if account.pw_name != WORKER_NAME:
        print("custodian-worker-launch: refusing unexpected service identity", file=sys.stderr)
        return 77
    if not Path(VALIDATOR).is_file():
        print("custodian-worker-launch: validator is missing", file=sys.stderr)
        return 78
    try:
        preflight_pass, preflight = isolation_preflight()
    except Exception as exc:
        print(json.dumps({"schema": "custodian.worker_isolation_preflight_error.v1",
                          "error_type": type(exc).__name__, "message": str(exc)[:240]}, sort_keys=True), flush=True)
        return 78
    if not preflight_pass:
        print(json.dumps(preflight, sort_keys=True), flush=True)
        return 79
    if preflight.get("preflight_only") is True:
        print(json.dumps(preflight, sort_keys=True), flush=True)
        return 0
    if preflight.get("model_only") is True:
        try:
            credentials_directory = systemd_credentials_directory()
        except (OSError, RuntimeError) as exc:
            print(f"custodian-worker-launch: {exc}", file=sys.stderr)
            return 78
        validator_mode = "--inside-model"
    else:
        credentials_directory = None
        validator_mode = "--inside-lfs" if preflight.get("lfs_only") is True else "--inside-worker"
    os.execve(VALIDATOR, [VALIDATOR, validator_mode], worker_environment(credentials_directory))
    return 127


if __name__ == "__main__":
    raise SystemExit(main())
