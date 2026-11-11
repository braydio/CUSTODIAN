#!/usr/bin/python3
"""Run or collect the disposable systemd worker-isolation proof."""

from __future__ import annotations

import argparse
import errno
import grp
import hashlib
import http.client
import ipaddress
import json
import os
import pwd
import re
import shutil
import socket
import ssl
import stat
import subprocess
import sys
import tempfile
import threading
import time
import urllib.parse
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

STATE = Path("/var/lib/custodian-worker")
CONFIG = STATE / "probe.json"
WORKSPACES = STATE / "workspaces"
UNIT = "custodian-worker@proof.service"
REPO_URL = "https://github.com/braydio/CUSTODIAN.git"
LFS_PATH = "archive/Hubworld/Ashen_Forum/Cliff_Section_01_32x64.png"
LFS_BATCH_URL = "https://github.com/braydio/CUSTODIAN.git/info/lfs/objects/batch"
LFS_OBJECT_OID = "f14d37604bbce8b31671550e7c0a3cd5168d5e4273e8c67b95e301c392761c51"
LFS_OBJECT_SIZE = 4852
DENIED_ERRNOS = {errno.EACCES, errno.EPERM, errno.EHOSTUNREACH, errno.ENETUNREACH}
FORBIDDEN_ENV = re.compile(r"^(?:GITHUB_|GH_|OPENAI_|HL_|SSH_AUTH_SOCK$|CODEX_SESSION|CODEX_API_KEY$)")
HTTP_HEADER_NAME = re.compile(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$")
CREDENTIAL_NAME = "openai-api-key"
CREDENTIAL_SOURCE = Path("/etc/custodian-worker/credentials/openai-api-key")
API_KEY_FORMAT = re.compile(r"sk-[A-Za-z0-9_-]{20,}")
MODEL_OK_MARKER = "WORKER_MODEL_OK"
MODEL_PROBE_TIMEOUT_SECONDS = 60


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
    if any(name in data and not isinstance(data[name], bool)
           for name in ("preflight_only", "lfs_only", "model_only")):
        return False
    if sum(data.get(name) is True for name in ("preflight_only", "lfs_only", "model_only")) > 1:
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

    lfs = fetch_one_public_lfs_object() if git_path else {"exit_code": 127}

    # The model probe is opt-in through the separate --model-only host mode.
    # A general proof run never consumes a model credential or makes a model call.
    codex = {"attempted": False, "exit_code": None, "response_verified": False,
             "disposition": "explicit_model_only_mode_required"}

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


def _read_runtime_model_credential() -> tuple[str, str | None]:
    """Read one systemd-delivered API key without exposing bytes in errors or reports."""
    directory_value = os.environ.get("CREDENTIALS_DIRECTORY", "")
    directory = Path(directory_value)
    if (not directory_value or not directory.is_absolute() or ".." in directory.parts or
            str(directory) != directory_value or directory.is_symlink() or not directory.is_dir()):
        return "missing", None
    path = directory / CREDENTIAL_NAME
    try:
        fd = os.open(path, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
    except FileNotFoundError:
        return "missing", None
    except OSError:
        return "invalid", None
    try:
        info = os.fstat(fd)
        if (not stat.S_ISREG(info.st_mode) or info.st_uid != os.geteuid() or
                stat.S_IMODE(info.st_mode) != 0o400 or info.st_nlink != 1 or
                info.st_size < 1 or info.st_size > 4096):
            return "invalid", None
        raw = os.read(fd, 4097)
        if len(raw) != info.st_size or len(raw) > 4096:
            return "invalid", None
    except OSError:
        return "invalid", None
    finally:
        os.close(fd)
    try:
        key = raw.decode("ascii")
    except UnicodeDecodeError:
        return "invalid", None
    if not API_KEY_FORMAT.fullmatch(key):
        return "invalid", None
    return "valid", key


def _model_response_has_marker(stdout: str) -> bool:
    for line in stdout.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(event, dict) or event.get("type") != "item.completed":
            continue
        item = event.get("item")
        if not isinstance(item, dict) or item.get("type") != "agent_message":
            continue
        if item.get("text", "").strip() == MODEL_OK_MARKER:
            return True
    return False


def codex_model_probe() -> dict[str, Any]:
    """Run one harmless Codex response with an API key supplied only to Codex."""
    forbidden_environment_present = any(FORBIDDEN_ENV.search(key) for key in os.environ)
    if forbidden_environment_present:
        return {
            "attempted": False,
            "exit_code": None,
            "response_verified": False,
            "response_marker": None,
            "disposition": "inherited_credentials_present",
            "credential_status": "not_checked",
            "authentication_mode": "systemd_LoadCredential_openai_api_key",
            "inherited_owner_credentials_absent": False,
            "mcp_browser_tools_disabled": False,
            "network_preflight_required": True,
            "timeout_seconds": MODEL_PROBE_TIMEOUT_SECONDS,
        }
    credential_status, api_key = _read_runtime_model_credential()
    result: dict[str, Any] = {
        "attempted": False,
        "exit_code": None,
        "response_verified": False,
        "response_marker": None,
        "disposition": "credential_missing" if credential_status == "missing" else "credential_invalid",
        "credential_status": credential_status,
        "authentication_mode": "systemd_LoadCredential_openai_api_key",
        "inherited_owner_credentials_absent": not forbidden_environment_present,
        "mcp_browser_tools_disabled": True,
        "mcp_configuration": "empty",
        "github_mcp_browser_cdp_tools_absent": True,
        "authentication_store": "temporary_worker_owned_codex_home",
        "credential_value_logged": False,
        "credential_in_command_arguments": False,
        "credential_passed_to_non_codex_processes": False,
        "network_preflight_required": True,
        "timeout_seconds": MODEL_PROBE_TIMEOUT_SECONDS,
    }
    if credential_status != "valid" or api_key is None:
        return result
    codex_path = shutil.which("codex")
    if not codex_path:
        result["disposition"] = "codex_cli_unavailable"
        api_key = None
        return result
    version = safe_command([codex_path, "--version"], timeout=10)
    result["codex_cli"] = version

    # Construct a fresh home so no persisted auth or MCP configuration is consulted.
    temp_root = Path(os.environ.get("TMPDIR", "/tmp"))
    try:
        with tempfile.TemporaryDirectory(prefix="codex-model-probe-", dir=temp_root) as home:
            os.chmod(home, 0o700)
            child_env = {
                key: os.environ[key]
                for key in (
                    "PATH", "LANG", "HOME", "TMPDIR", "CREDENTIALS_DIRECTORY",
                    "GIT_CONFIG_NOSYSTEM", "GIT_CONFIG_GLOBAL", "GIT_TERMINAL_PROMPT",
                    "GIT_ASKPASS", "GIT_LFS_SKIP_SMUDGE",
                )
                if key in os.environ
            }
            child_env["CODEX_HOME"] = home
            child_env["OPENAI_API_KEY"] = api_key
            argv = [
                codex_path, "exec", "--ephemeral", "--ignore-user-config", "--sandbox", "read-only",
                "--cd", str(WORKSPACES), "--color", "never", "--json",
                "--config", 'shell_environment_policy.inherit="none"',
                "--config", "shell_environment_policy.ignore_default_excludes=false",
                "--config", 'model_reasoning_effort="low"',
                "--config", "features.apps=false",
                "--config", "features.remote_plugin=false",
                "--config", "features.multi_agent=false",
                "--config", "features.shell_tool=false",
                "--config", "mcp_servers={}",
                f"Reply with exactly {MODEL_OK_MARKER} and do not use tools.",
            ]
            result["attempted"] = True
            try:
                completed = subprocess.run(
                    argv, text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                    timeout=MODEL_PROBE_TIMEOUT_SECONDS, check=False, env=child_env, close_fds=True,
                )
            except subprocess.TimeoutExpired:
                result["exit_code"] = 124
                result["disposition"] = "model_probe_timeout"
                return result
            except OSError:
                result["exit_code"] = 127
                result["disposition"] = "model_probe_launch_failed"
                return result
            result["exit_code"] = completed.returncode
            result["response_verified"] = completed.returncode == 0 and _model_response_has_marker(completed.stdout)
            result["response_marker"] = MODEL_OK_MARKER if result["response_verified"] else None
            result["disposition"] = "passed" if result["response_verified"] else "model_response_unverified"
    finally:
        api_key = None
    return result


def inside_model_probe() -> dict[str, Any]:
    config = read_probe_config()
    if config.get("model_only") is not True:
        raise RuntimeError("model probe requires an explicit root-owned model-only request")
    preflight_path = Path(os.environ.get("TMPDIR", "/tmp")) / f"isolation-preflight-{config['run_id']}.json"
    preflight = json.loads(preflight_path.read_text())
    network_preflight_pass = preflight.get("pass") is True and all(
        item.get("blocked") is True for item in preflight.get("probes", []))
    account = pwd.getpwuid(os.geteuid())
    cgroup = Path("/proc/self/cgroup").read_text().strip()
    identity_pass = (account.pw_name == "custodian-worker" and os.geteuid() != 0 and
                     "custodian-worker@proof.service" in cgroup)
    system_codex_config = path_denial("/etc/codex")
    config_boundary_pass = system_codex_config.get("denied") is True
    model = codex_model_probe() if network_preflight_pass and identity_pass and config_boundary_pass else {
        "attempted": False, "exit_code": None, "response_verified": False,
        "disposition": "isolation_preflight_or_config_boundary_failed", "credential_status": "not_checked",
        "inherited_owner_credentials_absent": False, "mcp_browser_tools_disabled": False,
        "network_preflight_required": True,
    }
    model["mcp_browser_tools_disabled"] = model.get("mcp_browser_tools_disabled") is True and config_boundary_pass
    return {
        "schema": "custodian.worker_model_probe.v1",
        "run_id": config["run_id"],
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "identity": {"user": account.pw_name, "uid": os.geteuid(), "gid": os.getegid(),
                     "cgroup": cgroup, "pass": identity_pass},
        "network_preflight_pass": network_preflight_pass,
        "codex_configuration_boundary": {
            "system_config_unavailable": config_boundary_pass,
            "system_config_access": system_codex_config,
            "user_config_ignored": True,
            "temporary_codex_home": True,
            "mcp_servers_empty": True,
            "apps_remote_plugins_shell_and_subagents_disabled": True,
            "child_environment_inheritance": "none",
        },
        "model_call": model,
        "full_proof_pass": False,
    }


def inside_lfs_diagnostic() -> dict[str, Any]:
    config = read_probe_config()
    preflight_path = Path(os.environ.get("TMPDIR", "/tmp")) / f"isolation-preflight-{config['run_id']}.json"
    preflight = json.loads(preflight_path.read_text())
    if preflight.get("pass") is not True:
        raise RuntimeError("LFS diagnostic refused because isolation preflight did not pass")
    git_path = shutil.which("git")
    lfs = fetch_one_public_lfs_object() if git_path else {
        "exit_code": 127, "disposition": "transport_failure", "phase": "tool_unavailable"}
    return {"schema": "custodian.worker_lfs_diagnostic.v1", "run_id": config["run_id"],
            "pid": os.getpid(), "cgroup": Path("/proc/self/cgroup").read_text().strip(),
            "isolation_preflight_pass": preflight.get("pass") is True, "lfs_read": lfs,
            "timestamp_utc": datetime.now(timezone.utc).isoformat()}

def _timing_record(started: float, *, passed: bool, **details: Any) -> dict[str, Any]:
    return {"pass": passed, "duration_seconds": round(time.monotonic() - started, 4), **details}


def _pinned_https_request(host: str, target: str, method: str, headers: dict[str, str],
                          payload: bytes | None = None, *, max_response_bytes: int = 1_000_000
                          ) -> tuple[dict[str, Any], bytes]:
    """Make one bounded HTTPS request without logging the target or supplied headers."""
    started = time.monotonic()
    phases: dict[str, Any] = {}
    forbidden_action_headers = {"host", "connection", "content-length", "transfer-encoding"}
    if (method not in {"GET", "POST"} or "\r" in target or "\n" in target or
            (method == "GET" and any(name.lower() in forbidden_action_headers for name in headers))):
        return {"pass": False, "phase": "request_validation", "phases": phases,
                "total_duration_seconds": round(time.monotonic() - started, 4)}, b""
    phase_started = time.monotonic()
    dns_rc, dns_output, _ = run(["/usr/bin/getent", "ahosts", host], timeout=5)
    if dns_rc:
        phases["dns"] = _timing_record(phase_started, passed=False,
                                       error="TimeoutError" if dns_rc == 124 else "ResolverError", answer_count=0)
        return {"pass": False, "phase": "dns", "phases": phases,
                "total_duration_seconds": round(time.monotonic() - started, 4)}, b""

    addresses: list[tuple[int, str]] = []
    for line in dns_output.splitlines():
        candidate = line.split()[0] if line.split() else ""
        try:
            parsed = ipaddress.ip_address(candidate)
        except ValueError:
            continue
        family = socket.AF_INET6 if parsed.version == 6 else socket.AF_INET
        if parsed.is_global and (family, str(parsed)) not in addresses:
            addresses.append((family, str(parsed)))
    phases["dns"] = _timing_record(phase_started, passed=bool(addresses), answer_count=len(addresses))
    if not addresses:
        return {"pass": False, "phase": "dns", "phases": phases,
                "total_duration_seconds": round(time.monotonic() - started, 4)}, b""

    raw = None
    last_error = None
    phase_started = time.monotonic()
    tcp_deadline = phase_started + 5
    for family, address in addresses[:4]:
        remaining = tcp_deadline - time.monotonic()
        if remaining <= 0:
            break
        try:
            raw = socket.create_connection((address, 443), timeout=remaining)
            break
        except OSError as exc:
            last_error = exc
    phases["tcp"] = _timing_record(phase_started, passed=raw is not None,
                                   **({} if raw is not None else {"error": type(last_error).__name__ if last_error else "ConnectionError"}))
    if raw is None:
        return {"pass": False, "phase": "tcp", "phases": phases,
                "total_duration_seconds": round(time.monotonic() - started, 4)}, b""

    secure = None
    response = None
    try:
        phase_started = time.monotonic()
        raw.settimeout(5)
        try:
            secure = ssl.create_default_context().wrap_socket(raw, server_hostname=host)
        except (OSError, ssl.SSLError) as exc:
            phases["tls"] = _timing_record(phase_started, passed=False, error=type(exc).__name__)
            return {"pass": False, "phase": "tls", "phases": phases,
                    "total_duration_seconds": round(time.monotonic() - started, 4)}, b""
        phases["tls"] = _timing_record(phase_started, passed=True, version=secure.version())

        request_headers = {"Host": host, "Connection": "close", "User-Agent": "custodian-worker-proof/1"}
        request_headers.update(headers)
        request_line = f"{method} {target} HTTP/1.1\r\n".encode("ascii")
        header_bytes = b"".join(f"{name}: {value}\r\n".encode("latin-1") for name, value in request_headers.items())
        phase_started = time.monotonic()
        secure.settimeout(10)
        secure.sendall(request_line + header_bytes + b"\r\n" + (payload or b""))
        response = http.client.HTTPResponse(secure)
        response.begin()
        status = response.status
        response_body = response.read(max_response_bytes + 1)
        too_large = len(response_body) > max_response_bytes
        if too_large:
            response_body = b""
        phases["http"] = _timing_record(phase_started, passed=200 <= status < 300 and not too_large,
                                        status=status, response_bytes=0 if too_large else len(response_body),
                                        response_too_large=too_large)
        ok = phases["http"]["pass"]
        return {"pass": ok, "phase": "complete" if ok else "http", "phases": phases,
                "total_duration_seconds": round(time.monotonic() - started, 4)}, response_body
    except (OSError, ssl.SSLError, http.client.HTTPException, UnicodeError, ValueError) as exc:
        phases.setdefault("http", _timing_record(time.monotonic(), passed=False, error=type(exc).__name__))
        failed_phase = "http" if "tls" in phases else "tls"
        return {"pass": False, "phase": failed_phase, "phases": phases,
                "total_duration_seconds": round(time.monotonic() - started, 4)}, b""
    finally:
        if response is not None:
            response.close()
        if secure is not None:
            secure.close()
        elif raw is not None:
            raw.close()


def fetch_one_public_lfs_object() -> dict[str, Any]:
    """Fetch one known public LFS object using an anonymous batch and in-memory action."""
    batch_parts = urllib.parse.urlsplit(LFS_BATCH_URL)
    batch_body = json.dumps({"operation": "download", "transfers": ["basic"],
                             "ref": {"name": "refs/heads/main"},
                             "objects": [{"oid": LFS_OBJECT_OID, "size": LFS_OBJECT_SIZE}]},
                            separators=(",", ":")).encode("utf-8")
    batch_headers = {"Accept": "application/vnd.git-lfs+json",
                     "Content-Type": "application/vnd.git-lfs+json",
                     "Content-Length": str(len(batch_body))}
    batch_result, batch_response = _pinned_https_request(
        batch_parts.hostname or "", batch_parts.path, "POST", batch_headers, batch_body,
    )
    if not batch_result["pass"]:
        status = batch_result["phases"].get("http", {}).get("status")
        timed_out = any(v.get("error") == "TimeoutError" for v in batch_result["phases"].values())
        disposition = "authentication_required" if status == 401 else "authorization_denied" if status == 403 else \
            "network_timeout" if timed_out else "transport_failure" if batch_result["phase"] != "http" else "lfs_protocol_or_object_failure"
        return {"exit_code": 124 if timed_out else 69,
                "disposition": disposition,
                "phase": f"batch_{batch_result['phase']}", "batch": batch_result["phases"],
                "authentication_result": "anonymous_request_no_authorization_header",
                "total_timeout_seconds": 50}
    try:
        envelope = json.loads(batch_response)
    except (UnicodeDecodeError, json.JSONDecodeError):
        return {"exit_code": 65, "disposition": "lfs_protocol_or_object_failure", "phase": "batch_json",
                "batch": batch_result["phases"], "authentication_result": "anonymous_request_no_authorization_header"}
    objects = envelope.get("objects") if isinstance(envelope, dict) else None
    item = objects[0] if isinstance(objects, list) and len(objects) == 1 else None
    if (not isinstance(item, dict) or item.get("oid") != LFS_OBJECT_OID or
            item.get("size") != LFS_OBJECT_SIZE or envelope.get("transfer", "basic") != "basic"):
        return {"exit_code": 65, "disposition": "lfs_protocol_or_object_failure", "phase": "batch_object",
                "batch": batch_result["phases"], "authentication_result": "anonymous_request_no_authorization_header"}
    actions = item.get("actions")
    action = actions.get("download") if isinstance(actions, dict) else None
    href = action.get("href") if isinstance(action, dict) else None
    action_headers = action.get("header", {}) if isinstance(action, dict) else {}
    if (not isinstance(href, str) or not isinstance(action_headers, dict) or len(action_headers) > 32 or
            sum(len(k) + len(v) for k, v in action_headers.items() if isinstance(k, str) and isinstance(v, str)) > 8192 or
            not all(isinstance(k, str) and isinstance(v, str) and HTTP_HEADER_NAME.fullmatch(k) and
                    "\r" not in k + v and "\n" not in k + v for k, v in action_headers.items())):
        return {"exit_code": 65, "disposition": "lfs_protocol_or_object_failure", "phase": "download_action",
                "batch": batch_result["phases"], "authentication_result": "anonymous_request_no_authorization_header"}
    try:
        download_url = urllib.parse.urlsplit(href)
        valid_action = (download_url.scheme == "https" and download_url.hostname == "github-cloud.githubusercontent.com"
                        and download_url.port in (None, 443) and not download_url.username
                        and not download_url.password and not download_url.fragment and bool(download_url.path))
    except ValueError:
        valid_action = False
        download_url = None
    if not valid_action or download_url is None:
        return {"exit_code": 65, "disposition": "lfs_protocol_or_object_failure", "phase": "download_action_host",
                "batch": batch_result["phases"], "authentication_result": "anonymous_request_no_authorization_header"}

    download_target = download_url.path + ("?" + download_url.query if download_url.query else "")
    download_result, payload = _pinned_https_request(
        "github-cloud.githubusercontent.com", download_target, "GET", action_headers,
        max_response_bytes=LFS_OBJECT_SIZE,
    )
    safe_download = {"host": "github-cloud.githubusercontent.com", "connection_tested": all(
        download_result["phases"].get(key, {}).get("pass") is True for key in ("dns", "tcp", "tls")),
        "phases": download_result["phases"]}
    if not download_result["pass"]:
        timed_out = any(v.get("error") == "TimeoutError" for v in download_result["phases"].values())
        status = download_result["phases"].get("http", {}).get("status")
        disposition = "authentication_required" if status == 401 else "authorization_denied" if status == 403 else \
            "network_timeout" if timed_out else "transport_failure" if download_result["phase"] != "http" else "lfs_protocol_or_object_failure"
        return {"exit_code": 124 if timed_out else 69,
                "disposition": disposition,
                "phase": f"download_{download_result['phase']}", "object_oid": LFS_OBJECT_OID,
                "expected_size": LFS_OBJECT_SIZE, "batch": batch_result["phases"],
                "download": safe_download,
                "authentication_result": "anonymous_batch_action_no_repository_authorization_header",
                "total_timeout_seconds": 50}
    digest = hashlib.sha256(payload).hexdigest()
    ok = len(payload) == LFS_OBJECT_SIZE and digest == LFS_OBJECT_OID
    return {"exit_code": 0 if ok else 67,
            "disposition": "anonymous_access_succeeded" if ok else "lfs_protocol_or_object_failure",
            "phase": "complete" if ok else "object_verify", "object_oid": LFS_OBJECT_OID,
            "expected_size": LFS_OBJECT_SIZE, "size": len(payload), "sha256": digest,
            "sha256_matches_pointer": digest == LFS_OBJECT_OID,
            "size_matches_pointer": len(payload) == LFS_OBJECT_SIZE,
            "batch": batch_result["phases"], "download": safe_download,
            "authentication_result": "anonymous_no_repository_credentials_used",
                "total_timeout_seconds": 50}


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


def host_proof(preflight_only: bool = False, lfs_only: bool = False,
               model_only: bool = False) -> dict[str, Any]:
    if sum((preflight_only, lfs_only, model_only)) > 1:
        raise RuntimeError("preflight-only, LFS-only, and model-only modes are mutually exclusive")
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
            "lfs_only": lfs_only, "model_only": model_only}
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
    model_probe_pass = bool(
        report and report.get("schema") == "custodian.worker_model_probe.v1" and
        report.get("identity", {}).get("pass") and report.get("network_preflight_pass") and
        report.get("model_call", {}).get("attempted") and report.get("model_call", {}).get("exit_code") == 0 and
        report.get("model_call", {}).get("response_verified") and
        report.get("model_call", {}).get("credential_status") == "valid" and
        report.get("model_call", {}).get("inherited_owner_credentials_absent") and
        report.get("model_call", {}).get("mcp_browser_tools_disabled") and
        started[0] == 0 and enabled == "disabled" and active_after == "inactive" and not timers and
        len(accepted4) == accepted_baseline["other_ipv4_loopback"] and
        len(accepted6) == accepted_baseline["ipv6_loopback"] and
        all(len(item[3]) == accepted_baseline[f"lan_ipv4_{i}"] for i, item in enumerate(lan_listeners))
    )
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
             "lfs_only": lfs_only, "model_only": model_only,
             "diagnostic_pass": preflight_pass if preflight_only else
             lfs_diagnostic_pass if lfs_only else model_probe_pass if model_only else complete_pass,
             "full_proof_pass": False if preflight_only or lfs_only or model_only else complete_pass}
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
    names = (*names, "LoadCredentialEncrypted")
    rc, out, _ = run(["/usr/bin/systemctl", "show", UNIT, "--no-pager", *(f"--property={n}" for n in names)], timeout=30)
    if rc:
        return {"systemctl_show_error": str(rc)}
    return dict(line.split("=", 1) for line in out.splitlines() if "=" in line)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--inside-worker", action="store_true")
    mode.add_argument("--inside-lfs", action="store_true")
    mode.add_argument("--inside-model", action="store_true")
    mode.add_argument("--host-run", action="store_true")
    parser.add_argument("--preflight-only", action="store_true", help="run only the in-service network gate")
    parser.add_argument("--lfs-only", action="store_true", help="run only the in-service bounded LFS diagnostic after the gate")
    parser.add_argument("--model-only", action="store_true", help="run only one credential-gated Codex response after the isolation gate")
    args = parser.parse_args(argv)
    try:
        if args.preflight_only and not args.host_run:
            raise RuntimeError("--preflight-only is valid only with --host-run")
        if args.lfs_only and not args.host_run:
            raise RuntimeError("--lfs-only is valid only with --host-run")
        if args.model_only and not args.host_run:
            raise RuntimeError("--model-only is valid only with --host-run")
        result = (inside_lfs_diagnostic() if args.inside_lfs else inside_model_probe() if args.inside_model else
                  inside_proof() if args.inside_worker else host_proof(args.preflight_only, args.lfs_only, args.model_only))
    except Exception as exc:
        print(json.dumps({"schema": "custodian.worker_proof_error.v1", "error_type": type(exc).__name__,
                          "message": str(exc)[:300]}, sort_keys=True))
        return 1
    print(json.dumps(result, sort_keys=True))
    if args.inside_model:
        return 0 if result.get("model_call", {}).get("response_verified") is True else 2
    return 0 if args.inside_worker or args.inside_lfs else (0 if result.get("diagnostic_pass", result.get("full_proof_pass")) else 2)


if __name__ == "__main__":
    raise SystemExit(main())
