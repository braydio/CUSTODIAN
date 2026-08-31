#!/usr/bin/env python3
"""Minimal local stdio MCP adapter; all authority stays in ArtAgentService."""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, Callable

from .service import ArtAgentService


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
        return [{"name":name,"description":name.replace("operator_art_","").replace("_"," "),"inputSchema":{"type":"object","additionalProperties":True}} for name in self.tools()]

    def dispatch(self, request: dict) -> dict:
        method=request.get("method"); request_id=request.get("id")
        if method=="initialize": result={"protocolVersion":"2025-03-26","capabilities":{"tools":{}},"serverInfo":{"name":"operator-art","version":"2.0"}}
        elif method=="tools/list": result={"tools":self.tool_definitions()}
        elif method=="tools/call":
            params=request.get("params",{}); name=params.get("name"); tool=self.tools().get(name)
            if tool is None: return {"jsonrpc":"2.0","id":request_id,"error":{"code":-32601,"message":"unknown tool"}}
            value=tool(**params.get("arguments",{})); result={"content":[{"type":"text","text":json.dumps(value)}],"structuredContent":value}
        else: return {"jsonrpc":"2.0","id":request_id,"error":{"code":-32601,"message":"unknown method"}}
        return {"jsonrpc":"2.0","id":request_id,"result":result}


def main() -> None:
    server=OperatorArtMCP()
    for line in sys.stdin:
        if line.strip():
            try: response=server.dispatch(json.loads(line))
            except Exception as error: response={"jsonrpc":"2.0","id":None,"error":{"code":-32000,"message":str(error)}}
            print(json.dumps(response),flush=True)


if __name__=="__main__": main()
