# Operator Fast Chain Inbox Reconciliation — Completion Summary

**Outcome:** Removed 12 proven duplicate east-facing Fast 01–04 lower-body, upper-body, and FX intake PNGs from `custodian/asset_drop/inbox/operator/`. Asset Doctor now reports a healthy pipeline. No source/runtime art, catalog, manifest, animation timing, or gameplay state changed.

## Disposition and original inbox SHA-256

All 12 are `STALE_DUPLICATE_INTAKE`. Nine are exact-byte matches to specialized-pipeline archive PNGs and have matching pipeline logs. The three Fast 01–03 FX strips have different PNG file hashes from source/runtime but decode to identical RGBA pixels; the source PNGs carry an `sRGB` chunk not present on the inbox copy. Each file has a valid 96×96 frame canvas and the declared 6/6/7/8-frame count in the runtime manifest.

| Inbox file | Original SHA-256 | Evidence |
|---|---|---|
| `operator__fx__unarmed__attack__fast_01__e__6f__96.png` | `c15ff58d51a94c1f44a1425eab8375283b73b7365732076ed4a8d81be50a3a81` | Decoded pixels match canonical source and runtime |
| `operator__fx__unarmed__attack__fast_02__e__6f__96.png` | `cd76b79db3ba1d04b3d2ac22c1c3b2e466c4a0e8a7dd5e1a7977615b458a5116` | Decoded pixels match canonical source and runtime |
| `operator__fx__unarmed__attack__fast_03__e__7f__96.png` | `4615e0c49dfbb278ec7b85cb525f5c4b0de8e3e012403c358ce6428a0c3d7f1c` | Decoded pixels match canonical source and runtime |
| `operator__fx__unarmed__attack__fast_04__e__8f__96.png` | `cf286a983d460bde536f0abdb78253e50510c9d95f3e7063d2a60a5f8c348f5b` | Archive byte match + specialized log |
| `operator__lower_body__unarmed__attack__fast_01__e__6f__96.png` | `d7310d0e5f4ced8c7baabeba9dea629b187b49901f1c8974d348c1e7f179576e` | Archive byte match + specialized log |
| `operator__lower_body__unarmed__attack__fast_02__e__6f__96.png` | `fb437e2a584188bdb188f59bcf18c180c2300e57f20eb75252f7722a154f32e8` | Archive byte match + specialized log |
| `operator__lower_body__unarmed__attack__fast_03__e__7f__96.png` | `61607ef54b5d5f69cc0ba6b2d8387f1404987e3ff2a5d35073c47c2720907349` | Archive byte match + specialized log |
| `operator__lower_body__unarmed__attack__fast_04__e__8f__96.png` | `1a6a26a39bd43ef3aee39151c5fc59fe738c8b03011cf9dd3640ae0165553a71` | Archive byte match + specialized log |
| `operator__upper_body__unarmed__attack__fast_01__e__6f__96.png` | `4221401d26f09059770a8c3ddea022e7f9e4e2e8b34148f75127cb2d316d93c8` | Archive byte match + specialized log |
| `operator__upper_body__unarmed__attack__fast_02__e__6f__96.png` | `a3f10acdd7d38716a267c0d4809d34507828d070c46813e4d87594b600705693` | Archive byte match + specialized log |
| `operator__upper_body__unarmed__attack__fast_03__e__7f__96.png` | `d0860419b8b5531ae564a49062e3a78f1b707e7ba409fd97ffa68b437d15f6d7` | Archive byte match + specialized log |
| `operator__upper_body__unarmed__attack__fast_04__e__8f__96.png` | `3a38ced9a950f51439e4ce472fc70345e5c5940d2dac213c736111068fdb9365` | Archive byte match + specialized log |

## Validation

- Before cleanup, Asset Doctor reported one warning: unregistered `operator` inbox family, 12 PNGs. After cleanup it reported `ASSET PIPELINE HEALTHY`, zero issues.
- `python3 custodian/tools/pipelines/sync_operator_runtime_assets.py --dry-run --strict` passed: 586 runtime sheets, zero warnings.
- `python3 custodian/tools/validation/operator_animation_contract_report.py --strict --json` passed: 60/63 present, zero missing required, three missing optional.
- `operator_animation_timing` smoke passed.
- `operator_unarmed_fast_chain` continuity smoke passed. Its first run timed out while a fresh project import rejected `hit_medium_body_01.wav` as non-PCM. Source WAV and `.import` settings were byte-identical to the root checkout; copying its already-generated, ignored Godot `.sample` into the temporary worktree cache allowed the same smoke to pass. Only classified ObjectDB/resource shutdown warnings remained.
- Compared before/after SHA-256 values for the runtime manifest, generated animation catalog, and all 12 east runtime outputs: unchanged. `git diff --check` passed.
- Moment Forge not run because this task changes no runtime or presentation behavior.

No ambiguous or divergent inbox files remained. The three optional animation-contract omissions predate this cleanup and are outside this packet.
