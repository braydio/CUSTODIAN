#!/usr/bin/env python3
"""Minimal local stdio MCP adapter; all authority stays in ArtAgentService."""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, Callable

from .service import ArtAgentService

_STRING = {"type": "string"}
_OPTIONAL_STRING = {"type": ["string", "null"]}
_INTEGER = {"type": "integer"}
_NUMBER = {"type": "number"}
_BOOLEAN = {"type": "boolean"}
_OBJECT = {"type": "object"}
_POINT = {"type": "array", "items": {"type": "integer"}, "minItems": 2, "maxItems": 2}
_POLYGON = {"type": "array", "items": _POINT, "minItems": 3}
_RECT = {"type": "array", "items": {"type": "integer"}, "minItems": 4, "maxItems": 4}
_RGBA = {"type": "array", "items": {"type": "integer", "minimum": 0, "maximum": 255}, "minItems": 4, "maxItems": 4}
_PIXELS = {"type": "array", "items": _OBJECT}
_LANDMARKS = {"type": "array", "items": _OBJECT}
_REQUIRED_LANDMARKS = {"anyOf": [{"type": "array", "items": {"type": "string"}}, _OBJECT]}
_POINTS = {"type": "array", "items": _POINT}

# name -> {property: (schema, required)}. Every tool mutates only the disposable
# `.ai` Workbench session named by `session`; none can write canonical source,
# generated runtime output, or invoke publish/git/shell. Coordinates are document
# pixel coordinates (origin top-left), integer-grid only.
_TOOL_SPECS: dict[str, dict[str, tuple[dict[str, Any], bool]]] = {
    "operator_art_start": {
        "profile": (_STRING, True), "action": (_STRING, True), "direction": (_STRING, True),
        "group": (_STRING, False), "weapon": (_STRING, False), "linked_profile": (_STRING, False),
    },
    "operator_art_status": {"session": (_STRING, True)},
    "operator_art_inspect": {"session": (_STRING, True)},
    "operator_art_render": {"session": (_STRING, True), "mode": (_STRING, False), "layer": (_STRING, False), "include_drafts": (_BOOLEAN, False)},
    "operator_art_get_landmarks": {"session": (_STRING, True)},
    "operator_art_set_landmarks": {"session": (_STRING, True), "landmarks": (_LANDMARKS, True)},
    "operator_art_validate_landmarks": {"session": (_STRING, True)},
    "operator_art_define_mask": {
        "session": (_STRING, True), "frame": (_INTEGER, True), "layer": (_STRING, True), "part": (_STRING, True),
        "polygon": (_POLYGON, False), "rect": (_RECT, False), "provenance": (_STRING, False), "confidence": (_NUMBER, False),
    },
    "operator_art_get_masks": {"session": (_STRING, True)},
    "operator_art_validate_masks": {"session": (_STRING, True)},
    "operator_art_mask_union": {"session": (_STRING, True), "mask_id_a": (_STRING, True), "mask_id_b": (_STRING, True), "part": (_STRING, True)},
    "operator_art_mask_subtract": {"session": (_STRING, True), "mask_id_a": (_STRING, True), "mask_id_b": (_STRING, True), "part": (_STRING, True)},
    "operator_art_mask_intersect": {"session": (_STRING, True), "mask_id_a": (_STRING, True), "mask_id_b": (_STRING, True), "part": (_STRING, True)},
    "operator_art_mask_dilate_1px": {"session": (_STRING, True), "mask_id": (_STRING, True), "part": (_STRING, False)},
    "operator_art_mask_erode_1px": {"session": (_STRING, True), "mask_id": (_STRING, True), "part": (_STRING, False)},
    "operator_art_mask_from_alpha_region": {
        "session": (_STRING, True), "frame": (_INTEGER, True), "layer": (_STRING, True), "part": (_STRING, True),
        "seed": (_POINT, False), "provenance": (_STRING, False),
    },
    "operator_art_preview_mask": {"session": (_STRING, True), "mask_id": (_STRING, True)},
    "operator_art_plan": {"session": (_STRING, True), "recipe": (_STRING, True)},
    "operator_art_get_metrics": {"session": (_STRING, True)},
    "operator_art_run_qa": {"session": (_STRING, True), "required_landmarks": (_REQUIRED_LANDMARKS, False)},
    "operator_art_draft_shift_part": {
        "session": (_STRING, True), "mask_id": (_STRING, True), "dx": (_INTEGER, False), "dy": (_INTEGER, False),
        "destination_frame": (_INTEGER, False), "operation_key": (_OPTIONAL_STRING, False),
    },
    "operator_art_draft_copy_part": {
        "session": (_STRING, True), "mask_id": (_STRING, True), "dx": (_INTEGER, False), "dy": (_INTEGER, False),
        "destination_frame": (_INTEGER, False), "operation_key": (_OPTIONAL_STRING, False),
    },
    "operator_art_draft_replace_part": {
        "session": (_STRING, True), "mask_id": (_STRING, True), "destination_mask_id": (_STRING, True),
        "dx": (_INTEGER, False), "dy": (_INTEGER, False), "operation_key": (_OPTIONAL_STRING, False),
    },
    "operator_art_draft_mirror_part": {
        "session": (_STRING, True), "mask_id": (_STRING, True), "axis_x": (_INTEGER, True),
        "dy": (_INTEGER, False), "operation_key": (_OPTIONAL_STRING, False),
    },
    "operator_art_get_drafts": {"session": (_STRING, True)},
    "operator_art_validate_drafts": {"session": (_STRING, True)},
    "operator_art_discard_draft": {"session": (_STRING, True), "draft_id": (_STRING, True), "operation_key": (_OPTIONAL_STRING, False)},
    "operator_art_bake_draft": {"session": (_STRING, True), "draft_id": (_STRING, True), "operation_key": (_OPTIONAL_STRING, False)},
    "operator_art_resolve_gap_repair": {"session": (_STRING, True), "draft_id": (_STRING, True), "note": (_STRING, False)},
    "operator_art_paint_pixels": {
        "session": (_STRING, True), "frame": (_INTEGER, True), "layer": (_STRING, True),
        "pixels": (_PIXELS, True), "operation_key": (_OPTIONAL_STRING, False),
    },
    "operator_art_erase_pixels": {
        "session": (_STRING, True), "frame": (_INTEGER, True), "layer": (_STRING, True),
        "pixels": (_PIXELS, True), "operation_key": (_OPTIONAL_STRING, False),
    },
    "operator_art_stroke": {
        "session": (_STRING, True), "frame": (_INTEGER, True), "layer": (_STRING, True), "rgba": (_RGBA, True),
        "brush": (_OBJECT, True), "points": (_POINTS, True), "operation_key": (_OPTIONAL_STRING, False),
    },
    "operator_art_record_critique": {"session": (_STRING, True), "critique": (_OBJECT, True)},
    "operator_art_review_packet": {"session": (_STRING, True), "task": (_STRING, False)},
    "operator_art_undo": {"session": (_STRING, True)},
}

