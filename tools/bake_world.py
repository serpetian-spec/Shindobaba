"""Shinobi dünyasını fırınlar -> godot/data/world/  (v3: ~77 x 64 km akışlı dünya)
  height.bin   : float32 MAKRO yükseklik (W x H), 32 m/piksel. İnce ayrıntı oyunda deterministik gürültüyle eklenir
                 (Game.terrain_height ve shaders/world_height.gdshaderinc aynı formülü kullanır).
  biome.png    : R=biyom id, G=yol (kaba), B=nehir/ıslak, A=ayrıntı genliği (0 düz köy/yol .. 1 vahşi doğa)
  shape.png    : R=sırt karışımı, G=basamaklı yar (mesa), B=kum tepesi, A=Ateş kaya çıkıntısı
  albedo.png   : arazi rengi (32 m/piksel)
  roads.json   : yol ve cadde çoklu çizgileri (yerel yol dokusu ve trafik için)
  rivers.json  : nehir çizgileri
  features.json: doğal yapılar + yol kenarı süsleri (oyunda bölge bölge akışla kurulur)
  pois.json    : vahşi doğa noktaları (mezra, han, haydut kampı, harabe, tapınak, kaplıca, iskele, karakol, anıt)
  patch_*.bin  : özel yerlerin 4 m/piksel yüksek çözünürlüklü yamaları (Sonun Vadisi, Gizli Şelale, Hokage Kayası)
  map.png      : dünya haritası
  world.json   : köyler, ülkeler, yerler, yama listesi
"""
import os
import sys
import json
import math
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from world_layout import WORLD, LAND, COUNTRIES, VILLAGES, LANDMARKS, ROADS, RIVERS, SCALE

OUT = os.path.join(os.path.dirname(__file__), '..', 'godot', 'data', 'world')
os.makedirs(OUT, exist_ok=True)
R = WORLD['res']
W = int((WORLD['x1'] - WORLD['x0']) / R)
H = int((WORLD['y1'] - WORLD['y0']) / R)
xs = (WORLD['x0'] + (np.arange(W) + .5) * R).astype(np.float64)
ys = (WORLD['y1'] - (np.arange(H) + .5) * R).astype(np.float64)  # satır 0 = kuzey
X, Y = np.meshgrid(xs, ys)
rng = np.random.default_rng(42)
print('grid', W, H)
DETAIL_MAX = 26.0  # ayrıntı gürültüsünün en büyük genliği (m), oyundaki formülle aynı

BIOMES = ['sea', 'beach', 'forest', 'desert', 'rain', 'rock', 'rice', 'grass', 'snow', 'mountain', 'swamp', 'village', 'road',
          'village_sand', 'village_stone', 'village_snow']
BID = {b: i for i, b in enumerate(BIOMES)}


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def value_noise(scale, seed, XX=None, YY=None):
    """Bilinear ara değerli rastgele ızgara gürültüsü (0..1)."""
    XX = X if XX is None else XX
    YY = Y if YY is None else YY
    r = np.random.default_rng(seed)
    gw, gh = int((WORLD['x1'] - WORLD['x0']) / scale) + 3, int((WORLD['y1'] - WORLD['y0']) / scale) + 3
    g = r.random((gh, gw))
    fx = np.clip((XX - WORLD['x0']) / scale, 0, gw - 2.001)
    fy = np.clip((WORLD['y1'] - YY) / scale, 0, gh - 2.001)
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


def dist_to_polyline(pts, XX=None, YY=None, reach=600.0):
    """Çoklu çizgiye uzaklık. Izgara için yalnızca her parçanın çevresindeki pencerede hesaplanır (reach dışı = 1e12)."""
    if XX is not None:
        d = np.full(XX.shape, 1e12)
        for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
            vx, vy = x1 - x0, y1 - y0
            L2 = vx * vx + vy * vy or 1.0
            t = np.clip(((XX - x0) * vx + (YY - y0) * vy) / L2, 0, 1)
            d = np.minimum(d, np.hypot(XX - (x0 + t * vx), YY - (y0 + t * vy)))
        return d
    d = np.full(X.shape, 1e12)
    for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
        c0 = int(max(0, (min(x0, x1) - reach - WORLD['x0']) / R)); c1 = int(min(W, (max(x0, x1) + reach - WORLD['x0']) / R + 1))
        r0 = int(max(0, (WORLD['y1'] - max(y0, y1) - reach) / R)); r1 = int(min(H, (WORLD['y1'] - min(y0, y1) + reach) / R + 1))
        if c1 <= c0 or r1 <= r0:
            continue
        sx, sy = X[r0:r1, c0:c1], Y[r0:r1, c0:c1]
        vx, vy = x1 - x0, y1 - y0
        L2 = vx * vx + vy * vy or 1.0
        t = np.clip(((sx - x0) * vx + (sy - y0) * vy) / L2, 0, 1)
        d[r0:r1, c0:c1] = np.minimum(d[r0:r1, c0:c1], np.hypot(sx - (x0 + t * vx), sy - (y0 + t * vy)))
    return d


