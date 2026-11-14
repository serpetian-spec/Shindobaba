extends Node3D
## Ana akış: yükleme -> ana menü -> karakter yaratma / kayıt yükleme -> oyun.

var world: GameWorld
var player: Player
var menu_cam: Camera3D
var menu_t = 0.0
var mode = "loading"  # loading | menu | creator | game
var loading: Control
var creator_state = {}
var preview: CharacterModel
var preview_yaw = 0.0
var actors: Node3D
var test_script = ""
var void_busy := false
var shot_dir = ""


class Router extends Node:
	var m: Node
	func _unhandled_input(e: InputEvent) -> void:
		m._route(e)


func _ready() -> void:
	var r = Router.new()
	r.m = self
	r.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(r)
	_setup_input()
	_parse_args()
	if test_script.ends_with("test_gdcheck.gd"):   # sözdizimi denetimi: dünya kurulmadan çalışır ve çıkar (tools/gdcheck.py)
		var gdc = Node.new()
		gdc.set_script(load(test_script))
		add_child(gdc)
		return
	_show_loading()
	await get_tree().process_frame
	world = GameWorld.new()
	world.name = "World"
	add_child(world)
	await world.build(func(v, label): _loading_progress(v, label))
	# kıyafet kabuklarını yükleme ekranında hazırla (oyunda ilk NPC'de takılma olmasın)
	_loading_progress(0.98, "Ninjalar giydiriliyor")
	await get_tree().process_frame
	await _warm_characters()
	# jutsu efekt shader/parçacıklarını önceden derle (ilk yayında 50-140 ms takılma olmasın)
	_loading_progress(0.99, "Jutsu efektleri hazırlanıyor")
	await VFX.warmup()
	actors = Node3D.new()
	actors.name = "Actors"
	add_child(actors)
	Spawner.flush(actors)
	var life = preload("res://scripts/world/village_life.gd").new()
	life.name = "VillageLife"
	actors.add_child(life)
	var squad = preload("res://scripts/core/squad.gd").new()
	squad.name = "GeninSquad"
	actors.add_child(squad)
	var pupils = preload("res://scripts/core/pupil_squad.gd").new()
	pupils.name = "PupilSquad"   # jōnin olunca kendi genin takımın
	actors.add_child(pupils)
	var teams = preload("res://scripts/world/ambient_teams.gd").new()
	teams.name = "AmbientTeams"   # çevrede gezen başka ninja takımları
	actors.add_child(teams)
	var friends = preload("res://scripts/core/friends.gd").new()
	friends.name = "Friends"
	actors.add_child(friends)
	var wpeople = preload("res://scripts/core/world_people.gd").new()
	wpeople.name = "WorldPeople"   # dünya nüfusu: kalıcı ninjalar, kendi hayatları, Bingo kaçakları onlardan
	actors.add_child(wpeople)
	var crime = preload("res://scripts/core/crime.gd").new()
	crime.name = "Crime"
	actors.add_child(crime)
	loading.queue_free()
	menu_cam = Camera3D.new()
	menu_cam.far = 5000.0
	add_child(menu_cam)
	menu_cam.current = true
	world.env.attach_post(menu_cam)
	if test_script != "":
		_run_test()
		return
	to_main_menu()
	var upd = Updater.new()   # ana exe: GitHub'da yeni sürüm varsa sorar, indirip kendini günceller
	upd.name = "Updater"
	add_child(upd)
	upd.check()


func _parse_args() -> void:
	# beceri deneme exe'si (ShinobiYolu_SKILLTEST.exe): menüsüz deneme modu
	if OS.get_executable_path().get_file().to_upper().contains("SKILLTEST") or "--sandbox" in OS.get_cmdline_user_args():
		test_script = "res://scripts/core/sandbox.gd"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--test="):
			test_script = a.substr(7)
			# test pencereleri ekranda görünür (kullanıcı izleyebilsin) ama odağı çalmaz
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		elif a.begins_with("--shots="):
			shot_dir = a.substr(8)


