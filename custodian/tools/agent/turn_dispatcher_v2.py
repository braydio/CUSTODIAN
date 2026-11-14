#!/usr/bin/env python3
"""Turn-scoped CUSTODIAN task execution with durable Git handoffs."""
from __future__ import annotations

import argparse
import hashlib
import fcntl
import importlib.util
import json
import marshal
import os
import py_compile
import re
import shutil
import subprocess
import sys
import tempfile
import time
import types
import uuid
from pathlib import Path

ID = re.compile(r"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")
HEADER = re.compile(r"^- ([A-Za-z][A-Za-z /-]+):\s*(.*)$", re.M)
PACKETS = "custodian/docs/ai_context/task_packets"
HANDOFFS = Path("custodian/docs/ai_context/turn_handoffs")
DESIGN_HOLD_FIELDS = {"user design hold", "user-owned design decision"}
OPEN_VALUES = {"open", "true", "yes", "unresolved", "required", "pending"}


class DispatchError(RuntimeError):
    """An unsafe or incomplete turn operation; local work remains recoverable."""


def git(repo: Path, *args: str, check: bool = True, env: dict[str, str] | None = None) -> str:
    proc = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True, env=env)
    if check and proc.returncode:
        detail = proc.stderr.strip() or proc.stdout.strip()
        raise DispatchError(f"git {' '.join(args)} failed: {detail}")
    return proc.stdout.strip() if proc.returncode == 0 else ""


def validate_id(value: str) -> str:
    if not ID.fullmatch(value):
        raise DispatchError(f"invalid task identity: {value}")
    return value


def repo_root(repo: Path) -> Path:
    try:
        return Path(git(repo, "rev-parse", "--show-toplevel")).resolve()
    except (OSError, DispatchError) as exc:
        raise DispatchError(f"not a Git checkout: {repo}: {exc}") from exc


