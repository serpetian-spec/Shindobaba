class_name ClanJutsu
extends Node
## Klan / kekkei genkai teknikleri: her jutsunun kendi koreografisi ve oyun etkisi var (genel şablon yok).
## Jutsu.execute önce burada "c_<id>" arar. Etkiler gerçek oyun durumlarıdır:
##   bind (kımıldayamaz), sealed (chakra noktaları kapalı: jutsu yapamaz), marked (fazla hasar alır),
##   slow, burn (zehir/kanama gibi sürekli hasar), stun, blind (hedefi kaybeder), mirror (gölgeyle taklit)
## ve alan etkileri (kemik ormanı, sis, fırtına bulutu), çağrılan birimler (ClanConstruct), oyuncu kipleri (uçuş, zırh).

# Atma koreografisi (CastAnim stili): her jutsuya uygun el/gövde hareketi
const STYLE := {
	"hakke_sanjuni_sho": "rush", "hakke_hyakunijuhachi_sho": "rush", "hakke_hasangeki": "two_palm", "juken": "rush", "jukenho_ichigekishin": "rush",
	"kage_nageami_shibari_no_jutsu": "ground", "kagezukami_no_jutsu": "ground", "kageyose_no_jutsu": "ground", "kagemane_shuriken_no_jutsu": "throw",
	"kage_nui_no_jutsu": "ground", "kagemane_kage_shibari_no_jutsu": "sense",
	"shinranshin_no_jutsu": "sense", "shindenshin_no_jutsu": "sense", "shinten_kugutsu_juin_no_jutsu": "sense", "shinten_bunshin_no_jutsu": "sense",
	"shindenshin_no_jin": "sense", "kanchi_denden": "sense",
	"chodan_bakugeki": "power", "cho_modo": "power", "karori_kontororu": "power", "bubun_baika_no_jutsu": "power", "nikudan_hari_sensha": "power",
	"cho_baika_no_jutsu": "power", "choharite": "palm",
	"mushikui": "two_palm", "mushi_bunshin_no_jutsu": "clone", "mushi_jamingu_no_jutsu": "two_palm", "hijutsu_mushidama": "two_palm",
	"kidaichu_mushikui": "summon", "mushi_kabe": "power",
	"tsuga": "rush", "jujin_bunshin": "clone", "shikyaku_no_jutsu": "power", "garoga": "rush", "dainamikku_makingu": "throw",
	"tsubaki_no_mai": "rush", "tessenka_no_mai_hana": "charge", "tessenka_no_mai_tsuru": "charge", "karamatsu_no_mai": "power",
	"sawarabi_no_mai": "ground", "bone_armor": "power",
	"hakke_no_fuin_shiki": "scroll", "fuja_hoin": "scroll", "shikoku_fuin": "scroll", "fuka_hoin": "scroll", "kinbaku_kingusari_no_jutsu": "scroll",
	"mizudeppo_nicho": "palm", "suiton_gosuiwan_no_jutsu": "power", "suiton_tate_eboshi": "ground",
	"sarutobi_haisekisho": "breath", "katon_goen_no_jutsu": "breath", "katon_haijingakure_no_jutsu": "breath", "sarutobi_hien": "charge",
	"hatake_hakko": "charge", "hatake_ninken": "summon", "chakura_to_maichimonji": "charge", "hatake_tsubame": "rush",
	"chinoike_ketsuryugan": "sense", "chinoike_kanshu": "sense", "chinoike_tetsu": "ground", "chinoike_kekkai": "sense", "chinoike_chi_no_ame": "sky",
	"hoshigaki_same": "two_palm", "suiro_sameodori_no_jutsu": "two_palm", "suiton_senshokuko": "sky", "suiton_daikodan_no_jutsu": "two_palm",
	"kurama_genjutsu": "sense", "kurama_kokuangyo": "sense", "magen_kokoni_arazu_no_jutsu": "sense", "magen_jubaku_satsu": "sense",
	"magen_niju_kokoni_arazu_no_jutsu": "sense",
	"fuma_shuriken_j": "throw", "fuma_kaze": "palm", "sofushasan_no_tachi": "throw", "shuriken_kage_bunshin_no_jutsu": "throw", "fuma_kaze_guruma": "throw",
	"kamizuru_bees": "two_palm", "kamizuru_wax": "breath", "kamizuru_hachi": "summon", "kamizuru_hari": "two_palm", "kamizuru_mitsu_bunshin": "clone",
	"kusa_boheki": "power", "suna_no_yoroi": "power", "gokusa_maiso": "ground", "suna_bunshin": "clone", "suna_shuriken": "throw",
	"sabaku_soso": "ground", "sabaku_suna_no_kumo": "ground",
	"kurohigi_kiki_ippatsu": "summon", "kiko_junbu": "summon", "kugutsu_no_jutsu": "summon", "akahigi_hyakki_no_soen": "summon",
	"shirohigi_jikki_chikamatsu_no_shu": "summon",
	"chigiri_toho_honenuki": "rush", "sairento_kiringu": "sense", "karatachi_suijin_giri": "charge", "karatachi_kirisame": "sense",
	"karatachi_nanatachi": "flicker", "karatachi_kubikiri": "charge",
	"doton_goremu_no_jutsu": "ground", "doton_keijugan_no_jutsu": "power", "doton_iwayado_kuzushi": "ground", "doton_kakogan": "power",
	"doton_koka_jutsu": "power", "doton_kajugan_no_jutsu": "palm", "doton_chokajugan_no_jutsu": "palm",
	"erubo": "rush", "girochin_doroppu": "rush", "jigokuzuki": "charge", "raiga_bomu": "rush", "raiton_rariatto": "rush",
	"katon_goka_mekkyaku": "breath", "katon_hosenka_tsumabeni": "throw", "uchiha_kaenjin": "ground", "uchihagaeshi": "power",
	"uchiha_ryu_kenjutsu": "rush", "uchiha_ryu_shurikenjutsu_ikazuchi_sanren": "throw",
	"sumi_bunshin_no_jutsu": "clone", "sumigasumi_no_jutsu": "breath", "choju_giga": "summon", "fuinjutsu_okutopasu_horudo": "summon", "choshin_giga": "summon",
	"ranton_reiza_sakasu": "sky", "ikazuchi_reiza_ame": "sky", "ikazuchi_koga": "charge", "ikazuchi_raiun": "sky", "ikazuchi_kosen": "palm",
	"futon_mugen_sajin_daitoppa": "breath", "kazahana_sajin_senpu": "two_palm", "kazahana_kazekiri_mai": "spin", "kazahana_sabaku_arashi": "sky",
	"kazahana_fujin_ya": "throw",
	"bakuha_jirai": "ground", "bakuha_kibaku_te": "palm", "bakuha_rensa": "ground",
	"jinton_kaku": "two_palm", "jinton_ensui": "two_palm", "jinton_ento": "sky", "jinton_genkai_hakuri_no_jutsu": "two_palm",
}

static var _inst: ClanJutsu = null


static func get_inst() -> ClanJutsu:
	if _inst == null or not is_instance_valid(_inst):
		_inst = ClanJutsu.new()
		_inst.name = "ClanJutsu"
		Jutsu.add_child(_inst)
	return _inst


static func handles(id: String) -> bool:
	return get_inst().has_method("c_" + id)


static func cast(c: Node3D, id: String, t: Node3D) -> void:
	get_inst().call("c_" + id, c, t)


# ================================================================== yardımcılar
const UCHIHA_FIRE := [Color(1, 0.85, 0.3, 1), Color(1, 0.55, 0.08, 1), Color(0.95, 0.3, 0.04, 0.9), Color(0.7, 0.1, 0.03, 0)]


func J() -> Node:
	return Jutsu


func gp(p: Vector3) -> Vector3:
	return Vector3(p.x, Game.ground_height(p.x, p.z), p.z)


func mult(c: Node3D) -> float:
	return Jutsu._mult(c)


func inf(c: Node3D, id: String, mul: float, extra := {}) -> Dictionary:
	return Jutsu._inf(c, id, mul, extra)


func tg(c: Node3D, t: Node3D, rng: float) -> Node3D:
	return Jutsu._tg(c, t, rng)


func fwd(c: Node3D, t: Node3D) -> Vector3:
	return Jutsu._aim_flat(c, t)


func hit(c: Node3D, pos: Vector3, r: float, info: Dictionary, exclude: Array = []) -> Array:
	return Combat.hit_sphere(c, pos, r, info, exclude)


func live(n) -> bool:
	return n != null and is_instance_valid(n) and not n.is_dead()


func st(t: Node3D, n: String, d: float) -> void:
	if live(t) and t.has_method("apply_status"):
		t.apply_status(n, d)


func enemies_near(c: Node3D, pos: Vector3, r: float) -> Array:
	var out = []
	for f in get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(pos) <= r + f.radius:
			out.append(f)
	return out


## dur saniye boyunca her dt'de fn(i, k) (k: 0..1 ilerleme), bitince done
func every(dur: float, dt: float, fn: Callable, done := Callable()) -> void:
	var n = maxi(1, int(dur / dt))
	var ep = VFX.epic
	var tw = create_tween()
	for i in n:
		tw.tween_callback(func():
			var o = VFX.epic
			VFX.epic = ep
			fn.call(i, float(i) / n)
			VFX.epic = o)
		tw.tween_interval(dt)
	if done.is_valid():
		tw.tween_callback(done)


func after(sec: float, fn: Callable) -> void:
	var ep = VFX.epic
	get_tree().create_timer(sec).timeout.connect(func():
		var o = VFX.epic
		VFX.epic = ep
		fn.call()
		VFX.epic = o)


## Sahneye yerleştirilmiş MB modeli (vertex renkli toon) ya da özel malzemeli
func place(b: MB, pos: Vector3, mat: Material = null, parent: Node = null) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon() if mat == null else null)
	if mat:
		mi.material_override = mat
	(parent if parent else get_tree().current_scene).add_child(mi)
	mi.global_position = pos
	return mi


func glow(col: Color, a := 1.0) -> Material:
	return JutsuEngine.glow_mat(col, a)


func fade_free(n: Node3D, delay: float, dur := 0.4) -> void:
	after(delay, func():
		if not is_instance_valid(n):
			return
		var tw = n.create_tween()
		tw.tween_property(n, "scale", n.scale * 0.05, dur).set_ease(Tween.EASE_IN)
		tw.tween_callback(n.queue_free))


func shake(s: float) -> void:
	if Game.world:
		Game.world.env.add_shake(s)


func busy(c: Node3D, dur: float) -> void:
	if c is Player:
		c.combat.action = "cast"
		c.combat.t = -10.0
		after(dur, func():
			if is_instance_valid(c) and c.combat.action == "cast":
				c.combat.action = "")


func anim(c: Node3D, key: String, speed := 1.4) -> void:
	if c.get("model"):
		c.model.play(key, 0.05, speed, true)


func chakra_gain(c: Node3D, amt: float) -> void:
	if c is Player:
		c.chakra = minf(c.max_chakra, c.chakra + amt)
		Combat.popup_text(c.global_position + Vector3.UP * 2.3, "+%d chakra" % int(amt), Color(0.5, 0.75, 1.0))


func heal(c: Node3D, amt: float) -> void:
	c.hp = minf(c.max_hp, c.hp + amt)
	Combat.popup_text(c.global_position + Vector3.UP * 2.3, "+%d" % int(amt), Color(0.5, 1.0, 0.5))


## Chakra noktalarını kapat: hedef dur sn jutsu yapamaz; üstünde mavi tenketsu noktaları söner
func seal_points(t: Node3D, dur: float, col := Color(0.55, 0.8, 1.0)) -> void:
	if not live(t):
		return
	st(t, "sealed", dur)
	Combat.popup_text(t.global_position + Vector3.UP * (t.height + 1.0), "Chakra noktaları kapandı!", col)
	var b = MB.new()
	for k in 12:
		var a = k * 0.52
		b.add("sphere", Vector3(cos(a) * t.radius * 1.1, 0.4 + (k % 4) * t.height * 0.22, sin(a) * t.radius * 1.1), Vector3.ONE * 0.09, Color.WHITE, Vector3.ZERO, 5)
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(null)
	mi.material_override = glow(col)
	t.add_child(mi)
	every(dur, 0.25, func(i, _k):
		if is_instance_valid(mi):
			mi.visible = i % 2 == 0 or i > dur * 3.0, func():
		if is_instance_valid(mi):
			mi.queue_free())


## Hedefin üstüne iliştirilmiş, süre sonunda kaybolan görsel
func attach(t: Node3D, n: Node3D, dur: float, offset := Vector3.ZERO) -> void:
	if not is_instance_valid(t):
		n.queue_free()
		return
	t.add_child(n)
	n.position = offset
	after(dur, func():
		if is_instance_valid(n):
			n.queue_free())


## Yere çizilen düz çember/desen (trigram, mühür, kan gölü)
func ground_disc(pos: Vector3, r: float, col: Color, dur: float, rings := 3, spokes := 8) -> Node3D:
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = gp(pos) + Vector3.UP * 0.06
	var m = glow(col, 0.85)
	for k in rings:
		var tor = MeshInstance3D.new()
		var tm = TorusMesh.new()
		var rr = r * (1.0 - k * 0.28)
		tm.inner_radius = rr - 0.08
		tm.outer_radius = rr
		tm.rings = 48
		tor.mesh = tm
		tor.material_override = m
		tor.scale = Vector3(1, 0.05, 1)
		root.add_child(tor)
	for k in spokes:
		var bar = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.1, 0.02, r * 0.95)
		bar.mesh = bm
		bar.material_override = m
		bar.rotation.y = k * TAU / spokes
		bar.position = Vector3(sin(k * TAU / spokes), 0, cos(k * TAU / spokes)) * r * 0.48
		root.add_child(bar)
	root.scale = Vector3(0.1, 1, 0.1)
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "rotation:y", 0.6, dur)
	tw.tween_property(root, "scale", Vector3(0.01, 1, 0.01), 0.2)
	tw.tween_callback(root.queue_free)
	return root


## Yerden fışkıran sivri (kemik, kan demiri, kaya, kum): kalıcı engel olabilir
func spike(pos: Vector3, h: float, w: float, col: Color, dur: float, tilt := Vector3.ZERO, solid := false) -> Node3D:
	var b = MB.new()
	b.add_grad("cone", Vector3(0, h * 0.5, 0), Vector3(w, h, w), col.lightened(0.15), col.darkened(0.35), Vector3.ZERO, 7)
	var mi = place(b, gp(pos), null)
	mi.rotation_degrees = tilt
	if solid:
		var sb = StaticBody3D.new()
		var cs = CollisionShape3D.new()
		var cy = CylinderShape3D.new()
		cy.radius = w * 0.3
		cy.height = h * 0.8
		cs.shape = cy
		cs.position.y = h * 0.4
		sb.add_child(cs)
		mi.add_child(sb)
	mi.scale = Vector3(1, 0.05, 1)
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_interval(dur)
	tw.tween_property(mi, "scale", Vector3(1, 0.02, 1), 0.35).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)
	return mi


## Atış: c'den dir yönünde mermi (mesh + iz), on_hit isteğe bağlı
func shot(c: Node3D, from: Vector3, dir: Vector3, speed: float, mesh: Node3D, info: Dictionary, homing: Node3D = null, pierce := false, life := 2.4, on_hit := Callable()) -> Projectile:
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = dir.normalized() * speed
	pr.info = info
	pr.life = life
	pr.pierce = pierce
	pr.radius = 0.35
	if homing:
		pr.homing = homing
		pr.homing_turn = 3.0
	if on_hit.is_valid():
		pr.on_hit = on_hit
	if mesh:
		pr.add_child(mesh)
	get_tree().current_scene.add_child(pr)
	pr.global_position = from
	if dir.length() > 0.01:
		pr.look_at(from + dir, Vector3.UP if absf(dir.normalized().y) < 0.95 else Vector3.RIGHT)
	return pr


func mesh_of(b: MB, mat: Material = null) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon() if mat == null else null)
	if mat:
		mi.material_override = mat
	return mi


## Gölge/zincir/iplik gibi iki nokta arası uzanan şerit; upd her karede uçları yeniler
func tether(a_fn: Callable, b_fn: Callable, w: float, mat: Material, dur: float) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(w, w * 0.6, 1.0)
	mi.mesh = bm
	mi.material_override = mat
	get_tree().current_scene.add_child(mi)
	var upd = func(_i, _k):
		var a: Vector3 = a_fn.call()
		var b: Vector3 = b_fn.call()
		var L = maxf(0.05, a.distance_to(b))
		var f = (b - a) / L
		if f.length() < 0.5:
			return
		mi.global_transform = Transform3D(Basis.looking_at(f, Vector3.UP if absf(f.y) < 0.95 else Vector3.RIGHT).scaled(Vector3(1, 1, L)), a + f * L * 0.5)
	upd.call(0, 0.0)
	every(dur, 1.0 / 30.0, upd, func(): mi.queue_free())
	return mi


func flat_mat(col: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if col.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


## Yanıltıcı kopya: düşmanlar ona saldırır, vurulunca dağılır (on_pop çağrılır)
func decoy(c: Node3D, pos: Vector3, dur: float, on_pop := Callable()) -> Node3D:
	var d = ShadowClone.new()
	d.team = c.team
	d.look = c.model.look.duplicate() if c.get("model") else {}
	d.life = dur
	get_tree().current_scene.add_child(d)
	d.global_position = gp(pos)
	if on_pop.is_valid():
		d.tree_exiting.connect(func():
			var at = d.global_position
			on_pop.call_deferred(at))
	for e in enemies_near(c, pos, 30.0):
		if e is Enemy:
			e.target = d
	return d


# ================================================================== HYŪGA — Yumuşak Yumruk: iç hasar + kapanan chakra noktaları
## Hyūga ortak: Byakugan damarları + ellerde mavi chakra alevi (jutsu boyunca)
func _byakugan_on(c: Node3D, dur: float) -> void:
	if c.get("model") and c.model.has_method("set_dojutsu_eyes"):
		c.model.set_dojutsu_eyes(2, 1, 2, 1, true)
		after(dur, func():
			if is_instance_valid(c) and c.get("model"):
				if c is Player and c.combat and c.combat.modes and c.combat.modes.eyes:
					c.combat.modes.eyes.refresh_visual()
				else:
					c.model.set_dojutsu_eyes(0, 0, 0, 0, false))
	for side in ["LeftHand", "RightHand"]:
		var fx = VFX.lightning_ball(0.35, Color(0.55, 0.8, 1.0))
		if c.get("model") and c.model.skel and c.model.skel.find_bone(side) >= 0:
			var ba = BoneAttachment3D.new()
			ba.bone_name = side
			c.model.skel.add_child(ba)
			ba.add_child(fx)
			after(dur, func(): if is_instance_valid(ba): ba.queue_free())


## Parlayan chakra avucu izi: vuruş noktasında açılıp sönen mavi el silueti
func _palm_flash(pos: Vector3, dir: Vector3, size := 0.9) -> void:
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(0.9, 1.0, 0.18), Color.WHITE, Vector3.ZERO, 12)
	for k in 4:
		b.add("cyl", Vector3(-0.33 + k * 0.22, 0.75 + (0.1 if k in [1, 2] else 0.0), 0), Vector3(0.16, 0.6, 0.12), Color.WHITE, Vector3(0, 0, -10 + k * 7), 6)
	b.add("cyl", Vector3(0.55, 0.1, 0), Vector3(0.17, 0.5, 0.12), Color.WHITE, Vector3(0, 0, -55), 6)
	var mi = mesh_of(b, glow(Color(0.6, 0.85, 1.0), 0.85))
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos
	var d2 = dir if dir.length() > 0.01 else Vector3.FORWARD
	mi.look_at(pos + d2, Vector3.UP if absf(d2.normalized().y) < 0.95 else Vector3.RIGHT)
	mi.rotate_object_local(Vector3.BACK, randf_range(-0.6, 0.6))
	mi.scale = Vector3.ONE * size * 0.4
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * size * 1.2, 0.08).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "scale", Vector3.ONE * size * 1.5, 0.12)
	tw.parallel().tween_property(mi, "transparency", 1.0, 0.12)
	tw.tween_callback(mi.queue_free)


## Sekiz Trigram alanı: yerde trigram çemberi, hedefe ışınlanıp avuç dizisi, sonunda chakra noktaları kapanır
func _hakke(c: Node3D, t: Node3D, id: String, strikes: int, r: float, seal_dur: float, all_in_circle: bool) -> void:
	var tt = tg(c, t, 9.0)
	if tt == null:
		Hud.msg("Sekiz Trigram: hedef en fazla 9 metrede olmalı", Color(0.8, 0.9, 1))
		return
	var center = gp((c.global_position + tt.global_position) * 0.5)
	ground_disc(center, r * 1.4, Color(0.55, 0.8, 1.0), 0.6 + strikes * 0.012, 4, 8)
	_byakugan_on(c, 1.0 + strikes * 0.012)
	VFX.shockwave(center + Vector3.UP * 0.1, Color(0.6, 0.85, 1.0), r * 3.0, 0.4)
	if c is Player:
		VFX.cinematic(c, 1.5, 0.4)
	c.global_position = gp(tt.global_position - (tt.global_position - c.global_position).normalized() * (tt.radius + 1.0))
	if c is Player:
		c.combat.face_to(tt)
		c.combat.invuln = 0.4 + strikes * 0.012
	busy(c, 0.4 + strikes * 0.012)
	var victims = enemies_near(c, center, r) if all_in_circle else [tt]
	if not tt in victims:
		victims.append(tt)
	for v in victims:
		st(v, "stun", 0.4 + strikes * 0.012)
	var per = maxi(1, strikes / 16)
	every(strikes / per * 0.03, 0.03, func(i, _k):
		var v = victims[i % victims.size()]
		if not live(v):
			return
		anim(c, ["jab", "cross"][i % 2], 3.2)
		var pt = v.global_position + Vector3.UP * randf_range(0.7, v.height - 0.2) + Vector3(randf_range(-0.2, 0.2), 0, randf_range(-0.2, 0.2))
		FX.burst(pt, {"amount": 5, "life": 0.22, "tex": FX.tex_spark, "size": 0.7, "vmin": 2, "vmax": 6, "colors": [Color(1, 1, 1), Color(0.55, 0.8, 1.0, 0)]})
		_palm_flash(pt, (pt - c.global_position - Vector3.UP), 0.7 + float(strikes) / 160.0)
		hit(c, pt, 0.9, inf(c, id, 1.2 / (strikes / per), {"knock": 0.2, "kind": "light", "hitstop": 0.0}))
		if i % 4 == 0:
			Combat.popup_text(pt + Vector3.UP * 0.6, "%d" % mini(strikes, (i + 1) * per * 2), Color(0.8, 0.9, 1))
			Sfx.play("punch", pt, 1.4), func():
		for v in victims:
			if live(v):
				hit(c, v.global_position + Vector3.UP, 1.4, inf(c, id, 0.8, {"knock": 16.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.1}))
				seal_points(v, seal_dur)
				_palm_flash(v.global_position + Vector3.UP * 1.1, v.global_position - c.global_position, 2.2)
		VFX.shockwave(center + Vector3.UP * 0.8, Color(0.7, 0.85, 1.0), r * 2.4, 0.35, false)
		VFX.shockwave(center + Vector3.UP * 0.1, Color(0.6, 0.85, 1.0), r * 3.5, 0.5)
		Combat.popup_text(center + Vector3.UP * 3.2, "%d AVUÇ!" % strikes, Color(0.75, 0.9, 1.0))
		shake(0.6))


func c_juuken_64(c: Node3D, t: Node3D) -> void:
	_hakke(c, t, "juuken_64", 64, 4.5, 8.0, false)


func c_hakke_sanjuni_sho(c: Node3D, t: Node3D) -> void:
	_hakke(c, t, "hakke_sanjuni_sho", 32, 3.5, 5.0, false)


func c_hakke_hyakunijuhachi_sho(c: Node3D, t: Node3D) -> void:
	_hakke(c, t, "hakke_hyakunijuhachi_sho", 128, 7.0, 10.0, true)


## Jūken: üç hızlı avuç; görünmez iç hasar (zırh/blok saymaz), her darbe chakra noktası kapatır
func c_juken(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	if tt and is_instance_valid(tt):
		c.global_position = gp(tt.global_position - (tt.global_position - c.global_position).normalized() * (tt.radius + 1.0))
		if c is Player:
			c.combat.face_to(tt)
	busy(c, 0.7)
	_byakugan_on(c, 1.2)
	every(0.6, 0.2, func(i, _k):
		anim(c, ["jab", "cross", "jab"][i], 2.4)
		var p = c.global_position + Vector3.UP * 1.1 + c.face_dir() * 1.1
		_palm_flash(p, c.face_dir(), 1.0)
		FX.ring(p, Color(0.6, 0.85, 1.0), 1.6, 0.2, false, c.face_dir())
		for h in hit(c, p, 1.0, inf(c, "juken", 0.55, {"knock": 1.0, "kind": "light", "pierce_guard": true})):
			var ripple = MeshInstance3D.new()
			ripple.mesh = VFX._sphere(0.5, 16, 8)
			ripple.material_override = glow(Color(0.55, 0.8, 1.0), 0.6)
			attach(h, ripple, 0.3, Vector3.UP * 1.1)
			var tw = ripple.create_tween()
			tw.tween_property(ripple, "scale", Vector3.ONE * 2.2, 0.3)
			seal_points(h, 1.5 * (i + 1))
		Sfx.play("punch", p, 1.2))


## Tek Darbe Beden: tek avuç, şok dalgası hedefin içinden geçip arkasındakileri de vurur
func c_jukenho_ichigekishin(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 0.6)
	_byakugan_on(c, 1.0)
	anim(c, "cross", 1.2)
	after(0.25, func():
		var p = c.global_position + Vector3.UP * 1.1 + d * 1.2
		_palm_flash(p, d, 2.0)
		VFX.shockwave(p, Color(0.7, 0.88, 1.0), 7.0, 0.3, false, d)
		VFX.star(p, Color(0.8, 0.92, 1.0), 3.0, 0.15)
		for k in 6:
			var q = p + d * k * 1.6
			after(k * 0.03, func():
				FX.ring(q, Color(0.6, 0.85, 1.0), 2.6 + k * 0.6, 0.3, false, d)
				if k % 2 == 0:
					_palm_flash(q, d, 1.4 + k * 0.2)
				hit(c, q, 1.3, inf(c, "jukenho_ichigekishin", 0.6, {"knock": 9.0, "launch": 2.0, "kind": "heavy", "hitstop": 0.05})))
		shake(0.4))


## Dağ Kıran: dev, saydam chakra avucu ileri kayar; yolundaki herkes bir kez ezilip savrulur
func c_hakke_hasangeki(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(4.2, 4.8, 0.9), Color.WHITE, Vector3.ZERO, 16)
	for k in 4:
		b.add("cyl", Vector3(-1.4 + k * 0.95, 3.4 + (0.5 if k in [1, 2] else 0.0), 0), Vector3(0.75, 2.6, 0.6), Color.WHITE, Vector3(0, 0, (-12 + k * 8)), 8)
	b.add("cyl", Vector3(2.4, 0.6, 0), Vector3(0.8, 2.2, 0.6), Color.WHITE, Vector3(0, 0, -55), 8)
	var palm = place(b, c.global_position + Vector3.UP * 5.0 + d * 3.0, VFX.mat_spiral(Color(0.9, 0.97, 1.0), Color(0.45, 0.7, 1.0), 3.0, 1.0, 3.0, 1.6))
	palm.look_at(palm.global_position + d, Vector3.UP)
	palm.scale = Vector3.ONE * 0.4
	busy(c, 0.5)
	Sfx.play("wind", c.global_position, 0.6)
	var hits = []
	var tw = palm.create_tween()
	tw.tween_property(palm, "scale", Vector3.ONE * 2.1, 0.15)
	every(0.7, 1.0 / 30.0, func(_i, k):
		palm.global_position = c.global_position + Vector3.UP * 5.0 + d * 3.0 if k < 0.02 else palm.global_position + d * 1.1
		for h in hit(c, palm.global_position - Vector3.UP * 1.2, 6.0, inf(c, "hakke_hasangeki", 1.6, {"knock": 22.0, "launch": 6.0, "kind": "heavy", "hitstop": 0.06}), hits):
			hits.append(h)
		if _i % 3 == 0:
			FX.dust(gp(palm.global_position), 1.3), func():
		VFX.shockwave(palm.global_position, Color(0.75, 0.9, 1.0), 9.0, 0.35, false, d)
		fade_free(palm, 0.0, 0.2))
	shake(0.6)


# ================================================================== NARA — gölge: bağla, taklit ettir, dik, boğ
## Kagemane: bağlanan düşman 4 sn senin hareketini aynen taklit eder (gölge taklidi)
func c_kagemane(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 22.0)
	if tt == null:
		Hud.msg("Kagemane: gölgen en fazla 22 metreye uzanır", Color(0.8, 0.8, 0.9))
		return
	Jutsu.j_kagemane(c, tt)
	var last = {"p": c.global_position}
	Combat.popup_text(tt.global_position + Vector3.UP * 3.0, "Gölge taklidi: hareketlerini kopyalıyor!", Color(0.65, 0.6, 0.85))
	every(4.0, 1.0 / 30.0, func(_i, _k):
		if not live(tt) or not is_instance_valid(c):
			return
		var dp: Vector3 = c.global_position - last["p"]
		last["p"] = c.global_position
		dp.y = 0
		tt.global_position = gp(tt.global_position + dp) if dp.length() < 3.0 else tt.global_position
		if tt.get("facing") != null and c.get("facing") != null:
			tt.facing = c.facing
		if c.get("model") and tt.get("model") and c.model.current != "" and c.model.current != tt.model.current:
			tt.model.play(c.model.current, 0.1))


## Ağ Gölge Felci: gölge ağ gibi her yöne yayılır, ağın üstündeki herkes donar
func c_kage_nageami_shibari_no_jutsu(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 8.0, 20.0))
	var m = flat_mat(Color(0.03, 0.02, 0.06, 0.9))
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = center + Vector3.UP * 0.05
	for k in 12:
		var bar = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.25, 0.02, 9.0)
		bar.mesh = bm
		bar.material_override = m
		bar.rotation.y = k * PI / 6.0
		root.add_child(bar)
	for r in [2.5, 5.0, 8.0]:
		var tor = MeshInstance3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = r - 0.12
		tm.outer_radius = r
		tor.mesh = tm
		tor.material_override = m
		tor.scale = Vector3(1, 0.03, 1)
		root.add_child(tor)
	root.scale = Vector3(0.05, 1, 0.05)
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.5).set_ease(Tween.EASE_OUT)
	Sfx.play("genjutsu", center, 0.5)
	after(0.5, func():
		for e in enemies_near(c, center, 9.0):
			st(e, "bind", 3.5)
			Combat.popup_text(e.global_position + Vector3.UP * 2.5, "Gölge ağı!", Color(0.6, 0.55, 0.8)))
	fade_free(root, 4.0, 0.4)


