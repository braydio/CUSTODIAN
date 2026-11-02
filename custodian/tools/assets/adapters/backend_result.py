"""Common result contract returned by Asset V2 backend adapters."""

from dataclasses import dataclass
from pathlib import Path

from asset_plan import AssetOperation


@dataclass(frozen=True)
class BackendResult:
    ok: bool
    operation: AssetOperation
    outputs: list[Path]
    errors: list[str]
