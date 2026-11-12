# Baby Opossum Runtime Hardening R1

## Outcome

Implemented the runtime hardening contract in `baby_opossum.gd` and extended
the animation set/runtime smoke to validate arrival, contact, deterministic
selection, transition priority, all-family FPS parity, and alias parity.

The new transition policy keeps soft actions and sensed threats ambient-only.
Attack rejection and explicit flee can preempt active soft sequences, while
duplicate hard reactions cannot continually restart an existing rejection or
flee chain. Treat approach succeeds only on arrival and has a distance/speed
based bounded timeout. Retrieval stores a pending target and carrying begins
only after matching contact. Timeout/cancel clears pending state. Search ties
resolve by distance, world y, world x, then stable node path; `target_found`
emits at the find beat. Empty gift drops no longer emit false success.

Updated the active behavior design and current-state record, corrected the asset
source-of-truth wording to name the requirement registry, and archived the
unreferenced production-wiring task record. All five production-art requirements
remain open and unchanged.

## Validation

- `baby_opossum_runtime_smoke.gd`: passed, including transition/approach/retrieve,
  deterministic search, repeated rejection, family FPS and alias checks.
- `baby_opossum_asset_contract_smoke.py`: passed (22 strips; existing geometry,
  alpha and layer-pairing checks retained).
- The five existing art requirements were queried: each remains `NEEDED`.
- Changed-file validation `/tmp/baby-opossum-validation.json`: passed 10/10,
  complete coverage, zero failed tests.
- `python3 custodian/tools/assets/asset.py needs --check`: passed.
- `git diff --check`: passed.

## Friction and Deferred Work

The first headless run needed a fresh Godot resource import. A test fixture that
passed a freed object to a typed API caused an engine diagnostic before the API
could validate it; the fixture was replaced with null and wrong-class inputs.
The first all-family `needs --json` invocation emits the entire registry rather
than a single requirement; normal human-readable scoped queries were used for
the five required checks. The five source-art re-exports remain explicitly
deferred; no art or Asset V2 pipeline changes were made.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: initial focused smoke needed a cold Godot import; a freed typed-object fixture emitted an engine error and was removed.
- Root cause / contributing factors: fresh worktree lacked Godot class/resource cache; typed method dispatch rejects freed instances before method validation.
- Prevention / pipeline improvement: run one editor import before focused headless scripts in a fresh worktree; use null/wrong-class fixtures for typed API rejection checks.
- Tooling / docs drift discovered: active runtime/current-state text named generated REQUIRED_ASSETS.md as authority; corrected to the registry.
- Follow-up: review-baby-opossum-runtime-hardening-r1
- What worked: focused and changed-file checks passed with complete coverage.

## Next Handoff

- Next workstream: review-baby-opossum-runtime-hardening-r1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: run the paired fresh-context review against the landed implementation.
- Blockers or open questions: none
