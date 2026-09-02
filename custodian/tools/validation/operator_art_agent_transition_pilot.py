#!/usr/bin/env python3
from __future__ import annotations
from datetime import datetime,timezone
from pathlib import Path
import json,sys
ROOT=Path(__file__).resolve().parents[3];sys.path.insert(0,str(ROOT/"custodian/tools/operator"))
from art_agent.service import ArtAgentService
from animation_workbench_model import file_sha256

def main()->int:
    stamp=datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ");root=ROOT/".ai/operator_art_agent/pilots/transition"/stamp
    service=ArtAgentService(art_root=root/"sessions",workspace_root=root/"workbench",aseprite=Path("/usr/bin/aseprite"))
    session=service.start_session(profile="melee_1h",group="posture",action="draw_01",direction="e",weapon="vigil_pattern_dagger")
    status=service.status(session); before=file_sha256(Path(status["workbench_path"]))
    reference=service.reference_resolve(session,profile="melee_1h",group="posture",action="idle_ready_01",direction="e",weapon="vigil_pattern_dagger",linked_profile="melee_1h_dagger")
    service.reference_render(session,reference_id=reference["reference_id"])
    result=service.compare_transition(session,reference_id=reference["reference_id"],target_tail_frames=2,reference_head_frames=2,layers=["lower_body","upper_body","weapon__vigil_pattern_dagger"])
    assert file_sha256(Path(status["workbench_path"]))==before
    report={"status":"PASS","session":str(session),"reference":reference,"transition":result,"target_unchanged":True,"reference_hashes":reference["source_hashes"]}
    (root/"pilot_report.json").write_text(json.dumps(report,indent=2)+"\n");print(json.dumps(report,indent=2));return 0
if __name__=="__main__":raise SystemExit(main())
