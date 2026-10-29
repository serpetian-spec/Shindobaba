class_name OutfitParts
extends RefCounted
## Genişletilmiş kıyafet parçaları (CharacterModel'e kancayla bağlanır):
## dış giysiler (örgüt pelerini, panço, yırtık pelerin, jinbaori, keşiş cübbesi, kesa, hasır yağmurluk, uzun haori),
## bol paça, gi kuşağı, başlıklar (hachimaki, haydut bandanası, sarık, jingasa, kabuto, tengai), yüz (mempo, göz bandı,
## peçe, yeni ANBU hayvanları), omuz/diz zırhı, sırt eşyaları (tespih, sepet, bel parşömenleri, sashimono bayrağı...), çizme.

const OUTER_SLEEVES := ["palto", "haori", "org_pelerin", "cuppe", "haori_uzun", "mino"]
const FOOT_KIND := {"sandal": 0, "zori": 0, "tabi": 1, "cizme": 2, "yuksek_sandal": 3, "bilek_bot": 4, "diz_cizme": 5, "sargili_bot": 6, "zirhli_tozluk": 7}


## Etek ucu yüksekliği (desen bandı için): dış giysinin bittiği dinlenme pozu y
static func _hem(m: CharacterModel) -> float:
	var knee = m._bp("LeftLowerLeg").y; var hips = m._bp("Hips").y; var ank = m._bp("LeftFoot").y; var chest = m._bp("UpperChest").y
	return {"palto": knee + 0.02, "pelerin": knee - 0.06, "haori": hips - 0.16, "kisa": chest - 0.3, "org_pelerin": ank + 0.12,
		"panco": hips - 0.04, "yirtik": knee - 0.12, "jinbaori": knee + 0.08, "cuppe": ank + 0.1, "mino": knee - 0.02,
		"haori_uzun": knee - 0.04, "kesa": hips - 0.05}.get(str(m.look.get("outer_style", "")), knee)


## Kumaş shader'ına yeni parametreler
static func mat_params(m: CharacterModel, mat: ShaderMaterial) -> void:
	var L = m.look
	mat.set_shader_parameter("wear", float(L.get("wear", 0.0)))
	mat.set_shader_parameter("foot_kind", int(FOOT_KIND.get(str(L.get("foot_style", "sandal")), 0)))
	mat.set_shader_parameter("foot_pattern", int(L.get("foot_pattern", 0)))
	mat.set_shader_parameter("outer_pattern", int(L.get("outer_pattern", 0)))
	var acc = L.get("outer_accent")
	mat.set_shader_parameter("outer_accent", Color(acc) if acc != null else Color(0.75, 0.12, 0.12))
	mat.set_shader_parameter("outer_hem", _hem(m))
	if L.get("outer_style") in OUTER_SLEEVES:
		mat.set_shader_parameter("outer_sleeves", 1)


