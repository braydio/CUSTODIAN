#!/usr/bin/env python3
from pathlib import Path
import sys,tempfile
ROOT=Path(__file__).resolve().parents[3];sys.path[:0]=[str(ROOT/"custodian/tools/operator")]
from art_agent.service import ArtAgentService

with tempfile.TemporaryDirectory() as tmp:
    service=ArtAgentService(art_root=Path(tmp)/"art",workspace_root=Path(tmp)/"wb",aseprite=Path("/usr/bin/aseprite"))
    session=service.start_session(profile="melee_1h",group="posture",action="draw_01",direction="e")
    ref=service.reference_resolve(session,profile="melee_1h",group="posture",action="idle_ready_01",direction="e")
    assert ref["authority"]=="canonical_source" and ref["frame_count"]==5
    rendered=service.reference_render(session,reference_id=ref["reference_id"])
    assert Path(rendered["animation"]).exists()
    before=ref["source_hashes"];assert service.reference_resolve(session,profile="melee_1h",group="posture",action="idle_ready_01",direction="e")["source_hashes"]==before
print("operator_art_agent_reference_smoke ok")