def parse_fields(content: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    started = False
    metadata = []
    for line in content.splitlines():
        if not line.strip():
            if started:
                break
            continue
        if line.startswith("# ") and not started:
            continue
        match = HEADER.match(line)
        if not match:
            if started:
                break
            continue
        started = True
        metadata.append(match.groups())
    for name, value in metadata:
        key = re.sub(r"\s+", " ", name.strip().lower())
        normalized = value.strip().strip("`")
        if key in {"workstream", *DESIGN_HOLD_FIELDS} and key in fields and fields[key] != normalized:
            raise DispatchError(f"task definition has conflicting {name} fields")
        fields[key] = normalized
    return fields


def latest_main(repo: Path) -> tuple[str, str]:
    """Fetch main to FETCH_HEAD and confirm it matches the advertised SHA."""
    for _ in range(2):
        advertised = git(repo, "ls-remote", "--heads", "origin", "refs/heads/main")
        rows = [line.split() for line in advertised.splitlines() if line.strip()]
        if len(rows) != 1 or len(rows[0]) < 2:
            raise DispatchError("origin/main is unavailable or ambiguous")
        expected = rows[0][0]
        git(repo, "fetch", "--no-tags", "origin", "refs/heads/main")
        fetched = git(repo, "rev-parse", "--verify", "FETCH_HEAD^{commit}")
        if fetched == expected:
            return fetched, expected
    raise DispatchError("origin/main changed during authentication; retry inspect")


def remote_packet(repo: Path, main_sha: str, workstream: str) -> tuple[str, str, dict[str, str]]:
    paths = git(repo, "ls-tree", "-r", "--name-only", main_sha, "--", PACKETS)
    matches: list[tuple[str, str, dict[str, str]]] = []
    for rel in paths.splitlines():
        if not rel.endswith(".md") or not rel.startswith(PACKETS + "/"):
            continue
        content = git(repo, "show", f"{main_sha}:{rel}")
        fields = parse_fields(content)
        if fields.get("workstream") == workstream:
            matches.append((rel, content, fields))
    active = [row for row in matches if "/archived/" not in row[0]]
    chosen = active if active else matches
    if len(chosen) != 1:
        reason = "missing" if not chosen else "ambiguous"
        raise DispatchError(f"{reason} authenticated task definition for {workstream} on origin/main")
    return chosen[0]


def remote_definition(repo: Path, main_sha: str, workstream: str) -> dict:
    """Resolve a task definition only from the authenticated main commit."""
    try:
        path, content, fields = remote_packet(repo, main_sha, workstream)
    except DispatchError as exc:
        if not str(exc).startswith("missing authenticated task definition"):
            raise
        return {"kind": "missing", "path": None, "content": None, "fields": {},
                "sha256": None, "error": str(exc)}
    return {"kind": "published-packet", "path": path, "content": content,
            "fields": fields, "sha256": hashlib.sha256(content.encode("utf-8")).hexdigest()}


def validate_owner_authorization(reference: str | None, digest: str | None) -> dict:
    """Record explicit caller authorization without treating a local file as authority.

    The caller must supply a conversation URL and the digest of the exact owner
    instruction. This is a provenance attestation, not an identity signature.
    """
    if not reference or not digest:
        raise DispatchError("owner-authorized acquisition requires an authorization URL and instruction SHA-256")
    from urllib.parse import urlsplit
    parsed = urlsplit(reference)
    if (parsed.scheme != "https"
            or (parsed.hostname or "").lower() not in {"chatgpt.com", "chat.openai.com"}
            or not re.search(r"/c/[A-Za-z0-9-]+/?$", parsed.path)):
        raise DispatchError("owner authorization must identify an exact ChatGPT conversation URL")
    if not re.fullmatch(r"[0-9a-f]{64}", digest):
        raise DispatchError("owner authorization instruction digest must be lowercase SHA-256")
    return {"type": "explicit-owner-instruction", "reference": reference,
            "instruction_sha256": digest, "identity_verified": False}


def has_design_hold(fields: dict[str, str]) -> bool:
    return any(fields.get(key, "").strip().lower() in OPEN_VALUES for key in DESIGN_HOLD_FIELDS)


def remote_branch(repo: Path, branch: str) -> str | None:
    result = git(repo, "ls-remote", "--heads", "origin", f"refs/heads/{branch}")
    rows = [line.split() for line in result.splitlines() if line.strip()]
    if len(rows) > 1:
        raise DispatchError(f"ambiguous remote branch: {branch}")
    return rows[0][0] if rows else None


def selection_cursor_path(repo: Path) -> Path:
    common = Path(git(repo, "rev-parse", "--git-common-dir"))
    if not common.is_absolute():
        common = (repo / common).resolve()
    return common / "custodian-turn-dispatcher-v2" / "selection-cursor.json"


def rotate_candidates(repo: Path, candidates: list[str]) -> list[str]:
    """Rotate active V2 candidates using optional, advisory local progress."""
    ordered = sorted(set(candidates))
    if not ordered:
        return []
    path = selection_cursor_path(repo)
    if path.is_symlink() or not path.is_file():
        return ordered
    try:
        state = json.loads(path.read_text(encoding="utf-8"))
        previous = state.get("last_workstream") if isinstance(state, dict) else None
    except (OSError, json.JSONDecodeError):
        return ordered
    if previous not in ordered:
        return ordered
    index = ordered.index(previous)
    return ordered[index + 1:] + ordered[:index + 1]


def record_selection(repo: Path, workstream: str, *, turn_id: str, main_sha: str) -> str | None:
    """Persist a best-effort cursor; it never gates explicit or resumed work."""
    path = selection_cursor_path(repo)
    try:
        path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        if path.is_symlink():
            return None
        payload = {"schema": "custodian.turn_dispatcher_v2.selection.v1",
                   "last_workstream": workstream, "turn_id": turn_id,
                   "main_sha": main_sha, "recorded_at": time.time()}
        temporary = path.with_name(path.name + f".{uuid.uuid4().hex}.tmp")
        try:
            with temporary.open("x", encoding="utf-8") as stream:
                stream.write(json.dumps(payload, sort_keys=True) + "\n")
            os.chmod(temporary, 0o600)
            os.replace(temporary, path)
        finally:
            if temporary.exists():
                temporary.unlink()
        return str(path)
    except OSError:
        return None


def task_progress_state(repo: Path, main_sha: str, workstream: str,
                        packet_path: str, fields: dict[str, str]) -> str:
    """Describe durable progress without turning it into an acquisition gate."""
    archived = "/archived/" in packet_path
    branch = f"agent/{workstream}"
    head = remote_branch(repo, branch)
    complete_declared = fields.get("status", "").lower().startswith("complete")
    if complete_declared and head:
        fetched = fetch_branch(repo, branch, head)
        if is_ancestor(repo, fetched, main_sha):
            return "completed"
    if archived:
        return "archived-unverified"
    return "resumable" if head else "new"


def fetch_branch(repo: Path, branch: str, expected: str | None) -> str:
    git(repo, "fetch", "--no-tags", "origin", f"refs/heads/{branch}")
    fetched = git(repo, "rev-parse", "--verify", "FETCH_HEAD^{commit}")
    if expected and fetched != expected:
        raise DispatchError(f"{branch} changed during fetch")
    return fetched


def is_ancestor(repo: Path, ancestor: str, descendant: str) -> bool:
    proc = subprocess.run(["git", "-C", str(repo), "merge-base", "--is-ancestor",
                          ancestor, descendant], capture_output=True, text=True)
    if proc.returncode not in {0, 1}:
        raise DispatchError(f"could not compare historical source with current main: {proc.stderr.strip()}")
    return proc.returncode == 0


def recovery_branch(workstream: str) -> str:
    return f"agent/{workstream}-recovery-fresh"


def ensure_fresh_branch(repo: Path, branch: str, main_sha: str) -> str:
    before = remote_branch(repo, branch)
    if before:
        return fetch_branch(repo, branch, before)
    git(repo, "push", "origin", f"{main_sha}:refs/heads/{branch}")
    after = remote_branch(repo, branch)
    if after != main_sha:
        raise DispatchError(f"fresh branch creation raced: {branch}")
    return main_sha


def retire_unmodified_turn(repo: Path, checkout: Path, local_branch: str, base_sha: str) -> None:
    if git(checkout, "status", "--porcelain", "--untracked-files=all"):
        raise DispatchError(f"fresh fallback checkout changed; preserving {checkout}")
    git(repo, "worktree", "remove", str(checkout))
    if checkout.exists() or checkout in attached(repo):
        raise DispatchError(f"could not retire exact fallback checkout {checkout}")
    git(repo, "update-ref", "-d", f"refs/heads/{local_branch}", base_sha)


def inspect(repo: Path, workstream: str, mode: str,
            authorization_url: str | None = None,
            authorization_sha256: str | None = None) -> dict:
    repo = repo_root(repo)
    validate_id(workstream)
    if mode not in {"normal", "historical", "owner-authorized"}:
        raise DispatchError(f"unknown acquisition mode: {mode}")
    main_sha, _ = latest_main(repo)
    definition = remote_definition(repo, main_sha, workstream)
    if definition["kind"] == "missing":
        if mode != "owner-authorized":
            raise DispatchError(definition["error"])
        authorization = validate_owner_authorization(authorization_url, authorization_sha256)
        packet_path, fields = None, {}
    else:
        packet_path, fields = definition["path"], definition["fields"]
        authorization = None
    if has_design_hold(fields):
        raise DispatchError("unresolved user-owned design decision holds task selection")
    branch = f"agent/{workstream}"
    return {"workstream": workstream, "mode": mode, "branch": branch,
            "packet": packet_path, "task_definition_sha": main_sha,
            "remote_head": remote_branch(repo, branch),
            "selection_policy": "v2-round-robin-progress-and-user-design-hold-v2", "repo": str(repo),
            "definition_kind": definition["kind"], "definition_sha256": definition["sha256"],
            "owner_authorization": authorization}


def attached(repo: Path) -> list[Path]:
    result: list[Path] = []
    for block in git(repo, "worktree", "list", "--porcelain").split("\n\n"):
        first = block.splitlines()
        if first and first[0].startswith("worktree "):
            result.append(Path(first[0].removeprefix("worktree ")).resolve())
    return result


def lfs_files(checkout: Path) -> list[str]:
    git(checkout, "lfs", "version")
    listing = git(checkout, "lfs", "ls-files", "--long")
    return [line.strip() for line in listing.splitlines() if line.strip()]


def hydrate_and_verify_lfs(checkout: Path) -> list[str]:
    files = lfs_files(checkout)
    if files:
        smudge = git(checkout, "config", "--get", "filter.lfs.smudge", check=False)
        process = git(checkout, "config", "--get", "filter.lfs.process", check=False)
        if not smudge and not process:
            raise DispatchError("Git LFS filters are not installed in this repository")
        git(checkout, "lfs", "fetch", "origin", "HEAD")
        git(checkout, "lfs", "checkout")
        git(checkout, "lfs", "fsck", "--objects")
    return files


def make_turn_checkout(repo: Path, workstream: str, branch: str, source_sha: str,
                       pool: Path, turn_id: str | None = None,
                       skip_lfs_smudge: bool = False) -> tuple[Path, str, str]:
    turn_id = turn_id or uuid.uuid4().hex
    checkout = pool / f"turn-{workstream}-{turn_id[:12]}"
    if branch == f"agent/{workstream}":
        local_branch = branch
    else:
        prefix = f"agent/{workstream}-recovery-"
        if not branch.startswith(prefix):
            raise DispatchError(f"unexpected target branch for {workstream}: {branch}")
        target_tag = "recovery-" + branch.removeprefix(prefix)
        local_branch = f"turn/{workstream}/{target_tag}/{turn_id}"
    pool.mkdir(parents=True, exist_ok=True)
    if checkout.exists():
        raise DispatchError(f"turn checkout path already exists: {checkout}")
    existing = git(repo, "rev-parse", "--verify", f"refs/heads/{local_branch}", check=False)
    if existing:
        if any(git(item, "symbolic-ref", "--short", "HEAD", check=False) == local_branch
               for item in attached(repo)):
            raise DispatchError(f"canonical branch {local_branch} is already attached; preserving existing checkout")
        if existing != source_sha:
            raise DispatchError(f"local {local_branch} differs from the authenticated source; preserve and reconcile it")
        git(repo, "worktree", "add", str(checkout), local_branch,
            env={**os.environ, **({"GIT_LFS_SKIP_SMUDGE": "1"} if skip_lfs_smudge else {})})
    else:
        git(repo, "worktree", "add", "-b", local_branch, str(checkout), source_sha,
            env={**os.environ, **({"GIT_LFS_SKIP_SMUDGE": "1"} if skip_lfs_smudge else {})})
    return checkout, local_branch, turn_id


def begin(repo: Path, workstream: str, mode: str, pool: Path,
          authorization_url: str | None = None,
          authorization_sha256: str | None = None,
          checkout_profile: str | None = None) -> dict:
    info = inspect(repo, workstream, mode, authorization_url, authorization_sha256)
    repo, pool = Path(info["repo"]), pool.expanduser().resolve()
    if pool == repo or pool in repo.parents:
        raise DispatchError("turn pool must be outside the repository")
    if pool in attached(repo):
        raise DispatchError("turn pool cannot be an attached repository worktree")

    branch, remote = info["branch"], info["remote_head"]
    canonical_branch = f"agent/{workstream}"
    fresh_branch = recovery_branch(workstream)
    if not remote:
        remote = remote_branch(repo, fresh_branch)
        if remote:
            branch = fresh_branch
    source_sha, source = None, "origin/main"
    if remote:
        try:
            source_sha = fetch_branch(repo, branch, remote)
            source = branch
        except DispatchError as exc:
            if mode != "historical" or branch == fresh_branch:
                raise DispatchError(f"advertised source branch could not be fetched safely: {exc}") from exc
            if remote_branch(repo, branch) is not None:
                raise DispatchError(f"historical branch changed or remains advertised; refusing fallback: {exc}") from exc
            source = f"origin/main (historical branch disappeared before fetch: {exc})"
            branch = fresh_branch
            remote = remote_branch(repo, branch)
            if remote:
                source_sha = fetch_branch(repo, branch, remote)
                source = f"{branch} (historical branch disappeared; existing fresh recovery branch)"
    else:
        source = "origin/main (no prior branch; fresh start)"

    if source_sha is None:
        source_sha = info["task_definition_sha"]
        if branch == fresh_branch or remote:
            branch = fresh_branch
            if mode == "historical":
                source = "origin/main (historical branch unavailable; fresh recovery branch)"
            else:
                source = "origin/main (no prior branch; fresh recovery branch)"
        source_sha = ensure_fresh_branch(repo, branch, source_sha)

    profile_receipt = None
    profile = None
    profile_inventory = None
    if checkout_profile is not None:
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        import worktree_provisioning
        try:
            profile = worktree_provisioning.load_profile(repo, info["task_definition_sha"], checkout_profile)
            if profile is None:
                raise worktree_provisioning.ProvisioningError("checkout profile was not loaded")
            capacity = worktree_provisioning.preflight_capacity(
                repo, profile_path=checkout_profile, ref=info["task_definition_sha"], target=pool,
            )
            if capacity.get("local_lfs_failures"):
                raise worktree_provisioning.ProvisioningError("required profile LFS objects are unavailable or corrupt")
            if not capacity.get("sufficient"):
                raise worktree_provisioning.ProvisioningError("insufficient storage for the profiled turn checkout")
            profile_inventory = worktree_provisioning.inventory(repo, info["task_definition_sha"], profile)
        except worktree_provisioning.ProvisioningError as exc:
            raise DispatchError(f"checkout profile preflight failed before turn acquisition: {exc}") from exc
    turn_id = uuid.uuid4().hex
    run_id = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime()) + "-" + turn_id[:12]
    checkout, local_branch, turn_id = make_turn_checkout(
        repo, workstream, branch, source_sha, pool, turn_id,
        skip_lfs_smudge=checkout_profile is not None,
    )
    try:
        if checkout_profile is None:
            lfs = hydrate_and_verify_lfs(checkout)
        else:
            import worktree_provisioning
            profile_inventory = worktree_provisioning.configure_sparse_checkout(
                checkout, repo, info["task_definition_sha"], profile,
            )
            lfs = [item.path for item in profile_inventory if item.path in profile.hydrate_lfs]
            profile_receipt = {
                "profile": profile.path, "profile_sha256": profile.digest,
                "paths": [item.path for item in profile_inventory],
                "hydrated_lfs_paths": list(profile.hydrate_lfs),
                "hydrated_lfs": [{"path": item.path, "oid": item.lfs_oid, "size": item.lfs_size}
                                  for item in profile_inventory if item.path in profile.hydrate_lfs],
            }
    except DispatchError as exc:
        receipt = write_receipt(repo, {"operation": "begin", "status": "blocked",
            "workstream": workstream, "mode": mode, "checkout": str(checkout),
            "branch": branch, "source": source, "source_sha": source_sha,
            "reason": f"required LFS data was not verified: {exc}"})
        raise DispatchError(f"LFS verification failed; checkout retained at {checkout}; receipt {receipt}") from exc
    result = {**info, "branch": branch, "source": source, "source_sha": source_sha,
            "checkout": str(checkout), "local_branch": local_branch,
            "turn_id": turn_id, "lfs_files": lfs,
            "run_id": run_id,
            "rehydrated": bool(remote and source_sha == remote),
            "checkout_profile": profile_receipt}
    acquisition = {"schema": "custodian.turn_dispatcher_v2.acquisition.v1",
        "workstream": workstream, "mode": mode, "checkout": str(checkout),
        "local_branch": local_branch, "turn_id": result["turn_id"],
        "run_id": run_id,
        "branch": branch, "source": source, "source_sha": source_sha,
        "packet": info["packet"],
        "task_definition_sha": info["task_definition_sha"],
        "definition_kind": info["definition_kind"],
        "definition_sha256": info["definition_sha256"],
        "source_is_ancestor_of_current_main": is_ancestor(repo, source_sha, info["task_definition_sha"]),
        "current_main_is_ancestor_of_source": is_ancestor(repo, info["task_definition_sha"], source_sha),
        "owner_authorization": info["owner_authorization"]}
    result["source_is_ancestor_of_current_main"] = acquisition["source_is_ancestor_of_current_main"]
    result["current_main_is_ancestor_of_source"] = acquisition["current_main_is_ancestor_of_source"]
    acquisition_path = acquisition_record_path(repo, result["turn_id"])
    try:
        acquisition_path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        if acquisition_path.is_symlink() or acquisition_path.exists():
            raise DispatchError("acquisition receipt path already exists or is a symlink")
        with acquisition_path.open("x", encoding="utf-8") as stream:
            stream.write(json.dumps(acquisition, indent=2, sort_keys=True) + "\n")
        os.chmod(acquisition_path, 0o600)
    except (OSError, DispatchError) as exc:
        receipt = write_receipt(repo, {"operation": "begin", "status": "blocked",
            "workstream": workstream, "mode": mode, "checkout": str(checkout),
            "local_branch": local_branch, "branch": branch, "source": source,
            "source_sha": source_sha, "reason": f"acquisition provenance was not persisted: {exc}"})
        raise DispatchError(f"acquisition provenance failed; checkout retained at {checkout}; receipt {receipt}") from exc
    result["acquisition_receipt"] = str(acquisition_path)
    return result


