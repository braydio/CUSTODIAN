#!/usr/bin/env python3
"""Turn-scoped CUSTODIAN task execution with durable Git handoffs."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import py_compile
import re
import shutil
import subprocess
import sys
import tempfile
import time
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


def git(repo: Path, *args: str, check: bool = True) -> str:
    proc = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True)
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


def has_design_hold(fields: dict[str, str]) -> bool:
    return any(fields.get(key, "").strip().lower() in OPEN_VALUES for key in DESIGN_HOLD_FIELDS)


def remote_branch(repo: Path, branch: str) -> str | None:
    result = git(repo, "ls-remote", "--heads", "origin", f"refs/heads/{branch}")
    rows = [line.split() for line in result.splitlines() if line.strip()]
    if len(rows) > 1:
        raise DispatchError(f"ambiguous remote branch: {branch}")
    return rows[0][0] if rows else None


def fetch_branch(repo: Path, branch: str, expected: str | None) -> str:
    git(repo, "fetch", "--no-tags", "origin", f"refs/heads/{branch}")
    fetched = git(repo, "rev-parse", "--verify", "FETCH_HEAD^{commit}")
    if expected and fetched != expected:
        raise DispatchError(f"{branch} changed during fetch")
    return fetched


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


def inspect(repo: Path, workstream: str, mode: str) -> dict:
    repo = repo_root(repo)
    validate_id(workstream)
    if mode not in {"normal", "historical"}:
        raise DispatchError(f"unknown acquisition mode: {mode}")
    main_sha, _ = latest_main(repo)
    packet_path, _, fields = remote_packet(repo, main_sha, workstream)
    if has_design_hold(fields):
        raise DispatchError("unresolved user-owned design decision holds task selection")
    branch = f"agent/{workstream}"
    return {"workstream": workstream, "mode": mode, "branch": branch,
            "packet": packet_path, "task_definition_sha": main_sha,
            "remote_head": remote_branch(repo, branch),
            "selection_policy": "v2-identity-and-user-design-hold-v1", "repo": str(repo)}


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
                       pool: Path) -> tuple[Path, str]:
    turn_id = uuid.uuid4().hex
    checkout = pool / f"turn-{workstream}-{turn_id[:12]}"
    if branch == f"agent/{workstream}":
        target_tag = "main"
    else:
        prefix = f"agent/{workstream}-recovery-"
        if not branch.startswith(prefix):
            raise DispatchError(f"unexpected target branch for {workstream}: {branch}")
        target_tag = "recovery-" + branch.removeprefix(prefix)
    local_branch = f"turn/{workstream}/{target_tag}/{turn_id}"
    pool.mkdir(parents=True, exist_ok=True)
    if checkout.exists():
        raise DispatchError(f"turn checkout path already exists: {checkout}")
    git(repo, "worktree", "add", "-b", local_branch, str(checkout), source_sha)
    return checkout, local_branch


def begin(repo: Path, workstream: str, mode: str, pool: Path) -> dict:
    info = inspect(repo, workstream, mode)
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

    checkout, local_branch = make_turn_checkout(repo, workstream, branch, source_sha, pool)
    try:
        lfs = hydrate_and_verify_lfs(checkout)
    except DispatchError as exc:
        receipt = write_receipt(repo, {"operation": "begin", "status": "blocked",
            "workstream": workstream, "mode": mode, "checkout": str(checkout),
            "branch": branch, "source": source, "source_sha": source_sha,
            "reason": f"required LFS data was not verified: {exc}"})
        raise DispatchError(f"LFS verification failed; checkout retained at {checkout}; receipt {receipt}") from exc
    result = {**info, "branch": branch, "source": source, "source_sha": source_sha,
            "checkout": str(checkout), "local_branch": local_branch,
            "turn_id": local_branch.rsplit("/", 1)[-1], "lfs_files": lfs,
            "rehydrated": bool(remote and source_sha == remote)}
    acquisition = {"schema": "custodian.turn_dispatcher_v2.acquisition.v1",
        "workstream": workstream, "mode": mode, "checkout": str(checkout),
        "local_branch": local_branch, "turn_id": result["turn_id"],
        "branch": branch, "source": source, "source_sha": source_sha,
        "task_definition_sha": info["task_definition_sha"]}
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


def read_acquisition(repo: Path, local_branch: str, checkout: Path) -> dict:
    turn_id = local_branch.rsplit("/", 1)[-1]
    path = acquisition_record_path(repo, turn_id)
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise DispatchError(f"missing or invalid acquisition provenance for {turn_id}") from exc
    if not isinstance(payload, dict) or payload.get("schema") != "custodian.turn_dispatcher_v2.acquisition.v1":
        raise DispatchError("unsupported acquisition provenance schema")
    if payload.get("local_branch") != local_branch or Path(payload.get("checkout", "")).resolve() != checkout:
        raise DispatchError("acquisition provenance does not identify this checkout")
    if git(checkout, "rev-parse", "HEAD") != payload.get("source_sha"):
        raise DispatchError("checkout base no longer matches its recorded acquisition source")
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
                         mode: str) -> str:
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
             f"Checkpoint base: {base_sha}", marker_end]
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
        with tempfile.TemporaryDirectory(prefix="custodian-pyc-verify-") as folder:
            regenerated = Path(folder) / path.name
            py_compile.compile(str(source), cfile=str(regenerated), doraise=True,
                               optimize=optimize)
            if regenerated.read_bytes() != data:
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


def checkpoint(repo: Path, workstream: str, checkout: Path, handoff: Path,
               message: str, pool: Path, retire: bool = True) -> dict:
    repo, checkout, pool = repo_root(repo), checkout.expanduser().resolve(), pool.expanduser().resolve()
    validate_id(workstream)
    if checkout.parent != pool or not checkout.name.startswith(f"turn-{workstream}-"):
        raise DispatchError("checkout is outside the managed turn pool")
    if checkout not in attached(repo):
        raise DispatchError("checkout is not attached to this Git common directory")
    local_branch = git(checkout, "symbolic-ref", "--short", "HEAD")
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
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.is_symlink() or not target.resolve().is_relative_to(checkout):
        raise DispatchError("handoff target escapes the exact turn checkout")
    if handoff.resolve() != target.resolve():
        shutil.copyfile(handoff, target)
    body = target.read_text(encoding="utf-8")
    main_sha, _ = latest_main(repo)
    packet_path, _, _ = remote_packet(repo, main_sha, workstream)
    base_sha = git(checkout, "rev-parse", "HEAD")
    body = add_handoff_metadata(body, workstream, packet_path, main_sha,
                                branch, base_sha, acquisition["source"],
                                acquisition["source_sha"], acquisition["mode"])
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

    if retire:
        git(repo, "worktree", "remove", str(checkout))
        if checkout.exists() or checkout in attached(repo):
            raise DispatchError("worktree retirement did not remove the exact registered checkout")
        git(repo, "update-ref", "-d", f"refs/heads/{local_branch}", sha)
    receipt = write_receipt(repo, {"operation": "checkpoint", "status": "published",
        "workstream": workstream, "checkout": str(checkout), "branch": branch,
        "head": sha, "handoff": str(rel), "ignored_disposable": disposable,
        "ignored_inventory": ignored_before,
        "retired": retire})
    return {"workstream": workstream, "branch": branch, "head": sha,
            "handoff": str(rel), "retired": retire, "receipt": receipt}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--pool", type=Path, default=Path.home() / "Projects/.custodian-turns")
    sub = parser.add_subparsers(dest="action", required=True)
    for action in ("inspect", "begin"):
        cmd = sub.add_parser(action)
        cmd.add_argument("workstream")
        cmd.add_argument("--mode", choices=("normal", "historical"), default="normal")
    cmd = sub.add_parser("checkpoint")
    cmd.add_argument("workstream")
    cmd.add_argument("--checkout", type=Path, required=True)
    cmd.add_argument("--handoff", type=Path, required=True)
    cmd.add_argument("--message", required=True)
    cmd.add_argument("--keep", action="store_true")
    args = parser.parse_args(argv)
    try:
        if args.action == "inspect":
            result = inspect(args.repo, args.workstream, args.mode)
        elif args.action == "begin":
            result = begin(args.repo, args.workstream, args.mode, args.pool)
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
