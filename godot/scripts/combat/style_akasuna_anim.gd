extends RefCounted
## Yol tarzı — Akasuna (Sasori, kukla ustası). ORTA. Görseller oyunun gerçek kukla sistemi: savaş kuklası (ClanConstruct
## "puppet" modeli, PathJutsu._puppet_at) ve parmaklardan uzanan mavi chakra iplikleri. Kanon: kuklalar ahşap, eklemli, içleri
## zehirli silah dolu; kuklacı uzakta durur, parmak hareketleriyle yönetir.
## 1 kukla atılıp keser, 2 kuklanın ağzından zehirli iğneler, 3 bıçaklı kollarla dönen kukla, 4 chakra iplikleri rakibi çeker,
## 5 mor zehir gazı, 6 Akahigi: hedefin çevresinde dört kukla birden saldırır (bitiriş).

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")
const R_STRING := {"RightUpperArm": Vector3(-0.3, -0.2, 0.93), "RightLowerArm": Vector3(0.0, 0.55, 0.83)}   # parmaklar havada (iplik çeker)
const L_STRING := {"LeftUpperArm": Vector3(0.3, -0.2, 0.93), "LeftLowerArm": Vector3(0.0, 0.55, 0.83)}
const R_PULL := {"RightUpperArm": Vector3(-0.5, -0.1, -0.5), "RightLowerArm": Vector3(-0.1, 0.6, 0.4)}       # ipliği geri çeker
const L_PULL := {"LeftUpperArm": Vector3(0.5, -0.1, -0.5), "LeftLowerArm": Vector3(0.1, 0.6, 0.4)}


static func steps() -> Array:
	return [
		C.step(0.55, 0.26, R_STRING, C.L_GUARD, C.R_REACH, C.L_GUARD, F.FIGHT, F.PIVOT, -14.0, 12.0, 0.36, 8.0),     # 1 kukla atılır
		C.step(0.55, 0.26, C.R_GUARD, L_STRING, C.R_GUARD, C.L_REACH, F.FIGHT, F.PIVOT_L, 14.0, -12.0, 0.36, 8.0),   # 2 zehirli iğne
		C.step(0.7, 0.32, R_STRING, L_STRING, C.R_SPREAD, C.L_SPREAD, F.FIGHT, F.FIGHT, 0.0, 0.0, 0.38, 0.0),        # 3 dönen kukla
		C.step(0.7, 0.34, R_STRING, L_STRING, R_PULL, L_PULL, F.FIGHT, F.SHIFT, 0.0, 0.0, 0.42, -14.0),              # 4 iplikle çek
		C.step(0.7, 0.32, R_STRING, L_STRING, C.R_PALM, C.L_PALM, F.FIGHT, F.STEPIN, 0.0, 0.0, 0.38, 10.0),          # 5 zehir gazı
		{"len": 1.15, "hit": 0.62, "keys": [   # 6 Akahigi: on parmak açılır, uzun bekleme -> eller öne savrulur
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.24, 0.4, 0, -8, C.R_SPREAD, C.L_SPREAD, F.FIGHT),
			C.t(0.52, 0.42, 0, -10, R_STRING, L_STRING, F.FIGHT),
			C.t(0.64, 0.44, 0, 14, C.R_REACH, C.L_REACH, F.STEPIN),
			C.t(0.9, 0.42, 0, 12, C.R_REACH, C.L_REACH, F.STEPIN),
			C.t(1.15, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
