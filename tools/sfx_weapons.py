"""Silah ve ayak sesleri (sentez): her silah türüne kendi savuruşu + isabeti, zemine göre adım sesi.
  python tools/sfx_weapons.py   -> godot/assets/sfx/*.wav
"""
import os
import wave
import numpy as np
from scipy.signal import butter, sosfilt

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'godot', 'assets', 'sfx')
SR = 44100
rng = np.random.default_rng(11)


def t_(d):
    return np.arange(int(SR * d)) / SR


def noise(d):
    return rng.uniform(-1, 1, int(SR * d))


def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], 'bandpass', fs=SR, output='sos'), x)


def lp(x, f, order=2):
    return sosfilt(butter(order, f, 'lowpass', fs=SR, output='sos'), x)


def hp(x, f, order=2):
    return sosfilt(butter(order, f, 'highpass', fs=SR, output='sos'), x)


def env(n, a=0.004, decay=6.0):
    t = np.arange(n) / SR
    return np.minimum(1.0, t / max(a, 1e-4)) * np.exp(-decay * t / (n / SR))


def swell(n, peak=0.45, sharp=2.0):
    """savuruş zarfı: yükselip düşen (havayı yaran bıçak)"""
    u = np.linspace(0, 1, n)
    return np.where(u < peak, (u / peak) ** sharp, ((1 - u) / (1 - peak)) ** 1.6)


