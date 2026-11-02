# Operator Animation Recipes

Recipes under `custodian/tools/operator/art_recipes/` describe animation
grammar, required landmarks, QA concerns, and immutable constraints for walk,
run, idle, fast attack, and heavy attack. They never prescribe a frame count;
the existing Workbench contract owns frame size, count, and timing.

`required_landmarks` is checked per frame, not merely present somewhere in the
session. A recipe may declare it as a flat list (required on every frame) or
as `{"each_frame": [...], "when_visible": [...]}`, where `when_visible`
entries are only required on frames where that landmark name is already
tracked elsewhere in the session (e.g. a weapon grip when a weapon is
equipped). A stale landmark never satisfies the requirement.

V2 plans are evidence packages. They cannot change gameplay timing, hit
windows, movement speeds, socket authority, or publish art.
