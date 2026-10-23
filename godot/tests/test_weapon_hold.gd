extends Node
## Silah tutuşu + kın: farklı silahlar, yaşlar ve hareket anlarında el yakın çekimi.
## WPN_IDS: virgüllü silah listesi; WPN_STATES: idle,run,slash,air,seal,sheathed,draw
var main: Node

const STATES := ["idle", "run", "slash", "air", "seal", "sheathed", "draw"]


func _look(id: String, age: String) -> Dictionary:
	var pr = {"rank": 3, "gear": [], "equip": {}, "look": {"gender": "m", "age": age, "hair_style": "kısa", "hair": Color(0.2, 0.15, 0.1), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8), "village": "konoha"}}
	for g in ["uzun_gomlek", "ninja_pant", "sandalet", "chunin_yelek"]:
		Gear.grant(pr, g, Gear.item(g)["slot"])
	var it = Gear.item(id)
	var slot: String = it["slot"]
	if slot == "el":
		slot = "sag"
	Gear.grant(pr, id, slot)
	if String(it.get("weapon", {}).get("style", "")) == "dual" or id == "kiba":
		Gear.grant(pr, id, "sol")
	Gear.apply_look(pr)
	return pr["look"]


func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	main.world.env.time_of_day = 0.42
	main.world.env.region_weather = "açık"
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"] + 20, v["y"] - 120))
	base.y = Game.terrain_height(base.x, base.z) + 80.0  # gökyüzü fonu: binalar kadrajı kapatmasın
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 40
	main.world.env.attach_post(cam)
	var ids = ["kunai", "katana", "samehada", "bo", "kubikiribocho", "tanto", "ikiz_hancer", "yelpaze"]
	if OS.get_environment("WPN_IDS") != "":
		ids = OS.get_environment("WPN_IDS").split(",")
	var states = STATES
	if OS.get_environment("WPN_STATES") != "":
		states = OS.get_environment("WPN_STATES").split(",")
	var ages = ["adult", "child"]
	if OS.get_environment("WPN_AGES") != "":
		ages = OS.get_environment("WPN_AGES").split(",")
	await get_tree().create_timer(1.0).timeout
	if OS.get_environment("WPN_AX") != "":
		var a = OS.get_environment("WPN_AX").split(",")
		WeaponRig.AX = Vector3(float(a[0]), float(a[1]), float(a[2]))
	if OS.get_environment("WPN_CAL") != "":
		# kalibrasyon: tutma noktası (kırmızı) orijinde, namlu +Z (mavi), yandan ve üstten
		for id in (ids if OS.get_environment("WPN_IDS") != "" else SFProps.WEAPONS.keys()):
			var n = SFProps.weapon_node(id)
			if n == null:
				continue
			main.add_child(n)
			n.global_position = base
			var mk = MeshInstance3D.new()
			var sp = SphereMesh.new(); sp.radius = 0.025; sp.height = 0.05
			mk.mesh = sp
			var mm = StandardMaterial3D.new(); mm.albedo_color = Color.RED; mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mm.no_depth_test = true
			mk.material_override = mm
			n.add_child(mk)
			var L = float(SFProps.WEAPONS[id]["len"])
			var c = base + Vector3(0, 0, L * 0.4)
			for vi in 2:
				cam.global_position = c + (Vector3(L * 1.6 + 0.3, 0.05, 0) if vi == 0 else Vector3(0.01, L * 1.6 + 0.3, 0))
				cam.look_at(c, Vector3.UP if vi == 0 else Vector3.RIGHT)
				await get_tree().create_timer(0.15).timeout
				await main.shot("cal_%s_%d" % [id, vi])
			n.queue_free()
		get_tree().quit()
		return
	for id in ids:
		for age in ages:
			var m = CharacterModel.new()
			main.add_child(m)
			m.setup(_look(id, age))
			m.global_position = base
			m.rotation.y = PI * 0.8
			for st in states:
				m.overlay.snap("ninja_run", 0.0)
				m.overlay.snap("seal", 0.0)
				if m.has_method("set_drawn"):
					m.set_drawn(st != "sheathed", false)
				match st:
					"idle": m.play("idle", 0.0, 1.0, true)
					"run":
						m.play("run", 0.0, 1.0, true)
						m.overlay.snap("ninja_run", 1.0)
					"slash":
						m.play("slash_a", 0.0, 1.0, true)
					"air": m.play("air", 0.0, 1.0, true)
					"seal":
						m.play("idle", 0.0, 1.0, true)
						m.overlay.snap("seal", 1.0)
					"sheathed": m.play("idle", 0.0, 1.0, true)
					"draw":
						m.play("idle", 0.0, 1.0, true)
						if m.has_method("set_drawn"):
							m.set_drawn(false, false)
							await get_tree().process_frame
							m.set_drawn(true, true)
				var wait = 0.22 if st == "slash" else (0.18 if st == "draw" else 0.5)
				await get_tree().create_timer(wait).timeout
				var c = base + Vector3(0, 1.0, 0)
				if not m.weapons.is_empty():
					c = (m.weapons[0]["hand"] as Node3D).global_position
				if OS.get_environment("WPN_HAND") == "":
					c = base + Vector3(0, 1.05 * m.age_scale, 0)
				var back = st in ["sheathed", "run"]
				var dir = -Vector3(sin(m.rotation.y), 0, cos(m.rotation.y))
				if back:
					dir = -dir
				dir = (dir + Vector3(dir.z, 0, -dir.x) * 0.6).normalized()
				cam.global_position = c + dir * (2.4 if OS.get_environment("WPN_HAND") == "" else 0.7) * m.age_scale + Vector3(0, 0.2, 0)
				cam.look_at(c)
				await get_tree().process_frame
				await main.shot("%s_%s_%s" % [id, age, st])
			m.queue_free()
			await get_tree().process_frame
	get_tree().quit()
