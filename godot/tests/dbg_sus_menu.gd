extends Node
## Gardıroptaki Susanoo önizlemesi yeni malzemeyle
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	var cl = CanvasLayer.new()
	cl.layer = 100
	add_child(cl)
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.13)
	bg.size = Vector2(2600, 1400)
	cl.add_child(bg)
	var x = 20.0
	for t in [2, 3, 4, 5]:
		var pr = {"susanoo": {"color": Susanoo.COLORS[(t - 2) % 4], "armor": t % 3, "face": t % 3, "weapon": "kilic", "wings": true, "mastery": 99999.0, "tier_pref": t}}
		var sn0 = Susanoo.new()
		var c = Menus._susanoo_preview(pr)
		c.position = Vector2(x, 40)
		c.size = Vector2(600, 1000)
		c.custom_minimum_size = Vector2(600, 1000)
		cl.add_child(c)
		if is_instance_valid(Menus._sus_prev) and Menus._sus_prev.tier != t:
			Menus._sus_prev.build(pr, t)
			Menus._sus_prev.scale = Vector3.ONE * (2.1 / 1.8)
			Menus._sus_prev.position.y = -0.95 * Menus._sus_prev.scale.y * 0.55 if t in [2, 3] else 0.0
		sn0.free()
		x += 620.0
	await get_tree().create_timer(2.0).timeout
	await main.shot("sus_menu")
	get_tree().quit()
