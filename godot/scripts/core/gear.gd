class_name Gear
extends RefCounted
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
	"set_chunin": {"name": "Konoha Chūnin Shōzoku", "slot": "set", "price": 600, "rank": 2, "desc": "Lacivert yüksek yakalı gömlek ve pantolon, omuzluklu yeşil taktik yelek, baldır sargıları.",
		"stats": {"def": 14, "hp": 25, "speed": 0.03}, "c1": Color(0.12, 0.15, 0.3), "c2": Color(0.12, 0.15, 0.3),
		"parts": [["uzun_gomlek", Color(0.12, 0.15, 0.3), Color(0.12, 0.15, 0.3)], ["ninja_pant", Color(0.12, 0.15, 0.3), null], ["chunin_yelek", Color(0.46, 0.56, 0.44), null], ["sandalet", Color(0.12, 0.15, 0.3), Color(0.92, 0.92, 0.9)]]},
	"set_jonin": {"name": "Konoha Jōnin Shōzoku", "slot": "set", "price": 0, "rank": 3, "desc": "Chūnin takımının üstüne parmaksız eldiven; yelek daha koyu yeşil. Katon jutsuları %10 güçlü, Katon'dan alınan hasar %10 az.",
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
		"parts": [["uzun_gomlek", Color(0.12, 0.12, 0.14), Color(0.12, 0.12, 0.14)], ["ninja_pant", Color(0.12, 0.12, 0.14), null], ["akatsuki_pelerini", Color(0.08, 0.08, 0.1), Color(0.8, 0.1, 0.12)], ["sandalet", Color(0.4, 0.3, 0.45), Color(0.92, 0.92, 0.9)]]},
	"set_kage": {"name": "Kage Shōzoku", "slot": "set", "price": 0, "rank": 6, "desc": "Köyün liderinin beyaz cübbesi.",
		"stats": {"def": 16, "chakra": 50, "hp": 30}, "c1": Color(0.95, 0.95, 0.92), "c2": Color(0.8, 0.2, 0.15),
		"parts": [["uzun_gomlek", Color(0.15, 0.2, 0.33), Color(0.12, 0.12, 0.14)], ["ninja_pant", Color(0.15, 0.2, 0.33), null], ["kage_cubbesi", Color(0.95, 0.95, 0.92), Color(0.8, 0.2, 0.15)], ["sandalet", Color(0.12, 0.12, 0.14), Color(0.92, 0.92, 0.9)]]},
}
const SHOP_SETS := ["set_genin", "set_shinobi", "set_chunin", "set_suna_chunin", "set_kiri_chunin", "set_kumo_chunin", "set_iwa_chunin", "set_uchiha", "set_suna"]
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
	"anbu_zirh": {"name": "ANBU Zırhı", "slot": "zirh", "price": 0, "rank": 4, "desc": "Hafif metal göğüs plakası ve omuz koruması.", "stats": {"def": 14, "speed": 0.03}, "look": {"vest_style": 5}, "c1": Color(0.75, 0.75, 0.78)},
	"samuray_zirh": {"name": "Hafif Samuray Zırhı", "slot": "zirh", "price": 1400, "rank": 3, "desc": "Lamel plakalı göğüslük ve omuzluklar. Ağır ama sağlam.", "stats": {"def": 18, "hp": 40, "speed": -0.05}, "look": {"vest_style": 6}, "c1": Color(0.35, 0.2, 0.18)},
	"sengoku_kizil": {"name": "Sengoku Yoroi: Akane", "slot": "zirh", "price": 2600, "rank": 3, "desc": "Savaşan Devletler döneminin kat kat lamel zırhı: geniş omuzluklar, plaka etek, kol koruması. Yangın görmüş kızıl lake.", "stats": {"def": 24, "hp": 60, "speed": -0.06}, "look": {"vest_style": 6, "armor_style": "sengoku"}, "c1": Color(0.55, 0.14, 0.11)},
	"sengoku_lacivert": {"name": "Sengoku Yoroi: Ruri", "slot": "zirh", "price": 2600, "rank": 3, "desc": "Lacivert lake plakalar, gümüş bağcıklar. Su gibi soğukkanlı komutanların zırhı.", "stats": {"def": 22, "chakra": 40, "speed": -0.05}, "look": {"vest_style": 6, "armor_style": "sengoku"}, "c1": Color(0.16, 0.22, 0.38)},
	"sengoku_kara": {"name": "Sengoku Yoroi: Shikkoku", "slot": "zirh", "price": 2600, "rank": 3, "desc": "Kömür karası plakalar, koyu kırmızı bağcıklar. Yenilmez bir klan reisine yaraşır.", "stats": {"def": 23, "melee": 0.06, "speed": -0.05}, "look": {"vest_style": 6, "armor_style": "sengoku"}, "c1": Color(0.15, 0.14, 0.15)},
	"sengoku_kahve": {"name": "Sengoku Yoroi: Kogecha", "slot": "zirh", "price": 2600, "rank": 3, "desc": "Toprak kahvesi lake, bronz bağcıklar. Uzun seferlerin yorgun ama sağlam zırhı.", "stats": {"def": 25, "hp": 40, "speed": -0.06}, "look": {"vest_style": 6, "armor_style": "sengoku"}, "c1": Color(0.4, 0.27, 0.17)},
	"deri_yelek": {"name": "Deri Yelek", "slot": "zirh", "price": 350, "rank": 1, "desc": "Paralı askerlerin sevdiği kalın yelek.", "stats": {"def": 6}, "look": {"vest_style": 0}, "c1": Color(0.4, 0.3, 0.2)},
	# --- dış giysi
	"kage_cubbesi": {"name": "Kage Cübbesi", "slot": "dis", "price": 0, "rank": 6, "desc": "Köyün liderinin beyaz cübbesi; eteğinde köyün rengi ve Kage yazısı.", "stats": {"def": 10, "chakra": 60, "hp": 40}, "look": {"outer_style": "palto"}, "c1": Color(0.96, 0.95, 0.92)},
	"kage_sapkasi": {"name": "Kage Şapkası", "slot": "kafa", "price": 0, "rank": 6, "desc": "Geniş kenarlı tören şapkası. Önünde köyün kanjisi.", "stats": {"def": 4, "chakra": 30}, "look": {"head_style": "kage"}, "c1": Color(0.95, 0.94, 0.9)},
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
	"kol_sargisi": {"name": "Kol Sargısı", "slot": "kol", "price": 30, "rank": 0, "desc": "Ön kolları saran bandaj.", "stats": {"melee": 0.03}, "look": {"arm_wraps": true}, "c1": Color(0.92, 0.92, 0.9)},
	"bacak_koruma": {"name": "Kaval Koruyucu", "slot": "kol", "price": 180, "rank": 0, "desc": "Kaval kemiğini saran metal plaka.", "stats": {"def": 3, "melee": 0.03}, "look": {"guards": "bacak"}, "c1": Color(0.55, 0.58, 0.62)},
	"iwa_pant": {"name": "Iwa Kanatlı Pantolonu", "slot": "bacak", "price": 0, "rank": 1, "desc": "Bir yanından dize kadar koyu kanat sarkan pantolon.", "stats": {"def": 2}, "look": {"pants_style": "ninja", "pants_flap": Color(0.48, 0.07, 0.1)}, "c1": Color(0.72, 0.16, 0.2)},
	"kiri_koruma": {"name": "Kiri Koruyucuları", "slot": "kol", "price": 0, "rank": 1, "desc": "Çizgili kol ve kaval koruyucuları.", "stats": {"def": 3}, "look": {"guards": "ikisi", "guard_stripes": Color(0.86, 0.92, 1.0)}, "c1": Color(0.6, 0.72, 0.9)},
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
	"kabuto_kizil": {"name": "Kızıl Lake Kabuto", "slot": "kafa", "price": 1600, "rank": 3, "desc": "Komutanların kırmızı lake miğferi.", "stats": {"def": 11, "hp": 35, "speed": -0.03}, "look": {"head_style": "kabuto"}, "c1": Color(0.55, 0.1, 0.1)},
	"tengai": {"name": "Tengai", "slot": "kafa", "price": 220, "rank": 0, "desc": "Yüzü tamamen örten derin hasır sepet şapka. Gezgin keşişlerin kimliği gizlidir.", "stats": {"def": 2, "chakra": 25}, "look": {"head_style": "tengai"}, "c1": Color(0.72, 0.6, 0.38)},
	"golge_kapuson": {"name": "Gölge Kapüşonu", "slot": "kafa", "price": 380, "rank": 1, "desc": "Koyu, derin kapüşon. Suikastçıların sevdiği.", "stats": {"def": 2, "speed": 0.04}, "look": {"head_style": "kapuson"}, "c1": Color(0.1, 0.1, 0.12)},
	"col_kapusonu": {"name": "Çöl Kapüşonu", "slot": "kafa", "price": 160, "rank": 0, "desc": "Kum rengi hafif kapüşon.", "stats": {"def": 2, "hp": 10}, "look": {"head_style": "kapuson"}, "c1": Color(0.78, 0.68, 0.5)},
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
	"akatsuki_pelerini": {"name": "Kızıl Bulut Pelerini", "slot": "dis", "price": 0, "rank": 3, "desc": "Akatsuki üyelerinin dik yakalı siyah pelerini; beyaz kenarlı kızıl bulutlar.", "stats": {"def": 10, "chakra": 50, "hp": 40}, "look": {"outer_style": "org_pelerin", "outer_pattern": 6}, "c1": Color(0.05, 0.05, 0.07), "c2": Color(0.78, 0.08, 0.1)},
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
	"altin_kunai": {"name": "Chakra Metali Kunai", "slot": "el", "price": 600, "rank": 2, "desc": "Chakra iletebilen özel metalden kunai.", "stats": {"chakra": 15}, "weapon": {"hit": 5, "dmg": 1.35, "reach": 0.2, "style": "blade"}, "c1": Color(0.85, 0.7, 0.3)},
	"patlayici_kunai": {"name": "Etiketli Kunai", "slot": "el", "price": 260, "rank": 1, "desc": "Sapına patlayıcı etiket sarılı kunai. Darbeler sert.", "stats": {}, "weapon": {"hit": 5, "dmg": 1.3, "reach": 0.15, "style": "blade"}, "c1": Color(0.6, 0.62, 0.66)},
	"zincirli_kunai": {"name": "Zincirli Kunai", "slot": "el", "price": 300, "rank": 1, "desc": "Halkasına zincir bağlı kunai: menzil uzar.", "stats": {}, "weapon": {"hit": 5, "dmg": 1.2, "reach": 0.6, "style": "blade"}, "c1": Color(0.6, 0.62, 0.66)},
	"senbon": {"name": "Senbon İğneleri", "slot": "el", "price": 120, "rank": 0, "desc": "İnce iğneler: hızlı, isabetli, düşük hasar.", "stats": {"speed": 0.02}, "weapon": {"hit": 4.5, "dmg": 1.1, "reach": 0.1, "style": "dual"}, "c1": Color(0.75, 0.77, 0.8)},
	"tanto": {"name": "Tantō", "slot": "el", "price": 320, "rank": 1, "desc": "Kısa kılıç. Hızlı ve keskin.", "stats": {}, "weapon": {"hit": 5, "dmg": 1.35, "reach": 0.35, "style": "blade"}, "c1": Color(0.75, 0.77, 0.8)},
	"ikiz_hancer": {"name": "Hançer", "slot": "el", "price": 240, "rank": 0, "desc": "Çift taşınmak için dengelenmiş kısa hançer.", "stats": {"speed": 0.02}, "weapon": {"hit": 5, "dmg": 1.25, "reach": 0.25, "style": "dual"}, "c1": Color(0.7, 0.72, 0.76)},
	"kama": {"name": "Kama (Orak)", "slot": "el", "price": 280, "rank": 1, "desc": "Kavisli tarım orağından savaş aleti.", "stats": {}, "weapon": {"hit": 5, "dmg": 1.35, "reach": 0.3, "style": "sickle"}, "c1": Color(0.7, 0.72, 0.76)},
	"pence": {"name": "Pençe", "slot": "el", "price": 400, "rank": 1, "desc": "Parmaklara takılan üç metal tırnak.", "stats": {"melee": 0.08}, "weapon": {"hit": 5, "dmg": 1.25, "reach": 0.2, "style": "claw"}, "c1": Color(0.6, 0.62, 0.66)},
	"musta": {"name": "Muşta Bıçağı", "slot": "el", "price": 450, "rank": 1, "desc": "Parmak korumalı bıçak. Rüzgar chakrası akıtılabilir.", "stats": {"melee": 0.1}, "weapon": {"hit": 5, "dmg": 1.3, "reach": 0.25, "style": "blade"}, "c1": Color(0.55, 0.57, 0.6)},
	"chakra_bicak": {"name": "Chakra Bıçakları", "slot": "el", "price": 1100, "rank": 3, "desc": "Chakra ile parlayan çift bıçak. Elementini taşır.", "stats": {"melee": 0.12, "chakra": 15}, "weapon": {"hit": 6, "dmg": 1.55, "reach": 0.3, "style": "dual"}, "c1": Color(0.55, 0.8, 1.0)},
	"tonfa": {"name": "Tonfa", "slot": "el", "price": 220, "rank": 0, "desc": "Savunma sopası. Gelen hasarı azaltır.", "stats": {"def": 4}, "weapon": {"hit": 5, "dmg": 1.2, "reach": 0.3, "style": "blade"}, "c1": Color(0.35, 0.25, 0.15)},
	"wakizashi": {"name": "Wakizashi", "slot": "el", "price": 520, "rank": 1, "desc": "Orta boy yan kılıç. Çift kılıç tekniğine uygun.", "stats": {}, "weapon": {"hit": 5.5, "dmg": 1.45, "reach": 0.55, "style": "sword"}, "c1": Color(0.78, 0.8, 0.84)},
	"katana": {"name": "Katana", "slot": "sag", "price": 900, "rank": 2, "desc": "Uzun kılıç. Geniş kesişler, yüksek hasar.", "stats": {"speed": -0.02}, "weapon": {"hit": 6.5, "dmg": 1.7, "reach": 0.9, "style": "sword"}, "c1": Color(0.78, 0.8, 0.84)},
	"nodachi": {"name": "Nodachi", "slot": "sag", "price": 1500, "rank": 3, "desc": "İnsan boyunda dev kılıç. Yavaş ama yıkıcı.", "stats": {"speed": -0.05}, "weapon": {"hit": 7.5, "dmg": 2.1, "reach": 1.3, "style": "heavy"}, "c1": Color(0.75, 0.77, 0.8)},
	"savas_cekici": {"name": "Savaş Çekici", "slot": "sag", "price": 1200, "rank": 2, "desc": "Uzun saplı demir çekiç. Zırhı ezer.", "stats": {"speed": -0.06, "def": 2}, "weapon": {"hit": 7, "dmg": 2.0, "reach": 0.9, "style": "heavy"}, "c1": Color(0.4, 0.4, 0.42)},
	# Maymun Kral'ın dönüştüğü asa (yalnız çağrı süresince elde): vuruşta uzar
	"kongo_asa": {"name": "Elmas Asa (Kongō Nyoi)", "slot": "sag", "price": 0, "rank": 4, "desc": "Maymun Kral'ın dönüştüğü kırılmaz asa. Vuruşta boyu uzar.", "stats": {"def": 6, "melee": 0.15}, "weapon": {"hit": 7.5, "dmg": 2.1, "reach": 1.9, "style": "staff", "special": "extend"}, "c1": Color(0.12, 0.12, 0.14)},
	"bo": {"name": "Bō Sopası", "slot": "sag", "price": 180, "rank": 0, "desc": "Uzun ahşap sopa. Geniş vuruş alanı.", "stats": {"def": 2}, "weapon": {"hit": 5, "dmg": 1.3, "reach": 1.0, "style": "staff"}, "c1": Color(0.45, 0.32, 0.2)},
	"mizrak": {"name": "Yari Mızrağı", "slot": "sag", "price": 650, "rank": 2, "desc": "Uzun mızrak. En uzun menzil.", "stats": {}, "weapon": {"hit": 6, "dmg": 1.55, "reach": 1.4, "style": "staff"}, "c1": Color(0.75, 0.77, 0.8)},
	"kusarigama": {"name": "Kusarigama", "slot": "sag", "price": 780, "rank": 2, "desc": "Zincirli orak: uzak ve yakın dövüş bir arada.", "stats": {"melee": 0.05}, "weapon": {"hit": 5.5, "dmg": 1.5, "reach": 1.1, "style": "chain"}, "c1": Color(0.7, 0.72, 0.76)},
	"el_shuriken": {"name": "Dev Shuriken", "slot": "sag", "price": 700, "rank": 2, "desc": "Elde tutulan dev dört kollu shuriken. Kesici savuruşlar.", "stats": {}, "weapon": {"hit": 6, "dmg": 1.6, "reach": 0.8, "style": "heavy"}, "c1": Color(0.5, 0.52, 0.56)},
	"yelpaze": {"name": "Savaş Yelpazesi", "slot": "sag", "price": 700, "rank": 2, "desc": "Büyük demir yelpaze. Fuuton jutsularını güçlendirir.", "stats": {"chakra": 30}, "weapon": {"hit": 5.5, "dmg": 1.4, "reach": 0.8, "style": "fan"}, "c1": Color(0.85, 0.82, 0.75)},
	# --- gözler (goz = sağ/sol göz yuvasına takılır; satılmaz). Örnek başına "lvl" (tomoe 1-3) ve "origin" (dogustan/nakil)
	"goz_sharingan": {"name": "Sharingan", "slot": "goz", "price": 0, "rank": 0, "desc": "Uchiha'nın kopyalayan gözü. Hareketleri önceden okur.", "stats": {"melee": 0.05, "chakra": 10}, "eye": {"kind": 1, "name": "Sharingan"}, "c1": Color(0.8, 0.05, 0.08)},
	"goz_mangekyo": {"name": "Mangekyō Sharingan", "slot": "goz", "price": 0, "rank": 0, "desc": "Büyük acıyla uyanan kaleydoskop göz. Güçlü ama kör eder.", "stats": {"melee": 0.1, "chakra": 30}, "eye": {"kind": 4, "name": "Mangekyō Sharingan"}, "c1": Color(0.8, 0.05, 0.08)},
	"goz_ems": {"name": "Ebedi Mangekyō Sharingan", "slot": "goz", "price": 0, "rank": 0, "desc": "Kardeş gözüyle birleşen, ışığı sönmeyen Mangekyō.", "stats": {"melee": 0.15, "chakra": 50}, "eye": {"kind": 5, "name": "Ebedi Mangekyō"}, "c1": Color(0.8, 0.05, 0.08)},
	"goz_rinnegan": {"name": "Rinnegan", "slot": "goz", "price": 0, "rank": 0, "desc": "Halkalı efsanevi göz. Altı yolun gücü.", "stats": {"chakra": 80}, "eye": {"kind": 6, "name": "Rinnegan"}, "c1": Color(0.6, 0.5, 0.85)},
	"goz_byakugan": {"name": "Byakugan", "slot": "goz", "price": 0, "rank": 0, "desc": "Hyūga'nın her yönü gören beyaz gözü.", "stats": {"melee": 0.08, "def": 2}, "eye": {"kind": 2, "name": "Byakugan"}, "c1": Color(0.9, 0.9, 0.96)},
	"goz_ketsuryugan": {"name": "Ketsuryūgan", "slot": "goz", "price": 0, "rank": 0, "desc": "Chinoike'nin kan rengi gözü: genjutsu ve kan teknikleri.", "stats": {"chakra": 20, "melee": 0.05}, "eye": {"kind": 3, "name": "Ketsuryūgan"}, "c1": Color(0.7, 0.08, 0.1)},
	"goz_tenseigan": {"name": "Tenseigan", "slot": "goz", "price": 0, "rank": 0, "desc": "Ay ışığı gibi parlayan, çekim ve itme gücü veren göz.", "stats": {"chakra": 60, "def": 4}, "eye": {"kind": 7, "name": "Tenseigan"}, "c1": Color(0.55, 0.75, 1.0)},
	"goz_jogan": {"name": "Jōgan", "slot": "goz", "price": 0, "rank": 0, "desc": "Görünmeyeni gören gizemli göz.", "stats": {"chakra": 40, "speed": 0.04}, "eye": {"kind": 8, "name": "Jōgan"}, "c1": Color(0.45, 0.65, 1.0)},
	# --- efsanevi silahlar (satılmaz: S/A görevleri ve boss ödülü). special: vuruş yeteneği
	"kubikiribocho": {"name": "Kubikiribōchō", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Sis'in Yedi Kılıcı'ndan dev satır. Delikli ağzı kesilenin kanıyla kendini onarır: vuruşlar can çalar.", "stats": {"hp": 40, "speed": -0.06}, "weapon": {"hit": 8.5, "dmg": 2.4, "reach": 1.3, "style": "heavy", "special": "lifesteal"}, "c1": Color(0.78, 0.8, 0.84)},
	"samehada": {"name": "Samehada", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Pullarla kaplı, sargılı canlı kılıç. Değdiği düşmanın chakrasını emer. Kuşanılıyken Suiton jutsuları %10 güçlü.", "stats": {"chakra": 60, "speed": -0.05}, "weapon": {"hit": 7.5, "dmg": 2.2, "reach": 1.2, "style": "heavy", "special": "drain", "boost": {"suiton": 0.10}}, "c1": Color(0.25, 0.32, 0.5)},
	"kiba": {"name": "Kiba (İkiz Yıldırım Kılıcı)", "slot": "el", "price": 0, "rank": 4, "legend": true, "desc": "Yedi Kılıç'tan ikiz dişli kılıçlar. Raiton taşır: sersemletir. İki ele birden kuşan.", "stats": {"speed": 0.04}, "weapon": {"hit": 6.5, "dmg": 1.8, "reach": 0.8, "style": "sword", "special": "raiton"}, "c1": Color(0.95, 0.85, 0.35)},
	"hiramekarei": {"name": "Hiramekarei", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Çift saplı geniş kılıç. Chakra depolar, ağzını uzatıp devasa bir bıçağa çevirir.", "stats": {"chakra": 40}, "weapon": {"hit": 7.5, "dmg": 2.1, "reach": 1.7, "style": "heavy", "special": "extend"}, "c1": Color(0.3, 0.45, 0.75)},
	"shibuki": {"name": "Shibuki", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Kalın mor rulolu, ağzı patlayıcı mühür kâğıtlarından kılıç. Ağır: rulo arkadan savrulur; her darbe patlar, kâğıtları serpip uzaktan da patlatır.", "stats": {"def": 2}, "weapon": {"hit": 7, "dmg": 2.0, "reach": 1.1, "style": "heavy", "special": "explode"}, "c1": Color(0.85, 0.8, 0.65)},
	"nuibari": {"name": "Nuibari", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Telli dev iğne-kılıç. Saplanır ve düşmanı sana çeker.", "stats": {"speed": 0.05}, "weapon": {"hit": 6.5, "dmg": 1.7, "reach": 1.6, "style": "staff", "special": "pull"}, "c1": Color(0.8, 0.82, 0.86)},
	"kabutowari": {"name": "Kabutowari", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Halatla birbirine bağlı balta (sağ el) ve çekiç (sol el). Çekiç baltayı kama gibi çakar: savunmayı ve zırhı parçalar.", "stats": {"def": 4, "speed": -0.06}, "weapon": {"hit": 8, "dmg": 2.3, "reach": 1.0, "style": "heavy", "special": "armor_break"}, "c1": Color(0.45, 0.45, 0.48)},
	"chokuto": {"name": "Kusanagi Tarzı Chokutō", "slot": "sag", "price": 0, "rank": 3, "legend": true, "desc": "Düz ağızlı efsanevi kılıç. İçinden akıtılan chakra keskinliği arttırır.", "stats": {"speed": 0.04, "melee": 0.1}, "weapon": {"hit": 7, "dmg": 1.95, "reach": 1.0, "style": "sword", "special": "flow"}, "c1": Color(0.85, 0.87, 0.9)},
	"raijin": {"name": "Raijin Kılıcı", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Saf yıldırım chakrasından oluşan ağız. Gök gürültüsüyle keser.", "stats": {"chakra": 30}, "weapon": {"hit": 7, "dmg": 2.0, "reach": 1.2, "style": "sword", "special": "raiton"}, "c1": Color(1.0, 0.9, 0.3)},
	"ruzgar_bicak": {"name": "Rüzgar Chakra Bıçakları", "slot": "el", "price": 0, "rank": 3, "legend": true, "desc": "Fuuton chakrası akıtılan muşta bıçakları: görünmez ağız menzili uzatır.", "stats": {"melee": 0.12}, "weapon": {"hit": 6.5, "dmg": 1.75, "reach": 0.8, "style": "dual", "special": "wind"}, "c1": Color(0.55, 1.0, 0.75)},
	"fuma_shuriken": {"name": "Fūma Shuriken", "slot": "sag", "price": 0, "rank": 3, "legend": true, "desc": "Yel değirmeni gibi açılan dev dört kollu shuriken.", "stats": {"speed": 0.02}, "weapon": {"hit": 7, "dmg": 1.9, "reach": 1.1, "style": "heavy", "special": "wind"}, "c1": Color(0.55, 0.57, 0.62)},
	"bashosen": {"name": "Bashōsen", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Altı Yolun Bilgesi'nin hazine yelpazesi: kırmızı uçlu beyaz tüyler. Bashōsen tekniklerini (Kaze/Hi/Rai/Mizu no Maki) yalnız bu yelpaze kuşanılmışken atabilirsin.", "stats": {"chakra": 40}, "weapon": {"hit": 5.5, "dmg": 1.5, "reach": 0.9, "style": "fan"}, "c1": Color(0.72, 0.1, 0.2)},
	"gunbai": {"name": "Gunbai Savaş Yelpazesi", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Dev yuvarlak demir yelpaze. Savuruşu fırtına gibi iter, kendisi kalkan olur. Kuşanılıyken Katon jutsuları %10 güçlü.", "stats": {"def": 10, "chakra": 20}, "weapon": {"hit": 6.5, "dmg": 1.8, "reach": 1.1, "style": "fan", "special": "gust", "boost": {"katon": 0.10}}, "c1": Color(0.75, 0.15, 0.15)},
	"uc_tirpan": {"name": "Üç Bıçaklı Tırpan", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Kızıl üç bıçaklı dev tırpan. Ağır: iki elle arkadan savrulur; biçer, bacak keser, kancayla çeker, yere saplanır, havaya fırlatır.", "stats": {"melee": 0.1}, "weapon": {"hit": 7.5, "dmg": 2.15, "reach": 1.4, "style": "heavy"}, "c1": Color(0.75, 0.12, 0.12)},
	"sai": {"name": "Sai", "slot": "el", "price": 380, "rank": 1, "desc": "Üç dişli savunma hançeri. Bloklarken saldırıyı kilitler.", "stats": {"def": 3}, "weapon": {"hit": 5, "dmg": 1.25, "reach": 0.2, "style": "dual"}, "c1": Color(0.7, 0.72, 0.76)},
}

## Efsanevi silahlar (dükkânda yok; A/S görevleri, boss düşürmesi)
const LEGENDARY := ["kubikiribocho", "samehada", "kiba", "hiramekarei", "shibuki", "nuibari", "kabutowari", "chokuto", "raijin", "ruzgar_bicak", "fuma_shuriken", "gunbai", "bashosen", "uc_tirpan"]


static func random_legendary() -> String:
	# Sis'in Yedi Kılıcı ganimet olarak düşmez: sahibini yenerek alınır (Swordsmen)
	return LEGENDARY.filter(func(x): return not x in MistSwords.IDS).pick_random()

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
const SHOP_WEAPONS := ["sai", "kunai", "senbon", "ikiz_hancer", "tonfa", "bo", "tanto", "kama", "patlayici_kunai", "zincirli_kunai", "pence", "musta",
	"wakizashi", "altin_kunai", "katana", "mizrak", "yelpaze", "el_shuriken", "kusarigama", "savas_cekici", "chakra_bicak", "nodachi"]
## Sadece görev ödülü olarak düşen (dükkânda satılmayan) parçalar dahil ödül havuzu
const REWARD_POOL := ["kafa_bandaji", "gozluk", "kasa", "kapuson", "atki", "kol_sargisi", "eldiven", "kolluk", "bacak_koruma", "tabi", "hakama",
	"kisa_pelerin", "haori", "dev_parsomen", "sirt_shuriken", "senbon", "kama", "pence", "zincirli_kunai", "wakizashi", "altin_kunai",
	"suna_yelek", "kiri_yelek", "kumo_yelek", "iwa_yelek", "chakra_bicak", "nodachi", "samuray_zirh", "uzun_palto", "anbu_kurt", "anbu_kus", "anbu_ayi",
	"hachimaki_kizil", "jingasa", "kabuto", "kabuto_kizil", "mempo", "mempo_kizil", "golge_kapuson", "arma_gomlek", "beyaz_arma", "golge_ust", "panel_ceket",
	"siyah_pant", "kizil_hakama", "zirhli_cizme", "siyah_tabi", "zincir_yelek", "deri_pul_zirh", "lake_zirh", "jonin_koyu", "jinbaori", "sennin_haorisi",
	"bantli_palto", "gece_pelerini", "omuz_zirhi", "agir_zirh", "bel_parsomenleri", "sashimono", "anbu_tilki", "anbu_kaplan", "anbu_yilan", "anbu_maymun",
	"org_pelerini", "kok_yelek", "cizik_alin"]


## Görev ödülü: rütbeye uygun rastgele parça (yoksa "")
static func random_reward(rank: int) -> String:
	var pool = REWARD_POOL.filter(func(id): return int(ITEMS[id].get("rank", 0)) <= rank)
	return pool.pick_random() if not pool.is_empty() else ""


static func item(id: String) -> Dictionary:
	if ITEMS.has(id):
		return ITEMS[id]
	if SETS.has(id):
		return SETS[id]
	if id.begins_with("u_"):
		return _custom().get(id, {})
	return {}


## Görünüm/kın için taban eşya: benzersiz eşyalar ("Ay Işığı Katana" = u_...) modeli bulunamayıp kısa bıçağa düşüyordu.
## Eski kayıtlarda taban kaydı yoksa addan bulunur (ön ek + taban adı) ve saklanır.
static func visual_id(id: String) -> String:
	if not id.begins_with("u_"):
		return id
	var it: Dictionary = item(id)
	if it.has("base"):
		return String(it["base"])
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


## Dükkân stoku: her 30 dakikada (gerçek zaman) köye göre değişen rastgele seçim + 2 benzersiz eşya
static func shop_stock(kind: String, vid: String) -> Array:
	var pool: Array = SHOP_WEAPONS if kind == "w" else SHOP_CLOTHES.filter(func(i): return not String(item(i).get("slot", "")) in OLD_CLOTH_SLOTS) + SHOP_SETS
	var period = int(Time.get_unix_time_from_system() / 1800.0)
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("%s|%s|%d|%s" % [kind, vid, period, String(Game.profile.get("name", ""))])
	var picks = pool.duplicate()
	for i in range(picks.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var t = picks[i]; picks[i] = picks[j]; picks[j] = t
	var out = picks.slice(0, mini(picks.size(), 10 if kind == "w" else 16))
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
			out.append(String(g["id"]))
	return out


static func find(p: Dictionary, uid) -> Dictionary:
	for g in p.get("gear", []):
		if int(g["uid"]) == int(uid):
			return g
	return {}


static func equipped(p: Dictionary, slot: String) -> Dictionary:
	return find(p, p.get("equip", {}).get(slot, -1))


## Yuvaya uyan tüm eşyalar; şartı tutmayanlar da listelenir (kilitli gösterilir, takılamaz)
static func owned_for(p: Dictionary, slot: String) -> Array:
	var out = []
	for g in p.get("gear", []):
		if fits(g["id"], slot):
			out.append(g)
	return out


## Takma şartı karşılanmıyorsa nedenini döndürür ("Chunin rütbesi gerekli"); karşılanıyorsa ""
static func req_text(id: String, p: Dictionary) -> String:
	var it = item(id)
	var need = int(it.get("rank", 0))
	if need > int(p.get("rank", 0)):
		return "%s rütbesi gerekli" % Data.RANKS[mini(need, Data.RANKS.size() - 1)]
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
	grant(p, "kunai", "sag")
	if L.get("band") != null:
		grant(p, "alin_koruyucu", "kafa", L["band"])
		grant(p, "alin_boyun", "", L["band"])
	_ensure_eyes(p)
	apply_look(p)


## Karakter yaratıcıdaki önizleme: setin parçalarını görünüme yazar (kıyafet artık sadece set)
const START_SETS := ["set_genin", "set_shinobi", "set_suna", "set_uchiha"]
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
	if chosen != "" and SETS.has(chosen) and int(p.get("rank", 0)) < 2:
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
static func apply_look(p: Dictionary) -> void:
	var L: Dictionary = p["look"]
	for k in ["band", "vest", "mask", "weapon_r", "weapon_l", "head_style", "face_style", "outer_style", "back_item", "guards", "eye_r", "eye_l"]:
		L[k] = null
	L["band_style"] = "none"
	L["gloves"] = false
	L["arm_wraps"] = false
	L["top_pattern"] = 0
	L["hakama"] = false
	L["vest_style"] = 0
	L["foot_style"] = "sandal"
	L["outer_pattern"] = 0
	L["outer_accent"] = null
	L["wear"] = 0.0
	L["rope_belt"] = false
	L["guard_stripes"] = null
	L["knee_wraps"] = false
	L["pants_flap"] = null
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
			"sol":
				L["weapon_l"] = visual_id(g["id"])
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