_DESCRIPTIONS: dict[str, str] = {
    "operator_art_start": "Start a new disposable Art Agent session over a Workbench V2 document. Read-only with respect to canonical source.",
    "operator_art_bake_draft": "Bake a previously created semantic draft into its owning Workbench binding. Mutates the disposable session only. Target layer/frame/mask are resolved from the draft's own immutable record, not from caller input.",
    "operator_art_discard_draft": "Delete a semantic draft layer without baking it. Mutates the disposable session only.",
    "operator_art_paint_pixels": "Set exact integer-grid pixel colors on an editable Workbench binding. Mutates the disposable session only. Coordinates are document pixel coordinates.",
    "operator_art_erase_pixels": "Clear exact integer-grid pixels to transparent on an editable Workbench binding. Mutates the disposable session only.",
    "operator_art_stroke": "Draw a deterministic square-brush line/point stroke. Mutates the disposable session only.",
    "operator_art_undo": "Restore the Workbench to the state before the last applied mutation, byte-exact. Mutates the disposable session only.",
}


def _tool_description(name: str) -> str:
    return _DESCRIPTIONS.get(name, name.replace("operator_art_", "").replace("_", " "))


def _schema_for(name: str) -> dict[str, Any]:
    spec = _TOOL_SPECS.get(name)
    if spec is None:
        return {"type": "object", "properties": {"session": _STRING}, "required": ["session"], "additionalProperties": False}
    return {
        "type": "object",
        "properties": {key: value for key, (value, _required) in spec.items()},
        "required": [key for key, (_value, required) in spec.items() if required],
        "additionalProperties": False,
    }