## Gölge Kavrama: gölgeden çıkan eller hedefe tırmanıp boğar (en fazla 3 hedef)
func c_kagezukami_no_jutsu(c: Node3D, t: Node3D) -> void:
	var list = enemies_near(c, c.global_position, 20.0)
	list.sort_custom(func(a, b): return a.global_position.distance_to(c.global_position) < b.global_position.distance_to(c.global_position))
	var m = flat_mat(Color(0.02, 0.01, 0.04, 0.95))
	for e in list.slice(0, 3):
		Jutsu._shadow_line(c, e, 4.0)
		st(e, "bind", 4.0)
		for k in 4:
			var b = MB.new()
			b.add("cyl", Vector3(0, 0.6, 0), Vector3(0.12, 1.2, 0.12), Color.WHITE, Vector3.ZERO, 5)
			for f in 3:
				b.add("cyl", Vector3((f - 1) * 0.06, 1.25, 0), Vector3(0.04, 0.25, 0.04), Color.WHITE, Vector3(0, 0, (f - 1) * 20), 4)
			var hand = mesh_of(b, m)
			hand.rotation = Vector3(0.3, k * PI * 0.5, 0.2)
			attach(e, hand, 4.0, Vector3(cos(k * 1.57) * e.radius, 0.1, sin(k * 1.57) * e.radius))
			hand.scale = Vector3(1, 0.05, 1)
			var tw = hand.create_tween()
			tw.tween_property(hand, "scale", Vector3(1, e.height * 0.8, 1), 0.6 + k * 0.1)
		every(4.0, 0.5, func(_i, _k):
			if live(e):
				hit(c, e.global_position + Vector3.UP * e.height * 0.8, 0.8, inf(c, "kagezukami_no_jutsu", 0.22, {"knock": 0.0, "kind": "light"})))


## Gölge Toplama: çevredeki gölgeler tek noktaya akar, düşmanları içine çeker ve sıkıştırır
func c_kageyose_no_jutsu(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 10.0, 22.0))
	var pool = ground_disc(center, 6.0, Color(0.05, 0.02, 0.1), 2.0, 4, 16)
	pool.get_child(0).material_override = flat_mat(Color(0.03, 0.01, 0.06, 0.9))
	every(1.6, 1.0 / 30.0, func(_i, _k):
		for e in enemies_near(c, center, 11.0):
			var v = center - e.global_position
			v.y = 0
			if v.length() > 0.8:
				e.global_position = gp(e.global_position + v.normalized() * minf(v.length(), 0.28)), func():
		for e in enemies_near(c, center, 3.0):
			st(e, "bind", 3.0)
			hit(c, e.global_position + Vector3.UP, 1.0, inf(c, "kageyose_no_jutsu", 1.2, {"knock": 0.0}))
		FX.ring(center + Vector3.UP * 0.2, Color(0.2, 0.1, 0.3), 6.0, 0.3))
	Sfx.play("genjutsu", center, 0.4)


## Gölge Taklit Shuriken: shurikenin gölgesinde ikinci gölge saklı; değdiği hedefe gölge bağlanır
func c_kagemane_shuriken_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 30.0)
	var d = (tt.global_position + Vector3.UP - Jutsu._hand(c)).normalized() if tt else Jutsu._aim(c, t)
	var b = MB.new()
	for k in 4:
		b.add("cone", Vector3(cos(k * 1.57) * 0.25, 0, sin(k * 1.57) * 0.25), Vector3(0.12, 0.45, 0.03), Color(0.3, 0.3, 0.35), Vector3(0, -k * 90, -90), 4)
	var mesh = mesh_of(b)
	var sh = mesh_of(b, flat_mat(Color(0.02, 0.01, 0.05, 0.9)))
	sh.position = Vector3(0, -0.3, 0.4)
	mesh.add_child(sh)
	var pr = shot(c, Jutsu._hand(c), d, 38.0, mesh, inf(c, "kagemane_shuriken_no_jutsu", 0.6), tt, false, 1.6, func(_pos, target):
		if live(target):
			Jutsu._shadow_line(c, target, 3.0)
			st(target, "bind", 3.0)
			Combat.popup_text(target.global_position + Vector3.UP * 2.4, "Gölge bağlandı!", Color(0.65, 0.6, 0.85)))
	pr.spin = Vector3(0, 0, 25.0)
	Sfx.play("kunai", c.global_position)


## Gölge Dikiş: gölgeden fışkıran kara iğneler birden çok hedefi deler ve yere diker
func c_kage_nui_no_jutsu(c: Node3D, t: Node3D) -> void:
	var list = enemies_near(c, c.global_position, 18.0).slice(0, 4)
	if list.is_empty():
		Hud.msg("Kage Nui: yakında hedef yok", Color(0.8, 0.8, 0.9))
		return
	for e in list:
		Jutsu._shadow_line(c, e, 1.0)
		after(0.4, func():
			if not live(e):
				return
			for k in 5:
				var a = k * TAU / 5.0
				var p = e.global_position + Vector3(cos(a), 0, sin(a)) * 1.6
				var s = spike(p, 2.6, 0.18, Color(0.05, 0.03, 0.08), 2.0, Vector3(cos(a) * 30, 0, -sin(a) * 30))
				s.look_at(e.global_position + Vector3.UP * 1.2, Vector3.UP)
				s.rotate_object_local(Vector3.RIGHT, -PI * 0.5)
			hit(c, e.global_position + Vector3.UP, 1.2, inf(c, "kage_nui_no_jutsu", 1.0, {"knock": 0.0, "kind": "heavy"}))
			st(e, "bind", 2.5))
	Sfx.play("genjutsu", c.global_position, 0.7)


## Gölge Taklit Bağı: gölge yelpaze gibi açılır, koninin içindeki herkes donar
func c_kagemane_kage_shibari_no_jutsu(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	for k in 5:
		var dd = d.rotated(Vector3.UP, (k - 2) * 0.25)
		var end = gp(c.global_position + dd * 16.0)
		var strip = tether(func(): return gp(c.global_position) + Vector3.UP * 0.05, func(): return end + Vector3.UP * 0.05, 0.6, flat_mat(Color(0.03, 0.02, 0.06, 0.9)), 3.0)
		strip.scale = Vector3.ONE
	for e in enemies_near(c, c.global_position, 16.0):
		var v = e.global_position - c.global_position
		v.y = 0
		if v.normalized().dot(d) > 0.75:
			st(e, "bind", 3.0)
	Sfx.play("genjutsu", c.global_position, 0.6)


# ================================================================== YAMANAKA — zihin
## Zihin Karıştırma: hedef 6 sn kimin dost olduğunu bilemez, yakınındakilere saldırır
func c_shinranshin_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	if tt == null or not tt is Enemy:
		Hud.msg("Shinranshin: bir düşmanı hedefle", Color(0.8, 0.7, 1))
		return
	var old = tt.team
	tt.team = "kargasa"   # herkese düşman
	tt.target = null
	var halo = MeshInstance3D.new()
	var tm = TorusMesh.new()
	tm.inner_radius = 0.35
	tm.outer_radius = 0.45
	halo.mesh = tm
	halo.material_override = glow(Color(0.85, 0.5, 1.0))
	attach(tt, halo, 6.0, Vector3.UP * (tt.height + 0.4))
	Combat.popup_text(tt.global_position + Vector3.UP * 2.6, "Zihni karıştı!", Color(0.85, 0.6, 1))
	Sfx.play("genjutsu", tt.global_position, 1.3)
	every(6.0, 0.5, func(_i, _k):
		if is_instance_valid(halo):
			halo.rotation.y += 1.2
		if live(tt) and (tt.target == null or not is_instance_valid(tt.target)):
			var best = null
			for e in enemies_near(tt, tt.global_position, 20.0):
				if e != tt:
					best = e
			tt.target = best, func():
		if is_instance_valid(tt):
			tt.team = old
			tt.target = null)


## Zihin Aktarımı: 60 m içindeki tüm düşmanların yeri ışık sütunlarıyla belli olur, saklanamazlar
func c_shindenshin_no_jutsu(c: Node3D, _t: Node3D) -> void:
	VFX.shockwave(c.global_position + Vector3.UP, Color(0.85, 0.6, 1.0), 30.0, 0.8, true)
	for e in enemies_near(c, c.global_position, 60.0):
		st(e, "marked", 15.0)
		var b = MB.new()
		b.add("cyl", Vector3(0, 6, 0), Vector3(0.3, 12, 0.3), Color.WHITE, Vector3.ZERO, 6)
		var pillar = mesh_of(b, glow(Color(0.85, 0.55, 1.0), 0.55))
		attach(e, pillar, 15.0, Vector3.ZERO)
	Hud.msg("Zihin ağı: düşmanların yerini görüyorsun", Color(0.85, 0.7, 1.0))
	Sfx.play("genjutsu", c.global_position, 1.5)


## Lanetli Mühürlü Zihin Kuklası: hedef 15 sn senin kuklan olur, sonunda mühür onu sersemletir
func c_shinten_kugutsu_juin_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	if tt == null or not tt is Enemy or tt is Boss:
		Hud.msg("Bu teknik sıradan bir düşmanı hedef almalı", Color(0.8, 0.7, 1))
		return
	var mark = ground_disc(tt.global_position, 1.6, Color(0.6, 0.2, 0.8), 0.6, 2, 6)
	mark.reparent(tt)
	tt.team = c.team
	tt.target = null
	tt.power = float(tt.power) * 1.4
	Combat.popup_text(tt.global_position + Vector3.UP * 2.6, "Zihin kuklası!", Color(0.8, 0.5, 1))
	var a = FX.aura(tt, Color(0.65, 0.25, 0.95), 1.0, Vector3(0, 0.9, 0), 0.0)
	after(15.0, func():
		if is_instance_valid(a):
			a.emitting = false
		if live(tt):
			tt.team = "enemy"
			tt.power = float(tt.power) / 1.4
			tt.target = null
			st(tt, "stun", 3.0)
			seal_points(tt, 6.0, Color(0.75, 0.4, 1.0)))


## Zihin Klon Değişimi: hedefin zihnine kısa süre gir ve kendi jutsusunu kendi müttefiklerine attır
func c_shinten_bunshin_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	if tt == null or not tt is Enemy:
		return
	var others = enemies_near(c, tt.global_position, 25.0).filter(func(e): return e != tt)
	FX.ring(tt.global_position + Vector3.UP, Color(0.8, 0.5, 1.0), 3.0, 0.3, false)
	if others.is_empty():
		st(tt, "stun", 2.5)
		return
	var old = tt.team
	tt.team = c.team
	var jl: Array = tt.arch.get("jutsu", []) if tt.get("arch") else []
	if jl.is_empty():
		hit(tt, others[0].global_position + Vector3.UP, 1.5, inf(c, "shinten_bunshin_no_jutsu", 1.4, {"knock": 8.0, "kind": "heavy"}))
	else:
		Jutsu.execute(tt, jl.pick_random(), others[0])
	Combat.popup_text(tt.global_position + Vector3.UP * 2.6, "Kendi dostuna saldırdı!", Color(0.8, 0.6, 1))
	after(1.2, func():
		if is_instance_valid(tt):
			tt.team = old
			st(tt, "stun", 1.5))


## Zihin Aktarım Düzeni: çağrılan birimlerin ve klonların zihnine bağlan: 20 sn hepsi güçlenir
func c_shindenshin_no_jin(c: Node3D, _t: Node3D) -> void:
	var allies = []
	for f in get_tree().get_nodes_in_group("fighters"):
		if f != c and f.get("team") == c.team and f.global_position.distance_to(c.global_position) < 40.0:
			allies.append(f)
	for a in allies:
		tether(func(): return c.global_position + Vector3.UP * 1.6, func(): return a.global_position + Vector3.UP * 1.4 if is_instance_valid(a) else c.global_position, 0.06, glow(Color(0.85, 0.6, 1.0)), 20.0)
		if a.get("dmg") != null:
			a.dmg = float(a.dmg) * 1.5
	if c is Player:
		Buffs.add("shindenshin_no_jin", 20.0, {"jutsu": 1.2, "melee": 1.2})
	Hud.msg("Zihin ağı: %d müttefik bağlandı" % allies.size(), Color(0.85, 0.7, 1.0))


## Algılama Aktarımı: chakra nabzı 80 m'ye yayılır, düşmanlar 10 sn işaretli kalır ve yavaşlar
func c_kanchi_denden(c: Node3D, _t: Node3D) -> void:
	for k in 3:
		after(k * 0.25, func(): VFX.shockwave(c.global_position + Vector3.UP * 0.3, Color(0.6, 0.85, 1.0), 40.0, 0.9, true))
	for e in enemies_near(c, c.global_position, 80.0):
		st(e, "marked", 10.0)
		var b = MB.new()
		b.add("cone", Vector3.ZERO, Vector3(0.5, 0.8, 0.5), Color.WHITE, Vector3(180, 0, 0), 4)
		var arrow = mesh_of(b, glow(Color(1.0, 0.4, 0.3)))
		attach(e, arrow, 10.0, Vector3.UP * (e.height + 0.9))
	Sfx.play("genjutsu", c.global_position, 1.8)


# ================================================================== AKİMİCHİ — beden boyutu, kalori, kelebek
func c_baika(c: Node3D, t: Node3D) -> void:
	Jutsu.j_baika(c, t)
	after(0.45, func():
		# devleşen beden yere çöker: çevredekiler ezilir
		var p = gp(c.global_position)
		VFX.cracks(p, 7.0)
		VFX.shockwave(p + Vector3.UP * 0.2, Color(1.0, 0.85, 0.6), 14.0, 0.4)
		FX.dust(p, 2.5)
		hit(c, p + Vector3.UP, 5.0, inf(c, "baika", 1.4, {"knock": 14.0, "launch": 5.0, "kind": "heavy", "element": "doton"}))
		shake(0.9)
		Sfx.play("boom", p, 0.6))


## Kısmi Büyüme: kollar devleşir (20 sn uzun erim) ve hemen dev yumruk hedefin üstüne iner
func c_bubun_baika_no_jutsu(c: Node3D, t: Node3D) -> void:
	var at = gp(Jutsu._aim_ground(c, t, 6.0, 10.0))
	if c is Player:
		Buffs.add("bubun_baika", 20.0, {"reach": 2.6, "melee": 1.5})
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(2.4, 2.0, 2.8), Color(0.95, 0.75, 0.6), Vector3.ZERO, 12)
	for k in 4:
		b.add("sphere", Vector3(-0.9 + k * 0.6, 0.7, -1.2), Vector3(0.6, 0.6, 0.7), Color(0.92, 0.72, 0.58), Vector3.ZERO, 8)
	var fist = place(b, at + Vector3.UP * 12.0)
	busy(c, 0.6)
	var tw = fist.create_tween()
	tw.tween_property(fist, "global_position", at + Vector3.UP * 1.2, 0.28).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		VFX.cracks(at, 6.0)
		FX.impact(at, Color(1, 0.85, 0.6), 1.8)
		hit(c, at + Vector3.UP, 3.5, inf(c, "bubun_baika_no_jutsu", 1.6, {"knock": 10.0, "launch": 2.0, "kind": "heavy"}))
		shake(0.7)
		Sfx.play("boom", at, 0.7))
	fade_free(fist, 0.6, 0.3)


## Süper Büyüme: dağ gibi devleşirsin; her adımın yeri sarsar
func c_cho_baika_no_jutsu(c: Node3D, _t: Node3D) -> void:
	if not c is Player:
		return
	c.combat.modes.set_size(7.0, 15.0)
	Buffs.add("cho_baika", 15.0, {"melee": 2.6, "speed": 0.8, "armor": 0.5, "reach": 3.6})
	FX.smoke_puff(c.global_position + Vector3.UP * 3.0, 3.5, 30)
	every(15.0, 0.9, func(_i, _k):
		if not is_instance_valid(c):
			return
		var p = gp(c.global_position)
		if Vector2(c.velocity.x, c.velocity.z).length() > 1.0:
			FX.dust(p, 2.0)
			VFX.shockwave(p + Vector3.UP * 0.1, Color(0.9, 0.8, 0.6), 18.0, 0.35)
			hit(c, p + Vector3.UP, 8.0, inf(c, "cho_baika_no_jutsu", 0.5, {"knock": 8.0, "launch": 3.0, "kind": "heavy"}))
			shake(0.35))
	Hud.msg("Chō Baika! (15 sn dağ gibi)", Color(1, 0.8, 0.5))


## Kalori Kontrolü: yağ chakraya dönüşür: canın bir kısmı gider, chakra dolar, jutsuların güçlenir
func c_karori_kontororu(c: Node3D, _t: Node3D) -> void:
	var cost = c.max_hp * 0.15
	c.hp = maxf(1.0, c.hp - cost)
	chakra_gain(c, cost * 2.5)
	if c is Player:
		Buffs.add("karori", 15.0, {"jutsu": 1.3, "melee": 1.2})
	var a = FX.aura(c, Color(1.0, 0.8, 0.25), 1.2, Vector3(0, 0.9, 0), 15.0)
	FX.burst(c.global_position + Vector3.UP, {"amount": 30, "life": 0.6, "size": 0.5, "vmin": 2, "vmax": 6, "colors": [Color(1, 0.9, 0.4), Color(1, 0.6, 0.1, 0)]})
	Sfx.play("levelup", c.global_position, 0.8, 0.5)


## Dikenli İnsan Mermisi: dikenli dev top; her düşmanı yarım saniyede bir yeniden ezer ve kanatır
func c_nikudan_hari_sensha(c: Node3D, t: Node3D) -> void:
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(3.2, 3.2, 3.2), Color(0.85, 0.62, 0.45), Vector3.ZERO, 14)
	for k in 26:
		var dir = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var bs = Basis(Quaternion(Vector3.UP, dir))
		b.add_xf("cone", Transform3D(bs * Basis.from_scale(Vector3(0.28, 0.9, 0.28)), dir * 1.75), Color(0.95, 0.92, 0.85))
	var ball = mesh_of(b)
	c.add_child(ball)
	ball.position = Vector3(0, 1.6, 0)
	c.model.visible = false
	var last = {}
	Jutsu._dash(c, t, 1.6, 24.0, func(pt):
		ball.rotation.x -= 0.4
		FX.dust(gp(c.global_position), 0.6)
		for e in enemies_near(c, pt, 2.4):
			if Time.get_ticks_msec() - int(last.get(e.get_instance_id(), 0)) > 450:
				last[e.get_instance_id()] = Time.get_ticks_msec()
				hit(c, e.global_position + Vector3.UP, 1.0, inf(c, "nikudan_hari_sensha", 0.6, {"knock": 9.0, "launch": 3.0, "kind": "heavy", "burn": 3.0})), func():
		ball.queue_free()
		if is_instance_valid(c):
			c.model.visible = true)
	Sfx.play("earth", c.global_position, 0.8)


func _butterfly_wings(c: Node3D, dur: float) -> Node3D:
	var root = Node3D.new()
	var m = VFX.mat_spiral(Color(1.0, 0.9, 0.95), Color(1.0, 0.45, 0.65), 2.0, 1.0, 2.0, 1.8)
	for sx in [-1.0, 1.0]:
		for k in 2:
			var b = MB.new()
			b.add("sphere", Vector3(1.0 * sx, 0.5 - k * 1.0, 0), Vector3(1.8 - k * 0.5, 1.4 - k * 0.4, 0.06), Color.WHITE, Vector3(0, 0, 25 * sx * (1 - k * 2)), 12)
			var w = mesh_of(b, m)
			root.add_child(w)
			var tw = w.create_tween().set_loops()
			tw.tween_property(w, "rotation:y", 0.35 * sx, 0.3)
			tw.tween_property(w, "rotation:y", -0.15 * sx, 0.3)
	attach(c, root, dur, Vector3(0, 1.5, 0.35))
	return root


## Kelebek Bombası: kelebek kanatları açılır, gökten dev chakra yumruğu iner: krater
func c_chodan_bakugeki(c: Node3D, t: Node3D) -> void:
	var at = gp(Jutsu._aim_ground(c, t, 8.0, 18.0))
	_butterfly_wings(c, 1.6)
	busy(c, 1.2)
	c.velocity.y = 16.0
	after(0.55, func():
		if not is_instance_valid(c):
			return
		c.global_position = at + Vector3.UP * 8.0
		c.velocity = Vector3(0, -40, 0)
		var fist = MeshInstance3D.new()
		fist.mesh = VFX._sphere(3.2, 18, 10)
		fist.material_override = VFX.mat_spiral(Color(1, 0.9, 0.95), Color(1.0, 0.4, 0.6), 3.0, 1.0, 4.0, 2.0)
		c.add_child(fist)
		fist.position = Vector3(0, 0.6, -0.8)
		after(0.25, func():
			fist.queue_free()
			VFX.cracks(at, 18.0)
			VFX.shockwave(at + Vector3.UP * 0.3, Color(1.0, 0.6, 0.75), 34.0, 0.5)
			FX.impact(at, Color(1, 0.55, 0.7), 4.0)
			VFX.debris(at, Color(0.5, 0.42, 0.32), 22, 14.0, 0.6)
			hit(c, at + Vector3.UP, 9.5, inf(c, "chodan_bakugeki", 2.0, {"knock": 18.0, "launch": 8.0, "kind": "heavy", "hitstop": 0.12}))
			shake(1.2)
			Sfx.play("boom", at, 0.5)))


## Kelebek Modu: kalori patlaması: kanatlar, ×2.2 yakın dövüş, hız ve zırh; her saniye can yakar
func c_cho_modo(c: Node3D, _t: Node3D) -> void:
	_butterfly_wings(c, 25.0)
	var a = FX.aura(c, Color(1.0, 0.5, 0.7), 1.6, Vector3(0, 0.9, 0), 25.0)
	if c is Player:
		Buffs.add("cho_modo", 25.0, {"melee": 2.2, "speed": 1.3, "armor": 0.6, "reach": 1.6})
	every(25.0, 1.0, func(_i, _k):
		if is_instance_valid(c):
			c.hp = maxf(1.0, c.hp - c.max_hp * 0.01))
	VFX.shockwave(c.global_position + Vector3.UP, Color(1.0, 0.6, 0.8), 14.0, 0.5, false)
	Hud.msg("Chō Mōdo! Kalorilerin yanıyor (25 sn)", Color(1, 0.6, 0.75))


