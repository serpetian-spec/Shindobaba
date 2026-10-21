"""Oyun verileri: klanlar, elementler, mühürler, jutsular, eşyalar, rütbeler, yetenek ağacı.
Kanon karakter YOK - sadece evrenin sistemleri, teknikleri, mekanları."""

# ------------------------------------------------------------------ elementler
ELEMENTS = {
    'katon': dict(name='Katon (Ateş)', col='#ff6a2a'),
    'suiton': dict(name='Suiton (Su)', col='#3d9be0'),
    'fuuton': dict(name='Fuuton (Rüzgar)', col='#a8f0c8'),
    'doton': dict(name='Doton (Toprak)', col='#a07a4a'),
    'raiton': dict(name='Raiton (Yıldırım)', col='#bfe8ff'),
}
# a, b'yi yener
BEATS = {'katon': 'fuuton', 'fuuton': 'raiton', 'raiton': 'doton', 'doton': 'suiton', 'suiton': 'katon'}
# birleşik elementler (kekkei genkai)
COMBINED = {
    'mokuton': dict(name='Mokuton (Odun)', needs=('doton', 'suiton'), col='#8a6a3a'),
    'hyoton': dict(name='Hyoton (Buz)', needs=('fuuton', 'suiton'), col='#cff4ff'),
    'yoton': dict(name='Yoton (Lav)', needs=('katon', 'doton'), col='#ff4a1a'),
    'ranton': dict(name='Ranton (Fırtına)', needs=('raiton', 'suiton'), col='#9ad8ff'),
}


def element_mult(atk, dfn):
    if not atk or not dfn:
        return 1.0
    if BEATS.get(atk) == dfn:
        return 1.5
    if BEATS.get(dfn) == atk:
        return .75
    return 1.0


# ------------------------------------------------------------------ mühürler (12)
SEALS = ['Ne', 'Ushi', 'Tora', 'U', 'Tatsu', 'Mi', 'Uma', 'Hitsuji', 'Saru', 'Tori', 'Inu', 'I']
SEAL_TR = {'Ne': 'Fare', 'Ushi': 'Öküz', 'Tora': 'Kaplan', 'U': 'Tavşan', 'Tatsu': 'Ejderha', 'Mi': 'Yılan',
           'Uma': 'At', 'Hitsuji': 'Koç', 'Saru': 'Maymun', 'Tori': 'Horoz', 'Inu': 'Köpek', 'I': 'Domuz'}
# mühür modunda tuşlar: 1..9, 0, -, =
SEAL_KEYS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=']

# ------------------------------------------------------------------ klanlar
CLANS = {
    'none': dict(name='Klansız', desc='Saf çaba. Taijutsu +%15, Sekiz Kapı açılabilir.', eye='#3a2a1a',
                 dojutsu=None, jutsu=['hachimon']),
    'uchiha': dict(name='Uchiha', desc='Sharingan: zamanı yavaş görür, Katon ustalığı.', eye='#c0202a',
                   dojutsu='sharingan', jutsu=['katon_goukakyuu'], element_bonus='katon'),
    'hyuga': dict(name='Hyuga', desc='Byakugan: duvar arkasını görür. Yumuşak Yumruk, Kaiten.', eye='#e8e8f4',
                  dojutsu='byakugan', jutsu=['juuken_64', 'kaiten']),
    'nara': dict(name='Nara', desc='Gölge Taklidi: rakibi yerine çiviler.', eye='#2a2a2a',
                 dojutsu=None, jutsu=['kagemane', 'kage_kubi']),
    'akimichi': dict(name='Akimichi', desc='Baika: devleşir (dev hitbox!), Nikudan yuvarlanma.', eye='#3a2a1a',
                     dojutsu=None, jutsu=['baika', 'nikudan']),
    'aburame': dict(name='Aburame', desc='Kikaichu böcek sürüsü: chakra emer.', eye='#222222',
                    dojutsu=None, jutsu=['mushi_swarm']),
    'inuzuka': dict(name='Inuzuka', desc='Ninken yoldaşı, Gatsuga matkap saldırısı.', eye='#6a3a1a',
                    dojutsu=None, jutsu=['gatsuga'], companion='ninken'),
    'yamanaka': dict(name='Yamanaka', desc='Shintenshin: düşmanı kontrol eder.', eye='#5ab0d0',
                     dojutsu=None, jutsu=['shintenshin']),
    'senju': dict(name='Senju', desc='Mokuton (Odun) ve yüksek yaşam gücü.', eye='#3a2a1a',
                  dojutsu=None, jutsu=['mokuton_spikes', 'mokuton_wall'], hp_bonus=40),
    'yuki': dict(name='Yuki', desc='Hyoton (Buz) iğneleri ve buz mızrakları.', eye='#7aa8c8',
                 dojutsu=None, jutsu=['hyoton_senbon', 'hyoton_spears']),
    'kaguya': dict(name='Kaguya', desc='Shikotsumyaku: kemik mermi ve kemik zırh.', eye='#7a4a8a',
                   dojutsu=None, jutsu=['bone_bullets', 'bone_armor']),
}

