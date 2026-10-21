"""Shinobi dünyasını fırınlar -> godot/data/world/
  height.bin  : float32 yükseklik (W x H), 4 m/piksel
  albedo.png  : arazi rengi
  biome.png   : R=biyom id, G=yol, B=nehir/ıslak
  veg.bin     : bitki örtüsü örnekleri (x, y, z, ölçek, dönüş, tip) float32
  map.png     : dünya haritası ekranı için stilize harita
  world.json  : köyler, ülkeler, yerler
"""
import os
import sys
import json
import math
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from world_layout import WORLD, LAND, COUNTRIES, VILLAGES, LANDMARKS, ROADS, RIVERS

OUT = os.path.join(os.path.dirname(__file__), '..', 'godot', 'data', 'world')
os.makedirs(OUT, exist_ok=True)
R = WORLD['res']
W = int((WORLD['x1'] - WORLD['x0']) / R)
H = int((WORLD['y1'] - WORLD['y0']) / R)
xs = WORLD['x0'] + (np.arange(W) + .5) * R
ys = WORLD['y1'] - (np.arange(H) + .5) * R  # satır 0 = kuzey
X, Y = np.meshgrid(xs, ys)
rng = np.random.default_rng(42)
print('grid', W, H)

BIOMES = ['sea', 'beach', 'forest', 'desert', 'rain', 'rock', 'rice', 'grass', 'snow', 'mountain', 'swamp', 'village', 'road']
BID = {b: i for i, b in enumerate(BIOMES)}


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def value_noise(scale, seed):
    """Bilinear ara değerli rastgele ızgara gürültüsü (0..1)."""
    r = np.random.default_rng(seed)
    gw, gh = int((WORLD['x1'] - WORLD['x0']) / scale) + 3, int((WORLD['y1'] - WORLD['y0']) / scale) + 3
    g = r.random((gh, gw))
    fx = (X - WORLD['x0']) / scale
    fy = (WORLD['y1'] - Y) / scale
    ix, iy = np.floor(fx).astype(int), np.floor(fy).astype(int)
    tx, ty = fx - ix, fy - iy
    tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
    a = g[iy, ix] * (1 - tx) + g[iy, ix + 1] * tx
    b = g[iy + 1, ix] * (1 - tx) + g[iy + 1, ix + 1] * tx
    return a * (1 - ty) + b * ty


def fbm(scale, octaves, seed, gain=.5):
    s, a, tot = 0, 1, 0
    for o in range(octaves):
        s = s + value_noise(scale / 2 ** o, seed + o) * a
        tot += a
        a *= gain
    return s / tot


def ridged(scale, octaves, seed):
    s, a, tot = 0, 1, 0
    for o in range(octaves):
        n = 1 - np.abs(value_noise(scale / 2 ** o, seed + 100 + o) * 2 - 1)
        s = s + n * n * a
        tot += a
        a *= .5
    return s / tot


def dist_to_polyline(pts):
    d = np.full(X.shape, 1e9)
    for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
        vx, vy = x1 - x0, y1 - y0
        L2 = vx * vx + vy * vy
        t = np.clip(((X - x0) * vx + (Y - y0) * vy) / L2, 0, 1)
        d = np.minimum(d, np.hypot(X - (x0 + t * vx), Y - (y0 + t * vy)))
    return d


# ---------------------------------------------------------------- kara / deniz
warp_x = (fbm(700, 5, 1) - .5) * 520 + (fbm(160, 3, 4) - .5) * 120
warp_y = (fbm(700, 5, 2) - .5) * 520 + (fbm(160, 3, 5) - .5) * 120
WX, WY = X + warp_x, Y + warp_y
L = np.full(X.shape, -1.0)
for cx, cy, rx, ry in LAND:
    L = np.maximum(L, 1 - ((WX - cx) / rx) ** 2 - ((WY - cy) / ry) ** 2)
L += (fbm(250, 3, 3) - .5) * .12

# ---------------------------------------------------------------- bölge ağırlıkları
names = [c['id'] for c in COUNTRIES]
weights = np.stack([np.exp(-((WX - c['x']) ** 2 + (WY - c['y']) ** 2) / (c['r'] ** 2) * 1.6) for c in COUNTRIES])
dom = np.argmax(weights, axis=0)
wsum = weights.sum(0) + 1e-6
mount = sum(weights[i] * c['mount'] for i, c in enumerate(COUNTRIES)) / wsum

# ---------------------------------------------------------------- yükseklik
hills = fbm(900, 5, 10)
ridge = ridged(1400, 6, 20)
detail = fbm(120, 3, 30)
land_h = 3 + np.clip(L, 0, .6) * 30 + (hills - .5) * 36 + detail * 6
land_h += mount ** 1.3 * (ridge ** 1.6) * 260
# çöl kumulları
desert_w = weights[names.index('wind')] / wsum
dunes = (np.abs(np.sin((X * .9 + Y * .4) / 38 + fbm(300, 2, 40) * 6)) ** 1.5) * 9
land_h += desert_w * dunes
# Yıldırım ülkesinde sivri kayalık sütunlar
light_w = weights[names.index('lightning')] / wsum
land_h += light_w * np.clip(ridged(420, 3, 50) - .55, 0, 1) ** 2 * 900
sea_h = np.minimum(L * 140 - 2, -2)
coast = smoothstep(-.02, .05, L)
h = sea_h * (1 - coast) + land_h * coast

