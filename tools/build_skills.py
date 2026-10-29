"""Yetenek ağacı verisi -> godot/data/skills.json
Her düğüm: id, ad, açıklama, dal, kademe (satır), maliyet (puan), seviye şartı, ön şartlar, etkiler (fx), ek şartlar (need).
fx anahtarları (toplanır): hp, chakra (düz); melee, jutsu, speed, regen_chakra, regen_hp, jutsu_cost (-), seal_speed, wall_run,
leap, air_dash (+adet), jumps (+adet), water_cost (-), guard, def, throw_dmg, w_<stil>, el_<doğa>, kg, gen_power, gen_resist,
heal, poison_resist, sage_time, summon_cost (-), summon_power, eye_cost (-), shop (-), xp, ryo, stealth, sense, squad, combo.
unlock: oyun bayrakları (genjutsu, kai, gentle_fist, strong_fist, gates, elem2, elem3, barrier, scroll_store, scalpel, ...)."""
import json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
N = []


def node(br, nid, name, desc, tier, lvl, req=(), fx=None, cost=1, need=None, unlock=None, icon=None):
    N.append(dict(id=nid, name=name, desc=desc, branch=br, tier=tier, cost=cost, level=lvl, req=list(req),
                  fx=fx or {}, need=need or {}, unlock=unlock or [], icon=icon or ''))


# ---------------------------------------------------------------- Taijutsu
B = 'taijutsu'
node(B, 'tai1', 'Demir Yumruk', 'Yakın dövüş hasarı +%20.', 1, 1, fx={'melee': 0.2})
node(B, 'tai_kombo1', 'Akıcı Kombo', 'Kombo adımları arası bekleme kısalır, yakın dövüş +%5.', 1, 3, fx={'melee': 0.05, 'combo': 0.1})
node(B, 'tai2', 'Rüzgar Adım', 'Koşu hızı +%12.', 2, 4, ['tai1'], fx={'speed': 0.12})
node(B, 'tai_govde', 'Çelik Beden', 'Alınan hasar -%5, maks can +30.', 2, 6, ['tai1'], fx={'def': 0.05, 'hp': 30})
node(B, 'tai_guard', 'Kusursuz Blok', 'Blokta alınan hasar -%30 daha az.', 2, 8, ['tai_kombo1'], fx={'guard': 0.3})
node(B, 'strong_fist', 'Güçlü Yumruk Stili', 'Kemik kıran sert darbeler: yakın dövüş +%15, sersemletme gücü artar.', 3, 12, ['tai2', 'tai_govde'], fx={'melee': 0.15}, unlock=['strong_fist'])
node(B, 'gentle_fist', 'Yumuşak Yumruk Stili', 'Chakra noktalarına vuruş: darbeler chakra çalar, yakın dövüş +%10.', 3, 12, ['tai_guard'], fx={'melee': 0.1}, need={'clan_any': ['hyuga'], 'or_eye': 2}, unlock=['gentle_fist'])
node(B, 'tai_kombo2', 'Uzun Kombo', 'Kombo hızlanır ve son vuruş daha uzağa fırlatır, +%10 yakın dövüş.', 3, 15, ['tai_kombo1'], fx={'melee': 0.1, 'combo': 0.15})
node(B, 'tai4', 'Usta Savaşçı', 'Yakın dövüş hasarı +%30.', 4, 16, ['strong_fist'], fx={'melee': 0.3}, cost=2)
node(B, 'gates1', 'Kapı Ustalığı I', 'Sekiz Kapı açıkken can kaybı -%30.', 4, 20, ['tai2'], fx={'gates': 0.3}, unlock=['gates'])
node(B, 'gates2', 'Kapı Ustalığı II', 'Kapılar daha uzun dayanır, kapı modunda hız +%15.', 5, 45, ['gates1'], fx={'gates': 0.3, 'speed': 0.05}, cost=2)
node(B, 'tai_lotus', 'Ön Lotus', 'Havaya fırlatılan düşmana yakın dövüş +%20.', 5, 35, ['tai4'], fx={'melee': 0.1}, cost=2, unlock=['lotus'])
node(B, 'tai_master', 'Taijutsu Efsanesi', 'Yakın dövüş +%35, koşu hızı +%8.', 6, 70, ['tai_lotus'], fx={'melee': 0.35, 'speed': 0.08}, cost=3)

