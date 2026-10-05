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
   - any objective validation failures that remain.

The user can then ask ChatGPT to review that Dropbox manifest/path directly.

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

Visual baseline approval remains an explicit human decision.
