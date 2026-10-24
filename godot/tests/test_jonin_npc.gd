extends Node
## Jōnin terfi görevi: Yamagata nerede doğuyor, konuşulabiliyor mu
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Hud.show_game_hud(false)
	var m = Exams._jonin_mission()
	Missions.accept(m)
	await get_tree().create_timer(0.5).timeout
	Missions._next_step()
	await get_tree().create_timer(0.8).timeout
	var s = Missions._cur()
	var npc = Missions.npcs.get("jonin2")
	print("STEP %s npc=%s" % [s.get("text", ""), npc])
	if npc:
		var p = npc.global_position
		print("NPCPOS %s ground=%s terrain=%s" % [p, Game.ground_height(p.x, p.z), Game.terrain_height(p.x, p.z)])
		main.player.global_position = p + Vector3(2, 0.5, 2)
		await get_tree().create_timer(1.0).timeout
		var cam = main.player.cam
		cam.global_position = p + Vector3(6, 3, 6)
		cam.look_at(p + Vector3.UP)
		await main.shot("jonin2")
		var it = Interact.nearest(main.player.global_position) if Interact.has_method("nearest") else null
		print("NEAREST %s" % [it])
		var qn = Missions.talk_target_near(main.player.global_position, 4.0)
		print("TALK_TARGET %s" % qn)
		var ev = InputEventAction.new()
		ev.action = "interact"
		ev.pressed = true
		main._route(ev)
		await get_tree().create_timer(0.5).timeout
		print("DIALOG_OPEN %s" % Game.ui_open)
	get_tree().quit()
