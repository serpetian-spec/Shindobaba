class_name Eyes
extends Node
## Göz teknikleri (dōjutsu): sağ göz / sol göz ayrı ekipman.
## V: gözleri aç/kapa  •  göz teknikleri jutsu yuvalarına konur (göz açık değilse çalışmaz)
## V basılı (iki göz de Mangekyō/Ebedi): Susanoo  •  Düşmüş göz sahibinin yanında F: gözü al

const KINDS := {1: "Sharingan", 2: "Byakugan", 3: "Ketsuryūgan", 4: "Mangekyō Sharingan", 5: "Ebedi Mangekyō", 6: "Rinnegan", 7: "Tenseigan", 8: "Jōgan"}
## Gözler kapalıyken de görünen gözler (doğuştan desen)
const ALWAYS_VISIBLE := [2, 6, 7]
## [ad, chakra, bekleme] — sağ / sol göz
const SKILLS := {
	1: [["Genjutsu: Sharingan", 15.0, 12.0], ["Genjutsu: Sharingan", 15.0, 12.0]],
	2: [["Hakke Kūshō", 14.0, 6.0], ["Hakkeshō Kaiten", 22.0, 10.0]],
	3: [["Ketsuryūgan Genjutsu", 18.0, 12.0], ["Ketsuryūgan: Chi Sōsa", 20.0, 14.0]],
	4: [["Amaterasu", 40.0, 20.0], ["Tsukuyomi", 45.0, 24.0]],
	5: [["Amaterasu", 30.0, 14.0], ["Tsukuyomi", 32.0, 16.0]],
	6: [["Shinra Tensei", 35.0, 14.0], ["Banshō Ten'in", 25.0, 10.0]],
	7: [["Gudōdama", 30.0, 10.0], ["Çekim Darbesi", 25.0, 12.0]],
	8: [["Jōgan Nüfuzu", 20.0, 12.0], ["Boyut Görüşü", 10.0, 8.0]],
}

## Mangekyō tarzları: her Mangekyō gözü uyanınca (ya da alınınca) rastgele bir tarza bağlanır. Tarz = 2 göz tekniği (sağ / sol göz
## yuvası) + 6 jutsu; toplam 8. Yalnız sahip olduğun tarzın teknikleri açılır (eskiden her Mangekyō tekniği açılıyordu: aşırı güçlü).
## Ebedi Mangekyō iki farklı tarzın gözlerini birleştirebilir. Yeni tarz eklemek: buraya bir kayıt (oyunda olmayan kendi tarzlarımız da).
## Yalnız animedeki teknikler. "@..." = jutsu değil, gözün YETENEĞİ (yuva harcamaz, göz tuşuyla): Kamui içine çekme /
## ışınlanma, Shisui'nin Shunshin'i. Obito tarzı Mangekyō ayrıca kaçma tuşunu Kamui geçirgenliğine çevirir (basılı tut).
const MS_STYLES := {
	"itachi": {"name": "Itachi tarzı", "theme": "Kara alev, ay rüyası ve Susanoo'nun kutsal hazineleri", "eyes": ["amaterasu", "tsukuyomi"],
		"jutsu": ["izanami", "yasaka_no_magatama", "tensha_fuin_amaterasu", "totsuka_no_tsurugi", "yata_no_kagami", "magen_karasu_bunshin"]},
	"sasuke": {"name": "Sasuke tarzı", "theme": "Enton: biçimlenen kara alev", "eyes": ["enton_kagutsuchi", "amaterasu_entenka"],
		"jutsu": ["susanoo_kagutsuchi_no_yumiya", "enton_kagutsuchi_no_tsurugi", "susanoo_chidori", "indora_no_ya", "amaterasu", "susanoo"]},
	"obito": {"name": "Obito tarzı", "theme": "Kamui: içinden geçen, içine çeken, ışınlanan göz", "eyes": ["@kamui_kyuin", "@kamui_tobi"],
		"jutsu": ["kamui", "kamuibashiri"]},
	"kakashi": {"name": "Kakashi tarzı", "theme": "Uzak menzil Kamui ve şimşek", "eyes": ["kamui", "kamui_shuriken"],
		"jutsu": ["kamui_raikiri", "raiden", "kamuibashiri", "susanoo"]},
	"madara": {"name": "Madara tarzı", "theme": "Susanoo ve kara alev", "eyes": ["susanoo_hozan", "susanoo_tsukumo"],
		"jutsu": ["susanoo", "susanoo_gokakyu", "enton_yasaka_no_magatama", "kyoso_enbu"]},
	"shisui": {"name": "Shisui tarzı", "theme": "Kotoamatsukami ve göz açıp kapayan hız", "eyes": ["kotoamatsukami", "@shisui_shunshin"],
		"jutsu": ["susanoo"]},
}
const ABILITY_NAMES := {"@kamui_kyuin": "Kamui: içine çek", "@kamui_tobi": "Kamui: ışınlan", "@shisui_shunshin": "Shisui'nin Shunshin'i"}


## Göz eşyasının Mangekyō tarzı (yoksa uid'den sabit rastgele atanır ve kaydedilir)
static func ms_style_of(g: Dictionary) -> String:
	if g.is_empty() or not String(g.get("id", "")) in ["goz_mangekyo", "goz_ems"]:
		return ""
	if not MS_STYLES.has(String(g.get("ms_style", ""))):
		var keys = MS_STYLES.keys()
		g["ms_style"] = keys[absi(hash(int(g.get("uid", 0)) * 7919 + 13)) % keys.size()]
	return String(g["ms_style"])


## Takılı gözlerin tarzları (EMS iki tarz birleştirebilir)
## Normal Mangekyō: tek tarz (iki göz aynı tarzı paylaşır, sağ göz belirler). Ebedi Mangekyō (nakil): iki gözün tarzı birleşir.
static func ms_styles(pr: Dictionary) -> Array:
	var out = []
	var ems = false
	for slot in ["sag_goz", "sol_goz"]:
		var g = Gear.equipped(pr, slot)
		if String(g.get("id", "")) == "goz_ems":
			ems = true
		var s = ms_style_of(g)
		if s != "" and not s in out:
			out.append(s)
	return out if ems else out.slice(0, 1)


## Bu jutsu bir Mangekyō tarzına ait mi; aitse sahip olunan tarzlarda mı? (göz yuvası teknikleri jutsu listesinde ayrıca yer almaz)
static func ms_allowed(pr: Dictionary, jid: String) -> bool:
	var owner = ""
	for st in MS_STYLES:
		if jid in MS_STYLES[st]["eyes"]:
			return false   # göz yuvasında (V + sağ/sol göz): jutsu listesinde ikinci kopyası olmasın
		if jid in MS_STYLES[st]["jutsu"]:
			owner = st
	return owner == "" or owner in ms_styles(pr)


static func ms_tracked(jid: String) -> bool:
	for st in MS_STYLES:
		if jid in MS_STYLES[st]["eyes"] or jid in MS_STYLES[st]["jutsu"]:
			return true
	return false


var p: Player
var c: PlayerCombat
var active = false
var cd := {"sag": 0.0, "sol": 0.0}
var strain = 0.0          # Mangekyō yorgunluğu (görüş bulanır)
var susanoo = false
var susanoo_node: Susanoo
var sus_swipe_ready := 0     # Susanoo düz savuruş bekleme sonu (ms)
var sus_special_ready := 0
var v_held = -1.0
var markers := {}
var marker_t = 0.0
var steal_target: Node3D = null
var predict_t := 0.0      # Sharingan Öngörü süresi


func setup(combat: PlayerCombat) -> void:
	c = combat
	p = combat.p
	var j = get_node_or_null("/root/Jutsu")
	if j and j.has_signal("jutsu_cast"):
		j.jutsu_cast.connect(_on_jutsu_cast)
	refresh_visual()


func eye(side: String):
	return Game.profile.get("look", {}).get("eye_r" if side == "sag" else "eye_l")


func has_eyes() -> bool:
	return eye("sag") != null or eye("sol") != null


func _kind(side: String) -> int:
	var e = eye(side)
	return int(e["kind"]) if e != null else 0


func _lvl(side: String) -> int:
	var g = Gear.equipped(Game.profile, "sag_goz" if side == "sag" else "sol_goz")
	if not g.is_empty():
		return int(g.get("lvl", 3))
	var e = eye(side)
	return int(e.get("lvl", 3)) if e != null else 0


func _transplant_mult() -> float:
	# nakil göz (soydan değil) çok daha fazla chakra yer
	var m = 1.0
	for s in ["sag", "sol"]:
		var e = eye(s)
		if e != null and e.get("origin", "dogustan") == "nakil":
			m += 0.75
	return m


## Mangekyō deseni: her göz için benzersiz (oyuncu düzenleyebilir)
## style 0 çark, 1 yıldız, 2 taç yaprak, 3 shuriken, 4 sarmal, 5 haç, 6 tomoe halkası, 7..17 (bkz. Menus.MS_STYLES)
static func random_design() -> Dictionary:
	return {"style": randi() % 50, "blades": randi_range(3, 6), "curve": randf_range(-2.5, 2.5), "thick": randf_range(0.35, 0.75),
		"inner": randf_range(0.14, 0.3), "ring": randf() < 0.4, "invert": randf() < 0.12, "spin": randf_range(0.2, 1.0),
		"col": [0.9, 0.05, 0.06]}


static func design_vecs(d: Dictionary) -> Array:
	var c: Array = d.get("col", [0.9, 0.05, 0.06])
	return [Vector4(d.get("style", 0), d.get("blades", 3), d.get("curve", 1.5), d.get("thick", 0.5)),
		Vector4(d.get("inner", 0.22), 1.0 if d.get("ring", false) else 0.0, 1.0 if d.get("invert", false) else 0.0, d.get("spin", 0.6)),
		Color(c[0], c[1], c[2])]


