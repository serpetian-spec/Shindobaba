extends Node
## Kıyafet / saç vitrin testi: farklı görünümleri yan yana dizer, tam boy + kafa + ayak yakın çekimleri alır.
var main: Node

const LOOKS := [
	{"gender": "m", "hair_style": "diken", "hair": Color(0.95, 0.8, 0.25), "top": Color(0.95, 0.5, 0.12), "top2": Color(0.12, 0.12, 0.15), "top_style": "ceket", "pants": Color(0.95, 0.5, 0.12), "band": Color(0.15, 0.22, 0.55), "age": "child"},
	{"gender": "m", "hair_style": "dağınık", "hair": Color(0.08, 0.08, 0.1), "top": Color(0.15, 0.2, 0.33), "top_style": "yakali", "pants": Color(0.85, 0.82, 0.75), "pants_style": "sort", "band": Color(0.15, 0.22, 0.55), "age": "teen"},
	{"gender": "f", "hair_style": "uzun", "hair": Color(0.9, 0.55, 0.7), "top": Color(0.75, 0.15, 0.15), "top_style": "tisort", "pants": Color(0.15, 0.15, 0.17), "pants_style": "sort", "band": Color(0.15, 0.22, 0.55), "age": "teen"},
	{"gender": "m", "hair_style": "kase", "hair": Color(0.08, 0.08, 0.1), "top": Color(0.15, 0.2, 0.33), "top_style": "uzun", "pants": Color(0.15, 0.2, 0.33), "vest": Color(0.38, 0.48, 0.28), "band": Color(0.15, 0.22, 0.55), "age": "adult"},
	{"gender": "f", "hair_style": "atkuyruğu", "hair": Color(0.95, 0.85, 0.4), "top": Color(0.35, 0.25, 0.45), "top_style": "uzun", "pants": Color(0.15, 0.15, 0.17), "band": Color(0.15, 0.22, 0.55), "band_style": "neck", "age": "young"},
	{"gender": "m", "hair_style": "kısa", "hair": Color(0.6, 0.6, 0.62), "top": Color(0.15, 0.2, 0.33), "top_style": "uzun", "pants": Color(0.15, 0.2, 0.33), "vest": Color(0.38, 0.48, 0.28), "band": Color(0.15, 0.22, 0.55), "age": "adult"},
]


func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	main.world.env.time_of_day = 0.42
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"] + 20, v["y"] - 120))
	var models = []
	for i in LOOKS.size():
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup(LOOKS[i])
		var p = base + Vector3((i - 2.5) * 1.1, 0, 0)
		p.y = Game.terrain_height(p.x, p.z)
		m.global_position = p
		m.rotation.y = 0.0
		m.play("idle")
		models.append(m)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	main.world.env.attach_post(cam)
	cam.global_position = base + Vector3(0, 1.2, -4.6)
	cam.look_at(base + Vector3(0, 0.85, 0))
	await get_tree().create_timer(2.5).timeout
	await main.shot("o1_dizi")
	for i in [0, 3]:
		var m: Node3D = models[i]
		var hp = m.global_position + Vector3(0, 1.45 * m.age_scale, 0)
		cam.global_position = hp + Vector3(0.35, 0.1, -0.9)
		cam.look_at(hp)
		await get_tree().create_timer(0.4).timeout
		await main.shot("o2_kafa_%d" % i)
		cam.global_position = hp + Vector3(0.0, 0.0, 0.9)
		cam.look_at(hp)
		await get_tree().create_timer(0.3).timeout
		await main.shot("o3_ense_%d" % i)
		var fp = m.global_position + Vector3(0, 0.25, 0)
		cam.global_position = fp + Vector3(0.5, 0.25, -1.0)
		cam.look_at(fp)
		await get_tree().create_timer(0.3).timeout
		await main.shot("o4_ayak_%d" % i)
	for m in models:
		m.rotation.y = PI
	cam.global_position = base + Vector3(0, 1.2, -4.6)
	cam.look_at(base + Vector3(0, 0.85, 0))
	await get_tree().create_timer(0.4).timeout
	await main.shot("o5_arka")
	get_tree().quit()
