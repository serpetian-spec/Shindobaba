class_name PathJutsu
extends ClanJutsu
## Efsane Yolları teknikleri (LegendPaths): kanon imza teknikleri, her biri kendi koreografisi ve gerçek oyun etkisiyle.
## Jutsu.execute önce "p_<id>" arar. Yardımcılar ClanJutsu'dan gelir (every, after, hit, st, spike, tether, decoy...).
##   Yılan Yolu: yılanlar kollardan fışkırıp bağlar/çeker, Rashōmon kapıları gerçekten engel olur, Kusanagi 25 m uzar,
##               lanetli mühür aşamaları güç verip can eritir, Yamata'da sekiz baş ayrı ayrı saldırır, Edo Tensei'de ölü ninjalar savaşır.
##   Silah Ustası Yolu: parşömenden gerçek silah yağmuru, zincirle çekme/kancalanma, telli silah fırtınası, demir yelpaze kalkanı,
##               gökten dev topuz, efsanevi Bashōsen'in dört sargısı.

const PSTYLE := {
	"sen_ei_jashu": "two_palm", "jagei_jubaku": "sense", "hebi_bunshin_no_jutsu": "clone", "sen_ei_tajashu": "two_palm",
	"kuchiyose_rashomon": "summon", "kusanagi_kuchi": "breath", "gogyo_fuin": "palm", "sen_ei_ranjashu": "ground",
	"ten_no_juin": "power", "juin_ni_no_dankai": "power", "mandara_no_jin": "breath", "orochimaru_ryu_no_kawarimi_no_jutsu": "power",
	"hakuja_sennin_modo": "power", "kuchiyose_sanju_rashomon": "summon", "yamata_no_jutsu": "power", "kuchiyose_edo_tensei": "summon",
	"sojasosai_no_jutsu": "sense",
	"buki_kuchiyose": "scroll", "tesso_kusari": "throw", "soshoryu": "scroll", "tekkosen": "summon", "ito_buki_arashi": "spin",
	"kuchiyose_tetsuzan": "summon", "bashosen_kaze_no_maki": "two_palm", "bashosen_hi_no_maki": "two_palm",
	"bashosen_rai_no_maki": "two_palm", "bashosen_mizu_no_maki": "two_palm",
	# Şifacı Yolu
	"senpuku": "ground", "shikon_no_jutsu": "summon", "saikan_chushutsu_no_jutsu": "medical", "dokugiri": "breath",
	"ranshinsho": "palm", "chakura_no_mesu": "medical", "in_yu_shometsu": "medical", "sozo_saisei": "power",
	# Sekiz Kapı Yolu
	"omote_renge": "rush", "ura_renge": "rush", "hachimon_tonko_no_jin": "power", "asakujaku": "rush", "hirudora": "two_palm",
	"sekizo": "charge", "yagai": "power",
	# Kâğıt Yolu
	"kami_bunshin": "clone", "kami_chocho": "palm", "kami_tsubasa": "power", "shikigami_no_mai": "spin", "kami_yari": "ground",
	"kami_no_shisha_no_jutsu": "summon", "kami_shuriken": "throw",
	# Akademi / genel
	"gofu_kekkai": "seal", "mizu_bunshin_no_jutsu": "clone", "nan_no_kaizo": "power", "narikawari_no_jutsu": "clone", "sanzengarasu_no_jutsu": "sense", "sly_mind_affect_technique": "sense", "sosai_no_ne": "palm", "soshujin": "throw", "suiken": "rush", "suiton_homatsu_rappa": "breath", "suiton_kokuu_no_jutsu": "breath", "suiton_mizu_shibari": "palm", "suiton_mizu_shuriken": "throw", "suiton_mizuame_nabara": "breath", "suiton_mizurappa": "breath", "suiton_suiben": "palm", "suiton_suidan_no_jutsu": "breath", "suiton_suisandan": "breath", "suiton_takitsubo_no_jutsu": "ground", "suiton_teppodama": "breath", "tsukikage": "rush", "tsutenkyaku": "rush", "uchi_naru_sakura": "power", "water_release_wild_water_wave": "breath", "zankukyokuha": "two_palm", "zessenbaku": "palm", "zessenzan": "palm",
	"futon_hanachiri_mai": "spin", "genjutsu_suzune_bunshin": "sense", "kage_buyo": "rush", "karasu_bunshin_no_jutsu": "clone", "kawazu_kumite": "power", "kawazu_tataki": "rush", "konoha_shofu": "rush", "kumo_ryu_omotegiri": "rush", "kumo_ryu_uragiri": "rush", "kumo_shibari": "palm", "kumo_soka": "palm", "kumogakure_taijutsu_okami_ringu": "spin", "kyomeisen": "palm", "mizuame_teppo": "breath", "nekozume": "rush", "okasho": "rush", "raigeki": "rush", "raigyaku_suihei_choppu": "rush", "raikyu": "palm", "raiton_ikazuchi_unagi": "palm", "raiton_raiju_tsuiga": "palm", "rakanken": "rush", "shikomishindan": "throw", "shishi_rendan": "rush",
	"bubble_clone_technique": "clone", "bubitorappu": "ground", "chakura_kontororu_baku": "palm", "earth_release_rock_shelter": "ground", "fujinheki": "two_palm", "futon_fujin_no_jutsu": "breath", "futon_toppa": "breath", "genjutsu_shibari": "sense", "hayanie": "rush", "jouro_senbon": "throw", "juha_sho": "spin", "kamaitachi_no_jutsu": "spin", "konoha_daisenpu": "rush", "konoha_otoshi": "rush", "kaeru_kaeru_no_jutsu": "palm",
	"doton_renga_no_jutsu": "ground", "doton_sazareishi": "palm", "doton_shinju_zanshu_no_jutsu": "ground", "kasumi_jusha_no_jutsu": "sense", "oboro_bunshin_no_jutsu": "clone", "doton_tobi_tsubute": "ground", "doton_dosekiryu": "ground", "doton_retsudo_tensho": "ground", "futon_reppusho": "palm", "futon_kazekiri_no_jutsu": "palm", "katon_endan": "breath",
	"kage_shuriken_no_jutsu": "throw", "kage_senbon": "throw", "konoha_senpu": "rush", "konoha_reppu": "rush", "dainamikku_entori": "rush",
	"zankuha": "two_palm", "sennen_goroshi": "rush", "kanashibari_no_jutsu": "sense",
	# Kurbağa Bilgesi Yolu
	"gamayudan": "breath", "kebari_senbon": "power", "ranjishigami_no_jutsu": "sense", "hari_jizo": "power",
	"kuchiyose_gamaguchi_shibari": "summon", "katon_gamayu_endan": "breath", "senpo_kawazu_naki": "sense",
}

const SNAKE := Color(0.42, 0.3, 0.5)
const SNAKE_BELLY := Color(0.78, 0.72, 0.55)

static var _pinst: PathJutsu = null
static var _mcache := {}


static func get_pinst() -> PathJutsu:
	if _pinst == null or not is_instance_valid(_pinst):
		_pinst = PathJutsu.new()
		_pinst.name = "PathJutsu"
		Jutsu.add_child(_pinst)
	return _pinst


static func handles_path(id: String) -> bool:
	return get_pinst().has_method("p_" + id)


static func cast_path(c: Node3D, id: String, t: Node3D) -> void:
	get_pinst().call("p_" + id, c, t)


# ================================================================== yardımcılar
func hand_pos(c: Node3D, right := true) -> Vector3:
	var m = c.get("model")
	if m and is_instance_valid(m) and m.skel:
		var bi = m.skel.find_bone("RightHand" if right else "LeftHand")
		if bi >= 0:
			return (m.skel.global_transform * m.skel.get_bone_global_pose(bi)).origin
	var side = c.face_dir().cross(Vector3.UP).normalized()
	return c.global_position + Vector3.UP * 1.2 + c.face_dir() * 0.4 + side * (0.3 if right else -0.3)


func bone_attach(c: Node3D, bone: String) -> Node3D:
	var m = c.get("model")
	if m == null or not is_instance_valid(m) or m.skel == null or m.skel.find_bone(bone) < 0:
		return null
	var ba = BoneAttachment3D.new()
	ba.bone_name = bone
	m.skel.add_child(ba)
	return ba


func cached(key: String, build: Callable) -> ArrayMesh:
	if not _mcache.has(key):
		var b: MB = build.call()
		_mcache[key] = b.build(Props.toon())
	return _mcache[key]


func mi_of(mesh: Mesh, mat: Material = null) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	if mat:
		mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func scene_add(n: Node3D, pos: Vector3) -> Node3D:
	get_tree().current_scene.add_child(n)
	n.global_position = pos
	return n


func toward(n: Node3D, dir: Vector3) -> void:
	if dir.length() > 0.01:
		n.look_at(n.global_position + dir, Vector3.UP if absf(dir.normalized().y) < 0.95 else Vector3.RIGHT)


## Yılan başı (ileri = -Z): uzun kafa, açık çene, sivri dişler, sarı gözler, çatal dil
func snake_head(col: Color, size: float) -> Node3D:
	var key = "shead_%s" % col.to_html(false)
	var mesh = cached(key, func():
		var b = MB.new()
		b.add_grad("sphere", Vector3(0, 0, 0), Vector3(0.62, 0.42, 0.95), col.lightened(0.12), col.darkened(0.25), Vector3.ZERO, 10)
		b.add_grad("sphere", Vector3(0, 0.04, -0.42), Vector3(0.48, 0.24, 0.62), col.lightened(0.08), col.darkened(0.2), Vector3(-8, 0, 0), 9)
		b.add("sphere", Vector3(0, -0.15, -0.38), Vector3(0.42, 0.12, 0.6), SNAKE_BELLY, Vector3(22, 0, 0), 8)   # alt çene (açık)
		for sx in [-1.0, 1.0]:
			b.add("sphere", Vector3(0.2 * sx, 0.16, -0.22), Vector3(0.13, 0.1, 0.16), Color(1.0, 0.85, 0.15), Vector3.ZERO, 6)
			b.add("box", Vector3(0.2 * sx, 0.165, -0.27), Vector3(0.02, 0.09, 0.03), Color(0.05, 0.03, 0.02))
			b.add("cone", Vector3(0.12 * sx, -0.04, -0.62), Vector3(0.05, 0.2, 0.05), Color(1, 1, 0.95), Vector3(180, 0, 0), 4)
			b.add("box", Vector3(0.05 * sx, -0.08, -1.0), Vector3(0.03, 0.015, 0.16), Color(0.85, 0.12, 0.2), Vector3(0, 18 * sx, 0))
		b.add("box", Vector3(0, -0.08, -0.82), Vector3(0.035, 0.015, 0.3), Color(0.85, 0.12, 0.2))
		return b)
	var root = Node3D.new()
	var mi = mi_of(mesh)
	mi.scale = Vector3.ONE * size * 1.3
	root.add_child(mi)
	return root


## Kafası ve kıvrılan gövdesiyle yılan: döndürülen baş düğümünü hareket ettir, gövde izini takip eder
func make_snake(from: Vector3, col: Color, size: float, segs := 10) -> Node3D:
	var head = Node3D.new()
	scene_add(head, from)
	head.add_child(snake_head(col, size))
	var body = VfxSerpent.new()
	body.head = head
	body.count = segs
	body.spacing = 0.42 * size
	body.radius = 0.32 * size
	body.mat = Props.toon_color(col)
	get_tree().current_scene.add_child(body)
	return head


## Başı a'dan b'ye kıvrılarak taşı (sinüs sapmalı yol)
func slither(head: Node3D, a: Vector3, b: Vector3, dur: float, wiggle := 0.8, done := Callable()) -> void:
	var d = b - a
	var side = d.cross(Vector3.UP).normalized()
	if side.length() < 0.1:
		side = Vector3.RIGHT
	every(dur, 1.0 / 40.0, func(_i, k):
		if not is_instance_valid(head):
			return
		var p = a.lerp(b, k) + side * sin(k * TAU * 1.5) * wiggle * (1.0 - k)
		var nx = a.lerp(b, minf(1.0, k + 0.04)) + side * sin((k + 0.04) * TAU * 1.5) * wiggle * (1.0 - k)
		head.global_position = p
		toward(head, nx - p), func():
		if is_instance_valid(head):
			head.global_position = b
		if done.is_valid():
			done.call())


func poison(c: Node3D, e: Node3D, id: String, mul: float, dur := 4.0) -> void:
	hit(c, e.global_position + Vector3.UP * e.height * 0.6, e.radius + 0.6, inf(c, id, mul, {"knock": 1.0, "kind": "light", "burn": dur, "hitstop": 0.03}))
	FX.burst(e.global_position + Vector3.UP * e.height * 0.6, {"amount": 8, "life": 0.5, "size": 0.5, "vmin": 1, "vmax": 3,
		"colors": [Color(0.6, 0.25, 0.75), Color(0.25, 0.6, 0.2, 0)]})


func cone_enemies(c: Node3D, d: Vector3, rng: float, deg: float) -> Array:
	var out = []
	for e in enemies_near(c, c.global_position, rng):
		var v = e.global_position - c.global_position
		v.y = 0
		if v.length() < 0.5 or rad_to_deg(v.normalized().angle_to(d)) <= deg * 0.5:
			out.append(e)
	out.sort_custom(func(a, b): return a.global_position.distance_to(c.global_position) < b.global_position.distance_to(c.global_position))
	return out


## Hedefi c'ye doğru çek (dur saniyede), önünde durur
func pull_to(c: Node3D, e: Node3D, dur: float, stop := 1.6) -> void:
	var from = e.global_position
	every(dur, 1.0 / 40.0, func(_i, k):
		if not live(e) or not is_instance_valid(c):
			return
		var to = c.global_position + (from - c.global_position).normalized() * (stop + e.radius)
		e.global_position = gp(from.lerp(to, k * k)), Callable())


func summon_circle(pos: Vector3, r: float, col: Color, dur: float) -> void:
	ground_disc(pos, r, col, dur, 2, 12)
	FX.smoke_puff(pos + Vector3.UP * 0.6, r * 0.35, 14)
	Sfx.play("poof", pos, 0.8)


# ================================================================== YILAN YOLU
## Sen'ei Jashu: iki yılan yenden fırlar, hedefi ısırıp sarar, sonra seni ona değil onu sana çeker
func p_sen_ei_jashu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	busy(c, 0.9)
	anim(c, "cross", 1.2)
	Sfx.play("whoosh", c.global_position, 0.7)
	var to = tt.global_position + Vector3.UP * tt.height * 0.55 if tt else c.global_position + Vector3.UP * 1.1 + fwd(c, t) * 16.0
	for k in 2:
		var from = hand_pos(c, k == 0)
		var head = make_snake(from, SNAKE, 0.9, 14)
		var side = fwd(c, t).cross(Vector3.UP).normalized() * (0.6 if k == 0 else -0.6)
		slither(head, from, to + side, 0.32, 1.2, func():
			if tt and live(tt):
				poison(c, tt, "sen_ei_jashu", 0.45, 4.0)
				st(tt, "bind", 2.4)
			else:
				FX.dust(gp(to), 0.8))
		after(0.32, func():
			if is_instance_valid(head) and tt and live(tt):
				every(1.6, 1.0 / 30.0, func(_i, _k):
					if is_instance_valid(head) and live(tt):
						head.global_position = tt.global_position + Vector3.UP * tt.height * 0.55 + side * 0.5, Callable()))
		fade_free(head, 2.2, 0.2)
	if tt:
		Combat.popup_text(tt.global_position + Vector3.UP * (tt.height + 0.8), "Yılanlar sardı!", Color(0.7, 0.5, 0.85))
		after(0.5, func():
			if live(tt):
				pull_to(c, tt, 0.5))


