"""ISOLATED, GATED legacy branch: Meshy `.meshy` v1 -> GLB container reconstruction.

Only imported when the input header is `MESHY.AI` AND the caller passed --confirm-authorized. `--confirm-authorized` is the user's own assertion
that they are entitled to process the file (e.g. their own generation, provider permission); it is NOT automated proof of authorization.
The key/layout come from the user-supplied reconstruction script (third-party reverse-engineered format notes). The 16-byte authentication tag
is SKIPPED, so the result is never cryptographically authenticated. Standard exported GLB is the supported default path; do not extend this
decoder or reuse it on main without re-checking the provider's explicit authorization and the `cryptography` licence/policy."""
import struct
KEY = b'JSON{"accessors":[{"bufferView":'; ENC_BEGIN, ENC_END, TAG_END = 32, 8224, 8240
SUPPORTED_VERSION = 1

def header_info(blob):
    if len(blob) < TAG_END or blob[:8] != b'MESHY.AI': raise ValueError('not a Meshy container')
    return {'version': struct.unpack_from('<H', blob, 8)[0]}

def to_glb(blob):
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    if header_info(blob)['version'] != SUPPORTED_VERSION: raise ValueError('unsupported Meshy container version (only v1)')
    dec = Cipher(algorithms.AES(KEY), modes.CTR(blob[10:22] + b'\x00\x00\x00\x02')).decryptor()
    pre = dec.update(blob[ENC_BEGIN:ENC_END]) + dec.finalize()
    if pre[:4] != b'glTF': raise ValueError('reconstruction did not yield GLB magic')
    out = bytearray(pre + blob[TAG_END:]); struct.pack_into('<I', out, 8, len(out)); return bytes(out)
