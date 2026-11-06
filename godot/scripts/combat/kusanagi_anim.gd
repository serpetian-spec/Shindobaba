extends RefCounted
## Kusanagi no Tsurugi (ref kusanagi.png, muhafızsız düz kılıç): tek el, HIZLI kılıç (Sasuke tarzı). Uçma/uzama YOK.
## Kombo: akıcı kesikler + Shunshin saplama + kesik yağmuru sonunda Chidori Nagashi (yere saplama) + iai geçiş bitirişi.
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
const R_PLANT := {"RightUpperArm": Vector3(-0.15, -0.6, 0.78), "RightLowerArm": Vector3(0.0, -0.9, 0.4)}       # kılıç önde yere saplı (Chidori Nagashi)
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.2, 0.3, 0.93)}
const L_BACK := {"LeftUpperArm": Vector3(0.55, -0.6, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}
const L_SEAL := {"LeftUpperArm": Vector3(0.25, -0.6, 0.75), "LeftLowerArm": Vector3(-0.6, 0.65, 0.45)}
const L_POINT := {"LeftUpperArm": Vector3(0.15, 0.05, 1), "LeftLowerArm": Vector3(0.05, 0.0, 1)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	# HIZLI KILIÇ (ref kusanagi.png, muhafızsız düz kılıç): kısa geri çekiş -> şimşek kesik -> hemen sonraki kesiğe akış.
	# 1 çapraz iniş, 2 ters yatay, 3 uzayan saplama (Chōtō), 4 yükselen kesik (kaldırır), 5 kesik yağmuru + uçan kılıç, 6 iai bitiriş (uzar)
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.1, -0.35, 0.93)
	return [
		# 1 Kesa: sağ omzun üstüne kısa kalkış -> çapraz şimşek iniş
		{"len": 0.5, "hit": 0.22, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.12, 0.38, -18, -8, Vector3(-0.2, 0.8, -0.5), R_HIGH, L_GUARD, BK),
			_t(0.22, 0.46, 16, 18, Vector3(0.6, -0.6, 0.5), R_LOWEND, L_BACK, L),
			_t(0.32, 0.44, 18, 16, Vector3(0.65, -0.65, 0.4), R_LOWEND, L_BACK, L),
			_t(0.5, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 2 Gyaku: sol omuz önünden ters yatay kesik sağa
		{"len": 0.5, "hit": 0.2, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.1, 0.4, 26, -4, Vector3(0.8, 0.2, 0.5), R_LEFT, L_GUARD, CR),
			_t(0.2, 0.44, -24, 14, Vector3(-0.9, 0.1, 0.4), R_WIDE, L_POINT, ST),
			_t(0.3, 0.42, -28, 12, Vector3(-0.95, 0.05, 0.3), R_WIDE, L_POINT, W),
			_t(0.5, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 3 Chōtō Tsuki: dirsek geride -> uzun adımla saplama, ağız bir anda uzar
		{"len": 0.7, "hit": 0.3, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.14, 0.42, -16, -6, Vector3(0, 0.05, 1), R_CHAMBER, L_POINT, BK),
			_t(0.24, 0.44, -18, -8, Vector3(0, 0.05, 1), R_CHAMBER, L_POINT, BK),
			_t(0.3, 0.52, 10, 22, Vector3(0, 0.0, 1), R_STAB, L_BACK, L),
			_t(0.48, 0.5, 8, 18, Vector3(0, 0.0, 1), R_STAB, L_BACK, L),
			_t(0.7, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 4 Kiri Age: alçakta -> yükselen kesik (havaya kaldırır)
		{"len": 0.55, "hit": 0.26, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.12, 0.58, -14, 16, Vector3(0, -0.7, 0.7), R_LOW, L_GUARD, BK),
			_t(0.26, 0.26, 8, -12, Vector3(0, 0.95, 0.3), R_UP, L_BACK, L),
			_t(0.36, 0.24, 6, -14, Vector3(0, 0.95, 0.25), R_UP, L_BACK, L),
			_t(0.55, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 5 Ranbu: art arda dört hızlı kesik (çapraz-yatay-çapraz-yatay), sonunda kılıç elden uçup hedefin çevresinde döner
		{"len": 1.15, "hit": 0.2, "extra_hits": [0.34, 0.48, 0.62, 0.8], "extra_radius": 1.6, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.1, 0.4, -18, -6, Vector3(-0.2, 0.8, -0.5), R_HIGH, L_GUARD, BK),
			_t(0.2, 0.46, 16, 16, Vector3(0.6, -0.6, 0.5), R_LOWEND, L_GUARD, ST),
			_t(0.34, 0.44, -22, 12, Vector3(-0.9, 0.1, 0.4), R_WIDE, L_GUARD, LL),
			_t(0.48, 0.46, 18, 16, Vector3(0.6, -0.6, 0.5), R_LOWEND, L_GUARD, L),
			_t(0.62, 0.44, -24, 12, Vector3(-0.9, 0.1, 0.4), R_WIDE, L_GUARD, ST),
			_t(0.76, 0.6, 0, 24, Vector3(0, -0.95, 0.3), R_PLANT, L_SEAL, L),
			_t(0.9, 0.62, 0, 26, Vector3(0, -0.95, 0.3), R_PLANT, L_SEAL, L),
			_t(1.05, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 6 Iai Chōtō (bitiriş): kılıç sol kalçaya çekilir (kın tutuşu, bekle) -> şimşek yatay iai, ağız uzayıp geniş biçer
		{"len": 1.0, "hit": 0.44, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.16, 0.5, 26, 10, Vector3(0.8, -0.4, -0.3), R_LOWEND, L_SEAL, CR),
			_t(0.4, 0.52, 30, 12, Vector3(0.8, -0.4, -0.3), R_LOWEND, L_SEAL, CR),
			_t(0.44, 0.5, -20, 16, Vector3(-0.9, 0.1, 0.4), R_WIDE, L_BACK, L),
			_t(0.62, 0.48, -30, 14, Vector3(-0.95, 0.05, 0.3), R_WIDE, L_BACK, L),
			_t(1.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
	]
