from textual.widgets import Static
from ..state import SessionView


class AnimationDetail(Static):
    def show_session(self, session: SessionView) -> None:
        migration = ""
        if session.migration:
            item = session.migration
            migration = (
                f"\n\nPENDING {item.operation.upper()} @ {item.position}\n"
                f"{item.old_frames}f → {item.new_frames}f\n"
                f"Affected: {', '.join(item.affected)}\nAudit: {item.audit}"
            )
        weapon = session.context.get("weapon_id") or "none"
        self.update(
            f"[b]SELECTED ANIMATION[/b]\n\n{session.selection.identity}\n\n"
            f"Workbench:   {session.workbench_state}\n"
            f"Source:      {session.source_frames}f\n"
            f"Workspace:   {session.workspace_frames}f\n"
            f"Document:    {session.document_frames}f\n"
            f"Migration:   {session.contract_state}\n"
            f"Dependencies:{session.dependency_status:>7}\n\n"
            f"Weapon context: {weapon}\n\n"
            f"Workspace: {session.workspace_path}\n"
            f"Aseprite:  {session.aseprite_path}{migration}"
        )
