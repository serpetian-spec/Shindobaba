extends RefCounted
## Samehada YENİ kombosu (kaynaksız; _tmp/ed/samehada2_desc.md kendime anlatımı, her satır bir anahtar). Eski video kombosu
## samehada_anim.gd'de duruyor (ortak poz kısayolları oradan). Ağır ritim: uzun geri çekiş -> duraksama -> hızlı -> ağırlık
## bedeni sürükler -> yavaş toparlanma. "roll": kılıcın sap ekseni etrafında dönüşü (90 = yassı yüz önde). Etkiler: KeyedCombos.

const S = preload("res://scripts/combat/samehada_anim.gd")


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary, roll := 0.0) -> Dictionary:
	var k = S._k(t, minf(1.0, crouch * 1.1), yaw * 1.5, lean * 1.4, blade.normalized(), S._a(r, l), legs)
	k["roll"] = roll
	return k


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	return [
		# 1 Kazıyış: sağ omzun üstünden sırta yatırılır -> sola-aşağı çapraz iner -> temasta sürüklenip kalçaya geri çekilir (3 rende)
		{"len": 1.1, "hit": 0.42, "two": false, "extra_hits": [0.56, 0.68, 0.8], "extra_radius": 2.4, "keys": [
			_t(0.0, 0.3, 0, 0, Vector3(-0.3, 0.6, -0.75), S.H_SH_BACK, S.L_DOWN, W),
			_t(0.16, 0.35, -28, -10, Vector3(-0.25, 0.3, -0.92), S.H_SH_BACK, S.L_FWD, W),
			_t(0.3, 0.38, -42, -16, Vector3(-0.2, -0.15, -0.97), S.H_EAR_BACK, S.L_FWD, W),
			_t(0.36, 0.39, -44, -17, Vector3(-0.2, -0.18, -0.96), S.H_EAR_BACK, S.L_FWD, W),
			_t(0.42, 0.6, 18, 30, Vector3(0.35, -0.35, 0.87), S.H_FOREHEAD, S.L_BACK, L),
			_t(0.5, 0.65, 26, 34, Vector3(0.55, -0.55, 0.62), S.H_LCHEST, S.L_BACK, L),
			_t(0.68, 0.6, 10, 20, Vector3(0.2, -0.55, 0.81), S.H_BELLY, S.L_BACK, W),   # geri sürükleme (rende)
			_t(0.84, 0.55, -5, 10, Vector3(-0.1, -0.5, 0.86), S.H_HIP_FRONT, S.L_DOWN, W),
			_t(1.1, 0.45, -8, 5, Vector3(-0.15, -0.45, 0.88), S.H_HIP_FRONT, S.L_DOWN, W),
		]},
		# 2 Yan Ezme (iki el): sola-arkaya burulup çekilir -> yassı yüz önde sağa göğüs hizasında, omuz yüklenir
		{"len": 1.0, "hit": 0.44, "two": true, "keys": [
			_t(0.0, 0.45, -8, 5, Vector3(-0.15, -0.45, 0.88), S.H_HIP_FRONT, S.L_DOWN, W),
			_t(0.18, 0.45, 40, -6, Vector3(0.85, 0.1, -0.5), S.H_LCHEST, S.L_DOWN, W, 90.0),
			_t(0.32, 0.48, 55, -12, Vector3(0.55, 0.12, -0.83), S.H_LCHEST, S.L_DOWN, W, 90.0),
			_t(0.38, 0.49, 56, -13, Vector3(0.53, 0.12, -0.84), S.H_LCHEST, S.L_DOWN, W, 90.0),
			_t(0.44, 0.55, 5, 22, Vector3(0.05, 0.08, 1.0), S.H_CHEST, S.L_DOWN, L, 90.0),
			_t(0.52, 0.58, -32, 28, Vector3(-0.9, 0.05, 0.4), S.H_SIDE, S.L_DOWN, L, 90.0),
			_t(0.7, 0.55, -40, 20, Vector3(-0.85, 0.0, -0.5), S.H_SIDE, S.L_DOWN, L, 70.0),
			_t(1.0, 0.45, -28, 8, Vector3(-0.75, -0.1, -0.65), S.H_HIP_SIDE, S.L_DOWN, W, 30.0),
		]},
		# 3 Isırık: sağ-arkada alçakta derin çömelerek kurulur -> aşağıdan yukarı patlar, tepede pullar kabarır (havaya)
		{"len": 0.95, "hit": 0.4, "two": false, "keys": [
			_t(0.0, 0.45, -28, 8, Vector3(-0.75, -0.1, -0.65), S.H_HIP_SIDE, S.L_DOWN, W),
			_t(0.2, 0.72, -38, 22, Vector3(-0.45, -0.55, -0.7), S.H_HANG, S.L_FWD, W),
			_t(0.3, 0.75, -40, 24, Vector3(-0.43, -0.57, -0.7), S.H_HANG, S.L_FWD, W),
			_t(0.36, 0.6, -12, 14, Vector3(-0.2, -0.55, 0.81), S.H_LOW_FRONT, S.L_FWD, L),
			_t(0.4, 0.38, 6, -4, Vector3(0.0, 0.55, 0.84), S.H_FOREHEAD, S.L_BACK, L),
			_t(0.5, 0.25, 10, -14, Vector3(0.05, 0.98, 0.15), S.H_UP, S.L_BACK, W),
			_t(0.95, 0.3, 4, -8, Vector3(0.0, 0.9, -0.42), S.H_ABOVE, S.L_DOWN, W),
		]},
		# 4 Kuyruk Kamçısı: yukarıdan sırtın arkasına düşer, kalça sola -> diz altı soldan sağa ters savuruş (rakip yere)
		{"len": 0.95, "hit": 0.42, "two": false, "keys": [
			_t(0.0, 0.3, 4, -8, Vector3(0.0, 0.9, -0.42), S.H_ABOVE, S.L_DOWN, W),
			_t(0.16, 0.5, 30, 10, Vector3(0.4, -0.3, -0.87), S.H_LHIP, S.L_SIDE, W),
			_t(0.3, 0.7, 50, 22, Vector3(0.65, -0.5, -0.57), S.H_LHIP, S.L_SIDE, W),
			_t(0.36, 0.71, 51, 23, Vector3(0.64, -0.51, -0.57), S.H_LHIP, S.L_SIDE, W),
			_t(0.42, 0.78, 5, 28, Vector3(0.05, -0.55, 0.83), S.H_LOW_FRONT, S.L_UP, L),
			_t(0.5, 0.75, -35, 24, Vector3(-0.85, -0.45, 0.25), S.H_HIP_LOW, S.L_UP, L),
			_t(0.66, 0.65, -45, 16, Vector3(-0.7, -0.4, -0.6), S.H_HIP_LOW, S.L_SIDE, L),
			_t(0.95, 0.5, -30, 8, Vector3(-0.6, -0.2, -0.77), S.H_HIP_SIDE, S.L_DOWN, W),
		]},
		# 5 Delme (iki el): sağ yanda yatay geri çekilir, gövde geriye -> derin hamleyle ileri saplar, tutar
		{"len": 0.95, "hit": 0.4, "two": true, "keys": [
			_t(0.0, 0.5, -30, 8, Vector3(-0.6, -0.2, -0.77), S.H_HIP_SIDE, S.L_DOWN, W),
			_t(0.18, 0.48, -38, -10, Vector3(-0.08, 0.02, 1.0), S.H_BEHIND, S.L_DOWN, W),
			_t(0.3, 0.5, -45, -16, Vector3(-0.06, 0.03, 1.0), S.H_BEHIND, S.L_DOWN, W),
			_t(0.36, 0.5, -46, -17, Vector3(-0.06, 0.03, 1.0), S.H_BEHIND, S.L_DOWN, W),
			_t(0.4, 0.7, 12, 34, Vector3(0.0, -0.02, 1.0), S.H_FWD, S.L_DOWN, L),
			_t(0.7, 0.7, 12, 32, Vector3(0.0, -0.04, 1.0), S.H_FWD, S.L_DOWN, L),
			_t(0.95, 0.6, 8, 24, Vector3(0.0, -0.05, 1.0), S.H_FWD, S.L_DOWN, L),
		]},
		# 6 Doyumsuz Ağız (bitiriş, iki el): saplı rakip uçta -> kılıç başın üstünden arkaya taşınır, rakip arkaya yere çarpılır
		{"len": 1.25, "hit": 0.22, "two": true, "keys": [
			_t(0.0, 0.6, 8, 24, Vector3(0.0, -0.05, 1.0), S.H_FWD, S.L_DOWN, L),
			_t(0.16, 0.62, 4, 28, Vector3(0.0, -0.3, 0.95), S.H_LOW_FRONT, S.L_DOWN, L),   # ağırlığı yüklenip altına girer
			_t(0.3, 0.5, 0, 8, Vector3(0.0, 0.55, 0.83), S.H_FOREHEAD, S.L_DOWN, W),
			_t(0.44, 0.4, 0, -18, Vector3(0.0, 0.99, -0.1), S.H_UP, S.L_DOWN, W),
			_t(0.58, 0.55, 0, -30, Vector3(0.0, 0.2, -0.98), S.H_EAR_BACK, S.L_DOWN, W),   # arkaya çarpış
			_t(0.66, 0.62, 0, -32, Vector3(0.0, -0.1, -0.99), S.H_BEHIND, S.L_DOWN, W),
			_t(0.95, 0.55, 0, -14, Vector3(-0.2, 0.3, -0.93), S.H_SH_BACK, S.L_DOWN, W),
			_t(1.25, 0.4, 0, -4, Vector3(-0.3, 0.6, -0.75), S.H_SH_BACK, S.L_DOWN, W),
		]},
	]
