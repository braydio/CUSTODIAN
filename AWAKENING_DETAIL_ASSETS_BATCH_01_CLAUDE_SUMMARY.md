# Awakening Detail Assets Batch 01 — Closing Summary

Ingested the 10-state `custodian_awakening_detail_batch_01_asset_handoff_v1`
handoff bundle (`service_basin_b`, Late Service relay-lamp `idle`, six
`awakening_authority_inlay` route tiles, `floor_crack_a`, `rubble_small`)
through the standalone `asset_handoff_installer.py` and current Asset
Pipeline V2, and reconciled the documentation that referenced these states as
missing. Scene/tile binding (CODEX_IMPLEMENTATION.md's Integration section)
was deliberately **not** performed; see Blockers below.

## What was done

- Verified `SHA256SUMS.txt` (already clean per user) and independently
  re-verified all 10 source + inbox PNGs' SHA-256, declared dimensions, and
  true-alpha (RGBA, alpha min 0 / max 255) against `MANIFEST.json`.
- The downloaded bundle's `MANIFEST.json` does **not** match the live
  `asset_handoff_installer.py`'s actual `custodian.asset_handoff.v1` schema
  (multi-family manifest, `source_file`/`inbox_file`/array-dimension keys, no
  `review_status`/`install_source`/`install_inbox` flags) — this is schema
  drift between the package snapshot and live installer contract. Reconciled
  it by generating four schema-conformant per-family manifests (one
  `family_id` each, as the live installer requires) from the bundle's own
  verified hashes/sizes/dimensions, setting `review_status: RUNTIME_READY`
  and both install flags true, and running the real, unmodified installer
  against each. The original bundle `MANIFEST.json` was restored unchanged
  afterward; nothing in `/home/braydenchaffee/Downloads/` was touched.
- `asset_handoff_installer.py --repo <worktree> --dry-run` then (for real)
  installed all 10 states into `custodian/asset_drop/source_work/awakening/<family>/`
  and `custodian/asset_drop/inbox/<family>/<state>.png`, exactly matching
  CODEX_IMPLEMENTATION.md's named destinations. All four family contracts
  already existed on live main (confirmed, not duplicated).
- `asset plan` / `asset ingest --yes` / `asset status` / `asset doctor` for
  all four families: all 10 states CREATE-only, exact dimensions, no
  replace/collision. Ran `godot --headless --import` to generate `.import`
  sidecars (worktree-local Godot project, independent of the user's live
  editor session) and `asset needs --write` to regenerate `REQUIRED_ASSETS.md`.
  `asset doctor` now reports `ASSET PIPELINE HEALTHY`.
- 32px authority-inlay adjacency check: composed native-32px row and
  mixed-topology grids (straight/corner/t_junction/cross/ring_node/threshold)
  and inspected visually. All six share one consistent teal-inlay/brass-border
  route language with plausible, consistent cardinal connections; reads
  coherently as one system at native size.
- `straight.png`'s central-horizontal-band derivation (from the cross/junction
  source) was inspected directly: usable, no leaked vertical-arm artifacts,
  consistent with the family's node-bulge convention.
- `floor_crack_a` / `rubble_small` inspected at 64px: clean alpha, no matte
  box, natural silhouette edges.
- Focused validation: `awakening_first_return`, `awakening_first_return_geometry`,
  `awakening_first_return_progression`, and `asset_handoff_installer` all
  passed. `run_validation.py --changed --base origin/main --json`: 7/8
  passed; the one failure (`agent_workflow_contract`) is a pre-existing,
  unrelated repo-wide gap (`.github/workflows/expire-lfs-degraded-mode.yml`
  absent from `origin/main`), already logged in
  `ASSET_HANDOFF_BUNDLE_INSTALLER_V1_CLAUDE_SUMMARY.md` as a prior-session
  follow-up, not caused by this slice. `git diff --check` clean.
- Updated `CURRENT_STATE.md`, `design/04_architecture/AWAKENING_ASSET_MANIFEST.md`,
  and `custodian/docs/reports/awakening_runtime_ingest_status.md` to reflect
  the ingested-but-unbound state truthfully. `REQUIRED_ASSETS.md` regenerated
  by `asset needs --write` (not hand-edited).

## Blockers — Integration section deliberately not done

CODEX_IMPLEMENTATION.md's Integration section asks to bind `service_basin_b`,
the relay lamp, the six inlay tiles, and the two ruin decals into
`awakening_first_return.tscn` using "existing scene/layout authority." I
inspected the live scene, `awakening_layout.gd`, and the live production
plate art before writing any scene edit, and found no safe, unambiguous seam:

- **`service_basin_b`**: `awakening_layout.gd` defines two candidate
  obstacles, `west_service_basin` (-352,-704) and `east_service_basin`
  (352,-864), both `blocking: true`, 96×96. I rendered the live Ambulatory
  plate (`awakening_ambulatory_underlay/foreground_1152x960.png`) and cropped
  both exact obstacle footprints: **both already show matching baked
  basin/tank dressing**, symmetric left/right. There is no documented mapping
  of which baked instance fulfills `service_basin_a` versus where a
  standalone `service_basin_b` sprite should sit without visually doubling
  existing art, and `AWAKENING_ASSET_MANIFEST.md` already classified this
  family as baked-only with no standalone-binding precedent.
