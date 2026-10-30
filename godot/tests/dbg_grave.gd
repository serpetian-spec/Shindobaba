extends Node
## Mezarlık + cenaze töreni + listeden düşme
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var id = Friends._make_friend("Nara Shun", "nara", ClanWorld.clan_look("nara", "chunin", "konoha", false), 70, "Nara klanı")
	var f: Dictionary = Friends.all()[id]
	f["family"] = [{"rel": "Annesi", "name": "Nara Yoshino", "alive": true}, {"rel": "Babası", "name": "Nara Kenta", "alive": true}]
	f["status"] = "öldü"
	await get_tree().create_timer(1.5).timeout
	for b in Hud.dialog_layer.find_children("*", "Button", true, false):
		if String(b.text).begins_with("Katılacağım"):
			b.pressed.emit()
	Menus.clear()
	print("GRAVE died_t=", f.has("died_t"), " waypoint=", Game.profile.get("waypoint"))
	f["funeral_t"] = 0.0
	var gp = Graveyard.pos_of("konoha")
	var cam = get_viewport().get_camera_3d()
	var cf = -cam.global_transform.basis.z
	cf.y = 0
	cf = cf.normalized()
	var p0 = gp - cf * 16.0
	p0.y = Game.ground_height(p0.x, p0.z) + 0.3
	pl.global_position = p0
	await get_tree().create_timer(3.0).timeout
	await main.shot("grave_empty")
	pl.global_position = gp + Vector3(0, 0.5, 7)
	await get_tree().create_timer(2.0).timeout
	print("GRAVE funeral=", Friends.inst().funeral.get("id", ""))
	var pf = gp + Vector3(0, 0, 12.0)
	pf.y = Game.ground_height(pf.x, pf.z) + 0.3
	pl.global_position = pf
	pl.yaw = 0.0
	Menus.clear()
	await get_tree().create_timer(5.5).timeout
	await main.shot("grave_funeral")
	await get_tree().create_timer(20.0).timeout
	for b in Hud.dialog_layer.find_children("*", "Button", true, false):
		if String(b.text).begins_with("Tütsü"):
			b.pressed.emit()
	Menus.clear()
	await get_tree().create_timer(2.5).timeout
	print("GRAVE buried=", f.get("buried"), " listed=", Friends.listed().has(id), " log=", f["log"].slice(-2))
	var p1 = gp + Vector3(-7.5, 0, 9.5)
	p1.y = Game.ground_height(p1.x, p1.z) + 0.3
	pl.global_position = p1
	pl.yaw = 0.0
	await get_tree().create_timer(2.5).timeout
	await main.shot("grave_stone")
	get_tree().quit()
