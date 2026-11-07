class_name Kanzeon
extends Node3D
## Kanzeon Renge-Ō (kanon, Tobi/Zetsu Yamato'yu araç ederek; ref _tmp/kanzeonref): Shin Sūsenju'dan küçük, AYAKTA dev tahta heykel —
## aşağı doğru sütun gibi genişleyen uzun cüppe, göğsünde çapraz ana kollar, ana başta topuz, başın çevresinde taç gibi beş küçük
## baş (Issai Kaiku: her biri bir doğa salar), ardında büyük hale halkası ve ondan ışın gibi açılan iki sıra uzun kol.
## Boy ~160 m. Tasarım: toplam yükseklik 10, ön -Z.

const H := 160.0
const WOOD := Color(0.5, 0.4, 0.33)
const DARK := Color(0.33, 0.26, 0.21)

var body: Node3D
var fan_xf: Array = []
var heads: Array = []   # beş küçük başın tasarım konumları (Issai Kaiku çıkış noktaları)


static func spawn(parent: Node, at: Vector3, yaw: float) -> Kanzeon:
	var k = Kanzeon.new()
	parent.add_child(k)
	k.global_position = at
	k.rotation.y = yaw
	return k


func _ready() -> void:
	body = Node3D.new()
	add_child(body)
	_build()
	body.scale = Vector3.ONE * (H / 10.0)


