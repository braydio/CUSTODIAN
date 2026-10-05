#!/usr/bin/env python3
"""Small shared rclone transport primitives for CUSTODIAN Dropbox workflows."""

from __future__ import annotations

import hashlib
import os
import subprocess
from pathlib import Path
from typing import Callable, Mapping, Sequence


Runner = Callable[..., subprocess.CompletedProcess[str]]


def run(
    args: list[str],
    *,
    check: bool = True,
    capture_output: bool = True,
) -> subprocess.CompletedProcess[str]:
    """Run a transport command without exposing config or credential contents."""
    return subprocess.run(
        args,
        check=check,
        text=True,
        stdout=subprocess.PIPE if capture_output else None,
        stderr=subprocess.PIPE if capture_output else None,
    )


def resolve_remote(
    explicit: str | None,
    env: Mapping[str, str] | None = None,
    *,
    env_precedence: Sequence[str] = ("CUSTODIAN_REVIEW_REMOTE",),
    runner: Runner = run,
) -> str:
    """Resolve one configured Dropbox-like rclone remote.

    Callers specify their lane-specific environment precedence. Credentials are
    never read by this helper; ``rclone listremotes`` returns names only.
    """
    environ = os.environ if env is None else env
    remote = (explicit or "").strip()
    if not remote:
        remote = next(
            (environ[name].strip() for name in env_precedence if environ.get(name, "").strip()),
            "",
        )
    if remote:
        return remote if remote.endswith(":") else f"{remote}:"

    try:
        result = runner(["rclone", "listremotes"])
    except FileNotFoundError as exc:
        raise RuntimeError("rclone is not installed") from exc
    remotes = {line.strip() for line in result.stdout.splitlines() if line.strip()}
    if "dropbox:" in remotes:
        return "dropbox:"

    dropbox_named = sorted(name for name in remotes if "dropbox" in name.lower())
    if len(dropbox_named) == 1:
        return dropbox_named[0]
    if len(dropbox_named) > 1:
        raise RuntimeError(
            "multiple Dropbox-like rclone remotes are configured; pass --remote "
            "or set the lane's remote environment variable explicitly. "
            f"Candidates: {', '.join(dropbox_named)}"
        )

    listed = ", ".join(sorted(remotes)) or "(none)"
    raise RuntimeError(
        "no Dropbox rclone remote configured; pass --remote, configure a remote "
        "named dropbox:, or keep exactly one configured remote whose name "
        f"contains 'dropbox'. Configured remotes: {listed}"
    )


def remote_path(remote: str, remote_root: str, *parts: str) -> str:
    """Join a configured rclone remote with slash-delimited path components."""
    clean_root = remote_root.strip("/")
    clean_parts = [part.strip("/") for part in parts if part]
    suffix = "/".join([clean_root, *clean_parts]) if clean_root else "/".join(clean_parts)
    return f"{remote}{suffix}"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()
