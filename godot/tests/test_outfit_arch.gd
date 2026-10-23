extends Node
## Kıyafet arketipleri vitrini: her sayfada 6 NPC, önden ve arkadan
var main: Node
const PAGES := [
	[["genin", "konoha"], ["genin", "konoha"], ["chunin", "konoha"], ["jonin", "konoha"], ["anbu", "konoha"], ["kok", "konoha"]],
	[["rogue", "kiri"], ["rogue", "iwa"], ["rogue", "konoha"], ["bandit", ""], ["bandit", ""], ["bandit", ""]],
	[["samurai", ""], ["samurai", ""], ["akatsuki", "ame"], ["org", "oto"], ["monk", ""], ["hunter", "kiri"]],
	[["chunin", "suna"], ["chunin", "kiri"], ["chunin", "kumo"], ["chunin", "iwa"], ["chunin", "oto"], ["chunin", "ame"]],
	[["civ", ""], ["civ", ""], ["civ", ""], ["merchant", ""], ["farmer", ""], ["worker", ""]],
	[["noble", ""], ["medic", "konoha"], ["elder", ""], ["traveler", ""], ["sennin", "konoha"], ["kid", ""]],
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
	var hairs = CharacterModel.HAIR_STYLES.keys()
	for page in PAGES.size():
		var models = []
		for i in PAGES[page].size():
			var a = PAGES[page][i]
			seed(page * 100 + i * 7 + 3)
			var lk = Outfits.roll(a[0], a[1])
			lk["gender"] = "f" if i % 3 == 1 else "m"
			lk["hair_style"] = hairs[(page * 6 + i) % hairs.size()]
			lk["hair"] = [Color(0.1, 0.08, 0.06), Color(0.35, 0.22, 0.12), Color(0.75, 0.45, 0.2), Color(0.6, 0.6, 0.62)][i % 4]
			if a[0] in ["kid", "genin"]:
				lk["age"] = "teen" if a[0] == "genin" else "child"
			var m = CharacterModel.new()
			main.add_child(m)
			m.setup(lk)
			if lk.has("age"):
				m.apply_age(lk["age"])
			var p = base + Vector3((i - 2.5) * 0.95, 0, 0)
			p.y = Game.terrain_height(p.x, p.z)
			m.global_position = p
			m.play("idle")
			models.append(m)
		for side in [0, 1]:
			for m in models:
				m.rotation.y = (PI if side == 1 else 0.0) + 0.25
			cam.global_position = base + Vector3(0, 1.1, 6.4)
			cam.look_at(base + Vector3(0, 0.95, 0))
			await get_tree().create_timer(1.2).timeout
			await main.shot("of_%d_%s" % [page, "arka" if side == 0 else "on"])
		for m in models:
			m.queue_free()
	get_tree().quit()
