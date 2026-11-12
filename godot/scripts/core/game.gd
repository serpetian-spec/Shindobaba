extends Node
## Global oyun durumu (autoload "Game"): dünya verisi, arazi sorguları, ayarlar, profil, kayıt.

const SAVE_DIR := "user://kayitlar"
const SETTINGS_PATH := "user://ayarlar.cfg"

var world_info: Dictionary = {}
var heights: PackedFloat32Array
var hw: int = 0
var hh: int = 0
var x0: float = 0.0
var y1: float = 0.0
var res: float = 4.0
var height_tex: ImageTexture
var albedo_tex: Texture2D
var biome_img: Image

var settings := {
	"sens": 1.0, "ui_scale": 1.0, "fov": 70.0, "music": 0.5, "sfx": 0.8, "view": 1.0, "fullscreen": false,
	"shadows": true, "outline": true, "dreamy": true, "blood": true, "invert_y": false, "show_fps": false, "quality": 2,
}
var profile: Dictionary = {}
var paused := false
var ui_open := false
var player: Node3D = null
var world: Node3D = null
var hud: Node = null
var build_tag := "dev"
var version := "0.2.0"


## Oyun saati (sn): duraklatmada/menüde durur. Düşman bekleme süreleri gerçek saatle tutuluyordu: menüden dönünce
## düşmanın jutsuları hazır oluyordu (oyuncununki donarken). Bekleme süreleri bununla tutulur.
var clock := 0.0


func now() -> float:
	return clock


func _process(dt: float) -> void:
	if not paused and not get_tree().paused:
		clock += dt


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_build_info()
	load_settings()
	_load_world()
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _load_build_info() -> void:
	var f := FileAccess.open("res://data/build.json", FileAccess.READ)
	if f:
		var d = JSON.parse_string(f.get_as_text())
		if d:
			build_tag = d.get("build", "dev")
			version = d.get("version", version)


# ------------------------------------------------------------------ dünya verisi
## Dünya (v3, ~77 x 64 km): makro harita 32 m/piksel + deterministik ayrıntı gürültüsü + yüksek çözünürlüklü yamalar.
## terrain_height, shaders/world_height.gdshaderinc ile BİREBİR aynı formülü kullanır (çarpışma = görüntü).
const WORLD_VERSION := 3
var biome_bytes: PackedByteArray   # RGBA8 (R biyom, G kaba yol, B ıslak, A ayrıntı genliği)
var shape_bytes: PackedByteArray   # RGBA8 (R sırt, G mesa, B kum tepesi, A kaya çıkıntısı)
var biome_tex: ImageTexture
var shape_tex: ImageTexture
var detail_max := 26.0
var patches: Array = []            # {x0, z0, size, n, res, fade, data: PackedFloat32Array, tex}
var roads: Array = []              # {a, b, kind, pts: PackedVector2Array (harita x,y)}
var rivers: Array = []
var pois: Array = []
var _road_grid := {}               # Vector2i(256 m) -> [[yol idx, parça idx]]
const ROAD_CELL := 256.0
const ROAD_HALF := {"road": 5.0, "street": 6.0, "path": 2.0}


func _load_world() -> void:
	world_info = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/world.json"))
	var w: Dictionary = world_info["world"]
	hw = int(w["w"]); hh = int(w["h"])
	x0 = float(w["x0"]); y1 = float(w["y1"]); res = float(w["res"])
	detail_max = float(w.get("detail_max", 26.0))
	var bytes := FileAccess.get_file_as_bytes("res://data/world/height.bin")
	heights = bytes.to_float32_array()
	height_tex = ImageTexture.create_from_image(Image.create_from_data(hw, hh, false, Image.FORMAT_RF, bytes))
	albedo_tex = load("res://data/world/albedo.png")
	biome_img = (load("res://data/world/biome.png") as Texture2D).get_image()
	biome_img.convert(Image.FORMAT_RGBA8)
	biome_bytes = biome_img.get_data()
	biome_tex = ImageTexture.create_from_image(biome_img)
	var shape_img := (load("res://data/world/shape.png") as Texture2D).get_image()
	shape_img.convert(Image.FORMAT_RGBA8)
	shape_bytes = shape_img.get_data()
	shape_tex = ImageTexture.create_from_image(shape_img)
	for pd in world_info.get("patches", []):
		var pb := FileAccess.get_file_as_bytes("res://data/world/patch_%s.bin" % pd["id"])
		var n := int(pd["n"])
		patches.append({"id": pd["id"], "x0": float(pd["x0"]), "z0": -float(pd["y1"]), "size": float(pd["size"]), "n": n,
			"res": float(pd["res"]), "fade": float(pd["fade"]), "data": pb.to_float32_array(),
			"tex": ImageTexture.create_from_image(Image.create_from_data(n, n, false, Image.FORMAT_RF, pb))})
	_default_gates()
	for rl in JSON.parse_string(FileAccess.get_file_as_string("res://data/world/roads.json")):
		var pts := PackedVector2Array()
		for q in rl["pts"]:
			pts.append(Vector2(q[0], q[1]))
		roads.append({"a": rl["a"], "b": rl["b"], "kind": rl["kind"], "pts": pts})
	_fix_village_roads()
	for ri in range(roads.size()):
		var pts: PackedVector2Array = roads[ri]["pts"]
		for si in range(pts.size() - 1):
			var a2 := pts[si]
			var b2 := pts[si + 1]
			var lo := Vector2(minf(a2.x, b2.x), minf(a2.y, b2.y)) - Vector2.ONE * 20.0
			var hi := Vector2(maxf(a2.x, b2.x), maxf(a2.y, b2.y)) + Vector2.ONE * 20.0
			for cx in range(floori(lo.x / ROAD_CELL), floori(hi.x / ROAD_CELL) + 1):
				for cy in range(floori(lo.y / ROAD_CELL), floori(hi.y / ROAD_CELL) + 1):
					var k := Vector2i(cx, cy)
					if not _road_grid.has(k):
						_road_grid[k] = []
					_road_grid[k].append([ri, si])
	rivers = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/rivers.json"))
	pois = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/pois.json"))


