# Asset Workbench — Slice 1 (FAMILY / REVIEW / PIPELINE)

Workstream: `asset-workbench` · Branch: `agent/asset-workbench` · Base: `origin/main@ea80fd7a`

> **Reminder for the operator (per explicit instruction this run):** this work
> happened on a *separate* worktree/branch from the in-progress Operator C2b
> slice. The C2b work-in-progress lives on `claude/operator-c2b-final` in the
> `CUSTODIAN-operator` worktree and was left untouched. **Return to
> `claude/operator-c2b-final` to continue C2b.**

## What this is

A generic, non-Operator **Asset Workbench** for reviewing any Asset Pipeline
V2 family, exposed through the existing non-Operator CLI:

```bash
python3 custodian/tools/assets/asset.py ui
python3 custodian/tools/assets/asset.py ui ambient_baby_opossum
```

It is a sibling of the Operator Workbench (`custodian/tools/operator/ui/`),
not a clone and not a replacement. Baby Opossum (50 states, 7 action_groups,
22 published runtime strips, `4dir` + `auto_mirror`) is the acceptance
fixture and was used for every check below against live repository state.

## Files changed

New:

- `custodian/tools/workbench/__init__.py`, `custodian/tools/workbench/preview/{__init__.py,frame_ops.py,canvas.py,filmstrip.py,controls.py}`
- `custodian/tools/assets/ui/{__init__.py,state.py,service.py,app.py,requirements.txt}`
- `custodian/tools/assets/ui/widgets/{__init__.py,family_tree.py,state_detail.py,coverage_panel.py,pipeline_panel.py,activity_log.py}`
- `custodian/tools/validation/asset_workbench_ui_smoke.py`

Modified:

- `custodian/tools/assets/asset.py` — added `ui [family]` subcommand (`cmd_ui`), mirroring `operator_cli.py`'s optional-Textual-dependency handling exactly (exit 2 + install hint on `ModuleNotFoundError` for `textual`).
- `custodian/tools/operator/ui/features/base.py` — retired the dead, never-implemented `PreviewAdapter` protocol (see Documentation drift below). `WorkbenchFeature` (the protocol actually used by `AnimationFeature`) is untouched.
- `custodian/tools/validation/validation_manifest.json` — registered `asset_workbench_ui`.
- `custodian/docs/ai_context/{CURRENT_STATE.md,FILE_INDEX.md}` — see Documentation drift.

## Generic/shared pieces extracted

`custodian/tools/workbench/preview/` — pulled out of
`custodian/tools/operator/animation_preview.py` and
`operator/ui/widgets/preview_{canvas,filmstrip,controls}.py`:

- `frame_ops.py`: `ZoomMode`, `scale_preview_frame`, `split_strip`,
  `split_image`, `compare_frames`/`FrameDiffMetrics` — pure PIL, zero
  Operator/Asset-V2 identity concepts.
- `canvas.py`, `filmstrip.py`, `controls.py` — the Textual preview widgets,
  repointed to import from `frame_ops` instead of `animation_preview`.

**Operator's own copies are untouched** — no wholesale OPUI relocation in
this slice, per the task brief's explicit non-goal. Slice 1 accepts the
resulting duplication rather than touching working Operator code from an
unrelated branch.

The Asset Workbench's identity model (`ui/state.py: AssetSelection`) is its
own `(family_id, state_id, direction, review_source)` — it does not reuse or
extend Operator's `AnimationSelection`. Layer/action_group/variant are always
resolved through the family contract, never invented.

## Commands added

```bash
python3 custodian/tools/assets/asset.py ui                       # first registered family
python3 custodian/tools/assets/asset.py ui ambient_baby_opossum  # specific family
```

Keys: `1/2/3` Family/Review/Pipeline, `R` refresh, `Space` play/pause,
`←/→` frame step, `Home/End` first/last, `[`/`]` review speed, `Z` zoom
(auto/1x/2x/3x/fit), `S` review source (runtime ⇄ inbox, when both exist),
`D` single/split/diff.

## Focused tests and results

`custodian/tools/validation/asset_workbench_ui_smoke.py` — all 10 acceptance
checks from the task brief, run twice:

