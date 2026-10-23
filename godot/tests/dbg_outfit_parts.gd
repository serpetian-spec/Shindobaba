extends Node
## Tek tek kıyafet parçası ayıklama vitrini
var main: Node
const LOOKS := [
	{"pants_style": "bol", "pants": Color(0.8, 0.7, 0.5)},
	{"outer_style": "panco", "outer": Color(0.45, 0.35, 0.25), "outer_pattern": 1},
	{"vest": Color(0.35, 0.24, 0.15), "vest_style": 9},
	{"face_style": "pece", "facegear": Color(0.82, 0.74, 0.58), "head_style": "sarik", "headgear": Color(0.85, 0.76, 0.58)},
	{"head_style": "kapuson", "headgear": Color(0.1, 0.1, 0.12), "face_style": "anbu_tilki", "facegear": Color.WHITE},
	{"back_item": "bel_parsomen", "backc": Color(0.88, 0.82, 0.65), "outer_style": "kesa", "outer": Color(0.6, 0.18, 0.1), "top_style": "gi"},
]


func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	main.world.env.time_of_day = 0.42
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"] + 20, v["y"] - 300))
	base.y = Game.terrain_height(base.x, base.z)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 50
	main.world.env.attach_post(cam)
	var models = []
	for i in LOOKS.size():
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup(LOOKS[i])
		var p = base + Vector3((i - 2.5) * 0.95, 0, 0)
		p.y = Game.terrain_height(p.x, p.z)
		m.global_position = p
		m.rotation.y = PI + 0.25
		m.play("idle")
		models.append(m)
	cam.global_position = base + Vector3(0, 1.1, 6.4)
	cam.look_at(base + Vector3(0, 0.95, 0))
	await get_tree().create_timer(1.2).timeout
	await main.shot("dp_on")
	for m in models:
		m.rotation.y = 0.25
	await get_tree().create_timer(0.5).timeout
	await main.shot("dp_arka")
	for m in models:
		m.rotation.y = PI + 0.4
	cam.global_position = base + Vector3(0, 1.55, 3.2)
	cam.look_at(base + Vector3(0, 1.45, 0))
	await get_tree().create_timer(0.5).timeout
	await main.shot("dp_kafa")
	get_tree().quit()
