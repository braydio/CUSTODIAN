# Ritualant NPC silhouette readability shader V1 — closeout

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20

## Implementation and approval

The existing production Ritualant `AnimatedSprite2D` uses the scene-local
readability material and internal ash-silver rim. The published human visual
decision approves the kneeling ROI treatment, dated 2026-10-17, for candidate
`03678c0af88caf911166040a06fba460bcf4d2e0`, review run
`ritualant-readability-human-gate`. The reviewed artifact was
`artifacts/before_after_roi.png` (SHA-256
`dffb67e0369b018c4fd5deb2410bf1634207bac62622f4695f20af3ef42931df`). The
approval covers that visual decision; hostile/dissolve/death phase correctness
remains an objective implementation and independent-review obligation.

Human decision receipt:
`custodian/docs/ai_context/reports/ritualant_npc_silhouette_readability_shader_v1_human_visual_decision.md`

Published review manifest:
`/CUSTODIAN/visual_review/ritualant-npc-silhouette-readability-shader-v1/ritualant-readability-human-gate/REVIEW_MANIFEST.json`

## Preserved evidence

RC-056 escrow manifest:
`.git/custodian-workflow/preserved-evidence/ritualant-npc-silhouette-readability-shader-v1/20261017T035803Z-c5ab7b12713c/MANIFEST.json`
SHA-256: `17c0f94d6c6c956c301620131f4eac16a372207e81691039df435cda83617626`

RC-058 sidecar escrow manifest:
`.git/custodian-workflow/preserved-evidence/ritualant-npc-silhouette-readability-shader-v1/20261017T035803Z-c5ab7b12713c/sidecars-rc058/MANIFEST.json`
SHA-256: `84754e74d5bd693083fdcd0f29615a9dc29e1407d8cd54e5864d299eb3ba1445`
Both escrows are outside the disposable worktree; no original evidence was
modified or discarded.

## Validation

- `forlorn_ritualant_presentation`: PASS (1/1).
- `forlorn_ritualant_runtime`: PASS (1/1).
- `forlorn_ritualant_underground_smoke.gd`: PASS.
- `run_validation.py --changed --base origin/main --json`: PASS (13/13; zero failures, timeouts, or infrastructure errors) on the synchronized candidate before the latest remote-main refresh.
- `git diff --check`: PASS.
- The lifecycle will record the final validation after synchronizing current main.

## Closeout state

The original claim was resumed in its existing worktree. Current-main
integration at that point was merge `decd2552a4d42ffedcd48eea786e7c9468adbfb2`.
The canonical finish is responsible for synchronizing the latest main and
recording any required post-sync validation. The implementation packet is
complete and archived as part of this closeout. The existing mandatory review
`review-ritualant-npc-silhouette-readability-shader-v1` remains pending and must
run in a fresh context after landing; no review acceptance is claimed here.

Operator dependency gates, chassis review, Procession claim/evidence/lock, and
unrelated workstreams remain unchanged.