## Takılı Mangekyō/EMS gözünün desen sözlüğü (yoksa üretip kaydeder)
static func design_for(pr: Dictionary, slot: String) -> Dictionary:
	var g = Gear.equipped(pr, slot)
	if g.is_empty():
		return {}
	var kind = int(Gear.item(g["id"]).get("eye", {}).get("kind", 0))
	if not kind in [4, 5]:
		return {}
	if not g.has("design"):
		g["design"] = random_design()
		if kind == 5:  # ebedi: iki deseni birleştiren daha karmaşık stil
			g["design"]["ring"] = true
			g["design"]["blades"] = int(g["design"]["blades"]) + 1
	return g["design"]


## Göz dokusunu güncelle (model yeniden kurulunca da çağrılır)
func refresh_visual() -> void:
	if p == null or p.model == null:
		return
	var r = _kind("sag"); var l = _kind("sol")
	var vr = r if (active or r in ALWAYS_VISIBLE) else 0
	var vl = l if (active or l in ALWAYS_VISIBLE) else 0
	p.model.set_dojutsu_eyes(vr, _lvl("sag"), vl, _lvl("sol"), active and (r == 2 or l == 2))
	p.model.set_ms_designs(design_for(Game.profile, "sag_goz"), design_for(Game.profile, "sol_goz"))
	_third_eye(false)   # alında üçüncü göz (Rinne Sharingan / Ōtsutsuki) oyundan kaldırıldı


## Rinne-Sharingan: alında dikey kızıl göz, eşmerkezli halkalar ve dokuz tomoe
var _third: Node3D = null
func _third_eye(on: bool) -> void:
	if is_instance_valid(_third):
		_third.queue_free()
	_third = null
	if not on or p.model == null or p.model.skel == null or p.model.skel.find_bone("Head") < 0:
		return
	var ba = BoneAttachment3D.new()
	ba.bone_name = "Head"
	p.model.skel.add_child(ba)
	_third = ba
	var ec: Vector3 = p.model.eye_center_model if p.model.face_mi else p.model._head_center() + Vector3(0, -0.03, 0.09)
	var root = Node3D.new()
	ba.add_child(root)
	root.position = Vector3(0, ec.y - p.model._bp("Head").y + 0.052, ec.z - p.model._bp("Head").z + 0.07)
	root.scale = Vector3.ONE * 1.5
	var red = StandardMaterial3D.new()
	red.albedo_color = Color(0.85, 0.08, 0.1)
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var dark = StandardMaterial3D.new()
	dark.albedo_color = Color(0.05, 0.0, 0.0)
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var white = StandardMaterial3D.new()
	white.albedo_color = Color(0.97, 0.95, 0.93)
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var lid = MeshInstance3D.new()
	lid.mesh = SphereMesh.new()
	lid.material_override = white
	lid.scale = Vector3(0.022, 0.034, 0.008)
	root.add_child(lid)
	var iris = MeshInstance3D.new()
	iris.mesh = SphereMesh.new()
	iris.material_override = red
	iris.scale = Vector3(0.019, 0.019, 0.006)
	iris.position = Vector3(0, 0, 0.003)
	root.add_child(iris)
	for k in 2:
		var ring = MeshInstance3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = 0.0055 + k * 0.0025; tm.outer_radius = 0.0063 + k * 0.0025; tm.rings = 24; tm.ring_segments = 4
		ring.mesh = tm
		ring.material_override = dark
		ring.rotation.x = PI * 0.5
		ring.position = Vector3(0, 0, 0.0055)
		root.add_child(ring)
	for k in 9:
		var a = k * TAU / 3.0 + floor(k / 3.0) * 0.5
		var r = 0.0045 + floor(k / 3.0) * 0.0025
		var tom = MeshInstance3D.new()
		tom.mesh = SphereMesh.new()
		tom.material_override = dark
		tom.scale = Vector3.ONE * 0.0022
		tom.position = Vector3(cos(a) * r, sin(a) * r, 0.006)
		root.add_child(tom)
	var pupil = MeshInstance3D.new()
	pupil.mesh = SphereMesh.new()
	pupil.material_override = dark
	pupil.scale = Vector3.ONE * 0.003
	pupil.position = Vector3(0, 0, 0.006)
	root.add_child(pupil)


# ------------------------------------------------------------------ girdi (PlayerModes'tan)
func handle_input(e: InputEvent) -> bool:
	if e.is_action_pressed("dojutsu"):
		v_held = 0.0
		return true
	if e.is_action_released("dojutsu") and v_held >= 0.0:
		var held = v_held
		v_held = -1.0
		if held < 0.45:
			toggle()
		return true
	if susanoo and is_instance_valid(susanoo_node):
		# Susanoo vuruşları ağır ve yavaş: her savuruş arası bekleme + chakra (eskiden tıkladıkça seri vuruyordu: her şeyi kesiyordu)
		var now = Time.get_ticks_msec()
		var tr = susanoo_node.tier
		if e.is_action_pressed("attack"):
			if now < sus_swipe_ready:
				return true
			var cost = 6.0 + tr * 3.0
			if p.chakra < cost:
				Hud.msg("Susanoo savuruşu için chakra yetmiyor.", Color(0.6, 0.7, 1))
				return true
			p.chakra -= cost
			sus_swipe_ready = now + int((1.6 + tr * 0.45) * 1000.0)
			susanoo_node.swipe(p, p.cam_forward() if p.wish_dir().length() < 0.1 else p.wish_dir().normalized())
			return true
		if e.is_action_pressed("guard"):
			if now < sus_special_ready:
				Hud.msg("Susanoo silahı hazır değil (%.0f sn)" % ((sus_special_ready - now) / 1000.0), Color(0.9, 0.8, 0.6))
				return true
			var cost2 = 14.0 + tr * 5.0
			if p.chakra < cost2:
				Hud.msg("Susanoo silahı için chakra yetmiyor.", Color(0.6, 0.7, 1))
				return true
			p.chakra -= cost2
			sus_special_ready = now + int((6.0 + tr * 1.5) * 1000.0)
			sus_swipe_ready = maxi(sus_swipe_ready, now + 900)
			susanoo_node.special(p, p.cam_forward())
			return true
	# Kamui geçirgenliği (Obito tarzı Mangekyō, gözler açıkken): kaçma tuşunu basılı tut — saldırılar içinden geçer
	if e.is_action_pressed("substitute") and active and has_style("obito") and blind() < 1.0 and phase_cd <= 0.0:
		_phase_start()
		return true
	if e.is_action_released("substitute") and phasing:
		_phase_end()
		return true
	if phasing and (e.is_action_pressed("attack") or e.is_action_pressed("throw") or (e is InputEventKey and e.pressed and e.keycode >= KEY_1 and e.keycode <= KEY_9)):
		Hud.msg("Kamui'deyken saldıramazsın — bırak, katılaş.", Color(0.75, 0.6, 0.9), 1.2)
		return true
	if e.is_action_pressed("interact") and steal_target != null:
		_steal(steal_target)
		return true
	return false


func toggle() -> void:
	if not has_eyes():
		Hud.msg("Bir göz tekniğin yok. (Gözler: Tab > Gözler)", Color(0.8, 0.8, 0.8))
		return
	if susanoo:
		_end_susanoo()
	active = not active
	if active:
		var pm = p.combat.modes if p.combat else null
		if pm and pm.has_method("exclusive"):
			pm.exclusive("eyes")
		Progress.clan_unlocks(true)   # nakil/uyanış sonrası göz teknikleri hemen açılsın
		var r = _kind("sag"); var l = _kind("sol")
		var main_kind = maxi(r, l)
		var shar = r in [1, 4, 5] or l in [1, 4, 5]
		if shar:
			Sfx.play("sharingan", null)
		elif r == 2 or l == 2:
			Sfx.play("byakugan", null)
		else:
			Sfx.play("genjutsu", p.global_position, 1.5, 0.6)
		var names = []
		for k in [r, l]:
			if k > 0 and not KINDS[k] in names:
				names.append(KINDS[k])
		var sk = []
		for sd in ["sag", "sol"]:
			var sn = _skill_name(sd)
			if sn != "" and not sn in sk:
				sk.append(sn)
		Hud.msg("%s AÇILDI%s%s" % [" / ".join(names).to_upper(), ("  —  teknikler (jutsu yuvası): " + ", ".join(sk)) if not sk.is_empty() else "", "   (V basılı: Susanoo)" if _can_susanoo() else ""], Color(1, 0.45, 0.45) if main_kind != 2 else Color(0.85, 0.9, 1))
		if shar or r in [3, 6] or l in [3, 6]:   # Ketsuryūgan da göze dalan açılışla (yoksa fark edilmiyordu)
			_eye_closeup(r if r in [1, 3, 4, 5, 6] else l)
		FX.ring(p.global_position + Vector3.UP * 1.5, Color(1, 0.2, 0.2) if main_kind != 2 else Color(0.8, 0.85, 1), 2.5, 0.35, false, -p.face_dir())
		if Game.world:
			Game.world.env.set_tint(Color(0.9, 0.1, 0.1, 0.07) if main_kind != 2 else Color(0.6, 0.7, 1.0, 0.08))
		if r in [1, 4, 5] or l in [1, 4, 5]:
			var tl = maxi(_lvl("sag"), _lvl("sol"))
			Combat.base_time_scale = 0.94 - 0.02 * tl   # daha hafif yavaşlatma
			Combat.self_slow = true   # dünya yavaşlar, sen normal hızdasın
		_eye_buff()
	else:
		_close()
	refresh_visual()


