class_name Villager
extends Fighter
## Köy halkı. Sokak rolleri: walker, kid, chat, patrol, roof, sitter, vendor, shopper, spar, worker, guard, drunk, ball.
## İç mekân rolleri: keeper (dükkâncı), customer, student, teacher, nurse, patient. [F] ile konuşulur.
## Konuşma balonları (Label3D), oyuncuyu rütbesine göre selamlama, çarpınca tepki.

const LINES := {
	"walker": ["Bugün hava çok güzel, değil mi?", "Ichiraku'nun yeni ramen tarifi efsaneymiş!", "Hokage Kulesi'nde yine görev kuyruğu var.",
		"Pazardan taze balık aldım, akşam ızgara yapacağım.", "Son zamanlarda sınırda tuhaf ninjalar görülüyormuş... dikkatli ol.",
		"Kayadaki yüzlere her bakışımda içim ısınıyor."],
	"kid": ["Hey! Sen de akademidensin değil mi? Yarışalım mı?", "Ben büyüyünce Hokage olacağım!", "Kawarimi'yi daha yapamıyorum, hep kütük düşüyor...",
		"Shuriken atmayı öğretir misin? Lütfeeen!", "Saklambaç oynuyoruz, sen ebesin!", "Annem akademiden sonra eve gel dedi ama..."],
	"chat": ["...ve sonra Chunin sınavında rakibini tek hamlede yenmiş!", "Duydun mu? Kumo'dan elçiler gelmiş.", "Fiyatlar yine artmış, bu Ryō nereye gidiyor?",
		"Oğlum Genin oldu, gururluyum!"],
	"vendor": ["Taze sebzeler! Bugün toplandı!", "Kunai, shuriken! Akademi öğrencilerine indirim!", "Dango, sıcacık dango!", "Ninja çantası lazım mı? En sağlamı bende!"],
	"sitter": ["Biraz dinleniyorum... Gençler hep koşturuyor.", "Benim gençliğimde savaş vardı, şimdi barış... kıymetini bilin.", "Bu bankta oturup köyü izlemeyi seviyorum."],
	"patrol": ["Devriyedeyiz. Bir sorun görürsen haber ver.", "Akademi öğrencisi misin? Çok çalış, Ateşin İradesi seninle.", "Kapıdan çıkarken dikkatli ol, ormanlar tehlikeli."],
	"roof": ["Çatılar en hızlı yol! Yakala beni!"],
	"shopper": ["Bu fiyata mı? Biraz indirim yap!", "Şu elmalar ne kadar taze...", "Akşam yemeğine ne alsam?"],
	"spar": ["Bir tur daha! Bu sefer Kawarimi yok!", "Taijutsu'nda açık veriyorsun!", "Antrenman bitmeden eve gitmek yok!"],
	"worker": ["Yeni ev yapıyoruz, ahşap jutsu olsa ne kolay olurdu...", "Kalas dikkat! Kafana düşmesin!", "Bu çatı yarın bitecek."],
	"guard": ["Kapı nöbeti sıkıcı ama önemli.", "Kimlik kontrolü! Şaka şaka, geç bakalım.", "Gece nöbeti uzun sürer."],
	"drunk": ["Hık! Bir şişe sake daha...", "Ben... hık... bir zamanlar Jonin olacaktım!", "Ay iki tane mi? Hık!"],
	"ball": ["Pas ver, pas!", "Gol! Gol!", "Top bende!"],
	"customer": ["Burası köyün en iyisi.", "Hmm, karar veremedim...", "Görevden sonra buraya gelmek gibisi yok."],
	"student": ["Mühürler çok karışık...", "Sensei bugün sınav yapacak mı?", "Teneffüs ne zaman?"],
	"patient": ["Bir görevde yaralandım...", "Tıbbi ninjalar mucize yaratıyor."],
}
const CALLS := {
	"vendor": ["Taze sebze!", "Buyrun, buyrun!", "Sıcak dango!", "Kunai indirimde!", "Taze balık!", "Bugüne özel!"],
	"drunk": ["Hık!", "Sake...", "Lalala~"],
	"ball": ["Pas!", "Benim!", "Gooool!"],
	"spar": ["Hah!", "Hıyaa!", "Tekrar!"],
	"worker": ["Kaldır!", "Dikkat!"],
}

