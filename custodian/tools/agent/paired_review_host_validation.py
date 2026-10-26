"""Coordinator-side validation evidence for restricted paired-review sessions."""
from __future__ import annotations

import hashlib
import json
import os
import re
import socket
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Callable

from godot_project_lock import godot_home
import review_outcome
from review_receipt_delta import read_git_text, resolve_target_implementation_commit, verify_review_receipt_delta
from task_packet_contract import PACKET_ROOT, header_field, parse_packet
from task_packet_index import MANAGED_BLOCK_END, MANAGED_BLOCK_START


class HostValidationError(RuntimeError):
    pass


_IMPLEMENTATION_SUFFIXES = {".gd", ".py", ".gdshader", ".tscn", ".tres", ".json"}
FAILED_IMPORT_RECOVERY_WORKSTREAM = (
    "review-agent-paired-review-missing-archived-disposition-continuation-v1"
)
FAILED_IMPORT_RECOVERY_RUN_ID = "20261020T165418Z-53992bd05f83"
FAILED_IMPORT_RECOVERY_SIDECARS = frozenset(
    f"custodian/tools/iteration/grunt_candidate_ab/generated/candidate_{direction}_{size}px.png.import"
    for direction in ("s", "n", "e", "w") for size in (64, 72, 80)
)
_REPOSITORY_MARKDOWN_PATH_RE = re.compile(
    r"(?<![A-Za-z0-9_./-])((?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+\.md)(?![A-Za-z0-9_./-])"
)
_WORK_SURFACE_BRACE_PATH_RE = re.compile(
    r"custodian/([A-Za-z0-9_-]+(?:/[A-Za-z0-9_-]+)*)/"
    r"\{([A-Za-z_][A-Za-z0-9_]*(?:,[A-Za-z_][A-Za-z0-9_]*)+)\}"
    r"(\.[A-Za-z0-9]+)"
)

_GRUNT_SCOPE_ATTESTATION_PATH = (
    "custodian/docs/ai_context/review_scope_attestations/grunt_candidate_raster_v1.json"
)
_GRUNT_SCOPE_SOURCE_WORKSTREAM = "grunt-candidate-raster-workflow-v1"
_GRUNT_SCOPE_SOURCE_ARCHIVE = "e29847bb2dc409ad994ac59ee3e8bb4db637142e"
_GRUNT_SCOPE_SOURCE_PACKET = (
    f"{PACKET_ROOT}/archived/GRUNT_CANDIDATE_RASTER_WORKFLOW_V1.md"
)
_GRUNT_SCOPE_SOURCE_PACKET_BLOB = "73dc311261f396b1636d117730fdffb18be9965e"
_GRUNT_SCOPE_CORRECTION_WORKSTREAM = "agent-grunt-raster-review-scope-attestation-v1"
_GRUNT_SCOPE_CORRECTION_PACKET = (
    f"{PACKET_ROOT}/archived/AGENT_GRUNT_RASTER_REVIEW_SCOPE_ATTESTATION_V1.md"
)
_GRUNT_SCOPE_REVIEW_WORKSTREAM = "review-agent-grunt-raster-review-scope-attestation-v1"
_GRUNT_SCOPE_REVIEW_PACKET = (
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_GRUNT_RASTER_REVIEW_SCOPE_ATTESTATION_V1.md"
)
_GRUNT_SCOPE_MARKDOWN_FILES = {
    "custodian/docs/ai_context/CURRENT_STATE.md": "1a9368fa1d293570c968fd486972d69f73a1a687",
    "custodian/docs/ai_context/FILE_INDEX.md": "4a7f88cc00689dd55ab080230e2c43b58cf6e0c5",
    "custodian/tools/iteration/raster_pipeline/README.md": "364f0b366c6c7f25d893ca3957c05238278c0fb7",
}
_GRUNT_SCOPE_CODE_FILES = {
    "custodian/tools/iteration/raster_pipeline/__init__.py": "bd5b6ae6d224c86909372b1710d51efe7c3a289a",
    "custodian/tools/iteration/grunt_candidate_ab/grunt_raster_plan.json": "4e2ecb1b333c1d95d5b3b468dbcd9b7b7162a9ae",
    "custodian/tools/validation/validation_manifest.json": "f99d1deec38aac1757838bd52bee102740597808",
}
_GRUNT_SCOPE_FILES = {**_GRUNT_SCOPE_MARKDOWN_FILES, **_GRUNT_SCOPE_CODE_FILES}

_PROCESSION_SCOPE_ATTESTATION_PATH = (
    "custodian/docs/ai_context/review_scope_attestations/road_procession_p1_source_scope_v1.json"
)
_PROCESSION_SCOPE_SOURCE_WORKSTREAM = "hub-road-empty-procession-sequence-v1"
_PROCESSION_SCOPE_SOURCE_ARCHIVE = "68cef17f59c6d5e04026b56025451b901bd08185"
_PROCESSION_SCOPE_SOURCE_PACKET = (
    f"{PACKET_ROOT}/archived/HUB_ROAD_EMPTY_PROCESSION_SEQUENCE_V1.md"
)
_PROCESSION_SCOPE_SOURCE_PACKET_BLOB = "9ad75ac27b88508647b6257245242272f49b21aa"
_PROCESSION_SCOPE_SOURCE_FILES = {
    "custodian/docs/ai_context/VALIDATION_RECIPES.md": "bf1595c7a554bd307e9c77f241fe94817affe58a",
    "custodian/game/state/persistent/hub_state.gd": "08216a9df060f0dd8ae703f597c66cc4df9ba4e0",
    "custodian/game/world/hub/events/road_procession/road_procession_sequence.gd": "5de12336e853024f1e252e7d0dc552e17f36cda7",
    "custodian/game/world/hub/events/road_procession/road_procession_sequence.gd.uid": "67b4d9d44729a7d828a8061798c7f0f99e9d7a7b",
    "custodian/game/world/hub/first_set/hub_first_set_map.gd": "338c21b43c2768aca5e3b248393aac90b8f6e1c9",
    "custodian/tools/validation/hub_road_empty_procession_smoke.gd": "8a1a77c1c29431672990781b926d28e6f3e67c09",
    "custodian/tools/validation/hub_road_empty_procession_smoke.gd.uid": "e72ccbfef55f557c7b0e050efda20f27e5ea92fb",
    "custodian/tools/validation/validation_manifest.json": "016101bf9e76309b1991e3e45fb6f15104c1c94a",
}
_PROCESSION_SCOPE_CORRECTION_WORKSTREAM = "agent-paired-review-procession-doc-scope-recovery-v1"
_PROCESSION_SCOPE_CORRECTION_PACKET = (
    f"{PACKET_ROOT}/archived/AGENT_PAIRED_REVIEW_PROCESSION_DOC_SCOPE_RECOVERY_V1.md"
)
_PROCESSION_SCOPE_REVIEW_WORKSTREAM = "review-agent-paired-review-procession-doc-scope-recovery-v1"
_PROCESSION_SCOPE_REVIEW_PACKET = (
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_PROCESSION_DOC_SCOPE_RECOVERY_V1.md"
)

# Exact historical source-scope exceptions authorize PRELAUNCH only.
# Neither historical case changes the mandatory independent review outcome.
_PROCESSION_RECOVERY_ARCHIVE = "c0f9d325e75cdb121489898f9f34a5f5c47f3196"
_PROCESSION_RECOVERY_PARENT = "49a93aa726e26bd40220d3bdb658079ea9da3440"
_PROCESSION_RECOVERY_TREE = "39230667c764b62213fcf07527cccb810d5e14d5"
_PROCESSION_RECOVERY_ACTIVE_BLOB = "0dd7ef934ce0cc3ae37fc5493678f80a54df3c67"
_PROCESSION_RECOVERY_PACKET_BLOB = "73e6e864d5212289d46e1eb88a48fd040435ee95"
_PROCESSION_RECOVERY_UNDECLARED_FILES = {
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_PROCESSION_DOC_SCOPE_RECOVERY_V1.md":
        "8e37fe7ce02fa4948e05034dbcb49e02401007a0",
    "custodian/docs/ai_context/review_scope_attestations/road_procession_p1_source_scope_v1.json":
        "fa581b9ce63a29100219bf57044e9cd0856d426b",
    "custodian/tools/agent/paired_review_host_validation.py":
        "8b66f59641830c063c30f9f8b31d4416da261f4b",
    "custodian/tools/agent/test_paired_review_runner.py":
        "0981c8ff5e7ab6eaf4a036188521305888bd1932",
    "custodian/tools/validation/validation_manifest.json":
        "c7a6d734d5df4e42854a37ea4544b34d783c2e27",
}
_PROCESSION_RECOVERY_EXTRA_FILES = frozenset(_PROCESSION_RECOVERY_UNDECLARED_FILES)
_PROCESSION_RECOVERY_ARCHIVE_BLOBS = {
    **_PROCESSION_RECOVERY_UNDECLARED_FILES,
    f"{PACKET_ROOT}/archived/AGENT_PAIRED_REVIEW_PROCESSION_DOC_SCOPE_RECOVERY_V1.md":
        _PROCESSION_RECOVERY_PACKET_BLOB,
    f"{PACKET_ROOT}/README.md": "5ec21636665e03e046b9e9980a6dcbc9cf380b56",
    "AGENT_PAIRED_REVIEW_PROCESSION_DOC_SCOPE_RECOVERY_V1_CLAUDE_SUMMARY.md":
        "2df333fd1ba82f8c4de6305be3e4629e8743cc5c",
}

_PROCESSION_RECOVERY_MERGE = "f01a4982f1f1ddd05e4eb68740a2b1bddcaeefe3"
_PROCESSION_RECOVERY_MERGE_SECOND_PARENT = "668ab1c793d262fbbbc8d65e6e3406ad17ffe2eb"
_PROCESSION_RECOVERY_MERGE_TREE = "7ba4a5fa474ab5b5180856c073a212e83a9efc9c"
_PROCESSION_RECOVERY_MERGED_SOURCE_BLOBS = {
    "custodian/tools/agent/paired_review_host_validation.py":
        "02b5119da3b92402b99dd1da06f50b3b4a57700e",
    "custodian/tools/agent/test_paired_review_runner.py":
        "0aa7360551f57474c62275e3fc14cccc58a4c396",
    "custodian/tools/validation/validation_manifest.json":
        "51093242a8d08aed106b631ef1d54c7cfef61215",
}

_OR1_BOOTSTRAP_WORKSTREAM = "agent-orphan-recovery-observability-v1"
_OR1_BOOTSTRAP_ARCHIVE = "8ae6be7c9978dd8e7864fb790f9526a7d17f15e8"
_OR1_BOOTSTRAP_PARENT = "f8d91812e991ea49fce6f05207f455083d8eaa54"
_OR1_BOOTSTRAP_TREE = "bc94dc738d0b49ce16abc67fcef2f3a5ce5fc01c"
_OR1_BOOTSTRAP_ACTIVE_BLOB = "55142dc7a62c3c38ea6a9ec5c730d162092560a3"
_OR1_BOOTSTRAP_PACKET = f"{PACKET_ROOT}/archived/AGENT_ORPHAN_RECOVERY_OBSERVABILITY_V1.md"
_OR1_BOOTSTRAP_DOCS = {
    "custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md":
        "1032ef02822956ef5c1980c2cf93ec114dbb606e",
    "custodian/docs/ai_context/FILE_INDEX.md":
        "a90881285e5289381aaca5786ecc3101b02e0542",
}
_OR1_BOOTSTRAP_EXTRA_BLOBS = {
    **_OR1_BOOTSTRAP_DOCS,
    "custodian/tools/agent/session_supervisor.py": "8d4a3d51c31b9993ffb6e750379f7bfbb96b1213",
    "custodian/tools/agent/test_session_supervisor.py": "54911e8e6603e33768dcb9b9434a7e6b60bb1e9f",
    "custodian/tools/agent/workstream_recovery.py": "ce5f0580556db52e481d1536658a7b46c68248bc",
    "custodian/tools/validation/validation_manifest.json": "0c931df98bc1742e8a63b5f55d8e9b980332780d",
}
_OR1_BOOTSTRAP_ARCHIVE_BLOBS = {
    **_OR1_BOOTSTRAP_EXTRA_BLOBS,
    _OR1_BOOTSTRAP_PACKET: "50ed3aa6da55010252503b2017065b80eeedd434",
    f"{PACKET_ROOT}/README.md": "54f41405d73cd3b70871a11478f28bc93f3be5b8",
    "AGENT_ORPHAN_RECOVERY_OBSERVABILITY_V1_CLAUDE_SUMMARY.md":
        "274d987614e6d27b80e3bf31300f13a87ad53208",
}

_RESET_FOLLOWUP_WORKSTREAM = "agent-execution-reset-v1"
_RESET_FOLLOWUP_RUN_ID = "20261020T135839Z-db96534ed3a7"
_RESET_FOLLOWUP_BASE = "b5a46e82913455cb341c84811fd9be66b78ed138"
_RESET_FOLLOWUP_CLAIM_OID = "599c97403c67d53d60f3c394d09c756ff2b79c2d"
_RESET_FOLLOWUP_ARCHIVE = "bf0f59f478c361b6b34b6e0c6c354c8f3649eac0"
_RESET_FOLLOWUP_MERGE = "f43f3e6ec32a95ebbdc1e98f39f790d275411992"
_RESET_FOLLOWUP_MERGE_MAIN = "134e4c2913fbb88ea25fd5395ff6dc059e26f05f"
_RESET_FOLLOWUP_HEAD = "f635c33d8bb209d9cbc4fafb4aff88af27084867"
_RESET_FOLLOWUP_PATHS = {
    "custodian/tools/agent/test_workstream.py",
    "custodian/docs/ai_context/task_packets/archived/AGENT_EXECUTION_RESET_V1.md",
    "AGENT_EXECUTION_RESET_V1_CLAUDE_SUMMARY.md",
}

_HOST_IMPORT_CONFLICT_WORKSTREAM = (
    "agent-paired-review-failed-host-validation-import-recovery-v1"
)
_HOST_IMPORT_CONFLICT_RUN_ID = "20261020T200652Z-2fd156ce23d0"
_HOST_IMPORT_CONFLICT_ARCHIVE = "25229d8d3874608f7b8492df98bc3df4385a9d28"
_HOST_IMPORT_ARCHIVE_PARENT = "66266c1d8faa1fc6ffee84681a7b0907e59603ad"
_HOST_IMPORT_ARCHIVE_TREE = "ec70cea3f49f8c6d7a8cc3ecb58e548b2c3078ec"
_HOST_IMPORT_REVIEW_PACKET = (
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md"
)
_HOST_IMPORT_ARCHIVE_PATHS = {
    f"{PACKET_ROOT}/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md",
    f"{PACKET_ROOT}/archived/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md",
    f"{PACKET_ROOT}/README.md",
    _HOST_IMPORT_REVIEW_PACKET,
}
_HOST_IMPORT_ARCHIVE_BLOBS = {
    f"{PACKET_ROOT}/archived/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md":
        "a8650380c90545457e8503041409f5fb8f4861d6",
    f"{PACKET_ROOT}/README.md": "1daf7eae0a3cb126d2fa6f284e9d1609de8f3248",
    _HOST_IMPORT_REVIEW_PACKET: "17ecaac9ca17818d769a9f953003cf1ac7610665",
}
_HOST_IMPORT_CONFLICT_LANDING = "6e75b57ea828f5d90679ae737052a4acdefce361"
_HOST_IMPORT_CONFLICT_TRACE_REF = (
    "refs/remotes/origin/agent-diagnostics/"
    f"{_HOST_IMPORT_CONFLICT_WORKSTREAM}/{_HOST_IMPORT_CONFLICT_RUN_ID}"
)
_HOST_IMPORT_CONFLICT_TRACE_BLOB = "cdde47b5855c709e639fabc0455abe567b326310"
_HOST_IMPORT_CONFLICT_TRACE_SHA256 = (
    "8d51464d6fe4852cc6154e71889bff250b32994a61f0551cb66b98da8b84a915"
)
_HOST_IMPORT_PUBLISHED_TRACE_SHA256 = (
    "3c3327ae13b533e5e7e5bf483bbd92fe726f888a2c1d8f83a4c30482a003f502"
)
_HOST_IMPORT_LOCAL_TRACE_FINAL_EVENT = {
    "agent": None,
    "data": {
        "argv": [
            "git", "push", "origin",
            "fc31dfe831d562f5e5c68fba7483e124942b2f44:refs/heads/"
            "agent-diagnostics/agent-paired-review-failed-host-validation-import-recovery-v1/"
            "20261020T200652Z-2fd156ce23d0",
        ],
        "duration_ms": 2442,
        "return_code": 0,
        "stderr": "To github.com:braydio/CUSTODIAN.git\n"
        "   47ad2c46e..fc31dfe83  fc31dfe831d562f5e5c68fba7483e124942b2f44 -> "
        "agent-diagnostics/agent-paired-review-failed-host-validation-import-recovery-v1/"
        "20261020T200652Z-2fd156ce23d0\n",
        "stdout": "",
    },
    "elapsed_ms": 119776061,
    "event": "subprocess",
    "execution_generation": "execution-reset-v1-20261020",
    "host": "archdesk",
    "packet": f"{PACKET_ROOT}/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md",
    "pid": 1633009,
    "run_id": "20261020T200652Z-2fd156ce23d0",
    "schema": "custodian.workflow_trace_event.v1",
    "schema_version": 1,
    "timestamp_utc": "2026-10-22T05:23:08.540+00:00",
    "workstream": "agent-paired-review-failed-host-validation-import-recovery-v1",
}
_HOST_IMPORT_CONFLICT_MERGES = (
    {
        "commit": "dbcf8aec4eb09264b60bea9d26c99f235022efb5",
        "first_parent": "49772f31f4dfe28614b8be9c5c820f14e8872f6b",
        "main_sha": "e9e69fc2178b1a96e02240f4b0a86cdaf30581e7",
        "tree": "1937ca5af43c755a509c35ebb207e691bbd14fa3",
        "conflict_tree": "630cd341a3157a6712f4c06b11743ead3fdd38d5",
        "resolution": {
            "custodian/docs/ai_context/task_packets/README.md": (
                "100644", "b0afb24682bd1071bcf5a64bd5250b5210d310f0"),
            "custodian/docs/ai_context/task_packets/archived/"
            "AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md": (
                "100644", "a8650380c90545457e8503041409f5fb8f4861d6"),
            "custodian/tools/agent/test_paired_review_runner.py": (
                "100644", "7e9051cac61dc56ddc63c013e546a439681fcabd"),
            "custodian/tools/validation/validation_manifest.json": (
                "100644", "07f867213d3f6e778628f04ab38369dd782a0fca"),
        },
        "blocked_event_index": 26,
    },
    {
        "commit": "d83319a3a9c211fe3947e4951bfaa06f1684bf05",
        "first_parent": "b7b245dbf113b7fc21a5c34a83aee0bd65d7ccc8",
        "main_sha": "8e4bca145658b825bb6dedeed595a3c53497a138",
        "tree": "92cbaa6f98f93f0e354e04c37a3913637162d5fb",
        "conflict_tree": "0ae7a22eb2c76be9f9035e96b8417e944738389e",
        "resolution": {
            "custodian/docs/ai_context/task_packets/archived/"
            "AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md": (
                "100644", "5825264aa7296014bf2b3ccf498a8b30152fa654"),
        },
        "blocked_event_index": 29,
    },
)
_HOST_IMPORT_LATER_SYNC_MERGE = {
    "commit": "4b1af571345583e1f7d5a9b672647b28c75bd55f",
    "first_parent": "d66664cfc037c8eb8ba9b8e316badcc06955aa9d",
    "main_sha": "b5b1e5f2450f3f577a5df5c173c338e6da5187d1",
}
_HOST_IMPORT_FOLLOWUP_PATHS = {
    "AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1_CLAUDE_SUMMARY.md",
    f"{PACKET_ROOT}/archived/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md",
    "custodian/tools/agent/test_workstream.py",
    "custodian/tools/agent/workstream.py",
}
_HOST_IMPORT_FOLLOWUP_COMMITS = (
    "49772f31f4dfe28614b8be9c5c820f14e8872f6b",
    "a55c14e020d4986fb35baa75bde691c0c2e67e93",
    "b7b245dbf113b7fc21a5c34a83aee0bd65d7ccc8",
    "d68bd6e5c5b151ddd6aa38485ae9c2302a5fe993",
    "a3f7bfc4fbb7911b7dfe2a2982cff6de981f99a8",
    "819c9347a59f0029ce8d52ddcdcf6c58838ab2c0",
    "596dc6c1e9c949eb18940769e4232351ad9f1e60",
    "9c806d5dd592c14ce0e82ceeeff056bb284305e7",
    "1f6cfba992dfe73691ae71eaefe9c75f729a18fe",
    "2aac89ebfe200d5fb26b4bf06d975db06f7f985a",
    "d66664cfc037c8eb8ba9b8e316badcc06955aa9d",
    "6e75b57ea828f5d90679ae737052a4acdefce361",
)
_HOST_IMPORT_FINAL_FOLLOWUP_BLOBS = {
    "AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1_CLAUDE_SUMMARY.md":
        "416bb0aa16339c1ef92d0ccb023e54ae11190968",
    f"{PACKET_ROOT}/archived/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md":
        "5825264aa7296014bf2b3ccf498a8b30152fa654",
    "custodian/tools/agent/test_workstream.py": "be61e5dbf28793f7ddf6695a9d9d1ada0380705d",
    "custodian/tools/agent/workstream.py": "bf4cda7b8f00a6540f0849e68b21a2d1c3b6698c",
}
_HOST_IMPORT_CONFLICT_RESUME_EVENT_INDEX = 35
_HOST_IMPORT_CONFLICT_LATER_SYNC = {
    "changed": True,
    "head": "4b1af571345583e1f7d5a9b672647b28c75bd55f",
    "main_sha": "b5b1e5f2450f3f577a5df5c173c338e6da5187d1",
}
_HOST_IMPORT_CONFLICT_FINAL_SYNC = {
    "changed": False,
    "head": _HOST_IMPORT_CONFLICT_LANDING,
    "main_sha": "b5b1e5f2450f3f577a5df5c173c338e6da5187d1",
}


