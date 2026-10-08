# Operator 2.5D canonical visual contract evidence

Design source SHA-256: `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`.

First animation source SHA-256: `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`.

Normalized reference SHA-256: `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`.

Provisional 128px profile SHA-256: `c2fa7472a8d97079da65a7635757449850e87b2d1dd0818f37237ab79d1220fd`.

The design-derived 128px reference uses one sheet-wide crisp scale and is measurement evidence only. Root/floor remains provisional: the candidate guide is x=64, root y=106, ground y=107. The supplied PNG has no authoritative timing metadata, so FPS is unresolved.

## Action-envelope proxy evidence

Pre-migration `full_body` source frames were translated by +16,+22 (legacy anchor [48,84] to candidate root [64,106]); alpha bounds were not equalized. This is a proxy scan, not proof that legacy art is canonical 2.5D. Eight pixels of safety margin are used.

| Action class | Proxy frames | Safety-margin overflow | Canvas overflow | Status |
| --- | ---: | ---: | ---: | --- |
| deep_dodge_crouch | 112 | 0 | 0 | proxy_within_margin |
| fast_chain_extension | 180 | 71 | 46 | proxy_canvas_overflow |
| block_enter_hold_exit | 7 | 0 | 0 | proxy_within_margin |
| overhead_melee | 41 | 0 | 0 | proxy_within_margin |
| long_one_handed_reach | 47 | 24 | 16 | proxy_canvas_overflow |
| hit_recoil | 27 | 0 | 0 | proxy_within_margin |
| downed_death | 32 | 0 | 0 | proxy_within_margin |

Fast-chain maximum: `custodian/content/sprites/operator/source/animations/melee_1h/attack/fast_02/operator__full_body__melee_1h__attack__fast_02__e__8f__156x96.png` frame 4 has source alpha bbox `[35, 11, 136, 85]` and candidate translated bbox `[51, 33, 152, 107]`. This exceeds the 128px canvas under the stated root mapping; do not claim a universal 128px action envelope from the neutral idle. Ranged aim, a wide block-hit pose, and locked-projection coverage remain unproven.

Pixel cleanup review remains open.
