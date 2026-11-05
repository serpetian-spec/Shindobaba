extends Node
## Kaçakken yolda tek kaçak: tanışınca sığınak yeri ayrılır; sığınakta yalnız tanıştıkların durur
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	var pl = main.player
	Game.profile["rank"] = 2
	Orgs.defect()
	await get_tree().create_timer(0.3).timeout
	Hud.close_dialog()
	var hp = Orgs.hideout_pos()
	pl.respawn(hp + Vector3(0, 1, 60))
	await get_tree().create_timer(5.0).timeout
	Orgs._ensure_hideout()
	var n0 = Orgs._hideout_node.find_children("*", "Villager", true, false).size()
	print("LONE sığınakta başta kaçak=%d" % n0)
	Encounters.start("lone_rogue")
	await get_tree().create_timer(0.5).timeout
	var r = Encounters.cur.get("rogue")
	print("LONE yolda kaçak var=%s" % (r != null and is_instance_valid(r)))
	Friends._meet(r)
	var fid = ""
	for id in Friends.all():
		if String(Friends.all()[id].get("site", "")).begins_with("hideout_"):
			fid = id
	print("LONE tanışıldı: id=%s rütbe=%s site=%s" % [fid, Friends.rank_label(Friends.all()[fid]) if fid != "" else "-", Friends.all()[fid].get("site") if fid != "" else "-"])
	Orgs._hideout_node.queue_free()
	Orgs._hideout_node = null
	await get_tree().process_frame
	Orgs._ensure_hideout()
	await get_tree().create_timer(0.3).timeout
	var vs = Orgs._hideout_node.find_children("*", "Villager", true, false)
	print("LONE sığınakta şimdi kaçak=%d ad=%s" % [vs.size(), vs[0].display_override if vs.size() > 0 else "-"])
	get_tree().quit()
