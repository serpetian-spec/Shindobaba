"""bake_world.py -> Dünya 2.0: daha dramatik arazi, basamaklı yarlar, sık Ateş ormanı, özellik listesi (features.json)."""
import sys

p = sys.argv[1]
s = open(p, encoding='utf8').read()

# ---------------------------------------------------------------- yükseklik
old_start = s.index("# ---------------------------------------------------------------- yükseklik")
old_end = s.index("# ---------------------------------------------------------------- nehirler")
s = s[:old_start] + '''# ---------------------------------------------------------------- yükseklik
def W_(cid):
    return weights[names.index(cid)] / wsum


def terrace(hh, step, edge=.8):
    k = hh / step
    f = k - np.floor(k)
    f = np.clip((f - edge) / (1 - edge), 0, 1)
    f = f * f * (3 - 2 * f)
    return (np.floor(k) + f) * step


hills = fbm(900, 5, 10)
ridge = ridged(1400, 6, 20)
detail = fbm(120, 3, 30)
land_h = 4 + np.clip(L, 0, .6) * 35 + (hills - .5) * 60 + detail * 8
land_h += mount ** 1.3 * (ridge ** 1.6) * 300
# Ateş: yuvarlak tepeler ve vadiler
fire_w = W_('fire') + W_('waves') * .5
land_h += fire_w * (fbm(350, 3, 12) - .5) * 34
# basamaklı yarlar (mesa): Toprak, Taş, Nehirler, Rüzgar; Ateş'te nadir kaya çıkıntıları
mesa_n = fbm(520, 3, 77)
mesa_w = np.clip(W_('earth') + W_('stone') + W_('rivers') + W_('north') * .8 + W_('wind') * .7, 0, 1) * smoothstep(.42, .55, mesa_n)
land_h = land_h * (1 - mesa_w) + terrace(land_h + 6, 22.0) * mesa_w
out_w = fire_w * smoothstep(.74, .8, fbm(600, 2, 88))
land_h = land_h * (1 - out_w) + (terrace(land_h, 14.0, .75) + 10) * out_w
# çöl kumulları
desert_w = W_('wind')
dunes = (np.abs(np.sin((X * .9 + Y * .4) / 38 + fbm(300, 2, 40) * 6)) ** 1.5) * 12
land_h += desert_w * dunes * (1 - mesa_w)
# Yıldırım ülkesinde sivri zirveler
light_w = W_('lightning')
land_h += light_w * np.clip(ridged(420, 3, 50) - .55, 0, 1) ** 2 * 1100
sea_h = np.minimum(L * 140 - 2, -2)
coast = smoothstep(-.02, .05, L)
h = sea_h * (1 - coast) + land_h * coast

''' + s[old_end:]

# ---------------------------------------------------------------- yollar: çoklu çizgileri sakla
s = s.replace("""named = {v['id']: v for v in VILLAGES + LANDMARKS}
road = np.zeros_like(h)""", """named = {v['id']: v for v in VILLAGES + LANDMARKS}
road = np.zeros_like(h)
road_lines = []""")
s = s.replace("""    d = dist_to_polyline(pts)
    road = np.maximum(road, 1 - smoothstep(4, 9, d))""", """    d = dist_to_polyline(pts)
    road = np.maximum(road, 1 - smoothstep(4, 9, d))
    road_lines.append(pts)""")

# ---------------------------------------------------------------- Sonun Vadisi: yeni oyma
old_start = s.index("# Sonun Vadisi: derin kanyon + şelale")
old_end = s.index("# Gizli şelale")
s = s[:old_start] + '''# Sonun Vadisi: yüksek plato, ortadan akan nehir, kuzeyde şelale basamağı
ve = named['valley_end']
dx, dy = X - ve['x'], Y - ve['y']
inside = (np.abs(dy) < 330) & (np.abs(dx) < 240)
plateau = 48.0
bank = smoothstep(32, 46, np.abs(dx))
lower = np.where(dy > 230, 34.0, -3.5)
vh = lower * (1 - bank) + plateau * bank
blend = 1 - smoothstep(200, 260, np.maximum(np.abs(dx), np.abs(dy) - 90))
h = np.where(inside, h * (1 - blend) + vh * blend, h)
ve['base'] = plateau
''' + s[old_end:]

