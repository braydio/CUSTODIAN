from textual.widgets import DataTable
from ..state import SessionView


class LayerTable(DataTable):
    def on_mount(self) -> None:
        self.cell_padding = 0
        self.add_columns("LAYER", "CONTRACT", "CANVAS")
        self.cursor_type = "row"
        self._layers = ()

    def show_session(self, session: SessionView) -> None:
        self.clear()
        self._layers = session.layers
        for layer in session.layers:
            name = layer.layer if layer.publishing else f"↳ {layer.layer} [reference]"
            contract = f"{layer.source_frames} → {layer.workspace_frames} → {layer.publish_frames}"
            self.add_row(name, contract, layer.canvas)

    def selected_detail(self, row_index: int) -> str:
        if row_index < 0 or row_index >= len(self._layers):
            return ""
        layer = self._layers[row_index]
        return (
            f"Owner: {layer.owner}   Profile: {layer.profile}\n"
            f"Role: {layer.role}   Publish: {'yes' if layer.publishing else 'no (reference)'}"
        )
