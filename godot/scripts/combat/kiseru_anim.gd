extends RefCounted
## Hōmatsu Kiseru (Utakata'nın kabarcık borusu) kombosu: orta menzil. Dar ağızlık AĞIZDA (BLOW pozu taramayla bulundu: ağızlık-ağız
## ~2 cm), sol el borunun ortasında (iki el). Her üfleme: nefes alma (gövde geri, göğüs kalkar, omuz yukarı) -> üfleme (gövde öne,
## yanaklar...) ; kabarcıklar çandan çıkıp hedefe süzülür (KeyedCombos.on_strike). 3. vuruş boruyla yakın darbe.

const S = preload("res://scripts/combat/samehada_anim.gd")

# üfleme pozu (mouth_scan3: üst kol / ön kol / boru yönü)
const R_BLOW := {"RightUpperArm": Vector3(0.209, -0.262, 0.942), "RightLowerArm": Vector3(0.517, 0.776, 0.362)}
const BLOW := Vector3(-0.3, -0.45, 0.84)
const L_TUBE := {"LeftUpperArm": Vector3(0.25, -0.75, 0.6), "LeftLowerArm": Vector3(-0.3, 0.1, 0.95)}   # sol el boruyu alttan tutar (IK sapa taşır)
# boru darbesi (çan ucuyla vuruş)
const R_SWING_BACK := {"RightUpperArm": Vector3(-0.6, 0.6, -0.5), "RightLowerArm": Vector3(-0.2, 0.9, -0.4)}
const R_SWING_END := {"RightUpperArm": Vector3(0.25, -0.4, 0.88), "RightLowerArm": Vector3(0.85, -0.3, 0.4)}
const L_FREE := {"LeftUpperArm": Vector3(0.55, -0.6, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.3, lean * 1.2, blade.normalized(), S._a(r, l), legs)


## nefes al -> üfle (yaw: gövdenin baktığı yan, kabarcık akışının yönünü verir)
static func _blow(t0: float, inhale: float, blow: float, yaw: float, legs_in: Dictionary, legs_out: Dictionary, end: float) -> Array:
	return [
		_t(t0, 0.3, yaw * 0.5, 0, BLOW, R_BLOW, L_TUBE, legs_in),
		_t(t0 + inhale, 0.28, yaw * 0.6, -10, BLOW, R_BLOW, L_TUBE, legs_in),         # nefes: gövde geri, göğüs kalkar
		_t(t0 + inhale + 0.05, 0.28, yaw * 0.6, -11, BLOW, R_BLOW, L_TUBE, legs_in),
		_t(t0 + inhale + 0.12, 0.36, yaw, 10, BLOW, R_BLOW, L_TUBE, legs_out),        # üfle: gövde öne
		_t(t0 + inhale + blow, 0.36, yaw, 12, BLOW, R_BLOW, L_TUBE, legs_out),
		_t(end, 0.32, yaw * 0.5, 2, BLOW, R_BLOW, L_TUBE, S.LEG_WIDE),
	]


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	return [
		# 1 Köpük Akışı: kısa nefes, sürekli üfleme — küçük kabarcık seli hedefe süzülür
		{"len": 0.75, "hit": 0.3, "two": true, "keys": _blow(0.0, 0.16, 0.45, 0, BK, W, 0.75)},
		# 2 Patlayan Köpük: derin nefes, tek uzun üfleme — kocaman kabarcık yavaşça süzülüp hedefte patlar
		{"len": 0.9, "hit": 0.42, "two": true, "keys": _blow(0.0, 0.28, 0.5, -12, BK, L, 0.9)},
		# 3 Boru Darbesi: boru sağ omzun arkasına kalkar (ağırlık geride) -> çan ucuyla çapraz iner, çarpışta kabarcık patlar
		{"len": 0.7, "hit": 0.34, "two": false, "keys": [
			_t(0.0, 0.32, 0, 2, BLOW, R_BLOW, L_TUBE, W),
			_t(0.14, 0.36, -26, -10, Vector3(-0.2, 0.9, -0.4), R_SWING_BACK, L_FREE, BK),
			_t(0.24, 0.37, -28, -11, Vector3(-0.2, 0.88, -0.42), R_SWING_BACK, L_FREE, BK),
			_t(0.29, 0.38, -8, 4, Vector3(0.0, 0.6, 0.8), R_SWING_BACK, L_FREE, ST),
			_t(0.34, 0.5, 18, 20, Vector3(0.55, -0.55, 0.62), R_SWING_END, L_FREE, L),
			_t(0.7, 0.32, 4, 4, BLOW, R_BLOW, L_TUBE, W),
		]},
		# 4 Köpük Kafesi: yana dönüp üfler — dev kabarcık hedefi içine alır (hapseder)
		{"len": 0.85, "hit": 0.4, "two": true, "keys": _blow(0.0, 0.24, 0.45, 16, BK, W, 0.85)},
		# 5 Asit Yağmuru: başı geriye atıp yukarı üfler — kabarcıklar yay çizip hedefin üstüne düşer, aşındırır
		{"len": 0.85, "hit": 0.38, "two": true, "keys": [
			_t(0.0, 0.3, 0, 2, BLOW, R_BLOW, L_TUBE, W),
			_t(0.2, 0.26, 0, -18, BLOW, R_BLOW, L_TUBE, BK),
			_t(0.26, 0.26, 0, -20, BLOW, R_BLOW, L_TUBE, BK),
			_t(0.38, 0.3, 0, -12, BLOW, R_BLOW, L_TUBE, W),
			_t(0.6, 0.3, 0, -10, BLOW, R_BLOW, L_TUBE, W),
			_t(0.85, 0.32, 0, 2, BLOW, R_BLOW, L_TUBE, W),
		]},
		# 6 Köpük Seli (bitiriş): en derin nefes (gövde iyice geri, uzun duraksama) -> uzun, güçlü üfleme; kabarcık seli hedefi sarar,
		# hepsi zincirleme patlar
		{"len": 1.3, "hit": 0.5, "two": true, "keys": _blow(0.0, 0.36, 0.7, 0, BK, L, 1.3)},
	]
