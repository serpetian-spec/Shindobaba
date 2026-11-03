extends RefCounted
## Nuibari (ref nuibari.png): çok uzun iğne-kılıç — İĞNELEME silahı. Savurmaz, saplar: kol geri çekilir -> duraksama -> şimşek gibi
## dümdüz ileri saplama -> iğne düşmanı delip geçer; tel (KeyedCombos._needle) delinenleri birbirine diker ve çeker.
## 1 hızlı saplama, 2 delip geçen çift saplama, 3 telle fırlatış (yolundakileri deler, tel çekince döner, delinenleri sürükler),
## 4 alttan yukarı saplama, 5 tel ucunda çevrede döndürme, 6 Kage Nui (bitiriş): üç düşmanı birbirine dikip çeker.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.3, -0.6, 0.75), "RightLowerArm": Vector3(0.05, 0.1, 1)}           # iğne önde, uç hedefe
const R_DRAW := {"RightUpperArm": Vector3(-0.45, -0.5, -0.75), "RightLowerArm": Vector3(0.1, 0.25, 0.97)}       # dirsek geride: saplama kurulumu
const R_THRUST := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.0, 1)}             # kol tam ileri
const R_LOW := {"RightUpperArm": Vector3(-0.25, -0.9, 0.3), "RightLowerArm": Vector3(0.0, -0.3, 0.95)}          # alçak (yukarı saplama kurulumu)
const R_UP := {"RightUpperArm": Vector3(-0.1, 0.75, 0.65), "RightLowerArm": Vector3(0.0, 0.9, 0.4)}             # yukarı saplama
const R_HIGH := {"RightUpperArm": Vector3(-0.5, 0.6, -0.6), "RightLowerArm": Vector3(-0.1, 0.9, 0.3)}           # baş üstü-arkası (fırlatış)
const R_WIDE := {"RightUpperArm": Vector3(-0.95, 0.1, 0.25), "RightLowerArm": Vector3(-0.9, 0.1, 0.4)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.2, 0.3, 0.93)}
const L_AIM := {"LeftUpperArm": Vector3(0.1, 0.05, 1), "LeftLowerArm": Vector3(-0.1, 0.0, 1)}                 # sol el hedefi gösterir
const L_BACK := {"LeftUpperArm": Vector3(0.5, -0.6, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}
const L_PULL := {"LeftUpperArm": Vector3(0.35, -0.7, -0.6), "LeftLowerArm": Vector3(-0.1, 0.0, 1)}             # teli kalçaya çeker


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var F = Vector3(0, 0, 1)
	return [
		# 1 Hari Tsuki: dirsek geri, uç hedefte (bekle) -> uzun adımla şimşek saplama -> geri çek
		{"len": 0.7, "hit": 0.3, "keys": [
			_t(0.0, 0.34, -6, 4, F, R_READY, L_AIM, W),
			_t(0.16, 0.4, -18, -6, F, R_DRAW, L_AIM, BK),
			_t(0.26, 0.42, -20, -8, F, R_DRAW, L_AIM, BK),
			_t(0.3, 0.5, 10, 20, F, R_THRUST, L_BACK, L),
			_t(0.45, 0.48, 8, 16, F, R_THRUST, L_BACK, L),
			_t(0.7, 0.34, -6, 4, F, R_READY, L_AIM, W),
		]},
		# 2 Nui Tsuki: iki ardışık saplama, iğne öndekinden arkasındakine geçer (delip geçen hat)
		{"len": 0.85, "hit": 0.24, "extra": [0.5], "extra_r": 1.2, "keys": [
			_t(0.0, 0.34, -6, 4, F, R_READY, L_AIM, W),
			_t(0.14, 0.42, -18, -6, F, R_DRAW, L_AIM, BK),
			_t(0.24, 0.5, 8, 18, F, R_THRUST, L_BACK, ST),
			_t(0.38, 0.44, -14, -4, F, R_DRAW, L_AIM, ST),
			_t(0.5, 0.54, 12, 24, F, R_THRUST, L_BACK, L),
			_t(0.85, 0.34, -6, 4, F, R_READY, L_AIM, W),
		]},
		# 3 Ito Nage: iğne baş üstünden geriye kurulur -> mızrak gibi fırlatılır, sol el teli tutar -> tel çekilir, iğne döner
		{"len": 1.15, "hit": 0.36, "keys": [
			_t(0.0, 0.34, -6, 4, F, R_READY, L_AIM, W),
			_t(0.16, 0.4, -26, -12, Vector3(0, 0.4, 0.9), R_HIGH, L_AIM, BK),
			_t(0.3, 0.42, -30, -14, Vector3(0, 0.4, 0.9), R_HIGH, L_AIM, BK),
			_t(0.36, 0.48, 16, 22, F, R_THRUST, L_AIM, L),
			_t(0.62, 0.44, -10, -10, F, R_THRUST, L_PULL, BK),
			_t(0.85, 0.42, -12, -12, F, R_READY, L_PULL, BK),
			_t(1.15, 0.34, -6, 4, F, R_READY, L_AIM, W),
		]},
		# 4 Ten Tsuki: çömelip uç aşağıda -> gövdeyle doğrularak yukarı saplama, rakip havaya kalkar
		{"len": 0.8, "hit": 0.36, "keys": [
			_t(0.0, 0.34, -6, 4, F, R_READY, L_AIM, W),
			_t(0.16, 0.68, -10, 18, Vector3(0, -0.2, 1), R_LOW, L_GUARD, BK),
			_t(0.28, 0.7, -12, 20, Vector3(0, -0.2, 1), R_LOW, L_GUARD, BK),
			_t(0.36, 0.22, 6, -12, Vector3(0, 0.85, 0.5), R_UP, L_BACK, L),
			_t(0.55, 0.26, 4, -8, Vector3(0, 0.85, 0.5), R_UP, L_BACK, L),
			_t(0.8, 0.34, -6, 4, F, R_READY, L_AIM, W),
		]},
		# 5 Ito Senpū: iğne tel ucunda bırakılır, kol açılır; gövde dönerken iğne geniş çember çizer (çevreyi deler)
		{"len": 1.2, "hit": 0.3, "keys": [
			_t(0.0, 0.34, -6, 4, F, R_READY, L_AIM, W),
			_t(0.16, 0.42, 30, 4, Vector3(-0.9, 0, 0.3), R_WIDE, L_GUARD, CR),
			_t(0.4, 0.44, -40, 6, Vector3(-0.9, 0, 0.3), R_WIDE, L_GUARD, W),
			_t(0.66, 0.44, 40, 6, Vector3(-0.9, 0, 0.3), R_WIDE, L_GUARD, CR),
			_t(0.9, 0.42, -20, 4, Vector3(-0.9, 0, 0.3), R_WIDE, L_GUARD, W),
			_t(1.2, 0.34, -6, 4, F, R_READY, L_AIM, W),
		]},
		# 6 Kage Nui (bitiriş): uzun kurulum -> fırlatış; iğne üç düşmanı delip birbirine diker -> iki elle tel çekilir, hepsi bağlanıp sürüklenir
		{"len": 1.5, "hit": 0.4, "keys": [
			_t(0.0, 0.34, -6, 4, F, R_READY, L_AIM, W),
			_t(0.2, 0.42, -30, -14, Vector3(0, 0.4, 0.9), R_HIGH, L_AIM, BK),
			_t(0.36, 0.44, -34, -16, Vector3(0, 0.4, 0.9), R_HIGH, L_AIM, BK),
			_t(0.4, 0.5, 18, 24, F, R_THRUST, L_AIM, L),
			_t(0.8, 0.48, 14, 18, F, R_THRUST, L_AIM, L),
			_t(0.95, 0.46, -14, -16, F, R_DRAW, L_PULL, BK),
			_t(1.2, 0.44, -16, -18, F, R_DRAW, L_PULL, BK),
			_t(1.5, 0.34, -6, 4, F, R_READY, L_AIM, W),
		]},
	]
