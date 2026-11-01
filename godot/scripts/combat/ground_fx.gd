class_name GroundFX
extends Node
## Jutsuların dünyaya etkisi: çarpma yerinde 3-5 sn kalan, işlevi olan zemin bölgeleri.
##   wet      (su)    : içindekiler ıslanır (Elements: ıslak + şimşek = çarpılma, ıslak + buz = donma); şimşek ıslak zemine değerse tüm alan çarpılır
##   cracked  (toprak, ağır vuruş): yarık ve moloz — üstünden geçen yavaşlar
##   burning  (ateş)  : yanan zemin — içindekiler tutuşur; rüzgâr değerse büyür, su değerse buhar olur
##   frozen   (buz)   : kırağı — içindekiler üşür, yavaşlar
##   mud      (çamur) : çok yavaşlatır
##   steam    (ateş+su): buhar — içindekiler hedefi kaybeder
## Görseller Storm tarzı: düz su birikintisi, çatlak + kaya, alev dilleri, kırağı, buhar.

static var inst: GroundFX
static var zones: Array = []   # {pos, r, kind, t, caster, node}
const SLOW_KINDS := {"cracked": 0.6, "mud": 1.2, "frozen": 0.6}
var _tick := 0.0


static func _ensure() -> GroundFX:
	if inst == null or not is_instance_valid(inst):
		inst = GroundFX.new()
		inst.name = "GroundFX"
		VFX.scene().add_child(inst)
	return inst


const ENABLED := false


## Bölge ekle. Mevcut bölgelerle etkileşir (ateş+su = buhar, rüzgâr ateşi büyütür).
static func add(pos: Vector3, kind: String, r: float, dur := 4.0, caster: Node3D = null) -> void:
	# kullanıcı isteği (2026-11-01): jutsu bitince yerde kalan bölge/birikinti sistemi tamamen kapalı
	if ENABLED == false or VFX.scene() == null:
		return
	var g = Vector3(pos.x, Game.jutsu_floor(pos.x, pos.z), pos.z)
	if pos.y - g.y > 3.0 + r * 0.3:
		return   # havada patlayan jutsu zemine iz bırakmaz
	_ensure()
	r = clampf(r, 1.0, 14.0)
	# etkileşimler
	for z in zones.duplicate():
		if z["pos"].distance_to(g) > z["r"] + r * 0.6:
			continue
		if (kind == "wet" and z["kind"] == "burning") or (kind == "burning" and z["kind"] == "wet"):
			_remove(z)
			add(g, "steam", maxf(r, z["r"]), 3.0, caster)
			return
		if kind == "wet" and z["kind"] == "wet":   # aynı yere tekrar su: birikinti büyür, süresi uzar
			z["r"] = minf(14.0, maxf(z["r"], r) + 0.5)
			z["t"] = maxf(z["t"], dur)
			_refresh_visual(z)
			return
	var z = {"pos": g, "r": r, "kind": kind, "t": dur, "caster": caster, "node": null}
	z["node"] = _visual(z)
	zones.append(z)


## Rüzgâr çarptı: yakındaki yanan zemin büyür ve uzar
static func wind(pos: Vector3, r: float) -> void:
	for z in zones:
		if z["kind"] == "burning" and z["pos"].distance_to(pos) < z["r"] + r:
			z["r"] = minf(14.0, z["r"] * 1.5)
			z["t"] = maxf(z["t"], 4.0)
			_refresh_visual(z)


## Şimşek çarptı: değdiği ıslak zeminin tamamı elektriklenir, içindekiler çarpılır
static func shock(pos: Vector3, attacker: Node3D, dmg: float) -> void:
	for z in zones:
		if z["kind"] != "wet" or z["pos"].distance_to(pos) > z["r"] + 1.0:
			continue
		var c: Vector3 = z["pos"]
		for i in 8:
			var a = TAU * i / 8.0
			VFX.bolt(c + Vector3.UP * 0.2, c + Vector3(cos(a), 0.1, sin(a)) * z["r"] * randf_range(0.6, 1.0), Color(0.6, 0.85, 1.0), 0.12, 0.3, 2)
		FX.light(c + Vector3.UP, Color(0.6, 0.85, 1.0), 6.0, z["r"] * 2.0, 0.25)
		for f in VFX.tree().get_nodes_in_group("fighters"):
			if not is_instance_valid(f) or f == attacker or (f.has_method("is_dead") and f.is_dead()):
				continue
			if Vector2(f.global_position.x - c.x, f.global_position.z - c.z).length() <= z["r"]:
				if attacker and not Combat.hostile(attacker, f):
					continue
				f.take_hit({"dmg": dmg * 0.6, "element": "", "knock": 2.0, "kind": "light", "attacker": attacker, "hitstop": 0.03})
				if f.has_method("apply_status"):
					f.apply_status("stun", 1.2)
				Combat.popup_text(f.global_position + Vector3.UP * 2.2, "Çarpıldı!", Color(0.6, 0.85, 1.0))


static func kind_at(p: Vector3) -> String:
	for z in zones:
		if Vector2(p.x - z["pos"].x, p.z - z["pos"].z).length() <= z["r"] and absf(p.y - z["pos"].y) < 2.5:
			return z["kind"]
	return ""


static func _remove(z: Dictionary) -> void:
	zones.erase(z)
	var n = z.get("node")
	if is_instance_valid(n):
		var tw = n.create_tween()
		tw.tween_property(n, "scale", Vector3(n.scale.x, 0.01, n.scale.z), 0.4)
		tw.tween_callback(n.queue_free)


static func _refresh_visual(z: Dictionary) -> void:
	var n = z.get("node")
	if is_instance_valid(n):
		n.queue_free()
	z["node"] = _visual(z)


