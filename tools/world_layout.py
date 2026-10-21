"""Shinobi dünyasının yerleşimi - Narutopedia canon dünya haritası koordinatlarından (research/geography.json).
Koordinat: x=doğu, y=kuzey (metre). Dönüşüm: x=(gx-48)*72, y=(gy-38)*58. Godot'da konum = Vector3(x, h, -y)."""

WORLD = dict(x0=-3584, x1=4096, y0=-2560, y1=3840, res=4.0)

# kara kütleleri: (merkez x, merkez y, yarıçap x, yarıçap y)
LAND = [
    (194, -500, 1150, 780),        # Ateş Ülkesi
    (-400, -300, 800, 700),        # Ateş batı
    (-662, -1148, 600, 520),       # Nehirler Ülkesi
    (-2167, -900, 1350, 1150),     # Rüzgar Ülkesi
    (-1246, 0, 600, 520),          # Yağmur
    (-1138, 441, 520, 460),        # Çimen
    (-2050, 350, 650, 520),        # Taş köyü sınır toprakları
    (-2110, 2100, 1350, 1150),     # Toprak Ülkesi
    (-648, 1270, 620, 520),        # Şelale
    (259, 1038, 640, 520),         # Ses
    (900, 700, 650, 550),          # Sıcak Su
    (1044, 1241, 560, 460),        # Don (Shimo)
    (2614, 2343, 1150, 950),       # Yıldırım
    (1800, 1700, 750, 520),        # Yıldırım bağlantısı
    (504, 3132, 850, 620),         # Demir
    (-600, 2400, 1050, 750),       # kuzey toprakları
    (-1300, 2900, 900, 500),
    (-1150, 1500, 750, 520),       # Toprak-Şelale bağlantısı
    (250, 2350, 700, 520),         # Demir bağlantısı
    (1150, 2200, 650, 450),
    (-1500, 900, 600, 500),
    # adalar
    (3370, -690, 540, 780),        # Su Ülkesi ana ada
    (2900, -1380, 260, 230),
    (3720, 120, 250, 230),
    (2700, -180, 180, 160),
    (202, -1860, 400, 290),        # Dalga Ülkesi
    (1700, -580, 260, 240),        # Girdap (Uzushio) adası
    (1850, 180, 220, 200),         # Çay adaları
]

COUNTRIES = [
    dict(id='fire', name='Ateş Ülkesi', x=194, y=-560, r=1250, biome='forest', mount=.15),
    dict(id='rivers', name='Nehirler Ülkesi', x=-662, y=-1148, r=480, biome='rock', mount=.45),
    dict(id='wind', name='Rüzgar Ülkesi', x=-2167, y=-900, r=1250, biome='desert', mount=.25),
    dict(id='rain', name='Yağmur Ülkesi', x=-1246, y=0, r=480, biome='rain', mount=.05),
    dict(id='grass', name='Çimen Ülkesi', x=-1138, y=441, r=440, biome='grass', mount=.12),
    dict(id='stone', name='Taş Sınır Toprakları', x=-2050, y=350, r=520, biome='rock', mount=.5),
    dict(id='earth', name='Toprak Ülkesi', x=-2110, y=2100, r=1250, biome='rock', mount=1.0),
    dict(id='waterfall', name='Şelale Ülkesi', x=-648, y=1270, r=500, biome='forest', mount=.45),
    dict(id='sound', name='Ses Ülkesi', x=259, y=1038, r=500, biome='rice', mount=.25),
    dict(id='hotwater', name='Sıcak Su Ülkesi', x=900, y=700, r=520, biome='grass', mount=.4),
    dict(id='frost', name='Don Ülkesi', x=1044, y=1241, r=450, biome='snow', mount=.45),
    dict(id='lightning', name='Yıldırım Ülkesi', x=2614, y=2343, r=1100, biome='mountain', mount=.9),
    dict(id='iron', name='Demir Ülkesi', x=504, y=3132, r=750, biome='snow', mount=.7),
    dict(id='north', name='Kuzey Toprakları', x=-700, y=2600, r=900, biome='rock', mount=.6),
    dict(id='water', name='Su Ülkesi', x=3300, y=-600, r=950, biome='swamp', mount=.3),
    dict(id='waves', name='Dalga Ülkesi', x=202, y=-1860, r=400, biome='forest', mount=.12),
    dict(id='whirlpool', name='Girdap Ülkesi (harabe)', x=1700, y=-580, r=260, biome='grass', mount=.15),
]

