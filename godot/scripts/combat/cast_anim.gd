class_name CastAnim
extends Node
## Jutsu atma koreografisi: el mühürleri (12 mühür + klon + yüzleşme mühürü), sonra jutsuya özel
## hazırlık (wind) ve salınım (release) pozu. Oyuncu ve düşmanlar ortak kullanır:
##   var a = CastAnim.play(fighter, jid)           # oyuncu: süreleri kendisi hesaplar
##   var a = CastAnim.play(enemy, jid, 0.55)       # düşman: verilen sürenin sonunda salınım
## a.release_t (sn) anında jutsu çıkmalı; a.total_t sonunda düğüm kendini siler.

# ------------------------------------------------------------------ mühür kütüphanesi
## Model uzayı: +Z karakterin önü, +X karakterin solu, +Y yukarı.
## Her mühür: el yönleri (L/R) + parmak kıvrımları [işaret, orta, yüzük, serçe, başparmak] (rad, 0 = düz)
## eller göğüs önünde birleşir: dirsek gövdeye yakın, ön kol merkeze doğru
static var SEAL_ARMS_L := [Vector3(0.22, -0.85, 0.47), Vector3(-0.74, 0.42, 0.52)]   # eller göğüs ortasında buluşur (çapraz geçmez)
static var SEAL_ARMS_R := [Vector3(-0.22, -0.85, 0.47), Vector3(0.74, 0.42, 0.52)]
const SEALS := {
	"Ne": {"tr": "Fare", "L": Vector3(-0.2, 0.6, 0.75), "R": Vector3(0.1, 0.95, 0.2), "fL": [1.4, 1.4, 1.4, 1.4, 0.6], "fR": [0.0, 0.0, 1.5, 1.5, 0.9]},
	"Ushi": {"tr": "Öküz", "L": Vector3(-0.2, 0.95, 0.2), "R": Vector3(0.95, 0.1, 0.3), "fL": [0.0, 0.0, 0.0, 0.0, 0.3], "fR": [0.9, 0.9, 0.9, 0.9, 0.3]},
	"Tora": {"tr": "Kaplan", "L": Vector3(-0.15, 0.95, 0.25), "R": Vector3(0.15, 0.95, 0.25), "fL": [0.0, 0.0, 1.5, 1.5, 0.1], "fR": [0.0, 0.0, 1.5, 1.5, 0.1], "lift": 0.1},
	"U": {"tr": "Tavşan", "L": Vector3(-0.2, 0.9, 0.35), "R": Vector3(0.3, -0.3, 0.9), "fL": [0.0, 0.0, 0.0, 0.0, 0.2], "fR": [1.4, 1.4, 1.4, 1.4, 0.8]},
	"Tatsu": {"tr": "Ejderha", "L": Vector3(-0.4, 0.5, 0.75), "R": Vector3(0.4, 0.5, 0.75), "fL": [1.0, 1.0, 1.0, 1.0, 0.0], "fR": [1.0, 1.0, 1.0, 1.0, 0.0]},
	"Mi": {"tr": "Yılan", "L": Vector3(-0.5, 0.3, 0.8), "R": Vector3(0.5, 0.3, 0.8), "fL": [1.3, 1.3, 1.3, 1.3, 0.5], "fR": [1.3, 1.3, 1.3, 1.3, 0.5], "lift": -0.1},
	"Uma": {"tr": "At", "L": Vector3(-0.3, 0.85, 0.4), "R": Vector3(0.3, 0.85, 0.4), "fL": [0.0, 1.5, 1.5, 1.5, 0.0], "fR": [0.0, 1.5, 1.5, 1.5, 0.0], "lift": 0.15},
	"Hitsuji": {"tr": "Koç", "L": Vector3(-0.2, 0.6, 0.75), "R": Vector3(0.15, 0.95, 0.2), "fL": [1.3, 1.3, 1.4, 1.4, 0.6], "fR": [0.0, 0.0, 1.5, 1.5, 0.9], "lift": 0.2},
	"Saru": {"tr": "Maymun", "L": Vector3(-0.95, 0.15, 0.25), "R": Vector3(0.2, 0.95, 0.2), "fL": [0.0, 0.0, 0.0, 0.0, 0.2], "fR": [0.0, 0.0, 0.0, 0.0, 0.2]},
	"Tori": {"tr": "Kuş", "L": Vector3(-0.3, 0.4, 0.85), "R": Vector3(0.3, 0.4, 0.85), "fL": [0.0, 0.0, 0.0, 1.2, 0.2], "fR": [0.0, 0.0, 0.0, 1.2, 0.2]},
	"Inu": {"tr": "Köpek", "L": Vector3(-0.9, -0.1, 0.4), "R": Vector3(0.2, 0.2, 0.95), "fL": [0.0, 0.0, 0.0, 0.0, 0.0], "fR": [1.4, 1.4, 1.4, 1.4, 0.9], "lift": -0.15},
	"I": {"tr": "Domuz", "L": Vector3(-0.2, -0.5, 0.85), "R": Vector3(0.2, -0.5, 0.85), "fL": [0.0, 0.0, 0.0, 0.0, 0.6], "fR": [0.0, 0.0, 0.0, 0.0, 0.6], "lift": -0.2},
	"Bunshin": {"tr": "Klon", "L": Vector3(-0.95, 0.0, 0.3), "R": Vector3(0.1, 0.95, 0.2), "fL": [0.0, 0.0, 1.5, 1.5, 0.9], "fR": [0.0, 0.0, 1.5, 1.5, 0.9]},
	"Tairitsu": {"tr": "Yüzleşme", "L": null, "R": Vector3(0.1, 0.95, 0.2), "fL": [], "fR": [0.0, 0.0, 1.5, 1.5, 0.9], "one": true},
}