## Godot dünya koordinatı -> harita (x doğu, y kuzey)
func to_map(p: Vector3) -> Vector2:
	return Vector2(p.x, -p.z)


func from_map(m: Vector2, h: float = NAN) -> Vector3:
	var y := terrain_height(m.x, -m.y) if is_nan(h) else h
	return Vector3(m.x, y, -m.y)


# --- shader ile aynı deterministik gürültü (32 bit tamsayı hash)
static func _wh_hash(px: int, pz: int, seed: int) -> int:
	var h := ((px & 0xFFFFFFFF) * 374761393 + (pz & 0xFFFFFFFF) * 668265263 + seed * 2246822519) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	return h ^ (h >> 16)


static func _wh_lat(px: int, pz: int, seed: int) -> float:
	return float(_wh_hash(px, pz, seed) & 16777215) / 16777215.0


static func _wh_vn(x: float, z: float, seed: int) -> float:
	var ix := floori(x)
	var iz := floori(z)
	var fx := x - ix
	var fz := z - iz
	var ux := fx * fx * (3.0 - 2.0 * fx)
	var uz := fz * fz * (3.0 - 2.0 * fz)
	var a := lerpf(_wh_lat(ix, iz, seed), _wh_lat(ix + 1, iz, seed), ux)
	var b := lerpf(_wh_lat(ix, iz + 1, seed), _wh_lat(ix + 1, iz + 1, seed), ux)
	return lerpf(a, b, uz)


static func _terrace(h: float, step_h: float, edge: float) -> float:
	var k := h / step_h
	var f := clampf((k - floor(k) - edge) / (1.0 - edge), 0.0, 1.0)
	f = f * f * (3.0 - 2.0 * f)
	return (floor(k) + f) * step_h


## Makro bilinear hücresi: [i00, tx, tz] (shader wh_bilin ile aynı: kenarda kenetlenir)
func _macro_cell(x: float, z: float) -> Array:
	var fx := (x - x0) / res - 0.5
	var fz := (z + y1) / res - 0.5
	var fix := floori(fx)
	var fiz := floori(fz)
	var ix := clampi(fix, 0, hw - 2)
	var iz := clampi(fiz, 0, hh - 2)
	return [iz * hw + ix, clampf(fx - fix, 0.0, 1.0), clampf(fz - fiz, 0.0, 1.0)]


func _bytes_bilin(b: PackedByteArray, i: int, ch: int, tx: float, tz: float) -> float:
	var a := lerpf(b[i * 4 + ch], b[(i + 1) * 4 + ch], tx)
	var c := lerpf(b[(i + hw) * 4 + ch], b[(i + hw + 1) * 4 + ch], tx)
	return lerpf(a, c, tz) / 255.0


## Ayrıntı genliği 0..1 (köyler/yollar 0)
func detail_amp(x: float, z: float) -> float:
	var c := _macro_cell(x, z)
	return _bytes_bilin(biome_bytes, c[0], 3, c[1], c[2])


