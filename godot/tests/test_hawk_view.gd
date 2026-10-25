extends Node
## Şahin: referans açılarına benzer çekimler (önden-aşağıdan, yukarıdan, yandan) — kanatlar ve maske görünsün
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
	var h = 4.0
	var d = SummonModels.build("hawk_giant", h, h)
	var root: Node3D = d["root"]
	main.add_child(root)
	var p = pl.global_position + Vector3(0, 0, -30)
	p.y = Game.ground_height(p.x, p.z) + h * 1.2   # havada
	root.global_position = p
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	var ver = OS.get_environment("VER")
	for s in [["below", Vector3(0, -h * 0.9, -h * 3.2)], ["above", Vector3(h * 1.0, h * 2.6, -h * 2.2)], ["face", Vector3(h * 0.4, h * 0.15, -h * 1.7)]]:
		cam.global_position = p + s[1]
		cam.look_at(p + Vector3(0, h * 0.6, -h * 0.4) if s[0] == "face" else p + Vector3(0, h * 0.5, 0))
		await get_tree().create_timer(0.3).timeout
		await main.shot("hawk_%s_%s" % [ver, s[0]])
	get_tree().quit()
