from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Checkbox, Label, Static
from ..state import PublishView


class PublishDialog(ModalScreen[tuple[bool, bool] | None]):
    def __init__(self, preview: PublishView, aseprite_open: bool = False) -> None: super().__init__(); self.preview=preview; self.aseprite_open=aseprite_open
    def compose(self)->ComposeResult:
        p=self.preview; warning="\n[yellow]Aseprite is currently open. Publish uses the last SAVED workbench state.[/yellow]\n" if self.aseprite_open else ""
        retired="\n".join(p.retired_paths) or "none"; direct_operations=p.direct_operations or tuple("REPLACE" for _ in p.new_paths); new="\n".join(f"{operation}  {path}" for operation,path in zip(direct_operations,p.new_paths)) or "none"
        mirror="\n".join(f"{operation}  {path}" for operation,path in zip(p.mirror_operations,p.mirror_paths)) or "no mirrored counterpart"
        replacement="\n[yellow]Existing %s source will be replaced by a horizontal promotion of %s.[/yellow]"%(p.counterpart_direction.upper(),p.selection.direction.upper()) if "REPLACE" in p.mirror_operations else ""
        with Vertical(classes="dialog publish-dialog"):
            yield Label("PUBLISH",classes="dialog-title")
            yield Static(f"{p.selection.identity}\n\nCanonical changes      {p.old_frames}f → {p.new_frames}f\n\nDIRECT\nRetired contracts\n{retired}\nNew contracts\n{new}\n\nMIRROR PROMOTION\n{mirror}{replacement}\n\nDependency audit       {p.audit}\nCompatibility preflight PASS{warning}",classes="dialog-body",id="publish-preview")
            label=f"Also publish mirrored counterpart ({p.selection.direction.upper()} → {p.counterpart_direction.upper()})" if p.counterpart_direction else "No mirrored counterpart"
            yield Checkbox(label,id="mirror-counterpart",disabled=p.counterpart_direction is None)
            yield Checkbox("Full changed-file validation",id="full-validation")
            with Horizontal(classes="dialog-buttons"):
                yield Button("CANCEL",id="cancel");yield Button("PUBLISH",id="confirm",variant="success",disabled=p.audit!="GREEN")
    def on_button_pressed(self,event:Button.Pressed)->None:self.dismiss(None if event.button.id=="cancel" else (self.query_one("#full-validation",Checkbox).value,self.query_one("#mirror-counterpart",Checkbox).value))
