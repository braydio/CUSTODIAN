#!/usr/bin/env python3
"""Sanitize and validate public worker-proof JSON evidence."""
from __future__ import annotations

import argparse
import ipaddress
import json
import re
from pathlib import Path
from typing import Any

LAN_NAME = re.compile(r"^lan_ipv4_(\d+)$")


class EvidenceError(ValueError):
    pass


def sanitize_public_evidence(payload: dict[str, Any]) -> dict[str, Any]:
    """Replace private LAN destination IPs with stable names; preserve all other evidence."""
    result = json.loads(json.dumps(payload))
    probes = result.get("probes")
    if not isinstance(probes, list):
        raise EvidenceError("worker evidence must contain a probes list")
    for probe in probes:
        if not isinstance(probe, dict):
            raise EvidenceError("worker probe entry must be an object")
        name = probe.get("name")
        match = LAN_NAME.fullmatch(name) if isinstance(name, str) else None
        destination = probe.get("destination")
        if not match or not isinstance(destination, str):
            continue
        host, separator, port = destination.rpartition(":")
        if not separator or not port.isdigit():
            raise EvidenceError(f"invalid LAN destination for {name}")
        try:
            address = ipaddress.ip_address(host)
        except ValueError as exc:
            raise EvidenceError(f"invalid LAN destination for {name}") from exc
        if address.version != 4 or not address.is_private:
            raise EvidenceError(f"expected private IPv4 destination for {name}")
        probe["destination"] = f"<PRIVATE_LAN_IPV4_{match.group(1)}>:{port}"
    validate_public_evidence(result)
    return result


def validate_public_evidence(payload: dict[str, Any]) -> None:
    """Reject actual private IPv4 destination addresses in public worker evidence."""
    probes = payload.get("probes")
    if not isinstance(probes, list):
        raise EvidenceError("worker evidence must contain a probes list")
    for probe in probes:
        if not isinstance(probe, dict):
            raise EvidenceError("worker probe entry must be an object")
        name = probe.get("name")
        if not isinstance(name, str) or not LAN_NAME.fullmatch(name):
            continue
        destination = probe.get("destination")
        if not isinstance(destination, str):
            raise EvidenceError(f"LAN destination missing for {name}")
        host, separator, port = destination.rpartition(":")
        if not separator or not port.isdigit():
            raise EvidenceError(f"invalid public LAN destination for {name}")
        if host != f"<PRIVATE_LAN_IPV4_{LAN_NAME.fullmatch(name).group(1)}>":
            raise EvidenceError(f"public worker evidence contains a non-symbolic LAN destination for {name}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="source worker-proof JSON")
    parser.add_argument("output", type=Path, help="new sanitized public JSON path")
    args = parser.parse_args(argv)
    try:
        payload = json.loads(args.input.read_text(encoding="utf-8"))
        if not isinstance(payload, dict):
            raise EvidenceError("worker evidence root must be an object")
        sanitized = sanitize_public_evidence(payload)
        if args.output.exists():
            raise EvidenceError(f"refusing to overwrite existing output: {args.output}")
        args.output.write_text(json.dumps(sanitized, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    except (OSError, json.JSONDecodeError, EvidenceError) as exc:
        parser.error(str(exc))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
