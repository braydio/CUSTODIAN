# CUSTODIAN Moment Forge System

**Project:** CUSTODIAN  
**Created:** 2026-07-28  
**Status:** active — V1 core implemented; scenario calibration remains  
**Last Updated:** 2026-07-29  
**Owner:** gameplay/tools  
**Runtime Target:** Godot 4.7 project in `custodian/`  
**Active Spec Path:** `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md`  
**Repository Basis:** `braydio/CUSTODIAN`, branch `main`, inspected at commit `f25ee5fca746b4d4cb779ed3d54692ada7905009`

---

## 1. Purpose

CUSTODIAN Moment Forge is a developer-only deterministic micro-playtest, capture, and comparison system.

It lets the developer define a short authored gameplay moment—normally 2 to 8 seconds—run it repeatedly under the same simulation conditions, and compare the resulting:

- gameplay outcomes;
- event chronology;
- actor movement and displacement;
- animation state and frame timing;
- visual keyframes;
- synchronized audio;
- Developer Observatory telemetry;
- warnings and stable assertions.

The system exists to answer iteration questions that ordinary smoke tests cannot answer reliably:

- Did this hit become heavier or merely louder?
- Is damage applied on the intended contact frame?
- Did attack displacement improve commitment without adding excessive travel?
- Does the parry flash occur at contact or one tick late?
- Did a new sprite strip shift the Operator’s planted foot?
- Did a fog, moonlight, or camera change improve the Sundered Keep reveal?
- Did the Field Patch sound, animation, resource spend, and healing commit remain synchronized?
- Did a change improve one direction while degrading another?
- Did a code or content change alter a previously approved encounter without producing an obvious runtime failure?

Moment Forge converts those questions from memory-based judgment into repeatable evidence.

It is deliberately smaller than the proposed Developer Replay System. Moment Forge re-runs curated scenarios from an authored initial state. It does not reconstruct arbitrary human play sessions.

---

## 2. Executive Decision

Implement Moment Forge as a hybrid system:

1. **Python owns orchestration, schema validation, baseline selection, changed-file routing, report generation, image/audio analysis, and process supervision.**
2. **A development-only Godot `SceneTree` runner owns scene loading, deterministic setup, fixed-tick action injection, role probes, assertion evidence, keyframe capture, and Developer Observatory export.**
3. **Godot Movie Maker mode owns synchronized full-run frame and audio capture.**
4. **Pillow owns contact sheets and visual comparison images.**
5. **FFmpeg is optional for H.264 MP4 generation; raw PNG sequence plus WAV remains the canonical capture evidence.**
6. **Developer Observatory remains the telemetry authority. Moment Forge enriches observed events with scenario ticks in its own run timeline but does not create a competing gameplay telemetry system.**
7. **No new autoload is added. Moment Forge is active only when launched explicitly through its CLI.**
8. **Stable gameplay assertions may fail a run. Pixel, luminance, and audio-difference metrics are advisory in V1 and may not fail CI.**

This architecture fits the live repository:

- `DevMode` already resolves explicit command-line development eligibility.
- `DevObservatory` already exposes structured event, warning, counter, gauge, and JSON export surfaces.
- the project viewport is already 1280×720;
- `custodian/scenes/debug/combat_playground.tscn` is a usable combat fixture;
- renderer-backed validation scripts already capture images from Godot;
- existing Python review tooling already depends on Pillow and emits HTML/JSON artifacts under generated review locations.

---

## 3. Scope

### 3.1 In Scope for V1

Moment Forge V1 handles:

- versioned JSON scenario definitions;
- deterministic seed application;
- fixed 60 Hz scenario execution;
- short, bounded scenario duration;
- deterministic role lookup, spawning, removal, and property setup;
- InputMap-based action press/release injection;
- deterministic pointer/aim target placement where required;
- limited, allowlisted fixture operations when InputMap alone cannot stage a condition;
- disabling uncontrolled AI or physics processing for stationary review targets;
- exact authored tick markers;
- selected post-draw keyframe capture;
- synchronized full-run frame and audio capture through Godot Movie Maker;
- Developer Observatory reset, event mirroring, warning mirroring, and JSON export;
- post-run metric extraction;
- stable assertion evaluation;
- run manifest generation;
- baseline/current comparison;
- 3×2 six-frame contact sheets;
- advisory visual and audio deltas;
- self-contained local HTML reports;
- changed-file-to-scenario suggestions;
- deterministic repeatability validation;
- repository and worktree provenance;
- renderer-backed and headless validation modes.

### 3.2 Out of Scope for V1

V1 does not implement:

- arbitrary save-state replay;
- recording and replaying a human input session;
- universal entity serialization;
- full-world restoration;
- multiplayer replay;
- rollback networking;
- player-facing death replay;
- video reconstruction from Observatory JSON;
- automatic artistic approval;
- ML-based visual scoring;
- automatic balance tuning;
- hard CI failures based on pixel or audio differences;
- invisible invocation during normal game boot;
- a second telemetry autoload;
- direct report output under `custodian/content/`;
- external web services or report dependencies;
- permanent modification of production project settings;
- scenario scripts capable of invoking arbitrary methods by name.

### 3.3 Relationship to Developer Replay System

Moment Forge and Developer Replay serve different jobs:

| System | Input | Reproduction Model | Primary Use |
|---|---|---|---|
| Moment Forge | Authored short scenario | Re-run from a deterministic fixture | game-feel iteration and curated regression evidence |
| Developer Replay | Recorded playtest data | Inspect or reconstruct a past session | diagnosis of emergent or player-reported behavior |

Moment Forge may later provide fixtures, event conventions, comparison UI, or deterministic runner code to the Developer Replay System. It must not claim arbitrary replay coverage.

---

## 4. Design Principles and Non-Negotiable Invariants

### 4.1 Simulation Authority

- Gameplay systems remain authoritative.
- Moment Forge may inject the same public InputMap actions a developer or player would use.
- Moment Forge may stage fixture state before scenario tick 0.
- Moment Forge may read runtime state for probes and assertions.
- Moment Forge may not use captured metrics, visual differences, or Observatory state to influence gameplay outcomes.
- Scenario-only presentation and fixture helpers may not migrate into ordinary runtime authority.

### 4.2 Determinism

- Scenario time is measured in integer physics ticks.
- V1 physics rate is exactly 60 Hz.
- Scenario tick 0 is the first pre-physics boundary after setup and warmup complete.
- Timeline actions scheduled for tick `N` execute before gameplay `_physics_process` for tick `N`.
- Probes for tick `N` sample after gameplay physics completes for tick `N`.
- Keyframes for tick `N` are captured after that tick’s render completes.
- Every scenario declares an explicit seed.
- Any fixture subsystem using randomness must receive the scenario seed or a deterministic derived sub-seed.
- System time, run IDs, absolute paths, frame rate samples, and engine timestamps are excluded from the stable fingerprint.
- A scenario that cannot make a relevant random source deterministic must fail preflight rather than silently claim determinism.

### 4.3 Development Gating

- No Moment Forge autoload.
- No changes to ordinary main-scene startup.
- Runner activation requires `run_moment.py` or an explicit low-level `--script res://tools/iteration/godot/moment_runner.gd` invocation.
- The Python launcher passes `--custodian-dev --observe`.
- Release-style normal boot remains unchanged.
- Debug fixture nodes and runner scripts must live outside production content ownership.

### 4.4 Evidence Separation

Generated outputs belong only under:

```text
reports/moment_forge/
```

They must never be written into:

```text
custodian/content/
custodian/game/
custodian/scenes/
design/
```

except when the user explicitly accepts a generated artifact into source control through a separate workflow.

### 4.5 Advisory Media Diffs

A visual or audio difference is not automatically a defect. Therefore:

- visual changed-pixel ratios are advisory;
- luminance deltas are advisory;
- audio onset, peak, RMS, and loudness deltas are advisory;
- a missing requested capture file is a failure;
- gameplay assertions and deterministic fingerprint mismatches may fail;
- V1 CI must not fail because two approved artistic variants differ.

---

## 5. Primary Developer Experience

### 5.1 Run One Scenario

From repository root:

```bash
python3 custodian/tools/iteration/run_moment.py combat/light_hit_grunt
```

Expected behavior:

1. Resolve `custodian/tools/iteration/scenarios/combat/light_hit_grunt.json`.
2. Validate it against `moment_schema.json`.
3. Resolve repository and Godot paths.
4. Create a unique run directory.
5. Run a deterministic Godot process.
6. Capture telemetry, keyframes, full-frame sequence, and audio.
7. Evaluate stable assertions.
8. Build metrics and an HTML report.
9. Print a compact pass/fail summary and report path.
10. Exit with a documented status code.

### 5.2 Compare Against a Baseline

```bash
python3 custodian/tools/iteration/run_moment.py \
  combat/light_hit_grunt \
  --baseline reports/moment_forge/_baselines/combat/light_hit_grunt/approved-v1
```

The baseline argument may point to:

- a run directory containing `manifest.json`;
- a baseline directory containing `manifest.json`;
- a manifest path directly.

The comparison must reject incompatible scenario versions, dimensions, frame rates, or keyframe tick sets unless `--allow-incompatible-baseline` is passed for manual inspection. Incompatible baselines never produce a passing automated comparison.

### 5.3 List Scenarios

```bash
python3 custodian/tools/iteration/run_moment.py --list
python3 custodian/tools/iteration/run_moment.py --list --tag combat
python3 custodian/tools/iteration/run_moment.py --list --json
```

The default listing shows:

- scenario ID;
- description;
- duration;
- tags;
- scene;
- baseline availability;
- schema validity.

### 5.4 Suggest Scenarios for Current Changes

```bash
python3 custodian/tools/iteration/run_moment.py --changed
```

Default changed-file discovery includes:

- unstaged tracked changes;
- staged changes;
- untracked non-ignored files.

It does not infer a commit range when the worktree is clean.

For committed branch changes:

```bash
python3 custodian/tools/iteration/run_moment.py --changed --base origin/main
```

The command prints ranked suggestions and exact run commands. It does not execute expensive captures by default.

Explicit execution:

```bash
python3 custodian/tools/iteration/run_moment.py \
  --changed \
  --base origin/main \
  --execute-suggested
```

### 5.5 Run Without Full Media Capture

For fast runtime and assertion iteration:

```bash
python3 custodian/tools/iteration/run_moment.py \
  combat/light_hit_grunt \
  --capture-mode evidence
```

Capture modes:

