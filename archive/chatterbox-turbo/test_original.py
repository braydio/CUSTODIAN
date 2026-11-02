import soundfile as sf
from chatterbox.tts import ChatterboxTTS

print("Loading original Chatterbox on CPU...", flush=True)

model = ChatterboxTTS.from_pretrained(device="cpu")

print("Generating...", flush=True)

wav = model.generate(
    "The west gate, was still taking people... when the closure order came... Mothers pressed their children beneath the banners. The Custodians... walked the walls with covered lanterns... And, still, the ash came.",
    audio_prompt_path="reference.wav",
    # Performance controls
    exaggeration=0.70,
    cfg_weight=0.30,
    temperature=0.80,
    repetition_penalty=1.20,
    min_p=0.05,
    top_p=1.0,
)

print("Generation returned:", wav.shape, flush=True)

audio = wav.squeeze().detach().cpu().numpy()

sf.write(
    "forlorn_original_test.wav",
    audio,
    model.sr,
    subtype="PCM_16",
)

print("DONE: forlorn_original_test.wav", flush=True)
