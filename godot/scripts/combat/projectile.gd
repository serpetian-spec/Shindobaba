class_name Projectile
extends Node3D
## Genel mermi: kunai, shuriken, ateş topu, su ejderhası... Kapsül hitbox'lara ve dünyaya çarpar.

var shooter: Node3D
var epic := VFX.epic   # yaratıldığı yayının destan ölçeği (çarpma/iz efektleri bununla büyür)
var vel = Vector3.ZERO
var gravity = 0.0
var radius = 0.2
var life = 3.0
var info = {}
var homing: Node3D = null
var homing_turn = 0.0
var pierce = false
var on_hit: Callable = Callable()   # func(pos: Vector3, target: Node3D)
var on_tick: Callable = Callable()  # func(proj, dt)
var spin = Vector3.ZERO
var stick = false
var hit_list: Array = []
var dead = false
var blockable = true


func _ready() -> void:
	add_to_group("projectiles")


func _physics_process(dt: float) -> void:
	if dead:
		return
	life -= dt
	if life <= 0.0:
		_finish(global_position, null)
		return
	if homing and is_instance_valid(homing) and not homing.is_dead():
		var want: Vector3 = (homing.global_position + Vector3.UP * homing.height * 0.5 - global_position).normalized() * vel.length()
		vel = vel.lerp(want, minf(1.0, homing_turn * dt))
	vel.y -= gravity * dt
	var step = vel * dt
	var from = global_position
	var to = from + step
	# element çarpışmaları: karşı takımın jutsuları ve element duvarları
	if _check_clash(to):
		return
	# savaşçılar (alt adımlarla)
	var n = maxi(1, int(step.length() / maxf(radius, 0.3)) + 1)
	for i in n:
		var pt = from.lerp(to, float(i + 1) / n)
		for f in get_tree().get_nodes_in_group("fighters"):
			if f in hit_list or not Combat.hostile(shooter, f) or f.is_dead():
				continue
			if Combat.capsule_hit(pt, f, radius):
				var inf = info.duplicate()
				inf["attacker"] = shooter
				inf["dir"] = Vector3(vel.x, 0, vel.z).normalized()
				f.take_hit(inf)
				hit_list.append(f)
				if not pierce:
					_finish(pt, f)
					return
				elif on_hit.is_valid():
					var ep = VFX.epic
					VFX.epic = epic
					on_hit.call(pt, f)
					VFX.epic = ep
	# dünya
	var space = get_world_3d().direct_space_state
	var q = PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit = space.intersect_ray(q)
	if not hit.is_empty():
		_finish(hit["position"], null, hit["normal"])
		return
	if to.y < Game.terrain_height(to.x, to.z):
		_finish(Vector3(to.x, Game.terrain_height(to.x, to.z), to.z), null, Vector3.UP)
		return
	global_position = to
	if spin != Vector3.ZERO:
		rotation += spin * dt
	elif vel.length() > 0.1:
		look_at(global_position + vel, Vector3.UP if absf(vel.normalized().y) < 0.98 else Vector3.RIGHT)
	if on_tick.is_valid():
		var ep = VFX.epic
		VFX.epic = epic
		on_tick.call(self, dt)
		VFX.epic = ep


func _finish(pos: Vector3, target: Node3D, normal := Vector3.ZERO) -> void:
	if dead:
		return
	dead = true
	var el: String = info.get("element", "")
	if target == null and el in ["katon", "yoton", "shakuton"] and pos.y - Game.terrain_height(pos.x, pos.z) < 2.0:
		Elements.scorch(pos, clampf(radius * 1.8, 1.2, 5.0))
	if on_hit.is_valid():
		var ep = VFX.epic
		VFX.epic = epic
		on_hit.call(pos, target)
		VFX.epic = ep
	if stick and target == null and normal != Vector3.ZERO:
		global_position = pos - vel.normalized() * 0.15
		Sfx.play("clink", pos)
		var tw = create_tween()
		tw.tween_interval(6.0)
		tw.tween_callback(queue_free)
		return
	# parçacıklar sönerek kaybolsun
	for c in get_children():
		if c is GPUParticles3D:
			c.emitting = false
			c.reparent(get_tree().current_scene)
			get_tree().create_timer(c.lifetime + 0.2).timeout.connect(c.queue_free)
	queue_free()