# ---------------------------------------------------------------- Ninjutsu
B = 'ninjutsu'
node(B, 'nin1', 'Chakra Kontrolü', 'Jutsu maliyeti -%10.', 1, 1, fx={'jutsu_cost': -0.1})
node(B, 'nin2', 'Geniş Chakra', 'Maks chakra +50.', 2, 4, ['nin1'], fx={'chakra': 50})
node(B, 'nin3', 'Hızlı Mühür', 'Mühür süresi -%40.', 2, 8, ['nin1'], fx={'seal_speed': 0.4})
node(B, 'nin_el1', 'Doğa Ustalığı I', 'Ana chakra doğanın jutsuları +%15.', 2, 6, ['nin1'], fx={'el_main': 0.15})
node(B, 'elem2', 'İkinci Element', 'Yeni bir chakra doğası öğren (Chunin).', 3, 12, ['nin2'], need={'rank': 2}, unlock=['elem2'], cost=2)
node(B, 'nin_kontrol2', 'Kusursuz Kontrol', 'Jutsu maliyeti -%10 daha, chakra yenilenmesi +%25.', 3, 14, ['nin3'], fx={'jutsu_cost': -0.1, 'regen_chakra': 0.25})
node(B, 'nin_el2', 'Doğa Ustalığı II', 'Tüm element jutsuları +%10.', 3, 18, ['nin_el1'], fx={'el_all': 0.1})
node(B, 'nin4', 'Jutsu Ustası', 'Jutsu hasarı +%30.', 4, 16, ['nin3'], fx={'jutsu': 0.3}, cost=2)
node(B, 'nin_tek_el', 'Tek El Mühürü', 'Mühürler yarı sürede, savaş içinde bile.', 4, 30, ['nin3'], fx={'seal_speed': 0.3}, cost=2)
node(B, 'elem3', 'Üçüncü Element', 'Üçüncü chakra doğası (Jonin).', 5, 45, ['elem2'], need={'rank': 3}, unlock=['elem3'], cost=3)
node(B, 'kg1', 'Kekkei Genkai Ustalığı', 'Kekkei genkai jutsuları +%25, maliyeti -%10.', 5, 30, ['nin_el2'], fx={'kg': 0.25}, need={'kg': True}, cost=2)
node(B, 'nin_rasen', 'Şekil Dönüşümü', 'Şekil ustalığı: tüm jutsular +%15, mühürsüz küre teknikleri.', 5, 40, ['nin4'], fx={'jutsu': 0.15}, cost=2, unlock=['shape'])
node(B, 'nin_chakra3', 'Chakra Okyanusu', 'Maks chakra +150, yenilenme +%30.', 6, 60, ['nin_kontrol2'], fx={'chakra': 150, 'regen_chakra': 0.3}, cost=3)
node(B, 'nin_master', 'Ninjutsu Efsanesi', 'Jutsu hasarı +%40.', 6, 80, ['nin_rasen'], fx={'jutsu': 0.4}, cost=3)

