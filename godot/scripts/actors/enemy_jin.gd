class_name EnemyJin
extends RefCounted
## Düşman jinchūriki pelerini ve dönüşümü (oyuncu BeastCloak ile AYNI kurallar ve görsel — AI eşitliği):
## dövüşte canı azaldıkça Sürüm 1 (canavarın kuyruk sayısı kadar, en çok 4) -> Sürüm 2 -> tam Kuyruklu Canavar dönüşümü.
## Tam dönüşümde gerçek TailedBeast (jinchūriki'nin gücüne ölçekli) onun yerinde doğar; bastırılınca form dağılır,
## jinchūriki bitkin hâlde geri gelir (anime). Seviye eşikleri can oranıyla: 1:0.85 2:0.72 3:0.6 4:0.5 5:0.36 6:0.2

const STEP_HP := [1.0, 0.85, 0.72, 0.6, 0.5, 0.36, 0.2]


## Her AI düşünme adımında: can oranına göre hedef seviye; eksikse bir sonraki geçerli seviyeye çık
static func tick(e: Enemy) -> void:
	if not e.arch.has("beast") or e.dead or e.get_meta("jin_spent", false) or e.has_meta("jin_form"):
		return
	var bid = String(e.arch["beast"])
	var tails = BeastCloak.beast_tails(bid)
	var lvl = int(e.get_meta("jin_lvl", 0))
	var r = e.hp / maxf(1.0, e.max_hp)
	var maxl = 2 if bid == "raiju" else 6
	if lvl >= maxl:
		return
	var nxt = BeastCloak.next_level(lvl, tails)
	if nxt > maxl or r > float(STEP_HP[clampi(nxt, 0, 6)]):
		return
	set_level(e, nxt)


static func set_level(e: Enemy, lvl: int) -> void:
	var bid = String(e.arch["beast"])
	var col: Color = BeastModels.INFO.get(bid, BeastModels.INFO["kurama"])["chakra"]
	e.set_meta("jin_lvl", lvl)
	# oyuncuyla aynı güç artışı (BeastCloak.set_level)
	e.add_buff("beast", 9999.0, {"melee": 1.1 + lvl * 0.08, "speed": 1.05 + lvl * 0.04, "armor": maxf(0.6, 1.0 - lvl * 0.06), "jutsu": 1.05 + lvl * 0.06})
	FX.ring(e.global_position + Vector3.UP * 0.3, col, 6.0 + lvl * 3.0, 0.5)
	Sfx.play("roar", e.global_position, 1.3 - lvl * 0.08, 0.7)
	Combat.popup_text(e.global_position + Vector3.UP * (e.height + 1.4), BeastCloak.level_name(lvl), col.lightened(0.3))
	if lvl == 6:
		_full_transform(e, bid)
		return
	var m = e.model
	if m == null or not is_instance_valid(m):
		return
	var cl = e.get_meta("jin_cloak", {})
	if cl.is_empty() or not is_instance_valid(cl.get("mesh")):
		cl = BeastCloak.build_cloak(m, col)
		e.set_meta("jin_cloak", cl)
	for tl in e.get_meta("jin_tails", []):
		if is_instance_valid(tl[0]):
			tl[0].queue_free()
	var tails = BeastCloak.beast_tails(bid)
	var n = mini(lvl, tails) if lvl <= 4 else tails
	e.set_meta("jin_tails", BeastCloak.build_tails(cl["tail_root"], n, lvl, cl["mat"]))
	var mt: ShaderMaterial = cl["mat"]
	mt.set_shader_parameter("dark", 0.85 if lvl == 5 else 0.0)
	mt.set_shader_parameter("dark_col", BeastCloak.v2_dark(bid))
	mt.set_shader_parameter("grow", 0.05 + lvl * 0.012)


static func clear_cloak(e: Enemy) -> void:
	for tl in e.get_meta("jin_tails", []):
		if is_instance_valid(tl[0]):
			tl[0].queue_free()
	e.set_meta("jin_tails", [])
	var cl = e.get_meta("jin_cloak", {})
	for k in ["mesh", "ears"]:
		if cl.has(k) and is_instance_valid(cl[k]):
			cl[k].queue_free()
	if cl.has("tail_root") and is_instance_valid(cl["tail_root"]) and cl["tail_root"].get_parent():
		cl["tail_root"].get_parent().queue_free()
	e.set_meta("jin_cloak", {})
	e.buffs.erase("beast")


## Tam dönüşüm: jinchūriki gizlenir, yerinde ona ölçekli gerçek kuyruklu canavar doğar
static func _full_transform(e: Enemy, bid: String) -> void:
	clear_cloak(e)
	var b = TailedBeast.new()
	b.setup(bid)
	b.jin_host = e
	var info: Dictionary = BeastModels.INFO[bid]
	b.height = maxf(16.0, float(info["height"]) * 0.32)   # jinchūriki dönüşümü: vahşi canavardan küçük (oyuncu dönüşümü gibi)
	b.radius = b.height * 0.24
	b.max_hp = e.max_hp * 3.0
	b.hp = b.max_hp
	b.power = e.power * 1.6
	b.display_name = "%s (%s)" % [String(info["name"]).split(" — ")[0], e.display_name]
	var p = e.global_position
	e.get_tree().current_scene.add_child(b)
	b.global_position = p
	b.home = p
	FX.smoke_puff(p + Vector3.UP * b.height * 0.4, b.height * 0.3, 40)
	if Game.world:
		Game.world.env.add_shake(1.0)
	Hud.banner("KUYRUKLU CANAVAR", "%s tam dönüşüme geçti!" % e.display_name, info["chakra"])
	e.set_meta("jin_form", b)
	e.visible = false
	e.process_mode = Node.PROCESS_MODE_DISABLED
	e.set_meta("jin_layer", e.collision_layer)
	e.collision_layer = 0
	e.remove_from_group("fighters")
	b._start_fight()


## Canavar bastırıldı: form dağılır, jinchūriki bitkin hâlde geri gelir (bir daha dönüşemez)
static func form_broken(b: TailedBeast) -> void:
	var e = b.jin_host
	var p = b.global_position
	FX.smoke_puff(p + Vector3.UP * 3.0, 4.0, 30)
	Hud.boss_bar(null)
	b._end_fight()
	b.queue_free()
	if e == null or not is_instance_valid(e):
		return
	e.remove_meta("jin_form")
	e.set_meta("jin_spent", true)
	e.set_meta("jin_lvl", 0)
	e.global_position = p
	e.visible = true
	e.process_mode = Node.PROCESS_MODE_INHERIT
	e.collision_layer = int(e.get_meta("jin_layer", 1))
	e.add_to_group("fighters")
	e.hp = e.max_hp * 0.15
	e.add_buff("jin_tukenme", 30.0, {"melee": 0.6, "speed": 0.7})
	Combat.popup_text(e.global_position + Vector3.UP * (e.height + 1.4), "Canavar formu dağıldı — bitkin!", Color(1, 0.85, 0.5))
	Hud.boss_bar(e)
