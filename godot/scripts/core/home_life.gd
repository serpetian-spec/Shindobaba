class_name HomeLife
extends ScenePoser
## Ev hayatı: oyuncunun evinde eş (ve çocuklar) gerçekten yaşar. Her şey sahne olarak oynanır, yazı kutusu değil:
## · eve girince eşin işini bırakıp karşılar (el sallar / sarılır; uzun süre uğramadıysan kollarını kavuşturup sırtını döner)
## · ev işleri: ocakta tencere karıştırır, masada çay içer, yeri süpürür
## · sofra: eşin ocakta pişirir, doğrar, tepsiyle sofraya getirir; herkes minderine oturur, "Itadakimasu", çubuklarla yenir
## · uyku: futona uzanılır, yorgan örtülür, lamba söner; sabah kalkılır, eşin gerinir
## · çıkarken kapıda uğurlar
## İhmal: evden uzak geçen oyun süresi birikir; eşin köyde seni bulup sitem eder, bağ düşer.

const AWAY_WARN := 1500.0   # 25 dk eve uğramazsan eşin sitem etmeye başlar
const AWAY_STEP := 600.0
const MEAL_CD := 480.0

static var cur: HomeLife
static var seeker: Node3D
static var seek_done := true

var I: Node
var W := 8.0
var D := 8.0
var H := 3.0
var sid := ""
var sp: Node3D
var kids: Array = []
var busy := false
var routine := ""
var routine_t := 0.0
var upset := false
var greeted := false
var bye := false
var lamps: Array = []
var lamp_e: Array = []
var blankets: Array = []
var dishes: Node3D
var steam: CPUParticles3D
var _kid_t := 0.0
# çocuk büyütme
var baby_kid := {}
var cradle: MeshInstance3D
var cradle_pos := Vector3.ZERO
var baby: MeshInstance3D
var baby_held: Node3D
var target_pos := Vector3.ZERO
var rock_amp := 0.0
var rock_after := 0.0
var _nt := 0.0
var leaves: Array = []
var kin_host := false   # bekârken evin sahibi annen (eş değil)
var folk: Array = []     # baban / kardeşin (akşam evde, sofrada)
var newborn := {}     # eve girerken yeni doğan (doğum sahnesi oynanır)
var mw: Node3D        # ebe
var greet_n := 0      # karşılama koşusu süren çocuk sayısı (bitmeden ders başlamaz)


# ------------------------------------------------------------------ durum (kayıt)
static func pr() -> Dictionary:
	return Game.profile


static func night() -> bool:
	var t = 0.4
	if Game.world and Game.world.get("env"):
		t = float(Game.world.env.time_of_day)
	return t < 0.27 or t > 0.74


## Eşin şu an evde mi (gece ya da "evde" işi; görevde / takımda / kaçak değilse)
static func spouse_home() -> bool:
	var id = Friends.spouse_id()
	if id == "" or not Friends.all().has(id):
		return false
	if Orgs.is_rogue():
		return RogueKin.at_home(id)   # köyde kalan eşin: yalnız gece, gizlice
	var f: Dictionary = Friends.all()[id]
	if not Friends.available(f) or f.get("party", false) or String(f.get("status", "")) != "":
		return false
	if float(pr().get("birth_wait", 0.0)) > 0.0:
		return true   # doğum: evde
	var job = Friends.job_of(f)
	if job == "görev":
		return false
	return night() or job == "evde"


## Evin sahibi: eşin; bekârsan annen
static func host_id() -> String:
	var s = Friends.spouse_id()
	if s != "" and Friends.all().has(s) and String(Friends.all()[s].get("status", "")) == "":
		return s
	return Kin.id_of("anne") if Kin.alive("anne") else ""


static func _kin_home(id: String) -> bool:
	if id == "" or not Friends.all().has(id):
		return false
	if Orgs.is_rogue():
		return RogueKin.at_home(id)
	var f: Dictionary = Friends.all()[id]
	if not Friends.available(f) or f.get("party", false) or String(f.get("status", "")) != "":
		return false
	return night() or Friends.job_of(f) == "evde"


static func host_home() -> bool:
	var id = host_id()
	if id == "":
		return false
	return spouse_home() if id == Friends.spouse_id() else _kin_home(id)


## Evin kapısı (kendi köyünde); köy kurulu değilse Vector3.INF
static func door_pos() -> Vector3:
	for it in Interact.items:
		if String(it.get("room", "")) == "home_player" and not it.get("interior", false) and String(it.get("home_of", Progress.home())) == Progress.home():
			return it["pos"]
	return Vector3.INF


## Evden uzak geçen süre: eşin önce köyde seni bulup sitem eder, sonra bağ düşmeye başlar
static func tick(dt: float) -> void:
	var id = Friends.spouse_id()
	if id == "" or not Friends.all().has(id) or Game.player == null:
		return
	if is_instance_valid(seeker) and not seek_done and seeker.global_position.distance_to(Game.player.global_position) < 3.4:
		seek_done = true
		seeker.wait = 6.0
		seeker.model.play("fold", 0.25)
		seeker.say(["Eve uğramayı unuttun mu? Sofra kaç gündür sensiz kuruluyor.", "Seni köyde arayıp duruyorum. Akşam eve gel artık.", "Kapıyı her açtığımda sen sanıyorum... Bu akşam evde ol."].pick_random(), 5.0)
	if is_instance_valid(cur):
		return
	var f: Dictionary = Friends.all()[id]
	if not Friends.available(f) or f.get("party", false) or Orgs.is_rogue():
		return   # birlikteyken ya da o köyde değilken ihmal sayılmaz
	var a = float(pr().get("home_away", 0.0)) + dt
	pr()["home_away"] = a
	var stage = 0 if a < AWAY_WARN else 1 + int((a - AWAY_WARN) / AWAY_STEP)
	if stage > int(pr().get("home_stage", 0)):
		pr()["home_stage"] = stage
		Friends.add_bond(id, -3, true)
		f["love"] = maxi(0, int(f.get("love", 0)) - 2)
		_seek(id)


static func _seek(id: String) -> void:
	var me = Friends.inst()
	if me == null or (Interiors.inst and Interiors.inst.inside != ""):
		return
	var v = Game.village(Progress.home())
	if v.is_empty() or Game.to_map(Game.player.global_position).distance_to(Vector2(v["x"], v["y"])) > float(v["r"]):
		return
	if me.visitor != null and is_instance_valid(me.visitor):
		return
	var d = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 18.0
	me.visitor = me._spawn_npc(id, Game.player.global_position + d, true)
	me.visit_t = 0.0
	seeker = me.visitor
	seek_done = false
	Hud.msg("%s seni arıyor, sana doğru geliyor." % Friends.all()[id]["name"], Color(1, 0.75, 0.8))


static func _quality(bond: int, love: int) -> void:
	pr()["home_away"] = 0.0
	pr()["home_stage"] = 0
	var id = Friends.spouse_id()
	if id != "" and Friends.all().has(id):
		Friends.add_bond(id, bond, true)
		var f: Dictionary = Friends.all()[id]
		f["love"] = mini(100, int(f.get("love", 0)) + love)


## Masadaki not (eşin evde değilken)
static func note_text() -> String:
	var id = Friends.spouse_id()
	if id == "" or not Friends.all().has(id) or spouse_home():
		return ""
	var f: Dictionary = Friends.all()[id]
	match Friends.job_of(f):
		"görev": return "\n\n%s'in notu: \"Göreve çıktım. Yemeğin ocakta, ısıtıp ye. Dönünce anlatırım.\"" % f["name"]
		"nöbet": return "\n\n%s'in notu: \"Kapı nöbetindeyim. Akşam evdeyim, beni bekle.\"" % f["name"]
		"antrenman": return "\n\n%s'in notu: \"Antrenman alanındayım. İstersen gel, birlikte çalışalım.\"" % f["name"]
	return ""


## Eşinle evde konuşurken çıkan seçenekler
static func spouse_opts(id: String) -> Array:
	if not is_instance_valid(cur) or cur.sid != id or cur.busy or not is_instance_valid(cur.sp):
		return []
	var me = cur
	var opts = []
	if me.routine == "rest":
		return [{"label": "Dinlen, ben buradayım", "cb": func(): me._say(me.sp, ["Hı hı... iyi ki geldin.", "Bebeğe bakar mısın? Ben biraz kestireyim."].pick_random(), 3.0)}]
	if me.upset:
		opts.append({"label": "Özür dile (eğil)", "cb": func(): me._apologize()})
		return opts
	var now = Time.get_unix_time_from_system()
	if now - float(pr().get("home_meal_t", 0.0)) >= MEAL_CD:
		opts.append({"label": "Sofrayı kuralım (birlikte yemek)", "cb": func(): me._meal()})
	if now - float(pr().get("home_hug_t", 0.0)) >= 240.0:
		opts.append({"label": "Sarıl", "cb": func(): me._hug_seq(true)})
	opts.append({"label": "İyi geceler (sabaha kadar uyu)" if me.kin_host else "Yatalım (sabaha kadar uyu)", "cb": func(): me._sleep()})
	if Orgs.is_rogue():
		if int(pr().get("ryo", 0)) >= 500:
			opts.append({"label": "Sofraya para bırak (500 Ryō)", "cb": func(): me._rogue_gift()})
		opts.append({"label": "Benimle gel. Bu köyü bırak.", "cb": func(): me._rogue_take()})
	return opts


## Yatağa [F]: uzanıp gerçekten uyunur (evliysen eşin de yanına yatar). true: sahne başladı
static func on_bed() -> bool:
	if not is_instance_valid(cur) or cur.busy:
		return is_instance_valid(cur)
	cur._sleep()
	return true


