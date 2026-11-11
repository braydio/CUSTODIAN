from __future__ import annotations

import os
import hashlib
import subprocess
import sys
import tempfile
import unittest
import json
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
WORKER_TOOLS = ROOT / "tools" / "worker"
sys.path.insert(0, str(WORKER_TOOLS))
import worker_launcher  # noqa: E402
import validate_worker_isolation  # noqa: E402
import provision_worker_isolation  # noqa: E402

PROVISIONER = WORKER_TOOLS / "provision_worker_isolation.py"


class LauncherTests(unittest.TestCase):
    def test_only_fixed_proof_instance_is_accepted(self) -> None:
        self.assertTrue(worker_launcher.valid_instance("proof"))
        for value in ("", "agent", "../proof", "proof;sh", "proof.service"):
            with self.subTest(value=value):
                self.assertFalse(worker_launcher.valid_instance(value))

    def test_environment_is_fixed_and_drops_host_values(self) -> None:
        with patch.dict(os.environ, {"GITHUB_TOKEN": "must-not-pass", "SSH_AUTH_SOCK": "/tmp/agent.sock",
                                    "OPENAI_API_KEY": "must-not-pass", "PATH": "/host/bin"}, clear=True):
            env = worker_launcher.worker_environment()
        self.assertEqual(env, worker_launcher.WORKER_ENV)
        self.assertNotIn("GITHUB_TOKEN", env)
        self.assertNotIn("SSH_AUTH_SOCK", env)
        self.assertNotIn("OPENAI_API_KEY", env)
        self.assertEqual(env["GIT_CONFIG_GLOBAL"], "/dev/null")
        self.assertEqual(env["GIT_TERMINAL_PROMPT"], "0")

    def test_credential_directory_pointer_is_the_only_forwarded_secret_context(self) -> None:
        with tempfile.TemporaryDirectory() as credentials_directory:
            env = worker_launcher.worker_environment(credentials_directory)
        self.assertEqual(env["CREDENTIALS_DIRECTORY"], credentials_directory)
        self.assertNotIn("OPENAI_API_KEY", env)

    def test_invalid_instance_fails_before_identity_or_exec(self) -> None:
        self.assertEqual(worker_launcher.main(["other"]), 64)

    def test_valid_launch_execs_only_the_validator_with_sanitized_environment(self) -> None:
        exec_calls = []
        with patch.dict(os.environ, {}, clear=True), \
             patch.object(worker_launcher.os, "geteuid", return_value=987), \
             patch.object(worker_launcher.pwd, "getpwuid", return_value=SimpleNamespace(pw_name="custodian-worker")), \
             patch.object(worker_launcher.Path, "is_file", return_value=True), \
             patch.object(worker_launcher, "isolation_preflight", return_value=(True, {"pass": True})), \
             patch.object(worker_launcher.os, "execve", side_effect=lambda *args: exec_calls.append(args)):
            code = worker_launcher.main(["proof"])
        self.assertEqual(code, 127)
        self.assertEqual(len(exec_calls), 1)
        path, argv, env = exec_calls[0]
        self.assertEqual(path, worker_launcher.VALIDATOR)
        self.assertEqual(argv, [worker_launcher.VALIDATOR, "--inside-worker"])
        self.assertEqual(env, worker_launcher.WORKER_ENV)

    def test_missing_systemd_credential_directory_fails_model_mode_before_validator(self) -> None:
        with patch.dict(os.environ, {}, clear=True), \
             patch.object(worker_launcher.os, "geteuid", return_value=987), \
             patch.object(worker_launcher.pwd, "getpwuid", return_value=SimpleNamespace(pw_name="custodian-worker")), \
             patch.object(worker_launcher.Path, "is_file", return_value=True), \
             patch.object(worker_launcher, "isolation_preflight", return_value=(True, {"pass": True, "model_only": True})), \
             patch.object(worker_launcher.os, "execve") as execve:
            self.assertEqual(worker_launcher.main(["proof"]), 78)
        execve.assert_not_called()

    def test_non_model_modes_run_without_systemd_credentials(self) -> None:
        for preflight in ({"pass": True}, {"pass": True, "lfs_only": True}):
            with self.subTest(preflight=preflight):
                exec_calls = []
                with patch.dict(os.environ, {}, clear=True), \
                     patch.object(worker_launcher.os, "geteuid", return_value=987), \
                     patch.object(worker_launcher.pwd, "getpwuid", return_value=SimpleNamespace(pw_name="custodian-worker")), \
                     patch.object(worker_launcher.Path, "is_file", return_value=True), \
                     patch.object(worker_launcher, "isolation_preflight", return_value=(True, preflight)), \
                     patch.object(worker_launcher.os, "execve", side_effect=lambda *args: exec_calls.append(args)):
                    self.assertEqual(worker_launcher.main(["proof"]), 127)
                self.assertEqual(exec_calls[0][2], worker_launcher.WORKER_ENV)
                expected = "--inside-lfs" if preflight.get("lfs_only") else "--inside-worker"
                self.assertEqual(exec_calls[0][1], [worker_launcher.VALIDATOR, expected])

    def test_explicit_model_mode_selects_only_the_model_probe(self) -> None:
        exec_calls = []
        with tempfile.TemporaryDirectory() as credentials_directory, \
             patch.dict(os.environ, {"CREDENTIALS_DIRECTORY": credentials_directory}, clear=True), \
             patch.object(worker_launcher.os, "geteuid", return_value=987), \
             patch.object(worker_launcher.pwd, "getpwuid", return_value=SimpleNamespace(pw_name="custodian-worker")), \
             patch.object(worker_launcher.Path, "is_file", return_value=True), \
             patch.object(worker_launcher, "isolation_preflight", return_value=(True, {"pass": True, "model_only": True})), \
             patch.object(worker_launcher.os, "execve", side_effect=lambda *args: exec_calls.append(args)):
            self.assertEqual(worker_launcher.main(["proof"]), 127)
        self.assertEqual(exec_calls[0][1], [worker_launcher.VALIDATOR, "--inside-model"])

    def test_failed_preflight_refuses_to_launch_validator(self) -> None:
        with patch.object(worker_launcher.os, "geteuid", return_value=987), \
             patch.object(worker_launcher.pwd, "getpwuid", return_value=SimpleNamespace(pw_name="custodian-worker")), \
             patch.object(worker_launcher.Path, "is_file", return_value=True), \
             patch.object(worker_launcher, "isolation_preflight", return_value=(False, {"pass": False})), \
             patch.object(worker_launcher.os, "execve") as execve:
            self.assertEqual(worker_launcher.main(["proof"]), 79)
        execve.assert_not_called()


