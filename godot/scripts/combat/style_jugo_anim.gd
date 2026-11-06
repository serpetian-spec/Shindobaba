extends RefCounted
## Dövüş tarzı — Jūgo (Senninka, kısmi dönüşüm). YAKIN, AĞIR. Ref: refs/styles/jugo_*.png (Jūgo: kol taş-ten dev balyoz olur,
## dirsekten buhar jeti fışkırıp yumruğu ivmelendirir, dikenli kol).
## Vuruş kolu gerçek kemikle kalınlaşır (bulk) ve el devleşir; jet adımlarında dirsekten beyaz buhar fışkırır.
## 1 Tetsui: sağ dev kroşe, 2 Sa-tetsui: sol dev kroşe, 3 Funsha: dirsekten jetle ileri atılan yumruk (uzun atılış),
## 4 Ryōtsui: iki balyoz kolla başın üstünden yere (şok), 5 Hari-ude: kol dikenlenip ileri saplanır (menzil),
## 6 Ten'yō Funsha: jetle aparkat — rakip havaya uçar.

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")   # canlı bacaklar: bükük diz, ağırlık aktarımı, pivot

const R_GUARD := {"RightUpperArm": Vector3(-0.35, -0.8, 0.45), "RightLowerArm": Vector3(0.0, 0.4, 0.92)}
const L_GUARD := {"LeftUpperArm": Vector3(0.35, -0.8, 0.45), "LeftLowerArm": Vector3(0.0, 0.4, 0.92)}
const R_HOOK0 := {"RightUpperArm": Vector3(-0.95, 0.05, -0.2), "RightLowerArm": Vector3(-0.4, 0.1, 0.9)}
const R_HOOK1 := {"RightUpperArm": Vector3(0.15, 0.05, 0.99), "RightLowerArm": Vector3(0.9, 0.05, 0.4)}
const L_HOOK0 := {"LeftUpperArm": Vector3(0.95, 0.05, -0.2), "LeftLowerArm": Vector3(0.4, 0.1, 0.9)}
const L_HOOK1 := {"LeftUpperArm": Vector3(-0.15, 0.05, 0.99), "LeftLowerArm": Vector3(-0.9, 0.05, 0.4)}
const R_CHAMBER := {"RightUpperArm": Vector3(-0.45, -0.6, -0.65), "RightLowerArm": Vector3(-0.1, 0.35, 0.93)}
const R_PUNCH := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}
const R_UP := {"RightUpperArm": Vector3(-0.3, 0.9, 0.1), "RightLowerArm": Vector3(-0.1, 0.9, -0.4)}
const L_UP := {"LeftUpperArm": Vector3(0.3, 0.9, 0.1), "LeftLowerArm": Vector3(0.1, 0.9, -0.4)}
const R_DOWN := {"RightUpperArm": Vector3(-0.1, -0.35, 0.93), "RightLowerArm": Vector3(0.0, -0.75, 0.66)}
const L_DOWN := {"LeftUpperArm": Vector3(0.1, -0.35, 0.93), "LeftLowerArm": Vector3(0.0, -0.75, 0.66)}
const R_UPP0 := {"RightUpperArm": Vector3(-0.3, -0.9, 0.2), "RightLowerArm": Vector3(0.0, -0.2, 0.98)}
const R_UPP1 := {"RightUpperArm": Vector3(-0.1, 0.4, 0.92), "RightLowerArm": Vector3(0.0, 0.98, 0.2)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.3, lean * 1.2, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = F.SHIFT
	return [
		{"len": 0.6, "hit": 0.3, "keys": [
			_t(0.0, 0.55, 0, 14, R_GUARD, L_GUARD, W),
			_t(0.16, 0.6, -34, 6, R_HOOK0, L_GUARD, BK),
			_t(0.3, 0.6, 30, 22, R_HOOK1, L_GUARD, L),
			_t(0.42, 0.58, 34, 20, R_HOOK1, L_GUARD, L),
			_t(0.6, 0.55, 0, 14, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.6, "hit": 0.3, "keys": [
			_t(0.0, 0.55, 0, 14, R_GUARD, L_GUARD, W),
			_t(0.16, 0.6, 34, 6, R_GUARD, L_HOOK0, BK),
			_t(0.3, 0.6, -30, 22, R_GUARD, L_HOOK1, LL),
			_t(0.42, 0.58, -34, 20, R_GUARD, L_HOOK1, LL),
			_t(0.6, 0.55, 0, 14, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.7, "hit": 0.34, "keys": [
			_t(0.0, 0.55, 0, 14, R_GUARD, L_GUARD, W),
			_t(0.18, 0.66, -30, 10, R_CHAMBER, L_GUARD, BK),
			_t(0.34, 0.6, 20, 30, R_PUNCH, L_GUARD, L),
			_t(0.5, 0.58, 18, 28, R_PUNCH, L_GUARD, L),
			_t(0.7, 0.55, 0, 14, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.85, "hit": 0.46, "keys": [
			_t(0.0, 0.55, 0, 14, R_GUARD, L_GUARD, W),
			_t(0.22, 0.4, 0, -14, R_UP, L_UP, W),
			_t(0.36, 0.38, 0, -16, R_UP, L_UP, W),
			_t(0.46, 0.85, 0, 42, R_DOWN, L_DOWN, L),
			_t(0.62, 0.82, 0, 40, R_DOWN, L_DOWN, L),
			_t(0.85, 0.55, 0, 14, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.65, "hit": 0.3, "keys": [
			_t(0.0, 0.55, 0, 14, R_GUARD, L_GUARD, W),
			_t(0.16, 0.6, -24, 8, R_CHAMBER, L_GUARD, BK),
			_t(0.3, 0.6, 16, 26, R_PUNCH, L_GUARD, L),
			_t(0.44, 0.58, 14, 24, R_PUNCH, L_GUARD, L),
			_t(0.65, 0.55, 0, 14, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.85, "hit": 0.44, "keys": [
			_t(0.0, 0.55, 0, 14, R_GUARD, L_GUARD, W),
			_t(0.2, 0.85, -20, 30, R_UPP0, L_GUARD, W),
			_t(0.34, 0.88, -22, 32, R_UPP0, L_GUARD, W),
			_t(0.44, 0.25, 10, -14, R_UPP1, L_GUARD, L),
			_t(0.6, 0.22, 8, -16, R_UPP1, L_GUARD, L),
			_t(0.85, 0.55, 0, 14, R_GUARD, L_GUARD, W),
		]},
	]
