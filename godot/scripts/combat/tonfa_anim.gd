extends RefCounted
## Tonfa kombosu — İKİ EL: tonfalar ön kol boyunca (kalkan gibi), yan kabza yumrukta. Dövüş: blok-karşı vuruş ritmi —
## ön kollar yüz önünde kapanır (tonfa gövdeleri darbeyi karşılar) -> açılıp yumruk ucu / dirsek ucu / geniş kanca savuruşları.
## Her vuruş: belirgin geri çekiş (omuz-kalça ters burulur) -> adımla hızlı darbe -> takip -> toparlanma (asuma_anim ayak işi).
## 1 blok + düz yumruk ucu, 2 çift kanca, 3 dirsek ucu + geri kol, 4 dönerek geri kol savuruşu, 5 alttan çift kaldırma,
## 6 Sōtsui (bitiriş): iki tonfa baş üstünde çapraz -> aynı anda aşağı ezici çift darbe.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_GUARD := {"RightUpperArm": Vector3(-0.3, -0.55, 0.75), "RightLowerArm": Vector3(0.45, 0.8, 0.4)}       # ön kol dik, yüz önünde
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.55, 0.75), "LeftLowerArm": Vector3(-0.45, 0.8, 0.4)}
const R_COCK := {"RightUpperArm": Vector3(-0.65, -0.5, -0.57), "RightLowerArm": Vector3(-0.15, 0.45, 0.88)}
const L_COCK := {"LeftUpperArm": Vector3(0.65, -0.5, -0.57), "LeftLowerArm": Vector3(0.15, 0.45, 0.88)}
const R_JAB := {"RightUpperArm": Vector3(-0.06, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}
const L_JAB := {"LeftUpperArm": Vector3(0.06, 0.05, 1), "LeftLowerArm": Vector3(0.0, 0.05, 1)}
const R_HOOK := {"RightUpperArm": Vector3(-0.9, 0.05, 0.4), "RightLowerArm": Vector3(0.75, 0.1, 0.65)}
const R_HOOK_END := {"RightUpperArm": Vector3(0.2, 0.05, 0.95), "RightLowerArm": Vector3(0.95, 0.05, 0.2)}
const L_HOOK := {"LeftUpperArm": Vector3(0.9, 0.05, 0.4), "LeftLowerArm": Vector3(-0.75, 0.1, 0.65)}
const L_HOOK_END := {"LeftUpperArm": Vector3(-0.2, 0.05, 0.95), "LeftLowerArm": Vector3(-0.95, 0.05, 0.2)}
const R_ELBOW := {"RightUpperArm": Vector3(-0.4, 0.2, 0.9), "RightLowerArm": Vector3(0.9, 0.2, -0.3)}         # dirsek öne: tonfa ucu dirsekten çıkar
const R_BACKFIST := {"RightUpperArm": Vector3(-0.95, 0.15, -0.1), "RightLowerArm": Vector3(-0.9, 0.3, -0.25)}  # geri kol: dönüşte arkaya açılmış
const R_LOW := {"RightUpperArm": Vector3(-0.35, -0.9, 0.2), "RightLowerArm": Vector3(-0.1, -0.6, 0.8)}
const L_LOW := {"LeftUpperArm": Vector3(0.35, -0.9, 0.2), "LeftLowerArm": Vector3(0.1, -0.6, 0.8)}
const R_UPPER := {"RightUpperArm": Vector3(-0.2, -0.2, 0.95), "RightLowerArm": Vector3(0.05, 0.9, 0.4)}
const L_UPPER := {"LeftUpperArm": Vector3(0.2, -0.2, 0.95), "LeftLowerArm": Vector3(-0.05, 0.9, 0.4)}
const R_CROSS_UP := {"RightUpperArm": Vector3(-0.15, 0.95, 0.2), "RightLowerArm": Vector3(0.6, 0.75, 0.1)}     # baş üstünde çapraz
const L_CROSS_UP := {"LeftUpperArm": Vector3(0.15, 0.95, 0.2), "LeftLowerArm": Vector3(-0.6, 0.75, 0.1)}
const R_SMASH := {"RightUpperArm": Vector3(-0.15, -0.3, 0.94), "RightLowerArm": Vector3(0.0, -0.7, 0.7)}
const L_SMASH := {"LeftUpperArm": Vector3(0.15, -0.3, 0.94), "LeftLowerArm": Vector3(0.0, -0.7, 0.7)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var BKL = S.mirror(S.LEG_BACK)
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	return [
		# 1 Uke Tsuki: iki ön kol yüz önünde kapanır (blok) -> sağ geri çekilir -> sağ ayakla öne kayarak düz yumruk ucu darbesi
		{"len": 0.62, "hit": 0.3, "keys": [
			_t(0.0, 0.4, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.1, 0.46, 0, 8, R_GUARD, L_GUARD, W),
			_t(0.2, 0.44, -26, -6, R_COCK, L_GUARD, BK),
			_t(0.3, 0.5, 16, 18, R_JAB, L_GUARD, L),
			_t(0.4, 0.48, 14, 16, R_JAB, L_GUARD, L),
			_t(0.62, 0.4, 0, 4, R_GUARD, L_GUARD, W),
		]},
		# 2 Sōkō: sol kanca -> hemen sağ kanca (kalça iki yöne burulur), tonfa gövdeleri yay çizer
		{"len": 0.72, "hit": 0.26, "extra_hits": [0.48], "extra_radius": 1.5, "keys": [
			_t(0.0, 0.4, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.12, 0.45, 30, -6, R_GUARD, L_COCK, BKL),
			_t(0.26, 0.5, -24, 14, R_GUARD, L_HOOK_END, LL),
			_t(0.36, 0.46, -36, -4, R_COCK, L_GUARD, BK),
			_t(0.48, 0.5, 34, 16, R_HOOK_END, L_GUARD, L),
			_t(0.72, 0.4, 0, 4, R_GUARD, L_GUARD, W),
		]},
		# 3 Hiji Ate: dönen kalçayla sağ dirsek öne (tonfa ucu dirsekten çıkıp göğse saplanır) -> geri kol
		{"len": 0.8, "hit": 0.32, "extra_hits": [0.56], "extra_radius": 1.6, "keys": [
			_t(0.0, 0.4, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.16, 0.46, -28, -6, R_COCK, L_GUARD, BK),
			_t(0.32, 0.52, 22, 20, R_ELBOW, L_GUARD, L),
			_t(0.44, 0.48, 30, 14, R_ELBOW, L_JAB, L),
			_t(0.56, 0.48, -10, 10, R_HOOK, L_GUARD, ST),
			_t(0.8, 0.4, 0, 4, R_GUARD, L_GUARD, W),
		]},
		# 4 Kaiten Ura: tam dönüş (sırt rakibe), dönüşün sonunda geniş geri kol savuruşu — tonfa gövdesi şakağa iner
		{"len": 0.9, "hit": 0.5, "keys": [
			_t(0.0, 0.4, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.16, 0.44, 40, 4, R_GUARD, L_GUARD, CR),
			_t(0.32, 0.46, 110, 6, R_BACKFIST, L_GUARD, W),
			_t(0.5, 0.5, 170, 10, R_BACKFIST, L_GUARD, ST),
			_t(0.66, 0.46, 30, 8, R_HOOK_END, L_GUARD, W),
			_t(0.9, 0.4, 0, 4, R_GUARD, L_GUARD, W),
		]},
		# 5 Nidan Age: eğilip iki tonfa alçakta -> yaylanıp çift aparkat (havaya kaldırır)
		{"len": 0.8, "hit": 0.42, "keys": [
			_t(0.0, 0.4, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.16, 0.74, 10, 26, R_LOW, L_LOW, W),
			_t(0.32, 0.78, -6, 28, R_LOW, L_LOW, W),
			_t(0.42, 0.22, 0, -14, R_UPPER, L_UPPER, ST),
			_t(0.54, 0.2, 0, -16, R_UPPER, L_UPPER, L),
			_t(0.8, 0.4, 0, 4, R_GUARD, L_GUARD, W),
		]},
		# 6 Sōtsui (bitiriş): iki tonfa baş üstünde çapraz (gövde geriye kavislenir, bekle) -> sıçrayışla aynı anda aşağı ezici çift darbe
		{"len": 1.1, "hit": 0.6, "keys": [
			_t(0.0, 0.4, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.2, 0.36, 0, -20, R_CROSS_UP, L_CROSS_UP, BK),
			_t(0.46, 0.34, 0, -24, R_CROSS_UP, L_CROSS_UP, BK),
			_t(0.6, 0.64, 0, 34, R_SMASH, L_SMASH, L),
			_t(0.82, 0.66, 0, 30, R_SMASH, L_SMASH, L),
			_t(1.1, 0.4, 0, 4, R_GUARD, L_GUARD, W),
		]},
	]
