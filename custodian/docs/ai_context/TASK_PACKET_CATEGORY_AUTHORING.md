# Task Packet Category Authoring Contract

`TASK_PACKET_CATEGORIES.json` is the sole ordered taxonomy for new CUSTODIAN packet classification and the Quickshell Mission Control category selector. The taxonomy is editorial and never changes dispatch eligibility, task status, locks, review acceptance or process liveness.

## When authoring a packet

1. Read `custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json` from the current repository before choosing a category. Do not copy/paste a private or invented category list into a prompt.
2. Select exactly one `id` from `categories`, based on the *primary work surface and intended outcome*, not just a keyword in the title. Explain ambiguous cases in the packet's task-specific context rather than creating new IDs.
3. Put `- Category: \`<exact-id>\`` in the packet's top metadata header immediately after `Workstream:`. Review and correction packets inherit the category of the implementation/root packet they review or correct, even if the review involves agent tooling.
4. Do not invent additional IDs. To add one, review taxonomy overlap and update the manifest in the repository first, in a separate explicit change.
5. Before publishing, run `python3 custodian/tools/agent/check_packet_categories.py <packet paths...>` and the existing packet-authoring preflight. Treat invalid/unknown IDs as authoring failures.

For existing historic packets with no Category header, the shell shows `Uncategorized`; do not assign a category from filename alone or silently rewrite archived packets. A future explicit backfill may classify them without changing lifecycle metadata.

One primary category per packet. Implementation/review/correction remain separate dimensions, not categories. Taskwarrior project/group labels remain independent personal task navigation.
