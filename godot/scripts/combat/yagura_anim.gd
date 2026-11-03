extends RefCounted
## Yagura'nın kancalı sopası — AĞIR KILIÇ GİBİ savrulur (saplama/mızrak hareketi yok): vuran uç çiçekli büyük kancalı uç.
## Ağır ritim: büyük geri çekiş -> kısa bekleme -> kalçadan açılan geniş savuruş -> uç bedeni sürükler -> toparlanma.
## Her adımda su (KeyedCombos): 1 çapraz iniş, 2 ters yatay savuruş, 3 iki tur dönen savuruş, 4 alttan kaldıran savuruş,
## 5 kancayla yakalayıp yana savurma, 6 Suiro Kaiten (bitiriş): baş üstünden yere çakma, su girdabı.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.35, -0.75, 0.5), "RightLowerArm": Vector3(0.2, 0.55, 0.8)}       # sopa omuz önünde çapraz
const R_HIGH := {"RightUpperArm": Vector3(-0.45, 0.85, -0.3), "RightLowerArm": Vector3(-0.15, 0.9, -0.4)}
const R_DOWN := {"RightUpperArm": Vector3(0.2, -0.4, 0.9), "RightLowerArm": Vector3(0.5, -0.55, 0.65)}
const R_BACK_R := {"RightUpperArm": Vector3(-0.95, 0.2, -0.25), "RightLowerArm": Vector3(-0.7, 0.4, -0.55)}
const R_ACROSS := {"RightUpperArm": Vector3(0.45, 0.15, 0.88), "RightLowerArm": Vector3(0.95, 0.2, 0.2)}
const R_BACK_L := {"RightUpperArm": Vector3(0.4, 0.2, 0.9), "RightLowerArm": Vector3(0.9, 0.4, -0.2)}
const R_SWEEP_R := {"RightUpperArm": Vector3(-0.95, 0.0, 0.3), "RightLowerArm": Vector3(-0.9, 0.1, 0.4)}
const R_LOWBACK := {"RightUpperArm": Vector3(-0.35, -0.9, -0.25), "RightLowerArm": Vector3(-0.15, -0.75, 0.6)}
const R_UP := {"RightUpperArm": Vector3(-0.1, 0.75, 0.65), "RightLowerArm": Vector3(0.0, 0.95, 0.3)}
const R_WIDE := {"RightUpperArm": Vector3(-0.98, 0.0, 0.15), "RightLowerArm": Vector3(-0.95, 0.05, 0.3)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.8, 0.5), "LeftLowerArm": Vector3(-0.1, -0.1, 0.99)}
const L_POINT := {"LeftUpperArm": Vector3(0.15, 0.05, 1), "LeftLowerArm": Vector3(0.05, 0.0, 1)}
const L_BACK := {"LeftUpperArm": Vector3(0.5, -0.6, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}
const L_SEAL := {"LeftUpperArm": Vector3(0.2, -0.3, 0.93), "LeftLowerArm": Vector3(-0.6, 0.45, 0.66)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.5, lean * 1.4, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.45, 0.8, 0.4)
	return [
		# 1 Mizu Otoshi: sopa baş üstüne-arkaya kalkar (bekle) -> sağ omuzdan sol kalçaya çapraz ağır iniş
		{"len": 1.05, "hit": 0.52, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.18, 0.4, -24, -24, Vector3(-0.2, 0.6, -0.78), R_HIGH, L_POINT, BK),
			_t(0.46, 0.42, -28, -28, Vector3(-0.25, 0.55, -0.8), R_HIGH, L_POINT, BK),
			_t(0.52, 0.58, 28, 30, Vector3(0.5, -0.6, 0.6), R_DOWN, L_BACK, L),
			_t(0.64, 0.56, 26, 22, Vector3(0.55, -0.7, 0.45), R_DOWN, L_BACK, L),
			_t(0.95, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 2 Gyaku Nami: sol omuz önüne sarılır -> ters (backhand) geniş yatay savuruş sağa
		{"len": 1.05, "hit": 0.5, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.18, 0.44, 46, -8, Vector3(0.8, 0.4, 0.3), R_BACK_L, L_GUARD, CR),
			_t(0.44, 0.46, 52, -10, Vector3(0.75, 0.45, 0.4), R_BACK_L, L_GUARD, CR),
			_t(0.5, 0.48, -36, 18, Vector3(-0.9, 0.2, 0.4), R_SWEEP_R, L_POINT, L),
			_t(0.62, 0.44, -38, 12, Vector3(-0.95, 0.1, 0.3), R_SWEEP_R, L_POINT, L),
			_t(0.95, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 3 Uzu Giri: uç yana açık, gövde iki tam tur döner (ağır uç geniş çember çizer, su halkası)
		{"len": 1.25, "hit": 0.36, "extra": [0.62, 0.88], "extra_r": 2.8, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.18, 0.46, -30, 4, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_GUARD, BK),
			_t(0.4, 0.48, 70, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_GUARD, CR),
			_t(0.62, 0.48, 180, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_GUARD, W),
			_t(0.86, 0.48, 290, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_GUARD, CR),
			_t(1.25, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 4 Ten Nami: uç yerde geride (çömel) -> alttan öne-yukarı ağır savuruş, rakip havaya kalkar
		{"len": 1.05, "hit": 0.52, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.18, 0.72, -32, 24, Vector3(0, -0.7, -0.7), R_LOWBACK, L_POINT, BK),
			_t(0.46, 0.74, -36, 26, Vector3(0, -0.65, -0.75), R_LOWBACK, L_POINT, BK),
			_t(0.52, 0.24, 10, -16, Vector3(0, 0.9, 0.4), R_UP, L_BACK, L),
			_t(0.62, 0.24, 6, -16, Vector3(0, 0.95, 0.25), R_UP, L_BACK, L),
			_t(0.95, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 5 Kagi Nage: sağ-arkaya geniş kurulum -> yatay savuruşta kanca rakibi yakalar, dönüşün sonunda yana savurur
		{"len": 1.15, "hit": 0.56, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.2, 0.46, -52, -10, Vector3(-0.8, 0.3, -0.5), R_BACK_R, L_SEAL, BK),
			_t(0.48, 0.48, -58, -12, Vector3(-0.75, 0.35, -0.55), R_BACK_R, L_SEAL, BK),
			_t(0.53, 0.5, 6, 14, Vector3(-0.2, 0.2, 0.96), R_WIDE, L_SEAL, ST),
			_t(0.6, 0.54, 50, 20, Vector3(0.9, 0.2, 0.35), R_ACROSS, L_BACK, L),
			_t(0.78, 0.48, 52, 14, Vector3(0.9, 0.1, 0.3), R_ACROSS, L_BACK, L),
			_t(1.05, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 6 Suiro Kaiten (bitiriş): baş üstünde iki tur döndürür -> sıçrayıp tüm ağırlıkla yere çakar, su girdabı yükselir
		# 6 Suijin Senpū (bitiriş): sopa baş üstünde iki tur çevrilir (su toplanır) -> sağ-arkaya derin kurulum -> öne dev yatay savuruş,
		#   çiçekli uçtan su dalgası 13 m ilerler (zıplama yok)
		{"len": 1.5, "hit": 0.86, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.18, 0.36, -20, -8, Vector3(0, 0.95, 0.2), R_UP, L_SEAL, W),
			_t(0.4, 0.38, 24, -8, Vector3(0, 0.95, 0.2), R_UP, L_SEAL, CR),
			_t(0.62, 0.46, -54, -10, Vector3(-0.8, 0.3, -0.5), R_BACK_R, L_SEAL, BK),
			_t(0.8, 0.48, -60, -12, Vector3(-0.8, 0.3, -0.5), R_BACK_R, L_SEAL, BK),
			_t(0.86, 0.52, 10, 16, Vector3(-0.2, 0.2, 0.96), R_WIDE, L_POINT, L),
			_t(0.96, 0.56, 52, 22, Vector3(0.9, 0.2, 0.35), R_ACROSS, L_BACK, L),
			_t(1.15, 0.54, 60, 18, Vector3(0.9, 0.1, 0.3), R_ACROSS, L_BACK, L),
			_t(1.5, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
	]
