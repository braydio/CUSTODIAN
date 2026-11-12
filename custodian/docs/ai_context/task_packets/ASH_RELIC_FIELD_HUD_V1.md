# ASH & RELIC FIELD HUD V1 — ONE-SITTING CODEX TASK

- Packet schema: `custodian.task_packet.v2`
- Workstream: `ash-relic-field-hud-v1`
- Category: `tools-ux`
- Status: `ready`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `none`
- Kind: `implementation`
- Review: `none`
- Review stage: `post-land`
- Review modes: `none`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `0`
- Review rationale: Reversible, bounded **visual presentation only**, not an authority cutover. Legacy `ui.gd` remains sole source for gameplay/terminal/inventory operations; the new passive view can be removed without data migration. Focused state, single-HUD and responsive tests plus current prompt/controller/terminal/inventory regression smokes directly falsify the expected risks. There is no new external approval, migration or paired-review dependency.
- Reviewed main: `0268a56c8f578779199cbdc39c98c9a12574b19b`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9a2f9-cf10-83e8-bffe-5f16e079abac`
- Visual review: `none`
- Goal: Ship the owner-approved Ash & Relic **Field HUD v1** as the one ordinary gameplay display in the actual CUSTODIAN main game, with truthful status and responsive rendering, in one completable Codex sitting.
- Completion boundary: A Godot-native Ash & Relic presenter and narrow adapter are wired into `custodian/scenes/game.tscn`; duplicate old normal-field widgets are suppressed; integrity, stamina, weapon, prompt and location values reflect actual game; no terminal, pause, inventory or controller regression; focused smoke and 3 viewport sizes pass; real gameplay comparison captures are supplied or exact capture limitations reported; workstream is committed/landed and completed through normal V2 lifecycle. Later inventory, terminal, map and global UI replacements are **not part of this packet**.
- Current measured state: Main `game.tscn` owns a `UI` CanvasLayer using ~321 KB `game/ui/hud/ui.gd` (HUD, terminal coordination, command compatibility). Separate `custodian_hud.tscn`/`.gd` supports local Black Reliquary contexts and has half-scale major visual controls. Existing `black_reliquary_palette.gd` has vivid diagnostic cyan and green. IBM Plex faces are shipped. Ash & Relic visuals are adopted in design but not implemented in this inspected main.
- Evidence: `custodian/scenes/game.tscn`; `custodian/game/ui/hud/ui.gd`; `custodian/game/ui/hud/custodian_hud.tscn`; `custodian/game/ui/hud/custodian_hud.gd`; `custodian/game/ui/theme/black_reliquary_palette.gd`; `custodian/game/ui/theme/black_reliquary_styles.gd`; `custodian/content/ui/fonts/README.md`; `design/04_architecture/codebase_systems_audit/F03_HUD_TERMINAL_UI.md`.
- Task-specific authority: `design/02_features/ui/ASH_AND_RELIC_UI_SYSTEM_V1.md` supplies fully self-contained approved visuals, semantic hex, type, responsive layout and rollout rules. Current runtime UI and `design/02_features/terminal/BLACK_RELIQUARY_UI.md` remain the existing **behavior/command authority**.
- Work surface: `custodian/scenes/game.tscn`, `custodian/game/ui/hud/ui.gd`, `custodian/game/ui/theme/black_reliquary_palette.gd`, `custodian/game/ui/theme/black_reliquary_styles.gd`; create `custodian/game/ui/hud/ash_relic_field_hud.tscn` and matching `.gd`, a small adapter if needed, one focused smoke and registration in `custodian/tools/validation/validation_manifest.json`. Existing terminal/inventory/minimap scripts and local `CustodianHUD` are consumers to preserve, not wholesale rewrite targets.
- Publication inputs: `design/02_features/ui/ASH_AND_RELIC_UI_SYSTEM_V1.md`
- Change: Implement one **passive presentation** of existing Operator/HUD data. Top-left readable health/stamina bars, top-center transient location, optional top-right map when authorized, one bottom-left provider-backed interaction prompt, bottom-right weapon/ammo/heat/reload. Exploration is quiet, combat emphasizes immediate information, interaction renders one truthful action. Use native Godot UI and shipped IBM Plex, fixed Ash & Relic semantic color roles. Wire into actual main game and hide only duplicated *normal-play* legacy widgets. Do not move terminal dispatch/input, inventory authority or simulation into the view. Create and register new focused state/layout/no-duplicate regression; clarify shipped-vs-future UI docs.
- Preserve: Existing health/stamina/combat calculations, weapons/reload/heat, prompt precedence and leases, keyboard/controller focus and bindings, minimap toggle/expand, pause, terminal commands, fabrication, inventory/save, construction/debug overlays, local Black Reliquary scenes, world/Hub navigation and gameplay determinism.
- Non-goals: No complete `ui.gd` rewrite, terminal command authority move, inventory refactor, global all-scene replacement, image or font generation, Asset V2 source approval/ingest, new task/lock/dependency, world/camera/map edit or Memorial Court workstream edits.
- Acceptance: **A1** One ordinary field HUD in the actual `game.tscn` runtime, with the old normal widget copies hidden. **A2** Health/stamina and loaded/reserve ammo, reload/overheat/heat change as runtime sources change. **A3** One-shot/proximity/latched prompt expiry and precedence remain correct. **A4** Pause, inventory, terminal, controller/gameplay and minimap shortcuts work unchanged. **A5** 1024×648, 1280×720, 1920×1080 have no clipped vitals/weapon/prompt, intersecting HUD groups or center obstruction. **A6** Fixed UI semantic colors work against dark Hub and at least one bright/neutral test backdrop. **A7** Real 1280×720 before/after same-camera screenshots exist, or the exact unmet capture is disclosed, never invented. **A8** One dedicated focused new HUD smoke is registered and passes, the five existing checks below pass or preexisting failures are isolated, changed-file validation and diff checks pass. **A9** No unrelated behavior/asset/schema/geometry authority changes.
- Validation: Run `res://tools/validation/black_reliquary_ui_smoke.gd`, `res://tools/validation/hud_interaction_prompt_lease_smoke.gd`, `res://tools/validation/controller_input_contract_smoke.gd`, `res://tools/validation/inventory_ui_responsive_smoke.gd`, and `res://tools/validation/terminal_overview_layout_smoke.gd` using `godot --headless --path custodian --script <resource>`. Add a **new** focused Ash & Relic smoke to the validation manifest and this Validation field once it exists. Run repository changed-file validation and `git diff --check`; `godot --headless --quit` alone is never proof.
- Task overrides: `none`
- Deferred: Full Inventory/Ledger, Terminal/Fabrication, Map/Wayfinding and global UI asset retirement will be separately authored by ChatGPT and the user **after** this slice. None is an existing queued successor, task dependency or blocker. If implementing a new authority migration becomes necessary, do not widen this packet; keep a passive view and report that future architectural work instead.