## Jagei Jubaku: arkanda dev bir yılan hayali yükselir, bakışınla dehşete düşen herkes donar
func p_jagei_jubaku(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 0.8)
	var victims = cone_enemies(c, d, 18.0, 110.0)
	# bakıştan doğan illüzyon: arkasından yerden kıvrılarak yükselen dev mor yılan, ağzını açıp kurbanların üstüne eğilir
	var side = d.cross(Vector3.UP).normalized()
	var root_p = gp(c.global_position - d * 4.0)
	var head = make_snake(root_p + Vector3.DOWN * 2.0, Color(0.5, 0.25, 0.62), 3.2, 22)
	var top = root_p + Vector3.UP * 9.0 + side * 2.0
	var strike = c.global_position + d * 6.0 + Vector3.UP * 5.0
	var path = [root_p + side * 3.0 + Vector3.UP * 2.0, root_p - side * 2.5 + Vector3.UP * 5.0, top, strike]
	var seq = head.create_tween()
	for k in path.size():
		seq.tween_property(head, "global_position", path[k], 0.16 if k < 3 else 0.22).set_trans(Tween.TRANS_SINE)
	seq.tween_callback(func():
		toward(head, d + Vector3.DOWN * 0.6)
		VFX.shockwave(strike, Color(0.75, 0.4, 1.0), 9.0, 0.35, false, d))
	seq.tween_interval(1.0)
	seq.tween_property(head, "global_position", root_p + Vector3.DOWN * 6.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	seq.tween_callback(head.queue_free)
	every(0.6, 1.0 / 30.0, func(_i, _k):
		if is_instance_valid(head):
			var nx = head.global_position + d * 0.5 + Vector3.DOWN * 0.15
			head.look_at(nx, Vector3.UP))
	FX.burst(root_p + Vector3.UP * 0.5, {"amount": 40, "life": 1.2, "tex": FX.tex_smoke, "add": false, "size": 2.0, "radius": 3.0, "vmin": 1, "vmax": 3,
		"colors": [Color(0.35, 0.15, 0.45, 0.6), Color(0.2, 0.05, 0.25, 0)]})
	if Game.world and c is Player:
		Game.world.env.flash_tint(Color(0.35, 0.1, 0.45, 0.18), 1.4)
	VFX.screen_lines(0.5, 0.8, Color(0.6, 0.3, 0.8))
	Sfx.play("genjutsu", c.global_position, 0.6)
	FX.flash_sphere(c.global_position + Vector3.UP * 1.6 + d * 0.3, Color(1.0, 0.85, 0.15), 0.6, 0.25)
	for e in victims:
		st(e, "stun", 3.5)
		st(e, "fear", 3.5)
		Combat.popup_text(e.global_position + Vector3.UP * (e.height + 0.8), "Dehşet!", Color(0.85, 0.6, 1.0))
		hit(c, e.global_position + Vector3.UP, e.radius + 0.4, inf(c, "jagei_jubaku", 0.2, {"knock": 0.0, "kind": "light"}))


## Yılan klonu: yerinde bir klon kalır, sen geri sıçrarsın; klon vurulunca yılan sürüsüne dağılıp çevreyi ısırır
func p_hebi_bunshin_no_jutsu(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var at = c.global_position
	FX.smoke_puff(at + Vector3.UP, 0.8, 10)
	decoy(c, at, 12.0, func(pos: Vector3):
		FX.burst(pos + Vector3.UP, {"amount": 20, "life": 0.5, "size": 0.6, "vmin": 2, "vmax": 6, "colors": [Color(0.6, 0.5, 0.7), Color(0.3, 0.25, 0.35, 0)]})
		var near = enemies_near(c, pos, 11.0)
		for k in 8:
			var e = near[k % near.size()] if not near.is_empty() else null
			var to = e.global_position + Vector3.UP * 0.6 if e else pos + Vector3(cos(k * 0.785), 0, sin(k * 0.785)) * 7.0
			var head = make_snake(pos + Vector3.UP * 0.6, SNAKE.lightened(0.1), 0.5, 7)
			slither(head, pos + Vector3.UP * 0.6, to, 0.35 + k * 0.03, 0.6, func():
				if e and live(e):
					poison(c, e, "hebi_bunshin_no_jutsu", 0.25, 3.0))
			fade_free(head, 0.8, 0.2))
	c.global_position = gp(at - d * 6.0)
	if c is Player:
		c.combat.invuln = 0.4
	FX.smoke_puff(c.global_position + Vector3.UP, 0.6, 8)


## Sen'ei Tajashu: iki koldan onlarca yılan yelpaze gibi açılır, menzildeki 6 düşmana kadar hepsini sarar
func p_sen_ei_tajashu(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 1.0)
	anim(c, "cross", 1.0)
	var victims = cone_enemies(c, d, 24.0, 140.0).slice(0, 6)
	Sfx.play("whoosh", c.global_position, 0.6)
	var n = 12
	for k in n:
		var right = k % 2 == 0
		var from = hand_pos(c, right)
		var e = victims[k % victims.size()] if not victims.is_empty() else null
		var ang = deg_to_rad(-60.0 + 120.0 * float(k) / (n - 1))
		var free_to = from + d.rotated(Vector3.UP, ang) * 20.0
		var to = e.global_position + Vector3.UP * e.height * 0.5 + Vector3(randf_range(-0.4, 0.4), randf_range(-0.3, 0.3), randf_range(-0.4, 0.4)) if e else free_to
		var head = make_snake(from, SNAKE.lerp(Color(0.3, 0.45, 0.25), randf() * 0.5), 0.7, 12)
		after(k * 0.03, func():
			if not is_instance_valid(head):
				return
			slither(head, from, to, 0.38, 1.6, func():
				if e and live(e):
					poison(c, e, "sen_ei_tajashu", 0.22, 4.0)
					st(e, "bind", 3.0)
				else:
					FX.dust(gp(to), 0.6)
					hit(c, to, 1.5, inf(c, "sen_ei_tajashu", 0.25, {"knock": 3.0, "kind": "light"}))))
		fade_free(head, 3.0, 0.25)
	for e in victims:
		Combat.popup_text(e.global_position + Vector3.UP * (e.height + 0.8), "Yılan ağı!", Color(0.7, 0.5, 0.85))


## Rashōmon kapısı: şeytan yüzlü dev kapı yerden fırlar (önündekileri havaya savurur), saldırıları gerçekten durdurur
func rashomon_gate(c: Node3D, pos: Vector3, d: Vector3, s: float, dur: float, id: String) -> Node3D:
	var mesh = cached("rashomon", func():
		var b = MB.new()
		var wood = Color(0.55, 0.12, 0.1)
		b.add("box", Vector3(0, 5.0, 0), Vector3(9.0, 10.0, 1.1), Color(0.32, 0.3, 0.33))    # kapı kanatları (demir)
		b.add("box", Vector3(0, 5.0, -0.1), Vector3(0.18, 10.0, 1.2), Color(0.15, 0.14, 0.16))
		for sx in [-1.0, 1.0]:
			b.add("box", Vector3(5.0 * sx, 6.0, 0), Vector3(1.1, 12.0, 1.6), wood)                 # direkler
			b.add("box", Vector3(5.0 * sx, 0.4, 0), Vector3(1.6, 0.8, 2.0), Color(0.25, 0.22, 0.2))
			for k in 4:
				b.add("sphere", Vector3(2.2 * sx, 1.6 + k * 2.3, -0.62), Vector3(0.32, 0.32, 0.25), Color(0.7, 0.6, 0.25), Vector3.ZERO, 6)   # perçinler
		b.add("box", Vector3(0, 12.3, 0), Vector3(12.5, 0.9, 2.2), wood)                        # üst kiriş
		b.add("box", Vector3(0, 13.2, 0), Vector3(14.0, 0.5, 2.8), Color(0.18, 0.15, 0.15))
		# şeytan yüzü
		b.add_grad("sphere", Vector3(0, 7.2, -0.7), Vector3(4.2, 4.0, 1.4), Color(0.75, 0.25, 0.18), Color(0.4, 0.1, 0.08), Vector3.ZERO, 12)
		for sx in [-1.0, 1.0]:
			b.add("sphere", Vector3(0.95 * sx, 7.9, -1.3), Vector3(0.75, 0.45, 0.3), Color(1.0, 0.9, 0.2), Vector3(0, 0, 15 * sx), 8)
			b.add("cone", Vector3(1.4 * sx, 9.4, -0.9), Vector3(0.45, 1.7, 0.45), Color(0.9, 0.85, 0.7), Vector3(0, 0, -25 * sx), 6)
			b.add("cone", Vector3(0.7 * sx, 6.0, -1.35), Vector3(0.2, 0.7, 0.2), Color(1, 1, 0.95), Vector3(180, 0, 0), 4)
		b.add("box", Vector3(0, 6.15, -1.3), Vector3(2.2, 0.35, 0.3), Color(0.1, 0.02, 0.02))
		return b)
	var gate = mi_of(mesh)
	gate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var root = Node3D.new()
	scene_add(root, gp(pos) - Vector3.UP * 13.0 * s)
	root.add_child(gate)
	gate.scale = Vector3.ONE * s
	toward(root, -d)
	# engel: gövde ve mermiler geçemez
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	var cs = CollisionShape3D.new()
	var bx = BoxShape3D.new()
	bx.size = Vector3(12.0, 13.0, 1.6) * s
	cs.shape = bx
	cs.position = Vector3(0, 6.5, 0) * s
	sb.add_child(cs)
	root.add_child(sb)
	var tw = root.create_tween()
	tw.tween_property(root, "global_position", gp(pos), 0.28).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	VFX.cracks(gp(pos), 8.0 * s)
	FX.dust(gp(pos), 2.0 * s)
	VFX.debris(gp(pos), Color(0.45, 0.38, 0.3), 18, 12.0, 0.6)
	shake(0.7 * s)
	Sfx.play("earth", pos, 0.6)
	for e in enemies_near(c, pos, 6.5 * s):
		hit(c, e.global_position + Vector3.UP, e.radius + 0.5, inf(c, id, 0.6, {"knock": 10.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.06}))
	# kapıya çarpan mermiler patlayıp söner
	var catch_r = 7.0 * s
	every(dur, 0.05, func(_i, _k):
		if not is_instance_valid(root):
			return
		for pr in get_tree().get_nodes_in_group("projectiles"):
			if pr is Projectile and is_instance_valid(pr) and pr.shooter != c and pr.global_position.distance_to(root.global_position + Vector3.UP * 6.0 * s) < catch_r:
				FX.hit_spark(pr.global_position, Color(1, 0.8, 0.4), 1.2)
				pr.queue_free(), func():
		if is_instance_valid(root):
			var t2 = root.create_tween()
			t2.tween_property(root, "global_position", root.global_position - Vector3.UP * 14.0 * s, 0.5).set_ease(Tween.EASE_IN)
			t2.tween_callback(root.queue_free)
			FX.smoke_puff(root.global_position + Vector3.UP * 3.0, 2.0 * s, 16))
	return root


func p_kuchiyose_rashomon(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 0.6)
	summon_circle(c.global_position + d * 5.0, 5.0, Color(0.85, 0.25, 0.2), 0.6)
	after(0.2, func(): rashomon_gate(c, c.global_position + d * 5.0, d, 1.0, 8.0, "kuchiyose_rashomon"))


func p_kuchiyose_sanju_rashomon(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 1.0)
	summon_circle(c.global_position + d * 6.0, 7.0, Color(0.85, 0.25, 0.2), 1.0)
	for k in 3:
		var pos = c.global_position + d * (5.0 + k * 3.2)
		var s = 1.0 + k * 0.25
		after(0.15 + k * 0.28, func(): rashomon_gate(c, pos, d, s, 10.0, "kuchiyose_sanju_rashomon"))
	after(1.0, func(): VFX.slowmo(0.5, 0.4))


## Kusanagi: ağızdan çıkan yılan kılıcı dişlerinde tutar, kılıç 25 m uzayıp hattı deler; sonra 15 sn elinde kalır
func kusanagi_blade(len_: float) -> MeshInstance3D:
	var mesh = cached("kusanagi", func():
		var b = MB.new()
		b.add_grad("box", Vector3(0, 0, -0.5), Vector3(0.12, 0.025, 1.0), Color(1.0, 1.0, 1.0), Color(0.78, 0.85, 0.95))
		b.add("box", Vector3(0, 0.0, -0.5), Vector3(0.04, 0.03, 1.0), Color(0.6, 0.7, 0.9))   # oluk
		b.add("box", Vector3(0, 0, 0.04), Vector3(0.2, 0.07, 0.06), Color(0.7, 0.6, 0.3))
		b.add("cyl", Vector3(0, 0, 0.16), Vector3(0.05, 0.22, 0.05), Color(0.2, 0.12, 0.25), Vector3(90, 0, 0), 6)
		return b)
	var mi = mi_of(mesh)
	mi.scale = Vector3(1, 1, len_)
	return mi


func p_kusanagi_kuchi(c: Node3D, t: Node3D) -> void:
	var d = Jutsu._aim(c, t)
	busy(c, 1.1)
	if c is Player and t:
		c.combat.face_to(t)
	var mouth = Jutsu._mouth(c)
	var head = make_snake(mouth, Color(0.55, 0.45, 0.6), 0.45, 6)
	slither(head, mouth, mouth + d * 1.6, 0.25, 0.1)
	var blade = kusanagi_blade(1.0)
	head.add_child(blade)
	blade.position = Vector3(0, -0.05, -0.35)
	Sfx.play("clink", mouth, 0.7)
	var hits = []
	after(0.28, func():
		if not is_instance_valid(blade):
			return
		VFX.trail(blade, 0.5, Color(1, 1, 1), Color(0.75, 0.85, 1.0), Color(0.5, 0.6, 1.0, 0.0), 12, 0.5)
		VFX.star(mouth + d * 0.6, Color(0.85, 0.9, 1.0), 2.5, 0.15)
		var tw = blade.create_tween()
		tw.tween_property(blade, "scale", Vector3(1.6, 1.6, 25.0), 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.25)
		tw.tween_property(blade, "scale", Vector3(1, 1, 0.6), 0.2)
		Sfx.play("whoosh", mouth, 1.4)
		after(0.12, func():
			for k in 17:
				var p = mouth + d * (1.5 + k * 1.5)
				for h in hit(c, p, 0.9, inf(c, "kusanagi_kuchi", 1.6, {"knock": 6.0, "kind": "heavy", "pierce_guard": true, "burn": 2.0, "hitstop": 0.08}), hits):
					hits.append(h)
					FX.hit_spark(h.global_position + Vector3.UP, Color(0.85, 0.9, 1.0), 1.4)
			FX.speed_lines(mouth + d * 12.0, d)
			for k in 5:
				VFX.shockwave(mouth + d * (4.0 + k * 5.0), Color(0.8, 0.9, 1.0), 2.5, 0.25, false, d)
			shake(0.4)))
	fade_free(head, 1.0, 0.2)
	# kılıç 15 sn sağ elde: vuruşlar uzar ve güçlenir
	if c is Player:
		Buffs.add("kusanagi", 15.0, {"melee": 1.35, "reach": 1.6})
		var ba = bone_attach(c, "RightHand")
		if ba:
			var hb = kusanagi_blade(1.15)
			ba.add_child(hb)
			hb.position = Vector3(0, 0.05, 0)
			hb.rotation_degrees = Vector3(-90, 0, 0)
			after(15.0, func():
				if is_instance_valid(ba):
					ba.queue_free())


## Gogyō Fūin: beş parmak ucunda beş element yanar; karnına bastırılan mühür chakrayı 12 sn kilitler
func p_gogyo_fuin(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 9.0)
	if tt == null:
		Hud.msg("Gogyō Fūin: hedef en fazla 9 metrede olmalı", Color(0.85, 0.75, 1.0))
		return
	var cols = [Color(1, 0.4, 0.1), Color(0.3, 0.6, 1.0), Color(0.6, 1.0, 0.7), Color(0.75, 0.55, 0.3), Color(1.0, 1.0, 0.4)]
	var hp_ = hand_pos(c, true)
	var dots = []
	for k in 5:
		var s = MeshInstance3D.new()
		s.mesh = VFX._sphere(0.09, 10, 6)
		s.material_override = glow(cols[k])
		scene_add(s, hp_ + Vector3(cos(k * 1.256) * 0.18, sin(k * 1.256) * 0.18 + 0.05, 0))
		dots.append(s)
	busy(c, 0.8)
	after(0.35, func():
		if not live(tt):
			return
		c.global_position = gp(tt.global_position - (tt.global_position - c.global_position).normalized() * (tt.radius + 0.9))
		if c is Player:
			c.combat.face_to(tt)
		anim(c, "cross", 2.0)
		var belly = tt.global_position + Vector3.UP * tt.height * 0.5
		for k in 5:
			var s: MeshInstance3D = dots[k]
			if is_instance_valid(s):
				var tw = s.create_tween()
				tw.tween_property(s, "global_position", belly + Vector3(cos(k * 1.256) * 0.3, sin(k * 1.256) * 0.3, 0), 0.12)
				tw.tween_callback(s.queue_free)
		after(0.12, func():
			if not live(tt):
				return
			hit(c, belly, tt.radius + 0.5, inf(c, "gogyo_fuin", 0.9, {"knock": 7.0, "kind": "heavy", "hitstop": 0.12}))
			seal_points(tt, 12.0, Color(0.85, 0.55, 1.0))
			var ring = ground_disc(belly - Vector3.UP * tt.height * 0.5, 2.2, Color(0.8, 0.5, 1.0), 1.2, 2, 5)
			ring.global_position = belly
			VFX.shockwave(belly, Color(0.85, 0.6, 1.0), 4.0, 0.3, false, (belly - c.global_position).normalized())
			Combat.popup_text(belly + Vector3.UP * 1.2, "Beş Element Mühürü: chakra kilitlendi!", Color(0.85, 0.65, 1.0))
			Sfx.play("seal", belly, 0.8)))


## Sen'ei Ranjashu: koni boyunca üç dalga halinde yerden vahşi yılanlar fışkırıp dalar
func p_sen_ei_ranjashu(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 0.7)
	VFX.cracks(c.global_position + d * 2.0, 4.0)
	var hits = {}
	for wave in 3:
		for k in 7:
			var ang = deg_to_rad(-26.0 + 52.0 * float(k) / 6.0 + randf_range(-4, 4))
			var dist = 6.0 + wave * 7.0 + randf_range(-1.5, 1.5)
			var g = gp(c.global_position + d.rotated(Vector3.UP, ang) * dist)
			after(0.1 + wave * 0.22 + k * 0.02, func():
				var head = make_snake(g - Vector3.UP * 1.0, SNAKE.lerp(Color(0.25, 0.35, 0.2), randf()), 0.75, 9)
				var top = g + Vector3.UP * randf_range(3.5, 5.5) + d * 1.5
				var land = g + d * 4.5 - Vector3.UP * 1.2
				FX.dust(g, 0.6)
				slither(head, g - Vector3.UP * 1.0, top, 0.22, 0.3, func():
					slither(head, top, land, 0.3, 0.3))
				for e in enemies_near(c, g, 2.6):
					if not hits.has(e):
						hits[e] = true
						poison(c, e, "sen_ei_ranjashu", 0.55, 4.0)
						st(e, "slow", 4.0)
						hit(c, e.global_position + Vector3.UP, e.radius + 0.4, inf(c, "sen_ei_ranjashu", 0.25, {"knock": 3.0, "launch": 7.0, "kind": "heavy"}))
				fade_free(head, 0.9, 0.2))
	shake(0.4)
	Sfx.play("earth", c.global_position, 0.8)


## Lanetli mühür desenleri: boyun mühüründen bedene yayılan kara alev dilleri
func juin_marks(c: Node3D, col: Color, dur: float, spread: float) -> Array:
	var out = []
	var mat = flat_mat(col)
	for bone in ["Neck", "UpperChest", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "Head", "LeftUpperLeg", "RightUpperLeg"]:
		var ba = bone_attach(c, bone)
		if ba == null:
			continue
		var b = MB.new()
		var n = 3 if bone != "Head" else 2
		for k in n:
			var a = k * TAU / n + randf() * 0.6
			var r = 0.085 if bone in ["Neck", "Head"] else (0.13 if bone == "UpperChest" else 0.065)
			b.add("cone", Vector3(cos(a) * r, 0.05 + k * 0.04, sin(a) * r), Vector3(0.05, 0.16, 0.012), Color.WHITE, Vector3(0, rad_to_deg(-a), randf_range(-35, 35)), 4)
		var mi = mesh_of(b, mat)
		ba.add_child(mi)
		mi.scale = Vector3.ONE * 0.05
		var tw = mi.create_tween()
		tw.tween_interval(randf() * 0.25 + (0.0 if bone == "Neck" else 0.25))
		tw.tween_property(mi, "scale", Vector3.ONE * spread, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		out.append(ba)
	after(dur, func():
		for ba in out:
			if is_instance_valid(ba):
				ba.queue_free())
	return out


## Ten no Juin — 1. aşama: kara alev desenleri, güç ve hız; can yavaşça erir (canın %15'in altına inince söner)
func p_ten_no_juin(c: Node3D, _t: Node3D) -> void:
	var dur = 22.0
	juin_marks(c, Color(0.04, 0.02, 0.05), dur, 1.0)
	var a = FX.aura(c, Color(0.35, 0.08, 0.45), 1.3, Vector3(0, 0.9, 0), 0.0)
	Sfx.play("genjutsu", c.global_position, 0.5)
	VFX.shockwave(c.global_position + Vector3.UP, Color(0.4, 0.1, 0.5), 6.0, 0.35, true)
	if c is Player:
		Buffs.add("juin1", dur, {"melee": 1.3, "jutsu": 1.25, "speed": 1.15, "_desc": "her sn canın %1'i erir"})
		Hud.msg("Lanetli mühür uyandı: güç akıyor... ama bedel ağır.", Color(0.8, 0.55, 0.95))
	every(dur, 1.0, func(_i, _k):
		if is_instance_valid(c) and c.hp > c.max_hp * 0.15 and (not c is Player or Buffs.has("juin1")):
			c.hp -= c.max_hp * 0.01
		elif c is Player:
			Buffs.remove("juin1"), func():
		if is_instance_valid(a):
			a.emitting = false)


## 2. aşama: ten grileşir, sırttan el biçimli kanatlar açılır, uçabilirsin; güç patlar, can hızla erir
func hand_wing(right: bool) -> MeshInstance3D:
	var mesh = cached("handwing2", func():
		var b = MB.new()
		var sk = Color(0.52, 0.48, 0.58)
		b.add_grad("cyl", Vector3(0, 0.45, 0), Vector3(0.2, 0.9, 0.2), sk.lightened(0.1), sk.darkened(0.25), Vector3.ZERO, 8)   # bilek
		b.add_grad("sphere", Vector3(0, 1.15, 0), Vector3(0.78, 0.7, 0.2), sk.lightened(0.05), sk.darkened(0.3), Vector3.ZERO, 12)   # avuç
		for f in 5:
			var a = deg_to_rad(-62.0 + f * 31.0)
			var L = [0.95, 1.5, 1.7, 1.5, 1.1][f]
			var base = Vector3(sin(a) * 0.3, 1.3 + cos(a) * 0.3, 0)
			var dir = Vector3(sin(a), cos(a), 0)
			b.add_grad("cyl", base + dir * L * 0.25, Vector3(0.13, L * 0.5, 0.11), sk.lightened(0.05), sk.darkened(0.25), Vector3(0, 0, -rad_to_deg(a)), 6)
			b.add_grad("cone", base + dir * L * 0.72, Vector3(0.12, L * 0.48, 0.1), sk, sk.darkened(0.35), Vector3(0, 0, -rad_to_deg(a)), 6)
			b.add("cone", base + dir * (L * 0.98), Vector3(0.06, 0.16, 0.05), Color(0.12, 0.08, 0.14), Vector3(0, 0, -rad_to_deg(a)), 4)   # tırnak
		return b)
	var mi = mi_of(mesh)
	mi.scale = Vector3(-1 if not right else 1, 1, 1)
	return mi


const JUIN_FORMS := {
	"kanat": {"name": "Kanatlı Form", "skin": Color(0.56, 0.52, 0.6), "desc": "Sırttan el kanatlar: uçabilirsin (Space/Ctrl)",
		"mods": {"melee": 1.5, "jutsu": 1.4, "speed": 1.3}},
	"boynuz": {"name": "Boynuzlu Form", "skin": Color(0.8, 0.46, 0.38), "desc": "Alnından boynuzlar: jutsu ve genjutsu çok güçlü",
		"mods": {"jutsu": 1.8, "melee": 1.25, "speed": 1.15}},
	"kaya": {"name": "Kaya Deri", "skin": Color(0.86, 0.56, 0.3), "desc": "Sırtta kaya yumruları: darbelere dayanıklı, yumrukların ağır",
		"mods": {"melee": 1.9, "armor": 0.55, "speed": 1.05}},
	"orumcek": {"name": "Örümcek Formu", "skin": Color(0.46, 0.33, 0.26), "desc": "Sırttan iki çift ek kol: çok hızlı ve uzun erimli",
		"mods": {"melee": 1.6, "speed": 1.45, "reach": 1.4}},
}


## Lanetli mühür II beden parçaları: kemiğe (sırt/baş) bağlı, büyüyerek çıkar. Döner: silinecek düğümler
func juin_parts(c: Node3D, form: String) -> Array:
	var m = c.get("model")
	var out = []
	if m == null or m.skel == null:
		return out
	var sk: Skeleton3D = m.skel
	var chest_b = "UpperChest" if sk.find_bone("UpperChest") >= 0 else "Chest"
	var p_ch: Vector3 = m._grest(sk.find_bone(chest_b)).origin
	var skin_c: Color = JUIN_FORMS[form]["skin"]
	var dark = skin_c.darkened(0.35)
	var grow = func(node: Node3D, sc: Vector3):
		node.scale = sc * 0.05
		node.create_tween().tween_property(node, "scale", sc, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	match form:
		"kanat":
			for right in [true, false]:
				var sx = -1.0 if right else 1.0   # model uzayı: +X karakterin solu, -Z sırt
				var ba = m._attach(chest_b, Transform3D(Basis.IDENTITY, p_ch + Vector3(sx * 0.12, 0.08, -0.14)))
				var w = hand_wing(right)
				ba.get_child(0).add_child(w)
				w.rotation_degrees = Vector3(18, 180, 62 * sx)   # dışa-yukarı açılır, avuç geriye
				grow.call(w, Vector3(-0.62 if not right else 0.62, 0.62, 0.62))   # animedeki gibi: sırttan çıkan, gövdeyi aşmayan el kanatlar
				out.append(ba)
		"boynuz":
			var hb = sk.find_bone("Head")
			var p_h: Vector3 = m._grest(hb).origin
			var top = maxf(float(m.head_ab.end.y) - 0.03, p_h.y + 0.15) if m.head_ab.size != Vector3.ZERO else p_h.y + 0.2
			var mb = MB.new()
			for sx in [-1.0, 1.0]:
				for k in 2:
					var b0 = Vector3(sx * (0.045 + k * 0.05), top - 0.04 * k, 0.05 - k * 0.04)
					Loft.tube(mb, [b0, b0 + Vector3(sx * 0.03, 0.09, -0.02), b0 + Vector3(sx * 0.07, 0.16 - k * 0.04, -0.07)], [0.028 - k * 0.006, 0.018, 0.004], [dark, skin_c, Color(0.15, 0.1, 0.1)], 8, 3, true, false)
			var ba = m._attach("Head", Transform3D.IDENTITY)
			var mi = mesh_of(mb)
			ba.get_child(0).add_child(mi)
			out.append(ba)
		"kaya":
			var mb = MB.new()
			var rng = RandomNumberGenerator.new()
			rng.seed = 77
			for k in 9:
				var a = rng.randf_range(-1.2, 1.2)
				var q = p_ch + Vector3(sin(a) * 0.14, rng.randf_range(-0.18, 0.12), -0.12 - cos(a) * 0.04)
				mb.add("boulder", q, Vector3.ONE * rng.randf_range(0.07, 0.12), skin_c.darkened(rng.randf_range(0.1, 0.3)), Vector3(0, rng.randf() * 360, 0), k)
			for sx in [-1.0, 1.0]:   # omuz yumruları
				mb.add("boulder", p_ch + Vector3(sx * 0.17, 0.12, -0.02), Vector3(0.12, 0.1, 0.12), dark, Vector3.ZERO, 3)
			var ba = m._attach(chest_b, Transform3D.IDENTITY)
			var holder = Node3D.new()
			holder.position = p_ch
			ba.get_child(0).add_child(holder)
			var mi = mesh_of(mb)
			mi.position = -p_ch
			holder.add_child(mi)
			grow.call(holder, Vector3.ONE)
			out.append(ba)
		"orumcek":
			var mb = MB.new()
			for sx in [-1.0, 1.0]:
				for k in 2:
					var s0 = p_ch + Vector3(sx * 0.1, 0.02 - k * 0.12, -0.12)
					var s1 = s0 + Vector3(sx * 0.3, 0.12 - k * 0.15, -0.12)
					var s2 = s1 + Vector3(sx * 0.18, -0.25, 0.22)
					Loft.tube(mb, [s0, s1, s2], [0.045, 0.04, 0.035], skin_c, 10, 3, true, false)
					mb.add("sphere", s2 + Vector3(0, -0.03, 0.03), Vector3(0.08, 0.06, 0.1), skin_c.darkened(0.1), Vector3.ZERO, 8)
					mb.add("sphere", s1, Vector3(0.06, 0.06, 0.06), dark, Vector3.ZERO, 8)
			var ba = m._attach(chest_b, Transform3D.IDENTITY)
			var holder = Node3D.new()
			holder.position = p_ch
			ba.get_child(0).add_child(holder)
			var mi = mesh_of(mb)
			mi.position = -p_ch
			holder.add_child(mi)
			grow.call(holder, Vector3.ONE)
			out.append(ba)
	return out


func p_juin_ni_no_dankai(c: Node3D, _t: Node3D) -> void:
	var dur = 18.0
	juin_marks(c, Color(0.02, 0.0, 0.03), dur, 1.6)
	var a = FX.aura(c, Color(0.25, 0.05, 0.35), 1.8, Vector3(0, 0.9, 0), 0.0)
	VFX.slowmo(0.4, 0.5)
	shake(0.8)
	Sfx.play("roar", c.global_position, 0.8)
	VFX.shockwave(c.global_position + Vector3.UP, Color(0.3, 0.05, 0.4), 12.0, 0.45, true)
	# form: her kullanıcının mührü farklı uyanır (Sasuke tipi kanat, Tayuya tipi boynuz, Jirōbō tipi kaya deri, Kidōmaru tipi ek kollar)
	var form = "kanat"
	if c is Player:
		if not Game.profile.has("juin_form"):
			Game.profile["juin_form"] = ["kanat", "boynuz", "kaya", "orumcek"].pick_random()
		form = String(Game.profile["juin_form"])
	else:
		form = ["kanat", "boynuz", "kaya", "orumcek"][abs(c.get_instance_id()) % 4]
	var F = JUIN_FORMS[form]
	# ten rengi değişir (deri malzemeleri)
	var skin_mats = []
	var m = c.get("model")
	if m and is_instance_valid(m):
		var ratio: Color = m._skin_ratio()
		for sm in m.materials:
			if sm is ShaderMaterial and sm.get_shader_parameter("tint") == ratio:
				skin_mats.append(sm)
				sm.set_shader_parameter("tint", F["skin"])
	# beden parçaları: kemiğe bağlı (gövdeyle hareket eder)
	var parts = juin_parts(c, form) if m and is_instance_valid(m) else []
	var wings = parts
	if c is Player:
		var mods: Dictionary = (F["mods"] as Dictionary).duplicate()
		mods["_name"] = "Lanetli Mühür II — %s" % F["name"]
		mods["_desc"] = F["desc"]
		Buffs.add("juin2", dur, mods)
		Buffs.remove("juin1")
		if form == "kanat":
			c.start_flight("juin", {"drain": 0.0, "speed": 18.0, "dur": dur})
		Hud.msg("İkinci aşama — %s! %s. Canın hızla eriyor!" % [F["name"], F["desc"]], Color(0.85, 0.55, 1.0))
	every(dur, 1.0, func(_i, _k):
		if is_instance_valid(c) and c.hp > c.max_hp * 0.1:
			c.hp -= c.max_hp * 0.03, func():
		if is_instance_valid(a):
			a.emitting = false
		for sm in skin_mats:
			if is_instance_valid(m):
				sm.set_shader_parameter("tint", m._skin_ratio())
		for w in wings:
			if is_instance_valid(w):
				w.queue_free()
		if c is Player and is_instance_valid(c) and c.flight_source() == "juin":
			c.stop_flight())


## Mandara no Jin: ağızdan on binlerce yılan seli — 70° yelpazede 38 m boyunca her şeyi ısırıp sürükler
func p_mandara_no_jin(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 1.6)
	var mouth = Jutsu._mouth(c)
	VFX.slowmo(0.6, 0.35)
	shake(0.6)
	Sfx.play("roar", mouth, 0.6)
	FX.burst(mouth + d * 0.6, {"amount": 30, "life": 0.6, "size": 0.9, "vmin": 4, "vmax": 12, "colors": [Color(0.45, 0.35, 0.5), Color(0.2, 0.18, 0.22, 0)]})
	var hits = {}
	for k in 16:
		var ang = deg_to_rad(-35.0 + 70.0 * float(k) / 15.0)
		var dd = d.rotated(Vector3.UP, ang)
		var start = mouth + dd * 0.8
		var g0 = gp(c.global_position + dd * 3.0) + Vector3.UP * 0.5
		var end_ = gp(c.global_position + dd * randf_range(30.0, 38.0)) + Vector3.UP * 0.5
		after(k * 0.04, func():
			var head = make_snake(start, SNAKE.lerp(Color(0.3, 0.3, 0.25), randf() * 0.6), 0.8, 12)
			slither(head, start, g0, 0.12, 0.2, func():
				slither(head, g0, end_, 1.4, 2.2))
			every(1.6, 0.1, func(_i, _k):
				if not is_instance_valid(head):
					return
				for e in enemies_near(c, head.global_position, 2.4):
					if not hits.has(e):
						hits[e] = true
						poison(c, e, "mandara_no_jin", 0.7, 5.0)
						st(e, "slow", 5.0)
					if live(e):
						e.global_position = gp(e.global_position + dd * 0.6), Callable())
			fade_free(head, 1.8, 0.3))
	# zeminde kıvranan yılan halısı izi
	for k in 10:
		after(0.2 + k * 0.12, func(): FX.dust(gp(c.global_position + d * (4.0 + k * 3.2)), 1.6))


## Kabuk değiştirme: eski beden griye dönüp yarılır, ağzından yepyeni bedenle çıkarsın (%45 can, durumlar temizlenir)
func p_orochimaru_ryu_no_kawarimi_no_jutsu(c: Node3D, _t: Node3D) -> void:
	var m = c.get("model")
	if m == null or not is_instance_valid(m):
		return
	var husk = CharacterModel.new()
	get_tree().current_scene.add_child(husk)
	husk.setup(m.look.duplicate())
	husk.global_transform = m.global_transform
	husk.play("hit", 0.0, 0.2)
	for sm in husk.materials:
		if sm is ShaderMaterial:
			sm.set_shader_parameter("tint", Color(0.62, 0.6, 0.58))
	var tw = husk.create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(husk, "scale", Vector3(1.15, 0.25, 1.15), 0.5).set_ease(Tween.EASE_IN)
	tw.tween_interval(3.0)
	tw.tween_property(husk, "scale", Vector3(1.2, 0.02, 1.2), 0.6)
	tw.tween_callback(husk.queue_free)
	FX.burst(c.global_position + Vector3.UP, {"amount": 26, "life": 0.7, "size": 0.6, "vmin": 2, "vmax": 7, "colors": [Color(0.85, 0.85, 0.75), Color(0.6, 0.7, 0.5, 0)]})
	VFX.splash(c.global_position, 2.0)
	Sfx.play("water", c.global_position, 0.6)
	var d = c.face_dir()
	c.global_position = gp(c.global_position + d * 2.0)
	m.scale = Vector3.ONE * 0.3 * m.age_scale
	var t2 = m.create_tween()
	t2.tween_property(m, "scale", Vector3.ONE * m.age_scale, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	heal(c, c.max_hp * 0.45)
	for s in ["burn", "bind", "slow", "stun", "sealed", "poison", "marked", "fear", "frozen", "chilled", "shocked", "mud"]:
		if c.get("statuses") is Dictionary:
			c.statuses.erase(s)
	if c is Player:
		c.combat.invuln = 1.2
	Combat.popup_text(c.global_position + Vector3.UP * 2.4, "Kabuk değiştirdi!", Color(0.85, 0.95, 0.8))


## Beyaz Yılan Bilge Modu: pullar bedeni sarar, yaralar kapanır; her 1.4 sn yakındaki düşmana beyaz yılan saldırır, düşmanlar sezilir
func p_hakuja_sennin_modo(c: Node3D, _t: Node3D) -> void:
	var dur = 30.0
	var a = FX.aura(c, Color(0.92, 0.9, 1.0), 1.5, Vector3(0, 0.9, 0), 0.0)
	juin_marks(c, Color(0.95, 0.93, 1.0), dur, 0.8)   # beyaz pullar
	VFX.shockwave(c.global_position + Vector3.UP * 0.2, Color(0.95, 0.95, 1.0), 14.0, 0.5, true)
	Sfx.play("heal", c.global_position, 0.7)
	if c is Player:
		Buffs.add("hakuja", dur, {"melee": 1.25, "armor": 0.85, "jutsu": 1.15})
	for e in enemies_near(c, c.global_position, 34.0):
		st(e, "marked", dur)
		Combat.popup_text(e.global_position + Vector3.UP * (e.height + 0.8), "Sezildi", Color(0.9, 0.9, 1.0))
	every(dur, 1.4, func(i, _k):
		if not is_instance_valid(c) or (c is Player and not Buffs.has("hakuja")):
			return
		if i % 2 == 0:
			heal(c, c.max_hp * 0.03)
		var near = enemies_near(c, c.global_position, 13.0)
		if near.is_empty():
			return
		var e = near[i % near.size()]
		var from = c.global_position + Vector3.UP * 1.1
		var head = make_snake(from, Color(0.95, 0.94, 0.98), 0.6, 9)
		slither(head, from, e.global_position + Vector3.UP * e.height * 0.6, 0.25, 0.7, func():
			if live(e):
				poison(c, e, "hakuja_sennin_modo", 0.35, 3.0))
		fade_free(head, 0.6, 0.2), func():
		if is_instance_valid(a):
			a.emitting = false)


## Yamata no Jutsu: sekiz başlı dev yılana dönüşürsün; başlar ayrı ayrı 40 m'ye kadar dalar, sen gövdeyle yürürsün
func p_yamata_no_jutsu(c: Node3D, _t: Node3D) -> void:
	var dur = 16.0
	var m = c.get("model")
	VFX.slowmo(0.4, 0.6)
	shake(1.2)
	Sfx.play("roar", c.global_position, 0.5)
	FX.smoke_puff(c.global_position + Vector3.UP * 2.0, 4.0, 24)
	if m:
		m.visible = false
	if c is Player:
		Buffs.add("yamata", dur, {"armor": 0.45, "speed": 0.85})
		# dev beden: kamera geri çekilip yükselir (kamera gövdenin içinde kalıyordu)
		var cd0 = c.cam_dist
		c.cam_dist = 26.0
		after(dur, func(): if is_instance_valid(c): c.cam_dist = cd0)
	var col = Color(0.36, 0.28, 0.42)
	var mound = MB.new()
	mound.add_grad("sphere", Vector3(0, 1.5, 0), Vector3(9.0, 5.0, 10.0), col.lightened(0.1), col.darkened(0.3), Vector3.ZERO, 14)
	for k in 6:
		mound.add_grad("sphere", Vector3(cos(k) * 4.0, 0.8, sin(k) * 4.5), Vector3(4.0, 2.4, 5.0), col, col.darkened(0.35), Vector3(0, k * 50, 0), 10)
	var body = place(mound, c.global_position)
	var heads = []
	for k in 8:
		var ang = TAU * k / 8.0
		var h = make_snake(c.global_position + Vector3.UP * 3.0, col.lerp(Color(0.5, 0.4, 0.3), k % 3 * 0.2), 2.6, 18)
		heads.append({"n": h, "ang": ang, "cd": 0.6 + k * 0.22, "busy": 0.0, "y": randf_range(9.0, 14.0)})
	var tick = func(_i, _k):
		if not is_instance_valid(c):
			return
		if is_instance_valid(body):
			body.global_position = c.global_position
		for hd in heads:
			var h: Node3D = hd["n"]
			if not is_instance_valid(h):
				continue
			hd["cd"] -= 1.0 / 30.0
			if hd["busy"] > 0.0:
				hd["busy"] -= 1.0 / 30.0
				continue
			var tt = Time.get_ticks_msec() * 0.001
			var rest = c.global_position + Vector3(cos(hd["ang"] + sin(tt * 0.7) * 0.2) * 6.0, hd["y"] + sin(tt * 1.3 + hd["ang"]) * 0.8, sin(hd["ang"] + sin(tt * 0.7) * 0.2) * 6.0)
			h.global_position = h.global_position.lerp(rest, 0.12)
			toward(h, (rest - c.global_position).normalized() + Vector3.DOWN * 0.3)
			if hd["cd"] <= 0.0:
				var near = enemies_near(c, c.global_position, 40.0)
				if not near.is_empty():
					var e = near[randi() % near.size()]
					hd["cd"] = randf_range(1.4, 2.2)
					hd["busy"] = 0.75
					var from = h.global_position
					var to = e.global_position + Vector3.UP * e.height * 0.5
					slither(h, from, to, 0.28, 1.0, func():
						if live(e):
							hit(c, e.global_position + Vector3.UP, e.radius + 2.2, inf(c, "yamata_no_jutsu", 1.1, {"knock": 14.0, "launch": 7.0, "kind": "heavy", "burn": 3.0, "hitstop": 0.08}))
							FX.dust(gp(e.global_position), 1.8)
							shake(0.35))
	every(dur, 1.0 / 30.0, tick, func():
		for hd in heads:
			if is_instance_valid(hd["n"]):
				hd["n"].queue_free()
		if is_instance_valid(body):
			fade_free(body, 0.0, 0.5)
		if m and is_instance_valid(m):
			m.visible = true
		if is_instance_valid(c):
			FX.smoke_puff(c.global_position + Vector3.UP * 2.0, 3.0, 18))


## Edo Tensei: topraktan iki tabut yükselir, kapakları düşer; çatlak tenli diriltilmiş ninjalar 30 sn senin için savaşır
func p_kuchiyose_edo_tensei(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var side = d.cross(Vector3.UP).normalized()
	busy(c, 1.2)
	summon_circle(c.global_position + d * 4.0, 5.0, Color(0.5, 0.35, 0.25), 1.2)
	VFX.screen_lines(0.6, 0.6, Color(0.4, 0.3, 0.25))
	Sfx.play("earth", c.global_position, 0.5)
	var cof = cached("coffin", func():
		var b = MB.new()
		b.add_grad("box", Vector3(0, 1.3, 0), Vector3(1.3, 2.6, 0.8), Color(0.5, 0.4, 0.32), Color(0.32, 0.25, 0.2))
		b.add("box", Vector3(0, 2.4, -0.42), Vector3(1.0, 0.5, 0.05), Color(0.9, 0.86, 0.7))
		return b)
	for k in 2:
		var pos = gp(c.global_position + d * 4.0 + side * (k * 2.6 - 1.3))
		var coffin = mi_of(cof)
		coffin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		scene_add(coffin, pos - Vector3.UP * 2.8)
		toward(coffin, -d)
		var tw = coffin.create_tween()
		tw.tween_property(coffin, "global_position", pos, 0.6).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.5)
		tw.tween_callback(func():
			FX.smoke_puff(pos + Vector3.UP * 1.3, 0.9, 10)
			Sfx.play("poof", pos, 0.9)
			var w = EdoWarrior.new()
			w.team = c.team
			w.owner_f = c
			w.look = EdoWarrior.edo_look(k)
			w.power = (Stats.jutsu_mult(Game.profile) if c is Player else float(c.get("power") if c.get("power") != null else 1.0)) * 1.6
			get_tree().current_scene.add_child(w)
			w.global_position = pos + d * 1.2)
		tw.tween_interval(28.0)
		tw.tween_property(coffin, "global_position", pos - Vector3.UP * 3.0, 0.6)
		tw.tween_callback(coffin.queue_free)


## Sōjasōsai: iki dev yılan seni ve hedefi sarar; canının yarısı karşılığında hedefe ölümcül darbe
func p_sojasosai_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	if tt == null:
		Hud.msg("Sōjasōsai: hedef en fazla 14 metrede olmalı", Color(0.85, 0.7, 1.0))
		return
	busy(c, 1.6)
	if c is Player:
		c.combat.invuln = 1.6
	st(tt, "bind", 1.6)
	VFX.slowmo(0.35, 0.8)
	Sfx.play("genjutsu", c.global_position, 0.4)
	var cols = [Color(0.95, 0.95, 0.98), Color(0.1, 0.08, 0.12)]
	var who = [c, tt]
	for k in 2:
		var e: Node3D = who[k]
		var head = make_snake(e.global_position + Vector3(2.5, 0.2, 0), cols[k], 1.4, 16)
		var center = e.global_position
		every(1.4, 1.0 / 40.0, func(i, kk):
			if not is_instance_valid(head) or not is_instance_valid(e):
				return
			var a = kk * TAU * 2.5 + k * PI
			head.global_position = center + Vector3(cos(a) * 1.6, 0.3 + kk * 3.0, sin(a) * 1.6)
			toward(head, Vector3(-sin(a), 0.4, cos(a))), Callable())
		fade_free(head, 1.6, 0.2)
	ground_disc(tt.global_position, 4.0, Color(0.55, 0.25, 0.7), 1.5, 3, 6)
	after(1.4, func():
		if not live(tt):
			return
		var p = tt.global_position + Vector3.UP
		FX.flash_sphere(p, Color(0.8, 0.6, 1.0), 6.0, 0.4)
		VFX.shockwave(p, Color(0.5, 0.2, 0.7), 14.0, 0.5, false)
		shake(1.0)
		hit(c, p, tt.radius + 1.0, inf(c, "sojasosai_no_jutsu", 6.0, {"knock": 4.0, "kind": "heavy", "pierce_guard": true, "hitstop": 0.2}))
		if is_instance_valid(c):
			c.hp = maxf(1.0, c.hp * 0.5)
			Combat.popup_text(c.global_position + Vector3.UP * 2.4, "Bedel: canının yarısı", Color(0.85, 0.55, 0.9)))


# ================================================================== SİLAH USTASI YOLU
const WEAPON_KINDS := ["kunai", "fuma", "kama", "katana", "sai", "ono", "kusari", "chakram", "yari", "tonfa", "senbon", "shuriken"]


## Silah meshleri (uç = -Z): her biri ayrı biçim
func weapon_mesh(kind: String) -> ArrayMesh:
	return cached("wpn_" + kind, func():
		var b = MB.new()
		var steel = Color(0.78, 0.8, 0.86)
		var dark = Color(0.22, 0.2, 0.22)
		var wrap = Color(0.55, 0.18, 0.15)
		match kind:
			"kunai":
				b.add("box", Vector3(0, 0, -0.28), Vector3(0.11, 0.025, 0.5), steel)
				b.add("cyl", Vector3(0, 0, 0.12), Vector3(0.05, 0.3, 0.05), wrap, Vector3(90, 0, 0), 6)
				b.add("torus", Vector3(0, 0, 0.32), Vector3(0.12, 0.12, 0.12), dark, Vector3(90, 0, 0), 8)
			"shuriken":
				for k in 4:
					b.add("box", Vector3.ZERO, Vector3(0.6, 0.02, 0.1), steel, Vector3(0, k * 45, 0))
			"fuma":
				for k in 4:
					b.add("box", Vector3(0, 0, -0.45), Vector3(0.22, 0.03, 0.9), steel, Vector3(0, k * 90, 0))
					b.add("box", Vector3(0.18, 0, -0.75), Vector3(0.12, 0.03, 0.4), steel, Vector3(0, k * 90 + 35, 0))
				b.add("cyl", Vector3.ZERO, Vector3(0.25, 0.08, 0.25), dark, Vector3.ZERO, 10)
			"kama":
				b.add("cyl", Vector3(0, 0, 0.1), Vector3(0.05, 0.7, 0.05), Color(0.5, 0.35, 0.2), Vector3(90, 0, 0), 6)
				b.add("box", Vector3(0.16, 0, -0.28), Vector3(0.38, 0.02, 0.08), steel, Vector3(0, -25, 0))
			"katana":
				b.add_grad("box", Vector3(0, 0, -0.6), Vector3(0.06, 0.02, 1.1), steel.lightened(0.1), steel)
				b.add("box", Vector3(0, 0, 0.0), Vector3(0.16, 0.04, 0.06), Color(0.65, 0.55, 0.25))
				b.add("cyl", Vector3(0, 0, 0.2), Vector3(0.05, 0.35, 0.05), Color(0.1, 0.1, 0.12), Vector3(90, 0, 0), 6)
			"sai":
				b.add("cyl", Vector3(0, 0, -0.35), Vector3(0.035, 0.7, 0.035), steel, Vector3(90, 0, 0), 6)
				for sx in [-1.0, 1.0]:
					b.add("cyl", Vector3(0.1 * sx, 0, -0.08), Vector3(0.025, 0.28, 0.025), steel, Vector3(90, 0, 30 * sx), 5)
				b.add("cyl", Vector3(0, 0, 0.12), Vector3(0.04, 0.22, 0.04), wrap, Vector3(90, 0, 0), 6)
			"ono":
				b.add("cyl", Vector3(0, 0, 0.0), Vector3(0.06, 1.1, 0.06), Color(0.45, 0.3, 0.18), Vector3(90, 0, 0), 6)
				b.add("box", Vector3(0.2, 0, -0.45), Vector3(0.42, 0.04, 0.3), steel)
			"kusari":
				b.add("sphere", Vector3(0, 0, -0.2), Vector3(0.36, 0.36, 0.36), dark, Vector3.ZERO, 8)
				for k in 8:
					var a = k * TAU / 8.0
					b.add("cone", Vector3(cos(a) * 0.2, sin(a) * 0.2, -0.2), Vector3(0.07, 0.2, 0.07), steel, Vector3(0, 0, rad_to_deg(a) - 90), 4)
			"chakram":
				b.add("torus", Vector3.ZERO, Vector3(0.55, 0.55, 0.55), steel, Vector3.ZERO, 16)
			"yari":
				b.add("cyl", Vector3(0, 0, 0.3), Vector3(0.04, 1.6, 0.04), Color(0.45, 0.3, 0.18), Vector3(90, 0, 0), 6)
				b.add("cone", Vector3(0, 0, -0.62), Vector3(0.1, 0.4, 0.04), steel, Vector3(-90, 0, 0), 4)
			"tonfa":
				b.add("box", Vector3(0, 0, -0.1), Vector3(0.07, 0.07, 0.75), Color(0.35, 0.22, 0.12))
				b.add("cyl", Vector3(0, -0.12, 0.12), Vector3(0.05, 0.2, 0.05), Color(0.35, 0.22, 0.12), Vector3.ZERO, 6)
			"senbon":
				for k in 3:
					b.add("cyl", Vector3((k - 1) * 0.05, 0, -0.2), Vector3(0.012, 0.6, 0.012), steel, Vector3(90, 0, 0), 4)
		return b)


## Silahı fırlat: from'dan to'ya döne döne uçar; saplandığı yerde kalır (stick), isabet edene hasar
func throw_weapon(c: Node3D, id: String, kind: String, from: Vector3, to: Vector3, speed: float, mul: float, homing: Node3D = null, extra := {}) -> Projectile:
	var d = (to - from).normalized()
	var mi = mi_of(weapon_mesh(kind))
	var info = inf(c, id, mul, {"knock": 2.0, "kind": "light", "hitstop": 0.02}).merged(extra, true)
	var pr = shot(c, from, d, speed, mi, info, homing, false, (from.distance_to(to) / speed) + 0.6)
	pr.radius = 0.35
	pr.stick = true
	if kind in ["shuriken", "fuma", "chakram"]:
		pr.spin = Vector3(0, 28.0, 0)
	elif kind in ["kusari", "ono", "kama", "tonfa"]:
		pr.spin = Vector3(-20.0, 0, 0)
	return pr


## Parşömen: açılmış kâğıt (beyaz, kırmızı kenar) + ahşap rulolar
func scroll_node(w: float, h: float) -> Node3D:
	var mesh = cached("scroll_%d_%d" % [int(w * 10), int(h * 10)], func():
		var b = MB.new()
		b.add("box", Vector3(0, 0, 0), Vector3(w, h, 0.02), Color(0.96, 0.94, 0.86))
		b.add("box", Vector3(0, h * 0.5 - 0.06, -0.012), Vector3(w, 0.1, 0.02), Color(0.75, 0.12, 0.12))
		b.add("box", Vector3(0, -h * 0.5 + 0.06, -0.012), Vector3(w, 0.1, 0.02), Color(0.75, 0.12, 0.12))
		for k in 5:
			b.add("box", Vector3(-w * 0.35 + k * w * 0.17, 0, -0.014), Vector3(0.05, h * 0.55, 0.01), Color(0.1, 0.08, 0.08))
		for sy in [-1.0, 1.0]:
			b.add("cyl", Vector3(0, sy * h * 0.5, 0), Vector3(0.14, w + 0.3, 0.14), Color(0.45, 0.28, 0.15), Vector3(0, 0, 90), 8)
		return b)
	var root = Node3D.new()
	root.add_child(mi_of(mesh))
	return root


## Silah Yağmuru: önünde parşömen açılır, on iki farklı silah art arda fırlar
func p_buki_kuchiyose(c: Node3D, t: Node3D) -> void:
	var d = Jutsu._aim(c, t)
	var fd = fwd(c, t)
	busy(c, 1.2)
	anim(c, "throw", 1.2)
	var sc = scroll_node(1.6, 1.0)
	scene_add(sc, c.global_position + Vector3.UP * 1.3 + fd * 1.1)
	toward(sc, -fd)
	sc.scale = Vector3(0.05, 1, 1)
	var tw = sc.create_tween()
	tw.tween_property(sc, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	fade_free(sc, 1.3, 0.25)
	Sfx.play("poof", sc.global_position, 1.1)
	var tt = tg(c, t, 35.0)
	for k in 12:
		var kind: String = WEAPON_KINDS[k]
		after(0.18 + k * 0.07, func():
			if not is_instance_valid(sc):
				return
			var from = sc.global_position + Vector3(randf_range(-0.5, 0.5), randf_range(-0.3, 0.3), 0) + fd * 0.2
			FX.smoke_puff(from, 0.25, 4)
			var to = (tt.global_position + Vector3.UP * tt.height * 0.5 + Vector3(randf_range(-0.6, 0.6), randf_range(-0.3, 0.4), randf_range(-0.6, 0.6))) if tt and live(tt) else from + d * 30.0 + Vector3(randf_range(-2, 2), randf_range(-1, 1), randf_range(-2, 2))
			throw_weapon(c, "buki_kuchiyose", kind, from, to, 48.0, 0.28 if kind not in ["fuma", "ono", "kusari"] else 0.45, tt if tt and live(tt) else null)
			Sfx.play("kunai", from, randf_range(0.9, 1.3), 0.6))


## Demir Pençe Zinciri: zincir hedefe dolanıp onu sana çeker; hedef yoksa zemine saplanıp seni oraya çeker (kanca)
func p_tesso_kusari(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 26.0)
	var from = hand_pos(c, true)
	var to = tt.global_position + Vector3.UP * tt.height * 0.5 if tt else gp(Jutsu._aim_ground(c, t, 18.0, 26.0)) + Vector3.UP * 0.2
	busy(c, 0.9)
	anim(c, "throw", 1.4)
	var claw_mesh = cached("tesso_claw", func():
		var b = MB.new()
		b.add("sphere", Vector3.ZERO, Vector3(0.3, 0.3, 0.3), Color(0.25, 0.24, 0.26), Vector3.ZERO, 8)
		for k in 3:
			var a = k * TAU / 3.0
			b.add("cone", Vector3(cos(a) * 0.15, sin(a) * 0.15, -0.25), Vector3(0.07, 0.42, 0.07), Color(0.8, 0.82, 0.88), Vector3(-90 + sin(a) * 25, 0, cos(a) * 25), 4)
		return b)
	var claw = mi_of(claw_mesh)
	scene_add(claw, from)
	toward(claw, to - from)
	var chain_mat = Props.toon_color(Color(0.35, 0.34, 0.38))
	tether(func(): return hand_pos(c, true) if is_instance_valid(c) else from, func(): return claw.global_position if is_instance_valid(claw) else from, 0.07, chain_mat, 1.25)
	Sfx.play("clink", from, 1.2)
	var tw = claw.create_tween()
	tw.tween_property(claw, "global_position", to, 0.22)
	tw.tween_callback(func():
		if tt and live(tt):
			hit(c, to, tt.radius + 0.5, inf(c, "tesso_kusari", 0.7, {"knock": 0.0, "kind": "heavy", "hitstop": 0.06}))
			st(tt, "bind", 0.6)
			Combat.popup_text(to + Vector3.UP, "Zincirlendi!", Color(0.85, 0.85, 0.9))
			after(0.15, func():
				if live(tt):
					pull_to(c, tt, 0.35, 1.4)
					st(tt, "stun", 2.0))
			every(0.6, 1.0 / 30.0, func(_i, _k):
				if live(tt) and is_instance_valid(claw):
					claw.global_position = tt.global_position + Vector3.UP * tt.height * 0.5, func():
				if is_instance_valid(claw):
					claw.queue_free())
		else:
			FX.dust(gp(to), 0.6)
			VFX.cracks(gp(to), 1.2)
			# kanca: seni zincirin ucuna çeker
			var start = c.global_position
			if c is Player:
				c.combat.invuln = 0.4
			every(0.35, 1.0 / 40.0, func(_i, k):
				if is_instance_valid(c):
					c.global_position = start.lerp(gp(to), k) + Vector3.UP * sin(k * PI) * 2.0, func():
				if is_instance_valid(claw):
					claw.queue_free()))


## Sōshōryū: iki parşömen ejderha gibi sarmal çizip göğe yükselir; tepede silah yağmuru (60 silah, 10 m yarıçap)
func p_soshoryu(c: Node3D, t: Node3D) -> void:
	var fd = fwd(c, t)
	var center = gp(Jutsu._aim_ground(c, t, 14.0, 30.0))
	busy(c, 2.4)
	if c is Player:
		c.combat.invuln = 1.0
		c.velocity.y = 22.0
	var base = c.global_position
	VFX.slowmo(0.6, 0.5)
	Sfx.play("poof", base, 0.8)
	for k in 2:
		var head = Node3D.new()
		scene_add(head, base)
		var sc = scroll_node(0.5, 0.35)
		head.add_child(sc)
		VFX.trail(head, 0.9, Color(1, 1, 0.97), Color(0.97, 0.94, 0.85), Color(0.85, 0.2, 0.2, 0.0), 26)
		every(1.0, 1.0 / 40.0, func(_i, kk):
			if not is_instance_valid(head):
				return
			var a = kk * TAU * 2.2 + k * PI
			head.global_position = base + Vector3(cos(a) * (2.5 + kk * 2.0), 1.0 + kk * 19.0, sin(a) * (2.5 + kk * 2.0))
			head.rotate_y(0.3), Callable())
		fade_free(head, 2.6, 0.3)
	var sky = base + Vector3.UP * 20.0
	for k in 60:
		after(0.9 + k * 0.025, func():
			var kind: String = WEAPON_KINDS[k % WEAPON_KINDS.size()]
			var land = center + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
			land = gp(land)
			var from = sky + Vector3(randf_range(-3, 3), randf_range(-1, 2), randf_range(-3, 3))
			var pr = throw_weapon(c, "soshoryu", kind, from, land + Vector3.UP * 0.1, 55.0, 0.22)
			pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
				hit(c, pos, 1.4, inf(c, "soshoryu", 0.18, {"knock": 2.0, "kind": "light"}))
				FX.dust(pos, 0.35)
			if k % 6 == 0:
				Sfx.play("kunai", from, randf_range(0.8, 1.2), 0.7))
	after(1.0, func():
		FX.ring(center + Vector3.UP * 0.1, Color(0.95, 0.9, 0.8), 20.0, 0.6, true)
		shake(0.5))


## Demir Yelpaze: dev demir yelpaze açılır, 6 sn mermileri durdurur; kapanırken savurduğu rüzgar düşmanları uçurur
func p_tekkosen(c: Node3D, t: Node3D) -> void:
	var fd = fwd(c, t)
	busy(c, 0.6)
	var mesh = cached("tekkosen", func():
		var b = MB.new()
		for k in 11:
			var a = deg_to_rad(-80.0 + k * 16.0)
			b.add_grad("box", Vector3(sin(a) * 2.2, cos(a) * 2.2, 0), Vector3(0.55, 4.4, 0.08), Color(0.42, 0.42, 0.46), Color(0.2, 0.2, 0.24), Vector3(0, 0, -rad_to_deg(a)))
			b.add("sphere", Vector3(sin(a) * 4.4, cos(a) * 4.4, 0), Vector3(0.28, 0.28, 0.12), Color(0.85, 0.7, 0.25), Vector3.ZERO, 6)
		b.add("cyl", Vector3(0, 0, 0), Vector3(0.6, 0.25, 0.6), Color(0.8, 0.65, 0.25), Vector3(90, 0, 0), 12)
		b.add("box", Vector3(0, 1.8, -0.06), Vector3(5.6, 0.18, 0.04), Color(0.7, 0.12, 0.12))
		return b)
	var fan = mi_of(mesh)
	fan.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var root = Node3D.new()
	scene_add(root, gp(c.global_position + fd * 2.4))
	toward(root, -fd)
	root.add_child(fan)
	fan.position = Vector3(0, 0.4, 0)
	fan.scale = Vector3(0.05, 1, 1)
	var tw = fan.create_tween()
	tw.tween_property(fan, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	var cs = CollisionShape3D.new()
	var bx = BoxShape3D.new()
	bx.size = Vector3(8.0, 4.8, 0.8)
	cs.shape = bx
	cs.position = Vector3(0, 2.6, 0)
	sb.add_child(cs)
	root.add_child(sb)
	Sfx.play("clink", root.global_position, 0.6)
	every(6.0, 0.05, func(_i, _k):
		if not is_instance_valid(root):
			return
		for pr in get_tree().get_nodes_in_group("projectiles"):
			if pr is Projectile and is_instance_valid(pr) and pr.shooter != c and pr.global_position.distance_to(root.global_position + Vector3.UP * 2.5) < 4.8:
				FX.hit_spark(pr.global_position, Color(1, 0.9, 0.6), 1.0)
				Sfx.play("clink", pr.global_position, 1.3, 0.6)
				pr.queue_free(), func():
		if not is_instance_valid(root):
			return
		var t2 = fan.create_tween()
		t2.tween_property(fan, "rotation:y", PI * 0.5, 0.2)
		t2.tween_callback(root.queue_free)
		var wd = fd
		if is_instance_valid(c):
			wd = c.face_dir()
		VFX.shockwave(root.global_position + Vector3.UP * 1.5, Color(0.85, 0.95, 1.0), 12.0, 0.35, false, wd)
		Sfx.play("wind", root.global_position, 0.9)
		for e in enemies_near(c, root.global_position + wd * 6.0, 8.0):
			hit(c, e.global_position + Vector3.UP, e.radius + 0.5, inf(c, "tekkosen", 0.9, {"knock": 24.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.05})))


## Telli Silah Fırtınası: 10 silah tellerle etrafında döner; her 0.45 sn ikisi en yakın düşmanlara saplanıp geri döner, tele dolanan bağlanır
func p_ito_buki_arashi(c: Node3D, _t: Node3D) -> void:
	var dur = 7.0
	busy(c, 0.5)
	var wire = glow(Color(0.75, 0.9, 1.0), 0.75)
	var ws = []
	for k in 10:
		var w = Node3D.new()
		w.add_child(mi_of(weapon_mesh(WEAPON_KINDS[k % WEAPON_KINDS.size()])))
		scene_add(w, c.global_position + Vector3.UP)
		ws.append({"n": w, "a": TAU * k / 10.0, "busy": 0.0})
		var wn = w
		tether(func(): return hand_pos(c, k % 2 == 0) if is_instance_valid(c) else Vector3.ZERO, func(): return wn.global_position if is_instance_valid(wn) else Vector3.ZERO, 0.025, wire, dur)
	Sfx.play("whoosh", c.global_position, 0.9)
	var acc = {"t": 0.0}
	every(dur, 1.0 / 30.0, func(_i, kk):
		if not is_instance_valid(c):
			return
		acc["t"] += 1.0 / 30.0
		var tt = Time.get_ticks_msec() * 0.001
		for w in ws:
			var n: Node3D = w["n"]
			if not is_instance_valid(n):
				continue
			if w["busy"] > 0.0:
				w["busy"] -= 1.0 / 30.0
				continue
			var a = w["a"] + tt * 3.2
			var rest = c.global_position + Vector3(cos(a) * 3.2, 1.2 + sin(tt * 2.0 + w["a"]) * 0.5, sin(a) * 3.2)
			n.global_position = n.global_position.lerp(rest, 0.35)
			toward(n, Vector3(-sin(a), 0, cos(a)))
			for e in enemies_near(c, n.global_position, 0.9):
				hit(c, n.global_position, 1.0, inf(c, "ito_buki_arashi", 0.08, {"knock": 1.5, "kind": "light", "hitstop": 0.0}))
		if acc["t"] >= 0.45:
			acc["t"] = 0.0
			var near = enemies_near(c, c.global_position, 16.0)
			if near.is_empty():
				return
			var sent = 0
			for w in ws:
				if sent >= 2 or w["busy"] > 0.0 or not is_instance_valid(w["n"]):
					continue
				var e = near[(sent + int(tt * 10.0)) % near.size()]
				var n: Node3D = w["n"]
				w["busy"] = 0.5
				sent += 1
				var from = n.global_position
				var to = e.global_position + Vector3.UP * e.height * 0.5
				var tw = n.create_tween()
				tw.tween_property(n, "global_position", to, 0.14)
				tw.tween_callback(func():
					if live(e):
						hit(c, to, e.radius + 0.5, inf(c, "ito_buki_arashi", 0.32, {"knock": 2.0, "kind": "light", "hitstop": 0.03}))
						st(e, "bind", 0.6)
						Sfx.play("kunai", to, 1.2, 0.5))
				tw.tween_property(n, "global_position", from, 0.2), func():
		for w in ws:
			if is_instance_valid(w["n"]):
				FX.smoke_puff(w["n"].global_position, 0.3, 4)
				w["n"].queue_free())


## Dev Demir Topuz: gökte çağırma çemberi açılır, çivili dev topuz düşüp krater açar
func p_kuchiyose_tetsuzan(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 14.0, 32.0))
	busy(c, 0.8)
	var sky = center + Vector3.UP * 28.0
	ground_disc(sky, 6.0, Color(0.85, 0.3, 0.25), 1.0, 2, 12).global_position = sky
	ground_disc(center, 8.0, Color(1.0, 0.4, 0.3), 1.0, 1, 0)
	Sfx.play("poof", sky, 0.6)
	var mesh = cached("tetsuzan", func():
		var b = MB.new()
		b.add_grad("sphere", Vector3.ZERO, Vector3(7.0, 7.0, 7.0), Color(0.36, 0.35, 0.38), Color(0.15, 0.14, 0.16), Vector3.ZERO, 16)
		for k in 22:
			var a = k * 2.4
			var y = -0.9 + 1.8 * float(k) / 21.0
			var r = sqrt(maxf(0.0, 1.0 - y * y))
			var dir = Vector3(cos(a) * r, y, sin(a) * r).normalized()
			var basis = Basis(Quaternion(Vector3.UP, dir))
			var e = basis.get_euler()
			b.add("cone", dir * 3.6, Vector3(0.9, 2.2, 0.9), Color(0.75, 0.75, 0.8), Vector3(rad_to_deg(e.x), rad_to_deg(e.y), rad_to_deg(e.z)), 5)
		b.add("box", Vector3(0, 3.6, 0), Vector3(0.6, 1.4, 0.6), Color(0.3, 0.28, 0.3))
		b.add("torus", Vector3(0, 4.5, 0), Vector3(1.4, 1.4, 1.4), Color(0.3, 0.28, 0.3), Vector3(90, 0, 0), 10)
		return b)
	var ball = mi_of(mesh)
	ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	scene_add(ball, sky)
	ball.scale = Vector3.ONE * 0.2
	var tw = ball.create_tween()
	tw.tween_property(ball, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(ball, "global_position", center + Vector3.UP * 2.2, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		VFX.slowmo(0.5, 0.25)
		shake(1.3)
		VFX.cracks(center, 14.0)
		VFX.debris(center, Color(0.45, 0.38, 0.3), 30, 18.0, 0.9)
		FX.dust(center, 3.5)
		VFX.shockwave(center + Vector3.UP * 0.3, Color(0.85, 0.75, 0.6), 28.0, 0.5, true)
		Sfx.play("boom", center, 0.6)
		hit(c, center + Vector3.UP, 8.5, inf(c, "kuchiyose_tetsuzan", 2.4, {"knock": 18.0, "launch": 12.0, "kind": "heavy", "hitstop": 0.14})))
	tw.tween_interval(3.0)
	tw.tween_callback(func(): FX.smoke_puff(ball.global_position, 3.0, 18))
	tw.tween_property(ball, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(ball.queue_free)


## Bashōsen: palmiye yaprağı biçimli efsanevi yelpaze elde belirir; her sargı ayrı bir doğa — ek chakra emer
func bashosen_fan(c: Node3D, el_col: Color) -> Node3D:
	var mesh = cached("bashosen", func():
		var b = MB.new()
		b.add_grad("sphere", Vector3(0, 1.3, 0), Vector3(1.5, 1.9, 0.08), Color(0.78, 0.82, 0.45), Color(0.45, 0.55, 0.22), Vector3.ZERO, 14)
		for k in 7:
			b.add("box", Vector3((k - 3) * 0.18, 1.25, -0.05), Vector3(0.03, 1.7, 0.02), Color(0.4, 0.45, 0.2), Vector3(0, 0, (k - 3) * 9))
		b.add("cyl", Vector3(0, 0.0, 0), Vector3(0.09, 0.8, 0.09), Color(0.35, 0.2, 0.12), Vector3.ZERO, 8)
		b.add("sphere", Vector3(0, -0.45, 0), Vector3(0.22, 0.26, 0.22), Color(0.75, 0.55, 0.2), Vector3.ZERO, 8)   # su kabağı topuzu
		b.add("box", Vector3(0, -0.6, 0), Vector3(0.05, 0.25, 0.05), Color(0.8, 0.15, 0.15))
		return b)
	var root = Node3D.new()
	var mi = mi_of(mesh)
	root.add_child(mi)
	var rim = MeshInstance3D.new()
	rim.mesh = VFX._sphere(0.5, 16, 8)
	rim.material_override = glow(el_col, 0.45)
	rim.scale = Vector3(1.75, 2.1, 0.2)
	rim.position = Vector3(0, 1.3, 0)
	root.add_child(rim)
	var ba = bone_attach(c, "RightHand")
	if ba:
		ba.add_child(root)
		root.rotation_degrees = Vector3(-90, 0, 0)
	else:
		scene_add(root, hand_pos(c, true))
	root.scale = Vector3.ONE * 0.05
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE * 1.25, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.4)
	tw.tween_property(root, "scale", Vector3.ONE * 0.05, 0.25)
	tw.tween_callback(func():
		if is_instance_valid(ba):
			ba.queue_free()
		elif is_instance_valid(root):
			root.queue_free())
	if c is Player:
		c.chakra = maxf(0.0, c.chakra - c.max_chakra * 0.15)
		Combat.popup_text(c.global_position + Vector3.UP * 2.4, "Bashōsen chakranı emiyor!", Color(0.95, 0.85, 0.5))
	busy(c, 1.1)
	anim(c, "slash_a", 1.0)
	return root


func p_bashosen_kaze_no_maki(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	bashosen_fan(c, Color(0.7, 1.0, 0.85))
	after(0.35, func():
		var tor = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 7.5
		cm.bottom_radius = 1.4
		cm.height = 26.0
		cm.radial_segments = 20
		cm.rings = 6
		tor.mesh = cm
		tor.material_override = VFX.mat_wind(Color(0.8, 1.0, 0.92), 9.0, 7.0, Vector3.UP, 0.8)
		var start = gp(c.global_position + d * 4.0)
		scene_add(tor, start + Vector3.UP * 13.0)
		Sfx.play("wind", start, 0.6)
		shake(0.6)
		var hits = {}
		every(3.0, 1.0 / 30.0, func(i, k):
			if not is_instance_valid(tor):
				return
			var p = gp(start + d * (k * 42.0)) + Vector3.UP * 13.0
			tor.global_position = p
			tor.rotate_y(0.6)
			var base = p - Vector3.UP * 12.0
			if i % 4 == 0:
				FX.dust(base, 2.0)
			for e in enemies_near(c, base, 6.5):
				if live(e):
					e.global_position = e.global_position.lerp(base + Vector3.UP * minf(10.0, 2.0 + hits.get(e, 0) * 0.4), 0.15)
					hits[e] = hits.get(e, 0) + 1
					if hits[e] % 6 == 1:
						hit(c, e.global_position + Vector3.UP, e.radius + 0.6, inf(c, "bashosen_kaze_no_maki", 0.35, {"element": "fuuton", "knock": 4.0, "launch": 4.0, "kind": "heavy"})), func():
			if is_instance_valid(tor):
				fade_free(tor, 0.0, 0.4)))


func p_bashosen_hi_no_maki(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var side = d.cross(Vector3.UP).normalized()
	bashosen_fan(c, Color(1.0, 0.55, 0.15))
	after(0.35, func():
		var wall = Node3D.new()
		var start = gp(c.global_position + d * 4.0)
		scene_add(wall, start)
		toward(wall, d)
		for n in 11:
			var cm = CylinderMesh.new()
			cm.top_radius = 0.3; cm.bottom_radius = 1.2; cm.height = 1.0; cm.radial_segments = 12; cm.rings = 4
			cm.cap_top = false; cm.cap_bottom = false
			var col = VFX._mi(cm, VFX.mat_fire("fire", 3.2, 1.8, 0.4, 1.4, 0.24, Vector3.UP, true))
			wall.add_child(col)
			var hh = 8.0 - absf(n - 5) * 0.55
			col.position = Vector3((n - 5) * 2.1, hh * 0.5, absf(n - 5) * 0.35)
			col.scale = Vector3(2.0, 0.1, 2.0)
			var ct = col.create_tween()
			ct.tween_interval(absf(n - 5) * 0.03)
			ct.tween_property(col, "scale", Vector3(2.0, hh, 2.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sfx.play("fire", start, 0.6)
		shake(0.7)
		var hits = {}
		every(2.4, 1.0 / 30.0, func(i, k):
			if not is_instance_valid(wall):
				return
			var p = gp(start + d * (k * 36.0))
			wall.global_position = p
			if i % 3 == 0:
				VFX.embers(p + side * randf_range(-10, 10) + Vector3.UP * 2.0, Color(1, 0.55, 0.15), 10, 10.0)
				if i % 9 == 0:
					VFX.black_smolder(p + side * randf_range(-9, 9), 1.6, 3.0)
			for e in enemies_near(c, p + Vector3.UP, 11.5):
				var rel = e.global_position - p
				if absf(rel.dot(d)) < 2.5 and not hits.has(e):
					hits[e] = true
					hit(c, e.global_position + Vector3.UP, e.radius + 0.6, inf(c, "bashosen_hi_no_maki", 1.6, {"element": "katon", "burn": 6.0, "knock": 12.0, "launch": 5.0, "kind": "heavy"})), func():
			if is_instance_valid(wall):
				fade_free(wall, 0.0, 0.4)))


func p_bashosen_rai_no_maki(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var side = d.cross(Vector3.UP).normalized()
	bashosen_fan(c, Color(0.6, 0.8, 1.0))
	var center = gp(c.global_position + d * 16.0)
	after(0.35, func():
		var field = ground_disc(center, 13.0, Color(0.55, 0.75, 1.0), 4.4, 3, 16)
		field.scale = Vector3(1.0, 1, 1.0)
		Sfx.play("thunder", center, 0.7)
		every(4.0, 0.35, func(i, _k):
			for k in 5:
				var p = center + d * randf_range(-11, 11) + side * randf_range(-11, 11)
				var g = gp(p)
				var near = enemies_near(c, center, 13.0)
				if k < 2 and not near.is_empty():
					g = near[(i + k) % near.size()].global_position
				VFX.bolt(g + Vector3.UP * 26.0 + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)), g, Color(0.6, 0.8, 1.0), 0.35, 0.2, 4)
				FX.ring(g + Vector3.UP * 0.1, Color(0.6, 0.85, 1.0), 3.0, 0.25, true)
				for e in enemies_near(c, g, 2.4):
					hit(c, e.global_position + Vector3.UP, e.radius + 0.5, inf(c, "bashosen_rai_no_maki", 0.35, {"element": "raiton", "knock": 2.0, "kind": "light", "hitstop": 0.04}))
					st(e, "stun", 0.6)
			if i % 2 == 0:
				shake(0.25), Callable()))


func p_bashosen_mizu_no_maki(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var side = d.cross(Vector3.UP).normalized()
	bashosen_fan(c, Color(0.4, 0.7, 1.0))
	after(0.35, func():
		var wave = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 2.5
		cm.bottom_radius = 5.0
		cm.height = 24.0
		cm.radial_segments = 16
		wave.mesh = cm
		wave.material_override = VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.8, 0.95, 1.0), d, 0.9, 0.7, 0.08)
		var start = gp(c.global_position + d * 3.0)
		scene_add(wave, start + Vector3.UP * 2.6)
		wave.look_at(wave.global_position + side, Vector3.UP)
		wave.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		Sfx.play("water", start, 0.6)
		shake(0.6)
		every(2.6, 1.0 / 30.0, func(i, k):
			if not is_instance_valid(wave):
				return
			var p = gp(start + d * (k * 38.0))
			wave.global_position = p + Vector3.UP * (2.6 + sin(k * PI) * 1.5)
			if i % 3 == 0:
				VFX.splash(p + side * randf_range(-10, 10), 2.4)
			for e in enemies_near(c, p, 12.0):
				var rel = e.global_position - p
				if absf(rel.dot(d)) < 3.5 and live(e):
					e.global_position = gp(e.global_position + d * 0.9)
					if i % 5 == 0:
						hit(c, e.global_position + Vector3.UP, e.radius + 0.6, inf(c, "bashosen_mizu_no_maki", 0.4, {"element": "suiton", "knock": 3.0, "kind": "heavy"}))
						st(e, "wet", 8.0), func():
			if is_instance_valid(wave):
				fade_free(wave, 0.0, 0.4)
				VFX.splash(wave.global_position, 4.0)))


# ================================================================== Şifacı Yolu (Tıbbi Ninja)
const MED := Color(0.45, 0.95, 0.6)


## Toprak Gizlenmesi: yere gömülür (görünmez, darbe almaz), 3 sn sonra hedefin dibinden yukarı fırlayıp çene darbesi
func p_senpuku(c: Node3D, t: Node3D) -> void:
	busy(c, 0.4)
	anim(c, "crouch", 1.6)
	FX.dust(c.global_position, 1.2)
	Sfx.play("earth", c.global_position, 0.8)
	var m = c.get("model")
	if m:
		m.create_tween().tween_property(m, "position:y", -2.0, 0.35)
	if c is Player:
		Buffs.add("stealth_senpuku", 3.0, {"stealth": 1.0, "armor": 0.0, "_desc": "Yerin altındasın: görünmez, hasar almazsın"})
	after(3.0, func():
		if not live(c):
			return
		var tt = tg(c, t, 14.0)
		if tt:
			c.global_position = gp(tt.global_position + fwd(c, tt) * -0.8)
		if m:
			m.create_tween().tween_property(m, "position:y", 0.0, 0.15)
		VFX.puffs(c.global_position, {"amount": 30, "life": 0.7, "size": 0.8, "radius": 1.0, "vmin": 4, "vmax": 9, "dir": Vector3.UP, "spread": 30.0,
			"colors": [Color(0.6, 0.5, 0.38, 0.9), Color(0.5, 0.42, 0.32, 0)]})
		anim(c, "hook", 1.6)
		Sfx.play("hit_heavy", c.global_position, 0.9)
		hit(c, c.global_position + Vector3.UP * 1.0, 2.0, inf(c, "senpuku", 1.0, {"launch": 9.0, "knock": 4.0, "kind": "heavy"})))


## Ceset Diriltme: solgun, dikişli bir ceset ayağa kalkar ve 20 sn senin için savaşır
func p_shikon_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.6)
	var at = gp(c.global_position + fwd(c, t) * 3.0)
	summon_circle(at, 1.6, Color(0.5, 0.75, 0.55), 1.2)
	after(0.5, func():
		if not live(c):
			return
		var d = ShadowClone.new()
		d.team = c.team
		var lk = CharacterModel.default_look()
		lk.merge({"skin": Color(0.72, 0.74, 0.7), "top": Color(0.35, 0.33, 0.3), "top2": Color(0.3, 0.28, 0.26), "pants": Color(0.25, 0.24, 0.22),
			"hair": Color(0.3, 0.3, 0.3), "face_mark": "kırışık", "band_style": "slashed"}, true)
		d.look = lk
		d.life = 20.0
		get_tree().current_scene.add_child(d)
		d.global_position = at
		d.max_hp = 1.0
		FX.burst(at + Vector3.UP, {"amount": 26, "life": 0.8, "tex": FX.tex_smoke, "add": false, "size": 0.7, "vmin": 1, "vmax": 3, "colors": [Color(0.55, 0.7, 0.55, 0.8), Color(0.4, 0.5, 0.4, 0)]})
		Combat.popup_text(at + Vector3.UP * 2.4, "Ceset kalktı!", Color(0.6, 0.85, 0.6)))


## Zehir Çekme: avuçta dönen su küresi bedenden mor zehri çeker; zehir/yavaşlama/bağ biter, can yenilenir
func p_saikan_chushutsu_no_jutsu(c: Node3D, _t: Node3D) -> void:
	busy(c, 1.2)
	anim(c, "cast", 1.0)
	var orb = MeshInstance3D.new()
	orb.mesh = VFX._sphere(0.22, 16, 8)
	orb.material_override = VFX.mat_water(Color(0.15, 0.55, 0.65), Color(0.4, 0.85, 0.8), Color(0.85, 1, 0.95), Vector3.UP, 0.4, 0.6, 0.1)
	get_tree().current_scene.add_child(orb)
	every(1.1, 1.0 / 30.0, func(_i, k):
		if is_instance_valid(orb) and live(c):
			orb.global_position = hand_pos(c, true) + Vector3.UP * 0.15
			orb.scale = Vector3.ONE * (0.6 + k * 0.8)
			if randf() < 0.5:
				VFX.puffs(c.global_position + Vector3.UP * randf_range(0.6, 1.5), {"amount": 2, "life": 0.4, "size": 0.15, "radius": 0.2, "vmin": 1, "vmax": 2,
					"colors": [Color(0.55, 0.2, 0.65, 0.9), Color(0.4, 0.1, 0.5, 0)]}), func():
		if is_instance_valid(orb):
			FX.burst(orb.global_position, {"amount": 20, "life": 0.5, "tex": FX.tex_smoke, "add": false, "size": 0.3, "vmin": 2, "vmax": 4, "gravity": Vector3(0, -8, 0), "colors": [Color(0.5, 0.2, 0.6, 0.9), Color(0.3, 0.1, 0.4, 0)]})
			orb.queue_free()
		if live(c):
			for s in ["poison", "slow", "bind", "stun", "burn"]:
				if c.has_method("clear_status"):
					c.clear_status(s)
				elif "statuses" in c:
					c.statuses.erase(s)
			heal(c, c.max_hp * 0.25)
			Combat.popup_text(c.global_position + Vector3.UP * 2.6, "Zehir çekildi", MED))


## Zehir Sisi: ağızdan mor sis yelpazesi; 7 sn yerde kalır, içindekiler zehirlenir ve yavaşlar
func p_dokugiri(c: Node3D, t: Node3D) -> void:
	busy(c, 0.7)
	var d = fwd(c, t)
	var center = gp(c.global_position + d * 6.0)
	Sfx.play("wind", c.global_position, 0.6)
	for k in 5:
		after(k * 0.08, func():
			VFX.puffs(c.global_position + Vector3.UP * 1.5 + d * (1.0 + k * 1.4), {"amount": 26, "life": 1.4, "size": 1.4 + k * 0.3, "radius": 0.6 + k * 0.4, "vmin": 2, "vmax": 5, "dir": d, "spread": 25.0,
				"colors": [Color(0.55, 0.25, 0.65, 0.75), Color(0.35, 0.15, 0.45, 0)]}))
	every(7.0, 0.5, func(_i, _k):
		VFX.puffs(center + Vector3.UP * 0.8, {"amount": 8, "life": 1.2, "size": 1.8, "radius": 4.0, "vmin": 0.2, "vmax": 0.8, "colors": [Color(0.55, 0.25, 0.65, 0.5), Color(0.35, 0.15, 0.45, 0)]})
		for e in enemies_near(c, center, 5.0):
			st(e, "slow", 1.0)
			e.take_hit(inf(c, "dokugiri", 0.12, {"knock": 0.0, "kind": "light", "element": ""})), Callable())


## Sinir Karıştırma: elektrikli yeşil avuç darbesi; hedefin sinirleri karışır (3 sn sersem, sonra yavaş)
func p_ranshinsho(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	busy(c, 0.6)
	anim(c, "jab", 1.6)
	var pt = hand_pos(c, true)
	FX.burst(pt, {"amount": 30, "life": 0.35, "tex": FX.tex_spark, "add": true, "size": 0.25, "vmin": 2, "vmax": 7, "colors": [Color(0.6, 1, 0.7), Color(0.3, 1, 0.5, 0)]})
	Sfx.play("chidori", pt, 1.6, 0.4)
	if tt and tt.global_position.distance_to(c.global_position) < 4.0:
		tt.take_hit(inf(c, "ranshinsho", 0.6, {"knock": 1.0, "kind": "light"}))
		st(tt, "stun", 3.0)
		after(3.0, func(): st(tt, "slow", 4.0))
		Combat.popup_text(tt.global_position + Vector3.UP * 2.4, "Sinirler karıştı!", Color(0.6, 1, 0.7))


## Chakra Neşteri: iki elde mavi parlayan bıçak (12 sn); yakın dövüş güçlenir, vurulan kas kesilir (yavaşlar)
func p_chakura_no_mesu(c: Node3D, _t: Node3D) -> void:
	anim(c, "cast", 1.4)
	var blades = []
	for right in [true, false]:
		var ba = bone_attach(c, "RightHand" if right else "LeftHand")
		if ba == null:
			continue
		var b = MB.new()
		b.add("box", Vector3(0, 0.12, 0.02), Vector3(0.02, 0.22, 0.07), Color(0.6, 0.9, 1.0))
		var mi = mesh_of(b, glow(Color(0.55, 0.9, 1.0), 0.8))
		ba.add_child(mi)
		blades.append(ba)
	Sfx.play("chidori", c.global_position, 2.0, 0.3)
	if c is Player:
		Buffs.add("chakura_no_mesu", 12.0, {"melee": 1.5, "_name": "Chakra Neşteri", "_desc": "vurduğun düşman yavaşlar (kas kesildi)"})
	every(12.0, 0.25, func(_i, _k):
		for e in enemies_near(c, c.global_position, 2.2):
			if randf() < 0.25:
				st(e, "slow", 2.0), func():
		for ba in blades:
			if is_instance_valid(ba):
				ba.queue_free())


## Hücre Yenileme: bedeni saran yeşil ışık, 15 sn her saniye %4 can
func p_in_yu_shometsu(c: Node3D, _t: Node3D) -> void:
	anim(c, "cast", 1.2)
	var a = FX.aura(c, MED, 1.1, Vector3(0, 0.9, 0), 0.0)
	if c is Player:
		Buffs.add("in_yu_shometsu", 15.0, {"_name": "Hücre Yenileme", "_desc": "her sn canın %4'ü yenilenir"})
	every(15.0, 1.0, func(_i, _k):
		if live(c):
			heal(c, c.max_hp * 0.04), func():
		if is_instance_valid(a):
			a.emitting = false)


## Yaradılış Yenilenmesi: alında elmas mühür açılır, yüze/kollara mühür çizgileri yayılır; tam iyileşme + 20 sn güçlü yenilenme
func p_sozo_saisei(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.8)
	anim(c, "cast", 0.9)
	var m = c.get("model")
	var parts = []
	var hb = bone_attach(c, "Head")
	if hb:
		var b = MB.new()
		b.add("box", Vector3(0, 0.1, 0.1), Vector3(0.025, 0.025, 0.008), Color(0.6, 0.2, 0.75), Vector3(0, 0, 45))   # Byakugō elması
		var mi = mesh_of(b, glow(Color(0.65, 0.25, 0.85), 1.0))
		hb.add_child(mi)
		parts.append(hb)
	for bone in ["LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "Neck"]:
		var ba = bone_attach(c, bone)
		if ba == null:
			continue
		var b2 = MB.new()
		for k in 3:
			b2.add("box", Vector3(0.045 * (1 if k % 2 == 0 else -1), 0.05 + k * 0.07, 0.03), Vector3(0.008, 0.06, 0.004), Color(0.25, 0.1, 0.35), Vector3(0, 0, 25 - k * 25))
		ba.add_child(mesh_of(b2, glow(Color(0.35, 0.12, 0.45), 1.0)))
		parts.append(ba)
	FX.ring(c.global_position + Vector3.UP * 1.0, Color(0.7, 0.3, 0.9), 4.0, 0.5)
	Sfx.play("heal", c.global_position, 0.8)
	heal(c, c.max_hp)
	if c is Player:
		Buffs.add("sozo_saisei", 20.0, {"armor": 0.85, "_name": "Yaradılış Yenilenmesi", "_desc": "tam iyileşme + her sn canın %6'sı yenilenir"})
	every(20.0, 1.0, func(_i, _k):
		if live(c):
			heal(c, c.max_hp * 0.06), func():
		for pp in parts:
			if is_instance_valid(pp):
				pp.queue_free())


# ================================================================== Sekiz Kapı Yolu
const GATE_GREEN := Color(0.45, 1.0, 0.45)


func _gate_cost(c: Node3D, frac: float) -> void:
	if c is Player:
		c.hp = maxf(1.0, c.hp - c.max_hp * frac)
	FX.aura(c, GATE_GREEN, 1.0, Vector3(0, 0.9, 0), 0.8)


## Ön Lotus: hedefe atıl, çeneden yukarı tekmele, havada sargıyla sar ve başaşağı yere çak
func p_omote_renge(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 12.0)
	_gate_cost(c, 0.05)
	busy(c, 1.4)
	if tt == null:
		anim(c, "hook", 1.5)
		return
	c.global_position = gp(tt.global_position - fwd(c, tt) * 1.0)
	anim(c, "hook", 1.8)
	Sfx.play("hit_heavy", c.global_position, 1.1)
	tt.take_hit(inf(c, "omote_renge", 0.3, {"launch": 14.0, "knock": 0.0, "kind": "heavy"}))
	after(0.45, func():
		if not live(tt):
			return
		# sargı: hedefle aradaki beyaz bant
		tether(func(): return c.global_position + Vector3.UP * 1.2, func(): return tt.global_position + Vector3.UP, 0.08, glow(Color(0.95, 0.94, 0.9), 1.0), 0.5)
		c.global_position = tt.global_position + Vector3.UP * 0.5
		anim(c, "air", 1.4))
	after(0.95, func():
		if not live(c):
			return
		var p = gp(c.global_position)
		c.global_position = p
		if live(tt):
			tt.global_position = p
		FX.impact(p, GATE_GREEN, 2.0)
		FX.ring(p + Vector3.UP * 0.1, Color(0.7, 0.65, 0.55), 6.0, 0.4)
		shake(0.7)
		Sfx.play("boom", p, 0.8)
		hit(c, p + Vector3.UP * 0.6, 3.0, inf(c, "omote_renge", 1.4, {"knock": 8.0, "kind": "heavy"})))


## Arka Lotus: üçüncü kapı; hedefi havaya savurup arkasından görünerek 6 hızlı vuruş, son yumrukla yere çakar
func p_ura_renge(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	_gate_cost(c, 0.1)
	busy(c, 1.8)
	if tt == null:
		return
	c.global_position = gp(tt.global_position - fwd(c, tt) * 1.0)
	tt.take_hit(inf(c, "ura_renge", 0.2, {"launch": 16.0, "knock": 0.0, "kind": "heavy"}))
	for k in 6:
		after(0.25 + k * 0.13, func():
			if not live(tt) or not live(c):
				return
			var side = Vector3(cos(k * 2.1), 0.4, sin(k * 2.1)) * 1.2
			c.global_position = tt.global_position + side
			anim(c, ["jab", "cross", "hook"][k % 3], 2.2)
			FX.impact(tt.global_position + Vector3.UP * 0.8, GATE_GREEN, 0.8)
			Sfx.play("punch", tt.global_position, 1.2 + k * 0.05)
			tt.take_hit(inf(c, "ura_renge", 0.22, {"knock": 0.0, "launch": 2.0, "kind": "light", "hitstop": 0.03})))
	after(1.15, func():
		if not live(c):
			return
		var p = gp(tt.global_position if live(tt) else c.global_position)
		c.global_position = p + Vector3.UP * 0.2
		if live(tt):
			tt.global_position = p
		anim(c, "cross", 1.4)
		FX.impact(p, GATE_GREEN, 3.0)
		FX.ring(p + Vector3.UP * 0.1, Color(0.7, 0.65, 0.55), 9.0, 0.5)
		shake(1.1)
		Sfx.play("boom", p, 0.6)
		hit(c, p + Vector3.UP * 0.6, 4.0, inf(c, "ura_renge", 1.8, {"knock": 12.0, "kind": "heavy"})))


## Sekiz Kapı Açılışı: yeşil buhar fışkırır, ten kızarır; 25 sn büyük güç ve hız, can yavaşça erir
func p_hachimon_tonko_no_jin(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.8)
	anim(c, "cast", 1.0)
	shake(0.8)
	Sfx.play("roar", c.global_position, 1.2, 0.6)
	FX.ring(c.global_position + Vector3.UP * 0.2, GATE_GREEN, 10.0, 0.5)
	var a = FX.aura(c, GATE_GREEN, 1.6, Vector3(0, 0.9, 0), 0.0)
	var m = c.get("model")
	var skin_mats = []
	if m:
		var ratio: Color = m._skin_ratio()
		for sm in m.materials:
			if sm is ShaderMaterial and sm.get_shader_parameter("tint") == ratio:
				skin_mats.append(sm)
				sm.set_shader_parameter("tint", ratio * Color(1.15, 0.78, 0.72))   # kapılar açıkken ten kızarır
	if c is Player:
		Buffs.add("hachimon", 25.0, {"melee": 2.1, "speed": 1.5, "_name": "Sekiz Kapı Açık", "_desc": "her sn canın %1.5'i erir"})
	every(25.0, 0.4, func(_i, _k):
		if live(c):
			if c is Player:
				c.hp = maxf(1.0, c.hp - c.max_hp * 0.006)
			VFX.puffs(c.global_position + Vector3.UP * 1.2, {"amount": 3, "life": 0.8, "size": 0.6, "radius": 0.4, "vmin": 1, "vmax": 3, "dir": Vector3.UP, "spread": 30.0,
				"colors": [Color(0.75, 1, 0.75, 0.6), Color(0.6, 0.9, 0.6, 0)]}), func():
		if is_instance_valid(a):
			a.emitting = false
		if m and is_instance_valid(m):
			for sm in skin_mats:
				sm.set_shader_parameter("tint", m._skin_ratio()))


## Sabah Tavuskuşu: altıncı kapı; sürtünmeden alev alan yumruklar tavuskuşu kuyruğu gibi yelpazelenir
func p_asakujaku(c: Node3D, t: Node3D) -> void:
	_gate_cost(c, 0.12)
	busy(c, 1.3)
	var d = fwd(c, t)
	var right = d.cross(Vector3.UP).normalized()
	for k in 18:
		after(k * 0.05, func():
			if not live(c):
				return
			anim(c, "jab" if k % 2 == 0 else "cross", 2.6)
			var off = right * randf_range(-2.2, 2.2) + Vector3.UP * randf_range(0.6, 2.6)
			var from = c.global_position + Vector3.UP * 1.3 + d * 0.6
			var b = MB.new()
			b.add("sphere", Vector3.ZERO, Vector3(0.5, 0.5, 0.8), Color(1, 0.6, 0.2))
			var mi = mesh_of(b, glow(Color(1, 0.55, 0.15), 0.85))
			var pr = shot(c, from, (d * 12.0 + off).normalized(), 46.0, mi, inf(c, "asakujaku", 0.18, {"element": "katon", "burn": 1.5, "knock": 2.0, "kind": "light"}), null, false, 0.6)
			Projectile.trail(pr, [Color(1, 0.7, 0.3, 0.9), Color(1, 0.3, 0.1, 0)], 0.35, 16, 0.3, FX.tex_smoke, true)
			if k % 4 == 0:
				Sfx.play("fire", from, 1.4, 0.4))
	FX.speed_lines(c.global_position + Vector3.UP, d)


## Gündüz Kaplanı: yedinci kapı; avuç ileri, kaplan başı biçiminde dev hava basıncı topu (her şeyi savurur)
func p_hirudora(c: Node3D, t: Node3D) -> void:
	_gate_cost(c, 0.15)
	busy(c, 1.0)
	anim(c, "push", 1.0)
	var d = fwd(c, t)
	after(0.35, func():
		if not live(c):
			return
		var from = c.global_position + Vector3.UP * 1.3 + d * 1.2
		var node = Node3D.new()
		var core = MeshInstance3D.new()
		core.mesh = VFX._sphere(1.6, 18, 10)
		core.material_override = glow(Color(0.85, 1.0, 0.9), 0.35)
		node.add_child(core)
		for sx in [-1.0, 1.0]:   # kaplan kulakları ve çene hatları (hava girdabı)
			var ear = MeshInstance3D.new()
			ear.mesh = VFX._sphere(0.6, 10, 6)
			ear.material_override = glow(Color(0.8, 1.0, 0.85), 0.3)
			ear.position = Vector3(sx * 1.2, 1.3, 0.2)
			node.add_child(ear)
		var pr = shot(c, from, d, 26.0, node, inf(c, "hirudora", 2.2, {"knock": 22.0, "launch": 6.0, "kind": "heavy", "hitstop": 0.1}), null, true, 1.4)
		Projectile.trail(pr, [Color(0.85, 1, 0.9, 0.6), Color(0.7, 0.9, 0.8, 0)], 1.4, 20, 0.5, FX.tex_smoke, false)
		shake(0.9)
		Sfx.play("wind", from, 0.5)
		Sfx.play("roar", from, 1.3, 0.5))


## Akşam Fili: sekizinci kapı; beş ardışık süpersonik yumruk, her biri öne uzanan hava şoku
func p_sekizo(c: Node3D, t: Node3D) -> void:
	_gate_cost(c, 0.2)
	busy(c, 2.0)
	var d = fwd(c, t)
	for k in 5:
		after(0.2 + k * 0.32, func():
			if not live(c):
				return
			anim(c, "cross", 2.0)
			var o = c.global_position + Vector3.UP * 0.4
			FX.ring(o + d * 2.0 + Vector3.UP, Color(0.8, 1, 0.8), 3.5 + k * 0.6, 0.3, false, d)
			VFX.puffs(o + d * 4.0 + Vector3.UP, {"amount": 30, "life": 0.5, "size": 1.0, "radius": 1.5, "vmin": 12, "vmax": 22, "dir": d, "spread": 15.0,
				"colors": [Color(0.9, 1, 0.9, 0.7), Color(0.7, 0.9, 0.7, 0)]})
			shake(0.5 + k * 0.1)
			Sfx.play("boom", o, 1.2 - k * 0.08, 0.6)
			Combat.hit_zone(c, o, d, 18.0 + k * 3.0, 14.0, 4.0, inf(c, "sekizo", 0.75, {"knock": 16.0, "launch": 3.0, "kind": "heavy", "hitstop": 0.05})))


## Gece Gayı: sekizinci kapının son tekmesi; kızıl ejderha biçimli buhar, uzayı büken tek hamlede hedefin içinden geç.
## Bedeli: canın %10'a iner, 12 sn bitkin (yavaş)
func p_yagai(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 30.0)
	busy(c, 1.8)
	anim(c, "crouch", 0.8)
	var a = FX.aura(c, Color(1, 0.25, 0.2), 2.4, Vector3(0, 0.9, 0), 0.0)
	Sfx.play("roar", c.global_position, 0.6)
	shake(1.0)
	after(0.9, func():
		if not live(c):
			return
		var d = fwd(c, tt)
		var start = c.global_position
		var dist = 26.0 if tt == null else c.global_position.distance_to(tt.global_position) + 6.0
		var end = gp(start + d * dist)
		# ejderha: başlangıçtan bitişe kıvrılan kızıl buhar şeridi
		for k in 14:
			var q = start.lerp(end, k / 13.0) + Vector3.UP * (1.2 + sin(k * 0.8) * 0.8) + d.cross(Vector3.UP) * cos(k * 0.6) * 1.2
			VFX.puffs(q, {"amount": 14, "life": 1.2, "size": 1.6 - k * 0.05, "radius": 0.8, "vmin": 0.5, "vmax": 2, "colors": [Color(1, 0.3, 0.2, 0.85), Color(0.7, 0.1, 0.1, 0)]})
		c.global_position = end
		anim(c, "dash", 1.4)
		Combat.hit_zone(c, start, d, dist, 10.0, 4.0, inf(c, "yagai", 6.0, {"knock": 30.0, "launch": 10.0, "kind": "heavy", "hitstop": 0.2}))
		VFX.slowmo(0.35, 0.6)
		shake(2.0)
		Sfx.play("boom", end, 0.4)
		if is_instance_valid(a):
			a.emitting = false
		if c is Player:
			c.hp = minf(c.hp, c.max_hp * 0.1)
			st(c, "slow", 12.0)
			Hud.msg("Gece Gayı'nın bedeli: bedenin tükendi.", Color(1, 0.4, 0.4)))


# ================================================================== Kâğıt Yolu
const PAPER := Color(0.96, 0.95, 0.98)
const PAPER_V := Color(0.62, 0.52, 0.85)


## Tek bir kâğıt yaprağı (dörtgen, hafif kıvrık)
func paper_sheet(s := 0.35) -> MeshInstance3D:
	var b = MB.new()
	b.add("box", Vector3.ZERO, Vector3(s, 0.006, s * 1.3), PAPER, Vector3(randf_range(-20, 20), randf() * 360.0, randf_range(-20, 20)))
	return mesh_of(b)


## Kâğıt Klonu: beden yapraklara dağılıp yanında yeniden birleşir; asıl sen kısa süre görünmezsin, klon dikkati çeker ve patlar
func p_kami_bunshin(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	var at = gp(c.global_position + c.face_dir().cross(Vector3.UP) * 3.0)
	for k in 30:
		var sh = paper_sheet(0.3)
		get_tree().current_scene.add_child(sh)
		sh.global_position = c.global_position + Vector3.UP * randf_range(0.3, 1.8)
		var tw = sh.create_tween()
		tw.tween_property(sh, "global_position", at + Vector3(randf_range(-0.5, 0.5), randf_range(0.3, 1.8), randf_range(-0.5, 0.5)), 0.35 + randf() * 0.2)
		tw.tween_callback(sh.queue_free)
	Sfx.play("whoosh", c.global_position, 1.6, 0.6)
	after(0.45, func():
		if not live(c):
			return
		decoy(c, at, 8.0, func(pos):
			for k in 20:
				var sh2 = paper_sheet(0.25)
				get_tree().current_scene.add_child(sh2)
				sh2.global_position = pos + Vector3.UP
				var tw2 = sh2.create_tween()
				tw2.tween_property(sh2, "global_position", pos + Vector3(randf_range(-3, 3), randf_range(0.5, 3), randf_range(-3, 3)), 0.4)
				tw2.tween_callback(sh2.queue_free)
			FX.explosion(pos, 0.6)
			hit(c, pos + Vector3.UP, 2.6, inf(c, "kami_bunshin", 0.6, {"knock": 8.0, "kind": "heavy"})))
		if c is Player:
			Buffs.add("stealth_kami", 2.5, {"stealth": 1.0, "_desc": "kâğıt klon dikkati çekiyor"}))


## Kâğıt Kelebekler: kollardan kopan kelebek sürüsü düşmanların yüzüne kapanır (sersem + kesikler)
func p_kami_chocho(c: Node3D, t: Node3D) -> void:
	busy(c, 0.7)
	anim(c, "cast", 1.2)
	var foes = enemies_near(c, c.global_position + fwd(c, t) * 8.0, 9.0)
	var tt = tg(c, t, 18.0)
	if tt and not tt in foes:
		foes.append(tt)
	Sfx.play("wind", c.global_position, 1.8, 0.5)
	for e in foes.slice(0, 5):
		for k in 10:
			var b = MB.new()
			for sx in [-1.0, 1.0]:   # iki kanat
				b.add("box", Vector3(0.08 * sx, 0, 0), Vector3(0.14, 0.004, 0.12), PAPER if k % 3 else PAPER_V, Vector3(0, 0, 25 * sx))
			var bf = mesh_of(b)
			get_tree().current_scene.add_child(bf)
			var from = hand_pos(c, k % 2 == 0) + Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.4), randf_range(-0.3, 0.3))
			bf.global_position = from
			var mid = from.lerp(e.global_position, 0.5) + Vector3(randf_range(-2, 2), randf_range(1, 3), randf_range(-2, 2))
			var tw = bf.create_tween()
			tw.tween_property(bf, "global_position", mid, 0.35)
			tw.tween_property(bf, "global_position", e.global_position + Vector3.UP * e.height * 0.8 + Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.2), randf_range(-0.3, 0.3)), 0.3)
			tw.tween_interval(2.6)
			tw.tween_callback(bf.queue_free)
		after(0.65, func():
			if live(e):
				st(e, "stun", 3.0)
				e.take_hit(inf(c, "kami_chocho", 0.4, {"knock": 0.0, "kind": "light"}))
				Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Görüşü kapandı!", PAPER_V))


## Kâğıt Kanatlar: sırttan katmanlı kâğıt kanatlar açılır (kemiğe bağlı), 20 sn uçuş; kanat çırpınca kâğıt bıçaklar savrulur
func p_kami_tsubasa(c: Node3D, _t: Node3D) -> void:
	anim(c, "cast", 1.2)
	var m = c.get("model")
	var parts = []
	var wings = []
	if m and m.skel:
		var sk: Skeleton3D = m.skel
		var chest_b = "UpperChest" if sk.find_bone("UpperChest") >= 0 else "Chest"
		var p_ch: Vector3 = m._grest(sk.find_bone(chest_b)).origin
		for sx in [-1.0, 1.0]:
			var ba = m._attach(chest_b, Transform3D(Basis.IDENTITY, p_ch + Vector3(sx * 0.13, 0.0, -0.14)))   # kürek kemiği
			var b = MB.new()
			_paper_wing(b, sx)
			var wing = mesh_of(b)
			ba.get_child(0).add_child(wing)
			wing.scale = Vector3.ONE * 0.05
			wing.create_tween().tween_property(wing, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK)
			wing.set_meta("sx", sx)
			wings.append(wing)
			parts.append(ba)
	# kanat sırta bağlı ama gövde eğilse de dik durur (animedeki gibi kemer yukarıda, tüyler aşağı); yavaş çırpma
	every(20.0, 1.0 / 60.0, func(i, _k):
		if m == null or not is_instance_valid(m):
			return
		var tm = i / 60.0
		var fast = c is Player and Vector2(c.velocity.x, c.velocity.z).length() > 8.0
		var spd = 7.0 if fast else 4.0
		for w in wings:
			if not is_instance_valid(w):
				continue
			var sx = float(w.get_meta("sx"))
			var ph = sin(tm * spd)
			var sc: Vector3 = w.scale
			# çırpma: uçlar aşağı-yukarı (roll), kanat geriye katlanıp açılır (yaw), hızlıyken daha geride süzülür
			var roll = deg_to_rad(sx * (ph * 22.0 + 4.0))
			var yaw = deg_to_rad(-sx * ((30.0 if fast else 14.0) + cos(tm * spd) * 12.0))
			w.global_basis = m.global_basis.orthonormalized() * Basis.from_euler(Vector3(deg_to_rad(-8.0 + ph * 5.0), yaw, roll))
			w.scale = sc
		if i % 50 == 0 and live(c):
			Sfx.play("wind", c.global_position, 1.8, 0.25))
	Sfx.play("wind", c.global_position, 1.4)
	if c is Player and c.has_method("start_flight"):
		c.start_flight("kami", {"drain": 0.0, "speed": 20.0, "dur": 20.0})
		Buffs.add("kami_tsubasa", 20.0, {"speed": 1.15, "_name": "Kâğıt Kanatlar", "_desc": "uçuyorsun (Space/Ctrl); kanatlar kâğıt bıçak savurur"})
	every(20.0, 1.2, func(_i, _k):
		if not live(c):
			return
		var foes = enemies_near(c, c.global_position, 14.0)
		for k in 3:   # kanatlardan kopup savrulan kâğıtlar
			var sh = paper_sheet(0.12)
			get_tree().current_scene.add_child(sh)
			sh.global_position = c.global_position + Vector3(randf_range(-1.2, 1.2), randf_range(0.6, 2.4), randf_range(-0.6, 0.2))
			var tw = sh.create_tween()
			tw.tween_property(sh, "global_position", sh.global_position + Vector3(randf_range(-2, 2), randf_range(-2.5, -1), randf_range(-2, 2)), 1.4)
			tw.parallel().tween_property(sh, "rotation", Vector3(randf() * 6, randf() * 6, randf() * 6), 1.4)
			tw.tween_callback(sh.queue_free)
		if not foes.is_empty():
			var e = foes.pick_random()
			var b2 = MB.new()
			b2.add("box", Vector3.ZERO, Vector3(0.05, 0.005, 0.5), PAPER)
			shot(c, c.global_position + Vector3.UP * 1.4, (e.global_position + Vector3.UP - c.global_position - Vector3.UP * 1.4).normalized(), 40.0, mesh_of(b2), inf(c, "kami_tsubasa", 0.2, {"knock": 1.0, "kind": "light"}), null, false, 0.8), func():
		for pp in parts:
			if is_instance_valid(pp):
				pp.queue_free()
		if c is Player and is_instance_valid(c) and c.has_method("flight_source") and c.flight_source() == "kami":
			c.stop_flight())


## Shiki Dansı: bedenin etrafında yüzlerce kâğıt shuriken döner (kalkan), sonra hepsi hedefe yağar
func p_shikigami_no_mai(c: Node3D, t: Node3D) -> void:
	busy(c, 1.4)
	anim(c, "cast", 1.0)
	var ring = Node3D.new()
	get_tree().current_scene.add_child(ring)
	var stars = []
	for k in 36:
		var b = MB.new()
		for j in 4:
			b.add("box", Vector3.ZERO, Vector3(0.3, 0.005, 0.06), PAPER, Vector3(0, j * 45, 0))
		var mi = mesh_of(b)
		ring.add_child(mi)
		stars.append(mi)
	if c is Player:
		Buffs.add("shikigami", 1.2, {"armor": 0.3, "_name": "Kâğıt Kalkan"})
	every(1.1, 1.0 / 30.0, func(_i, k):
		if live(c) and is_instance_valid(ring):
			ring.global_position = c.global_position + Vector3.UP * 1.1
			for n in stars.size():
				var a = TAU * n / stars.size() + k * 9.0
				stars[n].position = Vector3(cos(a) * (1.4 + sin(n) * 0.3), sin(n * 1.7) * 0.8, sin(a) * (1.4 + sin(n) * 0.3))
				stars[n].rotation.y = k * 30.0 + n, func():
		if not is_instance_valid(ring):
			return
		var tt = tg(c, t, 30.0)
		var aim_p = tt.global_position + Vector3.UP if tt else c.global_position + fwd(c, t) * 20.0
		for n in stars.size():
			var from = stars[n].global_position
			var b3 = MB.new()
			for j in 4:
				b3.add("box", Vector3.ZERO, Vector3(0.3, 0.005, 0.06), PAPER, Vector3(0, j * 45, 0))
			var pr = shot(c, from, (aim_p - from).normalized().rotated(Vector3.UP, randf_range(-0.12, 0.12)), 45.0, mesh_of(b3), inf(c, "shikigami_no_mai", 0.08, {"knock": 1.0, "kind": "light"}), null, false, 1.2)
			pr.spin = Vector3(0, 40, 0)
		ring.queue_free()
		Sfx.play("whoosh", c.global_position, 1.3))


## Kâğıt Mızrak Ormanı: hedefin altından kâğıt mızraklar fışkırır, geniş halka halinde
func p_kami_yari(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	anim(c, "crouch", 1.4)
	var tt = tg(c, t, 24.0)
	var center = gp(tt.global_position if tt else c.global_position + fwd(c, t) * 10.0)
	for k in 22:
		after(0.15 + k * 0.025, func():
			var a = randf() * TAU
			var r = sqrt(randf()) * 4.5
			var q = center + Vector3(cos(a) * r, 0, sin(a) * r)
			q.y = Game.ground_height(q.x, q.z)
			var b = MB.new()
			var h = randf_range(1.8, 3.4)
			b.add("cone", Vector3(0, h * 0.5, 0), Vector3(0.28, h, 0.28), PAPER, Vector3(randf_range(-12, 12), 0, randf_range(-12, 12)), 4)
			var sp = mesh_of(b)
			get_tree().current_scene.add_child(sp)
			sp.global_position = q - Vector3.UP * h
			var tw = sp.create_tween()
			tw.tween_property(sp, "global_position", q, 0.08)
			tw.tween_interval(1.4)
			tw.tween_property(sp, "scale", Vector3(1, 0.05, 1), 0.25)
			tw.tween_callback(sp.queue_free))
	after(0.2, func():
		Sfx.play("earth", center, 1.6)
		hit(c, center + Vector3.UP, 4.8, inf(c, "kami_yari", 1.3, {"launch": 10.0, "knock": 3.0, "kind": "heavy"})))


## Kâğıt Tanrının Yolu: gökyüzü patlayıcı kâğıtlarla kaplanır, alan boyunca zincirleme patlamalar (son teknik)
func p_kami_no_shisha_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 1.6)
	anim(c, "cast", 0.8)
	var tt = tg(c, t, 40.0)
	var center = gp(tt.global_position if tt else c.global_position + fwd(c, t) * 18.0)
	# gökyüzünden yağan etiket bulutu
	for k in 120:
		after(randf() * 1.2, func():
			var sh = paper_sheet(0.4)
			get_tree().current_scene.add_child(sh)
			var q = center + Vector3(randf_range(-11, 11), 0, randf_range(-11, 11))
			sh.global_position = q + Vector3.UP * randf_range(14, 22)
			var tw = sh.create_tween()
			tw.tween_property(sh, "global_position", gp(q) + Vector3.UP * 0.2, randf_range(0.8, 1.4))
			tw.tween_interval(0.6)
			tw.tween_callback(sh.queue_free))
	Sfx.play("wind", center, 0.6)
	for k in 14:
		after(2.0 + k * 0.09, func():
			var q = center + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
			FX.explosion(gp(q), 1.4)
			if k % 3 == 0:
				shake(1.0)
			hit(c, gp(q) + Vector3.UP, 4.5, inf(c, "kami_no_shisha_no_jutsu", 0.55, {"knock": 14.0, "launch": 6.0, "kind": "heavy", "element": "katon"})))


# ================================================================== Kurbağa Bilgesi Yolu
const TOAD_OIL := Color(0.92, 0.75, 0.3)


## Kurbağa Yağı Mermisi: ağızdan kalın yağ topu; değdiği yerde kaygan yağ gölü (yavaşlatır, ateşle tutuşur)
func p_gamayudan(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	var d = fwd(c, t)
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(0.7, 0.6, 0.9), TOAD_OIL)
	var from = c.global_position + Vector3.UP * 1.5 + d * 0.6
	Sfx.play("water", from, 0.7)
	var pr = shot(c, from, d, 30.0, mesh_of(b, glow(TOAD_OIL, 0.85)), inf(c, "gamayudan", 0.7, {"knock": 6.0, "kind": "heavy"}), null, false, 1.2, func(p, _tgt):
		_oil_pool(c, p, 4.0, 8.0))
	Projectile.trail(pr, [Color(0.95, 0.8, 0.35, 0.8), Color(0.8, 0.6, 0.2, 0)], 0.4, 14, 0.4, FX.tex_smoke, false)


## Yağ gölü: içindekiler yavaşlar; ateş vurursa alev gölüne döner
func _oil_pool(c: Node3D, at: Vector3, r: float, dur: float) -> void:
	at = gp(at)
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = r; cm.bottom_radius = r; cm.height = 0.05
	mi.mesh = cm
	mi.material_override = flat_mat(Color(0.75, 0.55, 0.15, 0.75))
	get_tree().current_scene.add_child(mi)
	mi.global_position = at + Vector3.UP * 0.04
	every(dur, 0.5, func(_i, _k):
		for e in enemies_near(c, at, r):
			st(e, "slow", 1.0), func():
		if is_instance_valid(mi):
			mi.queue_free())


## Saç İğneleri: saç sertleşip ileriye yüzlerce iğne yağdırır
func p_kebari_senbon(c: Node3D, t: Node3D) -> void:
	busy(c, 0.9)
	anim(c, "crouch", 1.2)
	var d = fwd(c, t)
	var head = c.global_position + Vector3.UP * 1.7
	Sfx.play("whoosh", head, 1.7)
	for k in 40:
		after(k * 0.015, func():
			var b = MB.new()
			b.add("cyl", Vector3.ZERO, Vector3(0.015, 0.35, 0.015), Color(0.9, 0.9, 0.88), Vector3(90, 0, 0), 4)
			var dir = (d + Vector3(randf_range(-0.25, 0.25), randf_range(-0.12, 0.1), randf_range(-0.25, 0.25))).normalized()
			shot(c, head + Vector3(randf_range(-0.2, 0.2), randf_range(-0.1, 0.2), randf_range(-0.2, 0.2)), dir, 55.0, mesh_of(b), inf(c, "kebari_senbon", 0.07, {"knock": 0.5, "kind": "light"}), null, false, 0.6))


## Aslan Yelesi: saç uzayıp dev aslan yelesine döner, hedefi sarıp sıkar
func p_ranjishigami_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	busy(c, 1.2)
	anim(c, "crouch", 1.0)
	if tt == null:
		return
	var hair: Color = c.model.look.get("hair", Color(0.9, 0.9, 0.88)) if c.get("model") else Color(0.9, 0.9, 0.88)
	var strands = []
	for k in 7:
		var tw_n = tether(func(): return c.global_position + Vector3.UP * 1.75, func(): return tt.global_position + Vector3.UP * (0.6 + k * 0.15) if live(tt) else c.global_position, 0.12 + k * 0.01, glow(hair, 1.0), 2.4)
		strands.append(tw_n)
	Sfx.play("whoosh", c.global_position, 0.8)
	after(0.35, func():
		if live(tt):
			st(tt, "bind", 2.4)
			every(2.0, 0.5, func(_i, _k):
				if live(tt):
					tt.take_hit(inf(c, "ranjishigami_no_jutsu", 0.25, {"knock": 0.0, "kind": "light"})), Callable())
			Combat.popup_text(tt.global_position + Vector3.UP * 2.4, "Yeleye sarıldı!", Color(0.95, 0.9, 0.8)))


## Diken Bekçisi: saç bedeni saran dikenli bir kozaya döner (4 sn neredeyse hasarsız, yakına gelenler batar)
func p_hari_jizo(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.4)
	anim(c, "crouch", 1.2)
	var hair: Color = c.model.look.get("hair", Color(0.9, 0.9, 0.88)) if c.get("model") else Color(0.9, 0.9, 0.88)
	var b = MB.new()
	b.add("sphere", Vector3(0, 0.9, 0), Vector3(1.6, 1.9, 1.6), hair.darkened(0.1), Vector3.ZERO, 14)
	for k in 70:
		var a = randf() * TAU
		var e = randf_range(-0.6, 1.2)
		var d = Vector3(cos(a) * cos(e), sin(e), sin(a) * cos(e))
		b.add("cone", Vector3(0, 0.9, 0) + d * 0.8, Vector3(0.08, 0.5, 0.08), hair, Vector3(rad_to_deg(acos(clampf(d.y, -1, 1))), rad_to_deg(atan2(d.x, d.z)), 0), 4)
	var cocoon = mesh_of(b)
	get_tree().current_scene.add_child(cocoon)
	cocoon.global_position = c.global_position
	cocoon.scale = Vector3.ONE * 0.1
	cocoon.create_tween().tween_property(cocoon, "scale", Vector3.ONE, 0.2)
	if c is Player:
		Buffs.add("hari_jizo", 4.0, {"armor": 0.1, "_name": "Diken Bekçisi"})
	every(4.0, 0.25, func(_i, _k):
		if is_instance_valid(cocoon) and live(c):
			cocoon.global_position = c.global_position
			for e in enemies_near(c, c.global_position, 2.0):
				e.take_hit(inf(c, "hari_jizo", 0.15, {"knock": 6.0, "kind": "light"})), func():
		if is_instance_valid(cocoon):
			cocoon.queue_free())


## Kurbağa Midesi Bağı: çevre dev bir kurbağanın mide duvarlarına döner; içindekiler yapışıp erir
func p_kuchiyose_gamaguchi_shibari(c: Node3D, t: Node3D) -> void:
	busy(c, 0.9)
	var tt = tg(c, t, 16.0)
	var center = gp(tt.global_position if tt else c.global_position + fwd(c, t) * 6.0)
	summon_circle(c.global_position, 2.0, Color(1, 0.55, 0.15), 0.8)
	var b = MB.new()
	var flesh = Color(0.75, 0.35, 0.4)
	for k in 16:   # etli mide duvarı: kubbe halinde kıvrımlar
		var a = TAU * k / 16.0
		b.add("sphere", Vector3(cos(a) * 7.0, 2.5, sin(a) * 7.0), Vector3(3.6, 6.0, 3.0), flesh.darkened(0.1 * (k % 3)), Vector3(0, -rad_to_deg(a), 0), 10)
	b.add("cyl", Vector3(0, 0.05, 0), Vector3(14.0, 0.1, 14.0), flesh.darkened(0.25), Vector3.ZERO, 24)
	var wall = mesh_of(b)
	get_tree().current_scene.add_child(wall)
	wall.global_position = center
	wall.scale = Vector3(1, 0.05, 1)
	wall.create_tween().tween_property(wall, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK)
	Sfx.play("water", center, 0.5)
	every(6.0, 0.5, func(_i, _k):
		for e in enemies_near(c, center, 7.0):
			st(e, "bind", 0.6)
			e.take_hit(inf(c, "kuchiyose_gamaguchi_shibari", 0.12, {"knock": 0.0, "kind": "light"})), func():
		if is_instance_valid(wall):
			var tw = wall.create_tween()
			tw.tween_property(wall, "scale", Vector3(1, 0.05, 1), 0.4)
			tw.tween_callback(wall.queue_free))


## Kurbağa Yağı Alev Bombası: yanında beliren kurbağa yağ fışkırtır, sen ateşi üflersin — yağla büyüyen dev alev seli
func p_katon_gamayu_endan(c: Node3D, t: Node3D) -> void:
	busy(c, 1.4)
	var d = fwd(c, t)
	var side = d.cross(Vector3.UP).normalized()
	var toad_at = gp(c.global_position + side * 1.6)
	FX.smoke_puff(toad_at + Vector3.UP * 0.6, 1.0, 14)
	var tb = MB.new()
	tb.add("sphere", Vector3(0, 0.6, 0), Vector3(1.2, 1.0, 1.3), Color(0.85, 0.45, 0.2))
	tb.add("sphere", Vector3(0, 1.1, -0.45), Vector3(0.8, 0.5, 0.6), Color(0.9, 0.55, 0.25))
	var toad = mesh_of(tb)
	get_tree().current_scene.add_child(toad)
	toad.global_position = toad_at
	toad.look_at(toad_at + d, Vector3.UP)
	after(0.4, func():
		Sfx.play("water", toad_at, 0.6)
		VFX.puffs(toad_at + Vector3.UP * 1.1 + d, {"amount": 50, "life": 0.6, "size": 0.8, "radius": 0.4, "vmin": 12, "vmax": 20, "dir": d, "spread": 12.0,
			"colors": [Color(0.95, 0.8, 0.35, 0.9), Color(0.8, 0.6, 0.2, 0)]}))
	after(0.65, func():
		if not live(c):
			return
		anim(c, "push", 1.2)
		Sfx.play("fire", c.global_position, 0.6)
		for k in 7:
			after(k * 0.06, func():
				VFX.puffs(c.global_position + Vector3.UP * 1.4 + d * (2.0 + k * 2.6), {"amount": 40, "life": 1.0, "size": 1.6 + k * 0.45, "radius": 0.8 + k * 0.5, "vmin": 4, "vmax": 9, "dir": d, "spread": 22.0,
					"colors": [Color(1, 0.75, 0.3, 0.95), Color(1, 0.35, 0.1, 0.6), Color(0.3, 0.1, 0.05, 0)]}))
		Combat.hit_zone(c, c.global_position, d, 22.0, 24.0, 4.0, inf(c, "katon_gamayu_endan", 1.6, {"element": "katon", "burn": 3.0, "knock": 8.0, "kind": "heavy"}))
		# yerde yanan yağ gölü
		var pool_at = gp(c.global_position + d * 12.0)
		every(5.0, 0.5, func(_i, _k):
			VFX.puffs(pool_at + Vector3.UP * 0.5, {"amount": 10, "life": 0.6, "size": 1.0, "radius": 3.0, "vmin": 1, "vmax": 3, "dir": Vector3.UP, "spread": 20.0,
				"colors": [Color(1, 0.6, 0.2, 0.8), Color(1, 0.3, 0.1, 0)]})
			for e in enemies_near(c, pool_at, 4.0):
				e.take_hit(inf(c, "katon_gamayu_endan", 0.12, {"element": "katon", "burn": 1.0, "knock": 0.0, "kind": "light"})), Callable())
		shake(0.7))
	after(1.6, func():
		if is_instance_valid(toad):
			FX.smoke_puff(toad.global_position + Vector3.UP * 0.6, 1.0, 12)
			toad.queue_free())


## Bilge Sanatı: Kurbağa Çağrısı — omuzlarında iki yaşlı kurbağa belirir, şarkılarını duyan herkes 6 sn donar
func p_senpo_kawazu_naki(c: Node3D, _t: Node3D) -> void:
	busy(c, 1.6)
	anim(c, "cast", 0.8)
	var elders = []
	var m = c.get("model")
	if m and m.skel:
		var sk: Skeleton3D = m.skel
		var chest_b = "UpperChest" if sk.find_bone("UpperChest") >= 0 else "Chest"
		for sx in [-1.0, 1.0]:
			var ua = "LeftUpperArm" if sx > 0 else "RightUpperArm"
			var sh_b = "LeftShoulder" if sx > 0 else "RightShoulder"
			if sk.find_bone(sh_b) < 0:
				sh_b = chest_b
			var p_ua: Vector3 = m._grest(sk.find_bone(ua)).origin
			var p_sh: Vector3 = m._grest(sk.find_bone(sh_b)).origin
			# omzun üst yüzeyi: kol ekleminin hemen üstü, kafanın yanından dışarıda
			var seat = p_ua + Vector3(sx * 0.035, 0.035, -0.01)
			# model uzayında dik duran, öne bakan yaşlı kurbağa (sağ omuzda dişi: mor dudak); omuz kemiğiyle birlikte hareket eder
			var ba = m._attach(sh_b, Transform3D(Basis.IDENTITY, seat))
			var mi = mesh_of(_elder_toad(sx < 0))
			ba.get_child(0).add_child(mi)
			mi.scale = Vector3.ONE * 0.05
			mi.create_tween().tween_property(mi, "scale", Vector3.ONE * 0.62, 0.3).set_trans(Tween.TRANS_BACK)
			FX.smoke_puff(c.global_position + Vector3.UP * 1.6 + c.face_dir().cross(Vector3.UP) * -sx * 0.2, 0.3, 6)
			elders.append(ba)
	Sfx.play("genjutsu", c.global_position, 0.5)
	for k in 4:
		after(0.4 + k * 0.3, func():
			FX.ring(c.global_position + Vector3.UP * 1.6, Color(1, 0.75, 0.3), 6.0 + k * 6.0, 0.6))
	after(1.2, func():
		for e in enemies_near(c, c.global_position, 26.0):
			st(e, "stun", 6.0)
			Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Kurbağa şarkısı!", Color(1, 0.75, 0.3)))
	after(6.0, func():
		for ba in elders:
			if is_instance_valid(ba):
				ba.queue_free())


## Konan'ın melek kanadı: omuzdan başın üstüne kemer, oradan dizlere kadar sarkan tüy sütunları; her tüy küçük kâğıt tuğlalardan
func _paper_wing(b: MB, sx: float) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 77 if sx > 0 else 78
	var arm := func(u: float) -> Vector3:   # kemer (ikinci derece bezier): kök → yukarı → dış tepe
		var p0 = Vector2(0.0, 0.0); var p1 = Vector2(0.55, 0.12); var p2 = Vector2(1.0, 0.8)   # omuz hizasında dışa, uçta yukarı kemer
		var q = p0.lerp(p1, u).lerp(p1.lerp(p2, u), u)
		return Vector3(q.x * sx, q.y, -0.05 - q.x * 0.12)
	var cols = 15
	for ci in cols:
		var u = 0.12 + 0.88 * (ci + 0.5) / cols   # kökte (sırtta) tüy yok
		var top: Vector3 = arm.call(u)
		var L = 0.35 + 1.75 * pow(u, 1.3)                        # dışa doğru uzayan tüyler (dizlere iner)
		var dir = Vector3(sx * (0.1 + 0.3 * u), -1.0, -0.05).normalized()
		var n = int(L / 0.075)
		for k in n:
			var f = float(k) / maxf(1.0, n - 1)
			var w = 0.16 * (1.0 - 0.5 * pow(f, 2.0))           # uca doğru daralan tüy
			var q = top + dir * (k * 0.075) + Vector3(rng.randf_range(-0.012, 0.012), 0, (ci % 2) * -0.012)
			var col = PAPER.darkened(rng.randf_range(0.0, 0.1) + 0.06 * f)
			b.add("box", q, Vector3(w, 0.11, 0.008), col, Vector3(-4, 0, rad_to_deg(atan2(dir.x, -dir.y)) * -1.0 + rng.randf_range(-8, 8)))
	# kemer üzerindeki kalın üst kenar: çift sıra tuğla
	for k in 22:
		var u = 0.1 + 0.9 * k / 21.0
		var q: Vector3 = arm.call(u)
		var q2: Vector3 = arm.call(minf(1.0, u + 0.05))
		var ang = rad_to_deg(atan2(q2.y - q.y, (q2.x - q.x) * sx))
		for r in 2:
			b.add("box", q + Vector3(0, -0.06 * r, 0.006), Vector3(0.13, 0.09, 0.009), PAPER.darkened(0.03 * r + rng.randf_range(0, 0.05)), Vector3(-10, 0, ang * sx))


## Omuzda oturan yaşlı bilge kurbağa: yüksek yakalı cübbe, kulak diski, alın bandı; erkek: beyaz diken saç/kaş/keçi sakal + sırtta parşömen, dişi: kıvırcık mor saç, mor dudak (+Z öne bakar)
func _elder_toad(female: bool) -> MB:
	var skin = Color(0.48, 0.58, 0.3) if not female else Color(0.85, 0.86, 0.62)
	var robe = Color(0.5, 0.48, 0.45) if not female else Color(0.28, 0.2, 0.32)
	var robe_d = robe.darkened(0.25)
	var white = Color(0.95, 0.95, 0.93)
	var purple = Color(0.55, 0.32, 0.65)
	var b = MB.new()
	# gövde cübbenin içinde: yalnızca ayaklar dışarıda
	b.add("sphere", Vector3(0, 0.07, 0), Vector3(0.2, 0.15, 0.19), skin)
	for ex in [-1.0, 1.0]:
		b.add("sphere", Vector3(ex * 0.07, 0.012, 0.075), Vector3(0.045, 0.025, 0.06), skin)          # ön ayak parmakları
	b.add("sphere", Vector3(0, 0.08, -0.005), Vector3(0.235, 0.18, 0.225), robe, Vector3.ZERO, 12)    # cübbe gövdeyi sarar
	b.add("cyl", Vector3(0, 0.008, -0.005), Vector3(0.25, 0.016, 0.23), robe_d, Vector3.ZERO, 12)     # etek kenarı
	b.add("cyl", Vector3(0, 0.14, -0.005), Vector3(0.205, 0.05, 0.195), robe_d, Vector3.ZERO, 14)    # kalın yüksek yaka
	b.add("cyl", Vector3(0, 0.168, -0.005), Vector3(0.21, 0.012, 0.2), robe, Vector3.ZERO, 14)      # yaka kıvrımı
	b.add("sphere", Vector3(0, 0.17, -0.065), Vector3(0.15, 0.11, 0.07), robe_d)                      # sırtta kapüşon
	b.add("box", Vector3(0, 0.11, 0.1), Vector3(0.012, 0.09, 0.006), robe_d)                          # önde cübbe yarığı
	# baş
	b.add("sphere", Vector3(0, 0.17, 0.02), Vector3(0.18, 0.12, 0.16), skin)
	b.add("sphere", Vector3(0, 0.145, 0.07), Vector3(0.13, 0.05, 0.08), skin.darkened(0.05))         # ağız/çene
	for ex in [-1.0, 1.0]:
		b.add("sphere", Vector3(ex * 0.055, 0.215, 0.065), Vector3(0.055, 0.045, 0.045), skin)        # göz tümseği
		b.add("sphere", Vector3(ex * 0.058, 0.218, 0.085), Vector3(0.034, 0.03, 0.012), Color(0.92, 0.7, 0.2))
		b.add("box", Vector3(ex * 0.058, 0.218, 0.092), Vector3(0.024, 0.005, 0.003), Color(0.05, 0.05, 0.05))
		b.add("cyl", Vector3(ex * 0.088, 0.17, 0.01), Vector3(0.035, 0.008, 0.035), Color(0.7, 0.7, 0.66), Vector3(0, 0, 90), 10)   # kulak diski
		b.add("box", Vector3(ex * 0.092, 0.17, 0.01), Vector3(0.002, 0.004, 0.026), Color(0.35, 0.35, 0.33))
	b.add("cyl", Vector3(0, 0.2, 0.02), Vector3(0.185, 0.02, 0.165), Color(0.2, 0.24, 0.42), Vector3(-12, 0, 0), 16)   # alın bandı başı sarar
	b.add("box", Vector3(0, 0.208, 0.1), Vector3(0.045, 0.022, 0.004), Color(0.78, 0.8, 0.84), Vector3(-12, 0, 0))     # bant plakası
	b.add("box", Vector3(0, 0.208, 0.103), Vector3(0.024, 0.004, 0.002), Color(0.3, 0.3, 0.32), Vector3(-12, 0, 0))
	if not female:
		b.add("box", Vector3(0, 0.135, 0.11), Vector3(0.07, 0.004, 0.004), Color(0.15, 0.17, 0.1))   # düz, ciddi ağız
		for ex in [-1.0, 1.0]:
			for k in 3:   # diken kaşlar
				b.add("cone", Vector3(ex * (0.045 + k * 0.018), 0.238 + k * 0.004, 0.085), Vector3(0.016, 0.05, 0.01), white, Vector3(0, 0, -ex * (55 + k * 12)), 4)
		for k in 5:   # tepede beyaz diken saç
			b.add("cone", Vector3((k - 2) * 0.022, 0.27, 0.0 - abs(k - 2) * 0.01), Vector3(0.022, 0.06, 0.022), white, Vector3(-15, 0, (k - 2) * 22), 4)
		b.add("cone", Vector3(0, 0.11, 0.1), Vector3(0.035, 0.05, 0.015), white, Vector3(180, 0, 0), 4)   # keçi sakal
		b.add("cyl", Vector3(0.0, 0.13, -0.12), Vector3(0.035, 0.18, 0.035), Color(0.9, 0.82, 0.62), Vector3(0, 0, 70), 8)   # sırtta parşömen
		b.add("cyl", Vector3(0.0, 0.13, -0.12), Vector3(0.04, 0.03, 0.04), Color(0.6, 0.15, 0.12), Vector3(0, 0, 70), 8)
	else:
		b.add("box", Vector3(0, 0.138, 0.112), Vector3(0.1, 0.012, 0.006), purple, Vector3(0, 0, 0))   # geniş mor dudak (gülümser)
		for ex in [-1.0, 1.0]:
			b.add("box", Vector3(ex * 0.055, 0.143, 0.108), Vector3(0.025, 0.01, 0.006), purple, Vector3(0, 0, ex * 20))
		for k in 9:   # kıvırcık mor saç topları
			var a = PI * (k / 8.0)
			b.add("sphere", Vector3(cos(a) * 0.085, 0.24 + sin(a) * 0.045, -0.03), Vector3(0.05, 0.05, 0.05), purple)
		b.add("sphere", Vector3(0, 0.27, -0.02), Vector3(0.12, 0.06, 0.1), purple)
	return b


## Katlanmış kâğıt shuriken: 4 kanat, her kanat iki üçgen yüz (kat çizgisi gölgeli), ortada kare göbek
func _paper_star() -> MB:
	var b = MB.new()
	for k in 4:
		var a = k * 90.0
		var d = Vector3(cos(deg_to_rad(a)), 0, sin(deg_to_rad(a)))
		b.add("cone", d * 0.11, Vector3(0.09, 0.2, 0.006), PAPER, Vector3(90, 0, 0).rotated(Vector3.UP, 0) + Vector3(0, -a + 90, 0), 3)
		b.add("box", d * 0.1 + Vector3(0, 0.004, 0), Vector3(0.012, 0.004, 0.16), PAPER.darkened(0.2), Vector3(0, -a + 90, 0))   # kat çizgisi
	b.add("box", Vector3.ZERO, Vector3(0.08, 0.012, 0.08), PAPER.darkened(0.08), Vector3(0, 45, 0))
	return b


## Kâğıt Shuriken: elden yelpaze gibi açılan 5 katlanmış kâğıt yıldız; dönerek uçar, hedefe hafif yönelir, arkasında kâğıt kırpıntıları
func p_kami_shuriken(c: Node3D, t: Node3D) -> void:
	busy(c, 0.45)
	var tt = tg(c, t, 30.0)
	var d = fwd(c, t)
	if tt:
		d = (tt.global_position + Vector3.UP - c.global_position - Vector3.UP * 1.3).normalized()
	var from = hand_pos(c, true)
	Sfx.play("whoosh", from, 1.8, 0.5)
	for k in 5:
		after(k * 0.05, func():
			if not live(c):
				return
			var dir = d.rotated(Vector3.UP, deg_to_rad((k - 2) * 7.0))
			var pr = shot(c, from, dir, 38.0, mesh_of(_paper_star()), inf(c, "kami_shuriken", 0.35, {"knock": 1.5, "kind": "light", "bleed": 2.0}), tt, false, 1.4)
			pr.spin = Vector3(0, 28.0, 0)
			Projectile.trail(pr, [Color(1, 1, 1, 0.9), Color(0.85, 0.82, 0.95, 0)], 0.08, 10, 0.35, null, false))


# ================================================================== Akademi / genel teknikler (kendi koreografisi)
const LEAF := Color(0.45, 0.75, 0.3)


func _kick_pose(c: Node3D, dur: float) -> void:
	if c.get("model") and c.model.overlay:
		c.model.overlay.set_pose("kick", 1.0)
		after(dur, func():
			if is_instance_valid(c) and c.get("model") and c.model.overlay:
				c.model.overlay.set_pose("kick", 0.0))


func _leaves(at: Vector3, n: int, spd := 6.0) -> void:
	VFX.puffs(at, {"amount": n, "life": 0.9, "size": 0.18, "radius": 0.6, "vmin": spd * 0.5, "vmax": spd, "dir": Vector3.UP, "spread": 80.0, "add": false,
		"colors": [LEAF, LEAF.darkened(0.3), Color(0.6, 0.8, 0.35, 0)]})


## Atış yönü: hedef varsa göğsüne, yoksa nişangâha (Jutsu._aim)
func aim_at(c: Node3D, tt: Node3D, from: Vector3) -> Vector3:
	if tt and is_instance_valid(tt):
		return (tt.global_position + Vector3.UP * tt.height * 0.55 - from).normalized()
	return Jutsu._aim(c, tt)


func _face(c: Node3D, tt: Node3D) -> Vector3:
	var d = fwd(c, tt)
	if tt:
		d = tt.global_position - c.global_position
		d.y = 0
		d = d.normalized()
		if c is Player:
			c.combat.face_to(tt)
	return d


## Gölge Shuriken: tek büyük shuriken; hedefe yaklaşınca gölgesindeki ikinci shuriken ayrılıp yandan vurur
func p_kage_shuriken_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.4)
	var tt = tg(c, t, 30.0)
	var from = hand_pos(c, true)
	var dir = aim_at(c, tt, from)
	var mk = func() -> MeshInstance3D:
		var b = MB.new()
		for k in 4:
			b.add("cone", Vector3(cos(k * PI / 2.0), 0, sin(k * PI / 2.0)) * 0.13, Vector3(0.07, 0.22, 0.01), Color(0.55, 0.57, 0.62), Vector3(90, -k * 90.0 + 90.0, 0), 3)
		b.add("cyl", Vector3.ZERO, Vector3(0.09, 0.02, 0.09), Color(0.3, 0.3, 0.33), Vector3.ZERO, 10)
		return mesh_of(b)
	Sfx.play("whoosh", from, 1.5, 0.5)
	var p1 = shot(c, from, dir, 30.0, mk.call(), inf(c, "kage_shuriken_no_jutsu", 0.6, {"knock": 2.0, "kind": "light", "bleed": 2.0}), tt, false, 1.6)
	p1.spin = Vector3(0, 30, 0)
	after(0.18, func():
		if not is_instance_valid(p1):
			return
		var side = dir.cross(Vector3.UP).normalized() * (1.0 if randf() < 0.5 else -1.0)
		var p2 = shot(c, p1.global_position - Vector3.UP * 0.25, (dir + side * 0.35).normalized(), 30.0, mk.call(), inf(c, "kage_shuriken_no_jutsu", 0.6, {"knock": 2.0, "kind": "light", "bleed": 2.0}), tt, false, 1.4)
		p2.spin = Vector3(0, -30, 0)
		p2.homing_turn = 6.0
		Combat.popup_text(p1.global_position + Vector3.UP * 0.6, "Gölgede ikinci!", Color(0.8, 0.8, 0.9)))


## Gölge Senbon: senbon yelpazesi; gölgesinden ikinci yelpaze gecikmeyle çıkar
func p_kage_senbon(c: Node3D, t: Node3D) -> void:
	busy(c, 0.4)
	var tt = tg(c, t, 25.0)
	var from = hand_pos(c, true)
	var dir = aim_at(c, tt, from)
	for wave in 2:
		after(wave * 0.2, func():
			if not live(c):
				return
			for k in 5:
				var b = MB.new()
				b.add("cyl", Vector3.ZERO, Vector3(0.012, 0.32, 0.012), Color(0.85, 0.86, 0.9), Vector3(90, 0, 0), 4)
				var d = dir.rotated(Vector3.UP, deg_to_rad((k - 2) * 4.0)) + Vector3.UP * (0.02 * (wave * 2 - 1))
				shot(c, from - Vector3.UP * 0.12 * wave, d.normalized(), 48.0, mesh_of(b), inf(c, "kage_senbon", 0.12, {"knock": 0.5, "kind": "light"}), null, false, 0.9))
	Sfx.play("whoosh", from, 1.9, 0.4)


## Yaprak Kasırgası (Senpū): zıplayıp dönen yüksek tekme — çevresindeki herkesi savurur, yapraklar uçuşur
func p_konoha_senpu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.55)
	var tt = tg(c, t, 6.0)
	var d = _face(c, tt)
	_kick_pose(c, 0.45)
	if c is CharacterBody3D:
		c.velocity = d * (8.0 if tt else 3.0) + Vector3.UP * 4.0
	var ctr = c.global_position + Vector3.UP * 1.1
	for k in 8:
		after(k * 0.04, func():
			var a = k * TAU / 8.0
			VFX.puffs(ctr + Vector3(cos(a), 0, sin(a)) * 1.3, {"amount": 4, "life": 0.3, "size": 0.35, "radius": 0.1, "vmin": 1, "vmax": 2, "dir": Vector3.UP, "spread": 30.0,
				"colors": [Color(1, 1, 1, 0.7), Color(1, 1, 1, 0)]}))
	_leaves(c.global_position + Vector3.UP * 0.4, 30)
	Sfx.play("whoosh", ctr, 1.2, 0.6)
	after(0.15, func():
		if live(c):
			hit(c, c.global_position + Vector3.UP * 1.1, 2.4, inf(c, "konoha_senpu", 1.1, {"knock": 12.0, "launch": 3.0, "kind": "heavy"})))


## Yaprak Kasırgası (Reppū): kayarak alçak süpürme tekmesi — ayağını alır, yere serer
func p_konoha_reppu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.6)
	var d = _face(c, tg(c, t, 7.0))
	anim(c, "slide", 1.6)
	if c is CharacterBody3D:
		c.velocity = d * 12.0
	_leaves(c.global_position + Vector3.UP * 0.2, 20, 4.0)
	after(0.2, func():
		if not live(c):
			return
		for e in hit(c, c.global_position + d * 1.0 + Vector3.UP * 0.3, 1.6, inf(c, "konoha_reppu", 0.9, {"knock": 3.0, "kind": "heavy"})):
			st(e, "stun", 1.2)
			Combat.popup_text(e.global_position + Vector3.UP * 2.0, "Ayağı alındı!", LEAF))
	Sfx.play("whoosh", c.global_position, 1.0, 0.5)


## Dinamik Giriş: uçan çift ayak tekmesi — hedefe atılır, çarpınca uzağa savurur
func p_dainamikku_entori(c: Node3D, t: Node3D) -> void:
	var d = _face(c, tg(c, t, 14.0))
	busy(c, 0.6)
	_kick_pose(c, 0.55)
	if c is CharacterBody3D:
		c.velocity = d * 22.0 + Vector3.UP * 4.0
	var done := {"v": false}
	every(0.5, 1.0 / 30.0, func(_i, _k):
		if done["v"] or not live(c):
			return
		VFX.puffs(c.global_position + Vector3.UP * 0.8, {"amount": 2, "life": 0.25, "size": 0.4, "radius": 0.2, "vmin": 0, "vmax": 1, "dir": Vector3.UP, "spread": 20.0,
			"colors": [Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)]})
		var hs = hit(c, c.global_position + Vector3.UP * 0.9 + d * 0.8, 1.2, inf(c, "dainamikku_entori", 1.4, {"knock": 22.0, "launch": 4.0, "kind": "heavy", "dir": d}))
		if not hs.is_empty():
			done["v"] = true
			shake(0.4)
			FX.impact(hs[0].global_position + Vector3.UP, Color(1, 0.9, 0.7), 1.2)
			if c is CharacterBody3D:
				c.velocity = -d * 5.0 + Vector3.UP * 5.0)





## Bin Yıllık Ölüm: hedefin arkasında belirip iki parmakla dürter — hedef havaya fırlar
func p_sennen_goroshi(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 10.0)
	if tt == null:
		if c is Player:
			Hud.msg("Arkasına geçecek hedef yok", Color(1, 0.7, 0.5))
		return
	busy(c, 0.8)
	FX.smoke_puff(c.global_position + Vector3.UP, 0.6, 8)
	var away = (tt.global_position - c.global_position)
	away.y = 0
	c.global_position = gp(tt.global_position + away.normalized() * 1.1)
	if c is Player:
		c.combat.face_to(tt)
	anim(c, "crouch", 1.5)
	Combat.popup_text(c.global_position + Vector3.UP * 2.2, "Bin Yıllık Ölüm!!", Color(1, 0.6, 0.7))
	after(0.45, func():
		if not live(tt) or not live(c):
			return
		anim(c, "jab", 1.6)
		tt.take_hit(inf(c, "sennen_goroshi", 0.8, {"knock": 2.0, "launch": 14.0, "kind": "heavy"}))
		st(tt, "stun", 1.5)
		VFX.puffs(tt.global_position + Vector3.UP * 0.9, {"amount": 20, "life": 0.5, "size": 0.3, "radius": 0.2, "vmin": 3, "vmax": 7, "dir": Vector3.UP, "spread": 50.0,
			"colors": [Color(1, 0.7, 0.8, 0.9), Color(1, 0.9, 0.9, 0)]})
		Sfx.play("punch", tt.global_position, 1.4))


## Geçici Felç: bakışla bağlanan genjutsu — hedefin çevresinde mor bağ çizgileri, 2.5 sn kıpırdayamaz
func p_kanashibari_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 16.0)
	busy(c, 0.5)
	anim(c, "cast", 1.2)
	if tt == null:
		return
	var col = Color(0.65, 0.35, 0.9)
	for k in 6:
		var a = k * TAU / 6.0
		tether(func(): return tt.global_position + Vector3(cos(a) * 0.9, 1.6, sin(a) * 0.9) if live(tt) else Vector3.ZERO,
			func(): return tt.global_position + Vector3(cos(a + 2.1) * 0.9, 0.2, sin(a + 2.1) * 0.9) if live(tt) else Vector3.ZERO, 0.03, glow(col, 0.8), 2.5)
	FX.ring(tt.global_position + Vector3.UP * 0.1, col, 2.2, 0.6)
	st(tt, "stun", 2.5)
	Combat.popup_text(tt.global_position + Vector3.UP * 2.3, "Felç!", col)
	Sfx.play("genjutsu", tt.global_position, 1.2)


## PSTYLE: doton_renga_no_jutsu=ground doton_sazareishi=palm doton_shinju_zanshu_no_jutsu=ground kasumi_jusha_no_jutsu=sense oboro_bunshin_no_jutsu=clone doton_tobi_tsubute=ground doton_dosekiryu=ground doton_retsudo_tensho=ground futon_reppusho=palm futon_kazekiri_no_jutsu=palm katon_endan=breath
# ------------------------------------------------------------------ Grup 2: düşük seviye toprak / rüzgâr / ateş / klon
const EARTH := Color(0.55, 0.42, 0.3)


func _rock(s: float, col := EARTH) -> MeshInstance3D:
	var b = MB.new()
	b.add("boulder", Vector3.ZERO, Vector3(s, s * 0.8, s), col, Vector3(randf() * 360, randf() * 360, 0), 3)
	return mesh_of(b)











## Sis Hizmetkârı: sisin içinden hayalet askerler çıkar — vurdukları gerçek değil ama düşmanı oyalar ve korkutur
func p_kasumi_jusha_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.6)
	anim(c, "cast", 1.2)
	var center = c.global_position + c.face_dir() * 3.0
	VFX.puffs(center + Vector3.UP, {"amount": 60, "life": 2.5, "size": 2.5, "radius": 3.5, "vmin": 0.2, "vmax": 0.8, "dir": Vector3.UP, "spread": 60.0, "add": false,
		"colors": [Color(0.85, 0.9, 0.95, 0.5), Color(0.8, 0.85, 0.9, 0)]})
	for k in 4:
		var a = (k - 1.5) * 0.6
		decoy(c, center + c.face_dir().rotated(Vector3.UP, a) * 2.0, 7.0)
	for e in enemies_near(c, center, 10.0):
		st(e, "slow", 3.0)
	Sfx.play("genjutsu", center, 0.9)


## Pus Klonu: titreşen saydam kopyalar etrafa dağılır; düşmanlar onlara saldırır
func p_oboro_bunshin_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.4)
	for k in 3:
		var a = TAU * k / 3.0
		var at = c.global_position + Vector3(cos(a), 0, sin(a)) * 2.2
		VFX.puffs(at + Vector3.UP, {"amount": 14, "life": 0.6, "size": 0.9, "radius": 0.5, "vmin": 0.5, "vmax": 1.5, "dir": Vector3.UP, "spread": 40.0, "add": false,
			"colors": [Color(0.9, 0.92, 1.0, 0.6), Color(0.9, 0.92, 1.0, 0)]})
		decoy(c, at, 6.0)
	Sfx.play("poof", c.global_position, 1.2)


















## PSTYLE: bubble_clone_technique=clone bubitorappu=ground chakura_kontororu_baku=palm earth_release_rock_shelter=ground fujinheki=two_palm futon_fujin_no_jutsu=breath futon_toppa=breath genjutsu_shibari=sense hayanie=rush jouro_senbon=throw juha_sho=spin kamaitachi_no_jutsu=spin konoha_daisenpu=rush konoha_otoshi=rush kaeru_kaeru_no_jutsu=palm

# ------------------------------------------------------------------ Grup 3: rüzgâr / genjutsu / taijutsu / tuzak
const WIND := Color(0.85, 1.0, 0.95)


## Köpük Klonu: köpükten parlak kopya; düşman dokununca patlayıp ıslatır ve sersemletir
func p_bubble_clone_technique(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.4)
	var at = c.global_position + c.face_dir().cross(Vector3.UP) * 2.5
	VFX.puffs(at + Vector3.UP, {"amount": 40, "life": 0.8, "size": 0.35, "radius": 0.8, "vmin": 1, "vmax": 3, "dir": Vector3.UP, "spread": 90.0, "add": false,
		"colors": [Color(0.8, 0.95, 1.0, 0.8), Color(0.7, 0.9, 1.0, 0)]})
	decoy(c, at, 8.0, func(pos):
		VFX.puffs(pos + Vector3.UP, {"amount": 60, "life": 0.7, "size": 0.45, "radius": 1.0, "vmin": 4, "vmax": 9, "dir": Vector3.UP, "spread": 180.0, "add": false,
			"colors": [Color(0.8, 0.95, 1.0, 0.9), Color(0.7, 0.9, 1.0, 0)]})
		for e in hit(c, pos + Vector3.UP, 3.5, inf(c, "bubble_clone_technique", 0.5, {"knock": 6.0, "kind": "heavy", "element": "suiton"})):
			st(e, "stun", 1.5)
		Sfx.play("water", pos, 1.3))
	Sfx.play("water", at, 1.5)


## Tuzak: yere patlayıcı etiketli tel gerilir; üstüne basan düşman patlamayla havalanır
func p_bubitorappu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	anim(c, "crouch", 1.6)
	var at = gp(c.global_position + fwd(c, t) * 4.0)
	var b = MB.new()
	b.add("box", Vector3(0, 0.05, 0), Vector3(3.0, 0.01, 0.02), Color(0.85, 0.85, 0.8))
	for k in 3:
		b.add("box", Vector3(-1.0 + k * 1.0, 0.04, 0), Vector3(0.18, 0.01, 0.28), Color(0.95, 0.9, 0.75))
		b.add("box", Vector3(-1.0 + k * 1.0, 0.05, 0), Vector3(0.06, 0.012, 0.2), Color(0.8, 0.15, 0.1))
	var trap = mesh_of(b)
	get_tree().current_scene.add_child(trap)
	trap.global_position = at
	trap.look_at(at + fwd(c, t).cross(Vector3.UP), Vector3.UP)
	var fired := {"v": false}
	every(20.0, 0.15, func(_i, _k):
		if fired["v"] or not is_instance_valid(trap):
			return
		if not enemies_near(c, at, 1.8).is_empty():
			fired["v"] = true
			FX.explosion(at + Vector3.UP * 0.3, 1.6)
			shake(0.6)
			hit(c, at + Vector3.UP, 3.5, inf(c, "bubitorappu", 1.4, {"knock": 14.0, "launch": 9.0, "kind": "heavy", "element": "katon"}))
			trap.queue_free(), func():
		if is_instance_valid(trap):
			trap.queue_free())


## Çakra Bağı: avuçtan uzanan mavi çakra iplikleri hedefi sarar, kıpırdatmaz
func p_chakura_kontororu_baku(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	busy(c, 0.5)
	if tt == null:
		return
	var col = Color(0.4, 0.75, 1.0)
	for k in 4:
		tether(func(): return hand_pos(c, k % 2 == 0) if live(c) else Vector3.ZERO, func(): return tt.global_position + Vector3.UP * (0.5 + k * 0.35) if live(tt) else Vector3.ZERO, 0.04, glow(col, 0.9), 2.6)
	st(tt, "bind", 2.6)
	FX.ring(tt.global_position + Vector3.UP, col, 1.6, 0.5, false)
	Sfx.play("seal", tt.global_position, 1.2)





## Rüzgâr Duvarı: önünde dönen rüzgâr perdesi — mermileri savurur, yaklaşanı iter
func p_fujinheki(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	var d = fwd(c, t)
	var at = c.global_position + d * 2.0
	every(4.0, 0.1, func(_i, k):
		var side = d.cross(Vector3.UP)
		for j in 3:
			var q = at + side * randf_range(-3.0, 3.0) + Vector3.UP * randf_range(0.2, 3.0)
			VFX.puffs(q, {"amount": 2, "life": 0.4, "size": 0.6, "radius": 0.1, "vmin": 2, "vmax": 5, "dir": Vector3.UP, "spread": 40.0,
				"colors": [Color(0.85, 1, 0.95, 0.5), Color(0.85, 1, 0.95, 0)]})
		for p in get_tree().get_nodes_in_group("projectiles"):
			if p.get("shooter") != c and p.global_position.distance_to(at) < 3.5:
				p.queue_free()
		for e in enemies_near(c, at, 3.2):
			if e.get("velocity") != null:
				e.velocity += d * 4.0)
	if c is Player:
		Buffs.add("fujinheki", 4.0, {"armor": 0.6, "_name": "Rüzgâr Duvarı"})
	Sfx.play("wind", at, 0.9)








## Genjutsu Bağı: göz göze gelince dünya kırmızı-siyaha döner, hedef olduğu yerde donar
func p_genjutsu_shibari(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	busy(c, 0.5)
	anim(c, "cast", 1.2)
	if tt == null:
		return
	var col = Color(0.75, 0.1, 0.2)
	for k in 3:
		after(k * 0.15, func():
			if live(tt):
				FX.ring(tt.global_position + Vector3.UP * 1.6, col, 1.0 + k * 1.2, 0.5, false, (c.global_position - tt.global_position).normalized()))
	st(tt, "stun", 3.0)
	Combat.popup_text(tt.global_position + Vector3.UP * 2.4, "Genjutsu!", col)
	Sfx.play("genjutsu", tt.global_position, 0.8)


## Erken Kurban: hedefi yakalar, havaya kaldırıp sırtüstü yere çakar
func p_hayanie(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 4.0)
	busy(c, 0.8)
	_face(c, tt)
	anim(c, "push", 1.4)
	if tt == null:
		return
	st(tt, "stun", 1.2)
	var y0 = tt.global_position
	var tw = tt.create_tween()
	tw.tween_property(tt, "global_position", y0 + Vector3.UP * 2.2 + c.face_dir() * 0.5, 0.25)
	tw.tween_property(tt, "global_position", gp(y0 + c.face_dir() * 1.5), 0.12)
	tw.tween_callback(func():
		if live(tt):
			tt.take_hit(inf(c, "hayanie", 1.6, {"knock": 2.0, "kind": "heavy"}))
			FX.impact(tt.global_position, Color(0.9, 0.8, 0.6), 1.3)
			VFX.debris(tt.global_position, EARTH, 12, 5.0)
			shake(0.5)
			Sfx.play("hit_heavy", tt.global_position, 1.0))


## Senbon Yağmuru: gökyüzüne atılan senbonlar hedefin üstünde açılıp yağar
func p_jouro_senbon(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	anim(c, "throw", 1.5)
	var tt = tg(c, t, 24.0)
	var at = tt.global_position if tt else c.global_position + fwd(c, t) * 10.0
	for k in 30:
		after(0.35 + randf() * 0.5, func():
			var b = MB.new()
			b.add("cyl", Vector3.ZERO, Vector3(0.012, 0.32, 0.012), Color(0.85, 0.86, 0.9), Vector3(90, 0, 0), 4)
			var q = at + Vector3(randf_range(-2.5, 2.5), 9.0, randf_range(-2.5, 2.5))
			shot(c, q, (at + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)) - q).normalized(), 40.0, mesh_of(b), inf(c, "jouro_senbon", 0.07, {"knock": 0.3, "kind": "light"}), null, false, 0.5))
	Sfx.play("whoosh", c.global_position, 1.7)








## Büyük Yaprak Kasırgası: art arda üç dönen tekme, her biri daha yüksek
func p_konoha_daisenpu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	var d = _face(c, tt)
	busy(c, 1.0)
	for k in 3:
		after(k * 0.28, func():
			if not live(c):
				return
			_kick_pose(c, 0.22)
			if c is CharacterBody3D:
				c.velocity = d * 5.0 + Vector3.UP * (3.0 + k * 1.5)
			_leaves(c.global_position + Vector3.UP * 0.6, 18)
			hit(c, c.global_position + Vector3.UP * (1.0 + k * 0.3) + d * 0.8, 2.2, inf(c, "konoha_daisenpu", 0.6, {"knock": 4.0 + k * 6.0, "launch": 2.0 + k * 2.0, "kind": "heavy"}))
			Sfx.play("punch", c.global_position, 1.2 - k * 0.1))


## Yaprak Düşüşü: havaya sıçrayıp yukarıdan topukla iner — yer çatlar
func p_konoha_otoshi(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 7.0)
	var d = _face(c, tt)
	busy(c, 0.8)
	if c is CharacterBody3D:
		c.velocity = d * 4.0 + Vector3.UP * 9.0
	_kick_pose(c, 0.7)
	after(0.45, func():
		if not live(c):
			return
		if c is CharacterBody3D:
			c.velocity = d * 3.0 + Vector3.DOWN * 22.0
		after(0.15, func():
			var at = gp(c.global_position + d * 0.8)
			FX.impact(at + Vector3.UP * 0.3, Color(1, 0.9, 0.7), 1.4)
			FX.ring(at + Vector3.UP * 0.05, EARTH, 4.0, 0.4)
			VFX.debris(at, EARTH, 16, 6.0)
			shake(0.6)
			for e in hit(c, at + Vector3.UP, 2.4, inf(c, "konoha_otoshi", 1.5, {"knock": 4.0, "kind": "heavy"})):
				st(e, "stun", 1.0)
			Sfx.play("hit_heavy", at, 0.9)))


## Kurbağaya Dönüştürme: hedef duman bulutunda küçük bir kurbağaya döner (kısa süre zararsız ve yavaş)
func p_kaeru_kaeru_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	busy(c, 0.5)
	if tt == null:
		return
	FX.smoke_puff(tt.global_position + Vector3.UP, 1.0, 16)
	var body = tt.get("model") if tt.get("model") else null
	var b = MB.new()
	b.add("sphere", Vector3(0, 0.25, 0), Vector3(0.6, 0.45, 0.65), Color(0.4, 0.65, 0.3))
	for ex in [-1.0, 1.0]:
		b.add("sphere", Vector3(ex * 0.15, 0.5, 0.2), Vector3(0.14, 0.14, 0.14), Color(0.95, 0.9, 0.3))
	var frog = mesh_of(b)
	tt.add_child(frog)
	if body:
		body.visible = false
	st(tt, "stun", 4.0)
	Combat.popup_text(tt.global_position + Vector3.UP * 1.5, "Vrak!", Color(0.5, 0.85, 0.4))
	after(4.0, func():
		if is_instance_valid(frog):
			frog.queue_free()
		if is_instance_valid(body):
			body.visible = true
		if live(tt):
			FX.smoke_puff(tt.global_position + Vector3.UP, 1.0, 12))
	Sfx.play("poof", tt.global_position, 1.0)
## PSTYLE: futon_hanachiri_mai=spin genjutsu_suzune_bunshin=sense kage_buyo=rush karasu_bunshin_no_jutsu=clone kawazu_kumite=power kawazu_tataki=rush konoha_shofu=rush kumo_ryu_omotegiri=rush kumo_ryu_uragiri=rush kumo_shibari=palm kumo_soka=palm kumogakure_taijutsu_okami_ringu=spin kyomeisen=palm mizuame_teppo=breath nekozume=rush okasho=rush raigeki=rush raigyaku_suihei_choppu=rush raikyu=palm raiton_ikazuchi_unagi=palm raiton_raiju_tsuiga=palm rakanken=rush shikomishindan=throw shishi_rendan=rush

# ------------------------------------------------------------------ Grup 4: rüzgâr dansı / ses / genjutsu / senjutsu / ağ / Bulut kılıcı / şimşek / ağır taijutsu
const RAI := Color(0.65, 0.85, 1.0)
const WEB := Color(0.92, 0.92, 0.88)
const SAGE := Color(1.0, 0.65, 0.2)


func _bolt(a: Vector3, b: Vector3, col := RAI, w := 0.12) -> void:
	VFX.bolt(a, b, col, w, 0.25, 0)


func _jump_at(c: Node3D, tt: Node3D, up: float, fwd_v: float) -> Vector3:
	var d = _face(c, tt)
	if c is CharacterBody3D:
		c.velocity = d * fwd_v + Vector3.UP * up
	return d





## Zil Sesi Klonu: zil çalar, hedefin etrafında sallanan sahte kopyalar belirir — hepsi aynı anda saldırıyormuş gibi görünür
func p_genjutsu_suzune_bunshin(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	busy(c, 0.5)
	anim(c, "cast", 1.2)
	Sfx.play("seal", c.global_position, 2.0)
	if tt == null:
		return
	for k in 4:
		var a = TAU * k / 4.0
		decoy(c, tt.global_position + Vector3(cos(a), 0, sin(a)) * 2.5, 3.0)
	st(tt, "stun", 2.2)
	FX.ring(tt.global_position + Vector3.UP * 1.6, Color(1, 0.9, 0.5), 3.0, 0.6, false)
	Combat.popup_text(tt.global_position + Vector3.UP * 2.4, "Çın çın...", Color(1, 0.9, 0.5))


## Dans Eden Yaprağın Gölgesi: hedefi tekmeyle havaya fırlatır, gölgesi gibi peşinden sıçrar ve tepede vurur
func p_kage_buyo(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 5.0)
	busy(c, 1.0)
	_face(c, tt)
	_kick_pose(c, 0.25)
	if tt == null:
		return
	tt.take_hit(inf(c, "kage_buyo", 0.4, {"knock": 0.0, "launch": 13.0, "kind": "heavy"}))
	_leaves(tt.global_position, 20)
	after(0.3, func():
		if not live(c) or not live(tt):
			return
		c.global_position = tt.global_position - c.face_dir() * 0.8 - Vector3.UP * 0.6
		if c is CharacterBody3D:
			c.velocity = Vector3.UP * 3.0
		Combat.popup_text(c.global_position + Vector3.UP * 2.2, "Kage Buyō!", LEAF)
		after(0.2, func():
			if live(tt):
				anim(c, "hook", 1.6)
				tt.take_hit(inf(c, "kage_buyo", 0.9, {"knock": 8.0, "launch": -8.0, "kind": "heavy"}))
				FX.impact(tt.global_position + Vector3.UP, Color(1, 0.9, 0.7), 1.0)))


## Karga Klonu: beden karga sürüsüne dağılır, sürü düşmanın etrafında döner ve yanında yeniden birleşir
func p_karasu_bunshin_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.6)
	var tt = tg(c, t, 20.0)
	var black = Color(0.06, 0.06, 0.08)
	for k in 25:
		var b = MB.new()
		b.add("box", Vector3.ZERO, Vector3(0.35, 0.02, 0.12), black)
		b.add("sphere", Vector3(0, 0.03, 0.06), Vector3(0.08, 0.08, 0.12), black)
		var bird = mesh_of(b)
		get_tree().current_scene.add_child(bird)
		bird.global_position = c.global_position + Vector3.UP * randf_range(0.4, 1.8)
		var end = (tt.global_position if tt else c.global_position + fwd(c, t) * 8.0) + Vector3(randf_range(-2, 2), randf_range(0.5, 2.5), randf_range(-2, 2))
		var tw = bird.create_tween()
		tw.tween_property(bird, "global_position", end, 0.6 + randf() * 0.3)
		tw.tween_callback(bird.queue_free)
	decoy(c, c.global_position, 6.0)
	if tt:
		after(0.8, func():
			for e in enemies_near(c, tt.global_position, 3.0):
				st(e, "stun", 1.5)
				e.take_hit(inf(c, "karasu_bunshin_no_jutsu", 0.4, {"knock": 2.0, "kind": "light"})))
	Sfx.play("whoosh", c.global_position, 1.3)


## Kurbağa Dövüş Stili: doğa enerjisi aurası — yumruklar ıskalasa da aura vurur (12 sn yakın dövüş güçlü ve uzun)
func p_kawazu_kumite(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.5)
	anim(c, "fold", 1.0)
	VFX.puffs(c.global_position + Vector3.UP, {"amount": 50, "life": 1.0, "size": 0.6, "radius": 0.8, "vmin": 1, "vmax": 3, "dir": Vector3.UP, "spread": 40.0,
		"colors": [Color(1, 0.75, 0.3, 0.7), Color(1, 0.6, 0.2, 0)]})
	if c is Player:
		Buffs.add("kawazu_kumite", 12.0, {"melee": 1.6, "reach": 1.5, "_name": "Kurbağa Kata", "_desc": "doğa enerjisi aurası: yakın dövüş +%60, menzil +%50"})
	every(12.0, 0.4, func(_i, _k):
		if live(c):
			VFX.puffs(c.global_position + Vector3.UP * 1.0, {"amount": 5, "life": 0.6, "size": 0.4, "radius": 0.6, "vmin": 0.5, "vmax": 1.5, "dir": Vector3.UP, "spread": 30.0,
				"colors": [Color(1, 0.75, 0.3, 0.5), Color(1, 0.6, 0.2, 0)]}), Callable())
	Sfx.play("seal", c.global_position, 0.8)


## Kurbağa Vuruşu: doğa enerjili tek ağır yumruk — dokunmadan önce aura çarpar, uzağa uçurur
func p_kawazu_tataki(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	_jump_at(c, tt, 0.0, 10.0 if tt else 3.0)
	busy(c, 0.6)
	after(0.2, func():
		if not live(c):
			return
		anim(c, "cross", 1.4)
		var at = c.global_position + c.face_dir() * 1.4 + Vector3.UP * 1.1
		FX.impact(at, SAGE, 1.6)
		FX.ring(at, SAGE, 3.0, 0.4, false, c.face_dir())
		shake(0.5)
		hit(c, at, 2.0, inf(c, "kawazu_tataki", 1.8, {"knock": 24.0, "launch": 4.0, "kind": "heavy"}))
		Sfx.play("hit_heavy", at, 0.8))


## Yükselen Yaprak Rüzgârı: çömelip yukarı tekme — hedef dik havaya fırlar
func p_konoha_shofu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 4.0)
	_jump_at(c, tt, 0.0, 6.0 if tt else 0.0)
	busy(c, 0.5)
	anim(c, "crouch", 2.0)
	after(0.18, func():
		if not live(c):
			return
		_kick_pose(c, 0.3)
		_leaves(c.global_position + Vector3.UP * 0.4, 20, 8.0)
		hit(c, c.global_position + c.face_dir() * 0.8 + Vector3.UP * 0.8, 1.6, inf(c, "konoha_shofu", 1.0, {"knock": 1.0, "launch": 16.0, "kind": "heavy"}))
		Sfx.play("punch", c.global_position, 1.1))


## Bulut Stili Ön Kesik: tek adımda öne atılıp çapraz kılıç darbesi (kılıç yoksa çakra bıçağı)
func p_kumo_ryu_omotegiri(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 9.0)
	var d = _jump_at(c, tt, 0.0, 26.0 if tt else 12.0)
	busy(c, 0.5)
	anim(c, "slash_a", 1.8)
	after(0.12, func():
		if not live(c):
			return
		if c is CharacterBody3D:
			c.velocity = d * 2.0
		_arc_cut(c.global_position + Vector3.UP * 1.1 + d * 1.0, d, -40.0, 40.0, Color(0.85, 0.9, 1.0))
		hit(c, c.global_position + Vector3.UP * 1.0 + d * 1.2, 1.8, inf(c, "kumo_ryu_omotegiri", 1.2, {"knock": 8.0, "kind": "heavy", "bleed": 3.0}))
		Sfx.play("clink", c.global_position, 1.3))


## Bulut Stili Ters Kesik: ters tutuşla dönüp sırttan gelen aldatıcı kesik — rakip savunamaz (sersemler)
func p_kumo_ryu_uragiri(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	var d = _jump_at(c, tt, 0.0, 10.0 if tt else 4.0)
	busy(c, 0.6)
	anim(c, "slash_c", 1.7)
	after(0.2, func():
		if not live(c):
			return
		_arc_cut(c.global_position + Vector3.UP * 0.9 + d * 0.9, d, 160.0, 20.0, Color(0.9, 0.85, 1.0))
		for e in hit(c, c.global_position + Vector3.UP + d * 1.1, 1.8, inf(c, "kumo_ryu_uragiri", 1.1, {"knock": 6.0, "kind": "heavy", "bleed": 3.0})):
			st(e, "stun", 0.8)
		Sfx.play("clink", c.global_position, 1.1))


## Kılıç yayı izi: yatay yay boyunca parlak ince şeritler (a0..a1 derece)
func _arc_cut(at: Vector3, d: Vector3, a0: float, a1: float, col: Color, r := 1.4) -> void:
	for k in 9:
		var a = deg_to_rad(lerpf(a0, a1, k / 8.0))
		var q = at + d.rotated(Vector3.UP, a) * r
		var seg = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.35, 0.03, 0.05)
		seg.mesh = bm
		seg.material_override = glow(col, 0.9)
		get_tree().current_scene.add_child(seg)
		seg.global_position = q
		seg.rotation.y = atan2(d.rotated(Vector3.UP, a).x, d.rotated(Vector3.UP, a).z) + PI * 0.5
		var tw = seg.create_tween()
		tw.tween_interval(k * 0.012)
		tw.tween_property(seg, "scale", Vector3(0.01, 1, 1), 0.25)
		tw.tween_callback(seg.queue_free)


## Örümcek Ağı Bağı: avuçtan fırlayan yapışkan ağ topu hedefte açılıp sarar
func p_kumo_shibari(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	busy(c, 0.4)
	var from = hand_pos(c, true)
	var b = MB.new()
	for k in 6:
		b.add("box", Vector3.ZERO, Vector3(0.7, 0.01, 0.02), WEB, Vector3(0, k * 30.0, 0))
	b.add("torus", Vector3.ZERO, Vector3(0.4, 0.4, 0.02), WEB, Vector3(90, 0, 0), 10)
	shot(c, from, aim_at(c, tt, from), 30.0, mesh_of(b), inf(c, "kumo_shibari", 0.3, {"knock": 0.0, "kind": "light"}), tt, false, 1.0, func(p, h):
		if h and live(h):
			st(h, "bind", 3.0)
			for k in 5:
				tether(func(): return h.global_position + Vector3(cos(k * 1.26), 0.2, sin(k * 1.26)) * 0.8 if live(h) else Vector3.ZERO,
					func(): return h.global_position + Vector3(cos(k * 1.26 + 2.5), 1.5, sin(k * 1.26 + 2.5)) * 0.6 if live(h) else Vector3.ZERO, 0.03, glow(WEB, 0.9), 3.0)
			Combat.popup_text(h.global_position + Vector3.UP * 2.3, "Ağa takıldı!", WEB))
	Sfx.play("whoosh", from, 1.6, 0.5)


## Çiçek Ağı: havada dev çiçek desenli ağ açılır ve geniş alana iner — içindekiler yapışır
func p_kumo_soka(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 22.0)
	busy(c, 0.7)
	anim(c, "throw", 1.3)
	var at = gp(tt.global_position if tt else c.global_position + fwd(c, t) * 9.0)
	var b = MB.new()
	for k in 12:
		b.add("box", Vector3.ZERO, Vector3(8.0, 0.02, 0.04), WEB, Vector3(0, k * 15.0, 0))
	for r in [1.2, 2.2, 3.2, 4.0]:
		b.add("torus", Vector3.ZERO, Vector3(r * 2.0, r * 2.0, 0.04), WEB, Vector3(90, 0, 0), 24)
	var net = mesh_of(b)
	get_tree().current_scene.add_child(net)
	net.global_position = at + Vector3.UP * 6.0
	net.scale = Vector3.ONE * 0.1
	var tw = net.create_tween()
	tw.tween_property(net, "scale", Vector3.ONE, 0.3)
	tw.parallel().tween_property(net, "global_position", at + Vector3.UP * 0.6, 0.45)
	tw.tween_callback(func():
		for e in enemies_near(c, at, 4.5):
			st(e, "bind", 3.5)
			e.take_hit(inf(c, "kumo_soka", 0.3, {"knock": 0.0, "kind": "light"})))
	tw.tween_interval(3.5)
	tw.tween_callback(net.queue_free)
	Sfx.play("whoosh", at, 0.8)


## Kurt Halkası: kılıçla kendi etrafında tam tur dönerek daire kesik — her yandaki düşmana
func p_kumogakure_taijutsu_okami_ringu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.7)
	anim(c, "slash_b", 1.4)
	var at = c.global_position + Vector3.UP * 1.0
	_arc_cut(at, c.face_dir(), 0.0, 360.0, Color(0.85, 0.9, 1.0), 2.4)
	_arc_cut(at + Vector3.UP * 0.3, c.face_dir(), 20.0, 380.0, Color(0.7, 0.85, 1.0), 2.8)
	after(0.15, func():
		hit(c, at, 3.2, inf(c, "kumogakure_taijutsu_okami_ringu", 1.2, {"knock": 12.0, "kind": "heavy", "bleed": 3.0})))
	Sfx.play("clink", at, 1.0)


## Ses Yankısı: ses dalgası iç kulağı vurur — hedef sendeler, dengesini kaybeder (yavaş + kısa sersem)
func p_kyomeisen(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 16.0)
	busy(c, 0.5)
	anim(c, "push", 1.4)
	var d = fwd(c, tt)
	for k in 4:
		after(k * 0.08, func():
			FX.ring(c.global_position + Vector3.UP * 1.3 + d * (1.5 + k * 2.5), Color(0.8, 0.75, 1.0), 1.2 + k * 0.6, 0.35, false, d))
	if tt:
		after(0.3, func():
			if live(tt):
				st(tt, "stun", 1.2)
				st(tt, "slow", 4.0)
				tt.take_hit(inf(c, "kyomeisen", 0.4, {"knock": 1.0, "kind": "light"}))
				Combat.popup_text(tt.global_position + Vector3.UP * 2.3, "Denge bozuldu!", Color(0.8, 0.75, 1.0)))
	Sfx.play("genjutsu", c.global_position, 1.6)


## Şurup Mermileri: ağızdan yapışkan şurup topları — yere yapıştırır
func p_mizuame_teppo(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	busy(c, 0.6)
	var from = c.global_position + Vector3.UP * 1.55 + c.face_dir() * 0.4
	var syrup = Color(0.95, 0.75, 0.35)
	for k in 3:
		after(k * 0.15, func():
			if not live(c):
				return
			var b = MB.new()
			b.add("sphere", Vector3.ZERO, Vector3(0.5, 0.45, 0.6), syrup)
			shot(c, from, aim_at(c, tt, from), 24.0, mesh_of(b, glow(syrup, 0.85)), inf(c, "mizuame_teppo", 0.25, {"knock": 2.0, "kind": "light", "element": "suiton"}), null, false, 1.2, func(p, h):
				_oil_pool(c, p, 2.0, 4.0)
				if h and live(h):
					st(h, "bind", 2.0)))
	Sfx.play("water", from, 0.9)


## Kedi Pençesi: çakralı pençelerle çapraz üçlü çizik
func p_nekozume(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	var d = _jump_at(c, tt, 2.0, 12.0 if tt else 4.0)
	busy(c, 0.6)
	for k in 3:
		after(0.1 + k * 0.1, func():
			if not live(c):
				return
			anim(c, "hook" if k % 2 == 0 else "cross", 2.0)
			var at = c.global_position + Vector3.UP * 1.1 + d * 1.0
			for j in 3:
				var cut = MeshInstance3D.new()
				var bm = BoxMesh.new()
				bm.size = Vector3(0.04, 1.0, 0.04)
				cut.mesh = bm
				cut.material_override = glow(Color(0.7, 0.9, 1.0), 0.9)
				get_tree().current_scene.add_child(cut)
				cut.global_position = at + d.cross(Vector3.UP) * (j - 1) * 0.18
				cut.rotation = Vector3(0, atan2(d.x, d.z), deg_to_rad(35.0 * (1 if k % 2 == 0 else -1)))
				cut.create_tween().tween_property(cut, "scale", Vector3(1, 0.01, 1), 0.25).finished.connect(cut.queue_free)
			hit(c, at, 1.6, inf(c, "nekozume", 0.4, {"knock": 3.0, "kind": "light", "bleed": 2.0})))
	Sfx.play("whoosh", c.global_position, 1.5)




















## Rakan Yumruğu: ağır, dalga gibi art arda dört yumruk — her biri ileri iter
func p_rakanken(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 5.0)
	var d = _face(c, tt)
	busy(c, 1.0)
	for k in 4:
		after(k * 0.2, func():
			if not live(c):
				return
			anim(c, "jab" if k % 2 == 0 else "cross", 1.6)
			if c is CharacterBody3D:
				c.velocity = d * 5.0
			var at = c.global_position + Vector3.UP * 1.1 + d * 1.2
			FX.impact(at, Color(1, 0.85, 0.6), 0.8 + k * 0.2)
			hit(c, at, 1.6, inf(c, "rakanken", 0.5 + k * 0.15, {"knock": 3.0 + k * 4.0, "kind": "heavy"}))
			Sfx.play("punch", at, 1.0 - k * 0.08))


## Gizli İğne Fırlatıcı: bilek düzeneğinden sessizce zehirli iğneler (yeşil iz), zehirler
func p_shikomishindan(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	busy(c, 0.3)
	var from = hand_pos(c, true)
	for k in 4:
		after(k * 0.06, func():
			var b = MB.new()
			b.add("cyl", Vector3.ZERO, Vector3(0.012, 0.25, 0.012), Color(0.6, 0.8, 0.5), Vector3(90, 0, 0), 4)
			var pr = shot(c, from, aim_at(c, tt, from).rotated(Vector3.UP, randf_range(-0.04, 0.04)), 50.0, mesh_of(b), inf(c, "shikomishindan", 0.12, {"knock": 0.2, "kind": "light", "poison": 4.0}), null, false, 0.8)
			Projectile.trail(pr, [Color(0.5, 0.9, 0.4, 0.6), Color(0.4, 0.8, 0.3, 0)], 0.06, 8, 0.2, null, true))
	Sfx.play("kunai", from, 1.6, 0.4)


## Aslan Kombosu: tekmeyle havaya atar, gölge gibi arkasından sıçrar, art arda tekmeler ve havadan yere çakar
func p_shishi_rendan(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 5.0)
	busy(c, 1.6)
	_face(c, tt)
	_kick_pose(c, 0.25)
	if tt == null:
		return
	tt.take_hit(inf(c, "shishi_rendan", 0.4, {"knock": 0.0, "launch": 14.0, "kind": "heavy"}))
	after(0.3, func():
		if not live(c) or not live(tt):
			return
		c.global_position = tt.global_position - c.face_dir() * 0.8 - Vector3.UP * 0.4
		for k in 3:
			after(k * 0.12, func():
				if live(tt):
					_kick_pose(c, 0.1)
					tt.take_hit(inf(c, "shishi_rendan", 0.35, {"knock": 0.0, "launch": 2.0, "kind": "light"}))
					FX.impact(tt.global_position + Vector3.UP, Color(1, 0.9, 0.7), 0.7))
		after(0.45, func():
			if live(tt):
				anim(c, "hook", 1.4)
				tt.take_hit(inf(c, "shishi_rendan", 1.4, {"knock": 4.0, "launch": -22.0, "kind": "heavy"}))
				Combat.popup_text(tt.global_position + Vector3.UP * 2.0, "Shishi Rendan!", Color(1, 0.6, 0.3))
				after(0.3, func():
					if live(tt):
						FX.impact(tt.global_position, Color(1, 0.85, 0.6), 1.6)
						VFX.debris(tt.global_position, EARTH, 18, 7.0)
						shake(0.6)
						Sfx.play("hit_heavy", tt.global_position, 0.8))))
## PSTYLE: gofu_kekkai=seal mizu_bunshin_no_jutsu=clone nan_no_kaizo=power narikawari_no_jutsu=clone sanzengarasu_no_jutsu=sense sly_mind_affect_technique=sense sosai_no_ne=palm soshujin=throw suiken=rush suiton_homatsu_rappa=breath suiton_kokuu_no_jutsu=breath suiton_mizu_shibari=palm suiton_mizu_shuriken=throw suiton_mizuame_nabara=breath suiton_mizurappa=breath suiton_suiben=palm suiton_suidan_no_jutsu=breath suiton_suisandan=breath suiton_takitsubo_no_jutsu=ground suiton_teppodama=breath tsukikage=rush tsutenkyaku=rush uchi_naru_sakura=power water_release_wild_water_wave=breath zankukyokuha=two_palm zessenbaku=palm zessenzan=palm

# ------------------------------------------------------------------ Grup 5: su / mühür / ses / genjutsu / kurbağa dili / ağır taijutsu
const WATER := Color(0.35, 0.65, 1.0)


func _water_mat(a := 0.75) -> Material:
	return glow(Color(0.45, 0.75, 1.0), a)


func _splash(at: Vector3, s := 1.0) -> void:
	VFX.puffs(at, {"amount": int(30 * s), "life": 0.6, "size": 0.35 * s, "radius": 0.4 * s, "vmin": 3 * s, "vmax": 8 * s, "dir": Vector3.UP, "spread": 70.0, "add": false,
		"gravity": Vector3(0, -12, 0), "colors": [Color(0.75, 0.9, 1.0, 0.9), Color(0.5, 0.75, 1.0, 0)]})


func _mouth_pos(c: Node3D) -> Vector3:
	return c.global_position + Vector3.UP * 1.55 + c.face_dir() * 0.4


## Su küresi mermisi (ortak): ağızdan, çarpınca sıçrar
func _water_shot(c: Node3D, id: String, tt: Node3D, from: Vector3, s: float, speed: float, mul: float, extra := {}) -> Projectile:
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(s, s, s * 1.3), WATER)
	var info = {"knock": 6.0 * s, "kind": "heavy", "element": "suiton"}
	info.merge(extra, true)
	var pr = shot(c, from, aim_at(c, tt, from), speed, mesh_of(b, _water_mat()), inf(c, id, mul, info), null, false, 1.4, func(p, _h):
		_splash(p, s * 1.4))
	Projectile.trail(pr, [Color(0.75, 0.9, 1.0, 0.7), Color(0.5, 0.75, 1.0, 0)], s * 0.5, 18, 0.35, FX.tex_smoke, false)
	return pr


## Beş Mühür Bariyeri: beş etiket yere yapışır, aralarında mor ışıklı duvar örülür — geçilmez (içerideki düşman kapanır)
func p_gofu_kekkai(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	busy(c, 0.8)
	var at = gp(tt.global_position if tt else c.global_position + fwd(c, t) * 6.0)
	var col = Color(0.65, 0.4, 1.0)
	var pts = []
	for k in 5:
		var a = TAU * k / 5.0
		pts.append(at + Vector3(cos(a), 0, sin(a)) * 3.0)
	var b = MB.new()
	for k in 5:
		var p0: Vector3 = pts[k] - at
		var p1: Vector3 = pts[(k + 1) % 5] - at
		var mid = (p0 + p1) * 0.5 + Vector3.UP * 1.5
		b.add("box", mid, Vector3(p0.distance_to(p1), 3.0, 0.05), col, Vector3(0, -rad_to_deg(atan2(p1.z - p0.z, p1.x - p0.x)), 0))
		b.add("box", p0 + Vector3.UP * 0.4, Vector3(0.18, 0.3, 0.02), Color(0.95, 0.9, 0.75))
	var wall = mesh_of(b, glow(col, 0.35))
	get_tree().current_scene.add_child(wall)
	wall.global_position = at
	wall.scale = Vector3(1, 0.01, 1)
	var tw = wall.create_tween()
	tw.tween_property(wall, "scale", Vector3.ONE, 0.3)
	tw.tween_interval(6.0)
	tw.tween_property(wall, "scale", Vector3(1, 0.01, 1), 0.3)
	tw.tween_callback(wall.queue_free)
	for e in enemies_near(c, at, 3.0):
		st(e, "bind", 6.0)
		Combat.popup_text(e.global_position + Vector3.UP * 2.3, "Mühür bariyeri!", col)
	Sfx.play("seal", at, 0.8)


## Su Klonu: ayağının dibindeki sudan bir kopya yükselir; vurulunca su olup sıçrar
func p_mizu_bunshin_no_jutsu(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.5)
	var at = c.global_position + c.face_dir().cross(Vector3.UP) * 2.2
	_splash(at, 1.5)
	decoy(c, at, 9.0, func(pos):
		_splash(pos + Vector3.UP, 2.0))
	Sfx.play("water", at, 1.1)


## Lastik Beden: kollar ve bacaklar uzar (15 sn yakın dövüş menzili çok artar)
func p_nan_no_kaizo(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.4)
	if c.get("model") and c.model.overlay:
		c.model.overlay.limb_scale = 1.25
		after(15.0, func():
			if is_instance_valid(c) and c.get("model") and c.model.overlay:
				c.model.overlay.limb_scale = 1.0)
	if c is Player:
		Buffs.add("nan_no_kaizo", 15.0, {"reach": 1.8, "_name": "Lastik Beden", "_desc": "uzuvlar uzadı: yakın dövüş menzili +%80"})
	Sfx.play("whoosh", c.global_position, 0.7)


## Ayrı Beden İkamesi: saklı ikinci bedenin yerine geçer — 4 sn içindeki ilk darbeyi o alır (kütük değil, insan kabuğu)
func p_narikawari_no_jutsu(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.3)
	if c is Player:
		Buffs.add("narikawari", 4.0, {"armor": 0.0, "_name": "İkame Beden", "_desc": "sonraki darbe ikame bedene gider"})
	var shell = decoy(c, c.global_position, 4.0)
	FX.smoke_puff(c.global_position + Vector3.UP, 0.8, 12)
	c.global_position = gp(c.global_position - c.face_dir() * 4.0)
	Sfx.play("poof", c.global_position, 1.1)


## Bin Karga: hedefin etrafında kapkara bir karga fırtınası döner — göremez, saldıramaz
func p_sanzengarasu_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	busy(c, 0.6)
	if tt == null:
		return
	var black = Color(0.05, 0.05, 0.07)
	var birds = []
	for k in 40:
		var b = MB.new()
		b.add("box", Vector3.ZERO, Vector3(0.3, 0.02, 0.1), black)
		var bird = mesh_of(b)
		get_tree().current_scene.add_child(bird)
		birds.append(bird)
	every(3.0, 1.0 / 30.0, func(i, _k):
		if not live(tt):
			return
		for n in birds.size():
			var a = i * 0.25 + n * 0.7
			var r = 1.2 + (n % 5) * 0.3
			birds[n].global_position = tt.global_position + Vector3(cos(a) * r, 0.3 + (n % 7) * 0.3, sin(a) * r)
			birds[n].rotation.y = -a, func():
		for bd in birds:
			if is_instance_valid(bd):
				bd.queue_free())
	st(tt, "stun", 3.0)
	if tt.has_method("lose_target"):
		tt.lose_target(3.0)
	Sfx.play("genjutsu", tt.global_position, 1.0)


## Yol Kaybettirme: hedef düz yürüdüğünü sanırken daire çizer (6 sn yavaş, hedef kaybeder)
func p_sly_mind_affect_technique(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	busy(c, 0.5)
	anim(c, "cast", 1.2)
	if tt == null:
		return
	for k in 3:
		FX.ring(tt.global_position + Vector3.UP * 0.05, Color(0.6, 0.5, 0.9), 2.0 + k * 1.5, 1.2)
	st(tt, "slow", 6.0)
	if tt.has_method("lose_target"):
		tt.lose_target(6.0)
	Combat.popup_text(tt.global_position + Vector3.UP * 2.3, "Kayboldu...", Color(0.7, 0.6, 0.95))
	Sfx.play("genjutsu", tt.global_position, 1.3)


## Ses Bastırma: karşı ses dalgası — yakındaki düşman mermilerini ve ses tekniklerini söndürür, yakındakileri sersemletir
func p_sosai_no_ne(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.4)
	for k in 3:
		after(k * 0.07, func():
			FX.ring(c.global_position + Vector3.UP * 1.2, Color(0.85, 0.8, 1.0), 3.0 + k * 2.5, 0.35, false))
	for p in get_tree().get_nodes_in_group("projectiles"):
		if p.get("shooter") != c and p.global_position.distance_to(c.global_position) < 9.0:
			p.queue_free()
	for e in enemies_near(c, c.global_position, 6.0):
		st(e, "stun", 0.8)
	Sfx.play("genjutsu", c.global_position, 2.0)


## İpli Bıçaklar: tellere bağlı kunailer atılır, havada yön değiştirip hedefe her yandan saplanır
func p_soshujin(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 22.0)
	busy(c, 0.5)
	var from = hand_pos(c, true)
	for k in 5:
		var b = MB.new()
		b.add("cone", Vector3(0, 0, 0.12), Vector3(0.05, 0.2, 0.015), Color(0.6, 0.62, 0.66), Vector3(90, 0, 0), 4)
		b.add("cyl", Vector3(0, 0, -0.06), Vector3(0.025, 0.14, 0.025), Color(0.2, 0.2, 0.22), Vector3(90, 0, 0), 6)
		var side = c.face_dir().cross(Vector3.UP) * ((k - 2) * 0.6)
		var pr = shot(c, from, (aim_at(c, tt, from) + side + Vector3.UP * 0.2).normalized(), 26.0, mesh_of(b), inf(c, "soshujin", 0.25, {"knock": 1.0, "kind": "light", "bleed": 2.0}), tt, false, 1.6)
		pr.homing_turn = 5.0
		var wire = StandardMaterial3D.new()
		wire.albedo_color = Color(0.85, 0.85, 0.9)
		tether(func(): return hand_pos(c, true) if live(c) else Vector3.ZERO, func(): return pr.global_position if is_instance_valid(pr) else hand_pos(c, true), 0.01, wire, 0.9)
	Sfx.play("kunai", from, 1.4)


## Sarhoş Yumruk: sendeleyerek öngörülemez açılardan beş vuruş
func p_suiken(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	var d = _face(c, tt)
	busy(c, 1.2)
	for k in 5:
		after(k * 0.2, func():
			if not live(c):
				return
			var wob = d.rotated(Vector3.UP, randf_range(-0.8, 0.8))
			if c is CharacterBody3D:
				c.velocity = wob * 6.0 + Vector3.UP * (2.0 if k == 3 else 0.0)
			anim(c, ["jab", "hook", "cross", "slide", "hook"][k], 1.7)
			var at = c.global_position + Vector3.UP * (0.5 if k == 3 else 1.1) + wob * 1.1
			for e in hit(c, at, 1.6, inf(c, "suiken", 0.45, {"knock": 4.0, "kind": "heavy"})):
				FX.impact(e.global_position + Vector3.UP, Color(1, 0.85, 0.6), 0.8)
			Sfx.play("punch", at, 1.0 + randf() * 0.3))





## Kara Yağmur: ağızdan göğe kara yağ püskürür, geniş alana yağar — ateş değerse alev alır (yavaşlatır)
func p_suiton_kokuu_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	var tt = tg(c, t, 22.0)
	var at = gp(tt.global_position if tt else c.global_position + fwd(c, t) * 10.0)
	VFX.puffs(_mouth_pos(c), {"amount": 30, "life": 0.6, "size": 0.4, "radius": 0.2, "vmin": 10, "vmax": 16, "dir": Vector3.UP, "spread": 20.0, "add": false,
		"colors": [Color(0.12, 0.1, 0.08, 0.9), Color(0.1, 0.1, 0.1, 0)]})
	for k in 40:
		after(0.4 + randf() * 1.0, func():
			var q = at + Vector3(randf_range(-6, 6), 8.0, randf_range(-6, 6))
			var b = MB.new()
			b.add("sphere", Vector3.ZERO, Vector3(0.12, 0.25, 0.12), Color(0.1, 0.08, 0.06))
			var dr = mesh_of(b)
			get_tree().current_scene.add_child(dr)
			dr.global_position = q
			var tw = dr.create_tween()
			tw.tween_property(dr, "global_position", gp(q), 0.5)
			tw.tween_callback(dr.queue_free))
	after(1.0, func():
		_oil_pool(c, at, 6.0, 8.0))
	Sfx.play("water", at, 0.5)








## Şurup Gölü: ağızdan yere yapışkan şurup dökülür — içine basan yapışır
func p_suiton_mizuame_nabara(c: Node3D, t: Node3D) -> void:
	busy(c, 0.7)
	var at = gp(c.global_position + fwd(c, t) * 5.0)
	VFX.puffs(_mouth_pos(c), {"amount": 30, "life": 0.6, "size": 0.4, "radius": 0.2, "vmin": 6, "vmax": 10, "dir": fwd(c, t) - Vector3.UP * 0.5, "spread": 20.0, "add": false,
		"colors": [Color(0.95, 0.75, 0.35, 0.9), Color(0.9, 0.7, 0.3, 0)]})
	_oil_pool(c, at, 4.5, 10.0)
	every(10.0, 0.5, func(_i, _k):
		for e in enemies_near(c, at, 4.5):
			st(e, "bind", 0.6), Callable())
	Sfx.play("water", at, 0.6)





## Su Kırbacı: elde oluşan su kamçısı geniş yay çizer
func p_suiton_suiben(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 9.0)
	var d = _face(c, tt)
	busy(c, 0.6)
	anim(c, "slash_b", 1.4)
	for k in 10:
		after(k * 0.025, func():
			var a = deg_to_rad(-70.0 + k * 15.0)
			var q = c.global_position + Vector3.UP * 1.1 + d.rotated(Vector3.UP, a) * (1.0 + k * 0.5)
			_splash(q, 0.5))
	Combat.hit_zone(c, c.global_position, d, 7.0, 70.0, 2.5, inf(c, "suiton_suiben", 0.9, {"knock": 9.0, "kind": "heavy", "element": "suiton", "bleed": 1.0}))
	Sfx.play("whoosh", c.global_position, 1.2)














## Ay Gölgesi: kılıç ay hilali çizer, ardından solgun ay ışığı izi kalır
func p_tsukikage(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 8.0)
	var d = _jump_at(c, tt, 3.0, 14.0 if tt else 5.0)
	busy(c, 0.6)
	anim(c, "slash_c", 1.6)
	after(0.2, func():
		if not live(c):
			return
		var at = c.global_position + Vector3.UP * 1.3 + d * 0.8
		_arc_cut(at, d, -100.0, 100.0, Color(0.85, 0.9, 1.0), 2.0)
		_arc_cut(at + Vector3.UP * 0.15, d, -90.0, 90.0, Color(0.95, 0.97, 1.0), 1.8)
		hit(c, at + d * 0.8, 2.2, inf(c, "tsukikage", 1.4, {"knock": 9.0, "kind": "heavy", "bleed": 3.0}))
		Sfx.play("clink", at, 0.9))


## Göğü Delen Topuk: havaya sıçrayıp topukla iner, yer patlar
func p_tsutenkyaku(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 8.0)
	var d = _jump_at(c, tt, 10.0, 6.0 if tt else 1.0)
	busy(c, 1.0)
	_kick_pose(c, 0.9)
	after(0.5, func():
		if not live(c):
			return
		if c is CharacterBody3D:
			c.velocity = Vector3.DOWN * 25.0
		after(0.12, func():
			var at = gp(c.global_position + d * 0.6)
			FX.impact(at + Vector3.UP * 0.3, Color(1, 0.9, 0.7), 2.0)
			for r in [3.0, 5.5, 8.0]:
				FX.ring(at + Vector3.UP * 0.05, EARTH, r, 0.5)
			VFX.debris(at, EARTH, 30, 10.0)
			shake(0.9)
			hit(c, at + Vector3.UP, 5.0, inf(c, "tsutenkyaku", 1.9, {"knock": 14.0, "launch": 8.0, "kind": "heavy"}))
			Sfx.play("boom", at, 0.9)))


## İç Ses: genjutsuyu içeriden kırar — üstündeki sersemlik/bağ biter, 6 sn genjutsu bağışıklığı
func p_uchi_naru_sakura(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.3)
	if c.has_method("clear_status"):
		c.clear_status()
	elif c.get("status") is Dictionary:
		for k in ["stun", "bind", "slow"]:
			c.status.erase(k)
	if c is Player:
		Buffs.add("uchi_naru", 6.0, {"_name": "İç Ses", "_desc": "genjutsu kırıldı; kısa süre etkilenmezsin"})
	FX.ring(c.global_position + Vector3.UP * 1.7, Color(1, 0.6, 0.75), 2.0, 0.4, false)
	Combat.popup_text(c.global_position + Vector3.UP * 2.4, "KAI!", Color(1, 0.6, 0.75))
	Sfx.play("seal", c.global_position, 1.4)








## Kurbağa Dili Bağı: uzun yapışkan dil fırlar, hedefi sarar ve sana çeker
func p_zessenbaku(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	busy(c, 0.7)
	if tt == null:
		return
	var tongue = glow(Color(0.95, 0.45, 0.55), 1.0)
	tether(func(): return _mouth_pos(c) if live(c) else Vector3.ZERO, func(): return tt.global_position + Vector3.UP if live(tt) else _mouth_pos(c), 0.12, tongue, 0.8)
	st(tt, "bind", 1.0)
	after(0.25, func():
		if live(tt) and tt.get("velocity") != null:
			var v = c.global_position - tt.global_position
			tt.velocity = v.normalized() * minf(22.0, v.length() * 2.5) + Vector3.UP * 3.0)
	Sfx.play("whoosh", c.global_position, 0.8)


## Kurbağa Dili Kesiği: dil kamçı gibi yatay savrulur, keser
func p_zessenzan(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 8.0)
	var d = _face(c, tt)
	busy(c, 0.5)
	var tongue = glow(Color(0.95, 0.45, 0.55), 1.0)
	var tip := {"a": -1.2}
	tether(func(): return _mouth_pos(c) if live(c) else Vector3.ZERO, func(): return _mouth_pos(c) + d.rotated(Vector3.UP, tip["a"]) * 6.0 if live(c) else Vector3.ZERO, 0.12, tongue, 0.4)
	every(0.4, 1.0 / 30.0, func(_i, k):
		tip["a"] = lerpf(-1.2, 1.2, k), Callable())
	Combat.hit_zone(c, c.global_position, d, 6.5, 70.0, 2.5, inf(c, "zessenzan", 1.0, {"knock": 8.0, "kind": "heavy", "bleed": 2.0}))
	Sfx.play("whoosh", c.global_position, 1.0)


# ================================================================== ORTAK DETAYLI EFEKT KATMANI (VFX kütüphanesi: shader çekirdek + iz + toplanma + çarpma + kalıcı iz)
## Element mermisi: elde/ağızda çakra toplanır, shader'lı element çekirdeği (alev/su/rüzgâr/şimşek) element iziyle uçar,
## çarpınca elemente özel büyük çarpma (şok dalgası, yıldız, patlama/sıçrama/arklar/toz, çatlak, yerde kalan iz)
func eshot(c: Node3D, id: String, el: String, col: Color, tt: Node3D, from: Vector3, size: float, speed: float, mul: float, extra := {}, impact_s := 1.0, delay := 0.16) -> void:
	VFX.gather(from, col, 0.8 + size * 0.4)
	after(delay, func():
		if not live(c):
			return
		var core = VFX.element_core(el, col, size)
		var info = {"knock": 8.0 * impact_s, "kind": "heavy", "element": el, "hitstop": 0.05}
		info.merge(extra, true)
		var pr = shot(c, from, aim_at(c, tt, from), speed, core, inf(c, id, mul, info), null, false, 1.6, func(p, _h):
			impact_fx(el, col, p, impact_s))
		pr.radius = 0.35 + size * 0.4
		_etrail(pr, el, col, size))


func _etrail(pr: Projectile, el: String, col: Color, size: float) -> void:
	VFX.element_trail(pr, el, col, size * 0.9)
	match el:
		"katon":
			Projectile.trail(pr, [Color(1, 0.85, 0.35, 0.9), Color(1, 0.4, 0.05, 0.6), Color(0.25, 0.12, 0.08, 0)], size * 0.8, 30, 0.5, FX.tex_smoke, false)
		"suiton":
			Projectile.trail(pr, [Color(0.97, 0.99, 1, 1), Color(0.55, 0.82, 1, 0.9), Color(0.15, 0.4, 0.95, 0)], size * 0.9, 34, 0.5, FX.tex_smoke, false)
		"fuuton":
			Projectile.trail(pr, [Color(1, 1, 1, 0.6), Color(0.8, 1, 0.92, 0.35), Color(0.7, 0.95, 0.85, 0)], size * 1.0, 24, 0.4, FX.tex_smoke, false)
		"raiton":
			Projectile.trail(pr, [Color(1, 1, 1, 1), col.lightened(0.4), Color(col.r, col.g, col.b, 0)], size * 0.4, 30, 0.3, null, true)


## Elemente özel çarpma (s: ölçek)
func impact_fx(el: String, col: Color, at: Vector3, s := 1.0) -> void:
	var g = Vector3(at.x, Game.ground_height(at.x, at.z), at.z)
	var near_ground = at.y - g.y < 2.5
	VFX.star(at, col.lightened(0.4), 2.2 * s, 0.18)
	VFX.shockwave(at, col, 5.0 * s, 0.4, false, Vector3.UP)
	match el:
		"katon", "bakuton", "yoton":
			VFX.explosion(at, 1.1 * s, col)
			VFX.embers(at, col, int(30 * s), 12.0 * s)
			if near_ground:
				VFX.cracks(g, 3.0 * s, Color(0.08, 0.04, 0.02, 0.9), 6.0)
		"suiton", "hyoton":
			VFX.splash(at, 2.6 * s)
			VFX.smoke_ring(g + Vector3.UP * 0.1, 3.5 * s, Color(0.75, 0.88, 1.0))
		"fuuton":
			VFX.shockwave(at, Color(0.9, 1, 0.95), 7.0 * s, 0.3, true)
			VFX.smoke_ring(g + Vector3.UP * 0.1, 4.0 * s, Color(0.85, 0.8, 0.7))
			VFX.debris(g, Color(0.7, 0.65, 0.55), int(10 * s), 8.0 * s, 0.25)
		"raiton":
			for k in int(8 * s):
				VFX.bolt(at, at + Vector3(randf_range(-3, 3), randf_range(-1, 3), randf_range(-3, 3)) * s, col, 0.12 * s, 0.3, 2)
			if near_ground:
				VFX.cracks(g, 2.0 * s, Color(0.1, 0.12, 0.2, 0.8), 4.0)
		"doton":
			VFX.debris(g, EARTH, int(24 * s), 10.0 * s, 0.6)
			VFX.cracks(g, 3.5 * s)
			VFX.smoke_ring(g + Vector3.UP * 0.1, 4.0 * s, Color(0.55, 0.45, 0.35))
		_:
			FX.impact(at, col, 1.2 * s)
	if near_ground and el in ["katon", "suiton", "doton", "raiton", "yoton", "hyoton"]:
		VFX.linger(at, el, col, 1.3 * s, 3.0)
	shake(0.25 + 0.25 * s)


## Ağır yakın dövüş darbesi: yıldız patlaması, yönlü şok halkası, toz, kıvılcım, hız çizgileri
func melee_fx(c: Node3D, at: Vector3, col: Color, s := 1.0, ground := false) -> void:
	VFX.star(at, col.lightened(0.5), 2.0 * s, 0.15)
	VFX.shockwave(at, col, 3.5 * s, 0.3, false, c.face_dir())
	FX.impact(at, col, 1.0 * s)
	FX.burst(at, {"amount": int(16 * s), "life": 0.35, "tex": FX.tex_spark, "add": true, "size": 0.3 * s, "radius": 0.3, "vmin": 6.0, "vmax": 14.0, "dir": c.face_dir(), "spread": 60.0,
		"colors": [Color(1, 1, 1, 1), col, Color(col.r, col.g, col.b, 0)]})
	if ground:
		var g = gp(at)
		VFX.cracks(g, 3.0 * s)
		VFX.debris(g, EARTH, int(16 * s), 9.0 * s, 0.5)
		VFX.smoke_ring(g + Vector3.UP * 0.1, 3.5 * s, Color(0.6, 0.52, 0.42))
	if s >= 1.3 and c is Player:
		VFX.screen_lines(0.3, 0.8)
	shake(0.2 + 0.3 * s)


## Alev Mermisi: ağızda alev toplanır, katmanlı dönen alev küresi uçar; çarpınca patlama, kor, yerde yanan alev dilleri
func p_katon_endan(c: Node3D, t: Node3D) -> void:
	busy(c, 0.55)
	var tt = tg(c, t, 26.0)
	for k in 3:
		after(k * 0.14, func():
			if live(c):
				eshot(c, "katon_endan", "katon", Color(1.0, 0.5, 0.1), tt, _mouth_pos(c) + c.face_dir() * 0.5, 0.9 - k * 0.15, 30.0, 0.35, {"burn": 2.5}, 1.0 - k * 0.2, 0.1))
	Sfx.play("fire", c.global_position, 1.2)


## Kasırga Avuç: avuçta dönen hava küresi (kırılan kabuk + iç spiral) — çarpınca yatay şok halkası, toz halkası
func p_futon_reppusho(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	anim(c, "push", 1.6)
	eshot(c, "futon_reppusho", "fuuton", Color(0.8, 1.0, 0.92), tg(c, t, 24.0), hand_pos(c, true), 1.3, 30.0, 0.8, {"knock": 18.0, "launch": 4.0}, 1.3)
	FX.speed_lines(c.global_position + Vector3.UP * 1.3, c.face_dir())
	Sfx.play("wind", c.global_position, 1.3)


## Dev Su Mermisi: ağızda su toplanır, akan su dokulu dev küre; çarpınca dev sıçrama, dalga halkası, yerde su birikintisi
func p_suiton_teppodama(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	eshot(c, "suiton_teppodama", "suiton", Color(0.3, 0.6, 1.0), tg(c, t, 26.0), _mouth_pos(c) + c.face_dir() * 0.9, 2.4, 24.0, 1.6, {"knock": 20.0, "launch": 3.0}, 1.8, 0.3)
	VFX.splash(gp(c.global_position + c.face_dir()) , 1.2)
	shake(0.3)
	Sfx.play("water", c.global_position, 0.6)


## Şimşek Küresi: avuçta çatırdayan parlak çekirdek ve titreyen kalın arklar; çarpınca dallanan şimşekler, yanık iz
func p_raikyu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	var from = hand_pos(c, true)
	for k in 5:
		VFX.bolt(from, from + Vector3(randf_range(-0.6, 0.6), randf_range(-0.4, 0.6), randf_range(-0.6, 0.6)), RAI, 0.06, 0.25, 1)
	eshot(c, "raikyu", "raiton", RAI, tg(c, t, 26.0), from, 1.0, 34.0, 0.9, {"stun": 0.6}, 1.2, 0.2)
	Sfx.play("chidori", from, 1.4, 0.6)


## Rüzgâr Kesici: kol yatay savrulur, rüzgâr dokulu ince hilal bıçak (iz bırakır) uçar ve deler; değdiği yerde kesik şok halkası
func p_futon_kazekiri_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.45)
	anim(c, "slash_b", 1.6)
	var tt = tg(c, t, 26.0)
	var from = c.global_position + Vector3.UP * 1.25 + c.face_dir() * 0.7
	VFX.gather(from, WIND, 1.0)
	after(0.12, func():
		if not live(c):
			return
		var blade = Node3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = 1.25; tm.outer_radius = 1.45; tm.rings = 32; tm.ring_segments = 6
		var arc = MeshInstance3D.new()
		arc.mesh = tm
		arc.material_override = VFX.mat_wind(Color(0.85, 1.0, 0.95), 9.0, 7.0, Vector3(1, 0, 0), 0.95)
		arc.scale = Vector3(1.0, 0.12, 0.55)
		arc.position = Vector3(0, 0, -0.7)
		blade.add_child(arc)
		var inner = MeshInstance3D.new()
		inner.mesh = tm
		inner.material_override = VFX.mat_bolt(Color(0.9, 1.0, 0.97), 1.4)
		inner.scale = Vector3(0.95, 0.05, 0.5)
		inner.position = Vector3(0, 0, -0.7)
		blade.add_child(inner)
		var pr = shot(c, from, aim_at(c, tt, from), 42.0, blade, inf(c, "futon_kazekiri_no_jutsu", 0.7, {"knock": 5.0, "kind": "heavy", "element": "fuuton", "bleed": 3.0}), null, true, 0.9, func(p, _h):
			VFX.shockwave(p, WIND, 3.5, 0.25, false, Vector3.UP)
			VFX.star(p, Color(1, 1, 1), 1.6, 0.12))
		pr.radius = 1.0
		VFX.element_trail(pr, "fuuton", WIND, 1.6)
		Projectile.trail(pr, [Color(1, 1, 1, 0.5), Color(0.8, 1, 0.92, 0.25), Color(0.7, 0.95, 0.85, 0)], 1.2, 20, 0.3, FX.tex_smoke, false))
	Sfx.play("wind", from, 1.8, 0.6)


## Kiraz Çiçeği Darbesi: havaya sıçrar, yumruğunda çakra parlar, iner — zemin örümcek ağı gibi çatlar, kayalar fırlar, toz halkası, ekran sarsılır
func p_okasho(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 10.0)
	var d = _jump_at(c, tt, 7.0, 8.0 if tt else 2.0)
	busy(c, 1.0)
	anim(c, "air", 1.0)
	var pink = Color(1, 0.6, 0.75)
	every(0.45, 0.05, func(_i, _k):
		if live(c):
			FX.burst(hand_pos(c, true), {"amount": 3, "life": 0.25, "tex": FX.tex_spark, "add": true, "size": 0.25, "radius": 0.1, "vmin": 0.5, "vmax": 1.5,
				"colors": [Color(1, 1, 1, 1), pink, Color(pink.r, pink.g, pink.b, 0)]}), Callable())
	after(0.45, func():
		if not live(c):
			return
		anim(c, "cross", 1.2)
		if c is CharacterBody3D:
			c.velocity = Vector3.DOWN * 20.0
		after(0.12, func():
			var at = gp(c.global_position + d * 0.6)
			melee_fx(c, at + Vector3.UP * 0.4, pink, 1.8, true)
			VFX.cracks(at, 9.0, Color(0.1, 0.07, 0.05, 0.95), 8.0)
			for r in [4.0, 8.0, 12.0]:
				VFX.shockwave(at + Vector3.UP * 0.1, Color(0.85, 0.75, 0.6), r, 0.5, true)
			for k in 12:
				var q = at + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
				var rk = _rock(randf_range(0.6, 1.3))
				get_tree().current_scene.add_child(rk)
				rk.global_position = gp(q) - Vector3.UP * 0.6
				rk.rotation = Vector3(randf_range(-0.6, 0.6), randf() * TAU, randf_range(-0.6, 0.6))
				var tw = rk.create_tween()
				tw.tween_property(rk, "global_position", gp(q) + Vector3.UP * randf_range(0.3, 1.2), 0.1)
				tw.tween_interval(3.0)
				tw.tween_property(rk, "global_position", gp(q) - Vector3.UP * 1.5, 0.6)
				tw.tween_callback(rk.queue_free)
			VFX.debris(at, EARTH, 50, 13.0, 0.7)
			VFX.smoke_ring(at + Vector3.UP * 0.1, 8.0, Color(0.6, 0.52, 0.42))
			shake(1.2)
			hit(c, at + Vector3.UP, 6.5, inf(c, "okasho", 2.2, {"knock": 18.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.1}))
			Sfx.play("boom", at, 0.8)))


## Akış (su seli / rüzgâr seli): ağızdan büyüyerek uzanan, akan dokulu koni; uçta sıçrama/toz; dur sonra söner
func stream_fx(from: Vector3, d: Vector3, length: float, radius: float, mat: Material, dur: float, end_fx := Callable()) -> void:
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = from
	root.look_at(from + d, Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT)
	var cm = CylinderMesh.new()
	cm.top_radius = 0.25; cm.bottom_radius = radius; cm.height = length; cm.radial_segments = 24; cm.rings = 6
	var mi = MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = mat
	mi.rotation_degrees = Vector3(-90, 0, 0)
	mi.position = Vector3(0, 0, -length * 0.5)
	root.add_child(mi)
	var inner = MeshInstance3D.new()
	var cm2 = CylinderMesh.new()
	cm2.top_radius = 0.15; cm2.bottom_radius = radius * 0.6; cm2.height = length * 0.95; cm2.radial_segments = 16
	inner.mesh = cm2
	inner.material_override = mat
	inner.rotation_degrees = Vector3(-90, 0, 0)
	inner.position = Vector3(0, 0, -length * 0.48)
	root.add_child(inner)
	root.scale = Vector3(1, 1, 0.05)
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_QUAD)
	tw.tween_interval(dur)
	tw.tween_property(root, "scale", Vector3(0.05, 0.05, 1), 0.3)
	tw.tween_callback(root.queue_free)
	if end_fx.is_valid():
		after(0.22, func(): end_fx.call(from + d * length))


func _wmat() -> Material:
	return VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.62, 0.88, 1.0), Vector3(0, 1, 0), 0.9, 0.7, 0.1)


func _windmat(alpha := 0.7) -> Material:
	return VFX.mat_wind(Color(0.82, 1.0, 0.93), 9.0, 6.0, Vector3(0, 1, 0), alpha)


## Su Mermisi: ağızda su toplanır, akan su küresi; çarpınca sıçrama
func p_suiton_suidan_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	eshot(c, "suiton_suidan_no_jutsu", "suiton", WATER, tg(c, t, 24.0), _mouth_pos(c), 0.9, 30.0, 0.8, {}, 1.0)
	Sfx.play("water", c.global_position, 1.2)


## Yayılan Su Mermileri: art arda beş akan su küresi, yelpaze
func p_suiton_suisandan(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	var tt = tg(c, t, 22.0)
	for k in 5:
		after(k * 0.1, func():
			if live(c):
				var side = c.face_dir().cross(Vector3.UP) * ((k - 2) * 0.9)
				eshot(c, "suiton_suisandan", "suiton", WATER, tt, _mouth_pos(c) + side * 0.3, 0.55, 32.0, 0.25, {}, 0.6, 0.06))
	Sfx.play("water", c.global_position, 1.3)


## Su Shurikeni: avuçta su toplanır, akan su dokulu dört kanatlı şuriken döner; çarpınca sıçrama
func p_suiton_mizu_shuriken(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 24.0)
	busy(c, 0.5)
	var from = hand_pos(c, true)
	VFX.gather(from, WATER, 1.0)
	for k in 4:
		after(0.12 + k * 0.08, func():
			if not live(c):
				return
			var star = Node3D.new()
			for j in 4:
				var bl = MeshInstance3D.new()
				var pm = PrismMesh.new()
				pm.size = Vector3(0.22, 0.42, 0.05)
				bl.mesh = pm
				bl.material_override = _wmat()
				bl.rotation = Vector3(PI * 0.5, j * PI * 0.5, 0)
				bl.position = Vector3(cos(j * PI * 0.5), 0, sin(j * PI * 0.5)) * 0.22
				star.add_child(bl)
			var pr = shot(c, from, aim_at(c, tt, from).rotated(Vector3.UP, (k - 1.5) * 0.06), 34.0, star, inf(c, "suiton_mizu_shuriken", 0.3, {"knock": 2.0, "kind": "light", "element": "suiton", "bleed": 1.0}), tt, false, 1.3, func(p, _h):
				VFX.splash(p, 1.2)
				VFX.star(p, Color(0.8, 0.95, 1.0), 1.2))
			pr.spin = Vector3(0, 28, 0)
			_etrail(pr, "suiton", WATER, 0.5))
	Sfx.play("water", from, 1.6)


## Su Dalgası Atışı: ağızdan genişleyen akan su seli (dalga), uçta dev sıçrama
func p_suiton_mizurappa(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	var d = fwd(c, t)
	var from = _mouth_pos(c)
	VFX.gather(from, WATER, 1.2)
	stream_fx(from, (d - Vector3.UP * 0.12).normalized(), 14.0, 2.6, _wmat(), 0.5, func(end):
		VFX.splash(gp(end), 3.0)
		VFX.smoke_ring(gp(end) + Vector3.UP * 0.1, 5.0, Color(0.75, 0.88, 1.0)))
	Combat.hit_zone(c, c.global_position, d, 15.0, 22.0, 3.0, inf(c, "suiton_mizurappa", 0.9, {"knock": 14.0, "kind": "heavy", "element": "suiton", "dir": d}))
	shake(0.4)
	Sfx.play("water", c.global_position, 0.8)


## Vahşi Su Dalgası: uzun süren, kalın akan su akıntısı — önündekileri sürükler; zemine su birikir
func p_water_release_wild_water_wave(c: Node3D, t: Node3D) -> void:
	busy(c, 1.4)
	var d = fwd(c, t)
	var from = _mouth_pos(c)
	VFX.gather(from, WATER, 1.4)
	stream_fx(from, (d - Vector3.UP * 0.1).normalized(), 16.0, 3.0, _wmat(), 1.1, func(end):
		VFX.splash(gp(end), 3.5)
		VFX.linger(gp(end), "suiton", WATER, 2.0, 4.0))
	every(1.2, 0.2, func(_i, _k):
		if live(c):
			Combat.hit_zone(c, c.global_position, d, 15.0, 18.0, 3.0, inf(c, "water_release_wild_water_wave", 0.25, {"knock": 9.0, "kind": "light", "element": "suiton", "dir": d}))
			VFX.splash(gp(c.global_position + d * randf_range(4.0, 14.0)), 1.6), Callable())
	shake(0.5)
	Sfx.play("water", c.global_position, 0.5)


## Köpük Dalgası: ağızdan kabaran köpük seli (su dokulu yarı saydam koni + köpük kabarcıkları) — kayganlaştırır
func p_suiton_homatsu_rappa(c: Node3D, t: Node3D) -> void:
	busy(c, 0.9)
	var d = fwd(c, t)
	var from = _mouth_pos(c)
	var foam = VFX.mat_water(Color(0.6, 0.8, 0.95), Color(0.85, 0.94, 1.0), Color(1, 1, 1), Vector3(0, 1, 0), 0.75, 0.9, 0.2)
	stream_fx(from, (d - Vector3.UP * 0.2).normalized(), 12.0, 2.4, foam, 0.7)
	for k in 10:
		after(k * 0.06, func():
			var q = gp(c.global_position + d * (2.0 + k * 1.2)) + Vector3.UP * 0.5
			VFX.puffs(q, {"amount": 26, "life": 1.8, "size": 0.45, "radius": 1.3, "vmin": 0.5, "vmax": 2.0, "dir": Vector3.UP, "spread": 60.0, "add": false,
				"colors": [Color(1, 1, 1, 0.95), Color(0.85, 0.93, 1.0, 0.7), Color(0.8, 0.9, 1.0, 0)]})
			for e in hit(c, q, 2.0, inf(c, "suiton_homatsu_rappa", 0.15, {"knock": 6.0, "kind": "light", "element": "suiton", "dir": d})):
				st(e, "slow", 3.0))
	Sfx.play("water", c.global_position, 0.8)


## Şelale Çukuru: hedefin altında su halkası belirir, dev su sütunu fışkırır (akan su dokulu silindir), havaya savurur
func p_suiton_takitsubo_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	busy(c, 0.8)
	anim(c, "crouch", 1.4)
	var at = gp(tt.global_position if tt else c.global_position + fwd(c, t) * 8.0)
	VFX.shockwave(at + Vector3.UP * 0.1, WATER, 5.0, 0.4, true)
	VFX.cracks(at, 3.0, Color(0.1, 0.15, 0.25, 0.8), 5.0)
	after(0.25, func():
		var col = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 1.2; cm.bottom_radius = 2.0; cm.height = 9.0; cm.radial_segments = 24
		col.mesh = cm
		col.material_override = _wmat()
		get_tree().current_scene.add_child(col)
		col.global_position = at + Vector3.UP * 4.5
		col.scale = Vector3(1, 0.02, 1)
		var tw = col.create_tween()
		tw.tween_property(col, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK)
		tw.tween_interval(0.6)
		tw.tween_property(col, "scale", Vector3(0.3, 0.02, 0.3), 0.35)
		tw.tween_callback(col.queue_free)
		VFX.splash(at + Vector3.UP * 8.0, 3.0)
		VFX.splash(at, 3.0)
		hit(c, at + Vector3.UP, 3.5, inf(c, "suiton_takitsubo_no_jutsu", 1.2, {"knock": 6.0, "launch": 15.0, "kind": "heavy", "element": "suiton"}))
		VFX.linger(at, "suiton", WATER, 1.8, 4.0)
		shake(0.5))
	Sfx.play("water", at, 0.6)


## Su Bağı: yerden dönen su hortumu yükselir ve hedefi içine hapseder (akan dokulu)
func p_suiton_mizu_shibari(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 16.0)
	busy(c, 0.6)
	if tt == null:
		return
	var at = tt.global_position
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = at
	for k in 2:
		var mi = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 1.0 - k * 0.2; cm.bottom_radius = 1.4 - k * 0.2; cm.height = 2.8; cm.radial_segments = 24
		mi.mesh = cm
		mi.material_override = VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.62, 0.88, 1.0), Vector3(0, 1, 0), 0.6 - k * 0.15, 0.7, 0.1)
		mi.position = Vector3.UP * 1.4
		root.add_child(mi)
		var spin = mi.create_tween().set_loops()
		spin.tween_property(mi, "rotation:y", TAU * (1 if k == 0 else -1), 0.9).from(0.0)
	root.scale = Vector3(1, 0.02, 1)
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(2.7)
	tw.tween_callback(func(): VFX.splash(at + Vector3.UP, 2.6))
	tw.tween_callback(root.queue_free)
	st(tt, "bind", 3.0)
	every(3.0, 0.5, func(_i, _k):
		if live(tt):
			tt.take_hit(inf(c, "suiton_mizu_shibari", 0.12, {"knock": 0.0, "kind": "light", "element": "suiton"})), Callable())
	VFX.splash(at, 2.0)
	Sfx.play("water", at, 0.9)


## Büyük Atılım: ağızdan dev rüzgâr seli (rüzgâr dokulu koni + hız çizgileri), yolda toz halkaları
func p_futon_toppa(c: Node3D, t: Node3D) -> void:
	busy(c, 0.9)
	var d = fwd(c, t)
	var from = _mouth_pos(c)
	VFX.gather(from, WIND, 1.3)
	stream_fx(from, d, 20.0, 3.5, _windmat(0.75), 0.4, func(end):
		VFX.smoke_ring(gp(end) + Vector3.UP * 0.1, 7.0, Color(0.85, 0.8, 0.7)))
	for k in 5:
		after(0.1 + k * 0.06, func():
			var q = gp(c.global_position + d * (3.0 + k * 3.5))
			VFX.shockwave(q + Vector3.UP * 1.2, WIND, 3.0 + k, 0.3, false, d)
			VFX.debris(q, Color(0.75, 0.68, 0.55), 6, 9.0, 0.25))
	Combat.hit_zone(c, c.global_position, d, 20.0, 28.0, 4.0, inf(c, "futon_toppa", 1.0, {"knock": 26.0, "launch": 5.0, "kind": "heavy", "element": "fuuton", "dir": d}))
	FX.speed_lines(c.global_position + Vector3.UP * 1.4, d)
	shake(0.6)
	Sfx.play("wind", c.global_position, 0.6)


## Toz Bulutu: ağızdan toz ve kumla dolu rüzgâr seli, ardından alanı kaplayan yoğun toz bulutu — içindekiler göremez
func p_futon_fujin_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.7)
	var d = fwd(c, t)
	var at = c.global_position + d * 8.0
	var dust = VFX.mat_wind(Color(0.85, 0.75, 0.58), 5.0, 4.0, Vector3(0, 1, 0), 0.8)
	stream_fx(_mouth_pos(c), d, 10.0, 3.0, dust, 0.4)
	for k in 6:
		after(0.2 + k * 0.1, func():
			VFX.puffs(at + Vector3(randf_range(-4, 4), 0.8, randf_range(-4, 4)), {"amount": 40, "life": 4.0, "size": 3.5, "radius": 2.5, "vmin": 0.3, "vmax": 1.2, "dir": Vector3.UP, "spread": 70.0, "add": false,
				"colors": [Color(0.82, 0.73, 0.58, 0.85), Color(0.78, 0.7, 0.56, 0.6), Color(0.75, 0.68, 0.55, 0)]}))
	every(4.0, 0.5, func(_i, _k):
		for e in enemies_near(c, at, 8.0):
			st(e, "slow", 1.0)
			if e.has_method("lose_target"):
				e.lose_target(1.5), Callable())
	Sfx.play("wind", c.global_position, 0.8)


## Orak Gelincik: dev savuruş — rüzgâr dokulu geniş yelpaze dalgası; havada parlak kesikler, yerde kesik izleri
func p_kamaitachi_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.9)
	anim(c, "slash_c", 1.2)
	var d = fwd(c, t)
	VFX.gather(c.global_position + Vector3.UP * 1.3 + d, WIND, 1.3)
	after(0.12, func():
		stream_fx(c.global_position + Vector3.UP * 1.2, d, 22.0, 6.0, _windmat(0.55), 0.35)
		for k in 12:
			after(k * 0.04, func():
				var q = c.global_position + d * (3.0 + k * 1.8) + d.cross(Vector3.UP) * randf_range(-4.0, 4.0)
				var cut = MeshInstance3D.new()
				var bm = BoxMesh.new()
				bm.size = Vector3(3.0, 0.04, 0.08)
				cut.mesh = bm
				cut.material_override = VFX.mat_bolt(Color(0.92, 1, 0.97), 1.6)
				get_tree().current_scene.add_child(cut)
				cut.global_position = q + Vector3.UP * randf_range(0.4, 2.6)
				cut.rotation = Vector3(0, atan2(d.x, d.z) + PI * 0.5, randf_range(-0.8, 0.8))
				var tw = cut.create_tween()
				tw.tween_property(cut, "scale", Vector3(1.4, 1, 1), 0.12)
				tw.tween_property(cut, "scale", Vector3(0.01, 1, 1), 0.2)
				tw.tween_callback(cut.queue_free)
				VFX.cracks(gp(q), 1.5, Color(0.15, 0.12, 0.1, 0.8), 5.0))
		Combat.hit_zone(c, c.global_position, d, 24.0, 30.0, 4.0, inf(c, "kamaitachi_no_jutsu", 1.3, {"knock": 18.0, "launch": 4.0, "kind": "heavy", "element": "fuuton", "bleed": 4.0, "dir": d}))
		shake(0.6))
	Sfx.play("wind", c.global_position, 0.5)


## Canavar Yırtan Avuç: dönerek kendi etrafında rüzgâr hortumu (rüzgâr dokulu dönen huni) — içine giren savrulur
func p_juha_sho(c: Node3D, t: Node3D) -> void:
	busy(c, 1.2)
	var at = c.global_position
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = at
	for k in 2:
		var mi = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 3.2 - k * 0.6; cm.bottom_radius = 1.0 - k * 0.2; cm.height = 6.0; cm.radial_segments = 24
		mi.mesh = cm
		mi.material_override = _windmat(0.6 - k * 0.15)
		mi.position = Vector3.UP * 3.0
		root.add_child(mi)
		var spin = mi.create_tween().set_loops()
		spin.tween_property(mi, "rotation:y", TAU * (1 if k == 0 else -1), 0.45).from(0.0)
	root.scale = Vector3(0.2, 0.05, 0.2)
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.25)
	tw.tween_interval(0.9)
	tw.tween_property(root, "scale", Vector3(1.4, 0.05, 1.4), 0.3)
	tw.tween_callback(root.queue_free)
	VFX.smoke_ring(at + Vector3.UP * 0.1, 6.0, Color(0.85, 0.8, 0.7))
	every(1.2, 0.15, func(_i, _k):
		VFX.debris(at, Color(0.75, 0.68, 0.55), 4, 8.0, 0.25)
		hit(c, at + Vector3.UP * 1.2, 3.8, inf(c, "juha_sho", 0.12, {"knock": 9.0, "launch": 6.0, "kind": "light", "element": "fuuton"})), Callable())
	Sfx.play("wind", at, 0.7)


## Çiçek Saçan Dans: rüzgâr dokulu dönen akış içinde binlerce pembe yaprak ve çiçek — her şeyi keser
func p_futon_hanachiri_mai(c: Node3D, t: Node3D) -> void:
	busy(c, 1.0)
	var d = fwd(c, t)
	var petal = VFX.mat_wind(Color(1.0, 0.75, 0.85), 7.0, 5.0, Vector3(0, 1, 0), 0.5)
	stream_fx(c.global_position + Vector3.UP * 1.2, d, 14.0, 3.0, petal, 0.6)
	var petals = [Color(1.0, 0.7, 0.8), Color(1.0, 0.88, 0.92), Color(0.95, 0.55, 0.7)]
	for k in 8:
		after(k * 0.07, func():
			var q = c.global_position + Vector3.UP * 1.2 + d * (2.0 + k * 1.6)
			VFX.puffs(q, {"amount": 45, "life": 1.1, "size": 0.22, "radius": 1.2 + k * 0.3, "vmin": 6, "vmax": 12, "dir": d, "spread": 55.0, "add": false,
				"colors": [petals[k % 3], petals[(k + 1) % 3], Color(1, 0.9, 0.9, 0)]})
			hit(c, q, 2.0 + k * 0.2, inf(c, "futon_hanachiri_mai", 0.18, {"knock": 3.0, "kind": "light", "element": "fuuton", "bleed": 1.0})))
	Sfx.play("wind", c.global_position, 1.1)


## Kesici Hava Dalgası: avuçlardan üç genişleyen, rüzgâr dokulu basınç halkası; yolda toz kazır
func p_zankuha(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	anim(c, "push", 1.4)
	var tt = tg(c, t, 22.0)
	VFX.gather(hand_pos(c, true), WIND, 1.0)
	for k in 3:
		after(0.15 + k * 0.12, func():
			if not live(c):
				return
			var from = hand_pos(c, k % 2 == 0)
			var dir = aim_at(c, tt, from)
			var rm = MeshInstance3D.new()
			var tm = TorusMesh.new()
			tm.inner_radius = 0.42; tm.outer_radius = 0.62; tm.rings = 32; tm.ring_segments = 8
			rm.mesh = tm
			rm.material_override = _windmat(0.8)
			rm.rotation_degrees = Vector3(90, 0, 0)
			var pr = shot(c, from, dir, 34.0, rm, inf(c, "zankuha", 0.45, {"knock": 14.0, "kind": "heavy", "element": "fuuton"}), null, true, 0.75)
			pr.radius = 1.0
			rm.create_tween().tween_property(rm, "scale", Vector3.ONE * 2.8, 0.75)
			_etrail(pr, "fuuton", WIND, 1.0)
			every(0.75, 0.1, func(_i, _k):
				if is_instance_valid(pr):
					VFX.debris(gp(pr.global_position), Color(0.75, 0.68, 0.55), 3, 5.0, 0.2), Callable())
			Sfx.play("wind", from, 1.3, 0.5))


## Büyük Hava Basıncı Dalgası: iki avuçtan dev basınç akışı — rüzgâr dokulu geniş koni, zemini kazır, ardışık şok halkaları
func p_zankukyokuha(c: Node3D, t: Node3D) -> void:
	busy(c, 1.0)
	anim(c, "push", 1.2)
	var d = fwd(c, t)
	VFX.gather(c.global_position + Vector3.UP * 1.2 + d, WIND, 1.5)
	after(0.15, func():
		stream_fx(c.global_position + Vector3.UP * 1.1 + d * 0.6, d, 22.0, 5.0, _windmat(0.7), 0.45)
		for k in 8:
			after(k * 0.05, func():
				var q = c.global_position + Vector3.UP * 1.0 + d * (3.0 + k * 2.4)
				VFX.shockwave(q, WIND, 3.0 + k * 0.6, 0.3, false, d)
				VFX.debris(gp(q), Color(0.8, 0.72, 0.58), 6, 9.0, 0.3)
				VFX.cracks(gp(q), 1.8, Color(0.15, 0.12, 0.1, 0.7), 5.0))
		Combat.hit_zone(c, c.global_position, d, 22.0, 30.0, 4.0, inf(c, "zankukyokuha", 1.4, {"knock": 22.0, "launch": 5.0, "kind": "heavy", "element": "fuuton", "dir": d}))
		shake(0.7))
	Sfx.play("wind", c.global_position, 0.5)


## Toprak çıkışı: yerden kaya sökülürken çatlak, toz halkası, moloz
func _earth_burst(at: Vector3, s := 1.0) -> void:
	VFX.cracks(at, 2.2 * s)
	VFX.debris(at, EARTH, int(12 * s), 7.0 * s, 0.45)
	VFX.smoke_ring(at + Vector3.UP * 0.1, 2.5 * s, Color(0.6, 0.5, 0.4))


## Toprak Tuğla: avuç yere vurulur, zemin çatlar; büyük tuğla blokları sökülüp sırayla fırlar, çarpınca parçalanır
func p_doton_renga_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	anim(c, "crouch", 1.5)
	var tt = tg(c, t, 24.0)
	_earth_burst(gp(c.global_position + c.face_dir()), 1.4)
	for k in 4:
		after(0.18 + k * 0.12, func():
			if not live(c):
				return
			var from = c.global_position + c.face_dir() * 1.0 + c.face_dir().cross(Vector3.UP) * (k - 1.5) * 0.7 + Vector3.UP * 0.8
			_earth_burst(gp(from), 0.7)
			var b = MB.new()
			b.add("box", Vector3.ZERO, Vector3(0.8, 0.45, 0.55), Color(0.72, 0.38, 0.28))
			b.add("box", Vector3(0, 0.23, 0), Vector3(0.82, 0.03, 0.57), Color(0.85, 0.8, 0.7))
			b.add("box", Vector3(0.2, 0.0, 0.28), Vector3(0.02, 0.45, 0.02), Color(0.85, 0.8, 0.7))
			var pr = shot(c, from, aim_at(c, tt, from), 26.0, mesh_of(b), inf(c, "doton_renga_no_jutsu", 0.4, {"knock": 6.0, "kind": "heavy", "element": "doton"}), null, false, 1.4, func(p, _h):
				impact_fx("doton", EARTH, p, 0.7))
			pr.spin = Vector3(6, 0, 3)
			Projectile.trail(pr, [Color(0.7, 0.6, 0.5, 0.6), Color(0.6, 0.5, 0.4, 0)], 0.4, 16, 0.4, FX.tex_smoke, false)
			shake(0.2))
	Sfx.play("earth", c.global_position, 1.4)


## Toprak Çakıl: avuçtan toz bulutuyla birlikte yüzlerce çakıl saçması
func p_doton_sazareishi(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	anim(c, "push", 1.6)
	var tt = tg(c, t, 18.0)
	var from = hand_pos(c, true)
	var dir = aim_at(c, tt, from)
	VFX.gather(from, EARTH, 0.9)
	after(0.12, func():
		for k in 18:
			var d = dir.rotated(Vector3.UP, randf_range(-0.3, 0.3)) + Vector3.UP * randf_range(-0.06, 0.08)
			var pr = shot(c, from, d.normalized(), randf_range(30.0, 42.0), _rock(randf_range(0.08, 0.16)), inf(c, "doton_sazareishi", 0.07, {"knock": 1.0, "kind": "light", "element": "doton"}), null, false, 0.7)
			if k % 4 == 0:
				Projectile.trail(pr, [Color(0.75, 0.65, 0.5, 0.5), Color(0.7, 0.6, 0.5, 0)], 0.25, 10, 0.3, FX.tex_smoke, false)
		VFX.puffs(from + dir, {"amount": 30, "life": 0.6, "size": 0.9, "radius": 0.4, "vmin": 8, "vmax": 14, "dir": dir, "spread": 20.0, "add": false,
			"colors": [Color(0.75, 0.65, 0.5, 0.7), Color(0.7, 0.6, 0.5, 0)]})
		VFX.debris(from, EARTH, 10, 8.0, 0.2))
	Sfx.play("earth", from, 1.8, 0.6)


## Çift İntihar Başkesme: yere dalar (toz halkası), hedefin altından çatlakla çıkar, onu boynuna kadar toprağa çeker
func p_doton_shinju_zanshu_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 16.0)
	if tt == null:
		return
	busy(c, 1.0)
	_earth_burst(c.global_position, 1.2)
	c.visible = false
	after(0.45, func():
		if not live(c):
			return
		c.visible = true
		if not live(tt):
			return
		var at = tt.global_position
		c.global_position = gp(at + (c.global_position - at).normalized() * 1.2)
		_earth_burst(at, 1.6)
		VFX.shockwave(at + Vector3.UP * 0.1, EARTH, 4.0, 0.4, true)
		st(tt, "bind", 3.0)
		tt.take_hit(inf(c, "doton_shinju_zanshu_no_jutsu", 0.5, {"knock": 0.0, "kind": "heavy", "element": "doton"}))
		var body = tt.get("model") if tt.get("model") else tt
		var y0 = body.position.y
		var tw = body.create_tween()
		tw.tween_property(body, "position:y", y0 - tt.height * 0.75, 0.25)
		tw.tween_interval(2.6)
		tw.tween_property(body, "position:y", y0, 0.3)
		Combat.popup_text(at + Vector3.UP * 1.2, "Toprağa gömüldü!", EARTH.lightened(0.3))
		shake(0.4)
		Sfx.play("earth", at, 1.0))


## Uçan Taşlar: yer çatlayıp büyük kayalar havaya kalkar, etrafında döner; sonra toz izleriyle hedefe yağar
func p_doton_tobi_tsubute(c: Node3D, t: Node3D) -> void:
	busy(c, 0.9)
	anim(c, "cast", 1.3)
	var tt = tg(c, t, 22.0)
	_earth_burst(c.global_position, 1.8)
	var rocks = []
	for k in 8:
		var r = _rock(randf_range(0.5, 0.8))
		get_tree().current_scene.add_child(r)
		var a = TAU * k / 8.0
		var q = c.global_position + Vector3(cos(a), 0, sin(a)) * 2.0
		r.global_position = gp(q) - Vector3.UP * 0.5
		r.create_tween().tween_property(r, "global_position", q + Vector3.UP * 1.8, 0.35).set_trans(Tween.TRANS_BACK)
		VFX.debris(gp(q), EARTH, 5, 5.0, 0.3)
		rocks.append(r)
	shake(0.4)
	Sfx.play("earth", c.global_position, 1.2)
	after(0.6, func():
		for k in rocks.size():
			var r: Node3D = rocks[k]
			if not is_instance_valid(r):
				continue
			var from = r.global_position
			r.queue_free()
			if live(c):
				var pr = shot(c, from, aim_at(c, tt, from), 28.0, _rock(0.6), inf(c, "doton_tobi_tsubute", 0.3, {"knock": 5.0, "kind": "heavy", "element": "doton"}), tt, false, 1.4, func(p, _h):
					impact_fx("doton", EARTH, p, 0.6))
				pr.spin = Vector3(5, 3, 0)
				Projectile.trail(pr, [Color(0.7, 0.6, 0.5, 0.6), Color(0.6, 0.5, 0.4, 0)], 0.45, 14, 0.4, FX.tex_smoke, false))


## Çamur Kayması: önündeki zemin akan çamur seline döner (çamur dokulu akış), içindekileri sürükler ve yavaşlatır
func p_doton_dosekiryu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.9)
	anim(c, "crouch", 1.4)
	var d = fwd(c, t)
	var mud = Color(0.42, 0.32, 0.22)
	var mudmat = VFX.mat_water(Color(0.22, 0.15, 0.1), Color(0.42, 0.32, 0.22), Color(0.6, 0.5, 0.38), Vector3(0, 1, 0), 0.95, 0.5, 0.15)
	stream_fx(gp(c.global_position + d) + Vector3.UP * 0.5, (d - Vector3.UP * 0.03).normalized(), 16.0, 3.0, mudmat, 0.9)
	for k in 10:
		after(k * 0.06, func():
			var q = gp(c.global_position + d * (1.5 + k * 1.6))
			VFX.puffs(q + Vector3.UP * 0.4, {"amount": 14, "life": 0.9, "size": 1.4, "radius": 1.8, "vmin": 3, "vmax": 6, "dir": d + Vector3.UP * 0.6, "spread": 30.0, "add": false,
				"colors": [mud, mud.darkened(0.3), Color(0.35, 0.28, 0.2, 0)]})
			VFX.cracks(q, 1.6, Color(0.2, 0.15, 0.1, 0.8), 6.0)
			for e in hit(c, q + Vector3.UP * 0.5, 2.2, inf(c, "doton_dosekiryu", 0.15, {"knock": 7.0, "kind": "light", "element": "doton", "dir": d})):
				st(e, "slow", 3.0))
	shake(0.4)
	Sfx.play("earth", c.global_position, 0.8)


## Toprak Yırtan Avuç: avuç yere basılır, çevre zemin dönerek yarılır — dev çatlak ağı, halka halka şok, havaya kalkan moloz
func p_doton_retsudo_tensho(c: Node3D, t: Node3D) -> void:
	busy(c, 1.0)
	anim(c, "crouch", 1.2)
	var at = gp(c.global_position + c.face_dir() * 1.0)
	VFX.gather(at + Vector3.UP * 0.3, EARTH, 1.4)
	after(0.2, func():
		VFX.cracks(at, 10.0, Color(0.1, 0.07, 0.05, 0.95), 8.0)
		for k in 3:
			after(k * 0.15, func():
				VFX.shockwave(at + Vector3.UP * 0.1, EARTH, 6.0 + k * 4.0, 0.5, true)
				for j in 5:
					VFX.debris(at + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6)), EARTH, 10, 10.0, 0.6))
		VFX.smoke_ring(at + Vector3.UP * 0.1, 9.0, Color(0.6, 0.5, 0.4))
		shake(1.0)
		for e in hit(c, at + Vector3.UP * 0.5, 7.0, inf(c, "doton_retsudo_tensho", 0.6, {"knock": 3.0, "launch": 4.0, "kind": "heavy", "element": "doton"})):
			st(e, "stun", 1.4))
	Sfx.play("earth", at, 0.7)


## Kaya Sığınağı: zemin çatlar, büyük kaya plakaları dönerek yükselir ve kubbe olur; içindekiler korunur
func p_earth_release_rock_shelter(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.7)
	anim(c, "crouch", 1.4)
	var at = gp(c.global_position)
	VFX.cracks(at, 6.0)
	VFX.smoke_ring(at + Vector3.UP * 0.1, 6.0, Color(0.6, 0.5, 0.4))
	var b = MB.new()
	for k in 14:
		var a = TAU * k / 14.0
		b.add("boulder", Vector3(cos(a) * 2.6, 1.0, sin(a) * 2.6), Vector3(1.6, 2.4, 1.4), EARTH.darkened(0.05 * (k % 3)), Vector3(0, -rad_to_deg(a), 12), 3)
	for k in 6:
		var a = TAU * k / 6.0
		b.add("boulder", Vector3(cos(a) * 1.3, 2.6, sin(a) * 1.3), Vector3(1.8, 1.0, 1.8), EARTH.lightened(0.05), Vector3.ZERO, 3)
	var dome = mesh_of(b)
	get_tree().current_scene.add_child(dome)
	dome.global_position = at - Vector3.UP * 3.2
	dome.rotation.y = -0.6
	var tw = dome.create_tween()
	tw.tween_property(dome, "global_position", at, 0.35).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(dome, "rotation:y", 0.0, 0.35)
	tw.tween_callback(func():
		VFX.shockwave(at + Vector3.UP * 0.1, EARTH, 8.0, 0.4, true)
		VFX.debris(at, EARTH, 30, 9.0, 0.6))
	tw.tween_interval(4.5)
	tw.tween_property(dome, "global_position", at - Vector3.UP * 3.5, 0.5)
	tw.tween_callback(dome.queue_free)
	shake(0.7)
	if c is Player:
		Buffs.add("rock_shelter", 5.0, {"armor": 0.15, "_name": "Kaya Sığınağı", "_desc": "kubbenin içindesin: gelen hasar çok azalır"})
	Sfx.play("earth", at, 0.8)


## Şimşek elde: avuçta kalın arklı şimşek küresi belirir (dur sn)
func _rai_hand(c: Node3D, dur: float) -> void:
	var ba = bone_attach(c, "RightHand")
	if ba == null:
		return
	var orb = VFX.lightning_ball(0.35, RAI)
	ba.add_child(orb)
	after(dur, func():
		if is_instance_valid(ba):
			ba.queue_free())


## Şimşek Darbesi: avuçta şimşek küresi toplanır, atılıp vurur — çarpınca kalın dallar, yıldız, yanık çatlak, felç
func p_raigeki(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	_rai_hand(c, 0.5)
	VFX.gather(hand_pos(c, true), RAI, 1.0)
	busy(c, 0.6)
	after(0.15, func():
		_jump_at(c, tt, 0.0, 14.0 if tt else 3.0))
	after(0.3, func():
		if not live(c):
			return
		anim(c, "cross", 1.6)
		var at = c.global_position + Vector3.UP * 1.1 + c.face_dir() * 1.2
		melee_fx(c, at, RAI, 1.3)
		impact_fx("raiton", RAI, at, 1.0)
		for e in hit(c, at, 1.8, inf(c, "raigeki", 1.3, {"knock": 8.0, "kind": "heavy", "element": "raiton"})):
			st(e, "stun", 0.9)
		Sfx.play("thunder", at, 1.4))


## Şimşek Yatay El Bıçağı: el şimşekle kaplanır, yatay savrulur — parlayan şimşek yayı, yay boyunca arklar
func p_raigyaku_suihei_choppu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	var d = _face(c, tt)
	_rai_hand(c, 0.5)
	busy(c, 0.6)
	after(0.12, func():
		_jump_at(c, tt, 0.0, 10.0 if tt else 3.0))
	after(0.25, func():
		if not live(c):
			return
		anim(c, "slash_b", 1.8)
		var at = c.global_position + Vector3.UP * 1.2
		var arc = MeshInstance3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = 1.6; tm.outer_radius = 1.8; tm.rings = 32; tm.ring_segments = 6
		arc.mesh = tm
		arc.material_override = VFX.mat_bolt(RAI, 2.4)
		arc.scale = Vector3(1, 0.1, 1)
		get_tree().current_scene.add_child(arc)
		arc.global_position = at + d * 0.3
		var tw = arc.create_tween()
		tw.tween_property(arc, "scale", Vector3(1.3, 0.02, 1.3), 0.25)
		tw.tween_callback(arc.queue_free)
		for k in 7:
			var q = at + d.rotated(Vector3.UP, deg_to_rad(-70.0 + k * 23.0)) * 1.8
			VFX.bolt(q, q + Vector3(randf_range(-1, 1), randf_range(-0.6, 0.6), randf_range(-1, 1)), RAI, 0.1, 0.3, 2)
		Combat.hit_zone(c, c.global_position, d, 3.2, 75.0, 2.0, inf(c, "raigyaku_suihei_choppu", 1.3, {"knock": 10.0, "kind": "heavy", "element": "raiton", "stun": 0.5}))
		shake(0.4)
		Sfx.play("thunder", c.global_position, 1.7, 0.6))


## Şimşek Yılan Balığı: elden kalın, kıvrılan şimşek akımı uzanır; hedefi sarar ve sürekli çarpar (kıvılcım, felç)
func p_raiton_ikazuchi_unagi(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	busy(c, 0.9)
	anim(c, "push", 1.3)
	_rai_hand(c, 2.0)
	if tt == null:
		return
	st(tt, "bind", 2.0)
	every(2.0, 0.07, func(_i, _k):
		if live(c) and live(tt):
			VFX.bolt(hand_pos(c, true), tt.global_position + Vector3.UP * 1.0, RAI, 0.22, 0.12, 3)
			VFX.bolt(tt.global_position + Vector3(randf_range(-0.6, 0.6), 0.2, randf_range(-0.6, 0.6)), tt.global_position + Vector3(randf_range(-0.6, 0.6), 1.8, randf_range(-0.6, 0.6)), RAI, 0.08, 0.12, 1), Callable())
	every(2.0, 0.4, func(_i, _k):
		if live(tt):
			VFX.star(tt.global_position + Vector3.UP, RAI, 1.4, 0.1)
			tt.take_hit(inf(c, "raiton_ikazuchi_unagi", 0.25, {"knock": 0.0, "kind": "light", "element": "raiton"})), Callable())
	Sfx.play("thunder", tt.global_position, 1.5)


## Şimşek Tazısı: avuçtan şimşek dokulu bir tazı fırlar, yerde koşarak hedefi izler; çarpınca dev şimşek patlaması
func p_raiton_raiju_tsuiga(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 26.0)
	busy(c, 0.6)
	_rai_hand(c, 0.4)
	VFX.gather(hand_pos(c, true), RAI, 1.2)
	after(0.2, func():
		if not live(c):
			return
		var from = gp(c.global_position + c.face_dir() * 1.0) + Vector3.UP * 0.7
		var hound = Node3D.new()
		var m = VFX.mat_bolt(RAI, 2.0)
		for part in [[Vector3(0, 0, 0), Vector3(0.55, 0.45, 1.1)], [Vector3(0, 0.2, 0.62), Vector3(0.38, 0.34, 0.5)], [Vector3(0, 0.15, -0.7), Vector3(0.12, 0.12, 0.6)]]:
			var mi = MeshInstance3D.new()
			mi.mesh = SphereMesh.new()
			mi.material_override = m
			mi.position = part[0]
			mi.scale = part[1]
			hound.add_child(mi)
		var arcs = VFX.lightning_ball(0.6, RAI)
		hound.add_child(arcs)
		var dir = aim_at(c, tt, from)
		dir.y = 0
		var pr = shot(c, from, dir.normalized(), 24.0, hound, inf(c, "raiton_raiju_tsuiga", 1.1, {"knock": 10.0, "kind": "heavy", "element": "raiton", "stun": 0.8}), tt, false, 2.0, func(p, _h):
			impact_fx("raiton", RAI, p, 1.4))
		pr.homing_turn = 4.0
		pr.radius = 0.8
		_etrail(pr, "raiton", RAI, 0.8))
	Sfx.play("chidori", c.global_position, 1.2)
