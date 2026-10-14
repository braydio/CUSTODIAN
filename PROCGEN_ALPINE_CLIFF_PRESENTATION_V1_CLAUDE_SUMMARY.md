# Procgen Alpine Cliff Presentation V1 — Correction 2

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d

## Outcome

The stale visual disposition for evidence run `20261014T061508Z` is recorded as FAIL for contact/fascia integration and attached geology; playable-edge readability passed. Its delete-after-review manifest cleanup completed in the previous run. AP2 remains open and AP3 remains dependency-gated.

This correction found that a few authored sockets were opaque but lay on the silhouette itself. A zero-error point round trip therefore proved a touch, not an attached overlap. The ten contact PNG payloads already had true irregular binary geology alpha, transparent margins, and no detected crop walls; this correction kept those exact images and moved each authored socket inward. Asset V2 correctly classified the unchanged payloads as duplicates, so no new state IDs or PNG ingest were needed.

The Alpine profile now records all ten inboard socket coordinates and a 24 px minimum opaque support depth. Runtime placement rejects a socket that only touches the alpha silhouette, and such a rejected contact emits neither art nor fascia suppression. The contact composer reports support depth with each successful placement.

## Evidence

- `verify_alpine_cliff_presentation_assets.py --record`: PASS, all 26 AP2 states verified; receipt `850f3261b800bdb255c71aa61553e13bc1b9313a7d6b27ac193e484f0cc268ef`. The three AP2 Asset V2 family statuses remain complete: fascia 12/12, contact 10/10, depth chunks 11/11 registered optional states. Contact inbox files remain waiting for ingest because their payload hashes match the current runtime PNGs.
- Focused `procgen_alpine_cliff_presentation_smoke.gd`: PASS, including a negative control restoring the old east silhouette-edge socket; it fails closed and emits no fascia mask.
- Generic cliff smoke: PASS (`1001` cells, five representative seeds). Wall integration: PASS (eight seeds; `3531` fascia cells, `3601` wall cells, `1163` wall lips). Region Frame smoke: PASS. Macro Presentation smoke: PASS (`d2d2e420…`). Elevated-world asset contract: PASS (`37` sources, `944` face cells).
- Moment Forge `procgen/alpine_plateau_edge_review`, evidence run `20261014T164000Z-socket-embed-contract`: PASS, no run/probe/capture failures. North/east/south/west each have four successfully attached cardinal contacts; maximum socket error is `0 px`; minimum measured opaque support and configured minimum are both `24 px`; core/shoulder suppression remains `279` cells and `16` shoulder cells. Scenario assertions explicitly guard these attachment values. Review manifest: `/CUSTODIAN/visual_review/procgen-alpine-cliff-presentation-v1/20261014T164000Z-socket-embed-contract/REVIEW_MANIFEST.json`.
- The first attempt to add the new Moment Forge probe failed because its threshold variable was scoped inside the placement loop. The retained `20261014T163000Z-socket-embed-contract` run is diagnostic-only; the scope error was fixed, the focused smoke passed, and the successful `164000Z` run supersedes it.
- Accepted-world parity with `PARITY_KEYS=1`: AP2 hash `3211326287`; clean current `origin/main` hash `2068075335`. Fingerprint is `2896026968` on both. The only deterministic level-data key difference is `macro_presentation` (AP2 `2384386495`, main `1599143607`); all other stable keys match. The `2068075335` golden was not changed because no versioned level-data migration was established.
- Direct quick performance baseline with a 300 s outer timeout: AP2 and clean main both pass `determinism_ok=true` and share generation fingerprint `1773840677`, contract fingerprint `1223064559`, and streaming counts (`19` revealed, `1466` queue peak, `389` nodes). AP2/main generation runs were about `2.8/2.8 s`; contract loop was `55.9/54.2 s`; promotion/materialization was `82.0/78.8 s`; average sampled frame time was `6.894/6.887 ms`. The registered 120 s limit is too short for this host’s quick profile.
- Asset Doctor’s four Awakening Designation Locker mismatches are unrelated and were not included in AP2 scope.

## Checkpoint identity

At correction start, local `HEAD` and `origin/agent/procgen-alpine-cliff-presentation-v1` both resolved to `841769bee66d6f5a98f273a2b1af6f760c0a71a0`, whose subject is `alpine remote checkpoint history, review link [skip render]`. That branch contains the actual Alpine implementation commit `a9e67bc733c2edc6993f33216af427ecc92d0b8a`; it is not the Vaultwing commit that had occupied the ref before the earlier checkpoint repair. After fetching, the branch was 3 commits ahead and 10 behind `origin/main` (`8decfc1fc51fa10c6dbca2e88be50d7b059040e3`). Correction commit `d6acb605d8a86ec4c5053302653fd235806bbb46` is now verified at both local `HEAD` and `origin/agent/procgen-alpine-cliff-presentation-v1`; the branch is 4 commits ahead and 10 behind that same `origin/main`.

## Visual review handoff

- Current run: `20261014T164000Z-socket-embed-contract`.
- Manifest: `/CUSTODIAN/visual_review/procgen-alpine-cliff-presentation-v1/20261014T164000Z-socket-embed-contract/REVIEW_MANIFEST.json`.
- Retention: `delete-after-review`; after the decision, run `python3 custodian/tools/iteration/publish_review_artifacts.py --reviewed-manifest /CUSTODIAN/visual_review/procgen-alpine-cliff-presentation-v1/20261014T164000Z-socket-embed-contract/REVIEW_MANIFEST.json --reviewed-by chatgpt-user`.
- Questions: (1) Do contacts visibly join the playable terrace and fascia in all four directions without a chasm gap or floating slab? (2) Do the silhouettes read as attached geology without crop walls or detached masses? (3) Does the playable floor edge remain clear and truthful?
- A prior `20261014T065730-0400` upload has no recorded visual decision. It is superseded as the active review gate by this fresh run; its cloud bundle remains untouched because delete-after-review cleanup requires a recorded decision.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: the original attachment smoke treated an opaque boundary point with zero positional error as proof of physical attachment; the first probe-enhancement run also exposed a GDScript scope mistake.
- Root cause / contributing factors: the contract did not measure solid alpha support inward from the socket; the probe variable was declared inside a narrower block than its summary use.
- Prevention / pipeline improvement: require at least 24 opaque pixels of inward support in both preparation and runtime; keep the negative control that restores a boundary-touch socket; rerun focused smoke before producing evidence.
- Tooling / docs drift discovered: the quick performance profile includes a large accepted contract and can exceed its registered 120 s timeout; use an outer timeout of at least 240 s for direct comparisons on this host.
- Follow-up: fixed-in-scope
- What worked: comparing current AP2 and clean-main outputs with `PARITY_KEYS=1` isolated the golden mismatch to `macro_presentation`.

## Next Handoff

- Next workstream: procgen-alpine-cliff-presentation-v1
- Next packet state: human-required
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d
- Refresh reason: none
- Next action: review `/CUSTODIAN/visual_review/procgen-alpine-cliff-presentation-v1/20261014T164000Z-socket-embed-contract/REVIEW_MANIFEST.json`, answer the three contact-integration questions, then continue the same AP2 workstream.
- Blockers or open questions: the `macro_presentation` accepted-world hash mismatch remains unexplained as a versioned migration; AP2 cannot close until the current visual decision and parity disposition are resolved.
