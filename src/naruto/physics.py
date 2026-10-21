"""Basit ama sağlam çarpışma sistemi.

Dünya: Y ekseninde döndürülebilen kutular (Box) ve dikey silindirler (Cyl).
Karakterler: dikey kapsül/silindir (Body) -> yarıçap + boy. Boyut büyüdükçe hitbox da büyür.
Hiçbir karakter dünyanın içine ya da başka karakterin içine giremez.
"""
import math
from ursina import Vec3

CELL = 16.0
STEP_UP = 0.55  # bu yükseklikten alçak engellerin üstüne otomatik çıkılır


class Box:
    __slots__ = ('cx', 'cy', 'cz', 'hx', 'hy', 'hz', 'y0', 'y1', 'c', 's', 'R', 'tag')

    def __init__(self, center, size, yaw=0.0, tag=None):
        self.cx, self.cy, self.cz = center
        self.hx, self.hy, self.hz = size[0] / 2, size[1] / 2, size[2] / 2
        self.y0, self.y1 = self.cy - self.hy, self.cy + self.hy
        r = math.radians(yaw)
        self.c, self.s = math.cos(r), math.sin(r)
        self.R = math.hypot(self.hx, self.hz)
        self.tag = tag

    def local(self, x, z):
        dx, dz = x - self.cx, z - self.cz
        return dx * self.c - dz * self.s, dx * self.s + dz * self.c

    def world_dir(self, lx, lz):
        return lx * self.c + lz * self.s, -lx * self.s + lz * self.c

    def circle(self, x, z, r):
        """Daireyi kutudan dışarı itme: (pen, nx, nz) ya da None"""
        lx, lz = self.local(x, z)
        qx = max(-self.hx, min(self.hx, lx))
        qz = max(-self.hz, min(self.hz, lz))
        dx, dz = lx - qx, lz - qz
        d = math.hypot(dx, dz)
        if d > 1e-6:
            if d >= r:
                return None
            nx, nz = self.world_dir(dx / d, dz / d)
            return r - d, nx, nz
        px, pz = self.hx - abs(lx), self.hz - abs(lz)
        if px < pz:
            nx, nz = self.world_dir(1 if lx >= 0 else -1, 0)
            return px + r, nx, nz
        nx, nz = self.world_dir(0, 1 if lz >= 0 else -1)
        return pz + r, nx, nz

    def footprint_dist(self, x, z):
        lx, lz = self.local(x, z)
        dx = max(abs(lx) - self.hx, 0)
        dz = max(abs(lz) - self.hz, 0)
        return math.hypot(dx, dz)

    def ray(self, o, d, maxt):
        lx, lz = self.local(o[0], o[2])
        ldx, ldz = d[0] * self.c - d[2] * self.s, d[0] * self.s + d[2] * self.c
        tmin, tmax, axis = 0.0, maxt, -1
        for i, (p, v, lo, hi) in enumerate(((lx, ldx, -self.hx, self.hx), (o[1], d[1], self.y0, self.y1),
                                            (lz, ldz, -self.hz, self.hz))):
            if abs(v) < 1e-9:
                if p < lo or p > hi:
                    return None
                continue
            t1, t2 = (lo - p) / v, (hi - p) / v
            sgn = -1
            if t1 > t2:
                t1, t2, sgn = t2, t1, 1
            if t1 > tmin:
                tmin, axis, nsgn = t1, i, sgn
            tmax = min(tmax, t2)
            if tmin > tmax:
                return None
        if axis < 0:
            return None  # ışın kutunun içinden başlıyor
        if axis == 1:
            return tmin, Vec3(0, nsgn, 0)
        nx, nz = self.world_dir(nsgn if axis == 0 else 0, nsgn if axis == 2 else 0)
        return tmin, Vec3(nx, 0, nz)


class Cyl:
    __slots__ = ('cx', 'cz', 'r', 'y0', 'y1', 'R', 'tag')

    def __init__(self, x, z, r, y0, y1, tag=None):
        self.cx, self.cz, self.r, self.y0, self.y1, self.R, self.tag = x, z, r, y0, y1, r, tag

    def circle(self, x, z, r):
        dx, dz = x - self.cx, z - self.cz
        d = math.hypot(dx, dz)
        if d >= r + self.r:
            return None
        if d < 1e-6:
            return r + self.r, 1, 0
        return r + self.r - d, dx / d, dz / d

    def footprint_dist(self, x, z):
        return max(math.hypot(x - self.cx, z - self.cz) - self.r, 0)

    def ray(self, o, d, maxt):
        ox, oz = o[0] - self.cx, o[2] - self.cz
        a = d[0] ** 2 + d[2] ** 2
        best = None
        if a > 1e-9:
            b = 2 * (ox * d[0] + oz * d[2])
            c = ox * ox + oz * oz - self.r ** 2
            disc = b * b - 4 * a * c
            if disc >= 0 and c > 0:
                t = (-b - math.sqrt(disc)) / (2 * a)
                if 0 <= t <= maxt and self.y0 <= o[1] + d[1] * t <= self.y1:
                    best = (t, Vec3(ox + d[0] * t, 0, oz + d[2] * t).normalized())
        if abs(d[1]) > 1e-9:  # üst / alt kapak
            for yy, n in ((self.y1, 1), (self.y0, -1)):
                t = (yy - o[1]) / d[1]
                if 0 <= t <= maxt and (best is None or t < best[0]):
                    if (ox + d[0] * t) ** 2 + (oz + d[2] * t) ** 2 <= self.r ** 2 and (o[1] - yy) * n > 0:
                        best = (t, Vec3(0, n, 0))
        return best


