"""research/*.json -> godot/data/{jutsu,items,clans}.json (oyun verisi)"""
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
R = json.load(open(os.path.join(ROOT, 'research', 'jutsu.json'), encoding='utf8'))
A2J = {'Rat': 'Ne', 'Ox': 'Ushi', 'Tiger': 'Tora', 'Rabbit': 'U', 'Hare': 'U', 'Hare/Rabbit': 'U', 'Dragon': 'Tatsu',
       'Snake': 'Mi', 'Horse': 'Uma', 'Ram': 'Hitsuji', 'Monkey': 'Saru', 'Bird': 'Tori', 'Dog': 'Inu', 'Boar': 'I'}
canon = {x['id']: [A2J[s] for s in x.get('hand_seals', []) if s in A2J] for x in R['jutsu']}
rank_of = {x['id']: x['rank'] for x in R['jutsu']}


def seals(cid, n=8):
    return canon.get(cid, [])[:n]


# id, isim, canon_id, maliyet, cd, element, klan, seviye, rütbe, öğrenme, açıklama
J = [
    ('henge', 'Henge no Jutsu (Dönüşüm)', 'transformation_technique', 12, 20, '', '', 1, 0, 'academy', 'Köylü kılığına gir: düşmanlar seni fark etmez.'),
    ('shunshin', 'Shunshin (Işınlanma)', 'body_flicker_technique', 10, 3, '', '', 3, 1, 'trainer:academy', 'Baktığın yöne/hedefe anında ışınlan.'),
    ('bunshin', 'Kage Bunshin no Jutsu', 'shadow_clone_technique', 40, 12, '', '', 6, 1, 'quest:forbidden_scroll', 'Gerçek gölge klonlar savaşır. (Yasak Parşömen)'),
    ('katon_goukakyuu', 'Katon: Goukakyuu', 'great_fireball', 25, 5, 'katon', '', 2, 1, 'element', 'Dev ateş topu: patlar ve yakar.'),
    ('katon_housenka', 'Katon: Housenka', 'phoenix_sage_fire', 22, 6, 'katon', '', 7, 1, 'scroll', 'Hedefe yönelen 5 alev.'),
    ('katon_karyuu', 'Katon: Karyuu Endan', 'dragon_fire_technique', 40, 10, 'katon', '', 16, 2, 'trainer:konoha', 'Ejderha alevi püskürt.'),
    ('suiton_suikoudan', 'Suiton: Suikoudan', 'water_shark_bullet', 28, 6, 'suiton', '', 2, 1, 'element', 'Hedefe yönelen su köpekbalığı.'),
    ('suiton_suijinheki', 'Suiton: Suijinheki', 'water_formation_wall', 25, 12, 'suiton', '', 7, 1, 'scroll', 'Su kalkanı: mermileri yok eder.'),
    ('suiton_suiryuudan', 'Suiton: Suiryuudan', 'water_dragon_bullet', 40, 9, 'suiton', '', 16, 2, 'trainer:kiri', 'Su ejderhası (canon 44 mühür, burada ilk 8).'),
    ('fuuton_shinkuu', 'Fuuton: Shinkuu Gyoku', 'vacuum_sphere', 22, 5, 'fuuton', '', 2, 1, 'element', 'Ardı ardına vakum mermileri.'),
    ('fuuton_daitoppa', 'Fuuton: Daitoppa', 'great_breakthrough', 22, 6, 'fuuton', '', 7, 1, 'scroll', 'Önündekileri savuran fırtına.'),
    ('fuuton_rasenshuriken', 'Fuuton: Rasenshuriken', 'rasenshuriken', 70, 20, 'fuuton', '', 28, 3, 'quest:rasenshuriken', 'Fırlatılan dev rüzgar shurikeni.'),
    ('doton_doryuusou', 'Doton: Doryuusou', 'earth_flow_spears', 22, 6, 'doton', '', 2, 1, 'element', 'Yerden fışkıran toprak mızraklar.'),
    ('doton_doryuheki', 'Doton: Doryuheki', 'earth_style_wall', 20, 9, 'doton', '', 7, 1, 'scroll', 'Tırmanılabilir toprak duvar.'),
    ('doton_yomi', 'Doton: Yomi Numa', 'swamp_of_the_underworld', 35, 14, 'doton', '', 16, 2, 'trainer:iwa', 'Bataklık: düşmanlar yavaşlar.'),
    ('raiton_nagashi', 'Raiton: Chidori Nagashi', 'false_darkness', 22, 8, 'raiton', '', 2, 1, 'element', 'Etrafa elektrik: sersemletir.'),
    ('raiton_chidori', 'Chidori', 'chidori', 32, 7, 'raiton', '', 12, 2, 'trainer:konoha_jonin', 'Yıldırım hücumu.'),
    ('raiton_armor', 'Raiton no Yoroi', 'lightning_chakra_mode', 45, 25, 'raiton', '', 18, 2, 'trainer:kumo', 'Yıldırım zırhı: hız ve güç.'),
    ('rasengan', 'Rasengan', 'rasengan', 32, 7, '', '', 12, 2, 'quest:rasengan', 'Mühürsüz sarmal chakra küresi.'),
    ('shousen', 'Shousen (Tıbbi Ninjutsu)', 'mystical_palm', 25, 9, '', '', 4, 1, 'trainer:hospital', 'Kendini ve dostları iyileştir.'),
    ('narakumi', 'Magen: Narakumi', 'hell_viewing_technique', 22, 12, '', '', 5, 1, 'trainer:academy_genjutsu', 'Genjutsu: hedef dehşetle donar.'),
    ('kokuangyo', 'Kokuangyo no Jutsu', 'bringer_of_darkness', 35, 22, '', '', 15, 2, 'scroll', 'Düşmanlar seni kaybeder.'),
    ('kuchiyose', 'Kuchiyose no Jutsu', 'summoning_technique', 60, 45, '', '', 12, 2, 'quest:contract', 'Sözleşmeli dev hayvanı çağır.'),
    # ---- klan teknikleri (learn='clan': seviye gelince otomatik öğrenilir)
    ('juuken_64', 'Hakke Rokujūyon Shō', 'eight_trigrams_64_palms', 30, 9, '', 'hyuga', 4, 0, 'clan', 'Yumuşak Yumruk: 64 avuç darbesi, chakra noktalarını kapatır.'),
    ('kaiten', 'Hakkeshō Kaiten', 'eight_trigrams_palm_rotation', 25, 8, '', 'hyuga', 8, 0, 'clan', 'Dönen chakra kubbesi: iter ve mermileri durdurur.'),
    ('kagemane', 'Kagemane no Jutsu', 'shadow_imitation', 20, 10, '', 'nara', 3, 0, 'clan', 'Gölgen hedefe uzanır ve onu 4 sn kilitler.'),
    ('kage_kubi', 'Kage Kubi Shibari', 'shadow_neck_bind', 30, 12, '', 'nara', 9, 0, 'clan', 'Gölge eller hedefi boğar: kilit + sürekli hasar.'),
    ('baika', 'Baika no Jutsu', 'multi_size', 30, 25, '', 'akimichi', 3, 0, 'clan', '20 sn devleş: dev hitbox, ağır yumruklar.'),
    ('nikudan', 'Nikudan Sensha', 'human_bullet_tank', 25, 8, '', 'akimichi', 7, 0, 'clan', 'Dev top olup yoldakileri ez.'),
    ('mushi_swarm', 'Kikaichū Sürüsü', 'parasitic_insects', 25, 8, '', 'aburame', 3, 0, 'clan', 'Böcek bulutu: sürekli hasar, yavaşlatır.'),
    ('ninken', 'Ninken Yoldaşı', '', 15, 30, '', 'inuzuka', 2, 0, 'clan', 'Sadık savaş köpeğini çağır.'),
    ('gatsuga', 'Gatsūga', 'fang_passing_fang', 25, 7, '', 'inuzuka', 5, 0, 'clan', 'Dönen matkap hücumu.'),
    ('shintenshin', 'Shintenshin no Jutsu', 'mind_body_switch', 40, 25, '', 'yamanaka', 6, 0, 'clan', 'Düşmanın zihnine gir: 12 sn senin için savaşır.'),
    ('mokuton_spikes', 'Mokuton: Sashiki no Jutsu', '', 35, 7, '', 'senju', 4, 0, 'clan', 'Yerden fışkıran odun mızraklar.'),
    ('mokuton_wall', 'Mokuton: Mokujōheki', 'four_pillar_house', 30, 14, '', 'senju', 8, 0, 'clan', 'Etrafında odun kubbe yükselir.'),
    ('hyoton_senbon', 'Hyōton: Sensatsu Suishō', '', 22, 4, '', 'yuki', 3, 0, 'clan', 'Buz iğnesi yelpazesi.'),
    ('hyoton_spears', 'Hyōton: Tsurara', 'demonic_mirroring_ice_crystals', 35, 8, '', 'yuki', 7, 0, 'clan', 'Hedefin etrafında buz: dondurur.'),
    ('bone_bullets', 'Teshi Sendan', '', 18, 3, '', 'kaguya', 3, 0, 'clan', 'Parmak kemiği mermileri.'),
    ('bone_armor', 'Kemik Zırh', 'dance_of_the_willow', 30, 20, '', 'kaguya', 7, 0, 'clan', '20 sn gelen hasar yarıya iner.'),
    ('chakra_chains', 'Fūinjutsu: Kongō Fūsa', '', 35, 12, '', 'uzumaki', 5, 0, 'clan', 'Altın chakra zincirleri hedefi bağlar.'),
    ('suika', 'Suika no Jutsu', '', 25, 18, '', 'hozuki', 3, 0, 'clan', '15 sn bedenin suya dönüşür: darbeler içinden geçer.'),
    ('water_gun', 'Suiton: Mizudeppō', '', 15, 3, '', 'hozuki', 5, 0, 'clan', 'Parmaktan basınçlı su mermisi.'),
    # ---- yeni klanlar (uygulama: IMPL ile mevcut jutsulara bağlanır)
    ('sarutobi_haisekisho', 'Katon: Haisekishō', 'ash_pile_burning', 25, 8, 'katon', 'sarutobi', 3, 0, 'clan', 'Yanıcı kül bulutu üfle ve tutuştur.'),
    ('sarutobi_karyu', 'Katon: Karyū Endan (Sarutobi)', 'dragon_fire_technique', 35, 10, 'katon', 'sarutobi', 8, 0, 'clan', 'Klan ateşi: ejderha alevi erken öğrenilir.'),
    ('hatake_hakko', 'Hakkō Chakra Bıçağı', '', 25, 7, 'raiton', 'hatake', 3, 0, 'clan', 'Beyaz chakra ile parlayan bıçak hücumu.'),
    ('hatake_ninken', 'Ninken Sürüsü', '', 20, 30, '', 'hatake', 6, 0, 'clan', 'İz süren ninja köpeklerini çağır.'),
    ('chinoike_ketsuryugan', 'Ketsuryūgan: Kan Genjutsu', '', 25, 12, '', 'chinoike', 3, 0, 'clan', 'Kızıl gözle bakış: hedef dehşet içinde donar.'),
    ('chinoike_kanshu', 'Kan Akışı Kontrolü', '', 35, 20, '', 'chinoike', 8, 0, 'clan', 'Düşmanların görüşünü karartan kızıl sis.'),
    ('hoshigaki_same', 'Suiton: Gōshokuzame', 'water_shark_bullet', 28, 6, 'suiton', 'hoshigaki', 3, 0, 'clan', 'Avını kovalayan köpekbalığı sürüsü.'),
    ('hoshigaki_ryudan', 'Suiton: Bakusui Ryūdan', 'water_dragon_bullet', 40, 10, 'suiton', 'hoshigaki', 8, 0, 'clan', 'Dev su ejderhası.'),
    ('kurama_genjutsu', 'Kurama: Gerçeklik Genjutsusu', 'hell_viewing_technique', 25, 10, '', 'kurama', 3, 0, 'clan', 'Hayal gerçeğe dönüşür: hedef korkuyla kilitlenir.'),
    ('kurama_kokuangyo', 'Kurama: Karanlık Perde', 'bringer_of_darkness', 35, 18, '', 'kurama', 8, 0, 'clan', 'Tüm düşmanlar seni kaybeder.'),
    ('fuma_shuriken_j', 'Fūma Shuriken Fırlatışı', '', 20, 5, 'fuuton', 'fuma', 3, 0, 'clan', 'Rüzgar destekli dev shuriken fırtınası.'),
    ('fuma_kaze', 'Fuuton: Kamaitachi', 'great_breakthrough', 25, 7, 'fuuton', 'fuma', 7, 0, 'clan', 'Kesen rüzgar dalgası.'),
    ('kamizuru_bees', 'Arı Sürüsü', '', 25, 8, '', 'kamizuru', 3, 0, 'clan', 'Saldırgan arı bulutu: sürekli hasar.'),
    ('kamizuru_wax', 'Mitsu Rensei: Bal Mumu Kalkanı', '', 25, 14, '', 'kamizuru', 7, 0, 'clan', 'Yapışkan mum duvarı: düşmanları yavaşlatır.'),
]
SEAL_OVERRIDE = {
    'kagemane': ['Ne'], 'kage_kubi': ['Ne', 'Mi'], 'baika': ['Hitsuji'], 'mushi_swarm': ['Ne', 'Tori'],
    'gatsuga': ['Inu'], 'shintenshin': ['Ne', 'Hitsuji', 'Mi'], 'mokuton_spikes': ['Tori', 'Ushi', 'Tatsu'],
    'mokuton_wall': ['Ushi', 'Tora', 'Mi'], 'hyoton_senbon': ['Hitsuji', 'Tatsu'], 'hyoton_spears': ['Ne', 'Mi', 'Tora'],
    'chakra_chains': ['I', 'Inu', 'Tori', 'Saru'], 'suika': ['Ushi', 'U'], 'water_gun': ['Tora', 'Ushi'],
}
# yeni klan jutsuları mevcut j_* uygulamalarına bağlanır (jutsu.gd execute 'impl' alanını okur)
IMPL = {
    'sarutobi_haisekisho': 'katon_housenka', 'sarutobi_karyu': 'katon_karyuu', 'hatake_hakko': 'raiton_chidori',
    'hatake_ninken': 'ninken', 'chinoike_ketsuryugan': 'narakumi', 'chinoike_kanshu': 'kokuangyo',
    'hoshigaki_same': 'suiton_suikoudan', 'hoshigaki_ryudan': 'suiton_suiryuudan', 'kurama_genjutsu': 'narakumi',
    'kurama_kokuangyo': 'kokuangyo', 'fuma_shuriken_j': 'fuuton_shinkuu', 'fuma_kaze': 'fuuton_daitoppa',
    'kamizuru_bees': 'mushi_swarm', 'kamizuru_wax': 'doton_yomi',
}
SEAL_OVERRIDE.update({'hatake_hakko': ['Ushi', 'U', 'Saru'], 'hatake_ninken': ['I', 'Inu', 'Tori', 'Saru', 'Hitsuji'],
                      'chinoike_ketsuryugan': ['Mi'], 'chinoike_kanshu': ['Mi', 'Hitsuji'], 'kurama_genjutsu': ['Ne', 'Mi'],
                      'fuma_shuriken_j': ['Tora'], 'kamizuru_bees': ['Ne', 'Tori'], 'kamizuru_wax': ['Ushi', 'Mi']})
