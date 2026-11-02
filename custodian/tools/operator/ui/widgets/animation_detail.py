from textual.widgets import Static
from ..state import SessionView


class AnimationDetail(Static):
    def show_session(self, session: SessionView) -> None:
        migration = ""
        if session.migration:
            item = session.migration
            if hasattr(item, "old_document_size"):
                migration = (f"\n\nCANVAS MIGRATION PENDING\n"
                             f"{item.old_document_size[0]}×{item.old_document_size[1]} → {item.new_document_size[0]}×{item.new_document_size[1]}\n"
                             f"Affected: {', '.join(item.affected)}\nAudit: {item.audit}")
            else:
                migration = (f"\n\nPENDING {item.operation.upper()} @ {item.position}\n"
                             f"{item.old_frames}f → {item.new_frames}f\n"
                             f"Affected: {', '.join(item.affected)}\nAudit: {item.audit}")
        weapon = session.context.get("weapon_id") or "none"
        completeness = session.completeness
        if session.completeness_detail:
            completeness += f" — {session.completeness_detail}"
        if session.selection.art_generation == "operator_2_5d_128":
            source = f"{session.coverage_status} · {session.source_frames}f" if session.source_frames else session.coverage_status
            runtime = "not published; production selectors unchanged"
        else:
            source = "not published" if session.workbench_state.startswith("NEW /") else f"{session.source_frames}f"
            runtime = "DORMANT/unwired until a consumer is added" if session.workbench_state.startswith("NEW /") else "canonical/runtime"
        self.update(
            f"[b]SELECTED ANIMATION[/b]\n\n{session.selection.authoring_identity}\n\n"
            f"Coverage:    {session.coverage_status}\n"
            f"Workflow:    {session.workflow_status}{' · STALE' if session.stale_reference else ''}\n"
            f"Presentation: {completeness}\n"
            f"Workbench:   {session.workbench_state}\n"
            f"Source:      {source}\n"
            f"Runtime:     {runtime}\n"
            f"Workspace:   {session.workspace_frames}f\n"
            f"Document:    {session.document_frames}f\n"
            f"Migration:   {session.contract_state}\n"
            f"Dependencies:{session.dependency_status:>7}\n\n"
            f"Weapon context: {weapon}\n\n"
            f"Workspace: {session.workspace_display or session.workspace_path}\n"
            f"Aseprite:  {session.aseprite_path}{migration}"
        )
