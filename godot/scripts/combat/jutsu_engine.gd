class_name JutsuEngine
extends RefCounted
## Veri güdümlü jutsu motoru: elle yazılmış j_<id> yoksa Jutsu.execute buraya düşer.
## Her jutsu = şekil (shape) × element(ler) × güç kademesi (E..S → tier 0..5) × isimden çıkan görsel varyant.
## Mermiler/duvarlar/akışlar element çarpışma sistemine (Elements/Projectile) otomatik katılır.

const DMG := [8.0, 12.0, 18.0, 26.0, 36.0, 50.0]
const CAT_COLOR := {
	"genjutsu": Color(0.7, 0.35, 0.95), "medical": Color(0.4, 1.0, 0.55), "fuinjutsu": Color(0.25, 0.3, 0.55),
	"space_time": Color(0.55, 0.3, 0.9), "senjutsu": Color(1.0, 0.6, 0.2), "taijutsu": Color(1.0, 0.95, 0.85),
	"dojutsu": Color(0.95, 0.15, 0.15), "summoning": Color(0.9, 0.9, 0.9), "kinjutsu": Color(0.6, 0.1, 0.25),
}
const NATURE_COLOR := {"inton": Color(0.35, 0.2, 0.5), "yang": Color(1.0, 0.85, 0.4), "onmyoton": Color(0.9, 0.9, 0.95),
	"shoton": Color(0.85, 0.55, 0.95), "jinton": Color(0.95, 0.95, 1.0), "futton": Color(0.85, 0.9, 0.95), "jiton": Color(0.75, 0.6, 0.3)}


# ------------------------------------------------------------------ yardımcılar
static func J() -> Node:
	return Engine.get_main_loop().root.get_node("/root/Jutsu")


static func tree() -> SceneTree:
	return Engine.get_main_loop()


static func scene() -> Node:
	return tree().current_scene


static func color_of(d: Dictionary) -> Color:
	var el: String = d.get("element", "")
	if el != "":
		return Elements.color_of(el)
	for n in d.get("natures", []):
		if NATURE_COLOR.has(n):
			return NATURE_COLOR[n]
	return CAT_COLOR.get(d.get("category", ""), Color(0.6, 0.85, 1.0))


## İsim/açıklamadan görsel varyant (aynı şekil farklı görünsün)
static func variant(d: Dictionary) -> String:
	var s = (String(d.get("name_en", "")) + " " + String(d.get("name", ""))).to_lower()
	for pair in [["dragon", "dragon"], ["ryu", "dragon"], ["shark", "shark"], ["same", "shark"], ["bird", "bird"], ["phoenix", "bird"], ["crow", "bird"],
			["hawk", "bird"], ["swallow", "bird"], ["tiger", "beast"], ["wolf", "beast"], ["lion", "beast"], ["hound", "beast"], ["beast", "beast"],
			["rain", "barrage"], ["thousand", "barrage"], ["barrage", "barrage"], ["hail", "barrage"], ["shower", "barrage"], ["meteor", "barrage"],
			["needle", "needles"], ["senbon", "needles"], ["spear", "spear"], ["arrow", "needles"], ["lance", "spear"], ["spike", "spikes"],
			["shuriken", "disc"], ["sickle", "disc"], ["cutter", "disc"], ["blade", "disc"], ["slash", "disc"],
			["wave", "wave"], ["tsunami", "wave"], ["flood", "wave"], ["waterfall", "wave"],
			["tornado", "tornado"], ["whirlwind", "tornado"], ["vortex", "tornado"], ["cyclone", "tornado"], ["typhoon", "tornado"],
			["dome", "dome"], ["wall", "wall"], ["barrier", "dome"], ["shield", "wall"], ["rampart", "wall"],
			["prison", "prison"], ["cage", "prison"], ["coffin", "prison"], ["chain", "chains"], ["shadow", "shadow"], ["root", "roots"], ["tree", "roots"],
			["mist", "mist"], ["fog", "mist"], ["cloud", "mist"], ["smoke", "mist"], ["ash", "mist"], ["swamp", "swamp"], ["mud", "swamp"],
			["explo", "explosion"], ["bomb", "explosion"], ["blast", "explosion"], ["laser", "laser"], ["beam", "laser"], ["ray", "laser"], ["cannon", "laser"],
			["breath", "stream"], ["flame", "stream"], ["spray", "stream"], ["rasengan", "sphere"], ["sphere", "sphere"], ["chidori", "lightning_hand"],
			["lightning blade", "lightning_hand"], ["gate", "gates"], ["lotus", "lotus"], ["kick", "kick"], ["fist", "fist"], ["palm", "palm"], ["punch", "fist"]]:
		if s.contains(pair[0]):
			return pair[1]
	return ""


static func power(c: Node3D, d: Dictionary) -> float:
	var el: String = d.get("element", "")
	return J()._mult(c) * (J()._elem_bonus(c, el) if el != "" else 1.0)


static func base_dmg(c: Node3D, d: Dictionary) -> float:
	return DMG[clampi(int(d.get("tier", 2)), 0, 5)] * power(c, d)


