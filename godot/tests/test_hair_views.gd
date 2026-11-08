extends Node
## SV_H=stil (SV_G=m/f, SV_BAND=1 alın bandı) → kafa yakın çekimi: ön, 3/4, yan, arka, tepe, alt
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	var g = OS.get_environment("SV_G") if OS.get_environment("SV_G") != "" else "m"
	main.creator_state = {"slot": 3, "name": "Test", "gender": g, "clan": "none", "element": "katon", "village": "konoha", "hair_style": OS.get_environment("SV_H"), "hair": Color(0.32, 0.22, 0.16), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.5)
	Hud.close_dialog()
	Hud.visible = false
	var pl = main.player
	if OS.get_environment("SV_BAND") != "":
		Gear.grant(Game.profile, OS.get_environment("SV_BAND") if OS.get_environment("SV_BAND").length() > 1 else "alin_koruyucu", "kafa")
		Gear.apply_look(Game.profile)
		pl.rebuild_model()
	if OS.get_environment("SV_BAND") == "":
		var hl: Dictionary = Game.profile.get("hide_look", {})
		for sl in ["kafa", "yuz"]:
			hl[sl] = true
		Game.profile["hide_look"] = hl
		Gear.apply_look(Game.profile)
		pl.rebuild_model()
	await _w(3.0)
	for mm in get_tree().current_scene.find_children("*", "GeometryInstance3D", true, false):
		if mm is MultiMeshInstance3D:
			mm.queue_free()
	for nd in get_tree().current_scene.find_children("*", "GPUParticles3D", true, false):
		if not pl.is_ancestor_of(nd):
			nd.queue_free()
	pl.set_physics_process(false)
	pl.model.rotation.y = 0.0
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 30.0
	await _w(0.5)
	var hb = pl.model.skel.find_bone("Head")
	var hp: Vector3 = (pl.model.skel.global_transform * pl.model.skel.get_bone_global_pose(hb)).origin + Vector3(0, 0.08, 0)
	print("HAIR head ", hp)
	var views = [Vector3(0, 0.05, 1), Vector3(0.7, 0.1, 0.7), Vector3(1, 0.05, 0), Vector3(0, 0.05, -1), Vector3(-0.6, 0.15, -0.75), Vector3(0.3, 1.0, 0.25)]
	var tag = OS.get_environment("SV_TAG")
	for k in views.size():
		var dv: Vector3 = views[k].normalized()
		dv = -(pl.model.global_transform.basis * dv)
		dv.y = -dv.y
		cam.global_position = hp + dv * 1.25
		cam.look_at(hp, Vector3.UP if absf(dv.y) < 0.9 else Vector3.FORWARD)
		await _w(0.25)
		await main.shot("hv_%s%s_%d" % [OS.get_environment("SV_H"), tag, k])
	get_tree().quit()