# ---------------------------------------------------------------- kara / deniz
S = SCALE
warp_x = (fbm(700 * S, 5, 1) - .5) * 520 * S + (fbm(160 * S, 3, 4) - .5) * 120 * S
warp_y = (fbm(700 * S, 5, 2) - .5) * 520 * S + (fbm(160 * S, 3, 5) - .5) * 120 * S
WX, WY = X + warp_x, Y + warp_y
L = np.full(X.shape, -1.0)
for cx, cy, rx, ry in LAND:
    L = np.maximum(L, 1 - ((WX - cx) / rx) ** 2 - ((WY - cy) / ry) ** 2)
L += (fbm(250 * S, 3, 3) - .5) * .12

# ---------------------------------------------------------------- bölge ağırlıkları
names = [c['id'] for c in COUNTRIES]
weights = np.stack([np.exp(-((WX - c['x']) ** 2 + (WY - c['y']) ** 2) / (c['r'] ** 2) * 1.6) for c in COUNTRIES])
dom = np.argmax(weights, axis=0)
wsum = weights.sum(0) + 1e-6
mount = sum(weights[i] * c['mount'] for i, c in enumerate(COUNTRIES)) / wsum


def W_(cid):
    return weights[names.index(cid)] / wsum


# ---------------------------------------------------------------- makro yükseklik (büyük şekiller)
hills = fbm(5000, 5, 10)
ridge = ridged(9000, 6, 20)
mdet = fbm(1400, 3, 30)
land_h = 4 + np.clip(L, 0, .6) * 45 + (hills - .5) * 130 + mdet * 30
land_h += mount ** 1.3 * (ridge ** 1.6) * 560
fire_w = W_('fire') + W_('waves') * .5
land_h += fire_w * (fbm(3200, 3, 12) - .5) * 60
light_w = W_('lightning')
land_h += light_w * np.clip(ridged(2600, 3, 50) - .55, 0, 1) ** 2 * 1600
sea_h = np.minimum(L * 140 - 2, -2)
coast = smoothstep(-.02, .05, L)
h = sea_h * (1 - coast) + land_h * coast

# ---------------------------------------------------------------- şekil ağırlıkları (oyunda ayrıntıya uygulanır)
rock_mix = np.clip(W_('earth') + W_('stone') + W_('rivers') + W_('north') + W_('lightning') + W_('iron') * .7 + W_('frost') * .6, 0, 1)
mesa_w = np.clip(W_('earth') + W_('stone') + W_('rivers') + W_('north') * .8 + W_('wind') * .7, 0, 1) * smoothstep(.42, .55, fbm(5200, 3, 77))
dune_w = W_('wind') * (1 - mesa_w)
out_w = fire_w * smoothstep(.74, .8, fbm(6000, 2, 88))

# ---------------------------------------------------------------- nehirler
wet = np.zeros_like(h)
for pts in RIVERS:
    d = dist_to_polyline(pts)
    width = 45
    carve = 1 - smoothstep(width, width * 3, d)
    h = h * (1 - carve) + np.minimum(h, -3.0) * carve
    wet = np.maximum(wet, 1 - smoothstep(width, width * 4, d))

# ---------------------------------------------------------------- yollar
named = {v['id']: v for v in VILLAGES + LANDMARKS}
road_lines = []   # [{'a','b','kind','pts'}]
gates = {v['id']: [] for v in VILLAGES}
KONOHA_GATE_ANGLES = [180.0, 100.0, 260.0]


def _compass(dx, dy):
    return math.degrees(math.atan2(dx, dy)) % 360.0


def _polar(V, ang, rad):
    a = math.radians(ang)
    return (V['x'] + math.sin(a) * rad, V['y'] + math.cos(a) * rad)