def sweep_bp(x, f0, f1, width=0.5, steps=24):
    """bant geçirgeni zamanla kaydır (vınnn)"""
    n = len(x)
    out = np.zeros(n)
    seg = n // steps + 1
    for i in range(steps):
        a, b = i * seg, min(n, (i + 1) * seg + seg // 2)
        if a >= n:
            break
        f = f0 + (f1 - f0) * i / max(1, steps - 1)
        y = bp(x[max(0, a - seg // 2):b], f * (1 - width / 2), f * (1 + width / 2))
        y = y[(a - max(0, a - seg // 2)):]
        w = np.hanning(len(y) * 2)[len(y):] if i == steps - 1 else np.ones(len(y))
        out[a:a + len(y)] += y[:n - a] * w[:n - a]
    return out


def ring(freqs, d, decay=10.0, amps=None):
    t = t_(d)
    amps = amps or [1.0] * len(freqs)
    return sum(a * np.sin(2 * np.pi * f * t + rng.uniform(0, 6)) for f, a in zip(freqs, amps)) * env(len(t), 0.001, decay)


def write(name, x):
    x = np.asarray(x, dtype=np.float64)
    # kısa giriş/çıkış yumuşatma: tık sesi olmasın
    f = min(len(x) // 8, int(SR * 0.004))
    x[:f] *= np.linspace(0, 1, f)
    x[-f:] *= np.linspace(1, 0, f)
    m = np.max(np.abs(x)) or 1
    x = (x / m * 0.9 * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(x.tobytes())
    print('yazıldı', name, round(len(x) / SR, 2), 's')


def pad(x, d):
    n = int(SR * d)
    return np.concatenate([x, np.zeros(max(0, n - len(x)))])[:n]


# ---------------------------------------------------------------- savuruşlar
def swing(d, f0, f1, width, peak, metal=0.0, metal_f=3200):
    n = int(SR * d)
    x = sweep_bp(noise(d), f0, f1, width) * swell(n, peak)
    if metal > 0:
        x += ring([metal_f, metal_f * 1.53], d, 9.0) * metal * swell(n, peak, 1.2)
    return x


write('swing_blade', swing(0.22, 1800, 5200, 0.5, 0.45, 0.06, 4200))     # kunai / tantō / çift bıçak: kısa, ince "fşt"
write('swing_sword', swing(0.30, 900, 4200, 0.45, 0.5, 0.08, 3300))      # katana: uzun "vuuşş", hafif çelik şarkısı
write('swing_heavy', swing(0.48, 220, 900, 0.7, 0.55) * 1.0 + lp(noise(0.48), 180) * swell(int(SR * 0.48), 0.55) * 0.6)   # nodachi / çekiç / tırpan: derin "vuuum"
write('swing_staff', swing(0.30, 420, 1500, 0.6, 0.5))                   # asa / bō: odunsu "vuff"
write('swing_fan', swing(0.40, 300, 2600, 0.9, 0.35) + lp(noise(0.40), 600) * swell(int(SR * 0.40), 0.35) * 0.5)   # yelpaze: geniş rüzgâr
ch = swing(0.32, 700, 2600, 0.6, 0.5)
for k in range(5):   # zincir şıngırtısı
    at = int(SR * (0.03 + k * 0.05))
    c = ring([2600 + rng.uniform(-300, 300), 4100 + rng.uniform(-400, 400)], 0.06, 18.0) * 0.35
    ch[at:at + len(c)] += c[:len(ch) - at]
write('swing_chain', ch)


# ---------------------------------------------------------------- isabetler
def thud(d, f, amt=1.0):
    return lp(noise(d), f) * env(int(SR * d), 0.002, 9.0) * amt


def body(d=0.16, f0=140, f1=55):
    t = t_(d)
    ph = 2 * np.pi * np.cumsum(np.linspace(f0, f1, len(t))) / SR
    return np.sin(ph) * env(len(t), 0.002, 8.0)


# kesik: et kesen bıçak ("şlak") = keskin gürültü patlaması + kısa çelik çınlaması + gövde
hb = hp(noise(0.18), 1500) * env(int(SR * 0.18), 0.001, 14.0) * 0.8 + body(0.18, 160, 70) * 0.6 + pad(ring([3800, 5900], 0.12, 22.0) * 0.25, 0.18)
write('hit_blade', hb)
# kılıç isabeti: daha uzun kesik + çelik "şiing" kuyruğu
hs = hp(noise(0.3), 1100) * env(int(SR * 0.3), 0.001, 12.0) * 0.7 + body(0.3, 150, 60) * 0.7 + ring([2900, 4450, 6600], 0.3, 10.0, [0.35, 0.2, 0.1])
write('hit_sword', hs)
# ağır silah: derin "güm" + kalın metal çatırtı
hh = body(0.4, 110, 38) * 1.2 + thud(0.4, 380, 0.9) + pad(ring([900, 1430, 2210], 0.25, 12.0, [0.3, 0.2, 0.12]), 0.4)
write('hit_heavy_weapon', hh)
# asa: tahta "tok"
st_ = ring([620, 1240, 1900], 0.14, 26.0, [1.0, 0.35, 0.15]) + thud(0.14, 900, 0.5) + body(0.14, 130, 70) * 0.5
write('hit_staff', st_)
# zincir/orak: çengel + şıngırtı
hc = hb * 0.8
for k in range(4):
    at = int(SR * (0.02 + k * 0.035))
    c = ring([2400 + rng.uniform(-300, 300), 3900], 0.07, 16.0) * 0.4
    hc[at:at + len(c)] += c[:len(hc) - at]
write('hit_chain', hc)
# pençe: üç hızlı tırmık
cl = np.zeros(int(SR * 0.22))
for k in range(3):
    at = int(SR * k * 0.045)
    s = hp(noise(0.06), 2200) * env(int(SR * 0.06), 0.001, 10.0)
    cl[at:at + len(s)] += s[:len(cl) - at]
cl += body(0.22, 150, 70) * 0.5
write('hit_claw', cl)
# yelpaze: hava darbesi + yumuşak şaplak
hf = lp(noise(0.3), 900) * env(int(SR * 0.3), 0.01, 5.0)
hf[:int(SR * 0.08)] += hp(noise(0.08), 1200) * env(int(SR * 0.08), 0.001, 12.0) * 0.6
write('hit_fan', hf)
# kılıç bloğu: çelik çeliğe "çang"
write('clash', ring([2100, 3170, 4890, 6950], 0.45, 7.0, [1.0, 0.6, 0.35, 0.2])
      + pad(hp(noise(0.05), 2500) * env(int(SR * 0.05), 0.001, 10.0), 0.45) * 0.7)


# ---------------------------------------------------------------- adımlar (her zemin 3 varyasyon)
def step_dirt(i):
    d = 0.12
    x = lp(noise(d), 700 + i * 120) * env(int(SR * d), 0.003, 9.0) + body(d, 95 + i * 8, 55) * 0.5
    x += hp(noise(d), 2500) * env(int(SR * d), 0.01, 16.0) * 0.12   # toprak çıtırtısı
    return x


def step_grass(i):
    d = 0.16
    return bp(noise(d), 1500 + i * 300, 5500) * env(int(SR * d), 0.012, 8.0) * 0.7 + body(d, 90, 50) * 0.35


def step_stone(i):
    d = 0.10
    return ring([1900 + i * 150, 3100 + i * 200], d, 30.0, [0.25, 0.15]) + hp(noise(d), 1800) * env(int(SR * d), 0.001, 22.0) * 0.6 + body(d, 120, 70) * 0.4


def step_wood(i):
    d = 0.14
    return ring([210 + i * 18, 480 + i * 30, 950], d, 18.0, [0.7, 0.4, 0.15]) + lp(noise(d), 1400) * env(int(SR * d), 0.002, 14.0) * 0.4


for i in range(3):
    write('step_dirt%d' % i, step_dirt(i))
    write('step_grass%d' % i, step_grass(i))
    write('step_stone%d' % i, step_stone(i))
    write('step_wood%d' % i, step_wood(i))
