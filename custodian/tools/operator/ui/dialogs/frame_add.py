from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Input, Label, RadioButton, RadioSet, Static
from ..state import MigrationView


class FrameAddDialog(ModalScreen[dict | None]):
    def __init__(self, preview: MigrationView) -> None:
        super().__init__(); self.preview = preview

    def compose(self) -> ComposeResult:
        p = self.preview
        excluded = "\n".join(f"- {name}: {reason}" for name, reason in p.excluded) or "- none"
        with Vertical(classes="dialog"):
            yield Label("ADD FRAME", classes="dialog-title")
            yield Static(f"Current contract       {p.old_frames} frames", classes="dialog-body")
            yield Input(str(p.position), placeholder="After frame", type="integer", id="frame-position")
            with RadioSet(id="frame-fill"):
                yield RadioButton("Duplicate previous", value=p.fill == "duplicate-prev")
                yield RadioButton("Duplicate next", value=p.fill == "duplicate-next")
                yield RadioButton("Blank", value=p.fill == "blank")
            yield Static("AFFECTED\n" + "\n".join(f"✓ {x}   {p.old_frames} → {p.new_frames}" for x in p.affected) + f"\n\nEXCLUDED\n{excluded}\n\nDependency audit      {p.audit}", classes="dialog-body", id="frame-add-preview")
            with Horizontal(classes="dialog-buttons"):
                yield Button("CANCEL", id="cancel")
                yield Button("STAGE MIGRATION", id="confirm", variant="success", disabled=p.audit != "GREEN")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "cancel": self.dismiss(None); return
        fills = ("duplicate-prev", "duplicate-next", "blank")
        value = int(self.query_one("#frame-position", Input).value)
        fill = fills[self.query_one("#frame-fill", RadioSet).pressed_index]
        self.dismiss({"operation": "add", "position": value, "fill": fill})