def _read_host_import_local_trace(repo: Path) -> bytes:
    common = Path(_git(repo, "rev-parse", "--git-common-dir"))
    if not common.is_absolute():
        common = (repo / common).resolve()
    path = (common / "custodian-workflow" / "traces" / _HOST_IMPORT_CONFLICT_WORKSTREAM
            / f"{_HOST_IMPORT_CONFLICT_RUN_ID}.jsonl")
    if path.is_symlink() or not path.is_file():
        raise HostValidationError("host-import immutable local lifecycle trace is missing or unsafe")
    try:
        return path.read_bytes()
    except OSError as exc:
        raise HostValidationError("host-import immutable local lifecycle trace is unreadable") from exc


def _verify_host_import_conflict_merges(
    repo: Path, target_workstream: str, target_packet_text: str,
    landing_commit: str, trace_landing: str, merges: list[dict[str, str]],
    followup_commits: list[str],
    events: list[dict], trace_ref: str,
) -> dict | None:
    """Authenticate only the two conflict-resolved merges in the pinned host-import run."""
    if (target_workstream != _HOST_IMPORT_CONFLICT_WORKSTREAM
            or landing_commit != _HOST_IMPORT_CONFLICT_ARCHIVE
            or trace_landing != _HOST_IMPORT_CONFLICT_LANDING
            or trace_ref != _HOST_IMPORT_CONFLICT_TRACE_REF
            or header_field(target_packet_text, "Workstream") != _HOST_IMPORT_CONFLICT_WORKSTREAM
            or tuple((merge.get("commit"), merge.get("first_parent"), merge.get("main_sha"))
                     for merge in merges)
            != tuple((item["commit"], item["first_parent"], item["main_sha"])
                     for item in (*_HOST_IMPORT_CONFLICT_MERGES, _HOST_IMPORT_LATER_SYNC_MERGE))
            or tuple(followup_commits) != _HOST_IMPORT_FOLLOWUP_COMMITS):
        return None

    trace_blob = subprocess.run(
        ["git", "rev-parse", "--verify", f"{trace_ref}:trace.jsonl"],
        cwd=repo, text=True, capture_output=True,
    )
    trace_bytes = subprocess.run(
        ["git", "show", f"{trace_ref}:trace.jsonl"], cwd=repo, capture_output=True,
    )
    if (trace_blob.returncode or trace_blob.stdout.strip() != _HOST_IMPORT_CONFLICT_TRACE_BLOB
            or trace_bytes.returncode
            or _sha256(trace_bytes.stdout) != _HOST_IMPORT_PUBLISHED_TRACE_SHA256
            or len(events) != 62):
        raise HostValidationError("host-import conflict trace identity or content changed")
    try:
        published_events = [json.loads(line) for line in trace_bytes.stdout.splitlines()]
        local_trace_bytes = _read_host_import_local_trace(repo)
        local_events = [json.loads(line) for line in local_trace_bytes.splitlines()]
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        raise HostValidationError("host-import immutable lifecycle trace is malformed") from exc
    if (_sha256(local_trace_bytes) != _HOST_IMPORT_CONFLICT_TRACE_SHA256
            or published_events != events or len(local_events) != 63
            or local_events[:-1] != published_events
            or local_events[-1] != _HOST_IMPORT_LOCAL_TRACE_FINAL_EVENT):
        raise HostValidationError(
            "host-import local trace does not preserve the pinned publication and final push event"
        )
    if any(event.get("run_id") != _HOST_IMPORT_CONFLICT_RUN_ID
           or event.get("workstream") != _HOST_IMPORT_CONFLICT_WORKSTREAM
           or event.get("packet") != (
               f"{PACKET_ROOT}/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md")
           or event.get("schema") != "custodian.workflow_trace_event.v1"
           or event.get("schema_version") != 1 for event in events):
        raise HostValidationError("host-import conflict trace contains a mismatched run identity")

    conflict_reason = "origin/main merge conflicted; resolve in the preserved worktree"
    conflict_events = [
        index for index, event in enumerate(events)
        if event.get("event") == "run_blocked"
        and event.get("data") == {"reason": conflict_reason}
    ]
    expected_indexes = [item["blocked_event_index"] for item in _HOST_IMPORT_CONFLICT_MERGES]
    if conflict_events != expected_indexes:
        raise HostValidationError("host-import trace conflict interruptions are missing, duplicate, or reordered")
    resumed = events[_HOST_IMPORT_CONFLICT_RESUME_EVENT_INDEX]
    expected_resume = {
        "branch": f"agent/{_HOST_IMPORT_CONFLICT_WORKSTREAM}",
        "head": _HOST_IMPORT_CONFLICT_MERGES[1]["commit"],
        "worktree": "/home/braydenchaffee/Projects/.custodian-worktrees/"
        "agent-paired-review-failed-host-validation-import-recovery-v1-"
        "20261020T200652Z-2fd156ce23d0",
    }
    if (resumed.get("event") != "worktree_resumed" or resumed.get("data") != expected_resume
            or resumed.get("timestamp_utc") != "2026-10-22T04:11:09.185+00:00"):
        raise HostValidationError("host-import trace does not bind the exact post-conflict worktree resume")

    blocked_times = [datetime.fromisoformat(events[index]["timestamp_utc"])
                     for index in expected_indexes]
    resumed_time = datetime.fromisoformat(resumed["timestamp_utc"])
    merge_times = [datetime.fromisoformat(_git(repo, "show", "-s", "--format=%cI", item["commit"]))
                   for item in _HOST_IMPORT_CONFLICT_MERGES]
    if not (blocked_times[0] < merge_times[0] < blocked_times[1]
            and blocked_times[1] < merge_times[1] < resumed_time):
        raise HostValidationError("host-import conflict merges do not fit the ordered interruption timeline")

    merge_delta_paths = {}
    for actual, expected in zip(merges[:2], _HOST_IMPORT_CONFLICT_MERGES):
        if (actual.get("first_parent") != expected["first_parent"]
                or actual.get("main_sha") != expected["main_sha"]):
            raise HostValidationError("host-import conflict merge has substituted parent identities")
        parents = _git(repo, "rev-list", "--parents", "-n", "1", expected["commit"]).split()
        if parents != [expected["commit"], expected["first_parent"], expected["main_sha"]]:
            raise HostValidationError("host-import conflict merge has unexpected full Git parents")
        actual_tree = _git(repo, "rev-parse", f"{expected['commit']}^{{tree}}")
        if actual_tree != expected["tree"]:
            raise HostValidationError("host-import conflict merge tree identity changed")
        merge_tree = subprocess.run(
            ["git", "merge-tree", "--write-tree", expected["first_parent"], expected["main_sha"]],
            cwd=repo, text=True, capture_output=True,
        )
        merge_tree_oid = merge_tree.stdout.splitlines()[0].strip() if merge_tree.stdout.splitlines() else ""
        if merge_tree.returncode != 1 or merge_tree_oid != expected["conflict_tree"]:
            raise HostValidationError("host-import conflict merge no longer reproduces its pinned conflict tree")
        raw_diff = subprocess.run(
            ["git", "diff", "--raw", "--no-abbrev", expected["conflict_tree"], expected["commit"]],
            cwd=repo, text=True, capture_output=True,
        )
        if raw_diff.returncode:
            raise HostValidationError("cannot inspect host-import conflict-resolution paths and modes")
        resolutions = {}
        for line in raw_diff.stdout.splitlines():
            metadata, separator, path = line.partition("\t")
            fields = metadata.split()
            if not separator or len(fields) != 5 or fields[4] != "M":
                raise HostValidationError("host-import conflict resolution contains an unexpected file operation")
            old_mode, new_mode, _old_oid, new_oid, _status = fields
            old_mode = old_mode.removeprefix(":")
            resolutions[path] = (new_mode, new_oid)
            if old_mode != "100644" or new_mode != "100644":
                raise HostValidationError("host-import conflict resolution changed a regular file mode")
        if resolutions != expected["resolution"]:
            raise HostValidationError("host-import conflict-resolution paths or blob identities changed")
        first_parent_diff = subprocess.run(
            ["git", "diff", "--raw", "--no-abbrev", expected["first_parent"], expected["commit"]],
            cwd=repo, text=True, capture_output=True,
        )
        if first_parent_diff.returncode:
            raise HostValidationError("cannot inspect host-import merge source path and mode coverage")
        changed_paths = set()
        for line in first_parent_diff.stdout.splitlines():
            metadata, separator, path = line.partition("\t")
            fields = metadata.split()
            if not separator or len(fields) != 5:
                raise HostValidationError("host-import merge has malformed source path evidence")
            old_mode, new_mode = fields[0].removeprefix(":"), fields[1]
            if (fields[4] not in {"A", "M"}
                    or old_mode not in {"000000", "100644"} or new_mode != "100644"):
                raise HostValidationError("host-import merge source path has an unapproved operation or mode")
            changed_paths.add(path)
        merge_delta_paths[expected["commit"]] = sorted(changed_paths)

    if subprocess.run(
        ["git", "merge-base", "--is-ancestor", _HOST_IMPORT_CONFLICT_MERGES[0]["commit"],
         _HOST_IMPORT_CONFLICT_MERGES[1]["commit"]], cwd=repo, capture_output=True,
    ).returncode:
        raise HostValidationError("host-import conflict merges are not in the pinned ancestry order")

    expected_followup_paths = {
        "49772f31f4dfe28614b8be9c5c820f14e8872f6b": {
            "AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1_CLAUDE_SUMMARY.md"},
        "a55c14e020d4986fb35baa75bde691c0c2e67e93": {
            f"{PACKET_ROOT}/archived/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md"},
        "b7b245dbf113b7fc21a5c34a83aee0bd65d7ccc8": {
            "AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1_CLAUDE_SUMMARY.md"},
        "d68bd6e5c5b151ddd6aa38485ae9c2302a5fe993": {
            "custodian/tools/agent/test_workstream.py", "custodian/tools/agent/workstream.py"},
        "a3f7bfc4fbb7911b7dfe2a2982cff6de981f99a8": {
            "custodian/tools/agent/test_workstream.py", "custodian/tools/agent/workstream.py"},
        "819c9347a59f0029ce8d52ddcdcf6c58838ab2c0": {
            "custodian/tools/agent/test_workstream.py", "custodian/tools/agent/workstream.py"},
        "596dc6c1e9c949eb18940769e4232351ad9f1e60": {
            "custodian/tools/agent/workstream.py"},
        "9c806d5dd592c14ce0e82ceeeff056bb284305e7": {
            "custodian/tools/agent/test_workstream.py", "custodian/tools/agent/workstream.py"},
        "1f6cfba992dfe73691ae71eaefe9c75f729a18fe": {
            "custodian/tools/agent/test_workstream.py", "custodian/tools/agent/workstream.py"},
        "2aac89ebfe200d5fb26b4bf06d975db06f7f985a": {
            "custodian/tools/agent/test_workstream.py", "custodian/tools/agent/workstream.py"},
        "d66664cfc037c8eb8ba9b8e316badcc06955aa9d": {
            "custodian/tools/agent/test_workstream.py", "custodian/tools/agent/workstream.py"},
        _HOST_IMPORT_CONFLICT_LANDING: {
            "custodian/tools/agent/test_workstream.py", "custodian/tools/agent/workstream.py"},
    }
    all_followup_paths = set()
    for commit in _HOST_IMPORT_FOLLOWUP_COMMITS:
        parents = _git(repo, "rev-list", "--parents", "-n", "1", commit).split()
        if len(parents) != 2:
            raise HostValidationError("host-import follow-up chain contains an unexpected merge")
        diff = subprocess.run(
            ["git", "diff", "--raw", "--no-abbrev", parents[1], commit],
            cwd=repo, text=True, capture_output=True,
        )
        if diff.returncode:
            raise HostValidationError("cannot inspect host-import follow-up path and mode changes")
        actual_paths = set()
        for line in diff.stdout.splitlines():
            metadata, separator, path = line.partition("\t")
            fields = metadata.split()
            if not separator or len(fields) != 5 or fields[4] != "M":
                raise HostValidationError("host-import follow-up contains an unexpected file operation")
            old_mode, new_mode = fields[0].removeprefix(":"), fields[1]
            if old_mode != "100644" or new_mode != "100644":
                raise HostValidationError("host-import follow-up changed a file mode")
            actual_paths.add(path)
        if actual_paths != expected_followup_paths[commit]:
            raise HostValidationError("host-import follow-up changed an unpinned path set")
        all_followup_paths.update(actual_paths)
    if all_followup_paths != _HOST_IMPORT_FOLLOWUP_PATHS:
        raise HostValidationError("host-import follow-up path inventory changed")
    for path, expected_blob in _HOST_IMPORT_FINAL_FOLLOWUP_BLOBS.items():
        entry = subprocess.run(["git", "ls-tree", "-z", _HOST_IMPORT_CONFLICT_LANDING, "--", path],
                               cwd=repo, capture_output=True)
        if entry.returncode or not entry.stdout:
            raise HostValidationError("host-import final follow-up path is missing")
        metadata = entry.stdout.split(b"\t", 1)[0].split()
        if len(metadata) != 3 or metadata[0] != b"100644" or metadata[2].decode() != expected_blob:
            raise HostValidationError("host-import final follow-up mode or content identity changed")

    sync_events = [(index, event.get("data")) for index, event in enumerate(events)
                   if event.get("event") == "main_sync"]
    exact_later = [(index, data) for index, data in sync_events
                   if data == _HOST_IMPORT_CONFLICT_LATER_SYNC]
    exact_final = [(index, data) for index, data in sync_events
                   if data == _HOST_IMPORT_CONFLICT_FINAL_SYNC]
    if (len(sync_events) != 2 or len(exact_later) != 1 or len(exact_final) != 1
            or exact_later[0][0] != 42 or exact_final[0][0] != 54
            or exact_later[0][0] <= expected_indexes[-1]
            or exact_final[0][0] <= exact_later[0][0]
            or exact_final[0][0] >= next(
                index for index, event in enumerate(events)
                if event.get("event") == "landing_started")):
        raise HostValidationError("host-import trace lacks the exact ordered later main-sync witnesses")
    return {
        "blocked_event_indexes": {
            item["commit"]: item["blocked_event_index"]
            for item in _HOST_IMPORT_CONFLICT_MERGES
        },
        "followup_paths": sorted(all_followup_paths),
        "resolution_paths": {
            item["commit"]: sorted(item["resolution"])
            for item in _HOST_IMPORT_CONFLICT_MERGES
        },
        "merge_delta_paths": merge_delta_paths,
    }
_RESET_ARCHIVE_PATHS = {
    "AGENT_EXECUTION_RESET_V1_CLAUDE_SUMMARY.md",
    f"{PACKET_ROOT}/AGENT_EXECUTION_RESET_V1.md",
    f"{PACKET_ROOT}/AGENT_PAIRED_REVIEW_CLAIM_PUBLICATION_MAIN_ADVANCE_V1.md",
    f"{PACKET_ROOT}/README.md",
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_ADVANCED_HEAD_PASS_CLOSEOUT_V1.md",
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_CLAIM_PUBLICATION_MAIN_ADVANCE_V1.md",
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_EXACT_CLAIM_PARKING_V1.md",
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_INVALID_DISPOSITION_RECOVERY_V1.md",
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_PREVALIDATION_RECOVERY_PLAN_V1.md",
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_SOURCE_BEARING_ARCHIVE_GATE_V1.md",
    f"{PACKET_ROOT}/archived/AGENT_EXECUTION_RESET_V1.md",
    f"{PACKET_ROOT}/archived/AGENT_PAIRED_REVIEW_CLAIM_PUBLICATION_MAIN_ADVANCE_V1.md",
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_ADVANCED_HEAD_PASS_CLOSEOUT_V1.md",
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_CLAIM_PUBLICATION_MAIN_ADVANCE_V1.md",
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_EXACT_CLAIM_PARKING_V1.md",
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_INVALID_DISPOSITION_RECOVERY_V1.md",
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_PREVALIDATION_RECOVERY_PLAN_V1.md",
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_SOURCE_BEARING_ARCHIVE_GATE_V1.md",
}
_BLENDER_SOURCE_WORKSTREAM = "operator-motion-foundry-blender-2d-rig-v1"
_BLENDER_SOURCE_ARCHIVE = "a6604a80be32c9078336ae48de6c4e43ec6815c7"
_BLENDER_SOURCE_ROOT = (
    "custodian/asset_drop/source_work/operator/motion_foundry/"
    "operator_south_visible_surface_v1/blender/"
)
_BLENDER_SOURCE_PATH = _BLENDER_SOURCE_ROOT + "operator_south_cutout_rig_v1.blend"
_BLENDER_RECEIPT_PATH = _BLENDER_SOURCE_ROOT + "rig_build_receipt.json"
_BLENDER_SOURCE_OID = "b13a70b4c26da0b76f5b04d66902d93e7e03fc1394398c3135759305b9fb656f"
_RESUMED_PROVENANCE_SYNC_MERGE = "d5c6315979f1e3fd2ee55c6e15cae7f9e30c1f99"
_RESUMED_PROVENANCE_WORKSTREAM = "agent-paired-review-resumed-worktree-provenance-v1"
_RESUMED_PROVENANCE_SYNC_PARENTS = (
    "2e898dddc82a596b0a2bd15c150b1645cf61f29c",
    "e376be3735707a4e09618ebf3f3e4273a425009b",
)
_RESUMED_PROVENANCE_README_BLOBS = (
    "9c7317d14319a1da42333bd8d1dea572b15d52b2",
    "f77d5fb9e55546ff367526f85957440357598b22",
    "e8a77211b5fa4ec43451b45911d98fec1f356d84",
)


def _managed_packet_index_additive_reconciliation(first_parent: bytes,
                                                  second_parent: bytes,
                                                  merged: bytes) -> bool:
    """Accept only additive managed-index entries copied from prior main."""
    start = MANAGED_BLOCK_START.encode("ascii")
    end = MANAGED_BLOCK_END.encode("ascii")

    def split(value: bytes) -> tuple[bytes, bytes, bytes] | None:
        if value.count(start) != 1 or value.count(end) != 1:
            return None
        start_at = value.find(start)
        end_at = value.find(end)
        if end_at <= start_at or value.find(start, start_at + len(start)) >= 0:
            return None
        block_end = end_at + len(end)
        prefix = value[:start_at]
        block = value[start_at:block_end]
        suffix = value[block_end:]
        if not block.startswith(start + b"\n") or not block.endswith(b"\n" + end):
            return None
        return prefix, block, suffix

    original = split(first_parent)
    prior_main = split(second_parent)
    reconciled = split(merged)
    if original is None or prior_main is None or reconciled is None:
        return False
    if original[0] != reconciled[0] or original[2] != reconciled[2]:
        return False

    def entries(block: bytes) -> list[bytes]:
        return block[len(start) + 1:-(len(end) + 1)].split(b"\n")

    original_entries = entries(original[1])
    prior_entries = entries(prior_main[1])
    merged_entries = entries(reconciled[1])
    if (len(set(original_entries)) != len(original_entries)
            or len(set(prior_entries)) != len(prior_entries)
            or len(set(merged_entries)) != len(merged_entries)
            or not set(original_entries).issubset(merged_entries)
            or not set(merged_entries).issubset(prior_entries)):
        return False
    # Keep the original order and require added entries to retain their order
    # from the recorded prior-main managed block. The merge may omit other
    # second-parent additions because this is an additive reconciliation, not
    # an instruction to copy the entire current index.
    original_iter = iter(merged_entries)
    if not all(any(value == candidate for candidate in original_iter)
               for value in original_entries):
        return False
    added = [entry for entry in merged_entries if entry not in set(original_entries)]
    prior_added = [entry for entry in prior_entries if entry not in set(original_entries)]
    prior_iter = iter(prior_added)
    return all(any(value == candidate for candidate in prior_iter) for value in added)


