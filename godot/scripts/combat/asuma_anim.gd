extends RefCounted
## Chakura Tō (Asuma'nın bıçaklı muştaları) kombosu: İKİ EL, boks + bıçak. Her vuruşta kısa geri çekiş (kol geri, omuz döner),
## hızlı yumruk-kesik, kısa toparlanma. Bitiriş "Hien": bıçaklara chakra akar (mavi-beyaz), uzayan görünmez ağızla çift kesik.
## Yumruklar sol (L_*) ve sağ (R_*) kol pozlarıyla; bıçaklar yumruğa bağlı (bilek çevrilmez). Etkiler KeyedCombos.

const S = preload("res://scripts/combat/samehada_anim.gd")

# sağ kol
const R_GUARD := {"RightUpperArm": Vector3(-0.3, -0.75, 0.55), "RightLowerArm": Vector3(0.25, 0.6, 0.75)}        # gard: yumruk çene önünde
const R_COCK := {"RightUpperArm": Vector3(-0.6, -0.55, -0.55), "RightLowerArm": Vector3(-0.1, 0.4, 0.9)}         # yumruk geride, dirsek arkada
const R_JAB := {"RightUpperArm": Vector3(-0.08, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}                 # düz ileri
const R_HOOK := {"RightUpperArm": Vector3(-0.9, 0.05, 0.4), "RightLowerArm": Vector3(0.75, 0.1, 0.65)}           # kanca: kol yandan, ön kol içe
const R_HOOK_END := {"RightUpperArm": Vector3(0.2, 0.05, 0.95), "RightLowerArm": Vector3(0.95, 0.05, 0.2)}       # kanca bitişi: sol omuza
const R_LOW := {"RightUpperArm": Vector3(-0.35, -0.9, 0.2), "RightLowerArm": Vector3(-0.1, -0.6, 0.8)}           # aşağıda kurulu (aparkat)
const R_UPPER := {"RightUpperArm": Vector3(-0.2, -0.2, 0.95), "RightLowerArm": Vector3(0.05, 0.9, 0.4)}          # aparkat tepesi
const R_HIGH_BACK := {"RightUpperArm": Vector3(-0.6, 0.7, -0.3), "RightLowerArm": Vector3(0.1, 0.9, -0.4)}       # başın sağ-arkası
const R_CROSS := {"RightUpperArm": Vector3(0.3, -0.1, 0.95), "RightLowerArm": Vector3(0.9, 0.3, 0.2)}            # göğüs önünde çaprazlanmış
const R_OPEN := {"RightUpperArm": Vector3(-0.95, -0.1, 0.3), "RightLowerArm": Vector3(-0.85, -0.2, 0.5)}         # yana açılmış
# sol kol
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.25, 0.6, 0.75)}
const L_COCK := {"LeftUpperArm": Vector3(0.6, -0.55, -0.55), "LeftLowerArm": Vector3(0.1, 0.4, 0.9)}
const L_JAB := {"LeftUpperArm": Vector3(0.08, 0.05, 1), "LeftLowerArm": Vector3(0.0, 0.05, 1)}
const L_HOOK := {"LeftUpperArm": Vector3(0.9, 0.05, 0.4), "LeftLowerArm": Vector3(-0.75, 0.1, 0.65)}
const L_HOOK_END := {"LeftUpperArm": Vector3(-0.2, 0.05, 0.95), "LeftLowerArm": Vector3(-0.95, 0.05, 0.2)}
const L_LOW := {"LeftUpperArm": Vector3(0.35, -0.9, 0.2), "LeftLowerArm": Vector3(0.1, -0.6, 0.8)}
const L_UPPER := {"LeftUpperArm": Vector3(0.2, -0.2, 0.95), "LeftLowerArm": Vector3(-0.05, 0.9, 0.4)}
const L_CROSS := {"LeftUpperArm": Vector3(-0.3, -0.1, 0.95), "LeftLowerArm": Vector3(-0.9, 0.3, 0.2)}
const L_OPEN := {"LeftUpperArm": Vector3(0.95, -0.1, 0.3), "LeftLowerArm": Vector3(0.85, -0.2, 0.5)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.3, lean * 1.2, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	return [
		# 1 Sol düz kesik: sol yumruk geri çekilir, omuz döner -> düz ileri saplar (bıçak altından keser)
		{"len": 0.5, "hit": 0.2, "keys": [
			_t(0.0, 0.35, 0, 5, R_GUARD, L_GUARD, W),
			_t(0.1, 0.38, 15, 0, R_GUARD, L_COCK, W),
			_t(0.14, 0.38, 16, 0, R_GUARD, L_COCK, W),
			_t(0.2, 0.42, -18, 14, R_GUARD, L_JAB, L),
			_t(0.5, 0.38, -5, 6, R_GUARD, L_GUARD, W),
		]},
		# 2 Sağ kanca kesik: sağ omuz geriye -> yandan kavisle sola süpürür
		{"len": 0.55, "hit": 0.24, "keys": [
			_t(0.0, 0.38, -5, 6, R_GUARD, L_GUARD, W),
			_t(0.12, 0.4, -28, 2, R_COCK, L_GUARD, W),
			_t(0.17, 0.4, -30, 2, R_COCK, L_GUARD, W),
			_t(0.21, 0.45, 5, 12, R_HOOK, L_GUARD, L),
			_t(0.27, 0.45, 30, 14, R_HOOK_END, L_GUARD, L),
			_t(0.55, 0.38, 10, 6, R_GUARD, L_GUARD, W),
		]},
		# 3 Çift aparkat: diz kırılıp iki yumruk aşağıda kurulur -> ikisi birden yukarı keser (rakip havaya)
		{"len": 0.65, "hit": 0.3, "keys": [
			_t(0.0, 0.38, 10, 6, R_GUARD, L_GUARD, W),
			_t(0.16, 0.7, 0, 22, R_LOW, L_LOW, W),
			_t(0.24, 0.72, 0, 23, R_LOW, L_LOW, W),
			_t(0.3, 0.3, 0, -10, R_UPPER, L_UPPER, L),
			_t(0.4, 0.22, 0, -14, R_UPPER, L_UPPER, L),
			_t(0.65, 0.38, 0, 4, R_GUARD, L_GUARD, W),
		]},
		# 4 Sol gövde + sağ tepeden: sol kısa gövde kesiği, hemen sağ yumruk başın arkasından aşağı iner
		{"len": 0.7, "hit": 0.42, "extra_hits": [0.2], "extra_radius": 1.8, "keys": [
			_t(0.0, 0.38, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.1, 0.5, 18, 12, R_GUARD, L_COCK, W),
			_t(0.2, 0.55, -10, 20, R_GUARD, L_JAB, L),
			_t(0.32, 0.45, -20, -8, R_HIGH_BACK, L_GUARD, L),
			_t(0.37, 0.45, -21, -9, R_HIGH_BACK, L_GUARD, L),
			_t(0.42, 0.6, 10, 26, R_JAB, L_GUARD, L),
			_t(0.7, 0.4, 0, 6, R_GUARD, L_GUARD, W),
		]},
		# 5 Çapraz X kesik: iki kol göğüs önünde çaprazlanır (kurulma) -> dışarı doğru açılarak X çizer
		{"len": 0.65, "hit": 0.32, "keys": [
			_t(0.0, 0.4, 0, 6, R_GUARD, L_GUARD, W),
			_t(0.16, 0.45, 0, -4, R_CROSS, L_CROSS, W),
			_t(0.26, 0.47, 0, -6, R_CROSS, L_CROSS, W),
			_t(0.32, 0.5, 0, 18, R_OPEN, L_OPEN, L),
			_t(0.65, 0.4, 0, 6, R_GUARD, L_GUARD, W),
		]},
		# 6 Hien (bitiriş): bıçaklara chakra akar (kurulma: iki yumruk geride, gövde geri), atılıp çift düz kesik — ağız uzar
		{"len": 0.95, "hit": 0.48, "keys": [
			_t(0.0, 0.4, 0, 6, R_GUARD, L_GUARD, W),
			_t(0.2, 0.45, 0, -12, R_COCK, L_COCK, W),
			_t(0.38, 0.48, 0, -16, R_COCK, L_COCK, W),
			_t(0.44, 0.55, -8, 22, R_JAB, L_COCK, L),
			_t(0.48, 0.6, 8, 28, R_JAB, L_JAB, L),
			_t(0.95, 0.4, 0, 6, R_GUARD, L_GUARD, W),
		]},
	]