# ------------------------------------------------------------------ kurulum (Interiors._home çağırır)
static func furnish(inter: Node, w: float, d: float, h: float) -> void:
	var hl = HomeLife.new()
	hl.I = inter
	hl.W = w
	hl.D = d
	hl.H = h
	cur = hl
	var married = Friends.spouse_id() != "" and Friends.all().has(Friends.spouse_id()) and String(Friends.all()[Friends.spouse_id()].get("status", "")) == ""   # (seninle kaçan eş artık bu evde yaşamaz)
	var hosted = married or host_id() != ""
	if hosted:
		hl.sid = host_id()
		hl.kin_host = not married
		hl._kitchen()
		# eşin futonu (çift yatak) + aile panosu
		var fx = w * 0.5 - 2.35
		inter.bx(fx, 0.1, 3.0, 1.1, 0.2, 2.1, Color(0.95, 0.95, 0.98), true)
		inter.bx(fx, 0.22, 2.6, 1.12, 0.06, 1.4, Color(0.75, 0.35, 0.45))
		inter.bx(fx, 0.24, 3.8, 0.6, 0.12, 0.35, Color(1, 1, 1))
		if married:
			inter.bx(-w * 0.25, 1.7, d - 0.04, 0.9, 0.7, 0.04, Color(0.3, 0.2, 0.12))   # düğün resmi çerçevesi
			inter.bx(-w * 0.25, 1.7, d - 0.07, 0.78, 0.58, 0.02, Color(0.96, 0.9, 0.86))
			inter.bx(-w * 0.25 - 0.14, 1.62, d - 0.085, 0.16, 0.34, 0.01, Color(0.15, 0.15, 0.2))
			inter.bx(-w * 0.25 + 0.14, 1.62, d - 0.085, 0.16, 0.34, 0.01, Color(0.98, 0.98, 1.0))
			inter.sp(-w * 0.25 - 0.14, 1.84, d - 0.085, Vector3(0.12, 0.12, 0.02), Color(0.95, 0.8, 0.7))
			inter.sp(-w * 0.25 + 0.14, 1.84, d - 0.085, Vector3(0.12, 0.12, 0.02), Color(0.95, 0.8, 0.7))
	# çocuk futonları
	var ki = 0
	for kid in pr().get("children", []):
		if kid.get("grad", false) or ki >= 3 or KidLife.stage(kid) == "bebek":
			continue
		var kx = w * 0.5 - 3.35 - ki * 0.85
		inter.bx(kx, 0.08, 2.6, 0.7, 0.16, 1.4, Color(0.95, 0.95, 0.98))
		inter.bx(kx, 0.18, 2.35, 0.72, 0.05, 0.9, [Color(0.95, 0.75, 0.3), Color(0.45, 0.7, 0.9), Color(0.6, 0.85, 0.5)][ki % 3])
		inter.bx(kx, 0.2, 3.1, 0.4, 0.09, 0.25, Color(1, 1, 1))
		ki += 1
	# bebek: beşik (futonların baş ucunda); çocuklar için duvarda shuriken hedefi
	hl.cradle_pos = inter.L(w * 0.5 - 1.75, 0.02, minf(d - 1.6, 5.4))
	hl.target_pos = inter.L(-0.35, 1.2, d) + Vector3(0, 0, 0.125)
	if married and float(pr().get("birth_wait", 0.0)) > 0.0 and spouse_home():
		hl.newborn = Friends.birth()   # doğum şimdi oldu: sahnesi oynanır
	for kid in ([hl.newborn] if not hl.newborn.is_empty() else pr().get("children", [])):
		if KidLife.stage(kid) == "bebek":
			hl.baby_kid = kid
			inter.act(w * 0.5 - 2.45, minf(d - 1.6, 5.4), 1.3, "cradle", "[F] Bebeği kucağına al")
			break
	inter.room.add_child(hl)


func _kitchen() -> void:
	var kx = -W * 0.5 + 0.45
	I.bx(kx, 0.42, 3.3, 0.75, 0.84, 2.1, Color(0.5, 0.36, 0.22), true)         # tezgâh
	I.bx(kx, 0.86, 3.3, 0.8, 0.05, 2.16, Color(0.72, 0.6, 0.42))
	I.bx(kx, 0.95, 2.75, 0.5, 0.14, 0.5, Color(0.25, 0.24, 0.24))              # kamado (ocak)
	I.gl("box", kx + 0.26, 0.95, 2.75, Vector3(0.02, 0.07, 0.2), Color(1.0, 0.5, 0.15))
	I.cy(kx, 1.12, 2.75, 0.36, 0.2, Color(0.2, 0.2, 0.22), 14)                 # tencere
	I.cy(kx, 1.215, 2.75, 0.31, 0.02, Color(0.82, 0.62, 0.38), 14)             # çorba
	I.bx(kx, 0.9, 3.75, 0.42, 0.035, 0.3, Color(0.85, 0.72, 0.5))              # kesme tahtası
	I.cy(kx - 0.05, 0.94, 3.72, 0.07, 0.05, Color(0.95, 0.95, 0.9), 8)         # turp dilimleri
	I.cy(kx + 0.06, 0.94, 3.8, 0.06, 0.05, Color(0.95, 0.55, 0.2), 8)
	I.bx(kx - 0.2, 1.75, 3.3, 0.3, 0.04, 1.8, Color(0.45, 0.3, 0.18))          # raf + kavanozlar
	for k in 5:
		I.cy(kx - 0.2, 1.87, 2.6 + k * 0.35, 0.15, 0.2, [Color(0.7, 0.3, 0.25), Color(0.85, 0.8, 0.6), Color(0.35, 0.5, 0.35), Color(0.3, 0.4, 0.6), Color(0.8, 0.7, 0.4)][k], 8)
	I.cy(kx, 0.25, 4.6, 0.4, 0.5, Color(0.5, 0.35, 0.2), 10)                   # pirinç fıçısı
	pot_pos = I.L(kx, 1.23, 2.75)
	board_pos = I.L(kx, 0.93, 3.75)
	steam = CPUParticles3D.new()
	steam.amount = 10
	steam.lifetime = 1.6
	steam.direction = Vector3.UP
	steam.spread = 12.0
	steam.gravity = Vector3.ZERO
	steam.initial_velocity_min = 0.25
	steam.initial_velocity_max = 0.4
	steam.scale_amount_min = 0.5
	steam.scale_amount_max = 1.0
	var sm = SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	var smat = StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = Color(1, 1, 1, 0.22)
	sm.material = smat
	steam.mesh = sm
	I.room.add_child(steam)
	steam.global_position = pot_pos + Vector3.UP * 0.05


func _ready() -> void:
	for c in I.room.get_children():
		if c is OmniLight3D:
			lamps.append(c)
			lamp_e.append(c.light_energy)
	_nursery()
	if sid != "" and host_home():
		var me = Friends.inst()
		sp = me._spawn_npc(sid, Game.player.global_position, false)
		sp.reparent(I.room)
		sp.set_physics_process(false)
		sp.interior = true
		I.npcs.append(sp)
		sp.global_position = I.L(-W * 0.5 + 1.2, 0.05, 2.75)
		_face(sp, PI * 0.5)
		upset = int(pr().get("home_stage", 0)) >= 1 and not kin_host
		if kin_host:
			_folk_spawn()
		busy = true   # karşılama bitene kadar başka sahne başlamaz
		if not newborn.is_empty() and is_instance_valid(baby):
			upset = false
			_birth_setup()
		elif is_instance_valid(baby) and not baby_kid.get("met", false) and not upset:
			# yeni doğan: eşin beşiğin başında bekler
			var lc = cradle_pos - I.origin
			sp.global_position = I.L(lc.x - 0.62, 0.05, -lc.z)
			_look_at(sp, cradle_pos)
			_set_routine("cradle")
		else:
			_set_routine("cook")
	_arrive.call_deferred()


func _exit_tree() -> void:
	if cur == self:
		cur = null
	_release_player()


func _sit_style(n: Node3D) -> String:
	if n == Game.player:
		return "seiza" if String(pr().get("gender", "m")) == "f" else "agura"
	if n == sp:
		return "seiza" if String(Friends.all().get(sid, {}).get("look", {}).get("gender", "m")) == "f" else "agura"
	if n in folk:
		return "seiza" if String(Friends.all().get(String(n.get_meta("friend_id", "")), {}).get("look", {}).get("gender", "m")) == "f" else "agura"
	return "seiza"


# ------------------------------------------------------------------ poz üretimi (her kare)
func _process(dt: float) -> void:
	_apply_poses(dt)
	_nursery_tick(dt)
	if not busy:
		_routine(dt)
		_door_watch()
	_kids_idle(dt)


# ------------------------------------------------------------------ hareket
func _go(n: Node3D, x: float, d: float, spd := 1.5) -> void:
	var tgt: Vector3 = I.L(x, 0.05, d)
	var t0 := 0.0
	while is_instance_valid(n):
		var to = tgt - n.global_position
		to.y = 0
		if to.length() < 0.1 or t0 > 9.0:
			break
		var dt = get_process_delta_time()
		t0 += dt
		_turn(n, atan2(-to.x, -to.z), dt * 9.0)
		var stp = to.normalized() * minf(spd * dt, to.length())
		n.global_position += stp
		if n == Game.player:
			n.velocity = Vector3.ZERO
		n.model.play("walk", 0.2, spd / 1.5)
		await get_tree().process_frame
	if is_instance_valid(n):
		n.model.play("idle", 0.25)


func _route(n: Node3D, pts: Array, spd := 1.5) -> void:
	_clear_pose(n)
	for p in pts:
		await _go(n, p[0], p[1], spd)


func _spouse_name() -> String:
	return String(Friends.all().get(sid, {}).get("name", "Eşin"))


func _table() -> Vector2:
	return Vector2(0.0, D * 0.5 + 0.5)


# ------------------------------------------------------------------ gündelik ev işleri (eş)
func _set_routine(k: String) -> void:
	routine = k
	routine_t = randf_range(14.0, 22.0)
	if not is_instance_valid(sp):
		return
	match k:
		"cook":
			_face(sp, PI * 0.5)
			_pose(sp, "stir", {"anim": "idle"})
		"tea":
			_face(sp, PI * 0.5)
			_pose(sp, "tea", {"anim": "idle", "sit": _sit_style(sp), "table": I.L(0.5, 0.41, _table().y)})
		"sweep":
			_pose(sp, "sweep", {"anim": "walk"})
		"sulk":
			_pose(sp, "none", {"anim": "fold"})
		"cradle":
			_look_at(sp, cradle_pos)
			_pose(sp, "rock", {"anim": "idle", "sit": "seiza"})
			if randf() < 0.6:
				_say(sp, ["♪ Nen nen korori yo...", "♪ Uyu yavrum, uyu...", "Şşş... hadi bakalım."].pick_random(), 4.0)


func _routine(dt: float) -> void:
	if not is_instance_valid(sp) or upset or routine == "rest":
		return   # rest: doğumdan sonra futonda dinleniyor
	routine_t -= dt
	if routine == "sweep":
		# süpürürken ağır ağır odayı dolaşır
		var c = I.L(sin(routine_t * 0.25) * 1.6, 0.05, 2.2 + cos(routine_t * 0.2) * 0.5)
		var to = c - sp.global_position
		to.y = 0
		if to.length() > 0.2:
			_look_at(sp, c, dt * 2.0)
			sp.global_position += to.normalized() * 0.35 * dt
	var near = Game.player.global_position.distance_to(sp.global_position) < 1.7
	if near and not routine in ["tea", "cradle"] and st.has(sp) and String(st[sp]["k"]) != "none":
		_clear_pose(sp)
		_pose(sp, "none", {"anim": "idle"})
	if near and not routine in ["tea", "cradle"]:
		_look_at(sp, Game.player.global_position, dt * 5.0)
		routine_t = maxf(routine_t, 2.0)
	elif not near and st.has(sp) and String(st[sp]["k"]) == "none" and routine != "":
		_resume()
	if routine_t <= 0.0:
		_next_routine()


func _resume() -> void:
	busy = true
	var k = routine
	match k:
		"cook": await _route(sp, [[-W * 0.5 + 1.2, 2.75]])
		"tea": await _route(sp, [[1.5, 3.4], [0.95, _table().y]])
		"sweep": await _route(sp, [[0.0, 2.4]])
		"cradle":
			var lc = cradle_pos - I.origin
			await _route(sp, [[1.5, 3.4], [lc.x - 0.62, -lc.z]])
	busy = false
	if is_instance_valid(sp):
		_set_routine(k)


func _next_routine() -> void:
	var opts = ["cook", "tea", "sweep"]
	if is_instance_valid(baby):
		opts.append_array(["cradle", "cradle"])
	opts.erase(routine)
	routine = opts.pick_random()
	_resume()


