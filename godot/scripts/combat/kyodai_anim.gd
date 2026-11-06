extends RefCounted
## Kyodai Shuriken (ref fumavaryasyon.png): insandan büyük dört köşeli yıldız. UZUN MENZİL, AĞIR: iki kolla kurulur, uzun bekler,
## tüm gövdeyle fırlatılır (KeyedCombos._spin_throw). Fūma'dan farklı: atışlar gövde dönüşü/çömelmeyle, yavaş ve geniş.
## 1 baş üstünden heave, 2 tam tur dönüp bırakış, 3 yerde tekerlek gibi yuvarlama, 4 kalkan darbesi, 5 bumerang, 6 sıçrayıp yere çakma.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.45, -0.75, 0.2), "RightLowerArm": Vector3(-0.1, -0.3, 0.95)}
const L_READY := {"LeftUpperArm": Vector3(0.45, -0.7, 0.25), "LeftLowerArm": Vector3(0.1, -0.2, 0.97)}
const R_UP := {"RightUpperArm": Vector3(-0.3, 0.9, -0.3), "RightLowerArm": Vector3(-0.1, 0.8, -0.6)}
const L_UP := {"LeftUpperArm": Vector3(0.3, 0.9, -0.3), "LeftLowerArm": Vector3(0.1, 0.8, -0.6)}
const R_FWD := {"RightUpperArm": Vector3(-0.15, 0.3, 0.95), "RightLowerArm": Vector3(0.0, 0.2, 1)}
const L_FWD := {"LeftUpperArm": Vector3(0.15, 0.3, 0.95), "LeftLowerArm": Vector3(0.0, 0.2, 1)}
const R_WIDE := {"RightUpperArm": Vector3(-0.98, 0.1, 0.1), "RightLowerArm": Vector3(-0.95, 0.15, 0.25)}
const L_WIDE := {"LeftUpperArm": Vector3(0.95, -0.15, 0.2), "LeftLowerArm": Vector3(0.85, -0.2, 0.45)}
const R_LOW := {"RightUpperArm": Vector3(-0.3, -0.9, -0.3), "RightLowerArm": Vector3(-0.1, -0.85, 0.5)}
const R_BOWL := {"RightUpperArm": Vector3(-0.1, -0.6, 0.8), "RightLowerArm": Vector3(0.0, -0.4, 0.92)}
const R_SHIELD := {"RightUpperArm": Vector3(-0.35, -0.2, 0.9), "RightLowerArm": Vector3(0.5, 0.2, 0.85)}
const L_SHIELD := {"LeftUpperArm": Vector3(0.35, -0.2, 0.9), "LeftLowerArm": Vector3(-0.5, 0.2, 0.85)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.0, 0.6, 0.8)
	return [
		# 1 Kyodai Nage: iki kolla baş üstüne-arkaya kaldırır, gövde geriye kavislenir (uzun bekleme) -> tüm ağırlıkla öne fırlatır
		{"len": 1.3, "hit": 0.6, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.22, 0.42, -6, -22, Vector3(0, 0.6, -0.8), R_UP, L_UP, BK),
			_t(0.52, 0.44, -8, -26, Vector3(0, 0.55, -0.83), R_UP, L_UP, BK),
			_t(0.6, 0.5, 6, 30, Vector3(0, 0.2, 1), R_FWD, L_FWD, L),
			_t(0.85, 0.46, 4, 20, Vector3(0, 0.2, 1), R_FWD, L_FWD, L),
			_t(1.3, 0.36, 0, 4, RDY, R_READY, L_READY, W),
		]},
		# 2 Senkai Nage: tam tur döner (shuriken kolun ucunda geniş çember), dönüşün sonunda bırakır -> geniş yay çizer
		{"len": 1.35, "hit": 0.66, "extra_hits": [0.3, 0.48], "extra_radius": 2.6, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.16, 0.44, 40, 6, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, CR),
			_t(0.34, 0.46, -60, 6, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, W),
			_t(0.52, 0.46, 60, 6, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, CR),
			_t(0.66, 0.46, -20, 14, Vector3(0, 0.2, 1), R_FWD, L_WIDE, L),
			_t(0.95, 0.42, -10, 8, Vector3(0, 0.2, 1), R_FWD, L_WIDE, L),
			_t(1.35, 0.36, 0, 4, RDY, R_READY, L_READY, W),
		]},
		# 3 Sharin: derin çömelip alçaktan geriye kurar -> yere dik bırakır, tekerlek gibi yuvarlanarak gider
		{"len": 1.15, "hit": 0.5, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.2, 0.7, -20, 20, Vector3(0, -0.6, -0.8), R_LOW, L_WIDE, BK),
			_t(0.42, 0.72, -22, 22, Vector3(0, -0.6, -0.8), R_LOW, L_WIDE, BK),
			_t(0.5, 0.7, 10, 30, Vector3(0, -0.4, 0.9), R_BOWL, L_WIDE, L),
			_t(0.78, 0.56, 6, 18, Vector3(0, -0.3, 0.95), R_BOWL, L_WIDE, L),
			_t(1.15, 0.36, 0, 4, RDY, R_READY, L_READY, W),
		]},
		# 4 Tate Uchi: dev yıldızı göğüs önünde kalkan gibi tutar, omuzla öne yüklenip çarpar (yakın, ağır itiş)
		{"len": 0.9, "hit": 0.42, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.2, 0.5, -10, -6, Vector3(0, 1, 0.1), R_SHIELD, L_SHIELD, BK),
			_t(0.34, 0.52, -12, -8, Vector3(0, 1, 0.1), R_SHIELD, L_SHIELD, BK),
			_t(0.42, 0.5, 8, 26, Vector3(0, 1, 0.2), R_SHIELD, L_SHIELD, L),
			_t(0.6, 0.46, 6, 18, Vector3(0, 1, 0.2), R_SHIELD, L_SHIELD, L),
			_t(0.9, 0.36, 0, 4, RDY, R_READY, L_READY, W),
		]},
		# 5 Kaeshi: yan kurulup bırakır, shuriken hedefin ardından dönüp geri gelirken ikinci kez keser
		{"len": 1.25, "hit": 0.5, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.22, 0.44, 40, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, CR),
			_t(0.42, 0.46, 44, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_WIDE, CR),
			_t(0.5, 0.46, -30, 12, Vector3(0, 0.2, 1), R_FWD, L_WIDE, ST),
			_t(0.8, 0.42, -16, 6, Vector3(0, 0.2, 1), R_FWD, L_WIDE, W),
			_t(1.25, 0.36, 0, 4, RDY, R_READY, L_READY, W),
		]},
		# 6 Tenkū Otoshi (bitiriş): yüksek sıçrar, havada iki kolla baş üstüne kaldırır, aşağı fırlatır -> yere saplanır, şok dalgası
		# 6 Tenkū Nage (bitiriş): iki kolla yere kadar eğilip dev yıldızı alttan kavrar -> tüm gövdeyle göğe fırlatır; yıldız yükselip
		#   dönerek rakibin üstüne çakılır (KeyedCombos, oyuncu zıplamaz)
		{"len": 1.6, "hit": 0.62, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_READY, W),
			_t(0.22, 0.74, 0, 30, Vector3(0, -0.6, 0.8), R_BOWL, L_FWD, W),
			_t(0.5, 0.76, 0, 32, Vector3(0, -0.6, 0.8), R_BOWL, L_FWD, W),
			_t(0.62, 0.18, 0, -20, Vector3(0, 1, 0.2), R_UP, L_UP, ST),
			_t(0.9, 0.2, 0, -16, Vector3(0, 1, 0.2), R_UP, L_UP, ST),
			_t(1.6, 0.36, 0, 4, RDY, R_READY, L_READY, W),
		]},
	]
