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
	# arkadan ve yanlardan sarkan beyaz örtü
	for k in 5:
		var a = deg_to_rad(110.0 + k * 35.0)
		var r = D * 0.36
		m.add("box", Vector3(sin(a) * r, -H * 0.5 - 0.11, cos(a) * r), Vector3(0.11, 0.17, 0.01), white.darkened(0.04), Vector3(-8, rad_to_deg(a), 0))
	# önde: kanji çevresinde beyaz eşkenar dörtgen
	var slope = rad_to_deg(atan2(H, D * 0.5))
	var fy = H * 0.06
	var fz = D * 0.5 * (0.5 - fy / H) + 0.012
	m.add("box", Vector3(0, fy, fz), Vector3(0.075, 0.075, 0.006), white, Vector3(-(90.0 - slope), 0, 45))
	var top = hc.y + hh * 0.42
	var mi = model._mesh_on("Head", m.build(Props.toon()), Transform3D(Basis.IDENTITY, Vector3(hc.x, top + 0.05, hc.z)))
	var l = Label3D.new()
	l.text = KANJI.get(vid, "影")
	l.font = _font()
	l.font_size = 64
	l.pixel_size = 0.0009
	l.modulate = c.darkened(0.1)
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.position = Vector3(0, fy, fz + 0.005)
	l.rotation = Vector3(deg_to_rad(-(90.0 - slope)), 0, 0)
	mi.add_child(l)


static var _f: SystemFont
static func _font() -> SystemFont:
	if _f == null:
		_f = SystemFont.new()
		_f.font_names = PackedStringArray(["Yu Gothic UI", "Yu Gothic", "Meiryo", "MS Gothic", "Noto Sans CJK JP", "Microsoft YaHei"])
		_f.font_weight = 800
	return _f
