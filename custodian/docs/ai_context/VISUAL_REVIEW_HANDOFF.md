# Visual Review Handoff

Purpose: move important last-mile runtime/presentation evidence out of coding-agent
reasoning and into a compact external review bundle that the user and ChatGPT can
inspect through the linked Dropbox source.

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
4. Read the claimed packet/receipt's exact `Authoring chat`. That conversation is
   the review endpoint. Do not invent or substitute another ChatGPT link.
5. If a subjective question still matters, publish it:

```bash
python3 custodian/tools/iteration/publish_review_artifacts.py \
  --important \
  --reason "subjective art/readability review remains after objective checks passed" \
  --workstream <workstream-id> \
  --source <moment-forge-or-review-directory> \
  --scenario <scenario-id> \
  --question "<specific reviewer question>"
```

The publisher resolves the packet's `Authoring chat` automatically. Use
`--authoring-chat <exact-url>` only for a deliberate override. New bundles use
`custodian.visual_review_handoff.v2` and default to
`retention.policy=delete_after_review`. Use `--retain-after-review` only when
the user/packet explicitly says the evidence must remain in Dropbox.

6. Stop. Do not spend coding-agent tokens performing subjective visual critique.
7. Report the emitted `CUSTODIAN_VISUAL_REVIEW_HANDOFF_JSON` payload, especially:
   - exact authoring-chat URL;
   - workstream and commit/branch;
   - Dropbox manifest path;
   - exact reviewer questions;
   - cleanup policy and emitted cleanup command;
   - any objective validation failures that remain.
8. The user returns to the exact authoring ChatGPT conversation. ChatGPT web uses
   the connected Dropbox manifest/path directly, reviews only the listed evidence,
   and answers the recorded questions.
9. When the verdict reaches the execution agent, continue the **same workstream**.
   Unless the user/packet/manifest explicitly selected retention, run the exact
   emitted cleanup command before continuing or finishing:

```bash
python3 custodian/tools/iteration/publish_review_artifacts.py \
  --cleanup-reviewed \
  --workstream <workstream-id> \
  --run-id <run-id>
```

The cleanup command validates the v2 manifest identity and retention policy,
purges exactly that run directory, and removes `LATEST.json` only when it still
points to the reviewed run. A newer `LATEST.json` is preserved. Cleanup is
idempotent after a successful purge. Never delete review evidence by wildcard,
directory age, or guessed path.

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

## ChatGPT Web Review Contract

The authoring ChatGPT conversation should receive the **Dropbox path**, not copied
screenshots, whenever the connected Dropbox source can provide the evidence. The
execution agent reports:

```text
Authoring chat: <exact packet URL>
Dropbox manifest: /CUSTODIAN/visual_review/<workstream>/<run-id>/REVIEW_MANIFEST.json
Questions:
- ...
Cleanup policy: delete_after_review | retain
```

ChatGPT web should inspect that manifest and its declared artifacts through the
connected Dropbox source, answer the explicit questions, and return a compact
verdict to the same conversation. A useful response shape is:

```text
Visual review verdict: approved | changes_required | blocked
Findings: <specific visual findings or none>
Cleanup: delete | retain
```

`Cleanup: delete` is the default whenever the manifest says
`delete_after_review`. `retain` is used only when the user explicitly wants
the evidence kept. ChatGPT does not need to perform destructive Dropbox deletion;
the execution agent owns the exact-run cleanup command after receiving the
verdict.

## Authority and Retention

Dropbox review media is advisory, transient evidence, not runtime or design
authority.

Git remains authoritative for:

- implementation;
- schemas/contracts;
- tests and deterministic receipts;
- durable task/closing summaries and the authoring-chat backlink.

For new v2 handoffs, the default retention policy is **delete after review**.
Once the authoring-chat verdict has been received, the execution agent runs the
manifest-gated `--cleanup-reviewed` command automatically unless retention was
explicitly requested. This avoids accumulating stale evidence and Dropbox disk
usage while retaining the durable verdict/summary in Git.

Do not commit Dropbox review binaries merely to preserve them. If a durable
record matters, keep the implementation summary/receipt and record the reviewed
workstream/run id plus verdict. A Dropbox path may be recorded for traceability
even after its transient payload has been deleted.

The cleanup rule applies only to `CUSTODIAN/visual_review/`. It does **not**
delete inbound `CUSTODIAN/implementation_inputs/` handoffs.

Visual baseline approval remains an explicit human decision.
