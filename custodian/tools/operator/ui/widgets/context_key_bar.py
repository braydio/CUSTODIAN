from rich.text import Text
from textual.widgets import Static

HINTS = {
    "plan": "ENTER Open   / Search   1-5 Modes   ? Help",
    "workbench": "ENTER Layer   SPACE Show/Hide   E Edit   A/X Frame   ⇧R Resize Canvas   P Publish   V Validate   W Weapon   ? Help",
    "preview": "SPACE Play   ←/→ Frame   S Source   ⇧D Examiner   T Target   ⇧T Seam View   Z Zoom   ? Help",
    "timeline": "SPACE Play   ENTER Clip   I/⇧I In   O/⇧O Out   [/] FPS   ⇧L Loops   Ctrl+A Add   Del Remove   ? Help",
    "motion": (
        "SPACE Play   H Heading   M Tread/World   "
        "G Ground   D Distance   L Loop   ⇧L Span   "
        "ENTER Runtime   ? Help"
    ),
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

    def set_mode(self, mode: str, copy_mode: str = "body", show_superseded: bool = False) -> None:
        hint = HINTS.get(mode, HINTS["workbench"])
        label = copy_mode.upper().replace("_", "+")
        hint += f"   COPY MODE: {label}   Y Copy   ⇧Y Cycle Copy"
        if mode == "workbench":
            hint += f"   ⇧U {'Show' if not show_superseded else 'Hide'} Superseded"
        self.update(Text(hint, no_wrap=True, overflow="crop"))
