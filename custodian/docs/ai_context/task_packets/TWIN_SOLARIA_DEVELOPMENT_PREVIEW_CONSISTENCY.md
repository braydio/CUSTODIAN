# TWIN SOLARIA DEVELOPMENT PREVIEW CONSISTENCY

- Workstream: `twin-solaria-development-preview-consistency`
- Kind: `correction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `twin-solaria-runtime`
- Review: `none`
- Goal: Resolve the long-standing development-only Twin Solaria preview mismatch where the preview controller/smoke expects 3500×3000 while the loaded development texture is 4000×3000, without changing the authoritative 2048×1536 production runtime.
- Current measured state: `twin_solaria_backdrop_test.tscn` consumes `custodian/content/levels/hub/twin_solaria/development/twin_solaria_rebuilt_upscaled.png`; live runtime/docs record that the texture measures 4000×3000 while legacy preview expectation remains 3500×3000. Production Twin Solaria does not use this texture for coordinate authority.
- Task-specific authority: `design/05_levels/TWIN_SOLARIA.md` current runtime/persistent art sections; dev preview scene/controller/smoke; Git/LFS history and source provenance.
- Change: Determine whether 4000×3000 is an intentional later development composite or accidental drift, then make preview controller, smoke, and docs agree with proven provenance.
- Preserve: production 2048×1536 runtime, eight V2 plates, fidelity underlay, canonical reference art, all gameplay coordinates and collision.
- Non-goals: No rescaling production art; no replacing production plates; no route gameplay; no aesthetic repaint; no blind resize solely to satisfy a smoke.
- Acceptance: one documented dev-preview dimension is proven from repository provenance; preview scene/controller/smoke agree; no production file/hash/coordinate changes; stale 3500-vs-4000 follow-up is removed from active docs.

## Investigation

Inspect:

- Git/LFS history for the development texture;
- old 3500×3000 expectation introduction;
- current actual texture metadata;
- persistent design reference provenance;
- any source/master notes describing an upscale/export change.

Prefer evidence over visual guess.

If 4000×3000 is legitimate, update dev preview expected size/smoke/docs.

If 3500×3000 is proven canonical for this development preview and 4000×3000 is accidental, restore the correct historical LFS object. Do not resample 4000→3500.

If provenance remains ambiguous, do not mutate the texture; update the preview expectation to actual dimensions only if doing so is clearly harmless and record the uncertainty.

## Validation

Run the preview smoke, production Twin runtime smoke, canon-doc smoke, and `git diff --check`.

Assert production Twin files/hashes/coordinates are unchanged.

## Documentation Drift

Remove/update the explicit 3500×3000 vs 4000×3000 follow-up from CURRENT_STATE/TWIN_SOLARIA only after resolution.

## Completion

Archive complete, write
`TWIN_SOLARIA_DEVELOPMENT_PREVIEW_CONSISTENCY_CLAUDE_SUMMARY.md`, and land normally.
