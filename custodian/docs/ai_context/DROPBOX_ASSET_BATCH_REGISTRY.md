# CUSTODIAN Dropbox Asset Batch Registry

**Status:** active workflow authority  
**Root:** `CUSTODIAN/asset_batches/`  
**Registry:** `CUSTODIAN/asset_batches/_registry/`  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d

## Purpose

Use this document to find durable authored asset handoffs in Dropbox without searching arbitrary nested folders or confusing visual-review evidence with implementation input.

Dropbox has three distinct asset/presentation lanes:

```text
CUSTODIAN/visual_review/
    outbound screenshots, contact sheets, metrics and human-review evidence

CUSTODIAN/asset_batches/
    durable authored source/master asset batches and their registry records

CUSTODIAN/implementation_inputs/
    immutable implementation handoffs explicitly consumed by task packets
```

Git remains authority for code, design, task packets, schemas and durable project truth. Asset Pipeline V2 remains authority for source-work/inbox/runtime promotion.

## Discovery Contract

Before searching Dropbox broadly, inspect:

```text
CUSTODIAN/asset_batches/_registry/
```

The registry contains:

- `README.md` — Dropbox batch tracking rules;
- `CUSTODIAN_ASSET_UPLOAD_INDEX.md` — human-readable current index;
- `CUSTODIAN_ASSET_UPLOAD_INDEX.json` — machine-readable index;
- one immutable `<batch-id>.json` receipt per tracked batch.

Supported registry status values:

```text
active
superseded
reference_only
blocked_input
landed
```

When a batch is replaced, preserve the old receipt and mark it `superseded`; do not silently delete provenance.

## Current Alpine Cliff Source Batch

The active approved high-resolution source-master batch for AP2 is:

```text
batch_id: alpine-cliff-source-family-v1
workstream: procgen-alpine-cliff-presentation-v1
status: active

Dropbox folder:
CUSTODIAN/asset_batches/procgen-alpine-presentation/alpine-cliff-source-family-v1/

Primary package:
custodian_alpine_cliff_source_family_v1.zip

SHA-256:
e804c5d9d55f0610cafde5f4169a6b36438b0e08469b212ac3fff84618b127f3
```

The batch contains 12 approved high-resolution source masters plus:

```text
HANDOFF_MANIFEST.json
ASSET_MANIFEST.md
CHECKSUMS.sha256
README.md
CONTACT_SHEET.png
```

The batch manifest is source-master authority for the current gray-granite Alpine cliff family. It is not itself the final Asset V2 runtime payload.

The previous batch:

```text
CUSTODIAN/asset_batches/procgen-alpine-presentation/alpine-assets-11-20-v2/
```

is registered `superseded` and must not be used as current production source.

## Codex Retrieval Instructions

For AP2, Codex should:

1. Read the live task packet and `design/02_features/procgen/ALPINE_PLATEAU_PRESENTATION_ASSET_MANIFEST.md`.
2. Inspect the Dropbox registry record for `alpine-cliff-source-family-v1`.
3. Fetch `custodian_alpine_cliff_source_family_v1.zip` from the exact active batch folder into temporary staging outside the repository.
4. Verify the package SHA-256 exactly:
   `e804c5d9d55f0610cafde5f4169a6b36438b0e08469b212ac3fff84618b127f3`.
5. Extract only in temporary staging. Read `ASSET_MANIFEST.md` and `HANDOFF_MANIFEST.json` before moving any image.
6. Preserve the source masters under the manifest-declared `asset_drop/source_work/procgen/...` destinations.
7. Derive normalized target images with the project pixel-art resizer/normalizer and explicit alpha cleanup. Do not smooth-scale or nonuniformly squash the masters.
8. Route derived semantic states through Asset Pipeline V2 inbox/family contracts.
9. Validate assembled fascia runs and directional contact compositions before claiming Gate B complete.
10. Produce the exact immutable Gate B implementation handoff only after all final runtime target states pass the packet's technical checks.

If the configured Dropbox remote is not literally named `dropbox:`, use the repository's `custodian/tools/iteration/dropbox_transport.py` remote-resolution rules rather than guessing credentials or remote names.

## Source-Master Versus Runtime Authority

The high-resolution source masters are deliberately richer than their runtime derivatives.

For fascia:

```text
approved source master
    -> crop/select semantic geological fragment
    -> pixel-art normalization/resizer
    -> alpha cleanup
    -> exact semantic state
    -> assembled 4-8 tile repetition test
    -> Asset V2 inbox/runtime publication
```

For contact/depth plates:

```text
approved large source master
    -> crop/recompose at the required directional target
    -> preserve projection and lighting
    -> alpha cleanup
    -> exact manifest canvas
    -> deterministic placement test
    -> Asset V2 publication
```

Do not infer collision, navigation, terrain masks, walkability or claim ownership from source-image alpha.

## Tracking Rule For Future Asset Uploads

Every future durable asset upload should receive:

- a unique immutable `batch_id`;
- one canonical batch folder under `CUSTODIAN/asset_batches/<workstream>/<batch-id>/`;
- source-chat backlink;
- asset count;
- package checksum;
- `HANDOFF_MANIFEST.json`;
- `CHECKSUMS.sha256`;
- `README.md`;
- one registry receipt under `CUSTODIAN/asset_batches/_registry/<batch-id>.json`;
- an explicit current status.

Do not use `visual_review/` as implementation authority and do not use a mutable `latest` pointer as a task-packet gate.
