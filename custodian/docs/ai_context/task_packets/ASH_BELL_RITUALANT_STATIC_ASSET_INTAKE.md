# ASH-BELL / RITUALANT STATIC ASSET INTAKE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `ash-bell-ritualant-static-asset-intake`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-ash-bell-ritualant-runtime-truth-closeout`
- Locks: `asset-pipeline, ash-bell-art`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `asset-pipeline, runtime, visual`
- Paired review workstream: `review-ash-bell-ritualant-static-asset-intake`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `bounded production-art publication + live scene wiring`
- Reviewed main: `e888f4cd8a99`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Visual review: `required`
- Goal: Publish and wire the 12 already-reviewed Ritualant ritual-prop/chamber-dressing states through Asset Pipeline V2 without reopening encounter behavior or making the execution agent rediscover art/source decisions.
- Completion boundary: Fetch the exact two approved Dropbox source packages, verify their SHA-256 values, preserve their selected source masters under the declared source-work paths, register/merge exactly two Asset V2 families, ingest all 12 accepted static states, bind them into the authored Ritualant scene as presentation only, update the two requirement rows to Asset V2-derived truth, and prove native-scale scene readability. Do not generate new art in this packet.

- Current measured state: Two approved SHA-256-identified Dropbox archives supply six ritual-prop and six chamber-dressing static states; verify live Asset V2 ingestion and scene-binding state at claim time.
- Evidence: Exact package names, hashes, dimensions and intake paths below; `custodian/game/world/events/ash_bell/forlorn_ritualant_site.tscn`; current Asset V2 catalog/requirements registry and authored encounter spec.
- Task-specific authority: Current Asset Pipeline V2 schema and `custodian/tools/assets/asset.py` govern ingestion; authored Ritualant encounter spec/mapper govern placement; scene owns visual consumers; required-assets registry owns requirements.
- Work surface: `custodian/asset_drop/source_work/ash_bell/`, both `custodian/asset_drop/inbox/ash_bell_*` families, corresponding Asset V2 family contracts, Ritualant scene, and `custodian/content/metadata/assets/required_assets.registry.json`.
- Change: Verify both archive hashes; preserve exact source masters; register/merge two Asset V2 families; ingest 12 accepted static states; bind presentation-only scene sprites; migrate two requirement rows to derived Asset V2 status.
- Preserve: Broken chapel bell, Stilling Pin gating, White Thread gameplay hazard, authored room collision/navigation, Lower Quarter Seal, encounter combat/dialogue/timing, and existing attack/death animation families.
- Non-goals: No generated art, rise/reaction animation, apparition/procession/Fountain art, audio, route changes, encounter mechanics or alpha-driven collision/navigation.
- Acceptance: Both hashes pass; 12/12 exact RGBA states have healthy canonical Asset V2 status and scene consumers; both requirement rows derive from Asset V2; gameplay is unchanged; native-scale visual review is approved.
- Validation: Run SHA-256 checks, Asset V2 plan/status/doctor and needs check, existing asset-pipeline/requirements smokes, three existing Ritualant Godot smokes, `custodian/tools/validation/run_validation.py --changed --json`, and `git diff --check`.
- Deferred: Ritualant animations, apparition/procession, Dry Fountain, audio, and the broad production-art closeout refresh after the reviewed static intake.

## Approved durable source batch

Dropbox batch root:

`/CUSTODIAN/asset_batches/ash-bell-ritualant/ritual-props-chamber-dressing-v1/`

Primary package:

`custodian_ash_bell_ritual_props_chamber_dressing_handoff_v1.zip`

SHA-256:

`e814165c67a64ba93017c8b5651158ce118254d136050af9e4ce9ef07bd3d185`

Closeout addendum:

`custodian_ash_bell_chamber_static_closeout_handoff_v1.zip`

SHA-256:

`697923fa8782355aa7ba0c7cb2b893f5517e355d88880869d97e3396540b0412`

The first package contains `MANIFEST.json`, `README_IMPLEMENTATION.md`, `SHA256SUMS.txt`, two family-contract drafts, six ritual-prop sources + normalized candidates, and four chamber-dressing sources + normalized candidates. The closeout package contains the remaining two chamber states, `FAMILY_STATE_ADDENDUM.json`, manifest/instructions/checksums, and one alternate wrapped seal-marker donor under `references/alternates/`. That alternate is **reference only** and must not be ingested as a required runtime state.

