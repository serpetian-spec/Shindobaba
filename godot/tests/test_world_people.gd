extends Node
## Dünya nüfusu testi: nüfus dağılımı, 200 dünya turu (gelişim, ölüm, kaçış, uyanış), Bingo'nun gerçek kişiden dolması,
## Bingo kaçağının sahada kendi jutsularıyla çıkması, köy takımının dünya insanlarından kurulması.
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1),
		"top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var all = WorldPeople.all()
	print("WP nufus=", all.size())
	var by_v = {}
	var nats = 0
	var eyes = {}
	var two = 0
	var ranks = [0, 0, 0, 0]
	for id in all:
		var p = all[id]
		by_v[p["village"]] = int(by_v.get(p["village"], 0)) + 1
		if not (p["nat"] as Array).is_empty():
			nats += 1
		if int(p["eye"][0]) > 0:
			eyes[int(p["eye"][0])] = int(eyes.get(int(p["eye"][0]), 0)) + 1
		if (p["els"] as Array).size() > 1:
			two += 1
		ranks[int(p["rank"])] += 1
	print("WP koy=", by_v, " kan_soyu=", nats, " goz=", eyes, " iki_element=", two, " rutbe=", ranks)
	var ex = all.values().filter(func(p): return int(p["rank"]) >= 2).slice(0, 4)
	for p in ex:
		print("WP ornek %s (%s, %s, Güç %d, klan=%s, soy=%s, el=%s) jutsu=%s" % [p["name"], p["village"], WorldPeople.RANK_NAMES[int(p["rank"])], int(p["level"]), p["clan"], p["nat"], p["els"], p["jutsu"]])
	var wn = main.actors.get_node("WorldPeople")
	var bb0 = Missions._bingo()["list"].size()
	for i in 400:
		wn.world_tick()
	var paths = {}
	var eyes2 = {}
	var kin = 0
	for id2 in all:
		var q = all[id2]
		if q.has("path"):
			paths[q["path"]] = int(paths.get(q["path"], 0)) + 1
		if int(q["eye"][0]) > 0:
			eyes2[int(q["eye"][0])] = int(eyes2.get(int(q["eye"][0]), 0)) + 1
		for l in q["log"]:
			if "Yasak bir parşömenden" in String(l):
				kin += 1
	print("WP yollar=", paths, " gozler=", eyes2, " kinjutsu_ogrenen=", kin)
	for id3 in all:
		var q2 = all[id3]
		if int(q2["eye"][0]) >= 4:
			print("WP goz hayati %s (%d): %s jutsu=%s" % [q2["name"], int(q2["eye"][0]), q2["log"], q2["jutsu"]])
	var dead = 0
	var rog = 0
	var ms = 0
	for id in all:
		var p = all[id]
		if not WorldPeople.alive(p):
			dead += 1
		if WorldPeople.is_rogue(p):
			rog += 1
		if int(p["eye"][0]) == 4:
			ms += 1
	print("WP 400 tur sonra nufus=%d olu=%d kacak=%d mangekyo=%d bingo %d->%d" % [all.size(), dead, rog, ms, bb0, Missions._bingo()["list"].size()])
	for id in all:
		var p = all[id]
		if WorldPeople.is_rogue(p):
			print("WP kacak hayati %s: %s" % [p["name"], p["log"]])
			break
	for id in all:
		var p = all[id]
		if int(p["eye"][0]) == 4:
			print("WP uyanis %s: %s" % [p["name"], p["log"]])
			break
	var e = WorldPeople.bingo_from_world()
	print("WP bingo yeni: ", e.get("name"), " «", e.get("alias"), "» ", e.get("rank"), " suclar=", e.get("crimes"), " jutsu=", e.get("jutsu"), " klan=", e.get("clan", ""), " goz=", e.get("eye", 0))
	if not e.is_empty():
		Missions._bb_spawn(e, main.player.global_position + Vector3(0, 0, -15))
		var sp = Missions._bb_spawned.get(int(e["id"]))
		if sp and is_instance_valid(sp[0]):
			print("WP sahada: ", sp[0].display_name, " Güç=", sp[0].level, " jutsu=", sp[0].arch.get("jutsu"))
	var ros = main.actors.get_node("AmbientTeams").roster("konoha")
	var linked = 0
	for tm in ros:
		for pe in tm["people"]:
			if String(pe.get("wid", "")) != "":
				linked += 1
	print("WP konoha takimlari dunya insanina bagli uye=", linked)
	print("WP BITTI")
	get_tree().quit()
