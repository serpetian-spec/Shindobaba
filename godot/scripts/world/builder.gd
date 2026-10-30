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
var yoff := 0.0  # geçici dikey ofset (eğimli arazide bina tabanı)
var packs := {}  # hücre+mesh -> [mesh, Array[Transform3D]] (hazır modeller: MultiMesh)
var last_house := {}  # son yerleştirilen şablon ev (w, d, h, roof_top)
var houses: Array = []  # [x, n, gen, der, yaw, taban, stil] (peyzaj bahçeleri için)
var solids := {}  # 16 m ızgara (dünya xz) -> [[cx, cz, yarı_x, yarı_z, açı]] (peyzaj çakışma kontrolü)
var landscape := true  # finish()'te yeterince ev varsa CityLandscape ile bahçe/sokak ağacı/park
const SCELL := 16.0
static var _tree_mesh: Mesh
static var landscape_on := true  # testlerde karşılaştırma için kapatılabilir

static var roof_points := {}  # köy id -> [çatı tepe noktaları] (çatıdan çatıya koşan ninjalar için)


func _init(parent: Node3D, map_x: float, map_y: float, base_h: float, name := "Yapi") -> void:
	root = Node3D.new()
	root.name = name
	key = name.to_lower()
	parent.add_child(root)
	origin = Vector3(map_x, base_h, -map_y)
	body = StaticBody3D.new()
	body.collision_layer = 1
	# gövde sahneye finish()'te eklenir: ağaçtaki bir gövdeye her şekil eklemek fizik sunucusunda tüm şekilleri
	# yeniden kurar (O(n²)); Konoha'nın ~20 bin kutusu açılışı ~40 sn uzatıyordu
	root.tree_exiting.connect(func(): if is_instance_valid(body) and body.get_parent() == null: body.free())


## yerel (x, y, n) -> Godot dünya
func w(p: Vector3) -> Vector3:
	return origin + Vector3(p.x, p.y + yoff, -p.z)


func _mb(wp: Vector3) -> MB:
	var key = Vector2i(int(floor(wp.x / CELL)), int(floor(wp.z / CELL)))
	if not cells.has(key):
		cells[key] = MB.new()
	return cells[key]


func _collide(center: Vector3, size: Vector3, yaw_deg: float) -> void:
	if not is_instance_valid(body):
		return  # akışla kurulan yer yarıda silindi
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), center)
	body.add_child(cs)
	add_solid(center, size.x * 0.5, size.z * 0.5, deg_to_rad(yaw_deg))


func _collide_cyl(center: Vector3, r: float, h: float) -> void:
	if not is_instance_valid(body):
		return
	var cs = CollisionShape3D.new()
	var sh = CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	cs.position = center
	body.add_child(cs)
	add_solid(center, r, r, 0.0)


## Çakışma ızgarasına dönmüş dikdörtgen ekle (dünya merkezi, yarı boyutlar, Godot y açısı)
func add_solid(center: Vector3, hx: float, hz: float, ang: float) -> void:
	var e = maxf(hx, hz) * 1.415
	var x0 = floori((center.x - e) / SCELL); var x1 = floori((center.x + e) / SCELL)
	var z0 = floori((center.z - e) / SCELL); var z1 = floori((center.z + e) / SCELL)
	if (x1 - x0 + 1) * (z1 - z0 + 1) > 400:
		return  # çok büyük düz alanlar (meydan zemini vb.) kontrolü boğmasın
	var rec = [center.x, center.z, hx, hz, ang]
	for cx in range(x0, x1 + 1):
		for cz in range(z0, z1 + 1):
			var k = Vector2i(cx, cz)
			if not solids.has(k):
				solids[k] = []
			solids[k].append(rec)


## Dünya xz noktası çevresinde r yarıçaplı daire hiçbir çarpışma kutusuna değmiyor mu
func area_free(p: Vector2, r: float) -> bool:
	for cx in range(floori((p.x - r) / SCELL), floori((p.x + r) / SCELL) + 1):
		for cz in range(floori((p.y - r) / SCELL), floori((p.y + r) / SCELL) + 1):
			var lst = solids.get(Vector2i(cx, cz))
			if lst == null:
				continue
			for rec in lst:
				var dx: float = p.x - rec[0]
				var dz: float = p.y - rec[1]
				var a: float = rec[4]
				var ca = cos(a); var sa = sin(a)
				var lx = absf(ca * dx - sa * dz) - rec[2]
				var lz = absf(sa * dx + ca * dz) - rec[3]
				if Vector2(maxf(lx, 0.0), maxf(lz, 0.0)).length() < r:
					return false
	return true


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


