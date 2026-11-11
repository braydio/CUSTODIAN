# Disposable CUSTODIAN Worker Isolation Proof V1

This is a test-only local host integration. It does not migrate Dispatcher V2, start a recurring worker, or install a publisher/broker. The systemd template is manually started for one bounded proof invocation and remains disabled afterward.

The exact acceptance contract and paired-review route are in `custodian/docs/ai_context/task_packets/AGENT_ISOLATED_WORKER_PROOF_V1.md`. The owning authoring conversation is:

`https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34a5d-ca7c-83ea-b267-382f1be560df`

## Files and host boundary

- `deploy/systemd/custodian-worker@.service` runs as the dedicated `custodian-worker` identity, with no capabilities or supplementary groups, a private `/tmp` and device view, protected system/home paths, and IPv4/IPv6 loopback, link-local, RFC1918, CGNAT and IPv6 ULA denial.
- `tools/worker/custodian-worker-launch` accepts only the fixed `proof` instance, requires the effective systemd identity and address-deny policy, then probes every configured loopback and host-LAN test listener from its own service cgroup before it can execute any validator, Git, Codex or other network workload. Any successful connection stops launch with exit code `79`. The launcher records destination, timestamp, timeout, elapsed time, PID, UID, cgroup, effective unit properties and host positive controls. On a passing preflight it replaces the service environment with a small constant set.
- `tools/worker/provision_worker_isolation.sh install` installs only the exact unit and helper files, creates the non-login account and worker-owned directories, configures public DNS for this service, and leaves the unit disabled and inactive. It refuses conflicting files, directories, account attributes, or an enabled/active unit.
- `tools/worker/validate_worker_isolation.py --host-run --preflight-only` starts host-side listeners on a second IPv4 loopback, IPv6 loopback, and available RFC1918 host interfaces. It verifies the Chrome CDP endpoint and every test listener from the host before starting the unit, then checks the exact in-service preflight record. The listener ports, effective systemd properties and run identifier are supplied through a root-owned temporary file; the service can read but not modify it.
- `tools/worker/validate_worker_isolation.py --host-run --lfs-only` runs only the bounded anonymous LFS diagnostic after the same startup gate. It does not launch the toolchain or Codex model call. DNS (5 seconds), TCP (5 seconds), TLS (5 seconds), HTTP (8 seconds), clone (12 seconds), local pointer read (3 seconds) and Git LFS transfer (20 seconds) have separate results, for a 58-second maximum phase budget.
- `tools/worker/provision_worker_isolation.sh remove --remove-state` is deliberately explicit. It refuses active/enabled instances, unexpected managed-file contents, or unrecognized worker state. It removes only the dedicated service files, resolver config, worker account/group, and worker-owned proof state.

The service receives public DNS servers `1.1.1.1` and `2606:4700:4700::1111` through its own read-only resolver file. It does not use the host's Tailscale resolver or inherit DNS configuration from the operator environment. Network egress remains available to public development endpoints; private/LAN destinations are denied. The proof does not claim general egress filtering or production readiness.

The worker's `HOME` and `CODEX_HOME` are under `/var/lib/custodian-worker`; the host `/home`, `/root`, `/run/user`, Docker, D-Bus, systemd-control, and Tailscale sockets are hidden or inaccessible. Git uses no system/global Git config, no interactive prompt, no inherited SSH agent, and skips LFS smudge on clone. The single LFS probe explicitly fetches one small public object with no credentials configured. If anonymous LFS access is denied, do not add an owner credential or broaden GitHub permissions to make the proof pass.

Codex is invoked only through the explicit `--model-only` host mode, after the same in-service isolation preflight. The unit uses the ID-only `LoadCredentialEncrypted=custodian-worker-openai-api-key` form, which searches systemd's encrypted credential store and permits the credential to be absent. The launcher passes `CREDENTIALS_DIRECTORY` only in model-only mode; the validator checks the runtime file's owner, mode, type, size, and format, then adds `OPENAI_API_KEY` only to the Codex child environment. The value is never placed in argv, logs, reports, a persistent Codex home, or another validator/tool process. Codex runs with a fresh temporary `CODEX_HOME`, `--ignore-user-config`, no MCP servers, and apps, remote plugins, shell, and subagents disabled. Shell child environment inheritance is explicitly `none`; `/etc/codex` is inaccessible in the unit. The harmless prompt requests only `WORKER_MODEL_OK`, runs once with a 60-second timeout, and reports only a verified response marker and safe status fields. Model-only fails closed when runtime credential delivery is missing or invalid. General proof and LFS modes do not require or receive the runtime credential pointer. Any later publisher socket must authenticate `SO_PEERCRED` and authorize an explicit workstream, action, ref, and current generation before publishing.

