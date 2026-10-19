#!/usr/bin/env bash
# CUSTODIAN targeted interruption recovery for run 20261018T073442Z-9f32a80a4938.
# Default is READ-ONLY, and --release requires operator verification of no live claimant.
# This is NOT a general workstream recovery mechanism.
set -euo pipefail

WS=agent-paired-review-source-bearing-archive-gate-v1
RUN=20261018T073442Z-9f32a80a4938
BASE=83bdbd1e53fdcb06b18a5a5645f70a050c3cba01
CLAIM=34a947cf00cb0050fbb435bb1840eed57adf63b0
REPO=${CUSTODIAN_COORDINATOR:-/home/braydenchaffee/Projects/.custodian-worktrees/paired-review-coordinator-main-bf9ebf2be8}
POOL=${CUSTODIAN_WORKTREE_POOL:-/home/braydenchaffee/Projects/.custodian-worktrees}
PARTIAL=$POOL/$WS-$RUN
LOCAL=refs/heads/agent/$WS
REMOTE_CLAIM=refs/heads/dispatch-claims/$WS
REMOTE_BRANCH=refs/heads/agent/$WS
MODE=${1:---audit}
MIN_FREE_GIB=${CUSTODIAN_MIN_FREE_GIB:-9}

fail() { printf 'BLOCKED: %s\n' "$*" >&2; exit 2; }
info() { printf '  %-30s %s\n' "$1" "$2"; }
gitc() { git -C "$REPO" "$@"; }
usage() { cat <<'USAGE'
Usage:
  bash custodian_claim_checkout_recovery_v1.sh --audit
  CUSTODIAN_NO_LIVE_CLAIMANT_CONFIRMED=20261018T073442Z-9f32a80a4938 \
    bash custodian_claim_checkout_recovery_v1.sh --release

Defaults to a read-only audit, including size diagnostics.
Release uses exact-SHA CAS deletion of ONLY the orphan local agent branch and
ONLY the original remote dispatch claim. It does not create a new claim or worktree.
Never run --release until disk capacity and no-live-claimant checks are settled.
Override coordinator with CUSTODIAN_COORDINATOR=/path/to/clean/coordinator.
Override the worktree pool with CUSTODIAN_WORKTREE_POOL=/path/to/pool.
Release also requires exclusive dispatch and per-workstream lifecycle mutexes.
USAGE
}
[[ "$MODE" == '--audit' || "$MODE" == '--release' ]] || { usage; exit 2; }
[[ "$MIN_FREE_GIB" =~ ^[0-9]+$ ]] || fail 'CUSTODIAN_MIN_FREE_GIB must be integer'
[[ -d "$REPO" && -e "$REPO/.git" ]] || fail "coordinator not available: $REPO"
[[ -d "$POOL" ]] || fail "pool not available: $POOL"

printf '\nCUSTODIAN ORPHAN CLAIM AUDIT: %s\n' "$WS"
info 'run' "$RUN"
info 'coordinator' "$REPO"
info 'original claim base' "$BASE"
info 'original remote claim' "$CLAIM"
printf '\nStorage on intended worktree pool:\n'
df -h "$POOL"
df -i "$POOL"
printf '\nLargest relevant storage consumers (read-only, may take a moment):\n'
for path in "$REPO" "$HOME/.cache/custodian" "$HOME/.cache/pip" "$POOL"; do
  if [[ -e "$path" ]]; then du -shx "$path" 2>/dev/null || :; fi
done
printf '\nStorage triage by immediate child (read-only; do not delete protected worktrees):\n'
for path in "$HOME/.cache" "$POOL"; do
  if [[ -d "$path" ]]; then
    du -x -h --max-depth=1 "$path" 2>/dev/null | sort -h | tail -n 18 || :
  fi
done
printf '\nWorktree registration (read-only):\n'
gitc worktree list --porcelain | grep -E '^(worktree|HEAD|branch|locked|prunable) ' | tail -n 100 || :
printf '\nCandidate related processes (manually investigate any matches):\n'
ps -eo pid=,args= | grep -E '(dispatch\.py|workstream\.py|git worktree add|custodian-next)' | grep -v -E '(grep -E|custodian_claim_checkout_recovery_v1\.sh)' || :

[[ ! -e "$PARTIAL" && ! -L "$PARTIAL" ]] || fail "partial checkout exists; preserve and inspect: $PARTIAL"
info 'partial worktree directory' 'absent'

