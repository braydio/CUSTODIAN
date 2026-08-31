#!/usr/bin/env python3
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT/"custodian/tools/operator"))
from art_agent.mcp_server import OperatorArtMCP

class StubService:
    def inspect(self,session): return {"session":str(session),"ok":True}
    def apply_operation(self,session,operation,operation_key=None): return {"session":str(session),"operation":operation,"operation_key":operation_key}

def main():
    server=OperatorArtMCP(); definitions=server.tool_definitions(); names={x["name"] for x in definitions}
    assert "operator_art_inspect" in names and "operator_art_bake_draft" in names
    assert not any(any(word in name for word in ("publish","git","shell","read_file","write_file")) for name in names)
    for item in definitions:
        schema=item["inputSchema"]
        assert schema["type"]=="object" and schema["additionalProperties"] is False, item["name"]
        if item["name"]!="operator_art_start": assert "session" in schema["properties"], item["name"]
    bake_schema=next(x["inputSchema"] for x in definitions if x["name"]=="operator_art_bake_draft")
    assert set(bake_schema["properties"])=={"session","draft_id","operation_key"}
    assert "mask_id" not in bake_schema["properties"] and "target_layer" not in bake_schema["properties"]
    result=server.dispatch({"jsonrpc":"2.0","id":1,"method":"tools/list"}); assert result["result"]["tools"]
    stub=OperatorArtMCP(StubService())
    read=stub.dispatch({"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"operator_art_inspect","arguments":{"session":"/safe/session.json"}}}); assert read["result"]["structuredContent"]["ok"]
    mutation=stub.dispatch({"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"operator_art_paint_pixels","arguments":{"session":"/safe/session.json","frame":1,"layer":"lower_body","pixels":[],"operation_key":"k"}}}); assert mutation["result"]["structuredContent"]["operation_key"]=="k"

    extra=stub.dispatch({"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"operator_art_inspect","arguments":{"session":"/safe/session.json","not_a_real_field":True}}})
    assert extra["error"]["code"]==-32602 and "unexpected fields" in extra["error"]["message"]
    missing=stub.dispatch({"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"operator_art_bake_draft","arguments":{"session":"/safe/session.json"}}})
    assert missing["error"]["code"]==-32602 and "missing required field" in missing["error"]["message"]
    wrong_type=stub.dispatch({"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"operator_art_paint_pixels","arguments":{"session":"/safe/session.json","frame":"one","layer":"lower_body","pixels":[]}}})
    assert wrong_type["error"]["code"]==-32602

    # main()'s error path must preserve the request id even when dispatch() itself raises
    stdin_lines="\n".join([
        json.dumps({"jsonrpc":"2.0","id":"abc123","method":"tools/call","params":"not-a-dict"}),  # AttributeError inside dispatch(), request id still known
        "not json at all",  # id unknowable before json.loads fails: must fall back to null, not crash the loop
    ])+"\n"
    completed=subprocess.run([sys.executable,"-c","import sys; sys.path.insert(0,%r); from art_agent.mcp_server import main; main()"%str(ROOT/"custodian/tools/operator")],input=stdin_lines,capture_output=True,text=True,timeout=30)
    responses=[json.loads(line) for line in completed.stdout.splitlines() if line.strip()]
    assert len(responses)==2
    assert responses[0]["id"]=="abc123" and "error" in responses[0]
    assert responses[1]["id"] is None and "error" in responses[1]
    print("PASS operator_art_agent_mcp_smoke: explicit schemas, argument validation, error id correlation, no privileged surface")
if __name__=="__main__": main()
