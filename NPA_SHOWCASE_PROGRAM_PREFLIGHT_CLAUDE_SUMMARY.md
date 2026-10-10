# NPA Actor Showcase Program — Preflight and Initial Promotion

- Workstream: `npa-showcase-program-preflight`
- Program identity: `npa-actor-showcase`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac98ba2-b390-83e9-9a13-9d4c39b36168

## What this run did

Repository-native authoring, dependency, and dispatcher preflight for the 10
implementation/review pairs published under
`design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md`. Promoted the two
pairs authorized for this pass. Did not implement, claim, or touch any
gameplay/runtime code.

## Baseline / publication SHAs

- Fetched `origin/main` at task start: `cc817de96572...` (session snapshot).
- This workstream's worktree was created from `origin/main` at
  `55905da45588857f4c6847aaba5b506d090a4a3a`.
- Mid-task, `origin/main` advanced to `bc389a4e7` ("npa7 packet publication,
  post-sync gate") while this preflight was running — a concurrent agent
  published the `npa-7-commanded-ally-contracts` / `review-npa-7-commanded-ally-contracts`
  pair as `ready/auto`. That pair is **not yet implemented or archived
  complete**; it is only claimable. This does not change any promotion
  decision in this run — slices 3 (`npa-showcase-existing-drone-hardening`)
  and 6 (`npa-showcase-escort-frame-m7-actor`) remain correctly `draft/manual`
  because NPA-7 has not landed and passed independent review yet.
- This workstream merges forward to whatever `origin/main` is current at
  finish time; see the push/land step for the exact landed SHA.

## Preflight results — all 10 pairs

All 10 implementation packets and their 10 paired reviews were present,
uniquely identified, unclaimed, unarchived, and not superseded on fetched
`origin/main`:

| # | Implementation | Review | Authoring validator |
| - | --- | --- | --- |
| 1 | npa-showcase-arena-foundation | review-npa-showcase-arena-foundation | PASS |
| 2 | npa-showcase-existing-enemy-hardening | review-npa-showcase-existing-enemy-hardening | PASS |
| 3 | npa-showcase-existing-drone-hardening | review-npa-showcase-existing-drone-hardening | PASS |
| 4 | npa-showcase-existing-vaultwing-proof | review-npa-showcase-existing-vaultwing-proof | PASS |
| 5 | npa-showcase-broken-warrant-actor | review-npa-showcase-broken-warrant-actor | PASS |
| 6 | npa-showcase-escort-frame-m7-actor | review-npa-showcase-escort-frame-m7-actor | PASS |
| 7 | npa-showcase-dev-overlays | review-npa-showcase-dev-overlays | PASS |
| 8 | npa-showcase-actor-art-intake | review-npa-showcase-actor-art-intake | PASS |
| 9 | npa-showcase-artwork-completion-audit | review-npa-showcase-artwork-completion-audit | PASS |
| 10 | npa-showcase-complete-arena | review-npa-showcase-complete-arena | PASS |

**10/10 pairs PASS** `validate_task_packet_authoring.py`. 0 FAIL.

## Corrected structural defects

1. **`NPA_SHOWCASE_EXISTING_VAULTWING_PROOF.md` — internally contradictory
   refresh metadata.** Its `## Refresh Planning Authority` block declared
   `Refresh owner: execution-agent` / `ChatGPT/user planning refresh
   required: no`, while its own `## Handoff` block declared `Refresh owner:
   chatgpt-user` / `ChatGPT/user planning refresh required: yes` — a direct
   contradiction inside the same packet. Corrected the `Handoff` block to
   match the authoritative `Refresh Planning Authority` section
   (`execution-agent` / `no`), which also matches the roadmap's own
   characterization of this gate as a mechanical API refresh after
   `review-vaultwing-runtime-hardening` archives, not a human decision. This
   is the only packet of the 10 with this contradiction; all other 9 have
   internally consistent refresh fields.
2. No other mechanical defects found: workstream identities, paired-review
   bindings, dependency identities, lock scoping (no false shared lock
   between any two independent pairs), `Review target packet` archive paths,
   and `Reviewed main` SHAs are all internally and cross-pair consistent.
   Evidence file paths cited as already-existing (e.g.
   `custodian/game/actors/enemies/{enemy_grunt,enemy_marine,enemy_savage}.tscn`,
   `custodian/content/levels/levels.json`,
   `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`) were
   verified to actually exist; validation scripts correctly marked as new
   (e.g. `npa_showcase_arena_foundation_smoke.gd`,
   `npa_showcase_existing_enemy_smoke.gd`) were verified to not yet exist, so
   no existing/to-be-created test claims were misleading.
3. `Reviewed main: 6a5a60ddbf` (76 commits behind `origin/main` at session
   start) was checked for staleness against the two promoted pairs' exact
   work surfaces (`custodian/game/world/levels/authored/dev/`,
   `custodian/content/levels/levels.json`, `custodian/game/actors/enemies/`).
   Zero commits touched either surface in that window, and the claimed "no
   NPA showcase level directory exists yet" state is still true. Not stale
   in a way that changes correctness; left as authored.
4. Did **not** bulk-edit the `Authoring chat` URL across the 20 packets. The
   user supplied a corrected chat URL mid-session
   (`.../c/6ac98ba2-b390-83e9-9a13-9d4c39b36168`) distinct from the one
   recorded in all 20 packets and the roadmap doc
   (`.../c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`). Treated the correction as
   applying to this run's own closing summary/handoff (used above and in
   `Next Handoff` below), not as authorization to overwrite the durable
   per-packet backlink to the conversation that actually authored those 20
   files, which remains `6ac95a34...`. Flagging this for the user: if the
   packets' recorded authoring-chat URL is also wrong, say so explicitly and
   it can be corrected in a follow-up.

