class_name VillageBake
extends RefCounted
## Köyleri önceden pişirme: köy ilk kurulduğunda sahne ağacı (.scn) + köyün dünyaya kaydettiği veriler (.dat) diske yazılır;
## sonraki açılışlarda saniyede yüklenir (Konoha ~15 sn -> ~1-2 sn, hızlı seyahat anında).
## Anahtar: dünya kodu + dünya verisinin içerik özeti (dev) ya da build.json "world" alanı (exe). Kod değişirse önbellek yenilenir.
## Pişirilmeyenler: WorldDamage ev kayıtları (Konoha'da birleştirme sonrası zaten geçersizdi).

const DIR := "user://bake"
const VL = preload("res://scripts/world/village_life.gd")
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
	return {"inter": Interact.items.size(), "lights": Lights.points.size(), "leaf": Builder.leaf_spots.size(), "spawn": Spawner.pending.size()}


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
	parent.add_child(root)
	for it in data["inter"]:
		Interact.items.append(it)
	for p in data["lights"]:
		Lights.add(p)
	Builder.leaf_spots.append_array(data["leaf"])
	Spawner.pending.append_array(data["spawn"])
	VL.sites[vid] = data["sites"]
	VL.doors[vid] = data["doors"]
	Builder.roof_points[vid.to_lower()] = data["roofs"]
	CityInfill.lots_by[vid] = data["lots"]
	if data["lots_done"]:
		CityInfill.done[vid] = true
	print("Önbellekten yüklendi %s: %d ms" % [vid, Time.get_ticks_msec() - t0])
	return root