class EvidenceValidationTests(unittest.TestCase):
    def test_complete_proof_record_is_returned_after_preflight(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            run_id = "0123456789abcdef"
            preflight = {"pass": True, "probes": [{"name": "chrome_cdp_ipv4_9223", "blocked": True, "errno": "ETIMEDOUT"}]}
            (Path(tmp) / f"isolation-preflight-{run_id}.json").write_text(json.dumps(preflight))
            config = {"run_id": run_id}
            original_read_text = Path.read_text

            def read_text(path: Path, *args, **kwargs):
                if str(path) == "/proc/self/cgroup":
                    return "0::/system.slice/system-custodian-worker.slice/custodian-worker@proof.service\n"
                return original_read_text(path, *args, **kwargs)

            with patch.dict(os.environ, {"TMPDIR": tmp, "HOME": "/worker/home", "CODEX_HOME": "/worker/codex"}, clear=True), \
                 patch.object(validate_worker_isolation, "read_probe_config", return_value=config), \
                 patch.object(validate_worker_isolation.os, "geteuid", return_value=942), \
                 patch.object(validate_worker_isolation.os, "getegid", return_value=942), \
                 patch.object(validate_worker_isolation.os, "getgroups", return_value=[]), \
                 patch.object(validate_worker_isolation.pwd, "getpwuid", return_value=SimpleNamespace(pw_name="custodian-worker")), \
                 patch.object(validate_worker_isolation.grp, "getgrgid", return_value=SimpleNamespace(gr_name="custodian-worker")), \
                 patch.object(validate_worker_isolation.Path, "read_text", read_text), \
                 patch.object(validate_worker_isolation, "path_denial", return_value={"denied": True}), \
                 patch.object(validate_worker_isolation, "public_https_probe", return_value={
                     "pass": True, "phases": {"dns": {"pass": True, "answer_count": 1},
                                               "http": {"pass": True, "status": 200},
                                               "tcp": {"pass": True}, "tls": {"pass": True}},
                     "total_duration_seconds": 0.01}), \
                 patch.object(validate_worker_isolation.shutil, "which", return_value=None):
                result = validate_worker_isolation.inside_proof()
        self.assertEqual(result["schema"], "custodian.worker_isolation_proof.v1")
        self.assertTrue(result["identity"]["pass"])
        self.assertTrue(result["loopback"]["pass"])
        self.assertTrue(result["protected_interfaces"]["pass"])
        self.assertTrue(result["network"]["https_github"]["pass"])

    def test_public_network_dns_timeout_is_bounded_and_not_a_pass(self) -> None:
        with patch.object(validate_worker_isolation, "run", return_value=(124, "", "timeout")):
            result = validate_worker_isolation.public_https_probe("github.com")
        self.assertFalse(result["pass"])
        self.assertEqual(result["disposition"], "network_timeout")
        self.assertEqual(result["phases"]["dns"]["pass"], False)
        self.assertEqual(result["total_timeout_seconds"], 23)

    def test_probe_config_is_bound_to_only_expected_loopback_targets(self) -> None:
        valid = {
            "schema": "custodian.worker_probe_config.v1",
            "run_id": "0123456789abcdef",
            "targets": [
                {"name": "chrome_cdp_ipv4_9223", "host": "127.0.0.1", "port": 9223},
                {"name": "other_ipv4_loopback", "host": "127.0.0.2", "port": 43210},
                {"name": "ipv6_loopback", "host": "::1", "port": 43211},
                {"name": "lan_ipv4_0", "host": "192.168.1.237", "port": 43212},
            ],
        }
        self.assertTrue(validate_worker_isolation.valid_probe_config(valid))
        model_only = {**valid, "model_only": True}
        self.assertTrue(validate_worker_isolation.valid_probe_config(model_only))
        self.assertFalse(validate_worker_isolation.valid_probe_config({**model_only, "lfs_only": True}))
        self.assertFalse(validate_worker_isolation.valid_probe_config({**valid, "model_only": "true"}))
        hostile = {**valid, "targets": [
            *valid["targets"][:2],
            {"name": "ipv6_loopback", "host": "169.254.169.254", "port": 43211},
            valid["targets"][3],
        ]}
        self.assertFalse(validate_worker_isolation.valid_probe_config(hostile))

    def test_lfs_failure_classification_keeps_timeout_distinct(self) -> None:
        classify = validate_worker_isolation.classify_lfs_failure
        self.assertEqual(classify(124, "timeout"), "network_timeout")
        self.assertEqual(classify(1, "HTTP 401 authentication required"), "authentication_required")
        self.assertEqual(classify(1, "HTTP 403 forbidden"), "authorization_denied")
        self.assertEqual(classify(1, "TLS connection reset"), "transport_failure")
        self.assertEqual(classify(1, "invalid LFS batch response"), "lfs_protocol_or_object_failure")

    def test_lfs_pointer_hash_and_size_are_parsed(self) -> None:
        oid = "a" * 64
        pointer = f"version https://git-lfs.github.com/spec/v1\noid sha256:{oid}\nsize 4912\n"
        self.assertEqual(validate_worker_isolation.parse_lfs_pointer(pointer), (oid, 4912))
        self.assertIsNone(validate_worker_isolation.parse_lfs_pointer("not an LFS pointer\n"))

    def test_lfs_batch_and_download_keep_action_secrets_out_of_report(self) -> None:
        payload = b"verified public LFS payload"
        oid = hashlib.sha256(payload).hexdigest()
        signed_url = "https://github-cloud.githubusercontent.com/object/path?X-Amz-Signature=private-signature"
        action_header = "private-action-header"
        batch = json.dumps({"objects": [{"oid": oid, "size": len(payload), "actions": {
            "download": {"href": signed_url, "header": {"Authorization": action_header}}
        }}]}).encode()
        calls = []

        def request(host, target, method, headers, body=None, *, max_response_bytes=1_000_000):
            calls.append((host, target, method, dict(headers), body))
            phases = {name: {"pass": True, "duration_seconds": 0.01} for name in ("dns", "tcp", "tls", "http")}
            phases["http"].update({"status": 200, "response_bytes": len(batch if method == "POST" else payload),
                                   "response_too_large": False})
            result = {"pass": True, "phase": "complete", "phases": phases, "total_duration_seconds": 0.04}
            return result, batch if method == "POST" else payload

        with patch.object(validate_worker_isolation, "LFS_OBJECT_OID", oid), \
             patch.object(validate_worker_isolation, "LFS_OBJECT_SIZE", len(payload)), \
             patch.object(validate_worker_isolation, "_pinned_https_request", side_effect=request):
            result = validate_worker_isolation.fetch_one_public_lfs_object()

        self.assertEqual(result["exit_code"], 0)
        self.assertEqual(result["sha256"], oid)
        self.assertEqual(result["size"], len(payload))
        self.assertEqual(len(calls), 2)
        self.assertEqual(calls[0][0], "github.com")
        self.assertEqual(calls[0][2], "POST")
        self.assertNotIn("Authorization", calls[0][3])
        self.assertEqual(calls[1][0], "github-cloud.githubusercontent.com")
        self.assertEqual(calls[1][2], "GET")
        report = json.dumps(result)
        self.assertNotIn(signed_url, report)
        self.assertNotIn("X-Amz-Signature", report)
        self.assertNotIn(action_header, report)

    def test_lfs_batch_rejects_unapproved_action_host_without_leaking_href(self) -> None:
        signed_url = "https://unexpected.example/object?token=private-token"
        batch = json.dumps({"objects": [{"oid": validate_worker_isolation.LFS_OBJECT_OID,
                                          "size": validate_worker_isolation.LFS_OBJECT_SIZE,
                                          "actions": {"download": {"href": signed_url}}}]}).encode()
        phases = {name: {"pass": True, "duration_seconds": 0.01} for name in ("dns", "tcp", "tls", "http")}
        phases["http"].update({"status": 200, "response_bytes": len(batch), "response_too_large": False})
        with patch.object(validate_worker_isolation, "_pinned_https_request", return_value=(
                {"pass": True, "phase": "complete", "phases": phases, "total_duration_seconds": 0.04}, batch)) as request:
            result = validate_worker_isolation.fetch_one_public_lfs_object()
        self.assertEqual(result["phase"], "download_action_host")
        self.assertEqual(request.call_count, 1)
        self.assertNotIn(signed_url, json.dumps(result))
        self.assertNotIn("private-token", json.dumps(result))


class ModelCredentialTests(unittest.TestCase):
    SYNTHETIC_KEY = "synthetic-not-a-real-api-key"

    def make_credential(self, directory: Path, value: bytes, mode: int = 0o400) -> Path:
        directory.mkdir(parents=True, exist_ok=True)
        credential = directory / validate_worker_isolation.CREDENTIAL_NAME
        credential.write_bytes(value)
        credential.chmod(mode)
        return credential

    def test_runtime_credential_rejects_missing_empty_malformed_and_wrong_modes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            with patch.dict(os.environ, {"CREDENTIALS_DIRECTORY": str(root)}, clear=True):
                self.assertEqual(validate_worker_isolation._read_runtime_model_credential(), ("missing", None))
                credential = self.make_credential(root, b"")
                self.assertEqual(validate_worker_isolation._read_runtime_model_credential(), ("invalid", None))
                credential.chmod(0o600)
                credential.write_bytes(b"not-a-key")
                credential.chmod(0o400)
                self.assertEqual(validate_worker_isolation._read_runtime_model_credential(), ("invalid", None))
                credential.chmod(0o600)
                credential.write_text(self.SYNTHETIC_KEY)
                self.assertEqual(validate_worker_isolation._read_runtime_model_credential(), ("invalid", None))
                credential.write_text("sk-svcacct-" + "x" * 32)
                credential.chmod(0o400)
                with patch.object(validate_worker_isolation.os, "geteuid", return_value=os.geteuid() + 1):
                    self.assertEqual(validate_worker_isolation._read_runtime_model_credential(), ("invalid", None))
                credential.unlink()
                credential.symlink_to(root / "missing-target")
                self.assertEqual(validate_worker_isolation._read_runtime_model_credential(), ("invalid", None))

    def test_model_probe_does_not_launch_without_credential(self) -> None:
        with tempfile.TemporaryDirectory() as tmp, \
             patch.dict(os.environ, {"CREDENTIALS_DIRECTORY": tmp}, clear=True), \
             patch.object(validate_worker_isolation.subprocess, "run") as run_codex:
            result = validate_worker_isolation.codex_model_probe()
        self.assertEqual(result["disposition"], "credential_missing")
        self.assertFalse(result["attempted"])
        run_codex.assert_not_called()

    def test_response_verification_accepts_only_the_completed_agent_message(self) -> None:
        event = json.dumps({"type": "item.completed", "item": {
            "type": "agent_message", "text": validate_worker_isolation.MODEL_OK_MARKER}})
        self.assertTrue(validate_worker_isolation._model_response_has_marker(event))
        self.assertFalse(validate_worker_isolation._model_response_has_marker(
            json.dumps({"type": "turn.started", "prompt": validate_worker_isolation.MODEL_OK_MARKER})))

    def test_codex_key_wiring_is_limited_to_child_environment(self) -> None:
        import inspect
        source = inspect.getsource(validate_worker_isolation.codex_model_probe)
        self.assertIn('child_env["OPENAI_API_KEY"] = model_credential', source)
        self.assertIn("env=child_env", source)
        self.assertIn('"--config", \'shell_environment_policy.inherit="none"\'', source)
        self.assertNotIn("print(api_key)", source)

    def test_model_probe_refuses_inherited_owner_credential(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            self.make_credential(Path(tmp), self.SYNTHETIC_KEY.encode("ascii"))
            with patch.dict(os.environ, {
                    "CREDENTIALS_DIRECTORY": tmp, "OPENAI_API_KEY": self.SYNTHETIC_KEY}, clear=True), \
                 patch.object(validate_worker_isolation.subprocess, "run") as run_codex:
                result = validate_worker_isolation.codex_model_probe()
        self.assertEqual(result["disposition"], "inherited_credentials_present")
        self.assertFalse(result["inherited_owner_credentials_absent"])
        self.assertNotIn(self.SYNTHETIC_KEY, json.dumps(result))
        run_codex.assert_not_called()

    def test_lfs_download_action_cannot_override_host_or_connection_headers(self) -> None:
        for name in ("Host", "Connection", "Content-Length", "Transfer-Encoding"):
            with self.subTest(name=name):
                result, body = validate_worker_isolation._pinned_https_request(
                    "github-cloud.githubusercontent.com", "/object", "GET", {name: "attacker-value"})
                self.assertFalse(result["pass"])
                self.assertEqual(result["phase"], "request_validation")
                self.assertEqual(result["phases"], {})
                self.assertEqual(body, b"")


class ProvisionerTests(unittest.TestCase):
    def run_provisioner(self, root: Path, action: str, *extra: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run([sys.executable, str(PROVISIONER), action, "--root-dir", str(root), *extra],
                              text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)

    def test_install_is_repeatable_and_remove_is_bounded(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            first = self.run_provisioner(root, "install")
            self.assertEqual(first.returncode, 0, first.stderr)
            unit = root / "etc/systemd/system/custodian-worker@.service"
            launcher = root / "usr/local/libexec/custodian-worker/custodian-worker-launch"
            resolver = root / "etc/custodian-worker/resolv.conf"
            credential_directory = root / "etc/credstore.encrypted"
            credential = credential_directory / "custodian-worker-openai-api-key"
            self.assertTrue(unit.is_file())
            self.assertTrue(launcher.is_file())
            self.assertTrue(resolver.is_file())
            self.assertTrue(credential_directory.is_dir())
            self.assertEqual(credential_directory.stat().st_mode & 0o777, 0o700)
            self.assertFalse(credential.exists())
            unit_text = unit.read_text()
            self.assertIn("LoadCredentialEncrypted=custodian-worker-openai-api-key", unit_text)
            self.assertIn("InaccessiblePaths=-/home -/root -/etc/codex", unit_text)
            second = self.run_provisioner(root, "install")
            self.assertEqual(second.returncode, 0, second.stderr)
            credential.write_text("encrypted-test-fixture")
            credential.chmod(0o600)
            removed = self.run_provisioner(root, "remove", "--remove-state")
            self.assertEqual(removed.returncode, 0, removed.stderr)
            self.assertFalse(unit.exists())
            self.assertFalse(launcher.exists())
            self.assertFalse(resolver.exists())
            self.assertFalse((root / "var/lib/custodian-worker").exists())
            self.assertEqual(credential.read_text(), "encrypted-test-fixture")

    def test_install_refuses_an_incorrectly_permissioned_admin_credential(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.assertEqual(self.run_provisioner(root, "install").returncode, 0)
            credential = root / "etc/credstore.encrypted/custodian-worker-openai-api-key"
            credential.write_text("encrypted-test-fixture")
            credential.chmod(0o644)
            result = self.run_provisioner(root, "install")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("owner-only 0600", result.stderr)

    def test_install_preserves_secure_credential_store_modes(self) -> None:
        for mode in (0o700, 0o755):
            with self.subTest(mode=oct(mode)), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                store = root / "etc/credstore.encrypted"
                store.mkdir(parents=True)
                store.chmod(mode)
                result = self.run_provisioner(root, "install")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(store.stat().st_mode & 0o777, mode)

    def test_install_refuses_insecure_or_symlink_credential_store(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            store = root / "etc/credstore.encrypted"
            store.mkdir(parents=True)
            store.chmod(0o775)
            result = self.run_provisioner(root, "install")
            self.assertNotEqual(result.returncode, 0)
            self.assertTrue(store.is_dir())
            self.assertEqual(store.stat().st_mode & 0o777, 0o775)
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            target = root / "secure-store"
            target.mkdir()
            (root / "etc").mkdir()
            (root / "etc/credstore.encrypted").symlink_to(target, target_is_directory=True)
            result = self.run_provisioner(root, "install")
            self.assertNotEqual(result.returncode, 0)
            self.assertTrue((root / "etc/credstore.encrypted").is_symlink())

    def test_install_refuses_to_overwrite_conflicting_unit(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            unit = root / "etc/systemd/system/custodian-worker@.service"
            unit.parent.mkdir(parents=True)
            unit.write_text("operator-owned unit\n")
            result = self.run_provisioner(root, "install")
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(unit.read_text(), "operator-owned unit\n")

    def test_remove_preflights_unknown_state_before_removing_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.assertEqual(self.run_provisioner(root, "install").returncode, 0)
            state = root / "var/lib/custodian-worker"
            (state / "unexpected").write_text("preserve\n")
            unit = root / "etc/systemd/system/custodian-worker@.service"
            contents = unit.read_bytes()
            result = self.run_provisioner(root, "remove", "--remove-state")
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(unit.read_bytes(), contents)
            self.assertEqual((state / "unexpected").read_text(), "preserve\n")

    def make_upgrade_fixture(self, root: Path) -> tuple[Path, Path, Path]:
        repo = root / "repo"
        installed = root / "installed"
        source = repo / "tools/worker/validator.py"
        destination = installed / "usr/local/libexec/custodian-worker/validator.py"
        source.parent.mkdir(parents=True)
        destination.parent.mkdir(parents=True)
        resolver = installed / "etc/custodian-worker/resolv.conf"
        resolver.parent.mkdir(parents=True)
        source.write_text("old validator\n")
        destination.write_text("old validator\n")
        destination.chmod(0o644)
        resolver.write_text(provision_worker_isolation.RESOLVERS)
        resolver.chmod(0o644)
        subprocess.run(["git", "init", "-q", str(repo)], check=True)
        subprocess.run(["git", "-C", str(repo), "config", "user.name", "Worker Test"], check=True)
        subprocess.run(["git", "-C", str(repo), "config", "user.email", "worker-test@example.invalid"], check=True)
        subprocess.run(["git", "-C", str(repo), "add", "tools/worker/validator.py"], check=True)
        subprocess.run(["git", "-C", str(repo), "commit", "-qm", "baseline"], check=True)
        source.write_text("new validator\n")
        return repo, installed, destination

    def test_upgrade_replaces_only_files_matching_explicit_baseline(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo, root, destination = self.make_upgrade_fixture(Path(tmp))
            with patch.object(provision_worker_isolation, "FILES", ((
                    Path("tools/worker/validator.py"),
                    Path("/usr/local/libexec/custodian-worker/validator.py"), 0o644),)):
                provision_worker_isolation.upgrade(repo, root, "HEAD")
            self.assertEqual(destination.read_text(), "new validator\n")
            credentials = root / "etc/credstore.encrypted"
            self.assertTrue(credentials.is_dir())
            self.assertEqual(credentials.stat().st_mode & 0o777, 0o700)

    def test_upgrade_refuses_modified_installed_file_without_overwriting_it(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo, root, destination = self.make_upgrade_fixture(Path(tmp))
            destination.write_text("unknown local version\n")
            with patch.object(provision_worker_isolation, "FILES", ((
                    Path("tools/worker/validator.py"),
                    Path("/usr/local/libexec/custodian-worker/validator.py"), 0o644),)):
                with self.assertRaises(provision_worker_isolation.ProvisionError):
                    provision_worker_isolation.upgrade(repo, root, "HEAD")
            self.assertEqual(destination.read_text(), "unknown local version\n")

    def test_upgrade_accepts_only_exact_explicit_installed_hash_override(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo, root, destination = self.make_upgrade_fixture(Path(tmp))
            relative = "tools/worker/validator.py"
            expected = hashlib.sha256(b"old validator\n").hexdigest()
            with patch.object(provision_worker_isolation, "FILES", ((
                    Path(relative), Path("/usr/local/libexec/custodian-worker/validator.py"), 0o644),)):
                provision_worker_isolation.upgrade(repo, root, "HEAD", {relative: expected})
                destination.write_text("unexpected replacement\n")
                with self.assertRaises(provision_worker_isolation.ProvisionError):
                    provision_worker_isolation.upgrade(repo, root, "HEAD", {relative: expected})
            self.assertEqual(destination.read_text(), "unexpected replacement\n")


if __name__ == "__main__":
    unittest.main(verbosity=2)