## Ek giysi katmanları (loft): CharacterModel._garments sonunda çağrılır
static func garments(m: CharacterModel, g: Dictionary) -> void:
	var neck = m._bp("Neck").y; var hips = m._bp("Hips").y; var knee = m._bp("LeftLowerLeg").y; var ank = m._bp("LeftFoot").y
	var ua = m._bp("LeftUpperArm").x
	var ey = m.eye_center_model.y if m.face_mi else neck + 0.17
	var torso = func(p: Vector3) -> bool: return absf(p.x) < (ua * 0.95 if p.y > neck - 0.33 else 0.45) and p.y < neck + 0.06
	var neck_f = func(p: Vector3) -> bool: return p.y > neck - 0.1 and absf(p.x) < 0.15
	var front = func(ang: float) -> float: return absf(wrapf(ang - PI * 0.5, -PI, PI))
	m._outer_pad = 0.02 if m.look.get("vest") != null and m.look.get("outer_style") != null else 0.0   # yeleğin üstüne
	match m.look.get("outer_style"):
		"org_pelerin":
			# ayak bileğine inen kapalı örgüt pelerini + dik yüksek yaka
			m._garment("org_pelerin", func(): return m._loft(g, 1, neck - 0.01, ank + 0.12, 26, torso, func(t, _a): return 0.055 + t * 0.13, 8,
				func(t, ang): return t > 0.55 and front.call(ang) < 0.12, hips - 0.06))
			m._garment("org_yaka", func(): return m._loft(g, 1, neck - 0.03, ey - 0.035, 6, neck_f, func(t, _a): return 0.05 + t * 0.035, 8,
				func(t, ang): return t > 0.45 and front.call(ang) < 0.32))
		"panco":
			# omuzlardan dökülen, eteği saçaklı panço
			m._garment("panco", func(): return m._loft(g, 1, neck + 0.01, hips - 0.06, 16, torso, func(t, _a): return 0.05 + sqrt(t) * 0.15, 8,
				func(t, ang): return t > 0.9 and fposmod(ang * 2.5, 1.0) < 0.35, hips - 0.02, 32))
		"yirtik":
			# yırtık, saçakları sivri gezgin pelerini; yer yer delikli
			m._garment("yirtik", func(): return m._loft(g, 1, neck + 0.02, knee - 0.12, 22, torso, func(t, _a): return 0.06 + t * 0.1, 8,
				func(t, ang): return t > 0.74 + 0.24 * absf(sin(ang * 5.5 + 0.7)) or (t > 0.42 and t < 0.5 and absf(wrapf(ang + 0.6, -PI, PI)) < 0.25), hips - 0.06))
		"jinbaori":
			m._garment("jinbaori", func(): return m._loft(g, 1, neck - 0.03, knee + 0.08, 18, torso, func(t, _a): return 0.05 + t * 0.07, 8,
				func(t, ang): return front.call(ang) < 0.32 or (t > 0.55 and absf(cos(ang)) > 0.93), hips - 0.06))
		"cuppe":
			m._garment("cuppe", func(): return m._loft(g, 1, neck - 0.01, ank + 0.1, 24, torso, func(t, _a): return 0.045 + t * 0.11, 8, null, hips - 0.06))
		"haori_uzun":
			m._garment("haori_uzun", func(): return m._loft(g, 1, neck - 0.01, knee - 0.04, 20, torso, func(t, _a): return 0.045 + t * 0.08, 8,
				func(t, ang): return t > 0.04 and front.call(ang) < 0.24, hips - 0.06))
		"mino":
			m._garment("mino", func(): return m._loft(g, 1, neck + 0.02, knee - 0.02, 18, torso, func(t, _a): return 0.07 + t * 0.15, 8, null, hips - 0.06))
		"kesa":
			# tek omuzdan kalçaya çapraz inen keşiş örtüsü
			m._garment("kesa", func(): return m._loft(g, 1, neck - 0.02, hips - 0.08, 30, torso, func(_t, _a): return 0.035, 8,
				func(t, ang): return absf(cos(ang) - (0.9 - 1.8 * t)) > 0.42, -99.0, 48))
	m._outer_pad = 0.0
	if m.top_style() == "gi":
		# siyah kuşak (koyu yuva)
		m._garment("gi_kusak", func(): return m._loft(g, 1, hips + 0.03, hips + 0.1, 4, torso, func(_t, _a): return 0.032, 7))
	if m.look.get("rope_belt", false):
		m._garment("ip_kusak", func(): return m._loft(g, 1, hips + 0.05, hips + 0.1, 4, torso, func(_t, _a): return 0.04, 9))
	if m.pants_style() == "bol":
		for sx in [-1.0, 1.0]:
			m._garment("bol%d" % int(sx), func(): return m._loft(g, 1, knee + 0.1, ank + 0.035, 10, func(p): return signf(p.x) == sx and absf(p.x) < 0.35,
				# iç tarafta şişkinlik az: öbür bacağa değip ona bağlanmasın
				func(t, a): return 0.012 + sin(t * PI * 0.92) * (0.038 if cos(a) * sx > -0.2 else 0.008), 3, null, -99.0, 18))
	var gd = m.look.get("guards")
	if gd in ["dizlik", "agir"]:
		for sx in [-1.0, 1.0]:
			m._garment("dizlik%d" % int(sx), func(): return m._loft(g, 1, knee + 0.05, knee - 0.06, 5, func(p): return signf(p.x) == sx and absf(p.x) < 0.35,
				func(_t, ang): return 0.028 if front.call(ang) < 1.1 else 0.012, 9, null, -99.0, 16))


