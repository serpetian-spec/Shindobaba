"""Anime ağaç yaprak öbeği atlası (2x2): her hücre yuvarlak, kenarı tırtıklı yaprak öbeği.
R = yaprak parlaklığı (gölgeleme köşe rengiyle çarpılır), A = alfa kesme. Godot: godot/assets/tex/anime_leaf.png"""
import math, random
from PIL import Image, ImageDraw

S = 1024           # süper örnekleme (sonra 512'ye)
cell = S // 2
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

def leaf_poly(cx, cy, L, W, ang):
    pts = []
    n = 14
    for i in range(n + 1):           # üst kenar
        t = -1 + 2 * i / n
        w = W * (1 - t * t) ** 0.6
        pts.append((t * L, w))
    for i in range(n, -1, -1):       # alt kenar
        t = -1 + 2 * i / n
        w = W * (1 - t * t) ** 0.6
        pts.append((t * L, -w * 0.9))
    ca, sa = math.cos(ang), math.sin(ang)
    return [(cx + x * ca - y * sa, cy + x * sa + y * ca) for x, y in pts]

for v in range(4):
    rnd = random.Random(11 + v * 7)
    ox, oy = (v % 2) * cell, (v // 2) * cell
    R = cell * 0.44
    # öbek gövdesi: birkaç alt-öbek (yuvarlak değil, boyalı küme gibi düzensiz)
    subs = [(0.0, 0.0, 1.0)] + [(rnd.uniform(-0.45, 0.45), rnd.uniform(-0.4, 0.35), rnd.uniform(0.45, 0.62)) for _ in range(4)]
    leaves = []
    for _ in range(330):
        sx, sy, sr = rnd.choice(subs)
        a = rnd.random() * math.tau
        rr = math.sqrt(rnd.random()) * sr * 0.7
        px = (sx * 0.5 + math.cos(a) * rr)
        py = (sy * 0.5 + math.sin(a) * rr)
        if px * px + py * py > 0.92 ** 2:
            continue
        L = rnd.uniform(0.06, 0.095) * cell
        W = L * rnd.uniform(0.62, 0.78)
        out = math.hypot(px, py)
        ang = math.atan2(py, px) + rnd.uniform(-0.9, 0.9) if out > 0.35 else rnd.random() * math.tau
        # ışık sol-üstten: üst/sol açık, alt koyu; her yaprakta küçük oynama (boyalı görünüm)
        br = 0.6 + 0.42 * (-py * 0.85 - px * 0.25) + rnd.uniform(-0.1, 0.1)
        br = max(0.32, min(1.0, br))
        leaves.append((br, ox + cell / 2 + px * R * 1.1, oy + cell / 2 + py * R * 1.1, L, W, ang))
    leaves.sort(key=lambda q: q[0])          # koyular altta, açıklar üstte
    for br, cx, cy, L, W, ang in leaves:
        c = int(br * 255)
        d.polygon(leaf_poly(cx, cy, L, W, ang), fill=(c, c, c, 255))
        # orta damar: biraz daha koyu ince çizgi
        cd = int(br * 0.8 * 255)
        ca, sa = math.cos(ang), math.sin(ang)
        d.line([(cx - ca * L * 0.8, cy - sa * L * 0.8), (cx + ca * L * 0.8, cy + sa * L * 0.8)], fill=(cd, cd, cd, 255), width=1)

img = img.resize((512, 512), Image.LANCZOS)
# alfa: yumuşak kenarı kes (alfa kesme eşiği shader'da 0.5)
px = img.load()
for y in range(512):
    for x in range(512):
        r, g, b, a = px[x, y]
        if a > 0:
            k = a / 255.0
            px[x, y] = (min(255, int(r / max(k, 0.01))), min(255, int(g / max(k, 0.01))), min(255, int(b / max(k, 0.01))), a)
img.save("godot/assets/tex/anime_leaf.png")
print("ok")
