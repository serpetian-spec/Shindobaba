class_name JutsuEngine
extends RefCounted
## Veri güdümlü jutsu motoru: elle yazılmış j_<id> yoksa Jutsu.execute buraya düşer.
## Her jutsu = şekil (shape) × element(ler) × güç kademesi (E..S → tier 0..5) × isimden çıkan görsel varyant.
## Mermiler/duvarlar/akışlar element çarpışma sistemine (Elements/Projectile) otomatik katılır.

const DMG := [8.0, 12.0, 18.0, 26.0, 36.0, 50.0]
const CAT_COLOR := {
	"genjutsu": Color(0.7, 0.35, 0.95), "medical": Color(0.4, 1.0, 0.55), "fuinjutsu": Color(0.25, 0.3, 0.55),
	"space_time": Color(0.55, 0.3, 0.9), "senjutsu": Color(1.0, 0.6, 0.2), "taijutsu": Color(1.0, 0.95, 0.85),
	"dojutsu": Color(0.95, 0.15, 0.15), "summoning": Color(0.9, 0.9, 0.9), "kinjutsu": Color(0.6, 0.1, 0.25),
}
const NATURE_COLOR := {"inton": Color(0.35, 0.2, 0.5), "yang": Color(1.0, 0.85, 0.4), "onmyoton": Color(0.9, 0.9, 0.95),
	"shoton": Color(0.85, 0.55, 0.95), "jinton": Color(0.95, 0.95, 1.0), "futton": Color(0.85, 0.9, 0.95), "jiton": Color(0.75, 0.6, 0.3)}


# ------------------------------------------------------------------ yardımcılar
static func J() -> Node:
	return Engine.get_main_loop().root.get_node("/root/Jutsu")


static func tree() -> SceneTree:
	return Engine.get_main_loop()


static func scene() -> Node:
	return tree().current_scene


static func color_of(d: Dictionary) -> Color:
	var el: String = d.get("element", "")
	if el != "":
		return Elements.color_of(el)
	for n in d.get("natures", []):
		if NATURE_COLOR.has(n):
			return NATURE_COLOR[n]
	return CAT_COLOR.get(d.get("category", ""), Color(0.6, 0.85, 1.0))


## İsim/açıklamadan görsel varyant (aynı şekil farklı görünsün)
static func variant(d: Dictionary) -> String:
	var s = (String(d.get("name_en", "")) + " " + String(d.get("name", ""))).to_lower()
	for pair in [["dragon", "dragon"], ["ryu", "dragon"], ["shark", "shark"], ["same", "shark"], ["bird", "bird"], ["phoenix", "bird"], ["crow", "bird"],
			["hawk", "bird"], ["swallow", "bird"], ["tiger", "beast"], ["wolf", "beast"], ["lion", "beast"], ["hound", "beast"], ["beast", "beast"],
			["rain", "barrage"], ["thousand", "barrage"], ["barrage", "barrage"], ["hail", "barrage"], ["shower", "barrage"], ["meteor", "barrage"],
			["needle", "needles"], ["senbon", "needles"], ["spear", "spear"], ["arrow", "needles"], ["lance", "spear"], ["spike", "spikes"],
			["shuriken", "disc"], ["sickle", "disc"], ["cutter", "disc"], ["blade", "disc"], ["slash", "disc"],
			["wave", "wave"], ["tsunami", "wave"], ["flood", "wave"], ["waterfall", "wave"],
			["tornado", "tornado"], ["whirlwind", "tornado"], ["vortex", "tornado"], ["cyclone", "tornado"], ["typhoon", "tornado"],
			["dome", "dome"], ["wall", "wall"], ["barrier", "dome"], ["shield", "wall"], ["rampart", "wall"],
			["prison", "prison"], ["cage", "prison"], ["coffin", "prison"], ["chain", "chains"], ["shadow", "shadow"], ["root", "roots"], ["tree", "roots"],
			["mist", "mist"], ["fog", "mist"], ["cloud", "mist"], ["smoke", "mist"], ["ash", "mist"], ["swamp", "swamp"], ["mud", "swamp"],
			["explo", "explosion"], ["bomb", "explosion"], ["blast", "explosion"], ["laser", "laser"], ["beam", "laser"], ["ray", "laser"], ["cannon", "laser"],
			["breath", "stream"], ["flame", "stream"], ["spray", "stream"], ["rasengan", "sphere"], ["sphere", "sphere"], ["chidori", "lightning_hand"],
			["lightning blade", "lightning_hand"], ["gate", "gates"], ["lotus", "lotus"], ["kick", "kick"], ["fist", "fist"], ["palm", "palm"], ["punch", "fist"]]:
		if s.contains(pair[0]):
			return pair[1]
	return ""


static func power(c: Node3D, d: Dictionary) -> float:
	var el: String = d.get("element", "")
	var m = J()._mult(c) * (J()._elem_bonus(c, el) if el != "" else 1.0)
	if c is Player:
		m *= Stats.jutsu_cat_mult(Game.profile, String(d.get("category", "")), el)
	return m


static func base_dmg(c: Node3D, d: Dictionary) -> float:
	return DMG[clampi(int(d.get("tier", 2)), 0, 5)] * power(c, d)


