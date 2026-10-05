# BIDIRECTIONAL DROPBOX HANDOFF

- Packet schema: `custodian.task_packet.v2`
- Workstream: `bidirectional-dropbox-handoff`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `dropbox-handoff`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-bidirectional-dropbox-handoff`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `production workflow/tooling change that moves external binary inputs and review evidence across a credentialed transport boundary`
- Reviewed main: `10560b17`
- Authoring chat: `https://chatgpt.com/share/6ac306f1-f2a0-83e9-9823-86add3c01c91?ogimg=plain`
- Goal: Make the existing Dropbox visual-review transport bidirectional so ChatGPT/user-generated images, ZIP handoffs, and other explicit binary payloads can be placed in a canonical Dropbox implementation-input lane, fetched and integrity-verified by Codex before implementation, while preserving the existing Codex-to-Dropbox visual-review lane.
- Completion boundary:
  - Add one canonical inbound implementation-handoff contract and one repository-owned fetch/verification entrypoint.
  - Reuse one Dropbox/rclone transport authority rather than duplicating remote resolution between inbound and outbound helpers.
  - Make inbound handoffs immutable, manifest-committed, hash/size verified, path-safe, and staging-only.
  - Wire focused validation and active documentation so future task packets can name exact Dropbox payloads without manual download/re-upload.
  - Exercise the real configured Dropbox remote for inbound prepare/fetch and outbound visual-review publication, including one PNG and one ZIP transport smoke, while keeping credentials out of Git.
  - Done means Dropbox -> verified local staging and local review evidence -> Dropbox are both covered by focused tests and a real-provider smoke.
- Current measured state:
  - `custodian/tools/iteration/publish_review_artifacts.py` is the one-way outbound publisher. It publishes under `CUSTODIAN/visual_review/<workstream>/<run-id>/`, writes `REVIEW_MANIFEST.json`, and updates per-workstream `LATEST.json`.
  - `custodian/tools/iteration/test_publish_review_artifacts.py` covers remote resolution, artifact selection, slug validation, and the opt-in gate, but there is no repository-owned inbound Dropbox fetch/verification path.
  - `VISUAL_REVIEW_HANDOFF.md`, `AGENT_TOOLING_BY_ASK.md`, and `CURRENT_STATE.md` document only the outbound review lane.
  - No live repository file defines `custodian.implementation_handoff.v1`, `HANDOFF_MANIFEST.json`, or an `implementation_inputs` Dropbox root.
  - The connected ChatGPT Dropbox surface supports uploading generated conversation files to an existing Dropbox destination; the repository currently has no canonical destination/manifest contract for Codex to consume those files.
  - At authoring time the linked Dropbox search returned no `CUSTODIAN`, `visual_review`, or `REVIEW_MANIFEST` objects, so canonical remote roots must be verified/created rather than assumed.
- Evidence:
  - `custodian/tools/iteration/publish_review_artifacts.py`
  - `custodian/tools/iteration/test_publish_review_artifacts.py`
  - `custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md`
  - `custodian/docs/ai_context/AGENT_TOOLING_BY_ASK.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`
  - `custodian/tools/agent/task_packet_contract.py`
  - External authoring observation: ChatGPT Dropbox upload accepts generated conversation files when the exact destination parent exists; workstation-side rclone remote auto-detection already recognizes a unique Dropbox-like remote such as `git-dropbox-sync:`.
- Task-specific authority:
  - `custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md` owns the existing outbound human/ChatGPT review gate.
  - `custodian/tools/iteration/publish_review_artifacts.py` owns current outbound transport behavior and must remain backward compatible.
  - `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` owns task-packet provenance and review requirements.
  - Asset Pipeline V2 remains authoritative for semantic source/inbox/runtime routing after an external asset package has been fetched; Dropbox transport must not bypass it.
- Work surface:
  - Primary owner: `custodian/tools/iteration/`.
  - Prefer a small shared Dropbox transport module plus a focused inbound CLI, rather than cloning publisher internals. If live main exposes a cleaner seam, preserve this behavioral contract and avoid a parallel remote-resolution authority.
  - Expected tests/consumers: existing publisher/tests, new inbound handoff tests, and `custodian/tools/validation/validation_manifest.json`.
  - Documentation: new `custodian/docs/ai_context/IMPLEMENTATION_HANDOFF.md`, plus `AGENT_TOOLING_BY_ASK.md`, `VISUAL_REVIEW_HANDOFF.md`, `CURRENT_STATE.md`, `FILE_INDEX.md`, task-packet authoring guidance where external payload provenance belongs, and the packet index.
