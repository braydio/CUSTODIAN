from PIL import Image
import os

INPUT_DIR = "input_sprites"
OUTPUT_DIR = "output_sprites"

TARGET_W, TARGET_H = 32, 64
CANVAS_W, CANVAS_H = 96, 96

os.makedirs(OUTPUT_DIR, exist_ok=True)


def trim_transparency(img):
    bbox = img.getbbox()
    if bbox:
        return img.crop(bbox)
    return img  # fallback if empty


def process_image(path):
    img = Image.open(path).convert("RGBA")

    # --- TRIM EMPTY TRANSPARENCY ---

    print(img.size)
    img = trim_transparency(img)

    print(img.size)
    # --- SCALE TO TARGET HEIGHT ---
    scale = TARGET_H / img.height
    new_w = int(img.width * scale)
    new_h = int(img.height * scale)

    img = img.resize((new_w, new_h), Image.NEAREST)

    # --- CLAMP WIDTH IF TOO WIDE ---
    if new_w > TARGET_W:
        scale = TARGET_W / new_w
        img = img.resize((int(new_w * scale), int(new_h * scale)), Image.NEAREST)

    # --- CREATE FINAL 96x96 CANVAS ---
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))

    # --- BOTTOM-CENTER ALIGN (FEET LOCK) ---
    x = (CANVAS_W - img.width) // 2
    y = CANVAS_H - img.height

    print("Image final size:")
    print(img.size)

    canvas.paste(img, (x, y), img)

    return canvas


for file in os.listdir(INPUT_DIR):
    if file.endswith(".png"):
        result = process_image(os.path.join(INPUT_DIR, file))
        result.save(os.path.join(OUTPUT_DIR, file))

print("Done.")
