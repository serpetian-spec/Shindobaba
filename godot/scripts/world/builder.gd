class_name Builder
extends RefCounted
## Köy/yer inşa yardımcısı. Yerel koordinat: (x=doğu, y=yukarı, n=kuzey) merkez etrafında.
## Görseller 128 m hücrelere göre birleştirilir, çarpışmalar StaticBody3D kutularıdır.

const CELL := 128.0

var root: Node3D
var origin: Vector3  # Godot dünya konumu (merkez, taban yüksekliği)
var cells = {}
var body: StaticBody3D
var view_dist = 1400.0
var interactables: Array = []
var key := ""
var placer = null  # HouseKit.Placer (Japon tarzı detaylı evler)
var last_house := {}  # son yerleştirilen şablon ev (w, d, h, roof_top)

static var roof_points := {}  # köy id -> [çatı tepe noktaları] (çatıdan çatıya koşan ninjalar için)


func _init(parent: Node3D, map_x: float, map_y: float, base_h: float, name := "Yapi") -> void:
	root = Node3D.new()
	root.name = name
	key = name.to_lower()
	parent.add_child(root)
	origin = Vector3(map_x, base_h, -map_y)
	body = StaticBody3D.new()
	body.collision_layer = 1
	root.add_child(body)


## yerel (x, y, n) -> Godot dünya
func w(p: Vector3) -> Vector3:
	return origin + Vector3(p.x, p.y, -p.z)


func _mb(wp: Vector3) -> MB:
	var key = Vector2i(int(floor(wp.x / CELL)), int(floor(wp.z / CELL)))
	if not cells.has(key):
		cells[key] = MB.new()
	return cells[key]


func _collide(center: Vector3, size: Vector3, yaw_deg: float) -> void:
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), center)
	body.add_child(cs)


func _collide_cyl(center: Vector3, r: float, h: float) -> void:
	var cs = CollisionShape3D.new()
	var sh = CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	cs.position = center
	body.add_child(cs)


## p: yerel taban-merkez değil, MERKEZ. yaw: derece (kuzeyden doğuya). Godot'da y ekseni etrafında -yaw.
func box(p: Vector3, size: Vector3, col: Color, yaw := 0.0, collide := true, rot := Vector3.ZERO) -> void:
	var wp = w(p)
	_mb(wp).add("box", wp, size, col, Vector3(rot.x, -yaw + rot.y, rot.z))
	if collide:
		_collide(wp, size, -yaw)


func cyl(p: Vector3, d: float, h: float, col: Color, collide := true, seg := 16, top := -1.0) -> void:
	var wp = w(p)
	if top >= 0.0:
		_mb(wp).add_xf("cone", Transform3D(Basis.IDENTITY.scaled(Vector3(d, h, d)), wp), col, seg)
	else:
		_mb(wp).add("cyl", wp, Vector3(d, h, d), col, Vector3.ZERO, seg)
	if collide:
		_collide_cyl(wp, d * 0.5, h)


func cone(p: Vector3, d: float, h: float, col: Color, seg := 16, collide := false) -> void:
	var wp = w(p)
	_mb(wp).add("cone", wp, Vector3(d, h, d), col, Vector3.ZERO, seg)
	if collide:
		_collide_cyl(wp - Vector3(0, h * 0.25, 0), d * 0.3, h * 0.5)


func sphere(p: Vector3, size: Vector3, col: Color, seg := 12, collide := false) -> void:
	var wp = w(p)
	_mb(wp).add("sphere", wp, size, col, Vector3.ZERO, seg)
	if collide:
		_collide(wp, size * 0.75, 0.0)


## Dikey disk (arma/plaka): ön yüzü yaw yönüne (yerel -n) bakar
func disc(p: Vector3, d: float, thick: float, col: Color, yaw := 0.0, seg := 16) -> void:
	var wp = w(p)
	_mb(wp).add("cyl", wp, Vector3(d, thick, d), col, Vector3(90, -yaw, 0), seg)


func dome(p: Vector3, d: float, h: float, col: Color, seg := 16) -> void:
	var wp = w(p)
	_mb(wp).add("hemi", wp, Vector3(d, h * 2.0, d), col, Vector3.ZERO, seg)  # yarım küre tabanı y=0, tepe h


## Çatı: üçgen prizma (yaw ile döner). p: çatı tabanının merkezi
func roof(p: Vector3, size: Vector3, col: Color, yaw := 0.0) -> void:
	var wp = w(p) + Vector3(0, size.y * 0.5, 0)
	_mb(wp).add("prism", wp, size, col, Vector3(0, -yaw, 0))
	_collide(wp - Vector3(0, size.y * 0.25, 0), Vector3(size.x * 0.7, size.y * 0.5, size.z), -yaw)


