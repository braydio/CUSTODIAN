"""Fail-closed validation for the one authorized paired-review receipt delta."""
from __future__ import annotations

import re
import subprocess
from pathlib import Path

import review_outcome


_SECTION_RE = re.compile(r"(?m)^## Independent Review[ \t]*$")
_NEXT_SECTION_RE = re.compile(r"(?m)^## [^\r]*$")
_SHA_RE = re.compile(r"^[0-9a-f]{40,64}$")


def read_git_text(repo: Path, revision: str, path: str) -> str:
    """Read exact UTF-8 blob contents without stripping or newline conversion."""
    result = subprocess.run(["git", "show", f"{revision}:{path}"], cwd=repo,
                            capture_output=True, check=False)
    stdout = result.stdout if isinstance(result.stdout, bytes) else result.stdout.encode("utf-8")
    stderr = result.stderr if isinstance(result.stderr, bytes) else result.stderr.encode("utf-8")
    if result.returncode:
        raise ValueError(stderr.decode("utf-8", errors="replace").strip()
                         or f"cannot read {path} at {revision}")
    try:
        return stdout.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise ValueError(f"pinned packet {path} is not UTF-8") from exc


def resolve_target_implementation_commit(
    repo: Path,
    pinned_main: str,
    target_packet_path: str,
    target_workstream: str,
    baseline: str | None = None,
) -> tuple[str | None, str | None]:
    """Resolve identity from explicit metadata or the unique completed archive commit.

    Legacy V2 packets did not record an implementation commit. Their canonical
    workstream landing commit is the unique commit that introduced the exact
    archived packet as complete. The commit is derived from pinned history,
    never from reviewer-supplied receipt text.
    """
    if not _SHA_RE.fullmatch(pinned_main):
        return None, "pinned main is not a full commit SHA"
    if not target_packet_path.startswith("custodian/docs/ai_context/task_packets/archived/"):
        return None, "target packet is not at the canonical archive path"
    try:
        baseline = baseline if baseline is not None else read_git_text(repo, pinned_main, target_packet_path)
    except (OSError, ValueError) as exc:
        return None, f"cannot load pinned target packet: {exc}"

    explicit = re.findall(r"(?im)^- Implementation commit:\s*`?([0-9a-f]{40,64})`?\s*$", baseline)
    explicit_lines = re.findall(r"(?im)^- Implementation commit:.*$", baseline)
    if explicit_lines:
        if len(explicit) != 1 or len(explicit_lines) != 1:
            return None, "pinned target has malformed or ambiguous Implementation commit metadata"
        commit = explicit[0]
        if subprocess.run(["git", "cat-file", "-e", f"{commit}^{{commit}}"], cwd=repo,
                          capture_output=True).returncode:
            return None, "pinned target Implementation commit is unavailable"
        if subprocess.run(["git", "merge-base", "--is-ancestor", commit, pinned_main], cwd=repo,
                          capture_output=True).returncode:
            return None, "pinned target Implementation commit is not an ancestor of pinned main"
        return commit, None

    workstream_match = re.findall(r"(?im)^- Workstream:\s*`?([^`\r\n]+)`?\s*$", baseline)
    kind_match = re.findall(r"(?im)^- Kind:\s*`?(implementation|correction)`?\s*$", baseline)
    status_match = re.findall(r"(?im)^- Status:\s*`?(complete)`?\s*$", baseline)
    reviewed_main_match = re.findall(r"(?im)^- Reviewed main:\s*`?([0-9a-f]{40,64})`?\s*$", baseline)
    if (workstream_match != [target_workstream] or len(kind_match) != 1 or len(status_match) != 1
            or len(reviewed_main_match) != 1):
        return None, "pinned target is not one complete identified implementation packet"

    def _archive_candidates(*, follow: bool) -> list[str] | None:
        # The canonical archive path itself is the primary identity boundary.
        # Looking through renames first can also discover the packet's earlier
        # active-path introduction and make a perfectly unique archive landing
        # appear ambiguous. Only fall back to --follow for older histories
        # where the canonical archive path has no add/rename event at all.
        command = ["git", "log"]
        if follow:
            command.append("--follow")
        command += ["--diff-filter=AR", "--format=%H", pinned_main, "--", target_packet_path]
        history = subprocess.run(command, cwd=repo, capture_output=True, check=False)
        if history.returncode:
            return None
        candidates: list[str] = []
        for raw_sha in history.stdout.decode("ascii", errors="ignore").splitlines():
            if not _SHA_RE.fullmatch(raw_sha):
                continue
            try:
                archived = read_git_text(repo, raw_sha, target_packet_path)
            except ValueError:
                continue
            if (re.findall(r"(?im)^- Workstream:\s*`?([^`\r\n]+)`?\s*$", archived) == [target_workstream]
                    and re.findall(r"(?im)^- Kind:\s*`?(implementation|correction)`?\s*$", archived)
                    and re.findall(r"(?im)^- Status:\s*`?complete`?\s*$", archived)):
                candidates.append(raw_sha)
        return candidates

    candidates = _archive_candidates(follow=False)
    if candidates is None:
        return None, "cannot inspect pinned target archive history"
    if len(candidates) == 0:
        candidates = _archive_candidates(follow=True)
        if candidates is None:
            return None, "cannot inspect pinned target archive history"
    if len(candidates) != 1:
        return None, "pinned target has no unique complete archive-introduction commit"
    archive_commit = candidates[0]
    reviewed_main = reviewed_main_match[0]
    if subprocess.run(["git", "merge-base", "--is-ancestor", reviewed_main, archive_commit], cwd=repo,
                      capture_output=True).returncode:
        return None, "target archive commit does not descend from its recorded Reviewed main"
    if subprocess.run(["git", "merge-base", "--is-ancestor", archive_commit, pinned_main], cwd=repo,
                      capture_output=True).returncode:
        return None, "target archive commit is not an ancestor of pinned main"
    return archive_commit, None