out = {}
for (jid, name, cid, cost, cd, el, clan, lv, rk, learn, desc) in J:
    out[jid] = dict(id=jid, name=name, cost=cost, cd=cd, element=el, clan=clan, level=lv, rank=rk, learn=learn, desc=desc,
                    seals=SEAL_OVERRIDE.get(jid, seals(cid)), canon_rank=rank_of.get(cid, '?'))
    if jid in IMPL:
        out[jid]['impl'] = IMPL[jid]

# ================================================================== tam jutsu listesi (research/jutsu_full.json, 653 jutsu)
FULL = json.load(open(os.path.join(ROOT, 'research', 'jutsu_full.json'), encoding='utf8'))['jutsu']
EL_MAP = {'futon': 'fuuton', 'katon': 'katon', 'suiton': 'suiton', 'doton': 'doton', 'raiton': 'raiton', 'mokuton': 'mokuton',
          'hyoton': 'hyoton', 'yoton': 'yoton', 'futton': 'futton', 'ranton': 'ranton', 'shakuton': 'shakuton', 'bakuton': 'bakuton',
          'jiton': 'jiton', 'shoton': 'shoton', 'jinton': 'jinton', 'inton': 'inton', 'yang': 'yang', 'onmyoton': 'onmyoton'}
COMBAT_EL = set(['katon', 'suiton', 'fuuton', 'doton', 'raiton', 'mokuton', 'hyoton', 'yoton', 'futton', 'ranton', 'shakuton', 'bakuton', 'jiton', 'shoton', 'jinton'])
RANK_I = {'E': 0, 'D': 1, 'C': 2, 'B': 3, 'A': 4, 'S': 5}
SEAL_EN = {'Rat': 'Ne', 'Ox': 'Ushi', 'Tiger': 'Tora', 'Rabbit': 'U', 'Hare': 'U', 'Dragon': 'Tatsu', 'Snake': 'Mi', 'Horse': 'Uma',
           'Ram': 'Hitsuji', 'Monkey': 'Saru', 'Bird': 'Tori', 'Dog': 'Inu', 'Boar': 'I'}
