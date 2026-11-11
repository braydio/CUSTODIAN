#!/usr/bin/env python3
"""Exact-run recovery for one authenticated findings-only paired review."""
from __future__ import annotations
import argparse, hashlib, json, os, re, stat, subprocess, sys
from pathlib import Path
TOOLS = Path(__file__).resolve().parent
if str(TOOLS) not in sys.path: sys.path.insert(0, str(TOOLS))
import paired_review_runner as rr
import review_outcome

WORKSTREAM = "review-agent-paired-review-findings-artifact-recovery-v1"
RUN_ID = "20261110T113743Z-f5db7f631c66"
CLAIM_RUN = "20261110T113805Z-ee5bb73efbaf"
TURN = "ee5bb73efbaf4e39af72b0c82836f0eb"
REVIEWED_BASELINE = "6189e1ec2e2101be8c788efcbdea487bf80603bf"
SOURCE_SHA = "6ce61c8f8b101d88e8c05f0312cd1f4931873743"
SPAN_BASE = "d37b29291591454b0c8a6d9218b6806adf66263a"
IMPLEMENTATION = "a4e9dbc8505bcde3eb20b5f40b32df838a4b550d"
TARGET = "agent-paired-review-findings-artifact-recovery-v1"
TARGET_PACKET = f"{rr.PACKET_ROOT}/archived/AGENT_PAIRED_REVIEW_FINDINGS_ARTIFACT_RECOVERY_V1.md"
ACTIVE = f"{rr.PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_FINDINGS_ARTIFACT_RECOVERY_V1.md"
ARCHIVE = f"{rr.PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_FINDINGS_ARTIFACT_RECOVERY_V1.md"
SUMMARY = "REVIEW_AGENT_PAIRED_REVIEW_FINDINGS_ARTIFACT_RECOVERY_V1_CLAUDE_SUMMARY.md"
CHAT = "https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af253c2-3c40-83ea-a136-5047fc969fbe"
PINS = {
 "codex.stderr":"968303706222395f430b02a75548ca5c2b4e661aa89fec4ada21d7f4861dc2b7",
 "codex.jsonl":"260b1462b46b1796ef23abbc34540dd429479cb150f8030e68f9c913fceb43e6",
 "last-message.txt":"d7e36b6aa18cda73c56b27b0a402988bee03c52fecea5d089aa5d5bd4100e943",
 "claim-receipt.json":"ba74a6fe54ad6bef1ee8a3ae175fa6d089ccb43fa33de53595f026b2298deb93",
 "archive.md":"70b005b2555f77a640805c092b786d80f471f5113579e1f78cfd00b1124ac331",
 "summary.md":"1841fdc159a4fb7b6b1fa90212c2221184957da8eede0b252fce30cfb44edb6d",
 "validation.json":"c0cca55e56ea38395acc97ef8fdeb2d8d4b87cabacd5bac56e86e23fc6e07e19",
}
EXPECTED_ERR = "Failed to find expected lines"
COMMAND_FAILURES = ((27,2,"667086c63a101ae11fe3ed1b323ba0e18c68ef571b775f81a74bc9fcc29bbdfa"),(29,1,"b1b36359e3a8745332ca18e0c0c8f587eaca54daf9d611e487d0c67c68060728"),(33,1,"e0870116c7f8b5f284b4255d5a96074c767203b14397339efa7f4b2b18ad1f28"),(39,2,"5d0ea150030523b5ac1cc94f2f9b06415aa6fd3eec8c9553204251cfe4a82a45"),(40,1,"144862beaac58efe2c7ce3802bfcdae3198f080dcf8b81f2b0fcae8f5f1c3384"),(44,1,"fc086b74d4a3e800735ebd8f814041e76e24ec891bcac638b67238cf8e2b01c3"))

def digest(b: bytes) -> str: return hashlib.sha256(b).hexdigest()
def _plan_digest(payload: dict) -> str:
    body={k:v for k,v in payload.items() if k!="plan_sha256"}
    return digest(json.dumps(body,sort_keys=True,separators=(",",":"),ensure_ascii=False).encode())
def _validate_apply_authorization(receipt: dict, plan_sha256: str):
    del receipt, plan_sha256
    raise ValueError("apply is blocked: no independently verifiable project-owner authorization source is configured")

def public_plan_report(prepared: dict) -> dict:
    """Return the bounded plan projection safe for terminals and orchestration logs."""
    return {
        "schema": prepared["schema"], "workstream": prepared["workstream"],
        "run_id": prepared["run_id"], "reviewed_main_baseline": prepared["reviewed_main_baseline"],
        "run_source_sha": prepared["run_source_sha"], "implementation_commit": prepared["implementation_commit"],
        "branch_tip": prepared["branch_tip"], "plan_sha256": prepared["plan_sha256"],
        "outcome": prepared["outcome"].get("Outcome"),
        "finding_ids": list(review_outcome.finding_ids(prepared["outcome"])),
        "run_file_count": len(prepared["run_manifest"]),
        "session": {key: prepared["session"][key] for key in
                    ("jsonl_sha256", "final_sha256", "stderr_sha256", "command_failure_count")},
        "host_validation_sha256": prepared["host"].get("report_sha256"),
        "archive_sha256": prepared["archive_sha256"], "summary_sha256": prepared["summary_sha256"],
        "target_sha256": prepared["target_sha256"],
        "inventory_entry_count": len(prepared["checkout_inventory"]["entries"]),
        "ignored_path_count": len(prepared["checkout_inventory"]["ignored"]),
        "protected_status_path_count": len(prepared["protected_checkout_status"]),
        "owner_count": len(prepared["process_owner_scan"]["owners"]),
        "integrity_report_sha256": prepared["integrity_report_sha256"],
        "write_performed": False,
    }