class Body:
    """Karakter hitbox'ı: ayak noktası + yarıçap + boy. mass=0 -> itilemez (kukla vb.)"""

    def __init__(self, entity, radius=.4, height=1.8, mass=1.0):
        self.e, self.radius, self.height, self.mass = entity, radius, height, mass
        self.active = True


class Physics:
    def __init__(self, bound=290):
        self.grid = {}
        self.all = []
        self.bodies = []
        self.bound = bound

    def add(self, col):
        self.all.append(col)
        if isinstance(col, Box):
            x, z, R = col.cx, col.cz, col.R
        else:
            x, z, R = col.cx, col.cz, col.r
        for ix in range(int(math.floor((x - R) / CELL)), int(math.floor((x + R) / CELL)) + 1):
            for iz in range(int(math.floor((z - R) / CELL)), int(math.floor((z + R) / CELL)) + 1):
                self.grid.setdefault((ix, iz), []).append(col)
        return col

    def box(self, center, size, yaw=0, tag=None):
        return self.add(Box(center, size, yaw, tag))

    def cyl(self, x, z, r, y0, y1, tag=None):
        return self.add(Cyl(x, z, r, y0, y1, tag))

    def near(self, x0, z0, x1, z1):
        seen = set()
        out = []
        for ix in range(int(math.floor(min(x0, x1) / CELL)), int(math.floor(max(x0, x1) / CELL)) + 1):
            for iz in range(int(math.floor(min(z0, z1) / CELL)), int(math.floor(max(z0, z1) / CELL)) + 1):
                for c in self.grid.get((ix, iz), ()):
                    if id(c) not in seen:
                        seen.add(id(c))
                        out.append(c)
        return out

    # ---- karakter hareketi ----
    def resolve(self, pos, r, h):
        """pos'u (ayak) dünyadan dışarı iter. Dokunulan duvarları döndürür: [(nx, nz, col)]"""
        contacts = []
        for _ in range(3):
            moved = False
            for c in self.near(pos.x - r, pos.z - r, pos.x + r, pos.z + r):
                if c.y1 <= pos.y + STEP_UP or c.y0 >= pos.y + h:
                    continue
                res = c.circle(pos.x, pos.z, r)
                if res:
                    pen, nx, nz = res
                    pos.x += nx * (pen + 1e-4)
                    pos.z += nz * (pen + 1e-4)
                    contacts.append((nx, nz, c))
                    moved = True
            if not moved:
                break
        b = self.bound
        pos.x = max(-b, min(b, pos.x))
        pos.z = max(-b, min(b, pos.z))
        return contacts

    def floor(self, x, z, r, y):
        """y'nin altındaki (ya da STEP_UP kadar üstündeki) en yüksek zemin."""
        best = 0.0
        fr = r * .75
        for c in self.near(x - r, z - r, x + r, z + r):
            if c.y1 <= y + STEP_UP and c.y1 > best and c.footprint_dist(x, z) < fr:
                best = c.y1
        return best

    def ceiling(self, x, z, r, y_top):
        best = 1e9
        for c in self.near(x - r, z - r, x + r, z + r):
            if c.y0 >= y_top - .3 and c.y0 < best and c.footprint_dist(x, z) < r * .75:
                best = c.y0
        return best

    def raycast(self, o, d, maxt):
        """Dünyaya karşı ışın: (t, normal, col) ya da None"""
        e = o + d * maxt
        best = None
        for c in self.near(o.x, o.z, e.x, e.z):
            hit = c.ray(o, d, maxt)
            if hit and (best is None or hit[0] < best[0]):
                best = (hit[0], hit[1], c)
        if d.y < -1e-6 and o.y > 0:  # zemin
            t = -o.y / d.y
            if t <= maxt and (best is None or t < best[0]):
                best = (t, Vec3(0, 1, 0), None)
        return best

    # ---- karakter-karakter ----
    def separate_bodies(self):
        bs = [b for b in self.bodies if b.active and b.e.enabled]
        for i in range(len(bs)):
            a = bs[i]
            pa = a.e.position
            for j in range(i + 1, len(bs)):
                b = bs[j]
                pb = b.e.position
                if pa.y >= pb.y + b.height or pb.y >= pa.y + a.height:
                    continue
                dx, dz = pb.x - pa.x, pb.z - pa.z
                d = math.hypot(dx, dz)
                rr = a.radius + b.radius
                if d >= rr:
                    continue
                if d < 1e-5:
                    dx, dz, d = 1, 0, 1
                pen = rr - d
                ma, mb = a.mass, b.mass
                if ma == 0 and mb == 0:
                    continue
                wa = 0 if ma == 0 else (1 if mb == 0 else mb / (ma + mb))
                wb = 0 if mb == 0 else (1 if ma == 0 else ma / (ma + mb))
                nx, nz = dx / d, dz / d
                if wa:
                    a.e.x -= nx * pen * wa
                    a.e.z -= nz * pen * wa
                if wb:
                    b.e.x += nx * pen * wb
                    b.e.z += nz * pen * wb
        # itildikten sonra duvara girmesinler
        for b in bs:
            if b.mass:
                p = b.e.position
                self.resolve(p, b.radius, b.height)
                b.e.position = p


def capsule_hit(point, body, extra=0.0):
    """Bir noktanın (saldırı küresi merkezi) karakter kapsülüne değip değmediği."""
    p = body.e.position
    y = max(p.y, min(p.y + body.height, point[1]))
    d = math.sqrt((point[0] - p.x) ** 2 + (point[1] - y) ** 2 + (point[2] - p.z) ** 2)
    return d <= body.radius + extra
