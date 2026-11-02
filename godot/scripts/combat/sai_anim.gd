extends RefCounted
## Sai kombosu (çift el, sai.png): çevik savunma silahı — kısa kurulma, hızlı saplama; yan dişlerle kilitleme, topuzla ters
## vuruş, çift saplama. "blade": sağ sai yönü (sağ bilek buna çevrilir); sol sai sol kol pozuyla gider.

const S = preload("res://scripts/combat/samehada_anim.gd")

const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.2, 0.3, 0.93)}      # sol sai önde, gard
const L_COCK := {"LeftUpperArm": Vector3(0.6, -0.55, -0.55), "LeftLowerArm": Vector3(0.1, 0.4, 0.9)}
const L_STAB := {"LeftUpperArm": Vector3(0.08, 0.0, 1), "LeftLowerArm": Vector3(0.0, 0.0, 1)}              # düz ileri saplama
const L_LOW := {"LeftUpperArm": Vector3(0.35, -0.9, 0.2), "LeftLowerArm": Vector3(0.1, -0.6, 0.8)}
const L_HIGH := {"LeftUpperArm": Vector3(0.35, 0.85, 0.35), "LeftLowerArm": Vector3(0.1, 0.95, 0.2)}       # başın üstünde
const L_DOWN_STAB := {"LeftUpperArm": Vector3(0.15, -0.3, 0.94), "LeftLowerArm": Vector3(0.0, -0.75, 0.66)}
const L_CROSS := {"LeftUpperArm": Vector3(-0.3, -0.1, 0.95), "LeftLowerArm": Vector3(-0.9, 0.3, 0.2)}
const L_OPEN := {"LeftUpperArm": Vector3(0.95, -0.1, 0.3), "LeftLowerArm": Vector3(0.85, -0.2, 0.5)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.3, lean * 1.2, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	return [
		# 1 Sol saplama: sol sai geri çekilir -> düz ileri saplar; sağ sai gardda
		{"len": 0.5, "hit": 0.2, "keys": [
			_t(0.0, 0.35, 0, 4, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
			_t(0.1, 0.38, 16, 0, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_COCK, W),
			_t(0.14, 0.38, 17, 0, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_COCK, W),
			_t(0.2, 0.44, -16, 16, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_STAB, L),
			_t(0.5, 0.38, -4, 6, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
		]},
		# 2 Sağ saplama: sağ geri -> ileri
		{"len": 0.5, "hit": 0.2, "keys": [
			_t(0.0, 0.38, -4, 6, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
			_t(0.1, 0.4, -20, 0, Vector3(0.0, 0.1, 1.0), S.H_HIP_SIDE, L_GUARD, W),
			_t(0.14, 0.4, -21, 0, Vector3(0.0, 0.1, 1.0), S.H_HIP_SIDE, L_GUARD, W),
			_t(0.2, 0.46, 16, 16, Vector3(0.0, 0.0, 1.0), S.H_FWD, L_GUARD, L),
			_t(0.5, 0.38, 4, 6, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
		]},
		# 3 Kilit ve Çekiş: iki sai yukarıda çaprazlanıp rakibin kolunu/silahını yan dişlere alır -> aşağı-geri çekip dengesini bozar
		{"len": 0.65, "hit": 0.26, "keys": [
			_t(0.0, 0.38, 4, 6, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
			_t(0.14, 0.38, 0, 4, Vector3(0.3, 0.5, 0.8), S.H_LSHOULDER, L_CROSS, W),
			_t(0.22, 0.4, 0, 6, Vector3(0.3, 0.55, 0.78), S.H_LSHOULDER, L_CROSS, W),
			_t(0.3, 0.55, 0, -14, Vector3(-0.2, -0.4, 0.9), S.H_HIP_FRONT, L_LOW, W),
			_t(0.65, 0.42, 0, 4, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
		]},
		# 4 Topuz Darbesi: sai elde ters çevrilir (kol geri kalkar), topuzla yukarıdan aşağı çakar
		{"len": 0.6, "hit": 0.28, "keys": [
			_t(0.0, 0.42, 0, 4, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
			_t(0.14, 0.38, -18, -8, Vector3(0.0, -0.9, -0.4), S.H_ABOVE, L_GUARD, W),
			_t(0.22, 0.38, -19, -9, Vector3(0.0, -0.9, -0.4), S.H_ABOVE, L_GUARD, W),
			_t(0.28, 0.6, 10, 26, Vector3(0.0, -0.3, -0.95), S.H_FOREHEAD, L_GUARD, L),
			_t(0.6, 0.42, 4, 6, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
		]},
		# 5 Yükselen Çift: iki sai alçakta kurulur -> ikisi birden aşağıdan yukarı saplar (rakip havaya)
		{"len": 0.6, "hit": 0.28, "keys": [
			_t(0.0, 0.42, 4, 6, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
			_t(0.14, 0.68, 0, 22, Vector3(0.0, -0.6, 0.8), S.H_LOW_FRONT, L_LOW, W),
			_t(0.22, 0.7, 0, 23, Vector3(0.0, -0.6, 0.8), S.H_LOW_FRONT, L_LOW, W),
			_t(0.28, 0.3, 0, -10, Vector3(0.0, 0.85, 0.5), S.H_FOREHEAD, L_HIGH, L),
			_t(0.6, 0.38, 0, 4, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
		]},
		# 6 Çift Delik (bitiriş): iki sai başın üstüne kalkar (gövde geriye) -> atılıp ikisini birden öne-aşağı saplar
		{"len": 0.85, "hit": 0.42, "keys": [
			_t(0.0, 0.38, 0, 4, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
			_t(0.18, 0.32, 0, -14, Vector3(0.0, 0.9, -0.4), S.H_UP, L_HIGH, W),
			_t(0.34, 0.33, 0, -16, Vector3(0.0, 0.88, -0.45), S.H_UP, L_HIGH, W),
			_t(0.42, 0.7, 6, 34, Vector3(0.0, -0.45, 0.89), S.H_LOW_FRONT, L_DOWN_STAB, L),
			_t(0.85, 0.42, 0, 8, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
		]},
	]
