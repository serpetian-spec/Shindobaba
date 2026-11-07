class_name VillageBake
extends RefCounted
## Köyleri önceden pişirme: köy ilk kurulduğunda sahne ağacı (.scn) + köyün dünyaya kaydettiği veriler (.dat) diske yazılır;
## sonraki açılışlarda saniyede yüklenir (Konoha ~15 sn -> ~1-2 sn, hızlı seyahat anında).
## Anahtar: dünya kodu + dünya verisinin içerik özeti (dev) ya da build.json "world" alanı (exe). Kod değişirse önbellek yenilenir.
## Pişirilmeyenler: WorldDamage ev kayıtları (Konoha'da birleştirme sonrası zaten geçersizdi).

const DIR := "user://bake"
const VL = preload("res://scripts/world/village_life.gd")
const RM = preload("res://scripts/world/road_map.gd")
static var _key := ""


static func key() -> String:
	if _key != "":
		return _key
	var bj = JSON.parse_string(FileAccess.get_file_as_string("res://data/build.json"))
	if bj is Dictionary and String(bj.get("world", "")) != "":
		_key = String(bj["world"])
		return _key
	var files: Array = []
	for d in ["res://scripts/world", "res://data/world"]:
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd") or f.ends_with(".json") or f.ends_with(".bin") or f.ends_with(".png"):
				files.append(d.path_join(f))
	for f in ["res://scripts/actors/character_model.gd", "res://scripts/actors/outfit_parts.gd"]:
		files.append(f)
	files.sort()
	var acc = ""
	for f in files:
		acc += f + FileAccess.get_md5(f)
	_key = acc.md5_text().substr(0, 12)
	return _key


static func _path(vid: String, ext: String) -> String:
	return DIR.path_join("%s_%s.%s" % [vid, key(), ext])


static func snapshot(vid: String) -> Dictionary:
	return {"inter": Interact.items.size(), "lights": Lights.points.size(), "leaf": Builder.leaf_spots.size(), "spawn": Spawner.pending.size(), "lanes": RM.lanes.size(), "water": Game.water_list.size()}


## Kurulmuş köyü kaydet (root: köyün kök düğümü, snap: kurulumdan önceki snapshot)
static func save(root: Node3D, vid: String, snap: Dictionary) -> void:
	if OS.get_environment("NO_BAKE") != "" or not is_instance_valid(root):
		return
	var t0 = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR):   # aynı köyün eski sürümleri
		if f.begins_with(vid + "_") and not f.contains(key()):
			DirAccess.remove_absolute(DIR.path_join(f))
	var lk = vid.to_lower()
	var data = {
		"inter": Interact.items.slice(int(snap["inter"])),
		"lights": Array(Lights.points).slice(int(snap["lights"])),
		"leaf": Builder.leaf_spots.slice(int(snap["leaf"])),
		"spawn": Spawner.pending.slice(int(snap["spawn"])),
		"lanes": RM.lanes.slice(int(snap.get("lanes", 0))),   # ara sokak patikaları (çimen maskesi)
		"water": Game.water_list.slice(int(snap.get("water", 0))).map(func(e): return [e[1], e[2] * 2.0, e[3], e[4], e[5]]),   # su üstü yürüme yüzeyleri
		"sites": VL.sites.get(vid, []), "doors": VL.doors.get(vid, []),
		"roofs": Builder.roof_points.get(lk, []),
		"lots": CityInfill.lots_by.get(vid, []), "lots_done": CityInfill.done.has(vid),
	}
	# betikli düğümler (Hokage taş kafaları: CharacterModel) durağan: betik çıkar, iskelet pozu ve meshler kalsın
	for n in root.find_children("*", "", true, false):
		if n.get_script() != null:
			n.set_script(null)
		n.owner = root
	var ps = PackedScene.new()
	if ps.pack(root) != OK:
		push_warning("VillageBake: paketlenemedi " + vid)
		return
	if ResourceSaver.save(ps, _path(vid, "scn"), ResourceSaver.FLAG_COMPRESS) != OK:
		push_warning("VillageBake: kaydedilemedi " + vid)
		return
	var f = FileAccess.open(_path(vid, "dat"), FileAccess.WRITE)
	f.store_var(data)
	print("Pişirildi %s: %d ms" % [vid, Time.get_ticks_msec() - t0])