def _managed_packet_index_archival_reconciliation(repo: Path, first_parent: str,
                                                  second_parent: str, merge: str) -> bool:
    """Allow only index removals proven by complete packets archived on main."""
    path = f"{PACKET_ROOT}/README.md"
    try:
        versions = [
            subprocess.run(["git", "show", f"{revision}:{path}"], cwd=repo,
                           capture_output=True, check=True).stdout
            for revision in (first_parent, second_parent, merge)
        ]
    except subprocess.CalledProcessError:
        return False
    start = MANAGED_BLOCK_START.encode("ascii")
    end = MANAGED_BLOCK_END.encode("ascii")

    def split(raw: bytes) -> tuple[bytes, bytes, bytes] | None:
        if raw.count(start) != 1 or raw.count(end) != 1:
            return None
        begin = raw.find(start)
        finish = raw.find(end)
        if finish <= begin:
            return None
        end_at = finish + len(end)
        if not raw[begin:end_at].startswith(start + b"\n") or not raw[begin:end_at].endswith(b"\n" + end):
            return None
        return raw[:begin], raw[begin:end_at], raw[end_at:]

    original, prior, reconciled = map(split, versions)
    if (original is None or prior is None or reconciled is None
            or original[0] != reconciled[0] or original[2] != reconciled[2]):
        return False

    def entries(block: bytes) -> list[bytes]:
        return block[1][len(start) + 1:-(len(end) + 1)].split(b"\n")

    first_entries, main_entries, merged_entries = map(entries, (original, prior, reconciled))
    if any(len(set(values)) != len(values) for values in (first_entries, main_entries, merged_entries)):
        return False
    missing = [entry for entry in first_entries if entry not in merged_entries]
    if not missing:
        return False
    for entry in missing:
        try:
            line = entry.decode("utf-8")
        except UnicodeDecodeError:
            return False
        match = re.fullmatch(r"- `([A-Za-z0-9_.-]+\.md)` — .+", line)
        if match is None:
            return False
        filename = match.group(1)
        active_path = f"{PACKET_ROOT}/{filename}"
        archived_path = f"{PACKET_ROOT}/archived/{filename}"
        if _git_tree_entry(repo, second_parent, active_path) is not None:
            return False
        archived_entry = _git_tree_entry(repo, second_parent, archived_path)
        if archived_entry is None or archived_entry[0] != "100644":
            return False
        try:
            archived_text = subprocess.run(
                ["git", "show", f"{second_parent}:{archived_path}"], cwd=repo,
                text=True, capture_output=True, check=True,
            ).stdout
        except subprocess.CalledProcessError:
            return False
        packet = parse_packet(archived_path, archived_text)
        if packet.error or packet.status != "complete" or not packet.workstream:
            return False

    survivors = [entry for entry in first_entries if entry not in set(missing)]
    survivor_iter = iter(merged_entries)
    if not all(any(entry == candidate for candidate in survivor_iter) for entry in survivors):
        return False
    added = [entry for entry in merged_entries if entry not in set(first_entries)]
    prior_additions = [entry for entry in main_entries if entry not in set(first_entries)]
    prior_iter = iter(prior_additions)
    return all(entry in main_entries for entry in merged_entries) and all(
        any(entry == candidate for candidate in prior_iter) for entry in added
    )


def _resumed_provenance_index_reconciliation(repo: Path, first_parent: str,
                                             second_parent: str, merge: str) -> bool:
    """Pin the verified generated-index delta on the resumed-provenance landing."""
    parents = subprocess.run(["git", "rev-list", "--parents", "-n", "1", merge],
                             cwd=repo, text=True, capture_output=True)
    if parents.returncode or parents.stdout.split() != [merge, first_parent, second_parent]:
        return False
    if merge != _RESUMED_PROVENANCE_SYNC_MERGE or (first_parent, second_parent) != _RESUMED_PROVENANCE_SYNC_PARENTS:
        return False
    path = f"{PACKET_ROOT}/README.md"
    blobs = tuple(_git_tree_entry(repo, revision, path) for revision in
                  (first_parent, second_parent, merge))
    return all(entry is not None and entry[0] == "100644" for entry in blobs) and tuple(
        entry[1] for entry in blobs if entry is not None
    ) == _RESUMED_PROVENANCE_README_BLOBS


def _expand_braced_work_surface_paths(work_surface: str) -> set[str]:
    """Expand bounded file alternatives in backtick paths, never as globs."""
    expanded: set[str] = set()
    for token in re.findall(r"`([^`]+)`", work_surface):
        if "{" not in token and "}" not in token:
            continue
        if not token.startswith("custodian/"):
            if "custodian/" in token:
                raise HostValidationError("braced Work surface path must be repository-relative")
            continue
        match = _WORK_SURFACE_BRACE_PATH_RE.fullmatch(token)
        if match is None:
            raise HostValidationError("malformed braced Work surface path")
        directory, raw_names, suffix = match.groups()
        names = raw_names.split(",")
        if (not 2 <= len(names) <= 32 or len(set(names)) != len(names)
                or suffix.lower() not in _IMPLEMENTATION_SUFFIXES):
            raise HostValidationError("braced Work surface path is unbounded or unsupported")
        expanded.update(f"custodian/{directory}/{name}{suffix}" for name in names)
    return expanded


def _git(worktree: Path, *args: str) -> str:
    result = subprocess.run(["git", *args], cwd=worktree, text=True, capture_output=True)
    if result.returncode:
        raise HostValidationError(result.stderr.strip() or result.stdout.strip() or "git identity check failed")
    return result.stdout.strip()


def _git_paths(worktree: Path, revision: str) -> list[str]:
    result = subprocess.run(["git", "diff", "--name-only", revision], cwd=worktree,
                            text=True, capture_output=True)
    if result.returncode:
        raise HostValidationError(result.stderr.strip() or "could not enumerate validation source paths")
    return sorted({path for path in result.stdout.splitlines() if path})


