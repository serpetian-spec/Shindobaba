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
	"sofushasan_no_tachi": "throw", "shuriken_kage_bunshin_no_jutsu": "throw", "fuma_kaze_guruma": "throw",
	"kamizuru_bees": "two_palm", "kamizuru_wax": "breath", "kamizuru_hachi": "summon", "kamizuru_hari": "two_palm", "kamizuru_mitsu_bunshin": "clone",
	"kusa_boheki": "power", "suna_no_yoroi": "power", "gokusa_maiso": "ground", "suna_bunshin": "clone", "suna_shuriken": "sand_arms",
	"sabaku_soso": "ground", "sabaku_fuyu": "ground",
	"kurohigi_kiki_ippatsu": "summon", "kiko_junbu": "summon", "kugutsu_no_jutsu": "summon", "akahigi_hyakki_no_soen": "summon",
	"shirohigi_jikki_chikamatsu_no_shu": "summon",
	"chigiri_toho_honenuki": "rush", "sairento_kiringu": "sense", 
	
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


## Şu an atılan jutsunun sahibi: every/after/decoy geri çağrıları sahibi ölüp silinince çalışmaz
## (yoksa silinmiş yakalamalar null olur, yarım kalan jutsu hata/çökme üretir)
static var _caster: Node = null


static func cast(c: Node3D, id: String, t: Node3D) -> void:
	_caster = c
	get_inst().call("c_" + id, c, t)
	_caster = null


static func _own() -> int:
	return _caster.get_instance_id() if _caster != null and is_instance_valid(_caster) else 0


static func _gone(oid: int) -> bool:
	return oid != 0 and not is_instance_id_valid(oid)


# ================================================================== yardımcılar
const UCHIHA_FIRE := [Color(1, 0.85, 0.3, 1), Color(1, 0.55, 0.08, 1), Color(0.95, 0.3, 0.04, 0.9), Color(0.7, 0.1, 0.03, 0)]


func J() -> Node:
	return Jutsu


func gp(p: Vector3) -> Vector3:
	return Vector3(p.x, Game.jutsu_floor(p.x, p.z), p.z)


func mult(c: Node3D) -> float:
	return Jutsu._mult(c)


func inf(c: Node3D, id: String, mul: float, extra := {}) -> Dictionary:
	return Jutsu._inf(c, id, mul, extra)


func tg(c: Node3D, t: Node3D, rng: float) -> Node3D:
	return Jutsu._tg(c, t, rng)


func fwd(c: Node3D, t: Node3D) -> Vector3:
	# hedef verilmişse (kilit ya da nişangâhtaki düşman) ona dön; yoksa nişangâh yönü
	if t and is_instance_valid(t) and t != c:
		var d = t.global_position - c.global_position
		d.y = 0.0
		if d.length() > 0.2:
			return d.normalized()
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
	var own = _own()
	var tw = create_tween()
	var fin = {"done": false}
	for i in n:
		tw.tween_callback(func():
			if _gone(own):
				tw.kill()
				# atan öldü ve silindi: döngü durur ama sahnedeki parçalar (kubbe, köpekbalıkları, alanlar) temizlenmeli —
				# eskiden done hiç çağrılmıyor, Suirō Sameodori kubbesi ve köpekbalıkları sonsuza dek yerde kalıyordu
				if done.is_valid() and not fin["done"]:
					fin["done"] = true
					done.call()
				return
			var o = VFX.epic
			VFX.epic = ep
			fn.call(i, float(i) / n)
			VFX.epic = o)
		tw.tween_interval(dt)
	if done.is_valid():
		tw.tween_callback(func():
			if not fin["done"]:
				fin["done"] = true
				done.call())


func after(sec: float, fn: Callable) -> void:
	var ep = VFX.epic
	var own = _own()
	get_tree().create_timer(sec).timeout.connect(func():
		if _gone(own):
			return
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
	if (c is Player and Buffs.has("rinne_bedel")) or c.has_meta("rinne_bedel"):   # Rinne Tensei bedeli: iyileşemez
		return
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
	if mat == null:
		# baskın renge göre doku: doygun turuncu-kahve = ahşap (Mokuton), soluk gri-kahve = kaya (Doton)
		var acc = Vector3.ZERO
		var nc = mini(b.colors.size(), 400)
		for i in nc:
			var c: Color = b.colors[i * b.colors.size() / maxi(nc, 1)]
			acc += Vector3(c.r, c.g, c.b)
		if nc > 0:
			var a = acc / nc
			var avg = Color(a.x, a.y, a.z)
			if avg.s > 0.45 and avg.h > 0.04 and avg.h < 0.12 and avg.v < 0.75:
				mat = Props.bark_toon()
			elif avg.s < 0.42 and avg.v < 0.68 and avg.r >= avg.b and avg.r - avg.b < 0.25:
				mat = Props.rock_toon()
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
		var own = _own()
		d.tree_exiting.connect(func():
			if _gone(own):
				return
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
				st(v, "slow", seal_dur * 0.5)   # kanon: tenketsu kapanınca hareket etmek de zorlaşır
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
			seal_points(h, 1.5 * (i + 1))
		Sfx.play("punch", p, 1.2))


## Jūkenhō Ichigekishin (kanon, Neji): Hyūga bedenindeki bütün tenketsulardan aynı anda chakra fışkırtır — yakındakiler
## savrulur; ağ, su hapsi gibi bağlar parçalanır (Kidōmaru'nun ağı, Kisame'nin Suirō'su). Tenketsu kapalıysa yapılamaz (ninjutsu kuralı).
func c_jukenho_ichigekishin(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.5)
	_byakugan_on(c, 0.9)
	anim(c, "crouch", 2.4)
	var col = Color(0.78, 0.9, 1.0)
	# bağı çözer (kanon: bütün beden chakra basıncı)
	for k in ["bind", "mud", "slow", "chilled"]:
		if c.get("statuses") != null:
			c.statuses.erase(k)
	if c is Player:
		c.input_locked = 0.0
	# toplanma: tenketsu noktalarında küçük ışıltılar
	for k in 14:
		var q = Vector3(randf_range(-0.3, 0.3), randf_range(0.3, 1.7), randf_range(-0.3, 0.3))
		after(k * 0.008, func():
			if live(c):
				VFX.star(c.global_position + q, col, 0.35, 0.12))
	after(0.16, func():
		if not live(c):
			return
		anim(c, "cast_out", 2.0)
		var cp = c.global_position + Vector3.UP * 1.0
		# bütün bedenden dışa fışkıran chakra çizgileri (kabuk yok)
		# referans (Ichigekishin karesi): bedeni saran ak, sivri dikenli patlama silüeti — dikenler kısa, bedene yakın
		var smat = StandardMaterial3D.new()
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smat.albedo_color = Color(0.97, 0.98, 1.0)
		for n in 46:
			var hy = randf_range(0.05, 1.85)
			var ang = randf() * TAU
			var outd = Vector3(cos(ang), randf_range(-0.3, 0.5) + (0.6 if hy > 1.6 else 0.0), sin(ang)).normalized()
			var basep = c.global_position + Vector3(cos(ang) * 0.32, hy, sin(ang) * 0.32)
			var Ls = randf_range(0.45, 1.15)
			var sp = MeshInstance3D.new()
			var scm = CylinderMesh.new()
			scm.top_radius = 0.0
			scm.bottom_radius = randf_range(0.1, 0.18)
			scm.height = 1.0
			scm.radial_segments = 4
			sp.mesh = scm
			sp.material_override = smat
			sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			get_tree().current_scene.add_child(sp)
			var sdv = outd.cross(Vector3.UP if absf(outd.y) < 0.95 else Vector3.RIGHT).normalized()
			var bsp = Basis(sdv, outd, sdv.cross(outd))
			var stw = sp.create_tween()
			stw.tween_method(func(x: float):
				if is_instance_valid(sp):
					sp.global_transform = Transform3D(bsp * Basis.from_scale(Vector3(1, maxf(0.01, Ls * x), 1)), basep + outd * Ls * x * 0.5), 0.0, 1.0, 0.08)
			stw.tween_interval(0.22)
			stw.tween_method(func(x: float):
				if is_instance_valid(sp):
					sp.global_transform = Transform3D(bsp * Basis.from_scale(Vector3(x, maxf(0.01, Ls * x), x)), basep + outd * Ls * x * 0.5), 1.0, 0.0, 0.15)
			stw.tween_callback(sp.queue_free)
		# bedenden bir an taşan parlak chakra (tenketsulardan) — gövdeyi saran yumuşak ak-mavi bulut, hızla dışa açılır
		VFX.puffs(cp, {"amount": 16, "life": 0.3, "size": 0.12, "radius": 0.5, "vmin": 5.0, "vmax": 9.0, "dir": Vector3.UP, "spread": 180.0, "damp": 4.0, "add": true,
			"colors": [Color(1, 1, 1, 1), Color(0.8, 0.9, 1.0, 0)]})   # referans: bulut yok, yalnız kıvılcım
		VFX.star(cp, col, 2.4, 0.14)
		VFX.shockwave(gp(c.global_position) + Vector3.UP * 0.1, col, 7.0, 0.3)
		FX.dust(c.global_position, 1.2)
		# yakındaki mermiler/teknik parçaları basınçla söner
		for n in get_tree().current_scene.get_children():
			if n is Projectile and not n.dead and n.shooter != c and n.global_position.distance_to(cp) < 3.0:
				n.block()
		for e in enemies_near(c, c.global_position, 3.4):
			var v = e.global_position - c.global_position
			v.y = 0.0
			v = v.normalized() if v.length() > 0.05 else c.face_dir()
			hit(c, e.global_position + Vector3.UP, 0.9, inf(c, "jukenho_ichigekishin", 0.7, {"knock": 18.0, "launch": 3.0, "kind": "heavy", "dir": v, "hitstop": 0.06}))
		Combat.popup_text(c.global_position + Vector3.UP * 2.6, "Ichigekishin!", col)
		Sfx.play("wind", c.global_position, 1.3)
		shake(0.35))


## Hakke Hazangeki (kanon, Hiashi/Neji): Kūshō'nun güçlü hâli — YAKIN mesafede avuç hedefe dayanır, avuçtan çıkan dev
## chakra dalgası hedefi kayalara çarpacak kadar uçurur (dalga arkasındaki toprağı da yarar)
func c_hakke_hasangeki(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	if tt and is_instance_valid(tt):
		c.global_position = gp(tt.global_position - (tt.global_position - c.global_position).normalized() * (tt.radius + 0.9))
		if c is Player:
			c.combat.face_to(tt)
	var d = fwd(c, tt if tt else t)
	d.y = 0.0
	d = d.normalized()
	busy(c, 0.75)
	_byakugan_on(c, 1.2)
	anim(c, "crouch", 2.0)   # geri çekiliş: ağırlık arka ayağa
	var col = Color(0.8, 0.92, 1.0)
	VFX.gather(Jutsu._hand(c), col, 0.9)
	after(0.28, func():
		if not live(c):
			return
		anim(c, "cross", 1.6)
		var p0 = c.global_position + Vector3.UP * 1.1 + d * 0.9
		VFX.star(p0, col, 4.5, 0.2)
		# avuçtan ileri açılan parlak dalga: ak çekirdek, mavi kenar; 0.3 sn'de söner
		for layer in 2:
			var bm = CylinderMesh.new()
			bm.top_radius = 0.6 if layer == 0 else 0.9
			bm.bottom_radius = 3.2 if layer == 0 else 4.0
			bm.height = 12.0
			bm.radial_segments = 24
			bm.cap_top = false
			bm.cap_bottom = false
			var bmat = StandardMaterial3D.new()
			bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			bmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
			bmat.albedo_color = Color(1, 1, 1, 0.85) if layer == 0 else Color(0.45, 0.7, 1.0, 0.6)
			var beam = MeshInstance3D.new()
			beam.mesh = bm
			beam.material_override = bmat
			beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			get_tree().current_scene.add_child(beam)
			var up = d
			var sd = up.cross(Vector3.UP).normalized()
			beam.global_transform = Transform3D(Basis(sd, up, sd.cross(up)), p0 + d * 6.0)
			var btw = beam.create_tween()
			btw.tween_method(func(a: float): bmat.albedo_color.a = a, bmat.albedo_color.a, 0.0, 0.32)
			btw.tween_callback(beam.queue_free)
		# dalga: avuçtan ileri açılan basınç çizgileri + yerde yarılan toprak
		for n in 40:
			var off = Vector3(randf_range(-1, 1), randf_range(-0.6, 1), randf_range(-1, 1)) * 0.5
			var spread = d.cross(Vector3.UP) * randf_range(-0.22, 0.22) + Vector3.UP * randf_range(-0.08, 0.16)
			var L = randf_range(9.0, 15.0)
			WindFX.streak(func(u: float) -> Vector3: return p0 + off + (d + spread * u) * L * u, 0.4, 0.09, col, randf() * 0.06, 10)
		for k in 7:
			after(k * 0.04, func():
				var g = gp(c.global_position + d * (2.0 + k * 2.0))
				VFX.debris(g, Color(0.55, 0.42, 0.3), 6, 7.0, 0.35)
				WindFX.soft_dust(g, {"amount": 6, "life": 0.9, "size": 1.2, "radius": 0.9, "vmin": 2.0, "vmax": 5.0, "dir": Vector3.UP + d, "spread": 50.0}, WindFX.dust_col(g)))
		VFX.cracks(gp(c.global_position + d * 4.0), 5.0, Color(0.15, 0.12, 0.1, 0.8), 4.0)
		# yakın darbe: dayanılan hedef + önündeki dar koridor
		var hits = []
		for k in 5:
			for h in hit(c, p0 + d * (0.6 + k * 1.6), 1.2 + k * 0.15, inf(c, "hakke_hasangeki", 1.7, {"knock": 34.0, "launch": 5.0, "kind": "heavy", "dir": d, "hitstop": 0.1, "pierce_guard": true}), hits):
				hits.append(h)
		Sfx.play("wind", p0, 0.6)
		Sfx.play("punch", p0, 0.7)
		shake(0.7))


# ================================================================== NARA — gölge: bağla, taklit ettir, dik, boğ
## Kagemane: bağlanan düşman 4 sn senin hareketini aynen taklit eder (gölge taklidi)
func c_kagemane(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, Jutsu.shadow_reach())
	if tt == null:
		Hud.msg("Kagemane: gölgen şu ışıkta en fazla %d metreye uzanır" % int(Jutsu.shadow_reach()), Color(0.8, 0.8, 0.9))
		return
	Jutsu.j_kagemane(c, tt)
	var last = {"p": c.global_position}
	var held = [true]
	tt.set_meta("kagemane_hold", true)   # ortak 3 sn kilit sınırından muaf: chakra ve ışık yettikçe tutar (anime)
	Combat.popup_text(tt.global_position + Vector3.UP * 3.0, "Gölge taklidi: hareketlerini kopyalıyor!", Color(0.65, 0.6, 0.85))
	# kanon: bağı tutmak sürekli büyük chakra ister (uzun tutulamaz); hedef bağı kırarsa (ortak sersemletme sınırı) biter
	every(30.0, 1.0 / 30.0, func(_i, _k):
		if not held[0] or not live(tt) or not is_instance_valid(c):
			if is_instance_valid(tt) and tt.has_meta("kagemane_hold"):
				tt.remove_meta("kagemane_hold")
			return
		if _i > 15 and not tt.has_status("bind"):
			held[0] = false
			return
		if c is Player:
			c.chakra -= 8.0 / 30.0
			if c.chakra <= 0.0:
				c.chakra = 0.0
				held[0] = false
				tt.statuses.erase("bind")
				Combat.popup_text(c.global_position + Vector3.UP * 2.4, "Chakra bitti — gölge çekildi", Color(0.65, 0.6, 0.85))
				return
			st(tt, "bind", 0.2)
		elif _i > int(4.0 * Jutsu.shadow_k() * 30.0):
			held[0] = false
			return
		var dp: Vector3 = c.global_position - last["p"]
		last["p"] = c.global_position
		dp.y = 0
		tt.global_position = gp(tt.global_position + dp) if dp.length() < 3.0 else tt.global_position
		if tt.get("facing") != null and c.get("facing") != null:
			tt.facing = c.facing
		if c.get("model") and tt.get("model") and c.model.current != "" and c.model.current != tt.model.current:
			tt.model.play(c.model.current, 0.1), func():
		if is_instance_valid(tt) and tt.has_meta("kagemane_hold"):
			tt.remove_meta("kagemane_hold"))


## Kage Nageami Shibari (kanon, ağ gibi atılan gölge): kullanıcının gölgesinden öne doğru ağ gibi açılan kalın gölge şeritleri —
## şeritlerden birine değen her düşman donar. Görünüş: ortak gölge şeridi (kenarsız, parlamasız).
func c_kage_nageami_shibari_no_jutsu(c: Node3D, t: Node3D) -> void:
	var d = Jutsu._aim(c, t)
	d.y = 0.0
	d = d.normalized() if d.length() > 0.01 else c.face_dir()
	var L = minf(20.0, Jutsu.shadow_reach())
	var ends = []
	for k in 7:
		var dd = d.rotated(Vector3.UP, (k - 3) * 0.16)
		var e_p = c.global_position + dd * L * randf_range(0.85, 1.0)
		ends.append(e_p)
		Jutsu._shadow_path(func(): return c.global_position if is_instance_valid(c) else Vector3.ZERO, func(): return e_p, 4.0, 0.32, false)
	Sfx.play("genjutsu", c.global_position, 0.5)
	after(0.45, func():
		for e in enemies_near(c, c.global_position, L + 1.0):
			var v = e.global_position - c.global_position
			v.y = 0
			if v.length() > 0.1 and v.normalized().dot(d) > cos(0.6):
				st(e, "bind", 3.5)
				Combat.popup_text(e.global_position + Vector3.UP * 2.5, "Gölge ağı!", Color(0.6, 0.55, 0.8)))


## Kagezukami (kanon): hedefin gölgesinden kalkan kara gölge kolları bedene dolanıp kavrar ve sıkar (en fazla 3 hedef)
func c_kagezukami_no_jutsu(c: Node3D, t: Node3D) -> void:
	var list = enemies_near(c, c.global_position, minf(20.0, Jutsu.shadow_reach()))
	list.sort_custom(func(a, b): return a.global_position.distance_to(c.global_position) < b.global_position.distance_to(c.global_position))
	for e in list.slice(0, 3):
		Jutsu._shadow_line(c, e, 4.0)
		st(e, "bind", 4.0)
		after(0.45, func():
			if live(e):
				Jutsu._shadow_coil(e, 3.5, 1.4, 0.95, false)
				Jutsu._shadow_coil(e, 3.5, 1.0, 0.7, false))
		every(4.0, 0.5, func(_i, _k):
			if live(e):
				hit(c, e.global_position + Vector3.UP * e.height * 0.8, 0.8, inf(c, "kagezukami_no_jutsu", 0.22, {"knock": 0.0, "launch": 0.0, "kind": "light"})))


## Kageyose (kanon, gölge toplama): çevredeki gölgeler dört bir yandan şerit şerit tek noktaya akar, oradaki gölge göleti
## büyür; düşmanlar merkeze sürüklenir ve sıkıştırılır
func c_kageyose_no_jutsu(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 10.0, 22.0))
	for k in 8:
		var a = k * TAU / 8.0 + randf_range(-0.2, 0.2)
		var from = center + Vector3(cos(a), 0, sin(a)) * 10.0
		Jutsu._shadow_path(func(): return from, func(): return center, 2.0, 0.3, false)
	var pool = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 1.0; cm.bottom_radius = 1.0; cm.height = 0.02; cm.radial_segments = 40
	pool.mesh = cm
	pool.material_override = Jutsu._shadow_mat(0.9)
	get_tree().current_scene.add_child(pool)
	pool.global_position = center + Vector3.UP * 0.05
	pool.scale = Vector3(0.3, 1, 0.3)
	var tw = pool.create_tween()
	tw.tween_interval(0.4)
	tw.tween_property(pool, "scale", Vector3(3.2, 1, 3.2), 1.2).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.6)
	tw.tween_property(pool, "scale", Vector3(0.05, 1, 0.05), 0.4)
	tw.tween_callback(pool.queue_free)
	every(1.6, 1.0 / 30.0, func(_i, _k):
		for e in enemies_near(c, center, 11.0):
			var v = center - e.global_position
			v.y = 0
			if v.length() > 0.8:
				e.global_position = gp(e.global_position + v.normalized() * minf(v.length(), 0.28)), func():
		for e in enemies_near(c, center, 3.0):
			st(e, "bind", 3.0)
			Jutsu._shadow_coil(e, 2.5, 1.2, 0.9, false)
			hit(c, e.global_position + Vector3.UP, 1.0, inf(c, "kageyose_no_jutsu", 1.2, {"knock": 0.0, "launch": 0.0, "kind": "light"})))
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


