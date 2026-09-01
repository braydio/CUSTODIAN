import soundfile as sf
from chatterbox.tts_turbo import ChatterboxTurboTTS

print("Loading Chatterbox Nano on CPU...", flush=True)

model = ChatterboxTurboTTS.from_pretrained(device="cpu", nano=True)

print("Generating...", flush=True)

wav = model.generate(
    "When the station records stopped agreeing with the people in front of us, we wrote the name down and tied it at the wrist.",
    audio_prompt_path="reference.wav",
)

print("GENERATION RETURNED", wav.shape, flush=True)

audio = wav.squeeze().detach().cpu().numpy()

sf.write("forlorn_nano_test.wav", audio, model.sr, subtype="PCM_16")

print("DONE: forlorn_nano_test.wav", flush=True)