var role := "walker"
var home := Vector3.ZERO
var goal := Vector3.ZERO
var wait := 0.0
var speed := 2.6
var buddy: Node3D = null
var points: Array = []      # sokak noktaları / çatılar / tezgâh önleri (yönetici verir)
var hop_t := -1.0
var hop_from := Vector3.ZERO
var hop_to := Vector3.ZERO
var display := "Köylü"
# yeni davranışlar
var interior := false
var display_override := ""
var lines_override: Array = []
var look_extra := {}         # rol görünümünün üstüne yazılır (Kage cüppesi, ANBU maskesi...)
var eat_mode := false
var floor_sit := false
var wander_r := 0.0
var stand_face := 0.0        # sabit rollerin baktığı yön (radyan)
var fixed_face := false
var going_home := false
var work_anims: Array = []
var work_points: Array = []
var night := false
var anim_t := 0.0
var greet_cd := 0.0
var bump_cd := 0.0
var call_cd := 0.0
var bubble: Label3D
var bubble_t := 0.0
var kick_t := -1.0
var nav := {}               # NpcNav durumu (engelden dolaşma, takılma)
var fading := false


func _ready() -> void:
	team = "neutral"
	var tops := [Color(0.5, 0.6, 0.45), Color(0.6, 0.35, 0.3), Color(0.8, 0.75, 0.55), Color(0.4, 0.45, 0.6), Color(0.7, 0.55, 0.65),
		Color(0.85, 0.85, 0.85), Color(0.55, 0.3, 0.45), Color(0.9, 0.6, 0.3)]
	var t: Color = tops.pick_random()
	var lk = {"gender": ["m", "f"].pick_random(), "top": t, "top2": t.darkened(0.12), "pants": [Color(0.35, 0.3, 0.28), Color(0.2, 0.22, 0.3), Color(0.4, 0.35, 0.25)].pick_random(),
		"band": null, "hair_style": CharacterModel.HAIR_STYLES.keys().filter(func(h): return h != "kel" or randf() < 0.3).pick_random(),
		"hair": [Color(0.1, 0.08, 0.06), Color(0.35, 0.22, 0.12), Color(0.6, 0.6, 0.62), Color(0.75, 0.45, 0.2), Color(0.85, 0.75, 0.4)].pick_random(),
		"sleeves": randf() < 0.6, "pants_style": "sivil", "sandal": Color(0.3, 0.22, 0.15), "skin": [Color(0.96, 0.8, 0.66), Color(0.88, 0.7, 0.55), Color(0.98, 0.86, 0.75)].pick_random()}
	lk["face_mark"] = ["yok", "yok", "yok", "yok", "çil", "burun yarası", "yanak çizgisi"].pick_random()
	var ninja = {"vest": Color(0.38, 0.48, 0.28), "pants_style": "ninja", "top_style": "uzun", "sandal": Color(0.15, 0.2, 0.32), "top": Color(0.18, 0.22, 0.3),
		"top2": Color(0.18, 0.22, 0.3), "pants": Color(0.18, 0.22, 0.3), "band": Color(0.15, 0.22, 0.55), "age": "adult"}
	match role:
		"kid", "ball", "student":
			lk["age"] = "child"
			speed = 6.5
			display = "Çocuk" if role != "student" else "Akademi Öğrencisi"
		"patrol", "roof", "guard":
			lk.merge(ninja, true)
			speed = 4.5 if role != "roof" else 14.0
			display = "Konoha Chunin" if role != "guard" else "Kapı Nöbetçisi"
		"spar":
			lk.merge(ninja, true)
			if randf() < 0.5:
				lk["vest"] = null
				lk["top_style"] = ["ceket", "yakali", "tisort"].pick_random()
				lk["top"] = [Color(0.15, 0.2, 0.33), Color(0.45, 0.15, 0.15), Color(0.2, 0.38, 0.22), Color(0.95, 0.5, 0.12)].pick_random()
				lk["age"] = "teen"
			display = "Antrenman Yapan Ninja"
		"teacher":
			lk.merge(ninja, true)
			display = "Akademi Hocası"
		"sitter":
			lk["hair"] = Color(0.8, 0.8, 0.82)
			lk["age"] = "adult"
			lk["face_mark"] = "kırışık"
			lk["beard"] = randf() < 0.6
			display = "Yaşlı Köylü"
		"vendor", "keeper":
			display = "Satıcı" if role == "vendor" else "Dükkâncı"
			lk["age"] = "adult"
			lk["top_style"] = ["uzun", "tisort"].pick_random()
			lk["beard"] = lk["gender"] == "m" and randf() < 0.3
		"nurse":
			lk.merge({"top": Color(0.96, 0.96, 0.97), "top2": Color(0.96, 0.96, 0.97), "pants": Color(0.9, 0.9, 0.92), "top_style": "uzun", "age": "young"}, true)
			display = "Tıbbi Ninja"
		"worker":
			lk.merge({"top_style": "tisort", "top": Color(0.55, 0.42, 0.3), "pants": Color(0.3, 0.27, 0.24), "age": "adult", "band": Color(0.85, 0.85, 0.85), "band_style": "head"}, true)
			display = "İnşaat İşçisi"
		"drunk":
			lk.merge({"age": "adult", "top": Color(0.6, 0.35, 0.3), "beard": true}, true)
			speed = 1.3
			display = "Sarhoş Adam"
		"shopper":
			lk["age"] = ["adult", "adult", "young"].pick_random()
			display = "Alışverişçi"
		"customer", "patient":
			lk["age"] = ["adult", "young", "teen"].pick_random()
			display = "Müşteri" if role == "customer" else "Hasta"
		_:
			lk["age"] = ["adult", "adult", "young", "teen"].pick_random()
			lk["beard"] = lk["age"] == "adult" and randf() < 0.3
	if display_override != "":
		display = display_override
	# rol kıyafet seti (özel görünüm verilmişse — Kage, ANBU... — dokunma)
	if look_extra.is_empty():
		lk.merge(Outfits.roll(_outfit_arch(), Outfits.village_near()), true)
	lk.merge(look_extra, true)
	look = lk
	super._ready()
	remove_from_group("fighters")
	add_to_group("talkers")
	collision_layer = 4
	if model and look.get("age", "adult") != "adult":
		model.apply_age(look["age"])
		radius *= model.age_scale
		height *= model.age_scale
	goal = global_position
	home = global_position
	greet_cd = randf_range(2.0, 8.0)
	call_cd = randf_range(1.0, 8.0)
	anim_t = randf_range(0.0, 3.0)
	if role in ["guard", "patrol"] and night:
		_hold_lantern()


