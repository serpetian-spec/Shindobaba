extends RefCounted
## Dövüş tarzı — Hatake (Sakumo, Kakashi; silahsız). YAKIN + RAITON. Ref: refs/styles/hatake_*.png
## (0 Raikiri: avuçta beyaz-mavi şimşek topu, çevreye kırbaç gibi şimşek dalları; 1 Raijū Tsuiga: elden fırlayan, kırmızı gözlü
## şimşek tazısı; 2 Doton Tsuiga: yerden fırlayan ninkenler hedefi ısırıp tutar). Kanon: Kakashi taijutsuda tekme ağırlıklı,
## Shunshin ile arkaya geçer; Raikiri hamlesi düz çizgide hedefe dalar (Sharingan'sız tünel görüşü — burada hızlı dalış).
## 1 alçak süpürme tekmesi, 2 yüksek döner tekme, 3 Shunshin: rakibin arkasında belirip dirsek, 4 Raijū Tsuiga: şimşek tazısı
## hedefe koşar, 5 Doton Tsuiga: yerden ninkenler fırlayıp tutar (bağlar), 6 Raikiri (bitiriş): avuçta şimşek toplanır
## (uzun bekleme, alçak duruş) -> hedefe dalıp sapla.

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const R_GUARD := {"RightUpperArm": Vector3(-0.35, -0.85, 0.35), "RightLowerArm": Vector3(0.1, 0.3, 0.95)}
const L_GUARD := {"LeftUpperArm": Vector3(0.35, -0.85, 0.35), "LeftLowerArm": Vector3(-0.1, 0.3, 0.95)}
const R_LOWB := {"RightUpperArm": Vector3(-0.4, -0.9, -0.1), "RightLowerArm": Vector3(-0.2, -0.95, 0.2)}   # süpürmede eller yere yakın
const L_LOWB := {"LeftUpperArm": Vector3(0.4, -0.9, -0.1), "LeftLowerArm": Vector3(0.2, -0.95, 0.2)}
const R_ARMUP := {"RightUpperArm": Vector3(-0.85, 0.35, 0.2), "RightLowerArm": Vector3(-0.7, 0.6, 0.3)}   # tekmede denge kolu
const L_ARMUP := {"LeftUpperArm": Vector3(0.85, 0.35, 0.2), "LeftLowerArm": Vector3(0.7, 0.6, 0.3)}
const R_ELBOW := {"RightUpperArm": Vector3(-0.85, -0.2, -0.45), "RightLowerArm": Vector3(0.1, 0.1, 0.99)}   # geriye dirsek
const R_FLING := {"RightUpperArm": Vector3(-0.1, 0.0, 1), "RightLowerArm": Vector3(0.0, -0.1, 1)}            # avuç öne açılmış (tazıyı salar)
const R_GROUND := {"RightUpperArm": Vector3(-0.1, -0.75, 0.65), "RightLowerArm": Vector3(0.0, -0.95, 0.3)}   # avuç yere (kan mühürlü parşömen)
const L_GROUND := {"LeftUpperArm": Vector3(0.1, -0.75, 0.65), "LeftLowerArm": Vector3(0.0, -0.95, 0.3)}
const R_CHARGE := {"RightUpperArm": Vector3(-0.45, -0.6, 0.66), "RightLowerArm": Vector3(0.1, -0.2, 0.97)}   # şimşek topu aşağıda-önde, kol gergin
const L_GRIP := {"LeftUpperArm": Vector3(0.1, -0.6, 0.79), "LeftLowerArm": Vector3(-0.65, -0.2, 0.73)}       # sol el sağ bileği kavrar
const R_STAB := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}

const KICK_L := {"LeftUpperLeg": Vector3(0.5, 0.1, 0.86), "LeftLowerLeg": Vector3(0.6, 0.1, 0.8), "RightUpperLeg": Vector3(-0.15, -0.95, 0.2), "RightLowerLeg": Vector3(-0.05, -0.98, -0.15)}   # alçak süpürme
const KICK_H := {"RightUpperLeg": Vector3(-0.85, 0.35, 0.4), "RightLowerLeg": Vector3(-0.95, 0.2, 0.2), "LeftUpperLeg": Vector3(0.1, -0.98, 0.05), "LeftLowerLeg": Vector3(0.05, -0.98, -0.12)}   # yüksek döner tekme


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var BK = F.SHIFT
	var ST = F.STEPIN
	var PV = F.PIVOT
	return [
		{"len": 0.55, "hit": 0.26, "keys": [   # 1 alçak süpürme tekmesi: çömel, bacak yarım daire süpürür
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.12, 0.7, -40, 20, R_LOWB, L_LOWB, F.LOW),
			_t(0.26, 0.74, 60, 22, R_LOWB, L_LOWB, KICK_L),
			_t(0.38, 0.72, 90, 20, R_LOWB, L_LOWB, KICK_L),
			_t(0.55, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.6, "hit": 0.3, "keys": [   # 2 yüksek döner tekme
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.14, 0.38, 40, -6, R_ARMUP, L_GUARD, PV),
			_t(0.3, 0.3, -70, -14, R_ARMUP, L_ARMUP, KICK_H),
			_t(0.42, 0.3, -90, -12, R_ARMUP, L_ARMUP, KICK_H),
			_t(0.6, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.65, "hit": 0.36, "keys": [   # 3 Shunshin: kaybolur -> arkasında belirip geriye dirsek
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.14, 0.5, 0, 10, R_GUARD, L_GUARD, F.LOW),
			_t(0.28, 0.42, 30, -4, R_ELBOW, L_GUARD, BK),
			_t(0.36, 0.42, 36, -6, R_ELBOW, L_GUARD, BK),
			_t(0.65, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.7, "hit": 0.32, "keys": [   # 4 Raijū Tsuiga: avuç öne — şimşek tazısı salınır
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.16, 0.46, -16, 6, R_CHARGE, L_GRIP, BK),
			_t(0.32, 0.42, 14, 18, R_FLING, L_GRIP, ST),
			_t(0.5, 0.4, 12, 14, R_FLING, L_GRIP, ST),
			_t(0.7, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.34, "keys": [   # 5 Doton Tsuiga: diz çöküp avuçlar yere
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.16, 0.66, 0, 30, R_GROUND, L_GROUND, F.LOW),
			_t(0.34, 0.68, 0, 32, R_GROUND, L_GROUND, F.LOW),
			_t(0.56, 0.6, 0, 26, R_GROUND, L_GROUND, F.LOW),
			_t(0.75, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 1.2, "hit": 0.72, "keys": [   # 6 Raikiri: alçak duruşta şimşek toplanır (uzun) -> dalıp saplar
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.2, 0.62, -20, 18, R_CHARGE, L_GRIP, F.LOW),
			_t(0.6, 0.64, -22, 20, R_CHARGE, L_GRIP, F.LOW),
			_t(0.72, 0.5, 12, 30, R_STAB, L_GUARD, ST),
			_t(0.95, 0.48, 10, 26, R_STAB, L_GUARD, ST),
			_t(1.2, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
	]
