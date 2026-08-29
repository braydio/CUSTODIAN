from textual.widgets import RichLog
from ..state import ActivityEvent


class ActivityLog(RichLog):
    def add_event(self, event: ActivityEvent) -> None:
        prefix = {"ERROR": "[red]✗[/red]", "WARN": "[yellow]![/yellow]", "OK": "[green]✓[/green]"}.get(event.severity, "·")
        self.write(f"{event.timestamp} {prefix} {event.message}")