func _kids_idle(dt: float) -> void:
	_kid_t -= dt
	if _kid_t > 0.0:
		return
	_kid_t = 1.0
	kids = I.npcs.filter(func(k): return is_instance_valid(k) and String(k.role) == "kid")
	for k in kids:
		if k.global_position.y < I.origin.y - 0.6:   # emniyet: zeminin altına düşen çocuk odaya geri konur
			k.global_position = I.L(-0.6, 0.05, 2.2)
			k.velocity = Vector3.ZERO
			k.home = k.global_position
			k.goal = k.global_position
		if not k.has_meta("eyes_done") and k.model != null:
			k.set_meta("eyes_done", true)
			var cl: Array = kid_of(k).get("clans", [])
			if not cl.is_empty() and int(ClanWorld.EYE_KIND.get(String(cl[0]), 0)) == 2:
				k.model.set_dojutsu_eyes(2, 1, 2, 1, false)


# ------------------------------------------------------------------ sahneler
## Eve giriş: eşin işini bırakıp karşılar; çocuklar koşup gelir
func _arrive() -> void:
	await _wait(1.1)
	if not is_inside_tree() or greeted:
		busy = false
		return
	greeted = true
	_kids_idle(0.0)
	var pl = Game.player
	for i in kids.size():
		_kid_greet(kids[i], i)
	if not newborn.is_empty() and is_instance_valid(sp) and is_instance_valid(mw):
		pr()["home_away"] = 0.0
		pr()["home_stage"] = 0
		await _birth_scene()
		return
	if not is_instance_valid(sp):
		pr()["home_away"] = minf(float(pr().get("home_away", 0.0)), AWAY_WARN - 1.0) if sid != "" else 0.0
		return
	busy = true
	if Orgs.is_rogue():
		await _rogue_arrive()
		busy = false
		_resume()
		return
	if upset:
		# sitem: gelir ama sırtını dönüp kollarını kavuşturur
		await _route(sp, [[-W * 0.5 + 1.6, 2.6]])
		_look_at(sp, pl.global_position)
		_face(sp, sp.facing + 2.2)
		_pose(sp, "none", {"anim": "fold"})
		_say(sp, ["...Demek evin yolunu hatırladın.", "Kaç gündür tek başıma sofra kuruyorum.", "Hı. Geldin demek."].pick_random(), 4.5)
		routine = "sulk"
		busy = false
		return
	_clear_pose(sp)
	_look_at(sp, pl.global_position)
	_pose(sp, "wave", {"anim": "idle"})
	_say(sp, ["Hoş geldin! Yorgun görünüyorsun.", "Okaeri! Tam zamanında geldin.", "Hoş geldin! Bugün nasıl geçti?"].pick_random(), 3.5)
	await _wait(1.6)
	var f: Dictionary = Friends.all().get(sid, {})
	if int(f.get("love", 0)) >= 70 and Time.get_unix_time_from_system() - float(pr().get("home_hug_t", 0.0)) >= 240.0:
		await _hug_seq(false)
	else:
		_clear_pose(sp)
	pr()["home_away"] = 0.0
	busy = false
	if is_instance_valid(baby) and not baby_kid.get("met", false):
		baby_kid["met"] = true
		_say(sp, "Gel... %s seni bekliyor. Kucağına al." % String(baby_kid["name"]).split(" ")[-1], 3.0)
		await _wait(1.6)
		await _baby_hold()
		return
	_resume()


func _kid_greet(k: Node3D, i: int) -> void:
	var pl = Game.player
	k.set_physics_process(false)
	greet_n += 1
	var parent = KidLife.parent_word(kid_of(k))
	_say(k, ["%s geldi!" % parent, "%s! %s!" % [parent, parent], "Hoş geldin %s!" % parent.to_lower()][i % 3], 3.0)
	var side = Vector3(0.9 - i * 0.9, 0, -0.9)
	var t0 := 0.0
	while is_instance_valid(k) and t0 < 5.0:
		var tgt = pl.global_position + side
		# futonların (katı) üstüne koşmaz: odanın açık tarafında kalır
		var lt = tgt - I.origin
		tgt = I.L(clampf(lt.x, -W * 0.5 + 1.6, W * 0.5 - 3.4), 0.05, clampf(-lt.z, 1.7, D - 1.6))
		var to = tgt - k.global_position
		to.y = 0
		if to.length() < 0.25:
			break
		var dt = get_process_delta_time()
		t0 += dt
		_turn(k, atan2(-to.x, -to.z), dt * 10.0)
		k.global_position += to.normalized() * minf(3.2 * dt, to.length())
		k.model.play("run", 0.15, 0.8)
		await get_tree().process_frame
	if not is_instance_valid(k):
		greet_n -= 1
		return
	_look_at(k, pl.global_position)
	# sevinçten zıplar
	var y0 = k.global_position.y
	for h in 2:
		k.model.play("jump", 0.1, 1.2, true)
		var tt := 0.0
		while tt < 0.55 and is_instance_valid(k):
			tt += get_process_delta_time()
			k.global_position.y = y0 + sin(tt / 0.55 * PI) * 0.35
			await get_tree().process_frame
	if is_instance_valid(k):
		k.global_position.y = y0
		k.home = k.global_position
		k.goal = k.global_position
		k.model.play("idle", 0.2)
		k.set_physics_process(true)
	greet_n -= 1


## Sarılma: eşin yanına gelir, kollar gerçekten birbirini sarar
func _hug_seq(by_player: bool) -> void:
	if not is_instance_valid(sp):
		return
	var was_busy = busy
	busy = true
	var pl = Game.player
	_lock(6.0)
	_clear_pose(sp)
	if routine == "tea":
		await _route(sp, [[1.5, 3.4]])
	# eş oyuncunun önüne yürür (oyuncu ona döner)
	var t0 := 0.0
	while is_instance_valid(sp) and t0 < 6.0:
		var to = pl.global_position - sp.global_position
		to.y = 0
		_look_at(pl, sp.global_position, 0.2)
		pl.model.rotation.y = pl.facing
		if to.length() < 0.33:
			break
		var dt = get_process_delta_time()
		t0 += dt
		_turn(sp, atan2(-to.x, -to.z), dt * 9.0)
		sp.global_position += to.normalized() * minf(1.7 * dt, to.length() - 0.31)
		sp.model.play("walk", 0.2, 1.1)
		await get_tree().process_frame
	if not is_instance_valid(sp):
		_release_player()
		busy = was_busy
		return
	_look_at(sp, pl.global_position)
	_look_at(pl, sp.global_position)
	pl.model.play("idle", 0.2)
	sp.model.play("idle", 0.2)
	_pose(sp, "hug", {"with": pl, "anim": "idle", "hi": 0.14})
	_pose(pl, "hug", {"with": sp, "anim": "idle", "hi": -0.16})
	_say(sp, ["...Seni özledim.", "Sağ salim döndün ya, yeter.", "Biraz böyle kalalım."].pick_random() if not by_player else ["Ne oldu birden? ...İyi geldi ama.", "Hmm. Bugün zor geçti galiba.", "Buradayım."].pick_random(), 3.0)
	await _wait(1.0)
	Combat.popup_text((_bone(pl, "Head") + _bone(sp, "Head")) * 0.5 + Vector3.UP * 0.35, "♥", Color(1, 0.5, 0.65))
	await _wait(2.0)
	pr()["home_hug_t"] = Time.get_unix_time_from_system()
	_quality(1, 2)
	_clear_pose(sp)
	_clear_pose(pl)
	_release_player()
	busy = was_busy
	if not was_busy:
		_resume()


## Özür: önünde eğilirsin; eşin yumuşar, dönüp bakar
func _apologize() -> void:
	if busy or not is_instance_valid(sp):
		return
	busy = true
	var pl = Game.player
	_lock(5.0)
	_look_at(pl, sp.global_position)
	pl.model.rotation.y = pl.facing
	_pose(pl, "bow", {"anim": "idle", "len": 2.4})
	Combat.popup_text(pl.global_position + Vector3.UP * 2.0, "Özür dilerim...", Color(1, 0.9, 0.7))
	await _wait(1.3)
	if is_instance_valid(sp):
		var a0 = sp.facing
		var to = pl.global_position - sp.global_position
		var a1 = atan2(-to.x, -to.z)
		var k := 0.0
		while k < 1.0 and is_instance_valid(sp):
			k += get_process_delta_time() / 0.8
			_face(sp, lerp_angle(a0, a1, smoothstep(0.0, 1.0, k)))
			await get_tree().process_frame
		_pose(sp, "none", {"anim": "idle"})
		_say(sp, "...Kaldır başını. Bir daha beni bu kadar bekletme, tamam mı?", 4.0)
	await _wait(1.3)
	_clear_pose(pl)
	_release_player()
	upset = false
	pr()["home_stage"] = 0
	pr()["home_away"] = 0.0
	Friends.add_bond(sid, 2, true)
	busy = false
	_set_routine("cook")
	_resume()


