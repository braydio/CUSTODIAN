# Generate an Asset V2 Handoff Bundle

Repository workflow and safety defaults are inherited from `custodian/AGENTS.md`.

## Task

Prepare a reviewed source-art handoff for this family and purpose:

- **Family / design authority:** {{family_id_and_active_design_authority}}
- **States and intended use:** {{states_and_use}}
- **Source masters and normalized inbox files:** {{source_and_inbox_plan}}
- **Task-specific constraints:** {{constraints}}

Inspect the current `origin/main` checkout before choosing file names, family
IDs, paths, target states, or dimensions. Read the active family contract (if
one exists), the relevant design authority, and the applicable Asset V2 docs.
Do not infer canonical runtime names or destinations from an old handoff. If a
family contract needs to change, document that as a separate implementation
handoff; this bundle only stages reviewed source and inbox inputs.

When the work touches a tracked production requirement, inspect
`custodian/content/metadata/assets/required_assets.registry.json`, its generated
root `REQUIRED_ASSETS.md` projection, and the relevant design tracker. Report
documentation drift and the correct owner/action; do not hand-edit the
generated projection or silently change a requirement's route/status.

## Bundle contents

Return one downloadable ZIP containing:

- `README.md` — purpose, family identity, install command, and short contents
  summary.
- `MANIFEST_GAME32.md` — human-readable review and technical metadata for every
  image, including dimensions, source/normalized role, state, and signoff.
- `MANIFEST.json` — the machine-readable `custodian.asset_handoff.v1` manifest
  described below.
- `CODEX_IMPLEMENTATION.md` — intended Asset V2 follow-up: family contract
  questions, plan/status/doctor/ingest sequence, consumers, and deferred work.
- `INSTALL_INTO_REPO.py` — a byte-for-byte copy of
  `custodian/tools/assets/asset_handoff_installer.py` from the inspected live
  `origin/main` checkout.
- Package-local source masters and any normalized inbox PNGs referenced by the
  manifest. Do not include canonical runtime outputs as install destinations.

The recipient installs with:

```bash
python3 INSTALL_INTO_REPO.py --repo /path/to/CUSTODIAN
```

The installer supports `--dry-run`. The ZIP and its unpacked contents remain
the immutable review/source evidence after installation.

## Machine manifest contract

`MANIFEST.json` uses schema `custodian.asset_handoff.v1`. Keep transport and
review metadata here; `custodian.asset_family.v2` remains the semantic and
physical runtime contract. The bundle manifest does not create or modify family
contracts.

Use this shape for each asset state (include a package source master and its
intended source-work destination even when review says it should be skipped):

```json
{
  "schema": "custodian.asset_handoff.v1",
  "family_id": "example_family",
  "assets": [
    {
      "state_id": "idle",
      "review_status": "RUNTIME_READY",
      "install_source": true,
      "package_source": "source/idle_master.png",
      "repo_source_destination": "custodian/asset_drop/source_work/environment/example_family/idle_master.png",
      "source_sha256": "<64-character SHA-256>",
      "source_size_bytes": 12345,
      "generated_dimensions": {"width": 256, "height": 256},
      "install_inbox": true,
      "package_inbox": "normalized/idle.png",
      "repo_inbox_destination": "custodian/asset_drop/inbox/example_family/idle.png",
      "inbox_sha256": "<64-character SHA-256>",
      "inbox_size_bytes": 2345,
      "normalized_dimensions": {"width": 128, "height": 128}
    }
  ]
}
```

For each image, record exact package-relative and repository-relative paths,
SHA-256, byte size, and generated/normalized dimensions when applicable. Use
only these review statuses:

- `RUNTIME_READY`: source may be staged with `install_source: true`; a
  normalized file may be staged to inbox only with `install_inbox: true`.
- `SOURCE_READY_NEEDS_TUNE`: source may be staged; keep `install_inbox: false`
  until normalization is reviewed again.
- `REJECT_REGENERATE`: set both install flags to false. Explain the rejection
  and regeneration direction in `MANIFEST_GAME32.md` and `README.md`.

Source destinations must stay below
`custodian/asset_drop/source_work/`; inbox destinations must stay below
`custodian/asset_drop/inbox/`. Use portable relative paths without `..`,
absolute paths, symlink escapes, or destinations under `custodian/content/`.
Do not set `install_inbox` for a non-`RUNTIME_READY` state.

## Review and counts

Include a per-image review row with state, file, generated dimensions,
normalized dimensions if present, review status, install flags, exact
destinations, and concise approval/rejection reason. Summarize counts for:

- images generated;
- images remaining to generate;
- `RUNTIME_READY`;
- `SOURCE_READY_NEEDS_TUNE`;
- `REJECT_REGENERATE`.

Counts must reconcile with the per-image rows and manifest. Do not include a
placeholder or unreviewed file as runtime-ready.

## Game32 metadata for procgen/environmental families

When the family is for procgen or environmental presentation, document for each
image or coherent variant set:

- semantic placement role and intended procgen consumer;
- world scale and tile footprint;
- traversal effect and collision authority (including explicit presentation-only
status where applicable);
- line-of-sight and cover behavior;
- variation strategy and repetition limits;
- blend/alpha behavior and seams;
- placement constraints, exclusions, and clearance requirements;
- density and repetition guidance.

Keep these fields descriptive of presentation and authoring intent. Do not use
the handoff to create gameplay, collision, navigation, family-contract, or
runtime-binding authority.

## Boundaries

- Do not add automatic downloads, upload behavior, an asset-generation tool, a
  watcher, or a second ingest/publishing pipeline.
- Do not make the installer invoke `asset ingest`, modify family contracts,
  update generated catalogs, bind consumers, write runtime assets, delete
  source masters, or bypass specialized Operator tooling.
- After installation, inspect or update the existing family contract as needed,
  then continue through current Asset V2 planning/status/doctor/ingest tools
  under their existing approval and validation gates.
- Preserve source masters, rejected examples, and the original ZIP as review
  evidence.
