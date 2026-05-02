# AGENT MIGRATION PLAYBOOK

Operational instructions for documentation migrations, routing changes, and documentation-drift remediation inside `custodian/`.

## Use This When

- consolidating multiple entrypoints into one canonical primer
- moving documentation or asset-guidance files
- changing which file or folder is authoritative
- reviewing docs drift after runtime or content changes
- making evaluator-facing or agent-facing layout improvements

## Canonical Migration Goal

Every migration should leave three things true:

1. there is one clearly primary destination
2. all likely entrypoints route to it
3. the AI context pack reflects the new reality

## Migration Workflow

1. Define scope.
   List the files, folders, and audiences affected.
2. Name the new canonical destination.
   If you cannot name one, the migration is not ready.
3. Install the destination first.
   Create the new doc or layout target before redirecting traffic.
4. Route high-probability entrypoints.
   Update `AGENTS.md`, `README.md`, local indexes, and any adjacent folder guides.
5. Update authority and state.
   Refresh `docs/ai_context/CURRENT_STATE.md`, `CONTEXT.md`, and `FILE_INDEX.md`.
6. Review for adjacent drift.
   Search for old paths, old names, or stale behavior descriptions.
7. Remediate immediately or record a bounded follow-up.
8. Validate discoverability.
   A new contributor should be able to land on the new canonical destination in one or two hops.

## Drift Detection Workflow

Use this after any architecture, runtime, asset, or docs-layout change.

1. Search for old path references.
2. Search for old authority statements.
3. Search for duplicate “start here” instructions.
4. Compare `design/`, `docs/ai_context/`, and local READMEs for contradictions.
5. Check whether the runtime or asset tree now exposes a new primary file that should be indexed.

## Recommended Search Prompts

Use repository search for:

- the old path or filename
- “start here”
- “source of truth”
- the feature or system name being migrated
- the old authority location

## Automatic Remediation Standard

If drift is found during migration, the default action is to fix it in the same task when the scope is local and low-risk.

At minimum:

1. fix the primary authority doc
2. fix `docs/ai_context/CURRENT_STATE.md` if state changed
3. fix `docs/ai_context/FILE_INDEX.md` if location or ownership changed
4. fix visible entrypoints such as `AGENTS.md` and `README.md`

## Migration Completion Checklist

- The canonical destination exists and contains real guidance.
- Repository and local entrypoints point to it clearly.
- AI context files reflect the new state.
- Old instructions no longer compete with the new route.
- Deferred cleanup, if any, is explicitly documented.
