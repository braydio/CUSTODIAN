# KENNEY PATTERN LINES SOURCE LIBRARY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `kenney-pattern-lines-source-library`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `asset-pipeline`
- Kind: `implementation`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, asset-pipeline`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `0`
- Review rationale: `low-risk exemption: this slice only preserves third-party reference PNGs and provenance/index metadata under source_work; it does not normalize, ingest, publish, bind, or mutate production/runtime assets`
- Reviewed main: `69dfd9c5ea48`
- Authoring chat: `not-recorded`
- Goal: Preserve the user's four downloaded Kenney Pattern Pack Lines variants as a durable, searchable, provenance-complete CUSTODIAN source-material library so future production asset work can reuse individual motifs without re-downloading or rediscovering the pack.
- Completion boundary: Discover the four actual local Pattern Pack Lines deliveries in `~/Downloads`; verify the common 30-pattern identity set and expected size/thickness variants; copy all 120 PNGs byte-for-byte into one reference-only source_work library; preserve the bundled license/provenance; write one manifest and one concise usage index carrying the approved motif shortlist below; update the AI file index. Done means a later packet can name `pattern_###` plus a variant and resolve exact source bytes without touching the original downloads.
- Current measured state: The user supplied four galleries of the same 30 motifs, naturally corresponding to `pattern_000.png` through `pattern_029.png`: default 256px, doubled 512px thick, thin 256px, and thin 512px. Live main has task-scoped Kenney experimental source_work under `asset_drop/source_work/experiments/kenney_presentation/`, but no general reusable third-party source-material library. Production Asset V2 remains the required promotion route once any reference material becomes a real game asset.
- Evidence: `custodian/docs/ASSET_LAYOUT_CONVENTION.md` keeps source/master art out of runtime and routes registered production families through Asset V2; `custodian/docs/ai_context/reports/kenney_presentation/k3d1_source_inventory.json` provides the existing Kenney provenance/hash/license pattern; current K3D assets are explicitly experiment-scoped rather than a general material library.
- Task-specific authority: `custodian/docs/ASSET_LAYOUT_CONVENTION.md`; `custodian/docs/ai_context/reports/kenney_presentation/k3d1_source_inventory.json`.
- Work surface: primary owner `custodian/asset_drop/source_work/reference/kenney/pattern_pack_lines/`; adjacent docs `custodian/docs/ai_context/FILE_INDEX.md`. Local input discovery is limited to `~/Downloads`.
- Change: Implement the exact source-library contract below. Discover local roots from their contents rather than assuming download folder/archive names. Preserve source bytes exactly. The library is reference-only and must never be read by runtime code.
- Preserve: Existing K3D experimental families and sources; all current Asset V2 family/catalog/runtime truth; local downloaded originals; Kenney license text and exact source bytes.
- Non-goals: Do not create an Asset V2 family for the full pattern pack. Do not copy these files into `asset_drop/inbox/` or `res://content/`. Do not wire any pattern into a scene. Do not regenerate, recolor, resize, flatten, or otherwise derive production art in this workstream. Do not commit original ZIP archives.
- Acceptance: Exactly 30 PNGs exist in each of four variant folders, for 120 PNGs total; every copied file hash matches its local source; default/thin 256 variants are exactly 256x256 and doubled/thin-512 variants are exactly 512x512; pattern IDs are one-to-one across variants; license/provenance is recorded; the usage index includes every approved immediate and future motif listed below; no runtime/inbox files are added; `git diff --check` passes.
- Validation: Run one local Python verification that checks count, natural-sort pattern IDs, exact dimensions, SHA-256 source/copy equality, and cross-variant ID parity; then `git diff --check`. No Godot or Asset V2 ingest is required because this packet intentionally creates no production asset.
- Task overrides: `none`
- Deferred: Promotion of selected motifs into production art; Awakening Undergate foreground/underlay regeneration; the Gate wind-dust seam correction; Meridian hardened-floor/hardstand derivative work.

## Exact Source Library Layout

Create:

```text
custodian/asset_drop/source_work/reference/kenney/pattern_pack_lines/
    README.md
    LICENSE.txt
    manifest.json
    default_256/
        pattern_000.png
        ...
        pattern_029.png
    double_thick_512/
        pattern_000.png
        ...
        pattern_029.png
    thin_256/
        pattern_000.png
        ...
        pattern_029.png
    thin_512/
        pattern_000.png
        ...
        pattern_029.png
```

The repository folder names above are canonical even if the user's downloaded folders use different labels. Resolve the four local roots by inspecting dimensions/content and the bundled license, then copy exact PNG bytes into these normalized reference-library locations.

