"""ElevenLabs ile döngülü ortam sesi -> godot/assets/sfx/<ad>.wav (eski dosyanın ses seviyesinde, uçları çapraz geçişli).
  python tools/eleven_loop.py crowd 12 "prompt..."
Eski dosya _tmp/eleven/eski_<ad>.wav olarak yedeklenir."""
import json, os, shutil, sys, urllib.request, urllib.error
import numpy as np
import soundfile as sf

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY = open(os.path.join(ROOT, ".elevenlabs_key")).read().strip()
name, dur, prompt = sys.argv[1], float(sys.argv[2]), sys.argv[3]
out = os.path.join(ROOT, "godot", "assets", "sfx", name + ".wav")
raw = os.path.join(ROOT, "_tmp", "eleven", "loop_%s.mp3" % name)
os.makedirs(os.path.dirname(raw), exist_ok=True)
if not os.path.exists(raw):
    data = None
    for body in ({"text": prompt, "duration_seconds": dur, "prompt_influence": 0.5, "loop": True, "model_id": "eleven_text_to_sound_v2"},
                 {"text": prompt, "duration_seconds": dur, "prompt_influence": 0.5}):
        req = urllib.request.Request("https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128", data=json.dumps(body).encode(),
                                     headers={"xi-api-key": KEY, "Content-Type": "application/json"})
        try:
            data = urllib.request.urlopen(req, timeout=180).read()
            print("uretildi", "dongu=" + str("loop" in body))
            break
        except urllib.error.HTTPError as e:
            print("HTTP", e.code, e.read()[:200])
    if data is None:
        sys.exit(1)
    open(raw, "wb").write(data)
x, sr = sf.read(raw, dtype="float32", always_2d=True)
m = x.mean(axis=1)
# uçları çapraz geçişle birleştir: son 0.6 sn başın üstüne biner (dikişsiz döngü)
f = int(0.6 * sr)
if len(m) > f * 4:
    head, tail = m[:f].copy(), m[-f:].copy()
    t = np.linspace(0, 1, f, dtype="float32")
    m = m[:-f]
    m[:f] = head * np.sqrt(t) + tail * np.sqrt(1 - t)
old_rms = 0.05
if os.path.exists(out):
    o, _ = sf.read(out, dtype="float32", always_2d=True)
    old_rms = float(np.sqrt((o.mean(axis=1) ** 2).mean())) or 0.05
    bak = os.path.join(ROOT, "_tmp", "eleven", "eski_%s.wav" % name)
    if not os.path.exists(bak):
        shutil.copy(out, bak)
m = m * (old_rms / (float(np.sqrt((m ** 2).mean())) or 1e-6))
pk = float(np.abs(m).max())
if pk > 0.97:
    m *= 0.97 / pk
sf.write(out, m, sr, subtype="PCM_16")
print("OK %s %.1f sn %d Hz rms %.3f" % (name, len(m) / sr, sr, old_rms))