| Mode | Full frame sequence | WAV | Keyframes | Telemetry | Assertions | Intended Use |
|---|---:|---:|---:|---:|---:|---|
| `none` | no | no | no | yes | yes | fastest deterministic runtime checks |
| `evidence` | no | no | yes | yes | yes | default headless/structural review |
| `full` | yes | yes | yes | yes | yes | audiovisual review and baseline comparison |

Default mode for direct human use is `full`. Default mode for the focused runtime smoke is `none`.

### 5.6 Preserve Raw Capture

```bash
python3 custodian/tools/iteration/run_moment.py \
  combat/light_hit_grunt \
  --keep-raw
```

Without `--keep-raw`, the report builder may remove full PNG sequences after:

- keyframes are copied;
- contact sheets are generated;
- media conversion succeeds or is explicitly marked unavailable;
- hashes and frame counts are recorded.

The raw WAV is retained by default because it is comparatively small and useful for review.

### 5.7 Accept a Baseline

Baseline mutation must be explicit:

```bash
python3 custodian/tools/iteration/run_moment.py \
  combat/light_hit_grunt \
  --accept-baseline approved-v1
```

Rules:

- the run must pass stable assertions;
- the run must be complete;
- the destination must not already exist;
- overwriting requires `--replace-baseline` plus an interactive confirmation unless `--yes` is explicitly supplied;
- baseline acceptance copies evidence; it does not symlink a mutable run directory;
- baseline provenance records source run ID, commit, dirty state, and acceptance timestamp;
- baseline acceptance is a local review action, not automatic CI behavior.

---

## 6. Repository Layout

### 6.1 New Active Design and Task Packet

```text
design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md

custodian/docs/ai_context/task_packets/MOMENT_FORGE_V1.md
```

A full task packet is appropriate because this feature spans runtime tooling, renderer-backed capture, offline analysis, docs, and multiple implementation sessions.

### 6.2 Python Tooling

```text
custodian/tools/iteration/
├── README.md
├── run_moment.py
├── build_moment_report.py
├── changed_file_router.py
├── moment_schema.json
├── changed_file_routes.json
├── scenarios/
│   ├── combat/
│   │   ├── light_hit_grunt.json
│   │   ├── heavy_hit_grunt.json
│   │   ├── light_hit_marine_deflect.json
│   │   └── parry_success.json
│   ├── healing/
│   │   └── field_patch_commit.json
│   └── vista/
│       └── sundered_keep_first_reveal.json
├── godot/
│   ├── moment_runner.gd
│   ├── moment_action_driver.gd
│   ├── moment_capture.gd
│   ├── moment_probe_collector.gd
│   ├── moment_assertion_evidence.gd
│   └── fixtures/
│       └── sundered_keep_world_vista_fixture.gd
└── report_assets/
    ├── moment_report.css
    └── moment_report.js
```

`moment_report.css` and `moment_report.js` are embedded into `index.html` during report generation. The generated report has no network dependency.

### 6.3 Debug Fixture Scene

```text
custodian/scenes/debug/moment_forge/
└── sundered_keep_world_vista_moment.tscn
```

Combat and Field Patch scenarios use the existing:

```text
custodian/scenes/debug/combat_playground.tscn
```

The Vista fixture is allowed only because the production world reveal requires deterministic placement and camera setup that should not be duplicated inside generic JSON. It must instantiate production components and call their public configuration boundaries. It must not copy the production reveal algorithm.

### 6.4 Validation

```text
custodian/tools/validation/
├── moment_forge_schema_smoke.py
├── moment_forge_changed_router_smoke.py
├── moment_forge_report_smoke.py
├── moment_forge_runtime_smoke.gd
├── moment_forge_renderer_smoke.gd
└── run_moment_forge_suite.sh
```

### 6.5 Documentation Updates

```text
custodian/docs/ai_context/
├── AGENT_TOOLING_BY_ASK.md
├── VALIDATION_RECIPES.md
├── CURRENT_STATE.md
├── CONTEXT.md
└── FILE_INDEX.md
```

`CONTEXT.md` needs an update only if implementation introduces a durable new workflow rule beyond what this spec and the local primer already cover.

### 6.6 Generated Output

```text
reports/moment_forge/
├── _baselines/
│   └── <scenario-id>/
│       └── <baseline-name>/
└── <scenario-id>/
    └── <run-id>/
        ├── manifest.json
        ├── scenario.snapshot.json
        ├── run_result.json
        ├── telemetry.json
        ├── timeline.json
        ├── probes.json
        ├── assertions.json
        ├── metrics.json
        ├── audio_mix.wav
        ├── current.mp4
        ├── current_contact_sheet.png
        ├── baseline_contact_sheet.png
        ├── visual_diff.png
        ├── index.html
        ├── keyframes/
        │   ├── tick_000000.png
        │   └── ...
        ├── raw/
        │   ├── capture00000001.png
        │   ├── ...
        │   └── capture.wav
        └── logs/
            ├── godot.log
            ├── report.log
            └── command.json
```

Files that do not apply are omitted, not emitted as empty placeholders. `manifest.json` records their availability.

---

## 7. System Architecture

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                    run_moment.py (orchestrator)                          │
├─────────────────────────────────────────────────────────────────────────┤
│ Resolve scenario │ Validate schema │ Preflight │ Create run directory    │
│ Build Godot cmd  │ Supervise run   │ Evaluate  │ Build report            │
└──────────────┬──────────────────────────────────────────────────────────┘
               │ launches
               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              Godot Movie Maker + moment_runner.gd                        │
├─────────────────────────────────────────────────────────────────────────┤
│ Load fixture │ Apply seed/setup │ Inject actions │ Sample roles           │
│ Capture ticks│ Mirror Observatory events with tick │ Export evidence       │
└───────┬───────────────────────────────┬─────────────────────────────────┘
        │                               │
        ▼                               ▼
┌───────────────────────┐      ┌──────────────────────────────────────────┐
│ DevObservatory        │      │ Movie Writer / Viewport Capture          │
│ existing authority    │      │ PNG sequence + WAV + exact keyframes     │
└───────────────────────┘      └──────────────────────────────────────────┘
               │                               │
               └───────────────┬───────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                 build_moment_report.py                                   │
├─────────────────────────────────────────────────────────────────────────┤
│ Normalize timeline │ Stable fingerprint │ Contact sheets │ Audio metrics │
│ Visual metrics     │ Baseline deltas    │ Self-contained HTML            │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Component Responsibilities

### 8.1 `run_moment.py`

Owns:

- CLI parsing;
- repository-root discovery;
- scenario discovery;
- schema validation;
- scenario ID/path integrity;
- output-root containment;
- Godot executable discovery;
- renderer/display preflight;
- FFmpeg discovery;
- git metadata;
- dirty-worktree metadata;
- subprocess command construction;
- subprocess timeout and termination;
- stdout/stderr capture;
- exit-code mapping;
- calling report generation;
- baseline acceptance;
- `--list`;
- `--changed` delegation;
- concise terminal summary.

Must not:

- interpret gameplay code;
- fabricate missing runtime assets;
- edit scenario files;
- mutate the project;
- invoke private gameplay methods;
- mark artistic changes as automatically approved.

### 8.2 `moment_runner.gd`

`moment_runner.gd` extends `SceneTree`.

Owns:

- parsing Moment Forge user arguments;
- loading and parsing the already Python-validated scenario snapshot;
- validating critical runtime assumptions again;
- setting deterministic engine/runtime seed state;
- loading the scenario scene;
- pausing before setup where needed;
- assigning `current_scene`;
- role resolution and spawning;
- setup operations;
- controlled warmup;
- connection to `DevObservatory.event_logged` and `warning_logged`;
- clearing the Observatory before scenario tick 0;
- scenario tick clock;
- calling action, probe, capture, and assertion-evidence helpers;
- cleanup of injected inputs;
- exact Observatory export path;
- writing `run_result.json`;
- graceful `quit(exit_code)`.

It must not:

- become an autoload;
- modify project settings on disk;
- own report generation;
- evaluate image/audio differences;
- silently continue after a missing required role;
- let scenario JSON call arbitrary methods.

### 8.3 `moment_action_driver.gd`

Owns pre-physics timeline execution.

Supported V1 action types:

- `input_press`;
- `input_release`;
- `input_tap`;
- `aim_at_role`;
- `aim_at_world`;
- `set_role_position`;
- `set_role_property`;
- `set_role_physics_enabled`;
- `set_role_process_enabled`;
- `capture_marker`;
- `fixture_command`;
- `finish`.

The action driver:

- validates action type;
- validates required fields;
- validates the InputMap action exists;
- tracks every held action;
- releases all held actions during cleanup;
- executes actions in source order when several share a tick;
- records each attempted action and result;
- fails on unsupported actions;
- rejects negative ticks or ticks after `duration_ticks`;
- never calls a method named directly by scenario JSON.

`input_tap` is normalized internally into one press and one release. Its release tick must be explicit or derived from a positive `hold_ticks`.

### 8.4 `moment_capture.gd`

Owns exact visual evidence:

- validates capture resolution;
- validates contact-sheet tick list;
- requests post-draw keyframes;
- saves one PNG per selected tick;
- records image width, height, and hash;
- records the relationship between scenario tick and process/render frame;
- emits no gameplay input;
- never writes outside the supplied run output.

Full-frame/audio capture remains Movie Maker’s responsibility. This component exists because exact authored-tick keyframes must not depend on inferring offsets in a process-start movie sequence.

### 8.5 `moment_probe_collector.gd`

Samples role state after each selected physics tick.

V1 probe fields:

- `global_position`;
- `position`;
- `velocity`;
- `health`;
- `current_health`;
- `stamina`;
- `visible`;
- `animation`;
- `frame`;
- `animation_progress`;
- `state`;
- `custom_property`.

Probe definitions are declarative. A missing required field fails the scenario. An optional field emits an unavailable record.

The collector may use property reads and public getter calls from a fixed runner-side registry. Scenario JSON does not provide arbitrary getter names.

### 8.6 `moment_assertion_evidence.gd`

Collects runtime evidence required for offline assertion evaluation:

- role existence;
- input release state;
- scene identity;
- role property snapshots;
- event counts;
- warning counts;
- output-write status;
- requested metric source values.

Python performs final assertion evaluation so that one implementation handles both current-only and baseline-relative checks.

### 8.7 `build_moment_report.py`

Owns:

- loading run artifacts;
- validating cross-file consistency;
- normalizing stable metrics;
- generating a stable fingerprint;
- audio WAV parsing;
- audio onset/peak/RMS metrics;
- visual keyframe metrics;
- contact sheets;
- baseline contact sheets;
- visual diff;
- optional FFmpeg transcode;
- HTML generation;
- comparison status;
- report logging;
- report schema version.

