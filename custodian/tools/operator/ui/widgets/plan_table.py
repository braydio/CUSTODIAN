from textual.widgets import DataTable


class PlanTable(DataTable):
    def on_mount(self) -> None:
        self.add_columns("#", "PRI", "PLAN", "SRC ACCEPTED", "LOCAL", "WORKSPACE", "REVIEW QA", "VERIFIED", "DIRS", "NEXT", "TARGET")
        self.cursor_type = "row"
        self._items_by_id = {}

    def set_items(self, items: list[dict]) -> None:
        self.clear()
        self._items_by_id = {}
        for item in items:
            self._items_by_id[item["id"]] = item
            counts = item["primary_counts"]
            workflow = ", ".join(f"{key} {value}" for key, value in sorted(item["workflow_counts"].items()) if key != "NONE") or "NONE"
            qa = ", ".join(f"{key} {value}" for key, value in sorted(item["qa_counts"].items()) if key != "UNREVIEWED") or "UNREVIEWED"
            self.add_row(
                str(item["rank"]), item["priority"], str(item["state"]).upper(),
                f"{item['source_directions']} / {item['target_total']}",
                f"{counts['LOCAL CANONICAL']} / {item['target_total']}",
                workflow, qa,
                f"{item['verified']} / {item['target_total']}",
                f"{len(item['directions'])} dirs", item["next_direction"] or "BLOCKED",
                f"{item['profile']} / {item['group']} / {item['action']}", key=item["id"],
            )

    def item_for_key(self, key: str) -> dict | None:
        return self._items_by_id.get(key)
