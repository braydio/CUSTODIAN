from pathlib import Path

from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Input, Label


class ImportSourceDialog(ModalScreen[Path | None]):
    def compose(self) -> ComposeResult:
        with Vertical(classes="dialog"):
            yield Label("IMPORT OPERATOR 2.5D SOURCE", classes="dialog-title")
            yield Label("Choose a PNG from custodian/asset_drop/inbox/operator_2_5d")
            yield Input(placeholder="PNG path", id="source-path")
            with Horizontal(classes="dialog-buttons"):
                yield Button("CANCEL", id="cancel")
                yield Button("IMPORT", id="confirm", variant="primary")
                yield Button("DIRECTION SET", id="direction-set")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "cancel":
            self.dismiss(None)
            return
        if event.button.id == "direction-set":
            self.dismiss(Path("__direction_set__"))
            return
        value = self.query_one("#source-path", Input).value.strip()
        self.dismiss(Path(value) if value else None)


class DirectionSetImportDialog(ModalScreen[dict[str, Path] | None]):
    DIRECTIONS = ("n", "ne", "e", "se", "s", "sw", "w", "nw")

    def compose(self) -> ComposeResult:
        with Vertical(classes="dialog"):
            yield Label("IMPORT EIGHT DIRECTIONS", classes="dialog-title")
            yield Label("Map each target direction to one authorized PNG. Cell order is never inferred.")
            for direction in self.DIRECTIONS:
                yield Input(placeholder=f"{direction.upper()} source PNG path", id=f"source-{direction}")
            with Horizontal(classes="dialog-buttons"):
                yield Button("CANCEL", id="cancel")
                yield Button("IMPORT SET", id="confirm", variant="primary")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "cancel":
            self.dismiss(None)
            return
        sources = {direction: Path(self.query_one(f"#source-{direction}", Input).value.strip())
                   for direction in self.DIRECTIONS
                   if self.query_one(f"#source-{direction}", Input).value.strip()}
        self.dismiss(sources)
