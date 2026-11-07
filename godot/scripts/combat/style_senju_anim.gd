extends RefCounted
## Dövüş tarzı — Senju (Senju-ryū: Mokuton dalları + Senju kanının canavar gücü, Tsunade). YAKIN-ORTA. Ref: refs/styles/senju_*.png
## (0 Ōkashō: zemin dev sivri kaya parçaları hâlinde kalkar; 1 Tsūtenkyaku: yuvarlak krater, çatlaklar, moloz patlaması;
## 2-3 Mokuton Kesme Tekniği: koldan dallar fışkırıp rakibe saplanır). Kanon: Senju kanı muazzam yaşam gücü ve chakra
## (Hashirama, Tsunade); Tsunade'nin topuk inişi ve yere yumruğu yeri parçalar.
## 1 sağ düz yumruk, 2 sol kroşe, 3 Mokuton Kesme: sağ kol öne, koldan dallar fışkırıp saplanır (orta menzil),
## 4 Jukai Kōtan dalı: avuç yere, hedefin altından tahta sütunlar fışkırıp havaya kaldırır,
## 5 Ōkashō: diz çöküp yumruk yere, önündeki zemin sivri kayalarla kalkar, 6 Tsūtenkyaku (bitiriş): sıçrar, topuk iner, krater.

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const R_GUARD := {"RightUpperArm": Vector3(-0.35, -0.85, 0.35), "RightLowerArm": Vector3(0.1, 0.3, 0.95)}
const L_GUARD := {"LeftUpperArm": Vector3(0.35, -0.85, 0.35), "LeftLowerArm": Vector3(-0.1, 0.3, 0.95)}
const R_COCK := {"RightUpperArm": Vector3(-0.55, -0.4, -0.73), "RightLowerArm": Vector3(-0.1, 0.5, 0.86)}
const R_PUNCH := {"RightUpperArm": Vector3(-0.1, 0.0, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}
const L_COCK := {"LeftUpperArm": Vector3(0.75, -0.3, -0.58), "LeftLowerArm": Vector3(0.2, 0.6, 0.77)}
const L_HOOK := {"LeftUpperArm": Vector3(0.45, 0.15, 0.88), "LeftLowerArm": Vector3(-0.85, 0.1, 0.5)}
const R_REACH := {"RightUpperArm": Vector3(-0.08, 0.15, 1), "RightLowerArm": Vector3(0.0, 0.1, 1)}
const L_BRACE := {"LeftUpperArm": Vector3(0.1, -0.4, 0.9), "LeftLowerArm": Vector3(-0.6, 0.3, 0.74)}   # sol el sağ bileği tutar
const R_GROUND := {"RightUpperArm": Vector3(-0.1, -0.75, 0.65), "RightLowerArm": Vector3(0.0, -0.95, 0.3)}   # avuç yere
const L_GROUND := {"LeftUpperArm": Vector3(0.1, -0.75, 0.65), "LeftLowerArm": Vector3(0.0, -0.95, 0.3)}
const R_HIGH := {"RightUpperArm": Vector3(-0.3, 0.95, -0.1), "RightLowerArm": Vector3(-0.1, 0.9, -0.4)}
const L_HIGH := {"LeftUpperArm": Vector3(0.3, 0.95, -0.1), "LeftLowerArm": Vector3(0.1, 0.9, -0.4)}
const R_SMASH := {"RightUpperArm": Vector3(-0.1, -0.6, 0.8), "RightLowerArm": Vector3(0.0, -0.98, 0.15)}   # yumruk yere iner


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var BK = F.SHIFT
	var ST = F.STEPIN
	var PV = F.PIVOT
	var PL = F.PIVOT_L
	return [
		{"len": 0.45, "hit": 0.2, "keys": [   # 1 sağ düz yumruk
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.1, 0.42, -24, -2, R_COCK, L_GUARD, BK),
			_t(0.2, 0.38, 22, 16, R_PUNCH, L_GUARD, PV),
			_t(0.3, 0.37, 18, 14, R_PUNCH, L_GUARD, PV),
			_t(0.45, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.5, "hit": 0.22, "keys": [   # 2 sol kroşe
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.1, 0.42, 30, -2, R_GUARD, L_COCK, BK),
			_t(0.22, 0.4, -34, 14, R_GUARD, L_HOOK, PL),
			_t(0.34, 0.38, -30, 12, R_GUARD, L_HOOK, PL),
			_t(0.5, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.7, "hit": 0.34, "keys": [   # 3 Mokuton Kesme: kol öne uzanır, sol el bileği tutar, dallar fışkırır
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.16, 0.42, -14, 4, R_COCK, L_GUARD, BK),
			_t(0.3, 0.42, 6, 14, R_REACH, L_BRACE, ST),
			_t(0.5, 0.42, 6, 14, R_REACH, L_BRACE, ST),
			_t(0.7, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.38, "keys": [   # 4 avuçlar yere: tahta sütunlar fışkırır
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.18, 0.55, 0, 22, R_GROUND, L_GROUND, F.LOW),
			_t(0.38, 0.62, 0, 28, R_GROUND, L_GROUND, F.LOW),
			_t(0.56, 0.58, 0, 24, R_GROUND, L_GROUND, F.LOW),
			_t(0.75, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.85, "hit": 0.45, "keys": [   # 5 Ōkashō: yumruk yukarı kalkar -> diz çöküp yere çakar
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.2, 0.36, -10, -14, R_HIGH, L_GUARD, BK),
			_t(0.36, 0.38, -12, -16, R_HIGH, L_GUARD, BK),
			_t(0.45, 0.72, 6, 34, R_SMASH, L_GUARD, F.LOW),
			_t(0.66, 0.7, 4, 30, R_SMASH, L_GUARD, F.LOW),
			_t(0.85, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 1.15, "hit": 0.66, "keys": [   # 6 Tsūtenkyaku: sıçrayıp kollar yukarı -> topuk iner, krater
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.22, 0.28, 0, -14, R_HIGH, L_HIGH, F.HOP),
			_t(0.5, 0.26, 0, -18, R_HIGH, L_HIGH, F.HOP),
			_t(0.66, 0.6, 0, 22, R_GUARD, L_GUARD, F.LOW),
			_t(0.9, 0.55, 0, 18, R_GUARD, L_GUARD, F.LOW),
			_t(1.15, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
	]
