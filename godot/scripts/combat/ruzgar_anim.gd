extends RefCounted
## Rüzgar Chakra Bıçağı (ruzgarchakrabicagi.png) kombosu: TEK EL, hafif ve çok hızlı chakra bıçağı. FUUTON AĞIRLIKLI: her vuruşta
## bıçaktan ileri uçan rüzgar kesiği (KeyedCombos.on_strike: uzaktakilere fuuton hasarı + rüzgar perdesi). Kısa geri çekiş, şimşek hızı.

const S = preload("res://scripts/combat/samehada_anim.gd")


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.3, lean * 1.2, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	return [
		# 1 Rüzgar Hilali: sağ omuzdan sola-aşağı çapraz, hilal kesik uçar
		{"len": 0.5, "hit": 0.2, "keys": [
			_t(0.0, 0.3, 0, 4, Vector3(0.1, -0.2, 1.0), S.H_CHEST, S.L_DOWN, W),
			_t(0.1, 0.32, -22, -4, Vector3(-0.4, 0.85, -0.3), S.H_SH_UP, S.L_FWD, W),
			_t(0.14, 0.33, -24, -5, Vector3(-0.38, 0.86, -0.32), S.H_SH_UP, S.L_FWD, W),
			_t(0.2, 0.42, 14, 16, Vector3(0.5, -0.6, 0.62), S.H_LCHEST, S.L_BACK, L),
			_t(0.5, 0.34, 6, 6, Vector3(0.3, -0.5, 0.8), S.H_BELLY, S.L_DOWN, W),
		]},
		# 2 Yatay Kesik: sola kurulur -> soldan sağa geniş yatay, yatay rüzgar perdesi
		{"len": 0.5, "hit": 0.2, "keys": [
			_t(0.0, 0.34, 6, 6, Vector3(0.3, -0.5, 0.8), S.H_BELLY, S.L_DOWN, W),
			_t(0.1, 0.36, 26, 0, Vector3(0.9, 0.05, -0.4), S.H_LCHEST, S.L_DOWN, W),
			_t(0.14, 0.36, 27, 0, Vector3(0.88, 0.05, -0.45), S.H_LCHEST, S.L_DOWN, W),
			_t(0.2, 0.4, -10, 12, Vector3(0.0, 0.0, 1.0), S.H_FWD, S.L_BACK, L),
			_t(0.26, 0.4, -30, 12, Vector3(-0.95, 0.0, 0.3), S.H_SIDE, S.L_BACK, L),
			_t(0.5, 0.34, -12, 6, Vector3(-0.6, -0.2, 0.75), S.H_HIP_SIDE, S.L_DOWN, W),
		]},
		# 3 Ters Yükselen: aşağıdan yukarı ters çapraz, yukarı savrulan kesik (rakibi kaldırır)
		{"len": 0.55, "hit": 0.22, "keys": [
			_t(0.0, 0.34, -12, 6, Vector3(-0.6, -0.2, 0.75), S.H_HIP_SIDE, S.L_DOWN, W),
			_t(0.12, 0.5, -20, 16, Vector3(-0.5, -0.8, 0.3), S.H_HIP_LOW, S.L_FWD, W),
			_t(0.16, 0.5, -21, 17, Vector3(-0.5, -0.8, 0.3), S.H_HIP_LOW, S.L_FWD, W),
			_t(0.22, 0.3, 12, -8, Vector3(0.4, 0.85, 0.35), S.H_FOREHEAD, S.L_BACK, L),
			_t(0.55, 0.32, 4, 2, Vector3(0.1, 0.4, 0.9), S.H_CHEST, S.L_DOWN, W),
		]},
		# 4 Rüzgar Saplaması: geri çekilip ileri saplar; uçtan uzun ince rüzgar mızrağı fırlar
		{"len": 0.55, "hit": 0.24, "keys": [
			_t(0.0, 0.32, 4, 2, Vector3(0.1, 0.4, 0.9), S.H_CHEST, S.L_DOWN, W),
			_t(0.12, 0.36, -18, -10, Vector3(0.0, 0.05, 1.0), S.H_HIP_SIDE, S.L_FWD, W),
			_t(0.18, 0.37, -19, -11, Vector3(0.0, 0.05, 1.0), S.H_HIP_SIDE, S.L_FWD, W),
			_t(0.24, 0.5, 10, 24, Vector3(0.0, 0.0, 1.0), S.H_FWD, S.L_BACK, L),
			_t(0.55, 0.36, 4, 8, Vector3(0.1, -0.1, 1.0), S.H_CHEST, S.L_DOWN, W),
		]},
		# 5 Çift Hilal: hızlı ileri-geri iki çapraz (X), iki kesik ardı ardına uçar
		{"len": 0.6, "hit": 0.18, "extra_hits": [0.34], "extra_radius": 2.2, "keys": [
			_t(0.0, 0.36, 4, 8, Vector3(0.1, -0.1, 1.0), S.H_CHEST, S.L_DOWN, W),
			_t(0.1, 0.36, -18, -2, Vector3(-0.5, 0.8, -0.2), S.H_SH_UP, S.L_FWD, W),
			_t(0.18, 0.42, 12, 14, Vector3(0.5, -0.6, 0.62), S.H_LCHEST, S.L_FWD, L),
			_t(0.26, 0.4, 18, 6, Vector3(0.6, 0.75, -0.2), S.H_LSHOULDER, S.L_FWD, L),
			_t(0.34, 0.44, -14, 16, Vector3(-0.55, -0.6, 0.6), S.H_HIP_SIDE, S.L_BACK, L),
			_t(0.6, 0.36, -4, 6, Vector3(-0.2, -0.4, 0.9), S.H_BELLY, S.L_DOWN, W),
		]},
		# 6 Fūjin Ōgiri (bitiriş): bıçak başın üstüne, gövde geriye kavisli, rüzgar toplanır -> dev dikey rüzgar kesiği ileri uçar
		{"len": 0.9, "hit": 0.46, "keys": [
			_t(0.0, 0.36, -4, 6, Vector3(-0.2, -0.4, 0.9), S.H_BELLY, S.L_DOWN, W),
			_t(0.2, 0.3, -6, -14, Vector3(0.0, 0.95, -0.3), S.H_UP, S.L_UP, W),
			_t(0.38, 0.3, -6, -18, Vector3(0.0, 0.85, -0.5), S.H_UP, S.L_UP, W),
			_t(0.46, 0.7, 4, 36, Vector3(0.0, -0.6, 0.8), S.H_LOW_FRONT, S.L_BACK, L),
			_t(0.9, 0.4, 0, 8, Vector3(0.1, -0.2, 1.0), S.H_CHEST, S.L_DOWN, W),
		]},
	]