## Sofra: pişir, doğra, tepsiyle getir, herkes otursun, ye
func _meal() -> void:
	if busy or not is_instance_valid(sp):
		return
	busy = true
	var pl = Game.player
	var tb = _table()
	pr()["home_meal_t"] = Time.get_unix_time_from_system()
	_lock(60.0)
	_say(sp, "Hemen hazırlıyorum. Sen sofraya geç.", 3.0)
	# oyuncu minderine yürür, oturur
	_seat(pl, -0.95, tb.y, -PI * 0.5, [[-1.5, 3.4], [-1.5, tb.y], [-0.95, tb.y]])
	# çocuklar minderlerine
	var seats = [[0.0, tb.y + 0.75, PI], [0.0, tb.y - 0.75, 0.0]]
	var dn = _diners()
	for i in dn.size():
		dn[i].set_physics_process(false)
		var at_seat = dn[i].global_position.distance_to(I.L(seats[i][0], 0.05, seats[i][1])) < 0.4
		if not at_seat:
			if dn[i] in folk:
				_clear_pose(dn[i])
				_say(dn[i], "Geliyorum!", 1.8)
			_seat(dn[i], seats[i][0], seats[i][1], seats[i][2], [[seats[i][0], seats[i][1]]])
	# eş: ocak -> karıştır -> doğra
	await _route(sp, [[1.5, 3.4], [-W * 0.5 + 1.2, 3.4], [-W * 0.5 + 1.2, 2.75]] if routine == "tea" else [[-W * 0.5 + 1.2, 2.75]])
	_face(sp, PI * 0.5)
	_pose(sp, "stir", {"anim": "idle"})
	if steam:
		steam.amount = 22
	await _wait(3.6)
	await _route(sp, [[-W * 0.5 + 1.2, 3.75]], 1.1)
	_face(sp, PI * 0.5)
	_pose(sp, "chop", {"anim": "idle"})
	_say(sp, ["Bugün miso çorbası, ızgara balık, pirinç.", "Turpu ince doğruyorum, sevdiğin gibi.", "Az kaldı!"].pick_random(), 2.6)
	await _wait(3.0)
	# tepsi
	var hold = {}
	tray = _prop(hold, "tray")
	_pose(sp, "carry", {"anim": "idle"})
	await _wait(0.5)
	st[sp]["anim"] = "walk"
	for p in [[-W * 0.5 + 1.2, 3.4], [1.5, 3.4], [1.5, tb.y], [0.95, tb.y]]:
		await _go_keep(sp, p[0], p[1], 1.2)
	_face(sp, PI * 0.5)
	st[sp]["anim"] = "idle"
	await _wait(0.3)
	# sofraya dizer: tepsi kaybolur, tabaklar masada
	if is_instance_valid(tray):
		tray.queue_free()
	_lay_table()
	Sfx.play("clink", I.L(0, 0.4, tb.y), 0.6)
	_pose(sp, "rest", {"anim": "idle", "sit": _sit_style(sp)})
	await _wait(0.8)
	var eaters = [pl, sp]
	for e2 in dn:
		eaters.append(e2)
	for e in eaters:
		if is_instance_valid(e):
			_pose(e, "clap", {"anim": "idle", "sit": st.get(e, {}).get("sit", "seiza")})
	Combat.popup_text(I.L(0, 1.5, tb.y), "Itadakimasu!", Color(1.0, 0.85, 0.5))
	await _wait(1.3)
	for i in eaters.size():
		if is_instance_valid(eaters[i]):
			_pose(eaters[i], "eat", {"anim": "idle", "sit": _sit_style(eaters[i]), "off": i * 0.55})
	var f: Dictionary = Friends.all().get(sid, {})
	var news = String(f.get("news", ""))
	var talk = [news if news != "" else "Bugün pazarda öyle bir kalabalık vardı ki...", "Sen anlat, görevde neler oldu?",
		"Çocuklar bugün bütün gün seni sordu." if not kids.is_empty() else ("Hep birlikte sofra... eskisi gibi." if kin_host else "Böyle baş başa yemek... iyi geliyor."), "Biraz daha pirinç koyayım mı?"]
	for i in talk.size():
		_say(sp, talk[i], 2.8)
		await _wait(1.6)
		if i == 1:
			Combat.popup_text(_bone(pl, "Head") + Vector3.UP * 0.4, "Mmm, çok güzel olmuş!", Color(1, 0.9, 0.6))
		if i == 2 and not dn.is_empty() and is_instance_valid(dn[0]):
			_say(dn[0], "Eline sağlık." if dn[0] in folk else "Bir kase daha!", 2.2)
		if i == 3 and dn.size() > 1 and is_instance_valid(dn[1]) and dn[1] in folk:
			_say(dn[1], "Son parça benim!", 2.2)
		await _wait(1.6)
	for e in eaters:
		if is_instance_valid(e):
			_pose(e, "clap", {"anim": "idle", "sit": st.get(e, {}).get("sit", "seiza")})
	Combat.popup_text(I.L(0, 1.5, tb.y), "Gochisōsama!", Color(1.0, 0.85, 0.5))
	await _wait(1.3)
	pl.hp = pl.max_hp
	pl.chakra = pl.max_chakra
	ClanMech.on_eat()
	Buffs.add("ev_yemegi", 360.0, {"melee": 1.12, "armor": 0.9})
	_quality(4, 3)
	f["last_meal"] = Time.get_unix_time_from_system()
	Friends.log_event(f, "Evde birlikte yemek yediniz")
	Hud.msg("Ev yemeği: can ve chakra doldu; 6 dakika güç +%12, alınan hasar -%10.", Color(1.0, 0.85, 0.5))
	for e in eaters:
		if is_instance_valid(e):
			_stand(e)
	await _wait(0.6)
	_release_player()
	for e3 in dn:
		if not is_instance_valid(e3):
			continue
		if e3 in folk:
			_pose(e3, "rest", {"anim": "idle", "sit": _sit_style(e3)})
		else:
			e3.home = e3.global_position
			e3.goal = e3.global_position
			e3.set_physics_process(true)
	if steam:
		steam.amount = 10
	busy = false
	_set_routine("tea")


func _go_keep(n: Node3D, x: float, d: float, spd: float) -> void:
	var tgt: Vector3 = I.L(x, 0.05, d)
	var t0 := 0.0
	while is_instance_valid(n):
		var to = tgt - n.global_position
		to.y = 0
		if to.length() < 0.1 or t0 > 9.0:
			break
		var dt = get_process_delta_time()
		t0 += dt
		_turn(n, atan2(-to.x, -to.z), dt * 9.0)
		n.global_position += to.normalized() * minf(spd * dt, to.length())
		await get_tree().process_frame


func _seat(n: Node3D, x: float, d: float, face: float, pts: Array) -> void:
	await _route(n, pts)
	if not is_instance_valid(n):
		return
	var k := 0.0
	var a0 = n.facing
	while k < 1.0 and is_instance_valid(n):
		k += get_process_delta_time() / 0.35
		_face(n, lerp_angle(a0, face, minf(1.0, k)))
		await get_tree().process_frame
	if is_instance_valid(n) and not st.has(n):
		_pose(n, "rest", {"anim": "idle", "sit": _sit_style(n)})


func _stand(n: Node3D) -> void:
	_clear_pose(n)
	n.model.play("idle", 0.3)


func _lay_table() -> void:
	if is_instance_valid(dishes):
		dishes.queue_free()
	var tb = _table()
	var b = MB.new()
	var spots = [[-0.42, 0.0], [0.42, 0.0], [0.0, 0.28], [0.0, -0.28]]
	var n = 2 + mini(kids.size(), 2)
	for i in n:
		var q = Vector3(spots[i][0], 0.0, -spots[i][1])
		b.add("hemi", q + Vector3(0.1, 0.045, 0), Vector3(0.11, 0.09, 0.11), Color(0.15, 0.12, 0.1), Vector3(180, 0, 0), 10)   # miso çorbası
		b.add("cyl", q + Vector3(0.1, 0.043, 0), Vector3(0.098, 0.006, 0.098), Color(0.8, 0.6, 0.35), Vector3.ZERO, 10)
		b.add("box", q + Vector3(-0.08, 0.01, 0.0), Vector3(0.17, 0.014, 0.1), Color(0.9, 0.9, 0.86))                         # balık tabağı
		b.add("sphere", q + Vector3(-0.08, 0.03, 0.0), Vector3(0.14, 0.03, 0.05), Color(0.72, 0.5, 0.3), Vector3.ZERO, 8)
	b.add("cyl", Vector3(0, 0.03, 0), Vector3(0.14, 0.06, 0.14), Color(0.3, 0.45, 0.35), Vector3.ZERO, 10)                    # turşu kâsesi
	dishes = _mesh(b)
	dishes.global_position = I.L(tb.x, 0.37, tb.y)


## Uyku: futona uzan, yorgan, lamba söner; sabah kalk
func _sleep() -> void:
	if busy:
		return
	busy = true
	var pl = Game.player
	_lock(60.0)
	var with_sp = is_instance_valid(sp) and not upset and routine != "rest" and not kin_host
	var fx = W * 0.5 - 1.2
	var sleepers = [[pl, fx]]
	if with_sp:
		_say(sp, ["İyi geceler...", "Yoruldun, hadi yat artık.", "Oyasumi."].pick_random(), 3.0)
		sleepers.append([sp, W * 0.5 - 2.35])
	var ki = 0
	for k in kids:
		if is_instance_valid(k) and ki < 3:
			k.set_physics_process(false)
			sleepers.append([k, W * 0.5 - 3.35 - ki * 0.85])
			ki += 1
	var cnt = [0]
	for s in sleepers:
		_lie_down(s[0], s[1], cnt)
	var guard := 0.0
	while cnt[0] < sleepers.size() and guard < 14.0:
		guard += get_process_delta_time()
		await get_tree().process_frame
	# yorganlar
	for s in sleepers:
		var kid = s[0] != pl and s[0] != sp
		var b = MB.new()
		b.add("sphere", Vector3.ZERO, Vector3(0.78 if kid else 1.16, 0.3 if kid else 0.4, 1.25 if kid else 1.6), Color(0.3, 0.42, 0.7) if s[0] == pl else (Color(0.78, 0.38, 0.48) if s[0] == sp else Color(0.95, 0.78, 0.35)), Vector3.ZERO, 14)
		var m = _mesh(b)
		var end = I.L(s[1], 0.27 if not kid else 0.24, 2.75 if not kid else 2.4)
		m.global_position = end + Vector3(0, 0, 0.9)
		m.scale = Vector3(1, 1, 0.1)
		var tw = create_tween().set_parallel(true)
		tw.tween_property(m, "global_position", end, 0.8)
		tw.tween_property(m, "scale", Vector3.ONE, 0.8)
		blankets.append(m)
	await _wait(1.0)
	var tl = create_tween().set_parallel(true)
	for l in lamps:
		tl.tween_property(l, "light_energy", 0.06, 1.4)
	await _wait(2.2)
	await I._fade(1.0, 0.8)
	if Game.world:
		Game.world.env.time_of_day = 0.27
	pl.hp = pl.max_hp
	pl.chakra = pl.max_chakra
	Buffs.add("dinlenmis", 600.0, {"armor": 0.92, "melee": 1.05})
	if with_sp:
		_quality(3, 2)
	Game.save_game()
	await _wait(0.7)
	for i in lamps.size():
		lamps[i].light_energy = lamp_e[i]
	for m in blankets:
		if is_instance_valid(m):
			m.queue_free()
	blankets.clear()
	await I._fade(0.0, 0.9)
	for s in sleepers:
		_get_up(s[0])
	await _wait(2.3)
	if with_sp and is_instance_valid(sp):
		_pose(sp, "stretch", {"anim": "idle"})
		_say(sp, ["Günaydın! İyi uyudun mu?", "Ohayō... Kahvaltıyı hazırlayayım.", "Günaydın. Bugün dikkatli ol, olur mu?"].pick_random(), 3.5)
	_pose(pl, "stretch", {"anim": "idle"})
	await _wait(2.5)
	_clear_pose(pl)
	_release_player()
	if is_instance_valid(sp):
		_clear_pose(sp)
	for k in kids:
		if is_instance_valid(k):
			k.home = k.global_position
			k.goal = k.global_position
			k.set_physics_process(true)
	Hud.msg("Sabah oldu. Dinlendin: can ve chakra doldu, oyun kaydedildi.", Color(0.8, 0.9, 1.0))
	busy = false
	if is_instance_valid(sp):
		_set_routine("cook")
		_resume()


const LIE_FACE := PI      # uzanınca baş yastığa (odanın derinine) gelsin
const LIE_D := 2.7     # uzanış canlandırması gövdeyi geriye yatırır: ayaklar burada, baş yastıkta


func _lie_down(n: Node3D, x: float, cnt: Array) -> void:
	await _route(n, [[x - 0.75 if n == Game.player or n == sp else x, 1.75], [x, 2.2]])
	if is_instance_valid(n):
		var kid = n != Game.player and n != sp
		n.global_position = I.L(x, 0.24 if not kid else 0.72, LIE_D - (0.0 if not kid else 0.3))   # çocuk modeli kısa bacak için aşağı kayık: yükseltilir
		_face(n, LIE_FACE)
		var full: String = CharacterModel.ANIM["getup"]
		n.model.current = "getup"
		n.model.anim.play(full, 0.3, -1.4, true)
		await _wait(1.6)
	cnt[0] += 1


func _get_up(n: Node3D) -> void:
	if not is_instance_valid(n):
		return
	n.model.play("getup", 0.1, 1.0, true)
	await _wait(2.1)
	if is_instance_valid(n):
		if n != Game.player:
			n.global_position.y = I.L(0, 0.05, 0).y
		n.model.play("idle", 0.3)