# ------------------------------------------------------------------ tuşlar
func _setup_input() -> void:
	# menüler kendi kendine aşağı kayıyordu: kaymış bir gamepad çubuğu / eksen sürekli ui_down gönderiyor.
	# Menü odak gezintisinden analog eksenleri çıkar (ok tuşları ve d-pad kalır)
	for ua in ["ui_up", "ui_down", "ui_left", "ui_right", "ui_focus_next", "ui_focus_prev"]:
		if InputMap.has_action(ua):
			for ev in InputMap.action_get_events(ua):
				if ev is InputEventJoypadMotion:
					InputMap.action_erase_event(ua, ev)
	var keys = {
		"forward": [KEY_W], "back": [KEY_S], "left": [KEY_A], "right": [KEY_D],
		"jump": [KEY_SPACE], "leap": [KEY_CTRL], "dash": [KEY_SHIFT], "substitute": [KEY_Q], "charge": [KEY_C],
		"throw": [KEY_R], "tool_next": [KEY_T], "interact": [KEY_F], "lock": [KEY_E], "menu": [KEY_TAB], "salve": [KEY_H], "pill": [KEY_Y],
		"slot1": [KEY_1], "slot2": [KEY_2], "slot3": [KEY_3], "slot4": [KEY_4], "slot5": [KEY_5], "slot6": [KEY_6], "slot7": [KEY_7], "slot8": [KEY_8], "slot9": [KEY_9],
		"inventory": [KEY_I], "skills": [KEY_K], "map": [KEY_M], "pause": [KEY_ESCAPE], "dojutsu": [KEY_V],
		"walk": [KEY_CAPSLOCK], "sage": [KEY_Z], "beast": [KEY_X], "gates": [KEY_B], "seal_mode": [KEY_G], "weapon_draw": [KEY_N], "summon_cmd": [KEY_J], "summon_special": [KEY_U], "pill_next": [KEY_O], "track_next": [KEY_L],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in keys[action]:
			var ev = InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	for pair in [["attack", MOUSE_BUTTON_LEFT], ["guard", MOUSE_BUTTON_RIGHT], ["lock", MOUSE_BUTTON_MIDDLE]]:
		if not InputMap.has_action(pair[0]):
			InputMap.add_action(pair[0])
		var mb = InputEventMouseButton.new()
		mb.button_index = pair[1]
		InputMap.action_add_event(pair[0], mb)


# ------------------------------------------------------------------ yükleme
func _show_loading() -> void:
	loading = ColorRect.new()
	loading.color = Color(0.04, 0.03, 0.05)
	loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	Hud.root.add_child(loading)
	var t = UI.label("SHINOBI YOLU", 72, UI.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	t.set_anchors_preset(Control.PRESET_CENTER)
	t.position = Vector2(-400, -120)
	t.size = Vector2(800, 100)
	loading.add_child(t)
	var l = UI.label("Dünya yükleniyor...", 22, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER)
	l.name = "L"
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.position = Vector2(-400, 0)
	l.size = Vector2(800, 40)
	loading.add_child(l)
	var b = UI.bar(UI.ACCENT, 600, 12)
	b.name = "B"
	b.set_anchors_preset(Control.PRESET_CENTER)
	b.position = Vector2(-300, 50)
	b.max_value = 1.0
	loading.add_child(b)


func _loading_progress(v: float, label: String) -> void:
	if loading:
		(loading.get_node("L") as Label).text = label + "..."
		(loading.get_node("B") as ProgressBar).value = v


func _spawn_villagers() -> void:
	for i in 40:
		var vg = Villager.new()
		actors.add_child(vg)
		var v = Game.village("konoha")
		vg.global_position = Game.from_map(Vector2(v["x"] + randf_range(-300, 300), v["y"] + randf_range(-320, 200)))
		vg.home = vg.global_position


# ------------------------------------------------------------------ menü
func to_main_menu() -> void:
	if player:
		Game.save_game()
		Buffs.reset()
		player.queue_free()
		player = null
		Game.player = null
	if preview:
		preview.queue_free()
		preview = null
	mode = "menu"
	if Interiors.inst:
		Interiors.inst.hide_room()
	menu_cam.fov = 75.0
	menu_cam.h_offset = 0.0
	Game.paused = false
	get_tree().paused = false
	Hud.show_game_hud(false)
	menu_cam.current = true
	world.env.attach_post(menu_cam)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Menus.main_menu(self)
	Sfx.music("muz_menu")


func back_to_menu() -> void:
	if preview:
		preview.queue_free()
		preview = null
	to_main_menu()


func start_creator(slot: int) -> void:
	mode = "creator"
	creator_state = {"slot": slot, "name": "", "gender": "m", "clan": "none", "soy": "", "element": "katon", "village": "konoha", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "top2": Color(0.15, 0.15, 0.17), "pants": Color(0.15, 0.15, 0.17),
		"top_style": "ceket", "pants_style": "ninja",
		"skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	_update_preview()
	Menus.creator(self, creator_state, _update_preview, _start_new_game)


func _creator_look() -> Dictionary:
	var s = creator_state
	var eye: Color = s["eye"]
	if Data.clans.has(s["clan"]) and s["clan"] in ["uchiha", "hyuga", "aburame", "otsutsuki"]:
		var e: Array = Data.clans[s["clan"]]["eye"]
		eye = Color(e[0], e[1], e[2])
	var L = {"gender": s["gender"], "hair_style": s["hair_style"], "hair": s["hair"], "skin": s["skin"], "eye": eye, "band": null, "age": "child", "village": s.get("village", "konoha"),
		"start_set": s.get("start_set", "set_genin")}
	Gear.preview_set_look(L, String(L["start_set"]))   # seçilen set önizlemede giyili
	L["top"] = s["top"]   # üst rengi: setin üst giysisi
	L["pants"] = s.get("pants", L.get("pants", Color(0.15, 0.15, 0.17)))   # alt rengi: pantolon
	L["face_id"] = int(s.get("face_base", 0))
	L["face_cut"] = 0
	L["eye_art"] = maxi(0, CharacterModel.eye_art_names().find(String(s.get("eye_art", "Yuvarlak"))))
	L["face_v"] = CharacterModel.face_from_parts(String(s.get("face_eye", "Sade")), String(s.get("face_brow", "Sade")), String(s.get("face_head", "Sade")),
		String(s.get("face_iris", "Normal")), String(s.get("face_mouth", "Normal")))
	L["face_paint"] = String(s.get("face_paint", CharacterModel.CLAN_FACE_PAINT.get(String(s["clan"]), "yok")))
	L["face_paint_col"] = CharacterModel.FACE_PAINT_COLORS.get(String(s.get("face_paint_col_name", "Doğal")), Color(0, 0, 0, 0))
	return L


func _update_preview() -> void:
	if preview:
		preview.queue_free()
	preview = CharacterModel.new()
	add_child(preview)
	var cl = _creator_look()
	cl["own_hair"] = true
	preview.setup(cl)
	# arka plan: seçilen köyün renklerinde shinobi evi (gökte kurulan oda)
	var base: Vector3
	if Interiors.inst:
		base = Interiors.inst.show_room(String(creator_state.get("village", "konoha")))
	else:
		var v = Game.village("konoha")
		base = Game.from_map(Vector2(v["x"] - 120, v["y"] + 175 - 32))
	preview.global_position = base
	preview.rotation.y = PI + preview_yaw   # kameraya (kapı yönüne) bakar
	preview.play("idle")
	_frame_creator_cam(true)


## Yaratıcı kamerası: karakter sol paneli değil ekranın sağ boş alanını ortalar; Görünüm sekmesinde yüze yaklaşır
func _frame_creator_cam(snap := false) -> void:
	if preview == null:
		return
	# yaratıcıda kamera hep menü kamerası (oyundan menüye dönünce başka kamera etkin kalıp karakter görünmüyordu)
	if not menu_cam.current:
		menu_cam.current = true
		if world and world.env:
			world.env.attach_post(menu_cam)
	var base = preview.global_position
	var close = Menus._ctab == "gorunum"
	var dist = 2.3 if close else 3.7
	var h = 1.12 if close else 0.78
	menu_cam.fov = 38.0
	var vp = get_viewport().get_visible_rect().size
	var aspect = vp.x / maxf(vp.y, 1.0)
	# panelin sağındaki alanın ortası ~ekranın %66'sı: kamerayı yana kaydır (h_offset), karakter sağa geçer
	var half_w = dist * tan(deg_to_rad(menu_cam.fov * 0.5)) * aspect
	var to = Transform3D(Basis.IDENTITY, base + Vector3(0, h + 0.08, dist)).looking_at(base + Vector3(0, h, 0), Vector3.UP)
	var hoff = -half_w * 0.36
	if snap:
		menu_cam.global_transform = to
		menu_cam.h_offset = hoff
		return
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(menu_cam, "global_transform", to, 0.35)
	tw.tween_property(menu_cam, "h_offset", hoff, 0.35)


func _start_new_game() -> void:
	var s = creator_state
	if String(s["name"]).strip_edges() == "":
		s["name"] = ["Kaito", "Hiro", "Ren", "Sora", "Aki", "Yuki"].pick_random()
	Game.profile = Progress.new_profile({"slot": s["slot"], "name": s["name"], "gender": s["gender"], "clan": s["clan"], "soy": s.get("soy", "") if s["clan"] == "none" else "",
		"element": s["element"], "look": _creator_look(), "village": s.get("village", "konoha")})
	Game.profile["pos"] = null
	Buffs.reset()
	Progress.refresh_story()
	_begin_game(Progress.home_spawn())
	var vname = String(Game.village(Progress.home()).get("name", "Konoha"))
	Hud.banner(vname.to_upper(), "Akademi öğrencisi %s'nin hikâyesi başlıyor" % s["name"], UI.ACCENT)


func load_slot(slot: int) -> void:
	if not Game.load_game(slot):
		return
	Journal.migrate(Game.profile)   # eski kayıtlardaki Naruto hikâye adımları -> serbest oyun
	var pos = Game.profile.get("pos")
	var p: Vector3
	if pos != null:
		p = Vector3(pos[0], pos[1], pos[2])
	else:
		p = Progress.home_spawn()
	world.env.time_of_day = float(Game.profile.get("time", 0.35))
	_begin_game(p)


var perf_panel: Control


## Oyuncunun kendi görünüşü (saç, kıyafet) açılışta bir kez gizlice kurulur: klon / kılık teknikleri ilk atışta gövdeyi sıfırdan hesaplamaz
func _prewarm_player_look() -> void:
	if player == null or player.model == null:
		return
	var m = CharacterModel.new()
	m.visible = false
	add_child(m)
	m.setup(player.model.look.duplicate())
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(m):
		m.queue_free()


func _make_perf_panel() -> void:
	var cl = CanvasLayer.new()
	cl.layer = 120
	add_child(cl)
	perf_panel = preload("res://scripts/ui/perf_panel.gd").new()
	cl.add_child(perf_panel)


func _begin_game(pos: Vector3) -> void:
	get_tree().create_timer(2.5).timeout.connect(_prewarm_player_look)
	if perf_panel == null:
		_make_perf_panel()   # gizliyken de toplar: oturum grafiği baştan dolar
	if preview:
		preview.queue_free()
		preview = null
	if Interiors.inst:
		Interiors.inst.hide_room()
	Menus.clear()
	# doğuştan gelenler (kan soyu / klan doğası, klan teknikleri) ilk andan uyanık; kanının dövüş tarzı da kendiliğinden seçili gelir
	Progress.clan_unlocks(false)
	if not Game.profile.has("fight_style"):
		var fs: Array = FightingStyles.available(Game.profile)
		Game.profile["fight_style"] = String(fs[1]) if fs.size() > 1 else ""
	# JSON'dan gelen renkleri Color'a çevir
	var look: Dictionary = Game.profile["look"]
	for k in look.keys():
		if look[k] is String and String(look[k]).begins_with("("):
			look[k] = str_to_var("Color" + look[k])
	# eski kayıtlar: yüz boyası alanı yoksa klanın kanon boyası (Inuzuka dişleri vb.)
	if not look.has("face_paint"):
		look["face_paint"] = CharacterModel.CLAN_FACE_PAINT.get(String(Game.profile.get("clan", "none")), "yok")
	# eski kayıtlar: köy/itibar alanları yoksa Konoha
	if not Game.profile.has("village"):
		Game.profile["village"] = "konoha"
	if not Game.profile.has("rep"):
		Game.profile["rep"] = {}
	# kaldırılan klanlar (Bakuha -> Patlayıcı Kil Yolu; uydurma Ikazuchi/Kakō -> klansız kan soyu, Hōki -> Kök: Mürekkep Yolu,
	# Iwao/Kazahana/Kaminarimon -> köy eğitmeni): eski kayıt klansız devam eder, öğrenilmiş teknikler kalır
	var old_clan = String(Game.profile.get("clan", "none"))
	if not Data.clans.has(old_clan):
		Game.profile["clan"] = "none"
		var to_soy = {"ikazuchi": "ranton", "kako": "yoton"}
		if to_soy.has(old_clan) and String(Game.profile.get("soy", "")) == "":
			Game.profile["soy"] = to_soy[old_clan]
	look["village"] = Game.profile["village"]
	Progress.refresh_story()
	Missions._story_cache.clear()
	# eski kayıtlar 4 slotluydu: 6'ya tamamla
	var sl: Array = Game.profile.get("slots", [])
	while sl.size() < 9:
		sl.append("")
	Game.profile["slots"] = sl
	Gear.ensure(Game.profile)
	ClanMech.ensure(Game.profile)
	Progress.ensure_rank_outfit()   # terfi edip rütbe kıyafeti almamış eski kayıtlar
	Progress.clan_starter_kit(Game.profile)   # eski Shiranui kayıtlarına bir kez senbon
	Gear.apply_look(Game.profile)
	player = Player.new()
	add_child(player)
	player.global_position = pos
	var pc = PlayerCombat.new()
	player.add_child(pc)
	player.apply_profile_stats()
	player.hp = player.max_hp
	player.chakra = player.max_chakra
	world.env.attach_post(player.cam)
	mode = "game"
	Hud.show_game_hud(true)
	Hud.objective_changed()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Sfx.music("muz_koy")
	if not Game.profile.get("active_mission", {}).is_empty():
		var m: Dictionary = Game.profile["active_mission"]
		if m.get("type", "") != "story":
			Missions._setup(m)


# ------------------------------------------------------------------ oyun içi
func _route(e: InputEvent) -> void:
	if mode == "creator" and e is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		preview_yaw += e.relative.x * 0.01
		if preview:
			preview.rotation.y = PI + preview_yaw   # kurulumla aynı (klan/saç değişince model ters dönüyordu)
	if mode != "game":
		return
	if e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_F3, KEY_F4, KEY_F5]:   # performans paneli
		if perf_panel == null:
			_make_perf_panel()
		match e.keycode:
			KEY_F3: perf_panel.toggle()
			KEY_F4: perf_panel.next_test()
			KEY_F5: perf_panel.toggle_vsync()
		return
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_F8 and player != null and not void_busy:   # siyah leke teşhisi (oyuncu raporu)
		void_busy = true
		await preload("res://scripts/core/void_check.gd").run(self)
		void_busy = false
		return
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_F9 and player != null:   # görünmez yapı teşhisi (oyuncu raporu)
		preload("res://scripts/core/inv_check.gd").run(get_tree(), player.global_position)
		return
	if e.is_action_pressed("pause"):
		if Hud.dialog_open() and not Game.paused:
			Hud.close_dialog()
		elif Game.paused:
			resume()
		else:
			_pause()
			Menus.pause(self)
		return
	if Game.ui_open and not Game.paused:
		return
	if e.is_action_pressed("menu"):   # son açık bırakılan sekmeden devam
		_toggle_panel(func(): Menus.ninja_menu(self, Menus.last_tab()))
	elif e.is_action_pressed("inventory"):
		_toggle_panel(func(): Menus.ninja_menu(self, Menus.last_tab()))
	elif e.is_action_pressed("skills"):
		_toggle_panel(func(): Menus.ninja_menu(self, "jutsu"))
	elif e.is_action_pressed("map"):
		_toggle_panel(func(): Menus.region_map(self))
	elif e.is_action_pressed("track_next") and not Game.paused:
		Missions.cycle_track()   # harita işaretçisi: görev / dost / aranan / hedef arasında geç
	elif Game.paused:
		return
	elif e.is_action_pressed("interact"):
		var it = Interact.nearest(player.global_position)
		# önce yerdeki dōjutsu sahibinin gözleri (yakındaki etkileşimler F'yi yutuyordu)
		var ey = player.combat.modes.eyes if player.combat and player.combat.modes else null
		# görevin konuşulacak kişisi yakındaysa önce o (kapı/görev masası alanının içinde duruyorsa F onu yutuyordu)
		var qn = Missions.talk_target_near(player.global_position, 4.0)
		if ey and ey.steal_target != null and is_instance_valid(ey.steal_target):
			ey._steal(ey.steal_target)
		elif ey and ey.cell_target != null and is_instance_valid(ey.cell_target):
			ey._take_cells(ey.cell_target)
		elif qn != null:
			qn.talk()
		elif not it.is_empty():
			# hizmet bir kişiye bağlıysa: o kişi sana döner ve konuşur (masayla konuşmak yok)
			var who = it.get("npc")
			if who != null and is_instance_valid(who):
				Hud.forced_speaker = who   # konuşma kamerası bu kişiye (yakındaki başka birine/oyuncuya değil)
				var to: Vector3 = player.global_position - who.global_position
				who.facing = atan2(-to.x, -to.z)
				who.wait = 4.0
				if who.model:
					who.model.rotation.y = who.facing
					who.model.play("talk", 0.2)
				var back: Vector3 = who.global_position - player.global_position
				player.facing = atan2(-back.x, -back.z)
			Progress.interact(it)
		else:
			var c = Hud._near_catchable(player)
			if c:
				c.catch()
			else:
				var tk = Hud._near_talker(player)
				if tk:
					tk.talk()
	elif e.is_action_pressed("tool_next"):
		var tools = ["kunai", "shuriken", "senbon", "tag", "makibishi", "smoke"]
		var i = tools.find(Game.profile.get("throw_sel", "kunai"))
		for k in tools.size():
			i = (i + 1) % tools.size()
			if int(Game.profile["inventory"].get(tools[i], 0)) > 0:   # sahip olunan (bir kez alınmış) aletler
				break
		Game.profile["throw_sel"] = tools[i]
	elif e.is_action_pressed("salve"):
		use_item("salve")
	elif e.is_action_pressed("pill"):
		use_item("pill")
	elif e.is_action_pressed("pill_next"):
		ClanMech.next_pill()


func _toggle_panel(open: Callable) -> void:
	if Game.paused:
		resume()
	else:
		_pause()
		open.call()


func _pause() -> void:
	Game.paused = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func resume() -> void:
	Menus.clear()
	Game.paused = false
	Game.ui_open = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


const PILL_CD := 60.0   # asker hapı bekleme süresi (sn)


## Asker hapının kalan bekleme süresi (0 = hazır)
func pill_cooldown() -> float:
	var at = float(Game.profile.get("pill_ready_at", 0.0))
	var now = Time.get_ticks_msec() / 1000.0
	if at - now > PILL_CD + 1.0:
		Game.profile["pill_ready_at"] = 0.0   # oyun yeniden açıldı (saat sıfırlandı): kayıttaki eski süre geçersiz
		return 0.0
	return maxf(0.0, at - now)


const SALVE_CD := 300.0   # kullanıcı: 5 dk (2 dk çok çabuk geliyordu)
## Merhem de bitmez: bekleme süresiyle (asker hapı gibi)
func salve_cooldown() -> float:
	var at = float(Game.profile.get("salve_ready_at", 0.0))
	var now = Time.get_ticks_msec() / 1000.0
	if at - now > SALVE_CD + 1.0:
		Game.profile["salve_ready_at"] = 0.0
		return 0.0
	return maxf(0.0, at - now)


func use_item(id: String) -> void:
	if id == "salve":
		var sl = salve_cooldown()
		if sl > 0.0:
			Hud.msg("Merhem için %d sn bekle." % ceili(sl), Color(0.6, 1.0, 0.65))
			return
		Game.profile["salve_ready_at"] = Time.get_ticks_msec() / 1000.0 + SALVE_CD
		player.hp = minf(player.max_hp, player.hp + maxf(50.0, player.max_hp * 0.35) * (1.0 + Stats.skill(Game.profile, "heal")))
		FX.aura(player, Color(0.5, 1, 0.6), 0.8)
		Sfx.play("heal", player.global_position)
		return
	if id == "pill" and ClanMech.use_aki_pill():   # Akimichi: sıradaki renkli hap
		return
	var inv: Dictionary = Game.profile["inventory"]
	if id == "pill":
		# asker hapı bitmez: bekleme süresiyle kullanılır
		var left = pill_cooldown()
		if left > 0.0:
			Hud.msg("Asker hapı için %d sn bekle." % ceili(left), Color(1, 0.75, 0.45))
			return
		Game.profile["pill_ready_at"] = Time.get_ticks_msec() / 1000.0 + PILL_CD
		player.chakra = minf(player.max_chakra, player.chakra + maxf(60.0, player.max_chakra * 0.35))
		Buffs.add("pill", 20.0, {"melee": 1.15})
		if String(Game.profile.get("clan", "")) == "akimichi":
			# asker hapı (Hyōrōgan) sıkıştırılmış besin: Akimichi kalorisinin yarısını doldurur
			Game.profile["kalori"] = minf(ClanMech.KALORI_MAX, float(Game.profile.get("kalori", ClanMech.KALORI_MAX)) + ClanMech.KALORI_MAX * 0.5)
			Hud.msg("Asker hapı: kalori doldu (+%%%d)." % 50, Color(1.0, 0.65, 0.25))
		FX.aura(player, Color(1, 0.7, 0.3), 0.8)
		Sfx.play("heal", player.global_position, 0.8)
		return
	if int(inv.get(id, 0)) <= 0:
		Hud.msg("Hiç %s yok." % Data.items.get(id, {"name": id})["name"], Color(1, 0.6, 0.5))
		return
	inv[id] = int(inv[id]) - 1
	match id:
		"salve":
			# sabit +50 yüksek seviyede canın %10'u bile değildi: azami canın %35'i (en az 50)
			player.hp = minf(player.max_hp, player.hp + maxf(50.0, player.max_hp * 0.35) * (1.0 + Stats.skill(Game.profile, "heal")))
			FX.aura(player, Color(0.5, 1, 0.6), 0.8)
			Sfx.play("heal", player.global_position)
		"pill":
			player.chakra = minf(player.max_chakra, player.chakra + maxf(60.0, player.max_chakra * 0.35))
			Buffs.add("pill", 20.0, {"melee": 1.15})
			FX.aura(player, Color(1, 0.7, 0.3), 0.8)
			Sfx.play("heal", player.global_position, 0.8)


## Haritadaki bir bölgeye / yere ışınlanma (ülke merkezi, önemli yer): açık zemine iner
func travel_to_map(mx: float, my: float, name: String) -> void:
	resume()
	FX.smoke_puff(player.global_position + Vector3.UP, 1.0, 14)
	var q = Missions.open_ground(Game.from_map(Vector2(mx, my)), 80.0)
	q.y = Game.ground_height(q.x, q.z)
	player.respawn(q + Vector3.UP * 0.5)
	Hud.banner(name, "Işınlanma", Color(0.8, 0.95, 1.0))


func fast_travel(vid: String) -> void:
	var v = Game.village(vid)
	resume()
	FX.smoke_puff(player.global_position + Vector3.UP, 1.0, 14)
	# yükleme ekranı: köy kurulurken büyük kare bütçesi (oyun dururken hızlı kurulur), bitince oyuncu yerleşir
	var vs = world.get_node_or_null("VillageStream") if world else null
	if vs == null:
		for ch in world.find_children("VillageStream", "", true, false):
			vs = ch
	var rec: Dictionary = vs.request(vid) if vs and vid != "konoha" else {"done": true}
	if not rec.get("done", true):
		_show_loading()
		(loading.get_node("L") as Label).text = "%s yükleniyor..." % v["name"]
		get_tree().paused = false
		player.set_physics_process(false)
		BuildSites.budget_ms = 120.0
		var t0 = Time.get_ticks_msec()
		while not rec.get("done", false) and Time.get_ticks_msec() - t0 < 90000:
			_loading_progress(clampf((Time.get_ticks_msec() - t0) / 15000.0, 0.05, 0.95), "%s kuruluyor" % v["name"])
			await get_tree().process_frame
		BuildSites.budget_ms = 8.0
		player.set_physics_process(true)
		loading.queue_free()
		loading = null
	player.respawn(Missions.open_ground(Game.from_map(Vector2(v["x"], v["y"] - float(v["r"]) * 0.5)), 60.0) + Vector3.UP * 0.5)   # binaların arasına sıkışmasın
	Hud.banner(v["name"], "Hızlı seyahat", Color(0.8, 0.95, 1.0))


var _vram_t := -100.0


## Loga dakikada bir ekran belleği satırı (çöküş loglarında "kart doldu mu, ne zaman" görülsün)
var _fps_n := 0
var _fps_t := 0.0
var _fps_worst := 0.0
var _census_k := 0


var _census := {}
var _census_stack: Array = []
var _census_line := ""


func _census_step() -> void:
	var budget = 1500
	while budget > 0 and not _census_stack.is_empty():
		var nd = _census_stack.pop_back()
		if not is_instance_valid(nd):
			continue
		budget -= 1
		var key = nd.get_class()
		if nd.get_script() != null:
			key = String(nd.get_script().resource_path).get_file()
		_census[key] = int(_census.get(key, 0)) + 1
		if not (nd is StaticBody3D):   # çarpışma gövdelerinin içi sayılmaz (sabit, çok kalabalık)
			_census_stack.append_array(nd.get_children(true))
	if _census_stack.is_empty():
		var top := []
		for key in _census:
			if not (key in ["CollisionShape3D", "MultiMeshInstance3D", "StaticBody3D"]):
				top.append([_census[key], key])
		top.sort_custom(func(x, y): return x[0] > y[0])
		for e in top.slice(0, 28):
			_census_line += " | %s %d" % [e[1], e[0]]
		print(_census_line)
		_census = {}


func _vram_log(dt: float) -> void:
	if not _census_stack.is_empty():
		_census_step()
	_fps_n += 1
	_fps_t += dt
	_fps_worst = maxf(_fps_worst, dt)
	_vram_t -= dt
	if _vram_t > 0.0:
		return
	if _fps_t > 5.0 and mode == "game" and player:
		# kare hızı + nerede (köy / biyom) + ayar: "nerede kasıyor" loglardan okunsun
		var pp = player.global_position
		var vid = WorldDay.village_of(pp)
		var where = vid if vid != "" else ("biyom %d" % int(Game.biome_at(pp.x, pp.z)))
		if Interiors.inst and Interiors.inst.inside != "":
			where = "iç mekân " + String(Interiors.inst.inside)
		var ws = get_window().size
		print("FPS %d dk: ort %.0f, en uzun kare %.0f ms | %s | kalite %d, görüş %.2f | %dx%d" % [int(Time.get_ticks_msec() / 60000.0), _fps_n / _fps_t, _fps_worst * 1000.0, where,
			int(Game.settings.get("quality", 2)), float(Game.settings.get("view", 1.0)), ws.x, ws.y])
		# sızıntı izi: sahnedeki düğüm sayısı her dakika; 5 dakikada bir en kalabalık türler (uzun oturumda neyin biriktiği loglardan okunsun)
		var line = "SAYIM dugum %d | nesne %d | kaynak %d | yetim %d | bellek %d MB" % [int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_COUNT)),
			int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)]
		_census_k += 1
		if _census_k % 5 == 1 and _census_stack.is_empty():
			_census_line = line
			_census = {}
			_census_stack = [get_tree().root]   # sayım _census_step ile karelere yayılır (tek karede 190 bin düğüm gezmek takılma yapıyordu)
		else:
			print(line)
	_fps_n = 0
	_fps_t = 0.0
	_fps_worst = 0.0
	var first = _vram_t < -50.0
	_vram_t = 60.0 if not first else 20.0
	var mb = 1048576.0
	if first:
		print("Sürüm %s (%s) | %s" % [Game.version, Game.build_tag, RenderingServer.get_video_adapter_name()])
	print("VRAM %d dk: toplam %.0f MB, doku %.0f, tampon %.0f" % [int(Time.get_ticks_msec() / 60000.0),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / mb,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / mb,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED) / mb])