# Do not fetch or prune during the audit. This is a branch/ref consistency check.
# Read origin/main directly rather than mistaking a stale cached ref for live ancestry.
remote_main_line=$(gitc ls-remote --heads origin refs/heads/main) || fail 'could not reach origin/main'
[[ "$remote_main_line" == *$'\t'"refs/heads/main" ]] || fail 'remote main ref not found'
remote_main_sha=${remote_main_line%%$'\t'*}
cached_main_sha=$(gitc rev-parse --verify refs/remotes/origin/main 2>/dev/null) || fail 'cached origin/main unavailable'
if [[ "$remote_main_sha" != "$cached_main_sha" ]]; then
  fail "cached origin/main is stale ($cached_main_sha; remote $remote_main_sha). From the coordinator, run: git fetch origin main; rerun audit"
fi
info 'origin/main SHA (fresh)' "$remote_main_sha"

actual_local=$(gitc rev-parse --verify "$LOCAL^{commit}" 2>/dev/null) || fail "local branch $LOCAL missing or unresolved; state has changed"
info 'local branch HEAD' "$actual_local"
[[ "$actual_local" == "$BASE" ]] || fail "local branch changed from expected $BASE"

# Any attached/missing-path registered worktree for this branch must be preserved.
if gitc worktree list --porcelain | grep -Fxq "branch $LOCAL"; then
  fail 'local branch is registered to a worktree, including possibly a missing/prunable path'
fi
worktree_path=$(gitc for-each-ref --format='%(worktreepath)' "$LOCAL" | tr -d '\r')
[[ -z "$worktree_path" ]] || fail "local branch is checked out at $worktree_path"
info 'agent branch attachment' 'none'

if gitc merge-base --is-ancestor "$BASE" refs/remotes/origin/main; then
  info 'unique local branch commits' 'none; BASE is ancestor of fetched origin/main'
else
  fail 'local branch base is not ancestor of cached origin/main; refresh/reconcile history first'
fi

remote_branch=$(gitc ls-remote --heads origin "$REMOTE_BRANCH") || fail 'could not reach origin for remote agent branch check'
[[ -z "$remote_branch" ]] || fail "remote canonical agent branch exists; stop: $remote_branch"
info 'remote agent branch' 'absent'
remote_claim=$(gitc ls-remote --heads origin "$REMOTE_CLAIM") || fail 'could not reach origin to verify remote claim'
[[ "$remote_claim" == "$CLAIM"$'\t'"$REMOTE_CLAIM" ]] || fail "remote claim no longer matches expected exact SHA: $remote_claim"
info 'remote claim lease' 'exact SHA verified'

# Quota not included in df on all filesystems. This is a minimum safety threshold,
# not proof that an eventual checkout will fit (LFS/Godot caches may add usage).
free_kib=$(df -Pk "$POOL" | awk 'NR==2 {print $4}')
[[ "$free_kib" =~ ^[0-9]+$ ]] || fail 'could not read free capacity'
minimum_kib=$((MIN_FREE_GIB * 1024 * 1024))
info 'free GiB (approx)' "$((free_kib / 1024 / 1024))"
info 'minimum GiB to release' "$MIN_FREE_GIB"
if (( free_kib < minimum_kib )); then
  [[ "$MODE" != '--release' ]] || fail "insufficient free capacity for repeat checkout; require ${MIN_FREE_GIB}GiB"
  printf '\nAUDIT ONLY: free storage first. DO NOT delete a worktree or cache with protected evidence.\n'
  exit 0
fi

if [[ "$MODE" == '--audit' ]]; then
  printf '\nAUDIT ONLY: ref invariants passed. Release requires explicit operator no-live-claimant confirmation.\n'
  exit 0
fi

[[ "${CUSTODIAN_NO_LIVE_CLAIMANT_CONFIRMED:-}" == "$RUN" ]] || fail "set CUSTODIAN_NO_LIVE_CLAIMANT_CONFIRMED=$RUN only after manually ruling out active/tmux/subprocess claimant"
[[ -z "$(gitc status --porcelain --untracked-files=all)" ]] || fail 'coordinator is dirty; switch to a clean coordination checkout before release'