KG_MAP = {'Wood Release': 'mokuton', 'Ice Release': 'hyoton', 'Lava Release': 'yoton', 'Boil Release': 'futton', 'Storm Release': 'ranton',
          'Scorch Release': 'shakuton', 'Explosion Release': 'bakuton', 'Magnet Release': 'jiton', 'Crystal Release': 'shoton',
          'Dust Release': 'jinton', 'Shikotsumyaku': 'shikotsumyaku', "Jūgo's Clan's Kekkei Genkai": 'senjutsu_beden'}
EYE_MAP = {'Sharingan': 'sharingan', 'Mangekyō Sharingan': 'mangekyo', 'Eternal Mangekyō Sharingan': 'ems', 'Rinnegan': 'rinnegan',
           'Rinne Sharingan': 'rinne_sharingan', 'Byakugan': 'byakugan', 'Tenseigan': 'tenseigan', 'Jōgan': 'jogan',
           'Ketsuryūgan': 'ketsuryugan', 'Kokugan': 'kokugan'}
CLAN_MAP = {'Hyūga Clan': 'hyuga', 'Nara Clan': 'nara', 'Yamanaka Clan': 'yamanaka', 'Akimichi Clan': 'akimichi', 'Hōzuki Clan': 'hozuki',
            'Aburame Clan': 'aburame', 'Uzumaki Clan': 'uzumaki', 'Yuki Clan': 'yuki', 'Sarutobi Clan': 'sarutobi', 'Senju Clan': 'senju',
            'Uchiha Clan': 'uchiha', 'Inuzuka Clan': 'inuzuka', 'Kaguya Clan': 'kaguya', 'Hatake Clan': 'hatake'}
