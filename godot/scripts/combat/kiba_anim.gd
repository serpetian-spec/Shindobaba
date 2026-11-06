extends RefCounted
## Kiba (ref kiba.png) — İKİZ YILDIRIM KILICI, her elde bir tane. Düz ince ağız, iki yanda zıt kancalı diken. Her kesikte ağızlardan
## Raiton akar (KeyedCombos). Çevik ikiz ritim, kancalarla yakalama, sonunda gökten yıldırım çağırma.
## 1 Jūji: iki kılıç dıştan içe X kesik, 2 Renga: sağ-sol art arda saplama, 3 Kagi Hiki: dikenlerle kancalayıp çekme,
## 4 Raijin Senpū: kollar açık tam tur dönüş (elektrik halkası), 5 Rairyū Tsuki: kılıçlar baş üstünde çaprazlanıp yüklenir ->
## ikisi birden öne saplanır, ağızlardan ileri şimşek, 6 Kaminari Gekō (bitiriş): kılıçlar göğe kalkar, gökten yıldırım
## kılıçlara iner -> kılıçlar öne indirilir, yıldırım hedefin üstüne çakar.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_GUARD := {"RightUpperArm": Vector3(-0.3, -0.7, 0.62), "RightLowerArm": Vector3(0.15, 0.2, 0.97)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.7, 0.62), "LeftLowerArm": Vector3(-0.15, 0.2, 0.97)}
const R_OUT_HI := {"RightUpperArm": Vector3(-0.85, 0.45, -0.25), "RightLowerArm": Vector3(-0.5, 0.8, 0.3)}
const L_OUT_HI := {"LeftUpperArm": Vector3(0.85, 0.45, -0.25), "LeftLowerArm": Vector3(0.5, 0.8, 0.3)}
const R_IN_LO := {"RightUpperArm": Vector3(0.3, -0.45, 0.84), "RightLowerArm": Vector3(0.8, -0.35, 0.5)}
const L_IN_LO := {"LeftUpperArm": Vector3(-0.3, -0.45, 0.84), "LeftLowerArm": Vector3(-0.8, -0.35, 0.5)}
const R_CHAMBER := {"RightUpperArm": Vector3(-0.3, -0.6, -0.75), "RightLowerArm": Vector3(-0.05, -0.05, 1)}
const L_CHAMBER := {"LeftUpperArm": Vector3(0.3, -0.6, -0.75), "LeftLowerArm": Vector3(0.05, -0.05, 1)}
const R_STAB := {"RightUpperArm": Vector3(-0.05, 0.0, 1), "RightLowerArm": Vector3(0.0, 0.0, 1)}
const L_STAB := {"LeftUpperArm": Vector3(0.05, 0.0, 1), "LeftLowerArm": Vector3(0.0, 0.0, 1)}
const R_PULL := {"RightUpperArm": Vector3(-0.45, -0.7, -0.55), "RightLowerArm": Vector3(-0.1, 0.3, 0.95)}
const L_PULL := {"LeftUpperArm": Vector3(0.45, -0.7, -0.55), "LeftLowerArm": Vector3(0.1, 0.3, 0.95)}
const R_WIDE := {"RightUpperArm": Vector3(-0.98, 0.0, 0.15), "RightLowerArm": Vector3(-0.95, 0.05, 0.3)}
const L_WIDE := {"LeftUpperArm": Vector3(0.98, 0.0, 0.15), "LeftLowerArm": Vector3(0.95, 0.05, 0.3)}
const R_CROSS_UP := {"RightUpperArm": Vector3(0.1, 0.9, 0.4), "RightLowerArm": Vector3(0.45, 0.85, 0.2)}
const L_CROSS_UP := {"LeftUpperArm": Vector3(-0.1, 0.9, 0.4), "LeftLowerArm": Vector3(-0.45, 0.85, 0.2)}
const R_SKY := {"RightUpperArm": Vector3(-0.25, 0.97, 0.0), "RightLowerArm": Vector3(-0.1, 1.0, 0.0)}
const L_SKY := {"LeftUpperArm": Vector3(0.25, 0.97, 0.0), "LeftLowerArm": Vector3(0.1, 1.0, 0.0)}
const R_DOWN := {"RightUpperArm": Vector3(-0.15, -0.3, 0.94), "RightLowerArm": Vector3(0.0, -0.55, 0.83)}
const L_DOWN := {"LeftUpperArm": Vector3(0.15, -0.3, 0.94), "LeftLowerArm": Vector3(0.0, -0.55, 0.83)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.1, 0.3, 0.95)
	return [
		# 1 Jūji: iki kılıç omuzların dışında yukarıda (bekle) -> içe-aşağı X kesik
		{"len": 0.7, "hit": 0.32, "keys": [
			_t(0.0, 0.4, 0, 6, RDY, R_GUARD, L_GUARD, W),
			_t(0.14, 0.42, 0, -10, Vector3(-0.4, 0.8, -0.3), R_OUT_HI, L_OUT_HI, BK),
			_t(0.26, 0.44, 0, -12, Vector3(-0.4, 0.8, -0.3), R_OUT_HI, L_OUT_HI, BK),
			_t(0.32, 0.56, 0, 24, Vector3(0.6, -0.6, 0.5), R_IN_LO, L_IN_LO, L),
			_t(0.46, 0.54, 0, 20, Vector3(0.6, -0.6, 0.5), R_IN_LO, L_IN_LO, L),
			_t(0.7, 0.4, 0, 6, RDY, R_GUARD, L_GUARD, W),
		]},
		# 2 Renga: sağ saplama, hemen sol saplama (kalça yer değiştirir)
		{"len": 0.75, "hit": 0.22, "extra_hits": [0.44], "extra_radius": 1.6, "keys": [
			_t(0.0, 0.4, 0, 6, RDY, R_GUARD, L_GUARD, W),
			_t(0.12, 0.44, -20, -4, Vector3(0, 0.05, 1), R_CHAMBER, L_GUARD, BK),
			_t(0.22, 0.5, 18, 20, Vector3(0, 0.0, 1), R_STAB, L_CHAMBER, L),
			_t(0.34, 0.48, 10, 10, Vector3(0, 0.0, 1), R_CHAMBER, L_CHAMBER, ST),
			_t(0.44, 0.52, -20, 22, Vector3(0, 0.0, 1), R_CHAMBER, L_STAB, LL),
			_t(0.56, 0.5, -18, 18, Vector3(0, 0.0, 1), R_GUARD, L_STAB, LL),
			_t(0.75, 0.4, 0, 6, RDY, R_GUARD, L_GUARD, W),
		]},
		# 3 Kagi Hiki: iki kılıç öne uzanır (dikenler rakibin arkasına geçer) -> gövde geriye yaslanıp çeker
		{"len": 0.85, "hit": 0.3, "keys": [
			_t(0.0, 0.4, 0, 6, RDY, R_GUARD, L_GUARD, W),
			_t(0.16, 0.44, 0, -6, Vector3(0, 0.6, -0.8), R_OUT_HI, L_OUT_HI, BK),
			_t(0.3, 0.52, 0, 26, Vector3(0, 0.1, 1), R_STAB, L_STAB, L),
			_t(0.44, 0.5, 0, 22, Vector3(0, 0.1, 1), R_STAB, L_STAB, L),
			_t(0.58, 0.46, 0, -22, Vector3(0, 0.3, 0.95), R_PULL, L_PULL, BK),
			_t(0.68, 0.46, 0, -24, Vector3(0, 0.3, 0.95), R_PULL, L_PULL, BK),
			_t(0.85, 0.4, 0, 6, RDY, R_GUARD, L_GUARD, W),
		]},
		# 4 Raijin Senpū: kollar iki yana açık, tam tur dönüş (elektrik halkası)
		{"len": 0.95, "hit": 0.3, "extra_hits": [0.52, 0.72], "extra_radius": 2.4, "keys": [
			_t(0.0, 0.4, 0, 6, RDY, R_GUARD, L_GUARD, W),
			_t(0.14, 0.48, -30, 4, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, BK),
			_t(0.34, 0.5, 90, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, CR),
			_t(0.54, 0.5, 210, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, W),
			_t(0.74, 0.5, 330, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, CR),
			_t(0.95, 0.4, 0, 6, RDY, R_GUARD, L_GUARD, W),
		]},
		# 5 Rairyū Tsuki: kılıçlar baş üstünde çapraz (yüklenir) -> ikisi birden öne saplanır, ileri şimşek
		{"len": 1.1, "hit": 0.56, "keys": [
			_t(0.0, 0.4, 0, 6, RDY, R_GUARD, L_GUARD, W),
			_t(0.2, 0.36, 0, -8, Vector3(0, 0.95, 0.2), R_CROSS_UP, L_CROSS_UP, W),
			_t(0.46, 0.38, 0, -10, Vector3(0, 0.95, 0.2), R_CROSS_UP, L_CROSS_UP, W),
			_t(0.56, 0.56, 0, 28, Vector3(0, 0.0, 1), R_STAB, L_STAB, L),
			_t(0.8, 0.54, 0, 24, Vector3(0, 0.0, 1), R_STAB, L_STAB, L),
			_t(1.1, 0.4, 0, 6, RDY, R_GUARD, L_GUARD, W),
		]},
		# 6 Kaminari Gekō (bitiriş): iki kılıç dimdik göğe (yıldırım kılıçlara iner) -> öne-aşağı indirilir, yıldırım hedefe çakar
		{"len": 1.5, "hit": 0.86, "keys": [
			_t(0.0, 0.4, 0, 6, RDY, R_GUARD, L_GUARD, W),
			_t(0.24, 0.3, 0, -14, Vector3(0, 1, 0.05), R_SKY, L_SKY, W),
			_t(0.78, 0.3, 0, -16, Vector3(0, 1, 0.05), R_SKY, L_SKY, W),
			_t(0.86, 0.58, 0, 30, Vector3(0, -0.5, 0.86), R_DOWN, L_DOWN, L),
			_t(1.1, 0.56, 0, 26, Vector3(0, -0.5, 0.86), R_DOWN, L_DOWN, L),
			_t(1.5, 0.4, 0, 6, RDY, R_GUARD, L_GUARD, W),
		]},
	]