## Promoted packets (Pair A + Pair B)

Both pairs' scope was confirmed executable against current main, with no
unresolved design/human-approval gate, accurate dependencies (`none` for
both implementations — confirmed independent, no invented sequential
dependency between them), and no lock conflict (`npa-showcase-level` vs.
`enemy-runtime`, distinct from any other active claim in the dispatch
audit).

| Packet | Before | After |
| --- | --- | --- |
| `NPA_SHOWCASE_ARENA_FOUNDATION.md` | `draft`/`manual` | `ready`/`auto` |
| `REVIEW_NPA_SHOWCASE_ARENA_FOUNDATION.md` | `draft`/`manual` | `ready`/`auto` |
| `NPA_SHOWCASE_EXISTING_ENEMY_HARDENING.md` | `draft`/`manual` | `ready`/`auto` |
| `REVIEW_NPA_SHOWCASE_EXISTING_ENEMY_HARDENING.md` | `draft`/`manual` | `ready`/`auto` |

Both paired reviews are promoted to `ready/auto` alongside their
implementation (per root `AGENTS.md` → Task-Packet Promotion Before
Dispatch), but remain **dependency-gated** — each review's `Depends on` is
its own implementation workstream, which is not yet archived `complete`, so
neither review is claimable yet regardless of its `ready/auto` header.

Targeted authoring validator reruns after promotion: both pairs **PASS**.

## Downstream: 8 pairs intentionally left `draft/manual`

Not promoted in this pass, per explicit instruction:

- **`npa-showcase-existing-drone-hardening`** / its review — gated on the
  real landed + independently reviewed NPA-7 command contracts. Resolved the
  live workstream identities: `npa-7-commanded-ally-contracts` /
  `review-npa-7-commanded-ally-contracts`. As of this run those are
  `ready/auto` (newly published mid-task) but **not implemented or archived
  complete** — so the gate correctly remains open/unresolved. No dependency
  record invented.
- **`npa-showcase-escort-frame-m7-actor`** / its review — same NPA-7 gate as
  above.
- **`npa-showcase-existing-vaultwing-proof`** / its review — gated on
  `review-vaultwing-runtime-hardening`, which the live dispatch audit shows
  as `ready/auto` but itself blocked (`dependency not archived complete:
  vaultwing-runtime-hardening`). Gate confirmed accurate; not promoted.
- **`npa-showcase-broken-warrant-actor`** / its review — declared dependency
  `npa-showcase-existing-enemy-hardening`, which is promoted `ready/auto` in
  this run but not yet archived `complete`. Correctly stays draft; its own
  scope/dependency record is otherwise accurate and needs no refresh beyond
  normal dependency-complete wait.
