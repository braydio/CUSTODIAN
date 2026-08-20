"""Isolated regression cases shared by the Asset Pipeline V2 smoke entrypoints."""
from __future__ import annotations
import hashlib
import json
import sys
import tempfile
from pathlib import Path
from types import SimpleNamespace

from PIL import Image

ASSETS = Path(__file__).resolve().parents[1] / "assets"
sys.path.insert(0, str(ASSETS))

from asset_classifier import ResolutionConfidence, classify_input
from asset_contract import load_family
from asset_plan import AssetOperation, generate_plan
from asset_status import get_family_status
from asset_transaction import begin_transaction, rollback_transaction
from adapters.runtime_ready import stage_asset as runtime_stage
from adapters.sprite_ingest import build_manifest, stage_asset as sprite_stage
import asset as asset_cli


def fixture(root: Path):
    family_path = root / "family.asset.json"
    family_path.write_text(json.dumps({
        "schema":"custodian.asset_family.v1", "id":"fixture", "kind":"world_prop",
        "runtime":{"domain":"sprites/environment/props","owner":"fixture"},
        "canvas":{"width":16,"height":8}, "direction_policy":"omni",
        "states":{
            "idle":{"required":True,"layer":"body","action_group":"interaction","variant":"idle"},
            "active":{"required":True,"animation":True,"layer":"body","action_group":"interaction","variant":"active"}},
        "aliases":{"working":"active"}, "consumers":[]}), encoding="utf-8")
    return load_family(family_path)


def png(path: Path, size=(16, 8), color=(10, 20, 30, 255)):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGBA", size, color).save(path)


def test_contract_and_plan():
    with tempfile.TemporaryDirectory() as raw:
        root = Path(raw); family = fixture(root); inbox = root / "asset_drop/inbox/fixture"
        malformed = root / "malformed.asset.json"
        malformed.write_text('{"schema":"custodian.asset_family.v1","id":"bad"}')
        try:
            load_family(malformed)
            raise AssertionError("malformed contract was accepted")
        except ValueError:
            pass
        empty = generate_plan(family, inbox, root)
        assert empty.can_apply and not empty.assets
        png(inbox / "idle.png"); png(inbox / "working.png", (64, 8)); png(inbox / "unknown.png")
        before = snapshot(root); plan = generate_plan(family, inbox, root); assert snapshot(root) == before
        assert [a.confidence for a in plan.assets] == [ResolutionConfidence.EXACT, ResolutionConfidence.AMBIGUOUS, ResolutionConfidence.INFERRED]
        assert not plan.can_apply and plan.assets[1].operation == AssetOperation.CONFLICT
        old_project, old_inbox = asset_cli.PROJECT_DIR, asset_cli.INBOX_ROOT
        try:
            asset_cli.PROJECT_DIR, asset_cli.INBOX_ROOT = root, root / "asset_drop/inbox"
            before=snapshot(root)
            assert asset_cli.cmd_plan(SimpleNamespace(family="fixture"), {"fixture":family}) == 2
            assert snapshot(root) == before
        finally:
            asset_cli.PROJECT_DIR, asset_cli.INBOX_ROOT = old_project, old_inbox


def test_animation_contract():
    with tempfile.TemporaryDirectory() as raw:
        root=Path(raw); family=fixture(root); inbox=root/"asset_drop/inbox/fixture"; png(inbox/"active.png")
        plan=generate_plan(family,inbox,root)
        assert any("requires animation" in error for error in plan.errors)


def test_replacement_and_backend():
    with tempfile.TemporaryDirectory() as raw:
        root=Path(raw); family=fixture(root); inbox=root/"asset_drop/inbox/fixture"; png(inbox/"idle.png")
        plan=generate_plan(family,inbox,root); item=plan.assets[0]; assert item.operation == AssetOperation.CREATE
        result=runtime_stage(item,root); assert result.ok and result.operation == AssetOperation.CREATE
        duplicate=generate_plan(family,inbox,root).assets[0]; assert duplicate.operation == AssetOperation.DUPLICATE
        before=(root/duplicate.target_relative_path).stat().st_mtime_ns
        assert runtime_stage(duplicate,root).ok and (root/duplicate.target_relative_path).stat().st_mtime_ns == before
        png(inbox/"idle.png", color=(99,1,1,255)); replacement=generate_plan(family,inbox,root).assets[0]
        assert replacement.operation == AssetOperation.REPLACE and not runtime_stage(replacement,root).ok
        assert runtime_stage(replacement,root,replace=True).ok


