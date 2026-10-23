# Codex Art Import Pipeline V1

**Status:** proposed, implementation authorized by task-packet series (not yet runtime-complete)  
**Review baseline:** `main@d099e541941c5f7525f7c9af38f6e36536f9d574` (2026-10-16)  
**Owners:** shared pixelart geometry under `custodian/tools/art/`; pre-canonical generic import orchestration under `custodian/tools/assets/sprite_import/`; Operator source/Workbench remains specialized.  
**Authoring chat:** not-recorded (add exact chat URL when provided).

## Audit / current truth

- `custodian/tools/operator/art_agent/mcp_server.py` already exposes typed Art Agent and Source Session tools for source analysis, one shared animation-scale normalization, bounded integer registration, conversion, profile reports, review and specialized source handoff. Its handlers must remain thin; canonical Operator publication stays with Workbench.
- `custodian/tools/art/custodian_pixelart_converter.py` implements grid splitting, shared frame transforms, nearest-neighbor candidates, integer translation, alpha checks and sheet reports. Reuse this core, do not build a competing resizer.
- Accepted profile registry `custodian/content/data/operator/authoring/operator_art_profile.json` holds legacy 96x96 anchors (48,84), ground 85, and active accepted `operator_2_5d_128` root (64,106), shadow/ground y=107. The 128 profile has no accepted body-scale-segment mapping, so do not infer profile-based rescale. `custodian/tools/operator/README.md` still calls the 128 profile provisional and needs targeted reconciliation.
- `design/04_architecture/ASSET_WORKBENCH_ROADMAP.md` has complete read-only Slices 1-2, planned Slice 3 pipeline actions, and planned Slice 6 creation/source intake. This program supplies shared tools for Slice 6; it does not supersede the roadmap, duplicate its UI, or mark it done.
- `design/04_architecture/ASSET_PIPELINE_V2.md` and `custodian/tools/assets/` own generic family contracts, naming, plan, status, transactions and runtime ingest. The Artist/Art Agent is not a runtime publisher.
- Active review `review-operator-art-registration-profile-review-corrections-1-r1` is queued, covering the earlier Operator normalization-plan approval digest fixes. The first slice depends on its reviewed completion before changing shared source normalization authority.
- The code-review graph was not available in this session; audit used pinned live-main file and queue inspection, not a locally executed Aseprite/Godot smoke. No existing production art is being normalized in packet authoring.

## 2026-10-17 precision audit amendment

The reusable pipeline remains proposed, not implemented. The converter `pixelart` alias currently forces crisp (`--choose 1`), and the Python converter always emits binary-alpha candidates. This policy remains authoritative for accepted Operator pixel-art profiles, **not** for every detailed 2.5D building. See [Pixelart Deterministic Normalization Hardening V1](PIXELART_DETERMINISTIC_NORMALIZATION_HARDENING_V1.md) for source-overwrite/invalid-size/empty-output safeguards, explicit static architectural alpha/resize policies, component/assembly contracts, and machine-only QA evidence. These are additions to existing stage 1 and stage 3 implementation packets, not a sixth parallel resizer or an assertion they have landed.

## Product contract

Given a PNG source master and explicit family/state/direction or Operator profile, produce a **reviewed, deterministic, exact-size, pixel-art-clean** strip plus source→plan→review→inbox evidence, with a clear separation between preview/staging and runtime publication.

```text
raw PNG, approved semantic family/profile
  -> confined pre-canonical source_work
  -> geometry inspection (exact source grid)
  -> immutable shared-scale/anchor/registration plan + source/profile digests
  -> preview candidates via existing crisp converter
  -> structural QA (source, plan and output hash-bound)
  -> reviewed plan acceptance
  -> generic Asset V2 normalized inbox OR specialized Operator source-handoff
  -> existing Asset V2 plan/ingest/status/doctor OR Operator ingest/Workbench publish
```

## Rules