# ------------------------------------------------------------------ element çarpışması
func element() -> String:
	return info.get("element", "")


func power() -> float:
	return float(info.get("dmg", 10.0))


## true döndürürse mermi bu karede yok oldu
func _check_clash(pt: Vector3) -> bool:
	var el = element()
	if el == "" or shooter == null or not is_instance_valid(shooter):
		return false
	for o in get_tree().get_nodes_in_group("projectiles"):
		if o == self or o.dead or o.element() == "" or o.shooter == null or not is_instance_valid(o.shooter):
			continue
		if not Combat.hostile(shooter, o.shooter):
			continue
		if pt.distance_to(o.global_position) > radius + o.radius:
			continue
		var r = Elements.clash({"el": el, "pow": power()}, {"el": o.element(), "pow": o.power()})
		var contact = pt.lerp(o.global_position, 0.5)
		Elements.clash_fx(contact, r["effect"], el, o.element(), maxf(radius, o.radius))
		o.apply_clash(r["b_alive"], r["b_scale"])
		apply_clash(r["a_alive"], r["a_scale"])
		if dead:
			return true
	for w in get_tree().get_nodes_in_group("element_walls"):
		if not is_instance_valid(w) or not w.is_inside_tree():
			continue
		var owner_ = w.get_meta("owner", null)
		if owner_ != null and is_instance_valid(owner_) and not Combat.hostile(shooter, owner_):
			continue
		var lp: Vector3 = w.global_transform.affine_inverse() * pt - w.get_meta("center", Vector3.ZERO)
		var hf: Vector3 = w.get_meta("half", Vector3.ONE)
		if absf(lp.x) > hf.x + radius or absf(lp.y) > hf.y + radius or absf(lp.z) > hf.z + radius:
			continue
		var wel: String = w.get_meta("element", "doton")
		var r = Elements.clash({"el": el, "pow": power()}, {"el": wel, "pow": float(w.get_meta("power", 40.0))})
		Elements.clash_fx(pt, r["effect"], el, wel, maxf(radius, 1.5))
		if not r["b_alive"]:
			break_wall(w)
		else:
			w.set_meta("power", float(w.get_meta("power", 40.0)) * maxf(0.3, r["b_scale"]))
		apply_clash(r["a_alive"], r["a_scale"])
		if dead:
			return true
	return false


## Çarpışma sonucu: yok ol (patlamadan) ya da güç/boyut değiştir (rüzgarla büyüyen ateş vb.)
func apply_clash(alive: bool, scale_: float) -> void:
	if dead:
		return
	if not alive:
		dead = true
		for c in get_children():
			if c is GPUParticles3D:
				c.emitting = false
				c.reparent(get_tree().current_scene)
				get_tree().create_timer(c.lifetime + 0.2).timeout.connect(c.queue_free)
		queue_free()
		return
	info["dmg"] = power() * scale_
	var g = sqrt(clampf(scale_, 0.4, 2.0))
	radius *= g
	for c in get_children():
		if c is Node3D and not c is GPUParticles3D:
			c.scale *= g


## Element duvarını (toprak/ağaç/buz) yık
static func break_wall(w: Node3D) -> void:
	if not is_instance_valid(w):
		return
	if w is CollisionObject3D:
		w.collision_layer = 0
	var c: Vector3 = w.global_transform * w.get_meta("center", Vector3.ZERO)
	FX.dust(c, 3.0)
	FX.burst(c, {"amount": 60, "life": 1.4, "tex": FX.tex_soft, "add": false, "size": 0.9, "radius": 3.0, "vmin": 6, "vmax": 14,
		"gravity": Vector3(0, -22, 0), "colors": [Color(0.55, 0.45, 0.33, 1), Color(0.45, 0.35, 0.25, 0)]})
	Sfx.play("earth", c, 0.8)
	w.remove_from_group("element_walls")
	var tw = w.create_tween()
	tw.tween_property(w, "scale", Vector3(1.0, 0.05, 1.0), 0.35)
	tw.tween_callback(w.queue_free)