def _section(text: str) -> tuple[int, int, str] | None:
    matches = list(_SECTION_RE.finditer(text))
    if len(matches) != 1:
        return None
    match = matches[0]
    next_section = _NEXT_SECTION_RE.search(text, match.end())
    end = next_section.start() if next_section else len(text)
    return match.start(), end, text[match.start():end]


def _field(receipt: str, name: str) -> str | None:
    matches = re.findall(rf"(?m)^- {re.escape(name)}: `?([^`\r\n]+)`?\s*$", receipt)
    return matches[0].strip() if len(matches) == 1 else None


def render_review_receipt(outcome: dict[str, str]) -> str:
    """Render the target receipt only from one already-parsed canonical PASS outcome."""
    required = set(review_outcome.FIELDS)
    if set(outcome) != required or outcome.get("Outcome") != "passed":
        raise ValueError("a target receipt requires one complete canonical passed Review Outcome")
    parsed, error = review_outcome.parse_review_outcome(review_outcome.render_review_outcome(
        outcome=outcome["Outcome"], review_workstream=outcome["Review workstream"],
        target_workstream=outcome["Review target workstream"], reviewed_main=outcome["Reviewed main"],
        implementation_commit=outcome["Reviewed implementation commit"],
        provenance=outcome["Reviewer provenance"], run_id=outcome["Run ID"],
        review_cycle=int(outcome["Review cycle"]), ids=review_outcome.finding_ids(outcome),
    ))
    if error or parsed != outcome:
        raise ValueError("target receipt source is not the exact canonical PASS outcome")
    fields = (
        ("Schema", "Schema"), ("Review workstream", "Review workstream"),
        ("Review target workstream", "Review target workstream"), ("Status", "Outcome"),
        ("Blocking defects", None), ("Material gaps", None), ("Reviewer context", "Reviewer context"),
        ("Reviewer provenance", "Reviewer provenance"), ("Reviewed main", "Reviewed main"),
        ("Reviewed implementation commit", "Reviewed implementation commit"),
    )
    values = {"Blocking defects": "0", "Material gaps": "0"}
    values.update({field: outcome[source] for field, source in fields if source is not None})
    values["Schema"] = "custodian.paired_review.v1"
    return f"### Review Receipt: {outcome['Review workstream']}\n" + "".join(
        f"- {field}: `{values[field]}`\n" for field, _ in fields
    )