VILLAGE_OF = {'katon': 'konoha', 'fuuton': 'suna', 'suiton': 'kiri', 'raiton': 'kumo', 'doton': 'iwa'}
# şekil -> (maliyet çarpanı, bekleme çarpanı)
SHAPE_K = {'projectile': (1.0, 1.0), 'melee': (0.8, 0.8), 'aoe': (1.2, 1.3), 'bind': (1.0, 1.4), 'summon': (1.8, 3.0), 'buff': (1.2, 2.2),
           'clone': (1.2, 1.6), 'seal': (1.3, 1.8), 'genjutsu_stun': (1.0, 1.5), 'wall': (0.9, 1.5), 'field': (1.3, 1.8),
           'utility': (0.6, 1.0), 'transform': (0.8, 1.6), 'beam': (1.4, 1.4), 'stealth': (0.8, 1.6), 'trap': (0.8, 1.2),
           'teleport': (0.5, 0.4), 'debuff': (0.9, 1.3), 'counter': (0.8, 1.2), 'sensor': (0.5, 1.5), 'mode': (1.8, 3.0),
           'rush': (0.9, 0.8), 'heal': (1.0, 1.6), 'revive': (2.5, 4.0), 'dash': (0.6, 0.5)}
COST = [5, 10, 18, 28, 42, 60]
CD = [3, 4, 6, 9, 14, 22]
LEVEL = [1, 2, 5, 10, 18, 28]
NRANK = [0, 0, 1, 2, 3, 3]
SCROLL_PRICE = [100, 200, 400, 800, 1500, 3000]

