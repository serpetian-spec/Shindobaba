class_name Graveyard
extends Node3D
## Köy mezarlığı: ana kapının dışında, surun ağaçsız şeridinde çitli alan. Ölen dostların adı mezar taşlarında yazar;
## dost ölünce birkaç dakika sonra burada cenaze töreni yapılır (Friends._funeral_tick).

var vid := ""
var item := {}
var center := Vector3.ZERO


## Köyün mezarlık yeri (harita [x, y]); bir kez seçilip kayda yazılır
static func pos_of(v_id: String) -> Vector3:
	var fl: Dictionary = Game.profile.get("flags", {})
	if not fl.has("graveyards"):
		fl["graveyards"] = {}
	var g: Dictionary = fl["graveyards"]
	if g.has(v_id):
		return Game.from_map(Vector2(float(g[v_id][0]), float(g[v_id][1])))
	var v = Game.village(v_id)
	if v.is_empty():
		return Vector3.INF
	var c = Vector2(float(v["x"]), float(v["y"]))
	var r = float(v["r"])
	var wall = (r - 40.0) if v_id == "konoha" else r * 0.95
	var gates: Array = v.get("gates", [180.0])
	var ga = deg_to_rad(float(gates[0] if not gates.is_empty() else 180.0))
	var out = Vector2(sin(ga), cos(ga))
	var side = Vector2(out.y, -out.x)
	var best = c + out * (wall + 45.0) + side * 40.0
	for k in 12:
		var q = c + out * (wall + 40.0 + (k % 3) * 8.0) + side * (40.0 + int(k / 3) * 12.0) * (1.0 if k % 2 == 0 else -1.0)
		var w = Game.from_map(q)
		if Game.road_dist(w.x, w.z) > 18.0 and Game.terrain_height(q.x, -q.y) > 0.8:
			best = q
			break
	g[v_id] = [best.x, best.y]
	return Game.from_map(best)


static func dead_of(v_id: String) -> Array:
	var out = []
	for id in Friends.all():
		var f: Dictionary = Friends.all()[id]
		if String(f.get("status", "")) == "öldü" and String(f.get("village", Progress.home())) == v_id:
			out.append(id)
	out.sort_custom(func(a, b): return float(Friends.all()[a].get("died_t", 0.0)) < float(Friends.all()[b].get("died_t", 0.0)))
	return out


