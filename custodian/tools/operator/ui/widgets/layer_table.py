from textual.widgets import DataTable
from ..state import SessionView


class LayerTable(DataTable):
    def on_mount(self) -> None:
        self.add_columns("LAYER", "ROLE", "OWNER", "PROFILE", "SRC", "WORK", "PUB", "CANVAS")
        self.cursor_type = "row"

    def show_session(self, session: SessionView) -> None:
        self.clear()
        for layer in session.layers:
            name = layer.layer if layer.publishing else f"↳ {layer.layer} [reference]"
            self.add_row(name, layer.role, layer.owner, layer.profile, f"{layer.source_frames}f", f"{layer.workspace_frames}f", f"{layer.publish_frames}f", layer.canvas)
