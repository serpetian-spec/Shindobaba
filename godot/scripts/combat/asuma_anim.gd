extends RefCounted
## Chakura Tō (Asuma'nın bıçaklı muştaları) kombosu: İKİ EL, boks + bıçak; ayak işi boksörün ki gibi (geri adım, ağırlık aktarımı,
## öne kayış, eğilip kaçış). Her vuruş: belirgin geri çekiş (omuz ve kalça ters burulur, ağırlık arka ayakta) -> adımla hızlı
## yumruk-kesik -> devam -> toparlanma. Yaratıcı: eğilip-kalkış (bob & weave) aparkatı, dirsekle bıçak, Hien'de chakra ağzı.

const S = preload("res://scripts/combat/samehada_anim.gd")

# sağ kol
const R_GUARD := {"RightUpperArm": Vector3(-0.3, -0.75, 0.55), "RightLowerArm": Vector3(0.25, 0.6, 0.75)}
const R_COCK := {"RightUpperArm": Vector3(-0.65, -0.5, -0.57), "RightLowerArm": Vector3(-0.15, 0.45, 0.88)}
const R_JAB := {"RightUpperArm": Vector3(-0.06, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}
const R_HOOK := {"RightUpperArm": Vector3(-0.9, 0.05, 0.4), "RightLowerArm": Vector3(0.75, 0.1, 0.65)}
const R_HOOK_END := {"RightUpperArm": Vector3(0.2, 0.05, 0.95), "RightLowerArm": Vector3(0.95, 0.05, 0.2)}
const R_LOW := {"RightUpperArm": Vector3(-0.35, -0.9, 0.2), "RightLowerArm": Vector3(-0.1, -0.6, 0.8)}
const R_UPPER := {"RightUpperArm": Vector3(-0.2, -0.2, 0.95), "RightLowerArm": Vector3(0.05, 0.9, 0.4)}
const R_HIGH_BACK := {"RightUpperArm": Vector3(-0.6, 0.7, -0.3), "RightLowerArm": Vector3(0.1, 0.9, -0.4)}
const R_CROSS := {"RightUpperArm": Vector3(0.3, -0.1, 0.95), "RightLowerArm": Vector3(0.9, 0.3, 0.2)}
const R_OPEN := {"RightUpperArm": Vector3(-0.95, -0.1, 0.3), "RightLowerArm": Vector3(-0.85, -0.2, 0.5)}
const R_ELBOW := {"RightUpperArm": Vector3(-0.4, 0.2, 0.9), "RightLowerArm": Vector3(0.9, 0.2, -0.3)}       # dirsek öne, ön kol göğse katlı
# sol kol
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.25, 0.6, 0.75)}
const L_COCK := {"LeftUpperArm": Vector3(0.65, -0.5, -0.57), "LeftLowerArm": Vector3(0.15, 0.45, 0.88)}
const L_JAB := {"LeftUpperArm": Vector3(0.06, 0.05, 1), "LeftLowerArm": Vector3(0.0, 0.05, 1)}
const L_HOOK := {"LeftUpperArm": Vector3(0.9, 0.05, 0.4), "LeftLowerArm": Vector3(-0.75, 0.1, 0.65)}
const L_HOOK_END := {"LeftUpperArm": Vector3(-0.2, 0.05, 0.95), "LeftLowerArm": Vector3(-0.95, 0.05, 0.2)}
const L_LOW := {"LeftUpperArm": Vector3(0.35, -0.9, 0.2), "LeftLowerArm": Vector3(0.1, -0.6, 0.8)}
const L_UPPER := {"LeftUpperArm": Vector3(0.2, -0.2, 0.95), "LeftLowerArm": Vector3(-0.05, 0.9, 0.4)}
const L_CROSS := {"LeftUpperArm": Vector3(-0.3, -0.1, 0.95), "LeftLowerArm": Vector3(-0.9, 0.3, 0.2)}
const L_OPEN := {"LeftUpperArm": Vector3(0.95, -0.1, 0.3), "LeftLowerArm": Vector3(0.85, -0.2, 0.5)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var BKL = S.mirror(S.LEG_BACK)
	var ST = S.LEG_STEP
	var STL = S.mirror(S.LEG_STEP)
	return [
		# 1 Öncü Kesik: ağırlık arkaya, sol omuz geri burulur -> sol ayakla öne kayarak sol düz kesik (bıçak altından biçer)
		{"len": 0.58, "hit": 0.28, "keys": [
			_t(0.0, 0.38, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.12, 0.42, 24, -8, R_GUARD, L_COCK, BKL),
			_t(0.2, 0.43, 26, -10, R_GUARD, L_COCK, BKL),
			_t(0.24, 0.4, 10, 2, R_GUARD, L_COCK, STL),
			_t(0.28, 0.48, -18, 18, R_GUARD, L_JAB, LL),
			_t(0.38, 0.48, -20, 20, R_GUARD, L_JAB, LL),
			_t(0.58, 0.4, -4, 6, R_GUARD, L_GUARD, W),
		]},
		# 2 Kanca Kesiği: kalça ve sağ omuz iyice geriye (ağırlık sağ arka ayakta) -> kalçadan açılan geniş sağ kanca, bıçak yay çizer
		{"len": 0.66, "hit": 0.32, "keys": [
			_t(0.0, 0.4, -4, 6, R_GUARD, L_GUARD, W),
			_t(0.14, 0.45, -36, -6, R_COCK, L_GUARD, BK),
			_t(0.24, 0.46, -40, -8, R_COCK, L_GUARD, BK),
			_t(0.28, 0.48, -10, 8, R_HOOK, L_GUARD, ST),
			_t(0.32, 0.5, 18, 16, R_HOOK, L_GUARD, L),
			_t(0.4, 0.5, 38, 18, R_HOOK_END, L_GUARD, L),
			_t(0.66, 0.4, 12, 6, R_GUARD, L_GUARD, W),
		]},
		# 3 Eğil-Kalk Aparkatı: başını eğip yandan kaçar (bob & weave, diz bükük, gövde sola-aşağı) -> yaylanıp çift aparkat (havaya)
		{"len": 0.78, "hit": 0.4, "keys": [
			_t(0.0, 0.4, 12, 6, R_GUARD, L_GUARD, W),
			_t(0.14, 0.72, 18, 26, R_GUARD, L_GUARD, W),
			_t(0.24, 0.78, -14, 30, R_LOW, L_GUARD, W),
			_t(0.32, 0.8, -4, 28, R_LOW, L_LOW, W),
			_t(0.4, 0.25, 0, -12, R_UPPER, L_UPPER, ST),
			_t(0.5, 0.2, 0, -16, R_UPPER, L_UPPER, L),
			_t(0.78, 0.4, 0, 4, R_GUARD, L_GUARD, W),
		]},
		# 4 Dirsek ve Tepeden: sol kısa gövde kesiği, dönen kalçayla sağ dirsek; hemen sağ yumruk başın arkasından aşağı iner
		{"len": 0.85, "hit": 0.52, "extra_hits": [0.24], "extra_radius": 1.8, "keys": [
			_t(0.0, 0.4, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.12, 0.5, 20, 12, R_GUARD, L_COCK, BKL),
			_t(0.24, 0.55, -10, 20, R_ELBOW, L_JAB, LL),
			_t(0.36, 0.45, -24, -10, R_HIGH_BACK, L_GUARD, BK),
			_t(0.46, 0.45, -26, -12, R_HIGH_BACK, L_GUARD, BK),
			_t(0.52, 0.62, 12, 28, R_JAB, L_GUARD, L),
			_t(0.85, 0.4, 0, 6, R_GUARD, L_GUARD, W),
		]},
		# 5 X Biçme: iki kol göğüste çaprazlanıp kurulur, ağırlık geride (geri adım) -> öne kayarken dışa açılarak X çizer
		{"len": 0.75, "hit": 0.38, "keys": [
			_t(0.0, 0.4, 0, 6, R_GUARD, L_GUARD, W),
			_t(0.16, 0.48, 0, -10, R_CROSS, L_CROSS, BK),
			_t(0.28, 0.5, 0, -12, R_CROSS, L_CROSS, BK),
			_t(0.33, 0.48, 0, 4, R_CROSS, L_CROSS, ST),
			_t(0.38, 0.55, 0, 20, R_OPEN, L_OPEN, L),
			_t(0.75, 0.4, 0, 6, R_GUARD, L_GUARD, W),
		]},
		# 6 Hien (bitiriş): iki yumruk geride, chakra bıçaklara akar (uzun kurulma, gövde geriye) -> atılıp çift düz kesik, ağız uzar
		{"len": 1.05, "hit": 0.56, "keys": [
			_t(0.0, 0.4, 0, 6, R_GUARD, L_GUARD, W),
			_t(0.2, 0.48, 0, -14, R_COCK, L_COCK, BK),
			_t(0.42, 0.5, 0, -18, R_COCK, L_COCK, BK),
			_t(0.48, 0.45, 0, -2, R_COCK, L_COCK, ST),
			_t(0.52, 0.55, -10, 22, R_JAB, L_COCK, L),
			_t(0.56, 0.62, 10, 30, R_JAB, L_JAB, L),
			_t(0.8, 0.62, 10, 28, R_JAB, L_JAB, L),
			_t(1.05, 0.4, 0, 6, R_GUARD, L_GUARD, W),
		]},
	]