### 8.8 `changed_file_router.py`

Owns:

- collecting changed files;
- loading readable routing rules;
- matching glob and regex rules;
- mapping rules to tags and explicit scenarios;
- ranking suggestions;
- deduplicating reasons;
- emitting text or JSON;
- producing exact follow-up commands.

It does not launch a scenario unless the top-level CLI receives `--execute-suggested`.

---

## 9. Runtime Lifecycle

### 9.1 Launch

Python launches Godot from `custodian/`.

Illustrative full-capture command:

```bash
godot \
  --display-driver x11 \
  --rendering-driver opengl3 \
  --path . \
  --write-movie ../reports/moment_forge/combat/light_hit_grunt/<run-id>/raw/capture.png \
  --fixed-fps 60 \
  --script res://tools/iteration/godot/moment_runner.gd \
  -- \
  --custodian-dev \
  --observe \
  --moment-scenario res://tools/iteration/scenarios/combat/light_hit_grunt.json \
  --moment-output res://../reports/moment_forge/combat/light_hit_grunt/<run-id> \
  --moment-capture-mode full
```

The implementation must build this command as an argument list, never a shell-concatenated string.

For `capture-mode none`, omit Movie Maker arguments and use a headless display driver where supported.

### 9.2 Bootstrap

Runner sequence:

1. Parse arguments.
2. Resolve output path and confirm containment.
3. Parse scenario.
4. Apply process-wide seed:
   - `seed(scenario.seed)`;
   - create named `RandomNumberGenerator` instances from deterministic derived seeds when fixtures require them.
5. Load scene.
6. Add scene to root.
7. Set `current_scene`.
8. Pause or disable target processing before role setup.
9. Resolve and spawn roles.
10. Remove scenario-excluded nodes.
11. Apply properties and transforms.
12. Disable uncontrolled role processing.
13. Configure fixture.
14. Wait declared warmup ticks.
15. Clear Developer Observatory.
16. Connect event/warning mirrors.
17. Begin scenario tick 0.

### 9.3 Tick Loop

At each scenario tick:

1. Set `current_tick`.
2. Execute scheduled pre-physics actions.
3. Allow one physics frame.
4. Collect post-physics probes.
5. Evaluate capture marker eligibility.
6. Await post-draw when a keyframe is required.
7. Save keyframe.
8. Record timeline entries.
9. Continue until `duration_ticks` or an explicit successful `finish`.

A runtime exception, missing required role, failed fixture command, or timeout enters failure cleanup.

### 9.4 Cleanup

Always:

- release all injected InputMap actions;
- disconnect Observatory signals;
- export Observatory when possible;
- write failure context;
- save action/probe timeline accumulated so far;
- close files;
- quit gracefully.

Cleanup must occur on success and failure.

### 9.5 Timeout

Each scenario declares `max_wall_seconds`. Python additionally enforces a hard process timeout:

```text
max(declared max_wall_seconds + 10 seconds, 30 seconds)
```

A timed-out process is terminated, logs are retained, and exit code 4 is returned.

---

## 10. Determinism Contract

### 10.1 Fixed Tick

V1 requires:

```json
"simulation": {
  "physics_hz": 60,
  "warmup_ticks": 6,
  "max_wall_seconds": 30
}
```

Any other `physics_hz` is schema-valid only when future schema versions permit it. V1 runtime rejects values other than 60.

### 10.2 Seed Derivation

Derived seeds use a stable hash:

```text
derived_seed = first_signed_63_bits(
  SHA-256("<scenario-seed>:<namespace>")
)
```

Namespaces include:

- `fixture`;
- `procgen`;
- `enemy:<role-id>`;
- `visual:<role-id>`.

Python and GDScript implementations must use the same documented derivation test vectors if both need to derive seeds.

### 10.3 Stable Fingerprint

`metrics.json` contains:

```json
{
  "stable_fingerprint": {
    "schema": "custodian.moment_forge.stable_fingerprint.v1",
    "algorithm": "sha256",
    "value": "<hex>"
  }
}
```

The fingerprint input includes only normalized stable evidence:

- scenario ID and schema version;
- duration tick;
- ordered successful action records;
- canonical event kind, scenario tick, and selected stable payload fields;
- selected counter values;
- selected probe values quantized by scenario tolerance;
- stable assertion outcomes;
- actor start/end positions and measured travel;
- warning count and canonical warning categories.

It excludes:

- run ID;
- paths;
- timestamps;
- wall-clock duration;
- engine FPS;
- process ID;
- git commit;
- dirty state;
- frame file hashes;
- audio metrics;
- visual metrics;
- non-deterministic Observatory metadata.

A scenario declares the stable event payload fields it expects. Unknown payload fields are retained in telemetry but excluded from the fingerprint.

### 10.4 Double-Run Requirement

The focused deterministic validation runs one minimal scenario twice and requires identical:

- stable fingerprint;
- action result sequence;
- event kind/tick sequence;
- assertion result sequence;
- normalized start/end probes.

Media file hashes are not required to match across graphics drivers.

### 10.5 Known Determinism Limits

The report must disclose:

- graphics backend;
- GPU/renderer;
- engine version;
- operating system;
- Movie Maker mode;
- whether visual hashes were compared on the same environment;
- whether audio source sample rate required conversion;
- whether the worktree was dirty.

Visual and audio evidence may vary by platform while gameplay evidence remains deterministic.

---

## 11. Scenario Contract

### 11.1 File Location and Identity

Scenario path:

```text
custodian/tools/iteration/scenarios/<scenario-id>.json
```

Example:

```text
scenario-id: combat/light_hit_grunt
path: custodian/tools/iteration/scenarios/combat/light_hit_grunt.json
```

The ID must exactly equal the relative path without `.json`.

ID pattern:

```regex
^[a-z0-9][a-z0-9_/-]*[a-z0-9]$
```

Additional rules:

- no `..`;
- no backslash;
- no repeated `//`;
- no leading or trailing slash;
- maximum 120 characters;
- file and ID must agree.

### 11.2 Top-Level Shape

```json
{
  "schema_version": 1,
  "id": "combat/light_hit_grunt",
  "description": "Operator fast strike against one stationary grunt.",
  "scene": "res://scenes/debug/combat_playground.tscn",
  "seed": 104729,
  "duration_ticks": 150,
  "simulation": {},
  "capture": {},
  "setup": {},
  "timeline": [],
  "probes": [],
  "assertions": [],
  "stable_fingerprint": {},
  "tags": []
}
```

### 11.3 Required Fields

| Field | Type | Requirement |
|---|---|---|
| `schema_version` | integer | exactly `1` |
| `id` | string | valid and path-matched |
| `description` | string | non-empty, max 300 chars |
| `scene` | string | existing `res://*.tscn` |
| `seed` | integer | signed 63-bit |
| `duration_ticks` | integer | 1–1800; first pack target ≤480 |
| `simulation` | object | required |
| `capture` | object | required |
| `setup` | object | required |
| `timeline` | array | required; may be empty |
| `probes` | array | required |
| `assertions` | array | required |
| `stable_fingerprint` | object | required |
| `tags` | array of strings | at least one |

### 11.4 `simulation`

```json
{
  "physics_hz": 60,
  "warmup_ticks": 6,
  "max_wall_seconds": 30,
  "pause_during_setup": true
}
```

### 11.5 `capture`

```json
{
  "width": 1280,
  "height": 720,
  "fps": 60,
  "audio": true,
  "start_tick": 0,
  "end_tick": 149,
  "contact_sheet_ticks": [0, 24, 30, 33, 36, 54],
  "required_keyframes": true,
  "background": "opaque"
}
```

Rules:

- V1 full capture is 1280×720 at 60 fps.
- `start_tick <= end_tick < duration_ticks`.
- contact ticks are unique, sorted, and in capture range.
- first scenario pack uses exactly six contact ticks.
- six 1280×720 frames produce a 3840×1440 3×2 contact sheet.
- transparent capture is allowed only for specialized future fixtures; initial gameplay moments use opaque capture.
- `audio: true` requests canonical `audio_mix.wav`.

### 11.6 `setup`

```json
{
  "remove_nodes": [
    "World/Enemies/EnemyGrunt2",
    "World/Enemies/EnemyGrunt3",
    "World/DroneManager"
  ],
  "roles": {
    "operator": {
      "node_path": "World/Operator",
      "required": true
    },
    "target": {
      "node_path": "World/Enemies/EnemyGrunt1",
      "required": true
    },
    "camera": {
      "node_path": "World/Camera2D",
      "required": true
    }
  },
  "spawns": [],
  "properties": [
    {
      "role": "operator",
      "property": "global_position",
      "value": [420, 360]
    },
    {
      "role": "target",
      "property": "global_position",
      "value": [474, 360]
    }
  ],
  "processing": [
    {
      "role": "target",
      "physics": false,
      "process": true
    }
  ],
  "fixture": {
    "id": "combat_playground",
    "config": {}
  }
}
```

#### Role Resolution

A role may be resolved by:

- `node_path` relative to loaded scene root;
- `group` plus an unambiguous selector;
- `spawn_id` from the scenario’s spawn list.

Ambiguous group resolution fails.

#### Spawns

```json
{
  "id": "target_marine",
  "scene": "res://game/actors/enemies/enemy_marine.tscn",
  "parent_role": "enemies_root",
  "role": "target",
  "position": [474, 360],
  "properties": {
    "behavior_state_machine_enabled": false
  }
}
```

Spawn rules:

- scene must exist;
- parent role must exist;
- role ID must be unique;
- properties must pass the property allowlist;
- spawned nodes are freed during cleanup.

#### Property Allowlist

Scenario setup may write only:

- transform properties;
- exported scalar/string/bool properties;
- documented fixture-safe resource/state properties;
- explicitly registered properties in the runner’s allowlist.

It may not write:

- script;
- owner;
- process callback internals;
- arbitrary Object references;
- NodePaths outside the loaded fixture;
- project settings;
- autoload internals.

The runner logs every applied setup property.

### 11.7 `timeline`

Example:

```json
[
  {
    "tick": 12,
    "action": "aim_at_role",
    "role": "target"
  },
  {
    "tick": 20,
    "action": "input_press",
    "name": "attack_primary"
  },
  {
    "tick": 21,
    "action": "input_release",
    "name": "attack_primary"
  },
  {
    "tick": 33,
    "action": "capture_marker",
    "name": "expected_contact"
  }
]
```

Rules:

