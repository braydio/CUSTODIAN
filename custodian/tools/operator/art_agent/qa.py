from __future__ import annotations


def run_qa(metrics: dict, *, required_landmarks: list[str] | None = None, landmarks: list[dict] | None = None, critiques: list[dict] | None = None) -> dict:
    findings=[]; existing={x["name"] for x in landmarks or []}
    missing=sorted(set(required_landmarks or [])-existing)
    if missing: findings.append({"severity":"major","class":"anatomy","issue":"missing required landmarks","details":missing})
    if any(frame["semi_transparent_pixels"] for frame in metrics.get("frames",[])): findings.append({"severity":"advisory","class":"pixel_art","issue":"semi-transparent pixels present"})
    if metrics.get("duplicate_adjacent_frames"): findings.append({"severity":"advisory","class":"animation","issue":"adjacent duplicate frames","details":metrics["duplicate_adjacent_frames"]})
    if any(x.get("severity") in {"major","critical"} for x in critiques or []): findings.append({"severity":"major","class":"review","issue":"unresolved major critique"})
    status="RED" if any(x["severity"]=="critical" for x in findings) else "NEEDS_HUMAN_REVIEW" if any(x["severity"]=="major" for x in findings) else "YELLOW" if findings else "GREEN"
    return {"schema":"custodian.operator_art_qa.v1","status":status,"publish_authorized":False,"findings":findings}
