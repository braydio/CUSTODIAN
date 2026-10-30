#!/usr/bin/env python3
import argparse
from pathlib import Path
from meshy_container import to_glb

parser = argparse.ArgumentParser(description="Decode authorized Meshy v1 files to GLB")
parser.add_argument("input", type=Path)
parser.add_argument("output", type=Path)
parser.add_argument("--confirm-authorized", action="store_true")
args = parser.parse_args()

if not args.confirm_authorized:
    parser.error("--confirm-authorized is required")

if not args.input.is_file() or args.input.suffix.lower() != ".meshy":
    parser.error("input must be an existing .meshy file")

if args.output.suffix.lower() != ".glb":
    parser.error("output must have a .glb extension")

with args.output.open("xb") as output:
    output.write(to_glb(args.input.read_bytes()))

print(f"Decoded: {args.output}")
