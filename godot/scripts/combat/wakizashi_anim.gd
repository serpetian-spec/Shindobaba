extends RefCounted
## Wakizashi — kısa kavisli yan kılıç (kodachi): savunmacı, karşı vuruş odaklı, gövdeye yakın. Saldırıyı karşılayıp kesme.
## 1 Nuki Uchi: sol kalçadan çekip yukarı çapraz kesik, 2 Uke Nagashi: ağız baş üstünde yatay (karşılar, bekle) -> aşağı çapraz karşı kesik,
## 3 Tsuki Kaeshi: saplama, ağzı çevirip alttan yukarı kesik (iki vuruş), 4 Ushiro Giri: sırtını dönüp arkadan ters kesik,
## 5 Tai Atari: sol omuzla çarpma (sendeler) + hemen yatay kesik, 6 Jūmonji (bitiriş): önce dikey, sonra yatay kesik; havada artı
## biçimli iz kalır ve gecikmeyle patlar (KeyedCombos).

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.2, -0.75, 0.62), "RightLowerArm": Vector3(0.25, 0.1, 0.96)}
const R_HIP_L := {"RightUpperArm": Vector3(0.3, -0.85, 0.42), "RightLowerArm": Vector3(0.7, -0.5, 0.5)}       # sol kalçada (çekiş)
const R_RISE := {"RightUpperArm": Vector3(-0.55, 0.65, 0.5), "RightLowerArm": Vector3(-0.4, 0.85, 0.35)}      # sağ üstte bitmiş
const R_PARRY := {"RightUpperArm": Vector3(-0.3, 0.85, 0.42), "RightLowerArm": Vector3(0.75, 0.45, 0.5)}      # ağız başın üstünde yatay
const R_DOWN := {"RightUpperArm": Vector3(0.25, -0.5, 0.82), "RightLowerArm": Vector3(0.8, -0.35, 0.45)}
const R_CHAMBER := {"RightUpperArm": Vector3(-0.3, -0.6, -0.75), "RightLowerArm": Vector3(-0.05, -0.05, 1)}
const R_STAB := {"RightUpperArm": Vector3(-0.04, -0.03, 1), "RightLowerArm": Vector3(0.0, -0.02, 1)}
const R_UP := {"RightUpperArm": Vector3(-0.15, 0.7, 0.7), "RightLowerArm": Vector3(0.0, 0.95, 0.3)}
const R_WIDE := {"RightUpperArm": Vector3(-0.95, -0.1, 0.3), "RightLowerArm": Vector3(-0.85, -0.2, 0.5)}
const R_LEFT := {"RightUpperArm": Vector3(0.2, -0.1, 0.97), "RightLowerArm": Vector3(0.9, 0.2, 0.35)}
const R_HIGH := {"RightUpperArm": Vector3(-0.2, 0.95, -0.2), "RightLowerArm": Vector3(0.0, 0.95, 0.3)}
const R_LOW_C := {"RightUpperArm": Vector3(-0.05, -0.55, 0.83), "RightLowerArm": Vector3(0.0, -0.75, 0.66)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.2, 0.3, 0.93)}
const L_SHEATH := {"LeftUpperArm": Vector3(0.15, -0.95, 0.25), "LeftLowerArm": Vector3(-0.4, -0.5, 0.76)}    # kının ağzını tutar
const L_BACK := {"LeftUpperArm": Vector3(0.55, -0.6, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}
const L_SHOULDER := {"LeftUpperArm": Vector3(0.45, -0.5, 0.74), "LeftLowerArm": Vector3(-0.3, 0.8, 0.5)}     # omuz çarpması (kol göğse)


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.2, 0.5, 0.85)
	return [
		{"len": 0.6, "hit": 0.26, "keys": [
			_t(0.0, 0.38, 0, 6, RDY, R_READY, L_GUARD, W),
			_t(0.14, 0.5, 30, 10, Vector3(0.7, -0.6, 0.3), R_HIP_L, L_SHEATH, CR),
			_t(0.22, 0.52, 32, 12, Vector3(0.7, -0.6, 0.3), R_HIP_L, L_SHEATH, CR),
			_t(0.28, 0.44, -26, 14, Vector3(-0.6, 0.7, 0.4), R_RISE, L_BACK, L),
			_t(0.4, 0.42, -30, 12, Vector3(-0.6, 0.75, 0.3), R_RISE, L_BACK, L),
			_t(0.6, 0.38, 0, 6, RDY, R_READY, L_GUARD, W),
		]},
		{"len": 0.8, "hit": 0.48, "keys": [
			_t(0.0, 0.38, 0, 6, RDY, R_READY, L_GUARD, W),
			_t(0.12, 0.44, 0, -8, Vector3(0.95, 0.1, 0.2), R_PARRY, L_GUARD, BK),
			_t(0.4, 0.46, 0, -10, Vector3(0.95, 0.1, 0.2), R_PARRY, L_GUARD, BK),
			_t(0.48, 0.56, 22, 24, Vector3(0.6, -0.6, 0.5), R_DOWN, L_BACK, L),
			_t(0.62, 0.56, 26, 22, Vector3(0.65, -0.65, 0.4), R_DOWN, L_BACK, L),
			_t(0.8, 0.38, 0, 6, RDY, R_READY, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.22, "extra_hits": [0.42], "extra_radius": 1.6, "keys": [
			_t(0.0, 0.38, 0, 6, RDY, R_READY, L_GUARD, W),
			_t(0.12, 0.44, -14, -4, Vector3(0, 0.05, 1), R_CHAMBER, L_GUARD, BK),
			_t(0.22, 0.52, 10, 22, Vector3(0, 0.0, 1), R_STAB, L_BACK, L),
			_t(0.32, 0.6, 6, 26, Vector3(0, -0.7, 0.7), R_LOW_C, L_BACK, L),
			_t(0.42, 0.3, 4, -10, Vector3(0, 0.95, 0.3), R_UP, L_BACK, L),
			_t(0.54, 0.3, 4, -12, Vector3(0, 0.95, 0.25), R_UP, L_BACK, ST),
			_t(0.75, 0.38, 0, 6, RDY, R_READY, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.4, "keys": [
			_t(0.0, 0.38, 0, 6, RDY, R_READY, L_GUARD, W),
			_t(0.16, 0.44, 160, 4, Vector3(0.8, 0.2, 0.5), R_LEFT, L_GUARD, CR),
			_t(0.3, 0.46, 170, 6, Vector3(0.8, 0.2, 0.5), R_LEFT, L_GUARD, CR),
			_t(0.4, 0.5, 300, 14, Vector3(-0.9, 0.1, 0.4), R_WIDE, L_BACK, W),
			_t(0.52, 0.48, 360, 12, Vector3(-0.95, 0.05, 0.3), R_WIDE, L_BACK, ST),
			_t(0.75, 0.38, 360, 6, RDY, R_READY, L_GUARD, W),
		]},
		{"len": 0.8, "hit": 0.26, "extra_hits": [0.5], "extra_radius": 1.8, "keys": [
			_t(0.0, 0.38, 0, 6, RDY, R_READY, L_GUARD, W),
			_t(0.12, 0.5, 40, 10, RDY, R_READY, L_SHOULDER, BK),
			_t(0.26, 0.54, 50, 26, RDY, R_LEFT, L_SHOULDER, L),
			_t(0.38, 0.5, 40, 20, Vector3(0.8, 0.2, 0.5), R_LEFT, L_SHOULDER, L),
			_t(0.5, 0.48, -24, 16, Vector3(-0.9, 0.1, 0.4), R_WIDE, L_BACK, ST),
			_t(0.62, 0.46, -28, 14, Vector3(-0.95, 0.05, 0.3), R_WIDE, L_BACK, W),
			_t(0.8, 0.38, 0, 6, RDY, R_READY, L_GUARD, W),
		]},
		{"len": 1.3, "hit": 0.42, "extra_hits": [0.78], "extra_radius": 2.0, "keys": [
			_t(0.0, 0.38, 0, 6, RDY, R_READY, L_GUARD, W),
			_t(0.2, 0.4, 0, -12, Vector3(0, 0.95, -0.2), R_HIGH, L_GUARD, BK),
			_t(0.36, 0.42, 0, -14, Vector3(0, 0.95, -0.2), R_HIGH, L_GUARD, BK),
			_t(0.42, 0.58, 0, 26, Vector3(0, -0.7, 0.7), R_LOW_C, L_BACK, L),
			_t(0.56, 0.5, 30, 14, Vector3(0.8, 0.2, 0.5), R_LEFT, L_BACK, L),
			_t(0.7, 0.5, 32, 14, Vector3(0.8, 0.2, 0.5), R_LEFT, L_BACK, L),
			_t(0.78, 0.52, -28, 18, Vector3(-0.9, 0.1, 0.4), R_WIDE, L_BACK, ST),
			_t(0.95, 0.5, -30, 16, Vector3(-0.95, 0.05, 0.3), R_WIDE, L_BACK, W),
			_t(1.3, 0.38, 0, 6, RDY, R_READY, L_GUARD, W),
		]},
	]
