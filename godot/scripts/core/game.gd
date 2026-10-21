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
func _load_world() -> void:
	world_info = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/world.json"))
	var w: Dictionary = world_info["world"]
	hw = int(w["w"]); hh = int(w["h"])
	x0 = float(w["x0"]); y1 = float(w["y1"]); res = float(w["res"])
	var bytes := FileAccess.get_file_as_bytes("res://data/world/height.bin")
	heights = bytes.to_float32_array()
	var img := Image.create_from_data(hw, hh, false, Image.FORMAT_RF, bytes)
	height_tex = ImageTexture.create_from_image(img)
	albedo_tex = load("res://data/world/albedo.png")
	biome_img = (load("res://data/world/biome.png") as Texture2D).get_image()


## Godot dünya koordinatı -> harita (x doğu, y kuzey)
func to_map(p: Vector3) -> Vector2:
	return Vector2(p.x, -p.z)


func from_map(m: Vector2, h: float = NAN) -> Vector3:
	var y := terrain_height(m.x, -m.y) if is_nan(h) else h
	return Vector3(m.x, y, -m.y)


## Arazi yüksekliği (bilinear). x ve z Godot dünya koordinatı.
func terrain_height(x: float, z: float) -> float:
	var fx := (x - x0) / res - 0.5
	var fz := (z + y1) / res - 0.5
	var ix := clampi(int(floor(fx)), 0, hw - 2)
	var iz := clampi(int(floor(fz)), 0, hh - 2)
	var tx := clampf(fx - ix, 0.0, 1.0)
	var tz := clampf(fz - iz, 0.0, 1.0)
	var i := iz * hw + ix
	var a := lerpf(heights[i], heights[i + 1], tx)
	var b := lerpf(heights[i + hw], heights[i + hw + 1], tx)
	return lerpf(a, b, tz)


func terrain_normal(x: float, z: float) -> Vector3:
	var e := res
	var hx := terrain_height(x + e, z) - terrain_height(x - e, z)
	var hz := terrain_height(x, z + e) - terrain_height(x, z - e)
	return Vector3(-hx, 2.0 * e, -hz).normalized()


## Yürünebilir zemin: deniz/nehir yüzeyi (y=0) ninja için zemindir (su üstünde yürüme).
func ground_height(x: float, z: float, on_water := true) -> float:
	var h := terrain_height(x, z)
	return maxf(h, 0.0) if on_water else h


func biome_at(x: float, z: float) -> int:
	var px := clampi(int((x - x0) / res), 0, hw - 1)
	var pz := clampi(int((z + y1) / res), 0, hh - 1)
	return int(biome_img.get_pixel(px, pz).r8)


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
	return true


func slot_summary(slot: int) -> String:
	var p := save_path(slot)
	if not FileAccess.file_exists(p):
		return ""
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	if d == null:
		return ""
	return "%s — %s, Sv.%d  (%s)" % [d.get("name", "?"), Data.RANKS[int(d.get("rank", 0))], int(d.get("level", 1)), d.get("saved_at", "")]