def _reviewed_main(text: str):
    match=re.search(r"(?m)^- Reviewed main: `([0-9a-f]{40,64})`$",text)
    return match.group(1) if match else None
def run(args, cwd): return subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=True).stdout.strip()
def _tree(path: Path):
    """Complete lstat inventory; symlink targets are recorded, never followed."""
    rows=[]
    for p in sorted(path.rglob("*"), key=lambda x:x.relative_to(path).as_posix()):
        st=p.lstat(); rel=p.relative_to(path).as_posix(); mode=stat.S_IMODE(st.st_mode)
        if stat.S_ISLNK(st.st_mode): rows.append([rel,"symlink",mode,os.readlink(p)])
        elif stat.S_ISDIR(st.st_mode): rows.append([rel,"directory",mode])
        elif stat.S_ISREG(st.st_mode): rows.append([rel,"file",mode,digest(p.read_bytes())])
        else: rows.append([rel,"other",mode,st.st_rdev])
    return rows

def _proc_identity(proc_entry: Path):
    raw=(proc_entry/"stat").read_text()
    tail=raw.rsplit(")",1)[1].split()
    if len(tail)<=19: raise ValueError("process stat record is malformed")
    return tail[19]

def _gpg_service_identity(pid: int, uid: int):
    result=subprocess.run(["systemctl","--user","show","gpg-agent.service","-p","MainPID","-p","ControlGroup","-p","ActiveState"],capture_output=True,text=True)
    if result.returncode: return None
    values={}
    for line in result.stdout.splitlines():
        if "=" in line:
            key,value=line.split("=",1); values[key]=value
    expected_prefix=f"/user.slice/user-{uid}.slice/user@{uid}.service/"
    group=values.get("ControlGroup","")
    if (values.get("ActiveState")!="active" or values.get("MainPID")!=str(pid)
            or not group.startswith(expected_prefix) or not group.endswith("/gpg-agent.service")):
        return None
    return {"pid":pid,"uid":uid,"control_group":group,"service":"gpg-agent.service"}

def _verified_gpg_agent(pid: int, *, proc_root: Path=Path("/proc"), uid: int | None=None, service_lookup=None):
    """Return stable systemd-backed identity; a process name by itself never qualifies."""
    uid=os.getuid() if uid is None else uid
    service_lookup=_gpg_service_identity if service_lookup is None else service_lookup
    entry=proc_root/str(pid)
    try:
        if entry.stat().st_uid!=uid or (entry/"comm").read_text().strip()!="gpg-agent": return None
        start=_proc_identity(entry); group=(entry/"cgroup").read_text().strip().split("::",1)[-1]
        service=service_lookup(pid,uid)
        if not service or service.get("pid")!=pid or service.get("uid")!=uid or service.get("control_group")!=group: return None
        # Re-read OS identity and service ownership to reject PID reuse/races.
        again=_proc_identity(entry); comm=(entry/"comm").read_text().strip(); group2=(entry/"cgroup").read_text().strip().split("::",1)[-1]
        service2=service_lookup(pid,uid)
    except (OSError,ValueError,IndexError):
        return None
    if start!=again or comm!="gpg-agent" or group2!=group or service2!=service: return None
    return {**service,"start_ticks":start,"classification":"verified-systemd-credential-agent"}

def _ssh_service_identity(pid: int, uid: int):
    result=subprocess.run(["systemctl","--user","show","ssh-agent.service","-p","MainPID","-p","ControlGroup","-p","ActiveState"],capture_output=True,text=True)
    if result.returncode: return None
    values={line.split("=",1)[0]:line.split("=",1)[1] for line in result.stdout.splitlines() if "=" in line}
    group=values.get("ControlGroup",""); prefix=f"/user.slice/user-{uid}.slice/user@{uid}.service/"
    if values.get("ActiveState")!="active" or values.get("MainPID")!=str(pid) or not group.startswith(prefix) or not group.endswith("/ssh-agent.service"): return None
    return {"pid":pid,"uid":uid,"control_group":group,"service":"ssh-agent.service"}

def _verified_gpg_child(pid: int, *, proc_root: Path=Path("/proc"), uid: int | None=None):
    """Authenticate scdaemon only as a stable child of the pinned gpg-agent service."""
    uid=os.getuid() if uid is None else uid; entry=proc_root/str(pid)
    try:
        if entry.stat().st_uid!=uid or (entry/"comm").read_text().strip()!="scdaemon": return None
        start=_proc_identity(entry); fields=(entry/"stat").read_text().rsplit(")",1)[1].split(); parent=int(fields[1])
        parent_identity=_verified_gpg_agent(parent,proc_root=proc_root,uid=uid)
        group=(entry/"cgroup").read_text().strip().split("::",1)[-1]
        argv=(entry/"cmdline").read_bytes().split(b"\0")
        if not parent_identity or group!=parent_identity["control_group"] or b"--multi-server" not in argv: return None
        again=_proc_identity(entry); fields2=(entry/"stat").read_text().rsplit(")",1)[1].split()
        comm2=(entry/"comm").read_text().strip(); group2=(entry/"cgroup").read_text().strip().split("::",1)[-1]
        argv2=(entry/"cmdline").read_bytes().split(b"\0")
    except (OSError,ValueError,IndexError): return None
    if start!=again or int(fields2[1])!=parent or comm2!="scdaemon" or group2!=group or argv2!=argv: return None
    return {"pid":pid,"uid":uid,"parent_pid":parent,"start_ticks":start,"control_group":group,"classification":"verified-gpg-agent-child"}

