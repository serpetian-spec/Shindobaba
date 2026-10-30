extends Node
## Diyaloglar: dost sohbetinde senin cevapların, köylü sohbeti, görev konuşmasında cevaplar/pazarlık
var main: Node


func _btns() -> Array:
	return Hud.dialog_layer.find_children("*", "Button", true, false).map(func(b): return String(b.text))


func _press(prefix: String) -> bool:
	for b in Hud.dialog_layer.find_children("*", "Button", true, false):
		if String(b.text).begins_with(prefix):
			b.pressed.emit()
			return true
	return false


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = ClanResident.new()
	v.clan = "nara"
	v.vid = "konoha"
	v.given = "Nara Emi"
	v.display_override = v.given
	v.role = "nurse"
	v.look_extra = ClanWorld.clan_look("nara", "chunin", "konoha", true, "adult")
	main.actors.add_child(v)
	v.global_position = pl.global_position + pl.face_dir() * 2.0
	await get_tree().create_timer(0.5).timeout
	Friends._meet(v)
	Menus.clear()
	var id = String(v.get_meta("friend_id"))
	var f: Dictionary = Friends.all()[id]
	Friends._ensure_persona(f)
	f["trait"] = "neşeli"
	Friends._topic_dialog(id)
	await get_tree().process_frame
	print("DLG topics=", _btns())
	_press("Şaka yap")
	await get_tree().process_frame
	print("DLG replies=", _btns())
	var b0 = int(f["bond"])
	await main.shot("dlg_reply")
	_press("Kafasındaki")
	await get_tree().process_frame
	print("DLG bond ", b0, "->", f["bond"], " react=", _btns())
	Menus.clear()
	# köylü
	var vg = Villager.new()
	vg.role = "walker"
	main.actors.add_child(vg)
	vg.global_position = pl.global_position + Vector3(3, 0, 0)
	await get_tree().create_timer(0.4).timeout
	vg.talk()
	await get_tree().process_frame
	print("DLG villager=", _btns())
	_press("Köyde neler")
	await get_tree().process_frame
	print("DLG rumor=", _btns())
	Menus.clear()
	# görev konuşması
	var spot = Missions._spot("konoha", 100, 200)
	var m = Missions._q_weeds("konoha")
	m["rank"] = "D"
	m["village"] = "konoha"
	m["type"] = "quest"
	Missions.accept(m)
	await get_tree().create_timer(1.0).timeout
	var npc = null
	for n in get_tree().get_nodes_in_group("talkers"):
		if n is QuestNPC:
			npc = n
	Missions.on_quest_talk(npc)
	await get_tree().process_frame
	print("DLG quest=", _btns())
	await main.shot("dlg_quest")
	_press("Ödülü")
	await get_tree().process_frame
	print("DLG haggle ok=", Missions.active()["flags"].get("haggle_ok"), " btns=", _btns())
	Menus.clear()
	get_tree().quit()
