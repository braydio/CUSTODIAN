"""Exact-run recovery for the stranded finish-index reviewer PASS.

This module intentionally recognizes one immutable host run. It is not a
general ``codex_exited`` recovery path. Planning is read-only; apply requires
the exact plan digest and completes through the original review workstream.
"""
from __future__ import annotations

import fcntl
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import paired_review_runner as runner
import review_outcome
from review_receipt_delta import render_review_receipt, verify_review_receipt_delta


WORKSTREAM = "review-workstream-finish-index-conflict-recovery-v1"
TARGET = "workstream-finish-index-conflict-recovery-v1"
RUN_ID = "20261027T113425Z-50d9c7adf7a0"
CLAIM_RUN_ID = "20261027T113443Z-6f08c7ced9a2"
REVIEWED_MAIN = "c233fefa94f887bcc87989e2740c493ab84c2920"
IMPLEMENTATION = "4116c5009752599506e1c4cd95c24995b63503cb"
RUN_MANIFEST = {
    "claim-receipt.json": "04f488c78d142861aa6606dd7f9e48b796b52b4669a5044ea5fc8469871e66bb",
    "claim.stderr": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "claim.stdout": "50f06aa42c500051d4fada429f7682af11726e3aad3f196ace791abdb9c16258",
    "codex.jsonl": "97814c76ce9b56d8bd506e865a9a767b66dbf906dc00850c1afd840db480d1e0",
    "codex.stderr": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "coordinator-validation.json": "dd20a24b49c68d8ac136b784cc6b76d6e0ad77ec08ece53b3358ee14d97d0ec0",
    "last-message.txt": "183ee8b5d9917c6859e35604a4f7aa611085c6c0b0fbc9675fdaba2f4710530b",
    "metadata.json": "03c413ed1634a8c938e0043d4cbb7a78c9e8fbaa8a5cdff351ce3fd29220c4c8",
    "validation.json": "e6d94ebbca87e36b832c1cc93a41754eccfe2eb94950f5c1918f9bc5de67a244",
}
ACTIVE = "custodian/docs/ai_context/task_packets/REVIEW_WORKSTREAM_FINISH_INDEX_CONFLICT_RECOVERY_V1.md"
ARCHIVED = "custodian/docs/ai_context/task_packets/archived/REVIEW_WORKSTREAM_FINISH_INDEX_CONFLICT_RECOVERY_V1.md"
TARGET_PACKET = "custodian/docs/ai_context/task_packets/archived/WORKSTREAM_FINISH_INDEX_CONFLICT_RECOVERY_V1.md"
SUMMARY = "REVIEW_WORKSTREAM_FINISH_INDEX_CONFLICT_RECOVERY_V1_CLAUDE_SUMMARY.md"
REVIEWER_ARTIFACTS = {
    ACTIVE: "1a27db29572ff44482f4e5305dd215fe373f742dcaf1b5313c3b5c074634240b",
    SUMMARY: "c8cd70b01f0367e2ce1d51e50fdb954302c4daf089d87a67a866b09852402c2d",
}
RECOVERY_ROOT = "custodian-review-recoveries/finish-index-codex-exited-pass"
SCHEMA = "custodian.paired_review_finish_index_codex_exited_pass_recovery.v1"
AUTHORING_CHAT = (
    "https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/"
    "c/6ae03e16-cd34-83e9-ba0e-82b8f95f7690"
)