## Su duvarı vb. tarafından yok edilir
func block() -> void:
	if blockable and not dead:
		FX.hit_spark(global_position, Color(0.6, 0.85, 1.0), 0.6)
		dead = true
		queue_free()


# ------------------------------------------------------------------ ninja aletleri
static func tool(who: Node3D, start: Vector3, dir: Vector3, kind: String, target: Node3D) -> Projectile:
	var pr = Projectile.new()
	pr.shooter = who
	pr.vel = dir * (55.0 if kind != "smoke" else 30.0)
	pr.gravity = 3.0
	pr.radius = 0.15
	pr.stick = kind in ["kunai", "shuriken"]
	var mult = Stats.melee_mult(Game.profile) * (1.0 + Stats.skill(Game.profile, "throw_dmg") + (Stats.skill(Game.profile, "tag_dmg") if kind == "tag" else 0.0)) if who is Player else 1.0
	pr.info = {"dmg": (10.0 if kind == "kunai" else 6.0) * mult, "knock": 1.5, "kind": "light", "hitstop": 0.02}
	var mi = MeshInstance3D.new()
	var b = MB.new()
	match kind:
		"kunai", "tag":
			b.add("box", Vector3(0, 0, -0.18), Vector3(0.05, 0.02, 0.32), Color(0.6, 0.62, 0.66))
			b.add("cyl", Vector3(0, 0, 0.08), Vector3(0.03, 0.18, 0.03), Color(0.2, 0.2, 0.22), Vector3(90, 0, 0), 6)
			b.add("torus", Vector3(0, 0, 0.2), Vector3(0.08, 0.08, 0.08), Color(0.3, 0.3, 0.32), Vector3(90, 0, 0), 8)
			if kind == "tag":
				b.add("box", Vector3(0, 0, 0.1), Vector3(0.07, 0.005, 0.16), Color(0.95, 0.9, 0.75))
		"shuriken":
			for k in 4:
				b.add("box", Vector3(0, 0, 0), Vector3(0.36, 0.015, 0.06), Color(0.55, 0.57, 0.6), Vector3(0, k * 45, 0))
			pr.spin = Vector3(0, 30, 0)
			pr.info["dmg"] = 6.0 * mult
		"smoke":
			b.add("sphere", Vector3.ZERO, Vector3(0.18, 0.18, 0.18), Color(0.2, 0.2, 0.22))
	mi.mesh = b.build(Props.toon())
	# hayran modeli varsa kunai görseli (namlu uçuş yönüne, -Z)
	var tn = SFProps.weapon_node(kind, SFProps.THROWN) if kind in ["kunai", "tag"] else null
	if tn:
		tn.rotation.y = PI
		pr.add_child(tn)
	else:
		pr.add_child(mi)
	if kind == "tag":
		pr.stick = false
		pr.on_hit = func(pos: Vector3, _t: Node3D) -> void:
			var at = pos
			who.get_tree().create_timer(0.6).timeout.connect(func():
				FX.explosion(at, 0.8)
				Combat.hit_sphere(who, at, 3.5, {"dmg": 30.0 * mult, "knock": 14.0, "launch": 6.0, "kind": "heavy", "hitstop": 0.08}))
	elif kind == "smoke":
		pr.on_hit = func(pos: Vector3, _t: Node3D) -> void:
			FX.burst(pos, {"amount": 50, "life": 6.0, "tex": FX.tex_smoke, "add": false, "size": 6.0, "radius": 3.0,
				"vmin": 0.5, "vmax": 2.0, "damp": 1.0, "explosive": 0.6,
				"colors": [Color(0.85, 0.85, 0.88, 0), Color(0.8, 0.8, 0.82, 0.9), Color(0.8, 0.8, 0.82, 0.85), Color(0.8, 0.8, 0.85, 0)]})
			Sfx.play("poof", pos)
			for f in who.get_tree().get_nodes_in_group("fighters"):
				if f.has_method("lose_target") and f.global_position.distance_to(pos) < 12.0:
					f.lose_target(5.0)
	who.get_tree().current_scene.add_child(pr)
	pr.global_position = start
	# iz
	FX.burst(start, {"amount": 4, "life": 0.15, "tex": FX.tex_spark, "size": 0.8, "vmin": 0.1, "vmax": 0.2, "colors": [Color(1, 1, 1, 0.6), Color(1, 1, 1, 0)]})
	return pr


