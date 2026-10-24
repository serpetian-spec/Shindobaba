extends Node
## Her sözleşmenin her kademesi: çağrılır çağrılmaz imza tekniğini kullanıyor mu (yakında düşman) — hata yok mu, kısa çekim
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	pl.max_hp = 999999.0
	pl.hp = pl.max_hp
	Game.profile["level"] = 60
	Game.profile["rank"] = 3
	for id in Contracts.DEFS:
		for tier in Contracts.DEFS[id]["tiers"]:
			var a = Enemy.archetype("bandit", 0)
			a["respawn"] = false
			a["hp"] = 99999.0
			var e = Enemy.new()
			e.setup(a)
			main.add_child(e)
			var p = pl.global_position + pl.face_dir() * 12.0
			p.y = Game.ground_height(p.x, p.z)
			e.global_position = p
			e.home = p
			e.set_physics_process(false)
			var s = Summon.new()
			s.contract = id
			s.tier = tier
			s.def = Contracts.DEFS[id]["tiers"][tier]
			s.owner_f = pl
			s.team = pl.team
			main.add_child(s)
			s.global_position = pl.global_position + pl.face_dir() * 3.0
			var cd0 = s.special_cd
			var hp0 = e.hp
			var st0 = e.has_status("stun") or e.has_status("bind") or e.has_status("slow")
			var shoot = s.def["model"] in ["toad_mid", "snake_swarm", "crow_flock", "spider", "turtle_giant", "dog_pack"]
			if shoot:
				var f = pl.face_dir()
				var cam = Camera3D.new()
				main.add_child(cam)
				var sz = maxf(3.0, float(s.def["h"]))
				cam.global_position = pl.global_position + f * 7.0 + f.cross(Vector3.UP) * (6.0 + sz) + Vector3.UP * (2.5 + sz * 0.6)
				cam.look_at(pl.global_position + f * 8.0 + Vector3.UP * 1.0)
				cam.current = true
				await get_tree().create_timer(1.15).timeout
				await main.shot("skill_" + s.def["model"])
				cam.queue_free()
				await get_tree().create_timer(1.05).timeout
			else:
				await get_tree().create_timer(2.2).timeout
			var used = s.special_cd > cd0 or s.cd > 2.5
			print("SKILL %s t%d %s used=%s dmg=%d status=%s" % [id, tier, s.def["model"], used, int(hp0 - e.hp), e.has_status("stun") or e.has_status("bind") or e.has_status("slow")])
			if is_instance_valid(s):
				s.queue_free()
			e.queue_free()
			for x in get_tree().get_nodes_in_group("summons"):
				x.queue_free()
			Game.profile["equip"].erase("sag")
			await get_tree().create_timer(0.3).timeout
	get_tree().quit()
