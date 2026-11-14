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
const TREELESS := ["suna", "iwa", "kumo"]   # çöl ve kayalık köyler: köy içinde ağaç yok
var stream_vid := ""   # akış köyü kimliği (Koy_<id> altında kurulduysa)
var placer = null  # HouseKit.Placer (Japon tarzı detaylı evler)
var house_ti := -1   # >= 0: bir sonraki şablon ev bu şablon olsun (bitişik dizilimde genişlik önceden bilinir)
var yoff := 0.0  # geçici dikey ofset (eğimli arazide bina tabanı)
var packs := {}  # hücre+mesh -> [mesh, Array[Transform3D]] (hazır modeller: MultiMesh)
var road_guard := true   # house(): yolun üstüne düşen evi kurma (dükkân/özel yapılar kapatabilir)
var shift_off_road := false   # house(): yolu kapatıyorsa ATLAMA, yoldan dışarı kaydırıp kur (dükkânlar: tabelası/kapısı binasız kalıyordu)
var house_ok := false   # son house() gerçekten kuruldu mu (yol yüzünden atlandıysa false: kapı/süs eklenmesin)
var placed_xn := Vector2.ZERO  # son house() çağrısının gerçek konumu (kaydırıldıysa yeni yer)
var last_house := {}  # son yerleştirilen şablon ev (w, d, h, roof_top)
var houses: Array = []  # [x, n, gen, der, yaw, taban, stil] (peyzaj bahçeleri için)
var solids := {}  # 16 m ızgara (dünya xz) -> [[cx, cz, yarı_x, yarı_z, açı]] (peyzaj çakışma kontrolü)
var landscape := true  # finish()'te yeterince ev varsa CityLandscape ile bahçe/sokak ağacı/park
const SCELL := 16.0
static var _tree_mesh: Mesh
static var _tree_meshes: Array = []
var house_grid := {}   # 32 m yerel ızgara -> ev kayıtları (ağaç yerleşimi hızlı kontrol)
## yaprak dökümü: köy ağaçlarının [dünya konumu (taç), renk, taç yarıçapı] listesi
static var leaf_spots: Array = []
static var landscape_on := true  # testlerde karşılaştırma için kapatılabilir

static var roof_points := {}  # köy id -> [çatı tepe noktaları] (çatıdan çatıya koşan ninjalar için)


func _init(parent: Node3D, map_x: float, map_y: float, base_h: float, name := "Yapi") -> void:
	root = Node3D.new()
	root.name = name
	key = name.to_lower()
	parent.add_child(root)
	# akışla kurulan köyün içindeyse hangi köy (etkileşim noktaları köy silinince yalnız kendi köyünden silinir)
	var n: Node = parent
	while n != null:
		if String(n.name).begins_with("Koy_"):
			stream_vid = String(n.name).substr(4)
			break
		n = n.get_parent()
	origin = Vector3(map_x, base_h, -map_y)
	body = StaticBody3D.new()
	body.collision_layer = 1
	# gövde sahneye finish()'te eklenir: ağaçtaki bir gövdeye her şekil eklemek fizik sunucusunda tüm şekilleri
	# yeniden kurar (O(n²)); Konoha'nın ~20 bin kutusu açılışı ~40 sn uzatıyordu
	root.tree_exiting.connect(func(): if is_instance_valid(body) and body.get_parent() == null: body.free())
	root.tree_exiting.connect(func():
		for eb in extra_bodies:
			if is_instance_valid(eb) and eb.get_parent() == null:
				eb.free())


## yerel (x, y, n) -> Godot dünya
func w(p: Vector3) -> Vector3:
	return origin + Vector3(p.x, p.y + yoff, -p.z)


## Boyut kademeleri: küçük detaylar kısa mesafede söner (uzak köy tam detay çiziliyordu: Suna ~11 M üçgen)
## [en büyük boyut sınırı, hücre boyu, görünürlük bitişi (0 = view_dist), görünürlük başlangıcı]
## 3/4/5: büyük yuvarlak gövdeler (kubbe, kule, silindir) yakında tam segment, uzaklaştıkça yarı / çeyrek segmentli kopya
const ROUND_NEAR := 220.0
const ROUND_MID := 650.0
const TIERS := [[1.5, 48.0, 220.0, 0.0], [5.0, 128.0, 750.0, 0.0], [INF, CELL, 0.0, 0.0], [INF, CELL, ROUND_NEAR, 0.0], [INF, CELL, ROUND_MID, ROUND_NEAR], [INF, CELL, 0.0, ROUND_MID]]


func _mb(wp: Vector3, sz := INF) -> MB:
	var ti = 0
	while ti < 2 and sz >= TIERS[ti][0]:
		ti += 1
	return _cell(wp, ti)


func _cell(wp: Vector3, ti: int) -> MB:
	var cs: float = TIERS[ti][1]
	var key = Vector3i(int(floor(wp.x / cs)), int(floor(wp.z / cs)), ti)
	if not cells.has(key):
		cells[key] = MB.new()
	return cells[key]


## Segmentli şekil: büyükse yakın (tam) + uzak (az segment) hücrelerine
func _round(kind: String, wp: Vector3, size: Vector3, col: Color, rot: Vector3, seg: int, sz: float) -> void:
	if sz < TIERS[1][0] or seg <= 8:
		_mb(wp, sz).add(kind, wp, size, col, rot, seg)
		return
	_cell(wp, 3).add(kind, wp, size, col, rot, seg)
	_cell(wp, 4).add(kind, wp, size, col, rot, clampi(seg / 2, 6, 14))
	_cell(wp, 5).add(kind, wp, size, col, rot, clampi(seg / 4, 5, 8))


const PACK_NEAR := 300.0
static var _tri_cache := {}
static func _tris(m: ArrayMesh) -> int:
	var k = m.get_instance_id()
	if not _tri_cache.has(k):
		var t = 0
		for i in m.get_surface_count():
			t += m.surface_get_array_index_len(i) / 3
		_tri_cache[k] = t
	return _tri_cache[k]


static func _msz(v: Vector3) -> float:
	return maxf(absf(v.x), maxf(absf(v.y), absf(v.z)))


## Çarpışma şekli ekle: gövde başına en fazla BODY_MAX şekil, üçgen-mesh (ConcavePolygon) kendi gövdesinde. Jolt tek gövdede
## binlerce şekli / dev mesh içeren bileşiği kuramıyor ("Compound hierarchy is too deep") ve o gövde HİÇ çarpışmıyordu:
## Konoha'nın ~77 bin şekli tek gövdedeydi -> duvarların içinden geçiliyordu.
const BODY_MAX := 200
var extra_bodies: Array = []
var _body_n := 0
func add_shape(cs: CollisionShape3D) -> void:
	if not is_instance_valid(body):
		return
	if cs.shape is ConcavePolygonShape3D:
		var mb = _new_body()
		mb.add_child(cs)
		extra_bodies.append(mb)
		if body.is_inside_tree():
			root.add_child(mb)
		return
	if _body_n >= BODY_MAX:
		if body.is_inside_tree():
			body = _new_body()
			root.add_child(body)
		else:
			extra_bodies.append(body)
			body = _new_body()
		_body_n = 0
	body.add_child(cs)
	_body_n += 1


