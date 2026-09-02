#!/usr/bin/env python3
from pathlib import Path
import sys,tempfile
ROOT=Path(__file__).resolve().parents[3];sys.path[:0]=[str(ROOT/"custodian/tools/operator")]
from art_agent.service import ArtAgentService
from animation_workbench_model import file_sha256
with tempfile.TemporaryDirectory() as tmp:
    s=ArtAgentService(art_root=Path(tmp)/"art",workspace_root=Path(tmp)/"wb",aseprite=Path("/usr/bin/aseprite"));session=s.start_session(profile="melee_1h",group="posture",action="draw_01",direction="e")
    status=s.status(session);before=file_sha256(Path(status["workbench_path"]));ref=s.reference_resolve(session,profile="melee_1h",group="posture",action="idle_ready_01",direction="e")
    result=s.compare_transition(session,reference_id=ref["reference_id"]);assert all(Path(x).exists() for x in result["artifacts"].values());assert file_sha256(Path(status["workbench_path"]))==before
print("operator_art_agent_transition_smoke ok")
