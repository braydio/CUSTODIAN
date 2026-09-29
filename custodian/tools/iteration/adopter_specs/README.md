# Visual Validation Economy Adopter Specs

These four JSON specs capture the existing Moment Forge and image-metric
patterns for feature packets whose runtime consumers are separate from the
generic tooling slice. They are design-time templates, not entries under
`scenarios/`; `run_moment.py --list` must not try to load a feature scene that
does not exist yet.

When a consumer runtime lands:

1. Bind each role to the production presentation node or the consumer's
   read-only debug-snapshot owner.
2. Replace the symbolic state sequence with authored integer ticks and add the
   feature packet's own deterministic state-driving timeline.
3. Copy the declared probe and assertion templates into the consumer scenario.
   `state` and `states` become assertion ticks; `each_state` expands into one
   assertion per state. The test in `test_visual_validation_adopter_specs.py`
   demonstrates this binding and validates the resulting scenario against the
   current Moment Forge runner contract without launching Godot.
4. Use one compact ROI/contact sheet after the `capture-mode none` checks pass.
   Raw full frames remain secondary evidence; subjective art approval stays
   human-owned.

The Operator snapshot's direction/continuity fields are read-only evidence
owned by its presentation controller. The Solarium snapshot hash represents
the route-review state owned by that feature; the presentation must not mutate
it. Vaultwing's 24-strip count and 8×1 geometry come from the Asset V2 family
contract. Pixel metrics report measurements and do not define aesthetic
thresholds.
