from rich.text import Text
from textual.widgets import Static

HINTS = {
    "plan": "ENTER Open   / Search   1-5 Modes   ? Help",
    "workbench": "E Edit   A/X Frame   P Publish   V Validate   W Weapon   ? Help",
    "preview": "SPACE Play   ←/→ Frame   [/] FPS   L Loop   S Source   Z Zoom   ? Help",
    "timeline": "SPACE Play   Ctrl+A Add   Del Remove   Ctrl+↑/↓ Move   Ctrl+S/O Save/Load   ? Help",
    "motion": "SPACE Play   M Tread/World   D Distance   C Curve   G Ground   ⇧←/→ ±16   ENTER Runtime   ? Help",
}


class ContextKeyBar(Static):
    """One-line, mode-specific shortcut bar — replaces the global Textual Footer.

    Textual's stock Footer prints every binding in BINDINGS regardless of the
    active mode, which is unreadable once Workbench/Preview/Timeline/Motion
    shortcuts all pile up together. This shows only the bindings relevant to
    whatever mode is active right now.
    """

    def on_mount(self) -> None:
        self.set_mode("workbench")

    def set_mode(self, mode: str) -> None:
        hint = HINTS.get(mode, HINTS["workbench"])
        self.update(Text(hint, no_wrap=True, overflow="crop"))
