from pathlib import Path

import soundfile as sf
from chatterbox.tts import ChatterboxTTS

model = ChatterboxTTS.from_pretrained(device="cpu")

west_gate_text = """
The west gate was still taking people when the closure order came.

Mothers pressed their children beneath the banners.

The Custodians walked the walls with covered lanterns.

And still... the ash came.
"""

text = """
Easy! Do not pull the count apart.

You! Outside the white!

Back to the count!
"""

out_dir = Path("takes/west_gate")
out_dir.mkdir(parents=True, exist_ok=True)

for i in range(1, 3):
    print(f"Generating take {i}/8...", flush=True)

    wav = model.generate(
        text,
        audio_prompt_path="reference.wav",
        exaggeration=0.40,
        cfg_weight=0.18,
        temperature=0.80,
        repetition_penalty=1.2,
        min_p=0.05,
        top_p=1.0,
    )

    audio = wav.squeeze().detach().cpu().numpy()

    path = out_dir / f"take_{i:02d}.wav"

    sf.write(
        path,
        audio,
        model.sr,
        subtype="PCM_16",
    )

    print(f"  -> {path}")
