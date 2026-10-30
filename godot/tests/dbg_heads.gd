extends Node
## Hokage yüzleri: altlarında kaya ayağı + uçuruma çıkan merdiven
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	main.world.env.time_of_day = 0.42
	var cam = Camera3D.new()
	cam.far = 6000.0
	main.add_child(cam)
	cam.current = true
	main.world.env.attach_post(cam)
	var v = Game.village("konoha")
	var rock: Dictionary = v["hokage_rock"]
	var cn = float(rock["y"])
	for st in [["uzak", Vector2(0, -330), 30.0, Vector2(0, -20), 90.0], ["yan", Vector2(-420, -160), 20.0, Vector2(-130, -10), 70.0], ["merdiven", Vector2(-330, -90), 8.0, Vector2(-285, 0), 60.0]]:
		var cp = Game.from_map(Vector2(float(v["x"]) + st[1].x, cn + st[1].y))
		cp.y = Game.terrain_height(cp.x, cp.z) + st[2]
		var tp = Game.from_map(Vector2(float(v["x"]) + st[3].x, cn + st[3].y))
		tp.y = float(v["base"]) + st[4]
		cam.global_position = cp
		cam.look_at(tp)
		await get_tree().create_timer(2.5).timeout
		await main.shot("heads_" + st[0])
	get_tree().quit()
