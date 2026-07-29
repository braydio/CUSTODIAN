#!/usr/bin/env python3
"""Build self-contained Moment Forge evidence and comparison reports."""

from __future__ import annotations

import hashlib
import html
import json
import math
import shutil
import subprocess
import sys
import wave
from array import array
from datetime import datetime
from pathlib import Path
from typing import Any

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageOps


class BaselineCompatibilityError(ValueError):
    """Baseline cannot be compared as automated evidence."""


def _read_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, payload: Any) -> None:
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _canonical_json(payload: Any) -> bytes:
    return json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode()


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _sha256_payload(payload: Any) -> str:
    return hashlib.sha256(_canonical_json(payload)).hexdigest()


def _git_metadata(repo_root: Path) -> dict[str, Any]:
    def run(*args: str) -> str:
        completed = subprocess.run(
            ["git", *args],
            cwd=repo_root,
            check=False,
            capture_output=True,
            text=True,
        )
        return completed.stdout.strip() if completed.returncode == 0 else ""

    return {
        "root": str(repo_root.resolve()),
        "commit": run("rev-parse", "HEAD"),
        "branch": run("branch", "--show-current"),
        "dirty": bool(run("status", "--porcelain")),
        "changed_files": run("status", "--short").splitlines(),
    }


def _frame_path(run_dir: Path, tick: int) -> Path:
    candidates = (
        run_dir / "keyframes" / f"tick_{tick:06d}.png",
        run_dir / "frames" / f"frame_{tick:06d}.png",
    )
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    raise FileNotFoundError(f"missing authored keyframe for tick {tick}")


