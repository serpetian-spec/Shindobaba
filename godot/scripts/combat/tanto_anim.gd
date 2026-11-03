extends RefCounted
## Tantō — ANBU suikastçı kısa kılıcı: kısa, sessiz, yakın; saplama-burma, bacak kesme, boğaz kesme. Uzun kurulum yok, kısa geri çekiş.
## 1 Gyaku Giri: ters (sırt eli) yatay kesik, 2 Tsuki Hineri: saplayıp burma (kanama), 3 Ashi Kiri: yere çöküp baldır kesme (yavaşlatır),
## 4 Kubi Kaki: sol el yakayı tutar, sağ el boğaz hizasından keser, 5 Kaiten Tsuki: sırtını dönüp tam tur, dönüş sonunda saplama,
## 6 Hakkō Tsuki (bitiriş): sol el ağzın üstünden geçer, ağız beyaz chakra ile parlar -> bekle -> şimşek hızında uzun saplama, beyaz ışık çizgisi.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.25, -0.8, 0.55), "RightLowerArm": Vector3(0.25, -0.1, 0.96)}
const R_LEFT := {"RightUpperArm": Vector3(0.25, -0.2, 0.95), "RightLowerArm": Vector3(0.9, 0.15, 0.4)}          # sol omuz önünde (ters için)
const R_WIDE := {"RightUpperArm": Vector3(-0.95, -0.1, 0.3), "RightLowerArm": Vector3(-0.85, -0.2, 0.5)}
const R_CHAMBER := {"RightUpperArm": Vector3(-0.3, -0.6, -0.75), "RightLowerArm": Vector3(-0.05, -0.05, 1)}
const R_STAB := {"RightUpperArm": Vector3(-0.04, -0.05, 1), "RightLowerArm": Vector3(0.0, -0.03, 1)}
const R_LOW := {"RightUpperArm": Vector3(-0.6, -0.75, 0.25), "RightLowerArm": Vector3(-0.5, -0.6, 0.6)}
const R_LOW_IN := {"RightUpperArm": Vector3(0.3, -0.85, 0.45), "RightLowerArm": Vector3(0.75, -0.55, 0.35)}
const R_THROAT := {"RightUpperArm": Vector3(-0.6, 0.15, 0.78), "RightLowerArm": Vector3(-0.4, 0.3, 0.86)}       # sağda boyun hizası
const R_THROAT_END := {"RightUpperArm": Vector3(0.35, 0.2, 0.9), "RightLowerArm": Vector3(0.9, 0.25, 0.3)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.2, 0.3, 0.93)}
const L_BACK := {"LeftUpperArm": Vector3(0.55, -0.6, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}
const L_GRAB := {"LeftUpperArm": Vector3(0.1, 0.1, 1), "LeftLowerArm": Vector3(0.0, 0.15, 1)}               # yakayı tutar
const L_OVER := {"LeftUpperArm": Vector3(-0.2, -0.3, 0.93), "LeftLowerArm": Vector3(-0.7, 0.2, 0.68)}        # ağzın üstünden geçen el


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0, 0.1, 1)
	return [
		{"len": 0.45, "hit": 0.18, "keys": [
			_t(0.0, 0.42, 0, 8, RDY, R_READY, L_GUARD, W),
			_t(0.09, 0.46, 30, 0, Vector3(0.8, 0.1, 0.5), R_LEFT, L_GUARD, CR),
			_t(0.18, 0.5, -26, 16, Vector3(-0.9, 0.1, 0.4), R_WIDE, L_BACK, ST),
			_t(0.28, 0.48, -30, 14, Vector3(-0.95, 0.05, 0.3), R_WIDE, L_BACK, W),
			_t(0.45, 0.42, 0, 8, RDY, R_READY, L_GUARD, W),
		]},
		{"len": 0.6, "hit": 0.2, "keys": [
			_t(0.0, 0.42, 0, 8, RDY, R_READY, L_GUARD, W),
			_t(0.1, 0.46, -16, -4, Vector3(0, 0.05, 1), R_CHAMBER, L_GUARD, BK),
			_t(0.2, 0.54, 12, 22, Vector3(0, 0.0, 1), R_STAB, L_GUARD, L),
			_t(0.3, 0.54, 22, 22, Vector3(0.3, 0.0, 0.95), R_STAB, L_GUARD, L),   # burma
			_t(0.4, 0.52, -6, 18, Vector3(-0.3, 0.0, 0.95), R_STAB, L_GUARD, L),
			_t(0.6, 0.42, 0, 8, RDY, R_READY, L_GUARD, W),
		]},
		{"len": 0.6, "hit": 0.26, "keys": [
			_t(0.0, 0.42, 0, 8, RDY, R_READY, L_GUARD, W),
			_t(0.12, 0.86, -26, 34, Vector3(-0.8, -0.5, 0.3), R_LOW, L_GUARD, W),
			_t(0.26, 0.88, 26, 34, Vector3(0.8, -0.5, 0.3), R_LOW_IN, L_BACK, W),
			_t(0.36, 0.86, 30, 32, Vector3(0.8, -0.5, 0.3), R_LOW_IN, L_BACK, W),
			_t(0.6, 0.42, 0, 8, RDY, R_READY, L_GUARD, W),
		]},
		{"len": 0.7, "hit": 0.36, "keys": [
			_t(0.0, 0.42, 0, 8, RDY, R_READY, L_GUARD, W),
			_t(0.14, 0.48, -10, 16, Vector3(-0.8, 0.2, 0.5), R_THROAT, L_GRAB, L),
			_t(0.28, 0.5, -12, 18, Vector3(-0.8, 0.2, 0.5), R_THROAT, L_GRAB, L),
			_t(0.36, 0.5, 26, 18, Vector3(0.9, 0.2, 0.3), R_THROAT_END, L_GRAB, L),
			_t(0.5, 0.46, 30, 10, Vector3(0.9, 0.2, 0.3), R_THROAT_END, L_BACK, BK),
			_t(0.7, 0.42, 0, 8, RDY, R_READY, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.46, "keys": [
			_t(0.0, 0.42, 0, 8, RDY, R_READY, L_GUARD, W),
			_t(0.14, 0.5, 120, 6, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_BACK, CR),
			_t(0.3, 0.52, 250, 8, Vector3(0, 0.05, 1), R_CHAMBER, L_BACK, W),
			_t(0.4, 0.52, 340, 10, Vector3(0, 0.05, 1), R_CHAMBER, L_GUARD, ST),
			_t(0.46, 0.56, 360, 24, Vector3(0, 0.0, 1), R_STAB, L_BACK, L),
			_t(0.6, 0.54, 360, 22, Vector3(0, 0.0, 1), R_STAB, L_BACK, L),
			_t(0.75, 0.42, 360, 8, RDY, R_READY, L_GUARD, W),
		]},
		{"len": 1.2, "hit": 0.74, "keys": [
			_t(0.0, 0.42, 0, 8, RDY, R_READY, L_GUARD, W),
			_t(0.2, 0.56, -14, 4, Vector3(0, 0.05, 1), R_CHAMBER, L_OVER, BK),
			_t(0.66, 0.6, -16, 2, Vector3(0, 0.05, 1), R_CHAMBER, L_OVER, BK),
			_t(0.74, 0.62, 10, 34, Vector3(0, 0.0, 1), R_STAB, L_BACK, L),
			_t(0.95, 0.6, 8, 30, Vector3(0, 0.0, 1), R_STAB, L_BACK, L),
			_t(1.2, 0.42, 0, 8, RDY, R_READY, L_GUARD, W),
		]},
	]
