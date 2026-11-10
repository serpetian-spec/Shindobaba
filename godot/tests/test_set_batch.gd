extends Node
## SB_FROM/SB_TO: StrikerSets.SHOP dilimi; her set için ön + arka kare (cinsiyet setin "sex"inden, boşsa SB_G)
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	var ids: Array = Gear.STRIKER.SHOP.slice(int(OS.get_environment("SB_FROM")), int(OS.get_environment("SB_TO")))
	var g0 = OS.get_environment("SB_G") if OS.get_environment("SB_G") != "" else "m"
	main.creator_state = {"slot": 98, "name": "T", "gender": g0, "clan": "none", "element": "katon", "village": "konoha", "hair_style": "s2", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.5)
	Hud.close_dialog()
	Hud.visible = false
	var pl = main.player
	var sp = Missions._spot("konoha", 600, 900)
	var base = Missions.open_ground(Game.from_map(Vector2(sp[0], sp[1])) + Vector3(25, 0, 25), 60.0)
	pl.respawn(base + Vector3(0, 0.5, 0))
	await _w(1.0)
	for mm in get_tree().current_scene.find_children("*", "GeometryInstance3D", true, false):
		if mm is MultiMeshInstance3D or "rass" in String(mm.name) or "imen" in String(mm.name):
			mm.queue_free()
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 38.0
	for sid in ids:
		var sx = String(Gear.item(sid).get("sex", ""))
		Game.profile["look"]["gender"] = sx if sx != "" else g0
		Gear.grant(Game.profile, sid, "set")
		Gear.apply_look(Game.profile)
		pl.rebuild_model()
		await _w(1.6)
		pl.facing = 0.0
		pl.model.rotation.y = 0.0
		var p = pl.model.global_position
		var k = 0
		for v in [Vector3(-0.7, 1.0, -2.3), Vector3(0.6, 1.0, 2.3)]:
			cam.global_position = p + v
			cam.look_at(p + Vector3(0, 0.85, 0))
			await _w(0.25)
			await main.shot("sb_%s_%d" % [sid, k])
			k += 1
	get_tree().quit()
