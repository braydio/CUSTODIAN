# Operator Runtime Rules

Read `design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md`
before changing Operator animation or presentation behavior.

## Animation Wiring

A gameplay requirement such as:

- add a transition;
- connect a new attack animation;
- add startup or recovery;
- add a reaction;
- fix an animation gap; or
- wire new sprite art

does not authorize direct asset loading.

Active Operator code must not:

- preload animation PNGs;
- construct ordinary runtime animations from PNGs;
- maintain private animation texture dictionaries;
- invent directional fallback rules; or
- bypass `OperatorAnimationSelector`.

The correct path is:

```text
semantic gameplay action
-> OperatorAnimationSelector
-> generated operator_runtime_frames.tres
```

If the semantic clip is unavailable, fix the asset publication/runtime pipeline
first, then wire the gameplay state. Do not solve missing publication by
bypassing runtime authority.
