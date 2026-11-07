extends Node
## Asakujaku: yana koşan hedefe kaç yumruk isabet ediyor
var main: Node

class Rec extends TrainingDummy:
	var src: Node = null
	var total := 0.0
	var hits := 0
	var mv := Vector3.ZERO
	var velocity := Vector3.ZERO
	func take_hit(info: Dictionary) -> void:
		if info.get("attacker") == src:
			total += float(info.get("dmg", 0.0))
			hits += 1
	func _process(dt: float) -> void:
		hp = 1e9
		if "velocity" in self:
			set("velocity", mv)
		global_position += mv * dt
		if is_instance_valid(src):
			src.attack_cd = 99.0
			src.ranged_cd = 99.0

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var base = Missions.open_ground(Game.from_map(Vector2(Missions._spot("konoha", 500, 700)[0], Missions._spot("konoha", 500, 700)[1])), 40.0)
	pl.global_position = base + Vector3(0, 60, -80)
	pl.set_physics_process(false)
	await get_tree().create_timer(1.5).timeout
	for speed in [0.0, 5.0]:
		var a = Enemy.archetype("rogue", 0)
		a["power"] = 1.0; a["level"] = 30; a["respawn"] = false; a["jutsu"] = []
		var c = Enemy.new()
		c.setup(a)
		get_tree().current_scene.add_child(c)
		var p = base
		p.y = Game.ground_height(p.x, p.z)
		c.global_position = p
		c.target = null
		var d = Rec.new()
		d.src = c
		get_tree().current_scene.add_child(d)
		d.global_position = p + Vector3(0, 0, -10)
		d.mv = Vector3(speed, 0, 0)
		c.look_at(d.global_position, Vector3.UP, true)
		await get_tree().process_frame
		c.set_meta("gates", 8); c.set_meta("gates_until", Time.get_unix_time_from_system() + 60)
		Jutsu.execute(c, "asakujaku", d)
		await get_tree().create_timer(3.0).timeout
		print("ASK speed=%.0f hits=%d dmg=%.1f" % [speed, d.hits, d.total])
		c.queue_free(); d.queue_free()
		await get_tree().create_timer(0.5).timeout
	get_tree().quit()
