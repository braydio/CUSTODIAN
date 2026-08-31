# Operator Animation Recipes

Recipes under `custodian/tools/operator/art_recipes/` describe animation
grammar, required landmarks, QA concerns, and immutable constraints for walk,
run, idle, fast attack, and heavy attack. They never prescribe a frame count;
the existing Workbench contract owns frame size, count, and timing.

V2 plans are evidence packages. They cannot change gameplay timing, hit
windows, movement speeds, socket authority, or publish art.