## Arazi yüksekliği (x, z Godot dünya koordinatı)
func terrain_height(x: float, z: float) -> float:
	var c := _macro_cell(x, z)
	var i: int = c[0]
	var tx: float = c[1]
	var tz: float = c[2]
	var h := lerpf(lerpf(heights[i], heights[i + 1], tx), lerpf(heights[i + hw], heights[i + hw + 1], tx), tz)
	var amp := _bytes_bilin(biome_bytes, i, 3, tx, tz)
	if amp > 0.002:
		var sr := _bytes_bilin(shape_bytes, i, 0, tx, tz)
		var f := _wh_vn(x / 300.0, z / 300.0, 1) * 0.5 + _wh_vn(x / 150.0, z / 150.0, 2) * 0.3 + _wh_vn(x / 70.0, z / 70.0, 3) * 0.2
		var r1 := 1.0 - absf(_wh_vn(x / 520.0, z / 520.0, 4) * 2.0 - 1.0)
		var r2 := 1.0 - absf(_wh_vn(x / 230.0, z / 230.0, 5) * 2.0 - 1.0)
		var fine := _wh_vn(x / 24.0, z / 24.0, 6)
		var d := (f - 0.5) + sr * ((r1 * r1 * 0.7 + r2 * r2 * 0.3) - 0.45) * 1.6 + (fine - 0.5) * 0.08
		h += d * amp * detail_max
		var gate := clampf(amp * 5.0, 0.0, 1.0)
		var mesa := _bytes_bilin(shape_bytes, i, 1, tx, tz) * gate
		if mesa > 0.004:
			h = lerpf(h, _terrace(h + 6.0, 22.0, 0.8), mesa)
		var outc := _bytes_bilin(shape_bytes, i, 3, tx, tz) * gate
		if outc > 0.004:
			h = lerpf(h, _terrace(h, 14.0, 0.75) + 10.0, outc)
		var dune := _bytes_bilin(shape_bytes, i, 2, tx, tz) * gate
		if dune > 0.004:
			h += dune * pow(absf(sin((x * 0.9 - z * 0.4) / 38.0 + _wh_vn(x / 300.0, z / 300.0, 7) * 6.0)), 1.5) * 12.0
	for pt in patches:
		var lx: float = x - pt["x0"]
		var lz: float = z - pt["z0"]
		var sz: float = pt["size"]
		if lx < 0.0 or lz < 0.0 or lx > sz or lz > sz:
			continue
		var n: int = pt["n"]
		var pr: float = pt["res"]
		var pfx := lx / pr - 0.5
		var pfz := lz / pr - 0.5
		var pix := clampi(floori(pfx), 0, n - 2)
		var piz := clampi(floori(pfz), 0, n - 2)
		var ptx := clampf(pfx - floori(pfx), 0.0, 1.0)
		var ptz := clampf(pfz - floori(pfz), 0.0, 1.0)
		var dat: PackedFloat32Array = pt["data"]
		var j := piz * n + pix
		var v := lerpf(lerpf(dat[j], dat[j + 1], ptx), lerpf(dat[j + n], dat[j + n + 1], ptx), ptz)
		var e := minf(minf(lx, lz), minf(sz - lx, sz - lz))
		var wgt := clampf(e / float(pt["fade"]), 0.0, 1.0)
		wgt = wgt * wgt * (3.0 - 2.0 * wgt)
		h = lerpf(h, v, wgt)
	return h


func terrain_normal(x: float, z: float) -> Vector3:
	var e := 1.5
	var hx := terrain_height(x + e, z) - terrain_height(x - e, z)
	var hz := terrain_height(x, z + e) - terrain_height(x, z - e)
	return Vector3(-hx, 2.0 * e, -hz).normalized()


## Yürünebilir zemin: deniz/nehir yüzeyi (y=0) ve kayıtlı su yüzeyleri (gölet, kanal, Sonun Vadisi) ninja için zemindir.
func ground_height(x: float, z: float, on_water := true) -> float:
	var h := terrain_height(x, z)
	if not on_water:
		return h
	return maxf(h, water_level(x, z, h))


# ------------------------------------------------------------------ su yüzeyleri
## Arazinin üstüne/altına konan su meshleri (köy göleti, kanal, şelale havuzu) burada kayıtlıdır; deniz/nehir y=0.
## Kayıt mesh'e bağlı: mesh silinince (yapı boşaltılınca) kayıt da düşer.
const WATER_CELL := 32.0
var _water_grid := {}   # Vector2i -> [[mesh, merkez(Vector2), yarı boyut(Vector2), yaw, y, oval]]
var water_list: Array = []   # aynı kayıtlar sırayla (köy pişirme önbelleği dilimler: VillageBake)


## Düz su yüzeyi kaydı: c dünya xz merkezi, size tam boyut, yaw (radyan, mesh rotation.y), y yüzey yüksekliği
func add_water(owner: Node, c: Vector2, size: Vector2, yaw: float, y: float, oval := false) -> void:
	var e = [owner, c, size * 0.5, yaw, y, oval]
	water_list.append(e)
	var r = size.length() * 0.5
	for i in range(floori((c.x - r) / WATER_CELL), floori((c.x + r) / WATER_CELL) + 1):
		for j in range(floori((c.y - r) / WATER_CELL), floori((c.y + r) / WATER_CELL) + 1):
			var k = Vector2i(i, j)
			if not _water_grid.has(k):
				_water_grid[k] = []
			_water_grid[k].append(e)


## PlaneMesh/QuadMesh-yatay mesh: global dönüşümünden kaydet (ölçek dahil)
func add_water_mesh(mi: MeshInstance3D, size: Vector2, oval := false) -> void:
	if not mi.is_inside_tree():
		mi.tree_entered.connect(add_water_mesh.bind(mi, size, oval), CONNECT_ONE_SHOT)
		return
	var t = mi.global_transform
	var sc = Vector2(t.basis.x.length(), t.basis.z.length())
	add_water(mi, Vector2(t.origin.x, t.origin.z), size * sc, mi.global_rotation.y, t.origin.y, oval)