## Kapıya yürüyünce eşin uğurlar
func _door_watch() -> void:
	if bye or not greeted or not is_instance_valid(sp) or upset or routine == "rest":
		return
	var pl = Game.player
	var lp = pl.global_position - I.L(0, 0, 0)
	if -lp.z > 1.3 or absf(lp.x) > 1.4 or pl.global_position.distance_to(sp.global_position) < 2.2:
		return
	bye = true
	_clear_pose(sp)
	if routine == "tea":
		return
	_look_at(sp, pl.global_position)
	_pose(sp, "wave", {"anim": "idle"})
	_say(sp, ["Arka sokaktan çık. Kimse görmesin.", "İz bırakma... ve yine gel.", "Sağ kal. Benim için."].pick_random() if Orgs.is_rogue() else ["Itterasshai! Dikkatli ol.", "Akşam yemeğe geç kalma!", "Sağ salim dön, tamam mı?"].pick_random(), 3.0)
	routine_t = 3.0


# ================================================================== ÇOCUK BÜYÜTME (veri: KidLife)
## Bebek: beşik + kucağa alma. Çocuk: shuriken dersi (duvardaki hedef), taijutsu (avuçlara vurur), yaprak çalışması, havaya kaldırma.
func _nursery() -> void:
	var any_kid = false
	for kid in pr().get("children", []):
		if KidLife.stage(kid) in ["çocuk", "akademi"]:
			any_kid = true
	if not baby_kid.is_empty():
		KidLife.ensure(baby_kid)
		var lk = Friends._look_raw(baby_kid)
		var wood = Color(0.6, 0.42, 0.25)
		var c = MB.new()
		c.add("box", Vector3(0, 0.3, 0), Vector3(0.52, 0.04, 0.86), wood)
		for sx in [-1.0, 1.0]:
			c.add("box", Vector3(sx * 0.26, 0.43, 0), Vector3(0.03, 0.26, 0.86), wood.darkened(0.1))
			for q in 5:
				c.add("box", Vector3(sx * 0.275, 0.43, -0.34 + q * 0.17), Vector3(0.012, 0.22, 0.03), wood.lightened(0.15))
		for sz in [-1.0, 1.0]:
			c.add("box", Vector3(0, 0.46, sz * 0.43), Vector3(0.55, 0.34, 0.03), wood.darkened(0.15))
			c.add("box", Vector3(0, 0.07, sz * 0.36), Vector3(0.74, 0.06, 0.05), wood.darkened(0.25))    # sallanma kızakları
			c.add("box", Vector3(-0.35, 0.11, sz * 0.36), Vector3(0.08, 0.05, 0.05), wood.darkened(0.25), Vector3(0, 0, -28))
			c.add("box", Vector3(0.35, 0.11, sz * 0.36), Vector3(0.08, 0.05, 0.05), wood.darkened(0.25), Vector3(0, 0, 28))
			for sx in [-1.0, 1.0]:
				c.add("box", Vector3(sx * 0.22, 0.19, sz * 0.36), Vector3(0.04, 0.22, 0.04), wood.darkened(0.2))
		c.add("box", Vector3(0, 0.345, 0), Vector3(0.47, 0.05, 0.8), Color(0.97, 0.96, 0.92))               # şilte
		cradle = _mesh(c)
		cradle.global_position = cradle_pos
		var fem = String(baby_kid.get("gender", "m")) == "f"
		var b = MB.new()
		b.add("sphere", Vector3(0, 0, -0.04), Vector3(0.2, 0.17, 0.42), Color(0.98, 0.78, 0.82) if fem else Color(0.72, 0.84, 0.97), Vector3.ZERO, 12)   # kundak
		b.add("box", Vector3(0, 0.05, 0.04), Vector3(0.19, 0.06, 0.04), Color(1, 1, 1))
		b.add("sphere", Vector3(0, 0.03, 0.22), Vector3(0.15, 0.145, 0.15), lk.get("skin", Color(0.96, 0.8, 0.66)), Vector3.ZERO, 12)                   # baş
		b.add("sphere", Vector3(0, 0.035, 0.262), Vector3(0.145, 0.135, 0.09), lk.get("hair", Color(0.3, 0.2, 0.12)), Vector3.ZERO, 10)                 # saç
		b.add("sphere", Vector3(0, 0.1, 0.25), Vector3(0.04, 0.03, 0.04), lk.get("hair", Color(0.3, 0.2, 0.12)), Vector3.ZERO, 6)                       # perçem
		for sx in [-1.0, 1.0]:
			b.add("box", Vector3(sx * 0.03, 0.1, 0.2), Vector3(0.026, 0.005, 0.007), Color(0.15, 0.1, 0.08))                                           # kapalı gözler
			b.add("sphere", Vector3(sx * 0.045, 0.085, 0.175), Vector3(0.03, 0.012, 0.03), Color(1.0, 0.6, 0.6), Vector3.ZERO, 6)                     # yanaklar
		baby = _mesh(b)
		baby.global_position = cradle_pos + Vector3(0, 0.44, 0)
	if any_kid:
		var t = MB.new()
		t.add("box", Vector3(0, 0, -0.02), Vector3(0.8, 0.8, 0.04), Color(0.45, 0.3, 0.18))
		t.add("cyl", Vector3(0, 0, 0.03), Vector3(0.64, 0.1, 0.64), Color(0.86, 0.76, 0.5), Vector3(90, 0, 0), 20)     # hasır hedef
		t.add("cyl", Vector3(0, 0, 0.034), Vector3(0.46, 0.1, 0.46), Color(0.8, 0.2, 0.15), Vector3(90, 0, 0), 20)
		t.add("cyl", Vector3(0, 0, 0.038), Vector3(0.3, 0.1, 0.3), Color(0.95, 0.93, 0.85), Vector3(90, 0, 0), 20)
		t.add("cyl", Vector3(0, 0, 0.042), Vector3(0.12, 0.1, 0.12), Color(0.8, 0.2, 0.15), Vector3(90, 0, 0), 14)
		var tm = _mesh(t)
		tm.global_position = target_pos - Vector3(0, 0, 0.09)


## Bebeğin kucakta durduğu nokta (göğüs önü, hafif sallanır)
func _lap(n: Node3D, t: float) -> Vector3:
	var fd = _fd(n)
	var h = 0.7 if st.has(n) and st[n].has("sit") else 1.25
	return n.global_position + Vector3.UP * (h * n.model.age_scale + sin(t * 3.4) * 0.012) + fd * 0.2 + fd.cross(Vector3.UP).normalized() * sin(t * 1.7) * 0.045


