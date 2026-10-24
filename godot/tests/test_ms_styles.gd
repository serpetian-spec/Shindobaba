extends Node
## Tüm Mangekyō desen stillerini 2B önizleme ile ızgarada çeker
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	var cl = CanvasLayer.new()
	cl.layer = 100
	add_child(cl)
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.12)
	bg.size = Vector2(1920, 1080)
	cl.add_child(bg)
	for i in Menus.MS_STYLES.size():
		var d = Eyes.random_design()
		d["style"] = i
		d["blades"] = 4
		d["curve"] = 1.2
		d["thick"] = 0.55
		d["inner"] = 0.2
		d["ring"] = false
		d["invert"] = false
		d["spin"] = 0.0
		var pv = ColorRect.new()
		pv.size = Vector2(240, 240)
		pv.position = Vector2(20 + (i % 6) * 310, 20 + (i / 6) * 350)
		var sm = ShaderMaterial.new()
		sm.shader = load("res://shaders/ms_preview.gdshader")
		var vv = Eyes.design_vecs(d)
		sm.set_shader_parameter("ms_a", vv[0])
		sm.set_shader_parameter("ms_b", vv[1])
		sm.set_shader_parameter("col", vv[2])
		pv.material = sm
		cl.add_child(pv)
		var l = Label.new()
		l.text = "%d %s" % [i + 1, Menus.MS_STYLES[i]]
		l.position = pv.position + Vector2(0, 250)
		l.add_theme_font_size_override("font_size", 24)
		cl.add_child(l)
	await get_tree().create_timer(0.5).timeout
	await main.shot("ms_styles")
	get_tree().quit()
