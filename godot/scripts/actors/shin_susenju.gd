class_name ShinSusenju
extends Node3D
## Senpō Mokuton: Shin Sūsenju (kanon, Hashirama; ref _tmp/susenjuref): tam boy Kurama'yı ve tam beden Susanoo'yu cüce bırakan
## titanik tahta heykel — lotus oturuşunda, iki ana eli göğsünün önünde dua eder gibi birleşik, başının ardında hale; sırtından
## eş merkezli sıralar hâlinde binlerce kol tavus kuyruğu gibi açılır (her kolun bileğinde bant halkası, ucunda açık el).
## Saldırı: Chōjō Kebutsu (eller yağmur gibi iner). Boy ~450 m. Tasarım: toplam yükseklik 10 birim, ön -Z.

const H := 450.0
const WOOD := Color(0.55, 0.54, 0.42)
const DARK := Color(0.38, 0.37, 0.28)

var body: Node3D
var fan: MultiMeshInstance3D
var fan_xf: Array = []   # her kolun tasarım dönüşümü (eller yağmurunda başlangıç noktası)
static var _arm_mesh: ArrayMesh


static func spawn(parent: Node, at: Vector3, yaw: float) -> ShinSusenju:
	var s = ShinSusenju.new()
	parent.add_child(s)
	s.global_position = at
	s.rotation.y = yaw
	return s


func _ready() -> void:
	body = Node3D.new()
	add_child(body)
	_build_body()
	_build_fan()
	body.scale = Vector3.ONE * (H / 10.0)


func _mi(b: MB) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	body.add_child(mi)
	return mi


## Tek kol (birim uzunluk, +Y boyunca): ön kol + bilek bandı + açık el ve beş parmak — kuyruktaki tüm kollar bunun kopyası
static func arm_mesh() -> ArrayMesh:
	if _arm_mesh != null:
		return _arm_mesh
	var b = MB.new()
	Loft.tube(b, [Vector3(0, 0, 0), Vector3(0, 0.45, 0), Vector3(0, 0.8, 0)], [0.075, 0.065, 0.058], WOOD, 8, 2)
	b.add("cyl", Vector3(0, 0.78, 0), Vector3(0.14, 0.04, 0.14), DARK, Vector3.ZERO, 10)   # bilek bandı (ref)
	Loft.blob(b, Vector3(0, 0.86, 0), Vector3(0, 1, 0), 0.12, [Vector2(0.05, 0.02), Vector2(0.065, 0.025), Vector2(0.06, 0.022), Vector2(0.05, 0.018)], WOOD, 8)
	for f in 4:
		var fx = lerpf(-0.045, 0.045, f / 3.0)
		Loft.tube(b, [Vector3(fx, 0.96, 0), Vector3(fx * 1.25, 1.03, 0.005), Vector3(fx * 1.4, 1.09, 0.012)], [0.014, 0.012, 0.008], WOOD, 5, 2)
	Loft.tube(b, [Vector3(0.06, 0.88, 0), Vector3(0.1, 0.94, 0.01), Vector3(0.12, 0.99, 0.02)], [0.016, 0.013, 0.008], WOOD, 5, 2)
	_arm_mesh = b.build(Props.toon())
	return _arm_mesh


