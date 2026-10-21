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
]
out = {}
for (jid, name, cid, cost, cd, el, clan, lv, rk, learn, desc) in J:
    out[jid] = dict(id=jid, name=name, cost=cost, cd=cd, element=el, clan=clan, level=lv, rank=rk, learn=learn, desc=desc,
                    seals=seals(cid), canon_rank=rank_of.get(cid, '?'))
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
json.dump(clans, open(os.path.join(ROOT, 'godot', 'data', 'clans.json'), 'w', encoding='utf8'), ensure_ascii=False, indent=1)
print(len(out) - 1, 'jutsu,', len(items), 'items,', len(clans), 'clans')
print(out['katon_goukakyuu']['seals'], out['raiton_chidori']['seals'])
