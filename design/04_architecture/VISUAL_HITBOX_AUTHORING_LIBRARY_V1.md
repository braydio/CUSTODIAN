# CUSTODIAN | Visual Hitbox Lab | Full Buildout Roadmap V1

**Status:** approved program design and authored task-packet sequence; no production implementation or art approval implied.  
**Audit baseline:** braydio/CUSTODIAN main@ebfe3810eec146d7202a4378324b0f32c9e12fee (2026-11-08).  
**Authoring chat:** not-recorded (replace only with the exact user-supplied current conversation URL).  
**Implementation scope:** A frame-accurate authoring and diagnostic surface for the real attack volumes and hit timing already used in CUSTODIAN. The lab may change profile data only through reviewed, transactional operations; it never becomes damage authority.

## Verified starting condition

MeleeAttackProfile at custodian/game/systems/combat/melee_attack_profile.gd exports range_px, arc_degrees, windup_sec, active_sec, recovery_sec, presentation_action and hit_window_frames. OperatorWeaponDefinition references those resources. MeleeTargetResolver owns acquisition/drive reach. Existing Operator Animation Workbench owns canonical sprite and timing publication. The chassis/F2 extraction is not declared complete in CURRENT_STATE.md. A per-frame polygon authoring runtime is not established by this audit; don't fabricate it.

## Intended gameplay/presentation payoff and operating mechanics

1. Semantic attack selector resolves the exact weapon, attack profile, direction, animation clip, sprite source, authored per-frame durations and frame/root registration. Display diagnostic N/A rather than silently choose a legacy fallback.
2. Two superposed truths: a 128px-compatible (or source-declared size) preview of the real body/weapon clip and a geometry overlay computed from the current runtime range/arc/forward aim, plus any verified shape owner. Explicitly label range/arc as a sector, not an authored pixel-perfect polygon.
3. Scrubbable timeline shows windup, active, recovery, individual contact frames, queue/cancel regions, optional synchronized layers, hitstop and a planted test target with signed distance-to-hit.
4. Diagnostics flag out-of-range contact frames, inconsistent sidecar/frame duration, invalid direction mapping, anchor/root migration, unsupported source forms and intended tip-of-weapon mismatch. Every warning links to its actual profile or source owner.
5. Edit a narrow allowlist of MeleeAttackProfile values and hit-window frames only after a dry-run, a source fingerprint/revision check, UndoRedo-compatible commit, and collision checks with active F2 workstreams. Source PNGs, generated catalogs, socket files, and runtime artifacts remain under their existing owners.
6. Output replayable versioned machine-readable probe reports and minimal ROI review frames; compare before/after profiles in one fixed scenario. An optional runtime debug display consumes the same projection read-only; no gameplay mutation.

## Core boundaries

**Preserve:** One combat authority; the active F2/F3/F5/F6 migration, passive MeleeTargetResolver, existing .tres profile references, per-frame sidecars, exact operator identity, existing Workbench publication and independent review gates. No parallel operator.gd hitbox logic.

**Explicit non-goals:** Do not implement polygon-based melee damage, edit canonical art, change weapon balance automatically, regenerate Operator frames, or treat the overlay as a new collision source. A future true per-frame polygon gameplay system requires its own design and acceptance, only if a real encounter proves the current arc/range model insufficient.

**Measure success:** Against a pinned attack (.tres + exact source/canvas identity), display an 8-direction frame strip without changing contact frames; report reproducible active frame set, arc degrees, reach in pixels, source SHA, animation sidecar clock and root. User edits should round-trip only changed profile values and survive reload; invalid direction, moved source, mismatched frame count and untrusted path fail closed. Runtime combat regression checks must remain unchanged.

**Art / Asset Pipeline V2:** No newly generated art or Asset V2 family needed. Read existing approved Operator runtime/catalogs and profile resources; never insert preview exports into asset_drop/inbox. Any future character sprite change stays in the specialized Operator source-to-runtime pipeline.

**Human-owned review:** Human review is required for whether the displayed overlays are intelligible and whether contact looks right at native gameplay scale, not for the geometry identity checks. One test attack must pass an A/B before authoring becomes the preferred route.

## Dependency DAG and staged production

| Slice | Workstream ID | Deliverable | Depends on review | Visual decision |
|---|---|---|---|---|
| 1 | visual-hitbox-lab-runtime-probe-v1 | Read-only live geometry & timeline probe | none | conditional |
| 2 | visual-hitbox-lab-profile-editing-v1 | Constrained editor & transaction | review-visual-hitbox-lab-runtime-probe-v1 | conditional |
| 3 | visual-hitbox-lab-validation-v1 | Contact lab, runtime debug and adoption | review-visual-hitbox-lab-profile-editing-v1 | required |

### 1. Read-only live geometry & timeline probe

**Implementation:** visual-hitbox-lab-runtime-probe-v1  
**Independent review:** review-visual-hitbox-lab-runtime-probe-v1  
**Dependency:** none  
**Primary locks:** visual-hitbox-lab  
**Priority:** P1

**Change:** Create a versioned read-only probe of profile+source+direction+frame timing with root-aligned sector overlay, frame scrub, target-distance indicator, a truthful source-missing state, and JSON report. Resolve the actual attack/window clock, never infer target frames from filename recency; include deterministic synthetic geometry tests.

