class_name KinScene
extends ScenePoser
## Aile üyeleriyle dünyada oynanan sahneler: baba dersi (mühür gösterir, tekrar edersin / avuçlarına çalışırsın),
## anne bentosu (kutuyu uzatır, alırsın), sarılma.

static var cur: KinScene

var kind := ""
var id := ""
var v: Node3D
var box: MeshInstance3D
var box_at: Node3D
var _was_phys := true


static func start(k: String, fid: String, node: Node) -> void:
	if is_instance_valid(cur) or node == null or not is_instance_valid(node):
		return
	var s = KinScene.new()
	s.kind = k
	s.id = fid
	s.v = node
	cur = s
	Friends.inst().get_parent().add_child(s)


func _ready() -> void:
	Hud.close_dialog()
	_lock(60.0)
	_was_phys = v.is_physics_processing()
	v.set_physics_process(false)
	match kind:
		"lesson": await _lesson()
		"bento": await _bento()
		"hug": await _hug()
	_finish()


func _finish() -> void:
	var pl = Game.player
	_clear_pose(pl)
	pl.model.play("idle", 0.3)
	_release_player()
	if is_instance_valid(v):
		_clear_pose(v)
		v.model.play("idle", 0.3)
		v.home = v.global_position
		v.goal = v.global_position
		v.set_physics_process(_was_phys)
	if is_instance_valid(box):
		box.queue_free()
	if cur == self:
		cur = null
	queue_free()


func _exit_tree() -> void:
	if cur == self:
		cur = null
	_release_player()


func _process(dt: float) -> void:
	_apply_poses(dt)
	if is_instance_valid(box) and is_instance_valid(box_at):
		var fd = _fd(box_at)
		var p = box_at.global_position + Vector3.UP * 1.06 * box_at.model.age_scale + fd * 0.36
		box.global_position = box.global_position.lerp(p, minf(1.0, dt * 9.0))
		box.global_basis = Basis(Vector3.UP, box_at.facing)


## Karşısına geç (mesafe d), yüz yüze dön
func _front(d: float) -> void:
	var pl = Game.player
	var to = pl.global_position - v.global_position
	to.y = 0
	if to.length() < 0.1:
		to = Vector3(0, 0, 1)
	_look_at(v, pl.global_position)
	var spot = v.global_position + to.normalized() * d
	spot.y = Game.ground_height(spot.x, spot.z)
	await _go_w(pl, spot, 1.6)
	_look_at(pl, v.global_position)
	_look_at(v, pl.global_position)


func _tell(text: String, dur := 2.4) -> void:
	Combat.popup_text(_bone(Game.player, "Head") + Vector3.UP * 0.35, text, Color(1.0, 0.92, 0.72))
	await _wait(dur)


# ------------------------------------------------------------------ baba dersi
func _lesson() -> void:
	var pl = Game.player
	var f: Dictionary = Friends.all()[id]
	var clan = String(f.get("clan", ""))
	var plv = int(pr_().get("level", 1))
	var jid := ""
	if clan != "" and String(pr_().get("clan", "")) == clan:
		var learned: Array = pr_().get("learned", [])
		for c in ClanWorld.clan_jutsu(clan, plv, 12):
			var j: Dictionary = Data.jutsu.get(c, {})
			if not c in learned and int(j.get("level", 1)) <= plv and Progress.element_block(String(c)) == "" and not String(j.get("learn", "")).begins_with("eye:"):
				jid = String(c)
				break
	if jid != "":
		await _front(2.2)
		var jn = String(Data.jutsu[jid].get("name", jid)).split(" (")[0]
		_say(v, "Klanımızın tekniği: %s. İyi izle, bir kez gösteririm." % jn, 3.6)
		await _wait(1.6)
		_pose(v, "seal", {"anim": "idle"})
		Sfx.play("seal", v.global_position, 0.6)
		await _wait(1.5)
		_clear_pose(v)
		v.model.play("cast_out", 0.1, 1.0, true)
		Sfx.play("chakra", v.global_position, 0.5)
		await _wait(1.3)
		v.model.play("idle", 0.3)
		_say(v, "Mühürleri acele etme. Şimdi sen.", 2.6)
		await _wait(1.2)
		_pose(pl, "seal", {"anim": "idle"})
		Sfx.play("seal", pl.global_position, 0.6)
		await _wait(1.7)
		_clear_pose(pl)
		pl.model.play("cast_out", 0.1, 1.0, true)
		Sfx.play("chakra", pl.global_position, 0.5)
		await _wait(1.2)
		pl.model.play("idle", 0.3)
		v.model.play("yes", 0.15, 1.0, true)
		if Progress.learn(jid):
			_say(v, "İşte böyle. Artık senin.", 3.0)
			Journal.add("Babam bana %s tekniğini öğretti." % jn, "milestone")
		else:
			_say(v, "Henüz hazır değilsin. Biraz daha güçlen, yine gel.", 3.0)
		await _wait(2.0)
	else:
		# öğretecek teknik yok: avuçlarını tutar, vuruş çalışırsın
		await _front(0.95)
		_say(v, "Teknik değil, temel. Avuçlarıma vur — kalçandan!", 3.0)
		var c2 = pl.global_position + Vector3.UP * 1.32 + _fd(pl) * 0.52
		_pose(v, "pads", {"anim": "idle", "c": c2, "rec": 0.0})
		await _wait(1.3)
		var seq = ["jab", "cross", "jab", "cross", "hook", "jab", "cross", "hook"]
		for i in seq.size():
			pl.model.play(seq[i], 0.06, 1.25, true)
			await _wait(0.22)
			if st.has(v):
				st[v]["rec"] = 0.14 if seq[i] == "hook" else 0.09
			Sfx.play("punch", c2, 0.5)
			await _wait(0.34 if i < 4 else 0.26)
		pl.model.play("idle", 0.3)
		_clear_pose(v)
		v.model.play("yes", 0.15, 1.0, true)
		_say(v, ["Omuzların gevşedi, güzel.", "Fena değil. Ben senin yaşındayken iki katını yapardım ama."].pick_random(), 3.0)
		Mastery.gain(pr_(), "taijutsu", 1.0)
		Progress.add_xp(30 + plv * 8)
		await _wait(2.0)
	f["kin_lesson"] = Time.get_unix_time_from_system()
	Friends.add_bond(id, 2, true)