## Storm tarzı zemin görseli
static func _visual(z: Dictionary) -> Node3D:
	var root = Node3D.new()
	VFX.scene().add_child(root)
	root.global_position = z["pos"] + Vector3.UP * 0.04
	var r: float = z["r"]
	match z["kind"]:
		"wet":
			# yassı, düzensiz kenarlı su birikintisi (aynı Storm su malzemesi, düz)
			for i in 3:
				var mi = MeshInstance3D.new()
				mi.mesh = VFX._sphere(0.5, 18, 4)
				mi.material_override = VFX.mat_water(Color(0.1, 0.32, 0.75), Color(0.28, 0.6, 0.98), Color(0.7, 0.9, 1.0), Vector3(1, 0, 0.3), 0.7, 0.35, 0.0)
				var off = Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3)) * r if i > 0 else Vector3.ZERO
				mi.position = off
				mi.scale = Vector3(r * randf_range(1.4, 2.0), 0.03, r * randf_range(1.4, 2.0))
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				root.add_child(mi)
		"cracked":
			VFX.cracks(z["pos"], r * 1.2, Color(0.1, 0.08, 0.06, 0.95), z["t"] + 1.0, false)
			var rm = Props.toon_color(WindFX.dust_col(z["pos"]).darkened(0.35))
			for i in int(4 + r):
				var rk = MeshInstance3D.new()
				rk.mesh = VFX._sphere(0.5, 6, 4)
				rk.material_override = rm
				var a = randf() * TAU
				rk.position = Vector3(cos(a), 0.05, sin(a)) * randf_range(0.3, 1.0) * r
				rk.scale = Vector3(randf_range(0.3, 0.7), randf_range(0.2, 0.45), randf_range(0.3, 0.6)) * clampf(r * 0.35, 0.6, 1.6)
				rk.rotation = Vector3(randf(), randf(), randf())
				root.add_child(rk)
		"burning":
			VFX.cracks(z["pos"], r * 1.1, Color(0.08, 0.04, 0.02, 0.9), z["t"] + 2.0, false)
			var p = FX.burst(Vector3.ZERO, {"parent": root, "local": true, "amount": int(10 + r * 6), "life": 0.6, "tex": FX.tex_spark, "add": false, "size": 2.4,
				"radius": r * 0.8, "vmin": 1.0, "vmax": 2.6, "dir": Vector3.UP, "spread": 12.0, "gravity": Vector3(0, 2.0, 0), "explosive": 0.0,
				"scale_curve": [[0.0, 0.5], [0.35, 1.0], [1.0, 0.3]], "colors": [Color(1, 0.9, 0.4, 0.0), Color(1, 0.75, 0.2, 1), Color(1, 0.35, 0.05, 0.9), Color(0.6, 0.1, 0.02, 0.0)]})
			if p:
				p.one_shot = false
			var e = FX.burst(Vector3.UP * 0.3, {"parent": root, "local": true, "amount": int(6 + r * 2), "life": 0.9, "tex": FX.tex_spark, "size": 0.5, "radius": r * 0.7,
				"vmin": 1.0, "vmax": 3.0, "dir": Vector3.UP, "spread": 30.0, "explosive": 0.0, "colors": [Color(1, 1, 0.8, 1), Color(1, 0.6, 0.15, 1), Color(1, 0.3, 0.05, 0)]})
			if e:
				e.one_shot = false
		"frozen":
			VFX.cracks(z["pos"], r * 1.2, Color(0.75, 0.9, 1.0, 0.75), z["t"] + 1.0, false)
			var mi = MeshInstance3D.new()
			mi.mesh = VFX._sphere(0.5, 16, 4)
			var m = StandardMaterial3D.new()
			m.albedo_color = Color(0.85, 0.95, 1.0, 0.55)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mi.material_override = m
			mi.scale = Vector3(r * 2.0, 0.03, r * 2.0)
			root.add_child(mi)
		"mud":
			var mi = MeshInstance3D.new()
			mi.mesh = VFX._sphere(0.5, 16, 4)
			mi.material_override = Props.toon_color(Color(0.32, 0.24, 0.16))
			mi.scale = Vector3(r * 2.0, 0.05, r * 2.0)
			root.add_child(mi)
		"steam":
			var s = FX.burst(Vector3.UP * 0.4, {"parent": root, "local": true, "amount": int(8 + r * 2), "life": 1.6, "tex": FX.tex_smoke, "add": false, "cel": false, "size": 2.4,
				"radius": r * 0.8, "vmin": 0.5, "vmax": 1.6, "dir": Vector3.UP, "spread": 40.0, "explosive": 0.0,
				"colors": [Color(1, 1, 1, 0.0), Color(0.95, 0.97, 1.0, 0.6), Color(1, 1, 1, 0.0)]})
			if s:
				s.one_shot = false
	return root


func _process(dt: float) -> void:
	if zones.is_empty():
		return
	for z in zones.duplicate():
		z["t"] -= dt
		if z["t"] <= 0.0:
			_remove(z)
	_tick -= dt
	if _tick > 0.0:
		return
	_tick = 0.25
	for f in get_tree().get_nodes_in_group("fighters"):
		if not is_instance_valid(f) or not f.has_method("apply_status"):
			continue
		var k = kind_at(f.global_position)
		match k:
			"wet":
				f.apply_status("wet", 2.0)
			"cracked", "frozen":
				f.apply_status("slow", 0.35)
				if k == "frozen":
					f.apply_status("chill", 0.5)
			"mud":
				f.apply_status("mud", 0.4)
				f.apply_status("slow", 0.4)
			"burning":
				f.apply_status("burn", 1.0)
			"steam":
				if f.has_method("lose_target"):
					f.lose_target(0.5)