## Süper Tokat: dev açık el yandan savrulur, önündeki yarım dairede herkesi yere yapıştırır
func c_choharite(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var side = d.cross(Vector3.UP)
	var b = MB.new()
	b.add("box", Vector3.ZERO, Vector3(0.6, 3.4, 2.8), Color(0.95, 0.75, 0.6))
	for k in 4:
		b.add("box", Vector3(0, 2.3, -1.05 + k * 0.7), Vector3(0.55, 1.5, 0.55), Color(0.93, 0.73, 0.58))
	var hand = mesh_of(b)
	var pivot = Node3D.new()
	get_tree().current_scene.add_child(pivot)
	pivot.global_position = c.global_position + Vector3.UP * 1.5
	pivot.look_at(pivot.global_position + d, Vector3.UP)
	pivot.add_child(hand)
	hand.position = Vector3(3.5, 0, -3.0)
	pivot.rotation.y += 1.4
	busy(c, 0.5)
	var hits = []
	var tw = pivot.create_tween()
	tw.tween_property(pivot, "rotation:y", pivot.rotation.y - 2.8, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	every(0.3, 1.0 / 30.0, func(_i, _k):
		for h in hit(c, hand.global_position, 2.4, inf(c, "choharite", 1.6, {"knock": 20.0, "launch": 1.0, "kind": "heavy", "hitstop": 0.08}), hits):
			hits.append(h)
			st(h, "stun", 1.2))
	fade_free(pivot, 0.5, 0.2)
	Sfx.play("punch", c.global_position, 0.5)


# ================================================================== ABURAME — kikaichū: yapışır, chakra emer, kör eder
## Kikaichū sürüsü + yapışma: sürünün değdiği düşmanların üstünde böcekler kalır, chakra sana akar
func c_mushi_swarm(c: Node3D, t: Node3D) -> void:
	Jutsu.j_mushi_swarm(c, t)
	var center = Jutsu._aim_ground(c, t, 10.0)
	after(1.4, func():
		for e in enemies_near(c, tt_pos(t, center), 6.0):
			_insects_cling(c, e, 6.0, "mushi_swarm"))


func tt_pos(t: Node3D, fallback: Vector3) -> Vector3:
	return t.global_position if live(t) else fallback


func _insects_cling(c: Node3D, e: Node3D, dur: float, id: String) -> void:
	var cloud = Projectile.trail(e, [Color(0.06, 0.06, 0.05), Color(0.08, 0.08, 0.06), Color(0.06, 0.06, 0.05, 0)], 0.25, 50, 0.6, null, false)
	cloud.position = Vector3.UP * e.height * 0.5
	after(dur, func():
		if is_instance_valid(cloud):
			cloud.emitting = false)
	st(e, "slow", dur)
	every(dur, 0.6, func(_i, _k):
		if live(e):
			hit(c, e.global_position + Vector3.UP, 0.8, inf(c, id, 0.12, {"knock": 0.0, "kind": "light"}))
			if _i % 3 == 0:
				chakra_gain(c, 2.0))


## Böcek Isırığı: böcekler tek hedefe akın edip chakrasını yer: 4 sn jutsu yapamaz, chakrası sana geçer
func c_mushikui(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 16.0)
	if tt == null:
		return
	tether(func(): return Jutsu._hand(c), func(): return tt.global_position + Vector3.UP if is_instance_valid(tt) else Jutsu._hand(c), 0.35, flat_mat(Color(0.05, 0.05, 0.04, 0.85)), 0.7)
	after(0.6, func():
		if live(tt):
			_insects_cling(c, tt, 4.0, "mushikui")
			seal_points(tt, 4.0, Color(0.4, 0.5, 0.3))
			chakra_gain(c, 18.0))
	Sfx.play("wind", c.global_position, 2.2, 0.5)


## Böcek Klonu: düşmanları üstüne çeken klon; vurulunca böcek bulutuna dağılıp vuranlara yapışır
func c_mushi_bunshin_no_jutsu(c: Node3D, _t: Node3D) -> void:
	decoy(c, c.global_position + c.global_transform.basis.x * 2.5, 12.0, func(p: Vector3):
		FX.burst(p + Vector3.UP, {"amount": 60, "life": 0.8, "size": 0.12, "vmin": 2, "vmax": 7, "add": false, "colors": [Color(0.06, 0.06, 0.05), Color(0.06, 0.06, 0.05, 0)]})
		for e in enemies_near(c, p, 5.0):
			_insects_cling(c, e, 5.0, "mushi_bunshin_no_jutsu"))
	FX.smoke_puff(c.global_position + Vector3.UP, 0.8, 10)


## Böcek Karıştırma: böcek sisi alana çöker: içindekiler seni kaybeder, algılama ve jutsu bozulur
func c_mushi_jamingu_no_jutsu(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 8.0, 18.0))
	FX.burst(center + Vector3.UP * 1.5, {"amount": 220, "life": 5.0, "size": 0.14, "vmin": 0.5, "vmax": 2.0, "add": false, "gravity": Vector3.ZERO,
		"colors": [Color(0.05, 0.05, 0.04, 0.0), Color(0.05, 0.05, 0.04, 0.9), Color(0.05, 0.05, 0.04, 0)]})
	every(5.0, 0.5, func(_i, _k):
		for e in enemies_near(c, center, 7.0):
			if e.has_method("lose_target"):
				e.lose_target(1.0)
			st(e, "sealed", 1.0))
	Sfx.play("wind", center, 2.4, 0.6)


## Böcek Küresi: böcek kabuğu hedefi tamamen sarar, 4 sn hapseder ve chakrasını emer
func c_hijutsu_mushidama(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	if tt == null:
		return
	var sp = MeshInstance3D.new()
	sp.mesh = VFX._sphere(0.5, 20, 12)
	sp.material_override = VFX.mat_spiral(Color(0.2, 0.22, 0.15), Color(0.04, 0.04, 0.03), 9.0, 4.0, 3.0, 0.6)
	sp.scale = Vector3.ONE * (tt.height + 0.6)
	attach(tt, sp, 4.0, Vector3.UP * tt.height * 0.5)
	st(tt, "bind", 4.0)
	every(4.0, 0.5, func(_i, _k):
		if live(tt):
			hit(c, tt.global_position + Vector3.UP, 1.0, inf(c, "hijutsu_mushidama", 0.2, {"knock": 0.0}))
			if _i % 2 == 0:
				chakra_gain(c, 3.0))
	Sfx.play("wind", tt.global_position, 2.0, 0.5)


## Dev Parazit Böcekleri: yerde koşan dev kınkanatlılar (ClanConstruct) düşmanları ısırır
func c_kidaichu_mushikui(c: Node3D, _t: Node3D) -> void:
	ClanConstruct.spawn(c, "beetle", 3, Jutsu._jd("kidaichu_mushikui"))
	Sfx.play("wind", c.global_position, 1.6, 0.6)


## Böcek Duvarı: etrafında dönen böcek kubbesi 8 sn mermileri yutar, değenin chakrasını emer
func c_mushi_kabe(c: Node3D, _t: Node3D) -> void:
	var dome = MeshInstance3D.new()
	dome.mesh = VFX._sphere(0.5, 24, 12)
	dome.material_override = VFX.mat_spiral(Color(0.22, 0.24, 0.16, 0.9), Color(0.03, 0.03, 0.02), 12.0, 3.0, 4.0, 0.5)
	dome.scale = Vector3.ONE * 6.0
	attach(c, dome, 8.0, Vector3.UP * 1.0)
	every(8.0, 0.1, func(_i, _k):
		if not is_instance_valid(c):
			return
		dome.rotation.y += 0.3
		for n in get_tree().current_scene.get_children():
			if n is Projectile and not n.dead and n.shooter != c and Combat.hostile(c, n.shooter) and n.global_position.distance_to(c.global_position + Vector3.UP) < 3.4:
				FX.burst(n.global_position, {"amount": 10, "life": 0.4, "size": 0.15, "vmin": 1, "vmax": 3, "add": false, "colors": [Color(0.06, 0.06, 0.05), Color(0.06, 0.06, 0.05, 0)]})
				n.queue_free()
		if _i % 5 == 0:
			for e in enemies_near(c, c.global_position, 3.6):
				hit(c, e.global_position + Vector3.UP, 0.8, inf(c, "mushi_kabe", 0.15, {"knock": 5.0}))
				chakra_gain(c, 2.0))
	Sfx.play("wind", c.global_position, 2.2, 0.6)


# ================================================================== İNUZUKA — ninken ile çift hücum
## Gatsūga: matkap hücumu bitince sekip geri döner ve ikinci kez çarpar
func c_gatsuga(c: Node3D, t: Node3D) -> void:
	Jutsu.j_gatsuga(c, t)
	after(1.05, func():
		if is_instance_valid(c) and live(t) and t.global_position.distance_to(c.global_position) < 15.0:
			Jutsu.j_gatsuga(c, t))


## Tsūga: küçük matkap; ilk çarptığından en yakın sonraki düşmana seker (en fazla 3)
func c_tsuga(c: Node3D, t: Node3D) -> void:
	var chain = []
	var tt = tg(c, t, 14.0)
	var drill = Projectile.energy_mesh(Color(0.9, 0.85, 0.75), Color(0.5, 0.4, 0.3), 0.8, 30.0, 0.0, 1.0)
	drill.scale = Vector3(1.4, 2.0, 1.4)
	c.add_child(drill)
	drill.position = Vector3(0, 1.0, 0)
	var step = func(next_t):
		Jutsu._dash(c, next_t, 0.45, 26.0, func(pt):
			c.model.rotation.y += 1.4
			for h in hit(c, pt, 1.4, inf(c, "tsuga", 1.0, {"knock": 10.0, "launch": 4.0, "kind": "heavy"}), chain):
				chain.append(h))
	step.call(tt)
	every(1.4, 0.47, func(i, _k):
		if i == 0:
			return
		var nxt = null
		for e in enemies_near(c, c.global_position, 9.0):
			if not e in chain:
				nxt = e
		if nxt:
			step.call(nxt), func():
		drill.queue_free()
		if is_instance_valid(c):
			c.model.rotation.y = 0.0)
	Sfx.play("wind", c.global_position, 1.8)


## Canavar-İnsan Klonu: ninken sana dönüşür, 20 sn yanında senin gibi dövüşür
func c_jujin_bunshin(c: Node3D, _t: Node3D) -> void:
	var at = c.global_position + c.global_transform.basis.x * 2.0
	for n in get_tree().get_nodes_in_group("ninken"):
		at = n.global_position
		n.visible = false
		after(20.0, func():
			if is_instance_valid(n):
				n.visible = true)
	FX.smoke_puff(at + Vector3.UP, 1.0, 14)
	var cl = ShadowClone.new()
	cl.team = c.team
	cl.look = c.model.look.duplicate()
	cl.life = 20.0
	get_tree().current_scene.add_child(cl)
	cl.global_position = gp(at)
	FX.aura(cl, Color(0.85, 0.3, 0.2), 0.8, Vector3(0, 0.9, 0), 20.0)
	Hud.msg("Jūjin Bunshin: ninken sana dönüştü", Color(0.95, 0.75, 0.6))


## Dört Ayak: vahşi kip: tırnaklar uzar, hız ve yakın dövüş artar
func c_shikyaku_no_jutsu(c: Node3D, _t: Node3D) -> void:
	if c is Player:
		Buffs.add("shikyaku", 20.0, {"speed": 1.35, "melee": 1.35})
	FX.aura(c, Color(0.95, 0.35, 0.2), 1.0, Vector3(0, 0.9, 0), 20.0)
	for side in [-1.0, 1.0]:
		var b = MB.new()
		for k in 3:
			b.add("cone", Vector3((k - 1) * 0.05, 0, -0.12), Vector3(0.03, 0.22, 0.03), Color(0.95, 0.93, 0.88), Vector3(-90, 0, 0), 4)
		var claw = mesh_of(b)
		attach(c, claw, 20.0, Vector3(0.35 * side, 1.0, -0.35))
	Sfx.play("roar", c.global_position, 1.6, 0.6)


## Çift Kurt Dişi: sen ve ninken iki dev kurt kafalı matkap; hedefte birleşip patlarsınız
func c_garoga(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 25.0)
	var target_p = tt.global_position if tt else c.global_position + fwd(c, t) * 14.0
	var side = fwd(c, t).cross(Vector3.UP)
	for k in 2:
		var start = c.global_position + Vector3.UP + side * (3.0 if k == 0 else -3.0)
		var head = JutsuEngine.shape_mesh("beast", Color(0.85, 0.82, 0.78), 2.4, "")
		var dd = (target_p + Vector3.UP - start).normalized()
		var pr = shot(c, start, dd, 30.0, head, inf(c, "garoga", 1.2, {"knock": 18.0, "launch": 7.0, "kind": "heavy"}), tt, true, 1.2)
		pr.spin = Vector3(0, 0, 18.0)
		Projectile.trail(pr, [Color(1, 1, 1), Color(0.8, 0.75, 0.7), Color(0.6, 0.55, 0.5, 0)], 1.8, 40, 0.4)
	after(0.55, func():
		VFX.shockwave(gp(target_p) + Vector3.UP, Color(0.95, 0.9, 0.8), 14.0, 0.4, false)
		FX.impact(target_p + Vector3.UP, Color(0.9, 0.85, 0.75), 2.0)
		hit(c, target_p + Vector3.UP, 4.0, inf(c, "garoga", 1.4, {"knock": 20.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.12}))
		shake(0.9))
	busy(c, 0.6)
	Sfx.play("roar", c.global_position, 0.9)


## İz İşaretleme: hedef 20 sn işaretli: senden ve ninkenden %25 fazla hasar alır, saklanamaz
func c_dainamikku_makingu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	if tt == null:
		return
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(0.4, 0.4, 0.4), Color.WHITE, Vector3.ZERO, 8)
	shot(c, Jutsu._hand(c), (tt.global_position + Vector3.UP - Jutsu._hand(c)).normalized(), 30.0, mesh_of(b, glow(Color(0.95, 0.85, 0.3))), {"dmg": 1.0, "knock": 0.0}, tt, false, 1.5, func(_p, target):
		if live(target):
			st(target, "marked", 20.0)
			var tag = MeshInstance3D.new()
			tag.mesh = VFX._sphere(0.3, 10, 6)
			tag.material_override = glow(Color(0.95, 0.8, 0.25))
			attach(target, tag, 20.0, Vector3.UP * (target.height + 0.7))
			Combat.popup_text(target.global_position + Vector3.UP * 2.4, "İşaretlendi!", Color(1, 0.85, 0.3)))
	for n in get_tree().get_nodes_in_group("ninken"):
		n.tgt = tt


# ================================================================== KAGUYA — kemik dansları (her biri ayrı)
## Söğüt Dansı: bedenin her yerinden kemikler fışkırır; sonra kemik zırh
func c_bone_armor(c: Node3D, t: Node3D) -> void:
	Jutsu.j_bone_armor(c, t)
	var p = c.global_position
	for k in 16:
		var a = k * TAU / 16.0
		var dir = Vector3(cos(a), 0.25 + (k % 3) * 0.2, sin(a)).normalized()
		var b = MB.new()
		b.add_grad("cone", Vector3(0, 1.0, 0), Vector3(0.22, 2.0, 0.22), Color(0.98, 0.96, 0.9), Color(0.85, 0.82, 0.75), Vector3.ZERO, 6)
		var bone = place(b, p + Vector3.UP * (0.8 + (k % 4) * 0.3))
		bone.global_transform.basis = Basis(Quaternion(Vector3.UP, dir))
		bone.scale = Vector3(1, 0.05, 1)
		var tw = bone.create_tween()
		tw.tween_property(bone, "scale", Vector3.ONE, 0.08)
		fade_free(bone, 0.6, 0.2)
	hit(c, p + Vector3.UP, 2.6, inf(c, "bone_armor", 1.0, {"knock": 9.0, "kind": "heavy"}))
	Sfx.play("hit_heavy", p, 1.3)


func _bone_blade(c: Node3D, len_: float, dur: float) -> Node3D:
	var b = MB.new()
	b.add_grad("cone", Vector3(0, 0, -len_ * 0.5), Vector3(0.2, len_, 0.16), Color(0.98, 0.96, 0.9), Color(0.82, 0.78, 0.7), Vector3(-90, 0, 0), 6)
	b.add("sphere", Vector3.ZERO, Vector3(0.22, 0.22, 0.22), Color(0.95, 0.92, 0.85), Vector3.ZERO, 6)
	var bl = mesh_of(b)
	attach(c, bl, dur, Vector3(0.38, 1.15, -0.45))
	return bl


## Kamelya Dansı: kolundan çektiğin kemik kılıçla altı hızlı saplama; her biri önündeki hattı deler
func c_tsubaki_no_mai(c: Node3D, t: Node3D) -> void:
	var bl = _bone_blade(c, 1.4, 1.3)
	busy(c, 1.2)
	every(1.2, 0.2, func(i, _k):
		var d = fwd(c, t)
		c.velocity = d * 9.0 + Vector3(0, c.velocity.y, 0)
		anim(c, ["jab", "cross"][i % 2], 2.6)
		bl.position.z = -0.45 - (0.5 if i % 2 == 0 else 0.2)
		var p = c.global_position + Vector3.UP * 1.1
		for k in 3:
			hit(c, p + d * (1.0 + k * 0.9), 0.7, inf(c, "tsubaki_no_mai", 0.3, {"knock": 2.0, "kind": "light", "burn": 1.0}))
		FX.burst(p + d * 2.2, {"amount": 5, "life": 0.25, "size": 0.4, "vmin": 2, "vmax": 5, "colors": [Color(1, 1, 0.95), Color(1, 1, 1, 0)]})
		Sfx.play("kunai", p, 1.3))


## Clematis Çiçeği: kol sarmal kemik matkaba dönüşür; yüklenip tek dev saplama: blok ve zırh delinir
func c_tessenka_no_mai_hana(c: Node3D, t: Node3D) -> void:
	var b = MB.new()
	for k in 7:
		b.add_grad("cone", Vector3(0, 0, -0.4 - k * 0.45), Vector3(0.9 - k * 0.11, 0.7, 0.9 - k * 0.11), Color(0.98, 0.96, 0.9), Color(0.8, 0.76, 0.68), Vector3(-90, k * 25, 0), 7)
	var drill = mesh_of(b)
	attach(c, drill, 1.3, Vector3(0.3, 1.1, -0.4))
	drill.scale = Vector3.ONE * 0.2
	var tw = drill.create_tween()
	tw.tween_property(drill, "scale", Vector3.ONE, 0.45)
	busy(c, 1.2)
	after(0.5, func():
		var hits = []
		Jutsu._dash(c, t, 0.35, 34.0, func(pt):
			if is_instance_valid(drill):
				drill.rotation.z += 0.8
			for h in hit(c, pt + c.face_dir() * 1.5, 1.8, inf(c, "tessenka_no_mai_hana", 2.6, {"knock": 16.0, "launch": 3.0, "kind": "heavy", "pierce_guard": true, "hitstop": 0.1}), hits):
				hits.append(h)
				VFX.debris(h.global_position + Vector3.UP, Color(0.95, 0.92, 0.85), 10, 8.0, 0.3)))
	Sfx.play("whoosh", c.global_position, 0.6)


## Clematis Sarmaşığı: uzun omurga kamçısı hedefe dolanır, onu sana çeker ve bağlar
func c_tessenka_no_mai_tsuru(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 16.0)
	if tt == null:
		return
	var segs = []
	for k in 14:
		var b = MB.new()
		b.add("sphere", Vector3.ZERO, Vector3(0.3, 0.26, 0.36), Color(0.96, 0.93, 0.86), Vector3.ZERO, 6)
		b.add("cone", Vector3(0, 0.22, 0), Vector3(0.1, 0.2, 0.1), Color(0.9, 0.86, 0.78), Vector3.ZERO, 4)
		var s = place(b, Jutsu._hand(c))
		segs.append(s)
	st(tt, "bind", 1.6)
	every(1.6, 1.0 / 30.0, func(_i, k):
		if not is_instance_valid(c):
			return
		var a = Jutsu._hand(c)
		var bpos = tt.global_position + Vector3.UP if live(tt) else a
		if k > 0.35 and live(tt):   # çek
			var v = c.global_position - tt.global_position
			v.y = 0
			if v.length() > 1.6:
				tt.global_position = gp(tt.global_position + v.normalized() * 0.5)
		for n in segs.size():
			var f = float(n) / (segs.size() - 1)
			var p = a.lerp(bpos, f) + Vector3.UP * sin(f * PI) * 1.2 + Vector3(sin(f * 9.0 + _i * 0.3), 0, cos(f * 9.0)) * 0.15
			segs[n].global_position = p, func():
		for s in segs:
			s.queue_free()
		if live(tt):
			hit(c, tt.global_position + Vector3.UP, 1.2, inf(c, "tessenka_no_mai_tsuru", 1.2, {"knock": 4.0, "kind": "heavy"}))
			st(tt, "bind", 1.5))
	Sfx.play("whoosh", c.global_position, 1.1)


## Karaçam Dansı: tüm bedenden sivri kemikler çıkar: 8 sn yanına gelen her düşman delinir, gelen hasar azalır
func c_karamatsu_no_mai(c: Node3D, _t: Node3D) -> void:
	var b = MB.new()
	for k in 30:
		var dir = Vector3(randf_range(-1, 1), randf_range(-0.3, 1), randf_range(-1, 1)).normalized()
		var bs = Basis(Quaternion(Vector3.UP, dir))
		b.add_xf("cone", Transform3D(bs * Basis.from_scale(Vector3(0.1, 0.65, 0.1)), dir * 0.42 + Vector3.UP * randf_range(0.3, 1.5)), Color(0.97, 0.95, 0.88))
	var spikes = mesh_of(b)
	attach(c, spikes, 8.0, Vector3.ZERO)
	if c is Player:
		Buffs.add("karamatsu", 8.0, {"armor": 0.5})
	every(8.0, 0.4, func(_i, _k):
		if is_instance_valid(c):
			hit(c, c.global_position + Vector3.UP, 1.9, inf(c, "karamatsu_no_mai", 0.25, {"knock": 6.0, "kind": "light", "burn": 1.0})))
	Sfx.play("hit_heavy", c.global_position, 1.1)


## Eğrelti Dansı: hedef bölgede merkezden dışa dev kemik ormanı yükselir: deler, mıhlar, 10 sn duvar gibi kalır
func c_sawarabi_no_mai(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 10.0, 25.0))
	VFX.cracks(center, 12.0)
	busy(c, 0.8)
	var n = 64
	for k in n:
		var ring = sqrt(float(k) / n)
		var a = k * 2.4
		var p = center + Vector3(cos(a), 0, sin(a)) * ring * 18.0
		after(ring * 0.8, func():
			var h = randf_range(5.0, 11.0) * (1.25 - ring * 0.4)
			spike(p, h, randf_range(0.7, 1.3), Color(0.97, 0.95, 0.88), 10.0, Vector3(randf_range(-14, 14), 0, randf_range(-14, 14)), true)
			for e in enemies_near(c, p, 1.6):
				hit(c, e.global_position + Vector3.UP, 1.2, inf(c, "sawarabi_no_mai", 0.7, {"knock": 2.0, "launch": 6.0, "kind": "heavy"}))
				st(e, "bind", 2.0)
			if k % 6 == 0:
				FX.dust(p, 1.4))
	after(0.2, func():
		shake(1.0)
		Sfx.play("earth", center, 0.6))


# ================================================================== UZUMAKI — mühürler ve zincirler
## Sıkı Bağlayan Altın Zincir: dört altın zincir yerden çıkıp hedefe kenetlenir, onu yere çeker
func c_kinbaku_kingusari_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 22.0)
	if tt == null:
		return
	var gold = VFX.mat_spiral(Color(1.0, 0.95, 0.6), Color(1.0, 0.75, 0.2), 6.0, 1.0, 2.0, 2.0)
	for k in 4:
		var a = k * TAU / 4.0 + 0.4
		var root_p = gp(tt.global_position + Vector3(cos(a), 0, sin(a)) * 5.0)
		tether(func(): return root_p, func(): return tt.global_position + Vector3.UP * 1.1 if is_instance_valid(tt) else root_p, 0.3, gold, 4.0)
	st(tt, "bind", 4.0)
	st(tt, "stun", 1.0)
	every(4.0, 0.5, func(_i, _k):
		if live(tt):
			hit(c, tt.global_position + Vector3.UP, 0.8, inf(c, "kinbaku_kingusari_no_jutsu", 0.18, {"knock": 0.0})))
	Sfx.play("clink", tt.global_position, 0.8)
	Combat.popup_text(tt.global_position + Vector3.UP * 2.6, "Altın zincirler!", Color(1, 0.85, 0.3))


func _seal_glyph(t: Node3D, col: Color, dur: float, size := 0.9) -> void:
	var root = Node3D.new()
	var m = glow(col)
	for k in 3:
		var tor = MeshInstance3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = size * (0.3 + k * 0.25) - 0.03
		tm.outer_radius = size * (0.3 + k * 0.25)
		tor.mesh = tm
		tor.material_override = m
		tor.rotation.x = PI * 0.5
		tor.scale = Vector3(1, 0.1, 1)
		root.add_child(tor)
	for k in 4:
		var bar = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.04, size * 1.6, 0.02)
		bar.mesh = bm
		bar.material_override = m
		bar.rotation.z = k * PI / 4.0
		root.add_child(bar)
	attach(t, root, dur, Vector3(0, t.height * 0.55, -t.radius - 0.05))


