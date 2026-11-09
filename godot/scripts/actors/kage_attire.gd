class_name KageAttire
extends RefCounted
## Köy liderinin (Kage) giysisi: beyaz uzun cüppe, köy renginde iç giysi, geniş Kage şapkası (üst yarı köy renginde,
## önde köyün kanjisi, arkada beyaz örtü). Kage NPC'leri (ofis, tören) bunu kullanır.

const KANJI := {"konoha": "火", "suna": "風", "kiri": "水", "kumo": "雷", "iwa": "土"}
const COLOR := {"konoha": Color(0.8, 0.14, 0.12), "suna": Color(0.12, 0.42, 0.22), "kiri": Color(0.18, 0.38, 0.75),
	"kumo": Color(0.95, 0.78, 0.16), "iwa": Color(0.5, 0.3, 0.2)}
## Kage kişilikleri (kanon dışı): saç, sakal, yaş havası
const PERSONA := {
	"konoha": {"gender": "m", "hair": Color(0.82, 0.82, 0.84), "hair_style": "geriye", "beard": true, "skin": Color(0.95, 0.8, 0.66)},
	"suna": {"gender": "m", "hair": Color(0.62, 0.22, 0.14), "hair_style": "kısa", "beard": false, "skin": Color(0.9, 0.72, 0.56)},
	"kiri": {"gender": "f", "hair": Color(0.2, 0.25, 0.45), "hair_style": "uzun", "beard": false, "skin": Color(0.97, 0.86, 0.78)},
	"kumo": {"gender": "m", "hair": Color(0.92, 0.9, 0.82), "hair_style": "diken", "beard": true, "skin": Color(0.55, 0.38, 0.27)},
	"iwa": {"gender": "m", "hair": Color(0.7, 0.7, 0.72), "hair_style": "topuz", "beard": true, "skin": Color(0.92, 0.76, 0.62)},
}


static func look(vid: String) -> Dictionary:
	var c: Color = COLOR.get(vid, COLOR["konoha"])
	var pz: Dictionary = PERSONA.get(vid, PERSONA["konoha"])
	var lk = {"top_style": "kimono", "top": c.darkened(0.25), "top2": c.darkened(0.35), "pants": Color(0.92, 0.92, 0.9), "pants_style": "sivil",
		"outer_style": "palto", "outer": Color(0.97, 0.96, 0.93), "vest": null, "band": null, "hakama": true,
		"sandal": Color(0.25, 0.2, 0.16), "age": "adult", "face_mark": "kırışık", "head_style": null}
	lk.merge(pz, true)
	lk.merge(Kage.kage_persona(vid), true)   # dinamik Kage: yeni liderin saçı/cinsiyeti
	if not CharacterModel.HAIR_STYLES.has(lk["hair_style"]):
		lk["hair_style"] = CharacterModel.HAIR_STYLES.keys()[0]
	return lk


