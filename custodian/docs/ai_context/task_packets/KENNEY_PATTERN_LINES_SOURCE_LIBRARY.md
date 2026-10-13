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
- Current measured state: The user supplied four galleries of the same 30 motifs: default 256px, doubled 512px thick, thin 256px, and thin 512px. The claimed workstream's 2026-10-13 local intake audit found all four Downloads roots use **`pattern_0000.png` through `pattern_0029.png`** (four-digit source stems), rather than the packet's previously assumed three-digit basenames. This is an approved input-name difference, **not** an asset-content exception: normalize source index `0000`–`0029` to canonical reference-library ID `pattern_000`–`pattern_029` without changing PNG bytes. The operator reported a clean existing worktree; revalidate its actual state on resume. Live main has task-scoped Kenney experimental source_work under `asset_drop/source_work/experiments/kenney_presentation/`, but no general reusable third-party source-material library. Production Asset V2 remains the required promotion route once reference material becomes a real game asset.
- Evidence: `custodian/docs/ASSET_LAYOUT_CONVENTION.md` keeps source/master art out of runtime and routes registered production families through Asset V2; `custodian/docs/ai_context/reports/kenney_presentation/k3d1_source_inventory.json` provides the existing Kenney provenance/hash/license pattern; current K3D assets are explicitly experiment-scoped rather than a general material library.
- Task-specific authority: `custodian/docs/ASSET_LAYOUT_CONVENTION.md`; `custodian/docs/ai_context/reports/kenney_presentation/k3d1_source_inventory.json`.
- Work surface: primary owner `custodian/asset_drop/source_work/reference/kenney/pattern_pack_lines/`; adjacent docs `custodian/docs/ai_context/FILE_INDEX.md`. Local input discovery is limited to `~/Downloads`.
- Change: Implement the exact source-library contract below. Discover local roots from their contents rather than assuming download folder/archive names. Accept the verified four-digit source stems with the strict mapping below, write the existing three-digit canonical destination filenames, and record both identities in provenance. Preserve source bytes exactly. The library is reference-only and must never be read by runtime code.
- Preserve: Existing K3D experimental families and sources; all current Asset V2 family/catalog/runtime truth; local downloaded originals; Kenney license text and exact source bytes.
- Non-goals: Do not create an Asset V2 family for the full pattern pack. Do not copy these files into `asset_drop/inbox/` or `res://content/`. Do not wire any pattern into a scene. Do not regenerate, recolor, resize, flatten, or otherwise derive production art in this workstream. Do not commit original ZIP archives.
- Acceptance: Exactly 30 PNGs exist in each of four variant folders, for 120 PNGs total; source stems `pattern_0000`–`pattern_0029` map **by numeric value, without offset**, to repository stems `pattern_000`–`pattern_029` in each variant; original source path/name and mapped canonical ID are both recorded; every copied file SHA-256 matches its local source byte-for-byte; default/thin 256 variants are exactly 256x256 and doubled/thin-512 variants are exactly 512x512; the canonical 30-ID set is identical across all four variants with no duplicates, gaps, extra files, or ID collisions; license/provenance is recorded; the usage index includes every approved immediate and future motif listed below; no runtime/inbox files are added; `git diff --check` passes.
- Validation: Run one local Python verification that checks the 30 numeric source IDs `0000`–`0029` per variant; the explicit zero-offset four-to-three-digit source-to-canonical mapping; unique and identical 30-ID sets across variants; no ambiguous or extra PNGs; exact dimensions; original-path manifest provenance; SHA-256 source/copy equality; then `git diff --check`. No Godot or Asset V2 ingest is required because this packet intentionally creates no production asset.
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

### Approved source-name reconciliation (2026-10-13)

**Planning decision:** All four observed Downloads folders use four-digit input basenames `pattern_0000.png` through `pattern_0029.png`. These are approved input filenames. The library layout above remains canonical **three-digit** naming for all four destination variants; changing a filename during the copy does not authorize changing file contents.