# ---------------------------------------------------------------- nehirler
wet = np.zeros_like(h)
for pts in RIVERS:
    d = dist_to_polyline(pts)
    width = 16
    carve = 1 - smoothstep(width, width * 3.5, d)
    h = h * (1 - carve) + np.minimum(h, -2.5) * carve
    wet = np.maximum(wet, 1 - smoothstep(width, width * 6, d))

# ---------------------------------------------------------------- yollar
named = {v['id']: v for v in VILLAGES + LANDMARKS}
road = np.zeros_like(h)
for a, b in ROADS:
    A, B = named[a], named[b]
    # hafif kıvrımlı yol: orta noktayı kaydır
    mx, my = (A['x'] + B['x']) / 2, (A['y'] + B['y']) / 2
    nx, ny = -(B['y'] - A['y']), B['x'] - A['x']
    ln = math.hypot(nx, ny) or 1
    off = rng.uniform(-.12, .12) * math.hypot(B['x'] - A['x'], B['y'] - A['y'])
    pts = [(A['x'], A['y']), (mx + nx / ln * off, my + ny / ln * off), (B['x'], B['y'])]
    d = dist_to_polyline(pts)
    road = np.maximum(road, 1 - smoothstep(4, 9, d))

# ---------------------------------------------------------------- köy düzlükleri
for v in VILLAGES + LANDMARKS:
    d = np.hypot(X - v['x'], Y - v['y'])
    r = v['r']
    base = v.get('base')
    if base is None:
        m = d < r
        base = float(np.clip(np.median(h[m]), 4, 60)) if m.any() else 6.0
        v['base'] = base
    if v['id'] in ('valley_end', 'storm_canyon', 'sage_falls'):
        continue  # bunlar özel şekilde oyulur
    f = 1 - smoothstep(r * .85, r + 160, d)
    h = h * (1 - f) + base * f

# Sonun Vadisi: derin kanyon + şelale
ve = named['valley_end']
dx, dy = X - ve['x'], Y - ve['y']
canyon = (np.abs(dx) < 70) & (np.abs(dy) < 260)
cliff = 1 - smoothstep(40, 75, np.abs(dx))
h = np.where(np.abs(dy) < 300, h * (1 - cliff) + (np.where(dy > 60, 30, -6)) * cliff, h)
h = np.where((np.abs(dx) < 140) & (np.abs(dy) < 300) & (np.abs(dx) >= 60), np.maximum(h, 70), h)
# Gizli şelale: yüksek kayalık + gölet
sf = named['sage_falls']
d = np.hypot(X - sf['x'], Y - sf['y'])
h = np.where(d < 60, -3, h)
h = np.where((d >= 60) & (d < 160) & (Y > sf['y']), np.maximum(h, 55 * smoothstep(160, 60, d) + 8), h)

# kenarlar: dünya sınırında okyanus
edge = np.minimum.reduce([X - WORLD['x0'], WORLD['x1'] - X, Y - WORLD['y0'], WORLD['y1'] - Y])
h = np.where(edge < 220, np.minimum(h, -10 + edge * 0), h) * 1
h = h * smoothstep(0, 220, edge) + (-30) * (1 - smoothstep(0, 220, edge))

# ---------------------------------------------------------------- biyom & renk
biome = np.zeros(h.shape, dtype=np.uint8)
for i, c in enumerate(COUNTRIES):
    biome[dom == i] = BID[c['biome']]
slope = np.hypot(*np.gradient(h, R))
biome[(h < 2.5) & (h > -.5)] = BID['beach']
biome[h <= -.5] = BID['sea']
biome[(h > 170) & (biome != BID['sea'])] = BID['snow']
for v in VILLAGES:
    biome[np.hypot(X - v['x'], Y - v['y']) < v['r'] * .9] = BID['village']

PAL = {
    'sea': (40, 90, 130), 'beach': (222, 206, 160), 'forest': (78, 128, 52), 'desert': (226, 196, 136),
    'rain': (78, 98, 82), 'rock': (140, 124, 100), 'rice': (128, 168, 70), 'grass': (150, 182, 80),
    'snow': (236, 240, 245), 'mountain': (112, 118, 104), 'swamp': (78, 112, 88), 'village': (150, 160, 100),
    'road': (180, 154, 110),
}
wn = weights ** 3
wn = wn / (wn.sum(0) + 1e-9)
col = np.zeros(h.shape + (3,), dtype=np.float32)
for i, c in enumerate(COUNTRIES):
    col += wn[i][..., None] * np.array(PAL[c['biome']], dtype=np.float32)
for name in ('beach', 'sea', 'snow', 'village'):
    m = biome == BID[name]
    col[m] = PAL[name]
