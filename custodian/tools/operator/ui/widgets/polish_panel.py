from textual.containers import Horizontal, Vertical
from textual.widgets import Button, Checkbox, DataTable, Label, Static

from .review_family_table import ReviewFamilyTable


class PolishPanel(Vertical):
    """Small publication-free controls over one exact saved 2.5D Workbench."""

    def compose(self):
        yield Label("POLISH · exact 2.5D Workbench · no publication", classes="pane-title")
        with Horizontal(classes="polish-actions"):
            yield Button("Attach + Analyze", id="polish-attach", variant="primary")
            yield Button("Refresh Analysis", id="polish-refresh")
            yield Button("Review + Runtime Sandbox", id="polish-review")
            yield Button("Open Aseprite", id="polish-open")
            yield Button("Registration Guide", id="polish-guide")
        yield Checkbox("Explicit human disposition for major findings", id="polish-human-approved", value=False)
        with Horizontal(classes="polish-actions"):
            yield Button("Preview Center X", id="polish-center")
            yield Checkbox("Explicit planted/stationary choice for this proposal", id="polish-planted-opt-in", value=False)
            yield Button("Propose Planted Registration", id="polish-planted")
            yield Button("Apply Selected", id="polish-apply", variant="warning")
            yield Button("Undo Last", id="polish-undo")
        yield DataTable(id="polish-proposals")
        yield Label("FAMILY REVIEW · derived from target projection + current receipts", classes="pane-title")
        yield ReviewFamilyTable(id="polish-family-review")
        yield Static("Select an exact operator_2_5d_128 Workbench. Review receipts are evidence; they never publish assets.", id="polish-status")
