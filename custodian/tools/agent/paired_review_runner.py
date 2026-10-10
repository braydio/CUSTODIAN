#!/usr/bin/env python3
"""Claim and supervise one exact paired review in a fresh ephemeral Codex session."""
from __future__ import annotations

import argparse
import fcntl
import json
import re
import shutil
import subprocess
import sys
import threading
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

from task_packet_contract import ID_RE, PACKET_ROOT, parse_packet
from workflow_control import common_dir, redact

SCHEMA = "custodian.paired_review_run.v1"
CLAIM_SENTINEL = "CUSTODIAN_DISPATCH_RESULT_JSON:"


class RunnerError(RuntimeError):
    pass


def git(repo: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True)
    if check and result.returncode:
        raise RunnerError(redact(result.stderr or result.stdout))
    return result.stdout.strip()


def packet_at_main(repo: Path, workstream: str):
    git(repo, "fetch", "origin", "main")
    paths = git(repo, "ls-tree", "-r", "--name-only", "origin/main", PACKET_ROOT).splitlines()
    matches = []
    for path in paths:
        if not path.endswith(".md") or "/archived/" in path:
            continue
        content = git(repo, "show", f"origin/main:{path}")
        packet = parse_packet(path, content)
        if packet.workstream == workstream:
            matches.append((path, content, packet))
    if len(matches) != 1:
        raise RunnerError(f"expected one active packet for {workstream}, found {len(matches)}")
    return matches[0]


def current_review_authority(content: str) -> str:
    """Return current-packet authority without its future successor handoff.

    Paired review packets commonly put the *next* workstream's refresh gate
    under a top-level ``## Handoff``. That gate is evaluated only after this
    review completes, so it must not make the current review ineligible.
    """
    successor = re.search(r"(?im)^##[ \t]+(?:handoff|next handoff)[ \t]*$", content)
    return content[:successor.start()] if successor else content


def validate_eligible_review(repo: Path, workstream: str):
    path, content, packet = packet_at_main(repo, workstream)
    if packet.error:
        raise RunnerError(f"invalid review packet: {packet.error}")
    if packet.kind != "review":
        raise RunnerError("refusing to launch a non-review packet")
    if packet.status != "ready" or packet.dispatch != "auto":
        raise RunnerError("review must be ready/auto on fetched origin/main")
    if not packet.review_target_workstream or not packet.review_target_packet:
        raise RunnerError("review packet must name its completed target")
    if packet.review_target_workstream not in packet.dependencies:
        raise RunnerError("review target must be an explicit dependency")
    if packet.visual_review == "required":
        raise RunnerError("review packet requires a human visual review")
    authority = current_review_authority(content)
    if re.search(r"(?im)^\s*-\s*(?:ChatGPT/user planning refresh required|Human decision required):\s*`?yes\b", authority):
        raise RunnerError("review packet requires a human planning/decision gate")
    if re.search(r"(?im)^\s*-\s*Refresh owner:\s*`?(?:chatgpt-user|human)", authority):
        raise RunnerError("review packet has a human-owned refresh gate")

    target_path = packet.review_target_packet
    try:
        target_content = git(repo, "show", f"origin/main:{target_path}")
    except RunnerError as exc:
        raise RunnerError("completed review target is absent from origin/main") from exc
    target = parse_packet(target_path, target_content)
    if target.kind not in {"implementation", "correction"} or target.status != "complete":
        raise RunnerError("review target must be an archived, complete implementation/correction")
    if target_path != f"{PACKET_ROOT}/archived/{Path(target_path).name}":
        raise RunnerError("review target must be in the canonical archived packet directory")
    return path, content, packet


def codex_preflight() -> str:
    executable = shutil.which("codex")
    if not executable:
        raise RunnerError("codex executable unavailable; no review claim was created")
    probe = subprocess.run([executable, "exec", "--help"], text=True, capture_output=True)
    help_text = probe.stdout + probe.stderr
    required = ("--ephemeral", "--json", "--output-last-message", "--cd", "--add-dir", "--approve-for-me")
    missing = [flag for flag in required if flag not in help_text]
    if probe.returncode or missing:
        raise RunnerError(f"codex exec preflight failed before claim (missing: {', '.join(missing) or 'exec help'})")
    return executable


