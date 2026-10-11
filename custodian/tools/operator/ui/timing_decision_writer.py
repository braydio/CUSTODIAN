"""Persistence for the Workbench's observed timing-confirmation button path.

This module is deliberately not a WorkbenchService API. The Textual app calls it
only after receiving the live confirmation button event and consuming its
one-use preview. Generic service preview/read calls cannot write approval state.
"""
from __future__ import annotations

import json
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import operator_2_5d_timing_authority as timing_authority


def record_confirmed_timing(app: Any, event: Any, service: Any, selection: Any,
                            prepared: dict[str, Any]) -> dict[str, Any]:
    """Persist a consumed preview after the UI confirmation event was observed."""
    from textual.widgets import Button

    expected_button = app._main_widget("#polish-timing-confirm", Button)
    if not isinstance(event, Button.Pressed) or event.button is not expected_button:
        raise ValueError("timing approval requires the active Workbench confirmation button event")
    if prepared.get("identity") != selection.authoring_identity:
        raise ValueError("timing preview expired; review the exact timing again")
    inputs = service._timing_inputs(selection)
    if service._timing_input_hashes(inputs) != prepared.get("input_hashes"):
        raise ValueError("saved timing inputs changed after preview; preview them again")
    params = timing_authority.validate_parameters(
        fps=prepared["params"]["fps"], loop=prepared["params"]["loop"],
        durations=prepared["params"]["durations"], physical=inputs["physical"],
    )

    manifest = inputs["manifest"]
    timeline = manifest.setdefault("timeline", {})
    timeline.update({"fps": params["fps"], "loop": params["loop"],
                     "durations": params["durations"],
                     "frame_durations_ms": params["frame_durations_ms"], "timing_authority": True})
    manifest_path = inputs["manifest_path"]
    document_path = inputs["document_path"]
    bindings = {"manifest_sha256": "", "document_sha256": timing_authority.sha256_file(document_path),
        "plan_sha256": timing_authority.sha256_file(inputs["plan_path"]),
        "profile_sha256": inputs["profile_sha256"], "reference_sha256": inputs["reference_sha256"],
        "physical": {"frames": int(inputs["physical"]["frames"]), "width": int(inputs["physical"]["width"]),
                     "height": int(inputs["physical"]["height"]),
                     "durations": [float(value) for value in inputs["physical"]["durations"]]}}
    decision_root = getattr(service, "_timing_decision_root", None)
    if decision_root is None:
        decision_root = service.repo_root / ".ai/operator_animation_workbench/review_receipts/operator_2_5d_128"
    decision = timing_authority.decision_path(decision_root, selection)
    stamp = datetime.now().strftime("%Y%m%dT%H%M%S%f")
    backup = inputs["workspace"] / "backups" / f"timing_decision_{stamp}"
    backup.mkdir(parents=True, exist_ok=False)
    shutil.copy2(manifest_path, backup / "workbench.json")
    old_decision = None
    if decision.exists():
        old_decision = json.loads(decision.read_text(encoding="utf-8"))
        shutil.copy2(decision, backup / decision.name)
    try:
        timing_authority.atomic_json(manifest_path, manifest)
        bindings["manifest_sha256"] = timing_authority.sha256_file(manifest_path)
        record = {"schema": timing_authority.SCHEMA, "authoring_identity": selection.authoring_identity,
            "action": "workbench_explicit_timing_confirmation", "parameters": {
                "fps": params["fps"], "loop": params["loop"], "durations": params["durations"]},
            "provenance": {"kind": "workbench_explicit_user", "control": "timing-preview-confirm",
                "confirmed_utc": datetime.now(timezone.utc).isoformat()},
            "parameter_sha256": timing_authority.parameter_digest(fps=params["fps"],
                loop=params["loop"], durations=params["durations"]), "bindings": bindings}
        record["record_sha256"] = timing_authority.sha256_bytes(timing_authority.canonical_json(record))
        timing_authority.atomic_json(decision, record)
        current = timing_authority.current_decision(path=decision, selection=selection,
            manifest_path=manifest_path, document_path=document_path, physical=inputs["physical"],
            plan_path=inputs["plan_path"], profile_sha256=inputs["profile_sha256"],
            reference_sha256=inputs["reference_sha256"])
        if current is None:
            raise ValueError("timing decision failed immediate revalidation")
    except Exception:
        shutil.copy2(backup / "workbench.json", manifest_path)
        if old_decision is None:
            decision.unlink(missing_ok=True)
        else:
            timing_authority.atomic_json(decision, old_decision)
        raise
    return {"status": "APPROVED TIMING", "record_sha256": current["record_sha256"],
            "fps": params["fps"], "loop": params["loop"],
            "durations": params["durations"], "backup": str(backup)}
