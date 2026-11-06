extends RefCounted
## Dövüş tarzı — Kaguya (Shikotsumyaku kemik dansları). Ref: refs/styles/kaguya_*.png (Kimimaro: avuçtan kemik kılıç,
## kollardan/omuzlardan kemik dikenleri, parmak kemiği mermileri, bedenden fışkıran dikenler).
## Sağ el avucundan çıkan kemik kılıcı tutar (KeyedCombos: kemik bıçak eli izler). Zarif, akıcı, kılıç dansı ritmi.
## 1 Tsubaki: sağdan sola yatay kesik, 2 Tsubaki Gaeshi: ters kesik, 3 Tsubaki Tsuki: ileri hamle (menzil uzun),
## 4 Yanagi no Mai: kollar/omuzlardan dikenler fışkırır, dönerek keser, 5 Teshi Sendan: sol parmak uçlarından kemik mermileri,
## 6 Karamatsu no Mai: çömelip tüm bedenden dikenler fışkırır (alan).

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_REST := {"RightUpperArm": Vector3(-0.35, -0.9, 0.2), "RightLowerArm": Vector3(-0.1, -0.5, 0.85)}      # kılıç aşağı-önde
const L_REST := {"LeftUpperArm": Vector3(0.3, -0.9, 0.2), "LeftLowerArm": Vector3(0.2, -0.6, 0.75)}
const R_WIND := {"RightUpperArm": Vector3(-0.95, 0.05, -0.25), "RightLowerArm": Vector3(-0.9, 0.1, 0.4)}     # sağa açık
const R_CUT := {"RightUpperArm": Vector3(0.45, 0.0, 0.89), "RightLowerArm": Vector3(0.9, 0.0, 0.4)}          # sola süpürülmüş
const R_THRUST := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}
const R_PULL := {"RightUpperArm": Vector3(-0.3, -0.7, -0.65), "RightLowerArm": Vector3(-0.05, 0.25, 0.97)}
const R_OUT := {"RightUpperArm": Vector3(-1, -0.05, 0.1), "RightLowerArm": Vector3(-0.95, -0.1, 0.3)}
const L_OUT := {"LeftUpperArm": Vector3(1, -0.05, 0.1), "LeftLowerArm": Vector3(0.95, -0.1, 0.3)}
const L_POINT := {"LeftUpperArm": Vector3(0.05, 0.15, 1), "LeftLowerArm": Vector3(0.0, 0.18, 1)}           # sol el hedefi gösterir
const R_CROSS := {"RightUpperArm": Vector3(0.3, -0.5, 0.8), "RightLowerArm": Vector3(0.6, 0.6, 0.5)}         # kollar göğüste çapraz (Karamatsu kurulumu)
const L_CROSS := {"LeftUpperArm": Vector3(-0.3, -0.5, 0.8), "LeftLowerArm": Vector3(-0.6, 0.6, 0.5)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	return [
		{"len": 0.45, "hit": 0.18, "keys": [
			_t(0.0, 0.4, 0, 6, R_REST, L_REST, W),
			_t(0.08, 0.44, -30, 4, R_WIND, L_REST, BK),
			_t(0.18, 0.46, 32, 14, R_CUT, L_OUT, L),
			_t(0.28, 0.44, 36, 12, R_CUT, L_OUT, L),
			_t(0.45, 0.4, 0, 6, R_REST, L_REST, W),
		]},
		{"len": 0.45, "hit": 0.18, "keys": [
			_t(0.0, 0.4, 36, 6, R_CUT, L_REST, W),
			_t(0.18, 0.46, -34, 14, R_WIND, L_REST, CR),
			_t(0.28, 0.44, -36, 12, R_WIND, L_REST, CR),
			_t(0.45, 0.4, 0, 6, R_REST, L_REST, W),
		]},
		{"len": 0.5, "hit": 0.22, "keys": [
			_t(0.0, 0.4, 0, 6, R_REST, L_REST, W),
			_t(0.1, 0.5, -20, 4, R_PULL, L_OUT, BK),
			_t(0.22, 0.55, 14, 24, R_THRUST, L_OUT, L),
			_t(0.32, 0.54, 12, 22, R_THRUST, L_OUT, L),
			_t(0.5, 0.4, 0, 6, R_REST, L_REST, W),
		]},
		{"len": 0.75, "hit": 0.2, "extra_hits": [0.36, 0.52], "extra_radius": 2.0, "keys": [
			_t(0.0, 0.4, 0, 6, R_REST, L_REST, W),
			_t(0.1, 0.5, -90, 10, R_OUT, L_OUT, W),
			_t(0.22, 0.5, 60, 10, R_OUT, L_OUT, W),
			_t(0.34, 0.5, 180, 10, R_OUT, L_OUT, W),
			_t(0.46, 0.5, -170, 10, R_OUT, L_OUT, W),
			_t(0.58, 0.5, -60, 10, R_OUT, L_OUT, W),
			_t(0.75, 0.4, 0, 6, R_REST, L_REST, W),
		]},
		{"len": 0.6, "hit": 0.24, "keys": [
			_t(0.0, 0.4, 0, 6, R_REST, L_REST, W),
			_t(0.12, 0.44, -30, 4, R_REST, L_POINT, LL),
			_t(0.24, 0.44, -34, 6, R_REST, L_POINT, LL),
			_t(0.4, 0.44, -32, 6, R_REST, L_POINT, LL),
			_t(0.6, 0.4, 0, 6, R_REST, L_REST, W),
		]},
		{"len": 0.85, "hit": 0.44, "keys": [
			_t(0.0, 0.4, 0, 6, R_REST, L_REST, W),
			_t(0.2, 0.9, 0, 40, R_CROSS, L_CROSS, W),
			_t(0.36, 0.95, 0, 46, R_CROSS, L_CROSS, W),   # büzülür
			_t(0.44, 0.5, 0, -8, R_OUT, L_OUT, W),        # dikenler fışkırırken açılır
			_t(0.62, 0.5, 0, -6, R_OUT, L_OUT, W),
			_t(0.85, 0.4, 0, 6, R_REST, L_REST, W),
		]},
	]
