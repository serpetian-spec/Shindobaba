extends RefCounted
## Yol tarzı — Silah Ustası (Tenten). ORTA-UZAK. Görseller oyunun gerçek sistemleri: elde açılan parşömen (PathJutsu.hold_scroll),
## parşömenden fırlayan silahlar (PathJutsu.throw_weapon + weapon_mesh: kunai/fuma/kama/katana/sai/ono/kusari/chakram/yari),
## Tesso pençesi zinciri, Sōshōryū iki parşömenden yükselen silah yağmuru, dev demir topuz (cached "tetsuzan").
## Kanon: Tenten parşömeni açıp mühürden mühüre silah çağırır, telle geri çeker, iki parşömenle ejder gibi yükselip yağdırır.
## 1-2 parşömenden kunai / shuriken salvosu, 3 kusarigama zinciri çekişi, 4 havadan silah yağmuru (Sōshōryū küçük),
## 5 dev balta + kılıç ikilisi (ağır), 6 bitiriş: dev demir topuz gökten iner.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")
const L_SCROLL := {"LeftUpperArm": Vector3(0.2, -0.6, 0.77), "LeftLowerArm": Vector3(-0.7, 0.1, 0.71)}


static func steps() -> Array:
	return [
		C.step(0.5, 0.24, C.R_THROW_BACK, L_SCROLL, C.R_THROW, L_SCROLL, F.SHIFT, F.PIVOT, -22.0, 16.0, 0.38, 6.0),
		C.step(0.5, 0.24, C.R_THROW_BACK, L_SCROLL, C.R_SWEEP_OUT, L_SCROLL, F.FIGHT, F.PIVOT, -10.0, 30.0, 0.38, 6.0),
		C.step(0.65, 0.3, C.R_THROW_BACK, C.L_GUARD, C.R_THROW, C.L_BACK, F.SHIFT, F.STEPIN, -20.0, 10.0, 0.4, 10.0),
		{"len": 0.85, "hit": 0.46, "keys": [
			C.t(0.0, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.22, 0.3, 0, -10, C.R_SKY, C.L_SKY, F.HOP),
			C.t(0.46, 0.3, 0, -12, C.R_SKY, C.L_SKY, F.HOP),
			C.t(0.6, 0.38, 0, 8, C.R_DOWN, C.L_GUARD, F.FIGHT),
			C.t(0.85, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
		C.step(0.7, 0.34, C.R_HIGH, C.L_GUARD, C.R_DOWN, C.L_BACK, F.SHIFT, F.STEPIN, 0.0, 0.0, 0.45, 24.0),
		{"len": 1.15, "hit": 0.72, "keys": [
			C.t(0.0, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.25, 0.5, 0, 12, C.R_SEAL, C.L_SEAL, F.LOW),
			C.t(0.55, 0.62, 0, 26, C.R_GROUND, C.L_GROUND, F.LOW),
			C.t(0.95, 0.58, 0, 22, C.R_GROUND, C.L_GROUND, F.LOW),
			C.t(1.15, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