def verify_review_receipt_delta(
    baseline: str,
    candidate: str,
    *,
    review_workstream: str,
    target_workstream: str,
    reviewed_main: str,
    target_implementation_commit: str | None = None,
) -> tuple[dict[str, str] | None, str | None]:
    """Return the appended receipt only when all non-receipt bytes are immutable."""
    if not review_workstream or not target_workstream or not _SHA_RE.fullmatch(reviewed_main):
        return None, "review receipt identity or pinned main SHA is invalid"

    old = _section(baseline)
    new = _section(candidate)
    if new is None:
        return None, "candidate must contain exactly one Independent Review section"

    start, end, new_section = new
    receipt_heading = f"### Review Receipt: {review_workstream}\n"
    if old is None:
        if _SECTION_RE.search(baseline) or not baseline.endswith("\n") or candidate[:len(baseline)] != baseline:
            return None, "new review receipt must append after the exact baseline packet bytes"
        if candidate[len(baseline):start] != "\n" or candidate[end:] != "":
            return None, "new Independent Review section is not canonically appended at packet end"
        expected_section_start = "## Independent Review\n\n"
        if not new_section.startswith(expected_section_start + receipt_heading):
            return None, "new Independent Review section must contain the canonical receipt heading"
        delta = new_section[len(expected_section_start + receipt_heading):]
    else:
        old_start, old_end, old_section = old
        if baseline[:old_start] != candidate[:start] or baseline[old_end:] != candidate[end:]:
            return None, "packet bytes outside the Independent Review section changed"
        if not new_section.startswith(old_section):
            return None, "existing Independent Review receipt bytes were rewritten"
        separator = "\n" if old_section.endswith("\n") else "\n\n"
        expected_prefix = old_section + separator + receipt_heading
        if not new_section.startswith(expected_prefix):
            return None, "candidate must append exactly one canonical review receipt"
        delta = new_section[len(expected_prefix):]

    if delta.count(receipt_heading) != 0:
        return None, "candidate contains duplicate or ambiguous review receipts"
    if re.search(r"(?m)^### Review Receipt:", delta) or _SECTION_RE.search(delta):
        return None, "candidate contains duplicate or ambiguous review receipts"

    required = {
        "Schema": "custodian.paired_review.v1",
        "Review workstream": review_workstream,
        "Review target workstream": target_workstream,
        "Status": "passed",
        "Blocking defects": "0",
        "Material gaps": "0",
        "Reviewer context": "fresh",
        "Reviewed main": reviewed_main,
    }
    values: dict[str, str] = {}
    for key, expected in required.items():
        value = _field(delta, key)
        if value != expected:
            return None, f"review receipt has missing or mismatched {key}"
        values[key] = value
    provenance = _field(delta, "Reviewer provenance")
    if provenance not in {"different-agent", "same-agent-fresh-context"}:
        return None, "review receipt has missing or invalid Reviewer provenance"
    values["Reviewer provenance"] = provenance

    implementation_commit = _field(delta, "Reviewed implementation commit")
    if not implementation_commit or not _SHA_RE.fullmatch(implementation_commit):
        return None, "review receipt has missing or invalid Reviewed implementation commit"
    if not target_implementation_commit or not _SHA_RE.fullmatch(target_implementation_commit):
        return None, "pinned target baseline has no unique full Implementation commit"
    if implementation_commit != target_implementation_commit:
        return None, "review receipt names a different implementation commit than the baseline target"
    values["Reviewed implementation commit"] = implementation_commit
    allowed = set(required) | {"Reviewer provenance", "Reviewed implementation commit"}
    receipt_lines = [line for line in delta.splitlines() if line.strip()]
    for line in receipt_lines:
        match = re.fullmatch(r"- ([A-Za-z][A-Za-z ]*): `([^`\r\n]+)`", line)
        if not match or match.group(1) not in allowed:
            return None, "review receipt contains non-canonical or unauthorized content"
    if len(receipt_lines) != len(allowed):
        return None, "review receipt must contain exactly one canonical value for every required field"
    return values, None
