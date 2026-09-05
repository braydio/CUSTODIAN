from textual.app import ComposeResult
from textual.containers import Container, Horizontal, Vertical
from textual.screen import Screen
from textual.widgets import Footer, Input, Label, Static

from ..widgets import (ActivityLog, AnimationDetail, AnimationTree, LayerTable,
                       MotionCanvas, MotionControls, MotionMetrics, PlanTable,
                       PreviewCanvas, PreviewControls, TimelineTable, WorkbenchStatusBar)


class MainScreen(Screen):
    def compose(self) -> ComposeResult:
        yield WorkbenchStatusBar(id="workbench-status")
        yield Input(placeholder="Search profile / group / action / direction", id="search", classes="hidden")
        with Container(id="plan-mode", classes="mode-pane hidden"):
            yield Label("ANIMATION PLAN · authored rank / computed coverage", classes="pane-title")
            yield PlanTable(id="plan-table")
        with Horizontal(id="workspace-row", classes="mode-pane"):
            with Container(id="navigation-pane"):
                yield AnimationTree()
            with Container(id="detail-pane"):
                yield AnimationDetail("Select an animation", id="animation-detail")
            with Container(id="layers-pane"):
                yield Label("LAYERS", classes="pane-title")
                yield LayerTable(id="layer-table")
                yield Static("Select a layer for ownership details", id="layer-detail")
        with Container(id="preview-mode", classes="mode-pane hidden"):
            yield PreviewCanvas("Select an animation", id="preview-canvas")
            yield PreviewControls("REVIEW FPS", id="preview-controls")
        with Container(id="timeline-mode", classes="mode-pane hidden"):
            yield Label("REVIEW SEQUENCE · disposable .ai artifact", classes="pane-title")
            yield TimelineTable(id="timeline-table")
            yield PreviewCanvas("Add clips to review the sequence", id="timeline-canvas")
            yield PreviewControls("SEQUENCE REVIEW FPS", id="timeline-controls")
        with Container(id="motion-mode", classes="mode-pane hidden"):
            with Horizontal(id="motion-workspace"):
                yield MotionCanvas("Select an animation", id="motion-canvas")
                with Vertical(id="motion-inspector"):
                    yield Label("MOTION LAB", classes="pane-title")
                    yield MotionControls(id="motion-controls")
                    yield MotionMetrics(id="motion-metrics")
            yield PreviewControls("MOTION REVIEW", id="motion-preview-controls")
        with Vertical(id="activity-pane"):
            yield Label("ACTIVITY", classes="pane-title")
            yield ActivityLog(id="activity-log", max_lines=200, markup=True)
        yield Footer()