# mevcut elle yazılmış jutsular hangi araştırma kaydına denk geliyor (legacy_id = eski canon id)
cid_of = {jid: cid for (jid, name, cid, *_r) in J if cid}
best = {}
for r in FULL:
    lid = r.get('legacy_id')
    if not lid:
        continue
    cur = best.get(lid)
    if cur is None or (len(r.get('elements') or []), len(r['id'])) < (len(cur.get('elements') or []), len(cur['id'])):
        best[lid] = r
covered = set()


def research_fields(r):
    els = [EL_MAP.get(e, e) for e in (r.get('elements') or [])]
    combat = [e for e in els if e in COMBAT_EL]
    ri = RANK_I.get(r.get('canon_rank') or 'C', 2)
    req = r.get('requires') or {}
    return els, combat, ri, req


def learn_path(r, combat, ri, req, cat):
    h = sum(ord(ch) for ch in r['id'])
    if r.get('signature'):
        return 'quest:signature'
    if r.get('kinjutsu') or cat == 'kinjutsu' or req.get('otsutsuki_power'):
        return 'kinjutsu'
    if req.get('eye'):
        return 'eye:' + EYE_MAP.get(req['eye'][0], 'sharingan')
    if req.get('kekkei_genkai'):
        return 'kg:' + KG_MAP.get(req['kekkei_genkai'][0], 'kekkei')
    if req.get('clan_or_lineage'):
        c = CLAN_MAP.get(req['clan_or_lineage'][0])
        return ('clan:' + c) if c else 'quest:hiden'
    if req.get('sage_mode') or cat == 'senjutsu':
        return 'sage:any'
    if cat == 'summoning':
        return 'quest:contract'
    if cat == 'space_time':
        return 'kinjutsu' if ri >= 4 else 'trainer:jonin'
    if cat == 'medical':
        return 'trainer:hospital'
    if cat == 'genjutsu':
        return 'scroll' if ri <= 2 else 'trainer:genjutsu'
    if cat == 'taijutsu':
        return 'academy' if ri <= 1 else 'trainer:taijutsu'
    if cat == 'fuinjutsu':
        return 'scroll' if ri <= 3 else 'trainer:fuin'
    if cat in ('kekkei_genkai', 'hiden', 'dojutsu'):
        return 'quest:hiden'
    if ri <= 1 and not combat:
        return 'academy'
    if combat and combat[0] in VILLAGE_OF:
        if ri <= 2 or (ri == 3 and h % 2 == 0):
            return 'scroll'
        return 'trainer:' + VILLAGE_OF[combat[0]]
    return 'scroll' if ri <= 3 else 'trainer:jonin'


