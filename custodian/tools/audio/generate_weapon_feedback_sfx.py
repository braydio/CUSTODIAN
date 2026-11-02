#!/usr/bin/env python3
"""Generate temporary-production weapon feedback SFX for CUSTODIAN.

Outputs mono, 48 kHz, signed 16-bit WAV files using only Python's
standard library. No external samples or licensing dependencies.
"""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path
from typing import Callable

SAMPLE_RATE = 48_000
PEAK = 0.92
ROOT = Path(__file__).resolve().parents[2]

OUTPUTS = {
    "dry_fire": ROOT
    / "custodian/content/audio/sfx/weapons/common/weapon_dry_fire_01.wav",
    "reload_start": ROOT
    / "custodian/content/audio/sfx/weapons/carbine_mk1/carbine_mk1_reload_start_01.wav",
    "reload_complete": ROOT
    / "custodian/content/audio/sfx/weapons/carbine_mk1/carbine_mk1_reload_complete_01.wav",
    "heat_warning": ROOT
    / "custodian/content/audio/sfx/weapons/carbine_mk1/carbine_mk1_heat_warning_01.wav",
    "overheat_vent": ROOT
    / "custodian/content/audio/sfx/weapons/carbine_mk1/carbine_mk1_overheat_vent_01.wav",
}


def clamp(value: float, low: float = -1.0, high: float = 1.0) -> float:
    return max(low, min(high, value))


def exp_decay(time_sec: float, speed: float) -> float:
    return math.exp(-time_sec * speed)


def smooth_attack(time_sec: float, attack_sec: float) -> float:
    if attack_sec <= 0.0:
        return 1.0
    return min(1.0, max(0.0, time_sec / attack_sec))


def noise() -> float:
    return random.uniform(-1.0, 1.0)


def impulse(time_sec: float, start_sec: float, decay: float, frequency: float) -> float:
    local = time_sec - start_sec
    if local < 0.0:
        return 0.0
    return math.sin(math.tau * frequency * local) * exp_decay(local, decay)


def write_wav(
    path: Path,
    duration_sec: float,
    generator: Callable[[float], float],
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    frame_count = round(duration_sec * SAMPLE_RATE)
    samples = [generator(i / SAMPLE_RATE) for i in range(frame_count)]

    max_abs = max((abs(sample) for sample in samples), default=1.0)
    gain = PEAK / max(1.0, max_abs)

    packed = bytearray()
    for sample in samples:
        value = int(clamp(sample * gain) * 32767)
        packed.extend(struct.pack("<h", value))

    with wave.open(str(path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(bytes(packed))

    print(f"Wrote {path.relative_to(ROOT)} ({duration_sec:.2f}s)")


def dry_fire(time_sec: float) -> float:
    """Short metal trigger/bolt click: 0.12 seconds."""
    click = impulse(time_sec, 0.000, 95.0, 2_800.0)
    latch = impulse(time_sec, 0.019, 72.0, 1_650.0)
    body = impulse(time_sec, 0.004, 42.0, 420.0)

    local_noise = noise() * exp_decay(time_sec, 75.0)
    return click * 0.48 + latch * 0.34 + body * 0.18 + local_noise * 0.08


def reload_start(time_sec: float) -> float:
    """Magazine release and initial mechanical movement: 0.26 seconds."""
    release = impulse(time_sec, 0.000, 45.0, 1_050.0)
    metal = impulse(time_sec, 0.025, 36.0, 530.0)
    secondary = impulse(time_sec, 0.085, 48.0, 1_850.0)

    rattle_window = 1.0 if 0.035 <= time_sec <= 0.155 else 0.0
    rattle = noise() * rattle_window * exp_decay(max(0.0, time_sec - 0.035), 13.0)

    return release * 0.32 + metal * 0.36 + secondary * 0.22 + rattle * 0.10


def reload_complete(time_sec: float) -> float:
    """Magazine seat and positive latch confirmation: 0.22 seconds."""
    seat = impulse(time_sec, 0.000, 36.0, 360.0)
    latch = impulse(time_sec, 0.026, 60.0, 1_800.0)
    confirmation = impulse(time_sec, 0.052, 75.0, 3_100.0)

    transient_noise = noise() * exp_decay(time_sec, 42.0)
    return seat * 0.42 + latch * 0.31 + confirmation * 0.20 + transient_noise * 0.07


def heat_warning(time_sec: float) -> float:
    """Compact machine warning chirp with metallic edge: 0.18 seconds."""
    duration = 0.18
    normalized = time_sec / duration
    frequency = 1_480.0 - 420.0 * normalized

    envelope = smooth_attack(time_sec, 0.008) * exp_decay(time_sec, 12.0)

    tone = math.sin(math.tau * frequency * time_sec)
    harmonic = math.sin(math.tau * frequency * 2.03 * time_sec) * 0.28
    mechanical_tick = impulse(time_sec, 0.000, 80.0, 2_400.0)

    return (tone + harmonic) * envelope * 0.48 + mechanical_tick * 0.20


def overheat_vent(time_sec: float) -> float:
    """Pressure-release hiss with valve clack and decaying machinery: 1.05 seconds."""
    duration = 1.05
    release = impulse(time_sec, 0.000, 34.0, 520.0)
    valve = impulse(time_sec, 0.026, 52.0, 1_420.0)

    attack = smooth_attack(time_sec, 0.025)
    release_env = max(0.0, 1.0 - time_sec / duration) ** 1.7

    flutter = 0.78 + 0.22 * math.sin(math.tau * 17.0 * time_sec)
    hiss = noise() * attack * release_env * flutter

    low_pressure = math.sin(math.tau * 92.0 * time_sec) * exp_decay(time_sec, 3.2)

    # cooling_ring = 0.0
    final_tick = impulse(time_sec, 0.91, 48.0, 920.0)

    return (
        release * 0.25
        + valve * 0.22
        + hiss * 0.48
        + low_pressure * 0.12
        + final_tick * 0.05
    )


def main() -> None:
    random.seed(0xC0570D1A)

    write_wav(OUTPUTS["dry_fire"], 0.12, dry_fire)
    write_wav(OUTPUTS["reload_start"], 0.26, reload_start)
    write_wav(OUTPUTS["reload_complete"], 0.22, reload_complete)
    write_wav(OUTPUTS["heat_warning"], 0.18, heat_warning)
    write_wav(OUTPUTS["overheat_vent"], 1.05, overheat_vent)


if __name__ == "__main__":
    main()