- Change:
  - Establish canonical inbound root `CUSTODIAN/implementation_inputs` with immutable layout `CUSTODIAN/implementation_inputs/<workstream>/<handoff-id>/HANDOFF_MANIFEST.json` plus `payload/...`.
  - Define `custodian.implementation_handoff.v1`. The transport manifest must bind `schema`, `workstream`, `handoff_id`, `created_at_utc`, `authoring_chat` (URL, `not-recorded`, or `n/a`), and a non-empty `payloads` array. Each payload record carries a relative path under `payload/`, exact `size_bytes`, exact lowercase SHA-256, and short `purpose`; MIME/type metadata may be optional.
  - Treat `HANDOFF_MANIFEST.json` as the commit marker: upload payload bytes first and manifest last. Handoff IDs are immutable. Failed/revised uploads use a new ID; do not overwrite committed handoffs or maintain a mutable inbound `LATEST.json`.
  - Add an inbound CLI with stable `doctor`, `prepare`, and `fetch` behaviors. `doctor --ensure-root` verifies/creates the root. `prepare` creates an exact empty `<workstream>/<handoff-id>/payload/` target and fails on reuse/collision. `fetch` validates the manifest first, downloads only the declared handoff into temporary staging, verifies exact file set/size/SHA-256, atomically exposes verified staging, and emits `CUSTODIAN_IMPLEMENTATION_HANDOFF_JSON`.
  - Reject schema/identity mismatch, absolute or traversal paths, paths outside `payload/`, duplicate/colliding payload paths, malformed hashes/sizes, undeclared extra files, missing files, declared-size limit breach, checksum/size mismatch, and destinations that directly bypass staging into runtime or Asset V2 canonical directories.
  - Never auto-extract ZIPs, mutate runtime/content, route files into `asset_drop`, or infer semantic asset destinations. The owning task packet/Asset V2 package handles promotion after verified staging.
  - Add an explicit configurable total-size ceiling before download, with a test-covered default and override for intentionally larger packages.
  - Extract only genuinely shared rclone/remote/path/hash primitives needed by both directions. Preserve outbound flags, opt-in gate, review budgets, manifest schema, `LATEST.json`, emitted JSON prefix, and `CUSTODIAN_REVIEW_REMOTE` compatibility.
  - If a generic Dropbox env var is introduced, preserve legacy outbound env precedence and document exact inbound/outbound precedence. Never read, print, commit, or rewrite rclone credentials/tokens.
  - Add focused fixtures for good PNG + ZIP handoffs and hostile manifests. Register validation ownership so changed-file validation selects these tests without broad Godot sweeps.
  - Update active docs so `implementation_inputs` is transient external implementation input; `visual_review` is transient review evidence; Git remains authority for packets/design/code/schemas/receipts.
  - Correct active documentation drift discovered in scope. Do not rewrite historical closing summaries merely because their environment observations are older.
  - Perform one real-provider smoke: ensure both canonical roots, prepare a unique inbound handoff, upload a deterministic tiny PNG and ZIP plus valid manifest, fetch through the new CLI, prove byte hashes, publish one compact outbound review bundle, and verify remote manifest/artifact listing and round-trip hash. Use unique IDs.
  - Clean up only clearly disposable failed/corrupt smoke fixtures created by this workstream. Keep the successful smoke handoff/review evidence through paired review; never delete unrelated Dropbox content.
- Preserve:
  - Existing `publish_review_artifacts.py` caller behavior, CLI flags, outbound manifest schema, review budget, and opt-in subjective-review gate.
  - Existing rclone credentials/config location and configured remote names.
  - Git as durable authority; Dropbox remains transport/evidence, not a competing source of truth.
  - Asset Pipeline V2 source_work/inbox/runtime ownership and specialized Operator ingest rules.
  - Existing task-packet/workstream lifecycle, paired review, validation economy, and human-owned subjective visual decision boundary.
- Non-goals:
  - No Dropbox sync, continuous polling, watchers, daemons, background queue, or auto-claim-on-upload.
  - Do not make Dropbox a repository mirror or runtime asset source.
  - Do not auto-extract arbitrary archives or auto-ingest fetched assets.
  - Do not commit provider credentials, OAuth tokens, app keys, shared links, or secrets.
  - Do not redesign Moment Forge, Asset Pipeline V2, dispatch, or lifecycle beyond the minimal integration seam.
  - Do not require the user to manually download, move, unzip, or run setup commands that an execution surface can perform.
