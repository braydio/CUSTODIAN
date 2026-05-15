#!/usr/bin/env python3
"""Prompt and clipboard helper for CUSTODIAN fabrication resource sprite generation."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
RESOURCES_ROOT = PROJECT_ROOT / "content" / "sprites" / "resources"

PRE_PROMPT = """Create a pixel-art sci-fi command terminal UI asset for a tactical survival game called CUSTODIAN. Style: dark industrial metal, worn edges, muted green/cyan CRT glow accents with occasional amber warning accents, utilitarian military interface, readable at small sizes, transparent background where appropriate, no text, no numbers, no logos. Clean game-ready PNG sprite asset, nearest-neighbor pixel art, no anti-aliased blur, no photographic texture."""


@dataclass(frozen=True)
class AssetPrompt:
	key: str
	prompt: str
	reference: str


ASSETS: dict[str, AssetPrompt] = {
	"barricade_light": AssetPrompt(
		"barricade_light",
		"Create barricade_light sprite, 96x96. Light defensive barricade, sandbag or metal panel construction, dark industrial metal, worn edges, subtle cyan-green glow accents, no text, no numbers, no logos.",
		"frames/Frame_01.png",
	),
	"turret_basic": AssetPrompt(
		"turret_basic",
		"Create turret_basic sprite, 96x96. Basic auto-turret on mount, heavy gun barrel, dark metal housing, sandbag base, muted cyan-green glow details, no text, no numbers, no logos.",
		"frames/Frame_01.png",
	),
	"power_bank_patch": AssetPrompt(
		"power_bank_patch",
		"Create power_bank_patch sprite, 96x96. Portable power bank unit, modular power cell construction, dark industrial metal, amber-cyan glow accents on power indicators, no text, no numbers, no logos.",
		"frames/Frame_01.png",
	),
}


def main() -> int:
	parser = argparse.ArgumentParser(
		description="Copy fabrication resource sprite prompts and save generated PNGs from the clipboard."
	)
	parser.add_argument("resource", nargs="?", help="Resource key, or use --list.")
	parser.add_argument("--list", action="store_true", help="List configured resource prompts.")
	parser.add_argument("--all", action="store_true", help="Include resources that already exist when listing.")
	parser.add_argument("--dry-run", action="store_true", help="Print prompt/reference without touching clipboard.")
	parser.add_argument("--overwrite", action="store_true", help="Allow saving over an existing target file.")
	parser.add_argument("--no-wait", action="store_true", help="Copy prompt but do not wait to save clipboard image.")
	parser.add_argument("--no-open-reference", action="store_true", help="Do not open the suggested reference image.")
	parser.add_argument(
		"--copy-reference-image",
		action="store_true",
		help="After you paste the prompt, copy the reference PNG to the clipboard.",
	)
	parser.add_argument("--reference", help="Override reference PNG path, relative to content/sprites or absolute.")
	args = parser.parse_args()

	if args.list:
		list_resources(include_existing=args.all)
		return 0

	if not args.resource:
		parser.error("provide a resource key or --list")

	asset = ASSETS.get(args.resource)
	if asset is None:
		print(f"Unknown resource: {args.resource}", file=sys.stderr)
		print("Use --list to see available resource keys.", file=sys.stderr)
		return 2

	target = RESOURCES_ROOT / f"{asset.key}.png"
	reference = resolve_reference(args.reference if args.reference else asset.reference)
	prompt = build_prompt(asset, reference)

	if args.dry_run:
		print(prompt)
		print()
		print(f"Target: {target}")
		print(f"Reference: {reference if reference else 'none'}")
		return 0

	copy_text(prompt)
	print(f"Copied prompt for {asset.key} to clipboard.")
	print(f"Target: {target}")
	if reference:
		print(f"Reference image: {reference}")
		if not args.no_open_reference:
			open_reference(reference)
	else:
		print("Reference image: none found")

	if args.copy_reference_image and reference:
		input("Paste the prompt into the generator, then press Enter to copy the reference image...")
		copy_png_to_clipboard(reference)
		print("Copied reference PNG to clipboard. Attach/paste it in the generator.")

	if args.no_wait:
		return 0

	input("After the generated PNG is on your clipboard, press Enter to save it...")
	save_clipboard_png(target, overwrite=args.overwrite)
	print(f"Saved clipboard PNG to {target}")
	return 0


def list_resources(include_existing: bool) -> None:
	for key in sorted(ASSETS):
		target = RESOURCES_ROOT / f"{key}.png"
		if target.exists() and not include_existing:
			continue
		status = "exists" if target.exists() else "missing"
		print(f"{status}\t{key}")


def resolve_reference(value: str) -> Path | None:
	if not value:
		return None
	path = Path(value)
	if not path.is_absolute():
		path = RESOURCES_ROOT / ".." / "ui" / "terminal" / value
	if path.exists():
		return path
	return None


def build_prompt(asset: AssetPrompt, reference: Path | None) -> str:
	lines = [PRE_PROMPT, "", asset.prompt]
	if reference:
		lines.extend(
			[
				"",
				f"Use the attached/reference image as a style reference only: {reference.name}. Do not copy its exact shape unless this prompt asks for the same UI family.",
			]
		)
	return "\n".join(lines)


def copy_text(text: str) -> None:
	if shutil.which("wl-copy"):
		run(["wl-copy"], input_bytes=text.encode("utf-8"))
		return
	if shutil.which("xclip"):
		run(["xclip", "-selection", "clipboard", "-t", "text/plain"], input_bytes=text.encode("utf-8"))
		return
	if shutil.which("xsel"):
		run(["xsel", "--clipboard", "--input"], input_bytes=text.encode("utf-8"))
		return
	if shutil.which("pbcopy"):
		run(["pbcopy"], input_bytes=text.encode("utf-8"))
		return
	raise RuntimeError("No supported clipboard text tool found: wl-copy, xclip, xsel, or pbcopy.")


def copy_png_to_clipboard(path: Path) -> None:
	data = path.read_bytes()
	if shutil.which("wl-copy"):
		run(["wl-copy", "--type", "image/png"], input_bytes=data)
		return
	if shutil.which("xclip"):
		run(["xclip", "-selection", "clipboard", "-t", "image/png"], input_bytes=data)
		return
	raise RuntimeError("No supported clipboard image copy tool found: wl-copy or xclip.")


def save_clipboard_png(target: Path, overwrite: bool) -> None:
	if target.exists() and not overwrite:
		raise RuntimeError(f"Target already exists. Re-run with --overwrite to replace it: {target}")

	target.parent.mkdir(parents=True, exist_ok=True)
	data = read_clipboard_png()
	if not data.startswith(b"\x89PNG\r\n\x1a\n"):
		raise RuntimeError("Clipboard data is not a PNG image.")
	target.write_bytes(data)


def read_clipboard_png() -> bytes:
	if shutil.which("wl-paste"):
		return run(["wl-paste", "--no-newline", "--type", "image/png"], capture=True)
	if shutil.which("xclip"):
		return run(["xclip", "-selection", "clipboard", "-t", "image/png", "-o"], capture=True)
	raise RuntimeError("No supported clipboard image read tool found: wl-paste or xclip.")


def open_reference(path: Path) -> None:
	if shutil.which("xdg-open"):
		subprocess.Popen(["xdg-open", str(path)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def run(cmd: list[str], input_bytes: bytes | None = None, capture: bool = False) -> bytes:
	result = subprocess.run(
		cmd,
		input=input_bytes,
		stdout=subprocess.PIPE if capture else None,
		stderr=subprocess.PIPE,
		check=False,
	)
	if result.returncode != 0:
		message = result.stderr.decode("utf-8", errors="replace").strip()
		raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{message}")
	return result.stdout if capture else b""


if __name__ == "__main__":
	try:
		raise SystemExit(main())
	except KeyboardInterrupt:
		raise SystemExit(130)
	except Exception as exc:
		print(f"error: {exc}", file=sys.stderr)
		raise SystemExit(1)