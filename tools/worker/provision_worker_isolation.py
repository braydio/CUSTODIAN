#!/usr/bin/python3
"""Install or remove only the disposable local worker-proof service."""

from __future__ import annotations

import argparse
import grp
import hashlib
import os
import pwd
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

WORKER = "custodian-worker"
GROUP = "custodian-worker"
STATE = Path("/var/lib/custodian-worker")
RESOLVERS = "# Dedicated public resolvers for the loopback-denied proof worker.\nnameserver 1.1.1.1\nnameserver 2606:4700:4700::1111\n"
FILES = (
    (Path("deploy/systemd/custodian-worker@.service"), Path("/etc/systemd/system/custodian-worker@.service"), 0o644),
    (Path("tools/worker/custodian-worker-launch"), Path("/usr/local/libexec/custodian-worker/custodian-worker-launch"), 0o755),
    (Path("tools/worker/worker_launcher.py"), Path("/usr/local/libexec/custodian-worker/worker_launcher.py"), 0o644),
    (Path("tools/worker/validate_worker_isolation.py"), Path("/usr/local/libexec/custodian-worker/validate_worker_isolation.py"), 0o755),
)


class ProvisionError(RuntimeError):
    pass


def mapped(root: Path, absolute: Path) -> Path:
    return root / absolute.relative_to("/")


def check_directory(path: Path, mode: int, root_mode: bool, owner: tuple[int, int] | None = None) -> None:
    if path.is_symlink():
        raise ProvisionError(f"refusing symlink directory: {path}")
    if not path.exists():
        return
    if not path.is_dir():
        raise ProvisionError(f"refusing non-directory path: {path}")
    info = path.stat()
    if stat.S_IMODE(info.st_mode) != mode:
        raise ProvisionError(f"unexpected mode on managed directory {path}: {stat.S_IMODE(info.st_mode):o}")
    expected_owner = owner if owner is not None else ((0, 0) if root_mode else None)
    if expected_owner is not None and (info.st_uid, info.st_gid) != expected_owner:
        raise ProvisionError(f"unexpected owner on managed directory: {path}")


def safe_directory(path: Path, mode: int, root_mode: bool, owner: tuple[int, int] | None = None) -> None:
    check_directory(path, mode, root_mode, owner)
    if path.exists():
        return
    path.mkdir(parents=True, exist_ok=False)
    os.chmod(path, mode)
    expected_owner = owner if owner is not None else ((0, 0) if root_mode else None)
    if expected_owner is not None:
        os.chown(path, *expected_owner)


def exact_file(source: Path, destination: Path, mode: int, root_mode: bool) -> None:
    data = source.read_bytes()
    if destination.is_symlink():
        raise ProvisionError(f"refusing symlink file: {destination}")
    if destination.exists():
        if not destination.is_file() or destination.read_bytes() != data:
            raise ProvisionError(f"refusing to overwrite unexpected file: {destination}")
        current_mode = stat.S_IMODE(destination.stat().st_mode)
        if current_mode != mode:
            raise ProvisionError(f"unexpected mode on managed file {destination}: {current_mode:o}")
        if root_mode and (destination.stat().st_uid != 0 or destination.stat().st_gid != 0):
            raise ProvisionError(f"unexpected owner on managed file: {destination}")
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0)
    fd = os.open(destination, flags, mode)
    try:
        with os.fdopen(fd, "wb", closefd=False) as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
    finally:
        os.close(fd)
    os.chmod(destination, mode)
    if root_mode:
        os.chown(destination, 0, 0)


def exact_resolver(destination: Path, root_mode: bool) -> None:
    content = RESOLVERS.encode()
    if destination.is_symlink():
        raise ProvisionError(f"refusing symlink resolver file: {destination}")
    if destination.exists():
        if not destination.is_file() or destination.read_bytes() != content:
            raise ProvisionError(f"refusing to overwrite unexpected resolver config: {destination}")
        if stat.S_IMODE(destination.stat().st_mode) != 0o644:
            raise ProvisionError(f"unexpected resolver-config mode: {destination}")
        if root_mode and (destination.stat().st_uid != 0 or destination.stat().st_gid != 0):
            raise ProvisionError(f"unexpected resolver-config owner: {destination}")
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0), 0o644)
    try:
        with os.fdopen(fd, "wb", closefd=False) as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
    finally:
        os.close(fd)
    if root_mode:
        os.chown(destination, 0, 0)


