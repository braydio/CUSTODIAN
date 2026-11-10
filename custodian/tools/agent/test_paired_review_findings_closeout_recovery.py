import tempfile
import unittest
from unittest.mock import patch
import hashlib
import json
import os
import subprocess
from unittest.mock import patch
from pathlib import Path

from custodian.tools.agent import paired_review_findings_closeout_recovery as recovery

def _stage(repo, paths):
    pathspecs=[path for path in sorted(paths) if (Path(repo)/path).exists() or subprocess.run(["git","ls-files","--",path],cwd=repo,capture_output=True,text=True).stdout.strip()]
    if pathspecs:
        result=subprocess.run(["git","add","-A","--",*pathspecs],cwd=repo,capture_output=True,text=True)
        if result.returncode: raise AssertionError(result.stderr)
    return None

class FindingsCloseoutRecoveryTests(unittest.TestCase):
    def test_rejects_unpinned_stderr_even_when_shape_looks_expected(self):
        fake = (recovery.EXPECTED_ERR + "\n" + "x" * 550).encode()[:550]
        with self.assertRaisesRegex(ValueError, "digest mismatch"):
            recovery._validate_stderr_bytes(fake)

    def test_scoped_stderr_accepts_only_expected_context_error_shape(self):
        prefix = b"Error: Failed to find expected lines in a patch\napply_patch failed\n"
        raw = prefix + b"x" * (550 - len(prefix) - 2) + b"\n\n"
        with patch.dict(recovery.PINS, {"codex.stderr": hashlib.sha256(raw).hexdigest()}):
            recovery._validate_stderr_bytes(raw)
            changed = raw.replace(b"apply_patch", b"other_tool", 1)
            with patch.dict(recovery.PINS, {"codex.stderr": hashlib.sha256(changed).hexdigest()}):
                with self.assertRaisesRegex(ValueError, "expected context-verification"):
                    recovery._validate_stderr_bytes(changed)

    def test_plan_digest_changes_when_symlink_target_changes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); (root/"a").write_text("a"); (root/"b").write_text("b")
            link=root/"link"; link.symlink_to("a")
            first=recovery._plan_digest({"checkout_inventory":recovery._tree(root)})
            link.unlink(); link.symlink_to("b")
            second=recovery._plan_digest({"checkout_inventory":recovery._tree(root)})
            self.assertNotEqual(first,second)

    def test_apply_authorization_rejects_stale_plan_digest(self):
        plan_sha="a"*64
        message=f"I authorize apply for {recovery.WORKSTREAM} run {recovery.RUN_ID} plan {plan_sha}. Keep outcome findings R0-01."
        receipt={"schema":"custodian.chat_owner_approval.v1","source_url":recovery.CHAT,"approver":"project-owner","user_message":message,"user_message_sha256":hashlib.sha256(message.encode()).hexdigest(),"review_outcome":"findings","finding_ids":["R0-01"]}
        with self.assertRaisesRegex(ValueError,"no independently verifiable"):
            recovery._validate_apply_authorization(receipt,plan_sha)
        with self.assertRaisesRegex(ValueError,"no independently verifiable"):
            recovery._validate_apply_authorization(receipt,"b"*64)

    def test_public_plan_projection_never_contains_private_evidence(self):
        internal={"schema":"plan.v1","workstream":recovery.WORKSTREAM,"run_id":recovery.RUN_ID,
                  "reviewed_main_baseline":"a"*40,"run_source_sha":"b"*40,"implementation_commit":"c"*40,
                  "branch_tip":"d"*40,"plan_sha256":"e"*64,"outcome":{"Outcome":"findings"},
                  "outcome":{"Outcome":"findings","Finding IDs":"R0-01"},
                  "run_manifest":{"private":"f"*64},"session":{"thread_id":"SECRET_THREAD_ID","command_failure_count":6,
                  "jsonl_sha256":"7"*64,"final_sha256":"8"*64,"stderr_sha256":"9"*64,"secret":"SECRET_SESSION_FIELD"},
                  "host":{"report_sha256":"1"*64,"private_path":"/private/host/path"},
                  "archive_sha256":"2"*64,"summary_sha256":"3"*64,"archive_text":"PRIVATE REVIEW TEXT",
                  "summary_text":"PRIVATE SUMMARY","target_sha256":"4"*64,
                  "checkout_inventory":{"entries":[["secret","file",0,"5"*64]],"ignored":["secret"]},
                  "protected_checkout_status":["private/path"],"process_owner_scan":{"owners":[],"private":True},
                  "integrity_report_sha256":"6"*64}
        rendered=json.dumps(recovery.public_plan_report(internal))
        for secret in ("PRIVATE REVIEW TEXT","PRIVATE SUMMARY","/private/host/path","secret","private/path","run_manifest","SECRET_THREAD_ID","SECRET_SESSION_FIELD"):
            self.assertNotIn(secret,rendered)
        self.assertFalse(recovery.public_plan_report(internal)["write_performed"])

    def test_canonical_findings_validator_rejects_duplicate_outcomes_and_forged_pass(self):
        canonical=__import__("custodian.tools.agent.review_outcome",fromlist=["render_review_outcome"])
        from custodian.tools.agent.test_paired_review_findings_closeout import Fixture, REVIEW_HEADER, FINDING, SUMMARY_TEXT
        with tempfile.TemporaryDirectory() as tmp:
            fx=Fixture(Path(tmp),sidecar=False)
            header=REVIEW_HEADER.format(status="complete")+FINDING
            kwargs={"review_workstream":"review-sample","target_workstream":"sample-impl",
                    "reviewed_main":fx.reviewed_main,"implementation_commit":fx.implementation,
                    "provenance":"different-agent","run_id":"20261016T000000Z-0123456789ab","review_cycle":0}
            finding=canonical.render_review_outcome(outcome="findings",ids=("R0-01",),**kwargs)
            archive=header+"\n"+finding
            call=lambda value: recovery.rr.nonpassing_review_reasons(
                value,SUMMARY_TEXT,fx.baseline,repo=fx.repo,workstream="review-sample",
                active_packet_path="custodian/docs/ai_context/task_packets/REVIEW_SAMPLE.md",
                target_workstream="sample-impl",target_packet_path="custodian/docs/ai_context/task_packets/archived/SAMPLE_IMPL.md",
                target_content=fx.baseline,authoring_chat="https://chatgpt.com/c/example",
                reviewed_main=fx.reviewed_main,run_id="20261016T000000Z-0123456789ab")
            self.assertEqual(call(archive),[])
            duplicate=call(archive+"\n"+finding)
            self.assertTrue(any("more than one Review Outcome section" in reason for reason in duplicate))
            forged=canonical.render_review_outcome(outcome="passed",ids=(),**kwargs)
            forged_reasons=call(header+"\n"+forged)
            self.assertTrue(any("findings or human_required" in reason for reason in forged_reasons))

    def test_inventory_binds_symlink_type_and_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "target").write_text("x")
            (root / "link").symlink_to("target")
            rows = recovery._tree(root)
            self.assertIn(["link", "symlink", 0o777, "target"], rows)
            self.assertEqual(next(row for row in rows if row[0] == "target")[1], "file")

    def _fake_proc(self, root, pid, comm="python", argv="worker", cgroup="/user.slice/user-1000.slice/user@1000.service/app.slice/worker.service"):
        entry=Path(root)/str(pid); entry.mkdir(parents=True)
        tail=["S"]+["0"]*18+["77"]
        (entry/"stat").write_text(f"{pid} ({comm}) "+" ".join(tail))
        (entry/"comm").write_text(comm+"\n"); (entry/"cgroup").write_text("0::"+cgroup+"\n")
        (entry/"cmdline").write_bytes(argv.encode()+b"\0")
        (entry/"cwd").symlink_to("/tmp")
        return entry

    def test_real_gpg_agent_is_authenticated_by_systemd_and_pid_start_identity(self):
        result=__import__("subprocess").run(["systemctl","--user","show","gpg-agent.service","-p","MainPID","-p","ActiveState"],capture_output=True,text=True)
        if result.returncode or "ActiveState=active" not in result.stdout:
            self.skipTest("user gpg-agent.service is unavailable")
        pid=int(next(line.split("=",1)[1] for line in result.stdout.splitlines() if line.startswith("MainPID=")))
        identity=recovery._verified_gpg_agent(pid)
        self.assertIsNotNone(identity)
        self.assertEqual(identity["classification"],"verified-systemd-credential-agent")
        self.assertTrue(identity["start_ticks"])

    def test_spoofed_gpg_agent_name_is_not_excluded(self):
        with tempfile.TemporaryDirectory() as tmp:
            entry=self._fake_proc(tmp,88001,comm="gpg-agent")
            self.assertIsNone(recovery._verified_gpg_agent(88001,proc_root=Path(tmp),service_lookup=lambda *_:None))

    def test_inaccessible_unrelated_process_remains_blocking(self):
        with tempfile.TemporaryDirectory() as tmp:
            entry=self._fake_proc(tmp,88002)
            original=os.readlink
            def unreadable(path,*args,**kwargs):
                if str(path).endswith("/cwd"): raise PermissionError("hidden cwd")
                return original(path,*args,**kwargs)
            with patch.object(recovery.os,"readlink",side_effect=unreadable):
                with self.assertRaisesRegex(ValueError,"cannot inspect same-user process 88002"):
                    recovery._review_process_owners(Path("/tmp/held-review"),recovery.WORKSTREAM,recovery.RUN_ID,proc_root=Path(tmp))

    def test_stale_pid_start_identity_and_missing_service_fail_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            self._fake_proc(tmp,88003,comm="gpg-agent",cgroup="/user.slice/user-1000.slice/user@1000.service/app.slice/gpg-agent.service")
            service={"pid":88003,"uid":os.getuid(),"control_group":"/user.slice/user-1000.slice/user@1000.service/app.slice/gpg-agent.service","service":"gpg-agent.service"}
            with patch.object(recovery,"_proc_identity",side_effect=["77","78"]):
                self.assertIsNone(recovery._verified_gpg_agent(88003,proc_root=Path(tmp),service_lookup=lambda *_:service))
            self.assertIsNone(recovery._verified_gpg_agent(88003,proc_root=Path(tmp),service_lookup=lambda *_:None))

    def test_actual_reviewer_owner_still_detected_even_with_gpg_agent_service_identity(self):
        with tempfile.TemporaryDirectory() as tmp:
            target=Path(tmp)/"protected"; target.mkdir()
            group="/user.slice/user-1000.slice/user@1000.service/app.slice/gpg-agent.service"
            entry=self._fake_proc(tmp,88004,comm="gpg-agent",argv=f"gpg-agent {target}",cgroup=group)
            service={"pid":88004,"uid":os.getuid(),"control_group":group,"service":"gpg-agent.service"}
            # Keep the process directory separate from the target directory.
            self.assertEqual(entry.name,"88004")
            owners=recovery._review_process_owners(target,recovery.WORKSTREAM,recovery.RUN_ID,proc_root=Path(tmp),service_lookup=lambda *_:service)
            self.assertEqual(owners["owners"],[{"pid":88004,"identity_command_match":True}])

    def test_synthetic_apply_is_digest_gated_and_retry_is_idempotent(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); source=root/"repo"; remote=root/"remote.git"; checkout=root/"recovery"
            subprocess.run(["git","init","--bare",str(remote)],check=True,capture_output=True)
            source.mkdir(); subprocess.run(["git","init","-b","main",str(source)],check=True,capture_output=True)
            def git(*args): return subprocess.run(["git",*args],cwd=source,check=True,capture_output=True,text=True).stdout.strip()
            git("config","user.name","Synthetic Test"); git("config","user.email","test@example.invalid")
            target=recovery.TARGET_PACKET; active=recovery.ACTIVE; archive=recovery.ARCHIVE; summary=recovery.SUMMARY
            for rel,content in ((target,"reviewed target bytes\n"),(active,"active review packet\n"),(f"{recovery.rr.PACKET_ROOT}/README.md","before\n<!-- task_packet_index:managed:start -->\nmanaged\n<!-- task_packet_index:managed:end -->\nafter\n"),("custodian/tools/agent/task_packet_index.py","#!/usr/bin/env python3\n")):
                path=source/rel; path.parent.mkdir(parents=True,exist_ok=True); path.write_text(content)
            git("add","-f","--",target,active,f"{recovery.rr.PACKET_ROOT}/README.md","custodian/tools/agent/task_packet_index.py"); git("commit","-m","fixture base"); base=git("rev-parse","HEAD")
            subprocess.run(["git","remote","add","origin",str(remote)],cwd=source,check=True,capture_output=True)
            subprocess.run(["git","push","-u","origin","main"],cwd=source,check=True,capture_output=True)
            common=Path(git("rev-parse","--git-common-dir")); common=common if common.is_absolute() else source/common
            allowed=sorted([active,archive,f"{recovery.rr.PACKET_ROOT}/README.md",summary])
            integrity={"schema":"custodian.validation.result.v1","passed":True,"outcome":"findings","finding_ids":["R0-01"],"integrity_only":True}
            integrity_raw=(json.dumps(integrity,indent=2,sort_keys=True)+"\n").encode()
            prepared={"plan_sha256":"a"*64,"current_main":base,"allowed_paths":allowed,"archive_text":"canonical findings archive\n","summary_text":"Authoring chat: "+recovery.CHAT+"\n## Next Handoff\n","archive_sha256":recovery.digest(b"canonical findings archive\n"),"summary_sha256":recovery.digest(("Authoring chat: "+recovery.CHAT+"\n## Next Handoff\n").encode()),"target_sha256":recovery.digest(b"reviewed target bytes\n"),"integrity_report":integrity,"integrity_report_sha256":recovery.digest(integrity_raw),"integrity_report_path":str(common/"custodian-review-runs"/recovery.WORKSTREAM/f"{recovery.RUN_ID}.findings-closeout-integrity.json")}
            with patch.object(recovery,"plan",return_value=prepared), patch.object(recovery.rr,"nonpassing_review_reasons",return_value=[]), patch.object(recovery.rr,"landed_nonpassing_review_state",return_value={"complete":True}), patch.object(recovery.rr,"_stage_bounded",side_effect=lambda repo,paths: _stage(repo,paths)):
                with self.assertRaisesRegex(ValueError,"no independently verifiable"):
                    recovery.apply(source,checkout,prepared,{})
                message=f"I authorize apply for {recovery.WORKSTREAM} run {recovery.RUN_ID} plan {prepared['plan_sha256']}. Keep outcome findings R0-01."
                auth={"schema":"custodian.chat_owner_approval.v1","source_url":recovery.CHAT,"approver":"project-owner","user_message":message,"user_message_sha256":hashlib.sha256(message.encode()).hexdigest(),"review_outcome":"findings","finding_ids":["R0-01"]}
                original_run=recovery.subprocess.run; failed_push=[False]
                def fail_once(args,*pos,**kw):
                    if args[:2]==["git","push"] and not failed_push[0]:
                        failed_push[0]=True
                        raise subprocess.CalledProcessError(1,args,stderr=b"synthetic interrupted publication")
                    return original_run(args,*pos,**kw)
                with patch.object(recovery,"_validate_apply_authorization",return_value=True):
                    with patch.object(recovery.subprocess,"run",side_effect=fail_once):
                        with self.assertRaises(subprocess.CalledProcessError): recovery.apply(source,checkout,prepared,auth)
                    first=recovery.apply(source,checkout,prepared,auth)
                    second=recovery.apply(source,checkout,prepared,auth)
            self.assertEqual(first["commit"],second["commit"])
            self.assertEqual(first["status"],"published_findings_closeout_waiting_for_landing")
            self.assertFalse((checkout/active).exists())
            self.assertTrue((checkout/archive).is_file())
            self.assertTrue((checkout/summary).is_file())
            self.assertEqual(Path(prepared["integrity_report_path"]).read_bytes(),integrity_raw)
            remote_sha=subprocess.run(["git","ls-remote","--heads","origin",f"refs/heads/{first['branch']}"],cwd=source,check=True,capture_output=True,text=True).stdout.split()[0]
            self.assertEqual(remote_sha,first["commit"])

    def test_generic_parser_is_not_invoked_or_relaxed(self):
        # The dedicated verifier owns this one run; global parser behavior remains strict.
        import inspect
        src = inspect.getsource(recovery._parse_session)
        self.assertNotIn("_parse_redacted_final_session", src)
        runner_src = inspect.getsource(recovery.rr._parse_redacted_final_session)
        self.assertIn("if stderr.strip()", runner_src)

if __name__ == "__main__": unittest.main()