func _lines() -> Array:
	if not lines_override.is_empty():
		return lines_override
	return LINES.get(role, LINES["walker"])


func talk() -> void:
	if Game.player:
		var to = Game.player.global_position - global_position
		facing = atan2(-to.x, -to.z)
		model.rotation.y = facing
	if role not in ["sitter", "customer", "student", "patient"] and not floor_sit:
		model.play("talk", 0.2)
	wait = 4.0
	Hud.dialog(display, _lines().pick_random(), [])


## Kafanın üstünde kısa konuşma balonu
func say(text: String, dur := 2.6) -> void:
	if bubble == null:
		bubble = Label3D.new()
		bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bubble.font_size = 56
		bubble.pixel_size = 0.0075
		bubble.outline_size = 12
		bubble.modulate = Color(1, 0.97, 0.88)
		bubble.outline_modulate = Color(0.08, 0.06, 0.06)
		add_child(bubble)
	bubble.position = Vector3(0, 2.15 * (model.age_scale if model else 1.0), 0)
	bubble.text = text
	bubble.visible = true
	bubble_t = dur


func _hold_lantern() -> void:
	if model == null:
		return
	var b = MB.new()
	b.add("box", Vector3(0, -0.12, 0), Vector3(0.02, 0.24, 0.02), Color(0.2, 0.15, 0.1))
	b.add("cyl", Vector3(0, -0.42, 0), Vector3(0.22, 0.32, 0.22), Color(1.0, 0.85, 0.55), Vector3.ZERO, 8)
	var m = StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.emission_enabled = true
	m.emission = Color(1.0, 0.7, 0.35)
	m.emission_energy_multiplier = 1.5
	var hb = model.skel.find_bone("RightHand")
	if hb < 0:
		return
	var hp = model.skel.get_bone_global_rest(hb).origin
	var mi = model._mesh_on("RightHand", b.build(m), Transform3D(Basis.IDENTITY, hp + Vector3(-0.06, -0.03, 0.02)))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var l = OmniLight3D.new()
	l.light_color = Color(1.0, 0.72, 0.4)
	l.light_energy = 0.7
	l.omni_range = 5.0
	l.position = Vector3(0, -0.4, 0)
	mi.add_child(l)


