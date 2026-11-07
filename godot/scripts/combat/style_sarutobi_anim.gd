extends RefCounted
## Dövüş tarzı — Sarutobi (Hiruzen, Asuma, Konohamaru). YAKIN + ORTA (ateş/kül/shuriken). Ref: refs/styles/sarutobi_*.png
## (0 Haisekishō: ağızdan gri kabarık kül bulutu; 1 kül tutuşur: sarı-turuncu dev patlama; 2 Shuriken Kage Bunshin:
## havada çoğalan shuriken sürüsü; 3 Karyū Endan: kıvrılan ateş ejderi selleri). Kanon: Asuma rüzgâr chakrasını silahına/eline
## akıtır (Hien), kül bulutunu dişlerini çakarak tutuşturur; Hiruzen tek shuriken'i yüzlerce kopyaya böler.
## 1 Hien yumruk (sağ): rüzgâr chakralı yumruk, ileri kısa kesik, 2 aynısı sol, 3 Haisekishō: öne kül bulutu üfler (göz alır,
## yavaşlatır), 4 Kōsei: diş çakılır — kül bulutu patlar (yakar), 5 Shuriken Kage Bunshin: tek shuriken atılır, havada
## yelpaze gibi çoğalır, 6 Karyū Endan (bitiriş): mühür + ağızdan kıvrılan ateş seli.

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const R_GUARD := {"RightUpperArm": Vector3(-0.35, -0.85, 0.35), "RightLowerArm": Vector3(0.1, 0.3, 0.95)}
const L_GUARD := {"LeftUpperArm": Vector3(0.35, -0.85, 0.35), "LeftLowerArm": Vector3(-0.1, 0.3, 0.95)}
const R_COCK := {"RightUpperArm": Vector3(-0.55, -0.4, -0.73), "RightLowerArm": Vector3(-0.1, 0.5, 0.86)}
const R_PUNCH := {"RightUpperArm": Vector3(-0.1, 0.0, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}
const L_COCK := {"LeftUpperArm": Vector3(0.55, -0.4, -0.73), "LeftLowerArm": Vector3(0.1, 0.5, 0.86)}
const L_PUNCH := {"LeftUpperArm": Vector3(0.1, 0.0, 1), "LeftLowerArm": Vector3(0.0, 0.05, 1)}
const R_MOUTH := {"RightUpperArm": Vector3(-0.15, -0.45, 0.88), "RightLowerArm": Vector3(0.4, 0.88, 0.25)}   # el ağız önünde (üfler)
const L_HIP := {"LeftUpperArm": Vector3(0.2, -0.95, 0.15), "LeftLowerArm": Vector3(0.1, -0.6, 0.8)}
const R_CLICK := {"RightUpperArm": Vector3(-0.2, -0.6, 0.78), "RightLowerArm": Vector3(0.3, 0.75, 0.6)}      # çene önünde yumruk (diş çakar)
const R_THROW_BACK := {"RightUpperArm": Vector3(-0.6, 0.55, -0.55), "RightLowerArm": Vector3(-0.2, 0.8, 0.5)}
const R_THROW := {"RightUpperArm": Vector3(-0.1, 0.15, 0.98), "RightLowerArm": Vector3(0.05, 0.05, 1)}
const R_SEAL := {"RightUpperArm": Vector3(-0.25, -0.7, 0.67), "RightLowerArm": Vector3(0.75, 0.3, 0.6)}      # tora mührü: göğüs önünde
const L_SEAL := {"LeftUpperArm": Vector3(0.25, -0.7, 0.67), "LeftLowerArm": Vector3(-0.75, 0.3, 0.6)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var BK = F.SHIFT
	var ST = F.STEPIN
	var PV = F.PIVOT
	var PL = F.PIVOT_L
	return [
		{"len": 0.45, "hit": 0.2, "keys": [   # 1 Hien yumruk (sağ)
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.1, 0.42, -24, -2, R_COCK, L_GUARD, BK),
			_t(0.2, 0.38, 22, 16, R_PUNCH, L_GUARD, PV),
			_t(0.3, 0.37, 18, 14, R_PUNCH, L_GUARD, PV),
			_t(0.45, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.45, "hit": 0.2, "keys": [   # 2 Hien yumruk (sol)
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.1, 0.42, 24, -2, R_GUARD, L_COCK, BK),
			_t(0.2, 0.38, -22, 16, R_GUARD, L_PUNCH, PL),
			_t(0.3, 0.37, -18, 14, R_GUARD, L_PUNCH, PL),
			_t(0.45, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.36, "keys": [   # 3 Haisekishō: derin nefes (geriye eğil) -> öne eğilip kül üfler
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.16, 0.36, 0, -16, R_MOUTH, L_HIP, BK),
			_t(0.3, 0.36, 0, -18, R_MOUTH, L_HIP, BK),
			_t(0.38, 0.4, 0, 18, R_MOUTH, L_HIP, ST),
			_t(0.6, 0.4, 0, 16, R_MOUTH, L_HIP, ST),
			_t(0.75, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.55, "hit": 0.26, "keys": [   # 4 diş çakılır: yumruk çene önünde, kül patlar
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.12, 0.38, -6, 2, R_CLICK, L_GUARD, W),
			_t(0.26, 0.4, -4, -6, R_CLICK, L_GUARD, BK),
			_t(0.4, 0.38, 0, -4, R_CLICK, L_GUARD, BK),
			_t(0.55, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.6, "hit": 0.28, "keys": [   # 5 Shuriken Kage Bunshin: omuz üstünden fırlatış
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.14, 0.42, -28, -8, R_THROW_BACK, L_GUARD, BK),
			_t(0.28, 0.38, 24, 14, R_THROW, L_GUARD, PV),
			_t(0.42, 0.37, 20, 12, R_THROW, L_GUARD, PV),
			_t(0.6, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 1.15, "hit": 0.56, "keys": [   # 6 Karyū Endan: tora mührü (uzun) -> öne eğilip ateş seli
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.2, 0.4, 0, -6, R_SEAL, L_SEAL, W),
			_t(0.46, 0.4, 0, -10, R_SEAL, L_SEAL, BK),
			_t(0.56, 0.42, 0, 20, R_MOUTH, L_HIP, ST),
			_t(0.95, 0.42, 0, 18, R_MOUTH, L_HIP, ST),
			_t(1.15, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
	]
