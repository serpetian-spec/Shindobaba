import math
import random
from ursina import Entity, Vec3, scene, color, Sky, AmbientLight, DirectionalLight, camera
from .util import C, mdl
from .physics import Physics
from . import state

WALL_R = 150

ZONES = [
    # (isim, x, z, yarıçap) - küçükten büyüğe kontrol edilir
    ('Ichiraku Ramen', 16, -40, 10),
    ('Hokage Kulesi', 0, 80, 22),
    ('Ninja Akademisi', -55, 55, 25),
    ('Antrenman Alanı 3', 95, -20, 28),
    ('Uchiha Bölgesi', -100, -65, 32),
    ('Ana Kapı (A-Un)', 0, -150, 18),
    ('Hokage Kayası', 0, 175, 60),
    ('Ölüm Ormanı (44. Alan)', -215, -140, 70),
    ('Gölet ve İskele', 195, -120, 45),
    ('Konoha', 0, 0, WALL_R),
    ('Ateş Ülkesi Ormanları', 0, 0, 9999),
]


class World:
    def __init__(self, seed=7):
        random.seed(seed)
        self.phys = Physics(bound=290)
        self.static = Entity()
        self.spawn = Vec3(0, 0, -120)
        self.road_points = []
        state.world = self

        self.environment()
        self.ground()
        self.walls_and_gate()
        self.hokage_rock()
        self.hokage_tower()
        self.roads()
        self.ichiraku()
        self.academy()
        self.training_ground()
        self.uchiha_district()
        self.houses()
        self.forest()
        self.forest_of_death()
        self.lake()
        self.boundary_mountains()
        self.static.combine()
        self.static.collider = None

    # ------------------------------------------------------------ yardımcılar
    def vis(self, model, pos, scale, col, rot=(0, 0, 0)):
        return Entity(parent=self.static, model=mdl(model), position=pos, scale=scale, rotation=rot,
                      color=C(col) if isinstance(col, str) else col)

    def box(self, pos, scale, col, yaw=0, collide=True, tag=None):
        self.vis('cube', pos, scale, col, (0, yaw, 0))
        if collide:
            self.phys.box(pos, scale, yaw, tag)

    def cyl(self, x, z, r, y0, h, col, collide=True, res=12):
        self.vis(f'cyl{res}', (x, y0, z), (r * 2, h, r * 2), col)
        if collide:
            self.phys.cyl(x, z, r, y0, y0 + h)

    @staticmethod
    def rot(lx, lz, yaw):
        a = math.radians(yaw)
        return lx * math.cos(a) + lz * math.sin(a), -lx * math.sin(a) + lz * math.cos(a)

    def free(self, x, z, pad=0):
        """Ev koymak için boş mu?"""
        for name, zx, zz, r in ZONES[:7]:
            if name.startswith('Hokage Kayası'):
                continue
            if math.hypot(x - zx, z - zz) < r + pad:
                return False
        if abs(x) < 14 + pad:  # ana cadde
            return False
        for rz in (-60, 0, 40):
            if abs(z - rz) < 10 + pad:
                return False
        return True

    # ------------------------------------------------------------ bölümler
    def environment(self):
        Sky(color=C('#9fd3ff'))
        scene.fog_color = C('#bfe3ff')
        scene.fog_density = .0035
        camera.clip_plane_far = 900
        sun = DirectionalLight(shadows=False)
        sun.look_at(Vec3(.6, -1, .4))
        AmbientLight(color=C('#8a95a8'))

    def ground(self):
        self.vis('cube', (0, -.5, 0), (700, 1, 700), '#6aa84f')
        # köy içi daha açık toprak-çim
        self.vis('cyl32', (0, -.49, 0), (WALL_R * 2, .5, WALL_R * 2), '#88b45c')

    def walls_and_gate(self):
        seg = 6
        for deg in range(0, 360, seg):
            th = deg + seg / 2
            if abs(((th + 180) % 360) - 180) < 26:  # kuzey: kayalık
                continue
            if abs(th - 180) < 7:  # güney: kapı
                continue
            t = math.radians(th)
            x, z = WALL_R * math.sin(t), WALL_R * math.cos(t)
            L = 2 * math.pi * WALL_R * seg / 360 + .6
            self.box((x, 7, z), (L, 14, 3), '#c9b48a', yaw=th)
            self.box((x, 14.4, z), (L, .8, 3.6), '#8b3a2a', yaw=th, collide=False)
        # surları kayalığa bağla
        for sx in (-1, 1):
            t = math.radians(26)
            x, z = WALL_R * math.sin(t) * sx, WALL_R * math.cos(t)
            self.box((x, 7, (z + 160) / 2), (3, 14, 160 - z + 2), '#c9b48a')
        # A-Un kapısı
        gz = -WALL_R
        for sx in (-1, 1):
            self.box((11 * sx, 11, gz), (4, 22, 5), '#3f6b3a')
            self.box((19 * sx, 9, gz), (12, 18, 3.5), '#c9b48a')
            # açık kapı kanatları
            self.box((12.5 * sx, 8, gz + 5.5), (1, 16, 10), '#3f6b3a')
        self.box((0, 23, gz), (28, 3, 5), '#3f6b3a')
        self.box((0, 20, gz - 2.6), (10, 2.5, .3), '#e8e0c8', collide=False)  # tabela
        for sx in (-1, 1):  # kapı nöbetçi kulübesi
            self.box((22 * sx, 1.5, gz + 12), (6, 3, 4), '#a0784a')
            self.box((22 * sx, 3.2, gz + 12), (7, .4, 5), '#2e5a8a')

    def hokage_rock(self):
        rock, dark = '#8d8273', '#6c6256'
        self.box((0, 25, 190), (300, 50, 60), rock)
        self.box((0, 45, 230), (360, 90, 40), dark)
        self.vis('cone16', (-120, 40, 215), (120, 80, 80), dark)
        self.vis('cone16', (130, 40, 215), (140, 90, 80), dark)
        # beş Hokage yüzü (anıt)
        for i, x in enumerate((-56, -28, 0, 28, 56)):
            fz = 160
            self.box((x, 34, fz - 3), (16, 18, 6), '#9a8f7f')
            self.box((x, 44, fz - 2), (17, 4, 7), '#8a7f6f')  # saç çizgisi
            for ex in (-3.5, 3.5):
                self.box((x + ex, 37, fz - 6.1), (3, 1.2, .4), '#4a4238', collide=False)
            self.box((x, 33, fz - 6.6), (2, 4, 1.4), '#9a8f7f', collide=False)  # burun
            self.box((x, 29.5, fz - 6.1), (6, .8, .4), '#4a4238', collide=False)
        # kayalığa çıkan merdiven (doğu)
        for k in range(25):
            self.box((110, k * 2 + 1, 158 + k * 1.2), (8, 2, 3), '#a89b88')

    def hokage_tower(self):
        x, z = 0, 80
        self.cyl(x, z, 14, 0, 22, '#e6d8b8', res=24)
        self.cyl(x, z, 15.5, 22, 2, '#b8332a', res=24)
        self.cyl(x, z, 11, 24, 6, '#e6d8b8', res=24)
        self.vis('cone24', (x, 30, z), (25, 6, 25), '#b8332a')
        self.box((x, 26, z - 11.2), (5, 5, .4), '#b8332a', collide=False)  # "火" levhası
        self.box((x, 2.5, z - 14.2), (5, 5, .6), '#5a3a22', collide=False)  # kapı
        # yan bina
        self.box((28, 6, 82), (24, 12, 18), '#e6d8b8')
        self.box((28, 12.4, 82), (26, .8, 20), '#b8332a')

    def roads(self):
        dirt = '#c8b088'
        self.vis('cube', (0, .01, -40), (12, .04, 230), dirt)
        self.vis('cube', (0, .01, -210), (10, .04, 130), dirt)  # kapıdan dışarı
        for rz in (-60, 0, 40):
            self.vis('cube', (0, .015, rz), (260, .04, 8), dirt)
        for z in range(-140, 70, 10):
            self.road_points.append(Vec3(random.uniform(-4, 4), 0, z))
        for rz in (-60, 0, 40):
            for x in range(-120, 121, 12):
                self.road_points.append(Vec3(x, 0, rz + random.uniform(-2, 2)))

    def ichiraku(self):
        x, z = 16, -40
        self.box((x, .6, z - 1.5), (8, 1.2, 1), '#8a5a32')  # tezgah
        self.box((x, 1.25, z - 1.5), (8.4, .1, 1.4), '#c99a62', collide=False)
        self.box((x, 1.5, z + 2), (8, 3, 4), '#e8ddc4')  # mutfak
        for sx in (-4, 4):
            self.box((x + sx, 1.6, z - 2.2), (.3, 3.2, .3), '#5a3a22')
        self.box((x, 3.3, z), (9.5, .4, 6.5), '#b8332a')  # çatı
        for i in range(6):  # noren perdeler
            self.box((x - 3.3 + i * 1.32, 2.6, z - 2.3), (1.15, 1.0, .05), '#f2f2f2' if i % 2 else '#d84a3a',
                     collide=False)
        for i in range(4):  # tabureler
            self.cyl(x - 3 + i * 2, z - 3, .3, 0, .7, '#b8332a', collide=False)
        state.interactables.append(dict(pos=Vec3(x, 0, z - 3.5), radius=4, kind='ramen',
                                        label='[F] Ramen ye (Can + Chakra dolar)'))

    def academy(self):
        x, z = -55, 60
        self.box((x, 7, z), (40, 14, 16), '#d9c39a')
        self.box((x, 14.5, z), (42, 1, 18), '#b8332a')
        self.box((x, 2.5, z - 8.2), (5, 5, .5), '#5a3a22', collide=False)
        for i in range(8):
            for fl in (4, 10):
                self.box((x - 17 + i * 4.8, fl, z - 8.1), (2, 2, .3), '#5b8fb9', collide=False)
        # bahçedeki salıncaklı ağaç
        tx, tz = x + 14, z - 20
        self.cyl(tx, tz, .8, 0, 7, '#6b4a2b')
        self.vis('sphere', (tx, 9, tz), (9, 6, 9), '#4e8a3a')
        self.box((tx + 3, 5.2, tz), (6, .4, .4), '#6b4a2b')  # dal
        for dz in (-.4, .4):
            self.box((tx + 5, 3.4, tz + dz), (.05, 3.6, .05), '#dddddd', collide=False)
        self.box((tx + 5, 1.6, tz), (.6, .1, 1.1), '#8a5a32', collide=False)
        state.interactables.append(dict(pos=Vec3(tx + 5, 0, tz), radius=3, kind='swing',
                                        label='[F] Salıncağa otur'))

    def training_ground(self):
        x, z = 95, -20
        self.vis('cyl24', (x, .02, z), (50, .04, 50), '#7fae58')
        for i, dx in enumerate((-4, 0, 4)):  # üç kütük
            self.cyl(x + dx, z + 6, .45, 0, 1.6, '#7a5532')
        # dere
        self.vis('cube', (x + 22, .03, z), (6, .04, 60), C('#3d8fd1'))
        # anıt taşı
        self.box((x - 12, 1.5, z + 10), (3, 3, .8), '#7d7d7d')
        self.dummy_spots = [Vec3(x - 8 + i * 4, 0, z - 6) for i in range(5)]

    def uchiha_district(self):
        cx, cz = -100, -65
        for k in range(8):
            a = k * 45 + 22
            hx, hz = cx + 18 * math.sin(math.radians(a)), cz + 18 * math.cos(math.radians(a))
            self.house(hx, hz, 9, 8, 1, '#3a3a44', yaw=a + 180, walls='#d8d0c0', uchiha=True)
        # bölge duvarı (kısmi)
        for k in range(20):
            a = math.radians(k * 18)
            if 160 < k * 18 < 220:
                continue
            self.box((cx + 31 * math.sin(a), 1.8, cz + 31 * math.cos(a)), (10, 3.6, 1), '#d8d0c0', yaw=k * 18)

    def house(self, x, z, w, d, floors, roof, yaw=0, walls=None, uchiha=False):
        h = floors * 4
        walls = walls or random.choice(['#efe6d2', '#e8d9b5', '#f2efe6', '#e0cfa8', '#d6c7a8'])
        self.box((x, h / 2, z), (w, h, d), walls, yaw=yaw)
        self.box((x, h + .3, z), (w + 1, .6, d + 1), roof, yaw=yaw)
        # kapı + pencereler (ön yüz = yerel -z)
        px, pz = self.rot(0, -d / 2 - .05, yaw)
        self.box((x + px, 1.2, z + pz), (1.2, 2.4, .12), '#5a3a22', yaw=yaw, collide=False)
        for fl in range(floors):
            for wx in (-w / 3, w / 3):
                px, pz = self.rot(wx, -d / 2 - .05, yaw)
                self.box((x + px, fl * 4 + 2.4, z + pz), (1.3, 1.1, .12), '#6f9fc7', yaw=yaw, collide=False)
        if uchiha:  # yelpaze arması
            px, pz = self.rot(0, -d / 2 - .08, yaw)
            self.box((x + px, h - 1.2, z + pz), (1.6, 1.0, .1), '#c0302a', yaw=yaw, collide=False)
            self.box((x + px, h - 2.1, z + pz), (1.6, .8, .1), '#f2f2f2', yaw=yaw, collide=False)
        elif random.random() < .55:  # Konoha'nın meşhur çatı su tankları
            tx, tz = self.rot(random.uniform(-w / 4, w / 4), random.uniform(-d / 4, d / 4), yaw)
            self.cyl(x + tx, z + tz, 1.1, h + .6, 2.2, '#9aa3a8', res=10)

    def houses(self):
        roofs = ['#b8332a', '#2e5a8a', '#3f7a3a', '#c7642a', '#7a4a8a', '#a8323a']
        for gx in range(-130, 131, 17):
            for gz in range(-130, 150, 17):
                x, z = gx + random.uniform(-3, 3), gz + random.uniform(-3, 3)
                if math.hypot(x, z) > WALL_R - 12 or z > 140:
                    continue
                if not self.free(x, z, pad=6) or random.random() < .18:
                    continue
                w, d = random.uniform(8, 12), random.uniform(7, 11)
                floors = random.choice([1, 1, 2, 2, 3])
                yaw = random.choice([0, 90, 180, 270])
                self.house(x, z, w, d, floors, random.choice(roofs), yaw=yaw)
        # köy içi birkaç ağaç
        for _ in range(40):
            a, r = random.uniform(0, 6.28), random.uniform(20, WALL_R - 8)
            x, z = r * math.sin(a), r * math.cos(a)
            if self.free(x, z, pad=2) and z < 140:
                self.tree(x, z, random.uniform(.8, 1.2))

    def tree(self, x, z, s=1.0, giant=False):
        trunk_h = 6 * s
        self.cyl(x, z, .45 * s, 0, trunk_h, '#6b4a2b', res=8)
        g = random.choice(['#3f7d32', '#4a8a3a', '#356b2c'])
        self.vis('sphere', (x, trunk_h + 1.5 * s, z), (6 * s, 5 * s, 6 * s), g)
        self.vis('sphere', (x + .8 * s, trunk_h + 3.2 * s, z - .5 * s), (4 * s, 3.5 * s, 4 * s), g)

    def forest(self):
        n = 0
        while n < 380:
            x, z = random.uniform(-285, 285), random.uniform(-285, 285)
            r = math.hypot(x, z)
            if r < WALL_R + 12 or z > 150:
                continue
            if abs(x) < 12 and z < -WALL_R:  # yol
                continue
            if math.hypot(x - 195, z + 120) < 55:  # göl
                continue
            if math.hypot(x + 215, z + 140) < 72:  # ölüm ormanı ayrı
                continue
            self.tree(x, z, random.uniform(1.0, 1.8))
            n += 1

    def forest_of_death(self):
        cx, cz = -215, -140
        # çit
        for k in range(36):
            a = math.radians(k * 10)
            if 40 < k * 10 < 60:  # giriş kapısı
                continue
            self.box((cx + 70 * math.sin(a), 2, cz + 70 * math.cos(a)), (12.5, 4, .5), '#5a4a3a', yaw=k * 10)
        # dev ağaçlar ve üzerinde durulabilen dallar
        for _ in range(26):
            a, r = random.uniform(0, 6.28), random.uniform(8, 62)
            x, z = cx + r * math.sin(a), cz + r * math.cos(a)
            h = random.uniform(35, 55)
            rad = random.uniform(2.2, 3.5)
            self.cyl(x, z, rad, 0, h, '#4a3322', res=12)
            self.vis('sphere', (x, h + 4, z), (26, 14, 26), '#24451f')
            for b in range(3):  # dallar
                ba = random.uniform(0, 360)
                by = random.uniform(10, h - 6)
                L = random.uniform(8, 14)
                bx, bz = self.rot(0, rad + L / 2 - .5, ba)
                self.box((x + bx, by, z + bz), (2.2, 1.4, L), '#4a3322', yaw=ba)
        # karanlık zemin
        self.vis('cyl32', (cx, .02, cz), (140, .04, 140), '#3d5e2e')

    def lake(self):
        cx, cz = 195, -120
        self.water = Entity(model=mdl('cyl32'), position=(cx, .04, cz), scale=(90, .04, 70), color=C('#3d8fd1', .78))
        self.vis('cyl32', (cx, .01, cz), (96, .03, 76), '#c8b088')  # kum kıyı
        # iskele
        self.box((cx - 40, .5, cz), (14, .3, 3), '#8a6a42')
        for k in range(4):
            self.cyl(cx - 46 + k * 4, cz + 1.6, .2, -.5, 1.2, '#6b4a2b', collide=False)
            self.cyl(cx - 46 + k * 4, cz - 1.6, .2, -.5, 1.2, '#6b4a2b', collide=False)

    def boundary_mountains(self):
        for k in range(48):
            a = math.radians(k * 7.5)
            x, z = 330 * math.sin(a), 330 * math.cos(a)
            self.vis('cone16', (x, 0, z), (random.uniform(90, 140), random.uniform(60, 120), 90), '#6f7f63')

    def zone_at(self, p):
        for name, x, z, r in ZONES:
            if math.hypot(p.x - x, p.z - z) < r:
                return name
        return ZONES[-1][0]
