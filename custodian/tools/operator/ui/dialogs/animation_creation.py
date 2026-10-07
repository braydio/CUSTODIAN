from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Checkbox, Input, Label, RadioButton, RadioSet, Static


class AnimationCreationDialog(ModalScreen[dict | None]):
    def __init__(self, frame_size=(96, 96)) -> None:
        super().__init__()
        self.frame_size = frame_size

    def compose(self) -> ComposeResult:
        with Vertical(classes="dialog"):
            yield Label("NEW OPERATOR ANIMATION", classes="dialog-title")
            yield Static("Choose the semantic identity and body presentation template.", classes="dialog-body")
            for field, value, placeholder in (
                ("profile", "unarmed", "profile"), ("group", "locomotion", "action group"),
                ("action", "", "semantic action name"), ("direction", "e", "authored direction"),
                ("frames", "6", "frame count"), ("width", str(self.frame_size[0]), "frame width"), ("height", str(self.frame_size[1]), "frame height"),
                ("fps", "8", "FPS"),
            ):
                yield Input(value, placeholder=placeholder, id=f"create-{field}")
            with RadioSet(id="create-template"):
                yield RadioButton("Full body", value=True)
                yield RadioButton("Synchronized lower + upper body")
            yield Checkbox("Loop", value=True, id="create-loop")
            with Horizontal(classes="dialog-buttons"):
                yield Button("CANCEL", id="cancel")
                yield Button("REVIEW PLAN", id="review", variant="primary")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "cancel":
            self.dismiss(None)
            return
        try:
            values = {name: self.query_one(f"#create-{name}", Input).value.strip()
                      for name in ("profile", "group", "action", "direction", "frames", "width", "height", "fps")}
            template = "full_body" if self.query_one("#create-template", RadioSet).pressed_index == 0 else "modular_body"
            self.dismiss({"profile": values["profile"], "group": values["group"],
                "action": values["action"], "direction": values["direction"],
                "frames": int(values["frames"]), "frame_size": (int(values["width"]), int(values["height"])),
                "fps": float(values["fps"]), "loop": self.query_one("#create-loop", Checkbox).value,
                "template": template})
        except (TypeError, ValueError):
            self.dismiss({"error": "Enter numeric frame count, canvas size, and FPS values."})


class AnimationCreationPlanDialog(ModalScreen[bool]):
    def __init__(self, plan: dict) -> None:
        super().__init__()
        self.plan = plan

    def compose(self) -> ComposeResult:
        p = self.plan
        lines = [
            "IDENTITY", f"{p['identity']['profile']} / {p['identity']['group']} / {p['identity']['action']} / {p['identity']['direction']}",
            "", "PUBLISH LAYERS",
            *[f"{row['layer']}: CREATE\n  source: {row['source']}\n  runtime: {row['runtime']}" for row in p["layers"]],
            "", "REFERENCE GUIDES",
            *([f"{row['layer']} from {row['direction']}: {row['source']}" for row in p.get("references", ())] or ["none available for this frame contract"]),
            "", f"Contract: {p['frames']} frames · {p['frame_size'][0]}×{p['frame_size'][1]} · {p['fps']:g} FPS · loop={p['loop']}",
            f"Template: {p['template']} · mirror: {p['mirror']}",
            f"Collision: {p['collision']} · implementation plan present: {p['implementation_plan_present']}",
            f"Reachability: {p['reachability']} · runtime catalog present: {p['runtime_catalog_present']}",
            "", "No canonical files are created until Publish to Main.",
        ]
        with Vertical(classes="dialog"):
            yield Label("REVIEW NEW ANIMATION PLAN", classes="dialog-title")
            yield Static("\n".join(lines), classes="dialog-body")
            with Horizontal(classes="dialog-buttons"):
                yield Button("BACK", id="cancel")
                yield Button("CREATE WORKBENCH", id="confirm", variant="success", disabled=bool(p.get("collisions")))

    def on_button_pressed(self, event: Button.Pressed) -> None:
        self.dismiss(event.button.id == "confirm")