Dropbox is durable source transport, not runtime authority. Asset Pipeline V2 remains publication authority.

## Exact accepted states

### `ash_bell_ritual_props`

Source-work:
`custodian/asset_drop/source_work/ash_bell/ash_bell_ritual_props/`

Inbox:
`custodian/asset_drop/inbox/ash_bell_ritual_props/`

Family:
`custodian/content/metadata/assets/families/ash_bell_ritual_props.asset.json`

- `empty_bell_frame` — 96×96, 1f
- `stilling_pin` — 32×32, 1f
- `white_thread_floor_a` — 32×32, 1f
- `white_thread_floor_b` — 32×32, 1f
- `white_thread_hanging` — 32×64, 1f
- `white_thread_knot` — 16×16, 1f

### `ash_bell_chamber_dressing`

Source-work:
`custodian/asset_drop/source_work/ash_bell/ash_bell_chamber_dressing/`

Inbox:
`custodian/asset_drop/inbox/ash_bell_chamber_dressing/`

Family:
`custodian/content/metadata/assets/families/ash_bell_chamber_dressing.asset.json`

- `black_banner_hanging` — 32×64, 1f
- `black_banner_torn` — 32×48, 1f
- `black_banner_floor` — 32×32, 1f
- `ash_child_handprints` — 32×32, 1f
- `west_gate_seal_marker` — 32×64, 1f
- `sealed_gate_scratches` — 32×32, 1f

All states are static RGBA true-alpha presentation. No raster state owns collision, navigation, interaction, thread tension, or encounter resolution.

## Zero-search retrieval / staging commands

Run from repository root. Use these exact commands first; do not search Dropbox manually.

```bash
set -euo pipefail
STAGE="$(mktemp -d)"
BATCH='git-dropbox-sync:/CUSTODIAN/asset_batches/ash-bell-ritualant/ritual-props-chamber-dressing-v1'

rclone copyto "$BATCH/custodian_ash_bell_ritual_props_chamber_dressing_handoff_v1.zip"   "$STAGE/ritual_props_chamber_v1.zip"
rclone copyto "$BATCH/custodian_ash_bell_chamber_static_closeout_handoff_v1.zip"   "$STAGE/chamber_closeout_v1.zip"

echo 'e814165c67a64ba93017c8b5651158ce118254d136050af9e4ce9ef07bd3d185  '"$STAGE"'/ritual_props_chamber_v1.zip' | sha256sum -c -
echo '697923fa8782355aa7ba0c7cb2b893f5517e355d88880869d97e3396540b0412  '"$STAGE"'/chamber_closeout_v1.zip' | sha256sum -c -

unzip -q "$STAGE/ritual_props_chamber_v1.zip" -d "$STAGE"
unzip -q "$STAGE/chamber_closeout_v1.zip" -d "$STAGE"

B1="$STAGE/CUSTODIAN_ash_bell_ritual_props_chamber_dressing_handoff_v1"
B2="$STAGE/CUSTODIAN_ash_bell_chamber_static_closeout_handoff_v1"

cat "$B1/MANIFEST.json" >/dev/null
cat "$B2/MANIFEST.json" >/dev/null
```

If `git-dropbox-sync:` is not configured, use the repository's `custodian/tools/iteration/dropbox_transport.py` remote-resolution rules; do not guess credentials or search arbitrary Dropbox folders.

## Exact repository staging commands

First preserve source masters and stage the reviewed exact-canvas candidates:

```bash
set -euo pipefail

mkdir -p   custodian/asset_drop/source_work/ash_bell/ash_bell_ritual_props   custodian/asset_drop/source_work/ash_bell/ash_bell_chamber_dressing   custodian/asset_drop/inbox/ash_bell_ritual_props   custodian/asset_drop/inbox/ash_bell_chamber_dressing

rsync -a "$B1/payload/custodian/asset_drop/source_work/ash_bell/ash_bell_ritual_props/"   custodian/asset_drop/source_work/ash_bell/ash_bell_ritual_props/
rsync -a "$B1/payload/custodian/asset_drop/source_work/ash_bell/ash_bell_chamber_dressing/"   custodian/asset_drop/source_work/ash_bell/ash_bell_chamber_dressing/
rsync -a "$B2/payload/custodian/asset_drop/source_work/ash_bell/ash_bell_chamber_dressing/"   custodian/asset_drop/source_work/ash_bell/ash_bell_chamber_dressing/

rsync -a "$B1/payload/custodian/asset_drop/inbox/ash_bell_ritual_props/"   custodian/asset_drop/inbox/ash_bell_ritual_props/
rsync -a "$B1/payload/custodian/asset_drop/inbox/ash_bell_chamber_dressing/"   custodian/asset_drop/inbox/ash_bell_chamber_dressing/
rsync -a "$B2/payload/custodian/asset_drop/inbox/ash_bell_chamber_dressing/"   custodian/asset_drop/inbox/ash_bell_chamber_dressing/
```