- Acceptance:
  1. Active docs define both Dropbox lanes, immutable inbound semantics, manifest-last commit semantics, credential rules, and Git/Asset V2 authority boundaries.
  2. One shared transport authority resolves the configured Dropbox remote without regressing the outbound publisher; existing outbound focused tests remain green.
  3. Inbound `doctor --ensure-root` succeeds against the real configured Dropbox remote and proves `CUSTODIAN/implementation_inputs` readable; outbound doctor likewise proves `CUSTODIAN/visual_review`.
  4. `prepare` creates only the requested empty handoff/payload location and refuses reuse/collision after content or commit manifest exists.
  5. A valid real-remote manifest containing both a PNG and ZIP is fetched into non-production staging with exact byte-for-byte SHA-256 and size verification and a machine-readable success receipt.
  6. The helper fails closed with no promoted/partial final staging directory for: bad schema, identity mismatch, traversal/absolute path, duplicate path, undeclared extra file, missing file, malformed hash/size, declared-size ceiling breach, hash mismatch, and existing/unsafe destination.
  7. ZIP remains opaque verified bytes; no extraction or Asset V2/runtime mutation occurs in transport.
  8. A real outbound smoke creates `REVIEW_MANIFEST.json` plus at least one compact artifact under `CUSTODIAN/visual_review/bidirectional-dropbox-handoff/<run-id>/`; remote listing verifies both.
  9. Inbound fetched PNG/ZIP hashes match uploaded source hashes, and the outbound smoke artifact can be copied back through rclone with the same hash. Record remote paths/hashes without credentials.
  10. The ChatGPT/user upload contract is actionable without manual file shuffling: exact prepared destination, upload order, manifest shape, and generated PNG/ZIP support are documented. If Codex cannot invoke the ChatGPT connector itself, classify only that source-specific API hop as externally proven by connector capability; do not weaken the real-provider Dropbox fetch gate.
  11. `validation_manifest.json` selects the new focused tests for helper/shared transport owners without a broad Godot sweep.
  12. `python3 custodian/tools/agent/check_ai_context.py` is green after packet/docs updates, including review-pairing consistency and packet/index truth.
  13. `CURRENT_STATE.md`, `FILE_INDEX.md`, `AGENT_TOOLING_BY_ASK.md`, the inbound handoff doc, and `VISUAL_REVIEW_HANDOFF.md` contain no contradictory roots/ownership/use guidance.
  14. `BIDIRECTIONAL_DROPBOX_HANDOFF_CLAUDE_SUMMARY.md` records changed files, final schemas/paths, tests, real-remote smoke receipts, any source-specific connector limitation, documentation drift corrected, and this exact authoring-chat backlink.
- Validation:
  - First run the new focused inbound handoff unit suite and `python3 custodian/tools/iteration/test_publish_review_artifacts.py`.
  - Include explicit negative fixtures for every fail-closed class in Acceptance 6; corrupt-hash and unexpected-extra-file cases must assert no verified final destination is exposed.
  - Run the repository changed-file validation selector after focused tests pass.
  - Run `python3 custodian/tools/agent/check_ai_context.py` and the live review-pairing validation used by dispatcher/AI-context checks.
  - Real-provider setup/smoke: inbound doctor/ensure-root, outbound `python3 custodian/tools/iteration/publish_review_artifacts.py --doctor --ensure-root`, unique PNG+ZIP prepare/upload/fetch/hash roundtrip, then one outbound publish/list/hash verification. Fake-rclone evidence is not enough for final provider acceptance.
  - Inspect `git diff --check`; ensure no credential/config/token file, smoke binary, downloaded payload, or Dropbox cache is staged.
  - Finish only after focused tests, changed-file gate, AI-context/pairing gate, real-provider smoke, and required closing summary are green.
- Task overrides:
  - `TASK OVERRIDE: the user explicitly authorizes the execution agent, Codex, Cloud, or another available execution surface to perform the one-time Dropbox/rclone setup, canonical root creation, unique sacrificial upload/download round-trips, and safe cleanup required by this packet without asking the user to run those steps manually; do not expose or persist credentials, do not mutate unrelated Dropbox content, and stop only when an interactive provider authentication/consent boundary cannot be completed by the available execution surface.`
- Deferred:
  - Continuous watching/polling, automatic claim-on-upload, provider-agnostic cloud abstractions, and remote retention automation.
  - Automatic ZIP extraction or semantic Asset V2 routing.
  - Richer ChatGPT-side UX beyond the canonical path + manifest contract.

## Recommended Implementation Order

1. Extract/reuse minimal shared Dropbox transport primitives with no outbound behavior drift.
2. Implement/unit-test inbound manifest validation plus doctor/prepare/fetch staging.
3. Register focused validation ownership and update active docs/task-packet guidance.
4. Run both real-root doctors, unique PNG+ZIP inbound provider smoke, and outbound review publish/hash proof.
5. Run changed-file + AI-context/pairing gates, write the closing summary, and finish/land normally.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `pending`
- Friction severity: `none`
- What went wrong: `pending execution`
- Root cause / contributing factors: `pending execution`
- Prevention / pipeline improvement: `pending execution`
- Tooling / docs drift discovered: `pending execution`
- Follow-up: `pending execution`

## Handoff

- Next workstream: `review-bidirectional-dropbox-handoff`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/share/6ac306f1-f2a0-83e9-9823-86add3c01c91?ogimg=plain`
- Refresh reason: `none`
- Next action: `Run the paired fresh-context post-land review after this implementation is complete and archived.`
- Blockers or open questions: `none`