for a, b in ROADS:
    A, B = named[a], named[b]
    dx, dy = B['x'] - A['x'], B['y'] - A['y']
    dist = math.hypot(dx, dy)
    nx, ny = -dy / dist, dx / dist
    # kıvrımlı yol: 5 ara nokta, yumuşak sapma
    mids = []
    for k in range(1, 6):
        t = k / 6
        off = (rng.uniform(-.06, .06) + math.sin(t * math.pi) * rng.uniform(-.05, .05)) * dist
        mids.append((A['x'] + dx * t + nx * off, A['y'] + dy * t + ny * off))
    pts = [(A['x'], A['y'])] + mids + [(B['x'], B['y'])]
    # uçlar: köyde kapıdan çık (Konoha'da en yakın sabit kapı)
    for end in (0, 1):
        V = A if end == 0 else B
        nxt = pts[1] if end == 0 else pts[-2]
        ang = _compass(nxt[0] - V['x'], nxt[1] - V['y'])
        if V['id'] in gates:
            if V['id'] == 'konoha':
                ang = min(KONOHA_GATE_ANGLES, key=lambda k: abs((ang - k + 180) % 360 - 180))
            inner = _polar(V, ang, V['r'] * .3)
            gate = _polar(V, ang, V['r'])
            outer = _polar(V, ang, V['r'] + 260)
            way = [inner, gate, outer]
            if end == 0:
                pts = [pts[0]] + way + pts[1:]
            else:
                pts = pts[:-1] + way[::-1] + [pts[-1]]
            if not any(abs((ang - q + 180) % 360 - 180) < 12 for q in gates[V['id']]):
                gates[V['id']].append(round(ang, 1))
    road_lines.append(dict(a=a, b=b, kind='road', pts=[(round(x, 1), round(y, 1)) for x, y in pts]))
for v in VILLAGES:
    v['gates'] = gates[v['id']]
# köy içi caddeler: her kapıdan merkeze ana cadde + Konoha'da ızgara
for v in VILLAGES:
    r = v['r']
    for g in v['gates']:
        road_lines.append(dict(a=v['id'], b=v['id'], kind='street', pts=[_polar(v, g, r), (v['x'], v['y'])]))
    if v['id'] == 'konoha':
        for rn in (-.62, -.3, 0.0, .28, .52):
            hw_ = math.sqrt(max(1 - rn * rn, 0)) * r * .92
            road_lines.append(dict(a='konoha', b='konoha', kind='street',
                                   pts=[(v['x'] - hw_, v['y'] + rn * r), (v['x'] + hw_, v['y'] + rn * r)]))
        for rx in (-.5, -.22, .22, .5):
            hh_ = math.sqrt(max(1 - rx * rx, 0)) * r * .85
            road_lines.append(dict(a='konoha', b='konoha', kind='street',
                                   pts=[(v['x'] + rx * r, v['y'] - hh_), (v['x'] + rx * r, v['y'] + min(hh_, r * .7))]))
road = np.zeros_like(h)
for rl in road_lines:
    d = dist_to_polyline(rl['pts'])
    road = np.maximum(road, 1 - smoothstep(6, 40, d))

# ---------------------------------------------------------------- köy ve yer düzlükleri
for v in VILLAGES + LANDMARKS:
    d = np.hypot(X - v['x'], Y - v['y'])
    r = v['r']
    base = v.get('base')
    if base is None:
        m = d < r
        base = float(np.clip(np.median(h[m]), 4, 80)) if m.any() else 6.0
        v['base'] = round(base, 1)
    if v['id'] in ('valley_end', 'sage_falls'):
        continue  # yüksek çözünürlüklü yama
    f = 1 - smoothstep(r * .9, r + 500, d)
    h = h * (1 - f) + base * f

# Hokage Kayası: Konoha'nın kuzey kenarında 160 m dik yar ve arkasında dağ (yama + makro)
KV = named['konoha']
HOKAGE = dict(y=KV['y'] + KV['r'] * .78, top=KV['base'] + 165.0, x0=KV['x'] - KV['r'] * .55, x1=KV['x'] + KV['r'] * .55)
KV['hokage_rock'] = HOKAGE


def hokage_height(XX, YY, base_h):
    """Konoha kuzeyinde dik kaya yüzü + arkada yükselen dağ."""
    dy = YY - HOKAGE['y']
    along = np.clip((np.abs(XX - KV['x']) - KV['r'] * .55) / (KV['r'] * .5), 0, 1)
    wall = smoothstep(-6, 22, dy) * (1 - along ** 2)
    rise = smoothstep(0, 1800, dy) * 120 * (1 - along)
    top = HOKAGE['top'] + rise
    return base_h * (1 - wall) + np.maximum(base_h, top) * wall


m_hk = (np.abs(X - KV['x']) < KV['r'] * 1.3) & (Y > HOKAGE['y'] - 200) & (Y < HOKAGE['y'] + 2600)
h[m_hk] = hokage_height(X[m_hk], Y[m_hk], h[m_hk])

# Sonun Vadisi: dev kanyon, iki yanında 130 m kayalık, kuzeyde 95 m şelale basamağı
VE = named['valley_end']
VE_SPEC = dict(rim=130.0, river=-3.0, upper=96.0, fall_dy=520.0, half=95.0, plat_x=150.0)
VE['base'] = VE_SPEC['rim']
VE['spec'] = VE_SPEC


