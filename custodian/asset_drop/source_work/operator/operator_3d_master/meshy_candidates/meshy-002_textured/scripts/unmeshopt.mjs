import fs from 'fs'; import { MeshoptDecoder } from './meshopt_decoder.mjs';
const [inp, outp] = process.argv.slice(2); const d = fs.readFileSync(inp);
const jl = d.readUInt32LE(12); const j = JSON.parse(d.slice(20, 20 + jl).toString());
const bo = 20 + jl + 8; const bin = d.slice(bo, bo + j.buffers[0].byteLength);
await MeshoptDecoder.ready; const parts = []; let off = 0; const views = [];
for (const v of j.bufferViews) {
  const e = v.extensions && v.extensions.EXT_meshopt_compression;
  if (!e) { const raw = bin.slice(v.byteOffset || 0, (v.byteOffset || 0) + v.byteLength); const pad = (4 - (raw.length % 4)) % 4; parts.push(Buffer.from(raw), Buffer.alloc(pad)); const nv = { buffer: 0, byteOffset: off, byteLength: raw.length }; if (v.target) nv.target = v.target; views.push(nv); off += raw.length + pad; continue; }
  const src = new Uint8Array(bin.buffer, bin.byteOffset + e.byteOffset, e.byteLength);
  const out = await MeshoptDecoder.decodeGltfBufferAsync(e.count, e.byteStride, src, e.mode, e.filter || 'NONE');
  const pad = (4 - (out.length % 4)) % 4; parts.push(Buffer.from(out), Buffer.alloc(pad));
  const nv = { buffer: 0, byteOffset: off, byteLength: out.length, target: v.target }; if (v.byteStride && v.target === 34962) nv.byteStride = v.byteStride; views.push(nv); off += out.length + pad;
}
j.bufferViews = views; j.buffers = [{ byteLength: off }]; const drop = x => (x || []).filter(k => k !== 'EXT_meshopt_compression'); j.extensionsUsed = drop(j.extensionsUsed); j.extensionsRequired = drop(j.extensionsRequired); j.asset.generator += ' + local meshopt decode';
let js = Buffer.from(JSON.stringify(j)); js = Buffer.concat([js, Buffer.alloc((4 - js.length % 4) % 4, 0x20)]);
const binb = Buffer.concat(parts); const total = 12 + 8 + js.length + 8 + binb.length; const h = Buffer.alloc(12); h.write('glTF'); h.writeUInt32LE(2, 4); h.writeUInt32LE(total, 8);
const c1 = Buffer.alloc(8); c1.writeUInt32LE(js.length, 0); c1.write('JSON', 4); const c2 = Buffer.alloc(8); c2.writeUInt32LE(binb.length, 0); c2.writeUInt32LE(0x004E4942, 4);
fs.writeFileSync(outp, Buffer.concat([h, c1, js, c2, binb])); console.log('wrote', outp, total);