## Eve girer gibi kaybol
func vanish() -> void:
	if fading:
		return
	fading = true
	var tw = create_tween()
	tw.tween_property(model, "scale", Vector3(0.05, model.scale.y, 0.05), 0.35)
	tw.tween_callback(queue_free)


func _face(dir: Vector3, dt := 1.0) -> void:
	dir.y = 0
	if dir.length() < 0.01:
		return
	facing = lerp_angle(facing, atan2(-dir.x, -dir.z), minf(1.0, dt * 8.0))
	model.rotation.y = facing


func _hold_face(dt: float) -> void:
	facing = lerp_angle(facing, stand_face, minf(1.0, dt * 4.0))
	model.rotation.y = facing


func _cycle(dt: float, anims: Array, period := 3.5) -> void:
	anim_t -= dt
	if anim_t <= 0.0:
		anim_t = randf_range(period * 0.6, period * 1.4)
		model.play(anims.pick_random(), 0.3, 1.0, true)


func _physics_process(dt: float) -> void:
	if Game.paused or Game.player == null or fading:
		return
	var pl = Game.player
	var dist = global_position.distance_to(pl.global_position)
	if dist > 65.0:
		# uzaktakiler: animasyon ve hareket durur (performans)
		if model.anim.is_playing():
			# durdurmadan önce mevcut kareyi iskelete uygula (yoksa yeni doğan NPC T-pozda kalır)
			model.anim.seek(model.anim.current_animation_position, true)
			model.anim.pause()
		return
	elif not model.anim.is_playing():
		model.anim.play()
	_social(dt, dist)
	match role:
		"roof":
			_roof(dt)
			return
		"vendor", "keeper":
			step_move(Vector3.ZERO, dt, false)
			if dist < 5.0:
				_face(pl.global_position - global_position, dt)
			elif fixed_face:
				_hold_face(dt)
			if wait > 0.0:
				wait -= dt
			else:
				_cycle(dt, ["idle", "talk", "fold", "interact", "idle", "yes"])
			if role == "vendor":
				_call(dt, dist)
			return
		"sitter", "customer", "student", "patient":
			step_move(Vector3.ZERO, dt, false)
			if fixed_face:
				_hold_face(dt)
			if floor_sit:
				model.play("crouch", 0.3)
			elif role == "customer" and not eat_mode:
				_cycle(dt, ["idle", "interact", "talk", "yes", "no", "fold"])
			elif eat_mode or role == "student":
				_cycle(dt, ["sit", "sit", "a/Sitting_Talking"], 4.0)
			else:
				model.play("sit", 0.3)
			return
		"chat":
			step_move(Vector3.ZERO, dt, false)
			if buddy and is_instance_valid(buddy):
				_face(buddy.global_position - global_position, dt)
			model.play("talk" if fmod(Time.get_ticks_msec() * 0.001 + home.z, 6.0) < 3.0 else "idle", 0.3)
			return
		"spar":
			_spar(dt, dist)
			return
		"guard":
			step_move(Vector3.ZERO, dt, false)
			_hold_face(dt)
			if night:
				model.play("b/Idle_Lantern", 0.3)
			else:
				_cycle(dt, ["idle", "fold", "idle"], 6.0)
			return
		"worker":
			_work(dt)
			return
		"shopper":
			_shop(dt)
			return
		"ball":
			_ball(dt)
			return
		"teacher", "nurse":
			_wander_small(dt)
			return
	if wait > 0.0:
		wait -= dt
		step_move(Vector3.ZERO, dt)
		model.play("idle", 0.3)
		return
	var v = goal - global_position
	v.y = 0
	if v.length() < 1.5:
		if going_home:
			vanish()
			return
		_new_goal()
		return
	var mv = NpcNav.steer(self, v.normalized(), dt)
	if role == "drunk":
		var wob = sin(Time.get_ticks_msec() * 0.003 + home.x) * 0.9
		mv = mv.rotated(Vector3.UP, wob)
		_call(dt, dist)
	step_move(mv * speed, dt)
	model.play("run" if speed > 5.0 else "walk", 0.2, 0.75 if role == "drunk" else 1.0)
	if NpcNav.stuck(self, goal, dt):
		_unstick(dist)


