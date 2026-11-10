extends RefCounted
## Kan soyu tarzı — Bakuton (Patlama Salınımı, Gari / Iwa Patlama Birliği). YAKIN. Görseller oyunun gerçek Bakuton sistemi:
## VFX.clay_blast (beyaz parlama + gri duman, ateş topu değil), PathJutsu._bakuha_burst (patlamadan saçılan beyaz kıvılcım),
## VFX.element_core avuçta patlayıcı chakra. Kanon (Narutopedia "Gari"): chakrası değdiği yerde patlar — Jiraiken (mayın
## yumruğu) dokunduğu an patlar; avucunu yere vurunca zemin patlar; rakibe yapışan chakra sonradan patlar.
## 1 Jiraiken sağ yumruk (temasta patlar), 2 sol kroşe, 3 avuç yere: zemin boyunca hedefe koşan patlama zinciri,
## 4 avuç değer: hedefe patlayıcı chakra yapışır, kısa süre sonra patlar, 5 iki avuç birden (Shōgeki: geri savurur),
## 6 bitiriş: Jiraiken atılışı — sıçrayıp tam güçle yumruk, büyük patlama (kendi de geri savrulur).

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const L_HOOK := {"LeftUpperArm": Vector3(0.45, 0.15, 0.88), "LeftLowerArm": Vector3(-0.85, 0.1, 0.5)}


static func steps() -> Array:
	return [
		C.step(0.45, 0.2, C.R_COCK, C.L_GUARD, C.R_PUNCH, C.L_GUARD, F.SHIFT, F.PIVOT, -24.0, 22.0, 0.4, 14.0),
		C.step(0.5, 0.22, C.R_GUARD, C.L_COCK, C.R_GUARD, L_HOOK, F.FIGHT, F.PIVOT_L, 30.0, -34.0, 0.42, 12.0),
		C.step(0.65, 0.32, C.R_HIGH, C.L_GUARD, C.R_GROUND, C.L_GUARD, F.SHIFT, F.LOW, -10.0, 6.0, 0.62, 30.0),
		C.step(0.5, 0.22, C.R_COCK, C.L_GUARD, C.R_PALM, C.L_GUARD, F.SHIFT, F.STEPIN, -18.0, 14.0, 0.42, 14.0),
		C.step(0.65, 0.32, C.R_SEAL, C.L_SEAL, C.R_PALM, C.L_PALM, F.SHIFT, F.STEPIN, 0.0, 0.0, 0.45, 18.0),
		{"len": 1.1, "hit": 0.6, "keys": [   # 6 Jiraiken: çömel -> sıçra (kol geride) -> tam güç yumruk
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.22, 0.62, -20, 10, C.R_COCK, C.L_GUARD, F.LOW),
			C.t(0.45, 0.3, -30, -8, C.R_COCK, C.L_PUNCH, F.HOP),
			C.t(0.6, 0.45, 24, 24, C.R_PUNCH, C.L_BACK, F.PIVOT),
			C.t(0.85, 0.45, 20, 18, C.R_PUNCH, C.L_BACK, F.PIVOT),
			C.t(1.1, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
