# AWAKENING SCENE CORRECTNESS HARDENING

Audit/fix the live Awakening scene in ONE pass where practical.

Primary:
- custodian/scenes/awakening_first_return.tscn
- custodian/game/world/awakening/awakening_first_return.gd
- custodian/game/world/awakening/awakening_layout.gd

Inspect LOCAL working tree first. Preserve unrelated/concurrent changes.
Use current repo truth over this packet if implementation has advanced.

GOAL

Harden Awakening correctness without redesigning it:
1. remove leftover blockout visuals from production presentation;
2. enforce AwakeningLayout as spatial authority;
3. fix camera reveal lifecycle;
4. make debug reset honest;
5. audit/bind existing fixture assets conservatively;
6. technically verify Gate art/collision alignment;
7. preserve current route, plates, lighting, P-9, and Road behavior.

Do not regenerate art or change locked geometry unless an objective defect requires it.

----------------------------------------------------------------------
1. PRODUCTION TRAVERSAL PRESENTATION
----------------------------------------------------------------------

`_build_traversal_presentation()` currently creates connector/threshold floor
polygons + brass inlays above production underlays.

Separate VISUAL blockout presentation from spatial authority, e.g.:

    AwakeningZones/Traversal/BlockoutPresentation

Zones 01-09 have production underlay/foreground plates. Their production
gameplay must not show blockout connector polygons/inlays over the art.

PRESERVE unchanged:
- Layout.CONNECTORS
- Layout.THRESHOLDS
- Layout.traversal_rects()
- collision carving
- route dimensions/coordinates

Keep mapper/debug visualization available where useful.

Extend awakening_first_return_smoke.gd to assert production does not render the
blockout traversal overlay while traversal authority still exists.

----------------------------------------------------------------------
2. SINGLE SPATIAL AUTHORITY
----------------------------------------------------------------------

Remove controller-side duplicated coordinates where Layout already owns them.

At minimum replace hardcoded placement for:
- Crèche console -> marker `creche_console`
- Undergate console -> marker `port_status_plaque`
- Dust Lung lift lower -> marker `lift_lower`
- Dust Lung lift upper -> marker `lift_upper`

Use existing marker/set-piece lookup helpers or one small generic helper.

Do not add another coordinate registry.
Preserve exact current positions.

Add validation that runtime positions equal Layout markers.

----------------------------------------------------------------------
3. CAMERA REVEAL RACE
----------------------------------------------------------------------

Current delayed reveal releases can allow an old reveal timer to clear a newer
reveal.

Make reveal ownership generation-safe or cancellable.

Simple acceptable pattern:

    var _reveal_generation := 0

Each new reveal increments it.
A delayed release clears framing only if its captured generation is still current.

Do not change Layout.CAMERA_REVEALS values or camera behavior otherwise.

Add focused regression:
A starts -> B starts -> A timeout must not clear B -> B eventually clears normally.

----------------------------------------------------------------------
4. DEBUG RESET
----------------------------------------------------------------------

Audit `reset_progression()`.

At minimum ensure reset also cleans transient Awakening-owned state:
- pending camera reveal/release
- camera presentation framing
- transit lift transient state where safely resettable

Do NOT mutate/delete global inventory merely to rewind P-9.

If designation-locker/inventory state cannot safely be restored, keep reset
controller-scoped and update its comment/name/contract so it does not claim to
fully replay all persistent pickup state.

No test-only inventory hacks.

----------------------------------------------------------------------
5. FIXTURE CONSUMPTION AUDIT
----------------------------------------------------------------------

Inspect current Asset V2 status for Awakening fixture families, including:
- awakening_creche_fixtures
- awakening_ambulatory_fixtures
- awakening_attestation_fixtures
- awakening_reliquary_fixtures
- awakening_dust_lung_structures
- awakening_undergate_machinery
- awakening_late_service_relay_lamp

Do NOT blindly instance published sprites. Production backdrop art may already
contain them.

Classify each relevant available state as:

    BAKED_ONLY
    INDEPENDENT_WORLD_PROP
    FOREGROUND_OCCLUDER
    INTERACTABLE
    STATEFUL_PROP
    NOT_READY

Only bind independent/foreground/interactable/stateful assets.

Use Layout SET_PIECES/MARKERS for placement.
Do not double-render baked art.
Do not invent missing assets.
Do not create collision merely because a sprite exists.
Do not duplicate specialized existing systems:
- recovery alcove
- designation locker
- Dust Lung lift
- Gate components
- Undergate lighting/environment

If a fixture requires changing authored geometry, defer it and report why.

----------------------------------------------------------------------
6. GATE OF DUST TECHNICAL QA
----------------------------------------------------------------------

Do not redesign the Gate.

Current logical pylon blockers are approximately 160x320 while art canvases are
256x512. This may be intentional transparent padding.

Capture production scene with collision overlay and verify:
- west pylon visual vs collision
- east pylon visual vs collision
- central route remains clear
- no obviously solid opaque mass is walk-through
- collision does not extend unnecessarily through transparent space
- production backdrop/components remain registered correctly

Only change collision if objective capture evidence proves mismatch.

Save/report capture paths.

----------------------------------------------------------------------
7. PRESERVE VERIFIED SYSTEMS
----------------------------------------------------------------------

Do not alter unless required by a discovered regression:
- Zones 01-09 production plate registration
- foreground z/depth behavior
- Dust Lung -> Undergate transition
- Undergate lighting profiles/local lights/occluders
- Operator flashlight
- P-9 locker anchor/collider/one-time grant
- Road South Reach placement/presentation
- locked envelopes/connectors/entries/exits/world bounds

Existing Dust Lung -> Undergate review:
    reports/transition_review/dust_lung_undergate_20260918/

Do not recapture it unless this task changes something capable of affecting it.

----------------------------------------------------------------------
8. VALIDATION
----------------------------------------------------------------------

Run focused tests first:

awakening_first_return_smoke
awakening_first_return_geometry_smoke
awakening_undergate_lighting_smoke
awakening_designation_locker_presentation_smoke
operator_flashlight_smoke

Run any new camera/reset tests added here.

Then:

    python3 custodian/tools/validation/run_validation.py --changed --json

Do not weaken tests.
Separate unrelated pre-existing failures from regressions caused by this task.

Technical visual QA must produce evidence, not subjective "looks good" claims.

----------------------------------------------------------------------
9. DOC DRIFT
----------------------------------------------------------------------

Check current runtime against:
- design/04_architecture/AWAKENING_FIRST_RETURN.md
- design/04_architecture/AWAKENING_ASSET_MANIFEST.md
- REQUIRED_ASSETS.md
- custodian/docs/ai_context/CURRENT_STATE.md
- custodian/docs/ai_context/FILE_INDEX.md

Update only stale current-truth statements.
Do not churn historical task packets.

----------------------------------------------------------------------
NON-GOALS
----------------------------------------------------------------------

Do not:
- regenerate art
- resize/move zones
- change locked route coordinates
- redesign Gate
- change flashlight behavior
- retune Undergate lighting
- add enemies/encounters
- implement Field Terminal / Ashen Forum / Continuity Port / first Contract
- change P-9 balance
- create a new placement database
- create a new camera system
- bind every fixture merely because it exists

----------------------------------------------------------------------
REPORT
----------------------------------------------------------------------

Return compactly:
- files changed
- traversal overlay fix
- coordinates moved to Layout authority
- camera reveal fix
- final debug-reset contract
- fixture classifications + bindings actually added
- Gate QA capture paths/result
- tests/results
- doc drift corrected
- any deferred objective issue

Do not restate the task.
