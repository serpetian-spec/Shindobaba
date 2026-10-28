extends Node
## Kukla(lar): referans açılarından çekim (önden, yüz, yan); KIND ortam değişkeni ile tür
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	pl.set_process(false)
	var kind = OS.get_environment("KIND") if OS.get_environment("KIND") != "" else "puppet"
	var ver = OS.get_environment("VER")
	var us = ClanConstruct.spawn(pl, kind, 2, {"tier": 3})
	var u: ClanConstruct = us[int(OS.get_environment("SLOT")) if OS.get_environment("SLOT") != "" else 0]
	for x in us:
		if x != u:
			x.visible = false
	u.set_physics_process(false)
	await get_tree().create_timer(0.8).timeout
	var p = u.global_position
	var f = u.face_dir()
	var h = u.height
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	for s in [["front", f * h * 1.6 + Vector3.UP * h * 0.6, Vector3.UP * h * 0.5], ["face", f * h * 0.75 + f.cross(Vector3.UP) * h * 0.25 + Vector3.UP * h * 0.85, Vector3.UP * h * 0.85], ["side", f.cross(Vector3.UP) * h * 1.8 + Vector3.UP * h * 0.6, Vector3.UP * h * 0.5]]:
		cam.global_position = p + s[1]
		cam.look_at(p + s[2])
		await get_tree().create_timer(0.25).timeout
		await main.shot("%s_%s_%s" % [kind, ver, s[0]])
	get_tree().quit()
