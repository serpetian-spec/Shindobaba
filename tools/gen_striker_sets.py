# Shinobi Striker kostüm referanslarından (refs/outfits_ss) oyunun mevcut kıyafet parçalarıyla setler üretir
# -> godot/scripts/core/striker_sets.gd  (Gear.item bunu da okur)
# Satır: (ref no, kimlik, ad, açıklama, akış rengi, [(parça, c1, c2), ...], ek)
#   ek: "f" (bonus türü s/m/c/h/d) varsayılan d; cinsiyet ve sıra list.txt'ten (wiki kategorileri)
import json, re, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
lst = {}
for line in open(os.path.join(ROOT, '_tmp/ss_outfit/list.txt'), encoding='utf-8'):
    m = re.match(r'(\d+) ([FMU]) ([ABCS]*) (.*?) \|', line)
    if m:
        lst[int(m.group(1))] = (m.group(2), m.group(3), m.group(4))

def rank_of(r):
    if 'C' in r: return 0
    if 'B' in r: return 1
    if 'A' in r: return 2
    return 3

S = 'sandalet'
D = [
 (0, 'gunesi', 'Taiyō Kimono', 'Tek kolu açık, güneş desenli turuncu kimono, siyah kuşak, bol pantolon.', 'c', [('kimono_ust', 'e08a1e', 'c0392b'), ('bol_pantolon', 'e0a33a', None), ('zori', '6b4a2b', 'e8d6a8')]),
 (1, 'iryo_hemsire', 'Iryō Shōzoku', 'Pembe hemşire gömleği, beyaz kısa etek; sırtında 医.', 'h', [('yakali', 'f2d0d8', 'c0392b'), ('etek_mini', 'f4f2ee', None), ('uzun_sargi_eldiven', 'f4f2ee', None), ('tabi', 'f4f2ee', 'c0392b')]),
 (3, 'genis_yaka', 'Kuro Hiroeri', 'Geniş yakalı siyah gömlek, krem bol pantolon, yeşil ayakkabı.', 'm', [('tisort', '1c1c20', '1c1c20'), ('bol_pantolon', 'e6dfc8', None), ('ayak_002', '3c8a52', 'e6dfc8')]),
 (7, 'anbu_kapuson', 'Kakure Gaitō', 'Yırtık kapüşonlu krem uzun palto, siyah pantolon, kemerli botlar.', 's', [('golge_ust', '1c1c20', '1c1c20'), ('siyah_pant', '1c1c20', None), ('anbu_beyaz_palto', 'e8e0cc', None), ('ayak_009', '1c1c20', '9a9a9a')]),
 (8, 'yirminci', 'Hōshuku Kimono', 'Turuncu kimono, kuşak ve bol pantolon; kutlama giysisi.', 'c', [('kimono_ust', 'e0782a', '2a2a30'), ('bol_pantolon', '2a3050', None), ('zori', '6b4a2b', 'e8d6a8')]),
 (9, 'tehlike_ceket', 'Kiken Haori', 'File iç gömlek üstüne açık kahve ceket, koyu kahve etek.', 's', [('file_atlet', '2a2a30', '2a2a30'), ('etek_diz', '5a3a28', None), ('uzun_palto', 'cdb48a', None), ('sandalet', '2a3050', 'e8e8e4')]),
 (10, 'sigara_jonin', 'Kemuri Jōnin', 'Lacivert ninja takımı, kollarda beyaz sargı, beyaz bel peştamalı, yeşil yelek.', 'm', [('uzun_gomlek', '1e2a48', '1e2a48'), ('ninja_pant', '1e2a48', None), ('chunin_yelek', '4e6a48', None), ('kol_sargisi', 'eeeeea', None), ('anbu_atki', 'eeeeea', None), (S, '1e2a48', 'eeeeea')]),
 (11, 'alti_yol', 'Rokudō Koromo', 'Dik yakalı beyaz cübbe, göğüste tomoe dizisi, lacivert kuşak.', 'c', [('uzun_gomlek', 'e8e8e4', 'e8e8e4'), ('sivil_pant', 'e8e8e4', None), ('kesis_cubbesi', 'eeeeea', '2a3a6a'), ('tabi', 'e8e8e4', '1c1c20')]),
 (12, 'sahil', 'Kaigan Shōzoku', 'Kolsuz turuncu şişme yelek, koyu yeşil şort, parmak arası terlik.', 's', [('atlet', 'f0f0ec', 'f0f0ec'), ('kisa_sort', '2e5a3a', None), ('deri_yelek', 'f08a2a', None), ('zori', '2a3050', 'e8e8e4')]),
 (13, 'esofman', 'Kuro Ressha', 'Pembe biyeli siyah eşofman, beyaz iç tişört, baldır sargısı.', 's', [('panel_ceket', '1c1c22', 'd84a6a'), ('ninja_pant', '1c1c22', None), (S, '1c1c22', 'eeeeea')]),
 (14, 'esofman2', 'Kuro Ressha Ni', 'Kırmızı biyeli siyah fermuarlı ceket ve pantolon, kol koruması.', 's', [('panel_ceket', '1c1c22', 'c02a2a'), ('ninja_pant', '1c1c22', None), ('kolluk', '3a3a40', None), (S, '1c1c22', 'eeeeea')]),
 (15, 'esofman_yirtik', 'Yabureta Ressha', 'Yırtık siyah eşofman ceketi, açık renk iç giysi.', 's', [('panel_ceket', '1c1c22', 'c02a2a'), ('yamali_pant', '1c1c22', None), ('atki', 'd8d0c0', None), (S, '1c1c22', 'eeeeea')]),
 (16, 'kutlama', 'Shukuen Kimono', 'Alev desenli kırmızı kimono, mavi kenarlar, beyaz kürk atkı.', 'c', [('biyeli_kimono', 'c0302a', '2a4a9a'), ('hakama', '2a3060', None), ('atki', 'f4f2ee', None), ('zori', '6b4a2b', 'e8d6a8')]),
 (17, 'kimono_etek', 'Shiro Kimono Hakama', 'Beyaz kimono üst ve etek, file iç, kahve kemer, uzun siyah çorap.', 'h', [('kimono_ust', 'f2f0ea', '8a5a2a'), ('etek_diz', 'f2f0ea', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (18, 'yemek', 'Shoku Haori', 'Krem tişört üstüne yeşil ceket, koyu kırmızı pantolon.', 'h', [('tisort', 'e8e0cc', 'e8e0cc'), ('haori', '2e6a3a', None), ('ninja_pant', '5a1e22', None), (S, '1c1c20', 'eeeeea')]),
 (19, 'bulut_striker', 'Kumo Striker', 'Gri tişört, kırık beyaz atkı ve sargılar, beyaz biyeli kırmızı etek.', 's', [('tisort', 'a8aaae', 'a8aaae'), ('etek_diz', 'b0282a', None), ('atki', 'e8e4da', None), ('kol_sargisi', 'e8e4da', None), (S, '2a2a30', 'e8e4da')]),
 (20, 'kod', 'Kokuin Shōzoku', 'Lila yakalı koyu takım, bol mor paçalı pantolon.', 'm', [('yakali', '2a2a34', '9a7ac0'), ('bol_pantolon', '6a4a8a', None), ('eldiven', '1c1c20', None), (S, '1c1c20', '9a7ac0')]),
 (21, 'samuray_kuro', 'Kurogane Yoroi', 'Siyah samuray zırhı, beyaz ip kuşak, kırmızı kenarlar.', 'd', [('golge_ust', '1c1c22', '1c1c22'), ('hakama', '1c1c22', None), ('sengoku_kara', '1c1c22', None), ('ayak_012', '2a2a30', 'c0302a')]),
 (22, 'siyah_tulum', 'Kurokawa', 'Göğsü kayışlı simsiyah tulum, bileklik ve kaval koruyucu.', 's', [('golge_ust', '141418', '141418'), ('siyah_pant', '141418', None), ('kayis_kosum', '2a2a30', None), ('bacak_koruma', '5a5a60', None), ('siyah_tabi', '141418', '141418')]),
 (23, 'seytan', 'Akuma Fūdo', 'Kırmızı kapüşonlu uzun kollu üst, kırmızı şort, gri kemer ve zincir.', 'm', [('ceket', 'b0242a', 'b0242a'), ('kisa_sort', 'b0242a', None), ('kayis_kosum', '7a7a80', None), (S, '1c1c20', 'eeeeea')]),
 (24, 'kok_reisi', 'Ne no Osa', 'Beyaz kimono, siyah hakama, soluk mor kuşak, sargılı sağ kol.', 'c', [('kimono_ust', 'eceae4', '9a8ab0'), ('hakama', '1c1c22', None), ('kol_sargisi', 'eceae4', None), ('zori', '2a2a30', 'e8d6a8')]),
 (25, 'delta', 'Sankaku Tsunagi', 'Omuzları açık soluk mavi tulum, beyaz manşetler.', 's', [('atlet', '7a9ab8', '7a9ab8'), ('sivil_pant', '7a9ab8', None), ('eldiven', 'f2f0ea', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (26, 'denki', 'Denki Shōzoku', 'Cepli mavi gömlek, kıvrık paçalı mavi şort, açık mavi fular.', 's', [('yakali', '2a5ab8', '2a5ab8'), ('kisa_sort', '2a5ab8', None), (S, '1c1c20', 'eeeeea')]),
 (27, 'gezegen', 'Hoshi Sukāto', 'Yüksek yakalı kabarık beyaz üst, yıldız desenli siyah etek.', 'c', [('yakali', 'f4f2ee', 'f4f2ee'), ('etek_mini', '1c1c24', None), ('ayak_004', 'e8d0b8', 'e8d0b8')]),
 (28, 'kurbaga', 'Gama Kigurumi', 'Parmakları belli kabarık yeşil kurbağa tulumu.', 'h', [('golge_ust', '5ac04a', '5ac04a'), ('sivil_pant', '5ac04a', None), ('eldiven', '5ac04a', None), ('tabi', '5ac04a', '5ac04a')]),
 (29, 'yedi_kanat', 'Nanao Shōzoku', 'File üstüne beyaz kısa üst, beyaz kolluk, beyaz etek.', 's', [('file_atlet', '1c1c20', '1c1c20'), ('etek_mini', 'f2f0ea', None), ('uchiha_kolluk', 'f2f0ea', None), ('ayak_009', 'f2f0ea', 'f2f0ea')]),
 (30, 'kizil_palto', 'Akasuna Gaitō', 'Siyah düğmeli kırmızı uzun palto, iki kahve kemer.', 'd', [('uzun_gomlek', '8a1e2a', '8a1e2a'), ('siyah_pant', '1c1c20', None), ('uzun_palto', '8a1e2a', None), ('kayis_kosum', '6a4a2a', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (31, 'kum_cocuk', 'Suna Kodomo', 'Siyah tulum, çapraz beyaz kuşak, kahve kemer.', 'd', [('golge_ust', '1c1c20', '1c1c20'), ('ninja_pant', '1c1c20', None), ('kesa', 'e8e4da', None), (S, '1c1c20', 'eeeeea')]),
 (32, 'kizil_palto2', 'Akasuna Gaitō Ni', 'Uzun koyu kızıl palto, mavimsi gri gövde zırhı.', 'd', [('uzun_gomlek', '7a1a24', '7a1a24'), ('siyah_pant', '1c1c20', None), ('suna_yelek', '6a7480', None), ('uzun_palto', '7a1a24', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (33, 'yesil_canavar', 'Midori Tsunagi', 'Yeşil tulum, açık fermuarlı yeşil yelek, turuncu tozluk.', 'm', [('golge_ust', '2e6a3a', '2e6a3a'), ('ninja_pant', '2e6a3a', None), ('chunin_yelek', '6e9a6a', None), ('agirlikli_tozluk', 'e8842a', None), (S, '1c1c20', 'eeeeea')]),
 (34, 'yesil_canavar2', 'Midori Tsunagi Ni', 'Koyu yeşil tulum, kırmızı kemerli yeşil yelek, turuncu tozluk.', 'm', [('golge_ust', '1e4a2a', '1e4a2a'), ('ninja_pant', '1e4a2a', None), ('chunin_yelek', '3e7a4a', None), ('agirlikli_tozluk', 'e8842a', None), (S, '1c1c20', 'eeeeea')]),
 (35, 'buz_kimono', 'Hyōsetsu Kimono', 'Beyaz biyeli kısa mavi kimono, kahve tulum ve kısa hakama.', 'c', [('biyeli_kimono', '2a3a8a', 'f2f0ea'), ('hakama', '4a3a2a', None), ('zori', '2a2a30', 'e8d6a8')]),
 (36, 'buz_kimono2', 'Hyōsetsu Yukata', 'Girdap desenli soluk pembe kısa kimono, kırık beyaz kuşak.', 'c', [('yukata', 'f2d4d8', '6a3a6a'), ('etek_diz', 'f2d4d8', None), ('zori', '2a2a30', 'e8d6a8')]),
 (37, 'buhar_zirh', 'Jōki Yoroi', 'Kırmızı balıkçı yaka üstüne yırtık kollu gri-siyah gi, gri pantolon.', 'd', [('zirhli_gomlek', '8a1a22', '8a1a22'), ('bol_pantolon', '6a6a70', None), ('samuray_zirh', '3a3a40', None), ('eldiven', '1c1c20', None), ('ayak_012', '3a3a40', '8a1a22')]),
 (38, 'hime_hakama', 'Hime Hakama', 'İki tonlu turuncu kimono, kırmızı hakama, soluk sarı kuşak.', 'c', [('kimono_ust', 'e89a3a', 'f0d878'), ('kizil_hakama', 'c0302a', None), ('zori', 'c0302a', 'e8d6a8')]),
 (39, 'orman_zirh', 'Mori Yoroi', 'Kısa kesim lacivert tulum, kızıl zırh ve kolluklar, sırtta parşömen.', 'd', [('golge_ust', '1e2a48', '1e2a48'), ('ninja_pant', '1e2a48', None), ('sengoku_kizil', '9a1e22', None), ('kolluk', '9a1e22', None), (S, '1c1c20', 'eeeeea')]),
 (40, 'orman_zirh_genc', 'Mori Yoroi Wakate', 'Siyah kimono üstüne zeytin yeşili zırh ve omuzluklar.', 'd', [('kimono_ust', '1c1c20', '1c1c20'), ('hakama', '1c1c20', None), ('sengoku_kahve', '5a6a3a', None), ('ayak_012', '3a3a30', '5a6a3a')]),
 (41, 'soylu_pelerin', 'Kizoku Gaitō', 'Uzun beyaz kimono üstünde koyu yeşil pelerin, mavi obi.', 'c', [('beyaz_arma', 'eeeeea', '2a4a8a'), ('sivil_pant', '2a4a8a', None), ('gece_pelerini', '1e3a2a', None), ('ayak_004', '2a4a8a', '2a4a8a')]),
 (42, 'kumo_genin', 'Kumo Genin Shōzoku', 'Kısa kollu lacivert tulum, tek omzu askılı beyaz-gri ceket.', 's', [('uzun_gomlek', '1e2a48', '1e2a48'), ('ninja_pant', '1e2a48', None), ('kumo_yelek', 'e8e8e4', None), ('kumo_kaval', 'd8d8d4', None), (S, '1c1c20', 'eeeeea')]),
 (43, 'konoha_genin', 'Konoha Genin Shōzoku', 'Kolları ve paçaları kıvrık lacivert tulum, yeşil yelek, sağ bacakta beyaz sargı.', 'h', [('uzun_gomlek', '1e2a48', '1e2a48'), ('ninja_pant', '1e2a48', None), ('chunin_yelek', '5e8a5a', None), (S, '1e2a48', 'eeeeea')]),
 (44, 'kiri_genin', 'Kiri Genin Shōzoku', 'Kısa kollu kahve tulum, mavimsi beyaz yelek, açık mavi kolluklar.', 'c', [('uzun_gomlek', '4a3a2e', '4a3a2e'), ('ninja_pant', '4a3a2e', None), ('kiri_yelek', 'b8c4d4', None), ('kiri_koruma', '8aa8d0', None), (S, '1c1c20', 'eeeeea')]),
 (45, 'suna_genin', 'Suna Genin Shōzoku', 'Kısa kesim kara-kahve tulum, omuzluklu kahve yelek, gri atkı.', 'h', [('uzun_gomlek', '2a2420', '2a2420'), ('ninja_pant', '2a2420', None), ('suna_yelek', '7a5a3a', None), ('atki', 'a8a8a4', None), (S, '1c1c20', 'eeeeea')]),
 (46, 'iwa_genin', 'Iwa Genin Shōzoku', 'Kırmızı tulum, sırtı çantalı kahve ceket, sağ omuzda kırmızı kuşak.', 'd', [('tek_kol_ust', 'a82228', 'a82228'), ('iwa_pant', 'a82228', None), ('iwa_yelek', '5a4030', None), (S, '1c1c20', '6a6a70')]),
 (47, 'gunebakan', 'Himawari Fūdo', 'Sarı kapüşonlu üst, pembe kısa etek, siyah tayt.', 's', [('ceket', 'f0c84a', 'f0c84a'), ('etek_mini', 'e86a8a', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (48, 'lavanta_ceket', 'Fuji Fūdo', 'Lavanta-beyaz kapüşonlu üst, lacivert pantolon, beyaz sargı.', 'c', [('ceket', 'a89ad8', 'f2f0ea'), ('ninja_pant', '2a3a6a', None), (S, '2a3a6a', 'eeeeea')]),
 (49, 'pembe_ceket', 'Momo Uwagi', 'Beyaz gömlek üstüne pembe ceket, haki şort.', 'c', [('panel_ceket', 'e8b0c8', 'f2f0ea'), ('kisa_sort', 'b8a878', None), ('ayak_009', '4a2a5a', '4a2a5a')]),
 (50, 'acik_ceket', 'Fuji Fūdo Kai', 'Fermuarı açık lavanta ceket, kot şort.', 's', [('ceket', 'a89ad8', 'f2f0ea'), ('kisa_sort', '3a5a9a', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (51, 'mor_kemer', 'Murasaki Obi', 'Kolsuz lavanta üst, koyu mor kemer, koyu mor şort.', 's', [('kolsuz_yakali', 'b8a8e0', 'b8a8e0'), ('kisa_sort', '3a2a5a', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (52, 'pembe_kazak', 'Momo Sētā', 'Pembe-beyaz kısa kollu kazak, gri uzun kollu iç, pembe biyeli gri etek.', 'h', [('tisort', 'f0c8d8', 'f0c8d8'), ('etek_uzun', 'd8d0d4', None), ('uzun_sargi_eldiven', '6a6a70', None), ('ayak_004', '6a6a70', '6a6a70')]),
 (53, 'gelinlik', 'Kuro Hanayome', 'İki tonlu uzun siyah gelinlik ve eldiven.', 'c', [('kolsuz_yakali', '2a1e2a', '2a1e2a'), ('etek_uzun', '2a1e2a', None), ('eldiven', '1c1c20', None), ('tabi', '1c1c20', '1c1c20')]),
 (54, 'ates_pelerin', 'Hi no Gaitō', 'File iç ile siyah tulum, gri pelerin, mavi kemer.', 'c', [('golge_ust', '1c1c20', '1c1c20'), ('ninja_pant', '1c1c20', None), ('seyahat_pelerini', '8a8a90', None), (S, '1c1c20', 'eeeeea')]),
 (55, 'mor_etek', 'Murasaki Kunoichi', 'Kolsuz mor kısa üst, mor etek, file dirsek ve dizlikler.', 's', [('kolsuz_yakali', '7a3aa8', '7a3aa8'), ('etek_diz', '7a3aa8', None), ('dizlik', 'b8b8bc', None), (S, '1c1c20', 'eeeeea')]),
 (56, 'mor_genc', 'Murasaki Kodomo', 'İki parça mor kıyafet, mavi kemer, açık kahve çanta.', 's', [('tisort', '7a3aa8', '7a3aa8'), ('etek_diz', '2a2a5a', None), (S, '2a2a5a', 'eeeeea')]),
 (57, 'mor_uzun', 'Murasaki Nagasukāto', 'Kolsuz mor kısa üst, mor uzun etek, siyah sandalet.', 'c', [('kolsuz_yakali', '6a3a9a', '6a3a9a'), ('etek_uzun', '6a3a9a', None), ('ayak_018', '1c1c20', '1c1c20')]),
 (58, 'murekkep', 'Sumi Shōzoku', 'Omuzları kırmızı bantlı siyah kısa üst ve pantolon, gri iç.', 'c', [('tek_kol_ust', '1c1c24', 'c02a2a'), ('ninja_pant', '2a2a5a', None), ('eldiven', '1c1c20', None), (S, '1c1c20', 'eeeeea')]),
 (59, 'goksel_beyaz', 'Ten no Koromo', 'Kırmızı kenarlı beyaz pelerin, tomoe desenli kollar, siyah pantolon.', 'c', [('uzun_gomlek', '1c1c20', '1c1c20'), ('siyah_pant', '1c1c20', None), ('uzun_palto', 'f2f0ea', 'a82228'), ('ayak_009', '1c1c20', '1c1c20')]),
 (60, 'karga_tunik', 'Karasu Tunikku', 'File astarlı mavimsi gri tunik, beyaz kemer, kolyeli.', 'c', [('tunik', '4a4a6a', 'f2f0ea'), ('siyah_pant', '3a3a5a', None), ('kol_sargisi', 'eeeeea', None), (S, '1c1c20', 'eeeeea')]),
 (61, 'karga_cubbe', 'Karasu Koromo', 'Ortası fermuarlı haki astarlı bordo cübbe.', 'c', [('uzun_gomlek', '1c1c20', '1c1c20'), ('siyah_pant', '1c1c20', None), ('kesis_cubbesi', '6a1a22', 'b8a878'), (S, '1c1c20', 'eeeeea')]),
 (62, 'kaya_paltosu', 'Iwa Sodenashi', 'Gri iç üstüne kolsuz lacivert uzun palto.', 'd', [('tisort', '8a8a90', '8a8a90'), ('ninja_pant', '2a2a3a', None), ('bantli_palto', '1e3a4a', 'c02a2a'), (S, '1c1c20', 'eeeeea')]),
 (63, 'kabuk_cubbe', 'Kara Koromo', 'Kolları siyah desenli beyaz cübbe, kırmızı kuşak.', 'c', [('uzun_gomlek', 'e8e8e4', 'e8e8e4'), ('sivil_pant', 'e8e8e4', None), ('kesis_cubbesi', 'f2f0ea', '1c1c20'), ('zori', '2a2a30', 'e8d6a8')]),
 (64, 'kurbaga_bilge', 'Gama Sennin', 'Soluk yeşil kimono, file iç, sarı benekli kırmızı yelek.', 'c', [('kimono_ust', '9ab88a', '9ab88a'), ('bol_pantolon', '9ab88a', None), ('deri_yelek', 'b0242a', None), ('ayak_018', '6b4a2b', 'e8d6a8')]),
 (65, 'kurbaga_bilge2', 'Gama Sennin Kai', 'Soluk yeşil kimono, uzun kırmızı haori.', 'c', [('kimono_ust', '9ab88a', '9ab88a'), ('bol_pantolon', '9ab88a', None), ('sennin_haorisi', 'b0242a', 'f0c84a'), ('ayak_018', '6b4a2b', 'e8d6a8')]),
 (66, 'yilan_cubbe', 'Hebi Koromo', 'Ortası beyaz çizgili, kapüşonlu koyu kırmızı cübbe.', 'c', [('golge_ust', '1c1c20', '1c1c20'), ('siyah_pant', '1c1c20', None), ('kesis_cubbesi', '6a1a22', 'f2f0ea'), (S, '1c1c20', 'eeeeea')]),
 (67, 'kizil_zirh', 'Shinku Yoroi', 'Siyah dar üst, kızıl göğüs zırhı, kolluk ve kaval koruyucu.', 'd', [('golge_ust', '1c1c20', '1c1c20'), ('siyah_pant', '8a1a22', None), ('lake_zirh', '9a1e22', None), ('tam_koruma', '9a1e22', None), (S, '1c1c20', 'eeeeea')]),
 (68, 'tavsan_tanri', 'Megami Kimono', 'Yere uzanan beyaz kimono, siyah tomoe, sarı-mor biye.', 'c', [('biyeli_kimono', 'f4f2ee', '6a2a8a'), ('etek_uzun', 'f4f2ee', None), ('tabi', 'f4f2ee', 'f4f2ee')]),
 (69, 'tavsan_tanri2', 'Megami Koromo', 'Siyah biyeli bembeyaz giysi, sarı iç, siyah pantolon.', 'c', [('beyaz_arma', 'f4f2ee', '1c1c20'), ('siyah_pant', '1c1c20', None), ('kesis_cubbesi', 'f4f2ee', '1c1c20'), ('ayak_009', '1c1c20', '1c1c20')]),
 (70, 'maskeli_gaiden', 'Kakashi Gaiden', 'Maskeli lacivert takım, omuzları gri, kollukları kayışlı.', 's', [('uzun_gomlek', '1e2a48', '8a8a90'), ('ninja_pant', '1e2a48', None), ('kayis_kosum', '6a4a2a', None), ('uchiha_kolluk', '1e2a48', None), (S, '1e2a48', 'eeeeea')]),
 (71, 'ic_giysi', 'Shitagi Shōzoku', 'Yeleksiz lacivert ninja iç giysisi, maske.', 's', [('uzun_gomlek', '1e2a48', '1e2a48'), ('ninja_pant', '1e2a48', None), (S, '1e2a48', 'eeeeea')]),
 (72, 'maskeli_jonin', 'Kamen Jōnin', 'Maskeli lacivert tulum, yeşil yelek, sol kolda kırmızı bant.', 's', [('uzun_gomlek', '1e2a48', '1e2a48'), ('ninja_pant', '1e2a48', None), ('chunin_yelek', '4e6a48', None), ('eldiven', '1e2a48', None), (S, '1e2a48', 'eeeeea')]),
 (73, 'altinci', 'Rokudaime Gaitō', 'Uzun kırık beyaz pelerin, lacivert takım.', 'c', [('uzun_gomlek', '1e2a48', '1e2a48'), ('ninja_pant', '1e2a48', None), ('kage_cubbesi', 'f2f0ea', 'c02a2a'), (S, '1e2a48', 'eeeeea')]),
 (74, 'maskeli_genc', 'Kamen Wakate', 'Konoha takımı, mavi eldiven ve maske.', 's', [('uzun_gomlek', '1e2a48', '1e2a48'), ('ninja_pant', '1e2a48', None), ('chunin_yelek', '5e8a5a', None), ('eldiven', '2a4a8a', None), (S, '1e2a48', 'eeeeea')]),
 (75, 'bes_kalp', 'Itoguchi Shōzoku', 'Beyaz kemerli siyah yelek, gri atkı, açık gri pantolon.', 'h', [('kolsuz_yakali', '1c1c20', '1c1c20'), ('sivil_pant', 'a8a8b0', None), ('atki', '7a7a80', None), ('ayak_012', '1c1c20', 'f2f0ea')]),
 (76, 'kukla', 'Kugutsu Shōzoku', 'Siyah kapüşonlu tulum, kırmızı kuşak.', 'c', [('golge_ust', '1c1c22', '1c1c22'), ('ninja_pant', '1c1c22', None), (S, '1c1c22', 'eeeeea')]),
 (77, 'algi', 'Kanchi Shōzoku', 'Gri kemerli açık mor gömlek, siyah şort, uzun çorap.', 'c', [('yakali', 'b8a0d8', 'b8a0d8'), ('kisa_sort', '1c1c20', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (78, 'kabuk_cocuk', 'Kara Sodenashi', 'Yeşil atlet üstüne iki tonlu mavi kolsuz ceket.', 'm', [('atlet', '3a8a4a', '3a8a4a'), ('siyah_pant', '2a2a30', None), ('bantli_palto', '2a4a8a', '6a8ac0'), (S, '1c1c20', 'eeeeea')]),
 (79, 'kabuk_okul', 'Kara Gakusei', 'Cepli uzun mavi kolsuz palto.', 'm', [('tisort', 'f2f0ea', 'f2f0ea'), ('siyah_pant', '2a2a30', None), ('bantli_palto', '2a4a8a', '2a4a8a'), (S, '1c1c20', 'eeeeea')]),
 (80, 'kabuk_yirtik', 'Kara Ruro', 'Açık gri tulum üstüne yıpranmış mor palto, mor atkı.', 'm', [('golge_ust', 'b8b8bc', 'b8b8bc'), ('sivil_pant', 'b8b8bc', None), ('yirtik_pelerin', '5a3a6a', None), ('atki', '6a3a7a', None), (S, '1c1c20', 'eeeeea')]),
 (81, 'demir_dovme', 'Tetsu Shōzoku', 'Gömleksiz Kumo takımı, beyaz yelek, bel kuşağı.', 'm', [('atlet', 'c8a07a', 'c8a07a'), ('ninja_pant', '1e2a48', None), ('kumo_yelek', 'e8e8e4', None), ('kumo_kaval', 'd8d8d4', None), (S, '1c1c20', 'eeeeea')]),
 (82, 'kizil_kayis', 'Akaobi Shōzoku', 'Kayışlı kırmızı-siyah üst, gri bileklik, kahve kemerli kılıflık.', 'm', [('tek_kol_ust', 'a82228', '1c1c20'), ('ninja_pant', '6a1a22', None), ('kayis_kosum', '6a4a2a', None), ('kolluk', '8a8a90', None), (S, '1c1c20', 'eeeeea')]),
 (83, 'kagit_melek', 'Kami Kimono', 'Yeşil biyeli siyah kimono üst, gri katmanlı kuşak.', 'c', [('biyeli_kimono', '1c1c20', '2e6a4a'), ('etek_diz', '9ab8d8', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (84, 'yeni_nesil', 'Shinsedai Jōnin', 'Lacivert tulum, yeşil yelek, mavi atkı.', 'h', [('uzun_gomlek', '1e2a48', '1e2a48'), ('ninja_pant', '1e2a48', None), ('chunin_yelek', '6a9a6a', None), ('atki', '2a7ac0', None), (S, '1e2a48', 'eeeeea')]),
 (85, 'yeni_nesil2', 'Shinsedai Haori', 'Siyah biyeli gri-yeşil ceket, kahve pantolon, uzun mavi atkı.', 'h', [('panel_ceket', '9aa898', '1c1c20'), ('ninja_pant', '6a4a2a', None), ('atki', '2a7ac0', None), (S, '1c1c20', 'eeeeea')]),
 (86, 'genjutsu_sargi', 'Gensō Hōtai', 'Tek kırmızı kol, beyaz-siyah sargı elbise, file iç.', 'c', [('sargili_kolsuz', 'f2f0ea', 'a82228'), ('etek_diz', 'f2f0ea', None), ('kol_sargisi', 'f2f0ea', None), (S, '1c1c20', 'eeeeea')]),
 (87, 'onluk', 'Daidokoro Shōzoku', 'Beyaz fermuarlı gömlek üstüne yeşil önlük, gri bot.', 'h', [('yakali', 'f2f0ea', 'f2f0ea'), ('etek_uzun', '2e5a3a', None), ('ayak_004', '8a8a90', '8a8a90')]),
 (88, 'yaprak_striker', 'Konoha Striker', 'Dal desenli soluk yeşil ceket, sol omuzda girdap.', 'h', [('ceket', 'a8c89a', '2e5a3a'), ('ninja_pant', '2a3a2e', None), (S, '1c1c20', 'eeeeea')]),
 (89, 'genc_canavar', 'Wakai Midori', 'Koyu yeşil tulum, turuncu atkı ve tozluk, beyaz kol sargısı.', 'm', [('golge_ust', '1e4a2a', '1e4a2a'), ('ninja_pant', '1e4a2a', None), ('turuncu_boyunluk', 'e8842a', None), ('agirlikli_tozluk', 'e8842a', None), (S, '1c1c20', 'eeeeea')]),
 (90, 'simsek_kiyafet', 'Raimei Shōzoku', 'Sarı şimşek desenli gri-beyaz takım, yeşil kuşak.', 's', [('tunik', 'c8c8cc', 'e8e830'), ('sivil_pant', 'c8c8cc', None), ('kol_sargisi', 'e8e830', None), ('ayak_017', '2a2a30', 'e8e830')]),
 (91, 'savas_reisi', 'Shura Yoroi', 'Koyu mor pelerin, çatlak kırmızı zırh.', 'd', [('golge_ust', '2a1e3a', '2a1e3a'), ('ninja_pant', '2a1e3a', None), ('sengoku_kizil', '9a1e22', None), ('gece_pelerini', '2a1e3a', None), (S, '1c1c20', 'eeeeea')]),
 (92, 'savas_reisi2', 'Shura Koromo', 'Etekleri siyah magatama desenli beyaz pelerin, kırmızı yaka.', 'c', [('golge_ust', '1c1c20', '1c1c20'), ('siyah_pant', '1c1c20', None), ('uzun_palto', 'f2f0ea', 'a82228'), ('ayak_009', '1c1c20', '1c1c20')]),
 (93, 'savas_reisi3', 'Shura Gunpuku', 'Göğsü kılıflıklı mor palto, siyah eldiven ve pantolon.', 'm', [('golge_ust', '2a1e3a', '2a1e3a'), ('siyah_pant', '1c1c20', None), ('uzun_palto', '3a2a5a', None), ('kayis_kosum', '6a4a2a', None), ('eldiven', '1c1c20', None), (S, '1c1c20', 'eeeeea')]),
 (94, 'savas_reisi_genc', 'Shura Wakate', 'Açık kemerli moru palto, beyaz bacak sargısı.', 'm', [('golge_ust', '3a2a5a', '3a2a5a'), ('siyah_pant', '1c1c20', None), ('haori', '4a3a6a', None), (S, '1c1c20', 'eeeeea')]),
 (95, 'su_elbise', 'Mizu Doresu', 'Sağ bacaktan yırtmaçlı, beyaz biyeli mavi straplez elbise.', 'c', [('kolsuz_yakali', '2a4ab8', 'f2f0ea'), ('etek_diz', '2a4ab8', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (96, 'kara_palto', 'Kuro Nagagi', 'Gri desenli etekli uzun siyah palto, lacivert kuşak.', 'c', [('golge_ust', '1c1c20', '1c1c20'), ('siyah_pant', '1c1c20', None), ('uzun_palto', '1c1c22', '8a8a90'), (S, '1c1c20', 'eeeeea')]),
 (97, 'metal_canavar', 'Hagane Midori', 'Yeşil tulum, turuncu atkı ve tozluk, siyah kemer.', 'm', [('golge_ust', '2e6a3a', '2e6a3a'), ('ninja_pant', '2e6a3a', None), ('turuncu_boyunluk', 'e8842a', None), ('agirlikli_tozluk', 'e8842a', None), (S, '1c1c20', 'eeeeea')]),
 (98, 'sari_simsek', 'Kōsen Haori', 'Konoha takımı üstüne alev etekli beyaz haori.', 's', [('uzun_gomlek', '1e2a48', '1e2a48'), ('ninja_pant', '1e2a48', None), ('chunin_yelek', '4e6a48', None), ('sennin_haorisi', 'f2f0ea', 'd8302a'), (S, '1e2a48', 'eeeeea')]),
 (99, 'sari_simsek_genc', 'Kōsen Wakate', 'Siyah biyeli gri ceket, file iç, mavi pantolon, uzun bot.', 's', [('panel_ceket', '8a8a90', '1c1c20'), ('ninja_pant', '2a5a9a', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (100, 'sis_striker', 'Kiri Striker', 'Atkılı çok tonlu mor üst, açık mavi kolluk ve tozluk.', 'c', [('denizci_ust', '8a7ab8', '5a4a8a'), ('ninja_pant', '3a3a5a', None), ('kiri_koruma', '9ab8d8', None), (S, '1c1c20', 'eeeeea')]),
 (101, 'yilan_zirh', 'Hebi Yoroi', 'Koyu gri üniforma, göğüs ve sırtta açık gri zırh.', 'd', [('golge_ust', '3a3a40', '3a3a40'), ('siyah_pant', '3a3a40', None), ('anbu_zirh', 'b8b8bc', None), ('ayak_009', '3a3a40', '3a3a40')]),
 (102, 'yilan_kimono', 'Hebi Kimono', 'Beyaz biyeli iki tonlu mavi kimono üst, geniş kahve kuşak.', 'c', [('biyeli_kimono', '3a7ac0', 'f2f0ea'), ('ninja_pant', '2a3a6a', None), (S, '1c1c20', 'eeeeea')]),
 (103, 'kurucu_palto', 'Sōshi Gaitō', 'Ortası kırmızı biyeli dik yakalı siyah palto, gri kuşak.', 'c', [('golge_ust', '1c1c20', '1c1c20'), ('siyah_pant', '1c1c20', None), ('gece_pelerini', '1c1c20', 'a82228'), (S, '1c1c20', 'eeeeea')]),
 (104, 'kurucu_genc', 'Sōshi Wakate', 'Yeşil biyeli siyah kimono üst, gri kuşak, file bileklik.', 'c', [('biyeli_kimono', '1c1c20', '2e6a4a'), ('siyah_pant', '1c1c20', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (105, 'turuncu_esofman', 'Daidai Ressha', 'Turuncu-siyah eşofman, sırtta ve omuzda girdap.', 'h', [('ceket', 'e8842a', '1c1c20'), ('ninja_pant', 'e8842a', None), (S, '1c1c20', 'eeeeea')]),
 (106, 'yaz', 'Natsu Shōzoku', 'Lacivert tişört üstüne kolsuz turuncu yelek, turuncu kapri.', 's', [('tisort', '1e2a48', '1e2a48'), ('kapri', 'e8842a', None), ('deri_yelek', 'e8842a', None), (S, '1c1c20', 'eeeeea')]),
 (107, 'kizil_takim', 'Akagumi Ressha', 'Paçaları kıvrık kızıl-beyaz eşofman.', 's', [('panel_ceket', 'a82228', 'f2f0ea'), ('kapri', 'a82228', None), ('ayak_005', '1c1c20', 'f2f0ea')]),
 (108, 'turuncu_ceket', 'Daidai Uwagi', 'Turuncu-siyah fermuarlı üst, sağ bacakta beyaz sargı.', 'h', [('ceket', 'e8842a', '1c1c20'), ('ninja_pant', '1c1c20', None), (S, '1c1c20', 'eeeeea')]),
 (109, 'siyah_ceket', 'Kuro Uwagi', 'Turuncu fermuarlı siyah ceket, tek kol kıvrık, kırmızı kol bandı.', 'h', [('ceket', '1c1c22', 'e8842a'), ('kapri', 'e89a7a', None), (S, '1c1c20', 'eeeeea')]),
 (110, 'esofman_turuncu2', 'Daidai Undōgi', 'Siyah biyeli turuncu üst, beyaz iç, turuncu biyeli siyah eşofman altı.', 'h', [('panel_ceket', 'e8842a', '1c1c20'), ('bol_pantolon', '3a3a40', None), (S, '1c1c20', 'eeeeea')]),
 (111, 'yirtik_esofman', 'Yabureta Daidai', 'Yırtık turuncu eşofman, file iç.', 'h', [('yamali_gomlek', 'e8842a', '1c1c20'), ('yamali_pant', 'e8842a', None), (S, '1c1c20', 'eeeeea')]),
 (112, 'pijama', 'Nemaki', 'Sırtta girdaplı gri pijama.', 'h', [('uzun_gomlek', 'c8c8d0', 'c8c8d0'), ('sivil_pant', 'c8c8d0', None), ('zori', '6b4a2b', 'e8d6a8')]),
 (113, 'bilge_palto', 'Sennin Gaitō', 'Kırmızı-siyah palto, sırtta dev parşömen.', 'c', [('ceket', 'e8842a', '1c1c20'), ('ninja_pant', '1c1c20', None), ('sennin_haorisi', 'a82228', '1c1c20'), (S, '1c1c20', 'eeeeea')]),
 (114, 'turuncu_genc', 'Daidai Kodomo', 'Beyaz yakalı turuncu-mavi eşofman.', 'h', [('ceket', 'e8842a', '2a4a9a'), ('ninja_pant', 'e8842a', None), (S, '2a4a9a', 'eeeeea')]),
 (115, 'sakaci', 'Itazura Kozō', 'Ceketi belde bağlı siyah tişört, turuncu pantolon.', 's', [('tisort', '1c1c22', '1c1c22'), ('ninja_pant', 'e8842a', None), (S, '1c1c20', 'eeeeea')]),
 (116, 'kader_genc', 'Unmei Wakate', 'Bej kısa kollu ceket, mor şort, sağ kol ve bacakta sargı.', 'c', [('yakali', 'e8e0d0', 'e8e0d0'), ('kisa_sort', '4a3a5a', None), ('kol_sargisi', 'f2f0ea', None), (S, '1c1c20', 'eeeeea')]),
 (117, 'ninja_yolu_tisort', 'Nindō Tīshatsu', 'Önünde mühür baskılı turuncu-lacivert tişört.', 's', [('tisort', 'e8842a', '1e2a48'), ('sivil_pant', '2a2a30', None), (S, '1c1c20', 'eeeeea')]),
 (118, 'maske_pelerin', 'Kamen Gaitō', 'Beyaz biyeli dik yakalı mor pelerin.', 'c', [('golge_ust', '1c1c20', '1c1c20'), ('siyah_pant', '1c1c20', None), ('gece_pelerini', '3a2a6a', 'f2f0ea'), (S, '1c1c20', 'eeeeea')]),
 (119, 'gozluk_genc', 'Gōguru Wakate', 'Turuncu astarlı lacivert takım, lacivert eldiven.', 's', [('uchiha_yakali', '1e2a48', 'e8842a'), ('ninja_pant', '1e2a48', None), ('eldiven', '1e2a48', None), (S, '1c1c20', 'eeeeea')]),
 (120, 'on_kuyruk', 'Jūbi Koromo', 'Göğüste altı tomoe, beyaz beden giysisi, siyah alt.', 'c', [('beyaz_arma', 'd8e4dc', '1c1c20'), ('siyah_pant', '1c1c20', None), ('kesis_cubbesi', 'd8e4dc', '1c1c20'), ('tabi', 'd8e4dc', 'd8e4dc')]),
 (121, 'tas_yaşli', 'Iwa Rōjin', 'Siyah Iwa takımı, soluk yeşil yelek, kızıl pelerin.', 'd', [('uzun_gomlek', '1c1c20', '1c1c20'), ('iwa_pant', '1c1c20', None), ('iwa_yelek', '8a9a7a', None), ('kisa_pelerin', 'a82228', None), (S, '1c1c20', '6a6a70')]),
 (122, 'yilan_sanin', 'Hebi Sannin', 'Siyah balıkçı yaka üstüne kısa kollu krem üst, kalın mor ip kuşak.', 'c', [('kimono_ust', 'e8dcb8', '6a3a9a'), ('ninja_pant', '3a4a6a', None), (S, '1c1c20', 'eeeeea')]),
 (123, 'kaya_striker', 'Iwa Striker', 'Koyu kahve şal, açık sol kollu kızıl gi, kahve kemer.', 'd', [('gi_beyaz', 'a82228', '6a4a2a'), ('ninja_pant', 'a82228', None), ('kisa_pelerin', '5a3a28', None), (S, '1c1c20', 'eeeeea')]),
 (124, 'lav_zirh', 'Yōgan Yoroi', 'Mor kimono takımı, kahve zırh, lacivert kolluk.', 'd', [('kimono_ust', 'a82a8a', 'a82a8a'), ('bol_pantolon', 'a82a8a', None), ('deri_pul_zirh', '6a4a2a', None), ('kolluk', '2a2a5a', None), ('ayak_009', '2a2a5a', '2a2a5a')]),
 (125, 'murekkep_ceket', 'Sumi Uwagi', 'Omuzları kırmızı biyeli lacivert-mor ceket, gri iç.', 'c', [('panel_ceket', '2a2a4a', 'c02a2a'), ('ninja_pant', '2a2a4a', None), ('eldiven', '1c1c20', None), (S, '1c1c20', 'eeeeea')]),
 (126, 'pembe_kunoichi', 'Sakura Kunoichi', 'Kolsuz kırmızı fermuarlı üst, pembe etek, siyah eldiven.', 'h', [('kolsuz_yakali', 'b0242a', 'f2f0ea'), ('etek_mini', 'e8b0c0', None), ('eldiven', '1c1c20', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (127, 'pembe_genc', 'Sakura Kodomo', 'Daire desenli kısa kollu kırmızı-beyaz elbise.', 'h', [('yakali', 'c02a2a', 'f2f0ea'), ('etek_diz', 'c02a2a', None), (S, '2a3a8a', 'eeeeea')]),
 (128, 'pembe_kunoichi2', 'Sakura Kunoichi Ni', 'Beyaz biyeli kısa kızıl elbise, siyah tayt.', 'h', [('kolsuz_yakali', '8a1a22', 'f2f0ea'), ('etek_mini', '8a1a22', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (129, 'son_savas', 'Saigo no Tatakai', 'Yeleksiz Konoha takımı, sağ kolu yırtık.', 'h', [('yamali_gomlek', '1e2a48', '1e2a48'), ('ninja_pant', '1e2a48', None), (S, '1e2a48', 'eeeeea')]),
 (130, 'kizil_fermuar', 'Uchiha Kunoichi', 'Açık kırmızı fermuarlı üst, lacivert kolluk ve çorap.', 's', [('kolsuz_yakali', 'd84a4a', 'd84a4a'), ('kisa_sort', '1c1c20', None), ('uchiha_kolluk', '1e2a48', None), ('ayak_009', '1e2a48', '1e2a48')]),
 (131, 'kizil_elbise', 'Uchiha Doresu', 'Beyaz gömlek üstüne kızıl elbise, mor eldiven, sarı atkı.', 's', [('yakali', 'f2f0ea', 'f2f0ea'), ('etek_mini', 'a8222a', None), ('eldiven', '6a3a8a', None), ('atki', 'f0c84a', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (132, 'kukla_genc', 'Kugutsu Wakate', 'Kahve kemerli dik yakalı koyu mor ceket, parmaksız eldiven.', 'c', [('ceket', '3a2a4a', '3a2a4a'), ('ninja_pant', '4a4a50', None), ('eldiven', '1c1c20', None), (S, '1c1c20', 'eeeeea')]),
 (133, 'yelpaze', 'Uchiha Ryokō', 'Mavimsi gri dik yakalı gömlek, mor ip kuşak, lacivert peştamal.', 'm', [('uchiha_yakali', '8a8aa8', '8a8aa8'), ('ninja_pant', '1e2a48', None), ('anbu_atki', '1e2a48', None), (S, '1c1c20', 'eeeeea')]),
 (134, 'mikoshi', 'Mikoshi Shōzoku', 'Göğüs ipli siyah gömlek, gri sarashi, kırmızı-siyah hakama.', 'm', [('golge_ust', '1c1c20', '1c1c20'), ('hakama', 'a8222a', None), ('kol_sargisi', '8a8a90', None), (S, '1c1c20', 'eeeeea')]),
 (135, 'yelpaze_kolsuz', 'Uchiha Sodenashi', 'Kolsuz gri kimono üst, mor ip kuşak, lacivert peştamal.', 'm', [('kolsuz_yakali', '6a6a70', '6a6a70'), ('ninja_pant', '1e2a48', None), ('anbu_atki', '1e2a48', None), (S, '1c1c20', 'eeeeea')]),
 (136, 'yelpaze_genc2', 'Uchiha Kodomo Ni', 'Gri astarlı siyah gömlek, gri dirseklik, sol bacakta sargı.', 's', [('tisort', '1c1c20', '6a6a70'), ('ninja_pant', '1c1c20', None), ('dizlik', '6a6a70', None), (S, '1c1c20', 'eeeeea')]),
 (137, 'yelpaze_takim', 'Uchiha Seifuku', 'Gri takım üstüne açık mavi palto, lacivert eldiven.', 'c', [('yakali', '7a7a80', '7a7a80'), ('siyah_pant', '1c1c20', None), ('uzun_palto', '9ab8d8', None), ('eldiven', '1e2a48', None), (S, '1e2a48', 'eeeeea')]),
 (138, 'sokak', 'Machi Shōzoku', 'Siyah tişört üstüne lacivert düğmeli gömlek, bol yeşil pantolon.', 's', [('yakali', '1e2a48', '1c1c20'), ('bol_pantolon', '4a5a3a', None), (S, '1c1c20', 'eeeeea')]),
 (139, 'yelpaze_b', 'Uchiha Ryokō B', 'Hafif açık dik yakalı mavimsi gri gömlek, lacivert eşofman altı.', 'm', [('uchiha_yakali', '8a8aa8', '8a8aa8'), ('bol_pantolon', '1e2a48', None), (S, '1c1c20', 'eeeeea')]),
 (140, 'gezgin_palto', 'Rurō Gaitō', 'Siyah palto ve pantolon, göğüste mor kılıç kayışı.', 'm', [('golge_ust', '1c1c20', '1c1c20'), ('siyah_pant', '1c1c20', None), ('seyahat_pelerini', '1c1c22', None), ('kayis_kosum', '4a2a5a', None), ('eldiven', '1c1c20', None), (S, '1c1c20', 'eeeeea')]),
 (141, 'yelpaze_cocuk', 'Uchiha Osanai', 'Mor tulum, kolluk, gri yelek, beyaz kuşak.', 's', [('golge_ust', '3a2a5a', '3a2a5a'), ('ninja_pant', '3a2a5a', None), ('chunin_yelek', '7a7a80', None), ('uchiha_kolluk', '3a2a5a', None), (S, '1c1c20', 'eeeeea')]),
 (142, 'yelpaze_yirtik', 'Uchiha Saigo', 'Yırtık mavimsi gri gömlek, lacivert alt.', 'm', [('yamali_gomlek', '8a8aa8', '8a8aa8'), ('yamali_pant', '1e2a48', None), (S, '1c1c20', 'eeeeea')]),
 (143, 'yelpaze_genc', 'Uchiha Kodomo', 'Dik yakalı lacivert gömlek, beyaz kolluk, beyaz şort.', 's', [('uchiha_yakali', '1e2a6a', '1e2a6a'), ('kisa_sort', 'e8e4da', None), ('uchiha_kolluk', 'f2f0ea', None), (S, '1c1c20', 'eeeeea')]),
 (144, 'mevsim', 'Kisetsu Shōzoku', 'Çiçek desenli kareli yeşil palto, açık yeşil takım.', 'h', [('ust_036', '7ac0a0', 'e8a0b8'), ('bol_pantolon', 'f2e4ea', None), ('ayak_004', '2e6a4a', '2e6a4a')]),
 (145, 'golge_genc', 'Kage Wakate', 'Soluk sarı fermuarlı ceket, siyah kol bandı.', 's', [('ceket', 'e8e0a8', 'e8e0a8'), ('ninja_pant', '1e2a48', None), (S, '1c1c20', 'eeeeea')]),
 (146, 'golge_jonin', 'Kage Jōnin', 'Lacivert tulum üstüne açık sarı ceket.', 'c', [('uzun_gomlek', '1e2a48', '1e2a48'), ('ninja_pant', '1e2a48', None), ('haori', 'd8c890', None), (S, '1c1c20', 'eeeeea')]),
 (147, 'demir_kum', 'Satetsu Gaitō', 'Kabarık yakalı uzun siyah şal, açık kahve yelek.', 'd', [('golge_ust', '2a2a30', '2a2a30'), ('siyah_pant', '1c1c20', None), ('suna_yelek', 'a8885a', None), ('gece_pelerini', '1c1c22', None), (S, '1c1c20', 'eeeeea')]),
 (148, 'yelpaze_kilic', 'Uchiha Kenshi', 'Dik yakalı siyah tişört, kahve kılıç kayışı, lacivert pantolon.', 'm', [('uchiha_yakali', '1c1c20', '1c1c20'), ('ninja_pant', '1e2a48', None), ('kayis_kosum', '6a4a2a', None), (S, '1c1c20', 'eeeeea')]),
 (149, 'yelpaze_zirh', 'Uchiha Gusoku', 'Yelpaze desenli soluk mor uzun giysi, kızıl zırh.', 'd', [('golge_ust', '2a1e3a', '2a1e3a'), ('hakama', '2a2a3a', None), ('lake_zirh', '9a1e22', None), ('ayak_012', '2a2a30', '9a1e22')]),
 (150, 'okul_mor', 'Murasaki Gakusei', 'Siyah uzun kollu üstüne mor kıyafet, koyu mor kemer.', 'c', [('yakali', 'b8a0e0', '3a2a6a'), ('etek_diz', 'b8a0e0', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (151, 'mor_genin', 'Murasaki Genin', 'Lavanta-beyaz kolsuz üst, bol koyu mor şort, uzun çorap.', 's', [('kolsuz_yakali', 'c8b8e8', 'f2f0ea'), ('kisa_sort', '3a2a5a', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (152, 'gosterisli', 'Hade Striker', 'Siyah palto, dar pantolon, kayışlı yüksek bot.', 's', [('golge_ust', '1c1c20', '1c1c20'), ('siyah_pant', '1c1c20', None), ('uzun_palto', '1c1c22', None), ('eldiven', '1e2a48', None), ('ayak_011', '1e2a48', '1e2a48')]),
 (153, 'tatli', 'Amai Striker', 'Lavanta atlet üstüne krem straplez üst, mavi pantolon.', 's', [('kolsuz_yakali', 'e8dcc8', 'b8a8d8'), ('sivil_pant', '2a4a9a', None), (S, '1e2a48', 'eeeeea')]),
 (154, 'kuyruklu_beyaz', 'Bijū Byakue', 'Siyah desenli bol beyaz giysi, mavi göğüslük.', 'h', [('gi_beyaz', 'f2f0ea', '1c1c20'), ('bol_pantolon', 'f2f0ea', None), ('gogus_plakasi', '2a4a9a', None), ('ayak_009', '1e2a48', '1e2a48')]),
 (155, 'flut', 'Fue Shōzoku', 'Siyah tulum üstüne yin-yang desenli soluk pembe giysi, ip kuşak.', 'c', [('kimono_ust', 'e8d4d8', '6a4a7a'), ('ninja_pant', '1c1c20', None), ('etek_diz', 'e8d4d8', None), (S, '1c1c20', 'eeeeea')]),
 (156, 'ruzgar_kimono', 'Kaze Kimono', 'Kısa lacivert kimono, koyu mavi obi, pembe ip.', 'c', [('kimono_ust', '2a3a9a', '1e2a5a'), ('etek_diz', '2a3a9a', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (157, 'ruzgar_elbise', 'Kaze Doresu', 'Koyu mor elbise, soluk mor göğüslük, erik moru kemer.', 'c', [('kolsuz_yakali', '3a2a4a', '3a2a4a'), ('etek_mini', '3a2a4a', None), ('gogus_plakasi', 'b8a8c8', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (158, 'ruzgar_elbise2', 'Kaze Nagasode', 'Uzun kollu lavanta elbise, file çorap.', 'c', [('uzun_gomlek', 'b8a8d8', 'b8a8d8'), ('etek_diz', '2a3a6a', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (159, 'ruzgar_zirh', 'Kaze Yoroi', 'Gri uzun kollu üst, açık renk zırh, kırmızı kuşak, mor etek.', 'd', [('uzun_gomlek', '8a8a90', '8a8a90'), ('etek_uzun', '4a3a6a', None), ('suna_yelek', 'c8c0d0', None), ('eldiven', '1e2a48', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (160, 'ruzgar_genc', 'Kaze Kodomo', 'File üstüne uzun kollu soluk pembe elbise.', 'c', [('uzun_gomlek', 'e8d4dc', 'e8d4dc'), ('etek_diz', 'e8d4dc', None), (S, '1c1c20', 'eeeeea')]),
 (161, 'silah_ustasi', 'Buki Shōzoku', 'Kırmızı biyeli beyaz Çin tarzı üst, şeftali pembesi bol pantolon.', 'm', [('yakali', 'f2f0ea', 'c02a2a'), ('bol_pantolon', 'e89a9a', None), ('ayak_018', 'c02a2a', 'e8d6a8')]),
 (162, 'turuncu_maske', 'Uzumaki Kamen', 'Siyah koyu takım, mor atkı.', 's', [('golge_ust', '1e1e30', '1e1e30'), ('ninja_pant', '1e1e30', None), ('atki', '2a5a5a', None), (S, '1c1c20', 'eeeeea')]),
 (163, 'su_zirh', 'Mizu Yoroi', 'Kısa kesim lacivert tulum, mavi zırh, kürk yakalık.', 'd', [('golge_ust', '1e2a48', '1e2a48'), ('ninja_pant', '1e2a48', None), ('sengoku_lacivert', '2a4ab8', None), ('kolluk', 'b8a8d8', None), (S, '1c1c20', 'eeeeea')]),
 (164, 'ay_cubbe', 'Tsuki Koromo', 'Kırık beyaz kimono, haki önlük, beyaz pelerin.', 'c', [('kimono_ust', 'f2f0ea', 'c8c4a0'), ('sivil_pant', 'f2f0ea', None), ('kesis_cubbesi', 'd8d0a8', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (165, 'antrenman', 'Keiko-gi', 'Mavi hakamaya sokulmuş beyaz kimono üst, sarı koşum, beyaz tabi.', 'm', [('gi_beyaz', 'f2f0ea', 'f0c84a'), ('hakama', '2a4ab8', None), ('ayak_018', '2a4ab8', 'f0c84a')]),
 (166, 'naginata', 'Naginata Hakama', 'Kırmızı biyeli beyaz kimono üst, bağlı kırmızı hakama, siyah eldiven.', 'm', [('kimono_ust', 'f2f0ea', 'c02a2a'), ('kizil_hakama', 'b0244a', None), ('eldiven', '1c1c20', None), ('ayak_003', '6a4a2a', '6a4a2a')]),
 (167, 'kumarbaz', 'Kake Haori', 'Yeşil-siyah ceket, gri kimono üst, lacivert pantolon.', 'h', [('kimono_ust', 'b8b8bc', '1c1c20'), ('ninja_pant', '1e2a48', None), ('haori', '2e6a3a', None), ('ayak_004', '1c1c20', '1c1c20')]),
 (168, 'kopuk', 'Awa Kimono', 'Göğsü açık, koyu mavi biyeli bol açık mavi kimono.', 'c', [('biyeli_kimono', '7ab8e8', '1e3a9a'), ('etek_uzun', '7ab8e8', None), ('zori', '6b4a2b', 'e8d6a8')]),
 (169, 'kedi', 'Neko Fūdo', 'Kürk kenarlı yeşil kolsuz kapüşonlu, koyu yeşil şort.', 's', [('kolsuz_yakali', '8ab84a', '8ab84a'), ('kisa_sort', '4a5a2a', None), ('eldiven', '8a8a90', None), ('ayak_004', '6a4a2a', '6a4a2a')]),
 (170, 'harika', 'Kōkishin Striker', 'Mavi tişört üstüne gri hırka, siyah pantolon.', 's', [('tisort', '2a8ac0', '2a8ac0'), ('siyah_pant', '1c1c20', None), ('haori', 'b8b8bc', None), (S, '1c1c20', 'eeeeea')]),
 (171, 'kaplumbaga', 'Kame Shōzoku', 'Gri gömlek ve bol pantolon, yosun yeşili atkı ve kuşak.', 'c', [('tisort', '8a8a90', '8a8a90'), ('bol_pantolon', '8a8a90', None), ('kesa', '5a6a3a', None), ('ayak_009', '1c1c20', '1c1c20')]),
 (172, 'genclik', 'Seishun Striker', 'Siyah kapüşonlu üst, kırmızı-siyah botlara sokulmuş beyaz pantolon.', 's', [('ceket', '1c1c22', '1c1c22'), ('sivil_pant', 'f2f0ea', None), ('ayak_015', '1c1c20', 'c02a2a')]),
 (173, 'kedi_alev', 'Neko Yoroi', 'Siyah bol gömlek, gri göğüs zırhı, kırmızı kuşak, beyaz sargılar.', 'm', [('golge_ust', '2a2a30', '2a2a30'), ('ninja_pant', '4a3a6a', None), ('gogus_plakasi', '9a9aa0', None), ('kol_sargisi', 'f2f0ea', None), (S, '1c1c20', 'eeeeea')]),
 (174, 'iblis', 'Kiri no Oni', 'Arkaya düğmeli kuşaklı siyah tulum, kollarda inek desenli koruma.', 'm', [('golge_ust', '1c1c20', '1c1c20'), ('ninja_pant', '1c1c20', None), ('kiri_koruma', 'b8b8bc', None), (S, '1c1c20', 'eeeeea')]),
]

DONE = set()   # ref'e göre modellemesi bitip doğrulanan set kimlikleri

FLAV = {'s': {'speed': 0.04}, 'm': {'melee': 0.05}, 'c': {'chakra': 20}, 'h': {'hp': 20}, 'd': {'def': 4}}
BASE = [{'def': 5, 'hp': 10}, {'def': 8, 'hp': 15}, {'def': 12, 'hp': 25}, {'def': 15, 'hp': 30, 'chakra': 15}]
PRICE = [250, 500, 900, 1500]

def col(h):
    if h is None:
        return 'null'
    r, g, b = int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255
    return 'Color(%.3f, %.3f, %.3f)' % (r, g, b)

def gd_val(v):
    if isinstance(v, float): return repr(round(v, 3))
    return str(v)

out = ['extends RefCounted', '## OTOMATİK ÜRETİLDİ: tools/gen_striker_sets.py (refs/outfits_ss Shinobi Striker kostüm referansları).',
       '## Mevcut kıyafet parçalarından setler; "sex": "f"/"m" yalnız o cinsiyete satılır/seçilir, boş = herkes.', '', 'const SETS := {']
start, shop = [], []
seen = set()
for (i, sid, name, desc, fl, parts) in D:
    sex, rk, page = lst[i]
    r = rank_of(rk)
    sid = 'ss_' + re.sub(r'[^a-z0-9_]', '', sid.replace('ş', 's'))
    assert sid not in seen, sid
    seen.add(sid)
    st = dict(BASE[r])
    for k, v in FLAV[fl].items():
        st[k] = st.get(k, 0) + v
    stats = '{' + ', '.join('"%s": %s' % (k, gd_val(v)) for k, v in st.items()) + '}'
    ps = ', '.join('["%s", %s, %s]' % (p, col(a), col(b)) for (p, a, b) in parts)
    sx = {'F': 'f', 'M': 'm'}.get(sex, '')
    out.append('\t"%s": {"name": "%s", "slot": "set", "price": %d, "rank": %d, "sex": "%s", "desc": "%s", "stats": %s, "c1": %s, "c2": %s, "parts": [%s]},'
               % (sid, name, PRICE[r], min(r, 2), sx, desc, stats, col(parts[0][1]), col(parts[0][2] or parts[0][1]), ps))
    if sid in DONE:   # yalnız gerçekten modellenmiş (ref'e göre yeni 3B parçalı) setler satılır/seçilir
        shop.append(sid)
        if r == 0:
            start.append(sid)
out.append('}')
out.append('')
out.append('## Başlangıçta seçilebilen temel (C sırası) setler')
out.append('const START := [%s]' % ', '.join('"%s"' % s for s in start))
out.append('const SHOP := [%s]' % ', '.join('"%s"' % s for s in shop))
open(os.path.join(ROOT, 'godot/scripts/core/striker_sets.gd'), 'w', encoding='utf-8', newline='\n').write('\n'.join(out) + '\n')
print(len(shop), 'set', len(start), 'başlangıç')
