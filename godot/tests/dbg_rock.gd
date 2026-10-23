extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	var v = Game.village("konoha")
	var rock = v.get("hokage_rock", {})
	print("ROCK ", rock, " base=", v["base"])
	var cn = float(rock["y"])
	for x in [float(v["x"]) - 300.0, float(v["x"]), float(v["x"]) + 300.0]:
		var line = "X=%d: " % int(x - float(v["x"]))
		for k in range(-40, 50, 4):
			var p = Game.from_map(Vector2(x, cn + k))
			line += "%d:%d " % [k, int(Game.terrain_height(p.x, p.z) - float(v["base"]))]
		print(line)
	get_tree().quit()
