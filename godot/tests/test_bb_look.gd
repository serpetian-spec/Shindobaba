extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var ents = Missions.bingo_entries()
	var n = 0
	for x in ents.slice(0, 6):
		var e = null
		for be in Missions._bingo()["list"]:
			if int(be["id"]) == int(x["id"]):
				e = be
		if e == null:
			continue
		var pl = Game.player.global_position + Vector3(5 + n * 3, 0, 5)
		Missions._bb_spawn(e, pl)
		await get_tree().create_timer(0.3).timeout
		for f in get_tree().get_nodes_in_group("fighters"):
			if f.has_meta("bingo_id") and int(f.get_meta("bingo_id")) == int(e["id"]):
				var a: Dictionary = x["look"]
				var b: Dictionary = f.look
				var diff = []
				for k in a:
					if str(k).begins_with("hair") or k in ["band_style", "head", "hat"]:
						if str(a.get(k)) != str(b.get(k)):
							diff.append("%s: %s -> %s" % [k, str(a.get(k)), str(b.get(k))])
				for k in b:
					if str(k).begins_with("hair") and not a.has(k):
						diff.append("%s: (yok) -> %s" % [k, str(b.get(k))])
				var md = f.model.look if f.get("model") else {}
				var diff2 = []
				for k in md:
					if str(k).begins_with("hair") and str(md.get(k)) != str(a.get(k)):
						diff2.append("%s: %s -> %s" % [k, str(a.get(k)), str(md.get(k))])
				print("BB %s diff=%s model_diff=%s" % [e["name"], str(diff), str(diff2)])
				var before = Friends.all().keys()
				RogueBonds.spare(f)
				for fid in Friends.all():
					if not fid in before:
						var fr: Dictionary = Friends.all()[fid]
						var A = Friends.arch(fr)
						var L: Dictionary = A["look"]
						var d3 = []
						for k in a:
							if str(L.get(k)) != str(a.get(k)) and not k in ["band", "band_style", "village", "vest", "age"]:
								d3.append("%s: %s -> %s" % [k, str(a.get(k)), str(L.get(k))])
						print("BB friend_arch diff=", d3)
						var vg = Friends.inst()._spawn_npc(fid, Game.player.global_position + Vector3(3, 0, 0), false)
						await get_tree().create_timer(0.5).timeout
						var vl: Dictionary = vg.model.look if vg.get("model") else {}
						var d4 = []
						for k in ["hair", "hair_style", "head", "gender", "skin"]:
							if str(vl.get(k)) != str(a.get(k)):
								d4.append("%s: %s -> %s" % [k, str(a.get(k)), str(vl.get(k))])
						print("BB friend_villager diff=", d4)
		n += 1
	get_tree().quit()
