# Alpine Cliff Bunker — Production and Validation Plan V1

**Status:** LOCKED PROCESS (2026-11-03), not an executable packet, dispatcher claim, accepted image source, or runtime release. **Source baseline:** `main@50fd76fdb6e85d6bf11d01bce7c5e9ee26f5df62`.

**Design:** [Enterable V1](ALPINE_CLIFF_BUNKER_ENTERABLE_V1.md). **State inventory:** [JSON manifest](ALPINE_CLIFF_BUNKER_ASSET_MANIFEST_V1.json). Governed by `custodian/AGENTS.md`, the active [art review protocol](../04_architecture/AI_ART_GENERATION_REVIEW_PROTOCOL_V1.md), Asset Pipeline V2, and live geometry/transition owners.

## Philosophy

Do not chop the two flattened, oblique 1254px images into a large arbitrary tileset. Keep them as **concept references** and author a modest set of clean aligned layers. Both referenced PNGs are true RGBA with background alpha zero, but most of their partially filled pixels are not fully opaque. Transparency, matte fringe, pixel density, distortion and baked lighting must be inspected and corrected per derived state; background removal does not establish runtime-readiness. **First build a real-Operator, no-art traversal proof.** Then produce states against that geometry.

## Gates

### G0 — Scope and single-owner reconciliation

Read latest main, existing task claims, Alpine AP2 cliff/contact presentation, the already-implemented optional Abandoned Alpine Station event, and the separate `connected_bunker` compound layer/vertical entry work. Determine the exact site placement and whether the existing reviewed route/world ingress can be reused. Default is **separate optional cliff insert**, not a rewrite of those systems. Assign a single owner for surface claims, interior floor/collision, door crossing, camera and persistence; record accepted review status rather than presuming it.

**Gate:** site decision and named owners, no conflicting locks or broken routes.

### G1 — No-art blockout and traversal proof

Use canonical 32px-semantic floor/wall geometry, actual Operator clearance, approved exterior reservation, paired door anchors and a neutral antechamber. Create reversible surface→interior→originating surface travel using existing crossing authority, correct collision, navigation, camera, save/revisit, no trigger bounce, exactly one Operator and no generated-world obstruction. Test valid/invalid seed placement; skip invalid site. The deeper door remains closed. Standalone real-Operator proof before production switch.

**Gate:** exact floor masks/room transforms, passage width, camera registration and deterministic running-game evidence.

### G2 — Art registration and geometry lock

Human/production reviewer inspects **actual bytes** of both hash-pinned reference candidates. They are NOT yet production source approved or uploaded to the repository. Freeze the exact source canvas for each manifest state, shared 1:1 world↔pixel origin, camera projection, layer draw order, alpha/opacity, registration anchors and adjacent pixels. Floor-only underlays come first, then separate shell, doors, foreground occlusion, scenic depth and isolated dressing. Every foreground solid must match accepted blockout; no visual collider implied by alpha.

**Gate:** reviewed per-state spatial/alpha contract. The 1254×1254 reference size is never assumed to be runtime canvas size.

### G3 — Individually authored and approved assets

Each state gets an independent PNG (not a cut from a collage). Generate architecture/connector states individually using the actual G2 registration and approved neighboring image references. Inspect dimensions, color/alpha, matte edges, placement, perspective, occlusion, opacity and collision-free composition. Record exact source SHA-256 and an explicit per-state human decision. Reject/regenerate under the same state ID if geometry or visual consistency fails.

**Gate:** SHA-pinned approved sources and verified handoff; proposed source_work/inbox paths are not evidence of delivery.

### G4 — Asset V2 and V1a integration

Only after G3 create/validate owning `custodian.asset_family.v2` metadata and required registry demand. Preserve full-resolution masters in planned `asset_drop/source_work/campaign/<family>/`, independently normalized files in `asset_drop/inbox/<family>/`, then run asset `plan`, `status`, `doctor` and required-demand checks before reviewed `ingest`. Bind actual consumers explicitly. Test open/closed doorway, return, crossing persistence, camera restoration, real z-occlusion and art registration with a real Operator. The far door remains physically blocked.

**Gate:** playable, art-approved **exterior↔antechamber↔same exterior** with no counterfeit route or invisible collision.

### G5 — V1b deeper installation

Connect a service bay and control room through physically passable bulkhead and continuous appropriate interior layer, not fake room teleportation. Optionally add the equipment branch; ensure reversible exploration and no softlocks. Reuse modular architecture and prove one **local** engineering purpose, cost and physical evidence instead of generic anomalous logs or an extra Twin Solaria.

**Gate:** rooms can actually be reached, used and exited. No implied global campaign outcomes.

### G6 — Independent and human acceptance

Run focused registered smoke and changed-file validation: multi-seed/invalid-skip, real Operator nav/collision, closed/open gates, paired entry/return and camera bounds, reload/revisit, scene registration and draw-order/alpha tests, no regression of station, compound or procedural cliff. Inspect a minimum targeted in-engine camera view for entrance, foreground overlap and return. Independent review and human presentation decision are distinct; green checks do not establish a review PASS or host teardown.

**Gate:** explicit accepted receipts; gameplay landing and artifacts cannot self-approve.

## Status truth

| Gate | Today |
|---|---|
| G0 ownership and eligibility | Pending |
| G1 no-art V1a loop | Pending |
| G2 source geometry registration | Pending |
| G3 individual human source approvals | Pending |
| G4 Asset V2 / V1a gameplay | Pending |
| G5 actual service/control rooms | Pending |
| G6 independent and human acceptance | Pending |

**Next action:** resolve G0, then build G1. Do not dispatch, claim, review, re-register, ingest or modify runtime based on this planning-only lock.