HAIR_STYLES = ['diken', 'kısa', 'uzun', 'atkuyruğu', 'kase', 'dağınık']
HAIR_COLORS = ['#5a3a22', '#1a1a1a', '#e8c040', '#c84a2a', '#e8e8e8', '#3a4a8a', '#d890b0', '#3a6a3a']
OUTFIT_COLORS = ['#24324f', '#3a3a3a', '#5a2a2a', '#2a4a2a', '#4a3a5a', '#d8d0c0', '#7a5a2a', '#2a5a6a']

# ------------------------------------------------------------------ rütbeler
RANKS = ['Akademi Öğrencisi', 'Genin', 'Chunin', 'Jonin', 'ANBU']
RANK_REQ = {
    'Genin': 'Akademi mezuniyet sınavını geç (Akademi binası).',
    'Chunin': 'Seviye 10 + Chunin Sınavını kazan (Stadyum).',
    'Jonin': 'Seviye 20 + 3 A-rank görev tamamla.',
    'ANBU': 'Seviye 30 + 1 S-rank görev tamamla (ANBU Karargâhı).',
}
MISSION_RANKS_FOR = {0: ['D'], 1: ['D', 'C'], 2: ['C', 'B'], 3: ['B', 'A'], 4: ['A', 'S']}


def xp_for_level(lv):
    return int(80 * lv ** 1.45)


# ------------------------------------------------------------------ jutsular
# kind: proj | dash | aoe | buff | summon | special
# req: rank index, level, element/clan/skill
J = {}


def jutsu(id, name, cost, cd, seals, element=None, clan=None, level=1, rank=0, desc='', skill=None, cast=.0):
    J[id] = dict(id=id, name=name, cost=cost, cd=cd, seals=seals, element=element, clan=clan, level=level,
                 rank=rank, desc=desc, skill=skill, cast=cast)


# akademi / genel
jutsu('bunshin', 'Kage Bunshin', 40, 10, ['Hitsuji', 'Mi', 'Tora'], level=3, rank=1, desc='3 gölge klon savaşır.')
jutsu('henge', 'Henge (Dönüşüm)', 15, 20, ['Inu', 'I', 'Hitsuji'], desc='Köylü kılığı: düşmanlar seni fark etmez.')
jutsu('shunshin', 'Shunshin (Işınlanma)', 12, 3, ['Tora'], level=2, desc='Baktığın yöne anında 14m ışınlan.')
jutsu('rasengan', 'Rasengan', 30, 6, [], level=8, rank=1, desc='Mühürsüz sarmal chakra küresi.')
jutsu('kuchiyose', 'Kuchiyose (Çağırma)', 60, 45, ['I', 'Inu', 'Tori', 'Saru', 'Hitsuji'], level=12, rank=2,
      desc='Sözleşmeli dev hayvanı çağırır.', skill='contract')
jutsu('shousen', 'Shousen (Tıbbi)', 25, 8, ['Tori', 'Hitsuji'], level=4, desc='Kendini ve yakındakileri iyileştir.',
      skill='medic')
jutsu('narakumi', 'Magen: Narakumi', 25, 12, ['Ne', 'U', 'I'], level=6, desc='Genjutsu: hedef 3sn dehşetle donar.',
      skill='genjutsu')
