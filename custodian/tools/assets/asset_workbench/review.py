"""Read-only source/runtime review projections for Asset Pipeline V2."""

from __future__ import annotations

import hashlib
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops

ASSETS_DIR = Path(__file__).resolve().parents[1]
PROJECT_DIR = ASSETS_DIR.parent.parent
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))

from asset_catalog import CATALOG_PATH, load_catalog
from asset_contract import AssetFamilyContract, load_all_families
from asset_inspector import AssetInspection, FrameLayout, inspect_png
from asset_plan import PlannedAsset, generate_plan
from asset_router import load_kind_schemas

LFS_SIGNATURE = b"version https://git-lfs.github.com/spec/v1"


@dataclass(frozen=True)
class ReviewRepresentation:
    kind: str
    family_id: str
    state_id: str
    direction: str
    layer: str
    source_path: Path
    layout: FrameLayout
    frame_count: int
    frame_width: int
    frame_height: int
    columns: int | None
    rows: int | None
    provenance: str | None
    source_asset: str | None
    fps: float | None
    trusted: bool
    diagnostics: tuple[str, ...] = ()


@dataclass(frozen=True)
class ReviewResult:
    representations: tuple[ReviewRepresentation, ...]
    diagnostics: tuple[str, ...] = ()


def _is_lfs_pointer(path: Path) -> bool:
    try:
        with path.open("rb") as stream:
            return stream.read(256).startswith(LFS_SIGNATURE)
    except OSError:
        return False


def extract_frames(path: Path, inspection: AssetInspection) -> tuple[Image.Image, ...]:
    """Split exact RGBA frames according to the inspector's accepted layout."""
    if inspection.layout is FrameLayout.AMBIGUOUS or inspection.frame_count < 1:
        raise ValueError("ambiguous or mismatched frame geometry")
    if _is_lfs_pointer(path):
        raise ValueError(f"LFS OBJECT NOT HYDRATED: {path}")
    with Image.open(path) as opened:
        image = opened.convert("RGBA")
    fw, fh = inspection.frame_width, inspection.frame_height
    layout = inspection.layout
    if layout is FrameLayout.COPY:
        boxes = [(0, 0, fw, fh)]
    elif layout is FrameLayout.HORIZONTAL_STRIP:
        boxes = [(i * fw, 0, (i + 1) * fw, fh) for i in range(inspection.frame_count)]
    elif layout is FrameLayout.VERTICAL_STRIP:
        boxes = [(0, i * fh, fw, (i + 1) * fh) for i in range(inspection.frame_count)]
    elif layout is FrameLayout.GRID:
        if not inspection.columns or not inspection.rows or inspection.columns * inspection.rows != inspection.frame_count:
            raise ValueError("grid inspection is missing valid row/column geometry")
        boxes = [
            (column * fw, row * fh, (column + 1) * fw, (row + 1) * fh)
            for row in range(inspection.rows)
            for column in range(inspection.columns)
        ]
    else:
        raise ValueError(f"unsupported frame layout: {layout}")
    frames = tuple(image.crop(box) for box in boxes)
    if any(frame.size != (fw, fh) for frame in frames):
        raise ValueError("frame extraction changed source pixel dimensions")
    return frames


def scale_frame_nearest(frame: Image.Image, zoom: int = 1) -> Image.Image:
    """Apply an explicit integer review zoom without interpolating pixels."""
    if isinstance(zoom, bool) or not isinstance(zoom, int) or zoom < 1:
        raise ValueError("review zoom must be a positive integer")
    rgba = frame.convert("RGBA")
    if zoom == 1:
        return rgba.copy()
    return rgba.resize((rgba.width * zoom, rgba.height * zoom), Image.Resampling.NEAREST)


