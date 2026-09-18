from textual.widgets import Static


class WorkbenchStatusBar(Static):
    def set_status(
        self, branch: str, dirty: bool, aseprite: str,
        live: str = "waiting", v2: str = "✓",
    ) -> None:
        repo = "● dirty" if dirty else "○ clean"
        available = "✓" if aseprite != "unavailable" else "unavailable"
        live_label = {
            "starting": "… STARTING",
            "waiting": "○ WAITING",
            "connected": "● CONNECTED",
            "unavailable": "× UNAVAILABLE",
            "stopped": "○ STOPPED",
        }.get(live, "? UNKNOWN")
        self.update(
            f"[b]OPERATOR WORKBENCH[/b]    {branch}  {repo}    "
            f"Aseprite {available}    LIVE {live_label}    V2 {v2}    / search"
        )
