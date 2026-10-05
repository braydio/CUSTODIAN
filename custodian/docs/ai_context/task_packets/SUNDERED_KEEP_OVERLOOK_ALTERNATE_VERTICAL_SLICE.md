# SUNDERED KEEP OVERLOOK ALTERNATE VERTICAL SLICE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `sundered-keep-overlook-alternate-vertical-slice`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `review-isometric-2-5d-presentation-foundation`
- Locks: `sundered-keep-presentation, world-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual`
- Paired review workstream: `review-sundered-keep-overlook-alternate-vertical-slice`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `223d15ab6695dc79e714398e5645d24b4c89e4c7`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Summary backlink: Every durable implementation/review/correction/closeout summary for this packet must include `Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7` exactly.
- Goal: Build a standalone playable alternate Sundered Keep overlook in which the real Operator occupies a compact foreground shelf/perch above a vast apparent depth field and the Sundered Keep reads as a large distant physical destination, using reviewed CUSTODIAN 2.5D presentation rules while gameplay remains entirely 2D.
- Completion boundary: Done when a standalone dev/playtest level launches with the real Operator, real PlayerController and production Camera2D; its bounded shelf traversal is ordinary 2D gameplay; reviewed 2.5D foundation primitives stage visible shelf thickness, depth bands, distant Keep mass, atmospheric separation and foreground framing; the slice can be walked normally; existing Sundered donor assets are reused without modifying the production approach; objective validation passes; and renderer-backed evidence is published for explicit user/ChatGPT direction approval.
- Current measured state: CUSTODIAN's active 2.5D contract preserves 2D XY simulation/collision/navigation/combat and Camera2D while permitting presentation-only visual elevation, semantic depth bands, base-root sorting, contact grounding and roof/foreground occlusion. The live Sundered approach already owns underlay/vista/playable/roof/foreground bands, far/mid/near fortress presentation, ocean/mist and parallax donors, but its production composition is a route-first authority and must remain untouched in this proof. The user wants a more dramatic fixed-elevated-oblique composition: small shelf in the lower foreground, visible vertical drop/negative space, Sundered Keep dominating the upper/mid distance, convincingly fake-volumetric in the spirit of the project's Lords-of-Pain dimensional reference. No Blender requirement.
- Evidence: `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`; reviewed foundation once landed; `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md`; `custodian/game/world/approaches/sundered_keep/sundered_keep_approach.gd`; current Sundered parallax/fortress donors; K3D-1P real-Operator playtest precedent; Lords-of-Pain directional/volumetric presentation precedent; target composition described in the authoring chat.
- Task-specific authority: This packet owns one **standalone alternate test scene only**. Existing production Sundered route/approach/frontage authority is read-only donor/reference. The reviewed 2.5D foundation owns ground-vs-visual elevation semantics. Real Operator/controller/Camera2D retain gameplay authority.
- Work surface: Prefer `custodian/game/world/levels/authored/dev/sundered_keep_overlook_alt/` for the standalone level/playtest wrapper and `custodian/game/world/sundered_keep/presentation/sundered_keep_overlook_alt_rig.gd` for composition-only assembly. Reuse existing Sundered textures/resources through references; add focused validation under `custodian/tools/validation/levels/` and a Moment Forge scenario such as `vista/sundered_keep_overlook_alt_review`.
- Change: Create `sundered_keep_overlook_alt_level.tscn/.gd` plus a normal standalone playtest wrapper following the landed K3D-1P / authored-level playtest pattern. Use the real Operator, PlayerController and production Camera2D stack; no imitation controller or capture-only puppet.
- Change: Author a compact, collision-complete shelf/perch as the only gameplay surface. Use ordinary 2D floor/collision for traversal. Presentation may extend a cliff/shelf face downward from the ground anchor but that visible thickness owns no hidden walkable Z.
- Change: Stage depth in this order: FAR sky/storm/remote silhouette; KEEP far/mid/near architecture; DEPTH void/ocean/lower-ruin/mist field; SHELF ground + presentation-only face/thickness; Operator/actors; foreground framing/roof-occlusion elements. Exact z-values should consume the reviewed semantic-band helper instead of inventing a second hierarchy.
- Change: Recompose existing Sundered donor art before creating anything new. Existing fortress composer, ocean/storm, parallax mist, cliff/spire, route/foreground pieces may be repositioned/scaled/cropped/soft-feathered **inside this standalone scene**. Do not modify their shared source bytes or production transforms.
- Change: Tune the default camera for a fixed elevated-oblique composition. At the establishing position the Operator should read in the lower portion of frame, a substantial nonplayable depth interval should separate shelf from fortress, and the Keep should occupy a memorable upper/mid silhouette. Camera may follow within a small bounded shelf envelope but must not orbit or simulate free 3D pitch/yaw.
- Change: Use reviewed ground-root sorting, visual elevation, contact shadow and `RoofOccluder2D`/foreground readability behavior where relevant. The Operator's authoritative XY must not move when visual elevation/framing toggles.
- Change: Add a cheap A/B review toggle if clean: `flat/reference` vs `realized_2_5d`, or at minimum `depth_presentation_enabled`. The toggle must change presentation only.
- Change: Include a small stand-in structural/foreground element the Operator can pass in front of and behind so the slice proves depth sorting/occlusion in motion rather than only presenting a postcard.
- Preserve: Production `SunderedKeepApproach`, route graph, procgen frontage, Front Gate, campaign transitions, production asset bytes, Camera2D doctrine, 2D collision/navigation/combat, and current Sundered mapper authority.
- Non-goals: No production route replacement; no procgen insertion; no current-main spawn bug fix; no Camera3D/Node3D gameplay conversion; no Blender/Kenney Shape requirement; no new Asset V2 family in SKO-1; no generalized world-perspective engine; no Sundered campaign rewrite.
- Acceptance: (1) real Operator/controller/Camera2D scene is directly playable; (2) playable shelf is compact, bounded and collision-complete; (3) visible shelf thickness/depth is presentation-only; (4) obvious nonplayable depth separates shelf from Keep; (5) Keep reads as a distant physical mass rather than wallpaper; (6) scene feels materially volumetric under motion despite 2D gameplay; (7) front/behind sorting and foreground occlusion remain readable; (8) presentation toggle, if included, never changes gameplay XY/collision; (9) production Sundered route/assets are unmodified; (10) no runtime 3D gameplay node path appears; (11) human review can make a clear yes/no call on the direction.
- Validation: Focused scene smoke proving real Operator/controller/camera, gameplay floor/collision, no forbidden 3D gameplay nodes, reviewed 2.5D anchor/band use, production-scene non-mutation and A/B invariance. Run changed-file validation and `git diff --check`. After objective checks pass, run the real renderer with the smallest Moment Forge walkthrough that demonstrates shelf traversal, front/behind occlusion and camera composition, then publish via `publish_review_artifacts.py --important`.
- Visual review: Publish at most six keyframes plus one short MP4 only if motion/parallax cannot be judged from frames. Include: establishing overlook; shelf/cliff-depth read; Keep-destination read; deep negative-space read; Operator behind/in-front of one structure; optional flat-vs-realized comparison. Ask: (a) does the shelf feel tiny relative to the visible world; (b) does the Keep feel physically distant/large; (c) does the scene approach convincing fake volume rather than layered wallpaper; (d) does movement preserve tactical clarity; (e) is this the composition direction worth productionizing? Stop for explicit user/ChatGPT approval in the authoring chat.
- Task overrides: Existing donor assets may be recomposed in this isolated scene without creating Asset V2 copies. If donor art clearly prevents a convincing finish after composition is proven, record that as SKO-2 input instead of generating ad-hoc unregistered art here.
- Deferred: New bespoke overlook art; Blender/offline-3D authoring; production/procgen integration; broad Sundered route replacement.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Evidence: `<scene, focused validation, Moment Forge, Dropbox manifest, explicit decision>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill at closeout>`
- Friction severity: `<fill at closeout>`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `review-sundered-keep-overlook-alternate-vertical-slice`

## Handoff

- Next workstream: `review-sundered-keep-overlook-alternate-vertical-slice`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Next action: Run the paired fresh-context review after objective validation and explicit visual-direction approval.
- Blockers or open questions: none beyond reviewed foundation dependency.