## Pürüzlü katmanlı kaya sütunu (Kumo/Iwa kuleleri, krater duvarı). p: taban merkezi
func crag(p: Vector3, d: float, h: float, col: Color, variant := 0, collide := true, yaw := 0.0) -> void:
	var wp = w(p)
	_mb(wp).add("crag", wp + Vector3(0, h * 0.5, 0), Vector3(d, h, d), col, Vector3(0, yaw, 0), (100 + variant % 16) if variant >= 100 else variant % 16)
	if collide:
		_collide_cyl(wp + Vector3(0, h * 0.5, 0), d * 0.38, h)


## Düzensiz kaya. p: merkez
func boulder(p: Vector3, size: Vector3, col: Color, variant := 0, collide := false, yaw := 0.0) -> void:
	var wp = w(p)
	_mb(wp).add("boulder", wp, size, col, Vector3(0, yaw, 0), variant % 16)
	if collide:
		_collide(wp, size * 0.8, yaw)


## Yukarı daralan silindir (kule gövdesi). p: merkez
func frustum(p: Vector3, d: float, h: float, col: Color, collide := true, seg := 16) -> void:
	var wp = w(p)
	_mb(wp).add("frustum", wp, Vector3(d, h, d), col, Vector3.ZERO, seg)
	if collide:
		_collide_cyl(wp, d * 0.43, h)


static var _kanji_font: SystemFont
## Büyük kanji tabelası (風 雷 水 土...): ön yüzü yaw yönüne bakar
func kanji(p: Vector3, text: String, size: float, col: Color, yaw := 0.0) -> void:
	if not is_instance_valid(root):
		return
	if _kanji_font == null:
		_kanji_font = SystemFont.new()
		_kanji_font.font_names = PackedStringArray(["Yu Gothic UI", "Yu Gothic", "Meiryo", "MS Gothic", "Noto Sans CJK JP", "Microsoft YaHei"])
		_kanji_font.font_weight = 800
	var l = Label3D.new()
	l.text = text
	l.font = _kanji_font
	l.font_size = 128
	l.pixel_size = size / 128.0
	l.modulate = col
	l.outline_size = 0
	l.double_sided = false
	l.shaded = false
	l.visibility_range_end = view_dist
	root.add_child(l)
	l.global_position = w(p)
	l.rotation.y = deg_to_rad(-yaw)


## Yerel uzayda döndürülmüş ofset
static func rot(lx: float, ln: float, yaw: float) -> Vector2:
	var a = deg_to_rad(yaw)
	return Vector2(lx * cos(a) + ln * sin(a), -lx * sin(a) + ln * cos(a))


var defer_interact = null   # Array ise etkileşimler buraya toplanır (iş parçacığında kurulum)


func interact(p: Vector3, radius: float, kind: String, label: String, data := {}) -> void:
	var d = {"pos": w(p), "radius": radius, "kind": kind, "label": label}
	d.merge(data)
	if defer_interact != null:
		defer_interact.append(d)
	else:
		Interact.add(d)


