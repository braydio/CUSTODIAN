# PROCGEN ALPINE UNDERLAY VARIETY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-alpine-underlay-variety-v1`
- Status: `blocked`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `procgen-alpine-environment-cohesion-v1`
- Locks: `procgen-presentation, asset-pipeline`
- Kind: `implementation`
- Review: `manual`
- Review stage: `post-land`
- Review modes: `asset-pipeline, runtime, visual`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `alternate-frequency and rare scenic-landmark presentation need objective determinism/rarity checks plus human approval of repetition and visual hierarchy`
- Reviewed main: `14a572dd90c243c395f4468423485fa7a895e576`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Goal: Preserve the AP1 six-state Alpine underlay as the stable default while adding the approved non-baseline plates as deterministic low-frequency variety and the stronger scenic landmark plates as genuinely rare seed-driven moments, including a rare Custodian citadel, without turning the Alpine Plateau into an architecture biome or giving presentation art gameplay/POI authority.
- Completion boundary: Done when the exact 24-plate variety handoff is verified; 18 ordinary alternate states extend the existing `procgen_underlay_alpine_plateau` family as optional states; six scenic landmark plates publish through a separate `procgen_underlay_alpine_landmark` family; one data-owned selection policy preserves the AP1 baseline for ordinary seeds, allows at most one ordinary alternate substitution on an alternate seed, allows exactly one scenic landmark on a rare landmark seed with quiet baseline companions, remains deterministic from the accepted map seed, exposes selection diagnostics, leaves gameplay/topology/collision/navigation unchanged, and fixed-seed runtime evidence proves the variety feels occasional while the landmark plates feel special.
- Current measured state: AP1's reviewed final six are `far_world_a` = generation-02 `alpine_ruins_among_fog_islands`, `far_world_b` = generation-03 `snowy_custodian_ruins_above_the_clouds`, `depth_fog_a` = generation-03 `misty_alpine_ruins_overlay`, `depth_fog_b` = generation-02 `translucent_alpine_ruins_cloudscape`, `near_cliff_mist_a` = generation-03 `floating_alpine_cliffs_in_mist`, and `near_cliff_mist_b` = generation-02 `misty_ruined_alpine_plateau_cutout`. The three-generation review bundle retains 24 additional plates judged permissible for future use: 18 ordinary alternates and six stronger hero/landmark compositions. The bundle at `/CUSTODIAN/implementation_inputs/procgen-alpine-plateau-underlay-assets/alpine_underlay_last3_generations_review_bundle.zip` is donor/provenance only and is not the implementation gate for this packet. This packet is intentionally post-AP4 so it cannot block AP1/AP2/AP3/AP4 progress or destabilize the baseline closeout.
- Evidence: `design/02_features/procgen/ALPINE_PLATEAU_PRESENTATION_ASSET_MANIFEST.md`; AP1 final-eight permutation review; `ALPINE_UNDERLAY_LAST3_COMBO_REVIEW_CLAUDE_SUMMARY.md` donor review summary; `custodian/game/world/procgen/presentation/{procgen_underlay_profile.gd,procgen_depth_backdrop.gd}`; existing Asset Pipeline V2 family `procgen_underlay_alpine_plateau`; three-generation bundle manifest.
- Task-specific authority: landed AP1 production underlay/profile; `ProcgenUnderlayProfile`; `ProcgenDepthBackdrop`; Asset Pipeline V2; this packet's exact alternate/landmark catalog and selection policy. The term "scenic landmark" in this packet is presentation-only and is not procgen gameplay-landmark authority.
- Work surface: existing `custodian/content/metadata/assets/families/procgen_underlay_alpine_plateau.asset.json`; new `custodian/content/metadata/assets/families/procgen_underlay_alpine_landmark.asset.json`; runtime domains `custodian/content/backgrounds/procgen/alpine_plateau/` and `custodian/content/backgrounds/procgen/alpine_plateau/landmarks/`; a focused optional underlay-variant policy resource referenced by the Alpine underlay profile; existing `procgen_depth_backdrop.gd` selection seam; focused deterministic selection validation and compact Moment Forge evidence.
- Change: Keep the AP1 six required baseline states and their existing A/B selection intact. Extend the existing Alpine family with the 18 optional ordinary alternate states listed below. Add the six scenic landmark states to the dedicated landmark family listed below. Add one optional data-owned variant policy to the Alpine underlay profile; profiles without that policy must preserve current exact behavior. The policy selects one of three presentation tiers from the accepted map seed and stable profile/policy identity: baseline, ordinary alternate, or scenic landmark. Selection occurs once per generated region/profile application and is stable across reload/streaming. Do not use frame-time randomness.
- Preserve: AP1 six-state identity; AP1 opacity/parallax/base-fill tuning unless a later reviewed production change supersedes it; exterior/internal CHASM rules; Region Frame selection; Archive Resolve independence; gameplay camera authority; collision/navigation/topology; accepted-seed determinism; viewport coverage; non-Alpine profile behavior; AP2/AP3/AP4 presentation ownership.
- Non-goals: No new terrain/topology, gameplay POI, special room, encounter, lore state, traversal, collision, navigation, camera mode, weather behavior, cliff art, surface plate, or Archive Resolve behavior. A scenic landmark plate must never imply that a corresponding gameplay-space citadel/fortress exists. No multiple landmark plates in one region. No unconstrained random selection from all 30 donor images. No replacement of the AP1 baseline family.

