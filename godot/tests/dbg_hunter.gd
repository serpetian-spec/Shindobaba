extends Node
## İzci olayı + takımda Nara dostu: dost izciye saldırıyor mu, neden
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["level"] = 30
	Game.profile["rank"] = 2
	var spot = Missions._spot("konoha", 400, 600)
	pl.global_position = Game.from_map(Vector2(spot[0], spot[1])) + Vector3(0, 2, 0)
	await get_tree().create_timer(2.0).timeout
	var id = Friends._make_friend("Nara Shun", "nara", ClanWorld.clan_look("nara", "chunin", "konoha", false), 80, "Nara klanı")
	Friends.all()[id]["rank"] = 1
	Friends.set_party(id, true)
	await get_tree().create_timer(2.0).timeout
	Encounters.start("hunter")
	await get_tree().create_timer(1.0).timeout
	var h = Encounters.cur.get("npc")
	print("HUNT started kind=", Encounters.cur.get("kind"), " npc=", h, " rogue=", Encounters.cur.get("rogue_clan"))
	pl.global_position = h.global_position + Vector3(2, 0.5, 0)
	await get_tree().create_timer(1.0).timeout
	h.on_talk.call(h)
	await get_tree().process_frame
	# "Yardım et"
	for o in Hud._dlg_opts if "_dlg_opts" in Hud else []:
		pass
	var ff = Friends.inst()
	var comp = ff.members[0]["node"]
	var hp0 = h.hp if "hp" in h else -1
	# düğmeye bas: Hud diyalog seçeneklerini bul
	var btns = Hud.dialog_layer.find_children("*", "Button", true, false)
	for b in btns:
		if String(b.text).begins_with("Yardım"):
			b.pressed.emit()
	Menus.clear()
	for k in 30:
		await get_tree().create_timer(1.0).timeout
		var foes = Encounters.cur.get("foes", [])
		var fo = foes[0] if not foes.is_empty() and is_instance_valid(foes[0]) else null
		print("HUNT t=", k, " npc team=", h.team if is_instance_valid(h) else "X", " npc hp=", int(h.hp) if is_instance_valid(h) else -1,
			" comp team=", comp.team if is_instance_valid(comp) else "X", " comp target=", (comp.target.name if comp.target else "null") if is_instance_valid(comp) else "X",
			" foe team=", fo.team if fo else "X", " foe target=", (fo.target.name if fo and fo.target else "null"))
	get_tree().quit()
