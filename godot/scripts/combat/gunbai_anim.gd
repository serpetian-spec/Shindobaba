class_name GunbaiAnim
## Gunbai kombosu (kaynak yok — _tmp/ed/gunbai_desc.md hayal edilmiş tarifinden birebir; her tarif satırı bir anahtar).
## Yön/kol kısayolları SamehadaAnim ile ortak. "roll": yelpazenin sap ekseni etrafında dönüşü (90 = yüz rakibe).

static func _g(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary, roll := 0.0) -> Dictionary:
	var k = SamehadaAnim._k(t, minf(1.0, crouch * 1.15), yaw * 1.6, lean * 1.35, blade, SamehadaAnim._a(r, l), legs)
	k["roll"] = roll
	return k


static func steps() -> Array:
	# AĞIR silah ritmi (her vuruş): uzun kurulma (geriye çek, gövde ters burulur, ağırlık arka ayakta) -> kısa duraksama ->
	# çok hızlı vuruş -> ağırlığın taşıdığı uzun devam -> yavaş toparlanma. (_tmp/ed/gunbai_desc.md)
	# roll 0: dikey savuruşta kenar önde, yatay savuruşta yassı yüz önde; roll 90: sap dik iken yüz rakibe (kalkan)
	var S = SamehadaAnim
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	return [
		# 1: kenar yarması — sağ omzun çok arkasına kaldırıp başın arkasına yatırır, gövde sağa burulur ve geriye yaslanır; balta gibi çapraz indirir
		{"len": 0.95, "hit": 0.42, "keys": [
			_g(0.0, 0.3, 0, 5, Vector3(0.0, 0.4, 0.9), S.H_CHEST, S.L_DOWN, W),
			_g(0.16, 0.25, -25, -10, Vector3(-0.2, 0.95, -0.1), S.H_ABOVE, S.L_FWD, W),
			_g(0.28, 0.3, -40, -18, Vector3(-0.15, 0.4, -0.9), S.H_COCK, S.L_FWD, W),
			_g(0.34, 0.3, -42, -20, Vector3(-0.15, 0.3, -0.95), S.H_COCK, S.L_FWD, W),
			_g(0.42, 0.65, 15, 32, Vector3(0.35, -0.3, 0.88), S.H_FOREHEAD, S.L_BACK, L),
			_g(0.52, 0.75, 30, 42, Vector3(0.65, -0.65, 0.4), S.H_LHIP, S.L_BACK, L),
			_g(0.7, 0.7, 28, 38, Vector3(0.65, -0.68, 0.35), S.H_LHIP, S.L_BACK, L),
			_g(0.95, 0.55, 20, 25, Vector3(0.6, -0.65, 0.45), S.H_LHIP, S.L_DOWN, L),
		]},
		# 2: yüzle ters tokat — solda alçakta sola-arkaya iyice çeker (gövde sola burulur), yassı yüzle soldan sağa geniş savurur
		{"len": 0.9, "hit": 0.38, "keys": [
			_g(0.0, 0.55, 20, 25, Vector3(0.6, -0.65, 0.45), S.H_LHIP, S.L_DOWN, L),
			_g(0.2, 0.55, 45, 22, Vector3(0.7, -0.35, -0.62), S.H_LHIP, S.L_SIDE, L),
			_g(0.3, 0.55, 50, 20, Vector3(0.6, -0.3, -0.74), S.H_LHIP, S.L_SIDE, L),
			_g(0.38, 0.55, -5, 22, Vector3(0.0, 0.08, 1.0), S.H_CHEST, S.L_BACK, L),
			_g(0.5, 0.45, -38, 10, Vector3(-0.85, 0.45, 0.25), S.H_SIDE, S.L_FWD, W),
			_g(0.68, 0.4, -40, 6, Vector3(-0.75, 0.55, -0.35), S.H_SH_UP, S.L_FWD, W),
			_g(0.9, 0.35, -30, 2, Vector3(-0.5, 0.6, -0.6), S.H_SH_UP, S.L_DOWN, W),
		]},
		# 3: mızrak saplaması — başı kalçanın arkasına çeker, ağırlık arka ayakta, gövde geriye; derin hamleyle ileri saplar, tutar, geri çeker
		{"len": 0.9, "hit": 0.37, "keys": [
			_g(0.0, 0.35, -30, 2, Vector3(-0.5, 0.6, -0.6), S.H_SH_UP, S.L_DOWN, W),
			_g(0.18, 0.45, -35, -8, Vector3(-0.1, 0.0, 1.0), S.H_HIP_SIDE, S.L_FWD, W),
			_g(0.3, 0.5, -40, -12, Vector3(-0.08, -0.02, 1.0), S.H_HIP_SIDE, S.L_FWD, W),
			_g(0.37, 0.75, 15, 34, Vector3(0.0, 0.0, 1.0), S.H_FWD, S.L_BACK, L),
			_g(0.55, 0.75, 15, 34, Vector3(0.0, -0.03, 1.0), S.H_FWD, S.L_BACK, L),
			_g(0.9, 0.5, 5, 15, Vector3(0.0, 0.3, 0.95), S.H_CHEST, S.L_DOWN, L),
		]},
		# 4: kalkan + emme — ağır adımla geri çekilip yüzü rakibe dik kaldırır, ağırlığını verip bekler; yüzde chakra toplanır
		{"len": 0.75, "hit": 0.38, "keys": [
			_g(0.0, 0.5, 5, 15, Vector3(0.0, 0.3, 0.95), S.H_CHEST, S.L_DOWN, L, 30.0),
			_g(0.25, 0.55, -8, 12, Vector3(0.0, 0.95, 0.3), S.H_CHEST, S.L_DOWN, W, 90.0),
			_g(0.35, 0.5, -6, 10, Vector3(0.0, 0.95, 0.32), S.H_CHEST, S.L_DOWN, W, 90.0),
			_g(0.75, 0.5, -6, 10, Vector3(0.0, 0.95, 0.3), S.H_CHEST, S.L_DOWN, W, 90.0),
		]},
		# 5: Uchiha Gaeshi — kalkanla çömelip geriye yaylanır (ağırlık arka ayakta), patlayarak öne yüklenir ve iter, gövde ağırlıkla öne taşar
		{"len": 0.95, "hit": 0.38, "keys": [
			_g(0.0, 0.5, -6, 10, Vector3(0.0, 0.95, 0.3), S.H_CHEST, S.L_DOWN, W, 90.0),
			_g(0.22, 0.7, -12, -12, Vector3(0.0, 0.95, 0.22), S.H_CHEST, S.L_DOWN, W, 90.0),
			_g(0.3, 0.72, -14, -14, Vector3(0.0, 0.95, 0.2), S.H_CHEST, S.L_DOWN, W, 90.0),
			_g(0.38, 0.65, 12, 34, Vector3(0.0, 0.9, 0.44), S.H_FWD, S.L_BACK, L, 90.0),
			_g(0.55, 0.75, 14, 42, Vector3(0.0, 0.85, 0.52), S.H_FWD, S.L_BACK, L, 90.0),
			_g(0.95, 0.55, 8, 25, Vector3(0.0, 0.9, 0.42), S.H_CHEST, S.L_DOWN, L, 90.0),
		]},
	]