## Asset organization and exact donor mapping

Do not create an arbitrary runtime `alternates/` directory for ordinary plates. Their semantics belong in state ids and profile policy data.

### Existing family extension — `procgen_underlay_alpine_plateau`

- kind: `backdrop`
- canvas: 1536×1024 RGBA, true alpha, one static frame, direction `omni`
- standard source-work: `custodian/asset_drop/source_work/procgen/procgen_underlay_alpine_plateau/<state>_source.png`
- standard inbox: `custodian/asset_drop/inbox/procgen_underlay_alpine_plateau/<state>.png`
- runtime remains: `custodian/content/backgrounds/procgen/alpine_plateau/`
- all states below are `required: false`, `recommended: true`
- weights are relative inside their own layer pool and are normalized by the selection policy

| State | Donor plate | Role | Relative weight |
| --- | --- | --- | ---: |
| `far_world_alt_01` | gen1 `misty_alpine_ruins_in_the_clouds.png` | far | 0.45 |
| `far_world_alt_02` | gen1 `misty_floating_ruins_in_the_mountains.png` | far | 0.40 |
| `far_world_alt_03` | gen1 `ruined_alpine_valleys_in_mist.png` | far | 0.60 |
| `far_world_alt_04` | gen2 `floating_ruins_in_the_alpine_mist.png` | far | 0.45 |
| `far_world_alt_05` | gen2 `misty_cloud_ruins_and_cliffs.png` | far | 0.60 |
| `far_world_alt_06` | gen3 `snowy_ruins_above_the_mist.png` | far | 0.65 |
| `far_world_alt_07` | gen3 `floating_ruins_above_the_cloud_sea.png` | far | 0.45 |
| `depth_fog_alt_01` | gen1 `misty_alpine_ruins_fog_overlay.png` | middle | 0.70 |
| `depth_fog_alt_02` | gen1 `misty_mountain_ruins_fog_overlay.png` | middle | 0.65 |
| `depth_fog_alt_03` | gen2 `misty_floating_ruins_overlay.png` | middle | 0.45 |
| `depth_fog_alt_04` | gen3 `volumetric_mountain_ruins_in_mist.png` | middle | 0.70 |
| `depth_fog_alt_05` | gen3 `fog_wrapped_ruined_mountain_cliffs.png` | middle | 0.50 |
| `near_cliff_mist_alt_01` | gen1 `frostbound_ruins_above_the_mist.png` | near | 0.40 |
| `near_cliff_mist_alt_02` | gen1 `mistbound_mountain_ruins.png` | near | 0.45 |
| `near_cliff_mist_alt_03` | gen2 `floating_alpine_cliffs_in_mist.png` | near | 0.65 |
| `near_cliff_mist_alt_04` | gen2 `suspended_alpine_ruins_in_mist.png` | near | 0.45 |
| `near_cliff_mist_alt_05` | gen3 `fragmented_alpine_cliffs_in_mist.png` | near | 0.65 |
| `near_cliff_mist_alt_06` | gen3 `floating_alpine_cliffs_and_mist_islands.png` | near | 0.45 |

### New scenic-landmark family — `procgen_underlay_alpine_landmark`

These are deliberately separated from ordinary alternates so no generic variant array can accidentally make them common.

