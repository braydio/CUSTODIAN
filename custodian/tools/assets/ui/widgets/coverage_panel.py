"""Family-level dashboard: tier coverage, missing states, inbox waiting."""
from textual.widgets import Static

from ..state import FamilyProjection


class CoveragePanel(Static):
    def show(self, projection: FamilyProjection) -> None:
        heading = f"{projection.family_id}  ·  {projection.kind}"
        lines = [
            heading,
            "─" * len(heading),
            f"{projection.canvas[0]}x{projection.canvas[1]}  ·  {projection.direction_policy}  ·  "
            f"auto_mirror={'on' if projection.auto_mirror else 'off'}",
            f"completeness: {projection.completeness}",
            "consumers: " + (", ".join(str(consumer.get("path", "?")) for consumer in projection.consumers) or "none"),
            "",
        ]
        for tier in ("required", "recommended", "optional"):
            states = [state for state in projection.states if state.tier == tier]
            if not states:
                continue
            ready = sum(1 for state in states if state.art_present)
            lines.append(f"{tier.upper():12} {ready}/{len(states)} ready")
        missing = [state for state in projection.states if not state.art_present and state.tier in ("required", "recommended")]
        if missing:
            lines += ["", "NEEDS ART"]
            for state in missing:
                present = ", ".join(direction.upper() for direction in state.authored_directions + state.mirrored_directions) or "none"
                lines.append(f"  {state.state_id:26} has: {present}")
        if projection.inbox_files:
            lines += ["", f"INBOX WAITING ({len(projection.inbox_files)})"]
            for name in projection.inbox_files:
                lines.append(f"  {name}")
        self.update("\n".join(lines))