## Sert aksesuarlar: CharacterModel._accessories sonunda çağrılır
static func accessories(m: CharacterModel) -> void:
	var hc = m._head_center()
	var ab = m.head_ab
	var hw = clampf(ab.size.x, 0.16, 0.26) if ab.size.x > 0.05 else 0.2
	var hd = clampf(ab.size.z, 0.17, 0.28) if ab.size.z > 0.05 else 0.22
	var hh = clampf(ab.size.y, 0.12, 0.26) if ab.size.y > 0.05 else 0.2
	var htop = hc.y + hh * 0.42
	var ch = m._bp("UpperChest")
	var hip = m._bp("Hips")
	var L = m.look
	var steel = Color(0.62, 0.65, 0.7)
	var dark = Color(0.12, 0.12, 0.14)
	var gold = Color(0.85, 0.68, 0.25)
	var hg: Color = L.get("headgear") if L.get("headgear") != null else Color(0.5, 0.4, 0.3)
	var toon = Props.toon()
	# başı tamamen saran başlıklar: saç içinden taşmasın
	if L.get("head_style") in ["kabuto", "tengai", "sarik", "kapuson"]:
		var clumps = CharacterModel._hair_cache.values()
		for mi in m.skel.find_children("*", "MeshInstance3D", true, false):
			if mi.name == "VHair" or (mi.mesh != null and mi.mesh in clumps):
				mi.visible = false
	match L.get("head_style"):
		"hachimaki":
			var mb = MB.new()
			mb.add("cyl", Vector3.ZERO, Vector3(hw * 1.16, 0.04, hd * 1.1), hg, Vector3(5, 0, 0), 20)
			mb.add("box", Vector3(0.0, -0.005, -hd * 0.56), Vector3(0.035, 0.035, 0.03), hg.darkened(0.15))
			for sx in [-1.0, 1.0]:
				mb.add("box", Vector3(0.03 * sx, -0.08, -hd * 0.6), Vector3(0.035, 0.16, 0.006), hg, Vector3(-18, 0, 14 * sx))
			m._mesh_on("Head", mb.build(toon), Transform3D(Basis.IDENTITY, Vector3(hc.x, hc.y + 0.035, hc.z)))
		"basortu":
			var mb = MB.new()
			mb.add("hemi", Vector3.ZERO, Vector3(hw * 1.18, hh * 0.85, hd * 1.14), hg, Vector3(-8, 0, 0), 16)
			mb.add("sphere", Vector3(0, -0.02, -hd * 0.58), Vector3(0.05, 0.045, 0.04), hg.darkened(0.12), Vector3.ZERO, 8)
			for sx in [-1.0, 1.0]:
				mb.add("box", Vector3(0.025 * sx, -0.09, -hd * 0.62), Vector3(0.04, 0.13, 0.008), hg, Vector3(-22, 0, 20 * sx))
			m._mesh_on("Head", mb.build(toon), Transform3D(Basis.IDENTITY, Vector3(hc.x, hc.y - 0.0, hc.z)))
		"sarik":
			var mb = MB.new()
			mb.add("hemi", Vector3(0, 0.0, 0), Vector3(hw * 1.24, hh * 0.95, hd * 1.18), hg, Vector3.ZERO, 16)
			for k in 3:
				mb.add("cyl", Vector3(0, -0.01 + k * 0.035, 0), Vector3(hw * (1.27 - k * 0.07), 0.035, hd * (1.2 - k * 0.07)), hg.darkened(0.06 * k), Vector3(0, 0, 6 - k * 5), 18)
			mb.add("box", Vector3(-0.06, -0.18, -hd * 0.5), Vector3(0.09, 0.3, 0.012), hg.darkened(0.1), Vector3(-12, 0, -8))
			m._mesh_on("Head", mb.build(toon), Transform3D(Basis.IDENTITY, Vector3(hc.x, hc.y + 0.01, hc.z)))
		"jingasa":
			var mb = MB.new()
			mb.add("cone", Vector3.ZERO, Vector3(hw * 2.5, 0.1, hw * 2.5), hg, Vector3.ZERO, 20)
			mb.add("cyl", Vector3(0, -0.05, 0), Vector3(hw * 2.52, 0.012, hw * 2.52), hg.darkened(0.3), Vector3.ZERO, 20)
			mb.add("cyl", Vector3(0, 0.0, hw * 0.62), Vector3(0.06, 0.006, 0.06), gold, Vector3(70, 0, 0), 12)
			for sx in [-1.0, 1.0]:
				mb.add("box", Vector3(hw * 0.5 * sx, -0.14, 0.02), Vector3(0.008, 0.2, 0.008), dark, Vector3(0, 0, -8 * sx))
			m._mesh_on("Head", mb.build(toon), Transform3D(Basis.IDENTITY, Vector3(hc.x, htop + 0.0, hc.z)))
		"kabuto":
			var mb = MB.new()
			mb.add("hemi", Vector3.ZERO, Vector3(hw * 1.3, hh * 0.95, hd * 1.25), hg, Vector3.ZERO, 16)
			# boyun koruması (shikoro): arkaya ve yanlara açılan katmanlar
			for k in 3:
				mb.add("cone", Vector3(0, -0.02 - k * 0.035, -0.015), Vector3(hw * (1.55 + k * 0.18), 0.05, hd * (1.5 + k * 0.16)), hg.darkened(0.12 + k * 0.06), Vector3.ZERO, 16)
			mb.add("box", Vector3(0, -0.015, hd * 0.62), Vector3(hw * 1.15, 0.025, 0.07), hg.darkened(0.25), Vector3(-15, 0, 0))
			# kuwagata: V boynuz arması
			for sx in [-1.0, 1.0]:
				mb.add("box", Vector3(0.045 * sx, 0.12, hd * 0.6), Vector3(0.018, 0.2, 0.008), gold, Vector3(-10, 0, -24 * sx))
			mb.add("sphere", Vector3(0, 0.03, hd * 0.63), Vector3(0.04, 0.04, 0.015), gold, Vector3.ZERO, 8)
			m._mesh_on("Head", mb.build(toon), Transform3D(Basis.IDENTITY, Vector3(hc.x, hc.y + 0.04, hc.z)))
		"tengai":
			# keşişlerin yüzü örten derin hasır sepet şapkası
			var mb = MB.new()
			var r = hw * 1.55
			mb.add("cyl", Vector3(0, -0.06, 0), Vector3(r, 0.3, r * 1.04), hg, Vector3.ZERO, 18)
			mb.add("cone", Vector3(0, 0.12, 0), Vector3(r * 0.98, 0.07, r), hg.darkened(0.08), Vector3.ZERO, 18)
			for k in 5:
				mb.add("cyl", Vector3(0, -0.19 + k * 0.06, 0), Vector3(r + 0.006, 0.008, r * 1.04 + 0.006), hg.darkened(0.25), Vector3.ZERO, 18)
			mb.add("box", Vector3(0, -0.03, r * 0.52), Vector3(0.09, 0.03, 0.01), dark)
			m._mesh_on("Head", mb.build(toon), Transform3D(Basis.IDENTITY, Vector3(hc.x, hc.y + 0.02, hc.z)))
	# kapüşon: kafayı saran sert kabuk + enseye dökülen etek (VRoid gövdesinde kafa köşesi yok, loft kafayı saramıyor)
	if L.get("head_style") == "kapuson":
		var mb = MB.new()
		mb.add("sphere", Vector3(0, 0.0, -0.015), Vector3(hw * 1.36, hh * 1.32, hd * 1.32), hg, Vector3.ZERO, 16)
		mb.add("cone", Vector3(0, -0.13, -hd * 0.42), Vector3(hw * 1.5, 0.2, hd * 0.9), hg.darkened(0.08), Vector3(-12, 0, 0), 12)
		mb.add("cyl", Vector3(0, -0.02, hd * 0.42), Vector3(hw * 1.15, 0.03, 0.05), hg.darkened(0.2), Vector3(70, 0, 0), 14)
		m._mesh_on("Head", mb.build(toon), Transform3D(Basis.IDENTITY, Vector3(hc.x, hc.y + 0.02, hc.z)))
	var fg: Color = L.get("facegear") if L.get("facegear") != null else Color.WHITE
	var fs = String(L.get("face_style", "")) if L.get("face_style") != null else ""
	if fs in ["cloth", "pece"]:
		# bez maske / peçe: burundan çeneye sarılan kumaş + boyun
		var mb = MB.new()
		var ey = m.eye_center_model.y if m.face_mi else hc.y - 0.03
		mb.add("cyl", Vector3(0, ey - 0.07 - hc.y, 0.012), Vector3(hw * 1.06, 0.075, hd * 1.02), fg, Vector3(-6, 0, 0), 20)
		mb.add("cyl", Vector3(0, ey - 0.13 - hc.y, -0.005), Vector3(hw * 0.86, 0.07, hd * 0.86), fg.darkened(0.1), Vector3.ZERO, 18)
		if fs == "pece":
			mb.add("box", Vector3(0, ey - 0.15 - hc.y, hd * 0.47), Vector3(hw * 0.8, 0.12, 0.012), fg, Vector3(8, 0, 0))
		m._mesh_on("Head", mb.build(toon), Transform3D(Basis.IDENTITY, hc))
	match fs:
		"mempo":
			var mb = MB.new()
			mb.add("hemi", Vector3(0, 0, 0), Vector3(0.15, 0.1, 0.11), fg, Vector3(90, 0, 0), 12)
			mb.add("box", Vector3(0, 0.03, 0.055), Vector3(0.025, 0.04, 0.025), fg.darkened(0.15), Vector3(-20, 0, 0))
			for k in 3:
				mb.add("box", Vector3(0, -0.045 - k * 0.022, 0.0), Vector3(0.13 - k * 0.012, 0.016, 0.1), fg.darkened(0.1 + k * 0.08))
			for sx in [-1.0, 1.0]:
				mb.add("box", Vector3(0.035 * sx, -0.005, 0.05), Vector3(0.03, 0.004, 0.004), Color(0.95, 0.95, 0.9), Vector3(0, 0, 18 * sx))
			m._mesh_on("Head", mb.build(toon), Transform3D(Basis.IDENTITY, hc + Vector3(0, -0.105, 0.075)))
		"goz_bandi":
			var mb = MB.new()
			mb.add("cyl", Vector3.ZERO, Vector3(hw * 1.13, 0.012, hd * 1.07), dark, Vector3(-12, 0, 8), 20)
			mb.add("sphere", Vector3(0.034, -0.005, hd * 0.53), Vector3(0.045, 0.04, 0.012), dark, Vector3.ZERO, 10)
			var gy = m.eye_center_model.y if m.face_mi else hc.y + 0.03
			m._mesh_on("Head", mb.build(toon), Transform3D(Basis.IDENTITY, Vector3(hc.x, gy, hc.z)))
		"anbu_tilki", "anbu_kaplan", "anbu_yilan", "anbu_maymun":
			var mb = MB.new()
			var red = Color(0.75, 0.1, 0.12)
			match fs:
				"anbu_tilki":
					mb.add("cone", Vector3(0, -0.03, 0.105), Vector3(0.065, 0.09, 0.045), fg, Vector3(-80, 0, 0), 6)   # burun öne bakar (ters takılıyordu: sivri uç ense tarafına dönüktü)
					for sx in [-1.0, 1.0]:
						mb.add("cone", Vector3(0.065 * sx, 0.12, -0.01), Vector3(0.05, 0.09, 0.03), fg, Vector3(0, 0, -22 * sx), 4)
						mb.add("box", Vector3(0.05 * sx, 0.04, 0.045), Vector3(0.006, 0.05, 0.004), red, Vector3(0, 0, 35 * sx))
						mb.add("box", Vector3(0.06 * sx, -0.02, 0.04), Vector3(0.04, 0.006, 0.004), red, Vector3(0, 0, -10 * sx))
				"anbu_kaplan":
					for sx in [-1.0, 1.0]:
						mb.add("sphere", Vector3(0.07 * sx, 0.11, -0.005), Vector3(0.045, 0.045, 0.02), fg, Vector3.ZERO, 8)
						for k in 3:
							mb.add("box", Vector3((0.035 + k * 0.022) * sx, 0.075 - k * 0.012, 0.042), Vector3(0.006, 0.035, 0.004), dark, Vector3(0, 0, (14 + k * 8) * sx))
					mb.add("box", Vector3(0, 0.085, 0.045), Vector3(0.006, 0.04, 0.004), dark)
				"anbu_yilan":
					mb.add("box", Vector3(0, 0.0, 0.05), Vector3(0.006, 0.17, 0.004), Color(0.3, 0.55, 0.3))
					for sx in [-1.0, 1.0]:
						mb.add("box", Vector3(0.05 * sx, -0.045, 0.042), Vector3(0.04, 0.006, 0.004), Color(0.45, 0.2, 0.55), Vector3(0, 0, 25 * sx))
				"anbu_maymun":
					for sx in [-1.0, 1.0]:
						mb.add("sphere", Vector3(0.095 * sx, 0.0, -0.01), Vector3(0.04, 0.06, 0.025), fg, Vector3.ZERO, 8)
					mb.add("sphere", Vector3(0, -0.05, 0.05), Vector3(0.08, 0.05, 0.03), Color(0.92, 0.75, 0.65), Vector3.ZERO, 8)
					mb.add("box", Vector3(0, 0.075, 0.045), Vector3(0.09, 0.012, 0.004), red)
			m._mesh_on("Head", mb.build(toon), Transform3D(Basis.IDENTITY, hc + Vector3(0, -0.03, 0.085)))
		_:
			if fs != "":
				FaceItemsExt.build(m, fs, fg, hc, hw, hh, hd, toon)
	# --- omuz zırhı
	var gd = L.get("guards")
	var ac: Color = L.get("acc") if L.get("acc") != null else steel
	if gd in ["omuz", "agir"]:
		var sides = [1.0] if gd == "omuz" else [-1.0, 1.0]
		for sx in sides:
			var mb = MB.new()
			for k in 3:
				mb.add("hemi", Vector3(0.0, -k * 0.03, 0.0), Vector3(0.15 - k * 0.012, 0.07, 0.16 - k * 0.01), ac.darkened(k * 0.08), Vector3(0, 0, -28 * sx), 10)
			mb.add("box", Vector3(-0.17 * sx, -0.12, 0.0), Vector3(0.03, 0.42, 0.012), Color(0.3, 0.22, 0.15), Vector3(0, 0, 38 * sx))
			m._mesh_on("UpperChest", mb.build(toon), Transform3D(Basis.IDENTITY, ch + Vector3(0.2 * sx, 0.1, 0.0)))
	# --- sırt / bel ek eşyaları
	var bc: Color = L.get("backc") if L.get("backc") != null else Color(0.4, 0.33, 0.22)
	match L.get("back_item"):
		"tespih":
			var mb = MB.new()
			var n = 22
			for k in n:
				var a = TAU * k / n
				var big = k == 0
				mb.add("sphere", Vector3(sin(a) * 0.15, 0.06 + (0.11 if cos(a) > 0.0 else 0.0) * cos(a) - (0.05 if big else 0.0), cos(a) * 0.13 + 0.01),
					Vector3.ONE * (0.05 if big else 0.032), bc if not big else bc.lightened(0.2), Vector3.ZERO, 6)
			m._mesh_on("UpperChest", mb.build(toon), Transform3D(Basis.IDENTITY, ch + Vector3(0, -0.02, 0.0)))
		"sepet":
			var mb = MB.new()
			mb.add("frustum", Vector3(0, 0, 0), Vector3(0.36, 0.46, 0.26), bc, Vector3(180, 0, 0), 12)
			for k in 4:
				mb.add("cyl", Vector3(0, -0.18 + k * 0.11, 0), Vector3(0.34 - k * 0.03, 0.012, 0.25 - k * 0.02), bc.darkened(0.3), Vector3.ZERO, 12)
			mb.add("box", Vector3(0, 0.26, 0.0), Vector3(0.3, 0.05, 0.2), Color(0.55, 0.45, 0.3))
			m._mesh_on("UpperChest", mb.build(toon), Transform3D(Basis.IDENTITY, ch + Vector3(0, -0.12, -0.26)))
		"bel_parsomen":
			var mb = MB.new()
			# belin arkasında çapraz asılı iki parşömen
			for sx in [-1.0, 1.0]:
				mb.add("cyl", Vector3(0.1 * sx, 0.0, 0.0), Vector3(0.07, 0.26, 0.07), bc, Vector3(0, 0, 62 * sx), 10)
				mb.add("cyl", Vector3(0.1 * sx, 0.0, 0.0), Vector3(0.08, 0.035, 0.08), Color(0.6, 0.15, 0.12), Vector3(0, 0, 62 * sx), 10)
			m._mesh_on("Hips", mb.build(toon), Transform3D(Basis.IDENTITY, hip + Vector3(0, 0.04, -0.15)))
		"kemer_canta":
			var mb = MB.new()
			mb.add("box", Vector3(0.18, 0.0, 0.0), Vector3(0.09, 0.11, 0.08), bc)
			mb.add("box", Vector3(0.18, 0.04, 0.0), Vector3(0.095, 0.03, 0.085), bc.darkened(0.2))
			mb.add("box", Vector3(0.0, 0.0, -0.13), Vector3(0.2, 0.1, 0.07), bc)
			mb.add("cyl", Vector3(-0.17, -0.06, 0.02), Vector3(0.04, 0.2, 0.04), Color(0.55, 0.57, 0.6), Vector3(0, 0, -15), 6)
			m._mesh_on("Hips", mb.build(toon), Transform3D(Basis.IDENTITY, hip + Vector3(0, 0.06, 0)))
		"sashimono":
			# samuray sırt bayrağı: direk + dikey sancak
			var mb = MB.new()
			mb.add("cyl", Vector3(0, 0.45, 0), Vector3(0.025, 1.3, 0.025), Color(0.25, 0.18, 0.12), Vector3.ZERO, 6)
			mb.add("box", Vector3(0.11, 0.7, 0), Vector3(0.22, 0.7, 0.006), bc)
			mb.add("box", Vector3(0.11, 0.98, 0), Vector3(0.24, 0.025, 0.012), Color(0.25, 0.18, 0.12))
			mb.add("sphere", Vector3(0.11, 0.72, 0.004), Vector3(0.12, 0.12, 0.004), Color(0.95, 0.94, 0.9), Vector3.ZERO, 12)
			m._mesh_on("UpperChest", mb.build(toon), Transform3D(Basis.IDENTITY, ch + Vector3(0, -0.2, -0.2)))
		"ip_kangal":
			var mb = MB.new()
			for k in 3:
				mb.add("torus", Vector3(0, k * 0.012, 0), Vector3(0.2 - k * 0.012, 0.2, 0.2 - k * 0.012), bc.darkened(k * 0.08), Vector3(90, 0, 0), 14)
			m._mesh_on("Hips", mb.build(toon), Transform3D(Basis.IDENTITY, hip + Vector3(0.21, -0.02, 0.0)))
		_:
			if L.get("back_item") != null:
				BackItemsExt.build(m, String(L.get("back_item")), bc, ch, hip, toon)
	# --- örgüt pelerini: yakada küçük metal halka tokalar
	if L.get("outer_style") == "org_pelerin":
		var acc2 = L.get("outer_accent")
		var oc: Color = Color(acc2) if acc2 != null else Color(0.75, 0.12, 0.12)
		var mb = MB.new()
		for k in 3:
			mb.add("box", Vector3(0, -0.05 - k * 0.09, 0.0), Vector3(0.03, 0.03, 0.01), oc.lightened(0.15))
		m._mesh_on("UpperChest", mb.build(toon), Transform3D(Basis.IDENTITY, ch + Vector3(0, 0.12, 0.19)))


## Sandalet halkaları yerine ayakkabı türüne göre halka tanımı (null = varsayılan)
static func foot_rings(foot_style: String, fp: Vector3):
	match foot_style:
		"cizme":
			return [[1, fp.y + 0.215, 0.007, 0.012, 99.0], [1, fp.y + 0.02, 0.005, 0.008, 99.0]]
		"yuksek_sandal":
			return [[2, fp.z + 0.13, 0.004, 0.007, 0.075], [2, fp.z + 0.06, 0.004, 0.008, 0.11], [1, fp.y + 0.02, 0.006, 0.008, 99.0]]
		"bilek_bot":
			return [[1, fp.y + 0.09, 0.006, 0.01, 99.0], [1, fp.y + 0.02, 0.005, 0.008, 99.0]]
		"diz_cizme", "zirhli_tozluk":
			return [[1, fp.y + 0.36, 0.008, 0.013, 99.0], [1, fp.y + 0.18, 0.005, 0.009, 99.0], [1, fp.y + 0.02, 0.005, 0.008, 99.0]]
		"sargili_bot":
			return [[1, fp.y + 0.12, 0.006, 0.01, 99.0], [1, fp.y + 0.02, 0.005, 0.008, 99.0]]
	return null
