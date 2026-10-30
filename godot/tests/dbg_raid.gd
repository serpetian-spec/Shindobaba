extends Node
## Köy baskını + NPC klan/jutsu + kuyruklu canavar gücü + eskort NPC takılma
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Game.profile["level"] = 50
	Game.profile["rank"] = 3
	# NPC klan + jutsu
	var clans = 0
	for i in 12:
		var a = Enemy.archetype(["kiri", "kumo", "rogue", "iwa"][i % 4], i)
		a["level"] = 50
		a["jutsu"] = Enemy.auto_jutsu(a["kind"], String(a["element"]), 50)
		var e = Enemy.new()
		e.setup(a)
		if a.has("clan"):
			clans += 1
		print("NPC ", e.display_name, " skill=", snappedf(e.skill, 0.01), " jutsu=", a["jutsu"])
		e.free()
	print("NPC clan count=", clans, "/12")
	var tb = TailedBeast.new()
	tb.setup("kurama")
	print("BEAST ", tb.display_name, " hp=", tb.max_hp, " power=", tb.power)
	tb.free()
	Kage.st()["rel"]["kumo"] = -60
	Kage.start_raid("kumo")
	await get_tree().create_timer(2.0).timeout
	print("RAID enemies=", Kage.raid["nodes"].size(), " allies=", Kage.raid["allies"].size(), " names=", Kage.raid["nodes"].map(func(e): return e.display_name).slice(0, 4))
	var c = Kage.raid["at"]
	var cam = Camera3D.new()
	main.add_child(cam)
	main.player.set_process(false)
	cam.current = true
	main.world.env.attach_post(cam)
	cam.global_position = c + Vector3(0, 25, 35)
	cam.look_at(c)
	await get_tree().create_timer(1.5).timeout
	await main.shot("raid")
	for e in Kage.raid["nodes"]:
		e.take_hit({"dmg": 1e6, "knock": 1.0, "kind": "heavy", "dir": Vector3.FORWARD, "element": ""})
	await get_tree().create_timer(1.0).timeout
	Kage._raid_watch(0.1)
	print("RAID over=", Kage.raid.is_empty(), " rep=", Game.profile["rep"].get("konoha", 0))
	get_tree().quit()