def _type_matches(value: Any, type_name: str) -> bool:
    if type_name == "object": return isinstance(value, dict)
    if type_name == "array": return isinstance(value, list)
    if type_name == "string": return isinstance(value, str)
    if type_name == "integer": return isinstance(value, int) and not isinstance(value, bool)
    if type_name == "number": return isinstance(value, (int, float)) and not isinstance(value, bool)
    if type_name == "boolean": return isinstance(value, bool)
    if type_name == "null": return value is None
    return True


def _validate_value(schema: dict[str, Any], value: Any, label: str) -> None:
    if "anyOf" in schema:
        for option in schema["anyOf"]:
            try:
                _validate_value(option, value, label)
                return
            except ValueError:
                continue
        raise ValueError(f"{label} does not match any allowed schema")
    schema_type = schema.get("type")
    types = schema_type if isinstance(schema_type, list) else [schema_type] if schema_type else []
    if types and not any(_type_matches(value, item) for item in types):
        raise ValueError(f"{label} has wrong type: expected {types}")
    if isinstance(value, list) and ("array" in types):
        min_items, max_items = schema.get("minItems"), schema.get("maxItems")
        if min_items is not None and len(value) < min_items:
            raise ValueError(f"{label} has fewer than {min_items} items")
        if max_items is not None and len(value) > max_items:
            raise ValueError(f"{label} has more than {max_items} items")
        item_schema = schema.get("items")
        if item_schema:
            for index, item in enumerate(value):
                _validate_value(item_schema, item, f"{label}[{index}]")
    if isinstance(value, dict) and ("object" in types):
        properties = schema.get("properties", {})
        for key in schema.get("required", []):
            if key not in value:
                raise ValueError(f"{label} missing required field: {key}")
        if schema.get("additionalProperties") is False:
            extra = sorted(set(value) - set(properties))
            if extra:
                raise ValueError(f"{label} has unexpected fields: {extra}")
        for key, item in value.items():
            if key in properties:
                _validate_value(properties[key], item, f"{label}.{key}")


def validate_arguments(name: str, arguments: dict[str, Any]) -> None:
    _validate_value(_schema_for(name), arguments, name)


