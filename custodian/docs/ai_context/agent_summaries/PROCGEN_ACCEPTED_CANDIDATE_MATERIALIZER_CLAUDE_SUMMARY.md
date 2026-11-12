# PROCGEN Accepted Candidate Materializer

Implemented G4's accepted semantic candidate handoff. `CustodianContractMap`
now retains the selected candidate record rather than its live evaluation map,
disposes evaluation maps after measurement, and constructs a fresh final map
with the accepted seed, ProcGen settings, world profile, and runtime settings.
`ProcgenCandidateMaterializer` validates the handoff and asks
`ProcGenTilemap` to realize the final runtime once. The final map checks its
semantic fingerprint against the accepted snapshot and records phase order,
timings, structural/runtime invocation counts, S1 runtime fingerprint, and
floor/wall counts. S1 diagnostics and benchmark output expose this report.

## Evidence

- Candidate materializer parity smoke passed. It verified accepted floor/wall
  positions, terrain data, ocean/chasm semantics, semantic fingerprint, and
  equal final S1 runtime fingerprints across two independently generated
  fresh maps. Both maps recorded one structural realization and one runtime
  invocation.
- S1 quick passed with `determinism_ok: true`; repeated 48x48 seed-420777
  generation fingerprints were `1773840677`. Its accepted contract output had
  final runtime fingerprint `2884730602`.
- S1 full passed with `determinism_ok: true`. All nine 160x160, 192x192, and
  224x224 fixed-seed generation cases emitted stable fingerprints and required
  floor/wall counts. The three contract winners accepted attempt 0/12 and
  materialized once:
  - seed 420777: fingerprint `2884730602`, 10212 floors, 951 walls, 39837 ms;
  - seed 420779: fingerprint `392435093`, 10372 floors, 805 walls, 51489 ms;
  - seed 771923: fingerprint `1672459047`, 6317 floors, 1058 walls, 20333 ms.
- Full runtime case (192x192, seed 420777): 7.006 ms average across 60 samples,
  25 chunks revealed, queue peak 362.
- Candidate evaluator, semantic model, spatial normalization, terrain
  required cells, road semantics v2, world ingress spawner, S1 quick, and the
  materializer parity smoke passed. Final changed-file closeout passed all
  19/19 selected tests with complete ownership coverage and no timeouts. The
  ambient real-world spawn case passed in 106.6 seconds after its timeout was
  raised from 90 to 180 seconds. `git diff --check` passed.

## Friction and Deferred Work

The ambient-spawn timeout was repeatable: the old budget expired during the
new final realization before the smoke reached its post-generation assertions.
The 180-second budget is limited to that integration test. Changed-file
coverage also flagged the new materializer/parity smoke as unowned; the parity
smoke was registered and the full 19-test coverage-complete sweep passed. The
promotion smoke also carried a stale assumption that
separate maps must have the same streamed-paint count; fresh final maps begin
with independent reveal progress, so the check now enforces authoritative
floor bounds and streaming expansion instead.

The first materializer smoke run exposed that the final map did not inherit
evaluation-fixture presentation settings; capturing and applying those
settings fixed the mismatch. A pre-hydration validation preflight timed out
during Godot import. LFS objects were already cached locally, were checked out
without fetching, and generated tracked `.import` sidecars were restored.
Normal Godot exit leak warnings and deterministic stuck-pocket cleanup
warnings appeared in some passing checks. They were not changed by this task.

Legacy in-place promotion compatibility code remains for the declared G5
cleanup packet. Full S1 wall-clock times vary significantly by map size and
host load; the benchmark remains threshold-free. No full-resolution visual
capture was needed because acceptance was structural and fingerprint-based.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The ambient real-world spawn timeout was too short after adding fresh final realization; a streamed-paint equality assertion compared independent maps; the new parity smoke lacked manifest ownership.
- Root cause / contributing factors: The timeout budget predated the extra final generation, the smoke retained an in-place promotion assumption, and the new test had no owner mapping.
- Prevention / pipeline improvement: Raised the affected test timeout to 180 seconds, registered the parity smoke, and replaced cross-map paint equality with authoritative floor-bound and streaming-progress checks. The final changed-file run passed 19/19 with complete coverage.
- Tooling / docs drift discovered: The validation timeout did not account for both candidate evaluation and accepted materialization; changed-file coverage caught the missing parity-smoke owner entry.
- Follow-up: fixed-in-scope
- What worked: Accepted semantic and S1 runtime fingerprints remained deterministic.
