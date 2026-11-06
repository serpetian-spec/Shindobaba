extends RefCounted
## Dövüş tarzı — Hōzuki (Suika no Jutsu, sulaşma). ORTA MENZİL. Ref: refs/styles/hozuki_*.png (Suigetsu: parmak ucundan su mermisi
## Mizudeppō, suyla şişen kaslı kol Gōsuiwan, su kırbacı Mizu Muchi). Yakında kol şişip ezer, uzakta su atar.
## 1 Mizudeppō: sağ işaret parmağından su mermisi, 2 sol el su mermisi, 3 Mizu Muchi: sağ elden hedefe uzanan su kırbacı,
## 4 Gōsuiwan: sağ kol suyla şişer (gerçek kemik kalınlaşır), yakın dev yumruk, 5 Ryōmuchi: iki elden çapraz kırbaç,
## 6 Daimizudeppō: iki el birleşir, büyük su mermisi (geri teper).

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")   # canlı bacaklar: bükük diz, ağırlık aktarımı, pivot

const R_GUARD := {"RightUpperArm": Vector3(-0.3, -0.8, 0.5), "RightLowerArm": Vector3(0.0, 0.5, 0.86)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.8, 0.5), "LeftLowerArm": Vector3(0.0, 0.5, 0.86)}
const R_POINT := {"RightUpperArm": Vector3(-0.05, 0.1, 1), "RightLowerArm": Vector3(0.0, 0.12, 1)}   # parmak tabanca gibi ileri
const L_POINT := {"LeftUpperArm": Vector3(0.05, 0.1, 1), "LeftLowerArm": Vector3(0.0, 0.12, 1)}
const R_WHIP0 := {"RightUpperArm": Vector3(-0.8, 0.5, -0.3), "RightLowerArm": Vector3(-0.3, 0.9, 0.3)}
const R_WHIP1 := {"RightUpperArm": Vector3(0.2, -0.2, 0.96), "RightLowerArm": Vector3(0.6, -0.3, 0.75)}
const L_WHIP0 := {"LeftUpperArm": Vector3(0.8, 0.5, -0.3), "LeftLowerArm": Vector3(0.3, 0.9, 0.3)}
const L_WHIP1 := {"LeftUpperArm": Vector3(-0.2, -0.2, 0.96), "LeftLowerArm": Vector3(-0.6, -0.3, 0.75)}
const R_CHAMBER := {"RightUpperArm": Vector3(-0.45, -0.6, -0.65), "RightLowerArm": Vector3(-0.1, 0.35, 0.93)}
const R_PUNCH := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}
const R_JOIN := {"RightUpperArm": Vector3(0.1, 0.0, 1), "RightLowerArm": Vector3(0.15, 0.05, 1)}
const L_JOIN := {"LeftUpperArm": Vector3(-0.1, 0.0, 1), "LeftLowerArm": Vector3(-0.15, 0.05, 1)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = F.SHIFT
	return [
		{"len": 0.45, "hit": 0.18, "keys": [
			_t(0.0, 0.4, 0, 6, R_GUARD, L_GUARD, W),
			_t(0.1, 0.42, 14, 4, R_POINT, L_GUARD, W),
			_t(0.18, 0.4, 18, 2, R_POINT, L_GUARD, W),
			_t(0.26, 0.42, 22, -4, R_POINT, L_GUARD, BK),   # geri tepme
			_t(0.45, 0.4, 0, 6, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.45, "hit": 0.18, "keys": [
			_t(0.0, 0.4, 0, 6, R_GUARD, L_GUARD, W),
			_t(0.1, 0.42, -14, 4, R_GUARD, L_POINT, W),
			_t(0.18, 0.4, -18, 2, R_GUARD, L_POINT, W),
			_t(0.26, 0.42, -22, -4, R_GUARD, L_POINT, BK),
			_t(0.45, 0.4, 0, 6, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.6, "hit": 0.28, "keys": [
			_t(0.0, 0.4, 0, 6, R_GUARD, L_GUARD, W),
			_t(0.14, 0.44, -30, 0, R_WHIP0, L_GUARD, BK),
			_t(0.28, 0.46, 24, 14, R_WHIP1, L_GUARD, L),
			_t(0.4, 0.44, 30, 12, R_WHIP1, L_GUARD, L),
			_t(0.6, 0.4, 0, 6, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.7, "hit": 0.34, "keys": [
			_t(0.0, 0.4, 0, 6, R_GUARD, L_GUARD, W),
			_t(0.18, 0.5, -36, 2, R_CHAMBER, L_GUARD, BK),
			_t(0.28, 0.52, -38, 0, R_CHAMBER, L_GUARD, BK),
			_t(0.34, 0.46, 26, 20, R_PUNCH, L_GUARD, L),
			_t(0.5, 0.44, 22, 18, R_PUNCH, L_GUARD, L),
			_t(0.7, 0.4, 0, 6, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.7, "hit": 0.26, "extra_hits": [0.42], "extra_radius": 1.6, "keys": [
			_t(0.0, 0.4, 0, 6, R_GUARD, L_GUARD, W),
			_t(0.12, 0.44, -24, 2, R_WHIP0, L_GUARD, BK),
			_t(0.26, 0.46, 22, 12, R_WHIP1, L_WHIP0, L),
			_t(0.42, 0.46, -22, 12, R_WHIP1, L_WHIP1, LL),
			_t(0.52, 0.44, -18, 10, R_GUARD, L_WHIP1, LL),
			_t(0.7, 0.4, 0, 6, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.85, "hit": 0.46, "keys": [
			_t(0.0, 0.4, 0, 6, R_GUARD, L_GUARD, W),
			_t(0.2, 0.5, 0, -6, R_CHAMBER, {"LeftUpperArm": Vector3(0.45, -0.6, -0.65), "LeftLowerArm": Vector3(0.1, 0.35, 0.93)}, BK),
			_t(0.38, 0.52, 0, -8, R_CHAMBER, {"LeftUpperArm": Vector3(0.45, -0.6, -0.65), "LeftLowerArm": Vector3(0.1, 0.35, 0.93)}, BK),
			_t(0.46, 0.44, 0, 14, R_JOIN, L_JOIN, L),
			_t(0.58, 0.5, 0, -6, R_JOIN, L_JOIN, BK),   # büyük merminin geri tepmesi
			_t(0.85, 0.4, 0, 6, R_GUARD, L_GUARD, W),
		]},
	]
