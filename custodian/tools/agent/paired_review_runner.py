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
from review_receipt_delta import (
    read_git_text,
    resolve_target_implementation_commit,
    verify_review_receipt_delta,
)
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
        content = read_git_text(repo, "origin/main", path)
        packet = parse_packet(path, content)
        if packet.workstream == workstream:
            matches.append((path, content, packet))
    if len(matches) != 1:
        raise RunnerError(f"expected one active packet for {workstream}, found {len(matches)}")
    return matches[0]


def current_review_authority(content: str) -> str:
    """Keep current review gates while excluding explicitly scoped successor gates.

    A future handoff never gates the current review. A preceding
    ``## Refresh Planning Authority`` section, however, remains a current
    human gate unless it explicitly declares ``Refresh applies to: successor``
    AND the future handoff names a real next workstream. Missing or ambiguous
    scope fails closed.
    """
    handoff = re.search(r"(?im)^##[ \t]+(?:handoff|next handoff)[ \t]*$", content)
    authority = content[:handoff.start()] if handoff else content
    if not handoff:
        return authority
    next_workstream = re.search(
        r"(?im)^\s*-\s*Next workstream:\s*`?([a-z0-9-]+)`?\s*$",
        content[handoff.start():],
    )
    if not next_workstream or next_workstream.group(1) == "none":
        return authority

    sections = list(re.finditer(r"(?m)^##[ \t]+[^\r\n]+$", authority))
    for index in range(len(sections) - 1, -1, -1):
        heading = sections[index]
        if heading.group(0).strip().casefold() != "## refresh planning authority":
            continue
        end = sections[index + 1].start() if index + 1 < len(sections) else len(authority)
        body = authority[heading.end():end]
        if re.search(r"(?im)^\s*-\s*Refresh applies to:\s*`?successor`?\s*$", body):
            authority = authority[:heading.start()] + authority[end:]
    return authority


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
        target_content = read_git_text(repo, "origin/main", target_path)
    except ValueError as exc:
        raise RunnerError("completed review target is absent from origin/main") from exc
    target = parse_packet(target_path, target_content)
    if target.kind not in {"implementation", "correction"} or target.status != "complete":
        raise RunnerError("review target must be an archived, complete implementation/correction")
    if target_path != f"{PACKET_ROOT}/archived/{Path(target_path).name}":
        raise RunnerError("review target must be in the canonical archived packet directory")
    _, identity_error = resolve_target_implementation_commit(
        repo, git(repo, "rev-parse", "origin/main^{commit}"), target_path,
        packet.review_target_workstream, target_content,
    )
    if identity_error:
        raise RunnerError(f"review target implementation identity is invalid: {identity_error}")
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


def prompt_for(workstream: str, packet_path: str, target_path: str, *, run_dir: Path | None = None,
               authoring_chat: str | None = None, reviewed_main: str | None = None,
               implementation_commit: str | None = None) -> str:
    validation_path = str(run_dir / "validation.json") if run_dir else "the run evidence directory's validation.json"
    backlink = f"Use this exact Authoring chat URL in the summary: {authoring_chat}" if authoring_chat else "Preserve the packet's exact Authoring chat URL in the summary."
    pinned = f"Review the immutable baseline `origin/main` at `{reviewed_main}`; report this exact SHA in the review receipt." if reviewed_main else "Record the exact immutable reviewed-main SHA in the review receipt."
    implementation = (f"The exact reviewed implementation SHA derived from the pinned archived packet history is `{implementation_commit}`; report this exact SHA in the review receipt."
                      if implementation_commit else "Derive the implementation SHA from the exact archived target history; do not guess or use a reviewer-supplied value without verifying it.")
    return f"""You are the fresh independent paired reviewer for CUSTODIAN workstream `{workstream}`.

Reconstruct the review solely from durable repository evidence in this claimed worktree. Read `AGENTS.md`, `custodian/AGENTS.md`, `{packet_path}`, `{target_path}`, the target's root closing summary, and the landed diff/current main. {pinned} {implementation} Run every validation and fault-check required by the review packet. Do not use, request, or infer the implementation-session transcript. Do not edit reviewed implementation/runtime code. Record findings first, write the durable review receipt and required root summary. {backlink}

This is a restricted reviewer checkout. Do not run `git fetch`, `git push`, `git add`, `git commit`, `workstream.py checkpoint`, or `workstream.py finish`; shared Git metadata and landing belong to the coordinator. Do not remove the worktree or branch. If the target packet needs its receipt, append exactly one `### Review Receipt: {workstream}` block under `## Independent Review` (or append that section at EOF), preserving all existing target bytes. Use this exact field layout, substituting the review packet's exact target identity and the pinned main and implementation SHAs:

```markdown
### Review Receipt: {workstream}
- Schema: `custodian.paired_review.v1`
- Review workstream: `{workstream}`
- Review target workstream: `<exact target workstream>`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent` or `same-agent-fresh-context`
- Reviewed main: `<full pinned main SHA>`
- Reviewed implementation commit: `<full implementation SHA>`
```

Do not edit any other target bytes. Run the required validation and save its green structured JSON result to `{validation_path}` (schema `custodian.validation.result.v1`, with `passed: true`, `coverage.complete: true`, and all test statuses passed). Update/archive only the authorized review packet and managed index. If blocked, write the durable summary explaining the blocker and leave the packet/worktree recoverable. Do not claim another packet or hop to the global queue. Report the exact result and evidence paths."""