static func glow_mat(col: Color, alpha := 1.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(1, 1, 1, alpha)
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func info(c: Node3D, d: Dictionary, mul := 1.0, extra := {}) -> Dictionary:
	var el: String = d.get("element", "")
	var t = int(d.get("tier", 2))
	var inf = {"dmg": base_dmg(c, d) * mul, "element": el, "knock": 4.0 + t * 2.0, "launch": 1.0 + t * 0.6,
		"kind": "heavy" if t >= 3 else "light", "hitstop": 0.03 + t * 0.012}
	if el in ["katon", "yoton", "shakuton"]:
		inf["burn"] = 1.5 + t * 0.4
	if el in ["raiton", "ranton"] and t >= 2:
		inf["stun"] = 0.3 + t * 0.12
	inf.merge(extra, true)
	return inf


## Varyanta göre mermi gövdesi (ileri = -Z)
static func shape_mesh(v: String, col: Color, size: float) -> Node3D:
	var root = Node3D.new()
	var b = MB.new()
	var dark = col.darkened(0.35)
	var light = col.lightened(0.4)
	match v:
		"dragon":
			b.add("sphere", Vector3(0, 0, 0), Vector3(1.0, 0.8, 1.4), col, Vector3.ZERO, 10)
			b.add("cone", Vector3(0, -0.05, -0.95), Vector3(0.7, 0.9, 0.55), col, Vector3(-90, 0, 0), 8)
			for sx in [-1.0, 1.0]:
				b.add("cone", Vector3(0.35 * sx, 0.45, 0.25), Vector3(0.12, 0.8, 0.12), light, Vector3(35, 0, -25 * sx), 6)
				b.add("sphere", Vector3(0.3 * sx, 0.25, -0.55), Vector3(0.16, 0.12, 0.12), Color(1, 1, 0.8), Vector3.ZERO, 6)
			b.add("box", Vector3(0, -0.35, -0.7), Vector3(0.5, 0.12, 0.6), dark, Vector3(-15, 0, 0))
		"shark":
			b.add("sphere", Vector3.ZERO, Vector3(0.8, 0.7, 1.8), col, Vector3.ZERO, 10)
			b.add("cone", Vector3(0, 0.55, 0.1), Vector3(0.12, 0.7, 0.45), dark, Vector3(-20, 0, 0), 4)
			b.add("cone", Vector3(0, 0, 1.0), Vector3(0.55, 0.7, 0.12), dark, Vector3(90, 0, 0), 4)
			b.add("box", Vector3(0, -0.2, -0.75), Vector3(0.5, 0.06, 0.3), Color(1, 1, 1))
		"bird":
			b.add("cone", Vector3.ZERO, Vector3(0.35, 1.2, 0.35), col, Vector3(-90, 0, 0), 6)
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(0.55 * sx, 0, 0.1), Vector3(1.0, 0.05, 0.45), light, Vector3(0, 15 * sx, 12 * sx))
		"beast":
			b.add("sphere", Vector3.ZERO, Vector3(1.1, 0.95, 1.2), col, Vector3.ZERO, 10)
			b.add("sphere", Vector3(0, -0.15, -0.6), Vector3(0.7, 0.5, 0.7), light, Vector3.ZERO, 8)
			for sx in [-1.0, 1.0]:
				b.add("cone", Vector3(0.35 * sx, 0.55, 0.1), Vector3(0.2, 0.45, 0.2), dark, Vector3(0, 0, -20 * sx), 5)
				b.add("cone", Vector3(0.2 * sx, -0.35, -0.85), Vector3(0.06, 0.3, 0.06), Color(1, 1, 1), Vector3(180, 0, 0), 4)
		"needles", "spear":
			var n = 1 if v == "spear" else 1
			for i in n:
				b.add("cyl", Vector3.ZERO, Vector3(0.08, 1.6, 0.08), light, Vector3(90, 0, 0), 5)
				b.add("cone", Vector3(0, 0, -0.95), Vector3(0.12, 0.35, 0.12), col, Vector3(-90, 0, 0), 5)
		"disc":
			b.add("cyl", Vector3.ZERO, Vector3(1.6, 0.06, 1.6), light, Vector3.ZERO, 16)
			for k in 4:
				b.add("box", Vector3.ZERO, Vector3(2.2, 0.05, 0.25), col, Vector3(0, k * 45.0, 0))
		_:
			root.add_child(Projectile.energy_mesh(light, col, 1.0, 4.0, 2.0, 2.6))
	if v in ["dragon", "shark", "bird", "beast", "needles", "spear", "disc"]:
		var mi = MeshInstance3D.new()
		mi.mesh = b.build(glow_mat(col))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		var aura = Projectile.energy_mesh(light, col, 1.1, 3.0, 2.0, 1.6)
		root.add_child(aura)
	root.scale = Vector3.ONE * size
	return root


static func spawn_projectile(c: Node3D, d: Dictionary, start: Vector3, dir: Vector3, v: String, size: float, speed: float, inf: Dictionary, homing: Node3D = null) -> Projectile:
	var col = color_of(d)
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = dir * speed
	pr.radius = maxf(0.25, size * 0.6)
	pr.life = 2.6
	pr.info = inf
	if homing:
		pr.homing = homing
		pr.homing_turn = 2.2
	if v == "disc":
		pr.pierce = true
		pr.spin = Vector3(0, 14.0, 0)
	pr.add_child(shape_mesh(v, col, size))
	Projectile.trail(pr, [col.lightened(0.4), col, Color(col.r, col.g, col.b, 0)], size * 1.1, 40, 0.4)
	if v == "dragon":
		# yılan gibi kıvrılarak ilerleyen ejderha
		var t0 = randf() * TAU
		pr.on_tick = func(p: Projectile, dt: float) -> void:
			var side = p.vel.cross(Vector3.UP).normalized()
			p.global_position += side * sin(Time.get_ticks_msec() * 0.008 + t0) * dt * 6.0
	var t = int(d.get("tier", 2))
	pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
		var r = 1.5 + t * 0.6 + (1.5 if v in ["dragon", "beast", "shark"] else 0.0)
		FX.impact(pos, col, 0.6 + t * 0.15)
		if t >= 2 or v in ["dragon", "beast", "shark"]:
			FX.ring(pos, col, r * 1.8, 0.35)
			Combat.hit_sphere(c, pos, r, inf.merged({"dmg": inf["dmg"] * 0.5}, true), pr.hit_list)
		if d.get("element", "") in ["katon", "bakuton", "yoton", "shakuton"]:
			FX.explosion(pos, 0.4 + t * 0.2, col)
	scene().add_child(pr)
	pr.global_position = start
	return pr