func _process(dt: float) -> void:
	_vram_log(dt)
	if mode == "menu" and menu_cam:
		menu_t += dt * 0.05
		var v = Game.village("konoha")
		var c = Game.from_map(Vector2(v["x"], v["y"] + 120))
		menu_cam.global_position = c + Vector3(cos(menu_t) * 320.0, 110.0, sin(menu_t) * 320.0)
		menu_cam.look_at(c + Vector3(0, 30, 0), Vector3.UP)
	if mode == "game" and player and Engine.get_process_frames() % 30 == 0:
		# bölgeye göre müzik
		var near_enemy = Combat.nearest_enemy(player, 25.0) != null
		var night: bool = world.env.time_of_day < 0.24 or world.env.time_of_day > 0.78
		if Hud.boss and is_instance_valid(Hud.boss):
			Sfx.music("muz_boss")
		elif near_enemy:
			Sfx.music("muz_savas")
		elif night:
			Sfx.music("muz_gece")
		else:
			Sfx.music("muz_koy")
	if mode == "game" and Engine.get_process_frames() % 3600 == 0:
		Game.save_game()


# ------------------------------------------------------------------ otomatik test (geliştirici)
func _run_test() -> void:
	var script: GDScript = load(test_script) if test_script.begins_with("res://") else null
	if script == null:
		var f = FileAccess.open(test_script, FileAccess.READ)
		script = GDScript.new()
		script.source_code = f.get_as_text()
		script.reload()
	var t: Node = script.new()
	t.set("main", self)
	add_child(t)


