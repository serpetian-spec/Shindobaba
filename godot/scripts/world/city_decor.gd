class_name CityDecor
extends RefCounted
## Şehir süsleri: rüzgârda sallanan bayraklar (nobori), cadde üstü fener dizileri, kapı fenerleri.
## Gece parıltısı tek yerden yönetilir (VillageLife her saniye glow değerini günceller).

static var glow_mats: Array[ShaderMaterial] = []
static var _shader: Shader


static func _mat(amp: float, hang: float, glow_alpha := false) -> ShaderMaterial:
	if _shader == null:
		_shader = load("res://shaders/cloth_sway.gdshader")
	var m = ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("amp", amp)
	m.set_shader_parameter("hang", hang)
	m.set_shader_parameter("glow_only_alpha", 1.0 if glow_alpha else 0.0)
	return m


static func _ground(p: Vector3) -> float:
	return Game.terrain_height(p.x, p.z)


## Dikey nobori bayrağı: direk + üstten asılı kumaş (amblem şeridi). wp: Godot dünya konumu (zemin)
static func banner(parent: Node3D, wp: Vector3, yaw_deg: float, cloth: Color, band: Color) -> void:
	var g = _ground(wp)
	var root = Node3D.new()
	parent.add_child(root)
	root.global_position = Vector3(wp.x, g, wp.z)
	root.rotation.y = deg_to_rad(-yaw_deg)
	var pole = MB.new()
	pole.add("cyl", Vector3(0, 2.6, 0), Vector3(0.09, 5.2, 0.09), Color(0.32, 0.22, 0.14), Vector3.ZERO, 6)
	pole.add("box", Vector3(0.45, 5.0, 0), Vector3(0.95, 0.06, 0.06), Color(0.32, 0.22, 0.14))
	var pm = MeshInstance3D.new()
	pm.mesh = pole.build(Props.toon())
	root.add_child(pm)
	# kumaş: tepesi y=0 (shader buna göre sallar)
	var c = MB.new()
	c.add("box", Vector3(0, -1.6, 0), Vector3(0.85, 3.2, 0.03), cloth)
	c.add("box", Vector3(0, -0.45, 0.0), Vector3(0.86, 0.35, 0.035), band)
	c.add("box", Vector3(0, -2.4, 0.0), Vector3(0.4, 0.4, 0.04), band)
	var cm = MeshInstance3D.new()
	cm.mesh = c.build(null)
	cm.material_override = _mat(0.22, 3.2)
	cm.position = Vector3(0.48, 4.95, 0)
	cm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(cm)


## İki direk arasında sarkan ip + kâğıt fenerler (geceleri parlar)
static func lantern_string(parent: Node3D, a: Vector3, b: Vector3, count: int, cols: Array) -> void:
	var ga = _ground(a) + 6.2
	var gb = _ground(b) + 6.2
	var pa = Vector3(a.x, ga, a.z)
	var pb = Vector3(b.x, gb, b.z)
	var posts = MB.new()
	for p in [pa, pb]:
		posts.add("cyl", Vector3(p.x, p.y - 3.2, p.z), Vector3(0.18, 6.6, 0.18), Color(0.3, 0.2, 0.13), Vector3.ZERO, 6)
	# ip: sarkık eğriyi kısa parçalarla
	var segs = 10
	var prev = pa
	for i in segs:
		var t = float(i + 1) / segs
		var q = pa.lerp(pb, t) + Vector3.DOWN * sin(t * PI) * 0.9
		var mid = (prev + q) * 0.5
		var d = q - prev
		var yaw = rad_to_deg(atan2(d.x, d.z))
		var pitch = rad_to_deg(atan2(-d.y, Vector2(d.x, d.z).length()))
		posts.add("box", mid, Vector3(0.03, 0.03, d.length()), Color(0.2, 0.15, 0.1), Vector3(pitch, yaw, 0))
		prev = q
	var pm = MeshInstance3D.new()
	pm.mesh = posts.build(Props.toon())
	parent.add_child(pm)
	# tüm fenerler tek mesh (ip ucuna göre yerel); shader x'e göre faz kaydırır
	var mat = _mat(0.08, 2.2, true)
	glow_mats.append(mat)
	var l = MB.new()
	for i in count:
		var t = (float(i) + 0.5) / count
		var q = pa.lerp(pb, t) + Vector3.DOWN * (sin(t * PI) * 0.9 + 0.05) - pa
		var col: Color = cols[i % cols.size()]
		l.add("box", q + Vector3(0, -0.06, 0), Vector3(0.03, 0.12, 0.03), Color(0.2, 0.15, 0.1, 0.0))
		l.add("cyl", q + Vector3(0, -0.15, 0), Vector3(0.36, 0.06, 0.36), Color(0.15, 0.12, 0.1, 0.0), Vector3.ZERO, 10)
		l.add("sphere", q + Vector3(0, -0.45, 0), Vector3(0.42, 0.55, 0.42), Color(col.r, col.g, col.b, 1.0), Vector3.ZERO, 10)
		l.add("cyl", q + Vector3(0, -0.75, 0), Vector3(0.3, 0.06, 0.3), Color(0.15, 0.12, 0.1, 0.0), Vector3.ZERO, 10)
	var lm = MeshInstance3D.new()
	lm.mesh = l.build(null)
	lm.material_override = mat
	lm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lm.visibility_range_end = 500.0
	parent.add_child(lm)
	lm.global_position = pa


## Kapı fenerleri: tek MultiMesh (yüzlerce ev için ucuz); geceleri yanar
static func door_lanterns(parent: Node3D, xforms: Array) -> void:
	if xforms.is_empty():
		return
	var l = MB.new()
	l.add("box", Vector3(0, 0.05, -0.18), Vector3(0.04, 0.04, 0.36), Color(0.2, 0.15, 0.1, 0.0))
	l.add("cyl", Vector3(0, -0.12, 0), Vector3(0.24, 0.05, 0.24), Color(0.15, 0.12, 0.1, 0.0), Vector3.ZERO, 8)
	l.add("cyl", Vector3(0, -0.36, 0), Vector3(0.3, 0.42, 0.3), Color(0.98, 0.9, 0.75, 1.0), Vector3.ZERO, 8)
	l.add("cyl", Vector3(0, -0.6, 0), Vector3(0.24, 0.05, 0.24), Color(0.15, 0.12, 0.1, 0.0), Vector3.ZERO, 8)
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = l.build(null)
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat = _mat(0.04, 0.6, true)
	glow_mats.append(mat)
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 700.0
	parent.add_child(mmi)


## 0 = gündüz, 1 = gece (alacakaranlıkta yumuşak geçiş)
static func set_night(k: float) -> void:
	for m in glow_mats:
		m.set_shader_parameter("glow", k)
