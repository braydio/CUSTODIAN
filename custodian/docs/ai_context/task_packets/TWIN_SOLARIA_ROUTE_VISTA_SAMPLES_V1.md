# TWIN SOLARIA ROUTE VISTA SAMPLES V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `twin-solaria-route-vista-samples-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `twin-solaria-runtime, asset-catalog`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual, asset-pipeline`
- Paired review workstream: `review-twin-solaria-route-vista-samples-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `eae7f4a7175b`
- Goal: Ingest the three newly pushed Twin Solaria archway-view images as neutral Route Vista sample content for Solarium I, wire a presentation-only first-pass sampler at the canonical Resolved Route Vista registration, and make those samples reusable by later route-review/acquisition presentation without inventing traversal or destination canon.
- Completion boundary: Preserve the three archive originals as provenance inputs; copy them into a dedicated source-work family; normalize three static vista states through Asset Pipeline V2; bind a production-safe presentation component at the existing 465x280 Resolved Route Vista region; keep normal production Twin visually unchanged; add a playtest-only deterministic sample preview/capture path; generate one human-review capture per sample and run the existing kitty/xdg-open human approval gate before closeout.
- Current measured state: commit `eae7f4a7175bf6681f7fb1bcdba707fede683095` adds exactly three Git LFS PNGs under `archive/Hubworld/Level_Upscaling/`: `twin_solaria_archway_ancient_civ.png` (LFS sha256 `8b9089f1a3f05f155d7c61f08617ba7d02948c14bdb4ef416f0305df7cb2bce9`, 738815 bytes), `twin_solaria_archway_bloodborne.png` (`6d11ff3213c12d07faff2f5371f80b6b2c058da554bb97a698439ff8d01f7e66`, 680312 bytes), and `twin_solaria_archway_erd_tree.png` (`cc1989e99f50e2dc5542de64ee40dc98dc5a5ba4ef4db57afc470e55c937f4a6`, 956688 bytes). The GitHub connector exposes LFS pointers, so local implementation must inspect decoded pixel dimensions before normalization. The canonical Resolved Route Vista reference is 465x280 at Godot center `(-686.5,-453.0)`. No dedicated vista-sample family exists and the full Solarium I acquisition packet remains unclaimed.
- Evidence: `design/05_levels/TWIN_SOLARIA.md`; `custodian/asset_drop/source_work/hub/twin_solaria_v1_reference/{PLACEMENT_MANIFEST.json,CROP_MANIFEST.json}`; Twin production scene/layout; commit `eae7f4a7175...`.
- Task-specific authority: Twin Solaria Solarium I / Resolved Route Vista canon; current Asset Pipeline V2; existing 2048x1536 production coordinate authority.
- Change: Add `twin_solaria_route_vista_samples` as a static backdrop family with neutral states `candidate_01`, `candidate_02`, `candidate_03`; add a presentation-only vista owner that can show one sample, weak/partial sample, deterministic conflicting-sample bands, or hide the override; add a playtest/debug harness without changing production default behavior.
- Preserve: Existing environment/fidelity families and plate registration; physical aperture/court art; no new route-state authority; no Solarium I traversal; no Solarium II reconstruction; no runtime/player-facing use of third-party inspiration names; no direct runtime binding to `archive/`.
- Non-goals: No route-review gameplay; no HOLD/ABORT/AUTHORIZE logic; no acquisition animation; no anchor/witness FX; no Passage; no destination canon assignment; no cross-map travel; no environment repaint.
- Acceptance: All three source objects have actual decoded dimensions/hash recorded locally; source-work copies preserve provenance; normalized runtime states are exactly 465x280, one frame each, with no stretching; any crop is aspect-preserving and human-reviewed; presentation is centered at `(-686.5,-453.0)` and does not duplicate the physical aperture frame; production Twin is unchanged when sample override is disabled; playtest preview deterministically displays all three samples plus weak/conflict modes; Asset V2 plan/status/doctor are green; three human-review captures pass the agent-launched kitty sequence.
- Validation: Focused family/registration/presentation smoke plus three same-framing renderer captures. Run focused checks before changed-file validation and `git diff --check`.
- Task overrides: `none`
- Deferred: Full Slice E resolve/stable/warning/shutdown FX; canonical narrative identity of any sample; animated vista parallax; route candidate data integration; additional vista art.

## Canonical Interpretation

The large upper-left circle is `Solarium I / Acquisition Aperture`.

The image shown inside it is the `Resolved Route Vista`: a remote observational destination sample, not local sky and not passage permission.

The new images are candidate vista contents, not three portals and not three machine states.

## Source Inputs And Neutral Runtime Naming

Archive filenames remain provenance only:

```text
archive/Hubworld/Level_Upscaling/twin_solaria_archway_ancient_civ.png
archive/Hubworld/Level_Upscaling/twin_solaria_archway_bloodborne.png
archive/Hubworld/Level_Upscaling/twin_solaria_archway_erd_tree.png
```

Do not use `bloodborne` or `erd_tree` in runtime ids, family states, canon labels, or player-facing text.

Map deterministically:

```text
candidate_01 <- twin_solaria_archway_ancient_civ.png
candidate_02 <- twin_solaria_archway_bloodborne.png
candidate_03 <- twin_solaria_archway_erd_tree.png
```

## Asset Pipeline V2

Family target:

```text
custodian/content/metadata/assets/families/
twin_solaria_route_vista_samples.asset.json
```

Contract intent:

```text
id: twin_solaria_route_vista_samples
kind: backdrop
runtime domain: levels/hub/twin_solaria/vista_samples
direction: omni
auto mirror: false
canvas: 465x280
```

Use current live schema fields/tooling.

Source-work exact destinations:

```text
custodian/asset_drop/source_work/hub/twin_solaria_route_vista_samples/
    candidate_01_source.png
    candidate_02_source.png
    candidate_03_source.png
