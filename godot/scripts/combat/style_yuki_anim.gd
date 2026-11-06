extends RefCounted
## Dövüş tarzı — Yuki (Hyōton, Haku). ORTA MENZİL, ÇEVİK. Ref: refs/styles/yuki_*.png + text/yuki.txt (buz aynaları, buz iğneleri,
## Tsubame Fubuki buz kırlangıçları, Sensatsu Suishō bin iğne). Hafif ayaklı, sekerek; parmak arasında buz iğneleri.
## 1 Hari Uchi: sağ el yandan savrulur, üç buz iğnesi, 2 Gyaku Hari: sol el, üç iğne, 3 Hyōshō: yakın buz avucu (rakip donar),
## 4 Tsubame Fubuki: kollar açılır, hedefi takip eden buz kırlangıçları, 5 Kaiten Hari: dönerken çevreye iğne,
## 6 Sensatsu Suishō: tek el mühür — rakibin çevresinde iğneler belirir ve içe saplanır.

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const R_IDLE := {"RightUpperArm": Vector3(-0.3, -0.85, 0.42), "RightLowerArm": Vector3(0.2, 0.3, 0.93)}
const L_IDLE := {"LeftUpperArm": Vector3(0.3, -0.85, 0.42), "LeftLowerArm": Vector3(-0.2, 0.3, 0.93)}
const R_FLICK0 := {"RightUpperArm": Vector3(0.3, -0.5, 0.8), "RightLowerArm": Vector3(0.8, 0.3, 0.5)}     # göğüs önünde kurulu
const R_FLICK1 := {"RightUpperArm": Vector3(-0.85, 0.1, 0.5), "RightLowerArm": Vector3(-0.8, 0.05, 0.6)}  # yana fırlatılmış
const L_FLICK0 := {"LeftUpperArm": Vector3(-0.3, -0.5, 0.8), "LeftLowerArm": Vector3(-0.8, 0.3, 0.5)}
const L_FLICK1 := {"LeftUpperArm": Vector3(0.85, 0.1, 0.5), "LeftLowerArm": Vector3(0.8, 0.05, 0.6)}
const R_PALM := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.14, 1)}
const R_SPREAD := {"RightUpperArm": Vector3(-0.9, 0.35, 0.25), "RightLowerArm": Vector3(-0.85, 0.4, 0.35)}
const L_SPREAD := {"LeftUpperArm": Vector3(0.9, 0.35, 0.25), "LeftLowerArm": Vector3(0.85, 0.4, 0.35)}
const R_SEAL1 := {"RightUpperArm": Vector3(-0.15, -0.4, 0.9), "RightLowerArm": Vector3(0.3, 0.9, 0.3)}   # tek el mühür, yüz önünde dik


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var BK = F.SHIFT
	var PV = F.PIVOT
	var PL = F.PIVOT_L
	var H = F.HOP
	return [
		{"len": 0.42, "hit": 0.17, "keys": [
			_t(0.0, 0.38, 0, 6, R_IDLE, L_IDLE, W),
			_t(0.08, 0.44, 24, 4, R_FLICK0, L_IDLE, BK),
			_t(0.17, 0.4, -30, 8, R_FLICK1, L_IDLE, PV),
			_t(0.26, 0.4, -34, 6, R_FLICK1, L_IDLE, PV),
			_t(0.42, 0.38, 0, 6, R_IDLE, L_IDLE, W),
		]},
		{"len": 0.42, "hit": 0.17, "keys": [
			_t(0.0, 0.38, 0, 6, R_IDLE, L_IDLE, W),
			_t(0.08, 0.44, -24, 4, R_IDLE, L_FLICK0, BK),
			_t(0.17, 0.4, 30, 8, R_IDLE, L_FLICK1, PL),
			_t(0.26, 0.4, 34, 6, R_IDLE, L_FLICK1, PL),
			_t(0.42, 0.38, 0, 6, R_IDLE, L_IDLE, W),
		]},
		{"len": 0.5, "hit": 0.22, "keys": [
			_t(0.0, 0.38, 0, 6, R_IDLE, L_IDLE, W),
			_t(0.1, 0.5, -18, 4, R_FLICK0, L_IDLE, BK),
			_t(0.22, 0.46, 16, 18, R_PALM, L_IDLE, F.STEPIN),
			_t(0.32, 0.44, 14, 16, R_PALM, L_IDLE, F.STEPIN),
			_t(0.5, 0.38, 0, 6, R_IDLE, L_IDLE, W),
		]},
		{"len": 0.65, "hit": 0.3, "keys": [
			_t(0.0, 0.38, 0, 6, R_IDLE, L_IDLE, W),
			_t(0.14, 0.3, 0, -4, R_FLICK0, L_FLICK0, H),
			_t(0.3, 0.25, 0, -10, R_SPREAD, L_SPREAD, H),   # kollar açılır: kırlangıçlar fırlar
			_t(0.44, 0.3, 0, -8, R_SPREAD, L_SPREAD, W),
			_t(0.65, 0.38, 0, 6, R_IDLE, L_IDLE, W),
		]},
		{"len": 0.7, "hit": 0.2, "extra_hits": [0.36, 0.52], "extra_radius": 2.4, "keys": [
			_t(0.0, 0.38, 0, 6, R_IDLE, L_IDLE, W),
			_t(0.12, 0.42, 100, 4, R_SPREAD, L_SPREAD, W),
			_t(0.26, 0.42, -150, 4, R_FLICK1, L_FLICK1, W),
			_t(0.4, 0.42, 120, 4, R_SPREAD, L_SPREAD, W),
			_t(0.54, 0.42, -60, 4, R_FLICK1, L_FLICK1, W),
			_t(0.7, 0.38, 0, 6, R_IDLE, L_IDLE, W),
		]},
		{"len": 0.85, "hit": 0.48, "keys": [
			_t(0.0, 0.38, 0, 6, R_IDLE, L_IDLE, W),
			_t(0.18, 0.4, 0, 0, R_SEAL1, L_IDLE, BK),
			_t(0.38, 0.4, 0, 0, R_SEAL1, L_IDLE, BK),   # mühür: iğneler rakibin çevresinde belirir
			_t(0.48, 0.38, 0, 6, R_SEAL1, L_IDLE, W),
			_t(0.85, 0.38, 0, 6, R_IDLE, L_IDLE, W),
		]},
	]