Do **not** copy `$B2/references/alternates/west_gate_seal_marker_alt_wrapped_source.png` into inbox/runtime.

## Family registration

Before mutation:

```bash
python3 custodian/tools/assets/asset.py families | grep -E 'ash_bell_(ritual_props|chamber_dressing)' || true
```

If either family already exists on live main, merge the packet states into it instead of overwriting. If both are absent, the package drafts are the starting contract:

```bash
cp "$B1/family_contract_drafts/ash_bell_ritual_props.asset.json"   custodian/content/metadata/assets/families/ash_bell_ritual_props.asset.json
cp "$B1/family_contract_drafts/ash_bell_chamber_dressing.asset.json"   custodian/content/metadata/assets/families/ash_bell_chamber_dressing.asset.json
```

Then merge the two closeout states from `$B2/FAMILY_STATE_ADDENDUM.json` into the live `ash_bell_chamber_dressing.asset.json`. Reconcile current-main schema mechanically; do not redesign state names, dimensions, or art.

## Exact Asset V2 commands

Run the read-only plans first:

```bash
python3 custodian/tools/assets/asset.py plan ash_bell_ritual_props
python3 custodian/tools/assets/asset.py plan ash_bell_chamber_dressing
```

If the plan resolves exactly the 6 + 6 states above with no unexpected replacement/conflict, ingest:

```bash
python3 custodian/tools/assets/asset.py ingest ash_bell_ritual_props --yes --godot-import
python3 custodian/tools/assets/asset.py ingest ash_bell_chamber_dressing --yes --godot-import
python3 custodian/tools/assets/asset.py status ash_bell_ritual_props
python3 custodian/tools/assets/asset.py status ash_bell_chamber_dressing
python3 custodian/tools/assets/asset.py doctor
```

Canonical runtime filenames/paths come from Asset V2. Do not hand-author them.

## Live scene wiring

Consumer:
`custodian/game/world/events/ash_bell/forlorn_ritualant_site.tscn`

Use Asset V2 canonical outputs discovered from plan/status/catalog.

1. `empty_bell_frame`: add a presentation Sprite2D under `Props/EmptyBellFrame` behind the existing `Props/EmptyBellFrame/BrokenBell`. **Do not remove the visible broken ordinary chapel bell.** The new frame is the support/frame layer, not the historical Ninth Bell.
2. `stilling_pin`: replace the legacy texture currently bound at `Props/StillingPinPickup/Visual` (live ext-resource currently points to `res://content/tiles/encounters/ritualant_set/stilling_pin_pickup_01.png`).
3. `white_thread_floor_a/b`, `white_thread_hanging`, `white_thread_knot`: create/reuse a presentation-only `Props/WhiteThreadWeb` group. Register these around the existing authored White Thread/hazard composition and bell-frame/ritual dressing. They must not add/alter Area2D or CollisionShape2D nodes and must not imply the upstream White Thread Knot inventory item is obtainable here.
4. `black_banner_hanging/torn/floor`: populate the existing `Props/BlackBanners` presentation group while preserving its current candle children. No heraldry; these are emergency/funerary cloth.
5. `ash_child_handprints`: add/reuse a presentation-only `Props/ChildHandprints` node in the authored south/chamber storytelling zone.
6. `west_gate_seal_marker` + `sealed_gate_scratches`: add/reuse a presentation-only west-gate/sealed-arch dressing group on the chamber's west-side narrative surface. These must not create a real route/collision gate or conflict with the separate northern Lower Quarter Seal in the authored Underground wrapper.

Use `design/02_features/enemy_objective/FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md` and the current mapper as placement/composition authority. Do not invent gameplay semantics from the raster.