- kind: `backdrop`
- canvas: 1536×1024 RGBA, true alpha, one static frame, direction `omni`
- metadata target: `custodian/content/metadata/assets/families/procgen_underlay_alpine_landmark.asset.json`
- source-work: `custodian/asset_drop/source_work/procgen/procgen_underlay_alpine_landmark/<state>_source.png`
- inbox: `custodian/asset_drop/inbox/procgen_underlay_alpine_landmark/<state>.png`
- runtime: `custodian/content/backgrounds/procgen/alpine_plateau/landmarks/`
- all six states are required for this family/handoff; runtime rarity is controlled by the variant policy, not Asset V2 requiredness

| State | Donor plate | Replaces layer | Hero weight |
| --- | --- | --- | ---: |
| `far_custodian_fortress_01` | gen2 `floating_alpine_fortress_landscape.png` | far | 0.20 |
| `far_civic_archipelago_01` | gen3 `floating_snowy_temple_archipelago.png` | far | 0.20 |
| `far_monumental_realm_01` | gen1 `misty_ruins_of_the_far_mountain_realm.png` | far | 0.15 |
| `far_ruined_plateau_01` | gen2 `snowy_ruined_mountain_plateau.png` | far | 0.20 |
| `middle_ancient_ruin_reveal_01` | gen1 `transparent_mist_over_ancient_ruins.png` | middle | 0.15 |
| `near_custodian_citadel_01` | gen1 `misty_ruined_cliffside_citadel.png` | near | 0.10 |

The Custodian citadel is intentionally the rarest hero. With the landmark gate below and weight 0.10, its target effective occurrence is roughly 0.31% of Alpine seeds, about one in 320, before any future authored eligibility restriction.

## Exact deterministic usage policy

Implement the policy as data/config interpreted by the existing underlay authority. A focused resource such as `ProcgenUnderlayVariantPolicy` is appropriate; do not hard-code this table into the backdrop if live main offers a cleaner existing profile seam.

Use `selection_revision = 1` as part of every selection hash so a future intentional distribution change can be versioned.

### Tier gate

Evaluate in this order:

1. **Scenic landmark:** stable hash of `accepted_seed + profile_id + selection_revision + "landmark_gate"`; landmark tier when `hash % 32 == 0`. Target = 3.125% of Alpine seeds.
2. **Ordinary alternate:** only when landmark tier did not trigger. Stable independent hash ending in `"alternate_gate"`; alternate tier when `hash % 16 < 3`. Target = 18.75% of non-landmark seeds, about 18.16% overall.
3. **Baseline:** every remaining seed, about 78.71% overall.

The exact hash helper may follow live project conventions, but the identity inputs, revision, gates and resulting deterministic percentages are contract.

### Baseline tier

Use AP1 behavior unchanged. Preserve the existing independent deterministic A/B choice for FAR/MIDDLE/NEAR. Do not perturb baseline A/B results merely because this policy exists.

### Ordinary-alternate tier

- Substitute **exactly one** layer; never two or three.
- Choose the substituted layer deterministically with relative bucket weights FAR/MIDDLE/NEAR = **4/3/3**.
- Pick one state from that layer's ordinary alternate pool using the relative weights in the table above.
- The other two layers use their ordinary AP1 deterministic baseline A/B result.
- Do not mix a scenic landmark with an ordinary alternate.
- Ordinary alternates use the normal AP1 per-layer opacity, parallax, base fill and coverage behavior.

This keeps alternate seeds recognizably Alpine without producing unreviewed all-alt architecture stacks.

### Scenic-landmark tier

- Select **exactly one** scenic landmark from the six-state landmark family using the global hero weights above.
- Replace only the landmark's declared layer.
- Force every non-landmark layer to the quiet canonical **B** baseline companion for that layer.
- Do not select any ordinary alternate on a landmark seed.
- Maximum scenic landmarks per generated Alpine region = **1**.
- Use ordinary AP1 opacity/parallax/base-fill behavior; no glow, camera take-over, POI marker, encounter, music cue or gameplay semantic is implied by the image.
- The rare plate must remain stable for the accepted map seed across reload and streaming.
- If a future feature wants a real explorable citadel/fortress, that must be implemented as a separate gameplay-landmark/system and must not infer existence from this scenic plate.

## Diagnostics

Expose enough read-only state for validation/review:

- `selection_revision`
- selected tier: `baseline | alternate | landmark`
- baseline A/B ids for all three layers
- final selected state id for FAR/MIDDLE/NEAR
- alternate layer/state when applicable
- scenic landmark id when applicable

