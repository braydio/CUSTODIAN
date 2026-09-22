# Ranged source masters — staging for review

Generation masters (2172x724), **not** publishable sheets. They are named by the
canonical identity they are intended to become, so the mapping survives without
anyone having to remember it.

The frame/size suffix is deliberately absent. A name ending `__<n>f__96` is the
published-sheet contract, and the frame count is not known until the master is
sliced — using that form here would both guess and risk an ingest picking the
file up.

| file | canonical identity | notes |
|---|---|---|
| `...posture__relaxed_01__e__master.png` | `ranged_2h/posture/relaxed_01` | LIVE identity, already has e/w lower+upper+weapon |
| `...transition__take_aim_01__e__master.png` | `ranged_2h/transition/take_aim_01` | **new action**, needs a reachability entry |
| `...cosmetic__aim_01__e__master.png` | `ranged_2h/cosmetic/aim_01` | exists, currently DORMANT |
| `...cosmetic__reload_01__e__master.png` | `ranged_2h/cosmetic/reload_01` | LIVE, currently `omni` full_body |
| `...weapon__...reload_01__e__master.png` | same action, `weapon` layer | gun only (17% of cell) |
| `...fx__...reload_01__e__master.png` | same action, `fx` layer | effect only (25% of cell) |

Layer inference came from silhouette height in the master: the three "baked"
bodies occupy 50-59% of a cell, the weapon sprite 17%, the VFX 25%. Reload
therefore arrives as a proper three-layer set — body, weapon, fx — which is the
composition the ranged architecture wants.

## Open decisions before any of this is published

1. **`reload_01` is currently `omni` full_body**, promoted byte-for-byte from the
   legacy sheet. An east-specific full_body replaces that omni contract. That is
   a deliberate change, not a detail.
2. **`take_aim_01` does not exist.** Adding it means a reachability entry and a
   consumer; without a consumer it should land DORMANT.
3. **Full-body versus modular.** R4 established ranged presentation as the
   modular composition and deliberately left `stance_01/*/full_body`
   unpublished. These "baked" masters are fused body+weapon. Publishing them as
   `full_body` is only consistent if they are explicitly the temporary fused
   layers the ranged packet anticipated, pending a lower/upper split.
4. **East only.** Every master is east. West is not a mirror in this repo:
   across 146 published e/w pairs, only 9 are exact mirrors, and modular body
   layers differ from a mirrored east by ~10% of pixels (full_body by ~22%).

## Not an ingest path

This directory is staging for human review. Publishing goes
`_pipeline/inbox` -> `operator_ingest.sh --apply` -> source/runtime, so nothing
here is picked up automatically.