class OperatorArtMCP:
    def __init__(self, service: ArtAgentService | None = None): self.service=service or ArtAgentService()

    def tools(self) -> dict[str, Callable[..., Any]]:
        s=self.service
        return {
            "operator_art_start": lambda **x: {"session":str(s.start_session(**x))},
            "operator_art_status": lambda session,**_:s.status(Path(session)),
            "operator_art_inspect": lambda session,**_:s.inspect(Path(session)),
            "operator_art_render": lambda session,**x:s.render(Path(session),**x),
            "operator_art_get_landmarks": lambda session,**_:s.get_landmarks(Path(session)),
            "operator_art_set_landmarks": lambda session,landmarks,**_:s.set_landmarks(Path(session),landmarks),
            "operator_art_validate_landmarks": lambda session,**_:s.validate_landmarks(Path(session)),
            "operator_art_define_mask": lambda session,**x:s.define_mask(Path(session),**x),
            "operator_art_get_masks": lambda session,**_:s.get_masks(Path(session)),
            "operator_art_validate_masks": lambda session,**_:s.validate_masks(Path(session)),
            "operator_art_mask_union": lambda session,mask_id_a,mask_id_b,part,**_:s.mask_union(Path(session),mask_id_a,mask_id_b,part=part),
            "operator_art_mask_subtract": lambda session,mask_id_a,mask_id_b,part,**_:s.mask_subtract(Path(session),mask_id_a,mask_id_b,part=part),
            "operator_art_mask_intersect": lambda session,mask_id_a,mask_id_b,part,**_:s.mask_intersect(Path(session),mask_id_a,mask_id_b,part=part),
            "operator_art_mask_dilate_1px": lambda session,mask_id,part=None,**_:s.mask_dilate_1px(Path(session),mask_id,part=part),
            "operator_art_mask_erode_1px": lambda session,mask_id,part=None,**_:s.mask_erode_1px(Path(session),mask_id,part=part),
            "operator_art_mask_from_alpha_region": lambda session,**x:s.mask_from_alpha_region(Path(session),**x),
            "operator_art_preview_mask": lambda session,mask_id,**_:s.preview_mask(Path(session),mask_id),
            "operator_art_plan": lambda session,recipe,**_:s.plan(Path(session),recipe),
            "operator_art_get_metrics": lambda session,**_:s.get_metrics(Path(session)),
            "operator_art_run_qa": lambda session,**x:s.run_qa(Path(session),**x),
            "operator_art_draft_shift_part": lambda session,mask_id,operation_key=None,**x:s.create_draft(Path(session),kind="shift",mask_id=mask_id,operation_key=operation_key,**x),
            "operator_art_draft_copy_part": lambda session,mask_id,operation_key=None,**x:s.create_draft(Path(session),kind="copy",mask_id=mask_id,operation_key=operation_key,**x),
            "operator_art_draft_replace_part": lambda session,mask_id,operation_key=None,**x:s.create_draft(Path(session),kind="replace",mask_id=mask_id,operation_key=operation_key,**x),
            "operator_art_draft_mirror_part": lambda session,mask_id,operation_key=None,**x:s.create_draft(Path(session),kind="mirror",mask_id=mask_id,operation_key=operation_key,**x),
            "operator_art_get_drafts": lambda session,**_:s.get_drafts(Path(session)),
            "operator_art_validate_drafts": lambda session,**_:s.validate_drafts(Path(session)),
            "operator_art_discard_draft": lambda session,draft_id,operation_key=None,**_:s.discard_draft(Path(session),draft_id,operation_key=operation_key),
            "operator_art_bake_draft": lambda session,operation_key=None,**x:s.bake_draft(Path(session),operation_key=operation_key,**x),
            "operator_art_resolve_gap_repair": lambda session,draft_id,note="",**_:s.resolve_gap_repair(Path(session),draft_id,note),
            "operator_art_paint_pixels": lambda session,operation_key=None,**x:s.apply_operation(Path(session),{"type":"paint_pixels",**x},operation_key=operation_key),
            "operator_art_erase_pixels": lambda session,operation_key=None,**x:s.apply_operation(Path(session),{"type":"erase_pixels",**x},operation_key=operation_key),
            "operator_art_stroke": lambda session,operation_key=None,**x:s.apply_operation(Path(session),{"type":"stroke",**x},operation_key=operation_key),
            "operator_art_record_critique": lambda session,critique,**_:s.record_critique(Path(session),critique),
            "operator_art_review_packet": lambda session,**x:s.build_review_packet(Path(session),**x),
            "operator_art_undo": lambda session,**_:s.undo_last(Path(session)),
        }

    def tool_definitions(self) -> list[dict]:
        return [{"name":name,"description":_tool_description(name),"inputSchema":_schema_for(name)} for name in self.tools()]

    def dispatch(self, request: dict) -> dict:
        method=request.get("method"); request_id=request.get("id")
        if method=="initialize": result={"protocolVersion":"2025-03-26","capabilities":{"tools":{}},"serverInfo":{"name":"operator-art","version":"2.0"}}
        elif method=="tools/list": result={"tools":self.tool_definitions()}
        elif method=="tools/call":
            params=request.get("params",{}); name=params.get("name"); tool=self.tools().get(name)
            if tool is None: return {"jsonrpc":"2.0","id":request_id,"error":{"code":-32601,"message":"unknown tool"}}
            arguments=params.get("arguments",{})
            try:
                validate_arguments(name,arguments)
            except ValueError as error:
                return {"jsonrpc":"2.0","id":request_id,"error":{"code":-32602,"message":str(error)}}
            value=tool(**arguments); result={"content":[{"type":"text","text":json.dumps(value)}],"structuredContent":value}
        else: return {"jsonrpc":"2.0","id":request_id,"error":{"code":-32601,"message":"unknown method"}}
        return {"jsonrpc":"2.0","id":request_id,"result":result}


def main() -> None:
    server=OperatorArtMCP()
    for line in sys.stdin:
        if not line.strip(): continue
        request: Any = None
        try:
            request=json.loads(line)
            response=server.dispatch(request)
        except Exception as error:
            response={"jsonrpc":"2.0","id":request.get("id") if isinstance(request,dict) else None,"error":{"code":-32000,"message":str(error)}}
        print(json.dumps(response),flush=True)


if __name__=="__main__": main()
