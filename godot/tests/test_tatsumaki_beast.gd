extends Node
## Hijutsu: Mushitatsumaki kuyruklu canavarın boyunda: hortum bedeni sarar (içinde kaybolmaz)
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "aburame", "element": "katon", "hair_style": "diken", "hair": Color(0.2, 0.15, 0.12), "top": Color(0.3, 0.4, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pr = Game.profile
	pr["level"] = 35
	pr["rank"] = 3
	var pl = main.player
	pl.max_chakra = 999.0
	var lair: Vector2 = TailedBeasts.LAIRS["shukaku"]
	pl.respawn(Game.from_map(lair + Vector2(0, -170)))
	await _w(1.0)
	TailedBeasts._spawn("shukaku", lair)
	var b: TailedBeast = null
	for k in 30:
		await _w(0.5)
		b = TailedBeasts.spawned.get("shukaku")
		if b != null:
			break
	await _w(1.0)
	if b == null:
		print("TB no beast")
		get_tree().quit()
		return
	pl.global_position = b.global_position + Vector3(0, 0, b.radius + 8.0)
	pl.global_position.y = Game.ground_height(pl.global_position.x, pl.global_position.z)
	b.set_physics_process(false)
	print("TB beast height=%.1f radius=%.1f scale=%.2f" % [b.height, b.radius, PathJutsu.get_pinst().body_scale(b)])
	var n0 = b.get_child_count()
	print("TB edge=%.1f tg=%s" % [JutsuEngine.edge_dist(pl, b), str(JutsuEngine._target_in_range(pl, b, 24.0))])
	Jutsu.execute(pl, "aburame_mushi_hashira", b)
	await _w(1.6)
	print("TB children %d -> %d" % [n0, b.get_child_count()])
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var away = (pl.global_position - b.global_position)
	away.y = 0
	away = away.normalized()
	cc.global_position = b.global_position + away * b.height * 2.2 + Vector3.UP * b.height * 0.6
	cc.look_at(b.global_position + Vector3.UP * b.height * 0.5)
	cc.current = true
	await _w(0.1)
	await main.shot("tatsumaki_beast")
	get_tree().quit()
