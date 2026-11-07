extends Node
## NPC -> düşman dönüşümü: model yeniden kurulmaz, devralınır (köy takımı saldırısı + köylüye saldırı)
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	pl.max_hp = 1e9
	pl.hp = 1e9
	var at = main.get_node_or_null("AmbientTeams")
	if at == null:
		at = get_tree().current_scene.find_child("AmbientTeams", true, false)
	at._spawn(pl.global_position)
	await _w(1.5)
	print("ADOPT teams=%d" % at.teams.size())
	if at.teams.size() > 0:
		var tm = at.teams[0]
		var models_before = []
		for n in tm["nodes"]:
			if is_instance_valid(n):
				models_before.append(n.model)
				n.global_position = pl.global_position + Vector3(randf_range(-4, 4), 0, 6)
		var t0 = Time.get_ticks_usec()
		at._team_attack(tm, false)
		var dt = (Time.get_ticks_usec() - t0) / 1000.0
		await get_tree().process_frame
		var ens = get_tree().get_nodes_in_group("fighters").filter(func(f): return f is Enemy and not f.dead)
		var reused = 0
		for e in ens:
			if e.model in models_before:
				reused += 1
		print("ADOPT team_attack %.1fms enemies=%d reused_models=%d/%d" % [dt, ens.size(), reused, models_before.size()])
		await _w(2.0)
		var ok = 0
		for e in ens:
			if is_instance_valid(e) and e.model and e.model.is_inside_tree() and e.model.visible and e.model.get_parent() == e:
				ok += 1
		print("ADOPT after2s valid_models=%d state0=%s anim0=%s" % [ok, ens[0].state if ens.size() > 0 else "-", ens[0].model.current if ens.size() > 0 else "-"])
		var cc = Camera3D.new()
		get_tree().current_scene.add_child(cc)
		cc.global_position = pl.global_position + Vector3(0, 3, -6)
		cc.look_at(pl.global_position + Vector3(0, 1, 4))
		cc.current = true
		await _w(0.2)
		await main.shot("adopt")
	get_tree().quit()
