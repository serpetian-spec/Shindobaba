extends RefCounted
## Dövüş tarzı — Kamizuru (Hachi Tsukai, arı ustaları). ORTA-UZAK MENZİL. Ref: refs/styles/kamizuru_*.png
## (0 Hachi Senbon: turuncu-kara eşek arısı sürüsü öne uçar, iğneleri ince mor çizgi gibi fırlar; 1 Hachi Bakudan: arılar
## altlarında patlayıcı kâğıt taşır; 2-3 Hachi Mitsu: öldürülen arı iri turuncu yapışkan bala patlar; 4 dev kraliçe arı).
## Kanon (Narutopedia, Suzumebachi/Jibachi/Kurobachi): arı sokması zehirlidir, kurbanı saniyeler içinde uyutur; Kamizuru çağırma
## mührü genel mühür değil — sağ başparmak sol avuca bastırılır.
## 1 Hachi Senbon (sağ): yen savrulur, arılar iğne yağdırır, 2 aynısı sol, 3 Hachi Mitsu: iki avuç itilir, bal arıları hedefte
## patlayıp yapıştırır, 4 başparmak-avuç mührü: hedefin altından arı sütunu yükselir (havaya kaldırır),
## 5 Hachi Bakudan: kol yukarı-ileri fırlatılır, kâğıt taşıyan arılar kavisle dalıp patlar,
## 6 Senbon Fubuki (bitiriş): kollar iki yana açılır, sürü yelpaze gibi açılıp hedefte birleşir — zehir uyutur.

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")   # canlı bacaklar: bükük diz, ağırlık aktarımı, pivot

const R_GUARD := {"RightUpperArm": Vector3(-0.35, -0.85, 0.35), "RightLowerArm": Vector3(0.1, 0.3, 0.95)}
const L_GUARD := {"LeftUpperArm": Vector3(0.35, -0.85, 0.35), "LeftLowerArm": Vector3(-0.1, 0.3, 0.95)}
const R_WIND := {"RightUpperArm": Vector3(-0.85, 0.1, -0.5), "RightLowerArm": Vector3(-0.4, 0.5, -0.75)}    # yen arkaya toplanır
const L_WIND := {"LeftUpperArm": Vector3(0.85, 0.1, -0.5), "LeftLowerArm": Vector3(0.4, 0.5, -0.75)}
const R_FLING := {"RightUpperArm": Vector3(-0.25, 0.15, 0.96), "RightLowerArm": Vector3(0.15, 0.1, 0.98)}   # avuç açık öne savrulmuş
const L_FLING := {"LeftUpperArm": Vector3(0.25, 0.15, 0.96), "LeftLowerArm": Vector3(-0.15, 0.1, 0.98)}
const R_PUSH := {"RightUpperArm": Vector3(-0.1, 0.0, 1), "RightLowerArm": Vector3(0.05, 0.2, 0.98)}
const L_PUSH := {"LeftUpperArm": Vector3(0.1, 0.0, 1), "LeftLowerArm": Vector3(-0.05, 0.2, 0.98)}
# Kamizuru çağırma mührü: sol avuç göğüs önünde yukarı açık, sağ başparmak içine bastırır
const R_SEAL := {"RightUpperArm": Vector3(-0.3, -0.75, 0.6), "RightLowerArm": Vector3(0.75, 0.15, 0.65)}
const L_SEAL := {"LeftUpperArm": Vector3(0.3, -0.8, 0.5), "LeftLowerArm": Vector3(-0.7, 0.05, 0.71)}
const R_UPTHROW := {"RightUpperArm": Vector3(-0.2, 0.75, 0.62), "RightLowerArm": Vector3(-0.05, 0.85, 0.5)}
const R_SPREAD := {"RightUpperArm": Vector3(-0.95, 0.25, 0.2), "RightLowerArm": Vector3(-0.85, 0.35, 0.4)}
const L_SPREAD := {"LeftUpperArm": Vector3(0.95, 0.25, 0.2), "LeftLowerArm": Vector3(0.85, 0.35, 0.4)}
const R_CROSS := {"RightUpperArm": Vector3(0.2, -0.3, 0.93), "RightLowerArm": Vector3(0.7, 0.1, 0.7)}       # kollar göğüste çaprazlanır
const L_CROSS := {"LeftUpperArm": Vector3(-0.2, -0.3, 0.93), "LeftLowerArm": Vector3(-0.7, 0.1, 0.7)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var BK = F.SHIFT
	var ST = F.STEPIN
	var PV = F.PIVOT
	var PL = F.PIVOT_L
	return [
		{"len": 0.5, "hit": 0.2, "keys": [   # 1 Hachi Senbon (sağ)
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.1, 0.4, -30, 0, R_WIND, L_GUARD, BK),
			_t(0.2, 0.38, 22, 10, R_FLING, L_GUARD, PV),
			_t(0.32, 0.36, 18, 8, R_FLING, L_GUARD, PV),
			_t(0.5, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.5, "hit": 0.2, "keys": [   # 2 Hachi Senbon (sol)
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.1, 0.4, 30, 0, R_GUARD, L_WIND, BK),
			_t(0.2, 0.38, -22, 10, R_GUARD, L_FLING, PL),
			_t(0.32, 0.36, -18, 8, R_GUARD, L_FLING, PL),
			_t(0.5, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.6, "hit": 0.28, "keys": [   # 3 Hachi Mitsu: iki avuç itilir
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.14, 0.45, 0, -6, R_CROSS, L_CROSS, BK),
			_t(0.28, 0.4, 0, 12, R_PUSH, L_PUSH, ST),
			_t(0.42, 0.38, 0, 10, R_PUSH, L_PUSH, ST),
			_t(0.6, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.7, "hit": 0.34, "keys": [   # 4 başparmak-avuç mührü -> arı sütunu
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.16, 0.5, -8, 10, R_SEAL, L_SEAL, F.LOW),
			_t(0.34, 0.52, -8, 12, R_SEAL, L_SEAL, F.LOW),
			_t(0.5, 0.42, 0, 4, R_SEAL, L_SEAL, W),
			_t(0.7, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.36, "keys": [   # 5 Hachi Bakudan: kâğıtlı arıları yukarı-ileri salar
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.16, 0.48, -35, 6, R_WIND, L_GUARD, BK),
			_t(0.36, 0.3, 25, -10, R_UPTHROW, L_GUARD, ST),
			_t(0.5, 0.3, 20, -8, R_UPTHROW, L_GUARD, ST),
			_t(0.75, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
		{"len": 1.0, "hit": 0.5, "keys": [   # 6 Senbon Fubuki: kollar çaprazdan iki yana açılır, sürü yelpaze olur
			_t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
			_t(0.22, 0.5, 0, 16, R_CROSS, L_CROSS, F.LOW),
			_t(0.4, 0.52, 0, 18, R_CROSS, L_CROSS, F.LOW),
			_t(0.5, 0.28, 0, -10, R_SPREAD, L_SPREAD, W),
			_t(0.78, 0.28, 0, -10, R_SPREAD, L_SPREAD, W),
			_t(1.0, 0.35, 0, 4, R_GUARD, L_GUARD, W),
		]},
	]
