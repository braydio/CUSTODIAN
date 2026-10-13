# Render deployment isolation for CUSTODIAN

## Diagnosis (2026-10-13)

The existing Render service called **CUSTODIAN**
(`srv-d6gl7r9aae7s73beudcg`) sent repeated failed-deploy notices while
`braydio/CUSTODIAN`'s `main` branch was receiving unrelated GitHub commits.
For example, the 2026-10-13 commits `fdbb1338`, `3b70c24c`, and `b224e51a`
changed only Godot task-packet metadata/indexes. Without Render Build Filters,
a service linked to `main` auto-deploys on these pushes by default.

The repository already contains `python-sim/render.yaml`, with
`rootDir: python-sim` and `buildFilter.paths: [python-sim/**]`, but that
Blueprint defines a service named **custodian-terminal**, not the Render alert's
**CUSTODIAN**. The YAML alone does not establish the live service's settings,
and editing it does not update a standalone service.

## Apply to the existing Render service

1. Open the existing CUSTODIAN service in Render, not a new Blueprint.
   Verify its linked repo, branch (`main`), build command, start command,
   and deployed code are actually the legacy `python-sim/` terminal.
2. In **Settings > Build & Deploy > Build Filters**, configure
   **Included Paths**: `python-sim/**`. Leave **Ignored Paths** empty.
   If other shared runtime dependencies exist outside `python-sim/`, explicitly
   include their exact paths instead of silently excluding them.
3. Save the filter. Do not change `rootDir` during this fix, since changing
   it alters build/start-command paths. Do not disable all automatic deployments;
   the goal is still to deploy when the hosted terminal actually changes.
4. Confirm an unrelated Godot/docs/packet-only push records a skipped deploy
   and consumes no build minutes. Confirm a deliberate terminal change would
   match the include filter before relying on it. Manual deployments and
   service-setting changes are not restricted by Build Filters.

## Repository-side fallback

The root `AGENTS.md` directs agents to append `[skip render]` to commits
that do not affect `python-sim/` or its deployment dependencies. The automatic
packet-pair authoring publisher uses the same marker. Render supports this
commit-message marker for skipping an auto-deploy.

This is **best effort**: direct commits and third-party bots may omit the
marker. The live service Build Filter is the authoritative fix. The Render
dashboard change cannot be proven or applied by a GitHub commit alone if the
service is managed outside the repository's Blueprint.

References:
- https://render.com/docs/monorepo-support
- https://render.com/docs/deploys
