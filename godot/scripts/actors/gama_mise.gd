class_name GamaMise
extends Node3D
## Kuchiyose: Gama Mise no Jutsu (kanon, Jiraiya; ref _tmp/gamamiseref): Myōboku'nun "dükkân kurbağası" bir yapıya dönüşür —
## bej duvarlı, mavi-gri kavisli çatılı, çatısında iki pencereli küçük çatı odası olan, kapı üstünde "フロッグ" tabelalı dükkân;
## yanlarda kurbağanın bacakları bej yuvarlak tümsekler. İçeri giren hapsolur: mühürle yapı geri kurbağaya döner (lacivert-gri
## iri kafa, krem gövde, yuvarlak gözler + haç göz bebeği, gözaltında kırmızı leke) ve içindekiler midesinde kalır.
## Ön -Z. Ölçü metre: dükkân ~6 m genişlik, ~6 m yükseklik.

const WALL := Color(0.88, 0.82, 0.68)
const ROOF := Color(0.32, 0.34, 0.45)
const PANEL := Color(0.45, 0.4, 0.55)
const NAVY := Color(0.28, 0.3, 0.42)
const CREAM := Color(0.9, 0.85, 0.68)

var house: Node3D
var toad: Node3D


static func spawn(parent: Node, at: Vector3, yaw: float) -> GamaMise:
	var g = GamaMise.new()
	parent.add_child(g)
	g.global_position = at
	g.rotation.y = yaw
	return g


func _ready() -> void:
	house = Node3D.new()
	add_child(house)
	toad = Node3D.new()
	add_child(toad)
	_build_house()
	_build_toad()
	toad.visible = false


func _mi(parent: Node3D, b: MB) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	parent.add_child(mi)
	return mi


func _build_house() -> void:
	var b = MB.new()
	# kaide basamağı
	b.add("box", Vector3(0, 0.12, -0.4), Vector3(6.4, 0.24, 4.6), WALL.darkened(0.08))
	# ana gövde
	b.add("box", Vector3(0, 1.85, 0), Vector3(4.6, 3.3, 3.2), WALL)
	# iki yanda mor dikey panolar (ref: kapının iki yanında koyu mor paneller)
	for s in [-1.0, 1.0]:
		b.add("box", Vector3(s * 1.55, 1.7, -1.62), Vector3(0.7, 2.9, 0.06), PANEL)
		b.add("box", Vector3(s * 2.15, 1.7, -1.62), Vector3(0.25, 2.9, 0.06), PANEL.darkened(0.2))
	# kapı + tabela
	b.add("box", Vector3(0, 1.05, -1.62), Vector3(0.95, 1.9, 0.06), WALL.lightened(0.08))
	b.add("box", Vector3(0.28, 1.05, -1.66), Vector3(0.05, 0.12, 0.03), Color(0.3, 0.3, 0.3))
	b.add("box", Vector3(0, 2.65, -1.64), Vector3(1.1, 0.42, 0.06), Color(0.95, 0.93, 0.88))
	_mi(house, b)
	var sign = Label3D.new()
	sign.text = "フロッグ"
	sign.font_size = 64
	sign.pixel_size = 0.004
	sign.modulate = Color(0.75, 0.15, 0.15)
	sign.outline_size = 0
	house.add_child(sign)
	sign.position = Vector3(0, 2.65, -1.68)
	sign.rotation.y = PI
	# kavisli geniş çatı: saçaklar dışa kıvrık (ref: Japon tarzı, kenarları yukarı kalkık mavi-gri kiremit)
	var rb = MB.new()
	for k in 30:   # içbükey (saçağa doğru açılan) geniş kalça çatı: ince üst üste katlar
		var q = k / 29.0
		var flare = pow(1.0 - q, 1.8)
		var w = lerpf(2.2, 4.8, 1.0 - q) + flare * 3.2
		var d = lerpf(1.0, 3.4, 1.0 - q) + flare * 2.4
		var y = 3.15 + q * 2.5
		rb.add("box", Vector3(0, y, 0), Vector3(w, 0.13, d), ROOF.lightened(0.05 if k % 3 == 0 else 0.0))
	# çatıdaki iki küçük çatı odası (pencereli, sivri)
	for s in [-1.0, 1.0]:
		rb.add("box", Vector3(s * 1.3, 5.15, -0.3), Vector3(1.0, 1.1, 1.0), WALL)
		rb.add("box", Vector3(s * 1.3, 5.2, -0.81), Vector3(0.5, 0.5, 0.04), Color(0.25, 0.22, 0.2))
		rb.add("box", Vector3(s * 1.3, 5.2, -0.83), Vector3(0.04, 0.5, 0.03), WALL)
		rb.add("box", Vector3(s * 1.3, 5.2, -0.83), Vector3(0.5, 0.04, 0.03), WALL)
		for side in [-1.0, 1.0]:
			rb.add("box", Vector3(s * 1.3 + side * 0.35, 5.95, -0.3), Vector3(0.85, 0.12, 1.25), ROOF, Vector3(0, 0, -side * 42))
	_mi(house, rb)
	# yanlarda kurbağanın bacakları: bej yuvarlak tümsekler (taş gibi)
	var lb = MB.new()
	for s in [-1.0, 1.0]:
		Loft.blob(lb, Vector3(s * 3.2, 1.2, 0.9), Vector3(0, 0, -1), 4.6, [Vector2(0.9, 0.8), Vector2(1.5, 1.45), Vector2(1.45, 1.4), Vector2(0.9, 0.85)], WALL, 16)
	_mi(house, lb)