def validation_report_is_green(path: Path) -> bool:
    try:
        report = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return False
    tests = report.get("tests") if isinstance(report, dict) else None
    coverage = report.get("coverage") if isinstance(report, dict) else None
    return (report.get("schema") == "custodian.validation.result.v1" and report.get("passed") is True
            and isinstance(coverage, dict) and coverage.get("complete") is True
            and isinstance(tests, list) and bool(tests)
            and all(isinstance(test, dict) and test.get("status") == "passed" for test in tests))


def _changed_paths(repo: Path, *args: str) -> list[str]:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True)
    if result.returncode:
        raise RunnerError(redact(result.stderr or result.stdout))
    return [line for line in result.stdout.splitlines() if line]


def coordinator_finish_review(repo: Path, workstream: str, worktree: Path, active_packet_path: str,
                              target_workstream: str, target_packet_path: str, target_content: str,
                              authoring_chat: str | None, reviewed_main: str, run_dir: Path) -> str:
    """Commit only bounded reviewer evidence and delegate landing to workstream.py."""
    report = run_dir / "validation.json"
    if not validation_report_is_green(report):
        raise RunnerError(f"reviewer did not provide a green structured validation report: {report}")
    summary_path = expected_summary_path(workstream)
    archive_path = f"{PACKET_ROOT}/archived/{Path(active_packet_path).name}"
    allowed = {active_packet_path, archive_path, f"{PACKET_ROOT}/README.md", summary_path, target_packet_path}
    changed = set(_changed_paths(worktree, "diff", "--name-only", "origin/main...HEAD"))
    changed.update(_changed_paths(worktree, "diff", "--name-only", "HEAD"))
    changed.update(_changed_paths(worktree, "diff", "--cached", "--name-only"))
    changed.update(_changed_paths(worktree, "ls-files", "--others", "--exclude-standard"))
    unexpected = sorted(changed - allowed)
    if unexpected:
        raise RunnerError("reviewer changed files outside its bounded evidence scope: " + ", ".join(unexpected))
    implementation_commit, identity_error = resolve_target_implementation_commit(
        repo, reviewed_main, target_packet_path, target_workstream, target_content,
    )
    if identity_error:
        raise RunnerError("reviewed target implementation identity is invalid: " + identity_error)
    _, receipt_error = verify_review_receipt_delta(
        target_content, (worktree / target_packet_path).read_bytes().decode("utf-8"),
        review_workstream=workstream, target_workstream=target_workstream,
        reviewed_main=reviewed_main,
        target_implementation_commit=implementation_commit,
    )
    if receipt_error:
        raise RunnerError("reviewed target failed pinned receipt-delta verification: " + receipt_error)
    if not (worktree / archive_path).is_file() or not (worktree / summary_path).is_file():
        raise RunnerError("reviewer did not write the archived packet and exact root summary")
    if _changed_paths(worktree, "diff", "--cached", "--name-only"):
        raise RunnerError("reviewer staged evidence before coordinator authorization")
    staged = subprocess.run(["git", "add", "-A", "--", *sorted(allowed)], cwd=worktree, text=True, capture_output=True)
    if staged.returncode:
        raise RunnerError(redact(staged.stderr or staged.stdout))
    staged_paths = set(_changed_paths(worktree, "diff", "--cached", "--name-only"))
    if not staged_paths or staged_paths - allowed:
        raise RunnerError("coordinator staged no review evidence or staged an unauthorized path")
    committed = subprocess.run(["git", "commit", "-m", "paired review receipt, closeout"], cwd=worktree,
                               text=True, capture_output=True)
    if committed.returncode:
        raise RunnerError(redact(committed.stderr or committed.stdout))
    branch_head = git(worktree, "rev-parse", "--verify", "HEAD^{commit}")
    branch_state = landed_review_state(repo, branch_head, workstream, active_packet_path,
                                       target_workstream, target_packet_path, target_content,
                                       authoring_chat, reviewed_main)
    if not branch_state["complete"]:
        raise RunnerError("review evidence failed exact pre-land verification: " + "; ".join(branch_state["reasons"]))
    finish_cmd = [sys.executable, str(repo / "custodian/tools/agent/workstream.py"), "finish", workstream,
                  "--validation-report", str(report)]
    finished = subprocess.run(finish_cmd, cwd=repo, text=True, capture_output=True)
    finish_output = finished.stderr + finished.stdout
    if finished.returncode and "provide a green --validation-report-after-sync" in finish_output:
        after_sync_report = run_dir / "validation-after-sync.json"
        validation = subprocess.run([sys.executable, str(repo / "custodian/tools/validation/run_validation.py"),
                                     "--changed", "--json"], cwd=worktree, text=True, capture_output=True)
        if validation.returncode:
            raise RunnerError("post-sync changed-file validation failed; recovery retained: "
                              + redact(validation.stderr or validation.stdout))
        _write(after_sync_report, validation.stdout)
        if not validation_report_is_green(after_sync_report):
            raise RunnerError("post-sync changed-file validation report is not green; recovery retained")
        retry = finish_cmd + ["--validation-report-after-sync", str(after_sync_report)]
        finished = subprocess.run(retry, cwd=repo, text=True, capture_output=True)
    if finished.returncode:
        raise RunnerError("coordinator workstream finish failed; branch and evidence preserved: "
                          + redact(finished.stderr or finished.stdout))
    landed = re.search(r"verified ([0-9a-f]{40,64}) reachable from origin/main", finished.stdout + finished.stderr)
    if not landed:
        raise RunnerError("workstream finish did not return its verified landed commit; inspect preserved run evidence")
    return landed.group(1)


