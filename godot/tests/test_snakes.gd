extends Node
## Yılan çağrıları testi: sürü, dev yılan, Manda benzeri yılan hükümdarı. Yandan kamera, bekleme / hareket / saldırı kareleri.
## Kullanım: --test=res://tests/test_snakes.gd --shots=<dizin> [--tag=after]

var main: Node
var pl: Player
var tag := "after"


func _ready() -> void:
	await get_tree().process_frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather_t = 9999.0
	Game.world.env.region_weather = "açık"
	pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(4.0).timeout
	var base = pl.global_position
	for tier in [0, 1, 2]:
		await _snake(tier, base)
	print("SNAKES BITTI")
	get_tree().quit()


func _snake(tier: int, base: Vector3) -> void:
	var sd: Dictionary = Contracts.DEFS["yılan"]["tiers"][tier]
	var s = Summon.new()
	s.contract = "yılan"
	s.tier = tier
	s.def = sd
	s.owner_f = pl
	s.team = pl.team
	get_tree().current_scene.add_child(s)
	var L = maxf(float(sd.get("len", 0.0)), float(sd["h"]) * 3.0)
	var p = base + Vector3.FORWARD * maxf(6.0, L * 0.6)
	p.y = Game.ground_height(p.x, p.z)
	s.global_position = p
	s.facing = PI * 0.5
	s.life = 999.0
	pl.global_position = p + Vector3(L * 0.2, 0, L * 0.35)
	pl.reset_physics_interpolation()
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.global_position = p + Vector3(-L * 0.3, maxf(2.0, float(sd["h"]) * 2.2), L * 0.9 + 3.0)
	cam.look_at(p + Vector3.UP * float(sd["h"]) * 0.5)
	cam.far = 3000.0
	cam.current = true
	await get_tree().create_timer(1.2).timeout
	await main.shot("sn_%s_%d_0bekle" % [tag, tier])
	await get_tree().create_timer(0.6).timeout
	await main.shot("sn_%s_%d_0bekle_b" % [tag, tier])
	# hedef kukla: yılan saldırsın
	var e = Enemy.new()
	var a = Enemy.archetype("bandit", 0)
	a["hp"] = 99999.0
	a["respawn"] = false
	e.setup(a)
	get_tree().current_scene.add_child(e)
	var ep = p + Vector3(-L * 0.6 - 3.0, 0, 0)
	ep.y = Game.ground_height(ep.x, ep.z)
	e.global_position = ep
	e.home = ep
	for i in 6:
		await get_tree().create_timer(0.5).timeout
		if i in [1, 3, 5]:
			await main.shot("sn_%s_%d_1hareket_%d" % [tag, tier, i])
	e.queue_free()
	cam.queue_free()
	s.queue_free()
	await get_tree().create_timer(0.4).timeout