def write_receipt(repo: Path, payload: dict) -> str:
    common = Path(git(repo, "rev-parse", "--git-common-dir"))
    if not common.is_absolute():
        common = (repo / common).resolve()
    folder = common / "custodian-turn-dispatcher-v2" / "receipts"
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / f"{int(time.time())}-{uuid.uuid4().hex}.json"
    content = {"schema": "custodian.turn_dispatcher_v2.receipt.v1", **payload}
    path.write_text(json.dumps(content, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.chmod(path, 0o600)
    return str(path)


def acquisition_record_path(repo: Path, turn_id: str) -> Path:
    common = Path(git(repo, "rev-parse", "--git-common-dir"))
    if not common.is_absolute():
        common = (repo / common).resolve()
    return common / "custodian-turn-dispatcher-v2" / "acquisitions" / f"{turn_id}.json"



def continuation_root(repo: Path) -> Path:
    common = Path(git(repo, "rev-parse", "--git-common-dir"))
    common = common if common.is_absolute() else (repo / common)
    return common.resolve() / "custodian-turn-dispatcher-v2" / "continuations"


def continuation_record_path(repo: Path, continuation_id: str) -> Path:
    return continuation_root(repo) / f"{continuation_id}.json"


def _atomic_private_json(path: Path, payload: dict) -> None:
    if path.parent.is_symlink():
        raise DispatchError("continuation record directory is a symbolic link")
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    temporary = path.with_name(path.name + f".{uuid.uuid4().hex}.tmp")
    try:
        with temporary.open("x", encoding="utf-8") as stream:
            stream.write(json.dumps(payload, indent=2, sort_keys=True) + "\n")
        os.chmod(temporary, 0o600)
        os.link(temporary, path)
    except FileExistsError as exc:
        raise DispatchError(f"continuation record already exists: {path.name}") from exc
    finally:
        if temporary.exists():
            temporary.unlink()


def _dependency_only_change(original: str, current: str) -> bool:
    marker = re.compile(r"(?m)^(- Depends on: ).*$")
    if len(marker.findall(original)) != 1 or len(marker.findall(current)) != 1:
        return False
    return marker.sub(r"\1<dependency-metadata>", original, count=1) == marker.sub(
        r"\1<dependency-metadata>", current, count=1)


def _checkout_process_owners(checkout: Path, proc_root: Path = Path("/proc")) -> dict:
    """Identify matching owners; separate opaque unrelated services from uncertainty."""
    if not proc_root.is_dir():
        raise DispatchError("process ownership cannot be established: /proc is unavailable")
    target = checkout.resolve()
    owners, uncertain, unrelated_unreadable = [], [], []
    scanned = 0
    trusted_units = {"systemd", "sd-pam", "(sd-pam)", "ssh-agent"}
    for entry in proc_root.iterdir():
        if not entry.name.isdigit() or int(entry.name) == os.getpid():
            continue
        try:
            entry.stat()
            comm = (entry / "comm").read_text(encoding="utf-8", errors="replace").strip()
            cgroup = (entry / "cgroup").read_text(encoding="utf-8", errors="replace").strip()
            scanned += 1
            links = [entry / "cwd", entry / "root"]
            fd_dir = entry / "fd"
            denied = False
            if fd_dir.is_dir():
                try:
                    links.extend(fd_dir.iterdir())
                except PermissionError:
                    denied = True
            for link in links:
                try:
                    value = Path(os.readlink(link)).resolve()
                except (FileNotFoundError, ProcessLookupError):
                    continue
                except PermissionError:
                    denied = True
                    continue
                if value == target or target in value.parents:
                    owners.append({"pid": entry.name, "comm": comm, "cgroup": cgroup})
                    break
            else:
                if denied:
                    unit_match = any(unit in cgroup for unit in ("init.scope", "ssh-agent.service"))
                    if comm in trusted_units and unit_match:
                        unrelated_unreadable.append({"pid": entry.name, "comm": comm,
                            "cgroup": cgroup, "classification": "known-unrelated-service"})
                    else:
                        uncertain.append({"pid": entry.name, "comm": comm, "cgroup": cgroup})
        except (FileNotFoundError, ProcessLookupError):
            continue
        except PermissionError:
            uncertain.append({"pid": entry.name, "comm": "unreadable", "cgroup": "unreadable"})
    return {"owners": owners, "uncertain": uncertain,
            "unrelated_unreadable": unrelated_unreadable, "scanned_pids": scanned}


def _continuation_lock(repo: Path, turn_id: str):
    root = continuation_root(repo)
    folder = root / "locks"
    if root.is_symlink() or folder.is_symlink():
        raise DispatchError("continuation lock directory is a symbolic link")
    folder.mkdir(parents=True, exist_ok=True, mode=0o700)
    path = folder / f"{turn_id}.lock"
    if path.is_symlink():
        raise DispatchError("continuation lock file is a symbolic link")
    stream = path.open("a+")
    try:
        fcntl.flock(stream.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError as exc:
        stream.close()
        raise DispatchError("another V2 continuation/checkpoint operation owns this checkout") from exc
    return stream


def _continuations_for_checkout(repo: Path, workstream: str, checkout: Path) -> list[dict]:
    folder = continuation_root(repo)
    if folder.is_symlink():
        raise DispatchError("continuation record directory is a symbolic link")
    found = []
    if not folder.is_dir():
        return found
    for path in folder.glob("*.json"):
        if path.is_symlink() or not path.is_file():
            continue
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise DispatchError(f"continuation record is unreadable: {path.name}") from exc
        if (isinstance(payload, dict) and payload.get("workstream") == workstream
                and Path(payload.get("checkout", "")).resolve() == checkout.resolve()):
            found.append(payload)
    return found


def reauthorize_checkout(repo: Path, workstream: str, checkout: Path, pool: Path) -> dict:
    """Authenticate one dependency-metadata-only update on an attached V2 checkout."""
    repo, checkout, pool = repo_root(repo), checkout.expanduser().resolve(), pool.expanduser().resolve()
    validate_id(workstream)
    if checkout.parent != pool or not checkout.name.startswith(f"turn-{workstream}-"):
        raise DispatchError("checkout is outside the managed V2 turn pool")
    if checkout == repo or repo not in attached(repo) or checkout not in attached(repo):
        raise DispatchError("reauthorization requires the exact attached checkout and stable coordination repo")
    repo_common = Path(git(repo, "rev-parse", "--path-format=absolute", "--git-common-dir")).resolve()
    checkout_common = Path(git(checkout, "rev-parse", "--path-format=absolute", "--git-common-dir")).resolve()
    if repo_common != checkout_common:
        raise DispatchError("coordination repo and checkout do not share Git common directory")
    branch = git(checkout, "symbolic-ref", "--short", "HEAD")
    if branch != f"agent/{workstream}":
        raise DispatchError("reauthorization requires the exact canonical task branch")
    acquisition = read_acquisition(repo, branch, checkout)
    if acquisition.get("workstream") != workstream or acquisition.get("branch") != branch:
        raise DispatchError("original acquisition does not authenticate this task branch")
    lock = _continuation_lock(repo, acquisition["turn_id"])
    try:
        process_evidence = _checkout_process_owners(checkout)
        if process_evidence["owners"]:
            pids = ", ".join(item["pid"] for item in process_evidence["owners"])
            raise DispatchError(f"checkout has active process owner(s): {pids}")
        if process_evidence["uncertain"]:
            pids = ", ".join(item["pid"] for item in process_evidence["uncertain"])
            raise DispatchError(f"process ownership is uncertain for PID(s) {pids}; inspect these processes before continuing")
        if _continuations_for_checkout(repo, workstream, checkout):
            raise DispatchError("a continuation already exists for this checkout; refusing a conflicting successor")
        head = git(checkout, "rev-parse", "HEAD")
        if not is_ancestor(repo, acquisition.get("source_sha", ""), head):
            raise DispatchError("checkout HEAD no longer descends from authenticated acquisition source")
        remote = remote_branch(repo, branch)
        if not remote or not is_ancestor(repo, remote, head):
            raise DispatchError("remote task branch is missing or not preserved in checkout ancestry")
        before_status = git(checkout, "status", "--porcelain=v1", "--untracked-files=all")
        untracked = safe_untracked(checkout)
        assert_no_secret_content(checkout, untracked)
        ignored_before = ignored_inventory(checkout)
        if any(x["classification"] == "unresolved" for x in ignored_before):
            raise DispatchError("unclassified ignored data requires preservation before reauthorization")
        lfs = lfs_files(checkout)
        if lfs:
            git(checkout, "lfs", "fsck", "--objects")
        original_receipt_path = acquisition_record_path(repo, acquisition["turn_id"])
        original_receipt_sha = hashlib.sha256(original_receipt_path.read_bytes()).hexdigest()
        original_main = acquisition.get("task_definition_sha")
        main_sha, _ = latest_main(repo)
        if not original_main or not is_ancestor(repo, original_main, main_sha):
            raise DispatchError("original task definition commit is not in current main ancestry")
        packet_path = acquisition.get("packet")
        if not isinstance(packet_path, str) or not packet_path.startswith(PACKETS + "/"):
            raise DispatchError("original acquisition packet path is invalid")
        original_packet = git(repo, "show", f"{original_main}:{packet_path}")
        if hashlib.sha256(original_packet.encode("utf-8")).hexdigest() != acquisition.get("definition_sha256"):
            raise DispatchError("original packet bytes do not match immutable acquisition digest")
        definition = remote_definition(repo, main_sha, workstream)
        if definition.get("kind") != "published-packet" or definition.get("path") != packet_path:
            raise DispatchError("current authenticated packet identity/path changed")
        if definition.get("sha256") == acquisition.get("definition_sha256"):
            raise DispatchError("packet definition is unchanged; no continuation is needed")
        if not _dependency_only_change(original_packet, definition["content"]):
            raise DispatchError("packet change is outside the explicitly permitted dependency-metadata field")
        if has_design_hold(definition["fields"]):
            raise DispatchError("current packet contains an unresolved user-owned design hold")
        if (git(checkout, "status", "--porcelain=v1", "--untracked-files=all") != before_status
                or ignored_inventory(checkout) != ignored_before):
            raise DispatchError("checkout changed while reauthorization evidence was collected")
        continuation_id = uuid.uuid4().hex
        record = {"schema": "custodian.turn_dispatcher_v2.continuation.v1", "status": "active",
            "continuation_id": continuation_id, "workstream": workstream, "checkout": str(checkout),
            "local_branch": branch, "branch": branch, "head": head,
            "source": acquisition["source"], "source_sha": acquisition["source_sha"],
            "original_turn_id": acquisition["turn_id"], "original_acquisition_sha256": original_receipt_sha,
            "original_packet": packet_path, "original_packet_sha256": acquisition["definition_sha256"],
            "original_task_definition_sha": original_main, "current_packet_sha256": definition["sha256"],
            "current_task_definition_sha": main_sha, "remote_head": remote, "untracked": untracked,
            "ignored_inventory": ignored_before, "lfs_files": lfs,
            "process_ownership": process_evidence, "created_at_unix": int(time.time())}
        record_path = continuation_record_path(repo, continuation_id)
        _atomic_private_json(record_path, record)
        return {"continuation_id": continuation_id, "continuation_record": str(record_path),
            "workstream": workstream, "checkout": str(checkout), "branch": branch, "head": head,
            "original_packet_sha256": acquisition["definition_sha256"],
            "current_packet_sha256": definition["sha256"], "retired": False}
    finally:
        lock.close()


def read_continuation(repo: Path, acquisition: dict, checkout: Path, definition: dict, main_sha: str) -> dict | None:
    matches = _continuations_for_checkout(repo, acquisition["workstream"], checkout)
    if not matches:
        return None
    if len(matches) != 1:
        raise DispatchError("multiple continuation records identify this checkout")
    record = matches[0]
    original_path = acquisition_record_path(repo, acquisition["turn_id"])
    if (record.get("schema") != "custodian.turn_dispatcher_v2.continuation.v1"
            or record.get("status") != "active"
            or record.get("original_turn_id") != acquisition.get("turn_id")
            or record.get("original_acquisition_sha256") != hashlib.sha256(original_path.read_bytes()).hexdigest()
            or record.get("checkout") != str(checkout)
            or record.get("local_branch") != acquisition.get("local_branch")
            or record.get("branch") != acquisition.get("branch")
            or record.get("source_sha") != acquisition.get("source_sha")
            or record.get("original_packet_sha256") != acquisition.get("definition_sha256")
            or record.get("current_packet_sha256") != definition.get("sha256")
            or record.get("head") != git(checkout, "rev-parse", "HEAD")):
        raise DispatchError("successor continuation does not authenticate the current checkout and packet")
    if not is_ancestor(repo, record.get("source_sha", ""), record.get("head", "")):
        raise DispatchError("successor continuation source ancestry is invalid")
    if not is_ancestor(repo, record.get("current_task_definition_sha", ""), main_sha):
        raise DispatchError("successor task definition is not in current main ancestry")
    return record

def retirement_record_path(repo: Path, turn_id: str) -> Path:
    common = Path(git(repo, "rev-parse", "--git-common-dir"))
    if not common.is_absolute():
        common = (repo / common).resolve()
    return common / "custodian-turn-dispatcher-v2" / "retirements" / f"{turn_id}.json"


def write_retirement_record(repo: Path, turn_id: str, payload: dict) -> Path:
    path = retirement_record_path(repo, turn_id)
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    if path.is_symlink():
        raise DispatchError("retirement receipt path is a symbolic link")
    temporary = path.with_name(path.name + f".{uuid.uuid4().hex}.tmp")
    try:
        with temporary.open("x", encoding="utf-8") as stream:
            stream.write(json.dumps(payload, indent=2, sort_keys=True) + "\n")
        os.chmod(temporary, 0o600)
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()
    return path


def prior_acquisition_for_checkout(repo: Path, checkout: Path, workstream: str) -> dict | None:
    folder = acquisition_record_path(repo, "placeholder").parent
    if not folder.is_dir() or folder.is_symlink():
        return None
    matches = []
    for path in folder.glob("*.json"):
        if path.is_symlink() or not path.is_file():
            continue
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if (isinstance(payload, dict) and payload.get("workstream") == workstream
                and Path(payload.get("checkout", "")).resolve() == checkout):
            matches.append(payload)
    if len(matches) > 1:
        raise DispatchError("multiple acquisition receipts identify the retired checkout")
    return matches[0] if matches else None


def completed_retirement(repo: Path, checkout: Path, workstream: str) -> dict | None:
    acquisition = prior_acquisition_for_checkout(repo, checkout, workstream)
    if not acquisition:
        return None
    turn_id = acquisition.get("turn_id")
    if not isinstance(turn_id, str) or not re.fullmatch(r"[0-9a-f]{32}", turn_id):
        return None
    path = retirement_record_path(repo, turn_id)
    if path.is_symlink() or not path.is_file():
        return None
    try:
        receipt = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise DispatchError("retirement receipt is invalid; refusing to infer completion") from exc
    if (not isinstance(receipt, dict) or receipt.get("schema") != "custodian.turn_dispatcher_v2.retirement.v1"
            or receipt.get("turn_id") != turn_id or receipt.get("checkout") != str(checkout)
            or receipt.get("workstream") != workstream or receipt.get("status") not in {"remote-verified", "retired"}):
        raise DispatchError("retirement receipt does not authenticate this exact checkout")
    advertised = remote_branch(repo, receipt.get("branch", ""))
    if advertised != receipt.get("head"):
        raise DispatchError("retirement receipt remote head changed; preserving uncertainty")
    local_ref = f"refs/heads/{receipt.get('local_branch', '')}"
    local_head = git(repo, "rev-parse", "--verify", local_ref, check=False)
    if local_head and local_head != receipt.get("head"):
        raise DispatchError("temporary branch changed after retirement receipt; preserving uncertainty")
    if local_head:
        git(repo, "update-ref", "-d", local_ref, local_head)
    receipt["status"] = "retired"
    write_retirement_record(repo, turn_id, receipt)
    return {"workstream": workstream, "branch": receipt["branch"], "head": receipt["head"],
            "handoff": receipt["handoff"], "retired": True, "receipt": str(path),
            "idempotent": True}


def read_acquisition(repo: Path, local_branch: str, checkout: Path) -> dict:
    folder = acquisition_record_path(repo, "placeholder").parent
    matches = []
    for path in folder.glob("*.json") if folder.is_dir() and not folder.is_symlink() else []:
        if path.is_symlink() or not path.is_file():
            continue
        try:
            candidate = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if (isinstance(candidate, dict) and candidate.get("local_branch") == local_branch
                and Path(candidate.get("checkout", "")).resolve() == checkout):
            matches.append(candidate)
    if len(matches) != 1:
        raise DispatchError("missing or ambiguous acquisition provenance for this checkout")
    payload = matches[0]
    if not isinstance(payload, dict) or payload.get("schema") != "custodian.turn_dispatcher_v2.acquisition.v1":
        raise DispatchError("unsupported acquisition provenance schema")
    if payload.get("local_branch") != local_branch or Path(payload.get("checkout", "")).resolve() != checkout:
        raise DispatchError("acquisition provenance does not identify this checkout")
    if not is_ancestor(repo, str(payload.get("source_sha", "")), git(checkout, "rev-parse", "HEAD")):
        raise DispatchError("checkout no longer descends from its recorded acquisition source")
    return payload


def safe_untracked(checkout: Path) -> list[str]:
    raw = subprocess.run(["git", "-C", str(checkout), "ls-files", "--others",
                          "--exclude-standard", "-z"], capture_output=True, check=True).stdout
    paths = [os.fsdecode(part) for part in raw.split(b"\0") if part]
    secret = re.compile(r"(^|/)(\.env($|\.)|id_(rsa|ed25519)|.*\.(pem|key|p12|pfx)$)", re.I)
    unsafe = [path for path in paths if secret.search(path)]
    if unsafe:
        raise DispatchError(f"potential secrets need explicit handling: {unsafe[:10]}")
    nested = [path for path in paths if (checkout / path / ".git").exists()]
    if nested:
        raise DispatchError(f"nested repositories need explicit handling: {nested[:10]}")
    return paths


def assert_no_secret_content(checkout: Path, untracked: list[str]) -> None:
    modified = git(checkout, "diff", "--name-only", "-z").split("\0")
    staged = git(checkout, "diff", "--cached", "--name-only", "-z").split("\0")
    candidates = sorted({path for path in [*modified, *staged, *untracked] if path})
    secret_path = re.compile(r"(^|/)(\.env($|\.)|id_(rsa|ed25519)|.*\.(pem|key|p12|pfx)$)", re.I)
    signatures = (
        re.compile(rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
        re.compile(rb"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16})\b"),
        re.compile(rb"(?i)\b(?:password|passwd|secret|api[_-]?key|access[_-]?token)\s*[:=]\s*[\"']?[A-Za-z0-9_./+=:-]{20,}"),
    )
    for rel in candidates:
        if secret_path.search(rel):
            raise DispatchError(f"potential secret path needs explicit handling: {rel}")
        path = checkout / rel
        if path.is_symlink() or not path.is_file():
            continue
        with path.open("rb") as stream:
            carry = b""
            while chunk := stream.read(64 * 1024):
                sample = carry + chunk
                if any(signature.search(sample) for signature in signatures):
                    raise DispatchError(f"secret-like content needs explicit handling: {rel}")
                carry = sample[-256:]


def add_handoff_metadata(body: str, workstream: str,
                         packet: str, main_sha: str, branch: str,
                         base_sha: str, source: str, source_sha: str,
                         mode: str, continuation: dict | None = None) -> str:
    required = ("Original goal:", "Implemented:", "Remaining:", "Validation:",
                "Resume:", "Sources/evidence:")
    for label in required:
        if label not in body:
            raise DispatchError(f"handoff missing required field: {label}")
    marker_start, marker_end = "<!-- V2 turn metadata -->", "<!-- /V2 turn metadata -->"
    lines = [marker_start, f"Task identity: {workstream}",
             f"Task definition: {packet} at origin/main {main_sha}",
             f"Remote branch: {branch}", f"Acquisition mode: {mode}",
             f"Acquisition source: {source}", f"Acquisition source commit: {source_sha}",
             f"Checkpoint base: {base_sha}"]
    if continuation:
        lines.extend([f"Continuation identity: {continuation['continuation_id']}",
                      f"Original packet SHA-256: {continuation['original_packet_sha256']}",
                      f"Current packet SHA-256: {continuation['current_packet_sha256']}"])
    lines.append(marker_end)
    block = "\n".join(lines)
    if marker_start in body and marker_end in body:
        before = body.split(marker_start, 1)[0]
        after = body.split(marker_end, 1)[1].lstrip("\n")
        return f"{before}{block}\n\n{after}"
    return f"{block}\n\n{body.lstrip()}"


def ignored_paths(checkout: Path) -> list[str]:
    raw = subprocess.run(["git", "-C", str(checkout), "ls-files", "--others", "--ignored",
                          "--exclude-standard", "--directory", "-z"],
                         capture_output=True, check=True).stdout
    found: set[str] = set()
    for part in raw.split(b"\0"):
        if not part:
            continue
        rel = os.fsdecode(part).rstrip("/")
        path = checkout / rel
        if path.is_dir() and not path.is_symlink():
            for root, dirs, files in os.walk(path, followlinks=False):
                root_path = Path(root)
                dirs[:] = [d for d in dirs if not (root_path / d).is_symlink()]
                for name in [*files, *(d for d in os.listdir(root) if (root_path / d).is_symlink())]:
                    candidate = root_path / name
                    found.add(candidate.relative_to(checkout).as_posix())
        else:
            found.add(rel)
    return sorted(found)


def _verified_python_cache(checkout: Path, rel: str) -> bool:
    path = checkout / rel
    if path.is_symlink() or not path.is_file() or path.suffix != ".pyc":
        return False
    if "__pycache__" not in Path(rel).parts:
        return False
    source = path.parent.parent / (path.name.split(".", 1)[0] + ".py")
    if not source.is_file() or source.is_symlink():
        return False
    tracked = subprocess.run(["git", "-C", str(checkout), "ls-files", "--error-unmatch",
                              str(source.relative_to(checkout))], capture_output=True).returncode == 0
    if not tracked:
        return False
    try:
        optimize = 1 if ".opt-1." in path.name else 2 if ".opt-2." in path.name else 0
        optimization = str(optimize) if optimize else ""
        expected = Path(importlib.util.cache_from_source(str(source), optimization=optimization))
        if expected != path:
            return False
        data = path.read_bytes()
        if len(data) <= 16 or data[:4] != importlib.util.MAGIC_NUMBER:
            return False
        code = marshal.loads(data[16:])
        if not isinstance(code, types.CodeType):
            return False
        with tempfile.TemporaryDirectory(prefix="custodian-pyc-verify-") as folder:
            regenerated = Path(folder) / path.name
            py_compile.compile(str(source), cfile=str(regenerated), doraise=True,
                               dfile=code.co_filename, optimize=optimize)
            regenerated_data = regenerated.read_bytes()
            if (len(regenerated_data) <= 16
                    or regenerated_data[:4] != importlib.util.MAGIC_NUMBER):
                return False
            regenerated_code = marshal.loads(regenerated_data[16:])
            # Python's marshal reference-sharing encoding may vary between
            # equivalent compilations. Compare the decoded code object, not
            # incidental serialization bytes, to prove the cache matches its
            # tracked source.
            if not isinstance(regenerated_code, types.CodeType) or regenerated_code != code:
                return False
    except (OSError, py_compile.PyCompileError, ValueError):
        return False
    return True


def classify_ignored(checkout: Path) -> tuple[list[str], list[str]]:
    disposable, unresolved = [], []
    for rel in ignored_paths(checkout):
        (disposable if _verified_python_cache(checkout, rel) else unresolved).append(rel)
    return disposable, unresolved


def ignored_inventory(checkout: Path) -> list[dict]:
    disposable, _ = classify_ignored(checkout)
    disposable_set = set(disposable)
    entries = []
    for rel in ignored_paths(checkout):
        path = checkout / rel
        info = path.lstat()
        entry = {"path": rel, "mode": info.st_mode & 0o777,
                 "classification": "reproducible-cache" if rel in disposable_set else "unresolved"}
        if path.is_symlink():
            target = os.readlink(path)
            entry.update({"type": "symlink", "target": target,
                          "sha256": hashlib.sha256(os.fsencode(target)).hexdigest()})
        elif path.is_file():
            digest = hashlib.sha256()
            size = 0
            with path.open("rb") as stream:
                while chunk := stream.read(1024 * 1024):
                    digest.update(chunk)
                    size += len(chunk)
            entry.update({"type": "file", "sha256": digest.hexdigest(), "size": size})
        else:
            entry["type"] = "unsupported"
        entries.append(entry)
    return entries


def _checkpoint_locked(repo: Path, workstream: str, checkout: Path, handoff: Path,
                       message: str, pool: Path, retire: bool = True) -> dict:
    repo, checkout, pool = repo_root(repo), checkout.expanduser().resolve(), pool.expanduser().resolve()
    validate_id(workstream)
    if checkout.parent != pool or not checkout.name.startswith(f"turn-{workstream}-"):
        raise DispatchError("checkout is outside the managed turn pool")
    if repo == checkout:
        raise DispatchError("checkpoint --repo must be a stable coordination checkout, not the turn being retired")
    if repo not in attached(repo):
        raise DispatchError("checkpoint --repo must be an attached coordination checkout")
    if checkout not in attached(repo):
        if not checkout.exists():
            completed = completed_retirement(repo, checkout, workstream)
            if completed:
                return completed
        try:
            repo_common = Path(git(repo, "rev-parse", "--path-format=absolute", "--git-common-dir")).resolve()
            checkout_common = Path(git(checkout, "rev-parse", "--path-format=absolute", "--git-common-dir")).resolve()
        except DispatchError as exc:
            raise DispatchError("checkout is not attached to this Git common directory") from exc
        if repo_common != checkout_common:
            raise DispatchError("checkpoint --repo and turn checkout do not share the same Git common directory")
        raise DispatchError("checkout is not attached to this Git common directory")
    try:
        repo_common = Path(git(repo, "rev-parse", "--path-format=absolute", "--git-common-dir")).resolve()
        checkout_common = Path(git(checkout, "rev-parse", "--path-format=absolute", "--git-common-dir")).resolve()
    except DispatchError as exc:
        raise DispatchError("checkpoint requires an attached coordination checkout sharing the turn's Git common directory") from exc
    if repo_common != checkout_common:
        raise DispatchError("checkpoint --repo and turn checkout do not share the same Git common directory")
    local_branch = git(checkout, "symbolic-ref", "--short", "HEAD")
    if local_branch == f"agent/{workstream}":
        branch = local_branch
    else:
        parts = local_branch.split("/")
        if len(parts) != 4 or parts[0:2] != ["turn", workstream]:
            raise DispatchError("unexpected temporary turn branch")
        target_tag = parts[2]
        if target_tag == "main":
            branch = f"agent/{workstream}"
        elif target_tag.startswith("recovery-") and len(target_tag) > len("recovery-"):
            branch = f"agent/{workstream}-recovery-{target_tag.removeprefix('recovery-')}"
        else:
            raise DispatchError("turn branch has an invalid remote target")
    acquisition = read_acquisition(repo, local_branch, checkout)
    if acquisition.get("workstream") != workstream or acquisition.get("branch") != branch:
        raise DispatchError("acquisition provenance does not match checkpoint task and target branch")
    if not handoff.is_file() or handoff.is_symlink():
        raise DispatchError("handoff must be a regular file")
    rel, target = HANDOFFS / f"{workstream}.md", checkout / HANDOFFS / f"{workstream}.md"
    parent = checkout
    for part in HANDOFFS.parts:
        parent = parent / part
        if parent.is_symlink():
            raise DispatchError("handoff directory contains a symbolic link")
    if target.is_symlink() or not target.resolve().is_relative_to(checkout):
        raise DispatchError("handoff target escapes the exact turn checkout")
    main_sha, _ = latest_main(repo)
    definition = remote_definition(repo, main_sha, workstream)
    continuation = None
    if definition["kind"] == "missing":
        if acquisition.get("mode") != "owner-authorized" or not acquisition.get("owner_authorization"):
            raise DispatchError("authenticated task definition disappeared before checkpoint")
        auth = acquisition["owner_authorization"]
        packet_path = f"owner-authorized:{auth['reference']}#sha256={auth['instruction_sha256']}"
    else:
        if acquisition.get("definition_kind") == "missing":
            raise DispatchError("a published task definition appeared after owner-authorized acquisition; re-acquire before checkpoint")
        packet_path = definition["path"]
        continuation = read_continuation(repo, acquisition, checkout, definition, main_sha)
        if (acquisition.get("definition_kind") == "published-packet"
                and definition["sha256"] != acquisition.get("definition_sha256")
                and continuation is None):
            raise DispatchError("published task definition changed after acquisition; explicit same-checkout reauthorization required")
    target.parent.mkdir(parents=True, exist_ok=True)
    if handoff.resolve() != target.resolve():
        shutil.copyfile(handoff, target)
    body = target.read_text(encoding="utf-8")
    base_sha = git(checkout, "rev-parse", "HEAD")
    body = add_handoff_metadata(body, workstream, packet_path, main_sha,
                                branch, base_sha, acquisition["source"],
                                acquisition["source_sha"], acquisition["mode"], continuation)
    target.write_text(body, encoding="utf-8")
    try:
        untracked = safe_untracked(checkout)
        assert_no_secret_content(checkout, untracked)
        ignored_before = ignored_inventory(checkout)
        disposable = [item["path"] for item in ignored_before
                      if item["classification"] == "reproducible-cache"]
        unresolved = [item["path"] for item in ignored_before
                      if item["classification"] == "unresolved"]
    except (DispatchError, subprocess.CalledProcessError) as exc:
        receipt = write_receipt(repo, {"operation": "checkpoint", "status": "blocked",
            "workstream": workstream, "checkout": str(checkout), "branch": branch,
            "local_branch": local_branch, "head": git(checkout, "rev-parse", "HEAD"),
            "reason": str(exc)})
        raise DispatchError(f"checkpoint blocked; checkout retained; receipt {receipt}: {exc}") from exc
    if unresolved:
        receipt = write_receipt(repo, {"operation": "checkpoint", "status": "blocked",
            "workstream": workstream, "checkout": str(checkout), "branch": branch,
            "local_branch": local_branch, "head": git(checkout, "rev-parse", "HEAD"),
            "ignored_unresolved": unresolved, "ignored_disposable": disposable,
            "ignored_inventory": ignored_before,
            "reason": "ignored non-cache data requires preservation classification"})
        raise DispatchError(f"unclassified ignored data; checkout retained; receipt {receipt}")

    git(checkout, "add", "-u")
    for path in untracked:
        git(checkout, "add", "--", path)
    git(checkout, "add", "--", str(rel))
    if not git(checkout, "diff", "--cached", "--name-only"):
        raise DispatchError("checkpoint has no handoff or implementation changes to commit")
    git(checkout, "commit", "-m", f"{message} [skip render]")
    sha = git(checkout, "rev-parse", "HEAD")
    try:
        hydrate_and_verify_lfs(checkout)
        git(checkout, "lfs", "push", "origin", "HEAD")
        git(checkout, "push", "origin", f"HEAD:refs/heads/{branch}")
        advertised = remote_branch(repo, branch)
        if advertised != sha:
            raise DispatchError(f"remote SHA mismatch (expected {sha}, found {advertised})")
        if ignored_inventory(checkout) != ignored_before:
            raise DispatchError("ignored file identity changed after preservation classification")
        if git(checkout, "status", "--porcelain", "--untracked-files=all"):
            raise DispatchError("checkout changed after commit/push")
    except DispatchError as exc:
        receipt = write_receipt(repo, {"operation": "checkpoint", "status": "blocked",
            "workstream": workstream, "checkout": str(checkout), "branch": branch,
            "local_branch": local_branch, "head": sha, "ignored_disposable": disposable,
            "ignored_inventory": ignored_before, "untracked": untracked,
            "reason": str(exc)})
        raise DispatchError(f"checkpoint not verified; checkout retained at {checkout}; receipt {receipt}: {exc}") from exc

    retirement_path = None
    if retire:
        turn_id = acquisition["turn_id"]
        retirement = {"schema": "custodian.turn_dispatcher_v2.retirement.v1",
            "status": "remote-verified", "turn_id": turn_id,
            "workstream": workstream, "checkout": str(checkout),
            "local_branch": local_branch, "branch": branch, "head": sha,
            "handoff": str(rel), "ignored_inventory": ignored_before,
            "continuation_id": continuation.get("continuation_id") if continuation else None}
        retirement_path = write_retirement_record(repo, turn_id, retirement)
        git(repo, "worktree", "remove", str(checkout))
        if checkout.exists() or checkout in attached(repo):
            raise DispatchError("worktree retirement did not remove the exact registered checkout")
        git(repo, "update-ref", "-d", f"refs/heads/{local_branch}", sha)
        retirement["status"] = "retired"
        retirement_path = write_retirement_record(repo, turn_id, retirement)
    receipt = write_receipt(repo, {"operation": "checkpoint", "status": "published",
        "workstream": workstream, "checkout": str(checkout), "branch": branch,
        "head": sha, "handoff": str(rel), "ignored_disposable": disposable,
        "ignored_inventory": ignored_before,
        "continuation_id": continuation.get("continuation_id") if continuation else None,
        "retired": retire})
    return {"workstream": workstream, "branch": branch, "head": sha,
            "handoff": str(rel), "retired": retire, "receipt": receipt,
            "retirement_receipt": str(retirement_path) if retirement_path else None,
            "continuation_id": continuation.get("continuation_id") if continuation else None}



def checkpoint(repo: Path, workstream: str, checkout: Path, handoff: Path,
               message: str, pool: Path, retire: bool = True) -> dict:
    repo, checkout = repo_root(repo), checkout.expanduser().resolve()
    if checkout in attached(repo):
        branch = git(checkout, "symbolic-ref", "--short", "HEAD")
        acquisition = read_acquisition(repo, branch, checkout)
        lock = _continuation_lock(repo, acquisition["turn_id"])
        try:
            return _checkpoint_locked(repo, workstream, checkout, handoff, message, pool, retire)
        finally:
            lock.close()
    return _checkpoint_locked(repo, workstream, checkout, handoff, message, pool, retire)

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--pool", type=Path, default=Path.home() / "Projects/.custodian-turns")
    sub = parser.add_subparsers(dest="action", required=True)
    for action in ("inspect", "begin"):
        cmd = sub.add_parser(action)
        cmd.add_argument("workstream")
        cmd.add_argument("--mode", choices=("normal", "historical", "owner-authorized"), default="normal")
        cmd.add_argument("--authorization-url")
        cmd.add_argument("--authorization-sha256")
    cmd = sub.add_parser("reauthorize")
    cmd.add_argument("workstream")
    cmd.add_argument("--checkout", type=Path, required=True)
    cmd.add_argument("--pool", type=Path, default=Path.home() / "Projects/.custodian-turns")
    cmd = sub.add_parser("checkpoint")
    cmd.add_argument("workstream")
    cmd.add_argument("--checkout", type=Path, required=True)
    cmd.add_argument("--handoff", type=Path, required=True)
    cmd.add_argument("--message", required=True)
    cmd.add_argument("--keep", action="store_true")
    args = parser.parse_args(argv)
    try:
        if args.action == "inspect":
            result = inspect(args.repo, args.workstream, args.mode,
                             args.authorization_url, args.authorization_sha256)
        elif args.action == "begin":
            result = begin(args.repo, args.workstream, args.mode, args.pool,
                           args.authorization_url, args.authorization_sha256)
        elif args.action == "reauthorize":
            result = reauthorize_checkout(args.repo, args.workstream, args.checkout, args.pool)
        else:
            result = checkpoint(args.repo, args.workstream, args.checkout,
                                args.handoff, args.message, args.pool, not args.keep)
        print(json.dumps(result, indent=2, sort_keys=True))
        return 0
    except (DispatchError, subprocess.CalledProcessError) as exc:
        print(json.dumps({"schema": "custodian.turn_dispatcher_v2.receipt.v1",
                          "status": "blocked", "error": str(exc)}, indent=2, sort_keys=True),
              file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