- sorted by tick; validator may normalize stable source order but must reject decreasing ticks;
- duplicate ticks are allowed only for distinct actions;
- exact duplicate action records at one tick are rejected;
- unsupported InputMap actions fail preflight;
- every press must have a release unless the scenario ends and cleanup release is explicitly expected;
- release cleanup is recorded but does not make an authored missing release pass `no_unreleased_inputs`.

### 11.8 Fixture Commands

Some moments cannot be staged entirely through ordinary input without waiting for uncontrolled AI. V1 supports named fixture commands:

```json
{
  "tick": 30,
  "action": "fixture_command",
  "name": "begin_deterministic_grunt_attack",
  "args": {
    "target_role": "operator"
  }
}
```

Security and ownership rules:

- scenario JSON names a command, never a method;
- the loaded fixture exposes a fixed command registry;
- each command validates arguments;
- a fixture command may stage a public gameplay boundary or fixture-owned trigger;
- fixture commands must not duplicate gameplay result logic;
- fixture command implementation is dev-only;
- private method names beginning with `_` may not be exposed;
- every fixture command is documented in the fixture README or this spec;
- commands are used only where InputMap plus stable setup is insufficient.

Initial allowed fixture command families:

- `combat_playground.begin_deterministic_enemy_attack`;
- `combat_playground.set_target_guard_state`;
- `sundered_keep_world_vista.place_operator_at_reveal_progress`;
- `sundered_keep_world_vista.begin_walkthrough`.

If these cannot be implemented without duplicating gameplay authority, the associated scenario remains blocked rather than weakening the rule.

### 11.9 `probes`

Example:

```json
[
  {
    "id": "operator_transform",
    "role": "operator",
    "fields": ["global_position", "velocity", "animation", "frame"],
    "ticks": [0, 20, 33, 54, 149],
    "required": true
  },
  {
    "id": "target_health",
    "role": "target",
    "fields": ["health", "global_position", "animation", "frame"],
    "ticks": [0, 32, 33, 54, 149],
    "required": true
  }
]
```

A probe may use:

- explicit ticks;
- `every_ticks`;
- `start_tick` and `end_tick`;
- event-relative sampling in a future schema, not V1.

### 11.10 `assertions`

Supported V1 assertions:

#### Event Count

```json
{
  "type": "event_count",
  "event": "canonical_event_name",
  "exact": 1
}
```

Supports `exact`, `min`, and `max`.

#### Warning Count

```json
{
  "type": "warning_count",
  "max": 0
}
```

#### Counter Value

```json
{
  "type": "counter_value",
  "counter": "player_melee_hits",
  "op": ">=",
  "value": 1
}
```

#### Probe Compare

```json
{
  "type": "probe_compare",
  "probe": "target_health",
  "tick": 54,
  "field": "health",
  "op": "<",
  "value_from": {
    "probe": "target_health",
    "tick": 0,
    "field": "health"
  }
}
```

#### Metric Compare

```json
{
  "type": "metric_compare",
  "metric": "actors.operator.travel_px",
  "op": "<=",
  "value": 40.0,
  "tolerance": 0.25
}
```

#### Role Exists

```json
{
  "type": "role_exists",
  "role": "operator"
}
```

#### No Unreleased Inputs

```json
{
  "type": "no_unreleased_inputs"
}
```

#### Output Exists

```json
{
  "type": "output_exists",
  "path": "telemetry.json"
}
```

#### Event Order

```json
{
  "type": "event_order",
  "events": [
    "attack_started",
    "damage_applied",
    "enemy_reaction_started"
  ],
  "allow_same_tick": true
}
```

Exact event names for the first scenario pack must be taken from the live instrumentation during implementation. The scenario must not invent an event name merely to satisfy this document. Where current telemetry lacks a stable event required to prove a moment, add observability-only instrumentation through `DevObservatory` at the authoritative outcome boundary and update the Observatory design document in the same change.

### 11.11 `stable_fingerprint`

```json
{
  "event_payload_fields": {
    "player_melee_hit": [
      "attack_id",
      "target_id",
      "attempted_damage",
      "applied_damage",
      "strength"
    ]
  },
  "counters": [
    "player_melee_hits",
    "warnings"
  ],
  "probes": [
    "operator_transform",
    "target_health"
  ],
  "position_quantum_px": 0.01,
  "float_quantum": 0.0001
}
```

Payload fields that contain unstable instance IDs must be normalized to scenario role IDs where possible.

### 11.12 `tags`

Tag rules:

- lowercase snake case;
- no freeform spaces;
- stable across file moves;
- at least one domain tag and one behavior/content tag where possible.

Examples:

```json
[
  "combat",
  "melee",
  "fast_attack",
  "hit_light",
  "operator_animation",
  "grunt",
  "combat_audio",
  "combat_vfx"
]
```

---

## 12. Schema Validation

`moment_schema.json` is the machine-readable authority for scenario shape.

Python validation must additionally perform repository-aware checks that JSON Schema alone cannot prove:

- scenario ID matches path;
- scene exists;
- spawned scenes exist;
- capture/output paths are contained;
- role IDs are unique;
- timeline is ordered;
- duplicate action records do not exist;
- every contact tick is valid;
- required InputMap actions exist, using a generated or parsed action index;
- fixture ID is supported by the selected scene;
- assertion references point to defined probes;
- stable fingerprint references point to defined evidence;
- scenario duration is sufficient for all timeline/probe/capture ticks.

Malformed scenarios fail before Godot is launched.

---

## 13. Capture Contract

### 13.1 Resolution and Frame Rate

V1 review capture:

```text
Frame size: 1280×720
Frame rate: 60 fps
Color: opaque gameplay frame
Duration: 2–8 seconds preferred; 30 seconds hard V1 ceiling
```

The dimensions match the current project viewport. The runner must verify the root viewport size and either:

- set a development-only runtime window override for the process; or
- fail if the requested capture does not match the active viewport.

It must not persist a project setting change.

### 13.2 Full-Run Capture

Godot Movie Maker is the capture source for:

- full frame sequence;
- synchronized WAV.

Use PNG-sequence output as canonical evidence:

```text
raw/capture00000001.png
raw/capture00000002.png
...
raw/capture.wav
```

Benefits:

- exact frame availability;
- no lossy intermediate;
- straightforward keyframe validation;
- no dependency on video decoding for visual metrics;
- audio generated by the same fixed-frame run.

### 13.3 Exact Keyframes

At each selected tick:

1. gameplay physics for the tick completes;
2. draw completes;
3. `moment_capture.gd` obtains the viewport image;
4. image is saved as `keyframes/tick_<six-digits>.png`;
5. SHA-256, width, height, and render-frame index are recorded.

These keyframes, not decoded MP4 frames, feed contact sheets and visual diffs.

### 13.4 Contact Sheet

Initial scenario pack:

```text
Frames: 6
Individual frame: 1280×720
Grid: 3 columns × 2 rows
Final image: 3840×1440
```

Each cell includes a non-destructive report label strip or overlay containing:

- scenario tick;
- elapsed milliseconds;
- marker name if present;
- first relevant event at that tick.

Labels must not modify the standalone keyframe files.

### 13.5 Audio

Canonical review audio:

```text
Path: audio_mix.wav
Format: PCM WAV
Sample rate: 48 kHz
Channels: stereo
```

The raw Movie Maker WAV is inspected. If it is not 48 kHz stereo:

- preserve raw WAV metadata in manifest;
- convert to canonical `audio_mix.wav` with FFmpeg when available;
- without FFmpeg, retain raw WAV and mark canonical conversion unavailable;
- do not mislabel the raw file as 48 kHz.

Audio metrics:

- duration;
- sample rate;
- channels;
- peak dBFS;
- RMS dBFS;
- first onset above configured threshold;
- peak sample time;
- optional integrated loudness when FFmpeg support exists.

Default onset threshold:

```text
max(noise-floor estimate + 12 dB, -42 dBFS)
```

Scenarios may override the advisory threshold.

### 13.6 MP4

Preferred review output:

```text
1280×720
60 fps
H.264
yuv420p
AAC or PCM-derived audio
```

Illustrative conversion:

```bash
ffmpeg \
  -framerate 60 \
  -i raw/capture%08d.png \
  -i audio_mix.wav \
  -c:v libx264 \
  -pix_fmt yuv420p \
  -crf 18 \
  -c:a aac \
  -b:a 192k \
  -shortest \
  current.mp4
```

FFmpeg availability is:

- required only when `--require-mp4` is passed;
- otherwise a warning;
- never a reason to discard keyframes, WAV, telemetry, or report;
- recorded in `manifest.json`.

The HTML report falls back to a keyframe scrubber when MP4 is unavailable.

### 13.7 Video Trim and Timeline Origin

Movie Maker may capture bootstrap frames before scenario tick 0. Runner records:

- first scenario render frame;
- last scenario render frame;
- capture-start process frame;
- tick-to-render-frame mapping.

The report builder trims MP4 and audio to scenario capture bounds. It must validate that the observed raw frame count is consistent with the mapping. If it cannot prove the mapping, it leaves the untrimmed media available, marks synchronization degraded, and fails `--require-synchronized-media`.

---

## 14. Developer Observatory Integration

### 14.1 Existing Authority

Moment Forge uses the existing `/root/DevObservatory`.

At scenario start:

```gdscript
var observatory := get_root().get_node_or_null("DevObservatory")
observatory.clear()
observatory.event_logged.connect(_on_observatory_event)
observatory.warning_logged.connect(_on_observatory_warning)
```

At completion:

```gdscript
observatory.export_session_json(
    "<run-output>/telemetry.json"
)
```

Exact call shape must use the live API.

### 14.2 Tick-Enriched Timeline

Developer Observatory events carry runtime time, not authored scenario tick. Moment Forge therefore records a parallel observation envelope:

```json
{
  "scenario_tick": 33,
  "physics_frame": 128,
  "kind": "player_melee_hit",
  "data": {},
  "observed_order": 17
}
```

This envelope mirrors the signal. It does not replace or rewrite `telemetry.json`.

### 14.3 No Feedback

Moment Forge may assert on Observatory evidence after the authoritative event occurs. Gameplay code may not read Moment Forge or Observatory results to choose outcomes.

### 14.4 Instrumentation Gaps

When a scenario cannot prove a stable fact:

1. locate the authoritative outcome boundary;
2. add a low-frequency `DevObservatory.log_event`, counter, or gauge;
3. use canonical role/attack identifiers already present;
4. avoid per-frame event spam;
5. update `DEVELOPER_OBSERVATORY_SYSTEM.md`;
6. extend focused Observatory smoke coverage;
7. keep instrumentation disabled outside DevMode eligibility.

---

## 15. Metrics Contract

`metrics.json` schema:

```text
custodian.moment_forge.metrics.v1
```

### 15.1 Run Metrics

- scenario duration ticks and seconds;
- actual completed tick;
- wall-clock process duration;
- raw frame count;
- keyframe count;
- audio duration;
- warning count;
- assertion pass/fail count;
- Observatory event count;
- event-buffer saturation status.

### 15.2 Event Metrics

For each selected event kind:

- count;
- first tick;
- last tick;
- ordered tick list;
- minimum/maximum inter-event tick distance.

### 15.3 Actor Metrics

For selected roles:

- start position;
- end position;
- net displacement;
- integrated travel;
- maximum speed;
- first movement tick;
- health delta;
- stamina delta;
- animation state changes;
- frame at selected markers.

Travel is computed from post-physics probes:

```text
travel_px = Σ distance(position[t], position[t-1])
```

### 15.4 Timing Metrics

Examples:

- input press to attack start;
- attack start to damage event;
- damage event to reaction start;
- damage event to hitstop marker;
- damage event to visual FX onset;
- damage event to audio onset;
- Field Patch input to commit;
- reveal envelope entry to apex;
- apex to handback.

Scenarios declare event/marker pairs rather than report code hard-coding scenario-specific names.

### 15.5 Visual Metrics

For corresponding baseline/current keyframes:

- exact dimensions;
- per-channel mean absolute difference;
- changed-pixel ratio above threshold;
- alpha changed-pixel ratio;
- luminance mean and delta;
- perceptual hash distance;
- non-transparent bounding box;
- bounding-box center delta;
- changed-pixel bounding box;
- optional edge-map difference.

Default pixel threshold:

```text
8 / 255 per RGB channel
```

All visual metrics are advisory.

### 15.6 Audio Metrics

For baseline/current:

- onset delta in milliseconds;
- peak-time delta;
- peak-level delta in dB;
- RMS delta in dB;
- duration delta;
- cross-correlation lag estimate within ±250 ms.

All audio metrics are advisory.

---

## 16. Assertions and Run Status

### 16.1 Status Values

A run status is one of:

- `passed`;
- `failed_schema`;
- `failed_preflight`;
- `failed_runtime`;
- `failed_assertions`;
- `failed_report`;
- `baseline_incompatible`;
- `partial_media`;
- `cancelled`.

`partial_media` may still have passing stable assertions. CLI exit remains nonzero only when the caller required the missing media.

### 16.2 Assertion Severity

Assertions support:

```json
"severity": "error"
```

Values:

- `error`: fails run;
- `warning`: appears prominently but does not fail;
- `info`: recorded only.

Visual/audio threshold checks are forced to `warning` or `info` in schema version 1.

### 16.3 Stable Assertions

Suitable hard assertions:

- exact damage-event count;
- no player damage;
- target health decreased;
- one patch consumed;
- healing occurred only at commit;
- one parry success;
- no runtime warnings;
- no unreleased inputs;
- one reveal completion event;
- expected role exists;
- scenario completed;
- output written under permitted root.

Unsuitable hard assertions:

- “looks heavier”;
- exact changed-pixel percentage;
- exact dB peak;
- artistic brightness;
- exact MP4 file hash;
- GPU-rendered frame hash.

---

## 17. Baseline Contract

### 17.1 Baseline Contents

A baseline retains:

- manifest;
- scenario snapshot;
- metrics;
- assertions;
- timeline;
- telemetry;
- keyframes;
- contact sheet;
- audio;
- MP4 when available;
- provenance.

Full raw PNG sequence is optional.

### 17.2 Compatibility Key

Baseline compatibility requires equality of:

- scenario ID;
- scenario `schema_version`;
- scenario content hash unless scenario explicitly declares backward-compatible comparison;
- capture width;
- capture height;
- capture fps;
- capture tick range;
- contact-sheet tick list;
- keyframe count;
- metrics schema major version.

### 17.3 Baseline Provenance

```json
{
  "baseline_name": "approved-v1",
  "accepted_at": "2026-07-28T...",
  "source_run_id": "...",
  "git": {
    "commit": "...",
    "branch": "main",
    "dirty": false
  },
  "review_note": ""
}
```

### 17.4 No Automatic Approval

A passing run is not automatically a new baseline. Baseline acceptance is an explicit developer judgment.

---

## 18. Changed-File Routing

### 18.1 Configuration

Path:

```text
custodian/tools/iteration/changed_file_routes.json
```

Example:

```json
{
  "schema_version": 1,
  "rules": [
    {
      "id": "combat_audio",
      "include": [
        "custodian/content/audio/sfx/combat/**/*.wav",
        "custodian/game/**/audio*.gd"
      ],
      "tags": ["combat_audio"],
      "priority": 70,
      "reason": "Combat audio changed."
    },
    {
      "id": "operator_fast_attack_east_west",
      "include": [
        "custodian/content/sprites/operator/**/fast_*__e__*.png",
        "custodian/content/sprites/operator/**/fast_*__w__*.png",
        "custodian/game/actors/operator/**/*.gd"
      ],
      "tags": ["fast_attack", "operator_animation"],
      "priority": 90,
      "reason": "Operator fast-attack presentation or authority changed."
    },
    {
      "id": "sundered_keep_world_vista",
      "include": [
        "custodian/game/world/vistas/sundered_keep/**",
        "custodian/content/backgrounds/sundered_keep/**",
        "design/05_levels/SUNDERED_KEEP_WORLD_VISTA.md"
      ],
      "scenario_ids": ["vista/sundered_keep_first_reveal"],
      "priority": 100,
      "reason": "Sundered Keep world-Vista behavior or art changed."
    }
  ]
}
```

### 18.2 Matching

- Git paths are normalized to `/`.
- `include` uses repository-root globs.
- optional `exclude` globs remove generated/import files.
- explicit scenario IDs outrank tag matches.
- score is sum of matched priority plus specificity bonus.
- reasons are retained per match.
- scenario tags are read from validated scenario files.

### 18.3 Default Exclusions

Exclude:

```text
reports/**
custodian/.godot/**
**/*.import
.ai/**
tmp/**
```

unless a rule explicitly includes them.

### 18.4 Output

```text
Changed:
- custodian/content/audio/sfx/combat/hit_light_body_02.wav

Suggested:
1. combat/light_hit_grunt
   score: 140
   reason: Combat audio changed; tags: combat_audio, hit_light
   run: python3 custodian/tools/iteration/run_moment.py combat/light_hit_grunt

2. combat/fast_combo_three_hits
   score: 95
   reason: Combat audio changed; tags: combat_audio
```

### 18.5 Router Limits

The router is advisory. A path match does not prove behavior impact. The report must identify why each scenario was suggested.

---

## 19. HTML Report

### 19.1 Requirements

The report is:

- self-contained;
- usable from `file://`;
- network-free;
- keyboard accessible;
- readable at desktop widths;
- explicit about partial or incompatible evidence;
- linked to exact local source paths as text;
- safe against unescaped scenario descriptions or event payloads.

### 19.2 Header

Show:

- scenario ID and description;
- run status;
- baseline name/status;
- commit and branch;
- dirty state;
- scenario hash;
- engine/renderer;
- capture mode;
- timestamp;
- report schema;
- warnings.

### 19.3 Synchronized Media

When MP4 exists:

```text
BASELINE                         CURRENT
[synchronized video]            [synchronized video]
```

Controls:

- shared play/pause;
- shared scrubber;
- frame-step backward/forward;
- playback speed;
- loop;
- jump to marker/event;
- audio source selection: baseline/current/mute.

When MP4 is unavailable, use synchronized keyframe panels and event jumps.

### 19.4 Timeline

Rows include:

- tick;
- elapsed time;
- input action;
- gameplay event;
- marker;
- warning;
- selected role animation/frame;
- audio onset/peak;
- assertion result.

### 19.5 Metric Deltas

Example:

```text
Damage application          unchanged
Impact audio onset          +8.0 ms
Impact VFX keyframe         exact authored tick
Operator travel             +5.4 px
Enemy displacement          +2.1 px
Hitstop duration            unchanged
Peak audio                  +2.8 dB
Animation completion        +1 tick
Warnings                    0
```

No delta uses “better” or “worse” automatically unless the scenario defines a stable directional expectation.

### 19.6 Contact Sheets and Diff

Display:

- baseline contact sheet;
- current contact sheet;
- visual diff;
- per-keyframe metrics;
- toggleable alpha bounding box;
- toggleable changed-pixel bounding box;
- luminance summary.

### 19.7 Assertion Summary

Separate:

- failed errors;
- warnings;
- passed stable assertions;
- advisory media observations.

---

## 20. Manifest Contract

`manifest.json` schema:

```text
custodian.moment_forge.run_manifest.v1
```

Minimum payload:

```json
{
  "schema": "custodian.moment_forge.run_manifest.v1",
  "run_id": "20260728T173500-0400_f25ee5f",
  "status": "passed",
  "scenario": {
    "id": "combat/light_hit_grunt",
    "schema_version": 1,
    "path": "custodian/tools/iteration/scenarios/combat/light_hit_grunt.json",
    "sha256": "<hex>"
  },
  "repository": {
    "root": "<absolute local path>",
    "commit": "f25ee5f...",
    "branch": "main",
    "dirty": true,
    "changed_files": []
  },
  "runtime": {
    "godot_version": {},
    "renderer": "",
    "display_driver": "",
    "physics_hz": 60
  },
  "capture": {
    "mode": "full",
    "width": 1280,
    "height": 720,
    "fps": 60,
    "audio_requested": true,
    "synchronization": "verified"
  },
  "artifacts": {
    "telemetry": "telemetry.json",
    "metrics": "metrics.json",
    "audio": "audio_mix.wav",
    "video": "current.mp4",
    "contact_sheet": "current_contact_sheet.png",
    "report": "index.html"
  },
  "tools": {
    "python": "",
    "pillow": "",
    "ffmpeg": {
      "available": true,
      "version": ""
    }
  }
}
```

Absolute local paths may appear in `manifest.json` for provenance, but generated HTML should prefer repository-relative paths and escape all values.

---

## 21. First Scenario Pack

The first pack is an implementation requirement, not a placeholder list.

### 21.1 `combat/light_hit_grunt`

**Path**

```text
custodian/tools/iteration/scenarios/combat/light_hit_grunt.json
```

**Scene**

```text
res://scenes/debug/combat_playground.tscn
```

**Setup**

- keep `World/Operator`;
- keep one grunt;
- remove the two other grunts;
- remove or disable `DroneManager`;
- position Operator and grunt within fast-strike range;
- disable grunt physics processing so it remains stationary but can receive authoritative damage/reaction;
- clear active target noise;
- aim east;
- use unarmed or the explicitly selected live light-hit loadout;
- preserve actual gameplay collision and damage authority.