## Sharingan açılışı: Ninja Storm tarzı göze dalan kamera (yaklaşır, göz parlar, geri döner)
func _eye_closeup(kind: int) -> void:
	if p.model == null or p.model.skel == null or p.cam == null or Game.world == null:
		return
	var sk: Skeleton3D = p.model.skel
	var hb = sk.find_bone("Head")
	if hb < 0:
		return
	var f: Vector3 = p.face_dir()
	f.y = 0.0
	f = f.normalized()
	var right = f.cross(Vector3.UP).normalized()
	var a = float(p.model.age_scale)
	var head: Vector3 = (sk.global_transform * sk.get_bone_global_pose(hb)).origin
	var eye_p = head + Vector3.UP * 0.075 * a + f * 0.085 * a
	var cam = Camera3D.new()
	cam.fov = 40.0
	cam.near = 0.01
	Game.world.add_child(cam)
	cam.global_position = eye_p + f * 1.6 * a + Vector3.UP * 0.04
	cam.look_at(eye_p)
	cam.current = true
	p.input_locked = maxf(p.input_locked, 1.15)
	var col = Color(1, 0.12, 0.1) if kind != 6 else Color(0.7, 0.55, 1.0)
	var tw = cam.create_tween()
	tw.tween_property(cam, "global_position", eye_p + f * 0.42 * a + Vector3.UP * 0.01, 0.7).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(cam, "fov", 30.0, 0.7).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		FX.ring(eye_p, col, 0.35, 0.25, false, -f)
		if Game.world:
			Game.world.env.shake = maxf(Game.world.env.shake, 0.4))
	tw.tween_interval(0.35)
	tw.tween_callback(func():
		if is_instance_valid(p) and p.cam:
			p.cam.current = true
		cam.queue_free())


## Açık gözün etkisi ekranda buff olarak görünür (kaçınma/zaman yavaşlaması/Jūken ayrı uygulanır, burada yazılır)
func _eye_buff() -> void:
	var r = _kind("sag"); var l = _kind("sol")
	var k = maxi(r, l)
	var names = []
	for x in [r, l]:
		if x > 0 and not KINDS[x] in names:
			names.append(KINDS[x])
	var mods = {"_name": " / ".join(names)}
	var desc = []
	if r in [1, 4, 5] or l in [1, 4, 5]:
		mods["jutsu"] = 1.0 + 0.015 * maxi(_lvl("sag"), _lvl("sol")) + (0.05 if (r >= 4 and r <= 5) or (l >= 4 and l <= 5) else 0.0)
		desc.append("Kaçınma %%%d" % int(dodge_chance() * 100.0))
		desc.append("dünya yavaşlar (hareketleri okursun)")
	if r == 2 or l == 2:
		mods["melee"] = 1.0   # Jūken bonusu melee_bonus() ile uygulanır; açıklamada yazılır
		desc.append("Jūken yakın dövüş +%25, 360° görüş, düşman chakrası görünür")
	if r == 6 or l == 6:
		mods["jutsu"] = float(mods.get("jutsu", 1.0)) * 1.08
		desc.append("Altı Yol teknikleri açık")
	if k in [3, 7, 8]:
		mods["jutsu"] = float(mods.get("jutsu", 1.0)) * 1.04
	if float(mods.get("melee", 0.0)) == 1.0:
		mods.erase("melee")
	mods["_desc"] = ", ".join(desc)
	Buffs.add("eyes", 99999.0, mods)


func _close() -> void:
	Buffs.remove("eyes")
	active = false
	Combat.base_time_scale = 1.0
	Combat.self_slow = false
	if Game.world:
		Game.world.env.set_tint(Color(0, 0, 0, 0))
	for k in markers.keys():
		if is_instance_valid(markers[k]):
			markers[k].queue_free()
	markers.clear()
	if susanoo:
		_end_susanoo()


func _skill_name(side: String) -> String:
	var k = _kind(side)
	var mj = _ms_eye_jutsu(side)
	if mj.begins_with("@"):
		return String(ABILITY_NAMES.get(mj, mj))
	if mj != "":
		return String(Data.jutsu.get(mj, {}).get("name", mj))
	return SKILLS[k][0 if side == "sag" else 1][0] if k > 0 else "—"


## Mangekyō/EMS gözünün yuva tekniği (tarzına göre: sağ göz 1., sol göz 2. teknik)
func _ms_eye_jutsu(side: String) -> String:
	return ms_eye_jutsu_of(Game.profile, side, _kind(side))


## Statik: profil + göz tarafı + göz türü -> tarzın yuva tekniği ("" = varsayılan Amaterasu/Tsukuyomi)
static func ms_eye_jutsu_of(pr: Dictionary, side: String, k: int) -> String:
	if not k in [4, 5]:
		return ""
	var st = ms_style_of(Gear.equipped(pr, side + "_goz"))
	if k == 4:
		var all = ms_styles(pr)
		st = all[0] if not all.is_empty() else st   # normal Mangekyō: iki göz tek tarz
	if st == "":
		return ""
	return String(MS_STYLES[st]["eyes"][0 if side == "sag" else 1])


## Statik: yuvada / menüde görünen göz tekniği adı — basınca çalışan teknikle aynı (eskiden hep "Amaterasu" yazıyordu)
static func eye_skill_label(pr: Dictionary, side: String, k: int) -> String:
	var mj = ms_eye_jutsu_of(pr, side, k)
	if mj.begins_with("@"):
		return String(ABILITY_NAMES.get(mj, mj))
	if mj != "":
		return String(Data.jutsu.get(mj, {}).get("name", mj)).split(" (")[0]
	return String(SKILLS[k][0 if side == "sag" else 1][0]) if SKILLS.has(k) else "—"


# ------------------------------------------------------------------ teknikler
## Yetenek ağacı "Göz Gücü / Göz Efendisi": göz tekniklerinin hasar çarpanı
func _eye_pow() -> float:
	return 1.0 + Stats.skill(Game.profile, "eye_power")


func use_skill(side: String) -> void:
	var k = _kind(side)
	if k == 0:
		Hud.msg("%s gözünde dōjutsu yok." % ("Sağ" if side == "sag" else "Sol"), Color(0.8, 0.8, 0.8))
		return
	if cd[side] > 0.0:
		Hud.msg("%s hazır değil (%.0f sn)" % [_skill_name(side), cd[side]], Color(0.9, 0.8, 0.6))
		return
	if k == 6 and Jutsu.tendo_wait(p) > 0.0:
		Hud.msg("Tendō dolmadı — itme ve çekme peş peşe yapılamaz (%.1f sn)" % Jutsu.tendo_wait(p), Color(0.75, 0.9, 0.8))
		return
	if k == 4 and blind() >= 1.0:
		Hud.msg("Gözlerin kör: Mangekyō teknikleri kullanılamaz. Ebedi Mangekyō gerek.", Color(1, 0.45, 0.45))
		return
	var sk: Array = SKILLS[k][0 if side == "sag" else 1]
	var cost: float = sk[1] * _transplant_mult() * maxf(0.3, 1.0 + Stats.skill(Game.profile, "eye_cost"))
	if p.chakra < cost:
		Hud.msg("Yeterli chakra yok.", Color(0.6, 0.7, 1))
		return
	p.chakra -= cost
	cd[side] = sk[2] * maxf(0.3, 1.0 + Stats.skill(Game.profile, "eye_cd")) * (1.0 + blind() * 1.2)   # bozulan göz: teknikler gecikir
	Combat.popup_text(p.global_position + Vector3.UP * 2.4, _skill_name(side), Color(1, 0.5, 0.5) if k != 2 else Color(0.85, 0.9, 1))
	var t = Combat.nearest_enemy(p, 30.0, p.face_dir(), 0.3)
	if t == null:
		t = Combat.nearest_enemy(p, 30.0)
	var right = side == "sag"
	match k:
		1:
			_genjutsu_gaze(t, 1.5 + 0.5 * _lvl(side), 0.0)
		2:
			if right:
				_air_palm()
			else:
				_kaiten()
		3:
			# Ketsuryūgan (kanon): göz göze/tene dokunarak genjutsu; kanına chakra karışmış (yaralı) hedefin kanını yönetir
			if right:
				_genjutsu_gaze(t, 2.0 + 0.5 * _lvl(side), 0.0)
			else:
				var wounded = t != null and t.has_method("has_status") and (t.has_status("bleed") or (t.has_meta("last_wound") and Time.get_ticks_msec() - int(t.get_meta("last_wound")) < 20000))
				if t == null or not wounded:
					Hud.msg("Kan kontrolü için önce hedefi yaralamalısın (kanına chakra karışmalı).", Color(0.9, 0.3, 0.3))
					cd[side] = 1.0
				else:
					t.apply_status("bind", 3.0)
					t.take_hit({"dmg": 14.0 * _eye_pow(), "knock": 0.0, "launch": 0.0, "kind": "light", "pierce_guard": true, "bleed": 3.0, "attacker": p})
					Combat.popup_text(t.global_position + Vector3.UP * 2.4, "Kanı kontrol ediliyor", Color(0.85, 0.1, 0.12))
					VFX.debris(t.global_position + Vector3.UP, Color(0.6, 0.02, 0.04), 8, 3.0, 0.2)
		4, 5:
			var mj = _ms_eye_jutsu(side)
			if mj.begins_with("@"):
				_eye_ability(mj, t)
			elif mj == "amaterasu" or mj == "":
				_amaterasu(t, k == 5) if right or mj == "amaterasu" else _genjutsu_gaze(t, 4.0, 40.0 if k == 4 else 55.0)
			elif mj == "tsukuyomi":
				_genjutsu_gaze(t, 4.0, 40.0 if k == 4 else 55.0)
			else:
				Jutsu.execute(p, mj, t)   # tarzın göz tekniği (Kamui, Enton, Kotoamatsukami...)
			if k == 4:
				add_blind(0.035)
		6:   # Tendō: jutsu ile aynı çekirdek ve aynı 5 sn dolum
			if right:
				Jutsu.j_shinra_tensei(p, t)
			else:
				Jutsu.bansho_core(p, t, 30.0)
		7:
			if right:
				_truth_orb(t)
			else:
				_push(10.0, -18.0)
		8:
			if right:
				_genjutsu_gaze(t, 2.5, 15.0)
			else:
				_dimension_sight()
	Sfx.play("genjutsu", p.global_position, 0.8, 0.7)