## Bu noktadaki su yüzeyi: kayıtlı yüzey varsa onun y'si; yoksa arazi suyun altındaysa deniz (0); değilse -INF
func water_level(x: float, z: float, terr := NAN) -> float:
	var k = Vector2i(floori(x / WATER_CELL), floori(z / WATER_CELL))
	var best := -INF
	var lst = _water_grid.get(k)
	if lst:
		var i := 0
		while i < lst.size():
			var e = lst[i]
			if not is_instance_valid(e[0]):
				lst.remove_at(i)
				continue
			i += 1
			var d = Vector2(x, z) - e[1]
			d = d.rotated(e[3])
			var hs: Vector2 = e[2]
			var inside = (d.x / hs.x) * (d.x / hs.x) + (d.y / hs.y) * (d.y / hs.y) <= 1.0 if e[5] else absf(d.x) <= hs.x and absf(d.y) <= hs.y
			if inside:
				best = maxf(best, e[4])
	if is_nan(terr):
		terr = terrain_height(x, z)
	return maxf(best, 0.0) if terr < 0.0 else best   # deniz düzlemi (y=0) arazi suyun altındaysa her yeri kaplar


## Jutsu/efekt zemini: iç mekândayken (mağara, dükkân — dünyanın 1500 m üstünde) oda zemini, yoksa arazi.
## (Yer jutsuları mağarada 1500 m aşağıda patlıyordu.) Yalnız savaş/efekt kodu kullanır; NPC yürüyüşü ground_height ile kalır.
func jutsu_floor(x: float, z: float) -> float:
	var it = Interiors.inst
	if it and it.inside != "" and Vector2(x - it.origin.x, z - it.origin.z).length() < 160.0:   # Chūnin salonu 50 m'den büyük: uzak uçta araziye (1500 m aşağı) düşülüyordu
		return it.origin.y
	return ground_height(x, z)


## Adım sesi: iç mekân tahta, köy sokağı taş, yol toprak, gerisi çimen/toprak (3 varyasyon)
func step_sound(p: Vector3) -> String:
	var v = randi() % 3
	var it = Interiors.inst
	if it and it.inside != "":
		return "step_stone%d" % v if it.inside.begins_with("lair_") else "step_wood%d" % v
	if biome_at(p.x, p.z) in [1, 3, 13]:
		return "step_sand"   # kumsal, çöl, Suna (sokakları da sıkışmış kum; eskiden taş/toprak adımı tahta gibi çalıyordu)
	if road_at(p.x, p.z, "street") > 0.3:
		return "step_stone%d" % v
	if road_at(p.x, p.z) > 0.3:
		return "step_dirt%d" % v
	if water_level(p.x, p.z, terrain_height(p.x, p.z)) > terrain_height(p.x, p.z) + 0.02:
		return "step_water"   # suyun içinde/üstünde yürüme: şıpırtı
	var b = biome_at(p.x, p.z)   # 2 orman, 4 yağmur, 6 pirinç, 7 çimen, 10 bataklık | 5 kaya, 9 dağ, 14 taş köy
	if b in [2, 4, 6, 7, 10]:
		return "step_grass%d" % v
	if b in [8, 15]:
		return "step_snow"   # karlı dağ/köy: gerçek kar adımı (CC0 varyantlı)
	if b in [5, 9, 14]:
		return "step_stone%d" % v
	return "step_dirt%d" % v


func biome_at(x: float, z: float) -> int:
	var m := Vector2(x, -z)
	for v in world_info["villages"]:
		if m.distance_squared_to(Vector2(v["x"], v["y"])) < pow(float(v["r"]) * 0.95, 2.0):
			return int(v.get("ground", 11))
	var px := clampi(int((x - x0) / res), 0, hw - 1)
	var pz := clampi(int((z + y1) / res), 0, hh - 1)
	return int(biome_bytes[(pz * hw + px) * 4])


## Islaklık 0..1 (nehir kıyısı)
func wet_at(x: float, z: float) -> float:
	var c := _macro_cell(x, z)
	return _bytes_bilin(biome_bytes, c[0], 2, c[1], c[2])


## Yol: 1 = yolun ortası, 0 = yol dışı. kind: "" hepsi, "road" ya da "street"
func road_at(x: float, z: float, kind := "") -> float:
	var m := Vector2(x, -z)
	var lst = _road_grid.get(Vector2i(floori(m.x / ROAD_CELL), floori(m.y / ROAD_CELL)))
	if lst == null:
		return 0.0
	var best := 0.0
	for e in lst:
		var rl: Dictionary = roads[e[0]]
		if kind != "" and rl["kind"] != kind:
			continue
		var pts: PackedVector2Array = rl["pts"]
		var q := Geometry2D.get_closest_point_to_segment(m, pts[e[1]], pts[e[1] + 1])
		var half: float = ROAD_HALF.get(rl["kind"], 5.0)
		best = maxf(best, 1.0 - smoothstep(half * 0.7, half + 3.0, q.distance_to(m)))
	return best


