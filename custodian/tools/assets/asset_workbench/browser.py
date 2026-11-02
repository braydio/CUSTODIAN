"""Transactional snapshot acceptance and pure in-memory navigation/filtering."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

from .models import AssetSnapshot, FamilyProjection, StateProjection


class SnapshotBuilder(Protocol):
    def build_snapshot(self) -> AssetSnapshot: ...


@dataclass(frozen=True)
class RefreshResult:
    accepted: bool
    message: str
    fallback: bool = False


class AssetWorkbenchBrowser:
    """Keep selection attached to semantic IDs across atomic refreshes."""

    def __init__(self, service: SnapshotBuilder) -> None:
        self.service = service
        self.snapshot: AssetSnapshot | None = None
        self.selected_family_id: str | None = None
        self.selected_state_id: str | None = None
        self.message = "Not loaded"

    @property
    def selected_family(self) -> FamilyProjection | None:
        return self.snapshot.family(self.selected_family_id) if self.snapshot and self.selected_family_id else None

    @property
    def selected_state(self) -> StateProjection | None:
        family = self.selected_family
        return family.state(self.selected_state_id) if family and self.selected_state_id else None

    def refresh(self) -> RefreshResult:
        try:
            candidate = self.service.build_snapshot()
        except Exception as error:
            self.message = f"Refresh failed; previous view retained: {error}"
            return RefreshResult(False, self.message)

        old_family_id = self.selected_family_id
        old_state_id = self.selected_state_id
        self.snapshot = candidate
        if not candidate.families:
            self.selected_family_id = None
            self.selected_state_id = None
            self.message = (
                f"Selected family '{old_family_id}' was removed; no readable Asset V2 families remain."
                if old_family_id else "No readable Asset V2 families are registered."
            )
            return RefreshResult(True, self.message, fallback=old_family_id is not None)

        family = candidate.family(old_family_id) if old_family_id else None
        if family is not None:
            if old_state_id and family.state(old_state_id) is not None:
                self.selected_family_id = family.family_id
                self.selected_state_id = old_state_id
                self.message = "Refreshed; selection preserved."
                return RefreshResult(True, self.message)
            self.selected_family_id = family.family_id
            self.selected_state_id = family.states[0].state_id if family.states else None
            if old_state_id:
                self.message = (
                    f"Selected state '{old_state_id}' was removed; moved to "
                    f"{family.family_id} / {self.selected_state_id or '(no states)'}."
                )
                return RefreshResult(True, self.message, fallback=True)
            self.message = f"Refreshed {family.family_id}; family selection preserved."
            return RefreshResult(True, self.message)

        family = candidate.families[0]
        self.selected_family_id = family.family_id
        self.selected_state_id = family.states[0].state_id if family.states else None
        if old_family_id is None:
            self.message = f"Loaded {len(candidate.families)} Asset V2 families."
            return RefreshResult(True, self.message)
        self.message = (
            f"Selected family '{old_family_id}' was removed; moved to "
            f"{family.family_id} / {self.selected_state_id or '(no states)'}."
        )
        return RefreshResult(True, self.message, fallback=True)

    def select_family(self, family_id: str) -> bool:
        family = self.snapshot.family(family_id) if self.snapshot else None
        if family is None:
            return False
        self.selected_family_id = family.family_id
        self.selected_state_id = family.states[0].state_id if family.states else None
        return True

    def select_state(self, family_id: str, state_id: str) -> bool:
        family = self.snapshot.family(family_id) if self.snapshot else None
        if family is None or family.state(state_id) is None:
            return False
        self.selected_family_id = family.family_id
        self.selected_state_id = state_id
        return True

    def visible_families(self, query: str = "") -> tuple[FamilyProjection, ...]:
        """Filter accepted projections only; this method never calls the service."""
        if self.snapshot is None:
            return ()
        needle = query.strip().casefold()
        if not needle:
            return self.snapshot.families
        return tuple(
            family for family in self.snapshot.families
            if self._family_matches(family, needle)
        )

    @staticmethod
    def visible_states(family: FamilyProjection, query: str = "") -> tuple[StateProjection, ...]:
        needle = query.strip().casefold()
        if not needle:
            return family.states
        family_text = " ".join((family.family_id, family.kind)).casefold()
        if needle in family_text:
            return family.states
        return tuple(
            state for state in family.states
            if needle in " ".join((state.state_id, state.role, state.layer, state.action_group)).casefold()
        )

    @classmethod
    def _family_matches(cls, family: FamilyProjection, needle: str) -> bool:
        family_text = " ".join((family.family_id, family.kind)).casefold()
        return needle in family_text or any(
            needle in " ".join((state.state_id, state.role, state.layer, state.action_group)).casefold()
            for state in family.states
        )
