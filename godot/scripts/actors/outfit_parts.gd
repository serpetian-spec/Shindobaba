class_name OutfitParts
extends RefCounted
## Genişletilmiş kıyafet parçaları (CharacterModel'e kancayla bağlanır):
## dış giysiler (örgüt pelerini, panço, yırtık pelerin, jinbaori, keşiş cübbesi, kesa, hasır yağmurluk, uzun haori),
## bol paça, gi kuşağı, başlıklar (hachimaki, haydut bandanası, sarık, jingasa, kabuto, tengai), yüz (mempo, göz bandı,
## peçe, yeni ANBU hayvanları), omuz/diz zırhı, sırt eşyaları (tespih, sepet, bel parşömenleri, sashimono bayrağı...), çizme.

const OUTER_SLEEVES := ["palto", "haori", "org_pelerin", "cuppe", "haori_uzun", "mino", "anbu_palto"]
const FOOT_KIND := {"sandal": 0, "zori": 0, "tabi": 1, "cizme": 2, "yuksek_sandal": 3, "bilek_bot": 4, "diz_cizme": 5, "sargili_bot": 6, "zirhli_tozluk": 7, "shinobi": 8}


## Etek ucu yüksekliği (desen bandı için): dış giysinin bittiği dinlenme pozu y
static func _hem(m: CharacterModel) -> float:
	var knee = m._bp("LeftLowerLeg").y; var hips = m._bp("Hips").y; var ank = m._bp("LeftFoot").y; var chest = m._bp("UpperChest").y
	return {"palto": knee + 0.02, "pelerin": knee - 0.06, "haori": hips - 0.16, "kisa": chest - 0.3, "org_pelerin": ank + 0.12,
		"panco": hips - 0.04, "yirtik": knee - 0.12, "jinbaori": knee + 0.08, "cuppe": ank + 0.1, "mino": knee - 0.02,
		"haori_uzun": knee - 0.04, "kesa": hips - 0.05, "anbu_palto": knee + 0.07, "acik_ceket": hips + 0.035, "kiri_tunik": hips - 0.15, "bulut_etek": knee - 0.03, "kaya_gi": hips - 0.13}.get(str(m.look.get("outer_style", "")), knee)


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
	mat.set_shader_parameter("outer_top", m._bp("Neck").y)
	mat.set_shader_parameter("sleeve_end", absf(m._bp("LeftHand").x) - 0.03)
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
			m._garment("org_pelerin", func(): return m._loft(g, 1, neck - 0.01, ank + 0.14, 26, torso, func(t, _a): return 0.065 + t * 0.16, 8,
				func(t, ang): return t > 0.55 and front.call(ang) < 0.12, hips - 0.06))
			m._garment("org_yaka", func(): return m._loft(g, 1, neck - 0.03, ey - 0.025, 7, neck_f, func(t, _a): return 0.055 + t * 0.045, 8,
				func(t, ang): return t > 0.5 and front.call(ang) < 0.3))
			var ha = m._bp("LeftHand").x
			var la = m._bp("LeftLowerArm").x
			for sx in [-1.0, 1.0]:
				# çan kol: dirsekten bileğe genişleyerek açılır (ağzı kırmızı astarlı, shader)
				m._garment("org_kol%d" % int(sx), func(): return m._loft(g, 0, (la + 0.02) * sx, (ha - 0.02) * sx, 9, func(p): return signf(p.x) == sx and p.y > neck - 0.4,
					func(t, _a): return 0.025 + t * t * 0.075, 8, null, -99.0, 18))
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
		"anbu_palto":
			# ANBU beyaz paltosu (ref gozusaymasadecevicutanbu.png): önü kapalı, dize yakın; bol, kıvrımlı kapüşon yaka; geniş kollar
			m._garment("anbu_palto", func(): return m._loft(g, 1, neck - 0.01, knee + 0.07, 30, torso, func(t, _a): return 0.062 + t * 0.065, 8, null, hips - 0.06))
			m._garment("anbu_kapuson_yaka", func(): return m._loft(g, 1, neck - 0.07, neck + 0.055, 8, neck_f,
				func(t, ang): return 0.05 + sin(t * PI) * 0.035 + 0.008 * sin(ang * 6.0 + t * 3.0) + (0.02 if front.call(ang) > 2.0 else 0.0), 8,
				func(t, ang): return t > 0.45 and front.call(ang) < 0.32, -99.0, 28))
			var ha2 = m._bp("LeftHand").x
			var la2 = m._bp("LeftLowerArm").x
			for sx in [-1.0, 1.0]:
				m._garment("anbu_kol%d" % int(sx), func(): return m._loft(g, 0, (la2 - 0.06) * sx, (ha2 - 0.01) * sx, 10, func(p): return signf(p.x) == sx and p.y > neck - 0.4,
					func(t, _a): return 0.03 + t * 0.035, 8, null, -99.0, 18))
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
	_anbu_parts(m, g)
	var gd = m.look.get("guards")
	if gd in ["dizlik", "agir"]:
		for sx in [-1.0, 1.0]:
			m._garment("dizlik%d" % int(sx), func(): return m._loft(g, 1, knee + 0.05, knee - 0.06, 5, func(p): return signf(p.x) == sx and absf(p.x) < 0.35,
				func(_t, ang): return 0.028 if front.call(ang) < 1.1 else 0.012, 9, null, -99.0, 16))