## En yakın yol/cadde orta çizgisine uzaklık (m); yakında yol yoksa 1e9
func road_dist(x: float, z: float) -> float:
	var m := Vector2(x, -z)
	var lst = _road_grid.get(Vector2i(floori(m.x / ROAD_CELL), floori(m.y / ROAD_CELL)))
	if lst == null:
		return 1e9
	var best := 1e9
	for e in lst:
		var pts: PackedVector2Array = roads[e[0]]["pts"]
		best = minf(best, Geometry2D.get_closest_point_to_segment(m, pts[e[1]], pts[e[1] + 1]).distance_to(m))
	return best


## Merkez çevresindeki yol parçaları: [Vector2i(yol idx, parça idx)]
func road_segments_near(m: Vector2, radius: float) -> Array:
	var out := {}
	for cx in range(floori((m.x - radius) / ROAD_CELL), floori((m.x + radius) / ROAD_CELL) + 1):
		for cy in range(floori((m.y - radius) / ROAD_CELL), floori((m.y + radius) / ROAD_CELL) + 1):
			for e in _road_grid.get(Vector2i(cx, cy), []):
				out[Vector2i(e[0], e[1])] = true
	return out.keys()


## Arazi shader'larına ortak yükseklik parametrelerini verir (terrain, grass)
func setup_height_material(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("heightmap", height_tex)
	mat.set_shader_parameter("biome_map", biome_tex)
	mat.set_shader_parameter("shape_map", shape_tex)
	mat.set_shader_parameter("world_rect", world_rect())
	mat.set_shader_parameter("macro_size", Vector2(hw, hh))
	mat.set_shader_parameter("macro_res", res)
	mat.set_shader_parameter("detail_max", detail_max)
	var rects := []
	var infos := []
	for k in 3:
		if k < patches.size():
			var pt: Dictionary = patches[k]
			mat.set_shader_parameter("patch%d" % k, pt["tex"])
			rects.append(Vector4(pt["x0"], pt["z0"], pt["size"], pt["fade"]))
			infos.append(Vector3(pt["n"], pt["res"], 0))
		else:
			rects.append(Vector4.ZERO)
			infos.append(Vector3(2, 1, 0))
	mat.set_shader_parameter("patch_rect", rects)
	mat.set_shader_parameter("patch_info", infos)


func world_rect() -> Vector4:
	# x0, z_min, genişlik, derinlik
	return Vector4(x0, -y1, hw * res, hh * res)


## Bir noktanın hangi bölgede olduğunu döndürür (köy > yer > ülke)
func region_name(p: Vector3) -> String:
	var m := to_map(p)
	for v in world_info["villages"]:
		if m.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]):
			return v["name"]
	for l in world_info["landmarks"]:
		if m.distance_to(Vector2(l["x"], l["y"])) < float(l["r"]):
			return l["name"]
	var best := "Açık Deniz"
	var bd := 1e9
	if terrain_height(p.x, p.z) < -1.0:
		return best
	for c in world_info["countries"]:
		var d := m.distance_to(Vector2(c["x"], c["y"])) / float(c["r"])
		if d < bd:
			bd = d; best = c["name"]
	return best