def valley_height(XX, YY, around):
    dx, dy = XX - VE['x'], YY - VE['y']
    ax = np.abs(dx)
    wall = smoothstep(VE_SPEC['half'], VE_SPEC['half'] + 30, ax)
    floor_h = np.where(dy > VE_SPEC['fall_dy'], VE_SPEC['upper'], VE_SPEC['river'])
    floor_h = np.where((dy > VE_SPEC['fall_dy'] - 4) & (dy < VE_SPEC['fall_dy'] + 4), VE_SPEC['upper'] * smoothstep(VE_SPEC['fall_dy'] - 4, VE_SPEC['fall_dy'] + 4, dy) + VE_SPEC['river'] * (1 - smoothstep(VE_SPEC['fall_dy'] - 4, VE_SPEC['fall_dy'] + 4, dy)), floor_h)
    # üst nehir de dar bir oluk (şelaleden önce)
    floor_h = np.where((dy > VE_SPEC['fall_dy']) & (ax < 60), VE_SPEC['upper'] - 4, floor_h)
    v = floor_h * (1 - wall) + VE_SPEC['rim'] * wall
    blend = 1 - smoothstep(VE['r'] * .8, VE['r'] + 300, np.maximum(ax * 1.0, np.abs(dy) * .8))
    return around * (1 - blend) + v * blend


m_ve = (np.abs(X - VE['x']) < VE['r'] + 400) & (np.abs(Y - VE['y']) < VE['r'] * 1.25 + 400)
h[m_ve] = valley_height(X[m_ve], Y[m_ve], h[m_ve])
# Gizli şelale: yüksek kayalık + gölet
SF = named['sage_falls']


def sage_height(XX, YY, around):
    d = np.hypot(XX - SF['x'], YY - SF['y'])
    cliff = np.where(YY > SF['y'], 110 * smoothstep(320, 150, d) + 10, 0)
    pond = np.where(d < 140, -4.0, around)
    v = np.where(d < 140, pond, np.maximum(around, cliff))
    blend = 1 - smoothstep(SF['r'], SF['r'] + 250, d)
    return around * (1 - blend) + v * blend


m_sf = np.hypot(X - SF['x'], Y - SF['y']) < SF['r'] + 300
h[m_sf] = sage_height(X[m_sf], Y[m_sf], h[m_sf])

# kenarlar: dünya sınırında okyanus
edge = np.minimum.reduce([X - WORLD['x0'], WORLD['x1'] - X, Y - WORLD['y0'], WORLD['y1'] - Y])
h = h * smoothstep(0, 2200, edge) + (-30) * (1 - smoothstep(0, 2200, edge))

# ---------------------------------------------------------------- biyom
biome = np.zeros(h.shape, dtype=np.uint8)
for i, c in enumerate(COUNTRIES):
    biome[dom == i] = BID[c['biome']]
slope = np.hypot(*np.gradient(h, R))
biome[(h < 2.5) & (h > -.5)] = BID['beach']
biome[h <= -.5] = BID['sea']
biome[(h > 470) & (biome != BID['sea'])] = BID['snow']
CBIO = {c['id']: c['biome'] for c in COUNTRIES}
VILLAGE_BIOME = {}
for v in VILLAGES:
    cb = CBIO.get(v.get('country', ''), 'forest')
    vb = {'desert': 'village_sand', 'rock': 'village_stone', 'mountain': 'village_stone', 'swamp': 'village_stone',
          'snow': 'village_snow'}.get(cb, 'village')
    VILLAGE_BIOME[v['id']] = BID[vb]
    v['ground'] = BID[vb]
    biome[np.hypot(X - v['x'], Y - v['y']) < v['r'] * .95] = BID[vb]

# ---------------------------------------------------------------- ayrıntı genliği (A kanalı)
AMP = {'sea': 0, 'beach': .1, 'forest': 1.0, 'desert': .45, 'rain': .45, 'rock': .95, 'rice': .3, 'grass': .55,
       'snow': .85, 'mountain': 1.0, 'swamp': .25, 'village': 0, 'road': 0, 'village_sand': 0, 'village_stone': 0, 'village_snow': 0}
wn = weights ** 3
wn = wn / (wn.sum(0) + 1e-9)
amp = np.zeros_like(h)
for i, c in enumerate(COUNTRIES):
    amp += wn[i] * AMP[c['biome']]
amp *= smoothstep(-.5, 6, h)
vm = np.zeros_like(h)
for v in VILLAGES + LANDMARKS:
    d = np.hypot(X - v['x'], Y - v['y'])
    k = 1 - smoothstep(v['r'] * .95, v['r'] + 450, d)
    if v.get('arena'):
        k *= .85
    elif v['id'] in ('forest_death', 'nara_forest', 'storm_canyon', 'hideout', 'bandit_camp', 'border_post'):
        k *= .5
    vm = np.maximum(vm, k)
