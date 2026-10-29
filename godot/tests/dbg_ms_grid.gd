extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	var layer = CanvasLayer.new()
	layer.layer = 100
	main.add_child(layer)
	var bg = ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.14)
	bg.size = Vector2(2560, 1440)
	layer.add_child(bg)
	var sh = load("res://shaders/ms_preview.gdshader")
	var start = int(OS.get_environment("MS0")) if OS.get_environment("MS0") != "" else 0
	for i in 48 - start:
		var st = start + i
		var cr = ColorRect.new()
		var m = ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("ms_a", Vector4(st, 3, 1.0, 0.55))
		m.set_shader_parameter("ms_b", Vector4(0.2, 0.0, 0.0, 0.0))
		m.set_shader_parameter("col", Color(0.9, 0.05, 0.06))
		cr.material = m
		cr.size = Vector2(120, 120)
		cr.position = Vector2(10 + (i % 10) * 130, 10 + int(i / 10) * 150)
		layer.add_child(cr)
		var l = Label.new()
		l.text = str(st)
		l.position = cr.position + Vector2(45, 118)
		l.add_theme_font_size_override("font_size", 18)
		layer.add_child(l)
	await get_tree().create_timer(0.5).timeout
	await main.shot("ms_grid")
	get_tree().quit()