static func pr_() -> Dictionary:
	return Game.profile


# ------------------------------------------------------------------ anne bentosu
func _bento() -> void:
	var pl = Game.player
	var f: Dictionary = Friends.all()[id]
	await _front(0.95)
	_say(v, ["Yine mi bir şey yemeden çıktın? Al bakalım.", "Biliyordum, o yüzden yanımda taşıyorum.", "Zayıflamışsın sen. Al şunu."].pick_random(), 3.2)
	var b = MB.new()
	b.add("box", Vector3.ZERO, Vector3(0.24, 0.09, 0.16), Color(0.35, 0.12, 0.1))
	b.add("box", Vector3(0, 0.048, 0), Vector3(0.25, 0.012, 0.17), Color(0.15, 0.1, 0.1))
	b.add("box", Vector3(0, 0.056, 0), Vector3(0.03, 0.006, 0.19), Color(0.85, 0.75, 0.45))   # bağ
	b.add("box", Vector3(0, 0.056, 0), Vector3(0.27, 0.006, 0.03), Color(0.85, 0.75, 0.45))
	box = _mesh(b)
	box_at = v
	box.global_position = v.global_position + Vector3.UP * 1.0
	_pose(v, "carry", {"anim": "idle"})
	await _wait(1.3)
	_pose(pl, "carry", {"anim": "idle"})
	await _wait(0.5)
	box_at = pl
	_clear_pose(v)
	v.model.play("idle", 0.3)
	await _wait(0.7)
	await _tell("Sağ ol anne.", 1.2)
	_pose(pl, "bow", {"anim": "idle", "len": 1.4})
	box.queue_free()
	_say(v, "Dikkatli ol, tamam mı? Akşama eve gel.", 3.0)
	await _wait(1.6)
	pl.hp = pl.max_hp
	Buffs.add("anne_bentosu", 300.0, {"melee": 1.08, "armor": 0.92})
	Hud.msg("Annenin bentosu: can doldu; 5 dakika güç +%8, alınan hasar -%8.", Color(1.0, 0.85, 0.5))
	f["kin_bento"] = Time.get_unix_time_from_system()
	Friends.add_bond(id, 2, true)


# ------------------------------------------------------------------ sarılma
func _hug() -> void:
	var pl = Game.player
	await _front(0.32)
	_pose(v, "hug", {"with": pl, "anim": "idle", "hi": 0.1})
	_pose(pl, "hug", {"with": v, "anim": "idle", "hi": -0.12})
	_say(v, ["Ne oldu yavrum? ...Gel buraya.", "Kaç yaşına gelirsen gel, benim çocuğumsun.", "Yoruldun değil mi. Biliyorum."].pick_random(), 3.0)
	await _wait(1.2)
	Combat.popup_text((_bone(pl, "Head") + _bone(v, "Head")) * 0.5 + Vector3.UP * 0.35, "♥", Color(1, 0.5, 0.65))
	await _wait(2.0)
	Friends.add_bond(id, 1, true)
