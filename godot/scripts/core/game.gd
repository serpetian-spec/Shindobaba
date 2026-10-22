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
	"sens": 1.0, "fov": 70.0, "music": 0.5, "sfx": 0.8, "view": 1.0, "fullscreen": false,
	"shadows": true, "outline": true, "invert_y": false, "show_fps": false,
}
var profile: Dictionary = {}
var paused := false
var ui_open := false
var player: Node3D = null
var world: Node3D = null
var hud: Node = null
var build_tag := "dev"
var version := "0.2.0"


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
const ROAD_HALF := {"road": 5.0, "street": 6.0}


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
	for rl in JSON.parse_string(FileAccess.get_file_as_string("res://data/world/roads.json")):
		var pts := PackedVector2Array()
		for q in rl["pts"]:
			pts.append(Vector2(q[0], q[1]))
		roads.append({"a": rl["a"], "b": rl["b"], "kind": rl["kind"], "pts": pts})
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


## Yürünebilir zemin: deniz/nehir yüzeyi (y=0) ninja için zemindir (su üstünde yürüme).
func ground_height(x: float, z: float, on_water := true) -> float:
	var h := terrain_height(x, z)
	return maxf(h, 0.0) if on_water else h


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


func save_settings() -> void:
	var cf := ConfigFile.new()
	for k in settings.keys():
		cf.set_value("ayarlar", k, settings[k])
	cf.save(SETTINGS_PATH)
	apply_settings()


func apply_settings() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED)
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, 0.0)


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
	if int(profile.get("world_ver", 1)) != WORLD_VERSION:
		profile["pos"] = null  # dünya ölçeği değişti: eski konum anlamsız, köyde başla
		profile["world_ver"] = WORLD_VERSION
	return true


func slot_summary(slot: int) -> String:
	var p := save_path(slot)
	if not FileAccess.file_exists(p):
		return ""
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	if d == null:
		return ""
	return "%s — %s, Sv.%d  (%s)" % [d.get("name", "?"), Data.RANKS[int(d.get("rank", 0))], int(d.get("level", 1)), d.get("saved_at", "")]
