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

## Live service inspection (2026-10-15)

Render connection confirmed the existing web service, not the old Blueprint:

- ID: `srv-d6gl7r9aae7s73beudcg`; name: `CUSTODIAN`
- Linked repository: `https://github.com/braydio/CUSTODIAN`, branch `main`
- Automatic deploy mode: `checksPass`
- **Live root directory: empty** (repository root)
- Build command: `pip install -r requirements.txt`
- Start command: `gunicorn --bind 0.0.0.0:$PORT --workers 2 --threads 4 --chdir custodian-terminal server:app`
- Latest failed deploy inspected: `dep-db7n6fm0tbcc73c32ph0` at 2026-10-14T12:31:53Z
- The build succeeded, but the new instance logged `Error: can't chdir to 'custodian-terminal'` and exited with code 1. The directory exists at `python-sim/custodian-terminal`, **not** at the repository root.
- Render Events contain many `commit_ignored` entries on October 14–15, confirming the repository's `[skip render]` commit-message guard is already skipping deployments.

### Single live-service correction for BOTH problems

In [CUSTODIAN service settings](https://dashboard.render.com/web/srv-d6gl7r9aae7s73beudcg), update **Build & Deploy > Root Directory** from empty to **`python-sim`**. In the confirmation dialog retain/verify:

```text
Build command: pip install -r requirements.txt
Start command: gunicorn --bind 0.0.0.0:$PORT --workers 2 --threads 4 --chdir custodian-terminal server:app
```

Both commands are now relative to `python-sim`. This fixes the missing
`custodian-terminal` working directory **and** automatically ignores Git
changes outside `python-sim/` on future commits. Render's own documentation
says root-directory scope restricts automatic deploys in monorepos.
Use a build filter with Included Paths `python-sim/**` (and no ignored paths)
if additional path filtering is desired. Build-filter paths are repo-root
relative regardless of rootDir.

**Important:** Changing Render service configuration can itself trigger a
redeploy, which is expected; inspect its status afterward. Do not confuse
the no-redeploy objective (unrelated future commits) with suppressing this one
intentional configuration update. Do not create a new Render service.

**Connector limitation:** This specific connected Render integration exposes
service reads, logs and deploys, but no update-service/rootDir/buildFilter
write action. Consequently the live settings change must be applied in the
Render Dashboard or through an independently authorized Render API client.
A repository-only commit or standalone YAML edit cannot change this existing
service.

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