def _selected_plan_assets(family: AssetFamilyContract, project_dir: Path) -> tuple[dict[str, PlannedAsset], tuple[str, ...]]:
    inbox = project_dir / "asset_drop/inbox" / family.id
    if not inbox.is_dir():
        return {}, ()
    pointers = {path.name for path in inbox.glob("*.png") if _is_lfs_pointer(path)}
    assets: dict[str, PlannedAsset] = {}
    diagnostics = [f"{name}: LFS OBJECT NOT HYDRATED: {inbox / name}" for name in sorted(pointers)]
    # Plan each physical input through the canonical authority independently:
    # a malformed neighbor or batch-level collision must not hide a valid
    # selected source from the read-only review surface.
    with tempfile.TemporaryDirectory(prefix="asset-review-inbox-") as temporary:
        for index, path in enumerate(sorted(inbox.glob("*.png"))):
            if path.name in pointers:
                continue
            staged = Path(temporary) / str(index)
            staged.mkdir()
            (staged / path.name).symlink_to(path.resolve())
            try:
                plan = generate_plan(family, staged, project_dir, kind_schemas=load_kind_schemas())
            except Exception as error:
                diagnostics.append(f"{path.name}: source planning failed: {error}")
                continue
            for asset in plan.assets:
                assets[path.name] = asset
            diagnostics.extend(f"{path.name}: planner: {error}" for error in plan.errors)
    return assets, tuple(diagnostics)


