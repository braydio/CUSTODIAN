from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Label, Static
from ..state import CanvasMigrationView


class CanvasMigrationDialog(ModalScreen[bool | None]):
    def __init__(self, preview: CanvasMigrationView) -> None:
        super().__init__()
        self.preview = preview

    def compose(self) -> ComposeResult:
        p = self.preview
        report = p.raw
        changes = {item["binding_id"]: item for item in report.get("layer_changes", ())}
        affected = "\n".join(f"✓ {name}   {changes[name]['old_size'][0]}×{changes[name]['old_size'][1]} → {changes[name]['new_size'][0]}×{changes[name]['new_size'][1]}" for name in p.affected)
        excluded = "\n".join(f"- {name}: {reason}" for name, reason in p.excluded) or "- none"
        audit = "GREEN" if p.audit == "GREEN" else f"{p.audit} · coordinate migration required"
        with Vertical(classes="dialog"):
            yield Label("CANVAS MIGRATION REVIEW", classes="dialog-title")
            yield Static(f"Document              {p.old_document_size[0]}×{p.old_document_size[1]} → {p.new_document_size[0]}×{p.new_document_size[1]}\nScope                 {p.scope}\nFrames                unchanged\nPixel scaling         none\nClipping              checked before staging\n\nAFFECTED\n{affected}\n\nEXCLUDED\n{excluded}\n\nCoordinate dependencies  {audit}", classes="dialog-body")
            with Horizontal(classes="dialog-buttons"):
                yield Button("CANCEL", id="cancel")
                yield Button("STAGE CANVAS MIGRATION", id="confirm", variant="success", disabled=p.audit != "GREEN")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        self.dismiss(None if event.button.id == "cancel" else True)