func _new_body() -> StaticBody3D:
	var b = StaticBody3D.new()
	b.collision_layer = 1
	return b


## rot: görüntüdeki eğim/devrilme (derece, MB.add ile AYNI euler: x, yaw+y, z). Eskiden çarpışma eğimi yok sayıp kutuyu dik
## kuruyordu -> eğik duvar/kütük/kaya her yerde "görünmez yapı" (kullanıcı 2026-11-10: köyde, ormanda, her yerde takılıyorum)
func _collide(center: Vector3, size: Vector3, yaw_deg: float, rot := Vector3.ZERO) -> void:
	if not is_instance_valid(body):
		return  # akışla kurulan yer yarıda silindi
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	var bas = Basis(Vector3.UP, deg_to_rad(yaw_deg))
	if rot != Vector3.ZERO:
		bas = Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(yaw_deg + rot.y), deg_to_rad(rot.z)))
	cs.transform = Transform3D(bas, center)
	add_shape(cs)
	if rot == Vector3.ZERO:
		add_solid(center, size.x * 0.5, size.z * 0.5, deg_to_rad(yaw_deg))
	else:
		# NPC yürüme izi: dönmüş kutunun yatay izdüşümü (eksene hizalı yarı genişlikler)
		var hx = 0.0; var hz = 0.0
		for ax in [bas.x * size.x * 0.5, bas.y * size.y * 0.5, bas.z * size.z * 0.5]:
			hx += absf(ax.x); hz += absf(ax.z)
		add_solid(center, hx, hz, 0.0)


func _collide_convex(center: Vector3, pts: PackedVector3Array, r: float) -> void:
	if not is_instance_valid(body):
		return
	var cs = CollisionShape3D.new()
	var sh = ConvexPolygonShape3D.new()
	sh.points = pts
	cs.shape = sh
	cs.position = center
	add_shape(cs)
	add_solid(center, r, r, 0.0)


## Anime ağacının kalın dallarına kapsül çarpışma (mesh meta "limbs"); pack_mesh ile aynı konum/dönüş/ölçek
func tree_limbs(m: Mesh, local_pos: Vector3, rot_deg: float, sc: float) -> void:
	if not is_instance_valid(body) or not (m is ArrayMesh) or not m.has_meta("limbs"):
		return
	var base = Transform3D(Basis(Vector3.UP, deg_to_rad(rot_deg)) * Basis.from_scale(Vector3.ONE * sc), w(local_pos))
	for L in (m.get_meta("limbs") as Array) + (m.get_meta("roots", []) as Array):   # dallar + kökler (kökün gerçek kalınlığı)
		var a: Vector3 = L[0]
		var b: Vector3 = L[1]
		var r = maxf(0.12, float(L[2]))
		var cs = CollisionShape3D.new()
		var cap = CapsuleShape3D.new()
		cap.radius = r * sc
		cap.height = maxf(cap.radius * 2.0 + 0.01, ((b - a).length() + r * 2.0) * sc)
		cs.shape = cap
		var lx = AnimeTree.limb_xf(a, b)
		cs.transform = Transform3D(base.basis.orthonormalized() * lx.basis, base * lx.origin)
		add_shape(cs)


func _collide_cyl(center: Vector3, r: float, h: float) -> void:
	if not is_instance_valid(body):
		return
	var cs = CollisionShape3D.new()
	var sh = CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	cs.position = center
	add_shape(cs)
	add_solid(center, r, r, 0.0)


## Görünen pürüzlü kaya mesh'inin üçgenleri (ConcavePolygon): çarpışma görüntüyle birebir
func _collide_hull(kind: String, mv: int, center: Vector3, size: Vector3, yaw: float) -> void:
	if not is_instance_valid(body):
		return
	var arr: Array = MB._prim_arrays(kind, mv)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx = arr[Mesh.ARRAY_INDEX]
	var xf = Basis.from_euler(Vector3(0, deg_to_rad(yaw), 0)) * Basis.from_scale(size)
	var pts = PackedVector3Array()
	if idx != null and (idx as PackedInt32Array).size() > 0:
		for i in idx:
			pts.append(xf * verts[i])
	else:
		for v in verts:
			pts.append(xf * v)
	var sh = ConcavePolygonShape3D.new()   # üçgenlerin kendisi: dış kabuk (convex) katman girintilerini doldurup görünmez çıkıntı yapıyordu
	sh.backface_collision = true
	sh.set_faces(pts)
	var cs = CollisionShape3D.new()
	cs.shape = sh
	cs.position = center
	add_shape(cs)
	add_solid(center, size.x * 0.5, size.z * 0.5, 0.0)


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
	_mb(wp, _msz(size)).add("box", wp, size, col, Vector3(rot.x, -yaw + rot.y, rot.z))
	if collide:
		_collide(wp, size, -yaw, rot)
	# yere döşenmiş yassı yüzey (avlu taşı, kaldırım, meydan, platform): altından çimen çıkmasın
	# (yere gömülü kalın döşemeler de: ölçüt kalınlık değil, üst yüzeyin zemin hizasında olması)
	if rot == Vector3.ZERO and size.y <= 2.5 and maxf(size.x, size.z) >= 1.5 and minf(size.x, size.z) >= 0.9:
		var gh = Game.terrain_height(wp.x, wp.z)
		var top = wp.y + size.y * 0.5
		if top > gh - 0.4 and top < gh + 0.9:
			_grass_clear(wp, size, -yaw)


## Döşemenin kapladığı alanı çimen maskesine yaz (RoadMap şerit: uzun eksen boyunca, yarı genişlik = kısa kenar / 2)
func _grass_clear(wp: Vector3, size: Vector3, yaw_deg: float) -> void:
	var th = deg_to_rad(yaw_deg)
	var ax = Vector2(cos(th), -sin(th))   # kutunun yerel x ekseni (dünya xz)
	var az = Vector2(sin(th), cos(th))    # yerel z
	var c = Vector2(wp.x, wp.z)
	if size.x >= size.z:
		preload("res://scripts/world/road_map.gd").add_lane(c - ax * size.x * 0.5, c + ax * size.x * 0.5, size.z * 0.5 + 0.3)
	else:
		preload("res://scripts/world/road_map.gd").add_lane(c - az * size.z * 0.5, c + az * size.z * 0.5, size.x * 0.5 + 0.3)


