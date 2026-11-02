REFERENCE ONLY.

This 6-frame 64x64 carbine reload strip is preserved as visual/provenance
reference. It is NOT runtime authority and must not be normalized into the
Operator 96x96 animation pipeline.

Current target architecture:
Operator reload body animation
    + static socketed carbine sprite
    + MagazineSocket / OffhandPropSprite
    + mag_out / mag_in / reload_commit events
    + optional reload VFX

Do not restore animated weapon SpriteFrames from this sheet.

See design/02_features/operator_modular_weapon/HYBRID_WEAPON_SOCKET_SYSTEM.md.
The canonical body reload is `ranged_2h/cosmetic/reload_01` on the Operator body;
the carbine itself stays a static directional sprite driven by sockets. This
sheet remains useful as a TIMING reference for when the magazine leaves, re-enters
and the weapon settles — not as executable art.