jutsu('kokuangyo', 'Kokuangyo (Karanlık)', 35, 20, ['Tori', 'Ushi', 'Tora'], level=14, rank=2,
      desc='Genjutsu: çevredeki düşmanlar seni kaybeder.', skill='genjutsu')
# katon
jutsu('katon_goukakyuu', 'Katon: Goukakyuu', 25, 4, ['Mi', 'Hitsuji', 'Saru', 'I', 'Uma', 'Tora'], 'katon',
      desc='Büyük ateş topu, patlar ve yakar.')
jutsu('katon_housenka', 'Katon: Housenka', 20, 5, ['Ne', 'Tora', 'Inu', 'Ushi', 'U', 'Tora'], 'katon', level=5,
      desc='Hedefe yönelen 5 küçük alev.')
jutsu('katon_karyuu', 'Katon: Karyuu Endan', 40, 10, ['Mi', 'Tatsu', 'U', 'Tora'], 'katon', level=15, rank=2,
      desc='Ejderha alevi püskürtme (koni).')
# suiton
jutsu('suiton_suiryuudan', 'Suiton: Suiryuudan', 35, 7, ['Ushi', 'Saru', 'U', 'Ne', 'I', 'Tori'], 'suiton',
      desc='Su ejderhası, havaya fırlatır.')
jutsu('suiton_suijinheki', 'Suiton: Suijinheki', 25, 12, ['Ushi', 'U', 'Saru'], 'suiton', level=5,
      desc='Su duvarı: mermileri durdurur.')
jutsu('suiton_suikoudan', 'Suiton: Suikoudan', 40, 9, ['Tora', 'Ushi', 'Tatsu', 'U', 'Tori'], 'suiton', level=15,
      rank=2, desc='Hedefe yönelen su köpekbalığı.')
# fuuton
jutsu('fuuton_daitoppa', 'Fuuton: Daitoppa', 20, 5, ['Tora', 'Ushi', 'Inu', 'U', 'Mi'], 'fuuton',
      desc='Önündeki her şeyi uçuran rüzgar.')
jutsu('fuuton_shinkuu', 'Fuuton: Shinkuu Gyoku', 25, 5, ['Tora', 'Tori'], 'fuuton', level=5,
      desc='Ardı ardına vakum mermileri.')
jutsu('fuuton_rasenshuriken', 'Fuuton: Rasenshuriken', 70, 18, [], 'fuuton', level=25, rank=3,
      desc='Fırlatılan dev rüzgar shurikeni.')
# doton
jutsu('doton_doryuheki', 'Doton: Doryuheki', 20, 8, ['Tora', 'U', 'I', 'Inu'], 'doton',
      desc='Önüne toprak duvar diker (tırmanılabilir!).')
jutsu('doton_doryuusou', 'Doton: Doryuusou', 25, 6, ['Tora', 'Ushi', 'Tori'], 'doton', level=5,
      desc='Yerden fışkıran toprak mızraklar.')
jutsu('doton_yomi', 'Doton: Yomi Numa', 35, 14, ['Tora', 'Saru', 'U', 'Tatsu'], 'doton', level=15, rank=2,
      desc='Bataklık: düşmanlar yavaşlar.')
# raiton
jutsu('raiton_chidori', 'Chidori', 30, 6, ['Ushi', 'U', 'Saru'], 'raiton', desc='Yıldırım hücumu, deler.')
jutsu('raiton_nagashi', 'Chidori Nagashi', 25, 8, ['Ushi', 'U'], 'raiton', level=5, desc='Çevreye elektrik: sersemletir.')
jutsu('raiton_armor', 'Raiton no Yoroi', 45, 25, ['Ushi', 'Tora', 'Saru'], 'raiton', level=15, rank=2,
      desc='Yıldırım zırhı: hız ve hasar.')
# birleşik
jutsu('mokuton_spikes', 'Mokuton: Ağaç Mızraklar', 35, 7, ['Tori', 'Ushi', 'Tatsu'], 'mokuton', desc='Odun dikenleri.')
jutsu('mokuton_wall', 'Mokuton: Odun Kalkan', 30, 14, ['Ushi', 'Tora'], 'mokuton', level=5, desc='Odun kubbe.')
jutsu('hyoton_senbon', 'Hyoton: Buz İğneleri', 25, 4, ['Hitsuji', 'Tatsu'], 'hyoton', desc='Buz iğnesi yağmuru.')
jutsu('hyoton_spears', 'Hyoton: Buz Mızrakları', 35, 8, ['Ne', 'Mi', 'Tora'], 'hyoton', level=5,
      desc='Yerden buz, dondurur.')
