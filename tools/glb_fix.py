"""AI ile üretilmiş (Meshy vb.) dokusuz GLB'leri oyuna hazırlar.

Kullanım: python tools/glb_fix.py girdi.glb cikti.glb

- NORMAL yoksa yumuşak (alan ağırlıklı) köşe normalleri hesaplar; Godot normalsiz mesh'i gölgesiz düz silüet gösteriyor.
- Aynı konumdaki kopya köşeleri birleştirir (normal dikişlerini kapatır).
"""
import json
import struct
import sys

import numpy as np

COMP = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def read_glb(path):
    data = open(path, "rb").read()
    jlen = struct.unpack("<I", data[12:16])[0]
    j = json.loads(data[20:20 + jlen])
    off = 20 + jlen
    blen = struct.unpack("<I", data[off:off + 4])[0]
    return j, bytearray(data[off + 8:off + 8 + blen])


def accessor(j, buf, i):
    a = j["accessors"][i]
    bv = j["bufferViews"][a["bufferView"]]
    dt = COMP[a["componentType"]]
    n = NCOMP[a["type"]]
    start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    arr = np.frombuffer(bytes(buf[start:start + a["count"] * n * np.dtype(dt).itemsize]), dtype=dt)
    return arr.reshape(-1, n) if n > 1 else arr


def add_view(j, buf, arr, target):
    while len(buf) % 4:
        buf.append(0)
    off = len(buf)
    raw = arr.tobytes()
    buf.extend(raw)
    j["bufferViews"].append({"buffer": 0, "byteOffset": off, "byteLength": len(raw), "target": target})
    return len(j["bufferViews"]) - 1


def main(src, dst):
    j, buf = read_glb(src)
    out_buf = bytearray()
    new_views, new_acc = [], []
    j_out = dict(j)
    j_out["bufferViews"], j_out["accessors"] = new_views, new_acc
    for m in j["meshes"]:
        for p in m["primitives"]:
            pos = accessor(j, buf, p["attributes"]["POSITION"]).astype(np.float64)
            idx = accessor(j, buf, p["indices"]).astype(np.int64).reshape(-1, 3) if "indices" in p else np.arange(len(pos)).reshape(-1, 3)
            # kopya köşeleri birleştir
            key = np.round(pos, 6)
            uniq, inv = np.unique(key, axis=0, return_inverse=True)
            inv = inv.reshape(-1)
            idx = inv[idx]
            pos = uniq
            # alan ağırlıklı yumuşak normaller
            v0, v1, v2 = pos[idx[:, 0]], pos[idx[:, 1]], pos[idx[:, 2]]
            fn = np.cross(v1 - v0, v2 - v0)
            nrm = np.zeros_like(pos)
            for k in range(3):
                np.add.at(nrm, idx[:, k], fn)
            ln = np.linalg.norm(nrm, axis=1, keepdims=True)
            nrm = nrm / np.maximum(ln, 1e-12)
            pos32 = pos.astype(np.float32)
            nv = add_view(j_out, out_buf, pos32, 34962)
            new_acc.append({"bufferView": nv, "componentType": 5126, "count": len(pos32), "type": "VEC3",
                            "min": pos32.min(0).tolist(), "max": pos32.max(0).tolist()})
            pa = len(new_acc) - 1
            nn = add_view(j_out, out_buf, nrm.astype(np.float32), 34962)
            new_acc.append({"bufferView": nn, "componentType": 5126, "count": len(nrm), "type": "VEC3"})
            na = len(new_acc) - 1
            ni = add_view(j_out, out_buf, idx.astype(np.uint32).reshape(-1), 34963)
            new_acc.append({"bufferView": ni, "componentType": 5125, "count": idx.size, "type": "SCALAR"})
            p["attributes"] = {"POSITION": pa, "NORMAL": na}
            p["indices"] = len(new_acc) - 1
            print("mesh:", len(pos32), "köşe,", len(idx), "üçgen")
    j_out["buffers"] = [{"byteLength": len(out_buf)}]
    js = json.dumps(j_out).encode()
    while len(js) % 4:
        js += b" "
    while len(out_buf) % 4:
        out_buf.append(0)
    total = 12 + 8 + len(js) + 8 + len(out_buf)
    with open(dst, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        f.write(struct.pack("<II", len(out_buf), 0x004E4942) + bytes(out_buf))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
