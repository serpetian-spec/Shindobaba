extends RefCounted
## Kusanagi no Tsurugi (orochikusanagi.png, Orochimaru): tek el, hafif-orta, yılan gibi akıcı. Kanon: ağız bir anda uzar (Chōtō),
## kılıç uzaktan yönetilip hedefe uçar ve döner. Kombo: akıcı kesikler + uzayan saplama + uçan kılıç + uzayan geniş biçme.
## Her vuruşta geri çekiş ve ayak işi (BK -> ST -> L/LL -> W). Uzama/uçuş etkileri KeyedCombos (oyuncu + düşman).

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.2, -0.85, 0.45), "RightLowerArm": Vector3(0.2, -0.3, 0.93)}
const R_HIGH := {"RightUpperArm": Vector3(-0.5, 0.65, -0.55), "RightLowerArm": Vector3(-0.1, 0.9, 0.4)}       # sağ omzun üstü-arkası
const R_LOWEND := {"RightUpperArm": Vector3(0.25, -0.5, 0.82), "RightLowerArm": Vector3(0.85, -0.3, 0.4)}     # sol kalçaya inmiş
const R_LEFT := {"RightUpperArm": Vector3(0.2, -0.1, 0.97), "RightLowerArm": Vector3(0.9, 0.2, 0.35)}         # sol omuz önünde (ters için)
const R_WIDE := {"RightUpperArm": Vector3(-0.95, -0.1, 0.3), "RightLowerArm": Vector3(-0.85, -0.2, 0.5)}
const R_CHAMBER := {"RightUpperArm": Vector3(-0.3, -0.6, -0.75), "RightLowerArm": Vector3(-0.05, -0.05, 1)}
const R_STAB := {"RightUpperArm": Vector3(-0.04, -0.03, 1), "RightLowerArm": Vector3(0.0, -0.02, 1)}
const R_LOW := {"RightUpperArm": Vector3(-0.35, -0.9, 0.2), "RightLowerArm": Vector3(-0.1, -0.6, 0.8)}
const R_UP := {"RightUpperArm": Vector3(-0.15, 0.7, 0.7), "RightLowerArm": Vector3(0.0, 0.95, 0.3)}
const R_THROW := {"RightUpperArm": Vector3(-0.1, 0.25, 0.96), "RightLowerArm": Vector3(0.0, 0.2, 0.98)}       # kol öne uzanmış, el açık yönetir
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.2, 0.3, 0.93)}
const L_BACK := {"LeftUpperArm": Vector3(0.55, -0.6, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}
const L_SEAL := {"LeftUpperArm": Vector3(0.25, -0.6, 0.75), "LeftLowerArm": Vector3(-0.6, 0.65, 0.45)}
const L_POINT := {"LeftUpperArm": Vector3(0.15, 0.05, 1), "LeftLowerArm": Vector3(0.05, 0.0, 1)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.1, -0.35, 0.93)
	return [
		# 1 Yılan Dişi: kılıç sağ omzun arkasına kalkar, ağırlık geride -> adımla çapraz aşağı keser
		{"len": 0.55, "hit": 0.26, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.12, 0.38, -26, -8, Vector3(-0.3, 0.85, -0.42), R_HIGH, L_POINT, BK),
			_t(0.19, 0.39, -28, -9, Vector3(-0.3, 0.84, -0.44), R_HIGH, L_POINT, BK),
			_t(0.23, 0.38, -10, 4, Vector3(-0.1, 0.5, 0.86), R_HIGH, L_POINT, ST),
			_t(0.26, 0.46, 16, 18, Vector3(0.55, -0.55, 0.62), R_LOWEND, L_BACK, L),
			_t(0.55, 0.36, 6, 6, RDY, R_READY, L_GUARD, W),
		]},
		# 2 Ters Kıvrım: sol omuz önüne sarılır (gövde sola burulu) -> yılan gibi kıvrılıp sağa yatay ters keser
		{"len": 0.55, "hit": 0.27, "keys": [
			_t(0.0, 0.36, 6, 6, RDY, R_READY, L_GUARD, W),
			_t(0.12, 0.4, 30, 0, Vector3(0.9, 0.1, -0.4), R_LEFT, L_BACK, CR),
			_t(0.2, 0.4, 32, -1, Vector3(0.88, 0.12, -0.45), R_LEFT, L_BACK, CR),
			_t(0.27, 0.45, -20, 14, Vector3(-0.95, 0.0, 0.3), R_WIDE, L_POINT, LL),
			_t(0.55, 0.36, -6, 6, RDY, R_READY, L_GUARD, W),
		]},
		# 3 Chōtō (uzayan saplama): hazneye çekilir -> saplarken ağız bir anda uzar (on_start/on_strike), geri kısalır
		{"len": 0.75, "hit": 0.32, "keys": [
			_t(0.0, 0.36, -6, 6, RDY, R_READY, L_GUARD, W),
			_t(0.14, 0.42, -24, -10, Vector3(0, -0.02, 1), R_CHAMBER, L_SEAL, BK),
			_t(0.24, 0.43, -26, -12, Vector3(0, -0.02, 1), R_CHAMBER, L_SEAL, BK),
			_t(0.28, 0.4, -10, 2, Vector3(0, -0.02, 1), R_CHAMBER, L_SEAL, ST),
			_t(0.32, 0.55, 16, 24, Vector3(0, -0.03, 1), R_STAB, L_BACK, L),
			_t(0.5, 0.55, 16, 24, Vector3(0, -0.03, 1), R_STAB, L_BACK, L),
			_t(0.75, 0.36, 0, 6, RDY, R_READY, L_GUARD, W),
		]},
		# 4 Yükselen Yılan: çömelip alçakta kurulur -> yukarı biçer (havaya)
		{"len": 0.6, "hit": 0.3, "keys": [
			_t(0.0, 0.36, 0, 6, RDY, R_READY, L_GUARD, W),
			_t(0.14, 0.68, -16, 20, Vector3(-0.3, -0.85, 0.42), R_LOW, L_BACK, W),
			_t(0.24, 0.7, -17, 21, Vector3(-0.3, -0.85, 0.42), R_LOW, L_BACK, W),
			_t(0.3, 0.28, 10, -10, Vector3(0.1, 0.9, 0.4), R_UP, L_POINT, L),
			_t(0.6, 0.36, 2, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 5 Uçan Kusanagi: kol öne uzanır, kılıç elden fırlar, hedefin çevresinde uçup saplar ve ele döner (uzaktan yönetim)
		{"len": 1.1, "hit": 0.3, "keys": [
			_t(0.0, 0.36, 2, 4, RDY, R_READY, L_GUARD, W),
			_t(0.14, 0.4, -18, -8, Vector3(0, 0.05, 1), R_CHAMBER, L_SEAL, BK),
			_t(0.24, 0.42, -20, -10, Vector3(0, 0.05, 1), R_CHAMBER, L_SEAL, BK),
			_t(0.3, 0.45, 12, 14, Vector3(0, 0.1, 1), R_THROW, L_SEAL, L),
			_t(0.8, 0.45, 8, 12, Vector3(0, 0.1, 1), R_THROW, L_SEAL, L),
			_t(1.1, 0.36, 0, 6, RDY, R_READY, L_GUARD, W),
		]},
		# 6 Yamata Biçmesi (bitiriş): kılıç başın üstünden sağ-arkaya kurulur (uzun duraksama) -> ağız uzayarak çok geniş yatay biçer
		{"len": 1.05, "hit": 0.5, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.2, 0.4, -34, -10, Vector3(-0.85, 0.3, -0.45), R_WIDE, L_SEAL, BK),
			_t(0.38, 0.42, -40, -14, Vector3(-0.7, 0.3, -0.65), R_WIDE, L_SEAL, BK),
			_t(0.44, 0.42, -42, -15, Vector3(-0.68, 0.3, -0.67), R_WIDE, L_SEAL, BK),
			_t(0.5, 0.5, 10, 18, Vector3(0.0, 0.05, 1.0), R_STAB, L_BACK, L),
			_t(0.58, 0.52, 42, 20, Vector3(0.95, 0.05, 0.3), R_LEFT, L_BACK, L),
			_t(0.75, 0.48, 50, 14, Vector3(0.75, 0.0, -0.65), R_LEFT, L_BACK, L),
			_t(1.05, 0.36, 10, 6, RDY, R_READY, L_GUARD, W),
		]},
	]
