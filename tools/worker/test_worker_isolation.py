from __future__ import annotations

import os
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

    def test_invalid_instance_fails_before_identity_or_exec(self) -> None:
        self.assertEqual(worker_launcher.main(["other"]), 64)

    def test_valid_launch_execs_only_the_validator_with_sanitized_environment(self) -> None:
        exec_calls = []
        with patch.object(worker_launcher.os, "geteuid", return_value=987), \
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
            self.assertTrue(unit.is_file())
            self.assertTrue(launcher.is_file())
            self.assertTrue(resolver.is_file())
            second = self.run_provisioner(root, "install")
            self.assertEqual(second.returncode, 0, second.stderr)
            removed = self.run_provisioner(root, "remove", "--remove-state")
            self.assertEqual(removed.returncode, 0, removed.stderr)
            self.assertFalse(unit.exists())
            self.assertFalse(launcher.exists())
            self.assertFalse(resolver.exists())
            self.assertFalse((root / "var/lib/custodian-worker").exists())

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


if __name__ == "__main__":
    unittest.main(verbosity=2)