func finish() -> void:
	if not is_instance_valid(root):
		return
	if is_instance_valid(body) and body.get_parent() == null:
		root.add_child(body)
	if landscape and landscape_on and houses.size() >= 12 and not key.begins_with("yolkenari"):
		landscape = false
		CityLandscape.dress(self)
	if placer != null:
		placer.finish()
	for pk in packs:
		var pe: Array = packs[pk]
		var xfs: Array = pe[1]
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = pe[0]
		mm.instance_count = xfs.size()
		for i in xfs.size():
			mm.set_instance_transform(i, xfs[i])
			mm.set_instance_color(i, Color.WHITE)
		var mmi = MultiMeshInstance3D.new()
		mmi.layers = 2
		mmi.multimesh = mm
		mmi.visibility_range_end = view_dist * float(Game.settings["view"]) * float(pe[2])
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		mmi.visibility_range_end_margin = 60.0
		root.add_child(mmi)
	packs.clear()
	for key in cells:
		var mb: MB = cells[key]
		if mb.is_empty():
			continue
		var mi = MeshInstance3D.new()
		mi.layers = 2  # yapılar: sokak fenerleri (yalnız katman 1) bunları aydınlatmaz
		mi.mesh = mb.build(Props.toon())
		# görünürlük mesafesi parçanın merkezinden ölçülür: dev parçalar (Suna sur kayalıkları, uzun duvarlar) yanındayken bile
		# uzak merkezleri yüzünden yarı saydam soluyordu (çarpışma durduğu için "şeffaf ama yürünen duvar") — parça boyu kadar uzat
		mi.visibility_range_end = view_dist * float(Game.settings["view"]) + mi.mesh.get_aabb().size.length() * 0.6
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		mi.visibility_range_end_margin = 60.0
		root.add_child(mi)
	cells.clear()


# ------------------------------------------------------------------ hazır yapılar
## Japon tarzı ev. style: konoha | suna | kiri | iwa | kumo | ame | wood | snow
## Bina arazinin üstüne oturur: taban = ayak izindeki en yüksek nokta, alçak taraf taş temelle doldurulur
func house(x: float, n: float, wdt: float, dep: float, floors: int, yaw: float, style: String, rng: RandomNumberGenerator) -> void:
	var g = _ground_off(x, n, maxf(wdt, dep) * 0.6)
	if g.y - g.x > 0.25:
		var stone = Color(0.56, 0.53, 0.5) if style != "suna" else Color(0.74, 0.62, 0.45)
		var fh = g.y - g.x + 0.8
		box(Vector3(x, g.x - 0.6 + fh * 0.5, n), Vector3(wdt + 0.8, fh, dep + 0.8), stone, yaw)
	yoff = g.y
	last_house = {}
	_house_body(x, n, wdt, dep, floors, yaw, style, rng)
	yoff = 0.0
	_record_house(x, n, wdt, dep, yaw, g.y, style)


## Evin ayak izini (yan ekleri dahil) peyzaj için kaydet
func _record_house(x: float, n: float, wdt: float, dep: float, yaw: float, base: float, style: String) -> void:
	var hw = float(last_house.get("w", wdt))
	var hd = float(last_house.get("d", dep))
	houses.append([x, n, hw, hd, yaw, base, style])
	var c = w(Vector3(x, 0, n))
	add_solid(c, hw * 0.5 + 0.3, hd * 0.5 + 0.3, deg_to_rad(-yaw))
	var cols: Array = last_house.get("cols", [])
	if not cols.is_empty():
		var bs = Basis(Vector3.UP, deg_to_rad(-yaw) + PI)
		for e in cols:
			var sz: Vector3 = e[1]
			add_solid(c + bs * Vector3(e[0]), sz.x * 0.5 + 0.2, sz.z * 0.5 + 0.2, deg_to_rad(-yaw) + PI)


func _house_body(x: float, n: float, wdt: float, dep: float, floors: int, yaw: float, style: String, rng: RandomNumberGenerator) -> void:
	var hgt = floors * 4.2
	match style:
		"suna":
			VillageStyles.suna_house(self, x, n, wdt, dep, floors, yaw, rng)
			return
		"kiri":
			VillageStyles.kiri_house(self, x, n, wdt, dep, floors, yaw, rng)
			return
		"iwa", "rock":
			VillageStyles.iwa_house(self, x, n, wdt, dep, floors, yaw, rng)
			return
		"ame":
			VillageStyles.ame_house(self, x, n, wdt, dep, floors, yaw, rng)
			return
		"kumo":
			VillageStyles.kumo_house(self, x, n, wdt, dep, floors, yaw, rng)
			return
		"snow":
			VillageStyles.snow_house(self, x, n, wdt, dep, floors, yaw, rng)
			return
	# konoha / ahşap: detaylı şablon evler (HouseKit)
	var walls = [Color(0.96, 0.92, 0.84), Color(0.93, 0.87, 0.72), Color(0.98, 0.96, 0.9), Color(0.9, 0.84, 0.7), Color(0.86, 0.8, 0.7), Color(0.95, 0.88, 0.8)]
	var roofs = [Color(0.78, 0.22, 0.18), Color(0.22, 0.4, 0.62), Color(0.28, 0.52, 0.32), Color(0.85, 0.45, 0.18), Color(0.5, 0.32, 0.58), Color(0.65, 0.2, 0.24), Color(0.35, 0.35, 0.4)]
	if placer == null:
		placer = HouseKit.Placer.new(root, key)
		placer.view = view_dist
		# Konoha: evlerin bir kısmı hazır renkli Japon kasaba evleri
		placer.pack_chance = 0.3 if style == "konoha" else 0.0
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


