"""ElevenLabs ses efekti üretimi -> godot/assets/sfx/<ad>_vN.ogg (kırpılmış, -18 dBFS RMS).
Anahtar: proje kökünde .elevenlabs_key (depoya girmez).
  python tools/eleven_sfx.py liste.json            # [{"name": "poof", "prompt": "...", "dur": 1.2, "n": 3, "replace": true, "soft": true, "keep": 3, "fadein": 0.05}, ...]  (soft: n adaydan en yumuşak başlayan keep tanesi)
  python tools/eleven_sfx.py liste.json --only poof,seal
replace=true: o adın eski _vN.ogg varyantları silinir (yalnız yenileri kalır); false: sonuna eklenir.
Ham mp3'ler _tmp/eleven/ altında saklanır (aynı istek yeniden ücretlenmez)."""
import io, json, os, re, sys, time, urllib.request, urllib.error, hashlib
import numpy as np
import soundfile as sf

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "godot", "assets", "sfx")
RAW = os.path.join(ROOT, "_tmp", "eleven")
KEY = open(os.path.join(ROOT, ".elevenlabs_key")).read().strip()


def gen(prompt, dur, seed_tag, influence=0.45):
    os.makedirs(RAW, exist_ok=True)
    h = hashlib.md5(("%s|%s|%s|%s" % (prompt, dur, seed_tag, influence)).encode()).hexdigest()[:16]
    p = os.path.join(RAW, h + ".mp3")
    if os.path.exists(p) and os.path.getsize(p) > 1000:
        return p
    body = {"text": prompt, "prompt_influence": influence}
    if dur:
        body["duration_seconds"] = dur
    req = urllib.request.Request("https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128", data=json.dumps(body).encode(),
                                 headers={"xi-api-key": KEY, "Content-Type": "application/json"})
    for attempt in range(4):
        try:
            data = urllib.request.urlopen(req, timeout=120).read()
            open(p, "wb").write(data)
            return p
        except urllib.error.HTTPError as e:
            msg = e.read()[:300]
            if e.code in (429, 500, 502, 503) and attempt < 3:
                time.sleep(4 + attempt * 6)
                continue
            raise RuntimeError("HTTP %d %s" % (e.code, msg))
    return None


def attack_ms(mp3):
    """Sesin %5'ten %80 tepeye çıkış süresi: küçükse 'pat' diye patlar, büyükse yumuşak başlar."""
    x, sr = sf.read(mp3, dtype="float32", always_2d=True)
    env = np.abs(x.mean(axis=1))
    w = max(1, int(0.004 * sr))
    env = np.convolve(env, np.ones(w) / w, mode="same")
    pk = float(env.max()) or 1e-6
    return (int(np.argmax(env > pk * 0.8)) - int(np.argmax(env > pk * 0.05))) / sr * 1000.0


def tail_score(mp3):
    """Vuruş sesi puanı (küçük = iyi): ana darbeden sonra gelen ikinci / üçüncü çıtırtıların (cart curt) enerjisi."""
    x, sr = sf.read(mp3, dtype="float32", always_2d=True)
    env = np.abs(x.mean(axis=1))
    w = max(1, int(0.006 * sr))
    env = np.convolve(env, np.ones(w) / w, mode="same")
    ip = int(np.argmax(env))
    after = env[ip + int(0.09 * sr):]
    if len(after) == 0:
        return 0.0
    return float(after.max() / (env[ip] + 1e-9))


def process(mp3, out, loop=False, fadein=0.0):
    x, sr = sf.read(mp3, dtype="float32", always_2d=True)
    m = x.mean(axis=1)
    # baştaki / sondaki sessizliği kırp (tepe değerinin %2'si)
    thr = max(1e-4, float(np.abs(m).max()) * 0.02)
    idx = np.where(np.abs(m) > thr)[0]
    if len(idx):
        a = max(0, idx[0] - int(0.005 * sr))
        b = min(len(m), idx[-1] + int(0.06 * sr))
        m = m[a:b]
    rms = float(np.sqrt((m ** 2).mean())) or 1e-6
    m = m * (10 ** (-18 / 20) / rms)
    pk = float(np.abs(m).max())
    if pk > 0.97:
        m = m * (0.97 / pk)
    if fadein > 0.0:
        fi = min(len(m), int(fadein * sr))
        m[:fi] *= np.linspace(0, 1, fi, dtype="float32") ** 1.5
    if not loop:
        f = min(len(m), int(0.03 * sr))
        m[-f:] *= np.linspace(1, 0, f, dtype="float32")
    sf.write(out, m, sr, format="OGG", subtype="VORBIS")
    return len(m) / sr


def main():
    spec = json.load(open(sys.argv[1], encoding="utf-8"))
    only = None
    for a in sys.argv[2:]:
        if a.startswith("--only"):
            only = set(sys.argv[sys.argv.index(a) + 1].split(","))
    for s in spec:
        name = s["name"]
        if only and name not in only:
            continue
        n = int(s.get("n", 3))
        made = []
        try:
            for k in range(n):
                made.append(gen(s["prompt"], s.get("dur"), k, float(s.get("inf", 0.45))))
        except Exception as e:
            print("HATA", name, e)
            continue
        if s.get("keep") and not s.get("soft"):   # kısa vuruşlar: çıtırtılı / uzun kuyruklu adayları at (en kısa ve en "tek darbe" olanlar kalır)
            made.sort(key=tail_score)
            print("   kuyruk puanı:", " ".join("%.2f" % tail_score(q) for q in made))
            made = made[:int(s["keep"])]
        if s.get("soft"):   # yumuşak başlayanları seç ("pat" diye patlayanları at)
            made.sort(key=attack_ms, reverse=True)
            print("   atak (ms):", " ".join("%.0f" % attack_ms(q) for q in made))
            made = made[:int(s.get("keep", 3))]
        old = sorted(f for f in os.listdir(OUT) if re.fullmatch(re.escape(name) + r"_v\d+\.ogg(\.import)?", f))
        start = 0
        if s.get("replace", True):
            for f in old:
                os.remove(os.path.join(OUT, f))
        else:
            start = len([f for f in old if f.endswith(".ogg")])
        durs = []
        for k, p in enumerate(made):
            durs.append(process(p, os.path.join(OUT, "%s_v%d.ogg" % (name, start + k)), bool(s.get("loop")), float(s.get("fadein", 0.0))))
        print("OK %-16s %d varyant  %s sn" % (name, len(made), " ".join("%.1f" % d for d in durs)))


main()
