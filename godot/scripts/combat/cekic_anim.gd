extends RefCounted
## Savaş çekici (ref savascekici.png): dev blok kafalı uzun saplı çekiç, İKİ ELLE. Ağır silah ritmi: büyük geri çekiş -> uzun duraksama ->
## tüm gövdeyle hızlı darbe -> kafa bedeni sürükler (gövde öne çöker) -> yavaş toparlanma. Darbeler yeri yarar (KeyedCombos).
## 1 yatay savuruş (rüzgâr izi), 2 baş üstünden yere çakma, 3 iki tur dönen kasırga, 4 alttan kaldırma, 5 sap ucu dürtme, 6 sıçrayıp dev çakma.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.35, -0.85, 0.3), "RightLowerArm": Vector3(0.3, -0.45, 0.85)}     # çekiç çaprazda, kafa sol omuz önü-yukarı
const R_OVER := {"RightUpperArm": Vector3(-0.25, 0.9, -0.35), "RightLowerArm": Vector3(-0.05, 0.7, -0.7)}       # baş üstü-arkası (çakma kurulumu)
const R_DOWN := {"RightUpperArm": Vector3(-0.1, -0.35, 0.93), "RightLowerArm": Vector3(0.0, -0.6, 0.8)}         # öne aşağı inmiş
const R_SIDE := {"RightUpperArm": Vector3(-0.95, -0.1, -0.25), "RightLowerArm": Vector3(-0.7, 0.1, -0.7)}       # sağ-arkada yatay kurulum
const R_ACROSS := {"RightUpperArm": Vector3(0.4, -0.2, 0.9), "RightLowerArm": Vector3(0.9, 0.0, 0.4)}           # sola savrulmuş
const R_WIDE := {"RightUpperArm": Vector3(-0.98, 0.0, 0.15), "RightLowerArm": Vector3(-0.95, 0.05, 0.3)}
const R_LOWBACK := {"RightUpperArm": Vector3(-0.35, -0.9, -0.25), "RightLowerArm": Vector3(-0.15, -0.75, 0.6)}  # alçak geride
const R_UPF := {"RightUpperArm": Vector3(-0.1, 0.6, 0.8), "RightLowerArm": Vector3(0.0, 0.85, 0.5)}             # öne-yukarı
const R_JAB := {"RightUpperArm": Vector3(-0.2, -0.5, 0.85), "RightLowerArm": Vector3(0.1, -0.1, 1)}             # sap ucu öne
const L_ANY := {"LeftUpperArm": Vector3(0.3, -0.8, 0.45), "LeftLowerArm": Vector3(-0.1, -0.2, 0.97)}            # iki elli: IK ile sapa gider


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.5, lean * 1.4, blade.normalized(), S._a(r, L_ANY), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.5, 0.75, 0.4)
	return [
		# 1 Yoko Uchi: kafa sağ-arkaya açılır, gövde burulur (bekle) -> kalçadan açılan geniş yatay savuruş -> kafa bedeni sola sürükler
		{"len": 1.15, "hit": 0.52, "two": true, "keys": [
			_t(0.0, 0.4, 0, 4, RDY, R_READY, W),
			_t(0.22, 0.46, -34, -6, Vector3(-0.8, 0.2, -0.55), R_SIDE, BK),
			_t(0.44, 0.48, -38, -8, Vector3(-0.8, 0.2, -0.6), R_SIDE, BK),
			_t(0.52, 0.5, 4, 14, Vector3(-0.4, 0.05, 0.9), R_WIDE, ST),
			_t(0.62, 0.54, 34, 18, Vector3(0.8, 0.0, 0.6), R_ACROSS, L),
			_t(0.82, 0.52, 40, 16, Vector3(0.8, -0.1, 0.55), R_ACROSS, L),
			_t(1.15, 0.4, 0, 4, RDY, R_READY, W),
		]},
		# 2 Tettsui: iki elle baş üstüne-arkaya kaldırır, gövde geriye kavislenir (uzun bekleme) -> yere çakar, gövde öne çöker
		{"len": 1.3, "hit": 0.62, "two": true, "keys": [
			_t(0.0, 0.4, 0, 4, RDY, R_READY, W),
			_t(0.26, 0.38, -6, -24, Vector3(0, 0.7, -0.7), R_OVER, BK),
			_t(0.54, 0.4, -8, -28, Vector3(0, 0.65, -0.75), R_OVER, BK),
			_t(0.62, 0.66, 6, 34, Vector3(0, -0.75, 0.66), R_DOWN, L),
			_t(0.9, 0.68, 4, 30, Vector3(0, -0.8, 0.6), R_DOWN, L),
			_t(1.3, 0.4, 0, 4, RDY, R_READY, W),
		]},
		# 3 Tatsumaki: kafa yana açık, gövde iki tam tur döner (kafa geniş çember çizer, çoklu vuruş)
		{"len": 1.4, "hit": 0.36, "two": true, "extra_hits": [0.6, 0.86], "extra_radius": 2.8, "keys": [
			_t(0.0, 0.4, 0, 4, RDY, R_READY, W),
			_t(0.2, 0.48, -30, 4, Vector3(-0.9, 0.05, 0.3), R_WIDE, BK),
			_t(0.42, 0.5, 60, 8, Vector3(-0.9, 0.05, 0.3), R_WIDE, CR),
			_t(0.66, 0.5, -60, 8, Vector3(-0.9, 0.05, 0.3), R_WIDE, W),
			_t(0.9, 0.5, 60, 8, Vector3(-0.9, 0.05, 0.3), R_WIDE, CR),
			_t(1.08, 0.48, 10, 6, Vector3(-0.6, 0.1, 0.7), R_WIDE, ST),
			_t(1.4, 0.4, 0, 4, RDY, R_READY, W),
		]},
		# 4 Kachiage: kafa yerde geride (çömel) -> alttan öne-yukarı süpürüp rakibi havaya kaldırır
		{"len": 1.05, "hit": 0.5, "two": true, "keys": [
			_t(0.0, 0.4, 0, 4, RDY, R_READY, W),
			_t(0.22, 0.72, -24, 22, Vector3(0, -0.8, -0.55), R_LOWBACK, BK),
			_t(0.42, 0.74, -26, 24, Vector3(0, -0.8, -0.55), R_LOWBACK, BK),
			_t(0.5, 0.3, 8, -14, Vector3(0, 0.85, 0.5), R_UPF, L),
			_t(0.72, 0.28, 6, -16, Vector3(0, 0.9, 0.35), R_UPF, L),
			_t(1.05, 0.4, 0, 4, RDY, R_READY, W),
		]},
		# 5 Tsuki: sap ucuyla kısa dürtme (kafa geride), ardından kafa öne yarım savuruş
		{"len": 0.85, "hit": 0.26, "two": true, "extra_hits": [0.48], "extra_radius": 1.6, "keys": [
			_t(0.0, 0.4, 0, 4, RDY, R_READY, W),
			_t(0.14, 0.44, -10, -6, Vector3(0, 0.3, -0.95), R_JAB, BK),
			_t(0.26, 0.48, 10, 16, Vector3(0, 0.3, -0.95), R_JAB, L),
			_t(0.42, 0.48, 24, 14, Vector3(0.6, 0.3, 0.7), R_ACROSS, L),
			_t(0.85, 0.4, 0, 4, RDY, R_READY, W),
		]},
		# 6 Tenchi Kudaki (bitiriş): yüksek sıçrar, havada baş üstüne kaldırır (duraksama) -> inerken yere dev çakma, şok dalgası
		{"len": 1.6, "hit": 0.8, "two": true, "keys": [
			_t(0.0, 0.4, 0, 4, RDY, R_READY, W),
			_t(0.14, 0.72, 0, 14, RDY, R_READY, W),
			_t(0.4, 0.14, -6, -26, Vector3(0, 0.7, -0.7), R_OVER, ST),
			_t(0.7, 0.16, -8, -30, Vector3(0, 0.65, -0.75), R_OVER, ST),
			_t(0.8, 0.7, 6, 38, Vector3(0, -0.8, 0.6), R_DOWN, L),
			_t(1.15, 0.72, 4, 32, Vector3(0, -0.8, 0.6), R_DOWN, L),
			_t(1.6, 0.4, 0, 4, RDY, R_READY, W),
		]},
	]