func _enemies_in(r: float) -> Array:
	var out = []
	for f in get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(p, f) and not f.is_dead() and f.global_position.distance_to(p.global_position) < r:
			out.append(f)
	return out


func _genjutsu_gaze(t: Node3D, stun: float, dmg: float) -> void:
	if t and is_instance_valid(t):
		var rs = genjutsu_land(p, t, true)
		if rs <= 0.0:
			return
		stun *= rs
		dmg *= rs
	if t == null:
		Hud.msg("Göz göze gelecek hedef yok.", Color(0.8, 0.8, 0.8))
		return
	var gm = 1.0 + Stats.skill(Game.profile, "gen_power")
	t.apply_status("stun", stun * gm)
	dmg *= gm
	if dmg > 0.0:
		t.take_hit({"dmg": (dmg) * _eye_pow(), "knock": 0.0, "kind": "light", "dir": p.face_dir(), "element": ""})
	FX.ring(t.global_position + Vector3.UP * 1.6, Color(0.9, 0.05, 0.05), 1.6, 0.6, false, (p.global_position - t.global_position).normalized())
	Combat.popup_text(t.global_position + Vector3.UP * 2.2, "Genjutsu!", Color(1, 0.3, 0.3))


func _amaterasu(t: Node3D, eternal: bool) -> void:
	if t == null:
		return
	# ortak Amaterasu sistemi (jutsu ve düşmanla aynı kurallar): anında tutuşur, söndürülemez, yalnız hızla sıyrılınır
	t.take_hit({"dmg": (25.0) * _eye_pow(), "knock": 0.0, "kind": "light", "dir": p.face_dir(), "element": "katon"})
	Amaterasu.focus_flash(p)
	Amaterasu.ignite(p, t, t.global_position, 10.0 if eternal else 8.0, {"dmg": 3.0 * _eye_pow(), "knock": 0.0, "kind": "light", "element": "katon", "attacker": p})


func _air_palm() -> void:
	var dir = p.face_dir()
	for i in 6:
		var pt = p.global_position + Vector3.UP * 1.1 + dir * (1.5 + i * 1.6)
		Combat.hit_sphere(p, pt, 1.3, {"dmg": (18.0 * Stats.melee_mult(Game.profile)) * _eye_pow(), "knock": 14.0, "kind": "heavy", "dir": dir})
	FX.ring(p.global_position + Vector3.UP * 1.1 + dir * 2.0, Color(0.85, 0.9, 1), 2.5, 0.3, false, dir)
	FX.speed_lines(p.global_position + Vector3.UP, dir)
	Sfx.play("wind", p.global_position, 1.3)


func _kaiten() -> void:
	c.invuln = 1.4
	Jutsu.j_kaiten(p, null)   # tek Kaiten: jutsu ile aynı (dönen chakra çizgileri, mermi geri savurma)


func _push(r: float, force: float) -> void:
	for f in _enemies_in(r):
		var d = (f.global_position - p.global_position)
		d.y = 0
		f.take_hit({"dmg": (20.0) * _eye_pow(), "knock": force, "launch": absf(force) * 0.3, "kind": "heavy", "dir": d.normalized() * signf(force), "element": ""})
	FX.ring(p.global_position + Vector3.UP * 0.5, Color(0.75, 0.65, 1.0), r, 0.5)
	Sfx.play("boom", p.global_position, 0.7)


func _truth_orb(t: Node3D) -> void:
	var dir = p.face_dir() if t == null else (t.global_position - p.global_position).normalized()
	var at = p.global_position + Vector3.UP * 1.2 + dir * 3.0
	Combat.hit_sphere(p, at + dir * 4.0, 3.5, {"dmg": (35.0) * _eye_pow(), "knock": 18.0, "kind": "heavy", "dir": dir, "element": ""})
	FX.impact(at + dir * 4.0, Color(0.1, 0.1, 0.12), 1.4)


func _dimension_sight() -> void:
	# yakındaki tüm düşmanları ve etkileşim noktalarını 10 sn işaretle
	for f in _enemies_in(120.0):
		_mark(f, Color(0.95, 0.9, 0.5))
	get_tree().create_timer(10.0).timeout.connect(func():
		if not active:
			return
		for k in markers.keys():
			if is_instance_valid(markers[k]):
				markers[k].queue_free()
		markers.clear())


func _mark(f: Node3D, col: Color) -> void:
	if markers.has(f.get_instance_id()):
		return
	var l = Label3D.new()
	l.text = "◆"
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.002
	l.font_size = 48
	l.modulate = col
	l.outline_size = 8
	f.add_child(l)
	l.position = Vector3(0, f.height * 0.6, 0)
	markers[f.get_instance_id()] = l


# ------------------------------------------------------------------ Susanoo
func _can_susanoo() -> bool:
	return Susanoo.max_tier(Game.profile) > 0


func _start_susanoo() -> void:
	if not _can_susanoo() or susanoo:
		return
	if blind() >= 1.0 and not (_kind("sag") == 5 or _kind("sol") == 5):
		Hud.msg("Gözlerin kör: Susanoo'yu çağıramıyorsun.", Color(1, 0.45, 0.45))
		return
	if not active:
		toggle()
	susanoo = true
	var sn = Susanoo.new()
	sn.name = "Susanoo"
	p.add_child(sn)
	sn.build(Game.profile, -1, p.model)
	susanoo_node = sn
	var armor = [1.0, 0.65, 0.58, 0.5, 0.42, 0.35][sn.tier]   # alınan hasar çarpanı (eskiden %8'e kadar iniyordu: ölümsüzlük)
	Buffs.add("susanoo", 9999.0, {"armor": armor})
	var final_scale = sn.scale
	sn.scale = final_scale * 0.1
	sn.create_tween().tween_property(sn, "scale", final_scale, 0.6).set_trans(Tween.TRANS_BACK)
	Hud.banner("SUSANOO", "Kademe %d — %s   (sol tık: dev savuruş, sağ tık: silah)" % [sn.tier, Susanoo.TIER_NAMES[sn.tier]], Color(sn.mat.get_shader_parameter("col")))
	Sfx.play("roar", p.global_position, 1.6, 0.6)
	var h = Susanoo.TIER_HEIGHT[sn.tier]
	if sn.tier >= 2:
		# kamera Susanoo boyuna göre; kullanıcı Susanoo'nun içinde (göğüs / alın) süzülür
		p.set_meta("susanoo_cam", [p.cam_dist, p.cam_lift])
		p.cam_range = Vector2(maxf(3.0, h * 0.7), maxf(14.0, h * 3.0))
		p.cam_dist = h * 1.5 + 3.0
		p.cam_lift = h * (0.55 if sn.tier >= 3 else 0.3)
		p.cam_giant = sn.tier >= 3
		p.model_lift = h * Susanoo.USER_SEAT[sn.tier] if sn.tier >= 4 else 0.0   # İnsansı: kullanıcı yerde durur (uçmaz)
	# kanatlı tam Susanoo: havadayken Space ile uçuşa geç
	if sn.tier >= 5 and Susanoo.config(Game.profile).get("wings", true) and p.has_method("start_flight"):
		p.set_meta("wing_flight", {"speed": 24.0, "lift": 13.0, "drain": 1.2, "name": "Susanoo kanatları", "land_stop": true})
		Hud.msg("Kanatlar: havadayken Space ile uç", Color(0.8, 0.9, 1.0))


func _end_susanoo() -> void:
	susanoo = false
	p.model_lift = 0.0
	if p.has_meta("susanoo_cam"):
		var sc: Array = p.get_meta("susanoo_cam")
		p.cam_dist = float(sc[0])
		p.cam_lift = float(sc[1])
		p.remove_meta("susanoo_cam")
		p.cam_range = Vector2(2.2, 14.0)
		p.cam_giant = false
	if p.has_meta("wing_flight"):
		p.remove_meta("wing_flight")
	if p.has_method("flight_source") and p.flight_source() == "susanoo":
		p.stop_flight()
	Buffs.remove("susanoo")
	if is_instance_valid(susanoo_node):
		var sn = susanoo_node
		var tw = sn.create_tween()
		tw.tween_property(sn, "scale", sn.scale * 0.05, 0.35)
		tw.tween_callback(sn.queue_free)


# ------------------------------------------------------------------ göz çalma / nakil
## Düşman göz sahibi yapar (Bingo Book hedefleri, kaçak klan ninjaları)
static func give_enemy_eyes(f: Node, kind: int, lvl := 3) -> void:
	f.set_meta("eyes", {"kind": kind, "lvl": lvl})
	f.add_to_group("dojutsu_bearers")   # öldükten sonra "fighters"tan çıkar; göz çalma bu grubu tarar
	if f.get("model") and f.model and f.model.has_method("set_dojutsu_eyes"):
		f.model.set_dojutsu_eyes(kind, lvl, kind, lvl, kind == 2)


