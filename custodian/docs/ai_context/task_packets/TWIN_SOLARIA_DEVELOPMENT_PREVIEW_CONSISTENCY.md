# TWIN SOLARIA DEVELOPMENT PREVIEW CONSISTENCY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `twin-solaria-development-preview-consistency-r1`
- Kind: `implementation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `twin-solaria-runtime`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, workflow`
- Paired review workstream: `review-twin-solaria-development-preview-consistency-r1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `3880e3aead8244f6e9cc7d6fc65d5be4b92bd6f2`
- Authoring chat: `not-recorded`
- Goal: Resolve the long-standing development-only Twin Solaria preview mismatch where the preview controller/smoke expects 3500×3000 while the loaded development texture is 4000×3000, without changing the authoritative 2048×1536 production runtime.
- Current measured state: `twin_solaria_backdrop_test.tscn` consumes `custodian/content/levels/hub/twin_solaria/development/twin_solaria_rebuilt_upscaled.png`; live runtime/docs record that the texture measures 4000×3000 while legacy preview expectation remains 3500×3000. Production Twin Solaria does not use this texture for coordinate authority. The old `origin/agent/twin-solaria-development-preview-consistency` branch is fully contained by current main with zero unique commits but still exists remotely, so the original workstream identity is seen as claimed. This `-r1` identity is the canonical executable packet. The packet is an implementation/consistency slice, not a review-cycle correction, so its legacy `Kind: correction` classification is retired.
- Completion boundary: Done when provenance establishes one development-preview dimension, preview scene/controller/smoke/docs agree with it, production Twin Solaria art/coordinates/hashes remain unchanged, and the old 3500-vs-4000 drift note is retired.
- Evidence: development preview scene/controller/smoke, current texture metadata, Git/LFS provenance, production Twin runtime/canon validation, stale branch classification above.
- Task-specific authority: `design/05_levels/TWIN_SOLARIA.md` current runtime/persistent art sections; dev preview scene/controller/smoke; Git/LFS history and source provenance.
- Work surface: development-only Twin backdrop preview scene/controller/smoke, provenance notes, and only docs made stale by the chosen proven dimension. Production Twin runtime files are read-only acceptance evidence.
- Change: Determine whether 4000×3000 is an intentional later development composite or accidental drift, then make preview controller, smoke, and docs agree with proven provenance.
- Preserve: production 2048×1536 runtime, eight V2 plates, fidelity underlay, canonical reference art, all gameplay coordinates and collision.
- Non-goals: No rescaling production art; no replacing production plates; no route gameplay; no aesthetic repaint; no blind resize solely to satisfy a smoke.
- Acceptance: one documented dev-preview dimension is proven from repository provenance; preview scene/controller/smoke agree; no production file/hash/coordinate changes; stale 3500-vs-4000 follow-up is removed from active docs.
- Validation: Run the development preview smoke, production Twin runtime smoke, canon-doc smoke, changed-file validation, and `git diff --check`. Assert production Twin files/hashes/coordinates are unchanged.
- Task overrides: `none`
- Deferred: none beyond unresolved provenance that must be recorded rather than guessed.

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
