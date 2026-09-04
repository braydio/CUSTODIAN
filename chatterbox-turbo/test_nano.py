import soundfile as sf
from chatterbox.tts_turbo import ChatterboxTurboTTS

print("Loading Chatterbox Nano on CPU...", flush=True)

model = ChatterboxTurboTTS.from_pretrained(device="cpu", nano=True)

print("Generating...", flush=True)

text = "The West Gate closure. Thousands still inside."

wav = model.generate(
    text,
    audio_prompt_path="reference.wav",
)

print("GENERATION RETURNED", wav.shape, flush=True)
print("Generated for text:", text, flush=True)
audio = wav.squeeze().detach().cpu().numpy()

sf.write("forlorn_nano_test.wav", audio, model.sr, subtype="PCM_16")

print("DONE: forlorn_nano_test.wav", flush=True)
