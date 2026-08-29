"""Extensible Workbench feature-provider protocol."""
from typing import Any, Protocol


class WorkbenchFeature(Protocol):
    id: str
    title: str
    key_binding: str

    def build_navigation(self, query: str = "") -> Any: ...
    def build_detail(self, selection: Any) -> Any: ...
    def actions(self) -> tuple[Any, ...]: ...
    def refresh(self) -> Any: ...


class PreviewAdapter(Protocol):
    """Future image-preview seam; V1 intentionally registers no adapters."""
    id: str

    def available(self) -> bool: ...
    def preview(self, session: Any) -> Any: ...