func _steal(f: Node3D) -> void:
	var e: Dictionary = f.get_meta("eyes")
	f.set_meta("eyes_taken", true)
	steal_target = null
	Crime.on_eyes_taken(f)   # köy ninjasının gözü: suç
	var id = {1: "goz_sharingan", 2: "goz_byakugan", 3: "goz_ketsuryugan", 4: "goz_mangekyo", 5: "goz_ems", 6: "goz_rinnegan", 7: "goz_tenseigan", 8: "goz_jogan"}.get(int(e["kind"]), "goz_sharingan")
	var n_eyes = 1 if f.has_meta("eye_share") else 2
	for i in n_eyes:
		Gear.grant(Game.profile, id, "", null, null, {"lvl": int(e.get("lvl", 3)), "origin": "nakil"})
	Game.profile["flags"]["goz_hirsizi"] = int(Game.profile["flags"].get("goz_hirsizi", 0)) + 1
	if n_eyes == 1:
		Hud.dialog(String(f.get_meta("eye_share")), "Dur! Diğer göz bana lazım. Yardım ettiğin için bölüşelim: biri senin, biri benim.", [])
	Hud.banner("GÖZ ALINDI" if n_eyes == 1 else "GÖZLER ALINDI", "%s x%d kavanoza kondu — Tab > Gözler > Saklanan Gözler; nakil hastanede" % [KINDS.get(int(e["kind"]), "Göz"), n_eyes], Color(0.9, 0.3, 0.3))
	Sfx.play("seal", p.global_position, 0.7)


# ------------------------------------------------------------------ Sharingan kopyalama
var _copy_warned := {}   # kopyalanamayan teknik uyarısı jutsu başına bir kez
func _on_jutsu_cast(caster: Node, id: String) -> void:
	if caster == p and ms_tracked(id) and not (_kind("sag") == 5 or _kind("sol") == 5):
		add_blind(0.03)   # Mangekyō tarzının jutsuları da gözü yıpratır
	if not active or caster == p or not is_instance_valid(caster):
		return
	# Sharingan yalnız gördüğünü kopyalar: atan kişi önünde olmalı (arkandaki mühürleri okuyamazsın)
	var to_c = (caster.global_position - p.global_position)
	to_c.y = 0
	if to_c.length() > 1.0 and to_c.normalized().dot(p.face_dir()) < 0.15:
		return
	var tl = 0
	for s in ["sag", "sol"]:
		if _kind(s) in [1, 4, 5]:
			tl = maxi(tl, _lvl(s) + (2 if _kind(s) >= 4 else 0))
	if tl == 0 or caster.global_position.distance_to(p.global_position) > 35.0:
		return
	if id in Game.profile.get("learned", []) or not Data.jutsu.has(id):
		return
	# Sharingan yalnızca senin de yapabileceğin teknikleri kopyalar: seviye/rütbe sınırını aşar ama
	# sahip olmadığın element, başka klanın hiden tekniği, kekkei genkai, göz/sennin gerektiren ve yasak/özel teknikler kopyalanamaz
	var why = Progress.can_learn(id)
	if why != "" and not why.begins_with("Güç") and not why.begins_with("Ustalık") and not why.ends_with("rütbesi gerekli"):
		if not _copy_warned.has(id):
			_copy_warned[id] = true
			Hud.msg("Sharingan gördü ama kopyalayamaz: %s (%s)" % [Data.jutsu[id].get("name", id), why], Color(0.75, 0.55, 0.55))
		return
	# mühürler okunur: rakibin elleri izlenir (kanon: Kakashi / Sasuke mühürleri ezberler)
	var seals: Array = Data.jutsu[id].get("seals", [])
	if not seals.is_empty():
		Combat.popup_text(caster.global_position + Vector3.UP * 2.8, " - ".join(seals.slice(0, 6)), Color(1, 0.45, 0.45))
	if randf() < 0.2 * tl:
		Progress.learn(id)
		Hud.msg("SHARINGAN KOPYALADI: %s" % Data.jutsu[id].get("name", id), Color(1, 0.35, 0.35))
		FX.ring(p.global_position + Vector3.UP * 1.6, Color(0.9, 0.1, 0.12), 1.4, 0.4, false)
		Journal.add("Sharingan ile kopyaladım: %s" % Data.jutsu[id].get("name", id), "jutsu")


# ------------------------------------------------------------------ güncelleme
func _process(dt: float) -> void:
	if Game.paused or p == null:
		return
	check_awaken(dt)
	for s in cd:
		cd[s] = maxf(0.0, cd[s] - dt)
	predict_t = maxf(0.0, predict_t - dt)
	_phase_tick(dt)
	_blind_tick(dt)
	_hatred_tick(dt)
	# V basılı tutma: Susanoo
	if v_held >= 0.0:
		v_held += dt
		if v_held > 0.45 and _can_susanoo() and not susanoo:
			_start_susanoo()
			v_held = -1.0
	if susanoo and is_instance_valid(susanoo_node):
		susanoo_node.rotation.y = p.facing
		susanoo_node.follow = p.model
		var cfg = Susanoo.config(Game.profile)
		var before = Susanoo.max_tier(Game.profile)
		if not _enemies_in(25.0).is_empty():   # yalnız dövüşürken gelişir (boşta açık tutmak saymaz)
			cfg["mastery"] = float(cfg.get("mastery", 0.0)) + dt
		if Susanoo.max_tier(Game.profile) > before:
			Hud.banner("SUSANOO USTALIĞI", "Yeni kademe açıldı: %s" % Susanoo.TIER_NAMES[Susanoo.max_tier(Game.profile)], Color(0.8, 0.6, 1.0))
	if active:
		var ems = _kind("sag") == 5 or _kind("sol") == 5
		var drain = 2.0 * _transplant_mult() * (0.6 if ems else 1.0) * maxf(0.3, 1.0 + Stats.skill(Game.profile, "eye_cost"))
		if susanoo and is_instance_valid(susanoo_node):
			# Susanoo azami chakranın yüzdesini yer (sabit miktar yüksek seviyede yenilenmeye yenik düşüp sonsuz açık kalıyordu):
			# kademe 1 ~%1.6/sn (~60 sn), kademe 5 ~%3.2/sn (~30 sn); EMS ve yetenek indirimi en fazla %35 hafifletir
			var pct = 0.012 + 0.004 * susanoo_node.tier
			drain += p.max_chakra * pct * (0.8 if ems else 1.0) * maxf(0.65, 1.0 + Stats.skill(Game.profile, "eye_cost"))
		p.chakra -= drain * dt
		if p.chakra <= 0.0:
			p.chakra = 0.0
			Hud.msg("Chakra bitti, gözlerin kapandı.", Color(0.8, 0.8, 1))
			_close()
			refresh_visual()
		if _kind("sag") == 2 or _kind("sol") == 2:
			marker_t -= dt
			if marker_t <= 0.0:
				marker_t = 0.5
				for f in _enemies_in(90.0):
					_mark(f, Color(0.75, 0.85, 1.0, 0.9))
	# kanon (Kakashi): Uchiha kanı olmayan bedende nakil Sharingan kapanmaz — kapalıyken de chakrayı yavaşça emer
	if not active and String(Game.profile.get("clan", "")) != "uchiha":
		var open_n = 0
		for sd in ["sag", "sol"]:
			var ee = eye(sd)
			if ee != null and String(ee.get("origin", "dogustan")) == "nakil" and _kind(sd) in [1, 4, 5]:
				open_n += 1
		if open_n > 0 and p.chakra > 0.0:
			p.chakra = maxf(0.0, p.chakra - 0.5 * open_n * dt)
	# göz çalma: yakında gözleri alınmamış düşmüş dōjutsu sahibi
	steal_target = null
	for f in get_tree().get_nodes_in_group("dojutsu_bearers"):
		if f != p and f.has_meta("eyes") and not f.has_meta("eyes_taken") and f.is_dead() and f.global_position.distance_to(p.global_position) < 4.5:
			steal_target = f
			if not f.has_meta("eye_prompt"):
				f.set_meta("eye_prompt", true)
				Combat.popup_text(f.global_position + Vector3.UP * 1.5, "[F] Gözleri al", Color(1, 0.4, 0.4))
			break


# ------------------------------------------------------------------ uyanış ve gelişim (gözler eşya değil)
var _awaken_cd = 0.0
## Uyuyan klan gözü: hayatın tehlikedeyken (can < %20) yakında düşman varken uyanır
func check_awaken(dt: float) -> void:
	_awaken_cd -= dt
	var pr = Game.profile
	var dormant = String(pr.get("flags", {}).get("dormant_eye", ""))
	if dormant != "" and _awaken_cd <= 0.0 and p.hp < p.max_hp * 0.2 and not _enemies_in(20.0).is_empty():
		_awaken_cd = 5.0
		if randf() < 0.5:
			pr["flags"].erase("dormant_eye")
			Gear.grant(pr, dormant, "sag_goz", null, null, {"lvl": 1, "origin": "dogustan", "xp": 0.0})
			Gear.grant(pr, dormant, "sol_goz", null, null, {"lvl": 1, "origin": "dogustan", "xp": 0.0})
			Gear.apply_look(pr)
			p.rebuild_model()
			Hud.banner("SHARINGAN UYANDI", "Ölümün eşiğinde gözlerin açıldı", Color(1, 0.2, 0.2))
			Sfx.play("genjutsu", p.global_position, 1.3)
			if not active:
				toggle.call_deferred()
	evolve_tick(dt)
	# tomoe ilerlemesi: gözler açıkken dövüş
	if active and not _enemies_in(25.0).is_empty():
		for slot in ["sag_goz", "sol_goz"]:
			var g = Gear.equipped(pr, slot)
			if g.is_empty() or g["id"] != "goz_sharingan" or int(g.get("lvl", 1)) >= 3:
				continue
			g["xp"] = float(g.get("xp", 0.0)) + dt
			if g["xp"] >= 600.0 * int(g.get("lvl", 1)):   # 2 tomoe: 10 dk dövüş, 3 tomoe: +20 dk
				g["xp"] = 0.0
				g["lvl"] = int(g.get("lvl", 1)) + 1
				Hud.banner("SHARINGAN GELİŞTİ", "%d tomoe" % int(g["lvl"]), Color(1, 0.3, 0.3))
				Gear.apply_look(pr)  # görünüm sözlüğü (eye_r/eye_l lvl) güncellensin, yoksa göz eski tomoe'da kalır
				refresh_visual()