For every source PNG matching the exact pattern `^pattern_([0-9]{4})\\.png# KENNEY PATTERN LINES SOURCE LIBRARY

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
- Current measured state: The user supplied four galleries of the same 30 motifs: default 256px, doubled 512px thick, thin 256px, and thin 512px. The claimed workstream's 2026-10-13 local intake audit found all four Downloads roots use **`pattern_0000.png` through `pattern_0029.png`** (four-digit source stems), rather than the packet's previously assumed three-digit basenames. This is an approved input-name difference, **not** an asset-content exception: normalize source index `0000`–`0029` to canonical reference-library ID `pattern_000`–`pattern_029` without changing PNG bytes. The operator reported a clean existing worktree; revalidate its actual state on resume. Live main has task-scoped Kenney experimental source_work under `asset_drop/source_work/experiments/kenney_presentation/`, but no general reusable third-party source-material library. Production Asset V2 remains the required promotion route once reference material becomes a real game asset.
- Evidence: `custodian/docs/ASSET_LAYOUT_CONVENTION.md` keeps source/master art out of runtime and routes registered production families through Asset V2; `custodian/docs/ai_context/reports/kenney_presentation/k3d1_source_inventory.json` provides the existing Kenney provenance/hash/license pattern; current K3D assets are explicitly experiment-scoped rather than a general material library.
- Task-specific authority: `custodian/docs/ASSET_LAYOUT_CONVENTION.md`; `custodian/docs/ai_context/reports/kenney_presentation/k3d1_source_inventory.json`.
- Work surface: primary owner `custodian/asset_drop/source_work/reference/kenney/pattern_pack_lines/`; adjacent docs `custodian/docs/ai_context/FILE_INDEX.md`. Local input discovery is limited to `~/Downloads`.
- Change: Implement the exact source-library contract below. Discover local roots from their contents rather than assuming download folder/archive names. Accept the verified four-digit source stems with the strict mapping below, write the existing three-digit canonical destination filenames, and record both identities in provenance. Preserve source bytes exactly. The library is reference-only and must never be read by runtime code.
- Preserve: Existing K3D experimental families and sources; all current Asset V2 family/catalog/runtime truth; local downloaded originals; Kenney license text and exact source bytes.
- Non-goals: Do not create an Asset V2 family for the full pattern pack. Do not copy these files into `asset_drop/inbox/` or `res://content/`. Do not wire any pattern into a scene. Do not regenerate, recolor, resize, flatten, or otherwise derive production art in this workstream. Do not commit original ZIP archives.
- Acceptance: Exactly 30 PNGs exist in each of four variant folders, for 120 PNGs total; source stems `pattern_0000`–`pattern_0029` map **by numeric value, without offset**, to repository stems `pattern_000`–`pattern_029` in each variant; original source path/name and mapped canonical ID are both recorded; every copied file SHA-256 matches its local source byte-for-byte; default/thin 256 variants are exactly 256x256 and doubled/thin-512 variants are exactly 512x512; the canonical 30-ID set is identical across all four variants with no duplicates, gaps, extra files, or ID collisions; license/provenance is recorded; the usage index includes every approved immediate and future motif listed below; no runtime/inbox files are added; `git diff --check` passes.
- Validation: Run one local Python verification that checks the 30 numeric source IDs `0000`–`0029` per variant; the explicit zero-offset four-to-three-digit source-to-canonical mapping; unique and identical 30-ID sets across variants; no ambiguous or extra PNGs; exact dimensions; original-path manifest provenance; SHA-256 source/copy equality; then `git diff --check`. No Godot or Asset V2 ingest is required because this packet intentionally creates no production asset.
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

, parse its decimal index `n`. Require `0 <= n <= 29`, and copy its **unchanged bytes** to `pattern_{n:03d}.png` in the corresponding canonical variant directory. Examples:

| Original Downloads basename | Canonical library basename | Manifest pattern ID |
| --- | --- | --- |
| `pattern_0000.png` | `pattern_000.png` | `pattern_000` |
| `pattern_0006.png` | `pattern_006.png` | `pattern_006` |
| `pattern_0017.png` | `pattern_017.png` | `pattern_017` |
| `pattern_0029.png` | `pattern_029.png` | `pattern_029` |

This is **index-preserving**, never `n+1` or `n-1`. Gallery positions remain 1-based, so gallery #7 is still `pattern_006`. Discover the four source roots by dimension/thickness/content and bundled license as before; never assume Downloads folder names.

A source root may use the original three-digit scheme instead only if it is uniformly `pattern_000.png`–`pattern_029.png`; preserve the same canonical ID and bytes. In **each** of the four roots require exactly one coherent input naming scheme and exactly one file for each index 0–29. Reject mixed-width numbering within a root, a duplicate canonical ID, missing/extra/out-of-range patterns, unexpected PNG basenames, mismatched dimensions, unreadable PNGs, or ambiguous variant assignment. Stop with an exact inventory instead of guessing if those checks fail.

Keep Downloads originals untouched. In `manifest.json`, record **both** each PNG's exact original relative source path/basename (`pattern_0000.png`, etc.) and its canonical `pattern_000` ID and three-digit destination relative path, alongside the existing variant/dimensions/checksum/license fields. Hash the source and copied file and prove equality. This is a packet-only input-name refresh: **resume the existing `kenney-pattern-lines-source-library` claim/worktree**, do not create a second claim, retag another variant, change its locks, generate new art, or route these reference files into Asset V2 production ingest.

## Manifest Contract

`manifest.json` is reference metadata, not an Asset V2 family contract. Record at minimum:

- pack title and detected local source root/archive;
- license ID/text source;
- canonical variant ID;
- original relative source path and unchanged source basename (four-digit for the confirmed delivery);
- canonical three-digit library destination relative path;
- canonical pattern ID (three-digit, numerically equal to the parsed source index);
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
3. the manifest owns provenance/hash/variant/usage tags, including the original four-digit filename → canonical three-digit pattern-ID mapping;
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