# ---------------------------------------------------------------- Genjutsu
B = 'genjutsu'
node(B, 'genjutsu', 'Genjutsu Eğitimi', 'Genjutsu tekniklerini öğrenebilirsin.', 1, 5, unlock=['genjutsu'])
node(B, 'gen_kai', 'Kai!', 'Chakra akışını bozarak genjutsudan kurtul: genjutsu etkisi -%50.', 1, 5, fx={'gen_resist': 0.5}, unlock=['kai'])
node(B, 'gen_guc1', 'Yanılsama Gücü', 'Genjutsu süresi ve hasarı +%20.', 2, 10, ['genjutsu'], fx={'gen_power': 0.2})
node(B, 'gen_irade', 'Sarsılmaz İrade', 'Genjutsu ve sersemletme direnci +%25.', 2, 12, ['gen_kai'], fx={'gen_resist': 0.25})
node(B, 'gen_ses', 'Ses Genjutsusu', 'Genjutsu alanı genişler, +%15 güç.', 3, 20, ['gen_guc1'], fx={'gen_power': 0.15})
node(B, 'gen_ayna', 'Yansıtma', 'Sana yapılan genjutsuyu bazen yansıtırsın.', 3, 28, ['gen_irade'], fx={'gen_resist': 0.15}, unlock=['gen_reflect'], cost=2)
node(B, 'gen_usta', 'Yanılsamaların Efendisi', 'Genjutsu gücü +%40, maliyeti -%15.', 4, 50, ['gen_ses', 'gen_ayna'], fx={'gen_power': 0.4, 'jutsu_cost': -0.05}, cost=3)

# ---------------------------------------------------------------- Bukijutsu (silah)
B = 'bukijutsu'
node(B, 'buki_atis1', 'Keskin Nişan', 'Kunai/shuriken hasarı +%25.', 1, 2, fx={'throw_dmg': 0.25})
node(B, 'buki_blade', 'Bıçak Ustalığı', 'Kunai, tantō, muşta hasarı +%15.', 1, 4, fx={'w_blade': 0.15, 'w_dual': 0.1})
node(B, 'buki_sword', 'Kenjutsu', 'Kılıç hasarı +%20.', 2, 10, ['buki_blade'], fx={'w_sword': 0.2})
node(B, 'buki_heavy', 'Dev Silahlar', 'Ağır silah hasarı +%20.', 2, 14, ['buki_blade'], fx={'w_heavy': 0.2})
node(B, 'buki_staff', 'Sopa ve Mızrak', 'Sopa/mızrak hasarı +%20.', 2, 10, ['buki_blade'], fx={'w_staff': 0.2})
node(B, 'buki_chain', 'Zincir ve Orak', 'Kusarigama/orak hasarı +%20.', 2, 12, ['buki_blade'], fx={'w_chain': 0.2, 'w_sickle': 0.2})
node(B, 'buki_tel', 'Tel Ustalığı', 'Kunai atışları hedefi bağlar, atış +%15.', 3, 16, ['buki_atis1'], fx={'throw_dmg': 0.15}, unlock=['wire'])
node(B, 'buki_fan', 'Yelpaze Sanatı', 'Yelpaze ve pençe hasarı +%20.', 3, 18, ['buki_staff'], fx={'w_fan': 0.2, 'w_claw': 0.2})
node(B, 'buki_kanal', 'Chakra Akıtma', 'Silahlarına chakra akıt: tüm silahlar +%15.', 4, 30, ['buki_sword'], fx={'w_all': 0.15}, cost=2)
node(B, 'buki_yagmur', 'Silah Yağmuru', 'Atış hasarı +%30, tek seferde çok atış.', 4, 35, ['buki_tel'], fx={'throw_dmg': 0.3}, cost=2, unlock=['multi_throw'])
node(B, 'buki_master', 'Silah Efendisi', 'Tüm silahlar +%30.', 5, 65, ['buki_kanal'], fx={'w_all': 0.3}, cost=3)

# ---------------------------------------------------------------- Fūinjutsu
B = 'fuinjutsu'
node(B, 'fuin1', 'Mühür Temelleri', 'Patlayıcı mühür hasarı +%20, mühür parşömenleri ucuzlar.', 1, 8, fx={'tag_dmg': 0.2, 'shop': -0.03})
node(B, 'fuin_depo', 'Parşömen Deposu', 'Çantaya ekstra alet sığar (+%50 taşıma).', 2, 12, ['fuin1'], fx={'carry': 0.5}, unlock=['scroll_store'])
node(B, 'fuin_bariyer', 'Bariyer Mühürü', 'Kısa süreli koruyucu bariyer, savunma +%5.', 2, 16, ['fuin1'], fx={'def': 0.05}, unlock=['barrier'])
node(B, 'fuin_tuzak', 'Mühür Tuzakları', 'Tuzak hasarı +%30.', 3, 22, ['fuin1'], fx={'tag_dmg': 0.3})
node(B, 'fuin_isinlan', 'Işınlanma İşareti', 'İşaretli kunaiye ışınlanma (mühür bilgisi).', 4, 40, ['fuin_bariyer'], unlock=['mark_teleport'], cost=2)
node(B, 'fuin_master', 'Mühür Ustası', 'Mühür jutsuları +%40, savunma +%5.', 5, 60, ['fuin_isinlan', 'fuin_tuzak'], fx={'fuin': 0.4, 'def': 0.05}, cost=3)

