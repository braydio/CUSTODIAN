from textual.widgets import DataTable


class PlanTable(DataTable):
    def on_mount(self) -> None:
        self.add_columns("#", "PRI", "STATE", "COVERAGE", "PROFILE", "ANIMATION")
        self.cursor_type = "row"

    def set_items(self, items: list[dict]) -> None:
        self.clear()
        for item in items:
            self.add_row(
                str(item["rank"]), item["priority"], item["state"].upper(),
                f"{item['coverage']} / {item['coverage_total']}", item["profile"],
                f"{item['group']} / {item['action']}", key=item["id"],
            )
