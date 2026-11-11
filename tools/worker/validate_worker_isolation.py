#!/usr/bin/python3
"""Run or collect the disposable systemd worker-isolation proof."""

from __future__ import annotations

import argparse
import errno
import grp
import hashlib
import ipaddress
import json
import os
import pwd
import re
import shutil
import socket
import ssl
import subprocess
import sys
import threading
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

STATE = Path("/var/lib/custodian-worker")
CONFIG = STATE / "probe.json"
WORKSPACES = STATE / "workspaces"
UNIT = "custodian-worker@proof.service"
REPO_URL = "https://github.com/braydio/CUSTODIAN.git"
LFS_PATH = "archive/Hubworld/Ashen_Forum/Cliff_Section_01_32x64.png"
DENIED_ERRNOS = {errno.EACCES, errno.EPERM, errno.EHOSTUNREACH, errno.ENETUNREACH}
FORBIDDEN_ENV = re.compile(r"^(?:GITHUB_|GH_|OPENAI_|HL_|SSH_AUTH_SOCK$|CODEX_SESSION|CODEX_API_KEY$)")


def run(argv: list[str], *, timeout: int = 30) -> tuple[int, str, str]:
    try:
        proc = subprocess.run(argv, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout, check=False)
    except subprocess.TimeoutExpired:
        return 124, "", "timeout"
    return proc.returncode, proc.stdout, proc.stderr


def safe_command(argv: list[str], *, timeout: int = 30) -> dict[str, Any]:
    rc, stdout, stderr = run(argv, timeout=timeout)
    line = next((x.strip() for x in stdout.splitlines() if x.strip()), "")
    return {"exit_code": rc, "first_line": line[:240], "stderr_present": bool(stderr.strip())}


def valid_probe_config(data: dict[str, Any]) -> bool:
    if data.get("schema") != "custodian.worker_probe_config.v1":
        return False
    if not re.fullmatch(r"[a-f0-9]{16}", str(data.get("run_id", ""))):
        return False
    targets = data.get("targets")
    if not isinstance(targets, list) or len(targets) < 4:
        return False
    by_name = {item.get("name"): item for item in targets if isinstance(item, dict)}
    required = {"chrome_cdp_ipv4_9223", "other_ipv4_loopback", "ipv6_loopback"}
    if not required.issubset(by_name):
        return False
    expected = {"chrome_cdp_ipv4_9223": ("127.0.0.1", 9223),
                "other_ipv4_loopback": ("127.0.0.2", None), "ipv6_loopback": ("::1", None)}
    for name, (host, fixed_port) in expected.items():
        item = by_name[name]
        try:
            port = int(item.get("port"))
        except (TypeError, ValueError):
            return False
        if item.get("host") != host or not 1 <= port <= 65535 or (fixed_port is not None and port != fixed_port):
            return False
    lan_targets = [item for item in targets if item.get("name", "").startswith("lan_ipv4_")]
    if not lan_targets:
        return False
    for item in lan_targets:
        try:
            address = ipaddress.ip_address(item.get("host", ""))
            port = int(item.get("port"))
        except (ValueError, TypeError):
            return False
        if address.version != 4 or not address.is_private or not 1 <= port <= 65535:
            return False
    return True


def parse_lfs_pointer(pointer: str) -> tuple[str, int] | None:
    oid_match = re.search(r"^oid sha256:([0-9a-f]{64})$", pointer, re.M)
    size_match = re.search(r"^size ([0-9]+)$", pointer, re.M)
    if not oid_match or not size_match:
        return None
    return oid_match.group(1), int(size_match.group(1))


def classify_lfs_failure(returncode: int, detail: str) -> str:
    text = detail.lower()
    if returncode == 124 or "timed out" in text or "timeout" in text:
        return "network_timeout"
    if "403" in text or "forbidden" in text:
        return "authorization_denied"
    if "401" in text or "authentication" in text or "basic auth" in text:
        return "authentication_required"
    if any(term in text for term in ("connection", "tls", "ssl", "resolve", "network is unreachable")):
        return "transport_failure"
    return "lfs_protocol_or_object_failure"


