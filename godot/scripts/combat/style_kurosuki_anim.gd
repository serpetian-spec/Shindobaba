extends RefCounted
## Dövüş tarzı — Kurosuki (Raikō, Raiga'nın ailesi). YAKIN + GÖK ŞİMŞEĞİ. Ref: refs/styles/kurosuki_*.png
## (0 Raiga doğal şimşeği bedenine çeker: göğe uzanan beyaz-mavi şimşek sütunu; 1 Kara Kasırga: düz, çapraz beyaz ışık
## çizgileri). Kanon (Narutopedia "Raiga Kurosuki"): Kiba olmadan da Raiton kullanır, kımıldamadan doğal şimşek indirir,
## sis (Kirigakure) içinde saklanıp saldırır; şimşekle toprak yığıp "gömer".
## 1 Raiton Tegatana (sağ el kılıcı, ağız boyunca şimşek), 2 aynısı sol, 3 Kirigakure: sise karışıp rakibin yanında belirir,
## şimşekli diz/el darbesi (sersemletir), 4 Kuroi Jūji: iki el çaprazlanıp açılır — çapraz düz şimşek çizgileri,
## 5 Rakurai: sağ el göğe kalkar, hedefe gök şimşeği iner, 6 Ikazuchi no Utage (bitiriş): iki el göğe, hedefin çevresine
## şimşek yağmuru, sonunda büyük şimşek.

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const R_GUARD := {"RightUpperArm": Vector3(-0.35, -0.85, 0.35), "RightLowerArm": Vector3(0.1, 0.3, 0.95)}
const L_GUARD := {"LeftUpperArm": Vector3(0.35, -0.85, 0.35), "LeftLowerArm": Vector3(-0.1, 0.3, 0.95)}
const R_CHOP_UP := {"RightUpperArm": Vector3(-0.55, 0.65, -0.5), "RightLowerArm": Vector3(-0.2, 0.9, 0.35)}    # el kılıcı omuz üstünde
const L_CHOP_UP := {"LeftUpperArm": Vector3(0.55, 0.65, -0.5), "LeftLowerArm": Vector3(0.2, 0.9, 0.35)}
const R_CHOP_DOWN := {"RightUpperArm": Vector3(0.15, -0.35, 0.92), "RightLowerArm": Vector3(0.35, -0.5, 0.8)}  # çaprazlama aşağı inmiş
const L_CHOP_DOWN := {"LeftUpperArm": Vector3(-0.15, -0.35, 0.92), "LeftLowerArm": Vector3(-0.35, -0.5, 0.8)}
const R_LOW := {"RightUpperArm": Vector3(-0.3, -0.9, 0.2), "RightLowerArm": Vector3(0.2, -0.9, 0.3)}
const L_LOW := {"LeftUpperArm": Vector3(0.3, -0.9, 0.2), "LeftLowerArm": Vector3(-0.2, -0.9, 0.3)}
const R_JAB := {"RightUpperArm": Vector3(-0.1, -0.05, 1), "RightLowerArm": Vector3(0.0, 0.0, 1)}
const R_CROSS := {"RightUpperArm": Vector3(0.25, 0.2, 0.94), "RightLowerArm": Vector3(0.8, 0.45, 0.4)}     # kollar göğüste X
const L_CROSS := {"LeftUpperArm": Vector3(-0.25, 0.2, 0.94), "LeftLowerArm": Vector3(-0.8, 0.45, 0.4)}
const R_OPEN := {"RightUpperArm": Vector3(-0.9, -0.15, 0.4), "RightLowerArm": Vector3(-0.85, -0.25, 0.45)}  # X açılıp yanlara savrulur
const L_OPEN := {"LeftUpperArm": Vector3(0.9, -0.15, 0.4), "LeftLowerArm": Vector3(0.85, -0.25, 0.45)}
const R_SKY := {"RightUpperArm": Vector3(-0.15, 0.98, 0.1), "RightLowerArm": Vector3(-0.05, 1.0, 0.05)}     # el göğe
const L_SKY := {"LeftUpperArm": Vector3(0.15, 0.98, 0.1), "LeftLowerArm": Vector3(0.05, 1.0, 0.05)}
const R_POINT := {"RightUpperArm": Vector3(-0.1, 0.2, 0.98), "RightLowerArm": Vector3(0.0, 0.1, 1)}         # hedefi işaret eder


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var BK = F.SHIFT
	var ST = F.STEPIN
	var PV = F.PIVOT
	var PL = F.PIVOT_L
	return [
		{"len": 0.5, "hit": 0.22, "keys": [   # 1 Raiton Tegatana (sağ)
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.12, 0.42, -24, -6, R_CHOP_UP, L_GUARD, BK),
			_t(0.22, 0.42, 26, 18, R_CHOP_DOWN, L_GUARD, PV),
			_t(0.34, 0.4, 22, 14, R_CHOP_DOWN, L_GUARD, PV),
			_t(0.5, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.5, "hit": 0.22, "keys": [   # 2 Raiton Tegatana (sol)
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.12, 0.42, 24, -6, R_GUARD, L_CHOP_UP, BK),
			_t(0.22, 0.42, -26, 18, R_GUARD, L_CHOP_DOWN, PL),
			_t(0.34, 0.4, -22, 14, R_GUARD, L_CHOP_DOWN, PL),
			_t(0.5, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.42, "keys": [   # 3 Kirigakure: sise karışır (çömel) -> yanında belirip şimşekli dürtüş
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.16, 0.6, 0, 12, R_LOW, L_LOW, F.LOW),
			_t(0.32, 0.5, -20, 6, R_GUARD, L_GUARD, BK),
			_t(0.42, 0.42, 20, 20, R_JAB, L_GUARD, ST),
			_t(0.56, 0.4, 16, 16, R_JAB, L_GUARD, ST),
			_t(0.75, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.38, "keys": [   # 4 Kuroi Jūji: kollar göğüste X -> yanlara açılır
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.18, 0.46, 0, -6, R_CROSS, L_CROSS, BK),
			_t(0.3, 0.48, 0, -8, R_CROSS, L_CROSS, BK),
			_t(0.38, 0.42, 0, 14, R_OPEN, L_OPEN, ST),
			_t(0.56, 0.4, 0, 12, R_OPEN, L_OPEN, ST),
			_t(0.75, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.85, "hit": 0.46, "keys": [   # 5 Rakurai: sağ el göğe (şimşeği çağırır) -> hedefe işaret
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.2, 0.3, -10, -14, R_SKY, L_GUARD, W),
			_t(0.38, 0.3, -10, -16, R_SKY, L_GUARD, W),
			_t(0.46, 0.38, 8, 12, R_POINT, L_GUARD, ST),
			_t(0.66, 0.38, 6, 10, R_POINT, L_GUARD, ST),
			_t(0.85, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 1.2, "hit": 0.6, "keys": [   # 6 Ikazuchi no Utage: iki el göğe, uzun bekleme -> kollar iner, şimşek yağar
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.24, 0.28, 0, -18, R_SKY, L_SKY, W),
			_t(0.52, 0.28, 0, -20, R_SKY, L_SKY, W),
			_t(0.62, 0.5, 0, 16, R_OPEN, L_OPEN, F.LOW),
			_t(0.95, 0.48, 0, 14, R_OPEN, L_OPEN, F.LOW),
			_t(1.2, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
	]
