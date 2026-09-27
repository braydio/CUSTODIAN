"""Renders asset_status / asset_plan / asset_doctor for the selected family.

This widget never re-derives pipeline truth; ``AssetWorkbenchService`` already
calls ``generate_plan`` and ``run_doctor`` directly, so this is a pure render
of what those authorities returned.
"""
from textual.widgets import Static

from ..state import PipelineReport


class PipelinePanel(Static):
    def show(self, report: PipelineReport) -> None:
        heading = f"{report.family_id} · PIPELINE"
        lines = [heading, "─" * len(heading), ""]
        lines.append("PLAN")
        lines.append(f"  {report.plan_source_count} source file(s) → {report.plan_output_count} runtime asset(s)")
        lines.append(f"  can_apply: {'yes' if report.plan_can_apply else 'no'}")
        for operation, count in sorted(report.plan_operation_counts.items()):
            lines.append(f"    {operation.upper():9} {count}")
        if report.plan_errors:
            lines += ["  ERRORS"] + [f"    ✗ {message}" for message in report.plan_errors]
        if report.plan_warnings:
            lines += ["  WARNINGS"] + [f"    ⚠ {message}" for message in report.plan_warnings]
        lines += ["", "DOCTOR"]
        lines.append(f"  this family: {'✓ no issues' if not report.doctor_family_issues else f'{len(report.doctor_family_issues)} issue(s)'}")
        for issue in report.doctor_family_issues:
            marker = "✗" if issue.severity == "error" else "⚠"
            lines.append(f"    {marker} {issue.message}")
        if report.doctor_global_issues:
            errors = sum(1 for issue in report.doctor_global_issues if issue.severity == "error")
            lines.append(f"  repo-wide (other families): {len(report.doctor_global_issues)} issue(s), {errors} error(s) — run `asset doctor` for the full sweep")
        self.update("\n".join(lines))