static func glow_mat(col: Color, alpha := 1.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(1, 1, 1, alpha)
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func info(c: Node3D, d: Dictionary, mul := 1.0, extra := {}) -> Dictionary:
	var el: String = d.get("element", "")
	var t = int(d.get("tier", 2))
	var inf = {"dmg": base_dmg(c, d) * mul, "element": el, "knock": 4.0 + t * 2.0, "launch": 1.0 + t * 0.6,
		"kind": "heavy" if t >= 3 else "light", "hitstop": 0.03 + t * 0.012}
	if el in ["katon", "yoton", "shakuton"]:
		inf["burn"] = 1.5 + t * 0.4
	if el in ["raiton", "ranton"] and t >= 2:
		inf["stun"] = 0.3 + t * 0.12
	inf.merge(extra, true)
	return inf


## Jutsuya özgü sabit varyasyon (renk tonu, boyut, adet, hız): aynı şekil/elementteki iki jutsu aynı görünmesin
static func vary(d: Dictionary) -> Dictionary:
	var h = hash(String(d.get("id", d.get("name", ""))))
	var r = func(k: int) -> float: return float((h >> (k * 5)) & 31) / 31.0
	return {"hue": (r.call(0) - 0.5) * 0.06, "size": 0.85 + r.call(1) * 0.35, "count": 0.8 + r.call(2) * 0.5, "speed": 0.85 + r.call(3) * 0.3,
		"pick": int((h >> 21) & 7), "light": (r.call(4) - 0.5) * 0.2}


static func vcolor(d: Dictionary) -> Color:
	var c = color_of(d)
	var v = vary(d)
	return Color.from_hsv(fposmod(c.h + v["hue"], 1.0), c.s, clampf(c.v + v["light"] * 0.5, 0.15, 1.0))


## Elemente göre çarpma (patlama / sıçrama / buz kırığı / rüzgar patlaması / şimşek / kaya)
## Destan ölçeği: rütbe (E küçük … S devasa) × ustalık (oyuncu seviyesi). İmza element jutsuları rütbesinden büyük görünür.
const SIGNATURE_SCALE := {"katon_goukakyuu": 1.9, "katon_karyuu": 1.6, "fuuton_daitoppa": 1.7, "katon_housenka": 1.3, "suiton_suikoudan": 1.4,
	"fuuton_shinkuu": 1.3, "doton_doryuusou": 1.4, "suiton_suijinheki": 1.5}


static func grand(c: Node3D, d: Dictionary) -> float:
	var t = clampi(int(d.get("tier", 2)), 0, 5)
	var g: float = [0.7, 0.85, 1.15, 1.4, 1.75, 2.2][t]
	g = maxf(g, float(SIGNATURE_SCALE.get(String(d.get("id", "")), 0.0)))
	if c is Player:
		g *= 0.9 + clampf(float(Game.profile.get("level", 1)), 1.0, 60.0) / 60.0 * 0.3
	return g


static func impact_for(el: String, pos: Vector3, col: Color, s := 1.0) -> void:
	VFX.linger(pos, el, col, VFX.epic * s)
	match el:
		"katon", "yoton", "bakuton", "shakuton":
			VFX.explosion(pos, 0.5 * s + 0.3, col)
		"suiton", "futton":
			VFX.splash(pos, 1.2 * s + 0.6)
			VFX.star(pos, Color(0.6, 0.85, 1.0), 2.2 * s, 0.15)
		"hyoton":
			VFX.debris(pos, Color(0.75, 0.92, 1.0), int(10 * s) + 4, 11.0, 0.35)
			VFX.star(pos, Color(0.8, 0.95, 1.0), 2.6 * s, 0.18)
			VFX.shockwave(pos, Color(0.85, 0.97, 1.0), 6.0 * s, 0.35, false)
		"fuuton", "jinton":
			VFX.shockwave(pos, Color(0.9, 1.0, 0.95), 6.0 * s, 0.3, false)
			VFX.star(pos, Color(0.85, 1.0, 0.92), 2.2 * s, 0.14)
			FX.burst(pos, {"amount": int(18 * s), "life": 0.35, "tex": FX.tex_spark, "size": 1.8, "vmin": 10, "vmax": 20, "colors": [Color(1, 1, 1, 0.9), Color(0.8, 1, 0.9, 0)]})
		"raiton", "ranton":
			VFX.star(pos, col.lightened(0.3), 3.0 * s, 0.18)
			for k in 3 + int(s * 2):
				var dd = Vector3(randf_range(-1, 1), randf_range(-0.3, 1), randf_range(-1, 1)).normalized()
				VFX.bolt(pos, pos + dd * randf_range(2.5, 5.0) * s, col, 0.12 * s + 0.05, 0.2, 1)
			VFX.shockwave(pos, col, 6.0 * s, 0.3, false)
		"doton", "mokuton", "jiton", "shoton":
			VFX.debris(pos, col.darkened(0.2) if el != "shoton" else col, int(10 * s) + 4, 12.0, 0.45)
			VFX.cracks(pos, 3.0 * s)
			FX.dust(pos, 1.2 * s)
			VFX.star(pos, col.lightened(0.3), 2.4 * s, 0.15)
		_:
			FX.impact(pos, col, 0.6 * s + 0.2)


## Varyanta göre mermi gövdesi (ileri = -Z), element malzemesiyle
static func shape_mesh(v: String, col: Color, size: float, el := "") -> Node3D:
	var ep = VFX.epic
	VFX.epic = 1.0
	var root = Node3D.new()
	var mat: Material = VFX.element_mat(el, col) if el != "" else VFX.mat_spiral(col.lightened(0.5), col, 4.0, 2.0, 5.0, 1.5, Vector3(0, 0, 1))
	var eye = Color(1, 1, 0.75) if not el in ["suiton", "hyoton"] else Color(0.9, 1, 1)
	var b = MB.new()
	match v:
		"dragon":
			root.add_child(VfxSerpent.dragon_head(mat, 1.0, eye))
		"shark":
			b.add("sphere", Vector3.ZERO, Vector3(0.8, 0.7, 1.8), Color.WHITE, Vector3.ZERO, 12)
			b.add("cone", Vector3(0, 0.55, 0.1), Vector3(0.14, 0.7, 0.5), Color.WHITE, Vector3(-20, 0, 0), 4)
			b.add("cone", Vector3(0, 0, 1.05), Vector3(0.6, 0.7, 0.14), Color.WHITE, Vector3(90, 0, 0), 4)
			for sx in [-1.0, 1.0]:
				b.add("cone", Vector3(0.45 * sx, -0.15, 0.0), Vector3(0.12, 0.6, 0.35), Color.WHITE, Vector3(0, 0, -70 * sx), 4)
			var body = VFX._mi(b.build(null), mat)
			root.add_child(body)
			var t = MB.new()   # dişli ağız + gözler
			for k in 6:
				t.add("cone", Vector3(-0.25 + k * 0.1, -0.12, -0.82), Vector3(0.05, 0.14, 0.05), Color(1, 1, 1), Vector3(180, 0, 0), 4)
			for sx in [-1.0, 1.0]:
				t.add("sphere", Vector3(0.3 * sx, 0.12, -0.6), Vector3(0.1, 0.1, 0.08), eye, Vector3.ZERO, 6)
			root.add_child(VFX._mi(t.build(glow_mat(Color.WHITE)), null))
		"bird":
			b.add("cone", Vector3.ZERO, Vector3(0.35, 1.2, 0.35), Color.WHITE, Vector3(-90, 0, 0), 6)
			b.add("cone", Vector3(0, 0, 0.7), Vector3(0.5, 0.6, 0.1), Color.WHITE, Vector3(90, 0, 0), 4)
			root.add_child(VFX._mi(b.build(null), mat))
			for sx in [-1.0, 1.0]:
				var w = MB.new()
				w.add("box", Vector3(0.55 * sx, 0, 0.1), Vector3(1.1, 0.05, 0.5), Color.WHITE, Vector3(0, 15 * sx, 0))
				var wi = VFX._mi(w.build(null), mat)
				root.add_child(wi)
				var tw = wi.create_tween().set_loops()
				tw.tween_property(wi, "rotation:z", 0.6 * sx, 0.12)
				tw.tween_property(wi, "rotation:z", -0.4 * sx, 0.12)
		"beast":
			b.add("sphere", Vector3.ZERO, Vector3(1.1, 0.95, 1.3), Color.WHITE, Vector3.ZERO, 10)
			b.add("box", Vector3(0, -0.15, -0.75), Vector3(0.55, 0.4, 0.7), Color.WHITE, Vector3(8, 0, 0))
			b.add("box", Vector3(0, -0.4, -0.65), Vector3(0.5, 0.15, 0.6), Color.WHITE, Vector3(22, 0, 0))
			for sx in [-1.0, 1.0]:
				b.add("cone", Vector3(0.35 * sx, 0.55, 0.15), Vector3(0.22, 0.55, 0.22), Color.WHITE, Vector3(-10, 0, -20 * sx), 5)
			root.add_child(VFX._mi(b.build(null), mat))
			var t = MB.new()
			for sx in [-1.0, 1.0]:
				t.add("cone", Vector3(0.18 * sx, -0.35, -1.05), Vector3(0.07, 0.32, 0.07), Color(1, 1, 1), Vector3(180, 0, 0), 4)
				t.add("sphere", Vector3(0.3 * sx, 0.15, -0.55), Vector3(0.16, 0.08, 0.1), eye, Vector3(0, 0, 15 * sx), 6)
			root.add_child(VFX._mi(t.build(glow_mat(Color.WHITE)), null))
		"needles", "spear":
			b.add("cyl", Vector3.ZERO, Vector3(0.09, 1.7, 0.09), Color.WHITE, Vector3(90, 0, 0), 6)
			b.add("cone", Vector3(0, 0, -1.0), Vector3(0.16, 0.45, 0.16), Color.WHITE, Vector3(-90, 0, 0), 6)
			root.add_child(VFX._mi(b.build(null), mat))
		"disc":
			var disc = VFX._mi(VFX._sphere(0.5, 24, 6), mat)
			disc.scale = Vector3(1.8, 0.08, 1.8)
			root.add_child(disc)
			for k in 4:
				var bl = MB.new()
				bl.add("cone", Vector3(0.9, 0, 0), Vector3(0.3, 1.2, 0.06), Color.WHITE, Vector3(0, 0, -90), 4)
				var bi = VFX._mi(bl.build(null), mat)
				bi.rotation.y = k * PI * 0.5
				root.add_child(bi)
		_:
			root.add_child(VFX.element_core(el, col, 1.0))
	root.scale = Vector3.ONE * size * ep
	VFX.epic = ep
	return root


static func spawn_projectile(c: Node3D, d: Dictionary, start: Vector3, dir: Vector3, v: String, size: float, speed: float, inf: Dictionary, homing: Node3D = null) -> Projectile:
	var col = vcolor(d)
	var el: String = d.get("element", "")
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = dir * speed
	pr.radius = maxf(0.25, size * 0.6)
	pr.life = 2.6
	pr.info = inf
	if homing:
		pr.homing = homing
		pr.homing_turn = 2.2
	if v == "disc":
		pr.pierce = true
		pr.spin = Vector3(0, 14.0, 0)
	pr.add_child(shape_mesh(v, col, size, el))
	# element kuyruğu: sert kenarlı cel topaklar
	var tc = [col.lightened(0.5), col, Color(col.r, col.g, col.b, 0)]
	if el in ["katon", "yoton", "shakuton", "bakuton"]:
		var p: Array = VFX.FIRE_PRESETS[VFX.fire_preset_for(col) if el != "yoton" else "lava"]
		tc = [p[0], p[2], p[3], Color(p[4].r, p[4].g, p[4].b, 0)]
	Projectile.trail(pr, tc, size * 0.9 * minf(VFX.epic, 1.8), 34, 0.4, FX.tex_smoke, el in ["fuuton", "raiton", "ranton", "jinton"])
	if v == "dragon":
		var body = VfxSerpent.new()
		body.head = pr
		body.count = 9 + int(size * 2)
		body.spacing = size * 0.75
		body.radius = size * 0.6
		body.mat = VFX.element_mat(el, col) if el != "" else VFX.mat_spiral(col.lightened(0.5), col)
		body.fin_mat = body.mat
		scene().add_child(body)
		var t0 = randf() * TAU
		pr.on_tick = func(p: Projectile, dt: float) -> void:
			var side = p.vel.cross(Vector3.UP).normalized()
			p.global_position += side * sin(Time.get_ticks_msec() * 0.006 + t0) * dt * 5.0
	var t = int(d.get("tier", 2))
	pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
		var r = 1.5 + t * 0.6 + (1.5 if v in ["dragon", "beast", "shark"] else 0.0)
		impact_for(el, pos, col, 0.6 + t * 0.18 + (0.5 if v in ["dragon", "beast", "shark"] else 0.0))
		if t >= 2 or v in ["dragon", "beast", "shark"]:
			Combat.hit_sphere(c, pos, r, inf.merged({"dmg": inf["dmg"] * 0.5}, true), pr.hit_list)
	scene().add_child(pr)
	pr.global_position = start
	if v in ["", "dragon", "beast", "spear", "shark"] or size > 0.8:
		VFX.element_trail(pr, el, col, size * 1.1)
	return pr


# ------------------------------------------------------------------ giriş noktası
static func cast(c: Node3D, id: String, t: Node3D) -> void:
	var d: Dictionary = Data.jutsu.get(id, {})
	if d.is_empty():
		return
	var shape: String = d.get("shape", "projectile")
	var v = variant(d)
	match shape:
		"projectile":
			_projectile(c, d, t, v)
		"beam":
			if v == "stream":
				J()._stream(c, t, 1.0 + int(d.get("tier", 2)) * 0.25, color_of(d), d.get("element", ""), base_dmg(c, d) * 0.22, _snd(d))
			else:
				_beam(c, d, t)
		"aoe":
			if v == "stream":
				J()._stream(c, t, 1.2 + int(d.get("tier", 2)) * 0.3, color_of(d), d.get("element", ""), base_dmg(c, d) * 0.25, _snd(d))
			elif v == "tornado":
				_tornado(c, d, t)
			elif v == "wave":
				_wave(c, d, t)
			elif v == "barrage":
				_barrage(c, d, t)
			elif v in ["spikes", "roots"] or (d.get("element", "") in ["doton", "mokuton", "shoton"] and v == ""):
				_spikes(c, d, t)
			else:
				_aoe(c, d, t, v)
		"wall":
			if v == "dome":
				_dome(c, d)
			else:
				_wall(c, d, t)
		"bind", "debuff":
			_bind(c, d, t, v, shape == "debuff")
		"genjutsu_stun":
			_genjutsu(c, d, t)
		"summon":
			_summon(c, d)
		"buff", "mode", "utility":
			_buff(c, d, shape)
		"clone":
			_clone(c, d)
		"seal":
			_seal(c, d, t)
		"field":
			_field(c, d, t, v)
		"transform":
			if String(d.get("name_en", "")).to_lower().contains("transformation"):
				J().j_henge(c, t)
			else:
				_buff(c, d, "transform")
		"stealth":
			_stealth(c, d)
		"sensor":
			_sensor(c, d)
		"trap":
			_trap(c, d, t)
		"teleport":
			_teleport(c, d, t)
		"counter":
			_counter(c, d)
		"heal", "revive":
			_heal(c, d, shape == "revive")
		"melee", "rush", "dash":
			_melee(c, d, t, v, shape)
		_:
			_projectile(c, d, t, v)


static func _snd(d: Dictionary) -> String:
	match d.get("element", ""):
		"katon", "yoton", "shakuton", "bakuton": return "fire"
		"suiton", "hyoton", "futton": return "water"
		"fuuton", "jinton": return "wind"
		"raiton", "ranton": return "chidori"
		"doton", "mokuton", "jiton", "shoton": return "earth"
	return "whoosh"


# ------------------------------------------------------------------ şekiller
static func _projectile(c: Node3D, d: Dictionary, t: Node3D, v: String) -> void:
	var tier = int(d.get("tier", 2))
	var dir: Vector3 = J()._aim(c, t)
	var start: Vector3 = J()._cast_origin(c, String(d.get("id", ""))) + dir * 0.8
	Sfx.play(_snd(d), start)
	var vc = vcolor(d)
	var vr = vary(d)
	VFX.puffs(start, {"amount": 12, "life": 0.3, "size": 0.9, "vmin": 4, "vmax": 9, "dir": dir, "spread": 30.0, "damp": 3.0,
		"colors": [vc.lightened(0.5), vc, Color(vc.r, vc.g, vc.b, 0)]})
	VFX.star(start, vc.lightened(0.3), 1.2, 0.1)
	tier = clampi(tier, 0, 5)
	match v:
		"needles", "barrage":
			var n = 4 + tier * 2
			for i in n:
				var dd = dir.rotated(Vector3.UP, deg_to_rad(randf_range(-12, 12))) + Vector3.UP * randf_range(-0.05, 0.08)
				spawn_projectile(c, d, start + Vector3(randf_range(-0.4, 0.4), randf_range(-0.3, 0.3), 0), dd.normalized(), "needles", 0.35, 38.0,
					info(c, d, 1.6 / n, {"knock": 1.5, "kind": "light"}))
		"bird":
			var n = 2 + tier / 2
			for i in n:
				var dd = dir.rotated(Vector3.UP, deg_to_rad(-20 + 40.0 * i / maxf(1, n - 1)))
				spawn_projectile(c, d, start, dd, "bird", 0.6 + tier * 0.1, 22.0, info(c, d, 1.2 / n), t)
		"disc":
			spawn_projectile(c, d, start, dir, "disc", 0.7 + tier * 0.25, 26.0, info(c, d, 0.9))
		"dragon", "shark", "beast":
			spawn_projectile(c, d, start, dir, v, 1.2 + tier * 0.35, 18.0 + tier, info(c, d, 1.3), t if v == "shark" else null)
		"spear":
			spawn_projectile(c, d, start, dir, "spear", 0.9 + tier * 0.2, 34.0, info(c, d, 1.1))
		_:
			var nb = 1 if vr["pick"] < 5 else (2 if vr["pick"] < 7 else 3)
			for i in nb:
				var dd = dir.rotated(Vector3.UP, deg_to_rad((i - (nb - 1) * 0.5) * 9.0))
				spawn_projectile(c, d, start, dd, "", (0.6 + tier * 0.28) * vr["size"] / sqrt(nb), 24.0 * vr["speed"], info(c, d, 1.0 / nb))


## Işın: elden nişangâha uzanan, sürekli hasar veren ve karşı mermileri çarpıştıran sütun
static func _beam(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var col = vcolor(d)
	var el: String = d.get("element", "")
	var dur = 0.8 + tier * 0.2
	var width = (0.22 + tier * 0.09) * vary(d)["size"]
	var beam: Node3D
	var bolt: Arcs = null
	if el in ["raiton", "ranton"]:
		beam = Node3D.new()
		scene().add_child(beam)
		bolt = VFX.bolt(c.global_position, c.global_position + Vector3.UP, col, width * 0.9, 0.0, 3 + tier)
	else:
		var cm = CylinderMesh.new()
		cm.top_radius = 0.5; cm.bottom_radius = 0.5; cm.height = 1.0; cm.radial_segments = 16; cm.rings = 4
		cm.cap_top = false; cm.cap_bottom = false
		var m: Material
		match el:
			"katon", "yoton", "shakuton", "bakuton":
				m = VFX.mat_fire(VFX.fire_preset_for(col) if el != "yoton" else "lava", 5.0, 1.6, 0.3, 1.4, 0.15, Vector3(0, 1, 0))
			"suiton", "futton", "hyoton":
				m = VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.7, 0.92, 1.0), Vector3(0, 1, 0), 0.9, 0.7, 0.1)
			"fuuton", "jinton":
				m = VFX.mat_wind(Color(0.85, 1.0, 0.95), 14.0, 8.0, Vector3.UP, 0.95)
			_:
				m = VFX.mat_spiral(col.lightened(0.6), col, 6.0, 8.0, 10.0, 2.0)
		beam = VFX._mi(cm, m)
		scene().add_child(beam)
		var inner = VFX._mi(cm, VFX.mat_spiral(Color(1, 1, 1), col.lightened(0.2), 4.0, 6.0, 14.0, 1.6))
		inner.scale = Vector3(0.45, 1, 0.45)
		beam.add_child(inner)
	var vis_w = minf(VFX.epic, 2.0)   # ışın görsel kalınlığı (isabet genişliği aynı)
	Sfx.play(_snd(d), c.global_position, 0.8)
	if c is Player:
		VFX.screen_lines(dur, 0.45, col.lightened(0.5))
	var st = {"t": 0.0}
	var inf = info(c, d, 0.12)
	var timer = Timer.new()
	timer.wait_time = 0.05
	scene().add_child(timer)
	timer.timeout.connect(func():
		st["t"] += 0.05
		if not is_instance_valid(c) or st["t"] > dur:
			beam.queue_free()
			if bolt and is_instance_valid(bolt):
				bolt.queue_free()
			timer.queue_free()
			return
		var dir: Vector3 = J()._aim(c, t)
		var from: Vector3 = J()._cast_origin(c, String(d.get("id", "")))
		var length = 40.0
		var hit = c.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + dir * length, 1))
		if not hit.is_empty():
			length = from.distance_to(hit["position"])
		var grow = minf(1.0, st["t"] / 0.15)
		var w = width * 2.0 * vis_w * (1.0 + 0.12 * sin(st["t"] * 40.0)) * grow
		if bolt and is_instance_valid(bolt):
			bolt.global_position = from
			bolt.to_point = dir * length
		else:
			beam.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)) * Basis.from_scale(Vector3(w, length, w)), from + dir * length * 0.5)
		for k in int(length / 2.0):
			Combat.hit_sphere(c, from + dir * (1.0 + k * 2.0), width + 0.6, inf)
		for pr in tree().get_nodes_in_group("projectiles"):
			if pr.dead or pr.element() == "" or pr.shooter == null or not is_instance_valid(pr.shooter) or not Combat.hostile(c, pr.shooter):
				continue
			var rel: Vector3 = pr.global_position - from
			var along = rel.dot(dir)
			if along > 0.0 and along < length and (rel - dir * along).length() < width + pr.radius:
				var r = Elements.clash({"el": el, "pow": inf["dmg"] * 8.0}, {"el": pr.element(), "pow": pr.power()})
				Elements.clash_fx(pr.global_position, r["effect"], el, pr.element(), pr.radius)
				pr.apply_clash(r["b_alive"], r["b_scale"])
		var tip = from + dir * length
		if int(st["t"] * 20) % 3 == 0:
			VFX.star(tip, col.lightened(0.3), 1.5 + width * 3.0, 0.12)
			VFX.puffs(tip, {"amount": 5, "life": 0.35, "size": 0.9, "vmin": 3, "vmax": 7, "colors": [col.lightened(0.5), col, Color(col.r, col.g, col.b, 0)]}))
	timer.start()