def build_contact_sheet(
    run_dir: Path,
    ticks: list[int],
    width: int,
    height: int,
    timeline: list[dict[str, Any]] | None = None,
    output_name: str = "current_contact_sheet.png",
) -> Path:
    timeline = timeline or []
    markers: dict[int, list[str]] = {}
    for item in timeline:
        tick = item.get("scenario_tick", item.get("tick"))
        if isinstance(tick, int):
            label = str(item.get("name") or item.get("kind") or item.get("action") or "")
            if label:
                markers.setdefault(tick, []).append(label)
    sheet = Image.new("RGBA", (width * 3, height * 2), (8, 12, 18, 255))
    for index, tick in enumerate(ticks):
        with Image.open(_frame_path(run_dir, tick)) as source:
            frame = ImageOps.fit(source.convert("RGBA"), (width, height))
        draw = ImageDraw.Draw(frame, "RGBA")
        label = f"tick {tick:06d}  {tick * 1000.0 / 60.0:7.1f} ms"
        if markers.get(tick):
            label += "  " + " / ".join(markers[tick][:2])
        draw.rectangle((0, 0, width, 30), fill=(5, 9, 15, 208))
        draw.text((10, 8), label, fill=(224, 238, 248, 255))
        sheet.paste(frame, ((index % 3) * width, (index // 3) * height))
    output = run_dir / output_name
    sheet.save(output)
    return output


def _visual_metrics(current: Image.Image, baseline: Image.Image) -> dict[str, Any]:
    difference = ImageChops.difference(current.convert("RGBA"), baseline.convert("RGBA"))
    bbox = difference.getbbox()
    rgb = difference.convert("RGB")
    histogram = rgb.histogram()
    energy = sum((index % 256) * count for index, count in enumerate(histogram))
    samples = max(1, current.width * current.height * 3)
    changed_pixels = sum(
        1
        for pixel in rgb.getdata()
        if max(pixel) > 8
    )
    luminance_current = ImageOps.grayscale(current.convert("RGB"))
    luminance_baseline = ImageOps.grayscale(baseline.convert("RGB"))
    mean_current = sum(luminance_current.histogram()[value] * value for value in range(256)) / max(
        1, current.width * current.height
    )
    mean_baseline = sum(
        luminance_baseline.histogram()[value] * value for value in range(256)
    ) / max(1, baseline.width * baseline.height)
    return {
        "different": bbox is not None,
        "changed_pixel_ratio": changed_pixels / max(1, current.width * current.height),
        "changed_pixel_bbox": list(bbox) if bbox else None,
        "mean_absolute_channel_delta": energy / samples,
        "luminance_mean_current": mean_current,
        "luminance_mean_baseline": mean_baseline,
        "luminance_delta": mean_current - mean_baseline,
    }


def build_visual_diff(current: Path, baseline: Path, output: Path) -> dict[str, Any]:
    with Image.open(current) as current_image, Image.open(baseline) as baseline_image:
        current_rgba = current_image.convert("RGBA")
        baseline_rgba = baseline_image.convert("RGBA")
        if current_rgba.size != baseline_rgba.size:
            raise BaselineCompatibilityError("baseline/current image dimensions differ")
        difference = ImageChops.difference(current_rgba, baseline_rgba)
        ImageEnhance.Contrast(difference).enhance(4.0).save(output)
        return _visual_metrics(current_rgba, baseline_rgba)


def _pcm_audio_metrics(path: Path, onset_override: float | None = None) -> dict[str, Any]:
    if not path.is_file() or path.stat().st_size <= 44:
        return {"available": False}
    try:
        with wave.open(str(path), "rb") as audio:
            width = audio.getsampwidth()
            frames = audio.getnframes()
            channels = audio.getnchannels()
            rate = audio.getframerate()
            raw = audio.readframes(frames)
    except (wave.Error, EOFError):
        return {"available": False}
    result: dict[str, Any] = {
        "available": True,
        "sample_rate": rate,
        "channels": channels,
        "frames": frames,
        "duration_sec": frames / max(1, rate),
        "sample_width": width,
    }
    if width != 2 or not raw:
        result["analysis"] = "unsupported_sample_width"
        return result
    samples = array("h")
    samples.frombytes(raw)
    peak = max((abs(value) for value in samples), default=0)
    rms = math.sqrt(sum(value * value for value in samples) / max(1, len(samples)))

    def dbfs(value: float) -> float | None:
        return None if value <= 0.0 else 20.0 * math.log10(value / 32767.0)

    noise_window = samples[: max(channels, min(len(samples), int(rate * channels * 0.15)))]
    noise_rms = math.sqrt(sum(value * value for value in noise_window) / max(1, len(noise_window)))
    noise_db = dbfs(noise_rms)
    threshold_db = onset_override if onset_override is not None else max(
        (noise_db if noise_db is not None else -96.0) + 12.0,
        -42.0,
    )
    threshold = 32767.0 * (10.0 ** (threshold_db / 20.0))
    onset_sample = next((index for index, value in enumerate(samples) if abs(value) >= threshold), None)
    peak_sample = max(range(len(samples)), key=lambda index: abs(samples[index])) if samples else 0
    result.update(
        {
            "peak_dbfs": dbfs(float(peak)),
            "rms_dbfs": dbfs(rms),
            "noise_floor_dbfs": noise_db,
            "onset_threshold_dbfs": threshold_db,
            "onset_ms": onset_sample * 1000.0 / max(1, rate * channels)
            if onset_sample is not None
            else None,
            "peak_time_ms": peak_sample * 1000.0 / max(1, rate * channels),
        }
    )
    return result


def _canonical_audio(run_dir: Path, require: bool) -> tuple[Path | None, dict[str, Any]]:
    candidates = (
        run_dir / "raw" / "capture.wav",
        run_dir / "audio_mix.wav",
    )
    source = next((candidate for candidate in candidates if candidate.is_file()), None)
    if source is None:
        return None, {"requested": require, "available": False, "conversion": "source_missing"}
    output = run_dir / "audio_mix.wav"
    with wave.open(str(source), "rb") as audio:
        already_canonical = (
            audio.getframerate() == 48000
            and audio.getnchannels() == 2
            and audio.getsampwidth() == 2
        )
    if already_canonical:
        if source != output:
            shutil.copy2(source, output)
        return output, {"requested": require, "available": True, "conversion": "not_required"}
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
        return source, {
            "requested": require,
            "available": True,
            "canonical_available": False,
            "conversion": "ffmpeg_unavailable",
        }
    completed = subprocess.run(
        [
            ffmpeg, "-y", "-loglevel", "error", "-i", str(source),
            "-ar", "48000", "-ac", "2", "-c:a", "pcm_s16le", str(output),
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    return (
        (output if completed.returncode == 0 and output.is_file() else source),
        {
            "requested": require,
            "available": True,
            "canonical_available": completed.returncode == 0,
            "conversion": "ffmpeg" if completed.returncode == 0 else "failed",
        },
    )


def _build_video(run_dir: Path, fps: int, audio: Path | None) -> Path | None:
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
        return None
    raw_frames = sorted((run_dir / "raw").glob("capture*.png"))
    legacy_frames = sorted((run_dir / "frames").glob("frame_*.png"))
    if raw_frames:
        pattern = run_dir / "raw" / "capture%08d.png"
    elif legacy_frames:
        pattern = run_dir / "frames" / "frame_%06d.png"
    else:
        return None
    output = run_dir / "current.mp4"
    command = [
        ffmpeg,
        "-y",
        "-loglevel",
        "error",
        "-framerate",
        str(fps),
        "-i",
        str(pattern),
    ]
    if audio is not None and audio.is_file():
        command.extend(["-i", str(audio)])
    command.extend(["-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18"])
    if audio is not None and audio.is_file():
        command.extend(["-c:a", "aac", "-b:a", "192k", "-shortest"])
    command.extend(["-movflags", "+faststart", str(output)])
    completed = subprocess.run(command, check=False, capture_output=True, text=True)
    return output if completed.returncode == 0 and output.is_file() else None


def _stable_fingerprint(
    scenario: dict[str, Any],
    metrics: dict[str, Any],
    timeline: list[dict[str, Any]],
    probes: list[dict[str, Any]],
    assertions: list[dict[str, Any]],
) -> dict[str, str]:
    contract = scenario.get("stable_fingerprint", {})
    float_quantum = float(contract.get("float_quantum", 0.0001))
    position_quantum = float(contract.get("position_quantum_px", 0.25))

    def quantize(value: Any, key: str = "") -> Any:
        quantum = position_quantum if "position" in key else float_quantum
        if isinstance(value, float):
            return round(value / quantum) * quantum if quantum > 0 else value
        if isinstance(value, list):
            return [quantize(item, key) for item in value]
        if isinstance(value, dict):
            return {name: quantize(item, name) for name, item in sorted(value.items())}
        return value

    stable_assertions = [
        {
            "type": item.get("type"),
            "severity": item.get("severity", "error"),
            "passed": item.get("passed"),
            "actual": item.get("actual"),
        }
        for item in assertions
        if item.get("severity", "error") == "error"
    ]
    event_fields = contract.get("event_payload_fields", {})
    stable_timeline = []
    for item in timeline:
        kind = str(item.get("kind", ""))
        record = {
            key: item.get(key)
            for key in ("tick", "scenario_tick", "action", "kind", "name", "ok")
            if key in item
        }
        allowed_fields = event_fields.get(kind, [])
        data = item.get("data", {})
        if allowed_fields and isinstance(data, dict):
            record["data"] = {
                field: data.get(field) for field in allowed_fields if field in data
            }
        stable_timeline.append(record)
    probe_records = probes.get("records", []) if isinstance(probes, dict) else probes
    selected_probe_ids = set(str(value) for value in contract.get("probes", []))
    stable_probes = [
        record for record in probe_records
        if str(record.get("id", "")) in selected_probe_ids
    ]
    payload = {
        "scenario_id": scenario["id"],
        "scenario_schema_version": scenario["schema_version"],
        "completed_tick": metrics.get("stable", {}).get("completed_tick"),
        "metrics": metrics.get("stable", {}),
        "timeline": stable_timeline,
        "probes": stable_probes,
        "assertions": stable_assertions,
    }
    payload = quantize(payload)
    return {
        "schema": "custodian.moment_forge.stable_fingerprint.v1",
        "algorithm": "sha256",
        "value": _sha256_payload(payload),
    }


def _compatibility_key(scenario: dict[str, Any]) -> dict[str, Any]:
    capture = scenario["capture"]
    return {
        "scenario_id": scenario["id"],
        "scenario_schema_version": scenario["schema_version"],
        "scenario_sha256": _sha256_payload(scenario),
        "width": capture["width"],
        "height": capture["height"],
        "fps": capture["fps"],
        "start_tick": capture["start_tick"],
        "end_tick": capture["end_tick"],
        "contact_sheet_ticks": capture["contact_sheet_ticks"],
        "metrics_schema_major": 1,
    }


def _baseline_compatibility(
    scenario: dict[str, Any],
    baseline_manifest: dict[str, Any],
) -> tuple[bool, list[str]]:
    expected = _compatibility_key(scenario)
    observed = baseline_manifest.get("baseline_compatibility", {})
    mismatches = [
        key
        for key, value in expected.items()
        if observed.get(key) != value
    ]
    return not mismatches, mismatches


def _metric_rows(current: dict[str, Any], baseline: dict[str, Any] | None) -> list[dict[str, Any]]:
    stable = current.get("stable", {})
    baseline_stable = baseline.get("stable", {}) if baseline else {}
    rows = []
    for key in sorted(set(stable) | set(baseline_stable)):
        value = stable.get(key)
        before = baseline_stable.get(key) if baseline else None
        if isinstance(value, (int, float)) and isinstance(before, (int, float)):
            delta: Any = value - before
        elif baseline is not None:
            delta = "unchanged" if value == before else "changed"
        else:
            delta = None
        rows.append({"name": key, "baseline": before, "current": value, "delta": delta})
    return rows


def _artifact_html(run_dir: Path, name: str, tag: str = "img") -> str:
    path = run_dir / name
    if not path.is_file():
        return "<p class='muted'>Unavailable.</p>"
    if tag == "video":
        return f"<video controls loop src='{html.escape(name)}'></video>"
    return f"<img src='{html.escape(name)}' alt='{html.escape(name)}'>"


def _write_html(
    run_dir: Path,
    scenario: dict[str, Any],
    manifest: dict[str, Any],
    timeline: list[dict[str, Any]],
    metric_rows: list[dict[str, Any]],
    assertions: list[dict[str, Any]],
) -> None:
    timeline_rows = "\n".join(
        "<tr><td>{}</td><td>{}</td><td><code>{}</code></td></tr>".format(
            html.escape(str(item.get("scenario_tick", item.get("tick", "—")))),
            html.escape(str(item.get("kind", item.get("action", "")))),
            html.escape(json.dumps(item, sort_keys=True)),
        )
        for item in timeline
    )
    metrics_html = "\n".join(
        "<tr><td>{}</td><td>{}</td><td>{}</td><td>{}</td></tr>".format(
            html.escape(str(row["name"])),
            html.escape(str(row["baseline"])),
            html.escape(str(row["current"])),
            html.escape(str(row["delta"])),
        )
        for row in metric_rows
    )
    assertion_html = "\n".join(
        "<li class='{}'><b>{}</b> [{}]: {}</li>".format(
            "pass" if item.get("passed") else "fail",
            html.escape(str(item.get("type", ""))),
            html.escape(str(item.get("severity", "error"))),
            html.escape(str(item.get("message", item.get("actual", "")))),
        )
        for item in assertions
    )
    metadata = html.escape(json.dumps({
        "repository": manifest.get("repository"),
        "runtime": manifest.get("runtime"),
        "capture": manifest.get("capture"),
        "scenario": manifest.get("scenario"),
    }, indent=2, sort_keys=True))
    document = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Moment Forge — {html.escape(scenario['id'])}</title>
<style>
:root{{color-scheme:dark;--bg:#090d13;--panel:#111925;--line:#2d425a;--text:#dce8f2;--muted:#8ca0b4;--cyan:#66d9ef;--red:#ff6b72;--green:#72d69b}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--text);font:14px/1.45 system-ui,sans-serif}}main{{max-width:1600px;margin:auto;padding:24px}}code{{color:var(--cyan)}}.grid{{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}}.panel{{background:var(--panel);border:1px solid var(--line);padding:16px;border-radius:8px;overflow:auto;margin-bottom:16px}}video,img{{width:100%;height:auto;background:#000}}table{{width:100%;border-collapse:collapse}}th,td{{padding:7px 9px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}}.pass{{color:var(--green)}}.fail{{color:var(--red)}}.muted{{color:var(--muted)}}button,input{{margin:4px}}@media(max-width:900px){{.grid{{grid-template-columns:1fr}}}}
</style></head><body><main>
<h1>CUSTODIAN Moment Forge</h1>
<p><code>{html.escape(scenario['id'])}</code> — {html.escape(scenario['description'])}</p>
<p>Status: <b>{html.escape(str(manifest.get('status')))}</b> · fingerprint <code>{html.escape(manifest['stable_fingerprint']['value'][:16])}</code></p>
<section class="panel"><button id="playBoth">Play both</button><button id="pauseBoth">Pause</button><label>Scrub <input id="scrub" type="range" min="0" max="1000" value="0"></label>
<div class="grid"><div><h2>Baseline</h2>{_artifact_html(run_dir, 'baseline.mp4', 'video')}</div><div><h2>Current</h2>{_artifact_html(run_dir, 'current.mp4', 'video')}</div></div></section>
<div class="grid"><section class="panel"><h2>Baseline contact sheet</h2>{_artifact_html(run_dir, 'baseline_contact_sheet.png')}</section><section class="panel"><h2>Current contact sheet</h2>{_artifact_html(run_dir, 'current_contact_sheet.png')}</section></div>
<section class="panel"><h2>Visual difference (advisory)</h2>{_artifact_html(run_dir, 'visual_diff.png')}</section>
<section class="panel"><h2>Assertions</h2><ul>{assertion_html}</ul></section>
<section class="panel"><h2>Metric deltas</h2><table><thead><tr><th>Metric</th><th>Baseline</th><th>Current</th><th>Delta</th></tr></thead><tbody>{metrics_html}</tbody></table></section>
<section class="panel"><h2>Tick-enriched timeline</h2><table><thead><tr><th>Tick</th><th>Kind</th><th>Evidence</th></tr></thead><tbody>{timeline_rows}</tbody></table></section>
<section class="panel"><h2>Provenance</h2><pre>{metadata}</pre></section>
</main><script>
const videos=[...document.querySelectorAll('video')],scrub=document.getElementById('scrub');
document.getElementById('playBoth').onclick=()=>videos.forEach(v=>v.play());
document.getElementById('pauseBoth').onclick=()=>videos.forEach(v=>v.pause());
scrub.oninput=()=>videos.forEach(v=>{{if(Number.isFinite(v.duration))v.currentTime=v.duration*Number(scrub.value)/1000}});
</script></body></html>"""
    (run_dir / "index.html").write_text(document, encoding="utf-8")


def build_report(
    run_dir: Path,
    scenario: dict[str, Any],
    repo_root: Path,
    baseline_dir: Path | None = None,
    build_video: bool = True,
    require_mp4: bool = False,
    require_synchronized_media: bool = False,
    allow_incompatible_baseline: bool = False,
    keep_raw: bool = False,
) -> dict[str, Any]:
    run_dir = run_dir.resolve()
    runtime_result = _read_json(run_dir / "run_result.json", {})
    legacy_runtime = _read_json(run_dir / "runtime_manifest.json", {})
    if not runtime_result and legacy_runtime:
        runtime_result = legacy_runtime
    metrics = _read_json(run_dir / "metrics.json", {"schema": "custodian.moment_forge.metrics.v1", "stable": {}})
    timeline = _read_json(run_dir / "timeline.json", runtime_result.get("actions", []))
    probes = _read_json(run_dir / "probes.json", [])
    assertions = _read_json(run_dir / "assertions.json", runtime_result.get("assertions", []))
    telemetry = _read_json(run_dir / "telemetry.json", {"events": [], "warnings": []})
    capture_mode = str(runtime_result.get("capture_mode", "legacy"))
    contact_sheet = None
    if capture_mode != "none":
        contact_sheet = build_contact_sheet(
            run_dir,
            [int(tick) for tick in scenario["capture"]["contact_sheet_ticks"]],
            int(scenario["capture"]["width"]),
            int(scenario["capture"]["height"]),
            timeline,
        )
    audio_path, audio_state = _canonical_audio(run_dir, bool(scenario["capture"]["audio"]))
    audio_metrics = _pcm_audio_metrics(
        audio_path,
        scenario["capture"].get("audio_onset_threshold_dbfs"),
    ) if audio_path else {"available": False}
    video = _build_video(run_dir, int(scenario["capture"]["fps"]), audio_path) if build_video else None
    if require_mp4 and video is None:
        raise ValueError("MP4 was required but FFmpeg/video evidence is unavailable")

    scenario_hash = _sha256_payload(scenario)
    compatibility = _compatibility_key(scenario)
    baseline_metrics = None
    baseline_status = "not_requested"
    visual_diff = None
    baseline_audio_metrics = None
    if baseline_dir is not None:
        baseline_dir = baseline_dir.resolve()
        baseline_manifest = _read_json(baseline_dir / "manifest.json", {})
        compatible, mismatches = _baseline_compatibility(scenario, baseline_manifest)
        if not compatible and not allow_incompatible_baseline:
            raise BaselineCompatibilityError(
                "baseline incompatible: " + ", ".join(mismatches)
            )
        baseline_status = "compatible" if compatible else "incompatible_manual_only"
        for source_name, destination_name in (
            ("current_contact_sheet.png", "baseline_contact_sheet.png"),
            ("current.mp4", "baseline.mp4"),
        ):
            source = baseline_dir / source_name
            if source.is_file():
                shutil.copy2(source, run_dir / destination_name)
        if contact_sheet is not None and (run_dir / "baseline_contact_sheet.png").is_file():
            visual_diff = build_visual_diff(
                contact_sheet,
                run_dir / "baseline_contact_sheet.png",
                run_dir / "visual_diff.png",
            )
        baseline_metrics = _read_json(baseline_dir / "metrics.json", None)
        baseline_audio_metrics = baseline_manifest.get("media", {}).get("audio_metrics")

    stable_fingerprint = _stable_fingerprint(scenario, metrics, timeline, probes, assertions)
    metrics["stable_fingerprint"] = stable_fingerprint
    metrics["media"] = {
        "audio": audio_metrics,
        "visual_diff": visual_diff,
        "baseline_audio": baseline_audio_metrics,
    }
    _write_json(run_dir / "metrics.json", metrics)
    errors_pass = all(
        bool(item.get("passed", False))
        for item in assertions
        if item.get("severity", "error") == "error"
    )
    runtime_passed = bool(runtime_result.get("passed", runtime_result.get("status") == "passed"))
    stable_passed = runtime_passed and errors_pass
    synchronization = runtime_result.get("capture", {}).get("synchronization", "not_requested")
    if (
        capture_mode == "full"
        and (run_dir / "raw" / "capture.wav").is_file()
        and any((run_dir / "raw").glob("capture*.png"))
    ):
        synchronization = "verified"
    if require_synchronized_media and synchronization != "verified":
        raise ValueError("synchronized media was required but not verified")
    status = (
        "passed"
        if stable_passed and (not scenario["capture"]["audio"] or audio_path is not None)
        else "partial_media"
        if stable_passed
        else "failed_assertions"
    )
    repository = _git_metadata(repo_root)
    manifest = {
        "schema": "custodian.moment_forge.run_manifest.v1",
        "run_id": run_dir.name,
        "status": status,
        "scenario": {
            "id": scenario["id"],
            "schema_version": scenario["schema_version"],
            "path": runtime_result.get("scenario_path", ""),
            "sha256": scenario_hash,
        },
        "repository": repository,
        "runtime": runtime_result.get("runtime", {}),
        "capture": {
            "mode": capture_mode,
            "width": scenario["capture"]["width"],
            "height": scenario["capture"]["height"],
            "fps": scenario["capture"]["fps"],
            "audio_requested": scenario["capture"]["audio"],
            "synchronization": synchronization,
        },
        "artifacts": {
            "telemetry": "telemetry.json" if (run_dir / "telemetry.json").is_file() else None,
            "timeline": "timeline.json" if (run_dir / "timeline.json").is_file() else None,
            "probes": "probes.json" if (run_dir / "probes.json").is_file() else None,
            "assertions": "assertions.json" if (run_dir / "assertions.json").is_file() else None,
            "metrics": "metrics.json",
            "audio": audio_path.name if audio_path and audio_path.parent == run_dir else None,
            "video": video.name if video else None,
            "contact_sheet": contact_sheet.name if contact_sheet else None,
            "visual_diff": "visual_diff.png" if visual_diff else None,
            "report": "index.html",
        },
        "media": {
            "audio_state": audio_state,
            "audio_metrics": audio_metrics,
            "visual_diff": visual_diff,
            "ffmpeg_available": shutil.which("ffmpeg") is not None,
        },
        "tools": {
            "python": sys.version.split()[0],
            "pillow": Image.__version__ if hasattr(Image, "__version__") else "",
            "ffmpeg": shutil.which("ffmpeg") or "",
        },
        "baseline": {"status": baseline_status},
        "baseline_compatibility": compatibility,
        "stable_fingerprint": stable_fingerprint,
        "stable_assertions_passed": stable_passed,
        "generated_at": datetime.now().astimezone().isoformat(),
    }
    metric_rows = _metric_rows(metrics, baseline_metrics)
    _write_json(run_dir / "manifest.json", manifest)
    _write_json(run_dir / "metric_deltas.json", metric_rows)
    _write_html(run_dir, scenario, manifest, timeline, metric_rows, assertions)
    if not keep_raw and video is not None and (run_dir / "raw").is_dir():
        for frame in (run_dir / "raw").glob("capture*.png"):
            frame.unlink()
    return manifest
