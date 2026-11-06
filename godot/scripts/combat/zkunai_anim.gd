extends RefCounted
## Zincirli kunai (ref zincirlikunai.png): elde bir kunai, uzun fizikli zincirin ucunda ikinci kunai. ORTA-UZUN MENZİL:
## eldekiyle yakın kesik, zincirli kunai fırlatılıp hedefe saplanır/dolanır, baş üstünde döndürülür (KeyedCombos._kg_weight).
## 1 yakın kesik, 2 zincirli kunai fırlatışı (saplanıp sersemletir), 3 baş üstü döndürme, 4 çift kesik, 5 dolayıp çekme, 6 dolayıp çekip saplama.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.3, -0.75, 0.55), "RightLowerArm": Vector3(0.2, 0.0, 0.98)}
const R_BACK := {"RightUpperArm": Vector3(-0.6, 0.35, -0.7), "RightLowerArm": Vector3(-0.2, 0.6, -0.75)}
const R_REACH := {"RightUpperArm": Vector3(-0.05, 0.1, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}
const R_SLASH := {"RightUpperArm": Vector3(0.35, -0.25, 0.9), "RightLowerArm": Vector3(0.9, -0.1, 0.4)}
const R_OVER := {"RightUpperArm": Vector3(-0.2, 0.95, 0.1), "RightLowerArm": Vector3(0.1, 0.95, 0.25)}
const R_PULL := {"RightUpperArm": Vector3(-0.35, -0.75, -0.55), "RightLowerArm": Vector3(-0.05, 0.1, 1)}
const R_HIGH := {"RightUpperArm": Vector3(-0.5, 0.65, -0.55), "RightLowerArm": Vector3(-0.1, 0.9, 0.4)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.2, 0.3, 0.93)}
const L_POINT := {"LeftUpperArm": Vector3(0.15, 0.05, 1), "LeftLowerArm": Vector3(0.05, 0.0, 1)}
const L_HAUL := {"LeftUpperArm": Vector3(0.35, -0.7, -0.6), "LeftLowerArm": Vector3(-0.1, 0.0, 1)}
const L_WIDE := {"LeftUpperArm": Vector3(0.95, -0.2, 0.2), "LeftLowerArm": Vector3(0.85, -0.2, 0.45)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.0, 0.3, 0.95)
	return [
		# 1 Kiri: kunai sağ omuzdan çapraz aşağı kesik
		{"len": 0.6, "hit": 0.26, "keys": [
			_t(0.0, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.14, 0.36, -22, -6, Vector3(-0.3, 0.8, 0.5), R_HIGH, L_POINT, BK),
			_t(0.26, 0.44, 20, 14, Vector3(0.6, -0.5, 0.6), R_SLASH, L_GUARD, ST),
			_t(0.6, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 2 Kusari Nage: kol geri kurulur -> zincirli kunai düz fırlatılır, hedefe saplanıp zincir gergin (sersemletir) -> geri sarılır
		{"len": 1.2, "hit": 0.34, "keys": [
			_t(0.0, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.18, 0.38, -28, -10, Vector3(0, 0.3, -0.95), R_BACK, L_POINT, BK),
			_t(0.28, 0.4, -32, -12, Vector3(0, 0.3, -0.95), R_BACK, L_POINT, BK),
			_t(0.34, 0.44, 16, 18, Vector3(0, 0.1, 1), R_REACH, L_POINT, L),
			_t(0.7, 0.42, 4, -6, Vector3(0, 0.1, 1), R_PULL, L_HAUL, BK),
			_t(1.2, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 3 Kusari Senpū: zincirli kunai baş üstünde döndürülür, sonra yana açılıp çevreyi biçer
		{"len": 1.25, "hit": 0.22, "keys": [
			_t(0.0, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.18, 0.36, -20, -6, Vector3(0, 0.95, 0.2), R_OVER, L_WIDE, W),
			_t(0.4, 0.38, 24, -4, Vector3(0, 0.95, 0.2), R_OVER, L_WIDE, CR),
			_t(0.66, 0.42, -28, 4, Vector3(0, 0.95, 0.2), R_OVER, L_WIDE, W),
			_t(0.9, 0.42, 26, 4, Vector3(0, 0.95, 0.2), R_OVER, L_WIDE, CR),
			_t(1.25, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 4 Ni Kiri: eldeki kunaiyle ileri saplama + ters kesik
		{"len": 0.75, "hit": 0.22, "extra_hits": [0.44], "extra_radius": 1.3, "keys": [
			_t(0.0, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.12, 0.4, -10, -4, Vector3(0, 0.1, 1), R_PULL, L_POINT, BK),
			_t(0.22, 0.46, 12, 16, Vector3(0, 0.1, 1), R_REACH, L_GUARD, L),
			_t(0.34, 0.42, -24, 8, Vector3(-0.6, 0.2, 0.7), R_BACK, L_GUARD, ST),
			_t(0.44, 0.44, 22, 12, Vector3(0.7, -0.3, 0.6), R_SLASH, L_GUARD, L),
			_t(0.75, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 5 Maki Hiki: zincir fırlatılıp rakibe dolanır -> sol el zinciri yakalar, iki kolla kalçaya çeker (rakip sürüklenir)
		{"len": 1.15, "hit": 0.3, "keys": [
			_t(0.0, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.16, 0.4, -30, -12, Vector3(-0.3, 0.75, -0.6), R_HIGH, L_POINT, BK),
			_t(0.3, 0.46, 16, 20, Vector3(0, 0.3, 0.95), R_REACH, L_POINT, L),
			_t(0.6, 0.46, -10, -14, Vector3(0, 0.3, 0.95), R_PULL, L_HAUL, BK),
			_t(0.86, 0.44, -14, -16, Vector3(0, 0.3, 0.95), R_PULL, L_HAUL, BK),
			_t(1.15, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 6 Kusari Shitome (bitiriş): zincir rakibe dolanır ve çekilir (on_start) -> gelen rakibe eldeki kunaiyle derin saplama
		{"len": 1.25, "hit": 0.74, "keys": [
			_t(0.0, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.14, 0.4, 10, 10, Vector3(0, 0.6, 0.8), R_REACH, L_POINT, L),
			_t(0.32, 0.44, -10, -14, Vector3(0, 0.6, 0.78), R_PULL, L_HAUL, BK),
			_t(0.56, 0.44, -14, -16, Vector3(0, 0.6, 0.78), R_PULL, L_HAUL, BK),
			_t(0.66, 0.42, -20, -8, Vector3(0, 0.1, 1), R_PULL, L_HAUL, ST),
			_t(0.74, 0.54, 16, 26, Vector3(0, 0.1, 1), R_REACH, L_HAUL, L),
			_t(0.95, 0.5, 12, 20, Vector3(0, 0.1, 1), R_REACH, L_HAUL, L),
			_t(1.25, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
	]
