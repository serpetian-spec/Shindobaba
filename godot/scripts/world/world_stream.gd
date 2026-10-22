extends Node3D
## Dünya akışı: features.json (kaya sütunları, yol kenarı tapınakları, köprüler, tarlalar) ve pois.json
## (mezralar, hanlar, haydut kampları, harabeler, tapınaklar, kaplıcalar, iskeleler, karakollar, anıtlar)
## oyuncunun çevresinde 1 km'lik bölgeler halinde kurulur, uzaklaşınca silinir. Karede en fazla bir bölge kurulur.

const REGION := 1024.0
const BUILD_R := 2600.0
const POI_R := 1500.0          # POI içerikleri (NPC, düşman) bu mesafede kurulur
const FREE_PAD := 900.0

var feat_by_region := {}       # Vector2i -> [feature]
var poi_by_region := {}        # Vector2i -> [poi]
var regions := {}              # Vector2i -> {node, inter: Array, pois: bool}
var _queue: Array = []
var _t := 0.0


func _ready() -> void:
	var list = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/features.json"))
	for f in list:
		var k := Vector2i(floori(float(f["x"]) / REGION), floori(float(f["y"]) / REGION))
		if not feat_by_region.has(k):
			feat_by_region[k] = []
		feat_by_region[k].append(f)
	for p in Game.pois:
		var k := Vector2i(floori(float(p["x"]) / REGION), floori(float(p["y"]) / REGION))
		if not poi_by_region.has(k):
			poi_by_region[k] = []
		poi_by_region[k].append(p)


func _focus() -> Vector2:
	var p: Vector3
	if Game.player:
		p = Game.player.global_position
	else:
		var cam = get_viewport().get_camera_3d()
		if cam == null:
			return Vector2(1e9, 1e9)
		p = cam.global_position
	return Vector2(p.x, -p.z)


func _rdist(k: Vector2i, m: Vector2) -> float:
	return Vector2((k.x + 0.5) * REGION, (k.y + 0.5) * REGION).distance_to(m)


func _process(dt: float) -> void:
	_t -= dt
	var m := _focus()
	if _t <= 0.0:
		_t = 0.5
		_queue.clear()
		var ck := Vector2i(floori(m.x / REGION), floori(m.y / REGION))
		var rad := int(ceil(BUILD_R / REGION)) + 1
		for dy in range(-rad, rad + 1):
			for dx in range(-rad, rad + 1):
				var k := ck + Vector2i(dx, dy)
				var d := _rdist(k, m)
				if d > BUILD_R:
					continue
				var reg = regions.get(k)
				var want_pois := d < POI_R + REGION * 0.7
				if reg == null or (want_pois and not reg["pois"] and poi_by_region.has(k)):
					if feat_by_region.has(k) or poi_by_region.has(k):
						_queue.append([d, k, want_pois])
		_queue.sort_custom(func(a, b): return a[0] < b[0])
		for k in regions.keys():
			if _rdist(k, m) > BUILD_R + FREE_PAD:
				_free(k)
	# bölge kurulumu pahalı: üç karede bir (bitki parçalarıyla aynı kareye düşmesin)
	if not _queue.is_empty() and Engine.get_process_frames() % 3 == 1:
		var q: Array = _queue.pop_front()
		_build(q[1], q[2])


func _free(k: Vector2i) -> void:
	var reg: Dictionary = regions[k]
	for it in reg["inter"]:
		Interact.items.erase(it)
	reg["node"].queue_free()
	regions.erase(k)


func _build(k: Vector2i, with_pois: bool) -> void:
	if regions.has(k):
		_free(k)
	var node := Node3D.new()
	node.name = "Bolge_%d_%d" % [k.x, k.y]
	add_child(node)
	var before := Interact.items.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(k)
	var feats: Array = feat_by_region.get(k, [])
	if not feats.is_empty():
		var b := Builder.new(node, 0.0, 0.0, 0.0, "Yapilar")
		b.view_dist = 3000.0
		for f in feats:
			var g := Game.terrain_height(float(f["x"]), -float(f["y"]))
			if f["t"] in ["pillar", "spire", "mesa"]:
				var r := float(f["r"])
				for a in 6:
					g = minf(g, Game.terrain_height(float(f["x"]) + cos(a) * r, -float(f["y"]) + sin(a) * r))
			var ff: Dictionary = f.duplicate()
			ff["g"] = g if f["t"] != "bridge" else 0.0
			BuildFeatures._build(b, ff, rng)
		b.finish()
	if with_pois:
		for p in poi_by_region.get(k, []):
			PoiBuilder.build(node, p)
	var inter: Array = Interact.items.slice(before)
	regions[k] = {"node": node, "inter": inter, "pois": with_pois}