for gid, cid in cid_of.items():
    r = best.get(cid)
    if r is None or gid not in out:
        continue
    covered.add(r['id'])
    els, combat, ri, req = research_fields(r)
    g = out[gid]
    g.setdefault('category', r.get('category', 'ninjutsu'))
    g.setdefault('shape', r.get('shape', 'projectile'))
    g['elements'] = [g['element']] if g.get('element') else combat
    g['tier'] = ri
    g['name_en'] = r.get('name_en', '')
    g['research_id'] = r['id']
# elle yazılmışlara kategori/şekil varsayılanı (araştırmada karşılığı olmayanlar)
for gid, g in out.items():
    if gid.startswith('_'):
        continue
    g.setdefault('category', 'hiden' if g.get('clan') else 'ninjutsu')
    g.setdefault('shape', 'projectile')
    g.setdefault('elements', [g['element']] if g.get('element') else [])
    g.setdefault('tier', RANK_I.get(g.get('canon_rank', 'C'), 2))

new_count = 0
for r in FULL:
    jid = r['id']
    if jid in covered or jid in out:
        continue
    els, combat, ri, req = research_fields(r)
    cat = r.get('category', 'ninjutsu')
    shape = r.get('shape') or 'projectile'
    ck, dk = SHAPE_K.get(shape, (1.0, 1.0))
    learn = learn_path(r, combat, ri, req, cat)
    seals_ = [SEAL_EN[s] for s in (r.get('seals') or []) if s in SEAL_EN][:10]
    clan = learn[5:] if learn.startswith('clan:') else ''
    out[jid] = dict(
        id=jid, name=r['name'], name_en=r.get('name_en', ''), cost=int(round(COST[ri] * ck)), cd=round(CD[ri] * dk, 1),
        element=combat[0] if combat else '', elements=combat, natures=els, clan=clan, level=LEVEL[ri], rank=NRANK[ri],
        learn=learn, desc=r.get('desc', ''), seals=seals_, canon_rank=r.get('canon_rank') or 'C', tier=ri,
        category=cat, shape=shape, range=r.get('range') or '', requires=req, signature=bool(r.get('signature')),
        kinjutsu=bool(r.get('kinjutsu')), series=(r.get('first_appears') or {}).get('series', ''))
    new_count += 1
print(new_count, 'yeni jutsu araştırmadan eklendi;', len(covered), 'mevcut jutsu zenginleştirildi')

out['_seals'] = [s['name_jp'] for s in R['hand_seals'][:12]]
os.makedirs(os.path.join(ROOT, 'godot', 'data'), exist_ok=True)
json.dump(out, open(os.path.join(ROOT, 'godot', 'data', 'jutsu.json'), 'w', encoding='utf8'), ensure_ascii=False, indent=1)