## Yol bağlantısı olmayan surlu köy (Kiri adası) hiç kapısız kalıyordu: rehineler/takipçiler giremiyordu.
## Dışı kara olan, güneye en yakın açıya bir kapı aç.
## Köy uçlarında yol kapıdan çıkıp yeniden köyün içine dönüyor, sonra surdan kapısız geçiyordu (ör. Konoha -> Son Vadisi):
## kapının dışındaki köy içi noktalar atılır, gerekirse yol surun dışından yay çizerek dolanır; yakın başka kapı varsa ona oturur.
## Sonunda yolun sur çizgisini kestiği her açı köyün kapı listesinde olur (kapı + sur boşluğu kurulsun).
func _fix_village_roads() -> void:
	var vmap := {}
	for v in world_info["villages"]:
		vmap[v["id"]] = v
	var comp = func(d: Vector2) -> float:
		return fposmod(rad_to_deg(atan2(d.x, d.y)), 360.0)
	var polar = func(c: Vector2, ang: float, rad: float) -> Vector2:
		return c + Vector2(sin(deg_to_rad(ang)), cos(deg_to_rad(ang))) * rad
	for rd in roads:
		if rd["kind"] != "road":
			continue
		var p: PackedVector2Array = rd["pts"]
		for end in [0, 1]:
			var vid = String(rd["a"] if end == 0 else rd["b"])
			if not vmap.has(vid):
				continue
			var v: Dictionary = vmap[vid]
			var c = Vector2(v["x"], v["y"])
			var r = float(v["r"])
			var q: Array = Array(p)
			if end == 1:
				q.reverse()
			if q.size() < 5 or (q[0] as Vector2).distance_to(c) > 1.0:
				continue
			# yakındaki mevcut kapıya otur (bake ayrı kapı açmadan yolu 12° yanından sokuyordu)
			var ga: float = comp.call((q[2] as Vector2) - c)
			var best = ga
			var bd = 1e9
			for g in v.get("gates", []):
				var dd = absf(fposmod(ga - float(g) + 180.0, 360.0) - 180.0)
				if dd < bd:
					bd = dd
					best = float(g)
			if bd > 0.5 and bd < 14.0:
				ga = best
				q[1] = polar.call(c, ga, r * 0.3)
				q[2] = polar.call(c, ga, r)
				q[3] = polar.call(c, ga, r + 260.0)
			# kapının dışından sonra köye geri dönen noktaları at
			var k = 4
			while k < q.size() - 1 and (q[k] as Vector2).distance_to(c) < r + 200.0:
				k += 1
			q = q.slice(0, 4) + q.slice(k)
			# kapı dışından sonraki noktaya düz gidiş köyü kesiyorsa surun dışından yay çiz
			var o: Vector2 = q[3]
			var nx: Vector2 = q[4]
			if Geometry2D.get_closest_point_to_segment(c, o, nx).distance_to(c) < r + 120.0:
				var a0: float = comp.call(o - c)
				var da = fposmod(float(comp.call(nx - c)) - a0 + 180.0, 360.0) - 180.0
				var steps = maxi(1, int(absf(da) / 12.0))
				var arc = []
				for st in range(1, steps + 1):
					arc.append(polar.call(c, a0 + da * st / steps, r + 320.0))
				q = q.slice(0, 4) + arc + q.slice(4)
			if end == 1:
				q.reverse()
			p = PackedVector2Array(q)
		rd["pts"] = p
	# güvenlik: yolun sur çizgisini kestiği her açıda kapı
	for v in world_info["villages"]:
		if (v.get("gates", []) as Array).is_empty() and not CRAG_WALLS.has(v["id"]):
			continue
		var c = Vector2(v["x"], v["y"])
		var rg = float(v["r"]) * 0.95
		var gl: Array = v.get("gates", [])
		for rd in roads:
			if rd["kind"] != "road":
				continue
			var p: PackedVector2Array = rd["pts"]
			for i in p.size() - 1:
				var da = p[i].distance_to(c) - rg
				var db = p[i + 1].distance_to(c) - rg
				if da * db >= 0.0:
					continue
				var hit = p[i].lerp(p[i + 1], da / (da - db))
				var ang = snappedf(comp.call(hit - c), 0.1)
				var near = false
				for g in gl:
					if absf(fposmod(ang - float(g) + 180.0, 360.0) - 180.0) < 6.0:
						near = true
				if not near:
					gl.append(ang)
		v["gates"] = gl


func _default_gates() -> void:
	for v in world_info["villages"]:
		if not CRAG_WALLS.has(v["id"]) or not (v.get("gates", []) as Array).is_empty():
			continue
		var best := 180.0
		var bd := 1e9
		var r: float = float(v["r"])
		for k in 36:
			var a := 10.0 * k
			var ok := true
			for f in [1.12, 1.3]:
				var q: Vector2 = Vector2(v["x"], v["y"]) + Vector2(sin(deg_to_rad(a)), cos(deg_to_rad(a))) * r * f
				if terrain_height(q.x, -q.y) < 0.8:
					ok = false
			var d := absf(fmod(a - 180.0 + 540.0, 360.0) - 180.0)
			if ok and d < bd:
				bd = d
				best = a
		v["gates"] = [best]


## Kayalık surlu köyler (Suna, Kiri): sur halkası yarıçap oranı ve yarı kalınlığı (m). Bu bantta hiçbir şey doğmaz
const CRAG_WALLS := {"suna": [0.97, 95.0], "kiri": [0.97, 75.0]}


## Bu nokta bir köyün kayalık surunun içinde mi (görev/olay/NPC yerleşimi için)
func in_village_wall(x: float, z: float) -> bool:
	var m := Vector2(x, -z)
	for v in world_info["villages"]:
		var cw = CRAG_WALLS.get(v["id"])
		if cw == null:
			continue
		var d: float = m.distance_to(Vector2(v["x"], v["y"]))
		if absf(d - float(v["r"]) * float(cw[0])) < float(cw[1]):
			return true
	return false


## Kayalık sur bandındaki noktayı en yakın kenara (köy içi ya da dışı) taşır; bant dışındaysa aynen döner
func out_of_wall(p: Vector3) -> Vector3:
	var m := Vector2(p.x, -p.z)
	for v in world_info["villages"]:
		var cw = CRAG_WALLS.get(v["id"])
		if cw == null:
			continue
		var c: Vector2 = Vector2(v["x"], v["y"])
		var d: float = m.distance_to(c)
		var rr: float = float(v["r"]) * float(cw[0])
		if absf(d - rr) < float(cw[1]):
			var nd: float = (rr - float(cw[1]) - 12.0) if d < rr else (rr + float(cw[1]) + 12.0)
			var q: Vector2 = c + (m - c).normalized() * nd
			return Vector3(q.x, ground_height(q.x, -q.y), -q.y)
	return p