func _wander_small(dt: float) -> void:
	if wait > 0.0:
		wait -= dt
		step_move(Vector3.ZERO, dt)
		if role == "teacher":
			_hold_face(dt)
			_cycle(dt, ["talk", "talk", "yes", "interact"], 2.5)
		else:
			model.play("idle", 0.3)
		return
	var tv = goal - global_position
	tv.y = 0
	if tv.length() < 0.5:
		goal = home + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * maxf(1.0, wander_r)
		wait = randf_range(2.5, 6.0)
		return
	step_move(NpcNav.steer(self, tv.normalized(), dt) * 1.2, dt)
	model.play("walk", 0.2)
	if NpcNav.stuck(self, goal, dt):
		goal = home
		wait = randf_range(1.0, 3.0)


## Selamlama + çarpma tepkisi + balon süresi
func _social(dt: float, dist: float) -> void:
	greet_cd -= dt
	bump_cd -= dt
	if bubble and bubble.visible:
		bubble_t -= dt
		if bubble_t <= 0.0:
			bubble.visible = false
	var pl = Game.player
	var pv = Vector2(pl.velocity.x, pl.velocity.z).length()
	if dist < radius + 0.8 and pv > 6.5 and bump_cd <= 0.0 and role != "roof":
		bump_cd = 4.0
		model.play("hit", 0.05, 1.2, true)
		say(["Hey! Dikkat et!", "Ay! Önüne baksana!", "Koşma şurada!", "Ninjalar hep acelede..."].pick_random())
		var away = global_position - pl.global_position
		away.y = 0
		velocity += away.normalized() * 3.0
		wait = maxf(wait, 0.8)
		anim_t = maxf(anim_t, 0.8)
		return
	if dist < 4.5 and greet_cd <= 0.0 and role not in ["roof", "spar", "student"]:
		greet_cd = randf_range(20.0, 40.0)
		if randf() < 0.35:
			say(_greeting())


func _greeting() -> String:
	var rank = int(Game.profile.get("rank", 0))
	var t = Game.world.env.time_of_day if Game.world else 0.5
	var hello = "Günaydın" if t < 0.42 else ("İyi akşamlar" if t > 0.72 else "Merhaba")
	if role in ["kid", "ball"]:
		if rank > 0:
			return ["Vay, gerçek bir ninja!", "Bana bir jutsu göster!", "Alın koruyucun çok havalı!"][randi() % 3]
		return "Sen de akademidesin, değil mi?"
	match rank:
		0:
			return "%s küçük öğrenci, derslerine çalış!" % hello
		1:
			return "%s Genin-san!" % hello
		2:
			return "%s Chunin-san, kolay gelsin." % hello
		3:
			return "Jonin-sama! %s." % hello
	return "...ANBU mu bu? (fısıltı)"


func _call(dt: float, dist: float) -> void:
	call_cd -= dt
	if call_cd <= 0.0:
		call_cd = randf_range(6.0, 13.0)
		if dist < 30.0 and CALLS.has(role):
			say(CALLS[role].pick_random(), 2.0)


func _spar(dt: float, dist: float) -> void:
	step_move(Vector3.ZERO, dt, false)
	if buddy == null or not is_instance_valid(buddy):
		_cycle(dt, ["jab", "cross", "hook", "idle"], 1.2)
		return
	_face(buddy.global_position - global_position, dt)
	if kick_t > 0.0:
		kick_t -= dt
		if kick_t <= 0.0:
			model.overlay.set_pose("kick", 0.0)
	anim_t -= dt
	if anim_t > 0.0:
		return
	anim_t = randf_range(0.7, 1.3)
	var k = randi() % 6
	if k < 4:
		model.play(["jab", "cross", "hook", "slash_a"][k], 0.05, 1.3, true)
		if buddy.has_method("_take_spar"):
			buddy._take_spar()
		if dist < 25.0 and randf() < 0.5:
			Sfx.play("punch", global_position, randf_range(0.9, 1.15), 0.4)
	elif k == 4:
		model.overlay.set_pose("kick", 1.0)
		kick_t = 0.35
	else:
		model.play("block", 0.1, 1.0, true)
	if randf() < 0.15:
		say(CALLS["spar"].pick_random(), 1.2)


