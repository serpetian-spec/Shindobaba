class_name AssetLib
extends RefCounted
## Hazır 3B model paketleri (assets/packs, assets/sketchfab) için yükleyici:
## sahneyi tek bir ArrayMesh'e birleştirir (malzeme başına bir yüzey), ölçekler, zemine oturtur,
## malzemeleri anime ışığına (asset_toon) çevirir. Sonuçlar önbelleğe alınır; MultiMesh ile kullanılır.

const NATURE := "res://assets/packs/nature/"
const JAPAN := "res://assets/packs/japan/"
const FOLIAGE_WORDS := ["leaf", "leaves", "grass", "flower", "petal", "bush", "fern", "clover", "plant", "foliage", "bamboo", "needle"]

static var _cache := {}
static var _mats := {}
static var _sizes := {}


static var _parts := {}   # "yol|düğüm" -> [[mesh, yüzey, xform], AABB]


## path: glTF/GLB; height > 0 ise o yüksekliğe ölçeklenir (yoksa scale çarpanı); zemin y=0, xz merkezlenir
static func mesh(path: String, height := 0.0, scale := 1.0, opts := {}) -> ArrayMesh:
	if OS.get_environment("ASSET_PACKS") == "0":
		return null
	var key = "%s|%.3f|%.3f|%s" % [path, height, scale, str(opts)]
	if _cache.has(key):
		return _cache[key]
	if not ResourceLoader.exists(path):
		push_warning("AssetLib: yok " + path)
		_cache[key] = null
		return null
	# parçalar + sınırlar (yol|düğüm başına bir kez): aynı sahneyi her çağrıda yeniden açıp tüm köşeleri
	# GDScript'te gezmek kasaba evlerinde açılışa ~8 sn ekliyordu
	var pk = path + "|" + String(opts.get("node", ""))
	if not _parts.has(pk):
		var ps: PackedScene = load(path)
		var root: Node = ps.instantiate()
		var pl: Array = []  # [mesh, surface, xform]
		_collect(root, Transform3D.IDENTITY, pl, true, String(opts.get("node", "")), String(opts.get("node", "")) == "")
		var ab0 := AABB()
		var first := true
		for p in pl:
			var m: Mesh = p[0]
			var arr = m.surface_get_arrays(p[1])
			for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var w: Vector3 = p[2] * v
				if first:
					ab0 = AABB(w, Vector3.ZERO)
					first = false
				else:
					ab0 = ab0.expand(w)
		root.free()
		_parts[pk] = [pl, ab0]
	var parts: Array = _parts[pk][0]
	var ab: AABB = _parts[pk][1]
	var s = scale
	if height > 0.0 and ab.size.y > 0.001:
		s = height / ab.size.y
	var center = ab.get_center()
	var fix = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * s), Vector3(-center.x * s, -ab.position.y * s, -center.z * s))
	if opts.get("keep_origin", false):
		fix = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * s), Vector3.ZERO)
	if opts.has("yaw"):
		fix = Transform3D(Basis(Vector3.UP, deg_to_rad(float(opts["yaw"]))), Vector3.ZERO) * fix
	# malzemeye göre grupla
	var groups := {}   # mat key -> [SurfaceTool, ShaderMaterial]
	var only: String = opts.get("only", "")      # yalnızca adı bunu içeren malzemeler
	var skip: String = opts.get("skip", "")
	for p in parts:
		var m: Mesh = p[0]
		var sm: Material = m.surface_get_material(p[1])
		var mname = (sm.resource_name if sm else "").to_lower()
		if only != "" and not mname.contains(only):
			continue
		if skip != "" and mname.contains(skip):
			continue
		var mk = str(sm.get_instance_id()) if sm else "none"
		if not groups.has(mk):
			var st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[mk] = [st, convert_material(sm, opts)]
		var stt: SurfaceTool = groups[mk][0]
		stt.append_from(m, p[1], fix * p[2])
	var out = ArrayMesh.new()
	for mk in groups:
		var st: SurfaceTool = groups[mk][0]
		var a = st.commit_to_arrays()
		if a[Mesh.ARRAY_VERTEX] == null or (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
			continue
		# MultiMesh örnek rengi COLOR ile gelsin: vertex rengini beyaz yap
		var n = (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		if a[Mesh.ARRAY_COLOR] == null:
			var cols = PackedColorArray()
			cols.resize(n)
			cols.fill(Color.WHITE)
			a[Mesh.ARRAY_COLOR] = cols
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		out.surface_set_material(out.get_surface_count() - 1, groups[mk][1])
	_sizes[key] = ab.size * s
	_cache[key] = out
	return out


static func size_of(path: String, height := 0.0, scale := 1.0, opts := {}) -> Vector3:
	var key = "%s|%.3f|%.3f|%s" % [path, height, scale, str(opts)]
	if not _sizes.has(key):
		mesh(path, height, scale, opts)
	return _sizes.get(key, Vector3.ONE)


static func _collect(n: Node, xf: Transform3D, out: Array, is_root: bool, node_name := "", inside := true) -> void:
	var t = xf
	if n is Node3D and not is_root:
		t = xf * (n as Node3D).transform
	var ins = inside or (node_name != "" and String(n.name) == node_name)
	if ins and n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var m: Mesh = (n as MeshInstance3D).mesh
		for i in m.get_surface_count():
			out.append([m, i, t])
	for c in n.get_children():
		_collect(c, t, out, false, node_name, ins)


## Bir malzemeyi anime ışıklı malzemeye çevirir (doku korunur)
static func convert_material(src: Material, opts := {}) -> ShaderMaterial:
	var key = (str(src.get_instance_id()) if src else "none") + str(opts.get("tint", "")) + str(opts.get("sway", "")) + str(opts.get("sat", ""))
	if _mats.has(key):
		return _mats[key]
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/asset_toon.gdshader")
	var name = (src.resource_name if src else "").to_lower()
	var tex: Texture2D = null
	var col := Color.WHITE
	var transparent := false
	if src is BaseMaterial3D:
		tex = (src as BaseMaterial3D).albedo_texture
		col = (src as BaseMaterial3D).albedo_color
		transparent = (src as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED
	var foliage = transparent
	for w in FOLIAGE_WORDS:
		if name.contains(w):
			foliage = true
	if tex:
		m.set_shader_parameter("tex", tex)
	if opts.has("tint"):
		col = col * Color(opts["tint"])
	m.set_shader_parameter("tint", col)
	m.set_shader_parameter("cutout", foliage)
	if not foliage:
		m.set_shader_parameter("saturation", float(opts.get("sat", 1.0)))
	if foliage and opts.get("sway", true):
		m.set_shader_parameter("sway", float(opts.get("sway_amt", 0.08)))
		m.set_shader_parameter("sway_h", float(opts.get("sway_h", 6.0)))
	_mats[key] = m
	return m


## Bir sahneyi (bina, kapı, fener...) olduğu gibi örnekler; malzemeleri çevirir. height>0: o yüksekliğe ölçek.
static func instance(path: String, height := 0.0, scale := 1.0, opts := {}) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh(path, height, scale, opts)
	return mi


## Otomatik basitleştirilmiş kopya (uzak mesafe): ratio = hedef üçgen oranı (0.1 = %10)
static func lod(m: ArrayMesh, ratio := 0.15) -> ArrayMesh:
	if m == null:
		return null
	var key = "lod|%d|%.3f" % [m.get_instance_id(), ratio]
	if _cache.has(key):
		return _cache[key]
	var out = ArrayMesh.new()
	for i in m.get_surface_count():
		var a = m.surface_get_arrays(i)
		var im = ImporterMesh.new()
		im.add_surface(Mesh.PRIMITIVE_TRIANGLES, a)
		im.generate_lods(60.0, 25.0, [])
		var base: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var want = int(base.size() * ratio)
		var best: PackedInt32Array = base
		for li in im.get_surface_lod_count(0):
			var idx: PackedInt32Array = im.get_surface_lod_indices(0, li)
			best = idx
			if idx.size() <= want:
				break
		var b = a.duplicate()
		b[Mesh.ARRAY_INDEX] = best
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, b)
		out.surface_set_material(i, m.surface_get_material(i))
	_cache[key] = out
	return out


## Aksesuarlar (assets/packs/japan): anahtar -> [dosya, varsayılan yükseklik]
const PROPS := {
	"torii": ["torii_gate_7SyX.glb", 7.0], "torii_red": ["torii_8ZgG.glb", 7.0], "torii_lanterns": ["torii_gate_lYTD.glb", 7.5], "torii_small": ["torii_8ZgG.glb", 4.5],
	"pagoda": ["pagoda_1zS7.glb", 26.0], "pagoda_wood": ["pagoda_d1M5.glb", 18.0], "pagoda_green": ["pagoda_eHOI.glb", 14.0],
	"stone_lamp": ["japanese_stone_lamp_5gZf.glb", 2.2], "toro": ["toro_0Sgu.glb", 2.0], "red_lantern": ["red_lantern_7PZh.glb", 0.7],
	"paper_lantern": ["lantern_ilX8.glb", 0.6], "post_lantern": ["post_lantern_ZSQ6.glb", 3.0], "hanging_lantern": ["hanging_lantern_3jzk.glb", 0.8],
	"wood_lantern": ["lantern_d80a.glb", 3.0], "bamboo": ["bamboo_auVD.glb", 9.0], "bonsai": ["bonsai_1Bty.glb", 1.2],
	"shrine": ["shrine_tFxd.glb", 1.6], "bench": ["bench_cp2Q.glb", 1.0], "gazebo": ["gazebo_xYZB.glb", 5.0], "watch_tower": ["watch_tower_cMxu.glb", 14.0],
}


static func prop(kind: String, height := 0.0) -> ArrayMesh:
	if not PROPS.has(kind):
		return null
	var e: Array = PROPS[kind]
	return mesh(JAPAN + e[0], height if height > 0.0 else float(e[1]), 1.0, {"sway": false})


## Sokak/bahçe ağacı: yaklaşık 9 m geniş yapraklı ağaç varyantı (seed ile)
static func tree_mesh(seed: int) -> ArrayMesh:
	var names = ["CommonTree_1", "CommonTree_2", "CommonTree_3", "CommonTree_4", "CommonTree_5"]
	return mesh(NATURE + names[absi(seed) % names.size()] + ".gltf", 9.0, 1.0, {})


## Hazır Japon kasaba evleri (Sketchfab "Stylized Little Japanese Town Street"): [[mesh, boyut], ...]
const TOWN_STREET := "res://assets/sketchfab/jp_town_street/jp_town_street.glb"
const TOWN_HOUSES := ["DomekRdy_1", "DomekRdy_2", "DomekRdy_3", "DomekRdy_4", "DomekRdy_5", "DomekRdy_Ksiegarnia", "DomekRdy_Kwiaciarnia"]
static var _houses: Array = []
static func town_houses() -> Array:
	if not _houses.is_empty() or not ResourceLoader.exists(TOWN_STREET):
		return _houses
	# ortak ölçek: en uzun ev ~11 m
	var hmax = 0.0
	for nm in TOWN_HOUSES:
		hmax = maxf(hmax, size_of(TOWN_STREET, 0.0, 1.0, {"node": nm, "sway": false}).y)
	if hmax <= 0.0:
		return _houses
	var sc = 11.0 / hmax
	for nm in TOWN_HOUSES:
		var m = mesh(TOWN_STREET, 0.0, sc, {"node": nm, "sway": false, "sat": 0.72, "tint": Color(1.0, 0.96, 0.9)})
		if m != null and m.get_surface_count() > 0:
			_houses.append([m, size_of(TOWN_STREET, 0.0, sc, {"node": nm, "sway": false, "sat": 0.72, "tint": Color(1.0, 0.96, 0.9)})])
	return _houses


## Büyük Japon tapınağı (pagoda) — Sketchfab "Japanese Shrine"
const TEMPLE := "res://assets/sketchfab/jp_temple/jp_temple.glb"
static func temple(height := 26.0) -> ArrayMesh:
	return mesh(TEMPLE, height, 1.0, {"sway": false})


## Stilize kaya parçaları (Sketchfab "Free Pack - Rocks Stylized"): her biri ayrı mesh
const ROCKS := "res://assets/sketchfab/rocks_stylized/rocks_stylized.glb"
static func rock_parts(height: float) -> Array:
	var out = []
	if not ResourceLoader.exists(ROCKS):
		return out
	var ps: PackedScene = load(ROCKS)
	var r = ps.instantiate()
	var names = []
	for mi in r.find_children("*", "MeshInstance3D", true, false):
		names.append(String(mi.get_parent().name) if String(mi.name).begins_with("Object") else String(mi.name))
	r.free()
	for nm in names:
		var m = mesh(ROCKS, height, 1.0, {"node": nm, "sway": false})
		if m != null and m.get_surface_count() > 0:
			out.append(m)
	return out
