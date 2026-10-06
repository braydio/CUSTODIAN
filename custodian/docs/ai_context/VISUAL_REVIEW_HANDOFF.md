# Visual Review Handoff

Purpose: move important last-mile runtime/presentation evidence out of coding-agent
reasoning and into a compact external review bundle that the user and ChatGPT can
inspect through the linked Dropbox source, then remove reviewed cloud evidence by
default so the transport does not become a long-lived media archive.

This workflow does **not** replace deterministic validation. It begins only after
the cheapest objective checks have already settled everything they can.

This document owns only the outbound `CUSTODIAN/visual_review/` evidence lane.
Inbound ChatGPT/user-generated implementation inputs are a separate immutable,
manifest-committed lane under `CUSTODIAN/implementation_inputs/`; use
`IMPLEMENTATION_HANDOFF.md` and `implementation_handoff.py` for that workflow.
Both lanes share remote selection through `custodian/tools/iteration/dropbox_transport.py`.
The payload and review roots are transient transport, not Git or Asset Pipeline
V2 authority.

## Decision Boundary

Use the Dropbox handoff only when all of the following are true:

1. objective validation has completed or reached a stable known limitation;
2. a meaningful subjective visual question remains;
3. that question matters enough to justify human/ChatGPT review.

Good examples:

- art direction, composition, atmosphere, hierarchy, readability, or cohesion;
- whether an effect is too strong/weak despite being technically correct;
- gameplay-scale visual readability;
- motion/game-feel judgment after deterministic timing/state checks are green;
- choosing or approving a visual baseline.

Do **not** publish routine screenshots for facts already proven by probes, image
metrics, Asset V2 checks, registration/bounds assertions, collision ownership,
or deterministic state.

Execution agents may decide objective technical visual failures. They must not
approve subjective aesthetics, composition preference, game feel, or a visual
baseline.

## Canonical Publisher

Use:

```bash
python3 custodian/tools/iteration/publish_review_artifacts.py
```

The publisher uses `rclone` and never stores Dropbox credentials in the
repository.

Remote resolution order:

1. `--remote <name>`
2. `CUSTODIAN_REVIEW_REMOTE`
3. an rclone remote named `dropbox:`
4. one unambiguous configured remote whose name contains `dropbox`
   (for example `git-dropbox-sync:`)

If multiple Dropbox-like remotes exist, choose explicitly with `--remote` or
`CUSTODIAN_REVIEW_REMOTE`; the publisher will not guess.

Canonical remote root:

```text
/CUSTODIAN/visual_review/
```

Each upload lands at:

```text
/CUSTODIAN/visual_review/<workstream>/<run-id>/
    REVIEW_MANIFEST.json
    artifacts/
        ...
```

The publisher also maintains:

```text
/CUSTODIAN/visual_review/<workstream>/LATEST.json
```

so the user can ask ChatGPT to review the latest evidence for a workstream
without manually re-uploading screenshots.

## One-Time Setup Check

After configuring the user's local rclone Dropbox remote:

```bash
python3 custodian/tools/iteration/publish_review_artifacts.py --doctor
```

To create the canonical remote root if it is missing:

```bash
python3 custodian/tools/iteration/publish_review_artifacts.py \
  --doctor \
  --ensure-root
```

If the remote is not literally named `dropbox:`, set:

```bash
export CUSTODIAN_REVIEW_REMOTE="<remote-name>:"
```

Keep `~/.config/rclone/rclone.conf`, OAuth tokens, app keys, and provider
credentials outside the repository.

## Normal Agent Flow

1. Run the focused deterministic validation and image metrics first.
2. If renderer pixels are still necessary, run the smallest relevant Moment Forge
   scenario. Prefer `--capture-mode evidence`; use `full` only when continuous
   motion/audio/game feel is itself the question.
3. Build/reuse compact ROI/contact-sheet evidence when practical.
4. If a subjective question still matters, publish it:

```bash
python3 custodian/tools/iteration/publish_review_artifacts.py \
  --important \
  --reason "subjective art/readability review remains after objective checks passed" \
  --workstream <workstream-id> \
  --source <moment-forge-or-review-directory> \
  --scenario <scenario-id> \
  --question "<specific reviewer question>"
```

