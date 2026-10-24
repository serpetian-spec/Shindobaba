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
	_show_loading()
	await get_tree().process_frame
	world = GameWorld.new()
	world.name = "World"
	add_child(world)
	await world.build(func(v, label): _loading_progress(v, label))
	# kıyafet kabuklarını yükleme ekranında hazırla (oyunda ilk NPC'de takılma olmasın)
	_loading_progress(0.98, "Ninjalar giydiriliyor")
	await get_tree().process_frame
	for g in ["m", "f"]:
		var cm = CharacterModel.new()
		add_child(cm)
		cm.setup({"gender": g, "vest": Color(0.38, 0.48, 0.28)})
		cm.queue_free()
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


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--test="):
			test_script = a.substr(7)
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
		"slot1": [KEY_1], "slot2": [KEY_2], "slot3": [KEY_3], "slot4": [KEY_4], "slot5": [KEY_5], "slot6": [KEY_6],
		"inventory": [KEY_I], "skills": [KEY_K], "map": [KEY_M], "pause": [KEY_ESCAPE], "dojutsu": [KEY_V],
		"sage": [KEY_Z], "beast": [KEY_X], "gates": [KEY_B], "seal_mode": [KEY_G], "weapon_draw": [KEY_N],
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
		player.queue_free()
		player = null
		Game.player = null
	if preview:
		preview.queue_free()
		preview = null
	mode = "menu"
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
	creator_state = {"slot": slot, "name": "", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "top2": Color(0.15, 0.15, 0.17), "pants": Color(0.15, 0.15, 0.17),
		"top_style": "ceket", "pants_style": "ninja",
		"skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	_update_preview()
	Menus.creator(self, creator_state, _update_preview, _start_new_game)


func _creator_look() -> Dictionary:
	var s = creator_state
	var eye: Color = s["eye"]
	if Data.clans.has(s["clan"]) and s["clan"] in ["uchiha", "hyuga", "aburame"]:
		var e: Array = Data.clans[s["clan"]]["eye"]
		eye = Color(e[0], e[1], e[2])
	return {"gender": s["gender"], "hair_style": s["hair_style"], "hair": s["hair"], "top": s["top"],
		"top2": s.get("top2", Color(s["top"]).darkened(0.3)), "pants": s["pants"], "top_style": s.get("top_style", "ceket"), "pants_style": s.get("pants_style", "ninja"), "skin": s["skin"], "eye": eye, "band": null, "age": "child", "village": s.get("village", "konoha")}


func _update_preview() -> void:
	if preview:
		preview.queue_free()
	preview = CharacterModel.new()
	add_child(preview)
	preview.setup(_creator_look())
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"] - 120, v["y"] + 175 - 32))  # salıncaklı ağaç yakını
	preview.global_position = base
	preview.rotation.y = preview_yaw
	preview.play("idle")
	menu_cam.global_position = base + Vector3(-1.2, 1.3, -3.2)
	menu_cam.look_at(base + Vector3(-0.4, 1.0, 0), Vector3.UP)


func _start_new_game() -> void:
	var s = creator_state
	if String(s["name"]).strip_edges() == "":
		s["name"] = ["Kaito", "Hiro", "Ren", "Sora", "Aki", "Yuki"].pick_random()
	Game.profile = Progress.new_profile({"slot": s["slot"], "name": s["name"], "gender": s["gender"], "clan": s["clan"],
		"element": s["element"], "look": _creator_look(), "village": s.get("village", "konoha")})
	Game.profile["pos"] = null
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


func _begin_game(pos: Vector3) -> void:
	if preview:
		preview.queue_free()
		preview = null
	Menus.clear()
	# JSON'dan gelen renkleri Color'a çevir
	var look: Dictionary = Game.profile["look"]
	for k in look.keys():
		if look[k] is String and String(look[k]).begins_with("("):
			look[k] = str_to_var("Color" + look[k])
	# eski kayıtlar: köy/itibar alanları yoksa Konoha
	if not Game.profile.has("village"):
		Game.profile["village"] = "konoha"
	if not Game.profile.has("rep"):
		Game.profile["rep"] = {}
	look["village"] = Game.profile["village"]
	Progress.refresh_story()
	Missions._story_cache.clear()
	# eski kayıtlar 4 slotluydu: 6'ya tamamla
	var sl: Array = Game.profile.get("slots", [])
	while sl.size() < 6:
		sl.append("")
	Game.profile["slots"] = sl
	Gear.ensure(Game.profile)
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
			preview.rotation.y = preview_yaw
	if mode != "game":
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
	if e.is_action_pressed("menu"):
		_toggle_panel(func(): Menus.ninja_menu(self, "inv"))
	elif e.is_action_pressed("inventory"):
		_toggle_panel(func(): Menus.ninja_menu(self, "inv"))
	elif e.is_action_pressed("skills"):
		_toggle_panel(func(): Menus.ninja_menu(self, "jutsu"))
	elif e.is_action_pressed("map"):
		_toggle_panel(func(): Menus.world_map(self))
	elif Game.paused:
		return
	elif e.is_action_pressed("interact"):
		var it = Interact.nearest(player.global_position)
		# önce yerdeki dōjutsu sahibinin gözleri (yakındaki etkileşimler F'yi yutuyordu)
		var ey = player.combat.modes.eyes if player.combat and player.combat.modes else null
		if ey and ey.steal_target != null and is_instance_valid(ey.steal_target):
			ey._steal(ey.steal_target)
		elif not it.is_empty():
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
		var tools = ["kunai", "shuriken", "tag", "smoke"]
		var i = tools.find(Game.profile.get("throw_sel", "kunai"))
		for k in tools.size():
			i = (i + 1) % tools.size()
			if int(Game.profile["inventory"].get(tools[i], 0)) > 0:
				break
		Game.profile["throw_sel"] = tools[i]
	elif e.is_action_pressed("salve"):
		use_item("salve")
	elif e.is_action_pressed("pill"):
		use_item("pill")


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


func use_item(id: String) -> void:
	var inv: Dictionary = Game.profile["inventory"]
	if int(inv.get(id, 0)) <= 0:
		Hud.msg("Hiç %s yok." % Data.items.get(id, {"name": id})["name"], Color(1, 0.6, 0.5))
		return
	inv[id] = int(inv[id]) - 1
	match id:
		"salve":
			player.hp = minf(player.max_hp, player.hp + 50.0 * (1.0 + Stats.skill(Game.profile, "heal")))
			FX.aura(player, Color(0.5, 1, 0.6), 0.8)
			Sfx.play("heal", player.global_position)
		"pill":
			player.chakra = minf(player.max_chakra, player.chakra + 60.0)
			Buffs.add("pill", 20.0, {"melee": 1.25})
			FX.aura(player, Color(1, 0.7, 0.3), 0.8)
			Sfx.play("heal", player.global_position, 0.8)


func fast_travel(vid: String) -> void:
	var v = Game.village(vid)
	resume()
	FX.smoke_puff(player.global_position + Vector3.UP, 1.0, 14)
	player.respawn(Game.from_map(Vector2(v["x"], v["y"] - float(v["r"]) * 0.5)))
	Hud.banner(v["name"], "Hızlı seyahat", Color(0.8, 0.95, 1.0))


func _process(dt: float) -> void:
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