def public_https_probe(host: str, path: str = "/") -> dict[str, Any]:
    """Bound DNS, TCP, TLS and HTTP checks while pinning later phases to the resolved IP."""
    phases: dict[str, Any] = {}
    started = time.monotonic()
    rc, output, _ = run(["/usr/bin/getent", "ahosts", host], timeout=5)
    addresses = []
    if rc == 0:
        for line in output.splitlines():
            candidate = line.split()[0] if line.split() else ""
            try:
                address = ipaddress.ip_address(candidate)
            except ValueError:
                continue
            if str(address) not in addresses:
                addresses.append(str(address))
    phases["dns"] = {"pass": bool(addresses), "answer_count": len(addresses),
                     "duration_seconds": round(time.monotonic() - started, 4)}
    if not addresses:
        phases["tcp"] = {"pass": False, "not_attempted": True}
        phases["tls"] = {"pass": False, "not_attempted": True}
        phases["http"] = {"pass": False, "not_attempted": True}
        return {"pass": False, "disposition": "network_timeout" if rc == 124 else "dns_failure", "phases": phases,
                "total_duration_seconds": round(time.monotonic() - started, 4), "total_timeout_seconds": 23}
    sock = None
    secure = None
    phase_started = time.monotonic()
    try:
        sock = socket.create_connection((addresses[0], 443), timeout=5)
        phases["tcp"] = {"pass": True, "duration_seconds": round(time.monotonic() - phase_started, 4)}
    except OSError as exc:
        phases["tcp"] = {"pass": False, "error": type(exc).__name__,
                         "duration_seconds": round(time.monotonic() - phase_started, 4)}
        phases["tls"] = {"pass": False, "not_attempted": True}
        phases["http"] = {"pass": False, "not_attempted": True}
        return {"pass": False, "disposition": "network_timeout" if isinstance(exc, TimeoutError) else "transport_failure",
                "phases": phases, "total_duration_seconds": round(time.monotonic() - started, 4), "total_timeout_seconds": 23}
    phase_started = time.monotonic()
    try:
        sock.settimeout(5)
        secure = ssl.create_default_context().wrap_socket(sock, server_hostname=host)
        phases["tls"] = {"pass": True, "version": secure.version(),
                         "duration_seconds": round(time.monotonic() - phase_started, 4)}
    except (OSError, ssl.SSLError) as exc:
        if sock is not None:
            sock.close()
        phases["tls"] = {"pass": False, "error": type(exc).__name__,
                         "duration_seconds": round(time.monotonic() - phase_started, 4)}
        phases["http"] = {"pass": False, "not_attempted": True}
        return {"pass": False, "disposition": "network_timeout" if isinstance(exc, TimeoutError) else "transport_failure",
                "phases": phases, "total_duration_seconds": round(time.monotonic() - started, 4), "total_timeout_seconds": 23}
    phase_started = time.monotonic()
    try:
        secure.settimeout(8)
        request = f"GET {path} HTTP/1.1\r\nHost: {host}\r\nUser-Agent: custodian-worker-proof/1\r\nConnection: close\r\n\r\n".encode("ascii")
        secure.sendall(request)
        with secure.makefile("rb") as response_stream:
            status_line = response_stream.readline(4096).decode("ascii", "replace").strip()
        match = re.match(r"^HTTP/\d(?:\.\d)?\s+(\d{3})\b", status_line)
        status = int(match.group(1)) if match else None
        phases["http"] = {"pass": status is not None and 200 <= status < 400, "status": status,
                          "duration_seconds": round(time.monotonic() - phase_started, 4)}
    except (OSError, ssl.SSLError) as exc:
        phases["http"] = {"pass": False, "error": type(exc).__name__,
                          "duration_seconds": round(time.monotonic() - phase_started, 4)}
    finally:
        if secure is not None:
            secure.close()
    return {"pass": all(phases[name]["pass"] for name in ("dns", "tcp", "tls", "http")),
            "disposition": "passed" if all(phases[name]["pass"] for name in ("dns", "tcp", "tls", "http")) else
            "network_timeout" if any(phases[name].get("error") in ("TimeoutError", "TimeoutError") for name in ("tcp", "tls", "http")) else "transport_failure",
            "phases": phases, "total_duration_seconds": round(time.monotonic() - started, 4), "total_timeout_seconds": 23}