def _write(path: Path, value: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding="utf-8")


def unresolved_prior_run(common: Path, workstream: str, current_run_id: str) -> Path | None:
    """Find a prior post-claim run that must be recovered before any new claim."""
    safe_phases = {"preflight_complete", "claim_failed", "complete"}
    for metadata_path in sorted((common / "custodian-review-runs" / workstream).glob("*/metadata.json")):
        if metadata_path.parent.name == current_run_id:
            continue
        try:
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return metadata_path.parent
        if metadata.get("workstream") == workstream and metadata.get("phase") not in safe_phases:
            return metadata_path.parent
    return None


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


def expected_summary_path(workstream: str) -> str:
    """Return the one canonical root summary path used by workstream.py."""
    return f"{workstream.upper().replace('-', '_')}_CLAUDE_SUMMARY.md"


def _show_at(repo: Path, revision: str, path: str) -> str:
    """Read one exact path from one pinned commit (never a grep result)."""
    try:
        return read_git_text(repo, revision, path)
    except ValueError as exc:
        raise RunnerError(redact(str(exc))) from exc


def fetch_and_pin_main(repo: Path) -> str:
    """Fetch successfully, then return the immutable commit used for verification."""
    git(repo, "fetch", "origin", "main")
    revision = git(repo, "rev-parse", "--verify", "origin/main^{commit}")
    if not re.fullmatch(r"[0-9a-f]{40,64}", revision):
        raise RunnerError("origin/main did not resolve to a full commit ID")
    return revision