# ------------------------------------------------------------------ giriş noktası
static func cast(c: Node3D, id: String, t: Node3D) -> void:
	var d: Dictionary = Data.jutsu.get(id, {})
	if d.is_empty():
		return
	var shape: String = d.get("shape", "projectile")
	var v = variant(d)
	match shape:
		"projectile":
			_projectile(c, d, t, v)
		"beam":
			if v == "stream":
				J()._stream(c, t, 1.0 + int(d.get("tier", 2)) * 0.25, color_of(d), d.get("element", ""), base_dmg(c, d) * 0.22, _snd(d))
			else:
				_beam(c, d, t)
		"aoe":
			if v == "stream":
				J()._stream(c, t, 1.2 + int(d.get("tier", 2)) * 0.3, color_of(d), d.get("element", ""), base_dmg(c, d) * 0.25, _snd(d))
			elif v == "tornado":
				_tornado(c, d, t)
			elif v == "wave":
				_wave(c, d, t)
			elif v == "barrage":
				_barrage(c, d, t)
			elif v in ["spikes", "roots"] or (d.get("element", "") in ["doton", "mokuton", "shoton"] and v == ""):
				_spikes(c, d, t)
			else:
				_aoe(c, d, t, v)
		"wall":
			if v == "dome":
				_dome(c, d)
			else:
				_wall(c, d, t)
		"bind", "debuff":
			_bind(c, d, t, v, shape == "debuff")
		"genjutsu_stun":
			_genjutsu(c, d, t)
		"summon":
			_summon(c, d)
		"buff", "mode", "utility":
			_buff(c, d, shape)
		"clone":
			_clone(c, d)
		"seal":
			_seal(c, d, t)
		"field":
			_field(c, d, t, v)
		"transform":
			if String(d.get("name_en", "")).to_lower().contains("transformation"):
				J().j_henge(c, t)
			else:
				_buff(c, d, "transform")
		"stealth":
			_stealth(c, d)
		"sensor":
			_sensor(c, d)
		"trap":
			_trap(c, d, t)
		"teleport":
			_teleport(c, d, t)
		"counter":
			_counter(c, d)
		"heal", "revive":
			_heal(c, d, shape == "revive")
		"melee", "rush", "dash":
			_melee(c, d, t, v, shape)
		_:
			_projectile(c, d, t, v)


static func _snd(d: Dictionary) -> String:
	match d.get("element", ""):
		"katon", "yoton", "shakuton", "bakuton": return "fire"
		"suiton", "hyoton", "futton": return "water"
		"fuuton", "jinton": return "wind"
		"raiton", "ranton": return "chidori"
		"doton", "mokuton", "jiton", "shoton": return "earth"
	return "whoosh"


# ------------------------------------------------------------------ şekiller
static func _projectile(c: Node3D, d: Dictionary, t: Node3D, v: String) -> void:
	var tier = int(d.get("tier", 2))
	var dir: Vector3 = J()._aim(c, t)
	var start: Vector3 = J()._cast_origin(c, String(d.get("id", ""))) + dir * 0.8
	Sfx.play(_snd(d), start)
	FX.burst(start, {"amount": 16, "life": 0.3, "size": 0.8, "vmin": 3, "vmax": 8, "dir": dir, "spread": 30.0,
		"colors": [color_of(d).lightened(0.5), color_of(d), Color(0, 0, 0, 0)]})
	match v:
		"needles", "barrage":
			var n = 4 + tier * 2
			for i in n:
				var dd = dir.rotated(Vector3.UP, deg_to_rad(randf_range(-12, 12))) + Vector3.UP * randf_range(-0.05, 0.08)
				spawn_projectile(c, d, start + Vector3(randf_range(-0.4, 0.4), randf_range(-0.3, 0.3), 0), dd.normalized(), "needles", 0.35, 38.0,
					info(c, d, 1.6 / n, {"knock": 1.5, "kind": "light"}))
		"bird":
			var n = 2 + tier / 2
			for i in n:
				var dd = dir.rotated(Vector3.UP, deg_to_rad(-20 + 40.0 * i / maxf(1, n - 1)))
				spawn_projectile(c, d, start, dd, "bird", 0.6 + tier * 0.1, 22.0, info(c, d, 1.2 / n), t)
		"disc":
			spawn_projectile(c, d, start, dir, "disc", 0.7 + tier * 0.25, 26.0, info(c, d, 0.9))
		"dragon", "shark", "beast":
			spawn_projectile(c, d, start, dir, v, 1.2 + tier * 0.35, 18.0 + tier, info(c, d, 1.3), t if v == "shark" else null)
		"spear":
			spawn_projectile(c, d, start, dir, "spear", 0.9 + tier * 0.2, 34.0, info(c, d, 1.1))
		_:
			spawn_projectile(c, d, start, dir, "", 0.6 + tier * 0.28, 24.0, info(c, d, 1.0))


## Işın: elden nişangâha uzanan, sürekli hasar veren ve karşı mermileri çarpıştıran sütun
static func _beam(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var dur = 0.8 + tier * 0.2
	var width = 0.22 + tier * 0.09
	var beam = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = width; cm.bottom_radius = width; cm.height = 1.0; cm.radial_segments = 12
	beam.mesh = cm
	var bm = glow_mat(col, 0.7)
	bm.vertex_color_use_as_albedo = false
	bm.albedo_color = Color(col.r, col.g, col.b, 0.7)
	beam.material_override = bm
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene().add_child(beam)
	Sfx.play(_snd(d), c.global_position, 0.8)
	var st = {"t": 0.0}
	var inf = info(c, d, 0.12)
	var timer = Timer.new()
	timer.wait_time = 0.05
	scene().add_child(timer)
	timer.timeout.connect(func():
		st["t"] += 0.05
		if not is_instance_valid(c) or st["t"] > dur:
			beam.queue_free()
			timer.queue_free()
			return
		var dir: Vector3 = J()._aim(c, t)
		var from: Vector3 = J()._cast_origin(c, String(d.get("id", "")))
		var length = 40.0
		var hit = c.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + dir * length, 1))
		if not hit.is_empty():
			length = from.distance_to(hit["position"])
		beam.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)) * Basis.from_scale(Vector3(1, length, 1)), from + dir * length * 0.5)
		for k in int(length / 2.0):
			Combat.hit_sphere(c, from + dir * (1.0 + k * 2.0), width + 0.6, inf)
		for pr in tree().get_nodes_in_group("projectiles"):
			if pr.dead or pr.element() == "" or pr.shooter == null or not is_instance_valid(pr.shooter) or not Combat.hostile(c, pr.shooter):
				continue
			var rel: Vector3 = pr.global_position - from
			var along = rel.dot(dir)
			if along > 0.0 and along < length and (rel - dir * along).length() < width + pr.radius:
				var r = Elements.clash({"el": d.get("element", ""), "pow": inf["dmg"] * 8.0}, {"el": pr.element(), "pow": pr.power()})
				Elements.clash_fx(pr.global_position, r["effect"], d.get("element", ""), pr.element(), pr.radius)
				pr.apply_clash(r["b_alive"], r["b_scale"])
		if int(st["t"] * 20) % 3 == 0:
			FX.burst(from + dir * length, {"amount": 6, "life": 0.3, "tex": FX.tex_spark, "size": 0.8, "vmin": 2, "vmax": 6, "colors": [Color(1, 1, 1, 1), col, Color(col.r, col.g, col.b, 0)]}))
	timer.start()