amp *= 1 - vm
amp *= 1 - .9 * road
amp *= 1 - wet
amp = np.clip(amp, 0, 1)

# ---------------------------------------------------------------- renk
PAL = {
    'sea': (30, 95, 150), 'beach': (238, 214, 158), 'forest': (72, 132, 58), 'desert': (232, 196, 132),
    'rain': (66, 112, 78), 'rock': (156, 128, 94), 'rice': (112, 166, 70), 'grass': (120, 172, 74),
    'snow': (236, 242, 250), 'mountain': (120, 130, 104), 'swamp': (64, 124, 86), 'village': (108, 158, 74),
    'road': (196, 152, 102), 'village_sand': (216, 182, 132), 'village_stone': (150, 146, 136), 'village_snow': (226, 232, 240),
}
col = np.zeros(h.shape + (3,), dtype=np.float32)
for i, c in enumerate(COUNTRIES):
    col += wn[i][..., None] * np.array(PAL[c['biome']], dtype=np.float32)
for name in ('beach', 'sea', 'snow', 'village', 'village_sand', 'village_stone', 'village_snow'):
    m = biome == BID[name]
    col[m] = PAL[name]
rock = smoothstep(.35, .8, slope)
col = col * (1 - rock[..., None]) + np.array([118, 110, 98]) * rock[..., None]
var = (fbm(900, 3, 70) - .5)[..., None]
col = col * (1 + var * .3)
col = col * (1 - (wet * .25)[..., None]) + np.array([60, 90, 60]) * (wet * .25)[..., None]
col = np.clip(col, 0, 255).astype(np.uint8)


# ---------------------------------------------------------------- yardımcılar (nokta sorguları)
def cell(x, y):
    ix_, iy_ = int((x - WORLD['x0']) / R), int((WORLD['y1'] - y) / R)
    if 0 <= ix_ < W and 0 <= iy_ < H:
        return iy_, ix_
    return None


def hat(x, y):
    c = cell(x, y)
    if c is None:
        return -50.0, 0, 0.0, 0.0, 0.0
    return float(h[c]), int(biome[c]), float(wet[c]), float(road[c]), float(slope[c])


def near_village(x, y, pad):
    for v in VILLAGES + LANDMARKS:
        if math.hypot(x - v['x'], y - v['y']) < v['r'] + pad:
            return True
    return False


def country_at(x, y):
    c = cell(x, y)
    return names[int(dom[c])] if c else 'fire'


# ---------------------------------------------------------------- özellikler (oyunda bölge bölge akışla kurulur)
features = []
for cid, n, kind, hr, rr in [('earth', 1600, 'pillar', (40, 140), (8, 26)), ('stone', 500, 'pillar', (30, 90), (8, 20)),
                             ('rivers', 450, 'pillar', (25, 70), (6, 16)), ('wind', 500, 'mesa', (25, 70), (25, 70)),
                             ('lightning', 1200, 'spire', (80, 260), (8, 22)), ('north', 600, 'pillar', (30, 100), (8, 20)),
                             ('iron', 300, 'spire', (40, 120), (6, 14))]:
    c = COUNTRIES[names.index(cid)]
    k = 0
    tries = 0
    while k < n and tries < n * 20:
        tries += 1
        ang, rad = rng.uniform(0, 6.283), math.sqrt(rng.uniform(0, 1)) * c['r']
        x, y = c['x'] + rad * math.cos(ang), c['y'] + rad * math.sin(ang)
        g, b, wt, rd, sl = hat(x, y)
        if g < 2 or wt > .2 or rd > .05 or near_village(x, y, 200) or country_at(x, y) != cid:
            continue
        features.append(dict(t=kind, x=round(x, 1), y=round(y, 1), g=round(g, 1), h=round(rng.uniform(*hr), 1),
                             r=round(rng.uniform(*rr), 1), yaw=round(rng.uniform(0, 360), 1)))
        k += 1
for cid, n in [('wind', 70), ('earth', 70), ('rivers', 30), ('north', 25)]:
    c = COUNTRIES[names.index(cid)]
    for _ in range(n):
        ang, rad = rng.uniform(0, 6.283), math.sqrt(rng.uniform(0, 1)) * c['r'] * .8
        x, y = c['x'] + rad * math.cos(ang), c['y'] + rad * math.sin(ang)
        g, b, wt, rd, sl = hat(x, y)
        if g > 2 and not near_village(x, y, 300) and rd < .05:
            features.append(dict(t='arch', x=round(x, 1), y=round(y, 1), g=round(g, 1), h=round(rng.uniform(30, 70), 1),
                                 r=round(rng.uniform(30, 60), 1), yaw=round(rng.uniform(0, 180), 1)))