## ANBU takım parçaları (ref anbu.png / anbu2.png / anbu3.png): kumaş kabuğuna derili loft katmanları, dirsekle bükülür.
## Yuva renkleri: 7 = koyu (ısıtıcı), 9 = kolluk rengi (metal plaka), 4 = sargı rengi (beyaz bant/sargı)
static func _anbu_parts(m: CharacterModel, g: Dictionary) -> void:
	var L = m.look
	var neck = m._bp("Neck").y; var knee = m._bp("LeftLowerLeg").y; var ank = m._bp("LeftFoot").y
	var ua = m._bp("LeftUpperArm").x; var el = m._bp("LeftLowerArm").x; var ha = m._bp("LeftHand").x
	var arm = L.get("anbu_arm")
	if arm != null:
		for sx in [-1.0, 1.0]:
			var af = func(p: Vector3) -> bool: return signf(p.x) == sx and p.y > neck - 0.32
			var outer = func(_t: float, ang: float) -> bool: return absf(ang) > 1.0   # plaka yalnız dış yüzde (kol inince yana bakar)
			if arm == "uzun":
				# siyah ısıtıcı: üst kolun ortasından elin sırtına
				m._garment("anbu_isitici%d" % int(sx), func(): return m._loft(g, 0, lerpf(ua, el, 0.4) * sx, (ha + 0.035) * sx, 16, af,
					func(t, _a): return 0.006 + (1.0 - t) * 0.004, 7, null, -99.0, 18))
				m._garment("anbu_plaka_u%d" % int(sx), func(): return m._loft(g, 0, (el - 0.035) * sx, (ha - 0.02) * sx, 9, af,
					func(t, _a): return 0.024 + sin(t * PI) * 0.006, 9, outer, -99.0, 20))
				for q in [0.3, 0.62]:   # plakayı kola bağlayan iki kayış (bileğe yakın değil: el ağırlığı alıp halka gibi açılıyordu)
					var x0 = lerpf(el - 0.02, ha - 0.03, q)
					m._garment("anbu_kayis%d_%d" % [int(sx), int(q * 100)], func(): return m._loft(g, 0, (x0 - 0.009) * sx, (x0 + 0.009) * sx, 2, af,
						func(_t, a): return 0.03 if absf(a) < 1.1 else 0.009, 9, null, -99.0, 18))   # plakanın üstünde kalın, iç yüzde kola sıkı
				if L.get("anbu_band") == 2 or (L.get("anbu_band") == 1 and sx > 0.0):
					var bx = lerpf(ua, el, 0.47)
					m._garment("anbu_bant%d" % int(sx), func(): return m._loft(g, 0, (bx - 0.026) * sx, (bx + 0.026) * sx, 4, af,
						func(_t, _a): return 0.014, 4, null, -99.0, 18))
			else:
				# kısa kolluk: ön kolda koyu sargı + üstünde plaka (dirseği az aşar)
				m._garment("anbu_kisa_alt%d" % int(sx), func(): return m._loft(g, 0, (el + 0.03) * sx, (ha - 0.025) * sx, 8, af,
					func(_t, _a): return 0.01, 7, null, -99.0, 18))
				m._garment("anbu_plaka_k%d" % int(sx), func(): return m._loft(g, 0, (el - 0.02) * sx, (ha - 0.035) * sx, 8, af,
					func(t, _a): return 0.026 + sin(t * PI) * 0.006, 9, outer, -99.0, 20))
				for q in [0.2, 0.6]:
					var x1 = lerpf(el, ha - 0.04, q)
					m._garment("anbu_kkayis%d_%d" % [int(sx), int(q * 100)], func(): return m._loft(g, 0, (x1 - 0.008) * sx, (x1 + 0.008) * sx, 2, af,
						func(_t, a): return 0.031 if absf(a) < 1.1 else 0.012, 9, null, -99.0, 18))
	var leg = L.get("anbu_leg")
	if leg != null:
		for sx in [-1.0, 1.0]:
			var kx = m._bp(("Left" if sx > 0.0 else "Right") + "LowerLeg").x
			var lf = func(p: Vector3) -> bool: return signf(p.x) == sx and absf(p.x - kx) < 0.095
			if leg == "diz":
				# siyah bacak ısıtıcı: dizin altından bileğe, alta doğru hafif bol; iç yüz ince (öbür bacağın ağırlığını alıp yürürken uzamasın)
				m._garment("anbu_bacak%d" % int(sx), func(): return m._loft(g, 1, knee - 0.035, ank + 0.035, 12, lf,
					func(t, a): return (0.016 + t * 0.008) * (1.0 if cos(a) * sx > -0.3 else 0.3), 7, null, -99.0, 20))
				if sx < 0.0:   # sağ dizde beyaz sargı (ref: tek diz)
					m._garment("anbu_diz", func(): return m._loft(g, 1, knee + 0.05, knee - 0.04, 6, lf,
						func(t, a): return (0.032 + 0.005 * absf(sin(t * PI * 3.0))) * (1.0 if cos(a) * sx > -0.3 else 0.3), 4, null, -99.0, 20))
			elif leg == "bant":
				# boğum boğum bantlı tozluk: dizin altından bileğe halka halka
				m._garment("anbu_bantli%d" % int(sx), func(): return m._loft(g, 1, knee - 0.06, ank + 0.03, 24, lf,
					func(t, a): return (0.014 + (0.012 if fposmod(t * 5.0, 1.0) < 0.4 else 0.0)) * (1.0 if cos(a) * sx > -0.3 else 0.35), 7, null, -99.0, 20))
	if L.get("anbu_tasset", false) and L.get("outer") is Color:
		# belin arkasından dizlere sarkan peştamal (ref anbu2.png: bacak arasından görünür), ikincil hareket
		var hy = m._bp("Hips").y
		var bz = m._back_z(hy + 0.02)
		m.dangle_strip("Hips", Vector3(0, hy + 0.02, bz - 0.02), Vector3(0, -1.0, -0.12), 0.46, 0.2, L["outer"], 0.22, Vector3(1, 0, 0), 0.006)


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
	if L.get("head_style") in ["kabuto", "tengai", "kapuson"]:
		var clumps = CharacterModel._hair_cache.values()
		for mi in m.skel.find_children("*", "MeshInstance3D", true, false):
			if mi.name in ["VHair", "HairDangle"] or (mi.mesh != null and mi.mesh in clumps):
				mi.visible = false
	match L.get("head_style"):
		"hachimaki":
			# alına sıkıca bağlı kumaş bant (saçın üstünde), ensede düğüm + uzun uçuşan iki uç
			m.cloth_band(hg, 0.0, 0.04, 0.26, 0.034)
		"basortu":
			# haydut bezi: alnın üstünden kafanın tepesini ve arkasını saran bez, ensede iri düğüm + iki uç
			var yb = m.cloth_band(hg, -0.004, 0.034, 0.17, 0.042, 0.004)
			m.head_cap(hg, yb + 0.014, 0.075, 0.06)
		"sarik":
			# çöl sarığı: kafaya oturan kabarık bez + farklı eğimlerde üç kat sargı + arkada rüzgârda uçuşan uzun uç
			var ys = m.cloth_band(hg.darkened(0.04), 0.004, 0.036, 0.0, 0.0, 0.004, 0.02)
			m.head_cap(hg, ys + 0.016, 0.085, 0.12, 0.024, 0.045)
			m.cloth_band(hg.darkened(0.1), 0.03, 0.03, 0.0, 0.0, -0.022, 0.03)
			m.cloth_band(hg.darkened(0.02), 0.055, 0.026, 0.0, 0.0, 0.02, 0.026)
			var rr: PackedFloat32Array = m.band_ring[1]
			var rb = rr[int(floor((-PI * 0.5 + PI) / TAU * rr.size())) % rr.size()]
			m.dangle_strip("Head", Vector3(m.skull_c.x - 0.03, ys + 0.01, m.skull_c.z - rb - 0.03), Vector3(-0.15, -1.0, -0.35), 0.32, 0.085, hg.darkened(0.06), 0.12, Vector3(1, 0, 0.2), 0.004)
		"jingasa":
			var mb = MB.new()
			mb.add("cone", Vector3.ZERO, Vector3(hw * 2.5, 0.1, hw * 2.5), hg, Vector3.ZERO, 20)
			mb.add("cyl", Vector3(0, -0.05, 0), Vector3(hw * 2.52, 0.012, hw * 2.52), hg.darkened(0.3), Vector3.ZERO, 20)
			mb.add("cyl", Vector3(0, 0.0, hw * 0.62), Vector3(0.06, 0.006, 0.06), gold, Vector3(70, 0, 0), 12)
			for sx in [-1.0, 1.0]:
				mb.add("box", Vector3(hw * 0.5 * sx, -0.14, 0.02), Vector3(0.008, 0.2, 0.008), dark, Vector3(0, 0, -8 * sx))
			var jy = maxf(htop, m.head_top() + 0.005)   # kafanın gerçek tepesi koninin içinde kalsın
			m._mesh_on("Head", mb.build(toon), Transform3D(Basis.IDENTITY, Vector3(hc.x, jy, hc.z)))
			m.hair_mask_plane(Vector3.UP, Vector3(0, jy - 0.045, 0))   # şapka kenarının üstündeki saç şapkanın içinde kalır
		"kabuto":
			m.kabuto(hg, String(L.get("crest", "")))
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
	# kapüşon: kafaya bol oturan, yüzü açık, enseden omuzlara dökülen kumaş (CharacterModel.hood)
	if L.get("head_style") == "kapuson":
		m.hood(hg, String(L.get("hood", "")))
	var fg: Color = L.get("facegear") if L.get("facegear") != null else Color.WHITE
	var fs = String(L.get("face_style", "")) if L.get("face_style") != null else ""
	var handled = fs != "" and m.face_item(fs, fg)   # yüz kabuğuna oturan yeni sürüm
	if handled:
		pass
	elif fs in ["cloth", "pece"]:
		# bez maske / peçe: burundan çeneye sarılan kumaş + boyun
		var mb = MB.new()
		var ey = m.eye_center_model.y if m.face_mi else hc.y - 0.03
		mb.add("cyl", Vector3(0, ey - 0.07 - hc.y, 0.012), Vector3(hw * 1.06, 0.075, hd * 1.02), fg, Vector3(-6, 0, 0), 20)
		mb.add("cyl", Vector3(0, ey - 0.13 - hc.y, -0.005), Vector3(hw * 0.86, 0.07, hd * 0.86), fg.darkened(0.1), Vector3.ZERO, 18)
		if fs == "pece":
			mb.add("box", Vector3(0, ey - 0.15 - hc.y, hd * 0.47), Vector3(hw * 0.8, 0.12, 0.012), fg, Vector3(8, 0, 0))
		m._mesh_on("Head", mb.build(toon), Transform3D(Basis.IDENTITY, hc))
	match ("" if handled else fs):
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
	if L.get("armor_style") == "sengoku":
		_sengoku(m, L, ch, hip, toon)
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