def parse_claim_receipt(stdout: str, workstream: str, repo: Path) -> dict:
    lines = [line for line in stdout.splitlines() if line.startswith(CLAIM_SENTINEL)]
    if len(lines) != 1:
        raise RunnerError("dispatcher did not return exactly one structured claim receipt")
    try:
        receipt = json.loads(lines[0][len(CLAIM_SENTINEL):])
    except json.JSONDecodeError as exc:
        raise RunnerError("dispatcher claim receipt was malformed") from exc
    if not isinstance(receipt, dict):
        raise RunnerError("dispatcher claim receipt must be a JSON object")
    if receipt.get("result") != "claimed" or receipt.get("workstream") != workstream or receipt.get("verified") is not True:
        raise RunnerError("dispatcher receipt does not verify the requested review claim")
    if not all(isinstance(receipt.get(field), str) and receipt.get(field) for field in ("worktree", "branch", "packet")):
        raise RunnerError("dispatcher receipt omitted branch, worktree, or packet identity")
    worktree = Path(receipt.get("worktree", "")).resolve()
    if not worktree.is_dir() or git(worktree, "branch", "--show-current") != receipt.get("branch"):
        raise RunnerError("dispatcher worktree/branch identity could not be verified")
    if common_dir(worktree) != common_dir(repo):
        raise RunnerError("dispatcher returned a worktree from another repository")
    expected_packet = f"{PACKET_ROOT}/{Path(receipt.get('packet', '')).name}"
    if receipt.get("packet") != expected_packet:
        raise RunnerError("dispatcher returned an unexpected packet path")
    return receipt


def prompt_for(workstream: str, packet_path: str, target_path: str) -> str:
    return f"""You are the fresh independent paired reviewer for CUSTODIAN workstream `{workstream}`.

Reconstruct the review solely from durable repository evidence in this claimed worktree. Read `AGENTS.md`, `custodian/AGENTS.md`, `{packet_path}`, `{target_path}`, the target's root closing summary, and the landed diff/current main. Run every validation and fault-check required by the review packet. Do not use, request, or infer the implementation-session transcript. Do not edit reviewed implementation/runtime code. Record findings first, write the durable review receipt and required root summary with the exact Authoring chat URL, update/archive only the authorized review packet, and complete the normal `workstream.py finish` lifecycle when validation permits. If blocked, preserve the claimed workstream and write a durable summary explaining the blocker; never delete or reclaim it. Do not claim another packet or hop to the global queue. Report the exact result and landed SHA or recovery worktree/log path."""


def _write(path: Path, value: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding="utf-8")


def safe_output(value: str) -> str:
    """Redact credential-shaped text and secret-keyed JSON fields in runner logs."""
    safe_lines = []
    for line in value.splitlines():
        try:
            parsed = json.loads(line)
        except json.JSONDecodeError:
            safe_lines.append(redact(line))
            continue

        def scrub(item):
            if isinstance(item, dict):
                return {key: "<redacted>" if re.search(r"(?i)(authorization|api.?key|access.?token|refresh.?token|password|secret|credential|private.?key)", str(key)) else scrub(val) for key, val in item.items()}
            if isinstance(item, list):
                return [scrub(val) for val in item]
            if isinstance(item, str):
                return redact(item)
            return item
        safe_lines.append(json.dumps(scrub(parsed), sort_keys=True))
    return "\n".join(safe_lines) + ("\n" if value.endswith("\n") else "")


def next_handoff(summary: str) -> str:
    match = re.search(r"(?ms)^## Next Handoff\s*\n(.*?)(?=^## |\Z)", summary)
    return match.group(1).strip() if match else ""


def launch_codex(argv: list[str], worktree: Path, prompt: str, run_dir: Path, timeout: float | None) -> int:
    """Stream redacted JSONL/stderr to durable files while supervising Codex."""
    with (run_dir / "codex.jsonl").open("w", encoding="utf-8") as stdout_log, \
         (run_dir / "codex.stderr").open("w", encoding="utf-8") as stderr_log:
        process = subprocess.Popen(argv, cwd=worktree, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, text=True, bufsize=1)

        def copy_lines(source, destination):
            for line in iter(source.readline, ""):
                destination.write(safe_output(line))
                destination.flush()
            source.close()

        stdout_thread = threading.Thread(target=copy_lines, args=(process.stdout, stdout_log), daemon=True)
        stderr_thread = threading.Thread(target=copy_lines, args=(process.stderr, stderr_log), daemon=True)
        stdout_thread.start()
        stderr_thread.start()
        try:
            process.stdin.write(prompt)
            process.stdin.close()
            try:
                process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
                raise
        finally:
            stdout_thread.join(timeout=10)
            stderr_thread.join(timeout=10)
        return process.returncode