## Çok şekilli statik gövdeleri parçala: Jolt bir gövdedeki alt şekil kimlik bitlerini aşınca gövdeyi HİÇ kurmuyor
## (Konoha'nın pişmiş çarpışması: duvarların içinden geçiliyordu). Her gövde en fazla MAX_SHAPES şekil taşır.
const MAX_SHAPES := 200
static func split_bodies(root: Node, into: Node = null) -> int:
	if root == null or not is_instance_valid(root):
		return 0
	var _t0 = Time.get_ticks_msec()
	var made = 0
	var list: Array = [root] if root is StaticBody3D else root.find_children("*", "StaticBody3D", true, false)
	for sb in list:
		var par: Node = into if into != null else sb.get_parent()
		# üçgen-mesh şekilleri (ConcavePolygon) bileşikte çok bit yer: her biri kendi gövdesinde (158 bin üçgenlik Konoha zemini)
		var meshes = sb.get_children().filter(func(ch): return ch is CollisionShape3D and ch.shape is ConcavePolygonShape3D)
		if sb.get_children().filter(func(ch): return ch is CollisionShape3D or ch is CollisionPolygon3D).size() > 1:
			for s in meshes:
				var mb = StaticBody3D.new()
				mb.collision_layer = sb.collision_layer
				mb.collision_mask = sb.collision_mask
				mb.physics_material_override = sb.physics_material_override
				mb.transform = sb.transform
				for g in sb.get_groups():
					mb.add_to_group(g)
				sb.remove_child(s)
				mb.add_child(s)   # şekil gövde ağaca girmeden taşınır (ağaçtaki gövdeye her ekleme bileşiği baştan kurar)
				par.add_child(mb)
				mb.owner = sb.owner
				s.owner = sb.owner
				made += 1
		var shapes = sb.get_children().filter(func(ch): return ch is CollisionShape3D or ch is CollisionPolygon3D)
		if shapes.size() <= MAX_SHAPES:
			continue
		# SONDAN sök: ortadan/baştan remove_child her seferinde dizi kaydırır (77 bin şekilde 97 sn sürüyordu); sondan O(1)
		var nb: StaticBody3D = null
		var cnt = 0
		for idx in range(shapes.size() - 1, MAX_SHAPES - 1, -1):
			if nb == null:
				nb = StaticBody3D.new()
				nb.collision_layer = sb.collision_layer
				nb.collision_mask = sb.collision_mask
				nb.physics_material_override = sb.physics_material_override
				nb.transform = sb.transform
				for g in sb.get_groups():
					nb.add_to_group(g)
			var s = shapes[idx]
			sb.remove_child(s)
			nb.add_child(s)
			cnt += 1
			if cnt >= MAX_SHAPES or idx == MAX_SHAPES:
				par.add_child(nb)
				nb.owner = sb.owner
				for ch in nb.get_children():
					ch.owner = sb.owner
				made += 1
				nb = null
				cnt = 0
	return made


## Önbellekten yükle; yoksa false (normal kurulum yapılır)
static func try_load(parent: Node3D, vid: String) -> Node3D:
	if OS.get_environment("NO_BAKE") != "":
		return null
	var sp = _path(vid, "scn")
	var dp = _path(vid, "dat")
	if not FileAccess.file_exists(sp) or not FileAccess.file_exists(dp):
		return null
	var t0 = Time.get_ticks_msec()
	var ps = ResourceLoader.load(sp, "", ResourceLoader.CACHE_MODE_IGNORE)
	var f = FileAccess.open(dp, FileAccess.READ)
	var data = f.get_var() if f else null
	if not ps is PackedScene or not data is Dictionary:
		return null
	var root: Node3D = ps.instantiate()
	split_bodies(root)   # çarpışma: tek gövdede binlerce şekil Jolt'ta kurulamıyordu ("Compound hierarchy is too deep") -> duvarlardan geçiliyordu
	parent.add_child(root)
	for it in data["inter"]:
		Interact.items.append(it)
	for p in data["lights"]:
		Lights.add(p)
	Builder.leaf_spots.append_array(data["leaf"])
	Spawner.pending.append_array(data["spawn"])
	if data.has("lanes") and not (data["lanes"] as Array).is_empty():
		RM.lanes.append_array(data["lanes"])
		RM.lanes_dirty = true
	for w in data.get("water", []):
		Game.add_water(root, w[0], w[1], w[2], w[3], w[4])   # köy kökü boşaltılınca kayıt düşer
	VL.sites[vid] = data["sites"]
	VL.doors[vid] = data["doors"]
	Builder.roof_points[vid.to_lower()] = data["roofs"]
	CityInfill.lots_by[vid] = data["lots"]
	if data["lots_done"]:
		CityInfill.done[vid] = true
	print("Önbellekten yüklendi %s: %d ms" % [vid, Time.get_ticks_msec() - t0])
	return root