def landed_review_state(repo: Path, revision: str, workstream: str, review_packet_path: str,
                        target_workstream: str, target_packet_path: str,
                        expected_target_content: str, authoring_chat: str | None,
                        reviewed_main: str | None = None) -> dict:
    """Verify completion from exact archived packet, summary and receipt paths."""
    archive_path = f"{PACKET_ROOT}/archived/{Path(review_packet_path).name}"
    result = {"complete": False, "revision": revision, "summary_path": expected_summary_path(workstream),
              "reasons": []}
    try:
        archived_text = _show_at(repo, revision, archive_path)
        summary_text = _show_at(repo, revision, result["summary_path"])
        target_text = _show_at(repo, revision, target_packet_path)
    except RunnerError as exc:
        result["reasons"].append(str(exc))
        return result

    archived = parse_packet(archive_path, archived_text)
    target = parse_packet(target_packet_path, target_text)
    if archived.error or archived.kind != "review" or archived.status != "complete" or archived.workstream != workstream:
        result["reasons"].append("exact archived review packet is not complete")
    if archived.review_target_workstream != target_workstream or archived.review_target_packet != target_packet_path:
        result["reasons"].append("archived review packet names a different target")
    archived_receipt = _independent_review_receipt(archived_text)
    if archived_receipt is None:
        result["reasons"].append("archived review packet has no unambiguous independent review receipt")
    else:
        for key, expected in (("Schema", "custodian.paired_review.v1"),
                              ("Review target workstream", target_workstream),
                              ("Status", "passed"), ("Blocking defects", "0"),
                              ("Material gaps", "0"), ("Reviewer context", "fresh")):
            if archived_receipt.get(key) != expected:
                result["reasons"].append(f"archived review receipt has missing or mismatched {key}")
        if archived_receipt.get("Reviewer provenance") not in {"different-agent", "same-agent-fresh-context"}:
            result["reasons"].append("archived review receipt has missing or invalid reviewer provenance")
        if archived_receipt.get("Review workstream", workstream) != workstream:
            result["reasons"].append("archived review receipt identifies a different review workstream")
        if reviewed_main and archived_receipt.get("Reviewed main") != reviewed_main:
            result["reasons"].append("archived review receipt does not match the pinned reviewed main")
    if target.error or target.kind not in {"implementation", "correction"} or target.workstream != target_workstream or target.status != "complete":
        result["reasons"].append("exact reviewed implementation packet is not complete")
    implementation_commit, identity_error = resolve_target_implementation_commit(
        repo, reviewed_main or "", target_packet_path, target_workstream, expected_target_content,
    )
    receipt, receipt_error = verify_review_receipt_delta(
        expected_target_content, target_text, review_workstream=workstream,
        target_workstream=target_workstream, reviewed_main=reviewed_main or "",
        target_implementation_commit=implementation_commit,
    )
    if identity_error:
        result["reasons"].append(identity_error)
    if receipt_error:
        result["reasons"].append(receipt_error)
    if authoring_chat and archived.authoring_chat != authoring_chat:
        result["reasons"].append("archived review packet changed its authoring-chat identity")
    if reviewed_main and subprocess.run(["git", "merge-base", "--is-ancestor", reviewed_main, revision],
                                        cwd=repo, text=True, capture_output=True).returncode:
        result["reasons"].append("pinned post-review main is not descended from the reviewed main")

    reviewed_commit_value = receipt.get("Reviewed implementation commit") if receipt else None
    if not reviewed_commit_value:
        result["reasons"].append("independent review receipt is absent or not passed")
    if reviewed_commit_value and implementation_commit:
        commit = reviewed_commit_value
        if archived_receipt and archived_receipt.get("Reviewed implementation commit") != commit:
            result["reasons"].append("archived review receipt names a different implementation commit than target receipt")
        target_full = git(repo, "rev-parse", "--verify", f"{implementation_commit or ''}^{{commit}}", check=False)
        review_full = git(repo, "rev-parse", "--verify", f"{commit}^{{commit}}", check=False)
        if not target_full or target_full != review_full:
            result["reasons"].append("review receipt names a different implementation commit than the archived target")
        if subprocess.run(["git", "cat-file", "-e", f"{commit}^{{commit}}"], cwd=repo,
                          text=True, capture_output=True).returncode:
            result["reasons"].append("reviewed implementation commit is unavailable")
        elif subprocess.run(["git", "merge-base", "--is-ancestor", commit, revision], cwd=repo,
                            text=True, capture_output=True).returncode:
            result["reasons"].append("reviewed implementation commit is not an ancestor of pinned main")
    result["reviewed_implementation_commit"] = reviewed_commit_value
    if authoring_chat and f"Authoring chat: {authoring_chat}" not in summary_text:
        result["reasons"].append("exact closing summary is missing the packet authoring-chat backlink")
    if not next_handoff(summary_text):
        result["reasons"].append("exact closing summary omits Next Handoff")
    result["complete"] = not result["reasons"]
    return result