# yol kenarı: fener çiftleri, tapınak/torii/jizo/tabela, köprüler
for rl in road_lines:
    if rl['kind'] != 'road':
        continue
    pts = rl['pts']
    seg = []
    for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
        L_ = math.hypot(x1 - x0, y1 - y0)
        n = max(1, int(L_ / 20))
        for i in range(n):
            t = i / n
            seg.append((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, math.degrees(math.atan2(x1 - x0, y1 - y0))))
    dist = 0
    last_bridge = None
    for i, (x, y, yaw) in enumerate(seg):
        dist += 20
        g, b, wt, rd, sl = hat(x, y)
        if near_village(x, y, 60):
            continue
        if wt > .5 and g < 1.5:
            if last_bridge is None or math.hypot(last_bridge[0] - x, last_bridge[1] - y) > 200:
                features.append(dict(t='bridge', x=round(x, 1), y=round(y, 1), g=0, h=0, r=110, yaw=round(yaw, 1)))
                last_bridge = (x, y)
            continue
        if g < 1:
            continue
        if dist % 240 == 0:
            for sd in (-1, 1):
                ox, oy = math.cos(math.radians(yaw)) * 9 * sd, -math.sin(math.radians(yaw)) * 9 * sd
                features.append(dict(t='lantern', x=round(x + ox, 1), y=round(y + oy, 1), g=round(hat(x + ox, y + oy)[0], 1), h=0, r=0, yaw=round(yaw, 1)))
        if dist % 1400 == 700:
            kind = ['shrine', 'torii', 'jizo', 'sign', 'shrine', 'jizo'][rng.integers(6)]
            sd = 1 if rng.random() < .5 else -1
            ox, oy = math.cos(math.radians(yaw)) * 16 * sd, -math.sin(math.radians(yaw)) * 16 * sd
            if kind == 'torii':
                ox, oy = 0, 0
            features.append(dict(t=kind, x=round(x + ox, 1), y=round(y + oy, 1), g=round(hat(x + ox, y + oy)[0], 1), h=0, r=0, yaw=round(yaw, 1)))
# pirinç tarlaları
for vid, rr, n in [('oto', 1600, 260), ('konoha', 4200, 380), ('kusa', 1500, 140), ('yu', 1300, 90), ('tani', 1200, 80), ('nami', 1200, 80)]:
    V = named[vid]
    for _ in range(n):
        ang, rad = rng.uniform(0, 6.283), rng.uniform(V['r'] + 150, V['r'] + rr)
        x, y = V['x'] + rad * math.cos(ang), V['y'] + rad * math.sin(ang)
        g, b, wt, rd, sl = hat(x, y)
        if g < 2 or g > 90 or rd > .05 or wt > .3 or near_village(x, y, 60) or sl > .12:
            continue
        features.append(dict(t='paddy', x=round(x, 1), y=round(y, 1), g=round(g, 1), h=0, r=round(rng.uniform(22, 40), 1), yaw=round(rng.uniform(0, 90), 1)))
print('features', len(features))

# ---------------------------------------------------------------- vahşi doğa noktaları (POI)
pois = []
POI_NAMES = {
    'hamlet': ['Kiraz Mezrası', 'Pirinç Çiftliği', 'Çam Köyü', 'Değirmen Mezrası', 'Söğüt Köyü', 'Bambu Mezrası', 'Taş Köprü Köyü', 'Çay Bahçesi'],
    'inn': ['Yolcu Hanı', 'Ay Işığı Hanı', 'Kervan Durağı', 'Sıcak Çorba Hanı', 'Yorgun Ninja Hanı'],
    'camp': ['Haydut Kampı', 'Kaçak Ninja Kampı', 'Soyguncu İni'],
    'ruin': ['Eski Tapınak Harabesi', 'Yıkık Kale', 'Unutulmuş Sığınak', 'Savaş Harabeleri'],
    'shrine': ['Tepe Tapınağı', 'Rüzgar Sunağı', 'Ataların Mabedi'],
    'onsen': ['Kaplıca', 'Buharlı Pınar', 'Dağ Kaplıcası'],
    'dock': ['Balıkçı İskelesi', 'Kıyı İskelesi'],
    'checkpoint': ['Sınır Karakolu'],
    'tower': ['Gözetleme Kulesi'],
    'monument': ['Dev Ağaç', 'Taş Muhafız', 'Kızıl Pagoda', 'Büyük Torii'],
}


