class_name Mindscape
extends Node3D
## Jinchūriki zihin dünyası: su basmış karanlık kanalizasyon koridoru, devasa kafes, mühür kâğıdı,
## parmaklıkların ardında canavarın gözleri. Dünyanın çok üstünde kurulur (y=7000).

var beast_id = "kurama"
var talk_item := {}
var exit_item := {}
var rig: BeastRig


func spawn_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 40.0)


func _ready() -> void:
	var g = global_position
	talk_item = {"pos": g + Vector3(0, 1, -42), "radius": 10.0, "kind": "beast_talk", "label": "Canavarla konuş"}
	exit_item = {"pos": g + Vector3(0, 1, 52), "radius": 6.0, "kind": "mind_exit", "label": "Zihin dünyasından çık"}
	var wall = Color(0.16, 0.2, 0.18)
	var mb = MB.new()
	# zemin (çarpışmalı) + su
	_static_box(Vector3(0, -0.5, 0), Vector3(44, 1, 130))
	mb.add("box", Vector3(0, -0.5, 0), Vector3(44, 1, 130), Color(0.08, 0.1, 0.1))
	# duvarlar, tavan, borular
	for sx in [-1.0, 1.0]:
		mb.add("box", Vector3(22.5 * sx, 15, 0), Vector3(1, 32, 130), wall)
		_static_box(Vector3(22.5 * sx, 15, 0), Vector3(1, 32, 130))
		for i in 3:
			mb.add("cyl", Vector3(19 * sx, 26 - i * 3.0, 0), Vector3(1.4 - i * 0.2, 128, 1.4 - i * 0.2), Color(0.25, 0.28, 0.24), Vector3(90, 0, 0), 10)
		for z in range(-60, 61, 12):
			mb.add("box", Vector3(21.5 * sx, 8, z), Vector3(1.2, 16, 1.2), wall.darkened(0.3))
	mb.add("box", Vector3(0, 31.5, 0), Vector3(46, 1, 130), wall.darkened(0.4))
	mb.add("box", Vector3(0, 15, 65.5), Vector3(46, 32, 1), wall)
	mb.add("box", Vector3(0, 15, -100), Vector3(46, 32, 1), Color(0.02, 0.02, 0.03))
	# kafes: kalın parmaklıklar + yatay kirişler
	for x in range(-20, 21, 3):
		if absf(x) < 2:
			continue
		mb.add("cyl", Vector3(x, 15, -48), Vector3(0.9, 32, 0.9), Color(0.35, 0.3, 0.22), Vector3.ZERO, 10)
		_static_box(Vector3(x, 15, -48), Vector3(0.9, 32, 0.9))
	for y in [4.0, 16.0, 28.0]:
		mb.add("box", Vector3(0, y, -48), Vector3(44, 0.8, 1.2), Color(0.3, 0.26, 0.2))
	# ortadaki kapı ve mühür kâğıdı
	mb.add("box", Vector3(-1.2, 15, -48), Vector3(1.2, 32, 1.4), Color(0.4, 0.34, 0.25))
	mb.add("box", Vector3(1.2, 15, -48), Vector3(1.2, 32, 1.4), Color(0.4, 0.34, 0.25))
	mb.add("box", Vector3(0, 15, -47.2), Vector3(2.4, 6, 0.1), Color(0.95, 0.93, 0.85))
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(Props.toon())
	add_child(mi)
	var lb = Label3D.new()
	lb.text = "封"
	lb.font_size = 220
	lb.modulate = Color(0.75, 0.05, 0.05)
	lb.position = Vector3(0, 15, -47.1)
	lb.rotation.y = PI
	lb.pixel_size = 0.012
	add_child(lb)
	# su yüzeyi
	var w = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(44, 130)
	w.mesh = pm
	var wm = StandardMaterial3D.new()
	wm.albedo_color = Color(0.08, 0.18, 0.18, 0.75)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.metallic = 0.4
	wm.roughness = 0.05
	w.material_override = wm
	w.position = Vector3(0, 0.05, 0)
	add_child(w)
	# kafesin ardında canavar (karanlıkta, sadece gözler ve hatlar)
	rig = BeastModels.build(beast_id, 42.0 if beast_id != "raiju" else 14.0)
	add_child(rig)
	rig.position = Vector3(0, -10, -78)
	rig.rotation.y = PI   # kafese (oyuncuya) dönük; gövdenin çoğu karanlıkta, baş ve gözler parmaklıkların ardında
	rig.remove_colliders()
	# soluk ışıklar + çıkış ışığı
	for z in [30.0, 0.0, -30.0]:
		var l = OmniLight3D.new()
		l.light_color = Color(0.5, 0.75, 0.7)
		l.light_energy = 1.2
		l.omni_range = 26.0
		l.position = Vector3(0, 20, z)
		add_child(l)
	var cl = OmniLight3D.new()
	var ch: Color = BeastModels.INFO.get(beast_id, {}).get("chakra", Color(1, 0.4, 0.1))
	cl.light_color = ch
	cl.light_energy = 3.0
	cl.omni_range = 50.0
	cl.position = Vector3(0, 18, -62)
	add_child(cl)
	var ex = OmniLight3D.new()
	ex.light_color = Color(1, 1, 0.95)
	ex.light_energy = 3.0
	ex.omni_range = 12.0
	ex.position = Vector3(0, 3, 58)
	add_child(ex)


func _static_box(pos: Vector3, size: Vector3) -> void:
	var b = StaticBody3D.new()
	b.collision_layer = 1
	var cs = CollisionShape3D.new()
	var bx = BoxShape3D.new()
	bx.size = size
	cs.shape = bx
	b.add_child(cs)
	b.position = pos
	add_child(b)
