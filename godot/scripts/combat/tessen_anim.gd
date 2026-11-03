extends RefCounted
## Savaş Yelpazesi (Temari tarzı dev demir tessen): kapalıyken sopa gibi vurur, açılınca rüzgâr bıçakları (kamaitachi) savurur.
## Bashōsen'den farklı: AĞIR yelpaze, iki elle de savrulur; rüzgâr kesici ince bıçak çizgileri + toz, kalkan gibi önde tutulur.
## 1 kapalı yelpazeyle darbe, 2 Kamaitachi (açılıp yatay savuruş: kesici rüzgâr bıçakları), 3 kalkan + karşı rüzgâr,
## 4 dönerek açık yelpaze savuruşu, 5 yere vurup toz halkası, 6 Daikamaitachi (bitiriş): iki elle dev savuruş, uzun kesici fırtına.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.3, -0.85, 0.4), "RightLowerArm": Vector3(-0.05, -0.3, 0.95)}       # kapalı yelpaze yanda aşağı
const R_SH := {"RightUpperArm": Vector3(-0.55, 0.6, -0.55), "RightLowerArm": Vector3(-0.1, 0.9, 0.4)}          # omuz üstü-arkası
const R_STRIKE := {"RightUpperArm": Vector3(-0.1, -0.2, 0.97), "RightLowerArm": Vector3(0.05, -0.4, 0.9)}
const R_OPEN_BACK := {"RightUpperArm": Vector3(-0.95, 0.1, -0.3), "RightLowerArm": Vector3(-0.8, 0.3, -0.5)}
const R_SWEEP := {"RightUpperArm": Vector3(0.45, 0.05, 0.88), "RightLowerArm": Vector3(0.95, 0.1, 0.25)}
const R_SHIELD := {"RightUpperArm": Vector3(-0.3, -0.2, 0.93), "RightLowerArm": Vector3(0.6, 0.3, 0.74)}       # göğüs önünde kalkan
const R_WIDE := {"RightUpperArm": Vector3(-0.98, 0.0, 0.15), "RightLowerArm": Vector3(-0.95, 0.05, 0.3)}
const R_HIGH := {"RightUpperArm": Vector3(-0.25, 0.95, -0.2), "RightLowerArm": Vector3(-0.05, 0.85, -0.5)}
const R_DOWN := {"RightUpperArm": Vector3(-0.1, -0.3, 0.95), "RightLowerArm": Vector3(0.0, -0.7, 0.7)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.8, 0.5), "LeftLowerArm": Vector3(-0.1, -0.1, 0.99)}
const L_POINT := {"LeftUpperArm": Vector3(0.15, 0.05, 1), "LeftLowerArm": Vector3(0.05, 0.0, 1)}
const L_BRACE := {"LeftUpperArm": Vector3(-0.1, -0.3, 0.94), "LeftLowerArm": Vector3(-0.7, 0.3, 0.64)}         # yelpazeye destek
const L_HIGH := {"LeftUpperArm": Vector3(0.25, 0.95, -0.2), "LeftLowerArm": Vector3(0.05, 0.85, -0.5)}
const L_OPEN := {"LeftUpperArm": Vector3(0.95, -0.2, 0.2), "LeftLowerArm": Vector3(0.85, -0.2, 0.45)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0, -0.4, 0.9)
	return [
		# 1 Uchi: kapalı yelpaze omuz üstüne kalkar -> sopa gibi tepeden ağır darbe
		{"len": 0.8, "hit": 0.36, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.16, 0.4, -16, -10, Vector3(0, 0.8, -0.5), R_SH, L_POINT, BK),
			_t(0.3, 0.42, -18, -12, Vector3(0, 0.8, -0.5), R_SH, L_POINT, BK),
			_t(0.36, 0.52, 14, 22, Vector3(0, -0.4, 0.9), R_STRIKE, L_GUARD, L),
			_t(0.55, 0.5, 10, 18, Vector3(0, -0.5, 0.85), R_STRIKE, L_GUARD, L),
			_t(0.8, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 2 Kamaitachi: yelpaze sağ-arkaya açılır (gövde iyice burulur, bekle) -> yatay geniş savuruş, kesici rüzgâr bıçakları
		{"len": 1.0, "hit": 0.44, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.2, 0.44, -40, -6, Vector3(-0.8, 0.5, -0.3), R_OPEN_BACK, L_POINT, BK),
			_t(0.36, 0.46, -44, -8, Vector3(-0.8, 0.5, -0.3), R_OPEN_BACK, L_POINT, BK),
			_t(0.44, 0.48, 34, 16, Vector3(0.8, 0.4, 0.45), R_SWEEP, L_OPEN, L),
			_t(0.64, 0.46, 42, 14, Vector3(0.9, 0.3, 0.3), R_SWEEP, L_OPEN, L),
			_t(1.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 3 Tate Kaze: açık yelpaze göğüs önünde kalkan (iki el) -> öne itilir, karşı rüzgâr dalgası rakibi savurur
		{"len": 0.9, "hit": 0.48, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.18, 0.5, 0, -4, Vector3(0, 1, 0.1), R_SHIELD, L_BRACE, BK),
			_t(0.38, 0.52, 0, -6, Vector3(0, 1, 0.1), R_SHIELD, L_BRACE, BK),
			_t(0.48, 0.5, 6, 24, Vector3(0, 1, 0.2), R_SHIELD, L_BRACE, L),
			_t(0.66, 0.46, 4, 18, Vector3(0, 1, 0.2), R_SHIELD, L_BRACE, L),
			_t(0.9, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 4 Senpū: açık yelpaze yana uzanır, gövde tam tur döner -> çevreye kesici rüzgâr halkası
		{"len": 1.05, "hit": 0.54, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.18, 0.44, -30, 4, Vector3(-0.9, 0.3, 0.3), R_WIDE, L_OPEN, BK),
			_t(0.36, 0.46, 70, 8, Vector3(-0.9, 0.3, 0.3), R_WIDE, L_OPEN, CR),
			_t(0.54, 0.46, 180, 8, Vector3(-0.9, 0.3, 0.3), R_WIDE, L_OPEN, W),
			_t(0.76, 0.44, 30, 6, Vector3(-0.7, 0.4, 0.6), R_WIDE, L_OPEN, ST),
			_t(1.05, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 5 Jishin Ōgi: iki elle baş üstüne kaldırır -> önüne yere vurur, toz halkası yayılır (yakındakileri devirir)
		{"len": 1.05, "hit": 0.5, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.2, 0.36, -4, -20, Vector3(0, 0.7, -0.7), R_HIGH, L_HIGH, BK),
			_t(0.42, 0.38, -6, -24, Vector3(0, 0.65, -0.75), R_HIGH, L_HIGH, BK),
			_t(0.5, 0.66, 6, 34, Vector3(0, -0.8, 0.6), R_DOWN, L_BRACE, L),
			_t(0.72, 0.64, 4, 28, Vector3(0, -0.8, 0.6), R_DOWN, L_BRACE, L),
			_t(1.05, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 6 Daikamaitachi (bitiriş): yelpaze tamamen açılıp sırta kadar geriye kurulur (uzun bekleme) -> iki elle dev savuruş
		{"len": 1.4, "hit": 0.7, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.24, 0.46, -50, -10, Vector3(-0.8, 0.5, -0.3), R_OPEN_BACK, L_BRACE, BK),
			_t(0.6, 0.48, -56, -12, Vector3(-0.8, 0.5, -0.3), R_OPEN_BACK, L_BRACE, BK),
			_t(0.7, 0.54, 40, 22, Vector3(0.8, 0.4, 0.45), R_SWEEP, L_BRACE, L),
			_t(1.0, 0.52, 48, 18, Vector3(0.9, 0.3, 0.3), R_SWEEP, L_BRACE, L),
			_t(1.4, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
	]
