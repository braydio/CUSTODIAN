from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Label, Static

from ..state import ExistingContextView


class ContextMismatchDialog(ModalScreen[str | None]):
    def __init__(self, existing: ExistingContextView, requested: ExistingContextView) -> None:
        super().__init__()
        self.existing = existing
        self.requested = requested

    def compose(self) -> ComposeResult:
        with Vertical(classes="dialog error-dialog"):
            yield Label("WORKBENCH CONTEXT MISMATCH", classes="dialog-title")
            yield Static(
                "Existing workspace:\n"
                f"  Weapon: {self.existing.weapon_label}\n"
                f"  Profile: {self.existing.profile_label}\n"
                f"  Presentation: {self.existing.presentation_mode or 'none'}\n\n"
                "Requested:\n"
                f"  Weapon: {self.requested.weapon_label}\n"
                f"  Profile: {self.requested.profile_label}\n"
                f"  Presentation: {self.requested.presentation_mode or 'none'}\n\n"
                "Recontextualize backs up the existing document, manifest, edits, "
                "and pending migration before refreshing through Workbench V2.",
                classes="dialog-body", id="context-mismatch-body",
            )
            with Horizontal(classes="dialog-buttons"):
                yield Button("CANCEL", id="cancel")
                yield Button("OPEN EXISTING CONTEXT", id="open-existing", variant="primary")
                yield Button("RECONTEXTUALIZE", id="recontextualize", variant="warning")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        result = {
            "open-existing": "open-existing",
            "recontextualize": "recontextualize",
        }.get(event.button.id)
        self.dismiss(result)
