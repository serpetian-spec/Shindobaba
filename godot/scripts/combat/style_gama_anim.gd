extends RefCounted
## Yol tarzı — Kurbağa Bilgesi (Jiraiya). YAKIN-ORTA. Görseller oyunun gerçek sistemleri: saç iğneleri (kebari), kurbağa yağı
## akışı ve göleti (stream_fx/_oil_pool), ateş seli (fire_stream), küçük savaş kurbağası (SummonModels "toad_small"),
## Rasengan küresi (VFX.rasengan). Kanon: Jiraiya saçını iğneye çevirir, kurbağa yağını ateşle tutuşturur, kurbağa çağırır,
## Ōdama Rasengan.
## 1 saç iğneleri (kısa yağmur), 2 savaş kurbağası hedefe zıplar ezer, 3 Gamayudan: ağızdan kurbağa yağı (kaygan, yavaşlatır),
## 4 Katon: yağ tutuşur (alev seli), 5 saç kalkanı + iğne halkası (Hari Jizō: çevreye), 6 Ōdama Rasengan (bitiriş).

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")


static func steps() -> Array:
	return [
		C.step(0.55, 0.26, C.R_GUARD, C.L_GUARD, C.R_SPREAD, C.L_SPREAD, F.SHIFT, F.FIGHT, 0.0, 0.0, 0.38, -8.0),
		C.step(0.6, 0.3, C.R_SEAL, C.L_SEAL, C.R_GROUND, C.L_GUARD, F.FIGHT, F.LOW, 0.0, 0.0, 0.55, 20.0),
		C.step(0.7, 0.32, C.R_MOUTH, C.L_HIP, C.R_MOUTH, C.L_HIP, F.SHIFT, F.STEPIN, 0.0, 0.0, 0.38, 16.0),
		C.step(0.65, 0.3, C.R_SEAL, C.L_SEAL, C.R_MOUTH, C.L_HIP, F.FIGHT, F.STEPIN, 0.0, 0.0, 0.38, 16.0),
		C.step(0.7, 0.32, C.R_LOW, C.L_LOW, C.R_LOW, C.L_LOW, F.LOW, F.LOW, 0.0, 0.0, 0.7, 30.0),
		{"len": 1.15, "hit": 0.66, "keys": [
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.24, 0.42, -20, 6, C.R_PALM, C.L_PALM, F.SHIFT),
			C.t(0.56, 0.44, -24, 8, C.R_PALM, C.L_PALM, F.SHIFT),
			C.t(0.66, 0.44, 18, 22, C.R_PALM, C.L_GUARD, F.STEPIN),
			C.t(0.92, 0.42, 14, 18, C.R_PALM, C.L_GUARD, F.STEPIN),
			C.t(1.15, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