func cyl(p: Vector3, d: float, h: float, col: Color, collide := true, seg := 16, top := -1.0) -> void:
	var wp = w(p)
	if top >= 0.0:
		_mb(wp, maxf(d, h)).add_xf("cone", Transform3D(Basis.IDENTITY.scaled(Vector3(d, h, d)), wp), col, seg)
	else:
		_round("cyl", wp, Vector3(d, h, d), col, Vector3.ZERO, seg, maxf(d, h))
	if collide:
		_collide_cyl(wp, d * 0.5, h)


func cone(p: Vector3, d: float, h: float, col: Color, seg := 16, collide := false) -> void:
	var wp = w(p)
	_round("cone", wp, Vector3(d, h, d), col, Vector3.ZERO, seg, maxf(d, h))
	if collide or (d >= 3.0 and not key.begins_with("silhouet")):   # büyük koniler (kule/çatı) her zaman katı: içinden geçilmesin, eğiminde yürünsün
		var pts = PackedVector3Array()
		for i in 16:
			var a = TAU * i / 16.0
			pts.append(Vector3(cos(a) * d * 0.5, -h * 0.5, sin(a) * d * 0.5))
		pts.append(Vector3(0, h * 0.5, 0))
		_collide_convex(wp, pts, d * 0.5)


func sphere(p: Vector3, size: Vector3, col: Color, seg := 12, collide := false) -> void:
	var wp = w(p)
	_round("sphere", wp, size, col, Vector3.ZERO, seg, _msz(size))
	if collide:
		var pts = PackedVector3Array()
		for ring in 7:
			var e = (ring / 6.0 - 0.5) * PI
			for i in 12:
				var a = TAU * i / 12.0
				pts.append(Vector3(cos(a) * cos(e) * size.x * 0.5, sin(e) * size.y * 0.5, sin(a) * cos(e) * size.z * 0.5))
		_collide_convex(wp, pts, maxf(size.x, size.z) * 0.5)


## Dikey disk (arma/plaka): ön yüzü yaw yönüne (yerel -n) bakar
func disc(p: Vector3, d: float, thick: float, col: Color, yaw := 0.0, seg := 16) -> void:
	var wp = w(p)
	_round("cyl", wp, Vector3(d, thick, d), col, Vector3(90, -yaw, 0), seg, d)


func dome(p: Vector3, d: float, h: float, col: Color, seg := 16) -> void:
	var wp = w(p)
	_round("hemi", wp, Vector3(d, h * 2.0, d), col, Vector3.ZERO, seg, maxf(d, h))  # yarım küre tabanı y=0, tepe h
	if d >= 3.0 and not key.begins_with("silhouet"):   # kubbe katı
		var pts = PackedVector3Array()
		for ring in 5:
			var e = ring / 5.0 * PI * 0.5
			for i in 14:
				var a = TAU * i / 14.0
				pts.append(Vector3(cos(a) * cos(e) * d * 0.5, sin(e) * h, sin(a) * cos(e) * d * 0.5))
		pts.append(Vector3(0, h, 0))
		_collide_convex(wp, pts, d * 0.5)


## Çatı: üçgen prizma (yaw ile döner). p: çatı tabanının merkezi
func roof(p: Vector3, size: Vector3, col: Color, yaw := 0.0) -> void:
	var wp = w(p) + Vector3(0, size.y * 0.5, 0)
	_mb(wp, _msz(size)).add("prism", wp, size, col, Vector3(0, -yaw, 0))
	_collide(wp - Vector3(0, size.y * 0.25, 0), Vector3(size.x * 0.7, size.y * 0.5, size.z), -yaw)


## Pürüzlü katmanlı kaya sütunu (Kumo/Iwa kuleleri, krater duvarı). p: taban merkezi
## KURAL (shape-climb): kaya her zaman kendi yüzeyiyle katıdır -> şekline göre yürünür/tırmanılır; yalnız uzak siluette çarpışma yok
## collide=false yalnız bilinçli boşluk için (ör. in ağzındaki kayalar girişi kapatmasın)
func crag(p: Vector3, d: float, h: float, col: Color, variant := 0, collide := true, yaw := 0.0) -> void:
	if key.begins_with("silhouet"):
		collide = false
	var wp = w(p)
	var mv = (200 + variant % 16) if variant >= 200 else ((100 + variant % 16) if variant >= 100 else variant % 16)
	_mb(wp, maxf(d, h)).add("crag", wp + Vector3(0, h * 0.5, 0), Vector3(d, h, d), col, Vector3(0, yaw, 0), mv)
	if collide:
		_collide_hull("crag", mv, wp + Vector3(0, h * 0.5, 0), Vector3(d, h, d), yaw)   # görünen kayanın kendisi: tek kalın silindir daralan/eğik tepede görünmez duvardı


## Düzensiz kaya. p: merkez
## KURAL (shape-climb): varsayılan katı, kendi yüzeyiyle; küçük çakıl (<1.5 m) ve uzak siluet hariç
func boulder(p: Vector3, size: Vector3, col: Color, variant := 0, collide := true, yaw := 0.0) -> void:
	if _msz(size) < 1.5 or key.begins_with("silhouet"):
		collide = false
	var wp = w(p)
	_mb(wp, _msz(size)).add("boulder", wp, size, col, Vector3(0, yaw, 0), variant % 16)
	if collide:
		_collide_hull("boulder", variant % 16, wp, size, yaw)   # kutu köşeleri yuvarlak kayanın dışına taşıyordu


## Yukarı daralan silindir (kule gövdesi). p: merkez
func frustum(p: Vector3, d: float, h: float, col: Color, collide := true, seg := 16) -> void:
	var wp = w(p)
	_round("frustum", wp, Vector3(d, h, d), col, Vector3.ZERO, seg, maxf(d, h))
	if collide:
		frustum_shape(wp, d * 0.5, d * 0.36, h)


## Kesik koni çarpışması (görünen gövdeyle birebir: düz silindir tepede dışarı taşıp görünmez duvar oluyordu)
func frustum_shape(center: Vector3, r_bot: float, r_top: float, h: float) -> void:
	var pts = PackedVector3Array()
	for i in 16:
		var a = TAU * i / 16.0
		pts.append(Vector3(cos(a) * r_bot, -h * 0.5, sin(a) * r_bot))
		pts.append(Vector3(cos(a) * r_top, h * 0.5, sin(a) * r_top))
	_collide_convex(center, pts, maxf(r_bot, r_top))


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
	if stream_vid != "":
		d["_koy"] = stream_vid
	if defer_interact != null:
		defer_interact.append(d)
	else:
		Interact.add(d)


## Köylerdeki ev yoğunluğu (1.0 = eski sıkışık doku). Kullanıcı kararı 2026-11-14: her köyde bina sayısı yarıya iner
## (çizim yükü evlerde: Konoha ~30 bin parça); yerleştiriciler sıra / halka / ızgara düzenini buna göre seyreltir.
## EV_YOGUNLUK ortam değişkeni yalnız ölçüm için (önce / sonra ev sayısı).
const HOUSE_CAP := 3000   # bir köydeki en fazla ev
static func house_density() -> float:
	var e = OS.get_environment("EV_YOGUNLUK")
	return float(e) if e != "" else 0.5


