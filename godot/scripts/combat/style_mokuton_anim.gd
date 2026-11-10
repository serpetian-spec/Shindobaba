extends RefCounted
## Kan soyu / nakil tarzı — Mokuton (Ağaç Salınımı, Yamato). ORTA (kontrol). Senju tarzından ayrı: Senju kanının yumruğu yok,
## Yamato'nun yakalayıp hapseden Mokuton'u. Görseller oyunun gerçek Mokuton sistemi: PathJutsu._wood_trunk (kabuklu kıvrık
## gövde tabandan büyür), _branch (kazık), _wood_wrap (sarılan kökler), bark_toon. Kanon (Narutopedia "Yamato"): kolu ağaca
## dönüp uzanır ve rakibi yakalar, avuçtan kazık atar (Mokuton: Kui), dört sütunlu kafes (Shichūrō), çevresinde ahşap kubbe
## (Mokujōheki), kolundan öne fışkıran ağaç kütlesi (Daijurin no Jutsu).
## 1 avuçtan iki kazık (yavaşlatır), 2 kol ağaca dönüp uzanır, yakalayıp çeker, 3 ön koldan dal saplaması (yakın),
## 4 Shichūrō: avuçlar yere, hedefin çevresinden sütunlar fışkırıp kafesler, 5 Mokujōheki: mühür, çevreden kavisli ahşap duvar
## yaklaşanı iter, 6 bitiriş Daijurin: sağ kol öne, koldan fışkıran ağaç kütlesi önündeki her şeyi süpürür.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const L_BRACE := {"LeftUpperArm": Vector3(0.1, -0.4, 0.9), "LeftLowerArm": Vector3(-0.6, 0.3, 0.74)}
const R_TORA := {"RightUpperArm": Vector3(-0.2, -0.6, 0.77), "RightLowerArm": Vector3(0.6, 0.6, 0.53)}   # mühür (iki el yüz önünde)
const L_TORA := {"LeftUpperArm": Vector3(0.2, -0.6, 0.77), "LeftLowerArm": Vector3(-0.6, 0.6, 0.53)}


static func steps() -> Array:
	return [
		C.step(0.55, 0.26, C.R_COCK, C.L_GUARD, C.R_PALM, C.L_GUARD, F.SHIFT, F.PIVOT, -20.0, 14.0, 0.42, 10.0),
		C.step(0.75, 0.32, C.R_COCK, C.L_GUARD, C.R_REACH, L_BRACE, F.SHIFT, F.STEPIN, -12.0, 6.0, 0.42, 14.0),
		C.step(0.5, 0.22, C.R_GUARD, C.L_COCK, C.R_GUARD, C.L_PUNCH, F.FIGHT, F.PIVOT_L, 22.0, -20.0, 0.42, 12.0),
		C.step(0.8, 0.4, R_TORA, L_TORA, C.R_GROUND, C.L_GROUND, F.FIGHT, F.LOW, 0.0, 0.0, 0.6, 28.0),
		C.step(0.7, 0.34, C.R_GUARD, C.L_GUARD, R_TORA, L_TORA, F.FIGHT, F.LOW, 0.0, 0.0, 0.55, 6.0),
		{"len": 1.25, "hit": 0.6, "keys": [   # 6 Daijurin: kol geri -> sol el bileği tutar, sağ kol öne kilitlenir (ağaç kütlesi koldan)
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.26, 0.48, -24, -8, C.R_COCK, C.L_GUARD, F.SHIFT),
			C.t(0.46, 0.5, -26, -10, C.R_COCK, C.L_GUARD, F.SHIFT),
			C.t(0.6, 0.48, 8, 16, C.R_REACH, L_BRACE, F.STEPIN),
			C.t(1.0, 0.48, 6, 14, C.R_REACH, L_BRACE, F.STEPIN),
			C.t(1.25, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