## Anime enerji kütlesi: opak cel çekirdek (kademeli renk bantları) + üstünde bloom için additive parıltı katmanı
static func energy_mesh(core: Color, edge: Color, size: float, swirl := 3.0, flow := 0.0, intensity := 2.5) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	# aynı parametreli malzemeler paylaşılır: her yayında yeni ShaderMaterial yaratmak ~13 ms takılma yapıyordu
	var key = "energy_%s_%s_%.2f_%.2f_%.2f" % [core, edge, swirl, flow, intensity]
	if VFX._cache.has(key):
		var cm: Array = VFX._cache[key]
		mi.mesh = VFX._sphere(0.5, 28, 14)
		mi.material_override = cm[0]
		mi.scale = Vector3.ONE * size
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var g0 = MeshInstance3D.new()
		g0.mesh = VFX._sphere(0.5, 20, 10)
		g0.material_override = cm[1]
		g0.scale = Vector3.ONE * 1.18
		g0.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.add_child(g0)
		return mi
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/energy_cel.gdshader")
	var mid = core.lerp(edge, 0.55)
	mid = Color.from_hsv(mid.h, minf(1.0, mid.s * 1.25), minf(1.0, mid.v * 1.05))
	m.set_shader_parameter("core", core)
	m.set_shader_parameter("mid", mid)
	m.set_shader_parameter("edge", edge.darkened(0.15))
	m.set_shader_parameter("swirl", swirl)
	m.set_shader_parameter("flow", flow)
	m.set_shader_parameter("bright", 1.0 + intensity * 0.08)
	mi.mesh = VFX._sphere(0.5, 28, 14)   # paylaşılan önbellekli küre (her yayında yeni mesh üretme)
	mi.material_override = m
	mi.scale = Vector3.ONE * size
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# parıltı katmanı
	var g = MeshInstance3D.new()
	var gm = ShaderMaterial.new()
	gm.shader = load("res://shaders/energy.gdshader")
	gm.set_shader_parameter("core", core)
	gm.set_shader_parameter("edge", edge)
	gm.set_shader_parameter("swirl", -swirl * 0.6)
	gm.set_shader_parameter("flow", flow)
	gm.set_shader_parameter("intensity", intensity * 0.12)
	g.mesh = VFX._sphere(0.5, 20, 10)
	g.material_override = gm
	g.scale = Vector3.ONE * 1.18
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.add_child(g)
	VFX._cache[key] = [m, gm]
	return mi


## Sürekli iz bırakan parçacık (merminin çocuğu)
static func trail(parent: Node3D, cols: Array, size: float, amount := 40, life := 0.5, tex: Texture2D = null, add := true) -> GPUParticles3D:
	var p = GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = size * 0.35
	pm.spread = 180.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 1.5
	pm.gravity = Vector3(0, 1.5, 0)
	pm.damping_min = 1.0; pm.damping_max = 2.0
	pm.scale_min = 0.6; pm.scale_max = 1.2
	pm.angle_min = 0; pm.angle_max = 360
	pm.color_ramp = FX._gradient(cols)
	pm.scale_curve = FX._curve([[0.0, 1.0], [1.0, 0.2]])
	p.process_material = pm
	var q = QuadMesh.new()
	q.size = Vector2.ONE * size
	if not add:
		# karışımlı iz = sert kenarlı cel topaklar (alev/su/duman kuyruğu)
		var c: Color = cols[mini(1, cols.size() - 1)]
		var hot = c.s > 0.5 and c.v > 0.7
		q.material = VFX.mat_puff(1.1 if hot else 1.0, 0.25 if hot and c.r > c.b else 0.0, Color.from_hsv(c.h, minf(1.0, c.s + 0.2), c.v * 0.3))
	else:
		q.material = FX._draw_mat(tex if tex else FX.tex_soft, add)
	p.draw_pass_1 = q
	parent.add_child(p)
	p.emitting = true
	return p