def _sha(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def _git(repo: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True)
    if check and result.returncode:
        raise runner.RunnerError(runner.redact(result.stderr or result.stdout))
    return result.stdout.strip()


def _manifest(root: Path) -> dict[str, str]:
    return runner._file_manifest(root)


def _run_dir(common: Path) -> Path:
    return common / "custodian-review-runs" / WORKSTREAM / RUN_ID


def _recovery_paths(common: Path) -> tuple[Path, Path]:
    root = common / RECOVERY_ROOT / RUN_ID
    current = common
    for part in Path(RECOVERY_ROOT).parts + (RUN_ID,):
        current /= part
        if current.is_symlink():
            raise runner.RunnerError("recovery storage path contains a symlink")
        if current.exists() and not current.is_dir():
            raise runner.RunnerError("recovery storage parent is not a directory")
    if not root.resolve().is_relative_to(common.resolve()):
        raise runner.RunnerError("recovery storage escapes shared Git metadata")
    return root, root / "recovery.jsonl"


def _read_json(path: Path, label: str) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise runner.RunnerError(f"{label} is missing or malformed") from exc
    if not isinstance(value, dict):
        raise runner.RunnerError(f"{label} must be a JSON object")
    return value


def _parse_session(run_dir: Path, summary: str, metadata: dict) -> tuple[str, dict[str, str]]:
    final_path = run_dir / "last-message.txt"
    try:
        final = final_path.read_text(encoding="utf-8")
        lines = (run_dir / "codex.jsonl").read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise runner.RunnerError("original reviewer session evidence is unavailable") from exc
    messages: list[str] = []
    completed = 0
    event_kinds: list[str] = []
    for raw in lines:
        try:
            event = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise runner.RunnerError("original reviewer session contains malformed JSON") from exc
        if not isinstance(event, dict):
            raise runner.RunnerError("original reviewer session contains a non-object event")
        item = event.get("item")
        if isinstance(item, dict) and item.get("type") == "agent_message":
            text = item.get("text")
            if not isinstance(text, str):
                raise runner.RunnerError("original reviewer session contains a malformed message")
            messages.append(text)
            event_kinds.append("agent_message")
        if event.get("type") == "turn.completed":
            completed += 1
            event_kinds.append("turn.completed")
    if (completed != 1 or len(messages) != 5 or not messages or messages[-1].strip() != final.strip()
            or event_kinds[-1:] != ["turn.completed"]):
        raise runner.RunnerError("session does not prove one completed turn ending at captured final message")
    if any(re.search(r"(?im)^\s*(?:verdict|disposition|review outcome|status)\s*:\s*`?(?:passed|findings|human_required)", m)
           for m in messages[:-1]):
        raise runner.RunnerError("an earlier reviewer message contains a contradictory or premature disposition")
    if (metadata.get("phase") != "codex_exited" or metadata.get("fresh") is not True
            or metadata.get("exit_code") != 0 or metadata.get("run_id") != RUN_ID
            or metadata.get("workstream") != WORKSTREAM):
        raise runner.RunnerError("original run metadata does not authenticate this completed fresh review")
    if not re.search(r"(?is)^Workstream:\s*`?" + re.escape(WORKSTREAM) + r"`?\s+\*\*Passed:\*\*", final.strip()):
        raise runner.RunnerError("captured final message does not state PASS for this exact workstream")
    if not re.search(r"(?i)no blocking defects or material acceptance gaps", final):
        raise runner.RunnerError("captured PASS does not explicitly establish zero blocking defects and material gaps")
    if ("## Findings first" not in summary or "## Evidence and verification" not in summary
            or "## Review disposition" not in summary
            or not re.search(r"(?im)^- Status: `passed`\s*$", summary)
            or not re.search(r"(?im)^- Blocking defects: `0`\s*$", summary)
            or not re.search(r"(?im)^- Material gaps: `0`\s*$", summary)
            or REVIEWED_MAIN not in summary or IMPLEMENTATION not in summary):
        raise runner.RunnerError("findings-first summary lacks exact zero-defect PASS evidence")
    expected = {
        "Review workstream": WORKSTREAM, "Review target workstream": TARGET,
        "Reviewed main": REVIEWED_MAIN, "Reviewed implementation commit": IMPLEMENTATION,
        "Reviewer context": "fresh", "Reviewer provenance": "different-agent",
        "Review cycle": "0", "Run ID": RUN_ID,
    }
    return final, expected


def _verify_lock_available(path: Path) -> None:
    if not path.is_file() or path.is_symlink():
        raise runner.RunnerError("original review supervisor lock file is missing or unsafe")
    with path.open("rb") as handle:
        try:
            fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise runner.RunnerError("another supervisor owns the original review") from exc
        finally:
            try:
                fcntl.flock(handle.fileno(), fcntl.LOCK_UN)
            except OSError:
                pass


def _exact_review_owners(worktree: Path) -> list[dict[str, object]]:
    """Check same-user writers while excluding known credential/session agents."""
    proc = Path("/proc")
    if not proc.is_dir():
        raise runner.RunnerError("host process ownership cannot be verified")
    excluded = {os.getpid()}
    parent = os.getppid()
    while parent > 1 and parent not in excluded:
        excluded.add(parent)
        try:
            fields = (proc / str(parent) / "stat").read_text().rsplit(")", 1)[1].split()
            parent = int(fields[1])
        except (OSError, ValueError, IndexError):
            break
    ignored = {"systemd", "(sd-pam)", "ssh-agent", "gpg-agent", "scdaemon", "pinentry"}
    expected = str(worktree.resolve())
    owners = []
    for entry in proc.iterdir():
        if not entry.name.isdigit() or int(entry.name) in excluded:
            continue
        try:
            if entry.stat().st_uid != os.getuid():
                continue
            name = (entry / "comm").read_text().strip()
            if name in ignored:
                continue
            argv = (entry / "cmdline").read_bytes().replace(b"\0", b" ").decode(errors="replace")
            cwd = os.readlink(entry / "cwd").removesuffix(" (deleted)")
        except FileNotFoundError:
            continue
        except PermissionError as exc:
            raise runner.RunnerError(f"cannot inspect same-user process {entry.name} for review ownership") from exc
        if cwd == expected or cwd.startswith(expected + os.sep) or expected in argv:
            owners.append({"pid": int(entry.name), "cwd_match": cwd.startswith(expected),
                           "command_path_match": expected in argv})
        elif ((WORKSTREAM in argv or RUN_ID in argv)
              and any(token in argv.lower() for token in ("codex", "paired_review_runner", "workstream.py"))):
            owners.append({"pid": int(entry.name), "identity_command_match": True})
    return owners


def _plan(repo: Path, *, check_lock: bool = True) -> dict:
    repo = Path(_git(repo, "rev-parse", "--show-toplevel")).resolve()
    common = runner.common_dir(repo).resolve()
    run_dir = _run_dir(common)
    actual_manifest = _manifest(run_dir)
    if actual_manifest != RUN_MANIFEST:
        raise runner.RunnerError("original run bytes differ from the authenticated exact-run manifest")
    if any(run_dir.glob("continuation-*")):
        raise runner.RunnerError("original run has continuation evidence; this exact recovery does not accept it")
    metadata = _read_json(run_dir / "metadata.json", "original run metadata")
    expected_worktree = Path(str(metadata.get("worktree", ""))).resolve()
    if (metadata.get("run_dir") != str(run_dir) or metadata.get("branch") != f"agent/{WORKSTREAM}"
            or metadata.get("packet") != ACTIVE
            or expected_worktree.name != f"review-workstream-finish-index-conflict-recovery-v1-{CLAIM_RUN_ID}"):
        raise runner.RunnerError("paired-review run and original dispatcher claim identities disagree")
    claim = runner._claim_identity(run_dir, WORKSTREAM, repo, metadata)
    worktree = Path(claim["worktree"]).resolve()
    if (worktree != expected_worktree or claim.get("branch") != f"agent/{WORKSTREAM}"
            or claim.get("packet") != ACTIVE or not worktree.is_dir()
            or runner.common_dir(worktree).resolve() != common
            or _git(worktree, "branch", "--show-current") != f"agent/{WORKSTREAM}"):
        raise runner.RunnerError("original dispatcher claim does not resolve to its exact preserved checkout")
    if _git(worktree, "rev-parse", "HEAD") != REVIEWED_MAIN:
        raise runner.RunnerError("preserved review checkout is not at its authenticated published tip")
    remote = subprocess.run(["git", "ls-remote", "origin", f"refs/heads/agent/{WORKSTREAM}"],
                            cwd=repo, text=True, capture_output=True)
    if remote.returncode:
        raise runner.RunnerError("cannot read the current remote review branch tip")
    remote_rows = [line.split() for line in remote.stdout.splitlines() if line.strip()]
    if len(remote_rows) != 1 or remote_rows[0][0] != REVIEWED_MAIN:
        raise runner.RunnerError("remote review branch moved from its preserved tip")
    main_remote = subprocess.run(["git", "ls-remote", "origin", "refs/heads/main"],
                                 cwd=repo, text=True, capture_output=True)
    if main_remote.returncode:
        raise runner.RunnerError("cannot verify current origin/main without mutating local refs")
    main_rows = [line.split() for line in main_remote.stdout.splitlines() if line.strip()]
    if len(main_rows) != 1:
        raise runner.RunnerError("origin/main returned an ambiguous remote identity")
    current_main = main_rows[0][0]
    local_main = _git(repo, "rev-parse", "origin/main")
    if current_main != local_main:
        raise runner.RunnerError("cached origin/main is stale; fetch normally, then request a new plan")
    if subprocess.run(["git", "merge-base", "--is-ancestor", REVIEWED_MAIN, current_main],
                      cwd=repo, capture_output=True).returncode:
        raise runner.RunnerError("current main does not descend from the review's pinned baseline")
    if metadata.get("reviewed_main") not in (None, REVIEWED_MAIN):
        raise runner.RunnerError("run metadata pins a contradictory reviewed-main identity")
    owners = _exact_review_owners(worktree)
    if owners:
        raise runner.RunnerError("a live local process still owns the original reviewer checkout")
    lock = common / "custodian-review-runs" / "locks" / f"{WORKSTREAM}.lock"
    if check_lock:
        _verify_lock_available(lock)

    status = _git(worktree, "status", "--porcelain", "--untracked-files=all").splitlines()
    if set(status) != {f"M {ACTIVE}", f"?? {SUMMARY}"}:
        raise runner.RunnerError("preserved reviewer checkout has unexpected tracked or untracked changes")
    artifact_hashes: dict[str, str] = {}
    for relative, expected_hash in REVIEWER_ARTIFACTS.items():
        path = worktree / relative
        if path.is_symlink() or not path.is_file():
            raise runner.RunnerError(f"reviewer artifact is missing or not a regular file: {relative}")
        actual = _sha(path.read_bytes())
        if actual != expected_hash:
            raise runner.RunnerError(f"reviewer artifact bytes differ from the inspected original: {relative}")
        artifact_hashes[relative] = actual

    active_text = (worktree / ACTIVE).read_text(encoding="utf-8")
    summary = (worktree / SUMMARY).read_text(encoding="utf-8")
    packet = runner.parse_packet(ACTIVE, active_text)
    if (packet.error or packet.workstream != WORKSTREAM or packet.kind != "review"
            or packet.review_target_workstream != TARGET
            or packet.review_target_packet != TARGET_PACKET
            or not re.search(r"(?m)^- Reviewed main: `?dd3041b773959b50b38c7a5c2391ff0b7e120914`?\s*$", active_text)
            or packet.review_cycle != 0):
        raise runner.RunnerError("preserved reviewer packet identity differs from the exact historical review")
    if "## Review Outcome" in active_text or (worktree / ARCHIVED).exists():
        raise runner.RunnerError("review packet already has an outcome or archive; refusing duplicate closeout")
    final, outcome_fields = _parse_session(run_dir, summary, metadata)

    target_baseline = runner._show_at(repo, REVIEWED_MAIN, TARGET_PACKET)
    implementation, identity_error = runner.resolve_target_implementation_commit(
        repo, REVIEWED_MAIN, TARGET_PACKET, TARGET, target_baseline)
    if identity_error or implementation != IMPLEMENTATION:
        raise runner.RunnerError("pinned implementation target failed identity verification")
    candidate = (worktree / TARGET_PACKET).read_text(encoding="utf-8")
    if candidate != target_baseline or "## Independent Review" in target_baseline:
        raise runner.RunnerError("reviewed target changed or already contains a review receipt")

    host_meta = metadata.get("host_validation")
    if not isinstance(host_meta, dict):
        raise runner.RunnerError("original run has no pinned coordinator validation")
    host = runner._host_evidence_for_continuation(
        repo, worktree, run_dir, metadata, REVIEWED_MAIN, IMPLEMENTATION, TARGET, TARGET_PACKET)
    if (host.get("report_sha256") != RUN_MANIFEST["validation.json"]
            or host.get("metadata_sha256") != RUN_MANIFEST["coordinator-validation.json"]):
        raise runner.RunnerError("pinned host validation hashes differ from the exact reviewed evidence")
    owner_summary = "no blocking defects or material acceptance gaps"
    if owner_summary not in final.lower():
        raise runner.RunnerError("final reviewer statement does not substantiate a zero-defect PASS")
    if f"Authoring chat: {AUTHORING_CHAT}" not in summary:
        raise runner.RunnerError("findings-first reviewer summary omits the exact authoring-chat backlink")
    expected_receipt = {
        "Schema": "custodian.paired_review.v1", "Review workstream": WORKSTREAM,
        "Review target workstream": TARGET, "Status": "passed", "Blocking defects": "0",
        "Material gaps": "0", "Reviewer context": "fresh", "Reviewer provenance": "different-agent",
        "Reviewed main": REVIEWED_MAIN, "Reviewed implementation commit": IMPLEMENTATION,
    }
    if runner._independent_review_receipt(active_text) != expected_receipt:
        raise runner.RunnerError("reviewer-authored receipt fields do not match authenticated session and target")
    recovery_root, journal = _recovery_paths(common)
    if journal.exists():
        raise runner.RunnerError("recovery journal already exists; inspect prior apply state instead of replaying")
    outcome = _canonical_outcome(outcome_fields)
    archived_text = _archived_packet_text(active_text)
    target_after = target_baseline + "\n## Independent Review\n\n" + render_review_receipt(outcome)
    summary_after = _summary_handoff(summary)
    intended_mutations = {
        ACTIVE: None,
        ARCHIVED: _sha(archived_text.encode()),
        TARGET_PACKET: _sha(target_after.encode()),
        SUMMARY: _sha(summary_after.encode()),
        f"{runner.PACKET_ROOT}/README.md": _intended_index_sha(worktree, archived_text, target_after),
    }
    plan = {
        "schema": SCHEMA, "mode": "plan", "workstream": WORKSTREAM,
        "run_id": RUN_ID, "claim_run_id": CLAIM_RUN_ID, "target_workstream": TARGET,
        "reviewed_main": REVIEWED_MAIN, "implementation_commit": IMPLEMENTATION,
        "coordinator_main": current_main, "branch": f"agent/{WORKSTREAM}",
        "remote_tip": remote_rows[0][0], "local_head": _git(worktree, "rev-parse", "HEAD"),
        "claim_receipt_sha256": _sha((run_dir / "claim-receipt.json").read_bytes()),
        "run_evidence_sha256": actual_manifest, "reviewer_artifacts_sha256": artifact_hashes,
        "reviewer_final_sha256": _sha(final.encode()),
        "summary_sha256": _sha(summary.encode()), "reviewer_messages": 5,
        "completed_turns": 1, "reviewer_outcome": outcome,
        "target_baseline_sha256": _sha(target_baseline.encode()),
        "host_validation": {"report_sha256": host["report_sha256"],
                            "metadata_sha256": host["metadata_sha256"],
                            "selected": 9, "passed": 9},
        "active_review_packet": ACTIVE, "archived_review_packet": ARCHIVED,
        "target_packet": TARGET_PACKET, "summary": SUMMARY,
        "recovery_root": str(recovery_root), "journal": str(journal),
        "reviewer_process_owners": [], "action": "owner-authorized-exact-review-closeout",
        "intended_mutations_sha256": intended_mutations,
    }
    plan["plan_sha256"] = _sha(json.dumps(plan, sort_keys=True, separators=(",", ":")).encode())
    return plan


def plan(repo: Path) -> dict:
    # Disable Git's optional index refresh; no fetch, ref update, or evidence write.
    previous = os.environ.get("GIT_OPTIONAL_LOCKS")
    os.environ["GIT_OPTIONAL_LOCKS"] = "0"
    try:
        return _plan(repo)
    finally:
        if previous is None:
            os.environ.pop("GIT_OPTIONAL_LOCKS", None)
        else:
            os.environ["GIT_OPTIONAL_LOCKS"] = previous


def _write_new(path: Path, raw: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "wb") as stream:
        stream.write(raw)
        stream.flush()
        os.fsync(stream.fileno())
    if path.read_bytes() != raw:
        raise runner.RunnerError("create-only evidence preservation did not round-trip")


def _canonical_outcome(fields: dict[str, str]) -> dict[str, str]:
    text = review_outcome.render_review_outcome(
        outcome="passed", review_workstream=WORKSTREAM, target_workstream=TARGET,
        reviewed_main=REVIEWED_MAIN, implementation_commit=IMPLEMENTATION,
        provenance="different-agent", run_id=RUN_ID, review_cycle=0, ids=(),
    )
    parsed, error = review_outcome.parse_review_outcome(text)
    if error or parsed is None or parsed.get("Outcome") != "passed":
        raise runner.RunnerError("official outcome renderer did not produce a canonical PASS")
    return parsed


def _archived_packet_text(active_text: str) -> str:
    first_section = re.search(r"(?m)^## ", active_text)
    if first_section is None:
        raise runner.RunnerError("review packet has no body section after its metadata")
    header, body = active_text[:first_section.start()].rstrip(), active_text[first_section.start():]
    status_matches = list(re.finditer(r"(?m)^- Status: `?[^`\r\n]+`?[ \t]*$", header))
    review_matches = list(re.finditer(r"(?m)^- Review: `?[^`\r\n]+`?[ \t]*$", header))
    if (len(status_matches) != 1 or len(review_matches) != 1
            or re.search(r"(?m)^## Review Outcome[ \t]*$", body)):
        raise runner.RunnerError("review packet status or outcome sections are ambiguous")
    header = header[:status_matches[0].start()] + "- Status: `complete`" + header[status_matches[0].end():]
    review_matches = list(re.finditer(r"(?m)^- Review: `?[^`\r\n]+`?[ \t]*$", header))
    header = header[:review_matches[0].start()] + "- Review: `passed`" + header[review_matches[0].end():]
    outcome_text = review_outcome.render_review_outcome(
        outcome="passed", review_workstream=WORKSTREAM, target_workstream=TARGET,
        reviewed_main=REVIEWED_MAIN, implementation_commit=IMPLEMENTATION,
        provenance="different-agent", run_id=RUN_ID, review_cycle=0, ids=(),
    )
    return header + "\n\n" + body.rstrip() + "\n\n" + outcome_text


def _intended_index_sha(worktree: Path, archived_text: str, target_text: str) -> str:
    """Render the post-archive managed index from a disposable packet-tree copy."""
    packet_root = worktree / "custodian/docs/ai_context/task_packets"
    with tempfile.TemporaryDirectory(prefix="custodian-finish-index-plan-") as temporary:
        temp_repo = Path(temporary)
        temp_packets = temp_repo / "custodian/docs/ai_context/task_packets"
        shutil.copytree(packet_root, temp_packets, symlinks=True)
        (temp_packets / Path(ACTIVE).name).unlink()
        (temp_packets / "archived" / Path(ACTIVE).name).write_text(archived_text, encoding="utf-8")
        (temp_packets / TARGET_PACKET.removeprefix("custodian/docs/ai_context/task_packets/")) \
            .write_text(target_text, encoding="utf-8")
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        try:
            import task_packet_index
            readme = temp_packets / "README.md"
            original = readme.read_text(encoding="utf-8")
            expected = task_packet_index.render_managed_block(temp_repo)
            updated, count = task_packet_index._BLOCK_RE.subn(lambda _match: expected, original, count=1)
            if count != 1:
                raise runner.RunnerError("managed index block is missing from the preserved README")
            return _sha(updated.encode())
        finally:
            sys.path.pop(0)


def _prepare_artifacts(worktree: Path, active_text: str, summary_text: str,
                       target_baseline: str, outcome: dict[str, str],
                       intended_hashes: dict[str, str]) -> dict[str, str]:
    """Write the bounded review closeout artifacts once, checking planned bytes."""
    active_path, archive_path = worktree / ACTIVE, worktree / ARCHIVED
    target_path, summary_path = worktree / TARGET_PACKET, worktree / SUMMARY
    if archive_path.exists() or active_path.read_text(encoding="utf-8") != active_text:
        raise runner.RunnerError("active or archived reviewer packet changed before artifact preparation")
    if target_path.is_symlink() or not target_path.is_file():
        raise runner.RunnerError("review target packet is missing or unsafe")
    target_candidate = target_path.read_text(encoding="utf-8")
    if target_candidate != target_baseline:
        raise runner.RunnerError("review target changed before artifact preparation")
    archived_text = _archived_packet_text(active_text)
    target_text = target_baseline + "\n## Independent Review\n\n" + render_review_receipt(outcome)
    _, error = verify_review_receipt_delta(
        target_baseline, target_text, review_workstream=WORKSTREAM,
        target_workstream=TARGET, reviewed_main=REVIEWED_MAIN,
        target_implementation_commit=IMPLEMENTATION)
    if error:
        raise runner.RunnerError("rendered target receipt failed canonical verification: " + error)
    summary_after = _summary_handoff(summary_text)
    planned = {
        ARCHIVED: _sha(archived_text.encode()), TARGET_PACKET: _sha(target_text.encode()),
        SUMMARY: _sha(summary_after.encode()),
    }
    if any(intended_hashes.get(path) != digest for path, digest in planned.items()):
        raise runner.RunnerError("review closeout artifacts differ from their plan digests")
    archive_path.parent.mkdir(parents=True, exist_ok=True)
    archive_path.write_text(archived_text, encoding="utf-8")
    active_path.unlink()
    target_path.write_text(target_text, encoding="utf-8")
    summary_path.write_text(summary_after, encoding="utf-8")
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    try:
        import task_packet_index
        task_packet_index.write(worktree)
        current, diagnostic = task_packet_index.check(worktree)
        if not current:
            raise runner.RunnerError("managed task index verification failed: " + diagnostic)
    finally:
        sys.path.pop(0)
    readme = f"{runner.PACKET_ROOT}/README.md"
    if _sha((worktree / readme).read_bytes()) != intended_hashes.get(readme):
        raise runner.RunnerError("managed index differs from its plan digest")
    return {**planned, readme: _sha((worktree / readme).read_bytes())}


def _summary_handoff(summary: str) -> str:
    if "## Next Handoff" in summary:
        raise runner.RunnerError("reviewer summary already contains a Next Handoff; preserving ambiguity")
    if f"Authoring chat: {AUTHORING_CHAT}" not in summary:
        raise runner.RunnerError("reviewer summary lacks the exact historical authoring-chat backlink")
    handoff = (
        "\n\n## Next Handoff\n"
        "- Next workstream: `workflow-governance-simplification-v1`\n"
        "- Next packet state: dependency-gated\n"
        "- Refresh owner: none\n"
        "- ChatGPT/user planning refresh required: no\n"
        f"- Authoring chat: {AUTHORING_CHAT}\n"
        "- Refresh reason: none\n"
        "- Next action: After this exact review PASS lands, run the published read-only plan and obtain owner authorization before applying the original review closeout.\n"
        "- Blockers or open questions: Original-run apply remains separate and is not authorized by this recovery implementation.\n"
    )
    return summary.rstrip() + handoff


def apply(repo: Path, expected_plan_sha256: str) -> dict:
    if not re.fullmatch(r"[0-9a-f]{64}", expected_plan_sha256):
        raise runner.RunnerError("apply requires the exact SHA-256 from a fresh read-only plan")
    repo = Path(_git(repo, "rev-parse", "--show-toplevel")).resolve()
    common = runner.common_dir(repo).resolve()
    initial = plan(repo)
    if initial["plan_sha256"] != expected_plan_sha256:
        raise runner.RunnerError("exact run, refs, ownership or reviewer artifacts changed; obtain a fresh plan")
    lock = common / "custodian-review-runs" / "locks" / f"{WORKSTREAM}.lock"
    with lock.open("rb") as supervisor_lock:
        try:
            fcntl.flock(supervisor_lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise runner.RunnerError("another supervisor owns the original review") from exc
        fresh = _plan(repo, check_lock=False)
        if fresh["plan_sha256"] != expected_plan_sha256:
            raise runner.RunnerError("fresh locked plan differs; no recovery writes were made")
        root, journal_path = _recovery_paths(common)
        root.mkdir(parents=True, exist_ok=True)
        preserved: dict[str, str] = {}
        for relative, expected_hash in REVIEWER_ARTIFACTS.items():
            original = Path(_read_json(_run_dir(common) / "metadata.json", "run metadata")["worktree"]) / relative
            copy = root / "preserved" / relative
            raw = original.read_bytes()
            if _sha(raw) != expected_hash:
                raise runner.RunnerError("reviewer artifact changed before preservation")
            _write_new(copy, raw)
            preserved[relative] = _sha(copy.read_bytes())
        if preserved != REVIEWER_ARTIFACTS:
            raise runner.RunnerError("preserved reviewer artifact manifest does not match the plan")
        journal_identity = {"schema": SCHEMA, "workstream": WORKSTREAM, "run_id": RUN_ID,
                            "claim_run_id": CLAIM_RUN_ID, "plan_sha256": expected_plan_sha256,
                            "run_evidence_sha256": fresh["run_evidence_sha256"],
                            "reviewer_artifacts_sha256": preserved}

        def append_journal(stage: str, **details) -> None:
            event = {**journal_identity, "stage": stage, **details}
            flags = os.O_WRONLY | os.O_CREAT | (os.O_EXCL if not journal_path.exists() else os.O_APPEND)
            fd = os.open(journal_path, flags, 0o600)
            with os.fdopen(fd, "ab") as stream:
                stream.write((json.dumps(event, sort_keys=True) + "\n").encode())
                stream.flush()
                os.fsync(stream.fileno())

        append_journal("prepared")

        worktree = Path(_read_json(_run_dir(common) / "metadata.json", "run metadata")["worktree"])
        active_path, archive_path = worktree / ACTIVE, worktree / ARCHIVED
        summary_path = worktree / SUMMARY
        active_text = active_path.read_text(encoding="utf-8")
        summary_text = summary_path.read_text(encoding="utf-8")
        if archive_path.exists():
            raise runner.RunnerError("archived review packet appeared after planning")
        packet = runner.parse_packet(ACTIVE, active_text)
        if packet.error:
            raise runner.RunnerError("active review packet no longer parses")
        outcome = _canonical_outcome(fresh["reviewer_outcome"])
        target_baseline = runner._show_at(repo, REVIEWED_MAIN, TARGET_PACKET)
        artifact_hashes = _prepare_artifacts(
            worktree, active_text, summary_text, target_baseline, outcome,
            fresh["intended_mutations_sha256"],
        )

        append_journal("artifacts_prepared", outcome=outcome,
                       target_receipt_sha256=_sha(render_review_receipt(outcome).encode()),
                       artifact_hashes=artifact_hashes)

        metadata = _read_json(_run_dir(common) / "metadata.json", "original run metadata")
        host = runner._host_evidence_for_continuation(
            repo, worktree, _run_dir(common), metadata, REVIEWED_MAIN, IMPLEMENTATION, TARGET, TARGET_PACKET)
        host.update({"run_id": RUN_ID, "review_cycle": 0})
        result = runner.coordinator_finish_review(
            repo, WORKSTREAM, worktree, ACTIVE, TARGET, TARGET_PACKET,
            target_baseline, AUTHORING_CHAT, REVIEWED_MAIN, _run_dir(common), host)
        if _manifest(_run_dir(common)) != fresh["run_evidence_sha256"]:
            raise runner.RunnerError("original immutable review-run evidence changed during closeout")
        verified_main = runner.fetch_and_pin_main(repo)
        archived = runner._show_at(repo, verified_main, ARCHIVED)
        parsed, error = review_outcome.parse_review_outcome(archived)
        identity = review_outcome.outcome_identity_error(
            parsed or {}, review_workstream=WORKSTREAM, target_workstream=TARGET,
            reviewed_main=REVIEWED_MAIN, implementation_commit=IMPLEMENTATION,
            run_id=RUN_ID, review_cycle=0)
        if error or identity or not parsed or parsed.get("Outcome") != "passed":
            raise runner.RunnerError("landed review outcome failed canonical verification")
        append_journal("complete", landed_commit=result, verified_main=verified_main,
                       original_run_evidence_unchanged=True, coordinator_verified=True)
        return {"schema": SCHEMA, "workstream": WORKSTREAM, "run_id": RUN_ID,
                "stage": "complete", "landed_commit": result, "verified_main": verified_main,
                "original_run_evidence_unchanged": True, "coordinator_verified": True}


def main(argv: list[str]) -> int:
    import argparse
    parser = argparse.ArgumentParser(prog="paired_review_runner.py recover-finish-index-codex-exited-pass")
    parser.add_argument("review_workstream", choices=(WORKSTREAM,))
    parser.add_argument("--run-id", required=True, choices=(RUN_ID,))
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--plan", action="store_true")
    mode.add_argument("--apply", action="store_true")
    parser.add_argument("--plan-sha256", help="exact digest emitted by a fresh read-only --plan")
    args = parser.parse_args(argv)
    try:
        if args.plan:
            if args.plan_sha256:
                raise runner.RunnerError("read-only plan cannot include an apply digest")
            result = plan(Path.cwd())
        else:
            if not args.plan_sha256:
                raise runner.RunnerError("apply requires --plan-sha256 from a fresh plan")
            result = apply(Path.cwd(), args.plan_sha256)
    except (runner.RunnerError, OSError, ValueError, subprocess.SubprocessError) as exc:
        print(f"paired_review_runner: BLOCKED: {runner.redact(str(exc))}", file=sys.stderr)
        return 2
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0