func _take_spar() -> void:
	if randf() < 0.5:
		model.play("block", 0.05, 1.2, true)
	else:
		model.play("hit", 0.05, 1.3, true)
	anim_t = maxf(anim_t, 0.4)


func _work(dt: float) -> void:
	if work_points.size() >= 2:
		# taşıyıcı: iki nokta arasında kalas taşır
		if goal.distance_to(work_points[0]) > 0.5 and goal.distance_to(work_points[1]) > 0.5:
			goal = work_points[0]
		var v = goal - global_position
		v.y = 0
		if v.length() < 1.0 and wait <= 0.0:
			goal = work_points[1] if goal.distance_to(work_points[0]) < 0.5 else work_points[0]
			wait = 1.5
		if wait > 0.0:
			wait -= dt
			step_move(Vector3.ZERO, dt)
			model.play("pickup", 0.2)
			return
		step_move(v.normalized() * 1.6, dt)
		model.play("b/Walk_Carry", 0.2)
		return
	step_move(Vector3.ZERO, dt, false)
	_hold_face(dt)
	_cycle(dt, work_anims if not work_anims.is_empty() else ["b/TreeChopping", "a/Fixing_Kneeling"], 2.5)
	_call(dt, global_position.distance_to(Game.player.global_position))


func _shop(dt: float) -> void:
	if wait > 0.0:
		wait -= dt
		step_move(Vector3.ZERO, dt, false)
		_hold_face(dt)
		_cycle(dt, ["talk", "yes", "no", "interact", "idle", "talk"], 2.0)
		if wait <= 0.0:
			_pick_stall()
		elif randf() < dt * 0.04:
			say(LINES["shopper"].pick_random(), 2.2)
		return
	var v = goal - global_position
	v.y = 0
	if v.length() < 0.9:
		wait = randf_range(6.0, 14.0)
		return
	step_move(NpcNav.steer(self, v.normalized(), dt) * 2.4, dt)
	model.play("walk", 0.2)
	if NpcNav.stuck(self, goal, dt):
		if int(nav.get("n", 0)) >= 3 and global_position.distance_to(Game.player.global_position) > 30.0:
			global_position = goal  # görünmezken sıkıştıysa yerine al
			nav["n"] = 0
		else:
			_pick_stall()


func _pick_stall() -> void:
	if points.is_empty():
		return
	var s = points.pick_random()
	if s is Dictionary:
		goal = s["front"] + Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.4, 0.4))
		stand_face = s["face"]
	else:
		goal = s


func _ball(dt: float) -> void:
	var v = goal - global_position
	v.y = 0
	if kick_t > 0.0:
		kick_t -= dt
		step_move(Vector3.ZERO, dt)
		if kick_t <= 0.0:
			model.overlay.set_pose("kick", 0.0)
		return
	if v.length() < 0.6:
		step_move(Vector3.ZERO, dt)
		model.play("idle", 0.2)
		return
	_face(v, dt)
	step_move(v.normalized() * minf(5.5, v.length() * 2.5), dt, false)
	model.play("jog" if v.length() > 1.5 else "walk", 0.15)


func kick_ball() -> void:
	model.overlay.set_pose("kick", 1.0)
	kick_t = 0.3
	if randf() < 0.3:
		say(CALLS["ball"].pick_random(), 1.2)


