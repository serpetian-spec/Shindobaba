class_name ClanResident
extends Villager
## Köyde yaşayan klan üyesi (ClanWorld doğurur). Görünümü klanına göre (saç, kıyafet, Byakugan / Sharingan / Ketsuryūgan),
## [F] ile konuşulur: klan hikâyesi, dostça düello (klan teknikleriyle; %25 canda teslim olur), aynı klandansan klan dersi.

var clan := ""
var vid := ""
var given := ""
var eye_kind := 0
var eye_lvl := 0
var duel_cd := 0.0


func _ready() -> void:
	super._ready()
	if model and eye_kind > 0:
		var vk = 1 if eye_kind in [4, 5] else eye_kind   # Mangekyō gündelik hayatta açık durmaz
		model.set_dojutsu_eyes(vk, 3 if vk != eye_kind else eye_lvl, vk, 3 if vk != eye_kind else eye_lvl, false)


func _physics_process(dt: float) -> void:
	duel_cd -= dt
	super._physics_process(dt)


func talk() -> void:
	if Orgs.rogue_confront(self):
		return   # kaçaksın: köy ninjası konuşmaz, saldırır
	if Game.player:
		var to = Game.player.global_position - global_position
		facing = atan2(-to.x, -to.z)
		model.rotation.y = facing
	model.play("talk", 0.2)
	wait = 6.0
	var opts := []
	var cn := ClanWorld.clan_name(clan)
	var grown: bool = look.get("age", "adult") != "child"
	opts.append({"label": "%s klanını anlat" % cn, "cb": func(): Hud.dialog(display, _lines().pick_random(), [])})
	if grown and duel_cd <= 0.0:
		opts.append({"label": "Dostça düello teklif et", "cb": _duel})
	var friend: bool = Game.profile.get("flags", {}).get("klan_dostu_" + clan, false)
	if String(Game.profile.get("clan", "")) == clan and grown:
		opts.append({"label": "Klan büyüğünden ders iste", "cb": _lesson})
	elif friend and grown:
		opts.append({"label": "Klan dostu olarak antrenman iste", "cb": _lesson})
	opts.append_array(Friends.options_for(self))   # tanış / sohbet / hediye / takıma al
	opts.append_array(Crime.attack_option(self))   # gerçek saldırı (suç)
	var hello := Talk.clan_hello(clan, given, eye_kind)
	if has_meta("friend_id") and Friends.all().has(String(get_meta("friend_id"))):
		hello = Friends.greeting(String(get_meta("friend_id")))
	if friend:
		hello += "

(Klanımızın kaçağını yakalamana yardım ettiğini duyduk. Sen bizdensin artık.)"
	Hud.dialog(display, hello, opts)


func _duel() -> void:
	if Game.player == null:
		return
	duel_cd = 60.0
	var lv := 8 + absi(hash(String(given))) % 50   # sakinin kendi gücü (oyuncuya göre değil)
	var at := global_position
	FX.smoke_puff(at + Vector3.UP, 1.0, 14)
	visible = false
	collision_layer = 0
	remove_from_group("talkers")
	var e: Enemy = ClanWorld.spawn_enemy(clan, lv, at, {"duel": true, "outfit": "chunin", "village": vid, "name": "%s (düello)" % given,
		"female": look.get("gender", "m") == "f", "look": look})
	var t: ClanTrait = e.get_node("ClanTrait")
	t.on_yield = func(won: bool):
		if is_instance_valid(self):
			visible = true
			collision_layer = 4
			add_to_group("talkers")
			global_position = e.global_position if is_instance_valid(e) else at
			home = global_position
			if won:
				Progress.add_xp(30 + lv * 12)
				if has_meta("friend_id"):
					Friends.add_bond(String(get_meta("friend_id")), 6)
				say("İyi dövüştün! %s klanı seni tanıyacak." % ClanWorld.clan_name(clan), 3.5)
	Hud.banner("DOSTÇA DÜELLO", "%s — %s klan teknikleri" % [given, ClanWorld.clan_name(clan)], Color(0.9, 0.85, 0.55))


func _lesson() -> void:
	var fl: Dictionary = Game.profile["flags"]
	var now := Time.get_unix_time_from_system()
	if now - float(fl.get("clan_lesson_t", 0.0)) < 600.0:
		Hud.dialog(display, "Bugünlük yeter. Öğrendiklerini sindir, sonra yine gel.", [])
		return
	fl["clan_lesson_t"] = now
	var plv := int(Game.profile.get("level", 1))
	Progress.add_xp(40 + plv * 10)
	if String(Game.profile.get("clan", "")) != clan:
		Hud.dialog(display, "Gizli tekniklerimizi öğretemem ama dostumuza idman borcumuz var. Hadi, gardını al!", [])
		return
	var learned: Array = Game.profile.get("learned", [])
	for id in ClanWorld.clan_jutsu(clan, plv, 12):
		var j: Dictionary = Data.jutsu.get(id, {})
		if id in learned or int(j.get("level", 1)) > plv:
			continue
		if Progress.learn(id):
			Hud.dialog(display, "Klanımızın tekniği: %s. Ellerini böyle tut... evet, işte böyle." % j.get("name", id), [])
			return
	Hud.dialog(display, "Bildiğin her şeyi zaten biliyorsun. Sana sadece pratik kalıyor — biraz idman yaptık.", [])
