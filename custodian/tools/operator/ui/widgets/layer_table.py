from textual.widgets import DataTable
from ..state import SessionView


class LayerTable(DataTable):
    def on_mount(self) -> None:
        self.cell_padding = 0
        _, self._live_column, _, _ = self.add_columns("LAYER", "LIVE", "CONTRACT", "CANVAS")
        self.cursor_type = "row"
        self._layers = ()
        self._row_keys = ()
        self._live_visibility: dict[str, bool] = {}

    def show_session(self, session: SessionView) -> None:
        self.clear()
        self._layers = session.layers
        row_keys = []
        for layer in session.layers:
            name = layer.layer if layer.publishing else f"↳ {layer.layer} [reference]"
            contract = f"{layer.source_frames} → {layer.workspace_frames} → {layer.publish_frames}"
            row_keys.append(self.add_row(name, self._live_marker(layer.layer), contract, layer.canvas))
        self._row_keys = tuple(row_keys)

    def _live_marker(self, layer: str) -> str:
        visible = self._live_visibility.get(layer)
        return "?" if visible is None else ("●" if visible else "○")

    def layer_name_at(self, row_index: int) -> str | None:
        if row_index < 0 or row_index >= len(self._layers):
            return None
        return self._layers[row_index].layer

    def selected_layer_name(self) -> str | None:
        return self.layer_name_at(self.cursor_row)

    def select_live_layer(self, layer: str) -> None:
        for index, view in enumerate(self._layers):
            if view.layer == layer:
                self.move_cursor(row=index)
                return

    def set_live_visibility(self, layer: str, visible: bool) -> None:
        self._live_visibility[layer] = visible
        for index, view in enumerate(self._layers):
            if view.layer == layer:
                self.update_cell(self._row_keys[index], self._live_column, self._live_marker(layer))
                return

    def clear_live_state(self) -> None:
        self._live_visibility.clear()
        for index, view in enumerate(self._layers):
            self.update_cell(self._row_keys[index], self._live_column, "?")

    def selected_detail(self, row_index: int) -> str:
        if row_index < 0 or row_index >= len(self._layers):
            return ""
        layer = self._layers[row_index]
        return (
            f"Owner: {layer.owner}   Profile: {layer.profile}\n"
            f"Role: {layer.role}   Publish: {'yes' if layer.publishing else 'no (reference)'}"
        )