## Dünya haritası: bake görseli yalnız kaba yüksekliği biliyordu (ayrıntı gürültüsü kıyıları değiştiriyordu) — haritada kara görünen yer
## suyun altında, su görünen yer kara çıkıyordu. Gerçek arazi yüksekliğiyle bir kez düzeltilir, user:// içinde saklanır.
var map_texture: Texture2D
signal map_ready
const MAP_FIX := "user://map_fixed_v2.png"   # yalnız kara görünen su: nehir çizgileri korunur


func world_map_tex() -> Texture2D:
	if map_texture == null:
		if FileAccess.file_exists(MAP_FIX):
			var im := Image.load_from_file(MAP_FIX)
			if im:
				map_texture = ImageTexture.create_from_image(im)
		if map_texture == null:
			map_texture = load("res://data/world/map.png")
			WorkerThreadPool.add_task(_fix_map)
	return map_texture


func _fix_map() -> void:
	var src: Image = (load("res://data/world/map.png") as Texture2D).get_image()
	src.convert(Image.FORMAT_RGB8)
	var w := src.get_width()
	var h := src.get_height()
	var sx := float(hw) / w
	var sy := float(hh) / h
	var paper := Color(240 / 255.0, 228 / 255.0, 200 / 255.0)
	for py in h:
		for px in w:
			var x := x0 + (px + 0.5) * sx * res
			var z := -(y1 - (py + 0.5) * sy * res)
			var th := terrain_height(x, z)
			var c := src.get_pixel(px, py)
			var is_water := c.b > c.r + 0.12 and c.b > c.g
			if th < -0.3 and not is_water:
				var dp := clampf(-th / 60.0, 0.0, 1.0)
				var wc := Color(70 / 255.0, 140 / 255.0, 190 / 255.0).lerp(Color(30 / 255.0, 70 / 255.0, 120 / 255.0), dp)
				src.set_pixel(px, py, wc.lerp(paper, 0.18))
	src.save_png(MAP_FIX)
	call_deferred("_map_done", src)


func _map_done(im: Image) -> void:
	map_texture = ImageTexture.create_from_image(im)
	map_ready.emit()


func village(id: String) -> Dictionary:
	for v in world_info["villages"]:
		if v["id"] == id:
			return v
	for l in world_info["landmarks"]:
		if l["id"] == id:
			return l
	return {}


# ------------------------------------------------------------------ ayarlar
func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		for k in settings.keys():
			settings[k] = cf.get_value("ayarlar", k, settings[k])
	apply_settings()


## Grafik kalitesi hazır ayarı: 0 Düşük, 1 Orta, 2 Yüksek (görüş, gölge, çizgi değerlerini de ayarlar)
const QUALITY_NAMES := ["Düşük", "Orta", "Yüksek"]
func set_quality(q: int) -> void:
	settings["quality"] = clampi(q, 0, 2)
	settings["view"] = [0.65, 1.0, 1.3][settings["quality"]]
	settings["shadows"] = settings["quality"] > 0
	settings["outline"] = settings["quality"] > 0
	apply_graphics()


## Ayarları sahneye uygula: gölge mesafesi/bölme, çizgiler, çimen yarıçapı, NPC yoğunluğu
func apply_graphics() -> void:
	var q = int(settings.get("quality", 2))
	if world == null:
		return
	var env = world.get("env")
	if env:
		env.sun.shadow_enabled = bool(settings["shadows"])
		env.sun.directional_shadow_max_distance = [80.0, 120.0, 170.0][q]
		env.sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if q < 2 else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		if env.post:
			env.post.visible = bool(settings["outline"])
		env.set_dreamy(bool(settings.get("dreamy", true)))
		# dolgu yükü (yaprak kartları üst üste biner: ormanda kare hızını çözünürlük + kenar yumuşatma + ortam gölgesi belirler):
		# Yüksek aynen; Orta'da kenar yumuşatma hafif yönteme geçer, ortam gölgesi kapanır; Düşük'te ayrıca %75 çözünürlük
		var vp = world.get_viewport()
		if vp:
			vp.msaa_3d = Viewport.MSAA_2X if q == 2 else Viewport.MSAA_DISABLED
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED if q == 2 else Viewport.SCREEN_SPACE_AA_FXAA
			vp.scaling_3d_scale = 0.75 if q == 0 else 1.0
		var ee = env.get("env")
		if ee:
			ee.ssao_enabled = q == 2
	var grass = world.get_node_or_null("Grass")
	if grass:
		grass.visible = q > 0
		if grass.get("mat"):
			grass.mat.set_shader_parameter("radius", [30.0, 42.0, 58.0][q])
	npc_scale = [0.5, 0.8, 1.2][q]   # yüksek kalitede sokak daha kalabalık (büyük köy 43 kişi)


var npc_scale := 1.0