- **`npa-showcase-dev-overlays`** / its review — depends on
  `npa-showcase-arena-foundation` (promoted, not yet archived complete).
  Correctly stays draft.
- **`npa-showcase-actor-art-intake`** / its review — gated on real original
  art sources and landed Broken Warrant + Escort Frame M-7 presentation
  consumers; genuine external/human input, not available at authoring.
- **`npa-showcase-artwork-completion-audit`** / its review — gated on
  `npa-showcase-actor-art-intake` plus human visual acceptance.
- **`npa-showcase-complete-arena`** / its review — gated on all 8 other
  implementation predecessors archiving complete, especially NPA-7,
  Vaultwing, and real Asset V2 art completion.

None of these were promoted, redesigned, or had their acceptance/dependency
contracts altered beyond the one Vaultwing-proof `Handoff` internal-
consistency fix above.

## Index / repo-wide validation

- `python3 custodian/tools/agent/task_packet_index.py --write` → `task_packet_index: updated`
- `python3 custodian/tools/agent/task_packet_index.py` (no `--write`) → `PASS`
- Managed `Ready / Auto Dispatch` block in
  `custodian/docs/ai_context/task_packets/README.md` now lists
  `NPA_SHOWCASE_ARENA_FOUNDATION.md`, `NPA_SHOWCASE_EXISTING_ENEMY_HARDENING.md`,
  `REVIEW_NPA_SHOWCASE_ARENA_FOUNDATION.md`, and
  `REVIEW_NPA_SHOWCASE_EXISTING_ENEMY_HARDENING.md`, each exactly once; no
  duplicate identities found.
- `python3 custodian/tools/agent/check_ai_context.py --json` → `{"ok": true, "finding_count": 0}`
- `python3 custodian/tools/agent/validate_review_pairing.py` → `PASS (61 Review: auto packet(s) correctly paired)`
- `git diff --check` → clean, no whitespace errors.
- No Godot runtime/gameplay code was touched; no gameplay smoke/validation
  tests were required or run for this metadata-only change.

## Observed concurrent activity (not an incident)

While this preflight ran, a sibling worktree/branch
`agent/npa-showcase-parked-review-pair-contract` appeared (dirty, created
~3 minutes before this workstream, head at the then-current main tip) and
`origin/main` advanced via a separate `npa-7-packet-publication` lineage.
Noted for visibility; it did not touch this workstream's scoped files and
is not treated as a conflict.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: One packet (`NPA_SHOWCASE_EXISTING_VAULTWING_PROOF.md`)
  had self-contradictory `Refresh owner`/`ChatGPT/user planning refresh
  required` values between its `Refresh Planning Authority` and `Handoff`
  sections.
- Root cause / contributing factors: Likely a copy/paste divergence during
  bulk authoring of all 10 pairs from a single publishing pass; the other 9
  pairs are internally consistent.
- Prevention / pipeline improvement: `validate_task_packet_authoring.py`
  does not currently cross-check `Refresh Planning Authority` against
  `Handoff` refresh fields for internal agreement within one packet; a
  cheap addition there would catch this class of drift mechanically next
  time.
- Tooling / docs drift discovered: none beyond the above.
- Follow-up: fixed-in-scope (the one packet corrected in this run).
- What worked: The targeted authoring validator, dispatch audit, and
  managed-index regeneration caught everything structurally needed; manual
  reading was only required to catch the cross-section metadata
  contradiction, which is outside the validator's current scope.

## Next Handoff

- Next workstream: none (program-level preflight; no single-series successor)
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac98ba2-b390-83e9-9a13-9d4c39b36168
- Refresh reason: none
- Next action: A separate agent/session may `dispatch.py claim npa-showcase-arena-foundation --agent <id>` or `claim npa-showcase-existing-enemy-hardening --agent <id>` once verified eligible on landed `origin/main`. This workstream does not claim or implement either.
- Blockers or open questions: Downstream NPA-7, Vaultwing, and art-intake gates remain open as documented above; no action needed from this workstream.