def read_probe_config() -> dict[str, Any]:
    if CONFIG.is_symlink():
        raise RuntimeError("probe config must not be a symlink")
    st = CONFIG.stat(follow_symlinks=False)
    if not CONFIG.is_file() or st.st_uid != 0 or stat_mode_writable(st.st_mode):
        raise RuntimeError("probe config is absent, writable, or not root-owned")
    data = json.loads(CONFIG.read_text())
    if not valid_probe_config(data):
        raise RuntimeError("probe config failed schema and boundary validation")
    return data


def stat_mode_writable(mode: int) -> bool:
    return bool(mode & 0o022)


def denied_connect(host: str, port: int, family: int) -> dict[str, Any]:
    try:
        with socket.socket(family, socket.SOCK_STREAM) as sock:
            sock.settimeout(1.5)
            sock.connect((host, port))
        return {"blocked": False, "error": None}
    except OSError as exc:
        return {"blocked": exc.errno in DENIED_ERRNOS, "error": errno.errorcode.get(exc.errno, str(exc.errno))}


def path_denial(path: str, *, socket_path: bool = False) -> dict[str, Any]:
    try:
        if socket_path:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                sock.settimeout(0.5)
                sock.connect(path)
        else:
            with os.scandir(path) as entries:
                count = sum(1 for _ in entries)
            return {"denied": False, "empty": count == 0}
        return {"denied": False, "empty": False}
    except OSError as exc:
        return {"denied": exc.errno in {errno.EACCES, errno.EPERM, errno.ENOENT, errno.ENOTDIR, errno.ECONNREFUSED},
                "error": errno.errorcode.get(exc.errno, str(exc.errno))}


