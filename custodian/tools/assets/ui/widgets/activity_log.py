from rich.markup import escape
from textual.widgets import RichLog

SEVERITY_PREFIX = {"ERROR": "[red]✗[/red]", "WARN": "[yellow]![/yellow]", "OK": "[green]✓[/green]"}


class ActivityLog(RichLog):
    def add_message(self, message: str, severity: str = "INFO") -> None:
        # `message` can carry arbitrary filesystem paths/exception text, so it
        # must be escaped even though this widget renders Rich markup overall.
        self.write(f"{SEVERITY_PREFIX.get(severity, '·')} {escape(message)}")
