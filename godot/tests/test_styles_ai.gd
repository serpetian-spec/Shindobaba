extends Node
## Düşman AI aynı dövüş tarzını kullanır: klanlı silahsız düşman -> klan tarzı anahtar kombosu
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.25, 0.2, 0.15), "top": Color(0.85, 0.85, 0.8), "pants": Color(0.2, 0.2, 0.25), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.0).timeout
	for cl in ["jugo", "hozuki", "aburame", "yuki", "sabaku", "uzumaki", "yotsuki", "kamizuru"]:
		var e := Enemy.new()
		e.setup(Enemy.archetype(cl, 2))
		e.look["weapon_r"] = null
		e.arch["clan"] = cl
		main.actors.add_child(e)
		e.global_position = main.player.global_position + Vector3(0, 0, -6)
		await get_tree().process_frame
		print("AI %s clan=%s keyed=%s" % [cl, str(e.arch.get("clan", "")), e._keyed_id()])
		e.queue_free()
	# klansız kekkei genkai: elementi / jutsusu o doğadan olan silahsız düşman aynı kan soyu tarzıyla dövüşür
	for nat in ["ranton", "yoton", "bakuton", "shakuton", "shoton", "jinton", "mokuton"]:
		var e2 := Enemy.new()
		e2.setup(Enemy.archetype("rogue", 2))
		e2.look["weapon_r"] = null
		e2.arch["clan"] = "none"
		e2.element = nat
		main.actors.add_child(e2)
		e2.global_position = main.player.global_position + Vector3(0, 0, -6)
		await get_tree().process_frame
		print("AI kg %s keyed=%s stop=%s" % [nat, e2._keyed_id(), str(FightingStyles.stop_dist(e2._keyed_id()))])
		e2.queue_free()
	get_tree().quit()
