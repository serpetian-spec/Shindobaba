extends RefCounted
## Hakkō Chakura Tō — Hatake'nin beyaz ışık tantōsu (Sakumo "Konoha no Shiroi Kiba", Kakashi ANBU). Ref: refs/weapons/hakko_*.png.
## Kanon (Narutopedia): savrulunca arkasında beyaz chakra çizgisi bırakır — her kesik beyaz ışık yayı. Düz tantō kombosundan farkı:
## suikast (boğaz/baldır) değil, göz açıp kapayana kadar mesafeyi kapatan, rakibin İÇİNDEN geçen beyaz kesikler.
## 1 Hakkō Ichimonji: soldan sağa çok hızlı yatay kesik, 2 Kaeshi: sırt elle çapraz yükselen kesik,
## 3 Shiroi Kiba: şunşin atılışıyla rakibin içinden geçip arkasında belirir (beyaz çizgi), 4 Furimuki: arkasından dönüp
## yukarıdan aşağı dikey kesik (yere indirir), 5 Hakkō Senpū: tam tur dönen kesik (beyaz halka),
## 6 Hakkō Zan (bitiriş): ağız beyaz chakra ile dolar -> bekle -> ileri uzanan beyaz ışık hilali (orta menzil).

const S = preload("res://scripts/combat/samehada_anim.gd")
const T = preload("res://scripts/combat/tanto_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const R_HIGH := {"RightUpperArm": Vector3(-0.3, 0.85, 0.42), "RightLowerArm": Vector3(-0.1, 0.9, 0.42)}       # baş üstünde
const R_DOWN := {"RightUpperArm": Vector3(-0.15, -0.55, 0.82), "RightLowerArm": Vector3(-0.05, -0.75, 0.66)}  # dikey kesik sonu
const R_BACKHAND := {"RightUpperArm": Vector3(0.3, -0.6, 0.75), "RightLowerArm": Vector3(0.85, -0.3, 0.42)}   # sol kalça önünde (sırt eli)
const R_RISE := {"RightUpperArm": Vector3(-0.7, 0.55, 0.45), "RightLowerArm": Vector3(-0.55, 0.7, 0.45)}      # sağ üstte bitiş
const R_EXT := {"RightUpperArm": Vector3(-0.2, 0.05, 0.98), "RightLowerArm": Vector3(-0.1, 0.05, 1)}          # ileri uzanmış kesik sonu
const L_OPEN := {"LeftUpperArm": Vector3(0.85, -0.3, 0.42), "LeftLowerArm": Vector3(0.75, -0.2, 0.62)}        # denge için açık sol kol


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var ST = F.STEPIN
	var BK = F.SHIFT
	var PV = F.PIVOT
	var LO = F.LOW
	var RDY = Vector3(0, 0.1, 1)
	return [
		{"len": 0.4, "hit": 0.14, "keys": [   # 1 Hakkō Ichimonji
			_t(0.0, 0.42, 0, 8, RDY, T.R_READY, T.L_GUARD, W),
			_t(0.07, 0.48, 34, 2, Vector3(0.9, 0.1, 0.4), T.R_LEFT, T.L_GUARD, BK),
			_t(0.14, 0.52, -30, 16, Vector3(-0.9, 0.05, 0.4), T.R_WIDE, L_OPEN, PV),
			_t(0.24, 0.5, -34, 14, Vector3(-0.95, 0.0, 0.3), T.R_WIDE, L_OPEN, PV),
			_t(0.4, 0.42, 0, 8, RDY, T.R_READY, T.L_GUARD, W),
		]},
		{"len": 0.45, "hit": 0.18, "keys": [   # 2 Kaeshi (sırt elle yükselen çapraz)
			_t(0.0, 0.42, -20, 8, RDY, T.R_WIDE, T.L_GUARD, W),
			_t(0.08, 0.6, 20, 18, Vector3(0.6, -0.6, 0.5), R_BACKHAND, T.L_GUARD, BK),
			_t(0.18, 0.4, -24, -6, Vector3(-0.5, 0.75, 0.4), R_RISE, L_OPEN, ST),
			_t(0.28, 0.38, -28, -8, Vector3(-0.5, 0.8, 0.3), R_RISE, L_OPEN, ST),
			_t(0.45, 0.42, 0, 8, RDY, T.R_READY, T.L_GUARD, W),
		]},
		{"len": 0.55, "hit": 0.2, "keys": [   # 3 Shiroi Kiba: alçak atılış, rakibin içinden geçen kesik
			_t(0.0, 0.42, 0, 8, RDY, T.R_READY, T.L_GUARD, W),
			_t(0.1, 0.7, 24, 30, Vector3(0.7, 0.0, 0.7), T.R_LEFT, T.L_BACK, LO),
			_t(0.2, 0.66, -30, 34, Vector3(-0.9, 0.0, 0.4), T.R_WIDE, T.L_BACK, ST),
			_t(0.34, 0.6, -36, 30, Vector3(-0.95, 0.0, 0.3), T.R_WIDE, T.L_BACK, ST),
			_t(0.55, 0.42, 0, 8, RDY, T.R_READY, T.L_GUARD, W),
		]},
		{"len": 0.6, "hit": 0.3, "keys": [   # 4 Furimuki: dönüp yukarıdan dikey kesik
			_t(0.0, 0.42, 180, 8, RDY, T.R_READY, T.L_GUARD, W),
			_t(0.14, 0.36, 40, -10, Vector3(0, 0.9, -0.3), R_HIGH, L_OPEN, BK),
			_t(0.3, 0.6, 0, 30, Vector3(0, -0.8, 0.6), R_DOWN, T.L_BACK, ST),
			_t(0.42, 0.62, 0, 30, Vector3(0, -0.85, 0.5), R_DOWN, T.L_BACK, ST),
			_t(0.6, 0.42, 0, 8, RDY, T.R_READY, T.L_GUARD, W),
		]},
		{"len": 0.65, "hit": 0.36, "keys": [   # 5 Hakkō Senpū: tam tur kesik
			_t(0.0, 0.42, 0, 8, RDY, T.R_READY, T.L_GUARD, W),
			_t(0.12, 0.5, 60, 10, Vector3(0.9, 0.0, 0.3), T.R_LEFT, L_OPEN, BK),
			_t(0.26, 0.52, 200, 14, Vector3(-0.95, 0.0, 0.3), T.R_WIDE, L_OPEN, PV),
			_t(0.36, 0.52, 330, 16, Vector3(-0.95, 0.0, 0.3), T.R_WIDE, L_OPEN, PV),
			_t(0.46, 0.5, 360, 12, Vector3(-0.9, 0.0, 0.4), T.R_WIDE, L_OPEN, W),
			_t(0.65, 0.42, 360, 8, RDY, T.R_READY, T.L_GUARD, W),
		]},
		{"len": 1.1, "hit": 0.66, "keys": [   # 6 Hakkō Zan: chakra dolar, ileri uzanan beyaz hilal
			_t(0.0, 0.42, 0, 8, RDY, T.R_READY, T.L_GUARD, W),
			_t(0.2, 0.55, 30, 4, Vector3(0.8, 0.3, 0.5), T.R_LEFT, T.L_OVER, BK),   # sol el ağzın üstünden geçer
			_t(0.56, 0.58, 34, 2, Vector3(0.8, 0.3, 0.5), T.R_LEFT, T.L_OVER, BK),
			_t(0.66, 0.6, -24, 28, Vector3(-0.6, 0.0, 0.8), R_EXT, L_OPEN, ST),
			_t(0.86, 0.58, -30, 26, Vector3(-0.8, 0.0, 0.6), T.R_WIDE, L_OPEN, ST),
			_t(1.1, 0.42, 0, 8, RDY, T.R_READY, T.L_GUARD, W),
		]},
	]
