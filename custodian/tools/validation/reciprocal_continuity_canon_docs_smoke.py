#!/usr/bin/env python3
"""Fail-closed regression guard for active Reciprocal Continuity canon."""
from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]

REQUIRED_FILES = (
    "design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md",
    "design/03_world/THE_ASH-BELL_CONTINUITY.md",
    "design/03_world/lore/CORE_LORE.md",
    "design/03_world/PROCEDURAL_LORE_GENERATION.md",
    "design/04_architecture/HUB_SYSTEM_META_PROGRESSION.md",
    "custodian/docs/ai_context/CONTEXT.md",
    "custodian/docs/ai_context/CURRENT_STATE.md",
    "custodian/docs/ai_context/FILE_INDEX.md",
)

DOCTRINE_MARKERS = (
    "**Authority:** Cosmology and continuity doctrine.",
    "Where this doctrine conflicts with an older document,",
    "Provenance is evidence lineage and continuity-origin verification.",
    "It is not a metaphysical substrate.",
)

ASH_BELL_MARKERS = (
    "**Precentor Orra** was Station IX's officer, not a coordinator of all nine stations.",
    "The Open Interval ended when Orra reached Station IX and gave the Ninth Answer",
    "West Gate closure was a separate containment and evacuation event; it did not end the Open Interval.",
    "Later survivor and devotional language derived from Station IX and its missing Ninth Answer.",
    "There was no original ninth cast bronze bell.",
)

PROCEDURAL_FIELDS = (
    '"continuity_anomaly":',
    '"continuity_origin":',
    '"source_integrity":',
    '"provenance_status":',
)

RETIRED_RUNTIME_IDS = (
    "ash_bell_ninth_bell",
    "ash_bell_bellfall_containment",
)

TEXT_SUFFIXES = {
    ".cfg",
    ".gd",
    ".gdshader",
    ".godot",
    ".ini",
    ".json",
    ".md",
    ".tres",
    ".tscn",
    ".txt",
    ".yaml",
    ".yml",
}

AFFIRMATIVE_METAPHYSICS = (
    re.compile(
        r"\b(?:unarrival|unnarrival|provenance(?: failure)?)\b"
        r"[^.!?\n]{0,100}\b(?:is|remains|constitutes|causes)\b"
        r"[^.!?\n]{0,100}\b(?:universal|cosmic|metaphysical)\b"
        r"[^.!?\n]{0,60}\b(?:root cause|substrate|law)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(?:universal|cosmic|metaphysical)\b[^.!?\n]{0,60}"
        r"\b(?:root cause|substrate|law)\b[^.!?\n]{0,80}"
        r"\b(?:is|remains|constitutes)\b[^.!?\n]{0,40}"
        r"\b(?:unarrival|unnarrival|provenance(?: failure)?)\b",
        re.IGNORECASE,
    ),
)

NEGATION = re.compile(
    r"\b(?:not|never|no longer|retired|superseded|rejected|forbidden|"
    r"does not|do not|isn't|aren't|wasn't|weren't)\b",
    re.IGNORECASE,
)


def _affirmative_match(text: str, pattern: re.Pattern[str]) -> bool:
    """Ignore explicit denials and historical retirement statements."""
    for sentence in re.split(r"(?<=[.!?])\s+|\n+", text):
        match = pattern.search(sentence)
        if match is None:
            continue
        if NEGATION.search(sentence[: match.start()]) or NEGATION.search(sentence):
            continue
        return True
    return False


def validate_documents(
    documents: dict[str, str], runtime_sources: dict[str, str]
) -> list[str]:
    errors: list[str] = []
    missing = [path for path in REQUIRED_FILES if path not in documents]
    for path in missing:
        errors.append(f"missing Reciprocal Continuity authority: {path}")
    if missing:
        return errors

    doctrine = documents["design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md"]
    ash_bell = documents["design/03_world/THE_ASH-BELL_CONTINUITY.md"]
    core = documents["design/03_world/lore/CORE_LORE.md"]
    procedural = documents["design/03_world/PROCEDURAL_LORE_GENERATION.md"]
    hub = documents["design/04_architecture/HUB_SYSTEM_META_PROGRESSION.md"]
    context = documents["custodian/docs/ai_context/CONTEXT.md"]
    current = documents["custodian/docs/ai_context/CURRENT_STATE.md"]
    index = documents["custodian/docs/ai_context/FILE_INDEX.md"]

    for marker in DOCTRINE_MARKERS:
        if marker not in doctrine:
            errors.append(f"Reciprocal Continuity Doctrine missing authority marker: {marker!r}")

    for marker in ASH_BELL_MARKERS:
        if marker not in ash_bell:
            errors.append(f"Ash-Bell history missing canon marker: {marker!r}")

    for field in PROCEDURAL_FIELDS:
        if field not in procedural:
            errors.append(f"procedural lore schema missing active field: {field}")
    retired_field_lines = [
        line for line in procedural.splitlines() if "provenance_failure" in line
    ]
    if any("replaces the retired" not in line for line in retired_field_lines):
        errors.append("procedural lore reintroduces active provenance_failure ontology")

    for field in ("continuity_origin", "source_integrity", "provenance_status"):
        if field not in hub:
            errors.append(f"Hub knowledge model missing continuity evidence field: {field}")
    if "classifying continuity anomalies" not in hub:
        errors.append("Hub canon no longer identifies continuity anomalies as its classification work")

    # Historical and devotional references remain valid when clearly identified
    # as retired terminology or later language. These positive controls prevent
    # the regression guard from becoming a repository-wide word ban.
    if "The following terms are retired from active canon:" not in core:
        errors.append("CORE_LORE lost its explicit retired-terminology boundary")
    if "Unnarrival (double-n)" not in core or "Bellfall Containment" not in core:
        errors.append("CORE_LORE no longer preserves retired terminology as historical evidence")
    if "later survivor and devotional language" not in ash_bell:
        errors.append("Ash-Bell canon no longer permits later Ninth Bell devotional language")

    active_context = {
        "CONTEXT.md": context,
        "CURRENT_STATE.md": current,
    }
    for name, text in active_context.items():
        for pattern in AFFIRMATIVE_METAPHYSICS:
            if _affirmative_match(text, pattern):
                errors.append(f"{name} reasserts retired provenance/Unarrival metaphysics")
                break

    for name, text in (
        ("Hub system meta-progression", hub),
        ("active AI context", context + "\n" + current),
    ):
        for match in re.finditer(
            r"\bunarrived\s+(?:source|event)\b|\bimpossible[- ]provenance\b",
            text,
            re.IGNORECASE,
        ):
            sentence_start = max(
                text.rfind("\n", 0, match.start()),
                text.rfind(".", 0, match.start()),
            )
            sentence_end_candidates = [
                position
                for position in (text.find("\n", match.end()), text.find(".", match.end()))
                if position >= 0
            ]
            sentence_end = min(sentence_end_candidates) if sentence_end_candidates else len(text)
            sentence = text[sentence_start + 1 : sentence_end]
            if not NEGATION.search(sentence):
                errors.append(f"{name} restores retired impossible-provenance ontology")
                break

    if "reciprocal_continuity_canon_docs_smoke.py" not in index:
        errors.append("FILE_INDEX does not index the focused canon-drift validator")
    if "tools/lore/validate_reciprocal_continuity_migration.sh" not in index:
        errors.append("FILE_INDEX does not identify the lore report helper")

    for path, text in runtime_sources.items():
        for retired_id in RETIRED_RUNTIME_IDS:
            if retired_id in text:
                errors.append(f"production runtime/content {path} restores retired ID {retired_id}")

    return errors