## Yerel uzayda döndürülmüş ofset
static func rot(lx: float, ln: float, yaw: float) -> Vector2:
	var a = deg_to_rad(yaw)
	return Vector2(lx * cos(a) + ln * sin(a), -lx * sin(a) + ln * cos(a))


func interact(p: Vector3, radius: float, kind: String, label: String, data := {}) -> void:
	var d = {"pos": w(p), "radius": radius, "kind": kind, "label": label}
	d.merge(data)
	Interact.add(d)


func finish() -> void:
	if placer != null:
		placer.finish()
	for key in cells:
		var mb: MB = cells[key]
		if mb.is_empty():
			continue
		var mi = MeshInstance3D.new()
		mi.mesh = mb.build(Props.toon())
		mi.visibility_range_end = view_dist * float(Game.settings["view"])
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		mi.visibility_range_end_margin = 60.0
		root.add_child(mi)
	cells.clear()


# ------------------------------------------------------------------ hazır yapılar
## Japon tarzı ev. style: konoha | suna | kiri | iwa | kumo | ame | wood | snow
func house(x: float, n: float, wdt: float, dep: float, floors: int, yaw: float, style: String, rng: RandomNumberGenerator) -> void:
	var hgt = floors * 4.2
	match style:
		"suna":
			var c = Color(0.86, 0.74, 0.55).darkened(rng.randf_range(0, 0.12))
			var d = maxf(wdt, dep)
			cyl(Vector3(x, hgt * 0.5, n), d, hgt, c, true, 16)
			dome(Vector3(x, hgt, n), d, d * 0.35, c.lightened(0.05), 16)
			for k in 4:
				var o = rot(0, d * 0.5, yaw + k * 90)
				cyl(Vector3(x + o.x, hgt * 0.6, n + o.y), 1.3, 1.3, Color(0.25, 0.2, 0.15), false, 8)
			return
		"kiri":
			var c = Color(0.62, 0.7, 0.74).darkened(rng.randf_range(0, 0.15))
			var d = maxf(wdt, dep)
			cyl(Vector3(x, hgt * 0.5, n), d, hgt, c, true, 14)
			dome(Vector3(x, hgt, n), d + 0.8, d * 0.3, Color(0.35, 0.45, 0.55), 14)
			cyl(Vector3(x, hgt + d * 0.3 + 0.8, n), 0.8, 1.6, Color(0.5, 0.55, 0.6), false, 8)
			return
		"iwa", "rock":
			var c = Color(0.55, 0.47, 0.38).darkened(rng.randf_range(0, 0.15))
			box(Vector3(x, hgt * 0.5, n), Vector3(wdt, hgt, dep), c, yaw)
			box(Vector3(x, hgt + 0.4, n), Vector3(wdt + 1, 0.8, dep + 1), Color(0.42, 0.32, 0.25), yaw)
			return
		"ame":
			var c = Color(0.42, 0.44, 0.47).darkened(rng.randf_range(0, 0.1))
			box(Vector3(x, hgt * 0.5, n), Vector3(wdt, hgt, dep), c, yaw)
			for k in floors:
				box(Vector3(x, k * 4.2 + 2.6, n), Vector3(wdt + 0.3, 0.3, dep + 0.3), Color(0.3, 0.31, 0.33), yaw)
			var po = rot(wdt * 0.5 + 0.4, 0, yaw)
			cyl(Vector3(x + po.x, hgt * 0.5, n + po.y), 0.6, hgt, Color(0.35, 0.36, 0.38), false, 8)
			return
	# konoha / ahşap / kar: detaylı şablon evler (HouseKit)
	var walls = [Color(0.96, 0.92, 0.84), Color(0.93, 0.87, 0.72), Color(0.98, 0.96, 0.9), Color(0.9, 0.84, 0.7), Color(0.86, 0.8, 0.7), Color(0.95, 0.88, 0.8)]
	var roofs = [Color(0.78, 0.22, 0.18), Color(0.22, 0.4, 0.62), Color(0.28, 0.52, 0.32), Color(0.85, 0.45, 0.18), Color(0.5, 0.32, 0.58), Color(0.65, 0.2, 0.24), Color(0.35, 0.35, 0.4)]
	if placer == null:
		placer = HouseKit.Placer.new(root, key)
		placer.view = view_dist
	var wcol: Color = walls[rng.randi() % walls.size()]
	var rcol: Color = roofs[rng.randi() % roofs.size()]
	if style == "wood":
		wcol = Color(0.62, 0.47, 0.32).darkened(rng.randf_range(0, 0.2))
	elif style == "snow":
		rcol = Color(0.93, 0.95, 0.98)
	last_house = placer.add(w(Vector3(x, 0, n)), yaw, wcol, rcol, rng)
	return
	var wc: Color = walls[rng.randi() % walls.size()]
	if style == "wood":
		wc = Color(0.6, 0.45, 0.3).darkened(rng.randf_range(0, 0.2))
	var rc: Color = roofs[rng.randi() % roofs.size()]
	if style == "snow":
		rc = Color(0.93, 0.95, 0.98)
	box(Vector3(x, hgt * 0.5, n), Vector3(wdt, hgt, dep), wc, yaw)
	if not roof_points.has(key):
		roof_points[key] = []
	roof_points[key].append(w(Vector3(x, hgt + 0.7, n)))
	if floors >= 2 and rng.randf() < 0.3:  # çamaşır ipi (balkondan)
		var lo = rot(-wdt * 0.35, -dep * 0.5 - 1.0, yaw)
		var ro2 = rot(wdt * 0.35, -dep * 0.5 - 1.0, yaw)
		var mid = rot(0, -dep * 0.5 - 1.0, yaw)
		box(Vector3(x + lo.x, 5.6, n + lo.y), Vector3(0.08, 2.2, 0.08), Color(0.4, 0.3, 0.2), yaw, false)
		box(Vector3(x + ro2.x, 5.6, n + ro2.y), Vector3(0.08, 2.2, 0.08), Color(0.4, 0.3, 0.2), yaw, false)
		box(Vector3(x + mid.x, 6.6, n + mid.y), Vector3(wdt * 0.7, 0.03, 0.03), Color(0.9, 0.9, 0.9), yaw, false)
		for k in 4:
			var co = rot(-wdt * 0.25 + k * wdt * 0.17, -dep * 0.5 - 1.0, yaw)
			var cc = [Color(0.9, 0.9, 0.95), Color(0.3, 0.45, 0.75), Color(0.85, 0.35, 0.3), Color(0.95, 0.8, 0.4)][rng.randi() % 4]
			box(Vector3(x + co.x, 6.1, n + co.y), Vector3(0.9, 1.0, 0.04), cc, yaw, false)
	# Konoha: yuvarlatılmış/düz çatı + su tankı veya beşik çatı
	if rng.randf() < 0.55 and style == "konoha":
		box(Vector3(x, hgt + 0.35, n), Vector3(wdt + 1.2, 0.7, dep + 1.2), rc, yaw)
		if rng.randf() < 0.7:
			var o = rot(rng.randf_range(-wdt * 0.25, wdt * 0.25), rng.randf_range(-dep * 0.25, dep * 0.25), yaw)
			cyl(Vector3(x + o.x, hgt + 1.9, n + o.y), 2.4, 2.4, Color(0.62, 0.66, 0.7), true, 12)
			cyl(Vector3(x + o.x, hgt + 3.2, n + o.y), 2.6, 0.3, Color(0.5, 0.52, 0.55), false, 12)
	else:
		roof(Vector3(x, hgt, n), Vector3(wdt + 1.6, 2.8, dep + 1.4), rc, yaw)
	# ön cephe: kapı + pencereler + tente
	var front = rot(0, -dep * 0.5 - 0.06, yaw)
	box(Vector3(x + front.x, 1.25, n + front.y), Vector3(1.6, 2.5, 0.12), Color(0.35, 0.24, 0.16), yaw, false)
	var awn = rot(0, -dep * 0.5 - 0.7, yaw)
	box(Vector3(x + awn.x, 2.9, n + awn.y), Vector3(3.2, 0.15, 1.4), rc.darkened(0.15), yaw, false, Vector3(-12, 0, 0))
	for f in floors:
		for sx in [-1.0, 1.0]:
			var wo = rot(sx * wdt * 0.3, -dep * 0.5 - 0.06, yaw)
			box(Vector3(x + wo.x, f * 4.2 + 2.6, n + wo.y), Vector3(1.4, 1.2, 0.1), Color(0.42, 0.62, 0.78), yaw, false)
			box(Vector3(x + wo.x, f * 4.2 + 1.95, n + wo.y), Vector3(1.6, 0.12, 0.25), wc.darkened(0.2), yaw, false)
	if floors > 1:  # balkon
		var bo = rot(0, -dep * 0.5 - 0.6, yaw)
		box(Vector3(x + bo.x, 4.2, n + bo.y), Vector3(wdt * 0.7, 0.2, 1.2), wc.darkened(0.15), yaw)


