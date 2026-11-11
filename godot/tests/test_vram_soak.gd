extends Node
## Ekran belleği sızıntı avı: köyler arasında dolaş, her durakta VRAM dökümü yaz; sonra aynı turu tekrar et.
## İkinci turda rakamlar büyüyorsa sızıntı var. Kullanım: --test=res://tests/test_vram_soak.gd [--turns=2] [--wait=14]

var main: Node
var pl: Player
var turns := 2
var wait := 14.0


func _dump(tag: String) -> void:
	var rs = RenderingServer
	var mb = 1048576.0
	print("VRAM %-22s toplam %5.0f  doku %5.0f  tampon %5.0f | düğüm %6d  kaynak %5d  ram %5.0f  nesne %5d" % [tag,
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / mb,
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / mb,
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED) / mb,
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		Performance.get_monitor(Performance.MEMORY_STATIC) / mb,
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)])
	_caches()
	if "--tree" in OS.get_cmdline_user_args():
		_tree()


func _caches() -> void:
	var d = {"donor": CharacterModel._donor_cache, "skull": CharacterModel._skull_cache, "body": CharacterModel._body_cache, "shell": CharacterModel._shell_cache,
		"ring": CharacterModel._ring_cache, "sole": CharacterModel._sole_cache, "garment": CharacterModel._garment_cache, "gdyn": CharacterModel._gdyn_cache,
		"vest": CharacterModel._vest_kit_cache, "bodyvs": CharacterModel._body_vs_cache, "scalp": CharacterModel._scalp_cache, "hair": CharacterModel._hair_cache,
		"radial": CharacterModel._radial_cache, "hairvs": CharacterModel._hair_vs_cache, "ringfull": CharacterModel._ringfull_cache, "top": CharacterModel._top_cache,
		"fmap": CharacterModel._fmap_cache, "weapon": CharacterModel._weapon_cache, "kp": CharacterModel._kp_cache, "sfprops": SFProps._cache,
		"vfx": VFX._cache, "atree": AnimeTree._cache, "asset": AssetLib._cache, "tri": Builder._tri_cache, "veg": BuildKonoha._veg_cache,
		"city": CityLandscape._meshes, "mb": MB._cache}
	var t = ""
	for k in d:
		var seen = {}
		var b = _bytes(d[k], seen, 0)
		t += "%s=%d" % [k, (d[k] as Dictionary).size()]
		if b > 1048576.0:
			t += "(%.0fMB,%dm)" % [b / 1048576.0, seen.size()]
		t += " "
	print("   CACHE " + t + "| obje %d yetim %d" % [Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)])


func _bytes(v, seen: Dictionary, depth: int) -> float:
	if depth > 5:
		return 0.0
	var b = 0.0
	if v is Dictionary:
		for k in v:
			b += _bytes(v[k], seen, depth + 1)
	elif v is Array:
		for x in v:
			b += _bytes(x, seen, depth + 1)
	elif v is ArrayMesh:
		if not seen.has(v.get_instance_id()):
			seen[v.get_instance_id()] = true
			for si in v.get_surface_count():
				b += v.surface_get_array_len(si) * 40.0 + v.surface_get_array_index_len(si) * 4.0
	elif v is Node and is_instance_valid(v):
		for ch in ([v] + v.find_children("*", "MeshInstance3D", true, false)):
			if ch is MeshInstance3D and ch.mesh:
				b += _bytes(ch.mesh, seen, depth + 1)
	return b