def _write_exclusive(path: Path, contents: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(contents)
            stream.flush()
            os.fsync(stream.fileno())
        try:
            os.link(temporary, path)
        except FileExistsError as exc:
            raise HostValidationError(f"refusing to replace preexisting review evidence: {path.name}") from exc
        directory_fd = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
    finally:
        if temporary is not None:
            try:
                os.unlink(temporary)
            except FileNotFoundError:
                pass


def _validated_generated_png_import(worktree: Path, sidecar: Path) -> tuple[str, bytes] | None:
    """Return the exact tracked PNG source and bytes for a real Godot texture sidecar."""
    if sidecar.is_symlink() or not sidecar.is_file() or not str(sidecar).endswith(".png.import"):
        return None
    source = sidecar.relative_to(worktree).as_posix()[:-len(".import")]
    if not source.endswith(".png") or not (worktree / source).is_file():
        return None
    tracked = subprocess.run(["git", "ls-files", "--error-unmatch", "--", source], cwd=worktree,
                             capture_output=True, check=False)
    committed = subprocess.run(["git", "cat-file", "-e", f"HEAD:{source}"], cwd=worktree,
                               capture_output=True, check=False)
    if tracked.returncode or committed.returncode or not _tracked_png_matches_head(worktree, source):
        return None
    try:
        raw = sidecar.read_bytes()
        text = raw.decode("utf-8")
    except (OSError, UnicodeDecodeError):
        return None
    if not _valid_png_import_bytes(raw, source):
        return None
    return source, raw


def _tracked_png_matches_head(worktree: Path, source: str) -> bool:
    # Read the Git blob directly so LFS-backed sources remain pointers here;
    # `git show` invokes the smudge filter and may perform unrelated downloads.
    committed = subprocess.run(["git", "cat-file", "blob", f"HEAD:{source}"], cwd=worktree,
                               capture_output=True, check=False).stdout
    current = (worktree / source).read_bytes()
    pointer = re.fullmatch(
        rb"version https://git-lfs\.github\.com/spec/v1\n"
        rb"oid sha256:([0-9a-f]{64})\nsize ([0-9]+)\n?", committed,
    )
    if pointer:
        return (hashlib.sha256(current).hexdigest().encode() == pointer.group(1)
                and len(current) == int(pointer.group(2)))
    return current == committed


def _valid_png_import_bytes(raw: bytes, source: str) -> bool:
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        return False
    resource_path = source.removeprefix("custodian/")
    expected_source = f'source_file="res://{resource_path}"'
    return (text.startswith("[remap]\n") and '\nimporter="texture"\n' in text
            and '\ntype="CompressedTexture2D"\n' in text
            and re.search(r'(?m)^uid="uid://[A-Za-z0-9]+"$', text)
            and "\n[deps]\n" in text and f"\n{expected_source}\n" in text
            and "\n[params]\n" in text
            and re.search(r'(?m)^path="res://\.godot/imported/[^"\n]+"$', text))


def verified_failed_import_sidecars(worktree: Path, expected_paths: set[str] | None = None) -> list[dict]:
    """Authenticate only the exact known Grunt sidecars for the protected failed run."""
    worktree = Path(worktree).resolve()
    current = subprocess.run(["git", "ls-files", "--others", "--exclude-standard"], cwd=worktree,
                             text=True, capture_output=True, check=True).stdout.splitlines()
    untracked = set(current)
    expected = set(FAILED_IMPORT_RECOVERY_SIDECARS if expected_paths is None else expected_paths)
    if untracked != expected:
        raise HostValidationError("protected failed-import worktree has missing or unrelated untracked files")
    records = []
    for relative in sorted(expected):
        validated = _validated_generated_png_import(worktree, worktree / relative)
        if validated is None:
            raise HostValidationError(f"protected generated import sidecar is missing or malformed: {relative}")
        source, raw = validated
        if source != relative[:-len(".import")]:
            raise HostValidationError(f"protected import sidecar names a different PNG source: {relative}")
        records.append({"source_path": source, "sidecar_path": relative,
                        "sha256": _sha256(raw), "size_bytes": len(raw)})
    return records


def _snapshot_png_import_sidecars(worktree: Path) -> dict[str, str]:
    tracked = subprocess.run(["git", "ls-files", "--", "*.png"], cwd=worktree,
                             text=True, capture_output=True, check=True).stdout.splitlines()
    snapshot = {}
    for source in tracked:
        sidecar = worktree / f"{source}.import"
        if sidecar.exists() or sidecar.is_symlink():
            if sidecar.is_symlink() or not sidecar.is_file():
                snapshot[f"{source}.import"] = "unsafe"
            else:
                snapshot[f"{source}.import"] = _sha256(sidecar.read_bytes())
    return snapshot


def _capture_generated_png_imports(worktree: Path, run_dir: Path,
                                   initial_sidecars: dict[str, str]) -> tuple[list[dict], str | None]:
    """Copy/hash new admissible import companions, then unlink only verified copies."""
    current_sidecars = _snapshot_png_import_sidecars(worktree)
    baseline_errors = []
    for path, expected in initial_sidecars.items():
        if current_sidecars.get(path) != expected:
            baseline_errors.append(path)
    sidecar_paths = sorted(set(current_sidecars) - set(initial_sidecars))
    records: list[dict] = []
    invalid: list[str] = []
    evidence_dir = run_dir / "generated-import-artifacts"
    files_dir = evidence_dir / "files"
    if sidecar_paths:
        files_dir.mkdir(parents=True, exist_ok=False)
    for relative in sidecar_paths:
        source = worktree / relative
        validated = _validated_generated_png_import(worktree, source)
        if validated is None:
            invalid.append(relative)
            continue
        png_path, raw = validated
        digest = _sha256(raw)
        evidence_name = f"{digest}.png.import"
        evidence_path = files_dir / evidence_name
        _write_exclusive(evidence_path, raw)
        if evidence_path.read_bytes() != raw or _sha256(evidence_path.read_bytes()) != digest:
            raise HostValidationError(f"generated import sidecar preservation failed: {relative}")
        records.append({"source_path": png_path, "sidecar_path": relative,
                        "evidence_path": f"generated-import-artifacts/files/{evidence_name}",
                        "sha256": digest, "size_bytes": len(raw)})
    manifest_path = evidence_dir / "manifest.json"
    if records or sidecar_paths:
        records.sort(key=lambda item: item["sidecar_path"])
        _write_exclusive(manifest_path, (json.dumps(records, indent=2, sort_keys=True) + "\n").encode())
        manifest_sha = _sha256(manifest_path.read_bytes())
        for item in records:
            evidence_path = run_dir / item["evidence_path"]
            sidecar = worktree / item["sidecar_path"]
            if (evidence_path.is_symlink() or not evidence_path.is_file()
                    or _sha256(evidence_path.read_bytes()) != item["sha256"]
                    or sidecar.is_symlink() or not sidecar.is_file()
                    or _sha256(sidecar.read_bytes()) != item["sha256"]):
                raise HostValidationError("generated import sidecar changed after evidence capture")
        if not invalid:
            for item in records:
                (worktree / item["sidecar_path"]).unlink()
    else:
        manifest_sha = None
    errors = []
    if invalid:
        errors.append("new PNG import sidecars are not admissible generated metadata: " + ", ".join(invalid))
    if baseline_errors:
        errors.append("preexisting PNG import sidecars changed during validation: " + ", ".join(baseline_errors))
    error = "; ".join(errors) if errors else None
    return records, error


def _verify_generated_import_manifest(worktree: Path, evidence_dir: Path, metadata: dict) -> None:
    manifest_sha = metadata.get("generated_import_manifest_sha256")
    manifest_path = evidence_dir / "generated-import-artifacts/manifest.json"
    if manifest_sha is None:
        if manifest_path.exists():
            raise HostValidationError("unexpected generated import manifest")
        return
    if manifest_path.is_symlink() or not manifest_path.is_file() or _sha256(manifest_path.read_bytes()) != manifest_sha:
        raise HostValidationError("generated import manifest digest changed")
    try:
        records = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise HostValidationError("generated import manifest is malformed") from exc
    if not isinstance(records, list):
        raise HostValidationError("generated import manifest must be a list")
    for item in records:
        if not isinstance(item, dict):
            raise HostValidationError("generated import manifest entry is malformed")
        source = item.get("sidecar_path")
        evidence = item.get("evidence_path")
        source_image = item.get("source_path")
        if (not isinstance(source, str) or not source.endswith(".png.import")
                or not isinstance(source_image, str) or source != source_image + ".import"
                or not source_image.startswith("custodian/") or source_image.startswith("/")
                or ".." in Path(source_image).parts or not isinstance(evidence, str)
                or not evidence.startswith("generated-import-artifacts/files/")
                or ".." in Path(evidence).parts):
            raise HostValidationError("generated import manifest path is outside its bounded namespace")
        evidence_path = evidence_dir / evidence
        if not evidence_path.resolve().is_relative_to(evidence_dir.resolve()):
            raise HostValidationError("generated import evidence path escapes its append-only attempt")
        if (evidence_path.is_symlink() or not evidence_path.is_file()
                or _sha256(evidence_path.read_bytes()) != item.get("sha256")
                or evidence_path.stat().st_size != item.get("size_bytes")):
            raise HostValidationError("generated import artifact failed its recorded hash")
        tracked = subprocess.run(["git", "cat-file", "-e", f"HEAD:{source_image}"], cwd=worktree,
                                 capture_output=True, check=False)
        if (tracked.returncode or not _tracked_png_matches_head(worktree, source_image)
                or not _valid_png_import_bytes(evidence_path.read_bytes(), source_image)):
            raise HostValidationError("generated import artifact no longer matches a tracked PNG source")


def probe_host_capabilities() -> dict[str, bool]:
    """Verify the coordinator can bind loopback and write the isolated Godot HOME."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
            probe.bind(("127.0.0.1", 0))
    except OSError as exc:
        raise HostValidationError(f"coordinator loopback socket preflight failed: {exc}") from exc
    home = godot_home()
    try:
        with tempfile.NamedTemporaryFile(prefix="paired-review-home-probe-", dir=home):
            pass
    except OSError as exc:
        raise HostValidationError(f"isolated Godot HOME is not writable: {exc}") from exc
    return {"loopback_bind": True, "godot_home_writable": True}


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _source_hashes(worktree: Path, paths: list[str]) -> dict[str, str]:
    values = {}
    for relative in paths:
        path = worktree / relative
        if not path.is_file():
            raise HostValidationError(f"implementation diff source is missing: {relative}")
        values[relative] = _sha256(path.read_bytes())
    return values


def _verify_reset_archive_merge_followup(
    repo: Path, target_workstream: str, target_packet_path: str,
    source_base: str, landing_commit: str, trace_landing: str,
    trace_main_sync_sha: str | None, trace_ref: str, run_id: str,
    events: list[dict], claim_record: dict, landing_record: dict,
) -> dict:
    """Authenticate the one known archive -> sync merge -> bounded follow-up history."""
    if (target_workstream != _RESET_FOLLOWUP_WORKSTREAM
            or target_packet_path != f"{PACKET_ROOT}/archived/AGENT_EXECUTION_RESET_V1.md"
            or source_base != _RESET_FOLLOWUP_BASE
            or landing_commit != _RESET_FOLLOWUP_ARCHIVE
            or trace_landing != _RESET_FOLLOWUP_HEAD
            or trace_ref != f"refs/remotes/origin/agent-diagnostics/{_RESET_FOLLOWUP_WORKSTREAM}/{_RESET_FOLLOWUP_RUN_ID}"
            or run_id != _RESET_FOLLOWUP_RUN_ID
            or claim_record.get("ref") != trace_ref
            or claim_record.get("run_id") != run_id
            or landing_record.get("ref") != trace_ref
            or landing_record.get("run_id") != run_id
            or claim_record.get("base") != _RESET_FOLLOWUP_BASE
            or claim_record.get("branch") != f"agent/{_RESET_FOLLOWUP_WORKSTREAM}"
            or landing_record.get("branch") != f"agent/{_RESET_FOLLOWUP_WORKSTREAM}"
            or claim_record.get("worktree") != landing_record.get("path")
            or trace_main_sync_sha != _RESET_FOLLOWUP_MERGE_MAIN):
        raise HostValidationError("reset post-merge source span does not match its pinned run and claim identity")

    claim_events = [event for event in events if event.get("event") == "remote_claim_acquired"]
    publish_events = [event for event in events if event.get("event") == "worktree_published"]
    sync_events = [event for event in events if event.get("event") == "main_sync"]
    if (len(claim_events) != 1 or claim_events[0]["data"].get("claim_oid") != _RESET_FOLLOWUP_CLAIM_OID
            or claim_events[0]["data"].get("main_sha") != _RESET_FOLLOWUP_BASE
            or len(publish_events) != 1
            or publish_events[0]["data"].get("branch") != f"agent/{_RESET_FOLLOWUP_WORKSTREAM}"
            or publish_events[0]["data"].get("head") != _RESET_FOLLOWUP_BASE
            or publish_events[0]["data"].get("clean") is not True
            or publish_events[0]["data"].get("worktree") != landing_record.get("path")
            or len(sync_events) != 1
            or sync_events[0]["data"] != {
                "changed": False, "head": _RESET_FOLLOWUP_HEAD,
                "main_sha": _RESET_FOLLOWUP_MERGE_MAIN,
            }):
        raise HostValidationError("reset post-merge source span lacks its unique immutable claim and no-op sync events")

    parents = _git(repo, "rev-list", "--parents", "-n", "1", _RESET_FOLLOWUP_MERGE).split()
    if parents != [_RESET_FOLLOWUP_MERGE, _RESET_FOLLOWUP_ARCHIVE, _RESET_FOLLOWUP_MERGE_MAIN]:
        raise HostValidationError("reset post-merge source span has unexpected synchronization merge parents")
    followup_parent = _git(repo, "rev-parse", f"{_RESET_FOLLOWUP_HEAD}^1")
    if followup_parent != _RESET_FOLLOWUP_MERGE:
        raise HostValidationError("reset post-merge follow-up is not the one pinned child of the sync merge")
    status = subprocess.run(
        ["git", "diff", "--name-status", "--no-renames", _RESET_FOLLOWUP_MERGE,
         _RESET_FOLLOWUP_HEAD], cwd=repo, text=True, capture_output=True,
    )
    if status.returncode:
        raise HostValidationError("cannot inspect reset post-merge follow-up file set")
    rows = [line.split("\t") for line in status.stdout.splitlines()]
    if len(rows) != len(_RESET_FOLLOWUP_PATHS) or any(
        len(row) != 2 or row[0] != "M" for row in rows
    ) or {row[1] for row in rows} != _RESET_FOLLOWUP_PATHS:
        raise HostValidationError("reset post-merge follow-up contains unpinned paths or file operations")
    for path in sorted(_RESET_FOLLOWUP_PATHS):
        for revision in (_RESET_FOLLOWUP_MERGE, _RESET_FOLLOWUP_HEAD):
            entry = subprocess.run(["git", "ls-tree", "-z", revision, "--", path],
                                   cwd=repo, capture_output=True)
            if entry.returncode or not entry.stdout:
                raise HostValidationError("reset post-merge follow-up path is missing from a pinned tree")
            mode = entry.stdout.split(b"\t", 1)[0].split()[0]
            if mode != b"100644":
                raise HostValidationError("reset post-merge follow-up has a non-regular or executable path")
    return {
        "canonical_archive_commit": _RESET_FOLLOWUP_ARCHIVE,
        "sync_merge_commit": _RESET_FOLLOWUP_MERGE,
        "sync_merge_main_parent": _RESET_FOLLOWUP_MERGE_MAIN,
        "post_merge_followup_commit": _RESET_FOLLOWUP_HEAD,
        "followup_paths": sorted(_RESET_FOLLOWUP_PATHS),
        "merge_tree_proof": "exact-content-addressed-merge-and-ordered-parents",
    }


def _verify_archive_sync_followup(
    repo: Path, target_workstream: str, target_packet_text: str,
    landing_commit: str, trace_landing: str, reviewed_main: str, events: list[dict], trace_ref: str,
) -> dict:
    """Prove archive-first sync merges and one declared follow-up across retry races."""
    chain = subprocess.run(
        ["git", "rev-list", "--first-parent", "--reverse", f"{landing_commit}..{trace_landing}"],
        cwd=repo, text=True, capture_output=True,
    )
    if chain.returncode or not chain.stdout.splitlines():
        raise HostValidationError("post-merge source span has no first-parent history after its archive")
    commits = chain.stdout.splitlines()
    merges: list[dict[str, str]] = []
    followup_commits: list[str] = []
    previous = landing_commit
    for commit in commits:
        parents = _git(repo, "rev-list", "--parents", "-n", "1", commit).split()
        if len(parents) == 3 and parents[1] == previous:
            merges.append({"commit": commit, "first_parent": parents[1], "main_sha": parents[2]})
        elif len(parents) == 2 and parents[1] == previous:
            followup_commits.append(commit)
        else:
            raise HostValidationError("post-merge source span has an unbound commit or merge topology")
        previous = commit
    if not followup_commits:
        raise HostValidationError("post-merge source span needs a declared source follow-up")

    conflict_witnesses = _verify_host_import_conflict_merges(
        repo, target_workstream, target_packet_text, landing_commit, trace_landing,
        merges, followup_commits, events, trace_ref,
    )

    sync_events = [(index, event.get("data", {})) for index, event in enumerate(events)
                   if event.get("event") == "main_sync"]
    landing_started = [index for index, event in enumerate(events)
                       if event.get("event") == "landing_started"]
    if len(landing_started) != 1:
        raise HostValidationError("post-merge source trace lacks a unique landing start")
    if not merges:
        direct_tail_witnesses = [(index, data) for index, data in sync_events
                                 if isinstance(data, dict) and data == {
                                     "changed": False, "head": trace_landing,
                                     "main_sha": reviewed_main,
                                 }]
        if (len(sync_events) != 1 or len(direct_tail_witnesses) != 1
                or direct_tail_witnesses[0][0] >= landing_started[0]):
            raise HostValidationError("post-archive source tail lacks its unique exact no-op sync witness")
        witness = direct_tail_witnesses[0][0]
        if any(index >= landing_started[0] for index, _ in sync_events):
            raise HostValidationError("post-archive source trace records sync after landing started")
        return _verify_declared_source_tail(
            repo, target_workstream, target_packet_text, landing_commit, trace_landing,
            followup_commits, reviewed_main, witness,
        )
    expected_sync = []
    for merge_index, merge in enumerate(merges):
        matches = [(index, data) for index, data in sync_events
                   if isinstance(data, dict)
                   and data.get("head") == merge["commit"]
                   and data.get("main_sha") == merge["main_sha"]
                   and (data.get("changed") is True or data.get("changed") is False)]
        if len(matches) > 1:
            raise HostValidationError("post-merge source merge lacks a unique exact main-sync witness")
        if matches:
            expected_sync.append(matches[0][0])
            continue
        if (conflict_witnesses is not None
                and merge["commit"] in conflict_witnesses["blocked_event_indexes"]):
            expected_sync.append(conflict_witnesses["blocked_event_indexes"][merge["commit"]])
            continue
        # The latest main sync may be recorded after its bounded conflict
        # resolution tail. Bind that tail only through one exact immutable
        # no-op event at the authenticated trace tip and latest merge parent.
        final_tip = [(index, data) for index, data in sync_events
                     if isinstance(data, dict) and data == {
                         "changed": False, "head": trace_landing,
                         "main_sha": merge["main_sha"],
                     }]
        if (merge_index != len(merges) - 1 or len(final_tip) != 1):
            raise HostValidationError("post-merge source merge lacks a unique exact main-sync witness")
        expected_sync.append(final_tip[0][0])
    if expected_sync != sorted(expected_sync) or expected_sync[-1] >= landing_started[0]:
        raise HostValidationError("post-merge source sync events are out of lifecycle order")
    if any(index >= landing_started[0] for index, _ in sync_events):
        raise HostValidationError("post-merge source trace records sync after landing started")

    # No-op retries may occur at an authenticated current tip in this same
    # lineage, but may not name a stale merge, arbitrary head, or main SHA.
    final_tip_index = None
    if expected_sync and not any(
        isinstance(data, dict)
        and data.get("head") == merges[-1]["commit"]
        and data.get("main_sha") == merges[-1]["main_sha"]
        and (data.get("changed") is True or data.get("changed") is False)
        for _, data in sync_events
    ):
        final_tip_index = expected_sync[-1]
    for index, data in sync_events:
        if index in expected_sync:
            continue
        if index == final_tip_index:
            continue
        prior_merges = [merge_index for merge_index, sync_index in enumerate(expected_sync)
                        if sync_index < index]
        if not isinstance(data, dict) or not prior_merges or index >= landing_started[0]:
            raise HostValidationError("post-merge source span has an unbound no-op main-sync event")
        latest = prior_merges[-1]
        latest_commit_index = commits.index(merges[latest]["commit"])
        next_merge_index = (commits.index(merges[latest + 1]["commit"])
                            if latest + 1 < len(merges) else len(commits))
        allowed_heads = set(commits[latest_commit_index:next_merge_index])
        if (data.get("changed") is not False or data.get("head") not in allowed_heads
                or data.get("main_sha") != merges[latest]["main_sha"]):
            raise HostValidationError("post-merge source no-op event does not bind the current sync tip")
    final_parents = _git(repo, "rev-list", "--parents", "-n", "1", trace_landing).split()
    if len(final_parents) == 2:
        final_retry = [(index, data) for index, data in sync_events
                       if isinstance(data, dict) and data == {
                           "changed": False, "head": trace_landing,
                           "main_sha": merges[-1]["main_sha"]}]
        if (len(final_retry) != 1 or final_retry[0][0] >= landing_started[0]
                or (final_tip_index is not None and final_retry[0][0] != final_tip_index)):
            raise HostValidationError("post-merge source span lacks its final no-op retry witness")
    previous_sync_index = -1
    for merge, index in zip(merges, expected_sync):
        if index <= previous_sync_index:
            raise HostValidationError("post-merge source sync merges are out of trace order")
        previous_sync_index = index
        expected_tree = subprocess.run(
            ["git", "merge-tree", "--write-tree", merge["first_parent"], merge["main_sha"]],
            cwd=repo, text=True, capture_output=True,
        )
        actual_tree = _git(repo, "rev-parse", f"{merge['commit']}^{{tree}}")
        expected_tree_sha = expected_tree.stdout.splitlines()[0].strip() if expected_tree.stdout.splitlines() else None
        if not expected_tree_sha:
            raise HostValidationError("post-merge sync tree has no deterministic merge-tree result")
        if expected_tree.returncode or expected_tree_sha != actual_tree:
            if (conflict_witnesses is not None
                    and merge["commit"] in conflict_witnesses["blocked_event_indexes"]):
                # This exact historical merge's conflict result, parents, tree,
                # and complete resolution delta were authenticated above.
                continue
            resolution_paths = set(_changed_paths(repo, f"{expected_tree_sha}..{actual_tree}"))
            readme_path = f"{PACKET_ROOT}/README.md"
            first_readme = subprocess.run(["git", "show", f"{merge['first_parent']}:{readme_path}"],
                                          cwd=repo, capture_output=True)
            main_readme = subprocess.run(["git", "show", f"{merge['main_sha']}:{readme_path}"],
                                         cwd=repo, capture_output=True)
            merged_readme = subprocess.run(["git", "show", f"{merge['commit']}:{readme_path}"],
                                           cwd=repo, capture_output=True)
            if (resolution_paths != {readme_path} or first_readme.returncode
                    or main_readme.returncode or merged_readme.returncode
                    or not _managed_packet_index_additive_reconciliation(
                        first_readme.stdout, main_readme.stdout, merged_readme.stdout)):
                raise HostValidationError(
                    "post-merge sync differs from deterministic merge beyond additive managed-index "
                    f"reconciliation: {merge['commit']}"
                )

    packet_header = target_packet_text.split("\n## ", 1)[0].splitlines()
    work_surface_lines = []
    for index, line in enumerate(packet_header):
        if not re.match(r"^-\s*Work surface:\s*", line):
            continue
        work_surface_lines.append(re.sub(r"^-\s*Work surface:\s*", "", line))
        for continuation in packet_header[index + 1:]:
            if re.match(r"^-\s*[A-Z][^:]*:\s*", continuation):
                break
            if continuation.startswith((" ", "\t")):
                work_surface_lines.append(continuation.strip())
        break
    work_surface = " ".join(work_surface_lines)
    declared = {token for token in re.findall(r"`([^`]+)`", work_surface)
                if token.startswith("custodian/") and "{" not in token and "}" not in token}
    declared.update(_expand_braced_work_surface_paths(work_surface))
    followup_paths: set[str] = set()
    for commit in followup_commits:
        parent = _git(repo, "rev-parse", f"{commit}^1")
        status = subprocess.run(["git", "diff", "--name-status", "--no-renames", parent, commit],
                                cwd=repo, text=True, capture_output=True)
        if status.returncode:
            raise HostValidationError("cannot inspect post-merge follow-up file operations")
        rows = [line.split("\t") for line in status.stdout.splitlines()]
        authenticated_followup_paths = (
            set(conflict_witnesses["followup_paths"])
            if conflict_witnesses is not None else set()
        )
        if (not rows or any(len(row) != 2 or row[0] != "M"
                            or (row[1] not in declared
                                and row[1] not in authenticated_followup_paths) for row in rows)):
            raise HostValidationError("post-merge follow-up has undeclared paths or non-modification operations")
        for _, path in rows:
            for revision in (parent, commit):
                entry = subprocess.run(["git", "ls-tree", "-z", revision, "--", path],
                                       cwd=repo, capture_output=True)
                if entry.returncode or not entry.stdout:
                    raise HostValidationError("post-merge follow-up path is missing from a pinned tree")
                mode = entry.stdout.split(b"\t", 1)[0].split()[0]
                if mode != b"100644":
                    raise HostValidationError("post-merge follow-up contains a non-regular or executable path")
            followup_paths.add(path)
    if not _source_code_paths(sorted(followup_paths)):
        raise HostValidationError("post-merge follow-up has no declared implementation or test source")
    return {
        "canonical_archive_commit": landing_commit,
        "sync_merges": merges,
        "sync_merge_commit": merges[0]["commit"] if merges else None,
        "sync_merge_main_parent": merges[0]["main_sha"] if merges else None,
        "post_merge_followup_commit": followup_commits[0],
        "post_merge_followup_commits": followup_commits,
        "source_head": trace_landing,
        "followup_paths": sorted(followup_paths),
        "authenticated_followup_paths": (
            conflict_witnesses["followup_paths"] if conflict_witnesses is not None else []
        ),
        "authenticated_merge_paths": (
            conflict_witnesses["merge_delta_paths"] if conflict_witnesses is not None else {}
        ),
        "merge_tree_proof": "exact-trace-parent-and-bounded-declared-follow-up",
    }


def _verify_declared_source_tail(
    repo: Path, target_workstream: str, target_packet_text: str,
    landing_commit: str, trace_landing: str, followup_commits: list[str],
    reviewed_main: str, witness_index: int,
) -> dict:
    """Prove a linear declared source tail directly after an archive commit."""
    packet_header = target_packet_text.split("\n## ", 1)[0].splitlines()
    work_surface_lines = []
    for index, line in enumerate(packet_header):
        if not re.match(r"^-\s*Work surface:\s*", line):
            continue
        work_surface_lines.append(re.sub(r"^-\s*Work surface:\s*", "", line))
        for continuation in packet_header[index + 1:]:
            if re.match(r"^-\s*[A-Z][^:]*:\s*", continuation):
                break
            if continuation.startswith((" ", "\t")):
                work_surface_lines.append(continuation.strip())
        break
    declared = {token for token in re.findall(r"`([^`]+)`", " ".join(work_surface_lines))
                if token.startswith("custodian/") and "{" not in token and "}" not in token}
    declared.update(_expand_braced_work_surface_paths(" ".join(work_surface_lines)))
    followup_paths: set[str] = set()
    for commit in followup_commits:
        parent = _git(repo, "rev-parse", f"{commit}^1")
        status = subprocess.run(["git", "diff", "--name-status", "--no-renames", parent, commit],
                                cwd=repo, text=True, capture_output=True)
        if status.returncode:
            raise HostValidationError("cannot inspect post-archive source follow-up file operations")
        rows = [line.split("\t") for line in status.stdout.splitlines()]
        if not rows or any(len(row) != 2 or row[0] != "M" or row[1] not in declared for row in rows):
            raise HostValidationError("post-archive source tail has undeclared paths or non-modification operations")
        for _, path in rows:
            for revision in (parent, commit):
                entry = subprocess.run(["git", "ls-tree", "-z", revision, "--", path],
                                       cwd=repo, capture_output=True)
                if entry.returncode or not entry.stdout \
                        or entry.stdout.split(b"\t", 1)[0].split()[0] != b"100644":
                    raise HostValidationError("post-archive source tail contains missing or non-regular paths")
            followup_paths.add(path)
    if not _source_code_paths(sorted(followup_paths)):
        raise HostValidationError("post-archive source tail has no declared implementation or test source")
    return {
        "canonical_archive_commit": landing_commit,
        "sync_merges": [],
        "sync_merge_commit": None,
        "sync_merge_main_parent": None,
        "post_merge_followup_commit": followup_commits[0],
        "post_merge_followup_commits": followup_commits,
        "source_head": trace_landing,
        "followup_paths": sorted(followup_paths),
        "main_sync_event_index": witness_index,
        "main_sync_sha": reviewed_main,
        "merge_tree_proof": "linear-archive-follow-up-exact-noop-tip-witness",
    }


def _verified_blender_source_artifact(repo: Path, landing_commit: str,
                                      target_packet_text: str,
                                      extra_archive_paths: set[str]) -> dict | None:
    if _BLENDER_SOURCE_PATH not in extra_archive_paths:
        return None
    if landing_commit != _BLENDER_SOURCE_ARCHIVE:
        raise HostValidationError("Blender source artifact is not from its exact pinned archive")
    work_surface = header_field(target_packet_text, "Work surface") or ""
    if (_BLENDER_SOURCE_ROOT not in work_surface
            or "operator_south_cutout_rig_v1.blend" not in target_packet_text
            or _BLENDER_RECEIPT_PATH not in extra_archive_paths):
        raise HostValidationError("Blender source artifact is outside its packet-declared source-work contract")
    for revision in (_BLENDER_SOURCE_ARCHIVE,):
        entry = subprocess.run(["git", "ls-tree", "-z", revision, "--", _BLENDER_SOURCE_PATH],
                               cwd=repo, capture_output=True)
        if entry.returncode or not entry.stdout or entry.stdout.split(b"\t", 1)[0].split()[0] != b"100644":
            raise HostValidationError("Blender source artifact is not a tracked regular archive file")
    pointer = _git(repo, "show", f"{_BLENDER_SOURCE_ARCHIVE}:{_BLENDER_SOURCE_PATH}")
    pointer_match = re.fullmatch(
        r"version https://git-lfs.github.com/spec/v1\noid sha256:([0-9a-f]{64})\nsize ([0-9]+)\n?",
        pointer,
    )
    try:
        receipt = json.loads(_git(repo, "show", f"{_BLENDER_SOURCE_ARCHIVE}:{_BLENDER_RECEIPT_PATH}"))
    except (HostValidationError, json.JSONDecodeError) as exc:
        raise HostValidationError("Blender source artifact receipt is missing or malformed") from exc
    if (pointer_match is None or pointer_match.group(1) != _BLENDER_SOURCE_OID
            or not isinstance(receipt, dict)
            or receipt.get("schema") != "custodian.operator_motion_foundry.blender_rig_receipt.v1"
            or receipt.get("status") != "candidate_not_art_approved"
            or receipt.get("blend_sha256") != _BLENDER_SOURCE_OID):
        raise HostValidationError("Blender source artifact does not match its exact LFS and receipt evidence")
    return {
        "path": _BLENDER_SOURCE_PATH,
        "archive_commit": _BLENDER_SOURCE_ARCHIVE,
        "lfs_sha256": _BLENDER_SOURCE_OID,
        "receipt_path": _BLENDER_RECEIPT_PATH,
        "receipt_blob": _git(repo, "rev-parse", f"{_BLENDER_SOURCE_ARCHIVE}:{_BLENDER_RECEIPT_PATH}"),
    }


def _changed_paths(repo: Path, revision: str) -> list[str]:
    result = subprocess.run(["git", "diff", "--name-only", "--no-renames", revision], cwd=repo,
                            text=True, capture_output=True)
    if result.returncode:
        raise HostValidationError(result.stderr.strip() or "could not enumerate source-span paths")
    return sorted({path for path in result.stdout.splitlines() if path})


def _source_code_paths(paths: list[str]) -> set[str]:
    return {path for path in paths if Path(path).suffix.lower() in _IMPLEMENTATION_SUFFIXES}


def _trace_events(repo: Path, ref: str) -> list[dict]:
    result = subprocess.run(["git", "show", f"{ref}:trace.jsonl"], cwd=repo,
                            text=True, capture_output=True)
    if result.returncode:
        raise HostValidationError(f"source-span workstream trace is unreadable: {ref}")
    events = []
    try:
        for line in result.stdout.splitlines():
            value = json.loads(line)
            if not isinstance(value, dict):
                raise ValueError("event is not an object")
            events.append(value)
    except (json.JSONDecodeError, ValueError) as exc:
        raise HostValidationError(f"source-span workstream trace is malformed: {ref}") from exc
    if not events:
        raise HostValidationError(f"source-span workstream trace is empty: {ref}")
    if any(event.get("schema") != "custodian.workflow_trace_event.v1"
           or event.get("schema_version") != 1
           or not isinstance(event.get("data"), dict) for event in events):
        raise HostValidationError(f"source-span workstream trace has invalid event provenance: {ref}")
    return events


def _verified_landing_claim(repo: Path, event: dict, workstream: str,
                            landing_run_id: str, selected_base: str) -> bool:
    """Verify a claim event preserved in a landing trace, including retries."""
    data = event.get("data")
    if (event.get("run_id") != landing_run_id or event.get("workstream") != workstream
            or not isinstance(data, dict)):
        return False
    base = data.get("main_sha")
    claim_oid = data.get("claim_oid")
    if (not isinstance(base, str) or not re.fullmatch(r"[0-9a-f]{40,64}", base)
            or not isinstance(claim_oid, str) or not re.fullmatch(r"[0-9a-f]{40,64}", claim_oid)
            or data.get("local_ref") != f"refs/custodian/claims/{workstream}/{landing_run_id}"
            or data.get("remote_ref") != f"refs/heads/dispatch-claims/{workstream}"):
        return False
    resolved = subprocess.run(["git", "rev-parse", "--verify", f"{claim_oid}^{{commit}}"],
                              cwd=repo, text=True, capture_output=True)
    if resolved.returncode or resolved.stdout.strip() != claim_oid:
        return False
    parents = subprocess.run(["git", "rev-list", "--parents", "-n", "1", claim_oid],
                             cwd=repo, text=True, capture_output=True)
    fields = parents.stdout.split()
    if parents.returncode or len(fields) != 2 or fields[1] != base:
        return False
    subject = subprocess.run(["git", "show", "-s", "--format=%s", claim_oid],
                             cwd=repo, text=True, capture_output=True)
    expected_subject = re.compile(
        rf"^workstream claim {re.escape(workstream)} [^:\s]+:[0-9]+:{re.escape(landing_run_id)}$"
    )
    if subject.returncode or not expected_subject.fullmatch(subject.stdout.rstrip()):
        return False
    return subprocess.run(["git", "merge-base", "--is-ancestor", base, selected_base],
                          cwd=repo, capture_output=True).returncode == 0


def _git_tree_entry(repo: Path, revision: str, path: str) -> tuple[str, str] | None:
    result = subprocess.run(["git", "ls-tree", revision, "--", path], cwd=repo,
                            text=True, capture_output=True)
    if result.returncode:
        raise HostValidationError(f"cannot inspect pinned Git tree entry: {path}")
    fields = result.stdout.rstrip("\n").split("\t", 1)
    if len(fields) != 2 or fields[1] != path:
        return None
    mode_type_sha = fields[0].split()
    if len(mode_type_sha) != 3:
        raise HostValidationError(f"malformed pinned Git tree entry: {path}")
    return mode_type_sha[0], mode_type_sha[2]


def _canonical_review_packet_metadata_path(
    repo: Path, archive_parent: str, landing_commit: str, target_workstream: str,
    target_packet_path: str, target_packet_text: str, changed_paths: set[str],
) -> str | None:
    """Authenticate only the associated review packet's canonical chat-link closeout."""
    if target_workstream != _RESUMED_PROVENANCE_WORKSTREAM:
        return None
    review_workstream = f"review-{target_workstream}"
    review_name = f"REVIEW_{target_workstream.upper().replace('-', '_')}.md"
    review_path = f"{PACKET_ROOT}/{review_name}"
    if review_path not in changed_paths:
        return None

    active_packet = target_packet_path.replace("/archived/", "/", 1)
    active_entry = _git_tree_entry(repo, archive_parent, active_packet)
    archived_entry = _git_tree_entry(repo, landing_commit, target_packet_path)
    before_entry = _git_tree_entry(repo, archive_parent, review_path)
    after_entry = _git_tree_entry(repo, landing_commit, review_path)
    if (active_entry is None or active_entry[0] != "100644"
            or archived_entry is None or archived_entry[0] != "100644"
            or before_entry is None or before_entry[0] != "100644"
            or after_entry is None or after_entry[0] != "100644"):
        raise HostValidationError("canonical paired-review metadata path or mode is invalid")

    summary_path = f"{target_workstream.upper().replace('-', '_')}_CLAUDE_SUMMARY.md"
    summary_entry = _git_tree_entry(repo, landing_commit, summary_path)
    if summary_entry is None or summary_entry[0] != "100644":
        raise HostValidationError("canonical paired-review metadata lacks its regular closeout summary")
    active_text = _git(repo, "show", f"{archive_parent}:{active_packet}")
    summary_text = _git(repo, "show", f"{landing_commit}:{summary_path}")
    before = _git(repo, "show", f"{archive_parent}:{review_path}").encode("utf-8")
    after = _git(repo, "show", f"{landing_commit}:{review_path}").encode("utf-8")
    summary_urls = re.findall(r"(?m)^-? ?Authoring chat: (https://\S+)$", summary_text)
    canonical_url = summary_urls[0] if summary_urls and len(set(summary_urls)) == 1 else None
    active_authoring_chat = header_field(active_text, "Authoring chat")
    archived_authoring_chat = header_field(target_packet_text, "Authoring chat")
    if (header_field(active_text, "Workstream") != target_workstream
            or header_field(target_packet_text, "Workstream") != target_workstream
            or not canonical_url
            or active_authoring_chat not in {"not-recorded", canonical_url}
            or archived_authoring_chat != canonical_url):
        raise HostValidationError("implementation archive and summary disagree on canonical review metadata")

    expected_review_identity = {
        "Workstream": review_workstream,
        "Review target workstream": target_workstream,
        "Review target packet": target_packet_path,
        "Reviewed main": header_field(target_packet_text, "Reviewed main"),
    }
    if any(not value or header_field(before.decode("utf-8"), field) != value
           or header_field(after.decode("utf-8"), field) != value
           for field, value in expected_review_identity.items()):
        raise HostValidationError("changed Markdown is not the exact paired review packet")

    old_field = b"- Authoring chat: `not-recorded`"
    new_field = f"- Authoring chat: `{canonical_url}`".encode("utf-8")
    if before.count(old_field) != 2 or after != before.replace(old_field, new_field):
        raise HostValidationError("paired-review archive changes fields beyond canonical authoring chat metadata")
    return review_path


def _is_ancestor(repo: Path, ancestor: str, descendant: str) -> bool:
    return subprocess.run(["git", "merge-base", "--is-ancestor", ancestor, descendant],
                          cwd=repo, capture_output=True).returncode == 0


def _source_path_documented(path: str, target_packet_text: str, documented: set[str],
                            packet_terms: set[str], uid_companion_paths: set[str],
                            attested_scope_paths: set[str]) -> bool:
    """Check exact documented source identity, including only verified attestation paths."""
    if path in uid_companion_paths:
        return _source_path_documented(path[:-4], target_packet_text, documented,
                                       packet_terms, uid_companion_paths, attested_scope_paths)
    if path in attested_scope_paths:
        return True
    name = Path(path).name
    if path in documented or name in target_packet_text:
        return True
    if name.startswith("test_") and re.search(r"\b(test|tests|fixture)\b", target_packet_text, re.I):
        terms = set(re.findall(r"[a-z0-9]+", Path(name).stem.lower())) - {"test", "tests", "v1"}
        return len(terms & packet_terms) >= 2
    return False


def _scope_review_receipt(review_text: str) -> dict[str, str] | None:
    """Parse one flat reviewer-authored PASS receipt from the archived review packet."""
    sections = list(re.finditer(r"(?m)^## Independent Review[ \t]*$", review_text))
    if len(sections) != 1:
        return None
    section = review_text[sections[0].end():]
    following = re.search(r"(?m)^## [^\r]*$", section)
    if following:
        section = section[:following.start()]
    names = (
        "Schema", "Review workstream", "Review target workstream", "Status",
        "Blocking defects", "Material gaps", "Reviewer context", "Reviewer provenance",
        "Reviewed main", "Reviewed implementation commit",
    )
    values = {}
    for name in names:
        matches = re.findall(rf"(?m)^- {re.escape(name)}: `([^`\r\n]+)`\s*$", section)
        if len(matches) != 1:
            return None
        values[name] = matches[0].strip()
    return values


def _verified_grunt_scope_attestation(repo: Path, reviewed_main: str,
                                     extra_archive_paths: set[str]) -> dict:
    """Verify the one exact Grunt post-hoc Markdown exception and its accepted review.

    The JSON is intentionally not self-authorizing. Its correction must have an
    archived, canonical independent PASS, with the review's target receipt and
    implementation identity both verified from Git history.
    """
    attested_archive_paths = extra_archive_paths.intersection(_GRUNT_SCOPE_FILES)
    if attested_archive_paths != set(_GRUNT_SCOPE_FILES):
        raise HostValidationError("post-hoc Grunt scope attestation does not cover all six historical paths")

    source_packet_entry = _git_tree_entry(repo, _GRUNT_SCOPE_SOURCE_ARCHIVE,
                                          _GRUNT_SCOPE_SOURCE_PACKET)
    if source_packet_entry != ("100644", _GRUNT_SCOPE_SOURCE_PACKET_BLOB):
        raise HostValidationError("pinned original Grunt packet blob or mode does not match")
    source_entries = {}
    for path, expected_blob in _GRUNT_SCOPE_FILES.items():
        entry = _git_tree_entry(repo, _GRUNT_SCOPE_SOURCE_ARCHIVE, path)
        if entry != ("100644", expected_blob):
            raise HostValidationError(f"pinned historical Grunt Markdown blob or mode does not match: {path}")
        source_entries[path] = {"mode": entry[0], "blob": entry[1]}

    attestation_entry = _git_tree_entry(repo, reviewed_main, _GRUNT_SCOPE_ATTESTATION_PATH)
    if attestation_entry is None or attestation_entry[0] != "100644":
        raise HostValidationError("reviewed main lacks the regular-file Grunt scope attestation")
    try:
        attestation_bytes = subprocess.run(
            ["git", "show", f"{reviewed_main}:{_GRUNT_SCOPE_ATTESTATION_PATH}"],
            cwd=repo, capture_output=True, check=True,
        ).stdout
        attestation = json.loads(attestation_bytes)
    except (subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        raise HostValidationError("Grunt scope attestation is unreadable or invalid JSON") from exc
    expected_attestation = {
        "schema": "custodian.review_source_scope_attestation.v1",
        "source_workstream": _GRUNT_SCOPE_SOURCE_WORKSTREAM,
        "source_archive_commit": _GRUNT_SCOPE_SOURCE_ARCHIVE,
        "source_packet_path": _GRUNT_SCOPE_SOURCE_PACKET,
        "source_packet_blob": _GRUNT_SCOPE_SOURCE_PACKET_BLOB,
        "source_files": [
            {"path": path, "blob": blob, "mode": "100644"}
            for path, blob in sorted(_GRUNT_SCOPE_FILES.items())
        ],
        "reason": "The original archived Work surface omitted these exact Grunt raster paths.",
        "post_hoc": True,
    }
    canonical_bytes = (json.dumps(expected_attestation, indent=2, sort_keys=True) + "\n").encode("utf-8")
    if attestation != expected_attestation or attestation_bytes != canonical_bytes:
        raise HostValidationError("Grunt scope attestation bytes do not match the exact post-hoc authorization")

    origin_result = subprocess.run(
        ["git", "log", "--format=%H", reviewed_main, "--",
         _GRUNT_SCOPE_ATTESTATION_PATH], cwd=repo, text=True, capture_output=True,
    )
    if origin_result.returncode:
        raise HostValidationError("cannot resolve Grunt scope attestation origin commit")
    origins = [commit for commit in origin_result.stdout.splitlines()
               if _git_tree_entry(repo, commit, _GRUNT_SCOPE_ATTESTATION_PATH) == attestation_entry]
    if len(origins) != 1:
        raise HostValidationError("Grunt scope attestation has missing or ambiguous exact-blob origin history")
    origin_commit = origins[0]

    # The correction review is the sole activating authority. Validate both
    # reviewer outcome and the separately appended target receipt using the
    # repository's canonical parsers and receipt-delta verifier.
    try:
        correction_text = read_git_text(repo, reviewed_main, _GRUNT_SCOPE_CORRECTION_PACKET)
        review_text = read_git_text(repo, reviewed_main, _GRUNT_SCOPE_REVIEW_PACKET)
    except ValueError as exc:
        raise HostValidationError("Grunt scope attestation lacks archived correction review evidence") from exc
    correction = parse_packet(_GRUNT_SCOPE_CORRECTION_PACKET, correction_text)
    review = parse_packet(_GRUNT_SCOPE_REVIEW_PACKET, review_text)
    if (correction.error or correction.kind not in {"implementation", "correction"}
            or correction.status != "complete"
            or correction.workstream != _GRUNT_SCOPE_CORRECTION_WORKSTREAM
            or review.error or review.kind != "review" or review.status != "complete"
            or review.workstream != _GRUNT_SCOPE_REVIEW_WORKSTREAM
            or review.review_target_workstream != _GRUNT_SCOPE_CORRECTION_WORKSTREAM
            or review.review_target_packet != _GRUNT_SCOPE_CORRECTION_PACKET):
        raise HostValidationError("Grunt scope attestation correction/review packet identity is incomplete")

    outcome, outcome_error = review_outcome.parse_review_outcome(review_text)
    if outcome_error or outcome is None or outcome.get("Outcome") != "passed":
        raise HostValidationError("Grunt scope attestation has no canonical independent PASS outcome")
    accepted, _, acceptance_reason = review_outcome.review_acceptance(
        review_text, correction_text, _GRUNT_SCOPE_REVIEW_WORKSTREAM,
    )
    if not accepted:
        raise HostValidationError(f"Grunt scope attestation review is not accepted: {acceptance_reason}")
    review_baseline = read_git_text(repo, outcome["Reviewed main"], _GRUNT_SCOPE_CORRECTION_PACKET)
    implementation_commit, identity_error = resolve_target_implementation_commit(
        repo, outcome["Reviewed main"], _GRUNT_SCOPE_CORRECTION_PACKET,
        _GRUNT_SCOPE_CORRECTION_WORKSTREAM, review_baseline,
    )
    if identity_error:
        raise HostValidationError(f"Grunt scope attestation target identity is invalid: {identity_error}")
    if not _is_ancestor(repo, origin_commit, implementation_commit):
        raise HostValidationError("Grunt scope attestation was not present by its correction archive")
    if not _is_ancestor(repo, outcome["Reviewed main"], reviewed_main):
        raise HostValidationError("accepted Grunt attestation review is not an ancestor of reviewed main")
    if not _is_ancestor(repo, implementation_commit, outcome["Reviewed main"]):
        raise HostValidationError("accepted attestation review predates the correction implementation")
    receipt, receipt_error = verify_review_receipt_delta(
        review_baseline, correction_text, review_workstream=_GRUNT_SCOPE_REVIEW_WORKSTREAM,
        target_workstream=_GRUNT_SCOPE_CORRECTION_WORKSTREAM,
        reviewed_main=outcome["Reviewed main"], target_implementation_commit=implementation_commit,
    )
    if receipt_error or not receipt:
        raise HostValidationError(f"accepted Grunt attestation review target receipt is invalid: {receipt_error}")
    identity_error = review_outcome.outcome_identity_error(
        outcome, review_workstream=_GRUNT_SCOPE_REVIEW_WORKSTREAM,
        target_workstream=_GRUNT_SCOPE_CORRECTION_WORKSTREAM,
        reviewed_main=outcome["Reviewed main"], implementation_commit=implementation_commit,
        run_id=outcome["Run ID"], review_cycle=review.review_cycle,
    )
    if identity_error:
        raise HostValidationError(f"accepted Grunt attestation review identity is invalid: {identity_error}")
    reviewer_receipt = _scope_review_receipt(review_text)
    if reviewer_receipt is None:
        raise HostValidationError("accepted Grunt attestation review lacks one canonical reviewer receipt")
    expected_receipt = {
        "Schema": "custodian.paired_review.v1",
        "Review workstream": _GRUNT_SCOPE_REVIEW_WORKSTREAM,
        "Review target workstream": _GRUNT_SCOPE_CORRECTION_WORKSTREAM,
        "Status": "passed", "Blocking defects": "0", "Material gaps": "0",
        "Reviewer context": "fresh", "Reviewed main": outcome["Reviewed main"],
        "Reviewed implementation commit": implementation_commit,
    }
    if any(reviewer_receipt.get(field) != value for field, value in expected_receipt.items()) or (
        reviewer_receipt.get("Reviewer provenance") not in {"different-agent", "same-agent-fresh-context"}
    ):
        raise HostValidationError("accepted Grunt attestation reviewer receipt does not match its PASS outcome")

    return {
        "kind": "accepted-post-hoc-exact-markdown-attestation",
        "attestation_path": _GRUNT_SCOPE_ATTESTATION_PATH,
        "attestation_commit": origin_commit,
        "attestation_blob": attestation_entry[1],
        "attestation_sha256": _sha256(attestation_bytes),
        "source_archive_commit": _GRUNT_SCOPE_SOURCE_ARCHIVE,
        "source_packet_blob": _GRUNT_SCOPE_SOURCE_PACKET_BLOB,
        "source_files": source_entries,
        "approval_review_workstream": _GRUNT_SCOPE_REVIEW_WORKSTREAM,
        "approval_review_packet": _GRUNT_SCOPE_REVIEW_PACKET,
        "approval_review_packet_blob": _git_tree_entry(
            repo, reviewed_main, _GRUNT_SCOPE_REVIEW_PACKET,
        )[1],
        "approval_target_packet": _GRUNT_SCOPE_CORRECTION_PACKET,
        "approval_target_packet_blob": _git_tree_entry(
            repo, reviewed_main, _GRUNT_SCOPE_CORRECTION_PACKET,
        )[1],
        "approval_reviewed_main": outcome["Reviewed main"],
        "approval_run_id": outcome["Run ID"],
        "approval_implementation_commit": implementation_commit,
        "approval_outcome": outcome["Outcome"],
    }


def _verify_exact_bootstrap_landing(
    repo: Path, landing_commit: str, parent: str, tree: str,
    active_packet: str, active_blob: str, archive_blobs: dict[str, str],
) -> None:
    """Authenticate complete historical source bytes without granting review PASS."""
    if _git(repo, "rev-list", "--parents", "-n", "1", landing_commit).split() != [
        landing_commit, parent,
    ]:
        raise HostValidationError("bootstrap archive parent does not match pinned history")
    if _git(repo, "rev-parse", f"{landing_commit}^{{tree}}") != tree:
        raise HostValidationError("bootstrap archive tree does not match pinned history")
    if set(_changed_paths(repo, f"{parent}..{landing_commit}")) != (
        set(archive_blobs) | {active_packet}
    ):
        raise HostValidationError("bootstrap archive changed-path set differs from pinned history")
    if (_git_tree_entry(repo, parent, active_packet) != ("100644", active_blob)
            or _git_tree_entry(repo, landing_commit, active_packet) is not None):
        raise HostValidationError("bootstrap original packet or deletion differs")
    for path, blob in archive_blobs.items():
        if _git_tree_entry(repo, landing_commit, path) != ("100644", blob):
            raise HostValidationError(f"bootstrap archive blob or mode differs: {path}")


def _verified_procession_recovery_historical_scope(
    repo: Path, target_workstream: str, target_packet_path: str,
    landing_commit: str, extra_archive_paths: set[str],
) -> set[str]:
    """Authenticate only the exact five extra files at the original Procession landing."""
    if target_workstream != _PROCESSION_SCOPE_CORRECTION_WORKSTREAM:
        return set()
    if (landing_commit != _PROCESSION_RECOVERY_ARCHIVE
            or target_packet_path != _PROCESSION_SCOPE_CORRECTION_PACKET
            or extra_archive_paths != _PROCESSION_RECOVERY_EXTRA_FILES):
        raise HostValidationError("Procession recovery historical source scope does not match its exact archive")
    _verify_exact_bootstrap_landing(
        repo, landing_commit, _PROCESSION_RECOVERY_PARENT, _PROCESSION_RECOVERY_TREE,
        f"{PACKET_ROOT}/AGENT_PAIRED_REVIEW_PROCESSION_DOC_SCOPE_RECOVERY_V1.md",
        _PROCESSION_RECOVERY_ACTIVE_BLOB, _PROCESSION_RECOVERY_ARCHIVE_BLOBS,
    )
    return set(_PROCESSION_RECOVERY_UNDECLARED_FILES)


def _verified_procession_bootstrap_main_sync(
    repo: Path, target_workstream: str, landing_commit: str,
    merge: str, second_parent: str, changed_source_paths: set[str],
) -> bool:
    """One historical source reconciliation; not a source-coverage or review waiver.

    The original Procession archive is already independently authenticated. Its
    exact recorded main-sync commit combined the source with newer upstream
    validator/tests. Only the three pinned resulting file blobs are recognized.
    The reviewer must still validate the resulting reviewed-main source.
    """
    if target_workstream != _PROCESSION_SCOPE_CORRECTION_WORKSTREAM:
        return False
    if (landing_commit != _PROCESSION_RECOVERY_ARCHIVE
            or merge != _PROCESSION_RECOVERY_MERGE
            or second_parent != _PROCESSION_RECOVERY_MERGE_SECOND_PARENT
            or changed_source_paths != set(_PROCESSION_RECOVERY_MERGED_SOURCE_BLOBS)):
        return False
    if _git(repo, "rev-list", "--parents", "-n", "1", merge).split() != [
        merge, landing_commit, second_parent,
    ]:
        raise HostValidationError("Procession bootstrap main-sync parent identity differs")
    if _git(repo, "rev-parse", f"{merge}^{{tree}}") != _PROCESSION_RECOVERY_MERGE_TREE:
        raise HostValidationError("Procession bootstrap main-sync tree identity differs")
    for path, blob in _PROCESSION_RECOVERY_MERGED_SOURCE_BLOBS.items():
        if _git_tree_entry(repo, merge, path) != ("100644", blob):
            raise HostValidationError(f"Procession bootstrap merge source differs: {path}")
    return True


def _verified_or1_bootstrap_historical_scope(
    repo: Path, target_workstream: str, target_packet_path: str,
    landing_commit: str, extra_archive_paths: set[str],
) -> set[str]:
    """Authenticate only OR1's two historical undeclared documentation paths."""
    if target_workstream != _OR1_BOOTSTRAP_WORKSTREAM:
        return set()
    if (landing_commit != _OR1_BOOTSTRAP_ARCHIVE
            or target_packet_path != _OR1_BOOTSTRAP_PACKET
            or extra_archive_paths != set(_OR1_BOOTSTRAP_EXTRA_BLOBS)):
        raise HostValidationError("OR1 historical source scope does not match its exact archive")
    _verify_exact_bootstrap_landing(
        repo, landing_commit, _OR1_BOOTSTRAP_PARENT, _OR1_BOOTSTRAP_TREE,
        f"{PACKET_ROOT}/AGENT_ORPHAN_RECOVERY_OBSERVABILITY_V1.md",
        _OR1_BOOTSTRAP_ACTIVE_BLOB, _OR1_BOOTSTRAP_ARCHIVE_BLOBS,
    )
    return set(_OR1_BOOTSTRAP_DOCS)


def _verified_procession_scope_attestation(repo: Path, reviewed_main: str,
                                          landing_commit: str,
                                          extra_archive_paths: set[str]) -> dict:
    """Authenticate only the omitted P1 validation recipe after its paired PASS.

    This is deliberately tied to the single preserved Procession archive. The
    approval may postdate that run's pinned reviewed-main, but current
    origin/main is usable only after proving the pin is its ancestor and the
    exact recovery implementation has an accepted canonical independent PASS.
    """
    if landing_commit != _PROCESSION_SCOPE_SOURCE_ARCHIVE:
        raise HostValidationError("Procession scope attestation names a different source archive")
    if extra_archive_paths != set(_PROCESSION_SCOPE_SOURCE_FILES):
        raise HostValidationError("Procession scope attestation must cover exactly the eight pinned P1 source files")

    source_packet_entry = _git_tree_entry(repo, _PROCESSION_SCOPE_SOURCE_ARCHIVE,
                                          _PROCESSION_SCOPE_SOURCE_PACKET)
    if source_packet_entry != ("100644", _PROCESSION_SCOPE_SOURCE_PACKET_BLOB):
        raise HostValidationError("pinned Procession packet blob or mode does not match")
    source_entries = {}
    for source_path, expected_blob in _PROCESSION_SCOPE_SOURCE_FILES.items():
        entry = _git_tree_entry(repo, _PROCESSION_SCOPE_SOURCE_ARCHIVE, source_path)
        if not expected_blob or entry != ("100644", expected_blob):
            raise HostValidationError(f"pinned Procession source blob or mode does not match: {source_path}")
        source_entries[source_path] = entry

    approval_main = _git(repo, "rev-parse", "origin/main^{commit}")
    if not _is_ancestor(repo, reviewed_main, approval_main):
        raise HostValidationError("post-hoc Procession approval does not descend from the preserved reviewed main")
    if not _is_ancestor(repo, _PROCESSION_SCOPE_SOURCE_ARCHIVE, approval_main):
        raise HostValidationError("post-hoc Procession approval main does not contain the exact source archive")

    attestation_entry = _git_tree_entry(repo, approval_main, _PROCESSION_SCOPE_ATTESTATION_PATH)
    if attestation_entry is None or attestation_entry[0] != "100644":
        raise HostValidationError("approved main lacks the regular-file Procession scope attestation")
    try:
        attestation_bytes = subprocess.run(
            ["git", "show", f"{approval_main}:{_PROCESSION_SCOPE_ATTESTATION_PATH}"],
            cwd=repo, capture_output=True, check=True,
        ).stdout
        attestation = json.loads(attestation_bytes)
    except (subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        raise HostValidationError("Procession scope attestation is unreadable or invalid JSON") from exc
    expected_attestation = {
        "schema": "custodian.review_source_scope_attestation.v1",
        "source_workstream": _PROCESSION_SCOPE_SOURCE_WORKSTREAM,
        "source_archive_commit": _PROCESSION_SCOPE_SOURCE_ARCHIVE,
        "source_packet_path": _PROCESSION_SCOPE_SOURCE_PACKET,
        "source_packet_blob": _PROCESSION_SCOPE_SOURCE_PACKET_BLOB,
        "source_files": [
            {"path": path, "blob": blob, "mode": "100644"}
            for path, blob in sorted(_PROCESSION_SCOPE_SOURCE_FILES.items())
        ],
        "reason": "The original archived P1 Work surface omitted these exact eight source paths.",
        "post_hoc": True,
    }
    canonical_bytes = (json.dumps(expected_attestation, indent=2, sort_keys=True) + "\n").encode("utf-8")
    if attestation != expected_attestation or attestation_bytes != canonical_bytes:
        raise HostValidationError("Procession attestation bytes do not match the exact post-hoc authorization")

    origin_result = subprocess.run(
        ["git", "log", "--format=%H", approval_main, "--", _PROCESSION_SCOPE_ATTESTATION_PATH],
        cwd=repo, text=True, capture_output=True,
    )
    if origin_result.returncode:
        raise HostValidationError("cannot resolve Procession scope attestation origin commit")
    origins = [commit for commit in origin_result.stdout.splitlines()
               if _git_tree_entry(repo, commit, _PROCESSION_SCOPE_ATTESTATION_PATH) == attestation_entry]
    if len(origins) != 1:
        raise HostValidationError("Procession attestation has missing or ambiguous exact-blob origin history")
    origin_commit = origins[0]

    try:
        correction_text = read_git_text(repo, approval_main, _PROCESSION_SCOPE_CORRECTION_PACKET)
        review_text = read_git_text(repo, approval_main, _PROCESSION_SCOPE_REVIEW_PACKET)
    except ValueError as exc:
        raise HostValidationError("Procession attestation lacks archived correction review evidence") from exc
    correction = parse_packet(_PROCESSION_SCOPE_CORRECTION_PACKET, correction_text)
    review = parse_packet(_PROCESSION_SCOPE_REVIEW_PACKET, review_text)
    if (correction.error or correction.kind not in {"implementation", "correction"}
            or correction.status != "complete"
            or correction.workstream != _PROCESSION_SCOPE_CORRECTION_WORKSTREAM
            or review.error or review.kind != "review" or review.status != "complete"
            or review.workstream != _PROCESSION_SCOPE_REVIEW_WORKSTREAM
            or review.review_target_workstream != _PROCESSION_SCOPE_CORRECTION_WORKSTREAM
            or review.review_target_packet != _PROCESSION_SCOPE_CORRECTION_PACKET):
        raise HostValidationError("Procession attestation correction/review packet identity is incomplete")

    outcome, outcome_error = review_outcome.parse_review_outcome(review_text)
    if outcome_error or outcome is None or outcome.get("Outcome") != "passed":
        raise HostValidationError("Procession attestation has no canonical independent PASS outcome")
    accepted, _, acceptance_reason = review_outcome.review_acceptance(
        review_text, correction_text, _PROCESSION_SCOPE_REVIEW_WORKSTREAM,
    )
    if not accepted:
        raise HostValidationError(f"Procession attestation review is not accepted: {acceptance_reason}")
    review_baseline = read_git_text(repo, outcome["Reviewed main"], _PROCESSION_SCOPE_CORRECTION_PACKET)
    implementation_commit, identity_error = resolve_target_implementation_commit(
        repo, outcome["Reviewed main"], _PROCESSION_SCOPE_CORRECTION_PACKET,
        _PROCESSION_SCOPE_CORRECTION_WORKSTREAM, review_baseline,
    )
    if identity_error:
        raise HostValidationError(f"Procession attestation target identity is invalid: {identity_error}")
    if not _is_ancestor(repo, origin_commit, implementation_commit):
        raise HostValidationError("Procession attestation was not present by its recovery implementation archive")
    if not _is_ancestor(repo, outcome["Reviewed main"], approval_main):
        raise HostValidationError("accepted Procession attestation review is not an ancestor of approved main")
    if not _is_ancestor(repo, implementation_commit, outcome["Reviewed main"]):
        raise HostValidationError("accepted Procession attestation review predates its implementation")
    receipt, receipt_error = verify_review_receipt_delta(
        review_baseline, correction_text, review_workstream=_PROCESSION_SCOPE_REVIEW_WORKSTREAM,
        target_workstream=_PROCESSION_SCOPE_CORRECTION_WORKSTREAM,
        reviewed_main=outcome["Reviewed main"], target_implementation_commit=implementation_commit,
    )
    if receipt_error or not receipt:
        raise HostValidationError(f"accepted Procession attestation review target receipt is invalid: {receipt_error}")
    identity_error = review_outcome.outcome_identity_error(
        outcome, review_workstream=_PROCESSION_SCOPE_REVIEW_WORKSTREAM,
        target_workstream=_PROCESSION_SCOPE_CORRECTION_WORKSTREAM,
        reviewed_main=outcome["Reviewed main"], implementation_commit=implementation_commit,
        run_id=outcome["Run ID"], review_cycle=review.review_cycle,
    )
    if identity_error:
        raise HostValidationError(f"accepted Procession attestation review identity is invalid: {identity_error}")
    reviewer_receipt = _scope_review_receipt(review_text)
    if reviewer_receipt is None:
        raise HostValidationError("accepted Procession attestation review lacks one canonical reviewer receipt")
    expected_receipt = {
        "Schema": "custodian.paired_review.v1",
        "Review workstream": _PROCESSION_SCOPE_REVIEW_WORKSTREAM,
        "Review target workstream": _PROCESSION_SCOPE_CORRECTION_WORKSTREAM,
        "Status": "passed", "Blocking defects": "0", "Material gaps": "0",
        "Reviewer context": "fresh", "Reviewed main": outcome["Reviewed main"],
        "Reviewed implementation commit": implementation_commit,
    }
    if any(reviewer_receipt.get(field) != value for field, value in expected_receipt.items()) or (
        reviewer_receipt.get("Reviewer provenance") not in {"different-agent", "same-agent-fresh-context"}
    ):
        raise HostValidationError("accepted Procession attestation reviewer receipt does not match its PASS outcome")

    return {
        "kind": "accepted-post-hoc-exact-source-attestation",
        "attestation_path": _PROCESSION_SCOPE_ATTESTATION_PATH,
        "attestation_commit": origin_commit,
        "attestation_blob": attestation_entry[1],
        "attestation_sha256": _sha256(attestation_bytes),
        "source_archive_commit": _PROCESSION_SCOPE_SOURCE_ARCHIVE,
        "source_packet_blob": _PROCESSION_SCOPE_SOURCE_PACKET_BLOB,
        "source_files": {
            path: {"mode": mode, "blob": blob}
            for path, (mode, blob) in source_entries.items()
        },
        "approval_review_workstream": _PROCESSION_SCOPE_REVIEW_WORKSTREAM,
        "approval_review_packet": _PROCESSION_SCOPE_REVIEW_PACKET,
        "approval_target_packet": _PROCESSION_SCOPE_CORRECTION_PACKET,
        "approval_reviewed_main": outcome["Reviewed main"],
        "approval_run_id": outcome["Run ID"],
        "approval_implementation_commit": implementation_commit,
        "approval_outcome": outcome["Outcome"],
        "preserved_reviewed_main": reviewed_main,
    }
def _split_landing_source_span(repo: Path, reviewed_main: str, landing_commit: str,
                               target_workstream: str, target_packet_path: str,
                               target_packet_text: str) -> dict:
    """Resolve an archive landing to its exact source-bearing workstream range.

    The archive-introduction commit remains the canonical implementation identity.
    One immutable lifecycle trace may pin that commit directly, or pin a verified
    two-parent main-sync merge whose first parent is the archive commit. The
    immediately preceding source span must be a linear first-parent range and its
    implementation paths must be named by the archived packet.
    """
    active_packet = target_packet_path.replace("/archived/", "/", 1)
    prefix = f"refs/remotes/origin/agent-diagnostics/{target_workstream}/"
    refs = subprocess.run(["git", "for-each-ref", "--format=%(refname)", prefix],
                          cwd=repo, text=True, capture_output=True)
    if refs.returncode:
        raise HostValidationError("could not enumerate committed source-span workstream traces")
    claim_records = []
    landing_records = []
    legacy_records = []
    for ref in refs.stdout.splitlines():
        events = _trace_events(repo, ref)
        run_ids = {event.get("run_id") for event in events}
        if len(run_ids) != 1:
            continue
        run_id = next(iter(run_ids))
        if not ref.endswith("/" + str(run_id)):
            continue
        if any(event.get("workstream") != target_workstream or event.get("packet") != active_packet
               for event in events):
            continue
        started = [event for event in events if event.get("event") == "remote_claim_acquired"]
        published = [event for event in events if event.get("event") == "worktree_published"]
        create_begins = [event for event in events if event.get("event") == "worktree_create_begin"]
        resumed = [event for event in events if event.get("event") == "worktree_resumed"]
        landing_started = [event for event in events if event.get("event") == "landing_started"]
        landed = [event for event in events if event.get("event") == "landing_completed"]
        teardown_started = [event for event in events if event.get("event") == "teardown_started"]
        teardown_completed = [event for event in events if event.get("event") == "teardown_completed"]
        branch = f"agent/{target_workstream}"
        if len(started) == len(published) == 1 and not landing_started and not landed:
            claim, publication = started[0]["data"], published[0]["data"]
            base, path = claim.get("main_sha"), publication.get("worktree")
            if (isinstance(base, str) and re.fullmatch(r"[0-9a-f]{40,64}", base)
                    and publication.get("head") == base and publication.get("upstream") == base
                    and publication.get("branch") == branch and publication.get("clean") is True
                    and isinstance(path, str) and Path(path).is_absolute()
                    and claim.get("remote_ref") == f"refs/heads/dispatch-claims/{target_workstream}"
                    and isinstance(claim.get("claim_oid"), str)
                    and re.fullmatch(r"[0-9a-f]{40,64}", claim["claim_oid"])):
                claim_records.append({"ref": ref, "run_id": run_id, "base": base,
                                      "branch": branch, "worktree": path, "events": events})
            continue
        if (not published and len(landing_started) == len(landed) == len(teardown_started) == len(teardown_completed) == 1
                and len(started) <= 1):
            start_data, landed_data = landing_started[0]["data"], landed[0]["data"]
            trace_landing = start_data.get("start_sha")
            teardown_data, removed_data = teardown_started[0]["data"], teardown_completed[0]["data"]
            path = teardown_data.get("worktree")
            valid_landing = (isinstance(trace_landing, str) and re.fullmatch(r"[0-9a-f]{40,64}", trace_landing)
                    and start_data.get("branch") == branch and start_data.get("target") == "main"
                    and landed_data.get("head") == trace_landing and landed_data.get("outcome") == "landed"
                    and teardown_data.get("head") == trace_landing and teardown_data.get("branch") == branch
                    and removed_data.get("head") == trace_landing and removed_data.get("branch") == branch
                    and removed_data.get("worktree_removed") is True and isinstance(path, str)
                    and Path(path).is_absolute())
            resumed_claim_candidate = bool(started and (create_begins or resumed))
            if valid_landing and not resumed_claim_candidate:
                landing_records.append({"ref": ref, "run_id": run_id, "landing": trace_landing,
                                        "path": path, "branch": branch, "events": events})
            if not resumed_claim_candidate:
                continue
        if (len(started) == len(published) == len(landing_started) == len(landed) == 1
                and not teardown_started and not teardown_completed):
            claim, publication = started[0]["data"], published[0]["data"]
            start_data, landed_data = landing_started[0]["data"], landed[0]["data"]
            base, trace_landing = claim.get("main_sha"), start_data.get("start_sha")
            path = publication.get("worktree")
            if (isinstance(base, str) and publication.get("head") == base
                    and publication.get("branch") == branch and start_data.get("branch") == branch
                    and isinstance(trace_landing, str) and landed_data.get("head") == trace_landing):
                legacy_records.append((ref, run_id, base, trace_landing, path, events))
            continue
        if len(landing_started) != 1 or len(landed) != 1:
            continue
        start_data, landed_data = landing_started[0]["data"], landed[0]["data"]
        trace_landing = start_data.get("start_sha")
        if (not isinstance(trace_landing, str) or not re.fullmatch(r"[0-9a-f]{40,64}", trace_landing)
                or start_data.get("branch") != branch or start_data.get("target") != "main"
                or landed_data.get("head") != trace_landing):
            continue
        if teardown_started or teardown_completed:
            if len(teardown_started) != 1 or len(teardown_completed) != 1:
                continue
            teardown_data, removed_data = teardown_started[0]["data"], teardown_completed[0]["data"]
            path = teardown_data.get("worktree")
            if (landed_data.get("outcome") != "landed"
                    or teardown_data.get("head") != trace_landing or teardown_data.get("branch") != branch
                    or removed_data.get("head") != trace_landing or removed_data.get("branch") != branch
                    or (removed_data.get("worktree") is not None
                        and removed_data.get("worktree") != path)
                    or removed_data.get("worktree_removed") is not True
                    or not isinstance(path, str) or not Path(path).is_absolute()):
                continue
        else:
            path = None
        if len(started) > 1 or len(published) > 1:
            continue
        if started:
            # A landing trace may preserve an earlier failed claim attempt. It
            # is not sufficient provenance alone; cross-check its base against
            # the independently validated claim record below.
            if started[0]["data"].get("main_sha") is None:
                continue
        landing_records.append({"ref": ref, "run_id": run_id, "landing": trace_landing,
                                "path": path, "branch": branch, "events": events})

        # A failed initial creation has no worktree_published event. Accept its
        # later resume only when the immutable trace records the exact original
        # claim, one failed create for the canonical checkout, and one ordered
        # successful resume. workstream.py resume records the resulting HEAD
        # after synchronizing main; retain that SHA separately from the claim
        # base instead of fabricating a publication event or equating the two.
        if started and not published and (create_begins or resumed):
            if (len(started) != 1 or len(create_begins) != 1 or len(resumed) != 1
                    or len(landing_started) != 1):
                continue
            claim_event = started[0]
            claim_data = claim_event.get("data", {})
            create_event = create_begins[0]
            create_data = create_event.get("data", {})
            resume_event = resumed[0]
            resume_data = resume_event.get("data", {})
            claim_base = claim_data.get("main_sha")
            resumed_head = resume_data.get("head")
            worktree = create_data.get("worktree")
            failure_command = f"git worktree add -b {branch} {worktree} origin/main failed:"
            failed_creates = [
                (index, event) for index, event in enumerate(events)
                if event.get("event") == "run_blocked"
                and isinstance(event.get("data"), dict)
                and isinstance(event["data"].get("reason"), str)
                and failure_command in event["data"]["reason"]
            ]
            claim_index = events.index(claim_event)
            create_index = events.index(create_event)
            resume_index = events.index(resume_event)
            landing_index = events.index(landing_started[0])
            claim_subject = subprocess.run(
                ["git", "show", "-s", "--format=%s", str(claim_data.get("claim_oid", ""))],
                cwd=repo, text=True, capture_output=True,
            )
            claim_subject_match = re.fullmatch(
                rf"workstream claim {re.escape(target_workstream)} ([^:\s]+):[0-9]+:{re.escape(run_id)}",
                claim_subject.stdout.rstrip(),
            ) if claim_subject.returncode == 0 else None
            generation = claim_event.get("execution_generation")
            host = claim_event.get("host")
            claim_agent = claim_event.get("agent")
            failure_event = failed_creates[0][1] if failed_creates else {}
            required_lifecycle_events = [
                claim_event, create_event, failure_event, resume_event, landing_started[0], landed[0],
                teardown_started[0], teardown_completed[0],
            ]
            lifecycle_identity_matches = (
                isinstance(generation, str) and bool(generation)
                and isinstance(host, str) and bool(host)
                and all(event.get("execution_generation") == generation
                        and event.get("host") == host for event in required_lifecycle_events)
                and isinstance(claim_agent, str) and bool(claim_agent)
                and failure_event.get("agent") == claim_agent
                and resume_event.get("agent") in {None, claim_agent}
            )
            valid_resumed = (
                isinstance(claim_base, str) and re.fullmatch(r"[0-9a-f]{40,64}", claim_base)
                and isinstance(resumed_head, str) and re.fullmatch(r"[0-9a-f]{40,64}", resumed_head)
                and len(teardown_started) == len(teardown_completed) == 1
                and create_data.get("main_sha") == claim_base
                and create_data.get("branch") == branch
                and resume_data.get("branch") == branch
                and resume_data.get("worktree") == worktree
                and isinstance(worktree, str) and Path(worktree).is_absolute()
                and os.path.normpath(worktree) == worktree
                and claim_data.get("remote_ref") == f"refs/heads/dispatch-claims/{target_workstream}"
                and claim_data.get("local_ref") == f"refs/custodian/claims/{target_workstream}/{run_id}"
                and claim_subject_match is not None
                and claim_agent == claim_subject_match.group(1)
                and lifecycle_identity_matches
                and len(failed_creates) >= 1
                and claim_index < create_index < failed_creates[0][0] < resume_index < landing_index
                and _verified_landing_claim(repo, claim_event, target_workstream, run_id, resumed_head)
            )
            if valid_resumed:
                # The producer's resume path fast-forwards the clean original
                # branch before recording worktree_resumed. Require a first-
                # parent fast-forward from the claim base and reject merge or
                # side-branch substitutions as an unproven recovery base.
                resume_history = subprocess.run(
                    ["git", "rev-list", "--first-parent", "--reverse",
                     f"{claim_base}..{resumed_head}"], cwd=repo, text=True, capture_output=True,
                )
                if resume_history.returncode:
                    valid_resumed = False
                else:
                    previous = claim_base
                    for commit in resume_history.stdout.splitlines():
                        parents = _git(repo, "rev-list", "--parents", "-n", "1", commit).split()[1:]
                        if len(parents) != 1 or parents[0] != previous:
                            valid_resumed = False
                            break
                        previous = commit
                    if previous != resumed_head:
                        valid_resumed = False
                if valid_resumed and subprocess.run(
                    ["git", "merge-base", "--is-ancestor", resumed_head, trace_landing],
                    cwd=repo, capture_output=True,
                ).returncode:
                    valid_resumed = False
                if valid_resumed:
                    first_parent_history = subprocess.run(
                        ["git", "rev-list", "--first-parent", trace_landing],
                        cwd=repo, text=True, capture_output=True,
                    )
                    if (first_parent_history.returncode
                            or resumed_head not in first_parent_history.stdout.splitlines()):
                        valid_resumed = False
            if valid_resumed:
                claim_records.append({
                    "ref": ref, "run_id": run_id, "base": resumed_head,
                    "branch": branch, "worktree": worktree, "events": events,
                    "claim_oid": claim_data["claim_oid"], "claim_base": claim_base,
                    "resumed_head": resumed_head,
                    "create_event_index": create_index, "resume_event_index": resume_index,
                })

        # Support older single-trace lifecycles that contain claim, publication,
        # landing, and teardown together. The same strict field checks apply to
        # each role, and pair uniqueness below prevents ambiguous reuse.
        if len(started) == len(published) == 1:
            claim, publication = started[0]["data"], published[0]["data"]
            base, published_path = claim.get("main_sha"), publication.get("worktree")
            if (isinstance(base, str) and re.fullmatch(r"[0-9a-f]{40,64}", base)
                    and publication.get("head") == base and publication.get("upstream") == base
                    and publication.get("branch") == branch and publication.get("clean") is True
                    and isinstance(published_path, str) and Path(published_path).is_absolute()
                    and published_path == path
                    and claim.get("remote_ref") == f"refs/heads/dispatch-claims/{target_workstream}"
                    and isinstance(claim.get("claim_oid"), str)
                    and re.fullmatch(r"[0-9a-f]{40,64}", claim["claim_oid"])):
                claim_records.append({"ref": ref, "run_id": run_id, "base": base,
                                      "branch": branch, "worktree": published_path,
                                      "events": events})

    # Bind the two trace roles independently. A landing trace can preserve an
    # earlier failed remote-claim attempt; its teardown path identifies the
    # published checkout, while the exact claim base is checked against it.
    if not claim_records and len(legacy_records) == 1:
        ref, run_id, base, trace_landing, path, events = legacy_records[0]
        claim_records.append({"ref": ref, "run_id": run_id, "base": base,
                              "branch": f"agent/{target_workstream}", "worktree": path,
                              "events": events})
        landing_records.append({"ref": ref, "run_id": run_id, "landing": trace_landing,
                                "path": path, "branch": f"agent/{target_workstream}",
                                "events": events})
    recorded_main = re.findall(r"(?im)^- Reviewed main:\s*`?([0-9a-f]{40,64})`?\s*$",
                               target_packet_text)
    if len(recorded_main) != 1:
        raise HostValidationError("split target packet has missing or ambiguous Reviewed main provenance")
    exact_base = recorded_main[0]
    matching_pairs = []
    for claim in claim_records:
        for completed in landing_records:
            if (claim.get("resumed_head") is not None
                    and (claim["run_id"] != completed["run_id"]
                         or claim["ref"] != completed["ref"])):
                continue
            if (claim["worktree"] == completed["path"]
                    and claim["branch"] == completed["branch"]
                    and subprocess.run(["git", "merge-base", "--is-ancestor", exact_base,
                                        claim["base"]], cwd=repo, capture_output=True).returncode == 0
                    and subprocess.run(["git", "merge-base", "--is-ancestor", exact_base,
                                        completed["landing"]], cwd=repo, capture_output=True).returncode == 0):
                landing_claims = [event for event in completed["events"]
                                  if event.get("event") == "remote_claim_acquired"]
                if (len(landing_claims) > 1
                        or any(not _verified_landing_claim(repo, event, target_workstream,
                                                           completed["run_id"], claim["base"])
                               for event in landing_claims)):
                    continue
                matching_pairs.append((claim, completed))
    if len(matching_pairs) != 1:
        raise HostValidationError("split landing has missing or ambiguous exact workstream trace provenance")
    claim_record, landing_record = matching_pairs[0]
    source_base = claim_record["base"]
    trace_landing = landing_record["landing"]
    ref, run_id, events = landing_record["ref"], landing_record["run_id"], landing_record["events"]

    for sha, label in ((source_base, "source base"), (recorded_main[0], "packet Reviewed main"),
                       (landing_commit, "canonical landing"), (trace_landing, "trace landing"),
                       (reviewed_main, "pinned reviewed main")):
        resolved = subprocess.run(["git", "rev-parse", "--verify", f"{sha}^{{commit}}"], cwd=repo,
                                  text=True, capture_output=True)
        if resolved.returncode or resolved.stdout.strip() != sha:
            raise HostValidationError(f"split landing {label} is not an available full commit SHA")
    if subprocess.run(["git", "merge-base", "--is-ancestor", recorded_main[0], source_base],
                      cwd=repo, capture_output=True).returncode:
        raise HostValidationError("source-span base does not descend from packet Reviewed main")
    if subprocess.run(["git", "merge-base", "--is-ancestor", source_base, landing_commit],
                      cwd=repo, capture_output=True).returncode:
        raise HostValidationError("source-span base is not an ancestor of the canonical landing")

    # A legitimate synchronization merge is narrowly bound by both its parent
    # order and the immutable lifecycle main_sync event. Do not derive the source
    # span from this merge: it may contain unrelated changes from prior main.
    trace_landing_kind = "canonical-archive"
    trace_main_sync_sha = None
    reset_followup = None
    archive_sync_followup = None
    if trace_landing != landing_commit:
        sync_events = [event for event in events if event.get("event") == "main_sync"]
        if (target_workstream == _RESET_FOLLOWUP_WORKSTREAM
                and landing_commit == _RESET_FOLLOWUP_ARCHIVE
                and trace_landing == _RESET_FOLLOWUP_HEAD):
            sync_data = sync_events[0].get("data", {}) if len(sync_events) == 1 else {}
            if not isinstance(sync_data, dict):
                raise HostValidationError("reset follow-up trace has malformed main-sync provenance")
            trace_main_sync_sha = sync_data.get("main_sha")
            trace_landing_kind = "main-sync-merge-followup"
        else:
            history = subprocess.run(
                ["git", "rev-list", "--first-parent", "--reverse",
                 f"{landing_commit}..{trace_landing}"], cwd=repo, text=True, capture_output=True,
            )
            commits = history.stdout.splitlines() if history.returncode == 0 else []
            first_parents = [_git(repo, "rev-list", "--parents", "-n", "1", commit).split()
                             for commit in commits]
            saw_followup = False
            valid_tail = bool(first_parents) and len(first_parents[0]) in {2, 3} \
                and first_parents[0][1] == landing_commit
            previous_commit = landing_commit
            for index, parents in enumerate(first_parents):
                if len(parents) == 3 and parents[1] == previous_commit:
                    previous_commit = commits[index]
                    continue
                if len(parents) == 2 and parents[1] == previous_commit:
                    saw_followup = True
                    previous_commit = commits[index]
                    continue
                valid_tail = False
                break
            has_followup_chain = (
                valid_tail and saw_followup
            )
            if has_followup_chain:
                archive_sync_followup = _verify_archive_sync_followup(
                    repo, target_workstream, target_packet_text, landing_commit, trace_landing,
                    reviewed_main, events, landing_record["ref"],
                )
                if archive_sync_followup["sync_merges"]:
                    trace_main_sync_sha = archive_sync_followup["sync_merges"][-1]["main_sha"]
                    trace_landing_kind = "main-sync-merge-followup"
                else:
                    trace_main_sync_sha = reviewed_main
                    trace_landing_kind = "archive-source-followup"
            else:
                parent_line = _git(repo, "rev-list", "--parents", "-n", "1", trace_landing).split()
                if len(parent_line) != 3 or parent_line[1] != landing_commit:
                    raise HostValidationError("trace landing is not the exact two-parent archive-first main-sync merge")
                second_parent = parent_line[2]
                exact_true = [event for event in sync_events
                              if isinstance(event.get("data"), dict)
                              and event["data"].get("changed") is True
                              and event["data"].get("head") == trace_landing]
                if len(exact_true) == 1:
                    sync_data = exact_true[0]["data"]
                    valid_sync = sync_data.get("main_sha") == second_parent
                elif exact_true:
                    valid_sync = False
                else:
                    # A retry is admitted only for a unique immutable no-op event.
                    sync_data = sync_events[0].get("data", {}) if len(sync_events) == 1 else {}
                    valid_sync = (len(sync_events) == 1
                                  and isinstance(sync_data, dict)
                                  and sync_data.get("changed") is False
                                  and sync_data.get("head") == trace_landing
                                  and sync_data.get("main_sha") == second_parent)
                if not valid_sync:
                    raise HostValidationError("trace landing lacks an exact main-sync merge provenance event")
                trace_landing_kind = "main-sync-merge"
                trace_main_sync_sha = second_parent
    if subprocess.run(["git", "merge-base", "--is-ancestor", trace_landing, reviewed_main],
                      cwd=repo, capture_output=True).returncode:
        raise HostValidationError("trace landing is not an ancestor of pinned reviewed main")
    if target_workstream == _RESET_FOLLOWUP_WORKSTREAM:
        reset_followup = _verify_reset_archive_merge_followup(
            repo, target_workstream, target_packet_path, source_base, landing_commit,
            trace_landing, trace_main_sync_sha, ref, run_id, events, claim_record, landing_record,
        )

    # Validate the canonical archive commit independently of the later main-sync
    # merge. Its allowed closeout consists only of this packet's active deletion,
    # archived creation, exact root summary and generated packet index.
    archive_parent_line = _git(repo, "rev-list", "--parents", "-n", "1", landing_commit).split()
    if len(archive_parent_line) != 2:
        raise HostValidationError("canonical archive landing must have exactly one parent")
    archive_parent = archive_parent_line[1]
    archive_paths = set(_changed_paths(repo, f"{archive_parent}..{landing_commit}"))
    summary_path = f"{target_workstream.upper().replace('-', '_')}_CLAUDE_SUMMARY.md"
    allowed_archive_paths = {active_packet, target_packet_path, summary_path,
                             f"{PACKET_ROOT}/README.md"}
    if not {active_packet, target_packet_path}.issubset(archive_paths):
        raise HostValidationError("archive landing is missing its active or archived packet closeout")

    pinned_host_import_archive = (
        target_workstream == _HOST_IMPORT_CONFLICT_WORKSTREAM
        and landing_commit == _HOST_IMPORT_CONFLICT_ARCHIVE
    )
    if pinned_host_import_archive:
        if (archive_parent != _HOST_IMPORT_ARCHIVE_PARENT
                or _git(repo, "rev-parse", f"{landing_commit}^{{tree}}") != _HOST_IMPORT_ARCHIVE_TREE
                or archive_paths != _HOST_IMPORT_ARCHIVE_PATHS):
            raise HostValidationError("host-import canonical archive has an unpinned parent, tree, or path set")
        for path, expected_blob in _HOST_IMPORT_ARCHIVE_BLOBS.items():
            entry = subprocess.run(["git", "ls-tree", "-z", landing_commit, "--", path],
                                   cwd=repo, capture_output=True)
            if entry.returncode or not entry.stdout:
                raise HostValidationError("host-import canonical archive is missing a pinned closeout path")
            fields = entry.stdout.split(b"\t", 1)[0].split()
            if len(fields) != 3 or fields[0] != b"100644" or fields[2].decode() != expected_blob:
                raise HostValidationError("host-import canonical archive closeout identity changed")

    extra_archive_paths = archive_paths - allowed_archive_paths
    if pinned_host_import_archive:
        extra_archive_paths.discard(_HOST_IMPORT_REVIEW_PACKET)
    pinned_reset_archive = (
        target_workstream == _RESET_FOLLOWUP_WORKSTREAM
        and landing_commit == _RESET_FOLLOWUP_ARCHIVE
    )
    if pinned_reset_archive and archive_paths != _RESET_ARCHIVE_PATHS:
        raise HostValidationError("reset canonical archive has an unpinned closeout path set")
    source_bearing_archive = bool(extra_archive_paths) and not pinned_reset_archive
    paired_review_metadata_path = None
    source_artifact = _verified_blender_source_artifact(
        repo, landing_commit, target_packet_text, extra_archive_paths,
    ) if target_workstream == _BLENDER_SOURCE_WORKSTREAM else None
    # Godot .gd.uid is a data-only companion, not an implementation source.
    # Permit it only when its .gd is modified in this source-bearing archive;
    # the .gd must also pass the unchanged packet documentation/coverage gates.
    uid_companion_paths = {
        path for path in extra_archive_paths
        if path.endswith(".gd.uid") and path[:-4] in extra_archive_paths
    }
    scope_attestation = None
    historical_recovery_paths = (
        _verified_procession_recovery_historical_scope(
            repo, target_workstream, target_packet_path, landing_commit, extra_archive_paths,
        )
        | _verified_or1_bootstrap_historical_scope(
            repo, target_workstream, target_packet_path, landing_commit, extra_archive_paths,
        )
    )
    if source_bearing_archive:
        paired_review_metadata_path = _canonical_review_packet_metadata_path(
            repo, archive_parent, landing_commit, target_workstream, target_packet_path,
            target_packet_text, extra_archive_paths,
        )
        paired_review_metadata_paths = (
            {paired_review_metadata_path} if paired_review_metadata_path else set()
        )
        work_surface = header_field(target_packet_text, "Work surface") or ""
        declared_markdown_paths = set(_REPOSITORY_MARKDOWN_PATH_RE.findall(work_surface))
        if (target_workstream == _PROCESSION_SCOPE_SOURCE_WORKSTREAM
                and landing_commit == _PROCESSION_SCOPE_SOURCE_ARCHIVE):
            scope_attestation = _verified_procession_scope_attestation(
                repo, reviewed_main, landing_commit, extra_archive_paths,
            )
        elif (target_workstream == "grunt-candidate-raster-workflow-v1"
                and extra_archive_paths.intersection(_GRUNT_SCOPE_FILES)):
            if landing_commit != _GRUNT_SCOPE_SOURCE_ARCHIVE:
                raise HostValidationError("post-hoc Grunt scope attestation names a different source archive")
            scope_attestation = _verified_grunt_scope_attestation(
                repo, reviewed_main, extra_archive_paths,
            )
        attested_paths = (
            (set(scope_attestation["source_files"]) if scope_attestation else set())
            | historical_recovery_paths
        )
        if any(Path(path).suffix.lower() not in _IMPLEMENTATION_SUFFIXES
               and path not in uid_companion_paths
               and path not in paired_review_metadata_paths
               and not (source_artifact is not None and path == source_artifact["path"])
               and not (Path(path).suffix.lower() == ".md"
                        and (path in declared_markdown_paths
                             or path in attested_paths))
               for path in extra_archive_paths):
            raise HostValidationError("archive-only landing contains unrelated paths")
        for path in sorted(uid_companion_paths):
            uid_text = _git(repo, "show", f"{landing_commit}:{path}")
            if not re.fullmatch(r"uid://[a-z0-9]{8,32}", uid_text):
                raise HostValidationError("archive landing contains malformed Godot script UID sidecar")
    elif (archive_paths - allowed_archive_paths and not pinned_reset_archive
          and not pinned_host_import_archive):
        raise HostValidationError("archive-only landing contains unrelated paths")

    def has_path(revision: str, path: str) -> bool:
        result = subprocess.run(["git", "cat-file", "-e", f"{revision}:{path}"], cwd=repo,
                                capture_output=True)
        return result.returncode == 0

    if (not has_path(archive_parent, active_packet) or has_path(landing_commit, active_packet)
            or has_path(archive_parent, target_packet_path) or not has_path(landing_commit, target_packet_path)):
        raise HostValidationError("archive-only landing does not delete the active packet and create its canonical archive")
    # Archive closeout and source-bearing paths must all be regular, non-executable files.
    for revision in (archive_parent, landing_commit):
        for path in archive_paths:
            result = subprocess.run(["git", "ls-tree", "-z", revision, "--", path],
                                    cwd=repo, capture_output=True)
            if result.returncode:
                raise HostValidationError("could not inspect archive closeout file modes")
            if result.stdout:
                mode = result.stdout.split(b"\t", 1)[0].split()[0]
                if mode != b"100644":
                    raise HostValidationError("archive landing contains an executable or non-regular path")

    # A source-bearing archive includes its final source/test edits. An archive-
    # only closeout ends at its parent. Neither span includes a later main-sync.
    followup = reset_followup or archive_sync_followup
    source_head = landing_commit if source_bearing_archive else archive_parent
    if followup is not None:
        source_head = followup.get("source_head", followup["post_merge_followup_commit"])
    chain_end = landing_commit if followup is not None else source_head
    chain = subprocess.run(["git", "rev-list", "--first-parent", "--reverse",
                            f"{source_base}..{chain_end}"], cwd=repo,
                           text=True, capture_output=True)
    if chain.returncode or not chain.stdout.splitlines():
        raise HostValidationError("split landing has no source-bearing commits after its recorded workstream base")
    commits = chain.stdout.splitlines()
    if followup is not None:
        commits.extend(followup.get("post_merge_followup_commits",
                                    [followup["post_merge_followup_commit"]]))
    merge_commits = []
    owned_paths = set()
    for index, commit in enumerate(commits):
        parents = _git(repo, "rev-list", "--parents", "-n", "1", commit).split()[1:]
        if len(parents) == 1:
            owned_paths.update(_changed_paths(repo, f"{parents[0]}..{commit}"))
        else:
            merge_commits.append((index, commit, parents))
    if len(merge_commits) > 1:
        raise HostValidationError("split source span contains multiple synchronization merges")
    checkpoint_resume_merge = None
    source_main_sync_merge = None
    if merge_commits:
        if ref != claim_record["ref"] or run_id != claim_record["run_id"]:
            raise HostValidationError("checkpoint-resume merge claim and lifecycle events are not from one trace")
        merge_index, merge_sha, parents = merge_commits[0]
        if len(parents) != 2 or merge_index == 0 or parents[0] != commits[merge_index - 1]:
            raise HostValidationError("checkpoint-resume merge has invalid ordered parents")
        first_parent, second_parent = parents
        if not _is_ancestor(repo, source_base, second_parent):
            raise HostValidationError("checkpoint-resume merge second parent is outside published history")
        if not _is_ancestor(repo, second_parent, reviewed_main):
            raise HostValidationError("checkpoint-resume merge second parent is outside reviewed main")
        checkpoint_events = [
            (i, event) for i, event in enumerate(events)
            if event.get("event") == "checkpoint_completed"
            and isinstance(event.get("data"), dict)
            and event["data"].get("remote_head") == first_parent
            and event["data"].get("branch") == claim_record["branch"]
            and event["data"].get("removed") is False
        ]
        resume_events = [
            (i, event) for i, event in enumerate(events)
            if event.get("event") == "worktree_resumed"
            and isinstance(event.get("data"), dict)
            and event["data"].get("head") == merge_sha
            and event["data"].get("branch") == claim_record["branch"]
            and event["data"].get("worktree") == claim_record["worktree"]
        ]
        if len(checkpoint_events) != 1:
            raise HostValidationError("synchronization merge lacks a unique matching checkpoint")
        checkpoint_pos, checkpoint_event = checkpoint_events[0]
        all_resumes = [event for event in events if event.get("event") == "worktree_resumed"]
        sync_events = [(i, event) for i, event in enumerate(events)
                       if event.get("event") == "main_sync"]
        later_noop = [(i, event) for i, event in sync_events
                      if isinstance(event.get("data"), dict)
                      and event["data"].get("changed") is False
                      and event["data"].get("head") == landing_commit
                      and event["data"].get("main_sha") == second_parent]
        if len(later_noop) != 1:
            raise HostValidationError("synchronization merge lacks its exact no-op main-sync witness")
        if len(resume_events) == 1:
            resume_pos, resume_event = resume_events[0]
            if checkpoint_pos >= resume_pos or resume_pos >= later_noop[0][0]:
                raise HostValidationError("checkpoint-resume lifecycle events are out of order")
            if all_resumes != [resume_event]:
                raise HostValidationError("checkpoint-resume trace contains conflicting lifecycle events")
            if any(isinstance(event.get("data"), dict)
                   and event["data"].get("changed") is True
                   and event["data"].get("head") == merge_sha
                   and event["data"].get("main_sha") == second_parent
                   for _, event in sync_events):
                raise HostValidationError("checkpoint-resume trace contains conflicting in-place sync events")
            merge_kind = "checkpoint-resume"
        elif not resume_events and not all_resumes:
            changed_sync = [(i, event) for i, event in sync_events
                            if isinstance(event.get("data"), dict)
                            and event["data"].get("changed") is True
                            and event["data"].get("head") == merge_sha
                            and event["data"].get("main_sha") == second_parent]
            if len(changed_sync) != 1 or len(sync_events) != 2:
                raise HostValidationError("in-place main-sync merge lacks its unique exact lifecycle witness")
            changed_pos, changed_event = changed_sync[0]
            if not checkpoint_pos < changed_pos < later_noop[0][0]:
                raise HostValidationError("in-place main-sync lifecycle events are out of order")
            merge_kind = "in-place-main-sync"
        else:
            raise HostValidationError("synchronization merge trace has conflicting resume events")
        merge_tree = subprocess.run(["git", "merge-tree", "--write-tree", first_parent, second_parent],
                                    cwd=repo, text=True, capture_output=True)
        stored_tree = _git(repo, "rev-parse", f"{merge_sha}^{{tree}}")
        if merge_tree.returncode or not merge_tree.stdout.splitlines() \
                or merge_tree.stdout.splitlines()[0].strip() != stored_tree:
            raise HostValidationError("synchronization merge tree differs from deterministic Git merge")
        inherited_paths = set(_changed_paths(repo, f"{source_base}..{second_parent}"))
        # Local authorship is the union of first-parent non-merge commit diffs.
        # Paths touched on both sides remain owned and keep their test coverage.
        for path in owned_paths:
            if any(subprocess.run(["git", "cat-file", "-e", f"{revision}:{path}"],
                                  cwd=repo, capture_output=True).returncode
                   for revision in (merge_sha, source_head)):
                raise HostValidationError("synchronization merge loses workstream-owned source")
        merge_provenance = {
            "commit": merge_sha, "first_parent": first_parent, "second_parent": second_parent,
            "checkpoint_event_index": checkpoint_pos,
            "main_sync_event_index": later_noop[0][0], "tree": stored_tree,
            "checkpoint_event_id": {"run_id": run_id, "position": checkpoint_pos,
                                    "timestamp_utc": checkpoint_event.get("timestamp_utc")},
            "main_sync_event_id": {"run_id": run_id, "position": later_noop[0][0],
                                   "timestamp_utc": later_noop[0][1].get("timestamp_utc")},
            "merge_tree_proof": "git-merge-tree-write-tree-exact",
            "owned_paths": sorted(owned_paths), "inherited_paths": sorted(inherited_paths),
            "overlapping_paths": sorted(owned_paths.intersection(inherited_paths)),
        }
        if merge_kind == "checkpoint-resume":
            merge_provenance["resume_event_index"] = resume_pos
            merge_provenance["resume_event_id"] = {
                "run_id": run_id, "position": resume_pos,
                "timestamp_utc": resume_event.get("timestamp_utc"),
            }
            checkpoint_resume_merge = merge_provenance
        else:
            merge_provenance["changed_sync_event_index"] = changed_pos
            merge_provenance["changed_sync_event_id"] = {
                "run_id": run_id, "position": changed_pos,
                "timestamp_utc": changed_event.get("timestamp_utc"),
            }
            source_main_sync_merge = merge_provenance
    if followup is None and (
        (source_bearing_archive and commits[-1] != landing_commit)
        or (not source_bearing_archive and archive_parent != commits[-1])
    ):
        raise HostValidationError("split source span does not end at its canonical archive boundary")
    if followup is not None:
        source_paths = sorted(set(_changed_paths(repo, f"{source_base}..{landing_commit}")
                                  + followup["followup_paths"]))
    else:
        source_paths = sorted(owned_paths) if (checkpoint_resume_merge or source_main_sync_merge) else _changed_paths(
            repo, f"{source_base}..{source_head}")
    if paired_review_metadata_path is not None:
        source_paths = [path for path in source_paths if path != paired_review_metadata_path]
    code_paths = _source_code_paths(source_paths)
    if not code_paths:
        raise HostValidationError("split source span contains no implementation source or test files")

    # The archived task must itself identify every source/test path so a branch
    # carrying unrelated code cannot be laundered through an archive-only commit.
    documented = set(re.findall(r"custodian/[A-Za-z0-9_./-]+", target_packet_text))
    documented.add(f"{target_workstream.upper().replace('-', '_')}_CLAUDE_SUMMARY.md")
    work_surface = header_field(target_packet_text, "Work surface") or ""
    documented.update(_expand_braced_work_surface_paths(work_surface))
    if archive_sync_followup is not None:
        documented.update(archive_sync_followup.get("authenticated_followup_paths", []))
    packet_terms = set(re.findall(r"[a-z0-9]+", target_packet_text.lower()))
    archive_source_paths = set(extra_archive_paths) if source_bearing_archive else set()
    if paired_review_metadata_path is not None:
        archive_source_paths.discard(paired_review_metadata_path)

    attested_source_paths = (
        (set(scope_attestation["source_files"]) if scope_attestation is not None else set())
        | historical_recovery_paths
    )

    def is_documented(path: str) -> bool:
        if path in archive_source_paths and path in documented:
            return True
        return _source_path_documented(
            path, target_packet_text, documented, packet_terms,
            uid_companion_paths, attested_source_paths,
        )

    undocumented = {path for path in code_paths if not is_documented(path)}
    undocumented.update(path for path in archive_source_paths if not is_documented(path))
    if undocumented:
        raise HostValidationError(
            "split source span contains code/test paths not documented by its target packet: "
            + ", ".join(sorted(undocumented))
        )

    if (trace_landing_kind in {"main-sync-merge", "main-sync-merge-followup"}
            and reset_followup is None):
        if archive_sync_followup is not None:
            sync_merges = archive_sync_followup["sync_merges"]
        else:
            sync_merges = [{"commit": trace_landing, "first_parent": landing_commit,
                            "main_sha": trace_main_sync_sha}]
        readme_path = f"{PACKET_ROOT}/README.md"
        sync_source_paths = set(source_paths)
        for sync_merge in sync_merges:
            merge = sync_merge["commit"]
            first_parent = sync_merge["first_parent"]
            changed_in_merge = set(_changed_paths(repo, f"{first_parent}..{merge}"))
            if target_packet_path in changed_in_merge:
                authenticated_merge_paths = (
                    set(archive_sync_followup.get("authenticated_merge_paths", {}).get(merge, []))
                    if archive_sync_followup is not None else set()
                )
                if target_packet_path not in authenticated_merge_paths:
                    raise HostValidationError(
                        "main-sync merge changes archived target packet from archive-first-parent version"
                    )
            changed_source_paths = changed_in_merge.intersection(sync_source_paths)
            if readme_path in changed_source_paths:
                authenticated_merge_paths = (
                    set(archive_sync_followup.get("authenticated_merge_paths", {}).get(merge, []))
                    if archive_sync_followup is not None else set()
                )
                if readme_path not in authenticated_merge_paths:
                    first_parent_readme = subprocess.run(
                        ["git", "show", f"{first_parent}:{readme_path}"], cwd=repo,
                        capture_output=True,
                    )
                    second_parent_readme = subprocess.run(
                        ["git", "show", f"{sync_merge['main_sha']}:{readme_path}"], cwd=repo,
                        capture_output=True,
                    )
                    merged_readme = subprocess.run(
                        ["git", "show", f"{merge}:{readme_path}"], cwd=repo,
                        capture_output=True,
                    )
                    if (first_parent_readme.returncode or second_parent_readme.returncode
                            or merged_readme.returncode
                            or not (_managed_packet_index_additive_reconciliation(
                                first_parent_readme.stdout, second_parent_readme.stdout,
                                merged_readme.stdout)
                                or _managed_packet_index_archival_reconciliation(
                                    repo, first_parent, sync_merge["main_sha"], merge,
                                ) or _resumed_provenance_index_reconciliation(
                                    repo, first_parent, sync_merge["main_sha"], merge,
                                ))):
                        raise HostValidationError(
                            "main-sync README change is not an authenticated managed-index reconciliation"
                        )
                changed_source_paths.remove(readme_path)
            if archive_sync_followup is not None:
                authenticated_resolution = set(
                    archive_sync_followup.get("authenticated_merge_paths", {})
                    .get(merge, [])
                )
                changed_source_paths.difference_update(authenticated_resolution)
            if changed_source_paths and _verified_procession_bootstrap_main_sync(
                repo, target_workstream, landing_commit, merge,
                sync_merge["main_sha"], changed_source_paths,
            ):
                changed_source_paths.clear()
            if changed_source_paths:
                raise HostValidationError(
                    "main-sync merge changes reviewed source from archive-first-parent version: "
                    f"{merge}: {', '.join(sorted(changed_source_paths))}"
                )

    trace_sha = subprocess.run(["git", "rev-parse", "--verify", f"{ref}^{{commit}}"], cwd=repo,
                               text=True, capture_output=True, check=True).stdout.strip()
    trace_blob = subprocess.run(["git", "show", f"{ref}:trace.jsonl"], cwd=repo,
                                capture_output=True, check=True).stdout
    provenance = {"kind": "workstream-lifecycle-trace",
            "ref": ref, "trace_commit": trace_sha, "trace_sha256": _sha256(trace_blob),
            "run_id": run_id, "workstream": target_workstream,
            "trace_landing_commit": trace_landing,
            "trace_landing_kind": trace_landing_kind,
            "trace_main_sync_sha": trace_main_sync_sha,
            "claim_trace": {"ref": claim_record["ref"], "run_id": claim_record["run_id"],
                            "worktree": claim_record["worktree"], "branch": claim_record["branch"],
                            "base": claim_record["base"]},
            "landing_trace": {"ref": landing_record["ref"], "run_id": landing_record["run_id"],
                              "worktree": landing_record["path"], "branch": landing_record["branch"],
                              "landing": landing_record["landing"]},
            "archive_kind": "source-bearing" if source_bearing_archive else "archive-only"}
    if claim_record.get("resumed_head") is not None:
        provenance["claim_trace"]["claim_base"] = claim_record["claim_base"]
        provenance["claim_trace"]["resumed_head"] = claim_record["resumed_head"]
        provenance["claim_trace"]["create_event_index"] = claim_record["create_event_index"]
        provenance["claim_trace"]["resume_event_index"] = claim_record["resume_event_index"]
    if checkpoint_resume_merge is not None:
        provenance["checkpoint_resume_merge"] = checkpoint_resume_merge
    if source_main_sync_merge is not None:
        provenance["source_main_sync_merge"] = source_main_sync_merge
    if scope_attestation is not None:
        provenance["scope_attestation"] = scope_attestation
    if followup is not None:
        provenance["post_merge_followup"] = followup
    if source_artifact is not None:
        provenance["source_artifact"] = source_artifact
    return {"base": source_base, "head": source_head, "commits": commits,
            "paths": source_paths, "provenance": provenance}


def resolve_validation_source_span(repo: Path, reviewed_main: str, implementation_commit: str,
                                   target_workstream: str | None = None,
                                   target_packet_path: str | None = None) -> dict:
    """Keep canonical review identity separate from the source/test validation range."""
    repo = Path(repo).resolve()
    landing = _git(repo, "rev-parse", "--verify", f"{implementation_commit}^{{commit}}")
    parent = _git(repo, "rev-parse", f"{landing}^1")
    landing_paths = _changed_paths(repo, f"{parent}..{landing}")

    def has_path(revision: str, path: str) -> bool:
        return subprocess.run(["git", "cat-file", "-e", f"{revision}:{path}"], cwd=repo,
                              capture_output=True).returncode == 0

    archive_transition = False
    if target_workstream and target_packet_path and "/archived/" in target_packet_path:
        active_packet = target_packet_path.replace("/archived/", "/", 1)
        archive_transition = (has_path(parent, active_packet) and not has_path(landing, active_packet)
                             and not has_path(parent, target_packet_path)
                             and has_path(landing, target_packet_path))
    if _source_code_paths(landing_paths) and not archive_transition:
        return {"base": parent, "head": landing, "commits": [landing], "paths": landing_paths,
                "provenance": {"kind": "canonical-implementation-commit"}}
    if not target_workstream or not target_packet_path:
        raise HostValidationError("archive-only implementation requires exact target workstream provenance")
    try:
        packet_text = _git(repo, "show", f"{reviewed_main}:{target_packet_path}")
    except HostValidationError as exc:
        raise HostValidationError("cannot load pinned target packet for source-span provenance") from exc
    return _split_landing_source_span(repo, reviewed_main, landing, target_workstream,
                                      target_packet_path, packet_text)


def verify_pinned_canonical_commit_source_span(repo: Path, implementation_commit: str,
                                               source_span: dict) -> dict:
    """Verify an immutable, previously recorded direct-commit source span."""
    repo = Path(repo).resolve()
    landing = _git(repo, "rev-parse", "--verify", f"{implementation_commit}^{{commit}}")
    parent = _git(repo, "rev-parse", f"{landing}^1")
    diff = subprocess.run(["git", "diff-tree", "-r", "--name-only", "--find-renames", parent, landing],
                          cwd=repo, text=True, capture_output=True, check=True)
    expected_paths = sorted(path for path in diff.stdout.splitlines() if path)
    if (not isinstance(source_span, dict)
            or source_span != {"base": parent, "head": landing, "commits": [landing],
                               "paths": expected_paths,
                               "provenance": {"kind": "canonical-implementation-commit"}}
            or not _source_code_paths(expected_paths)):
        raise HostValidationError("pinned source span is not the exact canonical implementation commit diff")
    return source_span


def _validate_report(report: dict, implementation_paths: list[str]) -> None:
    if report.get("schema") != "custodian.validation.result.v1":
        raise HostValidationError("host validation report has the wrong schema")
    coverage = report.get("coverage")
    tests = report.get("tests")
    selected = report.get("selected")
    if (report.get("passed") is not True or not isinstance(coverage, dict)
            or coverage.get("complete") is not True or coverage.get("uncovered_files")
            or not isinstance(tests, list) or not tests or not isinstance(selected, list) or not selected):
        raise HostValidationError("host validation report is failed, incomplete, or vacuous")
    test_ids = {item.get("id") for item in tests if isinstance(item, dict)}
    if (len(test_ids) != len(tests) or test_ids != set(selected)
            or any(item.get("status") != "passed" for item in tests)):
        raise HostValidationError("host validation tests do not exactly match the selected passing IDs")
    summary = report.get("summary")
    if (not isinstance(summary, dict) or summary.get("selected") != len(tests)
            or summary.get("passed") != len(tests)
            or any(summary.get(key) != 0 for key in ("failed", "timed_out", "skipped", "infrastructure_errors"))):
        raise HostValidationError("host validation summary does not verify all selected checks passed")
    code_paths = _source_code_paths(implementation_paths)
    reported_paths = set(report.get("changed_files") or [])
    if not code_paths.issubset(reported_paths):
        raise HostValidationError("host validation changed-file selection omits part of the implementation diff")
    covered = set(coverage.get("covered_files") or [])
    excluded = set(coverage.get("excluded_files") or [])
    if not code_paths.issubset(covered | excluded):
        raise HostValidationError("host validation coverage omits files from the implementation diff")
    code_paths = _source_code_paths(implementation_paths)
    if not code_paths or not code_paths.issubset(covered):
        raise HostValidationError("host validation does not cover changed implementation source/test files")
    covered_by = coverage.get("covered_by")
    if not isinstance(covered_by, dict) or any(
        not (set(covered_by.get(path, [])) & set(selected)) for path in code_paths
    ):
        raise HostValidationError("host validation has no selected test owner for changed source/test files")


def run_coordinator_validation(repo: Path, run_dir: Path, reviewed_main: str, implementation_commit: str,
                               *, target_workstream: str | None = None,
                               target_packet_path: str | None = None,
                               source_span_override: dict | None = None,
                               run_validation: Callable | None = None,
                               capability_probe: Callable[[], dict[str, bool]] = probe_host_capabilities) -> dict:
    """Run and pin the canonical changed-file suite before launching the reviewer.

    The exact implementation parent drives selection. Validation itself delegates to
    run_validation.py, which acquires the canonical Godot project lock and job budget.
    Evidence paths are create-only so retries cannot silently replace prior results.
    """
    worktree = Path(repo).resolve()
    run_dir = Path(run_dir).resolve()
    report_path = run_dir / "validation.json"
    metadata_path = run_dir / "coordinator-validation.json"
    if report_path.exists() or metadata_path.exists():
        raise HostValidationError("coordinator validation evidence already exists; refusing to overwrite it")

    head = _git(worktree, "rev-parse", "--verify", "HEAD^{commit}")
    if head != reviewed_main:
        raise HostValidationError("claimed review worktree HEAD differs from pinned reviewed main")
    initial_status = _git(worktree, "status", "--porcelain", "--untracked-files=all")
    if initial_status:
        raise HostValidationError("claimed review worktree is dirty before host validation")
    initial_sidecars = _snapshot_png_import_sidecars(worktree)
    if "unsafe" in initial_sidecars.values():
        raise HostValidationError("review worktree has an unsafe preexisting PNG import sidecar")
    implementation_commit = _git(worktree, "rev-parse", "--verify", f"{implementation_commit}^{{commit}}")
    parent = _git(worktree, "rev-parse", "--verify", f"{implementation_commit}^1")
    if subprocess.run(["git", "merge-base", "--is-ancestor", parent, implementation_commit],
                      cwd=worktree, capture_output=True).returncode:
        raise HostValidationError("implementation parent is not an ancestor of the pinned implementation")
    if subprocess.run(["git", "merge-base", "--is-ancestor", implementation_commit, reviewed_main],
                      cwd=worktree, capture_output=True).returncode:
        raise HostValidationError("pinned implementation is not an ancestor of reviewed main")

    if source_span_override is not None:
        source_span = verify_pinned_canonical_commit_source_span(
            worktree, implementation_commit, source_span_override,
        )
    else:
        source_span = resolve_validation_source_span(
            worktree, reviewed_main, implementation_commit, target_workstream, target_packet_path,
        )
    source_base = source_span["base"]
    source_head = source_span["head"]
    implementation_paths = list(source_span["paths"])
    # The validation base is the source-span base, so every source/test file
    # under review must also be selected by the canonical changed-file runner.
    selected_source_paths = _git_paths(worktree, f"{source_base}..{reviewed_main}")
    required_changed_paths = set(_source_code_paths(implementation_paths))
    if not required_changed_paths or not required_changed_paths.issubset(selected_source_paths):
        raise HostValidationError("canonical changed-file selection does not include the implementation diff")
    code_paths = [path for path in implementation_paths
                  if Path(path).suffix.lower() in {".gd", ".py", ".gdshader", ".tscn", ".tres", ".json"}]
    source_hashes = _source_hashes(worktree, code_paths)
    capabilities = capability_probe()

    command = [sys.executable, str(worktree / "custodian/tools/validation/run_validation.py"),
               "--changed", "--base", source_base, "--json"]
    execute = run_validation or (lambda argv, cwd: subprocess.run(
        argv, cwd=cwd, text=True, capture_output=True, check=False,
    ))
    try:
        process = execute(command, worktree)
    except OSError as exc:
        raise HostValidationError(f"trusted coordinator could not launch canonical validation: {exc}") from exc
    raw_report = process.stdout.encode("utf-8")
    report_hash = _sha256(raw_report)
    # Keep even a failed structured report for diagnosis. A later retry gets a new run ID.
    _write_exclusive(report_path, raw_report)
    if process.stderr:
        _write_exclusive(run_dir / "coordinator-validation.stderr", process.stderr.encode("utf-8"))
    try:
        generated_imports, import_cleanup_error = _capture_generated_png_imports(
            worktree, run_dir, initial_sidecars,
        )
    except (HostValidationError, OSError) as exc:
        generated_imports, import_cleanup_error = [], str(exc)
    try:
        report = json.loads(raw_report)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        report = None
        parse_error = str(exc)
    else:
        parse_error = None

    current_head = _git(worktree, "rev-parse", "--verify", "HEAD^{commit}")
    current_status = _git(worktree, "status", "--porcelain", "--untracked-files=all")
    current_source_hashes = _source_hashes(worktree, code_paths)
    source_changed = (current_head != head or bool(current_status)
                      or current_source_hashes != source_hashes or bool(import_cleanup_error))
    metadata = {
        "schema": "custodian.paired_review_host_validation.v1",
        "worktree": str(worktree),
        "reviewed_main": reviewed_main,
        "implementation_commit": implementation_commit,
        "implementation_parent": parent,
        "source_span": source_span,
        "source_span_base": source_base,
        "source_span_head": source_head,
        "implementation_paths": implementation_paths,
        "code_paths": code_paths,
        "selected_source_paths": selected_source_paths,
        "source_sha256": source_hashes,
        "source_changed_during_validation": source_changed,
        "generated_import_manifest_sha256": (
            _sha256((run_dir / "generated-import-artifacts/manifest.json").read_bytes())
            if (run_dir / "generated-import-artifacts/manifest.json").is_file() else None
        ),
        "generated_import_count": len(generated_imports),
        "generated_import_cleanup_error": import_cleanup_error,
        "capabilities": capabilities,
        "command": command,
        "exit_code": process.returncode,
        "report_path": str(report_path),
        "report_sha256": report_hash,
        "report_parse_error": parse_error,
        "summary": report.get("summary") if isinstance(report, dict) else None,
        "selected": report.get("selected") if isinstance(report, dict) else None,
    }
    metadata_bytes = (json.dumps(metadata, indent=2, sort_keys=True) + "\n").encode("utf-8")
    _write_exclusive(metadata_path, metadata_bytes)
    metadata["metadata_sha256"] = _sha256(metadata_bytes)

    if source_changed:
        raise HostValidationError("reviewed worktree source changed during host validation")
    if import_cleanup_error:
        raise HostValidationError(import_cleanup_error)
    if process.returncode:
        raise HostValidationError(f"canonical host validation failed with exit code {process.returncode}")
    if not isinstance(report, dict):
        raise HostValidationError("canonical host validation did not return structured JSON")
    _validate_report(report, implementation_paths)
    return metadata


def verify_coordinator_validation(repo: Path, run_dir: Path, reviewed_main: str,
                                  implementation_commit: str, *, target_workstream: str | None = None,
                                  target_packet_path: str | None = None,
                                  source_span_override: dict | None = None,
                                  expected_report_sha256: str,
                                  expected_metadata_sha256: str) -> dict:
    """Recheck pinned host evidence after the restricted reviewer exits."""
    run_dir = Path(run_dir).resolve()
    report_path = run_dir / "validation.json"
    metadata_path = run_dir / "coordinator-validation.json"
    try:
        report_bytes = report_path.read_bytes()
        metadata_bytes = metadata_path.read_bytes()
        metadata = json.loads(metadata_bytes)
        report = json.loads(report_bytes)
    except (OSError, json.JSONDecodeError) as exc:
        raise HostValidationError(f"coordinator validation evidence is missing or malformed: {exc}") from exc
    if _sha256(report_bytes) != expected_report_sha256:
        raise HostValidationError("coordinator validation report digest changed during reviewer execution")
    if _sha256(metadata_bytes) != expected_metadata_sha256:
        raise HostValidationError("coordinator validation provenance digest changed during reviewer execution")
    if source_span_override is not None:
        expected_span = verify_pinned_canonical_commit_source_span(
            repo, implementation_commit, source_span_override,
        )
    else:
        expected_span = resolve_validation_source_span(
            repo, reviewed_main, implementation_commit, target_workstream, target_packet_path,
        )
    if (metadata.get("schema") != "custodian.paired_review_host_validation.v1"
            or metadata.get("reviewed_main") != reviewed_main
            or metadata.get("implementation_commit") != implementation_commit
            or metadata.get("source_span") != expected_span
            or metadata.get("source_span_base") != expected_span.get("base")
            or metadata.get("source_span_head") != expected_span.get("head")
            or metadata.get("report_sha256") != expected_report_sha256
            or metadata.get("source_changed_during_validation") is not False):
        raise HostValidationError("coordinator validation provenance does not match the pinned review identity")
    if _git(Path(repo), "rev-parse", "--verify", "HEAD^{commit}") != reviewed_main:
        raise HostValidationError("reviewed worktree HEAD changed after host validation")
    if _source_hashes(Path(repo), metadata.get("code_paths") or []) != metadata.get("source_sha256"):
        raise HostValidationError("reviewed implementation source changed after host validation")
    _verify_generated_import_manifest(Path(repo), run_dir, metadata)
    if metadata.get("implementation_paths") != expected_span.get("paths"):
        raise HostValidationError("coordinator source path inventory differs from the verified source span")
    _validate_report(report, expected_span.get("paths") or [])
    return report
