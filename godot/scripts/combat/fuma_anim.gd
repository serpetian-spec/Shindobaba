extends RefCounted
## Fūma Shuriken (ref fuumashuriken.png / acilmishali.png): UZUN MENZİL. Sağ el göbek halkasını kavrar; atışta bıçaklar açılır,
## shuriken dönerek hedefe uçar ve ele döner (KeyedCombos._spin_throw). Ağır silah ritmi: geri kurulur -> bekler -> hızlı bırakır -> takip.
## 1 düz atış, 2 yandan yay, 3 sıçrayıp yukarıdan, 4 elde dönen biçme, 5 Kage Fūsha (gölgede ikinci), 6 hedef çevresinde fırtına.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.3, -0.85, 0.35), "RightLowerArm": Vector3(0.1, -0.2, 0.97)}
const R_BACK := {"RightUpperArm": Vector3(-0.6, 0.35, -0.7), "RightLowerArm": Vector3(-0.2, 0.6, -0.75)}       # omuzun arkasına kurulmuş
const R_THROW := {"RightUpperArm": Vector3(-0.05, 0.15, 1), "RightLowerArm": Vector3(0.05, 0.05, 1)}           # öne bırakış
const R_SIDE := {"RightUpperArm": Vector3(0.6, -0.1, 0.4), "RightLowerArm": Vector3(0.95, 0.0, 0.3)}           # sol yana sarılmış (yan atış kurulumu)
const R_WIDE := {"RightUpperArm": Vector3(-0.95, 0.0, 0.3), "RightLowerArm": Vector3(-0.9, 0.0, 0.45)}         # sağa açık bırakış
const R_OVER := {"RightUpperArm": Vector3(-0.15, 0.95, 0.05), "RightLowerArm": Vector3(0.0, 0.9, -0.4)}        # baş üstü
const R_DOWN := {"RightUpperArm": Vector3(-0.1, -0.2, 0.98), "RightLowerArm": Vector3(0.0, -0.55, 0.85)}       # aşağı-öne bırakış
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.2, 0.3, 0.93)}
const L_POINT := {"LeftUpperArm": Vector3(0.15, 0.1, 1), "LeftLowerArm": Vector3(0.05, 0.05, 1)}
const L_BACK := {"LeftUpperArm": Vector3(0.5, -0.6, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}
const L_WIDE := {"LeftUpperArm": Vector3(0.95, -0.15, 0.2), "LeftLowerArm": Vector3(0.85, -0.2, 0.45)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.0, 0.2, 0.98)
	return [
		# 1 Fūma Nage: kol omuz arkasına kurulur, gövde burulur (bekle) -> adımla öne düz bırakış -> takip, ele dönüşü karşılar
		{"len": 0.95, "hit": 0.36, "keys": [
			_t(0.0, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.16, 0.38, -30, -10, Vector3(0, 0.3, -0.95), R_BACK, L_POINT, BK),
			_t(0.3, 0.4, -34, -12, Vector3(0, 0.3, -0.95), R_BACK, L_POINT, BK),
			_t(0.36, 0.42, 18, 18, Vector3(0, 0.1, 1), R_THROW, L_BACK, L),
			_t(0.55, 0.38, 10, 10, Vector3(0, 0.1, 1), R_THROW, L_BACK, L),
			_t(0.95, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 2 Kaiten Nage: kol sol kalçaya sarılır -> geniş yatay yan bırakış, shuriken yay çizip arkadan döner
		{"len": 1.0, "hit": 0.34, "keys": [
			_t(0.0, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.16, 0.42, 34, 6, Vector3(0.8, 0, 0.4), R_SIDE, L_BACK, CR),
			_t(0.28, 0.44, 38, 6, Vector3(0.8, 0, 0.4), R_SIDE, L_BACK, CR),
			_t(0.34, 0.42, -30, 4, Vector3(-0.9, 0, 0.4), R_WIDE, L_WIDE, ST),
			_t(0.6, 0.38, -20, 2, Vector3(-0.9, 0, 0.4), R_WIDE, L_WIDE, W),
			_t(1.0, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 3 Tobi Fūma: çömelip sıçrar, baş üstünden aşağı-öne bırakır (havadan iner)
		{"len": 1.0, "hit": 0.42, "jump": 6.0, "keys": [
			_t(0.0, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.12, 0.6, -8, 10, RDY, R_READY, L_GUARD, W),
			_t(0.26, 0.1, -10, -14, Vector3(0, 0.9, -0.3), R_OVER, L_WIDE, ST),
			_t(0.42, 0.2, 6, 30, Vector3(0, -0.6, 0.8), R_DOWN, L_BACK, ST),
			_t(0.7, 0.5, 4, 10, Vector3(0, -0.4, 0.9), R_DOWN, L_BACK, W),
			_t(1.0, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 4 Senpū Giri: açık shuriken elde, gövde iki tur döner (yakın çevre biçmesi, çoklu vuruş)
		{"len": 0.9, "hit": 0.3, "extra_hits": [0.42, 0.56], "extra_radius": 2.0, "keys": [
			_t(0.0, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.14, 0.44, 30, 4, Vector3(0.9, 0, 0.3), R_SIDE, L_WIDE, CR),
			_t(0.3, 0.46, -40, 6, Vector3(-0.9, 0, 0.3), R_WIDE, L_WIDE, W),
			_t(0.44, 0.46, 40, 6, Vector3(0.9, 0, 0.3), R_WIDE, L_WIDE, CR),
			_t(0.58, 0.46, -40, 6, Vector3(-0.9, 0, 0.3), R_WIDE, L_WIDE, W),
			_t(0.9, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 5 Kage Fūsha: geri kurulup tek atış görüntüsüyle iki shuriken bırakır; ikincisi ilkinin gölgesinde gizli
		{"len": 1.05, "hit": 0.4, "keys": [
			_t(0.0, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.18, 0.4, -36, -12, Vector3(0, 0.3, -0.95), R_BACK, L_BACK, BK),
			_t(0.34, 0.42, -40, -14, Vector3(0, 0.3, -0.95), R_BACK, L_BACK, BK),
			_t(0.4, 0.44, 22, 22, Vector3(0, 0.1, 1), R_THROW, L_POINT, L),
			_t(0.62, 0.4, 12, 12, Vector3(0, 0.1, 1), R_THROW, L_POINT, L),
			_t(1.05, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 6 Fūma Arashi (bitiriş): baş üstünde döndürüp hız kazanır (iki tur), sonra fırlatır: hedefin çevresinde dört tur biçer, döner
		{"len": 1.4, "hit": 0.78, "keys": [
			_t(0.0, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.2, 0.36, -20, -4, Vector3(0, 0.95, 0.2), R_OVER, L_WIDE, W),
			_t(0.42, 0.38, 24, -4, Vector3(0, 0.95, 0.2), R_OVER, L_WIDE, CR),
			_t(0.62, 0.4, -36, -12, Vector3(0, 0.3, -0.95), R_BACK, L_POINT, BK),
			_t(0.72, 0.42, -40, -14, Vector3(0, 0.3, -0.95), R_BACK, L_POINT, BK),
			_t(0.78, 0.46, 24, 24, Vector3(0, 0.1, 1), R_THROW, L_BACK, L),
			_t(1.0, 0.42, 14, 14, Vector3(0, 0.1, 1), R_THROW, L_BACK, L),
			_t(1.4, 0.3, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
	]