## Köy giriş kapısı: yolun köye girdiği açıda (0 = kuzey) iki dikme, çatılı kiriş, amblem, yan duvarlar, fenerler.
## gap_deg > 0 ise sur boşluğunu yan duvarlarla kapatır.
func village_gate(ang: float, r: float, half_open: float, height: float, post_col: Color, roof_col: Color, emblem: String, gap_deg := 0.0) -> void:
	var a = deg_to_rad(ang)
	var c = Vector2(r * sin(a), r * cos(a))
	var t = Vector2(cos(a), -sin(a))
	var g = _ground_off(c.x, c.y, half_open + 4.0)
	var y0 = g.x - 1.0
	var top = g.y + height
	for sx in [-1.0, 1.0]:
		var pp = c + t * (half_open + 1.6) * sx
		box(Vector3(pp.x, (y0 + top) * 0.5, pp.y), Vector3(3.2, top - y0, 3.2), post_col, ang)
		box(Vector3(pp.x, g.x + 0.8, pp.y), Vector3(4.4, 1.6, 4.4), Color(0.55, 0.52, 0.48), ang)
		var wing = (gap_deg / 360.0 * TAU * r * 0.5) - (half_open + 3.2) if gap_deg > 0.0 else 22.0
		if wing > 0.5:
			var wc = c + t * (half_open + 3.2 + wing * 0.5) * sx
			var wh = height * 0.62 if gap_deg <= 0.0 else maxf(22.0, height * 0.85)
			var wcol = post_col.lightened(0.12) if gap_deg > 0.0 else post_col.lightened(0.25)
			var wg = _ground_off(wc.x, wc.y, wing * 0.5)
			var wy0 = minf(y0, wg.x - 1.0)
			box(Vector3(wc.x, (wy0 + g.y + wh) * 0.5, wc.y), Vector3(wing + 0.6, g.y + wh - wy0, 8.0 if gap_deg > 0.0 else 3.0), wcol, ang)
			box(Vector3(wc.x, g.y + wh + 0.5, wc.y), Vector3(wing + 1.2, 1.0, 9.0 if gap_deg > 0.0 else 3.8), roof_col, ang, false)  # mazgal başlığı
			if gap_deg <= 0.0:
				# sursuz köy: kanat ucu kare gözetleme kulesiyle biter (kapı boşlukta asılı durmasın, kapı binası gibi okunsun)
				var tp = c + t * (half_open + 3.2 + wing + 2.5) * sx
				var tg = _ground_off(tp.x, tp.y, 3.0)
				var th = height * 0.85
				box(Vector3(tp.x, (tg.x - 1.0 + tg.y + th) * 0.5, tp.y), Vector3(6.0, tg.y + th - tg.x + 1.0, 6.0), post_col, ang)
				box(Vector3(tp.x, tg.y + th + 0.8, tp.y), Vector3(8.0, 1.0, 8.0), roof_col, ang, false)
				box(Vector3(tp.x, tg.y + th + 1.8, tp.y), Vector3(6.4, 1.0, 6.4), roof_col.darkened(0.15), ang, false)
		var lo = c + t * (half_open + 1.6) * sx + Vector2(sin(a), cos(a)) * 3.0
		lantern(lo.x, lo.y, 3.2)
	box(Vector3(c.x, top + 1.0, c.y), Vector3(half_open * 2.0 + 7.0, 2.0, 3.4), post_col.darkened(0.2), ang)
	box(Vector3(c.x, top + 2.4, c.y), Vector3(half_open * 2.0 + 10.0, 0.9, 6.0), roof_col, ang, false)
	box(Vector3(c.x, top + 3.1, c.y), Vector3(half_open * 2.0 + 8.0, 0.6, 3.6), roof_col.darkened(0.15), ang, false)
	var e = c + Vector2(sin(a), cos(a)) * 1.9
	disc(Vector3(e.x, top - 1.4, e.y), 3.2, 0.25, Color(0.94, 0.9, 0.82), ang)
	var e2 = c + Vector2(sin(a), cos(a)) * 2.05
	disc(Vector3(e2.x, top - 1.4, e2.y), 1.8, 0.25, post_col.darkened(0.3), ang)


