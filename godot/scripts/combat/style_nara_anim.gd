extends RefCounted
## Dövüş tarzı — Nara (Kagemane-ryū, gölge). ORTA MENZİL, KONTROL. Gölge görünüşü oyunun gerçek gölge şeridi
## (Jutsu._shadow_line: yere yapışık, kenarsız, parlamasız koyu şerit, hedefin altında gölge göleti) ve Kage Nui iğneleri.
## Kanon: Nara gölgesini uzatıp rakibe bağlar (Kagemane), gölgeden eller tırmanıp boğar (Kage Kubi Shibari), gölge iğneleriyle
## delip çiviler (Kage Nui); mühür (Ne mühürü, iki el) gölgeyi besler. Yakında zayıf: rakibe yanaşmaz.
## 1 gölge kırbacı (sağ el işaret eder, gölge uzanıp hedefin altından şaplar), 2 aynısı sol, 3 Kagemane: Ne mühürü, gölge bağlar
## (kısa), 4 Kage Nui: avuç yere, yerden gölge iğneleri fırlayıp deler, 5 Kage Kubi Shibari: gölge eller tırmanıp boğar
## (süreli hasar), 6 Kagemane + Kage Nui (bitiriş): bağla, iki el açılınca hedefin çevresinden iğne yağmuru.

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const R_GUARD := {"RightUpperArm": Vector3(-0.35, -0.85, 0.35), "RightLowerArm": Vector3(0.1, 0.3, 0.95)}
const L_GUARD := {"LeftUpperArm": Vector3(0.35, -0.85, 0.35), "LeftLowerArm": Vector3(-0.1, 0.3, 0.95)}
const R_POINT_LOW := {"RightUpperArm": Vector3(-0.15, -0.5, 0.85), "RightLowerArm": Vector3(0.0, -0.45, 0.89)}   # aşağı-öne işaret (gölgeyi yönlendirir)
const L_POINT_LOW := {"LeftUpperArm": Vector3(0.15, -0.5, 0.85), "LeftLowerArm": Vector3(0.0, -0.45, 0.89)}
const R_SEAL := {"RightUpperArm": Vector3(-0.25, -0.7, 0.67), "RightLowerArm": Vector3(0.75, 0.3, 0.6)}     # Ne mühürü: göğüs önünde
const L_SEAL := {"LeftUpperArm": Vector3(0.25, -0.7, 0.67), "LeftLowerArm": Vector3(-0.75, 0.3, 0.6)}
const R_GROUND := {"RightUpperArm": Vector3(-0.1, -0.75, 0.65), "RightLowerArm": Vector3(0.0, -0.95, 0.3)}
const L_GROUND := {"LeftUpperArm": Vector3(0.1, -0.75, 0.65), "LeftLowerArm": Vector3(0.0, -0.95, 0.3)}
const R_CLAW := {"RightUpperArm": Vector3(-0.2, 0.1, 0.97), "RightLowerArm": Vector3(0.1, 0.35, 0.93)}       # pençe gibi açık el öne (boğma)
const L_CLAW := {"LeftUpperArm": Vector3(0.2, 0.1, 0.97), "LeftLowerArm": Vector3(-0.1, 0.35, 0.93)}
const R_SPREAD := {"RightUpperArm": Vector3(-0.95, 0.15, 0.25), "RightLowerArm": Vector3(-0.85, 0.3, 0.4)}
const L_SPREAD := {"LeftUpperArm": Vector3(0.95, 0.15, 0.25), "LeftLowerArm": Vector3(0.85, 0.3, 0.4)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var BK = F.SHIFT
	var ST = F.STEPIN
	var PV = F.PIVOT
	var PL = F.PIVOT_L
	return [
		{"len": 0.55, "hit": 0.26, "keys": [   # 1 gölge kırbacı (sağ)
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.12, 0.42, -16, 0, R_GUARD, L_GUARD, BK),
			_t(0.26, 0.42, 12, 12, R_POINT_LOW, L_GUARD, PV),
			_t(0.4, 0.4, 10, 10, R_POINT_LOW, L_GUARD, PV),
			_t(0.55, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.55, "hit": 0.26, "keys": [   # 2 gölge kırbacı (sol)
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.12, 0.42, 16, 0, R_GUARD, L_GUARD, BK),
			_t(0.26, 0.42, -12, 12, R_GUARD, L_POINT_LOW, PL),
			_t(0.4, 0.4, -10, 10, R_GUARD, L_POINT_LOW, PL),
			_t(0.55, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.36, "keys": [   # 3 Kagemane: Ne mühürü (alçak, sakin)
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.18, 0.48, 0, 8, R_SEAL, L_SEAL, F.LOW),
			_t(0.36, 0.5, 0, 10, R_SEAL, L_SEAL, F.LOW),
			_t(0.56, 0.48, 0, 8, R_SEAL, L_SEAL, F.LOW),
			_t(0.75, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.36, "keys": [   # 4 Kage Nui: avuç yere
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.16, 0.62, 0, 26, R_GROUND, L_GUARD, F.LOW),
			_t(0.36, 0.64, 0, 28, R_GROUND, L_GUARD, F.LOW),
			_t(0.56, 0.58, 0, 22, R_GROUND, L_GUARD, F.LOW),
			_t(0.75, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.85, "hit": 0.4, "keys": [   # 5 Kage Kubi Shibari: pençe gibi eller öne, yavaşça sıkar
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.16, 0.42, 0, 6, R_SEAL, L_SEAL, BK),
			_t(0.4, 0.44, 0, 14, R_CLAW, L_CLAW, ST),
			_t(0.66, 0.46, 0, 16, R_CLAW, L_CLAW, ST),
			_t(0.85, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 1.15, "hit": 0.66, "keys": [   # 6 Kagemane + Kage Nui: mühür (uzun) -> kollar açılır, iğne yağmuru
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.22, 0.5, 0, 8, R_SEAL, L_SEAL, F.LOW),
			_t(0.56, 0.52, 0, 10, R_SEAL, L_SEAL, F.LOW),
			_t(0.66, 0.42, 0, -6, R_SPREAD, L_SPREAD, W),
			_t(0.95, 0.42, 0, -6, R_SPREAD, L_SPREAD, W),
			_t(1.15, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
	]