def add_poi(t, x, y, yaw=0.0, extra=None):
    g, b, wt, rd, sl = hat(x, y)
    p = dict(id='%s_%d' % (t, len(pois)), t=t, x=round(x, 1), y=round(y, 1), g=round(g, 1), yaw=round(yaw, 1),
             name=POI_NAMES[t][rng.integers(len(POI_NAMES[t]))], country=country_at(x, y))
    if extra:
        p.update(extra)
    pois.append(p)


def far_from_pois(x, y, d):
    return all(math.hypot(p['x'] - x, p['y'] - y) > d for p in pois)


# yol boyunca: mezralar, hanlar; ülke sınırı geçişlerinde karakol
for rl in road_lines:
    if rl['kind'] != 'road':
        continue
    pts = rl['pts']
    tot = 0.0
    prev_country = None
    next_stop = rng.uniform(2500, 4500)
    for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
        L_ = math.hypot(x1 - x0, y1 - y0)
        yaw = math.degrees(math.atan2(x1 - x0, y1 - y0))
        n = max(1, int(L_ / 50))
        for i in range(n):
            t = i / n
            x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            tot += L_ / n
            g, b, wt, rd, sl = hat(x, y)
            cid = country_at(x, y)
            if prev_country and cid != prev_country and g > 2 and not near_village(x, y, 400) and far_from_pois(x, y, 800):
                add_poi('checkpoint', x, y, yaw, dict(between=[prev_country, cid]))
            prev_country = cid
            if tot >= next_stop:
                next_stop = tot + rng.uniform(2800, 5200)
                kind = 'inn' if rng.random() < .4 else 'hamlet'
                sd = 1 if rng.random() < .5 else -1
                off = 40 if kind == 'inn' else rng.uniform(140, 260)
                px, py = x + math.cos(math.radians(yaw)) * off * sd, y - math.sin(math.radians(yaw)) * off * sd
                pg, pb, pw, prd, psl = hat(px, py)
                if pg > 2 and pw < .3 and not near_village(px, py, 500) and far_from_pois(px, py, 900) and psl < .25:
                    add_poi(kind, px, py, yaw)
# haydut kampları, harabeler, tapınaklar, kaplıcalar, anıtlar: vahşi doğada
for t, n, cond in [('camp', 70, lambda g, b, rd, sl: rd < .02 and sl < .25),
                   ('ruin', 60, lambda g, b, rd, sl: sl < .3),
                   ('shrine', 50, lambda g, b, rd, sl: g > 40 and sl < .35),
                   ('onsen', 24, lambda g, b, rd, sl: b in (BID['mountain'], BID['rock'], BID['snow'], BID['grass']) and sl < .3),
                   ('monument', 30, lambda g, b, rd, sl: sl < .2),
                   ('tower', 40, lambda g, b, rd, sl: g > 20 and sl < .3)]:
    k = tries = 0
    while k < n and tries < n * 60:
        tries += 1
        x = rng.uniform(WORLD['x0'] + 3000, WORLD['x1'] - 3000)
        y = rng.uniform(WORLD['y0'] + 3000, WORLD['y1'] - 3000)
        g, b, wt, rd, sl = hat(x, y)
        if g < 3 or wt > .1 or near_village(x, y, 900) or not far_from_pois(x, y, 1500):
            continue
        if t == 'onsen' and not (country_at(x, y) in ('hotwater', 'frost', 'lightning', 'earth', 'iron', 'fire') ):
            continue
        if not cond(g, b, rd, sl):
            continue
        add_poi(t, x, y, rng.uniform(0, 360))
        k += 1
# kıyı iskeleleri: kumsal pikselleri
beach_idx = np.argwhere(biome == BID['beach'])
rng.shuffle(beach_idx)
k = 0
for iy_, ix_ in beach_idx:
    if k >= 30:
        break
    x, y = xs[ix_], ys[iy_]
    if near_village(x, y, 900) or not far_from_pois(x, y, 2500):
        continue
    # denize bakan yön: en derin komşuya doğru
    best, by = 0, 0.0
    for a in range(0, 360, 30):
        sx, sy = x + math.sin(math.radians(a)) * 200, y + math.cos(math.radians(a)) * 200
        gg = hat(sx, sy)[0]
        if gg < best:
            best, by = gg, a
    if best < -1:
        add_poi('dock', x, y, by)
        k += 1
print('pois', len(pois))

# ---------------------------------------------------------------- yüksek çözünürlüklü yamalar (4 m)
PR = 4.0
patches = []


