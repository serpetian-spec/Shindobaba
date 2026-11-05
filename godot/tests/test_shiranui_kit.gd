extends Node
## Başlangıç silahı: klansız silahsız (kunai dükkânda), Shiranui Senbon İğneleri silahıyla; Shiranui NPC de senbonla
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	for clan in ["none", "shiranui"]:
		main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": clan, "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
		main._start_new_game()
		await get_tree().create_timer(1.0).timeout
		var w = Gear.equipped(Game.profile, "sag")
		print("KIT clan=%s silah=%s envanter=%s look_w=%s" % [clan, w.get("id", "yok"), Game.profile["inventory"], Game.profile["look"].get("weapon_r", null)])
	var a = Enemy.archetype("rogue", 0)
	a["clan_force"] = "shiranui"
	a["level"] = 20
	var e = Enemy.new()
	e.setup(a)
	print("KIT NPC shiranui silah=%s clan=%s" % [e.look.get("weapon_r", null), e.arch.get("clan", "")])
	e.free()
	print("KIT dükkânda kunai=%s" % ("kunai" in Gear.SHOP_WEAPONS))
	get_tree().quit()