1. **One transform per animation:** one uniform scale, one source/union crop, one target cell size, one global placement. Never independently trim, center or resize frames. Preserve deliberate jump/anticipation/recoil/displacement. Per-frame dx/dy only by explicit reviewed integer registration; overflow fails closed.
2. **Anchor semantics:** fixed actor root/ground and accepted Operator profile beat alpha bbox; props may use base-center/declared pivot; FX use declared impact/origin; tile atlases keep exact grid; free alpha-centering permitted only for opted-in static icon-type states. Do not invent artwork geometry from a bounding box.
3. **Data ownership:** `custodian.asset_family.v2` owns non-Operator target WxH/frame count, semantic identity, direction grammar and canonical routing. Active Operator art profile/semantic schema owns Operator anchors, pixel resizing and specialized handoff.
4. **Non-destructive by default:** raw source masters immutable and SHA256 pinned; derived evidence under ignored `.ai`/reports; no writes to generated runtime or canonical source from MCP; exact hash-bound plan+QA required before transactional inbox stage. UI, CLI and MCP share service, never parse each other's prose output.
5. **True production alpha:** actors/props/effects use real transparent RGBA, not a painted checkerboard, alpha matte, vignette or floor canvas. Tiles may use the family's legitimate opaque tile policy. No guide pixels, labels, guides, bleed or cross-cell content.
6. **Human aesthetics remain human:** objective geometry/alpha problems can be automatically rejected; qualitative pixel-art quality, composition and style approval cannot be manufactured from a PASS report.
7. **Operator resizing:** only `source tools/custodian_aliases.sh; pixelart <source> --choose 1 ...` may produce final rescaled Operator art. The shared Python core can plan/inspect both domains, but may not bypass the mandatory Operator source path.

## Exact synthetic regression geometries

| Fixture | Source contract | Target | Expected output |
| --- | --- | --- | --- |
| actor_8f | horizontal 8x1, each 512x512, true alpha | actor 128x128, 8f | 1024x128 horizontal strip |
| fx_grid_6f | grid 3x2, each 256x256, 6f | FX 128x128, 6f | 768x128 horizontal strip |
| prop_static | 1x1 128x160 source, 1f | base-anchored 128x160, 1f | 128x160 |
| vehicle_12f | horizontal 12x1 of 156x156 | vehicle 156x156, 12f | 1872x156 |
| actor_jump | 8f root sample with deliberate 6px vertical airborne shift | shared 128x128 | preserve exact authored 6px shift |
| bad_bleed/matte/clipped | malformed cells or contaminated alpha | any | fail closed, no inbox artifact |

Proposed fixture source under `custodian/tools/validation/fixtures/sprite_import/` must be synthetic/generated by tests, not new production art. No new `custodian.asset_family.v2` schema fields are presumed; if anchor metadata needs new canonical fields, require explicit schema/versioned compatibility design first.

## Five implementation / fresh-review pairs

| Slice | Workstream | Scope | Dependency |
| --- | --- | --- | --- |
| 1/5 | `codex-art-import-shared-transform` | Provide one deterministic, reusable source-sheet geometry and conversion-plan API for both generic Asset V2 and specialized Operator intake without introducing a second resize engine. | `review-operator-art-registration-profile-review-corrections-1-r1` |
| 2/5 | `codex-art-import-registration` | Normalize visual scale, centering, foot/root baselines and shared registration without erasing intended frame motion or anchoring equipment to the body incorrectly. | `review-codex-art-import-shared-transform` |
| 3/5 | `codex-art-import-quality-gates` | Make production-readiness observable and fail-closed with structural/pixel evidence, preview artifacts and stable quality reports before any handoff. | `review-codex-art-import-registration` |
| 4/5 | `codex-art-import-mcp` | Give Codex a discoverable, low-token, safe MCP interface to inspect, normalize, register, preview and QA source sheets using the single shared import service. | `review-codex-art-import-quality-gates` |
| 5/5 | `codex-art-import-asset-v2-handoff` | Finish the reusable source_work→normalized inbox→Asset V2 plan/status/doctor interface with verified artifacts and provenance while preserving the Operator-specific publication route. | `review-codex-art-import-mcp` |

All new packet pairs originate on main as `draft/manual` with the explicit authoring-handoff opt-in. The repository's push-triggered preflight may promote them to `ready/auto`; it does NOT execute Codex or override dispatcher dependencies/locks. Each implementation must land, archive, and pass independent paired review before the next slice is claimable.

## Documentation drift and closeout

Do not claim these tools implemented merely because this specification is committed. At each slice landing, refresh only genuinely affected `CURRENT_STATE.md`, `FILE_INDEX.md`, Operator README and Asset Workbench roadmap. Keep `required_assets.registry.json` canonical and never hand-edit generated `REQUIRED_ASSETS.md`. Respect root/custodian `AGENTS.md` tests, workstream isolation, landing and Render `[skip render]` policy.
