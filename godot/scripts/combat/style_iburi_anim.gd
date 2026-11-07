extends RefCounted
## Dövüş tarzı — Iburi (Kemuri Kenpō, duman bedeni). ORTA MENZİL. Ref: refs/styles/iburi_*.png
## (0 duman kolonları; 1 kırmızımsı oksitleme dumanı çemberi; 2 dumandan akan şerit yüze dolanır; 4 beden dumana dağılırken
## eller katı kalır; 5 açık mavi-gri kabarık duman). Kanon (Narutopedia "Iburi Clan"): istedikleri an dumana dönüşüp yine de
## fiziksel olarak dokunabilirler; dumanken bedenin içine girip oksitlerler (Ibushimi); rüzgâr dumanı dağıtır (zayıflık).
## 1 Kemuri Ken (sağ): kol dumana çözülüp 4-5 m uzanır, ucunda katı yumruk; 2 aynısı sol;
## 3 Kemuri Utsuri: beden dumana dağılır, rakibin arkasında yeniden katılaşır, ters el darbesi;
## 4 Kemuri Iaigiri: avuçta dumandan bıçak toplanır, yatay kesik; 5 Ibushimi Iki: oksitleyici (kızıl-gri) duman yüze üflenir,
## içeriden yakar ve yavaşlatır; 6 Kemuri Tatsumaki (bitiriş): beden dumana döner, çevrede duman hortumu yükselir, kaldırır.

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const R_GUARD := {"RightUpperArm": Vector3(-0.35, -0.85, 0.35), "RightLowerArm": Vector3(0.1, 0.3, 0.95)}
const L_GUARD := {"LeftUpperArm": Vector3(0.35, -0.85, 0.35), "LeftLowerArm": Vector3(-0.1, 0.3, 0.95)}
const R_BACK := {"RightUpperArm": Vector3(-0.6, -0.3, -0.75), "RightLowerArm": Vector3(-0.2, 0.2, -0.95)}   # kol geriye çekilmiş
const L_BACK := {"LeftUpperArm": Vector3(0.6, -0.3, -0.75), "LeftLowerArm": Vector3(0.2, 0.2, -0.95)}
const R_REACH := {"RightUpperArm": Vector3(-0.08, 0.12, 1), "RightLowerArm": Vector3(0.0, 0.1, 1)}         # kol tam öne uzanmış
const L_REACH := {"LeftUpperArm": Vector3(0.08, 0.12, 1), "LeftLowerArm": Vector3(0.0, 0.1, 1)}
const R_LOW := {"RightUpperArm": Vector3(-0.3, -0.9, 0.2), "RightLowerArm": Vector3(0.2, -0.9, 0.3)}
const L_LOW := {"LeftUpperArm": Vector3(0.3, -0.9, 0.2), "LeftLowerArm": Vector3(-0.2, -0.9, 0.3)}
const R_BACKHAND_IN := {"RightUpperArm": Vector3(0.6, 0.1, 0.78), "RightLowerArm": Vector3(0.95, 0.15, 0.2)}   # göğüs önünden sola sarılmış
const R_BACKHAND_OUT := {"RightUpperArm": Vector3(-0.95, 0.15, 0.25), "RightLowerArm": Vector3(-0.9, 0.2, 0.35)}  # sağa savrulmuş
const R_DRAW := {"RightUpperArm": Vector3(0.35, -0.75, 0.55), "RightLowerArm": Vector3(0.85, -0.2, 0.45)}   # sol kalça önünde (kın çeker gibi)
const L_DRAW := {"LeftUpperArm": Vector3(0.2, -0.85, 0.45), "LeftLowerArm": Vector3(0.3, -0.3, 0.9)}
const R_SLASH := {"RightUpperArm": Vector3(-0.9, 0.05, 0.42), "RightLowerArm": Vector3(-0.85, 0.05, 0.5)}  # sağa yatay açılmış
const R_MOUTH := {"RightUpperArm": Vector3(-0.15, -0.45, 0.88), "RightLowerArm": Vector3(0.4, 0.88, 0.25)}  # el ağız önünde
const L_MOUTH := {"LeftUpperArm": Vector3(0.15, -0.45, 0.88), "LeftLowerArm": Vector3(-0.4, 0.88, 0.25)}
const R_SPREAD := {"RightUpperArm": Vector3(-0.95, 0.25, 0.2), "RightLowerArm": Vector3(-0.85, 0.35, 0.4)}
const L_SPREAD := {"LeftUpperArm": Vector3(0.95, 0.25, 0.2), "LeftLowerArm": Vector3(0.85, 0.35, 0.4)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var BK = F.SHIFT
	var ST = F.STEPIN
	var PV = F.PIVOT
	var PL = F.PIVOT_L
	return [
		{"len": 0.55, "hit": 0.24, "keys": [   # 1 Kemuri Ken (sağ): geriye çek -> kol öne uzanır (duman kol)
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.12, 0.42, -26, -2, R_BACK, L_GUARD, BK),
			_t(0.24, 0.36, 24, 16, R_REACH, L_GUARD, PV),
			_t(0.38, 0.36, 20, 14, R_REACH, L_GUARD, PV),
			_t(0.55, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.55, "hit": 0.24, "keys": [   # 2 Kemuri Ken (sol)
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.12, 0.42, 26, -2, R_GUARD, L_BACK, BK),
			_t(0.24, 0.36, -24, 16, R_GUARD, L_REACH, PL),
			_t(0.38, 0.36, -20, 14, R_GUARD, L_REACH, PL),
			_t(0.55, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.7, "hit": 0.4, "keys": [   # 3 Kemuri Utsuri: çömel (dumana dağılır) -> arkasında belirip ters el
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.14, 0.62, 0, 14, R_LOW, L_LOW, F.LOW),
			_t(0.3, 0.45, 40, 4, R_BACKHAND_IN, L_GUARD, BK),
			_t(0.4, 0.4, -30, 8, R_BACKHAND_OUT, L_GUARD, PV),
			_t(0.52, 0.38, -26, 6, R_BACKHAND_OUT, L_GUARD, PV),
			_t(0.7, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.38, "keys": [   # 4 Kemuri Iaigiri: sol kalçada duman bıçak toplanır -> yatay kesik
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.16, 0.5, 38, 10, R_DRAW, L_DRAW, BK),
			_t(0.3, 0.52, 42, 12, R_DRAW, L_DRAW, BK),
			_t(0.38, 0.44, -48, 14, R_SLASH, L_GUARD, F.STEPIN),
			_t(0.56, 0.42, -52, 12, R_SLASH, L_GUARD, F.STEPIN),
			_t(0.75, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.8, "hit": 0.42, "keys": [   # 5 Ibushimi Iki: eller ağız önüne, öne eğilip duman üflenir
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.16, 0.4, 0, -8, R_MOUTH, L_MOUTH, BK),
			_t(0.32, 0.4, 0, -10, R_MOUTH, L_MOUTH, BK),
			_t(0.42, 0.42, 0, 22, R_MOUTH, L_MOUTH, ST),
			_t(0.62, 0.42, 0, 20, R_MOUTH, L_MOUTH, ST),
			_t(0.8, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 1.1, "hit": 0.55, "keys": [   # 6 Kemuri Tatsumaki: kollar açılır, tam tur döner, hortum yükselir
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.2, 0.55, -30, 6, R_SPREAD, L_SPREAD, F.LOW),
			_t(0.4, 0.4, 150, 2, R_SPREAD, L_SPREAD, PV),
			_t(0.55, 0.38, 330, 2, R_SPREAD, L_SPREAD, PV),
			_t(0.8, 0.36, 360, 4, R_SPREAD, L_SPREAD, W),
			_t(1.1, 0.35, 360, 4, R_GUARD, L_GUARD, W),
		]},
	]
