# Operator NE walk: frame-by-frame art policy, r1

This is an authored *raster transplant* experiment, not IK retargeting. The validated Iteration 004 output is the current source; a user-provided and visibly cleaner 15-frame Operator NE walk supplies intact lower-body silhouette pixels. Unlike the Knight donor, these are the Operator's own costume, contours, gold highlights and boot volumes.

The script is exact, deterministic, and based on three immutable 128×128-coordinate sources: the validated active strip, cleaner 15-frame strip, and single-frame style lock. The idle 15f is a read-only drape/provenance reference; the 10f alt is exploratory only and intentionally NOT interpolated into the 15f output.

Frame plan: every frame keeps all current pixels above an authored y-line, uses cleaner Operator apron/leg pixels below, and chooses a continuous +/-4px join around the line. The line is F01=66, F02=66, F03=65, F04=64, F05=63, F06=63, F07=63, F08=64, F09=65, F10=64, F11=62, F12=62, F13=62, F14=64, F15=65. Smaller numbers in F05–F07 and F11–F13 preserve more of the correctly drawn apron mass and crossing/extended leg contours. The seam path has at most 1px step between adjacent columns and searches for transparent/pixel-compatible boundaries.

The lower body is transplanted *whole* from the better-looking NE Operator frame rather than rotating a poorly aligned boot within a flattened source. This is the programmatic treatment for the east-reading near leg, shredded contours and apron stretch requested by the user. It retains the active upper torso, hood, shoulders and arms above the join. The script does not invent colors: every output pixel is copied from one of the two same-frame RGBA inputs at its current XY coordinate.

Specific frame attention:
- F01–F02: reference registration, planted near sole and start of loop.
- F03–F04: first crossover approaching, leg separation and hem connection.
- F05–F07: opposite lead, cloth overlap and hidden far sole, with cleaner source fabric.
- F08–F10: support leg remains visible while pivoting to recovery.
- F11–F13: extended near boot NE projection, strong apron opening and near calf integrity.
- F14–F15: return to seam without shredded edges; evaluate F15→F01 in motion.

No numerical contact, motion-phase or silhouette acceptance is inherited from the previous raster once pixels are changed. The output report records per-frame sole-footprint differences so later art review can decide whether additional controlled foot positioning is needed. The candidate is disposable; the input bytes are never altered.