### Separate worker model credential

The administrator-managed encrypted source is `/etc/credstore.encrypted/custodian-worker-openai-api-key`; its directory must be root-owned and not writable by group or world. Existing secure modes such as `0700` and `0755` are accepted and preserved; when the provisioner creates a missing directory, it uses `0700`. The encrypted file must be root-owned mode `0600`. Installation creates/verifies the store directory but never writes, reads, rotates, or removes the credential. Removal preserves the shared credential store and encrypted file. The source must be created by an administrator outside the worker and repository. Run `sudo sh -c 'umask 077; exec systemd-creds --with-key=host --name=custodian-worker-openai-api-key encrypt - /etc/credstore.encrypted/custodian-worker-openai-api-key'`, with the API key supplied on stdin by an approved non-echoing secret manager or secure provisioning interface; never put the key in a shell command, environment file, terminal history, or chat. The encrypted file can be checked with `stat` without decrypting or printing it. Systemd exposes the decrypted, read-only credential only under `$CREDENTIALS_DIRECTORY/custodian-worker-openai-api-key` when available. Because the unit uses the ID-only lookup form, an absent file does not prevent the ordinary full-proof, preflight-only, or LFS-only service modes from starting; model-only still requires successful runtime delivery.

Create a separate OpenAI Platform project service account for this workload, not a personal project key. Recommended initial controls are the narrowest Responses permission needed for inference (`api.responses.write`), seven-day key expiry, and a small project budget with usage alerts. Budgets and alerts are monitoring controls, not guaranteed hard spending cutoffs. Revoke the service-account key independently after the proof. Do not create or install a key through the Codex local `.env` setup flow. The API key must be generated and delivered by an administrator; the repository has no credential and no code path reads owner Codex authentication.

After the encrypted credential is provisioned and the current implementation is safely installed, the one-shot model-only proof command is:

```bash
sudo python3 tools/worker/validate_worker_isolation.py --host-run --model-only
```

The proof service remains disabled and inactive after the invocation. No model call is made by the ordinary full-proof, preflight-only, or LFS-only modes.

## Install and run

From a clean claimed implementation checkout:

```bash
systemd-analyze verify deploy/systemd/custodian-worker@.service
python3 -m unittest tools.worker.test_worker_isolation -v
python3 -m py_compile tools/worker/worker_launcher.py tools/worker/provision_worker_isolation.py tools/worker/validate_worker_isolation.py
bash -n tools/worker/provision_worker_isolation.sh
sudo tools/worker/provision_worker_isolation.sh install
systemd-analyze security custodian-worker@proof.service --no-pager
sudo python3 tools/worker/validate_worker_isolation.py --host-run
```

To upgrade an existing installation, use `sudo python3 tools/worker/provision_worker_isolation.py upgrade --from-ref <exact-installed-baseline>`. It refuses unless every installed managed file matches that Git baseline, the resolver config matches, and the service is inactive and disabled. For a previously installed, explicitly verified dirty file, `--installed-sha256 SOURCE=SHA256` can replace that one baseline comparison; use only a SHA-256 recorded from the exact installed file. The upgrade stages files beside their destinations and atomically replaces them after all baseline checks pass. It never changes worker state or account settings.

The full host-run command emits one JSON record. Exit code `0` means every full-proof gate passed. Exit code `2` means evidence was collected but at least one required gate is incomplete. Exit code `1` means the host runner itself could not safely set up or collect the proof. Diagnostic-only modes deliberately set `full_proof_pass` to false. Their exit code `0` means the requested focused diagnostic completed, not that full acceptance passed. Reports omit environment values and command stderr. Redact host-interface addresses before retaining evidence in Git.

The systemd service must remain disabled and no timer may be installed. The proof unit exits after one run and does not restart. Do not run `systemctl enable` or create a timer.

To remove the installation after preserving required evidence:

```bash
sudo tools/worker/provision_worker_isolation.sh remove --remove-state
```

If cleanup refuses, preserve the remaining state and inspect the exact reported path before taking any separate cleanup action.

## Proof record

Implementation source: `agent/agent-isolated-worker-proof-v1` (claimed from packet SHA `a16fb3ece74f90358dac36d1b981348efeaba412`).