## Yerel (x, n) çevresinde arazinin köy tabanına göre en düşük/en yüksek ofseti (duvarlar araziye otursun)
func _ground_off(x: float, n: float, rad: float) -> Vector2:
	var lo = 1e9
	var hi = -1e9
	for o in [Vector2.ZERO, Vector2(rad, 0), Vector2(-rad, 0), Vector2(0, rad), Vector2(0, -rad)]:
		var wp = w(Vector3(x + o.x, 0, n + o.y))
		var gh = Game.terrain_height(wp.x, wp.z) - origin.y
		lo = minf(lo, gh)
		hi = maxf(hi, gh)
	return Vector2(lo, hi)


## Dairesel duvar halkası. gaps: [[açı, genişlik derece]]
func wall_ring(r: float, h: float, thick: float, col: Color, gaps: Array, step := 4.0, top_col := Color(0.5, 0.2, 0.15)) -> void:
	var a = 0.0
	while a < 360.0:
		var mid = a + step * 0.5
		var skip = false
		for g in gaps:
			var d = absf(fmod(mid - g[0] + 540.0, 360.0) - 180.0)
			if d < g[1] * 0.5:
				skip = true
		if not skip:
			var rad = deg_to_rad(mid)
			var L = 2.0 * PI * r * step / 360.0 + 0.4
			var g = _ground_off(r * sin(rad), r * cos(rad), L * 0.5)
			var bot = minf(g.x, 0.0) - 2.0
			var top = g.y + h
			box(Vector3(r * sin(rad), (bot + top) * 0.5, r * cos(rad)), Vector3(L, top - bot, thick), col, mid)
			box(Vector3(r * sin(rad), top + 0.4, r * cos(rad)), Vector3(L, 0.8, thick + 0.8), top_col, mid, false)
		a += step


