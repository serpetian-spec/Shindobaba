extends RefCounted
## Jinchūriki tarzı — Matatabi (İki Kuyruk, Yugito). YAKIN. Görseller oyunun gerçek bijū sistemi (BijuuArts): mavi alevli pençe
## izleri (_claw_marks, "blue" ateş malzemesi), kedi sıçrayışı (_neko_pounce: yay çizen atılış), mavi ateş topları (_aobi_dama),
## yerde yanan mavi alev öbeği (_blue_patch). Kanon: Yugito kedi gibi dört ayak sıçrar, tırnakları mavi alevle uzar (Nekomata),
## mavi alev topları tükürür, Bakeneko'nun ruh alevleri.
## 1-2 mavi alev tırnak (sağ/sol pençe), 3 kedi sıçrayışı (yay çizip pençeyle iner), 4 mavi ateş topu yağmuru (küçük),
## 5 alçak süpürme + yerde mavi alev, 6 bitiriş: çapraz çift pençe X — mavi alev yarığı.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")
const R_CLAW := {"RightUpperArm": Vector3(-0.5, 0.45, 0.74), "RightLowerArm": Vector3(-0.2, 0.3, 0.93)}   # pençe yukarıdan
const L_CLAW := {"LeftUpperArm": Vector3(0.5, 0.45, 0.74), "LeftLowerArm": Vector3(0.2, 0.3, 0.93)}


static func steps() -> Array:
	return [
		C.step(0.42, 0.2, R_CLAW, C.L_GUARD, C.R_DOWN, C.L_GUARD, F.SHIFT, F.PIVOT, -24.0, 24.0, 0.5, 18.0),
		C.step(0.42, 0.2, C.R_GUARD, L_CLAW, C.R_GUARD, C.L_LOW, F.FIGHT, F.PIVOT_L, 24.0, -24.0, 0.5, 18.0),
		C.step(0.7, 0.36, C.R_LOW, C.L_LOW, R_CLAW, L_CLAW, F.LOW, F.HOP, 0.0, 0.0, 0.8, 34.0),
		C.step(0.6, 0.3, C.R_MOUTH, C.L_LOW, C.R_MOUTH, C.L_LOW, F.LOW, F.STEPIN, 0.0, 0.0, 0.7, 30.0),
		C.step(0.55, 0.26, C.R_LOW, C.L_LOW, C.R_SWEEP_OUT, C.L_LOW, F.LOW, F.LOW, 40.0, -60.0, 0.9, 40.0),
		{"len": 1.0, "hit": 0.56, "keys": [
			C.t(0.0, 0.5, 0, 14, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.24, 0.4, 0, -6, R_CLAW, L_CLAW, F.HOP),
			C.t(0.48, 0.4, 0, -8, R_CLAW, L_CLAW, F.HOP),
			C.t(0.56, 0.7, 0, 30, C.R_DOWN, C.L_LOW, F.STEPIN),
			C.t(0.8, 0.66, 0, 26, C.R_DOWN, C.L_LOW, F.STEPIN),
			C.t(1.0, 0.5, 0, 14, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