class AssetReviewService:
    """Resolve selected state representations from existing Asset V2 authorities."""

    def __init__(self, project_dir: Path = PROJECT_DIR, *, catalog_path: Path | None = None) -> None:
        self.project_dir = Path(project_dir)
        self.catalog_path = catalog_path or self.project_dir / CATALOG_PATH.relative_to(PROJECT_DIR)

    def representations(self, family_id: str, state_id: str) -> ReviewResult:
        try:
            family = load_all_families(self.project_dir / "content/metadata/assets/families").get(family_id)
        except Exception as error:
            return ReviewResult((), (f"Asset V2 family read failed: {error}",))
        if family is None or state_id not in family.states:
            return ReviewResult((), (f"Unknown Asset V2 selection: {family_id} / {state_id}",))
        contract = family.states[state_id]
        fw, fh = family.state_frame_size(contract)
        staged_assets, plan_diagnostics = _selected_plan_assets(family, self.project_dir)
        result: list[ReviewRepresentation] = []
        diagnostics: list[str] = list(plan_diagnostics)
        for asset in staged_assets.values():
            if asset.state_id != state_id:
                continue
            path = self.project_dir / "asset_drop/inbox" / family_id / asset.source_path.name
            if _is_lfs_pointer(path):
                continue
            selected_errors = tuple(error for error in plan_diagnostics if asset.source_path.name in error)
            result.append(ReviewRepresentation(
                "staged", family_id, state_id, asset.resolution.direction or "unknown", contract.layer,
                path, asset.inspection.layout, asset.inspection.frame_count, fw, fh,
                asset.inspection.columns, asset.inspection.rows,
                "authored", None, contract.fps, asset.inspection.layout is not FrameLayout.AMBIGUOUS,
                selected_errors,
            ))

        try:
            catalog = load_catalog(self.catalog_path)
        except Exception as error:
            diagnostics.append(f"Runtime catalog read failed: {error}")
            return ReviewResult(tuple(result), tuple(diagnostics))
        family_data = catalog.get("families", {}).get(family_id, {})
        entries = family_data.get("assets", {})
        for entry in entries.values():
            if entry.get("state_id") != state_id:
                continue
            direction = str(entry.get("direction", "omni"))
            relative = Path(str(entry.get("path", "")))
            if relative.is_absolute() or ".." in relative.parts:
                result.append(ReviewRepresentation("runtime", family_id, state_id, direction, contract.layer,
                    self.project_dir / relative, FrameLayout.AMBIGUOUS, int(entry.get("frames") or 0), fw, fh,
                    None, None, contract.fps, False, (f"runtime catalog path escapes project root: {relative}",)))
                continue
            path = self.project_dir / relative
            try:
                resolved_path = path.resolve()
                resolved_path.relative_to(self.project_dir.resolve())
            except (OSError, ValueError):
                result.append(ReviewRepresentation("runtime", family_id, state_id, direction, contract.layer,
                    path, FrameLayout.AMBIGUOUS, int(entry.get("frames") or 0), fw, fh,
                    None, None, contract.fps, False, (f"runtime catalog path escapes project root: {relative}",)))
                continue
            issues: list[str] = []
            expected_size = entry.get("frame_size")
            frames = entry.get("frames")
            if not path.is_file():
                issues.append(f"runtime file missing: {path}")
                result.append(ReviewRepresentation("runtime", family_id, state_id, direction, contract.layer,
                    path, FrameLayout.AMBIGUOUS, int(frames or 0), fw, fh, None, None, entry.get("provenance"),
                    entry.get("source_asset"), contract.fps, False, tuple(issues)))
                continue
            if _is_lfs_pointer(path):
                issues.append(f"LFS OBJECT NOT HYDRATED: {path}")
                result.append(ReviewRepresentation("runtime", family_id, state_id, direction, contract.layer,
                    path, FrameLayout.AMBIGUOUS, int(frames or 0), fw, fh, None, None, entry.get("provenance"),
                    entry.get("source_asset"), contract.fps, False, tuple(issues)))
                continue
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            if digest != entry.get("sha256"):
                issues.append(f"runtime catalog SHA-256 mismatch: {path}")
            if expected_size != [fw, fh]:
                issues.append(f"catalog frame size mismatch: expected {(fw, fh)}, found {expected_size}")
            if contract.expected_frames is not None and frames != contract.expected_frames:
                issues.append(f"Asset V2 state frame contract mismatch: expected {contract.expected_frames}, catalog declares {frames}")
            try:
                inspection = inspect_png(path, fw, fh, "horizontal_strip" if int(frames or 0) > 1 else "copy")
                if inspection.frame_count != frames:
                    issues.append(f"runtime frame count mismatch: catalog {frames}, file {inspection.frame_count}")
            except Exception as error:
                inspection = AssetInspection(path, 0, 0, fw, fh, 0, FrameLayout.AMBIGUOUS)
                issues.append(f"runtime image inspection failed: {error}")
            result.append(ReviewRepresentation(
                "runtime", family_id, state_id, direction, contract.layer, path, inspection.layout,
                inspection.frame_count, fw, fh, inspection.columns, inspection.rows,
                entry.get("provenance"), entry.get("source_asset"),
                contract.fps, not issues, tuple(issues),
            ))
        if not result:
            diagnostics.append(f"No staged or cataloged runtime representation for {family_id} / {state_id}.")
        return ReviewResult(tuple(sorted(result, key=lambda item: (item.kind != "runtime", item.direction, str(item.source_path)))), tuple(diagnostics))


def compare_frames(left: Image.Image, right: Image.Image, mode: str) -> tuple[Image.Image | None, str | None, int, tuple[int, int, int, int] | None]:
    """Return same-size overlay/diff evidence; never resample mismatched images."""
    if left.size != right.size:
        return None, f"Comparison requires equal frame dimensions; got {left.size} and {right.size}.", 0, None
    a, b = left.convert("RGBA"), right.convert("RGBA")
    if mode == "overlay":
        return Image.blend(a, b, 0.5), None, 0, None
    if mode != "diff":
        return None, f"Unsupported comparison mode: {mode}", 0, None
    diff = ImageChops.difference(a, b)
    changed = diff.convert("RGB").getbbox()
    count = sum(1 for pixel in diff.getdata() if pixel != (0, 0, 0, 0))
    return diff, None, count, changed


def side_by_side_frames(left: Image.Image, right: Image.Image) -> Image.Image:
    """Place source frames adjacently at their exact dimensions."""
    a, b = left.convert("RGBA"), right.convert("RGBA")
    canvas = Image.new("RGBA", (a.width + b.width, max(a.height, b.height)), (36, 40, 48, 255))
    canvas.paste(a, (0, 0))
    canvas.paste(b, (a.width, 0))
    return canvas