func _build_toad() -> void:
	var b = MB.new()
	# krem gövde: yassı geniş kubbe
	Loft.blob(b, Vector3(0, 0.0, 0.3), Vector3(0, 1, 0), 2.2, [Vector2(2.8, 2.6), Vector2(3.0, 2.8), Vector2(2.4, 2.2), Vector2(0.8, 0.8)], CREAM, 20)
	# lacivert iri kafa (önde, gövdenin üstüne taşar)
	Loft.blob(b, Vector3(0, 0.85, -0.6), Vector3(0, 0.2, -1), 3.1, [Vector2(2.0, 1.2), Vector2(2.75, 1.75), Vector2(2.65, 1.65), Vector2(1.6, 0.9)], NAVY, 20)
	# sırttaki çizgi desenleri
	for k in 5:
		b.add("box", Vector3((k - 2) * 0.35, 2.55, -0.6), Vector3(0.06, 0.04, 1.2), NAVY.darkened(0.25), Vector3(0, (k - 2) * 8, 0))
	# yuvarlak gözler: krem halka + koyu iris + haç biçimli göz bebeği; altında kırmızı leke
	for s in [-1.0, 1.0]:
		var e = Vector3(s * 1.2, 2.25, -2.95)
		b.add("sphere", e, Vector3(0.95, 0.95, 0.6), CREAM.lightened(0.1), Vector3.ZERO, 14)
		b.add("sphere", e + Vector3(0, 0, -0.2), Vector3(0.62, 0.62, 0.3), Color(0.55, 0.52, 0.32), Vector3.ZERO, 12)
		b.add("box", e + Vector3(0, 0, -0.36), Vector3(0.42, 0.09, 0.04), Color(0.1, 0.1, 0.1))
		b.add("box", e + Vector3(0, 0, -0.36), Vector3(0.09, 0.42, 0.04), Color(0.1, 0.1, 0.1))
		b.add("box", e + Vector3(s * 0.05, -0.62, -0.1), Vector3(0.18, 0.4, 0.05), Color(0.7, 0.2, 0.15), Vector3(0, 0, s * 20))
	# geniş ağız + dudak halkaları (ref: önde katmanlı ağız)
	# ağız: kafanın altından görünen iç içe krem dudak halkaları (ref)
	for k in 3:
		b.add("torus", Vector3(0, 0.45 + k * 0.06, -3.2 + k * 0.32), Vector3(2.2 - k * 0.55, 0.22, 1.1 - k * 0.28), CREAM.darkened(0.04 * k), Vector3.ZERO, 18)
	b.add("sphere", Vector3(0, 0.42, -2.85), Vector3(1.0, 0.4, 0.6), CREAM.lightened(0.05), Vector3.ZERO, 12)
	b.add("box", Vector3(0, 0.95, -3.62), Vector3(1.8, 0.08, 0.1), Color(0.2, 0.15, 0.2))
	# yanlarda ön ve arka bacaklar
	for s in [-1.0, 1.0]:
		Loft.blob(b, Vector3(s * 2.6, 0.4, -1.2), Vector3(s * 0.6, -0.3, -1), 1.8, [Vector2(0.4, 0.3), Vector2(0.6, 0.45), Vector2(0.5, 0.35), Vector2(0.3, 0.15)], CREAM, 12)
		Loft.blob(b, Vector3(s * 2.8, 0.5, 1.5), Vector3(s * 0.4, -0.2, 1), 2.4, [Vector2(0.5, 0.4), Vector2(0.8, 0.6), Vector2(0.7, 0.5), Vector2(0.35, 0.2)], CREAM, 12)
	_mi(toad, b)


## Dükkân -> kurbağa: yapı küçülüp kaybolur, kurbağa şişerek belirir (içindekiler midede)
func morph(dur := 0.6) -> void:
	toad.visible = true
	toad.scale = Vector3(1.0, 0.05, 1.0)
	var tw = create_tween()
	tw.tween_property(house, "scale", Vector3(1.0, 0.05, 1.0), dur * 0.5).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): house.visible = false)
	tw.tween_property(toad, "scale", Vector3.ONE, dur * 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Kurbağa içindekilerle birlikte küçülür (ref 3: avuç içi kadar kurbağa)
func shrink(dur := 0.8) -> void:
	var tw = create_tween()
	tw.tween_property(toad, "scale", Vector3.ONE * 0.08, dur).set_ease(Tween.EASE_IN)
