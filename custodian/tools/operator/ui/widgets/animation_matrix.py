"""Action × direction view over the same generation-aware browser projection."""
from textual.widgets import DataTable

from ..state import AnimationRecord, AnimationSelection


DIRECTIONS = ("n", "ne", "e", "se", "s", "sw", "w", "nw")
MARKERS = {
    "CANONICAL_2_5D": "✓",
    "PARTIAL": "◐",
    "LEGACY_FALLBACK": "◇",
    "PROJECTED": "→",
    "MISSING": "·",
}


class AnimationMatrix(DataTable):
    """Compact canonical-target matrix; each cell resolves to a tree selection."""

    def __init__(self) -> None:
        super().__init__(id="animation-matrix")
        self.cursor_type = "cell"
        self._rows: list[tuple[AnimationSelection | None, ...]] = []

    def on_mount(self) -> None:
        self.add_column("PROFILE / GROUP / ACTION", key="action")
        for direction in DIRECTIONS:
            self.add_column(direction.upper(), key=direction)

    def set_records(self, records: list[AnimationRecord] | tuple[AnimationRecord, ...]) -> None:
        families: dict[tuple[str, str, str], dict[str, AnimationRecord]] = {}
        ranks: dict[tuple[str, str, str], int] = {}
        for record in records:
            selection = record.selection
            if selection.art_generation != "operator_2_5d_128":
                continue
            key = (selection.profile, selection.group, selection.action)
            families.setdefault(key, {})[selection.direction] = record
            if record.plan_rank is not None:
                ranks[key] = record.plan_rank
        ordered = sorted(families, key=lambda key: (ranks.get(key, 10**9), *key))
        self.clear()
        self._rows = []
        for family in ordered:
            leaves = families[family]
            selections: list[AnimationSelection | None] = [None]
            cells = ["/".join(family)]
            for direction in DIRECTIONS:
                record = leaves.get(direction)
                selections.append(record.selection if record else None)
                cells.append(MARKERS.get(record.coverage_status, "!") if record else "·")
            self.add_row(*cells, key="/".join(family))
            self._rows.append(tuple(selections))

    def selection_at(self, row: int, column: int) -> AnimationSelection | None:
        if row < 0 or row >= len(self._rows) or column < 1 or column >= len(self._rows[row]):
            return None
        return self._rows[row][column]
