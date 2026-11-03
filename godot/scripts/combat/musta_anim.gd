extends RefCounted
## Muşta bıçağı — parmak korumalı bıçak: BOKS + bıçak. Yumruklar muşta kemeriyle, kesikler ağızla. Sol kol gardda, ayaklar sekerek.
## 1 Jab Kiri: sağ düz yumruk, ağız önden keser, 2 Kagi Tsuki: yatay kroşe, ağız yan keser, 3 Age Tsuki: çömelip aparkat (kaldırır),
## 4 Hara Uchi + Gyaku: gövdeye yumruk + geri çekerken ters kesik (iki vuruş), 5 Renda: sağ-sol değil — tek kolla beş hızlı yumruk
## (muşta topuzları), 6 Tekken Giri (bitiriş): gövdeyi sağa burup dizler bükülür (uzun kurulum) -> tüm ağırlıkla savrulan haymaker,
## çarpışmada şok halkası + derin kesik (KeyedCombos).

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_GUARD := {"RightUpperArm": Vector3(-0.25, -0.75, 0.6), "RightLowerArm": Vector3(0.15, 0.75, 0.64)}    # yumruk çene önünde
const L_GUARD := {"LeftUpperArm": Vector3(0.25, -0.75, 0.6), "LeftLowerArm": Vector3(-0.15, 0.75, 0.64)}
const R_JAB := {"RightUpperArm": Vector3(-0.05, 0.1, 1), "RightLowerArm": Vector3(0.0, 0.08, 1)}
const R_HOOK0 := {"RightUpperArm": Vector3(-0.95, 0.0, 0.2), "RightLowerArm": Vector3(0.3, 0.05, 0.95)}
const R_HOOK1 := {"RightUpperArm": Vector3(0.1, 0.05, 0.99), "RightLowerArm": Vector3(0.95, 0.05, 0.25)}
const R_UPP0 := {"RightUpperArm": Vector3(-0.3, -0.9, 0.2), "RightLowerArm": Vector3(0.0, -0.2, 0.98)}
const R_UPP1 := {"RightUpperArm": Vector3(-0.1, 0.3, 0.95), "RightLowerArm": Vector3(0.0, 0.98, 0.2)}
const R_BODY := {"RightUpperArm": Vector3(-0.1, -0.35, 0.93), "RightLowerArm": Vector3(0.05, -0.2, 0.98)}
const R_BACKSL := {"RightUpperArm": Vector3(-0.85, -0.3, 0.4), "RightLowerArm": Vector3(-0.85, -0.1, 0.5)}
const R_CHAMBER := {"RightUpperArm": Vector3(-0.3, -0.7, -0.6), "RightLowerArm": Vector3(-0.05, 0.4, 0.92)}
const R_WIND := {"RightUpperArm": Vector3(-0.9, -0.2, -0.38), "RightLowerArm": Vector3(-0.6, 0.3, -0.75)}       # haymaker kurulumu
const L_JAB := {"LeftUpperArm": Vector3(0.05, 0.1, 1), "LeftLowerArm": Vector3(0.0, 0.08, 1)}
const L_BACK := {"LeftUpperArm": Vector3(0.45, -0.65, -0.6), "LeftLowerArm": Vector3(0.2, 0.4, -0.9)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, Vector3(0, 0.2, 1).normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	return [
		{"len": 0.45, "hit": 0.16, "keys": [
			_t(0.0, 0.46, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.08, 0.48, -14, 4, R_CHAMBER, L_GUARD, BK),
			_t(0.16, 0.5, 16, 20, R_JAB, L_GUARD, L),
			_t(0.26, 0.48, 14, 16, R_JAB, L_GUARD, L),
			_t(0.45, 0.46, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.55, "hit": 0.24, "keys": [
			_t(0.0, 0.46, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.12, 0.5, -34, 6, R_HOOK0, L_GUARD, BK),
			_t(0.24, 0.52, 30, 18, R_HOOK1, L_GUARD, ST),
			_t(0.34, 0.5, 36, 16, R_HOOK1, L_GUARD, W),
			_t(0.55, 0.46, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.6, "hit": 0.28, "keys": [
			_t(0.0, 0.46, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.14, 0.78, -20, 26, R_UPP0, L_GUARD, W),
			_t(0.28, 0.26, 10, -12, R_UPP1, L_GUARD, L),
			_t(0.38, 0.24, 8, -14, R_UPP1, L_GUARD, L),
			_t(0.6, 0.46, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.65, "hit": 0.2, "extra": [0.4], "extra_r": 1.5, "keys": [
			_t(0.0, 0.46, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.1, 0.6, -10, 18, R_CHAMBER, L_GUARD, BK),
			_t(0.2, 0.64, 14, 26, R_BODY, L_GUARD, L),
			_t(0.3, 0.56, 24, 16, R_BODY, L_GUARD, L),
			_t(0.4, 0.5, -30, 10, R_BACKSL, L_GUARD, BK),
			_t(0.5, 0.48, -34, 8, R_BACKSL, L_GUARD, BK),
			_t(0.65, 0.46, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.85, "hit": 0.14, "extra": [0.26, 0.38, 0.5, 0.62], "extra_r": 1.4, "keys": [
			_t(0.0, 0.46, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.08, 0.5, -10, 12, R_CHAMBER, L_GUARD, ST),
			_t(0.14, 0.52, 10, 18, R_JAB, L_GUARD, L),
			_t(0.2, 0.5, -8, 12, R_CHAMBER, L_GUARD, L),
			_t(0.26, 0.52, 12, 18, R_JAB, L_GUARD, L),
			_t(0.32, 0.5, -8, 12, R_CHAMBER, L_GUARD, L),
			_t(0.38, 0.52, 10, 18, R_BODY, L_GUARD, L),
			_t(0.44, 0.5, -8, 12, R_CHAMBER, L_GUARD, L),
			_t(0.5, 0.52, 12, 18, R_JAB, L_GUARD, L),
			_t(0.56, 0.5, -8, 12, R_CHAMBER, L_GUARD, L),
			_t(0.62, 0.54, 14, 22, R_JAB, L_GUARD, L),
			_t(0.85, 0.46, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 1.2, "hit": 0.72, "keys": [
			_t(0.0, 0.46, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.24, 0.68, -60, 6, R_WIND, L_JAB, BK),
			_t(0.62, 0.7, -66, 4, R_WIND, L_JAB, BK),
			_t(0.72, 0.56, 50, 30, R_HOOK1, L_BACK, L),
			_t(0.92, 0.54, 56, 26, R_HOOK1, L_BACK, L),
			_t(1.2, 0.46, 0, 10, R_GUARD, L_GUARD, W),
		]},
	]
