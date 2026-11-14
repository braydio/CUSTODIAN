# Operator UI sync status refresh

Workstream: operator-ui-sync-status-refresh-v1

## Problem
`opui` ran the persistent-checkout sync once before launching the Workbench and
passed the result in `CUSTODIAN_SYNC_STATUS`. The UI printed that string as
`startup sync …` and never updated it, so a launch that landed while another
agent held `.git/custodian-persistent-checkout-sync.lock` showed `SYNC BUSY` for
the whole session.

## Change
- `persistent_checkout_sync.sync_lock_busy()` - read-only shared-lock probe.
- `WorkbenchService.live_sync_status()` - inspects both profiles (local refs, no
  fetch, nothing applied) and appends `sync lock held by another process` only
  while the lock is held. `startup_sync_status()` exposes the launch snapshot.
- `OperatorWorkbenchApp` - refreshes every 15 s and on `Shift+R`; the launch
  snapshot shows as `sync at launch: …` until the first live read replaces it.
  Changes in the status are written to the activity log.
- `checkout_status_label(..., include_startup_sync=True)` keeps its old default;
  the app passes `False` and composes the live status itself.

## Validation
- `persistent_checkout_sync_smoke.py` - new `live_sync_status_smoke` (lock
  free/held/released, probe leaves no lock, unreadable root, launch snapshot).
- `operator_workbench_ui_smoke.py` - new `sync_status_refresh_smoke` pilot
  (launch SYNC BUSY replaced on mount; `shift+r` clears a released lock).

## Notes
- "behind N" is relative to the locally cached `origin/main`; the refresh does
  not fetch. `csync`/`opui` still fetch and apply.
- The probe holds a shared lock for an instant; a sync starting in that instant
  would report SYNC BUSY once and succeed on retry.
