"""Stdlib-only preflight: check source PNG dimensions and package layout."""
from pathlib import Path
import struct

root = Path(__file__).resolve().parent.parent
files = {
    'creche_complete_1464x1074.png': (1464, 1074),
    'creche_floor_960x704.png': (960, 704),
    'creche_walls_960x704.png': (960, 704),
}
for filename, expected in files.items():
    path = root / 'references' / filename
    with path.open('rb') as stream:
        head = stream.read(24)
    if head[:8] != b'\x89PNG\r\n\x1a\n':
        raise RuntimeError('Not a PNG: ' + str(path))
    size = struct.unpack('>II', head[16:24])
    if size != expected:
        raise RuntimeError(f'{filename} wrong size {size}, expected {expected}')
    print(f'PASS {filename}: {size[0]}x{size[1]}')
print('PASS all source sizes. Pixel calibration: 32 px per Blender meter.')