## Savaşan Devletler zırhı (klan savaşları dönemi): kat kat lamel göğüslük (dō), boyun yakası, omuzdan sarkan
## katmanlı büyük omuzluklar (sode), ön kol plakaları ve uyluklara inen plaka etek (kusazuri). Renkler yelekten (c1) ve vurgudan.
## T-pozu: kollar ±X boyunca; kolun üst yüzü (+Y) kol inince dış yüze döner. Model önü +Z.
static func _sengoku(m: CharacterModel, L: Dictionary, ch: Vector3, hip: Vector3, toon: Material) -> void:
	var c: Color = L.get("vest") if L.get("vest") != null else Color(0.55, 0.16, 0.12)
	var trim: Color = L.get("armor_trim") if L.get("armor_trim") != null else c.darkened(0.45)
	var cord = Color(0.85, 0.7, 0.3) if c.r > c.b else Color(0.75, 0.75, 0.8)
	var sh = absf(m._bp("LeftUpperArm").x)
	var tw = sh * 1.85          # gövde genişliği
	var td = sh * 1.25          # gövde derinliği
	# göğüslük: üst gövdede 4, belde 3 lamel bandı (her bant bir öncekinin üstüne biner)
	var up = MB.new()
	for k in 4:
		var y = 0.1 - k * 0.075
		up.add("cyl", Vector3(0, y, 0.005), Vector3(tw * (1.0 + k * 0.02), 0.07, td * (1.02 + k * 0.02)), c.lightened(0.04 * (k % 2)), Vector3(-4, 0, 0), 18)
		up.add("cyl", Vector3(0, y - 0.034, 0.005), Vector3(tw * (1.01 + k * 0.02), 0.012, td * (1.03 + k * 0.02)), trim, Vector3(-4, 0, 0), 18)
		for j in 5:   # bant üstünde dikiş bağcıkları
			up.add("box", Vector3(-tw * 0.3 + j * tw * 0.15, y, td * (0.52 + k * 0.01)), Vector3(0.008, 0.05, 0.006), cord)
	# yüksek boyun yakası
	up.add("cyl", Vector3(0, 0.2, 0), Vector3(sh * 0.95, 0.07, sh * 0.85), c.darkened(0.15), Vector3.ZERO, 16)
	up.add("cyl", Vector3(0, 0.17, 0), Vector3(sh * 1.1, 0.02, sh * 1.0), trim, Vector3.ZERO, 16)
	m._mesh_on("UpperChest", up.build(toon), Transform3D(Basis.IDENTITY, ch))
	var lo = MB.new()
	for k in 3:
		lo.add("cyl", Vector3(0, -k * 0.065, 0), Vector3(tw * (0.9 + k * 0.03), 0.06, td * (0.98 + k * 0.03)), c.darkened(0.04 * (k % 2)), Vector3.ZERO, 18)
		lo.add("cyl", Vector3(0, -k * 0.065 - 0.03, 0), Vector3(tw * (0.91 + k * 0.03), 0.01, td * (0.99 + k * 0.03)), trim, Vector3.ZERO, 18)
	lo.add("cyl", Vector3(0, -0.2, 0), Vector3(tw * 1.0, 0.05, td * 1.08), Color(0.12, 0.1, 0.1), Vector3.ZERO, 18)   # kuşak
	m._mesh_on("Hips", lo.build(toon), Transform3D(Basis.IDENTITY, hip + Vector3(0, 0.22, 0)))
	# omuzluklar (sode): kolun üstünde, omuzdan dirseğe doğru 5 kat binen geniş plaka
	for side in ["Left", "Right"]:
		var ua = m._bp(side + "UpperArm")
		var sx = signf(ua.x)
		var sb = MB.new()
		for k in 5:
			var t = 0.03 + k * 0.045
			sb.add("box", Vector3(sx * t, 0.06 - k * 0.006, 0), Vector3(0.05, 0.022, 0.2 + k * 0.012), c.lightened(0.05 * (k % 2)), Vector3(0, 0, -sx * (14 + k * 3)))
			sb.add("box", Vector3(sx * (t + 0.022), 0.05 - k * 0.006, 0), Vector3(0.006, 0.024, 0.2 + k * 0.012), trim, Vector3(0, 0, -sx * (14 + k * 3)))
		sb.add("box", Vector3(sx * 0.02, 0.07, 0.0), Vector3(0.012, 0.012, 0.18), cord)
		m._mesh_on(side + "UpperArm", sb.build(toon), Transform3D(Basis.IDENTITY, ua))
		# ön kol plakası (kote)
		var la = m._bp(side + "LowerArm")
		var kb = MB.new()
		kb.add("cyl", Vector3(sx * 0.11, 0, 0), Vector3(0.075, 0.2, 0.08), c.darkened(0.1), Vector3(0, 0, 90), 10)
		for k in 3:
			kb.add("cyl", Vector3(sx * (0.05 + k * 0.06), 0, 0), Vector3(0.082, 0.012, 0.087), trim, Vector3(0, 0, 90), 10)
		m._mesh_on(side + "LowerArm", kb.build(toon), Transform3D(Basis.IDENTITY, la))
		# uyluk plakaları (kusazuri): önde ve dışta, kalçadan dize 4 sıra
		var ul = m._bp(side + "UpperLeg")
		var kz = MB.new()
		for k in 4:
			var y = -0.02 - k * 0.065
			kz.add("box", Vector3(0.0, y, 0.085), Vector3(0.15, 0.06, 0.02), c.lightened(0.04 * (k % 2)), Vector3(-6, 0, 0))
			kz.add("box", Vector3(sx * 0.085, y, 0.0), Vector3(0.02, 0.06, 0.15), c.lightened(0.04 * (k % 2)), Vector3(0, 0, sx * 6))
			kz.add("box", Vector3(0.0, y - 0.03, 0.096), Vector3(0.15, 0.008, 0.006), trim)
			kz.add("box", Vector3(sx * 0.096, y - 0.03, 0.0), Vector3(0.006, 0.008, 0.15), trim)
		m._mesh_on(side + "UpperLeg", kz.build(toon), Transform3D(Basis.IDENTITY, ul))


## Sandalet halkaları yerine ayakkabı türüne göre halka tanımı (null = varsayılan)
static func foot_rings(foot_style: String, fp: Vector3):
	match foot_style:
		"cizme":
			return [[1, fp.y + 0.02, 0.005, 0.008, 99.0]]   # konç bandı shader'da (ayak kemiğine bağlı yüksek halka bükülünce baldırdan fırlıyordu)
		"yuksek_sandal":
			return [[2, fp.z + 0.13, 0.004, 0.007, 0.075], [2, fp.z + 0.06, 0.004, 0.008, 0.11], [1, fp.y + 0.02, 0.006, 0.008, 99.0]]
		"bilek_bot":
			return [[1, fp.y + 0.09, 0.006, 0.01, 99.0], [1, fp.y + 0.02, 0.005, 0.008, 99.0]]
		"diz_cizme", "zirhli_tozluk":
			return [[1, fp.y + 0.02, 0.005, 0.008, 99.0]]
		"sargili_bot":
			return [[1, fp.y + 0.12, 0.006, 0.01, 99.0], [1, fp.y + 0.02, 0.005, 0.008, 99.0]]
	return null
