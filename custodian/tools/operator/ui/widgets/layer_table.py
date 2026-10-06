from textual.widgets import DataTable
from ..state import LayerView, SessionView


class LayerTable(DataTable):
    def on_mount(self) -> None:
        self.cell_padding = 0
        self.add_column("LAYER",width=10)
        self._live_column=self.add_column("LIVE",width=2)
        self.add_column("CLK",width=7)
        self.add_column("CANVAS",width=6)
        self.cursor_type = "row"
        self._layers = ()
        self._row_keys = ()
        self._adoptable = []
        self._detail = []
        self._live_visibility: dict[str, bool] = {}

    def show_session(self, session: SessionView, *, live_layer_names=(), live_modified: bool = False) -> None:
        self.clear()
        saved_names={layer.layer for layer in session.layers}
        live_only=tuple(LayerView(name,"unsaved live","operator",session.selection.profile,0,0,0,"—",False,False)
            for name in sorted((set(live_layer_names)&{"vfx","fx"})-saved_names)) if live_modified else ()
        self._layers = (*session.layers,*live_only)
        row_keys = []
        live_names=set(live_layer_names); self._adoptable=[]; self._detail=[]
        for layer in self._layers:
            if layer.publishing: name=layer.layer
            elif layer.role=="reference": name=f"↳ {layer.layer} [reference]"
            elif layer.layer in live_names and live_modified: name=f"{layer.layer} [UNSAVED · SAVE FIRST]"
            else: name=f"↳ {layer.layer} [unbound]"
            contract = f"{layer.source_frames}→{layer.workspace_frames}→{layer.publish_frames}"
            row_keys.append(self.add_row(name, self._live_marker(layer.layer), contract, layer.canvas))
            blocked=live_modified and (layer.layer in {"vfx","fx"})
            self._adoptable.append(bool(layer.adoptable and not blocked))
            self._detail.append(f"Owner: {layer.owner}   Profile: {layer.profile}\nRole: {layer.role}   Publish: {'yes' if layer.publishing else 'no'}"+
                ("\nSave the connected Workbench before adopting this layer." if blocked else "\nPress F to explicitly adopt this saved layer as semantic FX." if layer.adoptable else ""))
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

    def selected_layer_adoptable(self) -> bool:
        return 0<=self.cursor_row<len(self._adoptable) and self._adoptable[self.cursor_row]

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
        return self._detail[row_index] if row_index<len(self._detail) else ""