If the actual delivered filenames differ from `pattern_000.png` through `pattern_029.png`, stop and report the mismatch rather than inventing a mapping.

## Manifest Contract

`manifest.json` is reference metadata, not an Asset V2 family contract. Record at minimum:

- pack title and detected local source root/archive;
- license ID/text source;
- canonical variant ID;
- original relative source path;
- pattern ID;
- width/height;
- SHA-256;
- exact-copy boolean;
- usage tier: `immediate_candidate`, `future_candidate`, or `reference_only`;
- semantic tags from the shortlist below;
- preferred production-source variant where specified.

Do not invent a production runtime path. Future asset work must promote a selected motif by copying/deriving it into the owning production family's ordinary:

```text
custodian/asset_drop/source_work/<area>/<family>/<state>_source.png
custodian/asset_drop/inbox/<family>/<state>.png
custodian/content/metadata/assets/families/<family>.asset.json
```

and then use current Asset Pipeline V2.

## Approved Motif Classification

The user-facing gallery numbers are 1-based; repository filenames are 0-based.

### Immediate CUSTODIAN candidates

| Gallery | Pattern | Preferred source | Tags / intended role |
| ---: | --- | --- | --- |
| 7 | `pattern_006` | `thin_512` | anti-slip herringbone, service tread, broken catwalk fill |
| 8 | `pattern_007` | `thin_512` | machinery grille, louver/register face, technical panel |
| 9 | `pattern_008` | `thin_512` | woven service grate, industrial tread, dense maintenance fill |
| 14 | `pattern_013` | `thin_512` | truss mesh, gantry lattice, braced screen |
| 15 | `pattern_014` | `thin_512` | maintenance plate seams, service-panel subdivision |
| 18 | `pattern_017` | `thin_512` | square service grid, hatch matrix, modular floor panel |
| 23 | `pattern_022` | `double_thick_512` | structural X-brace, large frame reinforcement |
| 24 | `pattern_023` | `thin_512` | diamond guard mesh, catwalk/vent lattice |
| 28 | `pattern_027` | `thin_512` | dense guard lattice, grille field, industrial mesh |
| 29 | `pattern_028` | `double_thick_512` | broad directional chevron, threshold/service direction band |
| 30 | `pattern_029` | `double_thick_512` | repeated directional chevrons, airflow/route band |

### Future candidates

Tag these for later inspection without promoting them now:

- `pattern_000` — civic slab / four-quadrant registration geometry.
- `pattern_002`, `pattern_003` — elongated cell / structural framework; use cautiously because they can read generic sci-fi.
- `pattern_004` — simple diagonal lattice.
- `pattern_009` — registered square/diamond civic grid; keep separate from brass Authority Inlays.
- `pattern_016` — large quadrant/grid seam.
- `pattern_018`, `pattern_019` — diamond framing / repeated diamond cells.
- `pattern_024` — octagonal structural frame.
- `pattern_026` — sparse diagonal lattice.

All remaining pattern IDs are `reference_only` for now. In particular, rounded/circular motifs and ornate interlocks should not be treated as approved Awakening vocabulary merely because they are preserved in the library.

## README Content

The library README must state:

1. this folder contains third-party source/reference material, not runtime authority;
2. all 120 PNGs are retained to avoid destructive preselection;
3. the manifest owns provenance/hash/variant/usage tags;
4. only the shortlist above has current CUSTODIAN design approval;
5. production use requires copying/deriving a selected source into the real owning Asset V2 family and ingesting it normally;
6. direct scene/runtime references into this reference folder are forbidden.

## Documentation Drift Check

Do not fold Pattern Pack Lines into the K3D-1/K3D-2/K3D-3 roadmap simply because it is Kenney material. That roadmap evaluates presentation architecture and its selected experimental packs. Pattern Pack Lines is a cross-cutting source-material library.

If live main now contains a general third-party/reference source library that this packet's reviewed main did not expose, reuse that surviving convention instead of creating a parallel root, and update this packet before completion to record the actual canonical path.

## Next Handoff

- Next workstream: `awakening-undergate-presentation-repair`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `not-recorded`
- Refresh reason: `The source library should land first so the Undergate repair can cite immutable pattern IDs/variants and promote only the selected motifs into the existing awakening_undergate_environment Asset V2 family.`
- Next action: `After this library lands, refresh/authenticate the Undergate repair against current main, then regenerate the foreground and selected underlay details while fixing the Gate wind-dust seam.`
- Blockers or open questions: `none for source-library intake`