# ---------------------------------------------------------------- Tıbbi
B = 'iryo'
node(B, 'med1', 'İlk Yardım', 'Merhem ve iyileştirme +%25.', 1, 4, fx={'heal': 0.25})
node(B, 'vit1', 'Dayanıklılık', 'Maks can +40.', 1, 1, fx={'hp': 40})
node(B, 'vit2', 'Yenilenme', 'Chakra yenilenmesi x2.', 2, 10, ['vit1'], fx={'regen_chakra': 1.0})
node(B, 'med_zehir', 'Panzehir Bilgisi', 'Zehir ve yanma etkisi -%50.', 2, 10, ['med1'], fx={'poison_resist': 0.5})
node(B, 'med_can', 'Hücre Yenileme', 'Can yenilenmesi x2, iyileştirme +%15.', 3, 18, ['med1', 'vit1'], fx={'regen_hp': 1.0, 'heal': 0.15})
node(B, 'scalpel', 'Chakra Neşteri', 'Elinde chakra bıçağı: yakın dövüş +%10, kesikler zırhı deler.', 3, 22, ['med_zehir'], fx={'melee': 0.1}, unlock=['scalpel'], cost=2)
node(B, 'med_ust', 'Usta Tıbbi Ninja', 'İyileştirme +%40, maks can +60.', 4, 40, ['med_can'], fx={'heal': 0.4, 'hp': 60}, cost=2)
node(B, 'med_yuz', 'Yüz Mühürü', 'Biriktirilmiş chakra ile can yenilenmesi x3.', 5, 70, ['med_ust'], fx={'regen_hp': 2.0, 'chakra': 50}, cost=3, unlock=['byakugou'])

# ---------------------------------------------------------------- Sennin / Çağırma
B = 'senjutsu'
node(B, 'sum1', 'Çağırma Ustalığı', 'Çağırma maliyeti -%15.', 1, 12, fx={'summon_cost': -0.15})
node(B, 'sum2', 'Güçlü Çağrılar', 'Çağrıların hasarı ve canı +%25.', 2, 20, ['sum1'], fx={'summon_power': 0.25})
node(B, 'sum3', 'Kardeşlik Bağı', 'Çağrılar daha uzun kalır, maliyet -%15.', 3, 30, ['sum2'], fx={'summon_cost': -0.15, 'summon_power': 0.15})
node(B, 'sage1', 'Doğal Enerji Hissi', 'Sennin modu süresi +%30.', 2, 40, ['sum1'], fx={'sage_time': 0.3})
node(B, 'sage2', 'Hareketsiz Dinginlik', 'Doğal enerji daha hızlı toplanır, sennin süresi +%30.', 3, 50, ['sage1'], fx={'sage_time': 0.3}, cost=2)
node(B, 'sage3', 'Kusursuz Sennin', 'Sennin modunda tüm hasar +%20.', 4, 70, ['sage2'], fx={'sage_power': 0.2}, cost=3)