```

Copy the exact original pixels first. Record decoded dimensions, color/alpha mode, SHA-256, source archive path, and LFS object SHA.

Normalized inbox:

```text
custodian/asset_drop/inbox/twin_solaria_route_vista_samples/
    candidate_01.png
    candidate_02.png
    candidate_03.png
```

All three normalized states:

```text
canvas: 465x280
frames: 1
fps: 0
loop: false
role: full-bleed static vista content
```

Never stretch.

Normalization priority:

1. preserve aspect ratio;
2. use aspect-preserving cover crop to 465x280 when composition survives;
3. if cover crop damages the focal composition, use contained fit with dark Crown-Verge-style padding;
4. if a source includes the physical arch/frame, crop out only the destination content so the runtime does not double-render architecture;
5. human-review the normalized result.

Do not normalize until actual decoded source dimensions are known.

## Runtime Registration

Canonical vista region from the preserved master:

```text
master crop: x=105, y=175, width=465, height=280
Godot center: (-686.5,-453.0)
```

Create a focused presentation owner, e.g. `TwinSolariaVistaPresentation`.

It owns only:

```text
selected sample id
display mode
sample alpha/reveal
band/slice composition
```

It owns no route safety, authorization, traversal, or campaign state.

`TwinSolariaLayout` remains spatial authority and may expose the vista bounds/center.

## First-Pass Composition

The current production plate already paints the old golden vista.

In preview mode:

1. cover exactly the canonical 465x280 vista region with a dark/neutral presentation cover;
2. display the selected sample above that cover;
3. clip/feather inside the vista region so the physical arch/court remains readable;
4. do not redraw the circle, arch, anchors, or court.

If the exact rectangle overlaps visible aperture architecture, use the smallest inner mask/feather needed. Do not alter the environment plate.

Normal production after this task keeps the sample override disabled, preserving current appearance until Slice E drives it.

## Display Modes

`hidden`
- sample override off.

`candidate_weak`
- one deterministic sample at roughly 25-45% effective visibility using a stable partial-reveal mask.

`candidate_conflict`
- deterministic horizontal/vertical bands drawn from two or three samples.
- no per-frame random flicker.
- purpose: show contradictory/incomplete route reconstruction.

`candidate_resolved`
- one selected sample fills the vista cleanly.
- presentation preview only; not AUTHORIZE ACQUISITION.

## Playtest / Capture Harness

Use either a dedicated `twin_solaria_vista_samples_playtest.tscn` or a playtest-only controller over the current Twin wrapper.

It must expose deterministic preview of:

```text
candidate_01 resolved
candidate_02 resolved
candidate_03 resolved
candidate_weak
candidate_conflict
```

No permanent production debug keybind is required. Focused tests/capture tooling should set modes directly.

## Human Visual Review Gate

Required same-framing captures:

```text
01_candidate_01.png
02_candidate_02.png
03_candidate_03.png
```

Optional weak/conflict diagnostics may also be generated.

The coding agent must not visually approve them.

After structural checks:

1. print absolute capture paths;
2. create `/tmp/custodian_twin_vista_review.sh`;
3. run it itself;
4. use one foreground kitty + `xdg-open` per image;
5. closing current kitty means approve/advance;
6. interrupting the parent sequence means reject/stop;
7. do not close out until all three are approved.

Reuse the control contract established by the Awakening visual-review packet.

## Future Slice E Integration

Keep two independent presentation axes:

```text
route-review state
    |
    +-- selected vista sample id
    |       -> TwinSolariaVistaPresentation
    |
    +-- aperture machine state
            -> twin_solaria_acquisition_aperture_fx
```

Examples:

```text
ROUTE CANDIDATE:
  candidate_02 + candidate_weak

CORRELATING / CONFLICT:
  candidate_01 + candidate_03 + candidate_conflict

AUTHORIZE ACQUISITION:
  selected candidate_03 + acquisition_resolve FX

ACQUISITION STABLE:
  selected candidate_03 + acquisition_stable FX

RECIPROCITY WARNING:
  selected candidate remains visible + reciprocity_warning FX
```

Do not bake destination imagery into aperture FX strips.

## Documentation / Drift

When this lands:

- add the live vista-sample family to `design/05_levels/TWIN_SOLARIA.md`;
- clarify that aperture FX does not own destination imagery;
- update CURRENT_STATE/FILE_INDEX only to live truth;
- preserve archive filenames as provenance only;
- do not canonize these three images as named destinations.

## Completion

Archive this packet, leave paired review active, and write `TWIN_SOLARIA_ROUTE_VISTA_SAMPLES_V1_CLAUDE_SUMMARY.md` with source dimensions/hashes, normalization decisions, V2 status, runtime paths, registration, and human review result.

## Handoff

- Next action: Slice E depends on this family and reuses it rather than generating destination content inside aperture FX.
- Best starting files: the three archive PNGs; resolved-route-vista placement manifests; Twin production scene/layout; live Asset V2 tooling.
- Blockers or open questions: Actual decoded source dimensions and whether each source includes only vista content or also the physical arch must be inspected locally because GitHub exposes these as LFS pointers.
