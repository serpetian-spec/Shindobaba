extends RefCounted
## Temari'nin Dev Yelpazesi (Ōōgi; ref _tmp/temariref): kanon "ay" mekaniği — yelpaze açıldıkça üzerindeki mor aylar görünür,
## her açılan ay rüzgârı büyütür (Birinci Ay: Kamaitachi, İkinci Ay: rüzgâr duvarı, Üçüncü Ay: Daikamaitachi).
## Genel Savaş Yelpazesi kombosundan (tessen_anim) farklı akış:
## 1 kapalı yelpazeyle tepeden ağır darbe, 2 BİRİNCİ AY: yarım açılıp yatay savuruş (kısa kesici rüzgâr),
## 3 İKİNCİ AY: yelpaze önde iki elle dikilir (kalkan) -> itilir, rüzgâr duvarı rakibi savurur,
## 4 aşağıdan yukarı çapraz savuruş: kasırga rakibi havaya kaldırır,
## 5 yelpazeye sıçrayıp havadan aşağı savurur (yere çarpan rüzgâr), 6 ÜÇÜNCÜ AY: tam açık, sırta kadar kurulur -> Daikamaitachi.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.3, -0.85, 0.4), "RightLowerArm": Vector3(-0.05, -0.3, 0.95)}
const R_SH := {"RightUpperArm": Vector3(-0.55, 0.6, -0.55), "RightLowerArm": Vector3(-0.1, 0.9, 0.4)}
const R_STRIKE := {"RightUpperArm": Vector3(-0.1, -0.2, 0.97), "RightLowerArm": Vector3(0.05, -0.4, 0.9)}
const R_OPEN_BACK := {"RightUpperArm": Vector3(-0.95, 0.1, -0.3), "RightLowerArm": Vector3(-0.8, 0.3, -0.5)}
const R_SWEEP := {"RightUpperArm": Vector3(0.45, 0.05, 0.88), "RightLowerArm": Vector3(0.95, 0.1, 0.25)}
const R_WALL := {"RightUpperArm": Vector3(-0.2, -0.35, 0.92), "RightLowerArm": Vector3(0.1, 0.55, 0.83)}      # yelpaze önde dikili
const R_LOW := {"RightUpperArm": Vector3(-0.5, -0.8, -0.3), "RightLowerArm": Vector3(-0.3, -0.9, 0.2)}       # sağ arkada aşağıda
const R_UP := {"RightUpperArm": Vector3(0.35, 0.85, 0.4), "RightLowerArm": Vector3(0.3, 0.9, 0.3)}           # sol yukarı savrulmuş
const R_HIGH := {"RightUpperArm": Vector3(-0.25, 0.95, -0.2), "RightLowerArm": Vector3(-0.05, 0.85, -0.5)}
const R_DOWN := {"RightUpperArm": Vector3(-0.1, -0.3, 0.95), "RightLowerArm": Vector3(0.0, -0.7, 0.7)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.8, 0.5), "LeftLowerArm": Vector3(-0.1, -0.1, 0.99)}
const L_POINT := {"LeftUpperArm": Vector3(0.15, 0.05, 1), "LeftLowerArm": Vector3(0.05, 0.0, 1)}
const L_BRACE := {"LeftUpperArm": Vector3(-0.1, -0.3, 0.94), "LeftLowerArm": Vector3(-0.7, 0.3, 0.64)}
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
		# 1 Ōgi Uchi: kapalı dev yelpaze omuz üstüne kalkar (ağır: bekle) -> sopa gibi tepeden iner
		{"len": 0.85, "hit": 0.4, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.18, 0.42, -18, -12, Vector3(0, 0.8, -0.5), R_SH, L_POINT, BK),
			_t(0.33, 0.44, -20, -14, Vector3(0, 0.8, -0.5), R_SH, L_POINT, BK),
			_t(0.4, 0.56, 14, 24, Vector3(0, -0.4, 0.9), R_STRIKE, L_GUARD, L),
			_t(0.6, 0.52, 10, 18, Vector3(0, -0.5, 0.85), R_STRIKE, L_GUARD, L),
			_t(0.85, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 2 Birinci Ay — Kamaitachi: yelpaze ilk aya kadar açılır, sağ-arkaya kurulur -> yatay savuruş
		{"len": 0.95, "hit": 0.42, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.2, 0.44, -42, -6, Vector3(-0.8, 0.5, -0.3), R_OPEN_BACK, L_POINT, BK),
			_t(0.34, 0.46, -46, -8, Vector3(-0.8, 0.5, -0.3), R_OPEN_BACK, L_POINT, BK),
			_t(0.42, 0.48, 34, 16, Vector3(0.8, 0.4, 0.45), R_SWEEP, L_OPEN, L),
			_t(0.62, 0.46, 42, 14, Vector3(0.9, 0.3, 0.3), R_SWEEP, L_OPEN, L),
			_t(0.95, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 3 İkinci Ay — rüzgâr duvarı: yelpaze önde dikilir (iki el, kalkan, çömel) -> omuzla itilir
		{"len": 0.95, "hit": 0.5, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.16, 0.56, 0, -4, Vector3(0, 1, 0.15), R_WALL, L_BRACE, BK),
			_t(0.4, 0.6, 0, -6, Vector3(0, 1, 0.15), R_WALL, L_BRACE, BK),
			_t(0.5, 0.5, 4, 26, Vector3(0, 1, 0.3), R_WALL, L_BRACE, L),
			_t(0.7, 0.46, 2, 20, Vector3(0, 1, 0.3), R_WALL, L_BRACE, L),
			_t(0.95, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 4 Tatsumaki: yelpaze sağ arkada yere yakın (derin çömelme) -> aşağıdan sol yukarı çapraz savuruş, kasırga kaldırır
		{"len": 1.0, "hit": 0.5, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.22, 0.7, -38, 18, Vector3(-0.6, -0.7, -0.3), R_LOW, L_OPEN, BK),
			_t(0.42, 0.72, -42, 20, Vector3(-0.6, -0.7, -0.3), R_LOW, L_OPEN, BK),
			_t(0.5, 0.3, 30, -14, Vector3(0.4, 0.85, 0.3), R_UP, L_GUARD, ST),
			_t(0.72, 0.28, 36, -16, Vector3(0.4, 0.9, 0.2), R_UP, L_GUARD, ST),
			_t(1.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 5 Ōgi Tobi: sıçrar, havada yelpazeyi baş üstüne kaldırır -> aşağı savurur, yere çarpan rüzgâr
		{"len": 1.05, "hit": 0.55, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.2, 0.3, -6, -18, Vector3(0, 0.7, -0.7), R_HIGH, L_HIGH, CR),
			_t(0.45, 0.32, -8, -22, Vector3(0, 0.65, -0.75), R_HIGH, L_HIGH, CR),
			_t(0.55, 0.6, 6, 36, Vector3(0, -0.8, 0.6), R_DOWN, L_BRACE, L),
			_t(0.78, 0.6, 4, 30, Vector3(0, -0.8, 0.6), R_DOWN, L_BRACE, L),
			_t(1.05, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 6 Üçüncü Ay — Daikamaitachi (bitiriş): yelpaze tamamen açılır, sırta kadar kurulur (uzun bekleme) -> iki elle dev savuruş
		{"len": 1.45, "hit": 0.74, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.26, 0.48, -54, -10, Vector3(-0.8, 0.5, -0.3), R_OPEN_BACK, L_BRACE, BK),
			_t(0.64, 0.5, -60, -12, Vector3(-0.8, 0.5, -0.3), R_OPEN_BACK, L_BRACE, BK),
			_t(0.74, 0.56, 42, 22, Vector3(0.8, 0.4, 0.45), R_SWEEP, L_BRACE, L),
			_t(1.05, 0.54, 50, 18, Vector3(0.9, 0.3, 0.3), R_SWEEP, L_BRACE, L),
			_t(1.45, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
	]