## Kage Nui (kanon, referans: Hidan karesi): gölge şeridi hedefe ulaşır, hedefin gölgesinden çok ince, dümdüz, kapkara
## iğneler uzaktan çapraz fırlayıp bedeninde birleşir ve içinden geçer — deler ve yere diker
func c_kage_nui_no_jutsu(c: Node3D, t: Node3D) -> void:
	var list = enemies_near(c, c.global_position, minf(18.0, Jutsu.shadow_reach())).slice(0, 4)
	if list.is_empty():
		Hud.msg("Kage Nui: yakında hedef yok", Color(0.8, 0.8, 0.9))
		return
	var nm = StandardMaterial3D.new()
	nm.albedo_color = Color(0.03, 0.025, 0.04)
	nm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for e in list:
		Jutsu._shadow_line(c, e, 3.0)
		after(0.45, func():
			if not live(e):
				return
			var body = e.global_position + Vector3.UP * 1.0   # göğüs (height ölçekli kapsül boyu; iğneler başın üstünde birleşiyordu)
			for k in 7:
				var a = k * TAU / 7.0 + randf_range(-0.2, 0.2)
				var g = gp(e.global_position + Vector3(cos(a), 0, sin(a)) * randf_range(1.2, 2.0))   # dik açı (referans)
				var dir = (body + Vector3(randf_range(-0.2, 0.2), randf_range(-0.3, 0.4), randf_range(-0.2, 0.2)) - g).normalized()
				var L = g.distance_to(body) + 0.35   # bedenin içinden geçip hemen öbür yanda biter (referans)
				var nd = MeshInstance3D.new()
				var cm = CylinderMesh.new()
				cm.top_radius = 0.012
				cm.bottom_radius = 0.035
				cm.height = 1.0
				cm.radial_segments = 6
				nd.mesh = cm
				nd.material_override = nm
				nd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				get_tree().current_scene.add_child(nd)
				var sd = dir.cross(Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT).normalized()
				var bs = Basis(sd, dir, sd.cross(dir))
				nd.global_transform = Transform3D(bs * Basis.from_scale(Vector3(1, 0.01, 1)), g)
				var tw = nd.create_tween()
				tw.tween_interval(k * 0.02)
				tw.tween_method(func(x: float):
					if is_instance_valid(nd):
						nd.global_transform = Transform3D(bs * Basis.from_scale(Vector3(1, L * x, 1)), g + dir * L * x * 0.5), 0.01, 1.0, 0.12)
				tw.tween_interval(2.3)
				tw.tween_callback(nd.queue_free)
			hit(c, e.global_position + Vector3.UP, 1.2, inf(c, "kage_nui_no_jutsu", 1.0, {"knock": 0.0, "launch": 0.0, "kind": "light"}))   # çivilenen hedef ayakta kalır (referans)
			st(e, "bind", 2.5))
	Sfx.play("genjutsu", c.global_position, 0.7)


## Kagemane Kage Shibari (kanon, Ensui): gölge birden çok kola ayrılır, önündeki her düşmana ayrı bir kıvrımlı şerit uzanır ve bağlar
func c_kagemane_kage_shibari_no_jutsu(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var n = 0
	for e in enemies_near(c, c.global_position, minf(16.0, Jutsu.shadow_reach())):
		var v = e.global_position - c.global_position
		v.y = 0
		if v.length() > 0.1 and v.normalized().dot(d) > 0.5 and n < 6:
			n += 1
			Jutsu._shadow_line(c, e, 3.0)
			st(e, "bind", 3.0)
	if n == 0:
		Hud.msg("Kage Shibari: önünde gölgenin uzanacağı hedef yok", Color(0.8, 0.8, 0.9))
	Sfx.play("genjutsu", c.global_position, 0.6)


## Yamanaka ruhu (referans: Shintenshin): ruh GÖRÜNMEZ, düz bir hatta hedefe gider (ıskalarsa döner) — top/iz/patlama yok;
## yalnız varışta hedefin bir an sarsılması
func _mind_orb(c: Node3D, tt: Node3D, done: Callable) -> void:
	if c.get("model") and c.model.get("overlay"):
		c.model.overlay.set_pose("seal", 1.0)
		after(0.5, func(): if is_instance_valid(c) and c.get("model"): c.model.overlay.set_pose("seal", 0.0))
	var from: Vector3 = Jutsu._hand(c) + Vector3.UP * 0.2
	var dur = clampf(from.distance_to(tt.global_position) / 30.0, 0.15, 0.7)
	after(dur, func():
		if is_instance_valid(tt) and tt.get("model"):
			tt.model.play("hit_head", 0.05, 1.0, true)
		done.call())
	Sfx.play("genjutsu", c.global_position, 1.3)


## Zihni ele geçirilmiş/karışmış hedef: animede görünür halka yok (yalnız davranış değişir) — işaret bırakmaz
func _mind_halo(_tt: Node3D, _dur: float, _col := Color(0.85, 0.5, 1.0)) -> void:
	pass


## Zihin Karıştırma: hedef 6 sn kimin dost olduğunu bilemez, yakınındakilere saldırır
func c_shinranshin_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	if tt == null or not tt is Enemy:
		Hud.msg("Shinranshin: bir düşmanı hedefle", Color(0.8, 0.7, 1))
		return
	var old = tt.team
	tt.team = "kargasa"   # herkese düşman
	tt.target = null
	_mind_orb(c, tt, func(): if is_instance_valid(tt): _mind_halo(tt, 6.0))
	var halo = Node3D.new()
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
	for e in enemies_near(c, c.global_position, 60.0):
		st(e, "marked", 15.0)
		# zihin ağıyla aktarılan konum: başın üstünde küçük işaret (12 m ışık sütunu animede yok)
		var b = MB.new()
		b.add("cone", Vector3.ZERO, Vector3(0.4, 0.6, 0.4), Color.WHITE, Vector3(180, 0, 0), 4)
		var arrow = mesh_of(b, glow(Color(0.85, 0.55, 1.0)))
		attach(e, arrow, 15.0, Vector3.UP * (e.height + 0.9))
	Hud.msg("Zihin ağı: düşmanların yerini görüyorsun", Color(0.85, 0.7, 1.0))
	Sfx.play("genjutsu", c.global_position, 1.5)


## Lanetli Mühürlü Zihin Kuklası: hedef 15 sn senin kuklan olur, sonunda mühür onu sersemletir
func c_shinten_kugutsu_juin_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	if tt == null or not tt is Enemy or tt is Boss:
		Hud.msg("Bu teknik sıradan bir düşmanı hedef almalı", Color(0.8, 0.7, 1))
		return
	var mark = Node3D.new()   # referans: yerde mor çember yok (yalnız mühür kâğıdı)
	get_tree().current_scene.add_child(mark)
	mark.reparent(tt)
	_mind_orb(c, tt, func(): if is_instance_valid(tt): _mind_halo(tt, 15.0, Color(0.7, 0.25, 1.0)))
	for k in 3:
		pass   # referans: görünür halka/ışın/aura yok
	tt.team = c.team
	tt.target = null
	tt.power = float(tt.power) * 1.4
	Combat.popup_text(tt.global_position + Vector3.UP * 2.6, "Zihin kuklası!", Color(0.8, 0.5, 1))
	var a = null   # referans: görünür aura yok
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
	pass   # referans: görünür halka/ışın/aura yok
	_mind_orb(c, tt, func(): if is_instance_valid(tt): _mind_halo(tt, 1.6))
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
		pass   # referans: görünür halka/ışın/aura yok
		if a.get("dmg") != null:
			a.dmg = float(a.dmg) * 1.5
	if c is Player:
		Buffs.add("shindenshin_no_jin", 20.0, {"jutsu": 1.2, "melee": 1.2})
	Hud.msg("Zihin ağı: %d müttefik bağlandı" % allies.size(), Color(0.85, 0.7, 1.0))


## Algılama Aktarımı: chakra nabzı 80 m'ye yayılır, düşmanlar 10 sn işaretli kalır ve yavaşlar
func c_kanchi_denden(c: Node3D, _t: Node3D) -> void:
	for e in enemies_near(c, c.global_position, 80.0):   # referans: görünür algı dalgası yok; algılanan düşman işaretlenir
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


## Kısmi Büyüme (anime ref): karakterin GERÇEK kolu ve yumruğu devleşir (kemik büyümesi), yumruk tepeden aşağı iner;
## darbe devleşen elin yere değdiği yerde. Oyuncuda kol buff süresince (20 sn) büyük kalır, sonra küçülür.
func c_bubun_baika_no_jutsu(c: Node3D, t: Node3D) -> void:
	var dur = 20.0 if c is Player else 8.0
	if c is Player:
		Buffs.add("bubun_baika", dur, {"reach": 2.6, "melee": 1.25})
	busy(c, 1.2)
	var tt = tg(c, t, 14.0)
	# kurulma: kol geriye/yukarı (throw), büyürken avuçtan duman
	anim(c, "throw", 0.75)
	_aki_arm(c, true, [1.6, 1.85, 4.0], 0.3, dur, 0.45, true)   # el ~x12 (anime: yumruk gövdeden büyük)
	after(0.12, func():
		if live(c):
			FX.smoke_puff(_aki_hand(c), 0.45, 6))   # kol büyürken küçük duman (büyüğü dev eli örtüyordu)
	# vuruş: yumruk yere iner (devleşen elin gerçek konumu)
	after(0.58, func():
		if not live(c):
			return
		var hp = _aki_hand(c)
		var at = gp(hp)
		if hp.distance_to(at) > 4.0 and tt:
			at = gp(tt.global_position)
		VFX.cracks(at, 6.0)
		FX.impact(at + Vector3.UP * 0.5, Color(1, 0.85, 0.6), 1.8)
		VFX.debris(at, Color(0.55, 0.42, 0.3), 16, 11.0, 0.55)
		VFX.puffs(at + Vector3.UP, {"amount": 26, "life": 1.0, "size": 1.5, "radius": 2.4, "vmin": 3, "vmax": 7, "dir": Vector3.UP, "spread": 70.0, "add": false,
			"colors": [Color(0.85, 0.78, 0.65, 0.9), Color(0.75, 0.68, 0.55, 0)]})
		hit(c, at + Vector3.UP, 3.6, inf(c, "bubun_baika_no_jutsu", 1.6, {"knock": 10.0, "launch": 2.0, "kind": "heavy", "hitstop": 0.08}))
		shake(0.7)
		Sfx.play("boom", at, 0.7))


## Akimichi kemik büyümesi: kol (üst kol, ön kol, el) devleşir — PoseOverlay.grow; t_in sürede büyür, hold kalır, t_out'ta küçülür.
## Katsayılar kemik başınadır, çocuk kemiklere çarpılarak geçer (el = üst x ön x el).
func _aki_arm(c: Node3D, right: bool, k: Array, t_in: float, hold: float, t_out: float, make_fist := false, open_palm := false) -> void:
	var m = c.get("model")
	if m == null or not is_instance_valid(m) or m.get("overlay") == null:
		return
	var ov = m.overlay
	var sd = "Right" if right else "Left"
	var bones = [sd + "UpperArm", sd + "LowerArm", sd + "Hand"]
	# büyüyen eldeki silah da kemikle devleşiyordu: teknik süresince gizlenir (katman maskesi; görünürlük her kare yenilendiği için)
	var hidden = []
	for w in m.get("weapons") if m.get("weapons") != null else []:
		var wn = w.get("node")
		if String(w.get("side", "")) != sd or wn == null or not is_instance_valid(wn) or wn.get_parent() != w.get("hand"):
			continue
		var geos = (wn as Node).find_children("*", "GeometryInstance3D", true, false)
		if wn is GeometryInstance3D:
			geos.append(wn)
		for g in geos:
			if g.layers != 0:
				hidden.append([g, g.layers])
				g.layers = 0
	var tw = m.create_tween()
	tw.tween_method(func(u: float):
		if is_instance_valid(ov):
			for i in 3:
				ov.grow[bones[i]] = lerpf(1.0, float(k[i]), u)
			if make_fist:
				ov.fist[sd] = u
			elif open_palm:
				ov.fist[sd] = -u, 0.0, 1.0, t_in).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_method(func(u: float):
		if is_instance_valid(ov):
			for i in 3:
				ov.grow[bones[i]] = lerpf(float(k[i]), 1.0, u), 0.0, 1.0, t_out).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		if is_instance_valid(ov):
			for b in bones:
				ov.grow.erase(b)
			ov.fist.erase(sd)
		for hv in hidden:
			if is_instance_valid(hv[0]):
				hv[0].layers = hv[1])

## Akimichi: sağ elin dünya konumu (kemikten; devleşen elin gerçek yeri)
func _aki_hand(c: Node3D) -> Vector3:
	var m = c.get("model")
	if m and is_instance_valid(m) and m.get("skel"):
		var bi = m.skel.find_bone("RightHand")
		if bi >= 0:
			return (m.skel.global_transform * m.skel.get_bone_global_pose(bi)).origin
	return c.global_position + Vector3.UP * 1.2


## Kemiğe iliştirme düğümü (PathJutsu.bone_attach ile aynı)
func _aki_bone(c: Node3D, bone: String) -> Node3D:
	var m = c.get("model")
	if m == null or not is_instance_valid(m) or m.get("skel") == null or m.skel.find_bone(bone) < 0:
		return null
	var ba = BoneAttachment3D.new()
	ba.bone_name = bone
	m.skel.add_child(ba)
	return ba


## Süper Büyüme: dağ gibi devleşirsin; her adımın yeri sarsar
func c_cho_baika_no_jutsu(c: Node3D, _t: Node3D) -> void:
	if not c is Player:
		return
	c.combat.modes.set_size(7.0, 15.0)
	Buffs.add("cho_baika", 15.0, {"melee": 1.8, "speed": 0.8, "armor": 0.75, "reach": 3.6})
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
		Buffs.add("karori", 15.0, {"jutsu": 1.15, "melee": 1.1})
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
		Buffs.add("cho_modo", 25.0, {"melee": 1.6, "speed": 1.15, "armor": 0.8, "reach": 1.6})
	every(25.0, 1.0, func(_i, _k):
		if is_instance_valid(c):
			c.hp = maxf(1.0, c.hp - c.max_hp * 0.01))
	VFX.shockwave(c.global_position + Vector3.UP, Color(1.0, 0.6, 0.8), 14.0, 0.5, false)
	Hud.msg("Chō Mōdo! Kalorilerin yanıyor (25 sn)", Color(1, 0.6, 0.75))


## Süper Açık El Tokadı (anime ref): kol ve açık avuç devleşir (kemik büyümesi), avuç mavi chakrayla parlar;
## gerilip yandan savrulan tokat önündeki yarım dairede herkesi yere yapıştırır, sonra kol küçülür.
func c_choharite(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 1.0)
	var tt = tg(c, t, 10.0)
	anim(c, "hook", 0.85)
	_aki_arm(c, true, [1.4, 1.7, 3.8], 0.28, 0.6, 0.4, false, true)   # açık avuç ~x9
	var ba = _aki_bone(c, "RightHand")
	if ba:
		# avucu saran mavi chakra (ref): küre değil, elden sürekli yükselen mavi parçacıklar
		every(1.0, 0.04, func(_i, _k):
			if is_instance_valid(ba):
				FX.burst(ba.global_position, {"amount": 4, "life": 0.35, "tex": FX.tex_soft, "size": 0.55, "radius": 0.6, "vmin": 0.4, "vmax": 1.4,
					"spread": 180.0, "colors": [Color(0.55, 0.85, 1.0, 0.0), Color(0.45, 0.75, 1.0, 0.7), Color(0.4, 0.7, 1.0, 0.0)]}), Callable())
		after(1.1, func():
			if is_instance_valid(ba):
				ba.queue_free())
	after(0.42, func():
		if not live(c):
			return
		var hp = _aki_hand(c)
		_palm_flash(hp, d, 3.0)
		VFX.shockwave(hp, Color(0.45, 0.75, 1.0), 9.0, 0.3, false, d)
		VFX.puffs(gp(c.global_position + d * 4.0) + Vector3.UP * 0.3, {"amount": 22, "life": 0.8, "size": 1.2, "radius": 2.2, "vmin": 3, "vmax": 7, "dir": d + Vector3.UP * 0.3, "spread": 55.0, "add": false,
			"colors": [Color(0.85, 0.78, 0.65, 0.8), Color(0.75, 0.68, 0.55, 0)]})
		for e in enemies_near(c, c.global_position, 6.0):
			var to = e.global_position - c.global_position
			to.y = 0.0
			if to.length() < 0.5 or to.normalized().dot(d) > -0.15:   # önündeki yarım daire
				hit(c, e.global_position + Vector3.UP, e.radius + 0.3, inf(c, "choharite", 1.3, {"knock": 14.0, "launch": 0.0, "kind": "heavy", "hitstop": 0.1}))
		shake(0.6)
		Sfx.play("boom", c.global_position, 1.1))


# ================================================================== ABURAME — kikaichū: yapışır, chakra emer, kör eder
## Kikaichū sürüsü + yapışma: sürünün değdiği düşmanların üstünde böcekler kalır, chakra sana akar
func c_mushi_swarm(c: Node3D, t: Node3D) -> void:
	# Kikaichū no Jutsu: sürü hedefe akar ve yapışır (bulut alanı değil, yapışan sürü)
	var tt = tg(c, t, 18.0)
	var center = tt_pos(tt, Jutsu._aim_ground(c, t, 10.0))
	after(0.7, func():
		var hit_any = false
		for e in enemies_near(c, center, 3.5):
			_insects_cling(c, e, 6.0, "mushi_swarm")
			hit_any = true
		if not hit_any and live(tt) and tt.global_position.distance_to(center) < 6.0:
			_insects_cling(c, tt, 6.0, "mushi_swarm"))


func tt_pos(t: Node3D, fallback: Vector3) -> Vector3:
	return t.global_position if live(t) else fallback


## Böcek kütlesi malzemesi (kumlu, kaynayan, tırtıklı silüet) — Aburame ortak görünüşü
func swarm_mat(fade := 1.0, spin := 0.0, grain := 200.0) -> ShaderMaterial:
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/vfx_swarm.gdshader")
	m.set_shader_parameter("fade", fade)
	m.set_shader_parameter("spin", spin)
	m.set_shader_parameter("grain", grain)
	return m


## Bedenin şeklini alan böcek kaplaması (referans: Insect Sphere — hedef kollu bacaklı kara, kumlu bir silüete gömülür;
## Kikaichū yapışması: bedenin üstünde sürünen benekler). Modelin kendi meshlerine kaplama; modeli yoksa kapsül.
func swarm_body(e: Node3D, dur: float, cover := 1.0, grow := 0.06) -> void:
	var m = swarm_mat(0.0, 0.0, 220.0)
	m.set_shader_parameter("cover", cover)
	m.set_shader_parameter("grow", grow)
	m.set_shader_parameter("edge", 0.85 if cover < 1.0 else 0.72)
	var mdl = e.get("model")
	var meshes = []
	var prev = []
	if mdl and is_instance_valid(mdl):
		for mi in (mdl as Node).find_children("*", "MeshInstance3D", true, false):
			if (mi as MeshInstance3D).visible:
				prev.append((mi as MeshInstance3D).material_overlay)   # var olan kaplama (dış çizgi vb.) sonra geri gelir
				(mi as MeshInstance3D).material_overlay = m
				meshes.append(mi)
	if meshes.is_empty():
		var cmi = MeshInstance3D.new()
		var cm = CapsuleMesh.new()
		cm.radius = e.radius * 1.1
		cm.height = e.height * 1.05
		cmi.mesh = cm
		cmi.material_override = m
		attach(e, cmi, dur, Vector3.UP * e.height * 0.5)
	var tw = e.create_tween()
	tw.tween_method(func(v): m.set_shader_parameter("fade", v), 0.0, 1.0, 0.35)
	tw.tween_interval(maxf(0.1, dur - 0.8))
	tw.tween_method(func(v): m.set_shader_parameter("fade", v), 1.0, 0.0, 0.4)
	tw.tween_callback(func():
		for i in meshes.size():
			var mi = meshes[i]
			if is_instance_valid(mi) and (mi as MeshInstance3D).material_overlay == m:
				(mi as MeshInstance3D).material_overlay = prev[i])


func _insects_cling(c: Node3D, e: Node3D, dur: float, id: String) -> void:
	# kanon: kikaichū bedene yapışıp chakrayı yer — üstünde sürünen kara kılıf + çevresinde uçuşan böcekler
	swarm_body(e, dur, 0.45, 0.02)   # bedenin üstünde sürünen kikaichū benekleri
	var cloud = Projectile.trail(e, [Color(0.0, 0.0, 0.0), Color(0.02, 0.02, 0.01), Color(0.0, 0.0, 0.0, 0)], 0.25, 120, 0.7, null, false)
	cloud.position = Vector3.UP * e.height * 0.5
	after(dur, func():
		if is_instance_valid(cloud):
			cloud.emitting = false)
	st(e, "slow", dur)
	every(dur, 0.6, func(_i, _k):
		if live(e):
			hit(c, e.global_position + Vector3.UP, 0.8, inf(c, id, 0.1, {"knock": 0.0, "kind": "light", "chakra_drain": 5.0}))
			if _i % 3 == 0:
				chakra_gain(c, 2.0))


## Böcek Klonu: kikaichū toplanıp senin şeklini alır; vurulunca dağılıp vuranlara yapışır
func c_mushi_bunshin_no_jutsu(c: Node3D, _t: Node3D) -> void:
	decoy(c, c.global_position + c.global_transform.basis.x * 2.5, 12.0, func(p: Vector3):
		FX.burst(p + Vector3.UP, {"amount": 60, "life": 0.8, "size": 0.12, "vmin": 2, "vmax": 7, "add": false, "colors": [Color(0.06, 0.06, 0.05), Color(0.06, 0.06, 0.05, 0)]})
		for e in enemies_near(c, p, 5.0):
			_insects_cling(c, e, 5.0, "mushi_bunshin_no_jutsu"))
	FX.smoke_puff(c.global_position + Vector3.UP, 0.8, 10)


## Mushi Jamingu (kanon): yayılan böcekler sahte chakra izleri salar — algılayıcılar ve nişan alanlar seni kaybeder.
## (Jutsu yapmayı engellemez; yalnız hedef bulmayı bozar.) Oyuncuya karşı düşman: kilidin kırılır.
func c_mushi_jamingu_no_jutsu(c: Node3D, t: Node3D) -> void:
	var center = gp(c.global_position)
	c.set_meta("jamming_until", Time.get_ticks_msec() / 1000.0 + 8.0)
	every(8.0, 0.5, func(_i, _k):
		for e in enemies_near(c, center, 22.0):
			if e.has_method("lose_target"):
				e.lose_target(1.0)
			if e is Player and e.combat:
				e.combat.lock_target = null)
	Sfx.play("wind", center, 2.4, 0.6)


