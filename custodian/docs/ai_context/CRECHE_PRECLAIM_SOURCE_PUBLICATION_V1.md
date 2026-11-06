# Crèche 1464×1074: Bounded Pre-Claim Source Publication (V1)

**Status:** Owner-authorized input-only procedure; NOT executed by this documentation change.  
**Authority:** Root and nested `AGENTS.md`, `AGENT_TASK_PACKET_TEMPLATE.md`, existing `asset_handoff_installer.py`, Git LFS, and the unchanged `dispatch.py` queue.  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166  
**Scope:** Only `awakening-interactible-clean-room-plates-v1` before its FIRST claim. No global packet governance change, no Undergate, no Godot runtime or Asset V2 ingest.

## Why this pre-claim exception is necessary

This source-preparation packet is `draft/manual` because approved local images are not yet public claim-time inputs. `dispatch.py claim` correctly rejects drafts, and `workstream.py start` for a packeted task would bypass queue authority. The existing source installer only verifies/copies files; it cannot create a Git commit, provide LFS objects to other workers or issue a packet claim. The two old canonical source-work paths ALREADY exist as Git LFS objects for **different old images**. Blindly overwriting them during pre-claim publication would be an unauthorized replacement.

The authorized solution is an **input-only publication** in a separate scratch Git worktree, with a fast-forward-only commit to main that contains (1) two *new immutable* approved PNG paths, (2) an exact source receipt, (3) this existing clean-room packet's `draft/manual` → `ready/auto` metadata, and (4) the generated Ready/Auto README index if it changes. The source-preparation packet itself then claims **only via** `dispatch.py` and owns the later controlled copy into canonical `underlay_source.png`/`foreground_source.png` and inbox. No pre-claim helper may ingest, replace existing source-work paths, edit a V2 family, change scene/geometry, start a workstream, or certify gameplay visuals.

## Immutable user-approved bytes

| Role | Local path | Exact SHA-256 |
|---|---|---|
| floor / underlay | `/home/braydenchaffee/Downloads/03aaa288-64d9-4641-ae95-74d919e738d8.png` | `9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a` |
| wall / foreground | `/home/braydenchaffee/Downloads/8611c23f-9419-435c-9b69-c9f725a4eadb.png` | `515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc` |

Each is a one-frame 1464×1074 8-bit RGBA PNG with real alpha. The source names were reversed earlier and the user corrected them. `00f7cdda...` is superseded. Do not use the existing RGB `underlay_source.png` or old candidate `foreground_source.png` as the approved pair.

**New, non-colliding publication inputs:**

- `custodian/asset_drop/source_work/awakening/awakening_creche_environment/preclaim_20261106/underlay_source.png`
- `custodian/asset_drop/source_work/awakening/awakening_creche_environment/preclaim_20261106/foreground_source.png`
- `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_PRECLAIM_SOURCE_RECEIPT_20261106.md`

These files are tracked through Git LFS and Git, respectively. `SOURCE_READY_NEEDS_TUNE` in the installer means *do not install inbox/runtime during pre-claim*, not that the human is being asked to choose artwork again.

## Operator-controlled pre-claim procedure

This is a **bounded owner-authorized publication operation**, not a `workstream.py start`, dispatch claim, or general authorization to write source work outside a claim. Run on the user's local machine with Git LFS available, only after a fresh `origin/main` fetch and a dispatch audit confirming both Crèche workstreams are unclaimed and have no conflicting locks or active foreign worktrees. Never run in a currently claimed worktree. Preserve unrelated modifications to the user's root checkout.

The complete sequence uses the existing CUSTODIAN source installer and a detached disposable Git worktree:

```bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
python3 custodian/tools/agent/dispatch.py audit --json
git fetch origin main
BASE="$(git rev-parse origin/main)"
TMP="$(mktemp -d -t custodian-creche-preclaim-XXXXXXXX)"
WT="$TMP/checkout"
PKG="$TMP/handoff"
GIT_LFS_SKIP_SMUDGE=1 git worktree add --detach "$WT" "$BASE"
mkdir -p "$PKG"
cp "$WT/custodian/tools/assets/asset_handoff_installer.py" "$PKG/INSTALL_INTO_REPO.py"
python3 - "$PKG" "$WT" "$BASE" <<'PY'
import hashlib, json, shutil, sys
from pathlib import Path
from PIL import Image

pkg, wt, base = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
dest_root = "custodian/asset_drop/source_work/awakening/awakening_creche_environment/preclaim_20261106"
files = (
    ("underlay", Path("/home/braydenchaffee/Downloads/03aaa288-64d9-4641-ae95-74d919e738d8.png"), "9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a"),
    ("foreground", Path("/home/braydenchaffee/Downloads/8611c23f-9419-435c-9b69-c9f725a4eadb.png"), "515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc"),
)
assets = []
(pkg / "originals").mkdir(parents=True)
for state, path, expected in files:
    data = path.read_bytes()
    assert hashlib.sha256(data).hexdigest() == expected, f"{state}: SHA-256 mismatch"
    with Image.open(path) as im:
        im.verify()
    with Image.open(path) as im:
        assert im.format == "PNG" and im.mode == "RGBA" and im.size == (1464, 1074)
        assert im.getchannel("A").getextrema()[0] == 0, f"{state}: missing alpha-zero"
    (pkg / "originals" / f"{state}.png").write_bytes(data)
    assets.append({
        "state_id": state, "review_status": "SOURCE_READY_NEEDS_TUNE",
        "install_source": True, "install_inbox": False,
        "package_source": f"originals/{state}.png",
        "repo_source_destination": f"{dest_root}/{state}_source.png",
        "source_sha256": expected, "source_size_bytes": len(data),
        "generated_dimensions": {"width": 1464, "height": 1074}
    })
(pkg / "MANIFEST.json").write_text(json.dumps({
    "schema": "custodian.asset_handoff.v1",
    "family_id": "awakening_creche_environment",
    "assets": assets
}, indent=2) + "\n")
receipt = wt / "custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_PRECLAIM_SOURCE_RECEIPT_20261106.md"
receipt.parent.mkdir(parents=True, exist_ok=True)
assert not receipt.exists(), "immutable receipt already exists"
receipt.write_text(
    "# Crèche 1464×1074 pre-claim source publication (2026-11-06)\n\n"
    f"- Base main: \`{base}\`\n"
    "- User approval: approved the two downloaded originals and corrected floor/wall roles.\n"
    "- Scope: **pre-claim source-only**; no Godot runtime/Asset V2 ingest/visual completion.\n"
    "- Review: direct user/ChatGPT gameplay review after implementation; no Crèche paired Codex review.\n"
    + "".join(f"- \`{state}\`: \`{dest_root}/{state}_source.png\`, SHA-256 \`{digest}\`, 1464×1074 RGBA\n"
              for state, _, digest in files)
    + "- Validation: the pre-claim publisher must add actual installer/LFS/push outcomes before asserting success.\n"
)
PY
python3 "$PKG/INSTALL_INTO_REPO.py" --repo "$WT" --dry-run
python3 "$PKG/INSTALL_INTO_REPO.py" --repo "$WT"
```

Now validate **without publishing** that the new source bytes match exactly. Update only the clean-room packet's `Status: draft` → `ready`, `Dispatch: manual` → `auto`, and `Reviewed main` to the investigated full `BASE` SHA. Leave the console cutover packet `draft/manual`. The prepared clean-room packet already declares the immutable source inputs and receipt in `Publication inputs:`; its scope and completion boundary do not change.

```bash
python3 - "$WT" "$BASE" <<'PY'
import hashlib, re, sys
from pathlib import Path

wt, base = Path(sys.argv[1]), sys.argv[2]
root = "custodian/asset_drop/source_work/awakening/awakening_creche_environment/preclaim_20261106"
expected = {
    "underlay": "9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a",
    "foreground": "515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc",
}
for state, digest in expected.items():
    path = wt / root / f"{state}_source.png"
    assert hashlib.sha256(path.read_bytes()).hexdigest() == digest, state
p = wt / "custodian/docs/ai_context/task_packets/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md"
src = p.read_text(encoding="utf-8")
def replace_one(text, old, new):
    assert text.count(old) == 1, f"expected exactly one {old!r}"
    return text.replace(old, new, 1)
src = replace_one(src, "- Status: `draft`", "- Status: `ready`")
src = replace_one(src, "- Dispatch: `manual`", "- Dispatch: `auto`")
src, count = re.subn(r"(?m)^- Reviewed main: `[0-9a-f]{40}`$", f"- Reviewed main: `{base}`", src)
assert count == 1
p.write_text(src, encoding="utf-8")
console = wt / "custodian/docs/ai_context/task_packets/AWAKENING_CRECHE_CONSOLE_SPRITE_REAUTHOR_V1.md"
assert "- Status: `draft`" in console.read_text()
assert "- Dispatch: `manual`" in console.read_text()
print("Preclaim verified: two exact source hashes and clean-room metadata only")
PY
```