**Timeline**

- aim at target;
- press/release the live primary attack InputMap action;
- capture startup, pre-contact, contact, immediate follow-through, reaction, and settle.

**Stable Assertions**

- one authoritative player melee damage result;
- target health decreases;
- player health unchanged;
- no more than one damage application;
- no warnings;
- all inputs released;
- scenario completes.

**Advisory Metrics**

- input-to-contact ticks;
- Operator travel;
- grunt displacement;
- reaction start;
- audio onset;
- visual impact onset;
- animation completion.

**Capture**

```text
1280×720, 60 fps, 6 keyframes, 3840×1440 contact sheet
```

### 21.2 `combat/heavy_hit_grunt`

**Path**

```text
custodian/tools/iteration/scenarios/combat/heavy_hit_grunt.json
```

**Scene**

```text
res://scenes/debug/combat_playground.tscn
```

**Setup**

Same isolation as light hit, with sufficient stamina and the live heavy-input contract.

**Stable Assertions**

- exactly one heavy damage application;
- target enters the expected heavy stagger/knockdown class when the live threshold contract requires it;
- player damage remains zero;
- stamina spends once;
- no duplicate contact;
- no warnings.

**Advisory Metrics**

- windup ticks;
- active/contact tick;
- Operator attack displacement;
- target knockback/displacement;
- hitstop;
- camera response;
- impact audio.

### 21.3 `combat/light_hit_marine_deflect`

**Path**

```text
custodian/tools/iteration/scenarios/combat/light_hit_marine_deflect.json
```

**Scene**

```text
res://scenes/debug/combat_playground.tscn
```

**Setup**

- remove all grunts;
- spawn `res://game/actors/enemies/enemy_marine.tscn`;
- disable uncontrolled marine AI after fixture setup;
- stage the marine in its actual light-hit resistance/deflect state through a fixture command that delegates to a public runtime boundary;
- position within attack range.

**Stable Assertions**

- light hit resolves through the intended resisted/deflected outcome;
- no unintended full flinch;
- damage and guard/poise outcome match the live taxonomy;
- no player damage;
- one contact;
- no warnings.

**Advisory Metrics**

- armor/deflect audio onset;
- flash onset;
- Operator recoil;
- marine displacement;
- contact readability.

**Blocking Rule**

If no public boundary can stage the deflect state without duplicating result logic, this scenario remains `blocked` in its task packet until that public dev-fixture boundary is added. Do not call a private method from JSON.

### 21.4 `combat/parry_success`

**Path**

```text
custodian/tools/iteration/scenarios/combat/parry_success.json
```

**Scene**

```text
res://scenes/debug/combat_playground.tscn
```

**Setup**

- one grunt;
- no drones or other enemies;
- deterministic attack start through the combat fixture;
- live Operator parry input;
- actual contact geometry;
- no direct call that applies parry success.

**Timeline**

- start deterministic grunt attack;
- press/release the live parry action at the authored tick;
- capture pre-window, active window, contact, success burst, critical-open enter, and hold.

**Stable Assertions**

- one parry started;
- one parry success;
- zero player damage;
- one parry success audio cue;
- one world-space parry success burst;
- grunt enters critical-open flow;
- no duplicate ordinary hit resolution;
- no warnings.

**Advisory Metrics**

- parry input to active;
- attack contact to burst;
- burst to critical-open enter;
- audio onset;
- flash keyframe;
- enemy movement.

### 21.5 `healing/field_patch_commit`

**Path**

```text
custodian/tools/iteration/scenarios/healing/field_patch_commit.json
```

**Scene**

```text
res://scenes/debug/combat_playground.tscn
```

**Setup**

- remove enemies and drone;
- Operator max health 100;
- Operator current health 50;
- one carried Field Patch;
- default live 1.25-second use duration;
- camera centered;
- no damage interruption.

**Timeline**

- press/release `use_field_patch`;
- capture start, early channel, pre-commit, commit, immediate recovery, settle.

**Stable Assertions**

- patch begins;
- health remains 50 before commit;
- count remains 1 before commit;
- exactly one patch consumed at commit;
- health becomes the live expected committed value;
- no second heal;
- no interruption;
- no warnings.

**Advisory Metrics**

- input to animation start;
- input to audio onset;
- input to healing commit;
- animation/audio/heal alignment;
- UI prompt transition.

### 21.6 `vista/sundered_keep_first_reveal`

**Path**

```text
custodian/tools/iteration/scenarios/vista/sundered_keep_first_reveal.json
```

**Scene**

```text
res://scenes/debug/moment_forge/sundered_keep_world_vista_moment.tscn
```

**Fixture Requirements**

- instantiate the real procgen map and Sundered Keep world-Vista scene;
- use a fixed production-sized seed;
- claim the same authored overlook pocket required by production;
- instantiate a visible real Operator or production-equivalent rendered stand-in;
- use the real shared camera script;
- preserve production reveal controller logic;
- drive progress by Operator physical position, not direct alpha edits;
- include no route traversal;
- keep procgen active;
- expose no collision or gameplay authority from the Vista.

**Timeline**

- start before influence;
- move Operator through influence start;
- pass reveal apex;
- enter return;
- complete handback.

**Stable Assertions**

- authored pocket is claimed;
- procgen remains active;
- Operator remains in the same world;
- no route starts;
- camera influence becomes nonzero and returns to zero;
- reveal completion occurs once;
- camera follow/bounds authority is restored;
- no warnings.

**Advisory Metrics**

- Keep alpha progression;
- fog alpha/peel progression;
- moonlight peak;
- camera zoom and offset;
- Operator lower-quarter framing;
- visible image-boundary detection;
- reveal audio/music transition;
- apex contact sheet.

**Capture**

```text
1280×720 at 60 fps for Moment Forge
```

The existing 1920×1080 multi-seed Vista review remains a separate composition tool. Moment Forge validates one repeatable walkthrough; it does not replace the eight-seed review.

---

## 22. Report Asset Specifications

No new production game art is required for Moment Forge V1.

Generated review assets:

| Asset | Repository-Relative Output | Dimensions / Format | Frame Count |
|---|---|---|---:|
| Current keyframe | `reports/moment_forge/<id>/<run>/keyframes/tick_*.png` | 1280×720 PNG | authored |
| Contact sheet | `.../current_contact_sheet.png` | 3840×1440 PNG | 6 cells |
| Baseline sheet | `.../baseline_contact_sheet.png` | 3840×1440 PNG | 6 cells |
| Visual diff | `.../visual_diff.png` | 3840×1440 PNG by default | 6 cells |
| Raw sequence | `.../raw/capture%08d.png` | 1280×720 PNG | duration × 60 |
| Review video | `.../current.mp4` | 1280×720, 60 fps H.264 | duration × 60 |
| Review audio | `.../audio_mix.wav` | 48 kHz stereo PCM WAV | n/a |
| Report | `.../index.html` | responsive local HTML | n/a |

The Vista debug fixture may need a visible Operator stand-in only if the real Operator cannot be instantiated safely. Preferred path:

```text
custodian/scenes/debug/moment_forge/sundered_keep_world_vista_moment.tscn
```

Any stand-in must be a scene node using existing runtime sprite resources. Do not create a new PNG solely for the fixture unless the production Operator cannot render in the isolated scene. If a new review-only sprite becomes unavoidable:

```text
custodian/content/sprites/debug/moment_forge/
└── operator_stand_in__idle__s__1f__96.png
```

Specifications:

```text
Frame: 96×96
Frames: 1
Background: transparent
Use: debug fixture only
```

That asset must be tracked in `REQUIRED_ASSETS.md` as review-only and must not be used by gameplay.

---

## 23. Error Handling and Exit Codes

| Exit | Meaning |
|---:|---|
| 0 | requested operation completed and all required assertions/media passed |
| 2 | CLI or scenario schema error |
| 3 | environment/preflight failure |
| 4 | Godot runtime failure or timeout |
| 5 | stable assertion or deterministic-repeat failure |
| 6 | report-generation failure |
| 7 | baseline incompatible |
| 8 | requested media unavailable or synchronization unverified |
| 130 | interrupted by user |

Every nonzero exit prints:

- scenario ID;
- stage;
- concise reason;
- retained run directory;
- log path;
- next diagnostic command.

A failure must not delete partial evidence.

---

## 24. Security and Path Safety

### 24.1 Output Containment

Default output root:

```text
<repo>/reports/moment_forge
```

Resolve paths with `Path.resolve()` and require containment. External output requires:

```bash
--allow-external-output
```

Godot independently checks its globalized output path against the repository report root supplied by Python.

### 24.2 Scenario Safety

Reject:

- `..`;
- absolute paths where `res://` is required;
- unsupported scene extensions;
- arbitrary method names;
- arbitrary script paths;
- duplicate role IDs;
- role paths escaping current scene;
- fixture command not registered by fixture;
- property not allowlisted;
- output path under runtime content.

### 24.3 HTML Escaping

All scenario text, paths, events, payload values, and assertion messages are HTML-escaped before embedding. JSON embedded in HTML uses a safe serialization that escapes `</script>`.

### 24.4 Subprocess Safety

- use argument arrays;
- do not use `shell=True`;
- log the argument array to `logs/command.json`;
- redact environment secrets;
- inherit only required environment variables;
- allow a custom Godot binary only through an explicit CLI option or environment variable.

---

## 25. Performance and Storage Budgets

### 25.1 Runtime

- preferred scenario duration: 120–480 ticks;
- maximum V1 scenario duration: 1800 ticks;
- default process timeout: 30 seconds plus setup allowance;
- full capture runs non-real-time and may take longer than scenario duration;
- no full-tree sampling beyond existing Observatory behavior;
- role probes are scoped and authored, not recursive by default.

### 25.2 Storage

A 1280×720 lossless PNG sequence can be large. Therefore:

- `--keep-raw` is opt-in;
- keyframes, WAV, metrics, telemetry, and report are retained;
- MP4 is preferred for long-term visual review;
- baseline raw sequence is optional;
- report generation prints retained size;
- no automatic deletion outside the current run directory;
- future cleanup tooling may prune non-baseline runs but is not V1 scope.

### 25.3 Observatory Capacity

Scenario design should avoid saturating the current bounded Observatory event ring. If a scenario saturates it:

- manifest records saturation;
- stable assertions relying on missing retained events fail;
- cumulative counters may still be reported;
- increasing the global ring solely for Moment Forge is not the default fix;
- reduce event noise or use targeted counters.