func finish() -> void:
	if not is_instance_valid(root):
		return
	if houses.size() >= 12:
		print("Evler %s: %d" % [key, houses.size()])
	for eb in extra_bodies:
		if is_instance_valid(eb) and eb.get_parent() == null:
			root.add_child(eb)
	if is_instance_valid(body) and body.get_parent() == null:
		root.add_child(body)
	if landscape and landscape_on and houses.size() >= 12 and not key.begins_with("yolkenari"):
		landscape = false
		# peyzaj kareler boyunca kurulur (await): eskiden beklenmiyordu -> placer.finish() önce çalışıp sonradan eklenen ara arsa
		# evlerinin görseli HİÇ kurulmuyordu (çarpışma vardı = görünmez ev) ve köy önbelleğe yarım kaydediliyordu (boş arsalar).
		# Şimdi peyzaj bitince kalan iş yapılır; pişirme Builder.dressing sıfırlanana kadar bekler.
		dressing += 1
		_finish_after_dress()
		return
	_finish_rest()


static var dressing := 0
func _finish_after_dress() -> void:
	await CityLandscape.dress(self)
	dressing -= 1
	if is_instance_valid(root):
		_finish_rest()


func _finish_rest() -> void:
	for eb in extra_bodies:   # peyzajın eklediği ayrı gövdeler (üçgen şekiller) de ağaca girsin
		if is_instance_valid(eb) and eb.get_parent() == null:
			root.add_child(eb)
	if placer != null:
		placer.finish()
	for pk in packs:
		var pe: Array = packs[pk]
		var xfs: Array = pe[1]
		var end = view_dist * float(Game.settings["view"]) * float(pe[2])
		# ağır modeller (köy ağacı ~860 üçgen; Konoha'da binlercesi 1.5 km'ye dek ~17 M üçgen): uzakta sadeleştirilmiş kopya
		var near = PACK_NEAR * float(Game.settings["view"])
		var lv = [[pe[0], 0.0, end]]
		if pe[0] is ArrayMesh and (pe[0] as ArrayMesh).has_meta("anime_tree"):
			# anime ağacı: yakın tam taç -> az kartlı orta -> birkaç kartlı çok uzak (dither geçişli)
			var at: Array = (pe[0] as ArrayMesh).get_meta("anime_tree")
			var mid = maxf(near + 80.0, 600.0 * float(Game.settings["view"]))
			if end > near + 50.0:
				lv = [[pe[0], 0.0, near], [AnimeTree.mesh(at[0], at[1], at[2], true), near, minf(mid, end)]]
				if end > mid + 50.0:
					lv.append([AnimeTree.mesh(at[0], at[1], at[2], true, true), mid, end])
		elif pe[0] is ArrayMesh and end > near + 50.0 and _tris(pe[0]) > 300:
			lv = [[pe[0], 0.0, near], [AssetLib.lod(pe[0], 0.15), near, end]]
		for l in lv:
			var mm = MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true
			mm.mesh = l[0]
			mm.instance_count = xfs.size()
			for i in xfs.size():
				mm.set_instance_transform(i, xfs[i])
				mm.set_instance_color(i, Color.WHITE)
			var mmi = MultiMeshInstance3D.new()
			mmi.layers = 2
			mmi.multimesh = mm
			mmi.visibility_range_begin = l[1]
			mmi.visibility_range_begin_margin = 20.0 if l[1] > 0.0 else 0.0
			mmi.visibility_range_end = l[2]
			mmi.visibility_range_end_margin = 60.0 if l[2] == end else 20.0
			if l[2] == end or (l[0] is ArrayMesh and (l[0] as ArrayMesh).has_meta("anime_tree")):
				mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF   # ağaç kademeleri dither ile geçer (pop yok)
			if l[1] > 0.0:
				mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(mmi)
	packs.clear()
	for key in cells:
		var mb: MB = cells[key]
		if mb.is_empty():
			continue
		var mi = MeshInstance3D.new()
		mi.layers = 2  # yapılar: sokak fenerleri (yalnız katman 1) bunları aydınlatmaz
		mi.mesh = mb.build(Props.toon())
		if key is Vector3i:
			mi.name = "K%d_%d_%d" % [key.z, key.x, key.y]
		# görünürlük mesafesi parçanın merkezinden ölçülür: dev parçalar (Suna sur kayalıkları, uzun duvarlar) yanındayken bile
		# uzak merkezleri yüzünden yarı saydam soluyordu (çarpışma durduğu için "şeffaf ama yürünen duvar") — parça boyu kadar uzat
		var tv: float = TIERS[key.z][2] if key is Vector3i else 0.0
		var tb: float = TIERS[key.z][3] if key is Vector3i else 0.0
		mi.visibility_range_end = (tv if tv > 0.0 else view_dist) * float(Game.settings["view"]) + mi.mesh.get_aabb().size.length() * 0.6
		if tb > 0.0:
			mi.visibility_range_begin = tb * float(Game.settings["view"]) + mi.mesh.get_aabb().size.length() * 0.6
			mi.visibility_range_begin_margin = 30.0
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		mi.visibility_range_end_margin = 30.0 if tv > 0.0 and tv < 300.0 else 60.0
		root.add_child(mi)
	cells.clear()
	cap_ranges(root, view_dist)
	cap_ranges.call_deferred(root, view_dist)


## Görünürlük mesafesi verilmemiş geometri (taş Hokage kafaları / Sonun Vadisi heykelleri = CharacterModel, şehir süsleri,
## yol ustaları) 20+ km öteden bile çiziliyordu: hepsine view_dist + kendi boyu kadar sınır koy
static func cap_ranges(n: Node, dist: float) -> void:
	if not is_instance_valid(n) or not n.is_inside_tree():
		return
	var v = dist * float(Game.settings["view"])
	for g in n.find_children("*", "GeometryInstance3D", true, false):
		if g.visibility_range_end > 0.0:
			continue
		var a: AABB = g.global_transform * g.get_aabb()
		var sz = a.size.length()
		g.visibility_range_end = (minf(v, 260.0) if sz < 6.0 else v) + sz * 0.6   # insan boyu (usta, süs) 260 m
		g.visibility_range_end_margin = 40.0
		g.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


# ------------------------------------------------------------------ hazır yapılar
## Japon tarzı ev. style: konoha | suna | kiri | iwa | kumo | ame | wood | snow
## Bina arazinin üstüne oturur: taban = ayak izindeki en yüksek nokta, alçak taraf taş temelle doldurulur
## Evin taban alanı (merkez, köşeler, kenar ortaları) bir yolun / caddenin üstüne taşıyor mu? (cadde yarı genişliği ~4.5 m)
func footprint_on_road(x: float, n: float, wdt: float, dep: float, yaw: float, half_road := 5.0) -> bool:
	for u in [-0.5, 0.0, 0.5]:
		for v in [-0.5, 0.0, 0.5]:
			var o = rot(u * (wdt + 1.0), v * (dep + 1.0), yaw)
			var wp = w(Vector3(x + o.x, 0, n + o.y))
			if Game.road_dist(wp.x, wp.z) < half_road:
				return true
	return false