## Run instructions for Codex

1. From a clean coordination root, fetch `origin/main` and **explicitly** claim `ash-relic-field-hud-v1` with `python3 custodian/tools/agent/dispatch.py claim ash-relic-field-hud-v1 --agent codex`. Do not use `claim-next`. Work only in its returned V2 isolated checkout, never in the shared root.
2. Inspect the existing UI node and state contracts, then implement style tokens, one passive field view and narrow read-only projection. Use no new external files or generated art.
3. Integrate into real `scenes/game.tscn`, hide only the duplicated normal legacy widgets, and keep real terminal/inventory/minimap/pause controls untouched.
4. Add dedicated smoke for changing values, prompt lease, no duplicate UI, responsive bounds and input noninterference; register it. Run existing five listed regressions, new smoke, changed-file validation and diff check. Iterate locally within the **same** claimed workstream.
5. Produce two compact real 1280×720 same-camera gameplay comparison captures where possible; report exact failure otherwise. Commit, push, land, and finish via non-force V2 lifecycle. Set packet `Completion Truth`, `Execution Feedback` and archive status with concrete evidence. Use `[skip render]` on commits not touching hosted Python-sim.

**No task dependencies, special locks, external assets, new design decisions or paired reviewer are required. Standard V2 claim integrity, Git and Godot safety still apply. Do not silently fabricate a successful test or bypass a real merge conflict.**

## Handoff (fill on completion)

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9a2f9-cf10-83e8-bffe-5f16e079abac`
- Refresh reason: `none`
- Next action: Return exact gameplay evidence and user-facing result. Future UI slices only if user requests a refreshed packet.
- Blockers or open questions: `none`