---

## 26. Dependencies

### 26.1 Required

- Python 3.11+ or repository-supported Python version;
- Godot executable compatible with the project;
- Pillow;
- standard library modules only beyond Pillow for core report generation;
- git for provenance and changed-file routing.

### 26.2 Optional

- FFmpeg for:
  - H.264 MP4;
  - audio resampling;
  - extended loudness metrics.
- a graphical/display environment for renderer-backed full capture.

### 26.3 Dependency Preflight

```text
Godot missing             hard failure
Pillow missing            hard failure for evidence/full report
Git missing               warning for direct run; failure for --changed
FFmpeg missing            warning unless --require-mp4
Display unavailable       failure for full mode; suggest evidence mode
```

No Python package may be auto-installed by the CLI.

---

## 27. File-by-File Implementation Contract

### `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md`

- active authority;
- copy this specification;
- update status as slices land;
- maintain `Next Agent Slice`.

### `custodian/docs/ai_context/task_packets/MOMENT_FORGE_V1.md`

- full packet;
- track phases, blockers, exact validation, and deferred work;
- link this spec as authority.

### `custodian/tools/iteration/run_moment.py`

- CLI and orchestrator;
- no report internals beyond delegation;
- testable pure helpers for path and command construction.

### `custodian/tools/iteration/build_moment_report.py`

- report schema;
- image/audio metrics;
- baseline comparison;
- HTML emitter;
- optional FFmpeg wrapper.

### `custodian/tools/iteration/changed_file_router.py`

- pure route matching;
- subprocess git adapter separated from matching logic.

### `custodian/tools/iteration/moment_schema.json`

- JSON Schema Draft 2020-12 or repository-supported validator contract;
- no network `$ref`;
- versioned `$id` string without remote dependency.

### `custodian/tools/iteration/changed_file_routes.json`

- readable rules;
- no path logic hard-coded into Python except universal exclusions.

### `custodian/tools/iteration/godot/moment_runner.gd`

- SceneTree runner;
- orchestration only;
- split components when file grows beyond practical ownership.

### `moment_action_driver.gd`

- deterministic pre-physics input and fixture commands;
- held-input cleanup.

### `moment_capture.gd`

- post-draw keyframe capture;
- tick/frame mapping.

### `moment_probe_collector.gd`

- role probe registry and sampling.

### `moment_assertion_evidence.gd`

- runtime evidence only;
- no media comparison.

### Vista Fixture

- production components;
- fixed seed;
- visible Operator;
- public configuration;
- no copied reveal logic.

### Validation Files

- standard-library temporary directories;
- no writes to source content;
- deterministic and renderer paths separated.

---

## 28. Implementation Phases

### Phase 0 — Authority and Drift Setup

Deliver:

- active spec at final path;
- full task packet;
- documentation-drift check;
- current path references;
- no runtime code yet.

Acceptance:

- active design path is under `design/02_features/`;
- no new `design/20_features/` reference;
- task packet links correct authority;
- doc-only path checks pass.

### Phase 1 — Scenario, CLI, and Headless Runtime Core

Deliver:

- schema;
- `--list`;
- one valid scenario;
- SceneTree runner;
- fixed-tick action driver;
- role setup;
- Observatory export;
- probes;
- stable assertions;
- capture mode `none`;
- deterministic double-run smoke.

Initial scenario:

```text
healing/field_patch_commit
```

This is the best first runtime fixture because it has a bounded, already-smoked commit contract and does not require enemy AI.

Acceptance:

- scenario validates;
- malformed variants fail preflight;
- two runs have identical stable fingerprints;
- normal game boot unchanged;
- output remains under reports.

### Phase 2 — Exact Keyframes and Report

Deliver:

- capture mode `evidence`;
- post-draw keyframes;
- metrics;
- contact sheet;
- self-contained report;
- synthetic report smoke;
- current-only report.

Acceptance:

- six 1280×720 frames create 3840×1440 sheet;
- keyframe tick mapping is verified;
- report opens without network;
- malformed/missing evidence fails clearly.

### Phase 3 — Movie Maker Audio/Video

Deliver:

- capture mode `full`;
- PNG sequence and WAV;
- audio metrics;
- optional MP4;
- synchronization contract;
- raw cleanup flag;
- renderer smoke.

Acceptance:

- full run captures expected frame count;
- audio duration aligns within one video frame plus audio buffer tolerance;
- keyframes match corresponding raw sequence frames where mapping is available;
- missing FFmpeg degrades gracefully.

### Phase 4 — Combat Scenarios

Deliver:

- light hit;
- heavy hit;
- parry success;
- marine deflect;
- fixture command registry;
- stable combat assertions;
- Observatory instrumentation gaps addressed.

Acceptance:

- each scenario runs twice deterministically;
- actual gameplay damage/parry/deflect boundaries are used;
- no JSON-private-method calls;
- no extra enemies/drones influence runs.

### Phase 5 — Vista Scenario and Baselines

Deliver:

- Vista fixture;
- reveal scenario;
- baseline compare;
- visual diff;
- baseline acceptance;
- synchronized media panes.

Acceptance:

- production reveal logic is used;
- fixed seed and authored pocket;
- camera hands back;
- no route begins;
- contact sheet covers the complete reveal arc.

### Phase 6 — Changed-File Routing and Documentation

Deliver:

- changed routing config;
- `--changed`;
- `--base`;
- explicit suggested execution;
- tooling router;
- validation recipes;
- current state;
- file index;
- README;
- task packet completion/deferred notes.

Acceptance:

- representative combat audio, Operator animation, and Vista paths select expected scenarios;
- generated paths are excluded;
- no scenario runs silently;
- docs point to existing files and commands.

---

## 29. Validation Plan

### 29.1 Python Syntax

```bash
python3 -m py_compile \
  custodian/tools/iteration/run_moment.py \
  custodian/tools/iteration/build_moment_report.py \
  custodian/tools/iteration/changed_file_router.py
```

### 29.2 Schema Smoke

```bash
python3 custodian/tools/validation/moment_forge_schema_smoke.py
```

Must prove rejection of:

- malformed ID;
- path/ID mismatch;
- missing scene;
- invalid `res://` path;
- duplicate exact action;
- decreasing tick;
- out-of-range capture tick;
- invalid dimensions;
- unsupported action;
- missing probe reference;
- unregistered fixture command;
- output path traversal.

### 29.3 Changed Router Smoke

```bash
python3 custodian/tools/validation/moment_forge_changed_router_smoke.py
```

Synthetic cases:

- combat WAV → light/heavy/parry candidates;
- Operator fast attack E/W strip → matching fast-attack scenarios;
- Sundered Keep Vista asset → reveal scenario;
- generated report file → no suggestion;
- unrelated doc → no false high-priority scenario;
- multiple matched rules → deduplicated ranked result.

### 29.4 Report Smoke

```bash
python3 custodian/tools/validation/moment_forge_report_smoke.py
```

Use generated synthetic 1280×720 PNGs and a short WAV. Validate:

- 3840×1440 contact sheet;
- visual diff;
- escaped HTML;
- no external script/style link;
- baseline incompatibility;
- advisory metric output;
- missing FFmpeg fallback;
- manifest/report consistency.

### 29.5 Runtime Smoke

From `custodian/`:

```bash
env HOME=/tmp/custodian-godot-home \
godot --headless --path . \
  --script res://tools/validation/moment_forge_runtime_smoke.gd
```

Proves:

- runner components parse;
- fixed tick order;
- action press before physics;
- probe after physics;
- cleanup releases input;
- Observatory export;
- stable run result;
- output containment;
- normal autoload order unchanged.

### 29.6 End-to-End Determinism

```bash
python3 custodian/tools/iteration/run_moment.py \
  healing/field_patch_commit \
  --capture-mode none \
  --repeat 2 \
  --require-identical-stable-fingerprint
```

### 29.7 Renderer Smoke

Linux renderer-backed command:

```bash
cd custodian
env HOME=/tmp/custodian-godot-home \
godot \
  --display-driver x11 \
  --rendering-driver opengl3 \
  --path . \
  --write-movie ../reports/moment_forge/_smoke/raw/capture.png \
  --fixed-fps 60 \
  --script res://tools/validation/moment_forge_renderer_smoke.gd
```

Or use the top-level CLI once implemented:

```bash
python3 custodian/tools/iteration/run_moment.py \
  healing/field_patch_commit \
  --capture-mode full \
  --output-root reports/moment_forge/_smoke
```

### 29.8 Existing Regression Validation

Run:

```bash
cd custodian
env HOME=/tmp/custodian-godot-home godot --headless --path . --import --quit
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/dev_observatory_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/dev_observatory_audit_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/field_patch_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
```

For Vista work:

```bash
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/sundered_keep_world_vista_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/sundered_keep_ingress_smoke.gd
```

### 29.9 Suite

```bash
bash custodian/tools/validation/run_moment_forge_suite.sh
```

The suite must separate:

- core headless checks;
- renderer-required checks;
- optional FFmpeg checks.

It must not silently skip a requested required tier.

---

## 30. Documentation Changes

### `AGENT_TOOLING_BY_ASK.md`

Add “Deterministic Gameplay Moment Review” with:

```bash
python3 custodian/tools/iteration/run_moment.py --list
python3 custodian/tools/iteration/run_moment.py combat/light_hit_grunt
python3 custodian/tools/iteration/run_moment.py --changed
```

Explain:

- Moment Forge is for repeatable audiovisual/gameplay review;
- ordinary focused smoke tests remain the first tool for narrow logic verification;
- Moment Forge evidence is generated review output;
- baseline approval is human.

### `VALIDATION_RECIPES.md`

Add:

- core Moment Forge suite;
- deterministic repeat command;
- renderer full-capture command;
- when to use `none`, `evidence`, and `full`;
- existing Observatory regressions.

### `CURRENT_STATE.md`

On implementation:

- note implemented phase and scenario coverage;
- do not claim all six complete until they are;
- identify blocked fixture/public-boundary work;
- state baseline/media support accurately.

### `FILE_INDEX.md`

Index:

- active design spec;
- CLI;
- scenario root;
- runner;
- report builder;
- changed router;
- validation suite;
- report output root;
- task packet.

### `CONTEXT.md`

Update only if the project adopts a general rule such as:

> New high-value combat or presentation regressions should receive a focused smoke for stable logic and may receive a Moment Forge scenario for audiovisual/game-feel evidence.

---

## 31. Documentation Drift Review

### 31.1 Resolved Authority Drift

The attached/Drive-era root guidance routes new design work through:

```text
design/20_features/in_progress/
```