items = {
    'kunai': dict(name='Kunai', price=10, kind='throw', desc="Fırlat [R]. 10 hasar."),
    'shuriken': dict(name='Shuriken', price=8, kind='throw', desc="Üçlü yelpaze atış."),
    'tag': dict(name='Patlayıcı Etiketli Kunai', price=45, kind='throw', desc="Saplandığı yerde patlar."),
    'smoke': dict(name='Duman Bombası', price=30, kind='throw', desc="Düşmanlar seni kaybeder."),
    'salve': dict(name='Şifalı Merhem', price=35, kind='use', desc="+50 can [H]."),
    'pill': dict(name='Asker Hapı', price=70, kind='use', desc="+60 chakra, 20sn güç [Y]."),
    'herb': dict(name='Şifalı Ot', price=0, kind='quest', sell=6, desc="Görev eşyası."),
    'package': dict(name='Teslimat Paketi', price=0, kind='quest', desc="Görev eşyası."),
    'scroll_katon_housenka': dict(name='Parşömen: Housenka', price=400, kind='scroll', jutsu='katon_housenka', desc="Katon kullanıcıları öğrenebilir."),
    'scroll_suiton_suijinheki': dict(name='Parşömen: Suijinheki', price=400, kind='scroll', jutsu='suiton_suijinheki', desc="Suiton kullanıcıları."),
    'scroll_fuuton_daitoppa': dict(name='Parşömen: Daitoppa', price=400, kind='scroll', jutsu='fuuton_daitoppa', desc="Fuuton kullanıcıları."),
    'scroll_doton_doryuheki': dict(name='Parşömen: Doryuheki', price=400, kind='scroll', jutsu='doton_doryuheki', desc="Doton kullanıcıları."),
    'scroll_kokuangyo': dict(name='Parşömen: Kokuangyo', price=900, kind='scroll', jutsu='kokuangyo', desc="Seviye 15 + Chunin."),
}
# satılık jutsu parşömenleri: 'scroll' yolu olan her jutsu için
have_scroll = set(v.get('jutsu') for v in items.values() if v.get('kind') == 'scroll')
for jid, j in out.items():
    if jid.startswith('_') or j.get('learn') != 'scroll' or jid in have_scroll:
        continue
    short = j['name'].split(' (')[0]
    items['scroll_' + jid] = dict(name='Parşömen: ' + short, price=SCROLL_PRICE[j.get('tier', 2)], kind='scroll', jutsu=jid,
                                  desc=('%s — %s' % (j.get('canon_rank', '?'), j.get('desc', '')))[:160])
json.dump(items, open(os.path.join(ROOT, 'godot', 'data', 'items.json'), 'w', encoding='utf8'), ensure_ascii=False, indent=1)

C = json.load(open(os.path.join(ROOT, 'research', 'clans_factions.json'), encoding='utf8'))
clans = {'none': dict(name='Klansız', desc='Saf çaba: taijutsu +%15. İleride Sekiz Kapı.', kg='Yok', eye=[0.25, 0.45, 0.8])}
want = {'Uchiha': 'uchiha', 'Hyūga': 'hyuga', 'Nara': 'nara', 'Akimichi': 'akimichi', 'Yamanaka': 'yamanaka', 'Aburame': 'aburame',
        'Inuzuka': 'inuzuka', 'Senju': 'senju', 'Uzumaki': 'uzumaki', 'Kaguya': 'kaguya', 'Yuki': 'yuki', 'Hōzuki': 'hozuki'}
eyes = {'uchiha': [0.12, 0.1, 0.12], 'hyuga': [0.9, 0.9, 0.96], 'nara': [0.2, 0.18, 0.15], 'akimichi': [0.3, 0.2, 0.12],
        'yamanaka': [0.4, 0.7, 0.85], 'aburame': [0.1, 0.1, 0.1], 'inuzuka': [0.45, 0.25, 0.12], 'senju': [0.3, 0.22, 0.15],
        'uzumaki': [0.25, 0.45, 0.85], 'kaguya': [0.55, 0.4, 0.65], 'yuki': [0.45, 0.6, 0.75], 'hozuki': [0.6, 0.45, 0.75]}
for c in C['clans']:
    for k, cid in want.items():
        if c['name'].startswith(k):
            clans[cid] = dict(name=c['name'].replace(' Clan', ''), desc=c.get('game_suggestion', '')[:200],
                              kg=str(c.get('kekkei_genkai_or_hiden', ''))[:80], eye=eyes[cid])
