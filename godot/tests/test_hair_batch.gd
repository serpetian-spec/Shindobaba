extends Node
## Toplu saç/başlık çekimi tek oturumda: HB_H="e0:m,e2:f,..." (saç) ya da HB_HEAD="iwabe:m,..." (başlık, saç s2/f2)
## Her model için 4 açı (ön, 3/4, yan, arka) yetişkin, yakın çekim -> hb_<anahtar>_<açı>.png
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "age": "adult", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "s2", "hair": Color(0.32, 0.22, 0.16), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	Hud.visible = false
	var heads = OS.get_environment("HB_HEAD") != ""
	var bands = OS.get_environment("HB_BAND") != ""
	var items = (OS.get_environment("HB_BAND") if bands else (OS.get_environment("HB_HEAD") if heads else OS.get_environment("HB_H"))).split(",", false)
	var base: Vector3 = main.player.global_position + Vector3(0, 0, -6)
	main.player.visible = false
	main.player.set_physics_process(false)
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.fov = 30
	cam.current = true
	var views = [Vector3(0, 0.05, 1), Vector3(0.7, 0.1, 0.7), Vector3(1, 0.05, 0), Vector3(0, 0.1, -1)]
	for it in items:
		var a = it.split(":")
		var lk = Game.profile["look"].duplicate()
		lk["gender"] = a[1] if a.size() > 1 else "m"
		lk["age"] = "adult"
		lk["own_hair"] = true
		lk["hair"] = Color(0.32, 0.22, 0.16)
		if OS.get_environment("HB_FP") != "":   # yüz boyası: HB_FP=1, öğeler "fpN:cinsiyet"
			lk["hair_style"] = "s23" if lk["gender"] == "m" else "f14"
			lk["head_style"] = null
			lk["face_paint"] = a[0]
			lk["mask"] = null
			lk["face_style"] = null
		elif bands:   # HB_BAND="takılış:cinsiyet:saç"
			lk["hair_style"] = a[2] if a.size() > 2 else ("f2" if lk["gender"] == "f" else "s2")
			lk["head_style"] = null
			lk["band"] = Color(0.15, 0.2, 0.45)
			lk["band_style"] = "head"
			lk["band_wear"] = a[0]
		elif heads:
			lk["hair_style"] = "f2" if lk["gender"] == "f" else "s2"
			lk["head_style"] = a[0]
			lk["headgear"] = Color(a[2]) if a.size() > 2 else Color(0.25, 0.25, 0.3)
		else:
			lk["hair_style"] = a[0]
			lk["head_style"] = null
		if OS.get_environment("HB_FP") == "":
			lk["face_style"] = null
		if OS.get_environment("HB_NOMASK") != "" or OS.get_environment("HB_FP") != "":
			lk["mask"] = null
			lk["top_style"] = "tisort"
		var m = CharacterModel.new()
		get_tree().current_scene.add_child(m)
		m.setup(lk)
		var gy = Game.terrain_height(base.x, base.z)
		m.global_position = Vector3(base.x, gy, base.z)
		m.rotation.y = 0.0
		await get_tree().create_timer(0.6).timeout
		var hb = m.skel.find_bone("Head")
		var c: Vector3 = (m.skel.global_transform * m.skel.get_bone_global_pose(hb)).origin + Vector3(0, 0.02, 0)
		var dist = 1.6
		if bands and a[0] in ["bel", "kol", "kusak", "boyun"]:
			c += Vector3(0, -0.45 if a[0] != "boyun" else -0.15, 0)
			dist = 2.6 if a[0] != "boyun" else 1.8
		if OS.get_environment("HB_BODY") != "":   # boydan: saçın bele/kalçaya göre boyu görünsün
			c += Vector3(0, -0.42, 0)
			dist = 3.5
		for vi in views.size():
			var dv: Vector3 = views[vi].normalized()
			cam.global_position = c + dv * dist * (float(OS.get_environment("HB_ZOOM")) if OS.get_environment("HB_ZOOM") != "" else 1.0)
			cam.look_at(c, Vector3.UP)
			await get_tree().create_timer(0.2).timeout
			await main.shot("hb_%s%s_%d" % [a[0], ("_" + a[2]) if bands and a.size() > 2 else "", vi])
		m.queue_free()
		await get_tree().process_frame
	get_tree().quit()
