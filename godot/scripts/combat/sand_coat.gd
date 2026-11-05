class_name SandCoat
extends RefCounted
## Kum kaplaması: hedefin her mesh'ine material_overlay olarak kum katmanı (pozu/animasyonu izler; kabuk/kürenin yerine).
## Sabaku Kyū: ayaktan boyna tırmanır (baş dışarıda) • Sabaku Sōsō: sıkışıp patlar • Suna no Yoroi: tüm bedende ince katman.

const SHADER := preload("res://shaders/vfx_sand_coat.gdshader")


## Kaplamayı başlat: top_frac = boyun oranı (1.2 = tüm beden), rise = tırmanma süresi. Dönen durum: {"mat", "meshes", "node"}
static func apply(target: Node3D, top_frac: float, rise: float, inflate := 0.03, crack := 1.0) -> Dictionary:
	var m = target.get("model")
	if m == null or not is_instance_valid(m):
		return {}
	var h = float(target.get("height")) if target.get("height") != null else 1.8
	var sc = float(m.get("age_scale")) if m.get("age_scale") != null else 1.0
	var mat = ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("reveal_h", 0.0)
	mat.set_shader_parameter("top_h", h * top_frac / maxf(0.3, sc) * sc)
	mat.set_shader_parameter("inflate", inflate)
	mat.set_shader_parameter("crack", crack)
	var meshes = []
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var g = mi as MeshInstance3D
		if g.mesh == null:
			continue
		if g.material_overlay != null and g.material_overlay.has_meta("sand_coat"):
			continue
		meshes.append([g, g.material_overlay])
		g.material_overlay = mat
	mat.set_meta("sand_coat", true)
	var st = {"mat": mat, "meshes": meshes, "top": h * top_frac, "target": target}
	var tw = target.create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("reveal_h", v), 0.0, h * top_frac + 0.1, maxf(0.05, rise)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	target.set_meta("sand_coat", st)
	return st


## Kum dökülerek çözülür (yukarıdan aşağı), sonra eski overlay geri gelir
static func remove(st: Dictionary, fall := 0.45) -> void:
	if st.is_empty():
		return
	var mat: ShaderMaterial = st["mat"]
	var t: Node3D = st["target"]
	var restore = func():
		for pair in st["meshes"]:
			if is_instance_valid(pair[0]) and pair[0].material_overlay == mat:
				pair[0].material_overlay = pair[1]
		if is_instance_valid(t) and t.has_meta("sand_coat") and t.get_meta("sand_coat") == st:
			t.remove_meta("sand_coat")
	if not is_instance_valid(t) or not t.is_inside_tree():
		restore.call()
		return
	var tw = t.create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("reveal_h", v), float(st["top"]) + 0.1, -0.1, fall).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(restore)


## Sabaku Sōsō: kaplama önce kabarır, sonra hedefin üstüne çöker (ezme anı)
static func squeeze(st: Dictionary, dur := 0.35) -> void:
	if st.is_empty() or not is_instance_valid(st["target"]):
		return
	var mat: ShaderMaterial = st["mat"]
	var tw = (st["target"] as Node3D).create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("inflate", v), 0.03, 0.09, dur * 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_method(func(v): mat.set_shader_parameter("inflate", v), 0.09, -0.005, dur * 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
