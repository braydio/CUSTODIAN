# AWAKENING INTERACTIBLE CLEAN ROOM PLATES V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-interactible-clean-room-plates-v1`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-awakening-creche-console-idle-fx-binding-v1`
- Locks: `awakening-interaction-presentation, awakening-interactible-asset-contracts`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, visual, asset-pipeline`
- Paired review workstream: `review-awakening-interactible-clean-room-plates-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `two production-sized backdrops are artistically reauthored; independent byte/registration and human visual review matter`
- Reviewed main: `58c8783248f486905646a9b4d2a75db04767bbbf`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `required`
- Goal: Author pixel-registered, machine-free Crèche and Undergate room underlays, keeping every actual console/Port as a future separate world-prop.
- Completion boundary: Produce two exact-size, source-work-only replacement plate candidates, their SHA-256/provenance records, unchanged-room-region comparisons, and a compact side-by-side/temporary prop-composited visual approval. Do not ingest, swap live scene textures or modify interactions in this packet.
- Current measured state: Crèche 960×704 underlay is baked with the console and currently owns its visible body; Undergate 1536×1216 underlay contains machinery under the read-only Port marker. Current `CrecheConsoleBody` node at (105,118) has no body sprite and retains baked-source metadata. Art originals are LFS-managed; the previous agent hydrated references in `/tmp/custodian-awakening-review`, which is inspection evidence only, not an implicitly claimable worktree.
- Evidence: `custodian/scenes/awakening_first_return.tscn`, `custodian/game/world/awakening/awakening_first_return.gd`, registered backdrop families, `design/04_architecture/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md`, current inspection handoff.
- Task-specific authority: `design/04_architecture/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md` defines user-approved separation; registered Asset V2 backdrop family schemas and existing room geometry, interactions, lighting, scene and prop families retain authority.
- Work surface: `custodian/asset_drop/source_work/awakening/awakening_creche_environment/underlay_source.png`, `custodian/asset_drop/source_work/awakening/awakening_undergate_environment/underlay_source.png`, explicit disposable previews/checksum manifest. Do not change runtime/scene/foreground in this source-only packet.
- Change: Recreate the two background images faithful to existing architectural registration, but without the old console/Port machine or their machine-specific shadows/screens. Respect 960×704 and 1536×1216 one-frame RGBA. Stage exact masters and identify derived inbox candidates (do not ingest yet). Include no-prop/with-prop preview and measurable outside-ROI geometry/color parity.
- Preserve: One existing Crèche gameplay owner, one damaged Port status owner, route/collisions, scene centers/transforms, original source plates for rollback, foreground alpha/occlusion, production lighting, existing 8f activation FX; no temporary empty-machine deployment.
- Non-goals: No new interaction mechanics, Godot binding changes, Asset V2 runtime replacement, broad Awakening room redesign, Gate/lift/reliquary changes, or self-approved art.
- Acceptance: The two source candidates retain plate size/registration and architectural coherence, remove all interactive machine pixels, pass pixel/alpha/region QA, and receive a documented explicit human visual decision with exact file SHA-256. Remain source-only at closeout.
- Validation: PNG dimensions/alpha/registration and native-size comparison; temporary composite using independent hero art; exact source hash/Asset V2 plan dry-run; visually check remaining room details/lighting and original foreground overlay; changed-file ownership where applicable; no runtime ingest.
- Task overrides: `none`
- Deferred: Crèche underlay+hero atomic production replacement and Port underlay+body atomic replacement are owned by their existing following packets.

## Human art decision
- Design/layout separation authorized in the planning chat; neither source image has been approved. Pause before promoting this packet to executable until exact source work, visual output, and required authoring validation are available. Do not mistake existing Dropbox `SOURCE_READY_NEEDS_TUNE` candidates for approval.
- Canonical visual review handoff: `/CUSTODIAN/visual_review/awakening-interactible-clean-room-plates-v1/`. Questions: Is each room architecturally identical enough to preserve traversal? Are all interactible machines absent from the plate? Does each independently composited prop fit its socket? Are foreground/shadows and scene lighting coherent?
- Source work: `custodian/asset_drop/source_work/awakening/awakening_creche_environment/underlay_source.png` and `custodian/asset_drop/source_work/awakening/awakening_undergate_environment/underlay_source.png`.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `Current baked-room underlays retained until separate reviewed atomic cutovers`
- Evidence: `<fill at closeout>`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `<fill>`
- Root cause / contributing factors: `<fill>`
- Prevention / pipeline improvement: `<fill>`
- Tooling / docs drift discovered: `<fill>`
- Follow-up: `review-awakening-interactible-clean-room-plates-v1`
- What worked: `<fill>`

## Next Handoff
- Next workstream: `review-awakening-interactible-clean-room-plates-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `human-approved source art required before publication`
- Next action: Human art review, then fresh independent source/registration review; existing consumers make atomic runtime cutovers after both proofs.
- Blockers or open questions: `source images have not been accepted; no runtime publication yet`
