extends RefCounted
## ELLE YAPILMIŞ SİLAH KOMBOLARI — TEK KAYIT. Oyuncu (PlayerCombat) ve yapay zekâ (Enemy) ikisi de buradan okur:
## yeni bir silah animasyonu (X_anim.gd, steps() -> 5-6 adım) yalnız buraya eklenir, düşmanlar da otomatik kullanır.
## [adım betiği, hız çarpanı]
const TABLE := {
	"samehada": [preload("res://scripts/combat/samehada_kombo.gd"), 1.05],   # yeni ağır kombo (eski video kombosu samehada_anim.gd)
	"gunbai": [preload("res://scripts/combat/gunbai_anim.gd"), 1.05],   # ağır silah ritmi
	"kunai": [preload("res://scripts/combat/kunai_anim.gd"), 1.0],
	"raijin": [preload("res://scripts/combat/raijin_anim.gd"), 1.0],
	"uc_tirpan": [preload("res://scripts/combat/tirpan_anim.gd"), 1.0],
	"shibuki": [preload("res://scripts/combat/shibuki_anim.gd"), 1.0],
	"kabutowari": [preload("res://scripts/combat/kabuto_anim.gd"), 1.0],
	"chakra_bicak": [preload("res://scripts/combat/asuma_anim.gd"), 1.0],
	"ruzgar_bicak": [preload("res://scripts/combat/ruzgar_anim.gd"), 1.0],
	"sai": [preload("res://scripts/combat/sai_anim.gd"), 1.0],
	"hiraishin_kunai": [preload("res://scripts/combat/hiraishin_anim.gd"), 1.0],
	"homatsu_kiseru": [preload("res://scripts/combat/kiseru_anim.gd"), 1.0],
	"kusanagi": [preload("res://scripts/combat/kusanagi_anim.gd"), 1.0],
	"kusarigama": [preload("res://scripts/combat/kusarigama_anim.gd"), 1.0],
	"fuma_shuriken": [preload("res://scripts/combat/fuma_anim.gd"), 1.0],
	"kyodai_shuriken": [preload("res://scripts/combat/kyodai_anim.gd"), 0.95],
	"fuma_makimono": [preload("res://scripts/combat/makimono_anim.gd"), 1.0],
	"nuibari": [preload("res://scripts/combat/nuibari_anim.gd"), 1.0],
	"savas_cekici": [preload("res://scripts/combat/cekic_anim.gd"), 0.95],
	"zincirli_kunai": [preload("res://scripts/combat/zkunai_anim.gd"), 1.0],
	"tonfa": [preload("res://scripts/combat/tonfa_anim.gd"), 1.05],
	"bashosen": [preload("res://scripts/combat/bashosen_anim.gd"), 1.0],
	"kubikiribocho": [preload("res://scripts/combat/kubikiri_anim.gd"), 0.95],
	"yagura_sopa": [preload("res://scripts/combat/yagura_anim.gd"), 1.0],
	"yelpaze": [preload("res://scripts/combat/tessen_anim.gd"), 1.0],
	"temari_ogi": [preload("res://scripts/combat/temari_anim.gd"), 1.0],   # Temari'nin dev yelpazesi: ay mekaniği
	"kongo_asa": [preload("res://scripts/combat/kongo_anim.gd"), 1.0],
	"kama": [preload("res://scripts/combat/orak_anim.gd"), 1.0],
	"pence": [preload("res://scripts/combat/pence_anim.gd"), 1.05],
	"senbon": [preload("res://scripts/combat/senbon_anim.gd"), 1.0],
	"hiramekarei": [preload("res://scripts/combat/hirame_anim.gd"), 1.0],
	"bo": [preload("res://scripts/combat/bo_anim.gd"), 1.05],
	"kiba": [preload("res://scripts/combat/kiba_anim.gd"), 1.0],
	"tanto": [preload("res://scripts/combat/tanto_anim.gd"), 1.05],
	"mateki": [preload("res://scripts/combat/mateki_anim.gd"), 1.0],   # Tayuya flütü
	"hakko_chakura_to": [preload("res://scripts/combat/hakko_anim.gd"), 1.15],   # Hatake beyaz ışık tantōsu: kendi kombosu
	"wakizashi": [preload("res://scripts/combat/wakizashi_anim.gd"), 1.0],
	"nodachi": [preload("res://scripts/combat/nodachi_anim.gd"), 0.95],
	"musta": [preload("res://scripts/combat/musta_anim.gd"), 1.05],
	# dövüş tarzları (silahsız düz vuruş; FightingStyles)
	"style_juken": [preload("res://scripts/combat/style_juken_anim.gd"), 1.05],
	"style_akimichi": [preload("res://scripts/combat/style_akimichi_anim.gd"), 0.92],
	"style_inuzuka": [preload("res://scripts/combat/style_inuzuka_anim.gd"), 1.1],
	"style_kaguya": [preload("res://scripts/combat/style_kaguya_anim.gd"), 1.0],
	"style_uchiha": [preload("res://scripts/combat/style_uchiha_anim.gd"), 1.05],
	"style_hozuki": [preload("res://scripts/combat/style_hozuki_anim.gd"), 1.0],
	"style_aburame": [preload("res://scripts/combat/style_aburame_anim.gd"), 1.0],
	"style_jugo": [preload("res://scripts/combat/style_jugo_anim.gd"), 0.92],
	"style_yuki": [preload("res://scripts/combat/style_yuki_anim.gd"), 1.1],
	"style_sabaku": [preload("res://scripts/combat/style_sabaku_anim.gd"), 0.95],
	"style_uzumaki": [preload("res://scripts/combat/style_uzumaki_anim.gd"), 1.0],
	"style_yotsuki": [preload("res://scripts/combat/style_yotsuki_anim.gd"), 1.15],
	"style_kamizuru": [preload("res://scripts/combat/style_kamizuru_anim.gd"), 1.0],
	"style_iburi": [preload("res://scripts/combat/style_iburi_anim.gd"), 1.05],
	"style_kurosuki": [preload("res://scripts/combat/style_kurosuki_anim.gd"), 1.05],
	"style_senju": [preload("res://scripts/combat/style_senju_anim.gd"), 1.0],
	"style_sarutobi": [preload("res://scripts/combat/style_sarutobi_anim.gd"), 1.05],
	"style_hatake": [preload("res://scripts/combat/style_hatake_anim.gd"), 1.1],
	"style_nara": [preload("res://scripts/combat/style_nara_anim.gd"), 1.0],
	# yol tarzları (LegendPaths: yolda olunca açılır)
	"style_kapi": [preload("res://scripts/combat/style_kapi_anim.gd"), 1.1],
	"style_kil": [preload("res://scripts/combat/style_kil_anim.gd"), 1.0],
	"style_akasuna": [preload("res://scripts/combat/style_akasuna_anim.gd"), 1.0],
	"style_kagit": [preload("res://scripts/combat/style_kagit_anim.gd"), 1.0],
	"style_sumi": [preload("res://scripts/combat/style_sumi_anim.gd"), 1.0],
	"style_yilan": [preload("res://scripts/combat/style_yilan_anim.gd"), 1.0],
	"style_gama": [preload("res://scripts/combat/style_gama_anim.gd"), 1.0],
	"style_chidori": [preload("res://scripts/combat/style_chidori_anim.gd"), 1.05],
	"style_hiraishin": [preload("res://scripts/combat/style_hiraishin_anim.gd"), 1.15],
	"style_tip": [preload("res://scripts/combat/style_tip_anim.gd"), 1.1],
	"style_kakuzu": [preload("res://scripts/combat/style_kakuzu_anim.gd"), 0.95],
	"style_jashin": [preload("res://scripts/combat/style_jashin_anim.gd"), 1.0],
	"style_hachibi": [preload("res://scripts/combat/style_hachibi_anim.gd"), 1.0],
	"style_silah": [preload("res://scripts/combat/style_silah_anim.gd"), 1.1],
	"style_jin_shukaku": [preload("res://scripts/combat/style_jin_shukaku_anim.gd"), 0.95],
	"style_jin_matatabi": [preload("res://scripts/combat/style_jin_matatabi_anim.gd"), 1.15],
	"style_jin_isobu": [preload("res://scripts/combat/style_jin_isobu_anim.gd"), 1.0],
	"style_jin_son_goku": [preload("res://scripts/combat/style_jin_son_goku_anim.gd"), 0.95],
	"style_jin_kokuo": [preload("res://scripts/combat/style_jin_kokuo_anim.gd"), 1.05],
	"style_jin_saiken": [preload("res://scripts/combat/style_jin_saiken_anim.gd"), 1.0],
	"style_jin_chomei": [preload("res://scripts/combat/style_jin_chomei_anim.gd"), 1.1],
	"style_jin_gyuki": [preload("res://scripts/combat/style_jin_gyuki_anim.gd"), 1.0],
	"style_jin_kurama": [preload("res://scripts/combat/style_jin_kurama_anim.gd"), 1.1],
}
## uzun menzil silahları: yapay zekâ uzakta durup atar (Enemy._chase)
const RANGED := ["fuma_shuriken", "kyodai_shuriken", "fuma_makimono", "senbon", "mateki"]   # mateki: genjutsu flütü, uzakta durup çalar
## silah ağırlığı (0 hafif .. 1 ağır): kol/silah yaylanması (PoseOverlay.key_mass) — ağır silah gecikip taşar
const MASS := {"temari_ogi": 0.65, "uc_tirpan": 1.0, "samehada": 0.9, "kabutowari": 0.9, "shibuki": 0.85, "gunbai": 0.8, "raijin": 0.35, "kunai": 0.1,
	"sai": 0.2, "chakra_bicak": 0.25, "ruzgar_bicak": 0.1, "hiraishin_kunai": 0.15, "homatsu_kiseru": 0.3, "kusanagi": 0.35, "kusarigama": 0.55, "fuma_shuriken": 0.4, "kyodai_shuriken": 1.0, "fuma_makimono": 0.15, "nuibari": 0.25, "savas_cekici": 1.0, "zincirli_kunai": 0.3, "tonfa": 0.3, "bashosen": 0.35, "kubikiribocho": 0.95, "yagura_sopa": 0.4, "yelpaze": 0.6, "kongo_asa": 0.45, "kama": 0.75, "pence": 0.15, "senbon": 0.05, "hiramekarei": 0.7, "bo": 0.35, "kiba": 0.25, "tanto": 0.1, "hakko_chakura_to": 0.08, "mateki": 0.06, "wakizashi": 0.25, "nodachi": 0.7, "musta": 0.15,
	"style_juken": 0.08, "style_akimichi": 0.65, "style_inuzuka": 0.12, "style_kaguya": 0.2,
	"style_uchiha": 0.1, "style_hozuki": 0.3, "style_aburame": 0.05, "style_jugo": 0.7,
	"style_yuki": 0.05, "style_sabaku": 0.05, "style_uzumaki": 0.1, "style_yotsuki": 0.3, "style_kamizuru": 0.05, "style_iburi": 0.05, "style_kurosuki": 0.15, "style_senju": 0.45, "style_sarutobi": 0.12, "style_hatake": 0.1, "style_nara": 0.05, "style_kapi": 0.15, "style_kil": 0.05, "style_akasuna": 0.05, "style_kagit": 0.05, "style_sumi": 0.05, "style_yilan": 0.1, "style_gama": 0.2, "style_chidori": 0.1, "style_hiraishin": 0.05, "style_tip": 0.12, "style_kakuzu": 0.3, "style_jashin": 0.5, "style_hachibi": 0.35, "style_silah": 0.1, "style_jin_shukaku": 0.5, "style_jin_matatabi": 0.15, "style_jin_isobu": 0.3, "style_jin_son_goku": 0.45, "style_jin_kokuo": 0.3, "style_jin_saiken": 0.1, "style_jin_chomei": 0.1, "style_jin_gyuki": 0.4, "style_jin_kurama": 0.3}


static func mass(id: String) -> float:
	return float(MASS.get(id, 0.5))


## iki elli adımlarda sol elin sağ yumruktan sap boyunca uzaklığı
const TWO_OFF := {"kama": 0.55, "bo": 0.45, "kongo_asa": 0.5, "savas_cekici": 0.45, "uc_tirpan": 0.42, "shibuki": 0.2, "samehada": 0.3, "homatsu_kiseru": 0.3}   # shibuki: sağ el sapın arka ucunda, sol el önde (ruloya yakın)


static func has(id: String) -> bool:
	return TABLE.has(id)


static func steps(id: String) -> Array:
	return TABLE[id][0].steps()


static func speed(id: String) -> float:
	return float(TABLE[id][1])


static func two_off(id: String) -> float:
	return float(TWO_OFF.get(id, 0.32))


## Adım değiştiricileri — oyuncu ve düşman AYNI: heavy (yere serer), knock, launch, stun, pull (kanca çekişi), reach_add,
## lunge_mul (kurulurken kayma), special (silah özelliğini ez: "" = yok). Görsel/alan etkileri on_strike'ta.
static func mods(id: String, i: int) -> Dictionary:
	match id:
		"style_juken":
			var m = {"lunge_mul": 0.9, "tenketsu": true, "special": ""}
			match i:
				2: m.merge({"launch": 6.0, "knock": 2.0})
				4: m.merge({"knock": 1.0})
				5: m.merge({"knock": 18.0, "heavy": true, "reach_add": 0.6})
			return m
		"style_akimichi":
			var m = {"lunge_mul": 0.6, "special": ""}
			match i:
				0: m.merge({"reach_add": 0.5, "knock": 9.0})
				1: m.merge({"heavy": true, "knock": 5.0, "reach_add": 0.4})
				2: m.merge({"knock": 13.0})
				3: m.merge({"reach_add": 1.2, "knock": 17.0, "heavy": true})
				4: m.merge({"heavy": true, "knock": 6.0, "launch": 6.0, "reach_add": 0.6})
				5: m.merge({"reach_add": 2.6, "launch": 9.0, "knock": 15.0, "heavy": true})
			return m
		"style_inuzuka":
			var m = {"lunge_mul": 1.25, "special": ""}
			match i:
				2: m.merge({"lunge_mul": 2.3, "knock": 6.0})
				3: m.merge({"heavy": true, "knock": 4.0})
				5: m.merge({"lunge_mul": 3.0, "knock": 12.0, "launch": 5.0, "heavy": true})
			return m
		"style_uchiha":
			var m = {"lunge_mul": 1.0, "special": ""}
			match i:
				1: m.merge({"knock": 8.0})
				2: m.merge({"launch": 9.0, "knock": 1.0})
				3: m.merge({"knock": 3.0, "lunge_mul": 1.6})
				4: m.merge({"heavy": true, "knock": 6.0, "launch": 0.0, "slam": true})
				5: m.merge({"lunge_mul": 0.0, "knock": 4.0})
			return m
		"style_hozuki":   # orta menzil: atılmaz; su mermisi/kırbacı on_strike'ta (yakındaki yumruk değil)
			var m = {"lunge_mul": 0.15, "special": ""}
			if i == 3:
				m.merge({"lunge_mul": 0.9, "reach_add": 0.9, "knock": 14.0, "heavy": true})
			return m
		"style_aburame":   # uzak menzil: hiç atılmaz, el değmez; tüm hasar böcek sürüsünden (on_strike)
			return {"lunge_mul": 0.0, "special": "", "knock": 1.0}
		"style_kamizuru":   # orta-uzak: atılmaz; tüm hasar arılardan (on_strike)
			return {"lunge_mul": 0.0, "special": "", "knock": 1.0}
		"style_yilan", "style_gama":   # yakın-orta: tüm vuruşlar yılan / kurbağa sanatından (on_strike)
			return {"lunge_mul": 0.25, "special": "", "knock": 1.0, "reach_add": -9.0}
		"style_chidori":   # yakın Chidori darbeleri + orta senbon/mızrak/iğne; bitiriş koşu kendi içinde
			var m = {"lunge_mul": 0.6, "special": "", "knock": 4.0, "reach_add": 0.4}
			if i in [1, 2, 3, 4, 5]:
				m.merge({"lunge_mul": 0.0, "reach_add": -9.0})
			return m
		"style_tip":   # yakın: neşter/avuç/yumruk; zehir sisi orta
			var m = {"lunge_mul": 0.7, "special": "", "knock": 2.0, "reach_add": 0.3}
			if i == 3:
				m.merge({"lunge_mul": 0.0, "reach_add": -9.0})
			if i == 5:
				m.merge({"lunge_mul": 0.5, "reach_add": -9.0})
			return m
		"style_kakuzu":   # iplikler/maskeler orta; Domu yumruğu yakın
			var m = {"lunge_mul": 0.0, "special": "", "knock": 1.0, "reach_add": -9.0}
			if i == 2:
				m = {"lunge_mul": 0.9, "special": "", "knock": 10.0, "reach_add": 0.5, "heavy": true}
			return m
		"style_jin_shukaku":   # kum pençe yakın (atılır), rüzgâr/kum orta
			var m = {"lunge_mul": 0.0, "special": "", "knock": 1.0, "reach_add": -9.0}
			if i == 0:
				m = {"lunge_mul": 0.7, "special": "", "knock": 1.0, "reach_add": -9.0}
			return m
		"style_jin_matatabi":   # kedi: yakın, atılgan (tırnak vuruşları on_strike, el değmesi yok — pençe izleri vurur)
			var m = {"lunge_mul": 0.9, "special": "", "knock": 1.0, "reach_add": -9.0}
			if i in [2, 3]:
				m["lunge_mul"] = 0.0
			return m
		"style_jin_kurama":   # pençeler yakın (atılır), kollar/kükreme/top orta
			var m = {"lunge_mul": 0.9, "special": "", "knock": 1.0, "reach_add": -9.0}
			if i >= 2:
				m["lunge_mul"] = 0.0
			return m
		"style_jin_isobu", "style_jin_saiken", "style_jin_chomei", "style_jin_gyuki":
			return {"lunge_mul": 0.0, "special": "", "knock": 1.0, "reach_add": -9.0}
		"style_jin_son_goku":   # lav yumrukları yakın (atılır); lav kayası/fışkırma orta
			var m = {"lunge_mul": 0.8, "special": "", "knock": 1.0, "reach_add": -9.0}
			if i in [2, 3, 4]:
				m["lunge_mul"] = 0.0
			return m
		"style_jin_kokuo":   # tekmeci: yakın, atılgan; hücum ve roket tekme kendi hareketiyle
			var m = {"lunge_mul": 0.9, "special": "", "knock": 1.0, "reach_add": -9.0}
			if i in [2, 3, 4, 5]:
				m["lunge_mul"] = 0.0
			return m
		"style_jashin", "style_hachibi", "style_silah":   # tüm vuruşlar kendi sanatından (on_strike): yürüyerek atılmaz
			return {"lunge_mul": 0.0, "special": "", "knock": 1.0, "reach_add": -9.0}
		"style_hiraishin":   # ışınlanır, yürüyerek yanaşmaz: tüm vuruşlar kunai/flaş sanatından (on_strike)
			return {"lunge_mul": 0.0, "special": "", "knock": 1.0, "reach_add": -9.0}
		"style_kagit", "style_sumi":   # orta-uzak: el değmez, tüm hasar kâğıt / mürekkepten (on_strike)
			return {"lunge_mul": 0.0, "special": "", "knock": 1.0, "reach_add": -9.0}
		"style_akasuna":   # orta: kuklacı yanaşmaz; tüm hasar kuklalardan (on_strike)
			return {"lunge_mul": 0.0, "special": "", "knock": 1.0, "reach_add": -9.0}
		"style_kil":   # orta-uzak: el değmez, tüm hasar kil figürlerden (on_strike)
			return {"lunge_mul": 0.0, "special": "", "knock": 1.0, "reach_add": -9.0}
		"style_kapi":   # yakın Gōken; 5-6 kapı teknikleri uzaktan da (alev yumrukları, kaplan)
			var m = {"lunge_mul": 0.8, "special": "", "knock": 5.0, "reach_add": 0.5}
			match i:
				0: m.merge({"knock": 8.0})
				1: m.merge({"knock": 2.0, "stun": 0.5})
				2: m.merge({"knock": 1.0, "launch": 9.0, "heavy": true})
				3, 4, 5: m.merge({"lunge_mul": 0.0, "reach_add": -9.0})
			return m
		"style_nara":   # orta menzil: el değmez, tüm etki gölgeden (on_strike)
			return {"lunge_mul": 0.0, "special": "", "knock": 1.0, "reach_add": -9.0}
		"style_hatake":   # yakın tekmeler + raiton
			var m = {"lunge_mul": 0.7, "special": "", "knock": 5.0, "reach_add": 0.4}
			match i:
				0: m.merge({"knock": 2.0, "stun": 0.5})   # süpürme: ayağını alır
				1: m.merge({"knock": 9.0, "heavy": true})
				2, 3, 4, 5: m.merge({"lunge_mul": 0.0, "reach_add": -9.0})
			return m
		"style_sarutobi":   # yakın Hien yumrukları + orta kül/ateş/shuriken
			var m = {"lunge_mul": 0.6, "special": "", "knock": 4.0, "reach_add": 0.5}
			if i >= 2:
				m.merge({"lunge_mul": 0.0, "reach_add": -9.0})
			return m
		"style_senju":   # yakın yumruk + orta menzil ahşap; Senju kanının ağır vuruşu
			var m = {"lunge_mul": 0.6, "special": "", "knock": 6.0, "snd": "earth"}   # kullanıcı: düz vuruşta tınlayan yumruk değil, Mokuton toprak sesi
			match i:
				0, 1: m.merge({"knock": 7.0})
				2, 3: m.merge({"lunge_mul": 0.0, "reach_add": -9.0})   # dallar / sütunlar on_strike
				4: m.merge({"lunge_mul": 0.3, "reach_add": -9.0})      # Ōkashō zemin dalgası on_strike
				5: m.merge({"lunge_mul": 0.0, "reach_add": -9.0})      # topuk krateri on_strike
			return m
		"style_kurosuki":   # yakın el kılıcı + gök şimşeği (5-6 uzaktan)
			var m = {"lunge_mul": 0.5, "special": "", "knock": 4.0}
			match i:
				2: m.merge({"lunge_mul": 0.0, "reach_add": -9.0})   # Kirigakure darbesi on_strike'ta (ışınlanma sonrası)
				3: m.merge({"lunge_mul": 0.0, "reach_add": -9.0})   # çapraz şimşek çizgileri on_strike
				4, 5: m.merge({"lunge_mul": 0.0, "reach_add": -9.0})   # gök şimşeği
			return m
		"style_iburi":   # orta: duman kol uzanır; tüm vuruşlar on_strike'ta (duman kol, Utsuri ters eli, Iaigiri)
			return {"lunge_mul": 0.0, "special": "", "knock": 1.0, "reach_add": -9.0}
		"style_jugo":
			var m = {"lunge_mul": 0.7, "special": "", "reach_add": 0.4}
			match i:
				0, 1: m.merge({"knock": 10.0, "heavy": true})
				2: m.merge({"lunge_mul": 2.6, "knock": 14.0, "heavy": true})
				3: m.merge({"heavy": true, "knock": 6.0, "launch": 6.0})
				4: m.merge({"reach_add": 1.5, "knock": 8.0})
				5: m.merge({"launch": 12.0, "knock": 4.0, "heavy": true})
			return m
		"style_yuki":   # orta menzil: iğneler on_strike'ta; yakın avuç donduruyor
			var m = {"lunge_mul": 0.25, "special": ""}
			if i == 2:
				m.merge({"lunge_mul": 1.1, "freeze": true, "knock": 3.0})
			return m
		"style_sabaku":   # uzak: kıpırdamaz, el değmez, kum vurur
			return {"lunge_mul": 0.0, "special": "", "knock": 1.0}
		"style_uzumaki":
			var m = {"lunge_mul": 0.2, "special": ""}
			if i == 5:
				m.merge({"heavy": true})
			return m
		"style_yotsuki":
			var m = {"lunge_mul": 1.4, "special": "", "element": "raiton"}
			match i:
				0: m.merge({"knock": 6.0, "stun": 0.2})
				1: m.merge({"lunge_mul": 2.6, "knock": 16.0, "heavy": true})
				2: m.merge({"lunge_mul": 2.4, "knock": 18.0, "launch": 4.0, "heavy": true, "reach_add": 0.8})
				3: m.merge({"stun": 0.5, "knock": 8.0})
				4: m.merge({"knock": 2.0})
				5: m.merge({"lunge_mul": 1.2, "heavy": true, "liger": true, "knock": 4.0})
			return m
		"style_kaguya":
			var m = {"special": "", "reach_add": 0.5}   # kemik kılıç: yumruktan uzun
			match i:
				2: m.merge({"reach_add": 1.3, "knock": 6.0})
				3: m.merge({"knock": 4.0})
				4: m.merge({"lunge_mul": 0.0})
				5: m.merge({"heavy": true, "knock": 14.0, "launch": 6.0, "lunge_mul": 0.0})
			return m
		"uc_tirpan":
			var m = {"lunge_mul": 0.5}
			match i:
				1: m.merge({"heavy": true, "knock": 3.0})
				2: m.merge({"pull": true, "knock": 0.5})
				3: m.merge({"stun": 0.6, "knock": 2.0})
				4: m.merge({"launch": 12.0, "knock": 2.0})
				5: m.merge({"reach_add": 0.6, "knock": 18.0, "heavy": true})
			return m
		"samehada":
			# rendeler + chakra emer (silahın "drain" özelliği kalır); ağır: kurulurken kaymaz
			var m = {"lunge_mul": 0.55, "eat": true, "special": ""}   # emme _samehada_eat'te (genel "drain" iki kez emmesin)   # her isabet: chakra yer, jutsuyu yutar, buff/pelerin söker, doyup büyür
			match i:
				0: m.merge({"knock": 2.0})
				1: m.merge({"heavy": true, "knock": 14.0})
				2: m.merge({"knock": 6.0, "reach_add": 1.4})                    # canlı atılış: menzil uzar
				3: m.merge({"launch": 11.0, "knock": 2.0})
				4: m.merge({"heavy": true, "launch": 9.0, "knock": 7.0, "reach_add": 0.4, "lunge_mul": 0.0})   # havadan yere çakar
				5: m.merge({"heavy": true, "knock": 16.0, "launch": 8.5})   # öne yere çarpılıp savrulur (yakın dövüşte launch >= 8 olmazsa yere sermez, sadece iter)
			return m
		"kusarigama":
			# orta menzil: kanca çekişi, ağırlık/orak fırlatışları on_strike'ta (yakın vuruş yalnız sap/orak teması)
			var m = {"lunge_mul": 0.35}
			match i:
				0: m.merge({"reach_add": 1.3, "kg_drag": true, "knock": 0.5})
				1: m.merge({"lunge_mul": 0.0, "knock": 2.0})
				2: m.merge({"lunge_mul": 0.0, "knock": 3.0})
				3: m.merge({"lunge_mul": 0.0, "knock": 1.0})
				4: m.merge({"launch": 7.5, "knock": 0.5, "stun": 0.6, "reach_add": 0.7, "lunge_mul": 0.7})
				5: m.merge({"heavy": true, "knock": 15.0, "reach_add": 1.6, "lunge_mul": 1.0})
			return m
		"nuibari":
			# iğneleme: uzun saplama menzili, hat boyu delme, tel fırlatışı ve dikiş (on_strike)
			var m = {"lunge_mul": 0.7, "knock": 2.0}
			match i:
				0: m.merge({"reach_add": 1.4, "knock": 3.0})
				1: m.merge({"reach_add": 1.0, "knock": 2.0})
				2: m.merge({"lunge_mul": 0.0})
				3: m.merge({"launch": 9.5, "knock": 1.0, "reach_add": 0.8})
				4: m.merge({"lunge_mul": 0.0})
				5: m.merge({"lunge_mul": 0.0, "stun": 1.2})
			return m
		"savas_cekici":
			var m = {"lunge_mul": 0.5}
			match i:
				0: m.merge({"knock": 12.0, "reach_add": 0.8})
				1: m.merge({"heavy": true, "knock": 5.0, "reach_add": 0.6})
				2: m.merge({"knock": 8.0, "reach_add": 0.9})
				3: m.merge({"launch": 11.0, "knock": 2.0})
				4: m.merge({"knock": 5.0})
				5: m.merge({"heavy": true, "knock": 15.0, "reach_add": 1.2, "lunge_mul": 0.9})
			return m
		"kama":
			var m = {"lunge_mul": 0.5, "reach_add": 1.2, "knock": 6.0}
			match i:
				0: m.merge({"knock": 10.0, "bleed": 3.0})
				1: m.merge({"pull": true, "knock": 0.5})
				2: m.merge({"knock": 10.0, "bleed": 3.0})
				3: m.merge({"launch": 10.0, "knock": 1.0})
				4: m.merge({"knock": 8.0})
				5: m.merge({"heavy": true, "knock": 15.0, "lunge_mul": 0.9, "reach_add": 1.5})
			return m
		"mateki":   # yakın iki vuruş, sonra ezgiler: atılmaz (genjutsu ustası mesafede kalır)
			var m = {"lunge_mul": 0.8 if i < 2 else 0.0, "knock": 2.0}
			if i >= 2:
				m.merge({"special": ""})
			return m
		"hakko_chakura_to":
			var m = {"lunge_mul": 1.0, "knock": 1.5}
			match i:
				2: m.merge({"lunge_mul": 0.0, "knock": 4.0, "bleed": 2.0})   # Shiroi Kiba: atılış on_start'ta (rakibin içinden geçer)
				3: m.merge({"knock": 1.0, "launch": -6.0, "stun": 0.4})      # dikey kesik yere indirir
				4: m.merge({"knock": 7.0, "lunge_mul": 0.4})
				5: m.merge({"lunge_mul": 0.6, "knock": 10.0, "heavy": true, "pierce_guard": true})
			return m
		"tanto":
			var m = {"lunge_mul": 0.8, "knock": 1.0}
			match i:
				1: m.merge({"bleed": 4.0})
				3: m.merge({"stun": 0.5, "knock": 0.5})
				5: m.merge({"lunge_mul": 3.2, "knock": 9.0, "pierce_guard": true, "heavy": true, "reach_add": 0.6})
			return m
		"wakizashi":
			var m = {"lunge_mul": 0.8, "knock": 2.0}
			match i:
				2: m.merge({"launch": 6.0, "knock": 1.0})
				4: m.merge({"stun": 0.6, "knock": 4.0})
				5: m.merge({"lunge_mul": 0.5, "knock": 2.0})
			return m
		"nodachi":
			var m = {"lunge_mul": 0.7, "knock": 5.0, "reach_add": 0.6}
			match i:
				1: m.merge({"reach_add": 1.2, "knock": 7.0})
				2: m.merge({"reach_add": 1.6, "lunge_mul": 1.4, "knock": 8.0})
				3: m.merge({"launch": 3.5, "stun": 0.6, "reach_add": 1.0})
				4: m.merge({"launch": 9.0, "knock": 1.0})
				5: m.merge({"heavy": true, "knock": 12.0, "reach_add": 1.4})
			return m
		"musta":
			var m = {"lunge_mul": 0.9, "knock": 2.0, "bleed": 1.5}
			match i:
				2: m.merge({"launch": 9.0, "knock": 1.0})
				4: m.merge({"knock": 0.6, "lunge_mul": 0.3})
				5: m.merge({"heavy": true, "knock": 16.0, "bleed": 5.0})
			return m
		"kiba":
			# her vuruş Raiton: kısa uyuşma
			var m = {"lunge_mul": 0.9, "knock": 2.0, "stun": 0.25}
			match i:
				2: m.merge({"pull": true, "knock": 0.5, "stun": 0.5})
				4: m.merge({"knock": 4.0, "reach_add": 0.6})
				5: m.merge({"lunge_mul": 0.0, "knock": 1.0})
			return m
		"pence":
			var m = {"lunge_mul": 0.9, "knock": 3.0, "bleed": 2.0}
			match i:
				2: m.merge({"knock": 6.0})
				3: m.merge({"launch": 9.0, "knock": 1.0})
				4: m.merge({"heavy": true, "knock": 5.0})
				5: m.merge({"knock": 14.0, "lunge_mul": 1.6, "bleed": 5.0})
			return m
		"senbon":
			return {"lunge_mul": 0.0, "knock": 0.5, "reach_add": -9.0}   # yakın vuruş yok: iğneler vurur
		"hiramekarei":
			var m = {"lunge_mul": 0.6, "knock": 6.0, "reach_add": 0.6}
			match i:
				0: m.merge({"heavy": true, "knock": 6.0})
				1: m.merge({"knock": 8.0})
				2: m.merge({"knock": 4.0, "stun": 0.4})
				3: m.merge({"knock": 9.0})
				5: m.merge({"heavy": true, "knock": 16.0, "lunge_mul": 0.9, "reach_add": 1.2})
			return m
		"bo":
			var m = {"lunge_mul": 0.6, "knock": 5.0, "reach_add": 0.6}
			match i:
				2: m.merge({"knock": 9.0, "reach_add": 1.0})
				3: m.merge({"heavy": true, "knock": 3.0})
				5: m.merge({"heavy": true, "knock": 12.0})
			return m
		"temari_ogi":
			var m = {"lunge_mul": 0.4, "knock": 5.0, "reach_add": 0.5}
			match i:
				0: m.merge({"heavy": true, "knock": 4.0})
				2: m.merge({"knock": 14.0, "lunge_mul": 0.2})
				3: m.merge({"knock": 2.0, "launch": 7.0})
				4: m.merge({"heavy": true, "knock": 6.0})
				5: m.merge({"knock": 16.0, "lunge_mul": 0.0})
			return m
		"yelpaze":
			var m = {"lunge_mul": 0.4, "knock": 5.0}
			match i:
				0: m.merge({"heavy": true, "knock": 3.0})
				2: m.merge({"knock": 12.0, "lunge_mul": 0.6})
				4: m.merge({"heavy": true, "knock": 6.0})
				5: m.merge({"knock": 14.0, "lunge_mul": 0.0})
			return m
		"kongo_asa":
			var m = {"lunge_mul": 0.5, "knock": 4.0}
			match i:
				0: m.merge({"reach_add": 2.4, "knock": 9.0})
				1: m.merge({"heavy": true, "knock": 4.0, "reach_add": 1.2})
				2: m.merge({"lunge_mul": 0.0, "knock": 0.0, "reach_add": -9.0})   # yakın vuruş yok: Maymun Kral vurur
				3: m.merge({"knock": 9.0, "reach_add": 2.0})
				4: m.merge({"knock": 12.0, "lunge_mul": 0.4})
				5: m.merge({"knock": 14.0, "reach_add": 3.5, "lunge_mul": 0.0})
			return m
		"yagura_sopa":
			# ağır kılıç gibi: geniş savuruşlar, uzun menzil (2.4 m sopa)
			var m = {"lunge_mul": 0.5, "knock": 6.0, "reach_add": 1.0}
			match i:
				0: m.merge({"heavy": true, "knock": 5.0})
				1: m.merge({"knock": 10.0})
				2: m.merge({"knock": 6.0})
				3: m.merge({"launch": 10.0, "knock": 1.0})
				4: m.merge({"pull": true, "knock": 12.0})
				5: m.merge({"heavy": true, "knock": 14.0, "lunge_mul": 0.8, "reach_add": 1.4})
			return m
		"kubikiribocho":
			var m = {"lunge_mul": 0.6}
			match i:
				0: m.merge({"heavy": true, "knock": 6.0, "reach_add": 0.8})
				1: m.merge({"knock": 12.0, "reach_add": 1.1, "bleed": 4.0})
				2: m.merge({"launch": 11.0, "knock": 2.0, "reach_add": 0.6})
				3: m.merge({"knock": 9.0, "reach_add": 1.0})
				4: m.merge({"knock": 14.0, "lunge_mul": 0.4})
				5: m.merge({"heavy": true, "knock": 16.0, "reach_add": 1.4, "lunge_mul": 0.9})
			return m
		"bashosen":
			# yelpaze: asıl etki rüzgâr dalgası (on_strike); yakın vuruş itici
			var m = {"lunge_mul": 0.3, "knock": 6.0}
			match i:
				2: m.merge({"heavy": true, "knock": 3.0})
				3: m.merge({"launch": 10.0, "knock": 1.0})
				4: m.merge({"knock": 9.0, "reach_add": 0.6})
				5: m.merge({"knock": 14.0, "lunge_mul": 0.0})
			return m
		"tonfa":
			# çift el sopa: ezici, sersemletici; bitiriş yere serer
			var m = {"lunge_mul": 0.8}
			match i:
				0: m.merge({"knock": 4.0})
				1: m.merge({"knock": 3.0})
				2: m.merge({"stun": 0.5, "knock": 5.0})
				3: m.merge({"knock": 9.0, "reach_add": 0.4})
				4: m.merge({"launch": 9.0, "knock": 1.5})
				5: m.merge({"heavy": true, "knock": 12.0, "stun": 0.6})
			return m
		"zincirli_kunai":
			var m = {"lunge_mul": 0.5}
			match i:
				1, 2, 4: m.merge({"lunge_mul": 0.0, "knock": 1.0})
				5: m.merge({"heavy": true, "knock": 10.0, "lunge_mul": 0.3})
			return m
		"fuma_shuriken", "kyodai_shuriken", "fuma_makimono":
			# uzun menzil: hasar uçan shurikende (on_strike); kurulurken öne kaymaz, yakın vuruş yalnız elde tutulan adımlarda
			var m = {"lunge_mul": 0.0, "knock": 1.0}
			if id == "fuma_shuriken" and i == 3:
				m.merge({"knock": 3.0, "reach_add": 0.8})
			if id == "kyodai_shuriken" and i == 3:
				m.merge({"heavy": true, "knock": 14.0, "reach_add": 0.6, "lunge_mul": 0.8})
			return m
		"kusanagi":
			# Sasuke tarzı hızlı kılıç: uçma/uzama YOK (Orochimaru tekniği değil). Shunshin saplama, Chidori Nagashi, iai geçişi.
			var m = {"lunge_mul": 0.9}
			match i:
				2: m.merge({"lunge_mul": 2.6, "knock": 6.0, "stun": 0.4})
				3: m.merge({"launch": 9.0, "knock": 2.0})
				4: m.merge({"lunge_mul": 0.0, "knock": 0.5})
				5: m.merge({"lunge_mul": 0.0, "knock": 0.0})
			return m
		"homatsu_kiseru":
			# kabarcıklar asıl hasarı verir (on_strike); yakın vuruş yalnız boru darbesi
			var m = {"lunge_mul": 0.0}
			match i:
				2: m.merge({"lunge_mul": 0.8, "knock": 6.0, "heavy": true})
			return m
		"hiraishin_kunai":
			# her isabet işaret koyar (on_target); 3 ve 5. adım ışınlanır (on_start); bitiriş flaşlı çoklu kesik (on_strike)
			var m = {"lunge_mul": 1.0, "mark": true}
			match i:
				2: m.merge({"knock": 5.0, "lunge_mul": 0.0})
				3: m.merge({"launch": 9.0, "knock": 2.0})
				4: m.merge({"lunge_mul": 0.0})
				5: m.merge({"heavy": true, "knock": 14.0, "lunge_mul": 0.0})
			return m
		"sai":
			# saplama silahı: kilitleme, yükselen saplama, çift delik
			var m = {"lunge_mul": 1.0}
			match i:
				3: m.merge({"stun": 0.8, "knock": 1.0})                   # yakala ve sapla
				4: m.merge({"launch": 9.0, "knock": 2.0})                 # yükselen saplama: havaya
				5: m.merge({"heavy": true, "knock": 12.0, "reach_add": 0.4})   # çift delik
			return m
		"chakra_bicak":
			# Asuma muştaları: hızlı; bitiriş Hien (chakra akışı: menzil uzar, sert)
			var m = {"lunge_mul": 1.0}
			match i:
				2: m.merge({"launch": 9.0, "knock": 2.0})
				4: m.merge({"knock": 8.0})
				5: m.merge({"heavy": true, "knock": 14.0, "reach_add": 1.6})
			return m
		"ruzgar_bicak":
			# her vuruş fuuton: rüzgar kesiği on_strike'ta ileri uçar
			var m = {"lunge_mul": 0.8, "element": "fuuton"}
			match i:
				2: m.merge({"launch": 9.0, "knock": 2.0})
				3: m.merge({"knock": 9.0, "reach_add": 0.6})
				5: m.merge({"heavy": true, "knock": 16.0})
			return m
		"kabutowari":
			# zırh kırıcı (silahın armor_break özelliği her vuruşta); ağır: kurulurken kaymaz
			var m = {"lunge_mul": 0.5}
			match i:
				0: m.merge({"heavy": true, "knock": 3.0})
				1: m.merge({"heavy": true, "knock": 12.0})
				2: m.merge({"pull": true, "knock": 1.0})
				3: m.merge({"heavy": true, "stun": 0.9, "knock": 6.0, "shatter": true})
				4: m.merge({"heavy": true, "knock": 3.0})
				5: m.merge({"heavy": true, "launch": 10.0, "knock": 5.0, "shatter": true, "reach_add": 0.4})
			return m
		"shibuki":
			# patlamalar on_strike'ta (her vuruşta kendi biçimi): silahın genel "explode" özelliği iki kez patlamasın
			var m = {"lunge_mul": 0.6, "special": ""}
			match i:
				0: m.merge({"knock": 6.0})
				1: m.merge({"heavy": true, "stun": 0.4, "knock": 3.0})
				2: m.merge({"knock": 2.0})
				3: m.merge({"heavy": true, "knock": 12.0})
				4: m.merge({"knock": 14.0, "reach_add": 0.3})
				5: m.merge({"heavy": true, "launch": 6.0, "knock": 4.0})
			return m
	return {}


## İsabet eden hedefe adım etkisi (kanca çekişi)
static func on_target(id: String, i: int, who: Node3D, h: Node3D) -> void:
	var m = mods(id, i)
	if bool(m.get("pull", false)) and h is CharacterBody3D:
		h.velocity = (who.global_position - h.global_position).normalized() * 9.0 + Vector3.UP * 2.0
	if bool(m.get("mark", false)) and h.has_method("apply_status"):
		h.apply_status("marked", 12.0)   # Hiraishin işareti (shiki): işaretli hedef fazla hasar alır, ışınlanma ona gider
		h.set_meta("hiraishin_by", who.get_instance_id())
	if bool(m.get("kg_drag", false)):
		_kg_drag(who, h)   # kusarigama kancası: mesafeye göre çeker, önünde durur (içinden geçmez)
	if bool(m.get("eat", false)):
		_samehada_eat(who, h, i == 5)
	if bool(m.get("tenketsu", false)):
		_tenketsu(who, h, i)
	if bool(m.get("slam", false)) and h is CharacterBody3D:   # Shishi Otoshi: havadaki rakip topukla yere çakılır
		h.velocity = Vector3(0, -16.0, 0)
	if bool(m.get("freeze", false)) and h.has_method("apply_status"):   # Hyōshō: buz avucu dondurur
		h.apply_status("slow", 2.0)
		FX.hit_spark(h.global_position + Vector3.UP, Color(0.8, 0.95, 1.0), 1.0)
	if bool(m.get("liger", false)) and h is CharacterBody3D:   # Liger Bomb: kaldırılıp yere çakılır
		h.velocity = Vector3(0, -18.0, 0)
	if bool(m.get("shatter", false)):
		_shatter(who, h)
	if bool(m.get("throw_back", false)) and h is CharacterBody3D:
		# Samehada bitiriş: saplı rakip başın üstünden arkaya savrulup yere çarpar
		var f: Vector3 = who.face_dir() if who.has_method("face_dir") else -who.global_transform.basis.z
		f.y = 0
		h.velocity = -f.normalized() * 9.0 + Vector3.UP * 11.0


## Vuruş anı etkileri (isabet olsun olmasın): zemin, patlama, uçan kâğıt; alan hasarı who adına (oyuncu ve düşman aynı)
static func on_strike(id: String, i: int, who: Node3D, dmg: float) -> void:
	if who == null or not is_instance_valid(who):
		return
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else -who.global_transform.basis.z
	f.y = 0
	f = f.normalized()
	var side = Vector3.UP.cross(f).normalized()
	var gp = func(d: float, s := 0.0) -> Vector3:
		var q = who.global_position + f * d + side * s
		q.y = Game.ground_height(q.x, q.z) + 0.05
		return q
	if id.begins_with("style_"):
		var tf = _near_foe(who, 16.0)   # tarz vuruşları hedefe yönelir (uzak/orta menzilde baktığın yön değil rakip)
		if tf:
			var dd = tf.global_position - who.global_position
			dd.y = 0
			if dd.length() > 0.3:
				f = dd.normalized()
				side = Vector3.UP.cross(f).normalized()
		_style_strike(id, i, who, dmg, f, side)
		return
	match id:
		"fuma_shuriken":
			var o = {"mesh": "fuma_shuriken", "radius": 0.6, "spin": 3.2, "wind": true}
			match i:
				0: _spin_throw(who, dmg, "straight", o)
				1: _spin_throw(who, dmg, "arc", o)
				2: _spin_throw(who, dmg * 1.1, "down", o)
				4:   # Kage Fūsha: ikinci shuriken ilkinin gölgesinde (hemen ardından, biraz alçak)
					_spin_throw(who, dmg, "straight", o)
					_spin_throw(who, dmg, "straight", o.merged({"hold": false, "hide_held": false, "delay": 0.12, "return": false}))
				5: _spin_throw(who, dmg * 0.6, "circle", o.merged({"turns": 4.0, "orbit": 1.4, "dur": 2.2}))
		"kyodai_shuriken":
			var o = {"mesh": "kyodai_shuriken", "radius": 1.25, "spin": 1.4, "knock": 9.0, "dur_k": 1.0}
			match i:
				0: _spin_throw(who, dmg * 1.2, "straight", o)
				1: _spin_throw(who, dmg, "arc", o)
				2: _spin_throw(who, dmg, "roll", o.merged({"spin": 1.8}))
				4: _spin_throw(who, dmg, "boomerang", o.merged({"side": -1.0}))
				5:   # Tenkū Nage: göğe fırlatılır, rakibin üstüne çakılır (oyuncu yerde)
					_spin_throw(who, dmg * 1.4, "down", o.merged({"return": true, "dur": 1.6}))
					who.get_tree().create_timer(0.75).timeout.connect(func():
						if is_instance_valid(who):
							var tg = _throw_target(who)
							var q = (tg.global_position if tg != null else who.global_position + f * 8.0)
							q.y = Game.ground_height(q.x, q.z) + 0.05
							VFX.cracks(q, 3.2)
							VFX.debris(q, Color(0.5, 0.45, 0.4), 12, 6.0, 0.35)
							Combat.hit_sphere(who, q + Vector3.UP * 0.6, 3.2, {"dmg": dmg * 0.5, "knock": 10.0, "launch": 6.0, "kind": "heavy", "hitstop": 0.06, "melee": false})
							_shake(who, 0.7))
		"fuma_makimono":
			_summon_three(who, dmg, ["fan", "orbit", "rain", "line", "pincer", "cage"][clampi(i, 0, 5)])
		"nuibari":
			var o = {"mesh": "nuibari", "radius": 0.45, "orient": "path", "wire": true, "range": 20.0}
			match i:
				1:   # Nui Tsuki: iğne öndekinden arkasındakine geçer (hat boyu delme)
					for k in 5:
						Combat.hit_sphere(who, who.global_position + Vector3.UP * 1.1 + f * (1.4 + k * 0.9), 0.6, {"dmg": dmg * 0.5, "knock": 1.5, "kind": "light", "hitstop": 0.02, "melee": true, "bleed": 2.0})
					WindFX.streak(func(t: float) -> Vector3: return who.global_position + Vector3.UP * 1.1 + f * (0.6 + t * 5.0), 0.16, 0.03, Color(0.9, 0.93, 1.0, 0.9), 0.0, 10)
				2: _spin_throw(who, dmg, "straight", o.merged({"stitch": true}))
				4: _spin_throw(who, dmg * 0.6, "orbit_self", o.merged({"dur": 1.0, "orbit": 3.4, "turns": 2.0}))
				5: _spin_throw(who, dmg * 1.3, "straight", o.merged({"stitch": true, "bind": 2.0, "dur": 1.3}))
		"savas_cekici":
			match i:
				0:   # yatay savuruş: rüzgâr izi yay
					for k in 3:
						WindFX.streak(func(t: float) -> Vector3:
							var a = lerpf(-1.3, 1.3, t)
							return who.global_position + Vector3.UP * (1.0 + k * 0.15) + (f * cos(a) - side * sin(a)) * 2.3, 0.22, 0.07, Color(0.85, 0.9, 1.0, 0.7), k * 0.03, 14)
				1, 5:   # yere çakma: yarık, taşlar, sarsıntı (bitirişte şok dalgası)
					var big = i == 5
					var q = gp.call(2.2 if big else 2.0)
					VFX.cracks(q, 3.4 if big else 2.2)
					VFX.debris(q, Color(0.5, 0.45, 0.4), 14 if big else 8, 6.5 if big else 5.0, 0.35)
					_shake(who, 0.8 if big else 0.5)
					if big:
						Combat.hit_sphere(who, q + Vector3.UP * 0.5, 3.6, {"dmg": dmg * 0.6, "knock": 12.0, "launch": 7.0, "kind": "heavy", "hitstop": 0.07, "melee": false})
						Dangle.blast(q, 45.0, 8.0)
		"kama":
			# kızıl biçme izi (hilal bıçağın yolu)
			var red = Color(0.9, 0.12, 0.18, 0.9)
			if i in [0, 2, 4]:
				var sg = -1.0 if i == 2 else 1.0
				for k in (1 if i != 4 else 2):
					WindFX.streak(func(t: float) -> Vector3:
						var a = lerpf(-1.4, 1.4, t) * sg + k * PI
						return who.global_position + Vector3.UP * (1.0 + k * 0.2) + (f * cos(a) - side * sin(a)) * 2.6, 0.24, 0.12, red, k * 0.1, 16)
			if i == 3:
				WindFX.streak(func(t: float) -> Vector3: return who.global_position + f * 1.8 + Vector3.UP * (0.2 + t * 2.6) - f * t * 0.6, 0.22, 0.12, red, 0.0, 12)
			if i == 5:   # Kama Nage: orak dönerek fırlatılır, rakibin çevresinde biçer, ele döner
				_spin_throw(who, dmg * 0.6, "circle", {"mesh": "kama", "radius": 1.0, "spin": 2.6, "turns": 3.0, "orbit": 1.6, "dur": 1.0, "knock": 8.0})
		"kiba":
			_kiba_strike(who, i, dmg, f, side)
		"mateki":
			_mateki_strike(who, i, dmg, f, side)
		"hakko_chakura_to":
			_hakko_strike(who, i, dmg, f, side)
		"tanto":
			if i == 2:   # Ashi Kiri: baldır kesilir, yavaşlar
				for h in Combat.hit_sphere(who, gp.call(1.0) + Vector3.UP * 0.3, 1.4, {"dmg": dmg * 0.2, "knock": 0.0, "kind": "light", "melee": false}):
					if is_instance_valid(h) and h.has_method("apply_status"):
						h.apply_status("slow", 2.0)
			elif i == 5:   # Shunshin Tsuki: göz açıp kapayana kadar uzun saplama (beyaz chakra izi yalnız Hakkō Chakura Tō'da)
				var o = who.global_position + Vector3.UP * 1.15
				WindFX.streak(func(t: float) -> Vector3: return o - f * 1.5 + f * t * 5.5, 0.25, 0.05, Color(0.7, 0.74, 0.8, 0.7), 0.0, 10)
				VFX.slowmo(0.3, 0.2)
		"wakizashi":
			if i == 5:   # Jūmonji: havada kalan artı izi gecikmeyle patlar
				var c = who.global_position + Vector3.UP * 1.2 + f * 1.4
				var wc = Color(0.95, 0.97, 1.0, 0.9)
				WindFX.streak(func(t: float) -> Vector3: return c + Vector3.UP * lerpf(0.9, -0.9, t), 0.5, 0.06, wc, 0.0, 10)
				WindFX.streak(func(t: float) -> Vector3: return c + side * lerpf(0.9, -0.9, t), 0.5, 0.06, wc, 0.2, 10)
				who.get_tree().create_timer(0.5).timeout.connect(func():
					if is_instance_valid(who):
						FX.hit_spark(c, Color(1, 1, 1), 1.6)
						Combat.hit_sphere(who, c, 1.8, {"dmg": dmg * 0.9, "knock": 9.0, "kind": "heavy", "hitstop": 0.1, "melee": false, "bleed": 4.0}))
		"nodachi":
			if i == 5:   # Zankū Sen: ağızdan kopan hava kesiği öne 10 m ilerler
				var hit_list = []
				var o = who.global_position + Vector3.UP * 1.1
				for k in 8:
					who.get_tree().create_timer(k * 0.05).timeout.connect(func():
						if not is_instance_valid(who):
							return
						var q = o + f * (1.5 + k * 1.2)
						WindFX.streak(func(t: float) -> Vector3: return q + side * lerpf(-1.6, 1.6, t) - f * sin(t * PI) * 0.5, 0.18, 0.08, Color(0.92, 0.96, 1.0, 0.85), 0.0, 12)
						for h in Combat.hit_sphere(who, q, 1.6, {"dmg": dmg * 0.5, "knock": 8.0, "kind": "heavy", "hitstop": 0.05, "melee": false}, hit_list):
							hit_list.append(h))
				_shake(who, 0.5)
		"musta":
			if i == 5:   # Tekken Giri: muşta çarpışmasında şok halkası
				var q = who.global_position + Vector3.UP * 1.2 + f * 1.3
				for k in 10:
					var a = TAU * k / 10.0
					var dd = (side * cos(a) + Vector3.UP * sin(a))
					WindFX.streak(func(t: float) -> Vector3: return q + dd * (0.2 + t * 1.3), 0.2, 0.06, Color(1, 0.95, 0.8, 0.8), 0.0, 8)
				FX.hit_spark(q, Color(1, 0.9, 0.6), 1.5)
				_shake(who, 0.6)
				VFX.slowmo(0.25, 0.2)
		"pence":
			# chakra pençeleri: her yırtıkta bıçaklardan parlayan üç paralel mavi iz; bitirişte dev X
			var glow = Color(0.45, 0.8, 1.0, 0.95)
			var rake = func(d: Vector3, lift: float, length: float, w: float):
				for k in 3:
					var off = side * ((k - 1) * 0.16)
					var o = who.global_position + Vector3.UP * (1.25 + lift) + f * 0.5 + off
					WindFX.streak(func(t: float) -> Vector3: return o + d * (t * length) + Vector3.UP * (-t * 0.9 * signf(lift + 0.001)), 0.18, w, glow, k * 0.02, 10)
			match i:
				0: rake.call((f + side * 0.5).normalized(), 0.3, 1.6, 0.04)
				1: rake.call((f - side * 0.5).normalized(), 0.3, 1.6, 0.04)
				2:
					rake.call((f + side * 0.6).normalized(), 0.35, 1.8, 0.05)
					rake.call((f - side * 0.6).normalized(), 0.35, 1.8, 0.05)
				3: rake.call(f, -0.6, 1.4, 0.05)
				4: rake.call(f, 0.6, 2.0, 0.05)
				5:
					rake.call((f + side * 0.7).normalized(), 0.5, 3.2, 0.08)
					rake.call((f - side * 0.7).normalized(), 0.5, 3.2, 0.08)
					VFX.star(who.global_position + Vector3.UP * 1.3 + f * 1.8, Color(0.5, 0.85, 1.0), 2.4, 0.18)
					Combat.hit_sphere(who, who.global_position + Vector3.UP * 1.1 + f * 2.2, 2.2, {"dmg": dmg * 0.6, "knock": 10.0, "kind": "heavy", "hitstop": 0.06, "melee": false})
			VFX.star(who.global_position + Vector3.UP * 1.2 + f * 0.6, Color(0.45, 0.8, 1.0), 0.8, 0.1)   # bıçaklarda chakra parlaması
		"senbon":
			_senbon_volley(who, dmg, i)
		"hiramekarei":
			var cc = Color(0.55, 0.75, 1.0, 0.85)
			match i:
				1, 2, 3:   # ikiye bölünmüş: iki bıçaktan iki iz
					for k in 2:
						WindFX.streak(func(t: float) -> Vector3:
							var a = lerpf(-1.1, 1.1, t) * (1.0 if k == 0 else -1.0)
							return who.global_position + Vector3.UP * 1.2 + (f * cos(a) - side * sin(a)) * 2.2, 0.2, 0.08, cc, k * 0.05, 14)
				4:   # birleşip chakra yükler
					VFX.star(who.global_position + Vector3.UP * 2.4, Color(0.6, 0.8, 1.0), 2.2, 0.3)
				5:   # Chakra Tsuchi: kılıcın ucunda dev chakra çekici belirir, yatay savuruşla ezer
					_hk_hammer(who, 0.6)
					for k in 5:
						var a2 = lerpf(-1.2, 1.2, k / 4.0)
						var hp2 = who.global_position + Vector3.UP * 1.1 + (f * cos(a2) - side * sin(a2)) * 2.6
						Combat.hit_sphere(who, hp2, 1.8, {"dmg": dmg * 0.4, "knock": 16.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.05, "melee": false})
					_shake(who, 0.7)
		"bo":
			if i == 5:
				var q = gp.call(1.8)
				VFX.cracks(q, 1.8)
				VFX.debris(q, Color(0.5, 0.45, 0.4), 6, 4.0, 0.25)
		"temari_ogi":
			# ay arttıkça rüzgâr büyür: ince kesici bıçak çizgileri (kamaitachi) + toz; her ay menzili ve gücü artırır
			var moon = [0, 1, 2, 2, 2, 3][clampi(i, 0, 5)]
			var mk = 1.0 + 0.35 * moon
			var blades2 = func(nb: int, length: float, spread: float, h: float, mul: float):
				for k in nb:
					var off = (float(k) / maxf(nb - 1, 1) - 0.5) * spread
					var d = (f + side * off).normalized()
					var o = who.global_position + Vector3.UP * (h + randf_range(-0.3, 0.3))
					WindFX.streak(func(t: float) -> Vector3: return o + d * (0.8 + t * length) + side * sin(t * 6.0 + k) * 0.15, 0.22, 0.035, Color(0.9, 0.97, 1.0, 0.95), k * 0.03, 10)
					Combat.hit_sphere(who, o + d * length * 0.6, 1.1, {"dmg": dmg * mul, "knock": 4.0 * mk, "kind": "light", "hitstop": 0.02, "melee": false, "element": "wind", "bleed": 2.0})
			match i:
				0:
					var q0 = gp.call(1.4)
					VFX.debris(q0, Color(0.6, 0.55, 0.45), 6, 3.0, 0.2)
				1: blades2.call(4, 8.0, 0.6, 1.2, 0.3)   # Birinci Ay: kısa kamaitachi
				2:   # İkinci Ay: rüzgâr duvarı — önündeki her şeyi geri savurur, mermileri dağıtır
					WindFX.gust(who.global_position + Vector3.UP * 1.0 + f, f, 8.0, 4.5, {"n": 16})
					WindFX.wake(gp.call(1.0), f, 7.0, 5.0, Color(0.85, 0.82, 0.72, 0.5), 0.7)
					Combat.hit_zone(who, who.global_position, f, 7.0, 40.0, 3.0, {"dmg": dmg * 0.55, "knock": 16.0, "kind": "light", "melee": false, "element": "wind"})
					for pj in who.get_tree().get_nodes_in_group("projectiles"):
						if is_instance_valid(pj) and pj.global_position.distance_to(who.global_position + f * 3.0) < 4.0 and pj.get("shooter") != who:
							pj.queue_free()
				3:   # kasırga: önündeki rakibi havaya kaldırır
					var q3 = gp.call(2.2)
					WindFX.gust(q3, Vector3.UP, 5.0, 2.0, {"n": 14})
					VFX.debris(q3, Color(0.65, 0.6, 0.5), 10, 6.0, 0.3)
					Combat.hit_sphere(who, q3 + Vector3.UP * 0.8, 2.4, {"dmg": dmg * 0.5, "knock": 2.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.03, "melee": false, "element": "wind"})
				4:   # havadan aşağı: yere çarpan rüzgâr halkası
					var q4 = gp.call(1.8)
					VFX.cracks(q4, 1.6)
					VFX.debris(q4, Color(0.65, 0.58, 0.45), 12, 5.0, 0.3)
					WindFX.wake(q4, f, 5.0, 4.0, Color(0.75, 0.68, 0.55, 0.6), 0.8)
					Combat.hit_sphere(who, q4 + Vector3.UP * 0.4, 3.4, {"dmg": dmg * 0.65, "knock": 9.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.04, "melee": false, "element": "wind"})
					_shake(who, 0.35)
				5:   # Üçüncü Ay — Daikamaitachi: uzun, geniş kesici fırtına
					blades2.call(11, 20.0, 1.4, 1.3, 0.4)
					WindFX.gust(who.global_position + Vector3.UP * 1.2 + f, f, 18.0, 6.0, {"n": 24})
					Dangle.gust(who.global_position + f * 8.0, f * 45.0, 14.0, 1.2)
					_shake(who, 0.6)
		"yelpaze":
			# kesici rüzgâr bıçakları (kamaitachi): ince keskin çizgiler + toz; Bashōsen'in yumuşak dalgalarından farklı
			var blades = func(n: int, length: float, spread: float, h: float):
				for k in n:
					var off = (float(k) / maxf(n - 1, 1) - 0.5) * spread
					var d = (f + side * off).normalized()
					var o = who.global_position + Vector3.UP * (h + randf_range(-0.3, 0.3))
					WindFX.streak(func(t: float) -> Vector3: return o + d * (0.8 + t * length) + side * sin(t * 6.0 + k) * 0.15, 0.22, 0.035, Color(0.9, 0.97, 1.0, 0.95), k * 0.03, 10)
					Combat.hit_sphere(who, o + d * length * 0.6, 1.0, {"dmg": dmg * 0.35, "knock": 4.0, "kind": "light", "hitstop": 0.02, "melee": false, "element": "wind", "bleed": 2.0})
			match i:
				1: blades.call(5, 9.0, 0.8, 1.2)
				2: WindFX.gust(who.global_position + Vector3.UP * 1.0 + f, f, 6.0, 3.0, {"n": 12})
				3:
					for k in 8:
						var d = f.rotated(Vector3.UP, TAU * k / 8.0)
						var o = who.global_position + Vector3.UP * 1.0
						WindFX.streak(func(t: float) -> Vector3: return o + d * (0.6 + t * 4.0), 0.2, 0.035, Color(0.9, 0.97, 1.0, 0.95), k * 0.02, 8)
					Combat.hit_sphere(who, who.global_position + Vector3.UP, 4.0, {"dmg": dmg * 0.6, "knock": 9.0, "kind": "light", "hitstop": 0.03, "melee": false, "element": "wind"})
				4:
					var q = gp.call(1.6)
					VFX.debris(q, Color(0.65, 0.58, 0.45), 12, 5.0, 0.3)
					WindFX.wake(q, f, 5.0, 4.0, Color(0.75, 0.68, 0.55, 0.6), 0.8)
					Combat.hit_sphere(who, q + Vector3.UP * 0.4, 3.2, {"dmg": dmg * 0.6, "knock": 8.0, "launch": 5.0, "kind": "heavy", "hitstop": 0.04, "melee": false})
				5:
					blades.call(9, 16.0, 1.2, 1.3)
					WindFX.gust(who.global_position + Vector3.UP * 1.2 + f, f, 14.0, 5.0, {"n": 20})
					Dangle.gust(who.global_position + f * 6.0, f * 40.0, 12.0, 1.0)
					_shake(who, 0.5)
		"kongo_asa":
			match i:
				0: _staff_extend(who, 2.2, 0.35)
				1:
					var q = gp.call(2.6)
					VFX.cracks(q, 1.8)
					_staff_extend(who, 1.6, 0.4)
				2: _enma_cameo(who, dmg * 1.6, false)
				3: _staff_extend(who, 2.0, 0.5)
				5:
					_staff_extend(who, 3.4, 0.55)
					who.get_tree().create_timer(0.5).timeout.connect(func():
						if is_instance_valid(who):
							_enma_cameo(who, dmg * 2.0, true))
		"yagura_sopa":
			# her adımda su: sopa uçlarından su püskürür (kendi su chakrası), darbede sıçrama, bitirişte girdap
			var wn = _weapon_node(who)
			var tip: Vector3 = wn.to_global(Vector3(0, 0, 1.67)) if wn != null else who.global_position + Vector3.UP * 1.3 + f * 1.5
			var hp = who.global_position + Vector3.UP * 1.1 + f * 1.8
			match i:
				0:   # kanca çekişi: kanca suyla hedefe uzanır, çekerken su kuyruğu
					WaterArt.jet(tip, hp + f * 1.6 + Vector3.DOWN * 0.2, 0.3)   # kancadan hedefe su hortumu (3B serpinti tek başına görünmüyordu)
					WaterArt.spray(tip, 0.9, f, 25.0, 1.4)
					WaterArt.drops(hp, 8, 0.8, 5.0, -f, 0.5)
				1:   # iki uçla: her vuruşta yandan su yayı
					WaterArt.spray(tip, 0.8, (f + side).normalized(), 40.0, 1.2)
					who.get_tree().create_timer(0.24).timeout.connect(func():
						if is_instance_valid(who):
							WaterArt.spray(who.global_position + Vector3.UP * 1.0 + f * 1.2, 0.8, (f - side).normalized(), 40.0, 1.2))
					VFX.splash(hp, 1.4)
				2:   # çark: sopa dönerken çevresine su halkası saçar
					for k in 4:
						who.get_tree().create_timer(k * 0.15).timeout.connect(func():
							if is_instance_valid(who):
								var a = TAU * k / 4.0
								var dd = (f * cos(a) + Vector3.UP * sin(a)).normalized()
								WaterArt.spray(who.global_position + Vector3.UP * 1.1 + f * 1.0, 0.7, dd, 30.0, 1.0)
								Combat.hit_sphere(who, who.global_position + Vector3.UP * 1.1 + f * 1.6, 1.6, {"dmg": dmg * 0.25, "knock": 2.0, "kind": "light", "hitstop": 0.02, "melee": false, "element": "water"}))
				3:   # süpürme + kaldırma: yerden su sütunu
					var q = gp.call(1.8)
					WaterArt.ripple(q, 2.0)
					WaterArt.spray(q, 1.4, Vector3.UP, 15.0, 1.8)
					WaterArt.splash(q, 1.2)
				4:   # kancayla yakalama (pull) + su kalkanı + itme: önde su duvarı, ardından su dalgası öne
					WaterArt.jet(tip, hp + f * 1.8, 0.32, 0.2)   # kanca su hortumuyla hedefi yakalar
					var q = gp.call(1.2)
					WaterArt.splash(q, 1.6)
					WaterArt.spray(q + Vector3.UP * 0.3, 1.6, f, 30.0, 1.6, true)
					Combat.hit_sphere(who, who.global_position + f * 2.4 + Vector3.UP, 2.2, {"dmg": dmg * 0.6, "knock": 11.0, "kind": "light", "hitstop": 0.03, "melee": false, "element": "water"})
				5:   # Suijin Senpū (UZUN MENZİL): yatay savuruştan çıkan su dalgası öne 13 m ilerler (fışkırma dizisi) -> ucunda su girdabı
					var q0 = gp.call(1.6)
					WaterArt.spray(who.global_position + Vector3.UP * 1.1 + f * 1.4, 1.6, f, 50.0, 1.8, true)
					_shake(who, 0.5)
					for k in 8:
						who.get_tree().create_timer(0.06 + k * 0.07).timeout.connect(func():
							if not is_instance_valid(who):
								return
							var qd = q0 + f * (1.2 + k * 1.6)
							qd.y = q0.y
							WaterArt.ripple(qd, 1.4)
							WaterArt.spray(qd, 1.2 + k * 0.05, Vector3.UP, 14.0, 1.6)
							Combat.hit_sphere(who, qd + Vector3.UP * 0.8, 1.6, {"dmg": dmg * 0.3, "knock": 6.0, "launch": 5.0, "kind": "heavy", "hitstop": 0.03, "melee": false, "element": "water"}))
					who.get_tree().create_timer(0.66).timeout.connect(func():
						if not is_instance_valid(who):
							return
						var q = q0 + f * 13.0
						WaterArt.splash(q, 2.4)
						for k in 3:
							WindFX.streak(func(t: float) -> Vector3:
								var a2 = t * TAU * 2.0 + k * 2.1
								return q + Vector3(cos(a2) * (1.0 + t * 1.6), t * 3.2, sin(a2) * (1.0 + t * 1.6)), 0.6, 0.12, Color(0.55, 0.8, 1.0, 0.85), k * 0.08, 24)
						Combat.hit_sphere(who, q + Vector3.UP, 3.4, {"dmg": dmg * 0.7, "knock": 12.0, "launch": 7.0, "kind": "heavy", "hitstop": 0.06, "melee": false, "element": "water"}))
		"kubikiribocho":
			match i:
				1:   # boyun biçmesi: geniş kılıç izi
					WindFX.streak(func(t: float) -> Vector3:
						var a = lerpf(-1.4, 1.4, t)
						return who.global_position + Vector3.UP * 1.45 + (f * cos(a) - side * sin(a)) * 2.6, 0.2, 0.09, Color(0.85, 0.9, 1.0, 0.75), 0.0, 16)
				4:   # kılıcın saplandığı yer
					var q = gp.call(1.3)
					VFX.cracks(q, 1.2)
				5:   # Kirigakure Kubikiri: arkadan boyun biçmesi (sis içinde)
					WindFX.streak(func(t: float) -> Vector3:
						var a2 = lerpf(-1.5, 1.5, t)
						return who.global_position + Vector3.UP * 1.45 + (f * cos(a2) - side * sin(a2)) * 2.8, 0.22, 0.12, Color(0.85, 0.9, 1.0, 0.85), 0.0, 18)
					Combat.hit_sphere(who, who.global_position + Vector3.UP * 1.3 + f * 1.8, 2.4, {"dmg": dmg * 0.8, "knock": 12.0, "kind": "heavy", "hitstop": 0.1, "melee": false, "bleed": 6.0})
					VFX.slowmo(0.25, 0.3)
		"bashosen":
			# her savuruşun kendi rüzgârı: yatay yelpaze dalgası, yere basan dalga, yükselen burgu, çevre halkası, dev fırtına koridoru
			var from = who.global_position + Vector3.UP * 1.1 + f * 0.7
			match i:
				0, 1:
					var sweep = side * (1.0 if i == 0 else -1.0)
					WindFX.gust(from, (f + sweep * 0.25).normalized(), 8.0, 4.0, {"n": 14})
					Combat.hit_sphere(who, from + f * 3.5, 2.6, {"dmg": dmg * 0.7, "knock": 10.0, "kind": "light", "hitstop": 0.03, "melee": false, "element": "wind"})
				2:
					var q = gp.call(2.0)
					WindFX.gust(q + Vector3.UP * 0.3, f, 7.0, 5.0, {"n": 16})
					VFX.debris(q, Color(0.6, 0.55, 0.45), 8, 4.0, 0.25)
					Combat.hit_sphere(who, q + f * 2.5 + Vector3.UP * 0.5, 3.0, {"dmg": dmg * 0.8, "knock": 8.0, "kind": "heavy", "hitstop": 0.04, "melee": false, "element": "wind"})
				3:
					for k in 3:
						WindFX.streak(func(t: float) -> Vector3:
							var a = t * TAU * 1.5 + k * 2.1
							return who.global_position + f * 2.4 + Vector3(cos(a) * (0.6 + t * 0.6), t * 4.0, sin(a) * (0.6 + t * 0.6)), 0.5, 0.08, Color(0.85, 0.95, 0.9, 0.8), k * 0.05, 16)
					Combat.hit_sphere(who, who.global_position + f * 2.4 + Vector3.UP, 1.8, {"dmg": dmg * 0.6, "knock": 1.0, "launch": 9.0, "kind": "light", "hitstop": 0.03, "melee": false, "element": "wind"})
				4:
					for k in 2:
						WindFX.streak(func(t: float) -> Vector3:
							var a = t * TAU
							return who.global_position + Vector3.UP * (0.6 + k * 0.6) + Vector3(cos(a), 0, sin(a)) * 3.2, 0.4, 0.1, Color(0.85, 0.95, 0.9, 0.75), k * 0.06, 24)
					Combat.hit_sphere(who, who.global_position + Vector3.UP, 3.6, {"dmg": dmg * 0.6, "knock": 12.0, "kind": "light", "hitstop": 0.03, "melee": false, "element": "wind"})
				5:
					WindFX.gust(from, f, 16.0, 6.0, {"n": 24})
					for k in 4:
						Combat.hit_sphere(who, from + f * (2.5 + k * 3.2), 2.8, {"dmg": dmg * 0.5, "knock": 16.0, "kind": "heavy", "hitstop": 0.04, "melee": false, "element": "wind"})
					Dangle.gust(from + f * 6.0, f * 40.0, 12.0, 1.0)
					_shake(who, 0.5)
		"zincirli_kunai":
			match i:
				1:
					_kg_weight(who, dmg, "straight")
				2:
					_kg_weight(who, dmg, "whirl")
				4:
					_kg_weight(who, dmg, "wrap")
		"kusarigama":
			match i:
				1:
					_kg_weight(who, dmg, "straight")
				2:
					_kg_weight(who, dmg, "whirl")
				3:
					_kg_sickle(who, dmg)
				5:   # Shinigami Gari: uzun orak yere kadar iner — önde yarık + toz
					var q = gp.call(2.2)
					VFX.cracks(q, 2.4)
					VFX.debris(q, Color(0.5, 0.45, 0.4), 8, 5.0, 0.3)
					_shake(who, 0.5)
		"kusanagi":
			var bl = Color(0.55, 0.8, 1.0)
			var wn = _weapon_node(who)
			var tip: Vector3 = wn.to_global(Vector3(0, 0, 0.9)) if wn != null else who.global_position + Vector3.UP * 1.2 + f * 1.2
			match i:
				0, 1:   # ağızda kısa Chidori kıvılcımı
					VFX.bolt(tip - f * 0.6, tip, bl, 0.12, 0.12, 2)
				2:   # Shunshin Tsuki: ani atılma + saplama, arkada şimşek izi
					VFX.bolt(who.global_position + Vector3.UP - f * 2.4, who.global_position + Vector3.UP, bl, 0.18, 0.2, 3)
				4:   # Chidori Nagashi: kılıç yere saplanır, akım çevreye yayılır, çevredekiler uyuşur
					var c = who.global_position + f * 1.0
					c.y = Game.ground_height(c.x, c.z) + 0.1
					for k in 8:
						var a2 = TAU * k / 8.0
						VFX.bolt(c, c + Vector3(cos(a2), 0.05, sin(a2)) * 3.2, bl, 0.2, 0.3, 2)
					VFX.cracks(c, 1.6)
					Combat.hit_sphere(who, c + Vector3.UP * 0.5, 3.4, {"dmg": dmg * 0.6, "knock": 3.0, "stun": 0.8, "kind": "light", "hitstop": 0.06, "melee": false})
					Sfx.play("zap", c, 1.2, 0.7)
				5:   # Iai Senkō: hedefin içinden şimşek gibi geçer; kılıç kına girerken kesik gecikmeli açılır
					_kusa_iai(who, dmg)
		"homatsu_kiseru":
			_kiseru_strike(who, i, dmg)
		"hiraishin_kunai":
			if i == 5:   # Hiraishin Giri: hedefin çevresinde art arda üç flaşla belirip keser
				var tg = _hira_target(who)
				if tg != null:
					for k in 3:
						who.get_tree().create_timer(0.04 + k * 0.09).timeout.connect(func():
							if is_instance_valid(who) and is_instance_valid(tg):
								var a = TAU * k / 3.0 + 0.6
								_blink(who, tg, Vector3(cos(a), 0, sin(a)) * 1.4)
								Combat.hit_sphere(who, tg.global_position + Vector3.UP, 1.2, {"dmg": dmg * 0.4, "knock": 2.0, "kind": "light", "hitstop": 0.03, "melee": true}))
		"chakra_bicak":
			if i == 5:   # Hien: bıçaklara chakra akar — mavi-beyaz uzayan ağız izi
				var q = gp.call(1.6) + Vector3.UP * 1.2
				for k in 2:
					var sx = -0.35 + k * 0.7
					WindFX.streak(func(t: float) -> Vector3: return q + side * sx + f * t * 2.6, 0.18, 0.09, Color(0.75, 0.9, 1.0, 0.9), k * 0.04, 12)
				VFX.star(q + f * 1.8, Color(0.8, 0.92, 1.0), 2.4, 0.16)
				_shake(who, 0.4)
		"ruzgar_bicak":
			_wind_slash(who, i, f, side, dmg)
		"kabutowari":
			match i:
				2:   # çift darbe: kancadan sonra çekiç önde yere iner
					who.get_tree().create_timer(0.24).timeout.connect(func():
						if is_instance_valid(who):
							var q = gp.call(1.7, 0.3)
							VFX.cracks(q, 1.8)
							VFX.debris(q, Color(0.5, 0.45, 0.4), 8, 5.0, 0.3)
							_shake(who, 0.35))
				3:   # kama çakma: çekiç baltanın sırtına çarpar — metal kıvılcım + beyaz flaş
					var q = gp.call(1.6) + Vector3.UP * 1.2
					VFX.star(q, Color(1, 1, 1), 3.6, 0.2)
					FX.burst(q, {"amount": 22, "life": 0.4, "tex": FX.tex_spark, "size": 0.5, "vmin": 5, "vmax": 11, "colors": [Color(1, 0.95, 0.7, 1), Color(1, 0.6, 0.2, 0)]})
					_shake(who, 0.6)
				5:   # Kabuto Wari: balta yere çakılır, çekiç sırtına iner — önde uzun yarık
					for k in 5:
						who.get_tree().create_timer(k * 0.05).timeout.connect(func():
							if is_instance_valid(who):
								var q = gp.call(1.8 + k * 1.2)
								VFX.cracks(q, 2.4 - k * 0.2)
								VFX.debris(q, Color(0.5, 0.45, 0.4), 6, 6.0, 0.35))
					VFX.star(gp.call(1.8) + Vector3.UP * 0.6, Color(1, 1, 1), 3.2, 0.2)
					_shake(who, 0.8)
		"samehada":
			var blue = Color(0.45, 0.75, 1.0)
			match i:
				0:   # rende: temas boyunca mavi chakra kıvılcımları
					for k in 3:
						who.get_tree().create_timer(0.12 * (k + 1)).timeout.connect(func():
							if is_instance_valid(who):
								FX.hit_spark(gp.call(1.8, 0.3 - k * 0.3) + Vector3.UP * 0.7, blue, 1.0))
				1:
					VFX.star(gp.call(1.8) + Vector3.UP * 1.2, Color(1, 1, 1), 2.6, 0.18)
					_shake(who, 0.5)
				2:   # canlı atılış: Samehada kendi kabarıp ileri atılır (kısa süre büyür), uçta mavi ısırık
					_swell(who, 1.25, 0.1, 0.15)
					VFX.star(gp.call(3.2) + Vector3.UP * 1.0, blue, 2.8, 0.18)
				3:   # ısırık: pullar dikene döner (dikenli mavi patlama)
					var q = gp.call(1.6) + Vector3.UP * 2.0
					VFX.star(q, blue, 3.4, 0.22)
					FX.burst(q, {"amount": 18, "life": 0.45, "tex": FX.tex_spark, "size": 0.6, "vmin": 4, "vmax": 9, "colors": [Color(0.85, 0.95, 1, 1), Color(0.35, 0.6, 1, 0)]})
					_shake(who, 0.35)
				4:   # havadan iniş: önde çatlak + şok
					var q = gp.call(2.0)
					VFX.cracks(q, 2.6)
					VFX.shockwave(q + Vector3.UP * 0.1, blue, 4.5, 0.35)
					VFX.debris(q, Color(0.5, 0.45, 0.4), 10, 6.0, 0.3)
					_shake(who, 0.55)
				5:   # Ziyafet: öndeki yere çarpış
					var q = gp.call(2.2)
					VFX.cracks(q, 2.8)
					VFX.shockwave(q + Vector3.UP * 0.1, blue, 5.0, 0.4)
					VFX.debris(q, Color(0.5, 0.45, 0.4), 12, 7.0, 0.35)
					_shake(who, 0.6)
		"uc_tirpan":
			if i == 3:
				var q = gp.call(2.3)
				VFX.cracks(q, 3.2)
				VFX.debris(q, Color(0.45, 0.38, 0.3), 12, 7.0, 0.35)
				FX.impact(q, Color(0.75, 0.65, 0.5), 0.9)
				_shake(who, 0.45)
		"shibuki":
			match i:
				0:   # yay boyunca üç küçük patlama (sağdan sola)
					for k in 3:
						_boom(who, gp.call(1.9, -1.1 + k * 1.1) + Vector3.UP * 0.9, 0.5, dmg * 0.4, 1.4, k * 0.05)
				1:   # rulo yere: patlama + çatlak
					var q = gp.call(1.8, -0.5)
					VFX.cracks(q, 2.6)
					_boom(who, q + Vector3.UP * 0.3, 0.8, dmg * 0.6, 2.0, 0.0, 5.0)
					_shake(who, 0.4)
				2:   # beş kâğıt yelpaze gibi uçar, düşer, sırayla patlar
					for k in 5:
						var a = deg_to_rad(-36.0 + k * 18.0)
						var dir = (f * cos(a) + side * sin(a)).normalized()
						var land = who.global_position + dir * randf_range(3.2, 5.8)
						land.y = Game.ground_height(land.x, land.z) + 0.05
						_fly_tag(who, who.global_position + Vector3.UP * 2.0 + f * 0.8, land, 0.35 + k * 0.05, dmg * 0.45)
				3:   # ters savuruş: tek büyük patlama baş hizasında
					_boom(who, gp.call(1.8) + Vector3.UP * 1.4, 0.95, dmg * 0.7, 2.2, 0.0)
					_shake(who, 0.35)
				4:   # rulo ucunda patlama; itişi kullanıcıyı da geri iter
					_boom(who, gp.call(2.3) + Vector3.UP * 1.0, 0.75, dmg * 0.6, 1.8, 0.0)
					if who is CharacterBody3D:
						who.velocity += -f * 7.0 + Vector3.UP * 1.5
				5:   # kâğıt yere damga: ileri doğru büyüyen beş patlamalık zincir
					VFX.cracks(gp.call(1.6), 2.4)
					for k in 5:
						_boom(who, gp.call(1.6 + k * 1.3) + Vector3.UP * 0.4, 0.55 + k * 0.12, dmg * 0.6, 1.6 + k * 0.15, 0.08 + k * 0.11, 3.0 if k == 4 else 1.5)
					_shake(who, 0.6)


static func _shake(who: Node3D, a: float) -> void:
	if who is Player and Game.world:
		Game.world.env.add_shake(a)


## Patlama (gecikmeli olabilir): ateşli patlama görseli + alan hasarı (sahibini ve dostlarını vurmaz: Combat.hit_sphere)
static func _boom(who: Node3D, pos: Vector3, s: float, dmg: float, r: float, delay: float, launch := 2.0) -> void:
	var fire = func():
		if not is_instance_valid(who):
			return
		FX.explosion(pos, s)
		Combat.hit_sphere(who, pos, r, {"dmg": dmg, "knock": 7.0, "launch": launch, "kind": "heavy", "burn": 1.5, "hitstop": 0.03})
	if delay <= 0.0:
		fire.call()
	else:
		who.get_tree().create_timer(delay).timeout.connect(fire)


static var _tag_fly_mat: StandardMaterial3D
## Uçan mühür kâğıdı: kavisle düşer, yere yapışır, kısa bekleyip patlar
static func _fly_tag(who: Node3D, from: Vector3, to: Vector3, dur: float, dmg: float) -> void:
	if _tag_fly_mat == null:
		_tag_fly_mat = StandardMaterial3D.new()
		_tag_fly_mat.albedo_texture = load("res://assets/weapons/shibuki_tag.png")
		_tag_fly_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		_tag_fly_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_tag_fly_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var q = MeshInstance3D.new()
	var qm = QuadMesh.new()
	qm.size = Vector2(0.16, 0.4)
	q.mesh = qm
	q.material_override = _tag_fly_mat
	who.get_tree().current_scene.add_child(q)
	q.global_position = from
	var spin = randf_range(6.0, 11.0)
	var tw = q.create_tween()
	tw.tween_method(func(t: float):
		if is_instance_valid(q):
			q.global_position = from.lerp(to, t) + Vector3.UP * sin(t * PI) * 1.4
			q.rotation = Vector3(t * spin, t * spin * 0.6, 0.0) if t < 0.95 else Vector3(-PI * 0.5, 0, 0), 0.0, 1.0, dur)
	tw.tween_interval(0.35)   # yere yapışık bekler
	tw.tween_callback(func():
		if is_instance_valid(q):
			q.queue_free()
		_boom(who, to + Vector3.UP * 0.3, 0.6, dmg, 1.6, 0.0))


## Adım başlarken (oyuncu _start_step / düşman _swing_keyed): sıçrama, Samehada'nın sargısını açıp büyümesi vb.
static func on_start(id: String, i: int, who: Node3D) -> void:
	if who == null or not is_instance_valid(who):
		return
	if id.begins_with("style_"):
		_style_start(id, i, who)
		return
	match id:
		"temari_ogi":
			# ay mekaniği: adıma göre yelpaze kaçıncı aya kadar açılır (kapalı / 1 / 2 / 3)
			_ogi_stage(who, [0, 1, 2, 2, 2, 3][clampi(i, 0, 5)], [0.85, 0.95, 0.95, 1.0, 1.05, 1.45][clampi(i, 0, 5)])
			if i == 4 and who is CharacterBody3D:
				who.velocity.y = 8.0   # Ōgi Tobi: yelpazeye sıçrayıp havadan savurur
		"zincirli_kunai":
			if i == 5:
				_kg_weight(who, 0.0, "wrap")
		"pence", "senbon":
			var jp = 7.0 if (id == "pence" and i == 4) or (id == "senbon" and i == 3) else 0.0
			if jp > 0.0 and who is CharacterBody3D:
				who.velocity.y = jp
				if id == "senbon":
					var bf: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.ZERO
					who.velocity.x -= bf.x * 6.0
					who.velocity.z -= bf.z * 6.0
		"hiramekarei":
			if i == 1:
				_hk_split(who, 2.9)
			elif i == 4:
				_hk_join(who)
		"bo":
			if i == 5 and who is CharacterBody3D:
				who.velocity.y = 7.5
		"savas_cekici":
			if i == 5 and who is CharacterBody3D:
				who.velocity.y = 9.5   # zıplayıp yere çakma YALNIZ çekiçte (kalıp tekrarı yok)
		"kubikiribocho":
			if i == 5:
				_kirigakure(who)
		"hakko_chakura_to":
			if i == 2:   # Shiroi Kiba: şunşin — rakibin içinden geçip arkasında belirir, geride beyaz çizgi
				_hakko_dash(who)
			elif i == 3:   # Furimuki: arkasında belirdiği rakibe dönüp keser (kamera yönüne değil)
				var tf = _near_foe(who, 5.0)
				if tf:
					if who is Player:
						who.combat.face_to(tf)
					elif who.get("facing") != null:
						var dd = tf.global_position - who.global_position
						who.facing = atan2(-dd.x, -dd.z)
			elif i == 5:   # Hakkō Zan: ağız beyaz chakra ile dolar (kurulum boyunca)
				var n2 = _weapon_node(who)
				if n2 != null:
					for k in 7:
						who.get_tree().create_timer(k * 0.09).timeout.connect(func():
							if is_instance_valid(n2):
								for q in 3:
									FX.hit_spark(n2.to_global(Vector3(0, 0, 0.08 + q * 0.1)), Color(1, 1, 1), 0.45))
		"tanto":
			if i == 5 and false:   # (beyaz chakra parlaması Hakkō Chakura Tō'ya taşındı)
				var n = _weapon_node(who)
				if n != null:
					for k in 6:
						who.get_tree().create_timer(k * 0.1).timeout.connect(func():
							if is_instance_valid(n):
								FX.hit_spark(n.to_global(Vector3(0, 0, 0.1 + k * 0.05)), Color(1, 1, 1), 0.5))
		"kiba":
			if i == 5:
				who.get_tree().create_timer(0.4).timeout.connect(func():
					if is_instance_valid(who):
						for tp in _kiba_tips(who):
							VFX.bolt(tp[1] + Vector3.UP * 25.0, tp[1], Color(0.75, 0.88, 1.0), 0.5, 0.35, 4)
						Sfx.play("zap", who.global_position, 1.4, 0.6))
			elif i == 4:
				for tp in _kiba_tips(who):
					VFX.bolt(tp[0], tp[1], Color(0.6, 0.8, 1.0), 0.2, 0.45, 3)
		"fuma_shuriken", "kyodai_shuriken":
			var jmp = 6.0 if (id == "fuma_shuriken" and i == 2) else 0.0
			if jmp > 0.0 and who is CharacterBody3D:
				who.velocity.y = jmp
		"kusarigama":
			if i == 5:   # bitiriş: ağırlık fırlatılıp hedefe dolanır, zincir çekilir
				_kg_weight(who, 0.0, "wrap")
		"hiraishin_kunai":
			if i == 2 or i == 4:   # Hiraishin: hedefin (işaretli olanı önce) arkasında / yanında sarı flaşla belir
				var tg = _hira_target(who)
				if tg != null:
					var back = tg.global_position - who.global_position
					back.y = 0
					back = back.normalized() if back.length() > 0.01 else Vector3.FORWARD
					var side = Vector3.UP.cross(back)
					_blink(who, tg, back * 1.3 if i == 2 else side * 1.3)
		"samehada":
			if i == 4 and who is CharacterBody3D:   # Havada Ezme: fırlayan rakibin peşinden sıçra
				who.velocity.y = 8.5
				var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.ZERO
				who.velocity.x += f.x * 2.5
				who.velocity.z += f.z * 2.5
			if i == 5:   # Ziyafet: sargı açılır (pullu canlı hali), kılıç büyür; bitince sarılıp küçülür
				_unwrap(who, 1.6)
				_swell(who, 1.3, 0.25, 1.2)


## Temari yelpazesinin açıklığı (0 kapalı, 1-3 açık ay sayısı); adım bitince yeniden kapanır
static func _ogi_stage(who: Node3D, stage: int, dur: float) -> void:
	var n = _weapon_node(who)
	if n == null or not (n is MeshInstance3D):
		return
	(n as MeshInstance3D).mesh = CharacterModel.weapon_mesh("temari_ogi_%d" % stage if stage > 0 else "temari_ogi")
	if stage > 0:
		Sfx.play("whoosh", who.global_position, 1.3, 0.4)   # yelpaze açılma sesi
	var tok = int(who.get_meta("ogi_tok", 0)) + 1
	who.set_meta("ogi_tok", tok)
	who.get_tree().create_timer(dur + 0.25).timeout.connect(func():
		if is_instance_valid(who) and int(who.get_meta("ogi_tok", 0)) == tok and is_instance_valid(n):
			(n as MeshInstance3D).mesh = CharacterModel.weapon_mesh("temari_ogi"))


static func _weapon_node(who: Node3D) -> Node3D:
	var m = who.get("model")
	if m == null or m.get("weapons") == null or (m.weapons as Array).is_empty():
		return null
	var n = m.weapons[0]["node"]
	return n if is_instance_valid(n) else null


## Samehada'nın boyu: doyma (6 sn) × anlık kabarma
static func _apply_size(who: Node3D) -> void:
	var n = _weapon_node(who)
	if n == null:
		return
	var sat = int(who.get_meta("same_sat", 0))
	var sw = float(who.get_meta("same_swell", 1.0))
	n.scale = Vector3.ONE * (1.0 + 0.06 * sat) * sw


## Anlık kabarma: rise sn'de s katına, hold sn tutar, geri iner
static func _swell(who: Node3D, s: float, rise: float, hold: float) -> void:
	var tw = who.create_tween()
	tw.tween_method(func(v: float):
		if is_instance_valid(who):
			who.set_meta("same_swell", v)
			_apply_size(who), 1.0, s, rise)
	tw.tween_interval(hold)
	tw.tween_method(func(v: float):
		if is_instance_valid(who):
			who.set_meta("same_swell", v)
			_apply_size(who), s, 1.0, 0.35)


## Sargıyı aç: pullu canlı Samehada modeline geç, dur sn sonra sargılıya dön
static func _unwrap(who: Node3D, dur: float) -> void:
	var n = _weapon_node(who)
	if not (n is MeshInstance3D):
		return
	(n as MeshInstance3D).mesh = CharacterModel.weapon_mesh("samehada_acik")
	FX.burst(n.global_position, {"amount": 14, "life": 0.5, "size": 0.5, "vmin": 2, "vmax": 5, "colors": [Color(0.95, 0.95, 0.9, 1), Color(0.8, 0.8, 0.75, 0)]})   # sargı parçaları
	who.get_tree().create_timer(dur).timeout.connect(func():
		if is_instance_valid(n):
			(n as MeshInstance3D).mesh = CharacterModel.weapon_mesh("samehada"))


## Samehada yer (kanon): rakibin chakrasını emer (sahibine geçer), mühür yapıyorsa jutsusunu yutar (iptal), buff / chakra
## pelerinlerini söker; her isabette doyar ve büyür (6 sn yemezse eski boyu). Ziyafet'te çok daha fazla emer.
static func _samehada_eat(who: Node3D, h: Node3D, feast: bool) -> void:
	if not is_instance_valid(who) or not is_instance_valid(h):
		return
	var blue = Color(0.45, 0.75, 1.0)
	var take = 18.0 if feast else 6.0
	var got = 0.0
	if h is Player:
		got = minf(take, h.chakra)
		h.chakra = maxf(0.0, h.chakra - take)
		if h.combat and String(h.combat.get("action")) == "cast":   # mühür yaparken: jutsu yutuldu
			h.combat.action = ""
			h.model.overlay.set_pose("seal", 0.0)
			Combat.popup_text(h.global_position + Vector3.UP * 2.2, "Jutsu yutuldu!", blue)
		if Buffs.active.keys().any(func(k): return k in Buffs.MODE_GROUP or k == "beast"):
			Buffs.clear_modes()
			Buffs.remove("beast")
			Combat.popup_text(h.global_position + Vector3.UP * 2.5, "Chakra pelerini yenildi!", blue)
	else:
		if "chakra" in h:
			got = minf(take, float(h.chakra))
			h.chakra = maxf(0.0, float(h.chakra) - take)
		else:
			got = take * 0.5
		if String(h.get("state")) == "cast":
			h.state = "hitstun"
			h.state_t = 0.0
			if h.get("model"):
				h.model.overlay.set_pose("seal", 0.0)
			Combat.popup_text(h.global_position + Vector3.UP * 2.2, "Jutsu yutuldu!", blue)
		if h.get("buffs") is Dictionary and not (h.buffs as Dictionary).is_empty():
			h.buffs.clear()
			Combat.popup_text(h.global_position + Vector3.UP * 2.5, "Güçlendirme yenildi!", blue)
	# sahibine geçer
	if who is Player:
		who.chakra = minf(who.max_chakra, who.chakra + maxf(got, 2.0))
	elif "chakra" in who:
		who.chakra = float(who.chakra) + maxf(got, 2.0)
	# doyma: büyür (en fazla 5 kademe), 6 sn yemezse küçülür
	var sat = mini(5, int(who.get_meta("same_sat", 0)) + (2 if feast else 1))
	who.set_meta("same_sat", sat)
	who.set_meta("same_sat_until", Time.get_ticks_msec() + 6000)
	_apply_size(who)
	who.get_tree().create_timer(6.05).timeout.connect(func():
		if is_instance_valid(who) and Time.get_ticks_msec() >= int(who.get_meta("same_sat_until", 0)):
			who.set_meta("same_sat", 0)
			_apply_size(who))
	# rakipten sahibine akan mavi chakra (Ziyafet'te uzun akış)
	var n = 6 if feast else 2
	for k in n:
		who.get_tree().create_timer(k * 0.06).timeout.connect(func():
			if is_instance_valid(who) and is_instance_valid(h):
				var a = h.global_position + Vector3.UP * 1.2
				var b = who.global_position + Vector3.UP * 1.2
				for j in 4:
					FX.hit_spark(a.lerp(b, (j + 1) / 5.0), blue, 0.5))


## Kabutowari "miğfer kıran": savunmayı ve zırh buff'larını parçalar (oyuncu: zırh/kalkan jutsuları; AI: kendi buff'ları + blok)
static func _shatter(who: Node3D, h: Node3D) -> void:
	if not is_instance_valid(h):
		return
	var broke = false
	if h is Player:
		for k in Buffs.active.keys():
			if float((Buffs.active[k]["mods"] as Dictionary).get("armor", 1.0)) < 1.0:
				Buffs.remove(k)
				broke = true
		if h.combat and String(h.combat.get("action")) == "guard":
			h.combat.action = ""
			broke = true
	else:
		if h.get("buffs") is Dictionary:
			for k in (h.buffs as Dictionary).keys():
				if float((h.buffs[k]["mods"] as Dictionary).get("armor", 1.0)) < 1.0:
					h.buffs.erase(k)
					broke = true
		if h.get("guarding"):
			h.guarding = false
			broke = true
		if h.has_method("apply_status"):
			h.apply_status("armor_broken", 5.0)
	if broke:
		Combat.popup_text(h.global_position + Vector3.UP * 2.4, "Zırh Kırıldı!", Color(1, 0.8, 0.4))


## Rüzgar Chakra Bıçağı: her savuruşta ileri uçan rüzgar kesiği — görsel (perde + akım çizgileri) ve yol boyunca fuuton hasarı
## (oyuncu da düşman da). i: adım (1 hilal çapraz, 2 yatay, 3 yükselen, 4 mızrak, 5 çift hilal, 6 dev dikey)
static func _wind_slash(who: Node3D, i: int, f: Vector3, side: Vector3, dmg: float) -> void:
	var from = who.global_position + Vector3.UP * 1.2 + f * 0.8
	var length = [7.0, 7.0, 6.0, 10.0, 7.0, 13.0][clampi(i, 0, 5)]
	var width = [3.0, 4.0, 2.6, 1.2, 3.0, 5.5][clampi(i, 0, 5)]
	var lift = [0.0, 0.0, 1.2, 0.0, 0.0, 0.0][clampi(i, 0, 5)]
	var fire = func(delay: float):
		var go = func():
			if not is_instance_valid(who):
				return
			WindFX.gust(from, f, length, width, {"n": 10, "sheets": 3 if i < 5 else 6, "speed": 38.0, "lift": lift, "leaves": i == 5, "dust": i == 5})
			# yol boyunca isabet (yakın vuruşun ötesindeki düşmanlar da kesilir)
			var info = {"dmg": dmg * (0.45 if i < 5 else 0.9), "element": "fuuton", "knock": 6.0 if i < 5 else 14.0, "launch": 4.0 if i == 2 else 0.0,
				"kind": "heavy" if i == 5 else "light", "hitstop": 0.02}
			var hit_once: Array = []
			for k in 4:
				var c = from + f * (2.0 + k * (length - 2.0) / 3.0)
				for h in Combat.hit_sphere(who, c, width * 0.4 + 0.6, info, hit_once):
					hit_once.append(h)
					FX.hit_spark(h.global_position + Vector3.UP, Color(0.7, 1.0, 0.85), 1.0)
			if i == 5:
				_shake(who, 0.55)
		if delay <= 0.0:
			go.call()
		else:
			who.get_tree().create_timer(delay).timeout.connect(go)
	fire.call(0.0)
	if i == 4:   # çift hilal: ikinci kesik
		fire.call(0.16)


## Hiraishin hedefi: bu ninjanın işaretlediği (öncelikli) ya da 14 m içindeki en yakın düşman
static func _hira_target(who: Node3D) -> Node3D:
	var best: Node3D = null
	var bd = 14.0
	var my = who.get_instance_id()
	for f in who.get_tree().get_nodes_in_group("fighters"):
		if f == who or not Combat.hostile(who, f) or f.is_dead():
			continue
		var d = f.global_position.distance_to(who.global_position)
		if f.has_meta("hiraishin_by") and int(f.get_meta("hiraishin_by")) == my and f.has_method("has_status") and f.has_status("marked"):
			d *= 0.3   # işaretli hedef öncelikli
		if d < bd:
			bd = d
			best = f
	return best


## Sarı flaş ışınlanma: eski yerde ve yeni yerde sarı parlama + kıvılcım, hedefin yanına (off) ışınlan, ona dön
# ------------------------------------------------------------------ Iburi dumanı (PathJutsu._smoke görünüşü: açık mavi-gri kabarık)
static func _smoke_puff_at(p: Vector3, r: float, n: int, dir := Vector3.UP, col := Color(0.62, 0.64, 0.7, 0.9)) -> void:
	VFX.puffs(p, {"amount": n, "life": 0.9, "size": 0.9, "radius": r, "vmin": 0.4, "vmax": 1.2, "dir": dir, "spread": 50.0, "add": false,
		"colors": [col, Color(col.r * 0.7, col.g * 0.7, col.b * 0.75, 0.0)]})


## Duman şeridi: elden hedefe akan kabarık duman (ref iburi_2)
static func _smoke_line(a: Vector3, b: Vector3, r: float, col := Color(0.62, 0.64, 0.7, 0.9)) -> void:
	var n = maxi(4, int(a.distance_to(b) / 0.45))
	var tree = Engine.get_main_loop() as SceneTree
	for k in n:
		var q = a.lerp(b, float(k + 1) / n)
		tree.create_timer(k * 0.015).timeout.connect(func(): _smoke_puff_at(q, r, 3, (b - a).normalized(), col))


## Beden dumana çözülür: çevresinden duman yükselir (eller katı kalır)
static func _smoke_body(who: Node3D, dur: float) -> void:
	for k in int(dur / 0.08):
		who.get_tree().create_timer(k * 0.08).timeout.connect(func():
			if is_instance_valid(who):
				_smoke_puff_at(who.global_position + Vector3.UP * randf_range(0.3, 1.6), 0.45, 3))


## Kemuri Utsuri: dumana dağıl, rakibin arkasında katılaş (kısa dokunulmazlık)
static func _smoke_shift(who: Node3D, tg: Node3D) -> void:
	var from = who.global_position
	var m = who.get("model")
	if m:
		m.visible = false
	_smoke_puff_at(from + Vector3.UP, 0.6, 14)
	var back = tg.global_position - from
	back.y = 0
	back = back.normalized() if back.length() > 0.01 else Vector3.FORWARD
	_smoke_line(from + Vector3.UP, tg.global_position + back * 1.2 + Vector3.UP, 0.35)
	if who is Player:
		who.combat.invuln = maxf(who.combat.invuln, 0.3)
	who.get_tree().create_timer(0.12).timeout.connect(func():
		if not is_instance_valid(who):
			return
		if who.get("model"):
			who.model.visible = true
		if not is_instance_valid(tg):
			return
		var to = tg.global_position + back * 1.2
		to.y = Game.ground_height(to.x, to.z)
		who.global_position = to
		var d = tg.global_position - to
		d.y = 0
		if d.length() > 0.01 and "facing" in who:
			who.facing = atan2(-d.x, -d.z)
		_smoke_puff_at(to + Vector3.UP, 0.6, 14)
		Sfx.play("whoosh", to, 1.2, 0.5))


## Avuçta şimşek topu (Raikiri/Chidori görünüşü): sağ ele bağlı parlayan top + çevreye kırbaçlanan dallar
static func _rai_hand(who: Node3D, dur: float, big: bool) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var ba = pj.bone_attach(who, "RightHand")
	if ba == null:
		return
	var ball = VFX.lightning_ball(0.55 if big else 0.35, Color(0.7, 0.88, 1.0))
	ba.add_child(ball)
	var n = int(dur / 0.08)
	for k in n:
		who.get_tree().create_timer(k * 0.08).timeout.connect(func():
			if is_instance_valid(ball):
				var c = ball.global_position
				VFX.bolt(c, c + Vector3(randf_range(-1, 1), randf_range(-0.6, 0.8), randf_range(-1, 1)).normalized() * (1.6 if big else 0.9), Color(0.7, 0.88, 1.0), 0.06, 0.1, 1))
	if big:
		Sfx.play("chidori", who.global_position, 1.1, 0.6)
	who.get_tree().create_timer(dur + 0.3).timeout.connect(func():
		if is_instance_valid(ba):
			ba.queue_free())


## Raijū Tsuiga: şimşekten tazı (gövde/baş parıltı çekirdekleri, omurga ve bacak arkları) hedefe koşar
static func _rai_hound(who: Node3D, tg: Node3D, dmg: float, f: Vector3) -> void:
	var col = Color(0.55, 0.8, 1.0)
	var hound = Node3D.new()
	hound.add_child(VFX.lightning_ball(0.8, col))
	var head = VFX.lightning_ball(0.5, Color(0.8, 0.92, 1.0))
	head.position = Vector3(0, 0.3, -0.8)
	hound.add_child(head)
	who.get_tree().current_scene.add_child(hound)
	var from = who.global_position + Vector3.UP * 0.8 + f * 1.0
	hound.global_position = from
	var to = (tg.global_position + Vector3.UP * 0.8) if tg else from + f * 10.0
	hound.look_at(Vector3(to.x, from.y, to.z), Vector3.UP)
	var dur = clampf(from.distance_to(to) / 22.0, 0.15, 0.6)
	var tw = hound.create_tween()
	tw.tween_property(hound, "global_position", to, dur)
	tw.tween_callback(func():
		VFX.star(to, Color(0.9, 0.96, 1.0), 2.2, 0.16)
		for k in 4:
			VFX.bolt(to, to + Vector3(randf_range(-1.6, 1.6), randf_range(-0.8, 1.2), randf_range(-1.6, 1.6)), col, 0.1, 0.18, 1)
		if is_instance_valid(who):
			Combat.hit_sphere(who, to, 1.5, _kinfo(dmg, 1.0, {"element": "raiton", "knock": 7.0, "kind": "heavy", "stun": 0.7})))
	tw.tween_callback(hound.queue_free)
	for k in int(dur / 0.05) + 1:   # arkasında şimşek izi
		who.get_tree().create_timer(k * 0.05).timeout.connect(func():
			if is_instance_valid(hound):
				var p = hound.global_position
				VFX.bolt(p, p - (to - from).normalized() * 1.4 + Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), 0), col, 0.08, 0.12, 1))


## Kage Nui iğneleri (ClanJutsu.c_kage_nui görünüşü): hedefin çevresinden yerden fırlayan kara sivri iğneler bedeni deler
static func _shadow_needles(tg: Node3D, n: int) -> void:
	var nm = StandardMaterial3D.new()
	nm.albedo_color = Color(0.03, 0.025, 0.04)
	nm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var body = tg.global_position + Vector3.UP * 1.0
	var tree = tg.get_tree()
	for k in n:
		var a = k * TAU / n + randf_range(-0.2, 0.2)
		var g = tg.global_position + Vector3(cos(a), 0, sin(a)) * randf_range(1.2, 2.0)
		g.y = Game.jutsu_floor(g.x, g.z)
		var dir = (body + Vector3(randf_range(-0.2, 0.2), randf_range(-0.3, 0.4), randf_range(-0.2, 0.2)) - g).normalized()
		var L = g.distance_to(body) + 0.35
		var nd = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.012
		cm.bottom_radius = 0.035
		cm.height = 1.0
		cm.radial_segments = 6
		nd.mesh = cm
		nd.material_override = nm
		nd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tree.current_scene.add_child(nd)
		var sd = dir.cross(Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT).normalized()
		var bs = Basis(sd, dir, sd.cross(dir))
		nd.global_transform = Transform3D(bs * Basis.from_scale(Vector3(1, 0.01, 1)), g)
		var tw = nd.create_tween()
		tw.tween_interval(k * 0.015)
		tw.tween_method(func(x: float):
			if is_instance_valid(nd):
				nd.global_transform = Transform3D(bs * Basis.from_scale(Vector3(1, L * x, 1)), g + dir * L * x * 0.5), 0.01, 1.0, 0.12)
		tw.tween_interval(1.2)
		tw.tween_callback(nd.queue_free)


## Kage Kubi Shibari: hedefin bedeninde yukarı tırmanan kara gölge eli (yassı parmaklı el izi)
static func _shadow_hand(tg: Node3D) -> void:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.04, 0.035, 0.05, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var b = MB.new()
	b.add("box", Vector3(0, 0, 0), Vector3(0.14, 0.18, 0.02), Color.WHITE)
	for f2 in 4:
		b.add("box", Vector3(-0.05 + f2 * 0.035, 0.15, 0), Vector3(0.025, 0.12, 0.02), Color.WHITE)
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(m)
	mi.material_override = m
	tg.add_child(mi)
	var a = randf() * TAU
	var r = float(tg.get("radius")) if tg.get("radius") != null else 0.4
	mi.position = Vector3(cos(a) * (r + 0.02), 0.3, sin(a) * (r + 0.02))
	mi.rotation.y = -a + PI * 0.5
	var tw = mi.create_tween()
	tw.tween_property(mi, "position:y", 1.45, 0.4)
	tw.tween_interval(0.5)
	tw.tween_callback(mi.queue_free)


## Avuçta büyüyen Rasengan (VFX.rasengan): kurulum boyunca sağ ele bağlı, vuruşta söner
static func _rasen_hand(who: Node3D, dur: float) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var ba = pj.bone_attach(who, "RightHand")
	if ba == null:
		return
	var r = VFX.rasengan(0.5)
	ba.add_child(r)
	r.position = Vector3(0, 0.12, 0.1)
	r.scale = Vector3.ONE * 0.2
	var tw = r.create_tween()
	tw.tween_property(r, "scale", Vector3.ONE * 1.4, dur)
	tw.tween_interval(0.12)
	tw.tween_callback(func():
		if is_instance_valid(ba):
			ba.queue_free())


## Mürekkep canavarı (Chōjū Giga): sayfadan fırlar, hedefe koşar, çarpınca mürekkebe dağılır
static func _ink_run(who: Node3D, pj, kind: String, s: float, from: Vector3, to: Vector3, dmg: float, extra: Dictionary) -> void:
	var beast: Node3D = pj._ink_beast(kind, s)
	who.get_tree().current_scene.add_child(beast)
	var g0 = from
	if kind == "tiger":
		g0.y = Game.ground_height(from.x, from.z)
	beast.global_position = g0
	var tg2 = to
	if kind == "tiger":
		tg2.y = Game.ground_height(to.x, to.z)
	var dv = tg2 - g0
	if Vector2(dv.x, dv.z).length() > 0.01:
		beast.look_at(Vector3(tg2.x, g0.y, tg2.z), Vector3.UP)
	pj._ink_splash(g0 + Vector3.UP * 0.5, 10)
	var tw = beast.create_tween()
	tw.tween_property(beast, "global_position", tg2, clampf(g0.distance_to(tg2) / 18.0, 0.15, 0.6))
	tw.tween_callback(func():
		pj._ink_splash(tg2 + Vector3.UP * 0.6, 18)
		if is_instance_valid(who):
			var inf = _kinfo(dmg, 1.0, {"element": "", "knock": 4.0, "kind": "heavy"})
			inf.merge(extra, true)
			Combat.hit_sphere(who, tg2 + Vector3.UP * 0.8, 1.3 * maxf(1.0, s), inf))
	tw.tween_callback(beast.queue_free)


## Kâğıt kanatlar (Konan): sırttan açılıp kapanan büyük kâğıt kanat çifti (gerçek _paper_wing geometrisi)
static func _paper_wings(who: Node3D, dur: float) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var ba = pj.bone_attach(who, "UpperChest")
	if ba == null:
		return
	var root = Node3D.new()
	ba.add_child(root)
	root.position = Vector3(0, 0.0, 0.18)
	for sx in [-1.0, 1.0]:
		var b = MB.new()
		pj._paper_wing(b, sx)
		var mi = MeshInstance3D.new()
		mi.mesh = b.build(Props.toon())
		root.add_child(mi)
	root.scale = Vector3.ONE * 0.1
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.15)
	tw.tween_interval(maxf(0.1, dur - 0.3))
	tw.tween_property(root, "scale", Vector3.ONE * 0.05, 0.15)
	tw.tween_callback(func():
		if is_instance_valid(ba):
			ba.queue_free())


## Tarz kuklası: gerçek savaş kuklası modeli + chakra iplikleri, DUMANSIZ belirir/kaybolur (her vuruşta duman bulutu görüşü kapatıyordu)
static func _style_puppet(who: Node3D, pj, at: Vector3, d: Vector3, dur: float) -> Node3D:
	var pup: Node3D = pj._puppet_mesh(1.0)
	who.get_tree().current_scene.add_child(pup)
	var g = at
	g.y = Game.ground_height(at.x, at.z)
	pup.global_position = g
	pup.rotation.y = atan2(d.x, d.z)
	pup.scale = Vector3.ONE * 0.6
	pup.create_tween().tween_property(pup, "scale", Vector3.ONE, 0.12)
	pj._chakra_strings(who, [pup], dur)
	who.get_tree().create_timer(dur).timeout.connect(func():
		if is_instance_valid(pup):
			var tw = pup.create_tween()
			tw.tween_property(pup, "scale", Vector3.ONE * 0.05, 0.15)
			tw.tween_callback(pup.queue_free))
	return pup


## Kukla atılışı: gerçek savaş kuklası (iplikli) belirir, hedefe atılıp keser, yerine döner
static func _puppet_lunge(who: Node3D, pj, from: Vector3, to: Vector3, dmg: float, extra: Dictionary) -> void:
	var dirv = to - from
	dirv.y = 0
	var pup: Node3D = _style_puppet(who, pj, from, dirv.normalized() if dirv.length() > 0.01 else Vector3.FORWARD, 0.9)
	var mid = to - dirv.normalized() * 0.9 if dirv.length() > 0.01 else to
	mid.y = Game.ground_height(mid.x, mid.z)
	var back = pup.global_position
	var tw = pup.create_tween()
	tw.tween_property(pup, "global_position", mid, 0.16)
	tw.tween_callback(func():
		if is_instance_valid(who):
			var inf = _kinfo(dmg, 1.0, {"element": "", "knock": 5.0, "kind": "heavy"})
			inf.merge(extra, true)
			Combat.hit_sphere(who, to + Vector3.UP, 1.3, inf)
			FX.hit_spark(to + Vector3.UP, Color(0.95, 0.9, 0.8), 0.8))
	tw.tween_interval(0.12)
	tw.tween_property(pup, "global_position", back, 0.2)


## Kil figür (ClayArt) fırlatılır: arc yüksekliğiyle uçar, varınca VFX.clay_blast + hasar
static func _clay_fly(who: Node3D, kind: String, from: Vector3, to: Vector3, s: float, dur: float, arc: float, dmg: float, blast: float) -> void:
	var fig: Node3D = ClayArt.bird(s) if kind == "bird" else (ClayArt.spider(s) if kind == "spider" else ClayArt.doll(s))
	who.get_tree().current_scene.add_child(fig)
	fig.global_position = from
	var tw = fig.create_tween()
	tw.tween_method(func(u: float):
		if is_instance_valid(fig):
			var p = from.lerp(to, u) + Vector3.UP * sin(u * PI) * arc
			var nx = from.lerp(to, minf(1.0, u + 0.05)) + Vector3.UP * sin(minf(1.0, u + 0.05) * PI) * arc
			fig.global_position = p
			if nx.distance_to(p) > 0.01:
				fig.look_at(nx, Vector3.UP), 0.0, 1.0, dur)
	tw.tween_callback(func():
		VFX.clay_blast(to, blast)
		if is_instance_valid(who):
			Combat.hit_sphere(who, to, 1.2 + blast, _kinfo(dmg, 1.0, {"element": "doton", "knock": 5.0, "kind": "heavy"})))
	tw.tween_callback(fig.queue_free)


## Efektsiz yer değiştirme (sis/duman tarzları kendi efektini koyar): hedefin yanına geç, hedefe dön
static func _blink_plain(who: Node3D, tg: Node3D, off: Vector3) -> void:
	var to = tg.global_position + off
	to.y = Game.ground_height(to.x, to.z)
	who.global_position = to
	if who is CharacterBody3D:
		who.velocity = Vector3.ZERO
	var d = tg.global_position - to
	d.y = 0
	if d.length() > 0.01 and "facing" in who:
		who.facing = atan2(-d.x, -d.z)


static func _blink(who: Node3D, tg: Node3D, off: Vector3) -> void:
	var yel = Color(1.0, 0.88, 0.3)
	var from = who.global_position + Vector3.UP
	VFX.star(from, yel, 2.4, 0.12)
	FX.burst(from, {"amount": 14, "life": 0.3, "tex": FX.tex_spark, "size": 0.5, "vmin": 3, "vmax": 8, "colors": [Color(1, 1, 0.8, 1), Color(1, 0.8, 0.2, 0)]})
	var to = tg.global_position + off
	to.y = Game.ground_height(to.x, to.z)
	who.global_position = to
	if who is CharacterBody3D:
		who.velocity = Vector3.ZERO
	var d = tg.global_position - to
	d.y = 0
	if d.length() > 0.01:
		var yaw = atan2(-d.x, -d.z)
		if who is Player:
			who.facing = yaw
		elif "facing" in who:
			who.facing = yaw
	VFX.star(to + Vector3.UP, yel, 2.8, 0.14)
	FX.burst(to + Vector3.UP, {"amount": 18, "life": 0.35, "tex": FX.tex_spark, "size": 0.55, "vmin": 2, "vmax": 7, "colors": [Color(1, 1, 0.85, 1), Color(1, 0.75, 0.15, 0)]})
	Sfx.play("whoosh", to, 1.6, 0.6)


# ------------------------------------------------------------------ Hōmatsu Kiseru (kabarcık borusu)
## Kabarcıklar borunun çanından çıkar ve hedefe süzülür. Oyuncu ve düşman aynı (suiton).
static func _kiseru_bell(who: Node3D) -> Vector3:
	var n = _weapon_node(who)
	if n == null:
		return who.global_position + Vector3.UP * 1.3
	return n.to_global(Vector3(0, 0, 0.74))


## Tek kabarcık uçuşu: çandan, hafif yükselip dalgalanarak hedef noktaya (fn: anlık hedef) süzülür; varınca arrive(pos) çağrılır
static func _bub_fly(who: Node3D, size: float, dur: float, fn: Callable, arrive: Callable, delay := 0.0, arc := 0.6) -> void:
	var go = func():
		if not is_instance_valid(who):
			return
		var from = _kiseru_bell(who)
		var b = VFX.soap_bubble(size)
		who.get_tree().current_scene.add_child(b)
		b.global_position = from
		var ph = randf() * TAU
		var tw = b.create_tween()
		tw.tween_method(func(k: float):
			if not is_instance_valid(b):
				return
			var to: Vector3 = fn.call()
			var p = from.lerp(to, k) + Vector3.UP * sin(k * PI) * arc + Vector3(sin(k * 9.0 + ph), cos(k * 7.0 + ph) * 0.5, cos(k * 8.0 + ph)) * 0.08 * size
			b.global_position = p
			b.scale = Vector3.ONE * size * (0.35 + 0.65 * minf(1.0, k * 4.0)), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func():
			if is_instance_valid(b):
				var p = b.global_position
				b.queue_free()
				arrive.call(p))
	if delay <= 0.0:
		go.call()
	else:
		who.get_tree().create_timer(delay).timeout.connect(go)


static func _bub_pop(p: Vector3, s: float) -> void:
	VFX.bubble_pop(p, clampf(s * 0.4, 0.12, 2.4))   # doğal köpük patlaması (duman/toz yok)


static func _kiseru_strike(who: Node3D, i: int, dmg: float) -> void:
	var tg = _hira_target(who)
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else -who.global_transform.basis.z
	var aim_fn = _kiseru_aim.bind(who, tg, f)
	match i:
		0:   # Köpük Akışı: 10 küçük kabarcık art arda; her biri hedefte patlar (küçük hasar)
			for k in 10:
				var sz = randf_range(0.12, 0.3)
				var jit = Vector3(randf_range(-0.6, 0.6), randf_range(-0.3, 0.5), randf_range(-0.6, 0.6))
				_bub_fly(who, sz, randf_range(0.55, 0.8), _kiseru_aim_off.bind(who, tg, f, jit), _arrive_small.bind(who, sz, dmg), k * 0.04, 0.3)
		1:   # Patlayan Köpük: kocaman kabarcık yavaş süzülür, hedefte patlar (sert)
			_bub_fly(who, 0.85, 1.1, aim_fn, _arrive_big.bind(who, dmg), 0.0, 0.4)
		2:   # Boru Darbesi: çan çarpınca kabarcık püskürür
			var bp = _kiseru_bell(who)
			for k in 6:
				var b = VFX.soap_bubble(randf_range(0.1, 0.25))
				who.get_tree().current_scene.add_child(b)
				b.global_position = bp
				var to = bp + Vector3(randf_range(-1, 1), randf_range(0.2, 1.2), randf_range(-1, 1))
				var tw = b.create_tween()
				tw.tween_property(b, "global_position", to, randf_range(0.5, 0.9)).set_ease(Tween.EASE_OUT)
				tw.tween_callback(_pop_free.bind(b, 0.5))
		3:   # Köpük Kafesi: dev kabarcık hedefe süzülür, içine alır ve hapseder (sersemletme), sonra patlar
			_bub_fly(who, 0.6, 0.8, aim_fn, _arrive_cage.bind(who, tg, dmg), 0.0, 0.3)
		4:   # Asit Yağmuru: kabarcıklar yukarı yay çizip hedefin çevresine düşer, aşındırır (yavaşlatma + hasar)
			for k in 8:
				var off = Vector3(randf_range(-1.6, 1.6), -0.6, randf_range(-1.6, 1.6))
				var sz = randf_range(0.25, 0.5)
				_bub_fly(who, sz, randf_range(0.9, 1.2), _kiseru_aim_off.bind(who, tg, f, off), _arrive_acid.bind(who, sz, dmg), k * 0.06, 2.2)
		5:   # Köpük Seli: 22 kabarcık hedefin çevresine dolar, sonra zincirleme patlar
			var bubs: Array = []
			for k in 22:
				var sz = [0.15, 0.25, 0.35, 0.5, 0.7][k % 5]
				var a = TAU * k / 22.0
				var ring = Vector3(cos(a), randf_range(-0.3, 0.9), sin(a)) * randf_range(0.8, 1.8)
				_bub_fly(who, sz, randf_range(0.7, 1.0), _kiseru_aim_off.bind(who, tg, f, ring), _arrive_park.bind(who, sz, bubs), k * 0.035, 0.4)
			who.get_tree().create_timer(1.75).timeout.connect(_chain_pop.bind(who, bubs, dmg))


static func _kiseru_aim(who: Node3D, tg: Node3D, f: Vector3) -> Vector3:
	if tg != null and is_instance_valid(tg):
		return tg.global_position + Vector3.UP * 1.0
	if is_instance_valid(who):
		return who.global_position + f * 8.0 + Vector3.UP * 1.2
	return Vector3.ZERO


static func _kiseru_aim_off(who: Node3D, tg: Node3D, f: Vector3, off: Vector3) -> Vector3:
	return _kiseru_aim(who, tg, f) + off


static func _kinfo(dmg: float, mul: float, extra := {}) -> Dictionary:
	var d = {"dmg": dmg * mul, "element": "suiton", "knock": 3.0, "kind": "light", "hitstop": 0.02}
	d.merge(extra, true)
	return d


static func _pop_free(b: Node3D, s: float) -> void:
	if is_instance_valid(b):
		_bub_pop(b.global_position, s)
		b.queue_free()


static func _arrive_small(p: Vector3, who: Node3D, sz: float, dmg: float) -> void:
	_bub_pop(p, sz * 2.0)
	if is_instance_valid(who):
		Combat.hit_sphere(who, p, 0.7, _kinfo(dmg, 0.4, {"knock": 1.0}))


static func _arrive_big(p: Vector3, who: Node3D, dmg: float) -> void:
	_bub_pop(p, 2.2)
	if is_instance_valid(who):
		Combat.hit_sphere(who, p, 2.0, _kinfo(dmg, 2.4, {"knock": 9.0, "launch": 3.0, "kind": "heavy"}))
		_shake(who, 0.4)


static func _arrive_cage(p: Vector3, who: Node3D, tg: Node3D, dmg: float) -> void:
	if not is_instance_valid(who):
		return
	if tg == null or not is_instance_valid(tg):
		_bub_pop(p, 1.5)
		return
	var cage = VFX.soap_bubble(2.4)
	who.get_tree().current_scene.add_child(cage)
	cage.global_position = tg.global_position + Vector3.UP * 0.95
	if tg.has_method("apply_status"):
		tg.apply_status("stun", 1.6)
		tg.apply_status("wet", 6.0)
	Combat.hit_sphere(who, cage.global_position, 1.0, _kinfo(dmg, 1.0, {"knock": 0.0, "stun": 1.6}))
	var tw = cage.create_tween()
	tw.tween_method(_cage_follow.bind(cage, tg), 0.0, 1.0, 1.6)
	tw.tween_callback(_pop_free.bind(cage, 3.0))


static func _cage_follow(k: float, cage: Node3D, tg: Node3D) -> void:
	if is_instance_valid(cage) and is_instance_valid(tg):
		cage.global_position = tg.global_position + Vector3.UP * 0.95
		cage.scale = Vector3.ONE * 2.4 * (1.0 + sin(k * 18.0) * 0.02)


static func _arrive_acid(p: Vector3, who: Node3D, sz: float, dmg: float) -> void:
	_bub_pop(p, sz * 2.5)
	FX.burst(p, {"amount": 6, "life": 0.5, "tex": FX.tex_spark, "add": false, "size": 0.06, "vmin": 0.5, "vmax": 1.5, "gravity": Vector3(0, -9, 0),
		"colors": [Color(0.8, 1.0, 0.55, 0.9), Color(0.65, 0.9, 0.4, 0)]})   # aşındırıcı damlacıklar
	if is_instance_valid(who):
		for h in Combat.hit_sphere(who, p, 1.1, _kinfo(dmg, 0.6, {"knock": 0.5})):
			if h.has_method("apply_status"):
				h.apply_status("slow", 3.0)


static func _arrive_park(p: Vector3, who: Node3D, sz: float, bubs: Array) -> void:
	if not is_instance_valid(who):
		return
	var b = VFX.soap_bubble(sz)
	who.get_tree().current_scene.add_child(b)
	b.global_position = p
	bubs.append(b)


static func _chain_pop(who: Node3D, bubs: Array, dmg: float) -> void:
	if not is_instance_valid(who):
		for b in bubs:
			if is_instance_valid(b):
				b.queue_free()
		return
	var idx = 0
	for b in bubs:
		who.get_tree().create_timer(idx * 0.04).timeout.connect(_chain_one.bind(who, b, dmg))
		idx += 1
	_shake(who, 0.6)


static func _chain_one(who: Node3D, b: Node3D, dmg: float) -> void:
	if not is_instance_valid(b):
		return
	var p = b.global_position
	b.queue_free()
	_bub_pop(p, 1.6)
	if is_instance_valid(who):
		Combat.hit_sphere(who, p, 1.0, _kinfo(dmg, 0.45, {"knock": 4.0}))


# ------------------------------------------------------------------ Kusanagi
## Chōtō: ağız bir anda L metre uzar, kısa tutup geri kısalır (uzantı düğümü KusaExt)
static func _kusa_extend(who: Node3D, L: float, hold: float) -> void:
	var n = _weapon_node(who)
	if n == null:
		return
	var ext = n.get_node_or_null("KusaExt")
	if ext == null:
		return
	ext.visible = true
	ext.scale = Vector3(1, 1, 0.01)
	var tw = ext.create_tween()
	tw.tween_property(ext, "scale", Vector3(1, 1, L / maxf(0.01, n.scale.z)), 0.06).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_property(ext, "scale", Vector3(1, 1, 0.01), 0.12)
	tw.tween_callback(func():
		if is_instance_valid(ext):
			ext.visible = false)
	FX.hit_spark(n.to_global(Vector3(0, 0, 1.0)), Color(0.85, 0.9, 1.0), 0.8)


## Uçan Kusanagi: kılıç elden fırlar, hedefe uçup saplanır, çevresinde bir tur atıp tekrar saplar, ele döner (uzaktan yönetim)
static func _kusa_fly(who: Node3D, dmg: float) -> void:
	var n = _weapon_node(who)
	if n == null:
		return
	var tg = _hira_target(who)
	var copy = MeshInstance3D.new()
	copy.mesh = CharacterModel.weapon_mesh("kusanagi")
	who.get_tree().current_scene.add_child(copy)
	copy.global_transform = n.global_transform
	n.visible = false
	var start: Vector3 = n.global_position
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	var center: Vector3 = (tg.global_position + Vector3.UP) if tg != null else start + f * 7.0
	var hits = [0.35, 0.62]
	var tw = copy.create_tween()
	tw.tween_method(func(k: float):
		if not is_instance_valid(copy):
			return
		var c = (tg.global_position + Vector3.UP) if tg != null and is_instance_valid(tg) else center
		var p: Vector3
		var look: Vector3
		if k < 0.35:   # hedefe uç
			p = start.lerp(c, k / 0.35)
			look = c
		elif k < 0.62:   # çevresinde tur
			var a = (k - 0.35) / 0.27 * TAU
			p = c + Vector3(cos(a), 0.2, sin(a)) * 1.2
			look = c
		else:   # ele dön
			var hand = n.global_position if is_instance_valid(n) else start
			p = c.lerp(hand, (k - 0.62) / 0.38)
			look = p + (p - c)
		var d = (look - p)
		copy.global_position = p
		if d.length() > 0.01:
			copy.look_at(p - d.normalized(), Vector3.UP)   # silah +Z ileri: look_at -Z'yi hedefe çevirir
		, 0.0, 1.0, 0.75)
	tw.tween_callback(func():
		if is_instance_valid(copy):
			copy.queue_free()
		if is_instance_valid(n):
			n.visible = true)
	for t in hits:
		who.get_tree().create_timer(t * 0.75).timeout.connect(func():
			if is_instance_valid(who) and is_instance_valid(copy):
				FX.hit_spark(copy.global_position, Color(0.8, 0.9, 1.0), 1.0)
				Combat.hit_sphere(who, copy.global_position, 1.2, {"dmg": dmg * 0.7, "knock": 3.0, "kind": "light", "hitstop": 0.03, "melee": true}))
	Sfx.play("whoosh", start, 1.3, 0.6)


# ------------------------------------------------------------------ Kusarigama (Hanzō tipi, sickle.png)
## Zincir CharacterModel'de fizikli (kchain_*): burada yalnız uç noktası (ağırlık / uçan orak) bir işaretçiye tutturulup yol çizdirilir.
static func _kg_model(who) -> Object:
	if who == null or not is_instance_valid(who):
		return null
	var m = who.get("model")
	if m == null or not is_instance_valid(m) or not ("kchain_pin" in m):
		return null
	return m


static func _kg_face(who) -> Vector3:
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else -who.global_transform.basis.z
	f.y = 0
	return f.normalized() if f.length() > 0.01 else Vector3.FORWARD


## Hedef noktası: 9 m içindeki düşmanın göğsü, yoksa önde 6.5 m
static func _kg_aim(who, tg, f: Vector3) -> Vector3:
	if tg != null and is_instance_valid(tg) and tg.global_position.distance_to(who.global_position) < 9.0:
		return tg.global_position + Vector3.UP * 1.0
	return who.global_position + Vector3.UP * 1.1 + f * 6.5


## Ağırlık zincirle: "straight" düz fırlatma, "whirl" baş üstünde döndürüp geniş çember, "wrap" hedefe dolanır (bitiriş)
static func _kg_weight(who: Node3D, dmg: float, mode: String) -> void:
	var m = _kg_model(who)
	if m == null:
		return
	var tg = _hira_target(who)
	var f = _kg_face(who)
	var mk = Node3D.new()
	who.get_tree().current_scene.add_child(mk)
	var start: Vector3 = m.kchain_tip()
	mk.global_position = start
	m.kchain_pin = Callable(mk, "get_global_position")
	var dur = {"straight": 1.05, "whirl": 1.0, "wrap": 0.85}[mode]
	var tw = mk.create_tween()
	tw.tween_method(_kg_path.bind(mk, who, tg, f, mode, start), 0.0, 1.0, dur)
	tw.tween_callback(_kg_release.bind(who, mk))
	Sfx.play("whoosh", who.global_position, 1.2, 0.6)
	match mode:
		"straight":
			# ağırlık hedefe çarpar, zincir gövdesine dolanır: sersemletir (dolanma süresince), sonra çözülüp döner
			who.get_tree().create_timer(dur * 0.24).timeout.connect(_kg_hit.bind(who, mk, 1.1, dmg * 0.9, {"knock": 0.5, "stun": 1.3, "kind": "light", "hitstop": 0.06}))
		"whirl":
			for k in 5:
				who.get_tree().create_timer(dur * (0.42 + k * 0.1)).timeout.connect(_kg_hit.bind(who, mk, 1.4, dmg * 0.4, {"knock": 6.0, "kind": "light", "hitstop": 0.02}))
		"wrap":
			who.get_tree().create_timer(dur * 0.32).timeout.connect(_kg_bind.bind(who, tg))


static func _kg_home(who) -> Vector3:
	var n = _weapon_node(who)
	if n != null:
		return n.to_global(Vector3(0, 0, -0.39)) + Vector3.DOWN * 0.55
	return who.global_position + Vector3.UP * 0.6


static func _kg_path(u: float, mk, who, tg, f: Vector3, mode: String, start: Vector3) -> void:
	if not is_instance_valid(mk) or not is_instance_valid(who):
		return
	var aim = _kg_aim(who, tg, f)
	var home = _kg_home(who)
	var p: Vector3
	match mode:
		"straight":   # 0..0.24 düz uçuş, 0.24..0.74 hedefin gövdesine dolanır (sarar), sonra çözülüp sarkarak geri
			var c2 = aim if tg == null or not is_instance_valid(tg) or tg.global_position.distance_to(who.global_position) > 9.0 else tg.global_position + Vector3.UP * 1.0
			if u < 0.24:
				var k = u / 0.24
				p = start.lerp(c2, 1.0 - (1.0 - k) * (1.0 - k)) + Vector3.UP * sin(k * PI) * 0.25
			elif u < 0.74:
				var a = (u - 0.24) / 0.5 * TAU * 3.5
				var r = 0.45 if c2 != aim or tg != null else 0.0
				p = c2 + Vector3(cos(a), (u - 0.24) * 0.5 - 0.12, sin(a)) * Vector3(r, 1.0, r)
			else:
				var k = (u - 0.74) / 0.26
				p = c2.lerp(home, k * k) + Vector3.DOWN * sin(k * PI) * 0.6
		"whirl":   # baş üstünde iki tur küçük çember -> genişleyip gövdenin çevresinde bel hizasında geniş çember -> geri
			var c = who.global_position
			var a = u * TAU * 3.2
			if u < 0.35:
				p = c + Vector3.UP * 2.35 + f * 0.15 + Vector3(cos(a), 0, sin(a)) * 0.9
			elif u < 0.9:
				var k = clampf((u - 0.35) / 0.15, 0.0, 1.0)
				var r = lerpf(0.9, 3.4, k)
				p = c + Vector3.UP * lerpf(2.35, 1.0, k) + Vector3(cos(a), 0, sin(a)) * r
			else:
				var k = (u - 0.9) / 0.1
				var q = c + Vector3.UP * 1.0 + Vector3(cos(a), 0, sin(a)) * 3.4
				p = q.lerp(home, k)
		_:   # wrap: hedefe uçar, göğsünün çevresinde dolanır
			if u < 0.3:
				var k = u / 0.3
				p = start.lerp(aim, k) + Vector3.UP * sin(k * PI) * 0.4
			else:
				var a = (u - 0.3) / 0.7 * TAU * 3.0
				var c2 = aim if tg == null or not is_instance_valid(tg) else tg.global_position + Vector3.UP * 1.05
				p = c2 + Vector3(cos(a), sin(a * 0.5) * 0.12, sin(a)) * 0.45
	mk.global_position = p


static func _kg_hit(who, mk, r: float, dmg: float, extra: Dictionary) -> void:
	if not is_instance_valid(who) or not is_instance_valid(mk):
		return
	var info = {"dmg": dmg, "knock": 3.0, "kind": "light", "hitstop": 0.03, "melee": true}
	info.merge(extra, true)
	var hs = Combat.hit_sphere(who, mk.global_position, r, info)
	if not hs.is_empty():
		FX.hit_spark(mk.global_position, Color(0.85, 0.85, 0.95), 1.1)
		Sfx.play("hit_heavy_weapon", mk.global_position, 1.1, 0.7)


static func _kg_release(who, mk) -> void:
	var m = _kg_model(who)
	if m != null:
		m.kchain_pin = Callable()
	if is_instance_valid(mk):
		mk.queue_free()


## Bitiriş: zincir hedefe dolandı — sersemler ve kullanıcıya doğru sürüklenir
static func _kg_bind(who, tg) -> void:
	if not is_instance_valid(who) or tg == null or not is_instance_valid(tg):
		return
	if tg.has_method("apply_status"):
		tg.apply_status("stun", 1.1)
	FX.hit_spark(tg.global_position + Vector3.UP, Color(0.8, 0.8, 0.9), 1.2)
	if tg is CharacterBody3D:
		var d = who.global_position - tg.global_position
		d.y = 0
		var L = d.length()
		if L > 2.0:
			tg.velocity = d.normalized() * minf(18.0, (L - 1.5) * 3.6) + Vector3.UP * 1.0


## Kama Nage: orak elden fırlar (zincir elde), dönerek hedefin arkasına kancalanır, zincirle geri çekilir (rakip sürüklenir), ele döner
static func _kg_sickle(who: Node3D, dmg: float) -> void:
	var n = _weapon_node(who)
	var m = _kg_model(who)
	if n == null or m == null:
		return
	var tg = _hira_target(who)
	var f = _kg_face(who)
	var copy = MeshInstance3D.new()
	copy.mesh = CharacterModel.weapon_mesh("kusarigama")
	who.get_tree().current_scene.add_child(copy)
	copy.global_transform = n.global_transform
	var butt = Node3D.new()
	copy.add_child(butt)
	butt.position = Vector3(0, 0, -0.39)
	n.visible = false
	m.kchain_start = Callable(n.get_parent(), "get_global_position")
	m.kchain_pin = Callable(butt, "get_global_position")
	m.kchain_hide_weight = true
	var tw = copy.create_tween()
	tw.tween_method(_kg_sickle_path.bind(copy, who, tg, f, copy.global_position), 0.0, 1.0, 0.78)
	tw.tween_callback(_kg_sickle_end.bind(who, copy))
	who.get_tree().create_timer(0.78 * 0.36).timeout.connect(_kg_hook.bind(who, copy, dmg))
	Sfx.play("whoosh", who.global_position, 1.0, 0.7)


static func _kg_sickle_path(u: float, copy, who, tg, f: Vector3, start: Vector3) -> void:
	if not is_instance_valid(copy) or not is_instance_valid(who):
		return
	var aim = _kg_aim(who, tg, f)
	var d = aim - start
	d.y = 0
	var dir = d.normalized() if d.length() > 0.1 else f
	var side = dir.cross(Vector3.UP).normalized()
	var hook = aim + dir * 0.55
	var hand = _weapon_node(who)
	var back_to: Vector3 = hand.get_parent().global_position if hand != null else who.global_position + Vector3.UP
	var p: Vector3
	var spin := 0.0
	if u < 0.36:   # dönerek uçar
		var k = u / 0.36
		p = start.lerp(hook, k) + Vector3.UP * sin(k * PI) * 0.7
		spin = k * TAU * 2.0
	elif u < 0.5:   # kancalı: orak hedefin arkasında, sap kullanıcıya bakar
		p = hook if tg == null or not is_instance_valid(tg) else tg.global_position + Vector3.UP * 1.0 + dir * 0.55
		spin = 0.0
	else:   # zincirle geri çekilir
		var k = (u - 0.5) / 0.5
		var from = hook if tg == null or not is_instance_valid(tg) else tg.global_position + Vector3.UP * 1.0 + dir * 0.55
		p = from.lerp(back_to, k * k)
		spin = -k * TAU * 1.5
	var base = Basis.looking_at(-dir, Vector3.UP)   # silah +Z ileri (sap dibi geride)
	if u >= 0.36 and u < 0.5:
		base = Basis.looking_at(dir, Vector3.UP)   # kanca: sap dibi kullanıcıya, orak hedefin arkasından geri bakar
	copy.global_transform = Transform3D(Basis(side, spin) * base, p)


static func _kg_hook(who, copy, dmg: float) -> void:
	if not is_instance_valid(who) or not is_instance_valid(copy):
		return
	var q: Vector3 = copy.global_position
	var hs = Combat.hit_sphere(who, q, 1.4, {"dmg": dmg * 1.1, "knock": 0.0, "stun": 0.8, "kind": "light", "hitstop": 0.06, "melee": true})
	FX.hit_spark(q, Color(0.9, 0.9, 1.0), 1.3)
	Sfx.play("hit_heavy_weapon", q, 0.95, 0.8)
	for h in hs:
		who.get_tree().create_timer(0.1).timeout.connect(_kg_drag.bind(who, h))


static func _kg_drag(who, h) -> void:
	if not is_instance_valid(who) or not is_instance_valid(h) or not (h is CharacterBody3D):
		return
	var d = who.global_position - h.global_position
	d.y = 0
	var L = d.length()
	if L > 1.8:
		h.velocity = d.normalized() * minf(20.0, (L - 1.4) * 3.4) + Vector3.UP * 3.0


static func _kg_sickle_end(who, copy) -> void:
	if is_instance_valid(copy):
		copy.queue_free()
	var m = _kg_model(who)
	if m != null:
		m.kchain_start = Callable()
		m.kchain_pin = Callable()
		m.kchain_hide_weight = false
	var n = _weapon_node(who) if is_instance_valid(who) else null
	if n != null:
		n.visible = true


## ------------------------------------------------------------------ uzun menzil atılan shurikenler (Fūma / Kyodai / Kuchiyose)
## Hedef: en yakın düşman (24 m), yoksa ileri. Uçan kopya kendi ekseninde döner; yol boyunca küreyle vurur (her geçişte hedef başına bir kez).
static func _throw_target(who: Node3D, rng := 24.0) -> Node3D:
	var best: Node3D = null
	var bd = rng
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else -who.global_transform.basis.z
	for fi in who.get_tree().get_nodes_in_group("fighters"):
		if fi == who or not Combat.hostile(who, fi) or fi.is_dead():
			continue
		var dv = fi.global_position - who.global_position
		var d = dv.length()
		if d < 0.5:
			continue
		var score = d * (1.6 - 0.6 * f.dot(dv / d))   # önündekiler öncelikli
		if score < bd:
			bd = score
			best = fi
	return best


## mode: straight / arc / down / circle / roll / boomerang / shadow(gecikmeli ikinci)
## opts: mesh, hold (eldeki silah uçarken gizlensin), radius, dur, spin (tur/sn), return (ele dön), delay, side, scale, knock
static func _spin_throw(who: Node3D, dmg: float, mode: String, opts := {}) -> void:
	if who == null or not is_instance_valid(who):
		return
	var n = _weapon_node(who) if opts.get("hold", true) else null
	var tg = _throw_target(who, float(opts.get("range", 24.0)))
	var copy = MeshInstance3D.new()
	copy.mesh = CharacterModel.weapon_mesh(String(opts.get("mesh", "fuma_shuriken")))
	who.get_tree().current_scene.add_child(copy)
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	f.y = 0
	f = f.normalized()
	var side = Vector3.UP.cross(f).normalized() * float(opts.get("side", 1.0))
	var start: Vector3 = n.global_position if n != null else who.global_position + Vector3.UP * 1.3 + f * 0.6
	copy.global_position = start
	var sc = float(opts.get("scale", 1.0))
	if n != null and opts.get("hide_held", true):
		n.visible = false
	var aim: Vector3 = (tg.global_position + Vector3.UP * 1.0) if tg != null else start + f * 16.0
	var dist = start.distance_to(aim)
	var dur = float(opts.get("dur", clampf(dist / 16.0, 0.6, 1.5) * (2.0 if opts.get("return", true) else 1.0)))
	var R = float(opts.get("radius", 1.0))
	var spin = float(opts.get("spin", 3.0))
	var hit_t = {}
	var info = {"dmg": dmg, "knock": float(opts.get("knock", 4.0)), "kind": "light", "hitstop": 0.04, "melee": false, "element": "wind" if opts.get("wind", false) else ""}
	var t0 = Time.get_ticks_msec() / 1000.0
	var vertical = mode == "roll"
	var orient_path = opts.get("orient", "") == "path"   # iğne: uç gidiş yönüne bakar (dönmez)
	var last_p = [start]
	var pierced: Array = []
	var wire_mi: MeshInstance3D = null
	if opts.get("wire", false):
		wire_mi = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.004
		cm.bottom_radius = 0.004
		cm.height = 1.0
		cm.radial_segments = 4
		wire_mi.mesh = cm
		wire_mi.material_override = Props.toon_color(Color(0.85, 0.87, 0.92), 0.2)
		who.get_tree().current_scene.add_child(wire_mi)
	var tw = copy.create_tween()
	if float(opts.get("delay", 0.0)) > 0.0:
		copy.visible = false
		tw.tween_interval(float(opts["delay"]))
		tw.tween_callback(func(): if is_instance_valid(copy): copy.visible = true)
	tw.tween_method(func(k: float):
		if not is_instance_valid(copy) or not is_instance_valid(who):
			return
		var c = (tg.global_position + Vector3.UP * 1.0) if tg != null and is_instance_valid(tg) and not tg.is_dead() else aim
		var hand = n.global_position if n != null and is_instance_valid(n) else who.global_position + Vector3.UP * 1.3
		var p: Vector3
		var ret = opts.get("return", true)
		var ko = 0.5 if ret else 1.0
		if not ret:
			k = minf(k, 0.9999)   # dönmeyen uçuş: son karede (k - ko) / (1 - ko) = 0/0 olmasın
		match mode:
			"arc", "boomerang":
				var u = k / ko if k < ko else (k - ko) / (1.0 - ko)
				var mid = start.lerp(c, 0.5) + side * dist * 0.45
				if k < ko:
					p = start.lerp(mid, u).lerp(mid.lerp(c + f * 2.0, u), u)
				else:
					var mid2 = c.lerp(hand, 0.5) - side * dist * 0.45
					p = (c + f * 2.0).lerp(mid2, u).lerp(mid2.lerp(hand, u), u)
			"down":
				var top = c + Vector3.UP * 7.0 - f * 2.0
				if k < 0.45:
					var u = k / 0.45
					p = start.lerp(top, u).lerp(top.lerp(c, u), u)
				elif ret:
					p = c.lerp(hand, (k - 0.45) / 0.55)
				else:
					p = c
			"circle":
				if k < 0.3:
					p = start.lerp(c, k / 0.3)
				elif k < 0.8:
					var a = (k - 0.3) / 0.5 * TAU * float(opts.get("turns", 3.0))
					p = c + Vector3(cos(a), 0.15 * sin(a * 2.0), sin(a)) * float(opts.get("orbit", 1.5))
				elif ret:
					p = c.lerp(hand, (k - 0.8) / 0.2)
				else:
					p = c   # kafes: içeri çöker
			"orbit_self":
				var a = k * TAU * float(opts.get("turns", 2.0))
				var rr = float(opts.get("orbit", 3.0)) * sin(PI * clampf(k * 1.15, 0.0, 1.0))
				var wf = who.global_position + Vector3.UP * 1.1
				p = wf + Vector3(cos(a), 0, sin(a)) * rr
			"roll":
				var g0 = Vector3(start.x, Game.ground_height(start.x, start.z) + R * sc * 0.9, start.z)
				var far = c + (c - start).normalized() * 4.0
				var g1 = Vector3(far.x, Game.ground_height(far.x, far.z) + R * sc * 0.9, far.z)
				if k < ko:
					p = g0.lerp(g1, k / ko)
					p.y = Game.ground_height(p.x, p.z) + R * sc * 0.9
				else:
					p = g1.lerp(hand, (k - ko) / (1.0 - ko))
			_:
				if k < ko:
					p = start.lerp(c + (c - start).normalized() * 1.5, k / ko)
				else:
					p = (c + (c - start).normalized() * 1.5).lerp(hand, (k - ko) / (1.0 - ko))
		if not p.is_finite():
			return
		copy.global_position = p
		var tnow = Time.get_ticks_msec() / 1000.0 - t0
		var ang = tnow * spin * TAU
		if wire_mi != null:
			var dv = p - hand
			if dv.length() > 0.05:
				wire_mi.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, dv.normalized())) * Basis.from_scale(Vector3(1, dv.length(), 1)), (p + hand) * 0.5)
		if opts.get("stitch", false) and k > ko:
			# dikiş: delinenler telle iğneye bağlı, dönüşte birbirine dikilip sürüklenir
			for pj in pierced:
				if is_instance_valid(pj) and not pj.is_dead():
					var to = p - Vector3.UP * 0.9 - pj.global_position
					if to.length() > 0.8:
						pj.global_position += to * 0.18
		if orient_path:
			var mv = p - last_p[0]
			if mv.length() > 0.001:
				copy.global_transform = Transform3D(Basis.looking_at(-mv.normalized(), Vector3.UP if absf(mv.normalized().y) < 0.95 else Vector3.RIGHT), p)
			last_p[0] = p
		elif vertical:
			var dirv = (c - start); dirv.y = 0
			copy.global_transform.basis = Basis.looking_at(dirv.normalized() if dirv.length() > 0.1 else f, Vector3.UP).rotated(Vector3.UP, PI * 0.5) * Basis(Vector3(0, 0, 1), ang)
			copy.global_transform.basis = copy.global_transform.basis.scaled(Vector3.ONE * sc)
		else:
			# yassı yüz yere paralel (XY düzlemli model): X ekseni etrafında 90° yatır, Y'de döndür
			copy.global_transform.basis = (Basis(Vector3.UP, ang) * Basis(Vector3.RIGHT, PI * 0.5)).scaled(Vector3.ONE * sc)
		# yol boyunca vuruş (her hedefe 0.3 sn'de bir)
		for fi in who.get_tree().get_nodes_in_group("fighters"):
			if fi == who or not Combat.hostile(who, fi) or fi.is_dead():
				continue
			if fi.global_position.distance_to(p - Vector3.UP * 0.9) < R * sc * 0.8 + 0.5:
				var id = fi.get_instance_id()
				if tnow - float(hit_t.get(id, -9.0)) > 0.3:
					hit_t[id] = tnow
					var inf = info.duplicate()
					inf["attacker"] = who
					fi.take_hit(inf)
					if not fi in pierced:
						pierced.append(fi)
						if float(opts.get("bind", 0.0)) > 0.0 and fi.has_method("apply_status"):
							fi.apply_status("bind", float(opts["bind"]))
					FX.hit_spark(p, Color(0.85, 0.9, 1.0), 1.0)
		, 0.0, 1.0, dur)
	tw.tween_callback(func():
		if is_instance_valid(wire_mi):
			wire_mi.queue_free()
		if is_instance_valid(copy):
			if not opts.get("return", true):
				FX.smoke_puff(copy.global_position, 0.6, 8)
			copy.queue_free()
		if n != null and is_instance_valid(n) and opts.get("hide_held", true):
			n.visible = true)
	Sfx.play("whoosh", start, 0.8 if sc > 1.5 else 1.2, 0.5)


## Kuchiyose: parşömenden dumanla üç kare Fūma çıkar, düzenine göre uçar (dönmez, sonunda dumanla kaybolur)
static func _summon_three(who: Node3D, dmg: float, form: String) -> void:
	if who == null or not is_instance_valid(who):
		return
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	f.y = 0
	f = f.normalized()
	var side = Vector3.UP.cross(f).normalized()
	FX.smoke_puff(who.global_position + Vector3.UP * 1.3 + f * 1.4, 0.7, 10)
	for k in 3:
		var o = {"mesh": "fuma_kare", "hold": false, "hide_held": false, "return": false, "radius": 1.05, "spin": 2.4, "knock": 5.0, "scale": 1.8}   # büyük çağrı shurikenleri (1.8x)
		var s = float(k - 1)
		match form:
			"fan":
				o["side"] = s * 0.6
				_spin_throw(who, dmg * 0.55, "arc" if k != 1 else "straight", o)
			"orbit":
				o["delay"] = k * 0.08
				_spin_throw(who, dmg * 0.55, "circle", o.merged({"turns": 1.5, "orbit": 1.2, "return": false}))
			"rain":
				o["delay"] = k * 0.12
				_spin_throw(who, dmg * 0.6, "down", o)
			"line":
				o["delay"] = k * 0.14
				_spin_throw(who, dmg * 0.55, "straight", o)
			"pincer":
				o["side"] = -1.0 if k == 0 else 1.0
				if k == 1:
					o["delay"] = 0.2
				_spin_throw(who, dmg * 0.6, "arc" if k != 1 else "down", o)
			"cage":
				o["delay"] = k * 0.1
				_spin_throw(who, dmg * 0.5, "circle", o.merged({"turns": 2.5, "orbit": 1.8, "return": false, "dur": 1.6}))


## Elmas asa uzar: silah düğümü sap ekseninde (z) büyür, sonra eski boyuna döner
static func _staff_extend(who: Node3D, mult: float, dur: float) -> void:
	var n = _weapon_node(who)
	if n == null:
		return
	var s0: Vector3 = n.scale
	var tw = n.create_tween()
	tw.tween_property(n, "scale", Vector3(s0.x, s0.y, s0.z * mult), dur * 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(dur * 0.3)
	tw.tween_property(n, "scale", s0, dur * 0.4).set_trans(Tween.TRANS_SINE)
	Sfx.play("whoosh", who.global_position, 0.8, 0.5)


## Maymun Kral (Enma) asadan çıkar: asa elinden kaybolur, dumanla hedefin yanında (big: üstünde) belirir, yumruk(lar) atar,
## dumanla kaybolur, asa ele döner. Oyuncu ve düşman aynı.
static func _enma_cameo(who: Node3D, dmg: float, big: bool) -> void:
	var n = _weapon_node(who)
	var tg = _throw_target(who, 16.0)
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	f.y = 0
	f = f.normalized()
	var at: Vector3 = (tg.global_position - f * 1.6) if tg != null else who.global_position + f * 3.0
	at.y = tg.global_position.y if tg != null else who.global_position.y   # ground_height burada gerçek zeminden alçak dönebiliyor
	if n != null:
		n.visible = false
		FX.smoke_puff(n.global_position, 0.6, 8)
	var parts = SummonModels.build("monkey_king", 2.6 if big else 2.1, 1.0)
	var mk: Node3D = parts["root"]
	who.get_tree().current_scene.add_child(mk)
	var look_to = (tg.global_position if tg != null else at + f * 2.0)
	mk.global_position = at + (Vector3.UP * 3.0 if big else Vector3.ZERO)
	var d = look_to - at
	d.y = 0
	if d.length() > 0.01:
		mk.look_at(mk.global_position + d.normalized(), Vector3.UP)   # model önü -Z: hedefe dönük
	FX.smoke_puff(mk.global_position + Vector3.UP * 1.2, 0.7, 10)
	Sfx.play("summon", mk.global_position, 1.0, 0.6)
	var base = mk.global_position
	var fwd = d.normalized() if d.length() > 0.01 else f
	var tw = mk.create_tween()
	var hits = [0.32] if not big else [0.4, 0.75]
	if big:
		# yukarıdan iniş + iki yumruk
		tw.tween_property(mk, "global_position", at, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(mk, "global_position", at + fwd * 0.6, 0.12)
		tw.tween_property(mk, "global_position", at, 0.2)
		tw.tween_property(mk, "global_position", at + fwd * 0.7, 0.12)
		tw.tween_interval(0.35)
	else:
		# geri çekilip öne yumruk atılışı
		tw.tween_property(mk, "global_position", base - fwd * 0.3, 0.18)
		tw.tween_property(mk, "global_position", base + fwd * 0.9, 0.12).set_trans(Tween.TRANS_BACK)
		tw.tween_interval(0.4)
	tw.tween_callback(func():
		if is_instance_valid(mk):
			FX.smoke_puff(mk.global_position + Vector3.UP * 1.2, 0.7, 10)
			mk.queue_free()
		if n != null and is_instance_valid(n):
			n.visible = true
			FX.smoke_puff(n.global_position, 0.6, 8))
	for ht in hits:
		who.get_tree().create_timer(ht).timeout.connect(func():
			if not is_instance_valid(who) or not is_instance_valid(mk):
				return
			var p = mk.global_position + fwd * 1.2 + Vector3.UP * 1.0
			Combat.hit_sphere(who, p, 1.8 if not big else 2.6, {"dmg": dmg * (0.6 if big else 1.0), "knock": 14.0 if not big else 6.0, "launch": 0.0 if not big else 3.0, "kind": "heavy", "hitstop": 0.08, "melee": false})
			VFX.star(p, Color(1.0, 0.9, 0.6), 1.6, 0.14)
			_shake(who, 0.5)
			if big:
				var q = mk.global_position + fwd * 1.0
				q.y = at.y + 0.05
				VFX.cracks(q, 2.6)
				VFX.debris(q, Color(0.5, 0.45, 0.4), 10, 5.0, 0.3))


## Senbon atışları (Haku tarzı): adım başına farklı düzen; iğneler gerçek mermi (Projectile.tool), oyuncu ve düşman aynı
static func _senbon_volley(who: Node3D, dmg: float, i: int) -> void:
	var tg = _throw_target(who, 26.0)
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	f.y = 0
	f = f.normalized()
	var side = Vector3.UP.cross(f).normalized()
	var s0 = who.global_position + Vector3.UP * 1.35 + f * 0.5
	var aim_at = func(from: Vector3) -> Vector3:
		return ((tg.global_position + Vector3.UP) - from).normalized() if tg != null else f
	var shoot = func(from: Vector3, d: Vector3, delay: float):
		if delay <= 0.0:
			Projectile.tool(who, from, d, "senbon", tg)
		else:
			who.get_tree().create_timer(delay).timeout.connect(func():
				if is_instance_valid(who):
					Projectile.tool(who, from, d, "senbon", tg))
	match i:
		0, 1:   # tek elden üç iğne
			var o = s0 + side * (0.25 if i == 0 else -0.25)
			for k in 3:
				shoot.call(o, aim_at.call(o).rotated(Vector3.UP, deg_to_rad((k - 1) * 3.0)), k * 0.03)
		2:   # iki elden yelpaze: iki sıra
			for row in 2:
				for k in 5:
					shoot.call(s0 + Vector3.UP * (row * 0.2 - 0.1), aim_at.call(s0).rotated(Vector3.UP, deg_to_rad((k - 2) * 7.0)), row * 0.08)
		3:   # havadan aşağı yağmur
			var o = who.global_position + Vector3.UP * 2.6
			var tp = (tg.global_position if tg != null else who.global_position + f * 8.0)
			for k in 10:
				var jitter = Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
				shoot.call(o, ((tp + jitter) - o).normalized(), k * 0.03)
		4:   # dönüp çevreye halka
			for k in 16:
				shoot.call(s0 - f * 0.5, f.rotated(Vector3.UP, TAU * k / 16.0), 0.0)
		5:   # Sensatsu Suishō: hedefin çevresinde iğneler belirir, içeri saplanır
			var c = (tg.global_position + Vector3.UP) if tg != null else who.global_position + f * 8.0 + Vector3.UP
			for k in 24:
				var a = TAU * k / 24.0
				var e = deg_to_rad(randf_range(-30.0, 50.0))
				var p = c + Vector3(cos(a) * cos(e), sin(e), sin(a) * cos(e)) * 3.2
				shoot.call(p, (c - p).normalized(), 0.2 + (k % 6) * 0.05)
			VFX.star(c, Color(0.85, 0.95, 1.0), 2.0, 0.2)


## Hiramekarei ikiye bölünür: sağ eldeki kılıç yarıya döner, sol ele öbür yarı gelir (süre sonunda ya da _hk_join'de birleşir)
static func _hk_split(who: Node3D, dur: float) -> void:
	var n = _weapon_node(who)
	var m = who.get("model")
	if n == null or m == null or not (n is MeshInstance3D):
		return
	(n as MeshInstance3D).mesh = CharacterModel.weapon_mesh("hiramekarei_yari")
	VFX.star(n.global_position + Vector3.UP * 0.2, Color(0.6, 0.8, 1.0), 1.2, 0.14)
	Sfx.play("whoosh", who.global_position, 1.3, 0.5)
	if m.has_method("hold_temp"):
		m.hold_temp("hiramekarei_yari", dur, "Left", 1.0, 0.0, false, true)
	who.get_tree().create_timer(dur).timeout.connect(func(): _hk_join(who))


static func _hk_join(who: Node3D) -> void:
	if who == null or not is_instance_valid(who):
		return
	var n = _weapon_node(who)
	if n == null or not (n is MeshInstance3D):
		return
	if (n as MeshInstance3D).mesh != CharacterModel.weapon_mesh("hiramekarei"):
		(n as MeshInstance3D).mesh = CharacterModel.weapon_mesh("hiramekarei")
		VFX.star(n.global_position + Vector3.UP * 0.2, Color(0.6, 0.8, 1.0), 1.4, 0.16)


## Zabuza: Kirigakure — sis yayılır, kullanıcı sisin içinde kaybolup hedefin arkasında belirir
static func _kirigakure(who: Node3D) -> void:
	for k in 6:
		var a = TAU * k / 6.0
		FX.smoke_puff(who.global_position + Vector3(cos(a), 0.6, sin(a)) * 2.0, 1.0, 10)
	var tg = _hira_target(who)
	who.get_tree().create_timer(0.5).timeout.connect(func():
		if not is_instance_valid(who) or tg == null or not is_instance_valid(tg):
			return
		var back = tg.global_position - who.global_position
		back.y = 0
		back = back.normalized() if back.length() > 0.01 else Vector3.FORWARD
		FX.smoke_puff(who.global_position + Vector3.UP, 0.8, 8)
		_blink(who, tg, back * 1.6)
		FX.smoke_puff(who.global_position + Vector3.UP, 0.8, 8))


## Hiramekarei'nin chakra çekici: kılıcın ucunda yarı saydam mavi dev çekiç başı (kısa süre)
static func _hk_hammer(who: Node3D, dur: float) -> void:
	var n = _weapon_node(who)
	if n == null:
		return
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.7, 1.4, 0.7)
	mi.mesh = bm
	var mt = StandardMaterial3D.new()
	mt.albedo_color = Color(0.45, 0.7, 1.0, 0.55)
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.emission_enabled = true
	mt.emission = Color(0.4, 0.65, 1.0)
	mt.emission_energy_multiplier = 1.6
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mt
	n.add_child(mi)
	mi.position = Vector3(0, 0, 1.25)
	mi.scale = Vector3.ONE * 0.2
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(dur)
	tw.tween_property(mi, "scale", Vector3.ONE * 0.05, 0.15)
	tw.tween_callback(mi.queue_free)


## Kusanagi iai geçişi: 5 m öne şimşek gibi geçer (yol boyu iz), 0.3 s sonra yol üstündekilerde kesik açılır
static func _kusa_iai(who: Node3D, dmg: float) -> void:
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	f.y = 0
	f = f.normalized()
	var from = who.global_position
	var to = from + f * 5.0
	to.y = Game.ground_height(to.x, to.z)
	var bl = Color(0.55, 0.8, 1.0)
	VFX.bolt(from + Vector3.UP, to + Vector3.UP, bl, 0.3, 0.35, 4)
	WindFX.streak(func(t: float) -> Vector3:
		return from.lerp(to, t) + Vector3.UP * 1.1, 0.25, 0.1, Color(0.8, 0.9, 1.0, 0.8), 0.0, 14)
	who.global_position = to
	if who is CharacterBody3D:
		who.velocity = Vector3.ZERO
	Sfx.play("whoosh", to, 1.8, 0.6)
	who.get_tree().create_timer(0.32).timeout.connect(func():
		if not is_instance_valid(who):
			return
		for k in 5:
			var q = from.lerp(to, (k + 0.5) / 5.0) + Vector3.UP
			Combat.hit_sphere(who, q, 1.4, {"dmg": dmg * 0.45, "knock": 7.0, "kind": "heavy", "hitstop": 0.06, "melee": false, "bleed": 4.0})
			FX.hit_spark(q, Color(0.85, 0.9, 1.0), 0.9)
		VFX.slowmo(0.2, 0.25))


## Kiba: iki ağzın kök/uç noktaları (sağ + sol el)
static func _kiba_tips(who: Node3D) -> Array:
	var out = []
	var m = who.get("model")
	if m == null or m.get("weapons") == null:
		return out
	for w in m.weapons:
		if String(w["id"]).begins_with("kiba") and is_instance_valid(w["node"]):
			var n: Node3D = w["node"]
			out.append([n.to_global(Vector3(0, 0, 0.26)), n.to_global(Vector3(0, 0, 1.1))])
	return out


static func _kiba_strike(who: Node3D, i: int, dmg: float, f: Vector3, side: Vector3) -> void:
	var bl = Color(0.6, 0.8, 1.0)
	for tp in _kiba_tips(who):   # her vuruşta ağız boyunca şimşek
		VFX.bolt(tp[0], tp[1], bl, 0.14, 0.14, 2)
	var c = who.global_position + Vector3.UP * 1.1 + f * 1.4
	match i:
		0:
			for sg in [-1.0, 1.0]:
				VFX.bolt(c + side * 0.8 * sg + Vector3.UP * 0.7, c - side * 0.8 * sg - Vector3.UP * 0.6, bl, 0.18, 0.2, 2)
		3:   # elektrik halkası
			var o = who.global_position + Vector3.UP * 1.1
			for k in 10:
				var a = TAU * k / 10.0
				var a2 = TAU * (k + 1) / 10.0
				VFX.bolt(o + Vector3(cos(a), 0, sin(a)) * 2.2, o + Vector3(cos(a2), 0, sin(a2)) * 2.2, bl, 0.16, 0.25, 1)
		4:   # Rairyū Tsuki: ağızlardan ileri 9 m şimşek
			var o = who.global_position + Vector3.UP * 1.2 + f * 0.9
			VFX.bolt(o, o + f * 9.0, bl, 0.35, 0.35, 4)
			for k in 6:
				Combat.hit_sphere(who, o + f * (1.2 + k * 1.4), 1.0, {"dmg": dmg * 0.25, "knock": 3.0, "stun": 0.6, "kind": "light", "hitstop": 0.02, "melee": false})
			Sfx.play("zap", o, 1.2, 0.7)
		5:   # Kaminari Gekō: gökten yıldırım hedefe çakar
			var tg = _hira_target(who)
			var q: Vector3 = who.global_position + f * 4.0
			if tg != null and tg.global_position.distance_to(who.global_position) < 14.0:
				q = tg.global_position
			q.y = Game.ground_height(q.x, q.z)
			VFX.bolt(q + Vector3.UP * 30.0, q, Color(0.75, 0.88, 1.0), 0.9, 0.5, 6)
			for k in 8:
				var a = TAU * k / 8.0
				VFX.bolt(q + Vector3.UP * 0.1, q + Vector3(cos(a), 0.1, sin(a)) * 3.4, bl, 0.25, 0.35, 2)
			VFX.cracks(q, 2.2)
			Combat.hit_sphere(who, q + Vector3.UP, 3.4, {"dmg": dmg * 1.3, "knock": 6.0, "launch": 5.0, "stun": 1.2, "kind": "heavy", "hitstop": 0.12, "melee": false})
			_shake(who, 0.8)
			Sfx.play("zap", q, 1.6, 0.5)


# ================================================================== DÖVÜŞ TARZLARI (FightingStyles) — oyuncu ve düşman aynı
static func _ov(who: Node3D):
	var m = who.get("model")
	return m.overlay if m and m.get("overlay") else null


## Eller (açık avuç / yumruk / pençe), uzuv büyümesi, kemik kılıç; kombo bitince (1.4 sn adım gelmezse) her şey geri alınır
static func _style_start(id: String, i: int, who: Node3D) -> void:
	var ov = _ov(who)
	if ov == null:
		return
	var tok = Time.get_ticks_msec()
	who.set_meta("style_tok", tok)
	ov.grow = {}
	match id:
		"style_juken":
			ov.fist = {"Right": -1.0, "Left": -1.0}   # açık avuç (negatif = parmaklar düz açılır)
			if i == 4:
				ov.fist = {"Right": 0.55, "Left": 0.55}   # iki parmak dürtüşü: parmaklar yarı kıvrık
		"style_akimichi":
			ov.fist = {"Right": 1.0, "Left": 1.0}
			var g = {}
			match i:
				0: g = {"RightLowerArm": 1.35, "RightHand": 3.0}
				1: g = {"LeftLowerArm": 1.35, "LeftHand": 3.0}
				3:
					g = {"RightLowerArm": 1.5, "RightHand": 3.8}
					ov.fist = {"Right": -1.0, "Left": 1.0}   # Chō Harite: açık dev avuç
				4: g = {"RightLowerArm": 1.3, "LeftLowerArm": 1.3, "RightHand": 2.8, "LeftHand": 2.8}
				5: g = {"RightUpperArm": 1.3, "RightLowerArm": 1.8, "RightHand": 4.2}
			_grow_in(who, ov, g, [0.32, 0.36, 0.0, 0.46, 0.5, 0.55][i] / speed(id), tok)
		"style_inuzuka":
			ov.fist = {"Right": 0.55, "Left": 0.55}   # pençe
			if i in [0, 1, 3] and who is CharacterBody3D:   # kanon: vur-kaç — pençeden hemen sonra dört ayak geri sekiş
				var ht = [0.16, 0.16, 0.0, 0.27][i] / speed(id)
				who.get_tree().create_timer(ht + 0.06).timeout.connect(func():
					if is_instance_valid(who):
						var fb: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
						who.velocity.x = -fb.x * 6.5
						who.velocity.z = -fb.z * 6.5
						who.velocity.y = 3.0)
			if i == 5 and who is CharacterBody3D:   # Gatsūga: kendi ekseninde dönerek hücum
				var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
				who.get_tree().create_timer(0.3 / speed(id)).timeout.connect(func():
					if is_instance_valid(who):
						who.velocity.x = f.x * 17.0
						who.velocity.z = f.z * 17.0
						WindFX.swirl(who.global_position + Vector3.UP * 0.4, 0.9, 1.6, 0.5, 8, Color(0.85, 0.82, 0.75, 0.85), true))
		"style_uchiha":
			ov.fist = {"Right": 1.0, "Left": 1.0}
			if i == 3:   # Kage Buyō (kanon, Shishi Rendan): havaya kalkan rakibin hemen arkasında yaprak gölgesi gibi belirir
				var tgu = _near_foe(who, 7.0)
				if tgu and who is CharacterBody3D:
					var away = tgu.global_position - who.global_position
					away.y = 0
					away = away.normalized() if away.length() > 0.05 else Vector3.FORWARD
					var pjk = PathJutsu.get_pinst()
					if pjk:
						pjk._trail_ghost(who, 0.45, 0.35)
					who.global_position = tgu.global_position + away * 0.9 + Vector3.UP * 0.4
					who.velocity = Vector3(0, 3.0, 0)
					if who is Player:
						who.combat.face_to(tgu)
					elif who.get("facing") != null:
						who.facing = atan2(-away.x, -away.z) + PI
		"style_hozuki":
			ov.fist = {"Right": 0.6, "Left": 0.6}   # parmak tabancası: işaret parmağı açık, diğerleri kıvrık
			if i == 3:
				_bulk_in(who, ov, {"RightUpperArm": 2.0, "RightLowerArm": 1.8}, 0.34 / speed(id), tok)
				ov.fist = {"Right": 1.0, "Left": 0.6}
				_grow_in(who, ov, {"RightHand": 1.8}, 0.34 / speed(id), tok)
		"style_aburame":
			ov.fist = {"Right": -0.6, "Left": -0.6}   # gevşek açık eller (yenlerden sürü)
		"style_yilan":
			ov.fist = {"Right": -0.6, "Left": -0.6}
		"style_gama":
			ov.fist = {"Right": -0.8, "Left": -0.8} if i == 5 else {"Right": 0.5, "Left": 0.5}
			if i == 5:   # Ōdama Rasengan: avuçta büyüyen küre (kurulum boyunca)
				_rasen_hand(who, 0.62 / speed(id))
		"style_chidori":
			ov.fist = {"Right": -0.7, "Left": 0.6} if i != 4 else {"Right": 0.6, "Left": 0.6}   # Chidori: pençe gibi açık avuç
			if i == 1:
				ov.fist = {"Right": 0.6, "Left": -0.9}
			if i in [0, 2, 5]:   # elde bin kuş: şimşek küresi kurulumdan vuruşa kadar
				_rai_hand(who, (0.75 if i == 5 else 0.4) / speed(id), i == 5)
				Sfx.play("chidori", who.global_position + Vector3.UP, 1.3 if i != 5 else 1.0, 0.5)
			if i == 5:   # Chidori koşusu: el yere sürtülür, toprak yarılır (hendek), hedefin dibine kadar
				who.get_tree().create_timer(0.22 / speed(id)).timeout.connect(func():
					if not is_instance_valid(who) or int(who.get_meta("style_tok", 0)) != tok:
						return
					_chidori_run(who, 0.36 / speed(id)))
		"style_tip":
			ov.fist = {"Right": -1.0, "Left": -1.0} if i != 5 else {"Right": 1.0, "Left": 0.6}
			if i in [0, 1]:   # Chakra Neşteri: parmak uçlarından mavi bıçak (kurulum + kesik boyunca)
				_scalpel(who, i == 0, 0.45 / speed(id))
			if i == 5:   # Ōkashō: chakra yumrukta toplanır
				_tip_fist(who, 0.62 / speed(id))
		"style_kakuzu":
			ov.fist = {"Right": -0.6, "Left": -0.6} if i != 2 else {"Right": 1.0, "Left": 1.0}
			if i == 2:   # Domu: ten taşlaşır, kısa kalkan
				var pjd = PathJutsu.get_pinst()
				if pjd:
					pjd._stone_skin(who, 0.8 / speed(id), Color(0.18, 0.17, 0.17))
				if who is Player:
					who.combat.invuln = maxf(who.combat.invuln, 0.5 / speed(id))
		"style_jin_shukaku":
			ov.fist = {"Right": -1.0, "Left": 0.6}
			if i in [0, 1, 5]:   # kısmi dönüşüm: sağ kol kumla kaplanıp dev pençeye büyür
				_grow_in(who, ov, {"RightHand": 2.6 if i == 5 else 2.0}, (0.26 if i != 5 else 0.6) / speed(id), tok)
				_bulk_in(who, ov, {"RightUpperArm": 1.5, "RightLowerArm": 1.7}, (0.26 if i != 5 else 0.6) / speed(id), tok)
				_sand_arm(who, (0.6 if i != 5 else 1.1) / speed(id))
		"style_jin_matatabi":
			ov.fist = {"Right": -0.4, "Left": -0.4}   # pençe: parmaklar yarı kıvrık
			if i in [0, 1, 5]:
				_blue_claws(who, i != 1, i != 0, 0.45 / speed(id))
		"style_jin_isobu":
			ov.fist = {"Right": -0.8, "Left": -0.8}
		"style_jin_son_goku":
			ov.fist = {"Right": 1.0, "Left": 1.0}
			if i in [0, 5]:
				_lava_fist(who, "RightHand", (0.24 if i == 0 else 0.64) / speed(id) + 0.2)
			elif i == 1:
				_lava_fist(who, "LeftHand", 0.24 / speed(id) + 0.2)
		"style_jin_kokuo":
			ov.fist = {"Right": 1.0, "Left": 1.0}
			if i == 5:   # Kōjōki: sırttaki kazandan buhar fışkırır, roket gibi öne
				who.get_tree().create_timer(0.5 / speed(id)).timeout.connect(func():
					if is_instance_valid(who) and int(who.get_meta("style_tok", 0)) == tok:
						_steam_rocket(who, 0.22))
		"style_jin_saiken":
			ov.fist = {"Right": -0.8, "Left": -0.8}
		"style_jin_chomei":
			ov.fist = {"Right": -0.8, "Left": -0.8}
			if i in [0, 1, 4, 5]:   # sırttan şeffaf böcek kanatları açılır
				_bug_wings(who, (0.5 if i < 2 else 0.85) / speed(id))
			if i == 4 and who is CharacterBody3D:   # kanatla sıçra
				who.velocity.y = 8.0
		"style_jin_gyuki":
			ov.fist = {"Right": 1.0, "Left": 1.0}
			FX.aura(who, Color(0.65, 0.35, 0.75), 1.1, Vector3(0, 0.9, 0), 0.6 / speed(id))   # Gyūki'nin mor chakra örtüsü
		"style_jin_kurama":
			ov.fist = {"Right": -0.4, "Left": -0.4}
			FX.aura(who, Color(1.0, 0.55, 0.15), 1.1, Vector3(0, 0.9, 0), 0.6 / speed(id))   # Kurama'nın turuncu chakra örtüsü
			if i == 5:
				_rasen_hand(who, 0.68 / speed(id))
		"style_jashin":
			ov.fist = {"Right": 1.0, "Left": -0.5}
			if i in [1, 4, 5]:   # elde kara mızrak (geri çekilebilir)
				_jashin_spike(who, (0.5 if i == 1 else 0.75) / speed(id))
		"style_hachibi":
			ov.fist = {"Right": 1.0, "Left": 1.0} if i != 2 else {"Right": 0.6, "Left": 0.6}
			if i == 3:   # Lariat: Raiton örtüsü + atılış
				var pjl = PathJutsu.get_pinst()
				if pjl:
					pjl._rai_cloak(who, 0.55 / speed(id))
				who.get_tree().create_timer(0.14 / speed(id)).timeout.connect(func():
					if is_instance_valid(who) and int(who.get_meta("style_tok", 0)) == tok and who is CharacterBody3D:
						var tgl = _near_foe(who, 9.0)
						var dl = who.face_dir()
						if tgl:
							dl = tgl.global_position - who.global_position
							dl.y = 0
							dl = dl.normalized()
						who.velocity = dl * 15.0 + Vector3(0, who.velocity.y, 0))
		"style_silah":
			ov.fist = {"Right": 0.8, "Left": 0.8}
			if i in [0, 1, 4]:   # parşömen iki el arasında açılır (mühürden mühüre silah)
				var pjs = PathJutsu.get_pinst()
				if pjs:
					var sc = pjs.hold_scroll(who, 0.55 / speed(id), 0.36, 0.55)
					pjs.fade_free(sc, 0.55 / speed(id), 0.15)
		"style_hiraishin":
			ov.fist = {"Right": -1.0, "Left": -0.3} if i in [1, 4] else {"Right": 0.5, "Left": -0.3}
			var tgh = _hira_target(who)
			match i:
				1:   # en yakın kunaiye (hedefin yanındaki) ışınlan
					who.get_tree().create_timer(0.08 / speed(id)).timeout.connect(func():
						if is_instance_valid(who) and int(who.get_meta("style_tok", 0)) == tok:
							var kp = _hira_mark_near(who, tgh.global_position if tgh else who.global_position + who.face_dir() * 4.0)
							if kp != Vector3.INF:
								_hira_hop(who, kp, tgh)
							elif tgh and tgh.global_position.distance_to(who.global_position) < 10.0:
								_hira_hop(who, tgh.global_position - (tgh.global_position - who.global_position).normalized() * 1.3, tgh))
				2:   # Ni no Dan: işaretli rakibin ARKASINDA belir
					who.get_tree().create_timer(0.1 / speed(id)).timeout.connect(func():
						if is_instance_valid(who) and int(who.get_meta("style_tok", 0)) == tok and is_instance_valid(tgh) and tgh.global_position.distance_to(who.global_position) < 14.0:
							var away = tgh.global_position - who.global_position
							away.y = 0
							_hira_hop(who, tgh.global_position + away.normalized() * 1.1, tgh))
				3:   # kunai hedefin üstüne atılır, havada yakalanır: yukarıdan iniş
					if tgh and tgh.global_position.distance_to(who.global_position) < 14.0:
						var top = tgh.global_position + Vector3.UP * 3.2
						_hira_throw(who, who.global_position + Vector3.UP * 1.5, top, 0.12, false)
						who.get_tree().create_timer(0.14 / speed(id)).timeout.connect(func():
							if is_instance_valid(who) and int(who.get_meta("style_tok", 0)) == tok and is_instance_valid(tgh):
								_hira_hop(who, top - (tgh.global_position - who.global_position).normalized() * 0.4, tgh, false)
								if who is CharacterBody3D:
									who.velocity = Vector3(0, -14.0, 0))
				5:   # Rasengan yoğrulur; vuruştan hemen önce hedefin arkasında sarı flaş
					_rasen_hand(who, 0.6 / speed(id))
					who.get_tree().create_timer(0.48 / speed(id)).timeout.connect(func():
						if is_instance_valid(who) and int(who.get_meta("style_tok", 0)) == tok and is_instance_valid(tgh) and tgh.global_position.distance_to(who.global_position) < 16.0:
							var away2 = tgh.global_position - who.global_position
							away2.y = 0
							_hira_hop(who, tgh.global_position + away2.normalized() * 1.0, tgh))
		"style_kagit":
			ov.fist = {"Right": -0.8, "Left": -0.8}
			if i == 4:   # kâğıt kanatlar sırttan açılır (kısa)
				_paper_wings(who, 0.9 / speed(id))
		"style_sumi":
			ov.fist = {"Right": 0.7, "Left": 0.4}   # sağ el fırçayı tutar, sol parşömen
		"style_akasuna":
			ov.fist = {"Right": -1.0, "Left": -1.0}   # on parmak açık: chakra iplikleri
		"style_kil":
			ov.fist = {"Right": -0.8, "Left": -0.8} if i != 5 else {"Right": 0.6, "Left": 0.2}   # avuç ağızları açık; Katsu: iki parmak mühürü
		"style_kapi":
			ov.fist = {"Right": 1.0, "Left": 1.0} if i != 5 else {"Right": -0.9, "Left": -0.9}
			if i == 3 and who is CharacterBody3D:   # Kage Buyō: havaya kalkan rakibin peşinden sıçra
				who.velocity.y = 9.0
				var tgk = _near_foe(who, 6.0)
				if tgk:
					var dk = tgk.global_position - who.global_position
					dk.y = 0
					who.velocity.x = dk.x * 1.4
					who.velocity.z = dk.z * 1.4
			elif i >= 4:   # kapılar açılır: bedenden yeşil buhar (Sekiz Kapı aurası)
				FX.aura(who, Color(0.45, 1.0, 0.45), 1.0, Vector3(0, 0.9, 0), 0.9)
		"style_nara":
			ov.fist = {"Right": 0.5, "Left": 0.5} if i in [2, 5] else {"Right": -0.6, "Left": -0.6}   # Ne mühürü / açık el
		"style_hatake":
			ov.fist = {"Right": 1.0, "Left": 1.0} if i in [0, 1, 2] else {"Right": -0.4, "Left": 0.6}
			if i == 2:   # Shunshin: kaybolup rakibin arkasında belir
				var tg4 = _near_foe(who, 8.0)
				if tg4:
					who.get_tree().create_timer(0.14 / speed(id)).timeout.connect(func():
						if is_instance_valid(who) and is_instance_valid(tg4):
							var bk = tg4.global_position - who.global_position
							bk.y = 0
							bk = bk.normalized() if bk.length() > 0.01 else Vector3.FORWARD
							FX.speed_lines(who.global_position + Vector3.UP, bk)
							_blink_plain(who, tg4, bk * 1.1)
							if "facing" in who:
								who.facing += PI   # sırtı rakibe: geriye dirsek
							FX.speed_lines(who.global_position + Vector3.UP, -bk))
			elif i == 3 or i == 5:   # avuçta şimşek toplanır (ref hatake_0)
				_rai_hand(who, [0, 0, 0, 0.35, 0, 0.78][i] / speed(id), i == 5)
		"style_sarutobi":
			ov.fist = {"Right": 1.0, "Left": 1.0} if i in [0, 1, 3] else ({"Right": 0.6, "Left": 0.6} if i == 4 else {"Right": -0.5, "Left": -0.5})
		"style_senju":
			ov.fist = {"Right": 1.0, "Left": 1.0} if i in [0, 1, 4] else {"Right": -0.7, "Left": -0.7}
			if i == 5 and who is CharacterBody3D:
				who.velocity.y = 9.0   # Tsūtenkyaku: sıçrar, topukla iner
		"style_kurosuki":
			ov.fist = {"Right": -1.0, "Left": -1.0}   # el kılıcı: düz açık avuç
			if i == 2:   # Kirigakure: sise karışıp rakibin yanında belir
				var tg3 = _near_foe(who, 10.0)
				if tg3:
					for k in 6:
						var a3 = TAU * k / 6.0
						_smoke_puff_at(who.global_position + Vector3(cos(a3), 0.5, sin(a3)) * 1.4, 0.8, 6, Vector3.UP, Color(0.92, 0.95, 1.0, 0.85))
					who.get_tree().create_timer(0.28 / speed(id)).timeout.connect(func():
						if is_instance_valid(who) and is_instance_valid(tg3):
							var sd = (tg3.global_position - who.global_position).cross(Vector3.UP).normalized()
							_smoke_puff_at(who.global_position + Vector3.UP, 0.7, 8, Vector3.UP, Color(0.92, 0.95, 1.0, 0.85))
							_blink_plain(who, tg3, sd * 1.3)
							_smoke_puff_at(who.global_position + Vector3.UP, 0.7, 8, Vector3.UP, Color(0.92, 0.95, 1.0, 0.85)))
			elif i == 5:   # bedene doğal şimşek çekilir (ref kurosuki_0): göğe uzanan sütun
				var top = who.global_position + Vector3.UP * 18.0
				VFX.bolt(top, who.global_position + Vector3.UP * 1.8, Color(0.85, 0.93, 1.0), 0.5, 0.35, 4)
				FX.aura(who, Color(0.7, 0.85, 1.0), 0.9, Vector3(0, 0.9, 0), 1.0)
		"style_iburi":
			ov.fist = {"Right": 1.0, "Left": 1.0} if i in [0, 1] else {"Right": -0.6, "Left": -0.6}
			if i == 2:   # Kemuri Utsuri: dumana dağılıp rakibin arkasında katılaşır
				var tg2 = _near_foe(who, 9.0)
				if tg2:
					who.get_tree().create_timer(0.16 / speed(id)).timeout.connect(func():
						if is_instance_valid(who) and is_instance_valid(tg2):
							_smoke_shift(who, tg2))
			elif i == 5:   # Tatsumaki: beden kısmen dumana döner (eller katı) — ref iburi_4
				_smoke_body(who, 1.0 / speed(id))
		"style_kamizuru":
			ov.fist = {"Right": -0.8, "Left": -0.8}   # açık avuç (arıları salar); mühürde sol avuç açık, sağ başparmak bastırır
			if i == 3:
				ov.fist = {"Right": 0.7, "Left": -1.0}
			_bee_escort(who, [0.5, 0.5, 0.6, 0.7, 0.75, 1.0][i] / speed(id))   # tarz açıkken çevresinde uçuşan birkaç arı
		"style_jugo":   # ref jugo_*.png: ten boz-griye döner, boyundan kara lanet lekeleri yayılır; ön kol jet delikli taş balyoza dönüşür
			ov.fist = {"Right": 1.0, "Left": 1.0}
			_senninka_look(who)
			var ht = [0.3, 0.3, 0.34, 0.46, 0.3, 0.44][i] / speed(id)
			var left = i == 1
			if not left:
				_jugo_club(who, "RightLowerArm", i == 4)
			if left or i == 3:
				_jugo_club(who, "LeftLowerArm", false)
			if i != 3 and i != 4:   # dirsekteki deliklerden jet: yumruğu ivmelendirir
				_jet(who, "LeftLowerArm" if left else "RightLowerArm", ht)
		"style_yuki":
			ov.fist = {"Right": 0.35, "Left": 0.35}   # parmak arasında iğne
			if i in [0, 1, 3] and who is CharacterBody3D and i != 3:   # çevik: atıştan sonra yana sekme
				who.get_tree().create_timer(0.22 / speed(id)).timeout.connect(func():
					if is_instance_valid(who):
						var fb: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
						var sd = Vector3.UP.cross(fb) * (1.0 if i == 0 else -1.0)
						who.velocity.x = sd.x * 5.5 - fb.x * 2.0
						who.velocity.z = sd.z * 5.5 - fb.z * 2.0
						who.velocity.y = 2.5)
		"style_sabaku":
			ov.fist = {"Right": -1.0, "Left": 0.6}
			if i == 5:   # Sōsō: açık avuç vuruş anında yumruğa kapanır
				var tk5 = tok
				who.get_tree().create_timer(0.48 / speed(id)).timeout.connect(func():
					if is_instance_valid(who) and int(who.get_meta("style_tok", 0)) == tk5:
						ov.fist = {"Right": 1.0, "Left": 0.6})
		"style_uzumaki":
			ov.fist = {"Right": -0.5, "Left": -0.5}
		"style_yotsuki":
			ov.fist = {"Right": 1.0, "Left": 1.0}
			if i == 3:
				ov.fist = {"Right": -1.0, "Left": 1.0}   # el kılıcı: açık düz el
			_rai_armor(who)
		"style_kaguya":
			ov.fist = {"Right": 0.9, "Left": 0.15}
			_bone_blade(who)
			if i == 3:
				_bone_spikes(who, ["RightUpperArm", "LeftUpperArm", "RightLowerArm", "LeftLowerArm", "UpperChest"], 0.75 / speed(id))
	who.get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(who) and int(who.get_meta("style_tok", 0)) == tok:
			_style_end(who))


static func _style_end(who: Node3D) -> void:
	var ov = _ov(who)
	if ov:
		ov.fist = {}
		ov.grow = {}
		for b in (who.get_meta("style_bulk", []) as Array):   # yalnız tarzın kalınlaştırdığı kemikler (Gōsuiwan jutsusu ayrı)
			ov.bulk.erase(b)
		who.remove_meta("style_bulk")
	if who.has_meta("rai_armor"):
		var ra = who.get_meta("rai_armor")
		who.remove_meta("rai_armor")
		if is_instance_valid(ra):
			ra.queue_free()
	if who.has_meta("bone_blade"):
		var bb = who.get_meta("bone_blade")
		who.remove_meta("bone_blade")
		if is_instance_valid(bb):
			bb.queue_free()
	if who.has_meta("jugo_clubs"):
		for ba in (who.get_meta("jugo_clubs") as Dictionary).values():
			if is_instance_valid(ba):
				var tw = ba.create_tween()
				tw.tween_property(ba.get_child(0), "scale", Vector3(0.6, 0.2, 0.6), 0.25)
				tw.tween_callback(ba.queue_free)
		who.remove_meta("jugo_clubs")
	if who.has_meta("senninka_look"):
		var prev = int(who.get_meta("senninka_look"))
		who.remove_meta("senninka_look")
		var m = who.get("model")
		if m and is_instance_valid(m):
			m.set_skin_tint(Color.WHITE, 0.0)
			var bm = m.get("body_mesh")
			var smat = bm.get_surface_override_material(0) if bm else null
			if smat is ShaderMaterial and smat.get_shader_parameter("sage_marks") != null and int(smat.get_shader_parameter("sage_marks")) == 5:
				smat.set_shader_parameter("sage_marks", prev)


## Bubun Baika: vuruş anına doğru büyür, vuruştan sonra küçülür (gerçek kemik büyümesi — PoseOverlay.grow)
static func _grow_in(who: Node3D, ov, g: Dictionary, hit_t: float, tok: int) -> void:
	if g.is_empty():
		return
	var steps = 8
	for k in steps + 6:
		who.get_tree().create_timer(hit_t * float(k) / steps).timeout.connect(func():
			if not is_instance_valid(who) or int(who.get_meta("style_tok", 0)) != tok:
				return
			var u = clampf(float(k) / (steps * 0.7), 0.0, 1.0) if k <= steps else clampf(1.0 - float(k - steps) / 6.0, 0.0, 1.0)   # vuruştan önce doruğa: vuruş boyunca dev
			var d = {}
			for b in g:
				d[b] = lerpf(1.0, float(g[b]), u * u * (3.0 - 2.0 * u))
			ov.grow = d)


## Gōsuiwan / Senninka: kol kasları gerçek kemikle kalınlaşır (PoseOverlay.bulk), vuruştan sonra iner
static func _bulk_in(who: Node3D, ov, b: Dictionary, hit_t: float, tok: int) -> void:
	var mine: Array = who.get_meta("style_bulk", [])
	for k in b:
		if not k in mine:
			mine.append(k)
	who.set_meta("style_bulk", mine)
	var steps = 8
	for k in steps + 6:
		who.get_tree().create_timer(hit_t * float(k) / steps).timeout.connect(func():
			if not is_instance_valid(who) or int(who.get_meta("style_tok", 0)) != tok:
				return
			var u = clampf(float(k) / (steps * 0.7), 0.0, 1.0) if k <= steps else clampf(1.0 - float(k - steps) / 6.0, 0.0, 1.0)
			for bn in b:
				ov.bulk[bn] = lerpf(1.0, float(b[bn]), u * u * (3.0 - 2.0 * u)))


## Jūgo: dirsekten fışkıran beyaz buhar jeti (yumruğu ivmelendirir)
static func _jet(who: Node3D, bone: String, at_t: float) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	who.get_tree().create_timer(maxf(0.0, at_t - 0.12)).timeout.connect(func():
		if not is_instance_valid(who):
			return
		var m = who.get("model")
		if m == null or m.skel == null or m.skel.find_bone(bone) < 0:
			return
		var bt: Transform3D = m.skel.global_transform * m.skel.get_bone_global_pose(m.skel.find_bone(bone))
		var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
		var back = (-f + Vector3.UP * 0.15).normalized()
		for k in 3:   # balyozun sırtındaki üç delik (dirsek tarafı)
			var p = bt * Vector3(0, 0.06 + k * 0.09, 0) - f * 0.14
			FX.burst(p, {"amount": 14, "life": 0.22, "tex": FX.tex_spark, "add": true, "size": 0.32, "radius": 0.03,
				"vmin": 9.0, "vmax": 15.0, "dir": back, "spread": 7.0, "damp": 3.0,
				"colors": [Color(1, 1, 0.9, 1), Color(1.0, 0.75, 0.3, 0.9), Color(0.9, 0.35, 0.1, 0)]})
		var e = bt * Vector3(0, 0.12, 0) - f * 0.2
		VFX.shockwave(e - f * 0.25, Color(1.0, 0.9, 0.75), 1.2, 0.18, false, -f)
		WindFX.streak(func(u: float) -> Vector3: return e - f * (0.2 + u * 2.4), 0.2, 0.05, Color(1, 0.95, 0.85), 0.0, 6)
		Sfx.play("whoosh", who.global_position, 1.6, 0.6))


## Senninka görünüşü (ref jugo_0/2): ten boz-griye döner, boyundan kara lanet lekeleri yayılır (toon sage_marks 5); kombo bitince geri
static func _senninka_look(who: Node3D) -> void:
	if who.has_meta("senninka_look"):
		return
	var m = who.get("model")
	if m == null or not is_instance_valid(m) or not m.has_method("set_skin_tint"):
		return
	var bm = m.get("body_mesh")
	var smat = bm.get_surface_override_material(0) if bm else null
	var prev = 0
	if smat is ShaderMaterial:
		var pv = smat.get_shader_parameter("sage_marks")
		prev = int(pv) if pv != null else 0
		smat.set_shader_parameter("sage_marks", 5)
	who.set_meta("senninka_look", prev)
	var tw = who.create_tween()
	tw.tween_method(func(k: float):
		if is_instance_valid(m) and who.has_meta("senninka_look"):
			m.set_skin_tint(Color(0.58, 0.5, 0.44), k), 0.0, 0.75, 0.2)


## Senninka kolu (ref jugo_2/3): ön kol + yumruk boz taş balyoza dönüşür — kalınlaşan gövde, kemik pütürleri, dirsek tarafında
## üç jet deliği, ön yüzde iri boğum. spiky: Hari-ude — kol boyunca öne eğik dikenler. Kemiğe bağlı: kol nereye, balyoz oraya.
static func _jugo_club(who: Node3D, bone: String, spiky: bool) -> void:
	var clubs: Dictionary = who.get_meta("jugo_clubs", {})
	if clubs.has(bone) and is_instance_valid(clubs[bone]):
		var old = clubs[bone]
		if bool(old.get_meta("spiky", false)) == spiky:
			return
		old.queue_free()
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var ba = pj.bone_attach(who, bone)
	if ba == null:
		return
	var skin = Color(0.56, 0.5, 0.45)
	var dark = Color(0.3, 0.26, 0.24)
	var b = MB.new()
	var pts = [Vector3(0, 0.0, 0), Vector3(0, 0.12, 0.01), Vector3(0, 0.26, 0.02), Vector3(0, 0.38, 0.02), Vector3(0, 0.47, 0.01), Vector3(0, 0.53, 0)]
	var rad = [Vector2(0.06, 0.06), Vector2(0.085, 0.08), Vector2(0.11, 0.1), Vector2(0.135, 0.12), Vector2(0.13, 0.115), Vector2(0.05, 0.045)]
	Loft.tube(b, pts, rad, [skin.darkened(0.1), skin, skin, skin.lightened(0.05), skin, skin.darkened(0.15)], 14, 4, true, true)
	for k in 7:   # pütürler: yüzeyde taş kabarcıkları
		var a = k * TAU / 7.0 + 0.3
		var y = 0.14 + (k % 3) * 0.11
		var r = 0.08 + y * 0.09
		b.add("sphere", Vector3(cos(a) * r, y, sin(a) * r), Vector3(0.05, 0.035, 0.05), skin.lerp(dark, 0.35), Vector3.ZERO, 6)
	for k in 4:   # yumruk boğumları (ön yüz)
		b.add("sphere", Vector3((k - 1.5) * 0.055, 0.47, 0.075), Vector3(0.065, 0.06, 0.06), skin.lightened(0.08), Vector3.ZERO, 8)
	for k in 3:   # jet delikleri (dirsek tarafı: -Z)
		b.add("cyl", Vector3(0, 0.08 + k * 0.09, -0.09), Vector3(0.04, 0.05, 0.04), dark.darkened(0.5), Vector3(90, 0, 0), 8)
		b.add("cyl", Vector3(0, 0.08 + k * 0.09, -0.085), Vector3(0.055, 0.025, 0.055), dark, Vector3(90, 0, 0), 10)
	if spiky:
		for k in 6:
			var a2 = k * TAU / 6.0
			b.add("cone", Vector3(cos(a2) * 0.15, 0.2 + (k % 2) * 0.14, sin(a2) * 0.15), Vector3(0.06, 0.34, 0.06), skin.lightened(0.15),
				Vector3(rad_to_deg(-sin(a2)) * 0.9 - 25.0, 0, rad_to_deg(cos(a2)) * 0.9), 5)
		b.add("cone", Vector3(0, 0.72, 0.02), Vector3(0.1, 0.45, 0.08), skin.lightened(0.15), Vector3.ZERO, 6)   # uçtaki sivri kazık
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	ba.add_child(mi)
	ba.set_meta("spiky", spiky)
	mi.scale = Vector3(0.5, 0.3, 0.5)
	mi.create_tween().tween_property(mi, "scale", Vector3.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	clubs[bone] = ba
	who.set_meta("jugo_clubs", clubs)


static var _bone_mat: StandardMaterial3D
static func _bone_material() -> StandardMaterial3D:
	if _bone_mat == null:
		_bone_mat = StandardMaterial3D.new()
		_bone_mat.albedo_color = Color(0.93, 0.92, 0.86)
		_bone_mat.roughness = 0.6
	return _bone_mat


## Tsubaki: sağ avuçtan çıkan kemik kılıç (ele bağlı, kombo boyunca)
static func _bone_blade(who: Node3D) -> void:
	if who.has_meta("bone_blade") and is_instance_valid(who.get_meta("bone_blade")):
		return
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var ba = pj.bone_attach(who, "RightLowerArm")   # kemik +Y = ön kol doğrultusu: kılıç bileğin ötesine kolun devamı olarak uzanır
	if ba == null:
		return
	var b = MB.new()
	b.add("cyl", Vector3(0, 0.3, 0.0), Vector3(0.045, 0.1, 0.045), Color(0.9, 0.88, 0.82), Vector3.ZERO, 8)   # avuçtan çıkan kemik kökü
	b.add("cone", Vector3(0, 0.66, 0.0), Vector3(0.075, 0.7, 0.028), Color(0.95, 0.94, 0.88), Vector3.ZERO, 4)   # yassı sivri kemik kılıç
	b.add("box", Vector3(0, 0.6, 0.0), Vector3(0.012, 0.5, 0.012), Color(0.75, 0.72, 0.66))   # sırt çizgisi
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	ba.add_child(mi)
	who.set_meta("bone_blade", ba)


## Yanagi / Karamatsu: kemiklerden fışkıran sivri kemik dikenleri (kısa süre)
static func _bone_spikes(who: Node3D, bones: Array, dur: float) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	for bn in bones:
		var ba = pj.bone_attach(who, bn)
		if ba == null:
			continue
		var b = MB.new()
		for k in 4:
			var a = k * TAU / 4.0 + 0.4
			var d = Vector3(cos(a), 0.3, sin(a)).normalized()
			b.add_xf("cone", Transform3D(Basis(Quaternion(Vector3.UP, d)) * Basis.from_scale(Vector3(0.05, 0.32, 0.05)), Vector3(0, 0.08 + k * 0.05, 0) + d * 0.2), Color(0.94, 0.93, 0.87), 5)
		var mi = MeshInstance3D.new()
		mi.mesh = b.build(Props.toon())
		ba.add_child(mi)
		mi.scale = Vector3.ONE * 0.05
		var tw = mi.create_tween()
		tw.tween_property(mi, "scale", Vector3.ONE, 0.08)
		tw.tween_interval(dur)
		tw.tween_property(mi, "scale", Vector3.ONE * 0.05, 0.12)
		tw.tween_callback(ba.queue_free)


## Chidori koşusu: el yere sürtülerek hedefin dibine atılış; ardında şimşekli hendek (zemin yarığı + toz)
static func _chidori_run(who: Node3D, dur: float) -> void:
	var tg = _near_foe(who, 12.0)
	var from = who.global_position
	var f = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	var to = (tg.global_position - (tg.global_position - from).normalized() * 0.9) if tg else from + f * 7.0
	to.y = Game.ground_height(to.x, to.z)
	if tg and who.has_method("face_dir") and "facing" in who:
		var d = tg.global_position - from
		who.facing = atan2(-d.x, -d.z)
	var rai = Color(0.68, 0.86, 1.0)
	var n = 6
	for k in n:
		who.get_tree().create_timer(dur * k / n).timeout.connect(func():
			if not is_instance_valid(who):
				return
			var q = from.lerp(to, float(k) / n) + (to - from).normalized().cross(Vector3.UP) * 0.35
			q.y = Game.ground_height(q.x, q.z)
			VFX.cracks(q, 1.0, Color(0.12, 0.12, 0.16, 0.85), 2.0)
			VFX.debris(q, Color(0.55, 0.5, 0.42), 4, 3.5, 0.18)
			VFX.bolt(q + Vector3.UP * 0.1, q + Vector3(randf_range(-0.8, 0.8), randf_range(0.3, 1.0), randf_range(-0.8, 0.8)), rai, 0.1, 0.2, 1))
	FX.speed_lines(from + Vector3.UP, (to - from).normalized())
	var tw = who.create_tween()
	tw.tween_property(who, "global_position", to, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Chakra Neşteri: parmak uçlarından titreşen mavi bıçak (p_chakura_no_mesu ile aynı yapı), dur sn sonra söner
static func _scalpel(who: Node3D, right: bool, dur: float) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var ba = pj.bone_attach(who, "RightHand" if right else "LeftHand")
	if ba == null:
		return
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.012, 0.22, 0.05)
	mi.mesh = bm
	mi.position = Vector3(0, 0.15, 0.02)
	mi.material_override = VFX.mat_bolt(Color(0.6, 0.9, 1.0), 1.2)
	ba.add_child(mi)
	pj._hand_glow(ba, "blade", Color(0.35, 0.65, 1.0))
	who.get_tree().create_timer(dur).timeout.connect(func():
		if is_instance_valid(ba):
			ba.queue_free())


## Ōkashō: yumrukta toplanan chakra (beyaz-mavi parıltı), dur sn
static func _tip_fist(who: Node3D, dur: float) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var ba = pj.bone_attach(who, "RightHand")
	if ba == null:
		return
	pj._hand_glow(ba, "palm", Color(0.55, 0.85, 1.0))
	who.get_tree().create_timer(dur).timeout.connect(func():
		if is_instance_valid(ba):
			ba.queue_free())


## Shukaku kısmi dönüşüm: sağ kolun çevresinde dönen kum taneleri (kemiğe bağlı) — kol kum pençeye döner
static func _sand_arm(who: Node3D, dur: float) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	for bone in ["RightLowerArm", "RightHand"]:
		var ba = pj.bone_attach(who, bone)
		if ba == null:
			continue
		FX.burst(Vector3(0, 0.1, 0), {"amount": 40, "life": 0.5, "explosive": 0.0, "local": true, "parent": ba, "tex": FX.tex_soft, "add": false, "size": 0.16, "radius": 0.14,
			"vmin": 0.1, "vmax": 0.4, "spread": 180.0, "orbit": 1.5, "colors": [Color(0.9, 0.75, 0.5, 0.95), Color(0.78, 0.62, 0.4, 0.7), Color(0.7, 0.55, 0.35, 0.0)]}).one_shot = false
		who.get_tree().create_timer(dur).timeout.connect(func():
			if is_instance_valid(ba):
				ba.queue_free())


## Kedi pençesi izi: üç paralel mavi alev kesiği (çapraz; right = sağ üstten sol alta)
static func _cat_claw(who: Node3D, at: Vector3, f: Vector3, right: bool, r: float, col := Color(0.25, 0.5, 1.0, 0.85)) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var am = VFX.asset("slash_arc")
	if am == null:
		for k in 3:
			pj._arc_cut(at + Vector3.UP * (k - 1) * 0.22, f, 60.0 if right else -60.0, -50.0 if right else 50.0, Color(0.12, 0.3, 1.0), r)
		return
	# hilal kesik gövdesi + oyunun mavi Matatabi alevi malzemesi (beyaz parlama değil, mavi alev)
	var mat = StandardMaterial3D.new()   # düz mavi alev rengi (parlama malzemesi bloom'da beyaza dönüyordu)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = Color(col.r * 0.4, col.g * 0.4, col.b * 0.9)
	mat.emission_energy_multiplier = 0.6
	for k in 3:
		var arc = MeshInstance3D.new()
		arc.mesh = am
		arc.material_override = mat
		arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		who.get_tree().current_scene.add_child(arc)
		arc.global_position = at + Vector3.UP * (k - 1) * 0.22
		arc.global_rotation.y = atan2(-f.x, -f.z)
		arc.rotate_object_local(Vector3.FORWARD, deg_to_rad(35.0 if right else -35.0))
		arc.scale = Vector3(r * 0.7, r, r * 0.6)
		var tw = arc.create_tween()
		tw.tween_interval(k * 0.03)
		tw.tween_property(arc, "scale", Vector3(r * 0.8, r * 0.25, r * 1.1), 0.3).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(arc.queue_free)


## Rōshi: yumruğu saran erimiş lav (kemiğe bağlı pürüzlü lav kütlesi + damlalar), dur sn
static func _lava_fist(who: Node3D, bone: String, dur: float) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var ba = pj.bone_attach(who, bone)
	if ba == null:
		return
	var lb = MB.new()
	lb.add("boulder", Vector3.ZERO, Vector3.ONE, Color.WHITE, Vector3.ZERO, 2)
	var mi = MeshInstance3D.new()
	mi.mesh = lb.build(null)
	mi.material_override = VFX.lava_mat("molten")
	mi.position = Vector3(0, 0.08, 0.02)
	mi.scale = Vector3(0.085, 0.1, 0.085)
	ba.add_child(mi)
	who.get_tree().create_timer(dur).timeout.connect(func():
		if is_instance_valid(ba):
			ba.queue_free())


## Han: Kōjōki — sırttan buhar jeti, kısa roket atılış (en yakın rakibe)
static func _steam_rocket(who: Node3D, dur: float) -> void:
	var tg = _near_foe(who, 10.0)
	var from = who.global_position
	var f = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	var to = (tg.global_position - (tg.global_position - from).normalized() * 1.0) if tg else from + f * 6.0
	to.y = Game.ground_height(to.x, to.z)
	for k in 4:
		who.get_tree().create_timer(dur * k / 4.0).timeout.connect(func():
			if is_instance_valid(who):
				BijuuArts._steam_cloud(who.global_position + Vector3.UP * 1.2 - who.face_dir() * 0.6, 0.25, 0.7, 0.7))
	FX.speed_lines(from + Vector3.UP, (to - from).normalized())
	who.create_tween().tween_property(who, "global_position", to, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Utakata: hedefi içine alan köpük balon (Saiken baloncuğu malzemesi), dur sn bağlı kalır, sonra patlar
static func _bubble_trap(who: Node3D, tg: Node3D, dur: float) -> void:
	var bub = MeshInstance3D.new()
	bub.mesh = VFX._sphere(0.5, 20, 10)
	bub.material_override = BijuuArts._glass(Color(0.85, 1.0, 0.95), 0.4, 0.25)
	tg.add_child(bub)
	var h = float(tg.get("height")) if tg.get("height") != null else 1.8
	bub.position = Vector3.UP * h * 0.5
	bub.scale = Vector3.ONE * 0.2
	var tw = bub.create_tween()
	tw.tween_property(bub, "scale", Vector3.ONE * h * 1.3, 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(dur)
	tw.tween_callback(func():
		if is_instance_valid(bub):
			VFX.puffs(bub.global_position, {"amount": 14, "life": 0.6, "size": 0.6, "radius": 0.6, "vmin": 3, "vmax": 7, "gravity": Vector3(0, -10, 0), "colors": [Color(0.95, 1, 1, 1), Color(0.75, 0.95, 0.9, 0)]})
			bub.queue_free())
	if tg.has_method("apply_status"):
		tg.apply_status("bind", dur)
	Combat.popup_text(tg.global_position + Vector3.UP * (h + 0.8), "KÖPÜĞE HAPSOLDU!", Color(0.75, 0.95, 0.9))


## Fū: sırttan dört şeffaf böcek kanadı (Chōmei kanat malzemesi), hızla çırpar, dur sn
static func _bug_wings(who: Node3D, dur: float) -> void:
	var mat = BijuuArts._glass(Color(0.55, 0.85, 1.0), 0.45, 0.6)
	var wings = []
	for k in 4:
		var piv = Node3D.new()
		who.add_child(piv)
		piv.position = Vector3(0, 1.35 - (k / 2) * 0.25, 0.18)
		piv.rotation.y = (who.get("facing") if who.get("facing") != null else 0.0)
		var wing = MeshInstance3D.new()
		wing.mesh = VFX._sphere(0.5, 10, 5)
		wing.material_override = mat
		var sx = -1.0 if k % 2 == 0 else 1.0
		wing.position = Vector3(sx * 0.6, 0.12, 0.15)
		wing.scale = Vector3(1.1, 0.04, 0.4) * (1.0 - (k / 2) * 0.25)
		piv.add_child(wing)
		wings.append(piv)
	var n = int(dur / 0.04)
	for t in n:
		who.get_tree().create_timer(t * 0.04).timeout.connect(func():
			for i in wings.size():
				var w: Node3D = wings[i]
				if is_instance_valid(w):
					w.rotation.z = (0.35 + sin(t * 1.1 + i) * 0.45) * (1.0 if i % 2 == 0 else -1.0))
	who.get_tree().create_timer(dur).timeout.connect(func():
		for w in wings:
			if is_instance_valid(w):
				w.queue_free())


## Matatabi tırnakları: parmak uçlarında mavi alev (oyunun "blue" ateş malzemesi), dur sn
static func _blue_claws(who: Node3D, right: bool, left: bool, dur: float) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var bones = []
	if right:
		bones.append("RightHand")
	if left:
		bones.append("LeftHand")
	for bone in bones:
		var ba = pj.bone_attach(who, bone)
		if ba == null:
			continue
		for k in 3:
			var cm = CylinderMesh.new()
			cm.top_radius = 0.0
			cm.bottom_radius = 0.025
			cm.height = 0.28
			var mi = MeshInstance3D.new()
			mi.mesh = cm
			mi.material_override = VFX.mat_fire("blue", 3.0, 2.0, 0.2, 1.6, 0.05)
			mi.position = Vector3((k - 1) * 0.035, 0.2, 0.03)
			ba.add_child(mi)
		who.get_tree().create_timer(dur).timeout.connect(func():
			if is_instance_valid(ba):
				ba.queue_free())


## Üç bıçaklı tırpan: oyunun gerçek silah modeli (SFProps hayran modeli, yoksa CharacterModel prosedürel) — kabza (0,0,0), sap +Z
static func _scythe_node() -> Node3D:
	var n = SFProps.weapon_node("uc_tirpan")
	if n != null:
		return n
	var mi = MeshInstance3D.new()
	mi.mesh = CharacterModel.weapon_mesh("uc_tirpan")
	mi.material_override = Props.toon()
	return mi


## Jashin kara mızrağı: elde geri çekilebilir siyah sivri mızrak (p_jashin_kazik ile aynı biçim), dur sn
static func _jashin_spike(who: Node3D, dur: float) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var ba = pj.bone_attach(who, "RightHand")
	if ba == null:
		return
	var spike = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.035
	cm.height = 1.2
	spike.mesh = cm
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.08, 0.08, 0.1)
	m.metallic = 0.6
	m.roughness = 0.3
	spike.material_override = m
	spike.position = Vector3(0, 0.45, 0.02)
	ba.add_child(spike)
	spike.scale = Vector3(1, 0.05, 1)
	spike.create_tween().tween_property(spike, "scale", Vector3.ONE, 0.12)   # geri çekilmiş halden uzar
	who.get_tree().create_timer(dur).timeout.connect(func():
		if is_instance_valid(ba):
			ba.queue_free())


## Jashin çemberi: kan rengi daire + içinde üçgen (p_jashin_kurban'ın küçüğü), dur sn yerde kalır
static func _jashin_circle(who: Node3D, at: Vector3, dur: float) -> void:
	var red = Color(0.75, 0.1, 0.12)
	var b = MB.new()
	b.add("cyl", Vector3(0, 0.02, 0), Vector3(2.4, 0.02, 2.4), red, Vector3.ZERO, 32)
	b.add("cyl", Vector3(0, 0.03, 0), Vector3(2.1, 0.02, 2.1), Color(0.5, 0.45, 0.4), Vector3.ZERO, 32)
	for k in 3:
		var a1 = k * TAU / 3.0 + PI * 0.5
		var a2 = (k + 1) * TAU / 3.0 + PI * 0.5
		var p1 = Vector3(cos(a1), 0, sin(a1)) * 1.0
		var p2 = Vector3(cos(a2), 0, sin(a2)) * 1.0
		b.add("box", (p1 + p2) * 0.5 + Vector3.UP * 0.04, Vector3(0.08, 0.02, p1.distance_to(p2)), red, Vector3(0, rad_to_deg(atan2((p2 - p1).x, (p2 - p1).z)), 0))
	var mi = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.mesh = b.build(mat)
	who.get_tree().current_scene.add_child(mi)
	mi.global_position = at + Vector3.UP * 0.05
	mi.scale = Vector3(0.05, 1, 0.05)
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, 0.3)
	tw.tween_interval(dur)
	tw.tween_property(mi, "scale", Vector3(0.05, 1, 0.05), 0.3)
	tw.tween_callback(mi.queue_free)


## Jashin lanet bağı: kendine saplarsın — bağlıysa (çemberdeyken) rakip aynı yarayı alır. Bedel: kendi canının bir kısmı.
static func _jashin_self(who: Node3D, dmg: float, mul: float, cost: float, txt: String) -> bool:
	var ln = who.get_meta("jashin_link", [])
	var now = Time.get_ticks_msec() / 1000.0
	if ln.is_empty() or now > float(ln[1]) or (who.global_position - (ln[2] as Vector3)).length() > 1.8:
		return false
	var e = instance_from_id(int(ln[0]))
	if e == null or not is_instance_valid(e) or e.is_dead():
		return false
	if who.get("hp") != null and who.get("max_hp") != null:
		who.hp = maxf(1.0, who.hp - who.max_hp * cost)
	var blood = Color(0.7, 0.05, 0.05)
	FX.hit_spark(who.global_position + Vector3.UP * 1.0, blood, 0.6)
	FX.hit_spark(e.global_position + Vector3.UP * 1.1, blood, 1.0)
	e.take_hit({"dmg": dmg * mul, "knock": 0.0, "kind": "heavy", "attacker": who, "pierce_guard": true, "true_dmg": true, "hitstop": 0.1})
	Combat.popup_text(e.global_position + Vector3.UP * 2.4, txt, Color(0.85, 0.15, 0.15))
	_shake(who, 0.35)
	return true


## Hiraishin işaretleri (yere saplı kunailer): [{pos, until, node}]
static func _hira_marks(who: Node3D) -> Array:
	var now = Time.get_ticks_msec() / 1000.0
	var mk: Array = who.get_meta("style_kunai", [])
	mk = mk.filter(func(m): return now < float(m["until"]))
	who.set_meta("style_kunai", mk)
	return mk


static func _hira_mark_near(who: Node3D, p: Vector3) -> Vector3:
	var best = Vector3.INF
	var bd = 6.0
	for m in _hira_marks(who):
		var d = (m["pos"] as Vector3).distance_to(p)
		if d < bd:
			bd = d
			best = m["pos"]
	return best


## Üç uçlu kunai fırlatır; stick: yere saplanıp 8 sn işaret olarak kalır
static func _hira_throw(who: Node3D, from: Vector3, to: Vector3, dur: float, stick: bool) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var k = pj._hira_kunai()
	who.get_tree().current_scene.add_child(k)
	k.global_position = from
	if from.distance_to(to) > 0.05:
		k.look_at(to, Vector3.UP if absf((to - from).normalized().y) < 0.95 else Vector3.FORWARD)
		k.rotate_object_local(Vector3.UP, PI)   # bıçak ucu (+Z) gidiş yönünde
	var tw = k.create_tween()
	tw.tween_property(k, "global_position", to, dur)
	if stick:
		var mk: Array = who.get_meta("style_kunai", [])
		mk.append({"pos": Vector3(to.x, to.y - 0.15, to.z), "until": Time.get_ticks_msec() / 1000.0 + 8.0})
		who.set_meta("style_kunai", mk.slice(maxi(0, mk.size() - 6)))
		tw.tween_callback(func(): FX.hit_spark(to, Color(1.0, 0.9, 0.5), 0.3))
		tw.tween_interval(8.0)
	else:
		tw.tween_interval(0.25)
	tw.tween_callback(k.queue_free)


## Sarı flaşla bir noktaya ışınlan (yerde ya da havada); tg verilirse ona dön
static func _hira_hop(who: Node3D, p: Vector3, tg: Node3D, ground := true) -> void:
	var pj = PathJutsu.get_pinst()
	if pj:
		pj._yellow_flash(who.global_position + Vector3.UP)
	var to = p
	if ground:
		to.y = Game.ground_height(to.x, to.z)
	who.global_position = to
	if who is CharacterBody3D:
		who.velocity = Vector3.ZERO
	if pj:
		pj._yellow_flash(to + Vector3.UP)
	if tg and is_instance_valid(tg) and "facing" in who:
		var d = tg.global_position - to
		d.y = 0
		if d.length() > 0.01:
			who.facing = atan2(-d.x, -d.z)
			if who.get("model"):
				who.model.rotation.y = who.facing
	Sfx.play("whoosh", to, 1.6, 0.5)


static func _near_foe_at(who: Node3D, p: Vector3, r: float) -> Node3D:
	var best: Node3D = null
	var bd = r
	for e in who.get_tree().get_nodes_in_group("fighters"):
		if e == who or not Combat.hostile(who, e) or e.is_dead():
			continue
		var d = e.global_position.distance_to(p)
		if d < bd:
			bd = d
			best = e
	return best


static func _near_foe(who: Node3D, r: float) -> Node3D:
	var best: Node3D = null
	var bd = r
	for f in who.get_tree().get_nodes_in_group("fighters"):
		if f == who or not Combat.hostile(who, f) or f.is_dead():
			continue
		var d = f.global_position.distance_to(who.global_position)
		if d < bd:
			bd = d
			best = f
	return best


## Jūken: her isabet tenketsuya chakra akıtıp kapatır — rakibin chakrası tıkanır (oyuncu/düşman aynı)
static func _tenketsu(who: Node3D, h: Node3D, i: int) -> void:
	if h == null or not is_instance_valid(h) or h.get("chakra") == null:
		return
	var mx = float(h.get("max_chakra")) if h.get("max_chakra") != null else 100.0
	var k = 0.07 if i == 4 else 0.035
	h.chakra = maxf(0.0, float(h.chakra) - mx * k)
	FX.hit_spark(h.global_position + Vector3.UP * 1.1, Color(0.7, 0.85, 1.0), 0.6)
	if i == 4 and h.has_method("apply_status"):
		h.apply_status("slow", 1.2)   # chakra noktaları kapanınca beden ağırlaşır


## Vuruş anı görselleri + alan/mermi (isabetten bağımsız)
static func _style_strike(id: String, i: int, who: Node3D, dmg: float, f: Vector3, side: Vector3) -> void:
	var at = who.global_position + Vector3.UP * 1.1 + f * 1.1
	Sfx.play_style(id, i, at)   # dövüş tarzının kendi sesi (böcek, kum, kemik, Mokuton toprağı, kâğıt...)
	match id:
		"style_juken":
			FX.hit_spark(at, Color(0.75, 0.88, 1.0), 0.7)   # avuçtan çıkan chakra
			if i == 5:   # Hakke Kūshō: çift avuçtan ileri giden hava basıncı
				WindFX.gust(who.global_position + Vector3.UP * 1.1, f, 7.0, 2.2, {})
				for d in [2.5, 4.5]:
					Combat.hit_sphere(who, who.global_position + Vector3.UP * 1.0 + f * d, 1.6, _kinfo(dmg, 0.7, {"element": "", "knock": 16.0, "kind": "heavy", "melee": true}))
		"style_akimichi":
			if i == 4:   # iki dev yumruk yere: şok dalgası
				var g = who.global_position + f * 1.6
				g.y = Game.ground_height(g.x, g.z) + 0.05
				VFX.shockwave(g + Vector3.UP * 0.1, Color(0.75, 0.68, 0.55), 6.0, 0.35, true)
				VFX.cracks(g, 3.5)
				Combat.hit_sphere(who, g + Vector3.UP * 0.5, 2.6, _kinfo(dmg, 0.6, {"element": "", "knock": 6.0, "launch": 5.0, "kind": "heavy", "melee": true}))
				_shake(who, 0.4)
			elif i == 3 or i == 5:
				_shake(who, 0.25)
				FX.hit_spark(at + f * 0.8, Color(1.0, 0.95, 0.85), 1.2)
		"style_inuzuka":
			var pj = PathJutsu.get_pinst()
			if pj:   # üç pençe izi
				for k in 3:
					pj._arc_cut(at + Vector3.UP * (k - 1) * 0.12, f, -50.0, 50.0, Color(0.9, 0.88, 0.8), 1.2)
		"style_uchiha":
			if i == 4:   # topuk inişi: yer çatlar
				var g = who.global_position + f * 1.2
				g.y = Game.ground_height(g.x, g.z) + 0.05
				VFX.cracks(g, 2.4)
				_shake(who, 0.3)
			elif i == 5:   # Katon: ağızdan kısa ateş seli (orta menzil)
				var o = who.global_position + Vector3.UP * 1.55 + f * 0.4
				for k in 6:
					who.get_tree().create_timer(k * 0.05).timeout.connect(func():
						if not is_instance_valid(who):
							return
						var fb = VFX.fireball(0.6 + k * 0.18)
						who.get_tree().current_scene.add_child(fb)
						fb.global_position = o
						var tw = fb.create_tween()
						tw.tween_property(fb, "global_position", o + f * (1.5 + k * 0.8) + Vector3.DOWN * 0.3, 0.3)
						tw.tween_property(fb, "scale", Vector3.ONE * 0.05, 0.25)
						tw.tween_callback(fb.queue_free))
				for d in [2.0, 3.8, 5.4]:
					Combat.hit_sphere(who, who.global_position + Vector3.UP * 1.1 + f * d, 1.4, _kinfo(dmg, 0.55, {"element": "katon", "burn": 2.5, "knock": 4.0, "kind": "heavy", "melee": true}))
		"style_hozuki":
			var tg = _near_foe(who, 12.0)
			var hand = who.global_position + Vector3.UP * 1.35 + f * 0.6
			if i == 0 or i == 1 or i == 5:   # Mizudeppō: su mermisi (5: iki elle büyük)
				_water_bullet(who, hand + side * (0.2 if i == 1 else -0.2), tg, dmg * (1.6 if i == 5 else 0.8), 0.22 if i < 5 else 0.5)
			elif i == 2 or i == 4:   # Mizu Muchi: hedefe uzanan dalgalı su kırbacı
				_water_whip(who, tg, dmg * 0.9, i == 4)
			elif i == 3:   # Gōsuiwan: şişen kasla yumruk (ref hozuki_2: su değil, kas) — darbe halkası + su sıçrar
				VFX.shockwave(at + f * 0.4, Color(0.9, 0.95, 1.0), 3.0, 0.22, false, f)
				WaterArt.spray(at + f * 0.3, 0.7, f, 35.0, 1.2)
				_shake(who, 0.3)
		"style_aburame":
			var tg = _near_foe(who, 16.0)
			match i:
				0, 1:
					_swarm(who, tg, dmg * 0.8, 0.6, side * (0.25 if i == 1 else -0.25))
				2:
					_swarm(who, tg, dmg * 0.6, 0.55, side * 0.3)
					_swarm(who, tg, dmg * 0.6, 0.55, side * -0.3)
				3:   # böcek sütunu: hedefin altından fışkırır
					if tg:
						var p = tg.global_position
						for k in 3:
							who.get_tree().create_timer(0.1 + k * 0.12).timeout.connect(func():
								if is_instance_valid(who):
									_swarm_cloud(p + Vector3.UP * (0.5 + k * 0.8), 0.9, 0.5))
						Combat.hit_sphere(who, p + Vector3.UP, 1.6, _kinfo(dmg, 1.0, {"element": "", "knock": 2.0, "launch": 5.0, "kind": "heavy", "kikai": true}))
						_kikai_drain(who, tg, 0.04)
				4:   # böcek küresi: yavaş büyük sürü
					_swarm(who, tg, dmg * 1.4, 1.2, Vector3.ZERO, 14.0)
				5:   # Kikaichū Kyōshū: hedefi yutan dev sürü
					if tg:
						var p2 = tg.global_position
						for k in 6:
							who.get_tree().create_timer(k * 0.12).timeout.connect(func():
								if is_instance_valid(who):
									_swarm_cloud(p2 + Vector3.UP * 1.0, 1.4, 0.6))
						Combat.hit_sphere(who, p2 + Vector3.UP, 2.4, _kinfo(dmg, 1.3, {"element": "", "knock": 1.0, "kind": "heavy"}))
						_kikai_drain(who, tg, 0.14)
		"style_yilan":
			var tg = _near_foe(who, 12.0)
			var pjy = PathJutsu.get_pinst()
			if pjy == null:
				return
			var aimy = tg.global_position if tg else who.global_position + f * 6.0
			match i:
				0, 1, 2:   # Sen'ei Jashu / Tajashu: yenden yılanlar (gerçek SleeveSnake)
					var n = 4 if i == 2 else 2
					var right = i != 1
					var sns = []
					for k in n:
						var sn = pjy.sleeve_snake(who, right, tg, k, n, f * 7.0)
						sns.append(sn)
						sn.extend(0.25 + k * 0.03)
					who.get_tree().create_timer(0.9).timeout.connect(func():
						for sn2 in sns:
							if is_instance_valid(sn2):
								sn2.retract(0.25))
					if tg and tg.global_position.distance_to(who.global_position) < 8.0:
						who.get_tree().create_timer(0.3).timeout.connect(func():
							if is_instance_valid(who) and is_instance_valid(tg):
								Combat.hit_sphere(who, tg.global_position + Vector3.UP, 1.2, _kinfo(dmg, 0.8 if i < 2 else 1.0, {"element": "", "knock": 0.0, "kind": "light", "poison": 3.0, "bind": 1.0 if i == 2 else 0.0})))
				3:   # Kusanagi: ağızdan kılıç uzayıp saplanır
					var mo = who.global_position + Vector3.UP * 1.55 + f * 0.25
					var mi = MeshInstance3D.new()
					mi.mesh = CharacterModel.weapon_mesh("kusanagi")
					who.get_tree().current_scene.add_child(mi)
					mi.global_position = mo
					mi.look_at(mo + f, Vector3.UP)
					mi.rotate_object_local(Vector3.UP, PI)
					mi.scale = Vector3(1, 1, 0.2)
					var tw = mi.create_tween()
					tw.tween_property(mi, "scale", Vector3(1, 1, 4.0), 0.12)
					tw.tween_interval(0.25)
					tw.tween_property(mi, "scale", Vector3(1, 1, 0.1), 0.12)
					tw.tween_callback(mi.queue_free)
					Combat.hit_zone(who, who.global_position, f, 4.6, 10.0, 2.2, _kinfo(dmg, 1.4, {"element": "", "knock": 4.0, "kind": "heavy", "bleed": 3.0, "pierce_guard": true}))
				4:   # yılan atılışı: beden esneyip ısırır
					var to = aimy - f * 0.8
					to.y = Game.ground_height(to.x, to.z)
					FX.speed_lines(who.global_position + Vector3.UP, f)
					who.create_tween().tween_property(who, "global_position", to, 0.14)
					who.get_tree().create_timer(0.14).timeout.connect(func():
						if is_instance_valid(who):
							Combat.hit_sphere(who, who.global_position + Vector3.UP * 1.0 + f * 0.8, 1.2, _kinfo(dmg, 1.1, {"element": "", "knock": 5.0, "kind": "heavy", "poison": 3.0, "melee": true})))
				5:   # Mandara: yerden yılan sürüsü fışkırıp hedefi yutar (gerçek yılan modeli)
					var g = Vector3(aimy.x, Game.ground_height(aimy.x, aimy.z), aimy.z)
					for k in 3:
						var a = TAU * k / 3.0
						var q = g + Vector3(cos(a), 0, sin(a)) * 1.6
						who.get_tree().create_timer(k * 0.06).timeout.connect(func():
							var snk: Node3D = SummonModels.build("snake_swarm", 1.6, 1.0)["root"]
							who.get_tree().current_scene.add_child(snk)
							snk.global_position = q - Vector3.UP * 1.5
							snk.look_at(Vector3(g.x, q.y, g.z), Vector3.UP)
							VFX.debris(q, Color(0.5, 0.45, 0.38), 6, 4.0, 0.25)
							var tw2 = snk.create_tween()
							tw2.tween_property(snk, "global_position", q, 0.18)
							tw2.tween_interval(0.7)
							tw2.tween_property(snk, "global_position", q - Vector3.UP * 2.0, 0.25)
							tw2.tween_callback(snk.queue_free))
					Combat.hit_sphere(who, g + Vector3.UP, 2.4, _kinfo(dmg, 1.9, {"element": "", "knock": 3.0, "launch": 4.0, "kind": "heavy", "poison": 4.0, "bind": 1.0}))
					_shake(who, 0.4)
		"style_gama":
			var tg = _near_foe(who, 12.0)
			var pjg = PathJutsu.get_pinst()
			if pjg == null:
				return
			var aimg = tg.global_position if tg else who.global_position + f * 6.0
			var mouthg = who.global_position + Vector3.UP * 1.55 + f * 0.4
			match i:
				0:   # saç iğneleri: başın çevresinden öne iğne yağmuru
					var hair: Color = who.model.look.get("hair", Color(0.9, 0.9, 0.88)) if who.get("model") else Color(0.9, 0.9, 0.88)
					var head = who.global_position + Vector3.UP * 1.75
					for k in 14:
						var dirv = (f + Vector3(randf_range(-0.25, 0.25), randf_range(-0.12, 0.08), randf_range(-0.25, 0.25))).normalized()
						var nd = MeshInstance3D.new()
						var cm = CylinderMesh.new()
						cm.top_radius = 0.008
						cm.bottom_radius = 0.014
						cm.height = 0.45
						nd.mesh = cm
						var nmat = StandardMaterial3D.new()
						nmat.albedo_color = hair.lightened(0.15)
						nd.material_override = nmat
						who.get_tree().current_scene.add_child(nd)
						var st = head + Vector3(randf_range(-0.25, 0.25), randf_range(-0.1, 0.2), randf_range(-0.25, 0.25))
						nd.global_position = st
						nd.look_at(st + dirv, Vector3.UP)
						nd.rotate_object_local(Vector3.RIGHT, PI * 0.5)
						var tw3 = nd.create_tween()
						tw3.tween_interval(k * 0.01)
						tw3.tween_property(nd, "global_position", st + dirv * 9.0, 0.2)
						tw3.tween_callback(nd.queue_free)
					Combat.hit_zone(who, who.global_position, f, 8.0, 18.0, 2.4, _kinfo(dmg, 0.9, {"element": "", "knock": 2.0, "kind": "light", "bleed": 2.0}))
				1:   # savaş kurbağası hedefe zıplayıp ezer (gerçek model)
					var toad: Node3D = SummonModels.build("toad_small", 1.2, 1.0)["root"]
					who.get_tree().current_scene.add_child(toad)
					var st2 = who.global_position + side * 1.2
					toad.global_position = st2
					toad.look_at(Vector3(aimg.x, st2.y, aimg.z), Vector3.UP)
					var tw4 = toad.create_tween()
					tw4.tween_method(func(u: float):
						if is_instance_valid(toad):
							toad.global_position = st2.lerp(aimg, u) + Vector3.UP * sin(u * PI) * 2.5, 0.0, 1.0, 0.4)
					tw4.tween_callback(func():
						FX.impact(aimg, Color(1, 0.8, 0.5), 0.8)
						if is_instance_valid(who):
							Combat.hit_sphere(who, aimg + Vector3.UP * 0.6, 1.8, _kinfo(dmg, 1.3, {"element": "", "knock": 6.0, "launch": 3.0, "kind": "heavy"})))
					tw4.tween_interval(0.4)
					tw4.tween_callback(toad.queue_free)
				2:   # Gamayudan: kurbağa yağı akışı + kaygan gölet
					var oil = VFX.mat_water(Color(0.45, 0.32, 0.08), Color(0.78, 0.6, 0.22), Color(0.95, 0.82, 0.4), Vector3(0, 1, 0), 0.95, 0.8, 0.12)
					pjg.stream_fx(mouthg, (f - Vector3.UP * 0.1).normalized(), 7.0, 1.0, oil, 0.35, func(end):
						VFX.splash(Vector3(end.x, Game.ground_height(end.x, end.z), end.z), 1.4))
					who.set_meta("toad_oil", [who.global_position + f * 5.0, Time.get_ticks_msec() / 1000.0 + 5.0])
					Combat.hit_zone(who, who.global_position, f, 7.0, 18.0, 2.4, _kinfo(dmg, 0.5, {"element": "suiton", "knock": 4.0, "kind": "light", "slow": 2.5}))
				3:   # Katon: yağ tutuşur — yağ varsa alev seli büyük
					var oiled = who.has_meta("toad_oil") and Time.get_ticks_msec() / 1000.0 < float(who.get_meta("toad_oil")[1])
					pjg.fire_stream(mouthg + f * 0.4, f, 9.0 if oiled else 6.0, 2.8 if oiled else 1.8, 8)
					Combat.hit_zone(who, who.global_position, f, 9.0 if oiled else 6.0, 20.0, 2.6, _kinfo(dmg, 1.8 if oiled else 1.0, {"element": "katon", "knock": 6.0, "kind": "heavy", "burn": 3.0}))
					who.remove_meta("toad_oil")
				4:   # Hari Jizō: saç kalkanı, çevreye iğne halkası
					var hair2: Color = who.model.look.get("hair", Color(0.9, 0.9, 0.88)) if who.get("model") else Color(0.9, 0.9, 0.88)
					VFX.shockwave(who.global_position + Vector3.UP * 0.9, hair2.lightened(0.3), 4.5, 0.3, true)
					Combat.hit_sphere(who, who.global_position + Vector3.UP, 3.0, _kinfo(dmg, 1.1, {"element": "", "knock": 9.0, "kind": "heavy", "bleed": 2.0}))
					if who is Player:
						who.combat.invuln = maxf(who.combat.invuln, 0.35)
				5:   # Ōdama Rasengan: büyük küre hedefe
					var to2 = (tg.global_position + Vector3.UP) if tg and tg.global_position.distance_to(who.global_position) < 5.0 else who.global_position + Vector3.UP + f * 1.6
					VFX.shockwave(to2, Color(0.6, 0.85, 1.0), 4.0, 0.3, false, f)
					Combat.hit_sphere(who, to2, 1.8, _kinfo(dmg, 2.4, {"element": "", "knock": 16.0, "launch": 4.0, "kind": "heavy"}))
					_shake(who, 0.6)
		"style_chidori":
			var tg = _near_foe(who, 16.0)
			var rai = Color(0.68, 0.86, 1.0)
			var hand = who.global_position + Vector3.UP * 1.2 + f * 0.7
			var aimc = (tg.global_position + Vector3.UP) if tg else hand + f * 10.0
			match i:
				0:   # Chidori darbesi: avuçtan öne dallanan kısa şimşek
					for k in 3:
						VFX.bolt(hand, hand + f * 2.6 + Vector3(randf_range(-0.5, 0.5), randf_range(-0.4, 0.5), randf_range(-0.5, 0.5)), rai, 0.14, 0.2, 2)
					VFX.star(hand + f * 0.6, Color(0.9, 0.96, 1.0), 1.6, 0.12)
					Combat.hit_zone(who, who.global_position, f, 3.0, 30.0, 2.2, _kinfo(dmg, 1.2, {"element": "raiton", "knock": 5.0, "kind": "heavy", "melee": true, "stun": 0.3}))
				1:   # Chidori Senbon: sol elden şimşek iğne yelpazesi
					var lh = who.global_position + Vector3.UP * 1.3 - side * 0.3 + f * 0.5
					var dv = (aimc - lh).normalized()
					for k in 7:
						var dd = dv.rotated(Vector3.UP, deg_to_rad((k - 3) * 5.0))
						who.get_tree().create_timer(k * 0.012).timeout.connect(func():
							VFX.bolt(lh, lh + dd * 11.0, Color(0.85, 0.94, 1.0), 0.04, 0.16, 0))
					Combat.hit_zone(who, who.global_position, dv, 11.0, 18.0, 2.4, _kinfo(dmg, 0.8, {"element": "raiton", "knock": 1.0, "kind": "light", "stun": 0.4}))
				2:   # Chidori Eisō: avuçtaki şimşek mızrağa uzar, delip geçer
					var end = hand + (aimc - hand).normalized() * 10.0
					var spear = MeshInstance3D.new()
					var cm = CylinderMesh.new()
					cm.top_radius = 0.0
					cm.bottom_radius = 0.1
					cm.height = 10.0
					spear.mesh = cm
					spear.material_override = VFX.mat_bolt(rai, 2.6)
					who.get_tree().current_scene.add_child(spear)
					spear.global_position = (hand + end) * 0.5
					spear.look_at(end, Vector3.UP)
					spear.rotate_object_local(Vector3.RIGHT, -PI * 0.5)
					spear.scale = Vector3(1, 0.05, 1)
					var tw = spear.create_tween()
					tw.tween_property(spear, "scale", Vector3.ONE, 0.07)
					tw.tween_interval(0.22)
					tw.tween_property(spear, "scale", Vector3(0.01, 1, 0.01), 0.12)
					tw.tween_callback(spear.queue_free)
					VFX.bolt(hand, end, rai, 0.16, 0.25, 3)
					Combat.hit_zone(who, who.global_position, (aimc - hand).normalized(), 10.0, 6.0, 2.4, _kinfo(dmg, 1.5, {"element": "raiton", "knock": 7.0, "kind": "heavy", "stun": 0.6, "pierce_guard": true}))
				3:   # Chidori Nagashi: bedenden her yöne akım
					var c0 = who.global_position + Vector3.UP
					for k in 10:
						var a = TAU * k / 10.0 + randf_range(-0.2, 0.2)
						VFX.bolt(c0 + Vector3.UP * randf_range(-0.4, 0.6), who.global_position + Vector3(cos(a) * 3.8, randf_range(0.1, 1.8), sin(a) * 3.8), rai, 0.12, 0.25, 2)
					VFX.shockwave(c0, rai, 7.0, 0.3, true)
					VFX.cracks(Vector3(who.global_position.x, Game.ground_height(who.global_position.x, who.global_position.z), who.global_position.z), 2.6, Color(0.1, 0.12, 0.2, 0.8), 3.0)
					Combat.hit_sphere(who, c0, 3.8, _kinfo(dmg, 1.1, {"element": "raiton", "knock": 7.0, "kind": "heavy", "stun": 1.2}))
					Sfx.play("chidori", c0, 0.9)
				4:   # Chidori Tōshi: işaret parmağından ince, uzun delici şimşek
					var tip = who.global_position + Vector3.UP * 1.4 + f * 0.9
					var dt = (aimc - tip).normalized()
					VFX.bolt(tip, tip + dt * 16.0, Color(0.9, 0.97, 1.0), 0.07, 0.3, 1)
					FX.hit_spark(tip, Color(0.9, 0.97, 1.0), 0.5)
					Combat.hit_zone(who, who.global_position, dt, 16.0, 4.0, 2.4, _kinfo(dmg, 1.0, {"element": "raiton", "knock": 3.0, "kind": "light", "stun": 0.5, "pierce_guard": true}))
				5:   # koşunun sonu: hendekten yukarı saplanış — hedef havaya
					var up0 = who.global_position + Vector3.UP * 1.0 + f * 0.8
					for k in 5:
						VFX.bolt(up0, up0 + Vector3(randf_range(-1.2, 1.2), randf_range(2.0, 4.0), randf_range(-1.2, 1.2)), rai, 0.16, 0.3, 2)
					VFX.star(up0 + Vector3.UP * 0.4, Color(0.92, 0.97, 1.0), 2.8, 0.18)
					Combat.hit_sphere(who, up0 + Vector3.UP * 0.3, 1.8, _kinfo(dmg, 2.3, {"element": "raiton", "knock": 4.0, "launch": 9.0, "kind": "heavy", "stun": 0.8, "pierce_guard": true}))
					_shake(who, 0.55)
		"style_tip":
			var tg = _near_foe(who, 10.0)
			var pjt = PathJutsu.get_pinst()
			if pjt == null:
				return
			var blue = Color(0.6, 0.9, 1.0)
			var med = Color(0.45, 0.95, 0.6)
			match i:
				0, 1:   # neşter kesiği: görünmez yara — kas kesilir (yavaşlar), kanama
					pjt._arc_cut(who.global_position + Vector3.UP * 1.15, f, 70.0 if i == 0 else -70.0, -70.0 if i == 0 else 70.0, blue, 1.8)
					Combat.hit_zone(who, who.global_position, f, 2.4, 50.0, 2.2, _kinfo(dmg, 0.9, {"element": "", "knock": 1.0, "kind": "light", "melee": true, "slow": 2.0, "bleed": 1.5}))
				2:   # Ranshinshō: yeşil şimşekli avuç — sinirler karışır
					var pt = who.global_position + Vector3.UP * 1.2 + f * 0.8
					for k in 5:
						VFX.bolt(pt, pt + Vector3(randf_range(-0.8, 0.8), randf_range(-0.5, 0.8), randf_range(-0.8, 0.8)) + f * 0.4, Color(0.5, 1.0, 0.6), 0.07, 0.22, 1)
					FX.hit_spark(pt, Color(0.6, 1.0, 0.7), 0.8)
					Combat.hit_zone(who, who.global_position, f, 2.6, 35.0, 2.2, _kinfo(dmg, 0.8, {"element": "", "knock": 1.0, "kind": "light", "melee": true, "stun": 1.2}))
					Sfx.play("chidori", pt, 1.6, 0.35)
				3:   # Dokugiri: ağızdan mor zehir akışı (sis bulutu değil: akışın kendisi)
					var mouth = who.global_position + Vector3.UP * 1.55 + f * 0.35
					var dz = (f - Vector3.UP * 0.12).normalized()
					FX.burst(mouth, {"amount": 60, "life": 0.7, "tex": FX.tex_soft, "add": false, "size": 0.5, "radius": 0.15, "vmin": 6.0, "vmax": 10.0, "dir": dz, "spread": 16.0, "damp": 4.0,
						"smin": 0.6, "smax": 1.6, "colors": [Color(0.62, 0.3, 0.75, 0.75), Color(0.45, 0.18, 0.55, 0.45), Color(0.35, 0.12, 0.45, 0.0)]})
					Combat.hit_zone(who, who.global_position, f, 7.0, 25.0, 2.4, _kinfo(dmg, 0.5, {"element": "", "knock": 0.0, "kind": "light", "poison": 4.0, "slow": 1.5}))
					Sfx.play("wind", mouth, 1.3, 0.5)
				4:   # Shōsen emişi: avuç değer, rakibin chakrası seni onarır (kanon Kabuto: tıbbi chakra hem keser hem onarır)
					var pt2 = who.global_position + Vector3.UP * 1.15 + f * 0.8
					FX.hit_spark(pt2, med, 0.8)
					var hits = Combat.hit_zone(who, who.global_position, f, 2.4, 40.0, 2.2, _kinfo(dmg, 1.0, {"element": "", "knock": 3.0, "kind": "light", "melee": true}))
					if hits is Array and not hits.is_empty() or (tg and tg.global_position.distance_to(who.global_position) < 2.6):
						pjt.heal(who, who.max_hp * 0.04)
						if who.get("chakra") != null and who.get("max_chakra") != null:
							who.chakra = minf(who.max_chakra, who.chakra + 6.0)
						if tg:
							pjt.tether(func(): return tg.global_position + Vector3.UP * 1.1 if is_instance_valid(tg) else pt2, func(): return who.global_position + Vector3.UP * 1.1 if is_instance_valid(who) else pt2, 0.04, VFX.mat_bolt(med, 1.2), 0.35)
				5:   # Ōkashō: yere yumruk — yer yarılır, kaya parçaları, çevre havaya
					var g = who.global_position + f * 1.0
					g.y = Game.ground_height(g.x, g.z)
					VFX.cracks(g, 6.0)
					VFX.debris(g + Vector3.UP * 0.2, Color(0.55, 0.5, 0.42), 18, 8.0, 0.4)
					VFX.shockwave(g + Vector3.UP * 0.15, Color(0.75, 0.68, 0.55), 7.0, 0.35, true)
					Combat.hit_sphere(who, g + Vector3.UP * 0.6, 3.6, _kinfo(dmg, 2.3, {"element": "", "knock": 8.0, "launch": 8.0, "kind": "heavy", "stun": 0.6}))
					_shake(who, 0.8)
					Sfx.play("boom", g, 0.8)
		"style_kakuzu":
			var tg = _near_foe(who, 18.0)
			var pjz = PathJutsu.get_pinst()
			if pjz == null:
				return
			var thread = StandardMaterial3D.new()
			thread.albedo_color = Color(0.06, 0.06, 0.08)
			var handz = who.global_position + Vector3.UP * 1.2 + f * 0.5
			var aimz = (tg.global_position + Vector3.UP) if tg else handz + f * 9.0
			match i:
				0:   # iplik kırbacı: koldan fışkıran kıvrımlı kara iplik demeti yatay savrulur
					for k in 7:
						var end = aimz + side * (k - 3) * 0.45 + Vector3.UP * randf_range(-0.4, 0.4)
						pjz.wavy_tether(func(): return (who.global_position + Vector3.UP * 1.2 + who.face_dir() * 0.4) if is_instance_valid(who) else handz, func(): return end, 0.03, thread, 0.4, randf_range(0.12, 0.3))
					Combat.hit_zone(who, who.global_position, f, 9.0, 30.0, 2.4, _kinfo(dmg, 1.0, {"element": "", "knock": 3.0, "kind": "heavy", "bleed": 2.0}))
				1:   # iplik kancası: kara iplik demeti hedefi sarar (gövdesine dolanır), sonra önüne çeker
					if tg and tg.global_position.distance_to(who.global_position) < 14.0:
						var tgt = tg
						for k in 8:
							var a0 = TAU * k / 8.0
							var off = Vector3(cos(a0) * 0.35, 0.6 + (k % 4) * 0.25, sin(a0) * 0.35)
							pjz.wavy_tether(func(): return (who.global_position + Vector3.UP * 1.2 + who.face_dir() * 0.4) if is_instance_valid(who) else handz,
								func(): return (tgt.global_position + off) if is_instance_valid(tgt) else handz, 0.028, thread, 0.65, 0.12)
						who.get_tree().create_timer(0.15).timeout.connect(func():
							if is_instance_valid(who) and is_instance_valid(tgt):
								Combat.hit_sphere(who, tgt.global_position + Vector3.UP, 1.0, _kinfo(dmg, 0.9, {"element": "", "knock": 0.0, "kind": "heavy", "stun": 0.5, "bind": 0.4}))
								var to = who.global_position + who.face_dir() * 1.6
								to.y = Game.ground_height(to.x, to.z)
								tgt.create_tween().tween_property(tgt, "global_position", to, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN))
				2:   # Domu yumruğu: taş yumruk, kısa yarık
					var g2 = who.global_position + f * 1.3
					g2.y = Game.ground_height(g2.x, g2.z)
					VFX.cracks(g2, 1.6)
					FX.hit_spark(who.global_position + Vector3.UP * 1.2 + f * 1.1, Color(0.6, 0.55, 0.5), 0.9)
					_shake(who, 0.35)
				3:   # Katon maskesi: Zukokku — maske ağzından dev alev küresi
					var mb = pjz._mask_beast(who, 1.0, Color(1.0, 0.5, 0.12))
					who.get_tree().create_timer(0.25).timeout.connect(func():
						if not (is_instance_valid(who) and is_instance_valid(mb)):
							return
						var from = mb.global_position + who.face_dir() * 0.6
						var to = (tg.global_position + Vector3.UP) if is_instance_valid(tg) else from + who.face_dir() * 14.0
						var fb = VFX.fireball(1.8)
						who.get_tree().current_scene.add_child(fb)
						fb.global_position = from
						var tw2 = fb.create_tween()
						tw2.tween_property(fb, "global_position", to, from.distance_to(to) / 30.0)
						tw2.tween_callback(func():
							VFX.explosion(to, 2.2)
							if is_instance_valid(who):
								Combat.hit_sphere(who, to, 2.6, _kinfo(dmg, 1.6, {"element": "katon", "knock": 9.0, "launch": 3.0, "kind": "heavy", "burn": 3.0}))
							fb.queue_free()))
					who.get_tree().create_timer(1.4).timeout.connect(func():
						if is_instance_valid(mb):
							pjz._beast_out(mb))
				4:   # Fūton maskesi: Atsugai — basınçlı rüzgâr akışı
					var mb2 = pjz._mask_beast(who, -1.0, Color(0.6, 0.85, 0.7))
					who.get_tree().create_timer(0.3).timeout.connect(func():
						if not (is_instance_valid(who) and is_instance_valid(mb2)):
							return
						var d = who.face_dir()
						pjz.stream_fx(mb2.global_position + d * 0.5, d, 14.0, 2.6, VFX.mat_wind(Color(0.85, 0.95, 0.9), 10.0, 7.0, Vector3(0, 0, 1), 0.65), 0.5)
						Combat.hit_zone(who, who.global_position, d, 14.0, 26.0, 4.0, _kinfo(dmg, 1.4, {"element": "fuuton", "knock": 16.0, "launch": 3.0, "kind": "heavy", "bleed": 1.5})))
					who.get_tree().create_timer(1.4).timeout.connect(func():
						if is_instance_valid(mb2):
							pjz._beast_out(mb2))
				5:   # bitiriş: Atsugai + Zukokku — rüzgâr alevi büyütür, geniş alev fırtınası
					var mf = pjz._mask_beast(who, 1.0, Color(1.0, 0.5, 0.12))
					var mw = pjz._mask_beast(who, -1.0, Color(0.6, 0.85, 0.7))
					who.get_tree().create_timer(0.3).timeout.connect(func():
						if not is_instance_valid(who):
							return
						var d = who.face_dir()
						var o = who.global_position + Vector3.UP * 2.0 + d * 1.2
						if is_instance_valid(mw):
							pjz.stream_fx(mw.global_position + d * 0.5, (d + Vector3.UP * -0.05).normalized(), 16.0, 3.0, VFX.mat_wind(Color(0.85, 0.95, 0.9), 10.0, 7.0, Vector3(0, 0, 1), 0.5), 0.6)
						pjz.fire_stream(o, d, 16.0, 4.2, 12)
						for k in 4:
							VFX.linger(Vector3(o.x, Game.ground_height(o.x, o.z), o.z) + d * (5.0 + k * 3.0), "katon", Color(1.0, 0.5, 0.12), 2.0, 3.0)
						Combat.hit_zone(who, who.global_position, d, 16.0, 30.0, 4.0, _kinfo(dmg, 2.6, {"element": "katon", "knock": 14.0, "launch": 4.0, "kind": "heavy", "burn": 4.0}))
						_shake(who, 0.7))
					who.get_tree().create_timer(1.6).timeout.connect(func():
						for b in [mf, mw]:
							if is_instance_valid(b):
								pjz._beast_out(b))
		"style_jin_shukaku":
			var tg = _near_foe(who, 16.0)
			var aim = (tg.global_position + Vector3.UP) if tg else who.global_position + Vector3.UP + f * 10.0
			var sand = Color(0.85, 0.7, 0.45)
			match i:
				0:   # kum pençe savuruşu
					_sand_burst(who.global_position + f * 1.6, 0.6)
					Combat.hit_zone(who, who.global_position, f, 3.2, 70.0, 2.6, _kinfo(dmg, 1.3, {"element": "doton", "knock": 9.0, "kind": "heavy", "melee": true}))
				1:   # pençe kavrar: kum tabutu
					if tg and tg.global_position.distance_to(who.global_position) < 6.0:
						BijuuArts._sand_coffin(tg, 1.4, true)
						Combat.hit_sphere(who, tg.global_position + Vector3.UP, 1.2, _kinfo(dmg, 0.9, {"element": "doton", "knock": 0.0, "kind": "heavy"}))
				2:   # Fūton: Renkūdan — karından hava mermisi (küçük)
					BijuuArts._renkudan(who, {"s": 0.28, "from": who.global_position + Vector3.UP * 1.1 + f * 0.6, "aim": aim, "dmg": dmg * 1.3, "tgt": tg})
				3:   # Sabaku Taisō: önden kum dalgası (küçük)
					BijuuArts._sabaku_taiso(who, {"s": 0.32, "aim": aim, "dmg": dmg * 1.2, "tgt": tg})
				4:   # Suna no Tate: kısa kum kalkanı + çevre sarsma
					VFX.shockwave(who.global_position + Vector3.UP, sand, 5.0, 0.3, true)
					Combat.hit_sphere(who, who.global_position + Vector3.UP, 2.6, _kinfo(dmg, 0.8, {"element": "doton", "knock": 10.0, "kind": "heavy"}))
					if who is Player:
						who.combat.invuln = maxf(who.combat.invuln, 0.6)
						Buffs.add("suna_tate_k", 2.0, {"armor": 0.5, "_name": "Kum Kalkanı"})
				5:   # dev kum pençe yere + büyük Renkūdan
					var g = who.global_position + f * 2.0
					g.y = Game.ground_height(g.x, g.z)
					_sand_burst(g, 1.4)
					VFX.cracks(g, 4.0)
					Combat.hit_sphere(who, g + Vector3.UP * 0.6, 2.8, _kinfo(dmg, 1.4, {"element": "doton", "knock": 6.0, "launch": 5.0, "kind": "heavy"}))
					who.get_tree().create_timer(0.2).timeout.connect(func():
						if is_instance_valid(who):
							BijuuArts._renkudan(who, {"s": 0.45, "from": who.global_position + Vector3.UP * 1.2 + who.face_dir() * 0.6, "aim": aim, "dmg": dmg * 1.4, "tgt": tg}))
					_shake(who, 0.5)
		"style_jin_matatabi":
			var tg = _near_foe(who, 14.0)
			var aim = tg.global_position if tg else who.global_position + f * 8.0
			match i:
				0, 1:   # mavi alev tırnak izleri
					_cat_claw(who, who.global_position + Vector3.UP * 1.15, f, i == 0, 2.0)
					Combat.hit_zone(who, who.global_position, f, 3.0, 50.0, 2.4, _kinfo(dmg, 1.0, {"element": "katon", "knock": 4.0, "kind": "light", "melee": true, "burn": 2.0}))
				2:   # kedi sıçrayışı: yay çizip pençeyle iner
					BijuuArts._neko_pounce(who, {"s": 0.3, "aim": aim, "dmg": dmg * 1.6, "tgt": tg})
				3:   # mavi ateş topları (küçük yay)
					BijuuArts._aobi_dama(who, {"s": 0.3, "from": who.global_position + Vector3.UP * 1.4 + f * 0.5, "aim": aim, "dmg": dmg * 1.5, "tgt": tg})
				4:   # alçak süpürme: yerde mavi alev şeridi
					for k in 3:
						var p = who.global_position + f * (1.2 + k * 1.1) + side * (k - 1) * 0.6
						BijuuArts._blue_patch(who, p, 0.4, dmg * 0.5, 3.0)
					Combat.hit_zone(who, who.global_position, f, 2.8, 80.0, 1.2, _kinfo(dmg, 0.9, {"element": "katon", "knock": 2.0, "kind": "light", "melee": true, "stun": 0.4, "burn": 2.0}))
				5:   # çapraz çift pençe X
					var o = who.global_position + Vector3.UP * 1.2 + f * 0.9
					_cat_claw(who, o - f * 0.8, f, true, 2.6)
					_cat_claw(who, o - f * 0.8, f, false, 2.6)
					VFX.shockwave(o, Color(0.45, 0.65, 1.0), 4.5, 0.3, false, f)
					Combat.hit_zone(who, who.global_position, f, 3.6, 60.0, 2.6, _kinfo(dmg, 2.2, {"element": "katon", "knock": 14.0, "launch": 4.0, "kind": "heavy", "burn": 4.0, "hitstop": 0.1}))
					_shake(who, 0.5)
		"style_jin_son_goku":
			var tg = _near_foe(who, 16.0)
			var aim = tg.global_position if tg else who.global_position + f * 8.0
			match i:
				0, 1:   # lav yumruğu: çarpınca lav sıçrar, yakar
					var hp = who.global_position + Vector3.UP * 1.25 + f * 1.0 + side * (0.2 if i == 0 else -0.2)
					VFX.lava_splash(hp, 0.2)
					Combat.hit_zone(who, who.global_position, f, 2.6, 40.0, 2.4, _kinfo(dmg, 1.2, {"element": "yoton", "knock": 6.0, "kind": "heavy", "melee": true, "burn": 2.0}))
				2:   # Yōton: Kakōgan (küçük lav kayaları)
					BijuuArts._kakogan(who, {"s": 0.22, "from": who.global_position + Vector3.UP * 1.4 + f * 0.6, "aim": aim, "dmg": dmg * 1.4, "tgt": tg})
				3:   # Funkatsu: hedefin altından lav fışkırır
					BijuuArts._funkatsu(who, {"s": 0.28, "aim": aim, "dmg": dmg * 1.5, "tgt": tg})
				4:   # lav kabuğu sarsıntısı: çevreye lav damlası + sarsma
					var c0 = who.global_position + Vector3.UP
					VFX.goo_drops(c0, "molten", 5, 0.35, 5.0)
					VFX.shockwave(Vector3(c0.x, Game.ground_height(c0.x, c0.z) + 0.1, c0.z), BijuuArts.LAVA, 5.0, 0.35, true)
					for h in Combat.hit_sphere(who, c0, 2.8, _kinfo(dmg, 1.0, {"element": "yoton", "knock": 9.0, "kind": "heavy", "burn": 3.0})):
						pass
				5:   # lav yumruğu yere: erimiş yarık + lav gölü
					var g = who.global_position + f * 1.6
					g.y = Game.ground_height(g.x, g.z)
					VFX.cracks(g, 4.5, Color(1.0, 0.45, 0.05, 0.95), 3.0)
					VFX.debris(g, Color(0.25, 0.12, 0.08), 10, 6.0, 0.25)
					BijuuArts._lava_pool(who, g, 0.28, dmg * 0.3, 4.0)
					Combat.hit_sphere(who, g + Vector3.UP * 0.6, 2.8, _kinfo(dmg, 2.2, {"element": "yoton", "knock": 8.0, "launch": 7.0, "kind": "heavy", "burn": 4.0}))
					_shake(who, 0.6)
		"style_jin_kokuo":
			var tg = _near_foe(who, 16.0)
			var aim = tg.global_position if tg else who.global_position + f * 8.0
			var back = who.global_position + Vector3.UP * 1.3 - f * 0.4
			match i:
				0, 1:   # buharlı tekme: sırttan buhar fışkırır, tekme hızlanır
					BijuuArts._steam_cloud(back, 0.22, 0.6, 0.6)
					Combat.hit_zone(who, who.global_position, f, 2.6, 60.0, 2.4 if i == 0 else 1.2, _kinfo(dmg, 1.2, {"element": "futton", "knock": 8.0 if i == 0 else 2.0, "kind": "heavy", "melee": true, "stun": 0.0 if i == 0 else 0.5}))
				2:   # boynuz atılışı (kısa hücum)
					BijuuArts._horn_ram(who, {"s": 0.22, "aim": aim, "dmg": dmg * 1.5, "tgt": tg})
				3:   # haşlama buharı: hedefin üstünde kaynar sis
					BijuuArts._futton_boil(who, {"s": 0.22, "aim": aim, "dmg": dmg * 1.2, "tgt": tg})
				4:   # buhar patlaması
					BijuuArts._steam_burst(who, {"s": 0.22, "dmg": dmg * 1.3})
				5:   # roket tekmenin çarpışı
					var kp = who.global_position + Vector3.UP * 1.0 + f * 1.0
					VFX.star(kp, BijuuArts.STEAM, 2.4, 0.15)
					BijuuArts._steam_cloud(kp, 0.22, 0.6, 0.6)
					Combat.hit_zone(who, who.global_position, f, 3.0, 50.0, 2.4, _kinfo(dmg, 2.3, {"element": "futton", "knock": 18.0, "launch": 5.0, "kind": "heavy", "hitstop": 0.1}))
					_shake(who, 0.55)
		"style_jin_chomei":
			var tg = _near_foe(who, 18.0)
			var aim = (tg.global_position + Vector3.UP) if tg else who.global_position + Vector3.UP + f * 9.0
			var hand = who.global_position + Vector3.UP * 1.4 + f * 0.5
			match i:
				0, 1:   # kanat çırpışı: iki ince rüzgâr bıçağı ileri
					var sx = 1.0 if i == 0 else -1.0
					var o = who.global_position + Vector3.UP * 1.3
					for k in 2:
						WindFX.streak(func(t: float) -> Vector3: return o + Vector3.UP * (k - 0.5) * 0.3 + f * (0.6 + t * 6.0) + side * sin(t * PI) * 0.5 * sx, 0.2, 0.1, Color(0.85, 1.0, 0.75, 0.95), k * 0.03, 12)
					Combat.hit_zone(who, who.global_position, f, 6.5, 22.0, 2.4, _kinfo(dmg, 1.0, {"element": "fuuton", "knock": 4.0, "kind": "light", "bleed": 1.0}))
				2:   # böcek sürüsü: chakra emer
					BijuuArts._mushi_swarm(who, {"s": 0.4, "from": hand, "aim": aim, "dmg": dmg * 1.6, "tgt": tg})
				3:   # pul tozu parlaması: kör eder
					BijuuArts._rinpun(who, {"s": 0.32, "from": hand, "aim": aim, "dmg": dmg * 1.3})
				4:   # havadan dalış tekmesi
					var kp = who.global_position + Vector3.UP * 0.8 + f * 1.0
					VFX.shockwave(Vector3(kp.x, Game.ground_height(kp.x, kp.z) + 0.1, kp.z), BijuuArts.SCALE, 3.5, 0.3, true)
					Combat.hit_sphere(who, kp, 1.8, _kinfo(dmg, 1.5, {"element": "fuuton", "knock": 8.0, "launch": 3.0, "kind": "heavy", "melee": true}))
				5:   # kanatlar açılır: pul tozu + rüzgâr fırtınası
					BijuuArts._rinpun(who, {"s": 0.4, "from": hand, "aim": aim, "dmg": dmg * 1.2})
					var o5 = who.global_position + Vector3.UP * 1.2
					for k in 5:
						var dd = f.rotated(Vector3.UP, deg_to_rad((k - 2) * 12.0))
						WindFX.streak(func(t: float) -> Vector3: return o5 + dd * (0.5 + t * 8.0) + Vector3.UP * sin(t * PI * 2.0 + k) * 0.3, 0.24, 0.12, Color(0.85, 1.0, 0.75, 0.95), k * 0.02, 12)
					Combat.hit_zone(who, who.global_position, f, 8.0, 35.0, 3.0, _kinfo(dmg, 1.6, {"element": "fuuton", "knock": 12.0, "launch": 3.0, "kind": "heavy", "bleed": 1.5}))
					_shake(who, 0.4)
		"style_jin_gyuki":
			var tg = _near_foe(who, 16.0)
			var aim = tg.global_position if tg else who.global_position + f * 8.0
			var purple = Color(0.65, 0.35, 0.75)
			match i:
				0, 1:   # örtüden chakra kolu darbesi
					BijuuArts._chakra_kaina(who, {"s": 0.35, "aim": aim, "dmg": dmg * 1.4, "tgt": tg, "col": purple})
				2:   # iki dokunaç kavrayıp çarpar
					for k in 2:
						var off = f.cross(Vector3.UP) * (k - 0.5) * 1.2
						who.get_tree().create_timer(k * 0.1).timeout.connect(func():
							if is_instance_valid(who):
								BijuuArts._tako_ude(who, {"s": 0.5, "dmg": dmg * 1.0, "aim": aim + off, "tgt": tg, "base_h": 1.7 + k * 0.15}))
				3:   # Tako Bunshin: mürekkep bulutu, ahtapot klonları, geri kaçış
					BijuuArts._tako_bunshin(who, {"s": 0.3})
				4:   # dokunaç süpürmesi
					for k in 3:
						var a = TAU * k / 3.0
						var q = who.global_position + Vector3(cos(a), 0, sin(a)) * 3.0
						who.get_tree().create_timer(k * 0.06).timeout.connect(func():
							if is_instance_valid(who):
								BijuuArts._tako_ude(who, {"s": 0.4, "dmg": dmg * 0.7, "aim": q, "tgt": null, "base_h": 1.6}))
				5:   # küçük Bijūdama
					BijuuArts._bijudama_rasengan(who, {"s": 0.3, "from": who.global_position + Vector3.UP * 1.5 + f * 0.8, "aim": aim + Vector3.UP, "dmg": dmg * 2.6, "col": purple})
					_shake(who, 0.4)
		"style_jin_kurama":
			var tg = _near_foe(who, 16.0)
			var aim = tg.global_position if tg else who.global_position + f * 8.0
			var fox = Color(1.0, 0.5, 0.12)
			match i:
				0, 1:   # chakra pençesi: turuncu tilki ateşi izleri
					_cat_claw(who, who.global_position + Vector3.UP * 1.15, f, i == 0, 2.2, Color(1.0, 0.5, 0.12, 0.85))
					Combat.hit_zone(who, who.global_position, f, 3.0, 50.0, 2.4, _kinfo(dmg, 1.2, {"element": "katon", "knock": 5.0, "kind": "heavy", "melee": true, "burn": 1.5}))
				2:   # chakra kolu kavrar, yere çarpar
					BijuuArts._chakra_kaina(who, {"s": 0.38, "aim": aim, "dmg": dmg * 1.6, "tgt": tg, "col": fox})
				3:   # Bijū Hōkō: kükreme dalgası
					BijuuArts._biju_hoko(who, {"s": 0.3, "from": who.global_position + Vector3.UP * 1.5 + f * 0.5, "aim": aim + Vector3.UP, "dmg": dmg * 1.4, "col": fox})
				4:   # iki chakra kolu birden (çapraz)
					for k in 2:
						var off = f.cross(Vector3.UP) * (k - 0.5) * 2.0
						who.get_tree().create_timer(k * 0.08).timeout.connect(func():
							if is_instance_valid(who):
								BijuuArts._chakra_kaina(who, {"s": 0.3, "aim": aim + off, "dmg": dmg * 0.9, "tgt": tg if k == 0 else null, "col": fox}))
				5:   # Bijūdama Rasengan (küçük)
					BijuuArts._bijudama_rasengan(who, {"s": 0.3, "from": who.global_position + Vector3.UP * 1.3 + f * 0.9, "aim": aim + Vector3.UP, "dmg": dmg * 2.6, "col": fox})
					_shake(who, 0.5)
		"style_jin_saiken":
			var tg = _near_foe(who, 18.0)
			var aim = (tg.global_position + Vector3.UP) if tg else who.global_position + Vector3.UP + f * 9.0
			var hand = who.global_position + Vector3.UP * 1.3 + f * 0.6
			match i:
				0, 1:   # köpük-asit baloncukları (Saiken'in gerçek baloncuğu; küçük)
					BijuuArts._fukuso(who, {"s": 0.32, "from": hand + side * (0.25 if i == 0 else -0.25), "aim": aim, "dmg": dmg * 0.9})
				2:   # asit sisi
					BijuuArts._acid_mist(who, {"s": 0.3, "aim": aim, "dmg": dmg * 1.1})
				3:   # sümük gölü: saplar, yavaşlatır
					BijuuArts._slime(who, {"s": 0.3, "aim": Vector3(aim.x, Game.ground_height(aim.x, aim.z), aim.z), "dmg": dmg})
				4:   # baloncuk hapsi: hedef köpük balonun içinde kalır
					if tg and tg.global_position.distance_to(who.global_position) < 12.0:
						_bubble_trap(who, tg, 1.6)
						Combat.hit_sphere(who, tg.global_position + Vector3.UP, 1.0, _kinfo(dmg, 0.6, {"element": "suiton", "knock": 0.0, "kind": "light"}))
				5:   # baloncuk halkası art arda patlar
					var c0 = Vector3(aim.x, Game.ground_height(aim.x, aim.z), aim.z)
					for k in 6:
						var a = TAU * k / 6.0
						var q = c0 + Vector3(cos(a) * 1.3, 0.9 + (k % 2) * 0.5, sin(a) * 1.3)
						var bub = MeshInstance3D.new()
						bub.mesh = VFX._sphere(0.5, 16, 8)
						bub.material_override = BijuuArts._glass(Color(0.85, 1.0, 0.9), 0.45, 0.3)
						who.get_tree().current_scene.add_child(bub)
						bub.global_position = q
						bub.scale = Vector3.ONE * 0.1
						var tw = bub.create_tween()
						tw.tween_property(bub, "scale", Vector3.ONE * 0.7, 0.2).set_trans(Tween.TRANS_BACK)
						tw.tween_interval(0.15 + k * 0.07)
						tw.tween_callback(func():
							VFX.puffs(q, {"amount": 10, "life": 0.5, "size": 0.4, "radius": 0.3, "vmin": 3, "vmax": 6, "gravity": Vector3(0, -10, 0), "colors": [Color(0.95, 1, 0.9, 1), BijuuArts.ACID, Color(0.4, 0.8, 0.2, 0)]})
							if is_instance_valid(who):
								for h in Combat.hit_sphere(who, q, 1.4, _kinfo(dmg, 0.45, {"element": "suiton", "knock": 3.0, "kind": "light"})):
									BijuuArts._corrode(h, 3.0, dmg * 0.05, BijuuArts.ACID)
							bub.queue_free())
					_shake(who, 0.3)
		"style_jin_isobu":
			var tg = _near_foe(who, 16.0)
			var aim = tg.global_position if tg else who.global_position + f * 8.0
			var aimg = Vector3(aim.x, Game.ground_height(aim.x, aim.z), aim.z)
			match i:
				0:   # mercan diken: hedefin altından
					BijuuArts._coral(aimg - Vector3.UP * 0.2, 2.2, 2.5, BijuuArts.CORAL)
					Combat.hit_sphere(who, aimg + Vector3.UP * 0.8, 1.3, _kinfo(dmg, 1.2, {"element": "suiton", "knock": 2.0, "launch": 7.0, "kind": "heavy"}))
				1:   # su avucu itişi
					var pt = who.global_position + Vector3.UP * 1.1 + f * 1.2
					WaterArt.splash(pt, 0.8)
					WaterArt.spray(pt, 1.0, f, 25.0, 1.4)
					Combat.hit_zone(who, who.global_position, f, 3.4, 40.0, 2.4, _kinfo(dmg, 1.0, {"element": "suiton", "knock": 10.0, "kind": "heavy"}))
				2:   # mercan tarlası (küçük): bağlar
					BijuuArts._sango(who, {"s": 0.28, "aim": aim, "dmg": dmg * 1.2, "tgt": tg})
				3:   # kabuk yuvarlanışı
					BijuuArts._shell_roll(who, {"s": 0.32, "aim": aim, "dmg": dmg * 1.4, "tgt": tg})
				4:   # yanılsama sisi (küçük)
					BijuuArts._kiri_genjutsu(who, {"s": 0.35, "aim": aim, "dmg": dmg, "tgt": tg})
				5:   # mercan halkası kapanır + su patlaması
					for k in 6:
						var a = TAU * k / 6.0
						var q = aimg + Vector3(cos(a), 0, sin(a)) * 1.3
						who.get_tree().create_timer(k * 0.03).timeout.connect(func():
							BijuuArts._coral(q - Vector3.UP * 0.2, 2.6, 2.0, BijuuArts.CORAL if k % 2 else BijuuArts.CORAL2))
					who.get_tree().create_timer(0.25).timeout.connect(func():
						VFX.splash(aimg + Vector3.UP * 0.5, 1.6)
						if is_instance_valid(who):
							for h in Combat.hit_sphere(who, aimg + Vector3.UP, 2.2, _kinfo(dmg, 2.2, {"element": "suiton", "knock": 6.0, "launch": 6.0, "kind": "heavy"})):
								if h.has_method("apply_status"):
									h.apply_status("bind", 1.2)
							_shake(who, 0.5))
		"style_jashin":
			var tg = _near_foe(who, 20.0)
			var pjj = PathJutsu.get_pinst()
			if pjj == null:
				return
			var blood = Color(0.6, 0.05, 0.05)
			var red = Color(0.75, 0.1, 0.12)
			var handj = who.global_position + Vector3.UP * 1.3 + f * 0.5
			match i:
				0:   # tırpan kabloyla fırlar, kanı alır, geri gelir
					var to = (tg.global_position + Vector3.UP) if tg and tg.global_position.distance_to(who.global_position) < 16.0 else handj + f * 10.0
					var sc = _scythe_node()
					who.get_tree().current_scene.add_child(sc)
					sc.global_position = handj
					sc.look_at(to, Vector3.UP)   # sap gidiş yönünde, bıçaklar yukarı
					var cable = StandardMaterial3D.new()
					cable.albedo_color = Color(0.25, 0.25, 0.28)
					pjj.tether(func(): return (who.global_position + Vector3.UP * 1.3) if is_instance_valid(who) else handj, func(): return sc.global_position if is_instance_valid(sc) else handj, 0.02, cable, 0.75)
					var tw = sc.create_tween()
					tw.tween_property(sc, "global_position", to, 0.22)
					tw.parallel().tween_property(sc, "rotation:y", sc.rotation.y + TAU * 2.0, 0.22)
					tw.tween_callback(func():
						if not is_instance_valid(who):
							return
						VFX.debris(to, blood, 10, 5.0, 0.2)
						for h in Combat.hit_sphere(who, to, 1.4, _kinfo(dmg, 1.1, {"element": "", "knock": 3.0, "kind": "heavy", "bleed": 3.0})):
							h.set_meta("jashin_kan", Time.get_ticks_msec()))
					tw.tween_method(func(u: float):
						if is_instance_valid(sc) and is_instance_valid(who):
							sc.global_position = to.lerp(who.global_position + Vector3.UP * 1.3, u), 0.0, 1.0, 0.3)
					tw.tween_callback(sc.queue_free)
				1:   # kara mızrak dürtüşü: kan alır
					var hits1 = Combat.hit_zone(who, who.global_position, f, 3.0, 25.0, 2.2, _kinfo(dmg, 1.0, {"element": "", "knock": 3.0, "kind": "heavy", "melee": true, "bleed": 2.5}))
					for h in hits1:
						h.set_meta("jashin_kan", Time.get_ticks_msec())
						VFX.debris(h.global_position + Vector3.UP, blood, 8, 4.0, 0.2)
				2:   # tırpan savuruşu: çevreyi biçer
					var piv = Node3D.new()
					who.add_child(piv)
					piv.position = Vector3(0, 1.1, 0)
					piv.rotation.y = who.get("facing") if who.get("facing") != null else 0.0
					var sc2 = _scythe_node()
					piv.add_child(sc2)
					sc2.rotation = Vector3(0, PI, PI * 0.5)   # sap öne (-Z), bıçaklar yana: yatay biçme
					var tw2 = piv.create_tween()
					tw2.tween_property(piv, "rotation:y", piv.rotation.y - TAU, 0.3)
					tw2.tween_callback(piv.queue_free)
					pjj._arc_cut(who.global_position + Vector3.UP * 1.1, f, -180.0, 180.0, Color(0.85, 0.85, 0.9), 2.6)
					for h in Combat.hit_sphere(who, who.global_position + Vector3.UP, 2.8, _kinfo(dmg, 1.0, {"element": "", "knock": 6.0, "kind": "heavy", "bleed": 2.0})):
						h.set_meta("jashin_kan", Time.get_ticks_msec())
				3:   # Jashin çemberi: ayakla çizilir; yakında kanını aldığın biri varsa lanet bağı kurulur
					var atj = Vector3(who.global_position.x, Game.ground_height(who.global_position.x, who.global_position.z), who.global_position.z)
					_jashin_circle(who, atj, 6.0)
					var cursed: Node3D = null
					for e in who.get_tree().get_nodes_in_group("fighters"):
						if e != who and Combat.hostile(who, e) and not e.is_dead() and e.has_meta("jashin_kan") and Time.get_ticks_msec() - int(e.get_meta("jashin_kan")) < 20000 and e.global_position.distance_to(who.global_position) < 30.0:
							cursed = e
							break
					if cursed:
						who.set_meta("jashin_link", [cursed.get_instance_id(), Time.get_ticks_msec() / 1000.0 + 6.0, atj])
						Combat.popup_text(cursed.global_position + Vector3.UP * 2.4, "Lanet bağı!", red)
						FX.aura(who, Color(0.08, 0.08, 0.1), 1.2, Vector3(0, 0.9, 0), 6.0)   # beden kara-ak ölüm desenine bürünür (aura)
					else:
						Combat.popup_text(who.global_position + Vector3.UP * 2.4, "Kan yok...", Color(0.7, 0.6, 0.6))
				4:   # bacağına sapla: bağlı rakip aynı yarayı alır (kendi canından küçük bedel)
					_jashin_self(who, dmg, 1.4, 0.03, "Bacağa!")
				5:   # kalbe sapla: bağlı rakibe ağır yara; bağ yoksa tırpanı yere çakar
					if not _jashin_self(who, dmg, 3.2, 0.06, "Jashin-sama!"):
						var g = who.global_position + f * 1.5
						g.y = Game.ground_height(g.x, g.z)
						VFX.cracks(g, 3.0)
						VFX.debris(g, Color(0.5, 0.45, 0.4), 12, 6.0, 0.3)
						Combat.hit_sphere(who, g + Vector3.UP * 0.6, 2.2, _kinfo(dmg, 1.6, {"element": "", "knock": 6.0, "launch": 4.0, "kind": "heavy", "bleed": 2.0}))
						_shake(who, 0.4)
		"style_hachibi":
			var tg = _near_foe(who, 14.0)
			var pjb = PathJutsu.get_pinst()
			if pjb == null:
				return
			var octo = Color(0.75, 0.4, 0.62)
			var aimb = tg.global_position if tg else who.global_position + f * 7.0
			match i:
				0:   # dokunaç kırbacı (Gyūki'nin gerçek Takoashi Ude dokunacı, insan ölçeği)
					BijuuArts._tako_ude(who, {"s": 0.45, "dmg": dmg * 1.1, "aim": aimb, "tgt": tg, "base_h": 1.6})
				1:   # yedi kılıç dönüşü (kollar/koltuk altı/ağız)
					var root = Node3D.new()
					who.add_child(root)
					root.position = Vector3.UP * 1.2
					for k in 7:
						var a = k * TAU / 7.0
						var b = MB.new()
						b.add("box", Vector3(0, 0, 0.6), Vector3(0.04, 0.12, 1.2), Color(0.8, 0.82, 0.86))
						b.add("cyl", Vector3(0, 0, -0.05), Vector3(0.04, 0.15, 0.04), Color(0.15, 0.12, 0.1), Vector3(90, 0, 0), 6)
						var sw = MeshInstance3D.new()
						sw.mesh = b.build(Props.toon())
						root.add_child(sw)
						sw.rotation.y = a
						sw.position = Vector3(cos(a), (k % 3 - 1) * 0.3, sin(a)) * 0.4
					var tw = root.create_tween()
					tw.tween_property(root, "rotation:y", TAU * 2.0, 0.4)
					tw.tween_callback(root.queue_free)
					Combat.hit_sphere(who, who.global_position + Vector3.UP, 2.6, _kinfo(dmg, 1.2, {"element": "", "knock": 5.0, "kind": "heavy", "bleed": 1.5}))
				2:   # mürekkep tükürüğü: kara mürekkep seli — kör eder, yavaşlatır
					var mouth = who.global_position + Vector3.UP * 1.55 + f * 0.35
					var di = (f - Vector3.UP * 0.08).normalized()
					FX.burst(mouth, {"amount": 70, "life": 0.6, "tex": FX.tex_soft, "add": false, "size": 0.45, "radius": 0.1, "vmin": 9.0, "vmax": 14.0, "dir": di, "spread": 10.0, "damp": 3.0,
						"gravity": Vector3(0, -6, 0), "smin": 0.5, "smax": 1.4, "colors": [Color(0.03, 0.03, 0.05, 0.95), Color(0.06, 0.05, 0.08, 0.8), Color(0.05, 0.05, 0.07, 0.0)]})
					var pe = who.global_position + di * 7.0
					pjb._ink_splash(Vector3(pe.x, Game.ground_height(pe.x, pe.z) + 0.05, pe.z), 14)
					Combat.hit_zone(who, who.global_position, f, 8.0, 22.0, 2.4, _kinfo(dmg, 0.5, {"element": "suiton", "knock": 1.0, "kind": "light", "blind": 2.0, "slow": 2.0}))
				3:   # Lariat: şimşekli sol kol çarpar
					var lp = who.global_position + Vector3.UP * 1.3 + f * 0.8
					VFX.shockwave(lp, Color(0.95, 0.95, 1.0), 4.0, 0.25, false, f)
					for k in 4:
						VFX.bolt(lp, lp + Vector3(randf_range(-1.2, 1.2), randf_range(-0.6, 1.0), randf_range(-1.2, 1.2)), Color(0.85, 0.9, 1.0), 0.12, 0.2, 1)
					Combat.hit_zone(who, who.global_position, f, 2.8, 70.0, 2.4, _kinfo(dmg, 1.6, {"element": "raiton", "knock": 14.0, "launch": 6.0, "kind": "heavy", "melee": true, "hitstop": 0.1}))
					_shake(who, 0.45)
				4:   # dokunaçla kavrayıp yere çarpma (iki dokunaç)
					for k in 2:
						var off = f.cross(Vector3.UP) * (k - 0.5) * 1.2
						who.get_tree().create_timer(k * 0.12).timeout.connect(func():
							if is_instance_valid(who):
								BijuuArts._tako_ude(who, {"s": 0.5, "dmg": dmg * 1.0, "aim": aimb + off, "tgt": tg, "base_h": 1.7 + k * 0.15}))
				5:   # Sekiz Kuyruk topu (küçük): ağızda toplanır, fırlar, mor kubbe patlar
					var from = who.global_position + Vector3.UP * 1.5 + f * 1.0
					var ball = pjb._bijuball(0.55)
					who.get_tree().current_scene.add_child(ball)
					ball.global_position = from
					BijudamaFX.launch(from, f, 0.55, ball)
					var to2 = (tg.global_position + Vector3.UP) if tg else from + f * 12.0
					var tw5 = ball.create_tween()
					tw5.tween_property(ball, "global_position", to2, from.distance_to(to2) / 34.0)
					tw5.tween_callback(func():
						ball.queue_free()
						BijudamaFX.explode(to2, 2.8)
						if is_instance_valid(who):
							Combat.hit_sphere(who, to2, 2.8, _kinfo(dmg, 2.4, {"element": "", "knock": 18.0, "launch": 6.0, "kind": "heavy", "hitstop": 0.12}))
							_shake(who, 0.7))
		"style_silah":
			var tg = _near_foe(who, 20.0)
			var pjw = PathJutsu.get_pinst()
			if pjw == null:
				return
			var from0 = who.global_position + Vector3.UP * 1.3 + f * 0.6
			var aimw = (tg.global_position + Vector3.UP) if tg else from0 + f * 14.0
			match i:
				0, 1:   # parşömenden salvo: 0 kunai, 1 shuriken + fuma
					var kinds = ["kunai", "kunai", "kunai", "senbon"] if i == 0 else ["shuriken", "shuriken", "fuma"]
					for k in kinds.size():
						var kd: String = kinds[k]
						var to = aimw + side * (k - (kinds.size() - 1) * 0.5) * 0.45
						who.get_tree().create_timer(k * 0.05).timeout.connect(func():
							if is_instance_valid(who):
								pjw.throw_weapon(who, "buki_kuchiyose", kd, from0 + side * randf_range(-0.2, 0.2), to, 46.0, 0.3, tg, {"dmg": dmg * (0.32 if i == 0 else 0.42)}))
				2:   # kusarigama zinciri: kancalı orak hedefe, zincirle çeker
					if tg and tg.global_position.distance_to(who.global_position) < 15.0:
						var kama = pjw.mi_of(pjw.weapon_mesh("kama"))
						who.get_tree().current_scene.add_child(kama)
						kama.global_position = from0
						var chain = StandardMaterial3D.new()
						chain.albedo_color = Color(0.45, 0.45, 0.5)
						pjw.tether(func(): return (who.global_position + Vector3.UP * 1.3) if is_instance_valid(who) else from0, func(): return kama.global_position if is_instance_valid(kama) else from0, 0.025, chain, 0.7)
						var tgt = tg
						var tw = kama.create_tween()
						tw.tween_method(func(u: float):
							if is_instance_valid(kama) and is_instance_valid(tgt):
								kama.global_position = from0.lerp(tgt.global_position + Vector3.UP, u)
								kama.rotation.x = u * TAU * 3.0, 0.0, 1.0, 0.18)
						tw.tween_callback(func():
							if is_instance_valid(who) and is_instance_valid(tgt):
								Combat.hit_sphere(who, tgt.global_position + Vector3.UP, 1.0, _kinfo(dmg, 1.0, {"element": "", "knock": 0.0, "kind": "heavy", "bleed": 2.0, "stun": 0.4}))
								var to3 = who.global_position + who.face_dir() * 1.8
								to3.y = Game.ground_height(to3.x, to3.z)
								tgt.create_tween().tween_property(tgt, "global_position", to3, 0.3))
						tw.tween_method(func(u: float):
							if is_instance_valid(kama) and is_instance_valid(who):
								kama.global_position = kama.global_position.lerp(who.global_position + Vector3.UP * 1.3, u), 0.0, 1.0, 0.3)
						tw.tween_callback(kama.queue_free)
				3:   # havadan silah yağmuru: hedefin üstünden karışık silahlar düşer (Sōshōryū küçük)
					var c0 = tg.global_position if tg and tg.global_position.distance_to(who.global_position) < 18.0 else who.global_position + f * 7.0
					for k in 10:
						var kd2: String = ["kunai", "katana", "sai", "yari", "kama", "shuriken", "kunai", "chakram", "senbon", "ono"][k]
						var land = c0 + Vector3(randf_range(-1.8, 1.8), 0, randf_range(-1.8, 1.8))
						land.y = Game.ground_height(land.x, land.z) + 0.2
						var sky = land + Vector3(randf_range(-2.0, 2.0), 9.0, randf_range(-2.0, 2.0))
						who.get_tree().create_timer(k * 0.04).timeout.connect(func():
							if is_instance_valid(who):
								pjw.throw_weapon(who, "soshoryu", kd2, sky, land, 40.0, 0.3, null, {"dmg": dmg * 0.3}))
					who.get_tree().create_timer(0.35).timeout.connect(func():
						if is_instance_valid(who):
							Combat.hit_sphere(who, c0 + Vector3.UP * 0.6, 2.4, _kinfo(dmg, 0.8, {"element": "", "knock": 2.0, "kind": "light", "bleed": 2.0})))
				4:   # dev balta: parşömenden çekilip tepeden indirilir
					var ono = pjw.mi_of(pjw.weapon_mesh("ono"))
					who.get_tree().current_scene.add_child(ono)
					ono.scale = Vector3.ONE * 3.0
					var g = who.global_position + f * 2.0
					g.y = Game.ground_height(g.x, g.z)
					ono.global_position = g + Vector3.UP * 4.0
					ono.look_at(g + f * 3.0 + Vector3.UP * 4.0, Vector3.UP)
					var tw4 = ono.create_tween()
					tw4.tween_property(ono, "global_position", g + Vector3.UP * 0.8, 0.12).set_ease(Tween.EASE_IN)
					tw4.parallel().tween_property(ono, "rotation:x", ono.rotation.x - 1.4, 0.12)
					tw4.tween_callback(func():
						VFX.cracks(g, 2.4)
						VFX.debris(g, Color(0.5, 0.45, 0.4), 10, 5.0, 0.3)
						if is_instance_valid(who):
							Combat.hit_sphere(who, g + Vector3.UP * 0.6, 2.0, _kinfo(dmg, 1.6, {"element": "", "knock": 8.0, "kind": "heavy", "stun": 0.5})))
					tw4.tween_interval(0.5)
					tw4.tween_property(ono, "scale", Vector3.ONE * 0.05, 0.15)
					tw4.tween_callback(ono.queue_free)
				5:   # dev demir topuz gökten iner (kuchiyose mührü avuçla yere)
					var center = tg.global_position if tg and tg.global_position.distance_to(who.global_position) < 18.0 else who.global_position + f * 8.0
					center.y = Game.ground_height(center.x, center.z)
					var ball = pjw.mi_of(pjw._tetsuzan_mesh())
					who.get_tree().current_scene.add_child(ball)
					ball.scale = Vector3.ONE * 0.4
					ball.global_position = center + Vector3.UP * 16.0
					var tw5 = ball.create_tween()
					tw5.tween_property(ball, "global_position", center + Vector3.UP * 1.3, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					tw5.tween_callback(func():
						VFX.cracks(center, 6.0)
						VFX.debris(center, Color(0.45, 0.38, 0.3), 16, 9.0, 0.5)
						VFX.shockwave(center + Vector3.UP * 0.3, Color(0.85, 0.75, 0.6), 9.0, 0.4, true)
						if is_instance_valid(who):
							Combat.hit_sphere(who, center + Vector3.UP, 3.2, _kinfo(dmg, 2.4, {"element": "", "knock": 12.0, "launch": 7.0, "kind": "heavy", "hitstop": 0.12}))
							_shake(who, 0.8)
						Sfx.play("boom", center, 0.8))
					tw5.tween_interval(1.0)
					tw5.tween_property(ball, "scale", Vector3.ONE * 0.02, 0.25)
					tw5.tween_callback(ball.queue_free)
		"style_hiraishin":
			var tg = _hira_target(who)
			var pjh = PathJutsu.get_pinst()
			if pjh == null:
				return
			var yel = Color(1.0, 0.9, 0.4)
			match i:
				0:   # üç kunai yelpazesi: hedefin çevresine saplanır, her biri işaret
					var aim0 = tg.global_position if tg and tg.global_position.distance_to(who.global_position) < 18.0 else who.global_position + f * 8.0
					var from = who.global_position + Vector3.UP * 1.5 + f * 0.4
					for k in 3:
						var land = aim0 + side * (k - 1) * 1.6 - f * (0.6 if k != 1 else 0.0)
						land.y = Game.ground_height(land.x, land.z) + 0.15
						_hira_throw(who, from, land, 0.16 + k * 0.03, true)
					if tg:
						who.get_tree().create_timer(0.2).timeout.connect(func():
							if is_instance_valid(who) and is_instance_valid(tg) and tg.global_position.distance_to(aim0) < 1.8:
								Combat.hit_sphere(who, tg.global_position + Vector3.UP, 0.9, _kinfo(dmg, 0.7, {"element": "", "knock": 1.5, "kind": "light", "bleed": 1.0}))
								if tg.has_method("apply_status"):
									tg.apply_status("marked", 20.0)
									tg.set_meta("hiraishin_by", who.get_instance_id()))
				1:   # ışınlandığı kunainin yanında el kılıcı (yatay)
					pjh._arc_cut(who.global_position + Vector3.UP * 1.15, who.face_dir(), -80.0, 80.0, yel, 2.0)
					Combat.hit_zone(who, who.global_position, who.face_dir(), 2.6, 60.0, 2.2, _kinfo(dmg, 1.1, {"element": "", "knock": 6.0, "kind": "heavy", "melee": true}))
				2:   # Ni no Dan: arkadan yukarı tekme
					var kp = who.global_position + Vector3.UP * 1.0 + who.face_dir() * 0.9
					VFX.star(kp, yel, 1.8, 0.12)
					Combat.hit_sphere(who, kp, 1.4, _kinfo(dmg, 1.3, {"element": "", "knock": 3.0, "launch": 8.0, "kind": "heavy", "melee": true}))
				3:   # yukarıdan iniş darbesi: yere çarpar
					var g3 = who.global_position + who.face_dir() * 0.6
					g3.y = Game.ground_height(g3.x, g3.z)
					VFX.shockwave(g3 + Vector3.UP * 0.1, yel, 4.0, 0.25, true)
					VFX.cracks(g3, 2.2)
					Combat.hit_sphere(who, g3 + Vector3.UP * 0.6, 2.0, _kinfo(dmg, 1.4, {"element": "", "knock": 5.0, "kind": "heavy", "melee": true, "stun": 0.5}))
					_shake(who, 0.35)
				4:   # kunailer arası zincir kesik: her işarette bir flaş, yakınındakiler kesilir, başa dön
					var start = who.global_position
					var marks = _hira_marks(who).filter(func(m): return (m["pos"] as Vector3).distance_to(start) < 18.0).slice(0, 3)
					if marks.is_empty() and tg:
						marks = [{"pos": tg.global_position - (tg.global_position - start).normalized() * 1.2}]
					for k in marks.size():
						var mp: Vector3 = marks[k]["pos"]
						who.get_tree().create_timer(k * 0.09).timeout.connect(func():
							if not is_instance_valid(who):
								return
							var prev = who.global_position
							_hira_hop(who, mp, _near_foe_at(who, mp, 3.0))
							VFX.bolt(prev + Vector3.UP, who.global_position + Vector3.UP, yel, 0.08, 0.15, 0)
							pjh._arc_cut(who.global_position + Vector3.UP * 1.1, who.face_dir(), -90.0, 90.0, yel, 2.2)
							Combat.hit_sphere(who, who.global_position + Vector3.UP, 2.4, _kinfo(dmg, 0.8, {"element": "", "knock": 5.0, "kind": "heavy", "bleed": 1.5})))
					who.get_tree().create_timer(marks.size() * 0.09 + 0.12).timeout.connect(func():
						if is_instance_valid(who):
							_hira_hop(who, start, null))
				5:   # arkadan Rasengan
					var at5 = who.global_position + Vector3.UP * 1.1 + who.face_dir() * 0.9
					var dome = VFX.rasengan(0.8)
					who.get_tree().current_scene.add_child(dome)
					dome.global_position = at5
					var tw5 = dome.create_tween()
					tw5.tween_property(dome, "scale", Vector3.ONE * 2.4, 0.2)
					tw5.tween_property(dome, "scale", Vector3.ONE * 0.05, 0.15)
					tw5.tween_callback(dome.queue_free)
					VFX.shockwave(at5, Color(0.6, 0.85, 1.0), 3.6, 0.3, false, who.face_dir())
					Combat.hit_sphere(who, at5, 1.7, _kinfo(dmg, 2.4, {"element": "", "knock": 18.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.12}))
					_shake(who, 0.6)
		"style_kagit":
			var tg = _near_foe(who, 16.0)
			var pjk = PathJutsu.get_pinst()
			if pjk == null:
				return
			var aimk = (tg.global_position + Vector3.UP) if tg else who.global_position + f * 8.0 + Vector3.UP
			var handk = who.global_position + Vector3.UP * 1.35 + f * 0.5
			match i:
				0, 1:   # kâğıt shuriken
					var mesh = pjk._paper_star().build(Props.toon())
					for k in 3:
						var mi = MeshInstance3D.new()
						mi.mesh = mesh
						who.get_tree().current_scene.add_child(mi)
						var st = handk + side * ((0.3 if i == 0 else -0.3) + (k - 1) * 0.2)
						mi.global_position = st
						var to = aimk + side * (k - 1) * 0.5
						var tw = mi.create_tween()
						tw.tween_property(mi, "global_position", to, 0.25 + k * 0.03)
						tw.parallel().tween_property(mi, "rotation:y", TAU * 4.0, 0.3)
						tw.tween_callback(func():
							if is_instance_valid(who):
								Combat.hit_sphere(who, to, 0.9, _kinfo(dmg, 0.45, {"element": "", "knock": 2.0, "kind": "light", "bleed": 1.5})))
						tw.tween_callback(mi.queue_free)
				2:   # kelebek sürüsü: hedefi sarar, kör eder
					for k in 12:
						var bf = pjk._paper_butterfly(k)
						who.get_tree().current_scene.add_child(bf)
						var st2 = handk + Vector3(randf_range(-0.5, 0.5), randf_range(-0.3, 0.4), randf_range(-0.5, 0.5))
						bf.global_position = st2
						var to2 = aimk + Vector3(randf_range(-0.8, 0.8), randf_range(-0.6, 0.8), randf_range(-0.8, 0.8))
						var tw2 = bf.create_tween()
						tw2.tween_interval(k * 0.03)
						tw2.tween_property(bf, "global_position", to2, 0.45).set_trans(Tween.TRANS_SINE)
						tw2.tween_interval(0.6)
						tw2.tween_callback(bf.queue_free)
					Combat.hit_sphere(who, aimk, 1.6, _kinfo(dmg, 0.8, {"element": "", "knock": 0.0, "kind": "light", "blind": 2.0, "slow": 1.5}))
				3:   # Kami Yari: hedefin altından kâğıt mızraklar
					var p = Vector3(aimk.x, Game.ground_height(aimk.x, aimk.z), aimk.z)
					for k in 7:
						var mi2 = MeshInstance3D.new()
						mi2.mesh = pjk._paper_spear(randf_range(1.8, 2.8)).build(Props.toon())
						who.get_tree().current_scene.add_child(mi2)
						var q = p + Vector3(randf_range(-0.9, 0.9), -2.5, randf_range(-0.9, 0.9))
						mi2.global_position = q
						mi2.rotation = Vector3(randf_range(-0.3, 0.3), randf() * TAU, randf_range(-0.3, 0.3))
						var tw3 = mi2.create_tween()
						tw3.tween_interval(k * 0.02)
						tw3.tween_property(mi2, "global_position:y", p.y - 0.2, 0.12).set_trans(Tween.TRANS_BACK)
						tw3.tween_interval(0.8)
						tw3.tween_property(mi2, "global_position:y", p.y - 3.0, 0.3)
						tw3.tween_callback(mi2.queue_free)
					Combat.hit_sphere(who, p + Vector3.UP, 1.8, _kinfo(dmg, 1.3, {"element": "", "knock": 2.0, "launch": 6.0, "kind": "heavy", "bleed": 2.0}))
				4:   # kanat çırpışı: kesici kâğıt fırtınası (öne)
					for k in 14:
						var bf2 = pjk._paper_butterfly(k)
						who.get_tree().current_scene.add_child(bf2)
						var o = who.global_position + Vector3.UP * 1.4
						bf2.global_position = o
						var to3 = o + (f + side * randf_range(-0.6, 0.6)).normalized() * randf_range(5.0, 8.0) + Vector3.UP * randf_range(-0.8, 0.8)
						var tw4 = bf2.create_tween()
						tw4.tween_property(bf2, "global_position", to3, 0.4)
						tw4.tween_callback(bf2.queue_free)
					Combat.hit_zone(who, who.global_position, f, 7.0, 35.0, 2.6, _kinfo(dmg, 1.0, {"element": "", "knock": 8.0, "kind": "heavy", "bleed": 2.0}))
				5:   # Shikigami no Mai: hedefin çevresinde patlayıcı kâğıt halkası
					var c0 = aimk - Vector3.UP
					for k in 10:
						var a = TAU * k / 10.0
						var q2 = c0 + Vector3(cos(a), 0.4, sin(a)) * 2.2
						who.get_tree().create_timer(0.1 + k * 0.04).timeout.connect(func():
							VFX.explosion(q2, 0.7, Color(1.0, 0.65, 0.25)))
					who.get_tree().create_timer(0.35).timeout.connect(func():
						if is_instance_valid(who):
							Combat.hit_sphere(who, c0 + Vector3.UP, 3.4, _kinfo(dmg, 2.0, {"element": "katon", "knock": 9.0, "launch": 4.0, "kind": "heavy", "burn": 2.0}))
							_shake(who, 0.5))
		"style_sumi":
			var tg = _near_foe(who, 16.0)
			var pjs = PathJutsu.get_pinst()
			if pjs == null:
				return
			var aims = tg.global_position if tg else who.global_position + f * 8.0
			var st0 = who.global_position + f * 1.0
			match i:
				0, 1:   # mürekkep aslan sayfadan fırlar
					_ink_run(who, pjs, "tiger", 0.5, st0 + side * (0.4 if i == 0 else -0.4), aims, dmg * 1.0, {"knock": 5.0})
				2:   # mürekkep ejder (yılan) dolanıp bağlar
					_ink_run(who, pjs, "dragon", 0.45, st0 + Vector3.UP * 0.8, aims + Vector3.UP * 0.8, dmg * 0.8, {"bind": 1.2, "knock": 0.0})
				3:   # üç aslan sürüsü
					for k in 3:
						var off = side * (k - 1) * 0.8
						who.get_tree().create_timer(k * 0.08).timeout.connect(func():
							if is_instance_valid(who):
								_ink_run(who, pjs, "tiger", 0.45, st0 + off, aims + off * 0.4, dmg * 0.6, {"knock": 4.0}))
				4:   # mürekkep sisi
					for k in 5:
						var q = who.global_position + Vector3.UP * 1.0 + f * (1.5 + k * 1.2)
						who.get_tree().create_timer(k * 0.05).timeout.connect(func():
							VFX.puffs(q, {"amount": 12, "life": 2.2, "size": 1.4, "radius": 0.7 + k * 0.2, "vmin": 0.2, "vmax": 0.8, "dir": f, "spread": 60.0, "add": false,
								"colors": [Color(0.06, 0.06, 0.08, 0.9), Color(0.1, 0.1, 0.12, 0.0)]}))
					Combat.hit_zone(who, who.global_position, f, 7.0, 30.0, 2.4, _kinfo(dmg, 0.4, {"element": "", "knock": 0.0, "kind": "light", "blind": 2.0, "slow": 2.0}))
				5:   # Chōjū Giga: dev mürekkep kaplan + ejder birden
					_ink_run(who, pjs, "tiger", 1.2, st0, aims, dmg * 1.5, {"knock": 10.0, "launch": 4.0})
					who.get_tree().create_timer(0.15).timeout.connect(func():
						if is_instance_valid(who):
							_ink_run(who, pjs, "dragon", 0.9, st0 + Vector3.UP * 2.0, aims + Vector3.UP * 1.0, dmg * 1.0, {"knock": 6.0, "bind": 1.0}))
					_shake(who, 0.4)
		"style_akasuna":
			var tg = _near_foe(who, 14.0)
			var pjp = PathJutsu.get_pinst()
			if pjp == null:
				return
			var aimp = tg.global_position if tg else who.global_position + f * 6.0
			match i:
				0:   # kukla yanından atılıp keser, geri döner
					_puppet_lunge(who, pjp, who.global_position + side * 1.4 + f * 0.8, aimp, dmg * 1.1, {"bleed": 2.0})
				1:   # kuklanın ağzından zehirli iğneler
					var pup = _style_puppet(who, pjp, who.global_position - side * 1.4 + f * 0.6, f, 0.9)
					for k in 4:
						var o = pup.global_position + Vector3.UP * 1.5
						who.get_tree().create_timer(0.1 + k * 0.05).timeout.connect(func():
							if is_instance_valid(who):
								Projectile.tool(who, o, ((aimp + Vector3.UP * 1.0) - o).normalized().rotated(Vector3.UP, (k - 1.5) * 0.06), "senbon", tg))
					if tg:
						Combat.hit_sphere(who, tg.global_position + Vector3.UP, 1.0, _kinfo(dmg, 0.5, {"element": "", "knock": 1.0, "kind": "light", "poison": 4.0}))
				2:   # bıçaklı kollarla dönen kukla
					var pup2 = _style_puppet(who, pjp, aimp - f * 1.2, f, 0.9)
					var tw = pup2.create_tween()
					tw.tween_property(pup2, "rotation:y", pup2.rotation.y + TAU * 3.0, 0.7)
					Combat.hit_sphere(who, aimp + Vector3.UP, 2.2, _kinfo(dmg, 1.3, {"element": "", "knock": 6.0, "kind": "heavy", "bleed": 3.0}))
				3:   # chakra iplikleri rakibi çeker
					if tg:
						pjp._chakra_strings(who, [tg], 0.8)
						var tgt = tg
						var tw2 = tg.create_tween()
						tw2.tween_property(tg, "global_position", who.global_position + f * 1.8, 0.35)
						Combat.hit_sphere(who, who.global_position + f * 1.8 + Vector3.UP, 1.2, _kinfo(dmg, 0.7, {"element": "", "knock": 0.0, "kind": "light", "bind": 0.6}))
				4:   # mor zehir gazı
					var pup3 = _style_puppet(who, pjp, who.global_position + f * 1.0, f, 1.0)
					for k in 5:
						var q = pup3.global_position + Vector3.UP * 1.3 + f * (1.0 + k * 1.0)
						who.get_tree().create_timer(k * 0.06).timeout.connect(func():
							VFX.puffs(q, {"amount": 10, "life": 1.8, "size": 1.3, "radius": 0.6 + k * 0.2, "vmin": 0.3, "vmax": 1.0, "dir": f, "spread": 50.0, "add": false,
								"colors": [Color(0.55, 0.3, 0.6, 0.85), Color(0.35, 0.2, 0.4, 0.0)]}))
					Combat.hit_zone(who, who.global_position, f, 6.0, 30.0, 2.4, _kinfo(dmg, 0.6, {"element": "", "knock": 0.0, "kind": "light", "poison": 5.0, "slow": 2.0}))
				5:   # Akahigi: hedefin çevresinde dört kukla birden
					for k in 4:
						var a = TAU * k / 4.0
						var st = aimp + Vector3(cos(a), 0, sin(a)) * 3.2
						who.get_tree().create_timer(k * 0.06).timeout.connect(func():
							if is_instance_valid(who):
								_puppet_lunge(who, pjp, st, aimp, dmg * 0.7, {"bleed": 2.0, "poison": 2.0}))
		"style_kil":
			var tg = _near_foe(who, 18.0)
			var hand = who.global_position + Vector3.UP * 1.3 + f * 0.5
			var aim = (tg.global_position + Vector3.UP * 0.6) if tg else who.global_position + f * 9.0 + Vector3.UP * 0.6
			match i:
				0, 1:   # kil örümcekler (avuç ağzından)
					for k in 2:
						_clay_fly(who, "spider", hand + side * ((0.3 if i == 0 else -0.3) + (k - 0.5) * 0.3), aim + side * (k - 0.5) * 0.6, 0.35, 0.35 + k * 0.05, 0.0, dmg * 0.6, 0.6)
				2:   # kil kuş: yukarı süzülüp hedefe dalar
					_clay_fly(who, "bird", hand + Vector3.UP * 0.5, aim, 0.6, 0.7, 3.5, dmg * 1.2, 1.0)
				3:   # Jirai: hedefin altına kil mayın — kısa gecikmeyle patlar
					var p = Vector3(aim.x, Game.ground_height(aim.x, aim.z), aim.z)
					var mine = ClayArt.spider(0.35)
					who.get_tree().current_scene.add_child(mine)
					mine.global_position = p - Vector3.UP * 0.15
					who.get_tree().create_timer(0.45).timeout.connect(func():
						if is_instance_valid(mine):
							mine.queue_free()
						VFX.clay_blast(p + Vector3.UP * 0.4, 1.0)
						if is_instance_valid(who):
							Combat.hit_sphere(who, p + Vector3.UP * 0.6, 2.4, _kinfo(dmg, 1.3, {"element": "doton", "knock": 4.0, "launch": 7.0, "kind": "heavy"})))
				4:   # üç kuşluk dalga
					for k in 3:
						_clay_fly(who, "bird", hand + side * (k - 1) * 0.6 + Vector3.UP * 0.4, aim + side * (k - 1) * 1.2, 0.5, 0.6 + k * 0.08, 3.0, dmg * 0.7, 0.9)
				5:   # Katsu!: dev kil bebek hedefe düşüp büyük patlama
					var doll = ClayArt.doll(1.2)
					who.get_tree().current_scene.add_child(doll)
					var top = aim + Vector3.UP * 9.0
					doll.global_position = top
					var tw = doll.create_tween()
					tw.tween_property(doll, "global_position", aim - Vector3.UP * 0.4, 0.45).set_ease(Tween.EASE_IN)
					tw.tween_callback(func():
						VFX.clay_blast(aim, 2.2)
						if is_instance_valid(who):
							Combat.hit_sphere(who, aim, 4.2, _kinfo(dmg, 2.2, {"element": "doton", "knock": 12.0, "launch": 6.0, "kind": "heavy"}))
							_shake(who, 0.7))
					tw.tween_callback(doll.queue_free)
					Combat.popup_text(who.global_position + Vector3.UP * 2.4, "Katsu!", Color(1.0, 0.95, 0.85))
		"style_kapi":
			var tg = _near_foe(who, 14.0)
			match i:
				0, 1:   # tekme rüzgârı
					WindFX.streak(func(u: float) -> Vector3:
						var a = lerpf(1.2, -1.2, u) * (1.0 if i == 0 else -1.0)
						return who.global_position + Vector3.UP * (1.3 if i == 0 else 0.3) + (f * cos(a) - side * sin(a)) * 1.6, 0.18, 0.12, Color(0.9, 1.0, 0.92, 0.9), 0.0, 12)
				3:   # topuk inişi
					var g = who.global_position + f * 0.6
					g.y = Game.ground_height(g.x, g.z)
					VFX.cracks(g, 2.4)
					VFX.debris(g + Vector3.UP * 0.3, Color(0.55, 0.5, 0.42), 8, 5.0, 0.3)
					Combat.hit_sphere(who, g + Vector3.UP * 0.6, 2.2, _kinfo(dmg, 1.4, {"element": "", "knock": 6.0, "launch": -4.0, "kind": "heavy", "melee": true}))
					_shake(who, 0.4)
				4:   # Asakujaku: sırttan tavuskuşu yelpazesi gibi açılan alevli yumruklar hedefe yağar (gerçek p_asakujaku görünüşü)
					var aim = (tg.global_position + Vector3.UP) if tg else who.global_position + f * 8.0 + Vector3.UP
					for k in 10:
						var a2 = lerpf(-1.2, 1.2, k / 9.0)
						var from = who.global_position + Vector3.UP * 1.3 + (side * sin(a2) + Vector3.UP * cos(a2)) * 1.4 - f * 0.3
						who.get_tree().create_timer(k * 0.04).timeout.connect(func():
							var fb = VFX.fireball(0.45)
							who.get_tree().current_scene.add_child(fb)
							fb.global_position = from
							var to = aim + side * randf_range(-0.7, 0.7) + Vector3.UP * randf_range(-0.4, 0.6)
							var tw = fb.create_tween()
							tw.tween_property(fb, "global_position", to, 0.18)
							tw.tween_callback(func():
								FX.burst(to, {"amount": 8, "life": 0.25, "tex": FX.tex_spark, "size": 0.3, "vmin": 3.0, "vmax": 7.0, "spread": 180.0, "colors": [Color(1, 0.95, 0.6, 1), Color(1, 0.4, 0.1, 0)]})
								if is_instance_valid(who):
									Combat.hit_sphere(who, to, 1.0, _kinfo(dmg, 0.25, {"element": "katon", "knock": 1.5, "kind": "light", "burn": 1.0})))
							tw.tween_callback(fb.queue_free))
				5:   # Hirudora: avuçtan kaplan başı hava basıncı (gerçek _tiger_head modeli)
					var pjh = PathJutsu.get_pinst()
					if pjh:
						var node = pjh._tiger_head(1.1)
						who.get_tree().current_scene.add_child(node)
						var st0 = who.global_position + Vector3.UP * 1.4 + f * 1.4
						node.global_position = st0
						node.look_at(st0 + f, Vector3.UP)
						node.scale = Vector3.ONE * 0.2
						var tw2 = node.create_tween()
						tw2.tween_property(node, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK)
						tw2.parallel().tween_property(node, "global_position", st0 + f * 12.0, 0.5)
						tw2.tween_callback(node.queue_free)
					Combat.hit_zone(who, who.global_position, f, 12.0, 20.0, 3.0, _kinfo(dmg, 2.0, {"element": "", "knock": 18.0, "launch": 5.0, "kind": "heavy"}))
					_shake(who, 0.6)
		"style_nara":
			var tg = _near_foe(who, minf(12.0, Jutsu.shadow_reach()))
			if tg == null:
				return
			match i:
				0, 1:   # gölge kırbacı: şerit uzanır, hedefin altından şaplar
					Jutsu._shadow_line(who, tg, 0.6)
					who.get_tree().create_timer(0.25).timeout.connect(func():
						if is_instance_valid(who) and is_instance_valid(tg):
							Combat.hit_sphere(who, tg.global_position + Vector3.UP * 0.8, 1.0, _kinfo(dmg, 0.8, {"element": "", "knock": 3.0, "kind": "light", "slow": 1.0})))
				2:   # Kagemane: kısa gölge bağı (tarz vuruşu: jutsudan kısa)
					Jutsu._shadow_line(who, tg, 1.6)
					who.get_tree().create_timer(0.35).timeout.connect(func():
						if is_instance_valid(who) and is_instance_valid(tg):
							Combat.hit_sphere(who, tg.global_position + Vector3.UP * 0.8, 1.0, _kinfo(dmg, 0.4, {"element": "", "knock": 0.0, "kind": "light", "bind": 1.2})))
				3:   # Kage Nui: gölge iğneleri yerden fırlayıp deler
					Jutsu._shadow_line(who, tg, 1.2)
					who.get_tree().create_timer(0.35).timeout.connect(func():
						if is_instance_valid(who) and is_instance_valid(tg):
							_shadow_needles(tg, 5)
							Combat.hit_sphere(who, tg.global_position + Vector3.UP, 1.2, _kinfo(dmg, 1.3, {"element": "", "knock": 0.0, "kind": "heavy", "bleed": 2.0, "bind": 0.6})))
				4:   # Kage Kubi Shibari: gölge eller tırmanır, süreli boğma
					Jutsu._shadow_line(who, tg, 1.8)
					for k in 5:
						who.get_tree().create_timer(0.35 + k * 0.25).timeout.connect(func():
							if is_instance_valid(who) and is_instance_valid(tg) and not tg.is_dead():
								_shadow_hand(tg)
								Combat.hit_sphere(who, tg.global_position + Vector3.UP * 1.3, 0.9, _kinfo(dmg, 0.3, {"element": "", "knock": 0.0, "kind": "light", "bind": 0.4})))
				5:   # Kagemane + Kage Nui: bağla, kollar açılınca çevreden iğne yağmuru
					Jutsu._shadow_line(who, tg, 1.8)
					who.get_tree().create_timer(0.3).timeout.connect(func():
						if is_instance_valid(who) and is_instance_valid(tg):
							Combat.hit_sphere(who, tg.global_position + Vector3.UP, 1.0, _kinfo(dmg, 0.2, {"element": "", "knock": 0.0, "kind": "light", "bind": 1.0})))
					who.get_tree().create_timer(0.55).timeout.connect(func():
						if is_instance_valid(who) and is_instance_valid(tg):
							_shadow_needles(tg, 12)
							Combat.hit_sphere(who, tg.global_position + Vector3.UP, 1.6, _kinfo(dmg, 2.0, {"element": "", "knock": 4.0, "launch": 3.0, "kind": "heavy", "bleed": 3.0}))
							_shake(who, 0.4))
		"style_hatake":
			var tg = _near_foe(who, 14.0)
			var rai = Color(0.65, 0.85, 1.0)
			match i:
				2:   # Shunshin sonrası geriye dirsek
					Combat.hit_sphere(who, who.global_position + Vector3.UP * 1.2 - who.face_dir() * 0.7 if who.has_method("face_dir") else at, 1.2, _kinfo(dmg, 1.2, {"element": "", "knock": 8.0, "kind": "heavy", "melee": true}))
				3:   # Raijū Tsuiga: şimşek tazısı hedefe koşar (ref hatake_1)
					_rai_hound(who, tg, dmg * 1.3, f)
				4:   # Doton Tsuiga: yerden ninkenler fırlayıp hedefi ısırır, tutar (ref hatake_2) — oyunun gerçek ninken modeli
					if tg:
						var p = tg.global_position
						for k in 4:
							var a = TAU * k / 4.0
							var q = p + Vector3(cos(a), 0, sin(a)) * 1.1
							q.y = Game.ground_height(q.x, q.z)
							who.get_tree().create_timer(0.05 + k * 0.05).timeout.connect(func():
								VFX.debris(q, Color(0.55, 0.47, 0.38), 5, 4.0, 0.25)
								var dog: Node3D = SummonModels.build("dog_small" if k == 0 else "dog_pack", 0.45 if k == 0 else 0.62, 1.0)["root"]
								who.get_tree().current_scene.add_child(dog)
								dog.global_position = q - Vector3.UP * 0.7
								dog.look_at(Vector3(p.x, dog.global_position.y, p.z), Vector3.UP)
								var tw = dog.create_tween()
								tw.tween_property(dog, "global_position", q + (p - q) * 0.45 + Vector3.UP * 0.2, 0.18)
								tw.tween_interval(1.4)
								tw.tween_property(dog, "global_position:y", q.y - 0.8, 0.25)
								tw.tween_callback(dog.queue_free))
						Combat.hit_sphere(who, p + Vector3.UP * 0.6, 1.4, _kinfo(dmg, 0.9, {"element": "", "knock": 0.0, "kind": "heavy", "bleed": 2.0, "bind": 1.6}))
				5:   # Raikiri: hedefe dalıp sapla
					var to = (tg.global_position - f * 0.9) if tg and tg.global_position.distance_to(who.global_position) < 10.0 else who.global_position + f * 6.0
					to.y = Game.ground_height(to.x, to.z)
					var from = who.global_position
					FX.speed_lines(from + Vector3.UP, f)
					var tw2 = who.create_tween()
					tw2.tween_property(who, "global_position", to, 0.12)
					for k in 5:
						VFX.bolt(from.lerp(to, k / 4.0) + Vector3.UP * 1.1, from.lerp(to, (k + 1) / 4.0) + Vector3.UP * 1.1, rai, 0.16, 0.25, 2)
					who.get_tree().create_timer(0.12).timeout.connect(func():
						if is_instance_valid(who):
							var hp2 = who.global_position + Vector3.UP * 1.1 + f * 0.8
							VFX.star(hp2, Color(0.9, 0.96, 1.0), 2.6, 0.18)
							for k2 in 4:
								VFX.bolt(hp2, hp2 + Vector3(randf_range(-2, 2), randf_range(-1, 1.5), randf_range(-2, 2)), rai, 0.12, 0.2, 1)
							Combat.hit_sphere(who, hp2, 1.4, _kinfo(dmg, 2.2, {"element": "raiton", "knock": 10.0, "kind": "heavy", "stun": 0.8, "pierce_guard": true}))
							_shake(who, 0.5)
							Sfx.play("chidori", hp2, 1.0, 0.8))
		"style_sarutobi":
			var tg = _near_foe(who, 12.0)
			var pj2 = PathJutsu.get_pinst()
			var mouth = who.global_position + Vector3.UP * 1.55 + f * 0.4
			match i:
				0, 1:   # Hien: rüzgâr chakralı yumruk — ileri kısa mavi-beyaz kesik
					var sx = 1.0 if i == 0 else -1.0
					var o = who.global_position + Vector3.UP * 1.3 + side * sx * 0.2
					for k in 2:   # yumruğun önünden iki kavisli rüzgâr kesiği (Asuma'nın Hien akışı)
						WindFX.streak(func(t: float) -> Vector3: return o + Vector3.UP * (k - 0.5) * 0.25 + f * (0.5 + t * 2.6) + side * sin(t * PI) * 0.35 * sx, 0.22, 0.13, Color(0.78, 0.92, 1.0, 0.95), k * 0.03, 12)
					FX.hit_spark(o + f * 1.2, Color(0.8, 0.93, 1.0), 0.6)
					Combat.hit_zone(who, who.global_position, f, 2.8, 30.0, 2.2, _kinfo(dmg, 1.0, {"element": "fuuton", "knock": 5.0, "kind": "light", "melee": true, "bleed": 1.0}))
				2:   # Haisekishō: kül bulutu (ref sarutobi_0) — göz alır, yavaşlatır; bulut 4 sn kalır, tutuşturulabilir
					for k in 6:
						var q = mouth + f * (1.5 + k * 1.2)
						who.get_tree().create_timer(k * 0.06).timeout.connect(func():
							VFX.puffs(q, {"amount": 14, "life": 3.5, "size": 1.6, "radius": 0.7 + k * 0.25, "vmin": 0.3, "vmax": 1.2, "dir": f, "spread": 50.0, "add": false,
								"colors": [Color(0.48, 0.48, 0.5, 0.92), Color(0.32, 0.32, 0.34, 0.0)]}))
					who.set_meta("ash_cloud", [who.global_position + f * 4.5, Time.get_ticks_msec() / 1000.0 + 4.0])
					Combat.hit_zone(who, who.global_position, f, 8.0, 25.0, 2.6, _kinfo(dmg, 0.25, {"element": "katon", "knock": 0.0, "kind": "light", "slow": 2.5, "blind": 1.5}))
				3:   # diş çakılır: kül bulutu varsa patlar (ref sarutobi_1), yoksa küçük kıvılcım
					var ac = who.get_meta("ash_cloud", [])
					if not ac.is_empty() and Time.get_ticks_msec() / 1000.0 < float(ac[1]):
						var c0: Vector3 = ac[0]
						for k in 5:
							var q2 = c0 + Vector3(randf_range(-2.0, 2.0), randf_range(0.6, 1.8), randf_range(-2.0, 2.0))
							who.get_tree().create_timer(k * 0.05).timeout.connect(func(): VFX.explosion(q2, 0.9, Color(1.0, 0.6, 0.15)))
						Combat.hit_sphere(who, c0 + Vector3.UP, 3.6, _kinfo(dmg, 2.0, {"element": "katon", "knock": 8.0, "launch": 3.0, "kind": "heavy", "burn": 3.0}))
						who.remove_meta("ash_cloud")
						_shake(who, 0.5)
					else:
						FX.hit_spark(mouth + f * 0.3, Color(1.0, 0.7, 0.3), 0.6)
				4:   # Shuriken Kage Bunshin: tek shuriken havada yelpaze gibi çoğalır (ref sarutobi_2)
					var s0 = who.global_position + Vector3.UP * 1.5 + f * 0.6
					var aim = ((tg.global_position + Vector3.UP) - s0).normalized() if tg else f
					for k in 7:
						var dd = aim.rotated(Vector3.UP, deg_to_rad((k - 3) * 6.0))
						who.get_tree().create_timer(0.06 + k * 0.015).timeout.connect(func():
							if is_instance_valid(who):
								Projectile.tool(who, s0 + dd * 0.8, dd, "shuriken", tg))
				5:   # Karyū Endan: ağızdan kıvrılan ateş seli (ref sarutobi_3)
					if pj2:
						pj2.fire_stream(mouth + f * 0.6, f, 11.0, 3.2, 9)
					Combat.hit_zone(who, who.global_position, f, 11.0, 18.0, 3.0, _kinfo(dmg, 1.7, {"element": "katon", "knock": 7.0, "kind": "heavy", "burn": 3.0}))
					Sfx.play("fire", who.global_position, 0.9)
		"style_senju":
			var tg = _near_foe(who, 9.0)
			var pj = PathJutsu.get_pinst()
			var gcol = Color(0.55, 0.47, 0.38)
			match i:
				0, 1:   # Senju kanı: yumruğun ardında hava patlaması
					Combat.hit_sphere(who, at + f * 0.3, 1.1, _kinfo(dmg, 1.0, {"element": "", "knock": 7.0, "kind": "heavy", "melee": true}))
					VFX.shockwave(at + f * 0.6, Color(1.0, 0.95, 0.85), 1.6, 0.18, false, f)
				2:   # Mokuton Kesme: koldan rakibe dallar fışkırıp saplanır (ref senju_2/3)
					var hand = who.global_position + Vector3.UP * 1.3 + f * 0.6
					var to = tg.global_position + Vector3.UP * 1.0 if tg and tg.global_position.distance_to(who.global_position) < 6.5 else hand + f * 5.0
					if pj:
						var gh = Vector3(hand.x, Game.jutsu_floor(hand.x, hand.z), hand.z)   # _wood_trunk tabanı yere indirir: elden çıksın diye sonra ele taşınır
						for k in 3:
							var tip = to + side * (k - 1) * 0.35 + Vector3.UP * (k % 2) * 0.3
							var br: Node3D = pj._wood_trunk(hand, gh + (tip - hand), 0.07, 0.5, k * 0.04, 0.3)
							br.global_position = hand
					Combat.hit_sphere(who, to, 1.0, _kinfo(dmg, 1.2, {"element": "", "knock": 3.0, "kind": "heavy", "bleed": 2.0, "bind": 0.5}))
				3:   # avuçlar yere: hedefin altından tahta sütunlar fışkırıp kaldırır
					var p = tg.global_position if tg else who.global_position + f * 4.0
					if pj:
						for k in 3:
							var q = p + Vector3(randf_range(-0.7, 0.7), 0, randf_range(-0.7, 0.7))
							q.y = Game.ground_height(q.x, q.z)
							pj._wood_trunk(q, q + Vector3.UP * 3.2 + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4)), 0.32, 0.6, k * 0.06, 0.2)
					Combat.hit_sphere(who, p + Vector3.UP, 1.6, _kinfo(dmg, 1.15, {"element": "", "knock": 2.0, "launch": 8.0, "kind": "heavy"}))
				4:   # Ōkashō: yumruk yere — önündeki zemin sivri kayalarla kalkar (ref senju_0)
					var g = who.global_position + f * 1.8
					g.y = Game.ground_height(g.x, g.z)
					VFX.cracks(g, 4.0)
					VFX.debris(g + Vector3.UP * 0.3, gcol, 14, 7.0, 0.35)
					# Senju: önündeki zeminden sivri ahşap kazıklar fırlar (toprak dikeni değil — Mokuton kanı)
					if pj:
						for k in 7:
							var off = side * randf_range(-1.6, 1.6) + f * (1.0 + k * 0.45)
							var q2 = g + off
							q2.y = Game.ground_height(q2.x, q2.z)
							var lean = (f * 0.6 + side * randf_range(-0.4, 0.4)) * 0.6
							pj._wood_trunk(q2, q2 + Vector3.UP * randf_range(1.4, 2.2) + lean, randf_range(0.14, 0.22), 0.7, k * 0.03, 0.2)
					Combat.hit_zone(who, who.global_position, f, 5.0, 45.0, 2.5, _kinfo(dmg, 1.3, {"element": "", "knock": 6.0, "launch": 6.0, "kind": "heavy"}))
					_shake(who, 0.6)
				5:   # Tsūtenkyaku: topuk inişi — yuvarlak krater, çatlak, moloz patlaması (ref senju_1)
					var g2 = who.global_position + f * 0.8
					g2.y = Game.ground_height(g2.x, g2.z)
					VFX.cracks(g2, 5.5)
					VFX.shockwave(g2 + Vector3.UP * 0.1, gcol.lightened(0.2), 9.0, 0.4, true)
					VFX.debris(g2 + Vector3.UP * 0.4, gcol, 22, 9.0, 0.4)
					# son ağır darbe: inişin çevresinden ağaçlar fışkırır (Mokuton ormanının gerçek ağaçları) + kökler
					if pj:
						for k in 5:
							var a5 = k * TAU / 5.0 + randf() * 0.4
							var q5 = g2 + Vector3(cos(a5), 0, sin(a5)) * randf_range(2.6, 3.8)
							pj._wood_grow_tree(q5, randf_range(5.0, 7.5), k * 0.05, 2.4)
							pj._creep_root(g2, Vector3(cos(a5), 0, sin(a5)), 3.0, 0.25, 0.05, 2.2)
					Combat.hit_sphere(who, g2 + Vector3.UP * 0.6, 4.2, _kinfo(dmg, 1.5, {"element": "", "knock": 9.0, "launch": 7.0, "kind": "heavy"}))
					_shake(who, 0.8)
		"style_kurosuki":
			var tg = _near_foe(who, 12.0)
			var col = Color(0.82, 0.92, 1.0)
			match i:
				0, 1:   # el kılıcı ağzı boyunca şimşek (kısa kesik)
					var sx = 1.0 if i == 0 else -1.0
					var a0 = who.global_position + Vector3.UP * 1.7 + side * sx * 0.5 + f * 0.4
					var b0 = who.global_position + Vector3.UP * 0.8 - side * sx * 0.4 + f * 1.9
					VFX.bolt(a0, b0, col, 0.18, 0.18, 2)
					Combat.hit_zone(who, who.global_position, f, 2.4, 55.0, 2.2, _kinfo(dmg, 0.9, {"element": "raiton", "knock": 4.0, "kind": "light", "melee": true, "stun": 0.25}))
				2:   # yanından şimşekli dürtüş: sersemletir
					Combat.hit_sphere(who, at + f * 0.3, 1.1, _kinfo(dmg, 1.15, {"element": "raiton", "knock": 7.0, "kind": "heavy", "melee": true, "stun": 0.6}))
					VFX.bolt(at, at + f * 1.4, col, 0.2, 0.2, 2)
				3:   # Kuroi Jūji: çapraz düz şimşek çizgileri (ref kurosuki_1) — öne 6 m
					for sx2 in [-1.0, 1.0]:
						var p0 = who.global_position + Vector3.UP * 1.3 + side * sx2 * 1.2
						var p1 = who.global_position + Vector3.UP * 1.1 - side * sx2 * 1.4 + f * 6.0
						VFX.bolt(p0, p1, col, 0.22, 0.25, 1)
					Combat.hit_zone(who, who.global_position, f, 6.0, 22.0, 2.4, _kinfo(dmg, 1.1, {"element": "raiton", "knock": 6.0, "kind": "heavy", "stun": 0.4}))
				4:   # Rakurai: hedefe gök şimşeği
					var p = tg.global_position if tg else who.global_position + f * 7.0
					VFX.bolt(p + Vector3.UP * 22.0, p, col, 0.45, 0.3, 4)
					VFX.cracks(Vector3(p.x, Game.ground_height(p.x, p.z) + 0.05, p.z), 1.6)
					Combat.hit_sphere(who, p + Vector3.UP, 1.6, _kinfo(dmg, 1.3, {"element": "raiton", "knock": 3.0, "kind": "heavy", "stun": 0.8}))
					Sfx.play("zap", p, 1.0, 0.7)
				5:   # Ikazuchi no Utage: hedefin çevresine şimşek yağmuru + büyük şimşek
					var c = tg.global_position if tg else who.global_position + f * 6.0
					for k in 6:
						var q = c + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
						who.get_tree().create_timer(k * 0.07).timeout.connect(func():
							if is_instance_valid(who):
								VFX.bolt(q + Vector3.UP * 20.0, q, col, 0.3, 0.22, 3)
								Combat.hit_sphere(who, q + Vector3.UP, 1.5, _kinfo(dmg, 0.35, {"element": "raiton", "knock": 2.0, "kind": "light", "stun": 0.3})))
					who.get_tree().create_timer(0.5).timeout.connect(func():
						if is_instance_valid(who):
							VFX.bolt(c + Vector3.UP * 24.0, c, Color(0.95, 0.97, 1.0), 0.7, 0.4, 5)
							VFX.shockwave(c + Vector3.UP * 0.1, col, 6.0, 0.35, true)
							Combat.hit_sphere(who, c + Vector3.UP, 2.6, _kinfo(dmg, 1.2, {"element": "raiton", "knock": 8.0, "launch": 4.0, "kind": "heavy", "stun": 0.6}))
							_shake(who, 0.5)
							Sfx.play("zap", c, 0.8, 0.9))
		"style_iburi":
			var tg = _near_foe(who, 10.0)
			var hand = who.global_position + Vector3.UP * 1.35 + f * 0.5
			match i:
				0, 1:   # Kemuri Ken: kol dumana çözülüp uzanır, ucunda katı yumruk
					var to = tg.global_position + Vector3.UP * 1.1 if tg and tg.global_position.distance_to(who.global_position) < 6.0 else hand + f * 4.5
					_smoke_line(hand + side * (0.25 if i == 0 else -0.25), to, 0.22)
					Combat.hit_sphere(who, to, 0.9, _kinfo(dmg, 0.9, {"element": "", "knock": 4.0, "kind": "light", "melee": true}))
					FX.hit_spark(to, Color(0.85, 0.88, 0.95), 0.7)
				2:   # Utsuri ters eli: arkasında belirdiği rakibe
					Combat.hit_sphere(who, at + f * 0.2, 1.1, _kinfo(dmg, 1.2, {"element": "", "knock": 9.0, "kind": "heavy", "melee": true}))
				3:   # Kemuri Iaigiri: dumandan bıçakla geniş yatay kesik
					for k in 9:
						var a = lerpf(1.1, -1.1, k / 8.0)
						var q = who.global_position + Vector3.UP * 1.15 + (f * cos(a) - side * sin(a)) * 2.6
						who.get_tree().create_timer(k * 0.012).timeout.connect(func(): _smoke_puff_at(q, 0.28, 3, f))
					Combat.hit_zone(who, who.global_position, f, 4.2, 70.0, 2.4, _kinfo(dmg, 1.1, {"element": "", "knock": 6.0, "kind": "heavy", "bleed": 2.0, "melee": true}))
				4:   # Ibushimi Iki: oksitleyici kızıl-gri duman yüze, içeriden yakar + yavaşlatır
					var mouth = who.global_position + Vector3.UP * 1.6 + f * 0.3
					var to2 = tg.global_position + Vector3.UP * 1.6 if tg and tg.global_position.distance_to(who.global_position) < 7.0 else mouth + f * 5.0
					_smoke_line(mouth, to2, 0.3, Color(0.72, 0.55, 0.55, 0.85))
					Combat.hit_sphere(who, to2, 1.2, _kinfo(dmg, 0.6, {"element": "katon", "knock": 0.0, "kind": "light", "burn": 3.0, "slow": 2.0}))
				5:   # Kemuri Tatsumaki: çevrede yükselen duman hortumu, yakındakileri kaldırır
					for k in 14:
						var a2 = k * 0.75
						var kk = k
						who.get_tree().create_timer(k * 0.035).timeout.connect(func():
							if is_instance_valid(who):
								_smoke_puff_at(who.global_position + Vector3(cos(a2), 0, sin(a2)) * 2.2 + Vector3.UP * (0.2 + kk * 0.22), 0.5, 5, Vector3.UP))
					Combat.hit_sphere(who, who.global_position + Vector3.UP, 4.4, _kinfo(dmg, 1.3, {"element": "", "knock": 4.0, "launch": 8.0, "kind": "heavy"}))
		"style_kamizuru":
			var tg = _near_foe(who, 16.0)
			var hand = who.global_position + Vector3.UP * 1.3 + f * 0.6
			match i:
				0, 1:   # Hachi Senbon: yenden üç arı çıkar, hedefe dalarken iğne fırlatır
					for k in 3:
						_bee_dart(who, hand + side * ((0.3 if i == 1 else -0.3) + (k - 1) * 0.15) + Vector3.UP * (k % 2) * 0.2, tg, dmg * 0.4, k * 0.05, false)
				2:   # Hachi Mitsu: bal dolu arılar hedefte patlar, bal yapıştırır
					for k in 2:
						_bee_dart(who, hand + side * (k - 0.5) * 0.5, tg, dmg * 0.7, k * 0.08, true)
				3:   # mühür: hedefin altından arı sütunu yükselir, havaya kaldırır
					if tg:
						var p = tg.global_position
						for k in 4:
							who.get_tree().create_timer(0.08 + k * 0.08).timeout.connect(func():
								if is_instance_valid(who):
									_bee_rise(p + Vector3(randf_range(-0.6, 0.6), 0.0, randf_range(-0.6, 0.6)), 2.6))
						Combat.hit_sphere(who, p + Vector3.UP, 1.6, _kinfo(dmg, 1.0, {"element": "", "knock": 2.0, "launch": 6.0, "kind": "heavy", "slow": 1.0}))
				4:   # Hachi Bakudan: patlayıcı kâğıt taşıyan arılar kavisle dalıp patlar
					for k in 3:
						_bee_bomb(who, hand + Vector3.UP * 0.4 + side * (k - 1) * 0.35, tg, dmg * 0.7, k * 0.1)
				5:   # Senbon Fubuki: sürü yelpaze gibi açılıp hedefte birleşir; zehir uyutur
					for k in 10:
						var a = lerpf(-1.1, 1.1, k / 9.0)
						_bee_dart(who, who.global_position + Vector3.UP * (1.2 + (k % 3) * 0.3) + side * sin(a) * 1.6 + f * 0.3, tg, dmg * 0.22, 0.04 * k, false, k == 9)
		"style_jugo":
			if i == 3:   # iki balyoz kol yere: şok
				var g = who.global_position + f * 1.7
				g.y = Game.ground_height(g.x, g.z) + 0.05
				VFX.shockwave(g + Vector3.UP * 0.1, Color(0.7, 0.62, 0.52), 6.5, 0.35, true)
				VFX.cracks(g, 4.0)
				Combat.hit_sphere(who, g + Vector3.UP * 0.5, 2.6, _kinfo(dmg, 0.6, {"element": "", "knock": 6.0, "launch": 5.0, "kind": "heavy", "melee": true}))
				_shake(who, 0.5)
			elif i == 2 or i == 5:
				_shake(who, 0.35)
				VFX.shockwave(at + f * 0.4, Color(1.0, 0.95, 0.85), 2.4, 0.2, false, f)
				FX.hit_spark(at + f * 0.5, Color(1.0, 0.85, 0.55), 1.4)
			elif i == 4:   # Hari-ude: dikenli kol saplanır
				FX.hit_spark(at + f * 0.9, Color(0.95, 0.9, 0.8), 1.0)
		"style_yuki":
			var tg = _near_foe(who, 14.0)
			var hand = who.global_position + Vector3.UP * 1.35 + f * 0.5
			match i:
				0, 1:
					for k in 3:
						_ice_needle(who, hand + side * (k - 1) * 0.12, tg, dmg * 0.4, (k - 1) * 0.06)
				3:   # Tsubame Fubuki: takip eden buz kırlangıçları
					for k in 5:
						who.get_tree().create_timer(k * 0.05).timeout.connect(func():
							if is_instance_valid(who):
								_ice_swallow(who, hand + side * (k - 2) * 0.3 + Vector3.UP * 0.2, tg, dmg * 0.45))
				4:   # dönerken çevreye iğne
					for k in 8:
						var dd = f.rotated(Vector3.UP, k * TAU / 8.0)
						_ice_needle(who, who.global_position + Vector3.UP * 1.2 + dd * 0.5, null, dmg * 0.3, 0.0, dd)
				5:   # Sensatsu Suishō: rakibin çevresinde iğneler belirir, içe saplanır
					if tg:
						_sensatsu(who, tg, dmg)
		"style_sabaku":
			var tg = _near_foe(who, 16.0)
			match i:
				0:   # Suna no Te: yerden kum yumruğu
					if tg:
						_sand_burst(tg.global_position, 1.0)
						Combat.hit_sphere(who, tg.global_position + Vector3.UP, 1.6, _kinfo(dmg, 1.0, {"element": "doton", "knock": 7.0, "launch": 4.0, "kind": "heavy"}))
				1:   # Suna Shuriken
					for k in 3:
						_sand_ball(who, who.global_position + Vector3.UP * 1.3 + f * 0.8 + side * (k - 1) * 0.4, tg, dmg * 0.45, 0.22, (k - 1) * 0.08)
				2:   # Suna Tsunami: ileri kum dalgası
					for d in [2.0, 4.0, 6.0, 8.0]:
						var p = who.global_position + f * d
						p.y = Game.ground_height(p.x, p.z)
						who.get_tree().create_timer(d * 0.04).timeout.connect(func():
							if is_instance_valid(who):
								_sand_burst(p, 0.8)
								Combat.hit_sphere(who, p + Vector3.UP * 0.6, 1.8, _kinfo(dmg, 0.35, {"element": "doton", "knock": 6.0, "kind": "light"})))
				3:   # Sabaku Kyū: kum sarar, bağlar
					if tg:
						_sand_coffin(tg, 1.4)
						if tg.has_method("apply_status"):
							tg.apply_status("bind", 1.3)
						Combat.hit_sphere(who, tg.global_position + Vector3.UP, 1.2, _kinfo(dmg, 0.5, {"element": "doton", "knock": 0.0, "kind": "light"}))
				4:   # kum yağmuru
					if tg:
						var p4 = tg.global_position
						for k in 6:
							who.get_tree().create_timer(k * 0.07).timeout.connect(func():
								if is_instance_valid(who):
									_sand_burst(p4 + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2)), 0.5))
						Combat.hit_sphere(who, p4 + Vector3.UP, 2.0, _kinfo(dmg, 0.9, {"element": "doton", "knock": 3.0, "kind": "heavy"}))
				5:   # Sabaku Sōsō: sarılı kum sıkıştırır
					if tg:
						var stc = SandCoat.apply(tg, 0.82, 0.22)   # Sabaku Kyū kaplaması tırmanır...
						who.get_tree().create_timer(0.3).timeout.connect(func():
							if is_instance_valid(tg) and not stc.is_empty():
								SandCoat.squeeze(stc, 0.35))   # ...ve avuç kapanınca çöker (Sōsō)
						who.get_tree().create_timer(0.62).timeout.connect(func():
							if is_instance_valid(tg):
								if not stc.is_empty():
									SandCoat.remove(stc, 0.3)
								VFX.puffs(tg.global_position + Vector3.UP, {"amount": 30, "life": 0.8, "size": 0.9, "radius": 0.8, "vmin": 2, "vmax": 6, "gravity": Vector3(0, -6, 0),
									"colors": [Color(0.95, 0.82, 0.58, 0.95), Color(0.8, 0.65, 0.4, 0)]})
								Combat.hit_sphere(who, tg.global_position + Vector3.UP, 1.6, _kinfo(dmg, 1.6, {"element": "doton", "knock": 4.0, "kind": "heavy", "bleed": 2.0})))
						_shake(who, 0.35)
		"style_uzumaki":
			var tg = _near_foe(who, 10.0)
			var chest = who.global_position + Vector3.UP * 1.2
			var end = (tg.global_position + Vector3.UP) if tg else chest + f * 5.0
			match i:
				0, 1:
					_chakra_chain(chest - f * 0.2 + Vector3.UP * 0.4, end, 0.35)
					Combat.hit_sphere(who, end, 1.3, _kinfo(dmg, 0.9, {"element": "", "knock": 6.0, "kind": "light"}))
				2:   # zincir mızrak: uzun
					var e2 = (tg.global_position + Vector3.UP) if tg and tg.global_position.distance_to(who.global_position) < 9.0 else chest + f * 8.0
					_chakra_chain(chest, e2, 0.4)
					Combat.hit_sphere(who, e2, 1.3, _kinfo(dmg, 1.3, {"element": "", "knock": 9.0, "kind": "heavy", "bleed": 1.5}))
				3:   # Kongō Shibari: sarar, bağlar, chakrasını mühürler
					if tg:
						for k in 3:
							_chakra_chain(chest + side * (k - 1) * 0.3, tg.global_position + Vector3.UP * (0.6 + k * 0.4), 1.3)
						if tg.has_method("apply_status"):
							tg.apply_status("bind", 1.5)
						_kikai_drain(who, tg, 0.1)
						Combat.popup_text(tg.global_position + Vector3.UP * 2.4, "Chakra mühürlendi!", Color(1.0, 0.85, 0.4))
				4:   # Rensa Senpū: dört zincir çevreyi süpürür
					for k in 4:
						var dd = f.rotated(Vector3.UP, k * TAU / 4.0)
						_chakra_chain(chest, chest + dd * 3.2, 0.3)
				5:   # Fūsa Otoshi: zincirle kaldırıp yere çarpar
					if tg:
						_chakra_chain(chest, tg.global_position + Vector3.UP, 0.8)
						if tg is CharacterBody3D:
							tg.velocity = Vector3(0, 9.0, 0)
						var tgr = tg
						who.get_tree().create_timer(0.3).timeout.connect(func():
							if is_instance_valid(tgr) and is_instance_valid(who):
								if tgr is CharacterBody3D:
									tgr.velocity = Vector3(0, -18.0, 0)
								var g = tgr.global_position
								g.y = Game.ground_height(g.x, g.z)
								VFX.cracks(g, 3.0)
								Combat.hit_sphere(who, g + Vector3.UP * 0.6, 1.8, _kinfo(dmg, 1.4, {"element": "", "knock": 8.0, "kind": "heavy"})))
		"style_yotsuki":
			VFX.bolt(at, at + f * 1.2 + Vector3(randf_range(-0.4, 0.4), randf_range(-0.3, 0.3), 0), Color(0.75, 0.88, 1.0), 0.18, 0.2, 2)
			if i == 5:   # Liger Bomb: yer çatlar, şimşek patlar
				var g5 = who.global_position + f * 1.3
				g5.y = Game.ground_height(g5.x, g5.z) + 0.05
				VFX.cracks(g5, 4.0)
				VFX.shockwave(g5 + Vector3.UP * 0.1, Color(0.75, 0.88, 1.0), 6.0, 0.35, true)
				for k in 4:
					VFX.bolt(g5 + Vector3.UP * 0.2, g5 + Vector3(randf_range(-2, 2), 0.2, randf_range(-2, 2)), Color(0.7, 0.85, 1.0), 0.25, 0.3, 2)
				Combat.hit_sphere(who, g5 + Vector3.UP * 0.6, 2.2, _kinfo(dmg, 0.8, {"element": "raiton", "stun": 0.6, "knock": 6.0, "kind": "heavy", "melee": true}))
				_shake(who, 0.5)
		"style_kaguya":
			if i == 4:   # Teshi Sendan: sol parmak uçlarından üç kemik mermisi
				var pj = PathJutsu.get_pinst()
				var tg = _near_foe(who, 20.0)
				for k in 3:
					var b = MB.new()
					b.add("cone", Vector3(0, 0, 0.08), Vector3(0.05, 0.18, 0.05), Color(0.95, 0.94, 0.88), Vector3(90, 0, 0), 5)
					var mi = MeshInstance3D.new()
					mi.mesh = b.build(Props.toon())
					var dir = (f + side * (k - 1) * 0.06).normalized()
					if tg:
						dir = ((tg.global_position + Vector3.UP) - (who.global_position + Vector3.UP * 1.3)).normalized()
					if pj:
						pj.shot(who, who.global_position + Vector3.UP * 1.3 + f * 0.6 + side * (k - 1) * 0.08, dir, 42.0, mi, _kinfo(dmg, 0.55, {"element": "", "knock": 2.0, "kind": "light", "bleed": 1.0}), tg, false, 0.8)
			elif i == 5:   # Karamatsu: bedenden fışkıran dikenler — çevreye alan hasarı
				_bone_spikes(who, ["Hips", "Spine", "UpperChest", "RightUpperArm", "LeftUpperArm", "RightUpperLeg", "LeftUpperLeg"], 0.6)
				Combat.hit_sphere(who, who.global_position + Vector3.UP * 1.0, 2.6, _kinfo(dmg, 0.9, {"element": "", "knock": 14.0, "launch": 6.0, "kind": "heavy", "bleed": 2.0, "melee": true}))


## Hōzuki Mizudeppō: parmak ucundan fırlayan su mermisi (hedefe yönelir)
static func _water_bullet(who: Node3D, from: Vector3, tg: Node3D, dmg: float, size: float) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	var dir = ((tg.global_position + Vector3.UP * 1.1) - from).normalized() if tg else f
	# ref hozuki_1: yuvarlak baş önde (-Z), arkaya incelen kuyruk; camsı Storm suyu (WaterArt)
	var b = MB.new()
	var s = size * (0.55 if size < 0.4 else 0.9)
	Loft.tube(b, [Vector3(0, 0, -s * 1.0), Vector3(0, 0, -s * 0.75), Vector3(0, 0, -s * 0.2), Vector3(0, 0, s * 0.8), Vector3(0, 0, s * 2.2)],
		[Vector2(0.02, 0.02), Vector2(s * 0.62, s * 0.62), Vector2(s * 0.7, s * 0.7), Vector2(s * 0.35, s * 0.35), Vector2(0.01, 0.01)], Color.WHITE, 12, 4, true, true)
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(null)
	mi.material_override = WaterArt.mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	WaterArt.spray(from, 0.35 if size < 0.4 else 0.8, dir, 20.0, 1.2)
	var big = size >= 0.4
	pj.shot(who, from, dir, 34.0 if not big else 24.0, mi, _kinfo(dmg, 1.0, {"element": "suiton", "knock": 4.0 if not big else 12.0, "kind": "heavy" if big else "light"}), tg, false, 0.9, func(p, _h):
		WaterArt.splash(p, 0.5 if not big else 1.1))
	Sfx.play("water", from, 1.4, 0.5)


## Hōzuki Mizu Muchi: elden hedefe uzanan dalgalı su kırbacı; ucunda isabet
static var _water_mat: StandardMaterial3D
static func _water_whip(who: Node3D, tg: Node3D, dmg: float, twin: bool) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	if _water_mat == null:
		_water_mat = StandardMaterial3D.new()
		_water_mat.albedo_color = Color(0.6, 0.85, 1.0, 0.85)
		_water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_water_mat.emission_enabled = true
		_water_mat.emission = Color(0.3, 0.5, 0.7)
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	var end = (tg.global_position + Vector3.UP * 1.0) if tg and tg.global_position.distance_to(who.global_position) < 7.5 else who.global_position + Vector3.UP * 1.0 + f * 6.0
	for k in (2 if twin else 1):
		var sd = (-1.0 if k == 0 else 1.0)
		var hand = who.global_position + Vector3.UP * 1.3 + f * 0.5 + Vector3.UP.cross(f) * sd * 0.25
		_whip_arc(who, hand, end, sd)
	WaterArt.splash(end - Vector3.UP * 0.6, 0.6)
	Combat.hit_sphere(who, end, 1.4, _kinfo(dmg, 1.0, {"element": "suiton", "knock": 7.0, "kind": "heavy"}))
	FX.hit_spark(end, Color(0.7, 0.9, 1.0), 1.0)
	Sfx.play("water", end, 1.2, 0.6)


## Su kırbacı yayı (ref hozuki_3: elden çıkan, geniş kavis çizip ucu ileri savrulan ince camsı su şeridi). Yerel +Z: hedefe.
## Kırbaç uzar (ölçek), yayı savrulur (Z ekseninde döner), sonra incelip söner.
static func _whip_arc(who: Node3D, a: Vector3, b2: Vector3, sd: float) -> void:
	var d = b2 - a
	var L = d.length()
	if L < 0.3:
		return
	var mb = MB.new()
	var pts = []
	var rad = []
	for k in 17:
		var u = k / 16.0
		pts.append(Vector3(sin(u * PI) * L * 0.28 * sd + sin(u * TAU) * L * 0.05, sin(u * PI) * L * 0.12, u * L))
		var w = lerpf(0.1, 0.03, u) * (1.0 + sin(u * PI) * 0.4)
		rad.append(Vector2(w, w))
	Loft.tube(mb, pts, rad, Color.WHITE, 10, 2, true, true)
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(null)
	mi.material_override = WaterArt.mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	who.get_tree().current_scene.add_child(mi)
	mi.global_position = a
	mi.look_at(b2, Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.RIGHT)
	mi.rotate_object_local(Vector3.UP, PI)   # +Z hedefe
	var r0 = mi.rotation
	mi.scale = Vector3(1, 1, 0.1)
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, 0.1).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(func(x: float): if is_instance_valid(mi): mi.rotation = r0; mi.rotate_object_local(Vector3.BACK, x * sd), -0.6, 0.4, 0.4)
	tw.tween_property(mi, "scale", Vector3(0.2, 0.2, 1.05), 0.14)
	tw.tween_callback(mi.queue_free)
	WaterArt.spray(a, 0.3, d.normalized(), 25.0, 0.8)


## Aburame: böcek sürüsü — titreşen kara benek bulutu, hedefe süzülür; isabette chakra emer
static func _swarm_mesh(r: float) -> MeshInstance3D:
	var b = MB.new()
	for k in int(60 + r * 60):   # dolgun sürü: içi yoğun, kenarı seyrek; tek tek kanatlı benekler
		var p = Vector3(randf_range(-1, 1), randf_range(-0.7, 0.7), randf_range(-1, 1)).normalized() * r * pow(randf(), 0.7)
		b.add("sphere", p, Vector3(randf_range(0.05, 0.08), randf_range(0.03, 0.05), randf_range(0.05, 0.08)), Color(0.05, 0.05, 0.04).lightened(randf() * 0.12), Vector3.ZERO, 4)
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	return mi


static func _swarm(who: Node3D, tg: Node3D, dmg: float, r: float, off: Vector3, speed := 20.0) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	var from = who.global_position + Vector3.UP * 1.2 + f * 0.6 + off
	var dir = ((tg.global_position + Vector3.UP * 1.1) - from).normalized() if tg else f
	var mi = _swarm_mesh(r * 0.55)   # çekirdek: yoğun kara böcekler; asıl sürü arkasından akan kikaichū parçacıkları
	var pr = pj.shot(who, from, dir, speed, mi, _kinfo(dmg, 1.0, {"element": "", "knock": 1.0, "kind": "light", "kikai": true}), tg, false, 1.4, func(_p, h):
		if h and is_instance_valid(h):
			_kikai_drain(who, h, 0.03)
			var cj = ClanJutsu.get_inst()
			if cj:
				cj.swarm_body(h, 1.6, 0.45, 0.02))   # Kikaichū no Jutsu'nun yapışma görünüşü: bedende sürünen benekler
	if pr:
		mi.create_tween().set_loops().tween_property(mi, "rotation", Vector3(TAU, TAU * 0.7, TAU * 0.4), 0.6).as_relative()
		Projectile.trail(pr, [Color(0.0, 0.0, 0.0), Color(0.03, 0.03, 0.02), Color(0.0, 0.0, 0.0, 0)], 0.09 + r * 0.06, int(90 + r * 120), 0.45, null, false)
	Sfx.play("whoosh", from, 0.6, 0.4)


static func _swarm_cloud(p: Vector3, r: float, life: float) -> void:
	var mi = _swarm_mesh(r * 0.6)
	var sc = Engine.get_main_loop().current_scene
	sc.add_child(mi)
	mi.global_position = p
	Projectile.trail(mi, [Color(0.0, 0.0, 0.0), Color(0.03, 0.03, 0.02), Color(0.0, 0.0, 0.0, 0)], 0.12, int(80 + r * 80), 0.5, null, false)
	var tw = mi.create_tween()
	tw.tween_property(mi, "rotation", Vector3(0, TAU, 0), life)
	tw.parallel().tween_property(mi, "scale", Vector3.ONE * 1.3, life)
	tw.tween_callback(mi.queue_free)


## Kikaichū: isabet eden böcekler rakibin chakrasını emer (sahibine bir kısmı döner) — oyuncu/düşman aynı
static func _kikai_drain(who: Node3D, h: Node3D, k: float) -> void:
	if h == null or not is_instance_valid(h) or h.get("chakra") == null:
		return
	var mx = float(h.get("max_chakra")) if h.get("max_chakra") != null else 100.0
	var amt = mx * k
	h.chakra = maxf(0.0, float(h.chakra) - amt)
	if is_instance_valid(who) and who.get("chakra") != null and who.get("max_chakra") != null:
		who.chakra = minf(float(who.max_chakra), float(who.chakra) + amt * 0.5)


## Yuki: buz iğnesi — IceArt kristal malzemesiyle ince sivri senbon (ucu -Z: mermi yönü)
static func _ice_mesh(L: float, w: float) -> MeshInstance3D:
	var b = MB.new()
	IceArt.shard(b, Vector3(0, 0, L * 0.5), Vector3.FORWARD, L, w, IceArt._rng(), Color.WHITE, 5, true)
	return IceArt._mi(b)


static func _ice_needle(who: Node3D, from: Vector3, tg: Node3D, dmg: float, yaw_off := 0.0, dir_in := Vector3.ZERO) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	var dir = dir_in if dir_in != Vector3.ZERO else (((tg.global_position + Vector3.UP * 1.1) - from).normalized() if tg else f)
	dir = dir.rotated(Vector3.UP, yaw_off)
	var pr = pj.shot(who, from, dir, 40.0, _ice_mesh(0.42, 0.035), _kinfo(dmg, 1.0, {"element": "hyoton", "knock": 1.0, "kind": "light", "bleed": 1.0, "slow": 0.6}), tg if dir_in == Vector3.ZERO else null, false, 0.7)
	if pr:
		VFX.trail(pr, 0.03, Color(0.9, 0.97, 1.0, 0.8), Color(0.75, 0.9, 1.0, 0.35), Color(0.7, 0.9, 1.0, 0), 8, 0.0)


## Tsubame Fubuki: IceArt.swallow (Hyōton jutsusunun kendi buz kırlangıcı), kavisle hedefe
static func _ice_swallow(who: Node3D, from: Vector3, tg: Node3D, dmg: float) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	var dir = (((tg.global_position + Vector3.UP) - from).normalized() if tg else f) + Vector3.UP * 0.35
	var pr = pj.shot(who, from, dir.normalized(), 18.0, IceArt.swallow(0.55), _kinfo(dmg, 1.0, {"element": "hyoton", "knock": 2.0, "kind": "light", "slow": 1.0}), tg, false, 1.6, func(p, _h):
		IceArt.shatter(Engine.get_main_loop(), p, 0.35, 5))
	if pr:
		pr.homing_turn = 5.0
		VFX.trail(pr, 0.06, Color(0.9, 0.97, 1.0, 0.7), Color(0.7, 0.9, 1.0, 0.3), Color(0.7, 0.9, 1.0, 0), 12, 0.0)


## Sensatsu Suishō (ref yuki_*): rakibin çevresinde iğneler belirir, kısa bekleyip içe saplanır; isabette kırılır
static func _sensatsu(who: Node3D, tg: Node3D, dmg: float) -> void:
	var c = tg.global_position + Vector3.UP * 1.0
	var sc = who.get_tree().current_scene
	var needles = []
	for k in 20:
		var a = k * TAU / 20.0
		var y = float(k % 4) * 0.35 - 0.5
		var p = c + Vector3(cos(a) * 2.0, y, sin(a) * 2.0)
		var n = _ice_mesh(0.55, 0.04)
		sc.add_child(n)
		n.global_position = p
		n.look_at(c, Vector3.UP)   # mesh ucu -Z: içe bakar
		n.scale = Vector3.ONE * 0.05
		n.create_tween().tween_property(n, "scale", Vector3.ONE, 0.15)
		needles.append(n)
	who.get_tree().create_timer(0.35).timeout.connect(func():
		for n in needles:
			if is_instance_valid(n):
				var tw = n.create_tween()
				tw.tween_property(n, "global_position", c, 0.12)
				tw.tween_callback(n.queue_free)
		if is_instance_valid(who):
			who.get_tree().create_timer(0.12).timeout.connect(func():
				IceArt.shatter(Engine.get_main_loop(), c, 0.6, 12)
				if is_instance_valid(who):
					Combat.hit_sphere(who, c, 1.4, _kinfo(dmg, 1.7, {"element": "hyoton", "knock": 3.0, "kind": "heavy", "bleed": 3.0, "slow": 2.0}))))


## Sabaku: Suna Shuriken jutsusunun mekik kum bıçağı + kum izi
static func _sand_mesh(r: float) -> MeshInstance3D:
	var sand = Color(0.88, 0.74, 0.5)
	var sand_d = Color(0.7, 0.56, 0.36)
	var bm = MB.new()
	var L = r * 1.6
	Loft.tube(bm, [Vector3(0, 0, L), Vector3(0, 0, L * 0.35), Vector3(0, 0, -L * 0.35), Vector3(0, 0, -L)],
		[Vector2(0.01, 0.01), Vector2(r * 0.6, r * 0.24), Vector2(r * 0.6, r * 0.24), Vector2(0.01, 0.01)], [sand_d, sand, sand.lightened(0.12), sand_d], 8, 4, true, true)
	var mi = MeshInstance3D.new()
	mi.mesh = bm.build(Props.toon())
	return mi


static func _sand_ball(who: Node3D, from: Vector3, tg: Node3D, dmg: float, r: float, yaw_off := 0.0) -> void:
	var pj = PathJutsu.get_pinst()
	if pj == null:
		return
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	var dir = (((tg.global_position + Vector3.UP) - from).normalized() if tg else f).rotated(Vector3.UP, yaw_off)
	var pr = pj.shot(who, from, dir, 36.0, _sand_mesh(r), _kinfo(dmg, 1.0, {"element": "doton", "knock": 3.0, "kind": "light", "slow": 1.0}), tg, false, 1.0, func(p, _h):
		VFX.puffs(p, {"amount": 12, "life": 0.5, "size": 0.5, "radius": 0.3, "vmin": 2, "vmax": 4, "colors": [Color(0.95, 0.82, 0.58, 0.9), Color(0.8, 0.65, 0.4, 0)]}))
	if pr:
		pr.spin = Vector3(0, 0, 30.0)
		Projectile.trail(pr, [Color(0.95, 0.82, 0.58, 0.85), Color(0.8, 0.65, 0.4, 0)], 0.25, 22, 0.35, FX.tex_smoke, false)


## Suna no Te / Tsunami: yerden fışkıran organik kum kütlesi (Sabaku Sōsō dalgasının kendi topak-şerit kütlesi), sonra çöker
static func _sand_burst(p: Vector3, s: float) -> void:
	var m = JutsuEngine.organic_mass("sand", Vector3(1.6, 2.2, 1.6) * s)
	var sc = Engine.get_main_loop().current_scene
	sc.add_child(m)
	m.global_position = p - Vector3.UP * 1.6 * s
	var tw = m.create_tween()
	tw.tween_property(m, "global_position", p - Vector3.UP * 0.2 * s, 0.14).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.25)
	tw.tween_property(m, "global_position", p - Vector3.UP * 2.0 * s, 0.35).set_ease(Tween.EASE_IN)
	tw.tween_callback(m.queue_free)
	VFX.puffs(p + Vector3.UP * 0.3, {"amount": int(10 * s) + 4, "life": 0.7, "size": 0.7 * s, "radius": 0.6 * s, "vmin": 1, "vmax": 4, "dir": Vector3.UP, "spread": 50.0, "gravity": Vector3(0, -6, 0),
		"colors": [Color(0.95, 0.82, 0.58, 0.9), Color(0.8, 0.65, 0.4, 0)]})


## Sabaku Kyū: Gaara jutsusunun kendi kum kaplaması (SandCoat) — ayaktan boyna tırmanır, süre bitince dökülür
static func _sand_coffin(tg: Node3D, life: float) -> void:
	var st = SandCoat.apply(tg, 0.82, 0.3)
	if st.is_empty():
		return
	tg.get_tree().create_timer(life).timeout.connect(func():
		if is_instance_valid(tg):
			SandCoat.remove(st, 0.4))


## Uzumaki: Kongō Fūsa — Kinbaku/Chakra zincirleri jutsusunun kendi halkalı zinciri (Jutsu._chain_line), gövdeden hedefe
static func _chakra_chain(a: Vector3, b2: Vector3, life: float) -> void:
	if a.distance_to(b2) < 0.2:
		return
	var root = Node3D.new()
	Engine.get_main_loop().current_scene.add_child(root)
	Jutsu._chain_line(root, a, b2, 0.12, 0.12, Jutsu._chain_mat(), false)
	root.get_tree().create_timer(life + 0.15).timeout.connect(func():
		if is_instance_valid(root):
			root.queue_free())


## Yotsuki: Raiton Chakra zırhı — Raiton no Yoroi jutsusunun kendi aurası + bedeni saran şimşek arkları (kombo boyunca)
static func _rai_armor(who: Node3D) -> void:
	if who.has_meta("rai_armor") and is_instance_valid(who.get_meta("rai_armor")):
		return
	var root = Node3D.new()
	who.add_child(root)
	var a = FX.aura(who, Color(0.6, 0.85, 1.0), 1.3, Vector3(0, 0.9, 0), 0.0)
	if a:
		a.reparent(root)
	var arcs = Arcs.new()
	arcs.color = Color(0.6, 0.85, 1.0)
	arcs.radius = 1.0
	root.add_child(arcs)
	arcs.position = Vector3(0, 1, 0)
	who.set_meta("rai_armor", root)


# ------------------------------------------------------------------ Kamizuru arıları (ref refs/styles/kamizuru_*.png)
## Arı modeli: dev arı çağrısının (ClanConstruct "bee") aynısı, küçük (ClanJutsu._kz_bee)
static func _bee_node(sc: float) -> Node3D:
	var cj = ClanJutsu.get_inst()
	if cj:
		return cj._kz_bee(sc)
	return Node3D.new()


static var _sting_mat: StandardMaterial3D
## Arı iğnesi: ref 0'daki ince açık mor-beyaz çizgi
static func _sting_mesh() -> MeshInstance3D:
	if _sting_mat == null:
		_sting_mat = StandardMaterial3D.new()
		_sting_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_sting_mat.albedo_color = Color(0.86, 0.8, 1.0)
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.02, 0.02, 0.55)
	mi.mesh = bm
	mi.material_override = _sting_mat
	return mi


## Arı dalışı: arı yenden çıkıp hedefe uçar, yarı yolda iğnesini fırlatır (ref 0). honey: bal arısı — isabette bala patlar,
## hedefi kısa yapıştırır (ref 2-3). sleep: zehir uyutur (kanon: Kamizuru sokması kurbanı saniyeler içinde uyutur)
static func _bee_dart(who: Node3D, from: Vector3, tg: Node3D, dmg: float, delay: float, honey: bool, sleep := false) -> void:
	who.get_tree().create_timer(maxf(0.001, delay)).timeout.connect(func():
		if not is_instance_valid(who):
			return
		var pj = PathJutsu.get_pinst()
		if pj == null:
			return
		var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
		var to = (tg.global_position + Vector3.UP * 1.1) if tg and is_instance_valid(tg) else from + f * 12.0
		var dir = (to - from).normalized()
		var bee = _bee_node(0.4 if honey else 0.32)
		var extra = {"element": "", "knock": 1.0, "kind": "light", "slow": 1.2}
		pj.shot(who, from, dir, 18.0, bee, _kinfo(dmg * (1.0 if honey else 0.5), 1.0, extra), tg, false, 1.3, func(p, h):
			if honey:
				_honey_burst(p, 0.8)
				if h and is_instance_valid(h) and h.has_method("apply_status"):
					h.apply_status("bind", 0.9)
			else:
				VFX.puffs(p, {"amount": 6, "life": 0.4, "size": 0.08, "radius": 0.2, "vmin": 1.0, "vmax": 3.0, "spread": 180.0, "add": false,
					"colors": [Color(1.0, 0.6, 0.1, 1.0), Color(0.1, 0.06, 0.02, 0)]}))
		if honey:
			return
		# yarı yolda iğne: arıdan ayrılan hızlı ince iğne (asıl zehir)
		who.get_tree().create_timer(0.18).timeout.connect(func():
			if not is_instance_valid(who) or not is_instance_valid(bee):
				return
			var sp = bee.global_position
			var to2 = (tg.global_position + Vector3.UP * 1.1) if tg and is_instance_valid(tg) else sp + dir * 10.0
			pj.shot(who, sp, (to2 - sp).normalized(), 46.0, _sting_mesh(), _kinfo(dmg * 0.5, 1.0, {"element": "", "knock": 0.3, "kind": "light", "slow": 1.5}), tg, false, 0.6, func(_p2, h2):
				if sleep and h2 and is_instance_valid(h2) and h2.has_method("apply_status"):
					h2.apply_status("stun", 1.6)
					Combat.popup_text(h2.global_position + Vector3.UP * 2.3, "Zehir: uyudu!", Color(0.85, 0.7, 1.0)))))


## Bal patlaması: iri turuncu yapışkan bal öbekleri (lava_mat "honey" — yapışkan sıvı sistemi), yere yapışır
static func _honey_burst(p: Vector3, s: float) -> void:
	VFX.goo_drops(p, "honey", int(6 * s) + 3, 1.1 * s, 4.5)


## Arı sütunu: yerden dönerek yükselen arılar (mühürle hedefin altından)
static func _bee_rise(p: Vector3, h: float) -> void:
	var sc = Engine.get_main_loop().current_scene
	var g = Vector3(p.x, Game.ground_height(p.x, p.z) + 0.2, p.z)
	for k in 5:
		var b = _bee_node(0.3)
		sc.add_child(b)
		var a0 = randf() * TAU
		var r = randf_range(0.3, 0.8)
		var tw = b.create_tween()
		tw.tween_method(func(t: float):
			if is_instance_valid(b):
				var a = a0 + t * TAU * 1.5
				b.global_position = g + Vector3(cos(a) * r, t * h, sin(a) * r)
				b.rotation.y = -a, 0.0, 1.0, 0.55 + k * 0.04)
		tw.tween_callback(b.queue_free)


## Hachi Bakudan (ref 1): arı altında sallanan patlayıcı kâğıtla kavis çizip hedefe dalar, varınca patlar
static func _bee_bomb(who: Node3D, from: Vector3, tg: Node3D, dmg: float, delay: float) -> void:
	who.get_tree().create_timer(maxf(0.001, delay)).timeout.connect(func():
		if not is_instance_valid(who):
			return
		var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
		var to = tg.global_position + Vector3.UP * 0.9 if tg and is_instance_valid(tg) else from + f * 10.0
		var b = _bee_node(0.4)
		if _tag_fly_mat == null:
			_tag_fly_mat = StandardMaterial3D.new()
			_tag_fly_mat.albedo_texture = load("res://assets/weapons/shibuki_tag.png")
			_tag_fly_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			_tag_fly_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			_tag_fly_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var q = MeshInstance3D.new()
		var qm = QuadMesh.new()
		qm.size = Vector2(0.12, 0.3)
		q.mesh = qm
		q.material_override = _tag_fly_mat
		b.add_child(q)
		q.position = Vector3(0, -0.22, 0)
		who.get_tree().current_scene.add_child(b)
		b.global_position = from
		var side = f.cross(Vector3.UP).normalized() * randf_range(-1.5, 1.5)
		var dur = clampf(from.distance_to(to) / 14.0, 0.45, 1.1)
		var tw = b.create_tween()
		tw.tween_method(func(t: float):
			if not is_instance_valid(b):
				return
			var live_to = tg.global_position + Vector3.UP * 0.9 if tg and is_instance_valid(tg) else to
			var p = from.lerp(live_to, t) + Vector3.UP * sin(t * PI) * 2.2 + side * sin(t * PI)
			var fl = live_to - p
			fl.y = 0.0
			if fl.length() > 0.05:
				b.rotation.y = atan2(-fl.x, -fl.z)
			b.global_position = p
			q.rotation.z = sin(t * 30.0) * 0.4, 0.0, 1.0, dur)   # kâğıt arının altında sallanır
		tw.tween_callback(func():
			var at = b.global_position if is_instance_valid(b) else to
			if is_instance_valid(b):
				b.queue_free()
			_boom(who, at, 0.55, dmg, 1.5, 0.0, 3.0)))


## Tarz açıkken çevresinde uçuşan birkaç arı (Kamizuru'nun yanında hep sürü olur); adım süresince
static func _bee_escort(who: Node3D, dur: float) -> void:
	if not is_instance_valid(who):
		return
	for k in 3:
		var b = _bee_node(0.22)
		who.add_child(b)
		var a0 = k * TAU / 3.0
		var tw = b.create_tween()
		tw.tween_method(func(t: float):
			if is_instance_valid(b):
				var a = a0 + t * TAU * 2.0
				b.position = Vector3(cos(a) * 0.8, 1.5 + sin(t * 9.0 + k) * 0.15, sin(a) * 0.8)
				b.rotation.y = -a, 0.0, 1.0, dur)
		tw.tween_callback(b.queue_free)


# ------------------------------------------------------------------ Hakkō Chakura Tō (Hatake beyaz ışık tantōsu)
const HAKKO_WHITE := Color(1.0, 1.0, 0.97, 0.95)

## Her kesik beyaz chakra yayı bırakır (kanon: "savrulunca beyaz chakra çizgisi"); bitiriş ileri uzanan ışık hilali
static func _hakko_strike(who: Node3D, i: int, dmg: float, f: Vector3, side: Vector3) -> void:
	var pj = PathJutsu.get_pinst()
	var at = who.global_position + Vector3.UP * 1.1 + f * 0.9
	match i:
		0:
			if pj:
				pj._arc_cut(at, f, -70.0, 70.0, HAKKO_WHITE, 1.3)
		1:
			if pj:
				pj._arc_cut(at + Vector3.UP * 0.2, (f + Vector3.UP * 0.6).normalized(), 60.0, -60.0, HAKKO_WHITE, 1.3)
		2:
			pass   # çizgi atılışta (_hakko_dash)
		3:
			if pj:
				pj._arc_cut(at, (f - Vector3.UP * 0.2).normalized(), 90.0, -20.0, HAKKO_WHITE, 1.4)
			FX.hit_spark(at + Vector3.DOWN * 0.4, Color(1, 1, 1), 0.9)
		4:   # tam tur: çevresinde beyaz halka, yakındaki herkese
			if pj:
				for k in 3:
					pj._arc_cut(who.global_position + Vector3.UP * 1.0, f.rotated(Vector3.UP, k * TAU / 3.0), -70.0, 70.0, HAKKO_WHITE, 1.6)
			Combat.hit_sphere(who, who.global_position + Vector3.UP * 1.0, 2.2, _kinfo(dmg, 0.6, {"element": "", "knock": 6.0, "kind": "light", "melee": true, "blade": true}))
		5:   # Hakkō Zan: ağızdan ileri uzanan beyaz ışık hilali (orta menzil ~6 m)
			var o = who.global_position + Vector3.UP * 1.1
			for k in 4:
				who.get_tree().create_timer(k * 0.04).timeout.connect(func():
					if is_instance_valid(who) and pj:
						pj._arc_cut(o + f * (1.2 + k * 1.4), f, -55.0, 55.0, HAKKO_WHITE, 1.4 + k * 0.25))
			WindFX.streak(func(t: float) -> Vector3: return o + f * t * 6.5, 0.3, 0.08, HAKKO_WHITE, 0.0, 12)
			for d in [2.5, 4.2, 5.8]:
				Combat.hit_sphere(who, o + f * d, 1.3, _kinfo(dmg, 0.55, {"element": "", "knock": 9.0, "kind": "heavy", "melee": true, "blade": true, "bleed": 2.0}))


## Shiroi Kiba atılışı: en yakın rakibin içinden geçip 1.6 m arkasında belirir; geçtiği yolda beyaz çizgi, yol üstündekiler kesilir
static func _hakko_dash(who: Node3D) -> void:
	var tg = _near_foe(who, 7.0)
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.FORWARD
	var from = who.global_position
	var to: Vector3
	if tg:
		var d = tg.global_position - from
		d.y = 0
		var dn = d.normalized() if d.length() > 0.05 else f
		to = tg.global_position + dn * 1.6
		f = dn
	else:
		to = from + f * 4.5
	to.y = Game.ground_height(to.x, to.z)
	var pj = PathJutsu.get_pinst()
	if pj:
		pj._trail_ghost(who, 0.4, 0.3)
	var o = from + Vector3.UP * 1.1
	var e = to + Vector3.UP * 1.1
	WindFX.streak(func(t: float) -> Vector3: return o.lerp(e, t), 0.35, 0.09, HAKKO_WHITE, 0.0, 12)
	if who is CharacterBody3D:
		who.global_position = to
		who.velocity = Vector3.ZERO
		if who is Player:
			if tg:
				who.combat.face_to(tg)
		elif who.get("facing") != null and tg:
			var back = tg.global_position - to
			who.facing = atan2(-back.x, -back.z)
	var dmg = 6.0
	if who is Player:
		dmg = float(who.combat._combo(2).get("dmg", 6.0)) if who.combat.has_method("_combo") else 6.0
	for k in 3:
		Combat.hit_sphere(who, o.lerp(e, 0.25 + k * 0.25), 1.0, _kinfo(dmg, 0.5, {"element": "", "knock": 3.0, "kind": "light", "melee": true, "blade": true, "bleed": 2.0}))


# ------------------------------------------------------------------ Mateki (Tayuya'nın şeytani flütü)
const MATEKI_RED := Color(0.9, 0.2, 0.25)

## Flütün ucu (dünya): ses ve ruhlar buradan çıkar
static func _flute_tip(who: Node3D) -> Vector3:
	var n = _weapon_node(who)
	if n != null:
		return n.to_global(Vector3(0, 0, 0.45))
	return who.global_position + Vector3.UP * 1.5


static func _mateki_strike(who: Node3D, i: int, dmg: float, f: Vector3, side: Vector3) -> void:
	var tg = _near_foe(who, 14.0)
	var at = who.global_position + Vector3.UP * 1.2 + f * 1.0
	match i:
		0, 1:
			FX.hit_spark(at, Color(0.95, 0.93, 1.0), 0.6)
		2:   # Onpa: keskin nota — önde ses halkaları, iter
			var o = who.global_position + Vector3.UP * 1.5
			for k in 3:
				who.get_tree().create_timer(k * 0.06).timeout.connect(func():
					if is_instance_valid(who):
						VFX.shockwave(o + f * (0.8 + k * 1.1), Color(0.85, 0.8, 1.0), 1.4 + k * 0.9, 0.25, false, f))
			for d in [1.6, 3.2]:
				Combat.hit_sphere(who, o + f * d, 1.4, _kinfo(dmg, 0.6, {"element": "", "knock": 9.0, "kind": "light", "melee": false}))
		3:   # Mugen Onsa: kırmızı ses dalgaları, rakibi ses zincirleri bağlar
			var o2 = who.global_position + Vector3.UP * 1.5
			for k in 3:
				who.get_tree().create_timer(k * 0.1).timeout.connect(func():
					if is_instance_valid(who):
						VFX.shockwave(o2, MATEKI_RED, 3.0 + k * 2.5, 0.35, false))
			if tg and is_instance_valid(tg):
				var pj = PathJutsu.get_pinst()
				if pj:
					for j in 3:
						var a = j * TAU / 3.0
						pj.tether(func(): return tg.global_position + Vector3(cos(a) * 1.4, 2.4, sin(a) * 1.4) if is_instance_valid(tg) else Vector3.ZERO, func(): return tg.global_position + Vector3.UP if is_instance_valid(tg) else Vector3.ZERO, 0.04, VFX.mat_bolt(MATEKI_RED, 1.4), 1.2)
				if tg.has_method("apply_status"):
					tg.apply_status("bind", 1.0)
				tg.take_hit(_kinfo(dmg, 0.5, {"element": "", "knock": 0.0, "kind": "light", "attacker": who}))
				Combat.popup_text(tg.global_position + Vector3.UP * 2.4, "Ses zinciri!", MATEKI_RED)
		4:   # Reigeki: flütten ruh solucanı rakibe dalar, chakra yer
			if tg and is_instance_valid(tg):
				var from = _flute_tip(who)
				var to = tg.global_position + Vector3.UP * 1.0
				Doki.spirit_worm(who.get_tree().current_scene, from, to, 0.55, func(p: Vector3):
					VFX.puffs(p, {"amount": 14, "life": 0.5, "size": 0.35, "radius": 0.4, "vmin": 1, "vmax": 3, "spread": 180.0, "add": false, "colors": [Color(0.55, 0.45, 0.7, 0.9), Color(0.3, 0.25, 0.4, 0)]})
					if is_instance_valid(who):
						for h in Combat.hit_sphere(who, p, 1.4, _kinfo(dmg, 1.0, {"element": "", "knock": 3.0, "kind": "heavy"})):
							_kikai_drain(who, h, 0.05))
		5:   # Doki no Tsuchi: Gürzlü Doki arkadan dumanla belirir, gürzünü rakibin üstüne indirir
			var tp = tg.global_position if tg and is_instance_valid(tg) else who.global_position + f * 5.0
			var dp = who.global_position - f * 2.2
			dp.y = Game.ground_height(dp.x, dp.z)
			FX.smoke_puff(dp + Vector3.UP * 2.0, 1.2, 12)
			var dk = Doki.spawn(who.get_tree().current_scene, dp, 0.0, 0)
			var fl = tp - dp
			fl.y = 0
			dk.rotation.y = atan2(-fl.x, -fl.z)
			dk.set_pose("raise", 0.0)
			who.get_tree().create_timer(0.35).timeout.connect(func():
				if is_instance_valid(dk):
					dk.set_pose("smash", 0.18))
			who.get_tree().create_timer(0.53).timeout.connect(func():
				if not is_instance_valid(who) or not is_instance_valid(dk):
					return
				var g = dk.weapon.to_global(Vector3(0, 4.5, 0)) if dk.weapon else tp
				g.y = Game.ground_height(g.x, g.z)
				VFX.cracks(g, 3.0)
				VFX.shockwave(g + Vector3.UP * 0.1, Color(0.7, 0.62, 0.52), 5.0, 0.3, true)
				_shake(who, 0.4)
				Combat.hit_sphere(who, g + Vector3.UP * 0.8, 2.4, _kinfo(dmg, 2.2, {"element": "", "knock": 6.0, "launch": 6.0, "kind": "heavy"})))
			who.get_tree().create_timer(1.5).timeout.connect(func():
				if is_instance_valid(dk):
					FX.smoke_puff(dk.global_position + Vector3.UP * 2.5, 2.2, 20)
					dk.queue_free())
