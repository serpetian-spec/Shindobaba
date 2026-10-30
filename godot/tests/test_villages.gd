extends Node
## Köy mimarisi vitrini: her köy için kuşbakışı + sokak seviyesi çekim (akışla kurulmasını bekler).
var main: Node

## köy id, sokak noktası (merkeze göre harita x, y), bakış (derece, 0 = kuzey)
const SPOTS := [
	["suna", Vector2(0, -260), 0.0], ["kiri", Vector2(-120, -200), 20.0], ["kumo", Vector2(60, -260), 0.0],
	["iwa", Vector2(0, -250), 0.0], ["ame", Vector2(0, -200), 0.0], ["tetsu", Vector2(0, -260), 0.0],
	["taki", Vector2(0, -300), 0.0], ["nami", Vector2(80, -160), 180.0], ["yu", Vector2(0, -60), 0.0],
	["oto", Vector2(0, -120), 0.0], ["tani", Vector2(0, -120), 0.0], ["shimo", Vector2(40, -60), 0.0], ["uzushio", Vector2(0, -60), 0.0],
]


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var cam = Camera3D.new()
	cam.far = 20000.0
	main.add_child(cam)
	var only = OS.get_environment("VILLAGE")
	for s in SPOTS:
		if only != "" and not String(s[0]) in only.split(","):
			continue
		var v = Game.village(s[0])
		Game.world.env.time_of_day = 0.42
		Game.world.env.region_weather = "açık"
		Game.world.env.weather_t = 999
		Game.world.env.overcast = 0.0
		Game.world.env.weather = "açık"
		Game.world.env.set_process(false)
		Game.world.env.env.fog_density = 0.0001
		Game.world.env.rain.emitting = false
		var sp: Vector2 = s[1]
		var p = Game.from_map(Vector2(v["x"] + sp.x, v["y"] + sp.y))
		p.y = Game.ground_height(p.x, p.z) + 0.5
		pl.respawn(p)
		pl.set_physics_process(false)
		await get_tree().create_timer(float(OS.get_environment("VWAIT")) if OS.get_environment("VWAIT") != "" else 9.0).timeout
		var c = Game.from_map(Vector2(v["x"], v["y"]))
		c.y = float(v["base"])
		var r = float(v["r"])
		# kuşbakışı (güneydoğudan)
		cam.current = true
		main.world.env.attach_post(cam)
		cam.global_position = c + Vector3(r * 0.9, r * 0.55, r * 1.05)
		cam.look_at(c + Vector3(0, 40, 0))
		await get_tree().create_timer(1.0).timeout
		await main.shot("v_%s_ust" % s[0])
		# sokak seviyesi
		var yaw = deg_to_rad(float(s[2]))
		var fwd = Vector3(sin(yaw), 0, -cos(yaw))
		cam.global_position = p + Vector3(0, 2.2, 0) - fwd * 4.0
		cam.look_at(cam.global_position + fwd * 10.0 + Vector3(0, 1.2, 0))
		await get_tree().create_timer(0.8).timeout
		await main.shot("v_%s_sokak" % s[0])
		# yukarı bakış (dikey yapılar)
		cam.look_at(cam.global_position + fwd * 10.0 + Vector3(0, 7, 0))
		await get_tree().create_timer(0.4).timeout
		await main.shot("v_%s_yukari" % s[0])
		cam.current = false
		main.world.env.attach_post(pl.cam)
		pl.set_physics_process(true)
	get_tree().quit()