## Parmak Oyma Mühürü: hedefe dokunup karnına mühür kazırsın: 10 sn jutsu yapamaz ve yavaşlar
func c_shikoku_fuin(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	if tt == null:
		Hud.msg("Mühür için hedefe dokunacak kadar yaklaş (6 m)", Color(0.9, 0.8, 0.6))
		return
	c.global_position = gp(tt.global_position - (tt.global_position - c.global_position).normalized() * (tt.radius + 0.9))
	anim(c, "cross", 1.4)
	after(0.2, func():
		if live(tt):
			_seal_glyph(tt, Color(0.6, 0.85, 1.0), 10.0)
			seal_points(tt, 10.0)
			st(tt, "slow", 10.0)
			Sfx.play("seal", tt.global_position))


## Ateş Mühürleme: parşömen açılır, 3 sn çevredeki düşman mermilerini yutar; yuttuğu ateşi geri kusar
func c_fuka_hoin(c: Node3D, t: Node3D) -> void:
	var b = MB.new()
	b.add("cyl", Vector3.ZERO, Vector3(0.35, 2.4, 0.35), Color(0.85, 0.78, 0.6), Vector3(0, 0, 90), 10)
	b.add("box", Vector3(0, -0.6, 0.02), Vector3(2.2, 1.2, 0.02), Color(0.95, 0.92, 0.82))
	var scroll = place(b, c.global_position + Vector3.UP * 1.6 + c.face_dir() * 1.2)
	scroll.look_at(c.global_position + Vector3.UP * 1.6, Vector3.UP)
	var store = {"fire": 0, "n": 0}
	busy(c, 3.0)
	every(3.0, 1.0 / 20.0, func(_i, _k):
		FX.ring(scroll.global_position, Color(0.85, 0.75, 0.5), 3.0, 0.2, false, c.face_dir())
		for n in get_tree().current_scene.get_children():
			if n is Projectile and not n.dead and n.shooter != c and Combat.hostile(c, n.shooter) and n.global_position.distance_to(scroll.global_position) < 14.0:
				var v = scroll.global_position - n.global_position
				if v.length() < 1.2:
					store["n"] += 1
					if String(n.info.get("element", "")) in ["katon", "yoton"]:
						store["fire"] += 1
					FX.burst(scroll.global_position, {"amount": 8, "life": 0.3, "size": 0.4, "vmin": 1, "vmax": 3, "colors": [Color(1, 0.9, 0.6), Color(1, 0.8, 0.4, 0)]})
					n.queue_free()
				else:
					n.vel = v.normalized() * maxf(n.vel.length(), 18.0), func():
		if store["n"] > 0:
			chakra_gain(c, store["n"] * 8.0)
		if store["fire"] > 0:
			Jutsu._stream(c, t, 1.0 + store["fire"] * 0.3, Color(1.0, 0.55, 0.15), "katon", 4.0 * mult(c) * store["fire"], "fire")
		fade_free(scroll, 0.0, 0.3))
	Sfx.play("seal", c.global_position, 0.8)


## Sekiz Trigram Mühür Stili: avuçla hedefin karnına dev trigram mühürü: 15 sn jutsu yok, gücü yarıya iner
func c_hakke_no_fuin_shiki(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	if tt == null:
		Hud.msg("Sekiz Trigram Mühürü: hedefe 6 metre içinde dokunmalısın", Color(0.9, 0.8, 0.6))
		return
	ground_disc(tt.global_position, 3.5, Color(0.3, 0.3, 0.35), 1.2, 3, 8)
	anim(c, "cross", 1.2)
	after(0.25, func():
		if not live(tt):
			return
		_seal_glyph(tt, Color(0.15, 0.15, 0.2), 15.0, 1.3)
		seal_points(tt, 15.0, Color(0.9, 0.9, 1.0))
		if tt.get("power") != null:
			tt.power = float(tt.power) * 0.5
			after(15.0, func():
				if is_instance_valid(tt):
					tt.power = float(tt.power) * 2.0)
		VFX.shockwave(tt.global_position + Vector3.UP, Color(0.9, 0.9, 1.0), 6.0, 0.3, false)
		Combat.popup_text(tt.global_position + Vector3.UP * 2.8, "Mühürlendi: güç yarıya indi", Color(0.9, 0.9, 1))
		Sfx.play("seal", tt.global_position, 0.7))


## Kötülük Mühürleme: üstündeki her etki silinir (bağ, sersemleme, zehir, mühür); 10 sn genjutsu ve sersemlemeye bağışıksın
func c_fuja_hoin(c: Node3D, _t: Node3D) -> void:
	ground_disc(c.global_position, 3.0, Color(1.0, 0.85, 0.4), 1.0, 2, 12)
	for k in ["bind", "stun", "burn", "slow", "sealed", "fear", "mud", "chilled", "frozen"]:
		if c.get("statuses") != null:
			c.statuses.erase(k)
	if c is Player:
		c.input_locked = 0.0
	_seal_glyph(c, Color(1.0, 0.85, 0.4), 10.0, 1.1)
	every(10.0, 0.1, func(_i, _k):
		if is_instance_valid(c) and c.get("statuses") != null:
			for k in ["stun", "fear", "bind"]:
				c.statuses.erase(k))
	Combat.popup_text(c.global_position + Vector3.UP * 2.4, "Mühürle arındın!", Color(1, 0.9, 0.5))
	Sfx.play("seal", c.global_position, 1.1)


# ================================================================== HŌZUKİ — su beden, basınçlı su
## Çift Su Tabancası: iki elden sırayla sekiz basınçlı su mermisi; delip geçer, ıslatır
func c_mizudeppo_nicho(c: Node3D, t: Node3D) -> void:
	busy(c, 0.9)
	every(0.9, 0.11, func(i, _k):
		var side = c.global_transform.basis.x * (0.35 if i % 2 == 0 else -0.35)
		var from = c.global_position + Vector3.UP * 1.3 + side + c.face_dir() * 0.5
		var d = Jutsu._aim(c, t)
		var drop = JutsuEngine.shape_mesh("needles", Color(0.4, 0.75, 1.0), 0.45, "suiton")
		shot(c, from, d, 46.0, drop, inf(c, "mizudeppo_nicho", 0.2, {"knock": 3.0, "kind": "light"}), null, true, 1.2)
		VFX.splash(from + d * 0.4, 0.4)
		Sfx.play("water", from, 1.6, 0.4))


## Büyük Su Kolu: kol suyla şişip dev yumruğa dönüşür; ileri savurur, 10 sn kolun dev kalır
func c_suiton_gosuiwan_no_jutsu(c: Node3D, t: Node3D) -> void:
	var arm = VFX.water_ball(1.4)
	attach(c, arm, 10.0, Vector3(0.45, 1.1, -0.5))
	if c is Player:
		Buffs.add("gosuiwan", 10.0, {"melee": 1.6, "reach": 1.8})
	busy(c, 0.45)
	after(0.25, func():
		var d = fwd(c, t)
		var p = c.global_position + Vector3.UP * 1.1 + d * 2.0
		VFX.splash(p, 3.0)
		VFX.shockwave(p, Color(0.5, 0.8, 1.0), 6.0, 0.3, false, d)
		hit(c, p, 2.4, inf(c, "suiton_gosuiwan_no_jutsu", 1.8, {"knock": 18.0, "launch": 3.0, "kind": "heavy", "hitstop": 0.1}))
		Sfx.play("water", p, 0.7))


## Su Kalkanı (Tate Eboshi): önünde yükselen su duvarı 6 sn mermileri yutar, yaklaşanı geri iter
func c_suiton_tate_eboshi(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var b = MB.new()
	b.add("box", Vector3(0, 2.0, 0), Vector3(7.0, 4.0, 0.6), Color.WHITE)
	var wall = place(b, gp(c.global_position + d * 2.5), VFX.mat_water())
	wall.look_at(wall.global_position + d, Vector3.UP)
	wall.scale = Vector3(1, 0.05, 1)
	var tw = wall.create_tween()
	tw.tween_property(wall, "scale", Vector3.ONE, 0.25).set_ease(Tween.EASE_OUT)
	every(6.0, 0.1, func(_i, _k):
		for n in get_tree().current_scene.get_children():
			if n is Projectile and not n.dead and Combat.hostile(c, n.shooter) and n.global_position.distance_to(wall.global_position + Vector3.UP * 2.0) < 3.8:
				VFX.splash(n.global_position, 1.0)
				n.queue_free()
		for e in enemies_near(c, wall.global_position, 3.0):
			var v = e.global_position - c.global_position
			v.y = 0
			e.global_position = gp(e.global_position + v.normalized() * 0.4))
	fade_free(wall, 6.0, 0.4)
	Sfx.play("water", c.global_position, 0.6)


# ================================================================== SARUTOBİ — kül ve ateş
## Kül Yığını Yakma: dişlerden kızgın kül bulutu üflenir; içindekiler kör olur, bir buçuk saniye sonra bulut patlar
func c_sarutobi_haisekisho(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var origin = Jutsu._mouth(c)
	var pts = []
	for k in 6:
		pts.append(origin + d * (2.5 + k * 1.8) + Vector3(randf_range(-1, 1), randf_range(-0.3, 0.6), randf_range(-1, 1)))
	for p in pts:
		FX.burst(p, {"amount": 26, "life": 1.6, "tex": FX.tex_smoke, "add": false, "size": 2.0, "vmin": 0.2, "vmax": 1.0, "gravity": Vector3(0, 0.3, 0),
			"colors": [Color(0.35, 0.33, 0.32, 0.0), Color(0.3, 0.28, 0.27, 0.9), Color(0.25, 0.22, 0.2, 0)]})
	for e in enemies_near(c, origin + d * 6.0, 7.0):
		if e.has_method("lose_target"):
			e.lose_target(1.6)
	Sfx.play("wind", origin, 0.6)
	after(1.5, func():
		Sfx.play("clink", c.global_position, 1.6)   # dişler çakar: kıvılcım
		for i in pts.size():
			var p = pts[i]
			after(i * 0.06, func():
				VFX.explosion(p, 1.1, Color(1.0, 0.5, 0.12))
				hit(c, p, 2.6, inf(c, "sarutobi_haisekisho", 0.45, {"knock": 9.0, "launch": 3.0, "kind": "heavy"})))
		shake(0.8))


## Büyük Alev: geniş ateş seli, ardında 4 sn yanan zemin bırakır
func c_katon_goen_no_jutsu(c: Node3D, t: Node3D) -> void:
	Jutsu._stream(c, t, 1.6, Color(1.0, 0.5, 0.12), "katon", 5.5 * mult(c), "fire")
	var d = fwd(c, t)
	after(1.6, func():
		for k in 5:
			var p = gp(c.global_position + d * (4.0 + k * 3.0))
			FX.burst(p + Vector3.UP * 0.4, {"amount": 40, "life": 4.0, "size": 1.4, "vmin": 0.5, "vmax": 2.5, "gravity": Vector3(0, 3, 0),
				"colors": [Color(1, 0.85, 0.3), Color(1, 0.45, 0.1), Color(0.6, 0.15, 0.05, 0)]})
			every(4.0, 0.5, func(_i, _k):
				hit(c, p + Vector3.UP, 1.8, inf(c, "katon_goen_no_jutsu", 0.08, {"knock": 0.0, "kind": "light"}))))


## Küle Saklanma: yoğun kül bulutu patlar, yakındaki herkes seni kaybeder; 4 sn görünmezsin
func c_katon_haijingakure_no_jutsu(c: Node3D, _t: Node3D) -> void:
	FX.burst(c.global_position + Vector3.UP, {"amount": 90, "life": 2.5, "tex": FX.tex_smoke, "add": false, "size": 3.0, "vmin": 1, "vmax": 5,
		"colors": [Color(0.3, 0.28, 0.27, 0.0), Color(0.28, 0.26, 0.25, 0.95), Color(0.2, 0.18, 0.17, 0)]})
	for e in enemies_near(c, c.global_position, 22.0):
		if e.has_method("lose_target"):
			e.lose_target(4.0)
	if c.get("model"):
		c.model.visible = false
		after(4.0, func():
			if is_instance_valid(c):
				c.model.visible = true)
	if c is Player:
		Buffs.add("henge_ash", 4.0, {"speed": 1.2})
	Sfx.play("poof", c.global_position, 0.6)


## Uçan Kırlangıç: chakra bıçaklarına rüzgar akar, bıçak uzar; dört kesik dört rüzgar hilaline dönüşür
func c_sarutobi_hien(c: Node3D, t: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var b = MB.new()
		b.add("cone", Vector3(0, 0, -0.5), Vector3(0.12, 1.1, 0.03), Color(0.8, 0.82, 0.85), Vector3(-90, 0, 0), 4)
		var blade = mesh_of(b)
		var wind = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.02
		cm.bottom_radius = 0.18
		cm.height = 1.8
		wind.mesh = cm
		wind.material_override = VFX.mat_wind(Color(0.75, 1.0, 0.9), 8.0, 4.0, Vector3.UP, 0.7)
		wind.rotation.x = -PI * 0.5
		wind.position = Vector3(0, 0, -1.2)
		blade.add_child(wind)
		attach(c, blade, 10.0, Vector3(0.38 * side, 1.1, -0.45))
	if c is Player:
		Buffs.add("hien", 10.0, {"reach": 1.8, "melee": 1.3})
	busy(c, 0.9)
	every(0.8, 0.2, func(i, _k):
		anim(c, ["slash_a", "slash_b"][i % 2], 2.0)
		var d = fwd(c, t).rotated(Vector3.UP, (i % 2 - 0.5) * 0.3)
		var disc = JutsuEngine.shape_mesh("disc", Color(0.7, 1.0, 0.85), 0.9, "fuuton")
		var pr = shot(c, c.global_position + Vector3.UP * 1.1 + d, d, 32.0, disc, inf(c, "sarutobi_hien", 0.4, {"knock": 5.0, "kind": "light", "burn": 1.0}), null, true, 0.7)
		pr.spin = Vector3(0, 20, 0)
		Sfx.play("wind", c.global_position, 1.8, 0.5))


# ================================================================== HATAKE — beyaz chakra bıçağı, ninken
## Beyaz Işık Chakra Bıçağı: göz açıp kapayana kadar hedefin içinden geçersin; arkanda beyaz ışık çizgisi kalır
func c_hatake_hakko(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var tt = tg(c, t, 16.0)
	var start = c.global_position
	var dist = (tt.global_position.distance_to(c.global_position) + 3.0) if tt else 10.0
	var end = gp(start + d * dist)
	for k in 8:
		var p = start.lerp(end, k / 7.0) + Vector3.UP * 1.1
		hit(c, p, 1.4, inf(c, "hatake_hakko", 0.4, {"knock": 6.0, "kind": "heavy", "hitstop": 0.03}))
	c.global_position = end
	if c is Player:
		c.facing = atan2(-d.x, -d.z)
	tether(func(): return start + Vector3.UP * 1.1, func(): return end + Vector3.UP * 1.1, 0.12, glow(Color(1, 1, 1)), 0.35)
	FX.light(end + Vector3.UP, Color(0.95, 0.97, 1.0), 6.0, 8.0, 0.25)
	VFX.star(end + Vector3.UP * 1.1, Color(1, 1, 1), 3.0, 0.2)
	Sfx.play("whoosh", end, 1.6)


## Ninken Sürüsü (İz Süren Diş): ninkenler hedefin altından fışkırıp onu ısırarak yere çiviler
func c_hatake_ninken(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 30.0)
	if tt == null:
		Hud.msg("Ninken sürüsü: önce bir hedef seç", Color(0.9, 0.8, 0.6))
		return
	busy(c, 0.5)
	VFX.cracks(tt.global_position, 3.0)
	for k in 6:
		var a = k * TAU / 6.0
		var p = tt.global_position + Vector3(cos(a), 0, sin(a)) * (tt.radius + 0.5)
		var b = MB.new()
		var col = [Color(0.6, 0.5, 0.35), Color(0.25, 0.22, 0.2), Color(0.85, 0.82, 0.75)][k % 3]
		b.add("sphere", Vector3(0, 0.0, 0.3), Vector3(0.5, 0.45, 0.9), col, Vector3.ZERO, 8)
		b.add("sphere", Vector3(0, 0.25, -0.25), Vector3(0.4, 0.38, 0.42), col, Vector3.ZERO, 8)
		b.add("box", Vector3(0, 0.15, -0.5), Vector3(0.18, 0.14, 0.26), col.darkened(0.1))
		b.add("torus", Vector3(0, 0.18, -0.05), Vector3(0.32, 0.32, 0.32), Color(0.2, 0.25, 0.5), Vector3(80, 0, 0), 10)
		var dog = place(b, gp(p) - Vector3.UP * 0.8)
		dog.look_at(tt.global_position, Vector3.UP)
		var tw = dog.create_tween()
		tw.tween_property(dog, "global_position", gp(p) + Vector3.UP * (0.5 + (k % 3) * 0.3), 0.15).set_delay(k * 0.04)
		fade_free(dog, 3.0, 0.3)
	FX.dust(tt.global_position, 1.6)
	st(tt, "bind", 3.0)
	every(3.0, 0.4, func(_i, _k):
		if live(tt):
			hit(c, tt.global_position + Vector3.UP * 0.8, 0.9, inf(c, "hatake_ninken", 0.15, {"knock": 0.0}))
			Sfx.play("punch", tt.global_position, 1.6, 0.4))
	Combat.popup_text(tt.global_position + Vector3.UP * 2.4, "Ninkenler yakaladı!", Color(0.9, 0.8, 0.6))


## Chakra Bıçağı: Düz Hat: bıçağın chakrayla 15 m uzar ve önündeki her şeyi tek çizgide yarar
func c_chakura_to_maichimonji(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 0.6)
	after(0.3, func():
		var a = c.global_position + Vector3.UP * 1.1 + d * 0.5
		var b = a + d * 15.0
		tether(func(): return a, func(): return b, 0.18, glow(Color(0.85, 0.95, 1.0)), 0.25)
		for k in 10:
			hit(c, a.lerp(b, k / 9.0), 0.9, inf(c, "chakura_to_maichimonji", 0.25, {"knock": 6.0, "kind": "heavy"}))
		anim(c, "slash_a", 2.2)
		Sfx.play("whoosh", a, 1.4))


## Kırlangıç Dönüşü: ileri atılırken bir hilal kesik, aynı yoldan geri dönerken ikinci kesik
func c_hatake_tsubame(c: Node3D, t: Node3D) -> void:
	var start = c.global_position
	var d = fwd(c, t)
	var hits1 = []
	var hits2 = []
	busy(c, 0.9)
	every(0.8, 1.0 / 30.0, func(i, k):
		var ph = k * 2.0
		var target_p = start + d * (10.0 * (ph if ph < 1.0 else 2.0 - ph))
		c.global_position = gp(target_p)
		var p = c.global_position + Vector3.UP * 1.1
		if i % 3 == 0:
			VFX.star(p, Color(1, 1, 1), 1.0, 0.1)
		for h in hit(c, p, 1.6, inf(c, "hatake_tsubame", 0.9, {"knock": 7.0, "kind": "heavy"}), hits1 if ph < 1.0 else hits2):
			(hits1 if ph < 1.0 else hits2).append(h))
	Sfx.play("whoosh", c.global_position, 1.3)


# ================================================================== CHİNOİKE — kan gözü, kan demiri
## Kan Genjutsusu: kızıl göz bakışı; önündeki konide herkes dehşetle donar, sonra seni kaybeder
func c_chinoike_ketsuryugan(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	FX.light(c.global_position + Vector3.UP * 1.7, Color(1.0, 0.1, 0.1), 5.0, 6.0, 0.4)
	for e in enemies_near(c, c.global_position, 16.0):
		var v = e.global_position - c.global_position
		v.y = 0
		if v.normalized().dot(d) > 0.5:
			st(e, "stun", 2.2)
			if e.has_method("lose_target"):
				after(2.2, func():
					if is_instance_valid(e):
						e.lose_target(3.0))
			var red = MeshInstance3D.new()
			red.mesh = VFX._sphere(0.5, 12, 6)
			red.material_override = glow(Color(0.8, 0.0, 0.05), 0.35)
			red.scale = Vector3.ONE * (e.height + 0.4)
			attach(e, red, 2.2, Vector3.UP * e.height * 0.5)
	Sfx.play("genjutsu", c.global_position, 0.7)


## Kan Akışı Kontrolü: 8 sn çevrende kızıl kan sisi: düşmanlar yönünü kaybeder, kanar; sen biraz iyileşirsin
func c_chinoike_kanshu(c: Node3D, _t: Node3D) -> void:
	var center = c.global_position
	FX.burst(center + Vector3.UP, {"amount": 160, "life": 8.0, "tex": FX.tex_smoke, "add": false, "size": 2.5, "vmin": 0.3, "vmax": 2.0, "gravity": Vector3.ZERO,
		"colors": [Color(0.6, 0.02, 0.05, 0.0), Color(0.55, 0.02, 0.05, 0.6), Color(0.4, 0.0, 0.03, 0)]})
	every(8.0, 0.8, func(_i, _k):
		var n = 0
		for e in enemies_near(c, center, 10.0):
			n += 1
			hit(c, e.global_position + Vector3.UP, 0.8, inf(c, "chinoike_kanshu", 0.15, {"knock": 0.0, "burn": 1.0}))
			if e.has_method("lose_target") and _i % 3 == 0:
				e.lose_target(1.0)
		if n > 0 and is_instance_valid(c):
			heal(c, 2.0 * n))
	Sfx.play("genjutsu", center, 0.5)


## Kan Demiri Mızrakları: hedefe doğru sıra sıra kızıl mızraklar fışkırır
func c_chinoike_tetsu(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	for k in 10:
		var p = c.global_position + d * (2.0 + k * 1.6)
		after(k * 0.06, func():
			spike(p, 2.6 + k * 0.15, 0.55, Color(0.62, 0.05, 0.08), 1.6, Vector3(randf_range(-15, 15), 0, randf_range(-15, 15)))
			for e in enemies_near(c, p, 1.3):
				hit(c, e.global_position + Vector3.UP, 1.0, inf(c, "chinoike_tetsu", 0.5, {"knock": 2.0, "launch": 5.0, "kind": "heavy", "burn": 1.5})))
	Sfx.play("earth", c.global_position, 1.3)


## Kan Hapsi: kızıl kan parmaklıkları hedefin etrafında kapanır; 3 sn hapseder, canını sana aktarır
func c_chinoike_kekkai(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	if tt == null:
		return
	var b = MB.new()
	for k in 10:
		var a = k * TAU / 10.0
		b.add("cyl", Vector3(cos(a) * 1.2, 1.4, sin(a) * 1.2), Vector3(0.12, 2.8, 0.12), Color(0.65, 0.04, 0.08), Vector3.ZERO, 6)
	b.add("torus", Vector3(0, 2.8, 0), Vector3(2.5, 2.5, 2.5), Color(0.5, 0.02, 0.05), Vector3.ZERO, 16)
	b.add("torus", Vector3(0, 0.05, 0), Vector3(2.5, 2.5, 2.5), Color(0.5, 0.02, 0.05), Vector3.ZERO, 16)
	var cage = mesh_of(b)
	attach(tt, cage, 3.0)
	cage.scale = Vector3(1, 0.05, 1)
	var tw = cage.create_tween()
	tw.tween_property(cage, "scale", Vector3.ONE, 0.2)
	st(tt, "bind", 3.0)
	every(3.0, 0.5, func(_i, _k):
		if live(tt):
			hit(c, tt.global_position + Vector3.UP, 0.8, inf(c, "chinoike_kekkai", 0.2, {"knock": 0.0}))
			heal(c, 3.0))
	Sfx.play("genjutsu", tt.global_position, 0.6)


## Kan Yağmuru: gökten 3 sn boyunca kızıl iğneler yağar; değdiği herkes kanar
func c_chinoike_chi_no_ame(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 10.0, 22.0))
	FX.burst(center + Vector3.UP * 12.0, {"amount": 60, "life": 3.0, "tex": FX.tex_smoke, "add": false, "size": 4.0, "vmin": 0.1, "vmax": 0.6, "gravity": Vector3.ZERO,
		"colors": [Color(0.4, 0.0, 0.03, 0.0), Color(0.35, 0.0, 0.03, 0.8), Color(0.3, 0.0, 0.02, 0)]})
	every(3.0, 0.08, func(_i, _k):
		var p = center + Vector3(randf_range(-8, 8), 12.0, randf_range(-8, 8))
		var nd = JutsuEngine.shape_mesh("needles", Color(0.7, 0.05, 0.08), 0.5, "")
		shot(c, p, Vector3(randf_range(-0.1, 0.1), -1, randf_range(-0.1, 0.1)), 30.0, nd, inf(c, "chinoike_chi_no_ame", 0.07, {"knock": 0.0, "kind": "light", "burn": 2.0}), null, false, 0.8))
	Sfx.play("water", center, 0.5)


# ================================================================== HOSHİGAKİ — köpekbalıkları
## Beş Köpekbalığı: her köpekbalığı ayrı bir düşmanı kovalar
func c_hoshigaki_same(c: Node3D, t: Node3D) -> void:
	var list = enemies_near(c, c.global_position, 30.0)
	var tt = tg(c, t, 30.0)
	if tt and not tt in list:
		list.push_front(tt)
	for k in 7:
		var target = list[k % list.size()] if not list.is_empty() else null
		var d = (Jutsu._aim(c, t)).rotated(Vector3.UP, (k - 3) * 0.28)
		var shark = JutsuEngine.shape_mesh("shark", Color(0.35, 0.65, 1.0), 1.2, "suiton")
		var pr = shot(c, c.global_position + Vector3.UP * 1.2 + d, d, 22.0, shark, inf(c, "hoshigaki_same", 0.5, {"knock": 8.0, "kind": "heavy"}), target, false, 3.0)
		Projectile.trail(pr, [Color(0.8, 0.95, 1), Color(0.3, 0.6, 1.0), Color(0.2, 0.4, 0.9, 0)], 0.8, 30, 0.4)
	Sfx.play("water", c.global_position, 0.8)


## Büyük Köpekbalığı Mermisi: dev köpekbalığı yolundaki düşman jutsularını yutar ve her yuttuğunda büyür
func c_suiton_daikodan_no_jutsu(c: Node3D, t: Node3D) -> void:
	var d = Jutsu._aim(c, t)
	var shark = JutsuEngine.shape_mesh("shark", Color(0.3, 0.55, 1.0), 2.6, "suiton")
	var pr = shot(c, c.global_position + Vector3.UP * 1.6 + d * 2.0, d, 20.0, shark, inf(c, "suiton_daikodan_no_jutsu", 1.8, {"knock": 18.0, "launch": 4.0, "kind": "heavy"}), tg(c, t, 40.0), false, 3.0, func(pos, _tg):
		VFX.splash(pos, 4.0)
		VFX.shockwave(pos, Color(0.5, 0.8, 1.0), 10.0, 0.4, false))
	pr.radius = 1.8
	pr.on_tick = func(p, _dt):
		for n in get_tree().current_scene.get_children():
			if n is Projectile and n != p and not n.dead and Combat.hostile(c, n.shooter) and n.global_position.distance_to(p.global_position) < 3.5:
				n.queue_free()
				shark.scale *= 1.15
				p.info["dmg"] = float(p.info["dmg"]) * 1.2
				VFX.splash(p.global_position, 1.5)
				chakra_gain(c, 6.0)
	Sfx.play("water", c.global_position, 0.6)


## Bin Köpekbalığı: ağzından boşalan dev su seli (30 m genişliğinde) öne akar; içinde onlarca köpekbalığı yüzer, değdiğini ısırır
func c_suiton_senshokuko(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var side = d.cross(Vector3.UP)
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(30.0, 6.0, 9.0), Color.WHITE, Vector3.ZERO, 20)
	var flood = place(b, gp(c.global_position + d * 4.0), VFX.mat_water(Color(0.04, 0.25, 0.7), Color(0.15, 0.5, 0.95), Color(0.6, 0.86, 1.0), Vector3(0, 0, 1), 0.82))
	flood.look_at(flood.global_position + d, Vector3.UP)
	flood.scale = Vector3(0.2, 0.2, 0.2)
	var tw = flood.create_tween()
	tw.tween_property(flood, "scale", Vector3.ONE, 0.4).set_ease(Tween.EASE_OUT)
	var sharks = []
	for k in 22:
		var s = JutsuEngine.shape_mesh("shark", Color(0.3, 0.6, 1.0), 1.0, "suiton")
		get_tree().current_scene.add_child(s)
		sharks.append([s, randf_range(-13, 13), randf_range(0.5, 4.5), randf_range(-3.5, 3.5), randf() * TAU])
	busy(c, 0.8)
	VFX.slowmo(0.55, 0.35)
	var bitten = {}
	every(2.4, 1.0 / 30.0, func(i, k):
		var center = gp(c.global_position + d * (4.0 + k * 30.0))
		flood.global_position = center + Vector3.UP * 1.0
		for sh in sharks:
			var ph = i * 0.18 + sh[4]
			var p = center + side * (sh[1] + sin(ph) * 1.5) + Vector3.UP * (sh[2] + sin(ph * 1.7) * 0.6) + d * (sh[3] + cos(ph) * 1.2)
			sh[0].look_at(p + d + side * cos(ph) * 0.5, Vector3.UP)
			sh[0].global_position = p
		if i % 3 == 0:
			VFX.splash(center + side * randf_range(-13, 13) + Vector3.UP * 4.0, 2.0)
		for e in enemies_near(c, center, 15.0):
			var v = e.global_position - center
			if absf(v.dot(d)) < 5.0:
				e.global_position = gp(e.global_position + d * 0.5)   # sel sürükler
				st(e, "slow", 0.4)
				var key = e.get_instance_id()
				if Time.get_ticks_msec() - int(bitten.get(key, 0)) > 400:
					bitten[key] = Time.get_ticks_msec()
					hit(c, e.global_position + Vector3.UP, 1.0, inf(c, "suiton_senshokuko", 0.18, {"knock": 3.0, "kind": "light", "element": "suiton"})), func():
		for sh in sharks:
			sh[0].queue_free()
		fade_free(flood, 0.0, 0.5))
	shake(0.8)
	Sfx.play("water", c.global_position, 0.4)


## Su Hapsi Köpekbalığı Dansı: 50 m çapında dev su kubbesi yükselir; içinde normal boy köpekbalıkları dolaşır.
## İçeridekiler boğulur (sürekli hasar), çok yavaşlar, köpekbalıkları sırayla saldırır; sen suyun içinde hızlanırsın.
func c_suiro_sameodori_no_jutsu(c: Node3D, t: Node3D) -> void:
	var center = gp(c.global_position)
	var R = 25.0
	var dome = MeshInstance3D.new()
	dome.mesh = VFX._sphere(0.5, 40, 20)
	dome.material_override = VFX.mat_water(Color(0.03, 0.22, 0.62), Color(0.12, 0.45, 0.9), Color(0.55, 0.85, 1.0), Vector3(1, 0, 0), 0.55)
	get_tree().current_scene.add_child(dome)
	dome.global_position = center
	dome.scale = Vector3.ONE * 0.5
	var tw = dome.create_tween()
	tw.tween_property(dome, "scale", Vector3(R * 2.0, R * 1.5, R * 2.0), 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	VFX.slowmo(0.4, 0.6)
	VFX.cinematic(c, 14.0, 7.0)
	busy(c, 0.9)
	FX.burst(center + Vector3.UP * 4.0, {"amount": 160, "life": 8.0, "size": 0.35, "vmin": 0.3, "vmax": 1.2, "gravity": Vector3(0, 1.2, 0),
		"colors": [Color(0.85, 0.95, 1.0, 0.0), Color(0.85, 0.95, 1.0, 0.8), Color(0.85, 0.95, 1.0, 0)]})   # kabarcıklar
	var sharks = []
	for k in 16:
		var s = JutsuEngine.shape_mesh("shark", Color(0.3, 0.6, 1.0), 1.2, "suiton")
		get_tree().current_scene.add_child(s)
		sharks.append({"n": s, "r": randf_range(6.0, R - 3.0), "h": randf_range(2.0, R * 0.9), "ph": randf() * TAU, "sp": randf_range(0.6, 1.1) * (1.0 if k % 2 == 0 else -1.0), "atk": -1.0, "tg": null})
	if c is Player:
		Buffs.add("sameodori", 8.0, {"speed": 1.4})
	var bite_cd = {"t": 0.0}
	every(8.0, 1.0 / 30.0, func(i, _k):
		bite_cd["t"] -= 1.0 / 30.0
		var inside = enemies_near(c, center, R)
		for s in sharks:
			var n: Node3D = s["n"]
			if s["atk"] >= 0.0 and live(s["tg"]):
				# saldırı: hedefe dalar, ısırır, geri çekilir
				s["atk"] += 1.0 / 30.0
				var goal = s["tg"].global_position + Vector3.UP
				var p = n.global_position.lerp(goal, 0.22)
				n.look_at(goal, Vector3.UP)
				n.global_position = p
				if p.distance_to(goal) < 1.2 or s["atk"] > 0.8:
					hit(c, goal, 1.2, inf(c, "suiro_sameodori_no_jutsu", 0.3, {"knock": 4.0, "kind": "heavy", "element": "suiton"}))
					VFX.splash(goal, 1.2)
					s["atk"] = -1.0
					s["tg"] = null
				continue
			s["ph"] += 0.025 * s["sp"]
			var p2 = center + Vector3(cos(s["ph"]) * s["r"], s["h"] + sin(s["ph"] * 2.0) * 1.5, sin(s["ph"]) * s["r"])
			n.look_at(p2 + Vector3(-sin(s["ph"]), 0, cos(s["ph"])) * s["sp"], Vector3.UP)
			n.global_position = p2
		if bite_cd["t"] <= 0.0 and not inside.is_empty():
			bite_cd["t"] = 0.35
			var free = sharks.filter(func(x): return x["atk"] < 0.0)
			if not free.is_empty():
				var s = free[randi() % free.size()]
				s["atk"] = 0.0
				s["tg"] = inside[randi() % inside.size()]
		if i % 15 == 0:
			for e in inside:
				st(e, "slow", 0.6)
				hit(c, e.global_position + Vector3.UP, 0.8, inf(c, "suiro_sameodori_no_jutsu", 0.08, {"knock": 0.0, "kind": "light", "element": "suiton"}))   # boğulma
				if e.has_method("lose_target") and i % 45 == 0:
					e.lose_target(0.5), func():
		for s in sharks:
			s["n"].queue_free()
		var tw2 = dome.create_tween()
		tw2.tween_property(dome, "scale", Vector3(R * 2.4, 0.5, R * 2.4), 0.5)
		tw2.tween_callback(dome.queue_free)
		VFX.splash(center + Vector3.UP, 8.0))
	shake(1.2)
	Sfx.play("water", center, 0.35)


# ================================================================== KURAMA — gerçeğe dönüşen genjutsu
## Gerçeklik Genjutsusu: hedef bir resmin içine çekilir; çizilen alevler gerçekten yakar
func c_kurama_genjutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	if tt == null:
		return
	st(tt, "stun", 3.0)
	var frame = MB.new()
	frame.add("box", Vector3(0, 0, 0), Vector3(3.2, 3.2, 0.08), Color(0.95, 0.9, 0.8))
	frame.add("box", Vector3(0, 1.6, 0), Vector3(3.4, 0.15, 0.15), Color(0.45, 0.3, 0.2))
	frame.add("box", Vector3(0, -1.6, 0), Vector3(3.4, 0.15, 0.15), Color(0.45, 0.3, 0.2))
	var canvas = mesh_of(frame)
	attach(tt, canvas, 3.0, Vector3(0, 1.4, 0.6))
	every(3.0, 0.3, func(i, _k):
		if not live(tt):
			return
		var stroke = MB.new()
		stroke.add("cone", Vector3.ZERO, Vector3(0.3, 1.2, 0.05), Color(1.0, 0.45 + randf() * 0.3, 0.1), Vector3(0, 0, randf_range(-30, 30)), 4)
		var st_m = mesh_of(stroke, glow(Color(1.0, 0.5, 0.15)))
		attach(tt, st_m, 3.0 - i * 0.3, Vector3(randf_range(-1.2, 1.2), randf_range(0.5, 2.4), 0.55))
		hit(c, tt.global_position + Vector3.UP, 0.8, inf(c, "kurama_genjutsu", 0.18, {"knock": 0.0, "burn": 1.0})))
	Sfx.play("genjutsu", tt.global_position, 1.1)


## Karanlık Perde: 20 m içindeki düşmanların dünyası kararır: 6 sn seni bulamazlar
func c_kurama_kokuangyo(c: Node3D, _t: Node3D) -> void:
	for e in enemies_near(c, c.global_position, 20.0):
		if e.has_method("lose_target"):
			e.lose_target(6.0)
		var dark = MeshInstance3D.new()
		dark.mesh = VFX._sphere(0.5, 14, 8)
		dark.material_override = flat_mat(Color(0.0, 0.0, 0.02, 0.85))
		dark.scale = Vector3.ONE * 1.4
		attach(e, dark, 6.0, Vector3.UP * (e.height - 0.3))
	VFX.shockwave(c.global_position + Vector3.UP, Color(0.1, 0.05, 0.15), 30.0, 0.6, true)
	Sfx.play("genjutsu", c.global_position, 0.5)


## Sahte Çevre: düşmanlar senin bir yanılsamana saldırır; sen 5 sn görünmez olursun
func c_magen_kokoni_arazu_no_jutsu(c: Node3D, _t: Node3D) -> void:
	decoy(c, c.global_position + c.face_dir() * 2.0, 8.0)
	if c.get("model"):
		c.model.visible = false
		after(5.0, func():
			if is_instance_valid(c):
				c.model.visible = true)
	Sfx.play("genjutsu", c.global_position, 1.3)


## Ağaçla Bağlayan Ölüm: hedefin altından ağaç büyüyüp onu sarar; sen gövdeden çıkıp saplarsın
func c_magen_jubaku_satsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	if tt == null:
		return
	var b = MB.new()
	b.add_grad("cyl", Vector3(0, 2.0, 0.6), Vector3(1.0, 4.0, 1.0), Color(0.5, 0.35, 0.22), Color(0.3, 0.2, 0.12), Vector3.ZERO, 9)
	for k in 5:
		var a = k * 1.25
		b.add("cyl", Vector3(cos(a) * 0.5, 0.6 + k * 0.4, sin(a) * 0.5), Vector3(0.18, 1.6, 0.18), Color(0.42, 0.3, 0.18), Vector3(sin(a) * 50, 0, cos(a) * 50), 6)
	b.add_grad("sphere", Vector3(0, 4.4, 0.6), Vector3(3.0, 2.0, 3.0), Color(0.35, 0.65, 0.3), Color(0.15, 0.35, 0.15), Vector3.ZERO, 10)
	var tree = mesh_of(b)
	attach(tt, tree, 4.0, Vector3.ZERO)
	tree.scale = Vector3(0.6, 0.05, 0.6)
	var tw = tree.create_tween()
	tw.tween_property(tree, "scale", Vector3.ONE, 0.6).set_ease(Tween.EASE_OUT)
	st(tt, "bind", 4.0)
	after(1.6, func():
		if not live(tt) or not is_instance_valid(c):
			return
		c.global_position = gp(tt.global_position + tt.face_dir() * 1.2) if tt.has_method("face_dir") else c.global_position
		anim(c, "cross", 1.6)
		hit(c, tt.global_position + Vector3.UP * 1.2, 1.3, inf(c, "magen_jubaku_satsu", 2.2, {"knock": 4.0, "kind": "heavy", "hitstop": 0.12}))
		VFX.star(tt.global_position + Vector3.UP * 1.2, Color(1, 0.9, 0.9), 2.0, 0.2))
	Sfx.play("genjutsu", tt.global_position, 0.9)


## Çifte Sahte Çevre: iki yanılsama kopyası; 4 sn sonra ikisi de genjutsu şokuyla patlayıp çevreyi sersemletir
func c_magen_niju_kokoni_arazu_no_jutsu(c: Node3D, _t: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var p = c.global_position + c.global_transform.basis.x * side * 3.0
		decoy(c, p, 4.0, func(q: Vector3):
			FX.ring(q + Vector3.UP, Color(0.75, 0.5, 1.0), 6.0, 0.4, false)
			for e in enemies_near(c, q, 5.0):
				st(e, "stun", 2.0))
	for e in enemies_near(c, c.global_position, 20.0):
		if e.has_method("lose_target"):
			e.lose_target(1.0)
	Sfx.play("genjutsu", c.global_position, 1.0)


# ================================================================== FŪMA — dev shuriken sanatı
func _fuma_mesh(size: float) -> Node3D:
	var b = MB.new()
	b.add("cyl", Vector3.ZERO, Vector3(0.5, 0.12, 0.5), Color(0.25, 0.22, 0.2), Vector3.ZERO, 10)
	for k in 4:
		var a = k * 90.0
		b.add("cone", Vector3(sin(deg_to_rad(a)) * 0.75, 0, cos(deg_to_rad(a)) * 0.75), Vector3(0.45, 1.3, 0.06), Color(0.72, 0.74, 0.78), Vector3(90, a, 0), 4)
	var mi = mesh_of(b)
	mi.scale = Vector3.ONE * size
	return mi


## Fūma Shuriken: dev shuriken düşmanları delip geçer, 20 m sonra geri dönüp yine keser
func c_fuma_shuriken_j(c: Node3D, t: Node3D) -> void:
	var d = Jutsu._aim(c, t)
	var sh = _fuma_mesh(1.8)
	var pr = shot(c, Jutsu._hand(c), d, 30.0, sh, inf(c, "fuma_shuriken_j", 0.8, {"knock": 6.0, "kind": "heavy"}), null, true, 1.6)
	pr.spin = Vector3(0, 28, 0)
	var turned = {"v": false}
	pr.on_tick = func(p, _dt):
		if not turned["v"] and p.global_position.distance_to(c.global_position) > 20.0:
			turned["v"] = true
			p.hit_list.clear()
			p.homing = c
			p.homing_turn = 6.0
			p.shooter = c
		if turned["v"] and p.global_position.distance_to(c.global_position + Vector3.UP) < 1.5:
			p.queue_free()
	Sfx.play("wind", c.global_position, 1.2)


## Kamaitachi: üç dev dönen rüzgar hilali yelpaze halinde keser, kanatır
func c_fuma_kaze(c: Node3D, t: Node3D) -> void:
	for k in 3:
		var d = Jutsu._aim(c, t).rotated(Vector3.UP, (k - 1) * 0.3)
		var b = MB.new()
		b.add("torus", Vector3.ZERO, Vector3(2.4, 2.4, 2.4), Color.WHITE, Vector3(90, 0, 0), 20)
		var crescent = mesh_of(b, VFX.mat_wind(Color(0.75, 1.0, 0.9), 10.0, 5.0, Vector3.UP, 0.85))
		crescent.scale = Vector3(1, 0.25, 0.5)
		var pr = shot(c, c.global_position + Vector3.UP * 1.2 + d, d, 30.0, crescent, inf(c, "fuma_kaze", 0.55, {"knock": 8.0, "kind": "heavy", "burn": 2.0, "element": "fuuton"}), null, true, 0.9)
		pr.spin = Vector3(0, 0, 18)
	Sfx.play("wind", c.global_position, 0.9)


## Üçlü Yel Değirmeni: tellere bağlı üç shuriken hedefin etrafında dönüp onu sarar, sonra tel sıkılır
func c_sofushasan_no_tachi(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 22.0)
	if tt == null:
		return
	var sh = []
	var wire = flat_mat(Color(0.85, 0.88, 0.95))
	for k in 3:
		var s = _fuma_mesh(0.6)
		get_tree().current_scene.add_child(s)
		sh.append(s)
		var idx = k
		tether(func(): return Jutsu._hand(c), func(): return sh[idx].global_position if is_instance_valid(sh[idx]) else Jutsu._hand(c), 0.03, wire, 2.0)
	st(tt, "bind", 2.6)
	every(2.0, 1.0 / 30.0, func(i, k):
		for n in sh.size():
			var a = i * 0.35 + n * TAU / 3.0
			var r = lerpf(6.0, 0.9, minf(1.0, k * 1.6))
			sh[n].global_position = tt.global_position + Vector3(cos(a) * r, 1.0 + n * 0.3, sin(a) * r) if live(tt) else sh[n].global_position
			sh[n].rotation.y += 0.6, func():
		for s in sh:
			s.queue_free()
		if live(tt):
			hit(c, tt.global_position + Vector3.UP, 1.3, inf(c, "sofushasan_no_tachi", 1.6, {"knock": 2.0, "kind": "heavy", "burn": 2.0}))
			Combat.popup_text(tt.global_position + Vector3.UP * 2.4, "Teller sıkıldı!", Color(0.9, 0.9, 1)))
	Sfx.play("kunai", c.global_position, 0.8)


## Shuriken Gölge Klonu: tek shuriken havada yirmi dörde bölünür, hedefe yağar
func c_shuriken_kage_bunshin_no_jutsu(c: Node3D, t: Node3D) -> void:
	var d = Jutsu._aim(c, t)
	var tt = tg(c, t, 35.0)
	var pr = shot(c, Jutsu._hand(c), d, 26.0, _fuma_mesh(0.35), {"dmg": 1.0, "knock": 0.0}, null, false, 0.3)
	pr.spin = Vector3(0, 30, 0)
	after(0.22, func():
		var p = pr.global_position if is_instance_valid(pr) else Jutsu._hand(c) + d * 5.0
		FX.smoke_puff(p, 0.6, 8)
		for k in 24:
			var dd = d.rotated(Vector3.UP, randf_range(-0.5, 0.5)).rotated(d.cross(Vector3.UP).normalized(), randf_range(-0.25, 0.25))
			var s = shot(c, p, dd, 34.0, _fuma_mesh(0.3), inf(c, "shuriken_kage_bunshin_no_jutsu", 0.09, {"knock": 1.0, "kind": "light"}), tt if k % 3 == 0 else null, false, 1.4)
			s.spin = Vector3(0, 30, 0))
	Sfx.play("kunai", c.global_position)


## Rüzgar Çarkı: rüzgara sarılı dev shuriken etrafında 8 m yarıçapla üç sn döner, her şeyi biçer
func c_fuma_kaze_guruma(c: Node3D, _t: Node3D) -> void:
	var sh = _fuma_mesh(2.2)
	get_tree().current_scene.add_child(sh)
	var w = VFX.wind_ball(1.6)
	sh.add_child(w)
	var hit_t = {}
	every(3.0, 1.0 / 30.0, func(i, _k):
		if not is_instance_valid(c):
			return
		var a = i * 0.16
		sh.global_position = c.global_position + Vector3(cos(a) * 8.0, 1.4, sin(a) * 8.0)
		sh.rotation.y += 0.7
		for e in enemies_near(c, sh.global_position, 2.2):
			var key = e.get_instance_id()
			if Time.get_ticks_msec() - int(hit_t.get(key, 0)) > 600:
				hit_t[key] = Time.get_ticks_msec()
				hit(c, e.global_position + Vector3.UP, 1.0, inf(c, "fuma_kaze_guruma", 0.6, {"knock": 9.0, "kind": "heavy", "element": "fuuton"}))
		if i % 4 == 0:
			FX.dust(gp(sh.global_position), 0.6), func():
		sh.queue_free())
	Sfx.play("wind", c.global_position, 0.8)


# ================================================================== KAMİZURU — arılar ve bal mumu
## Arı Sürüsü: sarı sürü 5 sn hedefin peşinde; sokar, zehirler, yavaşlatır
func c_kamizuru_bees(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 30.0)
	var pos = {"p": c.global_position + Vector3.UP * 1.5}
	var swarm = FX.burst(pos["p"], {"amount": 90, "life": 5.0, "size": 0.12, "vmin": 0.5, "vmax": 2.0, "gravity": Vector3.ZERO,
		"colors": [Color(1.0, 0.85, 0.2), Color(0.15, 0.1, 0.05), Color(1.0, 0.8, 0.2, 0)]})
	every(5.0, 0.1, func(i, _k):
		var goal = tt.global_position + Vector3.UP * 1.2 if live(tt) else pos["p"]
		pos["p"] = pos["p"].lerp(goal, 0.12)
		if swarm and is_instance_valid(swarm):
			swarm.global_position = pos["p"]
		if i % 5 == 0:
			for e in enemies_near(c, pos["p"], 2.2):
				hit(c, e.global_position + Vector3.UP, 0.8, inf(c, "kamizuru_bees", 0.14, {"knock": 0.0, "burn": 2.0}))
				st(e, "slow", 1.0))
	Sfx.play("wind", c.global_position, 2.6, 0.5)


func _honey_mesh(size: float) -> Node3D:
	var mi = MeshInstance3D.new()
	mi.mesh = VFX._sphere(0.5, 14, 8)
	mi.material_override = VFX.mat_spiral(Color(1.0, 0.85, 0.35), Color(0.85, 0.5, 0.05), 3.0, 1.0, 1.0, 1.4)
	mi.scale = Vector3.ONE * size
	return mi


## Bal Mumu: üç yapışkan bal topu; değdiği hedefi yere yapıştırır, yerde 5 sn yapışkan mum gölü kalır
func c_kamizuru_wax(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 25.0)
	for k in 3:
		var d = Jutsu._aim(c, t).rotated(Vector3.UP, (k - 1) * 0.12)
		var pr = shot(c, Jutsu._mouth(c), d, 22.0, _honey_mesh(0.7), inf(c, "kamizuru_wax", 0.3, {"knock": 0.0}), tt, false, 1.6, func(pos, target):
			if live(target):
				st(target, "bind", 3.0)
			var pool = ground_disc(pos, 2.4, Color(0.95, 0.7, 0.15), 5.0, 2, 0)
			every(5.0, 0.3, func(_i, _k):
				for e in enemies_near(c, pos, 2.4):
					st(e, "slow", 0.5)))
		pr.gravity = 6.0
	Sfx.play("water", c.global_position, 0.7)


func c_kamizuru_hachi(c: Node3D, _t: Node3D) -> void:
	FX.smoke_puff(c.global_position + Vector3.UP * 2, 1.4, 16)
	ClanConstruct.spawn(c, "bee", 3, Jutsu._jd("kamizuru_hachi"))
	Sfx.play("wind", c.global_position, 2.0, 0.6)


## Arı İğnesi Yağmuru: sürüden on iki zehirli iğne kıvrılarak hedeflere uçar
func c_kamizuru_hari(c: Node3D, t: Node3D) -> void:
	var list = enemies_near(c, c.global_position, 28.0)
	var origin = c.global_position + Vector3.UP * 2.2
	FX.burst(origin, {"amount": 40, "life": 0.6, "size": 0.12, "vmin": 1, "vmax": 3, "colors": [Color(1, 0.85, 0.2), Color(0.15, 0.1, 0.05, 0)]})
	for k in 12:
		var target = list[k % list.size()] if not list.is_empty() else null
		var d = (Jutsu._aim(c, t) + Vector3(randf_range(-0.6, 0.6), randf_range(0.1, 0.6), randf_range(-0.6, 0.6))).normalized()
		var nd = JutsuEngine.shape_mesh("needles", Color(0.95, 0.8, 0.2), 0.35, "")
		after(k * 0.04, func():
			shot(c, origin, d, 30.0, nd, inf(c, "kamizuru_hari", 0.12, {"knock": 0.5, "kind": "light", "burn": 2.5}), target, false, 1.6, func(_p, tgt):
				st(tgt, "slow", 2.0)))
	Sfx.play("kunai", c.global_position, 1.6)


## Bal Klonu: düşmanları üstüne çeker; vurulunca patlar, çevredeki herkes yapışkan muma saplanır
func c_kamizuru_mitsu_bunshin(c: Node3D, _t: Node3D) -> void:
	decoy(c, c.global_position + c.global_transform.basis.x * 2.5, 12.0, func(p: Vector3):
		FX.burst(p + Vector3.UP, {"amount": 40, "life": 0.7, "size": 0.5, "vmin": 2, "vmax": 7, "add": false, "colors": [Color(1, 0.8, 0.25), Color(0.9, 0.55, 0.05, 0)]})
		ground_disc(p, 5.0, Color(0.95, 0.7, 0.15), 3.0, 2, 0)
		for e in enemies_near(c, p, 5.0):
			st(e, "bind", 3.0))
	FX.smoke_puff(c.global_position + Vector3.UP, 0.8, 10)


# ================================================================== SABAKU — kum ve demir
## Kum Zırhı: tenin ince kum tabakasıyla kaplanır: 20 sn gelen hasar yarıya iner
func c_suna_no_yoroi(c: Node3D, _t: Node3D) -> void:
	var shell = MeshInstance3D.new()
	shell.mesh = VFX._sphere(0.5, 16, 10)
	shell.material_override = VFX.mat_spiral(Color(0.95, 0.85, 0.6, 0.35), Color(0.8, 0.65, 0.4, 0.25), 9.0, 2.0, 0.6, 0.4)
	shell.scale = Vector3(1.0, 2.0, 1.0)
	attach(c, shell, 20.0, Vector3.UP * 0.95)
	if c is Player:
		Buffs.add("suna_no_yoroi", 20.0, {"armor": 0.5})
	VFX.puffs(c.global_position, {"amount": 30, "life": 0.7, "size": 0.8, "radius": 1.2, "vmin": 2, "vmax": 5, "dir": Vector3.UP, "spread": 30.0,
		"colors": [Color(0.92, 0.8, 0.58), Color(0.82, 0.68, 0.45, 0)]})
	Sfx.play("earth", c.global_position, 1.4)


## Hava-Kum Kalkanı: etrafında kum kubbesi döner; 8 sn mermileri kendiliğinden durdurur, yaklaşanı iter
func c_kusa_boheki(c: Node3D, _t: Node3D) -> void:
	var dome = MeshInstance3D.new()
	dome.mesh = VFX._sphere(0.5, 24, 12)
	dome.material_override = VFX.mat_spiral(Color(0.95, 0.85, 0.6, 0.8), Color(0.75, 0.6, 0.38, 0.7), 7.0, 2.0, 2.0, 0.6)
	dome.scale = Vector3.ONE * 6.4
	attach(c, dome, 8.0, Vector3.UP * 0.8)
	every(8.0, 0.1, func(_i, _k):
		dome.rotation.y -= 0.25
		for n in get_tree().current_scene.get_children():
			if n is Projectile and not n.dead and Combat.hostile(c, n.shooter) and n.global_position.distance_to(c.global_position + Vector3.UP) < 3.6:
				VFX.puffs(n.global_position, {"amount": 10, "life": 0.4, "size": 0.6, "radius": 0.4, "vmin": 1, "vmax": 3, "colors": [Color(0.9, 0.78, 0.55), Color(0.8, 0.65, 0.4, 0)]})
				n.queue_free()
		for e in enemies_near(c, c.global_position, 3.6):
			var v = e.global_position - c.global_position
			v.y = 0
			e.global_position = gp(e.global_position + v.normalized() * 0.5))
	Sfx.play("earth", c.global_position, 0.9)


## Kum Hapis Gömüsü: hedefin altında bataklık kum açılır; içine çekilir, sonra kum kapanıp ezer
func c_gokusa_maiso(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 24.0)
	if tt == null:
		return
	var p = gp(tt.global_position)
	ground_disc(p, 3.4, Color(0.8, 0.65, 0.42), 3.0, 4, 12)
	st(tt, "bind", 3.4)
	if tt.get("model"):
		var tw = tt.model.create_tween()
		tw.tween_property(tt.model, "position:y", -1.2, 2.4)
		tw.tween_property(tt.model, "position:y", 0.0, 0.3).set_delay(0.6)
	every(2.6, 0.2, func(_i, _k):
		VFX.puffs(p, {"amount": 8, "life": 0.6, "size": 0.9, "radius": 2.6, "vmin": 1, "vmax": 3, "dir": Vector3.UP, "spread": 25.0, "tangent": 6.0,
			"colors": [Color(0.9, 0.78, 0.55), Color(0.8, 0.65, 0.4, 0)]}), func():
		VFX.puffs(p + Vector3.UP, {"amount": 50, "life": 0.9, "size": 1.8, "radius": 1.5, "vmin": 6, "vmax": 14, "colors": [Color(0.92, 0.8, 0.58), Color(0.8, 0.65, 0.4, 0)]})
		if live(tt):
			hit(c, tt.global_position + Vector3.UP, 1.6, inf(c, "gokusa_maiso", 2.0, {"knock": 2.0, "kind": "heavy", "hitstop": 0.12}))
		shake(0.7))
	Sfx.play("earth", p, 0.7)


## Kum Klonu: kumdan kopya; vurulunca dağılıp vuranın üstüne kapanır ve onu bağlar
func c_suna_bunshin(c: Node3D, _t: Node3D) -> void:
	decoy(c, c.global_position + c.global_transform.basis.x * 2.5, 12.0, func(p: Vector3):
		VFX.puffs(p + Vector3.UP, {"amount": 40, "life": 0.8, "size": 1.2, "radius": 1.0, "vmin": 3, "vmax": 8, "colors": [Color(0.92, 0.8, 0.58), Color(0.8, 0.65, 0.4, 0)]})
		for e in enemies_near(c, p, 4.5):
			st(e, "bind", 2.5)
			var shell = MeshInstance3D.new()
			shell.mesh = VFX._sphere(0.5, 14, 8)
			shell.material_override = Props.toon_color(Color(0.82, 0.68, 0.45))
			shell.scale = Vector3(e.radius * 3.0, e.height * 0.9, e.radius * 3.0)
			attach(e, shell, 2.5, Vector3.UP * e.height * 0.4))
	VFX.puffs(c.global_position, {"amount": 20, "life": 0.6, "size": 0.8, "radius": 0.8, "vmin": 2, "vmax": 4, "colors": [Color(0.92, 0.8, 0.58), Color(0.8, 0.65, 0.4, 0)]})


## Kum Shurikeni: kumdan sekiz shuriken yelpaze halinde; değdiğini kumla ağırlaştırır
func c_suna_shuriken(c: Node3D, t: Node3D) -> void:
	for k in 8:
		var d = Jutsu._aim(c, t).rotated(Vector3.UP, (k - 3.5) * 0.09)
		var disc = JutsuEngine.shape_mesh("disc", Color(0.85, 0.7, 0.45), 0.5, "")
		var pr = shot(c, Jutsu._hand(c), d, 34.0, disc, inf(c, "suna_shuriken", 0.15, {"knock": 2.0, "kind": "light"}), null, false, 1.4, func(_p, tgt):
			st(tgt, "slow", 2.5))
		pr.spin = Vector3(0, 25, 0)
	Sfx.play("earth", c.global_position, 1.8, 0.6)


## Kum Şelalesi Cenazesi: yerden dev kum dalgası yükselir, ileri yuvarlanıp her şeyi gömer
func c_sabaku_soso(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var b = MB.new()
	b.add_grad("sphere", Vector3(0, 0, 0), Vector3(32.0, 14.0, 9.0), Color(0.95, 0.83, 0.6), Color(0.7, 0.55, 0.33), Vector3.ZERO, 18)
	var wave = place(b, gp(c.global_position + d * 3.0) - Vector3.UP * 3.0)
	wave.look_at(wave.global_position + d, Vector3.UP)
	busy(c, 0.8)
	var hits = []
	every(1.4, 1.0 / 30.0, func(i, k):
		wave.global_position = gp(c.global_position + d * (6.0 + k * 30.0)) + Vector3.UP * (sin(k * PI) * 3.0 - 2.0)
		if i % 2 == 0:
			VFX.puffs(wave.global_position + Vector3.UP * 3.0, {"amount": 12, "life": 0.7, "size": 1.6, "radius": 6.0, "vmin": 2, "vmax": 6, "dir": Vector3.UP, "spread": 40.0,
				"colors": [Color(0.92, 0.8, 0.58), Color(0.8, 0.65, 0.4, 0)]})
		for h in hit(c, wave.global_position + Vector3.UP * 1.5, 12.0, inf(c, "sabaku_soso", 2.2, {"knock": 14.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.06}), hits):
			hits.append(h)
			st(h, "bind", 2.0), func():
		fade_free(wave, 0.0, 0.5))
	shake(1.0)
	Sfx.play("earth", c.global_position, 0.5)


## Uçan Kum Bulutu: ayağının altındaki kum bulutuna binip uçarsın
func c_sabaku_suna_no_kumo(c: Node3D, _t: Node3D) -> void:
	if not c is Player:
		return
	if c.flight_source() == "sand":
		c.stop_flight()
		return
	var b = MB.new()
	for k in 9:
		var a = k * TAU / 9.0
		b.add_grad("sphere", Vector3(cos(a) * 0.9, 0, sin(a) * 0.9), Vector3(1.3, 0.55, 1.3), Color(0.95, 0.85, 0.62), Color(0.75, 0.6, 0.38), Vector3.ZERO, 9)
	b.add_grad("sphere", Vector3.ZERO, Vector3(2.4, 0.7, 2.4), Color(0.95, 0.86, 0.64), Color(0.72, 0.58, 0.36), Vector3.ZERO, 12)
	var cloud = mesh_of(b)
	cloud.position = Vector3(0, -0.15, 0)
	var vis = Node3D.new()
	vis.add_child(cloud)
	add_child(vis)
	Projectile.trail(vis, [Color(0.92, 0.8, 0.58), Color(0.85, 0.7, 0.45), Color(0.8, 0.65, 0.4, 0)], 0.7, 40, 0.8, null, false)
	c.start_flight("sand", {"speed": 15.0, "lift": 8.0, "drain": 2.0, "vis": vis, "name": "Kum bulutu"})


# ================================================================== SHİROGANE — savaş kuklaları
func c_kugutsu_no_jutsu(c: Node3D, _t: Node3D) -> void:
	ClanConstruct.spawn(c, "puppet", 1, Jutsu._jd("kugutsu_no_jutsu"))
	Sfx.play("clink", c.global_position, 0.9)


func c_shirohigi_jikki_chikamatsu_no_shu(c: Node3D, _t: Node3D) -> void:
	FX.smoke_puff(c.global_position + Vector3.UP * 2.0, 2.4, 30)
	ClanConstruct.spawn(c, "puppet", 4, Jutsu._jd("shirohigi_jikki_chikamatsu_no_shu"))
	Sfx.play("clink", c.global_position, 0.7)


func c_akahigi_hyakki_no_soen(c: Node3D, _t: Node3D) -> void:
	FX.smoke_puff(c.global_position + Vector3.UP * 3.0, 3.2, 40)
	var list = ClanConstruct.spawn(c, "puppet", 6, Jutsu._jd("akahigi_hyakki_no_soen"))
	for u in list:
		u.global_position += Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	Hud.msg("Yüz Kukla Gösterisi!", Color(0.9, 0.45, 0.45))
	Sfx.play("clink", c.global_position, 0.5)


## Kara Makine Tek Atış: kara tabut-kukla hedefi içine kapatır, dört yandan bıçaklar saplanır
func c_kurohigi_kiki_ippatsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	if tt == null:
		return
	var box = MB.new()
	box.add("box", Vector3(0, 1.3, 0), Vector3(1.8, 2.6, 1.8), Color(0.12, 0.1, 0.1))
	box.add("box", Vector3(0, 2.65, 0), Vector3(1.95, 0.1, 1.95), Color(0.45, 0.1, 0.1))
	box.add("sphere", Vector3(0, 2.2, -0.92), Vector3(0.5, 0.6, 0.1), Color(0.92, 0.88, 0.8), Vector3.ZERO, 8)
	var coffin = mesh_of(box)
	attach(tt, coffin, 2.2, Vector3.ZERO)
	coffin.scale = Vector3(1, 0.05, 1)
	var tw = coffin.create_tween()
	tw.tween_property(coffin, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_EXPO)
	tether(func(): return Jutsu._hand(c), func(): return tt.global_position + Vector3.UP * 2.6 if is_instance_valid(tt) else Jutsu._hand(c), 0.03, glow(Color(0.45, 0.85, 1.0)), 2.2)
	st(tt, "bind", 2.2)
	Sfx.play("block", tt.global_position, 0.6)
	every(1.6, 0.2, func(i, _k):
		if not live(tt):
			return
		var a = i * 1.1
		var bl = MB.new()
		bl.add("cone", Vector3.ZERO, Vector3(0.12, 1.4, 0.03), Color(0.85, 0.88, 0.92), Vector3(0, 0, 90), 4)
		var blade = mesh_of(bl)
		attach(tt, blade, 1.0, Vector3(cos(a) * 1.1, 0.8 + (i % 3) * 0.5, sin(a) * 1.1))
		blade.look_at(tt.global_position + Vector3.UP * 1.2, Vector3.UP)
		hit(c, tt.global_position + Vector3.UP, 0.9, inf(c, "kurohigi_kiki_ippatsu", 0.3, {"knock": 0.0, "kind": "light", "burn": 2.0}))
		Sfx.play("kunai", tt.global_position, 1.4, 0.5))


## Mekanik Kalkan: önünde kukla açılır, kalkan plakaları 6 sn mermileri keser; yaklaşanı gizli bıçaklar deler
func c_kiko_junbu(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var b = MB.new()
	for k in 5:
		var a = (k - 2) * 28.0
		b.add("box", Vector3(sin(deg_to_rad(a)) * 1.4, 1.5, -cos(deg_to_rad(a)) * 0.4), Vector3(0.9, 2.6, 0.12), Color(0.55, 0.4, 0.28), Vector3(0, a, 0))
		b.add("box", Vector3(sin(deg_to_rad(a)) * 1.4, 1.5, -cos(deg_to_rad(a)) * 0.4 - 0.07), Vector3(0.5, 0.5, 0.03), Color(0.75, 0.15, 0.15), Vector3(0, a, 0))
	b.add("sphere", Vector3(0, 2.9, 0.3), Vector3(0.4, 0.45, 0.4), Color(0.92, 0.88, 0.8), Vector3.ZERO, 8)
	var shield = place(b, gp(c.global_position + d * 2.0))
	shield.look_at(shield.global_position - d, Vector3.UP)
	every(6.0, 0.1, func(i, _k):
		for n in get_tree().current_scene.get_children():
			if n is Projectile and not n.dead and Combat.hostile(c, n.shooter) and n.global_position.distance_to(shield.global_position + Vector3.UP * 1.5) < 2.8:
				FX.hit_spark(n.global_position, Color(1, 0.9, 0.6), 0.8)
				Sfx.play("block", n.global_position, 1.2, 0.5)
				n.queue_free()
		if i % 6 == 0:
			for e in enemies_near(c, shield.global_position, 2.6):
				hit(c, e.global_position + Vector3.UP, 0.9, inf(c, "kiko_junbu", 0.3, {"knock": 8.0, "kind": "heavy", "burn": 1.5})))
	fade_free(shield, 6.0, 0.3)
	Sfx.play("clink", c.global_position, 0.8)


# ================================================================== HŌKİ — canlanan mürekkep
func c_choju_giga(c: Node3D, _t: Node3D) -> void:
	var b = MB.new()
	b.add("box", Vector3.ZERO, Vector3(2.4, 0.02, 0.8), Color(0.95, 0.92, 0.82))
	var scroll = place(b, gp(c.global_position + c.face_dir() * 1.5) + Vector3.UP * 0.05)
	fade_free(scroll, 1.0, 0.3)
	ClanConstruct.spawn(c, "ink", 3, Jutsu._jd("choju_giga"))
	Sfx.play("poof", c.global_position, 0.8)


func c_choshin_giga(c: Node3D, _t: Node3D) -> void:
	var list = ClanConstruct.spawn(c, "ink", 1, Jutsu._jd("choshin_giga"))
	for u in list:
		u.vis.scale = Vector3.ONE * 2.4
		u.dmg *= 2.8
		u.max_hp *= 3.0
		u.hp = u.max_hp
		u.radius *= 2.0
	VFX.shockwave(c.global_position + Vector3.UP * 0.1, Color(0.05, 0.05, 0.08), 12.0, 0.5)
	Sfx.play("roar", c.global_position, 0.8)


## Mürekkep Klonu: vurulunca mürekkep patlaması: çevredekiler kör olur ve yavaşlar
func c_sumi_bunshin_no_jutsu(c: Node3D, _t: Node3D) -> void:
	decoy(c, c.global_position + c.global_transform.basis.x * 2.5, 12.0, func(p: Vector3):
		FX.burst(p + Vector3.UP, {"amount": 50, "life": 0.8, "size": 0.7, "vmin": 2, "vmax": 8, "add": false, "colors": [Color(0.04, 0.04, 0.06), Color(0.04, 0.04, 0.06, 0)]})
		ground_disc(p, 3.0, Color(0.05, 0.05, 0.08), 3.0, 2, 0)
		for e in enemies_near(c, p, 5.0):
			st(e, "slow", 3.0)
			if e.has_method("lose_target"):
				e.lose_target(2.5))
	FX.burst(c.global_position + Vector3.UP, {"amount": 20, "life": 0.5, "size": 0.4, "vmin": 1, "vmax": 3, "add": false, "colors": [Color(0.04, 0.04, 0.06), Color(0.04, 0.04, 0.06, 0)]})


## Mürekkep Sisi: önüne kara mürekkep sisi üflersin: 6 sn içindekiler görmez, mürekkep yapışıp yavaşlatır
func c_sumigasumi_no_jutsu(c: Node3D, t: Node3D) -> void:
	var center = c.global_position + fwd(c, t) * 7.0
	FX.burst(center + Vector3.UP, {"amount": 140, "life": 6.0, "tex": FX.tex_smoke, "add": false, "size": 3.0, "vmin": 0.3, "vmax": 1.6, "gravity": Vector3.ZERO,
		"colors": [Color(0.04, 0.04, 0.06, 0.0), Color(0.04, 0.04, 0.06, 0.92), Color(0.04, 0.04, 0.06, 0)]})
	every(6.0, 0.5, func(_i, _k):
		for e in enemies_near(c, center, 7.0):
			st(e, "slow", 0.6)
			if e.has_method("lose_target"):
				e.lose_target(0.6))
	Sfx.play("wind", c.global_position, 0.7)


## Ahtapot Tutuşu: yerdeki parşömenden mürekkep dokunaçları fışkırır, dört düşmanı yakalayıp sıkar
func c_fuinjutsu_okutopasu_horudo(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 6.0, 16.0))
	var b = MB.new()
	b.add("box", Vector3.ZERO, Vector3(3.0, 0.02, 1.0), Color(0.95, 0.92, 0.82))
	var scroll = place(b, center + Vector3.UP * 0.05)
	fade_free(scroll, 4.0, 0.3)
	var inkm = flat_mat(Color(0.03, 0.03, 0.05, 1.0))
	var list = enemies_near(c, center, 12.0).slice(0, 4)
	for e in list:
		tether(func(): return center + Vector3.UP * 0.2, func(): return e.global_position + Vector3.UP * 1.0 if is_instance_valid(e) else center, 0.45, inkm, 3.5)
		st(e, "bind", 3.5)
		every(3.5, 0.5, func(_i, _k):
			if live(e):
				hit(c, e.global_position + Vector3.UP, 0.8, inf(c, "fuinjutsu_okutopasu_horudo", 0.2, {"knock": 0.0})))
	FX.burst(center + Vector3.UP, {"amount": 40, "life": 0.6, "size": 0.6, "vmin": 3, "vmax": 7, "add": false, "colors": [Color(0.04, 0.04, 0.06), Color(0.04, 0.04, 0.06, 0)]})
	Sfx.play("water", center, 0.5)


# ================================================================== KAZAHANA — çöl rüzgarı
## Sonsuz Kum Bulutu Atılımı: kumlu dev rüzgar konisi herkesi uzağa savurur ve kör eder
func c_futon_mugen_sajin_daitoppa(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	Jutsu._wind_cone(Jutsu._mouth(c), d, 24.0, 10.0, 0.8)
	for k in 6:
		VFX.puffs(c.global_position + Vector3.UP + d * (3.0 + k * 3.5), {"amount": 14, "life": 0.8, "size": 1.8, "radius": 2.0 + k * 0.6, "vmin": 10, "vmax": 18, "dir": d, "spread": 20.0,
			"colors": [Color(0.92, 0.8, 0.58), Color(0.8, 0.65, 0.4, 0)]})
	for e in enemies_near(c, c.global_position + d * 12.0, 13.0):
		var v = e.global_position - c.global_position
		v.y = 0
		if v.normalized().dot(d) > 0.4:
			hit(c, e.global_position + Vector3.UP, 1.0, inf(c, "futon_mugen_sajin_daitoppa", 1.0, {"knock": 26.0, "launch": 5.0, "kind": "heavy", "element": "fuuton"}))
			if e.has_method("lose_target"):
				e.lose_target(2.0)
	Sfx.play("wind", c.global_position, 0.5)


## Kum Kasırgası: yürüyen kumlu hortum; içine giren havaya kalkar ve savrulur
func c_kazahana_sajin_senpu(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var tor = Node3D.new()
	get_tree().current_scene.add_child(tor)
	for k in 3:
		var cyl = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 5.0 - k * 1.0
		cm.bottom_radius = 1.0 + k * 0.4
		cm.height = 15.0 - k * 2.5
		cyl.mesh = cm
		cyl.material_override = VFX.mat_wind(Color(0.95, 0.82, 0.55), 7.0 + k * 2.0, 5.0, Vector3.UP, 0.8)
		cyl.position.y = cm.height * 0.5
		tor.add_child(cyl)
	tor.global_position = gp(c.global_position + d * 3.0)
	var hit_t = {}
	every(3.0, 1.0 / 30.0, func(i, _k):
		tor.global_position = gp(tor.global_position + d * 0.32)
		tor.rotation.y += 0.5
		if i % 3 == 0:
			VFX.puffs(tor.global_position, {"amount": 6, "life": 0.6, "size": 1.0, "radius": 2.0, "vmin": 3, "vmax": 6, "dir": Vector3.UP, "spread": 30.0, "tangent": 10.0,
				"colors": [Color(0.92, 0.8, 0.58), Color(0.8, 0.65, 0.4, 0)]})
		for e in enemies_near(c, tor.global_position, 4.2):
			var key = e.get_instance_id()
			if Time.get_ticks_msec() - int(hit_t.get(key, 0)) > 500:
				hit_t[key] = Time.get_ticks_msec()
				hit(c, e.global_position + Vector3.UP, 1.0, inf(c, "kazahana_sajin_senpu", 0.35, {"knock": 3.0, "launch": 9.0, "kind": "heavy", "element": "fuuton"})), func():
		fade_free(tor, 0.0, 0.4))
	Sfx.play("wind", c.global_position, 0.6)


## Rüzgar Kesen Dans: dönerek dört dalga halinde her yöne rüzgar bıçakları savurursun
func c_kazahana_kazekiri_mai(c: Node3D, _t: Node3D) -> void:
	busy(c, 1.0)
	every(1.0, 0.25, func(i, _k):
		if c.get("model"):
			c.model.rotation.y += PI * 0.5
		for k in 8:
			var d = Vector3(cos(k * TAU / 8.0 + i * 0.4), 0, sin(k * TAU / 8.0 + i * 0.4))
			var disc = JutsuEngine.shape_mesh("disc", Color(0.8, 1.0, 0.9), 0.6, "fuuton")
			var pr = shot(c, c.global_position + Vector3.UP * 1.1 + d * 0.8, d, 24.0, disc, inf(c, "kazahana_kazekiri_mai", 0.1, {"knock": 4.0, "kind": "light", "element": "fuuton"}), null, true, 0.5)
			pr.spin = Vector3(0, 22, 0)
		Sfx.play("wind", c.global_position, 1.6, 0.6), func():
		if is_instance_valid(c) and c.get("model"):
			c.model.rotation.y = 0.0)


## Çöl Fırtınası: 8 sn çevrende kum fırtınası; düşmanlar kör ve yavaş, sen rüzgarla hızlanırsın
func c_kazahana_sabaku_arashi(c: Node3D, _t: Node3D) -> void:
	var center = c.global_position
	FX.burst(center + Vector3.UP * 2.0, {"amount": 260, "life": 8.0, "tex": FX.tex_smoke, "add": false, "size": 2.6, "vmin": 4.0, "vmax": 9.0, "gravity": Vector3.ZERO,
		"colors": [Color(0.85, 0.7, 0.45, 0.0), Color(0.82, 0.68, 0.45, 0.75), Color(0.75, 0.6, 0.38, 0)]})
	if c is Player:
		Buffs.add("sabaku_arashi", 8.0, {"speed": 1.3})
	every(8.0, 0.5, func(i, _k):
		for e in enemies_near(c, center, 14.0):
			st(e, "slow", 0.6)
			if i % 2 == 0 and e.has_method("lose_target"):
				e.lose_target(0.8)
			if i % 4 == 0:
				hit(c, e.global_position + Vector3.UP, 0.8, inf(c, "kazahana_sabaku_arashi", 0.1, {"knock": 0.0, "element": "fuuton"})))
	Sfx.play("wind", center, 0.4)
	shake(0.4)


## Rüzgar Tanrısı Okları: üç sıkıştırılmış rüzgar oku art arda; her biri hattaki herkesi deler
func c_kazahana_fujin_ya(c: Node3D, t: Node3D) -> void:
	busy(c, 0.6)
	every(0.6, 0.2, func(_i, _k):
		var d = Jutsu._aim(c, t)
		var arrow = JutsuEngine.shape_mesh("needles", Color(0.8, 1.0, 0.9), 1.1, "fuuton")
		var pr = shot(c, Jutsu._hand(c), d, 60.0, arrow, inf(c, "kazahana_fujin_ya", 0.45, {"knock": 7.0, "kind": "heavy", "element": "fuuton"}), null, true, 1.0)
		Projectile.trail(pr, [Color(1, 1, 1), Color(0.75, 1.0, 0.9), Color(0.6, 0.9, 0.8, 0)], 0.5, 30, 0.3)
		Sfx.play("wind", c.global_position, 2.0, 0.6))


# ================================================================== KARATACHİ — Sis kılıç ustalığı
## Sessiz Öldürme: sis çöker, kaybolursun; bir buçuk sn sonra en yakın düşmanın arkasında belirip üç kez kesersin
func c_sairento_kiringu(c: Node3D, _t: Node3D) -> void:
	FX.burst(c.global_position + Vector3.UP, {"amount": 120, "life": 4.0, "tex": FX.tex_smoke, "add": false, "size": 3.0, "vmin": 1, "vmax": 4, "gravity": Vector3.ZERO,
		"colors": [Color(0.85, 0.88, 0.92, 0.0), Color(0.85, 0.88, 0.92, 0.85), Color(0.85, 0.88, 0.92, 0)]})
	for e in enemies_near(c, c.global_position, 15.0):
		if e.has_method("lose_target"):
			e.lose_target(2.5)
	if c.get("model"):
		c.model.visible = false
	after(1.4, func():
		if not is_instance_valid(c):
			return
		c.model.visible = true
		var list = enemies_near(c, c.global_position, 18.0)
		if list.is_empty():
			return
		var e = list[0]
		var behind = e.global_position - (e.face_dir() if e.has_method("face_dir") else Vector3.FORWARD) * (e.radius + 0.9)
		c.global_position = gp(behind)
		if c is Player:
			c.combat.face_to(e)
		every(0.45, 0.15, func(i, _k):
			anim(c, ["slash_a", "slash_b", "slash_a"][i], 2.6)
			hit(c, e.global_position + Vector3.UP, 1.2, inf(c, "sairento_kiringu", 0.7, {"knock": 3.0 if i < 2 else 12.0, "kind": "heavy", "hitstop": 0.05}))
			Sfx.play("kunai", c.global_position, 1.3)))


## Kemik Parçalama: kılıç bedenin içinden geçer: zırhı yok sayan ağır kesik, kanama ve sersemleme
func c_chigiri_toho_honenuki(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	var d = fwd(c, t)
	busy(c, 0.5)
	anim(c, "slash_b", 1.6)
	after(0.2, func():
		var p = (tt.global_position if live(tt) else c.global_position + d * 2.0) + Vector3.UP
		tether(func(): return p - d * 1.5, func(): return p + d * 1.5, 0.1, glow(Color(0.85, 0.2, 0.25)), 0.25)
		for h in hit(c, p, 1.5, inf(c, "chigiri_toho_honenuki", 2.2, {"knock": 2.0, "kind": "heavy", "burn": 6.0, "hitstop": 0.15})):
			st(h, "stun", 1.0)
			FX.burst(h.global_position + Vector3.UP, {"amount": 20, "life": 0.5, "size": 0.4, "vmin": 2, "vmax": 6, "add": false, "colors": [Color(0.75, 0.05, 0.08), Color(0.5, 0.0, 0.03, 0)]})
		Sfx.play("kunai", p, 0.8))


## Su Bıçağı Kesiği: kılıç çekilişinde 10 m genişliğinde basınçlı su hilali ileri kayar
func c_karatachi_suijin_giri(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 0.45)
	anim(c, "slash_a", 2.0)
	var b = MB.new()
	b.add("torus", Vector3.ZERO, Vector3(5.0, 5.0, 5.0), Color.WHITE, Vector3(90, 0, 0), 24)
	var arc = mesh_of(b, VFX.mat_water())
	arc.scale = Vector3(1.0, 0.18, 0.4)
	var pr = shot(c, c.global_position + Vector3.UP * 1.1 + d, d, 34.0, arc, inf(c, "karatachi_suijin_giri", 1.1, {"knock": 9.0, "kind": "heavy", "element": "suiton"}), null, true, 0.8)
	pr.radius = 2.4
	pr.on_tick = func(p, _dt):
		if randf() < 0.4:
			VFX.splash(p.global_position, 0.8)
	Sfx.play("water", c.global_position, 1.2)


## Sis Yağmuru: bölgeye sis çöker; 4 sn içindeki düşmanların üstüne su iğneleri yağar, sen görünmezsin
func c_karatachi_kirisame(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 8.0, 18.0))
	FX.burst(center + Vector3.UP * 2.0, {"amount": 160, "life": 4.5, "tex": FX.tex_smoke, "add": false, "size": 3.0, "vmin": 0.3, "vmax": 1.2, "gravity": Vector3.ZERO,
		"colors": [Color(0.85, 0.9, 0.95, 0.0), Color(0.85, 0.9, 0.95, 0.8), Color(0.85, 0.9, 0.95, 0)]})
	if c.get("model"):
		c.model.visible = false
		after(4.0, func():
			if is_instance_valid(c):
				c.model.visible = true)
	every(4.0, 0.12, func(_i, _k):
		var list = enemies_near(c, center, 9.0)
		if list.is_empty():
			return
		var e = list[randi() % list.size()]
		var from = e.global_position + Vector3(randf_range(-2, 2), 7.0, randf_range(-2, 2))
		var nd = JutsuEngine.shape_mesh("needles", Color(0.6, 0.85, 1.0), 0.4, "suiton")
		shot(c, from, (e.global_position + Vector3.UP - from).normalized(), 40.0, nd, inf(c, "karatachi_kirisame", 0.06, {"knock": 0.0, "kind": "light"}), null, false, 0.6))
	Sfx.play("water", center, 0.5)


## Yedi Kılıç Dansı: ışık hızında yedi atılış; yakındaki düşmanlar arasında zikzak çizerek kesersin
func c_karatachi_nanatachi(c: Node3D, _t: Node3D) -> void:
	var list = enemies_near(c, c.global_position, 16.0)
	if list.is_empty():
		Hud.msg("Yakında düşman yok", Color(0.8, 0.8, 0.8))
		return
	busy(c, 1.2)
	if c is Player:
		c.combat.invuln = 1.2
	var prev = {"p": c.global_position}
	every(1.15, 0.16, func(i, _k):
		var alive = list.filter(func(e): return live(e))
		if alive.is_empty():
			return
		var e = alive[i % alive.size()]
		var side = Vector3(cos(i * 2.1), 0, sin(i * 2.1))
		var to = gp(e.global_position + side * (e.radius + 1.0))
		var from = prev["p"]
		tether(func(): return from + Vector3.UP * 1.1, func(): return to + Vector3.UP * 1.1, 0.1, glow(Color(0.8, 0.9, 1.0)), 0.18)
		c.global_position = to
		prev["p"] = to
		if c is Player:
			c.combat.face_to(e)
		anim(c, ["slash_a", "slash_b"][i % 2], 2.8)
		hit(c, e.global_position + Vector3.UP, 1.2, inf(c, "karatachi_nanatachi", 0.4, {"knock": 4.0, "kind": "heavy", "hitstop": 0.04}))
		VFX.star(e.global_position + Vector3.UP, Color(0.85, 0.95, 1.0), 1.4, 0.12)
		Sfx.play("kunai", to, 1.5))


## Baş Kesen Çekiliş: kılıcı yükle, tek dev yay kesik; canı azalmış düşmanlara iki kat hasar
func c_karatachi_kubikiri(c: Node3D, t: Node3D) -> void:
	var a = FX.aura(c, Color(0.75, 0.85, 1.0), 1.0, Vector3(0, 0.9, 0), 0.8)
	busy(c, 1.2)
	after(0.75, func():
		if not is_instance_valid(c):
			return
		var d = fwd(c, t)
		anim(c, "slash_b", 1.4)
		var b = MB.new()
		b.add("torus", Vector3.ZERO, Vector3(4.0, 4.0, 4.0), Color.WHITE, Vector3(90, 0, 0), 24)
		var arc = place(b, c.global_position + Vector3.UP * 1.1 + d * 1.5, glow(Color(0.85, 0.93, 1.0)))
		arc.look_at(arc.global_position + d, Vector3.UP)
		arc.scale = Vector3(1.0, 1.0, 0.15)
		fade_free(arc, 0.12, 0.15)
		for e in enemies_near(c, c.global_position + d * 2.5, 4.0):
			var low = e.hp < e.max_hp * 0.4
			hit(c, e.global_position + Vector3.UP, 1.2, inf(c, "karatachi_kubikiri", 3.6 if low else 1.8, {"knock": 14.0, "launch": 3.0, "kind": "heavy", "hitstop": 0.16}))
			if low:
				Combat.popup_text(e.global_position + Vector3.UP * 2.6, "İnfaz!", Color(1, 0.4, 0.4))
		shake(0.7)
		Sfx.play("hit_heavy", c.global_position, 0.8))


# ================================================================== YOTSUKİ — yıldırım güreşi
func _lightning_limb(c: Node3D, dur: float) -> void:
	var arcs = Arcs.new()
	arcs.color = Color(0.6, 0.85, 1.0)
	arcs.radius = 0.6
	c.add_child(arcs)
	arcs.position = Vector3(0.4, 1.2, -0.3)
	after(dur, func():
		if is_instance_valid(arcs):
			arcs.queue_free())


## Liger Bombası: hedefi yakala, birlikte havalan, yıldırımla yere çak
func c_raiga_bomu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	if tt == null:
		Hud.msg("Liger Bombası: hedefi yakalamak için yaklaş", Color(0.8, 0.9, 1))
		return
	_lightning_limb(c, 1.3)
	busy(c, 1.3)
	st(tt, "bind", 1.3)
	var base = gp(tt.global_position)
	every(0.9, 1.0 / 30.0, func(_i, k):
		var h = sin(minf(k * 1.4, 1.0) * PI * 0.5) * 7.0 if k < 0.7 else lerpf(7.0, 0.0, (k - 0.7) / 0.3)
		if live(tt):
			tt.global_position = base + Vector3.UP * h
		c.global_position = base + Vector3.UP * (h + 1.4) - c.face_dir() * 0.4, func():
		if live(tt):
			tt.global_position = base
		VFX.cracks(base, 7.0)
		VFX.bolt(base + Vector3.UP * 12.0, base, Color(0.6, 0.85, 1.0), 0.5, 0.3, 4)
		VFX.shockwave(base + Vector3.UP * 0.2, Color(0.6, 0.85, 1.0), 12.0, 0.4)
		hit(c, base + Vector3.UP, 3.0, inf(c, "raiga_bomu", 2.4, {"knock": 10.0, "launch": 2.0, "kind": "heavy", "element": "raiton", "hitstop": 0.15}))
		shake(1.1)
		Sfx.play("thunder", base, 0.8))


## Giyotin Düşüşü: hedefin üstüne sıçrayıp yıldırım yüklü topukla iner: krater ve devirme
func c_girochin_doroppu(c: Node3D, t: Node3D) -> void:
	var at = gp(Jutsu._aim_ground(c, t, 6.0, 14.0))
	_lightning_limb(c, 1.0)
	busy(c, 1.0)
	c.velocity = Vector3(0, 22, 0)
	after(0.45, func():
		if not is_instance_valid(c):
			return
		c.global_position = at + Vector3.UP * 9.0
		c.velocity = Vector3(0, -55, 0)
		after(0.18, func():
			VFX.cracks(at, 6.0)
			VFX.bolt(at + Vector3.UP * 9.0, at, Color(0.6, 0.85, 1.0), 0.45, 0.25, 3)
			FX.impact(at, Color(0.6, 0.85, 1.0), 1.8)
			for h in hit(c, at + Vector3.UP, 3.4, inf(c, "girochin_doroppu", 2.0, {"knock": 12.0, "launch": 6.0, "kind": "heavy", "element": "raiton", "hitstop": 0.12})):
				st(h, "stun", 1.2)
			shake(1.0)
			Sfx.play("thunder", at, 1.0)))


## Yıldırım Lariat: yıldırımlı kol açık hücum; yoldaki herkesi boynundan biçip havaya fırlatır
func c_raiton_rariatto(c: Node3D, t: Node3D) -> void:
	var arcs = Arcs.new()
	arcs.color = Color(0.6, 0.85, 1.0)
	arcs.radius = 1.4
	c.add_child(arcs)
	arcs.position = Vector3(0, 1.1, 0)
	var hits = []
	Jutsu._dash(c, t, 0.6, 34.0, func(pt):
		for h in hit(c, pt + c.global_transform.basis.x * 0.6, 1.8, inf(c, "raiton_rariatto", 1.8, {"knock": 18.0, "launch": 9.0, "kind": "heavy", "element": "raiton", "hitstop": 0.08}), hits):
			hits.append(h)
			VFX.bolt(h.global_position + Vector3.UP * 3.0, h.global_position + Vector3.UP, Color(0.6, 0.85, 1.0), 0.3, 0.2, 2), func():
		arcs.queue_free())
	Sfx.play("chidori", c.global_position, 1.2)


## Dirsek: kısa atılış, yıldırımlı dirsek yukarı vurur, hedef sersemler
func c_erubo(c: Node3D, t: Node3D) -> void:
	_lightning_limb(c, 0.5)
	Jutsu._dash(c, t, 0.2, 22.0, func(_pt): pass, func():
		var p = c.global_position + Vector3.UP * 1.2 + c.face_dir() * 1.0
		anim(c, "hook", 2.0)
		for h in hit(c, p, 1.4, inf(c, "erubo", 1.4, {"knock": 6.0, "launch": 10.0, "kind": "heavy", "element": "raiton", "hitstop": 0.1})):
			st(h, "stun", 1.4)
		VFX.bolt(p, p + Vector3.UP * 4.0, Color(0.6, 0.85, 1.0), 0.3, 0.2, 2)
		Sfx.play("thunder", p, 1.4, 0.6))


## Cehennem Saplaması: dört parmak yıldırım mızrağı olur, 6 m hattı delip geçer
func c_jigokuzuki(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 0.5)
	anim(c, "cross", 1.6)
	after(0.2, func():
		var a = c.global_position + Vector3.UP * 1.2 + d * 0.6
		var b = a + d * 6.0
		VFX.bolt(a, b, Color(0.65, 0.9, 1.0), 0.35, 0.25, 2)
		for k in 6:
			hit(c, a.lerp(b, k / 5.0), 0.8, inf(c, "jigokuzuki", 0.6, {"knock": 8.0, "kind": "heavy", "element": "raiton", "hitstop": 0.05}))
		Sfx.play("chidori", a, 1.5))


# ================================================================== İKAZUCHİ — Ranton (fırtına)
func _laser(a: Vector3, b: Vector3, w := 0.3, dur := 0.3) -> void:
	tether(func(): return a, func(): return b, w, glow(Color(0.75, 0.9, 1.0)), dur)
	VFX.bolt(a, b, Color(0.5, 0.75, 1.0), w * 0.5, dur, 1)


## Lazer Sirki: ellerden çıkan sekiz ışın kıvrılarak ayrı hedeflere bükülür
func c_ranton_reiza_sakasu(c: Node3D, t: Node3D) -> void:
	var list = enemies_near(c, c.global_position, 35.0)
	busy(c, 0.6)
	for k in 8:
		var target = list[k % list.size()] if not list.is_empty() else null
		var d = (Jutsu._aim(c, t) + Vector3(randf_range(-0.8, 0.8), randf_range(0.2, 0.8), randf_range(-0.8, 0.8))).normalized()
		var core = MeshInstance3D.new()
		core.mesh = VFX._sphere(0.25, 8, 6)
		core.material_override = glow(Color(0.85, 0.95, 1.0))
		var pr = shot(c, Jutsu._hand(c), d, 40.0, core, inf(c, "ranton_reiza_sakasu", 0.3, {"knock": 4.0, "kind": "heavy", "element": "ranton", "stun": 0.4}), target, true, 1.6)
		pr.homing_turn = 6.0
		Projectile.trail(pr, [Color(1, 1, 1), Color(0.6, 0.85, 1.0), Color(0.3, 0.5, 1.0, 0)], 0.5, 40, 0.35, null, true)
	Sfx.play("chidori", c.global_position, 1.7)


## Lazer Yağmuru: fırtına bulutundan aşağı bükülen ışınlar 2 sn boyunca bölgeye iner
func c_ikazuchi_reiza_ame(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 12.0, 26.0))
	FX.burst(center + Vector3.UP * 14.0, {"amount": 50, "life": 2.5, "tex": FX.tex_smoke, "add": false, "size": 6.0, "vmin": 0.1, "vmax": 0.5, "gravity": Vector3.ZERO,
		"colors": [Color(0.2, 0.22, 0.3, 0.0), Color(0.18, 0.2, 0.28, 0.95), Color(0.15, 0.15, 0.2, 0)]})
	every(2.0, 0.1, func(_i, _k):
		var list = enemies_near(c, center, 10.0)
		var p = (list[randi() % list.size()].global_position if not list.is_empty() and randf() < 0.6 else center + Vector3(randf_range(-9, 9), 0, randf_range(-9, 9)))
		_laser(p + Vector3(randf_range(-3, 3), 14.0, randf_range(-3, 3)), p + Vector3.UP * 0.2, 0.25, 0.2)
		hit(c, p + Vector3.UP * 0.8, 1.4, inf(c, "ikazuchi_reiza_ame", 0.12, {"knock": 2.0, "element": "ranton"}))
		FX.ring(p + Vector3.UP * 0.1, Color(0.7, 0.9, 1.0), 2.0, 0.2))
	Sfx.play("thunder", center, 1.1)


## Fırtına Tazısı: su-yıldırım tazısı zikzak çizerek koşar; çarptığını sersemletir
func c_ikazuchi_koga(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var hound = JutsuEngine.shape_mesh("beast", Color(0.55, 0.8, 1.0), 1.5, "ranton")
	var arcs = Arcs.new()
	arcs.color = Color(0.7, 0.9, 1.0)
	arcs.radius = 1.0
	hound.add_child(arcs)
	var pr = shot(c, gp(c.global_position + d) + Vector3.UP * 0.9, d, 26.0, hound, inf(c, "ikazuchi_koga", 1.1, {"knock": 8.0, "kind": "heavy", "element": "ranton", "stun": 1.2}), tg(c, t, 30.0), false, 2.2)
	var st0 = {"t": 0.0}
	var side = d.cross(Vector3.UP)
	pr.on_tick = func(p, dt):
		st0["t"] += dt
		p.global_position += side * cos(st0["t"] * 10.0) * 0.45
		p.global_position.y = Game.ground_height(p.global_position.x, p.global_position.z) + 0.9
	Sfx.play("thunder", c.global_position, 1.5, 0.6)


## Gök Gürültüsü Bulutu: 8 sn kara bulut; içindeki her düşmana saniyede bir şimşek iner
func c_ikazuchi_raiun(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 10.0, 24.0))
	var cloud = MeshInstance3D.new()
	cloud.mesh = VFX._sphere(0.5, 20, 10)
	cloud.material_override = VFX.mat_puff(0.4, 0.0, Color(0.05, 0.05, 0.08))
	get_tree().current_scene.add_child(cloud)
	cloud.global_position = center + Vector3.UP * 12.0
	cloud.scale = Vector3(22.0, 4.0, 22.0)
	every(8.0, 1.0, func(_i, _k):
		for e in enemies_near(c, center, 12.0):
			_laser(cloud.global_position + Vector3(randf_range(-4, 4), -1.5, randf_range(-4, 4)), e.global_position + Vector3.UP, 0.35, 0.25)
			hit(c, e.global_position + Vector3.UP, 1.0, inf(c, "ikazuchi_raiun", 0.35, {"knock": 2.0, "element": "ranton", "stun": 0.5}))
		Sfx.play("thunder", center, 1.0, 0.7), func():
		fade_free(cloud, 0.0, 0.5))


## Bükülen Işın: ışın yukarı kıvrılıp engellerin üstünden aşar ve kilitli hedefe tepeden iner
func c_ikazuchi_kosen(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 40.0)
	var a = Jutsu._hand(c)
	var b = tt.global_position + Vector3.UP if tt else a + Jutsu._aim(c, t) * 25.0
	var mid = (a + b) * 0.5 + Vector3.UP * (6.0 + a.distance_to(b) * 0.2)
	var pts = []
	for k in 9:
		var f = k / 8.0
		pts.append(a.lerp(mid, f).lerp(mid.lerp(b, f), f))
	for k in pts.size() - 1:
		_laser(pts[k], pts[k + 1], 0.35, 0.35)
	hit(c, b, 1.6, inf(c, "ikazuchi_kosen", 1.8, {"knock": 8.0, "kind": "heavy", "element": "ranton", "stun": 0.8, "hitstop": 0.08}))
	FX.impact(b, Color(0.7, 0.9, 1.0), 1.4)
	Sfx.play("chidori", a, 1.9)


# ================================================================== İWAO — taş, ağırlık, golem
func c_doton_goremu_no_jutsu(c: Node3D, _t: Node3D) -> void:
	ClanConstruct.spawn(c, "golem", 1, Jutsu._jd("doton_goremu_no_jutsu"))
	Sfx.play("earth", c.global_position, 0.5)


## Hafif Kaya: bedenin tüy gibi hafifler: serbestçe uçarsın (Space yüksel, Ctrl alçal); tekrar yapınca inersin
func c_doton_keijugan_no_jutsu(c: Node3D, _t: Node3D) -> void:
	if not c is Player:
		return
	if c.flight_source() == "light":
		c.stop_flight()
		return
	var vis = Node3D.new()
	add_child(vis)
	Projectile.trail(vis, [Color(0.9, 0.86, 0.75), Color(0.8, 0.75, 0.62), Color(0.7, 0.65, 0.55, 0)], 0.3, 30, 0.9, null, false)
	var ring = MeshInstance3D.new()
	var tm = TorusMesh.new()
	tm.inner_radius = 0.7
	tm.outer_radius = 0.78
	ring.mesh = tm
	ring.material_override = glow(Color(0.9, 0.85, 0.6), 0.6)
	ring.position.y = 0.1
	vis.add_child(ring)
	c.start_flight("light", {"speed": 13.0, "lift": 9.0, "drain": 3.0, "vis": vis, "name": "Hafif Kaya"})


## Kaya Konağı Yıkımı: hedefin çevresine kayalar düşüp kubbe gibi kapanır; sonra çöküp ezer
func c_doton_iwayado_kuzushi(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 22.0)
	if tt == null:
		return
	var p = gp(tt.global_position)
	st(tt, "bind", 3.0)
	for k in 8:
		var a = k * TAU / 8.0
		var b = MB.new()
		b.add("crag", Vector3.ZERO, Vector3(1.6, 2.2, 1.4), Color(0.52, 0.47, 0.4), Vector3(0, k * 40, 0), k)
		var rock = place(b, p + Vector3(cos(a) * 1.7, 14.0, sin(a) * 1.7))
		rock.look_at(p + Vector3.UP * 3.0, Vector3.UP)
		var tw = rock.create_tween()
		tw.tween_property(rock, "global_position", p + Vector3(cos(a) * 1.5, 1.2, sin(a) * 1.5), 0.35).set_delay(k * 0.05).set_ease(Tween.EASE_IN)
		fade_free(rock, 3.0, 0.3)
	after(0.75, func():
		VFX.debris(p + Vector3.UP, Color(0.5, 0.45, 0.38), 14, 6.0, 0.5)
		shake(0.5))
	after(2.9, func():
		FX.impact(p + Vector3.UP, Color(0.6, 0.55, 0.45), 1.8)
		if live(tt):
			hit(c, tt.global_position + Vector3.UP, 1.6, inf(c, "doton_iwayado_kuzushi", 2.2, {"knock": 4.0, "kind": "heavy", "hitstop": 0.12}))
		Sfx.play("earth", p, 0.6))


## Taş Parlaklığı: yumrukların taşa dönüşür: 15 sn yakın dövüş ağırlaşır, vuruşların yere çatlak atar
func c_doton_kakogan(c: Node3D, _t: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var b = MB.new()
		b.add("crag", Vector3.ZERO, Vector3(0.42, 0.42, 0.5), Color(0.55, 0.5, 0.42), Vector3.ZERO, int(side + 2))
		attach(c, mesh_of(b), 15.0, Vector3(0.38 * side, 1.0, -0.4))
	if c is Player:
		Buffs.add("kakogan", 15.0, {"melee": 1.6})
	VFX.debris(c.global_position + Vector3.UP, Color(0.55, 0.5, 0.42), 8, 4.0, 0.3)
	Sfx.play("earth", c.global_position, 1.3)


## Sertleşme: tenin taşa döner: 12 sn hasar çok azalır, savrulmazsın ama yavaşlarsın
func c_doton_koka_jutsu(c: Node3D, _t: Node3D) -> void:
	var shell = MeshInstance3D.new()
	shell.mesh = VFX._sphere(0.5, 14, 8)
	shell.material_override = Props.toon_color(Color(0.5, 0.47, 0.42, 0.55))
	shell.scale = Vector3(1.0, 2.0, 1.0)
	attach(c, shell, 12.0, Vector3.UP * 0.95)
	if c is Player:
		Buffs.add("koka", 12.0, {"armor": 0.35, "speed": 0.8})
		c.combat.set("poise_t", 12.0)
	VFX.cracks(c.global_position, 2.5)
	Sfx.play("earth", c.global_position, 1.0)


## Ağırlık Ekleme: dokunduğun hedef taş gibi ağırlaşır: 8 sn ağır ağır hareket eder
func c_doton_kajugan_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 5.0)
	if tt == null:
		Hud.msg("Kajūgan: hedefe dokunmalısın (5 m)", Color(0.85, 0.8, 0.7))
		return
	anim(c, "cross", 1.4)
	st(tt, "slow", 8.0)
	for k in 3:
		var b = MB.new()
		b.add("cone", Vector3.ZERO, Vector3(0.3, 0.5, 0.3), Color.WHITE, Vector3(180, 0, 0), 4)
		var arrow = mesh_of(b, glow(Color(0.85, 0.75, 0.5)))
		attach(tt, arrow, 8.0, Vector3((k - 1) * 0.4, tt.height + 0.6, 0))
		var tw = arrow.create_tween().set_loops()
		tw.tween_property(arrow, "position:y", tt.height + 0.2, 0.4)
		tw.tween_property(arrow, "position:y", tt.height + 0.6, 0.01)
	FX.dust(tt.global_position, 1.2)
	Sfx.play("earth", tt.global_position, 1.4)


## Süper Ağırlık: hedef dev ağırlıkla yere mıhlanır, altındaki zemin çöker
func c_doton_chokajugan_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	if tt == null:
		Hud.msg("Chōkajūgan: hedefe dokunmalısın (6 m)", Color(0.85, 0.8, 0.7))
		return
	anim(c, "cross", 1.2)
	st(tt, "bind", 4.0)
	var p = gp(tt.global_position)
	VFX.cracks(p, 4.5)
	VFX.shockwave(p + Vector3.UP * 0.1, Color(0.8, 0.7, 0.5), 6.0, 0.3)
	FX.dust(p, 1.8)
	if tt.get("model"):
		var tw = tt.model.create_tween()
		tw.tween_property(tt.model, "position:y", -0.45, 0.2)
		tw.tween_property(tt.model, "position:y", 0.0, 0.3).set_delay(3.6)
	every(4.0, 1.0, func(_i, _k):
		if live(tt):
			hit(c, tt.global_position + Vector3.UP, 0.8, inf(c, "doton_chokajugan_no_jutsu", 0.3, {"knock": 0.0, "kind": "light"})))
	shake(0.5)
	Sfx.play("earth", p, 0.5)


# ================================================================== BAKUHA — patlama
func _clay(size: float) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = VFX._sphere(0.5, 10, 6)
	mi.material_override = Props.toon_color(Color(0.95, 0.94, 0.9))
	mi.scale = Vector3.ONE * size
	return mi


## Mayın Tarlası: önüne yay şeklinde altı kil mayın tükürürsün; 15 sn üstüne basan düşmanın altında patlar
func c_bakuha_jirai(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	for k in 6:
		var p = gp(c.global_position + d.rotated(Vector3.UP, (k - 2.5) * 0.35) * (6.0 + (k % 2) * 3.0))
		var mine = _clay(0.45)
		get_tree().current_scene.add_child(mine)
		mine.global_position = c.global_position + Vector3.UP
		var tw = mine.create_tween()
		tw.tween_property(mine, "global_position", p + Vector3.UP * 0.12, 0.35)
		var armed = {"on": true}
		after(0.4, func():
			every(15.0, 0.1, func(_i, _k):
				if not armed["on"] or not is_instance_valid(mine):
					return
				if not enemies_near(c, p, 1.6).is_empty():
					armed["on"] = false
					mine.queue_free()
					VFX.explosion(p + Vector3.UP * 0.5, 1.3, Color(1.0, 0.75, 0.3))
					hit(c, p + Vector3.UP, 3.0, inf(c, "bakuha_jirai", 0.8, {"knock": 12.0, "launch": 7.0, "kind": "heavy", "element": "bakuton"}))
					shake(0.5), func():
				if is_instance_valid(mine):
					mine.queue_free()))
	Sfx.play("poof", c.global_position, 1.3)


## Patlayan Avuç: avuçtaki ağızdan kil hedefe yapışır, iki saniye sonra içeriden patlar
func c_bakuha_kibaku_te(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 5.0)
	anim(c, "cross", 1.6)
	if tt == null:
		return
	var blob = _clay(0.5)
	attach(tt, blob, 2.0, Vector3(0, tt.height * 0.55, -tt.radius))
	var tw = blob.create_tween().set_loops()
	tw.tween_property(blob, "scale", Vector3.ONE * 0.65, 0.2)
	tw.tween_property(blob, "scale", Vector3.ONE * 0.45, 0.2)
	Combat.popup_text(tt.global_position + Vector3.UP * 2.4, "...", Color(1, 0.85, 0.4))
	after(2.0, func():
		var p = tt.global_position + Vector3.UP if is_instance_valid(tt) else c.global_position
		VFX.explosion(p, 1.8, Color(1.0, 0.7, 0.3))
		hit(c, p, 3.0, inf(c, "bakuha_kibaku_te", 2.2, {"knock": 16.0, "launch": 8.0, "kind": "heavy", "element": "bakuton", "hitstop": 0.12}))
		Combat.popup_text(p + Vector3.UP * 1.4, "Katsu!", Color(1, 0.9, 0.5))
		shake(0.8))


## Zincirleme Patlama: yerden ileriye doğru sıra sıra büyüyen patlamalar
func c_bakuha_rensa(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	for k in 7:
		var p = gp(c.global_position + d * (3.0 + k * 3.0))
		after(0.15 + k * 0.12, func():
			VFX.explosion(p + Vector3.UP * 0.5, 0.8 + k * 0.18, Color(1.0, 0.7, 0.3))
			VFX.cracks(p, 2.0 + k * 0.3)
			hit(c, p + Vector3.UP, 2.0 + k * 0.25, inf(c, "bakuha_rensa", 0.35, {"knock": 9.0, "launch": 5.0, "kind": "heavy", "element": "bakuton"}))
			shake(0.25 + k * 0.05))
	Sfx.play("boom", c.global_position, 0.9)


# ================================================================== UCHİHA — ateş ve kılıç sanatı
## Uchiha Kılıç Sanatı: göz açıp kapayana kadar hedefin etrafında üç noktada belirip kesersin
func c_uchiha_ryu_kenjutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 12.0)
	if tt == null:
		Hud.msg("Hedef 12 metre içinde olmalı", Color(0.8, 0.8, 0.8))
		return
	busy(c, 1.0)
	if c is Player:
		c.combat.invuln = 1.0
	if c.get("model"):
		c.model.hold_temp("katana", 1.2, "Right", 1.0, 0.0, false, true)
	# Sharingan öngörüsüyle üç yönden ışınlanarak kesen kılıç: her kesişte kızıl ay kavisi ve ardıl görüntü
	every(0.9, 0.3, func(i, _k):
		if not live(tt):
			return
		var a = i * 2.1 + 0.5
		var from = c.global_position
		var to = gp(tt.global_position + Vector3(cos(a), 0, sin(a)) * (tt.radius + 1.2))
		VFX.star(from + Vector3.UP * 1.1, Color(1, 0.3, 0.25), 1.6, 0.12)
		c.global_position = to
		tether(func(): return from + Vector3.UP * 1.1, func(): return to + Vector3.UP * 1.1, 0.08, glow(Color(0.95, 0.15, 0.12)), 0.18)
		if c is Player:
			c.combat.face_to(tt)
		anim(c, ["slash_a", "slash_b", "slash_c"][i], 3.0)
		_slash_arc(tt.global_position + Vector3.UP * 1.1, (tt.global_position - to).normalized(), [-35.0, 30.0, 0.0][i], Color(1.0, 0.2, 0.15), 3.2 if i < 2 else 4.5)
		hit(c, tt.global_position + Vector3.UP, 1.3, inf(c, "uchiha_ryu_kenjutsu", 0.55, {"knock": 3.0 if i < 2 else 14.0, "launch": 0.0 if i < 2 else 5.0, "kind": "heavy", "hitstop": 0.07}))
		shake(0.2 if i < 2 else 0.45)
		Sfx.play("kunai", c.global_position, 1.2))


## Kılıç kesik kavisi: yarım ay biçiminde parlayan şerit, hızla açılıp söner
func _slash_arc(pos: Vector3, dir: Vector3, roll_deg: float, col: Color, size: float) -> void:
	var b = MB.new()
	for k in 14:
		var a0 = lerpf(-1.25, 1.25, k / 14.0)
		var a1 = lerpf(-1.25, 1.25, (k + 1) / 14.0)
		var w = sin(PI * (k + 0.5) / 14.0)
		var p0 = Vector3(sin(a0), cos(a0) - 0.6, 0) * size
		var p1 = Vector3(sin(a1), cos(a1) - 0.6, 0) * size
		b.add_xf("box", Transform3D(Basis(Vector3.BACK, -(a0 + a1) * 0.5) * Basis.from_scale(Vector3((p1 - p0).length() * 1.05, 0.06 + 0.22 * w, 0.02)), (p0 + p1) * 0.5), col)
	var mi = mesh_of(b, glow(col))
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos
	var d2 = Vector3(dir.x, 0, dir.z).normalized() if Vector3(dir.x, 0, dir.z).length() > 0.01 else Vector3.FORWARD
	mi.look_at(pos + d2.cross(Vector3.UP), Vector3.UP)
	mi.rotate_object_local(Vector3.BACK, deg_to_rad(roll_deg))
	mi.scale = Vector3.ONE * 0.5
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * 1.15, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "scale", Vector3(1.25, 0.05, 1.25), 0.18)
	tw.tween_callback(mi.queue_free)


## Uchiha Şuriken Sanatı: Yıldırım Üçlüsü: telli üç shuriken farklı açılardan hedefi sarar; tellerden yıldırım akar
func c_uchiha_ryu_shurikenjutsu_ikazuchi_sanren(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 28.0)
	if tt == null:
		return
	for k in 3:
		var d = (tt.global_position + Vector3.UP - Jutsu._hand(c)).normalized().rotated(Vector3.UP, (k - 1) * 0.7)
		var b = MB.new()
		for n in 4:
			b.add("cone", Vector3(cos(n * 1.57) * 0.45, 0, sin(n * 1.57) * 0.45), Vector3(0.24, 0.9, 0.05), Color(0.3, 0.3, 0.35), Vector3(0, -n * 90, -90), 4)
		var pr = shot(c, Jutsu._hand(c), d, 30.0, mesh_of(b), inf(c, "uchiha_ryu_shurikenjutsu_ikazuchi_sanren", 0.15), tt, false, 1.6)
		pr.homing_turn = 4.0
		pr.spin = Vector3(0, 0, 30)
	after(0.7, func():
		if not live(tt):
			return
		st(tt, "bind", 2.0)
		for k in 3:
			tether(func(): return Jutsu._hand(c), func(): return tt.global_position + Vector3.UP * (0.8 + k * 0.3) if is_instance_valid(tt) else Jutsu._hand(c), 0.04, flat_mat(Color(0.85, 0.88, 0.95)), 2.0)
		every(2.0, 0.25, func(_i, _k):
			if live(tt):
				VFX.bolt(Jutsu._hand(c), tt.global_position + Vector3.UP, Color(0.6, 0.85, 1.0), 0.15, 0.15, 1)
				hit(c, tt.global_position + Vector3.UP, 0.8, inf(c, "uchiha_ryu_shurikenjutsu_ikazuchi_sanren", 0.2, {"knock": 0.0, "element": "raiton", "stun": 0.3}))))
	Sfx.play("kunai", c.global_position, 1.1)


## Uchiha Alev Düzeni: yere vurulan elden halka biçiminde 20 alev sütunu fışkırır; 8 sn içeridekiler kaçamaz, duvara değen yanar
func c_uchiha_kaenjin(c: Node3D, _t: Node3D) -> void:
	var center = gp(c.global_position)
	var r = 11.0
	busy(c, 0.7)
	anim(c, "cast_out", 1.0)
	VFX.shockwave(center + Vector3.UP * 0.2, Color(1, 0.5, 0.15), r * 2.2, 0.5)
	VFX.cracks(center, r * 0.5, Color(0.15, 0.05, 0.02, 0.8), 9.0)
	var ring = Node3D.new()
	get_tree().current_scene.add_child(ring)
	ring.global_position = center
	var mats = []
	for k in 20:
		var a = k * TAU / 20.0
		var cm = CylinderMesh.new()
		cm.top_radius = 0.25; cm.bottom_radius = 1.1; cm.height = 1.0; cm.radial_segments = 12; cm.rings = 4
		cm.cap_top = false; cm.cap_bottom = false
		var fm = VFX.mat_fire("fire", 3.6, 1.6, 0.42, 1.3, 0.25, Vector3.UP, true)
		mats.append(fm)
		var col = VFX._mi(cm, fm)
		ring.add_child(col)
		col.position = Vector3(cos(a), 0, sin(a)) * r
		col.scale = Vector3(1.6, 0.1, 1.6)
		var h = randf_range(5.0, 7.5)
		var tw = col.create_tween()
		tw.tween_interval(k * 0.02)
		tw.tween_property(col, "scale", Vector3(1.6, h, 1.6), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(col, "position:y", h * 0.5, 0.25)
	var light = OmniLight3D.new()
	light.light_color = Color(1, 0.5, 0.2); light.light_energy = 4.0; light.omni_range = r * 2.5
	ring.add_child(light)
	light.position.y = 3.0
	shake(0.5)
	Sfx.play("fire", center, 0.6)
	every(8.0, 0.2, func(i, _k):
		for e in enemies_near(c, center, r + 2.0):
			var v = e.global_position - center
			v.y = 0
			var dist = v.length()
			if dist > r - 1.6 and dist < r + 1.6:
				hit(c, e.global_position + Vector3.UP, 0.8, inf(c, "uchiha_kaenjin", 0.14, {"knock": 0.0, "element": "katon", "burn": 2.0}))
				e.global_position = gp(center + v.normalized() * (r - 1.8))   # duvar dışarı bırakmaz
		if i % 4 == 0:
			VFX.embers(center + Vector3.UP * 4.0, Color(1, 0.55, 0.15), 10, 6.0)
	, func():
		for fm in mats:
			var tw = ring.create_tween()
			tw.tween_method(func(x: float): fm.set_shader_parameter("alpha_cut", x), 0.0, 1.1, 0.6)
		get_tree().create_timer(0.7).timeout.connect(func(): if is_instance_valid(ring): ring.queue_free()))


## Uchiha Dönüşü: elde dev gunbai yelpazesi; önünde dönen kızıl chakra kalkanı gelen mermileri sahibine geri yollar,
## sonunda yelpaze savrulur ve önündeki her şeyi deviren bir fırtına patlar
func c_uchihagaeshi(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var dur = 2.4
	busy(c, dur + 0.3)
	if c.get("model"):
		c.model.hold_temp("gunbai", dur + 0.5, "Right", 2.2, PI * 0.5, false, true)
		c.model.play("block", 0.08, 1.0)
	if c is Player:
		c.facing = atan2(-d.x, -d.z)
	var center = func(): return c.global_position + Vector3.UP * 2.0 + (c.face_dir() if c.has_method("face_dir") else d) * 0.9
	# yelpazenin önünde dönen kalkan: kızıl yarı saydam disk + dönen rüzgâr halkası
	var shield = Node3D.new()
	get_tree().current_scene.add_child(shield)
	var disc = MeshInstance3D.new()
	var dm = CylinderMesh.new()
	dm.top_radius = 1.35; dm.bottom_radius = 1.35; dm.height = 0.04; dm.radial_segments = 32
	disc.mesh = dm
	var dmat = flat_mat(Color(1.0, 0.2, 0.15, 0.14))
	dmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	dmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	disc.material_override = dmat
	disc.rotation_degrees = Vector3(90, 0, 0)
	shield.add_child(disc)
	var ring = MeshInstance3D.new()
	var tm = TorusMesh.new()
	tm.inner_radius = 1.25; tm.outer_radius = 1.45; tm.rings = 32; tm.ring_segments = 8
	ring.mesh = tm
	ring.material_override = VFX.mat_wind(Color(1.0, 0.45, 0.35), 9.0, 7.0, Vector3.UP, 0.55)
	ring.rotation_degrees = Vector3(90, 0, 0)
	shield.add_child(ring)
	shield.scale = Vector3.ONE * 0.2
	shield.create_tween().tween_property(shield, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	VFX.shockwave(center.call(), Color(1.0, 0.35, 0.3), 3.0, 0.3, true, d)
	Sfx.play("wind", c.global_position, 0.7)
	var reflected = [0]
	every(dur, 1.0 / 30.0, func(_i, _k):
		if not is_instance_valid(c):
			return
		var cp: Vector3 = center.call()
		var fd: Vector3 = (cp - c.global_position - Vector3.UP * 1.3).normalized()
		shield.global_position = cp
		shield.look_at(cp + fd, Vector3.UP)
		ring.rotate_object_local(Vector3.UP, 0.35)
		for n in get_tree().current_scene.get_children():
			if n is Projectile and not n.dead and n.shooter != c and Combat.hostile(c, n.shooter) and n.global_position.distance_to(cp) < 3.2:
				var back = n.shooter
				n.shooter = c
				n.hit_list.clear()
				n.vel = -n.vel * 1.3
				if is_instance_valid(back):
					n.homing = back
					n.homing_turn = 4.0
				reflected[0] += 1
				VFX.star(n.global_position, Color(1, 0.5, 0.4), 2.5, 0.2)
				VFX.shockwave(cp, Color(1.0, 0.5, 0.4), 2.6, 0.25, true, fd)
				shake(0.15)
				Sfx.play("guard", cp, 0.8)
		for e in enemies_near(c, cp, 2.2):
			hit(c, e.global_position + Vector3.UP, 0.8, inf(c, "uchihagaeshi", 0.3, {"knock": 14.0, "launch": 3.0, "kind": "heavy"}))
	, func():
		# kapanış: yelpaze savrulur, önde koni biçimli fırtına
		if not is_instance_valid(c):
			shield.queue_free()
			return
		anim(c, "slash_b", 1.6)
		var cp: Vector3 = center.call()
		var fd: Vector3 = (cp - c.global_position - Vector3.UP * 1.3).normalized()
		var cone = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.6; cm.bottom_radius = 4.5; cm.height = 11.0; cm.radial_segments = 24; cm.cap_top = false; cm.cap_bottom = false
		cone.mesh = cm
		cone.material_override = VFX.mat_wind(Color(1.0, 0.85, 0.8), 14.0, 8.0, Vector3.UP, 0.75)
		get_tree().current_scene.add_child(cone)
		cone.global_position = cp + fd * 5.5
		cone.global_transform.basis = Basis(Quaternion(Vector3.UP, fd))
		fade_free(cone, 0.35, 0.3)
		for k in 3:
			VFX.shockwave(cp + fd * (2.0 + k * 3.0), Color(1.0, 0.6, 0.5), 3.5 + k * 1.5, 0.35 + k * 0.08, true, fd)
		VFX.debris(gp(cp + fd * 4.0), Color(0.55, 0.48, 0.38), 14, 12.0, 0.4)
		var foes = enemies_near(c, cp + fd * 5.0, 6.5)
		for e in foes:
			var v = (e.global_position - c.global_position).normalized()
			if v.dot(fd) > 0.2:
				hit(c, e.global_position + Vector3.UP, 1.0, inf(c, "uchihagaeshi", 0.9 + 0.25 * reflected[0], {"knock": 26.0, "launch": 6.0, "kind": "heavy", "dir": fd}))
		shake(0.45)
		Sfx.play("wind", cp, 0.5)
		var tw = shield.create_tween()
		tw.tween_property(shield, "scale", Vector3.ONE * 0.05, 0.2)
		tw.tween_callback(shield.queue_free))


## Anka Çiçek Tırnağı: yelpaze gibi açılan altı ateş topu, her birinin içinde dönen gizli shuriken; ateş sönse de shuriken hedefi bulur
func c_katon_hosenka_tsumabeni(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 34.0)
	busy(c, 0.8)
	anim(c, "cast_out", 1.3)
	Sfx.play("fire", c.global_position, 1.1)
	for k in 6:
		var d = Jutsu._aim(c, t).rotated(Vector3.UP, (k - 2.5) * 0.18) + Vector3.UP * (0.08 if k % 2 else -0.02)
		var root = Node3D.new()
		var fb = VFX.fireball(1.2)
		root.add_child(fb)
		var b = MB.new()
		for n in 4:
			var bs = Basis(Vector3.UP, n * PI * 0.5)
			b.add_xf("cone", Transform3D(bs * Basis(Vector3.BACK, PI * 0.5) * Basis.from_scale(Vector3(0.14, 0.42, 0.03)), bs * Vector3(0.21, 0, 0)), Color(0.32, 0.32, 0.38), 4)
		b.add("cyl", Vector3.ZERO, Vector3(0.1, 0.04, 0.1), Color(0.2, 0.2, 0.24), Vector3.ZERO, 10)
		var sh = mesh_of(b)
		root.add_child(sh)
		var spin = sh.create_tween().set_loops()
		spin.tween_property(sh, "rotation:y", TAU, 0.18).from(0.0)
		after(k * 0.08, func():
			if not is_instance_valid(c):
				return
			var pr = shot(c, Jutsu._mouth(c) + d.normalized() * 0.8, d.normalized(), 30.0, root, inf(c, "katon_hosenka_tsumabeni", 0.32, {"knock": 5.0, "element": "katon", "burn": 2.0}), tt, false, 2.2)
			pr.homing_turn = 3.0
			VFX.element_trail(pr, "katon", Color(1, 0.5, 0.1), 0.9)
			VFX.puffs(Jutsu._mouth(c), {"amount": 8, "life": 0.3, "size": 0.8, "vmin": 6, "vmax": 12, "dir": d.normalized(), "spread": 18.0, "glow": 1.1, "hot": 0.3, "colors": UCHIHA_FIRE}))


## Büyük Ateş Yok Ediş: derin nefes, ağızdan 45 m genişliğe yayılan dev ateş duvarı ileri yürür; geçtiği yeri yakar
func c_katon_goka_mekkyaku(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var side = d.cross(Vector3.UP).normalized()
	busy(c, 2.2)
	anim(c, "cast_out", 0.8)
	VFX.cinematic(c, 0.6, 0.5)
	var mo: Vector3 = Jutsu._mouth(c) + d * 0.8
	VFX.shockwave(mo, Color(1, 0.7, 0.3), 6.0, 0.4, false)
	Sfx.play("fire", mo, 0.5, 1.6)
	var start: Vector3 = gp(c.global_position)
	# ateş duvarı: yan yana 15 alev sütunu; yelpaze gibi açılarak ileri yürür
	var wall = Node3D.new()
	get_tree().current_scene.add_child(wall)
	var cols = []
	for n in 15:
		var cm = CylinderMesh.new()
		cm.top_radius = 0.3; cm.bottom_radius = 1.0; cm.height = 1.0; cm.radial_segments = 12; cm.rings = 4
		cm.cap_top = false; cm.cap_bottom = false
		var col = VFX._mi(cm, VFX.mat_fire("fire", 3.4, 1.7, 0.42, 1.3, 0.25, Vector3.UP, true))
		wall.add_child(col)
		cols.append(col)
	var light = OmniLight3D.new()
	light.light_color = Color(1, 0.55, 0.2); light.light_energy = 5.0; light.omni_range = 40.0
	wall.add_child(light)
	var hits = []
	every(2.0, 0.05, func(i, k):
		var reach = 6.0 + k * 34.0
		var w = lerpf(5.0, 46.0, minf(1.0, k * 1.5))
		var h = lerpf(2.5, 10.0, minf(1.0, k * 2.0))
		var cen = gp(start + d * reach)
		light.global_position = cen + Vector3.UP * 4.0
		for n in cols.size():
			var u = (n - 7) / 7.0
			var pp = cen + side * u * w * 0.5 - d * absf(u) * 3.0
			pp.y = Game.ground_height(pp.x, pp.z)
			var hh = h * (1.0 - absf(u) * 0.35) * (0.85 + 0.15 * sin(i * 0.7 + n))
			cols[n].global_position = pp + Vector3.UP * hh * 0.5
			cols[n].scale = Vector3(2.2, hh, 2.2)
		if i % 2 == 0:
			VFX.puffs(Jutsu._mouth(c) if is_instance_valid(c) else start, {"amount": 10, "life": 0.4, "size": 1.4, "vmin": 10, "vmax": 26, "dir": d, "spread": 22.0, "damp": 1.5,
				"glow": 1.2, "hot": 0.35, "stretch": 1.6, "outline_col": Color(0.3, 0.04, 0.02), "colors": UCHIHA_FIRE})
		if i % 3 == 0:
			for n in 5:
				var pq = cen + side * (n - 2) * w * 0.2
				VFX.cracks(pq, 3.5, Color(0.1, 0.05, 0.02, 0.9), 8.0)
				WorldDamage.impact(pq, 4.0, {"dmg": 30.0, "element": "katon", "kind": "light"})
		for n in 7:
			var hp = cen + Vector3.UP * 1.5 + side * (n - 3) * w * 0.15
			for e in hit(c, hp, 3.8, inf(c, "katon_goka_mekkyaku", 0.6, {"knock": 9.0, "kind": "heavy", "element": "katon", "burn": 3.0}), hits):
				hits.append(e)
		if i % 6 == 0:
			shake(0.35)
	, func():
		var tw = wall.create_tween()
		for col in cols:
			tw.parallel().tween_property(col, "scale:y", 0.05, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_callback(wall.queue_free))


# ================================================================== JİNTON — toz: atomlarına ayırma
## Atomize etme: alan içindeki her şey (düşman, ağaç, ev) toza döner
func _atomize(c: Node3D, pos: Vector3, r: float, id: String, mul: float) -> void:
	VFX.star(pos, Color(1, 1, 1), r, 0.25)
	for e in enemies_near(c, pos, r):
		hit(c, e.global_position + Vector3.UP, 1.0, inf(c, id, mul, {"knock": 1.0, "kind": "heavy", "hitstop": 0.1}))
		FX.burst(e.global_position + Vector3.UP, {"amount": 30, "life": 1.0, "size": 0.25, "vmin": 1, "vmax": 4, "add": false, "gravity": Vector3(0, 1, 0),
			"colors": [Color(0.95, 0.95, 0.95), Color(0.85, 0.85, 0.85, 0)]})
	WorldDamage.impact(pos, r, {"dmg": 260.0, "kind": "heavy"})
	FX.burst(pos, {"amount": 80, "life": 1.6, "size": 0.35, "vmin": 1, "vmax": 6, "add": false, "gravity": Vector3(0, 0.5, 0),
		"colors": [Color(1, 1, 1, 0.9), Color(0.85, 0.85, 0.85, 0)]})
	if Game.world:
		Game.world.env.screen_flash(0.4)
	shake(0.9)


func _dust_shape(mesh: Mesh) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = VFX.mat_spiral(Color(1, 1, 1, 0.5), Color(0.8, 0.88, 1.0, 0.35), 4.0, 1.0, 5.0, 1.6)
	return mi


func c_jinton_genkai_hakuri_no_jutsu(c: Node3D, t: Node3D) -> void:
	Jutsu.j_jinton_genkai_hakuri_no_jutsu(c, t)
	var tt = tg(c, t, 40.0)
	var pos: Vector3 = (tt.global_position + Vector3.UP) if tt else Jutsu._aim_ground(c, t, 18.0, 40.0) + Vector3.UP
	after(1.2, func(): WorldDamage.impact(pos, 5.0, {"dmg": 260.0, "kind": "heavy"}))


## Toz Küpü: şeffaf küp hedef noktada genişler, içini atomlarına ayırır
func c_jinton_kaku(c: Node3D, t: Node3D) -> void:
	var pos = gp(Jutsu._aim_ground(c, t, 16.0, 40.0)) + Vector3.UP * 4.0
	var cube = _dust_shape(BoxMesh.new())
	get_tree().current_scene.add_child(cube)
	cube.global_position = Jutsu._hand(c)
	cube.scale = Vector3.ONE * 0.3
	var tw = cube.create_tween()
	tw.tween_property(cube, "global_position", pos, 0.35)
	tw.parallel().tween_property(cube, "rotation", Vector3(TAU, TAU, 0), 0.35)
	tw.tween_property(cube, "scale", Vector3.ONE * 9.0, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.3)
	tw.tween_callback(func(): _atomize(c, pos, 5.5, "jinton_kaku", 3.0))
	tw.tween_property(cube, "scale", Vector3.ONE * 0.01, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_callback(cube.queue_free)
	Sfx.play("genjutsu", c.global_position, 1.7)


## Toz Koni Işını: uzun koni ışın hattaki her şeyi deler ve toza çevirir
func c_jinton_ensui(c: Node3D, t: Node3D) -> void:
	var d = Jutsu._aim(c, t)
	var cm = CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 2.4
	cm.height = 40.0
	var cone = _dust_shape(cm)
	get_tree().current_scene.add_child(cone)
	var a = Jutsu._hand(c)
	cone.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, -d)), a + d * 20.0)
	cone.scale = Vector3(0.05, 1, 0.05)
	var tw = cone.create_tween()
	tw.tween_property(cone, "scale", Vector3.ONE, 0.25).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.25)
	tw.tween_property(cone, "scale", Vector3(0.01, 1, 0.01), 0.2)
	tw.tween_callback(cone.queue_free)
	after(0.25, func():
		for k in 8:
			_atomize(c, a + d * (5.0 + k * 5.0), 2.2 + k * 0.1, "jinton_ensui", 0.9))
	busy(c, 0.7)
	Sfx.play("genjutsu", a, 1.9)


## Toz Silindiri: gökten inen geniş silindir bölgeyi tamamen siler
func c_jinton_ento(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 18.0, 40.0))
	var cm = CylinderMesh.new()
	cm.top_radius = 14.0
	cm.bottom_radius = 14.0
	cm.height = 40.0
	var cyl = _dust_shape(cm)
	get_tree().current_scene.add_child(cyl)
	cyl.global_position = center + Vector3.UP * 60.0
	var tw = cyl.create_tween()
	tw.tween_property(cyl, "global_position", center + Vector3.UP * 15.0, 0.5).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_atomize(c, center + Vector3.UP * 2.0, 14.0, "jinton_ento", 3.5)
		VFX.shockwave(center + Vector3.UP * 0.2, Color(0.95, 0.97, 1.0), 26.0, 0.5))
	tw.tween_interval(0.4)
	tw.tween_property(cyl, "scale", Vector3(0.01, 1, 0.01), 0.3)
	tw.tween_callback(cyl.queue_free)
	busy(c, 1.0)
	Sfx.play("genjutsu", c.global_position, 1.5)


# ================================================================== SHARINGAN GENJUTSULARI (her biri ayrı)
## Dönen üç tomoe Sharingan diski (göz göze gelme görseli)
func _sharingan_disc(size: float) -> Node3D:
	var b = MB.new()
	b.add("cyl", Vector3.ZERO, Vector3(1.0, 0.02, 1.0), Color(0.85, 0.05, 0.06), Vector3(90, 0, 0), 32)
	b.add("torus", Vector3(0, 0, 0.012), Vector3(0.62, 0.62, 0.62), Color(0.08, 0.02, 0.02), Vector3(90, 0, 0), 32)
	b.add("cyl", Vector3(0, 0, 0.015), Vector3(0.18, 0.02, 0.18), Color(0.05, 0.02, 0.02), Vector3(90, 0, 0), 16)
	for k in 3:
		var a = k * TAU / 3.0
		var p = Vector3(cos(a), sin(a), 0) * 0.31
		b.add("cyl", p + Vector3(0, 0, 0.018), Vector3(0.12, 0.02, 0.12), Color(0.05, 0.02, 0.02), Vector3(90, 0, 0), 12)
		b.add_xf("cone", Transform3D(Basis(Vector3.BACK, a + PI * 0.9) * Basis.from_scale(Vector3(0.07, 0.16, 0.02)), p + Vector3(cos(a + 0.6), sin(a + 0.6), 0) * 0.07 + Vector3(0, 0, 0.018)), Color(0.05, 0.02, 0.02), 6)
	var mi = mesh_of(b)
	var root = Node3D.new()
	root.add_child(mi)
	root.scale = Vector3.ONE * size
	var spin = mi.create_tween().set_loops()
	spin.tween_property(mi, "rotation:z", -TAU, 1.2).from(0.0)
	return root


func _gen_power(c: Node3D) -> float:
	return (1.0 + Stats.skill(Game.profile, "gen_power")) if c is Player else 1.0


## Sharingan İllüzyonu: göz göze gelinir; hedefin önünde dev dönen Sharingan, hedef donakalır (3 sn), dünya kızıla boyanır
func c_genjutsu_sharingan(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 22.0)
	if tt == null:
		return
	busy(c, 0.5)
	var gm = _gen_power(c)
	var eye_pos = Jutsu._mouth(c) + Vector3.UP * 0.12
	VFX.star(eye_pos, Color(1, 0.15, 0.1), 1.4, 0.2)
	tether(func(): return eye_pos, func(): return tt.global_position + Vector3.UP * 1.5 if is_instance_valid(tt) else eye_pos, 0.04, glow(Color(1, 0.1, 0.08)), 0.35)
	var disc = _sharingan_disc(0.1)
	get_tree().current_scene.add_child(disc)
	var face = tt.global_position + Vector3.UP * 1.6
	disc.global_position = face + (c.global_position - tt.global_position).normalized() * 1.2
	disc.look_at(face, Vector3.UP)
	var tw = disc.create_tween()
	tw.tween_property(disc, "scale", Vector3.ONE * 2.6, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.8)
	tw.tween_property(disc, "scale", Vector3.ONE * 0.01, 0.25)
	tw.tween_callback(disc.queue_free)
	st(tt, "stun", 3.0 * gm)
	st(tt, "fear", 3.0 * gm)
	hit(c, tt.global_position + Vector3.UP, 0.8, inf(c, "genjutsu_sharingan", 0.35, {"knock": 0.0, "dir": Vector3.ZERO}))
	if Game.world:
		if tt == Game.player:
			Game.world.env.flash_tint(Color(0.85, 0.05, 0.05, 0.28), 1.4)
		elif c is Player:
			Game.world.env.flash_tint(Color(0.85, 0.05, 0.05, 0.14), 0.6)
	Sfx.play("genjutsu", tt.global_position)


## Zorlayıcı Sharingan: gözlerden yayılan kızıl baskı dalgası; 18 m içindekiler diz çöker (sersem + korku)
func c_iatsu_sharingan(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.7)
	var gm = _gen_power(c)
	var center = c.global_position
	var fd: Vector3 = c.face_dir() if c.has_method("face_dir") else Vector3.FORWARD
	for k in 3:
		after(k * 0.15, func():
			VFX.shockwave(center + Vector3.UP * 1.5, Color(0.9, 0.08, 0.06), 10.0 + k * 8.0, 0.5, false)
			VFX.shockwave(gp(center) + Vector3.UP * 0.1, Color(0.6, 0.02, 0.02), 16.0 + k * 10.0, 0.6))
	var disc = _sharingan_disc(1.0)
	get_tree().current_scene.add_child(disc)
	disc.global_position = Jutsu._mouth(c) + Vector3.UP * 0.6 + fd * 0.8
	disc.look_at(disc.global_position + fd, Vector3.UP)
	var tw = disc.create_tween()
	tw.tween_property(disc, "scale", Vector3.ONE * 3.5, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(disc, "global_position:y", disc.global_position.y + 2.0, 0.5)
	tw.tween_property(disc, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(disc.queue_free)
	for e in enemies_near(c, center, 18.0):
		st(e, "stun", 2.4 * gm)
		st(e, "fear", 3.5 * gm)
		if e.get("model"):
			e.model.play("crouch", 0.1)
		FX.burst(e.global_position + Vector3.UP * 1.8, {"amount": 10, "life": 0.8, "size": 0.3, "vmin": 0.5, "vmax": 1.5, "gravity": Vector3(0, -2, 0), "colors": [Color(1, 0.2, 0.2), Color(0.5, 0, 0, 0)]})
	var near = tg(c, null, 18.0)
	if near:
		hit(c, near.global_position + Vector3.UP, 0.8, inf(c, "iatsu_sharingan", 0.5, {"knock": 0.0}))
	shake(0.5)
	if Game.world and c is Player:
		Game.world.env.flash_tint(Color(0.6, 0.0, 0.0, 0.18), 0.9)
	Sfx.play("genjutsu", center, 0.7)


## Serap Karga: kara kargalar sürüsü hedefin etrafında döner; hedef kör olur, yavaşlar; sonunda tüyler saçılır
func c_magen_shinkarasu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 26.0)
	if tt == null:
		return
	busy(c, 0.4)
	var gm = _gen_power(c)
	var crows = []
	for k in 18:
		var cb = MB.new()
		cb.add("sphere", Vector3.ZERO, Vector3(0.22, 0.2, 0.5), Color(0.05, 0.04, 0.07), Vector3.ZERO, 8)
		cb.add("cone", Vector3(0, 0, -0.32), Vector3(0.06, 0.16, 0.06), Color(0.15, 0.12, 0.1), Vector3(-90, 0, 0), 5)
		cb.add("sphere", Vector3(0.05, 0.05, -0.22), Vector3(0.04, 0.04, 0.03), Color(0.9, 0.1, 0.1), Vector3.ZERO, 5)
		var wl = MB.new()
		wl.add("box", Vector3(0.35, 0, 0), Vector3(0.7, 0.03, 0.3), Color(0.06, 0.05, 0.08), Vector3.ZERO)
		var bird = mesh_of(cb)
		for sx in [-1.0, 1.0]:
			var w = mesh_of(wl)
			w.scale.x = sx
			bird.add_child(w)
			var fl = w.create_tween().set_loops()
			fl.tween_property(w, "rotation:z", 0.8 * sx, 0.12)
			fl.tween_property(w, "rotation:z", -0.5 * sx, 0.12)
		get_tree().current_scene.add_child(bird)
		bird.global_position = c.global_position + Vector3(randf_range(-2, 2), randf_range(1, 3), randf_range(-2, 2))
		crows.append([bird, randf() * TAU, randf_range(1.6, 3.4), randf_range(0.6, 2.8), randf_range(2.5, 4.5)])
	every(3.5, 1.0 / 30.0, func(i, k):
		if not live(tt):
			return
		var cen = tt.global_position
		for cr in crows:
			var b: Node3D = cr[0]
			if not is_instance_valid(b):
				continue
			cr[1] += cr[4] / 30.0
			var target_p = cen + Vector3(cos(cr[1]) * cr[2], cr[3] + sin(cr[1] * 2.0) * 0.3, sin(cr[1]) * cr[2])
			var prev = b.global_position
			b.global_position = prev.lerp(target_p, 0.25 if k > 0.1 else 0.08)
			if (b.global_position - prev).length() > 0.01:
				b.look_at(b.global_position + (b.global_position - prev), Vector3.UP)
		if i % 10 == 0:
			st(tt, "slow", 1.2)
			if tt.has_method("lose_target"):
				tt.lose_target(1.5 * gm)
			elif tt == Game.player and Game.world:
				Game.world.env.flash_tint(Color(0.05, 0.02, 0.08, 0.45), 0.5)
			hit(c, tt.global_position + Vector3.UP, 0.8, inf(c, "magen_shinkarasu", 0.08, {"knock": 0.0}))
	, func():
		for cr in crows:
			if is_instance_valid(cr[0]):
				FX.burst(cr[0].global_position, {"amount": 6, "life": 1.2, "tex": FX.tex_leaf, "add": false, "cel": false, "size": 0.25, "vmin": 0.5, "vmax": 2.0, "gravity": Vector3(0, -1.5, 0), "spin": 300.0,
					"colors": [Color(0.05, 0.04, 0.07), Color(0.05, 0.04, 0.07, 0)]})
				cr[0].queue_free())
	Sfx.play("genjutsu", tt.global_position, 1.2)


## Zincirli Kazıklar: hedefin etrafında yerden kızıl kazıklar fırlar, kollarını ve bacaklarını çiviler; bağlı kalır ve kanar
func c_magen_kasegui_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 22.0)
	if tt == null:
		return
	busy(c, 0.5)
	var gm = _gen_power(c)
	var cen = gp(tt.global_position)
	VFX.shockwave(cen + Vector3.UP * 0.1, Color(0.5, 0.0, 0.02), 8.0, 0.5)
	var dur = 3.5 * gm
	for k in 7:
		var a = k * TAU / 7.0 + randf() * 0.3
		var base = cen + Vector3(cos(a), 0, sin(a)) * 1.6
		var tip = tt.global_position + Vector3.UP * randf_range(0.6, 1.6)
		var dir = (tip - base).normalized()
		after(k * 0.05, func():
			spike(base, (tip - base).length() + 0.5, 0.18, Color(0.55, 0.04, 0.05), dur, Vector3(-dir.z * 60.0, 0, dir.x * 60.0)))
	st(tt, "bind", dur)
	st(tt, "burn", dur)
	hit(c, tt.global_position + Vector3.UP, 0.8, inf(c, "magen_kasegui_no_jutsu", 0.5, {"knock": 0.0}))
	if Game.world:
		Game.world.env.flash_tint(Color(0.35, 0.0, 0.05, 0.3 if tt == Game.player else 0.12), 1.2)
	shake(0.35)
	Sfx.play("genjutsu", cen, 0.8)
