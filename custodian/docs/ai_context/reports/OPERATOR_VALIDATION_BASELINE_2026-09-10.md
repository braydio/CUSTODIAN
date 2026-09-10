# Operator Validation Baseline — 2026-09-10 (B.5)

**Purpose:** establish a deterministic clean-tree Operator validation baseline so
later architecture slices can distinguish regressions from existing failures.

**Verdict:** **safe to begin Slice C.** The Operator actor-tier suite is
**41/41 green across three consecutive sweeps**. One deterministic red was
diagnosed to root cause and formally characterized; the three "flaky" smokes
were environmental, not runtime races.

## 1. Worktree state

Other sessions' work was preserved throughout — nothing was reset, cleaned,
regenerated or overwritten.

```
git diff --name-only        (unstaged, tracked)
  AGENTS.md
  custodian/AGENTS.md
  custodian/asset_drop/source_work/awakening/creche_recovery_alcove/{idle,wake,wake.normalized,wake.source_original}.png
  custodian/asset_drop/source_work/awakening/gate_of_dust/awakening_creche_console_idle_source.png
  custodian/asset_drop/source_work/awakening/late_service/{gate_structure_idle,west_pylon}.png

git diff --cached --name-only
  (empty)

git status --short          5 untracked, 7 deleted, 2 modified
```

**Material change since the last session:** the dirty Operator generated
products that were the leading contamination suspect —
`operator_runtime_frames.tres`, `operator_runtime_manifest.generated.json` and
the four `idle_ready_01` posture PNGs — are **no longer dirty**. Another session
committed them in `0e12e71a3 cleanup operator stuff and some asset things`. No
Operator runtime resource is uncommitted. **Category D (dirty-worktree
contamination) is therefore ruled out for the current tree.**

## 2. Resource consumers

The four suspect smokes all reach the same resource spine:

| Resource | Consumed by |
|---|---|
| `operator_runtime_frames.tres` | all four (via `operator.tscn` sprite frames) |
| `operator_animation_catalog_frames.tres` | `operator_melee_posture`, `operator_visual_ownership` |
| `content/data/operator/generated/operator_weapon_sockets.generated.json` | `operator_primary_ranged_modular_fire`, `operator_ranged_ready_input`, `operator_modular_idle_hitreact` |
| carbine `directional_weapon_textures` (weapon definition `.tres`) | the same three |
| `idle_ready_01` PNGs | `operator_melee_posture` |

## 3. 10-run matrix

Direct invocation (`godot --headless --script`), settled tree:

| Smoke | pass | fail | signatures |
|---|---:|---:|---|
| `operator_vigil_dagger` | 10 | 0 | — |
| `operator_ranged_ready_input` | 10 | 0 | — |
| `operator_primary_ranged_modular_fire` | 10 | 0 | — |
| `operator_modular_idle_hitreact` (before fix) | 0 | 10 | `cleanup should restore modular idle presentation` (single, invariant) |
| `operator_modular_idle_hitreact` (after fix) | 10 | 0 | — |

Harness sweeps (`run_validation.py --tag operator --max-tier actor`), settled
tree, three consecutive runs: **41 selected / 41 passed / 0 failed.**

## 4. Root causes

### 4.1 `operator_modular_idle_hitreact` — deterministic red — **A: proven, fixed by characterization**

Not noise, and not obsolete art. The chain, each step measured:

1. The cleanup case sets `visual_idle_direction` and calls
   `finish_damage_reaction_presentation()`, which defers `_update_animation()`.
2. With a ranged primary equipped, the restored composition runs
   `_sync_modular_ranged_relaxed_upper_layers()` →
   `_sync_modular_ranged_weapon_layer()` → `_apply_frame_aware_primary_weapon_socket()`.
3. That function accepts only
   `OperatorWeaponSocketTracks.REQUIRED_SECTORS = [e, w, se, sw]`. Verified
   directly: `resolve_aim_sector(DOWN) = s (required=false)`,
   `resolve_aim_sector(UP) = n (required=false)`, `e`/`w` required.
4. It keys off `_get_frame_aware_weapon_direction()`, which prefers
   `aim_direction` — **not** `visual_idle_direction`.
