"""İğne yaprak (çam/köknar) öbeği, bambu yaprağı öbeği ve palmiye yaprağı dokuları (anime_leaf.png ile aynı kural:
R = parlaklık, A = kesme). 2x2 atlas (iğne, bambu); palmiye tek yaprak (dikey: sap aşağıda, uç yukarıda)."""
import math, random
from PIL import Image, ImageDraw

def finish(img, path, size):
    img = img.resize((size, size), Image.LANCZOS)
    px = img.load()
    for y in range(size):
        for x in range(size):
            r, g, b, a = px[x, y]
            if a > 0:
                k = a / 255.0
                px[x, y] = (min(255, int(r / max(k, 0.01))), min(255, int(g / max(k, 0.01))), min(255, int(b / max(k, 0.01))), a)
    img.save(path)

# --- iğne yaprak pedleri: yassı bulut gibi ped, kısa ince iğne çizgileri dışa doğru, üst açık alt koyu
S = 1024; cell = S // 2
img = Image.new("RGBA", (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
for v in range(4):
    rnd = random.Random(31 + v)
    ox, oy = (v % 2) * cell, (v // 2) * cell
    cx, cy = ox + cell / 2, oy + cell / 2
    strokes = []
    for _ in range(1400):
        a = rnd.random() * math.tau
        rr = math.sqrt(rnd.random())
        px_ = math.cos(a) * rr * 0.46
        py_ = math.sin(a) * rr * 0.3 + (0.04 if rr > 0.8 and math.sin(a) > 0 else 0)
        L = rnd.uniform(0.05, 0.09) * cell
        ang = math.atan2(py_, px_) + rnd.uniform(-0.5, 0.5)
        br = max(0.3, min(1.0, 0.62 + 0.45 * (-py_ / 0.3) * 0.6 + rnd.uniform(-0.12, 0.12)))
        strokes.append((br, cx + px_ * cell, cy + py_ * cell, L, ang))
    strokes.sort(key=lambda q: q[0])
    for br, x, y, L, ang in strokes:
        c = int(br * 255)
        d.line([(x - math.cos(ang) * L * 0.5, y - math.sin(ang) * L * 0.5), (x + math.cos(ang) * L * 0.5, y + math.sin(ang) * L * 0.5)], fill=(c, c, c, 255), width=5)
finish(img, "godot/assets/tex/anime_needle.png", 512)

# --- bambu: ince uzun mızrak yapraklar, sarkık yelpaze öbekleri
img = Image.new("RGBA", (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
def leaf_poly(cx, cy, L, W, ang):
    pts = []
    n = 12
    for i in range(n + 1):
        t = i / n
        pts.append((t * L, W * math.sin(math.pi * t) ** 0.8))
    for i in range(n, -1, -1):
        t = i / n
        pts.append((t * L, -W * math.sin(math.pi * t) ** 0.8))
    ca, sa = math.cos(ang), math.sin(ang)
    return [(cx + x * ca - y * sa, cy + x * sa + y * ca) for x, y in pts]
for v in range(4):
    rnd = random.Random(51 + v)
    ox, oy = (v % 2) * cell, (v // 2) * cell
    leaves = []
    for k in range(5):   # 5 dal ucu, her birinden sarkan 6-8 yaprak
        bx = ox + cell * rnd.uniform(0.25, 0.75); by = oy + cell * rnd.uniform(0.2, 0.55)
        for _ in range(rnd.randint(6, 8)):
            ang = math.pi * 0.5 + rnd.uniform(-1.3, 1.3)
            L = cell * rnd.uniform(0.22, 0.32); W = L * rnd.uniform(0.09, 0.13)
            br = max(0.35, min(1.0, 0.85 - (by - oy) / cell * 0.5 + rnd.uniform(-0.15, 0.15)))
            leaves.append((br, bx, by, L, W, ang))
    leaves.sort(key=lambda q: q[0])
    for br, x, y, L, W, ang in leaves:
        c = int(br * 255)
        d.polygon(leaf_poly(x, y, L, W, ang), fill=(c, c, c, 255))
finish(img, "godot/assets/tex/anime_bamboo.png", 512)

# --- palmiye yaprağı: ortada sap (aşağıdan yukarı), iki yana tüy gibi ince yaprakçıklar, uca doğru kısalır
S2 = 1024
img = Image.new("RGBA", (S2, S2), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
rnd = random.Random(77)
d.line([(S2 / 2, S2 - 10), (S2 / 2, 20)], fill=(150, 150, 150, 255), width=10)
for i in range(40):
    t = i / 40
    y = S2 - 40 - t * (S2 - 80)
    L = S2 * 0.44 * math.sin(math.pi * (0.1 + 0.9 * t)) ** 0.6
    for sgn in (-1, 1):
        # yaprakçık: saptan dışa ve uca doğru çıkar, ucunda hafif sarkar (kemer)
        pts = []
        for k in range(7):
            u = k / 6
            x = S2 / 2 + sgn * L * u
            yy = y - L * 0.55 * u + L * 0.35 * u * u
            pts.append((x, yy))
        br = max(90, min(255, int((0.7 + rnd.uniform(-0.15, 0.15) - 0.2 * t) * 255)))
        d.line(pts, fill=(br, br, br, 255), width=14, joint="curve")
finish(img, "godot/assets/tex/anime_frond.png", 512)
print("ok")