static func _aoe(c: Node3D, d: Dictionary, t: Node3D, v: String) -> void:
	var tier = int(d.get("tier", 2))
	var col = vcolor(d)
	var vr = vary(d)
	var r = (3.5 + tier * 1.3) * vr["size"]
	var rng_s = String(d.get("range", "")).to_lower()
	var far = rng_s.contains("long") or rng_s.contains("mid") or v == "explosion"
	var pos: Vector3 = J()._aim_ground(c, t, 10.0, 30.0) if far else c.global_position
	pos = J()._ground(pos)
	var inf = info(c, d, 1.2)
	var el: String = d.get("element", "")
	if el in ["raiton", "ranton"]:
		# fırtına bulutu toplanır, gökten yıldırımlar iner
		var sky = pos + Vector3.UP * 16.0
		VFX.puffs(sky, {"amount": 22, "life": 1.6, "size": 5.0, "radius": r * 0.8, "vmin": 0.3, "vmax": 1.2, "gravity": Vector3.ZERO, "spin": 20.0,
			"outline_col": Color(0.05, 0.05, 0.1), "colors": [Color(0.2, 0.2, 0.28, 0), Color(0.22, 0.22, 0.3, 1), Color(0.3, 0.3, 0.38, 0.9), Color(0.3, 0.3, 0.4, 0)]})
		for k in int((3 + tier) * vr["count"]):
			var p = pos + Vector3(randf_range(-r, r), 0, randf_range(-r, r)) * 0.7
			tree().create_timer(0.35 + k * 0.09).timeout.connect(func():
				VFX.bolt(p + Vector3(randf_range(-2, 2), 16.0, randf_range(-2, 2)), p, col, 0.3, 0.22, 2)
				VFX.star(p + Vector3.UP * 0.5, col.lightened(0.3), 2.8, 0.15)
				VFX.shockwave(p + Vector3.UP * 0.1, col, 5.0, 0.3)
				VFX.cracks(p, 2.0)
				Combat.hit_sphere(c, p + Vector3.UP, 2.2, inf.merged({"dmg": inf["dmg"] / 3.0}, true)))
		Sfx.play("thunder", pos)
		if Game.world:
			Game.world.env.screen_flash(0.12)
	else:
		match el:
			"katon", "bakuton", "yoton", "shakuton":
				VFX.explosion(pos + Vector3.UP, (0.8 + tier * 0.35) * vr["size"], col)
			"suiton", "futton":
				VFX.splash(pos + Vector3.UP, r * 0.6)
				_wave_ring(pos, r * 2.2, VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.7, 0.92, 1.0), Vector3.UP, 0.85, 0.8, 0.1), 0.6)
			"hyoton":
				_ice_burst(pos, r, tier)
			"fuuton", "jinton":
				var wb = VFX.wind_ball(1.0)
				scene().add_child(wb)
				wb.global_position = pos + Vector3.UP * 1.5
				var tw = wb.create_tween()
				tw.tween_property(wb, "scale", Vector3.ONE * r * 2.0, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
				tw.tween_property(wb, "scale", Vector3.ONE * 0.05, 0.25)
				tw.tween_callback(wb.queue_free)
				FX.burst(pos + Vector3.UP, {"amount": 40, "life": 0.4, "tex": FX.tex_spark, "size": 2.5, "vmin": 14, "vmax": 26, "colors": [Color(1, 1, 1, 0.9), Color(0.85, 1, 0.92, 0)]})
			"doton", "mokuton", "jiton", "shoton":
				_spikes_ring(c, pos, r, col, el, inf, tier)
				VFX.cracks(pos, r * 1.4)
				VFX.debris(pos, col.darkened(0.2), 18, 14.0, 0.5)
			_:
				VFX.star(pos + Vector3.UP, col.lightened(0.3), r * 1.2, 0.25)
				VFX.puffs(pos + Vector3.UP, {"amount": 30 + tier * 6, "life": 0.7, "size": 1.4, "radius": r * 0.4, "vmin": 4, "vmax": 9 + tier,
					"colors": [col.lightened(0.4), col, Color(col.r, col.g, col.b, 0)]})
		VFX.shockwave(pos + Vector3.UP * 0.2, col, r * 2.4, 0.45)
		VFX.shockwave(pos + Vector3.UP * 1.2, col.lightened(0.4), r * 1.6, 0.3, false)
		Combat.hit_sphere(c, pos + Vector3.UP, r, inf)
		Sfx.play("boom" if v == "explosion" else _snd(d), pos)
	if Game.world:
		Game.world.env.add_shake(0.2 + tier * 0.12)
	if c is Player and tier >= 3:
		VFX.screen_lines(0.4, 0.6)


## Yerde dışa yayılan halka dalga (su/lav seli)
static func _wave_ring(pos: Vector3, r: float, m: Material, dur: float) -> void:
	var tor = TorusMesh.new()
	tor.inner_radius = 0.75; tor.outer_radius = 1.0; tor.rings = 32; tor.ring_segments = 10
	var mi = VFX._mi(tor, m)
	scene().add_child(mi)
	mi.global_position = pos + Vector3.UP * 0.3
	mi.scale = Vector3(0.5, 1.2, 0.5)
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(r * 0.5, 2.4, r * 0.5), dur).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "scale", Vector3(r * 0.55, 0.05, r * 0.55), 0.3)
	tw.tween_callback(mi.queue_free)