The live repository root and local primer now identify:

```text
design/02_features/
```

as active and `design/20_features/` as retired.

Action:

- write this spec only to `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md`;
- do not edit or recreate the retired path;
- update any copied packet or prompt that contains the old path.

### 31.2 Automation Backlog Drift

`custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md` is dated 2026-05-03 and lists five scripts as suggested paths without implementation-status fields.

This Moment Forge work should not opportunistically build those unrelated scripts. It should, however, remediate the document enough to distinguish:

- proposed;
- implemented;
- superseded;
- deferred.

Recommended one-time audit:

```bash
for path in \
  custodian/tools/agent/check_ai_context.py \
  custodian/tools/agent/check_task_packets.py \
  custodian/tools/agent/check_prompts.py \
  custodian/tools/agent/validate_docs.py \
  custodian/tools/agent/check_git_safety.py
do
  test -e "$path" && echo "IMPLEMENTED $path" || echo "MISSING $path"
done
```

Then add a status column or status field to the backlog. This is separate from Moment Forge acceptance unless files touched by implementation rely on that backlog.

### 31.3 Tooling Router Staleness

`AGENT_TOOLING_BY_ASK.md` currently routes modular Operator asset work but has no deterministic gameplay-moment review section.

Action:

- update it in Phase 6;
- update its `Last updated` date;
- do not replace existing Operator tooling guidance.

### 31.4 Current-State and Index Drift

When implementation creates new authority and entrypoints:

- `CURRENT_STATE.md` must reflect actual phase;
- `FILE_INDEX.md` must index the new files;
- the task packet must record blocked/deferred scenarios;
- no doc may imply MP4 is guaranteed when FFmpeg was not made a hard dependency.

---

## 32. Acceptance Criteria

Moment Forge V1 is complete only when all of the following are true.

### Core

- [ ] Active spec exists at the correct path.
- [ ] Full task packet exists and is current.
- [ ] Scenario schema is versioned and validated.
- [ ] CLI supports direct run, list, baseline, and changed suggestions.
- [ ] Runner is dev-only and not an autoload.
- [ ] Normal game boot is unchanged.
- [ ] Fixed 60 Hz tick contract is implemented.
- [ ] Setup, action, probe, and cleanup order are tested.
- [ ] All injected inputs release on success and failure.
- [ ] Explicit seed and deterministic sub-seeds are applied.
- [ ] DevObservatory is reused.
- [ ] Tick-enriched timeline is generated.
- [ ] Stable fingerprint is generated.
- [ ] Two identical runs match stable fingerprint.
- [ ] Stable assertions can fail a run.
- [ ] Output containment is enforced.

### Media and Report

- [ ] Exact selected-tick PNGs are captured.
- [ ] Six-frame 3840×1440 contact sheet is generated.
- [ ] Movie Maker produces synchronized raw frame/audio evidence in full mode.
- [ ] 48 kHz stereo canonical audio is produced or correctly marked unavailable.
- [ ] MP4 is generated when FFmpeg is available.
- [ ] Missing FFmpeg has a functional report fallback.
- [ ] Baseline compatibility is enforced.
- [ ] Baseline/current report is self-contained.
- [ ] Visual and audio metrics are advisory.
- [ ] Partial evidence is disclosed.

### Scenario Pack

- [ ] `combat/light_hit_grunt`
- [ ] `combat/heavy_hit_grunt`
- [ ] `combat/light_hit_marine_deflect`
- [ ] `combat/parry_success`
- [ ] `healing/field_patch_commit`
- [ ] `vista/sundered_keep_first_reveal`

Each completed scenario:

- [ ] uses actual gameplay authority;
- [ ] has at least one stable assertion;
- [ ] has six authored keyframes;
- [ ] has deterministic double-run evidence;
- [ ] has no unsupported private-method shortcut;
- [ ] documents any intentional advisory-only evidence.

### Routing and Docs

- [ ] changed-file rules are readable config;
- [ ] combat WAV routing works;
- [ ] Operator action routing works;
- [ ] Vista routing works;
- [ ] router never silently executes;
- [ ] tooling router updated;
- [ ] validation recipes updated;
- [ ] current state updated;
- [ ] file index updated;
- [ ] drift findings remediated or explicitly deferred.

---

## 33. Deferred Work

After V1:

- more direction-specific moments;
- three-hit fast combo;
- dodge-chain/Flow moments;
- ranged fire, projectile travel, and impact moments;
- critical execution;
- marine dash;
- enemy savage pounce;
- camera/reveal variants across seeds;
- procgen traversal moments;
- automatic issue/PR report attachment;
- CI artifact publication;
- browser image-overlay slider;
- audio waveform visualization;
- reusable fixture interface for authored level moments;
- stable scenario packs per subsystem;
- integration with future Developer Replay System;
- automatic baseline storage policy;
- report retention/cleanup utility;
- trailer-capture presets.

None of these should block the six-scenario V1.

---

## 34. Next Agent Slice

### Goal

Implement Phase 0 and Phase 1: establish authority, schema, CLI, deterministic runtime core, Observatory export, probes/assertions, and the first `healing/field_patch_commit` scenario in `capture-mode none`.

### Read First

```text
custodian/AGENTS.md
design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md
design/02_features/debug_ui/DEVELOPER_OBSERVATORY_SYSTEM.md
design/02_features/debug_ui/DEV_MODE_SYSTEM.md
design/90_codex/tooling/developer_replay_system.md
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md
custodian/docs/ai_context/VALIDATION_RECIPES.md
custodian/tools/validation/field_patch_smoke.gd
custodian/game/systems/debug/dev_observatory.gd
custodian/game/systems/debug/dev_mode.gd
custodian/scenes/debug/combat_playground.tscn
```

### Change

```text
design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md
custodian/docs/ai_context/task_packets/MOMENT_FORGE_V1.md
custodian/tools/iteration/README.md
custodian/tools/iteration/run_moment.py
custodian/tools/iteration/moment_schema.json
custodian/tools/iteration/scenarios/healing/field_patch_commit.json
custodian/tools/iteration/godot/moment_runner.gd
custodian/tools/iteration/godot/moment_action_driver.gd
custodian/tools/iteration/godot/moment_probe_collector.gd
custodian/tools/iteration/godot/moment_assertion_evidence.gd
custodian/tools/validation/moment_forge_schema_smoke.py
custodian/tools/validation/moment_forge_runtime_smoke.gd
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md
custodian/docs/ai_context/VALIDATION_RECIPES.md
```

### Constraints

- no new autoload;
- no Movie Maker/media work in this first slice;
- no arbitrary method invocation;
- use live `use_field_patch` input;
- set setup state before tick 0;
- reuse Observatory;
- output only under reports;
- normal game boot unchanged;
- do not claim the remaining five scenarios are implemented.

### Acceptance

```bash
python3 -m py_compile custodian/tools/iteration/run_moment.py
python3 custodian/tools/validation/moment_forge_schema_smoke.py

cd custodian
env HOME=/tmp/custodian-godot-home godot --headless --path . --import --quit
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/moment_forge_runtime_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/field_patch_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/dev_observatory_smoke.gd

cd ..
python3 custodian/tools/iteration/run_moment.py \
  healing/field_patch_commit \
  --capture-mode none \
  --repeat 2 \
  --require-identical-stable-fingerprint
```

---

## 35. One-Shot Codex Implementation Packet

```text
You are working in the CUSTODIAN Godot 4.7 repository.

Objective:
Implement Phase 0 and Phase 1 of CUSTODIAN Moment Forge from:
design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md

Repository authority:
1. custodian/AGENTS.md
2. design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md
3. custodian/docs/ai_context/CURRENT_STATE.md
4. custodian/docs/ai_context/FILE_INDEX.md
5. custodian/docs/ai_context/VALIDATION_RECIPES.md

Read adjacent runtime authority:
- design/02_features/debug_ui/DEVELOPER_OBSERVATORY_SYSTEM.md
- design/02_features/debug_ui/DEV_MODE_SYSTEM.md
- design/90_codex/tooling/developer_replay_system.md
- custodian/game/systems/debug/dev_observatory.gd
- custodian/game/systems/debug/dev_mode.gd
- custodian/tools/validation/field_patch_smoke.gd
- custodian/scenes/debug/combat_playground.tscn

Required slice:
- create/update the full MOMENT_FORGE_V1 task packet;
- implement versioned scenario schema;
- implement CLI discovery, validation, run directory creation, subprocess
  supervision, and --list;
- implement a dev-only SceneTree runner;
- implement fixed-tick InputMap action injection and cleanup;
- implement role setup and scoped probes;
- clear and export DevObservatory;
- mirror Observatory events with scenario ticks;
- implement stable assertions and stable fingerprint;
- implement healing/field_patch_commit in capture-mode none;
- implement schema and runtime smokes;
- run the same scenario twice and require identical stable fingerprint;
- update CURRENT_STATE, FILE_INDEX, and VALIDATION_RECIPES accurately.

Do not implement in this slice:
- Movie Maker;
- audio capture;
- MP4;
- visual diffs;
- baseline comparison;
- changed-file routing;
- the other five scenarios.

Hard constraints:
- no new autoload;
- no normal-boot behavior change;
- no arbitrary method call from JSON;
- use InputMap for Field Patch;
- no output outside reports/moment_forge;
- no gameplay dependence on Observatory or Moment Forge;
- no design/20_features paths;
- do not stage, commit, or push without explicit approval.

Before editing:
- perform the adjacency and docs-drift check required by custodian/AGENTS.md;
- note any mismatch in the task packet;
- confirm exact live input/property names rather than copying assumptions.

Validation:
Run every command in the Next Agent Slice acceptance block. Preserve command
output and summarize any known pre-existing warnings separately from new
failures.
```

---

## 36. Final Design Rationale

Moment Forge should be built now because CUSTODIAN already has:

- deterministic fixed-step expectations;
- structured gameplay telemetry;
- debug eligibility;
- renderer-backed review patterns;
- rich combat, animation, VFX, audio, camera, and Vista iteration surfaces;
- a growing set of focused runtime smokes;
- repeatable moments whose quality cannot be judged from pass/fail logic alone.

The system’s value compounds:

- a bug can become a scenario;
- an approved hit can become a baseline;
- an animation replacement can be reviewed against exact prior timing;
- a difficult visual sequence can become executable design evidence;
- Codex can inspect generated facts instead of inferring runtime feel from source;
- stable scenario assertions can graduate into regression checks;
- media evidence can remain human-reviewed without turning aesthetic judgment into brittle CI.

The correct V1 is not a universal replay framework. It is a disciplined forge for a small number of high-value moments.