func _nursery_tick(dt: float) -> void:
	_nt += dt
	if is_instance_valid(cradle):
		rock_amp = lerpf(rock_amp, 0.11 if routine == "cradle" and st.has(sp) and String(st[sp]["k"]) == "rock" else (0.07 if rock_after > 0.0 else 0.0), minf(1.0, dt * 2.0))
		rock_after -= dt
		var ang = sin(_nt * 2.2) * rock_amp
		cradle.global_basis = Basis(Vector3(0, 0, 1), ang)
		if is_instance_valid(baby):
			var pos = cradle_pos + Vector3(0, 0.44, 0).rotated(Vector3(0, 0, 1), ang)
			var bas = Basis(Vector3(0, 0, 1), ang)
			if is_instance_valid(baby_held):
				var n = baby_held
				var fd = _fd(n)
				var right = fd.cross(Vector3.UP).normalized()
				pos = _lap(n, _nt) + Vector3.UP * 0.075
				var z = (-right + Vector3.UP * 0.22).normalized()
				var y = (Vector3.UP - fd * 0.45)
				y = (y - z * y.dot(z)).normalized()
				bas = Basis(y.cross(z), y, z)
			var k = minf(1.0, dt * 9.0)
			baby.global_position = baby.global_position.lerp(pos, k)
			baby.global_basis = baby.global_basis.orthonormalized().slerp(bas.orthonormalized(), k)
	# yapraklar (chakra çalışması)
	for L in leaves:
		var m: MeshInstance3D = L["m"]
		if not is_instance_valid(m) or not is_instance_valid(L["n"]):
			continue
		L["t"] = float(L["t"]) + dt
		if String(L["mode"]) == "stick":
			var n2: Node3D = L["n"]
			var fd2 = _fd(n2)
			var sc = n2.model.age_scale
			# alnın ortası: başın kendi eğimine göre (öne eğik başta da yüzeyde kalır)
			var sk: Skeleton3D = n2.model.skel
			var hb = (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head"))).basis.orthonormalized()
			var upv = hb.y
			var fw = (fd2 - upv * fd2.dot(upv)).normalized()
			var wob = sin(float(L["t"]) * 7.0) * float(L.get("wob", 0.0))
			m.global_position = _bone(n2, "Head") + upv * 0.155 * sc + fw * (0.135 if sc < 0.9 else 0.15) * sc + fw.cross(upv) * wob
			m.global_basis = Basis(fw.cross(upv).normalized(), fw, upv) * Basis(Vector3(0, 1, 0), wob * 8.0)
		elif String(L["mode"]) == "fall":
			var fl = I.L(0, 0.065, 0).y
			if m.global_position.y > fl:
				var tt = float(L["t"])
				m.global_position += Vector3(cos(tt * 4.0) * 0.25, -0.55, sin(tt * 3.1) * 0.12) * dt
				m.global_basis = Basis(Vector3(0, 0, 1), sin(tt * 4.0) * 0.9) * Basis(Vector3(1, 0, 0), 0.4)
			else:
				m.global_position.y = fl
				m.global_basis = Basis(Vector3(1, 0, 0), -PI * 0.5)
				L["mode"] = "rest"


static func kid_of(v: Node) -> Dictionary:
	if not is_instance_valid(cur) or v.get("interior") != true or String(v.get("role")) != "kid":
		return {}
	for kid in pr().get("children", []):
		if not kid.get("grad", false) and String(kid["name"]) == String(v.display_override):
			return kid
	return {}


## Evde çocuğunla konuşurken çıkan seçenekler
static func kid_opts(v: Node) -> Array:
	var kid = kid_of(v)
	if kid.is_empty() or cur.busy or cur.greet_n > 0:
		return []
	var me = cur
	var o = []
	var cd = KidLife.cd_left(kid, "lesson")
	if cd <= 0.0:
		o.append({"label": "Shuriken atmayı öğret", "cb": func(): me._kid_shuriken(v, kid)})
		o.append({"label": "Taijutsu çalıştır (avuçlarına vursun)", "cb": func(): me._kid_taijutsu(v, kid)})
		o.append({"label": "Yaprak çalışması (chakra kontrolü)", "cb": func(): me._kid_leaf(v, kid)})
	if KidLife.cd_left(kid, "play") <= 0.0:
		o.append({"label": "Havaya kaldır, döndür", "cb": func(): me._kid_lift(v, kid)})
	o.append({"label": "Neler öğrendin?", "cb": func():
		var parts = []
		for k in KidLife.LESSONS:
			parts.append("%s: %d" % [KidLife.LESSONS[k], int(KidLife.skill(kid, k))])
		Hud.dialog(String(v.display_override), "%s\n\n%s%s" % [["Bak bak! Hepsini ezberledim!", "Bugün de çalıştım!", "Akademide en iyisi ben olacağım!"].pick_random(), "  •  ".join(parts),
			("\n(Yoruldu: yeni ders için %d dk dinlenmeli.)" % int(ceil(cd / 60.0))) if cd > 0.0 else ""], [])})
	return o


## Beşiğe [F]
static func on_cradle() -> bool:
	if not is_instance_valid(cur) or cur.busy or not is_instance_valid(cur.baby):
		return false
	cur._baby_hold()
	return true


func _kid_begin(k: Node3D) -> void:
	busy = true
	_lock(90.0)
	Hud.close_dialog()
	if is_instance_valid(k):
		k.set_physics_process(false)
		k.global_position.y = I.L(0, 0.05, 0).y   # futonun üstünde duruyorsa yere iner (otururken havada kalmasın)
		if k.get("bubble") != null and is_instance_valid(k.bubble):
			k.bubble.visible = false


func _kid_end(k: Node3D) -> void:
	var pl = Game.player
	_clear_pose(pl)
	pl.model.play("idle", 0.3)
	_release_player()
	if is_instance_valid(k):
		_clear_pose(k)
		k.global_position.y = I.L(0, 0.05, 0).y
		k.model.play("idle", 0.3)
		k.home = k.global_position
		k.goal = k.global_position
		k.set_physics_process(true)
	busy = false
	if is_instance_valid(sp) and routine != "rest":
		_resume()


func _hop(k: Node3D, n: int) -> void:
	var y0 = k.global_position.y
	for h in n:
		if not is_instance_valid(k):
			return
		k.model.play("jump", 0.1, 1.2, true)
		var tt := 0.0
		while tt < 0.55 and is_instance_valid(k):
			tt += get_process_delta_time()
			k.global_position.y = y0 + sin(tt / 0.55 * PI) * 0.35
			await get_tree().process_frame
	if is_instance_valid(k):
		k.global_position.y = y0
		k.model.play("idle", 0.2)


func _tell(text: String, dur := 2.6) -> void:
	Combat.popup_text(_bone(Game.player, "Head") + Vector3.UP * 0.35, text, Color(1.0, 0.92, 0.72))
	await _wait(dur)


## Saçını okşa (ders sonu) + kazanım
func _pat_end(k: Node3D, kid: Dictionary, key: String, good: bool, line: String) -> void:
	var pl = Game.player
	if not is_instance_valid(k):
		_kid_end(k)
		return
	var to = pl.global_position - k.global_position
	to.y = 0
	var spot = k.global_position + to.normalized() * 0.52
	var lp = spot - I.origin
	await _go(pl, lp.x, -lp.z, 1.3)
	_look_at(pl, k.global_position)
	_look_at(k, pl.global_position)
	_pose(pl, "pat", {"anim": "idle", "with": k})
	_say(k, line, 2.6)
	await _wait(2.3)
	var amt = KidLife.train(kid, key, good)
	if is_instance_valid(k):
		Combat.popup_text(_bone(k, "Head") + Vector3.UP * 0.4, "%s +%s" % [KidLife.LESSONS[key], str(snappedf(amt, 0.1))], Color(0.6, 1.0, 0.7))
	Sfx.play("levelup", pl.global_position, 0.35)
	if sid != "" and Friends.all().has(sid):
		Friends.add_bond(sid, 1, true)
	await _wait(0.6)
	_kid_end(k)


# ------------------------------------------------------------------ bebek
func _baby_hold() -> void:
	if busy or not is_instance_valid(baby):
		return
	_kid_begin(null)
	var pl = Game.player
	var lc = cradle_pos - I.origin
	await _go(pl, lc.x - 0.74, -lc.z, 1.4)
	_look_at(pl, cradle_pos)
	_pose(pl, "reach", {"anim": "idle", "at": cradle_pos + Vector3(-0.05, 0.5, 0)})
	await _wait(0.9)
	baby_held = pl
	_pose(pl, "hold", {"anim": "idle"})
	await _wait(0.9)
	Combat.popup_text(baby.global_position + Vector3.UP * 0.3, "Agu~", Color(1, 0.8, 0.85))
	if is_instance_valid(sp) and not upset and routine != "rest":
		# eşin de gelir, parmağıyla sever
		if routine == "cradle" and st.has(sp):
			await _route(sp, [[lc.x - 1.25, -lc.z - 0.62]])
		else:
			await _route(sp, [[1.5, 3.4], [lc.x - 1.25, -lc.z - 0.62]])
		if is_instance_valid(sp):
			_look_at(sp, pl.global_position + _fd(pl) * 0.3)
			_pose(sp, "coo", {"anim": "idle"})
			_say(sp, ["Bak, sana gülüyor!", "Gözleri tıpkı seninkiler." if String(baby_kid.get("from", "sana")) == "sana" else "Burnu bana çekmiş, değil mi?", "Kucağında hemen sakinleşti."].pick_random(), 3.2)
	else:
		await _wait(1.2)
	await _wait(1.6)
	Combat.popup_text(baby.global_position + Vector3.UP * 0.3, "♪", Color(1, 0.8, 0.85))
	await _wait(1.8)
	Combat.popup_text(baby.global_position + Vector3.UP * 0.3, "Hihi!", Color(1, 0.8, 0.85))
	await _wait(1.8)
	_pose(pl, "reach", {"anim": "idle", "at": cradle_pos + Vector3(-0.05, 0.5, 0)})
	await _wait(0.5)
	baby_held = null
	rock_after = 6.0
	await _wait(0.8)
	if not baby_kid.has("tr"):
		baby_kid["tr"] = {}
	baby_kid["tr"]["bond"] = KidLife.skill(baby_kid, "bond") + 1.0
	if is_instance_valid(sp) and routine != "rest":
		_clear_pose(sp)
		Friends.add_bond(sid, 1, true)
	_kid_end(null)


# ------------------------------------------------------------------ shuriken dersi
func _throw(n: Node3D, to: Vector3, mode := "hit") -> void:
	n.model.play("throw", 0.1, 1.25, true)
	await _wait(0.36)
	if not is_instance_valid(n):
		return
	var b = MB.new()
	var steel = Color(0.72, 0.74, 0.78)
	for a in [0.0, 90.0]:
		b.add("box", Vector3.ZERO, Vector3(0.17, 0.034, 0.006), steel, Vector3(0, 0, a))
		b.add("box", Vector3.ZERO, Vector3(0.12, 0.05, 0.007), steel.darkened(0.15), Vector3(0, 0, a))
	b.add("cyl", Vector3.ZERO, Vector3(0.035, 0.012, 0.035), Color(0.2, 0.2, 0.22), Vector3(90, 0, 0), 8)
	var m = _mesh(b)
	var from = _hand(n, "Right")
	var end = to + Vector3(randf_range(-0.05, 0.05), randf_range(-0.05, 0.05), 0.02)
	var fl = I.L(0, 0.07, 0).y
	if mode == "wide":
		end = to + Vector3((1.0 if randf() < 0.5 else -1.0) * randf_range(0.5, 0.75), randf_range(-0.45, -0.1), -0.09)
	elif mode == "short":
		end = Vector3(to.x + randf_range(-0.3, 0.3), fl, to.z + randf_range(1.3, 1.8))
	Sfx.play("throw", from, 0.6)
	var dur = from.distance_to(end) / 13.0
	var dir = end - from
	dir.y = 0
	dir = dir.normalized()
	var bas = Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var k := 0.0
	while k < 1.0:
		k += get_process_delta_time() / dur
		var p = from.lerp(end, minf(k, 1.0))
		p.y += sin(minf(k, 1.0) * PI) * (0.55 if mode == "short" else 0.1)
		m.global_position = p
		m.global_basis = bas * Basis(Vector3(0, 0, 1), -k * dur * 42.0)
		await get_tree().process_frame
	if mode == "short":
		m.global_position = end
		m.global_basis = Basis(Vector3(1, 0, 0), PI * 0.5)
		Sfx.play("clink", end, 0.5)
	else:
		m.global_position = end
		m.global_basis = bas * Basis(Vector3(0, 0, 1), randf_range(0.2, 1.2))
		Sfx.play("kunai", end, 0.7)
	await _wait(0.3)
	if is_instance_valid(n):
		n.model.play("idle", 0.3)


func _kid_shuriken(k: Node3D, kid: Dictionary) -> void:
	if busy:
		return
	_kid_begin(k)
	var pl = Game.player
	var tl = target_pos - I.origin
	var tx = tl.x
	_say(k, ["Gerçekten mi?! Hadi hadi!", "Shuriken! Sonunda!", "Bu sefer tam ortadan vuracağım!"].pick_random(), 2.4)
	_go(k, tx, 2.7, 2.6)
	await _go(pl, tx + 0.9, 2.45, 1.5)
	await _wait(0.5)
	_look_at(pl, target_pos)
	_look_at(k, target_pos)
	await _tell("Önce izle.", 0.9)
	await _throw(pl, target_pos, "hit")
	_say(k, "Tam ortadan!", 1.8)
	await _wait(1.3)
	var skill = KidLife.skill(kid, "shuriken")
	var hits = 0
	var ok1 = randf() < clampf(0.1 + skill * 0.15, 0.1, 0.85)
	await _throw(k, target_pos, "hit" if ok1 else ("short" if skill < 2.0 else "wide"))
	if ok1:
		hits += 1
		_say(k, "İlk atışta!", 1.8)
		await _hop(k, 1)
	elif is_instance_valid(k):
		_pose(k, "pout", {"anim": "idle"})
		_say(k, ["Olmadı...", "Yine düştü...", "Neden seninki gibi gitmiyor?"].pick_random(), 2.2)
		await _wait(1.3)
		# arkasına geç, kolunu düzelt
		await _go(pl, tx + 0.2, 2.22, 1.4)
		_look_at(pl, target_pos)
		_pose(k, "aim", {"anim": "idle"})
		_pose(pl, "guide", {"anim": "idle", "with": k})
		await _tell("Omzunla değil bileğinle. Gözün hep hedefte.", 2.6)
		_clear_pose(pl)
		await _go(pl, tx + 0.9, 2.45, 1.4)
		_look_at(pl, target_pos)
		if is_instance_valid(k):
			_clear_pose(k)
	for i in 2:
		if not is_instance_valid(k):
			break
		var ok = randf() < clampf(0.5 + skill * 0.12, 0.5, 0.95)
		await _throw(k, target_pos, "hit" if ok else "wide")
		if ok:
			hits += 1
			_say(k, ["Vurdum!", "Gördün mü?! Gördün mü?!"][i], 1.8)
			await _hop(k, 1)
		else:
			_say(k, ["Az kaldı!", "Bir daha!"][i], 1.4)
			await _wait(0.8)
	await _pat_end(k, kid, "shuriken", hits >= 2, "Ben de senin gibi olacağım!" if hits >= 2 else "Yarın yine çalışalım, olur mu?")


# ------------------------------------------------------------------ taijutsu
func _kid_taijutsu(k: Node3D, kid: Dictionary) -> void:
	if busy:
		return
	_kid_begin(k)
	var pl = Game.player
	_say(k, ["Hazırım!", "Bugün seni yere sereceğim!", "Osu!"].pick_random(), 2.0)
	_go(k, -0.3, 2.6, 2.6)
	await _go(pl, 0.52, 2.6, 1.5)
	await _wait(0.5)
	if not is_instance_valid(k):
		_kid_end(k)
		return
	_look_at(pl, k.global_position)
	_look_at(k, pl.global_position)
	var c = k.global_position + Vector3.UP * 1.36 * k.model.age_scale + _fd(k) * 0.46
	_pose(pl, "pads", {"anim": "idle", "c": c, "rec": 0.0})
	await _tell("Yumruğunu sık. Kalçandan vur!", 1.2)
	var seq = ["jab", "cross", "jab", "cross", "hook", "jab", "cross", "hook"]
	for i in seq.size():
		if not is_instance_valid(k):
			break
		k.model.play(seq[i], 0.06, 1.35, true)
		await _wait(0.2)
		if st.has(pl):
			st[pl]["rec"] = 0.16 if seq[i] == "hook" else 0.1
		Sfx.play("punch", c, 0.45)
		if i % 3 == 1:
			_say(k, ["Ha!", "Ei!", "Ya!"][i / 3 % 3], 0.6)
		await _wait(0.34 if i < 4 else 0.24)
	# son vuruş: sahiden sarsılırsın
	if is_instance_valid(k):
		k.model.play("hook", 0.05, 1.0, true)
		await _wait(0.3)
		Sfx.play("hit_heavy", c, 0.4)
		if st.has(pl):
			st[pl]["rec"] = 0.26
		var back = -_fd(pl)
		var tt := 0.0
		pl.model.play("hit", 0.08, 1.0, true)
		while tt < 0.3:
			var dt = get_process_delta_time()
			tt += dt
			pl.global_position += back * 0.9 * dt
			await get_tree().process_frame
		_clear_pose(pl)
		await _tell("Oho! Güçlenmişsin.", 1.3)
		pl.model.play("idle", 0.3)
	if is_instance_valid(k):
		_pose(k, "tired", {"anim": "idle"})
		_say(k, "Hah... hah... bir daha!", 2.0)
		await _wait(1.7)
		_clear_pose(k)
	await _pat_end(k, kid, "taijutsu", true, ["Yumruklarım acıdı ama... iyi acıdı!", "Bir gün seni yeneceğim!"].pick_random())


# ------------------------------------------------------------------ yaprak çalışması (akademi chakra alıştırması)
func _leaf(n: Node3D) -> Dictionary:
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(0.09, 0.01, 0.14), Color(0.3, 0.62, 0.25), Vector3.ZERO, 8)
	b.add("box", Vector3(0, 0.003, 0), Vector3(0.004, 0.004, 0.12), Color(0.2, 0.42, 0.16))
	b.add("box", Vector3(0, 0, -0.075), Vector3(0.006, 0.006, 0.04), Color(0.3, 0.25, 0.12))
	var L = {"m": _mesh(b), "n": n, "mode": "stick", "t": 0.0, "wob": 0.0}
	leaves.append(L)
	return L