func shot(name: String) -> void:
	if shot_dir == "":
		return
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	img.save_png(shot_dir.path_join(name + ".png"))


## Karakter shader/malzeme ısıtması: çeşitli görünümler (saç maskesi, alın koruyucu, başlık, yüz kabuğu, sallanan
## parçalar, etekli giysi) gizli bir alt görüş alanında birkaç kare ÇİZİLİR -> oyunda ilk görüldüklerinde derleme takılması olmaz
func _warm_characters() -> void:
	var W = Vector3(0, 2400, 0)
	var sv = SubViewport.new()
	sv.size = Vector2i(320, 180)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.world_3d = get_viewport().world_3d
	add_child(sv)
	var cam = Camera3D.new()
	sv.add_child(cam)
	cam.global_position = W + Vector3(0, 1.4, 9)
	cam.look_at(W + Vector3(0, 1.2, 0))
	cam.current = true
	var looks = [
		{"gender": "m", "vest": Color(0.38, 0.48, 0.28), "band": Color(0.15, 0.2, 0.45), "band_style": "head", "hair_style": "uzun", "outer_style": "pelerin", "outer": Color(0.5, 0.4, 0.3)},
		{"gender": "f", "hair_style": "atkuyruğu", "band": Color(0.15, 0.2, 0.45), "band_style": "neck", "face_style": "cloth", "facegear": Color(0.2, 0.2, 0.24)},
		{"gender": "m", "hair_style": "diken", "head_style": "kapuson", "headgear": Color(0.3, 0.3, 0.3), "face_style": "mempo", "facegear": Color(0.2, 0.2, 0.2), "outer_style": "palto", "outer": Color(0.4, 0.4, 0.5)},
		{"gender": "f", "hair_style": "yele", "head_style": "kabuto", "headgear": Color(0.3, 0.3, 0.3), "hakama": true},
		{"gender": "m", "hair_style": "kase", "head_style": "bandana", "headgear": Color(0.2, 0.25, 0.5), "face_style": "spiral_maske"},
	]
	var ms = []
	for i in looks.size():
		var cm = CharacterModel.new()
		add_child(cm)
		cm.setup(looks[i])
		cm.global_position = W + Vector3((i - 2) * 1.3, 0, 0)
		cm.play("idle")
		ms.append(cm)
	for f in 4:
		await get_tree().process_frame
	for cm in ms:
		cm.queue_free()
	sv.queue_free()