func _build() -> void:
	var b = MB.new()
	# uzun cüppe: yerde geniş etekten yukarı daralan sütun (ref: heykel tek parça sütun gibi yükselir)
	Loft.tube(b, [Vector3(0, 0.0, 0.0), Vector3(0, 1.5, 0.0), Vector3(0, 3.5, 0.0), Vector3(0, 5.5, 0.0), Vector3(0, 6.6, 0.0)], [Vector2(1.5, 1.2), Vector2(1.1, 0.85), Vector2(0.85, 0.65), Vector2(0.8, 0.6), Vector2(0.95, 0.65)], WOOD, 20, 4, true, false)
	for k in 8:   # cüppe kıvrımları (dikey koyu çizgiler)
		var a = lerpf(-1.1, 1.1, k / 7.0)
		Loft.tube(b, [Vector3(sin(a) * 1.45, 0.05, -cos(a) * 1.15), Vector3(sin(a) * 1.0, 2.2, -cos(a) * 0.78), Vector3(sin(a) * 0.82, 5.2, -cos(a) * 0.62)], [0.03, 0.025, 0.02], DARK, 5, 3)
	# göğüs-omuz + çapraz kollar (ref: kollar göğsün önünde çapraz)
	Loft.tube(b, [Vector3(0, 6.4, 0.0), Vector3(0, 7.3, 0.0), Vector3(0, 7.7, 0.0)], [Vector2(1.05, 0.68), Vector2(1.1, 0.68), Vector2(0.45, 0.4)], WOOD, 16, 3)
	for s in [-1.0, 1.0]:
		Loft.tube(b, [Vector3(s * 1.05, 7.35, 0.0), Vector3(s * 1.1, 6.7, -0.4), Vector3(s * 0.35, 6.85, -0.78), Vector3(-s * 0.55, 7.15, -0.72)], [0.26, 0.24, 0.21, 0.18], WOOD.lightened(0.03 * s), 10, 3)
		Loft.blob(b, Vector3(-s * 0.68, 7.2, -0.7), Vector3(-s, 0.2, 0), 0.35, [Vector2(0.12, 0.08), Vector2(0.16, 0.1), Vector2(0.13, 0.08), Vector2(0.06, 0.04)], WOOD, 8)   # el
	# baş: sakin Buda yüzü, topuz
	Loft.tube(b, [Vector3(0, 7.6, 0.0), Vector3(0, 7.95, -0.03)], [0.3, 0.28], WOOD, 12, 2)
	Loft.blob(b, Vector3(0, 7.9, -0.03), Vector3(0, 1, 0), 1.0, [Vector2(0.4, 0.4), Vector2(0.52, 0.5), Vector2(0.48, 0.46), Vector2(0.24, 0.22)], WOOD, 14)
	Loft.blob(b, Vector3(0, 8.85, 0.0), Vector3(0, 1, 0), 0.55, [Vector2(0.2, 0.2), Vector2(0.24, 0.24), Vector2(0.18, 0.18), Vector2(0.06, 0.06)], DARK, 10)   # topuz
	for s in [-1.0, 1.0]:
		Loft.tube(b, [Vector3(s * 0.08, 8.35, -0.47), Vector3(s * 0.2, 8.32, -0.47), Vector3(s * 0.3, 8.35, -0.43)], [0.02, 0.025, 0.015], DARK, 5, 2)   # kapalı gözler
		Loft.blob(b, Vector3(s * 0.5, 8.2, 0.0), Vector3(0, -1, 0), 0.55, [Vector2(0.06, 0.04), Vector2(0.09, 0.05), Vector2(0.08, 0.05), Vector2(0.06, 0.03)], WOOD, 6)   # uzun kulak
	b.add("box", Vector3(0, 7.95, -0.47), Vector3(0.14, 0.02, 0.02), DARK)
	# taç gibi beş küçük baş (ön yarım çemberde, alın hizasında) — her biri topuzlu küçük Buda başı
	heads.clear()
	for k in 5:
		var a = lerpf(-1.25, 1.25, k / 4.0)
		var hp = Vector3(sin(a) * 0.62, 8.55, -cos(a) * 0.5)
		Loft.blob(b, hp + Vector3(0, -0.14, 0), Vector3(0, 1, 0), 0.32, [Vector2(0.11, 0.11), Vector2(0.14, 0.14), Vector2(0.13, 0.13), Vector2(0.07, 0.07)], WOOD.lightened(0.04), 8)
		b.add("sphere", hp + Vector3(0, 0.2, 0), Vector3(0.1, 0.12, 0.1), DARK, Vector3.ZERO, 6)
		heads.append(hp + Vector3(sin(a) * 0.12, -0.02, -cos(a) * 0.12))
	b.add("torus", Vector3(0, 8.45, 0.0), Vector3(1.3, 0.06, 1.05), DARK, Vector3.ZERO, 24)   # küçük başları taşıyan taç halkası
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	body.add_child(mi)
	# hale: gövdenin ardında büyük halka (ref)
	var hb = MB.new()
	hb.add("torus", Vector3(0, 7.4, 0.55), Vector3(5.0, 0.2, 5.0), DARK, Vector3(90, 0, 0), 40)
	hb.add("cyl", Vector3(0, 7.4, 0.62), Vector3(4.6, 0.06, 4.6), WOOD.darkened(0.1), Vector3(90, 0, 0), 40)
	var hmi = MeshInstance3D.new()
	hmi.mesh = hb.build(Props.toon())
	body.add_child(hmi)
	# haleden ışın gibi açılan iki sıra uzun kol
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = ShinSusenju.arm_mesh()
	var xfs = []
	var c = Vector3(0, 7.4, 0.7)
	for r in 2:
		var n = 22 + r * 8
		var L = 2.6 + r * 1.4
		for k in n:
			var a = (k + 0.5 * r) / float(n) * TAU
			var dir = Vector3(cos(a), sin(a), 0.12 + r * 0.08).normalized()
			var origin = c + Vector3(cos(a), sin(a), 0) * (2.3 + r * 0.25)
			var yb = dir
			var xb = Vector3.BACK.cross(yb).normalized()
			var zb = xb.cross(yb).normalized()
			xfs.append(Transform3D(Basis(xb * L * 1.1, yb * L, zb * L * 1.1), origin))
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	fan_xf = xfs
	var fan = MultiMeshInstance3D.new()
	fan.multimesh = mm
	fan.material_override = Props.toon_color(WOOD)   # kollar gövdeyle aynı kahverengi tahta (ref)
	body.add_child(fan)


func head_world(i: int) -> Vector3:
	return body.global_transform * (heads[i] as Vector3)


func random_hand_world() -> Vector3:
	var xf: Transform3D = fan_xf[randi() % fan_xf.size()]
	return body.global_transform * (xf * Vector3(0, 0.95, 0))