VILLAGES = [
    dict(id='konoha', name='Konohagakure', country='fire', x=-50, y=-75, r=430, base=8, kage='Hokage'),
    dict(id='suna', name='Sunagakure', country='wind', x=-1822, y=-1340, r=300, base=14, kage='Kazekage'),
    dict(id='kiri', name='Kirigakure', country='water', x=3204, y=-708, r=270, base=6, kage='Mizukage'),
    dict(id='kumo', name='Kumogakure', country='lightning', x=2261, y=1839, r=300, base=40, kage='Raikage'),
    dict(id='iwa', name='Iwagakure', country='earth', x=-1267, y=1752, r=300, base=45, kage='Tsuchikage'),
    dict(id='ame', name='Amegakure', country='rain', x=-1246, y=-12, r=260, base=5, kage=None),
    dict(id='kusa', name='Kusagakure', country='grass', x=-1138, y=441, r=190, base=12, kage=None),
    dict(id='taki', name='Takigakure', country='waterfall', x=-648, y=1270, r=230, base=16, kage=None),
    dict(id='oto', name='Otogakure', country='sound', x=259, y=1038, r=170, base=12, kage=None),
    dict(id='yu', name='Yugakure', country='hotwater', x=626, y=1015, r=180, base=14, kage=None),
    dict(id='shimo', name='Shimogakure', country='frost', x=1044, y=1241, r=160, base=20, kage=None),
    dict(id='tani', name='Tanigakure', country='rivers', x=-662, y=-1148, r=160, base=10, kage=None),
    dict(id='nami', name='Dalga Kasabası', country='waves', x=202, y=-1860, r=200, base=5, kage=None),
    dict(id='uzushio', name='Uzushiogakure Harabeleri', country='whirlpool', x=1700, y=-580, r=150, base=8, kage=None),
    dict(id='tetsu', name='Demir Kalesi (Samuraylar)', country='iron', x=504, y=3132, r=230, base=30, kage=None),
]

LANDMARKS = [
    dict(id='valley_end', name='Sonun Vadisi', x=120, y=600, r=220),
    dict(id='forest_death', name='Ölüm Ormanı (44. Alan)', x=430, y=-300, r=280),
    dict(id='nara_forest', name='Nara Ormanı', x=-560, y=40, r=200),
    dict(id='sage_falls', name='Gizli Şelale (Sennin Eğitimi)', x=-420, y=-900, r=160),
    dict(id='naruto_bridge', name='Büyük Naruto Köprüsü', x=200, y=-1450, r=60),
    dict(id='hideout', name='Kızıl Bulut Sığınağı', x=-1000, y=260, r=140),
    dict(id='storm_canyon', name='Fırtına Kanyonu (Raijū)', x=1900, y=2050, r=200),
    dict(id='bandit_camp', name='Haydut Kampı', x=650, y=-450, r=120),
    dict(id='border_post', name='Ateş Batı Sınır Karakolu', x=-850, y=-550, r=120),
]

ROADS = [
    ('konoha', 'tani'), ('tani', 'suna'), ('konoha', 'ame'), ('ame', 'kusa'), ('kusa', 'taki'), ('taki', 'iwa'),
    ('konoha', 'valley_end'), ('valley_end', 'oto'), ('oto', 'yu'), ('yu', 'shimo'), ('shimo', 'kumo'),
    ('konoha', 'naruto_bridge'), ('naruto_bridge', 'nami'), ('konoha', 'forest_death'), ('konoha', 'nara_forest'),
    ('konoha', 'bandit_camp'), ('konoha', 'border_post'), ('border_post', 'tani'), ('ame', 'suna'),
    ('oto', 'tetsu'), ('kumo', 'tetsu'), ('kusa', 'hideout'), ('konoha', 'sage_falls'), ('konoha', 'yu'),
]

RIVERS = [
    [(100, 760), (120, 600), (-20, 260), (-260, 60), (-300, -250), (-200, -700), (0, -1100), (120, -1450)],
    [(-648, 1480), (-648, 1270), (-520, 900), (-380, 560), (-260, 60)],
    [(-1246, 320), (-1246, 0), (-1050, -400), (-900, -800), (-662, -1148), (-600, -1550), (-520, -2000)],
    [(2261, 2120), (2261, 1839), (2000, 1500), (1700, 1200), (1500, 900), (1700, 400)],
]
