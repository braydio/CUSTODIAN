<!-- V2 turn metadata -->
Task identity: agent-isolated-worker-proof-v1
Task definition: custodian/docs/ai_context/task_packets/AGENT_ISOLATED_WORKER_PROOF_V1.md at origin/main 82e1a81125c803fa5c9a0fcb1ffc4ef9574d4526
Remote branch: agent/agent-isolated-worker-proof-v1
Acquisition mode: normal
Acquisition source: origin/main (no prior branch; fresh start)
Acquisition source commit: 926df15195f7c0e98adfca597adcae8c00637219
Checkpoint base: 82e1a81125c803fa5c9a0fcb1ffc4ef9574d4526
<!-- /V2 turn metadata -->

# Isolated Worker Proof V1 — implementation handoff

Workstream: `agent-isolated-worker-proof-v1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34a5d-ca7c-83ea-b267-382f1be560df

## V2 turn handoff

Original goal: Prove a disposable local CUSTODIAN worker can run in a dedicated unprivileged systemd sandbox without inheriting operator credentials, Chrome DevTools access, or privileged host interfaces.

Implemented: Preserved the existing active V2 acquisition and checkout, restored coordinator Git fetch by removing only 16 verified empty malformed remote-tracking files, and added a bounded anonymous Git LFS batch/action GET probe with redacted evidence and guarded service-file upgrade support.

Remaining: The historical loopback anomaly remains unexplained. A worker-owned isolated Codex/model identity and actual model execution are still unavailable. The original packet remains incomplete and must not be archived or marked PASS.

Validation: 19 worker-isolation unit tests pass; Python compilation, systemd unit verification, shell syntax, `git diff --check`, and canonical `run_validation.py --changed --base origin/main --json` pass. Actual LFS-only service run `a58315580085c773` passed launcher preflight, anonymous batch, exact object GET, size and SHA-256 verification; the service is inactive and disabled afterward.

Resume: Continue `agent-isolated-worker-proof-v1` in the existing V2 checkout `/home/braydenchaffee/Projects/.custodian-turns/turn-agent-isolated-worker-proof-v1-6b456941ad5b` using acquisition `6b456941ad5b46db8fc327307e2d9d3a`. Keep the 16 inventoried ignored Python caches and attached worktree; do not create a second checkout. Next resolve the historical loopback anomaly and obtain an independently authorized isolated model credential before any full proof.

Sources/evidence: `custodian/docs/operations/worker-isolation-proof.md`; `custodian/docs/operations/evidence/worker-isolation-lfs-batch-diagnostic-20261111.json`; private maintenance evidence at `/home/braydenchaffee/.local/state/custodian/maintenance/legacy-quarantine-batch-20261111T190900Z`; task packet `custodian/docs/ai_context/task_packets/AGENT_ISOLATED_WORKER_PROOF_V1.md`.

## Source commit

- Implementation commit: `c78823ece3dc273a138acc42c087a4731dc4dd68`
- Remote branch: `origin/agent/agent-isolated-worker-proof-v1` (verified at the same SHA)
- Packet acceptance was not weakened. This is a landed implementation/evidence milestone, not full worker isolation acceptance.

## Acceptance truth

- Dedicated worker account and test-only disabled systemd unit: provisioned; service is inactive and disabled after tests; no timer was installed.
- Launcher-boundary denial gate: checks service identity, cgroup, effective address-deny policy, and loopback/LAN destinations before any workload; successful connections fail closed with exit 79.
- Repeated focused host test: three actual-unit starts passed five host-positive-controlled destinations each. This does not explain the original full-run loopback anomaly or establish broader sustained isolation.
- Original loopback anomaly: unresolved; original report retained unchanged.
- Anonymous Git LFS retrieval: not proven; the bounded request timed out. No authentication outcome is inferred.
- Isolated Codex/model execution: not proven; a separate worker identity is unavailable. No owner credential was copied.
- Full autonomous-worker acceptance: incomplete. Do not archive as complete or claim PASS.

## Validation

- `python3 -m unittest tools.worker.test_worker_isolation -v`: 13 passed.
- Python compilation, shell syntax, `systemd-analyze verify`, and `systemd-analyze security`: passed.
- `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`: passed; complete changed-file coverage, including manifest self-checks.
- `git diff --cached --check` and `git diff --check`: passed before commit.
- Evidence SHA-256:
  - Original full run: `dc6a677b704e92408d23b4e4083ae6a45f9498c2c2bb11372f8e1f621bf97e59`
  - Three-run loopback preflight: `bc278d38ed335b77f9205d4a41c93cd1c82258e7346a5dfe4c749c92522cd04b`
  - Bounded LFS diagnostic: `4a0870dfd32e94d99da3aaf2ee540a5c2fa541b49a744c944fb80d3dfa1f0482`

The three reports are committed under `custodian/docs/operations/evidence/`; the operational details and exact remaining gates are in `custodian/docs/operations/worker-isolation-proof.md`.

## Lifecycle and next action

The implementation packet remains active/incomplete because its completion contract requires the unresolved LFS and model gates and full runtime proof. The paired review packet targets the archived implementation packet and is dependency-gated until the implementation is completed and archived. Do not force archival or claim the review early. After a future authorized proof completion, run the fresh-context paired review through Dispatcher V2.

The persistent project-root checkout was not modified. It is divergent from `origin/main`, so safe fast-forward synchronization is pending. The test service remains inactive and disabled.

## 2026-11-11 continuation — direct anonymous LFS proof

The malformed empty origin-tracking refs were removed in one guarded operation from the coordinator. All 16 corresponding local and remote quarantine authority commits/records were preserved; the agent branches, dispatch claims, packed refs, and 38 worktrees were unchanged. Git fetch recovered at `origin/main` `82e1a81125c803fa5c9a0fcb1ffc4ef9574d4526`.

The existing V2 acquisition `6b456941ad5b46db8fc327307e2d9d3a` remains unretired. Its exact checkout is `/home/braydenchaffee/Projects/.custodian-turns/turn-agent-isolated-worker-proof-v1-6b456941ad5b`, attached to the coordinator common Git directory. The canonical branch was clean and fast-forwarded to `82e1a81125c803fa5c9a0fcb1ffc4ef9574d4526`; the checkout's ignored Python caches were inventoried privately and preserved. A second resume checkout was not created.

The LFS diagnostic now sends an unauthenticated batch request directly, keeps the signed download action and its headers in memory, restricts the action host, records only safe stage timings/statuses, and verifies the exact public object. Final actual `custodian-worker@proof.service` run `a58315580085c773` used installed validator SHA-256 `e9bec1de965c9513320c87f48a7eaa80756c6fb43c36c39b2796a34c5d65ad5e`: launcher preflight PASS; batch DNS/TCP/TLS 1.3 and HTTP 200 PASS; `github-cloud.githubusercontent.com` DNS/TCP/TLS 1.3 and exact GET HTTP 200 PASS; payload 4,852 bytes and SHA-256 `f14d37604bbce8b31671550e7c0a3cd5168d5e4273e8c67b95e301c392761c51` PASS. The unit returned inactive and remains disabled. Durable redacted evidence is `custodian/docs/operations/evidence/worker-isolation-lfs-batch-diagnostic-20261111.json` (SHA-256 `e386625de039f8128b29a7934510c2a5f95291b37402309020da18362e327173`). The raw private host run remains in the mode-0700 maintenance evidence directory; no signed URL or action header was persisted.

Focused validation now has 19 passing worker-isolation unit tests, Python compilation, systemd unit verification, shell syntax, changed-file validation, and `git diff --check`. Full acceptance remains incomplete: the historical loopback anomaly is unexplained and isolated Codex/model execution is still unavailable. No full proof PASS is claimed.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34a5d-ca7c-83ea-b267-382f1be560df
