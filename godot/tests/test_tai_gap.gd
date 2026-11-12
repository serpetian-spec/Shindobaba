extends Node
## Temel taijutsu kombosu: her vuruşta oyuncu-hedef aralığı (gövde kenarından) ve hasar
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await _w(3.0)
	Hud.close_dialog()
	Hud.show_game_hud(false)
	var pl: Player = main.player
	Game.profile["rank"] = 3
	Aging.set_years(Game.profile, 24.0)
	pl.rebuild_model()
	pl.global_position = Missions.open_ground(pl.global_position + Vector3(0, 0, 30), 30.0) + Vector3.UP * 0.2
	await _w(1.0)
	Game.profile["weapon_drawn"] = false
	var b0 = pl.global_position
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	var fw: Vector3 = pl.cam_forward()
	fw.y = 0
	fw = fw.normalized()
	e.global_position = b0 + fw * 2.4
	e.max_hp = 1e9; e.hp = 1e9
	e.set_physics_process(false)
	await _w(0.6)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.fov = 40.0
	for g0 in [0.5, 1.0, 1.5, 2.0, 2.6, 3.5]:
		while pl.combat.action != "":
			await get_tree().process_frame
		await _w(0.3)
		e.global_position = pl.global_position + fw * (g0 + e.radius + pl.radius)
		pl.combat.face_to(e)
		var hp0 = e.hp
		pl.combat.step = 4
		pl.combat.combo_reset = 1.0
		pl.combat.attack()
		var c = pl.combat._combo(pl.combat.step)
		var mn = 99.0
		var gh = -1.0
		var e0 = e.global_position
		print("TGK keys=%s id=%s dur=%.2f" % [str(c.has("keys")), str(c.get("keyed_id", "")), float(c["dur"])])
		var fr = 0
		while pl.combat.action == "attack":
			fr += 1
			if false:
				var ps2: Skeleton3D = pl.model.skel
				var hb2 = ps2.find_bone("Hips")
				print("TGT t=%.2f kalca=%.2f yerel=%s kapsul=%.2f" % [pl.combat.t, (ps2.global_transform * ps2.get_bone_global_pose(hb2).origin - pl.global_position).dot(fw), str(ps2.get_bone_pose_position(hb2).snapped(Vector3(0.01, 0.01, 0.01))), e0.distance_to(pl.global_position) - e.radius - pl.radius])
			var gap = e0.distance_to(pl.global_position) - e.radius - pl.radius
			mn = minf(mn, gap)
			if gh < 0.0 and pl.combat.t >= float(c["hit"]):
				gh = gap
				var mid = (e0 + pl.global_position) * 0.5
				cc.global_position = mid + fw.cross(Vector3.UP) * 4.0 + Vector3.UP * 1.3
				cc.look_at(mid + Vector3.UP * 1.0)
				cc.current = true
				var ps: Skeleton3D = pl.model.skel
				var es: Skeleton3D = e.model.skel
				var ph = (ps.global_transform * ps.get_bone_global_pose(ps.find_bone("Hips")).origin - pl.global_position).dot(fw)
				var phd = (ps.global_transform * ps.get_bone_global_pose(ps.find_bone("Head")).origin - pl.global_position).dot(fw)
				var eh = (es.global_transform * es.get_bone_global_pose(es.find_bone("Hips")).origin - e0).dot(fw)
				print("TGB start=%.1f oyuncu kalca=%.2f bas=%.2f model=%.2f | dusman kalca=%.2f govde=%.2f" % [g0, ph, phd, (pl.model.global_position - pl.global_position).dot(fw), eh, (e.global_position - e0).dot(fw)])
				if g0 in [0.5, 2.6]:
					await main.shot("tai_f%d" % int(g0 * 10))
			await get_tree().physics_frame
		print("TG step=%d anim=%s start=%.1f gap_hit=%.2f gap_min=%.2f (eski yere gore) dmg=%.1f" % [pl.combat.step, str(c.get("anim")), g0, gh, mn, hp0 - e.hp])
	get_tree().quit()