- **Relay lamp `idle`**: the Late Service altar obstacle (`relay_lamp_altar`,
  -736,-5904) already shows a baked, lit brass lamp fixture in the live plate
  (`awakening_late_service_underlay/foreground_704x768.png`). Same ambiguity
  as above.
- **Authority inlay / ruin decal**: I grepped `custodian/game/`, `custodian/scenes/`,
  `design/`, and `custodian/docs/` for any existing route-tile or decal
  placement system — none exists. CODEX_IMPLEMENTATION.md itself only asks to
  use such a system "if" one exists and not to invent bespoke scene sprites;
  since none exists, inventing one is outside this ad hoc batch's authority.

Separately, `custodian/docs/ai_context/task_packets/AWAKENING_HANDOFF_READINESS_ART_CONVERGENCE_V1.md`
is an actively **claimed** workstream (live worktree exists, branch
`agent/awakening-handoff-readiness-art-convergence-v1`) holding locks
`awakening-runtime, awakening-art-registration` over this exact scene, and
its own asset ledger explicitly tracks these same four families as
"registered / currently unpublished" with "do not publish missing generic
art as part of this packet." Forcing scene edits here risks both a
visually-wrong guess and a collision with that workstream's declared
authority. This is a genuine blocker, not a missed search — reported per
instruction rather than forced.

## Acceptance (CODEX_IMPLEMENTATION.md, 8 criteria)

1. 10/10 source assets preserved in `source_work` — **met**.
2. 10/10 states pass Asset V2 plan + exact-dimension checks — **met**.
3. All 10 appear in Asset V2 status/catalog with canonical runtime outputs — **met**.
4. `service_basin_b` and relay lamp runtime-bound without geometry changes — **not met** (blocked, see above).
5. Authority-inlay states visually readable/compatible at 32px — **met**.
6. Ruin decals render with clean alpha at 64px — **met**.
7. Trackers remain truthful about missing/deferred states — **met**: `asset status` shows `bound: false` for all 10 new states; `route_circle`/`civic_spear`/`attestation_mark` and `floor_crack_b`/`floor_crack_c`/`rubble_medium` (+recommended) remain correctly `missing`.
8. Report exact commit SHA and validation evidence — **met**, see below.

## Commits (pushed, not landed)

- `3191a95c1` — ingest 10 source assets through Asset V2
- `5e13b2b81` — reconcile docs drift for ingested-unbound states

Branch `agent/awakening-detail-assets-batch-01` pushed to origin. **Not**
run through `workstream.py finish`/landed to main: 2 of 8 acceptance
criteria are genuinely blocked (see above), so landing as "complete" would
misrepresent acceptance. The ingest-only work itself is real, validated, and
non-destructive, and does not need to be held back from review.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: the downloaded handoff bundle's `MANIFEST.json` schema did not match the live `asset_handoff_installer.py` contract (multi-family vs. single-family manifest, different field names/types); the Integration section's target scene has no unambiguous binding seam for 2 of 4 families because their layout anchors already show baked-equivalent art, and no placement system exists yet for the tile families.
- Root cause / contributing factors: the handoff-bundle generation prompt and the installer's manifest schema appear to have diverged since this particular bundle was generated; the Awakening scene's fixture/prop "P1" families were originally authored by baking into zone master plates rather than live sprite binding, and no later decision formalized a standalone-binding path for new states layered on top of already-dressed anchors.
- Prevention / pipeline improvement: `generate_asset_handoff_bundle.md` should be checked against the live installer's actual expected manifest shape (or the installer should accept the multi-family shape) so future bundles don't require manual manifest adaptation. The Ambulatory/Late-Service baked-vs-standalone binding ambiguity should be resolved once, in design authority, rather than re-discovered per batch.
- Tooling / docs drift discovered: `MANIFEST.json` generator/installer schema mismatch (see above); `CURRENT_STATE.md`, `AWAKENING_ASSET_MANIFEST.md`, and `awakening_runtime_ingest_status.md` referenced `service_basin_b` as the only Ambulatory gap when it is now ingested but unbound — corrected in this slice.
- Follow-up: manual-follow-up — a design/art-direction decision is needed on how (or whether) `service_basin_b`, the relay lamp, authority-inlay tiles, and ruin decals should be scene/tile-bound given existing baked dressing and the absence of a route-tile/decal placement system; likely belongs to or should be coordinated with `awakening-handoff-readiness-art-convergence-v1`, which already locks this territory.
- What worked: Asset Pipeline V2's plan/ingest/status/doctor loop was clean and fast once the manifest was schema-adapted; the installer's integrity checks (hash/size/dimension) caught nothing wrong because the source bundle was genuinely clean.
