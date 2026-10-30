extends Node
## Köy boşlukları: surun üstünden içeri bakan havadan görüntüler (Konoha + akışla kurulan bir köy)
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
	var vid = OS.get_environment("FILL_VID") if OS.get_environment("FILL_VID") != "" else "konoha"
	var v = Game.village(vid)
	if vid != "konoha":
		# akış düğümü köyü kursun diye kamerayı köye taşı ve bekle
		var c0 = Game.from_map(Vector2(v["x"], v["y"]))
		cam.global_position = c0 + Vector3(0, 300, 0)
		for i in 40:
			await get_tree().create_timer(1.0).timeout
	var R = float(v["r"]) * 0.95
	for ang in [270.0, 0.0, 90.0, 180.0]:
		var a = deg_to_rad(ang)
		var mp = Vector2(v["x"], v["y"]) + Vector2(sin(a), cos(a)) * R
		var p = Game.from_map(mp)
		p.y = Game.terrain_height(p.x, p.z) + 120.0
		var c = Game.from_map(Vector2(v["x"], v["y"]))
		c.y = float(v["base"])
		cam.global_position = p
		cam.look_at(p.lerp(c, 0.45) - Vector3(0, 110, 0))
		await get_tree().create_timer(2.0).timeout
		await main.shot("fill_%s_%d" % [vid, int(ang)])
	get_tree().quit()
