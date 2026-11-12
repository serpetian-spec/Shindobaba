extends Node
## Konoha sokak seviyesi: göz hizasından bakış. SW="x,n,bakış_x,bakış_n;..." (köy yerel koordinatı), SWH=kamera yüksekliği
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	var v = Game.village("konoha")
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.fov = 65.0
	var h = 2.4
	if OS.get_environment("SWH") != "":
		h = float(OS.get_environment("SWH"))
	var spec = OS.get_environment("SW")
	if spec == "":
		spec = "-290,0,-200,0;-200,0,-110,-10;-120,0,-40,8;-60,0,30,-8;40,0,120,-10;120,0,200,-8;200,0,290,6;290,0,200,0;-170,-8,-170,-30;170,-8,170,-30;250,-8,250,-30;-110,8,-110,30;0,-60,0,-200;0,60,0,200;-150,-120,-60,-160;150,120,240,160"
	var i = 0
	for part in spec.split(";", false):
		var f = part.split(",")
		var px = float(f[0]); var pn = float(f[1])
		var at = Vector3(c.x + px, 0, c.z - pn)
		at.y = Game.terrain_height(at.x, at.z)
		var tg = Vector3(c.x + float(f[2]), 0, c.z - float(f[3]))
		tg.y = Game.terrain_height(tg.x, tg.z)
		main.player.respawn(at + Vector3(0, 1.0, 0) - (tg - at).normalized() * 3.0)
		await get_tree().create_timer(2.2).timeout
		cc.global_position = at + Vector3(0, h, 0)
		cc.look_at(tg + Vector3(0, 2.0, 0))
		cc.current = true
		await get_tree().create_timer(0.35).timeout
		await main.shot("sw_%02d" % i)
		i += 1
	print("SW n=", i)
	get_tree().quit()
