from textual.app import ComposeResult
from textual.containers import Horizontal,Vertical
from textual.screen import ModalScreen
from textual.widgets import Button,Label,Select,Static


class WeaponContextDialog(ModalScreen[str | None]):
    def __init__(self,weapons:list[dict[str,str]],current:str="")->None:super().__init__();self.weapons=weapons;self.current=current
    def compose(self)->ComposeResult:
        options=[("No weapon context","")]+[(f"{x['weapon_id']}  ·  {x['animation_profile']}  ·  {x['presentation_mode']}",x['weapon_id']) for x in self.weapons]
        with Vertical(classes="dialog"):
            yield Label("WEAPON CONTEXT",classes="dialog-title");yield Select(options,value=self.current or "",id="weapon-select");yield Static("Changing context never silently reuses an incompatible workspace.",classes="dialog-body")
            with Horizontal(classes="dialog-buttons"):
                yield Button("CANCEL",id="cancel");yield Button("SELECT",id="confirm",variant="primary")
    def on_button_pressed(self,event:Button.Pressed)->None:
        value=self.query_one("#weapon-select",Select).value
        self.dismiss(None if event.button.id=="cancel" else str(value or ""))
