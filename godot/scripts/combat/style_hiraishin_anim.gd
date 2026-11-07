extends RefCounted
## Yol tarzı — Uçan Yıldırım (Minato, Hiraishin). ORTA. Görseller oyunun gerçek sistemleri: üç uçlu Hiraishin kunaisi
## (PathJutsu._hira_kunai), sarı flaş (PathJutsu._yellow_flash), işaret (status "marked" + hiraishin_by), Rasengan (VFX.rasengan).
## Kanon: Minato kunaileri yelpaze gibi atar; kunai nereye saplanırsa işaret olur, bir an sonra oradadır. Dokunduğu rakibe de
## işaret koyar (Hiraishin Ni no Dan: işaretli rakibin arkasında belirir). Kunai havada da yakalanır.
## 1 üç kunai yelpazesi (yere saplanır = işaret), 2 en yakın kunaiye ışınlanıp el kılıcı, 3 Ni no Dan: işaretli hedefin
## arkasında belirip tekme (havaya), 4 havaya atılan kunaiye ışınlan + yukarıdan iniş darbesi, 5 kunailer arası zincir kesik,
## 6 bitiriş: sarı flaş — arkasında Rasengan.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")
const R_CHOP := {"RightUpperArm": Vector3(-0.85, 0.2, 0.48), "RightLowerArm": Vector3(-0.3, 0.0, 0.95)}   # el kılıcı yanda kurulu


static func steps() -> Array:
	return [
		C.step(0.5, 0.24, C.R_THROW_BACK, C.L_GUARD, C.R_THROW, C.L_GUARD, F.SHIFT, F.PIVOT, -24.0, 18.0, 0.38, 6.0),
		C.step(0.5, 0.22, R_CHOP, C.L_GUARD, C.R_SWEEP_IN, C.L_GUARD, F.FIGHT, F.PIVOT, -30.0, 30.0, 0.4, 10.0),
		{"len": 0.6, "hit": 0.26, "keys": [
			C.t(0.0, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.14, 0.42, 30, -4, C.R_GUARD, C.L_GUARD, F.SHIFT),
			C.t(0.26, 0.3, -40, -10, C.R_BACK, C.L_GUARD, C.KICK_UP_R),
			C.t(0.42, 0.3, -30, -8, C.R_BACK, C.L_GUARD, C.KICK_UP_R),
			C.t(0.6, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
		C.step(0.65, 0.3, C.R_SKY, C.L_GUARD, C.R_DOWN, C.L_BACK, F.HOP, F.LOW, 0.0, 0.0, 0.3, 30.0),
		C.step(0.65, 0.3, C.R_THROW_BACK, C.L_BACK, C.R_SWEEP_OUT, C.L_GUARD, F.SHIFT, F.PIVOT, 30.0, -40.0, 0.4, 8.0),
		{"len": 1.05, "hit": 0.6, "keys": [
			C.t(0.0, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.24, 0.44, -14, 8, C.R_PALM, C.L_SEAL, F.SHIFT),
			C.t(0.5, 0.44, -18, 10, C.R_PALM, C.L_SEAL, F.SHIFT),
			C.t(0.6, 0.42, 16, 22, C.R_PALM, C.L_GUARD, F.STEPIN),
			C.t(0.85, 0.4, 12, 16, C.R_PALM, C.L_GUARD, F.STEPIN),
			C.t(1.05, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
