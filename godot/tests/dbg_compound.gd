extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var rows = []
	for sb in get_tree().current_scene.find_children("*", "CollisionObject3D", true, false):
		var n = 0
		for o in sb.get_shape_owners():
			n += sb.shape_owner_get_shape_count(o)
		var tri = 0
		for o in sb.get_shape_owners():
			for k in sb.shape_owner_get_shape_count(o):
				var sh0 = sb.shape_owner_get_shape(o, k)
				if sh0 is ConcavePolygonShape3D:
					tri += sh0.get_faces().size() / 3
		if tri > 0 and n > 1:
			print("TRI %d shapes=%d tris=%d %s" % [sb.get_instance_id(), n, tri, str(sb.get_path()).right(80)])
		if n > 100:
			var kinds = {}
			for o in sb.get_shape_owners():
				for k in sb.shape_owner_get_shape_count(o):
					var sh = sb.shape_owner_get_shape(o, k)
					kinds[sh.get_class()] = int(kinds.get(sh.get_class(), 0)) + 1
			rows.append([n, str(sb.get_path()).right(90), str(kinds), sb.get_class()])
	rows.sort()
	rows.reverse()
	for r in rows.slice(0, 8):
		print("CMP ", r)
	get_tree().quit()