def _verified_ssh_agent(pid: int, *, proc_root: Path=Path("/proc"), uid: int | None=None):
    uid=os.getuid() if uid is None else uid; entry=proc_root/str(pid)
    try:
        if entry.stat().st_uid!=uid or (entry/"comm").read_text().strip()!="ssh-agent": return None
        start=_proc_identity(entry); group=(entry/"cgroup").read_text().strip().split("::",1)[-1]
        service=_ssh_service_identity(pid,uid)
        if not service or service.get("control_group")!=group: return None
        again=_proc_identity(entry); comm=(entry/"comm").read_text().strip(); group2=(entry/"cgroup").read_text().strip().split("::",1)[-1]
        service2=_ssh_service_identity(pid,uid)
    except (OSError,ValueError,IndexError): return None
    if start!=again or comm!="ssh-agent" or group2!=group or service2!=service: return None
    return {**service,"start_ticks":start,"classification":"verified-systemd-credential-agent"}

def _verified_user_systemd(pid: int, *, proc_root: Path=Path("/proc"), uid: int | None=None):
    """Authenticate only the current user's systemd manager, never comm alone."""
    uid=os.getuid() if uid is None else uid; entry=proc_root/str(pid)
    expected_group=f"/user.slice/user-{uid}.slice/user@{uid}.service/init.scope"
    try:
        if entry.stat().st_uid!=uid: return None
        start=_proc_identity(entry); comm=(entry/"comm").read_text().strip()
        group=(entry/"cgroup").read_text().strip().split("::",1)[-1]
        argv=(entry/"cmdline").read_bytes().split(b"\0")
        # Require the manager invocation and its exact user-manager cgroup.
        if comm!="systemd" or group!=expected_group or b"--user" not in argv: return None
        again=_proc_identity(entry); comm2=(entry/"comm").read_text().strip()
        group2=(entry/"cgroup").read_text().strip().split("::",1)[-1]
        argv2=(entry/"cmdline").read_bytes().split(b"\0")
    except (OSError,ValueError,IndexError): return None
    if start!=again or comm2!="systemd" or group2!=expected_group or argv2!=argv: return None
    return {"pid":pid,"uid":uid,"start_ticks":start,"control_group":group,"classification":"verified-user-systemd-manager"}

def _verified_user_pam(pid: int, *, proc_root: Path=Path("/proc"), uid: int | None=None):
    """Authenticate the user manager's PAM session helper by cgroup and parent identity."""
    uid=os.getuid() if uid is None else uid; entry=proc_root/str(pid)
    expected_group=f"/user.slice/user-{uid}.slice/user@{uid}.service/init.scope"
    try:
        if entry.stat().st_uid!=uid: return None
        start=_proc_identity(entry); tail=(entry/"stat").read_text().rsplit(")",1)[1].split(); parent=int(tail[1])
        comm=(entry/"comm").read_text().strip(); group=(entry/"cgroup").read_text().strip().split("::",1)[-1]
        argv=(entry/"cmdline").read_bytes().split(b"\0")
        manager=_verified_user_systemd(parent,proc_root=proc_root,uid=uid)
        if comm!="(sd-pam)" or group!=expected_group or argv not in ([b"(sd-pam)",b""],[b"(sd-pam)"] ) or not manager: return None
        again=_proc_identity(entry); tail2=(entry/"stat").read_text().rsplit(")",1)[1].split()
        comm2=(entry/"comm").read_text().strip(); group2=(entry/"cgroup").read_text().strip().split("::",1)[-1]
        argv2=(entry/"cmdline").read_bytes().split(b"\0")
    except (OSError,ValueError,IndexError): return None
    if start!=again or int(tail2[1])!=parent or comm2!="(sd-pam)" or group2!=expected_group or argv2!=argv: return None
    return {"pid":pid,"uid":uid,"parent_pid":parent,"start_ticks":start,"control_group":group,"classification":"verified-user-systemd-pam-helper"}

