extends RefCounted
## Yol tarzı — Jashin (Hidan). YAKIN-ORTA. Görseller oyunun gerçek sistemleri: üç bıçaklı tırpan (PathJutsu._tri_scythe) ve
## kablosu (tether), geri çekilen kara mızrak (p_jashin_kazik ile aynı), kan sıçraması (VFX.debris kırmızı), Jashin çemberi
## (p_jashin_kurban'daki üçgenli kan çemberi, küçük). Kanon: Hidan tırpanı kabloyla fırlatıp geri çeker; rakibin kanını tadınca
## ayağıyla Jashin çemberini çizer, içindeyken kendine verdiği yarayı rakip de alır (lanet bağı); sonunda kalbine saplar.
## 1 tırpan fırlatışı (kan alır), 2 mızrak dürtüşü (kan alır), 3 tırpan savuruşu (çevre), 4 çemberi çiz (kan aldıysa lanet bağı),
## 5 bacağına sapla: lanetli rakip aynı yarayı alır, 6 bitiriş: kalbine sapla — lanetliye ağır yara (bağ yoksa tırpanla yere çakış).

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")
const R_STAB_SELF := {"RightUpperArm": Vector3(-0.2, -0.6, 0.77), "RightLowerArm": Vector3(0.75, 0.25, 0.6)}   # mızrak kendi göğsüne dönük
const R_STAB_LEG := {"RightUpperArm": Vector3(-0.15, -0.95, 0.25), "RightLowerArm": Vector3(0.2, -0.95, 0.2)}   # aşağı, bacağa


static func steps() -> Array:
	return [
		C.step(0.6, 0.28, C.R_THROW_BACK, C.L_GUARD, C.R_THROW, C.L_GUARD, F.SHIFT, F.PIVOT, -28.0, 22.0, 0.38, 6.0),
		C.step(0.5, 0.24, C.R_COCK, C.L_GUARD, C.R_REACH, C.L_GUARD, F.SHIFT, F.STEPIN, -16.0, 10.0, 0.4, 12.0),
		C.step(0.65, 0.3, C.R_SWEEP_OUT, C.L_SPREAD, C.R_SWEEP_IN, C.L_SPREAD, F.SHIFT, F.PIVOT, -60.0, 90.0, 0.42, 8.0),
		{"len": 0.75, "hit": 0.5, "keys": [
			C.t(0.0, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.2, 0.42, -40, 10, C.R_SPREAD, C.L_SPREAD, C.KICK_LOW_L),
			C.t(0.4, 0.42, 40, 10, C.R_SPREAD, C.L_SPREAD, C.KICK_LOW_L),
			C.t(0.5, 0.42, 120, 10, C.R_SPREAD, C.L_SPREAD, F.FIGHT),
			C.t(0.75, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
		C.step(0.6, 0.3, C.R_HIGH, C.L_GUARD, R_STAB_LEG, C.L_GUARD, F.FIGHT, F.LOW, 0.0, 0.0, 0.5, 18.0),
		{"len": 1.15, "hit": 0.68, "keys": [
			C.t(0.0, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.3, 0.3, 0, -18, C.R_SKY, C.L_SPREAD, F.FIGHT),
			C.t(0.58, 0.3, 0, -22, C.R_SKY, C.L_SPREAD, F.FIGHT),
			C.t(0.68, 0.42, 0, 26, R_STAB_SELF, C.L_SPREAD, F.FIGHT),
			C.t(0.95, 0.42, 0, 24, R_STAB_SELF, C.L_SPREAD, F.FIGHT),
			C.t(1.15, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
