# Awakening reveal framing review — 2026-09-20

The [before](before/zoom_samples.json) and [after](after/zoom_samples.json)
captures use the live Awakening scene, real Operator, and 1920×1080 camera.
Each reveal has normal, halfway, hold, and released PNGs in those directories.

Normal framing at the trigger settles near zoom `2.025`. Before this follow-up,
the authored absolute reveal targets were `0.72` (Dust Lung), `0.68` (Gate),
and `0.66` (Approach): 36%, 34%, and 33% of normal framing. The captures show
the resulting large zoom-out and room plate shrinking into the void.

Awakening now multiplies those authored reveal targets by its local camera scale
`2.25` at presentation time. Layout.CAMERA_REVEALS is unchanged. The resulting
targets are `1.62`, `1.53`, and `1.485`: 80%, 76%, and 73% of normal framing.
This restores the original relative pullback while retaining the local normal
camera policy and the authored transition durations and offsets.
The recorded hold-frame zooms are `1.634`, `1.547`, and `1.499`; each continues
easing toward its target during the hold. The released frames return near
`2.025`.

No Undergate lighting profile was changed during this follow-up. Its prior
ambient increase still requires art-direction review.
