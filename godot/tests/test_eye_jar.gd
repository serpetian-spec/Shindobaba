extends Node
## Göz kavanozu: kayıttan gelen float uid'lerle takılı göz kavanozda görünmemeli, yok etme, EMS kanon şartı, klan tekniği kopyası
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pr = Game.profile
	var a = Gear.grant(pr, "goz_mangekyo", "sag_goz", null, null, {"origin": "nakil"})
	Gear.grant(pr, "goz_byakugan", "sol_goz", null, null, {"origin": "nakil"})
	var j = Gear.grant(pr, "goz_mangekyo", "", null, null, {"origin": "nakil"})
	# JSON kaydı gibi: tüm uid'ler float
	for s in pr["equip"]:
		pr["equip"][s] = float(pr["equip"][s])
	for g in pr["gear"]:
		g["uid"] = float(g["uid"])
	var jar = []
	for g in pr["gear"]:
		if Gear.is_eye(g["id"]) and not Gear.is_equipped(pr, g):
			jar.append("%s#%d" % [g["id"], int(g["uid"])])
	print("JAR ", jar, " opts=", EyeSurgery.options("medic").size())
	Eyes.transplant(pr, j, "sag_goz")
	print("AFTER nakil MS->nakil MS sag=", Gear.equipped(pr, "sag_goz")["id"])
	var before = pr["gear"].size()
	Menus._eye_destroy(pr, int(Gear.equipped(pr, "sol_goz")["uid"]))
	print("DESTROY gear ", before, "->", pr["gear"].size(), " sol_empty=", Gear.equipped(pr, "sol_goz").is_empty())
	print("COPY teshi: ", Progress.can_learn("bone_bullets"))
	var ey = main.player.combat.modes.eyes
	var got = []
	for k in 6:
		Gear.grant(pr, "goz_sharingan", "sag_goz", null, null, {"lvl": 3, "origin": "dogustan"})
		Gear.grant(pr, "goz_sharingan", "sol_goz", null, null, {"lvl": 3, "origin": "dogustan"})
		ey._awaken_mangekyo()
		got.append("%s/%s" % [Gear.equipped(pr, "sag_goz").get("ms_style"), Gear.equipped(pr, "sol_goz").get("ms_style")])
	print("MS STYLES ", got)
	get_tree().quit()