def make_patch(pid, cx, cy, half, fn):
    n = int(half * 2 / PR)
    pxs = cx - half + (np.arange(n) + .5) * PR
    pys = cy + half - (np.arange(n) + .5) * PR
    PX, PY = np.meshgrid(pxs, pys)
    # çevre: makro yüksekliğin bilinear örneği
    fx = np.clip((PX - WORLD['x0']) / R - .5, 0, W - 1.001)
    fy = np.clip((WORLD['y1'] - PY) / R - .5, 0, H - 1.001)
    ix, iy = np.floor(fx).astype(int), np.floor(fy).astype(int)
    tx, ty = fx - ix, fy - iy
    ix1, iy1 = np.minimum(ix + 1, W - 1), np.minimum(iy + 1, H - 1)
    around = (h[iy, ix] * (1 - tx) + h[iy, ix1] * tx) * (1 - ty) + (h[iy1, ix] * (1 - tx) + h[iy1, ix1] * tx) * ty
    ph = fn(PX, PY, around).astype(np.float32)
    ph.tofile(os.path.join(OUT, 'patch_%s.bin' % pid))
    patches.append(dict(id=pid, x0=round(cx - half, 1), y1=round(cy + half, 1), size=half * 2, n=n, res=PR, fade=200.0))


make_patch('valley_end', VE['x'], VE['y'], 1400, valley_height)
make_patch('sage_falls', SF['x'], SF['y'], 700, sage_height)
make_patch('hokage', KV['x'], HOKAGE['y'] + 500, 1600, lambda XX, YY, a: hokage_height(XX, YY, np.where((np.abs(XX - KV['x']) < KV['r'] * .6) & (YY < HOKAGE['y'] + 30), np.minimum(a, KV['base']), a)))
print('patches', [p['id'] for p in patches])

# ---------------------------------------------------------------- harita görseli
shade = np.clip(1 + (np.gradient(h, axis=1) - np.gradient(h, axis=0)) * .02, .5, 1.5)
mp = col.astype(np.float32) * shade[..., None]
seaw = h < 0
depth = np.clip(-h / 60, 0, 1)
mp[seaw] = (np.array([70, 140, 190]) * (1 - depth[seaw, None]) + np.array([30, 70, 120]) * depth[seaw, None])
paper = np.array([240, 228, 200], dtype=np.float32)
mp = np.clip(mp * .82 + paper * .18, 0, 255).astype(np.uint8)
mimg = Image.fromarray(mp).resize((W // 2, H // 2), Image.LANCZOS)
dr = ImageDraw.Draw(mimg)


def to_mpx(x, y):
    return ((x - WORLD['x0']) / R / 2, (WORLD['y1'] - y) / R / 2)


for rl in road_lines:
    if rl['kind'] == 'road':
        dr.line([to_mpx(x, y) for x, y in rl['pts']], fill=(150, 104, 60), width=2)
for pts in RIVERS:
    dr.line([to_mpx(x, y) for x, y in pts], fill=(70, 140, 190), width=3)

# ---------------------------------------------------------------- yaz
h.astype(np.float32).tofile(os.path.join(OUT, 'height.bin'))
Image.fromarray(col).save(os.path.join(OUT, 'albedo.png'))
Image.fromarray(np.dstack([biome, (road * 255).astype(np.uint8), (wet * 255).astype(np.uint8),
                           (amp * 255).astype(np.uint8)]), 'RGBA').save(os.path.join(OUT, 'biome.png'))
Image.fromarray(np.dstack([(rock_mix * 255).astype(np.uint8), (mesa_w * 255).astype(np.uint8),
                           (dune_w * 255).astype(np.uint8), (np.clip(out_w, 0, 1) * 255).astype(np.uint8)]), 'RGBA').save(
    os.path.join(OUT, 'shape.png'))
mimg.save(os.path.join(OUT, 'map.png'))
with open(os.path.join(OUT, 'features.json'), 'w', encoding='utf8') as f:
    json.dump(features, f)
with open(os.path.join(OUT, 'pois.json'), 'w', encoding='utf8') as f:
    json.dump(pois, f, ensure_ascii=False)
with open(os.path.join(OUT, 'roads.json'), 'w', encoding='utf8') as f:
    json.dump(road_lines, f)
with open(os.path.join(OUT, 'rivers.json'), 'w', encoding='utf8') as f:
    json.dump(RIVERS, f)
for old in ('veg.bin',):
    p = os.path.join(OUT, old)
    if os.path.exists(p):
        os.remove(p)
info = dict(world=dict(WORLD, w=W, h=H, detail_max=DETAIL_MAX, version=3), countries=COUNTRIES, villages=VILLAGES,
            landmarks=LANDMARKS, biomes=BIOMES, roads=ROADS, patches=patches)
with open(os.path.join(OUT, 'world.json'), 'w', encoding='utf8') as f:
    json.dump(info, f, ensure_ascii=False, indent=1)
print('min/max h', float(h.min()), float(h.max()))