# ---------------------------------------------------------------- Shinobi (hareket, gizlilik)
B = 'shinobi'
node(B, 'shi_parkur1', 'Duvar Koşucusu', 'Duvarda koşma hızı +%20.', 1, 2, fx={'wall_run': 0.2})
node(B, 'shi_leap1', 'Uzun Sıçrayış', 'Ctrl süper zıplama mesafesi +%15.', 1, 3, fx={'leap': 0.15})
node(B, 'shi_gizli1', 'Sessiz Adım', 'Gizlilik: düşmanlar seni %20 daha geç fark eder.', 1, 5, fx={'stealth': 0.2})
node(B, 'shi_hiss1', 'Chakra Algısı', 'Algılama mesafesi +%25.', 2, 8, ['shi_gizli1'], fx={'sense': 0.25})
node(B, 'shi_dash', 'Çift Hava Atılması', 'Havada bir atılma daha.', 2, 10, ['shi_parkur1'], fx={'air_dash': 1}, cost=2)
node(B, 'shi_su', 'Su Yürüyüşü Ustalığı', 'Su üstünde durmak %60 daha az chakra harcar.', 2, 8, ['shi_parkur1'], fx={'water_cost': -0.6})
node(B, 'shi_leap2', 'Kuş Gibi', 'Ctrl süper zıplama mesafesi +%25 daha.', 3, 18, ['shi_leap1'], fx={'leap': 0.25}, cost=2)
node(B, 'shi_jump3', 'Üçlü Zıplama', 'Havada bir zıplama daha.', 3, 22, ['shi_dash'], fx={'jumps': 1}, cost=2)
node(B, 'shi_hiz', 'Shunshin Ayakları', 'Koşu hızı +%10.', 3, 25, ['shi_parkur1'], fx={'speed': 0.1})
node(B, 'shi_gizli2', 'Gölge Gibi', 'Gizlilik +%35, arkadan saldırı +%25.', 4, 35, ['shi_hiss1'], fx={'stealth': 0.35, 'backstab': 0.25}, cost=2)
node(B, 'shi_hiss2', 'Algılayıcı Ninja', 'Algılama +%50, gizli düşmanlar haritada.', 4, 40, ['shi_hiss1'], fx={'sense': 0.5}, cost=2, unlock=['sensor'])
node(B, 'shi_master', 'Gölge Ninja', 'Hız +%12, Ctrl sıçrayış +%20, havada atılma +1.', 5, 65, ['shi_jump3', 'shi_leap2'], fx={'speed': 0.12, 'leap': 0.2, 'air_dash': 1}, cost=3)

# ---------------------------------------------------------------- Hayatta kalma / yardımcı
B = 'yasam'
node(B, 'sur_can1', 'Sağlam Bünye', 'Maks can +50.', 1, 3, fx={'hp': 50})
node(B, 'sur_chakra1', 'Derin Nefes', 'Maks chakra +40.', 1, 3, fx={'chakra': 40})
node(B, 'sur_tuccar', 'Pazarlıkçı', 'Dükkân fiyatları -%10.', 1, 6, fx={'shop': -0.1})
node(B, 'sur_xp', 'Hızlı Öğrenen', 'Kazanılan XP +%10.', 2, 8, ['sur_chakra1'], fx={'xp': 0.1})
node(B, 'sur_ganimet', 'Ganimet Avcısı', 'Düşmanlardan düşen Ryō +%25.', 2, 10, ['sur_tuccar'], fx={'ryo': 0.25})
node(B, 'sur_can2', 'Demir İrade', 'Maks can +100, alınan hasar -%5.', 3, 25, ['sur_can1'], fx={'hp': 100, 'def': 0.05}, cost=2)
node(B, 'sur_tuccar2', 'Tüccar Dostu', 'Dükkân fiyatları -%10 daha.', 3, 22, ['sur_ganimet'], fx={'shop': -0.1})
node(B, 'sur_xp2', 'Bilge Öğrenci', 'XP +%15 daha.', 3, 30, ['sur_xp'], fx={'xp': 0.15}, cost=2)
node(B, 'sur_can3', 'Ölümsüz Ruh', 'Maks can +200, chakra +100.', 4, 60, ['sur_can2'], fx={'hp': 200, 'chakra': 100}, cost=3)
node(B, 'sur_dayan', 'Savaş Gazisi', 'Alınan hasar -%10, can yenilenmesi +%50.', 5, 80, ['sur_can3'], fx={'def': 0.1, 'regen_hp': 0.5}, cost=3)