def _review_process_owners(worktree: Path, workstream: str, run_id: str, *, proc_root: Path=Path("/proc"), service_lookup=None):
    if not proc_root.is_dir(): raise ValueError("host process ownership cannot be verified")
    # Exclude only this verifier process. Its ancestors must still be checked:
    # launching the verifier does not make an ancestor unrelated to the review.
    excluded={os.getpid()}
    expected=str(worktree.resolve()); owners=[]; verified=[]
    for entry in proc_root.iterdir():
        if not entry.name.isdigit() or int(entry.name) in excluded: continue
        try:
            if entry.stat().st_uid!=os.getuid(): continue
            comm=(entry/"comm").read_text().strip()
        except FileNotFoundError: continue
        except PermissionError as exc: raise ValueError(f"cannot inspect same-user process {entry.name} identity") from exc
        if comm=="systemd":
            manager=_verified_user_systemd(int(entry.name),proc_root=proc_root)
            if manager:
                verified.append(manager); continue
        if comm=="scdaemon":
            child=_verified_gpg_child(int(entry.name),proc_root=proc_root)
            if child:
                try: argv=(entry/"cmdline").read_bytes().replace(b"\0",b" ").decode("utf-8","replace")
                except FileNotFoundError: continue
                except PermissionError as exc: raise ValueError(f"cannot verify authenticated scdaemon command identity for {entry.name}") from exc
                if expected in argv or workstream in argv or run_id in argv: owners.append({"pid":int(entry.name),"identity_command_match":True})
                else: verified.append(child)
                continue
        if comm=="(sd-pam)":
            pam=_verified_user_pam(int(entry.name),proc_root=proc_root)
            if pam:
                verified.append(pam); continue
        if comm=="ssh-agent":
            classification=_verified_ssh_agent(int(entry.name),proc_root=proc_root)
            if classification:
                try: argv=(entry/"cmdline").read_bytes().replace(b"\0",b" ").decode("utf-8","replace")
                except FileNotFoundError: continue
                except PermissionError as exc: raise ValueError(f"cannot verify authenticated ssh-agent command identity for {entry.name}") from exc
                if expected in argv or workstream in argv or run_id in argv: owners.append({"pid":int(entry.name),"identity_command_match":True})
                else: verified.append(classification)
                continue
        if comm=="gpg-agent":
            classification=_verified_gpg_agent(int(entry.name),proc_root=proc_root,uid=os.getuid(),service_lookup=service_lookup)
            if classification:
                try: argv=(entry/"cmdline").read_bytes().replace(b"\0",b" ").decode("utf-8","replace")
                except FileNotFoundError: continue
                except PermissionError as exc: raise ValueError(f"cannot verify authenticated gpg-agent command identity for {entry.name}") from exc
                if expected in argv or workstream in argv or run_id in argv:
                    owners.append({"pid":int(entry.name),"identity_command_match":True})
                else: verified.append(classification)
                continue
        try:
            argv=(entry/"cmdline").read_bytes().replace(b"\0",b" ").decode("utf-8","replace")
            cwd=os.readlink(entry/"cwd").removesuffix(" (deleted)")
        except FileNotFoundError: continue
        except PermissionError as exc: raise ValueError(f"cannot inspect same-user process {entry.name} for review ownership") from exc
        if cwd==expected or cwd.startswith(expected+os.sep) or expected in argv:
            owners.append({"pid":int(entry.name),"cwd_match":cwd==expected or cwd.startswith(expected+os.sep),"command_path_match":expected in argv})
        elif (workstream in argv or run_id in argv) and any(token in argv.lower() for token in ("codex","paired_review_runner","workstream.py")):
            owners.append({"pid":int(entry.name),"identity_command_match":True})
    return {"owners":owners,"verified_unrelated_processes":verified}

def _validate_stderr_bytes(stderr_bytes: bytes):
    if digest(stderr_bytes) != PINS["codex.stderr"]: raise ValueError("stderr digest mismatch")
    stderr=stderr_bytes.decode("utf-8")
    if len(stderr_bytes) != 550 or stderr.count(EXPECTED_ERR) != 1 or stderr.count("apply_patch") != 1 or "Traceback" in stderr or len(stderr.splitlines()) != 4:
        raise ValueError("stderr is not the single expected context-verification failure")

def _parse_session(run_dir, metadata, runner_source, control_source):
    # Keep the generic parser strict; this dedicated path does not call it or sanitize a copy.
    files={n:(run_dir/n).read_bytes() for n in ("codex.stderr","codex.jsonl","last-message.txt")}
    if any((run_dir/n).is_symlink() for n in files): raise ValueError("unsafe session evidence")
    _validate_stderr_bytes(files["codex.stderr"])
    if not metadata.get("fresh") is True or metadata.get("exit_code") != 0: raise ValueError("not a fresh successful run")
    events=[json.loads(line) for line in files["codex.jsonl"].decode().splitlines()]
    if not events or any(not isinstance(e,dict) for e in events): raise ValueError("invalid event stream")
    for e in events:
        typ=str(e.get("type","")).lower(); item=e.get("item",{})
        if typ in {"error","item.failed","turn.failed","tool.error","response.failed","stream.error"} or typ.endswith((".failed",".error")) or e.get("error") not in (None,"",{},[]): raise ValueError("failed session event")
        if isinstance(item,dict) and (item.get("type") in {"error","tool_error","failure","failed"} or item.get("error") not in (None,"",{},[])): raise ValueError("failed session item")
    threads=[e for e in events if e.get("type")=="thread.started"]
    starts=[i for i,e in enumerate(events) if e.get("type")=="turn.started"]
    ends=[i for i,e in enumerate(events) if e.get("type")=="turn.completed"]
    if len(threads)!=1 or not threads[0].get("thread_id") or len(starts)!=1 or len(ends)!=1 or starts[0]>=ends[0]: raise ValueError("not exactly one completed thread/turn")
    msgs=[]
    for i,e in enumerate(events):
        item=e.get("item")
        if isinstance(item,dict) and item.get("type")=="agent_message":
            if not isinstance(item.get("text"),str): raise ValueError("malformed agent message")
            msgs.append((i,item["text"]))
    if not msgs or msgs[-1][0]<=starts[0] or msgs[-1][0]>=ends[0] or any(i<=starts[0] or i>=ends[0] for i,_ in msgs): raise ValueError("missing/extra final messages")
    verdict=re.compile(r"(?im)^\s*\*{0,2}(?:independent disposition|verdict|review outcome|findings?)\s*:")
    if any(verdict.search(t) for _,t in msgs[:-1]): raise ValueError("contradictory earlier verdict")
    final=files["last-message.txt"].decode()
    rr._verify_redacted_final_capture(final,msgs[-1][1],runner_source,control_source)
    dispositions=re.findall(r"(?im)^\s*(?:review outcome|independent disposition|verdict|outcome)\s*:\s*`?([a-z_]+)",final)
    if ("R0-01" not in final or not re.search(r"(?i)findings?",final)
            or any(value.casefold() not in {"finding","findings"} for value in dispositions)):
        raise ValueError("final does not corroborate the exact findings / R0-01 disposition")
    failures=rr._classify_session_command_failures(events)
    observed=tuple((x["event_index"],x["exit_code"],x["stored_output_sha256"]) for x in failures)
    if observed!=COMMAND_FAILURES: raise ValueError("command failure inventory differs from the exact authenticated session")
    return final,{"thread_id":threads[0]["thread_id"],"jsonl_sha256":digest(files["codex.jsonl"]),"final_sha256":digest(files["last-message.txt"]),"stderr_sha256":digest(files["codex.stderr"]),"command_failure_count":len(failures)}

