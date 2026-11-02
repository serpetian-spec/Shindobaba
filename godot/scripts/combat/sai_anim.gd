extends RefCounted
## Sai kombosu (çift el): SAPLAMA silahı — savurma yok. Her vuruş: dirsek geriye kurulur (sai ucu hep öne bakar, yumruk kalçada /
## göğüs yanında "hazne"), ağırlık arka ayakta -> adımla kol dümdüz uzar, sai ucu hedefe saplanır -> kısa tutuş -> hazneye geri çekiş.
## Ayak işi her vuruşta (BK kurulma -> ST adım -> L/LL saplama -> W toparlanma).

const S = preload("res://scripts/combat/samehada_anim.gd")

# "hazne": üst kol geride, ön kol öne yatay — yumruk kalça/göğüs yanında, sai ucu ileri
const R_CHAMBER := {"RightUpperArm": Vector3(-0.3, -0.6, -0.75), "RightLowerArm": Vector3(-0.05, -0.05, 1)}
const R_CHAMBER_HI := {"RightUpperArm": Vector3(-0.45, -0.2, -0.87), "RightLowerArm": Vector3(-0.05, 0.1, 1)}   # göğüs hizası
const R_STAB := {"RightUpperArm": Vector3(-0.04, -0.05, 1), "RightLowerArm": Vector3(0.0, -0.03, 1)}             # düz ileri
const R_STAB_LOW := {"RightUpperArm": Vector3(-0.05, -0.45, 0.9), "RightLowerArm": Vector3(0.0, -0.3, 0.95)}     # karına
const R_STAB_UP := {"RightUpperArm": Vector3(-0.08, 0.2, 0.98), "RightLowerArm": Vector3(0.0, 0.55, 0.84)}       # çeneye yukarı
const R_LOW_CH := {"RightUpperArm": Vector3(-0.3, -0.85, -0.42), "RightLowerArm": Vector3(-0.05, -0.35, 0.94)}   # alçak hazne
const L_CHAMBER := {"LeftUpperArm": Vector3(0.3, -0.6, -0.75), "LeftLowerArm": Vector3(0.05, -0.05, 1)}
const L_STAB := {"LeftUpperArm": Vector3(0.04, -0.05, 1), "LeftLowerArm": Vector3(0.0, -0.03, 1)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.2, 0.3, 0.93)}
const L_CATCH := {"LeftUpperArm": Vector3(0.2, 0.35, 0.92), "LeftLowerArm": Vector3(-0.55, 0.6, 0.6)}   # yukarıda yakalama (yan dişler)
const L_LOW_CH := {"LeftUpperArm": Vector3(0.3, -0.85, -0.42), "LeftLowerArm": Vector3(0.05, -0.35, 0.94)}
const L_STAB_UP := {"LeftUpperArm": Vector3(0.08, 0.2, 0.98), "LeftLowerArm": Vector3(0.0, 0.55, 0.84)}
const GUARD_BLADE := Vector3(0.05, 0.1, 1.0)


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var BKL = S.mirror(S.LEG_BACK)
	var ST = S.LEG_STEP
	var STL = S.mirror(S.LEG_STEP)
	var F = Vector3(0.0, -0.03, 1.0)
	return [
		# 1 Öncü Saplama (sol): sol dirsek geriye kurulur, ağırlık geride -> sol ayakla kayıp sol sai dümdüz yüze saplanır
		{"len": 0.55, "hit": 0.27, "keys": [
			_t(0.0, 0.38, 0, 4, GUARD_BLADE, R_CHAMBER_HI, L_GUARD, W),
			_t(0.12, 0.42, 22, -8, GUARD_BLADE, R_CHAMBER_HI, L_CHAMBER, BKL),
			_t(0.19, 0.43, 24, -9, GUARD_BLADE, R_CHAMBER_HI, L_CHAMBER, BKL),
			_t(0.23, 0.4, 10, 2, GUARD_BLADE, R_CHAMBER_HI, L_CHAMBER, STL),
			_t(0.27, 0.48, -18, 16, GUARD_BLADE, R_CHAMBER_HI, L_STAB, LL),
			_t(0.36, 0.48, -19, 17, GUARD_BLADE, R_CHAMBER_HI, L_STAB, LL),
			_t(0.55, 0.4, -4, 6, GUARD_BLADE, R_CHAMBER_HI, L_GUARD, W),
		]},
		# 2 Arka Saplama (sağ): sağ dirsek ve kalça iyice geriye -> kalça dönerek sağ sai göğse saplanır
		{"len": 0.6, "hit": 0.3, "keys": [
			_t(0.0, 0.4, -4, 6, GUARD_BLADE, R_CHAMBER_HI, L_GUARD, W),
			_t(0.14, 0.44, -28, -8, F, R_CHAMBER, L_GUARD, BK),
			_t(0.22, 0.45, -30, -10, F, R_CHAMBER, L_GUARD, BK),
			_t(0.26, 0.42, -12, 4, F, R_CHAMBER, L_GUARD, ST),
			_t(0.3, 0.52, 18, 20, F, R_STAB, L_CHAMBER, L),
			_t(0.4, 0.52, 20, 22, F, R_STAB, L_CHAMBER, L),
			_t(0.6, 0.42, 6, 8, GUARD_BLADE, R_CHAMBER_HI, L_GUARD, W),
		]},
		# 3 Yağmur: yerinde sol-sağ-sol hızlı üç saplama (boksör gibi), ağırlık öne-arkaya aktarılır
		{"len": 0.72, "hit": 0.2, "extra_hits": [0.38, 0.54], "extra_radius": 2.0, "keys": [
			_t(0.0, 0.42, 6, 8, GUARD_BLADE, R_CHAMBER_HI, L_GUARD, W),
			_t(0.1, 0.45, 18, -4, F, R_CHAMBER, L_CHAMBER, BKL),
			_t(0.2, 0.5, -14, 14, F, R_CHAMBER, L_STAB, LL),
			_t(0.28, 0.48, 6, 6, F, R_CHAMBER, L_CHAMBER, W),
			_t(0.38, 0.52, 18, 16, F, R_STAB, L_CHAMBER, L),
			_t(0.46, 0.48, -4, 6, F, R_CHAMBER, L_CHAMBER, W),
			_t(0.54, 0.52, -16, 16, F, R_CHAMBER, L_STAB, LL),
			_t(0.72, 0.42, 0, 6, GUARD_BLADE, R_CHAMBER_HI, L_GUARD, W),
		]},
		# 4 Yakala ve Sapla: sol sai yukarıda rakibin kolunu yan dişlere alır (kilit), sağ dirsek alçakta geriye kurulur -> karına saplar
		{"len": 0.78, "hit": 0.42, "keys": [
			_t(0.0, 0.42, 0, 6, GUARD_BLADE, R_CHAMBER_HI, L_GUARD, W),
			_t(0.14, 0.42, 10, 2, GUARD_BLADE, R_CHAMBER_HI, L_CATCH, STL),
			_t(0.22, 0.44, 12, 4, GUARD_BLADE, R_CHAMBER_HI, L_CATCH, LL),
			_t(0.32, 0.55, -20, 2, Vector3(0, -0.25, 0.97), R_LOW_CH, L_CATCH, LL),
			_t(0.37, 0.56, -22, 1, Vector3(0, -0.25, 0.97), R_LOW_CH, L_CATCH, LL),
			_t(0.42, 0.6, 14, 22, Vector3(0, -0.3, 0.95), R_STAB_LOW, L_CATCH, L),
			_t(0.55, 0.6, 15, 22, Vector3(0, -0.32, 0.95), R_STAB_LOW, L_CATCH, L),
			_t(0.78, 0.42, 0, 6, GUARD_BLADE, R_CHAMBER_HI, L_GUARD, W),
		]},
		# 5 Yükselen Saplama: derin çömelip iki sai alçak haznede -> bedenle yaylanıp ikisi birden çeneye yukarı saplanır (havaya)
		{"len": 0.75, "hit": 0.38, "keys": [
			_t(0.0, 0.42, 0, 6, GUARD_BLADE, R_CHAMBER_HI, L_GUARD, W),
			_t(0.16, 0.75, 0, 24, Vector3(0, -0.2, 0.98), R_LOW_CH, L_LOW_CH, W),
			_t(0.28, 0.78, 0, 26, Vector3(0, -0.2, 0.98), R_LOW_CH, L_LOW_CH, W),
			_t(0.33, 0.55, 0, 8, Vector3(0, 0.3, 0.95), R_STAB, L_STAB, ST),
			_t(0.38, 0.25, 0, -12, Vector3(0, 0.6, 0.8), R_STAB_UP, L_STAB_UP, L),
			_t(0.48, 0.22, 0, -14, Vector3(0, 0.62, 0.78), R_STAB_UP, L_STAB_UP, L),
			_t(0.75, 0.42, 0, 4, GUARD_BLADE, R_CHAMBER_HI, L_GUARD, W),
		]},
		# 6 Çift Delik (bitiriş): iki dirsek iyice geride, gövde geriye yaslı, uzun duraksama -> uzun hamleyle iki sai birden
		# göğse saplanır, bir an saplı kalır, sonra sertçe geri çekilir (rakip geri savrulur)
		{"len": 1.0, "hit": 0.5, "keys": [
			_t(0.0, 0.42, 0, 4, GUARD_BLADE, R_CHAMBER_HI, L_GUARD, W),
			_t(0.18, 0.46, 0, -14, F, R_CHAMBER, L_CHAMBER, BK),
			_t(0.38, 0.48, 0, -18, F, R_CHAMBER, L_CHAMBER, BK),
			_t(0.44, 0.48, 0, -19, F, R_CHAMBER, L_CHAMBER, BK),
			_t(0.47, 0.45, 0, 0, F, R_CHAMBER, L_CHAMBER, ST),
			_t(0.5, 0.62, 0, 28, F, R_STAB, L_STAB, L),
			_t(0.7, 0.62, 0, 28, F, R_STAB, L_STAB, L),
			_t(0.8, 0.5, 0, 8, F, R_CHAMBER, L_CHAMBER, W),
			_t(1.0, 0.42, 0, 4, GUARD_BLADE, R_CHAMBER_HI, L_GUARD, W),
		]},
	]
