#!/usr/bin/env python3
from __future__ import annotations
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT/"custodian/tools/operator"))
from art_agent.mcp_server import OperatorArtMCP

class StubService:
    def inspect(self,session): return {"session":str(session),"ok":True}
    def apply_operation(self,session,operation,operation_key=None): return {"session":str(session),"operation":operation,"operation_key":operation_key}

def main():
    server=OperatorArtMCP(); names={x["name"] for x in server.tool_definitions()}
    assert "operator_art_inspect" in names and "operator_art_bake_draft" in names
    assert not any(any(word in name for word in ("publish","git","shell","read_file","write_file")) for name in names)
    result=server.dispatch({"jsonrpc":"2.0","id":1,"method":"tools/list"}); assert result["result"]["tools"]
    stub=OperatorArtMCP(StubService())
    read=stub.dispatch({"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"operator_art_inspect","arguments":{"session":"/safe/session.json"}}}); assert read["result"]["structuredContent"]["ok"]
    mutation=stub.dispatch({"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"operator_art_paint_pixels","arguments":{"session":"/safe/session.json","frame":1,"layer":"lower_body","pixels":[],"operation_key":"k"}}}); assert mutation["result"]["structuredContent"]["operation_key"]=="k"
    print("PASS operator_art_agent_mcp_smoke: tools enumerate and no privileged surface exists")
if __name__=="__main__": main()