## Şapka: model iskeletinin kafasına takılır
static func hat(model: Node, vid: String) -> void:
	if model == null or not model.has_method("_mesh_on"):
		return
	if vid in STRIKER_HATS:
		_hat_striker(model, vid)   # Striker ref'li (Hokage/Raikage/Mizukage/Tsuchikage); Kazekage ref yok -> eski şapka
		return
	var c: Color = COLOR.get(vid, COLOR["konoha"])
	var white = Color(0.97, 0.96, 0.93)
	var hc: Vector3 = model._head_center()
	var ab: AABB = model.head_ab
	var hw = clampf(ab.size.x, 0.16, 0.26) if ab.size.x > 0.05 else 0.2
	var hh = clampf(ab.size.y, 0.12, 0.26) if ab.size.y > 0.05 else 0.2
	var D = hw * 2.7   # kenar çapı (anime oranı: başın ~2.7 katı; eskiden 4.3 idi, fazla büyüktü)
	var H = 0.19
	var m = MB.new()
	m.add("cone", Vector3.ZERO, Vector3(D, H, D), white, Vector3.ZERO, 24)
	m.add("cone", Vector3(0, H * 0.25 + 0.004, 0), Vector3(D * 0.5, H * 0.5, D * 0.5), c, Vector3.ZERO, 24)
	m.add("cyl", Vector3(0, -H * 0.5 + 0.006, 0), Vector3(D * 1.01, 0.012, D * 1.01), white.darkened(0.12), Vector3.ZERO, 24)
	m.add("cyl", Vector3(0, -H * 0.5 - 0.02, 0), Vector3(hw * 1.08, 0.05, hw * 1.16), c.darkened(0.3), Vector3.ZERO, 14)
	m.add("sphere", Vector3(0, H * 0.5, 0), Vector3(0.025, 0.025, 0.025), c.darkened(0.2), Vector3.ZERO, 8)
	# önde: kanji çevresinde beyaz eşkenar dörtgen
	var slope = rad_to_deg(atan2(H, D * 0.5))
	var fy = H * 0.06
	var fz = D * 0.5 * (0.5 - fy / H) + 0.012
	m.add("box", Vector3(0, fy, fz), Vector3(0.075, 0.075, 0.006), white, Vector3(-(90.0 - slope), 0, 45))
	var top = hc.y + hh * 0.42
	var mi = model._mesh_on("Head", m.build(Props.toon()), Transform3D(Basis.IDENTITY, Vector3(hc.x, top + 0.05, hc.z)))
	# arkadan ve yanlardan sarkan beyaz örtü: rüzgârda/koşuda dalgalanan kumaş paneller (ikincil hareket)
	var brim_y = top + 0.05 - H * 0.5
	for k in 5:
		var a = deg_to_rad(110.0 + k * 35.0)
		var r = D * 0.36
		var out = Vector3(sin(a), 0, cos(a))
		model.dangle_strip("Head", Vector3(hc.x, brim_y - 0.01, hc.z) + out * r, (Vector3.DOWN + out * 0.12).normalized(), 0.19, 0.11, white.darkened(0.04), 0.22, out.cross(Vector3.UP).normalized(), 0.004)
	model.hair_mask_plane(Vector3.UP, Vector3(0, brim_y, 0))   # kenarın üstündeki saç şapkanın içinde kalır
	var l = Label3D.new()
	l.text = KANJI.get(vid, "影")
	l.font = _font()
	l.font_size = 64
	l.pixel_size = 0.0009
	l.modulate = c.darkened(0.1)
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD   # saydam sıralama yok (şapkayla sıra kavgası = bir görünüp bir kaybolma)
	l.rotation = Vector3(deg_to_rad(-(90.0 - slope)), 0, 0)
	# yüzey eğik (~55°): yalnız z'de 5 mm kaydırmak normal boyunca ~3 mm = kutunun yarı kalınlığı -> kanji kutunun içinde
	# kalıp derinlik çakışmasıyla titriyordu. Normal boyunca kutu yüzünün 8 mm önüne
	var nrm = Basis(Vector3.RIGHT, l.rotation.x) * Vector3(0, 0, 1)
	l.position = Vector3(0, fy, fz) + nrm * 0.011
	mi.add_child(l)


## Striker şapka tonları (ref ekran görüntülerinden; cüppe rengi COLOR ayrı)
const HAT_COLOR := {"konoha": Color(0.55, 0.08, 0.08), "kumo": Color(0.78, 0.6, 0.22), "kiri": Color(0.08, 0.13, 0.36), "iwa": Color(0.3, 0.17, 0.12), "suna": Color(0.08, 0.38, 0.2)}
const STRIKER_HATS := ["konoha", "kumo", "kiri", "iwa", "suna"]   # Kazekage: refs/hair_dlc/Kazekage_Hat.jpg