func _tree() -> void:
	var g = {}
	var seen = {}
	var root = get_tree().root
	for ch in root.find_children("*", "GeometryInstance3D", true, false):
		var me: Mesh = null
		var extra = 0.0
		if ch is MultiMeshInstance3D and ch.multimesh:
			me = ch.multimesh.mesh
			extra = ch.multimesh.instance_count * 80.0
		elif ch is MeshInstance3D:
			me = ch.mesh
		var b = extra
		if me and not seen.has(me.get_instance_id()):
			seen[me.get_instance_id()] = true
			if me is ArrayMesh:
				for si in me.get_surface_count():
					b += me.surface_get_array_len(si) * 40.0 + me.surface_get_array_index_len(si) * 4.0
		var pth = String(root.get_path_to(ch)).split("/")
		var k = "/".join(pth.slice(0, mini(4, pth.size() - 1)))
		if not g.has(k):
			g[k] = [0, 0.0]
		g[k][0] += 1
		g[k][1] += b
	var ks = g.keys()
	ks.sort_custom(func(a, b2): return g[a][1] > g[b2][1])
	var tot = 0.0
	for k in ks:
		tot += g[k][1]
	print("   AĞAÇ toplam %.0f MB, tekil mesh %d" % [tot / 1048576.0, seen.size()])
	for k in ks.slice(0, 9):
		print("      %-60s %5d adet %6.0f MB" % [k, g[k][0], g[k][1] / 1048576.0])


func _process(_dt: float) -> void:
	if pl:
		pl.hp = pl.max_hp


func _ready() -> void:
	await get_tree().process_frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--turns="):
			turns = int(a.substr(8))
		if a.begins_with("--wait="):
			wait = float(a.substr(7))
	_dump("menü")
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	pl = main.player
	await get_tree().create_timer(4.0).timeout
	_dump("doğuş")
	if "--bake" in OS.get_cmdline_user_args():
		var bid = "suna"
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--bid="):
				bid = a.substr(6)
		var n = Node3D.new()
		get_tree().current_scene.add_child(n)
		var r = VillageBake.try_load(n, bid)
		await get_tree().create_timer(3.0).timeout
		var rows = []
		var seen = {}
		var tot = 0.0
		var hist = {}
		for ch in n.find_children("*", "GeometryInstance3D", true, false):
			var me: Mesh = null
			if ch is MultiMeshInstance3D and ch.multimesh:
				me = ch.multimesh.mesh
			elif ch is MeshInstance3D:
				me = ch.mesh
			if me is ArrayMesh and not seen.has(me.get_instance_id()):
				seen[me.get_instance_id()] = true
				var v = 0
				var ix = 0
				for si in me.get_surface_count():
					v += me.surface_get_array_len(si)
					ix += me.surface_get_array_index_len(si)
				var fmt = me.surface_get_format(0) if me.get_surface_count() > 0 else 0
				rows.append([v, ix, String(n.get_path_to(ch)), fmt, ch.get_class()])
				tot += v
				var nm = String(ch.name).rstrip("0123456789@_")
				hist[nm] = hist.get(nm, 0) + v
		rows.sort_custom(func(x, y): return x[0] > y[0])
		print("BAKE %s yüklü=%s tekil mesh=%d toplam köşe=%.1f M" % [bid, r != null, rows.size(), tot / 1e6])
		for x in rows.slice(0, 25):
			print("   %8d köşe %8d indeks fmt=%x %s %s" % [x[0], x[1], x[3], x[4], x[2]])
		var hk = hist.keys()
		hk.sort_custom(func(x, y): return hist[x] > hist[y])
		for k in hk.slice(0, 20):
			print("   AD %-40s %.2f M köşe" % [k, hist[k] / 1e6])
		_dump("bake yüklü")
		print("SOAK BITTI")
		get_tree().quit()
		return
	var stops := []
	var vids = ["konoha", "suna", "kiri", "kumo", "iwa"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--vids="):
			vids = Array(a.substr(7).split(","))
	for vid in vids:
		var v = Game.village(vid)
		if v.is_empty():
			continue
		stops.append([vid + " merkez", Vector2(v["x"], v["y"])])
		stops.append([vid + " dışı", Vector2(v["x"], v["y"] + float(v["r"]) + 400)])
	for t in turns:
		for s in stops:
			pl.respawn(Game.from_map(s[1]))
			await get_tree().create_timer(wait).timeout
			_dump("%d %s" % [t + 1, s[0]])
	print("SOAK BITTI")
	get_tree().quit()
