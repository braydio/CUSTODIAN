#!/usr/bin/env python3
"""Tripwire for Operator authoring doc drift: retired builder paths and Workbench shortcut/mode changes.

Derives the live Workbench numbered-mode set and the WORKBENCH `Ctrl+R` canvas-resize
binding from `custodian/tools/operator/ui/app.py` and checks the active Operator
pipeline docs still describe them, instead of hardcoding a snapshot that silently goes
stale the next time a mode or shortcut changes.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]

APP_PY = "custodian/tools/operator/ui/app.py"
CHEATSHEET = "custodian/docs/SPRITE_PIPELINE_CHEATSHEET.md"
PIPELINE_README = "custodian/content/sprites/_pipeline/README.md"
ACTIVE_DOCS = (CHEATSHEET, PIPELINE_README)

FORBIDDEN_LEGACY_STRINGS = (
    "build_operator_modular_runtime.py",
    "update_operator_curated_resources.gd",
)

MODE_NAME_BY_ACTION = {
    "mode_plan": "PLAN",
    "mode_workbench": "WORKBENCH",
    "mode_preview": "PREVIEW",
    "mode_timeline": "TIMELINE",
    "mode_motion": "MOTION",
    "mode_polish": "POLISH",
}


def _extract_numbered_modes(app_source: str) -> list[tuple[str, str]]:
    modes = [
        (number, action)
        for number, action in re.findall(r'Binding\("(\d)",\s*"(mode_\w+)"', app_source)
    ]
    modes.sort(key=lambda pair: int(pair[0]))
    return modes


def _ctrl_r_opens_workbench_canvas_resize(app_source: str) -> bool:
    if 'Binding("ctrl+r", "context_ctrl_r"' not in app_source:
        return False
    handler = re.search(
        r"def action_context_ctrl_r\(self\)[^\n]*\n(.*?)\n    def ",
        app_source,
        re.DOTALL,
    )
    if handler is None:
        return False
    body = handler.group(1)
    return 'mode == "workbench"' in body and "action_resize_canvas" in body


def main() -> int:
    errors: list[str] = []

    app_source = (ROOT / APP_PY).read_text(encoding="utf-8")
    numbered_modes = _extract_numbered_modes(app_source)
    if not numbered_modes:
        errors.append(f"could not find any numbered WORKBENCH mode bindings in {APP_PY}")

    mode_names: list[str] = []
    for number, action in numbered_modes:
        name = MODE_NAME_BY_ACTION.get(action)
        if name is None:
            errors.append(
                f"unrecognized mode action '{action}' bound to key '{number}' in {APP_PY}; "
                "add it to MODE_NAME_BY_ACTION and update the active Operator docs"
            )
            continue
        mode_names.append(name)

    expected_range = f"`1`–`{len(numbered_modes)}`" if numbered_modes else None
    expected_mode_list = " / ".join(mode_names)
    ctrl_r_is_canvas_resize = _ctrl_r_opens_workbench_canvas_resize(app_source)

    doc_text: dict[str, str] = {}
    for relative in ACTIVE_DOCS:
        path = ROOT / relative
        if not path.is_file():
            errors.append(f"missing active Operator doc: {relative}")
            continue
        text = path.read_text(encoding="utf-8")
        doc_text[relative] = text
        for forbidden in FORBIDDEN_LEGACY_STRINGS:
            if forbidden in text:
                errors.append(f"{relative} still references retired '{forbidden}'")

    cheatsheet_text = doc_text.get(CHEATSHEET, "")

    if expected_range and expected_range not in cheatsheet_text:
        errors.append(
            f"{CHEATSHEET} does not document the live mode key range {expected_range} "
            f"(derived from {APP_PY})"
        )
    if expected_mode_list and expected_mode_list not in cheatsheet_text:
        errors.append(
            f"{CHEATSHEET} does not document the live mode order '{expected_mode_list}' "
            f"(derived from {APP_PY})"
        )
    if "Shift+R" in cheatsheet_text:
        errors.append(f"{CHEATSHEET} still documents the retired 'Shift+R' shortcut")
    if ctrl_r_is_canvas_resize and "`Ctrl+R` opens the same review flow" not in cheatsheet_text:
        errors.append(
            f"{CHEATSHEET} does not document that WORKBENCH `Ctrl+R` opens the canvas resize review flow "
            f"(derived from {APP_PY})"
        )

    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1

    print(
        "operator_authoring_surface_contract_smoke: PASS "
        f"modes={len(numbered_modes)} ctrl_r_canvas_resize={ctrl_r_is_canvas_resize}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