## Mangekyō uyanışı (kanon): 3 tomoe iken ilişkinin yüksek olduğu birini (yakınlık >= 60) KENDİ ELİNLE öldürmek.
## Enemy.die çağırır. İkinci yol: yanında ölen dost (on_ally_died).
func on_close_kill(who: String) -> void:
	if _awaken_mangekyo():
		Hud.msg("%s'i kendi ellerinle öldürdün..." % who, Color(1, 0.6, 0.6), 6.0)


## Mangekyō (kanon, ikinci yol): 3 tomoe iken YANINDA savaşan dost biri (takım arkadaşı, eskort edilen, peşinden gelen) gözünün
## önünde ÖLÜRSE. Yalnız gerçek ölüm sayılır (die çağrısı) — yaralanma/bayılma açmaz. Uzaktaki ölüm sayılmaz (40 m).
func on_ally_died(ally: Node3D) -> void:
	if ally == null or not is_instance_valid(ally) or p == null:
		return
	if ally.global_position.distance_to(p.global_position) > 40.0:
		return
	var nm = String(ally.get("display_name")) if ally.get("display_name") != null else ""
	if nm == "" and ally.get("display") != null:
		nm = String(ally.get("display"))
	if _awaken_mangekyo():
		Hud.msg("%s gözlerinin önünde öldü..." % (nm if nm != "" else "Yoldaşın"), Color(1, 0.6, 0.6), 6.0)


func _awaken_mangekyo() -> bool:
	var pr = Game.profile
	var ok = false
	for slot in ["sag_goz", "sol_goz"]:
		var g = Gear.equipped(pr, slot)
		if not g.is_empty() and g["id"] == "goz_sharingan" and int(g.get("lvl", 1)) >= 3:
			g["id"] = "goz_mangekyo"
			g.erase("design")
			g.erase("ms_style")
			ms_style_of(g)   # rastgele tarz
			ok = true
	if ok:
		var sts = ms_styles(pr)
		if not sts.is_empty():
			var st: Dictionary = MS_STYLES[sts[0]]
			Hud.msg("Mangekyō tarzın: %s — %s" % [st["name"], st["theme"]], Color(1, 0.5, 0.5), 7.0)
		Gear.apply_look(pr)
		p.rebuild_model()
		Hud.banner("MANGEKYŌ SHARINGAN", "Acı, gözlerini sonsuza dek değiştirdi", Color(0.8, 0.05, 0.1))
		Sfx.play("roar", p.global_position, 0.7, 0.5)
		start_hatred()
	return ok


## Hastanede nakil: saklanan bir gözü seçilen yuvaya takar (eski göz kavanoza)
static func transplant(pr: Dictionary, uid: int, slot: String) -> void:
	var g = Gear.find(pr, uid)
	if g.is_empty():
		return
	# Mangekyō sahibine başka bir Mangekyō nakli = Ebedi Mangekyō
	var cur = Gear.equipped(pr, slot)
	if not cur.is_empty() and cur["id"] == "goz_mangekyo" and g["id"] == "goz_mangekyo":
		g["id"] = "goz_ems"
		g["origin"] = "dogustan"
		g.erase("design")
		Hud.banner("EBEDİ MANGEKYŌ", "Gözlerin artık hiç kararmayacak", Color(0.9, 0.2, 0.3))
	pr["equip"][slot] = uid
	Buffs.add("nakil", 120.0, {"speed": 0.85, "melee": 0.85})
	Gear.apply_look(pr)
	if Game.player:
		Game.player.rebuild_model()


## Kaçma şansı (Sharingan öngörüsü): PlayerModes.on_player_hit çağırır
func dodge_chance() -> float:
	if not active:
		return 0.0
	var best = 0.0
	for s in ["sag", "sol"]:
		var k = _kind(s)
		if k in [1, 4, 5]:
			best = maxf(best, 0.035 * _lvl(s) + (0.05 if k >= 4 else 0.0) + Stats.skill(Game.profile, "eye_dodge") * 0.5)
	return best


## Byakugan yakın dövüş (Jūken) bonusu
func melee_bonus() -> float:
	if active and (_kind("sag") == 2 or _kind("sol") == 2):
		return 1.25
	return 1.0


## Öngörü sırasında kaçılan saldırıya anında karşı darbe (en yakın düşmana)
func counter_strike(_info: Dictionary) -> void:
	var t = Combat.nearest_enemy(p, 5.0)
	if t == null:
		return
	if p.combat:
		p.combat.face_to(t)
	p.model.play("cross", 0.05, 2.4, true)
	FX.ring(t.global_position + Vector3.UP, Color(1, 0.2, 0.2), 2.0, 0.25, false)
	t.take_hit({"dmg": 22.0 * Stats.melee_mult(Game.profile) * _eye_pow(), "knock": 10.0, "kind": "heavy", "dir": (t.global_position - p.global_position).normalized(), "element": ""})


# ------------------------------------------------------------------ anime evrim zincirleri
## Byakugan / Ketsuryūgan ustalığı (1-3), Tenseigan (ustalaşmış Byakugan + Sv.40 -> Kuzey'deki Ay Mabedi sınavı, KgPaths "moon"),
## Rinnegan (Ebedi Mangekyō + Senju gücü Sv.45 ya da Sv.60, ölümün eşiğinde), Rinne-Sharingan (Rinnegan + Altı Yol + Sv.60),
## Jōgan (Uzumaki soyunda nadir, sağ göz)
var _night_t := 0.0
var _evo_cd := 0.0


func _both_slots_kind(kind: int) -> bool:
	return _kind("sag") == kind and _kind("sol") == kind


func _replace_eyes(new_id: String, slots: Array, lvl := 1) -> void:
	var pr = Game.profile
	for slot in slots:
		Gear.grant(pr, new_id, slot, null, null, {"lvl": lvl, "origin": "uyanis", "xp": 0.0})
	Gear.apply_look(pr)
	p.rebuild_model()
	Progress.clan_unlocks(true)
	SpecialSlots.refresh(pr)
	refresh_visual()


func evolve_tick(dt: float) -> void:
	var pr = Game.profile
	var lv = int(pr.get("level", 1))
	var fighting = active and not _enemies_in(25.0).is_empty()
	# 1) Byakugan / Ketsuryūgan ustalığı: açıkken dövüştükçe gelişir
	if fighting:
		for slot in ["sag_goz", "sol_goz"]:
			var g = Gear.equipped(pr, slot)
			if g.is_empty() or not g["id"] in ["goz_byakugan", "goz_ketsuryugan"] or int(g.get("lvl", 1)) >= 3:
				continue
			g["xp"] = float(g.get("xp", 0.0)) + dt
			if g["xp"] >= 700.0 * int(g.get("lvl", 1)):   # Byakugan/Ketsuryūgan: 12 dk, +23 dk dövüş
				g["xp"] = 0.0
				g["lvl"] = int(g.get("lvl", 1)) + 1
				var nm = "BYAKUGAN" if g["id"] == "goz_byakugan" else "KETSURYŪGAN"
				Hud.banner(nm + " GELİŞTİ", "Ustalık %d / 3" % int(g["lvl"]), Color(0.85, 0.9, 1.0) if g["id"] == "goz_byakugan" else Color(0.9, 0.2, 0.25))
	# 2) Tenseigan (Ay Mabedi) Ōtsutsuki bölümüne kadar kapalı
	_evo_cd -= dt
	if _evo_cd > 0.0:
		return
	_evo_cd = 2.0
	# 3) Rinnegan: Ebedi Mangekyō + (Senju gücü ve Sv.45) ya da Sv.60; ölümün eşiğinde dövüşürken uyanır
	if _both_slots_kind(5) and p.hp < p.max_hp * 0.2 and not _enemies_in(25.0).is_empty():
		var senju = Progress.has_nature("mokuton") or String(pr.get("clan", "")) == "senju"
		if (senju and lv >= 45) or lv >= 60:
			_replace_eyes("goz_rinnegan", ["sag_goz", "sol_goz"], 3)
			p.hp = p.max_hp * 0.6
			Hud.banner("RINNEGAN", "Indra ile Ashura'nın chakrası birleşti: Altı Yolun gözü uyandı", Color(0.7, 0.55, 0.95))
			Sfx.play("roar", p.global_position, 0.6, 0.5)
			VFX.shockwave(p.global_position + Vector3.UP, Color(0.7, 0.55, 0.95), 16.0, 0.6, false)
	# 4) Rinne-Sharingan (alında üçüncü göz) kaldırıldı
	# 5) Jōgan: Uzumaki soyunda nadir, Sv.20+ her 2 sn'de çok düşük olasılık (yalnız gözsüz sağ yuva)
	if false and String(pr.get("clan", "")) == "uzumaki" and lv >= 20 and not pr.get("flags", {}).get("jogan_rolled_%d" % lv, false):   # Jōgan Ōtsutsuki bölümüne kadar kapalı
		pr["flags"]["jogan_rolled_%d" % lv] = true
		if Gear.equipped(pr, "sag_goz").is_empty() and randf() < 0.12:
			_replace_eyes("goz_jogan", ["sag_goz"], 1)
			Hud.banner("JŌGAN", "Sağ gözün mavi parladı: görünmeyeni görüyorsun", Color(0.4, 0.65, 1.0))


# ------------------------------------------------------------------ Mangekyō körlüğü (kanon: Itachi / Sasuke)
## Kalıcı göz hasarı 0..1 (profilde): her Mangekyō tekniği, Mangekyō tarz jutsusu ve açık Susanoo saniyesi biriktirir.
## Görüş kararır (ekran kenarı), göz teknikleri gecikir; 1.0 = kör: Mangekyō teknikleri + Susanoo kilitlenir.
## Ebedi Mangekyō (yakının gözü) körlüğü tamamen iyileştirir ve bir daha birikmez. Nefretin Laneti birikimi hızlandırır.
func blind() -> float:
	return float(Game.profile.get("ms_blind", 0.0))