## Requirements migration

Update:

`custodian/content/metadata/assets/required_assets.registry.json`

Migrate these two manual needs to Asset V2 family/state requirements:

- `ash-bell-ritual-prop-sprites` -> family `ash_bell_ritual_props`, all six required states.
- `ash-bell-chamber-dressing-props-decals` -> family `ash_bell_chamber_dressing`, all six required states.

Then regenerate/check the generated view:

```bash
python3 custodian/tools/assets/asset.py needs --write
python3 custodian/tools/assets/asset.py needs --check
```

Do not mark unrelated Ritualant rise, apparition/procession, Dry Fountain, or audio requirements fulfilled.

## Validation

Fast deterministic checks first:

```bash
python3 custodian/tools/validation/asset_pipeline_v21_production_smoke.py
python3 custodian/tools/validation/asset_requirements_smoke.py
python3 custodian/tools/assets/asset.py status ash_bell_ritual_props
python3 custodian/tools/assets/asset.py status ash_bell_chamber_dressing
python3 custodian/tools/assets/asset.py doctor
```

Then encounter/scene regressions:

```bash
godot --headless --path custodian --script res://tools/validation/forlorn_ritualant_completion_smoke.gd
godot --headless --path custodian --script res://tools/validation/forlorn_ritualant_mapper_semantics_smoke.gd
godot --headless --path custodian --script res://tools/validation/levels/forlorn_ritualant_underground_smoke.gd
python3 custodian/tools/validation/run_validation.py --changed --json
git diff --check
```

Add the smallest focused static-art contract smoke if existing tests do not prove all 12 Asset V2 states, exact frame dimensions, true alpha, and scene consumer references.

## Visual acceptance

Publish one compact native-scale Ritualant chamber review only after deterministic checks pass. Required questions:

1. Do the bell frame + existing broken bell read as chapel infrastructure rather than a fantasy shrine?
2. Does the Stilling Pin remain readable at 32×32?
3. Does White Thread read as physical funerary craft, not occult glyphwork/spiderweb?
4. Do black banners remain restrained and non-heraldic?
5. Are handprints, west-gate marker, and scratches legible without becoming hero props?
6. Is combat/traversal readability unchanged?

## Preserve

- encounter dialogue/state/combat/timing;
- current White Thread hazard collision/tension authority;
- current Stilling Pin interaction gating;
- existing broken chapel bell;
- authored room geometry/navigation;
- northern Lower Quarter Seal ownership;
- current canonical attack/death animation families.

## Non-goals

- No new image generation.
- No Ritualant rise/locomotion/reaction art.
- No Unarrived Saint/procession art.
- No Dry Fountain art.
- No audio.
- No route/procgen changes.
- No collision/navigation derived from prop alpha.

## Acceptance

- Both package hashes verify exactly.
- 12/12 selected states are preserved in source-work and published through Asset V2 with exact dimensions and true alpha.
- `ash_bell_ritual_props` and `ash_bell_chamber_dressing` are healthy and catalog-backed.
- The two required-assets rows derive complete from Asset V2 rather than manual `fulfilled` claims.
- All 12 states have explicit presentation consumers in the authored scene.
- Existing interaction/collision/encounter behavior is unchanged.
- Native-scale visual review passes.
- Focused validations, changed-file validation, and `git diff --check` pass.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill>`
- Completion boundary satisfied: `<fill>`
- Acceptance satisfied: `<fill>`
- Superseded/legacy production path disposition: `<fill>`
- Evidence: `<fill>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill>`
- Friction severity: `<fill>`
- What went wrong: `<fill>`
- Root cause / contributing factors: `<fill>`
- Prevention / pipeline improvement: `<fill>`
- Tooling / docs drift discovered: `<fill>`
- Follow-up: `<fill>`

## Handoff

- Next workstream: `ash-bell-forlorn-ritualant-production-art-closeout`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Summary backlink: Include this exact Authoring chat URL in every durable implementation/review/correction/recovery/closeout summary and final Next Handoff.
- Refresh reason: After these 12 static assets land, the remaining broad art closeout should be narrowed to only still-factual animation/apparition/procession/fountain/audio needs.
- Next action: Return this packet's implementation + paired-review evidence to the authoring chat, then refresh the broad art closeout.
- Blockers or open questions: none beyond the predecessor runtime-truth review dependency.
