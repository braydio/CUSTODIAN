# Road of Witnesses — Production Modules Batch 01

First ten production assets:

1. south_reach_civic_axis / underlay
2. south_reach_civic_axis / foreground
3. witness_plaza / underlay
4. witness_plaza / foreground
5. collapsed_chapel_court / underlay
6. collapsed_chapel_court / foreground
7. archive_ruin_west / underlay
8. archive_ruin_west / foreground
9. overgrown_reliquary_east / underlay
10. overgrown_reliquary_east / foreground

Collision is intentionally absent and remains authored separately.

The generated board is preserved under:
`custodian/asset_drop/source_work/road_of_witnesses/production_modules_batch01/`

Each module has a draft Asset Pipeline V2 family schema under:
`custodian/content/metadata/assets/families/`

Before ingest:
- visually inspect every pair;
- confirm foreground alpha and underlay/foreground registration;
- run `asset.py plan <family> --verbose`;
- run a dry-run ingest;
- bind only after collision/layout authority for the Road modules is defined.

The sixth proposed module, `north_processional_approach`, is intentionally deferred
to batch 02 because the user asked for the first ten assets.