static func _aoe(c: Node3D, d: Dictionary, t: Node3D, v: String) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var r = 3.5 + tier * 1.3
	var rng_s = String(d.get("range", "")).to_lower()
	var far = rng_s.contains("long") or rng_s.contains("mid") or v == "explosion"
	var pos: Vector3 = J()._aim_ground(c, t, 10.0, 30.0) if far else c.global_position
	pos = J()._ground(pos)
	var inf = info(c, d, 1.2)
	var el: String = d.get("element", "")
	if el in ["raiton", "ranton"]:
		# gökten inen yıldırımlar
		for k in 3 + tier:
			var p = pos + Vector3(randf_range(-r, r), 0, randf_range(-r, r)) * 0.7
			tree().create_timer(k * 0.08).timeout.connect(func():
				var arcs = Arcs.new()
				arcs.color = col
				arcs.radius = 1.5
				arcs.count = 6
				scene().add_child(arcs)
				arcs.global_position = p + Vector3.UP * 3.0
				tree().create_timer(0.25).timeout.connect(arcs.queue_free)
				FX.flash_sphere(p + Vector3.UP, col, 2.0, 0.2)
				Combat.hit_sphere(c, p + Vector3.UP, 2.2, inf.merged({"dmg": inf["dmg"] / 3.0}, true)))
		Sfx.play("thunder", pos)
	else:
		if v == "explosion" or el in ["katon", "bakuton", "yoton"]:
			FX.explosion(pos + Vector3.UP, 0.8 + tier * 0.35, col)
		else:
			FX.flash_sphere(pos + Vector3.UP, col.lightened(0.2), r * 0.6, 0.35)
		FX.ring(pos + Vector3.UP * 0.2, col, r * 2.0, 0.45)
		FX.burst(pos + Vector3.UP, {"amount": 40 + tier * 10, "life": 0.7, "tex": FX.tex_smoke, "size": 1.2, "vmin": 4, "vmax": 9 + tier,
			"colors": [col.lightened(0.4), col, Color(col.r, col.g, col.b, 0)]})
		Combat.hit_sphere(c, pos + Vector3.UP, r, inf)
		Sfx.play("boom" if v == "explosion" else _snd(d), pos)
	if Game.world:
		Game.world.env.add_shake(0.2 + tier * 0.12)


static func _spikes(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var dir: Vector3 = J()._aim_flat(c, t)
	var inf = info(c, d, 0.5, {"launch": 7.0 + tier})
	Sfx.play(_snd(d), c.global_position)
	for k in 5 + tier * 2:
		tree().create_timer(k * 0.05).timeout.connect(func():
			if not is_instance_valid(c):
				return
			var p = J()._ground(c.global_position + dir * (2.0 + k * 1.6) + dir.cross(Vector3.UP) * randf_range(-1.0, 1.0))
			var b = MB.new()
			for s in 2 + tier / 2:
				b.add("cone", Vector3(randf_range(-0.5, 0.5), 1.2, randf_range(-0.5, 0.5)), Vector3(0.8, 2.2 + tier * 0.4 + randf(), 0.8), col.darkened(0.15), Vector3(randf_range(-15, 15), 0, randf_range(-15, 15)), 6)
			var sp = MeshInstance3D.new()
			sp.mesh = b.build(Props.toon())
			scene().add_child(sp)
			sp.global_position = p - Vector3(0, 3, 0)
			var tw = sp.create_tween()
			tw.tween_property(sp, "global_position:y", p.y, 0.1)
			tw.tween_interval(1.2)
			tw.tween_property(sp, "global_position:y", p.y - 3.5, 0.4)
			tw.tween_callback(sp.queue_free)
			FX.dust(p, 0.7)
			Combat.hit_sphere(c, p + Vector3.UP, 1.6, inf))


static func _wave(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var dir: Vector3 = J()._aim_flat(c, t)
	var w = 5.0 + tier * 2.0
	var h = 2.0 + tier * 0.8
	var b = MB.new()
	b.add("cyl", Vector3.ZERO, Vector3(h * 1.2, w, h * 0.8), col, Vector3(0, 0, 90), 12)
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(glow_mat(col, 0.75))
	scene().add_child(mi)
	var start = J()._ground(c.global_position + dir * 2.0)
	mi.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), start + Vector3.UP * h * 0.4)
	Sfx.play(_snd(d), start)
	var inf = info(c, d, 1.0, {"knock": 14.0 + tier * 2})
	var tw = mi.create_tween()
	var hit = []
	tw.tween_method(func(k: float):
		var p = start + dir * k * (14.0 + tier * 3.0)
		mi.global_position = p + Vector3.UP * h * 0.4
		var got = Combat.hit_sphere(c, p + Vector3.UP, w * 0.5, inf, hit)
		hit.append_array(got)
		if randf() < 0.5:
			FX.burst(p + Vector3.UP * h, {"amount": 6, "life": 0.5, "add": false, "size": 0.6, "vmin": 2, "vmax": 5, "gravity": Vector3(0, -12, 0),
				"colors": [Color(1, 1, 1, 0.9), col, Color(col.r, col.g, col.b, 0)]}), 0.0, 1.0, 1.0)
	tw.tween_property(mi, "scale", Vector3(1, 0.05, 1), 0.3)
	tw.tween_callback(mi.queue_free)