static var overlap_moved := 0
static var overlap_skipped := 0
static var overlap_post := 0
static var overlap_log: Array = []


## Yerel (x, n) merkezli, yaw (derece) dönük hx×hz yarı boyutlu ev ayak izi daha önce kurulmuş bir evle çakışıyor mu
## (dönmüş dikdörtgen SAT; 0.6 m pay: bitişik nizam olur, iç içe girmez — yapi.png: yuvarlak kule evlerin içindeydi)
func house_overlaps(x: float, n: float, hx: float, hz: float, yaw: float) -> bool:
	var pad = 0.05   # değebilir ama iç içe giremez (eskiden 0.6 m iç içe girmeye izin veriliyordu); aralık sokak düzeninden (build_konoha)
	var a0 = deg_to_rad(-yaw)
	var ax = [Vector2(cos(a0), sin(a0)), Vector2(-sin(a0), cos(a0))]
	var ah = [maxf(0.5, hx - pad), maxf(0.5, hz - pad)]
	var gx = floori(x / 32.0); var gz = floori(n / 32.0)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for h in house_grid.get(Vector2i(gx + dx, gz + dz), []):
				var b0 = deg_to_rad(-float(h[4]))
				var bx_ = [Vector2(cos(b0), sin(b0)), Vector2(-sin(b0), cos(b0))]
				var bh = [maxf(0.5, float(h[2]) * 0.5 - pad), maxf(0.5, float(h[3]) * 0.5 - pad)]
				var d = Vector2(float(h[0]) - x, float(h[1]) - n)
				if d.length() > (Vector2(ah[0], ah[1]).length() + Vector2(bh[0], bh[1]).length()):
					continue
				var sep = false
				for axis in ax + bx_:
					var ra = absf(axis.dot(ax[0])) * ah[0] + absf(axis.dot(ax[1])) * ah[1]
					var rb = absf(axis.dot(bx_[0])) * bh[0] + absf(axis.dot(bx_[1])) * bh[1]
					if absf(axis.dot(d)) > ra + rb:
						sep = true
						break
				if not sep:
					return true
	return false


func house(x: float, n: float, wdt: float, dep: float, floors: int, yaw: float, style: String, rng: RandomNumberGenerator) -> void:
	last_house = {}
	house_ok = false
	placed_xn = Vector2(x, n)
	# gerçek ayak izi: zorla seçilmiş şablon (yuvarlak kule vb.) arsadan büyük olabilir
	var fw = wdt; var fd = dep
	if house_ti >= 0 and house_ti < HouseKit.templates.size():
		fw = maxf(fw, float(HouseKit.templates[house_ti]["w"]))
		fd = maxf(fd, float(HouseKit.templates[house_ti]["d"]))
	if house_overlaps(x, n, fw * 0.5, fd * 0.5, yaw):
		var moved = false
		for step in range(1, 7):
			for k in 8:
				var dv = Vector2(cos(TAU * k / 8.0), sin(TAU * k / 8.0)) * 2.0 * step
				if house_overlaps(x + dv.x, n + dv.y, fw * 0.5, fd * 0.5, yaw):
					continue
				if road_guard and footprint_on_road(x + dv.x, n + dv.y, wdt, dep, yaw):
					continue
				x += dv.x
				n += dv.y
				moved = true
				break
			if moved:
				break
		if not moved:
			overlap_skipped += 1
			house_ti = -1
			return   # boş yer yok: iç içe ev kurma
		overlap_moved += 1
		placed_xn = Vector2(x, n)
	if road_guard and footprint_on_road(x, n, wdt, dep, yaw):
		if not shift_off_road:
			return   # bina caddeyi / yolu kapatmasın (sokağın ortasına dikilen binalar)
		# yoldan uzaklaşan en kısa kaydırma: 2 m adımlarla 8 yön, yola en uzak olanı; bulunamazsa yerinde kurulur
		var found = false
		for step in range(1, 13):
			var best = Vector2.ZERO
			var bd = -1.0
			for k in 8:
				var dv = Vector2(cos(TAU * k / 8.0), sin(TAU * k / 8.0)) * 2.0 * step
				if footprint_on_road(x + dv.x, n + dv.y, wdt, dep, yaw):
					continue
				var wp = w(Vector3(x + dv.x, 0, n + dv.y))
				var rd = Game.road_dist(wp.x, wp.z)
				if rd > bd:
					bd = rd
					best = dv
			if bd >= 0.0:
				x += best.x
				n += best.y
				found = true
				break
		placed_xn = Vector2(x, n)
	var g = _ground_off(x, n, maxf(wdt, dep) * 0.6)
	if g.y - g.x > 0.25:
		var stone = Color(0.56, 0.53, 0.5) if style != "suna" else Color(0.74, 0.62, 0.45)
		var fh = g.y - g.x + 0.8
		box(Vector3(x, g.x - 0.6 + fh * 0.5, n), Vector3(wdt + 0.8, fh, dep + 0.8), stone, yaw)
	yoff = g.y
	last_house = {}
	_house_body(x, n, wdt, dep, floors, yaw, style, rng)
	house_ok = true
	yoff = 0.0
	_record_house(x, n, wdt, dep, yaw, g.y, style)