5. Stop. Do not spend coding-agent tokens performing subjective visual critique.
6. Report the emitted `CUSTODIAN_VISUAL_REVIEW_HANDOFF_JSON` payload, especially:
   - workstream;
   - commit/branch;
   - Dropbox manifest path;
   - exact reviewer questions;
   - any objective validation failures that remain;
   - exact `authoring_chat`, retention policy, and emitted cleanup command.

The user can then ask ChatGPT to review that Dropbox manifest/path directly.
When a packet has an `Authoring chat:` URL, that exact conversation is the default
review destination. The agent should return the manifest path there rather than
uploading duplicate screenshots into the conversation.

## Evidence Budget

Default publisher budget:

- at most 12 files;
- at most 6 keyframes;
- at most 50 MiB total;
- one MP4 only with explicit `--include-video`.

The publisher prefers compact review surfaces such as ROI/contact sheets, then a
small evenly sampled keyframe set, plus objective metrics/assertions.

Do not upload full raw frame sequences, caches, Godot imports, logs, or unrelated
artifacts.

## Review Questions

Every important handoff should contain one or more concrete questions. Prefer:

```text
Does the new foreground preserve Operator readability at gameplay scale?
Is Gate wind dust visually localized without obscuring the route?
Does this room still read as civic-industrial rather than generic fantasy?
Is the animation impact readable without overpowering the actor silhouette?
```

over:

```text
Does this look good?
```

## Authoring Chat And Dropbox Path Contract

Task authoring owns the route to human/ChatGPT review, not only the coding agent.

When a packet's `Visual review` metadata is `conditional` or `required`:

1. Record the exact packet `Authoring chat:` URL.
2. Use the canonical Dropbox workstream root:
   `/CUSTODIAN/visual_review/<workstream>/`.
3. State the smallest evidence budget and exact reviewer questions in the packet.
4. The execution agent publishes with `--authoring-chat <exact-url>` and returns
   the emitted exact `REVIEW_MANIFEST.json` path.
5. ChatGPT web in the recorded authoring conversation should open that Dropbox
   path through the connected Dropbox source and make the requested visual
   decision there. Do not ask the execution agent to re-send the same binaries
   into chat when Dropbox already carries them.
6. A required human/ChatGPT decision pauses the current workstream. It does not
   authorize `$custodian-next` or `claim-next` to abandon the workstream and
   claim unrelated work.

Dispatcher claim receipts expose the packet's `authoring_chat`, `visual_review`,
canonical `visual_review_root`, and retention default so autonomous workers can
carry this route forward without reconstructing it from surrounding prose.

## Review Resolution And Automatic Cleanup

Review media is transient by default. New handoffs use:

`retention.policy = delete-after-review`

After the user/ChatGPT has actually reviewed the evidence and the decision is
recorded, resume the same workstream and run the `cleanup_command` emitted in
`CUSTODIAN_VISUAL_REVIEW_HANDOFF_JSON` / `REVIEW_MANIFEST.json`. Equivalent
explicit form:

```bash
python3 custodian/tools/iteration/publish_review_artifacts.py \
  --reviewed-manifest /CUSTODIAN/visual_review/<workstream>/<run-id>/REVIEW_MANIFEST.json \
  --reviewed-by chatgpt-user
```

Cleanup is programmatic and fail-closed. It validates that the manifest path is
inside the canonical visual-review root, verifies manifest workstream/run
identity, purges only that exact run directory, and removes `LATEST.json` only
when the pointer references the run being deleted. It emits
`CUSTODIAN_VISUAL_REVIEW_CLEANUP_JSON`.

Use `--retain-after-review` only when the user or task packet explicitly says the
cloud evidence has continuing value. A retained manifest carries
`retention.policy = retain`; the reviewed cleanup command then reports
`retained` and performs no deletion.

The durable Git summary should keep the manifest path/run id, reviewer decision,
and cleanup/retention result. It should not preserve the Dropbox binaries simply
to keep a historical screenshot archive.

## Authority and Retention

Dropbox review media is advisory evidence, not runtime or design authority.

Git remains authoritative for:

- implementation;
- schemas/contracts;
- tests and deterministic receipts;
- durable task/closing summaries.

Do not commit Dropbox review binaries merely to preserve them. If a durable
record matters, keep the implementation summary/receipt and record the Dropbox
manifest path/run id there.

Visual baseline approval remains an explicit human decision. Unless the user or
packet explicitly requests retention, reviewed Dropbox media is deleted after
that decision while the durable Git receipt retains the decision provenance.