def inside_proof() -> dict[str, Any]:
    config = read_probe_config()
    euid = os.geteuid()
    egid = os.getegid()
    account = pwd.getpwuid(euid)
    groups = sorted(set(os.getgroups()) | {egid})
    env_keys = sorted(os.environ)
    cgroup = Path("/proc/self/cgroup").read_text().strip()
    identity_ok = (account.pw_name == "custodian-worker" and grp.getgrgid(egid).gr_name == "custodian-worker"
                   and euid != 0 and groups == [egid])
    environment_ok = not any(FORBIDDEN_ENV.search(key) for key in env_keys)
    unit_ok = "custodian-worker@proof.service" in cgroup

    preflight_path = Path(os.environ.get("TMPDIR", "/tmp")) / f"isolation-preflight-{config['run_id']}.json"
    preflight = json.loads(preflight_path.read_text())
    loopback = {item["name"]: {"blocked": item["blocked"], "error": item.get("errno")}
                for item in preflight["probes"]}
    loopback_ok = preflight.get("pass") is True and all(item["blocked"] for item in preflight["probes"])

    home_access = {path: path_denial(path) for path in ("/home", "/root", "/run/user")}
    protected_sockets = {
        path: path_denial(path, socket_path=True)
        for path in ("/run/docker.sock", "/var/run/docker.sock", "/run/dbus/system_bus_socket",
                     "/run/systemd/private", "/run/tailscale/tailscaled.sock")
    }


    interfaces_ok = all(result["denied"] for result in protected_sockets.values()) and all(
        result["denied"] or result.get("empty", False) for result in home_access.values())

    public_network = public_https_probe("github.com")
    dns_phase = public_network["phases"]["dns"]
    http_phase = public_network["phases"]["http"]
    dns_ok = dns_phase["pass"]
    https_ok = public_network["pass"]

    tools: dict[str, Any] = {}
    python_path = shutil.which("python3")
    godot_path = shutil.which("godot")
    blender_path = shutil.which("blender")
    git_path = shutil.which("git")
    git_lfs_path = shutil.which("git-lfs")
    codex_path = shutil.which("codex")
    tools["python"] = safe_command([python_path, "--version"]) if python_path else {"exit_code": 127}
    tools["godot_headless"] = safe_command([godot_path, "--headless", "--version"], timeout=60) if godot_path else {"exit_code": 127}
    tools["blender_background"] = safe_command([
        blender_path, "--background", "--factory-startup", "--disable-autoexec",
        "--python-expr", "import bpy; print('WORKER_BLENDER_OK ' + bpy.app.version_string)",
    ], timeout=120) if blender_path else {"exit_code": 127}
    tools["git"] = safe_command([git_path, "--version"]) if git_path else {"exit_code": 127}
    tools["git_lfs"] = safe_command([git_path, "lfs", "version"]) if git_path else {"exit_code": 127}
    tools["codex_cli"] = safe_command([codex_path, "--version"]) if codex_path else {"exit_code": 127}

    git_read = {"exit_code": 127, "head": None}
    if git_path:
        rc, out, _ = run([git_path, "-c", "credential.helper=", "ls-remote", REPO_URL, "HEAD"], timeout=60)
        git_read = {"exit_code": rc, "head": out.split()[0] if rc == 0 and out.split() else None}

    lfs = fetch_one_public_lfs_object(git_path, config["run_id"]) if git_path else {"exit_code": 127}

    # Attempt a real non-interactive Codex model call with only worker-owned state.
    # The result is summarized; stderr/stdout (which can contain request details) are never logged.
    codex = {"attempted": False, "exit_code": None, "response_verified": False, "disposition": "cli_unavailable"}
    worker_auth = Path(os.environ.get("CODEX_HOME", "/nonexistent")) / "auth.json"
    if codex_path and not worker_auth.exists():
        codex["attempted"] = True
        rc, out, _ = run([
            codex_path, "exec", "--ephemeral", "--ignore-user-config", "--sandbox", "read-only",
            "--cd", str(WORKSPACES), "Respond exactly with WORKER_MODEL_OK.",
        ], timeout=90)
        codex["exit_code"] = rc
        codex["response_verified"] = rc == 0 and "WORKER_MODEL_OK" in out
        codex["disposition"] = "passed" if codex["response_verified"] else "worker_auth_or_model_unavailable"
    elif worker_auth.exists():
        codex["disposition"] = "worker_auth_present_provenance_unverified"

    return {
        "schema": "custodian.worker_isolation_proof.v1",
        "run_id": config["run_id"],
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "identity": {"user": account.pw_name, "uid": euid, "gid": egid, "groups": groups,
                     "cgroup": cgroup, "pass": identity_ok and unit_ok},
        "environment": {"keys": env_keys, "forbidden_keys_absent": environment_ok,
                         "home": os.environ.get("HOME"), "codex_home": os.environ.get("CODEX_HOME")},
        "loopback": {"targets": loopback, "pass": loopback_ok},
        "isolation_preflight": preflight,
        "protected_interfaces": {"paths": {**home_access, **protected_sockets}, "pass": interfaces_ok},
        "network": {"dns": dns_phase,
                    "https_github": {"pass": https_ok, "status": http_phase.get("status"),
                                     "transport": public_network["phases"],
                                     "total_duration_seconds": public_network["total_duration_seconds"]}},
        "tools": tools,
        "git_read": git_read,
        "lfs_read": lfs,
        "model_call": codex,
    }


def inside_lfs_diagnostic() -> dict[str, Any]:
    config = read_probe_config()
    preflight_path = Path(os.environ.get("TMPDIR", "/tmp")) / f"isolation-preflight-{config['run_id']}.json"
    preflight = json.loads(preflight_path.read_text())
    if preflight.get("pass") is not True:
        raise RuntimeError("LFS diagnostic refused because isolation preflight did not pass")
    git_path = shutil.which("git")
    lfs = fetch_one_public_lfs_object(git_path, config["run_id"]) if git_path else {
        "exit_code": 127, "disposition": "transport_failure", "phase": "tool_unavailable"}
    return {"schema": "custodian.worker_lfs_diagnostic.v1", "run_id": config["run_id"],
            "pid": os.getpid(), "cgroup": Path("/proc/self/cgroup").read_text().strip(),
            "isolation_preflight_pass": preflight.get("pass") is True, "lfs_read": lfs,
            "timestamp_utc": datetime.now(timezone.utc).isoformat()}