## Evin ayak izini (yan ekleri dahil) peyzaj için kaydet
func _record_house(x: float, n: float, wdt: float, dep: float, yaw: float, base: float, style: String) -> void:
	var hw = float(last_house.get("w", wdt))
	var hd = float(last_house.get("d", dep))
	if house_overlaps(x, n, hw * 0.5, hd * 0.5, yaw):
		overlap_post += 1   # gerçek şablon ölçüsüyle çakışma (ölçüm)
		if overlap_log.size() < 12:
			overlap_log.append([key, int(x), int(n), int(hw), int(hd), int(last_house.get("arch", -1))])
	houses.append([x, n, hw, hd, yaw, base, style])
	var hk = Vector2i(floori(x / 32.0), floori(n / 32.0))
	if not house_grid.has(hk):
		house_grid[hk] = []
	house_grid[hk].append(houses[houses.size() - 1])
	var c = w(Vector3(x, 0, n))
	add_solid(c, hw * 0.5 + 0.3, hd * 0.5 + 0.3, deg_to_rad(-yaw))
	# ev tabanı: çimen evin içinde/zemininden çıkmasın (yol dokusuna düşük değerle)
	var hb = Basis(Vector3.UP, deg_to_rad(-yaw))
	var ha = c + hb * Vector3(0, 0, -hd * 0.5 + 0.6)
	var he = c + hb * Vector3(0, 0, hd * 0.5 - 0.6)
	preload("res://scripts/world/road_map.gd").add_lane(Vector2(ha.x, ha.z), Vector2(he.x, he.z), hw * 0.5)
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
		placer.pack_chance = 0.0   # hazır kasaba evi modeli (jp_town_street) pakete girmiyor: oyunda görünmez ev + çarpışma kalıyordu
	var wcol: Color = walls[rng.randi() % walls.size()]
	var rcol: Color = roofs[rng.randi() % roofs.size()]
	if style == "konoha":
		var kr = [Color(0.93, 0.56, 0.2), Color(0.95, 0.62, 0.25), Color(0.88, 0.48, 0.18), Color(0.9, 0.66, 0.3), Color(0.82, 0.32, 0.2),
			Color(0.93, 0.56, 0.2), Color(0.35, 0.62, 0.58), Color(0.4, 0.6, 0.85), Color(0.42, 0.66, 0.42), Color(0.95, 0.62, 0.25)]
		rcol = kr[rng.randi() % kr.size()]
	if style == "wood":
		wcol = Color(0.62, 0.47, 0.32).darkened(rng.randf_range(0, 0.2))
	elif style == "snow":
		rcol = Color(0.93, 0.95, 0.98)
	placer.force_ti = house_ti
	house_ti = -1
	last_house = placer.add(w(Vector3(x, 0, n)), yaw, wcol, rcol, rng, 1.0, wdt, dep)   # wdt/dep: arsa sınırı
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
		if rng.randf() < 0.25:
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
			box(Vector3(x + wo.x, f * 4.2 + 2.6, n + wo.y), Vector3(1.4, 1.2, 0.1), Color(0.55, 0.72, 0.85), yaw, false)
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
			box(Vector3(r * sin(rad), top + 0.4, r * cos(rad)), Vector3(L, 0.8, thick + 0.8), top_col, mid, true)   # başlık çarpışmalı: surun tepesinde yürürken içinden geçilmesin
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
			box(Vector3(wc.x, g.y + wh + 0.5, wc.y), Vector3(wing + 1.2, 1.0, 9.0 if gap_deg > 0.0 else 3.8), roof_col, ang, true)  # mazgal başlığı (üstünde yürünür)
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
	if key in TREELESS:
		return   # kanonda ağaçsız köy (kullanıcı 2026-11-10: lore'a göre ağaç yok)
	# prosedürel ağaç (hazır paket ağaçları doğal durmuyordu; kullanıcı eskisini tercih etti)
	if _tree_meshes.is_empty():
		for v in Props.VILLAGE_TREE_W.size():
			_tree_meshes.append(Props.village_tree_mesh(v))   # tür başına tek mesh: hücre başına tür başına tek MultiMesh
		_tree_mesh = _tree_meshes[0]
	# tür: ağırlıklı rastgele (hep aynı ağaç olmasın)
	var tot = 0
	for wv in Props.VILLAGE_TREE_W:
		tot += wv
	var pick = rng.randi() % tot
	var vi = 0
	while pick >= Props.VILLAGE_TREE_W[vi]:
		pick -= Props.VILLAGE_TREE_W[vi]
		vi += 1
	var tm = _tree_meshes[vi]
	if _underwater(x, n, y):
		return   # su altında ağaç yok
	for gx in range(-1, 2):   # yalnız evler (32 m ızgara): tacı binanın içinden fışkırmasın; saksı ağaçları etkilenmez
		for gz in range(-1, 2):
			for h in house_grid.get(Vector2i(floori(x / 32.0) + gx, floori(n / 32.0) + gz), []):
				if Vector2(x - float(h[0]), n - float(h[1])).length() < maxf(float(h[2]), float(h[3])) * 0.5 + 2.2 * s:
					return
	if tm != null:
		var sc = s * rng.randf_range(0.85, 1.15)
		var rot = rng.randf() * 360.0
		pack_mesh(tm, Vector3(x, y, n), rot, sc, 1.0)
		tree_limbs(tm, Vector3(x, y, n), rot, sc)
		leaf_spots.append([w(Vector3(x, y + Props.VILLAGE_TREE_TOP[vi] * sc, n)), Props.VILLAGE_TREE_LEAF[vi], 3.0 * sc])
		add_solid(w(Vector3(x, 0, n)), 2.6 * s, 2.6 * s, 0.0)   # yerleşim için taç genişliği (gövde değil): sonradan konan evlerin içinden ağaç geçmesin
		if tm is ArrayMesh and tm.has_meta("trunk") and is_instance_valid(body):   # gövdenin kendisi (ince/eğik gövdede kalın dik silindir boşluğa çarpıyordu)
			var T: Array = tm.get_meta("trunk")
			var tb = Transform3D(Basis(Vector3.UP, deg_to_rad(rot)) * Basis.from_scale(Vector3.ONE * sc), w(Vector3(x, y, n)))
			var tcs = CollisionShape3D.new()
			var cap = CapsuleShape3D.new()
			cap.radius = float(T[2]) * sc
			cap.height = maxf(cap.radius * 2.0 + 0.01, ((T[1] as Vector3) - (T[0] as Vector3)).length() * sc + cap.radius * 2.0)
			tcs.shape = cap
			var lx = AnimeTree.limb_xf(T[0], T[1])
			tcs.transform = Transform3D(tb.basis.orthonormalized() * lx.basis, tb * lx.origin)
			add_shape(tcs)
		else:
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
## Bu yerel noktada taban su yüzeyinin (deniz seviyesi 0) altında mı (arazi de suyun altında)
func _underwater(x: float, n: float, y: float) -> bool:
	var wp = w(Vector3(x, y, n))
	return wp.y < -0.3 and Game.terrain_height(wp.x, wp.z) < -0.3


func prop(kind: String, p: Vector3, yaw_deg := 0.0, height := 0.0, collide := 0.0) -> bool:
	if _underwater(p.x, p.z, p.y):
		return true   # su altında süs yok (true: çağıran yedek prosedürel modeli de kurmasın)
	var m = AssetLib.prop(kind, height)
	if m == null:
		return false
	pack_mesh(m, p, yaw_deg, 1.0, 0.7)
	if collide > 0.0:
		var hh = maxf(1.0, height if height > 0.0 else 2.0)
		_collide_cyl(w(p + Vector3(0, hh * 0.5, 0)), collide, hh)
	return true


func lantern(x: float, n: float, h := 3.2) -> void:
	# bölgenin feneri (lantern_region): h = eski taş fenerin tepe yüksekliği (zemin + 3.2)
	var wp = w(Vector3(x, 0, n))
	var rg = Builder.lantern_region(wp.x, wp.z)
	lantern_design(x, n, int(rg[0]), h - 3.2, rg[1], bool(rg[2]))


