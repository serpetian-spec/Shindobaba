extends Node
## Alın koruyucu görünürlüğü: her saç stilinde önden / yandan / arkadan yakın çekim
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500))
	base.y = Game.terrain_height(base.x, base.z)
	var styles = OS.get_environment("HAIR").split(",", false) if OS.get_environment("HAIR") != "" else CharacterModel.HAIR_STYLES.keys()
	var ms = []
	for i in styles.size():
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup({"gender": "f" if i % 2 else "m", "hair_style": styles[i], "hair": Color(0.15, 0.1, 0.08), "top_style": "uzun", "band": Color(0.15, 0.2, 0.45), "band_style": OS.get_environment("BAND") if OS.get_environment("BAND") != "" else "head", "head_style": OS.get_environment("HEAD") if OS.get_environment("HEAD") != "" else null, "headgear": Color(0.6, 0.15, 0.12) if OS.get_environment("HG") == "" else Color(OS.get_environment("HG")), "hood": OS.get_environment("HOOD"), "crest": OS.get_environment("CREST"), "back_item": OS.get_environment("BACK") if OS.get_environment("BACK") != "" else null, "face_style": OS.get_environment("FACE") if OS.get_environment("FACE") != "" else null, "facegear": Color(0.2, 0.2, 0.24) if OS.get_environment("FG") == "" else Color(OS.get_environment("FG")), "village": "konoha", "face": [0, 0, 0]})
		m.global_position = base + Vector3(i * 3.0, 0, 0)
		m.play("idle")
		m.set_process(false)
		ms.append(m)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 22
	await get_tree().create_timer(0.6).timeout
	var fwd = ms[0].global_transform.basis.z
	for i in ms.size():
		var hb = ms[i].skel.find_bone("Head")
		var c = (ms[i].skel.global_transform * ms[i].skel.get_bone_global_pose(hb)).origin + Vector3(0, float(OS.get_environment("CAMY")) if OS.get_environment("CAMY") != "" else 0.07, 0)
		for vw in [["f", fwd], ["q", (fwd + fwd.cross(Vector3.UP)).normalized()], ["s", fwd.cross(Vector3.UP)], ["b", -fwd]]:
			cam.global_position = c + (vw[1] as Vector3) * (float(OS.get_environment("DIST")) if OS.get_environment("DIST") != "" else 1.3) + Vector3(0, 0.12, 0)
			cam.look_at(c)
			await get_tree().process_frame
			await main.shot("bv_%02d_%s" % [i, vw[0]])
	get_tree().quit()