static func _tornado(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var pos: Vector3 = J()._ground(J()._aim_ground(c, t, 8.0, 25.0))
	var hgt = 6.0 + tier * 2.0
	var b = MB.new()
	for k in 6:
		b.add("torus", Vector3(0, k * hgt / 6.0, 0), Vector3(1.0 + k * 0.5, 0.6, 1.0 + k * 0.5), col, Vector3.ZERO, 14)
	b.add("cone", Vector3(0, hgt * 0.45, 0), Vector3(3.5 + tier * 0.4, hgt, 3.5 + tier * 0.4), col, Vector3(180, 0, 0), 14)
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(glow_mat(col, 0.4))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene().add_child(mi)
	mi.global_position = pos
	Sfx.play("wind", pos)
	var inf = info(c, d, 0.18, {"knock": 2.0, "launch": 5.0, "kind": "light"})
	var tw = mi.create_tween()
	for i in 16:
		tw.tween_callback(func():
			mi.rotate_y(0.8)
			Combat.hit_sphere(c, pos + Vector3.UP * 2.0, 3.0 + tier * 0.5, inf)
			for f in tree().get_nodes_in_group("fighters"):
				if Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(pos) < 9.0:
					f.velocity += (pos - f.global_position).normalized() * 2.0)
		tw.tween_interval(0.15)
	tw.tween_property(mi, "scale", Vector3(0.1, 1.0, 0.1), 0.3)
	tw.tween_callback(mi.queue_free)


static func _barrage(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var pos: Vector3 = J()._ground(J()._aim_ground(c, t, 10.0, 30.0))
	var n = 8 + tier * 4
	var r = 3.0 + tier
	Sfx.play(_snd(d), pos, 0.9)
	for i in n:
		tree().create_timer(i * 0.05).timeout.connect(func():
			if not is_instance_valid(c):
				return
			var tgt = pos + Vector3(randf_range(-r, r), 0, randf_range(-r, r))
			var start = tgt + Vector3(randf_range(-3, 3), 14.0, randf_range(-3, 3))
			spawn_projectile(c, d, start, (tgt - start).normalized(), "needles", 0.45, 34.0, info(c, d, 2.0 / n, {"kind": "light", "knock": 1.0})))


static func _wall(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var el: String = d.get("element", "")
	var dir: Vector3 = J()._aim_flat(c, t)
	var pos = J()._ground(c.global_position + dir * 3.5)
	var size = Vector3(7.0 + tier * 1.5, 4.0 + tier * 0.8, 1.6)
	var wall = StaticBody3D.new()
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position.y = size.y * 0.5
	wall.add_child(cs)
	var b = MB.new()
	var transparent = el in ["suiton", "fuuton", "hyoton", "raiton", "futton", ""]
	b.add("box", Vector3(0, size.y * 0.5, 0), size, col)
	if el in ["doton", "mokuton", "yoton", "shoton"]:
		for k in 4:
			b.add("box", Vector3(-size.x * 0.4 + k * size.x * 0.27, size.y + 0.3, 0), Vector3(size.x * 0.15, 0.6, size.z * 1.1), col.darkened(0.15))
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(glow_mat(col, 0.55) if transparent else Props.toon())
	wall.add_child(mi)
	scene().add_child(wall)
	J()._element_wall(wall, el if el != "" else "doton", c, Vector3(0, size.y * 0.5, 0), size * 0.5, base_dmg(c, d) * 2.0)
	wall.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), pos - Vector3(0, size.y + 0.5, 0))
	var tw = wall.create_tween()
	tw.tween_property(wall, "global_position:y", pos.y, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(8.0 + tier * 1.5)
	tw.tween_property(wall, "global_position:y", pos.y - size.y - 0.5, 0.5)
	tw.tween_callback(wall.queue_free)
	FX.dust(pos, 2.0)
	Sfx.play(_snd(d), pos)


static func _dome(c: Node3D, d: Dictionary) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var r = 3.0 + tier * 0.4
	var mi = MeshInstance3D.new()
	var b = MB.new()
	b.add("hemi", Vector3.ZERO, Vector3.ONE * r * 2.0, col, Vector3.ZERO, 18)
	mi.mesh = b.build(glow_mat(col, 0.45))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	c.add_child(mi)
	mi.scale = Vector3.ONE * 0.1
	var dur = 3.0 + tier * 0.6
	Buffs.add("dome_" + String(d.get("id", "")), dur, {"armor": 0.35})
	J()._element_wall(mi, d.get("element", "") if d.get("element", "") != "" else "doton", c, Vector3(0, r * 0.5, 0), Vector3(r, r * 0.5, r), base_dmg(c, d) * 2.0)
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(dur)
	tw.tween_property(mi, "scale", Vector3.ONE * 0.05, 0.3)
	tw.tween_callback(mi.queue_free)
	Sfx.play(_snd(d), c.global_position)


static func _target_in_range(c: Node3D, t: Node3D, rng: float) -> Node3D:
	if t and is_instance_valid(t) and not t.is_dead() and t.global_position.distance_to(c.global_position) < rng:
		return t
	var dir: Vector3 = J()._aim_flat(c, t)
	return Combat.nearest_enemy(c, rng, dir, 0.4)


static func _bind(c: Node3D, d: Dictionary, t: Node3D, v: String, debuff: bool) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var tg = _target_in_range(c, t, 18.0 + tier * 2.0)
	if tg == null:
		if c is Player:
			Hud.msg("Bağlanacak hedef yok.", Color(0.8, 0.8, 0.8))
		return
	var dur = 1.8 + tier * 0.45
	if debuff:
		tg.apply_status("slow", dur * 1.6)
		tg.apply_status("weak", dur * 1.6)
	else:
		tg.apply_status("bind", dur)
	var b = MB.new()
	match v:
		"prison":
			b.add("sphere", Vector3(0, 1.0, 0), Vector3(2.4, 2.6, 2.4), col, Vector3.ZERO, 14)
		"roots":
			for k in 6:
				b.add("cyl", Vector3(cos(k) * 0.6, 0.9, sin(k) * 0.6), Vector3(0.18, 2.2, 0.18), col.darkened(0.2), Vector3(randf_range(-25, 25), 0, randf_range(-25, 25)), 6)
		"shadow":
			b.add("cyl", Vector3(0, 0.02, 0), Vector3(2.2, 0.04, 2.2), Color(0.03, 0.02, 0.05), Vector3.ZERO, 16)
		_:
			for k in 4:
				b.add("torus", Vector3(0, 0.4 + k * 0.45, 0), Vector3(1.4, 0.5, 1.4), col, Vector3(randf_range(-15, 15), 0, randf_range(-15, 15)), 12)
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(glow_mat(col, 0.55 if v == "prison" else 0.9))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tg.add_child(mi)
	mi.scale = Vector3.ONE * maxf(1.0, tg.height / 1.8)
	if v == "shadow":
		J()._shadow_line(c, tg, dur)
	var inf = info(c, d, 0.12, {"knock": 0.0, "launch": 0.0, "kind": "light", "hitstop": 0.0})
	J()._ticks(int(dur / 0.4), 0.4, func(_i):
		if is_instance_valid(tg) and not tg.is_dead():
			tg.take_hit(inf.merged({"attacker": c, "dir": Vector3.ZERO}, true)), func():
		if is_instance_valid(mi):
			mi.queue_free())
	Sfx.play(_snd(d), tg.global_position)


static func _genjutsu(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var targets = []
	if tier >= 4:
		for f in tree().get_nodes_in_group("fighters"):
			if Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(c.global_position) < 14.0 + tier * 2:
				targets.append(f)
	else:
		var tg = _target_in_range(c, t, 20.0)
		if tg:
			targets.append(tg)
	if targets.is_empty():
		return
	Sfx.play("genjutsu", c.global_position)
	for tg in targets:
		tg.apply_status("stun", 1.6 + tier * 0.4)
		tg.apply_status("fear", 1.6 + tier * 0.4)
		if tier >= 3:
			tg.take_hit(info(c, d, 0.6, {"knock": 0.0, "attacker": c, "dir": Vector3.ZERO}))
		FX.burst(tg.global_position + Vector3.UP * 1.5, {"amount": 30, "life": 1.4, "tex": FX.tex_leaf, "add": false, "size": 0.3, "radius": 1.8,
			"vmin": 0.5, "vmax": 2.0, "gravity": Vector3(0, -1, 0), "spin": 200.0, "colors": [col.lightened(0.3), Color(col.r, col.g, col.b, 0)]})
	if c is Player and Game.world:
		Game.world.env.set_tint(Color(col.r, col.g, col.b, 0.2))
		tree().create_timer(0.7).timeout.connect(func(): Game.world.env.set_tint(Color(0, 0, 0, 0)))


static func _summon(c: Node3D, d: Dictionary) -> void:
	var s = String(d.get("name_en", "")).to_lower()
	var kind = Game.profile.get("summon", "kurbağa") if c is Player else "kurbağa"
	if s.contains("snake") or s.contains("serpent"):
		kind = "yılan"
	elif s.contains("slug"):
		kind = "sümüklü"
	elif s.contains("toad") or s.contains("frog"):
		kind = "kurbağa"
	var pos: Vector3 = J()._ground(J()._aim_ground(c, null, 6.0, 10.0))
	FX.smoke_puff(pos + Vector3.UP * 3, 4.0, 40)
	var sm = Summon.new()
	sm.kind = kind
	sm.team = c.team
	scene().add_child(sm)
	sm.global_position = pos
	if Game.world:
		Game.world.env.add_shake(1.0)
	Sfx.play("boom", pos, 0.6)


static func _buff(c: Node3D, d: Dictionary, kind: String) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var dur = 10.0 + tier * 3.0
	var mods = {"melee": 1.0 + 0.07 * (tier + 1)}
	var cat: String = d.get("category", "")
	var el: String = d.get("element", "")
	if kind == "mode" or cat == "senjutsu":
		mods = {"melee": 1.2 + 0.06 * tier, "armor": 0.85, "jutsu": 1.15 + 0.05 * tier}
	elif el in ["raiton", "ranton"]:
		mods = {"speed": 1.15 + 0.04 * tier, "melee": 1.1 + 0.05 * tier}
	elif el in ["doton", "shoton", "jiton"] or kind == "transform":
		mods = {"armor": maxf(0.5, 0.9 - 0.06 * tier), "melee": 1.05 + 0.04 * tier}
	elif el in ["fuuton"]:
		mods = {"speed": 1.2 + 0.04 * tier}
	elif kind == "utility":
		mods = {"speed": 1.1}
		dur = 8.0 + tier * 2.0
	Buffs.add(String(d.get("id", "buff")), dur, mods)
	FX.aura(c, col, 0.9 + tier * 0.1, Vector3(0, 0.9, 0), dur)
	FX.ring(c.global_position + Vector3.UP * 0.2, col, 4.0 + tier, 0.4)
	if c is Player:
		Hud.msg("%s: %d sn" % [String(d.get("name", "")).split(" (")[0], int(dur)], col.lightened(0.3))
	Sfx.play("seal", c.global_position, 0.8)


static func _clone(c: Node3D, d: Dictionary) -> void:
	var tier = int(d.get("tier", 2))
	var n = clampi(1 + tier / 2, 1, 4)
	var col = color_of(d)
	for i in n:
		var ang = TAU * i / n
		var off = Vector3(cos(ang), 0, sin(ang)) * 2.6
		var cl = ShadowClone.new()
		cl.team = c.team
		cl.look = c.model.look if c.get("model") else {}
		scene().add_child(cl)
		cl.global_position = c.global_position + off
		if d.get("element", "") != "":
			FX.burst(cl.global_position + Vector3.UP, {"amount": 20, "life": 0.6, "add": false, "size": 0.6, "vmin": 2, "vmax": 5,
				"colors": [col.lightened(0.3), Color(col.r, col.g, col.b, 0)]})
		else:
			FX.smoke_puff(cl.global_position + Vector3.UP, 1.0, 14)
	Sfx.play("poof", c.global_position)


static func _seal(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var tg = _target_in_range(c, t, 12.0 + tier)
	var pos = J()._ground(tg.global_position if tg else c.global_position + c.face_dir() * 4.0)
	var ink = Color(0.05, 0.05, 0.12)
	FX.ring(pos + Vector3.UP * 0.05, ink, 6.0 + tier, 0.8)
	FX.ring(pos + Vector3.UP * 0.06, Color(0.3, 0.4, 0.9), 3.5 + tier, 0.8)
	var mi = MeshInstance3D.new()
	var b = MB.new()
	b.add("cyl", Vector3.ZERO, Vector3(5.0 + tier, 0.02, 5.0 + tier), ink, Vector3.ZERO, 24)
	for k in 8:
		b.add("box", Vector3(cos(k * TAU / 8) * 2.0, 0.03, sin(k * TAU / 8) * 2.0), Vector3(0.15, 0.02, 1.0), Color(0.2, 0.2, 0.4), Vector3(0, -k * 45.0, 0))
	mi.mesh = b.build(glow_mat(ink, 0.8))
	scene().add_child(mi)
	mi.global_position = pos + Vector3.UP * 0.03
	var tw = mi.create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(mi, "scale", Vector3(0.05, 1, 0.05), 0.4)
	tw.tween_callback(mi.queue_free)
	if tg:
		tg.apply_status("stun", 1.2 + tier * 0.3)
		tg.apply_status("sealed", 6.0 + tier * 2.0)
		tg.take_hit(info(c, d, 0.8, {"knock": 0.0, "attacker": c, "dir": Vector3.ZERO}))
	Sfx.play("seal", pos)


static func _field(c: Node3D, d: Dictionary, t: Node3D, v: String) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var el: String = d.get("element", "")
	var r = 5.0 + tier * 1.2
	var pos: Vector3 = J()._ground(J()._aim_ground(c, t, 8.0, 25.0) if v != "mist" else c.global_position)
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = r; cm.bottom_radius = r; cm.height = 0.1 if v != "mist" else 4.0; cm.radial_segments = 24
	mi.mesh = cm
	var m = glow_mat(col, 0.35 if v != "mist" else 0.25)
	m.vertex_color_use_as_albedo = false
	m.albedo_color = Color(col.r, col.g, col.b, 0.35 if v != "mist" else 0.25)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene().add_child(mi)
	mi.global_position = pos + Vector3.UP * (0.05 if v != "mist" else 2.0)
	var dur = 6.0 + tier * 1.5
	var inf = info(c, d, 0.08, {"knock": 0.0, "launch": 0.0, "kind": "light", "hitstop": 0.0})
	Sfx.play(_snd(d), pos, 0.7)
	if v == "mist":
		mi.visible = false
		for f in tree().get_nodes_in_group("fighters"):
			if Combat.hostile(c, f) and f.global_position.distance_to(pos) < r * 1.5 and f.has_method("lose_target"):
				f.lose_target(dur * 0.6)
	J()._ticks(int(dur / 0.5), 0.5, func(_i):
		for f in tree().get_nodes_in_group("fighters"):
			if not Combat.hostile(c, f) or f.is_dead() or f.global_position.distance_to(pos) > r:
				continue
			if v == "swamp" or el in ["doton", "suiton", "hyoton", "mokuton"]:
				f.apply_status("slow", 0.7)
			if el != "" or d.get("category", "") in ["genjutsu", "kinjutsu", "senjutsu"]:
				f.take_hit(inf.merged({"attacker": c, "dir": Vector3.ZERO}, true))
		if v == "mist":
			FX.burst(pos + Vector3.UP * 1.5, {"amount": 14, "life": 2.2, "tex": FX.tex_smoke, "add": false, "size": 4.5, "radius": r,
				"vmin": 0.2, "vmax": 0.8, "gravity": Vector3.ZERO, "colors": [Color(0.92, 0.95, 1.0, 0.0), Color(0.9, 0.93, 0.98, 0.55), Color(0.9, 0.93, 0.98, 0.0)]})
		FX.burst(pos + Vector3.UP * 0.5, {"amount": 8, "life": 0.8, "tex": FX.tex_smoke, "add": el in ["katon", "raiton"], "size": 0.9, "radius": r * 0.8,
			"vmin": 0.5, "vmax": 2.0, "colors": [col.lightened(0.2), Color(col.r, col.g, col.b, 0)]}), func():
		var tw = mi.create_tween()
		tw.tween_property(mi, "scale", Vector3(0.05, 1, 0.05), 0.5)
		tw.tween_callback(mi.queue_free))


static func _stealth(c: Node3D, d: Dictionary) -> void:
	var tier = int(d.get("tier", 2))
	var dur = 8.0 + tier * 2.0
	Buffs.add("stealth_" + String(d.get("id", "")), dur, {"stealth": 1.0})
	for f in tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and f.global_position.distance_to(c.global_position) < 30 and f.has_method("lose_target"):
			f.lose_target(dur * 0.5)
	FX.smoke_puff(c.global_position + Vector3.UP, 1.2, 18)
	if c.get("model"):
		c.model.visible = false
		tree().create_timer(minf(dur, 4.0)).timeout.connect(func():
			if is_instance_valid(c) and c.get("model"):
				c.model.visible = true)
	Sfx.play("poof", c.global_position)


static func _sensor(c: Node3D, d: Dictionary) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	FX.ring(c.global_position + Vector3.UP, col, 30.0 + tier * 10.0, 0.9)
	for f in tree().get_nodes_in_group("fighters"):
		if not Combat.hostile(c, f) or f.is_dead() or f.global_position.distance_to(c.global_position) > 60.0 + tier * 20.0:
			continue
		var l = Label3D.new()
		l.text = "◆"
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.fixed_size = true
		l.pixel_size = 0.002
		l.font_size = 48
		l.modulate = col.lightened(0.3)
		f.add_child(l)
		l.position = Vector3(0, f.height * 0.6, 0)
		tree().create_timer(12.0).timeout.connect(func():
			if is_instance_valid(l):
				l.queue_free())
	Sfx.play("genjutsu", c.global_position, 1.4)


static func _trap(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var pos: Vector3 = J()._ground(J()._aim_ground(c, t, 6.0, 20.0))
	var mark = MeshInstance3D.new()
	var b = MB.new()
	b.add("cyl", Vector3.ZERO, Vector3(1.6, 0.03, 1.6), col.darkened(0.3), Vector3.ZERO, 12)
	mark.mesh = b.build(glow_mat(col, 0.6))
	scene().add_child(mark)
	mark.global_position = pos + Vector3.UP * 0.03
	var st = {"armed": true}
	J()._ticks(int(20.0 / 0.2), 0.2, func(_i):
		if not st["armed"]:
			return
		for f in tree().get_nodes_in_group("fighters"):
			if Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(pos) < 2.5:
				st["armed"] = false
				f.apply_status("bind", 1.5 + tier * 0.3)
				FX.explosion(pos + Vector3.UP * 0.5, 0.6 + tier * 0.2, col)
				Combat.hit_sphere(c, pos + Vector3.UP, 3.0 + tier * 0.5, info(c, d, 1.3))
				if is_instance_valid(mark):
					mark.queue_free()
				return, func():
		if is_instance_valid(mark):
			mark.queue_free())
	Sfx.play("seal", pos, 1.2)


static func _teleport(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var col = color_of(d)
	var tier = int(d.get("tier", 2))
	var from = c.global_position
	var dir: Vector3 = J()._aim_flat(c, t)
	var to = from + dir * (14.0 + tier * 4.0)
	if t and is_instance_valid(t):
		to = t.global_position - dir * (2.0 if tier < 4 else -2.0)  # yüksek kademe: hedefin arkasına
	var hit = c.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from + Vector3.UP, to + Vector3.UP, 1))
	if not hit.is_empty():
		to = hit["position"] - dir * 0.8
	to = J()._ground(to)
	for p in [from, to]:
		FX.burst(p + Vector3.UP, {"amount": 22, "life": 0.6, "tex": FX.tex_spark, "size": 0.6, "vmin": 2, "vmax": 6, "colors": [Color(1, 1, 1, 1), col, Color(col.r, col.g, col.b, 0)]})
		FX.ring(p + Vector3.UP, col, 3.0, 0.3, false)
	c.global_position = to
	if c.has_method("reset_physics_interpolation"):
		c.reset_physics_interpolation()
	Sfx.play("whoosh", to, 1.5)


static func _counter(c: Node3D, d: Dictionary) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	if c is Player and c.combat:
		c.combat.invuln = 0.8 + tier * 0.1
	Buffs.add("counter_" + String(d.get("id", "")), 1.2, {"armor": 0.2})
	for f in tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(c.global_position) < 4.0 + tier * 0.5:
			var dd = f.global_position - c.global_position
			dd.y = 0
			f.take_hit(info(c, d, 0.7, {"knock": 14.0, "dir": dd.normalized(), "attacker": c}))
	FX.ring(c.global_position + Vector3.UP, col, 6.0, 0.35, false, c.face_dir() if c.has_method("face_dir") else Vector3.FORWARD)
	Sfx.play("block", c.global_position, 0.8)


static func _heal(c: Node3D, d: Dictionary, revive: bool) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d) if d.get("element", "") != "" else Color(0.4, 1.0, 0.55)
	var amount = (6.0 + tier * 3.0) * (3.0 if revive else 1.0)
	FX.aura(c, col, 1.0, Vector3(0, 0.9, 0), 2.2)
	Sfx.play("heal", c.global_position)
	J()._ticks(10, 0.2, func(_i):
		if not is_instance_valid(c):
			return
		if c.get("hp") != null and c.get("max_hp") != null:
			c.hp = minf(c.max_hp, c.hp + amount * 0.25)
		for f in tree().get_nodes_in_group("fighters"):
			if f != c and not Combat.hostile(c, f) and f.global_position.distance_to(c.global_position) < 6 and f.get("hp") != null:
				f.hp = minf(f.max_hp, f.hp + amount * 0.25))


## Yakın dövüş / hücum: element aurası saran yumruk-tekme serisi, elde küre ya da yıldırım
static func _melee(c: Node3D, d: Dictionary, t: Node3D, v: String, shape: String) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	if v in ["sphere", "lightning_hand"] and c.get("model"):
		var hand: Node3D = Node3D.new()
		c.model.add_child(hand)
		hand.position = Vector3(0.35, 1.15, -0.55)
		hand.add_child(Projectile.energy_mesh(col.lightened(0.5), col, 0.6 + tier * 0.1, 14.0, 0.0, 3.0))
		if v == "lightning_hand":
			var arcs = Arcs.new()
			arcs.color = col
			arcs.radius = 0.9
			hand.add_child(arcs)
		Sfx.play("rasengan" if v == "sphere" else "chidori", c.global_position)
		J()._hand_dash(c, t, hand, 0.45, 26.0 + tier * 2.0, info(c, d, 1.6, {"kind": "heavy", "hitstop": 0.12}), col, v == "sphere")
		return
	var hits = 3 + tier if (v in ["fist", "palm", "lotus", "gates", ""] and shape == "melee") else 1
	var dur = 0.25 + 0.06 * hits if shape == "melee" else 0.4 + tier * 0.05
	var speed = 14.0 if shape == "melee" else 26.0
	var inf = info(c, d, 1.4 / hits)
	if v in ["lotus", "kick"]:
		inf["launch"] = 9.0 + tier
	var aura = FX.aura(c, col, 0.6 + tier * 0.1, Vector3(0, 0.9, 0), dur + 0.3)
	var hit_list = []
	var cnt = {"n": 0, "t": 0.0}
	if c.get("model"):
		c.model.play(["jab", "cross", "hook"][randi() % 3], 0.05, 1.6, true)
	J()._dash(c, t, dur, speed, func(pt: Vector3):
		cnt["t"] += 1.0 / 60.0
		if cnt["t"] >= dur / hits * (cnt["n"] + 1) or shape != "melee":
			var got = Combat.hit_sphere(c, pt, 1.4 + tier * 0.15, inf, [] if shape == "melee" else hit_list)
			if shape != "melee":
				hit_list.append_array(got)
			if shape == "melee":
				cnt["n"] += 1
				if c.get("model"):
					c.model.play(["jab", "cross", "hook"][cnt["n"] % 3], 0.03, 1.8, true)
			if not got.is_empty():
				FX.hit_spark(pt, col, 0.8)
		if shape != "melee" and randf() < 0.5:
			FX.burst(pt, {"amount": 3, "life": 0.3, "size": 0.7, "vmin": 1, "vmax": 3, "colors": [col.lightened(0.4), Color(col.r, col.g, col.b, 0)]}), func():
		if v in ["lotus", "gates"] or tier >= 4:
			FX.impact(c.global_position + c.face_dir() * 1.5, col, 0.8 + tier * 0.2)
			if Game.world:
				Game.world.env.add_shake(0.3 + tier * 0.1))
	Sfx.play("whoosh", c.global_position, 1.2)

