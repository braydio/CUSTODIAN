from __future__ import annotations

import json
from pathlib import Path


def append_critique(path: Path, critique: dict) -> dict:
    required={"frame","severity","category","part","bounds","issue","repair_intent","confidence"}
    missing=required-set(critique)
    if missing: raise ValueError(f"critique missing: {sorted(missing)}")
    with path.open("a",encoding="utf-8") as stream: stream.write(json.dumps(critique,sort_keys=True)+"\n")
    return critique


def critiques(path: Path) -> list[dict]:
    return [json.loads(x) for x in path.read_text().splitlines() if x] if path.exists() else []


def packet(path: Path, *, task: str, constraints: list[str], artifacts: dict, metrics: str, qa: str, references: list[dict], findings: list[dict]) -> dict:
    value={"schema":"custodian.operator_art_review_packet.v1","task":task,"constraints":constraints,"artifacts":artifacts,"metrics":metrics,"qa":qa,"references":references,"open_findings":findings}
    path.write_text(json.dumps(value,indent=2)+"\n"); return value