def plan(repo: Path, recovery_checkout: Path):
    repo=Path(run(["git","rev-parse","--show-toplevel"],repo)).resolve(); common=rr.common_dir(repo).resolve()
    main=rr._cached_remote_ref_for_readonly_plan(repo,"main")
    if subprocess.run(["git","merge-base","--is-ancestor",REVIEWED_BASELINE,main],cwd=repo,capture_output=True).returncode: raise ValueError("origin/main lacks pinned baseline")
    rd=common/"custodian-review-runs"/WORKSTREAM/RUN_ID
    if rd.is_symlink() or not rd.is_dir(): raise ValueError("exact protected run directory is missing or unsafe")
    expected_run_files={"metadata.json","claim.stdout","claim-receipt.json","claim.stderr","codex.jsonl","codex.stderr","last-message.txt","validation.json","coordinator-validation.json","RECOVERY.md"}
    entries=list(rd.iterdir())
    if {p.name for p in entries}!=expected_run_files: raise ValueError("exact run evidence file inventory changed")
    names=sorted(p.name for p in entries if p.is_file() and not p.is_symlink())
    if any(p.is_symlink() or not p.is_file() for p in rd.iterdir()): raise ValueError("unsafe or non-regular run evidence")
    run_manifest={name:digest((rd/name).read_bytes()) for name in names}
    for name in ("codex.stderr","codex.jsonl","last-message.txt","claim-receipt.json","validation.json"):
        if run_manifest.get(name) != PINS[name]: raise ValueError(f"pinned evidence digest mismatch: {name}")
    md=json.loads((rd/"metadata.json").read_text())
    if (md.get("run_id"),md.get("workstream"),md.get("phase"),md.get("reviewed_main"),md.get("branch")) != (RUN_ID,WORKSTREAM,"post_exit_recovery",SOURCE_SHA,f"agent/{WORKSTREAM}"): raise ValueError("run metadata identity mismatch")
    span=md.get("host_validation",{}).get("source_span",{})
    if (span.get("base"),span.get("head"),span.get("commits")) != (SPAN_BASE,IMPLEMENTATION,[IMPLEMENTATION]): raise ValueError("source-span identity mismatch")
    if span.get("provenance",{}).get("kind") != "canonical-implementation-commit": raise ValueError("source-span provenance mismatch")
    original=Path(md["worktree"])
    if not original.is_dir() or original.is_symlink() or rr.common_dir(original).resolve()!=common or run(["git","branch","--show-current"],original)!=f"agent/{WORKSTREAM}": raise ValueError("registered checkout mismatch")
    tip=rr._cached_remote_ref_for_readonly_plan(repo,f"agent/{WORKSTREAM}")
    if run(["git","rev-parse","HEAD"],original)!=tip or tip!=SOURCE_SHA: raise ValueError("branch tip mismatch")
    process_scan=_review_process_owners(original,WORKSTREAM,RUN_ID)
    if process_scan["owners"]: raise ValueError("a live process owns the protected review checkout")
    active_text=rr._show_at(repo,SOURCE_SHA,ACTIVE)
    current_active_text=rr._show_at(repo,main,ACTIVE)
    packet=rr.parse_packet(ACTIVE,active_text)
    current_packet=rr.parse_packet(ACTIVE,current_active_text)
    if (packet.error or _reviewed_main(active_text)!=REVIEWED_BASELINE or packet.workstream!=WORKSTREAM
            or current_packet.error or _reviewed_main(current_active_text)!=REVIEWED_BASELINE
            or current_packet.workstream!=WORKSTREAM or current_packet.review_target_workstream!=TARGET
            or current_packet.review_target_packet!=TARGET_PACKET or packet.review_target_packet!=TARGET_PACKET): raise ValueError("original active packet identity mismatch")
    archive_p=original/ARCHIVE; summary_p=original/SUMMARY
    if archive_p.is_symlink() or summary_p.is_symlink() or not archive_p.is_file() or not summary_p.is_file(): raise ValueError("unsafe reviewer artifact")
    source_status=rr._changed_paths(original,"status","--porcelain=v1","--untracked-files=all")
    status_paths={line[3:] for line in source_status}
    expected_status={ACTIVE,ARCHIVE,f"{rr.PACKET_ROOT}/README.md",SUMMARY}
    if status_paths!=expected_status or len(source_status)!=4: raise ValueError("protected review checkout contains changed or untracked paths outside its exact closeout state")
    ab,sb=archive_p.read_bytes(),summary_p.read_bytes()
    if digest(ab)!=PINS["archive.md"] or digest(sb)!=PINS["summary.md"]: raise ValueError("review artifact digest mismatch")
    archive,summary=ab.decode(),sb.decode()
    outcome,error=review_outcome.parse_review_outcome(archive)
    if error or not outcome or outcome.get("Outcome")!="findings" or review_outcome.finding_ids(outcome)!=("R0-01",): raise ValueError("not the exact R0-01 findings outcome")
    if outcome.get("Reviewed main")!=SOURCE_SHA or outcome.get("Reviewed implementation commit")!=IMPLEMENTATION or outcome.get("Run ID")!=RUN_ID: raise ValueError("outcome identity mismatch")
    target=rr._show_at(repo,SOURCE_SHA,TARGET_PACKET)
    impl,err=rr.resolve_target_implementation_commit(repo,SOURCE_SHA,TARGET_PACKET,TARGET,target)
    if err or impl!=IMPLEMENTATION or rr._show_at(repo,main,TARGET_PACKET)!=target: raise ValueError("target bytes/implementation changed")
    claim,source=rr._host_validation_claim_receipt(rd,WORKSTREAM,repo,{**md,"recovery_worktree":str(original)},ACTIVE)
    acquisition=Path(claim.get("acquisition_receipt",""))
    if (acquisition.is_symlink() or not acquisition.is_file()
            or not acquisition.resolve().is_relative_to((common/"custodian-turn-dispatcher-v2"/"acquisitions").resolve())): raise ValueError("acquisition record is missing or outside repository metadata")
    if source!="claim-receipt.json" or claim.get("turn_id")!=TURN or claim.get("worktree")!=str(original) or claim.get("branch")!=f"agent/{WORKSTREAM}": raise ValueError("claim/acquisition mismatch")
    run_dir=rd
    runner_source=rr._show_at(repo,SOURCE_SHA,"custodian/tools/agent/paired_review_runner.py")
    control_source=rr._show_at(repo,SOURCE_SHA,"custodian/tools/agent/workflow_control.py")
    final,session=_parse_session(run_dir,md,runner_source,control_source)
    if not re.search(r"(?i)R0-01",summary) or "findings" not in summary.casefold() or "R0-01" not in archive: raise ValueError("reviewer artifacts do not corroborate finding")
    host=rr._host_evidence_for_continuation(repo,original,rd,md,SOURCE_SHA,IMPLEMENTATION,TARGET,TARGET_PACKET)
    if host["report_sha256"]!=PINS["validation.json"]: raise ValueError("host report pin mismatch")
    author=packet.authoring_chat
    reasons=rr.nonpassing_review_reasons(archive,summary,rr._show_at(original,"HEAD",TARGET_PACKET) if False else target,repo=repo,workstream=WORKSTREAM,active_packet_path=ACTIVE,target_workstream=TARGET,target_packet_path=TARGET_PACKET,target_content=target,authoring_chat=author,reviewed_main=SOURCE_SHA,run_id=RUN_ID)
    if reasons: raise ValueError("canonical closeout rejected: "+"; ".join(reasons))
    inv={"entries":_tree(original),"git_status":rr._changed_paths(original,"status","--porcelain=v1","--untracked-files=all"),"ignored":sorted(rr._ignored_worktree_inventory(original))}
    cp=Path(recovery_checkout).resolve()
    integrity={**rr.nonpassing_integrity_report("findings"),"integrity_only":True,"workstream":WORKSTREAM,"run_id":RUN_ID,"finding_ids":["R0-01"],"reviewed_main":SOURCE_SHA,"implementation_commit":IMPLEMENTATION,"target_sha256":digest(target.encode())}
    integrity_path=common/"custodian-review-runs"/WORKSTREAM/f"{RUN_ID}.findings-closeout-integrity.json"
    if integrity_path.is_symlink(): raise ValueError("unsafe integrity-report path")
    integrity_bytes=(json.dumps(integrity,indent=2,sort_keys=True)+"\n").encode()
    if integrity_path.exists() and digest(integrity_path.read_bytes())!=digest(integrity_bytes): raise ValueError("existing integrity report differs from exact findings closeout")
    result={"schema":"custodian.paired_review_findings_closeout_recovery.plan.v1","workstream":WORKSTREAM,"run_id":RUN_ID,"claim_run_id":CLAIM_RUN,"turn_id":TURN,"reviewed_main_baseline":REVIEWED_BASELINE,"active_packet_sha256":digest(active_text.encode()),"current_active_packet_sha256":digest(current_active_text.encode()),"current_main":main,"run_source_sha":SOURCE_SHA,"source_span_base":SPAN_BASE,"implementation_commit":IMPLEMENTATION,"branch_tip":tip,"claim":claim,"acquisition_sha256":digest(Path(claim["acquisition_receipt"]).read_bytes()),"run_manifest":run_manifest,"session":session,"host":host,"archive_sha256":digest(ab),"summary_sha256":digest(sb),"archive_text":archive,"summary_text":summary,"target_sha256":digest(target.encode()),"checkout":str(original),"checkout_inventory":inv,"protected_checkout_status":source_status,"process_owner_scan":process_scan,"allowed_paths":[ACTIVE,ARCHIVE,f"{rr.PACKET_ROOT}/README.md",SUMMARY],"recovery_checkout":str(cp),"outcome":outcome,"final_sha256":digest(final.encode()),"integrity_report_path":str(integrity_path),"integrity_report":integrity,"integrity_report_sha256":digest(integrity_bytes)}
    result["plan_sha256"]=_plan_digest(result)
    return result