## Buz kristalleri patlaması (Hyōton)
static func _ice_burst(pos: Vector3, r: float, tier: int) -> void:
	var b = MB.new()
	for k in 7 + tier * 2:
		var a = randf() * TAU
		var dd = randf_range(0.2, 1.0) * r * 0.7
		var h = randf_range(1.5, 3.0 + tier * 0.6)
		b.add("cone", Vector3(cos(a) * dd, h * 0.4, sin(a) * dd), Vector3(0.5, h, 0.5), Color.WHITE, Vector3(randf_range(-30, 30), 0, randf_range(-30, 30)), 5)
	var mi = VFX._mi(b.build(null), VFX.mat_ice())
	scene().add_child(mi)
	mi.scale = Vector3.ONE * VFX.epic
	mi.global_position = pos - Vector3.UP * 3.0
	var tw = mi.create_tween()
	tw.tween_property(mi, "global_position:y", pos.y, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.5)
	tw.tween_property(mi, "scale", Vector3(1, 0.02, 1), 0.3)
	tw.tween_callback(mi.queue_free)
	VFX.debris(pos, Color(0.8, 0.95, 1.0), 14, 10.0, 0.3)


## Halka şeklinde fışkıran dikenler (toprak/ağaç/kristal)
static func _spikes_ring(c: Node3D, pos: Vector3, r: float, col: Color, el: String, inf: Dictionary, tier: int) -> void:
	var b = MB.new()
	for k in 8 + tier * 2:
		var a = TAU * k / (8 + tier * 2) + randf_range(-0.2, 0.2)
		var dd = r * randf_range(0.4, 0.95)
		var h = randf_range(2.0, 3.5 + tier * 0.6)
		b.add("cone", Vector3(cos(a) * dd, h * 0.4, sin(a) * dd), Vector3(0.9, h, 0.9), col.darkened(0.15), Vector3(cos(a) * 20, 0, -sin(a) * 20), 6)
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon() if el != "shoton" else null)
	if el == "shoton":
		mi.material_override = VFX.mat_spiral(Color(1, 0.9, 1), col, 3.0, 1.0, 2.0, 1.3)
	scene().add_child(mi)
	mi.scale = Vector3.ONE * VFX.epic
	mi.global_position = pos - Vector3.UP * 4.0
	var tw = mi.create_tween()
	tw.tween_property(mi, "global_position:y", pos.y, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.4)
	tw.tween_property(mi, "global_position:y", pos.y - 4.5, 0.4)
	tw.tween_callback(mi.queue_free)
	FX.dust(pos, 2.0)


static func _spikes(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var col = vcolor(d)
	var el: String = d.get("element", "")
	var dir: Vector3 = J()._aim_flat(c, t)
	var inf = info(c, d, 0.5, {"launch": 7.0 + tier})
	var vr = vary(d)
	Sfx.play(_snd(d), c.global_position)
	var mat: Material = Props.toon()
	if el == "hyoton":
		mat = VFX.mat_ice()
	elif el == "shoton":
		mat = VFX.mat_spiral(Color(1, 0.9, 1), col, 3.0, 1.0, 2.0, 1.3)
	var g = VFX.epic
	for k in int((5 + tier * 2) * vr["count"]):
		tree().create_timer(k * 0.05).timeout.connect(func():
			if not is_instance_valid(c):
				return
			var p = J()._ground(c.global_position + dir * (2.0 + k * 1.6) + dir.cross(Vector3.UP) * randf_range(-1.0, 1.0))
			var b = MB.new()
			for s in 2 + tier / 2:
				if el == "mokuton":
					# kıvrılan kök/dal
					b.add("cyl", Vector3(randf_range(-0.5, 0.5), 1.4, randf_range(-0.5, 0.5)), Vector3(0.45, 2.8 + tier * 0.4, 0.45), col.darkened(0.25), Vector3(randf_range(-25, 25), 0, randf_range(-25, 25)), 6)
					b.add("cone", Vector3(randf_range(-0.4, 0.4), 3.0 + tier * 0.4, randf_range(-0.4, 0.4)), Vector3(0.4, 1.0, 0.4), col.darkened(0.15), Vector3.ZERO, 5)
				else:
					b.add("cone", Vector3(randf_range(-0.5, 0.5), 1.2, randf_range(-0.5, 0.5)), Vector3(0.8, 2.2 + tier * 0.4 + randf(), 0.8), col.darkened(0.15), Vector3(randf_range(-15, 15), 0, randf_range(-15, 15)), 6)
			var sp = MeshInstance3D.new()
			sp.mesh = b.build(Props.toon() if mat is StandardMaterial3D else null)
			if not mat is StandardMaterial3D:
				sp.material_override = mat
			scene().add_child(sp)
			sp.scale = Vector3.ONE * g
			sp.global_position = p - Vector3(0, 3, 0)
			var tw = sp.create_tween()
			tw.tween_property(sp, "global_position:y", p.y, 0.1)
			tw.tween_interval(1.2)
			tw.tween_property(sp, "global_position:y", p.y - 3.5, 0.4)
			tw.tween_callback(sp.queue_free)
			FX.dust(p, 0.7)
			VFX.debris(p + Vector3.UP * 0.3, col.darkened(0.2) if el != "hyoton" else Color(0.8, 0.95, 1), 4, 8.0, 0.3)
			VFX.cracks(p, 2.4)
			Combat.hit_sphere(c, p + Vector3.UP, 1.6, inf))


static func _wave(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var col = vcolor(d)
	var el: String = d.get("element", "")
	var dir: Vector3 = J()._aim_flat(c, t)
	var vr = vary(d)
	var w = (5.0 + tier * 2.0) * vr["size"]
	var h = 2.0 + tier * 0.8
	# yarım silindir dalga duvarı (öne doğru kıvrılan tepe)
	var b = MB.new()
	b.add("cyl", Vector3.ZERO, Vector3(h * 1.2, w, h * 0.8), Color.WHITE, Vector3(0, 0, 90), 16)
	b.add("cyl", Vector3(0, h * 0.35, -h * 0.25), Vector3(h * 0.5, w * 0.95, h * 0.45), Color.WHITE, Vector3(0, 0, 90), 12)
	var m: Material
	match el:
		"suiton", "futton": m = VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.7, 0.92, 1.0), Vector3(0, 0, -1), 0.9, 0.9, 0.12)
		"katon", "yoton", "shakuton", "bakuton": m = VFX.mat_fire(VFX.fire_preset_for(col) if el != "yoton" else "lava", 3.0, 1.6, 0.4, 1.35, 0.15, Vector3(0, 1, 0))
		"fuuton", "jinton": m = VFX.mat_wind(Color(0.85, 1, 0.95), 12.0, 9.0, Vector3(1, 0, 0), 0.9)
		"raiton", "ranton": m = VFX.mat_spiral(Color(1, 1, 1), col, 9.0, 3.0, 12.0, 2.0, Vector3(1, 0, 0))
		"hyoton": m = VFX.mat_ice()
		_: m = Props.toon_color(col.darkened(0.2)) if el in ["doton", "mokuton", "jiton"] else VFX.mat_spiral(col.lightened(0.5), col)
	var mi = VFX._mi(b.build(null), m)
	scene().add_child(mi)
	var start = J()._ground(c.global_position + dir * 2.0)
	mi.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), start + Vector3.UP * h * 0.4)
	var g = minf(VFX.epic, 2.0)
	mi.scale = Vector3(g, 0.2, g)
	mi.create_tween().tween_property(mi, "scale", Vector3.ONE * g, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play(_snd(d), start)
	var inf = info(c, d, 1.0, {"knock": 14.0 + tier * 2})
	var tw = mi.create_tween()
	var hit = []
	tw.tween_interval(0.15)
	tw.tween_method(func(k: float):
		var p = start + dir * k * (14.0 + tier * 3.0)
		mi.global_position = p + Vector3.UP * h * 0.4
		var got = Combat.hit_sphere(c, p + Vector3.UP, w * 0.5, inf, hit)
		hit.append_array(got)
		if randf() < 0.6:
			VFX.puffs(p + Vector3.UP * h * 1.1 + dir * h * 0.3, {"amount": 4, "life": 0.5, "size": 1.0, "radius": w * 0.4, "vmin": 2, "vmax": 5, "gravity": Vector3(0, -12, 0),
				"colors": [Color(1, 1, 1, 1), col.lightened(0.3), Color(col.r, col.g, col.b, 0)]})
		if el in ["doton", "mokuton"] and randf() < 0.3:
			VFX.debris(p, col.darkened(0.2), 3, 6.0, 0.35), 0.0, 1.0, 1.0)
	tw.tween_property(mi, "scale", Vector3(g, 0.05, g), 0.3)
	tw.tween_callback(mi.queue_free)


static func _tornado(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var col = vcolor(d)
	var el: String = d.get("element", "")
	var pos: Vector3 = J()._ground(J()._aim_ground(c, t, 8.0, 25.0))
	var hgt = (6.0 + tier * 2.0) * vary(d)["size"]
	var cm = CylinderMesh.new()
	cm.top_radius = 0.5; cm.bottom_radius = 0.12; cm.height = 1.0; cm.radial_segments = 20; cm.rings = 6
	cm.cap_top = false; cm.cap_bottom = false
	var m: Material
	match el:
		"katon", "yoton", "shakuton": m = VFX.mat_fire(VFX.fire_preset_for(col), 4.0, 1.8, 0.45, 1.35, 0.2, Vector3.UP)
		"suiton", "futton": m = VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.7, 0.92, 1.0), Vector3.UP, 0.8, 0.9, 0.15)
		"raiton", "ranton": m = VFX.mat_spiral(Color(1, 1, 1), col, 6.0, 4.0, 10.0, 2.0)
		_: m = VFX.mat_wind(col.lerp(Color(0.85, 1, 0.95), 0.6), 10.0, 7.0, Vector3.UP, 0.9)
	var root = Node3D.new()
	scene().add_child(root)
	root.global_position = pos
	for k in 3:
		var mi = VFX._mi(cm, m)
		var wsz = (3.5 + tier * 0.4) * (1.0 - k * 0.22)
		mi.scale = Vector3(wsz * 2.0, hgt * (1.0 - k * 0.1), wsz * 2.0)
		mi.position = Vector3(0, hgt * 0.5, 0)
		root.add_child(mi)
		var twr = mi.create_tween().set_loops()
		twr.tween_property(mi, "rotation:y", TAU * (1 if k % 2 == 0 else -1), 0.6 + k * 0.25).from(0.0)
	FX.burst(pos + Vector3.UP * hgt * 0.4, {"amount": 50, "life": 0.6, "tex": FX.tex_spark, "size": 1.8, "radius": 2.5, "vmin": 2, "vmax": 6, "tangent": 30.0,
		"dir": Vector3.UP, "colors": [Color(1, 1, 1, 0.9), col.lightened(0.3), Color(col.r, col.g, col.b, 0)]})
	FX.dust(pos, 2.0)
	Sfx.play("wind", pos)
	var inf = info(c, d, 0.18, {"knock": 2.0, "launch": 5.0, "kind": "light"})
	root.scale = Vector3(0.2, 0.2, 0.2)
	var g = VFX.epic
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE * g, 0.25).set_trans(Tween.TRANS_BACK)
	for i in 16:
		tw.tween_callback(func():
			Combat.hit_sphere(c, pos + Vector3.UP * 2.0, 3.0 + tier * 0.5, inf)
			if randf() < 0.4:
				VFX.debris(pos + Vector3.UP, Color(0.5, 0.42, 0.32), 3, 8.0, 0.3)
			for f in tree().get_nodes_in_group("fighters"):
				if Combat.hostile(c, f) and not f.is_dead() and "velocity" in f and f.global_position.distance_to(pos) < 9.0:
					f.velocity += (pos - f.global_position).normalized() * 2.0)
		tw.tween_interval(0.15)
	tw.tween_property(root, "scale", Vector3(0.1, g, 0.1), 0.3)
	tw.tween_callback(root.queue_free)