def _independent_review_receipt(packet_text: str) -> dict[str, str] | None:
    """Parse a single flat receipt from the archived reviewer-authored packet."""
    matches = list(re.finditer(r"(?m)^## Independent Review[ \t]*$", packet_text))
    if len(matches) != 1:
        return None
    section = packet_text[matches[0].end():]
    next_section = re.search(r"(?m)^## [^\r]*$", section)
    if next_section:
        section = section[:next_section.start()]
    result: dict[str, str] = {}
    for name in ("Schema", "Review workstream", "Review target workstream", "Status",
                 "Blocking defects", "Material gaps", "Reviewer context", "Reviewer provenance",
                 "Reviewed main", "Reviewed implementation commit"):
        values = re.findall(rf"(?m)^- {re.escape(name)}: `?([^`\r\n]+)`?\s*$", section)
        if len(values) == 1:
            result[name] = values[0].strip()
    return result


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
        prior_run = unresolved_prior_run(common, workstream, run_id)
        if prior_run:
            metadata.update({"phase": "blocked_prior_recovery", "prior_run_dir": str(prior_run)})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"A prior run for `{workstream}` passed claim and has unresolved state. Recover it before another review claim. Prior evidence: `{prior_run}`. No new dispatcher claim was attempted.\n")
            raise RunnerError(f"prior claimed review needs recovery before retry; inspect {prior_run}; no new claim attempted")
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
        # Pin the baseline from the claimed checkout after dispatch has finished
        # synchronizing it. Keep the SHA and target bytes fixed for the full run.
        reviewed_main = git(worktree, "rev-parse", "--verify", "origin/main^{commit}")
        try:
            target_content = read_git_text(worktree, reviewed_main, packet.review_target_packet)
        except ValueError as exc:
            raise RunnerError("claimed review target is absent from its pinned main") from exc
        implementation_commit, identity_error = resolve_target_implementation_commit(
            worktree, reviewed_main, packet.review_target_packet,
            packet.review_target_workstream or "", target_content,
        )
        if identity_error:
            raise RunnerError("claimed review target implementation identity is invalid: " + identity_error)
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
                                      packet.review_target_packet or "", run_dir=run_dir,
                                      authoring_chat=packet.authoring_chat,
                                      reviewed_main=reviewed_main,
                                      implementation_commit=implementation_commit), run_dir, timeout)
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

        try:
            # A failed fetch cannot be replaced with stale refs or reviewer-local files.
            pinned_main = fetch_and_pin_main(repo)
            if exit_code == 0:
                pinned_main = coordinator_finish_review(repo, workstream, worktree, actual_path,
                                                       packet.review_target_workstream or "",
                                                       packet.review_target_packet or "", target_content,
                                                       packet.authoring_chat, reviewed_main, run_dir)
            state = landed_review_state(repo, pinned_main, workstream, actual_path,
                                        packet.review_target_workstream or "",
                                        packet.review_target_packet or "", target_content,
                                        packet.authoring_chat, reviewed_main)
        except RunnerError as exc:
            metadata.update({"phase": "post_exit_recovery", "reviewed_main": reviewed_main,
                             "post_exit_error": redact(str(exc)), "recovery_worktree": str(worktree)})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Coordinator could not verify/land review evidence: {redact(str(exc))}. Preserve `{receipt['branch']}` and `{worktree}`. Run evidence: `{run_dir}`. Do not reclaim the review.\n")
            raise RunnerError(f"post-exit coordinator recovery required; preserve claim at {worktree}; evidence: {run_dir}") from exc
        complete = state["complete"]
        if exit_code == 0 and not complete:
            metadata.update({"phase": "failed_missing_durable_review_state", "post_exit_state": state})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Codex exited 0 but exact landed review evidence is incomplete: {state['reasons']}. Preserve `{receipt['branch']}` and `{worktree}`. Run evidence: `{run_dir}`.\n")
            raise RunnerError(f"Codex exited 0 without durable review state; recovery at {run_dir}")
        summary_path = state["summary_path"]
        try:
            summary_text = _show_at(repo, pinned_main, summary_path)
        except RunnerError:
            summary_text = ""
        if not complete and not re.search(r"(?i)\b(blocked|blocker|partial|failed|incomplete|unable)\b", summary_text):
            metadata["phase"] = "failed_unexplained_active_review"
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Review workstream is active but its summary does not explain the blocker. Preserve `{receipt['branch']}` and `{worktree}`. Run evidence: `{run_dir}`.\n")
            raise RunnerError(f"active review lacks an explicit blocker explanation; recovery at {run_dir}")
        handoff = next_handoff(summary_text)
        metadata.update({"phase": "complete" if complete else "blocked_recoverable",
                         "reviewed_main": reviewed_main, "post_exit_main": pinned_main,
                         "durable_summary": summary_path, "archived_on_origin_main": complete,
                         "post_exit_state": state,
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
