extends Node
## Tüm çağrı modelleri tek açılışta: SM="model,model,..." (boşsa hepsi), her biri 3/4 ön + yan kare → sm_<model>_{0,1}.png
var main: Node
const ALL := ["toad_small", "toad_mid", "toad_boss", "snake_swarm", "snake_giant", "snake_boss", "slug_frag", "slug_acid", "slug_queen", "hawk_small", "hawk_mount", "hawk_giant",
	"dog_small", "dog_pack", "dog_giant", "monkey_small", "monkey_king", "crow_flock", "salamander", "turtle_small", "turtle_giant", "weasel_trio", "cat_small", "cat_giant", "spider",
	"rin_dog", "rin_centipede", "rin_crab", "rin_rhino", "rin_ox", "rin_panda", "rin_chameleon", "baku"]

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.5
	var pl = main.player
	var a = Game.world_info["landmarks"].filter(func(l): return l.get("id", "") == "arena_earth")[0]
	var base = Game.from_map(Vector2(a["x"], a["y"]))
	pl.respawn(base)
	await get_tree().create_timer(2.5).timeout
	pl.set_process(false)
	pl.visible = false
	var list = Array(OS.get_environment("SM").split(",", false)) if OS.get_environment("SM") != "" else ALL
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.far = 3000.0
	cam.fov = 45.0
	cam.current = true
	var h = 5.0
	var nidx = 0
	for model in list:
		nidx += 1
		var ln = h * 2.0
		for cid in Contracts.DEFS:
			for tr in Contracts.DEFS[cid]["tiers"]:
				var df: Dictionary = Contracts.DEFS[cid]["tiers"][tr]
				if df["model"] == model and df.has("len"):
					ln = h * float(df["len"]) / float(df["h"])
		var d = InuzukaModels.akamaru(2.5, int(model.substr(4))) if model.begins_with("inu_") else (InuzukaModels.twin_wolf(3 if int(model.substr(5)) >= 100 else 2, 4.4, int(model.substr(5)) % 100) if model.begins_with("wolf_") and model.substr(5).is_valid_int() else SummonModels.build(model, h, ln))
		var root: Node3D = d["root"]
		main.add_child(root)
		var p = base + Vector3(0, 0, -140.0)
		p.y = Game.terrain_height(p.x, p.z)
		root.global_position = p
		await get_tree().create_timer(0.4).timeout
		var ab := AABB(); var first = true
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			var bb: AABB = mi.global_transform * mi.get_aabb()
			if first:
				ab = bb; first = false
			else:
				ab = ab.merge(bb)
		var c = ab.get_center()
		var r = maxf(ab.size.length() * 0.5, 1.0)
		for k in 2:
			var dir = [Vector3(0.75, 0.3, -1.0), Vector3(1.0, 0.15, 0.05)][k].normalized()
			cam.global_position = c + dir * r * 2.9
			cam.look_at(c)
			await get_tree().process_frame
			await get_tree().process_frame
			await main.shot("sm_%s%s_%d" % [model, ("" if list.count(model) < 2 else str(nidx)), k])
		if model.begins_with("snake") and model != "snake_swarm":   # baş yakın çekim
			var mp: Vector3 = root.global_position + d["mouth"]
			for k in 2:
				cam.global_position = mp + [Vector3(0.9, 0.35, -1.0), Vector3(1.0, 0.1, 0.25)][k].normalized() * h * 2.2
				cam.look_at(mp + Vector3(0, h * 0.15, h * 0.5))
				await get_tree().process_frame
				await get_tree().process_frame
				await main.shot("sm_%s_h%d" % [model, k])
		root.queue_free()
		await get_tree().process_frame
	print("SM BITTI")
	get_tree().quit()