def apply(repo: Path, checkout: Path, prepared: dict, authorization: dict):
    """Apply a separately authorized plan only in a sibling recovery checkout."""
    repo=Path(run(["git","rev-parse","--show-toplevel"],repo)).resolve()
    checkout=Path(checkout).expanduser().resolve()
    if checkout==repo or not checkout.is_relative_to(repo.parent): raise ValueError("recovery checkout must be an isolated sibling")
    _validate_apply_authorization(authorization,prepared["plan_sha256"])
    common=rr.common_dir(repo).resolve(); branch=f"recovery/{WORKSTREAM}-{RUN_ID.rsplit('-',1)[1]}"
    journal=common/"custodian-review-runs"/WORKSTREAM/f"{RUN_ID}.closeout-recovery.json"
    if journal.is_symlink(): raise ValueError("unsafe recovery journal")
    state={"schema":"custodian.findings_closeout_recovery_journal.v1","plan_sha256":prepared["plan_sha256"],"branch":branch,"checkout":str(checkout)}
    if journal.exists():
        prior=json.loads(journal.read_text())
        if any(prior.get(k)!=state[k] for k in state): raise ValueError("journal belongs to another plan")
        allowed_stages={"checkout_creation_started","artifact_write_started","artifacts_written","commit_started","committed","integrity_report_written","publish_started","published"}
        if prior.get("stage") not in allowed_stages: raise ValueError("recovery journal stage is unsupported")
        state.update(prior)
    elif checkout.exists(): raise ValueError("recovery checkout exists without its authenticated journal")
    remote_ref=f"refs/heads/{branch}"
    remote_result=subprocess.run(["git","ls-remote","--heads","origin",remote_ref],cwd=repo,text=True,capture_output=True)
    if remote_result.returncode: raise ValueError("cannot authenticate recovery branch state")
    remote_rows=[line.split() for line in remote_result.stdout.splitlines() if line.split()]
    if len(remote_rows)>1 or (remote_rows and (len(remote_rows[0])!=2 or remote_rows[0][1]!=remote_ref or not re.fullmatch(r"[0-9a-f]{40,64}",remote_rows[0][0]))): raise ValueError("recovery branch ref is malformed or ambiguous")
    remote_sha=remote_rows[0][0] if remote_rows else None
    if remote_sha and not journal.exists(): raise ValueError("recovery branch exists without its authenticated journal")
    if remote_sha and state.get("published_sha") not in (None,remote_sha): raise ValueError("remote recovery branch differs from journal")
    if remote_sha and state.get("stage")=="published" and remote_sha!=state.get("commit_sha"): raise ValueError("published branch no longer matches journaled commit")
    def record(stage,**extra):
        state.update(stage=stage,**extra); journal.parent.mkdir(parents=True,exist_ok=True)
        tmp=journal.with_suffix(".tmp"); tmp.write_text(json.dumps(state,sort_keys=True,indent=2)+"\n"); os.replace(tmp,journal)
    def fresh():
        latest=plan(repo,checkout)
        if latest["plan_sha256"]!=prepared["plan_sha256"]: raise ValueError("source evidence, owner state, or plan changed")
    if not checkout.exists():
        fresh(); record("checkout_creation_started")
        subprocess.run(["git","worktree","add","-b",branch,str(checkout),prepared["current_main"]],cwd=repo,check=True,capture_output=True)
    if rr.common_dir(checkout).resolve()!=common or run(["git","branch","--show-current"],checkout)!=branch: raise ValueError("recovery checkout identity mismatch")
    allowed=set(prepared["allowed_paths"])
    changed=set(rr._changed_paths(checkout,"status","--porcelain=v1","--untracked-files=all"))
    paths={line[3:] for line in changed}
    if paths-allowed: raise ValueError("recovery checkout has out-of-scope files")
    completed_artifacts={"artifacts_written","commit_started","committed","integrity_report_written","publish_started","published"}
    if state.get("stage") not in completed_artifacts:
        fresh(); record("artifact_write_started")
        for rel,key in ((ARCHIVE,"archive_text"),(SUMMARY,"summary_text")):
            out=checkout/rel; out.parent.mkdir(parents=True,exist_ok=True)
            if out.exists() and out.read_text()!=prepared[key]: raise ValueError("destination artifact differs")
            fresh()
            tmp=out.with_suffix(out.suffix+".tmp"); tmp.write_text(prepared[key]); os.replace(tmp,out)
        active=checkout/ACTIVE
        fresh()
        if active.exists(): active.unlink()
        fresh()
        subprocess.run([sys.executable,str(checkout/"custodian/tools/agent/task_packet_index.py"),"--write"],cwd=checkout,check=True,capture_output=True)
        record("artifacts_written",artifact_hashes={ARCHIVE:prepared["archive_sha256"],SUMMARY:prepared["summary_sha256"]})
    else:
        for rel,key in ((ARCHIVE,"archive_sha256"),(SUMMARY,"summary_sha256")):
            path=checkout/rel
            if path.is_symlink() or not path.is_file() or digest(path.read_bytes())!=prepared[key]: raise ValueError("journaled recovery artifact changed")
        if (checkout/ACTIVE).exists(): raise ValueError("journaled recovery still contains the active packet")
    readme=checkout/f"{rr.PACKET_ROOT}/README.md"
    subprocess.run([sys.executable,str(checkout/"custodian/tools/agent/task_packet_index.py")],cwd=checkout,check=True,capture_output=True)
    base_readme=rr._show_at(checkout,prepared["current_main"],f"{rr.PACKET_ROOT}/README.md")
    updated_readme=(checkout/f"{rr.PACKET_ROOT}/README.md").read_text(encoding="utf-8")
    if rr._task_packet_readme_shell(base_readme)!=rr._task_packet_readme_shell(updated_readme): raise ValueError("managed index update changed README content outside its owned block")
    target=rr._show_at(checkout,prepared["current_main"],TARGET_PACKET)
    if digest(target.encode())!=prepared["target_sha256"] or rr._show_at(checkout,"HEAD",TARGET_PACKET)!=target: raise ValueError("target packet changed")
    archive=(checkout/ARCHIVE).read_text(); summary=(checkout/SUMMARY).read_text()
    reasons=rr.nonpassing_review_reasons(archive,summary,target,repo=checkout,workstream=WORKSTREAM,active_packet_path=ACTIVE,target_workstream=TARGET,target_packet_path=TARGET_PACKET,target_content=target,authoring_chat=CHAT,reviewed_main=SOURCE_SHA,run_id=RUN_ID)
    if reasons: raise ValueError("canonical nonpassing closeout rejected: "+"; ".join(reasons))
    if state.get("stage") not in {"committed","integrity_report_written","published"}:
        fresh(); record("commit_started")
        rr._stage_bounded(checkout,allowed)
        names=set(rr._changed_paths(checkout,"diff","--cached","--name-only"))
        if names-allowed: raise ValueError("staged paths exceed closeout allowlist")
        fresh()
        if names: subprocess.run(["git","commit","-m","paired review findings closeout recovery [skip render]"],cwd=checkout,check=True,capture_output=True)
        sha=run(["git","rev-parse","HEAD"],checkout); record("committed",commit_sha=sha)
    sha=run(["git","rev-parse","HEAD"],checkout)
    if set(rr._changed_paths(checkout,"diff","--name-only",f"{prepared['current_main']}...{sha}"))-allowed: raise ValueError("recovery commit exceeds the exact four-path allowlist")
    target_final=rr._show_at(checkout,"HEAD",TARGET_PACKET)
    if digest(target_final.encode())!=prepared["target_sha256"]: raise ValueError("committed recovery changed the reviewed target")
    state_check=rr.landed_nonpassing_review_state(checkout,"HEAD",WORKSTREAM,ACTIVE,TARGET,TARGET_PACKET,target_final,CHAT,SOURCE_SHA,RUN_ID)
    if not state_check.get("complete"): raise ValueError("committed closeout failed canonical nonpassing verification")
    integrity_path=Path(prepared["integrity_report_path"]); integrity_raw=(json.dumps(prepared["integrity_report"],indent=2,sort_keys=True)+"\n").encode()
    if digest(integrity_raw)!=prepared["integrity_report_sha256"]: raise ValueError("integrity report digest differs from plan")
    if state.get("stage") not in {"integrity_report_written","published"}:
        fresh()
        if integrity_path.exists() and digest(integrity_path.read_bytes())!=prepared["integrity_report_sha256"]: raise ValueError("integrity report path contains different content")
        if not integrity_path.exists():
            tmp=integrity_path.with_suffix(".tmp"); tmp.write_bytes(integrity_raw); os.replace(tmp,integrity_path)
        record("integrity_report_written",integrity_report_sha256=prepared["integrity_report_sha256"])
    if state.get("stage")!="published":
        fresh(); record("publish_started")
        subprocess.run(["git","push","-u","origin",f"HEAD:refs/heads/{branch}"],cwd=checkout,check=True,capture_output=True)
    remote_result=subprocess.run(["git","ls-remote","--heads","origin",f"refs/heads/{branch}"],cwd=repo,text=True,capture_output=True,check=True)
    remote_rows=[line.split() for line in remote_result.stdout.splitlines() if line.split()]
    if len(remote_rows)!=1 or len(remote_rows[0])!=2 or remote_rows[0][1]!=f"refs/heads/{branch}" or remote_rows[0][0]!=sha: raise ValueError("published recovery branch is missing or differs from the journaled SHA")
    if state.get("stage")!="published": record("published",published_sha=sha)
    return {"status":"published_findings_closeout_waiting_for_landing","branch":branch,"commit":sha,"outcome":"findings","finding_ids":["R0-01"],"integrity_only":True,"integrity_report":prepared["integrity_report_path"]}