jutsu('yoton_lava', 'Yoton: Lav Topları', 35, 6, ['Uma', 'Tora', 'I'], 'yoton', desc='Yakıcı lav topları.')
jutsu('ranton_laser', 'Ranton: Fırtına Işını', 40, 7, ['Ushi', 'Tatsu', 'Tori'], 'ranton', desc='Kıvrılan ışın.')
# klan
jutsu('hachimon', 'Sekiz Kapı (Hachimon)', 0, 30, [], clan='none', level=6, desc='Hız ve hasar, canın erir.')
jutsu('juuken_64', 'Hakke 64 Şō', 30, 8, [], clan='hyuga', desc='64 avuç darbesi, chakra kapatır.')
jutsu('kaiten', 'Hakkeshō Kaiten', 25, 7, [], clan='hyuga', level=4, desc='Dönen chakra kalkanı, iter.')
jutsu('kagemane', 'Kagemane (Gölge Taklidi)', 25, 10, ['Ne'], clan='nara', desc='Önündeki hedefi 4sn kilitler.')
jutsu('kage_kubi', 'Kage Kubi Shibari', 30, 10, ['Ne', 'Mi'], clan='nara', level=6, desc='Gölge boğma (hasar).')
jutsu('baika', 'Baika (Devleşme)', 30, 25, ['Ne'], clan='akimichi', desc='3 kat büyür, hitbox da büyür!')
jutsu('nikudan', 'Nikudan Sensha', 25, 8, [], clan='akimichi', level=4, desc='Dev top olup ezerek yuvarlan.')
jutsu('mushi_swarm', 'Kikaichu Sürüsü', 25, 7, ['Ne'], clan='aburame', desc='Böcekler chakra emer.')
jutsu('gatsuga', 'Gatsuga', 25, 6, ['Inu'], clan='inuzuka', desc='Dönen matkap hücumu.')
jutsu('shintenshin', 'Shintenshin', 40, 25, ['Ne', 'Mi'], clan='yamanaka', desc='Düşmanı ele geçir, savaştır.')
jutsu('bone_bullets', 'Teshi Sendan', 20, 3, [], clan='kaguya', desc='Parmak kemiği mermileri.')
jutsu('bone_armor', 'Kemik Zırh', 30, 20, [], clan='kaguya', level=4, desc='Gelen hasar %50 azalır.')
# özel modlar
jutsu('sharingan', 'Sharingan', 0, 2, [], clan='uchiha', desc='Aç/kapa (V).')
jutsu('byakugan', 'Byakugan', 0, 2, [], clan='hyuga', desc='Aç/kapa (V).')
jutsu('rinnegan_shinra', 'Shinra Tensei', 50, 15, [], level=35, desc='Rinnegan: her şeyi iter.', skill='rinnegan')
jutsu('rinnegan_banshou', 'Banshou Ten\'in', 30, 8, [], level=35, desc='Rinnegan: hedefi çeker.', skill='rinnegan')
jutsu('sage_mode', 'Sennin Modu', 0, 60, [], level=20, desc='Doğa enerjisi (Z).', skill='sage')
jutsu('jinchuriki', 'Kuyruklu Canavar Modu', 0, 90, [], level=30, desc='Raijū\'nun gücü (X).', skill='jinchuriki')

DOJUTSU_IDS = {'sharingan', 'byakugan', 'sage_mode', 'jinchuriki', 'hachimon'}

