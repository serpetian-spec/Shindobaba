extends RefCounted
## Kuchiyose Fūma (ref fumavaryasyon2.png): sağ elde çağırma parşömeni; her adımda parşömen açılır, dumanla ÜÇ büyük kare Fūma
## shuriken çıkar ve farklı düzenlerde hedefe uçar (KeyedCombos._summon_three). UZUN MENZİL.
## 1 yelpaze, 2 yörünge, 3 yağmur, 4 dizi, 5 kıskaç, 6 kafes (bitiriş).

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.3, -0.8, 0.45), "RightLowerArm": Vector3(0.3, -0.1, 0.95)}
const L_READY := {"LeftUpperArm": Vector3(0.3, -0.8, 0.45), "LeftLowerArm": Vector3(-0.3, -0.1, 0.95)}
const R_OPEN := {"RightUpperArm": Vector3(-0.9, 0.1, 0.4), "RightLowerArm": Vector3(-0.8, 0.1, 0.6)}
const L_OPEN := {"LeftUpperArm": Vector3(0.9, 0.1, 0.4), "LeftLowerArm": Vector3(0.8, 0.1, 0.6)}
const R_SEAL := {"RightUpperArm": Vector3(-0.2, -0.3, 0.93), "RightLowerArm": Vector3(0.6, 0.45, 0.66)}
const L_SEAL := {"LeftUpperArm": Vector3(0.2, -0.3, 0.93), "LeftLowerArm": Vector3(-0.6, 0.45, 0.66)}
const R_POINT := {"RightUpperArm": Vector3(-0.05, 0.2, 1), "RightLowerArm": Vector3(0.0, 0.1, 1)}
const L_POINT := {"LeftUpperArm": Vector3(0.05, 0.2, 1), "LeftLowerArm": Vector3(0.0, 0.1, 1)}
const R_SKY := {"RightUpperArm": Vector3(-0.1, 0.98, 0.15), "RightLowerArm": Vector3(0.0, 0.95, 0.3)}
const L_BACK := {"LeftUpperArm": Vector3(0.5, -0.6, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var RDY = Vector3(0.35, 0.15, 0.92)
	return [
		# 1 Ōgi: parşömen göğüste -> iki yana açılır (dumanla üç shuriken çıkar) -> sağ kol hedefi gösterir, yelpaze gibi uçarlar
		{"len": 1.0, "hit": 0.42, "keys": [
			_t(0.0, 0.32, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.18, 0.4, -6, -6, RDY, R_SEAL, L_SEAL, W),
			_t(0.34, 0.42, 0, -10, RDY, R_OPEN, L_OPEN, W),
			_t(0.42, 0.4, 10, 14, RDY, R_POINT, L_OPEN, ST),
			_t(0.7, 0.38, 6, 8, RDY, R_POINT, L_OPEN, ST),
			_t(1.0, 0.32, 0, 4, RDY, R_READY, L_READY, W),
		]},
		# 2 Kaiten: çıkanlar ustanın çevresinde döner (yakına çarpar) -> iki kol öne, hedefe salınırlar
		{"len": 1.25, "hit": 0.36, "extra": [0.5, 0.66], "extra_r": 2.4, "keys": [
			_t(0.0, 0.32, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.2, 0.42, 0, -10, RDY, R_OPEN, L_OPEN, W),
			_t(0.5, 0.44, 20, -6, RDY, R_OPEN, L_OPEN, W),
			_t(0.8, 0.44, -10, 14, RDY, R_POINT, L_POINT, L),
			_t(1.0, 0.4, -6, 8, RDY, R_POINT, L_POINT, L),
			_t(1.25, 0.32, 0, 4, RDY, R_READY, L_READY, W),
		]},
		# 3 Ame: parşömen göğe kaldırılır -> shurikenler hedefin üstünde belirip aşağı yağar
		{"len": 1.1, "hit": 0.4, "keys": [
			_t(0.0, 0.32, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.2, 0.3, 0, -16, Vector3(0, 1, 0.2), R_SKY, L_BACK, ST),
			_t(0.4, 0.28, 0, -18, Vector3(0, 1, 0.2), R_SKY, L_BACK, ST),
			_t(0.6, 0.44, 0, 16, RDY, R_POINT, L_BACK, W),
			_t(1.1, 0.32, 0, 4, RDY, R_READY, L_READY, W),
		]},
		# 4 Renda: geri adım, parşömen açık; shurikenler ardı ardına tek sıra dümdüz gider
		{"len": 1.0, "hit": 0.34, "keys": [
			_t(0.0, 0.32, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.2, 0.44, -14, -8, RDY, R_OPEN, L_OPEN, BK),
			_t(0.34, 0.44, 12, 16, RDY, R_POINT, L_OPEN, L),
			_t(0.6, 0.4, 8, 10, RDY, R_POINT, L_OPEN, L),
			_t(1.0, 0.32, 0, 4, RDY, R_READY, L_READY, W),
		]},
		# 5 Hasami: iki kol iki yana açılır -> shurikenler sağdan-soldan geniş kavisle hedefte buluşur
		{"len": 1.05, "hit": 0.38, "keys": [
			_t(0.0, 0.32, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.22, 0.42, 0, -6, RDY, R_SEAL, L_SEAL, W),
			_t(0.38, 0.42, 0, 8, RDY, R_OPEN, L_OPEN, W),
			_t(0.7, 0.4, 0, 6, RDY, R_OPEN, L_OPEN, W),
			_t(1.05, 0.32, 0, 4, RDY, R_READY, L_READY, W),
		]},
		# 6 Kago (bitiriş): mühür -> parşömen tamamen açılır; üç shuriken hedefin çevresinde kafes gibi döner, sonra içeri çarpar
		{"len": 1.6, "hit": 0.5, "keys": [
			_t(0.0, 0.32, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.24, 0.44, 0, -6, RDY, R_SEAL, L_SEAL, W),
			_t(0.44, 0.46, 0, -12, RDY, R_OPEN, L_OPEN, W),
			_t(0.5, 0.44, 10, 14, RDY, R_POINT, L_POINT, ST),
			_t(1.2, 0.42, 6, 10, RDY, R_POINT, L_POINT, ST),
			_t(1.6, 0.32, 0, 4, RDY, R_READY, L_READY, W),
		]},
	]