func add_blind(amount: float) -> void:
	var pr = Game.profile
	if _kind("sag") == 5 or _kind("sol") == 5:
		return
	if not (_kind("sag") == 4 or _kind("sol") == 4):
		return
	var before = blind()
	var mult = 1.35 if pr.get("flags", {}).get("hatred", false) else 1.0
	var now = minf(1.0, before + amount * mult)
	pr["ms_blind"] = now
	for th in [[0.35, "Gözlerin kanıyor... Mangekyō'yu her kullanışında görüşün biraz daha bulanıklaşıyor."],
			[0.65, "Görüşün kararıyor. Böyle giderse kör olacaksın — Ebedi Mangekyō tek çare."],
			[0.9, "Neredeyse hiçbir şey göremiyorsun. Bir kez daha zorlarsan gözlerin kapanacak."]]:
		if before < th[0] and now >= th[0]:
			Hud.msg(th[1], Color(1, 0.4, 0.4), 6.0)
	if before < 1.0 and now >= 1.0:
		Hud.banner("GÖZLERİN KARARDI", "Mangekyō'nun bedeli: körsün. Ebedi Mangekyō (yakınının gözü) ışığı geri getirir.", Color(0.5, 0.05, 0.08))
		Journal.add("Mangekyō gözlerimi kör etti.", "milestone")
		if susanoo:
			_end_susanoo()


var _blind_vis := -1.0
var _ems_healed := false
func _blind_tick(dt: float) -> void:
	var pr = Game.profile
	# Ebedi Mangekyō: körlük iyileşir
	if (_kind("sag") == 5 or _kind("sol") == 5) and blind() > 0.0:
		pr["ms_blind"] = 0.0
		Hud.banner("EBEDİ MANGEKYŌ", "Karanlık dağıldı: gözlerin bir daha kararmayacak", Color(0.9, 0.2, 0.25))
	if susanoo and is_instance_valid(susanoo_node) and not (_kind("sag") == 5 or _kind("sol") == 5):
		add_blind(dt * 0.0025)   # açık Susanoo da gözü yorar (~6-7 dk sürekli kullanım = körlük)
	# görüş kararması: ekran kenarları (yalnız değişince ayarla)
	var b = blind() if (_kind("sag") == 4 or _kind("sol") == 4) else 0.0
	if absf(b - _blind_vis) > 0.01 and Game.world and Game.world.env.get("post_mat"):
		_blind_vis = b
		Game.world.env.post_mat.set_shader_parameter("vignette", 0.55 + b * 2.5)


# ------------------------------------------------------------------ İzanagi bedeli (yasak Uchiha tekniği)
## İzanagi jutsusunun süresi bitince çağrılır: kullanılan Sharingan gözü sonsuza dek ışığını kaybeder (eşya silinir).
## Önce sol göz (kanon: Danzō / Itachi tek gözü karartır).
func izanagi_cost(tech := "İzanagi") -> void:
	var pr = Game.profile
	var slot = ""
	for s in ["sol_goz", "sag_goz"]:
		var g = Gear.equipped(pr, s)
		if not g.is_empty() and int(Gear.item(g["id"]).get("eye", {}).get("kind", 0)) in [1, 4, 5]:
			slot = s
			break
	if slot == "":
		return
	var g2 = Gear.equipped(pr, slot)
	pr["equip"].erase(slot)
	pr["gear"] = (pr.get("gear", []) as Array).filter(func(x): return int(x["uid"]) != int(g2["uid"]))
	pr["flags"]["izanagi_used"] = int(pr["flags"].get("izanagi_used", 0)) + 1
	Gear.apply_look(pr)
	Hud.banner("%s'NİN BEDELİ" % tech.to_upper(), "%s gözün sonsuza dek ışığını kaybetti" % ("Sol" if slot == "sol_goz" else "Sağ"), Color(0.75, 0.05, 0.08))
	Journal.add("%s kullandım; bir gözüm sonsuza dek karardı." % tech, "milestone")
	Sfx.play("genjutsu", p.global_position, 0.6, 0.9)
	if not has_eyes() and active:
		_close()
	p.rebuild_model()
	refresh_visual()


# ------------------------------------------------------------------ Nefretin Laneti (kanon: Uchiha'nın sevgisi nefrete döner)
## Mangekyō'yu açtıran kayıp karakterde iz bırakır: Uchiha'nın göz/ateş teknikleri güçlenir (+%12) ama Mangekyō körlüğü
## %35 hızlı birikir; ara sıra kaybını hatırlatan iç ses. Bir tapınakta dua etmek (huzur) laneti çözer.
func start_hatred() -> void:
	var pr = Game.profile
	pr["flags"]["hatred"] = true
	_apply_hatred_buff()
	Hud.msg("Kaybın içinde bir nefret uyandırdı. Gözlerin güçlü ama ruhun karanlık... (Bir tapınakta huzur bulabilirsin)", Color(0.85, 0.35, 0.4), 8.0)
	Journal.add("Nefretin Laneti: kaybım gözlerimi uyandırdı ama içimi kararttı.", "milestone")


func _apply_hatred_buff() -> void:
	Buffs.add("hatred", 99999.0, {"jutsu": 1.12, "_name": "Nefretin Laneti", "_desc": "jutsu +%12, Mangekyō körlüğü %35 hızlı; tapınakta dua et"})


static func clear_hatred() -> bool:
	var pr = Game.profile
	if not pr.get("flags", {}).get("hatred", false):
		return false
	pr["flags"].erase("hatred")
	Buffs.remove("hatred")
	Journal.add("Tapınakta dua ettim; nefret yerini huzura bıraktı.", "milestone")
	return true


var _hatred_t := 120.0
const HATRED_LINES := ["Onu kurtaramadın...", "Güç... daha fazla güç olsaydı.", "Bu acıyı unutmayacaksın.", "Nefret seni ayakta tutuyor, ama neye mal oluyor?"]
func _hatred_tick(dt: float) -> void:
	var pr = Game.profile
	if not pr.get("flags", {}).get("hatred", false):
		return
	if not Buffs.has("hatred"):
		_apply_hatred_buff()   # kayıttan yüklenince
	_hatred_t -= dt
	if _hatred_t <= 0.0:
		_hatred_t = randf_range(240.0, 420.0)
		Hud.msg("(" + HATRED_LINES.pick_random() + ")", Color(0.75, 0.4, 0.45), 4.0)


# ------------------------------------------------------------------ Sharingan okuma: saldırı öngörüsü + genjutsu direnci
## Düşman vuruşa başlarken Sharingan açıksa kısa kırmızı iz: hamleyi önceden görürsün (Enemy saldırı başlangıcı çağırır)
static func warn_attack(e: Node3D) -> void:
	var pl = Game.player
	if pl == null or not is_instance_valid(pl) or pl.combat == null or pl.combat.modes == null:
		return
	var ey = pl.combat.modes.eyes
	if ey == null or not ey.active or not (ey._kind("sag") in [1, 4, 5] or ey._kind("sol") in [1, 4, 5]):
		return
	if e.global_position.distance_to(pl.global_position) > 14.0:
		return
	FX.ring(e.global_position + Vector3.UP * 1.3, Color(1.0, 0.12, 0.15), 1.1, 0.22, false)


## Sharingan sahibine atılan genjutsu (göz göze sersemletme) kısalır; 3 tomoe / Mangekyō hemen kırar
static func genjutsu_resist(t: Node) -> float:
	if t == Game.player:
		var pl = Game.player
		if pl.combat and pl.combat.modes and pl.combat.modes.eyes and pl.combat.modes.eyes.active:
			var ey = pl.combat.modes.eyes
			var best = 0
			for s in ["sag", "sol"]:
				if ey._kind(s) in [1, 4, 5]:
					best = maxi(best, ey._lvl(s) + (2 if ey._kind(s) >= 4 else 0))
			if best >= 3:
				return 0.0
			if best > 0:
				return 0.5
		return 1.0
	if t.has_meta("eyes") and int(t.get_meta("eyes").get("kind", 0)) in [1, 4, 5]:
		return 0.0 if int(t.get_meta("eyes").get("lvl", 1)) >= 3 or int(t.get_meta("eyes").get("kind", 0)) >= 4 else 0.5
	return 1.0


## Genjutsu isabet kapısı (tüm Sharingan genjutsuları, oyuncu ve düşman aynı): döndürdüğü çarpan 0 ise genjutsu tutmadı.
## - Göz teması (need_eye): hedef sana bakmıyorsa tutmaz (kanon karşı-oyun: gözlerine bakma).
## - Magen: Kyō Tenchi-ten açık hedef genjutsuyu çözüp SALDIRANA geri yansıtır.
## - Sharingan direnci (genjutsu_resist).
static func genjutsu_land(caster: Node3D, t: Node3D, need_eye := true) -> float:
	if t == null or not is_instance_valid(t) or t.is_dead():
		return 0.0
	if need_eye and t.has_method("face_dir") and not (t.has_method("has_status") and (t.has_status("stun") or t.has_status("bind"))):
		var v = caster.global_position - t.global_position
		v.y = 0.0
		if v.length() > 0.5 and t.face_dir().dot(v.normalized()) < 0.25:
			Combat.popup_text(t.global_position + Vector3.UP * 2.3, "Göz göze gelmedi", Color(0.8, 0.8, 0.8))
			return 0.0
	var kyo = (t == Game.player and Buffs.has("magen_kyo")) or (t.has_meta("kyo_until") and Time.get_ticks_msec() < int(t.get_meta("kyo_until")))
	if kyo and caster != t and is_instance_valid(caster) and not caster.is_dead():
		# ayna: genjutsu çözülür ve aynen saldırana döner
		Combat.popup_text(t.global_position + Vector3.UP * 2.4, "Kyō Tenchi-ten!", Color(1, 0.35, 0.4))
		Combat.popup_text(caster.global_position + Vector3.UP * 2.4, "Genjutsu geri döndü!", Color(1, 0.35, 0.4))
		VFX.star(t.global_position + Vector3.UP * 1.65, Color(1, 0.2, 0.25), 2.2, 0.2)
		VFX.shockwave(caster.global_position + Vector3.UP * 1.6, Color(0.9, 0.1, 0.15), 3.0, 0.35, false)
		caster.apply_status("stun", 3.0)
		caster.apply_status("fear", 3.0)
		if caster == Game.player and Game.world:
			Game.world.env.flash_tint(Color(0.85, 0.05, 0.05, 0.3), 1.2)
		return 0.0
	var rs = genjutsu_resist(t)
	if rs < 1.0:
		Combat.popup_text(t.global_position + Vector3.UP * 2.4, "Genjutsu kırıldı!" if rs == 0.0 else "Sharingan direndi", Color(1, 0.5, 0.5))
	return rs