## Bölgeye göre fener: [tasarım, taş rengi (a=0: varsayılan gri), yosunlu mu]. Ülkenin doğasına göre —
## orman (Ateş, Şelale, Dalga): ahşap direkli kâğıt andon; çöl (Rüzgâr): kumtaşı Kasuga; kayalık (Toprak, Taş, Nehir, Kuzey): gri Kasuga;
## yağmur (Ame) ve dağ (Yıldırım): çift fenerli uzun sokak direği; çayır / pirinç (Çim, Kaplıca, Girdap, Ses): asılı kırmızı chōchin;
## kar (Kırağı, Demir): alçak yukimi (kar seyir feneri); bataklık (Su / Kiri): koyu yosunlu Kasuga
const LANTERN_BY_BIOME := {"forest": [2, Color(0, 0, 0, 0), true], "desert": [1, Color(0.8, 0.68, 0.5), false], "rock": [1, Color(0, 0, 0, 0), false],
	"rain": [5, Color(0, 0, 0, 0), false], "mountain": [5, Color(0, 0, 0, 0), false], "grass": [3, Color(0, 0, 0, 0), false], "rice": [3, Color(0, 0, 0, 0), false],
	"snow": [4, Color(0.72, 0.74, 0.78), false], "swamp": [1, Color(0.46, 0.5, 0.47), true]}
static var _lantern_cache := {}
static func lantern_region(wx: float, wz: float) -> Array:
	var ck = Vector2i(floori(wx / 256.0), floori(wz / 256.0))
	if _lantern_cache.has(ck):
		return _lantern_cache[ck]
	var m = Vector2(wx, -wz)
	var best = ""
	var bd = 1e18
	var bio := {}
	for c in Game.world_info.get("countries", []):
		bio[String(c["id"])] = String(c.get("biome", "forest"))
		var d = m.distance_squared_to(Vector2(float(c["x"]), float(c["y"])))
		if d < bd:
			bd = d
			best = String(c.get("biome", "forest"))
	for v in Game.world_info.get("villages", []):   # köy, ülke merkezinden uzak olabilir (Iwa): köyün kendi ülkesi sayılır
		var d2 = m.distance_squared_to(Vector2(float(v["x"]), float(v["y"])))
		if d2 < bd:
			bd = d2
			best = String(bio.get(String(v.get("country", "")), best))
	var r: Array = LANTERN_BY_BIOME.get(best, LANTERN_BY_BIOME["forest"])
	_lantern_cache[ck] = r
	return r


