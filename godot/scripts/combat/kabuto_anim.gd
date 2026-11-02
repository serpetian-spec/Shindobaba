extends RefCounted
## Kabutowari kombosu (kaynak: kabuto1-4 pozları + kanon "miğfer kıran": çekiç baltanın sırtına kama gibi vurur).
## İKİ TARAF: sağ elde balta ("blade" yönü), sol elde çekiç (sol kol pozlarıyla savrulur). Ağır ritim her vuruşta:
## uzun geri çekiş (gövde ters burulur, geriye yaslanır) -> duraksama -> hızlı -> ağırlık bedeni sürükler -> yavaş toparlanma.
## Etkiler KeyedCombos.on_strike / mods (oyuncu + düşman aynı).

const S = preload("res://scripts/combat/samehada_anim.gd")

# sol el (çekiç) pozları
const C_SHOULDER := {"LeftUpperArm": Vector3(0.75, -0.25, 0.6), "LeftLowerArm": Vector3(-0.15, 0.95, 0.2), "LeftHand": Vector3(0.894, 0.0, -0.447)}   # çekiç sol omuzda (bekleme)
const C_BACK := {"LeftUpperArm": Vector3(0.7, 0.3, -0.65), "LeftLowerArm": Vector3(0.45, 0.6, -0.65), "LeftHand": Vector3(0.3, 0.3, -0.9)}           # sol-arkaya kurulu
const C_HIGH := {"LeftUpperArm": Vector3(0.35, 0.9, -0.2), "LeftLowerArm": Vector3(0.1, 0.95, -0.3), "LeftHand": Vector3(0.0, 0.2, -0.98)}           # başın üstünde, kafa arkada
const C_FWD := {"LeftUpperArm": Vector3(0.1, 0.1, 1), "LeftLowerArm": Vector3(-0.1, -0.05, 1), "LeftHand": Vector3(-0.2, 0.6, 0.77)}                  # öne uzanmış, kafa yukarıda
const C_DOWN := {"LeftUpperArm": Vector3(0.15, -0.55, 0.82), "LeftLowerArm": Vector3(0.0, -0.75, 0.66), "LeftHand": Vector3(0.0, 0.3, 0.95)}         # öne-aşağı inmiş (çakış)
const C_ACROSS := {"LeftUpperArm": Vector3(-0.2, 0.0, 1), "LeftLowerArm": Vector3(-0.6, 0.0, 0.8), "LeftHand": Vector3(-0.5, 0.4, 0.75)}           # sağa doğru savrulmuş
const C_LOW_BACK := {"LeftUpperArm": Vector3(0.55, -0.6, -0.55), "LeftLowerArm": Vector3(0.35, -0.6, -0.7), "LeftHand": Vector3(0.2, -0.3, -0.9)}     # sol kalça arkasında alçak


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, minf(1.0, crouch * 1.1), yaw * 1.5, lean * 1.4, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	return [
		# 1 Balta Yarması: balta sağ omzun arkasına kadar kalkar (gövde sağa burulu, geriye) -> önden aşağı yarar; çekiç omuzda
		{"len": 0.95, "hit": 0.42, "keys": [
			_t(0.0, 0.3, 0, 0, Vector3(-0.1, -0.6, 0.8), S.H_HIP_FRONT, C_SHOULDER, W),
			_t(0.16, 0.32, -25, -8, Vector3(-0.2, 0.9, -0.38), S.H_SH_UP, C_SHOULDER, W),
			_t(0.3, 0.35, -35, -16, Vector3(-0.15, 0.4, -0.9), S.H_EAR_BACK, C_SHOULDER, W),
			_t(0.36, 0.36, -36, -17, Vector3(-0.15, 0.38, -0.91), S.H_EAR_BACK, C_SHOULDER, W),
			_t(0.42, 0.6, 10, 30, Vector3(0.0, -0.4, 0.92), S.H_FOREHEAD, C_SHOULDER, L),
			_t(0.52, 0.68, 18, 36, Vector3(0.1, -0.75, 0.65), S.H_LOW_FRONT, C_SHOULDER, L),
			_t(0.95, 0.5, 10, 18, Vector3(0.1, -0.7, 0.7), S.H_LOW_FRONT, C_SHOULDER, W),
		]},
		# 2 Çekiç Savuruşu (sol el): çekiç sol-arkaya kurulur (gövde sola burulu) -> soldan sağa göğüs hizasında geniş yay
		{"len": 0.95, "hit": 0.42, "keys": [
			_t(0.0, 0.5, 10, 18, Vector3(0.1, -0.7, 0.7), S.H_LOW_FRONT, C_SHOULDER, W),
			_t(0.18, 0.45, 40, -6, Vector3(-0.3, -0.7, 0.65), S.H_HIP_SIDE, C_BACK, W),
			_t(0.3, 0.47, 50, -12, Vector3(-0.3, -0.7, 0.65), S.H_HIP_SIDE, C_BACK, W),
			_t(0.36, 0.48, 51, -13, Vector3(-0.3, -0.7, 0.65), S.H_HIP_SIDE, C_BACK, W),
			_t(0.42, 0.55, 0, 20, Vector3(-0.3, -0.7, 0.65), S.H_HIP_SIDE, C_FWD, L),
			_t(0.5, 0.58, -38, 26, Vector3(-0.3, -0.7, 0.65), S.H_HIP_SIDE, C_ACROSS, L),
			_t(0.95, 0.48, -25, 10, Vector3(-0.3, -0.7, 0.65), S.H_HIP_SIDE, C_ACROSS, W),
		]},
		# 3 Çift Darbe: balta alçaktan kancalar (rakibi öne çeker) -> hemen çekiç tepeden iner
		{"len": 1.0, "hit": 0.36, "extra_hits": [0.6], "extra_radius": 2.2, "keys": [
			_t(0.0, 0.48, -25, 10, Vector3(-0.3, -0.7, 0.65), S.H_HIP_SIDE, C_ACROSS, W),
			_t(0.2, 0.6, -35, 15, Vector3(-0.6, -0.5, -0.6), S.H_HIP_LOW, C_SHOULDER, W),
			_t(0.3, 0.62, -36, 16, Vector3(-0.58, -0.5, -0.62), S.H_HIP_LOW, C_SHOULDER, W),
			_t(0.36, 0.62, 5, 24, Vector3(0.1, -0.55, 0.83), S.H_LOW_FRONT, C_HIGH, L),
			_t(0.48, 0.5, 0, 6, Vector3(-0.2, -0.3, 0.93), S.H_HIP_FRONT, C_HIGH, W),
			_t(0.56, 0.52, 0, 2, Vector3(-0.2, -0.3, 0.93), S.H_HIP_FRONT, C_HIGH, W),
			_t(0.6, 0.75, 8, 36, Vector3(-0.2, -0.4, 0.9), S.H_HIP_FRONT, C_DOWN, L),
			_t(1.0, 0.55, 5, 16, Vector3(-0.2, -0.45, 0.87), S.H_HIP_FRONT, C_DOWN, W),
		]},
		# 4 Kama Çakma (imza): balta önde rakibin savunmasına dayanır, çekiç başın üstünden geriye kalkar -> baltanın sırtına çakar (zırh kırılır)
		{"len": 1.1, "hit": 0.56, "keys": [
			_t(0.0, 0.55, 5, 16, Vector3(-0.2, -0.45, 0.87), S.H_HIP_FRONT, C_DOWN, W),
			_t(0.16, 0.5, -5, 14, Vector3(0.05, 0.1, 1.0), S.H_CHEST, C_SHOULDER, L),
			_t(0.32, 0.45, -10, -14, Vector3(0.05, 0.12, 1.0), S.H_CHEST, C_HIGH, L),
			_t(0.46, 0.45, -11, -16, Vector3(0.05, 0.12, 1.0), S.H_CHEST, C_HIGH, L),
			_t(0.52, 0.55, 0, 10, Vector3(0.05, 0.1, 1.0), S.H_CHEST, C_FWD, L),
			_t(0.56, 0.68, 8, 32, Vector3(0.05, 0.0, 1.0), S.H_FWD, C_DOWN, L),
			_t(0.8, 0.68, 8, 30, Vector3(0.05, -0.05, 1.0), S.H_FWD, C_DOWN, L),
			_t(1.1, 0.5, 0, 12, Vector3(0.0, -0.5, 0.86), S.H_HIP_FRONT, C_SHOULDER, W),
		]},
		# 5 Ters Balta: balta sola-arkaya, gövde sola burulu -> ters savuruşla sağa diz hizasında biçer; çekiç geride dengede
		{"len": 0.95, "hit": 0.42, "keys": [
			_t(0.0, 0.5, 0, 12, Vector3(0.0, -0.5, 0.86), S.H_HIP_FRONT, C_SHOULDER, W),
			_t(0.18, 0.55, 40, 8, Vector3(0.75, -0.3, -0.6), S.H_LHIP, C_LOW_BACK, W),
			_t(0.32, 0.6, 52, 14, Vector3(0.6, -0.35, -0.72), S.H_LHIP, C_LOW_BACK, W),
			_t(0.38, 0.6, 53, 15, Vector3(0.58, -0.35, -0.73), S.H_LHIP, C_LOW_BACK, W),
			_t(0.42, 0.68, 5, 26, Vector3(0.05, -0.5, 0.86), S.H_LOW_FRONT, C_LOW_BACK, L),
			_t(0.5, 0.65, -38, 22, Vector3(-0.85, -0.4, 0.33), S.H_SIDE, C_LOW_BACK, L),
			_t(0.95, 0.5, -28, 8, Vector3(-0.7, -0.4, -0.6), S.H_HIP_SIDE, C_SHOULDER, W),
		]},
		# 6 Kabuto Wari (bitiriş): balta başın üstüne dik kalkar, çekiç arkaya kurulur -> balta önde yere çakılır, çekiç sırtına iner:
		# zemin önde yarılır, rakip havaya fırlar
		{"len": 1.3, "hit": 0.62, "keys": [
			_t(0.0, 0.5, -28, 8, Vector3(-0.7, -0.4, -0.6), S.H_HIP_SIDE, C_SHOULDER, W),
			_t(0.2, 0.4, -5, -10, Vector3(0.0, 0.98, -0.2), S.H_UP, C_BACK, W),
			_t(0.36, 0.38, -8, -22, Vector3(0.0, 0.6, -0.8), S.H_EAR_BACK, C_HIGH, W),
			_t(0.5, 0.39, -8, -24, Vector3(0.0, 0.58, -0.81), S.H_EAR_BACK, C_HIGH, W),
			_t(0.56, 0.6, 0, 14, Vector3(0.0, 0.95, 0.3), S.H_UP, C_HIGH, W),
			_t(0.62, 0.9, 4, 46, Vector3(0.0, -0.6, 0.8), S.H_LOW_FRONT, C_DOWN, L),
			_t(0.95, 0.9, 4, 44, Vector3(0.0, -0.62, 0.78), S.H_LOW_FRONT, C_DOWN, L),
			_t(1.3, 0.5, 0, 12, Vector3(-0.1, -0.6, 0.8), S.H_HIP_FRONT, C_SHOULDER, W),
		]},
	]
