extends RefCounted
## Yol tarzı — Sekiz Kuyruk (Killer B). YAKIN-ORTA. Görseller oyunun gerçek sistemleri: Gyūki'nin Takoashi Ude dokunaçları
## (BijuuArts._tako_ude), mürekkep seli (stream_fx + mürekkep mat_water), Raiton örtüsü (PathJutsu._rai_cloak), yedi kılıç
## (p_hachibi_yedi_kilic ile aynı kılıç gövdesi), kuyruklu canavar topu (PathJutsu._bijuball). Kanon: B ritimle dövüşür,
## Lariat'ı Raikage ile aynı (şimşekli kol), kollarının altında/ağzında kılıçlarla döner, ahtapot kolu çıkarır, mürekkep tükürür.
## 1 dokunaç kırbacı, 2 yedi kılıç dönüşü (çevre), 3 mürekkep tükürüğü (kör eder, yavaşlatır), 4 Lariat (şimşekli kol atılışı),
## 5 dokunaçla kavrayıp yere çarpma, 6 bitiriş: Sekiz Kuyruk topu (küçük canavar topu).

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")
const L_LARIAT := {"LeftUpperArm": Vector3(0.98, 0.1, 0.15), "LeftLowerArm": Vector3(0.98, 0.1, 0.15)}   # sol kol yana açık (Lariat)


static func steps() -> Array:
	return [
		C.step(0.55, 0.26, C.R_GUARD, C.L_GUARD, C.R_SWEEP_OUT, C.L_GUARD, F.SHIFT, F.PIVOT, 20.0, -20.0, 0.38, 4.0),
		{"len": 0.75, "hit": 0.32, "keys": [
			C.t(0.0, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.18, 0.45, -60, 4, C.R_SPREAD, C.L_SPREAD, F.LOW),
			C.t(0.32, 0.45, 120, 4, C.R_SPREAD, C.L_SPREAD, F.LOW),
			C.t(0.5, 0.45, 300, 4, C.R_SPREAD, C.L_SPREAD, F.LOW),
			C.t(0.75, 0.38, 360, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
		C.step(0.6, 0.3, C.R_GUARD, C.L_GUARD, C.R_MOUTH, C.L_HIP, F.SHIFT, F.STEPIN, 0.0, 0.0, 0.4, 14.0),
		C.step(0.65, 0.3, C.R_GUARD, C.L_BACK, C.R_GUARD, L_LARIAT, F.SHIFT, F.STEPIN, 30.0, -50.0, 0.4, 18.0),
		C.step(0.65, 0.32, C.R_HIGH, C.L_GUARD, C.R_GROUND, C.L_GUARD, F.FIGHT, F.LOW, 0.0, 0.0, 0.55, 26.0),
		{"len": 1.2, "hit": 0.7, "keys": [
			C.t(0.0, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.3, 0.46, 0, -8, C.R_MOUTH, C.L_SEAL, F.LOW),
			C.t(0.6, 0.48, 0, -10, C.R_MOUTH, C.L_SEAL, F.LOW),
			C.t(0.7, 0.42, 0, 20, C.R_PALM, C.L_PALM, F.STEPIN),
			C.t(0.98, 0.4, 0, 16, C.R_PALM, C.L_PALM, F.STEPIN),
			C.t(1.2, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
