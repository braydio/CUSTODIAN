import torch
import torchaudio as ta
from chatterbox.tts_turbo import ChatterboxTurboTTS

print("Loading Turbo...")
model = ChatterboxTurboTTS.from_pretrained(device="cuda")

print("Generating...")
wav = model.generate(
    "The ritual has already begun. You should not have come here.",
    audio_prompt_path="reference.wav",
)

ta.save("forlorn_test.wav", wav, model.sr)
print("DONE: forlorn_test.wav")