func _kid_leaf(k: Node3D, kid: Dictionary) -> void:
	if busy:
		return
	_kid_begin(k)
	var pl = Game.player
	_say(k, ["Yaprak mı? Akademide büyükler yapıyor onu!", "Bu sefer düşürmeyeceğim!"].pick_random(), 2.2)
	_go(k, -0.42, 2.7, 2.4)
	await _go(pl, 0.5, 2.7, 1.5)
	await _wait(0.5)
	if not is_instance_valid(k):
		_kid_end(k)
		return
	_look_at(pl, k.global_position)
	_look_at(k, pl.global_position)
	var kstyle = "seiza"
	_pose(pl, "rest", {"anim": "idle", "sit": "agura"})
	_pose(k, "rest", {"anim": "idle", "sit": kstyle})
	await _wait(1.0)
	await _tell("Yaprağı alnına koy. Chakranı tek noktaya topla.", 1.6)
	var lp = _leaf(pl)
	var lk = _leaf(k)
	lk["wob"] = 0.012
	_pose(pl, "seal", {"anim": "idle", "sit": "agura"})
	_pose(k, "seal", {"anim": "idle", "sit": kstyle})
	Sfx.play("chakra", pl.global_position, 0.25)
	await _wait(2.4)
	var skill = KidLife.skill(kid, "chakra")
	var good = randf() < clampf(0.15 + skill * 0.18, 0.15, 0.9)
	if not good and is_instance_valid(k):
		lk["mode"] = "fall"
		lk["t"] = 0.0
		_say(k, ["Aa! Düştü...", "Tutamıyorum!"].pick_random(), 2.0)
		_pose(k, "pout", {"anim": "idle", "sit": kstyle})
		await _wait(1.8)
		await _tell("Zorlama. Nefes al... chakrayı itme, tut.", 2.0)
		lk = _leaf(k)
		lk["wob"] = 0.006
		_pose(k, "seal", {"anim": "idle", "sit": kstyle})
		await _wait(3.0)
	if is_instance_valid(k):
		lk["wob"] = 0.0
		Sfx.play("chakra", k.global_position, 0.3)
		await _wait(1.6)
		_say(k, ["Duruyor! Duruyor!!", "Bak bak! Düşmüyor!"].pick_random(), 2.2)
		_pose(k, "cheer", {"anim": "idle", "sit": kstyle})
		await _wait(0.5)
		lk["mode"] = "fall"   # sevinince dikkati dağılır, yaprak süzülür
		lk["t"] = 0.0
		await _wait(1.5)
	lp["mode"] = "fall"
	lp["t"] = 0.0
	_clear_pose(pl)
	if is_instance_valid(k):
		_clear_pose(k)
	await _wait(0.5)
	for L in leaves:
		if is_instance_valid(L["m"]):
			L["m"].queue_free()
	leaves.clear()
	await _pat_end(k, kid, "chakra", good, ["Alnım gıdıklandı!", "Chakra... sıcak bir şeymiş."].pick_random())


# ------------------------------------------------------------------ oyun: havaya kaldır
func _kid_lift(k: Node3D, kid: Dictionary) -> void:
	if busy:
		return
	_kid_begin(k)
	var pl = Game.player
	_say(k, ["Kaldır kaldır!", "Uçur beni!"].pick_random(), 1.6)
	_go(k, -0.2, 2.5, 2.6)
	await _go(pl, 0.35, 2.5, 1.5)
	await _wait(0.4)
	if not is_instance_valid(k):
		_kid_end(k)
		return
	_look_at(pl, k.global_position)
	_look_at(k, pl.global_position)
	_pose(pl, "lift", {"anim": "idle", "with": k})
	await _wait(0.55)
	_pose(k, "fly", {"anim": "air"})
	var y0 = k.global_position.y
	var a0 = pl.facing
	var tt := 0.0
	var total := 4.6
	var said := 0
	while tt < total and is_instance_valid(k):
		var dt = get_process_delta_time()
		tt += dt
		var up = smoothstep(0.0, 0.7, tt) * (1.0 - smoothstep(total - 0.7, total, tt))
		var spin = smoothstep(0.5, 1.2, tt) * (1.0 - smoothstep(total - 1.3, total - 0.6, tt))
		_face(pl, pl.facing + spin * 3.6 * dt)
		var fd = _fd(pl)
		k.global_position = pl.global_position + fd * 0.52 + Vector3.UP * (up * (0.95 + sin(tt * 5.0) * 0.05))
		k.global_position.y = y0 + up * (0.95 + sin(tt * 5.0) * 0.05)
		_face(k, pl.facing + PI)
		if said == 0 and tt > 1.2:
			said = 1
			_say(k, "Hahaha! Daha hızlı!", 1.6)
		elif said == 1 and tt > 3.0:
			said = 2
			_say(k, "Uçuyorum!", 1.4)
		await get_tree().process_frame
	if is_instance_valid(k):
		k.global_position.y = y0
		_clear_pose(k)
		k.model.play("idle", 0.2)
	_clear_pose(pl)
	KidLife.mark(kid, "play")
	if not kid.has("tr"):
		kid["tr"] = {}
	kid["tr"]["bond"] = KidLife.skill(kid, "bond") + 1.0
	if is_instance_valid(k):
		_say(k, ["Bir daha! Bir daha!", "Başım döndü, hihi."].pick_random(), 2.0)
		Combat.popup_text(_bone(k, "Head") + Vector3.UP * 0.4, "♥", Color(1, 0.5, 0.65))
	await _wait(1.2)
	_kid_end(k)


# ------------------------------------------------------------------ çocuk sahnesi pozları
func _make(n: Node3D, s: Dictionary) -> Dictionary:
	var t: float = s["t"]
	var fd = _fd(n)
	var right = fd.cross(Vector3.UP).normalized()
	var sc: float = n.model.age_scale
	match String(s["k"]):
		"hold":   # bebek kucakta: sol kol başının altında, sağ kol alttan sarar; hafif hafif sallar
			var c = _lap(n, _nt)
			var arms2 = _ik(n, "Left", c - right * 0.17 + Vector3.UP * 0.035 + fd * 0.03)
			arms2.append_array(_ik(n, "Right", c + right * 0.1 - Vector3.UP * 0.02 + fd * 0.05))
			return {"arms": arms2, "fL": HALF, "fR": HALF, "spine": 4.0, "neck": 26.0}
		"rock":   # beşiğin kenarından tutup sallar
			var rim = cradle.global_position + cradle.global_basis * Vector3(-0.27, 0.57, 0.0) if is_instance_valid(cradle) else n.global_position + fd * 0.4 + Vector3.UP * 0.5
			var arms4 = _ik(n, "Right", rim, 8.0)
			arms4.append_array([["LeftUpperArm", Vector3(0.18, -0.85, 0.45)], ["LeftLowerArm", Vector3(-0.1, -0.5, 0.86)]])
			return {"arms": arms4, "fL": HALF, "fR": GRIP, "spine": 8.0, "neck": 14.0}
	return super._make(n, s)


# ------------------------------------------------------------------ doğum (evde, ebeyle)
## Eve girildiğinde doğum yeni olmuştur: eşin futonda yatar, ebe bebeği kucağında tutar
func _birth_setup() -> void:
	var fx = W * 0.5 - 2.35
	sp.global_position = I.L(fx, 0.24, LIE_D)
	_face(sp, LIE_FACE)
	var full: String = CharacterModel.ANIM["getup"]
	sp.model.current = "getup"
	sp.model.anim.play(full, 0.0, -8.0, true)
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(1.16, 0.4, 1.6), Color(0.78, 0.38, 0.48), Vector3.ZERO, 14)
	var m = _mesh(b)
	m.global_position = I.L(fx, 0.27, 2.75)
	blankets.append(m)
	routine = "rest"
	mw = Villager.new()
	mw.role = "nurse"
	mw.interior = true
	mw.display_override = "Ebe"
	mw.lines_override = ["Anne de bebek de çok iyi.", "İlk günler bol bol uyur, merak etmeyin."]
	# görünüş: rolün kendi kıyafeti (hastane hemşiresi)
	I.room.add_child(mw)
	I.npcs.append(mw)
	mw.set_physics_process(false)
	mw.global_position = I.L(fx - 0.15, 0.05, 4.6)
	mw.home = mw.global_position
	mw.goal = mw.global_position
	_look_at(mw, I.L(fx, 0.05, 3.0))
	_pose(mw, "hold", {"anim": "idle", "sit": "seiza"})
	baby_held = mw