## Hijutsu: Mushidama (kanon): hedefi bedeninin şeklinde saran kara küre; chakrasını yer, kaçsa da peşinden gider
func c_hijutsu_mushidama(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 22.0)
	if tt == null:
		return
	after(0.6, func():
		if not live(tt):
			return
		swarm_body(tt, 4.5, 1.0, 0.12)   # kollu bacaklı kara silüet
		st(tt, "bind", 3.5)
		every(4.5, 0.5, func(_i, _k):
			if live(tt):
				hit(c, tt.global_position + Vector3.UP, 1.0, inf(c, "hijutsu_mushidama", 0.18, {"knock": 0.0, "chakra_drain": 8.0}))
				if _i % 2 == 0:
					chakra_gain(c, 3.0)))
	Sfx.play("wind", tt.global_position, 2.0, 0.5)


## Kidaichū — Mushikui (kanon): temas! Düşmanın derisine dev böcekler bırakılır; içine girip eti ve chakrayı yerken büyürler
func c_kidaichu_mushikui(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 3.2)
	if tt == null or tt.global_position.distance_to(c.global_position) > 3.2 + tt.radius:
		if c is Player:
			Hud.msg("Kidaichū için düşmana dokunmalısın (yakın mesafe).", Color(0.85, 0.85, 0.7))
		return
	# böcekler hedefin bedeninde CANLI: kemiklere bağlı deride sürünür (hedef düşse de bedeninde), gittiği yöne döner,
	# bacakları iki fazda yürür; yedikçe büyür (küçük başlar)
	var mA = _kidaichu_mesh(0).build(Props.toon())
	var mB = _kidaichu_mesh(1).build(Props.toon())
	var bones = ["Hips", "Spine", "Chest", "UpperChest", "RightUpperArm", "LeftUpperArm", "RightUpperLeg", "LeftUpperLeg"]
	var bugs = []
	for k in 5:
		var mi = MeshInstance3D.new()
		mi.mesh = mA
		get_tree().current_scene.add_child(mi)
		bugs.append({"mi": mi, "bone": bones[(k * 3) % bones.size()], "a": randf() * TAU, "sp": randf_range(0.6, 1.2) * (1.0 if k % 2 == 0 else -1.0), "ph": randf() * TAU})
	var dur = 8.0
	var tm = tt.get("model")
	var sk: Skeleton3D = tm.skel if tm and is_instance_valid(tm) else null
	every(dur, 1.0 / 30.0, func(i, k):
		if not live(tt):
			return
		for bg in bugs:
			var mi: MeshInstance3D = bg["mi"]
			if not is_instance_valid(mi):
				continue
			var bxf: Transform3D
			var bi = sk.find_bone(bg["bone"]) if sk and is_instance_valid(sk) else -1
			if bi >= 0:
				bxf = sk.global_transform * sk.get_bone_global_pose(bi)
			else:
				bxf = Transform3D(Basis.IDENTITY, tt.global_position + Vector3.UP * float(tt.height) * 0.6)
			bg["a"] = float(bg["a"]) + float(bg["sp"]) * 0.06
			var r = 0.16 if String(bg["bone"]).contains("Arm") or String(bg["bone"]).contains("Leg") else 0.2
			var ax: Vector3 = bxf.basis.y.normalized()   # kemik ekseni etrafında dolaş
			var px: Vector3 = bxf.basis.x.normalized()
			var pz: Vector3 = bxf.basis.z.normalized()
			var off = (px * cos(float(bg["a"])) + pz * sin(float(bg["a"]))) * r
			var slide = ax * sin(i * 0.05 + float(bg["ph"])) * 0.12
			var pos = bxf.origin + off + slide
			var tang = (px * -sin(float(bg["a"])) + pz * cos(float(bg["a"]))) * signf(float(bg["sp"]))
			mi.global_position = pos
			if tang.length() > 0.01 and off.length() > 0.01:
				mi.global_basis = Basis.looking_at(tang, off.normalized()).scaled(Vector3.ONE * (0.3 + k * 0.1))   # önkol boyunu geçmez (kullanıcı: "kolu kadar olsa yeter")
			if i % 3 == 0:
				mi.mesh = mB if mi.mesh == mA else mA   # tripod yürüyüş: bacak fazları değişir
		if i % 15 == 0:
			hit(c, tt.global_position + Vector3.UP, 1.0, inf(c, "kidaichu_mushikui", 0.08 + k * 0.3, {"knock": 0.0, "kind": "light", "chakra_drain": 4.0 + k * 8.0, "bleed": 0.5}))
			if i % 60 == 0:
				FX.burst(tt.global_position + Vector3.UP * float(tt.height) * 0.6, {"amount": 8, "life": 0.4, "size": 0.08, "vmin": 1, "vmax": 3, "add": false, "colors": [Color(0.5, 0.05, 0.05), Color(0.3, 0.02, 0.02, 0)]}), func():
		for bg in bugs:
			if is_instance_valid(bg["mi"]):
				bg["mi"].queue_free())
	Sfx.play("wind", c.global_position, 1.6, 0.6)


## Kidaichū / Kikaichū (anime referansı): uzun, parlak koyu karın (enine bölüm çizgileri), önde mor-gri çatlak göğüs kalkanı,
## küçük koyu baş, iri oval camgöbeği gözler, dizleri gövdeden yukarıda duran ince uzun eklemli bacaklar. İleri = -Z, sırt = +Y.
## phase 0/1: üçlü yürüyüş bacak fazları
func _kidaichu_mesh(phase := 0) -> MB:
	var b = MB.new()
	var DK = Color(0.11, 0.11, 0.11)
	var GL = Color(0.32, 0.32, 0.34)
	var SH = Color(0.56, 0.53, 0.62)
	b.add_grad("sphere", Vector3(0, 0.02, 0.2), Vector3(0.44, 0.3, 0.66), GL, DK, Vector3.ZERO, 14)   # karın
	for k in 5:   # enine bölüm çizgileri (koyu oluklar)
		var z = 0.0 + k * 0.1
		var w = sqrt(maxf(0.05, 1.0 - pow((z - 0.2) / 0.33, 2.0)))
		b.add("sphere", Vector3(0, 0.03, z), Vector3(0.45 * w, 0.31 * w, 0.025), DK.darkened(0.4), Vector3.ZERO, 12)
	b.add_grad("sphere", Vector3(0, 0.05, -0.18), Vector3(0.36, 0.27, 0.3), SH.lightened(0.08), SH.darkened(0.3), Vector3.ZERO, 12)   # göğüs kalkanı
	b.add_grad("sphere", Vector3(0, 0.0, -0.36), Vector3(0.22, 0.19, 0.18), GL, DK, Vector3.ZERO, 10)   # baş
	for sx in [-1.0, 1.0]:
		b.add_grad("sphere", Vector3(sx * 0.085, 0.03, -0.42), Vector3(0.08, 0.1, 0.09), Color(0.35, 0.75, 0.75), Color(0.12, 0.4, 0.42), Vector3.ZERO, 8)   # iri oval göz
		b.add("sphere", Vector3(sx * 0.095, 0.07, -0.46), Vector3(0.022, 0.025, 0.02), Color(0.9, 1.0, 1.0), Vector3.ZERO, 4)   # göz parıltısı
		BeastRig.claw(b, Vector3(sx * 0.04, -0.05, -0.43), Vector3(-sx * 0.3, -0.3, -1.0), 0.09, 0.016, DK)   # çene
		BeastRig.claw(b, Vector3(sx * 0.05, 0.08, -0.42), Vector3(sx * 0.35, 0.45, -0.85), 0.16, 0.008, DK)   # anten
		for k in 3:
			var z = -0.2 + k * 0.17
			var lift = 1.0 if ((k + (0 if sx > 0 else 1) + phase) % 2 == 0) else 0.0   # tripod: çapraz bacaklar birlikte kalkar
			var hip = Vector3(sx * 0.16, -0.04, z)
			var knee = hip + Vector3(sx * 0.2, 0.16 + lift * 0.05, (k - 1) * 0.07 - lift * 0.05)   # diz gövdeden yukarıda
			var foot = knee + Vector3(sx * 0.1, -0.42 + lift * 0.08, (k - 1) * 0.08)
			BeastRig.claw(b, hip, knee - hip, (knee - hip).length(), 0.022, DK)   # uyluk
			BeastRig.claw(b, knee, foot - knee, (foot - knee).length(), 0.017, DK)   # bacak
	return b


## Mushi Kame no Jutsu (kanon): çevrende Kaiten gibi hızla dönen böcek kubbesi; mermileri yutar, değenin chakrasını emer.
## Yeterli patlama gücü kubbeyi dağıtır (yutulan mermi hasarı eşiği aşınca).
func c_mushi_kabe(c: Node3D, _t: Node3D) -> void:
	var dome = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 28
	sm.rings = 14
	dome.mesh = sm
	var m = swarm_mat(1.0, 0.9, 240.0)
	dome.material_override = m
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dome.scale = Vector3.ONE * 6.0
	attach(c, dome, 8.0, Vector3.UP * 1.0)
	var taken = [0.0]
	var cap = 140.0 * Jutsu._mult(c)
	every(8.0, 0.1, func(_i, _k):
		if not is_instance_valid(c) or not is_instance_valid(dome):
			return
		dome.rotation.y += 0.45
		for n in get_tree().current_scene.get_children():
			if n is Projectile and not n.dead and n.shooter != c and Combat.hostile(c, n.shooter) and n.global_position.distance_to(c.global_position + Vector3.UP) < 3.4:
				taken[0] += float(n.info.get("dmg", 10.0))
				FX.burst(n.global_position, {"amount": 10, "life": 0.4, "size": 0.15, "vmin": 1, "vmax": 3, "add": false, "colors": [Color(0.06, 0.06, 0.05), Color(0.06, 0.06, 0.05, 0)]})
				n.queue_free()
		if taken[0] > cap:   # yeterince güçlü saldırı: kubbe dağılır
			FX.burst(c.global_position + Vector3.UP, {"amount": 120, "life": 1.0, "size": 0.12, "vmin": 3, "vmax": 9, "add": false, "colors": [Color(0.06, 0.06, 0.05), Color(0.06, 0.06, 0.05, 0)]})
			dome.queue_free()
			return
		if _i % 5 == 0:
			for e in enemies_near(c, c.global_position, 3.6):
				hit(c, e.global_position + Vector3.UP, 0.8, inf(c, "mushi_kabe", 0.12, {"knock": 5.0, "chakra_drain": 4.0}))
				chakra_gain(c, 2.0))
	Sfx.play("wind", c.global_position, 2.2, 0.6)


## Hijutsu: Mushiheki (kanon): önünde dev böcek duvarı — seni ve arkandakileri korur (mermi, düşen cisim, Katon)
func c_hijutsu_mushiheki(c: Node3D, t: Node3D) -> void:
	var d = c.face_dir() if c.has_method("face_dir") else Vector3.FORWARD
	d.y = 0
	d = d.normalized()
	var at = gp(c.global_position + d * 3.0)
	# referans: tırtıklı kenarlı dev duvar — üst üste binen düzensiz böcek kütleleri (kutu değil)
	var wall = Node3D.new()
	get_tree().current_scene.add_child(wall)
	wall.global_position = at
	wall.look_at(at + d, Vector3.UP)
	var m = swarm_mat(0.0, 0.0, 240.0)
	m.set_shader_parameter("edge", 0.8)
	m.set_shader_parameter("col", Color(0.17, 0.17, 0.16))   # referans: gri-kara taneli
	var sm = SphereMesh.new()
	sm.radial_segments = 16
	sm.rings = 10
	for k in 46:
		var mi = MeshInstance3D.new()
		mi.mesh = sm
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var x = randf_range(-5.5, 5.5)
		var top = 10.5 - absf(x) * 0.3 + randf_range(-1.5, 1.5)   # referans: insanın birkaç katı yüksek
		var y = randf_range(0.0, top) if k >= 12 else randf_range(0.0, 1.5)   # ilk kütleler tabanı yere oturtur
		mi.position = Vector3(x, y, randf_range(-0.3, 0.3))
		mi.scale = Vector3(randf_range(3.0, 4.4), randf_range(2.8, 4.0), randf_range(1.2, 1.8))
		if k >= 38:   # kenarlardan dışa uzanan sivri tırtıklar
			mi.position.x = signf(x) * randf_range(5.0, 6.5)
			mi.scale = Vector3(randf_range(2.6, 3.6), randf_range(0.8, 1.2), 1.0)
		wall.add_child(mi)
	wall.scale = Vector3(1, 0.05, 1)
	var tw = wall.create_tween()
	tw.tween_property(wall, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_method(func(v): m.set_shader_parameter("fade", v), 0.0, 1.0, 0.3)
	tw.tween_interval(6.0)
	tw.tween_method(func(v): m.set_shader_parameter("fade", v), 1.0, 0.0, 0.6)
	tw.tween_callback(wall.queue_free)
	every(6.5, 0.05, func(_i, _k):
		if not is_instance_valid(wall):
			return
		for n in get_tree().current_scene.get_children():
			if n is Projectile and not n.dead and n.shooter != c and Combat.hostile(c, n.shooter):
				var rel: Vector3 = n.global_position - at
				if absf(rel.dot(d)) < 1.2 and absf(rel.dot(d.cross(Vector3.UP))) < 6.0 and rel.y < 8.5:
					FX.burst(n.global_position, {"amount": 12, "life": 0.4, "size": 0.15, "vmin": 1, "vmax": 3, "add": false, "colors": [Color(0.06, 0.06, 0.05), Color(0.06, 0.06, 0.05, 0)]})
					n.queue_free())
	Sfx.play("wind", at, 1.8, 0.7)


## Hijutsu: Mushimayu (kanon): kendini kozaya sarar — hareketsiz ve savunmasız; böcekler hızla büyür, koloni dolar
func c_hijutsu_mushimayu(c: Node3D, _t: Node3D) -> void:
	var DUR = 5.0
	# anime: kullanıcı diz çöküp mühür yapar; böcekler ipek örer, yarı saydam parlayan koza alttan yukarı kapanır (içi görünür)
	var mi = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.95
	sm.height = 2.1
	sm.radial_segments = 40
	sm.rings = 24
	mi.mesh = sm
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://shaders/vfx_cocoon.gdshader")
	mat.set_shader_parameter("grow", 0.0)
	mat.set_shader_parameter("height", 2.1)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.scale = Vector3(1.0, 1.0, 0.92)
	attach(c, mi, DUR + 0.6, Vector3.UP * 0.75)
	var tw = mi.create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("grow", v), 0.0, 1.05, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(DUR - 1.2)
	tw.tween_method(func(v): mat.set_shader_parameter("grow", v), 1.05, 0.0, 0.5)
	var tt = [0.0]
	every(DUR, 0.1, func(i, _k):
		tt[0] += 0.1
		mat.set_shader_parameter("t", tt[0])
		if live(c) and c.get("model"):   # koza boyunca diz çökük + eller mühürde (anime); klip oyuncu animasyonunca eziliyordu
			c.set_meta("kneel", true)
			c.model.overlay.charge_k = 1.0
			c.model.overlay.set_pose("seal", 1.0)
		if live(c) and i % 2 == 0:   # örülen ipeğin etrafında dolaşan böcekler
			var a = randf() * TAU
			FX.burst(c.global_position + Vector3(cos(a) * 1.0, randf_range(0.2, 1.6), sin(a) * 1.0), {"amount": 4, "life": 0.6, "size": 0.06, "vmin": 0.3, "vmax": 1.0, "add": false,
				"tangent": 4.0, "colors": [Color(0.06, 0.06, 0.05), Color(0.06, 0.06, 0.05, 0)]}), Callable())
	busy(c, DUR)
	if c is Player:
		c.input_locked = DUR
		Buffs.add("mushimayu", DUR, {"speed": 0.0, "armor": 1.3})   # savunmasız: aldığı hasar artar
	after(DUR, func():
		if not live(c):
			return
		if c.get("model"):
			c.model.overlay.charge_k = 0.0
			c.model.overlay.set_pose("seal", 0.0)
		if c.has_meta("kneel"):
			c.remove_meta("kneel")
		FX.burst(c.global_position + Vector3.UP, {"amount": 90, "life": 1.0, "size": 0.1, "vmin": 2, "vmax": 6, "add": false, "colors": [Color(0.06, 0.06, 0.05), Color(0.06, 0.06, 0.05, 0)]})
		if c is Player:
			Game.profile["kikaichu"] = ClanMech.KOLONI_MAX
			Buffs.add("mushi_buyume", 40.0, {"jutsu": 1.25, "_name": "Büyümüş Kikaichū", "_desc": "böcek teknikleri güçlü"})
			Hud.msg("Koza açıldı: kikaichū kolonin doldu ve böceklerin güçlendi.", Color(0.75, 0.85, 0.6))
		elif c.has_method("add_buff"):
			c.add_buff("mushi_buyume", 40.0, {"jutsu": 1.25}))


# ================================================================== İNUZUKA — ninken ile çift hücum
## Gatsūga: matkap hücumu bitince sekip geri döner ve ikinci kez çarpar
func c_gatsuga(c: Node3D, t: Node3D) -> void:
	Jutsu.j_gatsuga(c, t)   # çapraz geçişler j_gatsuga içinde


## Tsūga: küçük matkap; ilk çarptığından en yakın sonraki düşmana seker (en fazla 3)
func c_tsuga(c: Node3D, t: Node3D) -> void:
	var chain = []
	var tt = tg(c, t, 14.0)
	var drill = Jutsu.gatsuga_drill(0.75)
	c.add_child(drill)
	drill.top_level = true
	drill.scale = Vector3(0.5, 0.5, 0.95)   # Tsūga: Gatsūga'dan ince, uzun tek matkap
	# matkap bedenin yerinde, gidiş yönüne bakar (gövde düğümü dönmez; yön hızdan/hedeften)
	var follow = drill.create_tween().set_loops()
	follow.tween_callback(func():
		if not is_instance_valid(c):
			return
		drill.global_position = c.global_position + Vector3.UP * 1.0
		var v: Vector3 = c.velocity if "velocity" in c else Vector3.ZERO
		v.y = 0
		if v.length() < 1.0:
			v = c.face_dir()
		drill.look_at(drill.global_position + v.normalized(), Vector3.UP))
	follow.tween_interval(0.016)
	var st = {"done": false}
	var reveal = func():
		st["done"] = true
		if is_instance_valid(drill):
			drill.queue_free()
		if is_instance_valid(c) and c.get("model"):
			c.model.visible = true
	# emniyet: kombo kesilse de (tween öldürülse de) beden en geç 2 sn sonra görünür
	c.get_tree().create_timer(2.0).timeout.connect(reveal)
	var step = func(next_t):
		Jutsu._dash(c, next_t, 0.45, 26.0, func(pt):
			if not st["done"]:
				c.model.visible = false   # kanon: beden matkabın içinde görünmez (kendi etrafında topaç gibi dönmez)
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
			step.call(nxt), reveal)
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
		Buffs.add("shikyaku", 20.0, {"speed": 1.18, "melee": 1.18})
	FX.aura(c, Color(0.95, 0.35, 0.2), 1.0, Vector3(0, 0.9, 0), 20.0)
	finger_claws(c, 20.0)
	Sfx.play("roar", c.global_position, 1.6, 0.6)


## Kanon (Shikyaku no Jutsu): tırnaklar parmak uçlarından pençe gibi uzar. Her parmağın uç kemiğine bağlı,
## parmağın baktığı yöne (orta boğum -> uç) dönük kısa kıvrık pençe; her karede kemikle birlikte hareket eder.
func finger_claws(c: Node3D, dur: float) -> void:
	var m = c.get("model")
	if m == null or not is_instance_valid(m) or m.get("skel") == null:
		return
	var sk: Skeleton3D = m.skel
	var b = MB.new()
	Loft.tube(b, [Vector3(0, 0, 0), Vector3(0, -0.006, -0.035), Vector3(0, -0.018, -0.065)], [0.011, 0.007, 0.001], Color(0.93, 0.9, 0.82), 6, 2)
	var mesh = b.build(Props.toon())
	var pairs = []
	for side in ["Left", "Right"]:
		for f in ["Index", "Middle", "Ring", "Little", "Thumb"]:
			var a = sk.find_bone(side + f + ("Proximal" if f == "Thumb" else "Intermediate"))
			var d = sk.find_bone(side + f + "Distal")
			if a < 0 or d < 0:
				continue
			var mi = MeshInstance3D.new()
			mi.mesh = mesh
			mi.top_level = true
			c.add_child(mi)
			pairs.append([mi, a, d])
	if pairs.is_empty():
		return
	var tw = c.create_tween()
	tw.tween_method(func(_u: float):
		if not is_instance_valid(sk):
			return
		for pr in pairs:
			var mi: MeshInstance3D = pr[0]
			if not is_instance_valid(mi):
				continue
			mi.visible = m.visible
			var pa: Vector3 = (sk.global_transform * sk.get_bone_global_pose(pr[1])).origin
			var pd: Vector3 = (sk.global_transform * sk.get_bone_global_pose(pr[2])).origin
			var dv = pd - pa
			if dv.length() < 0.0001:
				continue
			var tip = pd + dv.normalized() * dv.length() * 0.9   # uç kemiğin ucu (uç boğum ~ orta boğum boyu)
			var up = Vector3.UP if absf(dv.normalized().y) < 0.95 else Vector3.FORWARD
			mi.global_transform = Transform3D(Basis.looking_at(dv.normalized(), up), tip), 0.0, 1.0, dur)
	tw.tween_callback(func():
		for pr in pairs:
			if is_instance_valid(pr[0]):
				pr[0].queue_free())


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


## Dainamikku Mākingu (kanon): ninken havada dönerek hedefe işer — koku izi 60 sn; Inuzuka onu nereye giderse bulur (Garōga güdümü).
func c_dainamikku_makingu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	if tt == null:
		return
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(0.4, 0.4, 0.4), Color.WHITE, Vector3.ZERO, 8)
	shot(c, Jutsu._hand(c), (tt.global_position + Vector3.UP - Jutsu._hand(c)).normalized(), 30.0, mesh_of(b, glow(Color(0.95, 0.85, 0.3))), {"dmg": 1.0, "knock": 0.0}, tt, false, 1.5, func(_p, target):
		if live(target):
			target.set_meta("inu_scent", Time.get_ticks_msec() / 1000.0 + 60.0)   # kanon: koku izi — Garōga onu dönerken bile bulur
			var tag = MeshInstance3D.new()
			tag.mesh = VFX._sphere(0.3, 10, 6)
			tag.material_override = glow(Color(0.95, 0.8, 0.25))
			attach(target, tag, 20.0, Vector3.UP * (target.height + 0.7))
			Combat.popup_text(target.global_position + Vector3.UP * 2.4, "İşaretlendi!", Color(1, 0.85, 0.3)))
	for n in get_tree().get_nodes_in_group("ninken"):
		n.tgt = tt