func build(v_id: String) -> void:
	vid = v_id
	center = pos_of(v_id)
	center.y = Game.ground_height(center.x, center.z)
	global_position = center
	var b = MB.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(v_id)
	var gy = func(x: float, z: float) -> float: return Game.ground_height(center.x + x, center.z + z) - center.y
	var wood = Color(0.38, 0.27, 0.18)
	var stone = Color(0.55, 0.55, 0.53)
	# alçak taş çit + giriş
	for side in 4:
		for k in 13:
			var t = -12.0 + k * 2.0
			if side == 0 and absf(t) < 2.0:
				continue
			var p = Vector3(t, 0, 9.0) if side == 0 else (Vector3(t, 0, -9.0) if side == 1 else Vector3(-13.0 if side == 2 else 13.0, 0, t * 0.7))
			b.add("box", p + Vector3(0, gy.call(p.x, p.z) + 0.4, 0), Vector3(2.0 if side < 2 else 0.5, 0.8, 0.5 if side < 2 else 1.5), stone.darkened(0.08 * (k % 3)))
	# giriş fenerleri + küçük tapınak (sunak) + tütsü kabı
	for sx in [-1.0, 1.0]:
		b.add("box", Vector3(sx * 2.4, gy.call(sx * 2.4, 9.5) + 0.7, 9.5), Vector3(0.4, 1.4, 0.4), stone)
		b.add("box", Vector3(sx * 2.4, gy.call(sx * 2.4, 9.5) + 1.55, 9.5), Vector3(0.6, 0.35, 0.6), stone.lightened(0.1))
	b.add("box", Vector3(0, gy.call(0, -6.5) + 0.3, -6.5), Vector3(3.0, 0.6, 2.0), stone.darkened(0.1))
	b.add("box", Vector3(0, gy.call(0, -6.5) + 1.3, -6.5), Vector3(2.0, 1.4, 1.4), wood)
	b.add("prism", Vector3(0, gy.call(0, -6.5) + 2.4, -6.5), Vector3(2.8, 0.9, 2.2), Color(0.22, 0.2, 0.22))
	b.add("cyl", Vector3(0, gy.call(0, -4.6) + 0.35, -4.6), Vector3(0.6, 0.7, 0.6), Color(0.3, 0.28, 0.25), Vector3.ZERO, 10)
	# mezar sıraları: önce dostların taşları (adlı), kalanı eski taşlar
	var dead = dead_of(v_id)
	var slots = []
	for row in 3:
		for col in 7:
			slots.append(Vector3(-9.0 + col * 3.0, 0, 5.0 - row * 3.4))
	for i in slots.size():
		var p: Vector3 = slots[i]
		var g = gy.call(p.x, p.z)
		var named = i < dead.size()
		var h = 1.3 if named else rng.randf_range(0.8, 1.2)
		b.add("box", p + Vector3(0, g + 0.12, 0), Vector3(1.4, 0.24, 1.0), stone.darkened(0.15))
		b.add("box", p + Vector3(0, g + 0.24 + h * 0.5, -0.2), Vector3(0.6, h, 0.35), stone.lightened(0.08 if named else rng.randf() * 0.1))
		b.add("box", p + Vector3(0, g + 0.24 + h + 0.05, -0.2), Vector3(0.7, 0.1, 0.42), stone.darkened(0.05))
		if named:
			var f: Dictionary = Friends.all()[dead[i]]
			for sx in [-0.45, 0.45]:   # çiçekler
				b.add("sphere", p + Vector3(sx, g + 0.35, 0.25), Vector3(0.25, 0.22, 0.25), [Color(0.95, 0.85, 0.3), Color(0.95, 0.95, 0.95), Color(0.85, 0.3, 0.4)][i % 3], Vector3.ZERO, 6)
			var l = Label3D.new()
			l.text = "%s\n%s" % [f["name"], String(f.get("epitaph", "Ateşin İradesi onda yaşadı"))]
			l.font_size = 30
			l.pixel_size = 0.004
			l.outline_size = 6
			l.modulate = Color(0.95, 0.92, 0.85)
			l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			l.visibility_range_end = 14.0
			l.position = p + Vector3(0, g + h + 0.6, 0)
			add_child(l)
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	add_child(mi)
	item = {"pos": center + Vector3(0, 0.4, 7.0), "radius": 7.0, "kind": "graveyard", "label": "[F] Mezarlık", "vid": v_id}
	Interact.add(item)
	tree_exiting.connect(func(): Interact.items.erase(item))


## [F] mezarlıkta: yatanlar ve dua
static func talk(it: Dictionary) -> void:
	var v_id = String(it.get("vid", Progress.home()))
	var dead = dead_of(v_id)
	var lines = []
	for id in dead:
		var f: Dictionary = Friends.all()[id]
		var lg: Array = f.get("log", [])
		lines.append("• %s — %s" % [f["name"], String(lg[-1]) if not lg.is_empty() else "kahramanca öldü"])
	var txt = "Burada %s köyünün düşmüş ninjaları yatıyor." % Game.village(v_id).get("name", v_id)
	if not lines.is_empty():
		txt += "\n" + "\n".join(lines.slice(-6))
	Hud.dialog("Mezarlık", txt, [{"label": "Tütsü yak ve dua et", "cb": func():
		Hud.msg("Tütsünün dumanı göğe yükseliyor... İçin biraz hafifledi.", Color(0.85, 0.85, 0.95), 4.0)
		if Game.player:
			FX.smoke_puff(Game.player.global_position + Game.player.face_dir() * 1.2 + Vector3.UP * 0.6, 0.4, 6)}])