func _birth_scene() -> void:
	busy = true
	var pl = Game.player
	_lock(90.0)
	var fx = W * 0.5 - 2.35
	var fem = String(baby_kid.get("gender", "m")) == "f"
	var nm = String(baby_kid["name"]).split(" ")[-1]
	_say(mw, "Tam zamanında! Gözünüz aydın, nur topu gibi bir %s oldu." % ("kızınız" if fem else "oğlunuz"), 4.0)
	await _go(pl, fx - 1.8, 2.0, 2.4)
	# ebe kalkar, bebeği sana uzatır
	_clear_pose(mw)
	_pose(mw, "hold", {"anim": "idle"})
	await _wait(0.5)
	await _go_keep(mw, fx - 1.5, 4.3, 1.0)
	await _go_keep(mw, fx - 1.3, 2.5, 1.0)
	if is_instance_valid(mw):
		_look_at(mw, pl.global_position)
		_look_at(pl, mw.global_position)
		_pose(pl, "reach", {"anim": "idle", "at": _lap(mw, _nt)})
		await _wait(0.8)
	baby_held = pl
	_pose(pl, "hold", {"anim": "idle"})
	if is_instance_valid(mw):
		_clear_pose(mw)
		mw.model.play("idle", 0.3)
	await _wait(0.6)
	Combat.popup_text(_lap(pl, _nt) + Vector3.UP * 0.35, "Ingaa! Ingaa!", Color(1, 0.8, 0.85))
	await _wait(1.6)
	_say(mw, "Annesi de çok iyi. Biraz dinlensin, yeter.", 3.0)
	# eşinin baş ucuna diz çök
	await _go_keep(pl, fx - 1.5, 4.3, 1.0)
	await _go_keep(pl, fx - 0.15, 4.6, 1.0)
	_look_at(pl, I.L(fx, 0.05, 3.0))
	_pose(pl, "hold", {"anim": "idle", "sit": "seiza"})
	await _wait(1.2)
	_say(sp, "Bak... burnu sana benziyor. Adı %s olsun." % nm, 4.0)
	await _wait(1.6)
	Combat.popup_text(_lap(pl, _nt) + Vector3.UP * 0.4, "♥", Color(1, 0.5, 0.65))
	await _wait(2.4)
	_say(sp, "Hadi, beşiğine yatır. Ben biraz uyuyacağım...", 3.5)
	await _wait(1.6)
	_clear_pose(pl)
	_pose(pl, "hold", {"anim": "idle"})
	await _wait(0.6)
	var lc = cradle_pos - I.origin
	await _go_keep(pl, lc.x - 0.74, -lc.z, 1.1)
	_look_at(pl, cradle_pos)
	_pose(pl, "reach", {"anim": "idle", "at": cradle_pos + Vector3(-0.05, 0.5, 0)})
	await _wait(0.6)
	baby_held = null
	rock_after = 9.0
	await _wait(1.0)
	_clear_pose(pl)
	pl.model.play("idle", 0.3)
	# ebe eğilip selam verir, çıkar
	if is_instance_valid(mw):
		_look_at(mw, pl.global_position)
		_pose(mw, "bow", {"anim": "idle", "len": 1.8})
		_say(mw, "Hayırlı olsun. Bir şey olursa hastanedeyim.", 3.0)
		await _wait(1.9)
		_clear_pose(mw)
		await _go(mw, 0.0, 0.7, 1.6)
		if is_instance_valid(mw):
			I.npcs.erase(mw)
			mw.queue_free()
	baby_kid["met"] = true
	newborn = {}
	Journal.add("%s dünyaya geldi." % String(baby_kid["name"]), "milestone")
	if Friends.all().has(sid):
		Friends.add_bond(sid, 5, true)
	_release_player()
	busy = false


# ------------------------------------------------------------------ bekâr evi: baban ve kardeşin akşam sofranın başında
func _folk_spawn() -> void:
	var tb = _table()
	var seats = [[0.0, tb.y + 0.75, PI], [0.0, tb.y - 0.75, 0.0]]
	var i := 0
	for rel in ["baba", "kardeş"]:
		var id = Kin.id_of(rel)
		if not _kin_home(id):
			continue
		var n = Friends.inst()._spawn_npc(id, Game.player.global_position, false)
		if n == null:
			continue
		n.reparent(I.room)
		n.set_physics_process(false)
		n.interior = true
		I.npcs.append(n)
		if rel == "kardeş":
			n.global_position = I.L(-W * 0.5 + 1.2, 0.05, D - 3.05)
			_face(n, 0.0)
		else:
			n.global_position = I.L(seats[i][0], 0.05, seats[i][1])
			_face(n, seats[i][2])
		folk.append(n)
		_pose(n, "rest", {"anim": "idle", "sit": _sit_style(n)})
		i += 1


## Sofraya oturacak iki kişi: önce baban / kardeşin, yer kalırsa çocuklar
func _diners() -> Array:
	var o = []
	for n in folk + kids:
		if is_instance_valid(n) and o.size() < 2:
			o.append(n)
	return o


# ------------------------------------------------------------------ kaçak: gizli gece ziyareti
func _rogue_arrive() -> void:
	var pl = Game.player
	var f: Dictionary = Friends.all().get(sid, {})
	RogueKin.on_visit()
	_clear_pose(sp)
	_look_at(sp, pl.global_position)
	sp.model.play("hit", 0.1, 0.8, true)   # irkilir
	_say(sp, "...! Sen... sen misin?", 2.6)
	await _wait(1.7)
	if not is_instance_valid(sp):
		return
	sp.model.play("idle", 0.3)
	_say(sp, "Çabuk, kapıyı kapat. Devriye az önce geçti.", 3.2)
	await _wait(2.6)
	await _hug_seq(false)
	if not is_instance_valid(sp):
		return
	var s = RogueKin.st()
	if int(s.get("asked", 0)) > int(s.get("told", 0)):
		s["told"] = int(s["asked"])
		_look_at(sp, pl.global_position)
		if s.get("leak", false):
			s["leak"] = false
			_pose(sp, "bow", {"anim": "idle", "len": 4.5})
			_say(sp, "ANBU geldi... Saatlerce sordular. Dayanamadım; gittiğin yönü söyledim. Affet beni.", 5.0)
			await _wait(4.6)
			Friends.add_bond(sid, -4, true)
		else:
			sp.model.play("talk", 0.2)
			_say(sp, "ANBU geldi. Maskeli üç kişi... seni sordular. Tek kelime etmedim.", 4.6)
			await _wait(4.2)
			Friends.add_bond(sid, 3, true)
		_clear_pose(sp)
		sp.model.play("idle", 0.3)
	pr()["home_away"] = 0.0


## Sofraya para kesesi bırakırsın
func _rogue_gift() -> void:
	if busy or not is_instance_valid(sp) or int(pr().get("ryo", 0)) < 500:
		return
	busy = true
	Hud.close_dialog()
	var pl = Game.player
	var tb = _table()
	_lock(30.0)
	await _route(pl, [[-0.95, tb.y - 0.2]])
	_look_at(pl, I.L(0, 0.4, tb.y))
	pl.model.play("pickup", 0.15, 1.0, true)
	await _wait(0.7)
	var b = MB.new()
	b.add("sphere", Vector3(0, 0.06, 0), Vector3(0.2, 0.15, 0.18), Color(0.55, 0.42, 0.22), Vector3.ZERO, 10)
	b.add("cyl", Vector3(0, 0.14, 0), Vector3(0.07, 0.06, 0.07), Color(0.5, 0.38, 0.2), Vector3.ZERO, 8)
	b.add("cyl", Vector3(0, 0.13, 0), Vector3(0.09, 0.015, 0.09), Color(0.75, 0.2, 0.18), Vector3.ZERO, 8)   # bağ
	var pouch = _mesh(b)
	pouch.global_position = I.L(-0.42, 0.44, tb.y - 0.1)
	Sfx.play("coin", pouch.global_position, 0.7)
	Progress.add_ryo(-500)
	RogueKin.on_gift()
	await _wait(1.0)
	pl.model.play("idle", 0.3)
	_look_at(sp, pl.global_position)
	_look_at(pl, sp.global_position)
	_say(sp, ["Buna gerek yoktu... ama sağ ol. Kış zor geçiyor.", "Nereden buldun bunu? ...Sormayayım.", "Kendine de bak. Biz idare ediyoruz."].pick_random(), 3.6)
	await _wait(3.0)
	Friends.add_bond(sid, 3, true)
	_release_player()
	busy = false


## "Benimle gel": eşin (çocuk yoksa) eşyasını toplar, seninle köyü bırakır; annen evinden çıkmaz
func _rogue_take() -> void:
	if busy or not is_instance_valid(sp):
		return
	busy = true
	Hud.close_dialog()
	var pl = Game.player
	var f: Dictionary = Friends.all()[sid]
	_lock(60.0)
	_clear_pose(sp)
	_look_at(sp, pl.global_position)
	_look_at(pl, sp.global_position)
	var has_kids = not (pr().get("children", []) as Array).is_empty()
	if kin_host or has_kids or int(f.get("bond", 0)) < 60:
		sp.model.play("no", 0.2, 1.0, true)
		var why = "Ben bu evden çıkmam, yavrum. Baban da, mezarlarımız da burada. Sen yine gel, yeter."
		if not kin_host and has_kids:
			why = "Çocukları o hayata sürükleyemem. Biz burada bekleyeceğiz... sen sağ kal."
		elif not kin_host:
			why = "Seni seviyorum ama... her şeyi bırakacak kadar emin değilim. Henüz değil."
		_say(sp, why, 5.0)
		await _wait(4.4)
		sp.model.play("idle", 0.3)
		_release_player()
		busy = false
		return
	_say(sp, "...Emin misin? Dönüşü yok bunun.", 3.0)
	await _wait(2.6)
	_say(sp, "Peki. Sen neredeysen evim orası.", 3.2)
	await _wait(2.4)
	# dolaba gider, bohçasını toplar
	await _route(sp, [[-W * 0.5 + 1.25, D - 1.0]])
	_face(sp, PI * 0.5)
	for k in 2:
		sp.model.play("pickup", 0.15, 1.0, true)
		Sfx.play("pickup", sp.global_position, 0.5, 0.8)
		await _wait(1.3)
	var b = MB.new()
	b.add("sphere", Vector3(0, 0.0, 0), Vector3(0.34, 0.26, 0.3), Color(0.35, 0.3, 0.5), Vector3.ZERO, 10)
	b.add("sphere", Vector3(0, 0.15, 0), Vector3(0.1, 0.08, 0.1), Color(0.3, 0.26, 0.44), Vector3.ZERO, 8)
	var sack = _mesh(b)
	tray = sack   # "carry" pozu iki elin arasına oturtur
	_pose(sp, "carry", {"anim": "idle"})
	await _wait(0.5)
	var lp = pl.global_position - I.L(0, 0, 0)
	await _go_keep(sp, lp.x + 0.9, -lp.z, 1.3)
	_look_at(sp, pl.global_position)
	_say(sp, "Hazırım. Son bir kez bakayım... tamam. Gidelim.", 3.6)
	await _wait(3.2)
	await I._fade(1.0, 0.7)
	_clear_pose(sp)
	tray = null
	sack.queue_free()
	f["status"] = "kaçak"
	f["rogue"] = true
	f["party"] = false
	Friends.log_event(f, "Senin için köyünü bıraktı")
	f["news"] = "Sığınak soğuk ama sen buradasın. Yeter."
	Journal.add("%s benimle geldi. Artık o da kaçak." % String(f["name"]), "milestone")
	I.npcs.erase(sp)
	sp.queue_free()
	await _wait(0.8)
	await I._fade(0.0, 0.8)
	Hud.msg("%s gece karanlığında köyden çıktı; sığınağında seni bekliyor." % String(f["name"]).split(" ")[-1], Color(0.8, 0.9, 1.0), 7.0)
	_release_player()
	busy = false
	Game.save_game()