Do not proceed if the rooted staging checkout contains unrelated tracked modifications or if any old canonical `underlay_source.png`/`foreground_source.png`, inbox, runtime, family schema, or scene file changed. This procedure does not execute an Asset V2 ingest.

Run the ordinary authoring/category and queue checks before committing:

```bash
(
  cd "$WT"
  python3 custodian/tools/agent/check_packet_categories.py \
    custodian/docs/ai_context/task_packets/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md
  python3 custodian/tools/agent/task_packet_index.py --write
  python3 custodian/tools/agent/validate_review_pairing.py
  python3 custodian/tools/agent/check_ai_context.py --json
  git diff --check
)
```

If any new relevant packet-contract, claim-safety, input-publishing or source validation failure occurs, **stop**. Do not waive it or invoke `workstream.py start` to get around it. Existing unrelated diagnostics are not acceptance evidence.

Stage an **allowlisted-only** commit:

```bash
P1="custodian/asset_drop/source_work/awakening/awakening_creche_environment/preclaim_20261106/underlay_source.png"
P2="custodian/asset_drop/source_work/awakening/awakening_creche_environment/preclaim_20261106/foreground_source.png"
R="custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_PRECLAIM_SOURCE_RECEIPT_20261106.md"
P="custodian/docs/ai_context/task_packets/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md"
I="custodian/docs/ai_context/task_packets/README.md"
git -C "$WT" add -- "$P1" "$P2" "$R" "$P" "$I"
git -C "$WT" diff --cached --check
git -C "$WT" diff --cached --name-only
git -C "$WT" show ":$P1" | grep -Fx "oid sha256:9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a"
git -C "$WT" show ":$P2" | grep -Fx "oid sha256:515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc"
git -C "$WT" commit -m "art: publish approved Crèche 1464 sources for dispatcher intake [skip render]"
git -C "$WT" lfs push origin HEAD
git -C "$WT" push origin HEAD:refs/heads/main
git fetch origin main
test "$(git rev-parse origin/main)" = "$(git -C "$WT" rev-parse HEAD)"
```

**Important:** Confirm the staged path list consists of **only** the five allowlisted paths above and that both PNGs are real LFS pointers with the **expected original SHA-256 OIDs**. If the main branch advanced since `BASE`, the non-force push must fail and the owner must reconcile in a new scratch worktree; never force-push or silently rebase across another worker. A successful source/LFS push is still NOT a workstream claim or Godot validation. A failed push must never be described as publication.

### Normal implementation claim resumes

Only after both PNGs and the source receipt are verified on fetched `origin/main` and the clean-room packet is `ready/auto`:

```bash
python3 custodian/tools/agent/dispatch.py audit --json
python3 custodian/tools/agent/dispatch.py claim awakening-interactible-clean-room-plates-v1 --agent codex
```

The claimed clean-room source workstream validates the published immutable bytes against the receipt and uses its normal bounded implementation to copy the exact files into the **canonical** `underlay_source.png`/`foreground_source.png` and full-size inbox `underlay.png`/`foreground.png`; it records pre-existing source hashes and rollback, but **never ingests runtime art**. It then closes through the normal completion lifecycle, without a paired Codex review. The distinct Crèche room/console workstream remains `draft/manual` until clean-room closeout, console source readiness and separate explicit header promotion; it then uses the ordinary dispatcher for its own atomic Asset V2/scene/geometry cutover. The separate Undergate/Port pair retains its review requirements.

### Abort / cleanup

Before any successful commit, the disposable worktree and package can be discarded with `git worktree remove` after verifying no uncommitted evidence is needed. After a commit, preserve any unpublished evidence until reconciled; never delete an unknown worktree. After successful publication, remove only this pre-claim scratch worktree with the existing Git worktree lifecycle. The user's modified root checkout is never reset or cleaned.