func _build_body() -> void:
	var b = MB.new()
	# lotus oturuşu: bağdaş kurmuş bacaklar (geniş yassı kütle) + kaide
	b.add("cyl", Vector3(0, 0.25, 0.1), Vector3(5.6, 0.5, 4.2), DARK, Vector3.ZERO, 24)   # lotus kaidesi
	for s in [-1.0, 1.0]:
		Loft.tube(b, [Vector3(s * 1.9, 0.75, 0.2), Vector3(s * 0.9, 0.8, -0.65), Vector3(-s * 0.4, 0.75, -0.75)], [0.55, 0.5, 0.42], WOOD, 12, 3)   # bağdaş bacaklar
	# gövde: dik, geniş omuzlu
	Loft.tube(b, [Vector3(0, 0.8, 0.2), Vector3(0, 1.9, 0.15), Vector3(0, 3.2, 0.1), Vector3(0, 4.1, 0.0), Vector3(0, 4.55, 0.0)], [Vector2(1.5, 1.0), Vector2(1.4, 0.95), Vector2(1.6, 1.0), Vector2(1.75, 0.95), Vector2(0.6, 0.5)], WOOD, 20, 4)
	for s in [-1.0, 1.0]:
		Loft.blob(b, Vector3(s * 1.75, 4.05, 0.0), Vector3(s * 0.4, -1, 0), 1.0, [Vector2(0.2, 0.2), Vector2(0.5, 0.48), Vector2(0.45, 0.42), Vector2(0.18, 0.18)], WOOD, 12)
		# ana kollar: omuzdan inip göğsün önünde dua eden ellerde birleşir
		Loft.tube(b, [Vector3(s * 1.95, 3.95, 0.0), Vector3(s * 1.9, 3.0, -0.35), Vector3(s * 0.9, 2.75, -1.05), Vector3(s * 0.15, 3.15, -1.2)], [0.42, 0.38, 0.34, 0.3], WOOD, 12, 3)
		b.add("cyl", Vector3(s * 0.55, 2.9, -1.12), Vector3(0.62, 0.12, 0.62), DARK, Vector3(0, 0, s * 70), 12)   # bilek bandı
	# birleşik dua eden avuçlar (dik, parmaklar yukarı)
	Loft.blob(b, Vector3(0, 3.25, -1.25), Vector3(0, 1, -0.1), 1.1, [Vector2(0.28, 0.22), Vector2(0.36, 0.26), Vector2(0.3, 0.22), Vector2(0.12, 0.1)], WOOD, 12)
	# boyun + baş (Buda: topuz, uzun kulak memeleri, kapalı gözler)
	Loft.tube(b, [Vector3(0, 4.4, 0.0), Vector3(0, 4.85, -0.05)], [0.5, 0.45], WOOD, 12, 2)
	Loft.blob(b, Vector3(0, 4.85, -0.05), Vector3(0, 1, 0), 1.35, [Vector2(0.55, 0.55), Vector2(0.72, 0.7), Vector2(0.66, 0.64), Vector2(0.32, 0.3)], WOOD, 16)
	Loft.blob(b, Vector3(0, 6.05, 0.0), Vector3(0, 1, 0), 0.55, [Vector2(0.3, 0.3), Vector2(0.38, 0.38), Vector2(0.3, 0.3), Vector2(0.1, 0.1)], DARK, 12)   # topuz (uşnişa)
	for s in [-1.0, 1.0]:
		Loft.blob(b, Vector3(s * 0.7, 5.25, 0.05), Vector3(0, -1, 0), 0.9, [Vector2(0.1, 0.06), Vector2(0.14, 0.08), Vector2(0.13, 0.07), Vector2(0.1, 0.05)], WOOD, 8)   # uzun kulak
		Loft.tube(b, [Vector3(s * 0.12, 5.55, -0.66), Vector3(s * 0.28, 5.52, -0.66), Vector3(s * 0.42, 5.56, -0.6)], [0.025, 0.03, 0.02], DARK, 6, 2)   # kapalı göz yayı
	Loft.blob(b, Vector3(0, 5.45, -0.68), Vector3(0, -0.8, -0.6), 0.32, [Vector2(0.06, 0.05), Vector2(0.1, 0.08), Vector2(0.11, 0.08), Vector2(0.06, 0.04)], WOOD, 8)   # burun
	b.add("box", Vector3(0, 5.12, -0.68), Vector3(0.22, 0.03, 0.03), DARK)   # sakin ağız
	b.add("sphere", Vector3(0, 5.8, -0.66), Vector3(0.08, 0.08, 0.04), DARK, Vector3.ZERO, 8)   # alın beni (ürna)
	_mi(b)
	# hale: başın ardında halka + gövdenin ardında büyük daire (ref: figürü çevreleyen yuvarlak ışık çerçevesi)
	var hb = MB.new()
	hb.add("torus", Vector3(0, 5.4, 0.55), Vector3(2.4, 0.12, 2.4), DARK, Vector3(90, 0, 0), 32)
	hb.add("torus", Vector3(0, 3.4, 0.8), Vector3(5.2, 0.18, 5.2), DARK, Vector3(90, 0, 0), 40)
	for k in 24:   # hale çerçevesindeki alev/ışın çentikleri
		var a = k * TAU / 24.0
		hb.add("box", Vector3(cos(a) * 2.65, 3.4 + sin(a) * 2.65, 0.8), Vector3(0.12, 0.38, 0.06), DARK, Vector3(0, 0, rad_to_deg(a) - 90))
	_mi(hb)


## Sırttan eş merkezli sıralar hâlinde açılan binlerce kol: her sıra bir yarım daire yayı, dış sıralar daha uzun
func _build_fan() -> void:
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = arm_mesh()
	var rows = 12   # ref: kuyruk figürü cüce bırakır (2-3 kat yüksek ve geniş)
	var xfs = []
	var pivot = Vector3(0, 3.5, 1.3)
	for r in rows:
		var n = 28 + r * 7
		var L = 3.4 + r * 0.6
		for k in n:
			var a = lerpf(-1.85, 1.85, (k + 0.5 * (r % 2)) / float(n))   # dikeyden açı (yarım daireden geniş)
			var dir = Vector3(sin(a), cos(a) * 0.95 + 0.1, 0.25 + r * 0.05).normalized()
			var origin = pivot + Vector3(sin(a) * 0.9, cos(a) * 0.6, 0.2 + r * 0.12)
			var yb = dir
			var xb = Vector3.BACK.cross(yb).normalized()
			if xb.length() < 0.1:
				xb = Vector3.RIGHT
			var zb = xb.cross(yb).normalized()
			var basis = Basis(xb * L * 1.1, yb * L, zb * L * 1.1)
			xfs.append(Transform3D(basis, origin))
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	fan_xf = xfs
	fan = MultiMeshInstance3D.new()
	fan.multimesh = mm
	body.add_child(fan)


## Kuyruktaki rastgele bir elin dünya konumu (Chōjō Kebutsu: eller oradan kopup hedefe iner)
func random_hand_world() -> Vector3:
	var xf: Transform3D = fan_xf[randi() % fan_xf.size()]
	return body.global_transform * (xf * Vector3(0, 0.95, 0))
