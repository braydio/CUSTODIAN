#!/usr/bin/env python3
"""Guard the Godot-compatible PCM contract for the medium-hit WAV variant."""

from pathlib import Path
import wave


ASSET = Path(__file__).resolve().parents[2] / "content/audio/sfx/combat/hit_medium_body_01-1.wav"


def main() -> int:
    with wave.open(str(ASSET), "rb") as stream:
        assert stream.getcomptype() == "NONE", stream.getcomptype()
        assert stream.getnchannels() == 2, stream.getnchannels()
        assert stream.getsampwidth() == 2, stream.getsampwidth()
        assert stream.getframerate() == 48_000, stream.getframerate()
        duration = stream.getnframes() / stream.getframerate()
        assert abs(duration - 0.683521) < 0.0001, duration
    print("audio_pcm16_asset_smoke: PASS (PCM16 stereo, 48 kHz, duration retained)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
