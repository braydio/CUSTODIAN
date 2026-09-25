from pathlib import Path

from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Checkbox, Label, Static

from ..state import PublishRow, PublishView


DIRECTION_NAMES = {
    "n": "NORTH", "ne": "NORTH-EAST", "e": "EAST", "se": "SOUTH-EAST",
    "s": "SOUTH", "sw": "SOUTH-WEST", "w": "WEST", "nw": "NORTH-WEST",
    "omni": "OMNI",
}
OPERATION_STYLE = {"CREATE": "green", "REPLACE": "yellow", "UNCHANGED": "dim"}


def _target(path: str, width: int = 34) -> str:
    value = Path(path)
    compact = f"{value.parent.name}/{value.name}" if value.name else "—"
    if len(compact) <= width:
        return compact
    return f"{compact[:9]}…{compact[-(width-10):]}"


def _rows(rows: tuple[PublishRow, ...]) -> str:
    lines = ["Layer          Dir       Change     Target"]
    for row in rows:
        style = OPERATION_STYLE.get(row.operation, "")
        operation = f"[{style}]{row.operation:<9}[/{style}]" if style else f"{row.operation:<9}"
        lines.append(f"{row.layer[:13]:<14} {row.direction.upper()[:9]:<9} {operation}  {_target(row.target_path)}")
    return "\n".join(lines)


class PublishDialog(ModalScreen[tuple[bool, bool] | None]):
    def __init__(self, preview: PublishView, aseprite_open: bool = False) -> None:
        super().__init__()
        self.preview = preview
        self.aseprite_open = aseprite_open

    def _mirror_consequence(self) -> str:
        creates = self.preview.mirror_operations.count("CREATE")
        replaces = self.preview.mirror_operations.count("REPLACE")
        target = DIRECTION_NAMES.get(self.preview.counterpart_direction or "", self.preview.counterpart_direction or "counterpart")
        if creates and replaces:
            consequence = f"Creates {creates} and replaces {replaces} {target} sources."
        elif creates:
            consequence = f"Creates {creates} {target} source{'s' if creates != 1 else ''}."
        elif replaces:
            consequence = f"Replaces {replaces} existing {target} source{'s' if replaces != 1 else ''}."
        else:
            count = len(self.preview.mirror_operations)
            consequence = f"{count} {target} source{'s' if count != 1 else ''} unchanged."
        return consequence + "\nFrame-wise mirror; animation order preserved."

    def _details(self) -> str:
        p = self.preview
        durations = list(p.durations) if p.durations else "uniform/default"
        lines = ["TIMING", f"FPS: {p.fps:g}  Loop: {p.loop}  Durations: {durations}", "", "DIRECT PATHS"]
        for row in p.direct_rows:
            lines.extend((f"{row.layer} old: {row.old_path}", f"{row.layer} target: {row.target_path}"))
        if p.mirror_rows:
            lines.extend(("", "MIRROR PATHS"))
            for row in p.mirror_rows:
                lines.extend((f"{row.layer} old: {row.old_path or 'none'}", f"{row.layer} target: {row.target_path}"))
        if p.retired_paths:
            lines.extend(("", "RETIRED CONTRACTS", *p.retired_paths))
        lines.extend(("", "PREFLIGHT DETAIL", f"Dependency audit: {p.audit}", f"Compatibility preflight: {'PASS' if p.compatibility_preflight else 'FAIL'}"))
        return "\n".join(lines)

    def compose(self) -> ComposeResult:
        p = self.preview
        selection = p.selection
        timing = f"{p.new_frames} frames    {p.fps:g} FPS    {'LOOP' if p.loop else 'NON-LOOP'}"
        if p.variable_durations:
            timing += "    VARIABLE DURATIONS"
        layers = " + ".join(p.publishing_layers) or "no publishing layers"
        if p.migration and hasattr(p.migration, "old_document_size"):
            old, new = p.migration.old_document_size, p.migration.new_document_size
            contract = f"Canvas    {old[0]}×{old[1]} -> {new[0]}×{new[1]}"
        else:
            contract = f"Frames    {p.old_frames} -> {p.new_frames}" if p.contract_changed else "Frame contract unchanged"
        direction = DIRECTION_NAMES.get(selection.direction, selection.direction.upper())
        dependency = "[green]✓ Dependency audit[/green]" if p.audit == "GREEN" else "[red]✗ Dependency audit[/red]"
        compatibility = "[green]✓ Compatibility preflight[/green]" if p.compatibility_preflight else "[red]✗ Compatibility preflight[/red]"
        warning = " [yellow]Aseprite open: using last saved state.[/yellow]" if self.aseprite_open else ""
        with Vertical(classes="dialog publish-dialog"):
            yield Label("PUBLISH ANIMATION", classes="dialog-title")
            yield Static(f"[b]{selection.profile} / {selection.group} / {selection.action}[/b]\n[b]{direction}[/b]\n{timing}    {layers}\n{contract}", id="publish-summary", classes="publish-primary")
            yield Static("[b]DIRECT[/b]", classes="publish-section-title publish-primary")
            yield Static(_rows(p.direct_rows), classes="publish-table publish-primary", id="publish-direct")
            if p.counterpart_direction:
                yield Static("[b]MIRROR PROMOTION[/b]    NOT ENABLED", classes="publish-section-title publish-primary", id="mirror-title")
                yield Static(_rows(p.mirror_rows), classes="publish-table publish-primary", id="publish-mirror")
                yield Checkbox(f"Also publish mirrored counterpart ({selection.direction.upper()} -> {p.counterpart_direction.upper()})", id="mirror-counterpart", classes="publish-primary")
                yield Static(self._mirror_consequence(), id="mirror-consequence", classes="publish-primary")
            else:
                yield Static(f"[dim]Mirror promotion unavailable for {direction}.[/dim]", id="mirror-unavailable", classes="publish-primary")
            yield Static(f"{dependency}    {compatibility}{warning}", id="publish-preflight", classes="publish-primary")
            yield Checkbox("Full changed-file validation", id="full-validation", classes="publish-primary")
            yield Static(self._details(), id="publish-details", classes="hidden")
            with Horizontal(classes="dialog-buttons publish-buttons"):
                yield Button("DETAILS", id="details")
                yield Static("", id="publish-button-spacer")
                yield Button("CANCEL", id="cancel")
                yield Button("PUBLISH", id="confirm", variant="success", disabled=p.audit != "GREEN" or not p.compatibility_preflight)

    def on_checkbox_changed(self, event: Checkbox.Changed) -> None:
        if event.checkbox.id == "mirror-counterpart":
            status = "ENABLED" if event.value else "NOT ENABLED"
            self.query_one("#mirror-title", Static).update(f"[b]MIRROR PROMOTION[/b]    {status}")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "details":
            panel = self.query_one("#publish-details", Static)
            panel.toggle_class("hidden")
            for widget in self.query(".publish-primary"):
                widget.toggle_class("hidden")
            event.button.label = "HIDE DETAILS" if not panel.has_class("hidden") else "DETAILS"
            return
        mirror = self.query_one("#mirror-counterpart", Checkbox).value if self.preview.counterpart_direction else False
        result = None if event.button.id == "cancel" else (self.query_one("#full-validation", Checkbox).value, mirror)
        self.dismiss(result)
