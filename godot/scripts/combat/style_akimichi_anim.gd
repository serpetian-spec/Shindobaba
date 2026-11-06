extends RefCounted
## Dövüş tarzı — Akimichi (Baika). Ref: refs/styles/akimichi_*.png (Chōji/Chōza: Bubun Baika dev yumruk, Chō Harite dev avuç).
## Ağır ve yavaş: kalçadan dönen büyük kurulumlar; vuruş anında yumruk/avuç GERÇEK kemikle devleşir (KeyedCombos.on_start/grow).
## 1 Baika Tsuki: sağ düz yumruk (yumruk 2.2x), 2 Tetsui: sol çekiç yumruk yukarıdan aşağı, 3 Hara Oshi: göbekle itiş,
## 4 Chō Harite: sağ avuç 3x devleşip yandan tokat, 5 Ryōken Otoshi: iki yumruk devleşip başın üstünden yere (şok dalgası),
## 6 Bubun Baika: kol + yumruk dev olur, uzak menzilli düz yumruk (fırlatır).

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")   # canlı bacaklar: bükük diz, ağırlık aktarımı, pivot

const R_GUARD := {"RightUpperArm": Vector3(-0.3, -0.75, 0.55), "RightLowerArm": Vector3(0.1, 0.7, 0.7)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.1, 0.7, 0.7)}
const R_CHAMBER := {"RightUpperArm": Vector3(-0.45, -0.6, -0.65), "RightLowerArm": Vector3(-0.1, 0.35, 0.93)}
const R_STRAIGHT := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}
const L_UP := {"LeftUpperArm": Vector3(0.3, 0.9, 0.1), "LeftLowerArm": Vector3(0.1, 0.9, -0.4)}
const L_DOWN := {"LeftUpperArm": Vector3(0.1, -0.35, 0.93), "LeftLowerArm": Vector3(0.0, -0.75, 0.66)}
const R_BACK := {"RightUpperArm": Vector3(-0.5, -0.7, -0.5), "RightLowerArm": Vector3(-0.3, -0.6, -0.7)}
const L_BACK := {"LeftUpperArm": Vector3(0.5, -0.7, -0.5), "LeftLowerArm": Vector3(0.3, -0.6, -0.7)}
const R_WIDE := {"RightUpperArm": Vector3(-0.95, 0.1, -0.25), "RightLowerArm": Vector3(-0.8, 0.2, 0.55)}     # tokat kurulumu: kol yana açık
const R_SLAP := {"RightUpperArm": Vector3(0.3, 0.05, 0.95), "RightLowerArm": Vector3(0.8, 0.1, 0.55)}       # avuç önden sola süpürür
const R_UP := {"RightUpperArm": Vector3(-0.3, 0.9, 0.1), "RightLowerArm": Vector3(-0.1, 0.9, -0.4)}
const R_DOWN := {"RightUpperArm": Vector3(-0.1, -0.35, 0.93), "RightLowerArm": Vector3(0.0, -0.75, 0.66)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.2, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = F.SHIFT
	var ST = F.STEPIN
	return [
		{"len": 0.65, "hit": 0.32, "keys": [
			_t(0.0, 0.5, 0, 8, R_GUARD, L_GUARD, W),
			_t(0.16, 0.56, -34, 2, R_CHAMBER, L_GUARD, BK),
			_t(0.26, 0.56, -36, 2, R_CHAMBER, L_GUARD, BK),
			_t(0.32, 0.5, 24, 20, R_STRAIGHT, L_GUARD, L),
			_t(0.46, 0.5, 20, 18, R_STRAIGHT, L_GUARD, L),
			_t(0.65, 0.5, 0, 8, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.7, "hit": 0.36, "keys": [
			_t(0.0, 0.5, 0, 8, R_GUARD, L_GUARD, W),
			_t(0.18, 0.4, 18, -12, R_GUARD, L_UP, BK),
			_t(0.28, 0.42, 20, -14, R_GUARD, L_UP, BK),
			_t(0.36, 0.7, -10, 30, R_GUARD, L_DOWN, LL),
			_t(0.5, 0.68, -8, 28, R_GUARD, L_DOWN, LL),
			_t(0.7, 0.5, 0, 8, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.6, "hit": 0.3, "keys": [
			_t(0.0, 0.5, 0, 8, R_GUARD, L_GUARD, W),
			_t(0.16, 0.56, 0, -18, R_BACK, L_BACK, BK),
			_t(0.3, 0.5, 0, -6, R_BACK, L_BACK, L),   # göbek öne: gövde dik, kollar geride
			_t(0.42, 0.5, 0, -4, R_BACK, L_BACK, L),
			_t(0.6, 0.5, 0, 8, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.85, "hit": 0.46, "keys": [
			_t(0.0, 0.5, 0, 8, R_GUARD, L_GUARD, W),
			_t(0.2, 0.56, -40, 4, R_WIDE, L_GUARD, BK),
			_t(0.36, 0.58, -44, 2, R_WIDE, L_GUARD, BK),
			_t(0.46, 0.52, 34, 18, R_SLAP, L_GUARD, L),
			_t(0.62, 0.5, 40, 16, R_SLAP, L_GUARD, L),
			_t(0.85, 0.5, 0, 8, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.9, "hit": 0.5, "keys": [
			_t(0.0, 0.5, 0, 8, R_GUARD, L_GUARD, W),
			_t(0.22, 0.42, 0, -16, R_UP, L_UP, W),
			_t(0.38, 0.4, 0, -18, R_UP, L_UP, W),
			_t(0.5, 0.82, 0, 40, R_DOWN, L_DOWN, L),
			_t(0.66, 0.8, 0, 38, R_DOWN, L_DOWN, L),
			_t(0.9, 0.5, 0, 8, R_GUARD, L_GUARD, W),
		]},
		{"len": 1.0, "hit": 0.55, "keys": [
			_t(0.0, 0.5, 0, 8, R_GUARD, L_GUARD, W),
			_t(0.22, 0.6, -46, 0, R_CHAMBER, L_GUARD, BK),
			_t(0.42, 0.62, -50, -2, R_CHAMBER, L_GUARD, BK),   # uzun kurulum: kol devleşirken geride
			_t(0.55, 0.52, 30, 22, R_STRAIGHT, L_BACK, L),
			_t(0.75, 0.5, 26, 20, R_STRAIGHT, L_BACK, L),
			_t(1.0, 0.5, 0, 8, R_GUARD, L_GUARD, W),
		]},
	]