func tree(x: float, n: float, s: float, rng: RandomNumberGenerator, y := 0.0) -> void:
	cyl(Vector3(x, y + 2.6 * s, n), 0.7 * s, 5.2 * s, Color(0.42, 0.29, 0.18), true, 7)
	var g = Color(0.28, 0.55, 0.22).lightened(rng.randf_range(-0.05, 0.08))
	sphere(Vector3(x, y + 6.6 * s, n), Vector3(5.2, 4.0, 5.2) * s, g, 9)
	sphere(Vector3(x + 1.5 * s, y + 6.0 * s, n + 0.6 * s), Vector3(3.4, 2.8, 3.4) * s, g.darkened(0.08), 8)
	sphere(Vector3(x - 1.2 * s, y + 7.6 * s, n - 0.6 * s), Vector3(3.2, 2.6, 3.2) * s, g.lightened(0.05), 8)


func lantern(x: float, n: float, h := 3.2) -> void:
	box(Vector3(x, h * 0.5, n), Vector3(0.2, h, 0.2), Color(0.3, 0.22, 0.15), 0, false)
	box(Vector3(x, h + 0.35, n), Vector3(0.6, 0.7, 0.6), Color(1.0, 0.85, 0.55), 0, false)
	Lights.add(w(Vector3(x, h + 0.35, n)))


## Merkezi (cx, cn) olan dairesel duvar
func wall_ring_at(cx: float, cn: float, r: float, h: float, col: Color, gaps: Array, step := 6.0) -> void:
	var a = 0.0
	while a < 360.0:
		var mid = a + step * 0.5
		var skip = false
		for g in gaps:
			if absf(fmod(mid - g[0] + 540.0, 360.0) - 180.0) < g[1] * 0.5:
				skip = true
		if not skip:
			var rad = deg_to_rad(mid)
			var L = 2.0 * PI * r * step / 360.0 + 0.3
			var g = _ground_off(cx + r * sin(rad), cn + r * cos(rad), L * 0.5)
			var bot = minf(g.x, 0.0) - 1.0
			box(Vector3(cx + r * sin(rad), (bot + g.y + h) * 0.5, cn + r * cos(rad)), Vector3(L, g.y + h - bot, 1.0), col, mid)
		a += step


## Dikdörtgen avlu duvarı (güneyde kapı boşluğu)
func wall_rect(cx: float, cn: float, wd: float, dp: float, h: float, col: Color, gate := 10.0) -> void:
	box(Vector3(cx, h * 0.5, cn + dp * 0.5), Vector3(wd, h, 1), col)
	box(Vector3(cx - wd * 0.5, h * 0.5, cn), Vector3(1, h, dp), col)
	box(Vector3(cx + wd * 0.5, h * 0.5, cn), Vector3(1, h, dp), col)
	var side = (wd - gate) * 0.5
	box(Vector3(cx - gate * 0.5 - side * 0.5, h * 0.5, cn - dp * 0.5), Vector3(side, h, 1), col)
	box(Vector3(cx + gate * 0.5 + side * 0.5, h * 0.5, cn - dp * 0.5), Vector3(side, h, 1), col)