# yamaçlar kaya, yükseklik ile soğuk tonlar, gürültü ile canlılık
rock = smoothstep(.55, 1.1, slope)
col = col * (1 - rock[..., None]) + np.array([118, 110, 98]) * rock[..., None]
var = (fbm(60, 3, 70) - .5)[..., None]
col = col * (1 + var * .35)
col = col * (1 - (wet * .25)[..., None]) + np.array([60, 90, 60]) * (wet * .25)[..., None]
col = col * (1 - (road * .9)[..., None]) + np.array(PAL['road']) * (road * .9)[..., None]
col = np.clip(col, 0, 255).astype(np.uint8)

# ---------------------------------------------------------------- bitki örtüsü
# tipler: 0 geniş ağaç, 1 çam, 2 kuru ağaç, 3 kaktüs, 4 kaya, 5 dev ağaç, 6 bambu, 7 palmiye, 8 çalı
DENS = {'forest': (.0045, [0, 0, 0, 8, 6]), 'rain': (.002, [2, 2, 0, 8]), 'rock': (.0012, [4, 4, 1]),
        'rice': (.0008, [0, 8, 6]), 'grass': (.0010, [0, 8, 8, 8]), 'snow': (.0015, [1, 1, 4]),
        'mountain': (.0018, [1, 1, 4, 4]), 'swamp': (.0025, [2, 0, 8]), 'desert': (.00025, [3, 3, 4]),
        'beach': (.0005, [7, 8]), 'village': (0, []), 'sea': (0, []), 'road': (0, [])}
veg = []
area = R * R
for name, (dens, types) in DENS.items():
    if not dens:
        continue
    m = (biome == BID[name]) & (road < .2) & (h > .8) & (slope < .9) & (wet < .5)
    iy, ix = np.nonzero(m)
    keep = rng.random(len(ix)) < dens * area * (.4 + 1.2 * fbm(400, 2, 90)[iy, ix])
    iy, ix = iy[keep], ix[keep]
    for a, b in zip(iy, ix):
        t = types[rng.integers(len(types))]
        x = xs[b] + rng.uniform(-R / 2, R / 2)
        y = ys[a] + rng.uniform(-R / 2, R / 2)
        veg.append((x, float(h[a, b]), y, rng.uniform(.75, 1.35), rng.uniform(0, 6.283), t))
# Ölüm Ormanı: dev ağaçlar
fd = named['forest_death']
for _ in range(140):
    ang, rad = rng.uniform(0, 6.283), math.sqrt(rng.uniform(0, 1)) * (fd['r'] - 15)
    x, y = fd['x'] + rad * math.cos(ang), fd['y'] + rad * math.sin(ang)
    veg.append((x, fd['base'], y, rng.uniform(.8, 1.3), rng.uniform(0, 6.283), 5))
# Nara ormanı yoğun
nf = named['nara_forest']
for _ in range(500):
    ang, rad = rng.uniform(0, 6.283), math.sqrt(rng.uniform(0, 1)) * nf['r']
    veg.append((nf['x'] + rad * math.cos(ang), nf['base'], nf['y'] + rad * math.sin(ang), rng.uniform(.9, 1.3),
                rng.uniform(0, 6.283), 0))
veg = np.array(veg, dtype=np.float32)
print('vegetation', len(veg))

# ---------------------------------------------------------------- harita görseli
shade = np.clip(1 + (np.gradient(h, axis=1) - np.gradient(h, axis=0)) * .09, .5, 1.5)
mp = col.astype(np.float32) * shade[..., None]
seaw = h < 0
depth = np.clip(-h / 60, 0, 1)
mp[seaw] = (np.array([70, 140, 190]) * (1 - depth[seaw, None]) + np.array([30, 70, 120]) * depth[seaw, None])
mp = np.clip(mp, 0, 255).astype(np.uint8)
# kağıt dokusu tonu
paper = np.array([240, 228, 200], dtype=np.float32)
mp = (mp.astype(np.float32) * .82 + paper * .18).astype(np.uint8)

# ---------------------------------------------------------------- yaz
h.astype(np.float32).tofile(os.path.join(OUT, 'height.bin'))
Image.fromarray(col).save(os.path.join(OUT, 'albedo.png'))
Image.fromarray(np.dstack([biome, (road * 255).astype(np.uint8), (wet * 255).astype(np.uint8)])).save(
    os.path.join(OUT, 'biome.png'))
Image.fromarray(mp).resize((W // 2, H // 2), Image.LANCZOS).save(os.path.join(OUT, 'map.png'))
veg.tofile(os.path.join(OUT, 'veg.bin'))
info = dict(world=dict(WORLD, w=W, h=H), countries=COUNTRIES, villages=VILLAGES, landmarks=LANDMARKS,
            biomes=BIOMES, roads=ROADS)
with open(os.path.join(OUT, 'world.json'), 'w', encoding='utf8') as f:
    json.dump(info, f, ensure_ascii=False, indent=1)
print('min/max h', float(h.min()), float(h.max()))
