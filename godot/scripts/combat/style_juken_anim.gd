extends RefCounted
## Dövüş tarzı — Jūken (Hyūga Yumuşak Yumruk). Ref: refs/styles/juken_*.png (Neji/Hinata duruşu, Hakke).
## Duruş: yan dönük alçak geniş duruş, SOL açık avuç önde uzanık, SAĞ avuç geride göğüs hizasında; eller hep açık (yumruk yok).
## 1 Shō: sağ avuç ileri itilir, 2 Nishō: sol avuç, 3 Age-shō: çömelip yukarı avuç (çeneye), 4 Hakke Nishō: sağ-sol çift avuç,
## 5 Tenketsu dürtüşü: iki parmakla altı hızlı dürtüş (chakra noktaları), 6 Hakke Kūshō: iki el geri çekilir, çift avuçla
## hava basıncı fırlatılır (KeyedCombos.on_strike). Her isabet rakibin chakrasını tıkar (on_target).

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_STANCE := {"RightUpperArm": Vector3(-0.3, -0.75, -0.55), "RightLowerArm": Vector3(-0.05, 0.55, 0.83)}   # sağ avuç göğüs yanında geride
const L_STANCE := {"LeftUpperArm": Vector3(0.15, -0.35, 0.92), "LeftLowerArm": Vector3(0.0, 0.15, 1)}         # sol avuç önde uzanık
const R_PALM := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.14, 1)}
const L_PALM := {"LeftUpperArm": Vector3(0.05, 0.05, 1), "LeftLowerArm": Vector3(0.0, 0.14, 1)}
const L_BACK := {"LeftUpperArm": Vector3(0.3, -0.75, -0.55), "LeftLowerArm": Vector3(0.05, 0.55, 0.83)}
const R_LOW := {"RightUpperArm": Vector3(-0.15, -0.9, 0.35), "RightLowerArm": Vector3(0.0, -0.3, 0.95)}
const R_RISE := {"RightUpperArm": Vector3(-0.1, 0.45, 0.9), "RightLowerArm": Vector3(0.0, 0.9, 0.42)}
const R_FING := {"RightUpperArm": Vector3(-0.08, -0.15, 1), "RightLowerArm": Vector3(0.0, -0.05, 1)}
const L_FING := {"LeftUpperArm": Vector3(0.08, -0.1, 1), "LeftLowerArm": Vector3(0.0, 0.0, 1)}
const R_PULL := {"RightUpperArm": Vector3(-0.35, -0.7, -0.62), "RightLowerArm": Vector3(-0.05, 0.3, 0.95)}
const L_PULL := {"LeftUpperArm": Vector3(0.35, -0.7, -0.62), "LeftLowerArm": Vector3(0.05, 0.3, 0.95)}
const R_DBL := {"RightUpperArm": Vector3(0.05, 0.12, 1), "RightLowerArm": Vector3(0.12, 0.2, 1)}               # iki avuç birlikte, hafif yukarı
const L_DBL := {"LeftUpperArm": Vector3(-0.05, 0.12, 1), "LeftLowerArm": Vector3(-0.12, 0.2, 1)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	return [
		{"len": 0.45, "hit": 0.17, "keys": [
			_t(0.0, 0.62, -28, 8, R_STANCE, L_STANCE, W),
			_t(0.08, 0.66, -34, 4, R_PULL, L_STANCE, BK),
			_t(0.17, 0.62, 18, 16, R_PALM, L_BACK, L),
			_t(0.28, 0.6, 14, 14, R_PALM, L_BACK, L),
			_t(0.45, 0.62, -28, 8, R_STANCE, L_STANCE, W),
		]},
		{"len": 0.45, "hit": 0.18, "keys": [
			_t(0.0, 0.62, -28, 8, R_STANCE, L_STANCE, W),
			_t(0.08, 0.64, 20, 6, R_STANCE, L_PULL, BK),
			_t(0.18, 0.62, -26, 16, R_STANCE, L_PALM, LL),
			_t(0.28, 0.6, -22, 14, R_STANCE, L_PALM, LL),
			_t(0.45, 0.62, -28, 8, R_STANCE, L_STANCE, W),
		]},
		{"len": 0.55, "hit": 0.26, "keys": [
			_t(0.0, 0.62, -28, 8, R_STANCE, L_STANCE, W),
			_t(0.14, 0.85, -14, 24, R_LOW, L_STANCE, W),
			_t(0.26, 0.38, 10, -10, R_RISE, L_BACK, L),
			_t(0.36, 0.36, 8, -12, R_RISE, L_BACK, L),
			_t(0.55, 0.62, -28, 8, R_STANCE, L_STANCE, W),
		]},
		{"len": 0.6, "hit": 0.17, "extra_hits": [0.33], "extra_radius": 1.6, "keys": [
			_t(0.0, 0.62, -28, 8, R_STANCE, L_STANCE, W),
			_t(0.08, 0.64, -32, 6, R_PULL, L_STANCE, BK),
			_t(0.17, 0.6, 16, 16, R_PALM, L_PULL, L),
			_t(0.25, 0.62, 0, 10, R_PULL, L_PULL, ST),
			_t(0.33, 0.6, -18, 16, R_PULL, L_PALM, LL),
			_t(0.42, 0.6, -16, 14, R_PULL, L_PALM, LL),
			_t(0.6, 0.62, -28, 8, R_STANCE, L_STANCE, W),
		]},
		{"len": 0.9, "hit": 0.12, "extra_hits": [0.24, 0.36, 0.48, 0.6, 0.72], "extra_radius": 1.5, "keys": [
			_t(0.0, 0.62, -28, 8, R_STANCE, L_STANCE, W),
			_t(0.06, 0.66, -10, 12, R_PULL, L_STANCE, L),
			_t(0.12, 0.66, 10, 18, R_FING, L_PULL, L),
			_t(0.18, 0.66, -10, 14, R_PULL, L_PULL, L),
			_t(0.24, 0.66, -12, 18, R_PULL, L_FING, L),
			_t(0.3, 0.66, 0, 14, R_PULL, L_PULL, L),
			_t(0.36, 0.68, 12, 20, R_FING, L_PULL, L),
			_t(0.42, 0.66, -6, 14, R_PULL, L_PULL, L),
			_t(0.48, 0.68, -12, 20, R_PULL, L_FING, L),
			_t(0.54, 0.66, 0, 14, R_PULL, L_PULL, L),
			_t(0.6, 0.68, 12, 20, R_FING, L_PULL, L),
			_t(0.66, 0.66, -6, 14, R_PULL, L_PULL, L),
			_t(0.72, 0.7, -12, 22, R_PULL, L_FING, L),
			_t(0.9, 0.62, -28, 8, R_STANCE, L_STANCE, W),
		]},
		{"len": 0.85, "hit": 0.46, "keys": [
			_t(0.0, 0.62, -28, 8, R_STANCE, L_STANCE, W),
			_t(0.18, 0.74, 0, -6, R_PULL, L_PULL, BK),
			_t(0.34, 0.76, 0, -8, R_PULL, L_PULL, BK),   # kurulum: iki el kalça yanında, nefes
			_t(0.46, 0.6, 0, 18, R_DBL, L_DBL, L),
			_t(0.6, 0.58, 0, 16, R_DBL, L_DBL, L),
			_t(0.85, 0.62, -28, 8, R_STANCE, L_STANCE, W),
		]},
	]
