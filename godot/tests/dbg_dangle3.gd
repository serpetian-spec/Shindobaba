extends Node
## Arka kafa yakın çekim: solda fiziksiz, sağda fizikli (HAIR stili). Dururken + koşarken.
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500))
	base.y = Game.terrain_height(base.x, base.z)
	var st = OS.get_environment("HAIR") if OS.get_environment("HAIR") != "" else "diken"
	var ms = []
	for i in 2:
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup({"gender": "m", "hair_style": st, "hair": Color(0.12, 0.08, 0.07), "top_style": "uzun", "band": null, "face": [0, 0, 0]})
		m.global_position = base + Vector3(i * 0.7, 0, 0)
		m.play("idle")
		if i == 0:
			m._dangles = []
		ms.append(m)
		for d in m._dangles:
			print("DYN ", i, " ", d.mi.name, " chains=", d.chains.size())
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 30
	var fwd = ms[0].global_transform.basis.z
	var c = base + Vector3(0.35, 1.6, 0)
	cam.global_position = c + fwd * 1.8 + Vector3(0, 0.2, 0)
	cam.look_at(c)
	await get_tree().create_timer(1.0).timeout
	await main.shot("d3_%s_rest" % st)
	for m in ms:
		m.play("run")
	await get_tree().create_timer(0.6).timeout
	await main.shot("d3_%s_run" % st)
	get_tree().quit()