- **System Python (no Textual installed)** — PASS. Confirms the
  service/state layer needs no Textual, and `asset ui <family>` exits 2 with
  the documented install hint (matches `operator_cli.py`'s convention).
- **Throwaway venv with `pip install -r custodian/tools/assets/ui/requirements.txt`
  (Textual 0.89.1)** — PASS, including the real headless Textual pilot: boots
  the app against `ambient_baby_opossum`, switches to REVIEW (loads real
  runtime frames), switches to PIPELINE (loads a real plan/doctor report).

I also drove a manual pilot walkthrough beyond the smoke test's scope
(space/arrows/home/end/`[`/`]`/`z`/`s`/`d` on the `alert` state) to hand-check
each REVIEW keybinding against real frame data — all behaved as designed,
including the "only one review source" warning path (`alert` has no inbox
art) and correct FPS/zoom/view cycling.

Both runs are reproducible; the throwaway venv (`/tmp/asset-workbench-ui-venv`)
is outside the repo and not part of this change.

## Changed-validation result

**Not run.** `run_validation.py --changed` was skipped at closeout: at the
time of this task the machine had ~305Mi free RAM (`free -h`) and an
already-running interactive Godot editor + scene session (PID 702430,
`awakening_first_return.tscn` / `game.tscn`) that this task did not start.
Per `custodian/AGENTS.md`'s resource-budget guidance, starting anything
additional there — Godot or otherwise — was not worth the contention risk.
This change touches zero `.gd`/runtime files (Python, JSON manifest, and
Markdown only), so the narrowest test that can falsify it is the focused
smoke test above, which ran clean in both dependency configurations. Re-run
`run_validation.py --changed --json` once memory pressure clears if a
broader sweep is wanted.

## Documentation drift fixed

- `custodian/tools/operator/ui/features/base.py` carried a `PreviewAdapter`
  Protocol explicitly commented as `"Future image-preview seam; V1
  intentionally registers no adapters."` It was never implemented or
  referenced anywhere (verified with a repo-wide grep) while Operator grew a
  full concrete preview stack around it. Retired rather than "made generic,"
  since the actually-generic preview seam now genuinely exists as
  `custodian/tools/workbench/preview/`, and the brief's docs-drift item is
  now resolved instead of having two nominal generic-preview abstractions
  side by side.
- `FILE_INDEX.md` / `CURRENT_STATE.md` gained entries only for what now
  actually exists (no aspirational claims about Slice 2/3).

## Awkward parts (said plainly)

- **Caught a real footgun before it shipped, not after.** My first draft of
  `sys.path` wiring inserted `custodian/tools/` at `sys.path[0]` so
  `workbench.preview.*` would import. `custodian/tools/` contains a sibling
  directory literally named `operator/`, which would shadow Python's stdlib
  `operator` module (used pervasively by other libraries, including
  Textual's own dependencies) for any code importing it for the first time
  afterward. Fixed by `sys.path.append` instead of `insert(0)` for that one
  path, with a comment explaining why. Caught this myself during
  implementation, not via the test suite — the smoke test would not have
  caught it either, since `operator` typically gets imported indirectly and
  the failure mode is a confusing, delayed `AttributeError` elsewhere, not an
  import error at the call site. Worth flagging because it's the kind of bug
  that looks fine until it very much isn't, in a shared-runtime tool.
- **A real bug the Textual pilot caught, that static review missed.** My
  first key-bar hint string included a literal `[/]` (meant as "the `[` and
  `]` keys"). Rich's markup parser reads that as an unmatched closing tag and
  the app crashes on render. Static reading of the code looked fine; only
  actually running the app under `textual.app.App.run_test()` surfaced it.
  Fixed by disabling markup on the plain-text panels (`StateDetail`,
  `CoveragePanel`, `PipelinePanel`, key-bar) and escaping dynamic content
  routed through `ActivityLog` (which does want markup, for severity
  coloring). This is why I went and got Textual installed in a throwaway venv
  rather than shipping on inspection alone.
- **REVIEW mode has no direction-switching keybinding.** The task brief's
  Slice 1 REVIEW control list (Space/←/→/Home/End/`[`/`]`/Z/S/D) doesn't
  include one, so direction is fixed to whatever `resolve_selection` picks
  (first authored-or-mirrored direction, alphabetical) once a state is
  chosen from the FAMILY tree. Direction coverage is still fully visible in
  FAMILY/STATE DETAIL; you just can't cycle direction from inside REVIEW yet.
  Flagging as a real gap, not hiding it — worth deciding explicitly for
  Slice 2 rather than silently bolting on a keybinding the brief didn't ask
  for.
- **"SOURCE" review tier from the mockup doesn't exist for generic
  families.** Operator has a dedicated `content/sprites/operator/source/`
  convention; non-Operator Asset V2 families (checked: `ambient_creatures/`)
  have no equivalent — only `runtime/` and the inbox. REVIEW therefore
  supports `runtime` and `inbox` only, not the mockup's four-way
  SOURCE/INBOX/RUNTIME/DIFF. Implementing a fake "source" location would
  have meant inventing an authority Asset V2 doesn't have, which the brief
  explicitly forbids.
- **PIPELINE's family/global doctor-issue split is a best-effort substring
  filter** (`family_id in issue.message`), not a structural one —
  `asset_doctor.py`'s issue messages aren't tagged with a family field, just
  formatted strings. Nothing is hidden (`run_doctor` still runs its full
  sweep and every issue is counted), but a family whose id happens to be a
  substring of another message could theoretically misfile. Not observed in
  practice against the live 69-family catalog, but noted rather than
  presented as exact.

## Intentionally deferred (Slice 2/3, per the brief's own phasing)

- SEQUENCE mode (disposable review sequences from semantic states).
- DESIGN mode (explicit design-gap panel, contract/runtime diff detail).
- Direction-switching inside REVIEW.
- Any Aseprite/ingest mutation from the UI (Slice 1 is read-only by design;
  verified structurally — `ui/service.py` never imports `asset_transaction`,
  `save_catalog`, `stage_asset`, or `update_catalog_entry` — and behaviorally
  — the smoke test hashes `asset_catalog.generated.json` before/after every
  read call and asserts it's byte-identical).
