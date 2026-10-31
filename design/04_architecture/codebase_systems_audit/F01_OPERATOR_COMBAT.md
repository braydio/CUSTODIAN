# F01 · Operator runtime and combat

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** 2026-10-23 source-level ownership audit complete for the anti-rebloat boundary; in-game behavioral verification remains the domain packets' work
> **Decision state:** **LOCKED for Chassis Authority Seal V1 only**; the original F2/F3/F5/F6/G program remains authoritative
> **Snapshot:** `main@65ee6fef70a6ad326a16ffbd46ebf18d7f3326db` · October 23, 2026
> **Method:** live GitHub file/packet/architecture/validation inspection; no Godot execution
> **Priority:** P0 for pre-extraction guard; F2/F3/F5/F6/G remain P1

## Focus boundary
This item audits the named system's responsibility, integration seams, observed friction and relevant game-feel consequences. Existing architecture and implementation packets remain authoritative for already-claimed work. This document is a **diagnostic/decision record**, not a new feature spec or Codex execution instruction.

## Evidence from current inspection
- `game/actors/operator/operator.gd` is approximately 581 KB in the inspected tree; size is a hotspot indicator, not proof of an extraction defect.
- The architecture contract and CURRENT_STATE say F0 dependency injection and F4 Dodge extraction completed. `operator.gd` still exposes substantial orchestration and direct combat/presentation constants.
- F0 injection, F1 loadout, F4 dodge and guard/parry composition are archived complete; F2 melee, F3 ranged, F5 interaction, F6 recovery and final G shell collapse are active dependency-gated packet work.


## 2026-10-23 source-level audit: confirmed vs not yet proved

- `operator.gd`: **14,676 lines**, **738 top-level `func` declarations**, **478 top-level `var` declarations**, approximately **588 KB** at the exact snapshot above. The stored architecture debt baseline is an empty object, **not** an exhaustive structural ownership proof.
- The actor still stores melee attack/drive/contact/target/buffer state, ranged ammo/reload/ready/fire state, repair/build/interaction targets, damage/Field Patch/death state, and large presentation policy helpers. Existing controller names alone do not show that those stateful responsibilities moved.
- Foreign motor leak confirmed: the Operator's melee hit fallback still invokes `enemy.move_and_slide()` near line 7049. Record this as bounded F2 migration debt. Do not remove it without contact/knockback/regression evidence.
- The current architecture debt audit checks specific regex pattern families and permits any `move_and_slide()` call originating in `operator.gd`; it does not reject new or expanded domain-owned state, enlarged existing methods, or an increased actor facade surface.
- GitHub reports no rulesets and main is unprotected; normal push/PR CI is not a fail-closed pre-landing gate. Require the existing autonomous finish path to enforce the new guard, and separately distinguish any unverified server-side protection.
- **Not yet proved:** exact mutable-vs-facade classification for every field, dynamic method reachability, behavioral parity after extraction, final thin-chassis budget, or empirical current Godot runs. The seal implementation and fresh review must measure/falsify those, not inherit invented PASS evidence.

## Selected intervention and boundaries

- **Authorized now:** `operator-chassis-authority-seal-v1` implementation plus `review-operator-chassis-authority-seal-v1`, published as an atomic packet pair and promoted by the canonical automatic authoring handoff. This is **not** a competing decomposition and makes no gameplay changes.
- **Owner:** the dedicated Operator chassis guard, registered with existing validation/finish controls. State owners remain F2 melee, F3 ranged, F5 interaction, F6 damage/recovery, followed by G chassis collapse.
- **Required ordering:** F2/F3/F5/F6 and G must not proceed before the independent seal review is complete; update their existing dependencies, not new competing packets.
- **Acceptance:** classified factual migration baseline, measurable monotonic budgets, negative adversarial fixtures for new/expanded stateful methods, hidden foreign-body movement, policy bypass, and enforceable Operator-touching pre-landing failure. Chassis remains the sole local CharacterBody2D motor.
- **Non-goals:** no F2-F6 code extraction, no combat or rendering retuning, no art; retained compatibility facades require callers/expiry evidence. Post-G verification remains conceptual CS-F01-A until separately warranted.
- **Drift action:** correct stale F1 status and 41-violation references in current ownership summaries while preserving timestamped historical claims.

## Questions the deep audit must answer
- Which live state and mutation paths remain actor-owned after F0/F4, and which are intentional CharacterBody2D/chassis responsibilities?
- Are melee, ranged, loadout and presentation clocks duplicated or only mediated by the facade? Identify actual call sites and state mutation owners.
- Which moving-but-committed animation cases currently slide or freeze lower-body cadence? Verify with deterministic replay plus sparse Moment Forge evidence.

## Candidate directions (not approved)
- Prefer finishing existing F1–F6/G program in dependency order rather than a competing blanket `operator.gd` split.
- Keep fixed-step movement, public compatibility facade, and single simulation/presentation authorities; remove obsolete bridges only after consumer proof.
- Separate gameplay-equivalent extraction from feel tuning: composition fixes may travel with domain extraction, balance changes require later explicit decisions.

