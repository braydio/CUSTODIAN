# F14-C1 Correction 1 Independent Re-review

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
Workstream: `review-living-world-entity-reification-handoff-review-corrections-1`
Reviewed main: `a2ba651aaad4fb89af0a50fbbf6654181c4376ab`.
Reviewer context: fresh. Reviewer provenance: different-agent, reconstructed from durable authority, packets, receipts and live landed source.

## Findings and verdict

**Passed:** R0-01 fixed, R0-02 fixed, R0-03 fixed. No new blocking defect, material evidence gap or correction finding. No cycle-2 correction is required. This accepts the synthetic one-real-Grunt C1 boundary; production F14-C2/F15 awaits planning.

- R0-01 fixed: `_to_physical` captures and validates both anchor coordinates before scene instantiation, then checks the staged global position before committing authority. Fresh dotted-identity probes reject NaN/Infinity on both axes, preserve complete group/projection and causal history, have zero coordinator children immediately and zero active matching Grunts after a frame. A finite `(64,32)` anchor reifies exactly one actor; the committed A/B handoff smoke also passes.
- R0-02 fixed: original schema-v5/abstract-v1 payload SHA-256 is compared with the incoming fingerprint before deserialization/migration/capture. Fresh valid dotted-ID legacy input restores and retains `D.1.G.1.60`; its new canonical snapshot fingerprint is valid. Corrupted fingerprint and stale-hash payload tampering reject; restored legacy and current snapshots produce equal fingerprints after 120 continuation ticks. Existing v4/current-v5 snapshot smoke passes.
- R0-03 fixed: the committed physical hold is 120 ticks. Independent scratch subclass changes physical records to abstract only during `advance_to_fixed_tick`, then restores the marks, injected before setup and after snapshot restore. The hold starts at tick 133 and ends at 253, reaching eligible macro tick 240; the mutant exits 1 with `abstract movement advanced while the actor was physical`. Normal source passes. No runtime mutation was made in the worktree.
- Parent C1 conserved: actual Grunt, stable IDs and 39/78 health, nondefault supported `harass_player` goal, complete removal before abstract advancement, exactly one event, repeated crossings, abstract restore, duplicate/pending/attack/death/corpse/loot/invalid/failure rejection, and absence of production binding remain proved by source inspection and focused execution. Two separate full supported-goal replay processes reach tick 256 with equal fingerprint `a8858bab4c14571b627c6c8b36b49cd4cfef6d4d8f3f77e67ba9accac2b16c51` and sole causal event `11:F14C_DOMAIN:11:F14C_PATROL:120`.
- Import preflight/editor import and all five required focused smokes PASS. Snapshot smoke's unsupported-schema error is its expected negative path. Review-artifact changed-file validation and finish checks are recorded in the closing summary. No ambient spawner/Enemy owner change or broad sweep was required.

## Parent acceptance and limits

The nine-item parent contract was reconstructed from its archived packet and review, active F14/F15/NPA authority, real Grunt lifecycle, coordinator, state/migration and kernel sources. The five focused smokes prove real scene removal/reentry, identity/health/intent conservation, offscreen advancement/event dedupe, physical suspension, two crossing cycles, abstract snapshot restore and deterministic continuation, negative duplicate/spawn/attack/death/corpse/loot/invalid/failure paths, v4/v5 legacy compatibility and unchanged kernel/macro behavior. Representation changes run at the canonical fixed boundary before the abstract macro stage. No production spawner/camp/procgen owner was edited; no broad spawn sweep or visual capture was warranted.

The committed fixture carries `defend_relay`, which is not a supported goal lookup. The independent full replay used `harass_player`, matching the parent review's durable proof, so a supported nondefault intent was exercised without changing implementation. Legacy event-ID retention is intentional: the first scratch expectation of normalization was corrected; retained IDs, new canonical hashes and continuation all passed. Existing baseline F14 design/current-state prose still predates C1; the accepted receipts provide exact bounded implementation truth for the required production planning refresh.

## Validation

- Import preflight PASS; one fresh editor import initialized Godot classes/resources.
- Authored handoff, abstract activity, kernel, macro-state and snapshot-roundtrip smokes: all PASS. The snapshot smoke emitted its expected unsupported-schema negative diagnostic and exited 0.
- Fresh fault probe PASS: four invalid coordinate cases, unchanged group/projection/events, zero staged/leaked actor; finite anchor accepted; valid legacy dotted event retained; corrupted/stale fingerprints rejected; migrated/current continuation equal.
- Two full supported-goal replay processes PASS: tick 256 fingerprint `a8858bab4c14571b627c6c8b36b49cd4cfef6d4d8f3f77e67ba9accac2b16c51`; sole event `11:F14C_DOMAIN:11:F14C_PATROL:120` in both.
- Ownership-disabled negative control exits 1 at the intended `abstract movement advanced while the actor was physical` assertion. Hold 133→253 includes macro 180 (elapsed 47) and 240 (elapsed 107), so the second boundary exposes the bypass. Later crossing failures are consequences of that intentionally advanced location.
- Scratch reproductions/logs remain outside the worktree in `/tmp/f14c1-r1-review/`. For reproduction, copy the committed smoke, replace goal with `harass_player`, print final canonical fingerprint/events; inject a subclass at initial state and after restore that temporarily marks physical dictionaries abstract while calling the original advance, then restores the marks. No implementation files were mutated.
- Review-artifact `run_validation.py --changed --json`: PASS, 2/2 selected (review pairing and visual handoff), no uncovered files. Managed packet index PASS; `git diff --check` PASS. These artifact checks are distinct from the five runtime smokes and fault/mutation probes above.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Fresh worktree materialization/import took several minutes and produced nine unrelated import sidecars. The first scratch probe incorrectly expected legacy dotted event IDs to be rewritten.
- Root cause / contributing factors: Large LFS checkout and absent Godot import cache; legacy event compatibility deliberately retains accepted dotted IDs.
- Prevention / pipeline improvement: Initialize the editor cache once; remove only classified generated sidecars; assert legacy acceptance, canonical fingerprint and continuation rather than inventing normalization.
- Tooling / docs drift discovered: Existing F14 design/CURRENT_STATE baseline wording predates the narrowly landed C1 proof; production planning must reconcile that wording with the accepted C1 receipt. The committed smoke uses the unrecognized goal defend_relay; this review independently repeats its full flow with supported harass_player as the parent review did.
- Follow-up: manual-follow-up
- What worked: Fresh coordinate/hash probes and independent ownership mutation discriminated all retained findings.

## Next Handoff

- Next workstream: none
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: C1 is accepted after correction; production geographic IDs, semantic region ownership, ambient spawn reconciliation and repeated physical site crossing remain unapproved.
- Next action: Open the exact Authoring chat with workstream review-living-world-entity-reification-handoff-review-corrections-1 and refresh F14-C2/F15 against the accepted C1 source/tests/receipt.
- Blockers or open questions: Production binding is a planning gate; no bounded C1 correction remains.
