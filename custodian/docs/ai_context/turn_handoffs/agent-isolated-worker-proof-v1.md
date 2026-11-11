<!-- V2 turn metadata -->
Task identity: agent-isolated-worker-proof-v1
Task definition: custodian/docs/ai_context/task_packets/AGENT_ISOLATED_WORKER_PROOF_V1.md at origin/main 29ac4c5742c3acaa18c7cec51ab0fd97e4581e81
Remote branch: agent/agent-isolated-worker-proof-v1
Acquisition mode: normal
Acquisition source: origin/main (no prior branch; fresh start)
Acquisition source commit: 926df15195f7c0e98adfca597adcae8c00637219
Checkpoint base: 426eb20698bcdf082b989f474da39cf8d8cbd593
<!-- /V2 turn metadata -->

# Isolated Worker Proof V1 — implementation handoff

Workstream: `agent-isolated-worker-proof-v1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34a5d-ca7c-83ea-b267-382f1be560df

## V2 turn handoff

Original goal: Prove a disposable local CUSTODIAN worker can run in a dedicated unprivileged systemd sandbox without inheriting operator credentials, Chrome DevTools access, or privileged host interfaces.

Implemented: Preserved the existing active V2 acquisition and checkout, restored coordinator Git fetch by removing only 16 verified empty malformed remote-tracking files, added the bounded anonymous Git LFS batch/action GET probe with redacted evidence, and prepared encrypted systemd credential delivery plus an explicit credential-gated model-only probe. The preparation uses no live credential and makes no API request.

Remaining: The historical loopback anomaly remains unexplained. A dedicated OpenAI Platform project service account and its bounded key must be provisioned by an administrator, encrypted to `/etc/credstore.encrypted/custodian-worker-openai-api-key`, then installed and exercised through the model-only service mode. No live credential or model response is available. The original packet remains incomplete and must not be archived or marked PASS.

Validation: Credential-free preparation has 28 passing worker-isolation unit tests, Python compilation, `systemd-analyze verify`, shell syntax, `systemd-analyze security --offline` (exposure 2.2), `git diff --check`, and canonical changed-file validation against `origin/main` with complete coverage. The earlier actual LFS-only service run `a58315580085c773` passed launcher preflight, anonymous batch, exact object GET, size and SHA-256 verification; the service is inactive and disabled afterward. No updated unit was installed or started during this continuation.

Resume: Continue `agent-isolated-worker-proof-v1` in the existing V2 checkout `/home/braydenchaffee/Projects/.custodian-turns/turn-agent-isolated-worker-proof-v1-6b456941ad5b` using acquisition `6b456941ad5b46db8fc327307e2d9d3a`. Preserve the existing checkout and its 19 ignored Python cache files in six `__pycache__` directories; do not create a second checkout or clean the caches. The latest landed main is `cd3c297c4a5b104785751c855387dceecdd912dd`. Both checkpoint histories have been preserved by a normal merge; the supported V2 checkpoint with `--keep` publishes this continuation while retaining the active checkout. Verify the remote branch SHA against the checkpoint receipt before continuing. Wait for external administrator provisioning before any model-only run.

Sources/evidence: `custodian/docs/operations/worker-isolation-proof.md`; `custodian/docs/operations/evidence/worker-isolation-lfs-batch-diagnostic-20261111.json`; private maintenance evidence at `/home/braydenchaffee/.local/state/custodian/maintenance/legacy-quarantine-batch-20261111T190900Z`; task packet `custodian/docs/ai_context/task_packets/AGENT_ISOLATED_WORKER_PROOF_V1.md`.

## 2026-11-11 continuation — credential-free model preparation

Added an ID-only systemd encrypted-credential entry named `custodian-worker-openai-api-key`, sourced from `/etc/credstore.encrypted/custodian-worker-openai-api-key`, to the test-only unit. This systemd lookup is optional when the encrypted credential is absent, allowing non-model service modes to start. The provisioner accepts a root-owned credential-store directory that is not group/world writable, preserves existing secure modes such as `0700` or `0755`, and creates a missing store as `0700`. It validates any encrypted file as regular, singly linked, root-owned `0600` using metadata only, and preserves the credential store and file on removal. The launcher forwards `CREDENTIALS_DIRECTORY` only in model-only mode; ordinary full and LFS modes do not require it. The validator rejects missing, empty, malformed, symlinked, wrong-owner, and wrong-mode runtime delivery; it checks inherited credential variable names and refuses them. The explicit host `--model-only` mode runs only after the actual launcher network preflight, with a temporary `CODEX_HOME`, ignored user config, no MCP servers, apps, remote plugins, shell, or subagents, and child-environment inheritance set to none. The key value is included only in the Codex child environment; output, stderr, args, journals, and reports do not include it. The prompt is a one-line harmless marker request with a 60-second timeout. General full-proof and LFS modes never attempt a model call.

No live credential existed and none was read, created, or copied. The service was not upgraded or run; no model request occurred. A Platform administrator must create a dedicated project service account with minimum Responses inference permission, seven-day key expiry, a small monitored project budget, and independent revocation, then use `systemd-creds` to encrypt the key into `/etc/credstore.encrypted/custodian-worker-openai-api-key`. The encrypted source path is non-secret; never paste the key into chat or repository files. Platform service-account guidance: https://developers.openai.com/api/docs/guides/api-keys

The original loopback finding remains unresolved and full acceptance remains false. The implementation packet stays active/incomplete. Canonical changed-file validation passed for this prep. This turn is published through the supported V2 checkpoint; normal branch CI remains a separate check.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34a5d-ca7c-83ea-b267-382f1be560df

## 2026-11-11 continuation — optional credential delivery correction

The orchestrator's PR #143 review identified that an absolute `LoadCredentialEncrypted=ID:PATH` source fails unit startup when the key file is absent, and the launcher also rejected non-model runs without `CREDENTIALS_DIRECTORY`. Corrected the unit to use the systemd-supported ID-only optional lookup in `/etc/credstore.encrypted`, and restricted launcher credential-directory validation/forwarding to model-only. Added regression coverage for missing credentials in ordinary and LFS modes while retaining model-only fail-closed behavior. No credential was provisioned, no service was installed or started, and no model request occurred.

Current orchestration chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af4a80a-6f54-83e9-82a0-8222279dfc86

## 2026-11-11 continuation — preserve secure credential store modes

Host preparation found `/etc/credstore.encrypted` root-owned mode `0700`, with the named encrypted file absent. The service was inactive and disabled, with no drop-ins or worker timer. The landed provisioner required exactly `0755`, which would reject this more restrictive shared-store mode. The correction accepts correctly owned real directories when group/world write bits are clear, preserves existing modes, and creates a missing store as `0700`. Tests cover accepted `0700`/`0755`, rejection of group/world-writable directories and symlinks, and preservation. No credential content was accessed or modified, and no host upgrade has yet run.

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


## 2026-11-11 continuation — host credential-free preflight

PR #144 landed at `29ac4c5742c3acaa18c7cec51ab0fd97e4581e81` after all required CI passed. The retained checkout fast-forwarded safely to that exact main SHA, preserving six ignored Python cache directories. The guarded host upgrade used `--from-ref c78823ece3dc273a138acc42c087a4731dc4dd68` plus one exact validator hash override (`e9bec1de965c9513320c87f48a7eaa80756c6fb43c36c39b2796a34c5d65ad5e`), because the installed validator independently matched prior source `f93adb045a3de8ccf1dbc37f98c1841e7d4192de`; all other managed files matched the specified baseline. Upgrade succeeded with the service inactive/disabled. The root-owned `/etc/credstore.encrypted` remained mode `0700`; the named credential was confirmed absent by metadata only.

Actual credential-free preflight run `2665577433a2ba36` exited 0 and reported `diagnostic_pass=true`, `full_proof_pass=false`. Host positive controls succeeded for Chrome CDP and all four test listeners. The in-service process ran as UID 942 (`custodian-worker`) in the expected service cgroup, recorded `pass=true`, and blocked all five destinations (CDP IPv4 loopback, alternate IPv4 loopback, IPv6 loopback, and two RFC1918 LAN interfaces); each listener saw zero worker connections. The unit returned inactive and remains disabled, with no worker timer. Original report is preserved privately at `/home/braydenchaffee/.local/state/custodian/maintenance/worker-proof-evidence-20261111/preflight-original-2665577433a2ba36.json` (SHA-256 `b6b49c1ce428cfc01ffc62516c03a049d282a4ac03e0f544662b0b6319199493`). Its sanitized public representation is `custodian/docs/operations/evidence/worker-isolation-preflight-correction-20261111.json` (SHA-256 `48038e998dea0b5d54b7a85d34082418fccd95f5c893b73d90f0a6facd8243eb`); run identity, status, timings, UID, and cgroup are preserved while private destinations are symbolic. Previously published Git history retains the original bytes and has not been rewritten. The report includes the systemd credential property only as `[unprintable]`; no credential contents were read, created, or modified. Full worker acceptance remains incomplete pending model credential/model-only proof and resolution of the historical loopback anomaly.

## 2026-11-11 continuation — public evidence sanitization and readiness review

The original run JSON is preserved privately at `/home/braydenchaffee/.local/state/custodian/maintenance/worker-proof-evidence-20261111/preflight-original-2665577433a2ba36.json` with its original SHA-256. The public JSON replaces only private LAN destination literals with `<PRIVATE_LAN_IPV4_0>` and `<PRIVATE_LAN_IPV4_1>`; run ID, probe results, timings, UID, cgroup, and enforcement properties remain unchanged. New public SHA-256 is `48038e998dea0b5d54b7a85d34082418fccd95f5c893b73d90f0a6facd8243eb`. A focused offline sanitizer and regression tests reject non-symbolic private destinations in public worker-proof reports. Previously published Git history retains the original bytes; no history rewrite was performed.

Historical anomaly classification: **root cause unknown, current enforcement independently demonstrated**. Original run `0b9d19b84e5789e0` records worker UID/GID 942 and the expected cgroup, but reports successful CDP/IPv4/IPv6 loopback connections despite its captured deny policy listing IPv4 and IPv6 loopback. The host-side listener counters and later diagnostics do not establish how those connects succeeded. Current run `2665577433a2ba36` with the same UID/cgroup blocked the five positive-controlled targets; that establishes current enforcement only. No expensive full-toolchain rerun was performed.

Read-only model-auth readiness: installed validator source SHA-256 `2c26887dee394cf83d919d2d96a54fe27b284446014f7e8881f389c8e99f9eac` matches landed main. The unit's ID-only encrypted credential uses `custodian-worker-openai-api-key`; model-only expects systemd `$CREDENTIALS_DIRECTORY` delivery and validates a service-owned regular singly linked mode `0400` file, bounded size, and key format. Only model-only validates/forwards that directory. The Codex child gets the key only in its own environment, a fresh temporary worker-owned `CODEX_HOME`, no inherited owner auth/MCP/browser/SSH/GitHub credentials, empty MCP config, disabled apps/plugins/shell/subagents, read-only sandbox, and a 60-second timeout; it must return exactly `WORKER_MODEL_OK`. The encrypted source is absent. This is ready for administrator provisioning review, not for executing a probe. No key access or model request occurred.
