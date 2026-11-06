extends RefCounted
## Dövüş tarzı — Uchiha-ryū (Sharingan ile okunan tekme kombosu + Katon). YAKIN + ORTA. Ref: refs/styles/uchiha_*.png
## (Sasuke Shishi Rendan: havaya tekme, Kage Buyō ile arkasında belirme, topuk inişi; Gōkakyū/Hōsenka ateşi).
## 1 Choku-zuki: sağ düz yumruk, 2 Mawashi-geri: dönerek sağ yan tekme, 3 Ken-age: ön tekme yukarı (havaya kaldırır),
## 4 Kage Buyō: rakibin peşinden sıçrayış + havada diz, 5 Shishi Otoshi: yüksek topuk inişi (yere serer),
## 6 Katon: Hōka — el mühürü ve ağızdan kısa ateş seli (orta menzil, yakar).

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")   # canlı bacaklar: bükük diz, ağırlık aktarımı, pivot

const R_GUARD := {"RightUpperArm": Vector3(-0.25, -0.75, 0.6), "RightLowerArm": Vector3(0.15, 0.75, 0.64)}
const L_GUARD := {"LeftUpperArm": Vector3(0.25, -0.75, 0.6), "LeftLowerArm": Vector3(-0.15, 0.75, 0.64)}
const R_PUNCH := {"RightUpperArm": Vector3(-0.05, 0.08, 1), "RightLowerArm": Vector3(0.0, 0.06, 1)}
const R_CHAMBER := {"RightUpperArm": Vector3(-0.3, -0.7, -0.6), "RightLowerArm": Vector3(-0.05, 0.4, 0.92)}
const R_OUT := {"RightUpperArm": Vector3(-0.95, -0.2, 0.2), "RightLowerArm": Vector3(-0.8, -0.3, 0.5)}
const L_OUT := {"LeftUpperArm": Vector3(0.95, -0.2, 0.2), "LeftLowerArm": Vector3(0.8, -0.3, 0.5)}
const R_SEAL := {"RightUpperArm": Vector3(-0.2, -0.6, 0.78), "RightLowerArm": Vector3(0.55, 0.55, 0.62)}   # mühür: eller göğüs önünde
const L_SEAL := {"LeftUpperArm": Vector3(0.2, -0.6, 0.78), "LeftLowerArm": Vector3(-0.55, 0.55, 0.62)}
const R_MOUTH := {"RightUpperArm": Vector3(-0.2, -0.3, 0.93), "RightLowerArm": Vector3(0.6, 0.75, 0.25)}  # el ağız önünde (ateş üfleme)
const LEG_SIDEKICK := {"RightUpperLeg": Vector3(-0.95, 0.2, 0.2), "RightLowerLeg": Vector3(-0.98, 0.15, 0.1), "RightFoot": Vector3(-0.9, 0.1, 0.4),
	"LeftUpperLeg": Vector3(0.15, -0.98, 0.1), "LeftLowerLeg": Vector3(0.05, -0.97, -0.2), "LeftFoot": Vector3(0.05, -0.45, 0.89)}
const LEG_FRONTKICK := {"RightUpperLeg": Vector3(-0.1, 0.35, 0.93), "RightLowerLeg": Vector3(-0.05, 0.55, 0.83), "RightFoot": Vector3(0.0, 0.3, 0.95),
	"LeftUpperLeg": Vector3(0.15, -0.98, 0.1), "LeftLowerLeg": Vector3(0.05, -0.97, -0.2), "LeftFoot": Vector3(0.05, -0.45, 0.89)}
const LEG_KNEE := {"RightUpperLeg": Vector3(-0.1, 0.2, 0.97), "RightLowerLeg": Vector3(-0.05, -0.9, 0.4), "RightFoot": Vector3(0.0, -0.4, 0.9),
	"LeftUpperLeg": Vector3(0.2, -0.8, -0.55), "LeftLowerLeg": Vector3(0.1, -0.6, -0.8), "LeftFoot": Vector3(0.05, -0.9, 0.4)}