# ---------------------------------------------------------------- Dōjutsu (yalnız göz varsa)
B = 'dojutsu'
node(B, 'doj1', 'Göz Kontrolü', 'Göz tekniklerinin chakra maliyeti -%15.', 1, 5, fx={'eye_cost': -0.15}, need={'eye': True})
node(B, 'doj_oku', 'Öngörü', 'Gözler açıkken kaçma şansı +%10.', 2, 12, ['doj1'], fx={'eye_dodge': 0.1}, need={'eye': True})
node(B, 'doj_guc', 'Göz Gücü', 'Göz teknikleri +%25 güçlü.', 2, 15, ['doj1'], fx={'eye_power': 0.25}, need={'eye': True})
node(B, 'doj_dayanim', 'Göz Dayanımı', 'Göz açıkken chakra tüketimi -%25.', 3, 25, ['doj_guc'], fx={'eye_cost': -0.25}, need={'eye': True}, cost=2)
node(B, 'doj_genjutsu', 'Gözle Genjutsu', 'Bakışla genjutsu: genjutsu gücü +%30.', 3, 30, ['doj_oku'], fx={'gen_power': 0.3}, need={'eye': True}, cost=2)
node(B, 'doj_master', 'Göz Efendisi', 'Göz teknikleri +%40, bekleme süreleri -%25.', 4, 60, ['doj_dayanim', 'doj_genjutsu'], fx={'eye_power': 0.4, 'eye_cd': -0.25}, need={'eye': True}, cost=3)

# ---------------------------------------------------------------- Liderlik (Kage yolu)
B = 'liderlik'
node(B, 'lid1', 'Takım Ruhu', 'Yanındaki müttefikler +%10 güçlü.', 1, 15, fx={'squad': 0.1})
node(B, 'lid_itibar', 'Saygın Ninja', 'Köy itibarı kazancı +%25.', 2, 20, ['lid1'], fx={'rep': 0.25})
node(B, 'lid_komut', 'Saha Komutanı', 'Müttefikler +%15 daha güçlü, görev ödülü +%10.', 3, 35, ['lid1'], fx={'squad': 0.15, 'ryo': 0.1}, cost=2)
node(B, 'lid_diplomat', 'Diplomat', 'Yabancı köylerde itibar daha hızlı artar, fiyatlar -%5.', 3, 40, ['lid_itibar'], fx={'rep': 0.25, 'shop': -0.05})
node(B, 'lid_kage', 'Ateşin İradesi', 'Kage adaylığı: tüm hasar +%10, müttefikler +%20.', 4, 80, ['lid_komut', 'lid_diplomat'], fx={'melee': 0.1, 'jutsu': 0.1, 'squad': 0.2}, cost=3)

BRANCHES = [
    dict(id='taijutsu', name='Taijutsu', icon='hand'), dict(id='ninjutsu', name='Ninjutsu', icon='chakra'),
    dict(id='genjutsu', name='Genjutsu', icon='eye'), dict(id='bukijutsu', name='Bukijutsu', icon='sword'),
    dict(id='fuinjutsu', name='Fūinjutsu', icon='seal'), dict(id='iryo', name='Tıbbi', icon='heart'),
    dict(id='senjutsu', name='Sennin / Çağırma', icon='leaf'), dict(id='shinobi', name='Shinobi', icon='shuriken'),
    dict(id='yasam', name='Hayatta Kalma', icon='bag'), dict(id='dojutsu', name='Dōjutsu', icon='eye'),
    dict(id='liderlik', name='Liderlik', icon='village'),
]
ids = {n['id'] for n in N}
for n in N:
    for r in n['req']:
        assert r in ids, (n['id'], r)
out = dict(branches=BRANCHES, nodes={n['id']: n for n in N}, sp_per_level=1, sp_milestone=2, respec_cost=500)
json.dump(out, open(os.path.join(ROOT, 'godot', 'data', 'skills.json'), 'w', encoding='utf8'), ensure_ascii=False, indent=1)
print(len(N), 'düğüm,', sum(n['cost'] for n in N), 'toplam puan')