5. `aim_direction` is re-resolved from input on the next physics frame.
   Headless input has no mouse position, so aim lands on `(0, -1)` → sector
   `n`, regardless of what the test assigns. Measured:
   `aim=(0.0,-1.0) frame_aware_dir=(0.0,-1.0) sector=n applied=false err=''`
   — the empty error key confirms it refused at the sector gate, not at socket
   lookup, and the `e` directional texture is present.
6. Sector `n` is unsupported, so the composition **correctly** falls back to
   the legacy full body. The assertion demanded a modular restore that the
   live weapon-socket contract cannot produce.

The runtime is behaving correctly; the test precondition was unattainable. The
assertion is now sector-aware: it always guards the one-body invariant, asserts
the modular restore when the resolved sector is supported, and asserts the
documented legacy fallback otherwise. No wait was lengthened and no behaviour
was changed.

**This is a preview of the Slice D defect.** A test cannot pin Operator aim
because `_update_aim()` re-derives it from raw input every physics frame and
falls through to a default mouse position. That is precisely the input-device
aim ownership that Slice D fixes. Once aim is deterministic, the
`if supported / else fallback` branch in this test should collapse to a plain
modular-restore assertion.

### 4.2 `operator_vigil_dagger`, `operator_ranged_ready_input`, `operator_primary_ranged_modular_fire` — **E: environment, not reproducible on a settled tree**

Earlier rates (previous session): 3/3, 1/3 and 2/4 failing respectively, with
signatures like `weapon sprite has no directional texture`, `stance weapon
sprite has no directional texture`, `primary ranged static weapon hidden at
tick 0` — all in the weapon-socket/directional-texture spine of §2.

On the settled tree they are **30/30 green** (10 each, direct) and green across
three full harness sweeps. Attempts to reproduce deliberately all failed:

- rewriting `operator.gd` to invalidate the script cache: 4/4 pass;
- clearing the harness's isolated `HOME=/tmp/custodian-godot-home` Godot cache: 4/4 pass;
- pre-Slice-B and post-Slice-B `operator.gd`, direct runs: 5/5 pass each.

Best-supported explanation: the earlier failures coincided with a window in
which another session was actively rewriting and reimporting exactly those
Operator runtime products, while this session repeatedly swapped `operator.gd`
between HEAD and Slice B for A/B comparison. Concurrent writes to those `.tres`
/`.png` products and to `.godot/imported/` would produce transient
missing-directional-texture reads. Both conditions are now gone.

Worth knowing about the harness, since it shapes how these present: a test is
marked failed if **any** stderr line classifies as fatal, independently of exit
code and of the structured result sentinel (`run_validation.py:205`). So a smoke
that exits 0 and self-reports PASS can still be reported failed on a transient
engine `ERROR:`. That is a deliberate strictness, but it means resource-churn
noise surfaces as test failure rather than as a warning.

**Not claimed:** that these are proven free of a latent race. They are
unreproducible under every condition tried, on a clean tree, 30/30. If they
recur, the first thing to check is concurrent reimport activity.

## 5. Categories

| Smoke | Category | Status |
|---|---|---|
| `operator_modular_idle_hitreact` | A — deterministic, proven | fixed by sector-aware characterization |
| `operator_vigil_dagger` | E — environment/import churn | green, unreproducible |
| `operator_ranged_ready_input` | E — environment/import churn | green, unreproducible |
| `operator_primary_ranged_modular_fire` | E — environment/import churn | green, unreproducible |

No case was category B (test race) or C (generated-resource nondeterminism) on
evidence, and D is ruled out for the current tree.

## 6. Slice C baseline

Slice C must keep all of these green. Run as a set before and after:

```bash
python3 custodian/tools/validation/run_validation.py --tag operator --max-tier actor   # 41/41
python3 custodian/tools/validation/run_validation.py --test operator_visual_ownership
python3 custodian/tools/validation/operator_architecture_debt_audit.py
python3 custodian/tools/validation/operator_runtime_path_audit.py
```

Architecture debt at baseline: **322** violations across 11 rules
(`body_visibility_outside_presentation` retired to 0 in Slice B). Slice C should
retire `animation_resolver` (45), `attack_fallback_animation` (16),
`directional_animation_fallback` (6), `actor_local_spriteframes` (5) and
`operator_animation_catalog` (4), and must also remove the hidden legacy
animation-clock authority marked `MIGRATION DEBT` in
`operator_body_presenter.claim_modular()`.
