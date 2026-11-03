extends RefCounted
## Hiramekarei (ref hiramekarei.png kapalı / hiramekarei2.png açık): geniş yaprak kılıç. Kombonun ortasında İKİYE BÖLÜNÜR
## (KeyedCombos._hk_split): her yarı bir elde, çift kılıç kesikleri; sonra birleşir, tek el ağır bitiriş + chakra dalgası.
## 1 tek el ağır çapraz (kapalı), 2 ayrılış: kılıç ikiye açılır + çift çapraz, 3 çift kanat (iki yandan içe), 4 çift dönen kesik,
## 5 birleşip baş üstünde chakra yükler, 6 Hiramekarei Kaihō (bitiriş): chakra yüklü dev iniş, önde ezici dalga.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.35, -0.7, 0.6), "RightLowerArm": Vector3(0.2, 0.6, 0.78)}
const L_READY := {"LeftUpperArm": Vector3(0.3, -0.8, 0.5), "LeftLowerArm": Vector3(-0.1, -0.1, 0.99)}
const R_HIGH := {"RightUpperArm": Vector3(-0.45, 0.85, -0.3), "RightLowerArm": Vector3(-0.15, 0.9, -0.4)}
const L_HIGH := {"LeftUpperArm": Vector3(0.45, 0.85, -0.3), "LeftLowerArm": Vector3(0.15, 0.9, -0.4)}
const R_DOWN := {"RightUpperArm": Vector3(0.2, -0.4, 0.9), "RightLowerArm": Vector3(0.5, -0.55, 0.65)}
const L_DOWN := {"LeftUpperArm": Vector3(-0.2, -0.4, 0.9), "LeftLowerArm": Vector3(-0.5, -0.55, 0.65)}
const R_WIDE := {"RightUpperArm": Vector3(-0.98, 0.0, 0.15), "RightLowerArm": Vector3(-0.95, 0.05, 0.3)}
const L_WIDE := {"LeftUpperArm": Vector3(0.98, 0.0, 0.15), "LeftLowerArm": Vector3(0.95, 0.05, 0.3)}
const R_IN := {"RightUpperArm": Vector3(0.3, 0.0, 0.95), "RightLowerArm": Vector3(0.85, 0.1, 0.5)}
const L_IN := {"LeftUpperArm": Vector3(-0.3, 0.0, 0.95), "LeftLowerArm": Vector3(-0.85, 0.1, 0.5)}
const R_UP := {"RightUpperArm": Vector3(-0.1, 0.98, 0.1), "RightLowerArm": Vector3(0.0, 0.95, 0.2)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.4, 0.8, 0.4)
	return [
		{"len": 1.0, "hit": 0.48, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.2, 0.42, -20, -18, Vector3(-0.2, 0.7, -0.7), R_HIGH, L_READY, BK),
			_t(0.42, 0.44, -24, -22, Vector3(-0.2, 0.7, -0.7), R_HIGH, L_READY, BK),
			_t(0.48, 0.56, 24, 28, Vector3(0.5, -0.6, 0.6), R_DOWN, L_READY, L),
			_t(0.68, 0.56, 26, 24, Vector3(0.55, -0.7, 0.45), R_DOWN, L_READY, L),
			_t(1.0, 0.36, 0, 4, RDY, R_READY, L_READY, W),
		]},
		{"len": 0.95, "hit": 0.46, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.22, 0.42, 0, -14, Vector3(0, 0.8, -0.5), R_HIGH, L_HIGH, BK),
			_t(0.4, 0.44, 0, -16, Vector3(0, 0.8, -0.5), R_HIGH, L_HIGH, BK),
			_t(0.46, 0.56, 0, 26, Vector3(0.5, -0.6, 0.6), R_DOWN, L_DOWN, L),
			_t(0.66, 0.54, 0, 22, Vector3(0.5, -0.6, 0.6), R_DOWN, L_DOWN, L),
			_t(0.95, 0.4, 0, 6, RDY, R_READY, L_READY, W),
		]},
		{"len": 0.8, "hit": 0.38, "keys": [
			_t(0.0, 0.4, 0, 6, RDY, R_READY, L_READY, W),
			_t(0.16, 0.44, 0, -6, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, BK),
			_t(0.32, 0.46, 0, -8, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, BK),
			_t(0.38, 0.5, 0, 18, Vector3(0.8, 0.1, 0.5), R_IN, L_IN, ST),
			_t(0.54, 0.48, 0, 14, Vector3(0.8, 0.1, 0.5), R_IN, L_IN, L),
			_t(0.8, 0.4, 0, 6, RDY, R_READY, L_READY, W),
		]},
		{"len": 1.05, "hit": 0.32, "extra": [0.56, 0.78], "extra_r": 2.4, "keys": [
			_t(0.0, 0.4, 0, 6, RDY, R_READY, L_READY, W),
			_t(0.18, 0.46, -30, 4, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, BK),
			_t(0.38, 0.48, 90, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, CR),
			_t(0.6, 0.48, 200, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, W),
			_t(0.8, 0.48, 320, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, CR),
			_t(1.05, 0.4, 0, 6, RDY, R_READY, L_READY, W),
		]},
		{"len": 0.9, "hit": 0.5, "keys": [
			_t(0.0, 0.4, 0, 6, RDY, R_READY, L_READY, W),
			_t(0.2, 0.4, 0, -6, Vector3(0, 1, 0.1), R_UP, L_READY, W),
			_t(0.5, 0.42, 0, -8, Vector3(0, 1, 0.1), R_UP, L_READY, W),
			_t(0.6, 0.5, 14, 18, Vector3(0.5, -0.4, 0.75), R_DOWN, L_READY, L),
			_t(0.9, 0.36, 0, 4, RDY, R_READY, L_READY, W),
		]},
		# 6 Hiramekarei Kaihō — Tsuchi (bitiriş, kanon): birleşmiş kılıç iki elle sağ-arkaya kurulur, chakra kılıcın ucunda dev bir
		#   ÇEKİÇ biçimini alır (KeyedCombos) -> çekiç gövdeyle öne yatay savrulur, önündekileri ezip savurur
		{"len": 1.5, "hit": 0.82, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.24, 0.46, -52, -10, Vector3(-0.85, 0.2, -0.45), R_WIDE, L_WIDE, BK),
			_t(0.74, 0.48, -58, -12, Vector3(-0.85, 0.2, -0.45), R_WIDE, L_WIDE, BK),
			_t(0.82, 0.52, 8, 16, Vector3(-0.2, 0.15, 0.96), R_WIDE, L_IN, ST),
			_t(0.92, 0.56, 54, 22, Vector3(0.9, 0.15, 0.35), R_IN, L_IN, L),
			_t(1.12, 0.54, 62, 18, Vector3(0.9, 0.1, 0.3), R_IN, L_IN, L),
			_t(1.5, 0.36, 0, 4, RDY, R_READY, L_READY, W),
		]},
	]
