extends Node
## Sıradan düşman kaynakları dünya nüfusuna bağlı mı: kaçak/ses/köy ninjası kalıpları gerçek kişiye dönüşür, ölünce kişi de ölür
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1),
		"top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var wn = main.actors.get_node("WorldPeople")
	for i in 120:
		wn.world_tick()   # birkaç kaçak oluşsun
	var made = []
	var specs = [["rogue", 40], ["rogue", 90], ["rogue", 140], ["oto", 50], ["konoha", 35], ["konoha", 80], ["kumo", 60], ["suna", 100]]
	for sp in specs:
		var a: Dictionary
		if sp[0] in ["konoha", "kumo", "suna"]:
			a = Orgs._village_arch(String(sp[0]), 0, "chunin")
		else:
			a = Enemy.archetype(String(sp[0]), 0)
		Stats.npc_ninja(a, int(sp[1]))
		var e = Enemy.new()
		e.setup(a)
		get_tree().current_scene.add_child(e)
		e.global_position = main.player.global_position + Vector3(randf_range(-30, 30), 0, -40)
		e.set_physics_process(false)
		made.append(e)
		print("WE %s Güç%d -> %s | kişi=%s klan=%s göz=%s jutsu=%s" % [sp[0], sp[1], e.display_name, e.arch.get("world_person", "-"), e.arch.get("clan", ""), e.get_meta("eyes", {}), e.arch.get("jutsu")])
	await get_tree().create_timer(0.5).timeout
	for e in made:
		if e.arch.has("world_person"):
			var pid = String(e.arch["world_person"])
			e.die({"attacker": main.player, "dmg": 9999})
			var p = WorldPeople.get_p(pid)
			print("WE oldurme -> %s durum=%s son=%s" % [p["name"], p["status"], p["log"].back()])
			break
	print("WE BITTI")
	get_tree().quit()
