extends RefCounted
## Yagura'nın kancalı sopası (Yagura tarzı): ortadan tutulan uzun sopa, iki ucu da silah. Sakin, kısa adımlı, sopayı bilek ve
## gövde dönüşüyle çeviren ritim; kancayla rakibin ayağını/boynunu yakalayıp çeker, iki ucuyla art arda vurur, su chakrası akıtır
## (KeyedCombos: su izi, su kalkanı, su dalgası).
## 1 kanca çekişi, 2 iki uçla art arda vuruş, 3 sopa çevirme (çark gibi döner, çoklu), 4 alçak süpürme + kancayla kaldırma,
## 5 su kalkanı + kancalı itme, 6 Suiro Kaiten (bitiriş): sopa yere saplanır, çevresinde su girdabı yükselir.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.3, -0.75, 0.55), "RightLowerArm": Vector3(0.3, 0.2, 0.93)}       # sopa önde çapraz
const R_HIGH := {"RightUpperArm": Vector3(-0.5, 0.65, -0.55), "RightLowerArm": Vector3(-0.1, 0.9, 0.4)}
const R_REACH := {"RightUpperArm": Vector3(-0.05, 0.1, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}
const R_PULL := {"RightUpperArm": Vector3(-0.35, -0.75, -0.55), "RightLowerArm": Vector3(-0.05, 0.1, 1)}
const R_WIDE := {"RightUpperArm": Vector3(-0.95, -0.05, 0.3), "RightLowerArm": Vector3(-0.85, -0.1, 0.5)}
const R_ACROSS := {"RightUpperArm": Vector3(0.3, -0.2, 0.92), "RightLowerArm": Vector3(0.9, 0.0, 0.4)}
const R_LOW := {"RightUpperArm": Vector3(-0.35, -0.9, 0.2), "RightLowerArm": Vector3(-0.1, -0.6, 0.8)}
const R_UP := {"RightUpperArm": Vector3(-0.1, 0.75, 0.65), "RightLowerArm": Vector3(0.0, 0.95, 0.3)}
const R_TWIRL := {"RightUpperArm": Vector3(-0.4, -0.2, 0.9), "RightLowerArm": Vector3(0.4, 0.5, 0.75)}          # göğüs önünde çevirme
const R_PLANT := {"RightUpperArm": Vector3(-0.15, -0.6, 0.78), "RightLowerArm": Vector3(0.0, -0.9, 0.4)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.2, 0.3, 0.93)}
const L_POINT := {"LeftUpperArm": Vector3(0.15, 0.05, 1), "LeftLowerArm": Vector3(0.05, 0.0, 1)}
const L_SEAL := {"LeftUpperArm": Vector3(0.2, -0.3, 0.93), "LeftLowerArm": Vector3(-0.6, 0.45, 0.66)}
const L_BACK := {"LeftUpperArm": Vector3(0.5, -0.6, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.3, lean * 1.2, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(-0.3, 0.55, 0.78)
	return [
		# 1 Kagi Hiki: üst kanca öne uzanır, rakibin boynuna takılır -> geri adımla kalçaya çekilir
		{"len": 0.85, "hit": 0.34, "keys": [
			_t(0.0, 0.32, 0, 2, RDY, R_READY, L_GUARD, W),
			_t(0.16, 0.36, -14, -6, Vector3(-0.2, 0.8, -0.5), R_HIGH, L_POINT, BK),
			_t(0.34, 0.44, 12, 18, Vector3(0, 0.1, 1), R_REACH, L_POINT, L),
			_t(0.5, 0.42, -8, -10, Vector3(0, 0.3, 0.95), R_PULL, L_BACK, BK),
			_t(0.85, 0.32, 0, 2, RDY, R_READY, L_GUARD, W),
		]},
		# 2 Ryōtan: üst uçla sağdan vuruş -> bilek çevrilir, alt (büyük kanca) uçla soldan ikinci vuruş
		{"len": 0.8, "hit": 0.26, "extra": [0.5], "extra_r": 1.6, "keys": [
			_t(0.0, 0.32, 0, 2, RDY, R_READY, L_GUARD, W),
			_t(0.12, 0.38, -26, -4, Vector3(-0.8, 0.4, 0.4), R_WIDE, L_GUARD, BK),
			_t(0.26, 0.42, 18, 12, Vector3(0.8, 0.3, 0.5), R_ACROSS, L_GUARD, ST),
			_t(0.38, 0.4, 28, 6, Vector3(0.6, -0.6, 0.5), R_ACROSS, L_GUARD, ST),
			_t(0.5, 0.44, -22, 14, Vector3(-0.7, -0.5, 0.5), R_WIDE, L_POINT, L),
			_t(0.8, 0.32, 0, 2, RDY, R_READY, L_GUARD, W),
		]},
		# 3 Sharin Mawashi: sopa göğüs önünde çark gibi döner (su izi), yürüyerek ilerler — çoklu vuruş
		{"len": 1.1, "hit": 0.22, "extra": [0.4, 0.58, 0.76], "extra_r": 1.8, "keys": [
			_t(0.0, 0.32, 0, 2, RDY, R_READY, L_GUARD, W),
			_t(0.16, 0.38, 0, 8, Vector3(0, 1, 0.1), R_TWIRL, L_GUARD, ST),
			_t(0.34, 0.38, 6, 8, Vector3(0, -0.1, 1), R_TWIRL, L_GUARD, W),
			_t(0.52, 0.4, -6, 10, Vector3(0, -1, 0.1), R_TWIRL, L_GUARD, ST),
			_t(0.7, 0.4, 6, 10, Vector3(0, 0.1, -1), R_TWIRL, L_GUARD, W),
			_t(0.88, 0.38, 0, 8, Vector3(0, 1, 0.1), R_TWIRL, L_GUARD, ST),
			_t(1.1, 0.32, 0, 2, RDY, R_READY, L_GUARD, W),
		]},
		# 4 Ashi Kagi: çömelip alt kancayla bacakları süpürür -> kancayla yukarı kaldırır (launch)
		{"len": 0.85, "hit": 0.42, "keys": [
			_t(0.0, 0.32, 0, 2, RDY, R_READY, L_GUARD, W),
			_t(0.14, 0.66, -22, 16, Vector3(-0.6, -0.5, 0.6), R_LOW, L_BACK, W),
			_t(0.28, 0.68, 22, 18, Vector3(0.6, -0.5, 0.6), R_LOW, L_BACK, CR),
			_t(0.42, 0.26, 4, -12, Vector3(0, 0.95, 0.3), R_UP, L_POINT, L),
			_t(0.85, 0.32, 0, 2, RDY, R_READY, L_GUARD, W),
		]},
		# 5 Suijinheki Tsuki: tek el mühür (su kalkanı önde yükselir) -> kalkanın içinden kancalı itme
		{"len": 1.0, "hit": 0.5, "keys": [
			_t(0.0, 0.32, 0, 2, RDY, R_READY, L_GUARD, W),
			_t(0.18, 0.36, 0, -4, RDY, R_READY, L_SEAL, W),
			_t(0.36, 0.38, 0, -6, RDY, R_READY, L_SEAL, W),
			_t(0.5, 0.48, 10, 20, Vector3(0, 0.1, 1), R_REACH, L_SEAL, L),
			_t(0.7, 0.44, 6, 14, Vector3(0, 0.1, 1), R_REACH, L_GUARD, L),
			_t(1.0, 0.32, 0, 2, RDY, R_READY, L_GUARD, W),
		]},
		# 6 Suiro Kaiten (bitiriş): sopa baş üstünde döner -> yere saplanır; çevresinde su girdabı yükselip herkesi savurur
		{"len": 1.4, "hit": 0.7, "keys": [
			_t(0.0, 0.32, 0, 2, RDY, R_READY, L_GUARD, W),
			_t(0.2, 0.34, -20, -8, Vector3(0, 0.95, 0.2), R_UP, L_SEAL, W),
			_t(0.42, 0.36, 24, -8, Vector3(0, 0.95, 0.2), R_UP, L_SEAL, CR),
			_t(0.6, 0.36, -10, -10, Vector3(0, 0.95, 0.2), R_UP, L_SEAL, W),
			_t(0.7, 0.62, 4, 26, Vector3(0, -0.95, 0.3), R_PLANT, L_SEAL, L),
			_t(1.05, 0.6, 2, 22, Vector3(0, -0.95, 0.3), R_PLANT, L_SEAL, L),
			_t(1.4, 0.32, 0, 2, RDY, R_READY, L_GUARD, W),
		]},
	]
