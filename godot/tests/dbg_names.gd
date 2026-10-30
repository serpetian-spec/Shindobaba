extends Node
## Tanışınca isim etiketi, sabit yerde kimliğin korunması, düelloda görünüşün (cinsiyet) korunması
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["level"] = 20
	# 1) kapı nöbetçisi (sabit yer aktörü gibi): tanış -> etiket, kimlik + yer anahtarı
	var life = main.actors.get_node("VillageLife")
	var at = pl.global_position + pl.face_dir() * 3.0
	var g = life._villager("guard", at, [], {}, Friends.site_key(at), "")
	await get_tree().create_timer(0.3).timeout
	print("NAME before=", g.display)
	Friends._meet(g)
	Menus.clear()
	var fid = String(g.get_meta("friend_id"))
	print("NAME after=", g.display, " tag=", g.name_tag.text if g.name_tag else "YOK", " site=", Friends.all()[fid].get("site", ""), " title=", Friends.all()[fid]["title"])
	# yeniden kurulma: aynı yerde yine o mu
	var look_g = String(g.look.get("gender"))
	g.queue_free()
	await get_tree().process_frame
	var fid2 = Friends.at_site(Friends.site_key(at))
	var f: Dictionary = Friends.all()[fid2]
	var g2 = life._villager("guard", at, [], {"look_extra": Friends.look_of(f), "display_override": String(f["name"])}, Friends.site_key(at), fid2)
	await get_tree().create_timer(0.3).timeout
	print("NAME respawn=", g2.display, " same=", fid2 == fid, " gender ", look_g, "->", g2.look.get("gender"), " tag=", g2.name_tag.text if g2.name_tag else "YOK")
	var cam = Camera3D.new()
	main.add_child(cam)
	pl.set_process(false)
	pl.set_physics_process(false)
	pl.cam.current = false
	cam.current = true
	main.world.env.attach_post(cam)
	cam.global_position = g2.global_position + Vector3(0, 1.7, 0) - pl.face_dir() * -2.8 + Vector3(0, 0, 0)
	cam.global_position = pl.global_position + Vector3(0, 1.8, 0)
	cam.look_at(g2.global_position + Vector3(0, 1.6, 0))
	await get_tree().create_timer(0.4).timeout
	await main.shot("name_tag")
	# 2) kadın klan üyesiyle düello: rakip kadın kalmalı
	var r = ClanResident.new()
	r.clan = "hyuga"
	r.vid = "konoha"
	r.given = "Hyūga Mei"
	r.display_override = r.given
	r.role = "nurse"
	r.look_extra = ClanWorld.clan_look("hyuga", "chunin", "konoha", true, "adult")
	main.actors.add_child(r)
	r.global_position = pl.global_position + Vector3(4, 0, 0)
	await get_tree().create_timer(0.3).timeout
	r._duel()
	await get_tree().create_timer(0.3).timeout
	for e in get_tree().get_nodes_in_group("fighters"):
		if e is Enemy and String(e.display_name).contains("Mei"):
			print("DUEL resident=", r.look.get("gender"), " enemy=", e.look.get("gender"), " hair_same=", e.look.get("hair") == r.look.get("hair"))
	get_tree().quit()