static func _barrage(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var pos: Vector3 = J()._ground(J()._aim_ground(c, t, 10.0, 30.0))
	var n = 8 + tier * 4
	var r = 3.0 + tier
	Sfx.play(_snd(d), pos, 0.9)
	for i in n:
		tree().create_timer(i * 0.05).timeout.connect(func():
			if not is_instance_valid(c):
				return
			var tgt = pos + Vector3(randf_range(-r, r), 0, randf_range(-r, r))
			var start = tgt + Vector3(randf_range(-3, 3), 14.0, randf_range(-3, 3))
			spawn_projectile(c, d, start, (tgt - start).normalized(), "needles", 0.45, 34.0, info(c, d, 2.0 / n, {"kind": "light", "knock": 1.0})))


static func _wall(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var col = vcolor(d)
	var el: String = d.get("element", "")
	var dir: Vector3 = J()._aim_flat(c, t)
	var pos = J()._ground(c.global_position + dir * 3.5)
	var size = Vector3((7.0 + tier * 1.5) * vary(d)["size"], 4.0 + tier * 0.8, 1.6) * Vector3(clampf(VFX.epic, 1.0, 1.6), clampf(VFX.epic, 1.0, 1.8), 1.0)
	var wall = StaticBody3D.new()
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position.y = size.y * 0.5
	wall.add_child(cs)
	var b = MB.new()
	var mi: MeshInstance3D
	match el:
		"suiton", "futton":
			b.add("box", Vector3(0, size.y * 0.5, 0), size, Color.WHITE)
			mi = VFX._mi(b.build(null), VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.7, 0.92, 1.0), Vector3(0, -1, 0), 0.75, 0.8, 0.08))
		"hyoton":
			for k in 7:
				b.add("box", Vector3(-size.x * 0.45 + k * size.x * 0.15, size.y * 0.5, randf_range(-0.2, 0.2)), Vector3(size.x * 0.16, size.y * randf_range(0.8, 1.1), size.z), Color.WHITE, Vector3(0, randf_range(-10, 10), randf_range(-4, 4)))
			mi = VFX._mi(b.build(null), VFX.mat_ice())
		"fuuton", "jinton":
			b.add("box", Vector3(0, size.y * 0.5, 0), size, Color.WHITE)
			mi = VFX._mi(b.build(null), VFX.mat_wind(Color(0.85, 1, 0.95), 12.0, 10.0, Vector3.UP, 0.85))
		"katon", "yoton", "shakuton":
			b.add("box", Vector3(0, size.y * 0.5, 0), size, Color.WHITE)
			mi = VFX._mi(b.build(null), VFX.mat_fire(VFX.fire_preset_for(col) if el != "yoton" else "lava", 3.0, 1.6, 0.35, 1.35, 0.2, Vector3.UP))
		"raiton", "ranton":
			b.add("box", Vector3(0, size.y * 0.5, 0), size, Color.WHITE)
			mi = VFX._mi(b.build(null), VFX.mat_spiral(Color(1, 1, 1), col, 10.0, 3.0, 14.0, 2.0, Vector3(1, 0, 0)))
		"mokuton":
			for k in 9:
				b.add("cyl", Vector3(-size.x * 0.45 + k * size.x * 0.112, size.y * 0.5, 0), Vector3(0.9, size.y * randf_range(0.9, 1.15), 0.9), col.darkened(randf_range(0.1, 0.3)), Vector3(0, 0, randf_range(-5, 5)), 8)
			mi = VFX._mi(b.build(Props.toon()), null)
		_:
			b.add("box", Vector3(0, size.y * 0.5, 0), size, col)
			for k in 4:
				b.add("box", Vector3(-size.x * 0.4 + k * size.x * 0.27, size.y + 0.3, 0), Vector3(size.x * 0.15, 0.6, size.z * 1.1), col.darkened(0.15))
			for k in 6:
				b.add("box", Vector3(randf_range(-size.x * 0.45, size.x * 0.45), randf_range(0.4, size.y - 0.4), -size.z * 0.52), Vector3(randf_range(0.6, 1.4), randf_range(0.4, 0.9), 0.15), col.darkened(0.25))
			mi = VFX._mi(b.build(Props.toon()), null)
	wall.add_child(mi)
	scene().add_child(wall)
	J()._element_wall(wall, el if el != "" else "doton", c, Vector3(0, size.y * 0.5, 0), size * 0.5, base_dmg(c, d) * 2.0)
	wall.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), pos - Vector3(0, size.y + 0.5, 0))
	var tw = wall.create_tween()
	tw.tween_property(wall, "global_position:y", pos.y, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(8.0 + tier * 1.5)
	tw.tween_property(wall, "global_position:y", pos.y - size.y - 0.5, 0.5)
	tw.tween_callback(wall.queue_free)
	FX.dust(pos, 2.0)
	if el in ["", "doton", "mokuton", "jiton", "shoton", "hyoton"]:
		VFX.debris(pos + Vector3.UP * 0.5, col.darkened(0.2) if el != "hyoton" else Color(0.8, 0.95, 1), 16, 12.0, 0.45)
		VFX.cracks(pos, size.x * 0.9)
	elif el in ["suiton", "futton"]:
		VFX.splash(pos, 2.5)
	VFX.shockwave(pos + Vector3.UP * 0.1, col.lightened(0.2), size.x * 1.6, 0.4)
	Sfx.play(_snd(d), pos)


static func _dome(c: Node3D, d: Dictionary) -> void:
	var tier = int(d.get("tier", 2))
	var col = vcolor(d)
	var el: String = d.get("element", "")
	var r = (3.0 + tier * 0.4) * clampf(VFX.epic, 1.0, 1.5)
	var m: Material = VFX.element_mat(el, col) if el not in ["doton", "mokuton", "jiton", "shoton", ""] else VFX.mat_spiral(col.lightened(0.5), col, 6.0, 2.0, 3.0, 1.2)
	if el in ["doton", "mokuton"]:
		m = Props.toon_color(col.darkened(0.15))
	var mi = VFX._mi(VFX._sphere(0.5, 28, 14), m)
	c.add_child(mi)
	mi.position = Vector3(0, 0.2, 0)
	mi.scale = Vector3.ONE * 0.1
	var dur = 3.0 + tier * 0.6
	Buffs.add("dome_" + String(d.get("id", "")), dur, {"armor": 0.35})
	J()._element_wall(mi, el if el != "" else "doton", c, Vector3(0, 0, 0), Vector3(0.5, 0.5, 0.5), base_dmg(c, d) * 2.0)
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(r * 2.0, r * 1.6, r * 2.0), 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(dur)
	tw.tween_property(mi, "scale", Vector3.ONE * 0.05, 0.3)
	tw.tween_callback(mi.queue_free)
	VFX.shockwave(c.global_position + Vector3.UP * 0.1, col, r * 3.0, 0.4)
	if el in ["doton", "mokuton"]:
		VFX.debris(c.global_position, col.darkened(0.2), 14, 10.0, 0.4)
	Sfx.play(_snd(d), c.global_position)


static func _target_in_range(c: Node3D, t: Node3D, rng: float) -> Node3D:
	if t and is_instance_valid(t) and not t.is_dead() and t.global_position.distance_to(c.global_position) < rng:
		return t
	var dir: Vector3 = J()._aim_flat(c, t)
	return Combat.nearest_enemy(c, rng, dir, 0.4)


static func _bind(c: Node3D, d: Dictionary, t: Node3D, v: String, debuff: bool) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var tg = _target_in_range(c, t, 18.0 + tier * 2.0)
	if tg == null:
		if c is Player:
			Hud.msg("Bağlanacak hedef yok.", Color(0.8, 0.8, 0.8))
		return
	var dur = 1.8 + tier * 0.45
	if debuff:
		tg.apply_status("slow", dur * 1.6)
		tg.apply_status("weak", dur * 1.6)
	else:
		tg.apply_status("bind", dur)
	var b = MB.new()
	match v:
		"prison":
			b.add("sphere", Vector3(0, 1.0, 0), Vector3(2.4, 2.6, 2.4), col, Vector3.ZERO, 14)
		"roots":
			for k in 6:
				b.add("cyl", Vector3(cos(k) * 0.6, 0.9, sin(k) * 0.6), Vector3(0.18, 2.2, 0.18), col.darkened(0.2), Vector3(randf_range(-25, 25), 0, randf_range(-25, 25)), 6)
		"shadow":
			b.add("cyl", Vector3(0, 0.02, 0), Vector3(2.2, 0.04, 2.2), Color(0.03, 0.02, 0.05), Vector3.ZERO, 16)
		_:
			for k in 4:
				b.add("torus", Vector3(0, 0.4 + k * 0.45, 0), Vector3(1.4, 0.5, 1.4), col, Vector3(randf_range(-15, 15), 0, randf_range(-15, 15)), 12)
	var el: String = d.get("element", "")
	var nm = (String(d.get("name_en", "")) + " " + String(d.get("id", ""))).to_lower()
	var bm: Material = VFX.mat_spiral(col.lightened(0.6), col, 6.0, 2.0, 4.0, 1.5)
	var sandy = nm.contains("sand") or nm.contains("desert") or nm.contains("suna") or nm.contains("sabaku")
	if sandy:
		bm = Props.toon_color(Color(0.82, 0.68, 0.45))
		VFX.puffs(tg.global_position, {"amount": 26, "life": 0.7, "size": 1.0, "radius": 1.6, "vmin": 3, "vmax": 7, "dir": Vector3.UP, "spread": 25.0, "tangent": 8.0,
			"outline_col": Color(0.4, 0.3, 0.18), "colors": [Color(0.92, 0.8, 0.58, 1), Color(0.82, 0.68, 0.45, 1), Color(0.82, 0.68, 0.45, 0)]})
	elif nm.contains("hair") or nm.contains("lion"):
		bm = Props.toon_color(Color(0.92, 0.9, 0.85))
	elif nm.contains("puppet") or nm.contains("thread") or nm.contains("string") or nm.contains("wire"):
		# chakra ipleri: elden hedefe ince mavi çizgiler
		for k in 4:
			var off = Vector3(randf_range(-0.4, 0.4), randf_range(0.2, 1.6), randf_range(-0.4, 0.4))
			VFX.bolt(J()._hand(c), tg.global_position + off, Color(0.55, 0.8, 1.0), 0.04, 0.5, 0)
	elif nm.contains("insect") or nm.contains("bug") or nm.contains("kikaichu"):
		bm = Props.toon_color(Color(0.08, 0.08, 0.1))
	if v == "prison":
		bm = VFX.element_mat(el, col) if el != "" else VFX.mat_spiral(col.lightened(0.5), col, 5.0, 2.0, 3.0, 1.3)
		if el in ["suiton", "futton"]:
			bm = VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.7, 0.92, 1.0), Vector3.UP, 0.6, 0.6, 0.1)
	elif v == "roots":
		bm = Props.toon()
	elif v == "chains":
		bm = VFX.mat_spiral(Color(1, 0.95, 0.7), col, 8.0, 2.0, 6.0, 1.6)
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(bm if bm is StandardMaterial3D else null)
	if not bm is StandardMaterial3D:
		mi.material_override = bm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tg.add_child(mi)
	mi.scale = Vector3(1, 0.1, 1)
	mi.create_tween().tween_property(mi, "scale", Vector3.ONE * maxf(1.0, tg.height / 1.8), 0.3).set_trans(Tween.TRANS_BACK)
	VFX.star(tg.global_position + Vector3.UP * tg.height * 0.5, col.lightened(0.3), 2.5, 0.15)
	if el in ["suiton", "futton"]:
		VFX.splash(tg.global_position, 1.4)
	elif el in ["doton", "mokuton"] or v == "roots":
		VFX.debris(tg.global_position, col.darkened(0.2), 8, 8.0, 0.35)
	if v == "shadow":
		J()._shadow_line(c, tg, dur)
	var inf = info(c, d, 0.12, {"knock": 0.0, "launch": 0.0, "kind": "light", "hitstop": 0.0})
	J()._ticks(int(dur / 0.4), 0.4, func(_i):
		if is_instance_valid(tg) and not tg.is_dead():
			tg.take_hit(inf.merged({"attacker": c, "dir": Vector3.ZERO}, true)), func():
		if is_instance_valid(mi):
			mi.queue_free())
	Sfx.play(_snd(d), tg.global_position)