def main(argv=None):
    p=argparse.ArgumentParser(); sub=p.add_subparsers(dest="cmd",required=True)
    a=sub.add_parser("plan"); a.add_argument("--repo",type=Path,default=Path.cwd()); a.add_argument("--recovery-checkout",type=Path,required=True)
    a=sub.add_parser("apply"); a.add_argument("--repo",type=Path,default=Path.cwd()); a.add_argument("--recovery-checkout",type=Path,required=True); a.add_argument("--plan-sha256",required=True); a.add_argument("--authorization-receipt",type=Path,required=True)
    x=p.parse_args(argv)
    try:
        current=plan(x.repo,x.recovery_checkout)
        if x.cmd=="apply":
            if x.plan_sha256!=current["plan_sha256"]: raise ValueError("stale plan")
            if x.authorization_receipt.is_symlink() or not x.authorization_receipt.is_file(): raise ValueError("authorization receipt is missing or unsafe")
            receipt=json.loads(x.authorization_receipt.read_text(encoding="utf-8"))
            _validate_apply_authorization(receipt,current["plan_sha256"])
            result=apply(x.repo,x.recovery_checkout,current,receipt)
            print(json.dumps(result,indent=2,sort_keys=True)); return 0
        print(json.dumps(public_plan_report(current),indent=2,sort_keys=True)); return 0
    except Exception as e:
        print(json.dumps({"error":str(e)},sort_keys=True),file=sys.stderr); return 2
if __name__=="__main__": raise SystemExit(main())
