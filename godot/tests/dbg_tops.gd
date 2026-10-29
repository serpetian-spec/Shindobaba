extends Node
## Yeni üst kıyafetleri: 10 karakter yan yana, önden ve arkadan çekim. Env TOP0 = başlangıç numarası (1..100), BACK=1 arkadan
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.0).timeout
	pl.set_process(false)
	pl.visible = false
	var t0 = int(OS.get_environment("TOP0")) if OS.get_environment("TOP0") != "" else 1
	var step = int(OS.get_environment("STEP")) if OS.get_environment("STEP") != "" else 1
	var kind = OS.get_environment("KIND") if OS.get_environment("KIND") != "" else "ust"
	var base = pl.global_position + Vector3(0, 0, -6)
	base.y = Game.ground_height(base.x, base.z)
	for i in 10:
		var id = "%s_%03d" % [kind, t0 + i * step]
		var it: Dictionary = Gear.ITEMS.get(id, {})
		if it.is_empty():
			continue
		var L = CharacterModel.default_look()
		for k in it.get("look", {}):
			L[k] = it["look"][k]
		var c1: Color = it.get("c1", Color.WHITE)
		var c2: Color = it.get("c2", c1)
		match String(it.get("slot", "")):
			"govde":
				L["top"] = c1; L["top2"] = c2
				L["sleeves"] = String(it["look"].get("top_style", "")) not in ["tisort", "kolsuz"]
			"bacak":
				L["pants"] = c1
			"ayak":
				L["sandal"] = c1; L["wraps"] = c2
			"sirt":
				L["backc"] = c1
			"yuz":
				L["facegear"] = c1
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup(L)
		var p = base + Vector3((i - 4.5) * 1.1, 0, 0)
		p.y = Game.ground_height(p.x, p.z)
		m.global_position = p
		m.rotation.y = PI if OS.get_environment("BACK") != "" else 0.0
		m.play("idle", 0.0)
		var l = Label3D.new()
		l.text = str(t0 + i * step)
		l.font_size = 64
		l.pixel_size = 0.004
		l.position = Vector3(0, 2.1, 0)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		m.add_child(l)
	await get_tree().create_timer(0.8).timeout
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.fov = 40
	var zoom = float(OS.get_environment("CAMY")) if OS.get_environment("CAMY") != "" else 1.1
	cam.global_position = base + Vector3(0, zoom, 8.5)
	cam.look_at(base + Vector3(0, zoom, 0))
	cam.current = true
	await get_tree().create_timer(0.3).timeout
	await main.shot("tops_%d" % t0)
	get_tree().quit()