static func _genjutsu(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var targets = []
	if tier >= 4:
		for f in tree().get_nodes_in_group("fighters"):
			if Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(c.global_position) < 14.0 + tier * 2:
				targets.append(f)
	else:
		var tg = _target_in_range(c, t, 20.0)
		if tg:
			targets.append(tg)
	if targets.is_empty():
		return
	Sfx.play("genjutsu", c.global_position)
	var gm = (1.0 + Stats.skill(Game.profile, "gen_power")) if c is Player else 1.0
	for tg in targets:
		tg.apply_status("stun", (1.6 + tier * 0.4) * gm)
		tg.apply_status("fear", (1.6 + tier * 0.4) * gm)
		if tier >= 3:
			tg.take_hit(info(c, d, 0.6, {"knock": 0.0, "attacker": c, "dir": Vector3.ZERO}))
		var nm = String(d.get("name_en", "")).to_lower()
		var pc = col.lightened(0.3)
		if nm.contains("crow") or nm.contains("raven"):
			pc = Color(0.06, 0.05, 0.08)
		elif nm.contains("sakura") or nm.contains("flower") or nm.contains("petal"):
			pc = Color(1.0, 0.7, 0.82)
		FX.burst(tg.global_position + Vector3.UP * 1.5, {"amount": 40, "life": 1.6, "tex": FX.tex_leaf, "add": false, "cel": false, "size": 0.35, "radius": 2.2,
			"vmin": 0.5, "vmax": 2.5, "gravity": Vector3(0, -1, 0), "spin": 200.0, "colors": [pc, Color(pc.r, pc.g, pc.b, 0)]})
		VFX.shockwave(tg.global_position + Vector3.UP * 1.6, col, 3.5, 0.6, false)
		var ring = VFX.rasengan(1.6, Color(col.r, col.g, col.b), col.lightened(0.5))
		tg.add_child(ring)
		ring.position = Vector3(0, 1.0, 0)
		var twg = ring.create_tween()
		twg.tween_interval(1.2)
		twg.tween_property(ring, "scale", Vector3.ONE * 0.01, 0.3)
		twg.tween_callback(ring.queue_free)
	if c is Player and Game.world:
		Game.world.env.set_tint(Color(col.r, col.g, col.b, 0.2))
		tree().create_timer(0.7).timeout.connect(func(): Game.world.env.set_tint(Color(0, 0, 0, 0)))


static func _summon(c: Node3D, d: Dictionary) -> void:
	var s = String(d.get("name_en", "")).to_lower()
	# hayvan sözleşmesi çağırmaları (Kuchiyose ailesi) sözleşme sistemine gider
	var jid = String(d.get("id", ""))
	if String(d.get("category", "")) == "summoning" and (s.contains("summoning technique") or jid.begins_with("kuchiyose")) and not (jid.contains("edo") or jid.contains("gedo")):
		var sp = J()._ground(J()._aim_ground(c, null, 6.0, 10.0))
		FX.smoke_puff(sp + Vector3.UP * 3.0, 2.0 * sqrt(VFX.epic), 24)
		VFX.shockwave(sp + Vector3.UP * 0.1, Color(0.9, 0.9, 0.85), 16.0, 0.5)
		VFX.smoke_ring(sp, 3.0, Color(0.85, 0.85, 0.82))
		Contracts.summon(c, d)
		return
	var el: String = d.get("element", "")
	if el != "" and not (s.contains("toad") or s.contains("snake") or s.contains("slug") or s.contains("frog")):
		# element yaratığı: yerden yükselen ejderha / canavar, hedefe saldırır
		var pv = "dragon" if (s.contains("dragon") or s.contains("serpent")) else ("bird" if (s.contains("bird") or s.contains("phoenix") or s.contains("hawk")) else "beast")
		var fd = J()._aim_flat(c, null)
		var at = J()._ground(c.global_position + fd * 3.0)
		VFX.cracks(at, 4.0)
		impact_for(el, at, color_of(d), 1.0)
		var tg = _target_in_range(c, c.combat.lock_target if c is Player and c.combat else null, 40.0)
		for i in (2 if pv != "dragon" else 1):
			var st = at + Vector3.UP * (2.0 + i) + fd.cross(Vector3.UP) * (i * 2.0 - 1.0) * (1.0 if pv != "dragon" else 0.0)
			var dd = (fd + Vector3.UP * 0.6).normalized()
			spawn_projectile(c, d, st, dd, pv, 2.2 if pv == "dragon" else 1.6, 18.0, info(c, d, 0.7 if pv != "dragon" else 1.2), tg)
		if Game.world:
			Game.world.env.add_shake(0.6)
		return
	var kind = Game.profile.get("summon", "kurbağa") if c is Player else "kurbağa"
	if s.contains("snake") or s.contains("serpent"):
		kind = "yılan"
	elif s.contains("slug"):
		kind = "sümüklü"
	elif s.contains("toad") or s.contains("frog"):
		kind = "kurbağa"
	var pos: Vector3 = J()._ground(J()._aim_ground(c, null, 6.0, 10.0))
	FX.smoke_puff(pos + Vector3.UP * 3, 2.6 * sqrt(VFX.epic), 30)
	VFX.shockwave(pos + Vector3.UP * 0.1, Color(0.9, 0.9, 0.85), 16.0, 0.5)
	VFX.smoke_ring(pos, 3.0, Color(0.85, 0.85, 0.82))
	var sm = Summon.new()
	if "kind" in sm:
		sm.kind = kind
	sm.team = c.team
	scene().add_child(sm)
	sm.global_position = pos
	if Game.world:
		Game.world.env.add_shake(1.0)
	Sfx.play("boom", pos, 0.6)


static func _buff(c: Node3D, d: Dictionary, kind: String) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var dur = 10.0 + tier * 3.0
	var mods = {"melee": 1.0 + 0.07 * (tier + 1)}
	var cat: String = d.get("category", "")
	var el: String = d.get("element", "")
	if kind == "mode" or cat == "senjutsu":
		mods = {"melee": 1.2 + 0.06 * tier, "armor": 0.85, "jutsu": 1.15 + 0.05 * tier}
	elif el in ["raiton", "ranton"]:
		mods = {"speed": 1.15 + 0.04 * tier, "melee": 1.1 + 0.05 * tier}
	elif el in ["doton", "shoton", "jiton"] or kind == "transform":
		mods = {"armor": maxf(0.5, 0.9 - 0.06 * tier), "melee": 1.05 + 0.04 * tier}
	elif el in ["fuuton"]:
		mods = {"speed": 1.2 + 0.04 * tier}
	elif kind == "utility":
		mods = {"speed": 1.1}
		dur = 8.0 + tier * 2.0
	Buffs.add(String(d.get("id", "buff")), dur, mods)
	FX.aura(c, col, 0.9 + tier * 0.1, Vector3(0, 0.9, 0), dur)
	FX.ring(c.global_position + Vector3.UP * 0.2, col, 4.0 + tier, 0.4)
	_buff_look(c, d, col, dur)
	if c is Player:
		Hud.msg("%s: %d sn" % [String(d.get("name", "")).split(" (")[0], int(dur)], col.lightened(0.3))
	Sfx.play("seal", c.global_position, 0.8)


## Buff/mod görünümü: yükselen chakra sütunu + anahtar kelimeye göre chakra pelerini, kum/taş zırh, şimşek zırhı, sennin, Sekiz Kapı
static func _buff_look(c: Node3D, d: Dictionary, col: Color, dur: float) -> void:
	var s = (String(d.get("name_en", "")) + " " + String(d.get("id", ""))).to_lower()
	var el: String = d.get("element", "")
	var host: Node3D = c.model if c.get("model") else c
	var cm = CylinderMesh.new()
	cm.top_radius = 1.2; cm.bottom_radius = 1.6; cm.height = 1.0; cm.radial_segments = 20
	var col_mi = VFX._mi(cm, VFX.mat_spiral(col.lightened(0.6), col, 5.0, 2.0, 8.0, 1.6, Vector3.UP))
	scene().add_child(col_mi)
	col_mi.global_position = c.global_position
	col_mi.scale = Vector3(1, 0.1, 1)
	var tw = col_mi.create_tween()
	tw.tween_property(col_mi, "scale", Vector3(1, 9.0, 1), 0.25).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(col_mi, "global_position:y", c.global_position.y + 4.5, 0.25)
	tw.tween_property(col_mi, "scale", Vector3(0.05, 11.0, 0.05), 0.3)
	tw.tween_callback(col_mi.queue_free)
	VFX.star(c.global_position + Vector3.UP, col.lightened(0.4), 3.0, 0.15)
	var cloak: Node3D = null
	if s.contains("chakra mode") or s.contains("chakura") or s.contains("baryon") or s.contains("barion") or s.contains("cloak") or s.contains("kyubi") or s.contains("tailed"):
		var preset = "blue" if (s.contains("baryon") or s.contains("barion")) else "fire"
		cloak = VFX._mi(VFX._sphere(0.5, 24, 12), VFX.mat_fire(preset, 2.8, 3.0, 0.55, 1.4, 0.2, Vector3.UP, true))
		cloak.scale = Vector3(1.4, 2.3, 1.4)
		cloak.position = Vector3(0, 1.0, 0)
	elif s.contains("sand") or s.contains("suna") or el in ["doton", "shoton"] or s.contains("armour") or s.contains("armor"):
		var sc = Color(0.82, 0.68, 0.45) if (s.contains("sand") or s.contains("suna")) else col
		VFX.puffs(c.global_position + Vector3.UP, {"amount": 30, "life": 0.7, "size": 0.9, "radius": 1.6, "vmin": 2, "vmax": 5, "spin": 40.0, "tangent": 10.0,
			"colors": [sc.lightened(0.2), sc, Color(sc.r, sc.g, sc.b, 0)]})
		if not el in ["raiton", "ranton"]:
			# zırh kabuğu bedeni sarar, sonra içine oturur
			var shell = VFX._mi(VFX._sphere(0.5, 18, 9), Props.toon_color(sc))
			shell.scale = Vector3(0.1, 0.19, 0.1)
			shell.position = Vector3(0, 0.95, 0)
			host.add_child(shell)
			var st = shell.create_tween()
			st.tween_property(shell, "scale", Vector3(1.05, 1.95, 1.05), 0.2)
			st.tween_interval(0.3)
			st.tween_property(shell, "scale", Vector3.ONE * 0.01, 0.35)
			st.tween_callback(shell.queue_free)
	if el in ["raiton", "ranton"] or s.contains("lightning armor"):
		var arcs = Arcs.new()
		arcs.color = col
		arcs.radius = 1.3
		arcs.count = 7
		arcs.width = 0.06
		arcs.position = Vector3(0, 1.0, 0)
		host.add_child(arcs)
		c.get_tree().create_timer(dur).timeout.connect(func(): if is_instance_valid(arcs): arcs.queue_free())
	if s.contains("sage") or s.contains("sennin") or String(d.get("category", "")) == "senjutsu":
		VFX.puffs(c.global_position + Vector3.UP, {"amount": 24, "life": 1.0, "size": 1.0, "radius": 1.2, "vmin": 1, "vmax": 3, "dir": Vector3.UP, "spread": 20.0,
			"colors": [Color(1, 0.85, 0.4, 1), Color(0.95, 0.55, 0.15, 1), Color(0.9, 0.4, 0.1, 0)]})
	if s.contains("gate") or s.contains("hachimon"):
		var gc = Color(0.4, 0.95, 0.5)
		if s.contains("night") or s.contains("eighth") or s.contains("death"):
			gc = Color(1.0, 0.15, 0.1)
		elif s.contains("seventh") or s.contains("sixth"):
			gc = Color(0.4, 0.8, 1.0)
		cloak = VFX._mi(VFX._sphere(0.5, 24, 12), VFX.mat_spiral(gc.lightened(0.5), gc, 6.0, 2.5, 10.0, 1.6, Vector3.UP))
		cloak.scale = Vector3(1.5, 2.4, 1.5)
		cloak.position = Vector3(0, 1.0, 0)
		VFX.shockwave(c.global_position + Vector3.UP * 0.1, gc, 14.0, 0.5)
		FX.dust(c.global_position, 1.6)
	if cloak:
		host.add_child(cloak)
		var full = cloak.scale
		cloak.scale = full * 0.2
		var ct = cloak.create_tween()
		ct.tween_property(cloak, "scale", full, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ct.tween_interval(maxf(0.5, dur - 0.6))
		ct.tween_property(cloak, "scale", full * 0.05, 0.3)
		ct.tween_callback(cloak.queue_free)


static func _clone(c: Node3D, d: Dictionary) -> void:
	var tier = int(d.get("tier", 2))
	var n = clampi(1 + tier / 2, 1, 4)
	var col = color_of(d)
	for i in n:
		var ang = TAU * i / n
		var off = Vector3(cos(ang), 0, sin(ang)) * 2.6
		var cl = ShadowClone.new()
		cl.team = c.team
		cl.look = c.model.look.duplicate() if c.get("model") else {}
		scene().add_child(cl)
		cl.global_position = c.global_position + off
		if d.get("element", "") != "":
			FX.burst(cl.global_position + Vector3.UP, {"amount": 20, "life": 0.6, "add": false, "size": 0.6, "vmin": 2, "vmax": 5,
				"colors": [col.lightened(0.3), Color(col.r, col.g, col.b, 0)]})
		else:
			FX.smoke_puff(cl.global_position + Vector3.UP, 1.0, 14)
	Sfx.play("poof", c.global_position)


static func _seal(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var tg = _target_in_range(c, t, 12.0 + tier)
	var pos = J()._ground(tg.global_position if tg else c.global_position + c.face_dir() * 4.0)
	var ink = Color(0.05, 0.05, 0.12)
	FX.ring(pos + Vector3.UP * 0.05, ink, 6.0 + tier, 0.8)
	FX.ring(pos + Vector3.UP * 0.06, Color(0.3, 0.4, 0.9), 3.5 + tier, 0.8)
	var mi = MeshInstance3D.new()
	var b = MB.new()
	b.add("cyl", Vector3.ZERO, Vector3(5.0 + tier, 0.02, 5.0 + tier), ink, Vector3.ZERO, 24)
	for k in 8:
		b.add("box", Vector3(cos(k * TAU / 8) * 2.0, 0.03, sin(k * TAU / 8) * 2.0), Vector3(0.15, 0.02, 1.0), Color(0.2, 0.2, 0.4), Vector3(0, -k * 45.0, 0))
	mi.mesh = b.build(glow_mat(ink, 0.8))
	scene().add_child(mi)
	mi.global_position = pos + Vector3.UP * 0.03
	var tw = mi.create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(mi, "scale", Vector3(0.05, 1, 0.05), 0.4)
	tw.tween_callback(mi.queue_free)
	if tg:
		var fm = (1.0 + Stats.skill(Game.profile, "fuin")) if c is Player else 1.0
		tg.apply_status("stun", (1.2 + tier * 0.3) * fm)
		tg.apply_status("sealed", (6.0 + tier * 2.0) * fm)
		tg.take_hit(info(c, d, 0.8, {"knock": 0.0, "attacker": c, "dir": Vector3.ZERO}))
	Sfx.play("seal", pos)


static func _field(c: Node3D, d: Dictionary, t: Node3D, v: String) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var el: String = d.get("element", "")
	var r = 5.0 + tier * 1.2
	var pos: Vector3 = J()._ground(J()._aim_ground(c, t, 8.0, 25.0) if v != "mist" else c.global_position)
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = r; cm.bottom_radius = r; cm.height = 0.1 if v != "mist" else 4.0; cm.radial_segments = 24
	mi.mesh = cm
	cm.height = 0.06 if v != "mist" else 4.0
	var m: Material
	if v == "swamp" or el in ["doton", "shoton"]:
		m = Props.toon_color(Color(0.3, 0.22, 0.14))   # çamur bataklığı
	elif el in ["suiton", "futton"]:
		m = Props.toon_color(Color(0.16, 0.42, 0.85) if el == "suiton" else Color(0.75, 0.82, 0.9))   # su birikintisi
	elif el in ["katon", "yoton", "hyoton", "bakuton", "shakuton"]:
		m = VFX.element_mat(el, col)
	elif el == "mokuton":
		m = Props.toon_color(Color(0.28, 0.42, 0.18))
	else:
		# chakra / genjutsu / mühür alanı: dönen spiral çizgili daire (dolu soluk disk değil)
		m = VFX.mat_spiral(col.lightened(0.5), col, 6.0, 3.0, 1.5, 1.4, Vector3.UP)
	mi.material_override = m
	VFX.shockwave(pos + Vector3.UP * 0.12, col.lightened(0.2), r * 2.4, 0.5)
	if v != "mist":
		mi.scale = Vector3(0.05, 1, 0.05)
		mi.create_tween().tween_property(mi, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene().add_child(mi)
	mi.global_position = pos + Vector3.UP * (0.05 if v != "mist" else 2.0)
	var dur = 6.0 + tier * 1.5
	var inf = info(c, d, 0.08, {"knock": 0.0, "launch": 0.0, "kind": "light", "hitstop": 0.0})
	Sfx.play(_snd(d), pos, 0.7)
	if v == "mist":
		mi.visible = false
		for f in tree().get_nodes_in_group("fighters"):
			if Combat.hostile(c, f) and f.global_position.distance_to(pos) < r * 1.5 and f.has_method("lose_target"):
				f.lose_target(dur * 0.6)
	J()._ticks(int(dur / 0.5), 0.5, func(_i):
		for f in tree().get_nodes_in_group("fighters"):
			if not Combat.hostile(c, f) or f.is_dead() or f.global_position.distance_to(pos) > r:
				continue
			if v == "swamp" or el in ["doton", "suiton", "hyoton", "mokuton"]:
				f.apply_status("slow", 0.7)
			if el != "" or d.get("category", "") in ["genjutsu", "kinjutsu", "senjutsu"]:
				f.take_hit(inf.merged({"attacker": c, "dir": Vector3.ZERO}, true))
		if v == "mist":
			FX.burst(pos + Vector3.UP * 1.5, {"amount": 14, "life": 2.2, "tex": FX.tex_smoke, "add": false, "size": 4.5, "radius": r,
				"vmin": 0.2, "vmax": 0.8, "gravity": Vector3.ZERO, "colors": [Color(0.92, 0.95, 1.0, 0.0), Color(0.9, 0.93, 0.98, 0.55), Color(0.9, 0.93, 0.98, 0.0)]})
		if el in ["raiton", "ranton"] and _i % 2 == 0:
			var a = pos + Vector3(randf_range(-r, r) * 0.7, 0.2, randf_range(-r, r) * 0.7)
			VFX.bolt(a, a + Vector3(randf_range(-3, 3), randf_range(0.5, 2.5), randf_range(-3, 3)), col, 0.12, 0.2, 1)
		if v == "swamp" or el in ["doton", "suiton"]:
			VFX.puffs(pos + Vector3.UP * 0.2, {"amount": 4, "life": 0.7, "size": 0.6, "radius": r * 0.8, "vmin": 0.5, "vmax": 1.5, "dir": Vector3.UP, "spread": 10.0,
				"colors": [col.lightened(0.3), col, Color(col.r, col.g, col.b, 0)]})
		else:
			FX.burst(pos + Vector3.UP * 0.5, {"amount": 8, "life": 0.8, "tex": FX.tex_spark, "add": true, "size": 0.9, "radius": r * 0.8,
				"vmin": 0.5, "vmax": 2.0, "dir": Vector3.UP, "colors": [col.lightened(0.4), Color(col.r, col.g, col.b, 0)]}), func():
		var tw = mi.create_tween()
		tw.tween_property(mi, "scale", Vector3(0.05, 1, 0.05), 0.5)
		tw.tween_callback(mi.queue_free))


static func _stealth(c: Node3D, d: Dictionary) -> void:
	var tier = int(d.get("tier", 2))
	var dur = 8.0 + tier * 2.0
	Buffs.add("stealth_" + String(d.get("id", "")), dur, {"stealth": 1.0})
	for f in tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and f.global_position.distance_to(c.global_position) < 30 and f.has_method("lose_target"):
			f.lose_target(dur * 0.5)
	FX.smoke_puff(c.global_position + Vector3.UP, 1.2, 18)
	if c.get("model"):
		c.model.visible = false
		tree().create_timer(minf(dur, 4.0)).timeout.connect(func():
			if is_instance_valid(c) and c.get("model"):
				c.model.visible = true)
	Sfx.play("poof", c.global_position)


static func _sensor(c: Node3D, d: Dictionary) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	FX.ring(c.global_position + Vector3.UP, col, 30.0 + tier * 10.0, 0.9)
	for f in tree().get_nodes_in_group("fighters"):
		if not Combat.hostile(c, f) or f.is_dead() or f.global_position.distance_to(c.global_position) > 60.0 + tier * 20.0:
			continue
		var l = Label3D.new()
		l.text = "◆"
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.fixed_size = true
		l.pixel_size = 0.002
		l.font_size = 48
		l.modulate = col.lightened(0.3)
		f.add_child(l)
		l.position = Vector3(0, f.height * 0.6, 0)
		tree().create_timer(12.0).timeout.connect(func():
			if is_instance_valid(l):
				l.queue_free())
	Sfx.play("genjutsu", c.global_position, 1.4)


static func _trap(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	var pos: Vector3 = J()._ground(J()._aim_ground(c, t, 6.0, 20.0))
	var mark = MeshInstance3D.new()
	var b = MB.new()
	b.add("cyl", Vector3.ZERO, Vector3(1.6, 0.03, 1.6), col.darkened(0.3), Vector3.ZERO, 12)
	mark.mesh = b.build(glow_mat(col, 0.6))
	scene().add_child(mark)
	mark.global_position = pos + Vector3.UP * 0.03
	var st = {"armed": true}
	J()._ticks(int(20.0 / 0.2), 0.2, func(_i):
		if not st["armed"]:
			return
		for f in tree().get_nodes_in_group("fighters"):
			if Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(pos) < 2.5:
				st["armed"] = false
				f.apply_status("bind", 1.5 + tier * 0.3)
				FX.explosion(pos + Vector3.UP * 0.5, 0.6 + tier * 0.2, col)
				Combat.hit_sphere(c, pos + Vector3.UP, 3.0 + tier * 0.5, info(c, d, 1.3))
				if is_instance_valid(mark):
					mark.queue_free()
				return, func():
		if is_instance_valid(mark):
			mark.queue_free())
	Sfx.play("seal", pos, 1.2)


static func _teleport(c: Node3D, d: Dictionary, t: Node3D) -> void:
	var col = color_of(d)
	var tier = int(d.get("tier", 2))
	var from = c.global_position
	var dir: Vector3 = J()._aim_flat(c, t)
	var to = from + dir * (14.0 + tier * 4.0)
	if t and is_instance_valid(t):
		to = t.global_position - dir * (2.0 if tier < 4 else -2.0)  # yüksek kademe: hedefin arkasına
	var hit = c.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from + Vector3.UP, to + Vector3.UP, 1))
	if not hit.is_empty():
		to = hit["position"] - dir * 0.8
	to = J()._ground(to)
	var nm = (String(d.get("name_en", "")) + String(d.get("id", ""))).to_lower()
	for p in [from, to]:
		if nm.contains("kamui"):
			var sw = VFX._mi(VFX._sphere(0.5, 24, 12), VFX.mat_spiral(Color(0.1, 0.05, 0.15), Color(0.35, 0.2, 0.5), 3.0, 6.0, 8.0, 1.0))
			scene().add_child(sw)
			sw.global_position = p + Vector3.UP
			sw.scale = Vector3(2.5, 2.5, 0.3)
			var tws = sw.create_tween()
			tws.tween_property(sw, "scale", Vector3(0.05, 0.05, 0.05), 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			tws.tween_callback(sw.queue_free)
		elif nm.contains("hiraishin") or nm.contains("thunder"):
			VFX.star(p + Vector3.UP, Color(1.0, 0.85, 0.2), 4.0, 0.2)
			VFX.trail(c, 0.6, Color(1, 1, 0.8), Color(1, 0.85, 0.2), Color(1, 0.6, 0.1), 8, 0.8)
		else:
			FX.burst(p + Vector3.UP, {"amount": 26, "life": 0.9, "tex": FX.tex_leaf, "add": false, "cel": false, "size": 0.3, "radius": 0.8, "vmin": 2, "vmax": 5,
				"tangent": 14.0, "spin": 300.0, "colors": [Color(0.4, 0.75, 0.3, 1), Color(0.5, 0.8, 0.35, 0)]})
			FX.smoke_puff(p + Vector3.UP, 0.7, 8)
		VFX.shockwave(p + Vector3.UP, col, 3.0, 0.3, false)
	c.global_position = to
	if c.has_method("reset_physics_interpolation"):
		c.reset_physics_interpolation()
	Sfx.play("whoosh", to, 1.5)


static func _counter(c: Node3D, d: Dictionary) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	if c is Player and c.combat:
		c.combat.invuln = 0.8 + tier * 0.1
	Buffs.add("counter_" + String(d.get("id", "")), 1.2, {"armor": 0.2})
	for f in tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(c.global_position) < 4.0 + tier * 0.5:
			var dd = f.global_position - c.global_position
			dd.y = 0
			f.take_hit(info(c, d, 0.7, {"knock": 14.0, "dir": dd.normalized(), "attacker": c}))
	var dm = VFX._mi(VFX._sphere(0.5, 28, 14), VFX.mat_spiral(Color(1, 1, 1), col, 6.0, 1.5, 14.0, 1.4))
	c.add_child(dm)
	dm.position = Vector3(0, 0.8, 0)
	dm.scale = Vector3.ONE * 0.5
	var twd = dm.create_tween()
	twd.tween_property(dm, "scale", Vector3(7, 5, 7), 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	twd.tween_interval(0.4)
	twd.tween_property(dm, "scale", Vector3.ONE * 0.1, 0.2)
	twd.tween_callback(dm.queue_free)
	VFX.shockwave(c.global_position + Vector3.UP * 0.1, col, 9.0, 0.4)
	FX.dust(c.global_position, 1.5)
	Sfx.play("block", c.global_position, 0.8)


static func _heal(c: Node3D, d: Dictionary, revive: bool) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d) if d.get("element", "") != "" else Color(0.4, 1.0, 0.55)
	var amount = (6.0 + tier * 3.0) * (3.0 if revive else 1.0)
	FX.aura(c, col, 1.0, Vector3(0, 0.9, 0), 2.2)
	Sfx.play("heal", c.global_position)
	J()._ticks(10, 0.2, func(_i):
		if not is_instance_valid(c):
			return
		if c.get("hp") != null and c.get("max_hp") != null:
			c.hp = minf(c.max_hp, c.hp + amount * 0.25)
		for f in tree().get_nodes_in_group("fighters"):
			if f != c and not Combat.hostile(c, f) and f.global_position.distance_to(c.global_position) < 6 and f.get("hp") != null:
				f.hp = minf(f.max_hp, f.hp + amount * 0.25))


## Yakın dövüş / hücum: element aurası saran yumruk-tekme serisi, elde küre ya da yıldırım
static func _melee(c: Node3D, d: Dictionary, t: Node3D, v: String, shape: String) -> void:
	var tier = int(d.get("tier", 2))
	var col = color_of(d)
	if v in ["sphere", "lightning_hand"] and c.get("model"):
		var hand: Node3D = Node3D.new()
		c.model.add_child(hand)
		hand.position = Vector3(0.35, 1.15, -0.55)
		var nm = String(d.get("name_en", "")).to_lower()
		var sz = 0.85 + tier * 0.1
		if nm.contains("big ball") or nm.contains("odama") or nm.contains("massive"):
			sz = 2.2
			hand.position.y += 0.8
		if v == "sphere":
			var body = col if d.get("element", "") != "" else Color(0.15, 0.45, 1.0)
			hand.add_child(VFX.rasengan(sz, body, body.lightened(0.6)))
		else:
			hand.add_child(VFX.lightning_ball(sz * 0.8, col))
		Sfx.play("rasengan" if v == "sphere" else "chidori", c.global_position)
		J()._hand_dash(c, t, hand, 0.45, 26.0 + tier * 2.0, info(c, d, 1.6, {"kind": "heavy", "hitstop": 0.12}), col, v == "sphere")
		return
	var hits = 3 + tier if (v in ["fist", "palm", "lotus", "gates", ""] and shape == "melee") else 1
	var dur = 0.25 + 0.06 * hits if shape == "melee" else 0.4 + tier * 0.05
	var speed = 14.0 if shape == "melee" else 26.0
	var inf = info(c, d, 1.4 / hits)
	if v in ["lotus", "kick"]:
		inf["launch"] = 9.0 + tier
	var aura = FX.aura(c, col, 0.6 + tier * 0.1, Vector3(0, 0.9, 0), dur + 0.3)
	var el: String = d.get("element", "")
	if el == "":
		var wt = VFX.trail(c, 0.9, Color(1, 1, 1), col.lightened(0.4), Color(col.r, col.g, col.b, 0), 10, 1.0)
		if wt:
			c.get_tree().create_timer(dur + 0.2).timeout.connect(func(): if is_instance_valid(wt): wt.target = null)
	if el != "" and c.get("model"):
		# elemente bürünmüş yumruk/bıçak + hareket izi
		var fist: Node3D = VFX.element_core(el, col, 0.45 + tier * 0.06)
		c.model.add_child(fist)
		fist.position = Vector3(0.35, 1.15, -0.6)
		c.get_tree().create_timer(dur + 0.35).timeout.connect(fist.queue_free)
		var tr = VFX.element_trail(c, el, col, 0.9 + tier * 0.15)
		if tr:
			c.get_tree().create_timer(dur + 0.2).timeout.connect(func(): if is_instance_valid(tr): tr.target = null)
	var hit_list = []
	var cnt = {"n": 0, "t": 0.0}
	if c.get("model"):
		c.model.play(["jab", "cross", "hook"][randi() % 3], 0.05, 1.6, true)
	J()._dash(c, t, dur, speed, func(pt: Vector3):
		cnt["t"] += 1.0 / 60.0
		if cnt["t"] >= dur / hits * (cnt["n"] + 1) or shape != "melee":
			var got = Combat.hit_sphere(c, pt, 1.4 + tier * 0.15, inf, [] if shape == "melee" else hit_list)
			if shape != "melee":
				hit_list.append_array(got)
			if shape == "melee":
				cnt["n"] += 1
				if c.get("model"):
					c.model.play(["jab", "cross", "hook"][cnt["n"] % 3], 0.03, 1.8, true)
			if not got.is_empty():
				if el != "":
					impact_for(el, pt + Vector3.UP * 0.8, col, 0.45 + tier * 0.08)
				else:
					FX.hit_spark(pt, col, 0.8)
			elif el != "" and shape == "melee":
				VFX.shockwave(pt + Vector3.UP * 0.9, col.lightened(0.3), 2.4, 0.14, false)
		if shape != "melee" and randf() < 0.5:
			FX.burst(pt, {"amount": 3, "life": 0.3, "size": 0.7, "vmin": 1, "vmax": 3, "colors": [col.lightened(0.4), Color(col.r, col.g, col.b, 0)]}), func():
		if v in ["lotus", "gates"] or tier >= 4:
			FX.impact(c.global_position + c.face_dir() * 1.5, col, 0.8 + tier * 0.2)
			if Game.world:
				Game.world.env.add_shake(0.3 + tier * 0.1))
	Sfx.play("whoosh", c.global_position, 1.2)

