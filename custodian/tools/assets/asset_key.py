"""Shared semantic asset identity — the general equivalent of OperatorAssetKey."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class AssetKey:
    owner: str
    kind: str
    layer: str
    action_group: str
    variant: str
    direction: str
    frames: int
    frame_width: int
    frame_height: int

    @property
    def semantic_identity(self) -> tuple[str, str, str, str, str, str]:
        """Six-tuple that uniquely identifies a semantic asset revision.

        frames, frame_width, frame_height are deliberately excluded.
        """
        return (
            self.owner,
            self.kind,
            self.layer,
            self.action_group,
            self.variant,
            self.direction,
        )

    def same_semantic(self, other: AssetKey) -> bool:
        return self.semantic_identity == other.semantic_identity
