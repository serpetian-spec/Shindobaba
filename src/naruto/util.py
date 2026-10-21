import math
from ursina import color, Color, Entity, Vec3, destroy, curve
import random
from ursina.models.procedural.cylinder import Cylinder
from ursina.models.procedural.cone import Cone


def mdl(name):
    """'cyl12' / 'cone16' gibi isimleri prosedürel modele çevirir (taban y=0, yükseklik 1, çap 1)."""
    if isinstance(name, str):
        if name.startswith('cyl'):
            return Cylinder(resolution=int(name[3:] or 8), radius=.5, start=0, height=1)
        if name.startswith('cone'):
            return Cone(resolution=int(name[4:] or 8), radius=.5, height=1)
    return name


def C(h, a=1.0):
    h = h.lstrip('#')
    if len(h) == 3:
        h = ''.join(ch * 2 for ch in h)
    c = color.hex(h[:6])
    return Color(c[0], c[1], c[2], a)


def lerp_angle(a, b, t):
    d = (b - a + 180) % 360 - 180
    return a + d * min(1, t)


def flat(v):
    v = Vec3(v[0], 0, v[2])
    return v.normalized() if v.length() > 1e-5 else Vec3(0, 0, 0)


def poof(pos, size=1.0, col='#f2f2f2', count=10):
    """Duman efekti (gölge klon, ışınlanma vb.)"""
    for _ in range(count):
        p = Entity(model='sphere', color=C(col, .85), position=pos + Vec3(random.uniform(-.5, .5) * size,
                                                                          random.uniform(0, 1.2) * size,
                                                                          random.uniform(-.5, .5) * size),
                   scale=.3 * size, unlit=True)
        p.animate_scale(random.uniform(1.0, 1.8) * size, duration=.45, curve=curve.out_expo)
        p.animate_position(p.position + Vec3(0, .8 * size, 0), duration=.6)
        p.fade_out(duration=.6, delay=.1)
        destroy(p, delay=.75)


def burst(pos, col='#5fc8ff', size=4.0, dur=.4):
    e = Entity(model='sphere', color=C(col, .7), position=pos, scale=.5, unlit=True)
    e.animate_scale(size, duration=dur, curve=curve.out_expo)
    e.fade_out(duration=dur)
    destroy(e, delay=dur + .05)