for cid, nm, kg, desc in [('hyuga', 'Hyūga', 'Byakugan', 'Byakugan ile duvar arkasını görür; Yumuşak Yumruk ile chakra noktalarını kapatır, Hakkeshō Kaiten ile döner kalkan.'),
                           ('hozuki', 'Hōzuki', 'Hydrification', 'Bedenini suya dönüştürür; fiziksel darbelerden kaçar, Suiton yatkın.')]:
    if cid not in clans:
        clans[cid] = dict(name=nm, desc=desc, kg=kg, eye=eyes[cid])
# Narutopedia klanları (kanon karakter yok): yeni klanlar + pasif bonuslar + göz türü
for cid, nm, kg, desc, eye in [
    ('sarutobi', 'Sarutobi', 'Ateşin İradesi', "Konoha'nın köklü ateş klanı. Katon jutsuları güçlü, chakra yüksek. Kül ve ejderha alevi teknikleri.", [0.25, 0.18, 0.12]),
    ('hatake', 'Hatake', 'Beyaz Chakra', 'Kılıç ve ninken ustası küçük klan. Silahla yakın dövüş güçlü; Beyaz Chakra Bıçağı ve iz süren köpekler.', [0.2, 0.2, 0.22]),
    ('chinoike', 'Chinoike', 'Ketsuryūgan', 'Kan rengi göze sahip lanetli klan. Güçlü genjutsu ve kan kontrolü.', [0.7, 0.08, 0.1]),
    ('hoshigaki', 'Hoshigaki', 'Köpekbalığı Soyu', "Sis'in köpekbalığı benzeri savaşçıları. Dev chakra deposu, Suiton ustalığı.", [0.85, 0.85, 0.75]),
    ('kurama', 'Kurama', 'Gerçeklik Genjutsusu', 'Hayali gerçeğe çeviren nadir genjutsu yeteneği olan Konoha klanı.', [0.45, 0.3, 0.55]),
    ('fuma', 'Fūma', 'Dev Shuriken Sanatı', "Ses Ülkesi'nin eski ninja klanı. Dev shuriken ve rüzgar teknikleri.", [0.35, 0.3, 0.25]),
    ('kamizuru', 'Kamizuru', 'Arı Yetiştiriciliği', "Iwa'nın arı çağıran klanı. Böcek sürüleri ve bal mumu teknikleri.", [0.75, 0.6, 0.2]),
]:
    clans[cid] = dict(name=nm, desc=desc, kg=kg, eye=eye)
DOJUTSU = {'uchiha': 'sharingan', 'hyuga': 'byakugan', 'chinoike': 'ketsuryugan'}
BONUS = {  # hp, chakra (düz); melee, jutsu, speed (oran)
    'none': dict(melee=0.15), 'uchiha': dict(jutsu=0.1, chakra=10), 'hyuga': dict(melee=0.12), 'nara': dict(chakra=20),
    'akimichi': dict(hp=40, melee=0.15), 'yamanaka': dict(chakra=25), 'aburame': dict(chakra=20, hp=10), 'inuzuka': dict(melee=0.1, speed=0.05),
    'senju': dict(hp=40, chakra=20), 'uzumaki': dict(hp=20, chakra=60), 'kaguya': dict(hp=20, melee=0.12), 'yuki': dict(chakra=20, jutsu=0.05),
    'hozuki': dict(hp=15, chakra=15), 'sarutobi': dict(chakra=25, jutsu=0.08), 'hatake': dict(melee=0.12, speed=0.04), 'chinoike': dict(chakra=20, jutsu=0.05),
    'hoshigaki': dict(chakra=80, hp=20), 'kurama': dict(chakra=30), 'fuma': dict(melee=0.08, speed=0.05), 'kamizuru': dict(hp=20, chakra=20),
}
KG_NATURES = {'senju': (['mokuton'], 15), 'yuki': (['hyoton'], 1), 'kaguya': (['shikotsumyaku'], 1), 'hozuki': (['hydrification'], 1)}
for cid, c in clans.items():
    if cid in KG_NATURES:
        c['kg_natures'] = KG_NATURES[cid][0]
        c['kg_level'] = KG_NATURES[cid][1]
for cid, c in clans.items():
    if cid in DOJUTSU:
        c['dojutsu'] = DOJUTSU[cid]
    c['bonus'] = BONUS.get(cid, {})
json.dump(clans, open(os.path.join(ROOT, 'godot', 'data', 'clans.json'), 'w', encoding='utf8'), ensure_ascii=False, indent=1)
print(len(out) - 1, 'jutsu,', len(items), 'items,', len(clans), 'clans')
print(out['katon_goukakyuu']['seals'], out['raiton_chidori']['seals'])