Host provisioned: yes; exact dedicated account, disabled unit and worker-owned state only.

Original full host run: [worker-isolation-run-0b9d19b84e5789e0.json](evidence/worker-isolation-run-0b9d19b84e5789e0.json), immutable. The validator returned exit code 2. Identity, environment, protected paths/sockets, DNS, public HTTPS, tool versions and Git read passed. All three loopback attempts unexpectedly connected; anonymous LFS fetch timed out after 300 seconds; Codex model execution was unavailable because no separate worker credential exists. Service was disabled and inactive after collection.

The exact cause of the first run's loopback pass-through has not been established. The installed template and launcher matched the claimed sources, had no drop-ins, showed the expected `IPAddressDeny` and empty `IPAddressAllow`, and ran the validator in the service cgroup. Later diagnostics passed but did not explain the original result. The correction therefore adds an actual launcher-boundary fail-closed preflight; it does not claim that the historical discrepancy is explained.

Three repeated actual-unit, preflight-only runs passed after correction: five destinations each (CDP, second IPv4 loopback, IPv6 loopback, and two RFC1918 host interfaces). Host positive controls connected to all listeners first; no worker connection was accepted. Each run returned successfully, then the unit was inactive and disabled with no timer. See [worker-isolation-loopback-preflight-final-20261111.json](evidence/worker-isolation-loopback-preflight-final-20261111.json) (SHA-256 `bc278d38ed335b77f9205d4a41c93cd1c82258e7346a5dfe4c749c92522cd04b`). RFC1918 host addresses are redacted in durable evidence.

The bounded LFS-only run passed the isolation preflight and public DNS/TCP/TLS/HTTPS checks (GitHub returned HTTP 200 with TLS 1.3), then the Git LFS fetch timed out after 20.0205 seconds (bounded 58-second maximum total path). Authentication and the Git LFS endpoint HTTP response were not observed before timeout; this remains `network_timeout`, not an inferred authentication failure. See [worker-isolation-lfs-diagnostic-20261111.json](evidence/worker-isolation-lfs-diagnostic-20261111.json) (SHA-256 `4a0870dfd32e94d99da3aaf2ee540a5c2fa541b49a744c944fb80d3dfa1f0482`). The incomplete clone created for that one run was removed after preserving evidence.

Final bounded LFS-only run `a58315580085c773` used installed validator SHA-256 `e9bec1de965c9513320c87f48a7eaa80756c6fb43c36c39b2796a34c5d65ad5e`. The actual `custodian-worker@proof.service` launcher preflight passed; the anonymous Git LFS batch POST to `github.com` returned HTTP 200 after DNS, TCP, and TLS 1.3 passed. The in-memory download action was limited to `github-cloud.githubusercontent.com`; that host also passed DNS, TCP, and TLS 1.3, and the exact object GET returned HTTP 200. The 4,852-byte payload matched SHA-256 `f14d37604bbce8b31671550e7c0a3cd5168d5e4273e8c67b95e301c392761c51`. The report contains stage timings and statuses only; it omits the action URL, query, and action headers. The unit returned inactive and remained disabled. This proves the bounded anonymous LFS object path, but does not resolve the historical loopback discrepancy or satisfy isolated model execution. See [worker-isolation-lfs-batch-diagnostic-20261111.json](evidence/worker-isolation-lfs-batch-diagnostic-20261111.json) (SHA-256 `e386625de039f8128b29a7934510c2a5f95291b37402309020da18362e327173`).

Codex model execution remains unavailable until an independently authorized worker identity is provisioned. No owner credential was copied. Full proof remains incomplete and must not be certified.

Credential-free model preparation adds the encrypted systemd credential hook and an explicit one-shot model-only diagnostic. Synthetic test-only credentials exercise refusal and environment isolation; they are never sent to the API. The live credential source does not exist on this host, so the service upgrade and in-service model request were intentionally not run. Full proof remains false, and the historical loopback discrepancy remains unexplained.

Focused implementation validation passed: 13 worker-isolation unit tests, Python compilation, shell syntax, systemd unit verification, and `git diff --check`. The final preflight and LFS-only evidence were captured using the final installed launcher/validator source. No complete toolchain/model proof was repeated.

The direct-batch continuation passed 19 worker-isolation unit tests, Python compilation, shell syntax, `systemd-analyze verify`, `git diff --check`, and canonical changed-file validation. It did not repeat the full toolchain or model proof.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34a5d-ca7c-83ea-b267-382f1be560df