def run(repo: Path, workstream: str, *, codex_path: str | None = None, timeout: float | None = None) -> int:
    if not ID_RE.fullmatch(workstream):
        raise RunnerError("review workstream must be lowercase kebab-case")
    if timeout is not None and (timeout <= 0 or not float(timeout) < float("inf")):
        raise RunnerError("timeout must be a positive finite number")
    repo = Path(git(repo, "rev-parse", "--show-toplevel")).resolve()
    expected_packet_path, _content, packet = validate_eligible_review(repo, workstream)
    executable = codex_path or codex_preflight()
    if codex_path:
        help_result = subprocess.run([executable, "exec", "--help"], text=True, capture_output=True)
        if help_result.returncode or "--ephemeral" not in (help_result.stdout + help_result.stderr):
            raise RunnerError("test/injected Codex executable lacks ephemeral exec support")

    common = common_dir(repo)
    run_id = f"{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}-{uuid.uuid4().hex[:12]}"
    run_dir = common / "custodian-review-runs" / workstream / run_id
    run_dir.mkdir(parents=True, exist_ok=False)
    mutex_path = common / "custodian-review-runs" / "locks" / f"{workstream}.lock"
    mutex_path.parent.mkdir(parents=True, exist_ok=True)
    with mutex_path.open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise RunnerError(f"another local runner already supervises {workstream}; no claim attempted") from exc
        metadata = {"schema": SCHEMA, "run_id": run_id, "workstream": workstream,
                    "phase": "preflight_complete", "created_utc": datetime.now(timezone.utc).isoformat(),
                    "run_dir": str(run_dir)}
        _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
        claim_cmd = [sys.executable, str(repo / "custodian/tools/agent/dispatch.py"), "claim", workstream,
                     "--agent", "codex-reviewer"]
        claimed = subprocess.run(claim_cmd, cwd=repo, text=True, capture_output=True)
        _write(run_dir / "claim.stdout", redact(claimed.stdout))
        _write(run_dir / "claim.stderr", redact(claimed.stderr))
        if claimed.returncode:
            metadata["phase"] = "claim_failed"
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            raise RunnerError(f"exact review claim failed; no Codex process launched (see {run_dir})")
        try:
            receipt = parse_claim_receipt(claimed.stdout, workstream, repo)
        except RunnerError as exc:
            metadata.update({"phase": "claim_receipt_invalid", "receipt_error": redact(str(exc))})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Dispatcher reported a successful claim but its receipt could not be verified. Do not retry or reclaim `{workstream}` until `dispatch.py last-claim --json` and remote claims are reconciled. Run evidence: `{run_dir}`.\n")
            raise
        worktree = Path(receipt["worktree"]).resolve()
        actual_path = receipt["packet"]
        if actual_path != expected_packet_path:
            metadata.update({"phase": "claim_packet_mismatch", "worktree": str(worktree), "branch": receipt["branch"]})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Dispatcher claimed an unexpected packet for `{workstream}`. Preserve branch `{receipt['branch']}` and worktree `{worktree}` and reconcile the claim. Run evidence: `{run_dir}`.\n")
            raise RunnerError("dispatcher receipt packet differs from the fetched eligible packet")
        if not (worktree / actual_path).is_file():
            _write(run_dir / "RECOVERY.md", f"Claimed packet missing from verified worktree. Preserve branch `{receipt['branch']}` and worktree `{worktree}`. Run evidence: `{run_dir}`.\n")
            raise RunnerError(f"claimed packet missing from verified worktree; recover at {worktree}")
        metadata.update({"phase": "claimed", "branch": receipt["branch"], "worktree": str(worktree),
                         "packet": actual_path, "codex": str(executable), "fresh": True})
        _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
        last_message = run_dir / "last-message.txt"
        argv = [str(executable), "exec", "--ephemeral", "--json", "--approve-for-me",
                "--cd", str(worktree), "--add-dir", str(run_dir),
                "--output-last-message", str(last_message), "-"]
        metadata["phase"] = "codex_running"
        metadata["invocation"] = ["codex", "exec", "--ephemeral", "--json", "--approve-for-me",
                                  "--cd", str(worktree), "--add-dir", "<run-dir>",
                                  "--output-last-message", "<run-dir>/last-message.txt", "-"]
        _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
        started = time.monotonic()
        try:
            exit_code = launch_codex(argv, worktree, prompt_for(workstream, actual_path,
                                      packet.review_target_packet or ""), run_dir, timeout)
        except subprocess.TimeoutExpired:
            metadata.update({"phase": "codex_timeout_recovery", "elapsed_seconds": round(time.monotonic() - started, 3),
                             "recovery_worktree": str(worktree)})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Codex timed out after claim. Preserve branch `{receipt['branch']}` and worktree `{worktree}`. Run evidence: `{run_dir}`. Do not delete or reclaim.\n")
            return 2
        except OSError as exc:
            metadata.update({"phase": "codex_launch_failed_recovery", "launch_error": redact(str(exc)),
                             "recovery_worktree": str(worktree)})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Codex failed to launch after claim: {redact(str(exc))}. Preserve branch `{receipt['branch']}` and worktree `{worktree}`. Run evidence: `{run_dir}`. Do not delete or reclaim.\n")
            return 2
        if last_message.is_file():
            _write(last_message, safe_output(last_message.read_text(encoding="utf-8", errors="replace")))
        elif exit_code == 0:
            metadata["phase"] = "failed_missing_final_message"
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Codex exited 0 without the required final-message capture. Preserve branch `{receipt['branch']}` and worktree `{worktree}`. Run evidence: `{run_dir}`.\n")
            raise RunnerError(f"final-message capture is missing; recovery at {run_dir}")
        metadata.update({"phase": "codex_exited", "exit_code": exit_code,
                         "elapsed_seconds": round(time.monotonic() - started, 3)})
        _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")

        git(repo, "fetch", "origin", "main", check=False)
        summary_matches = git(repo, "grep", "-l", "--fixed-strings", workstream, "origin/main", "--", "*_CLAUDE_SUMMARY.md", check=False).splitlines()
        active_packet = (worktree / actual_path).is_file()
        active_summary = [p for p in worktree.glob("*_CLAUDE_SUMMARY.md") if workstream in p.read_text(encoding="utf-8", errors="replace")]
        durable_summary = bool(summary_matches) or (active_packet and bool(active_summary))
        archived_packet_path = f"{PACKET_ROOT}/archived/{Path(actual_path).name}"
        archive_probe = subprocess.run(["git", "cat-file", "-e", f"origin/main:{archived_packet_path}"], cwd=repo,
                                       text=True, capture_output=True)
        archived = False
        if archive_probe.returncode == 0:
            archived_packet = parse_packet(archived_packet_path, git(repo, "show", f"origin/main:{archived_packet_path}"))
            archived = archived_packet.kind == "review" and archived_packet.status == "complete" and archived_packet.workstream == workstream
        complete = archived and bool(summary_matches)
        if exit_code == 0 and not complete:
            metadata["phase"] = "failed_missing_durable_review_state"
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Codex exited 0 without a durable landed review receipt/summary. Preserve `{receipt['branch']}` and `{worktree}`. Run evidence: `{run_dir}`.\n")
            raise RunnerError(f"Codex exited 0 without durable review state; recovery at {run_dir}")
        if not durable_summary:
            metadata["phase"] = "failed_missing_summary"
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Review process did not leave a durable summary. Preserve `{receipt['branch']}` and `{worktree}`. Run evidence: `{run_dir}`.\n")
            raise RunnerError(f"review state is not durable; recovery at {run_dir}")
        summary_path = summary_matches[0] if summary_matches else str(active_summary[0])
        summary_text = git(repo, "show", f"origin/main:{summary_path}") if summary_matches else active_summary[0].read_text(encoding="utf-8", errors="replace")
        if not complete and not re.search(r"(?i)\b(blocked|blocker|partial|failed|incomplete|unable)\b", summary_text):
            metadata["phase"] = "failed_unexplained_active_review"
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Review workstream is active but its summary does not explain the blocker. Preserve `{receipt['branch']}` and `{worktree}`. Run evidence: `{run_dir}`.\n")
            raise RunnerError(f"active review lacks an explicit blocker explanation; recovery at {run_dir}")
        handoff = next_handoff(summary_text)
        metadata.update({"phase": "complete" if complete else "blocked_recoverable",
                         "durable_summary": summary_path, "archived_on_origin_main": archived,
                         "next_handoff": handoff})
        _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
        print(f"paired_review_runner: {'COMPLETE' if complete else 'BLOCKED_RECOVERABLE'} {workstream}")
        print(f"persistent summary: {summary_path}")
        if handoff:
            print("## Next Handoff\n" + handoff)
        if not complete:
            _write(run_dir / "RECOVERY.md", f"Review remains active/blocked with durable summary. Preserve `{receipt['branch']}` and `{worktree}`. Run evidence: `{run_dir}`.\n")
            return 2
        return exit_code


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("review_workstream", help="exact paired review workstream; global-next is unsupported")
    parser.add_argument("--timeout", type=float, default=None)
    args = parser.parse_args(argv)
    try:
        return run(Path.cwd(), args.review_workstream, timeout=args.timeout)
    except (RunnerError, OSError, subprocess.SubprocessError) as exc:
        print(f"paired_review_runner: BLOCKED: {redact(str(exc))}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
