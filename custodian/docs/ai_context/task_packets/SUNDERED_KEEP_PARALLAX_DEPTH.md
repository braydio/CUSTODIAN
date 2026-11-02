# SUNDERED KEEP PARALLAX DEPTH

- Status: `blocked`
- Authority: `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md`
- Goal: Share one presentation-only painterly parallax rig across Vista Approach and Return Causeway without changing either level's traversal or simulation contracts.
- Files: `game/world/sundered_keep/presentation/sundered_keep_parallax_rig.gd`, both production level builders, focused smokes, CI, active design and AI-context indexes.
- Constraints: Compose split mist pairs at runtime with overlap; use linear filtering and bounded `scroll_offset` drift; preserve Return Causeway compatibility node names; keep `ParallaxRoot` free of collision and navigation; do not modify `ReturnCausewayApproach.tscn`.
- Acceptance: Both levels build the required depth groups and layer scales, painterly sprites load with linear filtering, the Vista reveal owns reveal-layer alpha, Return Causeway compatibility paths remain valid, and focused validation proves the rig is presentation-only.
- Completed: Added the shared Vista/Return rig, controller-owned Vista alpha bindings, Return Causeway replacement builder with compatibility names, focused and cross-level smokes, route-suite/CI coverage, active design/index updates, and asset-layout drift remediation. Import, Vista approach, Vista polish, Return Causeway parallax, and content-audit checks complete; existing behavior smokes pass while reporting the missing plates.
- Deferred: Two required intake files, `ocean_mist_strip_right.png` and `near_edge_mist_left.png`, are not currently present in the runtime or asset-drop tree. The runtime-ready dry-run reports zero planned files, so the cross-level texture smoke and route suite cannot pass until those authored files are supplied and ingested.
