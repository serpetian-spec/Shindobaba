extends Node
## İlk kullanım kıyafet parçası maliyeti: önbellek boşken dış giysi × cinsiyet kurulur, parça süreleri (PROFG) yazılır.
## SHOT=1: her modelin önden / arkadan görüntüsü (_tmp/shots/garment/).
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	load("res://scripts/actors/character_model.gd").set("PROF", true)
	var shot = OS.get_environment("SHOT") != ""
	var cam: Camera3D = null
	if shot:
		var env = WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.background_mode = Environment.BG_COLOR
		env.environment.background_color = Color(0.55, 0.6, 0.65)
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color(1, 1, 1)
		env.environment.ambient_light_energy = 0.9
		add_child(env)
		var sun = DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-40, 30, 0)
		add_child(sun)
		cam = Camera3D.new()
		add_child(cam)
		cam.current = true
		cam.fov = 35.0
	var outs = ["haori", "mino", "panco", "pelerin", "palto", "kisa"]
	var total = 0
	var k = 0
	for o in outs:
		for gd in ["m", "f"]:
			for hk in [false, true]:
				var lk = CharacterModel.default_look()
				lk["gender"] = gd
				lk["hair_style"] = "s2" if gd == "m" else "f2"
				lk["outer_style"] = o
				lk["hakama"] = hk
				lk["face_id"] = 0
				var cm = CharacterModel.new()
				add_child(cm)
				var t0 = Time.get_ticks_usec()
				cm.setup(lk)
				var ms = (Time.get_ticks_usec() - t0) / 1000
				total += ms
				print("GCOST %s %s hakama=%s kurulum=%d ms" % [o, gd, hk, ms])
				if shot:
					cm.position = Vector3(k * 4.0, 0, 0)
					await get_tree().process_frame
					for side in [1.0, -1.0]:
						var tg = cm.position + Vector3(0, 0.95, 0)
						cam.position = tg + Vector3(0.9 * side, 0.2, 3.6 * side)
						cam.look_at(tg)
						await get_tree().process_frame
						await get_tree().process_frame
						get_viewport().get_texture().get_image().save_png("D:/Naruto 3D Game/_tmp/shots/garment/%s_g_%02d_%s.png" % [OS.get_environment("SHOT"), k, "on" if side > 0 else "arka"])
				cm.queue_free()
				k += 1
	print("GCOST toplam %d ms" % total)
	get_tree().quit()
