# Faction Canon Repair

- Recovered work was already present on pushed main in b3043e2 / 0c0ff2d: seven active polity profiles, gameplay opportunity bank, implementation tracker, narrative migration, and the first documentation smoke had been recovered from the shared worktree without consuming unrelated Operator/audio changes.
- Seal pass reconciled the remaining active split-brain docs: FACTION_EXPRESSION_SYSTEM now uses the seven-polity target while preserving every useful old-roster gameplay implication through explicit tradition/tendency/hazard mappings.
- Resolved the stale faction-migration hold in LATTICE_DOMAIN_COSMOLOGY_MIGRATION.md while preserving persistent Lattice Domains and transient CampaignRegion runtime semantics.
- Marked the root FACTION_PROFILES.md compilation and old visual briefs as historical source material rather than current polity authority.
- Updated region-generation, authored-room, and PixelPlanet lore metadata targets from present_ideology to resident_polity / secondary_polity / local_traditions / hazard_layers / occupancy_posture; the remaining active Region Generation "Feral Defense Systems" heading is now "Legacy Interdiction Mesh."
- Strengthened faction_canon_docs_smoke.py to catch AI-context-complete vs migration-hold disagreement, missing faction paths indexed by FILE_INDEX, retired narrative headings, stale Domain migration hold, and loss of the Mesh HAZARD_LAYER lock.
- Closing validation exposed and corrected one validator defect: FILE_INDEX uses brace-compressed faction paths, so the required-index check now compares against the same expanded path set used by the missing-path check.
- Live runtime compatibility is intentionally unchanged: dominant_faction and prototype values remain until FI-001/FI-002 perform the focused runtime migration.