## Evidence and falsification checklist
- Capture function/line/debt baseline using existing `operator_architecture_debt_audit.py --json`, runtime path and animation authority reports.
- Run focused action/guard/dodge/melee/ranged/Field Patch tests for the exact slice; final G gate owns `--final` audits.
- Record net eliminated actor-owned state, public API compatibility, and validation-manifest reassignment; identify any left-behind temporary seams.

## Existing source of truth and adjacent implementation work
- [`design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md)
- [`custodian/game/actors/operator/operator.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/actors/operator/operator.gd)
- [`custodian/docs/ai_context/CURRENT_STATE.md`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/CURRENT_STATE.md)

### Newly authorized anti-rebloat packet
- [`OPERATOR_CHASSIS_AUTHORITY_SEAL_V1.md`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_CHASSIS_AUTHORITY_SEAL_V1.md): structural guard, pre-landing integration and shrinking exception budget; independent paired review gates remaining extractions.

### 2026-10-31 implementation measurement (unlanded)

The active `operator-chassis-authority-seal-v1` workstream measured its claimed
source tree as 14,792 lines, 577 top-level fields (477 mutable and 100
constants), and 742 top-level functions. It records field readers/writers and
method ownership, state, clock, delegation, branch, and normalized code-token
fingerprint evidence. The current inventory reports 198 mutable F2 melee
fields, 94 F3 ranged, 6 F5 interaction, 57 F6 survivability, 75 chassis, 36
presentation bridge, and 11 delegation references. These are measured legacy
counts, not a claim of zero debt. Fifty-two methods remain explicitly labeled
`legacy_other_gameplay_authority`; mixed-domain and post-extraction compatibility
methods are also retained as measured categories.

Exactly one foreign-body movement exception remains: `enemy.move_and_slide()`
inside `_apply_melee_hitbox_tick()` at source line 7177 in this snapshot. F2
owns its retirement after the impact/knockback regression surface is covered.
The new guard work is in progress and unlanded; this note does not report an
independent review or completed acceptance. The existing migration-audit debt
is 23 legacy path-identity lines and 188 legacy runtime animation files; the
guard records their pre-change identities and prevents growth while leaving
the debt outstanding. F2/F3/F5/F6 own domain extraction and reduction; Slice G
owns final elimination and the final zero-debt audits. Passing ordinary audit
modes does not close these migrations. The dated 2026-10-23 snapshot and its
“not yet proved” findings above remain historical evidence.

### Existing task packets (do not duplicate)
- [`OPERATOR_LOADOUT_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/archived/OPERATOR_LOADOUT_DOMAIN_EXTRACTION.md) · **existing queue authority; not created by this audit**
- [`OPERATOR_MELEE_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_MELEE_DOMAIN_EXTRACTION.md) · **existing queue authority; not created by this audit**
- [`OPERATOR_RANGED_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_RANGED_DOMAIN_EXTRACTION.md) · **existing queue authority; not created by this audit**
- [`OPERATOR_INTERACTION_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_INTERACTION_DOMAIN_EXTRACTION.md) · **existing queue authority; not created by this audit**
- [`OPERATOR_RECOVERY_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_RECOVERY_DOMAIN_EXTRACTION.md) · **existing queue authority; not created by this audit**
- [`OPERATOR_RUNTIME_SHELL_COLLAPSE`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_RUNTIME_SHELL_COLLAPSE.md) · **existing queue authority; not created by this audit**

### Proposed packet slots (non-executable links to roadmap)
- [CS-F01-A: Post-extraction Operator ownership/debt verification, only if existing Slice G does not close evidence gaps](PACKET_ROADMAP.md#cs-f01-a) · proposed filename `CODEBASE_AUDIT_OPERATOR_POST_G_VERIFY.md`; **not created**

**Dependencies / interference guard:** Existing Operator program and its current review gates; do not bypass queued F1–F6/G.

## Decision lock record
- **Audit verdict:** Confirmed structural authority still actor-owned; zero regex debt does not imply thin chassis.
- **Chosen boundary and owner:** Operator chassis authority guard, not a second gameplay controller.
- **Selected behavior/game-feel:** No changes authorized.
- **Preserved invariants:** Fixed-step physics; one local movement chassis; canonical input, animation and existing extracted state owners; no runtime behavior changes from the guard itself.
- **Validation/falsification:** Exact source baseline, targeted positive/negative syntax-aware owner tests, captured pre-landing fail/green gates, existing architecture/path/animation final audits, relevant workflow tests.
- **User/ChatGPT approval:** Explicit user instruction on 2026-10-23: "Publish that now".
- **Implementation decision:** **LOCKED for seal only.** Other candidate directions and the conditional post-G audit are not separately approved.

## Planned next audit action
Publish the two seal packets together, let canonical authoring promotion validate them, implement and independently review the guard, then resume existing F2/F3/F5/F6/G in their locked ownership order. Existing F2-F6 tests remain responsible for behavior-level proof.
