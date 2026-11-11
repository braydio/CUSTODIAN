# Isolated Worker Proof V1 — implementation handoff

Workstream: `agent-isolated-worker-proof-v1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34a5d-ca7c-83ea-b267-382f1be560df

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