## Fener tasarımları: 1 Kasuga taş fener, 2 ahşap direkli kâğıt andon, 3 direğe asılı kırmızı chōchin,
## 4 alçak üç ayaklı yukimi taş fener, 5 çift fenerli uzun sokak direği. gy: zemin yüksekliği. Işıklı parçalar GLOW renginde (gece yanar).
## tint (a>0): taş rengi (kumtaşı, karlı gri...); mossy=false: yosun lekesi yok (çöl, kar, kayalık)
const LANTERN_GLOW := Color(1.0, 0.85, 0.5)
const LANTERN_RED := Color(0.9, 0.2, 0.15)   # toon gölgelendirici bu rengi gece kırmızı kâğıt fener olarak yakar
func lantern_design(x: float, n: float, style: int, gy := 0.0, tint := Color(0, 0, 0, 0), mossy := true) -> void:
	var stone = Color(0.6, 0.6, 0.58)
	var stone_d = Color(0.47, 0.48, 0.46)
	if tint.a > 0.0:
		stone = Color(tint.r, tint.g, tint.b)
		stone_d = stone.darkened(0.2)
	var moss = Color(0.36, 0.5, 0.3) if mossy else stone.lightened(0.06)
	var wood = Color(0.3, 0.2, 0.13)
	var wood_l = Color(0.45, 0.31, 0.19)
	var tile = Color(0.2, 0.22, 0.26)
	var light_y = gy + 1.9
	match style:
		1:
			# Kasuga tōrō: altıgen kaide, boğumlu gövde, tabla, pencereli ateş odası, kıvrık saçaklı şapka, tepe mücevheri
			cyl(Vector3(x, gy + 0.08, n), 0.95, 0.16, stone_d, false, 6)
			cyl(Vector3(x, gy + 0.22, n), 0.72, 0.14, stone, false, 6)
			cyl(Vector3(x, gy + 0.85, n), 0.3, 1.14, stone, true, 10)
			cyl(Vector3(x, gy + 0.85, n), 0.4, 0.09, stone_d, false, 10)
			cyl(Vector3(x, gy + 1.38, n), 0.46, 0.1, stone_d, false, 6)
			cyl(Vector3(x, gy + 1.5, n), 0.86, 0.14, stone, false, 6)
			box(Vector3(x, gy + 1.84, n), Vector3(0.4, 0.5, 0.4), LANTERN_GLOW, 0, false)
			for cx in [-1.0, 1.0]:
				for cz in [-1.0, 1.0]:
					box(Vector3(x + cx * 0.23, gy + 1.84, n + cz * 0.23), Vector3(0.1, 0.54, 0.1), stone, 0, false)
			for cy in [1.6, 2.08]:
				box(Vector3(x, gy + cy, n), Vector3(0.58, 0.07, 0.58), stone_d, 0, false)
			for q in 4:   # pencere çıtaları
				var a = q * 90.0
				var o = Builder.rot(0.0, 0.215, a)
				box(Vector3(x + o.x, gy + 1.84, n + o.y), Vector3(0.36, 0.04, 0.03), stone_d, a, false)
			cyl(Vector3(x, gy + 2.15, n), 1.25, 0.07, stone_d, false, 6)
			cone(Vector3(x, gy + 2.38, n), 1.12, 0.42, stone, 6)
			sphere(Vector3(x, gy + 2.66, n), Vector3(0.22, 0.26, 0.22), stone_d, 8)
			sphere(Vector3(x + 0.2, gy + 2.3, n - 0.15), Vector3(0.5, 0.16, 0.42), moss, 6)
			sphere(Vector3(x - 0.25, gy + 0.2, n + 0.2), Vector3(0.4, 0.14, 0.36), moss, 6)
			light_y = gy + 1.84
		2:
			# ahşap direkli andon: taş ayak, koyu ahşap direk, çıtalı kâğıt fener kutusu, küçük kiremit şapka
			box(Vector3(x, gy + 0.12, n), Vector3(0.5, 0.24, 0.5), stone, 0, false)
			box(Vector3(x, gy + 0.85, n), Vector3(0.16, 1.3, 0.16), wood, 0, true)
			box(Vector3(x, gy + 1.52, n), Vector3(0.62, 0.07, 0.62), wood, 0, false)
			box(Vector3(x, gy + 1.9, n), Vector3(0.46, 0.68, 0.46), LANTERN_GLOW, 0, false)
			for cx in [-1.0, 1.0]:
				for cz in [-1.0, 1.0]:
					box(Vector3(x + cx * 0.24, gy + 1.9, n + cz * 0.24), Vector3(0.055, 0.72, 0.055), wood, 0, false)
			for q in 4:
				var a = q * 90.0
				var o = Builder.rot(0.0, 0.245, a)
				for cy in [1.72, 1.9, 2.08]:
					box(Vector3(x + o.x, gy + cy, n + o.y), Vector3(0.46, 0.03, 0.025), wood, a, false)
				box(Vector3(x + o.x, gy + 1.9, n + o.y), Vector3(0.03, 0.66, 0.025), wood, a, false)
			box(Vector3(x, gy + 2.27, n), Vector3(0.62, 0.06, 0.62), wood, 0, false)
			cone(Vector3(x, gy + 2.47, n), 1.0, 0.36, tile, 4)
			sphere(Vector3(x, gy + 2.68, n), Vector3(0.12, 0.14, 0.12), wood, 6)
		3:
			# direğe asılı chōchin: uzun ahşap direk, yatay kol, ipte sallanan kırmızı kâğıt fener (koyu kapaklar + çemberler)
			box(Vector3(x, gy + 0.1, n), Vector3(0.44, 0.2, 0.44), stone, 0, false)
			box(Vector3(x, gy + 1.5, n), Vector3(0.14, 2.8, 0.14), wood, 0, true)
			box(Vector3(x + 0.38, gy + 2.72, n), Vector3(0.95, 0.1, 0.1), wood, 0, false)
			box(Vector3(x + 0.2, gy + 2.5, n), Vector3(0.07, 0.42, 0.07), wood_l, 0, false, Vector3(0, 0, 45))
			box(Vector3(x, gy + 2.95, n), Vector3(0.3, 0.07, 0.3), tile, 0, false)
			box(Vector3(x + 0.72, gy + 2.55, n), Vector3(0.02, 0.26, 0.02), Color(0.15, 0.12, 0.1), 0, false)
			cyl(Vector3(x + 0.72, gy + 2.4, n), 0.24, 0.07, Color(0.12, 0.1, 0.1), false, 10)
			sphere(Vector3(x + 0.72, gy + 2.06, n), Vector3(0.52, 0.66, 0.52), LANTERN_RED, 12)
			for cy in [1.9, 2.06, 2.22]:
				cyl(Vector3(x + 0.72, gy + cy, n), 0.53 if cy == 2.06 else 0.49, 0.018, Color(0.55, 0.1, 0.08), false, 12)
			cyl(Vector3(x + 0.72, gy + 1.72, n), 0.24, 0.07, Color(0.12, 0.1, 0.1), false, 10)
			box(Vector3(x + 0.72, gy + 1.58, n), Vector3(0.03, 0.22, 0.03), Color(0.75, 0.15, 0.1), 0, false)
			light_y = gy + 2.06
		4:
			# yukimi: üç kıvrık ayak, altıgen tabla, altıgen ateş odası, geniş basık şapka, yosun
			for q in 3:
				var a = q * 120.0 + 30.0
				var o = Builder.rot(0.0, 0.34, a)
				box(Vector3(x + o.x, gy + 0.3, n + o.y), Vector3(0.16, 0.62, 0.2), stone, a, false)
				box(Vector3(x + o.x * 1.25, gy + 0.06, n + o.y * 1.25), Vector3(0.2, 0.12, 0.3), stone_d, a, false)
			cyl(Vector3(x, gy + 0.66, n), 0.95, 0.12, stone_d, true, 6)
			cyl(Vector3(x, gy + 0.98, n), 0.5, 0.5, LANTERN_GLOW, false, 6)
			for q in 6:
				var a = q * 60.0
				var o = Builder.rot(0.0, 0.27, a + 30.0)
				box(Vector3(x + o.x, gy + 0.98, n + o.y), Vector3(0.09, 0.52, 0.09), stone, a + 30.0, false)
			cyl(Vector3(x, gy + 1.26, n), 0.7, 0.07, stone_d, false, 6)
			cyl(Vector3(x, gy + 1.33, n), 1.75, 0.07, stone_d, false, 6)
			cone(Vector3(x, gy + 1.52, n), 1.6, 0.34, stone, 6)
			sphere(Vector3(x, gy + 1.74, n), Vector3(0.24, 0.2, 0.24), stone_d, 8)
			sphere(Vector3(x + 0.3, gy + 1.5, n + 0.1), Vector3(0.7, 0.16, 0.6), moss, 6)
			sphere(Vector3(x - 0.4, gy + 1.44, n - 0.25), Vector3(0.45, 0.12, 0.4), moss.darkened(0.1), 6)
			light_y = gy + 0.98
		_:
			# sokak direği: uzun ahşap direk, kiremit şapka, çapraz kol, iki yanda asılı kâğıt fener kutuları
			box(Vector3(x, gy + 0.14, n), Vector3(0.5, 0.28, 0.5), stone, 0, false)
			box(Vector3(x, gy + 1.75, n), Vector3(0.18, 3.3, 0.18), wood, 0, true)
			box(Vector3(x, gy + 3.05, n), Vector3(1.5, 0.1, 0.12), wood, 0, false)
			box(Vector3(x, gy + 2.86, n), Vector3(0.9, 0.07, 0.09), wood_l, 0, false)
			cone(Vector3(x, gy + 3.58, n), 0.8, 0.3, tile, 4)
			box(Vector3(x, gy + 3.42, n), Vector3(0.46, 0.05, 0.46), wood, 0, false)
			for sx in [-1.0, 1.0]:
				var lx = x + sx * 0.62
				box(Vector3(lx, gy + 2.9, n), Vector3(0.02, 0.24, 0.02), Color(0.15, 0.12, 0.1), 0, false)
				box(Vector3(lx, gy + 2.76, n), Vector3(0.36, 0.05, 0.36), wood, 0, false)
				box(Vector3(lx, gy + 2.5, n), Vector3(0.3, 0.48, 0.3), LANTERN_GLOW, 0, false)
				for cx in [-1.0, 1.0]:
					for cz in [-1.0, 1.0]:
						box(Vector3(lx + cx * 0.155, gy + 2.5, n + cz * 0.155), Vector3(0.04, 0.5, 0.04), wood, 0, false)
				for q in 4:
					var a = q * 90.0
					var o = Builder.rot(0.0, 0.158, a)
					box(Vector3(lx + o.x, gy + 2.5, n + o.y), Vector3(0.3, 0.025, 0.02), wood, a, false)
				box(Vector3(lx, gy + 2.24, n), Vector3(0.36, 0.05, 0.36), wood, 0, false)
				box(Vector3(lx, gy + 2.12, n), Vector3(0.03, 0.2, 0.03), Color(0.75, 0.15, 0.1), 0, false)
			light_y = gy + 2.5
	Lights.add(w(Vector3(x, light_y, n)))


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
