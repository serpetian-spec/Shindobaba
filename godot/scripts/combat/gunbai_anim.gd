class_name GunbaiAnim
## Gunbai kombosu (kaynak yok — _tmp/ed/gunbai_desc.md hayal edilmiş tarifinden birebir; her tarif satırı bir anahtar).
## Yön/kol kısayolları SamehadaAnim ile ortak. "roll": yelpazenin sap ekseni etrafında dönüşü (90 = yüz rakibe).

static func _g(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary, roll := 0.0) -> Dictionary:
	var k = SamehadaAnim._k(t, minf(1.0, crouch * 1.15), yaw * 1.6, lean * 1.35, blade, SamehadaAnim._a(r, l), legs)
	k["roll"] = roll
	return k


static func steps() -> Array:
	# _tmp/ed/gunbai_desc.md: ağır başlı sopa/kalkan — kenar yarması, yüzle tokat, mızrak saplaması, kalkan+emme, Uchiha Gaeshi
	# roll 0: dikey savuruşta kenar önde, yatay savuruşta yassı yüz önde; roll 90: sap dik iken yüz rakibe (kalkan)
	var S = SamehadaAnim
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	return [
		# 1: kenar yarması (balta) — sağ omuz üstünden çapraz aşağı
		{"len": 0.55, "hit": 0.24, "keys": [
			_g(0.0, 0.3, -15, -5, Vector3(-0.2, 0.6, -0.77), S.H_COCK, S.L_FWD, W),
			_g(0.12, 0.25, -12, -10, Vector3(-0.05, 1.0, 0.05), S.H_ABOVE, S.L_FWD, W),
			_g(0.24, 0.6, 18, 30, Vector3(0.35, -0.3, 0.88), S.H_FOREHEAD, S.L_BACK, L),
			_g(0.36, 0.65, 25, 34, Vector3(0.6, -0.6, 0.5), S.H_LCHEST, S.L_BACK, L),
			_g(0.55, 0.55, 22, 28, Vector3(0.62, -0.62, 0.45), S.H_LHIP, S.L_BACK, L),
		]},
		# 2: yassı yüzle ters tokat (kürek) — aşağı-soldan yukarı-sağa
		{"len": 0.5, "hit": 0.22, "keys": [
			_g(0.0, 0.55, 22, 28, Vector3(0.62, -0.62, 0.45), S.H_LHIP, S.L_BACK, L),
			_g(0.22, 0.5, -5, 18, Vector3(0.0, 0.1, 1.0), S.H_CHEST, S.L_SIDE, L),
			_g(0.35, 0.4, -25, 6, Vector3(-0.8, 0.5, 0.3), S.H_SH_UP, S.L_FWD, W),
			_g(0.50, 0.35, -25, 2, Vector3(-0.5, 0.6, -0.6), S.H_SH_UP, S.L_FWD, W),
		]},
		# 3: mızrak saplaması — başı kalçaya çek, derin hamleyle ileri sapla
		{"len": 0.55, "hit": 0.30, "keys": [
			_g(0.0, 0.35, -25, 2, Vector3(-0.5, 0.6, -0.6), S.H_SH_UP, S.L_FWD, W),
			_g(0.16, 0.45, -20, 10, Vector3(-0.05, -0.05, 1.0), S.H_HIP_SIDE, S.L_FWD, W),
			_g(0.30, 0.7, 12, 30, Vector3(0.0, 0.0, 1.0), S.H_FWD, S.L_BACK, L),
			_g(0.55, 0.6, 10, 24, Vector3(0.0, 0.02, 1.0), S.H_FWD, S.L_BACK, L),
		]},
		# 4: kalkan + emme — geri çekil, yüz rakibe (dik), yüzde chakra toplanır
		{"len": 0.6, "hit": 0.30, "keys": [
			_g(0.0, 0.55, 8, 20, Vector3(0.0, 0.3, 0.95), S.H_FWD, S.L_BACK, L, 45.0),
			_g(0.18, 0.4, -5, -6, Vector3(0.0, 0.95, 0.3), S.H_CHEST, S.L_DOWN, W, 90.0),
			_g(0.30, 0.42, -5, -4, Vector3(0.0, 0.95, 0.32), S.H_CHEST, S.L_DOWN, W, 90.0),
			_g(0.60, 0.42, -5, -4, Vector3(0.0, 0.95, 0.3), S.H_CHEST, S.L_DOWN, W, 90.0),
		]},
		# 5: Uchiha Gaeshi — kalkanla yüklenip itme, emilen enerji yüzden ateşli dalga olarak patlar; rakip düz geri savrulur
		{"len": 0.6, "hit": 0.28, "keys": [
			_g(0.0, 0.42, -5, -4, Vector3(0.0, 0.95, 0.3), S.H_CHEST, S.L_DOWN, W, 90.0),
			_g(0.15, 0.55, 5, 18, Vector3(0.0, 0.93, 0.36), S.H_CHEST, S.L_BACK, L, 90.0),
			_g(0.28, 0.65, 10, 30, Vector3(0.0, 0.9, 0.44), S.H_FWD, S.L_BACK, L, 90.0),
			_g(0.60, 0.6, 10, 28, Vector3(0.0, 0.9, 0.42), S.H_FWD, S.L_BACK, L, 90.0),
		]},
	]
