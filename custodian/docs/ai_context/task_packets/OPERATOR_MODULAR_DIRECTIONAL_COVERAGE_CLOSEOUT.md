# OPERATOR MODULAR DIRECTIONAL COVERAGE CLOSEOUT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-modular-directional-coverage-closeout`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `operator-melee-domain-extraction, operator-ranged-domain-extraction, operator-guard-parry-composition-polish, operator-recovery-domain-extraction`
- Locks: `operator-assets`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `6ea46c34eade8b6737cd0f1f128594235aa1b5ff`
- Goal: Close only the directional/layer art gaps that remain visibly harmful after the modular runtime compositions are final, so authored coverage improves where the player can actually see projection artifacts without generating completeness-for-completeness's-sake.
- Completion boundary: Done when runtime evidence from the landed mobile guard/melee/ranged/recovery compositions produces a reviewed gap list; every accepted gap is fulfilled through Asset Pipeline V2 with production-quality registration/cadence; every rejected gap is documented as an intentional projection; canonical coverage/reachability and visual-fit tooling agree; and no runtime fallback/projection remains solely because required production art was never evaluated.
- Current measured state: Canonical art coverage is intentionally uneven. Current manifest facts include: unarmed upper `idle_01/ne` absent while lower NE is 6f; unarmed upper `walk_01/ne` and `walk_01/nw` absent while their lowers are 6f; ranged `aim_01` body/weapon currently publishes E/SE/SW/W, `fire_01` publishes N/E/SE/SW/W with FX sparser, and `stance_01` upper publishes all sectors except S; sidearm body/weapon draw/fire is authored primarily on NE/NW/SE/SW and projects cardinals; armed melee walk/run coverage is sparse relative to the independent-facing composition proposed in F2. Existing authored-sector projection tables intentionally preserve current visuals, so missing identity is not by itself proof new art is needed. Latest main also contains ten raw **east-facing** unarmed-defense source-work candidates at 2172x724 under `asset_drop/source_work/operator/unarmed_defense_10_generated/`. Those files do not close any directional gap and are not production assets; `operator-unarmed-defense-source-promotion` owns their normalization/promotion. This packet must not count raw source-work as authored coverage. Documentation drift also remains in the editable `custodian/content/metadata/assets/required_assets.registry.json`: several Operator modular lower/upper/ranged/sidearm needs still target the retired `content/sprites/operator/new_operator/modular/...` / `runtime/modules/new_operator/...` layout even though active publication is Asset V2 canonical `source/animations` -> `runtime/animations`. Root `REQUIRED_ASSETS.md` is generated and must not be hand-edited.
- Evidence: generated Operator runtime manifest; authored-sector policy tables in Operator presentation; post-F2/F3/guard/recovery visual-fit evidence; Operator art registration/Workbench tooling.
- Task-specific authority: canonical Operator animation authority; `design/04_architecture/ASSET_PIPELINE_V2.md`; Operator art registration profile; active combat/presentation specs after the dependent runtime slices land.
- Work surface: Asset V2 Operator inbox/source/runtime, only the accepted animation families/directions, visual-fit/registration validation and generated coverage/reachability reports. Runtime composition policy changes are out of scope except deleting a projection that becomes unnecessary after real art lands.
- Change:
  1. After dependencies land, generate a machine-readable requested-vs-authored coverage/visual-fit report for the actual live compositions. Rank by visible seam/projection error and runtime frequency, not by mathematical missing-sector count. Exclude `asset_drop/source_work/**` from authored/runtime coverage counts; only canonical Asset V2 source/runtime publication counts.
  2. Human-review the candidate list. Promote only gaps whose projection harms silhouette, hand/weapon registration, facing readability or cadence. Leave acceptable projections intentional and documented.
  3. Current candidate handoff convention for a newly authored Operator layer is `custodian/asset_drop/inbox/operator/operator__<layer>__<profile>__<group>__<action>__<direction>__<N>f__96.png`. Examples if review confirms they are needed:
     - `operator__upper_body__unarmed__locomotion__idle_01__ne__6f__96.png` -> 576x96
     - `operator__upper_body__unarmed__locomotion__walk_01__ne__6f__96.png` -> 576x96
     - `operator__upper_body__unarmed__locomotion__walk_01__nw__6f__96.png` -> 576x96
     - ranged `aim_01` missing action sectors use the existing 5f 96x96 family unless the approved source contract says otherwise -> 480x96 per layer
     - ranged `fire_01` missing sectors follow the corresponding reviewed body action frame count, not an invented uniform count.
  4. Asset-family schema for these additions: owner `operator`; semantic profile (for example `unarmed`, `ranged_2h`, `sidearm`, `melee_1h`); action group/action; exact direction; exact layer (`lower_body|upper_body|weapon|fx`); frame size `96x96`; reviewed frame count/FPS/loop/durations copied from the intended family clock when structurally compatible. Runtime names are generated.
  5. Final generated paths remain `custodian/content/sprites/operator/source/animations/<profile>/<group>/<action>/` and `.../runtime/animations/<profile>/<group>/<action>/`.
  6. Use Operator registration tooling before pixel judgment: anchor/seam metrics, alpha bounds, cadence/progress and counterpart registration. Do not fix a bad composite by hiding a seam with extra opaque pixels or by resampling.
  7. Re-run runtime composition evidence after each accepted family; remove caller-owned sector projection entries only when exact authored coverage now exists.
  8. Reconcile the **editable** required-assets registry entries for every touched Operator family to the current Asset V2 inbox/canonical source/runtime layout and factual coverage. Then regenerate/check root `REQUIRED_ASSETS.md`; never patch the generated view by hand.
- Preserve: existing acceptable projections; runtime movement/action ownership; frame timing; semantic identities; true-alpha pixel-art contract; no runtime mirroring of canonical identities unless an explicitly reviewed counterpart publication creates the canonical counterpart.
- Non-goals: No blanket eight-way expansion. No head/cape reactivation. No combat tuning. No new runtime state. No accepting lower-quality auto-generated art merely to fill a table.
- Acceptance: Every final asset need is justified by a concrete runtime visual/registration defect; accepted assets pass V2 and registration/cadence checks; no accepted gap remains projected; no rejected gap is regenerated merely for completeness; generated manifest/reachability/Workbench coverage agrees; touched required-assets registry rows no longer point at retired `new_operator/modular` paths and regenerated root `REQUIRED_ASSETS.md` matches; subjective art acceptance remains human-owned.
- Validation: Asset V2 dry-run/apply/doctor plus Operator animation contract/registration reports first. Use tight ROI/contact-sheet evidence for only the affected directions and transitions, at runtime scale. Full-motion capture only for cadence problems that still cannot be judged from keyframes. One changed-file closeout after final accepted assets.
- Task overrides: `none`
- Deferred: Modular head/cape remain dormant; reactivation requires its own presentation/art packet. East-facing defense source normalization/replacement is owned by `operator-unarmed-defense-source-promotion`, not this directional closeout.

## Handoff

- Next action: Do not promote to ready until the dependent runtime compositions land and a human has accepted the concrete gap list.
- Best starting files: generated runtime manifest; Operator visual-fit/registration reports; post-F2/F3/guard/recovery Moment Forge evidence.
- Blockers or open questions: Exact art list intentionally remains human-reviewed because current missing sectors are not automatically defects.