def test_duplicate_rollback_survives():
    with tempfile.TemporaryDirectory() as raw:
        root=Path(raw); family=fixture(root); inbox=root/"asset_drop/inbox/fixture"; png(inbox/"idle.png")
        first=generate_plan(family,inbox,root).assets[0]; runtime_stage(first,root)
        duplicate=generate_plan(family,inbox,root).assets[0]; record,_=begin_transaction("job",root,[duplicate])
        created=root/"content/temporary.png"; png(created); record.created_targets.append(created)
        rollback_transaction(record,root)
        assert (root/duplicate.target_relative_path).exists() and not created.exists()
        original=(root/duplicate.target_relative_path).read_bytes()
        png(inbox/"idle.png",color=(200,2,2,255)); replacement=generate_plan(family,inbox,root).assets[0]
        assert replacement.operation == AssetOperation.REPLACE
        record,_=begin_transaction("replace_job",root,[replacement])
        (root/replacement.target_relative_path).write_bytes(b"broken")
        catalog=root/"content/metadata/assets/generated/asset_catalog.generated.json"
        catalog.parent.mkdir(parents=True,exist_ok=True); catalog.write_text("{}")
        rollback_transaction(record,root)
        assert (root/replacement.target_relative_path).read_bytes() == original
        assert not catalog.exists() and (inbox/"idle.png").exists()


def test_sprite_delegation_and_dry_run():
    with tempfile.TemporaryDirectory() as raw:
        root=Path(raw); family=fixture(root); inbox=root/"asset_drop/inbox/fixture"; png(inbox/"active.png",(64,8))
        item=generate_plan(family,inbox,root).assets[0]; assert item.backend == "sprite_ingest"
        manifest=build_manifest(item,Path(item.canonical_filename)); assert manifest["mode"] == "strip" and manifest["frame_size"] == [16,8]
        before=snapshot(root); assert sprite_stage(item,root,dry_run=True).ok; assert snapshot(root)==before
        old_project, old_inbox = asset_cli.PROJECT_DIR, asset_cli.INBOX_ROOT
        try:
            asset_cli.PROJECT_DIR, asset_cli.INBOX_ROOT = root, root / "asset_drop/inbox"
            args = SimpleNamespace(family="fixture", dry_run=True, replace=False, yes=True, godot_import=False)
            before=snapshot(root); assert asset_cli.cmd_ingest(args,{"fixture":family}) == 0; assert snapshot(root)==before
            assert not (root / "asset_drop/staging").exists()
        finally:
            asset_cli.PROJECT_DIR, asset_cli.INBOX_ROOT = old_project, old_inbox


def test_status_runtime_not_inbox():
    with tempfile.TemporaryDirectory() as raw:
        root=Path(raw); family=fixture(root); inbox=root/"asset_drop/inbox/fixture"; png(inbox/"idle.png")
        status=get_family_status(family,root); assert status.states["idle"].source_pending and not status.states["idle"].art_present
        item=generate_plan(family,inbox,root).assets[0]; runtime_stage(item,root)
        output=root/item.target_relative_path; digest=hashlib.sha256(output.read_bytes()).hexdigest()
        catalog=root/"content/metadata/assets/generated/asset_catalog.generated.json"; catalog.parent.mkdir(parents=True)
        catalog.write_text(json.dumps({"schema":"custodian.asset_catalog.v1","families":{"fixture":{"states":{"idle":{"path":item.target_relative_path.as_posix(),"sha256":digest}}}}}))
        (inbox/"idle.png").unlink(); status=get_family_status(family,root)
        assert status.states["idle"].art_present and not status.states["idle"].source_pending and not status.states["idle"].bound


def snapshot(root: Path):
    return {p.relative_to(root).as_posix():(p.stat().st_size,p.stat().st_mtime_ns) for p in root.rglob("*") if p.is_file()}


CASES={"contract":test_contract_and_plan,"plan":test_contract_and_plan,"ingest":test_replacement_and_backend,
       "replacement":test_replacement_and_backend,"transaction":test_duplicate_rollback_survives,
       "status":test_status_runtime_not_inbox,"backend":test_sprite_delegation_and_dry_run,
       "animation":test_animation_contract}

def run(*names: str):
    for name in names: CASES[name]()
    print("PASS:", ", ".join(names))
