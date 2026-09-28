# TWIN SOLARIA ROUTE REVIEW AUTHORITY

- Workstream: `twin-solaria-route-review-authority`
- Kind: `implementation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-twin-solaria-crown-incident-forensics`
- Locks: `twin-solaria-runtime`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-twin-solaria-route-review-authority`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Implement Twin Solaria Slice D as one focused, fail-closed route-review authority that models a candidate route, classifies evidence, enforces Home Index and reciprocity sequencing, and records HOLD / ABORT / AUTHORIZE ACQUISITION without creating cross-map travel or presentation-owned route truth.
- Current measured state: Production Twin Solaria already has the authored 2048×1536 shell and dormant machine readouts. Slice C is queued to add Crown Incident forensic progression. Canon defines the operational sequence DORMANT → AUTHORITY WAKE → HOME REFERENCE → LISTENING → CORRELATING → ROUTE CANDIDATE → RECIPROCITY REVIEW → CUSTODIAN DECISION. Full Solarium I acquisition presentation remains Slice E.
- Task-specific authority: `design/05_levels/TWIN_SOLARIA.md` sections 7–9 and 30–32; `design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md`; live authored-level route-state hooks; completed Slice C runtime.
- Change: Add a local Twin Solaria route-review state model/controller, evidence classifications, candidate/evidence snapshots, machine interaction wiring for Home Index/Witnesses/Echo/Needle/Dial/Authority Threshold, and deterministic capture/restore. Authorize Acquisition records permission only; it does not perform Slice E's full visual resolve.
- Preserve: existing forensic progression and reserved mysteries; existing route traversal manager owns scene/world handoff; presentation reads route state but cannot decide safety; no new global campaign state; no Passage; no tactical portal changes.
- Non-goals: No cross-map Crown traversal; no Solarium II reconstruction; no Passage handoff; no acquisition FX assets; no final camera/lighting/audio pass; no global route-network rewrite; no random route generation; no implicit route safety inference from visual state.
- Acceptance: Home Index must converge before route work; evidence must progress through correlation and reciprocity before a decision; HOLD prevents stronger resolve while preserving evidence; ABORT returns to a safe local state; AUTHORIZE ACQUISITION is the only discretionary path that sets acquisition authorization; no action creates a route exit or player traversal; state round-trips through authored-level capture/restore.

## Runtime Authority

Create one focused owner, e.g.:

```text
TwinSolariaRouteReview
```

or the nearest live equivalent.

It owns only Twin Solaria's local review state:

```text
phase
home_reference
candidate
archive_evidence
live_evidence
echo_evidence
reciprocity_result
custodian_finding
acquisition_authorized
```

It must not own:

- scene/world travel;
- global campaign history;
- HubState;
- Contract state;
- Solarium I FX presentation;
- Passage state.

Do not put this state machine in `operator.gd`, `ui.gd`, or a large `TwinSolariaLayout` switchboard.

## Candidate Model

Use a deterministic data-only model. At minimum:

```text
candidate_id
display_label
provenance_class
archive_confidence
live_confidence
outbound_convergence
reciprocal_class
field_strain
known_holds
unresolved_flags
```

Do not invent a new global route registry just to satisfy this slice.

For the production level, it is acceptable to expose one authored/local candidate dataset representing the current preserved Resolved Route Vista, plus test fixtures for unsafe/multiple/nonconvergent cases. Candidate data belongs in a focused Twin Solaria data/resource surface, not hardcoded through interaction copy.

## Evidence Classes

Support clear machine-readable classifications matching canon:

- `archive`
- `live`
- `echo_outbound`
- `echo_return`
- `provenance`
- `hold`
- `reciprocity`

Each class can be absent / supporting / conflicting / unresolved where appropriate.

Archive does not override Live and Live does not override Archive.

The route-review authority decides progression from explicit evidence inputs. Presentation/UI only renders its snapshot.

## Operational Sequence

Implement the design sequence:

### DORMANT

No route candidate. No decision.

### AUTHORITY WAKE

Recognized local authority wakes basic instrumentation. No candidate.

### HOME REFERENCE

Home Index must resolve before further work.

Required success state:

```text
HOME REFERENCE: CONVERGED
LOCAL DOMAIN: CORRELATED
RECIPROCAL ORIGIN: STABLE
```

Failure/degraded state blocks further route work.

### LISTENING

Passive historical/current residue may be inspected. No active candidate yet.

### CORRELATING

Archive Witness + Live Witness + Meridian Needle compare evidence.

Conflicting evidence may keep the route in correlation or produce a candidate with warnings. Do not silently coerce conflict to success.

### ROUTE CANDIDATE

A candidate exists. Candidate is not safe and not authorized.

A faint/weak resolve flag may be exposed for Slice E presentation, but no full resolve is permitted here.

### RECIPROCITY REVIEW

Model at least:

- `converged`
- `multiple`
- `nonconvergent`
- `unresolved_contact`

A non-converged reciprocal state must fail closed into HOLD-eligible/no-authorize behavior.

### CUSTODIAN DECISION

Exactly three high-level findings:

- `HOLD`
- `ABORT`
- `AUTHORIZE_ACQUISITION`

Rules:

- HOLD preserves candidate/evidence and blocks full resolve.
- ABORT clears the active attempt and returns to a safe local state without claiming the route can never be revisited.
- AUTHORIZE_ACQUISITION is only available after a complete, admissible reciprocity review.
- AUTHORIZE_ACQUISITION sets local `acquisition_authorized=true`; it does not itself animate Solarium I.

## Interaction Wiring

Reuse the existing Twin Solaria machine/readout surface.

Suggested responsibilities:

- Home Index: wake/home-reference action and status.
- Archive Witness: archive evidence classification.
- Live Witness: live evidence classification.
- West Echo Drum: initiate/record outbound interrogation.
- East Echo Drum: returned evidence/reciprocity input.
- Meridian Needle: candidate correlation.
- Reciprocity Dial: review summary and reciprocal result.
- Authority Threshold: HOLD / ABORT / AUTHORIZE ACQUISITION action surface.

Do not invent a second global terminal UI. A compact Twin-local selection/readout overlay is allowed if required for the three decisions and reuses existing HUD patterns.

Blind Witness remains isolated and unresolved.

## State Persistence

Extend Twin Solaria's authored-level route-state snapshot without breaking Slice C.

Conceptually:

```gdscript
{
  "forensics": {...},
  "route_review": {
    "phase": "...",
    "candidate": {...},
    "evidence": {...},
    "reciprocity": "...",
    "finding": "...",
    "acquisition_authorized": false
  }
}
```

Requirements:

- deterministic ordering;
- no Node refs;
- invalid/impossible states rejected;
- no restore side effects;
- HOLD/ABORT/authorization restore correctly;
- capture→restore→capture exact.

## Safety Invariants

Prove:

- no phase skips Home Reference;
- no candidate skips reciprocity review;
- no nonconvergent/multiple reciprocal state can authorize;
- HOLD cannot enter acquisition resolve;
- ABORT clears authorization and active candidate attempt;
- only AUTHORIZE_ACQUISITION can set the authorization flag;
- no `LevelExit2D`, route-manager travel request, world ingress, or scene load is created;
- existing tactical procgen portal and Gate of Dust behavior remain unchanged.

## Focused Validation

Add:

`custodian/tools/validation/twin_solaria_route_review_smoke.gd`

Cover at least:

1. baseline dormant state;
2. Home Index block;
3. successful home convergence;
4. archive/live conflict retained;
5. candidate creation only after correlation;
6. reciprocity required;
7. multiple/nonconvergent/unresolved cannot authorize;
8. HOLD preserves evidence and blocks authorization;
9. ABORT returns safe and clears active attempt;
10. AUTHORIZE works only after admissible review;
11. presentation cannot mutate authoritative state through snapshot interfaces;
12. exact route-state round-trip;
13. invalid restore fails closed;
14. no route exit/travel request is created;
15. Slice C forensic state survives alongside route-review state;
16. existing Twin runtime/canon/forensic smokes remain green.

Register changed-file ownership and run focused checks before `--changed`.

## Documentation

Update Twin Solaria runtime status and CURRENT_STATE only after behavior is live.

Do not rewrite the canon operational sequence. Document implementation status against it.

## Completion

Archive complete packet, leave paired review active, write
`TWIN_SOLARIA_ROUTE_REVIEW_AUTHORITY_CLAUDE_SUMMARY.md`, run focused/changed validation, and land normally.

## Handoff

- Next action: after this implementation and its independent review pass, Slice E acquisition presentation becomes eligible.
- Best starting files: Twin Solaria layout/forensic controller, authored-level route-state hooks, machine readouts, `ROUTE_TRAVERSAL_SYSTEM.md`.
- Blockers or open questions: blocked intentionally on reviewed Slice C.