func save_settings() -> void:
	var cf := ConfigFile.new()
	for k in settings.keys():
		cf.set_value("ayarlar", k, settings[k])
	cf.save(SETTINGS_PATH)
	apply_settings()


## Ekran seçenekleri: tam ekran ya da sabit boyutlu pencere (ekrandan büyükse ekrana sığdırılır)
const DISPLAYS := ["full", "max", "1280x720", "1366x768", "1600x900", "1920x1080", "2560x1440"]


static func display_label(k: String) -> String:
	match k:
		"full": return "Tam ekran"
		"max": return "Pencere (ekranı kapla)"
	return "Pencere %s" % k.replace("x", " × ")


func display_key() -> String:
	var d = String(settings.get("display", ""))
	if d == "" or not d in DISPLAYS:
		d = "full" if bool(settings.get("fullscreen", false)) else "max"
	return d


func apply_settings() -> void:
	var d = display_key()
	if d == "full":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif d == "max":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var pp = d.split("x")
		var scr = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		var want = Vector2i(mini(int(pp[0]), scr.size.x), mini(int(pp[1]), scr.size.y - 32))
		DisplayServer.window_set_size(want)
		DisplayServer.window_set_position(scr.position + (scr.size - want) / 2)
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, 0.0)
	get_tree().root.content_scale_factor = float(settings.get("ui_scale", 1.0))   # arayüz ölçeği (yalnız 2B arayüz; 3B görüntü etkilenmez)


# ------------------------------------------------------------------ kayıt
func save_path(slot: int) -> String:
	return "%s/kayit_%d.json" % [SAVE_DIR, slot]


func save_game() -> void:
	if profile.is_empty():
		return
	if player:
		profile["pos"] = [player.global_position.x, player.global_position.y + 0.5, player.global_position.z]
	if world and world.has_method("get_time_of_day"):
		profile["time"] = world.get_time_of_day()
	profile["saved_at"] = Time.get_datetime_string_from_system(false, true)
	profile["world_ver"] = WORLD_VERSION
	var f := FileAccess.open(save_path(int(profile.get("slot", 1))), FileAccess.WRITE)
	f.store_string(JSON.stringify(profile, " "))


func load_game(slot: int) -> bool:
	var p := save_path(slot)
	if not FileAccess.file_exists(p):
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	if d == null:
		return false
	profile = d
	profile["slot"] = slot
	Buffs.reset()   # önceki kaydın buff'ları bu kayda taşınmasın
	if int(profile.get("world_ver", 1)) != WORLD_VERSION:
		profile["pos"] = null  # dünya ölçeği değişti: eski konum anlamsız, köyde başla
		profile["world_ver"] = WORLD_VERSION
	_migrate_jutsu_ids()
	# eski kayıt: Hoshigaki oyuncu normal tenle kalmış olabilir (klan teni mavi / soluk gri)
	if String(profile.get("clan", "")) == "hoshigaki" and profile.get("look") is Dictionary:
		var sk = profile["look"].get("skin")
		var col := Color(0.96, 0.8, 0.66)
		if sk is Color:
			col = sk
		elif sk is String:   # JSON kaydı: "(r, g, b, a)"
			var parts = String(sk).strip_edges().trim_prefix("(").trim_suffix(")").split(",")
			if parts.size() >= 3:
				col = Color(float(parts[0]), float(parts[1]), float(parts[2]))
		if col.b < col.r + 0.02:   # mavimsi/gri değilse (normal insan teni)
			profile["look"]["skin"] = ClanWorld.HOSHIGAKI_SKINS[0]
	return true


## Birleştirilen kopya jutsular (Data jutsu._aliases) ve kaldırılan eşyalar eski kayıtlarda güncellenir
func _migrate_jutsu_ids() -> void:
	var al: Dictionary = Data.jutsu.get("_aliases", {})
	var learned: Array = []
	for j in profile.get("learned", []):
		var nj = String(al.get(j, j))
		if Data.jutsu.has(nj) and not nj in learned:
			learned.append(nj)
	profile["learned"] = learned
	for j in learned:
		if String(j).begins_with("bashosen_") and not "bashosen" in Gear.owned_ids(profile):
			Gear.grant(profile, "bashosen")
			break
	var slots: Array = profile.get("slots", [])
	for i in slots.size():
		var sj = String(al.get(slots[i], slots[i]))
		slots[i] = sj if Data.jutsu.has(sj) else ""
	var inv: Dictionary = profile.get("inventory", {})
	for k in inv.keys():   # klan tekniğine dönüşen jutsuların satılık parşömenleri kalktı
		if String(k).begins_with("scroll_") and Data.jutsu.has(String(k).substr(7)) and not Data.items.has(k):
			inv.erase(k)


func slot_summary(slot: int) -> String:
	var p := save_path(slot)
	if not FileAccess.file_exists(p):
		return ""
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	if d == null:
		return ""
	return "%s — %s, Güç %d  (%s)" % [d.get("name", "?"), Data.RANKS[int(d.get("rank", 0))], int(d.get("level", 1)), d.get("saved_at", "")]
