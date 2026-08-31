from __future__ import annotations

from pathlib import Path


def assemble(manifest: dict, *, source_root: Path) -> list[dict]:
    references=[]
    for binding in manifest.get("layers", []):
        source=Path(binding.get("source_contract",{}).get("path",binding.get("source_path","")))
        if source and source.exists() and source.resolve().is_relative_to(source_root.resolve()):
            references.append({"identity":binding.get("semantic_identity",{}),"path":str(source.resolve()),"role":"target_layer","authority":"canonical_source","reason":"Workbench semantic binding"})
    return references
