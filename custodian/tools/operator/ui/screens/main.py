from textual.app import ComposeResult
from textual.containers import Container, Horizontal, Vertical
from textual.screen import Screen
from textual.widgets import Footer, Input, Label, Static

from ..widgets import ActivityLog, AnimationDetail, AnimationTree, LayerTable, WorkbenchStatusBar


class MainScreen(Screen):
    def compose(self) -> ComposeResult:
        yield WorkbenchStatusBar(id="workbench-status")
        yield Input(placeholder="Search profile / group / action / direction", id="search", classes="hidden")
        with Horizontal(id="workspace-row"):
            with Container(id="navigation-pane"):
                yield AnimationTree()
            with Container(id="detail-pane"):
                yield AnimationDetail("Select an animation", id="animation-detail")
            with Container(id="layers-pane"):
                yield Label("LAYERS", classes="pane-title")
                yield LayerTable(id="layer-table")
                yield Static("Select a layer for ownership details", id="layer-detail")
        with Vertical(id="activity-pane"):
            yield Label("ACTIVITY", classes="pane-title")
            yield ActivityLog(id="activity-log", max_lines=200, markup=True)
        yield Footer()
