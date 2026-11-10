class_name Gear
extends RefCounted
const WH = preload("res://scripts/core/weapon_holders.gd")
const STRIKER = preload("res://scripts/core/striker_sets.gd")   # Shinobi Striker kostüm setleri (tools/gen_striker_sets.py)
## Ekipman: kafa, yüz, üst/alt kıyafet, ayak, yelek, dış giysi, kol, sırt, sağ el / sol el silahı.
## profile["gear"] = sahip olunan parçalar [{uid, id, c1, c2}], profile["equip"] = {yuva: uid}

const SLOTS := [["kafa", "Kafa"], ["sag_goz", "Sağ Göz"], ["sol_goz", "Sol Göz"], ["set", "Kıyafet Seti"], ["sirt", "Sırt"], ["sag", "Silah"]]   # yüz eşyaları (maske, gözlük) Kafa yuvasında
## Eski tek tek kıyafet yuvaları (artık kıyafetler set olarak giyilir; bu yuvalardaki parçalar iç içe geçiyordu)
const OLD_CLOTH_SLOTS := ["govde", "bacak", "ayak", "zirh", "dis", "kol", "sol"]

## Kıyafet setleri: parçaları (eski kıyafet eşyaları) birlikte, uyumlu renklerle giyilir — iç içe geçmez.
## "parts": [eşya, c1, c2]. Kullanıcı yeni kıyafet örnekleri gönderecek; şimdilik birkaç temel set.
const SETS := {
	"set_genin": {"name": "Genin Kunrengi", "slot": "set", "price": 150, "rank": 0, "desc": "Turuncu-siyah eğitim ceketi, lacivert ninja pantolonu, sandalet.",
		"stats": {"def": 5, "hp": 10, "speed": 0.03}, "c1": Color(0.95, 0.5, 0.12), "c2": Color(0.12, 0.12, 0.14),
		"parts": [["ceket", Color(0.95, 0.5, 0.12), Color(0.12, 0.12, 0.14)], ["ninja_pant", Color(0.15, 0.2, 0.33), null], ["sandalet", Color(0.15, 0.2, 0.33), Color(0.92, 0.92, 0.9)]]},
	"set_shinobi": {"name": "Shinobi Shōzoku", "slot": "set", "price": 200, "rank": 0, "desc": "Lacivert uzun kollu gömlek, ninja pantolonu, kol sargısı, sandalet.",
		"stats": {"def": 6, "melee": 0.03, "speed": 0.03}, "c1": Color(0.15, 0.2, 0.33), "c2": Color(0.12, 0.12, 0.14),
		"parts": [["uzun_gomlek", Color(0.15, 0.2, 0.33), Color(0.12, 0.12, 0.14)], ["ninja_pant", Color(0.13, 0.16, 0.26), null], ["kol_sargisi", Color(0.92, 0.92, 0.9), null], ["sandalet", Color(0.12, 0.12, 0.14), Color(0.92, 0.92, 0.9)]]},
	"set_uchiha": {"name": "Uchiha Shōzoku", "slot": "set", "price": 300, "rank": 0, "clan": "uchiha", "desc": "Sırtı yelpaze armalı dik yakalı lacivert üst, kolluk, koyu pantolon.",
		"stats": {"def": 6, "chakra": 15, "melee": 0.04}, "c1": Color(0.13, 0.15, 0.26), "c2": Color(0.13, 0.15, 0.26),
		"parts": [["uchiha_yakali", Color(0.13, 0.15, 0.26), Color(0.13, 0.15, 0.26)], ["uchiha_kolluk", Color(0.12, 0.12, 0.14), null], ["ninja_pant", Color(0.88, 0.86, 0.8), null], ["sandalet", Color(0.12, 0.12, 0.14), Color(0.92, 0.92, 0.9)]]},
	"set_suna": {"name": "Suna Tabi Shōzoku", "slot": "set", "price": 350, "rank": 1, "desc": "Kum rengi yüksek yakalı gömlek, bol çöl şalvarı, kısa pelerin.",
		"stats": {"def": 6, "hp": 20, "speed": 0.02}, "c1": Color(0.8, 0.7, 0.5), "c2": Color(0.55, 0.3, 0.2),
		"parts": [["yakali", Color(0.62, 0.5, 0.36), Color(0.4, 0.3, 0.22)], ["col_salvari", Color(0.8, 0.7, 0.5), null], ["kisa_pelerin", Color(0.55, 0.3, 0.2), null], ["sandalet", Color(0.3, 0.22, 0.16), Color(0.85, 0.8, 0.7)]]},
	"set_anbu": {"name": "ANBU Shōzoku", "slot": "set", "price": 0, "rank": 4, "desc": "Koyu gömlek ve pantolon, metal göğüs plakası, kol koruması.",
		"stats": {"def": 18, "speed": 0.05, "melee": 0.05}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.85, 0.85, 0.82),
		"parts": [["uzun_gomlek", Color(0.12, 0.12, 0.14), Color(0.12, 0.12, 0.14)], ["ninja_pant", Color(0.12, 0.12, 0.14), null], ["anbu_zirh", Color(0.85, 0.85, 0.82), null], ["kol_sargisi", Color(0.9, 0.9, 0.88), null], ["sandalet", Color(0.12, 0.12, 0.14), Color(0.92, 0.92, 0.9)]]},
	# --- köy chūnin / jōnin setleri (kaynak: set1.png Konoha, sunaset.png Suna, mistset.png Kiri)
	"set_chunin": {"name": "Konoha Chūnin Shōzoku", "slot": "set", "price": 600, "rank": 2, "village": "konoha", "desc": "Lacivert yüksek yakalı gömlek ve pantolon, omuzluklu yeşil taktik yelek, baldır sargıları.",
		"stats": {"def": 14, "hp": 25, "speed": 0.03}, "c1": Color(0.12, 0.15, 0.3), "c2": Color(0.12, 0.15, 0.3),
		"parts": [["uzun_gomlek", Color(0.12, 0.15, 0.3), Color(0.12, 0.15, 0.3)], ["ninja_pant", Color(0.12, 0.15, 0.3), null], ["chunin_yelek", Color(0.46, 0.56, 0.44), null], ["sandalet", Color(0.12, 0.15, 0.3), Color(0.92, 0.92, 0.9)]]},
	"set_jonin": {"name": "Konoha Jōnin Shōzoku", "slot": "set", "price": 0, "rank": 3, "village": "konoha", "desc": "Chūnin takımının üstüne parmaksız eldiven; yelek daha koyu yeşil. Katon jutsuları %10 güçlü, Katon'dan alınan hasar %10 az.",
		"boost": {"katon": 0.10}, "resist": {"katon": 0.10}, "stats": {"def": 17, "hp": 30, "chakra": 25, "melee": 0.04}, "c1": Color(0.12, 0.15, 0.3), "c2": Color(0.12, 0.15, 0.3),
		"parts": [["uzun_gomlek", Color(0.12, 0.15, 0.3), Color(0.12, 0.15, 0.3)], ["ninja_pant", Color(0.12, 0.15, 0.3), null], ["chunin_yelek", Color(0.38, 0.48, 0.36), null], ["eldiven", Color(0.1, 0.12, 0.22), null], ["sandalet", Color(0.12, 0.15, 0.3), Color(0.92, 0.92, 0.9)]]},
	"set_suna_chunin": {"name": "Suna Chūnin Shōzoku", "slot": "set", "price": 600, "rank": 2, "village": "suna", "desc": "Koyu gömlek ve pantolon, geniş omuzluklu kahverengi taktik yelek.",
		"stats": {"def": 13, "hp": 30, "speed": 0.03}, "c1": Color(0.1, 0.1, 0.16), "c2": Color(0.1, 0.1, 0.16),
		"parts": [["uzun_gomlek", Color(0.1, 0.1, 0.16), Color(0.1, 0.1, 0.16)], ["ninja_pant", Color(0.1, 0.1, 0.15), null], ["suna_yelek", Color(0.46, 0.37, 0.28), null], ["sandalet", Color(0.08, 0.08, 0.1), Color(0.92, 0.92, 0.9)]]},
	"set_suna_jonin": {"name": "Suna Jōnin Shōzoku", "slot": "set", "price": 0, "rank": 3, "village": "suna", "desc": "Suna takımı; daha koyu yelek ve parmaksız eldiven. Fūton ve Doton jutsuları %5 güçlü, bunlardan alınan hasar %5 az.",
		"boost": {"fuuton": 0.05, "doton": 0.05}, "resist": {"fuuton": 0.05, "doton": 0.05}, "stats": {"def": 16, "hp": 35, "chakra": 25, "melee": 0.04}, "c1": Color(0.1, 0.1, 0.16), "c2": Color(0.1, 0.1, 0.16),
		"parts": [["uzun_gomlek", Color(0.1, 0.1, 0.16), Color(0.1, 0.1, 0.16)], ["ninja_pant", Color(0.1, 0.1, 0.15), null], ["suna_yelek", Color(0.38, 0.3, 0.22), null], ["eldiven", Color(0.08, 0.08, 0.1), null], ["sandalet", Color(0.08, 0.08, 0.1), Color(0.92, 0.92, 0.9)]]},
	"set_kiri_chunin": {"name": "Kiri Chūnin Shōzoku", "slot": "set", "price": 600, "rank": 2, "village": "kiri", "desc": "Siyah gömlek ve pantolon, önlüklü plakalı lila yelek, açık mavi çizgili kol ve kaval koruyucuları.",
		"stats": {"def": 14, "chakra": 25}, "c1": Color(0.08, 0.08, 0.1), "c2": Color(0.08, 0.08, 0.1),
		"parts": [["uzun_gomlek", Color(0.08, 0.08, 0.1), Color(0.08, 0.08, 0.1)], ["ninja_pant", Color(0.08, 0.08, 0.1), null], ["kiri_yelek", Color(0.56, 0.53, 0.66), null], ["kiri_koruma", Color(0.6, 0.72, 0.9), null], ["sandalet", Color(0.08, 0.08, 0.1), Color(0.92, 0.92, 0.9)]]},
	"set_kiri_jonin": {"name": "Kiri Jōnin Shōzoku", "slot": "set", "price": 0, "rank": 3, "village": "kiri", "desc": "Kiri takımı; daha koyu yelek. Suiton jutsuları %10 güçlü, Suiton'dan alınan hasar %10 az.",
		"boost": {"suiton": 0.10}, "resist": {"suiton": 0.10}, "stats": {"def": 17, "chakra": 35, "hp": 20}, "c1": Color(0.08, 0.08, 0.1), "c2": Color(0.08, 0.08, 0.1),
		"parts": [["uzun_gomlek", Color(0.08, 0.08, 0.1), Color(0.08, 0.08, 0.1)], ["ninja_pant", Color(0.08, 0.08, 0.1), null], ["kiri_yelek", Color(0.46, 0.43, 0.56), null], ["kiri_koruma", Color(0.52, 0.64, 0.84), null], ["sandalet", Color(0.08, 0.08, 0.1), Color(0.92, 0.92, 0.9)]]},
	"set_kumo_chunin": {"name": "Kumo Chūnin Shōzoku", "slot": "set", "price": 600, "rank": 2, "village": "kumo", "desc": "Lacivert gömlek ve pantolon, tek omuz askılı beyaz yelek, beyaz kaval koruyucuları.",
		"stats": {"def": 13, "melee": 0.06, "speed": 0.03}, "c1": Color(0.1, 0.12, 0.25), "c2": Color(0.1, 0.12, 0.25),
		"parts": [["uzun_gomlek", Color(0.1, 0.12, 0.25), Color(0.1, 0.12, 0.25)], ["ninja_pant", Color(0.1, 0.12, 0.25), null], ["kumo_yelek", Color(0.88, 0.88, 0.86), null], ["kumo_kaval", Color(0.86, 0.84, 0.82), null], ["sandalet", Color(0.08, 0.08, 0.1), Color(0.92, 0.92, 0.9)]]},
	"set_kumo_jonin": {"name": "Kumo Jōnin Shōzoku", "slot": "set", "price": 0, "rank": 3, "village": "kumo", "desc": "Kumo chūnin takımının aynısı (eldiven koruyucuların rengini karartıyordu). Fūton ve Raiton jutsuları %5 güçlü, bunlardan alınan hasar %5 az.",
		"boost": {"fuuton": 0.05, "raiton": 0.05}, "resist": {"fuuton": 0.05, "raiton": 0.05}, "stats": {"def": 16, "melee": 0.08, "hp": 25}, "c1": Color(0.1, 0.12, 0.25), "c2": Color(0.1, 0.12, 0.25),
		"parts": [["uzun_gomlek", Color(0.1, 0.12, 0.25), Color(0.1, 0.12, 0.25)], ["ninja_pant", Color(0.1, 0.12, 0.25), null], ["kumo_yelek", Color(0.88, 0.88, 0.86), null], ["kumo_kaval", Color(0.86, 0.84, 0.82), null], ["sandalet", Color(0.08, 0.08, 0.1), Color(0.92, 0.92, 0.9)]]},
	"set_iwa_chunin": {"name": "Iwa Chūnin Shōzoku", "slot": "set", "price": 600, "rank": 2, "village": "iwa", "desc": "Tek kollu kırmızı üst ve pantolon, karın plakalı kahverengi yelek, file baldır.",
		"stats": {"def": 15, "hp": 30, "speed": -0.01}, "c1": Color(0.72, 0.16, 0.2), "c2": Color(0.72, 0.16, 0.2),
		"parts": [["tek_kol_ust", Color(0.72, 0.16, 0.2), Color(0.72, 0.16, 0.2)], ["iwa_pant", Color(0.72, 0.16, 0.2), null], ["iwa_yelek", Color(0.36, 0.27, 0.19), null], ["sandalet", Color(0.08, 0.08, 0.1), Color(0.3, 0.3, 0.33)]]},
	"set_iwa_jonin": {"name": "Iwa Jōnin Shōzoku", "slot": "set", "price": 0, "rank": 3, "village": "iwa", "desc": "Iwa takımı; daha koyu yelek, parmaksız eldiven. Doton jutsuları %10 güçlü, Doton'dan alınan hasar %10 az.",
		"boost": {"doton": 0.10}, "resist": {"doton": 0.10}, "stats": {"def": 18, "hp": 35, "chakra": 20}, "c1": Color(0.66, 0.14, 0.18), "c2": Color(0.66, 0.14, 0.18),
		"parts": [["tek_kol_ust", Color(0.66, 0.14, 0.18), Color(0.66, 0.14, 0.18)], ["iwa_pant", Color(0.66, 0.14, 0.18), null], ["iwa_yelek", Color(0.3, 0.22, 0.15), null], ["eldiven", Color(0.08, 0.08, 0.1), null], ["sandalet", Color(0.08, 0.08, 0.1), Color(0.3, 0.3, 0.33)]]},
	"set_akatsuki": {"name": "Akatsuki Shōzoku", "slot": "set", "price": 0, "rank": 3, "desc": "Kızıl bulutlu dik yakalı siyah pelerin, koyu pantolon.",
		"stats": {"def": 12, "chakra": 30}, "c1": Color(0.08, 0.08, 0.1), "c2": Color(0.8, 0.1, 0.12),
		"parts": [["uzun_gomlek", Color(0.12, 0.12, 0.14), Color(0.12, 0.12, 0.14)], ["ninja_pant", Color(0.12, 0.12, 0.14), null], ["akatsuki_pelerini", Color(0.13, 0.14, 0.26), Color(0.72, 0.07, 0.14)], ["sandalet", Color(0.4, 0.3, 0.45), Color(0.92, 0.92, 0.9)]]},
	"set_tabibito": {"name": "Tabibito Shōzoku", "slot": "set", "price": 250, "rank": 0, "desc": "Biyeli tunik, sargılı pantolon, seyahat pelerini, sargılı gezgin botu. Uzun yolların ninjası.",
		"stats": {"def": 6, "hp": 15, "speed": 0.04}, "c1": Color(0.55, 0.42, 0.3), "c2": Color(0.3, 0.22, 0.16),
		"parts": [["tunik", Color(0.55, 0.42, 0.3), Color(0.3, 0.22, 0.16)], ["sargili_pant", Color(0.35, 0.3, 0.24), null], ["seyahat_pelerini", Color(0.42, 0.36, 0.28), null], ["ayak_014", Color(0.3, 0.24, 0.18), Color(0.8, 0.75, 0.65)]]},
	"set_iryonin": {"name": "Iryō-nin Shōzoku", "slot": "set", "price": 300, "rank": 1, "desc": "Yüksek yakalı açık gömlek, ninja pantolonu, kol sargıları: sahada yaralı taşıyan tıbbi ninjanın sade takımı. Tıbbi tekniklerin chakrası daha az.",
		"stats": {"def": 6, "chakra": 30, "hp": 10}, "c1": Color(0.86, 0.84, 0.78), "c2": Color(0.65, 0.2, 0.2),
		"parts": [["yakali", Color(0.86, 0.84, 0.78), Color(0.65, 0.2, 0.2)], ["ninja_pant", Color(0.2, 0.22, 0.28), null], ["kol_sargisi", Color(0.95, 0.95, 0.92), null], ["sandalet", Color(0.2, 0.22, 0.28), Color(0.92, 0.92, 0.9)]]},
	"set_kenpo": {"name": "Kenpō Dōgi", "slot": "set", "price": 280, "rank": 0, "desc": "Beyaz dövüş gi'si, bol paçalı pantolon, sargılı eldiven, tabi. Taijutsu ustalarının antrenman giysisi.",
		"stats": {"def": 5, "melee": 0.07, "speed": 0.03}, "c1": Color(0.94, 0.93, 0.9), "c2": Color(0.2, 0.2, 0.22),
		"parts": [["gi_beyaz", Color(0.94, 0.93, 0.9), Color(0.2, 0.2, 0.22)], ["bol_pantolon", Color(0.92, 0.9, 0.86), null], ["uzun_sargi_eldiven", Color(0.9, 0.88, 0.82), null], ["tabi", Color(0.15, 0.15, 0.17), null]]},
	"set_kenshi": {"name": "Kenshi Shōzoku", "slot": "set", "price": 400, "rank": 1, "desc": "Kimono üstü ve obi, hakama, metal kolluk, hasır zori. Kılıç yolunu seçenlerin giysisi.",
		"stats": {"def": 8, "melee": 0.06, "hp": 15}, "c1": Color(0.2, 0.24, 0.36), "c2": Color(0.75, 0.7, 0.6),
		"parts": [["kimono_ust", Color(0.2, 0.24, 0.36), Color(0.75, 0.7, 0.6)], ["hakama", Color(0.16, 0.16, 0.2), null], ["kolluk", Color(0.55, 0.56, 0.6), null], ["zori", Color(0.7, 0.6, 0.42), null]]},
	"set_samurai": {"name": "Samurai Yoroi", "slot": "set", "price": 700, "rank": 2, "desc": "Zincir örgü gömlek, hakama, hafif samuray zırhı ve zırhlı tozluk. Demir Ülkesi'nin kılıç ustaları gibi.",
		"stats": {"def": 18, "hp": 30, "speed": -0.03}, "c1": Color(0.3, 0.3, 0.32), "c2": Color(0.2, 0.2, 0.22),
		"parts": [["zirhli_gomlek", Color(0.3, 0.3, 0.32), Color(0.2, 0.2, 0.22)], ["hakama", Color(0.18, 0.2, 0.28), null], ["samuray_zirh", Color(0.32, 0.34, 0.42), null], ["ayak_012", Color(0.3, 0.3, 0.33), Color(0.6, 0.6, 0.62)]]},
	"set_sengoku": {"name": "Sengoku Musha", "slot": "set", "price": 900, "rank": 3, "desc": "Uzun kollu gömlek, kızıl hakama, kızıl lake Sengoku zırhı, zırhlı çizme. Savaşan Devletler çağının ruhu.",
		"stats": {"def": 20, "hp": 35, "melee": 0.04, "speed": -0.04}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.12, 0.12, 0.14),
		"parts": [["uzun_gomlek", Color(0.12, 0.12, 0.14), Color(0.12, 0.12, 0.14)], ["kizil_hakama", Color(0.62, 0.12, 0.12), null], ["sengoku_kizil", Color(0.66, 0.14, 0.12), null], ["zirhli_cizme", Color(0.2, 0.18, 0.18), Color(0.5, 0.45, 0.4)]]},
	"set_kage_no": {"name": "Kage no Shinobi", "slot": "set", "price": 450, "rank": 1, "desc": "Gölge ninja üstü, siyah taktik pantolon, kayış koşum, siyah tabi. Gece görevleri için sessiz giysi.",
		"stats": {"def": 7, "speed": 0.06}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.18, 0.18, 0.2),
		"parts": [["golge_ust", Color(0.1, 0.1, 0.12), Color(0.18, 0.18, 0.2)], ["siyah_pant", Color(0.08, 0.08, 0.1), null], ["kayis_kosum", Color(0.25, 0.2, 0.16), null], ["siyah_tabi", Color(0.08, 0.08, 0.1), null]]},
	"set_ame": {"name": "Ame Shōzoku", "slot": "set", "price": 500, "rank": 2, "desc": "Gri uzun kollu gömlek ve pantolon, Yağmur Köyü yeleği, panço. Hiç dinmeyen yağmura göre.",
		"stats": {"def": 12, "hp": 20, "chakra": 15}, "c1": Color(0.32, 0.34, 0.38), "c2": Color(0.32, 0.34, 0.38),
		"parts": [["uzun_gomlek", Color(0.32, 0.34, 0.38), Color(0.32, 0.34, 0.38)], ["ninja_pant", Color(0.28, 0.3, 0.34), null], ["ame_yelek", Color(0.4, 0.42, 0.46), null], ["panco", Color(0.3, 0.32, 0.36), null], ["ayak_014", Color(0.22, 0.22, 0.25), Color(0.6, 0.6, 0.62)]]},
	"set_ne": {"name": "Ne Shōzoku", "slot": "set", "price": 850, "rank": 3, "desc": "Siyah gömlek ve pantolon, Kök Birliği yeleği, kol sargıları. Adı ve yüzü olmayan ninjalar.",
		"stats": {"def": 15, "speed": 0.05, "melee": 0.04}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.1, 0.1, 0.12),
		"parts": [["uzun_gomlek", Color(0.1, 0.1, 0.12), Color(0.1, 0.1, 0.12)], ["siyah_pant", Color(0.08, 0.08, 0.1), null], ["kok_yelek", Color(0.22, 0.22, 0.24), null], ["kol_sargisi", Color(0.85, 0.85, 0.82), null], ["sandalet", Color(0.08, 0.08, 0.1), Color(0.9, 0.9, 0.88)]]},
	"set_soryo": {"name": "Sōryo Shōzoku", "slot": "set", "price": 350, "rank": 1, "desc": "Keşiş üstü, bol pantolon, kesa, hasır zori. Tapınakların savaşçı rahiplerinin giysisi.",
		"stats": {"def": 7, "chakra": 35, "hp": 10}, "c1": Color(0.85, 0.82, 0.72), "c2": Color(0.6, 0.4, 0.2),
		"parts": [["kesis_ustu", Color(0.85, 0.82, 0.72), Color(0.6, 0.4, 0.2)], ["bol_pantolon", Color(0.82, 0.78, 0.68), null], ["kesa", Color(0.72, 0.4, 0.15), null], ["zori", Color(0.7, 0.6, 0.42), null]]},
	"set_ronin": {"name": "Rōnin Shōzoku", "slot": "set", "price": 200, "rank": 0, "desc": "Yamalı gömlek ve pantolon, yırtık gezgin pelerini. Efendisiz kalmış savaşçı.",
		"stats": {"def": 6, "melee": 0.05, "hp": 10}, "c1": Color(0.4, 0.36, 0.3), "c2": Color(0.3, 0.26, 0.2),
		"parts": [["yamali_gomlek", Color(0.4, 0.36, 0.3), Color(0.3, 0.26, 0.2)], ["yamali_pant", Color(0.3, 0.28, 0.24), null], ["yirtik_pelerin", Color(0.35, 0.3, 0.26), null], ["ayak_014", Color(0.3, 0.24, 0.18), Color(0.75, 0.7, 0.6)]]},
	"set_yuki_tabi": {"name": "Yuki Tabi Shōzoku", "slot": "set", "price": 450, "rank": 1, "desc": "Deri ceket, sargılı pantolon, gece pelerini, kürk kenarlı kar çizmesi. Kar Ülkesi yolları için.",
		"stats": {"def": 10, "hp": 30, "speed": -0.01}, "c1": Color(0.36, 0.26, 0.2), "c2": Color(0.8, 0.78, 0.74),
		"parts": [["deri_ceket", Color(0.36, 0.26, 0.2), Color(0.8, 0.78, 0.74)], ["sargili_pant", Color(0.28, 0.26, 0.24), null], ["gece_pelerini", Color(0.22, 0.24, 0.3), null], ["ayak_010", Color(0.4, 0.32, 0.26), Color(0.9, 0.9, 0.88)]]},
	"set_matsuri": {"name": "Matsuri Yukata", "slot": "set", "price": 150, "rank": 0, "desc": "Çizgili yukata ve hasır zori. Festival akşamları için; savaşta koruması az.",
		"stats": {"def": 2, "chakra": 10, "speed": 0.02}, "c1": Color(0.28, 0.36, 0.62), "c2": Color(0.9, 0.86, 0.78),
		"parts": [["yukata", Color(0.28, 0.36, 0.62), Color(0.9, 0.86, 0.78)], ["sivil_pant", Color(0.2, 0.22, 0.3), null], ["zori", Color(0.7, 0.6, 0.42), null]]},
	"set_goken": {"name": "Gōken Shōzoku", "slot": "set", "price": 50, "rank": 0, "agirlik": true, "desc": "Yeşil kolsuz tulum, sargılı ön kollar, turuncu boyunluk ve içi ağırlıklı turuncu tozluklar. Giyiliyken yavaşlarsın ama koştukça bedenin dayanıklılaşır (Gōken ustalarının antrenmanı).",
		"stats": {"def": 3, "melee": 0.03}, "c1": Color(0.16, 0.36, 0.2), "c2": Color(0.16, 0.36, 0.2),
		"parts": [["sargili_kolsuz", Color(0.16, 0.36, 0.2), Color(0.16, 0.36, 0.2)], ["ninja_pant", Color(0.16, 0.36, 0.2), null], ["turuncu_boyunluk", Color(0.96, 0.6, 0.18), null], ["agirlikli_tozluk", Color(0.96, 0.58, 0.16), null], ["sandalet", Color(0.18, 0.2, 0.3), Color(0.92, 0.92, 0.9)]]},
	"set_kurenai_kenpo": {"name": "Akai Kenpō Shōzoku", "slot": "set", "price": 380, "rank": 1, "desc": "Kızıl dövüş ceketi, siyah taktik pantolon, parmaksız eldiven, bağcıklı bilek botu.",
		"stats": {"def": 7, "melee": 0.06, "speed": 0.03}, "c1": Color(0.7, 0.14, 0.14), "c2": Color(0.12, 0.12, 0.14),
		"parts": [["kizil_ceket", Color(0.7, 0.14, 0.14), Color(0.12, 0.12, 0.14)], ["siyah_pant", Color(0.1, 0.1, 0.12), null], ["eldiven", Color(0.1, 0.1, 0.12), null], ["ayak_005", Color(0.18, 0.15, 0.14), Color(0.6, 0.55, 0.5)]]},
	"set_sennin_shugyo": {"name": "Sennin Shugyō Shōzoku", "slot": "set", "price": 950, "rank": 3, "desc": "Uzun kollu gömlek, ninja pantolonu, alev etekli uzun haori. Doğa enerjisi eğitimi alan ninjanın giysisi.",
		"stats": {"def": 12, "chakra": 45, "hp": 25}, "c1": Color(0.85, 0.48, 0.15), "c2": Color(0.12, 0.12, 0.14),
		"parts": [["uzun_gomlek", Color(0.85, 0.48, 0.15), Color(0.12, 0.12, 0.14)], ["ninja_pant", Color(0.85, 0.48, 0.15), null], ["sennin_haorisi", Color(0.72, 0.18, 0.15), Color(0.95, 0.9, 0.8)], ["sandalet", Color(0.12, 0.12, 0.14), Color(0.92, 0.92, 0.9)]]},
	"set_kage": {"name": "Kage Shōzoku", "slot": "set", "price": 0, "rank": 6, "desc": "Köyün liderinin beyaz cübbesi.",
		"stats": {"def": 16, "chakra": 50, "hp": 30}, "c1": Color(0.95, 0.95, 0.92), "c2": Color(0.8, 0.2, 0.15),
		"parts": [["uzun_gomlek", Color(0.15, 0.2, 0.33), Color(0.12, 0.12, 0.14)], ["ninja_pant", Color(0.15, 0.2, 0.33), null], ["kage_cubbesi", Color(0.95, 0.95, 0.92), Color(0.8, 0.2, 0.15)], ["sandalet", Color(0.12, 0.12, 0.14), Color(0.92, 0.92, 0.9)]]},
	"set_hokage": {"name": "Hokage Shōzoku", "slot": "set", "price": 4000, "rank": 6, "desc": "Ateş Ülkesi liderinin tören giysisi: köy renginde kimono üstü, beyaz hakama, eteği Hokage renkli bantlı beyaz Kage cübbesi, hasır zori. Şapkası ayrıca: Kage Şapkası.",
		"stats": {"def": 16, "chakra": 50, "hp": 30}, "c1": Color(0.95, 0.95, 0.92), "c2": Color(0.80, 0.14, 0.12),
		"parts": [["kimono_ust", Color(0.56, 0.10, 0.08), Color(0.80, 0.14, 0.12)], ["hakama", Color(0.93, 0.93, 0.9), null], ["kage_cubbesi", Color(0.97, 0.96, 0.93), Color(0.80, 0.14, 0.12)], ["zori", Color(0.25, 0.2, 0.16), Color(0.92, 0.92, 0.9)]]},
	"set_kazekage": {"name": "Kazekage Shōzoku", "slot": "set", "price": 4000, "rank": 6, "desc": "Rüzgâr Ülkesi liderinin tören giysisi: köy renginde kimono üstü, beyaz hakama, eteği Kazekage renkli bantlı beyaz Kage cübbesi, hasır zori. Şapkası ayrıca: Kage Şapkası.",
		"stats": {"def": 16, "chakra": 50, "hp": 30}, "c1": Color(0.95, 0.95, 0.92), "c2": Color(0.16, 0.45, 0.38),
		"parts": [["kimono_ust", Color(0.11, 0.32, 0.27), Color(0.16, 0.45, 0.38)], ["hakama", Color(0.93, 0.93, 0.9), null], ["kage_cubbesi", Color(0.97, 0.96, 0.93), Color(0.16, 0.45, 0.38)], ["zori", Color(0.25, 0.2, 0.16), Color(0.92, 0.92, 0.9)]]},
	"set_mizukage": {"name": "Mizukage Shōzoku", "slot": "set", "price": 4000, "rank": 6, "desc": "Su Ülkesi liderinin tören giysisi: köy renginde kimono üstü, beyaz hakama, eteği Mizukage renkli bantlı beyaz Kage cübbesi, hasır zori. Şapkası ayrıca: Kage Şapkası.",
		"stats": {"def": 16, "chakra": 50, "hp": 30}, "c1": Color(0.95, 0.95, 0.92), "c2": Color(0.18, 0.38, 0.75),
		"parts": [["kimono_ust", Color(0.13, 0.27, 0.52), Color(0.18, 0.38, 0.75)], ["hakama", Color(0.93, 0.93, 0.9), null], ["kage_cubbesi", Color(0.97, 0.96, 0.93), Color(0.18, 0.38, 0.75)], ["zori", Color(0.25, 0.2, 0.16), Color(0.92, 0.92, 0.9)]]},
	"set_raikage": {"name": "Raikage Shōzoku", "slot": "set", "price": 4000, "rank": 6, "desc": "Yıldırım Ülkesi liderinin tören giysisi: köy renginde kimono üstü, beyaz hakama, eteği Raikage renkli bantlı beyaz Kage cübbesi, hasır zori. Şapkası ayrıca: Kage Şapkası.",
		"stats": {"def": 16, "chakra": 50, "hp": 30}, "c1": Color(0.95, 0.95, 0.92), "c2": Color(0.95, 0.78, 0.16),
		"parts": [["kimono_ust", Color(0.66, 0.55, 0.11), Color(0.95, 0.78, 0.16)], ["hakama", Color(0.93, 0.93, 0.9), null], ["kage_cubbesi", Color(0.97, 0.96, 0.93), Color(0.95, 0.78, 0.16)], ["zori", Color(0.25, 0.2, 0.16), Color(0.92, 0.92, 0.9)]]},
	"set_tsuchikage": {"name": "Tsuchikage Shōzoku", "slot": "set", "price": 4000, "rank": 6, "desc": "Toprak Ülkesi liderinin tören giysisi: köy renginde kimono üstü, beyaz hakama, eteği Tsuchikage renkli bantlı beyaz Kage cübbesi, hasır zori. Şapkası ayrıca: Kage Şapkası.",
		"stats": {"def": 16, "chakra": 50, "hp": 30}, "c1": Color(0.95, 0.95, 0.92), "c2": Color(0.50, 0.30, 0.20),
		"parts": [["kimono_ust", Color(0.35, 0.21, 0.14), Color(0.50, 0.30, 0.20)], ["hakama", Color(0.93, 0.93, 0.9), null], ["kage_cubbesi", Color(0.97, 0.96, 0.93), Color(0.50, 0.30, 0.20)], ["zori", Color(0.25, 0.2, 0.16), Color(0.92, 0.92, 0.9)]]},
	"set_anbu_konoha": {"name": "ANBU Shōzoku: Gece", "slot": "set", "price": 3200, "rank": 4, "desc": "ANBU'nun klasik gece takımı: kolsuz siyah üst, gri metal göğüs plakası, kol koruyucular, siyah tabi. Maskesi ayrıca (ANBU maskeleri).",
		"stats": {"def": 18, "speed": 0.05, "melee": 0.05}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.82, 0.82, 0.8),
		"parts": [["kolsuz_yakali", Color(0.1, 0.1, 0.12), Color(0.1, 0.1, 0.12)], ["ninja_pant", Color(0.1, 0.1, 0.12), null], ["anbu_zirh", Color(0.82, 0.82, 0.8), null], ["kolluk", Color(0.85, 0.85, 0.83), null], ["tabi", Color(0.1, 0.1, 0.12), null]]},
	"set_anbu_kaptan": {"name": "ANBU Shōzoku: Kaptan", "slot": "set", "price": 3800, "rank": 4, "desc": "ANBU takım kaptanının takımı: uzun kollu koyu gömlek, metal göğüs plakası, kol sargısı, sırtta pelerin.",
		"stats": {"def": 20, "speed": 0.04, "chakra": 30}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.85, 0.85, 0.82),
		"parts": [["uzun_gomlek", Color(0.12, 0.12, 0.14), Color(0.12, 0.12, 0.14)], ["ninja_pant", Color(0.12, 0.12, 0.14), null], ["anbu_zirh", Color(0.85, 0.85, 0.82), null], ["kol_sargisi", Color(0.9, 0.9, 0.88), null], ["kisa_pelerin", Color(0.16, 0.16, 0.18), Color(0.3, 0.3, 0.32)], ["sandalet", Color(0.12, 0.12, 0.14), Color(0.92, 0.92, 0.9)]]},
	"set_anbu_yami": {"name": "ANBU Shōzoku: Yami", "slot": "set", "price": 3400, "rank": 4, "desc": "Kolsuz boğazlı siyah üst, düz gri ANBU göğüs plakası (omuz askılı), dirseği aşan siyah kol ısıtıcı + dış kolda metal plaka, sol kolda beyaz bant, diz sargısı, siyah bacak ısıtıcı. Maskesi ayrıca.",
		"stats": {"def": 18, "speed": 0.06, "melee": 0.05}, "c1": Color(0.08, 0.08, 0.1), "c2": Color(0.08, 0.08, 0.1),
		"parts": [["kolsuz_yakali", Color(0.08, 0.08, 0.1), Color(0.08, 0.08, 0.1)], ["sivil_pant", Color(0.08, 0.08, 0.1), null], ["anbu_plaka", Color(0.74, 0.72, 0.78), null], ["anbu_kol_uzun", Color(0.74, 0.72, 0.78), null], ["anbu_ayak_diz", Color(0.08, 0.08, 0.1), Color(0.93, 0.93, 0.92)]]},
	"set_anbu_kasumi": {"name": "ANBU Shōzoku: Kasumi", "slot": "set", "price": 3600, "rank": 4, "desc": "Koyu mor kolsuz üst, gri ANBU plakası, uzun kol ısıtıcı + plaka, iki kolda beyaz bant, boyunda deniz yeşili atkı, belin arkasından sarkan deniz yeşili peştamal, boğumlu bacak bantları.",
		"stats": {"def": 17, "speed": 0.07, "chakra": 25}, "c1": Color(0.13, 0.11, 0.18), "c2": Color(0.16, 0.14, 0.22),
		"parts": [["kolsuz_yakali", Color(0.13, 0.11, 0.18), Color(0.13, 0.11, 0.18)], ["sivil_pant", Color(0.16, 0.14, 0.22), null], ["anbu_plaka", Color(0.72, 0.7, 0.76), null], ["anbu_kol_uzun_cift", Color(0.72, 0.7, 0.76), null], ["anbu_atki", Color(0.2, 0.42, 0.45), null], ["anbu_ayak_bant", Color(0.14, 0.12, 0.2), Color(0.93, 0.93, 0.92)]]},
	"set_anbu_wakate": {"name": "ANBU Shōzoku: Wakate", "slot": "set", "price": 3000, "rank": 4, "desc": "Genç ANBU takımı: kısa kollu boğazlı koyu mor üst, gri ANBU plakası, kısa kolluk (siyah sargı üstünde plaka), baldırda beyaz sargı, sandalet.",
		"stats": {"def": 15, "speed": 0.08, "melee": 0.04}, "c1": Color(0.18, 0.15, 0.24), "c2": Color(0.2, 0.17, 0.27),
		"parts": [["yakali", Color(0.18, 0.15, 0.24), Color(0.18, 0.15, 0.24)], ["ninja_pant", Color(0.2, 0.17, 0.27), null], ["anbu_plaka", Color(0.72, 0.7, 0.76), null], ["anbu_kol_kisa", Color(0.72, 0.7, 0.76), null], ["anbu_ayak_sargi", Color(0.15, 0.13, 0.2), Color(0.93, 0.93, 0.92)]]},
	"set_anbu_byakue": {"name": "ANBU Shōzoku: Byakue", "slot": "set", "price": 3600, "rank": 4, "desc": "Beyaz uzun ANBU paltosu: kapüşon gibi bol yaka, geniş kollar, önü kapalı; altında boğazlı siyah üst, koyu pantolon, baldırda koyu sargı, sandalet.",
		"stats": {"def": 16, "chakra": 40, "speed": 0.04}, "c1": Color(0.08, 0.08, 0.1), "c2": Color(0.12, 0.12, 0.18),
		"parts": [["uzun_gomlek", Color(0.08, 0.08, 0.1), Color(0.08, 0.08, 0.1)], ["ninja_pant", Color(0.12, 0.12, 0.18), null], ["anbu_beyaz_palto", Color(0.9, 0.88, 0.84), null], ["anbu_ayak_sargi", Color(0.1, 0.1, 0.14), Color(0.13, 0.12, 0.2)]]},
}

const KAGE_SETS := ["set_hokage", "set_kazekage", "set_mizukage", "set_raikage", "set_tsuchikage"]
const KAGE_HATS := ["kage_sapkasi", "hokage_sapkasi", "kazekage_sapkasi", "mizukage_sapkasi", "raikage_sapkasi", "tsuchikage_sapkasi"]
const KAGE_VID := {"set_hokage": "konoha", "set_kazekage": "suna", "set_mizukage": "kiri", "set_raikage": "kumo", "set_tsuchikage": "iwa",
	"hokage_sapkasi": "konoha", "kazekage_sapkasi": "suna", "mizukage_sapkasi": "kiri", "raikage_sapkasi": "kumo", "tsuchikage_sapkasi": "iwa"}


## Rütbe eşyası satılabilir/takılabilir mi: ANBU setleri ANBU+ ; Kage setleri/şapkaları yalnız Kage, köye özel olanlar yalnız kendi köyünün
static func rank_gear_ok(id: String) -> bool:
	if Game.profile.is_empty():
		return false
	var r = eff_rank(Game.profile)
	if id in ANBU_SETS or id == "set_anbu":
		return r >= 4
	if id in KAGE_SETS or id in KAGE_HATS or id == "set_kage":
		if r < 6:
			return false
		return not KAGE_VID.has(id) or KAGE_VID[id] == Progress.home()
	return true


const ANBU_SETS := ["set_anbu_konoha", "set_anbu_kaptan", "set_anbu_yami", "set_anbu_kasumi", "set_anbu_wakate", "set_anbu_byakue"]
const SHOP_SETS := ["set_goken", "set_genin", "set_shinobi", "set_chunin", "set_suna_chunin", "set_kiri_chunin", "set_kumo_chunin", "set_iwa_chunin", "set_uchiha", "set_suna", "set_tabibito", "set_iryonin", "set_kenpo", "set_kenshi", "set_samurai", "set_sengoku", "set_kage_no", "set_ame", "set_soryo", "set_ronin", "set_yuki_tabi", "set_matsuri", "set_kurenai_kenpo", "set_ne", "set_sennin_shugyo"]
## Boş bırakılamayan yuvalar (çıplak kalınmaz)
const REQUIRED := ["govde", "bacak", "ayak"]

## stats: def (hasar azaltma puanı), hp, chakra, speed (oran), melee (oran)
## silah: dmg (oran), reach (m), style: blade | dual | sword | heavy | staff | chain | sickle | claw | fan | fist
const ITEMS := {
	# --- kafa
	"alin_koruyucu": {"name": "Alın Koruyucu", "slot": "kafa", "price": 0, "rank": 1, "desc": "Köyünün sembolü. Genin olunca verilir.", "stats": {"def": 2}, "look": {"band_style": "head"}, "c1": Color(0.15, 0.22, 0.55)},
	"alin_boyun": {"name": "Alın Koruyucu (Boyunda)", "slot": "kafa", "price": 0, "rank": 1, "desc": "Alın koruyucuyu boynuna bağlarsın.", "stats": {"def": 2}, "look": {"band_style": "neck"}, "c1": Color(0.15, 0.22, 0.55)},
	"bandana": {"name": "Bandana Alın Koruyucu", "slot": "kafa", "price": 260, "rank": 1, "desc": "Başın tepesini saran bez, önünde köy plakası.", "stats": {"def": 3}, "look": {"head_style": "bandana", "band_style": "none"}, "c1": Color(0.15, 0.22, 0.55)},
	"kasa": {"name": "Hasır Şapka (Kasa)", "slot": "kafa", "price": 120, "rank": 0, "desc": "Geniş kenarlı gezgin şapkası. Güneşten ve yağmurdan korur.", "stats": {"def": 1, "chakra": 10}, "look": {"head_style": "kasa"}, "c1": Color(0.78, 0.66, 0.42)},
	"kapuson": {"name": "Bez Kapüşon", "slot": "kafa", "price": 150, "rank": 0, "desc": "Kafayı ve enseyi örten kapüşon. Gizlilik ustalarının tercihi.", "stats": {"def": 2, "speed": 0.02}, "look": {"head_style": "kapuson"}, "c1": Color(0.22, 0.2, 0.24)},
	"kafa_bandaji": {"name": "Kafa Bandajı", "slot": "kafa", "price": 40, "rank": 0, "desc": "Alnı saran bandaj. Savaşın izlerini taşır.", "stats": {"hp": 10}, "look": {"head_style": "bandaj"}, "c1": Color(0.92, 0.9, 0.86)},
	# --- yüz
	"bez_maske": {"name": "Bez Maske", "slot": "yuz", "price": 90, "rank": 0, "desc": "Yüzün alt yarısını ve boynu örter. Kimliğini gizler.", "stats": {"def": 1, "chakra": 10}, "look": {"face_style": "cloth"}, "c1": Color(0.15, 0.15, 0.2)},
	"anbu_maske": {"name": "ANBU Maskesi: Kedi", "slot": "yuz", "price": 900, "rank": 4, "desc": "Gizli birliklerin kedi maskesi.", "stats": {"def": 6, "melee": 0.05}, "look": {"face_style": "anbu_kedi"}, "c1": Color(0.95, 0.95, 0.95)},
	"anbu_kurt": {"name": "ANBU Maskesi: Kurt", "slot": "yuz", "price": 900, "rank": 4, "desc": "Kurt maskesi: avcı içgüdüsü.", "stats": {"def": 5, "melee": 0.08}, "look": {"face_style": "anbu_kurt"}, "c1": Color(0.95, 0.95, 0.95)},
	"anbu_kus": {"name": "ANBU Maskesi: Kuş", "slot": "yuz", "price": 900, "rank": 4, "desc": "Gagalı kuş maskesi: hız ve keşif.", "stats": {"def": 5, "speed": 0.05}, "look": {"face_style": "anbu_kus"}, "c1": Color(0.95, 0.95, 0.95)},
	"anbu_ayi": {"name": "ANBU Maskesi: Ayı", "slot": "yuz", "price": 900, "rank": 4, "desc": "Yuvarlak kulaklı ayı maskesi: dayanıklılık.", "stats": {"def": 8, "hp": 30}, "look": {"face_style": "anbu_ayi"}, "c1": Color(0.95, 0.95, 0.95)},
	"kitsune_maske": {"name": "Kitsune Maskesi", "slot": "yuz", "price": 420, "rank": 1, "desc": "Festival tilki maskesi. Kimliğini gizler.", "stats": {"def": 2, "chakra": 15}, "look": {"face_style": "kitsune"}, "c1": Color(0.95, 0.95, 0.95)},
	"tengu_maske": {"name": "Tengu Maskesi", "slot": "yuz", "price": 650, "rank": 2, "desc": "Uzun burunlu dağ ruhu maskesi.", "stats": {"def": 3, "speed": 0.04}, "look": {"face_style": "tengu"}, "c1": Color(0.75, 0.12, 0.1)},
	"oni_maske": {"name": "Oni Maskesi", "slot": "yuz", "price": 800, "rank": 2, "desc": "Samuray iblis yüz zırhı. Düşmanı korkutur.", "stats": {"def": 5, "melee": 0.04}, "look": {"face_style": "oni"}, "c1": Color(0.2, 0.2, 0.22)},
	"gaz_maskesi": {"name": "Gaz Maskesi", "slot": "yuz", "price": 380, "rank": 1, "desc": "Zehirli bulutlara karşı filtreli maske.", "stats": {"def": 3, "hp": 15}, "look": {"face_style": "gas"}, "c1": Color(0.2, 0.22, 0.2)},
	"gozluk": {"name": "Ninja Gözlüğü", "slot": "yuz", "price": 140, "rank": 0, "desc": "Rüzgar ve kum fırtınasında gözleri korur.", "stats": {"speed": 0.02, "chakra": 5}, "look": {"face_style": "goggles"}, "c1": Color(0.95, 0.55, 0.15)},
	# --- üst
	"tisort": {"name": "Kısa Kollu Tişört", "slot": "govde", "price": 40, "rank": 0, "desc": "Hafif ve rahat.", "stats": {"speed": 0.03}, "look": {"top_style": "tisort"}, "c1": Color(0.75, 0.2, 0.25), "c2": Color(0.12, 0.12, 0.14)},
	"kivrik_gomlek": {"name": "Kolu Kıvrık Ninja Gömleği", "slot": "govde", "price": 120, "rank": 0, "desc": "Kolları ön kol ortasına kadar kıvrılmış klasik shinobi gömleği (köy tulumu).", "stats": {"def": 2, "speed": 0.01}, "look": {"top_style": "uzun", "sleeve_roll": true}, "c1": Color(0.15, 0.2, 0.33), "c2": Color(0.12, 0.12, 0.14)},
	"uzun_gomlek": {"name": "Uzun Kollu Ninja Gömleği", "slot": "govde", "price": 120, "rank": 0, "desc": "Klasik shinobi gömleği.", "stats": {"def": 2}, "look": {"top_style": "uzun"}, "c1": Color(0.15, 0.2, 0.33), "c2": Color(0.12, 0.12, 0.14)},
	"ceket": {"name": "Fermuarlı Ceket", "slot": "govde", "price": 200, "rank": 0, "desc": "İki renkli, yüksek yakalı eğitim ceketi.", "stats": {"def": 3, "hp": 10}, "look": {"top_style": "ceket"}, "c1": Color(0.95, 0.5, 0.12), "c2": Color(0.12, 0.12, 0.14)},
	"yakali": {"name": "Yüksek Yakalı Gömlek", "slot": "govde", "price": 180, "rank": 0, "desc": "Bilek sargılı, kısa kollu. Chakra akışını rahatlatır.", "stats": {"def": 2, "chakra": 15}, "look": {"top_style": "yakali"}, "c1": Color(0.15, 0.2, 0.33), "c2": Color(0.12, 0.12, 0.14)},
	"zirhli_gomlek": {"name": "Zincir Örgü Gömlek", "slot": "govde", "price": 450, "rank": 1, "desc": "Uzun kollu, ince zincir örgü ağ gömlek. Kesiklere dayanır.", "stats": {"def": 6, "speed": -0.02}, "look": {"top_style": "uzun", "top_pattern": 1}, "c1": Color(0.2, 0.22, 0.24), "c2": Color(0.12, 0.12, 0.14)},
	"file_atlet": {"name": "File Atlet", "slot": "govde", "price": 160, "rank": 0, "desc": "Kısa kollu ağ fanila. Hafif koruma, tam hareket.", "stats": {"def": 3, "speed": 0.02}, "look": {"top_style": "tisort", "top_pattern": 1}, "c1": Color(0.15, 0.15, 0.17), "c2": Color(0.12, 0.12, 0.14)},
	"kolsuz_yakali": {"name": "Kolsuz Yakalı Gömlek", "slot": "govde", "price": 150, "rank": 0, "desc": "Kolları açık, boğazlı savaş gömleği. Taijutsu ustalarına göre.", "stats": {"melee": 0.06}, "look": {"top_style": "kolsuz"}, "c1": Color(0.85, 0.82, 0.75), "c2": Color(0.12, 0.12, 0.14)},
	"sargili_kolsuz": {"name": "Sargılı Savaşçı Üstü", "slot": "govde", "price": 220, "rank": 0, "desc": "Kolsuz üst, ön kollar bandajla sarılı.", "stats": {"melee": 0.08, "def": 1}, "look": {"top_style": "kolsuz", "arm_wraps": true}, "c1": Color(0.2, 0.38, 0.22), "c2": Color(0.12, 0.12, 0.14)},
	"kimono_ust": {"name": "Kimono Üstü ve Obi", "slot": "govde", "price": 300, "rank": 0, "desc": "Çapraz yakalı, geniş kollu üst; belde obi kuşağı.", "stats": {"chakra": 25}, "look": {"top_style": "kimono"}, "c1": Color(0.3, 0.32, 0.5), "c2": Color(0.75, 0.2, 0.25)},
	# --- alt
	"ninja_pant": {"name": "Ninja Pantolonu", "slot": "bacak", "price": 100, "rank": 0, "desc": "Baldırdan sargılı, hareket kısıtlamaz.", "stats": {"def": 2}, "look": {"pants_style": "ninja"}, "c1": Color(0.15, 0.2, 0.33)},
	"sort": {"name": "Diz Altı Şort", "slot": "bacak", "price": 80, "rank": 0, "desc": "Hafif. Koşu hızı biraz artar.", "stats": {"speed": 0.04}, "look": {"pants_style": "sort"}, "c1": Color(0.15, 0.15, 0.17)},
	"sivil_pant": {"name": "Uzun Pantolon", "slot": "bacak", "price": 40, "rank": 0, "desc": "Sivil kıyafeti.", "stats": {}, "look": {"pants_style": "sivil"}, "c1": Color(0.35, 0.3, 0.28)},
	"sargili_pant": {"name": "Sargılı Pantolon", "slot": "bacak", "price": 160, "rank": 0, "desc": "Dizden aşağısı sıkıca sarılı. Tekmeler daha keskin.", "stats": {"melee": 0.05, "speed": 0.02}, "look": {"pants_style": "sargi"}, "c1": Color(0.12, 0.12, 0.14)},
	"hakama": {"name": "Hakama", "slot": "bacak", "price": 340, "rank": 1, "desc": "Bol, pilili geniş paçalı pantolon. Kılıç ustalarının giysisi.", "stats": {"def": 3, "chakra": 10}, "look": {"pants_style": "sivil", "hakama": true}, "c1": Color(0.18, 0.18, 0.24)},
	# --- ayak
	"sandalet": {"name": "Ninja Sandaleti", "slot": "ayak", "price": 60, "rank": 0, "desc": "Açık burunlu shinobi sandaleti ve baldır sargıları.", "stats": {"speed": 0.03}, "look": {"foot_style": "shinobi"}, "c1": Color(0.15, 0.2, 0.32), "c2": Color(0.92, 0.92, 0.9)},
	"takviyeli_sandalet": {"name": "Takviyeli Sandalet", "slot": "ayak", "price": 260, "rank": 1, "desc": "Metal tabanlı, tekmeler daha sert.", "stats": {"def": 2, "melee": 0.06}, "look": {"foot_style": "sandal"}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.92, 0.92, 0.9)},
	"tabi": {"name": "Tabi Ayakkabı", "slot": "ayak", "price": 180, "rank": 0, "desc": "Ayağı tamamen saran sessiz ninja ayakkabısı.", "stats": {"speed": 0.05}, "look": {"foot_style": "tabi"}, "c1": Color(0.12, 0.12, 0.15), "c2": Color(0.92, 0.92, 0.9)},
	"zori": {"name": "Hasır Zori", "slot": "ayak", "price": 30, "rank": 0, "desc": "Parmak arası hasır terlik. Sivil işi.", "stats": {}, "look": {"foot_style": "zori"}, "c1": Color(0.78, 0.68, 0.45), "c2": Color(0.92, 0.92, 0.9)},
	# --- yelek / zırh
	"chunin_yelek": {"name": "Konoha Taktik Yeleği", "slot": "zirh", "price": 0, "rank": 2, "desc": "Chunin ve Jonin'lerin parşömen cepli yeleği.", "stats": {"def": 10, "hp": 20}, "look": {"vest_style": 0}, "c1": Color(0.38, 0.48, 0.28)},
	"suna_yelek": {"name": "Kum Köyü Yeleği", "slot": "zirh", "price": 850, "rank": 2, "desc": "Bej yelek, omuzdan çapraz kayış.", "stats": {"def": 9, "speed": 0.03}, "look": {"vest_style": 1}, "c1": Color(0.72, 0.62, 0.45)},
	"kiri_yelek": {"name": "Sis Köyü Yeleği", "slot": "zirh", "price": 850, "rank": 2, "desc": "Yatay dikişli, sudan etkilenmeyen yelek.", "stats": {"def": 9, "chakra": 20}, "look": {"vest_style": 2}, "c1": Color(0.45, 0.52, 0.46)},
	"kumo_yelek": {"name": "Bulut Köyü Yeleği", "slot": "zirh", "price": 850, "rank": 2, "desc": "Tek omuz askılı hafif yelek.", "stats": {"def": 8, "melee": 0.06}, "look": {"vest_style": 3}, "c1": Color(0.85, 0.85, 0.82)},
	"iwa_yelek": {"name": "Kaya Köyü Yeleği", "slot": "zirh", "price": 850, "rank": 2, "desc": "Kırmızı yelek, tek kolu zırhlı.", "stats": {"def": 12, "speed": -0.02}, "look": {"vest_style": 4}, "c1": Color(0.62, 0.18, 0.15)},
	"anbu_plaka": {"name": "ANBU Göğüs Plakası", "slot": "zirh", "price": 0, "rank": 4, "desc": "Düz, hafif metal göğüs plakası; omuz askılarıyla bağlanır.", "stats": {"def": 12, "speed": 0.04}, "look": {"vest_style": 12}, "c1": Color(0.74, 0.72, 0.78)},
	"anbu_kol_uzun": {"name": "ANBU Uzun Kolluk", "slot": "kol", "price": 0, "rank": 4, "desc": "Dirseği aşan siyah kol ısıtıcı, dış kolda metal plaka; sol kolda beyaz bant.", "stats": {"def": 4}, "look": {"anbu_arm": "uzun", "anbu_band": 1}, "c1": Color(0.74, 0.72, 0.78)},
	"anbu_kol_uzun_cift": {"name": "ANBU Uzun Kolluk (Bantlı)", "slot": "kol", "price": 0, "rank": 4, "desc": "Dirseği aşan siyah kol ısıtıcı ve plaka; iki kolda beyaz bant.", "stats": {"def": 4}, "look": {"anbu_arm": "uzun", "anbu_band": 2}, "c1": Color(0.72, 0.7, 0.76)},
	"anbu_kol_kisa": {"name": "ANBU Kısa Kolluk", "slot": "kol", "price": 0, "rank": 4, "desc": "Ön kolda siyah sargı üstünde metal plaka.", "stats": {"def": 3}, "look": {"anbu_arm": "kisa"}, "c1": Color(0.72, 0.7, 0.76)},
	"anbu_atki": {"name": "ANBU Atkı ve Peştamal", "slot": "dis", "price": 0, "rank": 4, "desc": "Boyna sarılı atkı; belin arkasından aynı renk peştamal sarkar.", "stats": {"speed": 0.02}, "look": {"outer_style": "atki", "anbu_tasset": true}, "c1": Color(0.2, 0.42, 0.45)},
	"anbu_beyaz_palto": {"name": "ANBU Beyaz Paltosu", "slot": "dis", "price": 0, "rank": 4, "desc": "Önü kapalı beyaz uzun palto, bol kapüşon yaka, geniş kollar.", "stats": {"def": 6, "chakra": 30}, "look": {"outer_style": "anbu_palto"}, "c1": Color(0.9, 0.88, 0.84)},
	"anbu_ayak_diz": {"name": "ANBU Bacak Isıtıcı", "slot": "ayak", "price": 0, "rank": 4, "desc": "Dizden bileğe siyah ısıtıcı, sağ dizde beyaz sargı, açık parmaklı shinobi sandaleti.", "stats": {"speed": 0.05}, "look": {"foot_style": "shinobi", "anbu_leg": "diz"}, "c1": Color(0.08, 0.08, 0.1), "c2": Color(0.93, 0.93, 0.92)},
	"anbu_ayak_bant": {"name": "ANBU Bantlı Tozluk", "slot": "ayak", "price": 0, "rank": 4, "desc": "Baldırı saran boğum boğum bantlı koyu tozluk ve kapalı ayakkabı.", "stats": {"speed": 0.05}, "look": {"foot_style": "tabi", "anbu_leg": "bant"}, "c1": Color(0.14, 0.12, 0.2), "c2": Color(0.93, 0.93, 0.92)},
	"anbu_ayak_sargi": {"name": "ANBU Sargılı Sandalet", "slot": "ayak", "price": 0, "rank": 4, "desc": "Baldırı saran sargı ve shinobi sandaleti.", "stats": {"speed": 0.05}, "look": {"foot_style": "shinobi"}, "c1": Color(0.12, 0.12, 0.16), "c2": Color(0.93, 0.93, 0.92)},
	"anbu_zirh": {"name": "ANBU Zırhı", "slot": "zirh", "price": 0, "rank": 4, "desc": "Hafif metal göğüs plakası ve omuz koruması.", "stats": {"def": 14, "speed": 0.03}, "look": {"vest_style": 5}, "c1": Color(0.75, 0.75, 0.78)},
	"samuray_zirh": {"name": "Hafif Samuray Zırhı", "slot": "zirh", "price": 1400, "rank": 3, "desc": "Lamel plakalı göğüslük ve omuzluklar. Ağır ama sağlam.", "stats": {"def": 18, "hp": 40, "speed": -0.05}, "look": {"vest_style": 6}, "c1": Color(0.35, 0.2, 0.18)},
	"sengoku_kizil": {"name": "Sengoku Yoroi: Akane", "slot": "zirh", "price": 2600, "rank": 3, "desc": "Savaşan Devletler döneminin kat kat lamel zırhı: geniş omuzluklar, plaka etek, kol koruması. Yangın görmüş kızıl lake.", "stats": {"def": 24, "hp": 60, "speed": -0.06}, "look": {"vest_style": 6, "armor_style": "sengoku"}, "c1": Color(0.55, 0.14, 0.11)},
	"sengoku_lacivert": {"name": "Sengoku Yoroi: Ruri", "slot": "zirh", "price": 2600, "rank": 3, "desc": "Lacivert lake plakalar, gümüş bağcıklar. Su gibi soğukkanlı komutanların zırhı.", "stats": {"def": 22, "chakra": 40, "speed": -0.05}, "look": {"vest_style": 6, "armor_style": "sengoku"}, "c1": Color(0.16, 0.22, 0.38)},
	"sengoku_kara": {"name": "Sengoku Yoroi: Shikkoku", "slot": "zirh", "price": 2600, "rank": 3, "desc": "Kömür karası plakalar, koyu kırmızı bağcıklar. Yenilmez bir klan reisine yaraşır.", "stats": {"def": 23, "melee": 0.06, "speed": -0.05}, "look": {"vest_style": 6, "armor_style": "sengoku"}, "c1": Color(0.15, 0.14, 0.15)},
	"sengoku_kahve": {"name": "Sengoku Yoroi: Kogecha", "slot": "zirh", "price": 2600, "rank": 3, "desc": "Toprak kahvesi lake, bronz bağcıklar. Uzun seferlerin yorgun ama sağlam zırhı.", "stats": {"def": 25, "hp": 40, "speed": -0.06}, "look": {"vest_style": 6, "armor_style": "sengoku"}, "c1": Color(0.4, 0.27, 0.17)},
	"deri_yelek": {"name": "Deri Yelek", "slot": "zirh", "price": 350, "rank": 1, "desc": "Paralı askerlerin sevdiği kalın yelek.", "stats": {"def": 6}, "look": {"vest_style": 0}, "c1": Color(0.4, 0.3, 0.2)},
	# --- dış giysi
	"kage_cubbesi": {"name": "Kage Cübbesi", "slot": "dis", "price": 0, "rank": 6, "desc": "Köyün liderinin beyaz cübbesi; eteğinde köyün rengi ve Kage yazısı.", "stats": {"def": 10, "chakra": 60, "hp": 40}, "look": {"outer_style": "palto"}, "c1": Color(0.96, 0.95, 0.92)},
	"kage_sapkasi": {"name": "Kage Şapkası", "slot": "kafa", "price": 1500, "rank": 6, "desc": "Geniş kenarlı tören şapkası. Önünde köyün kanjisi.", "stats": {"def": 4, "chakra": 30}, "look": {"head_style": "kage"}, "c1": Color(0.95, 0.94, 0.9)},
	"akatsuki_sapkasi": {"name": "Akatsuki Şapkası", "slot": "kafa", "price": 900, "rank": 0, "desc": "Hasır sivri şapka; kenarından yüzü gizleyen beyaz kâğıt şeritler ve çan sarkar.", "stats": {"def": 3, "speed": 0.02}, "look": {"head_style": "akatsuki"}, "c1": Color(0.78, 0.63, 0.46)},
	"hiruzen_migferi": {"name": "Savaş Miğferi (Hiruzen)", "slot": "kafa", "price": 1400, "rank": 0, "desc": "Beyaz savaş miğferi; alında metal plaka, iki yanda zincirli zırh plakaları.", "stats": {"def": 9, "hp": 25, "speed": -0.02}, "look": {"head_style": "miğfer"}, "c1": Color(0.93, 0.93, 0.92)},
	"orgu_bere": {"name": "Örgü Bere", "slot": "kafa", "price": 80, "rank": 0, "desc": "Kafayı saran yumuşak örgü bere.", "stats": {"hp": 10}, "look": {"head_style": "bere"}, "c1": Color(0.25, 0.22, 0.22)},
	"ichiraku_kepi": {"name": "Ichiraku Kepi", "slot": "kafa", "price": 60, "rank": 0, "desc": "Ramen ustasının düz tepeli siyah kepi; önünde kırmızı 一楽.", "stats": {"chakra": 10}, "look": {"head_style": "teuchi"}, "c1": Color(0.08, 0.08, 0.12)},
	"bas_ortusu": {"name": "Baş Örtüsü", "slot": "kafa", "price": 60, "rank": 0, "desc": "Başın tepesini saran, ensede bağlanan bez örtü.", "stats": {"hp": 8}, "look": {"head_style": "basortusu"}, "c1": Color(0.12, 0.13, 0.22)},
	"sargi_kep": {"name": "Sargı Kep", "slot": "kafa", "price": 120, "rank": 0, "desc": "Kafayı saran beyaz bez sargı; çapraz koyu bağ, tepede bez düğümü.", "stats": {"hp": 10}, "look": {"head_style": "iwabe"}, "c1": Color(0.93, 0.93, 0.92)},
	"uyku_kepi": {"name": "Uyku Kepi", "slot": "kafa", "price": 90, "rank": 0, "desc": "Koyu kep, beyaz kıvrık manşet; önünde çizgi film gözleri ve burun.", "stats": {"chakra": 8}, "look": {"head_style": "uyku"}, "c1": Color(0.16, 0.17, 0.3)},
	"samuray_basligi": {"name": "Samuray Başlığı", "slot": "kafa", "price": 600, "rank": 0, "desc": "Kafatasına oturan siyah başlık, alında arma, çene altında bağlanan mor kordon ve püsküller.", "stats": {"def": 4, "melee": 0.02}, "look": {"head_style": "samuray_s"}, "c1": Color(0.08, 0.08, 0.1)},
	"samuray_bandi": {"name": "Samuray Bandı", "slot": "kafa", "price": 450, "rank": 0, "desc": "Alnı örten geniş koyu bant; ensede beyaz bez bağ.", "stats": {"def": 3, "speed": 0.02}, "look": {"head_style": "samuray_k"}, "c1": Color(0.15, 0.17, 0.3)},
	"kurbaga_basligi": {"name": "Kurbağa Başlığı", "slot": "kafa", "price": 150, "rank": 0, "desc": "Yüzü açık bırakan koca kurbağa kapüşonu; tepede iki göz, yanaklarda pembe daire.", "stats": {"hp": 15}, "look": {"head_style": "kurbaga"}, "c1": Color(0.2, 0.2, 0.3)},
	"han_sapkasi": {"name": "Hasır Gezgin Şapkası", "slot": "kafa", "price": 500, "rank": 0, "desc": "Geniş gri hasır koni; kulakları ve çeneyi örten mor bez sarkıtlar.", "stats": {"def": 3, "hp": 20}, "look": {"head_style": "han"}, "c1": Color(0.48, 0.42, 0.66)},
	"kardan_adam": {"name": "Kardan Adam Başı", "slot": "kafa", "price": 100, "rank": 0, "desc": "Başı tümüyle örten kar topu; kömür gözler, havuç burun, sarı kova.", "stats": {"hp": 5}, "look": {"head_style": "kardan"}, "c1": Color(0.97, 0.97, 0.98)},
	"gelin_duvagi": {"name": "Gelin Duvağı", "slot": "kafa", "price": 300, "rank": 0, "desc": "Yeşil örgü kep ve başı, sırtı örten bele inen bej duvak.", "stats": {"chakra": 20}, "look": {"head_style": "gelin"}, "c1": Color(0.86, 0.8, 0.66)},
	"hokage_sapkasi": {"name": "Hokage Şapkası", "slot": "kafa", "price": 1500, "rank": 6, "desc": "Kırmızı Hokage şapkası; önünde beyaz kama üstünde 火, arkada omuza inen beyaz örtü.", "stats": {"def": 4, "chakra": 30}, "look": {"head_style": "kage", "kage_vid": "konoha"}, "c1": Color(0.95, 0.94, 0.9)},
	"kazekage_sapkasi": {"name": "Kazekage Şapkası", "slot": "kafa", "price": 1500, "rank": 6, "desc": "Yeşil Kazekage şapkası; önünde 風, arkada beyaz örtü.", "stats": {"def": 4, "chakra": 30}, "look": {"head_style": "kage", "kage_vid": "suna"}, "c1": Color(0.95, 0.94, 0.9)},
	"mizukage_sapkasi": {"name": "Mizukage Şapkası", "slot": "kafa", "price": 1500, "rank": 6, "desc": "Lacivert Mizukage şapkası; önünde 水, arkada beyaz örtü.", "stats": {"def": 4, "chakra": 30}, "look": {"head_style": "kage", "kage_vid": "kiri"}, "c1": Color(0.95, 0.94, 0.9)},
	"raikage_sapkasi": {"name": "Raikage Şapkası", "slot": "kafa", "price": 1500, "rank": 6, "desc": "Hardal sarısı Raikage şapkası; önünde 雷, arkada beyaz örtü.", "stats": {"def": 4, "chakra": 30}, "look": {"head_style": "kage", "kage_vid": "kumo"}, "c1": Color(0.95, 0.94, 0.9)},
	"tsuchikage_sapkasi": {"name": "Tsuchikage Şapkası", "slot": "kafa", "price": 1500, "rank": 6, "desc": "Kahverengi Tsuchikage şapkası; önünde 土, arkada beyaz örtü.", "stats": {"def": 4, "chakra": 30}, "look": {"head_style": "kage", "kage_vid": "iwa"}, "c1": Color(0.95, 0.94, 0.9)},
	"jonin_komutan_paltosu": {"name": "Jōnin Komutanı Haorisi", "slot": "dis", "price": 0, "rank": 3, "desc": "Jōnin komutanlarına verilen yeşil-gri haori.", "stats": {"def": 6, "chakra": 25}, "look": {"outer_style": "haori"}, "c1": Color(0.3, 0.38, 0.3)},
	"kok_maskesi": {"name": "Kök Birliği Maskesi", "slot": "yuz", "price": 0, "rank": 4, "desc": "Kök (Ne) biriminin ifadesiz beyaz maskesi. Varlığı resmî kayıtlarda yok.", "stats": {"def": 6, "speed": 0.04}, "look": {"face_style": "anbu_kus"}, "c1": Color(0.88, 0.88, 0.86)},
	"seyahat_pelerini": {"name": "Seyahat Pelerini", "slot": "dis", "price": 280, "rank": 0, "desc": "Dizlere inen kalın yolcu pelerini.", "stats": {"def": 3, "hp": 15}, "look": {"outer_style": "pelerin"}, "c1": Color(0.4, 0.32, 0.24)},
	"kisa_pelerin": {"name": "Kısa Pelerin ve Atkı", "slot": "dis", "price": 220, "rank": 0, "desc": "Omuzdan sırta inen pelerin, boyunda kalın atkı.", "stats": {"def": 2, "speed": 0.02}, "look": {"outer_style": "kisa"}, "c1": Color(0.6, 0.15, 0.15)},
	"uzun_palto": {"name": "Komutan Paltosu", "slot": "dis", "price": 1100, "rank": 3, "desc": "Önü açık, eteği dalgalanan uzun palto.", "stats": {"def": 6, "chakra": 30}, "look": {"outer_style": "palto"}, "c1": Color(0.9, 0.9, 0.88)},
	"haori": {"name": "Haori", "slot": "dis", "price": 420, "rank": 1, "desc": "Kalçaya inen geniş kollu üst ceket.", "stats": {"chakra": 20, "def": 2}, "look": {"outer_style": "haori"}, "c1": Color(0.15, 0.15, 0.2)},
	"atki": {"name": "Uzun Atkı", "slot": "dis", "price": 70, "rank": 0, "desc": "Boyna sarılan, ucu sırtta uçuşan atkı.", "stats": {"speed": 0.01}, "look": {"outer_style": "atki"}, "c1": Color(0.75, 0.2, 0.25)},
	# --- kol / koruma
	"kolluk": {"name": "Metal Kolluk", "slot": "kol", "price": 200, "rank": 0, "desc": "Ön kolu saran metal plakalı koruyucu. Bloklar daha sağlam.", "stats": {"def": 4}, "look": {"guards": "kol"}, "c1": Color(0.55, 0.58, 0.62)},
	"eldiven": {"name": "Parmaksız Eldiven", "slot": "kol", "price": 90, "rank": 0, "desc": "Elin üstünde metal plaka, parmaklar açık.", "stats": {"melee": 0.05}, "look": {"gloves": true}, "c1": Color(0.12, 0.12, 0.14)},
	"agirlikli_tozluk": {"name": "Ağırlıklı Tozluk", "slot": "kol", "price": 0, "rank": 0, "desc": "İncikleri saran turuncu tozluk; içinde ağırlıklar var.", "stats": {}, "look": {"leg_warmers": Color(0.96, 0.58, 0.16)}, "c1": Color(0.96, 0.58, 0.16)},
	"turuncu_boyunluk": {"name": "Turuncu Boyunluk", "slot": "kol", "price": 0, "rank": 0, "desc": "Boynu saran kalın, dilimli turuncu boyunluk.", "stats": {}, "look": {"neck_warmer": Color(0.96, 0.6, 0.18)}, "c1": Color(0.96, 0.6, 0.18)},
	"kol_sargisi": {"name": "Kol Sargısı", "slot": "kol", "price": 30, "rank": 0, "desc": "Ön kolları saran bandaj.", "stats": {"melee": 0.03}, "look": {"arm_wraps": true}, "c1": Color(0.92, 0.92, 0.9)},
	"bacak_koruma": {"name": "Kaval Koruyucu", "slot": "kol", "price": 180, "rank": 0, "desc": "Kaval kemiğini saran metal plaka.", "stats": {"def": 3, "melee": 0.03}, "look": {"guards": "bacak"}, "c1": Color(0.55, 0.58, 0.62)},
	"iwa_pant": {"name": "Iwa Kanatlı Pantolonu", "slot": "bacak", "price": 0, "rank": 1, "desc": "Bir yanından dize kadar koyu kanat sarkan pantolon.", "stats": {"def": 2}, "look": {"pants_style": "ninja", "pants_flap": Color(0.48, 0.07, 0.1)}, "c1": Color(0.72, 0.16, 0.2)},
	"kiri_koruma": {"name": "Kiri Koruyucuları", "slot": "kol", "price": 0, "rank": 1, "desc": "Dirsekten bileğe çizgili kolluk ve kaval koruyucuları.", "stats": {"def": 3}, "look": {"guards": "ikisi", "guard_long": true, "guard_stripes": Color(0.86, 0.92, 1.0)}, "c1": Color(0.6, 0.72, 0.9)},
	"kumo_kaval": {"name": "Kumo Kaval Koruyucusu", "slot": "kol", "price": 0, "rank": 1, "desc": "Beyaz kaval koruyucusu.", "stats": {"def": 2}, "look": {"guards": "bacak", "guard_stripes": Color(0.72, 0.1, 0.12), "knee_wraps": true}, "c1": Color(0.86, 0.84, 0.82)},
	"tam_koruma": {"name": "Tam Takım Koruyucu", "slot": "kol", "price": 520, "rank": 1, "desc": "Kolluk, eldiven ve kaval koruyucu bir arada.", "stats": {"def": 8, "melee": 0.05, "speed": -0.02}, "look": {"guards": "ikisi", "gloves": true}, "c1": Color(0.45, 0.47, 0.52)},
	# --- sırt / bel
	"kum_kabagi": {"name": "Kum Su Kabağı", "slot": "sirt", "price": 900, "rank": 2, "desc": "Sırtta taşınan dev kabak. Sabaku klanı kumunu içinde saklar.", "stats": {"def": 4, "chakra": 25}, "look": {"back_item": "kabak"}, "c1": Color(0.7, 0.5, 0.35)},
	"sake_kabagi": {"name": "Sake Kabağı", "slot": "sirt", "price": 60, "rank": 0, "desc": "Belde taşınan küçük kabak matara.", "stats": {"hp": 10}, "look": {"back_item": "sake"}, "c1": Color(0.75, 0.5, 0.25)},
	"dev_parsomen": {"name": "Dev Parşömen", "slot": "sirt", "price": 300, "rank": 1, "desc": "Sırtta taşınan çağırma parşömeni. Chakra deposu.", "stats": {"chakra": 35}, "look": {"back_item": "parsomen"}, "c1": Color(0.85, 0.78, 0.6)},
	"sirt_shuriken": {"name": "Sırt Shurikeni", "slot": "sirt", "price": 350, "rank": 1, "desc": "Sırtta taşınan dev katlanır shuriken.", "stats": {"melee": 0.05, "def": 1}, "look": {"back_item": "shuriken"}, "c1": Color(0.45, 0.48, 0.52)},
	"kilic_kini": {"name": "Sırt Kılıç Kını", "slot": "sirt", "price": 120, "rank": 0, "desc": "Çapraz takılan kılıç kını.", "stats": {"melee": 0.03}, "look": {"back_item": "kin"}, "c1": Color(0.15, 0.12, 0.12)},
	"sirt_cantasi": {"name": "Sırt Çantası", "slot": "sirt", "price": 100, "rank": 0, "desc": "Uzun görevler için erzak çantası ve rulo yatak.", "stats": {"hp": 20}, "look": {"back_item": "canta"}, "c1": Color(0.4, 0.33, 0.22)},
	"aletli_kemer": {"name": "Alet Kemeri", "slot": "sirt", "price": 150, "rank": 0, "desc": "Belde dört alet cebi ve parşömen tutucu.", "stats": {"def": 1, "chakra": 10}, "look": {"back_item": "kemer"}, "c1": Color(0.3, 0.24, 0.16)},
	# ================================================================ genişletilmiş gardırop
	# --- kafa
	"hachimaki": {"name": "Hachimaki", "slot": "kafa", "price": 60, "rank": 0, "desc": "Alına sıkıca bağlanan, uçları ensede uçuşan kararlılık bandı.", "stats": {"melee": 0.03}, "look": {"head_style": "hachimaki"}, "c1": Color(0.95, 0.94, 0.9)},
	"hachimaki_kizil": {"name": "Kızıl Hachimaki", "slot": "kafa", "price": 90, "rank": 0, "desc": "Savaş yemini edenlerin kırmızı alın bandı.", "stats": {"melee": 0.04}, "look": {"head_style": "hachimaki"}, "c1": Color(0.78, 0.12, 0.12)},
	"haydut_bandana": {"name": "Haydut Bandanası", "slot": "kafa", "price": 50, "rank": 0, "desc": "Başa bağlanan, arkası düğümlü kaba bez.", "stats": {"def": 1, "speed": 0.01}, "look": {"head_style": "basortu"}, "c1": Color(0.55, 0.2, 0.15)},
	"col_sarigi": {"name": "Çöl Sarığı", "slot": "kafa", "price": 180, "rank": 0, "desc": "Kat kat sarılmış kum rengi sarık. Güneşten ve kum fırtınasından korur.", "stats": {"def": 2, "hp": 15}, "look": {"head_style": "sarik"}, "c1": Color(0.85, 0.76, 0.58)},
	"jingasa": {"name": "Jingasa", "slot": "kafa", "price": 240, "rank": 1, "desc": "Lake kaplı yassı asker şapkası; önünde pirinç arma.", "stats": {"def": 4}, "look": {"head_style": "jingasa"}, "c1": Color(0.16, 0.14, 0.14)},
	"kabuto": {"name": "Samuray Kabutosu", "slot": "kafa", "price": 1300, "rank": 3, "desc": "Katmanlı boyun korumalı, altın boynuz armalı savaş miğferi.", "stats": {"def": 10, "hp": 30, "speed": -0.03}, "look": {"head_style": "kabuto"}, "c1": Color(0.22, 0.2, 0.22)},
	"kabuto_kizil": {"name": "Kızıl Lake Kabuto", "slot": "kafa", "price": 1600, "rank": 3, "desc": "Komutanların kırmızı lake miğferi.", "stats": {"def": 11, "hp": 35, "speed": -0.03}, "look": {"head_style": "kabuto", "crest": "kuwagata"}, "c1": Color(0.55, 0.1, 0.1)},
	"tengai": {"name": "Tengai", "slot": "kafa", "price": 220, "rank": 0, "desc": "Yüzü tamamen örten derin hasır sepet şapka. Gezgin keşişlerin kimliği gizlidir.", "stats": {"def": 2, "chakra": 25}, "look": {"head_style": "tengai"}, "c1": Color(0.72, 0.6, 0.38)},
	"golge_kapuson": {"name": "Gölge Kapüşonu", "slot": "kafa", "price": 380, "rank": 1, "desc": "Koyu, derin kapüşon. Suikastçıların sevdiği.", "stats": {"def": 2, "speed": 0.04}, "look": {"head_style": "kapuson", "hood": "derin"}, "c1": Color(0.1, 0.1, 0.12)},
	"col_kapusonu": {"name": "Çöl Kapüşonu", "slot": "kafa", "price": 160, "rank": 0, "desc": "Kum rengi hafif kapüşon.", "stats": {"def": 2, "hp": 10}, "look": {"head_style": "kapuson", "hood": "hafif"}, "c1": Color(0.78, 0.68, 0.5)},
	"yirtik_kasa": {"name": "Yırtık Gezgin Kasası", "slot": "kafa", "price": 70, "rank": 0, "desc": "Kenarları yıpranmış eski hasır şapka. Ronin işi.", "stats": {"def": 1}, "look": {"head_style": "kasa"}, "c1": Color(0.48, 0.4, 0.28)},
	"cizik_alin": {"name": "Çizik Alın Koruyucu", "slot": "kafa", "price": 0, "rank": 1, "desc": "Köyüne sırt çevirenlerin sembolü üstünden çizilmiş plakası.", "stats": {"def": 2, "melee": 0.04}, "look": {"band_style": "slashed"}, "c1": Color(0.2, 0.2, 0.24)},
	# --- yüz
	"mempo": {"name": "Mempo", "slot": "yuz", "price": 700, "rank": 2, "desc": "Samurayların dişli, bıyıklı demir alt yüz zırhı.", "stats": {"def": 5, "hp": 20}, "look": {"face_style": "mempo"}, "c1": Color(0.2, 0.18, 0.2)},
	"mempo_kizil": {"name": "Kızıl Mempo", "slot": "yuz", "price": 900, "rank": 3, "desc": "Kırmızı lake, korkutucu yüz zırhı.", "stats": {"def": 6, "melee": 0.04}, "look": {"face_style": "mempo"}, "c1": Color(0.6, 0.1, 0.1)},
	"goz_bandi": {"name": "Göz Bandı", "slot": "yuz", "price": 40, "rank": 0, "desc": "Eski bir yaradan kalan siyah göz bandı.", "stats": {"melee": 0.02}, "look": {"face_style": "goz_bandi"}, "c1": Color(0.1, 0.1, 0.1)},
	"col_pecesi": {"name": "Çöl Peçesi", "slot": "yuz", "price": 110, "rank": 0, "desc": "Burun ve ağzı örten ince kumaş. Kum ve zehre karşı.", "stats": {"def": 1, "hp": 10}, "look": {"face_style": "pece"}, "c1": Color(0.82, 0.74, 0.58)},
	"kizil_maske": {"name": "Kızıl Bez Maske", "slot": "yuz", "price": 120, "rank": 0, "desc": "Yüzün alt yarısını saran kırmızı bez.", "stats": {"def": 1, "speed": 0.02}, "look": {"face_style": "cloth"}, "c1": Color(0.55, 0.1, 0.12)},
	"anbu_tilki": {"name": "ANBU Maskesi: Tilki", "slot": "yuz", "price": 900, "rank": 4, "desc": "Sivri burunlu tilki maskesi: kurnazlık.", "stats": {"def": 5, "chakra": 30}, "look": {"face_style": "anbu_tilki"}, "c1": Color(0.95, 0.95, 0.95)},
	"anbu_kaplan": {"name": "ANBU Maskesi: Kaplan", "slot": "yuz", "price": 900, "rank": 4, "desc": "Çizgili kaplan maskesi: saldırganlık.", "stats": {"def": 5, "melee": 0.08}, "look": {"face_style": "anbu_kaplan"}, "c1": Color(0.95, 0.95, 0.95)},
	"anbu_yilan": {"name": "ANBU Maskesi: Yılan", "slot": "yuz", "price": 900, "rank": 4, "desc": "Ortasından yeşil çizgi inen yılan maskesi: sinsilik.", "stats": {"def": 4, "speed": 0.06}, "look": {"face_style": "anbu_yilan"}, "c1": Color(0.95, 0.95, 0.95)},
	"anbu_maymun": {"name": "ANBU Maskesi: Maymun", "slot": "yuz", "price": 900, "rank": 4, "desc": "Kulaklı maymun maskesi: çeviklik.", "stats": {"def": 4, "speed": 0.05, "melee": 0.03}, "look": {"face_style": "anbu_maymun"}, "c1": Color(0.95, 0.95, 0.95)},
	"yuz_001": {"name": "ANBU Maskesi: Kurt", "slot": "yuz", "price": 120, "rank": 3, "desc": "ANBU Maskesi: Kurt — kimliğini gizler.", "stats": {"def": 2}, "look": {"face_style": "anbu_kurt"}, "c1": Color(0.95, 0.95, 0.92)},
	"yuz_002": {"name": "ANBU Maskesi: Baykuş", "slot": "yuz", "price": 145, "rank": 3, "desc": "ANBU Maskesi: Baykuş — kimliğini gizler.", "stats": {"chakra": 15}, "look": {"face_style": "anbu_baykus"}, "c1": Color(0.95, 0.95, 0.92)},
	"yuz_003": {"name": "ANBU Maskesi: Ayı", "slot": "yuz", "price": 170, "rank": 3, "desc": "ANBU Maskesi: Ayı — kimliğini gizler.", "stats": {"def": 1, "speed": 0.02}, "look": {"face_style": "anbu_ayi"}, "c1": Color(0.95, 0.95, 0.92)},
	"yuz_004": {"name": "ANBU Maskesi: Kartal", "slot": "yuz", "price": 195, "rank": 3, "desc": "ANBU Maskesi: Kartal — kimliğini gizler.", "stats": {"melee": 0.04}, "look": {"face_style": "anbu_kartal"}, "c1": Color(0.95, 0.95, 0.92)},
	"yuz_005": {"name": "ANBU Maskesi: Tavşan", "slot": "yuz", "price": 220, "rank": 3, "desc": "ANBU Maskesi: Tavşan — kimliğini gizler.", "stats": {"hp": 15}, "look": {"face_style": "anbu_tavsan"}, "c1": Color(0.95, 0.95, 0.92)},
	"yuz_006": {"name": "ANBU Maskesi: Geyik", "slot": "yuz", "price": 245, "rank": 3, "desc": "ANBU Maskesi: Geyik — kimliğini gizler.", "stats": {"def": 3}, "look": {"face_style": "anbu_geyik"}, "c1": Color(0.95, 0.95, 0.92)},
	"yuz_007": {"name": "ANBU Maskesi: Kaplumbağa", "slot": "yuz", "price": 270, "rank": 3, "desc": "ANBU Maskesi: Kaplumbağa — kimliğini gizler.", "stats": {"def": 2}, "look": {"face_style": "anbu_kaplumbaga"}, "c1": Color(0.95, 0.95, 0.92)},
	"yuz_008": {"name": "ANBU Maskesi: Yarasa", "slot": "yuz", "price": 295, "rank": 3, "desc": "ANBU Maskesi: Yarasa — kimliğini gizler.", "stats": {"chakra": 15}, "look": {"face_style": "anbu_yarasa"}, "c1": Color(0.95, 0.95, 0.92)},
	"yuz_009": {"name": "ANBU Maskesi: Kurbağa", "slot": "yuz", "price": 320, "rank": 3, "desc": "ANBU Maskesi: Kurbağa — kimliğini gizler.", "stats": {"def": 1, "speed": 0.02}, "look": {"face_style": "anbu_kurbaga"}, "c1": Color(0.95, 0.95, 0.92)},
	"yuz_010": {"name": "ANBU Maskesi: Ejder", "slot": "yuz", "price": 345, "rank": 3, "desc": "ANBU Maskesi: Ejder — kimliğini gizler.", "stats": {"melee": 0.04}, "look": {"face_style": "anbu_ejder"}, "c1": Color(0.95, 0.95, 0.92)},
	"yuz_011": {"name": "Oni Maskesi", "slot": "yuz", "price": 370, "rank": 0, "desc": "Oni Maskesi — kimliğini gizler.", "stats": {"hp": 15}, "look": {"face_style": "oni"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_012": {"name": "Hannya Maskesi", "slot": "yuz", "price": 395, "rank": 0, "desc": "Hannya Maskesi — kimliğini gizler.", "stats": {"def": 3}, "look": {"face_style": "hannya"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_013": {"name": "Tengu Maskesi", "slot": "yuz", "price": 420, "rank": 0, "desc": "Tengu Maskesi — kimliğini gizler.", "stats": {"def": 2}, "look": {"face_style": "tengu"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_014": {"name": "Festival Tilki Maskesi", "slot": "yuz", "price": 445, "rank": 0, "desc": "Festival Tilki Maskesi — kimliğini gizler.", "stats": {"chakra": 15}, "look": {"face_style": "kitsune_festival"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_015": {"name": "Okame Maskesi", "slot": "yuz", "price": 470, "rank": 0, "desc": "Okame Maskesi — kimliğini gizler.", "stats": {"def": 1, "speed": 0.02}, "look": {"face_style": "okame"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_016": {"name": "Kök Birliği Maskesi", "slot": "yuz", "price": 495, "rank": 0, "desc": "Kök Birliği Maskesi — kimliğini gizler.", "stats": {"melee": 0.04}, "look": {"face_style": "kok_maskesi"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_017": {"name": "Sarmal Maske", "slot": "yuz", "price": 520, "rank": 0, "desc": "Sarmal Maske — kimliğini gizler.", "stats": {"hp": 15}, "look": {"face_style": "spiral_maske"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_018": {"name": "Sis Avcı Ninja Maskesi", "slot": "yuz", "price": 545, "rank": 0, "desc": "Sis Avcı Ninja Maskesi — kimliğini gizler.", "stats": {"def": 3}, "look": {"face_style": "avci_maske"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_019": {"name": "Yağmur Gaz Maskesi", "slot": "yuz", "price": 570, "rank": 0, "desc": "Yağmur Gaz Maskesi — kimliğini gizler.", "stats": {"def": 2}, "look": {"face_style": "gaz_maskesi"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_020": {"name": "Samuray Solunum Maskesi", "slot": "yuz", "price": 595, "rank": 0, "desc": "Samuray Solunum Maskesi — kimliğini gizler.", "stats": {"chakra": 15}, "look": {"face_style": "solunum_maskesi"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_021": {"name": "Alt Yüz Bandajı", "slot": "yuz", "price": 620, "rank": 1, "desc": "Alt Yüz Bandajı — kimliğini gizler.", "stats": {"def": 1, "speed": 0.02}, "look": {"face_style": "bandaj_alt"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_022": {"name": "Tam Yüz Sargısı", "slot": "yuz", "price": 645, "rank": 1, "desc": "Tam Yüz Sargısı — kimliğini gizler.", "stats": {"melee": 0.04}, "look": {"face_style": "tam_bandaj"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_023": {"name": "Yuvarlak Koyu Gözlük", "slot": "yuz", "price": 670, "rank": 1, "desc": "Yuvarlak Koyu Gözlük — kimliğini gizler.", "stats": {"hp": 15}, "look": {"face_style": "yuvarlak_gozluk"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_024": {"name": "Turuncu Koruyucu Gözlük", "slot": "yuz", "price": 695, "rank": 1, "desc": "Turuncu Koruyucu Gözlük — kimliğini gizler.", "stats": {"def": 3}, "look": {"face_style": "koruyucu_gozluk"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_025": {"name": "Vizör Gözlük", "slot": "yuz", "price": 720, "rank": 1, "desc": "Vizör Gözlük — kimliğini gizler.", "stats": {"def": 2}, "look": {"face_style": "vizor"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_026": {"name": "Demir Yarım Maske", "slot": "yuz", "price": 745, "rank": 1, "desc": "Demir Yarım Maske — kimliğini gizler.", "stats": {"chakra": 15}, "look": {"face_style": "demir_yarim_maske"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_027": {"name": "Savaş Boyası", "slot": "yuz", "price": 770, "rank": 1, "desc": "Savaş Boyası — kimliğini gizler.", "stats": {"def": 1, "speed": 0.02}, "look": {"face_style": "savas_boyasi"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_028": {"name": "Yüksek Yakalı Peçe", "slot": "yuz", "price": 795, "rank": 1, "desc": "Yüksek Yakalı Peçe — kimliğini gizler.", "stats": {"melee": 0.04}, "look": {"face_style": "yuksek_pece"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_029": {"name": "Tek Mercek", "slot": "yuz", "price": 820, "rank": 1, "desc": "Tek Mercek — kimliğini gizler.", "stats": {"hp": 15}, "look": {"face_style": "tek_mercek"}, "c1": Color(0.20, 0.20, 0.24)},
	"yuz_030": {"name": "Kemik Kafatası Maske", "slot": "yuz", "price": 845, "rank": 1, "desc": "Kemik Kafatası Maske — kimliğini gizler.", "stats": {"def": 3}, "look": {"face_style": "kemik_maske"}, "c1": Color(0.20, 0.20, 0.24)},
	# --- üst
	"gi_beyaz": {"name": "Beyaz Dövüş Gi'si", "slot": "govde", "price": 160, "rank": 0, "desc": "Geniş V yakalı, dirsek boyu kollu taijutsu gi'si; siyah kuşaklı.", "stats": {"melee": 0.06}, "look": {"top_style": "gi"}, "c1": Color(0.94, 0.93, 0.9), "c2": Color(0.85, 0.84, 0.8)},
	"gi_siyah": {"name": "Siyah Dövüş Gi'si", "slot": "govde", "price": 200, "rank": 0, "desc": "Gece antrenmanlarının koyu gi'si.", "stats": {"melee": 0.07}, "look": {"top_style": "gi"}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.55, 0.1, 0.1)},
	"kesis_ustu": {"name": "Keşiş Üstü", "slot": "govde", "price": 140, "rank": 0, "desc": "Safran rengi, çapraz yakalı tapınak giysisi.", "stats": {"chakra": 25}, "look": {"top_style": "gi"}, "c1": Color(0.9, 0.55, 0.15), "c2": Color(0.7, 0.35, 0.1)},
	"arma_gomlek": {"name": "Armalı Yüksek Yakalı Gömlek", "slot": "govde", "price": 340, "rank": 1, "desc": "Uzun kollu, dik yakalı klan gömleği; sırtında yuvarlak klan arması.", "stats": {"def": 3, "chakra": 20}, "look": {"top_style": "yakali_uzun", "top_pattern": 5}, "c1": Color(0.12, 0.13, 0.2), "c2": Color(0.85, 0.15, 0.15)},
	"uchiha_yakali": {"name": "Uchiha Yüksek Yakalı", "slot": "govde", "price": 220, "rank": 0, "clan": "uchiha", "desc": "Kısa kollu, dik yakalı lacivert klan üstü; sırtında kırmızı-beyaz Uchiha yelpazesi.", "stats": {"def": 2, "chakra": 15}, "look": {"top_style": "yakali", "top_pattern": 7}, "c1": Color(0.1, 0.12, 0.22), "c2": Color(0.1, 0.12, 0.22)},
	"uchiha_uzun": {"name": "Uchiha Uzun Kollu", "slot": "govde", "price": 300, "rank": 1, "clan": "uchiha", "desc": "Uzun kollu, boynu saran dik yakalı siyah klan gömleği; sırtta yelpaze arması.", "stats": {"def": 3, "chakra": 25}, "look": {"top_style": "yakali_uzun", "top_pattern": 7}, "c1": Color(0.08, 0.08, 0.1), "c2": Color(0.08, 0.08, 0.1)},
	"uchiha_beyaz": {"name": "Uchiha Beyaz Yakalı", "slot": "govde", "price": 340, "rank": 1, "clan": "uchiha", "desc": "Açık yakalı beyaz klan üstü; sırtta büyük yelpaze.", "stats": {"def": 2, "chakra": 30}, "look": {"top_style": "kolsuz_yakali", "top_pattern": 7}, "c1": Color(0.94, 0.93, 0.9), "c2": Color(0.94, 0.93, 0.9)},
	"uchiha_polis": {"name": "Uchiha Muhafız Üniforması", "slot": "govde", "price": 520, "rank": 2, "clan": "uchiha", "desc": "Köy güvenlik birliğinin koyu gri-yeşil, yakalı üniforması; sırtta arma.", "stats": {"def": 6, "hp": 25}, "look": {"top_style": "yakali_uzun", "top_pattern": 7}, "c1": Color(0.2, 0.25, 0.24), "c2": Color(0.2, 0.25, 0.24)},
	"uchiha_kolluk": {"name": "Uchiha Kolluğu", "slot": "kol", "price": 120, "rank": 0, "clan": "uchiha", "desc": "Dirsekten bileğe uzanan koyu kol ısıtıcıları.", "stats": {"melee": 0.04, "throw_dmg": 0.04}, "look": {"arm_wraps": true, "gloves": false}, "c1": Color(0.1, 0.1, 0.14)},
	"uchiha_haori": {"name": "Uchiha Klan Haorisi", "slot": "dis", "price": 900, "rank": 2, "clan": "uchiha", "desc": "Klan büyüklerinin siyah uzun haorisi; eteği kızıl biyeli.", "stats": {"chakra": 40, "def": 4}, "look": {"outer_style": "haori_uzun", "outer_pattern": 1}, "c1": Color(0.08, 0.08, 0.1), "c2": Color(0.8, 0.1, 0.1)},
	"beyaz_arma": {"name": "Beyaz Klan Cübbe-Gömleği", "slot": "govde", "price": 360, "rank": 1, "desc": "Soluk lila-beyaz, kenarları biyeli soylu klan üstü.", "stats": {"def": 2, "chakra": 30}, "look": {"top_style": "yakali_uzun", "top_pattern": 6}, "c1": Color(0.92, 0.9, 0.95), "c2": Color(0.55, 0.5, 0.7)},
	"cizgili_tisort": {"name": "Çizgili Tişört", "slot": "govde", "price": 60, "rank": 0, "desc": "Enine çizgili rahat tişört.", "stats": {"speed": 0.03}, "look": {"top_style": "tisort", "top_pattern": 2}, "c1": Color(0.85, 0.85, 0.82), "c2": Color(0.2, 0.3, 0.55)},
	"denizci_ust": {"name": "Çizgili Uzun Kollu", "slot": "govde", "price": 110, "rank": 0, "desc": "Liman köylerinin çizgili gömleği.", "stats": {"def": 1, "hp": 10}, "look": {"top_style": "uzun", "top_pattern": 2}, "c1": Color(0.9, 0.9, 0.88), "c2": Color(0.15, 0.25, 0.45)},
	"panel_ceket": {"name": "Yan Panelli Eğitim Ceketi", "slot": "govde", "price": 260, "rank": 0, "desc": "Yanlarından ve kollarından şerit geçen fermuarlı ceket.", "stats": {"def": 3, "speed": 0.03}, "look": {"top_style": "ceket", "top_pattern": 3}, "c1": Color(0.2, 0.35, 0.6), "c2": Color(0.95, 0.75, 0.2)},
	"kizil_ceket": {"name": "Kızıl Dövüş Ceketi", "slot": "govde", "price": 260, "rank": 0, "desc": "Kırmızı gövde, siyah omuzlu yüksek yakalı ceket.", "stats": {"def": 3, "melee": 0.04}, "look": {"top_style": "ceket", "top_pattern": 3}, "c1": Color(0.7, 0.12, 0.12), "c2": Color(0.1, 0.1, 0.12)},
	"atlet": {"name": "Atlet", "slot": "govde", "price": 30, "rank": 0, "desc": "Askılı, kolları ve omuzları açık atlet.", "stats": {"speed": 0.04}, "look": {"top_style": "atlet"}, "c1": Color(0.9, 0.9, 0.88), "c2": Color(0.9, 0.9, 0.88)},
	"tek_kol_ust": {"name": "Tek Kollu Savaş Üstü", "slot": "govde", "price": 230, "rank": 1, "desc": "Bir kolu açık, asimetrik kesim. Bulut köyü tarzı.", "stats": {"melee": 0.06, "speed": 0.02}, "look": {"top_style": "tek_kol"}, "c1": Color(0.22, 0.24, 0.28), "c2": Color(0.22, 0.24, 0.28)},
	"yamali_gomlek": {"name": "Yamalı Gömlek", "slot": "govde", "price": 20, "rank": 0, "desc": "Yamalarla tutturulmuş, eskimiş gömlek.", "stats": {"hp": 5}, "look": {"top_style": "uzun", "top_pattern": 4}, "c1": Color(0.48, 0.38, 0.28), "c2": Color(0.48, 0.38, 0.28)},
	"yamali_kolsuz": {"name": "Yırtık Kolsuz Üst", "slot": "govde", "price": 20, "rank": 0, "desc": "Kolları kopmuş, yamalı kaba üst.", "stats": {"melee": 0.03}, "look": {"top_style": "kolsuz", "top_pattern": 4}, "c1": Color(0.4, 0.34, 0.26), "c2": Color(0.4, 0.34, 0.26)},
	"file_kolsuz": {"name": "File Kolsuz", "slot": "govde", "price": 140, "rank": 0, "desc": "Ağ örgü kolsuz fanila.", "stats": {"def": 2, "speed": 0.03}, "look": {"top_style": "kolsuz", "top_pattern": 1}, "c1": Color(0.15, 0.15, 0.17), "c2": Color(0.15, 0.15, 0.17)},
	"biyeli_kimono": {"name": "Biyeli Kimono", "slot": "govde", "price": 420, "rank": 1, "desc": "Etek ve kol ağızları kontrast biyeli soylu kimono.", "stats": {"chakra": 35}, "look": {"top_style": "kimono", "top_pattern": 6}, "c1": Color(0.2, 0.22, 0.35), "c2": Color(0.85, 0.75, 0.45)},
	"yukata": {"name": "Çizgili Yukata", "slot": "govde", "price": 160, "rank": 0, "desc": "Hafif yazlık kimono. Festival akşamları için.", "stats": {"hp": 10}, "look": {"top_style": "kimono", "top_pattern": 2}, "c1": Color(0.9, 0.88, 0.82), "c2": Color(0.25, 0.35, 0.6)},
	"tunik": {"name": "Biyeli Tunik", "slot": "govde", "price": 150, "rank": 0, "desc": "Uzun kollu, kenarları biyeli gezgin tuniği.", "stats": {"def": 1, "chakra": 10}, "look": {"top_style": "uzun", "top_pattern": 6}, "c1": Color(0.45, 0.32, 0.22), "c2": Color(0.75, 0.6, 0.35)},
	"deri_ceket": {"name": "Deri Ceket", "slot": "govde", "price": 280, "rank": 1, "desc": "Kalın deri, yüksek yakalı paralı asker ceketi.", "stats": {"def": 5, "speed": -0.01}, "look": {"top_style": "ceket"}, "c1": Color(0.38, 0.25, 0.15), "c2": Color(0.22, 0.15, 0.1)},
	"golge_ust": {"name": "Gölge Ninja Üstü", "slot": "govde", "price": 320, "rank": 2, "desc": "Uzun kollu, yüksek yakalı simsiyah üst. Gece görevleri için.", "stats": {"def": 2, "speed": 0.05}, "look": {"top_style": "yakali_uzun"}, "c1": Color(0.08, 0.08, 0.1), "c2": Color(0.08, 0.08, 0.1)},
	"ust_001": {"name": "Siyah Kuşaklı Tişört", "slot": "govde", "price": 80, "rank": 0, "desc": "Kuşaklı tişört; lacivert vurgulu.", "stats": {"def": 2}, "look": {"top_style": "tisort", "top_pattern": 8}, "c1": Color(0.10, 0.10, 0.12), "c2": Color(0.12, 0.16, 0.34)},
	"ust_002": {"name": "Gri İnce Çizgili Yakalı Gömlek", "slot": "govde", "price": 86, "rank": 0, "desc": "İnce Çizgili yakalı gömlek; kahve vurgulu.", "stats": {"speed": 0.03}, "look": {"top_style": "yakali", "top_pattern": 9}, "c1": Color(0.45, 0.45, 0.48), "c2": Color(0.42, 0.28, 0.18)},
	"ust_003": {"name": "Turkuaz Damalı Gi", "slot": "govde", "price": 92, "rank": 0, "desc": "Damalı gi; pembe vurgulu.", "stats": {"chakra": 15}, "look": {"top_style": "gi", "top_pattern": 10}, "c1": Color(0.20, 0.70, 0.70), "c2": Color(0.92, 0.55, 0.65)},
	"ust_004": {"name": "Yeşil İki Renkli Tek Kollu Üst", "slot": "govde", "price": 98, "rank": 0, "desc": "İki Renkli tek kollu üst; kızıl vurgulu.", "stats": {"melee": 0.05}, "look": {"top_style": "tek_kol", "top_pattern": 11}, "c1": Color(0.20, 0.45, 0.25), "c2": Color(0.72, 0.12, 0.12)},
	"ust_005": {"name": "Zeytin Göğüs Bantlı Ceket", "slot": "govde", "price": 104, "rank": 0, "desc": "Göğüs Bantlı ceket; gri vurgulu.", "stats": {"hp": 15}, "look": {"top_style": "ceket", "top_pattern": 12}, "c1": Color(0.40, 0.42, 0.22), "c2": Color(0.45, 0.45, 0.48)},
	"ust_006": {"name": "Lacivert Puantiyeli Kimono", "slot": "govde", "price": 110, "rank": 0, "desc": "Puantiyeli kimono; zeytin vurgulu.", "stats": {"def": 3, "speed": 0.02}, "look": {"top_style": "kimono", "top_pattern": 13}, "c1": Color(0.12, 0.16, 0.34), "c2": Color(0.40, 0.42, 0.22)},
	"ust_007": {"name": "Altın Zikzak Etekli Atlet", "slot": "govde", "price": 116, "rank": 0, "desc": "Zikzak Etekli atlet; beyaz vurgulu.", "stats": {"chakra": 20, "def": 1}, "look": {"top_style": "atlet", "top_pattern": 14}, "c1": Color(0.85, 0.68, 0.25), "c2": Color(0.92, 0.92, 0.90)},
	"ust_008": {"name": "Beyaz Alev Etekli Uzun Kollu Gömlek", "slot": "govde", "price": 122, "rank": 0, "desc": "Alev Etekli uzun kollu gömlek; mor vurgulu.", "stats": {"melee": 0.04, "hp": 10}, "look": {"top_style": "uzun", "top_pattern": 15}, "c1": Color(0.92, 0.92, 0.90), "c2": Color(0.40, 0.22, 0.55)},
	"ust_009": {"name": "Kahve Bulutlu Kolsuz Üst", "slot": "govde", "price": 128, "rank": 0, "desc": "Bulutlu kolsuz üst; bordo vurgulu.", "stats": {"speed": 0.04}, "look": {"top_style": "kolsuz", "top_pattern": 16}, "c1": Color(0.42, 0.28, 0.18), "c2": Color(0.45, 0.08, 0.12)},
	"ust_010": {"name": "Kömür Sembollü Uzun Yakalı", "slot": "govde", "price": 134, "rank": 0, "desc": "Sembollü uzun yakalı; siyah vurgulu.", "stats": {"def": 4}, "look": {"top_style": "yakali_uzun", "top_pattern": 17}, "c1": Color(0.20, 0.20, 0.22), "c2": Color(0.10, 0.10, 0.12)},
	"ust_011": {"name": "Pembe Kamuflaj Yakalı Gömlek", "slot": "govde", "price": 140, "rank": 0, "desc": "Kamuflaj yakalı gömlek; bordo vurgulu.", "stats": {"def": 2}, "look": {"top_style": "yakali", "top_pattern": 19}, "c1": Color(0.92, 0.55, 0.65), "c2": Color(0.45, 0.08, 0.12)},
	"ust_012": {"name": "Turuncu Baklava Desenli Gi", "slot": "govde", "price": 146, "rank": 0, "desc": "Baklava Desenli gi; siyah vurgulu.", "stats": {"speed": 0.03}, "look": {"top_style": "gi", "top_pattern": 20}, "c1": Color(0.95, 0.50, 0.12), "c2": Color(0.10, 0.10, 0.12)},
	"ust_013": {"name": "Bordo Kontrast Yakalı Tek Kollu Üst", "slot": "govde", "price": 152, "rank": 0, "desc": "Kontrast Yakalı tek kollu üst; yeşil vurgulu.", "stats": {"chakra": 15}, "look": {"top_style": "tek_kol", "top_pattern": 21}, "c1": Color(0.45, 0.08, 0.12), "c2": Color(0.20, 0.45, 0.25)},
	"ust_014": {"name": "Kızıl Renk Geçişli Ceket", "slot": "govde", "price": 158, "rank": 0, "desc": "Renk Geçişli ceket; altın vurgulu.", "stats": {"melee": 0.05}, "look": {"top_style": "ceket", "top_pattern": 22}, "c1": Color(0.72, 0.12, 0.12), "c2": Color(0.85, 0.68, 0.25)},
	"ust_015": {"name": "Gök Mavisi Çapraz Kayışlı Kimono", "slot": "govde", "price": 164, "rank": 0, "desc": "Çapraz Kayışlı kimono; kömür vurgulu.", "stats": {"hp": 15}, "look": {"top_style": "kimono", "top_pattern": 23}, "c1": Color(0.35, 0.60, 0.90), "c2": Color(0.20, 0.20, 0.22)},
	"ust_016": {"name": "Beyaz Kol Şeritli Atlet", "slot": "govde", "price": 170, "rank": 0, "desc": "Kol Şeritli atlet; turuncu vurgulu.", "stats": {"def": 3, "speed": 0.02}, "look": {"top_style": "atlet", "top_pattern": 24}, "c1": Color(0.92, 0.92, 0.90), "c2": Color(0.95, 0.50, 0.12)},
	"ust_017": {"name": "Kahve Shuriken Armalı Uzun Kollu Gömlek", "slot": "govde", "price": 176, "rank": 0, "desc": "Shuriken Armalı uzun kollu gömlek; gök mavisi vurgulu.", "stats": {"chakra": 20, "def": 1}, "look": {"top_style": "uzun", "top_pattern": 25}, "c1": Color(0.42, 0.28, 0.18), "c2": Color(0.35, 0.60, 0.90)},
	"ust_018": {"name": "Kömür Yaprak Armalı Kolsuz Üst", "slot": "govde", "price": 182, "rank": 0, "desc": "Yaprak Armalı kolsuz üst; turkuaz vurgulu.", "stats": {"melee": 0.04, "hp": 10}, "look": {"top_style": "kolsuz", "top_pattern": 26}, "c1": Color(0.20, 0.20, 0.22), "c2": Color(0.20, 0.70, 0.70)},
	"ust_019": {"name": "Mor Dalga Desenli Uzun Yakalı", "slot": "govde", "price": 188, "rank": 0, "desc": "Dalga Desenli uzun yakalı; lacivert vurgulu.", "stats": {"speed": 0.04}, "look": {"top_style": "yakali_uzun", "top_pattern": 27}, "c1": Color(0.40, 0.22, 0.55), "c2": Color(0.12, 0.16, 0.34)},
	"ust_020": {"name": "Pembe Kuşaklı Uzun Kollu Gömlek", "slot": "govde", "price": 194, "rank": 0, "desc": "Kuşaklı uzun kollu gömlek; gök mavisi vurgulu.", "stats": {"def": 4}, "look": {"top_style": "uzun", "top_pattern": 8}, "c1": Color(0.92, 0.55, 0.65), "c2": Color(0.35, 0.60, 0.90)},
	"ust_021": {"name": "Turuncu İnce Çizgili Kolsuz Üst", "slot": "govde", "price": 200, "rank": 0, "desc": "İnce Çizgili kolsuz üst; turkuaz vurgulu.", "stats": {"def": 2}, "look": {"top_style": "kolsuz", "top_pattern": 9}, "c1": Color(0.95, 0.50, 0.12), "c2": Color(0.20, 0.70, 0.70)},
	"ust_022": {"name": "Bordo Damalı Uzun Yakalı", "slot": "govde", "price": 206, "rank": 0, "desc": "Damalı uzun yakalı; lacivert vurgulu.", "stats": {"speed": 0.03}, "look": {"top_style": "yakali_uzun", "top_pattern": 10}, "c1": Color(0.45, 0.08, 0.12), "c2": Color(0.12, 0.16, 0.34)},
	"ust_023": {"name": "Kızıl İki Renkli Tişört", "slot": "govde", "price": 212, "rank": 0, "desc": "İki Renkli tişört; kahve vurgulu.", "stats": {"chakra": 15}, "look": {"top_style": "tisort", "top_pattern": 11}, "c1": Color(0.72, 0.12, 0.12), "c2": Color(0.42, 0.28, 0.18)},
	"ust_024": {"name": "Gök Mavisi Göğüs Bantlı Yakalı Gömlek", "slot": "govde", "price": 218, "rank": 0, "desc": "Göğüs Bantlı yakalı gömlek; pembe vurgulu.", "stats": {"melee": 0.05}, "look": {"top_style": "yakali", "top_pattern": 12}, "c1": Color(0.35, 0.60, 0.90), "c2": Color(0.92, 0.55, 0.65)},
	"ust_025": {"name": "Siyah Puantiyeli Gi", "slot": "govde", "price": 224, "rank": 0, "desc": "Puantiyeli gi; kızıl vurgulu.", "stats": {"hp": 15}, "look": {"top_style": "gi", "top_pattern": 13}, "c1": Color(0.10, 0.10, 0.12), "c2": Color(0.72, 0.12, 0.12)},
	"ust_026": {"name": "Turkuaz Alev Etekli Ceket", "slot": "govde", "price": 230, "rank": 0, "desc": "Alev Etekli ceket; zeytin vurgulu.", "stats": {"def": 3, "speed": 0.02}, "look": {"top_style": "ceket", "top_pattern": 15}, "c1": Color(0.20, 0.70, 0.70), "c2": Color(0.40, 0.42, 0.22)},
	"ust_027": {"name": "Yeşil Bulutlu Kimono", "slot": "govde", "price": 236, "rank": 0, "desc": "Bulutlu kimono; beyaz vurgulu.", "stats": {"chakra": 20, "def": 1}, "look": {"top_style": "kimono", "top_pattern": 16}, "c1": Color(0.20, 0.45, 0.25), "c2": Color(0.92, 0.92, 0.90)},
	"ust_028": {"name": "Zeytin Sembollü Atlet", "slot": "govde", "price": 242, "rank": 0, "desc": "Sembollü atlet; mor vurgulu.", "stats": {"melee": 0.04, "hp": 10}, "look": {"top_style": "atlet", "top_pattern": 17}, "c1": Color(0.40, 0.42, 0.22), "c2": Color(0.40, 0.22, 0.55)},
	"ust_029": {"name": "Lacivert Girdaplı Uzun Kollu Gömlek", "slot": "govde", "price": 248, "rank": 0, "desc": "Girdaplı uzun kollu gömlek; zeytin vurgulu.", "stats": {"speed": 0.04}, "look": {"top_style": "uzun", "top_pattern": 18}, "c1": Color(0.12, 0.16, 0.34), "c2": Color(0.40, 0.42, 0.22)},
	"ust_030": {"name": "Altın Kamuflaj Kolsuz Üst", "slot": "govde", "price": 254, "rank": 0, "desc": "Kamuflaj kolsuz üst; beyaz vurgulu.", "stats": {"def": 4}, "look": {"top_style": "kolsuz", "top_pattern": 19}, "c1": Color(0.85, 0.68, 0.25), "c2": Color(0.92, 0.92, 0.90)},
	"ust_031": {"name": "Kızıl Baklava Desenli Uzun Yakalı", "slot": "govde", "price": 260, "rank": 0, "desc": "Baklava Desenli uzun yakalı; mor vurgulu.", "stats": {"def": 2}, "look": {"top_style": "yakali_uzun", "top_pattern": 20}, "c1": Color(0.72, 0.12, 0.12), "c2": Color(0.40, 0.22, 0.55)},
	"ust_032": {"name": "Gök Mavisi Kontrast Yakalı Tişört", "slot": "govde", "price": 266, "rank": 0, "desc": "Kontrast Yakalı tişört; bordo vurgulu.", "stats": {"speed": 0.03}, "look": {"top_style": "tisort", "top_pattern": 21}, "c1": Color(0.35, 0.60, 0.90), "c2": Color(0.45, 0.08, 0.12)},
	"ust_033": {"name": "Gri Çapraz Kayışlı Gi", "slot": "govde", "price": 272, "rank": 0, "desc": "Çapraz Kayışlı gi; yeşil vurgulu.", "stats": {"chakra": 15}, "look": {"top_style": "gi", "top_pattern": 23}, "c1": Color(0.45, 0.45, 0.48), "c2": Color(0.20, 0.45, 0.25)},
	"ust_034": {"name": "Turkuaz Kol Şeritli Tek Kollu Üst", "slot": "govde", "price": 278, "rank": 0, "desc": "Kol Şeritli tek kollu üst; altın vurgulu.", "stats": {"melee": 0.05}, "look": {"top_style": "tek_kol", "top_pattern": 24}, "c1": Color(0.20, 0.70, 0.70), "c2": Color(0.85, 0.68, 0.25)},
	"ust_035": {"name": "Yeşil Shuriken Armalı Ceket", "slot": "govde", "price": 284, "rank": 0, "desc": "Shuriken Armalı ceket; kömür vurgulu.", "stats": {"hp": 15}, "look": {"top_style": "ceket", "top_pattern": 25}, "c1": Color(0.20, 0.45, 0.25), "c2": Color(0.20, 0.20, 0.22)},
	"ust_036": {"name": "Zeytin Yaprak Armalı Kimono", "slot": "govde", "price": 290, "rank": 0, "desc": "Yaprak Armalı kimono; turuncu vurgulu.", "stats": {"def": 3, "speed": 0.02}, "look": {"top_style": "kimono", "top_pattern": 26}, "c1": Color(0.40, 0.42, 0.22), "c2": Color(0.95, 0.50, 0.12)},
	"ust_037": {"name": "Lacivert Dalga Desenli Atlet", "slot": "govde", "price": 296, "rank": 0, "desc": "Dalga Desenli atlet; gök mavisi vurgulu.", "stats": {"chakra": 20, "def": 1}, "look": {"top_style": "atlet", "top_pattern": 27}, "c1": Color(0.12, 0.16, 0.34), "c2": Color(0.35, 0.60, 0.90)},
	"ust_038": {"name": "Altın Kuşaklı Ceket", "slot": "govde", "price": 302, "rank": 0, "desc": "Kuşaklı ceket; kömür vurgulu.", "stats": {"melee": 0.04, "hp": 10}, "look": {"top_style": "ceket", "top_pattern": 8}, "c1": Color(0.85, 0.68, 0.25), "c2": Color(0.20, 0.20, 0.22)},
	"ust_039": {"name": "Beyaz İnce Çizgili Kimono", "slot": "govde", "price": 308, "rank": 0, "desc": "İnce Çizgili kimono; turuncu vurgulu.", "stats": {"speed": 0.04}, "look": {"top_style": "kimono", "top_pattern": 9}, "c1": Color(0.92, 0.92, 0.90), "c2": Color(0.95, 0.50, 0.12)},
	"ust_040": {"name": "Kahve Damalı Atlet", "slot": "govde", "price": 314, "rank": 0, "desc": "Damalı atlet; gök mavisi vurgulu.", "stats": {"def": 4}, "look": {"top_style": "atlet", "top_pattern": 10}, "c1": Color(0.42, 0.28, 0.18), "c2": Color(0.35, 0.60, 0.90)},
	"ust_041": {"name": "Kömür İki Renkli Uzun Kollu Gömlek", "slot": "govde", "price": 320, "rank": 0, "desc": "İki Renkli uzun kollu gömlek; turkuaz vurgulu.", "stats": {"def": 2}, "look": {"top_style": "uzun", "top_pattern": 11}, "c1": Color(0.20, 0.20, 0.22), "c2": Color(0.20, 0.70, 0.70)},
	"ust_042": {"name": "Mor Göğüs Bantlı Kolsuz Üst", "slot": "govde", "price": 326, "rank": 0, "desc": "Göğüs Bantlı kolsuz üst; lacivert vurgulu.", "stats": {"speed": 0.03}, "look": {"top_style": "kolsuz", "top_pattern": 12}, "c1": Color(0.40, 0.22, 0.55), "c2": Color(0.12, 0.16, 0.34)},
	"ust_043": {"name": "Pembe Puantiyeli Uzun Yakalı", "slot": "govde", "price": 332, "rank": 0, "desc": "Puantiyeli uzun yakalı; kahve vurgulu.", "stats": {"chakra": 15}, "look": {"top_style": "yakali_uzun", "top_pattern": 13}, "c1": Color(0.92, 0.55, 0.65), "c2": Color(0.42, 0.28, 0.18)},
	"ust_044": {"name": "Turuncu Zikzak Etekli Tişört", "slot": "govde", "price": 338, "rank": 0, "desc": "Zikzak Etekli tişört; pembe vurgulu.", "stats": {"melee": 0.05}, "look": {"top_style": "tisort", "top_pattern": 14}, "c1": Color(0.95, 0.50, 0.12), "c2": Color(0.92, 0.55, 0.65)},
	"ust_045": {"name": "Bordo Alev Etekli Yakalı Gömlek", "slot": "govde", "price": 344, "rank": 0, "desc": "Alev Etekli yakalı gömlek; kızıl vurgulu.", "stats": {"hp": 15}, "look": {"top_style": "yakali", "top_pattern": 15}, "c1": Color(0.45, 0.08, 0.12), "c2": Color(0.72, 0.12, 0.12)},
	"ust_046": {"name": "Lacivert Bulutlu Gi", "slot": "govde", "price": 470, "rank": 1, "desc": "Bulutlu gi; gri vurgulu.", "stats": {"def": 3, "speed": 0.02}, "look": {"top_style": "gi", "top_pattern": 16}, "c1": Color(0.12, 0.16, 0.34), "c2": Color(0.45, 0.45, 0.48)},
	"ust_047": {"name": "Altın Sembollü Tek Kollu Üst", "slot": "govde", "price": 476, "rank": 1, "desc": "Sembollü tek kollu üst; zeytin vurgulu.", "stats": {"chakra": 20, "def": 1}, "look": {"top_style": "tek_kol", "top_pattern": 17}, "c1": Color(0.85, 0.68, 0.25), "c2": Color(0.40, 0.42, 0.22)},
	"ust_048": {"name": "Beyaz Girdaplı Ceket", "slot": "govde", "price": 482, "rank": 1, "desc": "Girdaplı ceket; kızıl vurgulu.", "stats": {"melee": 0.04, "hp": 10}, "look": {"top_style": "ceket", "top_pattern": 18}, "c1": Color(0.92, 0.92, 0.90), "c2": Color(0.72, 0.12, 0.12)},
	"ust_049": {"name": "Kahve Kamuflaj Kimono", "slot": "govde", "price": 488, "rank": 1, "desc": "Kamuflaj kimono; gri vurgulu.", "stats": {"speed": 0.04}, "look": {"top_style": "kimono", "top_pattern": 19}, "c1": Color(0.42, 0.28, 0.18), "c2": Color(0.45, 0.45, 0.48)},
	"ust_050": {"name": "Kömür Baklava Desenli Atlet", "slot": "govde", "price": 494, "rank": 1, "desc": "Baklava Desenli atlet; zeytin vurgulu.", "stats": {"def": 4}, "look": {"top_style": "atlet", "top_pattern": 20}, "c1": Color(0.20, 0.20, 0.22), "c2": Color(0.40, 0.42, 0.22)},
	"ust_051": {"name": "Mor Kontrast Yakalı Uzun Kollu Gömlek", "slot": "govde", "price": 500, "rank": 1, "desc": "Kontrast Yakalı uzun kollu gömlek; beyaz vurgulu.", "stats": {"def": 2}, "look": {"top_style": "uzun", "top_pattern": 21}, "c1": Color(0.40, 0.22, 0.55), "c2": Color(0.92, 0.92, 0.90)},
	"ust_052": {"name": "Pembe Renk Geçişli Kolsuz Üst", "slot": "govde", "price": 506, "rank": 1, "desc": "Renk Geçişli kolsuz üst; mor vurgulu.", "stats": {"speed": 0.03}, "look": {"top_style": "kolsuz", "top_pattern": 22}, "c1": Color(0.92, 0.55, 0.65), "c2": Color(0.40, 0.22, 0.55)},
	"ust_053": {"name": "Turuncu Çapraz Kayışlı Uzun Yakalı", "slot": "govde", "price": 512, "rank": 1, "desc": "Çapraz Kayışlı uzun yakalı; bordo vurgulu.", "stats": {"chakra": 15}, "look": {"top_style": "yakali_uzun", "top_pattern": 23}, "c1": Color(0.95, 0.50, 0.12), "c2": Color(0.45, 0.08, 0.12)},
	"ust_054": {"name": "Bordo Kol Şeritli Tişört", "slot": "govde", "price": 518, "rank": 1, "desc": "Kol Şeritli tişört; siyah vurgulu.", "stats": {"melee": 0.05}, "look": {"top_style": "tisort", "top_pattern": 24}, "c1": Color(0.45, 0.08, 0.12), "c2": Color(0.10, 0.10, 0.12)},
	"ust_055": {"name": "Kızıl Shuriken Armalı Yakalı Gömlek", "slot": "govde", "price": 524, "rank": 1, "desc": "Shuriken Armalı yakalı gömlek; yeşil vurgulu.", "stats": {"hp": 15}, "look": {"top_style": "yakali", "top_pattern": 25}, "c1": Color(0.72, 0.12, 0.12), "c2": Color(0.20, 0.45, 0.25)},
	"ust_056": {"name": "Gök Mavisi Yaprak Armalı Gi", "slot": "govde", "price": 530, "rank": 1, "desc": "Yaprak Armalı gi; altın vurgulu.", "stats": {"def": 3, "speed": 0.02}, "look": {"top_style": "gi", "top_pattern": 26}, "c1": Color(0.35, 0.60, 0.90), "c2": Color(0.85, 0.68, 0.25)},
	"ust_057": {"name": "Siyah Dalga Desenli Tek Kollu Üst", "slot": "govde", "price": 536, "rank": 1, "desc": "Dalga Desenli tek kollu üst; kömür vurgulu.", "stats": {"chakra": 20, "def": 1}, "look": {"top_style": "tek_kol", "top_pattern": 27}, "c1": Color(0.10, 0.10, 0.12), "c2": Color(0.20, 0.20, 0.22)},
	"ust_058": {"name": "Gri Kuşaklı Yakalı Gömlek", "slot": "govde", "price": 542, "rank": 1, "desc": "Kuşaklı yakalı gömlek; yeşil vurgulu.", "stats": {"melee": 0.04, "hp": 10}, "look": {"top_style": "yakali", "top_pattern": 8}, "c1": Color(0.45, 0.45, 0.48), "c2": Color(0.20, 0.45, 0.25)},
	"ust_059": {"name": "Turkuaz İnce Çizgili Gi", "slot": "govde", "price": 548, "rank": 1, "desc": "İnce Çizgili gi; altın vurgulu.", "stats": {"speed": 0.04}, "look": {"top_style": "gi", "top_pattern": 9}, "c1": Color(0.20, 0.70, 0.70), "c2": Color(0.85, 0.68, 0.25)},
	"ust_060": {"name": "Yeşil Damalı Tek Kollu Üst", "slot": "govde", "price": 554, "rank": 1, "desc": "Damalı tek kollu üst; kömür vurgulu.", "stats": {"def": 4}, "look": {"top_style": "tek_kol", "top_pattern": 10}, "c1": Color(0.20, 0.45, 0.25), "c2": Color(0.20, 0.20, 0.22)},
	"ust_061": {"name": "Zeytin İki Renkli Ceket", "slot": "govde", "price": 560, "rank": 1, "desc": "İki Renkli ceket; turuncu vurgulu.", "stats": {"def": 2}, "look": {"top_style": "ceket", "top_pattern": 11}, "c1": Color(0.40, 0.42, 0.22), "c2": Color(0.95, 0.50, 0.12)},
	"ust_062": {"name": "Turuncu Göğüs Bantlı Kimono", "slot": "govde", "price": 566, "rank": 1, "desc": "Göğüs Bantlı kimono; gök mavisi vurgulu.", "stats": {"speed": 0.03}, "look": {"top_style": "kimono", "top_pattern": 12}, "c1": Color(0.95, 0.50, 0.12), "c2": Color(0.35, 0.60, 0.90)},
	"ust_063": {"name": "Bordo Puantiyeli Atlet", "slot": "govde", "price": 572, "rank": 1, "desc": "Puantiyeli atlet; turkuaz vurgulu.", "stats": {"chakra": 15}, "look": {"top_style": "atlet", "top_pattern": 13}, "c1": Color(0.45, 0.08, 0.12), "c2": Color(0.20, 0.70, 0.70)},
	"ust_064": {"name": "Kızıl Zikzak Etekli Uzun Kollu Gömlek", "slot": "govde", "price": 578, "rank": 1, "desc": "Zikzak Etekli uzun kollu gömlek; lacivert vurgulu.", "stats": {"melee": 0.05}, "look": {"top_style": "uzun", "top_pattern": 14}, "c1": Color(0.72, 0.12, 0.12), "c2": Color(0.12, 0.16, 0.34)},
	"ust_065": {"name": "Gök Mavisi Alev Etekli Kolsuz Üst", "slot": "govde", "price": 584, "rank": 1, "desc": "Alev Etekli kolsuz üst; kahve vurgulu.", "stats": {"hp": 15}, "look": {"top_style": "kolsuz", "top_pattern": 15}, "c1": Color(0.35, 0.60, 0.90), "c2": Color(0.42, 0.28, 0.18)},
	"ust_066": {"name": "Siyah Bulutlu Uzun Yakalı", "slot": "govde", "price": 590, "rank": 1, "desc": "Bulutlu uzun yakalı; pembe vurgulu.", "stats": {"def": 3, "speed": 0.02}, "look": {"top_style": "yakali_uzun", "top_pattern": 16}, "c1": Color(0.10, 0.10, 0.12), "c2": Color(0.92, 0.55, 0.65)},
	"ust_067": {"name": "Gri Sembollü Tişört", "slot": "govde", "price": 596, "rank": 1, "desc": "Sembollü tişört; kızıl vurgulu.", "stats": {"chakra": 20, "def": 1}, "look": {"top_style": "tisort", "top_pattern": 17}, "c1": Color(0.45, 0.45, 0.48), "c2": Color(0.72, 0.12, 0.12)},
	"ust_068": {"name": "Turkuaz Girdaplı Yakalı Gömlek", "slot": "govde", "price": 602, "rank": 1, "desc": "Girdaplı yakalı gömlek; kahve vurgulu.", "stats": {"melee": 0.04, "hp": 10}, "look": {"top_style": "yakali", "top_pattern": 18}, "c1": Color(0.20, 0.70, 0.70), "c2": Color(0.42, 0.28, 0.18)},
	"ust_069": {"name": "Yeşil Kamuflaj Gi", "slot": "govde", "price": 608, "rank": 1, "desc": "Kamuflaj gi; pembe vurgulu.", "stats": {"speed": 0.04}, "look": {"top_style": "gi", "top_pattern": 19}, "c1": Color(0.20, 0.45, 0.25), "c2": Color(0.92, 0.55, 0.65)},
	"ust_070": {"name": "Zeytin Baklava Desenli Tek Kollu Üst", "slot": "govde", "price": 614, "rank": 1, "desc": "Baklava Desenli tek kollu üst; kızıl vurgulu.", "stats": {"def": 4}, "look": {"top_style": "tek_kol", "top_pattern": 20}, "c1": Color(0.40, 0.42, 0.22), "c2": Color(0.72, 0.12, 0.12)},
	"ust_071": {"name": "Lacivert Kontrast Yakalı Ceket", "slot": "govde", "price": 620, "rank": 1, "desc": "Kontrast Yakalı ceket; gri vurgulu.", "stats": {"def": 2}, "look": {"top_style": "ceket", "top_pattern": 21}, "c1": Color(0.12, 0.16, 0.34), "c2": Color(0.45, 0.45, 0.48)},
	"ust_072": {"name": "Altın Renk Geçişli Kimono", "slot": "govde", "price": 626, "rank": 1, "desc": "Renk Geçişli kimono; zeytin vurgulu.", "stats": {"speed": 0.03}, "look": {"top_style": "kimono", "top_pattern": 22}, "c1": Color(0.85, 0.68, 0.25), "c2": Color(0.40, 0.42, 0.22)},
	"ust_073": {"name": "Kahve Kol Şeritli Uzun Kollu Gömlek", "slot": "govde", "price": 632, "rank": 1, "desc": "Kol Şeritli uzun kollu gömlek; mor vurgulu.", "stats": {"chakra": 15}, "look": {"top_style": "uzun", "top_pattern": 24}, "c1": Color(0.42, 0.28, 0.18), "c2": Color(0.40, 0.22, 0.55)},
	"ust_074": {"name": "Kömür Shuriken Armalı Kolsuz Üst", "slot": "govde", "price": 638, "rank": 1, "desc": "Shuriken Armalı kolsuz üst; bordo vurgulu.", "stats": {"melee": 0.05}, "look": {"top_style": "kolsuz", "top_pattern": 25}, "c1": Color(0.20, 0.20, 0.22), "c2": Color(0.45, 0.08, 0.12)},
	"ust_075": {"name": "Mor Yaprak Armalı Uzun Yakalı", "slot": "govde", "price": 644, "rank": 1, "desc": "Yaprak Armalı uzun yakalı; siyah vurgulu.", "stats": {"hp": 15}, "look": {"top_style": "yakali_uzun", "top_pattern": 26}, "c1": Color(0.40, 0.22, 0.55), "c2": Color(0.10, 0.10, 0.12)},
	"ust_076": {"name": "Pembe Dalga Desenli Tişört", "slot": "govde", "price": 650, "rank": 1, "desc": "Dalga Desenli tişört; yeşil vurgulu.", "stats": {"def": 3, "speed": 0.02}, "look": {"top_style": "tisort", "top_pattern": 27}, "c1": Color(0.92, 0.55, 0.65), "c2": Color(0.20, 0.45, 0.25)},
	"ust_077": {"name": "Yeşil Kuşaklı Kolsuz Üst", "slot": "govde", "price": 656, "rank": 1, "desc": "Kuşaklı kolsuz üst; bordo vurgulu.", "stats": {"chakra": 20, "def": 1}, "look": {"top_style": "kolsuz", "top_pattern": 8}, "c1": Color(0.20, 0.45, 0.25), "c2": Color(0.45, 0.08, 0.12)},
	"ust_078": {"name": "Zeytin İnce Çizgili Uzun Yakalı", "slot": "govde", "price": 662, "rank": 1, "desc": "İnce Çizgili uzun yakalı; siyah vurgulu.", "stats": {"melee": 0.04, "hp": 10}, "look": {"top_style": "yakali_uzun", "top_pattern": 9}, "c1": Color(0.40, 0.42, 0.22), "c2": Color(0.10, 0.10, 0.12)},
	"ust_079": {"name": "Lacivert Damalı Tişört", "slot": "govde", "price": 668, "rank": 1, "desc": "Damalı tişört; yeşil vurgulu.", "stats": {"speed": 0.04}, "look": {"top_style": "tisort", "top_pattern": 10}, "c1": Color(0.12, 0.16, 0.34), "c2": Color(0.20, 0.45, 0.25)},
	"ust_080": {"name": "Beyaz Göğüs Bantlı Gi", "slot": "govde", "price": 674, "rank": 1, "desc": "Göğüs Bantlı gi; kömür vurgulu.", "stats": {"def": 4}, "look": {"top_style": "gi", "top_pattern": 12}, "c1": Color(0.92, 0.92, 0.90), "c2": Color(0.20, 0.20, 0.22)},
	"ust_081": {"name": "Kahve Puantiyeli Tek Kollu Üst", "slot": "govde", "price": 800, "rank": 2, "desc": "Puantiyeli tek kollu üst; turuncu vurgulu.", "stats": {"def": 2}, "look": {"top_style": "tek_kol", "top_pattern": 13}, "c1": Color(0.42, 0.28, 0.18), "c2": Color(0.95, 0.50, 0.12)},
	"ust_082": {"name": "Kömür Zikzak Etekli Ceket", "slot": "govde", "price": 806, "rank": 2, "desc": "Zikzak Etekli ceket; gök mavisi vurgulu.", "stats": {"speed": 0.03}, "look": {"top_style": "ceket", "top_pattern": 14}, "c1": Color(0.20, 0.20, 0.22), "c2": Color(0.35, 0.60, 0.90)},
	"ust_083": {"name": "Mor Alev Etekli Kimono", "slot": "govde", "price": 812, "rank": 2, "desc": "Alev Etekli kimono; turkuaz vurgulu.", "stats": {"chakra": 15}, "look": {"top_style": "kimono", "top_pattern": 15}, "c1": Color(0.40, 0.22, 0.55), "c2": Color(0.20, 0.70, 0.70)},
	"ust_084": {"name": "Pembe Bulutlu Atlet", "slot": "govde", "price": 818, "rank": 2, "desc": "Bulutlu atlet; lacivert vurgulu.", "stats": {"melee": 0.05}, "look": {"top_style": "atlet", "top_pattern": 16}, "c1": Color(0.92, 0.55, 0.65), "c2": Color(0.12, 0.16, 0.34)},
	"ust_085": {"name": "Turuncu Sembollü Uzun Kollu Gömlek", "slot": "govde", "price": 824, "rank": 2, "desc": "Sembollü uzun kollu gömlek; kahve vurgulu.", "stats": {"hp": 15}, "look": {"top_style": "uzun", "top_pattern": 17}, "c1": Color(0.95, 0.50, 0.12), "c2": Color(0.42, 0.28, 0.18)},
	"ust_086": {"name": "Bordo Girdaplı Kolsuz Üst", "slot": "govde", "price": 830, "rank": 2, "desc": "Girdaplı kolsuz üst; turkuaz vurgulu.", "stats": {"def": 3, "speed": 0.02}, "look": {"top_style": "kolsuz", "top_pattern": 18}, "c1": Color(0.45, 0.08, 0.12), "c2": Color(0.20, 0.70, 0.70)},
	"ust_087": {"name": "Kızıl Kamuflaj Uzun Yakalı", "slot": "govde", "price": 836, "rank": 2, "desc": "Kamuflaj uzun yakalı; lacivert vurgulu.", "stats": {"chakra": 20, "def": 1}, "look": {"top_style": "yakali_uzun", "top_pattern": 19}, "c1": Color(0.72, 0.12, 0.12), "c2": Color(0.12, 0.16, 0.34)},
	"ust_088": {"name": "Gök Mavisi Baklava Desenli Tişört", "slot": "govde", "price": 842, "rank": 2, "desc": "Baklava Desenli tişört; kahve vurgulu.", "stats": {"melee": 0.04, "hp": 10}, "look": {"top_style": "tisort", "top_pattern": 20}, "c1": Color(0.35, 0.60, 0.90), "c2": Color(0.42, 0.28, 0.18)},
	"ust_089": {"name": "Siyah Kontrast Yakalı Yakalı Gömlek", "slot": "govde", "price": 848, "rank": 2, "desc": "Kontrast Yakalı yakalı gömlek; pembe vurgulu.", "stats": {"speed": 0.04}, "look": {"top_style": "yakali", "top_pattern": 21}, "c1": Color(0.10, 0.10, 0.12), "c2": Color(0.92, 0.55, 0.65)},
	"ust_090": {"name": "Gri Renk Geçişli Gi", "slot": "govde", "price": 854, "rank": 2, "desc": "Renk Geçişli gi; kızıl vurgulu.", "stats": {"def": 4}, "look": {"top_style": "gi", "top_pattern": 22}, "c1": Color(0.45, 0.45, 0.48), "c2": Color(0.72, 0.12, 0.12)},
	"ust_091": {"name": "Turkuaz Çapraz Kayışlı Tek Kollu Üst", "slot": "govde", "price": 860, "rank": 2, "desc": "Çapraz Kayışlı tek kollu üst; gri vurgulu.", "stats": {"def": 2}, "look": {"top_style": "tek_kol", "top_pattern": 23}, "c1": Color(0.20, 0.70, 0.70), "c2": Color(0.45, 0.45, 0.48)},
	"ust_092": {"name": "Mor Kol Şeritli Ceket", "slot": "govde", "price": 866, "rank": 2, "desc": "Kol Şeritli ceket; zeytin vurgulu.", "stats": {"speed": 0.03}, "look": {"top_style": "ceket", "top_pattern": 24}, "c1": Color(0.40, 0.22, 0.55), "c2": Color(0.40, 0.42, 0.22)},
	"ust_093": {"name": "Pembe Shuriken Armalı Kimono", "slot": "govde", "price": 872, "rank": 2, "desc": "Shuriken Armalı kimono; beyaz vurgulu.", "stats": {"chakra": 15}, "look": {"top_style": "kimono", "top_pattern": 25}, "c1": Color(0.92, 0.55, 0.65), "c2": Color(0.92, 0.92, 0.90)},
	"ust_094": {"name": "Turuncu Yaprak Armalı Atlet", "slot": "govde", "price": 878, "rank": 2, "desc": "Yaprak Armalı atlet; mor vurgulu.", "stats": {"melee": 0.05}, "look": {"top_style": "atlet", "top_pattern": 26}, "c1": Color(0.95, 0.50, 0.12), "c2": Color(0.40, 0.22, 0.55)},
	"ust_095": {"name": "Kızıl Kuşaklı Kimono", "slot": "govde", "price": 884, "rank": 2, "desc": "Kuşaklı kimono; beyaz vurgulu.", "stats": {"hp": 15}, "look": {"top_style": "kimono", "top_pattern": 8}, "c1": Color(0.72, 0.12, 0.12), "c2": Color(0.92, 0.92, 0.90)},
	"ust_096": {"name": "Gök Mavisi İnce Çizgili Atlet", "slot": "govde", "price": 890, "rank": 2, "desc": "İnce Çizgili atlet; mor vurgulu.", "stats": {"def": 3, "speed": 0.02}, "look": {"top_style": "atlet", "top_pattern": 9}, "c1": Color(0.35, 0.60, 0.90), "c2": Color(0.40, 0.22, 0.55)},
	"ust_097": {"name": "Siyah Damalı Uzun Kollu Gömlek", "slot": "govde", "price": 896, "rank": 2, "desc": "Damalı uzun kollu gömlek; bordo vurgulu.", "stats": {"chakra": 20, "def": 1}, "look": {"top_style": "uzun", "top_pattern": 10}, "c1": Color(0.10, 0.10, 0.12), "c2": Color(0.45, 0.08, 0.12)},
	"ust_098": {"name": "Gri İki Renkli Kolsuz Üst", "slot": "govde", "price": 902, "rank": 2, "desc": "İki Renkli kolsuz üst; siyah vurgulu.", "stats": {"melee": 0.04, "hp": 10}, "look": {"top_style": "kolsuz", "top_pattern": 11}, "c1": Color(0.45, 0.45, 0.48), "c2": Color(0.10, 0.10, 0.12)},
	"ust_099": {"name": "Turkuaz Göğüs Bantlı Uzun Yakalı", "slot": "govde", "price": 908, "rank": 2, "desc": "Göğüs Bantlı uzun yakalı; yeşil vurgulu.", "stats": {"speed": 0.04}, "look": {"top_style": "yakali_uzun", "top_pattern": 12}, "c1": Color(0.20, 0.70, 0.70), "c2": Color(0.20, 0.45, 0.25)},
	"ust_100": {"name": "Yeşil Puantiyeli Tişört", "slot": "govde", "price": 914, "rank": 2, "desc": "Puantiyeli tişört; altın vurgulu.", "stats": {"def": 4}, "look": {"top_style": "tisort", "top_pattern": 13}, "c1": Color(0.20, 0.45, 0.25), "c2": Color(0.85, 0.68, 0.25)},
	# --- alt
	"bol_pantolon": {"name": "Bol Paçalı Pantolon", "slot": "bacak", "price": 120, "rank": 0, "desc": "Baldırda balon gibi kabaran, bilekte toplanan pantolon.", "stats": {"def": 2, "speed": 0.02}, "look": {"pants_style": "bol"}, "c1": Color(0.25, 0.28, 0.35)},
	"col_salvari": {"name": "Çöl Şalvarı", "slot": "bacak", "price": 140, "rank": 0, "desc": "Kum rengi bol şalvar. Sıcakta serin tutar.", "stats": {"hp": 15}, "look": {"pants_style": "bol"}, "c1": Color(0.8, 0.7, 0.5)},
	"kapri": {"name": "Kapri", "slot": "bacak", "price": 70, "rank": 0, "desc": "Baldır ortasında biten hafif pantolon.", "stats": {"speed": 0.03}, "look": {"pants_style": "kapri"}, "c1": Color(0.3, 0.3, 0.33)},
	"kisa_sort": {"name": "Kısa Şort", "slot": "bacak", "price": 50, "rank": 0, "desc": "Diz üstü şort. Bacaklar serbest.", "stats": {"speed": 0.05}, "look": {"pants_style": "kisa_sort"}, "c1": Color(0.18, 0.18, 0.2)},
	"yamali_pant": {"name": "Yamalı Pantolon", "slot": "bacak", "price": 15, "rank": 0, "desc": "Dizleri yamalı, eskimiş pantolon.", "stats": {}, "look": {"pants_style": "sivil"}, "c1": Color(0.38, 0.32, 0.25)},
	"kot_panelli_pant": {"name": "Kot Panelli Bol Pantolon", "slot": "bacak", "price": 220, "rank": 0, "desc": "Baldırda büzgülü bol pantolon; önünde kalçadan dize daralan açık kot paneli.", "stats": {"speed": 0.03}, "look": {"pants_style": "bol", "pants_pattern": 13}, "c1": Color(0.12, 0.17, 0.4), "c2": Color(0.36, 0.52, 0.78)},
	"kot_panelli_pant_biye": {"name": "Biyeli Kot Panelli Pantolon", "slot": "bacak", "price": 260, "rank": 1, "desc": "Bol pantolon; önünde kenarı altın biyeli kot paneli.", "stats": {"melee": 0.03}, "look": {"pants_style": "bol", "pants_pattern": 13, "pants_pipe": Color(0.88, 0.7, 0.2)}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.75, 0.12, 0.12)},
	"bol_serit": {"name": "Yan Şeritli Bol Pantolon", "slot": "bacak", "price": 160, "rank": 0, "desc": "Baldırda büzgülü bol pantolon; iki yanında boydan şerit.", "stats": {"speed": 0.03}, "look": {"pants_style": "bol", "pants_pattern": 1}, "c1": Color(0.92, 0.92, 0.9), "c2": Color(0.1, 0.1, 0.12)},
	"bol_pant_cep": {"name": "Uyluk Cepli Bol Pantolon", "slot": "bacak", "price": 160, "rank": 0, "desc": "Baldırda büzgülü bol pantolon; sağ uylukta cep.", "stats": {"def": 2, "speed": 0.02}, "look": {"pants_style": "bol", "holster": true}, "c1": Color(0.3, 0.26, 0.24)},
	"bol_pant_balon": {"name": "Balon Desenli Bol Pantolon", "slot": "bacak", "price": 190, "rank": 0, "desc": "Baldırda büzgülü bol pantolon; üstünde kırmızı balon noktaları, sağ uylukta cep.", "stats": {"speed": 0.03}, "look": {"pants_style": "bol", "pants_pattern": 14, "holster": true}, "c1": Color(0.12, 0.16, 0.42), "c2": Color(0.85, 0.22, 0.22)},
	"bol_pant_serit_cep": {"name": "Şeritli Uyluk Cepli Bol Pantolon", "slot": "bacak", "price": 190, "rank": 0, "desc": "Baldırda büzgülü bol pantolon; yanında boydan şerit, sağ uylukta cep.", "stats": {"def": 2}, "look": {"pants_style": "bol", "pants_pattern": 1, "holster": true}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.92, 0.72, 0.2)},
	"etek_mini": {"name": "Kısa Etek", "slot": "bacak", "price": 180, "rank": 0, "desc": "Uyluk ortasında biten A kesim etek.", "stats": {"speed": 0.03}, "look": {"pants_style": "sort", "skirt": 1}, "c1": Color(0.7, 0.2, 0.25)},
	"etek_diz": {"name": "Diz Boyu Etek", "slot": "bacak", "price": 200, "rank": 0, "desc": "Dize inen pilili etek.", "stats": {"chakra": 10}, "look": {"pants_style": "sort", "skirt": 2}, "c1": Color(0.3, 0.32, 0.5)},
	"etek_uzun": {"name": "Uzun Etek", "slot": "bacak", "price": 240, "rank": 0, "desc": "Bileğe inen geniş etek.", "stats": {"chakra": 15}, "look": {"pants_style": "sivil", "skirt": 3}, "c1": Color(0.85, 0.85, 0.82)},
	"kizil_hakama": {"name": "Kızıl Hakama", "slot": "bacak", "price": 380, "rank": 1, "desc": "Tapınak muhafızlarının kırmızı hakaması.", "stats": {"def": 3, "chakra": 15}, "look": {"pants_style": "sivil", "hakama": true}, "c1": Color(0.65, 0.12, 0.12)},
	"siyah_pant": {"name": "Siyah Taktik Pantolon", "slot": "bacak", "price": 180, "rank": 1, "desc": "Baldırdan sargılı koyu pantolon.", "stats": {"def": 2, "speed": 0.03}, "look": {"pants_style": "ninja"}, "c1": Color(0.1, 0.1, 0.12)},
	"alt_001": {"name": "Siyah Yan Şeritli Ninja Pantolonu", "slot": "bacak", "price": 60, "rank": 0, "desc": "Yan Şeritli ninja pantolonu; beyaz ayrıntılı.", "stats": {"def": 2}, "look": {"pants_style": "ninja", "pants_pattern": 1}, "c1": Color(0.10, 0.10, 0.12), "c2": Color(0.90, 0.90, 0.88)},
	"alt_002": {"name": "Kahve Dizlikli Sargılı Pantolon", "slot": "bacak", "price": 72, "rank": 0, "desc": "Dizlikli sargılı pantolon; lacivert ayrıntılı.", "stats": {"speed": 0.03}, "look": {"pants_style": "sargi", "pants_pattern": 2}, "c1": Color(0.42, 0.28, 0.18), "c2": Color(0.12, 0.16, 0.34)},
	"alt_003": {"name": "Kızıl Kamuflaj Kısa Şort", "slot": "bacak", "price": 84, "rank": 0, "desc": "Kamuflaj kısa şort; mor ayrıntılı.", "stats": {"hp": 10}, "look": {"pants_style": "kisa_sort", "pants_pattern": 3}, "c1": Color(0.65, 0.12, 0.12), "c2": Color(0.38, 0.22, 0.50)},
	"alt_004": {"name": "Kum Damalı Uzun Pantolon", "slot": "bacak", "price": 96, "rank": 0, "desc": "Damalı uzun pantolon; zeytin ayrıntılı.", "stats": {"def": 1, "speed": 0.02}, "look": {"pants_style": "sivil", "pants_pattern": 4}, "c1": Color(0.78, 0.68, 0.48), "c2": Color(0.40, 0.42, 0.22)},
	"alt_005": {"name": "Gri İnce Çizgili Kapri", "slot": "bacak", "price": 108, "rank": 0, "desc": "İnce Çizgili kapri; kahve ayrıntılı.", "stats": {"melee": 0.04}, "look": {"pants_style": "kapri", "pants_pattern": 5}, "c1": Color(0.45, 0.45, 0.48), "c2": Color(0.42, 0.28, 0.18)},
	"alt_006": {"name": "Zeytin İki Renkli Diz Altı Şort", "slot": "bacak", "price": 120, "rank": 0, "desc": "İki Renkli diz altı şort; kum ayrıntılı.", "stats": {"def": 2}, "look": {"pants_style": "sort", "pants_pattern": 6}, "c1": Color(0.40, 0.42, 0.22), "c2": Color(0.78, 0.68, 0.48)},
	"alt_007": {"name": "Mor Paça Bantlı Bol Paçalı Pantolon", "slot": "bacak", "price": 132, "rank": 0, "desc": "Paça Bantlı bol paçalı pantolon; kızıl ayrıntılı.", "stats": {"speed": 0.03}, "look": {"pants_style": "bol", "pants_pattern": 7}, "c1": Color(0.38, 0.22, 0.50), "c2": Color(0.65, 0.12, 0.12)},
	"alt_008": {"name": "Lacivert Yamalı Ninja Pantolonu", "slot": "bacak", "price": 144, "rank": 0, "desc": "Yamalı ninja pantolonu; kahve ayrıntılı.", "stats": {"hp": 10}, "look": {"pants_style": "ninja", "pants_pattern": 8}, "c1": Color(0.12, 0.16, 0.34), "c2": Color(0.42, 0.28, 0.18)},
	"alt_009": {"name": "Beyaz Kargo Cepli Sargılı Pantolon", "slot": "bacak", "price": 156, "rank": 0, "desc": "Kargo Cepli sargılı pantolon; siyah ayrıntılı.", "stats": {"def": 1, "speed": 0.02}, "look": {"pants_style": "sargi", "pants_pattern": 9}, "c1": Color(0.90, 0.90, 0.88), "c2": Color(0.10, 0.10, 0.12)},
	"alt_010": {"name": "Turuncu Sarmal Sargılı Kısa Şort", "slot": "bacak", "price": 168, "rank": 0, "desc": "Sarmal Sargılı kısa şort; mor ayrıntılı.", "stats": {"melee": 0.04}, "look": {"pants_style": "kisa_sort", "pants_pattern": 10}, "c1": Color(0.92, 0.50, 0.14), "c2": Color(0.38, 0.22, 0.50)},
	"alt_011": {"name": "Siyah Alev Paçalı Uzun Pantolon", "slot": "bacak", "price": 180, "rank": 0, "desc": "Alev Paçalı uzun pantolon; beyaz ayrıntılı.", "stats": {"def": 2}, "look": {"pants_style": "sivil", "pants_pattern": 11}, "c1": Color(0.10, 0.10, 0.12), "c2": Color(0.90, 0.90, 0.88)},
	"alt_012": {"name": "Kahve Puantiyeli Kapri", "slot": "bacak", "price": 192, "rank": 0, "desc": "Puantiyeli kapri; lacivert ayrıntılı.", "stats": {"speed": 0.03}, "look": {"pants_style": "kapri", "pants_pattern": 12}, "c1": Color(0.42, 0.28, 0.18), "c2": Color(0.12, 0.16, 0.34)},
	"alt_013": {"name": "Kızıl Yan Şeritli Diz Altı Şort", "slot": "bacak", "price": 204, "rank": 1, "desc": "Yan Şeritli diz altı şort; mor ayrıntılı.", "stats": {"hp": 10}, "look": {"pants_style": "sort", "pants_pattern": 1}, "c1": Color(0.65, 0.12, 0.12), "c2": Color(0.38, 0.22, 0.50)},
	"alt_014": {"name": "Kum Dizlikli Bol Paçalı Pantolon", "slot": "bacak", "price": 216, "rank": 1, "desc": "Dizlikli bol paçalı pantolon; zeytin ayrıntılı.", "stats": {"def": 1, "speed": 0.02}, "look": {"pants_style": "bol", "pants_pattern": 2}, "c1": Color(0.78, 0.68, 0.48), "c2": Color(0.40, 0.42, 0.22)},
	"alt_015": {"name": "Gri Kamuflaj Ninja Pantolonu", "slot": "bacak", "price": 228, "rank": 1, "desc": "Kamuflaj ninja pantolonu; kahve ayrıntılı.", "stats": {"melee": 0.04}, "look": {"pants_style": "ninja", "pants_pattern": 3}, "c1": Color(0.45, 0.45, 0.48), "c2": Color(0.42, 0.28, 0.18)},
	"alt_016": {"name": "Zeytin Damalı Sargılı Pantolon", "slot": "bacak", "price": 240, "rank": 1, "desc": "Damalı sargılı pantolon; kum ayrıntılı.", "stats": {"def": 2}, "look": {"pants_style": "sargi", "pants_pattern": 4}, "c1": Color(0.40, 0.42, 0.22), "c2": Color(0.78, 0.68, 0.48)},
	"alt_017": {"name": "Mor İnce Çizgili Kısa Şort", "slot": "bacak", "price": 252, "rank": 1, "desc": "İnce Çizgili kısa şort; kızıl ayrıntılı.", "stats": {"speed": 0.03}, "look": {"pants_style": "kisa_sort", "pants_pattern": 5}, "c1": Color(0.38, 0.22, 0.50), "c2": Color(0.65, 0.12, 0.12)},
	"alt_018": {"name": "Lacivert İki Renkli Uzun Pantolon", "slot": "bacak", "price": 264, "rank": 1, "desc": "İki Renkli uzun pantolon; kahve ayrıntılı.", "stats": {"hp": 10}, "look": {"pants_style": "sivil", "pants_pattern": 6}, "c1": Color(0.12, 0.16, 0.34), "c2": Color(0.42, 0.28, 0.18)},
	"alt_019": {"name": "Beyaz Paça Bantlı Kapri", "slot": "bacak", "price": 276, "rank": 1, "desc": "Paça Bantlı kapri; siyah ayrıntılı.", "stats": {"def": 1, "speed": 0.02}, "look": {"pants_style": "kapri", "pants_pattern": 7}, "c1": Color(0.90, 0.90, 0.88), "c2": Color(0.10, 0.10, 0.12)},
	"alt_020": {"name": "Turuncu Yamalı Diz Altı Şort", "slot": "bacak", "price": 288, "rank": 1, "desc": "Yamalı diz altı şort; mor ayrıntılı.", "stats": {"melee": 0.04}, "look": {"pants_style": "sort", "pants_pattern": 8}, "c1": Color(0.92, 0.50, 0.14), "c2": Color(0.38, 0.22, 0.50)},
	# --- ayak
	"deri_cizme": {"name": "Deri Çizme", "slot": "ayak", "price": 220, "rank": 0, "desc": "Baldıra kadar çıkan kalın çizme.", "stats": {"def": 3}, "look": {"foot_style": "cizme"}, "c1": Color(0.28, 0.2, 0.14), "c2": Color(0.28, 0.2, 0.14)},
	"zirhli_cizme": {"name": "Zırhlı Çizme", "slot": "ayak", "price": 520, "rank": 2, "desc": "Metal plakalı ağır çizme.", "stats": {"def": 6, "speed": -0.02}, "look": {"foot_style": "cizme"}, "c1": Color(0.35, 0.36, 0.4), "c2": Color(0.35, 0.36, 0.4)},
	"yuksek_sandal": {"name": "Dize Sargılı Sandalet", "slot": "ayak", "price": 140, "rank": 0, "desc": "Bacağı dize kadar saran bandajlı sandalet.", "stats": {"speed": 0.04, "melee": 0.02}, "look": {"foot_style": "yuksek_sandal"}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.92, 0.92, 0.9)},
	"siyah_tabi": {"name": "Siyah Tabi", "slot": "ayak", "price": 220, "rank": 1, "desc": "Sessiz adım için koyu tabi.", "stats": {"speed": 0.06}, "look": {"foot_style": "tabi"}, "c1": Color(0.06, 0.06, 0.08), "c2": Color(0.92, 0.92, 0.9)},
	"ayak_001": {"name": "Burun Kapaklı Ninja Sandaleti", "slot": "ayak", "price": 60, "rank": 0, "desc": "Burnunda metal kapak; tekmeye güç katar.", "stats": {"melee": 0.03}, "look": {"foot_style": "sandal", "foot_pattern": 1}, "c1": Color(0.12, 0.14, 0.30), "c2": Color(0.70, 0.72, 0.76)},
	"ayak_002": {"name": "Kontrast Tabanlı Tabi", "slot": "ayak", "price": 78, "rank": 0, "desc": "Ayağı saran sessiz tabi, kalın açık taban.", "stats": {"speed": 0.03}, "look": {"foot_style": "tabi", "foot_pattern": 7}, "c1": Color(0.10, 0.10, 0.12), "c2": Color(0.85, 0.82, 0.75)},
	"ayak_003": {"name": "Çapraz Bağcıklı Tabi", "slot": "ayak", "price": 96, "rank": 0, "desc": "Bileğe kadar çapraz bağlanan beyaz tabi.", "stats": {"speed": 0.02, "def": 1}, "look": {"foot_style": "tabi", "foot_pattern": 2}, "c1": Color(0.90, 0.90, 0.88), "c2": Color(0.15, 0.15, 0.18)},
	"ayak_004": {"name": "Deri Bilek Botu", "slot": "ayak", "price": 114, "rank": 0, "desc": "Bileği saran yumuşak deri bot.", "stats": {"def": 2}, "look": {"foot_style": "bilek_bot", "foot_pattern": 0}, "c1": Color(0.38, 0.25, 0.15), "c2": Color(0.20, 0.14, 0.10)},
	"ayak_005": {"name": "Bağcıklı Bilek Botu", "slot": "ayak", "price": 132, "rank": 0, "desc": "Önü çapraz bağcıklı hafif bot.", "stats": {"speed": 0.03}, "look": {"foot_style": "bilek_bot", "foot_pattern": 2}, "c1": Color(0.15, 0.15, 0.17), "c2": Color(0.85, 0.85, 0.80)},
	"ayak_006": {"name": "Perçinli Bilek Botu", "slot": "ayak", "price": 150, "rank": 0, "desc": "Üstü metal perçinli sağlam bot.", "stats": {"def": 3}, "look": {"foot_style": "bilek_bot", "foot_pattern": 8}, "c1": Color(0.20, 0.18, 0.16), "c2": Color(0.60, 0.60, 0.62)},
	"ayak_007": {"name": "Uzun Konçlu Çizme", "slot": "ayak", "price": 168, "rank": 0, "desc": "Konç ağzı kızıl bantlı savaşçı çizmesi.", "stats": {"def": 2, "hp": 10}, "look": {"foot_style": "cizme", "foot_pattern": 3}, "c1": Color(0.10, 0.10, 0.12), "c2": Color(0.55, 0.12, 0.12)},
	"ayak_008": {"name": "Çizgili Çizme", "slot": "ayak", "price": 186, "rank": 0, "desc": "Enine çizgili gezgin çizmesi.", "stats": {"speed": 0.02, "def": 1}, "look": {"foot_style": "cizme", "foot_pattern": 4}, "c1": Color(0.25, 0.30, 0.45), "c2": Color(0.85, 0.85, 0.82)},
	"ayak_009": {"name": "Diz Çizmesi", "slot": "ayak", "price": 204, "rank": 0, "desc": "Dize kadar çıkan yüksek siyah çizme.", "stats": {"def": 3}, "look": {"foot_style": "diz_cizme", "foot_pattern": 0}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.30, 0.30, 0.33)},
	"ayak_010": {"name": "Kürk Kenarlı Kar Çizmesi", "slot": "ayak", "price": 222, "rank": 0, "desc": "Kar ülkesi ninjalarının kürklü çizmesi.", "stats": {"def": 3, "hp": 15}, "look": {"foot_style": "diz_cizme", "foot_pattern": 6}, "c1": Color(0.45, 0.35, 0.25), "c2": Color(0.90, 0.88, 0.84)},
	"ayak_011": {"name": "Bağcıklı Diz Çizmesi", "slot": "ayak", "price": 240, "rank": 1, "desc": "Dize kadar bağcıklı uzun bot.", "stats": {"def": 2, "speed": 0.02}, "look": {"foot_style": "diz_cizme", "foot_pattern": 2}, "c1": Color(0.30, 0.20, 0.12), "c2": Color(0.12, 0.10, 0.08)},
	"ayak_012": {"name": "Samuray Zırhlı Tozluğu", "slot": "ayak", "price": 258, "rank": 1, "desc": "Kaval kemiğini metal plakayla koruyan samuray tozluğu.", "stats": {"def": 5, "speed": -0.02}, "look": {"foot_style": "zirhli_tozluk", "foot_pattern": 5}, "c1": Color(0.25, 0.12, 0.10), "c2": Color(0.60, 0.60, 0.62)},
	"ayak_013": {"name": "Perçinli Zırh Tozluğu", "slot": "ayak", "price": 276, "rank": 1, "desc": "Demir perçinli ağır tozluk.", "stats": {"def": 6, "speed": -0.03}, "look": {"foot_style": "zirhli_tozluk", "foot_pattern": 8}, "c1": Color(0.15, 0.15, 0.18), "c2": Color(0.55, 0.55, 0.60)},
	"ayak_014": {"name": "Sargılı Gezgin Botu", "slot": "ayak", "price": 294, "rank": 1, "desc": "Deri bot, baldıra kadar bandaj sargılı.", "stats": {"speed": 0.03, "hp": 10}, "look": {"foot_style": "sargili_bot", "foot_pattern": 0}, "c1": Color(0.40, 0.32, 0.22), "c2": Color(0.90, 0.88, 0.82)},
	"ayak_015": {"name": "Kızıl Sargılı Bot", "slot": "ayak", "price": 312, "rank": 1, "desc": "Siyah bot, kızıl sargı ve taban.", "stats": {"melee": 0.04}, "look": {"foot_style": "sargili_bot", "foot_pattern": 7}, "c1": Color(0.10, 0.10, 0.12), "c2": Color(0.65, 0.10, 0.10)},
	"ayak_016": {"name": "Burun Kapaklı Diz Çizmesi", "slot": "ayak", "price": 330, "rank": 1, "desc": "Burnu ve topuğu metal kaplı uzun çizme.", "stats": {"def": 4}, "look": {"foot_style": "diz_cizme", "foot_pattern": 1}, "c1": Color(0.20, 0.22, 0.28), "c2": Color(0.70, 0.72, 0.76)},
	"ayak_017": {"name": "Çizgili Yüksek Sandalet", "slot": "ayak", "price": 348, "rank": 1, "desc": "Baldıra kadar bağlanan çizgili sandalet.", "stats": {"speed": 0.04}, "look": {"foot_style": "yuksek_sandal", "foot_pattern": 4}, "c1": Color(0.15, 0.18, 0.35), "c2": Color(0.90, 0.90, 0.88)},
	"ayak_018": {"name": "Hasır Zōri", "slot": "ayak", "price": 366, "rank": 2, "desc": "Hasır tabanlı, ince kayışlı geleneksel zōri.", "stats": {"chakra": 10}, "look": {"foot_style": "zori", "foot_pattern": 7}, "c1": Color(0.80, 0.70, 0.45), "c2": Color(0.30, 0.20, 0.12)},
	"ayak_019": {"name": "Kürklü Bilek Botu", "slot": "ayak", "price": 384, "rank": 2, "desc": "Bilek ağzı kürklü kışlık bot.", "stats": {"hp": 15}, "look": {"foot_style": "bilek_bot", "foot_pattern": 6}, "c1": Color(0.30, 0.22, 0.16), "c2": Color(0.90, 0.88, 0.84)},
	"ayak_020": {"name": "Metal Plakalı Çizme", "slot": "ayak", "price": 402, "rank": 2, "desc": "Önü metal plakalı ANBU çizmesi.", "stats": {"def": 4, "speed": 0.01}, "look": {"foot_style": "cizme", "foot_pattern": 5}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.60, 0.60, 0.62)},
	# --- yelek / zırh
	"kok_yelek": {"name": "Kök Birliği Yeleği", "slot": "zirh", "price": 0, "rank": 4, "desc": "Dikey dikişli simsiyah gizli birlik yeleği.", "stats": {"def": 11, "speed": 0.04}, "look": {"vest_style": 7}, "c1": Color(0.1, 0.1, 0.12)},
	"zincir_yelek": {"name": "Zincir Örgü Yelek", "slot": "zirh", "price": 600, "rank": 1, "desc": "Halka halka örülmüş metal yelek.", "stats": {"def": 9, "speed": -0.02}, "look": {"vest_style": 8}, "c1": Color(0.55, 0.57, 0.6)},
	"kayis_kosum": {"name": "Kayış Koşum", "slot": "zirh", "price": 90, "rank": 0, "desc": "Göğüste çapraz deri kayışlar ve bel kemeri.", "stats": {"def": 2, "melee": 0.03}, "look": {"vest_style": 9}, "c1": Color(0.35, 0.24, 0.15)},
	"deri_pul_zirh": {"name": "Deri Pullu Zırh", "slot": "zirh", "price": 720, "rank": 2, "desc": "Sıra sıra deri pullarla kaplı hafif zırh.", "stats": {"def": 11, "hp": 20, "speed": -0.02}, "look": {"vest_style": 10}, "c1": Color(0.42, 0.28, 0.18)},
	"gogus_plakasi": {"name": "Göğüs Plakası", "slot": "zirh", "price": 480, "rank": 1, "desc": "Yalnızca göğsü saran hafif metal plaka.", "stats": {"def": 7, "speed": 0.01}, "look": {"vest_style": 11}, "c1": Color(0.6, 0.62, 0.66)},
	"lake_zirh": {"name": "Kızıl Lake Zırh", "slot": "zirh", "price": 1800, "rank": 3, "desc": "Kırmızı lakeli lamel zırh, omuzluklarıyla birlikte.", "stats": {"def": 20, "hp": 45, "speed": -0.05}, "look": {"vest_style": 6}, "c1": Color(0.55, 0.1, 0.1)},
	"ame_yelek": {"name": "Yağmur Köyü Yeleği", "slot": "zirh", "price": 700, "rank": 2, "desc": "Gri, nem tutmayan dikişli yelek.", "stats": {"def": 8, "chakra": 15}, "look": {"vest_style": 2}, "c1": Color(0.45, 0.48, 0.52)},
	"jonin_koyu": {"name": "Gece Taktik Yeleği", "slot": "zirh", "price": 900, "rank": 2, "desc": "Koyu zeytin rengi, parşömen cepli yelek.", "stats": {"def": 10, "speed": 0.02}, "look": {"vest_style": 0}, "c1": Color(0.2, 0.26, 0.18)},
	# --- dış giysi
	"ciplak": {"name": "Üstsüz", "slot": "govde", "price": 0, "rank": 0, "desc": "Üstte giysi yok.", "stats": {}, "look": {"top_style": "yok"}, "c1": Color(0.9, 0.75, 0.6)},
	"keiko_gi": {"name": "Keiko-gi Üstü", "slot": "govde", "price": 220, "rank": 0, "desc": "Geniş kısa kollu beyaz antrenman gi'si; renkli iç yaka, omuzları saran ve sırtta çaprazlanan sarı tasuki.", "stats": {"melee": 0.05, "speed": 0.02}, "look": {"top_style": "gi", "wide_sleeve": true, "kg": {"inner": Color(0.62, 0.8, 0.95), "tasuki": Color(0.96, 0.76, 0.16)}}, "c1": Color(0.96, 0.96, 0.97), "c2": Color(0.9, 0.9, 0.92)},
	"keiko_gi_kirmizi": {"name": "Keiko-gi Üstü: Kırmızı Yaka", "slot": "govde", "price": 220, "rank": 0, "desc": "Geniş kısa kollu beyaz antrenman gi'si; kırmızı iç yaka, sarı tasuki.", "stats": {"melee": 0.03, "chakra": 15}, "look": {"top_style": "gi", "wide_sleeve": true, "kg": {"inner": Color(0.6, 0.1, 0.14), "tasuki": Color(0.96, 0.76, 0.16)}}, "c1": Color(0.96, 0.96, 0.97), "c2": Color(0.9, 0.9, 0.92)},
	"keiko_hakama": {"name": "Antrenman Hakaması", "slot": "bacak", "price": 300, "rank": 0, "desc": "Yüksek belli, baldır ortasında biten geniş paçalı hakama; önde çapraz bel bağları, sırtta koshi-ita, paçada beyaz bant.", "stats": {"def": 3, "melee": 0.03}, "look": {"pants_style": "kisa_sort", "hakama": true, "hakama_cut": "genis", "pants_pattern": 22}, "c1": Color(0.12, 0.22, 0.7), "c2": Color(0.96, 0.96, 0.97)},
	"pilili_etek": {"name": "Pilili Hakama Etek", "slot": "bacak", "price": 260, "rank": 0, "desc": "Yüksek belli, uyluk ortasında biten pilili kısa etek; önde büyük fiyonk, uçta beyaz bant.", "stats": {"speed": 0.04}, "look": {"pants_style": "kisa_sort", "pleat_skirt": true, "pants_pattern": 23}, "c1": Color(0.7, 0.1, 0.12), "c2": Color(0.96, 0.96, 0.97)},
	"tabi_zori": {"name": "Tabi ve Zōri", "slot": "ayak", "price": 90, "rank": 0, "desc": "Baldıra çıkan beyaz tabi çorabı, altın kayışlı zōri.", "stats": {"speed": 0.03}, "look": {"foot_style": "tabi", "foot_pattern": 12, "anbu_leg": "corap_kisa"}, "c1": Color(0.96, 0.96, 0.97), "c2": Color(0.15, 0.25, 0.7)},
	"tabi_zori_uzun": {"name": "Diz Üstü Tabi ve Zōri", "slot": "ayak", "price": 110, "rank": 0, "desc": "Diz üstüne çıkan, ağzı iki çizgili beyaz çorap, altın kayışlı zōri.", "stats": {"speed": 0.04}, "look": {"foot_style": "tabi", "foot_pattern": 12, "anbu_leg": "corap_dz"}, "c1": Color(0.96, 0.96, 0.97), "c2": Color(0.7, 0.1, 0.12)},
	"kolsuz_fermuar": {"name": "Çapraz Fermuarlı Kolsuz Üst", "slot": "govde", "price": 110, "rank": 0, "desc": "Dik yakalı kolsuz üst; fermuar yakadan sola kıvrılıp bele iner.", "stats": {"speed": 0.03, "melee": 0.03}, "look": {"top_style": "kolsuz", "top_pattern": 36}, "c1": Color(0.7, 0.12, 0.14), "c2": Color(0.7, 0.12, 0.14)},
	"dirseklik": {"name": "Dirseklik", "slot": "kol", "price": 70, "rank": 0, "desc": "Dirseği saran kumaş koruyucu.", "stats": {"def": 2}, "look": {"elbow_pads": Color(0.92, 0.72, 0.8)}, "c1": Color(0.92, 0.72, 0.8)},
	"mini_etek": {"name": "Mini Etek", "slot": "bacak", "price": 140, "rank": 0, "desc": "Uyluk üstünde biten A kesim kısa etek; altında kısa şort.", "stats": {"speed": 0.04}, "look": {"pants_style": "kisa_sort", "skirt": 1}, "c1": Color(0.35, 0.22, 0.15)},
	"isikli_tulum": {"name": "Işıklı Hatlı Tulum Üstü", "slot": "govde", "price": 260, "rank": 0, "desc": "Siyah dar tulum üstü; yakada, omuzda ve ön kolda parlayan beyaz-pembe hatlar.", "stats": {"speed": 0.05}, "look": {"top_style": "yakali_uzun", "top_pattern": 39}, "c1": Color(0.07, 0.07, 0.09), "c2": Color(0.07, 0.07, 0.09)},
	"isikli_pant": {"name": "Işıklı Hatlı Tulum Altı", "slot": "bacak", "price": 200, "rank": 0, "desc": "Siyah dar tulum altı; dizde V ve incikte parlayan hat.", "stats": {"speed": 0.04}, "look": {"pants_style": "sivil", "pants_pattern": 27}, "c1": Color(0.07, 0.07, 0.09), "c2": Color(1.0, 0.86, 0.95)},
	"chunin_yelek_acik": {"name": "Konoha Taktik Yeleği (Açık)", "slot": "zirh", "price": 0, "rank": 2, "desc": "Fermuarı açık bırakılmış chūnin-jōnin yeleği; altındaki kemer görünür.", "stats": {"def": 9, "hp": 20, "speed": 0.02}, "look": {"vest_style": 0, "vest_open": true, "waist_belt": Color(0.75, 0.12, 0.14)}, "c1": Color(0.45, 0.6, 0.4)},
	"file_kollu_tisort": {"name": "Kolu File Bantlı Tişört ve Şal", "slot": "govde", "price": 160, "rank": 0, "desc": "Kısa kollu siyah tulum üstü, kol ağzında file bant; sağ omuzdan sarkan uzun kırık beyaz şal.", "stats": {"def": 2, "chakra": 15}, "look": {"top_style": "tisort", "top_pattern": 41, "drape_sash": Color(0.9, 0.88, 0.82)}, "c1": Color(0.14, 0.1, 0.12), "c2": Color(0.14, 0.1, 0.12)},
	"kisa_kimono_haku": {"name": "Beyaz Biyeli Kısa Kimono", "slot": "dis", "price": 300, "rank": 0, "desc": "Uyluğa inen mavi kısa kimono; beyaz kruvaze yaka bandı, beyaz kol ağzı, kahve obi.", "stats": {"chakra": 25, "speed": 0.04}, "look": {"outer_style": "kisa_kimono", "outer_pattern": 0, "holster": false, "kk": {"obi": Color(0.4, 0.28, 0.18), "collar": Color(0.95, 0.95, 0.94), "sleeve": Color(0.95, 0.95, 0.94)}}, "c1": Color(0.14, 0.2, 0.5), "c2": Color(0.14, 0.2, 0.5)},
	"cizgili_hakama": {"name": "Çizgili Hakama", "slot": "bacak", "price": 340, "rank": 0, "desc": "İnce dikey çizgili koyu hakama.", "stats": {"def": 3}, "look": {"pants_style": "sivil", "hakama": true, "pants_pattern": 5}, "c1": Color(0.24, 0.24, 0.26), "c2": Color(0.12, 0.12, 0.13)},
	"yakali_uzun_cizgi": {"name": "Çizgili Dik Yaka Tulum Üstü", "slot": "govde", "price": 120, "rank": 0, "desc": "İnce dikey çizgili, uzun kollu dik yaka tulum üstü.", "stats": {"def": 2}, "look": {"top_style": "yakali_uzun", "top_pattern": 9}, "c1": Color(0.23, 0.2, 0.19), "c2": Color(0.14, 0.12, 0.12)},
	"uzun_balikci": {"name": "Uzun Balıkçı Yaka Kazak ve Gi Yelek", "slot": "govde", "price": 260, "rank": 0, "desc": "Uyluğa inen kırmızı balıkçı yaka kazak; üstünde omuzları yırtık gri kolsuz gi yelek, siyah yaka bandı.", "stats": {"def": 4, "hp": 30}, "look": {"top_style": "yakali_uzun", "top_pattern": 2, "gi_yelek": Color(0.5, 0.5, 0.52), "sweater_hem": Color(0.7, 0.12, 0.2)}, "c1": Color(0.7, 0.12, 0.2), "c2": Color(0.6, 0.1, 0.17)},
	"kimono_genis_kol": {"name": "Geniş Kollu Kimono ve Fiyonk", "slot": "govde", "price": 260, "rank": 0, "desc": "Çok geniş uzun kollu kimono üst; önde soluk sarı kuşak ve fiyonk.", "stats": {"chakra": 25}, "look": {"top_style": "kimono", "wide_sleeve_long": true, "front_bow": Color(0.96, 0.92, 0.75)}, "c1": Color(0.92, 0.62, 0.22), "c2": Color(0.96, 0.92, 0.75)},
	"buyuk_parsomen": {"name": "Dev Parşömen", "slot": "kol", "price": 400, "rank": 2, "desc": "Sırta yatay bağlanan, iki yana taşan dev mühür parşömeni.", "stats": {"chakra": 40}, "look": {"back_scroll": true}, "c1": Color(0.94, 0.94, 0.96)},
	"zirh_onluk": {"name": "Zırh Önlüğü ve İp Kuşak", "slot": "kol", "price": 300, "rank": 1, "desc": "Belden dize inen bağcıklı zeytin yeşili zırh önlüğü; bej ip kuşak.", "stats": {"def": 5}, "look": {"armor_apron": Color(0.45, 0.5, 0.42)}, "c1": Color(0.45, 0.5, 0.42)},
	"file_ninja_pant": {"name": "File Çoraplı Ninja Pantolonu", "slot": "bacak", "price": 120, "rank": 0, "desc": "Baldırda biten ninja pantolonu; altında file çorap.", "stats": {"def": 2, "speed": 0.02}, "look": {"pants_style": "ninja", "leg_fishnet": true}, "c1": Color(0.15, 0.15, 0.3)},
	"uzun_robe": {"name": "Önü Açık Uzun Cübbe", "slot": "dis", "price": 520, "rank": 2, "desc": "Bileğe inen, önü boydan boya açık koyu yeşil cübbe; çok geniş uzun kollar, koyu yaka bandı.", "stats": {"chakra": 35, "def": 4}, "look": {"outer_style": "uzun_robe", "outer_pattern": 0, "holster": false}, "c1": Color(0.1, 0.16, 0.12), "c2": Color(0.1, 0.16, 0.12)},
	"buyuk_kapusonlu": {"name": "Bol Kapüşonlu", "slot": "dis", "price": 240, "rank": 0, "desc": "Uyluğa inen bol sarı kapüşonlu; büzgü ipleri, kanguru cebi, ribana manşet.", "stats": {"hp": 25}, "look": {"outer_style": "buyuk_kapusonlu", "outer_pattern": 0, "holster": false}, "c1": Color(0.96, 0.82, 0.42), "c2": Color(0.96, 0.82, 0.42)},
	"yaprak_etek": {"name": "Katlı Yaprak Etek", "slot": "bacak", "price": 160, "rank": 0, "desc": "Üstte açık mavi sivri dişli kat, altta pembe fırfırlı kat; kısa etek.", "stats": {"speed": 0.04}, "look": {"pants_style": "kisa_sort", "petal_skirt": {"a": Color(0.75, 0.88, 0.95), "b": Color(0.95, 0.55, 0.62)}}, "c1": Color(0.15, 0.15, 0.17)},
	"hinata_ceket_acik": {"name": "Kapüşonlu Bol Ceket (Açık)", "slot": "dis", "price": 300, "rank": 0, "desc": "Fermuarı açık lavanta-beyaz kapüşonlu ceket; dolgun yaka, geniş kollar.", "stats": {"chakra": 20, "speed": 0.03}, "look": {"outer_style": "hinata_ceket", "outer_pattern": 31, "hc_open": true}, "c1": Color(0.62, 0.58, 0.85), "c2": Color(0.95, 0.95, 0.96)},
	"file_sutyen": {"name": "File Sütyen", "slot": "govde", "price": 90, "rank": 0, "desc": "Göğsü saran file üst; göbek açık.", "stats": {"speed": 0.04}, "look": {"top_style": "kolsuz", "top_pattern": 43}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.12, 0.12, 0.14)},
	"kot_sort": {"name": "Kemerli Kot Şort", "slot": "bacak", "price": 110, "rank": 0, "desc": "Paçası kıvrık mavi kot şort; koyu mavi kemer.", "stats": {"speed": 0.04}, "look": {"pants_style": "kisa_sort", "waist_belt": Color(0.12, 0.16, 0.32)}, "c1": Color(0.22, 0.4, 0.68)},
	"cizgili_kolsuz": {"name": "Çizgili Kolsuz Üst ve Geniş Obi", "slot": "govde", "price": 160, "rank": 0, "desc": "Dikey çizgili, dik yakalı kolsuz lavanta üst; belde geniş koyu mor obi ve sarkan mürdüm bez.", "stats": {"chakra": 20, "speed": 0.03}, "look": {"top_style": "kolsuz", "top_pattern": 9, "wide_obi": Color(0.24, 0.2, 0.36)}, "c1": Color(0.8, 0.75, 0.92), "c2": Color(0.62, 0.55, 0.8)},
	"kisa_kollu_kazak": {"name": "Kısa Kollu Kazak", "slot": "dis", "price": 200, "rank": 0, "desc": "Geniş yakalı, bele kadar pembe kazak; kısa kollarda ve etekte beyaz şeritler.", "stats": {"hp": 20}, "look": {"outer_style": "kisa_kollu_kazak", "outer_pattern": 0, "holster": false}, "c1": Color(0.95, 0.75, 0.82), "c2": Color(0.95, 0.75, 0.82)},
	"cizgili_uzun_etek_kapri": {"name": "Çizgili Uzun Etek ve Kapri", "slot": "bacak", "price": 180, "rank": 0, "desc": "Baldıra inen pembe çizgili gri A kesim etek; altında koyu gri kapri.", "stats": {"chakra": 15}, "look": {"pants_style": "kapri", "long_skirt": Color(0.86, 0.85, 0.86)}, "c1": Color(0.24, 0.24, 0.28)},
	"gelinlik": {"name": "Siyah Gelinlik", "slot": "dis", "price": 900, "rank": 0, "desc": "Boyundan bağlı kolsuz, belde fırfırlı, yere inen iki tonlu siyah gelinlik; önde pli şeritler.", "stats": {"chakra": 40, "hp": 20}, "look": {"outer_style": "gelinlik", "outer_pattern": 0, "holster": false}, "c1": Color(0.14, 0.1, 0.18), "c2": Color(0.14, 0.1, 0.18)},
	"hiruzen_aks": {"name": "Omuzluk ve Zırhlı Kolluk", "slot": "kol", "price": 220, "rank": 3, "desc": "İki omuzda gri omuzluk, sağ ön kolda yeşilimsi zırhlı kolluk.", "stats": {"def": 4}, "look": {"hiruzen_aks": Color(0.6, 0.62, 0.66)}, "c1": Color(0.6, 0.62, 0.66)},
	"gi_file_kol": {"name": "File Kollu Gi Üstü", "slot": "govde", "price": 140, "rank": 0, "desc": "Dirsek boyu kollu siyah gi üstü; ön kollar ve incikler file.", "stats": {"def": 2, "melee": 0.03}, "look": {"top_style": "uzun", "top_pattern": 44, "leg_fishnet": true}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.1, 0.1, 0.12)},
	"sarma_mini": {"name": "Kısa Sargı Etek", "slot": "dis", "price": 160, "rank": 0, "desc": "Uyluk ortasında biten düz mor sargı etek; önde bindirme kanadı.", "stats": {"speed": 0.04}, "look": {"outer_style": "sarma_mini", "outer_pattern": 33, "holster": true}, "c1": Color(0.4, 0.2, 0.55), "c2": Color(0.4, 0.2, 0.55)},
	"karin_sargi_ust": {"name": "Kolsuz Kısa Üst ve Karın Sargısı", "slot": "govde", "price": 110, "rank": 0, "desc": "Boğazlı kolsuz kısa mor üst; karında beyaz sargı, belde yaprak plakalı mavi kemer.", "stats": {"speed": 0.03}, "look": {"top_style": "kolsuz", "top_pattern": 32, "belly_wraps": Color(0.94, 0.94, 0.92), "waist_belt": Color(0.2, 0.28, 0.6)}, "c1": Color(0.4, 0.2, 0.55), "c2": Color(0.4, 0.2, 0.55)},
	"inojin_ceket": {"name": "Kayışlı Kısa Ceket", "slot": "dis", "price": 220, "rank": 0, "desc": "Göğüs altında biten kısa kollu siyah ceket; omuzlarda kırmızı kayış bantları, dik yaka, fermuar.", "stats": {"speed": 0.04, "chakra": 10}, "look": {"outer_style": "inojin_ceket", "outer_pattern": 0, "holster": true}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.1, 0.1, 0.12)},
	"isshiki_palto": {"name": "Yüksek Yakalı Beyaz Palto", "slot": "dis", "price": 900, "rank": 2, "desc": "Dize inen önü açık beyaz palto; yüksek kırmızı yaka, kırmızı biye ve manşetler, geniş kollar; göğüste tomoe dizisi.", "stats": {"chakra": 45, "def": 3}, "look": {"outer_style": "isshiki_palto", "outer_pattern": 0, "holster": false}, "c1": Color(0.93, 0.93, 0.95), "c2": Color(0.62, 0.08, 0.14)},
	"itachi_tunik": {"name": "Kısa Kollu Tunik ve Kuşak", "slot": "dis", "price": 260, "rank": 0, "desc": "Uyluğa inen kısa kollu kutu tunik; önde V yaka, belde beyaz kuşak.", "stats": {"speed": 0.04, "chakra": 15}, "look": {"outer_style": "itachi_tunik", "outer_pattern": 0, "holster": false}, "c1": Color(0.2, 0.3, 0.55), "c2": Color(0.2, 0.3, 0.55)},
	"edo_cubbe": {"name": "Kapüşonlu Fermuarlı Cübbe", "slot": "dis", "price": 520, "rank": 2, "desc": "Baldıra inen bordo cübbe; boyunda haki astarlı kapüşon, ortada fermuar, altta yırtmaç, geniş kollar.", "stats": {"chakra": 35, "def": 3}, "look": {"outer_style": "edo_cubbe", "outer_pattern": 0, "holster": false}, "c1": Color(0.4, 0.08, 0.14), "c2": Color(0.7, 0.62, 0.45)},
	"kolsuz_trench": {"name": "Kolsuz Uzun Trençkot", "slot": "dis", "price": 320, "rank": 0, "desc": "Baldıra inen, önü boydan boya açık kolsuz lacivert trençkot.", "stats": {"def": 4, "speed": 0.02}, "look": {"outer_style": "kolsuz_trench", "outer_pattern": 0, "holster": true}, "c1": Color(0.12, 0.2, 0.3), "c2": Color(0.12, 0.2, 0.3)},
	"jigen_cubbe": {"name": "Şeritli Uzun Cübbe ve Kuşak", "slot": "dis", "price": 1200, "rank": 3, "desc": "Bileğe inen, belden aşağı açılan beyaz cübbe; etek ucunda ve geniş kol ağızlarında siyah şeritler, belde halkalı püsküllü kırmızı kuşak.", "stats": {"chakra": 50, "def": 4}, "look": {"outer_style": "jigen_cubbe", "outer_pattern": 0, "holster": false}, "c1": Color(0.93, 0.93, 0.92), "c2": Color(0.08, 0.08, 0.1)},
	"sennin_yelek": {"name": "Benekli Uzun Yelek", "slot": "dis", "price": 700, "rank": 2, "desc": "Dize inen önü açık kolsuz kırmızı yelek; göğüste iki sarı yuvarlak.", "stats": {"chakra": 35, "def": 4}, "look": {"outer_style": "sennin_yelek", "outer_pattern": 0, "holster": false}, "c1": Color(0.66, 0.12, 0.14), "c2": Color(0.95, 0.8, 0.25)},
	"kaguya_kimono": {"name": "Çan Kollu Yer Kimonosu", "slot": "dis", "price": 1500, "rank": 3, "desc": "Yere inen çan etekli beyaz kimono; çapraz sarı-mor kuşak, önde siyah düğmeler, etek ucu ve kol ağızlarında sarı-mor biye.", "stats": {"chakra": 60}, "look": {"outer_style": "kaguya_kimono", "outer_pattern": 0, "holster": false}, "c1": Color(0.95, 0.94, 0.92), "c2": Color(0.95, 0.94, 0.92)},
	"rokudaime_cubbe": {"name": "Altıncı Kage Cübbesi", "slot": "dis", "price": 0, "rank": 6, "desc": "Bileğe inen önü kapalı kırık beyaz cübbe; boyunda kalın sargı yaka, bileğe inen geniş kollar.", "stats": {"def": 10, "chakra": 60, "hp": 40}, "look": {"outer_style": "rokudaime_cubbe", "outer_pattern": 0, "holster": false}, "c1": Color(0.9, 0.9, 0.88), "c2": Color(0.9, 0.9, 0.88)},
	"kawaki_palto": {"name": "Kolsuz Uzun Palto (Yakalı)", "slot": "dis", "price": 420, "rank": 1, "desc": "Dize inen önü açık kolsuz mavi palto; açık mavi geniş yaka ve pervaz.", "stats": {"def": 4, "speed": 0.02}, "look": {"outer_style": "kawaki_palto", "outer_pattern": 0, "holster": true}, "c1": Color(0.16, 0.3, 0.6), "c2": Color(0.5, 0.65, 0.85)},
	"kawaki_okul": {"name": "Kolsuz Geniş Etekli Palto", "slot": "dis", "price": 380, "rank": 0, "desc": "Kalçadan aşağı A açılan, dizin altına inen önü açık kolsuz mavi palto; açık mavi pervaz.", "stats": {"def": 4, "speed": 0.02}, "look": {"outer_style": "kawaki_okul", "outer_pattern": 0, "holster": true}, "c1": Color(0.2, 0.36, 0.6), "c2": Color(0.5, 0.65, 0.85)},
	"kawaki_ruro": {"name": "Kolsuz Gezgin Yeleği ve Atkı", "slot": "dis", "price": 220, "rank": 0, "desc": "Dize inen önü açık kolsuz koyu mor yelek; boyunda mor atkı.", "stats": {"def": 3, "speed": 0.03}, "look": {"outer_style": "kawaki_ruro", "outer_pattern": 0, "holster": true}, "c1": Color(0.22, 0.2, 0.32), "c2": Color(0.3, 0.22, 0.4)},
	"kukla_onluk": {"name": "Bel Önlüğü ve Kayışlar", "slot": "dis", "price": 240, "rank": 0, "desc": "Belden uyluğa inen siyah önlük, kırmızı kuşak; göğüste sırt çantasının beyaz omuz kayışları.", "stats": {"def": 3, "chakra": 15}, "look": {"outer_style": "kukla_onluk", "outer_pattern": 0, "holster": false}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.55, 0.1, 0.16)},
	"kaguya_cubbe": {"name": "Yere İnen Açık Beyaz Cübbe", "slot": "dis", "price": 1500, "rank": 3, "desc": "Omuzdan yere inen, önü giderek açılan bembeyaz cübbe; önde ince siyah çizgiler, bileği örten geniş kollar.", "stats": {"chakra": 60}, "look": {"outer_style": "kaguya_cubbe", "outer_pattern": 0, "holster": false}, "c1": Color(0.96, 0.96, 0.95), "c2": Color(0.96, 0.96, 0.95)},
	"haku_yukata": {"name": "Girdap Benekli Yukata", "slot": "dis", "price": 300, "rank": 0, "desc": "Diz altına inen soluk pembe yukata; önde çapraz kırmızı yaka şeridi, beyaz obi, koyu girdap benekleri.", "stats": {"chakra": 25}, "look": {"outer_style": "haku_yukata", "outer_pattern": 0, "holster": false}, "c1": Color(0.95, 0.86, 0.87), "c2": Color(0.85, 0.35, 0.35)},
	"savas_cubbe": {"name": "Dik Yakalı Savaş Cübbesi", "slot": "dis", "price": 900, "rank": 2, "desc": "Baldıra inen, kalçadan aşağı açılan koyu cübbe; yüksek dik yaka, çan gibi açılan geniş kollar.", "stats": {"chakra": 40, "def": 5}, "look": {"outer_style": "savas_cubbe", "outer_pattern": 0, "holster": false}, "c1": Color(0.16, 0.18, 0.38), "c2": Color(0.16, 0.18, 0.38)},
	"savas_cubbe_obi": {"name": "Obili Genç Savaşçı Cübbesi", "slot": "dis", "price": 700, "rank": 1, "desc": "Baldıra inen mor cübbe; belde geniş gri obi, yüksek dik yaka, geniş kollar.", "stats": {"chakra": 35, "def": 4}, "look": {"outer_style": "savas_cubbe", "outer_pattern": 0, "holster": false, "robe_obi": Color(0.6, 0.58, 0.62)}, "c1": Color(0.4, 0.3, 0.5), "c2": Color(0.4, 0.3, 0.5)},
	"mei_elbise": {"name": "Yırtmaçlı Uzun Mavi Elbise", "slot": "dis", "price": 800, "rank": 2, "desc": "Omuzları açık, bileğe inen mavi elbise; sağ bacakta yırtmaç, açık sarı ince kemer, çan kollar.", "stats": {"chakra": 40}, "look": {"outer_style": "mei_elbise", "outer_pattern": 0, "holster": false}, "c1": Color(0.12, 0.3, 0.8), "c2": Color(0.12, 0.3, 0.8)},
	"savas_cubbe_kurucu": {"name": "Kızıl Şeritli Kurucu Cübbesi", "slot": "dis", "price": 900, "rank": 2, "desc": "Baldıra inen dik yakalı siyah cübbe; önden inen ince kızıl şerit, belde gri obi, geniş kollar.", "stats": {"chakra": 45, "def": 4}, "look": {"outer_style": "savas_cubbe", "outer_pattern": 0, "holster": false, "robe_obi": Color(0.55, 0.56, 0.6), "robe_stripe": Color(0.75, 0.1, 0.12)}, "c1": Color(0.08, 0.08, 0.1), "c2": Color(0.08, 0.08, 0.1)},
	"hokage_haori": {"name": "Alev Etekli Kısa Kollu Haori", "slot": "dis", "price": 1400, "rank": 3, "desc": "Dize inen önü açık beyaz haori; dirseğe inen kısa kollar, eteği kızıl alev desenli.", "stats": {"chakra": 45, "def": 4}, "look": {"outer_style": "hokage_haori", "outer_pattern": 2, "holster": true}, "c1": Color(0.94, 0.93, 0.9), "c2": Color(0.85, 0.18, 0.12)},
	"bel_ceket": {"name": "Bele Bağlı Ceket", "slot": "dis", "price": 120, "rank": 0, "desc": "Kollarından bele bağlanmış turuncu eşofman ceketi; önde düğüm ve sarkan kollar.", "stats": {"speed": 0.04}, "look": {"outer_style": "bel_ceket", "outer_pattern": 0, "holster": false}, "c1": Color(0.95, 0.45, 0.2), "c2": Color(0.95, 0.45, 0.2)},
	"yilan_tunik": {"name": "Kısa Kollu Tunik ve Burgu Kuşak", "slot": "dis", "price": 300, "rank": 0, "desc": "Uyluğa inen kısa kollu krem tunik; belde kalın mor burgu ip kuşak.", "stats": {"chakra": 25}, "look": {"outer_style": "itachi_tunik", "outer_pattern": 0, "holster": false, "tunic_belt": Color(0.45, 0.3, 0.7)}, "c1": Color(0.9, 0.86, 0.74), "c2": Color(0.9, 0.86, 0.74)},
	"cin_elbise": {"name": "Halkalı Çin Elbisesi", "slot": "dis", "price": 260, "rank": 0, "desc": "Dize inen, iki yanı yırtmaçlı kırmızı çin elbisesi; önde altta beyaz halka, beyaz biye.", "stats": {"speed": 0.04, "hp": 10}, "look": {"outer_style": "cin_elbise", "outer_pattern": 0, "holster": true}, "c1": Color(0.7, 0.1, 0.18), "c2": Color(0.7, 0.1, 0.18)},
	"sarada_elbise": {"name": "V Yakalı Kolsuz Mini Elbise", "slot": "dis", "price": 220, "rank": 0, "desc": "Uyluk ortasına inen kolsuz A elbise; derin V yaka, belde sarkan beyaz kemer.", "stats": {"speed": 0.05}, "look": {"outer_style": "sarada_elbise", "outer_pattern": 0, "holster": true}, "c1": Color(0.3, 0.55, 0.85), "c2": Color(0.3, 0.55, 0.85)},
	"kolsuz_mini_obi": {"name": "Kolsuz Kruvaze Mini Elbise ve Obi", "slot": "dis", "price": 240, "rank": 0, "desc": "Uyluk ortasına inen kolsuz kızıl kruvaze elbise; belde geniş siyah obi.", "stats": {"speed": 0.04, "melee": 0.03}, "look": {"outer_style": "sarada_elbise", "outer_pattern": 0, "holster": true, "robe_obi": Color(0.08, 0.08, 0.1)}, "c1": Color(0.55, 0.1, 0.14), "c2": Color(0.55, 0.1, 0.14)},
	"gezgin_palto": {"name": "Dik Yakalı Gezgin Paltosu", "slot": "dis", "price": 420, "rank": 1, "desc": "Dize inen önü kapalı gri palto; dik yaka, dar uzun kollar, altta kısa yırtmaç.", "stats": {"def": 4, "speed": 0.03}, "look": {"outer_style": "gezgin_palto", "outer_pattern": 0, "holster": false}, "c1": Color(0.3, 0.3, 0.32), "c2": Color(0.3, 0.3, 0.32)},
	"bel_ortusu_mikoshi": {"name": "Bayram Bel Örtüsü ve Altın İp", "slot": "dis", "price": 320, "rank": 0, "desc": "Belden dize sarılı kızıl örtü; belde kalın altın burgu ip.", "stats": {"melee": 0.05, "def": 3}, "look": {"outer_style": "bel_ortusu", "outer_pattern": 0, "holster": false, "rope": Color(0.85, 0.65, 0.25), "wristband": Color(0.1, 0.1, 0.12)}, "c1": Color(0.7, 0.12, 0.12), "c2": Color(0.7, 0.12, 0.12)},
	"kolsuz_mini_obi_kizil": {"name": "Kruvaze Tunik Elbise ve Kızıl Kuşak", "slot": "dis", "price": 220, "rank": 0, "desc": "Uyluk ortasına inen kruvaze soluk pembe tunik elbise; belde kızıl kuşak.", "stats": {"speed": 0.04}, "look": {"outer_style": "sarada_elbise", "outer_pattern": 0, "holster": true, "robe_obi": Color(0.7, 0.2, 0.22)}, "c1": Color(0.92, 0.82, 0.86), "c2": Color(0.92, 0.82, 0.86)},
	"yagura_ortu": {"name": "Başlık ve Sargı Bel Örtüsü", "slot": "dis", "price": 650, "rank": 2, "desc": "Omuzlara dökülen kalın yosun yeşili başlık ve belden dize inen bindirmeli sargı örtü; sarkan uçlu turkuaz kuşak, göğüste çapraz kayış ve plaka.", "stats": {"chakra": 35, "def": 4}, "look": {"outer_style": "yagura_ortu", "outer_pattern": 0, "holster": false, "sash": Color(0.2, 0.5, 0.42)}, "c1": Color(0.36, 0.42, 0.2), "c2": Color(0.36, 0.42, 0.2)},
	"tisort_file_kol": {"name": "File Kollu Tişört", "slot": "govde", "price": 90, "rank": 0, "desc": "Gövdesi düz, kısa kolları file örgü tişört.", "stats": {"speed": 0.03}, "look": {"top_style": "tisort", "top_pattern": 44}, "c1": Color(0.3, 0.3, 0.42), "c2": Color(0.3, 0.3, 0.42)},
	"kolsuz_ust": {"name": "Geniş Askılı Kolsuz Üst", "slot": "govde", "price": 60, "rank": 0, "desc": "Geniş askılı düz kolsuz üst.", "stats": {"speed": 0.03, "melee": 0.02}, "look": {"top_style": "kolsuz"}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.1, 0.1, 0.12)},
	"onu_sarkan_atki": {"name": "Ucu Önde Sarkan Atkı", "slot": "dis", "price": 70, "rank": 0, "desc": "Boyna sarılı beyaz atkı; bir ucu önde göğse sarkar.", "stats": {"speed": 0.01}, "look": {"outer_style": "atki", "scarf_front_tail": true}, "c1": Color(0.9, 0.9, 0.92), "c2": Color(0.9, 0.9, 0.92)},
	"cizgili_isitici": {"name": "Çizgili Kol Isıtıcı ve Tozluk", "slot": "kol", "price": 90, "rank": 0, "desc": "Dirsekten ele uzanan çizgili örgü kol ısıtıcı ve bilekte çizgili tozluk.", "stats": {"def": 2, "speed": 0.02}, "look": {"guards": "ikisi", "guard_long": true, "guard_ankle": true, "guard_stripes": Color(0.45, 0.52, 0.7)}, "c1": Color(0.66, 0.74, 0.9)},
	"cepli_gomlek": {"name": "Cepli İş Gömleği ve Fular", "slot": "govde", "price": 140, "rank": 0, "desc": "Kısa kollu, kapaklı iki göğüs cepli gömlek; boyunda açık mavi fular, siyah kemer.", "stats": {"def": 2, "chakra": 10}, "look": {"top_style": "yakali", "chest_pockets": true, "neck_scarf": Color(0.55, 0.78, 0.92), "waist_belt": Color(0.12, 0.1, 0.1)}, "c1": Color(0.2, 0.35, 0.72), "c2": Color(0.2, 0.35, 0.72)},
	"kabarik_bluz": {"name": "Dik Boğazlı Kabarık Bluz", "slot": "dis", "price": 320, "rank": 0, "desc": "Uzun dik boğazlı, bele kadar bol beyaz bluz; balon kollar, bileklerde üçer mavi bilezik.", "stats": {"chakra": 30}, "look": {"outer_style": "kabarik_bluz", "outer_pattern": 0, "holster": false}, "c1": Color(0.96, 0.96, 0.97), "c2": Color(0.96, 0.96, 0.97)},
	"gezegen_sort": {"name": "Gezegen Baskılı Yüksek Bel Şort", "slot": "bacak", "price": 120, "rank": 0, "desc": "Siyah yüksek bel kısa şort; yeşil gezegen, yıldız ve hilal baskılı.", "stats": {"speed": 0.04}, "look": {"pants_style": "kisa_sort", "pants_pattern": 30}, "c1": Color(0.16, 0.16, 0.18), "c2": Color(0.4, 0.75, 0.65)},
	"kurbaga_kigurumi": {"name": "Kurbağa Kostümü", "slot": "dis", "price": 500, "rank": 0, "desc": "Boğazdan bileğe tüm vücudu saran kabarık yeşil kurbağa tulumu.", "stats": {"hp": 40}, "look": {"outer_style": "kurbaga_kigurumi", "outer_pattern": 0, "holster": false}, "c1": Color(0.32, 0.68, 0.3), "c2": Color(0.32, 0.68, 0.3)},
	"file_bant_ust": {"name": "File Bantlı Kısa Üst ve Kol Bandı", "slot": "govde", "price": 120, "rank": 0, "desc": "Askılı beyaz kısa üst, altında file bant; sağ üst kolda plakalı mavi bant.", "stats": {"speed": 0.04}, "look": {"top_style": "kolsuz", "top_pattern": 40, "armband": Color(0.15, 0.2, 0.4), "armband_side": -1.0}, "c1": Color(0.96, 0.96, 0.96), "c2": Color(0.96, 0.96, 0.96)},
	"seytan_kapuson": {"name": "Çivili Kısa Kapüşonlu", "slot": "dis", "price": 260, "rank": 0, "desc": "Belin üstünde biten kırmızı kapüşonlu; önde iki sıra çivi, yıldız uçlu fermuar, gri çizgili kemer, sarkan zincir.", "stats": {"melee": 0.05, "speed": 0.03}, "look": {"outer_style": "seytan_kapuson", "outer_pattern": 0, "holster": false}, "c1": Color(0.72, 0.12, 0.14), "c2": Color(0.72, 0.12, 0.14)},
	"civili_sort": {"name": "Çivili Diz Şortu", "slot": "bacak", "price": 90, "rank": 0, "desc": "Dize inen şort; yan dikişlerde çivi sırası.", "stats": {"speed": 0.03}, "look": {"pants_style": "sort", "pants_pattern": 28}, "c1": Color(0.72, 0.12, 0.14)},
	"danzo_ortu": {"name": "Bej Örtü ve Sargılı Kol", "slot": "dis", "price": 420, "rank": 3, "desc": "Belin önüne çapraz sarılı büyük bej bez; sağ kol baştan sona sargılı, bilekte altın halka, mor kuşağın sarkan uçları.", "stats": {"chakra": 30, "def": 4}, "look": {"outer_style": "danzo_ortu", "outer_pattern": 0, "holster": false, "kok_reisi": Color(0.62, 0.55, 0.75)}, "c1": Color(0.9, 0.85, 0.72), "c2": Color(0.9, 0.85, 0.72)},
	"delta_elbise": {"name": "Omzu Açık Balon Kollu Elbise", "slot": "dis", "price": 380, "rank": 0, "desc": "Dik yakalı, göğsü anahtar delikli soluk mavi mini elbise; omuzlar açık, balon kollar, geniş beyaz manşetler, sırtta pembe üçgen.", "stats": {"chakra": 30, "speed": 0.03}, "look": {"outer_style": "delta_elbise", "outer_pattern": 0, "holster": false}, "c1": Color(0.45, 0.6, 0.66), "c2": Color(0.45, 0.6, 0.66)},
	"cizgili_tayt": {"name": "Çizgili Tayt", "slot": "bacak", "price": 90, "rank": 0, "desc": "Siyah-pembe dikey çizgili tayt.", "stats": {"speed": 0.03}, "look": {"pants_style": "sivil", "pants_pattern": 29}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.85, 0.45, 0.55)},
	"uzun_cizme_beyaz": {"name": "Uyluk Boyu Çizme", "slot": "ayak", "price": 220, "rank": 0, "desc": "Uyluğa çıkan, burnu açık beyaz çizme.", "stats": {"speed": 0.03, "def": 2}, "look": {"foot_style": "shinobi", "anbu_leg": "cizme_ust"}, "c1": Color(0.94, 0.94, 0.96), "c2": Color(0.94, 0.94, 0.96)},
	"kutlama_kimono": {"name": "Kutlama Kimonosu", "slot": "dis", "price": 900, "rank": 2, "desc": "Baldıra inen alev desenli kırmızı kimono; mavi kenarlar, belden aşağı açılır; kürk atkı, sol omuzluk, siyah ve bej ip kuşak, sarkan ip ilmeği, mavi boncuklu püsküller.", "stats": {"chakra": 40, "def": 5}, "look": {"outer_style": "kutlama_kimono", "outer_pattern": 41, "holster": false, "fur_scarf": Color(0.95, 0.95, 0.94)}, "c1": Color(0.78, 0.14, 0.12), "c2": Color(0.18, 0.3, 0.7)},
	"bulut_hakama": {"name": "Bulut Desenli Hakama", "slot": "bacak", "price": 340, "rank": 0, "desc": "Bileğe inen lacivert hakama; etek ucunda gümüş bulut girdapları.", "stats": {"def": 3}, "look": {"pants_style": "sivil", "hakama": true, "pants_pattern": 26}, "c1": Color(0.16, 0.22, 0.55), "c2": Color(0.78, 0.8, 0.86)},
	"kolsuz_kimono": {"name": "Kolsuz Kimono Üst ve Obi", "slot": "dis", "price": 240, "rank": 0, "desc": "Belin altına inen kolsuz beyaz kimono üst; geniş turuncu obi ve önde büyük fiyonk, ince kahve kemer, sırtta sarı çanta.", "stats": {"hp": 25, "chakra": 10}, "look": {"outer_style": "kolsuz_kimono", "outer_pattern": 37, "holster": false}, "c1": Color(0.96, 0.96, 0.96), "c2": Color(0.96, 0.96, 0.96)},
	"takim_yelek": {"name": "Takım Yeleği ve Kravat", "slot": "dis", "price": 300, "rank": 0, "desc": "Belin altına inen siyah takım yeleği, solda dikey lila şerit, boyunda katlı beyaz kravat.", "stats": {"chakra": 20, "def": 2}, "look": {"outer_style": "takim_yelek", "outer_pattern": 42, "holster": false}, "c1": Color(0.14, 0.14, 0.17), "c2": Color(0.62, 0.5, 0.78)},
	"can_manset_gomlek": {"name": "Çan Manşetli Gömlek ve Pantolon Paçası", "slot": "govde", "price": 220, "rank": 0, "desc": "Dik yakalı koyu gömlek; bilekte geniş lila çan manşet, pantolonda lila çan paça.", "stats": {"speed": 0.03}, "look": {"top_style": "yakali_uzun", "bell_cuffs": Color(0.68, 0.56, 0.82)}, "c1": Color(0.16, 0.16, 0.2), "c2": Color(0.16, 0.16, 0.2)},
	"shimenawa_ip": {"name": "Shimenawa Fiyonku", "slot": "kol", "price": 200, "rank": 0, "desc": "Zırhın önüne bağlanan kalın beyaz burgu ipten büyük fiyonk.", "stats": {"def": 2, "chakra": 15}, "look": {"shimenawa": Color(0.95, 0.94, 0.9)}, "c1": Color(0.95, 0.94, 0.9)},
	"uzun_trench": {"name": "Uzun Trençkot", "slot": "dis", "price": 380, "rank": 0, "desc": "Dize inen önü açık açık kahve trençkot; açık dik yaka, kalçada torba cepler, bilekte geniş katlı manşet.", "stats": {"def": 4, "speed": 0.03}, "look": {"outer_style": "uzun_trench", "outer_pattern": 0, "holster": false}, "c1": Color(0.85, 0.75, 0.58), "c2": Color(0.85, 0.75, 0.58)},
	"file_govde": {"name": "File Tulum, Kemer ve Kolye", "slot": "govde", "price": 160, "rank": 0, "desc": "Gövde ve bacakları saran file tulum; belde siyah kemer, boyunda kırmızı kolye.", "stats": {"speed": 0.04, "def": 2}, "look": {"top_style": "tisort", "top_pattern": 1, "leg_fishnet": true, "waist_belt": Color(0.12, 0.1, 0.1), "necklace": Color(0.75, 0.12, 0.14)}, "c1": Color(0.3, 0.26, 0.22), "c2": Color(0.3, 0.26, 0.22)},
	"kaval_sandalet": {"name": "Kavallı Sandalet", "slot": "ayak", "price": 140, "rank": 0, "desc": "Açık burunlu lacivert sandalet ve dize kadar açık kahve kaval koruyucu.", "stats": {"def": 3, "speed": 0.02}, "look": {"foot_style": "shinobi", "guards": "bacak", "acc": Color(0.85, 0.78, 0.7)}, "c1": Color(0.15, 0.2, 0.35), "c2": Color(0.15, 0.2, 0.35)},
	"jonin_aks": {"name": "Jōnin Sargıları ve 火 Örtüsü", "slot": "kol", "price": 160, "rank": 3, "desc": "Üst kollarda beyaz sargı bandı ve omuzda kırmızı girdap, belde sarkan 火 işaretli açık mavi üçgen örtü, mavi bilezikler.", "stats": {"chakra": 20, "def": 2}, "look": {"jonin_aks": Color(0.94, 0.94, 0.92), "fire_sash": Color(0.75, 0.85, 0.95)}, "c1": Color(0.94, 0.94, 0.92)},
	"rikudo_cubbe": {"name": "Rikudō Cübbesi", "slot": "dis", "price": 900, "rank": 2, "desc": "Yüksek yakalı, bileğe inen beyaz cübbe; göğüste altı, sırtta dokuz tomoe, geniş lacivert obi, çok geniş kollar.", "stats": {"chakra": 50, "def": 4}, "look": {"outer_style": "rikudo_cubbe", "outer_pattern": 39, "holster": false}, "c1": Color(0.93, 0.93, 0.95), "c2": Color(0.93, 0.93, 0.95)},
	"yirtik_esofman": {"name": "Yırtık Eşofman Ceketi", "slot": "dis", "price": 200, "rank": 0, "desc": "Önü açık, eteği dişli yırtık siyah eşofman ceketi; kollarda üç kırmızı bant.", "stats": {"speed": 0.05, "melee": 0.03}, "look": {"outer_style": "yirtik_esofman", "outer_pattern": 40, "holster": false}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.78, 0.14, 0.2)},
	"esofman_alti_bant": {"name": "Bantlı Eşofman Altı", "slot": "bacak", "price": 90, "rank": 0, "desc": "Baldır altında biten siyah eşofman altı; paçada iki kırmızı bant.", "stats": {"speed": 0.03}, "look": {"pants_style": "kapri", "pants_pattern": 25}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.78, 0.14, 0.2)},
	"gunes_kimono": {"name": "Güneş Kimonosu", "slot": "dis", "price": 640, "rank": 1, "desc": "Sol omzu açık, sağ omuzdan sarılı turuncu kutlama kimonosu; göğüste alevli güneş, desenli kenar, siyah kuşakta 9 parlak magatama, yanda sarkan kızıl bez.", "stats": {"chakra": 40, "hp": 20}, "look": {"outer_style": "gunes_kimono", "outer_pattern": 38, "holster": false, "gk": {"cloth": Color(0.8, 0.12, 0.12)}}, "c1": Color(0.95, 0.68, 0.2), "c2": Color(0.85, 0.42, 0.1)},
	"gunes_kimono_beyaz": {"name": "Güneş Kimonosu: Yirminci Yıl", "slot": "dis", "price": 640, "rank": 1, "desc": "Sol omzu açık turuncu kimono; göğüste alevli güneş, siyah kuşakta 9 parlak magatama, yanda sarkan beyaz-lila bez, sarı omuz düğümü.", "stats": {"chakra": 30, "speed": 0.04}, "look": {"outer_style": "gunes_kimono", "outer_pattern": 38, "holster": false, "gk": {"cloth": Color(0.92, 0.9, 0.96), "knot": Color(0.95, 0.8, 0.3)}}, "c1": Color(0.92, 0.48, 0.18), "c2": Color(0.75, 0.25, 0.1)},
	"genis_gomlek": {"name": "Bol Geniş Yakalı Gömlek", "slot": "dis", "price": 220, "rank": 0, "desc": "Kalçaya inen bol siyah gömlek; geniş açık yaka, ön kol ortasına bol kollar, altın zincir kolye.", "stats": {"chakra": 20}, "look": {"outer_style": "genis_gomlek", "outer_pattern": 0, "holster": false}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.1, 0.1, 0.12)},
	"kuyruklu_ceket": {"name": "Kuyruklu Ceket", "slot": "dis", "price": 320, "rank": 0, "desc": "Önü bele kadar açık, arkası dize inen açık sarı ceket; dirsek boyu kollar, açık dik yaka.", "stats": {"chakra": 25, "def": 2}, "look": {"outer_style": "kuyruklu_ceket", "outer_pattern": 0, "holster": false}, "c1": Color(0.9, 0.82, 0.55), "c2": Color(0.9, 0.82, 0.55)},
	"v_tulum": {"name": "Derin V Yakalı Tulum Üstü ve Kolye", "slot": "govde", "price": 120, "rank": 0, "desc": "Uzun kollu, derin V yakalı tulum üstü; boyunda halkalı kolye.", "stats": {"def": 2, "chakra": 10}, "look": {"top_style": "uzun", "top_pattern": 37, "necklace": Color(0.8, 0.82, 0.85)}, "c1": Color(0.12, 0.16, 0.3), "c2": Color(0.12, 0.16, 0.3)},
	"kisa_kimono": {"name": "Kısa Kimono", "slot": "dis", "price": 280, "rank": 0, "desc": "Uyluk ortasına inen lacivert kısa kimono; geniş kollar, açık çizgili koyu obi, pembe ip.", "stats": {"chakra": 20, "speed": 0.04}, "look": {"outer_style": "kisa_kimono", "outer_pattern": 37, "holster": false}, "c1": Color(0.18, 0.3, 0.75), "c2": Color(0.18, 0.3, 0.75)},
	"cin_ust": {"name": "Çin Tarzı Üst", "slot": "govde", "price": 160, "rank": 0, "desc": "Dik yakalı beyaz üst; yakadan sağ koltuğa inen kırmızı biye, düğüm düğmeler, kırmızı etek bandı ve kıvrık manşetler, mavi bilezik.", "stats": {"melee": 0.04, "speed": 0.03}, "look": {"top_style": "uzun", "cin_ust": Color(0.78, 0.14, 0.14)}, "c1": Color(0.96, 0.96, 0.95), "c2": Color(0.96, 0.96, 0.95)},
	"panel_etek": {"name": "Yırtmaçlı Panel Etek", "slot": "dis", "price": 180, "rank": 0, "desc": "İki yanı yırtmaçlı, önde ve arkada ayrı panelli kısa etek.", "stats": {"speed": 0.05}, "look": {"outer_style": "panel_etek", "outer_pattern": 0}, "c1": Color(0.92, 0.72, 0.8), "c2": Color(0.92, 0.72, 0.8)},
	"uzun_panel_ust": {"name": "Yırtmaçlı Uzun Üst", "slot": "dis", "price": 240, "rank": 0, "desc": "Kolsuz, uyluğa inen yırtmaçlı üst; S kıvrımlı fermuar, beyaz biyeli etek, sırtında Uchiha yelpazesi.", "stats": {"speed": 0.04, "chakra": 10}, "look": {"outer_style": "uzun_panel_ust", "outer_pattern": 36}, "c1": Color(0.85, 0.3, 0.3), "c2": Color(0.85, 0.3, 0.3)},
	"bel_ortusu": {"name": "Bel Örtüsü ve İp Kuşak", "slot": "dis", "price": 320, "rank": 0, "desc": "Belden dize sarılı lacivert örtü; belde mor burgu ip, önde sarkan iki ip ilmeği, bilekte ter bandı.", "stats": {"melee": 0.05, "def": 3}, "look": {"outer_style": "bel_ortusu", "outer_pattern": 0, "holster": false, "rope": Color(0.55, 0.45, 0.82), "wristband": Color(0.14, 0.16, 0.36)}, "c1": Color(0.16, 0.18, 0.42), "c2": Color(0.16, 0.18, 0.42)},
	"kolsuz_palto": {"name": "Kolsuz Palto", "slot": "dis", "price": 300, "rank": 0, "desc": "Uyluğa inen açık mavi kolsuz palto; önden yırtmaçlı, çapraz ince kayışlı.", "stats": {"speed": 0.04, "def": 3}, "look": {"outer_style": "kolsuz_palto", "outer_pattern": 0, "holster": false}, "c1": Color(0.7, 0.8, 0.92), "c2": Color(0.7, 0.8, 0.92)},
	"onluk_elbise": {"name": "Uzun Önlük Elbise", "slot": "dis", "price": 260, "rank": 0, "desc": "Kolsuz, oval yakalı, baldıra inen yeşil önlük elbise; sol bilekte siyah bilezik.", "stats": {"hp": 30}, "look": {"outer_style": "onluk_elbise", "outer_pattern": 0, "holster": false, "bangle": Color(0.08, 0.08, 0.1)}, "c1": Color(0.15, 0.3, 0.2), "c2": Color(0.15, 0.3, 0.2)},
	"iki_ton_kimono": {"name": "İki Tonlu Kimono Üst", "slot": "dis", "price": 340, "rank": 0, "desc": "Sağ yarısı beyaz, sol yarısı mavi uyluk boyu kimono üst; çok geniş kollar, beyaz yaka bandı, hilal plakalı geniş kahve kuşak, sırtta çanta.", "stats": {"chakra": 25, "speed": 0.03}, "look": {"outer_style": "iki_ton_kimono", "outer_pattern": 34, "holster": false}, "c1": Color(0.15, 0.45, 0.8), "c2": Color(0.86, 0.9, 0.94)},
	"turuncu_ceket": {"name": "Turuncu Eşofman Ceketi", "slot": "dis", "price": 280, "rank": 0, "desc": "Fermuarı kapalı turuncu-siyah eşofman ceketi; dik siyah yaka, sırtta girdap, sol omuzda arma yaması.", "stats": {"hp": 20, "speed": 0.04}, "look": {"outer_style": "turuncu_ceket", "outer_pattern": 35, "holster": true}, "c1": Color(0.95, 0.52, 0.12), "c2": Color(0.12, 0.12, 0.16)},
	"kisa_bolero": {"name": "Kısa Bolero Ceket", "slot": "dis", "price": 260, "rank": 0, "desc": "Göbek üstünde biten önü açık lacivert-mor ceket; omuzlarda kırmızı şerit, beyaz-kırmızı kemer, kalçada parşömen.", "stats": {"chakra": 20, "speed": 0.04}, "look": {"outer_style": "kisa_bolero", "outer_pattern": 0, "holster": true}, "c1": Color(0.14, 0.14, 0.26), "c2": Color(0.14, 0.14, 0.26)},
	"fermuarli_gomlek": {"name": "Fermuarlı Dik Yaka Gömlek", "slot": "govde", "price": 110, "rank": 0, "desc": "Uzun kollu, dik yakalı, önü fermuarlı gömlek.", "stats": {"def": 2}, "look": {"top_style": "yakali_uzun", "top_pattern": 35}, "c1": Color(0.95, 0.95, 0.95), "c2": Color(0.95, 0.95, 0.95)},
	"yilan_cubbe": {"name": "Kapüşonlu Uzun Cübbe", "slot": "dis", "price": 480, "rank": 0, "desc": "Bileğe inen koyu kırmızı cübbe; boyunda toplu kapüşon, önde beyaz şerit, gri-yeşil astarlı çok geniş çan kollar.", "stats": {"chakra": 30, "def": 3}, "look": {"outer_style": "yilan_cubbe", "outer_pattern": 0, "holster": false, "lining": Color(0.55, 0.6, 0.55)}, "c1": Color(0.4, 0.08, 0.12), "c2": Color(0.55, 0.6, 0.55)},
	"algi_ceket": {"name": "Kemerli Uzun Ceket", "slot": "dis", "price": 300, "rank": 0, "desc": "Dik yakalı dar uzun ceket; kemerden aşağı önü açılır, gri kemer ve sırtta gri çanta.", "stats": {"chakra": 20, "speed": 0.03}, "look": {"outer_style": "algi_ceket", "outer_pattern": 0, "holster": false}, "c1": Color(0.72, 0.62, 0.85), "c2": Color(0.72, 0.62, 0.85)},
	"sargi_elbise": {"name": "Sargı Elbise", "slot": "dis", "price": 360, "rank": 0, "desc": "Gövdeyi çapraz saran beyaz sargı bantlarından kısa elbise; bant kenarlarında koyu dikenli şerit.", "stats": {"chakra": 25, "speed": 0.03}, "look": {"outer_style": "sargi_elbise", "outer_pattern": 0, "holster": false}, "c1": Color(0.95, 0.95, 0.94), "c2": Color(0.1, 0.08, 0.1)},
	"tek_kol_file": {"name": "Tek Kollu File Üst", "slot": "govde", "price": 140, "rank": 0, "desc": "Gövdesi file, yalnız sağ kolu kırmızı kumaş üst.", "stats": {"chakra": 15, "speed": 0.02}, "look": {"top_style": "tek_kol", "top_pattern": 34}, "c1": Color(0.66, 0.13, 0.16), "c2": Color(0.66, 0.13, 0.16)},
	"boyun_atki": {"name": "Boyun Atkısı ve Kol Bandı", "slot": "kol", "price": 80, "rank": 0, "desc": "Boyna sarılı mavi atkı (önde düğüm) ve sol kolda kırmızı bant.", "stats": {"chakra": 10}, "look": {"neck_scarf": Color(0.15, 0.5, 0.85), "armband": Color(0.7, 0.1, 0.12)}, "c1": Color(0.15, 0.5, 0.85)},
	"corap_bot": {"name": "Uzun Çoraplı Bot", "slot": "ayak", "price": 120, "rank": 0, "desc": "Diz üstü koyu çorap ve açık burunlu siyah bot.", "stats": {"speed": 0.04}, "look": {"foot_style": "shinobi", "foot_pattern": 11, "anbu_leg": "corap_dz"}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.18, 0.14, 0.12)},
	"hinata_ceket": {"name": "Kapüşonlu Bol Ceket", "slot": "dis", "price": 300, "rank": 0, "desc": "Lavanta önlü, beyaz yanlı ve kollu bol ceket; boynu saran dolgun kapüşon yakası, geniş uzun kollar, fermuar.", "stats": {"chakra": 20, "def": 3}, "look": {"outer_style": "hinata_ceket", "outer_pattern": 31}, "c1": Color(0.62, 0.58, 0.85), "c2": Color(0.95, 0.95, 0.96)},
	"kirpik_kapusonlu": {"name": "Kısa Kapüşonlu", "slot": "dis", "price": 260, "rank": 0, "desc": "Belin üstünde biten kısa kollu pembe kapüşonlu; ponponlu büzgü ipleri, altında lavanta iç giysi bandı.", "stats": {"speed": 0.04, "chakra": 10}, "look": {"outer_style": "kirpik_kapusonlu", "outer_pattern": 32, "holster": false, "under_band": Color(0.55, 0.42, 0.72)}, "c1": Color(0.9, 0.78, 0.9), "c2": Color(0.9, 0.78, 0.9)},
	"yirtmacli_etek": {"name": "Yırtmaçlı Etek", "slot": "dis", "price": 220, "rank": 0, "desc": "Önü yırtmaçlı diz üstü mor etek; içinde gri iç etek.", "stats": {"speed": 0.05}, "look": {"outer_style": "yirtmacli_etek", "outer_pattern": 0}, "c1": Color(0.45, 0.2, 0.62), "c2": Color(0.45, 0.2, 0.62)},
	"sargi_etek_uzun": {"name": "Uzun Sargı Etek", "slot": "dis", "price": 220, "rank": 0, "desc": "Baldır ortasına inen kruvaze mor sargı etek.", "stats": {"chakra": 20}, "look": {"outer_style": "sargi_etek_uzun", "outer_pattern": 33, "holster": false}, "c1": Color(0.42, 0.2, 0.6), "c2": Color(0.42, 0.2, 0.6)},
	"kisa_ust_dugme": {"name": "Düğmeli Kısa Üst", "slot": "govde", "price": 90, "rank": 0, "desc": "Kolsuz, boğazlı, göğüs altında biten düğmeli kısa üst.", "stats": {"speed": 0.03}, "look": {"top_style": "kolsuz", "top_pattern": 32}, "c1": Color(0.45, 0.2, 0.62), "c2": Color(0.45, 0.2, 0.62)},
	"kisa_ust_yaka": {"name": "Yarık Yakalı Kısa Üst", "slot": "govde", "price": 90, "rank": 0, "desc": "Kolsuz, yarık dik yakalı, ortası sivri biten kısa üst.", "stats": {"speed": 0.03}, "look": {"top_style": "kolsuz", "top_pattern": 33}, "c1": Color(0.42, 0.2, 0.6), "c2": Color(0.42, 0.2, 0.6)},
	"file_dizlik": {"name": "File Dirsek ve Dizlik", "slot": "kol", "price": 120, "rank": 0, "desc": "Dirsek ve dizleri saran file koruyucu; uçlarında şeritli bant.", "stats": {"def": 2, "speed": 0.02}, "look": {"net_pads": true}, "c1": Color(0.6, 0.6, 0.64)},
	"sort_kapakli": {"name": "Kapaklı Şort", "slot": "bacak", "price": 80, "rank": 0, "desc": "Haki kısa şort; önünde püsküllü kahve kapak.", "stats": {"speed": 0.03}, "look": {"pants_style": "kisa_sort", "pants_pattern": 24}, "c1": Color(0.75, 0.68, 0.48), "c2": Color(0.42, 0.26, 0.16)},
	"diz_cizme_acik": {"name": "Açık Burunlu Diz Çizmesi", "slot": "ayak", "price": 160, "rank": 0, "desc": "Diz boyu, burnu açık yumuşak çizme.", "stats": {"speed": 0.03, "def": 1}, "look": {"foot_style": "shinobi", "anbu_leg": "diz_konc"}, "c1": Color(0.3, 0.18, 0.36), "c2": Color(0.3, 0.18, 0.36)},
	"bilek_bot_acik": {"name": "Açık Burunlu Bilek Botu", "slot": "ayak", "price": 110, "rank": 0, "desc": "Bileği kalın katlı, burnu açık bot.", "stats": {"speed": 0.04}, "look": {"foot_style": "shinobi", "anbu_leg": "bilek_konc"}, "c1": Color(0.45, 0.45, 0.5), "c2": Color(0.45, 0.45, 0.5)},
	"esofman_ceket": {"name": "Eşofman Ceketi", "slot": "dis", "price": 260, "rank": 0, "desc": "Önü açık siyah eşofman ceketi; dik yaka, kollarında boydan renkli şerit, sırtında girdap arması, ribana bel ve manşet.", "stats": {"speed": 0.05}, "look": {"outer_style": "esofman_ceket", "outer_pattern": 30, "holster": true}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.85, 0.3, 0.42)},
	"kisa_haori": {"name": "Kısa Geniş Kollu Ceket", "slot": "dis", "price": 240, "rank": 0, "desc": "Önü açık, kalçayı örten yeşil ceket; dirsek altına geniş ağızlı kollar, önde yaka bandı.", "stats": {"hp": 25, "def": 2}, "look": {"outer_style": "kisa_haori", "outer_pattern": 0, "holster": false}, "c1": Color(0.15, 0.42, 0.2), "c2": Color(0.15, 0.42, 0.2)},
	"kizil_palto": {"name": "Kızıl Kruvaze Palto", "slot": "dis", "price": 520, "rank": 0, "desc": "Dik yakalı, baldıra inen kruvaze kızıl palto; çift sıra siyah düğme, belde iki kahve kemer, bilekte siyah şerit, önde yırtmaç.", "stats": {"def": 6, "chakra": 15}, "look": {"outer_style": "kizil_palto", "outer_pattern": 0, "holster": false}, "c1": Color(0.55, 0.1, 0.16), "c2": Color(0.07, 0.07, 0.09)},
	"tisort_biye": {"name": "Biyeli Tişört", "slot": "govde", "price": 60, "rank": 0, "desc": "Yaka ağzı koyu biyeli beyaz tişört.", "stats": {"speed": 0.02}, "look": {"top_style": "tisort", "top_pattern": 30}, "c1": Color(0.95, 0.95, 0.95), "c2": Color(0.1, 0.1, 0.12)},
	"tisort_amblem": {"name": "Amblemli Tişört ve Kemer", "slot": "govde", "price": 110, "rank": 0, "desc": "Göğsünde daire içinde 食 amblemi olan kırık beyaz tişört; belde kırmızı kemer, önde gümüş plaka.", "stats": {"hp": 20}, "look": {"top_style": "tisort", "top_pattern": 31, "waist_belt": Color(0.72, 0.16, 0.18)}, "c1": Color(0.9, 0.9, 0.88), "c2": Color(0.55, 0.12, 0.14)},
	"onluk": {"name": "Hemşire Önlüğü", "slot": "dis", "price": 400, "rank": 0, "desc": "Kolsuz, dik yakalı beyaz önlük elbise; kırmızı biyeli çift sıra düğmeli panel, arkada fiyonklu kırmızı kemer, kırmızı astarlı yırtmaç, sırtında 医; kırmızı şeritli manşetler.", "stats": {"hp": 20, "chakra": 15}, "look": {"outer_style": "onluk", "outer_pattern": 28, "holster": false, "nd": {"belt": Color(0.75, 0.12, 0.14), "cuff_line": Color(0.75, 0.12, 0.14)}}, "c1": Color(0.95, 0.95, 0.96), "c2": Color(0.62, 0.1, 0.14)},
	"onluk_bahar": {"name": "Hemşire Önlüğü: Bahar", "slot": "dis", "price": 440, "rank": 1, "desc": "Kolsuz, dik yakalı mavi-yeşil önlük; sarı biye, beyaz-sarı kemer, sırtında tavşan; kalpli manşetler.", "stats": {"hp": 30}, "look": {"outer_style": "onluk", "outer_pattern": 29, "holster": false, "nd": {"belt": Color(0.96, 0.96, 0.95), "belt_edge": Color(0.95, 0.82, 0.25), "cuff_line": Color(0.2, 0.62, 0.55), "hearts": true, "btn": Color(0.95, 0.95, 0.95)}}, "c1": Color(0.3, 0.68, 0.66), "c2": Color(0.95, 0.82, 0.25)},
	"corap_sandalet": {"name": "Çoraplı Açık Ayakkabı", "slot": "ayak", "price": 120, "rank": 0, "desc": "Diz üstü ince beyaz çorap (bilekte kıvrık) ve beyaz kayışlı açık burunlu ayakkabı.", "stats": {"speed": 0.04}, "look": {"foot_style": "shinobi", "foot_pattern": 11, "anbu_leg": "corap"}, "c1": Color(0.7, 0.1, 0.12), "c2": Color(0.96, 0.96, 0.97)},
	"hirka": {"name": "Ribanalı Hırka", "slot": "dis", "price": 360, "rank": 0, "desc": "Önü açık, kalçayı örten bol hırka; geniş ribana pervaz, şişkin kollar, ribana manşet.", "stats": {"hp": 15, "def": 2}, "look": {"outer_style": "hirka", "outer_pattern": 0, "holster": false, "hk": {"rib": true}}, "c1": Color(0.9, 0.9, 0.92), "c2": Color(0.9, 0.9, 0.92)},
	"hirka_duz": {"name": "Düz Hırka", "slot": "dis", "price": 360, "rank": 1, "desc": "Önü açık, kalçayı örten düz kenarlı bol hırka; şişkin kollar.", "stats": {"speed": 0.03, "def": 2}, "look": {"outer_style": "hirka", "outer_pattern": 0, "holster": false, "hk": {"rib": false}}, "c1": Color(0.08, 0.08, 0.1), "c2": Color(0.08, 0.08, 0.1)},
	"boncuk_tisort": {"name": "Boncuk Baskılı Tişört", "slot": "govde", "price": 90, "rank": 0, "desc": "Uzun kesim tişört; göğsünde boncuk dizisi baskısı.", "stats": {"chakra": 10}, "look": {"top_style": "tisort", "top_pattern": 28}, "c1": Color(0.2, 0.7, 0.85), "c2": Color(0.1, 0.3, 0.7)},
	"yildiz_tisort": {"name": "Yıldız Baskılı Tişört", "slot": "govde", "price": 90, "rank": 0, "desc": "Uzun kesim beyaz tişört; göğsünde iki çizgi yıldız.", "stats": {"chakra": 10}, "look": {"top_style": "tisort", "top_pattern": 29}, "c1": Color(0.94, 0.94, 0.96), "c2": Color(0.1, 0.1, 0.12)},
	"kapri_yildiz": {"name": "Yıldızlı Kapri", "slot": "bacak", "price": 120, "rank": 0, "desc": "Baldır ortasında biten, beyaz yıldız baskılı kapri.", "stats": {"speed": 0.03}, "look": {"pants_style": "kapri", "pants_pattern": 21}, "c1": Color(0.15, 0.15, 0.55), "c2": Color(0.95, 0.95, 0.97)},
	"acik_bot": {"name": "Açık Burunlu Bot", "slot": "ayak", "price": 110, "rank": 0, "desc": "Burnu ve topuğu açık, baldıra çıkan bot.", "stats": {"speed": 0.04}, "look": {"foot_style": "shinobi", "anbu_leg": "isitici", "foot_pattern": 3}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.55, 0.56, 0.58)},
	"acik_bot_yildiz": {"name": "Yıldızlı Açık Bot", "slot": "ayak", "price": 130, "rank": 0, "desc": "Burnu açık siyah bot; parmak bandı beyaz üstüne siyah yıldız, mavi taban.", "stats": {"speed": 0.04}, "look": {"foot_style": "shinobi", "anbu_leg": "isitici", "foot_pattern": 10}, "c1": Color(0.08, 0.08, 0.1), "c2": Color(0.15, 0.2, 0.6)},
	"uzun_ceket": {"name": "Uzun Fermuarlı Ceket", "slot": "dis", "price": 520, "rank": 0, "desc": "Dik yakalı, dize inen siyah ceket; belden aşağı ters V açılır, lila astar.", "stats": {"def": 5, "speed": 0.02}, "look": {"outer_style": "uzun_ceket", "outer_pattern": 25, "holster": false}, "c1": Color(0.09, 0.09, 0.11), "c2": Color(0.62, 0.66, 0.9)},
	"uzun_ceket_hava": {"name": "Uzun Ceket: Hava", "slot": "dis", "price": 580, "rank": 1, "desc": "Beyaz-kahve uzun ceket; açılım kenarında sarı çimen işi, kahve astar.", "stats": {"speed": 0.05}, "look": {"outer_style": "uzun_ceket", "outer_pattern": 26, "holster": false, "uc": {"collar": Color(0.62, 0.5, 0.42), "zip": Color(0.92, 0.75, 0.2)}}, "c1": Color(0.95, 0.94, 0.92), "c2": Color(0.48, 0.38, 0.32)},
	"uzun_ceket_bahar": {"name": "Uzun Ceket: Bahar", "slot": "dis", "price": 580, "rank": 1, "desc": "Beyaz kollu yeşil uzun ceket; sarı bel bandı, eteğe yakın toplar, sarı astar.", "stats": {"hp": 25}, "look": {"outer_style": "uzun_ceket", "outer_pattern": 27, "holster": false, "uc": {"collar": Color(0.93, 0.95, 0.96), "waist": Color(0.95, 0.85, 0.35)}}, "c1": Color(0.2, 0.62, 0.48), "c2": Color(0.9, 0.85, 0.2)},
	"kayisli_cizme": {"name": "Kayışlı Uzun Çizme", "slot": "ayak", "price": 200, "rank": 0, "desc": "Dize kadar çıkan, baldırı kayışlarla sarılı çizme.", "stats": {"speed": 0.03, "def": 2}, "look": {"foot_style": "diz_cizme", "foot_pattern": 9}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.2, 0.2, 0.24)},
	"omuz_kazak": {"name": "Omzu Açık Kazak", "slot": "dis", "price": 320, "rank": 0, "desc": "Omuzları açık, bele kadar kısa krem kazak; çan kollar, ribana kenarlar.", "stats": {"chakra": 15, "speed": 0.02}, "look": {"outer_style": "omuz_kazak", "outer_pattern": 0, "holster": false}, "c1": Color(0.95, 0.93, 0.9), "c2": Color(0.95, 0.93, 0.9)},
	"omuz_kazak_baklava": {"name": "Omzu Açık Kazak: Baklava", "slot": "dis", "price": 380, "rank": 1, "desc": "Önü baklava panelli kırmızı kısa kazak; beyaz ribana yaka ve etek, çan kollar.", "stats": {"hp": 20}, "look": {"outer_style": "omuz_kazak", "outer_pattern": 23, "holster": false, "sw": {"rib": Color(0.95, 0.94, 0.92)}}, "c1": Color(0.7, 0.12, 0.12), "c2": Color(0.7, 0.12, 0.12)},
	"omuz_kazak_kultur": {"name": "Omzu Açık Kazak: Kültür", "slot": "dis", "price": 380, "rank": 1, "desc": "Örgü bantlı lacivert kısa kazak; çan kollar.", "stats": {"chakra": 25}, "look": {"outer_style": "omuz_kazak", "outer_pattern": 24, "holster": false}, "c1": Color(0.12, 0.18, 0.5), "c2": Color(0.12, 0.18, 0.5)},
	"dar_pant_ekose": {"name": "Ekose Dar Pantolon", "slot": "bacak", "price": 140, "rank": 0, "desc": "Bilek boyu dar ekose pantolon.", "stats": {"speed": 0.02}, "look": {"pants_style": "sivil", "pants_pattern": 20}, "c1": Color(0.12, 0.18, 0.5), "c2": Color(0.3, 0.38, 0.7)},
	"kapusonlu": {"name": "Kapüşonlu", "slot": "dis", "price": 300, "rank": 0, "desc": "Bol siyah kapüşonlu; bağcıklar, ribana etek, sol omuzda kırmızı arma, sağ bilekte pembe bileklik.", "stats": {"speed": 0.03, "hp": 10}, "look": {"outer_style": "kapusonlu", "outer_pattern": 0, "yh": {"logo": Color(0.75, 0.15, 0.15), "wristband": Color(0.88, 0.28, 0.5)}}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.1, 0.1, 0.12)},
	"kapusonlu_ruh": {"name": "Kapüşonlu: Ruh", "slot": "dis", "price": 360, "rank": 1, "desc": "Beyaz gövdeli kırmızı kapüşonlu; sarı biyeli cepler, sırtta ateş topu, siyah bileklik.", "stats": {"melee": 0.04}, "look": {"outer_style": "kapusonlu", "outer_pattern": 22, "yh": {"hood": Color(0.78, 0.12, 0.12), "pocket_trim": Color(0.95, 0.78, 0.15), "logo": Color(0.95, 0.85, 0.3), "wristband": Color(0.1, 0.1, 0.12), "rib": Color(0.78, 0.12, 0.12)}}, "c1": Color(0.95, 0.95, 0.94), "c2": Color(0.95, 0.95, 0.94)},
	"kapusonlu_ayi": {"name": "Kapüşonlu: Kutup Ayısı", "slot": "dis", "price": 360, "rank": 1, "desc": "Açık mavi kapüşonlu; önde ayı yüzü ve pati, beyaz dalgalı etek, baklava desenli bileklik.", "stats": {"hp": 25}, "look": {"outer_style": "kapusonlu", "outer_pattern": 20, "yh": {"logo": Color(0.95, 0.97, 1.0), "wristband": Color(0.45, 0.75, 0.9), "rib": Color(0.95, 0.97, 1.0)}}, "c1": Color(0.4, 0.72, 0.92), "c2": Color(0.4, 0.72, 0.92)},
	"kapusonlu_kedi": {"name": "Kedi Kazağı", "slot": "dis", "price": 360, "rank": 1, "desc": "Yeşil kazak; göğüs altında sarı-siyah şerit ve beyaz fisto, iki kedi patisi, gri kapüşon.", "stats": {"speed": 0.04}, "look": {"outer_style": "kapusonlu", "outer_pattern": 21, "yh": {"hood": Color(0.6, 0.6, 0.62), "logo": Color(0.85, 0.3, 0.3), "rib": Color(0.15, 0.45, 0.2)}}, "c1": Color(0.2, 0.55, 0.25), "c2": Color(0.2, 0.55, 0.25)},
	"jogger_cep": {"name": "Cepli Jogger", "slot": "bacak", "price": 150, "rank": 0, "desc": "Bota sokulan bol jogger pantolon; sağ uylukta cep.", "stats": {"speed": 0.04}, "look": {"pants_style": "kapri", "holster": true}, "c1": Color(0.92, 0.92, 0.9)},
	"spor_bot": {"name": "Yüksek Spor Bot", "slot": "ayak", "price": 140, "rank": 0, "desc": "Baldıra çıkan bağcıklı spor botu; beyaz taban.", "stats": {"speed": 0.04}, "look": {"foot_style": "cizme", "foot_pattern": 7}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.95, 0.95, 0.95)},
	"bol_pant_baklava": {"name": "Baklava Desenli Bol Pantolon", "slot": "bacak", "price": 180, "rank": 0, "desc": "Beyaz bol pantolon; önde baklava sıraları, sağ uylukta cep.", "stats": {"def": 2}, "look": {"pants_style": "kapri", "pants_pattern": 18, "holster": true}, "c1": Color(0.95, 0.97, 1.0), "c2": Color(0.45, 0.75, 0.9)},
	"bol_pant_kedi": {"name": "Kedi Yüzlü Bol Pantolon", "slot": "bacak", "price": 180, "rank": 0, "desc": "Siyah bol pantolon; üst kısmı dişli kenarlı gri, dizlerde kedi yüzü.", "stats": {"speed": 0.03}, "look": {"pants_style": "kapri", "pants_pattern": 19, "holster": true}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.5, 0.5, 0.52)},
	"flamingo_elbise": {"name": "Flamingo Elbisesi", "slot": "dis", "price": 420, "rank": 0, "desc": "Omzu açık, flamingo baskılı kısa yaz elbisesi; çizgili omuz bandı, fırfırlı etek.", "stats": {"speed": 0.04, "hp": 10}, "look": {"outer_style": "flamingo_elbise", "outer_pattern": 19, "holster": false, "fe": {"band_a": Color(0.85, 0.3, 0.4), "band_b": Color(0.97, 0.9, 0.92)}}, "c1": Color(0.97, 0.95, 0.95), "c2": Color(0.95, 0.42, 0.55)},
	"sisme_yelek": {"name": "Şişme Yelek", "slot": "dis", "price": 380, "rank": 0, "desc": "Önü açık, kolsuz, yatay dolgu dilimli şişme yelek; dik yaka.", "stats": {"hp": 20}, "look": {"outer_style": "sisme_yelek", "outer_pattern": 0, "by": {"drawstring": Color(0.9, 0.9, 0.88)}}, "c1": Color(0.95, 0.55, 0.2), "c2": Color(0.95, 0.55, 0.2)},
	"sisme_yelek_denizci": {"name": "Şişme Yelek: Denizci", "slot": "dis", "price": 440, "rank": 1, "desc": "Kırmızı-beyaz-mavi bantlı şişme yelek; önde balıklı iki mavi cep, sırtta çapa.", "stats": {"hp": 25}, "look": {"outer_style": "sisme_yelek", "outer_pattern": 17, "by": {"collar": Color(0.12, 0.25, 0.7), "pockets": Color(0.15, 0.3, 0.8), "anchor": Color(0.12, 0.25, 0.7), "drawstring": Color(0.9, 0.9, 0.88)}}, "c1": Color(0.95, 0.95, 0.95), "c2": Color(0.85, 0.15, 0.15)},
	"sisme_yelek_gok": {"name": "Şişme Yelek: Gök Mavisi", "slot": "dis", "price": 440, "rank": 1, "desc": "Sarı-beyaz kapüşonlu kolsuz yelek.", "stats": {"speed": 0.04}, "look": {"outer_style": "sisme_yelek", "outer_pattern": 18, "by": {"collar": Color(0.95, 0.95, 0.94), "hood": Color(0.98, 0.82, 0.15), "drawstring": Color(0.9, 0.9, 0.88)}}, "c1": Color(0.98, 0.82, 0.15), "c2": Color(0.96, 0.96, 0.95)},
	"terlik": {"name": "Parmak Arası Terlik", "slot": "ayak", "price": 40, "rank": 0, "desc": "Plaj terliği; baldır sargısı yok.", "stats": {"speed": 0.02}, "look": {"foot_style": "terlik", "holster": false}, "c1": Color(0.15, 0.2, 0.4), "c2": Color(0.15, 0.2, 0.4)},
	"sort_cicek": {"name": "Hibiskus Şortu", "slot": "bacak", "price": 120, "rank": 0, "desc": "Diz üstü şort; hibiskus çiçekleri.", "stats": {"speed": 0.04}, "look": {"pants_style": "kisa_sort", "pants_pattern": 15}, "c1": Color(0.95, 0.95, 0.93)},
	"sort_serit": {"name": "Çizgili Şort", "slot": "bacak", "price": 120, "rank": 0, "desc": "Diz üstü şort; gök mavisi-beyaz geniş dikey çizgiler.", "stats": {"speed": 0.04}, "look": {"pants_style": "kisa_sort", "pants_pattern": 16}, "c1": Color(0.95, 0.95, 0.95), "c2": Color(0.45, 0.75, 0.9)},
	"sort_gok": {"name": "Gökyüzü Şortu", "slot": "bacak", "price": 120, "rank": 0, "desc": "Diz üstü şort; gökyüzü deseni, üstünde karpuz dilimleri.", "stats": {"speed": 0.04}, "look": {"pants_style": "kisa_sort", "pants_pattern": 17}, "c1": Color(0.3, 0.6, 0.9)},
	"suna_tunik": {"name": "Kum Tuniği", "slot": "dis", "price": 430, "rank": 0, "desc": "Kalçaya inen bol kolsuz soluk sarı tunik; kalın beyaz atkı, fişeklikli çapraz kılıflık kayışı, geniş gri kemer.", "stats": {"hp": 20, "def": 3}, "look": {"outer_style": "suna_tunik", "outer_pattern": 0, "st": {"scarf": Color(0.93, 0.93, 0.92), "strap": Color(0.46, 0.43, 0.4), "belt": Color(0.52, 0.5, 0.48)}}, "c1": Color(0.86, 0.82, 0.66), "c2": Color(0.86, 0.82, 0.66)},
	"suna_tunik_balon": {"name": "Kum Tuniği: Balonlar", "slot": "dis", "price": 500, "rank": 1, "desc": "Su balonu baskılı mavi tunik; lacivert atkı, kırmızı noktalı beyaz kayış, camgöbeği şeritli beyaz kemer.", "stats": {"chakra": 25}, "look": {"outer_style": "suna_tunik", "outer_pattern": 15, "st": {"scarf": Color(0.12, 0.16, 0.45), "strap": Color(0.94, 0.94, 0.92), "strap_dots": Color(0.85, 0.25, 0.25), "loops": Color(0.95, 0.75, 0.2), "belt": Color(0.94, 0.94, 0.92), "belt_stripe": Color(0.35, 0.85, 0.85), "buckle": Color(0.95, 0.75, 0.2)}}, "c1": Color(0.15, 0.3, 0.75), "c2": Color(0.15, 0.3, 0.75)},
	"suna_tunik_kabile": {"name": "Kum Tuniği: Kabile", "slot": "dis", "price": 500, "rank": 1, "desc": "Etek ucu sarı üçgen bantlı mor tunik; sarı kenarlı siyah atkı, sarı kayış, baklava desenli sarı kemer.", "stats": {"melee": 0.04}, "look": {"outer_style": "suna_tunik", "outer_pattern": 16, "st": {"scarf": Color(0.1, 0.1, 0.12), "scarf_trim": Color(0.92, 0.72, 0.2), "strap": Color(0.92, 0.72, 0.2), "loops": Color(0.25, 0.15, 0.1), "belt": Color(0.92, 0.72, 0.2), "belt_diamond": Color(0.3, 0.15, 0.45), "buckle": Color(0.85, 0.62, 0.15)}}, "c1": Color(0.38, 0.16, 0.55), "c2": Color(0.92, 0.72, 0.2)},
	"kaya_gi": {"name": "Kaya Gi", "slot": "dis", "price": 450, "rank": 0, "desc": "Kolsuz çapraz bağlı kızıl gi; beyaz biyeler, sarı etek bandı, koyu şal yaka, geniş kuşak, kuşaktan sarkan iki çanta.", "stats": {"melee": 0.04, "def": 3}, "look": {"outer_style": "kaya_gi", "outer_pattern": 14, "rg": {"shawl": Color(0.14, 0.11, 0.1), "obi": Color(0.1, 0.1, 0.12), "pouch": Color(0.36, 0.27, 0.18)}}, "c1": Color(0.45, 0.1, 0.14), "c2": Color(0.92, 0.72, 0.12)},
	"kaya_gi_kurtarici": {"name": "Kaya Gi: Kurtarıcı", "slot": "dis", "price": 520, "rank": 1, "desc": "Turuncu-beyaz gi; koyu şal yaka, siyah kuşak üstünde beyaz şerit, beyaz çantalar, sol kolda ok şeritleri ve beyaz kol bandı.", "stats": {"hp": 25}, "look": {"outer_style": "kaya_gi", "outer_pattern": 14, "rg": {"shawl": Color(0.12, 0.12, 0.13), "obi": Color(0.1, 0.1, 0.12), "obi_band": Color(0.95, 0.95, 0.93), "pouch": Color(0.92, 0.92, 0.9), "chevron": Color(0.9, 0.45, 0.15), "armband": Color(0.95, 0.95, 0.93)}}, "c1": Color(0.92, 0.38, 0.12), "c2": Color(0.92, 0.38, 0.12)},
	"kaya_gi_postaci": {"name": "Kaya Gi: Postacı", "slot": "dis", "price": 520, "rank": 1, "desc": "Mavi gi; beyaz şal yaka, siyah kuşak, etiketli mavi-sarı çantalar.", "stats": {"speed": 0.05}, "look": {"outer_style": "kaya_gi", "outer_pattern": 14, "rg": {"shawl": Color(0.92, 0.92, 0.92), "obi": Color(0.1, 0.1, 0.12), "pouch": Color(0.15, 0.3, 0.7), "tags": true}}, "c1": Color(0.15, 0.36, 0.8), "c2": Color(0.15, 0.36, 0.8)},
	"file_corapli_kapri": {"name": "File Çoraplı Diz Altı Pantolon", "slot": "bacak", "price": 180, "rank": 0, "desc": "Dizin hemen altında biten pantolon; baldırda file çorap.", "stats": {"speed": 0.04}, "look": {"pants_style": "sort", "leg_fishnet": true, "holster": true}, "c1": Color(0.6, 0.15, 0.2)},
	"bulut_etek": {"name": "Bulut Sargı Eteği", "slot": "dis", "price": 420, "rank": 0, "desc": "Göğüs altından dize inen yüksek belli kırmızı sargı etek; beyaz biyeler, gri-beyaz kuşak, kırık beyaz atkı.", "stats": {"speed": 0.03, "chakra": 10}, "look": {"outer_style": "bulut_etek", "outer_pattern": 11, "bk": {"scarf": Color(0.9, 0.9, 0.87), "belt": Color(0.88, 0.88, 0.86), "trim": Color(0.96, 0.96, 0.94)}}, "c1": Color(0.66, 0.12, 0.12), "c2": Color(0.96, 0.96, 0.94)},
	"bulut_etek_toprak": {"name": "Bulut Sargı Eteği: Toprak", "slot": "dis", "price": 480, "rank": 1, "desc": "Siyah sargı etek; ucunda yeşil zikzak bant, geometrik desenli yeşil kuşak, kırık beyaz atkı.", "stats": {"hp": 20}, "look": {"outer_style": "bulut_etek", "outer_pattern": 13, "bk": {"scarf": Color(0.88, 0.88, 0.86), "belt": Color(0.12, 0.45, 0.38), "belt_pattern": Color(0.85, 0.9, 0.88), "top_trim": false, "wrist_mark": Color(0.2, 0.6, 0.5)}}, "c1": Color(0.14, 0.11, 0.1), "c2": Color(0.2, 0.6, 0.5)},
	"bulut_etek_yildiz": {"name": "Bulut Sargı Eteği: Takımyıldız", "slot": "dis", "price": 480, "rank": 1, "desc": "Lacivert sargı etek; altında takımyıldız baskısı, mavi kuşak, yıldız işli mavi atkı.", "stats": {"chakra": 25}, "look": {"outer_style": "bulut_etek", "outer_pattern": 12, "bk": {"scarf": Color(0.25, 0.65, 0.85), "scarf_star": Color(0.92, 0.95, 1.0), "belt": Color(0.45, 0.72, 0.9), "top_trim": false}}, "c1": Color(0.12, 0.18, 0.55), "c2": Color(0.8, 0.9, 1.0)},
	"kiri_tunik": {"name": "Sis Tuniği", "slot": "dis", "price": 480, "rank": 0, "desc": "Kalçayı geçen dikey dikişli mor tunik; iki çıtçıtlı atkı yaka, çapraz yeşil kayış, tokalı kemer, sol kalçada çanta.", "stats": {"speed": 0.04, "def": 3}, "look": {"outer_style": "kiri_tunik", "outer_pattern": 9, "kt": {"strap": Color(0.48, 0.66, 0.2), "belt": Color(0.48, 0.66, 0.2), "pouch": Color(0.24, 0.19, 0.36)}}, "c1": Color(0.66, 0.6, 0.82), "c2": Color(0.16, 0.13, 0.26)},
	"kiri_tunik_beyaz": {"name": "Sis Tuniği: Beyaz", "slot": "dis", "price": 560, "rank": 1, "desc": "Beyaz-gri iki renkli tunik; sarı biyeli ön panel, etekte satranç taşı kesikleri, beyaz atkı yaka, siyah kayış, sarı tokalar, damalı çanta.", "stats": {"def": 5}, "look": {"outer_style": "kiri_tunik", "outer_pattern": 10, "kt": {"collar": Color(0.9, 0.9, 0.9), "snap": Color(0.3, 0.3, 0.32), "strap": Color(0.12, 0.12, 0.14), "buckle": Color(0.92, 0.78, 0.15), "belt": Color(0.92, 0.92, 0.9), "pouch": Color(0.9, 0.9, 0.9), "checker": Color(0.1, 0.1, 0.12)}}, "c1": Color(0.92, 0.92, 0.9), "c2": Color(0.6, 0.6, 0.62)},
	"kiri_tunik_siyah": {"name": "Sis Tuniği: Siyah", "slot": "dis", "price": 560, "rank": 1, "desc": "Siyah-gri iki renkli tunik; sarı biyeli ön panel, etekte satranç taşı kesikleri, siyah atkı yaka, siyah kayış, sarı tokalar, damalı çanta.", "stats": {"melee": 0.04, "def": 3}, "look": {"outer_style": "kiri_tunik", "outer_pattern": 10, "kt": {"collar": Color(0.1, 0.1, 0.12), "strap": Color(0.1, 0.1, 0.12), "buckle": Color(0.92, 0.78, 0.15), "belt": Color(0.92, 0.92, 0.9), "pouch": Color(0.9, 0.9, 0.9), "checker": Color(0.1, 0.1, 0.12)}}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.6, 0.6, 0.62)},
	"acik_ceket": {"name": "Yaprak Desenli Kısa Ceket", "slot": "dis", "price": 450, "rank": 0, "desc": "Önü açık, bele kadar kısa ceket; dik yaka, kıvrık manşet, yaprak dalı baskısı, sol kolda kırmızı arma; gri gömlek, beyaz kemer, yeşil bel çantası.", "stats": {"speed": 0.03, "def": 3}, "look": {"outer_style": "acik_ceket", "outer_pattern": 7, "jk": {"patch": Color(0.72, 0.12, 0.12), "shirt": Color(0.62, 0.63, 0.66), "belt": Color(0.94, 0.94, 0.92), "plate": Color(0.92, 0.92, 0.9), "bag": Color(0.18, 0.3, 0.2)}}, "c1": Color(0.72, 0.84, 0.78), "c2": Color(0.24, 0.42, 0.3)},
	"acik_ceket_matador": {"name": "Matador Kısa Ceketi", "slot": "dis", "price": 520, "rank": 1, "desc": "Siyah kısa ceket; manşetlerde üç altın şerit, omuzda altın arma; siyah gömlek, plakalı altın kemer, altın bantlı bot.", "stats": {"melee": 0.04, "def": 3}, "look": {"outer_style": "acik_ceket", "outer_pattern": 0, "jk": {"patch": Color(0.88, 0.7, 0.2), "cuff_stripes": Color(0.88, 0.7, 0.2), "shirt": Color(0.1, 0.1, 0.12), "belt": Color(0.88, 0.7, 0.2), "belt_plates": Color(0.7, 0.52, 0.12), "buckle": Color(0.7, 0.52, 0.12), "plate": Color(0.72, 0.12, 0.12), "bag": Color(0.12, 0.12, 0.14), "boot_band": Color(0.88, 0.7, 0.2)}}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.1, 0.1, 0.12)},
	"acik_ceket_kot": {"name": "Kovboy Kot Ceketi", "slot": "dis", "price": 520, "rank": 1, "desc": "Kapaklı göğüs cepli, dikişli kısa kot ceket; sarı gömlek, kahve kemer, yıldızlı çanta, perçinli bot.", "stats": {"hp": 20, "def": 3}, "look": {"outer_style": "acik_ceket", "outer_pattern": 0, "jk": {"patch": Color(0.72, 0.12, 0.12), "pockets": true, "shirt": Color(0.9, 0.78, 0.2), "belt": Color(0.4, 0.24, 0.14), "buckle": Color(0.62, 0.58, 0.5), "plate": Color(0.4, 0.24, 0.14), "bag": Color(0.45, 0.3, 0.16), "bag_star": Color(0.95, 0.95, 0.92), "boot_studs": Color(0.78, 0.72, 0.55)}}, "c1": Color(0.18, 0.35, 0.72), "c2": Color(0.18, 0.35, 0.72)},
	"akatsuki_pelerini": {"name": "Kızıl Bulut Pelerini", "slot": "dis", "price": 0, "rank": 3, "desc": "Akatsuki üyelerinin dik yakalı siyah pelerini; beyaz kenarlı kızıl bulutlar.", "stats": {"def": 10, "chakra": 50, "hp": 40}, "look": {"outer_style": "org_pelerin", "outer_pattern": 6}, "c1": Color(0.13, 0.14, 0.26), "c2": Color(0.72, 0.07, 0.14)},
	# köye özel Jōnin kıyafetleri (terfide verilir)
	"konoha_jonin": {"name": "Konoha Jōnin Haorisi", "slot": "dis", "price": 0, "rank": 3, "desc": "Konoha jōninlerinin kısa yeşil-gri haorisi, sırtında girdap arması.", "stats": {"def": 6, "chakra": 30, "speed": 0.02}, "look": {"outer_style": "haori", "outer_pattern": 1}, "c1": Color(0.32, 0.4, 0.28), "c2": Color(0.75, 0.2, 0.15)},
	"suna_jonin": {"name": "Suna Jōnin Pelerini", "slot": "dis", "price": 0, "rank": 3, "desc": "Kum fırtınasına dayanıklı bej pelerin ve omuz kayışı.", "stats": {"def": 6, "hp": 30, "speed": 0.02}, "look": {"outer_style": "kisa", "outer_pattern": 1}, "c1": Color(0.78, 0.68, 0.5), "c2": Color(0.45, 0.35, 0.25)},
	"kiri_jonin": {"name": "Kiri Jōnin Atkılı Paltosu", "slot": "dis", "price": 0, "rank": 3, "desc": "Sis Köyü jōninlerinin mavi-gri, kalın atkılı paltosu.", "stats": {"def": 6, "chakra": 40}, "look": {"outer_style": "palto", "outer_pattern": 1}, "c1": Color(0.36, 0.44, 0.5), "c2": Color(0.2, 0.25, 0.35)},
	"kumo_jonin": {"name": "Kumo Jōnin Kemeri ve Pelerini", "slot": "dis", "price": 0, "rank": 3, "desc": "Bulut Köyü'nün beyaz kısa pelerini; şimşek desenli kenar.", "stats": {"def": 5, "melee": 0.08}, "look": {"outer_style": "kisa", "outer_pattern": 2}, "c1": Color(0.9, 0.9, 0.86), "c2": Color(0.85, 0.72, 0.25)},
	"iwa_jonin": {"name": "Iwa Jōnin Kızıl Haorisi", "slot": "dis", "price": 0, "rank": 3, "desc": "Kaya Köyü jōninlerinin kahverengi-kızıl, tek omzu zırhlı haorisi.", "stats": {"def": 9, "hp": 30, "speed": -0.01}, "look": {"outer_style": "haori", "outer_pattern": 1}, "c1": Color(0.45, 0.28, 0.2), "c2": Color(0.62, 0.18, 0.15)},
	"org_pelerini": {"name": "Kızıl Hilal Pelerini", "slot": "dis", "price": 0, "rank": 3, "desc": "Bilinmeyen bir örgütün dik yakalı, kızıl hilal desenli uzun pelerini.", "stats": {"def": 8, "chakra": 40, "hp": 30}, "look": {"outer_style": "org_pelerin", "outer_pattern": 3}, "c1": Color(0.08, 0.08, 0.12), "c2": Color(0.75, 0.1, 0.12)},
	"panco": {"name": "Panço", "slot": "dis", "price": 150, "rank": 0, "desc": "Omuzlardan kalçaya inen geniş yağmurluk.", "stats": {"def": 2, "hp": 15}, "look": {"outer_style": "panco", "outer_pattern": 1}, "c1": Color(0.45, 0.35, 0.25), "c2": Color(0.7, 0.3, 0.15)},
	"yirtik_pelerin": {"name": "Yırtık Gezgin Pelerini", "slot": "dis", "price": 90, "rank": 0, "desc": "Eteği parça parça olmuş, delikli eski pelerin.", "stats": {"def": 2, "speed": 0.02}, "look": {"outer_style": "yirtik", "outer_pattern": 5}, "c1": Color(0.3, 0.27, 0.24)},
	"jinbaori": {"name": "Jinbaori", "slot": "dis", "price": 900, "rank": 2, "desc": "Samuray komutanlarının kolsuz, yandan yırtmaçlı savaş cüppesi.", "stats": {"def": 6, "hp": 30}, "look": {"outer_style": "jinbaori", "outer_pattern": 1}, "c1": Color(0.15, 0.15, 0.22), "c2": Color(0.85, 0.68, 0.25)},
	"kesis_cubbesi": {"name": "Keşiş Cübbesi", "slot": "dis", "price": 260, "rank": 0, "desc": "Ayak bileğine inen kollu tapınak cübbesi.", "stats": {"chakra": 40}, "look": {"outer_style": "cuppe", "outer_pattern": 1}, "c1": Color(0.3, 0.28, 0.35), "c2": Color(0.9, 0.55, 0.15)},
	"kesa": {"name": "Kesa", "slot": "dis", "price": 120, "rank": 0, "desc": "Tek omuzdan çapraz inen keşiş örtüsü.", "stats": {"chakra": 25}, "look": {"outer_style": "kesa"}, "c1": Color(0.62, 0.18, 0.1)},
	"sennin_haorisi": {"name": "Alev Etekli Uzun Haori", "slot": "dis", "price": 1400, "rank": 3, "desc": "Dize inen, eteği alev desenli uzun haori.", "stats": {"chakra": 45, "def": 4}, "look": {"outer_style": "haori_uzun", "outer_pattern": 2}, "c1": Color(0.9, 0.88, 0.84), "c2": Color(0.8, 0.15, 0.1)},
	"bantli_palto": {"name": "Bantlı Komutan Paltosu", "slot": "dis", "price": 1200, "rank": 3, "desc": "Eteği renkli bantla biten uzun palto.", "stats": {"def": 6, "chakra": 35}, "look": {"outer_style": "palto", "outer_pattern": 1}, "c1": Color(0.2, 0.22, 0.28), "c2": Color(0.85, 0.65, 0.2)},
	"mino": {"name": "Hasır Yağmurluk (Mino)", "slot": "dis", "price": 80, "rank": 0, "desc": "Saman liflerinden örülmüş kaba yağmurluk. Köylü ve gezgin işi.", "stats": {"def": 2, "hp": 20}, "look": {"outer_style": "mino", "outer_pattern": 4}, "c1": Color(0.68, 0.58, 0.36)},
	"gece_pelerini": {"name": "Gece Pelerini", "slot": "dis", "price": 520, "rank": 2, "desc": "Bileğe inen kapalı, koyu pelerin.", "stats": {"def": 4, "speed": 0.03}, "look": {"outer_style": "org_pelerin", "outer_pattern": 1}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.25, 0.25, 0.3)},
	# --- kol / koruma
	"omuz_zirhi": {"name": "Omuz Zırhı", "slot": "kol", "price": 300, "rank": 1, "desc": "Tek omuza takılan katmanlı plaka ve göğüs kayışı.", "stats": {"def": 5}, "look": {"guards": "omuz"}, "c1": Color(0.5, 0.52, 0.56)},
	"dizlik": {"name": "Dizlik", "slot": "kol", "price": 120, "rank": 0, "desc": "Dizleri koruyan sert ped.", "stats": {"def": 3, "melee": 0.02}, "look": {"guards": "dizlik"}, "c1": Color(0.3, 0.3, 0.32)},
	"agir_zirh": {"name": "Ağır Zırh Takımı", "slot": "kol", "price": 950, "rank": 2, "desc": "İki omuzluk ve dizlikler. Darbeleri sırtında taşırsın.", "stats": {"def": 10, "hp": 30, "speed": -0.04}, "look": {"guards": "agir", "gloves": true}, "c1": Color(0.4, 0.42, 0.46)},
	"uzun_sargi_eldiven": {"name": "Sargılı Eldiven", "slot": "kol", "price": 110, "rank": 0, "desc": "Parmaksız eldiven ve ön kol sargısı bir arada.", "stats": {"melee": 0.06}, "look": {"gloves": true, "arm_wraps": true}, "c1": Color(0.15, 0.15, 0.17)},
	# --- sırt / bel
	"tespih": {"name": "Dev Tespih", "slot": "sirt", "price": 200, "rank": 0, "desc": "Boyuna asılan iri ahşap tespih.", "stats": {"chakra": 30}, "look": {"back_item": "tespih"}, "c1": Color(0.35, 0.22, 0.12)},
	"sirt_sepeti": {"name": "Sırt Sepeti", "slot": "sirt", "price": 60, "rank": 0, "desc": "Tüccar ve gezginlerin hasır sırt sepeti.", "stats": {"hp": 25}, "look": {"back_item": "sepet"}, "c1": Color(0.7, 0.58, 0.35)},
	"bel_parsomenleri": {"name": "Bel Parşömenleri", "slot": "sirt", "price": 260, "rank": 1, "desc": "Kalçanın iki yanında taşınan çağırma parşömenleri.", "stats": {"chakra": 25}, "look": {"back_item": "bel_parsomen"}, "c1": Color(0.88, 0.82, 0.65)},
	"bel_cantasi": {"name": "Bel Çantası Takımı", "slot": "sirt", "price": 130, "rank": 0, "desc": "Yan cep, arka kese ve sarkan kunai kılıfı.", "stats": {"def": 1, "hp": 10}, "look": {"back_item": "kemer_canta"}, "c1": Color(0.3, 0.26, 0.2)},
	"sashimono": {"name": "Sashimono Bayrağı", "slot": "sirt", "price": 400, "rank": 2, "desc": "Sırta takılan samuray birlik sancağı.", "stats": {"def": 2, "hp": 20}, "look": {"back_item": "sashimono"}, "c1": Color(0.55, 0.12, 0.12)},
	"ip_kangali": {"name": "İp Kangalı", "slot": "sirt", "price": 25, "rank": 0, "desc": "Belde taşınan sağlam ip. Tırmanış ve tuzak için.", "stats": {"speed": 0.01}, "look": {"back_item": "ip_kangal"}, "c1": Color(0.7, 0.62, 0.45)},
	"sirt_001": {"name": "Dev Savaş Yelpazesi", "slot": "sirt", "price": 80, "rank": 0, "desc": "Dev Savaş Yelpazesi — sırtta/belde taşınır.", "stats": {"def": 2}, "look": {"back_item": "dev_yelpaze"}, "c1": Color(0.42, 0.30, 0.18)},
	"sirt_002": {"name": "Sırt Kunai Kılıf Seti", "slot": "sirt", "price": 95, "rank": 0, "desc": "Sırt Kunai Kılıf Seti — sırtta/belde taşınır.", "stats": {"melee": 0.04}, "look": {"back_item": "kunai_kilif_seti"}, "c1": Color(0.15, 0.15, 0.18)},
	"sirt_003": {"name": "Çapraz İkiz Katana", "slot": "sirt", "price": 110, "rank": 0, "desc": "Çapraz İkiz Katana — sırtta/belde taşınır.", "stats": {"chakra": 15}, "look": {"back_item": "ikiz_katana"}, "c1": Color(0.55, 0.15, 0.12)},
	"sirt_004": {"name": "Nodachi", "slot": "sirt", "price": 125, "rank": 0, "desc": "Nodachi — sırtta/belde taşınır.", "stats": {"hp": 15}, "look": {"back_item": "nodachi"}, "c1": Color(0.20, 0.30, 0.55)},
	"sirt_005": {"name": "Geniş Kesici Kılıç", "slot": "sirt", "price": 140, "rank": 0, "desc": "Geniş Kesici Kılıç — sırtta/belde taşınır.", "stats": {"speed": 0.02}, "look": {"back_item": "genis_kesici"}, "c1": Color(0.30, 0.42, 0.25)},
	"sirt_006": {"name": "Sargılı Dev Kılıç", "slot": "sirt", "price": 155, "rank": 0, "desc": "Sargılı Dev Kılıç — sırtta/belde taşınır.", "stats": {"def": 1, "chakra": 10}, "look": {"back_item": "sargili_kilic"}, "c1": Color(0.75, 0.65, 0.45)},
	"sirt_007": {"name": "Belde Kusarigama", "slot": "sirt", "price": 170, "rank": 0, "desc": "Belde Kusarigama — sırtta/belde taşınır.", "stats": {"melee": 0.03, "def": 1}, "look": {"back_item": "kusarigama_bel"}, "c1": Color(0.45, 0.30, 0.55)},
	"sirt_008": {"name": "Bō Asası", "slot": "sirt", "price": 185, "rank": 0, "desc": "Bō Asası — sırtta/belde taşınır.", "stats": {"def": 2}, "look": {"back_item": "bo_asa"}, "c1": Color(0.60, 0.60, 0.62)},
	"sirt_009": {"name": "Naginata", "slot": "sirt", "price": 200, "rank": 0, "desc": "Naginata — sırtta/belde taşınır.", "stats": {"melee": 0.04}, "look": {"back_item": "naginata"}, "c1": Color(0.42, 0.30, 0.18)},
	"sirt_010": {"name": "Yay ve Sadak", "slot": "sirt", "price": 215, "rank": 0, "desc": "Yay ve Sadak — sırtta/belde taşınır.", "stats": {"chakra": 15}, "look": {"back_item": "yay_sadak"}, "c1": Color(0.15, 0.15, 0.18)},
	"sirt_011": {"name": "Kukla Bohçası", "slot": "sirt", "price": 230, "rank": 0, "desc": "Kukla Bohçası — sırtta/belde taşınır.", "stats": {"hp": 15}, "look": {"back_item": "kukla_bohca"}, "c1": Color(0.55, 0.15, 0.12)},
	"sirt_012": {"name": "Üçlü Parşömen Rafı", "slot": "sirt", "price": 245, "rank": 0, "desc": "Üçlü Parşömen Rafı — sırtta/belde taşınır.", "stats": {"speed": 0.02}, "look": {"back_item": "uc_parsomen"}, "c1": Color(0.20, 0.30, 0.55)},
	"sirt_013": {"name": "Yatay Çağırma Parşömeni", "slot": "sirt", "price": 260, "rank": 0, "desc": "Yatay Çağırma Parşömeni — sırtta/belde taşınır.", "stats": {"def": 1, "chakra": 10}, "look": {"back_item": "yatay_parsomen"}, "c1": Color(0.30, 0.42, 0.25)},
	"sirt_014": {"name": "Kurbağa Cüzdan", "slot": "sirt", "price": 275, "rank": 0, "desc": "Kurbağa Cüzdan — sırtta/belde taşınır.", "stats": {"melee": 0.03, "def": 1}, "look": {"back_item": "kurbaga_cuzdan"}, "c1": Color(0.75, 0.65, 0.45)},
	"sirt_015": {"name": "İkiz Su Matarası", "slot": "sirt", "price": 290, "rank": 0, "desc": "İkiz Su Matarası — sırtta/belde taşınır.", "stats": {"def": 2}, "look": {"back_item": "ikiz_matara"}, "c1": Color(0.45, 0.30, 0.55)},
	"sirt_016": {"name": "Tıbbi Ninja Kutusu", "slot": "sirt", "price": 305, "rank": 0, "desc": "Tıbbi Ninja Kutusu — sırtta/belde taşınır.", "stats": {"melee": 0.04}, "look": {"back_item": "ilac_kutusu"}, "c1": Color(0.60, 0.60, 0.62)},
	"sirt_017": {"name": "Hasır Uyku Rulosu", "slot": "sirt", "price": 320, "rank": 0, "desc": "Hasır Uyku Rulosu — sırtta/belde taşınır.", "stats": {"chakra": 15}, "look": {"back_item": "hasir_rulo"}, "c1": Color(0.42, 0.30, 0.18)},
	"sirt_018": {"name": "Belde Flüt", "slot": "sirt", "price": 335, "rank": 0, "desc": "Belde Flüt — sırtta/belde taşınır.", "stats": {"hp": 15}, "look": {"back_item": "flut_kemer"}, "c1": Color(0.15, 0.15, 0.18)},
	"sirt_019": {"name": "Kemik Kılıç", "slot": "sirt", "price": 350, "rank": 0, "desc": "Kemik Kılıç — sırtta/belde taşınır.", "stats": {"speed": 0.02}, "look": {"back_item": "kemik_kilic"}, "c1": Color(0.55, 0.15, 0.12)},
	"sirt_020": {"name": "Savaş Baltası", "slot": "sirt", "price": 365, "rank": 0, "desc": "Savaş Baltası — sırtta/belde taşınır.", "stats": {"def": 1, "chakra": 10}, "look": {"back_item": "savas_baltasi"}, "c1": Color(0.20, 0.30, 0.55)},
	"sirt_021": {"name": "Dik Ninjatō", "slot": "sirt", "price": 380, "rank": 1, "desc": "Dik Ninjatō — sırtta/belde taşınır.", "stats": {"melee": 0.03, "def": 1}, "look": {"back_item": "ninjato"}, "c1": Color(0.30, 0.42, 0.25)},
	"sirt_022": {"name": "Tetsubō", "slot": "sirt", "price": 395, "rank": 1, "desc": "Tetsubō — sırtta/belde taşınır.", "stats": {"def": 2}, "look": {"back_item": "tetsubo"}, "c1": Color(0.75, 0.65, 0.45)},
	"sirt_023": {"name": "Shuriken Keseleri", "slot": "sirt", "price": 410, "rank": 1, "desc": "Shuriken Keseleri — sırtta/belde taşınır.", "stats": {"melee": 0.04}, "look": {"back_item": "shuriken_kesesi"}, "c1": Color(0.45, 0.30, 0.55)},
	"sirt_024": {"name": "Patlayıcı Etiket Kemeri", "slot": "sirt", "price": 425, "rank": 1, "desc": "Patlayıcı Etiket Kemeri — sırtta/belde taşınır.", "stats": {"chakra": 15}, "look": {"back_item": "etiket_kemeri"}, "c1": Color(0.60, 0.60, 0.62)},
	"sirt_025": {"name": "Bel Feneri", "slot": "sirt", "price": 440, "rank": 1, "desc": "Bel Feneri — sırtta/belde taşınır.", "stats": {"hp": 15}, "look": {"back_item": "fener"}, "c1": Color(0.42, 0.30, 0.18)},
	"sirt_026": {"name": "Ahşap Kalkan", "slot": "sirt", "price": 455, "rank": 1, "desc": "Ahşap Kalkan — sırtta/belde taşınır.", "stats": {"speed": 0.02}, "look": {"back_item": "ahsap_kalkan"}, "c1": Color(0.15, 0.15, 0.18)},
	"sirt_027": {"name": "İkiz Fūma Shuriken", "slot": "sirt", "price": 470, "rank": 1, "desc": "İkiz Fūma Shuriken — sırtta/belde taşınır.", "stats": {"def": 1, "chakra": 10}, "look": {"back_item": "ikiz_fuma"}, "c1": Color(0.55, 0.15, 0.12)},
	"sirt_028": {"name": "Keşiş Asası (Shakujō)", "slot": "sirt", "price": 485, "rank": 1, "desc": "Keşiş Asası (Shakujō) — sırtta/belde taşınır.", "stats": {"melee": 0.03, "def": 1}, "look": {"back_item": "shakujo"}, "c1": Color(0.20, 0.30, 0.55)},
	"sirt_029": {"name": "Nobori Sancağı", "slot": "sirt", "price": 500, "rank": 1, "desc": "Nobori Sancağı — sırtta/belde taşınır.", "stats": {"def": 2}, "look": {"back_item": "nobori"}, "c1": Color(0.30, 0.42, 0.25)},
	"sirt_030": {"name": "Kristal Küre Kutusu", "slot": "sirt", "price": 515, "rank": 1, "desc": "Kristal Küre Kutusu — sırtta/belde taşınır.", "stats": {"melee": 0.04}, "look": {"back_item": "kristal_kure"}, "c1": Color(0.75, 0.65, 0.45)},
	"sirt_031": {"name": "İkiz Tonfa", "slot": "sirt", "price": 530, "rank": 1, "desc": "İkiz Tonfa — sırtta/belde taşınır.", "stats": {"chakra": 15}, "look": {"back_item": "ikiz_tonfa"}, "c1": Color(0.45, 0.30, 0.55)},
	"sirt_032": {"name": "Belde Demir Yelpaze", "slot": "sirt", "price": 545, "rank": 1, "desc": "Belde Demir Yelpaze — sırtta/belde taşınır.", "stats": {"hp": 15}, "look": {"back_item": "tessen_bel"}, "c1": Color(0.60, 0.60, 0.62)},
	"sirt_033": {"name": "Manriki Zinciri", "slot": "sirt", "price": 560, "rank": 1, "desc": "Manriki Zinciri — sırtta/belde taşınır.", "stats": {"speed": 0.02}, "look": {"back_item": "manriki"}, "c1": Color(0.42, 0.30, 0.18)},
	"sirt_034": {"name": "İkiz Kabak Matara", "slot": "sirt", "price": 575, "rank": 1, "desc": "İkiz Kabak Matara — sırtta/belde taşınır.", "stats": {"def": 1, "chakra": 10}, "look": {"back_item": "ikiz_kabak"}, "c1": Color(0.15, 0.15, 0.18)},
	"sirt_035": {"name": "Furoshiki Bohçası", "slot": "sirt", "price": 590, "rank": 1, "desc": "Furoshiki Bohçası — sırtta/belde taşınır.", "stats": {"melee": 0.03, "def": 1}, "look": {"back_item": "furoshiki"}, "c1": Color(0.55, 0.15, 0.12)},
	"sirt_036": {"name": "Harita Tüpü", "slot": "sirt", "price": 605, "rank": 1, "desc": "Harita Tüpü — sırtta/belde taşınır.", "stats": {"def": 2}, "look": {"back_item": "harita_tupu"}, "c1": Color(0.20, 0.30, 0.55)},
	"sirt_037": {"name": "Haberci Kuş Kafesi", "slot": "sirt", "price": 620, "rank": 1, "desc": "Haberci Kuş Kafesi — sırtta/belde taşınır.", "stats": {"melee": 0.04}, "look": {"back_item": "kus_kafesi"}, "c1": Color(0.30, 0.42, 0.25)},
	"sirt_038": {"name": "Püsküllü Kılıç", "slot": "sirt", "price": 635, "rank": 1, "desc": "Püsküllü Kılıç — sırtta/belde taşınır.", "stats": {"chakra": 15}, "look": {"back_item": "puskullu_kilic"}, "c1": Color(0.75, 0.65, 0.45)},
	"sirt_039": {"name": "Yelpaze Dizili Kunailer", "slot": "sirt", "price": 650, "rank": 1, "desc": "Yelpaze Dizili Kunailer — sırtta/belde taşınır.", "stats": {"hp": 15}, "look": {"back_item": "kunai_yelpaze"}, "c1": Color(0.45, 0.30, 0.55)},
	"sirt_040": {"name": "Zırhlı Sırt Plakası", "slot": "sirt", "price": 665, "rank": 1, "desc": "Zırhlı Sırt Plakası — sırtta/belde taşınır.", "stats": {"speed": 0.02}, "look": {"back_item": "sirt_plakasi"}, "c1": Color(0.60, 0.60, 0.62)},
	"sirt_041": {"name": "Hayvan Dişi Kolyesi", "slot": "sirt", "price": 680, "rank": 2, "desc": "Hayvan Dişi Kolyesi — sırtta/belde taşınır.", "stats": {"def": 1, "chakra": 10}, "look": {"back_item": "dis_kolye"}, "c1": Color(0.42, 0.30, 0.18)},
	"sirt_042": {"name": "Çan Kemeri", "slot": "sirt", "price": 695, "rank": 2, "desc": "Çan Kemeri — sırtta/belde taşınır.", "stats": {"melee": 0.03, "def": 1}, "look": {"back_item": "can_kemeri"}, "c1": Color(0.15, 0.15, 0.18)},
	"sirt_043": {"name": "İkiz Kama", "slot": "sirt", "price": 710, "rank": 2, "desc": "İkiz Kama — sırtta/belde taşınır.", "stats": {"def": 2}, "look": {"back_item": "ikiz_kama"}, "c1": Color(0.55, 0.15, 0.12)},
	"sirt_044": {"name": "Ok Sadağı", "slot": "sirt", "price": 725, "rank": 2, "desc": "Ok Sadağı — sırtta/belde taşınır.", "stats": {"melee": 0.04}, "look": {"back_item": "sadak"}, "c1": Color(0.20, 0.30, 0.55)},
	"sirt_045": {"name": "Savaş Çekici", "slot": "sirt", "price": 740, "rank": 2, "desc": "Savaş Çekici — sırtta/belde taşınır.", "stats": {"chakra": 15}, "look": {"back_item": "savas_cekici"}, "c1": Color(0.30, 0.42, 0.25)},
	"sirt_046": {"name": "Belde Tilki Maskesi", "slot": "sirt", "price": 755, "rank": 2, "desc": "Belde Tilki Maskesi — sırtta/belde taşınır.", "stats": {"hp": 15}, "look": {"back_item": "tilki_maske_bel"}, "c1": Color(0.75, 0.65, 0.45)},
	"sirt_047": {"name": "Mürekkep ve Fırça Kutusu", "slot": "sirt", "price": 770, "rank": 2, "desc": "Mürekkep ve Fırça Kutusu — sırtta/belde taşınır.", "stats": {"speed": 0.02}, "look": {"back_item": "murekkep_kutusu"}, "c1": Color(0.45, 0.30, 0.55)},
	"sirt_048": {"name": "Belde Chakra Bıçakları", "slot": "sirt", "price": 785, "rank": 2, "desc": "Belde Chakra Bıçakları — sırtta/belde taşınır.", "stats": {"def": 1, "chakra": 10}, "look": {"back_item": "chakra_bicaklari"}, "c1": Color(0.60, 0.60, 0.62)},
	"sirt_049": {"name": "Bele Sarılı Zincir", "slot": "sirt", "price": 800, "rank": 2, "desc": "Bele Sarılı Zincir — sırtta/belde taşınır.", "stats": {"melee": 0.03, "def": 1}, "look": {"back_item": "zincir_bel"}, "c1": Color(0.42, 0.30, 0.18)},
	"sirt_050": {"name": "Bambu Matara", "slot": "sirt", "price": 815, "rank": 2, "desc": "Bambu Matara — sırtta/belde taşınır.", "stats": {"def": 2}, "look": {"back_item": "bambu_matara"}, "c1": Color(0.15, 0.15, 0.18)},
	# --- silahlar (el = iki ele de takılabilir)
	"kunai": {"name": "Kunai", "slot": "el", "price": 30, "rank": 0, "desc": "Her ninjanın yakın dövüş bıçağı.", "stats": {}, "weapon": {"hit": 4.5, "dmg": 1.15, "reach": 0.15, "style": "blade"}, "c1": Color(0.6, 0.62, 0.66)},
	"altin_kunai": {"removed": true, "name": "Chakra Metali Kunai", "slot": "el", "price": 600, "rank": 2, "desc": "Chakra iletebilen özel metalden kunai.", "stats": {"chakra": 15}, "weapon": {"hit": 5, "dmg": 1.35, "reach": 0.2, "style": "blade"}, "c1": Color(0.85, 0.7, 0.3)},
	"patlayici_kunai": {"removed": true, "name": "Etiketli Kunai", "slot": "el", "price": 260, "rank": 1, "desc": "Sapına patlayıcı etiket sarılı kunai. Darbeler sert.", "stats": {}, "weapon": {"hit": 5, "dmg": 1.3, "reach": 0.15, "style": "blade"}, "c1": Color(0.6, 0.62, 0.66)},
	"zincirli_kunai": {"name": "Zincirli Kunai", "slot": "el", "price": 300, "rank": 1, "desc": "Halkasına zincir bağlı kunai: menzil uzar.", "stats": {}, "weapon": {"hit": 5, "dmg": 1.2, "reach": 0.6, "style": "blade"}, "c1": Color(0.6, 0.62, 0.66)},
	"senbon": {"name": "Senbon İğneleri", "slot": "el", "price": 120, "rank": 0, "desc": "Parmak aralarında yelpaze gibi tutulan ince iğneler (iki elde). UZUN MENZİL: iğne yağmuru, kesin noktalara atış.", "stats": {"speed": 0.02}, "weapon": {"hit": 4.5, "dmg": 1.1, "reach": 0.1, "style": "dual", "ranged": true}, "c1": Color(0.75, 0.77, 0.8)},
	"hakko_chakura_to": {"name": "Hakkō Chakura Tō", "skin": true, "slot": "el", "price": 1400, "rank": 1, "clan": "hatake", "base": "tanto",
		"desc": "Beyaz Işık Chakra Kılıcı — Hatake ailesinin (Sakumo, Kakashi) düz bıçaklı tantōsu, küçük yuvarlak siperlik. Savrulunca beyaz chakra izi bırakır. Hakkō Chakura Tō tekniği bununla yapılır.",
		"stats": {"melee": 0.06, "chakra": 10}, "weapon": {"hit": 5, "dmg": 1.5, "reach": 0.4, "style": "blade"}, "c1": Color(0.92, 0.94, 0.98)},
	"mateki": {"name": "Mateki", "slot": "sag", "price": 650, "rank": 1, "desc": "Şeytani Flüt — Otogakure'nin genjutsu flütü (Tayuya). Yakında flütle vurur; ezgisi ses halkası, ses zincirleri ve ruh solucanları doğurur, bitirişte Doki'yi çağırır. Mateki tekniklerinin aracı.", "stats": {"chakra": 20}, "weapon": {"hit": 4.4, "dmg": 1.15, "reach": 0.35, "style": "blade"}, "c1": Color(0.88, 0.86, 0.94)},
	"tanto": {"name": "Tantō", "slot": "el", "price": 320, "rank": 1, "desc": "Kısa kılıç. Hızlı ve keskin.", "stats": {}, "weapon": {"hit": 5, "dmg": 1.35, "reach": 0.35, "style": "blade"}, "c1": Color(0.75, 0.77, 0.8)},
	"ikiz_hancer": {"removed": true, "name": "Hançer", "slot": "el", "price": 240, "rank": 0, "desc": "Çift taşınmak için dengelenmiş kısa hançer.", "stats": {"speed": 0.02}, "weapon": {"hit": 5, "dmg": 1.25, "reach": 0.25, "style": "dual"}, "c1": Color(0.7, 0.72, 0.76)},
	"kama": {"name": "Ō-Kama (Orak)", "slot": "sag", "price": 1400, "rank": 2, "desc": "Uzun saplı kızıl-siyah tırpan orak. İki elle savrulur: hilal bıçak rakibi kancalayıp biçer.", "stats": {"melee": 0.05}, "weapon": {"hit": 6.5, "dmg": 1.75, "reach": 1.3, "style": "heavy"}, "c1": Color(0.7, 0.72, 0.76)},
	"pence": {"name": "Pençe", "slot": "el", "price": 400, "rank": 1, "desc": "İki ele takılan, el sırtı plakalı üç uzun bıçaklı pençe. Kombo sırasında bıçaklara chakra akar.", "stats": {"melee": 0.08}, "weapon": {"hit": 5, "dmg": 1.3, "reach": 0.45, "style": "claw"}, "c1": Color(0.6, 0.62, 0.66)},
	"musta": {"name": "Muşta Bıçağı", "slot": "el", "price": 450, "rank": 1, "desc": "Parmak korumalı bıçak. Rüzgar chakrası akıtılabilir.", "stats": {"melee": 0.1}, "weapon": {"hit": 5, "dmg": 1.3, "reach": 0.25, "style": "blade"}, "c1": Color(0.55, 0.57, 0.6)},
	"chakra_bicak": {"name": "Chakura Tō (Chakra Bıçakları)", "slot": "el", "price": 1100, "rank": 3, "desc": "Parmaklara geçirilen çift muşta bıçak (iki elde). Dört parmak deliği, serçe parmak ucundan kıvrılan bıçak; chakra akıtılabilir.", "stats": {"melee": 0.12, "chakra": 15}, "weapon": {"hit": 6, "dmg": 1.55, "reach": 0.3, "style": "dual"}, "c1": Color(0.55, 0.8, 1.0)},
	"tonfa": {"name": "Tonfa", "slot": "el", "price": 220, "rank": 0, "desc": "Çift savunma sopası (iki elde): ön kol boyunca kalkan gibi tutulur, yumruk ve dirsek uçlarıyla ezer, sersemletir. Gelen hasarı azaltır.", "stats": {"def": 4}, "weapon": {"hit": 5, "dmg": 1.25, "reach": 0.35, "style": "dual"}, "c1": Color(0.35, 0.25, 0.15)},
	"wakizashi": {"name": "Wakizashi", "slot": "el", "price": 520, "rank": 1, "desc": "Orta boy yan kılıç. Çift kılıç tekniğine uygun.", "stats": {}, "weapon": {"hit": 5.5, "dmg": 1.45, "reach": 0.55, "style": "sword"}, "c1": Color(0.78, 0.8, 0.84)},
	"katana": {"name": "Katana", "slot": "sag", "price": 900, "rank": 2, "desc": "Uzun kılıç. Geniş kesişler, yüksek hasar.", "stats": {"speed": -0.02}, "weapon": {"hit": 6.5, "dmg": 1.7, "reach": 0.9, "style": "sword"}, "c1": Color(0.78, 0.8, 0.84)},
	"nodachi": {"name": "Nodachi", "slot": "sag", "price": 1500, "rank": 3, "desc": "İnsan boyunda dev kılıç. Yavaş ama yıkıcı.", "stats": {"speed": -0.05}, "weapon": {"hit": 7.5, "dmg": 2.1, "reach": 1.3, "style": "heavy"}, "c1": Color(0.75, 0.77, 0.8)},
	"savas_cekici": {"name": "Savaş Çekici", "slot": "sag", "price": 1200, "rank": 2, "desc": "Uzun saplı demir çekiç. Zırhı ezer.", "stats": {"speed": -0.06, "def": 2}, "weapon": {"hit": 7, "dmg": 2.0, "reach": 0.9, "style": "heavy"}, "c1": Color(0.4, 0.4, 0.42)},
	# Maymun Kral'ın dönüştüğü asa (yalnız çağrı süresince elde): vuruşta uzar
	"kongo_asa": {"name": "Elmas Asa (Kongō Nyoi)", "slot": "sag", "price": 0, "rank": 4, "desc": "Maymun Kral'ın dönüştüğü kırılmaz asa. Vuruşta boyu uzar.", "stats": {"def": 6, "melee": 0.15}, "weapon": {"hit": 7.5, "dmg": 2.1, "reach": 1.9, "style": "staff", "special": "extend"}, "c1": Color(0.12, 0.12, 0.14)},
	"bo": {"name": "Bō Sopası", "slot": "sag", "price": 180, "rank": 0, "desc": "Uzun ahşap sopa. Geniş vuruş alanı.", "stats": {"def": 2}, "weapon": {"hit": 5, "dmg": 1.3, "reach": 1.0, "style": "staff"}, "c1": Color(0.45, 0.32, 0.2)},
	"mizrak": {"removed": true, "name": "Yari Mızrağı", "slot": "sag", "price": 650, "rank": 2, "desc": "Uzun mızrak. En uzun menzil.", "stats": {}, "weapon": {"hit": 6, "dmg": 1.55, "reach": 1.4, "style": "staff"}, "c1": Color(0.75, 0.77, 0.8)},
	"kusarigama": {"name": "Kusarigama", "slot": "sag", "price": 1400, "rank": 2, "desc": "Hanzō tipi zincirli orak: uzun saplı orak, sap dibinden zincir ve çan ağırlık. Orta menzil: kancalayıp çeker, ağırlığı fırlatır ve döndürür, orağı zincirle fırlatıp geri çeker.", "stats": {"melee": 0.05}, "weapon": {"hit": 5.8, "dmg": 1.5, "reach": 1.3, "style": "chain"}, "c1": Color(0.2, 0.17, 0.29)},
	"el_shuriken": {"removed": true, "name": "Dev Shuriken", "slot": "sag", "price": 700, "rank": 2, "desc": "Elde tutulan dev dört kollu shuriken. Kesici savuruşlar.", "stats": {}, "weapon": {"hit": 6, "dmg": 1.6, "reach": 0.8, "style": "heavy"}, "c1": Color(0.5, 0.52, 0.56)},
	"yagura_sopa": {"name": "Yagura'nın Kancalı Sopası", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Sanbi'nin taşıyıcısı Mizukage'nin iki ucu ters kancalı uzun sopası; dibinde mavi-yeşil çiçek. Kancayla çeker, iki ucuyla döner, su chakrası akıtır.", "stats": {"chakra": 30, "def": 3}, "weapon": {"hit": 6, "dmg": 1.6, "reach": 1.3, "style": "staff", "special": "pull"}, "c1": Color(0.18, 0.2, 0.26)},
	"temari_ogi": {"name": "Temari no Ōōgi", "slot": "sag", "price": 0, "rank": 2, "legend": true, "desc": "Rüzgâr ustasının dev katlanır demir yelpazesi: bej kâğıdında üç mor ay. Açıldıkça (Birinci, İkinci, Üçüncü Ay) rüzgârı büyür; kalkan olur, Daikamaitachi'yi savurur. Orak Gelincik sözleşmesiyle verilir; Kirikiri Mai yalnız bu yelpazeyle çağrılır. Kuşanılıyken Fūton jutsuları %10 güçlü.", "stats": {"chakra": 30}, "weapon": {"hit": 6.0, "dmg": 1.6, "reach": 1.2, "style": "fan", "boost": {"fuuton": 0.10}}, "c1": Color(0.93, 0.87, 0.74)},
	"yelpaze": {"name": "Savaş Yelpazesi", "slot": "sag", "price": 700, "rank": 2, "desc": "Büyük demir yelpaze. Fuuton jutsularını güçlendirir.", "stats": {"chakra": 30}, "weapon": {"hit": 5.5, "dmg": 1.4, "reach": 0.8, "style": "fan"}, "c1": Color(0.85, 0.82, 0.75)},
	# --- gözler (goz = sağ/sol göz yuvasına takılır; satılmaz). Örnek başına "lvl" (tomoe 1-3) ve "origin" (dogustan/nakil)
	"goz_sharingan": {"name": "Sharingan", "slot": "goz", "price": 0, "rank": 0, "desc": "Uchiha'nın kopyalayan gözü. Hareketleri önceden okur.", "stats": {"melee": 0.05, "chakra": 10}, "eye": {"kind": 1, "name": "Sharingan"}, "c1": Color(0.8, 0.05, 0.08)},
	"goz_mangekyo": {"name": "Mangekyō Sharingan", "slot": "goz", "price": 0, "rank": 0, "desc": "Büyük acıyla uyanan kaleydoskop göz. Güçlü ama kör eder.", "stats": {"melee": 0.1, "chakra": 30}, "eye": {"kind": 4, "name": "Mangekyō Sharingan"}, "c1": Color(0.8, 0.05, 0.08)},
	"goz_ems": {"name": "Ebedi Mangekyō Sharingan", "slot": "goz", "price": 0, "rank": 0, "desc": "Kardeş gözüyle birleşen, ışığı sönmeyen Mangekyō.", "stats": {"melee": 0.15, "chakra": 50}, "eye": {"kind": 5, "name": "Ebedi Mangekyō"}, "c1": Color(0.8, 0.05, 0.08)},
	"goz_rinnegan": {"name": "Rinnegan", "slot": "goz", "price": 0, "rank": 0, "desc": "Halkalı efsanevi göz. Altı yolun gücü — en güçlü göz.", "stats": {"melee": 0.22, "chakra": 150, "def": 6, "hp": 80, "speed": 0.03}, "eye": {"kind": 6, "name": "Rinnegan"}, "c1": Color(0.6, 0.5, 0.85)},
	"goz_byakugan": {"name": "Byakugan", "slot": "goz", "price": 0, "rank": 0, "desc": "Hyūga'nın her yönü gören beyaz gözü.", "stats": {"melee": 0.08, "def": 2}, "eye": {"kind": 2, "name": "Byakugan"}, "c1": Color(0.9, 0.9, 0.96)},
	"goz_ketsuryugan": {"name": "Ketsuryūgan", "slot": "goz", "price": 0, "rank": 0, "desc": "Chinoike'nin kan rengi gözü: genjutsu ve kan teknikleri.", "stats": {"chakra": 20, "melee": 0.05}, "eye": {"kind": 3, "name": "Ketsuryūgan"}, "c1": Color(0.7, 0.08, 0.1)},
	"goz_tenseigan": {"name": "Tenseigan", "slot": "goz", "price": 0, "rank": 0, "desc": "Ay ışığı gibi parlayan, çekim ve itme gücü veren göz.", "stats": {"chakra": 60, "def": 4}, "eye": {"kind": 7, "name": "Tenseigan"}, "c1": Color(0.55, 0.75, 1.0)},
	"goz_jogan": {"name": "Jōgan", "slot": "goz", "price": 0, "rank": 0, "desc": "Görünmeyeni gören gizemli göz.", "stats": {"chakra": 40, "speed": 0.04}, "eye": {"kind": 8, "name": "Jōgan"}, "c1": Color(0.45, 0.65, 1.0)},
	# --- efsanevi silahlar (satılmaz: S/A görevleri ve boss ödülü). special: vuruş yeteneği
	"kubikiribocho": {"name": "Kubikiribōchō", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Sis'in Yedi Kılıcı'ndan dev satır. Delikli ağzı kesilenin kanıyla kendini onarır: vuruşlar can çalar.", "stats": {"hp": 40, "speed": -0.06}, "weapon": {"hit": 8.5, "dmg": 2.4, "reach": 1.3, "style": "heavy", "special": "lifesteal"}, "c1": Color(0.78, 0.8, 0.84)},
	"samehada": {"name": "Samehada", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Pullarla kaplı, sargılı canlı kılıç. Değdiği düşmanın chakrasını emer. Kuşanılıyken Suiton jutsuları %10 güçlü.", "stats": {"chakra": 60, "speed": -0.05}, "weapon": {"hit": 7.5, "dmg": 2.2, "reach": 1.2, "style": "heavy", "special": "drain", "boost": {"suiton": 0.10}}, "c1": Color(0.25, 0.32, 0.5)},
	"kiba": {"name": "Kiba (İkiz Yıldırım Kılıcı)", "slot": "el", "price": 0, "rank": 4, "legend": true, "desc": "Yedi Kılıç'tan ikiz yıldırım kılıçları, her elde bir tane. Her kesikte Raiton akar ve uyuşturur; kancalı dikenlerle çeker, bitirişte gökten yıldırım çağırır.", "stats": {"speed": 0.04}, "weapon": {"hit": 6.5, "dmg": 1.8, "reach": 0.8, "style": "sword", "special": "raiton"}, "c1": Color(0.95, 0.85, 0.35)},
	"hiramekarei": {"name": "Hiramekarei", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Çift saplı geniş kılıç. Chakra depolar, ağzını uzatıp devasa bir bıçağa çevirir.", "stats": {"chakra": 40}, "weapon": {"hit": 7.5, "dmg": 2.1, "reach": 1.7, "style": "heavy", "special": "extend"}, "c1": Color(0.3, 0.45, 0.75)},
	"shibuki": {"name": "Shibuki", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Kalın mor rulolu, ağzı patlayıcı mühür kâğıtlarından kılıç. Ağır: rulo arkadan savrulur; her darbe patlar, kâğıtları serpip uzaktan da patlatır.", "stats": {"def": 2}, "weapon": {"hit": 7, "dmg": 2.0, "reach": 1.1, "style": "heavy", "special": "explode"}, "c1": Color(0.85, 0.8, 0.65)},
	"nuibari": {"name": "Nuibari", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Telli dev iğne-kılıç. Saplanır ve düşmanı sana çeker.", "stats": {"speed": 0.05}, "weapon": {"hit": 6.5, "dmg": 1.7, "reach": 1.6, "style": "staff", "special": "pull"}, "c1": Color(0.8, 0.82, 0.86)},
	"kabutowari": {"name": "Kabutowari", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Halatla birbirine bağlı balta (sağ el) ve çekiç (sol el). Çekiç baltayı kama gibi çakar: savunmayı ve zırhı parçalar.", "stats": {"def": 4, "speed": -0.06}, "weapon": {"hit": 8, "dmg": 2.3, "reach": 1.0, "style": "heavy", "special": "armor_break"}, "c1": Color(0.45, 0.45, 0.48)},
	"chokuto": {"name": "Kusanagi Tarzı Chokutō", "slot": "sag", "price": 0, "rank": 3, "legend": true, "desc": "Düz ağızlı efsanevi kılıç. İçinden akıtılan chakra keskinliği arttırır.", "stats": {"speed": 0.04, "melee": 0.1}, "weapon": {"hit": 7, "dmg": 1.95, "reach": 1.0, "style": "sword", "special": "flow"}, "c1": Color(0.85, 0.87, 0.9)},
	"raijin": {"name": "Raijin Kılıcı", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Saf yıldırım chakrasından oluşan ağız. Gök gürültüsüyle keser.", "stats": {"chakra": 30}, "weapon": {"hit": 7, "dmg": 2.0, "reach": 1.2, "style": "sword", "special": "raiton"}, "c1": Color(1.0, 0.9, 0.3)},
	"ruzgar_bicak": {"name": "Fūton Chakura Tō (Rüzgar Chakra Bıçağı)", "slot": "el", "price": 0, "rank": 3, "legend": true, "desc": "Yalnız rüzgar chakrasından oluşan, yarı saydam hafif bıçak. Her savuruşta ileri uçan rüzgar kesiği çıkarır (fuuton).", "stats": {"melee": 0.12}, "weapon": {"hit": 6.5, "dmg": 1.75, "reach": 0.8, "style": "blade", "special": "wind"}, "c1": Color(0.55, 1.0, 0.75)},
	"fuma_shuriken": {"name": "Fūma Shuriken", "slot": "sag", "price": 0, "rank": 3, "legend": true, "desc": "Kında yelpaze gibi kapalı duran, atılınca açılıp dönerek uzaktaki hedefi biçen ve ele dönen dört orak bıçaklı shuriken. UZUN MENZİL.", "stats": {"speed": 0.02}, "weapon": {"hit": 7, "dmg": 1.9, "reach": 1.1, "style": "heavy", "special": "wind", "ranged": true}, "c1": Color(0.55, 0.57, 0.62)},
	"kyodai_shuriken": {"name": "Kyodai Shuriken", "slot": "sag", "price": 2400, "rank": 3, "desc": "İnsandan büyük dört köşeli dev shuriken. Ağır kurulup fırlatılır, yolundaki her şeyi biçer. UZUN MENZİL.", "stats": {"def": 2}, "weapon": {"hit": 9, "dmg": 2.3, "reach": 1.4, "style": "heavy", "ranged": true}, "c1": Color(0.22, 0.21, 0.2)},
	"fuma_makimono": {"name": "Kuchiyose Fūma", "slot": "sag", "price": 2000, "rank": 3, "desc": "Çağırma parşömeni: açıldığında üç büyük kare Fūma shuriken çıkar, hedefe sürüler hâlinde uçar. UZUN MENZİL.", "stats": {"chakra": 20}, "weapon": {"hit": 6, "dmg": 1.6, "reach": 0.6, "style": "heavy", "ranged": true}, "c1": Color(0.92, 0.88, 0.76)},
	"bashosen": {"name": "Bashōsen", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Altı Yolun Bilgesi'nin hazine yelpazesi: kırmızı uçlu beyaz tüyler. Bashōsen tekniklerini (Kaze/Hi/Rai/Mizu no Maki) yalnız bu yelpaze kuşanılmışken atabilirsin.", "stats": {"chakra": 40}, "weapon": {"hit": 5.5, "dmg": 1.5, "reach": 0.9, "style": "fan"}, "c1": Color(0.72, 0.1, 0.2)},
	"gunbai": {"name": "Gunbai Savaş Yelpazesi", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Dev yuvarlak demir yelpaze. Savuruşu fırtına gibi iter, kendisi kalkan olur. Kuşanılıyken Katon jutsuları %10 güçlü.", "stats": {"def": 10, "chakra": 20}, "weapon": {"hit": 6.5, "dmg": 1.8, "reach": 1.1, "style": "fan", "special": "gust", "boost": {"katon": 0.10}}, "c1": Color(0.75, 0.15, 0.15)},
	"uc_tirpan": {"name": "Üç Bıçaklı Tırpan", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Kızıl üç bıçaklı dev tırpan. Ağır: iki elle arkadan savrulur; biçer, bacak keser, kancayla çeker, yere saplanır, havaya fırlatır.", "stats": {"melee": 0.1}, "weapon": {"hit": 7.5, "dmg": 2.15, "reach": 1.4, "style": "heavy"}, "c1": Color(0.75, 0.12, 0.12)},
	"kusanagi": {"name": "Kusanagi no Tsurugi", "slot": "el", "price": 3400, "rank": 3, "desc": "Muhafızsız düz kılıç, siyah sap. Hızlı kesikler, şimşek atılması, ağızdan akan Chidori; bitirişte hedefin içinden geçen iai.", "stats": {"melee": 0.08, "speed": 0.04}, "weapon": {"hit": 6.0, "dmg": 1.5, "reach": 0.6, "style": "blade"}, "c1": Color(0.78, 0.8, 0.84)},
	"homatsu_kiseru": {"name": "Hōmatsu Kiseru (Kabarcık Borusu)", "slot": "el", "price": 2600, "rank": 3, "desc": "Utakata tarzı bambu kabarcık borusu. Dar ağızlıktan üflenir, çandan sabun köpükleri çıkar: patlayan, saran, aşındıran kabarcıklarla orta menzil kombo. Kuşanılıyken Suiton jutsuları %10 güçlü.", "stats": {"chakra": 25}, "weapon": {"hit": 4.0, "dmg": 1.2, "reach": 0.4, "style": "staff", "boost": {"suiton": 0.10}}, "c1": Color(0.82, 0.72, 0.5)},
	"hiraishin_kunai": {"name": "Hiraishin Kunai", "slot": "el", "price": 3200, "rank": 3, "desc": "Üç dişli, kanjili sargılı kunai (Minato tarzı). Her isabet hedefe Hiraishin işareti koyar; kombo sırasında işaretin yanında sarı flaşla belirip vurursun.", "stats": {"speed": 0.06, "melee": 0.06}, "weapon": {"hit": 5.5, "dmg": 1.4, "reach": 0.3, "style": "blade", "special": "hiraishin"}, "c1": Color(0.95, 0.85, 0.3)},
	"sai": {"name": "Sai", "slot": "el", "price": 380, "rank": 1, "desc": "Çift el üç dişli savunma hançeri. Yan dişleriyle silahı kilitler, ters tutuşla topuzla vurur, saplar.", "stats": {"def": 3}, "weapon": {"hit": 5, "dmg": 1.25, "reach": 0.2, "style": "dual"}, "c1": Color(0.7, 0.72, 0.76)},
}

## Efsanevi silahlar (dükkânda yok; A/S görevleri, boss düşürmesi)
const LEGENDARY := ["yagura_sopa", "kubikiribocho", "samehada", "kiba", "hiramekarei", "shibuki", "nuibari", "kabutowari", "chokuto", "raijin", "ruzgar_bicak", "fuma_shuriken", "gunbai", "bashosen", "uc_tirpan"]


static func random_legendary() -> String:
	# Sis'in Yedi Kılıcı ganimet olarak düşmez: sahibini yenerek alınır (Swordsmen)
	return LEGENDARY.filter(func(x): return not x in MistSwords.IDS and not WH.INFO.has(x)).pick_random()   # sahibi olan efsane silahlar da yalnız sahibinden düşer

## Mağazada satılanlar
const SHOP_CLOTHES := ["uchiha_yakali", "uchiha_uzun", "uchiha_beyaz", "uchiha_polis", "uchiha_kolluk", "uchiha_haori", "kitsune_maske", "tengu_maske", "oni_maske", "kum_kabagi", "sake_kabagi", "tisort", "uzun_gomlek", "ceket", "yakali", "kolsuz_yakali", "sargili_kolsuz", "file_atlet", "zirhli_gomlek", "kimono_ust",
	"ninja_pant", "sort", "sivil_pant", "sargili_pant", "hakama", "sandalet", "takviyeli_sandalet", "tabi", "zori",
	"kasa", "kapuson", "kafa_bandaji", "bandana", "bez_maske", "gozluk", "gaz_maskesi", "anbu_maske", "anbu_kurt", "anbu_kus", "anbu_ayi",
	"deri_yelek", "suna_yelek", "kiri_yelek", "kumo_yelek", "iwa_yelek", "samuray_zirh",
	"atki", "kisa_pelerin", "seyahat_pelerini", "haori", "uzun_palto",
	"kol_sargisi", "eldiven", "kolluk", "bacak_koruma", "tam_koruma", "aletli_kemer", "kilic_kini", "sirt_cantasi", "dev_parsomen", "sirt_shuriken",
	# genişletilmiş gardırop
	"hachimaki", "hachimaki_kizil", "haydut_bandana", "col_sarigi", "jingasa", "kabuto", "tengai", "golge_kapuson", "col_kapusonu", "yirtik_kasa",
	"mempo", "goz_bandi", "col_pecesi", "kizil_maske", "anbu_tilki", "anbu_kaplan", "anbu_yilan", "anbu_maymun",
	"gi_beyaz", "gi_siyah", "kesis_ustu", "arma_gomlek", "beyaz_arma", "cizgili_tisort", "denizci_ust", "panel_ceket", "kizil_ceket", "atlet", "tek_kol_ust",
	"yamali_gomlek", "yamali_kolsuz", "file_kolsuz", "biyeli_kimono", "yukata", "tunik", "deri_ceket", "golge_ust",
	"bol_pantolon", "col_salvari", "kapri", "kisa_sort", "yamali_pant", "kizil_hakama", "siyah_pant",
	"deri_cizme", "zirhli_cizme", "yuksek_sandal", "siyah_tabi",
	"zincir_yelek", "kayis_kosum", "deri_pul_zirh", "gogus_plakasi", "ame_yelek", "jonin_koyu",
	"panco", "yirtik_pelerin", "jinbaori", "kesis_cubbesi", "kesa", "bantli_palto", "mino", "gece_pelerini",
	"omuz_zirhi", "dizlik", "agir_zirh", "uzun_sargi_eldiven", "tespih", "sirt_sepeti", "bel_parsomenleri", "bel_cantasi", "sashimono", "ip_kangali"]
const SHOP_WEAPONS := ["mateki", "sai", "kunai", "senbon", "tonfa", "bo", "tanto", "kama", "zincirli_kunai", "pence", "musta",
	"wakizashi", "katana", "yelpaze", "kusarigama", "savas_cekici", "chakra_bicak", "nodachi", "kyodai_shuriken", "fuma_makimono"]
## Sadece görev ödülü olarak düşen (dükkânda satılmayan) parçalar dahil ödül havuzu
const REWARD_POOL := ["kafa_bandaji", "gozluk", "kasa", "kapuson", "atki", "kol_sargisi", "eldiven", "kolluk", "bacak_koruma", "tabi", "hakama",
	"kisa_pelerin", "haori", "dev_parsomen", "sirt_shuriken", "senbon", "kama", "pence", "zincirli_kunai", "wakizashi",
	"suna_yelek", "kiri_yelek", "kumo_yelek", "iwa_yelek", "chakra_bicak", "nodachi", "samuray_zirh", "uzun_palto", "anbu_kurt", "anbu_kus", "anbu_ayi",
	"hachimaki_kizil", "jingasa", "kabuto", "kabuto_kizil", "mempo", "mempo_kizil", "golge_kapuson", "arma_gomlek", "beyaz_arma", "golge_ust", "panel_ceket",
	"siyah_pant", "kizil_hakama", "zirhli_cizme", "siyah_tabi", "zincir_yelek", "deri_pul_zirh", "lake_zirh", "jonin_koyu", "jinbaori", "sennin_haorisi",
	"bantli_palto", "gece_pelerini", "omuz_zirhi", "agir_zirh", "bel_parsomenleri", "sashimono", "anbu_tilki", "anbu_kaplan", "anbu_yilan", "anbu_maymun",
	"org_pelerini", "kok_yelek", "cizik_alin"]


## Görev ödülü: rütbeye uygun rastgele parça (yoksa "")
static func random_reward(rank: int) -> String:
	var pool = REWARD_POOL.filter(func(id): return int(ITEMS[id].get("rank", 0)) <= rank)
	return pool.pick_random() if not pool.is_empty() else ""


## Benzersiz (nadir/efsane "u_…") eşyanın taban kimliği: kombo/animasyon, silah şartlı jutsu, düşman anahtar kombosu
## tabana göre çalışır (efsane sürüm gelince düz vuruş genel kombosuna dönüyordu)
static func base_id(id: String) -> String:
	if id.begins_with("u_"):
		return String(_custom().get(id, {}).get("base", id))
	return id


static func item(id: String) -> Dictionary:
	if ITEMS.has(id):
		return ITEMS[id]
	if SETS.has(id):
		return SETS[id]
	if STRIKER.SETS.has(id):
		return STRIKER.SETS[id]
	if id.begins_with("u_"):
		return _custom().get(id, {})
	return {}


## Kendi modeli olan özel silah ("skin": true, ör. Hakkō Chakura Tō): kombo/kın/tutuş tabanınki (tantō), yalnız görünen model kendisi.
## Benzersiz sürümü ("Kan Kızılı Hakkō Chakura Tō" = u_…) de aynı modeli taşır. Yoksa "".
static func skin_id(id: String) -> String:
	var cur = id
	for _k in 3:
		if ITEMS.has(cur) and bool(ITEMS[cur].get("skin", false)):
			return cur
		var it: Dictionary = item(cur)
		if not it.has("base") or String(it["base"]) == cur:
			return ""
		cur = String(it["base"])
	return ""


## Görünüm/kın için taban eşya: benzersiz eşyalar ("Ay Işığı Katana" = u_...) modeli bulunamayıp kısa bıçağa düşüyordu.
## Eski kayıtlarda taban kaydı yoksa addan bulunur (ön ek + taban adı) ve saklanır.
static func visual_id(id: String) -> String:
	if not id.begins_with("u_"):
		return String(ITEMS.get(id, {}).get("base", id))   # özel silah: taban modelin görünüşü (Hakkō Chakura Tō = tantō)
	var it: Dictionary = item(id)
	if it.has("base"):
		return visual_id(String(it["base"])) if ITEMS.has(String(it["base"])) else String(it["base"])   # taban da özel silahsa onun tabanı (Hakkō -> tantō); eskiden model bulunamayıp düz kutu çıkıyordu
	var best = ""
	for k in ITEMS:
		var nm = String(ITEMS[k].get("name", ""))
		if nm != "" and String(it.get("name", "")).ends_with(" " + nm) and ITEMS[k].get("slot", "") == it.get("slot", "") and nm.length() > best.length():
			best = k
	if best != "":
		it["base"] = best
		return best
	return id


# ------------------------------------------------------------------ benzersiz (rastgele üretilmiş) eşyalar ve dönen dükkân stoku
## Kayıtta saklanır (profile.custom_items): id -> eşya sözlüğü (Color'lar hex)
static var _ccache := {}   # çalışma zamanı kopyaları (renkler Color); kayıtta hex kalır
static func _custom() -> Dictionary:
	var pr = Game.profile
	if pr.is_empty():
		return {}
	if not pr.has("custom_items"):
		pr["custom_items"] = {}
	var cm: Dictionary = pr["custom_items"]
	for k in cm:
		if not _ccache.has(k):
			var it: Dictionary = (cm[k] as Dictionary).duplicate(true)
			for ck in ["c1", "c2"]:
				if it.get(ck) is String:
					it[ck] = Color.html(it[ck])
			if String(it.get("name", "")).contains(" (Beyaz Işık Chakra Kılıcı)"):   # eski uzun ad UI'da taşıyordu (romaji kuralı)
				it["name"] = String(it["name"]).replace(" (Beyaz Işık Chakra Kılıcı)", "")
				cm[k]["name"] = it["name"]
			_ccache[k] = it
	return _ccache


const U_PREFIX := {"w": ["Kan Kızılı", "Fırtına Kesen", "Sessiz Gölge", "Ejder Dişi", "Ay Işığı", "Kara Şimşek", "Kum Fısıltısı", "Sis Hayaleti", "Kaya Kıran", "Rüzgâr Çığlığı"],
	"c": ["Usta Dokuma", "Ruh Mühürlü", "Gece Avcısı", "Savaş Ustası", "Kadim Klan", "Fırtına Gezgini", "Gölge Örtülü", "Kızıl Lotus", "Demir İrade", "Ak Turna"]}
const U_EXTRA := ["def", "hp", "chakra", "speed", "melee"]


## Taban eşyadan benzersiz bir sürüm üretir: güçlü istatistikler, ek özellik, özel ad ve renk (tier 3 nadir, 4 efsane)
static func make_unique(base_id: String, kind: String, seed_v: int) -> String:
	var b: Dictionary = ITEMS.get(base_id, {})
	if b.is_empty():
		return ""
	var id = "u_%d" % (absi(seed_v) % 100000000)
	if _custom().has(id):
		return id
	var cm: Dictionary = Game.profile["custom_items"]
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_v
	var tier = 4 if rng.randf() < 0.25 else 3
	var it: Dictionary = b.duplicate(true)
	var k = (1.5 if tier == 3 else 2.2) + rng.randf() * 0.5
	var st: Dictionary = (it.get("stats", {}) as Dictionary).duplicate()
	for s in st:
		st[s] = float(st[s]) * k
	var ex = U_EXTRA[rng.randi() % U_EXTRA.size()]
	st[ex] = float(st.get(ex, 0.0)) + {"def": 4.0, "hp": 30.0, "chakra": 30.0, "speed": 0.03, "melee": 0.06}[ex] * (1.0 if tier == 3 else 1.8)
	it["stats"] = st
	if it.has("weapon"):
		var w: Dictionary = (it["weapon"] as Dictionary).duplicate()
		w["dmg"] = float(w.get("dmg", 1.0)) * (1.2 + rng.randf() * (0.2 if tier == 3 else 0.45))
		it["weapon"] = w
	it["base"] = base_id
	var pre = U_PREFIX[kind][rng.randi() % U_PREFIX[kind].size()]
	it["name"] = "%s %s" % [pre, b["name"]]
	it["desc"] = "%s — benzersiz %s. %s" % [b.get("desc", ""), "nadir eşya" if tier == 3 else "EFSANE eşya", "Bir daha aynısı çıkmaz."]
	it["price"] = int(maxf(400.0, float(b.get("price", 300))) * (4.0 if tier == 3 else 9.0))
	it["unique"] = tier
	it["rank"] = mini(int(b.get("rank", 0)), 2)
	var hue = rng.randf()
	it["c1"] = Color.from_hsv(hue, rng.randf_range(0.35, 0.8), rng.randf_range(0.25, 0.85)).to_html(false)
	it["c2"] = Color.from_hsv(fmod(hue + 0.5, 1.0), 0.7, 0.75).to_html(false)
	cm[id] = it
	_ccache.erase(id)
	return id


## Dükkân stoku: her 10 dakikada (gerçek zaman) köye göre değişen rastgele seçim + 2 benzersiz eşya
static func shop_stock(kind: String, vid: String) -> Array:
	var pool: Array = SHOP_WEAPONS if kind == "w" else SHOP_CLOTHES.filter(func(i): return not String(item(i).get("slot", "")) in OLD_CLOTH_SLOTS) + SHOP_SETS + STRIKER.SHOP.filter(func(i): return sex_ok(i, String(Game.profile.get("look", {}).get("gender", "m"))))
	var period = int(Time.get_unix_time_from_system() / 600.0)   # 10 dakikada bir yeni stok (30 dk boyunca hep aynı mallar görünüyordu)
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("%s|%s|%d|%s" % [kind, vid, period, String(Game.profile.get("name", ""))])
	var picks = pool.duplicate()
	for i in range(picks.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var t = picks[i]; picks[i] = picks[j]; picks[j] = t
	var out = picks.slice(0, mini(picks.size(), 10 if kind == "w" else 16))
	if kind == "c":   # ANBU setleri yalnız ANBU'ya, Kage seti/şapkası yalnız o köyün Kage'sine (rütbesiz satılıyordu)
		out = out.filter(func(i): return rank_gear_ok(i) and (String(item(i).get("village", "")) == "" or String(item(i).get("village", "")) == Progress.home()))   # başka köyün üniforması satılmaz
		for sid in KAGE_SETS + ANBU_SETS + KAGE_HATS:
			if rank_gear_ok(sid) and not sid in out:
				out.append(sid)
	var bought: Array = Game.profile.get("unique_bought", [])
	for u in 2:
		var uid = make_unique(String(picks[(u * 7 + 3) % picks.size()]), kind, int(rng.randi()))
		if uid != "" and not uid in bought:
			out.insert(0, uid)
	return out


static func fits(id: String, slot: String) -> bool:
	var s: String = item(id).get("slot", "")
	return s == slot or (s == "el" and slot == "sag") or (s == "goz" and slot in ["sag_goz", "sol_goz"]) or (s == "yuz" and slot == "kafa")


static func _hex(c) -> String:
	return Color(c).to_html(false)


## Envantere parça ekler, uid döner
static func grant(p: Dictionary, id: String, equip_slot := "", c1 = null, c2 = null, extra := {}) -> int:
	var it = item(id)
	if it.is_empty():
		return -1
	var uid = int(p.get("gear_uid", 0)) + 1
	p["gear_uid"] = uid
	if String(it.get("slot", "")) == "set":
		# set varsayılanları: üst giysinin ve pantolonun kendi renkleri
		for pt in it.get("parts", []):
			var psl = String(item(String(pt[0])).get("slot", ""))
			if psl == "govde" and c1 == null:
				c1 = pt[1] if pt[1] != null else item(String(pt[0])).get("c1", Color.WHITE)
			elif psl == "bacak" and c2 == null:
				c2 = pt[1] if pt[1] != null else item(String(pt[0])).get("c1", Color.WHITE)
	var g = {"uid": uid, "id": id, "c1": _hex(c1 if c1 != null else it.get("c1", Color.WHITE)), "c2": _hex(c2 if c2 != null else it.get("c2", it.get("c1", Color.WHITE)))}
	g.merge(extra, true)
	p["gear"].append(g)
	if equip_slot != "":
		p["equip"][equip_slot] = uid
	if p == Game.profile:
		teach_weapon_arts(p, id)
	return uid


## Kılıca özgü teknikler (learn "weapon:<id>"): o kılıç ele geçince öğrenilir (Samehada, Kiba, Hiramekarei...)
static func teach_weapon_arts(p: Dictionary, id: String) -> void:
	for jid in Data.jutsu:
		var j = Data.jutsu[jid]
		if not j is Dictionary or String(j.get("learn", "")) != "weapon:" + id or jid in p.get("learned", []):
			continue
		Progress.learn(jid, false)
		Hud.msg("%s ile yeni teknik: %s" % [String(item(id).get("name", id)), String(j.get("name", jid))], Color(0.85, 0.9, 1.0))


## Kuşanılı silah kimlikleri (sağ/sol el, sırt)
## Sahip olunan tüm eşya kimlikleri (kuşanılmamışlar dahil)
static func owned_ids(p: Dictionary) -> Array:
	var out = []
	for g in p.get("gear", []):
		out.append(String(g.get("id", "")))
	return out


static func held_ids(p: Dictionary) -> Array:
	var out = []
	for slot in p.get("equip", {}):
		var g = find(p, p["equip"][slot])
		if not g.is_empty():
			out.append(base_id(String(g["id"])))
	return out


static func find(p: Dictionary, uid) -> Dictionary:
	for g in p.get("gear", []):
		if int(g["uid"]) == int(uid):
			return g
	return {}


## Bu eşya bir yuvada takılı mı? (kayıttan gelen uid'ler float olur: `int in [float]` Godot'ta false döner)
static func is_equipped(p: Dictionary, g: Dictionary) -> bool:
	for s in p.get("equip", {}):
		if int(p["equip"][s]) == int(g.get("uid", -1)):
			return true
	return false


static func equipped(p: Dictionary, slot: String) -> Dictionary:
	return find(p, p.get("equip", {}).get(slot, -1))


## Yuvaya uyan tüm eşyalar; şartı tutmayanlar da listelenir (kilitli gösterilir, takılamaz)
static func owned_for(p: Dictionary, slot: String) -> Array:
	var out = []
	for g in p.get("gear", []):
		if fits(g["id"], slot):
			out.append(g)
	return out


## Geçerli rütbe: kaçakta köy rütbesi donmuş kalır, Bingo Kitabı sınıfı eşdeğer sayılır (C→Genin, B→Chunin, A→Jonin, S→Kage:
## S-rank kaçak Kage seviyesinde sayılır, ANBU/Kage eşyalarını takabilir)
static func eff_rank(p: Dictionary) -> int:
	var r = int(p.get("rank", 0))
	if Orgs.is_rogue() and (Game.profile.is_empty() or p == Game.profile):
		r = maxi(r, [1, 2, 3, 6, 6][clampi(Orgs.rogue_rank(), 0, 4)])
	return r


## Takma şartı karşılanmıyorsa nedenini döndürür ("Chunin rütbesi gerekli"); karşılanıyorsa ""
static func req_text(id: String, p: Dictionary) -> String:
	var it = item(id)
	var need = int(it.get("rank", 0))
	if need > eff_rank(p):
		return "%s rütbesi gerekli" % Data.RANKS[mini(need, Data.RANKS.size() - 1)]
	var iv = String(it.get("village", ""))   # köy üniforması (chūnin/jōnin yeleği vb.): yalnız o köyün ninjaları
	if iv != "" and iv != String(p.get("village", "konoha")):
		return "Yalnızca %s ninjaları giyebilir" % String(Game.village(iv).get("name", iv))
	if KAGE_VID.has(id) and String(KAGE_VID[id]) != String(p.get("village", "konoha")):
		return "Yalnızca %s Kage'si giyebilir" % String(Game.village(String(KAGE_VID[id])).get("name", KAGE_VID[id]))
	var cl = String(it.get("clan", ""))
	if cl != "" and cl != String(p.get("clan", "")):
		return "Yalnızca %s klanı giyebilir" % Data.clans.get(cl, {}).get("name", cl.capitalize())
	var lv = int(it.get("level", 0))
	if lv > int(p.get("level", 1)):
		return "Güç %d gerekli" % lv
	return ""


## Eşyanın şartlarının kısa özeti (şart yoksa ""): kartlarda her zaman gösterilir
static func req_summary(id: String) -> String:
	var it = item(id)
	var parts = []
	if int(it.get("rank", 0)) > 0:
		parts.append("%s rütbesi" % Data.RANKS[mini(int(it["rank"]), Data.RANKS.size() - 1)])
	if String(it.get("clan", "")) != "":
		parts.append("%s klanı" % Data.clans.get(String(it["clan"]), {}).get("name", String(it["clan"]).capitalize()))
	if int(it.get("level", 0)) > 0:
		parts.append("Güç %d" % int(it["level"]))
	return ("Gerekli: " + ", ".join(parts)) if not parts.is_empty() else ""


static func is_eye(id: String) -> bool:
	return String(item(id).get("slot", "")) == "goz"


## Eski kayıtlar / yeni karakter: görünümden başlangıç ekipmanı üretir
static func ensure(p: Dictionary) -> void:
	if p.has("gear") and p.has("equip"):
		var ch = _migrate_sets(p)
		if _ensure_eyes(p) or ch:
			apply_look(p)
		return
	p["gear"] = []
	p["equip"] = {}
	var L: Dictionary = p.get("look", {})
	grant(p, _starter_set(p), "set", L.get("top", null), L.get("pants", null))
	# silahsız başlanır (kunai silah dükkânında); Shiranui ailesi senbon iğneleriyle (Genma)
	if String(p.get("clan", "")) == "shiranui":
		grant(p, "senbon", "sag")
	# Hatake: Hakkō Chakura Tō aile yadigârı (kanon: Sakumo'dan Kakashi'ye) — başlangıçta verilir, dükkânda satılmaz
	if String(p.get("clan", "")) == "hatake":
		grant(p, "hakko_chakura_to", "sag")
	p["flags"] = p.get("flags", {})
	p["flags"]["hatake_kit"] = true
	if L.get("band") != null:
		grant(p, "alin_koruyucu", "kafa", L["band"])   # boyunda takmak artık takılış seçeneği (tek eşya)
	_ensure_eyes(p)
	apply_look(p)


## Karakter yaratıcıdaki önizleme: setin parçalarını görünüme yazar (kıyafet artık sadece set)
const START_SETS := ["set_genin", "set_shinobi", "set_suna", "set_uchiha", "set_goken"]


## Set bu cinsiyete uygun mu ("sex": "f"/"m"; boş = herkes)
static func sex_ok(id: String, gender: String) -> bool:
	var sx = String(item(id).get("sex", ""))
	return sx == "" or sx == gender


## Karakter yaratmada seçilebilen setler: temel setler + Striker'ın temel (C sırası) setleri, cinsiyete göre
static func start_sets(gender: String) -> Array:
	return START_SETS + STRIKER.START.filter(func(i): return sex_ok(i, gender))
static func preview_set_look(L: Dictionary, sid: String) -> void:
	for pt in item(sid).get("parts", []):
		var pit = item(String(pt[0]))
		if pit.is_empty():
			continue
		for k in pit.get("look", {}):
			L[k] = pit["look"][k]
		var c1: Color = pt[1] if pt[1] != null else pit.get("c1", Color.WHITE)
		var c2: Color = pt[2] if pt[2] != null else pit.get("c2", c1)
		match String(pit["slot"]):
			"govde":
				L["top"] = c1; L["top2"] = c2
			"bacak":
				L["pants"] = c1
			"ayak":
				L["sandal"] = c1; L["wraps"] = c2
			"zirh":
				L["vest"] = c1
			"dis":
				L["outer"] = c1
			"kol":
				L["acc"] = c1


static func _starter_set(p: Dictionary) -> String:
	var chosen = String(p.get("look", {}).get("start_set", ""))
	if chosen != "" and (SETS.has(chosen) or STRIKER.SETS.has(chosen)) and int(p.get("rank", 0)) < 2:
		return chosen
	if String(p.get("clan", "")) == "uchiha":
		return "set_uchiha"
	if int(p.get("rank", 0)) >= 4:
		return "set_anbu"
	var vil = String(p.get("village", "konoha"))
	var vk = {"suna": "suna_", "kiri": "kiri_", "kumo": "kumo_", "iwa": "iwa_"}.get(vil, "")
	if int(p.get("rank", 0)) >= 3:
		return "set_%sjonin" % vk
	if int(p.get("rank", 0)) >= 2:
		return "set_%schunin" % vk
	if String(p.get("village", "")) == "suna":
		return "set_suna"
	return "set_genin"


## Eski kayıt: tek tek kıyafet yuvaları (iç içe geçiyordu) -> başlangıç seti; sol el boşaltılır
static func _migrate_sets(p: Dictionary) -> bool:
	var eq: Dictionary = p.get("equip", {})
	var had = false
	# "Alın Koruyucu (Boyunda)" artık ayrı eşya değil, takılış seçeneği: takılıysa alın koruyucuya çevrilip takılış boyun olur,
	# takılı değilse çantadan kalkar (ikinci bir alın koruyucu olmasın)
	var gl: Array = p.get("gear", [])
	for gi in range(gl.size() - 1, -1, -1):
		var g: Dictionary = gl[gi]
		if String(g.get("id", "")) != "alin_boyun":
			continue
		had = true
		if eq.has("kafa") and int(eq["kafa"]) == int(g.get("uid", -1)):
			g["id"] = "alin_koruyucu"
			p["band_wear"] = "boyun"
			for gj in range(gl.size() - 1, -1, -1):   # diğer (takılı olmayan) alın koruyucu kopyası silinir
				if gj != gi and String(gl[gj].get("id", "")) == "alin_koruyucu":
					gl.remove_at(gj)
					break
		else:
			gl.remove_at(gi)
	if eq.has("yuz"):   # yüz yuvası kaldırıldı: kafa boşsa oraya taşınır
		if not eq.has("kafa"):
			eq["kafa"] = eq["yuz"]
		eq.erase("yuz")
		had = true
	for sl in OLD_CLOTH_SLOTS:
		if eq.has(sl):
			eq.erase(sl)
			had = true
	if not eq.has("set"):
		var L: Dictionary = p.get("look", {})
		grant(p, _starter_set(p), "set", L.get("top", null), L.get("top2", null))
		had = true
	return had


## Doğuştan klan gözleri (eski kayıtlar dahil bir kez verilir)
static func _ensure_eyes(p: Dictionary) -> bool:
	var eid = {"uchiha": "goz_sharingan", "hyuga": "goz_byakugan", "chinoike": "goz_ketsuryugan", "otsutsuki": "goz_byakugan"}.get(String(p.get("clan", "")), "")
	# eski kayıt: uyuyan Sharingan -> doğrudan ver (1 tomoe)
	var dormant = String(p.get("flags", {}).get("dormant_eye", ""))
	if dormant != "":
		p["flags"].erase("dormant_eye")
		grant(p, dormant, "sag_goz", null, null, {"lvl": 1, "origin": "dogustan"})
		grant(p, dormant, "sol_goz", null, null, {"lvl": 1, "origin": "dogustan"})
		return true
	if eid == "" or p.get("flags", {}).get("born_eyes", false):
		return false
	for g in p["gear"]:
		if item(g["id"]).get("slot", "") == "goz":
			return false
	grant(p, eid, "sag_goz", null, null, {"lvl": 1, "origin": "dogustan"})
	grant(p, eid, "sol_goz", null, null, {"lvl": 1, "origin": "dogustan"})
	if not p.has("flags"):
		p["flags"] = {}
	p["flags"]["born_eyes"] = true
	return true


## Takılı parçalardan görünüm sözlüğünü yeniden kurar
## Görünüşü gizlenebilen yuvalar: eşya takılı kalır, statları sayılır; yalnız modelde çizilmez (profil "hide_look")
const HIDE_SLOTS := ["sirt", "kafa"]   # görünüşü gizlenebilen yuvalar (kafa: alın koruyucu/bant — statlar sayılır)


static func look_hidden(p: Dictionary, slot: String) -> bool:
	return slot in HIDE_SLOTS and bool((p.get("hide_look", {}) as Dictionary).get(slot, false))


static func apply_look(p: Dictionary) -> void:
	for g0 in p.get("gear", []):   # oyundan kaldırılan Dev Shuriken: eldeki kopyalar Kyodai Shuriken'e döner
		if String(g0.get("id", "")) == "el_shuriken":
			g0["id"] = "kyodai_shuriken"
		elif String(g0.get("id", "")) in ["altin_kunai", "patlayici_kunai"]:   # oyundan kaldırıldı: düz kunaiye döner
			g0["id"] = "kunai"
		elif String(g0.get("id", "")) == "ikiz_hancer":   # oyundan kaldırıldı: tantoya döner
			g0["id"] = "tanto"
		elif String(g0.get("id", "")) == "mizrak":   # oyundan kaldırıldı: bo sopasına döner
			g0["id"] = "bo"
	var L: Dictionary = p["look"]
	# Kage seti giyiliyse şapka o köyün renginde/kanjisinde (Kazekage seti -> yeşil şapka, rüzgâr)
	L["kage_vid"] = {"set_hokage": "konoha", "set_kazekage": "suna", "set_mizukage": "kiri", "set_raikage": "kumo", "set_tsuchikage": "iwa"}.get(String(equipped(p, "set").get("id", "")), null)
	for k in ["band", "vest", "mask", "weapon_r", "weapon_l", "head_style", "face_style", "outer_style", "back_item", "guards", "eye_r", "eye_l", "hood", "crest", "leg_warmers", "neck_warmer", "anbu_arm", "anbu_band", "anbu_leg", "anbu_tasset"]:
		L[k] = null
	L["band_style"] = "none"
	L["band_wear"] = null
	L["gloves"] = false
	L["arm_wraps"] = false
	L["top_pattern"] = 0
	L["hakama"] = false
	L["skirt"] = 0
	L["jk"] = null
	L["kt"] = null
	L["bk"] = null
	L["rg"] = null
	L["st"] = null
	L["by"] = null
	L["fe"] = null
	L["yh"] = null
	L["sw"] = null
	L["uc"] = null
	L["hk"] = null
	L["nd"] = null
	L["kg"] = null
	L["sleeve_roll"] = false
	L["guard_long"] = false
	L["waist_belt"] = null
	L["under_band"] = null
	L["net_pads"] = false
	L["neck_scarf"] = null
	L["armband"] = null
	L["lining"] = null
	L["bangle"] = null
	L["elbow_pads"] = null
	L["rope"] = null
	L["wristband"] = null
	L["necklace"] = null
	L["cin_ust"] = null
	L["gk"] = null
	L["jonin_aks"] = null
	L["fire_sash"] = null
	L["fur_scarf"] = null
	L["bell_cuffs"] = null
	L["shimenawa"] = null
	L["kok_reisi"] = null
	L["chest_pockets"] = false
	L["armband_side"] = 1.0
	L["vest_open"] = false
	L["gi_yelek"] = null
	L["sweater_hem"] = null
	L["wide_sleeve_long"] = false
	L["front_bow"] = null
	L["back_scroll"] = false
	L["armor_apron"] = null
	L["hc_open"] = false
	L["petal_skirt"] = null
	L["long_skirt"] = null
	L["wide_obi"] = null
	L["hiruzen_aks"] = null
	L["belly_wraps"] = null
	L["tunic_belt"] = null
	L["robe_obi"] = null
	L["sash"] = null
	L["guard_ankle"] = null
	L["scarf_front_tail"] = null
	L["robe_stripe"] = null
	L["drape_sash"] = null
	L["kk"] = null
	L["hakama_cut"] = null
	L["pleat_skirt"] = false
	L["wide_sleeve"] = false
	L["holster"] = null   # önceki setin kılıflık ayarı sonrakine geçmesin
	L["leg_fishnet"] = false
	L["pants_pipe"] = null
	L["vest_style"] = 0
	L["foot_style"] = "sandal"
	L["outer_pattern"] = 0
	L["outer_accent"] = null
	L["wear"] = 0.0
	L["rope_belt"] = false
	L["guard_stripes"] = null
	L["knee_wraps"] = false
	L["pants_flap"] = null
	# önceki setin zırhı / desenleri sıfırlanır (Sengoku zırhı başka sete geçince üstte kalıyordu)
	L["armor_style"] = null
	L["pants_pattern"] = 0
	L["foot_pattern"] = 0
	var wear: Array = []   # [yuva, eşya, c1, c2, kayıt]
	for s in SLOTS:
		var g0 = equipped(p, s[0])
		if g0.is_empty():
			continue
		var it0 = item(g0["id"])
		if it0.is_empty():
			continue
		if String(it0.get("slot", "")) == "set":
			# set renkleri: c1 = ÜST (üst giysi), c2 = ALT (pantolon); diğer parçalar setin kendi renkleriyle
			for pt in it0.get("parts", []):
				var pit = item(String(pt[0]))
				if pit.is_empty():
					continue
				var psl = String(pit["slot"])
				var pc1: Color = pt[1] if pt[1] != null else pit.get("c1", Color.WHITE)
				var pc2: Color = pt[2] if pt[2] != null else pit.get("c2", pc1)
				if psl == "govde":
					pc1 = Color.html(g0["c1"])
				elif psl == "bacak":
					pc1 = Color.html(g0["c2"])
				wear.append([psl, pit, pc1, pc2, g0])
		else:
			wear.append([s[0], it0, Color.html(g0["c1"]), Color.html(g0["c2"]), g0])
	for wr in wear:
		if look_hidden(p, String(wr[0])):
			continue   # görünüş gizli: model çizmez (statlar Gear.stat ile ayrıca sayılır)
		var s = [wr[0]]
		var it: Dictionary = wr[1]
		var g: Dictionary = wr[4]
		var c1: Color = wr[2]; var c2: Color = wr[3]
		for k in it.get("look", {}):
			# iki parça aynı bayrağı açabilir (ör. kol sargısı + sargılı üst): açık olan kalsın
			if it["look"][k] is bool and L.get(k) == true:
				continue
			L[k] = it["look"][k]
		var islot: String = it["slot"] if not it["slot"] in ["el", "goz"] else s[0]
		match islot:
			"kafa":
				if it["look"].get("band_style", "none") != "none":
					L["band"] = c1
					L["band_wear"] = String(p.get("band_wear", "alin"))   # oyuncunun seçtiği takılış (ekipman > kafa > Takılış)
				if it["look"].has("head_style"):
					L["headgear"] = c1
					if it["look"]["head_style"] == "bandana":
						L["band"] = c1
			"yuz":
				L["facegear"] = c1
			"govde":
				L["top"] = c1
				L["top2"] = c2
				L["sleeves"] = it["look"]["top_style"] not in ["tisort", "kolsuz"]
			"bacak":
				L["pants"] = c1
				L["pants2"] = c2
			"ayak":
				L["sandal"] = c1
				L["wraps"] = c2
			"zirh":
				L["vest"] = c1
			"dis":
				L["outer"] = c1
				if it.has("c2"):
					L["outer_accent"] = c2
			"kol":
				L["acc"] = c1
			"sirt":
				L["backc"] = c1
			"sag_goz", "sol_goz":
				L["eye_r" if s[0] == "sag_goz" else "eye_l"] = {"kind": int(it["eye"]["kind"]), "lvl": int(g.get("lvl", 3)), "id": g["id"], "origin": g.get("origin", "dogustan")}
			"sag":
				L["weapon_r"] = visual_id(g["id"])
				L["weapon_skin_r"] = skin_id(g["id"])
			"sol":
				L["weapon_l"] = visual_id(g["id"])
				L["weapon_skin_l"] = skin_id(g["id"])
	# kaçak ninja: alın bandının sembolü çizik
	if p.get("flags", {}).get("rogue", false) and L.get("band") != null and String(L.get("band_style", "none")) != "none":
		L["band_style"] = "slashed"


## Takılı parçaların toplam istatistiği
static func stat(p: Dictionary, key: String) -> float:
	var v = 0.0
	for s in SLOTS:
		var g = equipped(p, s[0])
		if not g.is_empty():
			v += float(item(g["id"]).get("stats", {}).get(key, 0.0))
	return v


## Sağ el (yoksa sol el) silahı: {dmg, reach, style}
## Savaşçının giydiği kıyafet seti (oyuncu: Kıyafet Seti yuvası; AI: görünümündeki set_id)
static func set_of(actor) -> Dictionary:
	if actor is Player:
		var g = equipped(Game.profile, "set")
		return {} if g.is_empty() else item(String(g["id"]))
	var lk = actor.get("look") if actor != null and is_instance_valid(actor) else null
	if lk is Dictionary and lk.get("set_id") != null:
		return item(String(lk["set_id"]))
	return {}


## Element güçlendirmesi (silah + set) ve element direnci (set) — oyuncu ve AI aynı kural
static func elem_boost(actor, el: String) -> float:
	if el == "":
		return 0.0
	return float(weapon_of(actor).get("boost", {}).get(el, 0.0)) + float(set_of(actor).get("boost", {}).get(el, 0.0))


static func elem_resist(actor, el: String) -> float:
	if el == "":
		return 0.0
	return clampf(float(set_of(actor).get("resist", {}).get(el, 0.0)), 0.0, 0.9)


## Oyuncu ve AI aynı kural: savaşçının elindeki silahın verisi (yoksa yumruk)
static func weapon_of(actor) -> Dictionary:
	if actor is Player:
		return weapon(Game.profile)
	var lk = actor.get("look") if actor != null and is_instance_valid(actor) else null
	if lk is Dictionary:
		var wid = lk.get("weapon_r")
		if wid != null and String(wid) != "" and item(String(wid)).has("weapon"):
			return item(String(wid))["weapon"]
	return {"dmg": 1.0, "reach": 0.0, "style": "fist"}


static func weapon(p: Dictionary) -> Dictionary:
	for s in ["sag", "sol"]:
		var g = equipped(p, s)
		if not g.is_empty() and item(g["id"]).has("weapon"):
			var w: Dictionary = item(g["id"])["weapon"].duplicate()
			# iki elde de silah varsa küçük bonus
			var other = equipped(p, "sol" if s == "sag" else "sag")
			if not other.is_empty() and item(other["id"]).has("weapon"):
				w["dmg"] = float(w["dmg"]) + 0.15
			return w
	return {"dmg": 1.0, "reach": 0.0, "style": "fist"}


static func stats_text(id: String) -> String:
	var it = item(id)
	var parts = []
	var names = {"def": "Savunma", "hp": "Can", "chakra": "Chakra", "speed": "Hız", "melee": "Yakın dövüş"}
	for k in it.get("stats", {}):
		var v = float(it["stats"][k])
		if k in ["speed", "melee"]:
			parts.append("%s %+d%%" % [names[k], int(round(v * 100))])
		else:
			parts.append("%s %+d" % [names[k], int(v)])
	if it.has("weapon"):
		parts.push_front("Vuruş hasarı %.1f, menzil +%.1fm" % [float(it["weapon"].get("hit", 4.2)), it["weapon"]["reach"]])
	var en = {"katon": "Katon", "suiton": "Suiton", "fuuton": "Fūton", "raiton": "Raiton", "doton": "Doton"}
	var bo: Dictionary = it.get("boost", it.get("weapon", {}).get("boost", {}))
	for e in bo:
		parts.append("%s hasarı %+d%%" % [en.get(e, e), int(round(float(bo[e]) * 100))])
	for e in it.get("resist", {}):
		parts.append("%s'dan alınan hasar -%d%%" % [en.get(e, e), int(round(float(it["resist"][e]) * 100))])
	return ", ".join(parts) if not parts.is_empty() else "—"