# ------------------------------------------------------------------ atma stilleri
## wind/rel: {"L": [üst kol, ön kol, el] | null, "R": [...] | null, "fL", "fR", "spine", "neck", "hips_yaw"}
## pre: hazırlık süresi, post: salınım sonrası tutma, clip: gövde animasyonu (salınımda), wclip: hazırlıkta
const FIST := [1.45, 1.45, 1.45, 1.45, 0.9]
const OPEN := [0.0, 0.0, 0.0, 0.0, 0.0]
const CLAW := [0.6, 0.6, 0.6, 0.6, 0.4]
const STYLES := {
	# ağızdan alev/su/rüzgar: el halkası ağızda, geriye eğil -> öne üfle
	"breath": {"pre": 0.32, "post": 0.45, "wclip": "idle", "clip": "idle",
		"wind": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9],
			"L": [Vector3(0.25, -0.95, -0.1), Vector3(0.1, -0.95, 0.2), Vector3(0.0, -1.0, 0.1)], "fL": FIST, "spine": -16.0, "neck": -12.0},
		"rel": {"R": [Vector3(-0.25, -0.5, 0.82), Vector3(0.7, 0.62, 0.35), Vector3(0.4, 0.75, 0.5)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9],
			"L": [Vector3(0.3, -0.9, -0.2), Vector3(0.1, -0.9, -0.3), Vector3(0.0, -1.0, -0.1)], "fL": FIST, "spine": 18.0, "neck": 8.0}},
	# tek avuç ileri (Fūton patlaması, kemik mermisi, su tabancası)
	"palm": {"pre": 0.2, "post": 0.35, "wclip": "idle", "clip": "a/Spell_Simple_Shoot",
		"wind": {"R": [Vector3(-0.45, -0.6, -0.65), Vector3(-0.1, 0.4, 0.9), Vector3(0.0, 0.9, 0.4)], "fR": OPEN,
			"L": [Vector3(0.3, -0.55, 0.75), Vector3(-0.2, 0.1, 0.97), Vector3(-0.1, 0.9, 0.4)], "fL": OPEN, "spine": -6.0},
		"rel": {"R": [Vector3(-0.08, 0.05, 1.0), Vector3(0.0, 0.05, 1.0), Vector3(0.0, 0.9, 0.45)], "fR": OPEN,
			"L": [Vector3(0.35, -0.55, -0.75), Vector3(0.1, -0.6, -0.8), Vector3(0.0, -0.9, -0.3)], "fL": FIST, "spine": 14.0, "hips_yaw": -18.0}},
	# iki avuç ileri itiş (Suiton dalgası/ejderha, böcek sürüsü)
	"two_palm": {"pre": 0.26, "post": 0.4, "wclip": "idle", "clip": "a/Push",
		"wind": {"L": [Vector3(0.45, -0.75, -0.3), Vector3(-0.5, 0.3, 0.8), Vector3(-0.2, 0.9, 0.3)], "R": [Vector3(-0.45, -0.75, -0.3), Vector3(0.5, 0.3, 0.8), Vector3(0.2, 0.9, 0.3)], "fL": OPEN, "fR": OPEN, "spine": -8.0},
		"rel": {"L": [Vector3(0.15, 0.0, 1.0), Vector3(0.05, 0.0, 1.0), Vector3(0.0, 0.85, 0.5)], "R": [Vector3(-0.15, 0.0, 1.0), Vector3(-0.05, 0.0, 1.0), Vector3(0.0, 0.85, 0.5)], "fL": OPEN, "fR": OPEN, "spine": 12.0}},
	# yere vuruş (Doton/Mokuton/Hyōton mızrakları): kollar yukarı -> çömelip avuçlar yere
	"ground": {"pre": 0.3, "post": 0.5, "wclip": "idle", "clip": "idle",
		"wind": {"L": [Vector3(0.2, 0.95, 0.2), Vector3(0.1, 0.95, 0.3), Vector3(0.0, 1.0, 0.1)], "R": [Vector3(-0.2, 0.95, 0.2), Vector3(-0.1, 0.95, 0.3), Vector3(0.0, 1.0, 0.1)], "fL": OPEN, "fR": OPEN, "spine": -10.0, "neck": -10.0},
		"rel": {"L": [Vector3(0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "fL": OPEN, "fR": OPEN, "spine": 48.0, "neck": -22.0, "crouch": 0.85}},
	# gökyüzü çağrısı (Raiton yıldırımı, Kirin tarzı)
	"sky": {"pre": 0.35, "post": 0.5, "wclip": "idle", "clip": "idle",
		"wind": {"R": [Vector3(-0.6, 0.2, 0.75), Vector3(-0.3, 0.8, 0.5), Vector3(0.0, 1.0, 0.2)], "fR": OPEN, "L": [Vector3(0.25, -0.95, 0.0), Vector3(0.1, -0.95, 0.2), Vector3(0.0, -1.0, 0.0)], "fL": FIST, "neck": -15.0},
		"rel": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "fR": [0.0, 0.0, 1.4, 1.4, 0.8], "L": [Vector3(0.3, -0.9, 0.1), Vector3(0.1, -0.9, 0.3), Vector3(0.0, -1.0, 0.1)], "fL": FIST, "neck": -28.0, "spine": -8.0}},
	# tek elde enerji topla (Chidori/Rasengan): el aşağıda avuç açık, diğer el bileği tutar -> ileri saplama
	"charge": {"pre": 0.55, "post": 0.4, "wclip": "idle", "clip": "a/Punch_Cross",
		"wind": {"R": [Vector3(-0.25, -0.6, 0.75), Vector3(0.1, -0.15, 0.98), Vector3(0.1, -0.1, 1.0)], "fR": CLAW,
			"L": [Vector3(0.4, -0.65, 0.6), Vector3(-0.75, -0.1, 0.65), Vector3(-0.6, -0.2, 0.75)], "fL": [0.8, 0.8, 0.8, 0.8, 0.6], "spine": 22.0, "neck": -10.0, "crouch": 0.35},
		"rel": {"R": [Vector3(-0.05, 0.05, 1.0), Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.0, 1.0)], "fR": CLAW,
			"L": [Vector3(0.35, -0.6, -0.7), Vector3(0.1, -0.7, -0.7), Vector3(0.0, -0.9, -0.3)], "fL": FIST, "spine": 26.0, "hips_yaw": -22.0}},
	# fırlatma (alet jutsuları, dev shuriken)
	"throw": {"pre": 0.22, "post": 0.35, "wclip": "idle", "clip": "b/OverhandThrow",
		"wind": {"R": [Vector3(-0.6, 0.6, -0.5), Vector3(-0.2, 0.9, -0.4), Vector3(0.0, 1.0, -0.2)], "fR": FIST, "L": [Vector3(0.3, -0.3, 0.9), Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.3, 0.95)], "fL": OPEN, "spine": -10.0, "hips_yaw": 25.0},
		"rel": {}},
	# çağırma: başparmağı ısır -> çömel, avuç yere, duman
	"summon": {"pre": 0.5, "post": 0.95, "wclip": "idle", "clip": "idle",
		"wind": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.7, 0.65, 0.25), Vector3(0.3, 0.9, 0.2)], "fR": [1.4, 1.4, 1.4, 1.4, 0.0], "L": [Vector3(0.3, -0.85, 0.3), Vector3(0.0, -0.8, 0.6), Vector3(0.0, -0.9, 0.4)], "fL": OPEN},
		"rel": {"R": [Vector3(-0.1, -0.75, 0.65), Vector3(0.0, -0.97, 0.25), Vector3(0.0, -0.3, 0.95)], "fR": [-0.25, -0.25, -0.25, -0.25, -0.35], "L": [Vector3(0.45, -0.55, 0.7), Vector3(0.2, -0.75, 0.6), Vector3(0.0, -0.8, 0.6)], "fL": OPEN, "spine": 52.0, "neck": -30.0, "crouch": 1.0}},
	# klon: çapraz mühür tut
	"clone": {"pre": 0.25, "post": 0.3, "wclip": "idle", "clip": "idle", "seal_pose": "Bunshin"},
	# dönüşüm: kaplan mühürü + yerinde dönüş
	"spin": {"pre": 0.35, "post": 0.25, "wclip": "idle", "clip": "idle", "seal_pose": "Tora", "spin": 360.0},
	# beden titremesi: tek el yüzleşme mühürü, hızlı
	"flicker": {"pre": 0.1, "post": 0.15, "wclip": "idle", "clip": "idle", "seal_pose": "Tairitsu"},
	# algı / genjutsu: kaplan mühürü yüz hizasında, baş eğik
	"sense": {"pre": 0.32, "post": 0.35, "wclip": "idle", "clip": "idle", "seal_pose": "Tora", "neck": 10.0},
	# tıbbi: iki avuç bel hizasında aşağı bakar, yeşil ışık
	"medical": {"pre": 0.3, "post": 0.4, "wclip": "idle", "clip": "idle",
		"wind": {"L": [Vector3(0.2, -0.75, 0.6), Vector3(0.0, -0.3, 0.95), Vector3(0.0, -0.35, 0.95)], "R": [Vector3(-0.2, -0.75, 0.6), Vector3(0.0, -0.3, 0.95), Vector3(0.0, -0.35, 0.95)], "fL": OPEN, "fR": OPEN, "spine": 15.0},
		"rel": {"L": [Vector3(0.2, -0.75, 0.6), Vector3(0.0, -0.4, 0.92), Vector3(0.0, -0.5, 0.85)], "R": [Vector3(-0.2, -0.75, 0.6), Vector3(0.0, -0.4, 0.92), Vector3(0.0, -0.5, 0.85)], "fL": OPEN, "fR": OPEN, "spine": 22.0, "crouch": 0.5}},
	# mühürleme: avuçlar birleşik -> yana açılır (parşömen/zincir)
	"scroll": {"pre": 0.35, "post": 0.45, "wclip": "idle", "clip": "idle",
		"wind": {"L": [Vector3(0.3, -0.5, 0.8), Vector3(-0.5, 0.1, 0.85), Vector3(-0.3, 0.3, 0.9)], "R": [Vector3(-0.3, -0.5, 0.8), Vector3(0.5, 0.1, 0.85), Vector3(0.3, 0.3, 0.9)], "fL": OPEN, "fR": OPEN},
		"rel": {"L": [Vector3(0.6, -0.35, 0.7), Vector3(0.7, 0.0, 0.7), Vector3(0.7, 0.2, 0.7)], "R": [Vector3(-0.6, -0.35, 0.7), Vector3(-0.7, 0.0, 0.7), Vector3(-0.7, 0.2, 0.7)], "fL": OPEN, "fR": OPEN, "spine": 8.0}},
	# güç patlaması (Baika, kemik zırhı, yıldırım zırhı, chakra zincirleri): çömel, yumruklar geride -> kollar açılır, haykırış
	"power": {"pre": 0.4, "post": 0.5, "wclip": "idle", "clip": "idle",
		"wind": {"L": [Vector3(0.35, -0.85, -0.35), Vector3(0.1, -0.9, -0.4), Vector3(0.0, -1.0, -0.2)], "R": [Vector3(-0.35, -0.85, -0.35), Vector3(-0.1, -0.9, -0.4), Vector3(0.0, -1.0, -0.2)], "fL": FIST, "fR": FIST, "spine": 25.0, "neck": -10.0, "crouch": 0.55},
		"rel": {"L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "fL": FIST, "fR": FIST, "spine": -14.0, "neck": -22.0}},
	# Kum Shurikeni hazırlık: kollar iki yana açık, hafif yukarı, pençe eller (kum kollar bu pozda büyür) — Gaara referansı
	"sand_arms": {"pre": 0.3, "post": 0.55, "wclip": "idle", "clip": "idle",
		"wind": {"L": [Vector3(0.9, 0.05, -0.3), Vector3(0.95, 0.2, -0.1), Vector3(0.9, 0.35, 0.1)], "R": [Vector3(-0.9, 0.05, -0.3), Vector3(-0.95, 0.2, -0.1), Vector3(-0.9, 0.35, 0.1)], "fL": CLAW, "fR": CLAW, "spine": -6.0, "neck": -6.0, "crouch": 0.45},
		"rel": {"L": [Vector3(0.95, 0.2, -0.2), Vector3(0.95, 0.3, 0.0), Vector3(0.85, 0.45, 0.2)], "R": [Vector3(-0.95, 0.2, -0.2), Vector3(-0.95, 0.3, 0.0), Vector3(-0.85, 0.45, 0.2)], "fL": CLAW, "fR": CLAW, "spine": -10.0, "neck": -8.0, "crouch": 0.5}},
	# Kum Shurikeni savuruş: açık kollar öne çaprazlanarak savrulur
	"sand_swing": {"pre": 0.06, "post": 0.45, "wclip": "idle", "clip": "idle",
		"wind": {"L": [Vector3(0.95, 0.2, -0.2), Vector3(0.95, 0.3, 0.0), Vector3(0.85, 0.45, 0.2)], "R": [Vector3(-0.95, 0.2, -0.2), Vector3(-0.95, 0.3, 0.0), Vector3(-0.85, 0.45, 0.2)], "fL": CLAW, "fR": CLAW, "spine": -10.0, "crouch": 0.5},
		"rel": {"L": [Vector3(0.35, 0.0, 0.95), Vector3(-0.3, -0.05, 0.95), Vector3(-0.5, -0.1, 0.85)], "R": [Vector3(-0.35, 0.0, 0.95), Vector3(0.3, -0.05, 0.95), Vector3(0.5, -0.1, 0.85)], "fL": OPEN, "fR": OPEN, "spine": 22.0, "neck": -6.0, "crouch": 0.6}},
	# klan taijutsu atılımı (Gatsūga, Nikudan, Jūken): öne eğik hücum duruşu
	"rush": {"pre": 0.22, "post": 0.3, "wclip": "idle", "clip": "b/Melee_Hook",
		"wind": {"L": [Vector3(0.3, -0.5, 0.8), Vector3(-0.1, 0.0, 1.0), Vector3(0.0, 0.6, 0.8)], "R": [Vector3(-0.4, -0.7, -0.5), Vector3(0.0, -0.3, -0.95), Vector3(0.0, -0.6, -0.8)], "fL": OPEN, "fR": OPEN, "spine": 28.0, "neck": -18.0, "crouch": 0.4},
		"rel": {"R": [Vector3(-0.08, 0.05, 1.0), Vector3(0.0, 0.05, 1.0), Vector3(0.0, 0.9, 0.45)], "fR": OPEN, "L": [Vector3(0.35, -0.55, -0.75), Vector3(0.1, -0.6, -0.8), Vector3(0.0, -0.9, -0.3)], "fL": OPEN, "spine": 20.0}},
}

## Bilinen her jutsu -> stil (yeni jutsular için STYLE_DEFAULT kuralları)
const JUTSU_STYLE := {
	"henge": "spin", "shunshin": "flicker", "bunshin": "clone",
	"katon_goukakyuu": "breath", "katon_housenka": "breath", "katon_karyuu": "breath",
	"suiton_suikoudan": "two_palm", "suiton_suijinheki": "breath", "suiton_suiryuudan": "two_palm",
	"fuuton_shinkuu": "breath", "fuuton_daitoppa": "breath", "fuuton_rasenshuriken": "charge",
	"doton_doryuusou": "ground", "doton_doryuheki": "ground", "doton_yomi": "ground",
	"raiton_nagashi": "power", "raiton_chidori": "charge", "raiton_armor": "power",
	"rasengan": "charge", "shousen": "medical", "narakumi": "sense", "kokuangyo": "sense", "kuchiyose": "summon",
	"juuken_64": "rush", "kaiten": "spin", "kagemane": "sense", "kage_kubi": "sense",
	"baika": "power", "nikudan": "power", "mushi_swarm": "two_palm", "ninken": "summon", "gatsuga": "rush",
	"shintenshin": "sense", "mokuton_spikes": "ground", "mokuton_wall": "ground",
	"hyoton_senbon": "two_palm", "hyoton_spears": "ground", "bone_bullets": "palm", "bone_armor": "power",
	"chakra_chains": "scroll", "suika": "power", "water_gun": "palm",
	"sarutobi_haisekisho": "breath", "sarutobi_karyu": "breath", "hatake_hakko": "charge", "hatake_ninken": "summon",
	"chinoike_ketsuryugan": "sense", "chinoike_kanshu": "sense", "hoshigaki_same": "two_palm", "hoshigaki_ryudan": "two_palm",
	"kurama_genjutsu": "sense", "kurama_kokuangyo": "sense", 
	"kamizuru_bees": "two_palm", "kamizuru_wax": "breath",
	"suna_shuriken_swing": "sand_swing",
}


static func style_for(jid: String, j: Dictionary = {}) -> String:
	if ClanJutsu.STYLE.has(jid):
		return ClanJutsu.STYLE[jid]
	if PathJutsu.PANIM.has(jid):
		return String(PathJutsu.PANIM[jid].get("base", "palm"))
	if PathJutsu.PSTYLE.has(jid):
		return PathJutsu.PSTYLE[jid]
	if JUTSU_STYLE.has(jid):
		return JUTSU_STYLE[jid]
	var shape = String(j.get("shape", ""))
	match shape:
		"beam", "breath": return "breath"
		"wall", "spikes", "field": return "ground"
		"summon": return "summon"
		"heal": return "medical"
		"buff", "transform": return "power"
		"clone": return "clone"
		"teleport": return "flicker"
		"genjutsu_stun", "bind": return "sense"
		"melee": return "rush"
	var cat = String(j.get("category", ""))
	if cat in ["medical"]:
		return "medical"
	if cat in ["fuinjutsu", "sealing"]:
		return "scroll"
	if cat in ["genjutsu", "sensing"]:
		return "sense"
	if cat in ["summoning"]:
		return "summon"
	if cat in ["taijutsu"]:
		return "rush"
	var el = String(j.get("element", ""))
	if jid.contains("kuchiyose") or jid.contains("summon"):
		return "summon"
	match el:
		"katon", "yoton": return "breath"
		"shakuton": return "palm"        # Pakura: küreler avuçlardan
		"futton": return "breath"        # Mei: asit sisini ağızdan üfler
		"suiton": return "two_palm"
		"hyoton": return "sense"         # Haku: mühür pozu, buz kendiliğinden belirir
		"fuuton": return "palm"
		"jinton": return "two_palm"      # Ōnoki: küp iki avuç arasında
		"bakuton": return "palm"         # Deidara: avuçtaki ağızlardan kil
		"doton", "mokuton", "jiton": return "ground"
		"ranton": return "two_palm"      # Darui: birleşik avuçlardan lazer
		"raiton": return "sky" if (jid.contains("kirin") or jid.contains("thunder") or jid.contains("rai_")) else "charge"
	return "palm"


# ------------------------------------------------------------------ çalışma zamanı
var f: Node3D
var model: CharacterModel
var jid := ""
var j := {}
var style := "palm"
var st := {}
var seals: Array = []
var per := 0.1
var seal_end := 0.0
var release_t := 0.0
var total_t := 0.0
var t := 0.0
var released := false
var is_player := false
var _last_seal := -1
var _cam_base := -1.0
var _charge_fx_t := 0.0
var _track := false   # yalnızca gerçek atışta kesinti izlenir


## Bir jutsu atışını başlatır. fit > 0 ise salınım tam o anda olur (mühürler ona sığdırılır).
static func play(fighter: Node3D, id: String, fit := -1.0) -> CastAnim:
	var old = fighter.get_node_or_null("CastAnim")
	if old:
		old.finish()
		old.name = "CastAnimOld"
	var a = CastAnim.new()
	a.name = "CastAnim"
	a.f = fighter
	a.model = fighter.get("model")
	a.jid = id
	a.j = Data.jutsu.get(id, {})
	a.style = style_for(id, a.j)
	a.st = STYLES.get(a.style, STYLES["palm"])
	if PathJutsu.PANIM.has(id):   # jutsuya özel koreografi: temel stilin üstüne kendi hazırlık/salınım pozu ve zamanlaması
		var cust: Dictionary = PathJutsu.PANIM[id]
		var st2: Dictionary = a.st.duplicate(true)
		for k in cust:
			if k != "base":
				st2[k] = cust[k]
		a.st = st2
	a.seals = (a.j.get("seals", []) as Array).duplicate()
	a.is_player = fighter is Player
	a._plan(fit)
	fighter.add_child(a)
	a._begin()
	return a


func _plan(fit: float) -> void:
	# mühür hızı: Hızlı Mühür (nin3) yetisi + seviye ile hızlanır
	per = 0.2   # okunur mühür süresi (acemi ~0.27 sn/mühür, usta ~0.09)
	if is_player:
		per /= 1.0 + Stats.skill(Game.profile, "seal_speed")  # Hızlı Mühür, Tek El Mühürü
		per *= Mastery.seal_speed(Game.profile)   # acemi yavaş ve okunur mühür yapar, usta hızlanır
	var pre: float = st.get("pre", 0.2)
	var post: float = st.get("post", 0.35)
	if fit > 0.0:
		# düşman: verilen süreye sığdır
		var need = seals.size() * per + pre
		if need > fit:
			var k = fit / need
			per *= k
			pre *= k
	seal_end = seals.size() * per
	release_t = seal_end + pre
	total_t = release_t + post


func _begin() -> void:
	if model == null:
		return
	if is_player:
		_track = f.combat != null and f.combat.action == "cast"
	elif "state" in f:
		_track = f.state == "cast"
	model.overlay.set_pose("seal", 0.0)
	model.overlay.set_pose("cast", 1.0)
	# jutsuya özel hazırlık görseli (ör. Rasenshuriken başın üstünde oluşur)
	if Jutsu.has_method("form_" + jid):
		Jutsu.call("form_" + jid, f, release_t)
	elif PathJutsu.get_pinst() and PathJutsu.get_pinst().has_method("form_" + jid):
		PathJutsu.get_pinst().call("form_" + jid, f, release_t)   # Efsane Yolu hazırlığı (ör. parşömen ele gelir)
	if seals.size() > 0:
		model.play("idle", 0.08)
	else:
		model.play(st.get("wclip", "idle"), 0.1)
	# büyük jutsularda kamera hafifçe yaklaşır
	if is_player and (String(j.get("canon_rank", "")) in ["B", "A", "S"] or int(j.get("cost", 0)) >= 30):
		_cam_base = f.cam_dist
		var tw = f.create_tween()
		tw.tween_property(f, "cam_dist", _cam_base * 0.82, maxf(0.15, release_t)).set_trans(Tween.TRANS_SINE)


func _process(dt: float) -> void:
	if model == null or not is_instance_valid(f):
		queue_free()
		return
	t += dt
	# kesintiye uğradıysa (darbe, sersemleme) koreografiyi bırak
	if t < release_t and _track:
		var interrupted = false
		if is_player:
			interrupted = f.combat != null and f.combat.action != "cast"
		elif "state" in f:
			interrupted = f.state != "cast"
		if interrupted and t > 0.05:
			if t >= release_t - 0.25:
				# oyuncu jutsuyu bu karede saldı (sayaç bir kare geride): kesinti değil, salınıma geç
				t = release_t
			else:
				finish()
				return
	var pose: Dictionary
	if t < seal_end and seals.size() > 0:
		var idx = clampi(int(t / per), 0, seals.size() - 1)
		if idx != _last_seal:
			_last_seal = idx
			_on_seal(idx)
		var k = clampf((t - idx * per) / (per * 0.45), 0.0, 1.0)
		var prev = _seal_pose(seals[idx - 1]) if idx > 0 else _seal_pose(seals[idx])
		pose = _blend(prev, _seal_pose(seals[idx]), k)
	elif t < release_t:
		var k = clampf((t - seal_end) / maxf(0.01, release_t - seal_end), 0.0, 1.0)
		var from = _seal_pose(seals[-1]) if seals.size() > 0 else _style_pose("wind")
		if t - dt < seal_end or (seals.is_empty() and _last_seal == -1):
			_last_seal = 99
			model.play(st.get("wclip", "idle"), 0.12)
		pose = _blend(from, _style_pose("wind"), minf(1.0, k * 2.0))
		if st.has("spin"):
			pose["hips_yaw"] = float(st["spin"]) * k
		_charge_fx(dt)
	else:
		if not released:
			released = true
			_on_release()
		# salınım sonrası başka eyleme geçildiyse (saldırı, blok, darbe) poz hemen bırakılır
		if t > release_t + 0.05 and ((is_player and f.combat != null and f.combat.action not in ["", "cast"]) or (not is_player and "state" in f and f.state in ["hitstun", "knockdown", "attack", "dodge", "guard"])):
			finish()
			return
		var k = clampf((t - release_t) / 0.08, 0.0, 1.0)
		pose = _blend(_style_pose("wind"), _style_pose("rel"), k)
		if t >= total_t:
			finish()
			return
	model.overlay.cast_pose = pose


func finish() -> void:
	if model and is_instance_valid(model):
		model.overlay.set_pose("cast", 0.0)
	if _cam_base > 0.0 and is_instance_valid(f):
		f.create_tween().tween_property(f, "cam_dist", _cam_base, 0.35)
		_cam_base = -1.0
	queue_free()


# ------------------------------------------------------------------ pozlar
static func _arms_from(seal: Dictionary) -> Dictionary:
	var lift: float = seal.get("lift", 0.0)
	var p = {"fL": seal.get("fL", []), "fR": seal.get("fR", [])}
	var arms = []
	if seal.get("L") != null:
		arms.append(["LeftUpperArm", SEAL_ARMS_L[0] + Vector3(0, lift, 0)])
		arms.append(["LeftLowerArm", SEAL_ARMS_L[1] + Vector3(0, lift, 0)])
		arms.append(["LeftHand", seal["L"]])
	if seal.get("R") != null:
		if seal.get("one", false):
			# tek el yüz hizasında
			arms.append(["RightUpperArm", Vector3(-0.3, -0.45, 0.85)])
			arms.append(["RightLowerArm", Vector3(0.55, 0.75, 0.35)])
		else:
			arms.append(["RightUpperArm", SEAL_ARMS_R[0] + Vector3(0, lift, 0)])
			arms.append(["RightLowerArm", SEAL_ARMS_R[1] + Vector3(0, lift, 0)])
		arms.append(["RightHand", seal["R"]])
	p["arms"] = arms
	return p


func _seal_pose(name: String) -> Dictionary:
	return _arms_from(SEALS.get(name, SEALS["Tora"]))


func _style_pose(which: String) -> Dictionary:
	if st.has("seal_pose"):
		var sp = _seal_pose(st["seal_pose"])
		if st.has("neck"):
			sp["neck"] = st["neck"]
		return sp
	var src: Dictionary = st.get(which, {})
	if src.is_empty():
		src = st.get("wind", {})
	var p = {"fL": src.get("fL", []), "fR": src.get("fR", []), "spine": src.get("spine", 0.0), "neck": src.get("neck", 0.0), "hips_yaw": src.get("hips_yaw", 0.0), "crouch": src.get("crouch", 0.0)}
	var arms = []
	for side in [["L", "Left"], ["R", "Right"]]:
		var a = src.get(side[0])
		if a == null:
			continue
		arms.append([side[1] + "UpperArm", a[0]])
		arms.append([side[1] + "LowerArm", a[1]])
		arms.append([side[1] + "Hand", a[2]])
	p["arms"] = arms
	return p


## İki pozu karıştırır (aynı kemikler yön olarak, parmaklar doğrusal)
func _blend(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var out = {}
	var amap = {}
	for e in a.get("arms", []):
		amap[e[0]] = e[1]
	var arms = []
	for e in b.get("arms", []):
		var to: Vector3 = e[1]
		if amap.has(e[0]):
			arms.append([e[0], (amap[e[0]] as Vector3).normalized().slerp(to.normalized(), k)])
		else:
			arms.append([e[0], to])
	out["arms"] = arms
	for side in ["fL", "fR"]:
		var fa: Array = a.get(side, []); var fb: Array = b.get(side, [])
		if fb.size() == 5 and fa.size() == 5:
			var r = []
			for i in 5:
				r.append(lerpf(fa[i], fb[i], k))
			out[side] = r
		else:
			out[side] = fb if fb.size() == 5 else fa
	for key in ["spine", "neck", "hips_yaw", "crouch"]:
		out[key] = lerpf(float(a.get(key, 0.0)), float(b.get(key, 0.0)), k)
	return out


# ------------------------------------------------------------------ olaylar
func _hand_pos(side: String) -> Vector3:
	var sk: Skeleton3D = model.skel
	var bi = sk.find_bone(side + "Hand")
	if bi < 0:
		return f.global_position + Vector3.UP * 1.3
	return sk.global_transform * sk.get_bone_global_pose(bi).origin


func _elem_color() -> Color:
	return {"katon": Color(1.0, 0.55, 0.15), "suiton": Color(0.3, 0.6, 1.0), "fuuton": Color(0.75, 1.0, 0.85), "doton": Color(0.75, 0.55, 0.3),
		"raiton": Color(0.75, 0.85, 1.0), "mokuton": Color(0.45, 0.8, 0.35), "hyoton": Color(0.75, 0.95, 1.0)}.get(String(j.get("element", "")), Color(0.45, 0.75, 1.0))


func _on_seal(idx: int) -> void:
	var sname: String = seals[idx]
	var info: Dictionary = SEALS.get(sname, {})
	Sfx.play("seal", f.global_position, 1.0 + idx * 0.05, 0.7 if is_player else 0.4)
	# mühür anında ellerde chakra kıvılcımı
	var hp = (_hand_pos("Left") + _hand_pos("Right")) * 0.5
	var ec = _elem_color()
	FX.burst(hp, {"amount": 8, "life": 0.25, "tex": FX.tex_spark, "size": 0.25, "vmin": 0.5, "vmax": 1.8, "gravity": Vector3.ZERO,
		"colors": [Color(1, 1, 1, 0.95), Color(ec.r, ec.g, ec.b, 0.0)]})
	# son mühür: rütbe ölçekli hazırlık (içe çöken halka + toplanan chakra)
	if idx == seals.size() - 1:
		VFX.gather(hp, ec, JutsuEngine.grand(f, j))
	# mühür adı oyuncu için HUD'da (Hud.show_seals) gösterilir; düşmanda başın üstünde küçük yazı
	if not is_player and f.global_position.distance_to(Game.player.global_position if Game.player else f.global_position) < 18.0:
		Combat.popup_text(f.global_position + Vector3.UP * 2.3, sname, Color(0.85, 0.92, 1.0, 0.8))


func _charge_fx(dt: float) -> void:
	_charge_fx_t -= dt
	if _charge_fx_t > 0.0:
		return
	_charge_fx_t = 0.06
	match style:
		"charge":
			var hp = _hand_pos("Right")
			var col = Color(0.8, 0.9, 1.0) if String(j.get("element", "")) == "raiton" else Color(0.45, 0.7, 1.0)
			FX.burst(hp, {"amount": 8, "life": 0.2, "tex": FX.tex_spark, "size": 0.25, "vmin": 1.5, "vmax": 4.0, "gravity": Vector3.ZERO,
				"colors": [Color(col.r, col.g, col.b, 1.0), Color(col.r, col.g, col.b, 0.0)]})
			if randf() < 0.3:
				Sfx.play("chidori" if String(j.get("element", "")) == "raiton" else "rasengan", hp, randf_range(0.9, 1.2), 0.25)
		"medical":
			for s in ["Left", "Right"]:
				FX.burst(_hand_pos(s), {"amount": 3, "life": 0.4, "tex": FX.tex_spark, "size": 0.2, "vmin": 0.2, "vmax": 0.6, "gravity": Vector3(0, 1, 0),
					"colors": [Color(0.5, 1.0, 0.6, 0.9), Color(0.3, 1.0, 0.5, 0.0)]})
		"power":
			FX.burst(f.global_position + Vector3.UP * 0.2, {"amount": 6, "life": 0.35, "tex": FX.tex_smoke, "add": false, "size": 0.6, "vmin": 1.0, "vmax": 3.0, "gravity": Vector3(0, 2, 0),
				"colors": [Color(0.8, 0.75, 0.65, 0.6), Color(0.8, 0.75, 0.65, 0.0)]})
		"breath":
			var mouth = f.global_position + Vector3.UP * 1.55 * (model.age_scale if model else 1.0)
			FX.burst(mouth, {"amount": 2, "life": 0.3, "tex": FX.tex_spark, "size": 0.15, "vmin": 0.2, "vmax": 0.6, "gravity": Vector3.ZERO,
				"colors": [_elem_color(), Color(_elem_color().r, _elem_color().g, _elem_color().b, 0.0)]})
		"sense":
			if randf() < 0.3:
				FX.ring(f.global_position + Vector3.UP * 1.6, Color(0.7, 0.6, 1.0), 0.6, 0.25, false)


func _on_release() -> void:
	var clip: String = st.get("clip", "idle")
	if clip != "idle":
		model.play(clip, 0.06, 1.4, true)
	match style:
		"ground":
			FX.impact(f.global_position, _elem_color(), 0.9)
			FX.ring(f.global_position + Vector3.UP * 0.1, _elem_color(), 3.5, 0.35)
			Sfx.play("earth", f.global_position, 1.2, 0.5)
		"summon":
			# çağırma mührü: yerde yayılan kara yazı halkası (duman jutsunun kendisinden gelir)
			FX.ring(f.global_position + Vector3.UP * 0.05, Color(0.1, 0.08, 0.06), 3.2, 0.6)
			FX.ring(f.global_position + Vector3.UP * 0.05, Color(0.1, 0.08, 0.06), 1.8, 0.45)
			FX.dust(f.global_position, 0.6)
			Sfx.play("poof", f.global_position, 0.9, 0.6)
		"spin", "clone":
			if not jid.contains("moku"):   # ahşap klon bedenden filizlenir, duman yok (ref)
				FX.smoke_puff(f.global_position + Vector3.UP, 0.9, 12)
		"power":   # güç açılışı: halka + kükreme (ayak dibinde duman topu yok — duman kuralı)
			FX.ring(f.global_position + Vector3.UP * 0.1, Color(1, 0.95, 0.8), 4.0, 0.4)
			Sfx.play("roar", f.global_position, 1.4, 0.35)
		"flicker":
			FX.smoke_puff(f.global_position + Vector3.UP, 0.5, 8)
		"charge", "palm", "two_palm", "rush":
			FX.speed_lines(f.global_position + Vector3.UP, f.face_dir() if f.has_method("face_dir") else -f.global_transform.basis.z)
