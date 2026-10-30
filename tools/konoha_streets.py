"""Konoha iç cadde ağı (organik): tören caddesi, çarşı caddesi, iç/dış çevre yolu, kıvrımlı ara caddeler, simge yapılara kollar.
Eski düz ızgaranın yerini alır. bake_world.py bunu kullanır; tek başına çalıştırılınca roads.json'daki Konoha caddelerini yeniler:
  python tools/konoha_streets.py
Koordinatlar: köy merkezine göre yerel (x doğu, n kuzey) -> harita (x, y) = (v.x + x, v.y + n).
"""
import json
import math
import os

# simge yapılar (build_konoha.gd ile aynı): caddeler bunların içinden geçmesin
LANDMARKS = {
    "hokage": (0, 582, 120), "academy": (-540, 585, 85), "hospital": (557, 204, 75), "stadium": (1050, -700, 95),
    "uchiha": (-1020, -640, 135), "hyuga": (-1050, 250, 90), "training": (1050, 560, 80), "park": (-520, -250, 80),
}


def _wob(t, seed, amp):
    return amp * (math.sin(t * 6.1 + seed * 1.7) * 0.6 + math.sin(t * 13.3 + seed * 3.1) * 0.4)


def _ring(cx, cn, rx, rn, seed, amp, n=72, a0=0.0, a1=360.0):
    pts = []
    for i in range(n + 1):
        t = i / n
        a = math.radians(a0 + (a1 - a0) * t)
        r = 1.0 + _wob(t * (a1 - a0) / 360.0 * 3.0, seed, amp)
        pts.append((cx + math.sin(a) * rx * r, cn + math.cos(a) * rn * r))
    return pts


def _line(a, b, seed, amp, n=12):
    ax, an = a
    bx, bn = b
    dx, dn = bx - ax, bn - an
    L = math.hypot(dx, dn) or 1.0
    nx, nn = -dn / L, dx / L
    pts = []
    for i in range(n + 1):
        t = i / n
        o = _wob(t, seed, amp) * math.sin(t * math.pi) * L
        pts.append((ax + dx * t + nx * o, an + dn * t + nn * o))
    return pts


def _polar(ang, r, cx=0.0, cn=0.0):
    a = math.radians(ang)
    return (cx + math.sin(a) * r, cn + math.cos(a) * r)


def local_streets(R, gates):
    S = []
    # 1) tören caddesi: güney A-Un kapısından Hokage meydanının önüne, dümdüz
    S.append([(0.0, -R), (0.0, 470.0)])
    # 2) diğer kapılardan merkeze kıvrımlı ana yollar
    for g in gates:
        if abs((g - 180.0 + 180) % 360 - 180) < 1:
            continue
        gx, gn = _polar(g, R)
        S.append(_line((gx, gn), (0.0, 0.0), int(g), 0.035, 16))
    # 3) çarşı caddesi (doğu-batı, n=0)
    S.append([(-760.0, 0.0), (760.0, 0.0)])
    # 4) iç çevre yolu (merkez biraz kuzeyde, Hokage meydanının altından geçer)
    S.append(_ring(0.0, 40.0, 430.0, 380.0, 3, 0.035, 80))
    # 5) dış çevre yolu
    S.append(_ring(0.0, 0.0, 900.0, 860.0, 7, 0.03, 120))
    # 6) ara caddeler: iç halkadan dış halkaya, bazıları sura kadar
    for k, ang in enumerate([35, 65, 140, 160, 205, 218, 290, 320, 340]):
        a = _polar(ang, 440.0, 0, 40)
        e = _polar(ang + 6, 905.0)
        S.append(_line(a, e, k + 11, 0.05, 14))
        if ang in (140, 205, 160):   # güney mahallelere sura kadar uzanır
            e2 = _polar(ang + 10, R - 70.0)
            S.append(_line(e, e2, k + 31, 0.05, 12))
    # 7) simge yapılara kollar (dış halkadan yapının kenarına)
    for name, ang, stop in [("training", 62, (980.0, 500.0)), ("stadium", 124, (990.0, -620.0)), ("uchiha", 238, (-905.0, -525.0)),
                            ("hyuga", 283, (-965.0, 240.0)), ("academy", 313, (-540.0, 505.0)), ("hospital", 70, (557.0, 125.0))]:
        a = _polar(ang, 880.0) if name not in ("hospital",) else _polar(ang, 430.0, 0, 40)
        S.append(_line(a, stop, len(name), 0.03, 10))
    # 8) iç mahallede iki kısa çapraz cadde (çarşının kuzeyi ve güneyi)
    S.append(_line((-420.0, 220.0), (420.0, 230.0), 51, 0.03, 16))
    S.append(_line((-420.0, -230.0), (420.0, -220.0), 52, 0.03, 16))
    return S


def streets(v):
    out = []
    for pts in local_streets(float(v['r']) - 40.0, [float(g) for g in v.get('gates', [180.0, 100.0, 260.0])]):
        out.append(dict(a=v['id'], b=v['id'], kind='street', pts=[[round(v['x'] + x, 1), round(v['y'] + n, 1)] for x, n in pts]))
    return out


if __name__ == '__main__':
    D = os.path.join(os.path.dirname(__file__), '..', 'godot', 'data', 'world')
    world = json.load(open(os.path.join(D, 'world.json'), encoding='utf-8'))
    v = [x for x in world['villages'] if x['id'] == 'konoha'][0]
    roads = json.load(open(os.path.join(D, 'roads.json'), encoding='utf-8'))
    keep = [r for r in roads if not (r.get('a') == 'konoha' and r.get('b') == 'konoha' and r.get('kind') == 'street')]
    new = streets(v)
    json.dump(keep + new, open(os.path.join(D, 'roads.json'), 'w', encoding='utf-8'))
    print('konoha caddeleri:', len(roads) - len(keep), '->', len(new))
