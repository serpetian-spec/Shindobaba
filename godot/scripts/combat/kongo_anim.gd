extends RefCounted
## Elmas Asa (Kongō Nyoi) — Maymun Kral'ın dönüştüğü asa. İki elle tutulan uzun asa; vuruşta UZAR (KeyedCombos._staff_extend),
## bazı adımlarda asa canlanır: Maymun Kral dumanla hedefin yanında belirip kendisi vurur, sonra yine asaya döner (_enma_cameo).
## 1 uzayan saplama, 2 baş üstünden iniş, 3 Enma Kōgeki (maymun belirip yumruk), 4 dönen geniş süpürme (asa uzar),
## 5 sırıkla atlayıp tekme, 6 Kongō Rōheki (bitiriş): asa dev boyda süpürür + Maymun Kral iki yumrukla yere çakar.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.3, -0.8, 0.5), "RightLowerArm": Vector3(0.35, -0.1, 0.93)}
const R_DRAW := {"RightUpperArm": Vector3(-0.45, -0.5, -0.75), "RightLowerArm": Vector3(0.1, 0.25, 0.97)}
const R_THRUST := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.0, 1)}
const R_HIGH := {"RightUpperArm": Vector3(-0.3, 0.9, -0.3), "RightLowerArm": Vector3(-0.1, 0.8, -0.6)}
const R_DOWN := {"RightUpperArm": Vector3(-0.1, -0.35, 0.93), "RightLowerArm": Vector3(0.0, -0.6, 0.8)}
const R_WIDE := {"RightUpperArm": Vector3(-0.98, 0.0, 0.15), "RightLowerArm": Vector3(-0.95, 0.05, 0.3)}
const R_ACROSS := {"RightUpperArm": Vector3(0.4, -0.2, 0.9), "RightLowerArm": Vector3(0.9, 0.0, 0.4)}
const R_PLANT := {"RightUpperArm": Vector3(-0.15, -0.6, 0.78), "RightLowerArm": Vector3(0.0, -0.9, 0.4)}
const R_SEAL := {"RightUpperArm": Vector3(-0.2, -0.3, 0.93), "RightLowerArm": Vector3(0.6, 0.45, 0.66)}
const L_ANY := {"LeftUpperArm": Vector3(0.3, -0.8, 0.45), "LeftLowerArm": Vector3(-0.1, -0.2, 0.97)}
const L_SEAL := {"LeftUpperArm": Vector3(0.2, -0.3, 0.93), "LeftLowerArm": Vector3(-0.6, 0.45, 0.66)}
const KICK := {"RightUpperLeg": Vector3(-0.1, 0.1, 0.99), "RightLowerLeg": Vector3(-0.05, 0.05, 1), "RightFoot": Vector3(0, 0.6, 0.8)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, legs: Dictionary, l := L_ANY) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.3, 0.3, 0.9)
	var F = Vector3(0, 0, 1)
	return [
		# 1 Nobi Tsuki: asa geri çekilir -> adımla ileri saplama, asa iki katına uzar
		{"len": 0.85, "hit": 0.32, "two": true, "keys": [
			_t(0.0, 0.36, -4, 4, RDY, R_READY, W),
			_t(0.16, 0.42, -18, -6, F, R_DRAW, BK),
			_t(0.28, 0.44, -20, -8, F, R_DRAW, BK),
			_t(0.32, 0.5, 10, 20, F, R_THRUST, L),
			_t(0.56, 0.48, 8, 16, F, R_THRUST, L),
			_t(0.85, 0.36, -4, 4, RDY, R_READY, W),
		]},
		# 2 Otoshi: asa baş üstüne-arkaya kalkar (bekle) -> tüm gövdeyle önüne iner, yere vurur
		{"len": 1.0, "hit": 0.48, "two": true, "keys": [
			_t(0.0, 0.36, -4, 4, RDY, R_READY, W),
			_t(0.22, 0.38, -6, -22, Vector3(0, 0.7, -0.7), R_HIGH, BK),
			_t(0.4, 0.4, -8, -26, Vector3(0, 0.65, -0.75), R_HIGH, BK),
			_t(0.48, 0.64, 6, 32, Vector3(0, -0.75, 0.66), R_DOWN, L),
			_t(0.7, 0.62, 4, 28, Vector3(0, -0.8, 0.6), R_DOWN, L),
			_t(1.0, 0.36, -4, 4, RDY, R_READY, W),
		]},
		# 3 Enma Kōgeki: asa öne uzatılır, tek el mühür -> asa elinden kaybolur, Maymun Kral hedefin yanında belirip yumruk atar
		{"len": 1.3, "hit": 0.4, "keys": [
			_t(0.0, 0.36, -4, 4, RDY, R_READY, W),
			_t(0.18, 0.4, 0, 6, F, R_THRUST, ST, L_SEAL),
			_t(0.36, 0.4, 0, 6, F, R_THRUST, ST, L_SEAL),
			_t(0.5, 0.38, 0, 0, F, R_SEAL, W, L_SEAL),
			_t(1.0, 0.38, 0, 0, F, R_SEAL, W, L_SEAL),
			_t(1.3, 0.36, -4, 4, RDY, R_READY, W),
		]},
		# 4 Kaiten Barai: asa yana açık, gövde tam tur döner; asa uzayıp geniş süpürür (çoklu)
		{"len": 1.1, "hit": 0.36, "two": true, "extra_hits": [0.62], "extra_radius": 3.6, "keys": [
			_t(0.0, 0.36, -4, 4, RDY, R_READY, W),
			_t(0.18, 0.46, -30, 4, Vector3(-0.9, 0.05, 0.3), R_WIDE, BK),
			_t(0.36, 0.48, 70, 8, Vector3(-0.9, 0.05, 0.3), R_WIDE, CR),
			_t(0.56, 0.48, 180, 8, Vector3(-0.9, 0.05, 0.3), R_WIDE, W),
			_t(0.74, 0.46, 40, 10, Vector3(0.9, 0.05, 0.3), R_ACROSS, L),
			_t(1.1, 0.36, -4, 4, RDY, R_READY, W),
		]},
		# 5 Bō Tobi: asa önde yere saplanır, sırıkla havalanır -> çift tekme, asayı çekip iner
		{"len": 1.05, "hit": 0.52, "keys": [
			_t(0.0, 0.36, -4, 4, RDY, R_READY, W),
			_t(0.2, 0.52, 0, 22, Vector3(0, -0.95, 0.3), R_PLANT, L),
			_t(0.36, 0.28, 0, -12, Vector3(0, -0.95, 0.3), R_PLANT, W),
			_t(0.52, 0.18, 0, -28, Vector3(0, -0.95, 0.3), R_PLANT, KICK),
			_t(0.7, 0.22, 0, -22, Vector3(0, -0.95, 0.3), R_PLANT, KICK),
			_t(0.86, 0.42, 0, 8, Vector3(0, -0.9, 0.4), R_PLANT, W),
			_t(1.05, 0.36, -4, 4, RDY, R_READY, W),
		]},
		# 6 Kongō Rōheki (bitiriş): iki elle baş üstünde döndürür -> asa dev boyda uzayıp önü süpürür; ardından Maymun Kral
		#   hedefin üstünde belirip iki yumrukla yere çakar
		{"len": 1.7, "hit": 0.6, "two": true, "keys": [
			_t(0.0, 0.36, -4, 4, RDY, R_READY, W),
			_t(0.2, 0.36, -20, -8, Vector3(0, 0.95, 0.2), R_HIGH, W),
			_t(0.42, 0.38, 24, -8, Vector3(0, 0.95, 0.2), R_HIGH, CR),
			_t(0.52, 0.5, -30, 14, Vector3(-0.9, 0.05, 0.3), R_WIDE, ST),
			_t(0.62, 0.52, 40, 18, Vector3(0.9, 0.05, 0.3), R_ACROSS, L),
			_t(1.3, 0.46, 20, 10, Vector3(0.9, 0.05, 0.3), R_ACROSS, L),
			_t(1.7, 0.36, -4, 4, RDY, R_READY, W),
		]},
	]