def command(args: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if check and result.returncode:
        raise ProvisionError(f"command failed ({result.returncode}): {args[0]}")
    return result


def validate_existing_identity() -> None:
    try:
        group = grp.getgrnam(GROUP)
    except KeyError:
        group = None
    try:
        user = pwd.getpwnam(WORKER)
    except KeyError:
        user = None
    if group is not None and group.gr_mem:
        raise ProvisionError("existing worker group has supplementary members")
    if user is not None:
        if group is None or user.pw_gid != group.gr_gid:
            raise ProvisionError("existing worker account has an unexpected primary group")
        if user.pw_dir != str(STATE / "home") or user.pw_shell not in ("/usr/bin/nologin", "/sbin/nologin"):
            raise ProvisionError("existing worker account has an unexpected home or shell")
        groups = {g.gr_gid for g in grp.getgrall() if WORKER in g.gr_mem}
        groups.add(user.pw_gid)
        if groups != {user.pw_gid}:
            raise ProvisionError("existing worker account has supplementary group membership")


def ensure_identity() -> tuple[int, int]:
    validate_existing_identity()
    try:
        group = grp.getgrnam(GROUP)
    except KeyError:
        command(["/usr/bin/groupadd", "--system", GROUP])
        group = grp.getgrnam(GROUP)
    try:
        user = pwd.getpwnam(WORKER)
    except KeyError:
        command([
            "/usr/bin/useradd", "--system", "--no-create-home", "--gid", GROUP,
            "--home-dir", str(STATE / "home"), "--shell", "/usr/bin/nologin",
            "--comment", "CUSTODIAN disposable worker proof", WORKER,
        ])
        user = pwd.getpwnam(WORKER)
    if user.pw_gid != group.gr_gid:
        raise ProvisionError("worker primary group changed during provisioning")
    return user.pw_uid, group.gr_gid


def systemd_state(unit: str) -> None:
    active = command(["/usr/bin/systemctl", "is-active", unit], check=False).stdout.strip()
    if active not in ("inactive", "unknown", "failed"):
        raise ProvisionError(f"refusing installation while {unit} is {active}")
    enabled = command(["/usr/bin/systemctl", "is-enabled", unit], check=False).stdout.strip()
    if enabled not in ("disabled", "static", "not-found", "indirect"):
        raise ProvisionError(f"refusing installation while {unit} is enabled ({enabled})")


def install(repo: Path, root: Path) -> None:
    root_mode = root == Path("/")
    if root_mode and os.geteuid() != 0:
        raise ProvisionError("install requires root; use sudo")
    for source_rel, dest_abs, mode in FILES:
        source, dest = repo / source_rel, mapped(root, dest_abs)
        if not source.is_file():
            raise ProvisionError(f"required implementation file is missing: {source_rel}")
        if dest.is_symlink() or (dest.exists() and (not dest.is_file() or dest.read_bytes() != source.read_bytes())):
            raise ProvisionError(f"refusing to overwrite unexpected file: {dest}")
        if dest.exists() and stat.S_IMODE(dest.stat().st_mode) != mode:
            raise ProvisionError(f"unexpected mode on managed file {dest}")
        if root_mode and dest.exists() and (dest.stat().st_uid != 0 or dest.stat().st_gid != 0):
            raise ProvisionError(f"unexpected owner on managed file: {dest}")
    resolver_path = mapped(root, Path("/etc/custodian-worker/resolv.conf"))
    if resolver_path.is_symlink() or (resolver_path.exists() and resolver_path.read_text() != RESOLVERS):
        raise ProvisionError(f"refusing to overwrite unexpected resolver config: {resolver_path}")
    if resolver_path.exists() and stat.S_IMODE(resolver_path.stat().st_mode) != 0o644:
        raise ProvisionError(f"unexpected resolver-config mode: {resolver_path}")
    if root_mode and resolver_path.exists() and (resolver_path.stat().st_uid != 0 or resolver_path.stat().st_gid != 0):
        raise ProvisionError(f"unexpected resolver-config owner: {resolver_path}")
    for _, dest, _ in FILES:
        check_directory(mapped(root, dest.parent), 0o755, root_mode)
    state = mapped(root, STATE)
    check_directory(state, 0o755, root_mode)
    expected_owner = None
    if root_mode:
        validate_existing_identity()
        try:
            existing_user = pwd.getpwnam(WORKER)
            existing_group = grp.getgrnam(GROUP)
            expected_owner = (existing_user.pw_uid, existing_group.gr_gid)
        except KeyError:
            expected_owner = None
    else:
        expected_owner = (os.getuid(), os.getgid())
    for name in ("home", "codex-home", "tmp", "workspaces"):
        path = state / name
        if root_mode and path.exists() and expected_owner is None:
            raise ProvisionError(f"worker state exists without its dedicated account: {path}")
        check_directory(path, 0o700, root_mode, expected_owner if root_mode else None)
    check_directory(resolver_path.parent, 0o755, root_mode)
    if root_mode:
        systemd_state("custodian-worker@proof.service")
        uid, gid = ensure_identity()
    else:
        uid, gid = os.getuid(), os.getgid()
    for _, dest, _ in FILES:
        safe_directory(mapped(root, dest.parent), 0o755, root_mode)
    safe_directory(state, 0o755, root_mode)
    for name in ("home", "codex-home", "tmp", "workspaces"):
        safe_directory(state / name, 0o700, root_mode, (uid, gid) if root_mode else None)
    safe_directory(resolver_path.parent, 0o755, root_mode)
    exact_resolver(resolver_path, root_mode)
    for source_rel, dest_abs, mode in FILES:
        exact_file(repo / source_rel, mapped(root, dest_abs), mode, root_mode)
    if root_mode:
        command(["/usr/bin/systemctl", "daemon-reload"])
        systemd_state("custodian-worker@proof.service")
    print("worker isolation files installed; service remains disabled and inactive")


def git_file(repo: Path, ref: str, relative: Path) -> bytes:
    result = subprocess.run(["git", "-C", str(repo), "show", f"{ref}:{relative.as_posix()}"],
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if result.returncode:
        raise ProvisionError(f"cannot read approved prior worker source at {ref}:{relative.as_posix()}")
    return result.stdout


def atomic_file(path: Path, data: bytes, mode: int, owner: tuple[int, int] | None) -> None:
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.upgrade-", dir=path.parent)
    temp_path = Path(temporary)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temp_path, mode)
        if owner is not None:
            os.chown(temp_path, *owner)
        os.replace(temp_path, path)
        directory_fd = os.open(path.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
    finally:
        temp_path.unlink(missing_ok=True)


def upgrade(repo: Path, root: Path, from_ref: str,
            installed_hash_overrides: dict[str, str] | None = None) -> None:
    """Replace only installed files proven byte-identical to an explicit Git baseline."""
    root_mode = root == Path("/")
    if root_mode and os.geteuid() != 0:
        raise ProvisionError("upgrade requires root; use sudo")
    resolved = subprocess.run(["git", "-C", str(repo), "rev-parse", "--verify", "--end-of-options",
                               f"{from_ref}^{{commit}}"], text=True, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, check=False)
    if resolved.returncode:
        raise ProvisionError("upgrade baseline must resolve to a commit")
    if root_mode:
        systemd_state("custodian-worker@proof.service")

    installed_hash_overrides = installed_hash_overrides or {}
    allowed_paths = {source_rel.as_posix() for source_rel, _, _ in FILES}
    if set(installed_hash_overrides) - allowed_paths or any(
            not re.fullmatch(r"[0-9a-f]{64}", digest) for digest in installed_hash_overrides.values()):
        raise ProvisionError("installed-file SHA override must name a managed path and a lowercase SHA-256")
    staged: list[tuple[Path, bytes, bytes, int, tuple[int, int] | None]] = []
    for source_rel, dest_abs, mode in FILES:
        source, destination = repo / source_rel, mapped(root, dest_abs)
        if not source.is_file() or destination.is_symlink() or not destination.is_file():
            raise ProvisionError(f"upgrade requires regular source and installed files: {source_rel}")
        old = git_file(repo, from_ref, source_rel)
        current = destination.read_bytes()
        info = destination.stat()
        expected_hash = installed_hash_overrides.get(source_rel.as_posix())
        matches_baseline = (hashlib.sha256(current).hexdigest() == expected_hash) if expected_hash else (current == old)
        if not matches_baseline:
            raise ProvisionError(f"installed file does not match approved baseline: {destination}")
        if stat.S_IMODE(info.st_mode) != mode:
            raise ProvisionError(f"unexpected mode on managed file {destination}")
        owner = (0, 0) if root_mode else None
        if root_mode and (info.st_uid, info.st_gid) != owner:
            raise ProvisionError(f"unexpected owner on managed file: {destination}")
        new = source.read_bytes()
        if new != current:
            staged.append((destination, current, new, mode, owner))

    resolver_path = mapped(root, Path("/etc/custodian-worker/resolv.conf"))
    if resolver_path.is_symlink() or not resolver_path.is_file() or resolver_path.read_text() != RESOLVERS:
        raise ProvisionError("installed worker resolver differs from the managed configuration")
    if stat.S_IMODE(resolver_path.stat().st_mode) != 0o644:
        raise ProvisionError("unexpected resolver-config mode")
    if root_mode and (resolver_path.stat().st_uid != 0 or resolver_path.stat().st_gid != 0):
        raise ProvisionError("unexpected resolver-config owner")

    changed: list[tuple[Path, bytes, bytes, int, tuple[int, int] | None]] = []
    try:
        for item in staged:
            path, old, new, mode, owner = item
            atomic_file(path, new, mode, owner)
            changed.append(item)
    except OSError as exc:
        rollback_errors = []
        for path, old, _, mode, owner in reversed(changed):
            try:
                atomic_file(path, old, mode, owner)
            except OSError:
                rollback_errors.append(path.name)
        if rollback_errors:
            raise ProvisionError("upgrade failed and rollback was incomplete: " + ", ".join(rollback_errors)) from exc
        raise ProvisionError("upgrade failed; previously replaced files were restored") from exc

    if root_mode:
        command(["/usr/bin/systemctl", "daemon-reload"])
        systemd_state("custodian-worker@proof.service")
    if root_mode:
        print(f"worker isolation files upgraded from {resolved.stdout.strip()}; service remains disabled and inactive")
    else:
        print(f"worker isolation files upgraded from {resolved.stdout.strip()}; host service state was not touched")


def verify_disposable_tree(path: Path, owner: tuple[int, int]) -> None:
    if path.is_mount():
        raise ProvisionError(f"refusing worker state mounted at a separate mount point: {path}")
    root_device = path.stat().st_dev
    for current, dirs, files in os.walk(path, topdown=True, followlinks=False):
        current_path = Path(current)
        current_info = current_path.lstat()
        if stat.S_ISLNK(current_info.st_mode) or not stat.S_ISDIR(current_info.st_mode):
            raise ProvisionError(f"refusing unexpected worker state node: {current_path}")
        if (current_info.st_uid, current_info.st_gid) != owner or current_info.st_dev != root_device or current_path.is_mount():
            raise ProvisionError(f"refusing worker state with unexpected owner or mount: {current_path}")
        for name in dirs + files:
            child = current_path / name
            info = child.lstat()
            if stat.S_ISLNK(info.st_mode) or not (stat.S_ISDIR(info.st_mode) or stat.S_ISREG(info.st_mode)):
                raise ProvisionError(f"refusing non-regular worker state node: {child}")
            if (info.st_uid, info.st_gid) != owner or info.st_dev != root_device or child.is_mount():
                raise ProvisionError(f"refusing worker state with unexpected owner or mount: {child}")


def remove(root: Path, remove_state: bool) -> None:
    root_mode = root == Path("/")
    if root_mode and os.geteuid() != 0:
        raise ProvisionError("remove requires root; use sudo")
    if root_mode:
        active = command(["/usr/bin/systemctl", "is-active", "custodian-worker@proof.service"], check=False).stdout.strip()
        enabled = command(["/usr/bin/systemctl", "is-enabled", "custodian-worker@proof.service"], check=False).stdout.strip()
        if active == "active" or enabled in ("enabled", "enabled-runtime"):
            raise ProvisionError("refusing removal while proof service is active or enabled")
        if command(["/usr/bin/systemctl", "list-units", "--state=active", "--no-legend", "custodian-worker@*.service"], check=False).stdout.strip():
            raise ProvisionError("refusing removal while any worker instance is active")
    sources = []
    repo = Path(__file__).resolve().parents[2]
    for source_rel, dest_abs, expected_mode in FILES:
        dest = mapped(root, dest_abs)
        source = repo / source_rel
        if dest.is_symlink():
            raise ProvisionError(f"refusing symlink managed file: {dest}")
        if dest.exists() and (not dest.is_file() or dest.read_bytes() != source.read_bytes()):
            raise ProvisionError(f"refusing to remove unexpected file: {dest}")
        if dest.exists() and stat.S_IMODE(dest.stat().st_mode) != expected_mode:
            raise ProvisionError(f"refusing managed file with unexpected mode: {dest}")
        if root_mode and dest.exists() and (dest.stat().st_uid != 0 or dest.stat().st_gid != 0):
            raise ProvisionError(f"refusing managed file with unexpected owner: {dest}")
        sources.append(dest)
    resolver_path = mapped(root, Path("/etc/custodian-worker/resolv.conf"))
    if resolver_path.is_symlink() or (resolver_path.exists() and resolver_path.read_text() != RESOLVERS):
        raise ProvisionError(f"refusing to remove unexpected resolver config: {resolver_path}")
    state = mapped(root, STATE)
    expected_owner = (os.getuid(), os.getgid())
    if root_mode:
        try:
            worker_user = pwd.getpwnam(WORKER)
            worker_group = grp.getgrnam(GROUP)
        except KeyError:
            worker_user = worker_group = None
        if worker_user is not None and worker_group is not None:
            expected_owner = (worker_user.pw_uid, worker_group.gr_gid)
        elif remove_state and state.exists():
            raise ProvisionError("refusing state removal without the dedicated account")
        if remove_state and worker_user is not None:
            validate_existing_identity()
            if worker_user.pw_gid != worker_group.gr_gid:
                raise ProvisionError("refusing account removal with unexpected primary group")
    if remove_state and state.exists():
        if state.is_symlink() or not state.is_dir() or state.is_mount():
            raise ProvisionError("refusing unexpected or mounted worker state root")
        if root_mode and (state.stat().st_uid != 0 or state.stat().st_gid != 0 or stat.S_IMODE(state.stat().st_mode) != 0o755):
            raise ProvisionError("refusing worker state root with unexpected owner or mode")
        allowed = {"home", "codex-home", "tmp", "workspaces"}
        extras = {p.name for p in state.iterdir()} - allowed
        if extras:
            raise ProvisionError("refusing state removal with unrecognized entries: " + ", ".join(sorted(extras)))
        for name in allowed:
            path = state / name
            if path.is_symlink() or (path.exists() and not path.is_dir()):
                raise ProvisionError(f"refusing unexpected worker state: {path}")
            if path.exists():
                verify_disposable_tree(path, expected_owner)
    for dest in reversed(sources):
        dest.unlink(missing_ok=True)
    resolver_path.unlink(missing_ok=True)
    if root_mode:
        command(["/usr/bin/systemctl", "daemon-reload"])
    if remove_state:
        if state.exists():
            for name in ("home", "codex-home", "tmp", "workspaces"):
                path = state / name
                if path.exists():
                    shutil.rmtree(path)
            state.rmdir()
        if root_mode:
            user = pwd.getpwnam(WORKER) if WORKER in {p.pw_name for p in pwd.getpwall()} else None
            if user is not None:
                groups = {g.gr_gid for g in grp.getgrall() if WORKER in g.gr_mem}
                if groups - {user.pw_gid}:
                    raise ProvisionError("refusing to delete worker with supplementary groups")
                command(["/usr/bin/userdel", WORKER])
                group = grp.getgrnam(GROUP) if GROUP in {g.gr_name for g in grp.getgrall()} else None
                if group is not None:
                    command(["/usr/bin/groupdel", GROUP])
    print("worker isolation service files removed; state is preserved unless --remove-state was supplied")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("install", "upgrade", "remove"))
    parser.add_argument("--root-dir", type=Path, help="stage safely under a temporary root for tests")
    parser.add_argument("--remove-state", action="store_true", help="remove only the dedicated worker state and account")
    parser.add_argument("--from-ref", help="required Git baseline for a managed-file upgrade")
    parser.add_argument("--installed-sha256", action="append", default=[], metavar="SOURCE=SHA256",
                        help="exact installed-file hash override, repeatable for an approved dirty baseline")
    args = parser.parse_args(argv)
    repo = Path(__file__).resolve().parents[2]
    root = args.root_dir.resolve() if args.root_dir else Path("/")
    try:
        repo = Path(__file__).resolve().parents[2]
        root = args.root_dir.resolve() if args.root_dir else Path("/")
        if args.action == "install":
            if args.remove_state or args.from_ref or args.installed_sha256:
                raise ProvisionError("upgrade/remove options are invalid with install")
            install(repo, root)
        elif args.action == "upgrade":
            if args.remove_state:
                raise ProvisionError("--remove-state is valid only with remove")
            if not args.from_ref:
                raise ProvisionError("upgrade requires --from-ref with the exact installed Git baseline")
            overrides = {}
            for value in args.installed_sha256:
                source, separator, digest = value.partition("=")
                if not separator or source in overrides:
                    raise ProvisionError("--installed-sha256 must be a unique SOURCE=SHA256 value")
                overrides[source] = digest
            upgrade(repo, root, args.from_ref, overrides)
        else:
            if args.from_ref or args.installed_sha256:
                raise ProvisionError("upgrade options are invalid with remove")
            remove(root, args.remove_state)
    except (OSError, ProvisionError, subprocess.SubprocessError) as exc:
        print(f"worker provisioning refused: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
