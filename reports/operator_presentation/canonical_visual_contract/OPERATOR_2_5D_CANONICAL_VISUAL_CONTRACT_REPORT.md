# Operator 2.5D canonical visual contract evidence

Design source SHA-256: `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`.

First animation source SHA-256: `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`.

Normalized reference SHA-256: `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`.

Accepted 128px profile SHA-256: `05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761`.

The design-derived 128px reference uses one sheet-wide crisp scale and is accepted unchanged as the comparison reference. Accepted registration is fixed across all directions: center x=64, projected root [64,106], shadow origin/ground [64,107]. The first animation is registered as the accepted `unarmed/posture/idle_relaxed_01/full_body` source family (8 directions x 15 frames); timing is unknown/null and non-blocking.

## Action-envelope proxy evidence

Pre-migration `full_body` source frames were translated by +16,+22 (legacy anchor [48,84] to accepted root [64,106]); alpha bounds were not equalized. This is a proxy scan, not proof that legacy art is canonical 2.5D. Eight pixels of safety margin are used.

| Action class | Proxy frames | Safety-margin overflow | Canvas overflow | Status |
| --- | ---: | ---: | ---: | --- |
| deep_dodge_crouch | 112 | 0 | 0 | proxy_within_margin |
| fast_chain_extension | 180 | 71 | 46 | proxy_canvas_overflow |
| block_enter_hold_exit | 7 | 0 | 0 | proxy_within_margin |
| overhead_melee | 41 | 0 | 0 | proxy_within_margin |
| long_one_handed_reach | 47 | 24 | 16 | proxy_canvas_overflow |
| hit_recoil | 27 | 0 | 0 | proxy_within_margin |
| downed_death | 32 | 0 | 0 | proxy_within_margin |

Fast-chain maximum: `custodian/content/sprites/operator/source/animations/melee_1h/attack/fast_02/operator__full_body__melee_1h__attack__fast_02__e__8f__156x96.png` frame 4 has source alpha bbox `[35, 11, 136, 85]` and candidate translated bbox `[51, 33, 152, 107]`. This legacy proxy does not redefine the canonical body/reference frame. Universal action-envelope fit is explicitly not asserted; future genuine canonical overflow is handled with a root-preserving action-specific envelope or modular presentation.

Normalized-reference disposition: accepted unchanged, no cleanup pixels authorized.