# ================================================================== KAGUYA — kemik dansları (Shikotsumyaku; çelikten sert kemik = yetenek, PlayerModes/Enemy)
func _bone_blade(c: Node3D, len_: float, dur: float) -> Node3D:
	var b = MB.new()
	# referans (Tsubaki karesi): kolundan çektiği ince, uzun, beyaz kemik kılıç
	b.add_grad("cone", Vector3(0, 0, -len_ * 0.5), Vector3(0.07, len_, 0.06), Color(0.99, 0.98, 0.95), Color(0.88, 0.86, 0.8), Vector3(-90, 0, 0), 8)
	b.add("sphere", Vector3.ZERO, Vector3(0.1, 0.1, 0.1), Color(0.97, 0.95, 0.9), Vector3.ZERO, 8)
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
	# referans (Hana karesi): koldan öne uzanan dev, sivri, sarmal kemik katmanlı matkap
	var b = MB.new()
	b.add_grad("cone", Vector3(0, 0, -1.4), Vector3(0.9, 2.8, 0.9), Color(0.99, 0.98, 0.95), Color(0.86, 0.84, 0.78), Vector3(-90, 0, 0), 14)
	for sp in 5:   # sarmal sırtlar (katmanlar)
		var pts = []
		var rad = []
		for k in 16:
			var u = k / 15.0
			var a = sp * TAU / 5.0 + u * TAU * 1.3
			var r = 0.48 * (1.0 - u) + 0.02
			pts.append(Vector3(cos(a) * r, sin(a) * r, -u * 2.75))
			rad.append(Vector2(0.09, 0.05) * (1.0 - u * 0.8))
		Loft.tube(b, pts, rad, Color(0.97, 0.96, 0.92), 6, 2, true, true)
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
			# kanon: Hana, Tsuru ile bağlanmış hedefe vurulmak içindir — bağlıya tam güç, serbeste yarı
			var bound_mul = 1.0
			for e2 in enemies_near(c, pt + c.face_dir() * 1.5, 1.8):
				if e2.has_method("has_status") and e2.has_status("bind"):
					bound_mul = 1.6
			for h in hit(c, pt + c.face_dir() * 1.5, 1.8, inf(c, "tessenka_no_mai_hana", 1.7 * bound_mul, {"knock": 16.0, "launch": 3.0, "kind": "heavy", "pierce_guard": true, "hitstop": 0.1}), hits):
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


## Karamatsu no Mai (kanon, Kimimaro): yakın dövüşle vurulmak üzereyken bedenin her yerinden sivri kemikler çıkar —
## saldıran kendini kemiklere saplar; saldırı ne kadar güçlü/hızlıysa kendine o kadar zarar verir (Combat.larch_counter).
## 5 sn açık kalır; jutsu ve uzak saldırıya karşı işe yaramaz (zayıf nokta). Oyuncu ve düşman aynı kural.
func c_karamatsu_no_mai(c: Node3D, _t: Node3D) -> void:
	var b = MB.new()
	for k in 30:
		var dir = Vector3(randf_range(-1, 1), randf_range(-0.3, 1), randf_range(-1, 1)).normalized()
		var bs = Basis(Quaternion(Vector3.UP, dir))
		b.add_xf("cone", Transform3D(bs * Basis.from_scale(Vector3(0.1, 0.65, 0.1)), dir * 0.42 + Vector3.UP * randf_range(0.3, 1.5)), Color(0.97, 0.95, 0.88))
	var spikes = mesh_of(b)
	attach(c, spikes, 5.0, Vector3.ZERO)
	Buffs.add("karamatsu", 5.0, {"_name": "Karamatsu no Mai", "_desc": "yakın dövüşle vuran kemiklere saplanır"})
	Sfx.play("hit_heavy", c.global_position, 1.1)


## Eğrelti Dansı: hedef bölgede merkezden dışa dev kemik ormanı yükselir: deler, mıhlar, 10 sn duvar gibi kalır
func c_sawarabi_no_mai(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 10.0, 25.0))
	VFX.cracks(center, 12.0)
	busy(c, 0.8)
	var n = 120
	for k in n:
		var ring = sqrt(float(k) / n)
		var a = k * 2.4
		var p = center + Vector3(cos(a), 0, sin(a)) * ring * 18.0
		after(ring * 0.8, func():
			# referans (Sawarabi karesi): çok sık, ince, sivri, ak-mavimsi kemik bıçaklar
			var h = randf_range(3.5, 9.0) * (1.25 - ring * 0.4)
			spike(p, h, randf_range(0.22, 0.42), Color(0.93, 0.96, 1.0), 10.0, Vector3(randf_range(-18, 18), 0, randf_range(-18, 18)), true)
			for e in enemies_near(c, p, 1.6):
				hit(c, e.global_position + Vector3.UP, 1.2, inf(c, "sawarabi_no_mai", 0.7, {"knock": 2.0, "launch": 6.0, "kind": "heavy"}))
				st(e, "bind", 2.0)
			pass)
	after(0.2, func():
		shake(1.0)
		Sfx.play("earth", center, 0.6))
	# kanon: lanet mührü II'deyken Kimimaro kemik ormanıyla birleşir, hedefin kör noktasındaki kemikten çıkıp bitirir
	var j2 = Buffs.has("juin2") if c is Player else (c.get("buffs") != null and c.buffs.has("juin2"))
	var tt = tg(c, t, 30.0)
	if j2 and tt:
		after(1.3, func():
			if not (live(c) and live(tt)):
				return
			var back = -tt.face_dir() if tt.has_method("face_dir") else Vector3.BACK
			VFX.debris(c.global_position + Vector3.UP, Color(0.97, 0.95, 0.88), 10, 6.0, 0.3)
			c.global_position = gp(tt.global_position + back * 1.4)
			spike(c.global_position, 3.0, 0.9, Color(0.97, 0.95, 0.88), 1.0, Vector3.ZERO, true)
			if c is Player:
				c.combat.face_to(tt)
			anim(c, "cross", 2.0)
			Combat.popup_text(tt.global_position + Vector3.UP * 2.5, "Kemikten çıktı!", Color(0.97, 0.95, 0.88))
			hit(c, tt.global_position + Vector3.UP, 1.3, inf(c, "sawarabi_no_mai", 1.4, {"knock": 14.0, "launch": 3.0, "kind": "heavy", "pierce_guard": true})))


# ================================================================== UZUMAKI — mühürler ve zincirler
## Sıkı Bağlayan Altın Zincir: dört altın zincir yerden çıkıp hedefe kenetlenir, onu yere çeker
func c_kinbaku_kingusari_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 22.0)
	if tt == null:
		return
	# referans (Kinbaku karesi, Karin): chakra zincirleri doğrudan kullanıcının bedeninden (göğüs/sırt) fışkırıp hedefe saplanır
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	var cm = Jutsu._chain_mat()
	var fdv = c.face_dir() if c.has_method("face_dir") else Vector3.FORWARD
	var sdv = fdv.cross(Vector3.UP)
	for k in 4:
		var from = c.global_position + Vector3.UP * (1.0 + (k % 2) * 0.35) + sdv * (-0.25 + (k / 2) * 0.5) + fdv * 0.15
		Jutsu._chain_line(root, from, tt.global_position + Vector3.UP * (0.8 + k * 0.2) + sdv * ((k - 1.5) * 0.15), -0.4 + k * 0.25, 0.2, cm, true)
	get_tree().create_timer(4.0).timeout.connect(func(): if is_instance_valid(root): root.queue_free())
	st(tt, "bind", 4.0)
	st(tt, "stun", 1.0)
	every(4.0, 0.5, func(_i, _k):
		if live(tt):
			hit(c, tt.global_position + Vector3.UP, 0.8, inf(c, "kinbaku_kingusari_no_jutsu", 0.18, {"knock": 0.0, "launch": 0.0, "kind": "light"})))   # bağlanan ayakta kalır
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


## Fūka Hōin (kanon): önceden yazılmış, ortası boş parşömen açılır — yakındaki ATEŞ (katon/yoton, Amaterasu dahil) ortadaki
## boşluğa emilip mühürlenir, yerine "火" belirir. Ateş olmayan saldırıya etkisiz (zayıf nokta). Emilen ateş geri salınır.
func c_fuka_hoin(c: Node3D, t: Node3D) -> void:
	var fd = c.face_dir() if c.has_method("face_dir") else Vector3.FORWARD
	var scroll = Node3D.new()
	get_tree().current_scene.add_child(scroll)
	scroll.global_position = c.global_position + Vector3.UP * 1.25 + fd * 0.65
	scroll.look_at(scroll.global_position + fd, Vector3.UP)
	var paper = MeshInstance3D.new()
	var qm = QuadMesh.new()
	qm.size = Vector2(1.5, 0.42)
	paper.mesh = qm
	var pm = StandardMaterial3D.new()
	pm.albedo_color = Color(0.97, 0.95, 0.88)
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED   # referans: ak kâğıt (ışıklı malzemede arka yüz kapkara görünüyordu)
	pm.cull_mode = BaseMaterial3D.CULL_DISABLED
	paper.material_override = pm
	scroll.add_child(paper)
	paper.rotation.y = PI
	for sx in [-1.0, 1.0]:   # iki uçta rulolar
		var rl = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.045; cm.bottom_radius = 0.045; cm.height = 0.5
		rl.mesh = cm
		rl.material_override = pm
		scroll.add_child(rl)
		rl.position = Vector3(sx * 0.77, 0, 0)
	for k in 8:   # kenarlarda yazı sütunları, ortası boş
		var lb = Label3D.new()
		lb.text = ["封", "印", "火", "禁", "吸", "法", "式", "結"][k]
		lb.font_size = 48
		lb.pixel_size = 0.0035
		lb.modulate = Color(0.05, 0.04, 0.04)
		lb.position = Vector3((-0.62 + (k % 4) * 0.1) * (1.0 if k < 4 else -1.0), 0, -0.01)
		scroll.add_child(lb)
	scroll.scale = Vector3(0.05, 1, 1)
	scroll.create_tween().tween_property(scroll, "scale", Vector3.ONE, 0.2)
	var store = {"fire": 0}
	busy(c, 3.0)
	every(3.0, 1.0 / 20.0, func(_i, _k):
		if not is_instance_valid(scroll):
			return
		for n in get_tree().current_scene.get_children():
			if n is Projectile and not n.dead and n.shooter != c and Combat.hostile(c, n.shooter) and String(n.info.get("element", "")) in ["katon", "yoton", "enton"]:
				var v = scroll.global_position - n.global_position
				if v.length() < 1.0:
					store["fire"] += 1
					VFX.embers(scroll.global_position, Color(1, 0.6, 0.2), 10, 3.0, 0.3)
					n.queue_free()
				elif v.length() < 14.0:
					n.vel = v.normalized() * maxf(n.vel.length(), 18.0)   # ateş parşömene çekilir
		# Amaterasu dahil: yakındaki yanan hedefin/yerin ateşi de çekilir
		for e in get_tree().get_nodes_in_group("fighters"):
			if e != c and e.has_method("has_status") and e.has_status("burn") and e.global_position.distance_to(c.global_position) < 8.0:
				e.statuses.erase("burn")
				store["fire"] += 1, func():
		if is_instance_valid(scroll) and store["fire"] > 0:
			var mark = Label3D.new()
			mark.text = "火"
			mark.font_size = 140
			mark.pixel_size = 0.004
			mark.modulate = Color(0.1, 0.05, 0.03)
			scroll.add_child(mark)
			mark.position = Vector3(0, 0, -0.012)
			Combat.popup_text(scroll.global_position + Vector3.UP * 0.6, "Ateş mühürlendi", Color(1, 0.8, 0.5))
			Jutsu._stream(c, t, 1.0 + store["fire"] * 0.3, Color(1.0, 0.55, 0.15), "katon", 4.0 * mult(c) * store["fire"], "fire")
		if is_instance_valid(scroll):
			fade_free(scroll, 0.6, 0.3))
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