def _read_documents() -> dict[str, str]:
    return {
        path: (ROOT / path).read_text(encoding="utf-8")
        for path in REQUIRED_FILES
        if (ROOT / path).is_file()
    }


def _read_runtime_sources() -> dict[str, str]:
    sources: dict[str, str] = {}
    for base in (ROOT / "custodian" / "game", ROOT / "custodian" / "content"):
        for path in sorted(base.rglob("*")):
            if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
                continue
            try:
                sources[path.relative_to(ROOT).as_posix()] = path.read_text(encoding="utf-8")
            except (OSError, UnicodeError):
                continue
    return sources


def _run_negative_controls(documents: dict[str, str]) -> list[str]:
    cases = (
        (
            "doctrine authority",
            "design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md",
            "**Authority:** Cosmology and continuity doctrine.",
            "**Authority:** Supporting historical note.",
            {},
        ),
        (
            "Orra role",
            "design/03_world/THE_ASH-BELL_CONTINUITY.md",
            "not a coordinator of all nine stations",
            "coordinator of all nine stations",
            {},
        ),
        (
            "Open Interval termination",
            "design/03_world/THE_ASH-BELL_CONTINUITY.md",
            "West Gate closure was a separate containment and evacuation event; it did not end the Open Interval.",
            "West Gate closure ended the Open Interval.",
            {},
        ),
        (
            "Ninth Bell history",
            "design/03_world/THE_ASH-BELL_CONTINUITY.md",
            "There was no original ninth cast bronze bell.",
            "There was an original ninth cast bronze bell.",
            {},
        ),
        (
            "procedural fields",
            "design/03_world/PROCEDURAL_LORE_GENERATION.md",
            '"continuity_anomaly":',
            '"provenance_failure":',
            {},
        ),
        (
            "retired ontology",
            "design/04_architecture/HUB_SYSTEM_META_PROGRESSION.md",
            "classifying continuity anomalies",
            "classifying unarrived source metaphysics",
            {},
        ),
        (
            "AI context metaphysics",
            "custodian/docs/ai_context/CONTEXT.md",
            "Unarrival is an Ash-Bell term",
            "Unarrival is the universal metaphysical root cause.\nUnarrival is an Ash-Bell term",
            {},
        ),
        (
            "retired runtime ID",
            None,
            None,
            None,
            {"custodian/content/fixture.json": '{"knowledge_id":"ash_bell_ninth_bell"}'},
        ),
    )

    errors: list[str] = []
    for label, path, old, new, runtime_fixture in cases:
        fixture_documents = dict(documents)
        fixture_runtime = dict(_read_runtime_sources()) if runtime_fixture else {}
        if path is not None and old is not None and new is not None:
            original = fixture_documents[path]
            if old not in original:
                errors.append(f"negative control could not locate {label} mutation anchor")
                continue
            fixture_documents[path] = original.replace(old, new)
        fixture_runtime.update(runtime_fixture)
        if not validate_documents(fixture_documents, fixture_runtime):
            errors.append(f"negative control failed to reject {label} regression")

    # A negated historical mention remains legal; the guard is about claims,
    # not the appearance of retired phrases in correction notes.
    negative_history = dict(documents)
    context_path = "custodian/docs/ai_context/CONTEXT.md"
    negative_history[context_path] += (
        "\nThe phrase 'unarrived source' is not an active ontology.\n"
    )
    if validate_documents(negative_history, {}):
        errors.append("positive control rejected an explicitly negated historical reference")
    return errors


def main() -> int:
    documents = _read_documents()
    runtime_sources = _read_runtime_sources()
    errors = validate_documents(documents, runtime_sources)
    if not errors:
        errors.extend(_run_negative_controls(documents))
    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1
    print("reciprocal_continuity_canon_docs_smoke: PASS (current canon + mutation controls)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
