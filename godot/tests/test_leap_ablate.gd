extends Node
## Hızlı ilerlerken kare süresi hangi sistemden geliyor: düz hat boyunca SPEED m/sn ile git, her sistemi 4 sn kapatıp ortalama kareyi ölç.
## LA_FROM="x,y" LA_DIR="dx,dy" (Konoha merkezine göre harita), LA_SPEED
var main: Node
var pl: Player
var pos := Vector2.ZERO
var dir := Vector2(0, -1)
var speed := 70.0
var go := false
var acc := []

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	pl = main.player
	Game.world.env.time_of_day = 0.4
	Game.world.env.weather_t = 999
	var v = Game.village("konoha")
	var f = OS.get_environment("LA_FROM").split(",")
	pos = Vector2(v["x"], v["y"]) + (Vector2(float(f[0]), float(f[1])) if f.size() == 2 else Vector2(0, -1700))
	var d = OS.get_environment("LA_DIR").split(",")
	if d.size() == 2:
		dir = Vector2(float(d[0]), float(d[1])).normalized()
	if OS.get_environment("LA_SPEED") != "":
		speed = float(OS.get_environment("LA_SPEED"))
	pl.respawn(Game.from_map(pos))
	await get_tree().create_timer(4.0).timeout
	go = true
	var cands: Array = []
	for n in Game.world.get_children() + main.actors.get_children() + get_tree().root.get_children():
		if n == self or n == main or n == pl or n == get_tree().current_scene or n.get_script() == null:
			continue
		if n.has_method("_process") or n.has_method("_physics_process"):
			cands.append(n)
	print("LA taban ", await _measure(5.0))
	var res = []
	for n in cands:
		var pm = n.process_mode
		n.process_mode = Node.PROCESS_MODE_DISABLED
		var r = await _measure(3.0)
		n.process_mode = pm
		res.append([r[0], String(n.name), String(n.get_script().resource_path).get_file(), r[1]])
	res.sort_custom(func(a, b): return a[0] < b[0])
	for r in res:
		print("LA kapali %-28s %-24s ort=%.1f ms  en uzun=%.0f" % [r[1], r[2], r[0], r[3]])
	print("LA taban2 ", await _measure(5.0))
	get_tree().quit()

func _measure(sec: float) -> Array:
	acc.clear()
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < sec * 1000.0:
		await get_tree().process_frame
	var tot = 0.0
	var mx = 0.0
	for x in acc:
		tot += x
		mx = maxf(mx, x)
	return [tot / maxf(1, acc.size()), mx, acc.size()]

var _lt := 0
func _process(_dt: float) -> void:
	var now = Time.get_ticks_usec()
	if _lt != 0:
		var ms = (now - _lt) / 1000.0
		acc.append(ms)
		if go:
			pos += dir * speed * ms / 1000.0   # gerçek zamana göre ilerle (kare düşse de hız aynı)
			var p = Game.from_map(pos)
			p.y = Game.ground_height(p.x, p.z)
			pl.global_position = p
			pl.velocity = Vector3.ZERO
	_lt = now
