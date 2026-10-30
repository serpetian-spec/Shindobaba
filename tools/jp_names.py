"""Türkçe yazılmış jutsu adlarının Japonca (romaji) karşılıkları. build_data.py sonunda uygulanır:
- "Romaji (Türkçe)" biçimli adlar -> ad romaji kalır, Türkçe anlam "meaning" alanına taşınır
- tamamen Türkçe adlar -> aşağıdaki sözlükten romaji ad, eski Türkçe ad "meaning" olur
"""
import re

JP = {
    'mushi_swarm': 'Mushi Yose no Jutsu', 'ninken': 'Ninken Kuchiyose', 'bone_armor': 'Kotsu no Yoroi',
    'hatake_hakko': 'Hakkō Chakuratō', 'hatake_ninken': 'Tsuiga no Jutsu: Ninken Gundan',
    'chinoike_ketsuryugan': 'Ketsuryūgan: Chi Genjutsu', 'chinoike_kanshu': 'Ketsuryū Sōsa',
    'kurama_genjutsu': 'Kurama: Gen\'ei Jitsuzō', 'kurama_kokuangyo': 'Kurama: Kokuan Maku',
    'fuma_shuriken_j': 'Fūma Shuriken: Kazeguruma', 'kamizuru_bees': 'Hachi Kuchiyose: Hachi no Mure',
    'kamizuru_wax': 'Mitsu Rensei: Rōheki', 'sharingan_ongoru': 'Sharingan: Senken',
    'sharingan_kopya_kunai': 'Sharingan: Dōsa Fukusha', 'byakugan_tam_gorus': 'Byakugan: Zenshiya',
    'ketsuryugan_chi_ayatsuri': 'Ketsuryūgan: Chi Ayatsuri', 'ketsuryugan_kessho': 'Ketsuryūgan: Kesshō Chi',
    'tenseigan_inryoku': 'Tenseigan: Inryoku Sekiryoku', 'tenseigan_gudodama_ame': 'Tenseigan: Gudōdama no Ame',
    'jogan_jigen_kiri': 'Jōgan: Jigen Giri', 'jogan_kanpa': 'Jōgan: Kanpa no Me', 'jogan_fuin_kai': 'Jōgan: Fūin Kaijo',
    'jogan_seisen': 'Jōgan: Seisen', 'iburi_iaigiri': 'Iburi: Iaigiri', 'iburi_kemuri_kiri': 'Iburi: Enjin Tosshin',
    'iburi_kemuri_shibari': 'Iburi: Kemuri Shibari', 'shimura_kaze_kunai': 'Fūton: Kaze Kunai',
    'shimura_ne_fuin': 'Ne no Fūin: Zetsuhō Fūin', 'shimura_kaze_tate': 'Fūton: Kaze no Tate',
    'shimura_zetsuei': 'Fūton: Mumei Zetsuei', 'tsuchigumo_ito': 'Tsuchigumo: Kumo Ito',
    'tsuchigumo_kumo_ya': 'Tsuchigumo: Kumo Ya', 'tsuchigumo_doku': 'Tsuchigumo: Dokuga',
    'tsuchigumo_su': 'Tsuchigumo: Kumo no Su', 'tsuchigumo_kumo_bunshin': 'Tsuchigumo: Kumo Mure',
    'tsuchigumo_kumo_yoroi': 'Tsuchigumo: Kumo Ashi', 'tsuchigumo_ganseki': 'Tsuchigumo: Ganseki Otoshi',
    'tsuchigumo_kinjutsu': 'Kinjutsu: Tsuchigumo Bakuretsu', 'jugo_dikenler': 'Shizen Toge',
    'jugo_jet_yumruk': 'Funsha Ken', 'jugo_cekim': 'Shizen Enerugī Kyūin', 'jugo_kalkan': 'Iwahada no Kara',
    'jugo_top_kol': 'Shizen Taihō', 'jugo_ofke': 'Gekido Henka', 'funato_mizu_ito': 'Suiton: Mizu Ito',
    'funato_nami_giri': 'Suiton: Nami Giri', 'funato_kani_yoroi': 'Kani Kōra no Yoroi', 'funato_uzu': 'Suiton: Uzu Wana',
    'funato_mizu_tatsumaki': 'Suiton: Mizu Tatsumaki', 'funato_kaigan_bunshin': 'Suiton: Umiawa Bunshin',
    'funato_shinkai': 'Suiton: Shinkai Atsu', 'kaminarimon_denko_ken': 'Raiton: Denkō Ken',
    'kaminarimon_raijin_tate': 'Raiton: Raijin no Tate', 'kaminarimon_denki_ito': 'Raiton: Denki Ito Wana',
    'kaminarimon_raikou': 'Raiton: Raikō Sō', 'kaminarimon_raikyu_ame': 'Raiton: Raikyū no Ame',
    'kaminarimon_kuro_ikazuchi': 'Raiton: Kuro Ikazuchi Uchi', 'kaminarimon_tenrai': 'Raiton: Tenrai Chū',
    'otsutsuki_haikotsu': 'Haikotsu Hari', 'otsutsuki_kinko': 'Kinkō Chakra no Wa', 'otsutsuki_tsubasa': 'Shinyoku',
    'otsutsuki_gudodama': 'Gudōdama', 'otsutsuki_kubi': 'Kami no Tsurugi', 'otsutsuki_kugeki': 'Shinkū Shō',
    'otsutsuki_jikukan': 'Jikūkan Mon', 'otsutsuki_ten_no_kama': 'Tengetsu Rakka', 'namikaze_shunpo': 'Kōshin Ho',
    'namikaze_sankunai': 'Sanko Kunai Ōgi', 'namikaze_shiki': 'Hiraishin Shiki', 'namikaze_kekkai': 'Fūin Kekkai',
    'namikaze_zanzou': 'Kōsen Zanzō', 'namikaze_senko_rendan': 'Hiraishin: Senkō Rendan',
    'namikaze_kiiro_senko': 'Hiraishin: Kiiro Senkō Arashi', 'yuhi_hanabira': 'Genjutsu: Hanabira Gen\'ei',
    'yuhi_kokuangyo': 'Genjutsu: Yami Yoru', 'yuhi_sarmasik': 'Genjutsu: Tsuta Shibari', 'yuhi_ayna': 'Genjutsu: Kagami Utsushi',
    'yuhi_kelebek': 'Genjutsu: Akachō no Mure', 'yuhi_genei_ken': 'Genjutsu: Gen\'ei Ken', 'yuhi_kabus': 'Genjutsu: Akumu no Mori',
    'yuhi_kyoka': 'Genjutsu: Tsuki Kagami Hana', 'gekko_iai': 'Gekkō: Yoru Iai', 'gekko_tsukikage': 'Gekkō: Tsukikage Ashi',
    'gekko_sanjin': 'Gekkō: Mikazuki Sanjin', 'gekko_tsuki_no_kagami': 'Gekkō: Tsuki no Kagami', 'gekko_bunshin_mai': 'Gekkō: Mikazuki Kage Mai',
    'gekko_hangetsu': 'Gekkō: Hangetsu Giri', 'gekko_mangetsu': 'Gekkō: Mangetsu Zan', 'gekko_tsukiyo': 'Gekkō: Tsukiyo no Ame',
    'mitarashi_senei': 'Sen\'ei Jashu', 'mitarashi_jagei': 'Jabi', 'mitarashi_doku_kiba': 'Dokuga Kunai',
    'mitarashi_dachi': 'Dappi no Jutsu', 'mitarashi_tasou': 'Tatō Jashu', 'mitarashi_yuva': 'Hebi no Su',
    'mitarashi_jagan': 'Jagan Kanashibari', 'mitarashi_orochi': 'Kuchiyose: Ōhebi', 'shiranui_fukibari': 'Kuchi Senbon',
    'shiranui_senbon_ame': 'Senbon no Ame', 'shiranui_tenketsu': 'Tenketsu Bari', 'shiranui_kasumi': 'Senpū Senbon',
    'shiranui_kagebari': 'Kagebari', 'shiranui_kasoku': 'Kasoku Sashi', 'shiranui_hyakubari': 'Hyakubari Arashi',
    'shiranui_kafes': 'Gin Bari no Ori', 'momochi_mukuro': 'Sairento Kiringu', 'momochi_kubikiri': 'Kubikiri Nagi',
    'momochi_suiro': 'Suiton: Suirō no Jutsu', 'momochi_mizu_bunshin': 'Kirigakure: Mizu Bunshin', 'momochi_kishin': 'Kishin no Kiai',
    'momochi_kiyim': 'Kirigakure: Kiri Giri', 'kurosuki_kiba': 'Kiba Giri', 'kurosuki_raiu': 'Raiton: Raiu',
    'kurosuki_kuro_kumo': 'Raiton: Kurokumo', 'kurosuki_rakurai': 'Raiton: Rakurai', 'kurosuki_tate': 'Raiton: Raimaku',
    'kurosuki_ikazuchi_kiba': 'Raiton: Ikazuchi no Kiba', 'kurosuki_raiko': 'Raiton: Raikō Shintai', 'kurosuki_arashi': 'Raiton: Kuro Arashi',
    'hagoromo_kasumi_giri': 'Kasumi Gen\'ei Giri', 'hagoromo_hane': 'Hane Yaiba', 'hagoromo_genkaku': 'Genkaku Ken',
    'hagoromo_tennyo': 'Tennyo no Hagoromo', 'hagoromo_utsusemi': 'Utsusemi', 'hagoromo_hane_mai': 'Hane Mai',
    'hagoromo_tenba': 'Tenba Kassō', 'hagoromo_kyomu': 'Kyomu no Maku',
}

TR = re.compile('[çğıöşüÇĞİÖŞÜ]')
TRW = re.compile(r'\b(ve|ile|Kan|Gece|Ay|Ateş|Su|Rüzgar|Toprak|Gölge|Dev|Kara|Ak)\b')


def apply(out):
    """out: jutsu sözlüğü. Dönüş: hâlâ Türkçe kalan (sözlükte olmayan) idler."""
    missing = []
    for k, j in out.items():
        if not isinstance(j, dict):
            continue
        nm = j.get('name', '')
        m = re.match(r'^(.*?)\s*\(([^()]*)\)\s*$', nm)
        if m:
            j['name'] = m.group(1).strip()
            j['meaning'] = m.group(2).strip()
            nm = j['name']
        if k in JP:
            if not j.get('meaning'):
                j['meaning'] = nm
            j['name'] = JP[k]
        elif TR.search(nm) or TRW.search(nm):
            missing.append((k, nm))
    return missing