def fetch_one_public_lfs_object(git: str, run_id: str) -> dict[str, Any]:
    destination = WORKSPACES / f"lfs-proof-{run_id}"
    if destination.exists() or destination.is_symlink():
        return {"exit_code": 73, "disposition": "destination_already_exists"}
    public_network = public_https_probe("github.com")
    transport = public_network["phases"]
    if not public_network["pass"]:
        disposition = public_network["disposition"]
        return {"exit_code": 124 if disposition == "network_timeout" else 69,
                "disposition": disposition, "transport": transport,
                "total_duration_seconds": public_network["total_duration_seconds"],
                "total_timeout_seconds": public_network["total_timeout_seconds"]}
    clone_started = time.monotonic()
    rc, _, clone_stderr = run([
        git, "-c", "credential.helper=", "clone", "--filter=blob:none", "--depth=1",
        "--no-checkout", "--single-branch", "--branch", "main", REPO_URL, str(destination),
    ], timeout=12)
    if rc:
        disposition = classify_lfs_failure(rc, clone_stderr or ("timeout" if rc == 124 else "clone transport error"))
        return {"exit_code": rc, "disposition": disposition, "transport": transport, "phase": "public_clone",
                "clone_duration_seconds": round(time.monotonic() - clone_started, 4),
                "authentication_result": disposition if disposition in ("authentication_required", "authorization_denied") else "not_observed",
                "lfs_http_response": {"received": False, "status": None}, "total_timeout_seconds": 58}
    rc, pointer, _ = run([git, "-C", str(destination), "show", f"origin/main:{LFS_PATH}"], timeout=3)
    if rc:
        return {"exit_code": rc, "disposition": "lfs_pointer_not_available"}
    parsed = parse_lfs_pointer(pointer)
    if parsed is None:
        return {"exit_code": 65, "disposition": "not_a_valid_lfs_pointer"}
    oid, expected_size = parsed
    transfer_started = time.monotonic()
    rc, _, stderr = run([
        git, "-C", str(destination), "lfs", "fetch", f"--include={LFS_PATH}", "--exclude=", "origin", "main",
    ], timeout=20)
    if rc:
        kind = classify_lfs_failure(rc, stderr)
        status_match = re.search(r"\bHTTP(?:/\d(?:\.\d)?)?\s+(\d{3})\b", stderr, re.I)
        http_status = int(status_match.group(1)) if status_match else None
        return {"exit_code": rc, "disposition": kind, "object_oid": oid, "expected_size": expected_size,
                "transport": transport, "phase": "git_lfs_fetch",
                "transfer_duration_seconds": round(time.monotonic() - transfer_started, 4),
                "authentication_result": kind if kind in ("authentication_required", "authorization_denied") else "not_observed",
                "lfs_http_response": {"received": http_status is not None, "status": http_status},
                "total_timeout_seconds": 58}
    object_path = destination / ".git" / "lfs" / "objects" / oid[:2] / oid[2:4] / oid
    if not object_path.is_file():
        return {"exit_code": 66, "disposition": "fetched_object_missing", "object_oid": oid}
    digest = hashlib.sha256(object_path.read_bytes()).hexdigest()
    actual_size = object_path.stat().st_size
    ok = digest == oid and actual_size == expected_size
    return {"exit_code": 0 if ok else 67, "disposition": "anonymous_access_succeeded" if ok else "lfs_protocol_or_object_failure",
            "object_oid": oid, "size": actual_size, "sha256_matches_pointer": digest == oid,
            "size_matches_pointer": actual_size == expected_size, "path": LFS_PATH, "transport": transport,
            "authentication_result": "anonymous_no_auth_used", "lfs_http_response": {"received": True, "status": "not_exposed_by_git_lfs"},
            "transfer_duration_seconds": round(time.monotonic() - transfer_started, 4), "total_timeout_seconds": 58}