# ---------------------------------------------------------------- bitki örtüsü
old_start = s.index("# ---------------------------------------------------------------- bitki örtüsü")
old_end = s.index("# ---------------------------------------------------------------- harita görseli")
s = s[:old_start] + '''# ---------------------------------------------------------------- bitki örtüsü
# tipler: 0 geniş ağaç, 1 çam, 2 kuru ağaç, 3 kaktüs, 4 kaya, 5 dev ağaç, 6 bambu, 7 palmiye, 8 çalı,
#         9 Konoha orman ağacı (dev, dallı), 10 eğrelti, 11 büyük kaya kümesi, 12 çiçek öbeği
DENS = {'forest': (.0105, [9, 9, 9, 9, 0, 0, 8, 10, 10, 12, 6]), 'rain': (.003, [2, 2, 0, 8, 10]),
        'rock': (.0016, [4, 11, 1, 8]), 'rice': (.0012, [0, 8, 6, 12]), 'grass': (.002, [0, 9, 8, 12, 12, 10]),
        'snow': (.003, [1, 1, 1, 4]), 'mountain': (.0028, [1, 1, 4, 11, 8]), 'swamp': (.004, [2, 2, 0, 8, 10]),
        'desert': (.00035, [3, 3, 4, 11]), 'beach': (.0006, [7, 8]), 'village': (0, []), 'sea': (0, []), 'road': (0, [])}
clearing = fbm(260, 3, 91)
veg = []
area = R * R
for name, (dens, types) in DENS.items():
    if not dens:
        continue
    m = (biome == BID[name]) & (road < .1) & (h > .8) & (slope < 1.1) & (wet < .4)
    iy, ix = np.nonzero(m)
    local = (.35 + 1.3 * fbm(400, 2, 90)[iy, ix]) * smoothstep(.3, .42, clearing[iy, ix])
    keep = rng.random(len(ix)) < dens * area * local
    iy, ix = iy[keep], ix[keep]
    for a, b in zip(iy, ix):
        t = types[rng.integers(len(types))]
        if t in (9, 0) and slope[a, b] > .7:
            t = 4
        x = xs[b] + rng.uniform(-R / 2, R / 2)
        y = ys[a] + rng.uniform(-R / 2, R / 2)
        sc = rng.uniform(.8, 1.3) if t != 9 else rng.uniform(.85, 1.25)
        veg.append((x, float(h[a, b]), y, sc, rng.uniform(0, 6.283), t))
# köylerin çevresinde orman halkası (Konoha ormanın içinde bir köy)
for v in VILLAGES:
    if v['id'] not in ('konoha', 'kusa', 'taki', 'tani'):
        continue
    n = int(v['r'] * 3.2)
    for _ in range(n):
        ang = rng.uniform(0, 6.283)
        rad = v['r'] + 25 + abs(rng.normal(0, 90))
        x, y = v['x'] + rad * math.cos(ang), v['y'] + rad * math.sin(ang)
        ix_, iy_ = int((x - WORLD['x0']) / R), int((WORLD['y1'] - y) / R)
        if not (0 <= ix_ < W and 0 <= iy_ < H) or road[iy_, ix_] > .1 or h[iy_, ix_] < 1 or wet[iy_, ix_] > .4:
            continue
        veg.append((x, float(h[iy_, ix_]), y, rng.uniform(.9, 1.3), rng.uniform(0, 6.283), 9))
# Ölüm Ormanı: dev ağaçlar
fd = named['forest_death']
for _ in range(160):
    ang, rad = rng.uniform(0, 6.283), math.sqrt(rng.uniform(0, 1)) * (fd['r'] - 15)
    x, y = fd['x'] + rad * math.cos(ang), fd['y'] + rad * math.sin(ang)
    veg.append((x, fd['base'], y, rng.uniform(.8, 1.3), rng.uniform(0, 6.283), 5))
# Nara ormanı yoğun
nf = named['nara_forest']
for _ in range(600):
    ang, rad = rng.uniform(0, 6.283), math.sqrt(rng.uniform(0, 1)) * nf['r']
    veg.append((nf['x'] + rad * math.cos(ang), nf['base'], nf['y'] + rad * math.sin(ang), rng.uniform(.9, 1.3),
                rng.uniform(0, 6.283), [9, 9, 0, 10][rng.integers(4)]))
veg = np.array(veg, dtype=np.float32)
print('vegetation', len(veg))


# ---------------------------------------------------------------- özellikler (Godot Builder ile çarpışmalı inşa edilir)
def hat(x, y):
    ix_, iy_ = int((x - WORLD['x0']) / R), int((WORLD['y1'] - y) / R)
    if 0 <= ix_ < W and 0 <= iy_ < H:
        return float(h[iy_, ix_]), int(biome[iy_, ix_]), float(wet[iy_, ix_]), float(road[iy_, ix_])
    return -50.0, 0, 0.0, 0.0


def near_village(x, y, pad):
    for v in VILLAGES + LANDMARKS:
        if math.hypot(x - v['x'], y - v['y']) < v['r'] + pad:
            return True
    return False


features = []
# kaya sütunları / mesalar / sivri zirveler
for cid, n, kind, hr, rr in [('earth', 140, 'pillar', (25, 75), (6, 16)), ('stone', 40, 'pillar', (20, 55), (6, 14)),
                             ('rivers', 45, 'pillar', (18, 45), (5, 12)), ('wind', 45, 'mesa', (14, 35), (14, 34)),
                             ('lightning', 90, 'spire', (45, 140), (5, 12)), ('north', 50, 'pillar', (20, 60), (6, 14))]:
    c = COUNTRIES[names.index(cid)]
    k = 0
    tries = 0
    while k < n and tries < n * 30:
        tries += 1
        ang, rad = rng.uniform(0, 6.283), math.sqrt(rng.uniform(0, 1)) * c['r']
        x, y = c['x'] + rad * math.cos(ang), c['y'] + rad * math.sin(ang)
        g, b, wt, rd = hat(x, y)
        if g < 2 or wt > .2 or rd > .05 or near_village(x, y, 60):
            continue
        features.append(dict(t=kind, x=round(x, 1), y=round(y, 1), g=round(g, 1), h=round(rng.uniform(*hr), 1),
                             r=round(rng.uniform(*rr), 1), yaw=round(rng.uniform(0, 360), 1)))
        k += 1
# doğal kemerler
for cid, n in [('wind', 8), ('earth', 8), ('rivers', 4)]:
    c = COUNTRIES[names.index(cid)]
    for _ in range(n):
        ang, rad = rng.uniform(0, 6.283), math.sqrt(rng.uniform(0, 1)) * c['r'] * .8
        x, y = c['x'] + rad * math.cos(ang), c['y'] + rad * math.sin(ang)
        g, b, wt, rd = hat(x, y)
        if g > 2 and not near_village(x, y, 80) and rd < .05:
            features.append(dict(t='arch', x=round(x, 1), y=round(y, 1), g=round(g, 1), h=round(rng.uniform(20, 38), 1),
                                 r=round(rng.uniform(20, 36), 1), yaw=round(rng.uniform(0, 180), 1)))
# yol kenarı: fener çiftleri, tapınak/torii/jizo/tabela, çay evleri, köprüler
for pts in road_lines:
    seg = []
    for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
        L_ = math.hypot(x1 - x0, y1 - y0)
        n = max(1, int(L_ / 15))
        for i in range(n):
            t = i / n
            seg.append((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, math.degrees(math.atan2(x1 - x0, y1 - y0))))
    dist = 0.0
    total = len(seg)
    for i, (x, y, yaw) in enumerate(seg):
        dist += 15
        g, b, wt, rd = hat(x, y)
        if near_village(x, y, 30):
            continue
        if wt > .55 and g < 1.5:
            # nehir geçişi: köprü (aynı köprüyü tekrar koyma)
            if not features or features[-1]['t'] != 'bridge' or math.hypot(features[-1]['x'] - x, features[-1]['y'] - y) > 60:
                features.append(dict(t='bridge', x=round(x, 1), y=round(y, 1), g=0, h=0, r=40, yaw=round(yaw, 1)))
            continue
        if g < 1:
            continue
        if int(dist) % 120 == 0:
            for sd in (-1, 1):
                ox, oy = math.cos(math.radians(yaw)) * 8 * sd, -math.sin(math.radians(yaw)) * 8 * sd
                features.append(dict(t='lantern', x=round(x + ox, 1), y=round(y + oy, 1), g=round(hat(x + ox, y + oy)[0], 1), h=0, r=0, yaw=round(yaw, 1)))
        if int(dist) % 600 == 300:
            kind = ['shrine', 'torii', 'jizo', 'sign', 'shrine'][rng.integers(5)]
            sd = 1 if rng.random() < .5 else -1
            ox, oy = math.cos(math.radians(yaw)) * 14 * sd, -math.sin(math.radians(yaw)) * 14 * sd
            if kind == 'torii':
                ox, oy = 0, 0
            features.append(dict(t=kind, x=round(x + ox, 1), y=round(y + oy, 1), g=round(hat(x + ox, y + oy)[0], 1), h=0, r=0, yaw=round(yaw, 1)))
        if i == total // 2 and total > 30:
            sd = 1 if rng.random() < .5 else -1
            ox, oy = math.cos(math.radians(yaw)) * 22 * sd, -math.sin(math.radians(yaw)) * 22 * sd
            features.append(dict(t='teahouse', x=round(x + ox, 1), y=round(y + oy, 1), g=round(hat(x + ox, y + oy)[0], 1), h=0, r=0, yaw=round(yaw, 1)))
# pirinç tarlaları: Ses ülkesi + Konoha çevresi düzlükleri
for cx, cy, rr, n in [(259, 1038, 420, 60), (-50, -75, 760, 70), (-1138, 441, 360, 25)]:
    for _ in range(n):
        ang, rad = rng.uniform(0, 6.283), rng.uniform(rr * .62, rr)
        x, y = cx + rad * math.cos(ang), cy + rad * math.sin(ang)
        g, b, wt, rd = hat(x, y)
        if g < 2 or g > 60 or rd > .05 or wt > .3 or near_village(x, y, 20):
            continue
        features.append(dict(t='paddy', x=round(x, 1), y=round(y, 1), g=round(g, 1), h=0, r=round(rng.uniform(18, 30), 1), yaw=round(rng.uniform(0, 90), 1)))
print('features', len(features))

''' + s[old_end:]

s = s.replace("""veg.tofile(os.path.join(OUT, 'veg.bin'))""", """veg.tofile(os.path.join(OUT, 'veg.bin'))
with open(os.path.join(OUT, 'features.json'), 'w', encoding='utf8') as f:
    json.dump(features, f)""")
open(p, 'w', encoding='utf8').write(s)
print('ok')
