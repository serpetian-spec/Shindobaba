extends RefCounted
## Dövüş tarzı — Aburame (Kikaichū). UZAK MENZİL. Ref: refs/styles/aburame_*.png (Shino: kollar/yenlerden fışkıran böcek sürüsü,
## böcek küresi, böcek klonu). Yakına girmez: kollarını savurdukça yenlerden böcek sürüsü hedefe uçar, isabette chakra emer.
## 1 Migi Mushi: sağ kol öne savrulur (sürü), 2 Hidari Mushi: sol kol, 3 Sōchū: iki kol ileri itilir (iki sürü),
## 4 Mushi Bashira: kollar yukarı — hedefin altından böcek sütunu, 5 Mushi Dama: kollar daire çizer, yavaş büyük böcek küresi,
## 6 Kikaichū Kyōshū: kollar iki yana açılır — dev sürü hedefi yutar, çok chakra emer.

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")   # canlı bacaklar: bükük diz, ağırlık aktarımı, pivot

const R_IDLE := {"RightUpperArm": Vector3(-0.2, -0.95, 0.15), "RightLowerArm": Vector3(0.1, -0.5, 0.86)}   # eller cepte gibi önde aşağı
const L_IDLE := {"LeftUpperArm": Vector3(0.2, -0.95, 0.15), "LeftLowerArm": Vector3(-0.1, -0.5, 0.86)}
const R_BACK := {"RightUpperArm": Vector3(-0.7, -0.4, -0.6), "RightLowerArm": Vector3(-0.5, -0.2, -0.85)}
const L_BACK := {"LeftUpperArm": Vector3(0.7, -0.4, -0.6), "LeftLowerArm": Vector3(0.5, -0.2, -0.85)}
const R_THROW := {"RightUpperArm": Vector3(-0.15, 0.05, 1), "RightLowerArm": Vector3(0.05, 0.0, 1)}     # yen öne savrulmuş
const L_THROW := {"LeftUpperArm": Vector3(0.15, 0.05, 1), "LeftLowerArm": Vector3(-0.05, 0.0, 1)}
const R_UP := {"RightUpperArm": Vector3(-0.3, 0.95, 0.1), "RightLowerArm": Vector3(-0.1, 0.95, 0.2)}
const L_UP := {"LeftUpperArm": Vector3(0.3, 0.95, 0.1), "LeftLowerArm": Vector3(0.1, 0.95, 0.2)}
const R_SIDE := {"RightUpperArm": Vector3(-1, 0.1, 0.1), "RightLowerArm": Vector3(-0.95, 0.15, 0.25)}
const L_SIDE := {"LeftUpperArm": Vector3(1, 0.1, 0.1), "LeftLowerArm": Vector3(0.95, 0.15, 0.25)}
const R_CIRC := {"RightUpperArm": Vector3(-0.5, 0.3, 0.8), "RightLowerArm": Vector3(0.4, 0.6, 0.7)}
const L_CIRC := {"LeftUpperArm": Vector3(0.5, -0.3, 0.8), "LeftLowerArm": Vector3(-0.4, -0.5, 0.75)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = F.SHIFT
	return [
		{"len": 0.5, "hit": 0.2, "keys": [
			_t(0.0, 0.3, 0, 4, R_IDLE, L_IDLE, W),
			_t(0.1, 0.34, -28, 2, R_BACK, L_IDLE, BK),
			_t(0.2, 0.36, 20, 10, R_THROW, L_IDLE, L),
			_t(0.32, 0.34, 16, 8, R_THROW, L_IDLE, L),
			_t(0.5, 0.3, 0, 4, R_IDLE, L_IDLE, W),
		]},
		{"len": 0.5, "hit": 0.2, "keys": [
			_t(0.0, 0.3, 0, 4, R_IDLE, L_IDLE, W),
			_t(0.1, 0.34, 28, 2, R_IDLE, L_BACK, BK),
			_t(0.2, 0.36, -20, 10, R_IDLE, L_THROW, LL),
			_t(0.32, 0.34, -16, 8, R_IDLE, L_THROW, LL),
			_t(0.5, 0.3, 0, 4, R_IDLE, L_IDLE, W),
		]},
		{"len": 0.6, "hit": 0.26, "keys": [
			_t(0.0, 0.3, 0, 4, R_IDLE, L_IDLE, W),
			_t(0.14, 0.4, 0, -4, R_BACK, L_BACK, BK),
			_t(0.26, 0.38, 0, 12, R_THROW, L_THROW, L),
			_t(0.4, 0.36, 0, 10, R_THROW, L_THROW, L),
			_t(0.6, 0.3, 0, 4, R_IDLE, L_IDLE, W),
		]},
		{"len": 0.7, "hit": 0.32, "keys": [
			_t(0.0, 0.3, 0, 4, R_IDLE, L_IDLE, W),
			_t(0.16, 0.5, 0, 14, R_IDLE, L_IDLE, W),
			_t(0.32, 0.2, 0, -12, R_UP, L_UP, W),
			_t(0.48, 0.2, 0, -12, R_UP, L_UP, W),
			_t(0.7, 0.3, 0, 4, R_IDLE, L_IDLE, W),
		]},
		{"len": 0.8, "hit": 0.42, "keys": [
			_t(0.0, 0.3, 0, 4, R_IDLE, L_IDLE, W),
			_t(0.14, 0.34, -10, 6, R_CIRC, L_CIRC, W),
			_t(0.28, 0.34, 10, 6, L_CIRC.duplicate() if false else {"RightUpperArm": Vector3(-0.5, -0.3, 0.8), "RightLowerArm": Vector3(0.4, -0.5, 0.75)}, {"LeftUpperArm": Vector3(0.5, 0.3, 0.8), "LeftLowerArm": Vector3(-0.4, 0.6, 0.7)}, W),
			_t(0.42, 0.36, 0, 12, R_THROW, L_THROW, L),
			_t(0.56, 0.34, 0, 10, R_THROW, L_THROW, L),
			_t(0.8, 0.3, 0, 4, R_IDLE, L_IDLE, W),
		]},
		{"len": 1.0, "hit": 0.5, "keys": [
			_t(0.0, 0.3, 0, 4, R_IDLE, L_IDLE, W),
			_t(0.2, 0.5, 0, 18, R_BACK, L_BACK, W),
			_t(0.38, 0.5, 0, 20, R_BACK, L_BACK, W),   # sürü bedenin her yerinden toplanır
			_t(0.5, 0.25, 0, -10, R_SIDE, L_SIDE, W),
			_t(0.75, 0.25, 0, -10, R_SIDE, L_SIDE, W),
			_t(1.0, 0.3, 0, 4, R_IDLE, L_IDLE, W),
		]},
	]