func tree(x: float, n: float, s: float, rng: RandomNumberGenerator, y := 0.0) -> void:
	# prosedürel ağaç (hazır paket ağaçları doğal durmuyordu; kullanıcı eskisini tercih etti)
	if _tree_mesh == null:
		_tree_mesh = Props.vegetation_mesh(0)  # tek mesh: hücre başına tek MultiMesh (her ağaca ayrı çizim değil)
	var tm = _tree_mesh
	if tm != null:
		pack_mesh(tm, Vector3(x, y, n), rng.randf() * 360.0, s * rng.randf_range(0.85, 1.15), 1.0)
		add_solid(w(Vector3(x, 0, n)), 1.6 * s, 1.6 * s, 0.0)
		_collide_cyl(w(Vector3(x, y + 2.6 * s, n)), 0.35 * s, 5.2 * s)
		return
	cyl(Vector3(x, y + 2.6 * s, n), 0.7 * s, 5.2 * s, Color(0.42, 0.29, 0.18), true, 7)
	var g = Color(0.28, 0.55, 0.22).lightened(rng.randf_range(-0.05, 0.08))
	sphere(Vector3(x, y + 6.6 * s, n), Vector3(5.2, 4.0, 5.2) * s, g, 9)
	sphere(Vector3(x + 1.5 * s, y + 6.0 * s, n + 0.6 * s), Vector3(3.4, 2.8, 3.4) * s, g.darkened(0.08), 8)
	sphere(Vector3(x - 1.2 * s, y + 7.6 * s, n - 0.6 * s), Vector3(3.2, 2.6, 3.2) * s, g.lightened(0.05), 8)


## Hazır bir modeli (AssetLib) bu yapı grubuna ekler: hücre başına MultiMesh. dist: görünürlük çarpanı
func pack_mesh(m: Mesh, p: Vector3, yaw_deg := 0.0, scale := 1.0, dist := 1.0) -> void:
	if m == null:
		return
	var wp = w(p)
	var k = "%d|%d|%d" % [int(floor(wp.x / CELL)), int(floor(wp.z / CELL)), m.get_instance_id()]
	if not packs.has(k):
		packs[k] = [m, [], dist]
	packs[k][1].append(Transform3D(Basis(Vector3.UP, deg_to_rad(-yaw_deg)).scaled(Vector3.ONE * scale), wp))


## Hazır aksesuar (AssetLib.PROPS anahtarı): torii, pagoda, stone_lamp, red_lantern, post_lantern, bench, shrine...
## collide: >0 ise o yarıçapta silindir çarpışma
func prop(kind: String, p: Vector3, yaw_deg := 0.0, height := 0.0, collide := 0.0) -> bool:
	var m = AssetLib.prop(kind, height)
	if m == null:
		return false
	pack_mesh(m, p, yaw_deg, 1.0, 0.7)
	if collide > 0.0:
		var hh = maxf(1.0, height if height > 0.0 else 2.0)
		_collide_cyl(w(p + Vector3(0, hh * 0.5, 0)), collide, hh)
	return true


func lantern(x: float, n: float, h := 3.2) -> void:
	# taş fener (tōrō) hazır modeli; h: tepe yüksekliği (zemin dahil)
	var gy = h - 3.2
	if prop("stone_lamp", Vector3(x, gy, n), 0.0, 2.6):
		Lights.add(w(Vector3(x, gy + 1.9, n)))
		return
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
