extends Node
## Hareket pozları: süper zıplama şarjı (çömelme), Naruto koşusu, süzülme, koşarken vuruş (yan + arka görünüş)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	main.world.env.time_of_day = 0.42
	if main.player:
		main.player.visible = false
	var v = Game.village("konoha")
	var base = Exams.find_point(["training"])
	base.y = Game.terrain_height(base.x, base.z)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	main.world.env.attach_post(cam)
	var setups = [
		["sarj", "idle", {"charge": 1.0}],
		["kosu", "run", {"ninja_run": 1.0}],
		["suzul", "air", {"leap": 1.0}],
		["inis", "air", {"leap": 1.0}],
		["vurus", "run", {"ninja_run": 1.0}],
	]
	var models = []
	for i in setups.size():
		for ai in 2:
			var m = CharacterModel.new()
			main.add_child(m)
			m.setup({"gender": "m", "hair_style": "diken", "hair": Color(0.95, 0.8, 0.25), "age": ["child", "adult"][ai], "band": Color(0.15, 0.22, 0.55)})
			var p = base + Vector3((i * 2 + ai) * 8.0, 0, 0)
			p.y = Game.terrain_height(p.x, p.z) + (1.2 if setups[i][0] in ["suzul", "inis"] else 0.0)
			m.global_position = p
			m.play(setups[i][1], 0.0, 1.0)
			if "charge_k" in m.overlay:
				m.overlay.charge_k = 1.0
			if setups[i][0] == "inis":
				m.overlay.glide_land = 1.0
			for k in setups[i][2]:
				m.overlay.set_pose(k, setups[i][2][k])
			models.append(m)
	await get_tree().create_timer(1.0).timeout
	# koşarken ani vuruş: oyuncunun yaptığı gibi koşu kollarını bırak, yumruğu oynat
	for mi in models.size():
		if setups[mi / 2][0] == "vurus":
			models[mi].overlay.snap("ninja_run", 0.0)
			models[mi].play("jab", 0.05, 1.5, true)
	await get_tree().create_timer(0.12).timeout
	var views = [["yan", Vector3(3.2, 0.2, 0.0)], ["arka", Vector3(0.0, 0.9, 3.4)], ["on", Vector3(0.0, 0.5, -3.4)], ["capraz", Vector3(2.3, 0.8, 2.3)]]
	for mi in models.size():
		var m = models[mi]
		for vw in views:
			cam.global_position = m.global_position + Vector3(0, 0.9, 0) + vw[1]
			cam.look_at(m.global_position + Vector3(0, 0.8, 0))
			await get_tree().process_frame
			if setups[mi / 2][0] == "vurus":
				models[mi].play("jab", 0.0, 1.5, true)
				models[mi].anim.seek(0.12, true)
			await main.shot("poz_%s_%s_%s" % [setups[mi / 2][0], ["cocuk", "yetiskin"][mi % 2], vw[0]])
	get_tree().quit()