**Acceptance:** One unarmed and one armed attack across at least S/E/NW demonstrate exact profile reach, arc, hit-window frames and direction/root identity; snapshot report stable byte-for-byte; missing/ambiguous animation or stale profile fails closed; no tracked gameplay asset files changed.

**Validation:** custodian/tools/validation/operator_unarmed_fast_chain_smoke.gd; custodian/tools/validation/operator_modular_fast_attack_smoke.gd; custodian/tools/validation/operator_animation_plan_smoke.py; new focused probe unit and Godot scene smoke; changed-file validation.

**Next deferred:** Profile editing, user-authored spline/polygon collision, runtime debugging overlays and gameplay balance changes.

### 2. Constrained editor & transaction

**Implementation:** visual-hitbox-lab-profile-editing-v1  
**Independent review:** review-visual-hitbox-lab-profile-editing-v1  
**Dependency:** review-visual-hitbox-lab-runtime-probe-v1  
**Primary locks:** visual-hitbox-lab, melee-profile-authoring  
**Priority:** P2

**Change:** Add Godot editor controls for reach/arc and frame-window markers, preview-and-diff, undo/redo, readonly/armed modes, exact hash+mtime conflict refusal, and save of only whitelisted profile keys. Enforce direction-specific warnings without silently creating shape data. Check any F2 ownership/claim conflicts before work.

**Acceptance:** A 3-frame hit-window edit round-trips in one profile with nothing else changed; undo/redo returns exact prior values; stale source/ref, out-of-bounds frame, invalid arc or conflicting workstream all refuse writes; gameplay behavior unchanged except explicitly edited test profile.

**Validation:** custodian/tools/validation/operator_unarmed_fast_chain_smoke.gd; custodian/tools/validation/operator_sword_cleaver_smoke.gd; new editor transaction regression and conflict fixtures; changed-file validation.

**Next deferred:** No broad rebalancing, no automatic profile migration and no true polygon combat.

### 3. Contact lab, runtime debug and adoption

**Implementation:** visual-hitbox-lab-validation-v1  
**Independent review:** review-visual-hitbox-lab-validation-v1  
**Dependency:** review-visual-hitbox-lab-profile-editing-v1  
**Primary locks:** visual-hitbox-lab, combat-presentation-validation  
**Priority:** P2

**Change:** Add fixed-target and moving-target preview, side-by-side attack A/B, frame-contact capture, read-only runtime overlay gated to dev mode, discrepancy export, and bounded per-attack acceptance presets. Exercise combo queue, hitstop, multi-direction clips, animation timing sidecars and scene restore.

**Acceptance:** At least three distinct attack families (unarmed, melee 2h and one linked combo) produce reproducible reviews; exported discrepancy includes source/profile identities; enabling the runtime overlay cannot affect hits, damage or deterministic simulation; human approves native-scale readability.

**Validation:** custodian/tools/validation/operator_unarmed_fast_chain_smoke.gd; custodian/tools/validation/operator_sword_cleaver_smoke.gd; custodian/tools/validation/operator_modular_fast_attack_smoke.gd; new lab gameplay/projection smoke; changed-file validation.

**Next deferred:** Future polygon hitbox mechanics only on explicit need and separately reviewed contract.

## Integration and file ownership

- New library code and tests are **planned outputs**, not already published runtime features. Workstream packets name the recommended repository-relative owners and exact focused baselines.
- Required inputs for each packet are this document plus the current-main source owners named in its Evidence section; no chat-only schemas, reference ZIPs or art are needed to claim the first slice.
- Every implementation stage gets a separate post-land fresh-context review. The implementation workstream does not self-approve its review. Only the first implementation/review pair opts in to automatic authoring preflight; successors remain draft/manual pending predecessor review and a refreshed repository/claim audit.
- Before any new production texture, family or runtime art route, inspect design/04_architecture/ASSET_PIPELINE_V2.md, the registered family schema and the actual consumer. New art requires source/alpha/dimension/animation contracts, human review, and explicit source_work/inbox routing.
- Deterministic tests and source/geometry/contracts precede visual inspection. Material aesthetic decisions require a minimal ROI/short-motion handoff. The default is no new full-screen recording or unnecessary LFS generation.

## Documentation drift and change hygiene

The older design/02_features/combat_feel/COMBAT_FEEL_UPGRADE.md still presents some now-live feel work as PLANNED and references retired custodian/assets paths. Before later profile-writing slices, reconcile the active combat ownership map and those statements rather than copying them into a new authority.

This document is a forward plan, not a claim that every planned stage is implemented. On each stage closeout, reconcile impacted live design, CURRENT_STATE.md, FILE_INDEX.md, actual code, test ownership and asset registry truth. Do not rewrite unrelated historical state or bypass independent reviews.

## Release / stop conditions

1. Never assume a partial implementation is ready/auto without the current packet authoring preflight and remote publication receipts.
2. The review of every stage must archive PASS before the dependent stage becomes claimable. A review finding keeps the original workstream identity and enters its bounded correction/re-review lifecycle.
3. A human/ChatGPT visual decision is mandatory for final subjective polish; technical PASS does not imply aesthetic approval.
4. If a new runtime gameplay authority, unapproved art family, or incompatible schema is necessary, stop and return the smallest explicit decision/proof to the authoring chat instead of silently inventing ownership.
