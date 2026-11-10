extends Node
## Köy görünüş karşılaştırması: VC_V köyü kurulur, VC_CAMS kameralarından kare alınır.
## VC_CAMS = "ad:x,y,n>x,y,n;..." (köy yerel koordinatı: x doğu, y taban üstü, n kuzey; kamera > hedef)
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	var vid = OS.get_environment("VC_V")
	main.creator_state = {"slot": 98, "name": "T", "gender": "m", "clan": "none", "element": "katon", "village": vid if vid in ["konoha", "suna", "kiri", "kumo", "iwa"] else "konoha", "hair_style": "s2", "hair": Color(0.2, 0.2, 0.2), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(3.0)
	Hud.close_dialog()
	var v = Game.village(vid)
	var org = Vector3(float(v["x"]), float(v["base"]), -float(v["y"]))
	var pl = main.player
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	pl.respawn(c + Vector3(0, 2, 0))
	if vid != "konoha":
		var vs = get_tree().current_scene.find_child("VillageStream", true, false)
		if vs:
			var rec = vs.request(vid)
			var t = 0.0
			while not rec.get("done", false) and t < 200.0:
				await _w(0.5)
				t += 0.5
			print("VC built in ", t)
	await _w(4.0)
	Hud.visible = false
	var cam = Camera3D.new()
	cam.far = 9000.0
	get_tree().current_scene.add_child(cam)
	for spec in OS.get_environment("VC_CAMS").split(";", false):
		var nm = spec.split(":")[0]
		var pp = spec.split(":")[1].split(">")
		var a = pp[0].split(",")
		var b = pp[1].split(",")
		var cp = org + Vector3(float(a[0]), float(a[1]), -float(a[2]))
		var tp = org + Vector3(float(b[0]), float(b[1]), -float(b[2]))
		pl.global_position = Vector3(cp.x, Game.ground_height(cp.x, cp.z) + 0.5, cp.z)
		pl.velocity = Vector3.ZERO
		await _w(2.5)
		cam.global_position = cp
		cam.look_at(tp)
		cam.make_current()
		await _w(1.5)
		await main.shot("%s_%s" % [vid, nm])
	get_tree().quit()
