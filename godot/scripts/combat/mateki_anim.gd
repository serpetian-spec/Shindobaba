extends RefCounted
## Mateki — Tayuya'nın şeytani flütü (ref _tmp/dokiref "Demonic Flute.png": uzun beyaz-lavanta yan flüt, sağa doğru tutulur,
## iki el delikler üstünde). Kanon dövüşü: flütü dudağına götürüp ezgiyle genjutsu (Mateki: Mugen Onsa — ses zincirleri),
## ruh dalgası ve Doki'leri yönetir; yakına gelene flütle vurur. Kombo:
## 1 Fue Uchi: flütle ters el savuruş, 2 Fue Tsuki: flüt ucuyla dürtme, 3 Onpa: dudağa götürüp keskin nota — ses halkası iter,
## 4 Mugen Onsa: kısa ezgi, rakibi kırmızı ses zincirleri bağlar, 5 Reigeki: ezgiyle ruh solucanı rakibe dalar (chakra yer),
## 6 Doki no Tsuchi (bitiriş): uzun ezgi — Gürzlü Doki arkadan dumanla belirir, gürzünü rakibin üstüne indirir.

const S = preload("res://scripts/combat/samehada_anim.gd")
const T = preload("res://scripts/combat/tanto_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")

# çalma duruşu: iki el ağzın sağ önünde, flüt sağa uzanır (+X karakterin solu -> sağ: -X)
const R_PLAY := {"RightUpperArm": Vector3(-0.6, -0.22, 0.77), "RightLowerArm": Vector3(0.42, 0.88, 0.2)}
const L_PLAY := {"LeftUpperArm": Vector3(0.12, 0.28, 0.95), "LeftLowerArm": Vector3(-0.94, 0.3, 0.18)}   # sol el ağzın önünden flütün deliklerine uzanır
const R_PLAY_HI := {"RightUpperArm": Vector3(-0.62, -0.15, 0.77), "RightLowerArm": Vector3(0.38, 0.9, 0.18)}
const FLUTE := Vector3(-1.0, 0.12, 0.15)   # flütün yönü (çalarken)


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var ST = F.STEPIN
	var BK = F.SHIFT
	var PV = F.PIVOT
	var RDY = Vector3(0, 0.3, 1)
	return [
		{"len": 0.45, "hit": 0.18, "keys": [   # 1 Fue Uchi
			_t(0.0, 0.38, 0, 6, RDY, T.R_READY, T.L_GUARD, W),
			_t(0.09, 0.42, 30, 0, Vector3(0.8, 0.2, 0.5), T.R_LEFT, T.L_GUARD, BK),
			_t(0.18, 0.46, -28, 12, Vector3(-0.9, 0.1, 0.4), T.R_WIDE, T.L_BACK, PV),
			_t(0.28, 0.44, -30, 10, Vector3(-0.95, 0.05, 0.3), T.R_WIDE, T.L_BACK, PV),
			_t(0.45, 0.38, 0, 6, RDY, T.R_READY, T.L_GUARD, W),
		]},
		{"len": 0.45, "hit": 0.18, "keys": [   # 2 Fue Tsuki
			_t(0.0, 0.38, 0, 6, RDY, T.R_READY, T.L_GUARD, W),
			_t(0.09, 0.42, -12, -4, Vector3(0, 0.05, 1), T.R_CHAMBER, T.L_GUARD, BK),
			_t(0.18, 0.5, 10, 18, Vector3(0, 0.0, 1), T.R_STAB, T.L_BACK, ST),
			_t(0.3, 0.48, 10, 16, Vector3(0, 0.0, 1), T.R_STAB, T.L_BACK, ST),
			_t(0.45, 0.38, 0, 6, RDY, T.R_READY, T.L_GUARD, W),
		]},
		{"len": 0.6, "hit": 0.32, "keys": [   # 3 Onpa: flüt dudağa, keskin nota
			_t(0.0, 0.38, 0, 6, RDY, T.R_READY, T.L_GUARD, W),
			_t(0.16, 0.36, 18, 2, FLUTE, R_PLAY, L_PLAY, W),
			_t(0.32, 0.34, 20, -4, FLUTE, R_PLAY_HI, L_PLAY, BK),   # nota: baş hafif geri
			_t(0.44, 0.36, 18, 0, FLUTE, R_PLAY, L_PLAY, W),
			_t(0.6, 0.38, 0, 6, RDY, T.R_READY, T.L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.4, "keys": [   # 4 Mugen Onsa: kısa ezgi (gövde ritimle sallanır)
			_t(0.0, 0.38, 0, 6, RDY, T.R_READY, T.L_GUARD, W),
			_t(0.14, 0.36, 18, 2, FLUTE, R_PLAY, L_PLAY, W),
			_t(0.3, 0.38, 26, 6, FLUTE, R_PLAY_HI, L_PLAY, W),
			_t(0.46, 0.36, 12, -2, FLUTE, R_PLAY, L_PLAY, W),
			_t(0.6, 0.38, 22, 4, FLUTE, R_PLAY_HI, L_PLAY, W),
			_t(0.75, 0.38, 0, 6, RDY, T.R_READY, T.L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.38, "keys": [   # 5 Reigeki: ezgi, eğilip ruh salar
			_t(0.0, 0.38, 0, 6, RDY, T.R_READY, T.L_GUARD, W),
			_t(0.16, 0.42, 16, 10, FLUTE, R_PLAY, L_PLAY, W),
			_t(0.38, 0.48, 22, 18, FLUTE, R_PLAY_HI, L_PLAY, ST),
			_t(0.55, 0.44, 18, 12, FLUTE, R_PLAY, L_PLAY, ST),
			_t(0.75, 0.38, 0, 6, RDY, T.R_READY, T.L_GUARD, W),
		]},
		{"len": 1.4, "hit": 0.95, "keys": [   # 6 Doki no Tsuchi: uzun ezgi, Doki arkadan belirip gürzü indirir
			_t(0.0, 0.38, 0, 6, RDY, T.R_READY, T.L_GUARD, W),
			_t(0.2, 0.36, 18, 0, FLUTE, R_PLAY, L_PLAY, W),
			_t(0.5, 0.34, 26, -6, FLUTE, R_PLAY_HI, L_PLAY, BK),
			_t(0.8, 0.36, 14, 2, FLUTE, R_PLAY, L_PLAY, W),
			_t(1.1, 0.36, 22, -4, FLUTE, R_PLAY_HI, L_PLAY, W),
			_t(1.4, 0.38, 0, 6, RDY, T.R_READY, T.L_GUARD, W),
		]},
	]
