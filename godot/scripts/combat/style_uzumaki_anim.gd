extends RefCounted
## Dövüş tarzı — Uzumaki (Kongō Fūsa, Kushina). ORTA MENZİL. Ref: refs/styles/uzumaki_*.png + text/uzumaki.txt (gövdeden çıkan
## chakra zincirleri; sarıp bağlar, chakrayı mühürler; uzun zincirler yer altından dağılır). Zincirleri eller yönlendirir.
## 1 Kusari Muchi: sağ el savrulur — sırttan zincir kırbaç gibi iner, 2 sol el — ikinci zincir, 3 Kusari Yari: iki el ileri, zincir
## mızrak gibi saplanır (uzun menzil), 4 Kongō Shibari: kollar açık — zincir hedefi sarar (bağ + chakra mühürü),
## 5 Rensa Senpū: dönerken zincirler çevreyi süpürür, 6 Fūsa Otoshi: zincirle sarılan rakip havaya kaldırılıp yere çarpılır.

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const R_IDLE := {"RightUpperArm": Vector3(-0.3, -0.8, 0.5), "RightLowerArm": Vector3(0.1, 0.4, 0.91)}
const L_IDLE := {"LeftUpperArm": Vector3(0.3, -0.8, 0.5), "LeftLowerArm": Vector3(-0.1, 0.4, 0.91)}
const R_HIGH := {"RightUpperArm": Vector3(-0.5, 0.8, -0.2), "RightLowerArm": Vector3(-0.2, 0.9, 0.35)}
const R_DOWN := {"RightUpperArm": Vector3(0.1, -0.3, 0.95), "RightLowerArm": Vector3(0.3, -0.5, 0.8)}
const L_HIGH := {"LeftUpperArm": Vector3(0.5, 0.8, -0.2), "LeftLowerArm": Vector3(0.2, 0.9, 0.35)}
const L_DOWN := {"LeftUpperArm": Vector3(-0.1, -0.3, 0.95), "LeftLowerArm": Vector3(-0.3, -0.5, 0.8)}
const R_FWD := {"RightUpperArm": Vector3(-0.05, 0.1, 1), "RightLowerArm": Vector3(0.05, 0.12, 1)}
const L_FWD := {"LeftUpperArm": Vector3(0.05, 0.1, 1), "LeftLowerArm": Vector3(-0.05, 0.12, 1)}
const R_OPEN := {"RightUpperArm": Vector3(-0.95, 0.2, 0.25), "RightLowerArm": Vector3(-0.9, 0.25, 0.35)}
const L_OPEN := {"LeftUpperArm": Vector3(0.95, 0.2, 0.25), "LeftLowerArm": Vector3(0.9, 0.25, 0.35)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var BK = F.SHIFT
	var PV = F.PIVOT
	var PL = F.PIVOT_L
	return [
		{"len": 0.5, "hit": 0.22, "keys": [
			_t(0.0, 0.36, 0, 6, R_IDLE, L_IDLE, W),
			_t(0.1, 0.4, -20, -6, R_HIGH, L_IDLE, BK),
			_t(0.22, 0.42, 18, 14, R_DOWN, L_IDLE, PV),
			_t(0.32, 0.4, 14, 12, R_DOWN, L_IDLE, PV),
			_t(0.5, 0.36, 0, 6, R_IDLE, L_IDLE, W),
		]},
		{"len": 0.5, "hit": 0.22, "keys": [
			_t(0.0, 0.36, 0, 6, R_IDLE, L_IDLE, W),
			_t(0.1, 0.4, 20, -6, R_IDLE, L_HIGH, BK),
			_t(0.22, 0.42, -18, 14, R_IDLE, L_DOWN, PL),
			_t(0.32, 0.4, -14, 12, R_IDLE, L_DOWN, PL),
			_t(0.5, 0.36, 0, 6, R_IDLE, L_IDLE, W),
		]},
		{"len": 0.6, "hit": 0.28, "keys": [
			_t(0.0, 0.36, 0, 6, R_IDLE, L_IDLE, W),
			_t(0.14, 0.44, 0, -4, R_IDLE, L_IDLE, BK),
			_t(0.28, 0.42, 0, 14, R_FWD, L_FWD, F.STEPIN),
			_t(0.4, 0.4, 0, 12, R_FWD, L_FWD, F.STEPIN),
			_t(0.6, 0.36, 0, 6, R_IDLE, L_IDLE, W),
		]},
		{"len": 0.7, "hit": 0.32, "keys": [
			_t(0.0, 0.36, 0, 6, R_IDLE, L_IDLE, W),
			_t(0.16, 0.4, 0, 4, R_FWD, L_FWD, W),
			_t(0.32, 0.36, 0, -6, R_OPEN, L_OPEN, W),   # kollar açılır: zincir sarar
			_t(0.5, 0.36, 0, -6, R_OPEN, L_OPEN, W),
			_t(0.7, 0.36, 0, 6, R_IDLE, L_IDLE, W),
		]},
		{"len": 0.75, "hit": 0.22, "extra_hits": [0.4, 0.56], "extra_radius": 3.2, "keys": [
			_t(0.0, 0.36, 0, 6, R_IDLE, L_IDLE, W),
			_t(0.12, 0.4, 90, 4, R_OPEN, L_OPEN, W),
			_t(0.28, 0.4, -170, 4, R_OPEN, L_OPEN, W),
			_t(0.44, 0.4, 100, 4, R_OPEN, L_OPEN, W),
			_t(0.6, 0.4, -40, 4, R_OPEN, L_OPEN, W),
			_t(0.75, 0.36, 0, 6, R_IDLE, L_IDLE, W),
		]},
		{"len": 0.95, "hit": 0.56, "keys": [
			_t(0.0, 0.36, 0, 6, R_IDLE, L_IDLE, W),
			_t(0.2, 0.4, 0, -10, R_HIGH, L_HIGH, BK),
			_t(0.42, 0.36, 0, -14, R_HIGH, L_HIGH, BK),   # zincirle havaya kaldırır
			_t(0.56, 0.6, 0, 26, R_DOWN, L_DOWN, F.STEPIN),   # yere çarpar
			_t(0.72, 0.58, 0, 24, R_DOWN, L_DOWN, F.STEPIN),
			_t(0.95, 0.36, 0, 6, R_IDLE, L_IDLE, W),
		]},
	]