## Fūja Hōin (kanon, Kakashi -> Sasuke): lanet mührünün çevresine kanla yazılmış mühür formülü çizilir, mührün gücü bastırılır.
## Yalnız lanet mührüne işler (genel arınma değil): kendi ya da yakındaki dostun Lanetli Mühür I/II'si söner, 60 sn yeniden açılamaz.
func c_fuja_hoin(c: Node3D, _t: Node3D) -> void:
	var had = Buffs.has("juin1") or Buffs.has("juin2") if c is Player else (c.get("buffs") != null and (c.buffs.has("juin1") or c.buffs.has("juin2")))
	if not had:
		if c is Player:
			Hud.msg("Fūja Hōin yalnız lanet mührünü bastırır — üstünde etkin bir lanet mührü yok.", Color(0.9, 0.6, 0.6))
		return
	if c is Player:
		Buffs.remove("juin1")
		Buffs.remove("juin2")
	else:
		c.buffs.erase("juin1")
		c.buffs.erase("juin2")
	c.set_meta("fuja_until", Time.get_ticks_msec() + 60000)
	# (bedendeki parlak halka kaldırıldı: ortak parlama malzemesi kırmızıyı beyaza patlatıyordu; formül yerde, kan kırmızısı)
	Combat.popup_text(c.global_position + Vector3.UP * 2.4, "Lanet mührü bastırıldı", Color(0.85, 0.3, 0.3))
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
	# kanon: bedendeki su kola pompalanır, kol kasları anında şişer; şişen kolla yıkıcı yumruk. 10 sn kol iri kalır.
	var m = c.get("model")
	var ov = m.overlay if m and m.get("overlay") else null
	if c is Player:
		Buffs.add("gosuiwan", 10.0, {"melee": 1.3, "reach": 1.3, "_name": "Gōsuiwan", "_desc": "su pompalanmış kaslı kol"})
	elif c.has_method("add_buff"):
		c.add_buff("gosuiwan", 10.0, {"melee": 1.3})
	if ov:
		var tw = c.create_tween()
		tw.tween_method(func(x: float): if is_instance_valid(m): m.overlay.bulk["RightUpperArm"] = x, 1.0, 2.6, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(9.4)
		tw.tween_method(func(x: float): if is_instance_valid(m): m.overlay.bulk["RightUpperArm"] = x, 2.6, 1.0, 0.3)
		tw.tween_callback(func(): if is_instance_valid(m): m.overlay.bulk.erase("RightUpperArm"))
	# bedenden kola akan su damlaları (nem toplanıyor)
	for k in 10:
		var q = Vector3(randf_range(-0.35, 0.35), randf_range(0.3, 1.5), randf_range(-0.3, 0.3))
		after(k * 0.02, func():
			if live(c):
				var to = Jutsu._hand(c) + Vector3.UP * 0.25
				WindFX.streak(func(u: float) -> Vector3: return (c.global_position + q).lerp(to, u), 0.25, 0.05, Color(0.6, 0.85, 1.0), 0.0, 8))
	busy(c, 0.55)
	anim(c, "crouch", 2.0)
	after(0.3, func():
		if not live(c):
			return
		anim(c, "cross", 1.5)
		var d = fwd(c, t)
		var p = c.global_position + Vector3.UP * 1.1 + d * 1.6
		VFX.shockwave(p, Color(0.9, 0.92, 0.95), 4.0, 0.25, false, d)   # referans: su değil, kaslı yumruğun darbesi
		hit(c, p, 1.8, inf(c, "suiton_gosuiwan_no_jutsu", 1.8, {"knock": 18.0, "launch": 3.0, "kind": "heavy", "hitstop": 0.1}))
		Sfx.play("punch", p, 0.7))


## Su girdabı dokusu (Tate Eboshi yüzeyi): saydam zemin üzerinde ak, uçları kıvrılan "ε" biçimli su çizgileri — döşenebilir
static var _swirl: ImageTexture = null
static func _swirl_tex() -> ImageTexture:
	if _swirl:
		return _swirl
	var N = 128
	var img = Image.create(N, N, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var col = Color(1, 1, 1, 0.85)
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	var stamp = func(x: float, y: float, r: float):
		for yy in range(int(y - r) - 1, int(y + r) + 2):
			for xx in range(int(x - r) - 1, int(x + r) + 2):
				if Vector2(xx - x, yy - y).length() <= r:
					img.set_pixel(posmod(xx, N), posmod(yy, N), col)
	for k in 5:
		var cx = rng.randf_range(0, N)
		var cy = rng.randf_range(0, N)
		var R = rng.randf_range(9.0, 15.0)
		var dirs = 1.0 if rng.randf() < 0.5 else -1.0
		# iç içe açılan sarmal (girdap) + dışa uzanan kuyruk
		for i in 90:
			var u = i / 89.0
			var a = dirs * u * TAU * 1.4
			var rr = R * (0.15 + u)
			stamp.call(cx + cos(a) * rr, cy + sin(a) * rr * 0.8, 1.6 * (1.0 - u * 0.4))
		for i in 30:
			var u = i / 29.0
			stamp.call(cx + dirs * (R * 1.15 + u * 14.0), cy + R * 0.3 + sin(u * PI) * 6.0, 1.4 * (1.0 - u * 0.7))
	img.generate_mipmaps()
	_swirl = ImageTexture.create_from_image(img)
	return _swirl


## Suiton: Tate Eboshi (kanon, Suigetsu): Hōzuki bir su kaynağıyla birleşir, dev bir dalga (şeytan balığı gibi) kaldırır:
## 6 sn önündeki mermileri yutar, yaklaşanı geri iter, dostları korur. Su kaynağı yoksa yapılamaz (oyuncu: ClanMech; AI: burada).
func c_suiton_tate_eboshi(c: Node3D, t: Node3D) -> void:
	if not (c is Player) and not ClanMech.water_near(c.global_position):
		return
	var d = fwd(c, t)
	d.y = 0.0
	d = d.normalized()
	# referans (Suigetsu vs Hachibi): yerden kalkan dev, yarı saydam soluk su kütlesi — tepede uzun sırt dikeni, kenar
	# boyunca dışa bakan dikenler (kirpi balığı gibi), yüzeyde ak girdaplar; kullanıcı kütlenin içinde, arkadakiler korunur
	var W = 8.5   # referans: en ≈ boy, insanın ~5 katı (Hachibi'yi geri itecek kadar dev)
	var H = 9.0
	var D = 6.0
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = gp(c.global_position + d * 2.0)
	root.look_at(root.global_position + d, Vector3.UP)
	var wm = VFX.mat_water(Color(0.3, 0.55, 0.8), Color(0.62, 0.8, 0.94), Color(0.96, 0.99, 1.0), Vector3.UP, 0.66, 1.0, 0.1)
	var body = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 1.0
	sm.height = 1.0   # bu sürümde yarım kürenin boyu doğrudan height (2.0 kütleyi iki kat uzatıyordu)
	sm.is_hemisphere = true
	sm.radial_segments = 40
	sm.rings = 18
	body.mesh = sm
	body.material_override = wm
	body.scale = Vector3(W, H, D)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# yüzeyde ak girdaplar (referanstaki kıvrık su çizgileri): koddan çizilmiş döşenen doku, ikinci katman
	var sw = StandardMaterial3D.new()
	sw.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sw.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sw.albedo_texture = _swirl_tex()
	sw.uv1_scale = Vector3(11.0, 5.0, 1.0)
	sw.cull_mode = BaseMaterial3D.CULL_BACK
	sw.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	body.material_overlay = sw
	var uvt = body.create_tween().set_loops()   # girdaplar yavaşça yukarı akar
	uvt.tween_property(sw, "uv1_offset", Vector3(0.0, -1.0, 0.0), 4.0).from(Vector3.ZERO)
	root.add_child(body)
	# dikenler gökyüzüne karşı seçilsin: daha koyu, doygun mavi (soluk ak dikenler açık gökte kayboluyordu)
	var spm = VFX.mat_water(Color(0.12, 0.38, 0.72), Color(0.35, 0.62, 0.9), Color(0.85, 0.94, 1.0), Vector3.UP, 0.92, 0.5, 0.0)
	var spike = func(pos: Vector3, dir: Vector3, ln: float, rad: float):
		var cm = CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = rad
		cm.height = ln
		cm.radial_segments = 10
		var mi = MeshInstance3D.new()
		mi.mesh = cm
		mi.material_override = spm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		var up = dir.normalized()
		var side = up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		mi.transform = Transform3D(Basis(side, up, side.cross(up)), pos + up * ln * 0.45)
	# kenar dikenleri: ön düzlemdeki elips çevresi boyunca, dışa (elips normali) bakar; tepede en uzun sırt dikeni
	for k in 13:
		var ang = lerpf(-1.45, 1.45, k / 12.0)
		var pos = Vector3(sin(ang) * W, cos(ang) * H, -0.4)
		var nrm = Vector3(sin(ang) / W, cos(ang) / H, 0.0).normalized()
		var top = k == 6
		spike.call(pos * 0.95, (nrm + Vector3(0, 0.2, 0)).normalized() if not top else Vector3.UP, 5.0 if top else randf_range(2.0, 3.0), 0.85 if top else 0.55)
	# ön yüzeyde birkaç kısa diken
	for k in 5:
		var ang2 = randf_range(-0.9, 0.9)
		var el = randf_range(0.3, 0.75)
		var q = Vector3(sin(ang2) * W * 0.8, el * H, -D * 0.7)
		spike.call(q, (Vector3(sin(ang2) * 0.4, 0.5, -1.0)).normalized(), randf_range(1.0, 1.6), 0.3)
	# yükseliş: sudan kabarır
	root.scale = Vector3(0.6, 0.05, 0.6)
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var bt = body.create_tween().set_loops()
	bt.tween_property(body, "scale", Vector3(W * 1.02, H * 0.98, D * 1.03), 0.5).set_trans(Tween.TRANS_SINE)
	bt.tween_property(body, "scale", Vector3(W, H, D), 0.5).set_trans(Tween.TRANS_SINE)
	VFX.splash(root.global_position + Vector3.UP * 0.5, 4.0)
	WaterArt.drops(root.global_position + Vector3.UP * 4.0, 18, 2.4, 10.0)
	shake(0.5)
	var center = root.global_position + Vector3.UP * H * 0.4
	every(6.0, 0.1, func(_i, _k):
		if not is_instance_valid(root):
			return
		# kütleye giren düşman mermisi yutulur
		for n in get_tree().current_scene.get_children():
			if n is Projectile and not n.dead and Combat.hostile(c, n.shooter):
				var v2 = n.global_position - root.global_position
				var lx = v2.dot(root.global_basis.x) / W
				var ly = v2.dot(Vector3.UP) / H
				var lz = v2.dot(-root.global_basis.z) / (D + 1.5)
				if ly > -0.1 and lx * lx + ly * ly + lz * lz < 1.1:
					VFX.splash(n.global_position, 1.0)
					n.queue_free()
		# kütleye dayanan düşman dışarı itilir
		for e in enemies_near(c, root.global_position + d * 1.5, W + 0.5):
			var v = e.global_position - root.global_position
			v.y = 0
			if v.dot(d) > -0.5:
				e.global_position = gp(e.global_position + (d * 0.6 + v.normalized() * 0.2)))
	# çöküş: kütle yere boşalır, ıslak zemin bırakır (raitonla elektriklenebilir)
	after(6.0, func():
		if not is_instance_valid(root):
			return
		var tw2 = root.create_tween()
		tw2.tween_property(root, "scale", Vector3(1.25, 0.02, 1.25), 0.35).set_ease(Tween.EASE_IN)
		tw2.tween_callback(root.queue_free)
		VFX.splash(center, 4.5)
		WaterArt.drops(center, 20, 2.6, 8.0)
		GroundFX.add(root.global_position + d * 1.5, "wet", W + 1.0, 10.0, c))
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
		Buffs.add("hien", 10.0, {"reach": 1.8, "melee": 1.15})
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
	# kanon: kılıç savrulunca ardında beyaz chakra izi (Konoha'nın Beyaz Dişi) — hat boyunca ince parlak iz + savrulan yay
	tether(func(): return start + Vector3.UP * 1.1, func(): return end + Vector3.UP * 1.1, 0.07, glow(Color(1, 1, 1)), 0.45)
	_slash_arc(end + Vector3.UP * 1.1, d, -20.0, Color(1, 1, 1), 2.6)
	FX.light(end + Vector3.UP, Color(0.95, 0.97, 1.0), 6.0, 8.0, 0.25)
	VFX.star(end + Vector3.UP * 1.1, Color(1, 1, 1), 3.0, 0.2)
	Sfx.play("whoosh", end, 1.6)


## Ninken Sürüsü (İz Süren Diş): ninkenler hedefin altından fışkırıp onu ısırarak yere çiviler
func c_hatake_ninken(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 30.0)
	if tt == null:
		Hud.msg("Ninken sürüsü: önce bir hedef seç", Color(0.9, 0.8, 0.6))
		return
	busy(c, 0.6)
	# kanon: başparmaktan kan, parşömen yere açılır, çağırma formülü — köpekler yeraltından kokuyu izler
	if has_method("summon_circle"):
		call("summon_circle", gp(c.global_position + c.face_dir() * 0.9), 2.2, Color(0.6, 0.45, 0.3), 1.0)
	if tt.has_meta("hidden") or tt.has_meta("invisible"):
		tt.remove_meta("hidden")
	VFX.cracks(tt.global_position, 3.0)
	# anime (Zabuza yakalanışı): sekiz ninken (biri küçük Pakkun) hedefin altından fışkırır, bacaklarına, beline, kollarına
	# farklı yüksekliklerde kenetlenip ısırır. Köpekler ortak çağrı modeli (SummonModels dog_pack: alın bandı/yelekli sürü köpeği)
	var th = float(tt.get("height")) if tt.get("height") != null else 1.8
	var bites = [[0.0, 0.15], [1.6, 0.2], [3.2, 0.55], [4.7, 0.6], [0.8, 1.0], [2.4, 1.05], [3.9, 1.2], [5.5, 0.3]]
	for k in 8:
		var md = SummonModels.build("dog_small" if k == 0 else "dog_pack", 0.45 if k == 0 else 0.66, 1.0)
		var dog: Node3D = md["root"]
		get_tree().current_scene.add_child(dog)
		var a = float(bites[k][0])
		var hy = float(bites[k][1]) * th * 0.6
		var p = gp(tt.global_position) + Vector3(cos(a), 0, sin(a)) * (tt.radius + 0.42)
		dog.global_position = p - Vector3.UP * 1.2
		dog.look_at(Vector3(tt.global_position.x, p.y + hy, tt.global_position.z), Vector3.UP)
		dog.rotate_object_local(Vector3.RIGHT, -0.35 if hy > 0.5 else 0.0)   # üstten ısıranlar hafif yukarı
		var tw = dog.create_tween()
		tw.tween_interval(0.05 + k * 0.035)
		tw.tween_callback(func(): FX.dust(p, 0.5))
		tw.tween_property(dog, "global_position", p + Vector3.UP * hy, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		for q in 6:   # ısırırken silkelenir
			tw.tween_property(dog, "rotation:z", 0.18 * (1 if q % 2 == 0 else -1), 0.12)
		tw.tween_property(dog, "rotation:z", 0.0, 0.1)
		tw.tween_interval(1.3)
		tw.tween_callback(func(): FX.smoke_puff(dog.global_position + Vector3.UP * 0.3, 0.5, 8))
		tw.tween_callback(dog.queue_free)
	FX.dust(tt.global_position, 1.6)
	st(tt, "bind", 3.0)
	every(3.0, 0.4, func(_i, _k):
		if live(tt):
			hit(c, tt.global_position + Vector3.UP * 0.8, 0.9, inf(c, "hatake_ninken", 0.15, {"knock": 0.0, "launch": 0.0, "kind": "crush"}))   # ısırma tiki: bağlı hedef devrilmez
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
	var shark = SharkArt.shark(3.2)   # referans: tek, dev, çenesi açık SU köpekbalığı (ortak su malzemesi)
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
	var inner = MeshInstance3D.new()
	inner.mesh = VFX._sphere(0.5, 32, 16)
	var im = StandardMaterial3D.new()
	im.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	im.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	im.cull_mode = BaseMaterial3D.CULL_FRONT
	im.albedo_color = Color(0.08, 0.38, 0.75, 0.5)
	inner.material_override = im
	inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dome.add_child(inner)
	inner.scale = Vector3.ONE * 0.98
	VFX.slowmo(0.4, 0.6)
	VFX.cinematic(c, 14.0, 7.0)
	busy(c, 0.9)
	FX.burst(center + Vector3.UP * 4.0, {"amount": 160, "life": 8.0, "size": 0.35, "vmin": 0.3, "vmax": 1.2, "gravity": Vector3(0, 1.2, 0),
		"colors": [Color(0.85, 0.95, 1.0, 0.0), Color(0.85, 0.95, 1.0, 0.8), Color(0.85, 0.95, 1.0, 0)]})   # kabarcıklar
	var sharks = []
	for k in 16:
		var s = JutsuEngine.shape_mesh("shark", Color(0.3, 0.6, 1.0), 1.2, "suiton")
		get_tree().current_scene.add_child(s)
		s.global_position = center + Vector3(randf_range(-3, 3), randf_range(1.0, 4.0), randf_range(-3, 3))
		sharks.append({"n": s, "r": randf_range(6.0, R - 3.0), "h": randf_range(2.0, R * 0.9), "ph": randf() * TAU, "sp": randf_range(0.6, 1.1) * (1.0 if k % 2 == 0 else -1.0), "atk": -1.0, "tg": null})
	if c is Player:
		Buffs.add("sameodori", 8.0, {"speed": 1.4})
	var bite_cd = {"t": 0.0}
	every(8.0, 1.0 / 30.0, func(i, _k):
		bite_cd["t"] -= 1.0 / 30.0
		var inside = enemies_near(c, center, R)
		# su altı: oyuncu kubbenin içindeyken ekran mavi-yeşil tonlanır, etrafında kabarcıklar yükselir, yukarıdan ışık hüzmeleri iner
		var pl = Game.player
		if pl and is_instance_valid(pl) and Game.world:
			if pl.global_position.distance_to(center) < R * 0.95:
				Game.world.env.set_tint(Color(0.0, 0.28, 0.55, 0.62))
				if i % 2 == 0:
					FX.burst(pl.global_position + Vector3(randf_range(-3, 3), randf_range(0.0, 2.5), randf_range(-3, 3)), {"amount": 3, "life": 1.6, "tex": FX.tex_soft, "add": true, "cel": false,
						"size": 0.12, "radius": 0.5, "vmin": 0.6, "vmax": 1.6, "dir": Vector3.UP, "spread": 15.0, "gravity": Vector3(0, 1.0, 0),
						"colors": [Color(0.9, 0.97, 1.0, 0.0), Color(0.9, 0.97, 1.0, 0.85), Color(0.9, 0.97, 1.0, 0.0)]})
				if i % 6 == 0:
					var sp = pl.global_position + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
					FX.burst(sp + Vector3.UP * 10.0, {"amount": 1, "life": 1.2, "tex": FX.tex_spark, "add": true, "cel": false, "size": 9.0, "vmin": 0.0, "vmax": 0.1,
						"dir": Vector3.DOWN, "spread": 1.0, "colors": [Color(0.6, 0.9, 1.0, 0.0), Color(0.6, 0.9, 1.0, 0.25), Color(0.6, 0.9, 1.0, 0.0)]})
			else:
				Game.world.env.set_tint(Color(0, 0, 0, 0))
		for s in sharks:
			var n: Node3D = s["n"]
			if s["atk"] >= 0.0 and live(s["tg"]):
				# saldırı: hedefe dalar, ısırır, geri çekilir
				s["atk"] += 1.0 / 30.0
				var goal = s["tg"].global_position + Vector3.UP
				var p = n.global_position.lerp(goal, 0.22)
				if n.global_position.distance_to(goal) > 0.05:
					n.look_at(goal, Vector3.UP)
				n.global_position = p
				if p.distance_to(goal) < 1.2 or s["atk"] > 0.8:
					hit(c, goal, 1.2, inf(c, "suiro_sameodori_no_jutsu", 0.3, {"knock": 4.0, "kind": "heavy", "element": "suiton"}))
					VFX.splash(goal, 1.2)
					s["atk"] = -1.0
					s["tg"] = null
				continue
			s["ph"] += 0.035 * s["sp"]
			# av sürüsü: en yakın düşmanın çevresinde 3-7 m yarıçapta dönerek yüzer (düşman yoksa kullanıcının çevresinde)
			var hub: Vector3 = center
			var near_e = null
			var bd = 1e9
			for e in inside:
				var dd = e.global_position.distance_to(n.global_position)
				if dd < bd:
					bd = dd
					near_e = e
			if near_e:
				hub = near_e.global_position
			elif live(c):
				hub = c.global_position
			var rr = 3.0 + fmod(s["r"], 4.0)
			var want = hub + Vector3(cos(s["ph"]) * rr, 1.2 + fmod(s["h"], 3.0) + sin(s["ph"] * 2.0) * 0.8, sin(s["ph"]) * rr)
			var p2 = n.global_position.lerp(want, 0.08)
			var mv = p2 - n.global_position
			if mv.length() > 0.01:
				n.look_at(p2 + mv, Vector3.UP)
			n.global_position = p2
		if bite_cd["t"] <= 0.0 and not inside.is_empty():
			bite_cd["t"] = 0.22
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
		if Game.world:
			Game.world.env.set_tint(Color(0, 0, 0, 0))
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
			# yere yayılan yapışkan bal-balmumu gölü (ak halka değil)
			var pool = MeshInstance3D.new()
			var pcm = CylinderMesh.new()
			pcm.top_radius = 2.2; pcm.bottom_radius = 2.4; pcm.height = 0.06; pcm.radial_segments = 24
			pool.mesh = pcm
			var pmat = StandardMaterial3D.new()
			pmat.albedo_color = Color(0.92, 0.66, 0.16)
			pmat.roughness = 0.15
			pmat.metallic = 0.1
			pool.material_override = pmat
			get_tree().current_scene.add_child(pool)
			pool.global_position = gp(pos) + Vector3.UP * 0.03
			fade_free(pool, 5.0, 0.4)
			every(5.0, 0.3, func(_i, _k):
				for e in enemies_near(c, pos, 2.4):
					st(e, "slow", 0.5)))
		pr.gravity = 6.0
	Sfx.play("water", c.global_position, 0.7)


func c_kamizuru_hachi(c: Node3D, _t: Node3D) -> void:
	FX.smoke_puff(c.global_position + Vector3.UP * 2, 1.4, 16)
	ClanConstruct.spawn(c, "bee", 3, Jutsu._jd("kamizuru_hachi"))
	Sfx.play("wind", c.global_position, 2.0, 0.6)


## Kamizuru arısı: dev arı çağrısının (ClanConstruct "bee") modeli, önbellekli; küçültülüp mermi olarak kullanılır
static var _kz_bee_mesh: ArrayMesh = null
func _kz_bee(sc: float) -> Node3D:
	if _kz_bee_mesh == null:
		var cc = ClanConstruct.new()
		cc.kind = "bee"
		_kz_bee_mesh = cc._build_mesh()
		cc.free()
	var root = Node3D.new()
	var mi = MeshInstance3D.new()
	mi.mesh = _kz_bee_mesh
	mi.material_override = Props.toon()
	mi.scale = Vector3.ONE * sc
	mi.rotation.y = PI   # burun uçuş yönüne
	root.add_child(mi)
	return root


## Arı İğnesi Yağmuru: sürüden on iki zehirli iğne kıvrılarak hedeflere uçar
func c_kamizuru_hari(c: Node3D, t: Node3D) -> void:
	var list = enemies_near(c, c.global_position, 28.0)
	var origin = c.global_position + Vector3.UP * 2.2
	FX.burst(origin, {"amount": 40, "life": 0.6, "size": 0.12, "vmin": 1, "vmax": 3, "colors": [Color(1, 0.85, 0.2), Color(0.15, 0.1, 0.05, 0)]})
	for k in 12:
		var target = list[k % list.size()] if not list.is_empty() else null
		var d = (Jutsu._aim(c, t) + Vector3(randf_range(-0.6, 0.6), randf_range(0.1, 0.6), randf_range(-0.6, 0.6))).normalized()
		var nd = _kz_bee(0.35)   # referans: iğne fırlatan arılar (dev arı çağrısıyla aynı model, küçük)
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
## Suna no Yoroi (Gaara): bedeni ince, çatlak bir kum katmanı kaplar (kabuk/küre değil; pozu izler); hasarı emer
func c_suna_no_yoroi(c: Node3D, _t: Node3D) -> void:
	var old = c.get_meta("sand_coat") if c.has_meta("sand_coat") else {}
	if not old.is_empty():
		SandCoat.remove(old, 0.1)
	var st = SandCoat.apply(c, 1.35, 0.35, 0.012, 1.6)
	if c is Player:
		Buffs.add("suna_no_yoroi", 20.0, {"armor": 0.75})
	elif c.has_method("add_buff"):
		c.add_buff("suna_no_yoroi", 20.0, {"armor": 0.75})   # AI eşitliği
	after(20.0, func():
		if is_instance_valid(c):
			SandCoat.remove(st, 0.6))
	VFX.puffs(c.global_position, {"amount": 30, "life": 0.7, "size": 0.8, "radius": 1.2, "vmin": 2, "vmax": 5, "dir": Vector3.UP, "spread": 30.0,
		"colors": [Color(0.92, 0.8, 0.58), Color(0.82, 0.68, 0.45, 0)]})
	Sfx.play("earth", c.global_position, 1.4)


## Kūsa Bōheki (Gaara): kum havaya kalkıp başının üstünde kalın, kenarları yırtık bir kalkan tabakası olarak yayılır
## (kubbe değil); 8 sn mermileri durdurur, yaklaşanı iter
func c_kusa_boheki(c: Node3D, _t: Node3D) -> void:
	var sheet = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(8.0, 8.0)
	pm.subdivide_width = 28
	pm.subdivide_depth = 28
	sheet.mesh = pm
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://shaders/vfx_sand_sheet.gdshader")
	mat.set_shader_parameter("spread", 0.0)
	sheet.material_override = mat
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	attach(c, sheet, 8.0, Vector3.UP * 3.2)
	var tw = sheet.create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("spread", v), 0.0, 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(7.0)
	tw.tween_method(func(v): mat.set_shader_parameter("spread", v), 1.0, 0.0, 0.5)
	var tt = [0.0]
	every(8.0, 0.1, func(_i, _k):
		tt[0] += 0.1
		mat.set_shader_parameter("t", tt[0])
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


## Kum Shurikeni (REFERANS: Gaara'nın kolları kumdan dev pençe-kollara dönüşür; kollar iki yana açılır, öne savrulunca
## kol kenarlarından uzun mekik kum bıçakları her yöne fırlar):
## 1) kum, karakterin GERÇEK kollarını sarar: üst kol / ön kol kemiklerine bağlı dev kum kolları (mavi damarlar, sırtta geriye
##    yatık dikenler, kalın bilek, geniş avuç, koyu uçlu beş pençe) — kollar iki yana açık (hazırlık pozu, sand_arms);
## 2) kollar öne savrulur (sand_swing pozu), kolların dış kenarı boyunca 16 mekik bıçak yelpazeyle fırlar;
## 3) bıçaklar değdiği yerde kum patlar, vurulan yavaşlar; kum kollar ufalanıp dökülür.
func c_suna_shuriken(c: Node3D, t: Node3D) -> void:
	var sand = Color(0.88, 0.74, 0.5)
	var sand_d = Color(0.7, 0.56, 0.36)
	var vein = Color(0.22, 0.27, 0.52)
	var base = c.global_position
	var fd = fwd(c, t)
	Sfx.play("earth", base, 1.6, 0.7)
	# yerden kollara akan ince kum (gövdeyi kapatan bulut değil)
	VFX.puffs(base + Vector3.UP * 0.1, {"amount": 22, "life": 0.6, "size": 0.45, "radius": 1.0, "vmin": 1, "vmax": 3, "dir": Vector3.UP, "spread": 30.0,
		"colors": [Color(0.95, 0.82, 0.58, 0.8), Color(0.8, 0.65, 0.4, 0)]})
	var arms = _sand_arms(c, sand, sand_d, vein)
	# 2) savuruş: hazırlık pozunda kollar kumla büyür, sonra öne savrulur
	get_tree().create_timer(0.42).timeout.connect(func():
		if not is_instance_valid(c):
			return
		CastAnim.play(c, "suna_shuriken_swing")
		Sfx.play("whoosh", c.global_position, 1.1, 0.9))
	get_tree().create_timer(0.56).timeout.connect(func():
		if not is_instance_valid(c):
			return
		var aim = fwd(c, t)
		var tgt0 = tg(c, t, 40.0)
		var info = inf(c, "suna_shuriken", 0.13, {"knock": 3.0, "kind": "light"})
		var k = 0
		for arm in arms:
			if not is_instance_valid(arm):
				continue
			var pts: Array = arm.get_meta("edge")
			for q in pts:
				var from: Vector3 = arm.global_transform * q
				var d = aim
				if tgt0:
					d = (tgt0.global_position + Vector3.UP * 1.0 - from).normalized()
				d = d.rotated(Vector3.UP, randf_range(-0.22, 0.22))
				d.y += randf_range(-0.05, 0.09)
				var bm = MB.new()
				# mekik bıçak: ince uzun, iki ucu sivri, ortası açık renk
				Loft.tube(bm, [Vector3(0, 0, 0.85), Vector3(0, 0, 0.3), Vector3(0, 0, -0.3), Vector3(0, 0, -0.85)],
					[Vector2(0.01, 0.01), Vector2(0.13, 0.05), Vector2(0.13, 0.05), Vector2(0.01, 0.01)], [sand_d, sand, sand.lightened(0.12), sand_d], 8, 4, true, true)
				var sx = 1.0 if k % 2 == 0 else -1.0
				var pr = shot(c, from, d.normalized(), 40.0 + randf_range(-4, 6), mesh_of(bm), info, null, false, 1.3, func(p, tgt):
					st(tgt, "slow", 2.5)
					VFX.puffs(p, {"amount": 14, "life": 0.6, "size": 0.6, "radius": 0.4, "vmin": 2, "vmax": 5, "colors": [Color(0.95, 0.82, 0.58, 0.9), Color(0.8, 0.65, 0.4, 0)]}))
				pr.spin = Vector3(0, 0, 30.0 * sx)
				Projectile.trail(pr, [Color(0.95, 0.82, 0.58, 0.85), Color(0.8, 0.65, 0.4, 0)], 0.3, 26, 0.4, FX.tex_smoke, false)
				k += 1
		FX.speed_lines(c.global_position + Vector3.UP * 1.4, aim))
	# 3) kollar ufalanır
	get_tree().create_timer(1.25).timeout.connect(func():
		for arm in arms:
			if not is_instance_valid(arm):
				continue
			VFX.puffs(arm.global_transform * Vector3(arm.get_meta("mid")), {"amount": 36, "life": 0.9, "size": 0.9, "radius": 0.9, "vmin": 0.5, "vmax": 3,
				"gravity": Vector3(0, -7, 0), "colors": [Color(0.92, 0.8, 0.55, 0.95), Color(0.8, 0.65, 0.4, 0)]})
			var bas: Array = arm.get_meta("bas")
			for pv in arm.get_meta("pivots"):
				if is_instance_valid(pv):
					var tw = pv.create_tween()
					tw.tween_property(pv, "scale", Vector3(0.7, 0.05, 0.7), 0.3)
			arm.get_tree().create_timer(0.32).timeout.connect(func():
				for ba in bas:
					if is_instance_valid(ba):
						ba.queue_free()))


## Karakterin kol kemiklerine bağlı dev kum kolları. Mesh'ler model uzayında (dinlenme pozu) kurulur ve kemiğe bağlanır;
## böylece kol nereye giderse kum kol da oraya gider. Döner: [ön kol+el düğümü (sol), (sağ)] (meta "edge": bıçak çıkış noktaları)
func _sand_arms(c: Node3D, sand: Color, sand_d: Color, vein: Color) -> Array:
	var out = []
	var m = c.get("model")
	if m == null or m.skel == null:
		return out
	var sk: Skeleton3D = m.skel
	for side in ["Left", "Right"]:
		var bu = sk.find_bone(side + "UpperArm")
		var bl = sk.find_bone(side + "LowerArm")
		var bh = sk.find_bone(side + "Hand")
		if bu < 0 or bl < 0 or bh < 0:
			continue
		var p_sh: Vector3 = m._grest(bu).origin
		var p_el: Vector3 = m._grest(bl).origin
		var p_wr: Vector3 = m._grest(bh).origin
		var dir = (p_wr - p_el).normalized()
		var up = Vector3.UP - dir * dir.dot(Vector3.UP)
		up = up.normalized() if up.length() > 0.01 else Vector3.FORWARD
		var fw = dir.cross(up).normalized()
		if fw.z < 0.0:
			fw = -fw
		var s = clampf(float(m.age_scale), 0.6, 1.0)
		# --- üst kol (omuz-dirsek): kalın kum manşon
		var mu = MB.new()
		Loft.tube(mu, [p_sh - (p_el - p_sh) * 0.1, p_sh.lerp(p_el, 0.5) + up * 0.03, p_el], [0.13 * s, 0.17 * s, 0.2 * s], sand, 12, 3, true, true)
		for k in 3:
			var q = p_sh.lerp(p_el, 0.25 + k * 0.3)
			BeastRig.claw(mu, q + up * 0.15 * s, (up * 0.7 - dir * 0.7).normalized(), 0.22 * s, 0.05 * s, sand_d)
		var au = m._attach(side + "UpperArm", Transform3D.IDENTITY)
		var mu_i = mesh_of(mu)
		var pu = Node3D.new()   # ölçek omuzdan büyüsün
		pu.position = p_sh
		au.get_child(0).add_child(pu)
		pu.add_child(mu_i)
		mu_i.position = -p_sh
		# --- ön kol + dev el: dirsekten bileğin ötesine uzanır, kalınlaşır
		var L = 1.25 * s
		var wr2 = p_el + dir * ((p_wr - p_el).length() + 0.15 * s)
		var palm0 = wr2 + dir * 0.15 * s
		var palm1 = wr2 + dir * L * 0.55
		var ml = MB.new()
		Loft.tube(ml, [p_el - dir * 0.05, p_el.lerp(wr2, 0.5) + up * 0.04 * s, wr2, palm0], [0.2 * s, 0.26 * s, 0.32 * s, 0.36 * s], sand, 14, 3, true, false)
		# avuç: yassı, geniş (yukarı-aşağı açık el), parmaklar yelpaze
		Loft.tube(ml, [palm0, palm0.lerp(palm1, 0.5), palm1], [Vector2(0.2, 0.36) * s, Vector2(0.2, 0.5) * s, Vector2(0.17, 0.46) * s], sand, 12, 3, false, true)
		var edge = PackedVector3Array()
		for f in 5:
			var a = deg_to_rad(-48.0 + f * 24.0)
			var fdir = (dir * cos(a) + up * sin(a) + fw * 0.15).normalized()
			var f0 = palm1 + up * sin(a) * 0.28 * s
			var f1 = f0 + fdir * 0.42 * s
			var f2 = f1 + (fdir + fw * 0.35).normalized() * 0.32 * s   # pençe hafif öne kıvrık
			Loft.tube(ml, [f0, f1, f2], [0.1 * s, 0.085 * s, 0.065 * s], sand, 8, 2, true, false)
			BeastRig.claw(ml, f2, (fdir + fw * 0.6).normalized(), 0.3 * s, 0.065 * s, Color(0.22, 0.22, 0.26))
			edge.append(f2)
		# sırtta geriye yatık dikenler (kolun üst kenarı) + bıçak çıkış noktaları
		for k in 6:
			var q = p_el.lerp(palm1, 0.15 + k * 0.15)
			var r = lerpf(0.24, 0.44, k / 5.0) * s
			BeastRig.claw(ml, q + up * r * 0.85, (up * 0.65 - dir * 0.75).normalized(), (0.28 + k * 0.03) * s, 0.07 * s, sand_d)
			BeastRig.claw(ml, q - up * r * 0.8, (-up * 0.6 - dir * 0.8).normalized(), 0.2 * s, 0.05 * s, sand_d)
			edge.append(q + up * r * 1.1)
		# mavi damarlar: kol boyunca dalgalı ince çizgiler (yüzeyde)
		for vk in 3:
			var off = (up * cos(vk * 2.1) + fw * sin(vk * 2.1)).normalized()
			var vp = []
			for k in 7:
				var tt = k / 6.0
				var q = p_el.lerp(palm1, tt)
				var rr = lerpf(0.22, 0.4, tt) * s * 1.01
				vp.append(q + off * rr + dir.cross(off) * sin(tt * 9.0 + vk) * 0.04 * s)
			Loft.tube(ml, vp, [0.018 * s, 0.018 * s, 0.018 * s, 0.018 * s, 0.018 * s, 0.018 * s, 0.018 * s], vein, 5, 1, false, false)
		var al = m._attach(side + "LowerArm", Transform3D.IDENTITY)
		var ml_i = mesh_of(ml)
		var pl = Node3D.new()   # ölçek dirsekten büyüsün
		pl.position = p_el
		al.get_child(0).add_child(pl)
		pl.add_child(ml_i)
		ml_i.position = -p_el
		ml_i.set_meta("edge", Array(edge))
		ml_i.set_meta("mid", p_el.lerp(palm1, 0.5))
		# büyüme: kum bilekten yayılır (ölçek), üst kol aynı anda
		for pv in [pu, pl]:
			pv.scale = Vector3.ONE * 0.2
			pv.create_tween().tween_property(pv, "scale", Vector3.ONE, 0.32).set_trans(Tween.TRANS_BACK)
		ml_i.set_meta("pivots", [pu, pl])
		ml_i.set_meta("bas", [au, al])
		out.append(ml_i)
	return out


## Kum Şelalesi Cenazesi: yerden dev kum dalgası yükselir, ileri yuvarlanıp her şeyi gömer
func c_sabaku_soso(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	# kum tsunamisi: tek kabarcık değil; yüzlerce kum topağı, öne kıvrılan dalga sırtı, akış çizgileri ve dökülen kum
	var wave = JutsuEngine.organic_mass("sand", Vector3(30.0, 12.0, 8.0))
	get_tree().current_scene.add_child(wave)
	wave.global_position = gp(c.global_position + d * 3.0) - Vector3.UP * 3.0
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


## Kum bulutu uçuşu (Sabaku Fuyū kullanır): ayağının altındaki kum bulutuna binip uçarsın
func c_sabaku_suna_no_kumo(c: Node3D, _t: Node3D) -> void:
	if not c is Player:
		return
	if c.flight_source() == "sand":
		c.stop_flight()
		return
	# anime (Sabaku Fuyū): ayağın altında toplu, kalın bir kum kütlesi (altı yuvarlak topak), taneli ve çatlak kum dokusu
	var b = MB.new()
	b.add("sphere", Vector3(0, 0, 0), Vector3(1.7, 0.75, 1.6), Color.WHITE, Vector3.ZERO, 12)
	b.add("sphere", Vector3(0, -0.35, 0.05), Vector3(1.2, 0.8, 1.15), Color.WHITE, Vector3.ZERO, 10)
	for k in 6:
		var a = k * TAU / 6.0 + 0.4
		b.add("sphere", Vector3(cos(a) * 0.62, -0.05 + 0.06 * (k % 2), sin(a) * 0.58), Vector3(0.75, 0.5, 0.7), Color.WHITE, Vector3(0, rad_to_deg(a), 0), 8)
	var cloud = mesh_of(b)
	var smat = ShaderMaterial.new()
	smat.shader = preload("res://shaders/vfx_sand_coat.gdshader")
	smat.set_shader_parameter("reveal_h", 99.0)
	smat.set_shader_parameter("inflate", 0.0)
	smat.set_shader_parameter("crack", 0.6)
	smat.set_shader_parameter("selfglow", 0.35)
	cloud.material_override = smat
	cloud.position = Vector3(0, -0.3, 0)
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
	# referans (Kikō Junbū, Chiyo): iki kuklanın uzun tahta kolları önde çapraz kilitlenir — kalkan duvar değil, X biçimli kol bariyeri
	var d = fwd(c, t)
	var b = MB.new()
	var WOOD = Color(0.78, 0.74, 0.66)
	for sgn in [-1.0, 1.0]:
		b.add("cyl", Vector3(0, 1.5, 0), Vector3(0.34, 3.2, 0.34), WOOD, Vector3(0, 0, sgn * 42.0), 8)   # kol (referans: kalın tahta kol)
		b.add("cyl", Vector3(sgn * 0.62, 2.05, 0), Vector3(0.26, 1.4, 0.26), WOOD.darkened(0.1), Vector3(0, 0, sgn * 42.0), 8)   # ön kol
		b.add("sphere", Vector3(sgn * 0.0, 1.5, 0), Vector3(0.24, 0.24, 0.24), WOOD.darkened(0.2), Vector3.ZERO, 8)   # dirsek eklemi
		for f in 4:   # el ve parmaklar
			b.add("cyl", Vector3(sgn * (1.0 + f * 0.06), 2.55 + f * 0.05, 0), Vector3(0.04, 0.25, 0.04), WOOD, Vector3(0, 0, sgn * (20.0 + f * 8.0)), 5)
	var shield = place(b, gp(c.global_position + d * 1.6))
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
			c.model.visible = true)


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
	# hedef 16 m içindeyse önce ona koşup yakalar (eskiden 6 m'den uzaktaysa hiç algılamıyordu)
	var tt = tg(c, t, 16.0)
	if tt == null:
		Hud.msg("Raigā Bomu: yakında hedef yok", Color(0.8, 0.9, 1))
		return
	_lightning_limb(c, 1.6)
	busy(c, 1.7)
	var grab = func():
		if not (live(c) and live(tt)):
			return
		# anime A: rakibi boynundan yakalar, birlikte havaya sıçrar, en tepede ters çevirip şimşekli dirsekle yere çakar
		st(tt, "bind", 1.3)
		anim(c, "jump", 1.4)
		var base = gp(tt.global_position)
		var fd = c.face_dir()
		every(0.9, 1.0 / 30.0, func(_i, k):
			var h = sin(minf(k * 1.4, 1.0) * PI * 0.5) * 7.0 if k < 0.7 else lerpf(7.0, 0.0, (k - 0.7) / 0.3)
			if live(tt):
				tt.global_position = base + Vector3.UP * h
				tt.rotation.x = lerpf(0.0, PI, clampf((k - 0.55) / 0.2, 0.0, 1.0))   # tepede ters döner
			if is_instance_valid(c):
				c.global_position = base + Vector3.UP * (h + 1.3) - fd * 0.5
				c.velocity = Vector3.ZERO, func():
			if live(tt):
				tt.global_position = base
				tt.rotation.x = 0.0
			anim(c, "slash_c", 2.0)
			VFX.cracks(base, 7.0)
			VFX.bolt(base + Vector3.UP * 12.0, base, Color(0.6, 0.85, 1.0), 0.5, 0.3, 4)
			VFX.debris(base, Color(0.5, 0.42, 0.32), 14, 11.0, 0.35)
			hit(c, base + Vector3.UP, 3.0, inf(c, "raiga_bomu", 2.4, {"knock": 10.0, "launch": 2.0, "kind": "heavy", "element": "raiton", "hitstop": 0.15}))
			shake(1.1)
			Sfx.play("thunder", base, 0.8))
	if c.global_position.distance_to(tt.global_position) > 2.2:
		Jutsu._dash(c, tt, minf(0.5, c.global_position.distance_to(tt.global_position) / 30.0), 30.0, func(_pt):
			if is_instance_valid(c) and c.get("model"):
				c.model.play("run", 0.06, 2.0), grab)
	else:
		grab.call()


## Giyotin Düşüşü: hedefin üstüne sıçrayıp yıldırım yüklü topukla iner: krater ve devirme
func c_girochin_doroppu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	var at = gp(tt.global_position if tt else Jutsu._aim_ground(c, t, 6.0, 14.0))
	_lightning_limb(c, 1.4)
	busy(c, 1.3)
	# Girochin Doroppu (anime A): hedefin üstüne yay çizerek yüksek sıçrar, havada dizleri toplayıp takla atar,
	# şimşekli topuğu giyotin gibi tepesine indirir — ışınlanma yok
	var start = c.global_position
	var apex = at + Vector3.UP * 7.0 - (at - start).normalized() * 0.5
	var md = c.get("model")
	anim(c, "jump", 1.6)
	var st0 = {"t": 0.0}
	var dur_up = 0.5
	every(dur_up, 1.0 / 60.0, func(_i, k):
		if not is_instance_valid(c):
			return
		c.velocity = Vector3.ZERO
		var u = clampf(k, 0.0, 1.0)
		var flat = start.lerp(apex, u)
		flat.y = lerpf(start.y, apex.y, sin(u * PI * 0.5))
		c.global_position = flat
		if md and md.get("overlay"):
			md.overlay.tuck = sin(u * PI)   # havada takla: dizler göğse
		if c is Player:
			var d = at - c.global_position
			d.y = 0
			if d.length() > 0.1:
				c.facing = atan2(-d.x, -d.z), func():
		if not is_instance_valid(c):
			return
		if md and md.get("overlay"):
			md.overlay.tuck = 0.0
		anim(c, "slash_c", 2.2)
		# şimşekli topuk iniyor: yukarıdan aşağı ışık izi
		VFX.bolt(c.global_position + Vector3.UP * 1.0, at, Color(0.6, 0.85, 1.0), 0.45, 0.25, 3)
		var tw = c.create_tween()
		tw.tween_property(c, "global_position", at + Vector3.UP * 0.05, 0.14).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			VFX.cracks(at, 6.0)
			FX.impact(at, Color(0.6, 0.85, 1.0), 1.8)
			VFX.debris(at, Color(0.5, 0.42, 0.32), 12, 10.0, 0.3)
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
	# kaymadan koşar: koşu animasyonu, sağ kol yana açık (lariat); gövde koşu yönüne bakar
	Jutsu._dash(c, t, 0.6, 30.0, func(pt):
		if is_instance_valid(c) and c.get("model"):
			c.model.play("run", 0.06, 2.1)
		for h in hit(c, pt + c.global_transform.basis.x * 0.6, 1.8, inf(c, "raiton_rariatto", 1.8, {"knock": 18.0, "launch": 9.0, "kind": "heavy", "element": "raiton", "hitstop": 0.08}), hits):
			hits.append(h)
			VFX.bolt(h.global_position + Vector3.UP * 3.0, h.global_position + Vector3.UP, Color(0.6, 0.85, 1.0), 0.3, 0.2, 2), func():
		arcs.queue_free())
	Sfx.play("chidori", c.global_position, 1.2)


## Dirsek: kısa atılış, yıldırımlı dirsek yukarı vurur, hedef sersemler
func c_erubo(c: Node3D, t: Node3D) -> void:
	_lightning_limb(c, 0.6)
	# Erubō (anime A): kaymadan koşar — şimşekli dirsek önde, varınca dirsek darbesi yukarı savurur
	Jutsu._dash(c, t, 0.22, 22.0, func(_pt):
		if is_instance_valid(c) and c.get("model"):
			c.model.play("run", 0.06, 2.0), func():
		var p = c.global_position + Vector3.UP * 1.2 + c.face_dir() * 1.0
		anim(c, "hook", 2.0)
		for h in hit(c, p, 1.6, inf(c, "erubo", 1.4, {"knock": 6.0, "launch": 10.0, "kind": "heavy", "element": "raiton", "hitstop": 0.1})):
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
## Ranton fırtına bulutu: kenarsız, yumuşak koyu bulut kütlesi (cel topak / küre mesh değil);
## içinde ara ara mavi-beyaz parlamalar ve kısa kavisli ışınlar çakar. Döndürülen sözlük: "base" (bulut tabanı)
func _storm_cloud(center: Vector3, r: float, dur: float) -> Dictionary:
	var info = {"base": center}
	every(dur, 0.12, func(_i, _k):
		var q = center + Vector3(randf_range(-r, r), randf_range(-0.6, 0.8), randf_range(-r, r)) * 0.8
		VFX.fog(q, {"amount": 5, "life": 2.4, "size": r * 1.3 + 3.0, "radius": r * 0.4, "vmin": 0.05, "vmax": 0.3, "dir": Vector3.UP, "spread": 90.0, "gravity": Vector3.ZERO,
			"colors": [Color(0.16, 0.17, 0.24, 0.0), Color(0.14, 0.15, 0.22, 0.9), Color(0.12, 0.13, 0.19, 0.8), Color(0.1, 0.11, 0.16, 0.0)]})
		if randf() < 0.35:
			var f = center + Vector3(randf_range(-r, r) * 0.7, randf_range(-0.3, 0.5), randf_range(-r, r) * 0.7)
			FX.light(f, Color(0.55, 0.8, 1.0), 6.0, r * 1.5 + 4.0, 0.12)
			var e2 = f + Vector3(randf_range(-3, 3), randf_range(-0.6, 0.6), randf_range(-3, 3))
			LightRibbon.spawn(LightRibbon.curve(f, e2, f.lerp(e2, 0.5) + Vector3.UP * randf_range(-0.8, 0.8), 8), 0.35, 0.18, Color(0.45, 0.72, 1.0)), Callable())
	return info


## Ranton ışık gövdesi: mermiyi takip eden kameraya dönük kıvrık ışın kuyruğu (tazı / ejderha gövdesi)
func _ribbon_tail(pr: Node3D, w: float, n := 10) -> void:
	# tek kalıcı şerit: noktaları her kare merminin geçtiği yerlerle güncellenir; mermi bitince şerit kısa sürede söner
	var hist = [pr.global_position, pr.global_position]
	var rb = LightRibbon.spawn(hist, w, pr.life + 0.5, Color(0.45, 0.72, 1.0))
	rb.grow = 0.0
	rb.fade_start = 1.0
	every(pr.life + 0.4, 1.0 / 30.0, func(_i, _k):
		if not is_instance_valid(rb):
			return
		if not is_instance_valid(pr) or pr.dead:
			hist.pop_back()
			if hist.size() < 2:
				rb.queue_free()
			else:
				rb.pts = hist.duplicate()
			return
		hist.push_front(pr.global_position)
		if hist.size() > n:
			hist.pop_back()
		rb.pts = hist.duplicate(), func():
		if is_instance_valid(rb):
			rb.queue_free())


## Ranton lazeri (anime Darui): kameraya dönük ışın şeridi — beyaz-sıcak merkez, mavi hâle; şimşek gibi dallanmaz
func _laser(a: Vector3, b: Vector3, w := 0.3, dur := 0.3) -> void:
	LightRibbon.spawn([a, a.lerp(b, 0.5), b], maxf(0.5, w * 3.0), maxf(0.25, dur), Color(0.45, 0.72, 1.0))
	FX.light(b, Color(0.6, 0.85, 1.0), 3.0, 7.0, dur)


## Lazer Sirki: ellerden çıkan sekiz ışın kıvrılarak ayrı hedeflere bükülür
func c_ranton_reiza_sakasu(c: Node3D, t: Node3D) -> void:
	var list = enemies_near(c, c.global_position, 35.0)
	busy(c, 0.9)
	var hand = Jutsu._hand(c)
	var fwd_d = Jutsu._aim(c, t)
	var side = fwd_d.cross(Vector3.UP).normalized()
	for k in 12:
		var target = list[k % list.size()] if not list.is_empty() else null
		var end = (target.global_position + Vector3.UP * 1.0) if target else hand + (fwd_d + side * randf_range(-0.5, 0.5) + Vector3.UP * randf_range(-0.1, 0.3)).normalized() * 26.0
		# anime: ışınlar avuçtan yelpaze gibi açılıp kavis çizerek hedefe kıvrılır
		var mid = hand.lerp(end, 0.45) + side * ((k - 5.5) * 1.6 + randf_range(-0.6, 0.6)) + Vector3.UP * (1.0 + (k % 4) * 1.8)   # yelpaze: her ışın ayrı kavis
		var tt = target
		var e2 = end
		Jutsu.get_tree().create_timer(0.08 + k * 0.03).timeout.connect(func():
			if not is_instance_valid(c):
				return
			LightRibbon.spawn(LightRibbon.curve(Jutsu._hand(c), e2, mid, 20), 0.42, 0.6, Color(0.4, 0.68, 1.0))
			FX.light(e2, Color(0.6, 0.85, 1.0), 4.0, 8.0, 0.3)
			if tt and is_instance_valid(tt) and not tt.is_dead():
				tt.take_hit(inf(c, "ranton_reiza_sakasu", 0.3, {"knock": 4.0, "kind": "heavy", "element": "ranton", "stun": 0.4})))
	FX.light(hand, Color(0.8, 0.92, 1.0), 6.0, 10.0, 0.6)
	Sfx.play("chidori", c.global_position, 1.7)


## Lazer Yağmuru: fırtına bulutundan aşağı bükülen ışınlar 2 sn boyunca bölgeye iner
func c_ikazuchi_reiza_ame(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 12.0, 26.0))
	# gökte toplanan parlak ışık noktası (koyu bulut yok — gölge gibi okunuyordu); ışınlar buradan yağar
	var src = Node3D.new()
	src.add_child(VFX.storm_orb(3.5))
	get_tree().current_scene.add_child(src)
	src.global_position = center + Vector3.UP * 14.0
	FX.light(src.global_position, Color(0.6, 0.85, 1.0), 6.0, 30.0, 2.4)
	# yumuşak fırtına bulutu: yuvarlak hatlı açık gri cel topaklar (alt yüzü mavi-gri, köşesiz); içi ışıkla parlar
	for k in 9:
		var q = center + Vector3.UP * 15.0 + (Vector3(randf_range(-7, 7), randf_range(-0.6, 0.8), randf_range(-5, 5)) if k > 0 else Vector3.ZERO)
		after(k * 0.04, func():
			VFX.puffs(q, {"amount": 8, "life": 2.5, "size": 4.5, "radius": 2.2, "vmin": 0.05, "vmax": 0.25, "dir": Vector3.UP, "spread": 90.0, "gravity": Vector3.ZERO, "damp": 1.0,
				"rough": 0.14, "outline": 0.03, "outline_col": Color(0.3, 0.36, 0.48), "shade": 0.45, "spin": 6.0,
				"colors": [Color(0.72, 0.78, 0.88, 0.0), Color(0.72, 0.78, 0.88, 1), Color(0.6, 0.66, 0.78, 0.95), Color(0.55, 0.6, 0.72, 0.0)], "scale_curve": [[0.0, 0.5], [0.3, 1.0], [1.0, 0.95]]}))
	fade_free(src, 2.3, 0.3)
	every(2.0, 0.1, func(_i, _k):
		var list = enemies_near(c, center, 10.0)
		var p = (list[randi() % list.size()].global_position if not list.is_empty() and randf() < 0.6 else center + Vector3(randf_range(-9, 9), 0, randf_range(-9, 9)))
		var a = center + Vector3.UP * 14.0
		LightRibbon.spawn(LightRibbon.curve(a, p + Vector3.UP * 0.2, a.lerp(p, 0.4) + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)), 12), 0.7, 0.25, Color(0.45, 0.72, 1.0))
		hit(c, p + Vector3.UP * 0.8, 1.4, inf(c, "ikazuchi_reiza_ame", 0.12, {"knock": 2.0, "element": "ranton"}))
		FX.burst(p + Vector3.UP * 0.2, {"amount": 8, "life": 0.25, "tex": FX.tex_spark, "size": 1.0, "vmin": 6, "vmax": 12, "colors": [Color(1, 1, 1, 1), Color(0.55, 0.8, 1.0, 0)]}))
	Sfx.play("thunder", center, 1.1)


## Kōga (Işık Dişi): zikzak çizerek koşan ışın; çarptığını sersemletir
func c_ikazuchi_koga(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	# Işık Dişi: dörtnala koşan ışık tazısı; yerde iki metre genişlikte zikzak çizer, gövdesi koştuğu yöne döner
	var head = Node3D.new()
	var hound = RantonArt.hound(2.6)
	hound.position.y = -0.9
	head.add_child(hound)
	var spd = 17.0
	var pr = shot(c, gp(c.global_position + d) + Vector3.UP * 0.9, d, spd, head, inf(c, "ikazuchi_koga", 1.1, {"knock": 8.0, "kind": "heavy", "element": "ranton", "stun": 1.2}), tg(c, t, 30.0), false, 2.2,
		func(p, _h): JutsuEngine.impact_for("ranton", p, Color(0.55, 0.8, 1.0), 1.4))
	_ribbon_tail(pr, 0.45, 8)
	var st0 = {"t": 0.0, "off": 0.0}
	pr.on_tick = func(p, dt):
		st0["t"] += dt
		var v: Vector3 = p.vel
		v.y = 0.0
		var side = v.normalized().cross(Vector3.UP) if v.length() > 0.1 else d.cross(Vector3.UP)
		var w = 6.5
		var off = sin(st0["t"] * w) * 1.8
		p.global_position += side * (off - st0["off"])
		st0["off"] = off
		p.global_position.y = Game.jutsu_floor(p.global_position.x, p.global_position.z) + 0.9
		# gövde zikzak yönüne döner (yanal hız / ileri hız)
		if is_instance_valid(hound):
			hound.rotation.y = -atan2(cos(st0["t"] * w) * 1.8 * w, spd)
		if randf() < 0.5:
			FX.burst(p.global_position - Vector3.UP * 0.8, {"amount": 2, "life": 0.25, "tex": FX.tex_spark, "size": 0.35, "vmin": 1.0, "vmax": 3.0, "colors": [Color(1, 1, 1, 1), Color(0.55, 0.8, 1.0, 0)]})
	Sfx.play("thunder", c.global_position, 1.5, 0.6)


## Gök Gürültüsü Bulutu: 8 sn kara bulut; içindeki her düşmana saniyede bir şimşek iner
func c_ikazuchi_raiun(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 10.0, 24.0))
	var top = center + Vector3.UP * 12.0
	_storm_cloud(top, 8.0, 8.0)
	every(8.0, 1.0, func(_i, _k):
		for e in enemies_near(c, center, 12.0):
			var a = top + Vector3(randf_range(-4, 4), -1.5, randf_range(-4, 4))
			var b = e.global_position + Vector3.UP
			# buluttan inen ışın: düz değil hafif kavisli tek şerit (şimşek dalı yok)
			LightRibbon.spawn(LightRibbon.curve(a, b, a.lerp(b, 0.5) + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)), 12), 0.9, 0.3, Color(0.45, 0.72, 1.0))
			JutsuEngine.impact_for("ranton", b, Color(0.55, 0.8, 1.0), 0.8)
			hit(c, b, 1.0, inf(c, "ikazuchi_raiun", 0.35, {"knock": 2.0, "element": "ranton", "stun": 0.5}))
		Sfx.play("thunder", center, 1.0, 0.7), Callable())


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
	LightRibbon.spawn(pts, 1.0, 0.5, Color(0.45, 0.72, 1.0))
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
		Buffs.add("kakogan", 15.0, {"melee": 1.3})
	VFX.debris(c.global_position + Vector3.UP, Color(0.55, 0.5, 0.42), 8, 4.0, 0.3)
	Sfx.play("earth", c.global_position, 1.3)


## Sertleşme: tenin taşa döner: 12 sn hasar çok azalır, savrulmazsın ama yavaşlarsın
func c_doton_koka_jutsu(c: Node3D, _t: Node3D) -> void:
	# saydam küre kabuk kaldırıldı (beyaz bulut gibi duruyordu): taş plakalar gövdedeki kemiklere bağlı (_stone_skin)
	if c is Player:
		Buffs.add("koka", 12.0, {"armor": 0.68, "speed": 0.8})
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
func _clay(size: float) -> Node3D:
	var mi = ClayArt.lump(0.5)
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
					VFX.clay_blast(p + Vector3.UP * 0.5, 1.3)
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
		VFX.clay_blast(p, 1.8)
		hit(c, p, 3.0, inf(c, "bakuha_kibaku_te", 2.2, {"knock": 16.0, "launch": 8.0, "kind": "heavy", "element": "bakuton", "hitstop": 0.12}))
		Combat.popup_text(p + Vector3.UP * 1.4, "Katsu!", Color(1, 0.9, 0.5))
		shake(0.8))


## Zincirleme Patlama: yerden ileriye doğru sıra sıra büyüyen patlamalar
func c_bakuha_rensa(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	for k in 7:
		var p = gp(c.global_position + d * (3.0 + k * 3.0))
		after(0.15 + k * 0.12, func():
			VFX.clay_blast(p + Vector3.UP * 0.5, 0.8 + k * 0.18)
			VFX.cracks(p, 2.0 + k * 0.3)
			hit(c, p + Vector3.UP, 2.0 + k * 0.25, inf(c, "bakuha_rensa", 0.35, {"knock": 9.0, "launch": 5.0, "kind": "heavy", "element": "bakuton"}))
			shake(0.25 + k * 0.05))
	Sfx.play("boom", c.global_position, 0.9)


# ================================================================== UCHİHA — ateş ve kılıç sanatı
## Uchiha Ryū Kenjutsu (kanon, Sasuke): kılıç kınında, iai duruşu — kılıca şimşek akar (cıvıltı), tek hamlede hedefin
## içinden geçen çekiş-kesişi; kesik bir an sonra açılır (gecikmeli iai), şimşek kası felç eder.
func c_uchiha_ryu_kenjutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	busy(c, 1.0)
	if c.get("model"):
		c.model.hold_temp("katana", 1.1, "Right", 1.0, 0.0, false, true)
		c.model.play("crouch", 0.05, 1.0)
	var blue = Color(0.7, 0.85, 1.0)
	# iai duruşu: el kabzada, kılıç boyunca şimşek
	every(0.35, 0.05, func(_i, _k):
		if is_instance_valid(c):
			var h = Jutsu._hand(c)
			VFX.bolt(h, h + Vector3(randf_range(-0.6, 0.6), randf_range(-0.3, 0.5), randf_range(-0.6, 0.6)), blue, 0.05, 0.08, 1))
	Sfx.play("chidori", c.global_position, 1.6, 0.4)
	after(0.35, func():
		if not is_instance_valid(c):
			return
		var from = c.global_position
		var dist = (from.distance_to(tt.global_position) + 3.0) if live(tt) else 9.0
		var dur = clampf(dist / 70.0, 0.08, 0.26)
		anim(c, "slash_c", 3.0)
		if c is Player:
			c.combat.invuln = maxf(c.combat.invuln, dur + 0.1)
		var hits = []
		Sfx.play("kunai", from, 1.4)
		var dd = _aim_tt(c, t, tt, from + Vector3.UP)
		dd.y = 0.0
		dd = dd.normalized()
		if "facing" in c:
			c.facing = atan2(-dd.x, -dd.z)
		var dest = gp(from + dd * dist)
		var tw = c.create_tween()
		tw.tween_method(func(x: float):
			if not is_instance_valid(c):
				return
			var p = from.lerp(dest, x)
			p.y = maxf(p.y, Game.jutsu_floor(p.x, p.z))
			c.global_position = p
			if "velocity" in c:
				c.velocity = Vector3.ZERO
			var hp = p + Vector3.UP * 1.0
			for e in hit(c, hp, 1.8, inf(c, "uchiha_ryu_kenjutsu", 1.4, {"knock": 4.0, "kind": "heavy", "element": "raiton", "stun": 0.7, "hitstop": 0.1}), hits):
				hits.append(e)
			if randf() < 0.5:
				VFX.bolt(hp, hp + Vector3(randf_range(-1, 1), randf_range(-0.4, 0.6), randf_range(-1, 1)), blue, 0.06, 0.12, 1), 0.0, 1.0, dur)
		tw.tween_callback(func():
			if not is_instance_valid(c):
				return
			var to = c.global_position
			# geçilen yol boyunca ince ak-mavi kesik izi
			VFX.bolt(from + Vector3.UP * 1.1, to + Vector3.UP * 1.1, Color(0.9, 0.95, 1.0), 0.12, 0.35, 2)
			# gecikmeli kesik: hedefin üzerinde açılır
			after(0.22, func():
				for e in hits:
					if live(e):
						var q = e.global_position + Vector3.UP * 1.1
						_slash_arc(q, (to - from).normalized(), -20.0, Color(0.85, 0.92, 1.0), 2.4)
						VFX.star(q, Color(1, 1, 1), 2.0, 0.12)
						for k in 4:
							VFX.bolt(q, q + Vector3(randf_range(-1, 1), randf_range(-0.5, 1), randf_range(-1, 1)) * 2.0, blue, 0.08, 0.2, 2)
				if not hits.is_empty():
					shake(0.4)
					Sfx.play("thunder", to, 1.6, 0.4))))


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


## Uchiha Ryū Shurikenjutsu: Ikazuchi Sanren (kanon): şimşek yüklü üç shuriken art arda; Uchiha shurikenjutsusu gibi
## yay çizip farklı açılardan hedefe kıvrılır, değdiği yerde şimşek kası kısa felç eder.
func c_uchiha_ryu_shurikenjutsu_ikazuchi_sanren(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 30.0)
	busy(c, 0.6)
	var blue = Color(0.65, 0.85, 1.0)
	var aim = _aim_tt(c, t, tt, Jutsu._hand(c))
	for k in 3:
		after(k * 0.11, func():
			if not is_instance_valid(c):
				return
			anim(c, ["throw", "slash_a", "throw"][k], 2.2)
			var d = aim.rotated(Vector3.UP, [-0.55, 0.55, 0.0][k]) + Vector3.UP * [0.05, 0.05, 0.12][k]
			var b = MB.new()
			for n in 4:
				b.add("cone", Vector3(cos(n * 1.57) * 0.16, 0, sin(n * 1.57) * 0.16), Vector3(0.09, 0.32, 0.02), Color(0.3, 0.3, 0.36), Vector3(0, -n * 90, -90), 4)
			b.add("cyl", Vector3.ZERO, Vector3(0.08, 0.03, 0.08), Color(0.2, 0.2, 0.24), Vector3.ZERO, 8)
			var root = Node3D.new()
			root.add_child(mesh_of(b))
			var arcs = Arcs.new()
			arcs.color = blue
			arcs.radius = 0.4
			arcs.count = 3
			arcs.width = 0.03
			root.add_child(arcs)
			var pr = shot(c, Jutsu._hand(c), d.normalized(), 34.0, root, inf(c, "uchiha_ryu_shurikenjutsu_ikazuchi_sanren", 0.4, {"knock": 3.0, "element": "raiton", "stun": 0.45}), tt, false, 1.8, func(p, _h):
				for n in 3:
					VFX.bolt(p, p + Vector3(randf_range(-1, 1), randf_range(-0.3, 1), randf_range(-1, 1)) * 1.4, blue, 0.06, 0.15, 1)
				VFX.star(p, Color(0.85, 0.92, 1.0), 1.0, 0.1))
			pr.homing_turn = 5.0
			pr.spin = Vector3(0, 30, 0)
			VFX.trail(root, 0.06, Color(0.9, 0.95, 1.0), blue, Color(blue.r, blue.g, blue.b, 0.0), 12, 1.0)
			Sfx.play("kunai", c.global_position, 1.3))


## Nişan: menzilde hedef varsa ona (göğüs), yoksa oyuncunun nişangâhı
func _aim_tt(c: Node3D, t: Node3D, tt: Node3D, from: Vector3) -> Vector3:
	if live(tt):
		var v = tt.global_position + Vector3.UP * 1.1 - from
		if v.length() > 0.1:
			return v.normalized()
	return Jutsu._aim(c, t)


## Uchiha Kaenjin (kanon): parmak uçlarında alev yanar, avuç yere vurulur ve kullanıcının çevresinde silindir alev bariyeri
## yükselir. Bariyer korur: dışarıdan gelen mermiler duvarda yanıp söner, duvara değen düşman tutuşup geri savrulur. Az chakra.
func c_uchiha_kaenjin(c: Node3D, _t: Node3D) -> void:
	var r = 4.6
	var H = 6.5
	var DUR = 7.0
	busy(c, 1.0)
	anim(c, "cast", 1.4)
	# 1) parmak uçlarında alev
	every(0.45, 0.05, func(_i, _k):
		if is_instance_valid(c):
			VFX.puffs(Jutsu._hand(c), {"amount": 3, "life": 0.25, "size": 0.18, "radius": 0.12, "vmin": 1.0, "vmax": 2.5, "dir": Vector3.UP, "spread": 25.0,
				"glow": 1.3, "hot": 0.5, "colors": UCHIHA_FIRE}))
	Sfx.play("fire", c.global_position, 1.4, 0.5)
	# 2) avuç yere: zemin çatlar, alev halka hâlinde dışa koşar, duvar yükselir
	after(0.45, func():
		if not is_instance_valid(c):
			return
		anim(c, "crouch", 2.0)
		var center = gp(c.global_position)
		VFX.cracks(center, r * 0.8, Color(0.12, 0.04, 0.02, 0.85), DUR + 1.0)
		VFX.shockwave(center + Vector3.UP * 0.15, Color(1, 0.55, 0.15), r * 2.1, 0.35)
		VFX.puffs(center + Vector3.UP * 0.3, {"amount": 40, "life": 0.5, "size": 0.9, "radius": 0.5, "vmin": 8.0, "vmax": 12.0, "dir": Vector3.UP, "spread": 88.0, "damp": 3.0,
			"glow": 1.2, "hot": 0.3, "colors": UCHIHA_FIRE})
		shake(0.45)
		Sfx.play("fire", center, 0.6)
		var root = Node3D.new()
		get_tree().current_scene.add_child(root)
		root.global_position = center
		# duvar: dolu kabuk değil — çember boyunca yan yana yükselen, boyları ve eğimleri farklı alev dilleri (arada aralık kalır)
		var fm = VFX.mat_fire("fire", 3.6, 2.2, 0.46, 1.35, 0.3, Vector3.UP, true)
		var mats = [fm]
		var N = 44
		for k in N:
			var a = TAU * k / N + randf_range(-0.05, 0.05)
			var rr = r + randf_range(-0.25, 0.2)
			var tongue = VFX._mi(VFX._tongue_mesh(k % 3), fm)
			tongue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(tongue)
			tongue.position = Vector3(cos(a) * rr, -0.1, sin(a) * rr)
			tongue.rotation.y = -a + randf_range(-0.5, 0.5)
			tongue.rotate(Vector3(cos(a), 0, sin(a)).cross(Vector3.UP).normalized(), randf_range(-0.12, 0.12))   # yana yalar
			var h = H * (randf_range(0.55, 1.05) if k % 4 != 0 else randf_range(1.0, 1.25))
			var w = randf_range(1.0, 1.5)
			tongue.scale = Vector3(w, 0.05, w)
			var tw = tongue.create_tween()
			tw.tween_interval(absf(sin(a * 0.5)) * 0.12)   # yerden dalga gibi dışa doğru yükselir
			tw.tween_property(tongue, "scale", Vector3(w, h, w), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func():
				if not is_instance_valid(tongue):
					return
				var per = randf_range(0.22, 0.42)
				var fl = tongue.create_tween().set_loops()
				fl.tween_property(tongue, "scale", Vector3(w * 0.9, h * 1.1, w * 0.9), per).set_trans(Tween.TRANS_SINE)
				fl.tween_property(tongue, "scale", Vector3(w * 1.05, h * 0.85, w * 1.05), per).set_trans(Tween.TRANS_SINE))
		var light = OmniLight3D.new()
		light.light_color = Color(1, 0.5, 0.2)
		light.light_energy = 4.0
		light.omni_range = r * 3.0
		root.add_child(light)
		light.position.y = 3.0
		every(DUR, 0.1, func(i, _k):
			# gövde: dillerin arasından yükselen cel alev topakları
			var ab = randf() * TAU
			VFX.puffs(center + Vector3(cos(ab) * r, randf_range(0.5, H * 0.6), sin(ab) * r), {"amount": 3, "life": 0.5, "size": 1.1, "radius": 0.5, "vmin": 2.0, "vmax": 4.5, "dir": Vector3.UP, "spread": 15.0,
				"glow": 1.2, "hot": 0.3, "stretch": 1.4, "colors": UCHIHA_FIRE})
			# duvarın tepesinden kopan alev dilleri
			if i % 2 == 0:
				var a = randf() * TAU
				VFX.puffs(center + Vector3(cos(a) * r, H, sin(a) * r), {"amount": 4, "life": 0.45, "size": 0.9, "radius": 0.6, "vmin": 2.0, "vmax": 5.0, "dir": Vector3.UP, "spread": 20.0,
					"glow": 1.2, "hot": 0.3, "stretch": 1.5, "colors": UCHIHA_FIRE})
			# dışarıdan gelen mermiler duvarda yanar
			for n in get_tree().current_scene.get_children():
				if n is Projectile and not n.dead and n.shooter != c and Combat.hostile(c, n.shooter):
					var v = n.global_position - center
					var hd = Vector2(v.x, v.z).length()
					if hd > r - 1.2 and hd < r + 1.2 and v.y < H + 1.0:
						VFX.embers(n.global_position, Color(1, 0.55, 0.15), 14, 5.0, 0.6)
						VFX.star(n.global_position, Color(1, 0.7, 0.3), 1.4, 0.12)
						n.block()
			# duvara değen ya da içeri giren düşman tutuşur ve dışarı savrulur
			for e in enemies_near(c, center, r + 1.3):
				var v = e.global_position - center
				v.y = 0.0
				if v.length() < 0.1:
					v = Vector3.FORWARD
				hit(c, e.global_position + Vector3.UP, 0.8, inf(c, "uchiha_kaenjin", 0.25, {"knock": 14.0, "launch": 3.0, "kind": "heavy", "element": "katon", "burn": 3.0, "dir": v.normalized()}))
				e.global_position = gp(center + v.normalized() * (r + 2.2))
				VFX.puffs(center + v.normalized() * r + Vector3.UP * 1.2, {"amount": 10, "life": 0.4, "size": 0.7, "vmin": 4.0, "vmax": 8.0, "dir": v.normalized(), "spread": 40.0,
					"glow": 1.2, "hot": 0.3, "colors": UCHIHA_FIRE})
		, func():
			for fmx in mats:
				var tw = root.create_tween()
				tw.tween_method(func(x: float): fmx.set_shader_parameter("alpha_cut", x), 0.0, 1.1, 0.6)
			get_tree().create_timer(0.7).timeout.connect(func(): if is_instance_valid(root): root.queue_free())))


## Uchihagaeshi (kanon, Madara): gunbai önde; gelen saldırı yelpazenin yüzüne çarpar, emilir ve rüzgârla birlikte
## sahibine geri savrulur. Süre sonunda yelpaze savrulur: önde emilen saldırıyla güçlenen rüzgâr dalgası.
func c_uchihagaeshi(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var dur = 2.4
	busy(c, dur + 0.3)
	if c.get("model"):
		c.model.hold_temp("gunbai", dur + 0.5, "Right", 2.2, PI * 0.5, false, true)
		c.model.play("block", 0.08, 1.0)
	if c is Player:
		c.facing = atan2(-d.x, -d.z)
	var center = func(): return c.global_position + Vector3.UP * 1.6 + (c.face_dir() if c.has_method("face_dir") else d) * 0.9
	Sfx.play("wind", c.global_position, 0.7)
	WindFX.swirl(center.call(), 1.4, 0.6, 0.5, 8, Color(1.0, 0.9, 0.88), false)
	var reflected = [0]
	every(dur, 1.0 / 30.0, func(i, _k):
		if not is_instance_valid(c):
			return
		var cp: Vector3 = center.call()
		var fd: Vector3 = c.face_dir() if c.has_method("face_dir") else d
		# yelpaze yüzünde hafif hava kıvrımı (görünür kabuk yok)
		if i % 8 == 0:
			WindFX.swirl(cp, 1.2, 0.4, 0.35, 4, Color(1.0, 0.92, 0.9), false)
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
				# emiş: saldırı yelpazenin yüzünde bir an durur, sarmal rüzgârla geri fırlar
				VFX.star(n.global_position, Color(1, 0.6, 0.5), 2.2, 0.15)
				WindFX.gust(cp, n.vel.normalized(), 6.0, 2.5, {"n": 8, "dust": false, "leaves": false, "col": Color(1, 0.95, 0.9)})
				shake(0.15)
				Sfx.play("guard", cp, 0.8)
		for e in enemies_near(c, cp, 2.2):
			hit(c, e.global_position + Vector3.UP, 0.8, inf(c, "uchihagaeshi", 0.3, {"knock": 14.0, "launch": 3.0, "kind": "heavy"}))
	, func():
		# kapanış: yelpaze savrulur — önde rüzgâr dalgası, emilen saldırı sayısıyla güçlenir
		if not is_instance_valid(c):
			return
		anim(c, "slash_b", 1.6)
		var cp: Vector3 = center.call()
		var fd: Vector3 = c.face_dir() if c.has_method("face_dir") else d
		var pw = 1.0 + 0.35 * reflected[0]
		WindFX.gust(cp, fd, 12.0 * minf(pw, 2.0), 6.0 * minf(pw, 2.0), {"n": 18, "col": Color(1.0, 0.95, 0.92)})
		VFX.debris(gp(cp + fd * 4.0), Color(0.55, 0.48, 0.38), 14, 12.0, 0.4)
		for e in enemies_near(c, cp + fd * 5.0, 6.5 * minf(pw, 1.6)):
			var v = (e.global_position - c.global_position).normalized()
			if v.dot(fd) > 0.2:
				hit(c, e.global_position + Vector3.UP, 1.0, inf(c, "uchihagaeshi", 0.9 + 0.25 * reflected[0], {"knock": 26.0, "launch": 6.0, "kind": "heavy", "dir": fd}))
		shake(0.45)
		Sfx.play("wind", cp, 0.5))


## Katon: Hōsenka Tsumabeni (kanon, Itachi): ağızdan yelpaze gibi küçük ateş topları yağar; içlerine gizlenmiş shuriken'ler
## alevin içinden çıkıp hedefe kıvrılır (ateşten kaçan shuriken'e yakalanır). Shuriken değdiği yerde yanmaya devam eder.
func c_katon_hosenka_tsumabeni(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 34.0)
	busy(c, 0.9)
	anim(c, "cast_out", 1.3)
	Sfx.play("fire", c.global_position, 1.1)
	var aim = _aim_tt(c, t, tt, Jutsu._mouth(c))
	for k in 6:
		after(k * 0.07, func():
			if not is_instance_valid(c):
				return
			var d = (aim.rotated(Vector3.UP, (k - 2.5) * 0.17) + Vector3.UP * randf_range(0.0, 0.12)).normalized()
			var mo = Jutsu._mouth(c) + d * 0.6
			# ateş topu (yem): yavaşça yay çizer, yere/hedefe düşünce küçük patlar
			var fb = Node3D.new()
			fb.add_child(VFX.fireball(0.75))
			var fpr = shot(c, mo, d, 20.0, fb, inf(c, "katon_hosenka_tsumabeni", 0.18, {"knock": 3.0, "element": "katon", "burn": 2.0}), null, false, 1.6, func(p, _h):
				VFX.explosion(p, 0.5, Color(1.0, 0.55, 0.15)))
			fpr.gravity = 4.0
			fpr.radius = 0.6
			VFX.puffs(mo, {"amount": 5, "life": 0.3, "size": 0.6, "vmin": 5, "vmax": 10, "dir": d, "spread": 18.0, "glow": 1.1, "hot": 0.3, "colors": UCHIHA_FIRE})
			# içindeki shuriken: önce alevle birlikte gider, sonra alevden sıyrılıp hedefe kıvrılır
			var b = MB.new()
			for n in 4:
				var bs = Basis(Vector3.UP, n * PI * 0.5)
				b.add_xf("cone", Transform3D(bs * Basis(Vector3.BACK, PI * 0.5) * Basis.from_scale(Vector3(0.1, 0.3, 0.02)), bs * Vector3(0.15, 0, 0)), Color(0.32, 0.32, 0.38), 4)
			b.add("cyl", Vector3.ZERO, Vector3(0.07, 0.03, 0.07), Color(0.2, 0.2, 0.24), Vector3.ZERO, 8)
			var sh = Node3D.new()
			sh.add_child(mesh_of(b))
			var spr = shot(c, mo, d, 20.0, sh, inf(c, "katon_hosenka_tsumabeni", 0.3, {"knock": 4.0, "element": "katon", "burn": 4.0}), null, false, 2.0, func(p, _h):
				VFX.embers(p, Color(1, 0.55, 0.15), 8, 3.0, 0.6))
			spr.spin = Vector3(0, 35, 0)
			spr.radius = 0.35
			after(0.28, func():
				if is_instance_valid(spr) and not spr.dead:
					spr.homing = tt
					spr.homing_turn = 7.0
					spr.vel = spr.vel.normalized() * 38.0
					VFX.trail(sh, 0.05, Color(1, 0.8, 0.4), Color(1, 0.45, 0.1), Color(0.6, 0.1, 0.02, 0), 10, 1.0)))


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
	# Gōka Mekkyaku (ref katon.png üst): ağızdan çıkan kesintisiz alev kütlesi ileri aktıkça devasa bir dalgaya genişler,
	# yere iner ve önündeki her şeyi yutar (sütun duvarı değil). Kütle her tikte büyüyen tek gövde, uzun alev dilleriyle akar.
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_transform = Transform3D(Basis.looking_at(-d, Vector3.UP), Vector3(mo.x, start.y, mo.z))
	var fm = VFX.mat_fire("fire", 3.2, 0.32, 0.22, 1.25, 0.08, Vector3(0, 0, 1), true)
	fm.set_shader_parameter("fres_k", 0.42)   # dev yayvan kütle: kenar aşınması zayıf (delik delik kırmızı kabuk olmasın)
	var body = MeshInstance3D.new()
	body.material_override = fm
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(body)
	var mouth_h = mo.y - start.y
	var light = OmniLight3D.new()
	light.light_color = Color(1, 0.55, 0.2); light.light_energy = 5.0; light.omni_range = 40.0
	root.add_child(light)
	var hits = []
	every(2.0, 0.05, func(i, k):
		var reach = 6.0 + minf(1.0, k * 1.3) * 40.0
		var w = lerpf(4.0, 46.0, minf(1.0, k * 1.5))
		var h = lerpf(3.0, 12.0, minf(1.0, k * 1.8))
		body.mesh = FireArt.sheet_mesh(reach, w, h, mouth_h, k * 2.0)
		var cen = gp(start + d * reach * 0.8)
		light.global_position = cen + Vector3.UP * 4.0
		if i % 2 == 0:
			VFX.puffs(Jutsu._mouth(c) if is_instance_valid(c) else start, {"amount": 6, "life": 0.4, "size": 1.2, "vmin": 10, "vmax": 26, "dir": d, "spread": 16.0, "damp": 1.5,
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
		# alev denizi geride kalır: geniş alan bir süre yanmaya devam eder (Suiton ile söndürülür)
		for row in 3:
			for n in 5:
				GroundFX.add(gp(start + d * (12.0 + row * 12.0) + side * (n - 2) * 8.0), "burning", 5.5, 6.0, c)
		# söner: kütle yerinde erir (malzeme aşınması)
		var tw = root.create_tween()
		tw.tween_method(func(x: float): fm.set_shader_parameter("alpha_cut", x), 0.0, 1.1, 0.7)
		tw.tween_callback(root.queue_free))


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


## Genjutsu: Sharingan (kanon): GÖZ TEMASI şart — hedef sana bakmıyorsa tutmaz. Kurban yanılsamaya düşer: bilinci kayar,
## dizlerinin üstüne çöker; yanılsamada yerden yükselen gölge eller onu kavrar (izleyen de görür). Sharingan sahibi direnir.
func c_genjutsu_sharingan(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 22.0)
	if tt == null:
		return
	busy(c, 0.5)
	_eye_flash(c)
	var gm = _gen_power(c) * Eyes.genjutsu_land(c, tt, true)
	if gm <= 0.0:
		return
	var dur = 3.0 * gm
	st(tt, "stun", dur)
	st(tt, "fear", dur)
	_illusion(tt, dur, Color(0.85, 0.05, 0.05))
	_shadow_hands(tt, dur)
	hit(c, tt.global_position + Vector3.UP, 0.8, inf(c, "genjutsu_sharingan", 0.35, {"knock": 0.0, "dir": Vector3.ZERO}))
	Sfx.play("genjutsu", tt.global_position)


## Iatsu Sharingan (kanon): tek bir BAKIŞ — kurbana kabus genjutsusu çöker, ezici baskı onu dizlerinin üstüne düşürür
## (Sai bile sarsılmıştı). Tek hedef, göz teması şart. Kurban çöker, korkudan kıpırdayamaz.
func c_iatsu_sharingan(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	if tt == null:
		return
	busy(c, 0.6)
	_eye_flash(c, 1.6)
	var gm = _gen_power(c) * Eyes.genjutsu_land(c, tt, true)
	if gm <= 0.0:
		return
	var dur = 2.6 * gm
	st(tt, "stun", dur)
	st(tt, "fear", dur + 1.5)
	# baskı: bakışın yönünde kızıl-kara öldürme niyeti dalgası kurbanın üstüne çöker
	var from = Jutsu._mouth(c) + Vector3.UP * 0.12
	var to = tt.global_position + Vector3.UP * 1.4
	for k in 3:
		after(k * 0.08, func():
			VFX.shockwave(from.lerp(to, 0.35 + k * 0.3), Color(0.7, 0.02, 0.03), 2.0 + k * 1.2, 0.3, false, (to - from).normalized()))
	after(0.2, func():
		if not live(tt):
			return
		if tt.get("model"):
			tt.model.play("crouch", 0.05, 1.0)
		VFX.puffs(tt.global_position + Vector3.UP * 0.2, {"amount": 18, "life": 0.6, "size": 0.9, "radius": 0.6, "vmin": 2.0, "vmax": 4.0, "dir": Vector3.UP, "spread": 70.0,
			"hot": 0.0, "glow": 0.0, "outline": 0.05, "outline_col": Color(0.5, 0.0, 0.03), "colors": [Color(0.12, 0.0, 0.02, 0.9), Color(0.05, 0.0, 0.01, 0.0)]})
		_illusion(tt, dur, Color(0.7, 0.0, 0.03))
		shake(0.35))
	hit(c, tt.global_position + Vector3.UP, 0.8, inf(c, "iatsu_sharingan", 0.5, {"knock": 0.0}))
	if Game.world and c is Player:
		Game.world.env.flash_tint(Color(0.6, 0.0, 0.0, 0.14), 0.6)
	Sfx.play("genjutsu", tt.global_position, 0.7)


## Bakış anı: kullanıcının gözünde Sharingan çakar
func _eye_flash(c: Node3D, s := 1.2) -> void:
	VFX.star(Jutsu._mouth(c) + Vector3.UP * 0.12, Color(1, 0.12, 0.1), s, 0.18)


## Kurbanın yaşadığı yanılsama (izleyen de görür): bedeninden yükselen kızıl-kara tüller;
## kurban oyuncuysa ekran kızıla çalar
func _illusion(tt: Node3D, dur: float, col: Color) -> void:
	if not live(tt):
		return
	var wr = weakref(tt)
	every(maxf(0.9, dur), 0.2, func(_i, _k):
		var n = wr.get_ref()
		if n == null or not is_instance_valid(n):
			return
		VFX.puffs(n.global_position + Vector3.UP * randf_range(0.3, 1.6), {"amount": 3, "life": 0.9, "size": 0.5, "radius": 0.5, "vmin": 0.4, "vmax": 1.2, "dir": Vector3.UP, "spread": 40.0,
			"hot": 0.0, "glow": 0.0, "outline": 0.0, "colors": [Color(col.r, col.g, col.b, 0.0), Color(col.r, col.g, col.b, 0.55), Color(0.02, 0.0, 0.01, 0.0)]}))
	VFX.star(tt.global_position + Vector3.UP * 1.6, col.lightened(0.3), 1.2, 0.15)
	if tt == Game.player and Game.world:
		Game.world.env.flash_tint(Color(col.r, col.g, col.b, 0.3), minf(dur, 2.0))


## Genjutsu: Sharingan'ın yanılsaması (kanon örneği: gölge bir figür kurbanı kavrar): yerden gölge eller yükselip bedeni sarar
func _shadow_hands(tt: Node3D, dur: float) -> void:
	var base = tt.global_position
	var m = Jutsu._black_mat()
	for k in 5:
		var a = k * TAU / 5.0 + randf_range(-0.3, 0.3)
		var pts = []
		var rr = []
		for j in 9:
			var u = j / 8.0
			var ang = a + u * 2.4
			var rad = lerpf(1.1, 0.42, u)
			pts.append(Vector3(cos(ang) * rad, sin(u * PI * 0.75) * 1.25, sin(ang) * rad))
			var w = lerpf(0.13, 0.03, u)
			rr.append(Vector2(w, w))
		var mb = MB.new()
		Loft.tube(mb, pts, rr, Color.WHITE, 6, 2)
		for f in 4:   # parmak uçları
			var fa = a + 2.4 + (f - 1.5) * 0.22
			mb.add("cone", Vector3(cos(fa) * 0.4, 1.0, sin(fa) * 0.4), Vector3(0.04, 0.24, 0.04), Color.WHITE, Vector3(0, -rad_to_deg(fa), 150), 5)
		var mi = MeshInstance3D.new()
		mi.mesh = mb.build(null)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_tree().current_scene.add_child(mi)
		mi.global_position = base
		mi.scale = Vector3(1, 0.02, 1)
		var tw = mi.create_tween()
		tw.tween_interval(k * 0.05)
		tw.tween_property(mi, "scale", Vector3(1.15, 0.6, 1.15), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)   # alçaktan sarar (kurban yere çöker)
		tw.tween_interval(maxf(0.3, dur - 0.7))
		tw.tween_property(mi, "scale", Vector3(1, 0.02, 1), 0.3)
		tw.tween_callback(mi.queue_free)


## Magen: Shinkarasu (kanon, Itachi): göz teması GEREKMEZ — kullanıcıdan bir karga seli boşalır, kurbanı sarıp yutar ve
## onu savunmasız bırakır (sersem + hedefini kaybeder). Kargalar Itachi'nin kargaları (MsArts._crow), sonunda tüye dağılır.
func c_magen_shinkarasu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 26.0)
	if tt == null:
		return
	busy(c, 0.5)
	anim(c, "cast_out", 1.2)
	_eye_flash(c)
	var gm = _gen_power(c) * Eyes.genjutsu_land(c, tt, false)
	var crows = []
	var N = 34
	for k in N:
		after(k * 0.025, func():
			if not (is_instance_valid(c) and live(tt)):
				return
			var cr = MsArts._crow()
			get_tree().current_scene.add_child(cr)
			var from = c.global_position + Vector3.UP * 1.3 + Vector3(randf_range(-0.4, 0.4), randf_range(-0.3, 0.4), randf_range(-0.4, 0.4))
			cr.global_position = from
			cr.scale = Vector3.ONE * randf_range(0.8, 1.2)
			crows.append({"n": cr, "a": randf() * TAU, "r": randf_range(0.5, 1.6), "y": randf_range(0.3, 2.3), "w": randf_range(3.0, 6.0) * (1.0 if randf() < 0.5 else -1.0), "t": 0.0, "from": from}))
	var dur = 3.2
	every(dur, 1.0 / 30.0, func(i, _k):
		var cen = tt.global_position if live(tt) else c.global_position
		for cr in crows:
			var b = cr["n"]
			if not is_instance_valid(b):
				continue
			cr["t"] += 1.0 / 30.0
			cr["a"] += cr["w"] / 30.0
			var orbit = cen + Vector3(cos(cr["a"]) * cr["r"], cr["y"], sin(cr["a"]) * cr["r"])
			var prev = b.global_position
			var k = clampf(cr["t"] / 0.35, 0.0, 1.0)   # önce sel hâlinde hedefe akar, sonra etrafında döner
			b.global_position = (cr["from"] as Vector3).lerp(orbit, k * k * (3.0 - 2.0 * k)) if k < 1.0 else prev.lerp(orbit, 0.35)
			var dv = b.global_position - prev
			if dv.length() > 0.01 and absf(dv.normalized().y) < 0.97:   # büyük dünya koordinatında küçük fark kaybolmasın: birim yön
				b.look_at(b.global_position + dv.normalized() * 3.0, Vector3.UP)
			MsArts._flap(b, cr["t"] * 2.2)
		if i == 12 and gm > 0.0 and live(tt):
			# karga seli kurbanı yuttu: savunmasız
			st(tt, "stun", 2.4 * gm)
			st(tt, "fear", 3.0 * gm)
			if tt.has_method("lose_target"):
				tt.lose_target(3.0 * gm)
			_illusion(tt, 2.4 * gm, Color(0.3, 0.05, 0.08))
		if i % 10 == 5 and gm > 0.0 and live(tt):
			hit(c, tt.global_position + Vector3.UP, 0.8, inf(c, "magen_shinkarasu", 0.1, {"knock": 0.0}))
	, func():
		for cr in crows:
			var b = cr["n"]
			if is_instance_valid(b):
				FX.burst(b.global_position, {"amount": 5, "life": 1.2, "tex": FX.tex_leaf, "add": false, "cel": false, "size": 0.22, "vmin": 0.5, "vmax": 2.0, "gravity": Vector3(0, -1.5, 0), "spin": 300.0,
					"colors": [Color(0.05, 0.04, 0.07), Color(0.05, 0.04, 0.07, 0)]})
				b.queue_free())
	Sfx.play("genjutsu", tt.global_position, 1.2)


## Magen: Kasegui no Jutsu (kanon): önce Genjutsu: Sharingan (GÖZ TEMASI) — yanılsamada kurbanın bedenine yukarıdan dev kazıklar
## çakılır, hareket özgürlüğü elinden alınır; acı gerçektir (işkence). Kazıklar yanılsamadır: yarı saydam kızıl-kara.
func c_magen_kasegui_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 22.0)
	if tt == null:
		return
	busy(c, 0.5)
	_eye_flash(c)
	var gm = _gen_power(c) * Eyes.genjutsu_land(c, tt, true)
	if gm <= 0.0:
		return
	var dur = 3.5 * gm
	st(tt, "bind", dur)
	_illusion(tt, dur, Color(0.5, 0.0, 0.03))
	var cen = tt.global_position
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.0, 0.02, 0.92)
	mat.emission_enabled = true
	mat.emission = Color(0.75, 0.02, 0.06)
	mat.emission_energy_multiplier = 1.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var stakes = []
	for k in 6:
		after(0.12 + k * 0.11, func():
			if not live(tt):
				return
			var a = k * TAU / 6.0 + randf_range(-0.3, 0.3)
			var tilt = randf_range(0.35, 0.65)
			var dir = Vector3(cos(a) * sin(tilt), -cos(tilt), sin(a) * sin(tilt)).normalized()   # yukarıdan, eğik çakılır
			var through = tt.global_position + Vector3.UP * randf_range(0.6, 1.5)
			var b = MB.new()
			b.add("cone", Vector3(0, 0, -1.6), Vector3(0.22, 1.0, 0.22), Color.WHITE, Vector3(-90, 0, 0), 6)
			b.add("cyl", Vector3(0, 0, 0.6), Vector3(0.26, 3.4, 0.26), Color.WHITE, Vector3(90, 0, 0), 6)
			b.add("cyl", Vector3(0, 0, 2.35), Vector3(0.36, 0.14, 0.36), Color.WHITE, Vector3(90, 0, 0), 8)   # çakılan baş
			var mi = MeshInstance3D.new()
			mi.mesh = b.build(null)
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			get_tree().current_scene.add_child(mi)
			var start = through - dir * 5.0
			mi.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.FORWARD), start)
			var end = through + dir * 0.9
			var tw = mi.create_tween()
			tw.tween_property(mi, "global_position", end, 0.09).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			tw.tween_callback(func():
				VFX.star(through, Color(0.9, 0.1, 0.12), 1.2, 0.1)
				FX.burst(through, {"amount": 10, "life": 0.5, "size": 0.18, "vmin": 2.0, "vmax": 5.0, "gravity": Vector3(0, -6, 0), "colors": [Color(0.7, 0.02, 0.04), Color(0.3, 0.0, 0.02, 0)]})
				shake(0.12)
				Sfx.play("kunai", through, 0.6))
			stakes.append(mi))
	# işkence: acı gerçek — süre boyunca tik hasarı, kurban kıvranır
	every(dur, 0.5, func(i, _k):
		if live(tt):
			hit(c, tt.global_position + Vector3.UP, 0.8, inf(c, "magen_kasegui_no_jutsu", 0.12, {"knock": 0.0, "kind": "light"}))
			if i % 2 == 0 and tt.get("model"):
				tt.model.play("hit", 0.05, 0.8, true), func():
		for mi in stakes:
			if is_instance_valid(mi):
				var tw = mi.create_tween()
				tw.tween_property(mi, "scale", Vector3(0.05, 0.05, 1.0), 0.3)
				tw.tween_callback(mi.queue_free))
	if Game.world and tt == Game.player:
		Game.world.env.flash_tint(Color(0.35, 0.0, 0.05, 0.3), 1.2)
	Sfx.play("genjutsu", cen, 0.8)
