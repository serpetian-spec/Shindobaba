extends RefCounted
## Sai kombosu (çift el): okinawa kobudo ruhu — savunmadan saldırıya; ayaklar hep oyunda (adım, çapraz adım, ağırlık aktarımı).
## Her vuruş: belirgin geri çekiş (gövde ters burulur, ağırlık arka ayakta) -> hızlı vuruş (adımla) -> devam -> toparlanma.
## Yaratıcı noktalar: sai'yi avuçta ters çevirip topuzla vurma, yan dişlerle kilitleyip bileği burma, iki sai'yle makas,
## dönerek arkaya saplama yok (dönüş yok) — onun yerine çapraz adımla yan geçip böğre saplama.

const S = preload("res://scripts/combat/samehada_anim.gd")

const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.2, 0.3, 0.93)}
const L_COCK := {"LeftUpperArm": Vector3(0.65, -0.45, -0.6), "LeftLowerArm": Vector3(0.15, 0.45, 0.88)}       # sol yumruk kulak arkasına kurulu
const L_STAB := {"LeftUpperArm": Vector3(0.05, 0.0, 1), "LeftLowerArm": Vector3(-0.02, 0.0, 1)}
const L_LOW := {"LeftUpperArm": Vector3(0.35, -0.9, 0.2), "LeftLowerArm": Vector3(0.1, -0.6, 0.8)}
const L_HIGH := {"LeftUpperArm": Vector3(0.35, 0.85, 0.35), "LeftLowerArm": Vector3(0.1, 0.95, 0.2)}
const L_DOWN_STAB := {"LeftUpperArm": Vector3(0.15, -0.3, 0.94), "LeftLowerArm": Vector3(0.0, -0.75, 0.66)}
const L_CROSS := {"LeftUpperArm": Vector3(-0.3, -0.1, 0.95), "LeftLowerArm": Vector3(-0.9, 0.3, 0.2)}
const L_OPEN := {"LeftUpperArm": Vector3(0.95, -0.1, 0.3), "LeftLowerArm": Vector3(0.85, -0.2, 0.5)}
const L_BEHIND := {"LeftUpperArm": Vector3(0.55, -0.6, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}       # geride dengede
const L_SHIELD := {"LeftUpperArm": Vector3(0.2, -0.3, 0.93), "LeftLowerArm": Vector3(-0.85, 0.45, 0.2)}       # ön kol yüzün önünde yatay (sai kalkan)


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)   # sol ayak önde
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	return [
		# 1 Kalkan ve Saplama: sol sai ön kolda kalkan gibi yatay, sağ omuz geriye kurulur (ağırlık arkada) -> adımla sağ düz saplama
		{"len": 0.62, "hit": 0.3, "keys": [
			_t(0.0, 0.35, 0, 4, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
			_t(0.12, 0.42, -26, -10, Vector3(0.0, 0.1, 1.0), S.H_BEHIND, L_SHIELD, BK),
			_t(0.22, 0.44, -30, -12, Vector3(0.0, 0.1, 1.0), S.H_BEHIND, L_SHIELD, BK),
			_t(0.26, 0.4, -10, 4, Vector3(0.0, 0.05, 1.0), S.H_HIP_SIDE, L_SHIELD, ST),
			_t(0.3, 0.5, 18, 22, Vector3(0.0, 0.0, 1.0), S.H_FWD, L_SHIELD, L),
			_t(0.42, 0.5, 20, 24, Vector3(0.0, -0.02, 1.0), S.H_FWD, L_SHIELD, L),
			_t(0.62, 0.42, 6, 8, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
		]},
		# 2 Ters Topuz: sağ sai avuçta ters döner (uç dirseğe), sol adımla gövde sağa burulur -> sol sai kancayla, sağ topuzla şakağa
		{"len": 0.7, "hit": 0.36, "keys": [
			_t(0.0, 0.42, 6, 8, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
			_t(0.14, 0.45, -34, -6, Vector3(0.1, -0.6, -0.8), S.H_SH_BACK, L_GUARD, BK),
			_t(0.26, 0.47, -40, -10, Vector3(0.1, -0.55, -0.83), S.H_SH_BACK, L_COCK, BK),
			_t(0.3, 0.45, -20, 0, Vector3(0.1, -0.55, -0.83), S.H_SH_BACK, L_COCK, ST),
			_t(0.36, 0.55, 22, 20, Vector3(0.6, -0.2, -0.77), S.H_LSHOULDER, L_STAB, LL),
			_t(0.46, 0.55, 30, 22, Vector3(0.7, -0.2, -0.68), S.H_LCHEST, L_STAB, LL),
			_t(0.7, 0.42, 10, 8, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
		]},
		# 3 Kilit ve Burgu: iki sai yukarıda çaprazlanır, rakibin kolunu yan dişlere alır (duraksama) -> bilekleri burup aşağı-geri
		# çeker; rakip öne düşer, sen geri adım atarsın
		{"len": 0.8, "hit": 0.42, "keys": [
			_t(0.0, 0.42, 10, 8, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
			_t(0.14, 0.4, 0, 2, Vector3(0.3, 0.55, 0.78), S.H_LSHOULDER, L_CROSS, ST),
			_t(0.22, 0.42, 0, 8, Vector3(0.3, 0.55, 0.78), S.H_LSHOULDER, L_CROSS, L),
			_t(0.34, 0.42, 0, 8, Vector3(0.35, 0.5, 0.79), S.H_LSHOULDER, L_CROSS, L),
			_t(0.42, 0.62, -8, -18, Vector3(-0.3, -0.5, 0.81), S.H_HIP_FRONT, L_LOW, BK),
			_t(0.56, 0.66, -10, -22, Vector3(-0.3, -0.55, 0.78), S.H_HIP_FRONT, L_BEHIND, BK),
			_t(0.8, 0.45, 0, 4, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
		]},
		# 4 Yan Geçiş: çapraz adımla rakibin sol yanına kayılır (gövde alçak, sai'ler göğüste) -> sağ sai böğre, sol sai sırta saplanır
		{"len": 0.8, "hit": 0.42, "extra_hits": [0.52], "extra_radius": 2.0, "keys": [
			_t(0.0, 0.45, 0, 4, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
			_t(0.16, 0.6, 30, 10, Vector3(0.6, 0.2, 0.77), S.H_LCHEST, L_CROSS, CR),
			_t(0.3, 0.62, 45, 12, Vector3(0.6, 0.2, 0.77), S.H_LCHEST, L_CROSS, CR),
			_t(0.36, 0.6, 20, 20, Vector3(0.9, 0.0, 0.4), S.H_LCHEST, L_CROSS, LL),
			_t(0.42, 0.62, -10, 26, Vector3(0.95, -0.1, 0.25), S.H_SIDE, L_CROSS, LL),
			_t(0.52, 0.6, -25, 24, Vector3(0.95, -0.1, 0.25), S.H_SIDE, L_DOWN_STAB, LL),
			_t(0.8, 0.45, -8, 6, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
		]},
		# 5 Makas: iki sai dışa açılıp geriye kurulur (göğüs açık, geriye yaslanır) -> öne adımla makas gibi kapanır, çaprazlanıp
		# aşağıdan yukarı ayrılır (rakip havaya)
		{"len": 0.8, "hit": 0.4, "keys": [
			_t(0.0, 0.45, -8, 6, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
			_t(0.16, 0.42, 0, -16, Vector3(-0.8, 0.1, -0.5), S.H_SIDE, L_OPEN, BK),
			_t(0.28, 0.44, 0, -18, Vector3(-0.85, 0.1, -0.5), S.H_SIDE, L_OPEN, BK),
			_t(0.34, 0.55, 0, 16, Vector3(0.3, 0.0, 0.95), S.H_LCHEST, L_CROSS, ST),
			_t(0.4, 0.58, 0, 20, Vector3(0.3, -0.3, 0.9), S.H_LCHEST, L_CROSS, L),
			_t(0.5, 0.3, 0, -8, Vector3(-0.2, 0.9, 0.4), S.H_FOREHEAD, L_HIGH, L),
			_t(0.8, 0.4, 0, 4, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
		]},
		# 6 Ejder Dişi (bitiriş): iki sai başın üstünde dikey, gövde geriye kavisli, ağırlık arka ayakta (uzun duraksama) ->
		# sıçrar gibi derin hamleyle ikisini birden öne-aşağı saplar, çömelir, rakip yere çakılır
		{"len": 1.0, "hit": 0.52, "keys": [
			_t(0.0, 0.4, 0, 4, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
			_t(0.18, 0.35, 0, -16, Vector3(0.0, 0.9, -0.4), S.H_UP, L_HIGH, BK),
			_t(0.36, 0.33, 0, -22, Vector3(0.0, 0.85, -0.52), S.H_UP, L_HIGH, BK),
			_t(0.44, 0.36, 0, -24, Vector3(0.0, 0.84, -0.54), S.H_UP, L_HIGH, BK),
			_t(0.48, 0.3, 0, 4, Vector3(0.0, 0.8, 0.6), S.H_ABOVE, L_HIGH, ST),
			_t(0.52, 0.85, 4, 40, Vector3(0.0, -0.55, 0.84), S.H_LOW_FRONT, L_DOWN_STAB, L),
			_t(0.75, 0.88, 4, 38, Vector3(0.0, -0.56, 0.83), S.H_LOW_FRONT, L_DOWN_STAB, L),
			_t(1.0, 0.45, 0, 8, Vector3(0.1, 0.2, 1.0), S.H_CHEST, L_GUARD, W),
		]},
	]