def listener(family: int, host: str) -> tuple[socket.socket, int, list[int], threading.Event, threading.Thread]:
    sock = socket.socket(family, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind((host, 0))
    sock.listen(4)
    sock.settimeout(0.2)
    accepted: list[int] = []

    def accept_loop() -> None:
        while not stop.is_set():
            try:
                connection, _ = sock.accept()
            except socket.timeout:
                continue
            except OSError:
                return
            accepted.append(1)
            connection.close()

    stop = threading.Event()
    thread = threading.Thread(target=accept_loop, daemon=True)
    thread.start()
    return sock, int(sock.getsockname()[1]), accepted, stop, thread


def close_listener(sock: socket.socket, stop: threading.Event, thread: threading.Thread) -> None:
    stop.set()
    sock.close()
    thread.join(timeout=1)


def host_proof(preflight_only: bool = False, lfs_only: bool = False) -> dict[str, Any]:
    if preflight_only and lfs_only:
        raise RuntimeError("preflight-only and LFS-only modes are mutually exclusive")
    if os.geteuid() != 0:
        raise RuntimeError("host proof collection requires root; run through sudo")
    if CONFIG.is_symlink():
        raise RuntimeError("refusing symlink probe configuration")
    if CONFIG.exists():
        raise RuntimeError("probe configuration already exists; preserve and inspect it")
    chrome = socket.create_connection(("127.0.0.1", 9223), timeout=1.5)
    chrome.close()
    v4, p4, accepted4, stop4, thread4 = listener(socket.AF_INET, "127.0.0.2")
    v6, p6, accepted6, stop6, thread6 = listener(socket.AF_INET6, "::1")
    lan_listeners = []
    address_result = subprocess.run(["/usr/bin/ip", "-j", "-4", "address", "show", "scope", "global"],
                                    text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if address_result.returncode:
        raise RuntimeError("cannot inspect host LAN interfaces for positive-control targets")
    private_addresses = []
    for interface in json.loads(address_result.stdout):
        if interface.get("ifname", "").startswith(("br-", "docker", "tailscale", "virbr")):
            continue
        for item in interface.get("addr_info", []):
            address = ipaddress.ip_address(item.get("local", "0.0.0.0"))
            if address.version == 4 and any(address in net for net in (
                ipaddress.ip_network("10.0.0.0/8"), ipaddress.ip_network("172.16.0.0/12"),
                ipaddress.ip_network("192.168.0.0/16"))):
                if str(address) not in private_addresses:
                    private_addresses.append(str(address))
    for host in private_addresses[:2]:
        lan_listeners.append((host, *listener(socket.AF_INET, host)))
    if not lan_listeners:
        raise RuntimeError("no host RFC1918 LAN address is available for positive-control probes")
    run_id = os.urandom(8).hex()
    targets = [
        {"name": "chrome_cdp_ipv4_9223", "host": "127.0.0.1", "port": 9223},
        {"name": "other_ipv4_loopback", "host": "127.0.0.2", "port": p4},
        {"name": "ipv6_loopback", "host": "::1", "port": p6},
    ]
    for index, (host, sock, port, accepted, stop, thread) in enumerate(lan_listeners):
        targets.append({"name": f"lan_ipv4_{index}", "host": host, "port": port})
    positive_controls = []
    for target in targets:
        if target["name"] == "chrome_cdp_ipv4_9223":
            observed = socket.create_connection((target["host"], target["port"]), timeout=1.5)
            observed.close()
            positive_controls.append({"name": target["name"], "reachable": True, "method": "owner_connect"})
        else:
            listener_for_target = (v4, accepted4) if target["name"] == "other_ipv4_loopback" else \
                (v6, accepted6) if target["name"] == "ipv6_loopback" else \
                next((item[1], item[3]) for item in lan_listeners if item[0] == target["host"] and item[2] == target["port"])
            observed = socket.create_connection((target["host"], target["port"]), timeout=1.5)
            observed.close()
            deadline = time.monotonic() + 1.0
            while time.monotonic() < deadline and len(listener_for_target[1]) == 0:
                time.sleep(0.01)
            reachable = len(listener_for_target[1]) > 0
            positive_controls.append({"name": target["name"], "reachable": reachable,
                                      "method": "host_listener_accept", "host_listener_accept_count": len(listener_for_target[1])})
            if not reachable:
                raise RuntimeError(f"positive control listener did not accept host connection: {target['name']}")
    accepted_baseline = {"other_ipv4_loopback": len(accepted4), "ipv6_loopback": len(accepted6),
                         **{f"lan_ipv4_{i}": len(item[3]) for i, item in enumerate(lan_listeners)}}
    props = systemd_properties()
    data = {"schema": "custodian.worker_probe_config.v1", "run_id": run_id, "targets": targets,
            "unit_properties": props, "positive_controls": positive_controls, "preflight_only": preflight_only,
            "lfs_only": lfs_only}
    fd = os.open(CONFIG, os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0), 0o644)
    try:
        with os.fdopen(fd, "w", closefd=False) as stream:
            json.dump(data, stream, sort_keys=True)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
    finally:
        os.close(fd)
    os.chown(CONFIG, 0, 0)
    properties = systemd_properties()
    active_before = command_output(["/usr/bin/systemctl", "is-active", UNIT], allow_fail=True).strip()
    enabled = command_output(["/usr/bin/systemctl", "is-enabled", UNIT], allow_fail=True).strip()
    if active_before == "active" or enabled not in ("disabled", "static"):
        raise RuntimeError(f"service is not safely inactive/disabled (active={active_before}, enabled={enabled})")
    command_output(["/usr/bin/systemctl", "reset-failed", UNIT], allow_fail=True)
    started = run(["/usr/bin/systemctl", "start", UNIT], timeout=2700)
    logs_rc, logs, _ = run(["/usr/bin/journalctl", "--quiet", "--no-pager", "-o", "cat", "-u", UNIT, "-n", "300"], timeout=30)
    report = None
    for line in reversed(logs.splitlines()):
        if line.startswith("{"):
            try:
                candidate = json.loads(line)
            except json.JSONDecodeError:
                continue
            if candidate.get("run_id") == run_id:
                report = candidate
                break
    command_output(["/usr/bin/systemctl", "reset-failed", UNIT], allow_fail=True)
    time.sleep(0.25)
    close_listener(v4, stop4, thread4)
    close_listener(v6, stop6, thread6)
    for _, sock, _, _, stop, thread in lan_listeners:
        close_listener(sock, stop, thread)
    active_after = command_output(["/usr/bin/systemctl", "is-active", UNIT], allow_fail=True).strip()
    timers = command_output(["/usr/bin/systemctl", "list-timers", "--all", "--no-legend", "custodian-worker*"], allow_fail=True).strip()
    CONFIG.unlink(missing_ok=True)
    try:
        CONFIG.parent.chmod(0o755)
    except OSError:
        pass
    host_checks = {
        "chrome_loopback_listener_precondition": True,
        "ipv4_listener_accepted_connections": len(accepted4) - accepted_baseline["other_ipv4_loopback"],
        "ipv6_listener_accepted_connections": len(accepted6) - accepted_baseline["ipv6_loopback"],
        "lan_listener_accepted_connections": {f"lan_ipv4_{i}": len(item[3]) - accepted_baseline[f"lan_ipv4_{i}"]
                                                for i, item in enumerate(lan_listeners)},
        "positive_controls": positive_controls,
        "unit_start_exit_code": started[0],
        "unit_enabled_state": enabled,
        "unit_active_before": active_before,
        "unit_active_after": active_after,
        "worker_timers": timers,
        "unit_properties": properties,
        "journal_read_exit_code": logs_rc,
    }
    preflight_pass = bool(report and report.get("schema") == "custodian.worker_isolation_preflight.v1" and
                          report.get("pass") is True and all(item.get("blocked") for item in report.get("probes", [])))
    lfs_diagnostic_pass = bool(report and report.get("schema") == "custodian.worker_lfs_diagnostic.v1" and
                               report.get("isolation_preflight_pass"))
    complete_pass = bool(report and started[0] == 0 and
                report.get("identity", {}).get("pass") and report.get("environment", {}).get("forbidden_keys_absent") and
                report.get("loopback", {}).get("pass") and report.get("protected_interfaces", {}).get("pass") and
                report.get("network", {}).get("dns", {}).get("pass") and report.get("network", {}).get("https_github", {}).get("pass") and
                all(v.get("exit_code") == 0 for k, v in report.get("tools", {}).items() if k != "codex_cli") and
                report.get("git_read", {}).get("exit_code") == 0 and report.get("lfs_read", {}).get("disposition") == "anonymous_access_succeeded" and
                report.get("model_call", {}).get("response_verified") and enabled == "disabled" and active_after == "inactive" and
                not timers and len(accepted4) == accepted_baseline["other_ipv4_loopback"] and
                len(accepted6) == accepted_baseline["ipv6_loopback"] and
                all(len(item[3]) == accepted_baseline[f"lan_ipv4_{i}"] for i, item in enumerate(lan_listeners)) and started[0] == 0)
    result = {"schema": "custodian.worker_host_proof.v1", "run_id": run_id,
            "host_checks": host_checks, "inside_worker": report,
             "preflight_only": preflight_only,
             "diagnostic_pass": preflight_pass if preflight_only else lfs_diagnostic_pass if report and report.get("schema") == "custodian.worker_lfs_diagnostic.v1" else complete_pass,
             "full_proof_pass": False if preflight_only or (report and report.get("schema") == "custodian.worker_lfs_diagnostic.v1") else complete_pass}
    return result


def command_output(argv: list[str], allow_fail: bool = False) -> str:
    rc, stdout, _ = run(argv, timeout=30)
    if rc and not allow_fail:
        raise RuntimeError(f"host command failed: {argv[0]}")
    return stdout


def systemd_properties() -> dict[str, str]:
    names = ("User", "Group", "SupplementaryGroups", "CapabilityBoundingSet", "AmbientCapabilities",
             "NoNewPrivileges", "ProtectSystem", "ProtectHome", "PrivateTmp", "PrivateDevices",
             "ProtectProc", "IPAddressDeny", "RestrictAddressFamilies", "ReadWritePaths", "Restart",
             "UnitFileState", "ExecStart", "Slice", "FragmentPath", "DropInPaths", "IPAddressAllow")
    rc, out, _ = run(["/usr/bin/systemctl", "show", UNIT, "--no-pager", *(f"--property={n}" for n in names)], timeout=30)
    if rc:
        return {"systemctl_show_error": str(rc)}
    return dict(line.split("=", 1) for line in out.splitlines() if "=" in line)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--inside-worker", action="store_true")
    mode.add_argument("--inside-lfs", action="store_true")
    mode.add_argument("--host-run", action="store_true")
    parser.add_argument("--preflight-only", action="store_true", help="run only the in-service network gate")
    parser.add_argument("--lfs-only", action="store_true", help="run only the in-service bounded LFS diagnostic after the gate")
    args = parser.parse_args(argv)
    try:
        if args.preflight_only and not args.host_run:
            raise RuntimeError("--preflight-only is valid only with --host-run")
        if args.lfs_only and not args.host_run:
            raise RuntimeError("--lfs-only is valid only with --host-run")
        result = inside_lfs_diagnostic() if args.inside_lfs else inside_proof() if args.inside_worker else host_proof(args.preflight_only, args.lfs_only)
    except Exception as exc:
        print(json.dumps({"schema": "custodian.worker_proof_error.v1", "error_type": type(exc).__name__,
                          "message": str(exc)[:300]}, sort_keys=True))
        return 1
    print(json.dumps(result, sort_keys=True))
    return 0 if args.inside_worker or args.inside_lfs else (0 if result.get("diagnostic_pass", result.get("full_proof_pass")) else 2)


if __name__ == "__main__":
    raise SystemExit(main())
