#!/usr/bin/env python3
"""Prompt and clipboard helper for CUSTODIAN terminal UI asset generation."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
TERMINAL_ROOT = PROJECT_ROOT / "content" / "ui" / "terminal"

PRE_PROMPT = """Create a pixel-art sci-fi command terminal UI asset for a tactical survival game called CUSTODIAN. Style: dark industrial metal, worn edges, muted green/cyan CRT glow accents with occasional amber warning accents, utilitarian military interface, readable at small sizes, transparent background where appropriate, no text, no numbers, no logos. Clean game-ready PNG sprite asset, nearest-neighbor pixel art, no anti-aliased blur, no photographic texture."""


@dataclass(frozen=True)
class AssetPrompt:
	path: str
	prompt: str
	reference: str


ASSETS: dict[str, AssetPrompt] = {
	"panels/panel_frame_medium_9slice.png": AssetPrompt(
		"panels/panel_frame_medium_9slice.png",
		"Create panels/panel_frame_medium_9slice.png, 64x64. Reusable medium panel frame for NinePatchRect. Transparent center, 16px stretch-safe margins, dark metal border, subtle terminal glow, no text.",
		"frames/Frame_01.png",
	),
	"panels/panel_header_bar.png": AssetPrompt(
		"panels/panel_header_bar.png",
		"Create panels/panel_header_bar.png, 256x32. Blank neutral terminal header bar, tileable/stretchable horizontally, dark charcoal metal with subtle cyan-green edge glow, no text or symbols.",
		"overlays/Header_Bar_Active.png",
	),
	"panels/terminal_bg_tile_dark.png": AssetPrompt(
		"panels/terminal_bg_tile_dark.png",
		"Create panels/terminal_bg_tile_dark.png, 64x64. Seamless tileable dark terminal background texture, very subtle grid/noise pattern, low contrast, dark graphite with faint green CRT undertone. Must loop perfectly.",
		"frames/Frame_01.png",
	),
	"command_line/command_line_frame_9slice.png": AssetPrompt(
		"command_line/command_line_frame_9slice.png",
		"Create command_line/command_line_frame_9slice.png, 64x32. Terminal command input field frame for 9-slice use. Transparent center, 12px stretch-safe margins, dark inset look, thin cyan-green glow along lower edge, no text.",
		"frames/Frame_01.png",
	),
	"command_line/command_line_prompt_icon.png": AssetPrompt(
		"command_line/command_line_prompt_icon.png",
		"Create command_line/command_line_prompt_icon.png, 24x24. Small terminal prompt icon, transparent background, angular command-chevron or cursor glyph, monochrome green/cyan pixel art, no letters.",
		"Bracket_01.png",
	),
	"command_line/command_line_caret.png": AssetPrompt(
		"command_line/command_line_caret.png",
		"Create command_line/command_line_caret.png, 6x24. Blinking terminal caret sprite, transparent background, vertical glowing pixel bar, cyan-green, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"nav/nav_tab_idle_9slice.png": AssetPrompt(
		"nav/nav_tab_idle_9slice.png",
		"Create nav/nav_tab_idle_9slice.png, 96x32. Idle page tab button. Dark filled center suitable for text overlay, 12px stretch-safe margins, dark metal frame, subtle inactive green glow, no text.",
		"frames/Frame_01.png",
	),
	"nav/nav_tab_active_9slice.png": AssetPrompt(
		"nav/nav_tab_active_9slice.png",
		"Create nav/nav_tab_active_9slice.png, 96x32. Active page tab button. Same shape as idle tab, brighter cyan-green edge glow, slightly raised selected look, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"nav/nav_tab_hover_9slice.png": AssetPrompt(
		"nav/nav_tab_hover_9slice.png",
		"Create nav/nav_tab_hover_9slice.png, 96x32. Hover page tab state. Same dimensions and shape as idle/active, mild glow increase, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"nav/nav_tab_alert_9slice.png": AssetPrompt(
		"nav/nav_tab_alert_9slice.png",
		"Create nav/nav_tab_alert_9slice.png, 96x32. Alert page tab. Same shape as nav tabs, amber warning glow, restrained, no text.",
		"overlays/Header_Bar_Warning.png",
	),
	"nav/nav_tab_disabled_9slice.png": AssetPrompt(
		"nav/nav_tab_disabled_9slice.png",
		"Create nav/nav_tab_disabled_9slice.png, 96x32. Disabled page tab. Same shape as nav tabs, dim desaturated metal, low contrast, no text.",
		"frames/Frame_01.png",
	),
	"buttons/button_idle_9slice.png": AssetPrompt(
		"buttons/button_idle_9slice.png",
		"Create buttons/button_idle_9slice.png, 128x36. Terminal action button idle state, 12px stretch-safe margins, dark inset metal, subtle green edge light, center clean for Godot-rendered text, no text.",
		"frames/Frame_01.png",
	),
	"buttons/button_hover_9slice.png": AssetPrompt(
		"buttons/button_hover_9slice.png",
		"Create buttons/button_hover_9slice.png, 128x36. Terminal action button hover state, same shape as idle, slightly brighter cyan-green glow, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"buttons/button_pressed_9slice.png": AssetPrompt(
		"buttons/button_pressed_9slice.png",
		"Create buttons/button_pressed_9slice.png, 128x36. Terminal action button pressed state, same shape, visibly inset/depressed, reduced glow, no text.",
		"frames/Frame_01.png",
	),
	"buttons/button_disabled_9slice.png": AssetPrompt(
		"buttons/button_disabled_9slice.png",
		"Create buttons/button_disabled_9slice.png, 128x36. Terminal action button disabled state, same shape, dim gray metal, no glow, no text.",
		"frames/Frame_01.png",
	),
	"buttons/button_warning_9slice.png": AssetPrompt(
		"buttons/button_warning_9slice.png",
		"Create buttons/button_warning_9slice.png, 128x36. Terminal warning action button, same shape, amber edge glow, dark center for text overlay, no text.",
		"overlays/Header_Bar_Warning.png",
	),
	"buttons/button_critical_9slice.png": AssetPrompt(
		"buttons/button_critical_9slice.png",
		"Create buttons/button_critical_9slice.png, 128x36. Terminal critical action button, same shape, restrained red edge glow, dark center for text overlay, no text.",
		"overlays/Header_Bar_Critical.png",
	),
	"map/map_frame_large_9slice.png": AssetPrompt(
		"map/map_frame_large_9slice.png",
		"Create map/map_frame_large_9slice.png, 128x128. Tactical map viewport frame for NinePatchRect. Transparent center, 24px stretch-safe margins, reinforced corners, subtle grid/circuit details in the frame, no text.",
		"frames/Frame_01.png",
	),
	"map/map_grid_tile.png": AssetPrompt(
		"map/map_grid_tile.png",
		"Create map/map_grid_tile.png, 64x64. Seamless tileable tactical map grid overlay. Transparent background, very thin dim cyan-green grid lines, subtle coordinate-style tick marks but no numbers or letters.",
		"overlays/Header_Bar_Active.png",
	),
	"map/map_corner_marker.png": AssetPrompt(
		"map/map_corner_marker.png",
		"Create map/map_corner_marker.png, 16x16. Small map corner bracket marker, transparent background, cyan-green pixel line art.",
		"Bracket_01.png",
	),
	"map/map_crosshair_center.png": AssetPrompt(
		"map/map_crosshair_center.png",
		"Create map/map_crosshair_center.png, 32x32. Tactical map center crosshair, transparent background, thin cyan-green pixel lines, no text.",
		"Bracket_01.png",
	),
	"map/map_targeting_reticle.png": AssetPrompt(
		"map/map_targeting_reticle.png",
		"Create map/map_targeting_reticle.png, 32x32. Tactical targeting reticle marker, transparent background, angular sci-fi bracket shape, amber/cyan accents, no text.",
		"Bracket_01.png",
	),
	"meters/status_pip_green.png": AssetPrompt(
		"meters/status_pip_green.png",
		"Create meters/status_pip_green.png, 12x12. Tiny LED status pip, transparent background, circular or diamond pixel shape, green glow, readable at small size.",
		"overlays/Header_Bar_Active.png",
	),
	"meters/status_pip_yellow.png": AssetPrompt(
		"meters/status_pip_yellow.png",
		"Create meters/status_pip_yellow.png, 12x12. Same exact shape as status_pip_green, yellow/amber glow.",
		"overlays/Header_Bar_Warning.png",
	),
	"meters/status_pip_red.png": AssetPrompt(
		"meters/status_pip_red.png",
		"Create meters/status_pip_red.png, 12x12. Same exact shape as status_pip_green, red critical glow.",
		"overlays/Header_Bar_Critical.png",
	),
	"meters/status_pip_blue.png": AssetPrompt(
		"meters/status_pip_blue.png",
		"Create meters/status_pip_blue.png, 12x12. Same exact shape as status_pip_green, blue/cyan special-state glow.",
		"overlays/Header_Bar_Active.png",
	),
	"meters/status_pip_off.png": AssetPrompt(
		"meters/status_pip_off.png",
		"Create meters/status_pip_off.png, 12x12. Same exact shape as status_pip_green, dark inactive unlit metal/glass.",
		"frames/Frame_01.png",
	),
	"meters/meter_frame_horizontal_9slice.png": AssetPrompt(
		"meters/meter_frame_horizontal_9slice.png",
		"Create meters/meter_frame_horizontal_9slice.png, 128x16. Horizontal progress meter frame, transparent center, 8px stretch-safe margins, dark terminal metal, no text.",
		"frames/Frame_01.png",
	),
	"meters/meter_fill_green.png": AssetPrompt(
		"meters/meter_fill_green.png",
		"Create meters/meter_fill_green.png, 16x8. Tileable horizontal meter fill segment, green glowing energy bar, seamless left/right.",
		"overlays/Header_Bar_Active.png",
	),
	"meters/meter_fill_yellow.png": AssetPrompt(
		"meters/meter_fill_yellow.png",
		"Create meters/meter_fill_yellow.png, 16x8. Tileable horizontal meter fill segment, amber glowing energy bar, seamless left/right.",
		"overlays/Header_Bar_Warning.png",
	),
	"meters/meter_fill_red.png": AssetPrompt(
		"meters/meter_fill_red.png",
		"Create meters/meter_fill_red.png, 16x8. Tileable horizontal meter fill segment, red critical energy bar, seamless left/right.",
		"overlays/Header_Bar_Critical.png",
	),
	"icons/icon_power.png": AssetPrompt(
		"icons/icon_power.png",
		"Create icons/icon_power.png, 32x32. Pixel-art terminal power icon, transparent background, simple electrical bolt/core symbol, cyan-green glow, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"icons/icon_defense.png": AssetPrompt(
		"icons/icon_defense.png",
		"Create icons/icon_defense.png, 32x32. Pixel-art defense icon, transparent background, shield/barricade silhouette, cyan-green glow, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"icons/icon_repair.png": AssetPrompt(
		"icons/icon_repair.png",
		"Create icons/icon_repair.png, 32x32. Pixel-art repair icon, transparent background, wrench/maintenance silhouette, cyan-green glow, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"icons/icon_recon.png": AssetPrompt(
		"icons/icon_recon.png",
		"Create icons/icon_recon.png, 32x32. Pixel-art recon icon, transparent background, scanner/radar eye silhouette, cyan-green glow, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"icons/icon_contract.png": AssetPrompt(
		"icons/icon_contract.png",
		"Create icons/icon_contract.png, 32x32. Pixel-art contract icon, transparent background, document/mission chip silhouette, cyan-green glow, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"icons/icon_map.png": AssetPrompt(
		"icons/icon_map.png",
		"Create icons/icon_map.png, 32x32. Pixel-art tactical map icon, transparent background, folded grid map silhouette, cyan-green glow, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"icons/icon_turret.png": AssetPrompt(
		"icons/icon_turret.png",
		"Create icons/icon_turret.png, 32x32. Pixel-art turret icon, transparent background, small mounted gun silhouette, cyan-green glow, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"icons/icon_wall.png": AssetPrompt(
		"icons/icon_wall.png",
		"Create icons/icon_wall.png, 32x32. Pixel-art wall/building icon, transparent background, modular barricade blocks silhouette, cyan-green glow, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"icons/icon_drone.png": AssetPrompt(
		"icons/icon_drone.png",
		"Create icons/icon_drone.png, 32x32. Pixel-art drone icon, transparent background, small quad/drone silhouette, cyan-green glow, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"icons/icon_warning.png": AssetPrompt(
		"icons/icon_warning.png",
		"Create icons/icon_warning.png, 32x32. Pixel-art warning icon, transparent background, triangular alert glyph, amber glow, no text.",
		"overlays/Header_Bar_Warning.png",
	),
	"icons/icon_critical.png": AssetPrompt(
		"icons/icon_critical.png",
		"Create icons/icon_critical.png, 32x32. Pixel-art critical alert icon, transparent background, angular danger glyph, red glow, no text.",
		"overlays/Header_Bar_Critical.png",
	),
	"icons/icon_fabrication.png": AssetPrompt(
		"icons/icon_fabrication.png",
		"Create icons/icon_fabrication.png, 32x32. Pixel-art fabrication icon, transparent background, machine press/gear/anvil hybrid silhouette, amber-cyan glow, no text.",
		"overlays/Header_Bar_Warning.png",
	),
	"icons/icon_scan.png": AssetPrompt(
		"icons/icon_scan.png",
		"Create icons/icon_scan.png, 32x32. Pixel-art scan icon, transparent background, sweeping radar cone or pulse rings, cyan-green glow, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"markers/marker_operator.png": AssetPrompt(
		"markers/marker_operator.png",
		"Create markers/marker_operator.png, 16x16. Tactical minimap marker for player/operator, transparent background, distinct triangular humanoid/arrow silhouette, cyan-white.",
		"Bracket_01.png",
	),
	"markers/marker_enemy.png": AssetPrompt(
		"markers/marker_enemy.png",
		"Create markers/marker_enemy.png, 16x16. Tactical minimap marker for enemy, transparent background, distinct hostile angular silhouette, red, shape must differ from operator.",
		"Bracket_01.png",
	),
	"markers/marker_turret_friendly.png": AssetPrompt(
		"markers/marker_turret_friendly.png",
		"Create markers/marker_turret_friendly.png, 16x16. Tactical minimap marker for friendly turret, transparent background, small tripod/turret silhouette, green/cyan.",
		"Bracket_01.png",
	),
	"markers/marker_sector.png": AssetPrompt(
		"markers/marker_sector.png",
		"Create markers/marker_sector.png, 16x16. Tactical minimap marker for sector, transparent background, small square grid-node silhouette, blue/cyan.",
		"Bracket_01.png",
	),
	"markers/marker_objective.png": AssetPrompt(
		"markers/marker_objective.png",
		"Create markers/marker_objective.png, 16x16. Tactical minimap marker for objective, transparent background, diamond or bracketed target silhouette, amber.",
		"Bracket_01.png",
	),
	"markers/marker_fabricator.png": AssetPrompt(
		"markers/marker_fabricator.png",
		"Create markers/marker_fabricator.png, 16x16. Tactical minimap marker for fabricator, transparent background, small machine/gear silhouette, amber-cyan.",
		"Bracket_01.png",
	),
	"markers/marker_selected_overlay.png": AssetPrompt(
		"markers/marker_selected_overlay.png",
		"Create markers/marker_selected_overlay.png, 24x24. Transparent selection overlay marker, bracket-like shape with transparent center, cyan glow, no fill, no text.",
		"Bracket_01.png",
	),
	"overlays/terminal_scanline_overlay.png": AssetPrompt(
		"overlays/terminal_scanline_overlay.png",
		"Create overlays/terminal_scanline_overlay.png, 32x32. Seamless transparent scanline overlay tile, very subtle horizontal CRT scanlines, low alpha built into pixels, no text.",
		"overlays/Header_Bar_Active.png",
	),
	"overlays/terminal_noise_overlay.png": AssetPrompt(
		"overlays/terminal_noise_overlay.png",
		"Create overlays/terminal_noise_overlay.png, 64x64. Seamless transparent terminal noise overlay tile, sparse subtle pixel speckle/noise, very low contrast, no text.",
		"frames/Frame_01.png",
	),
	"overlays/overlay_warning_flash.png": AssetPrompt(
		"overlays/overlay_warning_flash.png",
		"Create overlays/overlay_warning_flash.png, 64x64. Transparent warning flash overlay tile, amber edge/pulse fragments, subtle enough for UI overlay, no text.",
		"overlays/Header_Bar_Warning.png",
	),
	"overlays/overlay_critical_flash.png": AssetPrompt(
		"overlays/overlay_critical_flash.png",
		"Create overlays/overlay_critical_flash.png, 64x64. Transparent critical flash overlay tile, restrained red glitch/pulse fragments, no text.",
		"overlays/Header_Bar_Critical.png",
	),
}


def main() -> int:
	parser = argparse.ArgumentParser(
		description="Copy terminal UI asset prompts and save generated PNGs from the clipboard."
	)
	parser.add_argument("asset", nargs="?", help="Asset path/key, or use --list.")
	parser.add_argument("--list", action="store_true", help="List missing configured asset prompts.")
	parser.add_argument("--all", action="store_true", help="Include assets that already exist when listing.")
	parser.add_argument("--dry-run", action="store_true", help="Print prompt/reference without touching clipboard or waiting.")
	parser.add_argument("--overwrite", action="store_true", help="Allow saving over an existing target file.")
	parser.add_argument("--no-wait", action="store_true", help="Copy prompt but do not wait to save clipboard image.")
	parser.add_argument("--no-open-reference", action="store_true", help="Do not open the suggested reference image.")
	parser.add_argument(
		"--copy-reference-image",
		action="store_true",
		help="After you paste the prompt, copy the reference PNG to the clipboard for manual attachment.",
	)
	parser.add_argument("--reference", help="Override reference PNG path, relative to content/ui/terminal or absolute.")
	args = parser.parse_args()

	if args.list:
		list_assets(include_existing=args.all)
		return 0

	if not args.asset:
		parser.error("provide an asset path/key or --list")

	asset = resolve_asset(args.asset)
	if asset is None:
		print(f"Unknown asset: {args.asset}", file=sys.stderr)
		print("Use --list to see available asset paths.", file=sys.stderr)
		return 2

	target = TERMINAL_ROOT / asset.path
	reference = resolve_reference(args.reference if args.reference else asset.reference)
	prompt = build_prompt(asset, reference)

	if args.dry_run:
		print(prompt)
		print()
		print(f"Target: {target}")
		print(f"Reference: {reference if reference else 'none'}")
		return 0

	copy_text(prompt)
	print(f"Copied prompt for {asset.path} to clipboard.")
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


def list_assets(include_existing: bool) -> None:
	for path in sorted(ASSETS):
		target = TERMINAL_ROOT / path
		if target.exists() and not include_existing:
			continue
		status = "exists" if target.exists() else "missing"
		print(f"{status}\t{path}")


def resolve_asset(value: str) -> AssetPrompt | None:
	normalized = value.replace("\\", "/")
	if normalized in ASSETS:
		return ASSETS[normalized]
	matches = [asset for path, asset in ASSETS.items() if path.endswith(normalized)]
	if len(matches) == 1:
		return matches[0]
	return None


def resolve_reference(value: str) -> Path | None:
	path = Path(value)
	if not path.is_absolute():
		path = TERMINAL_ROOT / value
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
