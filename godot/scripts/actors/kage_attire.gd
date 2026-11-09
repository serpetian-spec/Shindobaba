class_name KageAttire
extends RefCounted
## Köy liderinin (Kage) giysisi: beyaz uzun cüppe, köy renginde iç giysi, geniş Kage şapkası (üst yarı köy renginde,
## önde köyün kanjisi, arkada beyaz örtü). Kage NPC'leri (ofis, tören) bunu kullanır.

const KANJI := {"konoha": "火", "suna": "風", "kiri": "水", "kumo": "雷", "iwa": "土"}
const COLOR := {"konoha": Color(0.8, 0.14, 0.12), "suna": Color(0.16, 0.45, 0.38), "kiri": Color(0.18, 0.38, 0.75),
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
		_hat_striker(model, vid)
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
const STRIKER_HATS := ["konoha", "kumo", "kiri", "iwa", "suna"]   # Striker Kage şapkaları (v2, ref büyütülerek)


## Striker Kage şapkası (refs/hair_dlc/*_Hat.jpg büyütülmüş incelendi; anime refs/hats yan/arka):
##  - alçak oturur: kenar burun üstü hizasında, gözler şapkanın altında; geniş (çap ≈ 2.4 yüz), basık koni (eğim ~28°)
##  - kenarın tamamında kalın beyaz dudak (üstte dar beyaz şerit + aşağı kalınlık); alt yüz beyaz
##  - önde üstü düz beyaz yamuk (tabanı kenarda), içinde iri köy rengi kanji
##  - örtü TEK PARÇA kumaş: başın içinden (kenarın altından) omuza iner, arkada altta dışa açılır; yan ön paneller göğse uzun
static func _hat_striker(model: Node, vid: String) -> void:
	var c: Color = HAT_COLOR.get(vid, COLOR["konoha"])
	var white = Color(0.95, 0.95, 0.94)
	var hc: Vector3 = model._head_center()
	var ab: AABB = model.head_ab
	var hw = clampf(ab.size.x, 0.16, 0.26) if ab.size.x > 0.05 else 0.2
	var hh = clampf(ab.size.y, 0.12, 0.26) if ab.size.y > 0.05 else 0.2
	var eye_y: float = model.eye_center_model.y if model.get("eye_center_model") != null else hc.y
	var R = hw * 1.42
	var brim_y = eye_y + 0.004   # kenar göz üstü/burun kökü
	# koni kafatasının üstünden geçmeli; kafatası yuvarlak: r yarıçapında kafa yüksekliği top*sqrt(1-(r/rh)^2)
	var skull_top = hc.y + hh * 0.5
	for q in model._body_vs():   # gerçek kafatası tepesi (yüz kutusu tepeyi içermez)
		if absf(q.x - hc.x) < 0.05 and q.y > hc.y:
			skull_top = maxf(skull_top, q.y)
	var top = skull_top + 0.018 - brim_y
	var rh = hw * 0.55
	var H = R * 0.5
	for q in 11:
		var r = rh * q / 10.0
		var need = top * sqrt(maxf(0.0, 1.0 - pow(r / rh, 2.0)))
		H = maxf(H, need / maxf(0.05, 1.0 - r / R))
	var cen = Vector3(hc.x, brim_y, hc.z - 0.005)
	var apex_y = brim_y + H
	var pt = func(a: float, t: float, off := 0.0) -> Vector3:
		var n = Vector3(sin(a) * H, R, cos(a) * H).normalized()   # koni yüzey normali (yaklaşık)
		return Vector3(cen.x + sin(a) * R * t, apex_y - H * t, cen.z + cos(a) * R * t) + n * off
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var quad = func(q: Array, col: Color) -> void:
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_color(col)
			st.add_vertex(q[idx])
	var NA = 96; var NT = 16
	for i2 in NA:
		var a0 = TAU * i2 / NA - PI; var a1 = TAU * (i2 + 1) / NA - PI
		for k in NT:
			var t0 = float(k) / NT; var t1 = float(k + 1) / NT
			var cl = white if t0 >= 0.935 else c
			quad.call([pt.call(a0, t0), pt.call(a1, t0), pt.call(a1, t1), pt.call(a0, t1)], cl)
			# alt yüz (içeriden bakınca beyaz, 5 mm içeride)
			quad.call([pt.call(a0, t0, -0.006), pt.call(a0, t1, -0.006), pt.call(a1, t1, -0.006), pt.call(a1, t0, -0.006)], white.darkened(0.08))
		# kenar kalınlığı (dudak)
		var e0 = pt.call(a0, 1.0); var e1 = pt.call(a1, 1.0)
		var dn = Vector3(0, -0.02, 0)
		quad.call([e0, e1, e1 + dn, e0 + dn], white)
		quad.call([e0 + dn, e1 + dn, pt.call(a1, 0.96, -0.006) + dn * 0.6, pt.call(a0, 0.96, -0.006) + dn * 0.6], white.darkened(0.1))
	# ön yamuk: taban kenarda (±21°), üst düz (t=0.46, ±12°), 2.5 mm önde, düz kenarlı ayrı ızgara
	var NS = 12
	for u in NS:
		for v in NS:
			var g = func(uu: float, vv: float) -> Vector3:
				var t = lerpf(0.46, 0.935, vv)
				var half = deg_to_rad(lerpf(12.0, 21.0, vv))
				return pt.call(lerpf(-half, half, uu), t, 0.0025)
			var u0 = float(u) / NS; var u1 = float(u + 1) / NS; var v0 = float(v) / NS; var v1 = float(v + 1) / NS
			quad.call([g.call(u0, v0), g.call(u1, v0), g.call(u1, v1), g.call(u0, v1)], white)
	st.generate_normals()
	var mi = model._mesh_on("Head", st.commit(), Transform3D.IDENTITY)
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/toon.gdshader")
	mat.set_shader_parameter("rim_amount", 0.12)

	mi.material_override = mat
	# kanji: yamuğun ortasında, iri
	var kp = pt.call(0.0, 0.71, 0.005)
	var slope = rad_to_deg(atan2(H, R))
	var l = Label3D.new()
	l.text = KANJI.get(vid, "影")
	l.font = _font()
	l.font_size = 96
	l.pixel_size = 0.00115
	l.modulate = c.darkened(0.3) if vid == "kumo" else c   # Raikage: sarı beyazda soluk kalıyor, ref turuncu-kahve
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	l.rotation = Vector3(deg_to_rad(-(90.0 - slope)), 0, 0)
	l.position = kp
	mi.add_child(l)
	# örtü (ref: tek parça sert beyaz kumaş): kenarın altından, başın etrafında 60°..300° (önü açık) sürekli perde;
	# yanlarda göğse uzun ön paneller, arkada omza; alt kenarı hafif dışa açılır. 9 Dangle zinciri; köşeler komşu
	# zincirler arasında ağırlıklı: kumaş gibi bütün halinde salınır, aralık açılmaz.
	_veil(model, Vector3(cen.x, brim_y - 0.004, cen.z), hw * 0.6, hh, white)
	model.hair_mask_plane(Vector3.UP, Vector3(0, brim_y + 0.01, 0))


## Kage örtüsü: sürekli kumaş perde + zincirli ikincil hareket
static func _veil(model: Node, top: Vector3, r_in: float, hh: float, white: Color) -> void:
	var a0 = deg_to_rad(58.0); var a1 = deg_to_rad(302.0)
	var NA = 48; var NV = 10
	var NC = 9
	var len_at = func(a: float) -> float:
		var d = absf(wrapf(rad_to_deg(a), -180.0, 180.0))
		return hh * lerpf(1.5, 1.08, smoothstep(70.0, 120.0, d))   # yan önler uzun, arka omza
	var flare_at = func(a: float) -> float:
		var d = absf(wrapf(rad_to_deg(a), -180.0, 180.0))
		return lerpf(0.06, 0.2, smoothstep(90.0, 180.0, d))
	var p_at = func(a: float, v: float, off := 0.0) -> Vector3:
		var out = Vector3(sin(a), 0, cos(a))
		var L: float = len_at.call(a)
		return top + out * (r_in + flare_at.call(a) * L * v * v + off) + Vector3(0, -L * v, 0)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iu in NA:
		for iv in NV:
			var ua = lerpf(a0, a1, float(iu) / NA); var ub = lerpf(a0, a1, float(iu + 1) / NA)
			var va = float(iv) / NV; var vb = float(iv + 1) / NV
			var q = [p_at.call(ua, va), p_at.call(ub, va), p_at.call(ub, vb), p_at.call(ua, vb)]
			var qi = [p_at.call(ua, va, -0.004), p_at.call(ub, va, -0.004), p_at.call(ub, vb, -0.004), p_at.call(ua, vb, -0.004)]
			for idx in [0, 2, 1, 0, 3, 2]:   # dış yüz
				st.set_color(white)
				st.add_vertex(q[idx])
			for idx in [0, 1, 2, 0, 2, 3]:   # iç yüz (4 mm içeride; aynı yerde iki yüz z-çakışıp leke yapıyordu)
				st.set_color(white.darkened(0.08))
				st.add_vertex(qi[idx])
	st.generate_normals()
	var mesh = st.commit()
	var defs = []
	var cang = []
	for c in NC:
		var a = lerpf(a0, a1, float(c) / (NC - 1))
		cang.append(a)
		var pts = PackedVector3Array()
		for k in 5:
			pts.append(p_at.call(a, k / 4.0))
		var hp = CharacterModel.hair_profile(len_at.call(a))
		hp["stiff"] = 0.6; hp["stiff_tip"] = 0.3; hp["grav"] = 0.15; hp["col_r"] = 0.05
		hp["pts"] = pts
		defs.append(hp)
	var vtx: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var assign = func(vi: int, v: Vector3, _si: int) -> Array:
		var d = v - top
		var a = atan2(d.x, d.z)
		if a < 0.0:
			a += TAU
		var f = clampf((a - a0) / (a1 - a0), 0.0, 1.0) * (NC - 1)
		var c0 = mini(int(floor(f)), NC - 2)
		var w1 = f - c0
		var vv = clampf(-d.y / float(len_at.call(a)), 0.0, 1.0) * 4.0
		return [[c0, vv, 1.0 - w1], [c0 + 1, vv, w1]]
	var pack = Dangle.build(mesh, defs, assign)
	if pack.is_empty():
		return
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/toon.gdshader")
	mat.set_shader_parameter("rim_amount", 0.1)
	model.add_dangle("Head", pack, mat, Transform3D.IDENTITY, "KageVeil")


static var _f: SystemFont
static func _font() -> SystemFont:
	if _f == null:
		_f = SystemFont.new()
		_f.font_names = PackedStringArray(["Yu Gothic UI", "Yu Gothic", "Meiryo", "MS Gothic", "Noto Sans CJK JP", "Microsoft YaHei"])
		_f.font_weight = 800
	return _f