func _new_goal() -> void:
	match role:
		"kid":
			# kovalamaca: ev noktası etrafında hızlı koşuşturma (düz hattı açık nokta)
			var ks: Array = []
			for k in 4:
				ks.append(home + Vector3(randf_range(-14, 14), 0, randf_range(-14, 14)))
			var kq = NpcNav.pick_clear(self, ks)
			goal = kq if kq != null else home
			wait = randf_range(0.0, 0.6)
			if randf() < 0.15:
				Sfx.play("jump", global_position, 1.5, 0.4)
		"drunk":
			goal = home + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
			wait = randf_range(1.0, 4.0)
			if randf() < 0.3:
				model.play("dance", 0.3)
		_:
			# sokak noktalarından yakın (8-70 m) ve düz hattı açık olanı seç: köyün öbür ucuna,
			# evlerin içinden geçen bir hatta yürüyüp duvara yapışmasın
			var cands: Array = []
			if not points.is_empty():
				for k in 10:
					var q = points.pick_random()
					var qp: Vector3 = q["front"] if q is Dictionary else q
					var dq = qp.distance_to(global_position)
					if dq > 8.0 and dq < 70.0:
						cands.append(qp)
					if cands.size() >= 5:
						break
			var pq = NpcNav.pick_clear(self, cands)
			if pq != null:
				goal = pq
			elif not cands.is_empty():
				goal = cands[0]
			else:
				goal = home
			wait = randf_range(0.5, 6.0) if role == "walker" else randf_range(0.0, 1.0)
	NpcNav.reset(self)


## Takıldı: önce yeni hedef; art arda takılırsa başladığı sokak noktasına dön; görünmezken hâlâ
## sıkışıksa oraya yerleş (duvara yapışık kalmasın)
func _unstick(dist: float) -> void:
	var k = int(nav.get("n", 0))
	if going_home:
		if k >= 2:
			vanish()  # kapıya ulaşamadı: yine de "eve girdi"
		return
	if k >= 4 and dist > 30.0:
		global_position = home
		velocity = Vector3.ZERO
		nav["n"] = 0
		_new_goal()
	elif k >= 2:
		goal = home
		NpcNav.reset(self)
	else:
		_new_goal()


## Çatıdan çatıya sekerek koşan ninja
func _roof(dt: float) -> void:
	if points.size() < 2:
		return
	if hop_t < 0.0:
		var best: Vector3 = points[0]
		var bd = 1e9
		for i in 6:
			var q: Vector3 = points.pick_random()
			var d = q.distance_to(global_position)
			if d > 8.0 and d < 40.0 and d < bd:
				bd = d; best = q
		if bd > 1e8:
			best = points.pick_random()
			global_position = best
			return
		hop_from = global_position
		hop_to = best
		hop_t = 0.0
		var to = hop_to - hop_from
		facing = atan2(-to.x, -to.z)
		model.rotation.y = facing
		model.play("jump", 0.05, 1.4, true)
	var dur = maxf(0.6, hop_from.distance_to(hop_to) / speed)
	hop_t += dt / dur
	var k = clampf(hop_t, 0.0, 1.0)
	var p = hop_from.lerp(hop_to, k)
	p.y += sin(k * PI) * (4.0 + hop_from.distance_to(hop_to) * 0.15)
	global_position = p
	if k > 0.25 and k < 0.9:
		model.play("air", 0.2)
	if hop_t >= 1.0:
		hop_t = -1.0
		model.play("land", 0.05, 1.5, true)
		if randf() < 0.3:
			hop_t = -0.4  # kısa bekleme (negatif sayaç)


## Rolün kıyafet arketipi (Outfits): sokak halkı çeşitli, ninjalar köy üniformalı
func _outfit_arch() -> String:
	match role:
		"kid", "ball":
			return "kid"
		"student":
			return "student"
		"patrol", "roof":
			return "chunin" if randf() < 0.8 else "jonin"
		"guard":
			return "guard"
		"spar":
			return ["genin", "genin", "chunin"].pick_random()
		"teacher":
			return ["chunin", "jonin"].pick_random()
		"sitter":
			return "elder"
		"vendor", "keeper":
			return "merchant"
		"nurse":
			return "medic"
		"worker":
			return "worker"
		"drunk":
			return ["civ", "traveler"].pick_random()
	var r = randf()
	if r < 0.08:
		return "traveler"
	if r < 0.13:
		return "farmer"
	if r < 0.16:
		return "monk"
	if r < 0.2:
		return "merchant"
	if r < 0.23:
		return "noble"
	if r < 0.3 and role in ["walker", "chat"]:
		return ["genin", "chunin"].pick_random()
	return "civ"
