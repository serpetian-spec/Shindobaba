extends RefCounted
## Pençe (ref claw.png) — İKİ EL: vahşi, hızlı yırtma kombosu; her vuruşta bıçaklara chakra akar (KeyedCombos: üç paralel parlayan
## pençe izi). 1 sağ çapraz yırtık, 2 sol ters yırtık, 3 çift X yırtık, 4 çömelip yukarı çift pençe (kaldırır), 5 sıçrayıp üstten
## pençe dalışı, 6 Chakra Sōga (bitiriş): iki pençe tam chakra yüklü, ileri atılıp dev X kesik.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_GUARD := {"RightUpperArm": Vector3(-0.3, -0.6, 0.72), "RightLowerArm": Vector3(0.3, 0.55, 0.78)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.6, 0.72), "LeftLowerArm": Vector3(-0.3, 0.55, 0.78)}
const R_HIGH := {"RightUpperArm": Vector3(-0.6, 0.7, -0.2), "RightLowerArm": Vector3(-0.2, 0.9, 0.3)}
const L_HIGH := {"LeftUpperArm": Vector3(0.6, 0.7, -0.2), "LeftLowerArm": Vector3(0.2, 0.9, 0.3)}
const R_RAKE := {"RightUpperArm": Vector3(0.35, -0.4, 0.86), "RightLowerArm": Vector3(0.8, -0.4, 0.45)}        # sol kalçaya yırtmış
const L_RAKE := {"LeftUpperArm": Vector3(-0.35, -0.4, 0.86), "LeftLowerArm": Vector3(-0.8, -0.4, 0.45)}
const R_LOW := {"RightUpperArm": Vector3(-0.35, -0.9, 0.2), "RightLowerArm": Vector3(-0.1, -0.6, 0.8)}
const L_LOW := {"LeftUpperArm": Vector3(0.35, -0.9, 0.2), "LeftLowerArm": Vector3(0.1, -0.6, 0.8)}
const R_UP := {"RightUpperArm": Vector3(-0.15, 0.8, 0.6), "RightLowerArm": Vector3(0.0, 0.95, 0.3)}
const L_UP := {"LeftUpperArm": Vector3(0.15, 0.8, 0.6), "LeftLowerArm": Vector3(0.0, 0.95, 0.3)}
const R_FWD := {"RightUpperArm": Vector3(-0.1, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}
const L_FWD := {"LeftUpperArm": Vector3(0.1, 0.05, 1), "LeftLowerArm": Vector3(0.0, 0.05, 1)}
const R_BACK := {"RightUpperArm": Vector3(-0.65, -0.5, -0.57), "RightLowerArm": Vector3(-0.15, 0.45, 0.88)}
const L_BACK := {"LeftUpperArm": Vector3(0.65, -0.5, -0.57), "LeftLowerArm": Vector3(0.15, 0.45, 0.88)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, Vector3(0, 0, 1), S._a(r, l), legs)


# SAVURMA pozları: pençe bıçakları parmak yönünde (ön kol doğrultusu) olduğu için kolun yay çizmesi = bıçakların savrulması.
# Geniş geri çekiş (kol dışarı-geri) -> gövdenin önünden geçiş -> karşı kalçaya/omza süpürme; ara anahtar yayın önden geçmesini sağlar.
const R_WIDE := {"RightUpperArm": Vector3(-0.85, 0.15, -0.5), "RightLowerArm": Vector3(-0.75, 0.25, -0.6)}       # sağ-arkaya açılmış
const L_WIDE := {"LeftUpperArm": Vector3(0.85, 0.15, -0.5), "LeftLowerArm": Vector3(0.75, 0.25, -0.6)}
const R_SIDE := {"RightUpperArm": Vector3(-0.8, 0.1, 0.55), "RightLowerArm": Vector3(-0.45, 0.1, 0.9)}          # sağ önde, yay ortası
const L_SIDE := {"LeftUpperArm": Vector3(0.8, 0.1, 0.55), "LeftLowerArm": Vector3(0.45, 0.1, 0.9)}
const R_MID := {"RightUpperArm": Vector3(-0.2, 0.05, 0.98), "RightLowerArm": Vector3(0.35, 0.0, 0.94)}         # tam önden geçiş
const L_MID := {"LeftUpperArm": Vector3(0.2, 0.05, 0.98), "LeftLowerArm": Vector3(-0.35, 0.0, 0.94)}
const R_ACROSS := {"RightUpperArm": Vector3(0.5, -0.1, 0.86), "RightLowerArm": Vector3(0.95, -0.05, 0.3)}      # sol omuza süpürülmüş
const L_ACROSS := {"LeftUpperArm": Vector3(-0.5, -0.1, 0.86), "LeftLowerArm": Vector3(-0.95, -0.05, 0.3)}
const R_HSIDE := {"RightUpperArm": Vector3(-0.75, 0.6, 0.25), "RightLowerArm": Vector3(-0.5, 0.8, 0.35)}        # sağ üstte (çapraz iniş başı)
const L_HSIDE := {"LeftUpperArm": Vector3(0.75, 0.6, 0.25), "LeftLowerArm": Vector3(0.5, 0.8, 0.35)}
const R_LOWOUT := {"RightUpperArm": Vector3(-0.6, -0.75, 0.3), "RightLowerArm": Vector3(-0.55, -0.6, 0.6)}    # sağ alt dış (yukarı savurma başı)
const L_LOWOUT := {"LeftUpperArm": Vector3(0.6, -0.75, 0.3), "LeftLowerArm": Vector3(0.55, -0.6, 0.6)}


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	return [
		# 1 sağ yatay savurma: kol sağ-arkaya açılır, gövde döner, pençe önden geçip sol omza süpürülür
		{"len": 0.6, "hit": 0.24, "keys": [
			_t(0.0, 0.48, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.13, 0.52, -30, 4, R_WIDE, L_GUARD, BK),
			_t(0.19, 0.55, -12, 12, R_SIDE, L_GUARD, L),
			_t(0.24, 0.57, 10, 18, R_MID, L_GUARD, L),
			_t(0.31, 0.57, 30, 18, R_ACROSS, L_GUARD, L),
			_t(0.4, 0.55, 32, 16, R_ACROSS, L_GUARD, L),
			_t(0.6, 0.48, 0, 10, R_GUARD, L_GUARD, W),
		]},
		# 2 sol ters savurma (ayna)
		{"len": 0.6, "hit": 0.24, "keys": [
			_t(0.0, 0.48, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.13, 0.52, 30, 4, R_GUARD, L_WIDE, BK),
			_t(0.19, 0.55, 12, 12, R_GUARD, L_SIDE, LL),
			_t(0.24, 0.57, -10, 18, R_GUARD, L_MID, LL),
			_t(0.31, 0.57, -30, 18, R_GUARD, L_ACROSS, LL),
			_t(0.4, 0.55, -32, 16, R_GUARD, L_ACROSS, LL),
			_t(0.6, 0.48, 0, 10, R_GUARD, L_GUARD, W),
		]},
		# 3 çift X: iki kol yukarı-dışa açılır, çapraz aşağı savrulup karşı kalçalara iner
		{"len": 0.75, "hit": 0.36, "keys": [
			_t(0.0, 0.48, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.18, 0.46, 0, -10, R_HSIDE, L_HSIDE, BK),
			_t(0.28, 0.46, 0, -12, R_HSIDE, L_HSIDE, BK),
			_t(0.33, 0.55, 0, 14, R_MID, L_MID, L),
			_t(0.38, 0.6, 0, 26, R_RAKE, L_RAKE, L),
			_t(0.5, 0.58, 0, 22, R_RAKE, L_RAKE, L),
			_t(0.75, 0.48, 0, 10, R_GUARD, L_GUARD, W),
		]},
		# 4 çömelip alt-dıştan yukarı çift savurma (kaldırır)
		{"len": 0.75, "hit": 0.38, "keys": [
			_t(0.0, 0.48, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.16, 0.78, 0, 30, R_LOWOUT, L_LOWOUT, W),
			_t(0.3, 0.8, 0, 32, R_LOWOUT, L_LOWOUT, W),
			_t(0.35, 0.5, 0, 6, R_MID, L_MID, ST),
			_t(0.4, 0.22, 0, -14, R_UP, L_UP, ST),
			_t(0.52, 0.2, 0, -16, R_UP, L_UP, L),
			_t(0.75, 0.48, 0, 10, R_GUARD, L_GUARD, W),
		]},
		# 5 sıçrayıp üstten çapraz pençe dalışı
		{"len": 0.9, "hit": 0.48, "jump": 7.0, "keys": [
			_t(0.0, 0.48, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.12, 0.7, 0, 16, R_BACK, L_BACK, W),
			_t(0.3, 0.2, 0, -20, R_HSIDE, L_HSIDE, ST),
			_t(0.42, 0.25, 0, 18, R_MID, L_MID, ST),
			_t(0.5, 0.3, 0, 36, R_RAKE, L_RAKE, ST),
			_t(0.66, 0.6, 0, 24, R_RAKE, L_RAKE, W),
			_t(0.9, 0.48, 0, 10, R_GUARD, L_GUARD, W),
		]},
		# 6 Chakra Sōga: iki kol arkaya, ileri atılıp sağ yatay + sol yatay art arda dev savurma
		{"len": 1.2, "hit": 0.6, "keys": [
			_t(0.0, 0.48, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.2, 0.6, 0, 4, R_WIDE, L_WIDE, BK),
			_t(0.44, 0.62, 0, 2, R_WIDE, L_WIDE, BK),
			_t(0.5, 0.58, -8, 16, R_SIDE, L_WIDE, L),
			_t(0.55, 0.6, 14, 24, R_ACROSS, L_SIDE, L),
			_t(0.6, 0.62, -6, 28, R_ACROSS, L_MID, L),
			_t(0.66, 0.62, -26, 28, R_ACROSS, L_ACROSS, L),
			_t(0.85, 0.6, -20, 24, R_ACROSS, L_ACROSS, L),
			_t(1.2, 0.48, 0, 10, R_GUARD, L_GUARD, W),
		]},
	]
