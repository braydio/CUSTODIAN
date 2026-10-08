# OPERATOR 2.5D WORKBENCH POLISH AUTOMATION

> PRE-AUTHORED / REFRESH REQUIRED BEFORE IMPLEMENTATION  
> Refresh after WB25-2 + paired review land.

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-polish-automation
- Status: draft
- Dispatch: manual
- Priority: P1
- Depends on: review-operator-2-5d-workbench-ingress
- Locks: operator-art-agent, operator-aseprite-tooling, operator-workbench-ui
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, asset-pipeline, workflow, visual
- Paired review workstream: review-operator-2-5d-workbench-polish-automation
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: substantial engineering default
- Reviewed main: e56a75cfb76cdb5a3a430b21be267b1b4e20ed6e
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: conditional
- Goal: Turn the useful one-off Aseprite cleanup/registration tricks proven while authoring idle_relaxed_01 into safe Workbench/Art-Agent operations so a 2.5D strip can be aligned, inspected and polished without hand-running bespoke scripts or destroying intentional motion.
- Completion boundary: Add objective temporal/pixel diagnostics plus bounded preview/apply operations for planted-foot registration, detached islands and outline/highlight coherence, using existing ArtAgent/Aseprite mutation authority. Do not add autonomous anatomy redraw, image generation, publication, review sequencing or runtime cutover.
- Current measured state: ArtAgentService already supports hashed/journaled bounded Aseprite mutations, landmarks/masks/drafts, render/contact/onion/diff products and undo; current canonical QA measures frame/palette/silhouette facts. The successful first 8-direction idle family required manual Lua helpers for frame centering/registration, outline miscolor cleanup and visual detection of shoulder highlight shimmer.
- Evidence: design/02_features/animation/OPERATOR_ART_AGENT_SYSTEM.md; custodian/tools/operator/art_agent/service.py; custodian/tools/operator/art_agent/metrics.py; custodian/tools/operator/art_agent/qa.py; custodian/tools/aseprite/operator_art_agent.lua; custodian/tools/aseprite/operator_animation_workbench.lua; accepted Workbench mutation/undo architecture.
- Task-specific authority: canonical 2.5D profile/reference for guides and registration; ArtAgentService for bounded pixel mutations; Aseprite bridge for editor-local transactions; Workbench target/session for current identity/frame contract.
- Work surface: recommended new pure analysis/orchestration owner custodian/tools/operator/operator_2_5d_polish.py; custodian/tools/operator/art_agent/metrics.py and qa.py for reusable metrics only; custodian/tools/operator/art_agent/service.py for existing mutation delegation; Aseprite bridge only for missing primitive operations; UI service plus recommended custodian/tools/operator/ui/widgets/polish_panel.py; focused Art Agent/UI smokes.
- Change:
  1. Add a Workbench POLISH surface for operator_2_5d_128 targets. It consumes the open Workbench/session; it does not scan arbitrary PNGs.
  2. Add non-mutating diagnostics:
     - alpha/dimensions/frame-count contract;
     - connected opaque component count and detached-island bounds;
     - per-frame alpha bbox;
     - apparent width/height;
     - center/root/support residuals;
     - F01 canonical-reference diff;
     - frame-to-frame silhouette delta;
     - frame-to-frame outline/highlight delta;
     - F15→F01 loop seam delta.
  3. Add planted-foot registration proposal for actions explicitly marked stationary/planted. Frame 1 is authority by default. Compare lower-body/foot evidence and propose integer dx/dy only; never infer root from lowest alpha pixel alone.
  4. Add explicit Center X tool as a manual preview operation only. It must never auto-run and must warn that alpha-centroid centering is inappropriate for root-motion actions.
  5. Add detached-island repair proposal. Eligible automatic proposal is intentionally tiny: component is below a bounded pixel/area threshold, not intersecting approved semantic landmarks/masks, and separated from the main character component. Show exact pixels before apply.
  6. Add temporal outline/highlight diagnostic for external silhouette and configurable semantic regions. It reports unstable bright/dark clusters; it does not globally recolor or blur.
  7. Add Open/Refresh in Aseprite and canonical guide/ghost creation through existing profile authority. Guide/reference layers remain reserved/nonpublishing.
  8. Any apply operation is one Art Agent/Aseprite transaction with exact before/after pixel hashes, changed bounds, undo ownership and journal receipt.
  9. F01 reference replacement is never automatic. If F01 is not the accepted direction reference, report HARD_FAIL and require deliberate replacement/re-authoring.
  10. Do not move Y merely to equalize head tops or lowest opaque pixels. Semantic root/support evidence owns vertical registration.
- Preserve: existing Art Agent security/undo/stale checks; Aseprite live-bridge ownership; Workbench publish authority; canonical pixels untouched until explicit user apply + later publication; intentional animation motion.
- Non-goals: no pose synthesis; no anatomy warping; no per-frame scaling; no free rotation; no network generation; no automatic palette redesign; no publication; no runtime mutation.
- Acceptance: a synthetic 15f/128 planted idle with ±2px accidental registration jitter receives deterministic integer proposals while intentional breathing remains; a 3px detached island is identified and can be removed in one undoable transaction; a deliberately moving walk/root-motion fixture is refused by the planted registrar; F01 drift is caught; a shoulder-highlight flicker fixture produces a localized temporal warning without mutating art; all guide layers remain excluded from publish.
- Validation: extend existing Art Agent metrics/QA and Aseprite bridge smokes where possible; add only one focused polish smoke if needed; include negative controls for root-motion refusal, landmark-intersecting island refusal, stale document, guide leakage and undo; then changed unit validation + git diff --check. Visual handoff only if objective evidence leaves a material subjective question.
- Task overrides: none
- Deferred: sequence/family acceptance; Godot sandbox; production queue; runtime promotion.

## Recommended code shape

Keep analysis pure and mutation separate:

~~~python
@dataclass(frozen=True)
class PolishFinding:
    code: str
    severity: str
    frame: int
    bounds: tuple[int,int,int,int] | None
    metric: float | None
    message: str
    proposed_operation: dict | None = None

def analyze_idle(frames, profile, reference) -> list[PolishFinding]:
    ...
~~~

Registration proposal should return data, not move cels:

~~~json
{
  "kind": "planted_registration",
  "authority_frame": 1,
  "anchor": [64,106],
  "offsets": [{"frame":2,"dx":0,"dy":-1}],
  "mutates": false
}
~~~

The apply path then translates that proposal into existing journaled ArtAgent operations.

## Refresh Planning Authority

- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh instruction: Bring WB25-2 implementation/review evidence and the live Source Session→Workbench handoff shape back to this chat. Re-derive exact session metadata, accepted profile/root API, ArtAgent operation names, UI surface and validation ownership before ready.

## Handoff

- Next workstream: review-operator-2-5d-workbench-polish-automation
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Summary backlink: include exact Authoring chat URL
- Refresh reason: none after refresh/implementation
- Next action: paired review
- Blockers or open questions: packet must be refreshed before claim
