# Procgen Showcase Gallery Shell

Workstream: `procgen-showcase-gallery-shell`

## Delivered

- Registered `procgen_showcase_gallery` as a dev-only authored level with reset-on-entry lifecycle, a standard explicit return exit, and a world ingress site.
- Added a deterministic authored floor layout for Terrain, Topology, Sites, Population, and Presentation. The smoke proves every floor rectangle joins the same walkable region and each exhibit marker lands on floor.
- Added a central concourse with an explicitly labeled, collision-sealed arena threshold. No generated map, generator, exhibit catalog, or gameplay actor is embedded in the destination.
- Added a Collision/POI authoring scene and a standalone wrapper with exactly one real Operator, controller, and camera plus the ordinary combat/navigation roots.
- Registered a focused smoke that checks floor connectivity, collision boundaries, level definition paths, wrapper ownership, and operator-preserving ingress/return/re-entry.

## Evidence and awkward parts

- Focused validations passed: `level_registry_contract`, `authored_level_ingress_return`, `world_ingress_physics_reentry`, `npa_showcase_arena_foundation`, `lords_of_pain_test_gallery`, and `procgen_showcase_gallery_shell_smoke`.
- Final changed-file validation passed 46/46 checks with complete coverage using `TMPDIR=/dev/shm`.
- The first changed-file sweep stopped at `godot_import_lfs_preflight`: this host has `/tmp/.git`, so its standalone temporary-project fixture was incorrectly treated as Git-managed. Running that check with `TMPDIR=/dev/shm` passed, and the full changed-file gate then passed.
- A fresh worktree also needed one headless editor import before Godot global class names and imported resources were available. That import generated the required `.uid` files for the new scripts and two unrelated untracked `.uid` files; only the task-owned sidecars are retained.
- The existing level-registry test reports unrelated invalid-UID fallbacks and enemy-navigation warnings. The NPA foundation test passes with its existing renderer/ObjectDB leak warnings. No existing level or generator implementation was changed.
- No renderer capture was needed: acceptance is established by authored geometry, marker placement, collision segments, registered resource paths, and a deterministic route lifecycle fixture. Subjective art approval remains human-owned and outside PGA-1 acceptance.

## Deferred

Generated arena realization, catalog semantics, generation controls, runtime inspection, exemplar search, and seed comparison remain in later PGA slices. No source artwork or Asset V2 family was created.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: the host's `/tmp/.git` sentinel caused a false failure in the standalone Git LFS preflight fixture; the fresh Godot worktree initially lacked imported class/resource caches.
- Root cause / contributing factors: the validation fixture treats any ancestor `.git` directory as repository membership, and a new worktree has no local Godot import cache.
- Prevention / pipeline improvement: use a temporary root outside `/tmp` for this host's validation runs and perform one headless editor import before Godot scene validation in a fresh worktree.
- Tooling / docs drift discovered: `godot_import_lfs_preflight_smoke.py` is sensitive to an ambient `/tmp/.git` directory.
- Follow-up: none
- What worked: geometry assertions proved the shell's walkable connection and sealed threshold without renderer capture.

## Next Handoff
- Next workstream: review-procgen-showcase-gallery-shell
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e
- Refresh reason: none
- Next action: after this implementation lands and archives complete, launch the named fresh-context paired review; do not advance PGA-2/PGA-3 before its review completes.
- Blockers or open questions: none