# ------------------------------------------------------------------ Mangekyō göz YETENEKLERİ (jutsu değil; animede adı olmayan güçler)
func has_style(st: String) -> bool:
	return st in ms_styles(Game.profile)


func _eye_ability(id: String, t: Node3D) -> void:
	if t != null and (not is_instance_valid(t) or t.is_dead()):
		t = null   # ölü / silinmiş hedef seçilmesin
	match id:
		"@kamui_kyuin":
			_kamui_absorb(t)
		"@kamui_tobi":
			_kamui_warp(t)
		"@shisui_shunshin":
			_shisui_shunshin(t)


## Kısa menzil Kamui (Obito): yakındaki hedef girdaba çekilir. Zayıfsa Kamui boyutuna yutulur; güçlüyse direnir,
## ağır yarayla kurtulur (anime: Konan / Kakashi'nin kolu). Tutarken sen de yerindesin.
func _kamui_absorb(t: Node3D) -> void:
	var tg = t if t and t.global_position.distance_to(p.global_position) < 7.0 else Combat.nearest_enemy(p, 7.0, p.face_dir(), 0.2)
	if tg != null and tg.is_dead():
		tg = null
	if tg == null:
		Hud.msg("Kamui: dokunacak kadar yakında hedef yok (7 m).", Color(0.8, 0.8, 0.8))
		cd["sag"] = 0.5
		return
	var at = tg.global_position + Vector3.UP * 1.1
	MsArts.kamui_vortex(at, 1.8, 1.4)
	tg.apply_status("stun", 1.3)
	if p.combat:
		p.combat.action = "cast"
	var weak = not tg.has_meta("boss") and (int(tg.get("level")) <= int(Game.profile.get("level", 1)) or float(tg.get("hp")) < float(tg.get("max_hp")) * 0.5)
	Sfx.play("genjutsu", at, 0.7)
	if tg.get("model"):
		var tw = tg.model.create_tween()
		tw.tween_property(tg.model, "scale", tg.model.scale * (0.05 if weak else 0.7), 1.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(tg.model, "rotation:y", tg.model.rotation.y + TAU * 2.0, 1.1)
	get_tree().create_timer(1.15).timeout.connect(func():
		if p.combat and p.combat.action == "cast":
			p.combat.action = ""
		if not is_instance_valid(tg) or tg.is_dead():
			return
		if weak:
			Combat.popup_text(at + Vector3.UP, "Kamui boyutuna çekildi", Color(0.7, 0.55, 0.9))
			Game.profile["kamui_store"] = int(Game.profile.get("kamui_store", 0)) + 1
			tg.die({"execute": true, "attacker": p, "kamui": true, "dmg": 9999.0})
			if is_instance_valid(tg) and tg.get("model"):
				tg.model.visible = false
		else:
			if tg.get("model"):
				tg.model.create_tween().tween_property(tg.model, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK)
			Combat.popup_text(at + Vector3.UP, "Direndi!", Color(1, 0.6, 0.5))
			tg.take_hit({"dmg": float(tg.get("max_hp")) * 0.25 * _eye_pow(), "kind": "heavy", "knock": 10.0, "attacker": p, "dir": (tg.global_position - p.global_position).normalized()})
			VFX.star(at, Color(0.6, 0.45, 0.9), 2.4, 0.15))


## Kamui ışınlanması (Obito): baktığın yere / hedefin arkasına girdapla geçersin. Çıkışta kısa savunmasız an (anime: uzak geçiş anlık değil).
func _kamui_warp(t: Node3D) -> void:
	var from = p.global_position
	var dest: Vector3
	if t and is_instance_valid(t) and t.global_position.distance_to(from) < 40.0:
		var v = t.global_position - from
		v.y = 0
		dest = t.global_position + v.normalized() * 1.8
	else:
		var f = p.cam_forward() if p.has_method("cam_forward") else p.face_dir()
		f.y = 0
		dest = from + f.normalized() * 22.0
	dest.y = Game.jutsu_floor(dest.x, dest.z)
	MsArts.kamui_vortex(from + Vector3.UP * 1.1, 1.3, 0.8)
	add_blind(0.02 * minf(2.0, from.distance_to(dest) / 15.0))
	p.model.visible = false
	if p.combat:
		p.combat.invuln = maxf(p.combat.invuln, 0.5)
	Sfx.play("genjutsu", from, 1.2)
	get_tree().create_timer(0.4).timeout.connect(func():
		MsArts.kamui_vortex(dest + Vector3.UP * 1.1, 1.3, 0.8)
		p.global_position = dest + Vector3.UP * 0.2
		p.velocity = Vector3.ZERO
		if p.has_method("reset_physics_interpolation"):
			p.reset_physics_interpolation()
		get_tree().create_timer(0.3).timeout.connect(func(): p.model.visible = true)
		if t and is_instance_valid(t):
			var d = t.global_position - dest
			d.y = 0
			p.facing = atan2(-d.x, -d.z))


## Shisui'nin Shunshin'i: göz açıp kapayana dek hedefin yanına (ardıl görüntü izi), tek vuruş + kısa sersemletme
func _shisui_shunshin(t: Node3D) -> void:
	var tg = t if t and is_instance_valid(t) and t.global_position.distance_to(p.global_position) < 30.0 else Combat.nearest_enemy(p, 30.0)
	var from = p.global_position
	var dest = (tg.global_position + (from - tg.global_position).normalized() * 1.6) if tg else from + p.face_dir() * 14.0
	dest.y = Game.jutsu_floor(dest.x, dest.z)
	var col = Color(0.3, 0.95, 0.5)
	for k in 6:
		var q = from.lerp(dest, k / 5.0) + Vector3.UP
		VFX.puffs(q, {"amount": 5, "life": 0.45, "size": 0.7, "radius": 0.3, "vmin": 0.2, "vmax": 0.6, "colors": [Color(col.r, col.g, col.b, 0.45), Color(col.r, col.g, col.b, 0)]})
	p.global_position = dest + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO
	if p.has_method("reset_physics_interpolation"):
		p.reset_physics_interpolation()
	Sfx.play("whoosh", dest, 1.9)
	if tg and not tg.is_dead():
		var d = tg.global_position - dest
		d.y = 0
		p.facing = atan2(-d.x, -d.z)
		tg.take_hit({"dmg": 18.0 * _eye_pow(), "knock": 8.0, "kind": "heavy", "attacker": p, "dir": d.normalized(), "hitstop": 0.06})
		tg.apply_status("stun", 0.8)
	VFX.screen_lines(0.3, 0.8, col)


# ------------------------------------------------------------------ Kamui geçirgenliği (Obito)
## Basılı tuttukça (en fazla 3 sn) saldırılar içinden geçer; bu sırada saldıramazsın. Bırakınca katılaşırsın — animedeki zayıf
## nokta: katılaşma anı (tam o an gelen darbe işler; Minato / Naruto Obito'yu böyle vurdu). Chakra yer, Mangekyō körlüğü biriktirir.
const PHASE_MAX := 3.0
var phasing := false
var phase_t := 0.0
var phase_cd := 0.0
var _phase_vortex: Node3D


func _phase_start() -> void:
	phasing = true
	phase_t = 0.0
	if p.combat:
		p.combat.invuln = maxf(p.combat.invuln, 0.12)   # ilk karede de geçirgen
	_phase_vortex = MsArts.kamui_vortex(p.global_position + Vector3.UP * 1.0, 0.9, PHASE_MAX + 0.4)
	_set_phase_look(true)
	Sfx.play("genjutsu", p.global_position, 1.4, 0.5)


func _phase_end() -> void:
	if not phasing:
		return
	phasing = false
	phase_cd = 0.6
	_set_phase_look(false)
	if is_instance_valid(_phase_vortex):
		_phase_vortex.queue_free()
	Combat.popup_text(p.global_position + Vector3.UP * 2.2, "Katılaştı", Color(0.75, 0.6, 0.9))


func _phase_tick(dt: float) -> void:
	phase_cd = maxf(0.0, phase_cd - dt)
	if not phasing:
		return
	phase_t += dt
	if p.combat:
		p.combat.invuln = maxf(p.combat.invuln, 0.12)
	p.chakra -= 9.0 * dt * _transplant_mult()
	add_blind(0.006 * dt)
	if is_instance_valid(_phase_vortex):
		_phase_vortex.global_position = p.global_position + Vector3.UP * 1.0
	if phase_t >= PHASE_MAX or p.chakra <= 0.0 or not active or blind() >= 1.0:
		_phase_end()


func _set_phase_look(on: bool) -> void:
	if p.model == null:
		return
	for g in p.model.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = 0.55 if on else 0.0
