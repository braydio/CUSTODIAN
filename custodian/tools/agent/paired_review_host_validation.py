"""Coordinator-side validation evidence for restricted paired-review sessions."""
from __future__ import annotations

import hashlib
import json
import os
import re
import socket
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Callable

from godot_project_lock import godot_home
from task_packet_contract import PACKET_ROOT


class HostValidationError(RuntimeError):
    pass


_IMPLEMENTATION_SUFFIXES = {".gd", ".py", ".gdshader", ".tscn", ".tres", ".json"}


def _git(worktree: Path, *args: str) -> str:
    result = subprocess.run(["git", *args], cwd=worktree, text=True, capture_output=True)
    if result.returncode:
        raise HostValidationError(result.stderr.strip() or result.stdout.strip() or "git identity check failed")
    return result.stdout.strip()


def _git_paths(worktree: Path, revision: str) -> list[str]:
    result = subprocess.run(["git", "diff", "--name-only", revision], cwd=worktree,
                            text=True, capture_output=True)
    if result.returncode:
        raise HostValidationError(result.stderr.strip() or "could not enumerate validation source paths")
    return sorted({path for path in result.stdout.splitlines() if path})


def _write_exclusive(path: Path, contents: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(contents)
            stream.flush()
            os.fsync(stream.fileno())
        try:
            os.link(temporary, path)
        except FileExistsError as exc:
            raise HostValidationError(f"refusing to replace preexisting review evidence: {path.name}") from exc
        directory_fd = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
    finally:
        if temporary is not None:
            try:
                os.unlink(temporary)
            except FileNotFoundError:
                pass


def probe_host_capabilities() -> dict[str, bool]:
    """Verify the coordinator can bind loopback and write the isolated Godot HOME."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
            probe.bind(("127.0.0.1", 0))
    except OSError as exc:
        raise HostValidationError(f"coordinator loopback socket preflight failed: {exc}") from exc
    home = godot_home()
    try:
        with tempfile.NamedTemporaryFile(prefix="paired-review-home-probe-", dir=home):
            pass
    except OSError as exc:
        raise HostValidationError(f"isolated Godot HOME is not writable: {exc}") from exc
    return {"loopback_bind": True, "godot_home_writable": True}


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _source_hashes(worktree: Path, paths: list[str]) -> dict[str, str]:
    values = {}
    for relative in paths:
        path = worktree / relative
        if not path.is_file():
            raise HostValidationError(f"implementation diff source is missing: {relative}")
        values[relative] = _sha256(path.read_bytes())
    return values


def _changed_paths(repo: Path, revision: str) -> list[str]:
    result = subprocess.run(["git", "diff", "--name-only", "--no-renames", revision], cwd=repo,
                            text=True, capture_output=True)
    if result.returncode:
        raise HostValidationError(result.stderr.strip() or "could not enumerate source-span paths")
    return sorted({path for path in result.stdout.splitlines() if path})


def _source_code_paths(paths: list[str]) -> set[str]:
    return {path for path in paths if Path(path).suffix.lower() in _IMPLEMENTATION_SUFFIXES}


def _trace_events(repo: Path, ref: str) -> list[dict]:
    result = subprocess.run(["git", "show", f"{ref}:trace.jsonl"], cwd=repo,
                            text=True, capture_output=True)
    if result.returncode:
        raise HostValidationError(f"source-span workstream trace is unreadable: {ref}")
    events = []
    try:
        for line in result.stdout.splitlines():
            value = json.loads(line)
            if not isinstance(value, dict):
                raise ValueError("event is not an object")
            events.append(value)
    except (json.JSONDecodeError, ValueError) as exc:
        raise HostValidationError(f"source-span workstream trace is malformed: {ref}") from exc
    if not events:
        raise HostValidationError(f"source-span workstream trace is empty: {ref}")
    if any(event.get("schema") != "custodian.workflow_trace_event.v1"
           or event.get("schema_version") != 1
           or not isinstance(event.get("data"), dict) for event in events):
        raise HostValidationError(f"source-span workstream trace has invalid event provenance: {ref}")
    return events


def _split_landing_source_span(repo: Path, reviewed_main: str, landing_commit: str,
                               target_workstream: str, target_packet_path: str,
                               target_packet_text: str) -> dict:
    """Resolve an archive landing to its exact source-bearing workstream range.

    The archive-introduction commit remains the canonical implementation identity.
    One immutable lifecycle trace may pin that commit directly, or pin a verified
    two-parent main-sync merge whose first parent is the archive commit. The
    immediately preceding source span must be a linear first-parent range and its
    implementation paths must be named by the archived packet.
    """
    active_packet = target_packet_path.replace("/archived/", "/", 1)
    prefix = f"refs/remotes/origin/agent-diagnostics/{target_workstream}/"
    refs = subprocess.run(["git", "for-each-ref", "--format=%(refname)", prefix],
                          cwd=repo, text=True, capture_output=True)
    if refs.returncode:
        raise HostValidationError("could not enumerate committed source-span workstream traces")
    claim_records = []
    landing_records = []
    legacy_records = []
    for ref in refs.stdout.splitlines():
        events = _trace_events(repo, ref)
        run_ids = {event.get("run_id") for event in events}
        if len(run_ids) != 1:
            continue
        run_id = next(iter(run_ids))
        if not ref.endswith("/" + str(run_id)):
            continue
        if any(event.get("workstream") != target_workstream or event.get("packet") != active_packet
               for event in events):
            continue
        started = [event for event in events if event.get("event") == "remote_claim_acquired"]
        published = [event for event in events if event.get("event") == "worktree_published"]
        landing_started = [event for event in events if event.get("event") == "landing_started"]
        landed = [event for event in events if event.get("event") == "landing_completed"]
        teardown_started = [event for event in events if event.get("event") == "teardown_started"]
        teardown_completed = [event for event in events if event.get("event") == "teardown_completed"]
        branch = f"agent/{target_workstream}"
        if len(started) == len(published) == 1 and not landing_started and not landed:
            claim, publication = started[0]["data"], published[0]["data"]
            base, path = claim.get("main_sha"), publication.get("worktree")
            if (isinstance(base, str) and re.fullmatch(r"[0-9a-f]{40,64}", base)
                    and publication.get("head") == base and publication.get("upstream") == base
                    and publication.get("branch") == branch and publication.get("clean") is True
                    and isinstance(path, str) and Path(path).is_absolute()
                    and claim.get("remote_ref") == f"refs/heads/dispatch-claims/{target_workstream}"
                    and isinstance(claim.get("claim_oid"), str)
                    and re.fullmatch(r"[0-9a-f]{40,64}", claim["claim_oid"])):
                claim_records.append({"ref": ref, "run_id": run_id, "base": base,
                                      "branch": branch, "worktree": path, "events": events})
            continue
        if (not published and len(landing_started) == len(landed) == len(teardown_started) == len(teardown_completed) == 1
                and len(started) <= 1):
            start_data, landed_data = landing_started[0]["data"], landed[0]["data"]
            trace_landing = start_data.get("start_sha")
            teardown_data, removed_data = teardown_started[0]["data"], teardown_completed[0]["data"]
            path = teardown_data.get("worktree")
            if (isinstance(trace_landing, str) and re.fullmatch(r"[0-9a-f]{40,64}", trace_landing)
                    and start_data.get("branch") == branch and start_data.get("target") == "main"
                    and landed_data.get("head") == trace_landing and landed_data.get("outcome") == "landed"
                    and teardown_data.get("head") == trace_landing and teardown_data.get("branch") == branch
                    and removed_data.get("head") == trace_landing and removed_data.get("branch") == branch
                    and removed_data.get("worktree_removed") is True and isinstance(path, str)
                    and Path(path).is_absolute()):
                landing_records.append({"ref": ref, "run_id": run_id, "landing": trace_landing,
                                        "path": path, "branch": branch, "events": events})
            continue
        if (len(started) == len(published) == len(landing_started) == len(landed) == 1
                and not teardown_started and not teardown_completed):
            claim, publication = started[0]["data"], published[0]["data"]
            start_data, landed_data = landing_started[0]["data"], landed[0]["data"]
            base, trace_landing = claim.get("main_sha"), start_data.get("start_sha")
            path = publication.get("worktree")
            if (isinstance(base, str) and publication.get("head") == base
                    and publication.get("branch") == branch and start_data.get("branch") == branch
                    and isinstance(trace_landing, str) and landed_data.get("head") == trace_landing):
                legacy_records.append((ref, run_id, base, trace_landing, path, events))
            continue
        if len(landing_started) != 1 or len(landed) != 1:
            continue
        start_data, landed_data = landing_started[0]["data"], landed[0]["data"]
        trace_landing = start_data.get("start_sha")
        if (not isinstance(trace_landing, str) or not re.fullmatch(r"[0-9a-f]{40,64}", trace_landing)
                or start_data.get("branch") != branch or start_data.get("target") != "main"
                or landed_data.get("head") != trace_landing):
            continue
        if teardown_started or teardown_completed:
            if len(teardown_started) != 1 or len(teardown_completed) != 1:
                continue
            teardown_data, removed_data = teardown_started[0]["data"], teardown_completed[0]["data"]
            path = teardown_data.get("worktree")
            if (landed_data.get("outcome") != "landed"
                    or teardown_data.get("head") != trace_landing or teardown_data.get("branch") != branch
                    or removed_data.get("head") != trace_landing or removed_data.get("branch") != branch
                    or (removed_data.get("worktree") is not None
                        and removed_data.get("worktree") != path)
                    or removed_data.get("worktree_removed") is not True
                    or not isinstance(path, str) or not Path(path).is_absolute()):
                continue
        else:
            path = None
        if len(started) > 1 or len(published) > 1:
            continue
        if started:
            # A landing trace may preserve an earlier failed claim attempt. It
            # is not sufficient provenance alone; cross-check its base against
            # the independently validated claim record below.
            if started[0]["data"].get("main_sha") is None:
                continue
        landing_records.append({"ref": ref, "run_id": run_id, "landing": trace_landing,
                                "path": path, "branch": branch, "events": events})

        # Support older single-trace lifecycles that contain claim, publication,
        # landing, and teardown together. The same strict field checks apply to
        # each role, and pair uniqueness below prevents ambiguous reuse.
        if len(started) == len(published) == 1:
            claim, publication = started[0]["data"], published[0]["data"]
            base, published_path = claim.get("main_sha"), publication.get("worktree")
            if (isinstance(base, str) and re.fullmatch(r"[0-9a-f]{40,64}", base)
                    and publication.get("head") == base and publication.get("upstream") == base
                    and publication.get("branch") == branch and publication.get("clean") is True
                    and isinstance(published_path, str) and Path(published_path).is_absolute()
                    and published_path == path
                    and claim.get("remote_ref") == f"refs/heads/dispatch-claims/{target_workstream}"
                    and isinstance(claim.get("claim_oid"), str)
                    and re.fullmatch(r"[0-9a-f]{40,64}", claim["claim_oid"])):
                claim_records.append({"ref": ref, "run_id": run_id, "base": base,
                                      "branch": branch, "worktree": published_path,
                                      "events": events})

    # Bind the two trace roles independently. A landing trace can preserve an
    # earlier failed remote-claim attempt; its teardown path identifies the
    # published checkout, while the exact claim base is checked against it.
    if not claim_records and len(legacy_records) == 1:
        ref, run_id, base, trace_landing, path, events = legacy_records[0]
        claim_records.append({"ref": ref, "run_id": run_id, "base": base,
                              "branch": f"agent/{target_workstream}", "worktree": path,
                              "events": events})
        landing_records.append({"ref": ref, "run_id": run_id, "landing": trace_landing,
                                "path": path, "branch": f"agent/{target_workstream}",
                                "events": events})
    recorded_main = re.findall(r"(?im)^- Reviewed main:\s*`?([0-9a-f]{40,64})`?\s*$",
                               target_packet_text)
    if len(recorded_main) != 1:
        raise HostValidationError("split target packet has missing or ambiguous Reviewed main provenance")
    exact_base = recorded_main[0]
    matching_pairs = []
    for claim in claim_records:
        for completed in landing_records:
            if (claim["worktree"] == completed["path"]
                    and claim["branch"] == completed["branch"]
                    and subprocess.run(["git", "merge-base", "--is-ancestor", exact_base,
                                        claim["base"]], cwd=repo, capture_output=True).returncode == 0
                    and subprocess.run(["git", "merge-base", "--is-ancestor", exact_base,
                                        completed["landing"]], cwd=repo, capture_output=True).returncode == 0):
                failed_claims = [event["data"] for event in completed["events"]
                                 if event.get("event") == "remote_claim_acquired"]
                if any(item.get("main_sha") != claim["base"] for item in failed_claims):
                    continue
                matching_pairs.append((claim, completed))
    if len(matching_pairs) != 1:
        raise HostValidationError("split landing has missing or ambiguous exact workstream trace provenance")
    claim_record, landing_record = matching_pairs[0]
    source_base = claim_record["base"]
    trace_landing = landing_record["landing"]
    ref, run_id, events = landing_record["ref"], landing_record["run_id"], landing_record["events"]

    for sha, label in ((source_base, "source base"), (recorded_main[0], "packet Reviewed main"),
                       (landing_commit, "canonical landing"), (trace_landing, "trace landing"),
                       (reviewed_main, "pinned reviewed main")):
        resolved = subprocess.run(["git", "rev-parse", "--verify", f"{sha}^{{commit}}"], cwd=repo,
                                  text=True, capture_output=True)
        if resolved.returncode or resolved.stdout.strip() != sha:
            raise HostValidationError(f"split landing {label} is not an available full commit SHA")
    if subprocess.run(["git", "merge-base", "--is-ancestor", recorded_main[0], source_base],
                      cwd=repo, capture_output=True).returncode:
        raise HostValidationError("source-span base does not descend from packet Reviewed main")
    if subprocess.run(["git", "merge-base", "--is-ancestor", source_base, landing_commit],
                      cwd=repo, capture_output=True).returncode:
        raise HostValidationError("source-span base is not an ancestor of the canonical landing")

    # A legitimate synchronization merge is narrowly bound by both its parent
    # order and the immutable lifecycle main_sync event. Do not derive the source
    # span from this merge: it may contain unrelated changes from prior main.
    trace_landing_kind = "canonical-archive"
    trace_main_sync_sha = None
    if trace_landing != landing_commit:
        parent_line = _git(repo, "rev-list", "--parents", "-n", "1", trace_landing).split()
        if len(parent_line) != 3 or parent_line[1] != landing_commit:
            raise HostValidationError("trace landing is not the exact two-parent archive-first main-sync merge")
        second_parent = parent_line[2]
        sync_events = [event for event in events
                       if event.get("event") == "main_sync"
                       and event.get("data", {}).get("changed") is True
                       and event.get("data", {}).get("head") == trace_landing]
        if (len(sync_events) != 1
                or sync_events[0].get("data", {}).get("main_sha") != second_parent):
            raise HostValidationError("trace landing lacks an exact main-sync merge provenance event")
        trace_landing_kind = "main-sync-merge"
        trace_main_sync_sha = second_parent
    if subprocess.run(["git", "merge-base", "--is-ancestor", trace_landing, reviewed_main],
                      cwd=repo, capture_output=True).returncode:
        raise HostValidationError("trace landing is not an ancestor of pinned reviewed main")

    # Validate the canonical archive commit independently of the later main-sync
    # merge. Its allowed closeout consists only of this packet's active deletion,
    # archived creation, exact root summary and generated packet index.
    archive_parent_line = _git(repo, "rev-list", "--parents", "-n", "1", landing_commit).split()
    if len(archive_parent_line) != 2:
        raise HostValidationError("canonical archive landing must have exactly one parent")
    archive_parent = archive_parent_line[1]
    archive_paths = set(_changed_paths(repo, f"{archive_parent}..{landing_commit}"))
    summary_path = f"{target_workstream.upper().replace('-', '_')}_CLAUDE_SUMMARY.md"
    allowed_archive_paths = {active_packet, target_packet_path, summary_path,
                             f"{PACKET_ROOT}/README.md"}
    if not {active_packet, target_packet_path}.issubset(archive_paths):
        raise HostValidationError("archive landing is missing its active or archived packet closeout")

    extra_archive_paths = archive_paths - allowed_archive_paths
    source_bearing_archive = bool(extra_archive_paths)
    if source_bearing_archive:
        if any(Path(path).suffix.lower() not in _IMPLEMENTATION_SUFFIXES
               for path in extra_archive_paths):
            raise HostValidationError("archive-only landing contains unrelated paths")
    elif archive_paths - allowed_archive_paths:
        raise HostValidationError("archive-only landing contains unrelated paths")

    def has_path(revision: str, path: str) -> bool:
        result = subprocess.run(["git", "cat-file", "-e", f"{revision}:{path}"], cwd=repo,
                                capture_output=True)
        return result.returncode == 0

    if (not has_path(archive_parent, active_packet) or has_path(landing_commit, active_packet)
            or has_path(archive_parent, target_packet_path) or not has_path(landing_commit, target_packet_path)):
        raise HostValidationError("archive-only landing does not delete the active packet and create its canonical archive")
    # Archive closeout and source-bearing paths must all be regular, non-executable files.
    for revision in (archive_parent, landing_commit):
        for path in archive_paths:
            result = subprocess.run(["git", "ls-tree", "-z", revision, "--", path],
                                    cwd=repo, capture_output=True)
            if result.returncode:
                raise HostValidationError("could not inspect archive closeout file modes")
            if result.stdout:
                mode = result.stdout.split(b"\t", 1)[0].split()[0]
                if mode != b"100644":
                    raise HostValidationError("archive landing contains an executable or non-regular path")

    # A source-bearing archive includes its final source/test edits. An archive-
    # only closeout ends at its parent. Neither span includes a later main-sync.
    source_head = landing_commit if source_bearing_archive else archive_parent
    chain = subprocess.run(["git", "rev-list", "--first-parent", "--reverse",
                            f"{source_base}..{source_head}"], cwd=repo,
                           text=True, capture_output=True)
    if chain.returncode or not chain.stdout.splitlines():
        raise HostValidationError("split landing has no source-bearing commits after its recorded workstream base")
    commits = chain.stdout.splitlines()
    for commit in commits:
        parent_count = len(_git(repo, "rev-list", "--parents", "-n", "1", commit).split()) - 1
        if parent_count != 1:
            raise HostValidationError("split source span contains merge ancestry")
    if (source_bearing_archive and commits[-1] != landing_commit
            or not source_bearing_archive and archive_parent != commits[-1]):
        raise HostValidationError("split source span does not end at its canonical archive boundary")
    source_paths = _changed_paths(repo, f"{source_base}..{source_head}")
    code_paths = _source_code_paths(source_paths)
    if not code_paths:
        raise HostValidationError("split source span contains no implementation source or test files")

    # The archived task must itself identify every source/test path so a branch
    # carrying unrelated code cannot be laundered through an archive-only commit.
    documented = set(re.findall(r"custodian/[A-Za-z0-9_./-]+", target_packet_text))
    documented.add(f"{target_workstream.upper().replace('-', '_')}_CLAUDE_SUMMARY.md")
    packet_terms = set(re.findall(r"[a-z0-9]+", target_packet_text.lower()))
    archive_source_paths = set(extra_archive_paths) if source_bearing_archive else set()

    def is_documented(path: str) -> bool:
        if path in archive_source_paths and path in documented:
            return True
        name = Path(path).name
        if path in documented or name in target_packet_text:
            return True
        # Some packets authorize a specific test fixture by role in Work surface
        # without spelling its full path. Require multiple distinctive filename
        # terms from the packet; host report coverage still proves a selected test
        # owns each such source/test file.
        if name.startswith("test_") and re.search(r"\b(test|tests|fixture)\b", target_packet_text, re.I):
            terms = set(re.findall(r"[a-z0-9]+", Path(name).stem.lower())) - {"test", "tests", "v1"}
            return len(terms & packet_terms) >= 2
        return False

    undocumented = {path for path in code_paths if not is_documented(path)}
    undocumented.update(path for path in archive_source_paths if not is_documented(path))
    if undocumented:
        raise HostValidationError("split source span contains code/test paths not documented by its target packet")

    if trace_landing_kind == "main-sync-merge":
        changed_in_merge = set(_changed_paths(repo, f"{landing_commit}..{trace_landing}"))
        if target_packet_path in changed_in_merge:
            raise HostValidationError("main-sync merge changes archived target packet from archive-first-parent version")
        if changed_in_merge.intersection(source_paths):
            raise HostValidationError("main-sync merge changes reviewed source from archive-first-parent version")

    trace_sha = subprocess.run(["git", "rev-parse", "--verify", f"{ref}^{{commit}}"], cwd=repo,
                               text=True, capture_output=True, check=True).stdout.strip()
    trace_blob = subprocess.run(["git", "show", f"{ref}:trace.jsonl"], cwd=repo,
                                capture_output=True, check=True).stdout
    return {"base": source_base, "head": source_head, "commits": commits,
            "paths": source_paths, "provenance": {"kind": "workstream-lifecycle-trace",
            "ref": ref, "trace_commit": trace_sha, "trace_sha256": _sha256(trace_blob),
            "run_id": run_id, "workstream": target_workstream,
            "trace_landing_commit": trace_landing,
            "trace_landing_kind": trace_landing_kind,
            "trace_main_sync_sha": trace_main_sync_sha,
            "claim_trace": {"ref": claim_record["ref"], "run_id": claim_record["run_id"],
                            "worktree": claim_record["worktree"], "branch": claim_record["branch"],
                            "base": claim_record["base"]},
            "landing_trace": {"ref": landing_record["ref"], "run_id": landing_record["run_id"],
                              "worktree": landing_record["path"], "branch": landing_record["branch"],
                              "landing": landing_record["landing"]},
            "archive_kind": "source-bearing" if source_bearing_archive else "archive-only"}}


def resolve_validation_source_span(repo: Path, reviewed_main: str, implementation_commit: str,
                                   target_workstream: str | None = None,
                                   target_packet_path: str | None = None) -> dict:
    """Keep canonical review identity separate from the source/test validation range."""
    repo = Path(repo).resolve()
    landing = _git(repo, "rev-parse", "--verify", f"{implementation_commit}^{{commit}}")
    parent = _git(repo, "rev-parse", f"{landing}^1")
    landing_paths = _changed_paths(repo, f"{parent}..{landing}")

    def has_path(revision: str, path: str) -> bool:
        return subprocess.run(["git", "cat-file", "-e", f"{revision}:{path}"], cwd=repo,
                              capture_output=True).returncode == 0

    archive_transition = False
    if target_workstream and target_packet_path and "/archived/" in target_packet_path:
        active_packet = target_packet_path.replace("/archived/", "/", 1)
        archive_transition = (has_path(parent, active_packet) and not has_path(landing, active_packet)
                             and not has_path(parent, target_packet_path)
                             and has_path(landing, target_packet_path))
    if _source_code_paths(landing_paths) and not archive_transition:
        return {"base": parent, "head": landing, "commits": [landing], "paths": landing_paths,
                "provenance": {"kind": "canonical-implementation-commit"}}
    if not target_workstream or not target_packet_path:
        raise HostValidationError("archive-only implementation requires exact target workstream provenance")
    try:
        packet_text = _git(repo, "show", f"{reviewed_main}:{target_packet_path}")
    except HostValidationError as exc:
        raise HostValidationError("cannot load pinned target packet for source-span provenance") from exc
    return _split_landing_source_span(repo, reviewed_main, landing, target_workstream,
                                      target_packet_path, packet_text)


def _validate_report(report: dict, implementation_paths: list[str]) -> None:
    if report.get("schema") != "custodian.validation.result.v1":
        raise HostValidationError("host validation report has the wrong schema")
    coverage = report.get("coverage")
    tests = report.get("tests")
    selected = report.get("selected")
    if (report.get("passed") is not True or not isinstance(coverage, dict)
            or coverage.get("complete") is not True or coverage.get("uncovered_files")
            or not isinstance(tests, list) or not tests or not isinstance(selected, list) or not selected):
        raise HostValidationError("host validation report is failed, incomplete, or vacuous")
    test_ids = {item.get("id") for item in tests if isinstance(item, dict)}
    if (len(test_ids) != len(tests) or test_ids != set(selected)
            or any(item.get("status") != "passed" for item in tests)):
        raise HostValidationError("host validation tests do not exactly match the selected passing IDs")
    summary = report.get("summary")
    if (not isinstance(summary, dict) or summary.get("selected") != len(tests)
            or summary.get("passed") != len(tests)
            or any(summary.get(key) != 0 for key in ("failed", "timed_out", "skipped", "infrastructure_errors"))):
        raise HostValidationError("host validation summary does not verify all selected checks passed")
    code_paths = _source_code_paths(implementation_paths)
    reported_paths = set(report.get("changed_files") or [])
    if not code_paths.issubset(reported_paths):
        raise HostValidationError("host validation changed-file selection omits part of the implementation diff")
    covered = set(coverage.get("covered_files") or [])
    excluded = set(coverage.get("excluded_files") or [])
    if not code_paths.issubset(covered | excluded):
        raise HostValidationError("host validation coverage omits files from the implementation diff")
    code_paths = _source_code_paths(implementation_paths)
    if not code_paths or not code_paths.issubset(covered):
        raise HostValidationError("host validation does not cover changed implementation source/test files")
    covered_by = coverage.get("covered_by")
    if not isinstance(covered_by, dict) or any(
        not (set(covered_by.get(path, [])) & set(selected)) for path in code_paths
    ):
        raise HostValidationError("host validation has no selected test owner for changed source/test files")


def run_coordinator_validation(repo: Path, run_dir: Path, reviewed_main: str, implementation_commit: str,
                               *, target_workstream: str | None = None,
                               target_packet_path: str | None = None,
                               run_validation: Callable | None = None,
                               capability_probe: Callable[[], dict[str, bool]] = probe_host_capabilities) -> dict:
    """Run and pin the canonical changed-file suite before launching the reviewer.

    The exact implementation parent drives selection. Validation itself delegates to
    run_validation.py, which acquires the canonical Godot project lock and job budget.
    Evidence paths are create-only so retries cannot silently replace prior results.
    """
    worktree = Path(repo).resolve()
    run_dir = Path(run_dir).resolve()
    report_path = run_dir / "validation.json"
    metadata_path = run_dir / "coordinator-validation.json"
    if report_path.exists() or metadata_path.exists():
        raise HostValidationError("coordinator validation evidence already exists; refusing to overwrite it")

    head = _git(worktree, "rev-parse", "--verify", "HEAD^{commit}")
    if head != reviewed_main:
        raise HostValidationError("claimed review worktree HEAD differs from pinned reviewed main")
    if _git(worktree, "status", "--porcelain", "--untracked-files=all"):
        raise HostValidationError("claimed review worktree is dirty before host validation")
    implementation_commit = _git(worktree, "rev-parse", "--verify", f"{implementation_commit}^{{commit}}")
    parent = _git(worktree, "rev-parse", "--verify", f"{implementation_commit}^1")
    if subprocess.run(["git", "merge-base", "--is-ancestor", parent, implementation_commit],
                      cwd=worktree, capture_output=True).returncode:
        raise HostValidationError("implementation parent is not an ancestor of the pinned implementation")
    if subprocess.run(["git", "merge-base", "--is-ancestor", implementation_commit, reviewed_main],
                      cwd=worktree, capture_output=True).returncode:
        raise HostValidationError("pinned implementation is not an ancestor of reviewed main")

    source_span = resolve_validation_source_span(
        worktree, reviewed_main, implementation_commit, target_workstream, target_packet_path,
    )
    source_base = source_span["base"]
    source_head = source_span["head"]
    implementation_paths = list(source_span["paths"])
    # The validation base is the source-span base, so every source/test file
    # under review must also be selected by the canonical changed-file runner.
    selected_source_paths = _git_paths(worktree, f"{source_base}..{reviewed_main}")
    required_changed_paths = set(_source_code_paths(implementation_paths))
    if not required_changed_paths or not required_changed_paths.issubset(selected_source_paths):
        raise HostValidationError("canonical changed-file selection does not include the implementation diff")
    code_paths = [path for path in implementation_paths
                  if Path(path).suffix.lower() in {".gd", ".py", ".gdshader", ".tscn", ".tres", ".json"}]
    source_hashes = _source_hashes(worktree, code_paths)
    capabilities = capability_probe()

    command = [sys.executable, str(worktree / "custodian/tools/validation/run_validation.py"),
               "--changed", "--base", source_base, "--json"]
    execute = run_validation or (lambda argv, cwd: subprocess.run(
        argv, cwd=cwd, text=True, capture_output=True, check=False,
    ))
    try:
        process = execute(command, worktree)
    except OSError as exc:
        raise HostValidationError(f"trusted coordinator could not launch canonical validation: {exc}") from exc
    raw_report = process.stdout.encode("utf-8")
    report_hash = _sha256(raw_report)
    # Keep even a failed structured report for diagnosis. A later retry gets a new run ID.
    _write_exclusive(report_path, raw_report)
    if process.stderr:
        _write_exclusive(run_dir / "coordinator-validation.stderr", process.stderr.encode("utf-8"))
    try:
        report = json.loads(raw_report)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        report = None
        parse_error = str(exc)
    else:
        parse_error = None

    current_head = _git(worktree, "rev-parse", "--verify", "HEAD^{commit}")
    current_status = _git(worktree, "status", "--porcelain", "--untracked-files=all")
    current_source_hashes = _source_hashes(worktree, code_paths)
    source_changed = current_head != head or bool(current_status) or current_source_hashes != source_hashes
    metadata = {
        "schema": "custodian.paired_review_host_validation.v1",
        "worktree": str(worktree),
        "reviewed_main": reviewed_main,
        "implementation_commit": implementation_commit,
        "implementation_parent": parent,
        "source_span": source_span,
        "source_span_base": source_base,
        "source_span_head": source_head,
        "implementation_paths": implementation_paths,
        "code_paths": code_paths,
        "selected_source_paths": selected_source_paths,
        "source_sha256": source_hashes,
        "source_changed_during_validation": source_changed,
        "capabilities": capabilities,
        "command": command,
        "exit_code": process.returncode,
        "report_path": str(report_path),
        "report_sha256": report_hash,
        "report_parse_error": parse_error,
        "summary": report.get("summary") if isinstance(report, dict) else None,
        "selected": report.get("selected") if isinstance(report, dict) else None,
    }
    metadata_bytes = (json.dumps(metadata, indent=2, sort_keys=True) + "\n").encode("utf-8")
    _write_exclusive(metadata_path, metadata_bytes)
    metadata["metadata_sha256"] = _sha256(metadata_bytes)

    if source_changed:
        raise HostValidationError("reviewed worktree source changed during host validation")
    if process.returncode:
        raise HostValidationError(f"canonical host validation failed with exit code {process.returncode}")
    if not isinstance(report, dict):
        raise HostValidationError("canonical host validation did not return structured JSON")
    _validate_report(report, implementation_paths)
    return metadata


def verify_coordinator_validation(repo: Path, run_dir: Path, reviewed_main: str,
                                  implementation_commit: str, *, target_workstream: str | None = None,
                                  target_packet_path: str | None = None,
                                  expected_report_sha256: str,
                                  expected_metadata_sha256: str) -> dict:
    """Recheck pinned host evidence after the restricted reviewer exits."""
    run_dir = Path(run_dir).resolve()
    report_path = run_dir / "validation.json"
    metadata_path = run_dir / "coordinator-validation.json"
    try:
        report_bytes = report_path.read_bytes()
        metadata_bytes = metadata_path.read_bytes()
        metadata = json.loads(metadata_bytes)
        report = json.loads(report_bytes)
    except (OSError, json.JSONDecodeError) as exc:
        raise HostValidationError(f"coordinator validation evidence is missing or malformed: {exc}") from exc
    if _sha256(report_bytes) != expected_report_sha256:
        raise HostValidationError("coordinator validation report digest changed during reviewer execution")
    if _sha256(metadata_bytes) != expected_metadata_sha256:
        raise HostValidationError("coordinator validation provenance digest changed during reviewer execution")
    expected_span = resolve_validation_source_span(
        repo, reviewed_main, implementation_commit, target_workstream, target_packet_path,
    )
    if (metadata.get("schema") != "custodian.paired_review_host_validation.v1"
            or metadata.get("reviewed_main") != reviewed_main
            or metadata.get("implementation_commit") != implementation_commit
            or metadata.get("source_span") != expected_span
            or metadata.get("source_span_base") != expected_span.get("base")
            or metadata.get("source_span_head") != expected_span.get("head")
            or metadata.get("report_sha256") != expected_report_sha256
            or metadata.get("source_changed_during_validation") is not False):
        raise HostValidationError("coordinator validation provenance does not match the pinned review identity")
    if _git(Path(repo), "rev-parse", "--verify", "HEAD^{commit}") != reviewed_main:
        raise HostValidationError("reviewed worktree HEAD changed after host validation")
    if _source_hashes(Path(repo), metadata.get("code_paths") or []) != metadata.get("source_sha256"):
        raise HostValidationError("reviewed implementation source changed after host validation")
    if metadata.get("implementation_paths") != expected_span.get("paths"):
        raise HostValidationError("coordinator source path inventory differs from the verified source span")
    _validate_report(report, expected_span.get("paths") or [])
    return report