# The dispatcher takes its global mutex before its per-workstream mutex. Match
# that ordering, fail fast, and hold both across the identity checks + release.
# Never unlink the lock files. An exclusive flock is not a claimant-liveness
# oracle, hence the separate explicit operator confirmation requirement above.
common_raw=$(gitc rev-parse --git-common-dir) || fail 'cannot resolve Git common directory'
if [[ "$common_raw" = /* ]]; then
  common_path=$common_raw
else
  common_path=$REPO/$common_raw
fi
common_path=$(realpath -e "$common_path") || fail 'Git common directory does not exist'
lock_dir=$common_path/custodian-workflow
[[ -d "$lock_dir" && -d "$lock_dir/locks" ]] || fail 'workflow lock paths are missing; inspect claim state rather than creating a new lock namespace'
command -v flock >/dev/null || fail 'flock is required for safe claim release'
exec {dispatch_fd}>>"$lock_dir/dispatch.lock"
flock -n "$dispatch_fd" || fail 'LOCAL DISPATCH BUSY; retry only after the active operation completes'
exec {workstream_fd}>>"$lock_dir/locks/$WS.lock"
flock -n "$workstream_fd" || fail 'WORKSTREAM BUSY; retry only after verifying the owner'

# Recheck mutable invariants while holding both exact lifecycle mutexes.
[[ ! -e "$PARTIAL" && ! -L "$PARTIAL" ]] || fail "partial checkout appeared: $PARTIAL"
[[ "$(gitc rev-parse --verify "$LOCAL^{commit}" 2>/dev/null)" == "$BASE" ]] || fail 'local branch has moved'
if gitc worktree list --porcelain | grep -Fxq "branch $LOCAL"; then
  fail 'agent branch became attached while acquiring locks'
fi
[[ -z "$(gitc for-each-ref --format='%(worktreepath)' "$LOCAL")" ]] || fail 'agent branch has a worktree attachment'
[[ -z "$(gitc ls-remote --heads origin "$REMOTE_BRANCH")" ]] || fail 'a remote canonical agent branch appeared'
[[ "$(gitc ls-remote --heads origin "$REMOTE_CLAIM")" == "$CLAIM"
# Keep the diagnostic ref and the original commit via origin/main ancestry.
printf '\nReleasing exactly one verified orphan local branch...\n'
gitc update-ref -d "$LOCAL" "$BASE"
printf 'Local orphan removed with exact BASE lease. Remote claim remains until guarded push succeeds.\n'
printf 'Releasing exactly one original remote claim...\n'
gitc push "--force-with-lease=$REMOTE_CLAIM:$CLAIM" origin ":$REMOTE_CLAIM"
printf 'REMOTE CLAIM RELEASED. No new claim/checkout was created.\n'
printf 'Next: run dispatcher audit, then normal claim from clean coordination checkout.\n'\t'"$REMOTE_CLAIM" ]] || fail 'remote claim moved before release'
[[ "$(gitc ls-remote --heads origin refs/heads/main)" == "$(gitc rev-parse --verify refs/remotes/origin/main)"
# Keep the diagnostic ref and the original commit via origin/main ancestry.
printf '\nReleasing exactly one verified orphan local branch...\n'
gitc update-ref -d "$LOCAL" "$BASE"
printf 'Local orphan removed with exact BASE lease. Remote claim remains until guarded push succeeds.\n'
printf 'Releasing exactly one original remote claim...\n'
gitc push "--force-with-lease=$REMOTE_CLAIM:$CLAIM" origin ":$REMOTE_CLAIM"
printf 'REMOTE CLAIM RELEASED. No new claim/checkout was created.\n'
printf 'Next: run dispatcher audit, then normal claim from clean coordination checkout.\n'\t'"refs/heads/main" ]] || fail 'origin/main moved or cached ref is stale; rerun audit'
gitc merge-base --is-ancestor "$BASE" refs/remotes/origin/main || fail 'branch ancestry changed'
free_kib=$(df -Pk "$POOL" | awk 'NR==2 {print $4}')
[[ "$free_kib" =~ ^[0-9]+$ ]] || fail 'could not recheck free space'
(( free_kib >= minimum_kib )) || fail 'free capacity fell below the release threshold'

# Exact expected-value local branch deletion, then remote ref conditional deletion.
# Keep the diagnostic ref and the original commit via origin/main ancestry.
printf '\nReleasing exactly one verified orphan local branch...\n'
gitc update-ref -d "$LOCAL" "$BASE"
printf 'Local orphan removed with exact BASE lease. Remote claim remains until guarded push succeeds.\n'
printf 'Releasing exactly one original remote claim...\n'
gitc push "--force-with-lease=$REMOTE_CLAIM:$CLAIM" origin ":$REMOTE_CLAIM"
printf 'REMOTE CLAIM RELEASED. No new claim/checkout was created.\n'
printf 'Next: run dispatcher audit, then normal claim from clean coordination checkout.\n'