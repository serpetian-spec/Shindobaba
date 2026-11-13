extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	for f in DirAccess.get_files_at("res://../_tmp/bake_dev"):
		if not f.ends_with(".scn") or not (f.begins_with("kumo") or f.begins_with("kiri") or f.begins_with("konoha")):
			continue
		var ps = ResourceLoader.load("res://../_tmp/bake_dev/" + f, "", ResourceLoader.CACHE_MODE_IGNORE)
		var root = ps.instantiate()
		var st = {}
		for m in root.find_children("*", "MeshInstance3D", true, false):
			var nm = String(m.name).substr(0, 2)
			var k = nm
			if not st.has(k):
				st[k] = [0, 0, 0, 0.0]
			st[k][0] += 1
			if m.mesh == null or m.mesh.get_surface_count() == 0:
				st[k][1] += 1
			elif m.mesh.get_aabb().size.length() < 0.001:
				st[k][2] += 1
			if not m.visible:
				st[k][3] += 1
		var keys = st.keys(); keys.sort()
		var line = ""
		for k in keys:
			if st[k][0] > 20 or st[k][1] > 0:
				line += " %s:%s" % [k, str(st[k])]
		print("BK ", f, line)
		root.free()
	get_tree().quit()