const LEG_AXEUP := {"RightUpperLeg": Vector3(-0.1, 0.9, 0.42), "RightLowerLeg": Vector3(-0.05, 0.95, 0.3), "RightFoot": Vector3(0.0, 0.5, 0.86),
	"LeftUpperLeg": Vector3(0.15, -0.98, 0.1), "LeftLowerLeg": Vector3(0.05, -0.97, -0.2), "LeftFoot": Vector3(0.05, -0.45, 0.89)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var L = S.LEG_LUNGE
	var BK = F.SHIFT
	return [
		{"len": 0.42, "hit": 0.16, "keys": [
			_t(0.0, 0.4, 0, 8, R_GUARD, L_GUARD, W),
			_t(0.07, 0.44, -14, 4, R_CHAMBER, L_GUARD, BK),
			_t(0.16, 0.46, 16, 18, R_PUNCH, L_GUARD, L),
			_t(0.26, 0.44, 12, 14, R_PUNCH, L_GUARD, L),
			_t(0.42, 0.4, 0, 8, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.55, "hit": 0.26, "keys": [
			_t(0.0, 0.4, 0, 8, R_GUARD, L_GUARD, W),
			_t(0.12, 0.36, 60, -6, R_OUT, L_GUARD, W),
			_t(0.26, 0.3, 90, -16, R_OUT, L_GUARD, LEG_SIDEKICK),
			_t(0.36, 0.3, 92, -16, R_OUT, L_GUARD, LEG_SIDEKICK),
			_t(0.55, 0.4, 0, 8, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.5, "hit": 0.24, "keys": [
			_t(0.0, 0.4, 0, 8, R_GUARD, L_GUARD, W),
			_t(0.12, 0.5, 0, 10, R_GUARD, L_GUARD, BK),
			_t(0.24, 0.2, 0, -22, R_OUT, L_OUT, LEG_FRONTKICK),
			_t(0.34, 0.2, 0, -24, R_OUT, L_OUT, LEG_FRONTKICK),
			_t(0.5, 0.4, 0, 8, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.55, "hit": 0.3, "keys": [
			_t(0.0, 0.5, 0, 8, R_GUARD, L_GUARD, BK),
			_t(0.16, 0.3, 0, 10, R_OUT, L_OUT, LEG_KNEE),
			_t(0.3, 0.3, 0, 20, R_GUARD, L_GUARD, LEG_KNEE),
			_t(0.4, 0.3, 0, 18, R_GUARD, L_GUARD, LEG_KNEE),
			_t(0.55, 0.4, 0, 8, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.65, "hit": 0.36, "keys": [
			_t(0.0, 0.4, 0, 8, R_GUARD, L_GUARD, W),
			_t(0.16, 0.2, 0, -20, R_OUT, L_OUT, LEG_AXEUP),
			_t(0.28, 0.2, 0, -22, R_OUT, L_OUT, LEG_AXEUP),
			_t(0.36, 0.62, 0, 26, R_GUARD, L_GUARD, L),
			_t(0.48, 0.6, 0, 24, R_GUARD, L_GUARD, L),
			_t(0.65, 0.4, 0, 8, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.85, "hit": 0.46, "keys": [
			_t(0.0, 0.4, 0, 8, R_GUARD, L_GUARD, W),
			_t(0.16, 0.46, 0, 4, R_SEAL, L_SEAL, W),
			_t(0.34, 0.46, 0, 4, R_SEAL, L_SEAL, W),     # mühür
			_t(0.42, 0.4, 0, -10, R_MOUTH, L_GUARD, BK),
			_t(0.64, 0.4, 0, -8, R_MOUTH, L_GUARD, BK),   # ateş sürerken
			_t(0.85, 0.4, 0, 8, R_GUARD, L_GUARD, W),
		]},
	]