Reuse existing procgen/Moment Forge probe surfaces where practical. Do not add per-frame telemetry.

## Required External Input — Variety Handoff

Only a new immutable handoff satisfies this packet:

```text
CUSTODIAN/implementation_inputs/
  procgen-alpine-underlay-variety-v1/
    alpine-underlay-variety-v1/
      HANDOFF_MANIFEST.json
      payload/
        procgen_underlay_alpine_plateau/   # 18 exact ordinary alternate PNGs, renamed to state ids above
        procgen_underlay_alpine_landmark/  # 6 exact scenic-landmark PNGs, renamed to state ids above
```

Exactly **24 PNGs** are required. `HANDOFF_MANIFEST.json` must use `custodian.implementation_handoff.v1`, record this exact authoring chat URL, preserve the donor-generation/source filename mapping above, and provide hashes/dimensions for every payload file.

The existing 30-image review ZIP is donor/provenance evidence only. Do not use it directly as an implementation handoff, do not regenerate these plates, and do not reinterpret the six AP1 baseline choices as part of this packet.

## Acceptance

1. AP1/AP2/AP3/AP4 are complete and the AP1 final six remain unchanged.
2. The exact 24-plate variety handoff verifies schema, workstream/id, authoring chat, hashes, dimensions and donor mapping.
3. Existing `procgen_underlay_alpine_plateau` gains exactly the 18 optional ordinary states without changing/removing the six AP1 required states.
4. `procgen_underlay_alpine_landmark` publishes exactly six scenic landmark states in its separate runtime domain.
5. Profiles with no variant policy preserve pre-packet selection behavior exactly.
6. Baseline Alpine seeds preserve the existing AP1 per-layer A/B result.
7. Alternate seeds substitute exactly one layer, respect 4/3/3 layer weighting, and never select a scenic landmark.
8. Landmark seeds select exactly one scenic landmark, force the other two layers to canonical B companions, and never select an ordinary alternate.
9. A pure fixed-range sweep of at least 65,536 seeds proves all 24 new states are reachable, no seed violates the one-substitution/one-landmark caps, and observed baseline/alternate/landmark rates are within ±2 percentage points of the target distribution.
10. The rare `near_custodian_citadel_01` is reachable but remains materially rarer than an ordinary alternate; no code special-cases a hand-authored list of numeric seeds.
11. Same accepted seed/profile/revision gives identical selection across reload and streaming.
12. Internal CHASM, non-Alpine Region Frames, Archive Resolve, collision/navigation/topology and gameplay semantics are unchanged.
13. Compact renderer evidence includes at least one baseline seed, one alternate seed for each layer role, and all six scenic landmark plates; human review confirms ordinary alternates feel occasional and hero plates feel special rather than routine.
14. Active docs/index/roadmap describe AP5 as post-closeout variety, not a requirement for AP1–AP4 completion.

## Validation

Before renderer work, run Asset V2 plan/status/doctor for both affected families and focused profile/policy tests. Add a pure underlay-selection-policy smoke that can sweep at least 65,536 seeds without rendering and reports tier counts, per-layer alternate counts, per-state reachability, landmark counts, determinism and cap violations. Run existing Region Frame/underlay/elevated-world coverage, streaming/reload, non-Alpine compatibility and changed-file validation plus `git diff --check`.

After objective checks pass, publish the smallest useful Moment Forge review set:
- one ordinary baseline seed;
- three ordinary-alternate seeds, one FAR, one MIDDLE, one NEAR;
- six landmark seeds, one per scenic landmark plate.

Ask whether ordinary alternates extend geographic variety without drawing attention to themselves, whether each rare landmark reads as a memorable exception, whether the Citadel feels genuinely special, and whether any landmark plate makes the background compete with gameplay.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `none`
- Root cause / contributing factors: `none`
- Prevention / pipeline improvement: `none`
- Tooling / docs drift discovered: `none`
- Follow-up: `none | fixed-in-scope | manual-follow-up`

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Refresh instruction: At claim time, re-derive the landed AP1 underlay profile and selection seam from live main. Preserve the exact rarity contract and asset mapping above unless the user explicitly refreshes it. Escalate only if AP1/AP4 materially changed underlay ownership, persistence, or profile selection.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Refresh reason: `none`
- Next action: Human review of the post-closeout variety/landmark distribution after AP5 implementation.
- Blockers or open questions: AP4 must complete first and the exact 24-plate immutable variety handoff does not yet exist.