# ------------------------------------------------------------------ eşyalar
ITEMS = {
    'kunai': dict(name='Kunai', price=10, kind='throw', desc='Fırlat (R).'),
    'shuriken': dict(name='Shuriken', price=8, kind='throw', desc='3\'lü yelpaze atış.'),
    'tag': dict(name='Patlayıcı Etiketli Kunai', price=40, kind='throw', desc='Saplandığı yerde patlar.'),
    'smoke': dict(name='Duman Bombası', price=30, kind='throw', desc='Düşmanlar seni kaybeder.'),
    'salve': dict(name='Şifalı Merhem', price=35, kind='use', desc='+45 can (H).'),
    'pill': dict(name='Asker Hapı', price=60, kind='use', desc='+60 chakra ve 15sn güç (Y).'),
    'ramen_kupon': dict(name='Ramen Kuponu', price=0, kind='misc', desc='Ichiraku\'da bedava ramen.'),
    'herb': dict(name='Şifalı Ot', price=0, kind='quest', sell=5, desc='Görev eşyası.'),
    'package': dict(name='Teslimat Paketi', price=0, kind='quest', desc='Görev eşyası.'),
    'scroll': dict(name='Gizli Parşömen', price=0, kind='quest', sell=50, desc='Değerli parşömen.'),
}
THROWABLES = ['kunai', 'shuriken', 'tag', 'smoke']
SHOP_WEAPONS = ['kunai', 'shuriken', 'tag', 'smoke', 'salve', 'pill']

# ------------------------------------------------------------------ yetenek ağacı
# id: (isim, açıklama, kategori, ön koşul, seviye)
SKILLS = {
    # Taijutsu
    'tai1': ('Demir Yumruk', 'Yakın dövüş hasarı +%20', 'Taijutsu', None, 1),
    'tai2': ('Rüzgar Adım', 'Koşu hızı +%15', 'Taijutsu', 'tai1', 4),
    'tai3': ('Kasırga Tekme', 'Kombo 4. vuruş: alan tekmesi', 'Taijutsu', 'tai2', 8),
    'tai4': ('Usta Savaşçı', 'Yakın dövüş hasarı +%30', 'Taijutsu', 'tai3', 16),
    # Ninjutsu
    'nin1': ('Chakra Kontrolü', 'Jutsu maliyeti -%10', 'Ninjutsu', None, 1),
    'nin2': ('Geniş Chakra', 'Maks chakra +40', 'Ninjutsu', 'nin1', 4),
    'nin3': ('Hızlı Mühür', 'Mühür süresi -%40', 'Ninjutsu', 'nin2', 8),
    'nin4': ('Jutsu Ustası', 'Jutsu hasarı +%30', 'Ninjutsu', 'nin3', 16),
    'elem2': ('İkinci Element', 'Yeni bir element seç (Chunin)', 'Ninjutsu', 'nin2', 10),
    'elem3': ('Üçüncü Element', 'Bir element daha (Jonin)', 'Ninjutsu', 'elem2', 20),
    'kekkei': ('Kekkei Genkai Parşömeni', 'İki elementi birleştir (Jonin)', 'Ninjutsu', 'elem2', 22),
    # Destek
    'vit1': ('Dayanıklılık', 'Maks can +30', 'Destek', None, 1),
    'medic': ('Tıbbi Ninjutsu', 'Shousen jutsusu', 'Destek', 'vit1', 4),
    'genjutsu': ('Genjutsu Eğitimi', 'Genjutsu tekniklerini aç', 'Destek', None, 5),
    'vit2': ('Yenilenme', 'Can ve chakra yenilenmesi x2', 'Destek', 'vit1', 10),
    'contract': ('Çağırma Sözleşmesi', 'Kuchiyose (dev hayvan)', 'Destek', 'vit1', 12),
    # Efsane
    'sage': ('Sennin Eğitimi', 'Gizli Şelale\'de doğa enerjisi öğren', 'Efsane', None, 20),
    'jinchuriki': ('Mühürlü Canavar', 'Raijū\'yu yen ve mühürle', 'Efsane', None, 30),
    'rinnegan': ('Altı Yolun Gözü', 'Sonun Vadisi\'nde uyanış', 'Efsane', None, 35),
}
# Efsane yetenekler yetenek puanıyla değil görevle açılır
QUEST_SKILLS = {'sage', 'jinchuriki', 'rinnegan'}

SUMMONS = {
    'kurbağa': dict(name='Dev Kurbağa', col='#c8603a'),
    'yılan': dict(name='Dev Yılan', col='#7a5aa8'),
    'sümüklü': dict(name='Dev Sümüklü Böcek', col='#e0e8f0'),
    'köpek': dict(name='Ninken Sürüsü', col='#8a6a4a'),
}
