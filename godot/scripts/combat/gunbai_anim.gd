class_name GunbaiAnim
## Gunbai kombosu (kaynak yok — _tmp/ed/gunbai_desc.md hayal edilmiş tarifinden birebir; her tarif satırı bir anahtar).
## Yön/kol kısayolları SamehadaAnim ile ortak. "roll": yelpazenin sap ekseni etrafında dönüşü (90 = yüz rakibe).

static func _g(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary, roll := 0.0) -> Dictionary:
	var k = SamehadaAnim._k(t, crouch, yaw, lean, blade, SamehadaAnim._a(r, l), legs)
	k["roll"] = roll
	return k


static func steps() -> Array:
	var S = SamehadaAnim
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	return [
		# 1: geniş yatay süpürme sağdan sola
		{"len": 0.6, "hit": 0.26, "keys": [
			_g(0.0, 0.35, -35, 5, Vector3(-0.75, 0.15, -0.65), S.H_HIP_SIDE, S.L_FWD, W),
			_g(0.14, 0.4, -20, 10, Vector3(-1.0, 0.12, 0.05), S.H_SIDE, S.L_FWD, W),
			_g(0.26, 0.55, 5, 20, Vector3(0.0, 0.1, 1.0), S.H_CHEST, S.L_SIDE, L),
			_g(0.40, 0.55, 30, 18, Vector3(0.85, 0.1, 0.5), S.H_LCHEST, S.L_BACK, L),
			_g(0.60, 0.45, 30, 12, Vector3(0.75, 0.15, -0.6), S.H_LSHOULDER, S.L_BACK, W),
		]},
		# 2: ters savuruş soldan sağa, hafif yükselerek
		{"len": 0.55, "hit": 0.24, "keys": [
			_g(0.0, 0.45, 30, 12, Vector3(0.75, 0.15, -0.6), S.H_LSHOULDER, S.L_BACK, W),
			_g(0.24, 0.55, 0, 20, Vector3(0.0, 0.2, 1.0), S.H_CHEST, S.L_SIDE, L),
			_g(0.40, 0.45, -30, 8, Vector3(-0.8, 0.5, 0.3), S.H_SH_UP, S.L_FWD, W),
			_g(0.55, 0.4, -30, 5, Vector3(-0.6, 0.6, -0.5), S.H_SH_UP, S.L_FWD, W),
		]},
		# 3: tepeden yere çakma
		{"len": 0.65, "hit": 0.38, "keys": [
			_g(0.0, 0.4, -30, 5, Vector3(-0.6, 0.6, -0.5), S.H_SH_UP, S.L_FWD, W),
			_g(0.18, 0.3, -10, -8, Vector3(0.0, 1.0, 0.0), S.H_ABOVE, S.L_FWD, W),
			_g(0.28, 0.3, -12, -12, Vector3(0.0, 0.35, -0.94), S.H_COCK, S.L_FWD, W),
			_g(0.38, 0.8, 10, 45, Vector3(0.0, -0.45, 0.9), S.H_LOW_FRONT, S.L_BACK, L),
			_g(0.65, 0.7, 10, 38, Vector3(0.0, -0.4, 0.92), S.H_LOW_FRONT, S.L_BACK, L),
		]},
		# 4: kalkan itişi (yüz rakibe)
		{"len": 0.55, "hit": 0.32, "keys": [
			_g(0.0, 0.55, 5, 25, Vector3(0.0, 0.5, 0.86), S.H_CHEST, S.L_DOWN, L, 60.0),
			_g(0.20, 0.35, -5, -5, Vector3(0.0, 0.95, 0.3), S.H_CHEST, S.L_DOWN, W, 90.0),
			_g(0.32, 0.6, 10, 25, Vector3(0.0, 0.92, 0.4), S.H_FWD, S.L_BACK, L, 90.0),
			_g(0.55, 0.55, 10, 22, Vector3(0.0, 0.92, 0.38), S.H_FWD, S.L_BACK, L, 90.0),
		]},
		# 5: kepçe savuruşu — yerden arkadan öne-yukarı dikey çember (dönüş yok)
		{"len": 0.8, "hit": 0.62, "keys": [
			_g(0.0, 0.5, 8, 18, Vector3(0.0, 0.92, 0.38), S.H_CHEST, S.L_BACK, L, 90.0),
			_g(0.12, 0.6, -15, 30, Vector3(-0.3, -0.5, -0.81), S.H_HANG, S.L_FWD, L, 90.0),
			_g(0.26, 0.8, -20, 38, Vector3(-0.2, -0.2, -0.96), S.H_HANG, S.L_FWD, L, 90.0),
			_g(0.40, 0.75, -10, 40, Vector3(-0.35, -0.6, 0.72), S.H_HIP_FRONT, S.L_FWD, L, 90.0),
			_g(0.52, 0.7, 0, 35, Vector3(0.0, -0.3, 0.95), S.H_LOW_FRONT, S.L_SIDE, L, 90.0),
			_g(0.62, 0.15, 5, 0, Vector3(0.0, 0.7, 0.71), S.H_CHEST, S.L_BACK, W, 90.0),
			_g(0.72, 0.05, 5, -10, Vector3(0.0, 1.0, 0.1), S.H_UP, S.L_BACK, W, 90.0),
			_g(0.80, 0.1, 5, -15, Vector3(0.0, 0.85, -0.53), S.H_UP, S.L_BACK, W, 90.0),
		]},
	]