## Striker Kage şapkası (refs/hair_dlc/*_Hat.jpg): geniş, alçak koni tamamı köy renginde; önde tepeye doğru sivrilen
## beyaz üçgen kama içinde köy rengi kanji; ince beyaz kenar; kenarın altından yanları ve arkayı saran, omuza inen
## sert beyaz örtü (önü açık). Şapka alnı örter, kenar kaş hizasında.
static func _hat_striker(model: Node, vid: String) -> void:
	var c: Color = HAT_COLOR.get(vid, COLOR["konoha"])
	var white = Color(0.96, 0.96, 0.95)
	var hc: Vector3 = model._head_center()
	var ab: AABB = model.head_ab
	var hw = clampf(ab.size.x, 0.16, 0.26) if ab.size.x > 0.05 else 0.2
	var hh = clampf(ab.size.y, 0.12, 0.26) if ab.size.y > 0.05 else 0.2
	var R = hw * 1.25   # kenar yarıçapı (ref: kenar kafanın ~2.5 katı genişlikte)
	var H = R * 0.62    # koni yüksekliği
	var brim_y = hc.y + hh * 0.06   # kenar alın/kaş üstünde (ref: şapka alnı örter)
	var apex = Vector3(hc.x, brim_y + H, hc.z - 0.01)
	var cen = Vector3(hc.x, brim_y, hc.z - 0.01)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var NA = 120; var NT = 24   # sık: beyaz kama kenarı merdiven olmasın
	var pt = func(a: float, t: float, off: float) -> Vector3:
		var r = R * t + off
		return Vector3(cen.x + sin(a) * r, apex.y - H * t + off * 0.6, cen.z + cos(a) * r)
	var col_at = func(a: float, t: float) -> Color:
		var aa = absf(wrapf(a, -PI, PI))
		return white if (t > 0.3 and aa < deg_to_rad(30.0) * smoothstep(0.3, 1.0, t)) else c
	for i in NA:
		var a0 = TAU * i / NA - PI; var a1 = TAU * (i + 1) / NA - PI
		for k in NT:
			var t0 = float(k) / NT; var t1 = float(k + 1) / NT
			var q = [pt.call(a0, t0, 0.0), pt.call(a1, t0, 0.0), pt.call(a1, t1, 0.0), pt.call(a0, t1, 0.0)]
			var cl = col_at.call((a0 + a1) * 0.5, (t0 + t1) * 0.5)
			for idx in [0, 1, 2, 0, 2, 3]:   # tek yüz (çift yüz aynı yerde z-çakışıp leke yapıyordu)
				st.set_color(cl if idx < 4 else cl)
				st.add_vertex(q[idx])
		# kenar şeridi: beyaz, hafif kalın
		var e = [pt.call(a0, 1.0, 0.0), pt.call(a1, 1.0, 0.0), pt.call(a1, 1.0, 0.0) + Vector3(0, -0.012, 0), pt.call(a0, 1.0, 0.0) + Vector3(0, -0.012, 0)]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_color(white)
			st.add_vertex(e[idx])
	st.generate_normals()
	var mi = model._mesh_on("Head", st.commit(), Transform3D.IDENTITY)
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/toon.gdshader")
	mat.set_shader_parameter("rim_amount", 0.15)
	mat.set_shader_parameter("detail_tex_amt", 0.0)   # düz lake (sıva dokusu şapkada leke gibi duruyordu)
	mat.set_shader_parameter("detail_noise", 0.0)
	mi.material_override = mat
	# kanji: beyaz kamanın üstünde, yüzey normali boyunca önde
	var tk = 0.72
	var kp = pt.call(0.0, tk, 0.0)
	var slope = rad_to_deg(atan2(H, R))
	var l = Label3D.new()
	l.text = KANJI.get(vid, "影")
	l.font = _font()
	l.font_size = 64
	l.pixel_size = 0.0017
	l.modulate = c.darkened(0.15)
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	l.rotation = Vector3(deg_to_rad(-(90.0 - slope)), 0, 0)
	var nrm = Basis(Vector3.RIGHT, l.rotation.x) * Vector3(0, 0, 1)
	l.position = kp + nrm * 0.006
	mi.add_child(l)
	# örtü: kenarın içinden yanları ve arkayı saran, omuza inen sert beyaz panel (ikincil hareket)
	var nst = 9
	for k in nst:
		var a = deg_to_rad(lerpf(72.0, 288.0, (k + 0.5) / nst))
		var out = Vector3(sin(a), 0, cos(a))
		var r0 = R * 0.62
		model.dangle_strip("Head", cen + out * r0 + Vector3(0, -0.005, 0), (Vector3.DOWN + out * 0.45).normalized(), hh * 0.95, TAU * r0 / nst * 1.25, white.darkened(0.02), 0.5, out.cross(Vector3.UP).normalized(), 0.004)
	model.hair_mask_plane(Vector3.UP, Vector3(0, brim_y + 0.01, 0))   # şapkanın içinde kalan saç kesilir


static var _f: SystemFont
static func _font() -> SystemFont:
	if _f == null:
		_f = SystemFont.new()
		_f.font_names = PackedStringArray(["Yu Gothic UI", "Yu Gothic", "Meiryo", "MS Gothic", "Noto Sans CJK JP", "Microsoft YaHei"])
		_f.font_weight = 800
	return _f
