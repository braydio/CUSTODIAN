"""Side-effect-free Asset V2 read model for the Asset Workbench."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Callable

ASSET_TOOLS_DIR = Path(__file__).resolve().parents[1]
PROJECT_DIR = ASSET_TOOLS_DIR.parent.parent
if str(ASSET_TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSET_TOOLS_DIR))

from asset_contract import AssetFamilyContract, load_all_families
from asset_status import FamilyStatus, get_family_status

from .models import AssetSnapshot, FamilyProjection, StateProjection


FamilyLoader = Callable[[Path | None], dict[str, AssetFamilyContract]]
StatusLoader = Callable[[AssetFamilyContract, Path], FamilyStatus]


def _role(state) -> str:
    if state.required:
        return "required"
    if state.recommended:
        return "recommended"
    return "optional"


class AssetWorkbenchService:
    """Compose contracts and current status without mutating asset authorities."""

    def __init__(
        self,
        project_dir: Path = PROJECT_DIR,
        families_dir: Path | None = None,
        *,
        family_loader: FamilyLoader = load_all_families,
        status_loader: StatusLoader = get_family_status,
    ) -> None:
        self.project_dir = Path(project_dir)
        self.families_dir = Path(families_dir) if families_dir is not None else None
        self._family_loader = family_loader
        self._status_loader = status_loader

    def build_snapshot(self) -> AssetSnapshot:
        """Build a complete candidate snapshot or raise without partial acceptance."""
        contracts = self._family_loader(self.families_dir)
        projections = []
        for family_id in sorted(contracts):
            family = contracts[family_id]
            status = self._status_loader(family, self.project_dir)
            states = tuple(
                self._state_projection(family, state, status.states[state_id])
                for state_id, state in family.states.items()
            )
            consumers = tuple(
                tuple(sorted((str(key), str(value)) for key, value in consumer.items()))
                for consumer in family.consumers
            )
            projections.append(
                FamilyProjection(
                    family_id=family.id,
                    kind=family.kind,
                    required_completeness=status.completeness,
                    canvas_width=family.frame_width,
                    canvas_height=family.frame_height,
                    direction_policy=family.direction_policy,
                    allowed_directions=family.allowed_directions,
                    auto_mirror=family.auto_mirror,
                    consumers=consumers,
                    inbox_exists=status.inbox_exists,
                    inbox_pending_filenames=tuple(status.inbox_files),
                    runtime_outputs=tuple(status.runtime_outputs),
                    states=states,
                )
            )
        return AssetSnapshot(tuple(projections))

    @staticmethod
    def _state_projection(family, state, status) -> StateProjection:
        frame_width, frame_height = family.state_frame_size(state)
        return StateProjection(
            state_id=state.id,
            role=_role(state),
            layer=state.layer,
            action_group=state.action_group,
            animation=state.animation,
            fps=state.fps,
            expected_frames=state.expected_frames,
            frame_width=frame_width,
            frame_height=frame_height,
            min_direction_count=status.min_direction_count,
            required_directions=tuple(status.required_directions),
            authored_directions=tuple(status.authored_directions),
            mirrored_directions=tuple(status.mirrored_directions),
            source_pending=status.source_pending,
            art_present=status.art_present,
            imported=status.imported,
            bound=status.bound,
            runtime_verified=status.runtime_verified,
            runtime_path=status.runtime_path,
        )
