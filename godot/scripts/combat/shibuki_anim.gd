class_name ShibukiAnim
## Shibuki kombosu, 6 vuruş (pozlar ornek2-5; hareketler _tmp/ed/shibuki_desc.md kendime anlatımı, her satır bir anahtar).
## Ağır: rulo hep ARKADAN kurulur; kâğıt yüzü (yassı yüz) savuruşta önde gider ve patlar. Etkiler: KeyedCombos.on_strike.
## Yönler iskelet uzayında: +Z ön, +X karakterin solu, +Y yukarı. "blade": sağ yumruktan rulo ucuna sap yönü.

const R_BELLY := {"RightUpperArm": Vector3(-0.1, -0.85, 0.5), "RightLowerArm": Vector3(0.6, -0.2, 0.75)}
const R_SIDE := {"RightUpperArm": Vector3(-1, 0.05, 0.1), "RightLowerArm": Vector3(-0.95, 0.0, 0.3)}
const R_HIP_BACK := {"RightUpperArm": Vector3(-0.35, -0.9, -0.25), "RightLowerArm": Vector3(-0.15, -0.75, 0.6)}
const R_HIP_SIDE := {"RightUpperArm": Vector3(-0.4, -0.9, -0.1), "RightLowerArm": Vector3(-0.1, -0.95, 0.2)}
const R_FWD := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.0, 1)}
const R_FWD_HIGH := {"RightUpperArm": Vector3(-0.1, 0.45, 0.9), "RightLowerArm": Vector3(0.0, 0.3, 0.95)}
const R_LCHEST := {"RightUpperArm": Vector3(0.2, -0.6, 0.75), "RightLowerArm": Vector3(0.85, 0.4, 0.2)}
const R_LSHOULDER := {"RightUpperArm": Vector3(0.2, -0.3, 0.93), "RightLowerArm": Vector3(0.9, 0.4, -0.1)}
const R_LOW_FRONT := {"RightUpperArm": Vector3(-0.1, -0.8, 0.6), "RightLowerArm": Vector3(0.1, -0.7, 0.7)}
const R_ABOVE := {"RightUpperArm": Vector3(-0.3, 0.95, 0.1), "RightLowerArm": Vector3(-0.05, 1, 0.1)}
const R_SH_UP := {"RightUpperArm": Vector3(-0.6, 0.6, 0.5), "RightLowerArm": Vector3(-0.2, 0.9, 0.4)}
const R_CHEST := {"RightUpperArm": Vector3(-0.2, -0.4, 0.9), "RightLowerArm": Vector3(0.2, 0.1, 1)}
const L_DOWN := {"LeftUpperArm": Vector3(0.3, -0.9, 0.3), "LeftLowerArm": Vector3(0.1, -0.8, 0.6)}
const L_SIDE := {"LeftUpperArm": Vector3(0.9, -0.35, 0.2), "LeftLowerArm": Vector3(0.8, -0.4, 0.4)}   # denge kolu yana açık
const L_BACK := {"LeftUpperArm": Vector3(0.55, -0.55, -0.6), "LeftLowerArm": Vector3(0.3, -0.6, -0.75)}
const L_UP := {"LeftUpperArm": Vector3(0.75, 0.6, 0.25), "LeftLowerArm": Vector3(0.5, 0.8, 0.3)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	# ağır rulo bedeni taşır: burulma/eğilme tarif açılarından belirgin
	return SamehadaAnim._k(t, minf(1.0, crouch * 1.1), yaw * 1.5, lean * 1.4, blade.normalized(), SamehadaAnim._a(r, l), legs)


static func steps() -> Array:
	var W = SamehadaAnim.LEG_WIDE
	var L = SamehadaAnim.LEG_LUNGE
	return [
		# 1 Kâğıt Savuruşu: rulo sağ-arkaya açılır -> kâğıt yüzü önde sağdan sola göğüs hizası geniş yay (üç patlama) -> sol-arkaya
		{"len": 0.95, "hit": 0.42, "two": false, "keys": [
			_t(0.0, 0.3, 0, 2, Vector3(0.4, -0.2, 0.9), R_BELLY, L_DOWN, W),
			_t(0.14, 0.35, -30, -6, Vector3(-0.8, 0.0, -0.55), R_SIDE, L_SIDE, W),
			_t(0.28, 0.38, -48, -10, Vector3(-0.35, 0.05, -0.94), R_HIP_BACK, L_SIDE, W),
			_t(0.34, 0.39, -50, -11, Vector3(-0.33, 0.05, -0.94), R_HIP_BACK, L_SIDE, W),
			_t(0.38, 0.42, -20, 4, Vector3(-0.98, 0.05, 0.15), R_SIDE, L_SIDE, W),
			_t(0.42, 0.5, 14, 17, Vector3(0.1, 0.0, 1.0), R_FWD, L_BACK, L),
			_t(0.5, 0.52, 42, 21, Vector3(0.95, 0.0, 0.3), R_LCHEST, L_BACK, L),
			_t(0.66, 0.52, 52, 17, Vector3(0.75, -0.1, -0.65), R_LCHEST, L_BACK, L),
			_t(0.95, 0.4, 34, 8, Vector3(0.7, -0.2, -0.6), R_LCHEST, L_DOWN, W),
		]},
		# 2 Çapraz Çekiç (iki el): rulo sol omzun üstünden sırta kurulur, gövde sola burulu -> sağ-öne çapraz iner, yere vurur
		{"len": 1.0, "hit": 0.46, "two": true, "keys": [
			_t(0.0, 0.4, 34, 8, Vector3(0.7, -0.2, -0.6), R_LCHEST, L_DOWN, W),
			_t(0.16, 0.38, 30, -6, Vector3(0.45, 0.85, -0.2), R_LSHOULDER, L_DOWN, W),
			_t(0.3, 0.42, 38, -16, Vector3(0.45, 0.35, -0.82), R_LSHOULDER, L_DOWN, W),
			_t(0.36, 0.43, 40, -17, Vector3(0.44, 0.33, -0.83), R_LSHOULDER, L_DOWN, W),
			_t(0.41, 0.5, 15, 4, Vector3(0.2, 0.95, 0.2), R_ABOVE, L_DOWN, W),
			_t(0.46, 0.8, -15, 38, Vector3(-0.35, -0.5, 0.79), R_LOW_FRONT, L_DOWN, L),
			_t(0.7, 0.8, -15, 37, Vector3(-0.35, -0.51, 0.78), R_LOW_FRONT, L_DOWN, L),
			_t(1.0, 0.52, -18, 14, Vector3(-0.4, -0.45, 0.8), R_BELLY, L_DOWN, W),
		]},
		# 3 Mühür Serpme: rulo sağ-arkada alçakta sürüklenir -> aşağıdan yukarı-öne fırlatırcasına kalkar (beş kâğıt uçar), parmak ucunda biter
		{"len": 0.9, "hit": 0.38, "two": false, "keys": [
			_t(0.0, 0.52, -18, 14, Vector3(-0.4, -0.45, 0.8), R_BELLY, L_DOWN, W),
			_t(0.2, 0.62, -40, 15, Vector3(-0.4, -0.6, -0.7), R_HIP_BACK, L_SIDE, W),
			_t(0.28, 0.63, -42, 16, Vector3(-0.38, -0.6, -0.7), R_HIP_BACK, L_SIDE, W),
			_t(0.34, 0.55, -12, 10, Vector3(-0.3, -0.55, 0.78), R_LOW_FRONT, L_SIDE, L),
			_t(0.38, 0.35, 8, -6, Vector3(0.0, 0.6, 0.8), R_FWD_HIGH, L_BACK, L),
			_t(0.48, 0.22, 10, -14, Vector3(0.1, 0.97, 0.2), R_ABOVE, L_BACK, W),
			_t(0.9, 0.3, 6, -6, Vector3(0.1, 0.9, 0.4), R_SH_UP, L_DOWN, W),
		]},
		# 4 Ters Patlama: rulo sol omzun arkasına kurulur -> ters savuruşla yassı yüz baş hizasında rakibe çarpar (büyük patlama) -> sağ-arkaya
		{"len": 0.95, "hit": 0.37, "two": false, "keys": [
			_t(0.0, 0.3, 6, -6, Vector3(0.1, 0.9, 0.4), R_SH_UP, L_DOWN, W),
			_t(0.2, 0.4, 50, 8, Vector3(0.75, 0.3, -0.6), R_LSHOULDER, L_DOWN, W),
			_t(0.28, 0.41, 52, 9, Vector3(0.74, 0.3, -0.6), R_LSHOULDER, L_DOWN, W),
			_t(0.33, 0.45, 25, 10, Vector3(0.9, 0.25, 0.35), R_LCHEST, L_DOWN, W),
			_t(0.37, 0.52, -10, 15, Vector3(0.0, 0.15, 1.0), R_FWD, L_SIDE, L),
			_t(0.45, 0.55, -40, 18, Vector3(-0.95, 0.1, 0.25), R_SIDE, L_SIDE, L),
			_t(0.6, 0.5, -50, 12, Vector3(-0.7, 0.0, -0.7), R_HIP_BACK, L_SIDE, L),
			_t(0.95, 0.42, -32, 6, Vector3(-0.65, -0.1, -0.72), R_HIP_BACK, L_DOWN, W),
		]},
		# 5 Koç Dürtmesi (iki el): sap sağ kalçaya çekilir, rulo önde yatay, gövde geriye -> derin hamleyle ileri saplanır -> patlamayla geri itilir
		{"len": 0.9, "hit": 0.36, "two": true, "keys": [
			_t(0.0, 0.42, -32, 6, Vector3(-0.65, -0.1, -0.72), R_HIP_BACK, L_DOWN, W),
			_t(0.16, 0.45, -28, -8, Vector3(0.0, 0.0, 1.0), R_HIP_SIDE, L_DOWN, W),
			_t(0.26, 0.47, -32, -13, Vector3(0.02, 0.02, 1.0), R_HIP_SIDE, L_DOWN, W),
			_t(0.3, 0.47, -33, -14, Vector3(0.02, 0.02, 1.0), R_HIP_SIDE, L_DOWN, W),
			_t(0.36, 0.62, 10, 30, Vector3(0.0, 0.0, 1.0), R_FWD, L_DOWN, L),
			_t(0.48, 0.5, 2, -10, Vector3(0.0, 0.18, 0.98), R_CHEST, L_DOWN, W),
			_t(0.9, 0.4, 0, 0, Vector3(0.1, 0.1, 0.99), R_CHEST, L_DOWN, W),
		]},
		# 6 Patlama Zinciri (iki el): rulo başın üstüne dik, gövde geriye kavisli -> kâğıt yüzü öne yere damga basar, yerde ileri beş patlama
		{"len": 1.25, "hit": 0.42, "two": true, "keys": [
			_t(0.0, 0.4, 0, 0, Vector3(0.1, 0.1, 0.99), R_CHEST, L_DOWN, W),
			_t(0.25, 0.32, -6, -13, Vector3(0.0, 0.97, -0.22), R_ABOVE, L_DOWN, W),
			_t(0.34, 0.33, -6, -14, Vector3(0.0, 0.96, -0.25), R_ABOVE, L_DOWN, W),
			_t(0.42, 0.85, 0, 42, Vector3(0.0, -0.45, 0.89), R_LOW_FRONT, L_DOWN, L),
			_t(0.85, 0.85, 0, 41, Vector3(0.0, -0.46, 0.89), R_LOW_FRONT, L_DOWN, L),
			_t(1.25, 0.45, 0, 12, Vector3(0.2, -0.3, 0.93), R_BELLY, L_DOWN, W),
		]},
	]
