from textual.widgets import Static


class WorkbenchStatusBar(Static):
    def set_status(self, branch: str, dirty: bool, aseprite: str, v2: str = "✓") -> None:
        repo = "● dirty" if dirty else "○ clean"
        available = "✓" if aseprite != "unavailable" else "unavailable"
        self.update(f"[b]OPERATOR WORKBENCH[/b]    {branch}  {repo}    Aseprite {available}    V2 {v2}    / search")
