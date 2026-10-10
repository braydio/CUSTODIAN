from textual.widgets import DataTable


class ReviewFamilyTable(DataTable):
    """All required target directions and their current evidence state."""

    def on_mount(self) -> None:
        self.add_columns("DIR", "COVERAGE", "WORKFLOW", "QA", "HUMAN", "SANDBOX", "RUNTIME VERIFIED")
        self.cursor_type = "row"

    def set_family(self, family: dict) -> None:
        self.clear()
        for cell in family.get("cells", ()):
            self.add_row(cell["direction"], cell["coverage"], cell["workflow"], cell["qa"],
                         cell["human_review"], cell["sandbox"],
                         "YES" if cell["runtime_verified"] else "NO")
