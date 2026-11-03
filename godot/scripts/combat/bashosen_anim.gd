extends RefCounted
## Bashōsen kombosu: hafif ama geniş yelpaze. Her savuruş yelpaze yüzünü öne vererek havayı iter (kenar değil YÜZ önde),
## savuruşun ucunda rüzgâr dalgası çıkar (KeyedCombos: _wind_slash benzeri gust). Ritim: bilek geri kurulur -> kısa bekleme ->
## kalçadan açılan hızlı geniş savuruş -> yelpaze havayı takip eder -> yumuşak toparlanma.
## 1 yatay savuruş (geniş rüzgâr), 2 ters yatay (ikinci dalga), 3 yukarıdan aşağı (yere basan dalga), 4 alttan yukarı (kaldıran
## burgu), 5 dönerek çevre savuruşu (kasırga halkası), 6 Bashō Tenpū (bitiriş): iki elle baş üstünden dev yelpaze darbesi, uzun fırtına.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.35, -0.7, 0.6), "RightLowerArm": Vector3(0.15, 0.55, 0.82)}       # yelpaze göğüs önünde dik
const R_BACK_R := {"RightUpperArm": Vector3(-0.95, 0.15, -0.25), "RightLowerArm": Vector3(-0.75, 0.4, -0.5)}   # sağ-arkaya kurulmuş
const R_SWEEP_L := {"RightUpperArm": Vector3(0.45, 0.0, 0.88), "RightLowerArm": Vector3(0.95, 0.15, 0.25)}      # sola savrulmuş
const R_BACK_L := {"RightUpperArm": Vector3(0.4, 0.2, 0.9), "RightLowerArm": Vector3(0.9, 0.4, -0.2)}           # sol omuz önüne sarılmış
const R_SWEEP_R := {"RightUpperArm": Vector3(-0.95, 0.0, 0.3), "RightLowerArm": Vector3(-0.9, 0.1, 0.4)}        # sağa açılmış
const R_HIGH := {"RightUpperArm": Vector3(-0.25, 0.95, -0.2), "RightLowerArm": Vector3(-0.05, 0.85, -0.5)}       # baş üstü-arkası
const R_DOWN := {"RightUpperArm": Vector3(-0.1, -0.25, 0.96), "RightLowerArm": Vector3(0.0, -0.6, 0.8)}
const R_LOW := {"RightUpperArm": Vector3(-0.35, -0.9, 0.2), "RightLowerArm": Vector3(-0.1, -0.7, 0.7)}
const R_UP := {"RightUpperArm": Vector3(-0.1, 0.8, 0.6), "RightLowerArm": Vector3(0.0, 0.95, 0.3)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.8, 0.5), "LeftLowerArm": Vector3(-0.1, -0.1, 0.99)}
const L_OPEN := {"LeftUpperArm": Vector3(0.95, -0.2, 0.2), "LeftLowerArm": Vector3(0.85, -0.2, 0.45)}
const L_POINT := {"LeftUpperArm": Vector3(0.15, 0.05, 1), "LeftLowerArm": Vector3(0.05, 0.0, 1)}
const L_HIGH := {"LeftUpperArm": Vector3(0.25, 0.95, -0.2), "LeftLowerArm": Vector3(0.05, 0.85, -0.5)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.0, 0.9, 0.4)
	return [
		# 1 Kaze Harai: yelpaze sağ-arkaya açılır, gövde burulur -> kalçadan sola geniş yatay savuruş (yüz önde)
		{"len": 0.75, "hit": 0.34, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.16, 0.4, -32, -4, Vector3(-0.7, 0.6, -0.4), R_BACK_R, L_POINT, BK),
			_t(0.26, 0.42, -36, -6, Vector3(-0.7, 0.6, -0.4), R_BACK_R, L_POINT, BK),
			_t(0.34, 0.44, 26, 12, Vector3(0.8, 0.4, 0.45), R_SWEEP_L, L_OPEN, L),
			_t(0.5, 0.42, 34, 10, Vector3(0.9, 0.3, 0.3), R_SWEEP_L, L_OPEN, L),
			_t(0.75, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 2 Kaeshi: sol omuz önünden ters (backhand) savuruşla sağa ikinci dalga
		{"len": 0.75, "hit": 0.32, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.16, 0.4, 30, -4, Vector3(0.7, 0.6, 0.3), R_BACK_L, L_GUARD, CR),
			_t(0.26, 0.42, 34, -6, Vector3(0.7, 0.6, 0.3), R_BACK_L, L_GUARD, CR),
			_t(0.32, 0.44, -26, 12, Vector3(-0.8, 0.4, 0.45), R_SWEEP_R, L_OPEN, ST),
			_t(0.5, 0.42, -32, 10, Vector3(-0.9, 0.3, 0.3), R_SWEEP_R, L_OPEN, W),
			_t(0.75, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 3 Otoshi Kaze: baş üstüne-arkaya kalkar (gövde geriye kavislenir) -> öne aşağı vurur, dalga yere basıp yayılır
		{"len": 0.9, "hit": 0.42, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.2, 0.36, -6, -18, Vector3(0, 0.7, -0.7), R_HIGH, L_POINT, BK),
			_t(0.34, 0.38, -8, -20, Vector3(0, 0.7, -0.7), R_HIGH, L_POINT, BK),
			_t(0.42, 0.56, 6, 26, Vector3(0, -0.4, 0.9), R_DOWN, L_OPEN, L),
			_t(0.6, 0.54, 4, 22, Vector3(0, -0.5, 0.85), R_DOWN, L_OPEN, L),
			_t(0.9, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 4 Tatsumaki Age: çömelip yelpaze yerde -> doğrularak alttan yukarı savurur, burgu rakibi kaldırır
		{"len": 0.85, "hit": 0.4, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.18, 0.68, -14, 20, Vector3(0, -0.6, 0.6), R_LOW, L_OPEN, BK),
			_t(0.32, 0.7, -16, 22, Vector3(0, -0.6, 0.6), R_LOW, L_OPEN, BK),
			_t(0.4, 0.22, 8, -14, Vector3(0, 0.95, 0.3), R_UP, L_GUARD, L),
			_t(0.58, 0.2, 6, -16, Vector3(0, 0.95, 0.2), R_UP, L_GUARD, L),
			_t(0.85, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 5 Senpū: yelpaze yana açık, gövde tam tur döner -> çevreye kasırga halkası
		{"len": 1.0, "hit": 0.5, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.16, 0.42, -30, 4, Vector3(-0.9, 0.3, 0.3), R_SWEEP_R, L_OPEN, BK),
			_t(0.34, 0.44, 60, 6, Vector3(-0.9, 0.3, 0.3), R_SWEEP_R, L_OPEN, CR),
			_t(0.52, 0.44, 170, 8, Vector3(-0.9, 0.3, 0.3), R_SWEEP_R, L_OPEN, W),
			_t(0.72, 0.42, 30, 6, Vector3(-0.7, 0.4, 0.6), R_SWEEP_R, L_OPEN, ST),
			_t(1.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 6 Bashō Tenpū (bitiriş): iki elle baş üstünde kurulur (uzun bekleme, rüzgâr toplanır) -> öne dev darbe, uzun fırtına koridoru
		{"len": 1.3, "hit": 0.66, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.22, 0.36, -4, -22, Vector3(0, 0.7, -0.7), R_HIGH, L_HIGH, BK),
			_t(0.56, 0.38, -6, -26, Vector3(0, 0.65, -0.75), R_HIGH, L_HIGH, BK),
			_t(0.66, 0.58, 6, 30, Vector3(0, 0.0, 1.0), R_DOWN, L_POINT, L),
			_t(0.95, 0.56, 4, 24, Vector3(0, -0.2, 0.98), R_DOWN, L_POINT, L),
			_t(1.3, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
	]
