class_name EyeSurgery
extends RefCounted
## GÖZ NAKLİ — kanon (Narutopedia: Kakashi'ye Rin sahada taktı; Orochimaru/Kabuto gizli ameliyatlar yaptı; Madara Nagato'ya gizlice
## taktı; Danzō Shisui'nin gözünü sargı altında taşıdı). Köy hastanesi başkasının dōjutsusunu takmaz: klan gözü klanın malıdır.
## Nakli yapabilenler:
##   * takımdaki tıbbi ninja (Rin örneği) — sahada, ücretsiz, iyi ihtimalle tutar
##   * kendi tıbbi ninjutsun — Shōsen + yüksek chakra kontrolü; riskli, beden ağır yıpranır
##   * yeraltının Kara Cerrahı (Orochimaru/Kabuto benzeri) — pahalı, soru sormaz, neredeyse hep tutar
## Ameliyat dünyada gerçek bir olaydır: düşman yakında olmamalı, oturursun, yeşil şifa chakrası gözünde çalışır (~5 sn),
## sonra göz tutar ya da beden reddeder (göz bozulur). Ardından iyileşme süresi (Buffs "nakil").
## Bedel (kanon): Uchiha kanı olmayan bedende Sharingan kapanmaz — açık olmasa da chakrayı yavaşça emer (Eyes._process).

const OP_TIME := 5.0


## Kendi tıbbi ninjutsunla nakil yapabilir mi? (Shōsen bilgisi + chakra kontrolü ustalığı 50)
static func can_self(pr: Dictionary) -> bool:
	return "shousen" in pr.get("learned", []) and Mastery.get_v(pr, "chakra") >= 50.0


## Kendi ameliyatının tutma olasılığı: chakra kontrolü 50 -> %40, 100 -> %90; ileri tıbbi teknikler (Tsunade yolu) +%10
static func self_chance(pr: Dictionary) -> float:
	var c = clampf(0.4 + (Mastery.get_v(pr, "chakra") - 50.0) * 0.01, 0.4, 0.9)
	for adv in ["in_yu_shometsu", "sozo_saisei", "chakura_no_mesu"]:
		if adv in pr.get("learned", []):
			c += 0.05
	return minf(0.97, c)


static func surgeons(pr: Dictionary) -> Dictionary:
	return {
		"medic": {"title": "Sahada nakil", "chance": 0.88, "price": 0, "hp": 0.15, "recover": 150.0,
			"ok": "Gözün sarıldı. \"Bir süre bandajı çıkarma; beden yeni gözü tanıyana kadar ağrıyacak.\""},
		"self": {"title": "Kendi tıbbi ninjutsunla nakil", "chance": self_chance(pr), "price": 0, "hp": 0.4, "recover": 300.0,
			"ok": "Titreyen ellerle son sinir bağını da kapattın. Göz tuttu."},
		"black": {"title": "Kara Cerrah", "chance": 0.97, "price": 1200, "hp": 0.1, "recover": 90.0,
			"ok": "Kara Cerrah dikişleri attı: \"Kimden aldığını sormadım, sen de unut.\""},
	}


## Kavanozdaki her göz x her yuva için seçenek listesi (Hud.dialog seçenekleri)
static func options(kind: String) -> Array:
	var pr = Game.profile
	var s: Dictionary = surgeons(pr)[kind]
	var opts = []
	for g in pr.get("gear", []):
		if Gear.item(g["id"]).get("slot", "") != "goz" or Gear.is_equipped(pr, g):
			continue
		if String(g.get("origin", "dogustan")) == "dogustan" and bool(g.get("own", false)):
			continue   # kendi çıkardığın göz: menüden geri takılır, nakil gerekmez
		for sl in [["sag_goz", "sağ"], ["sol_goz", "sol"]]:
			var uid = int(g["uid"])
			var slot = sl[0]
			var price = int(s["price"])
			var lbl = "%s → %s göz  (tutma %%%d%s)" % [Gear.item(g["id"])["name"], sl[1], int(round(float(s["chance"]) * 100.0)), (", %d Ryō" % price) if price > 0 else ""]
			opts.append({"label": lbl, "cb": func(): operate(uid, slot, kind)})
	return opts


## Ameliyat olayı: düşman yokken oturur, şifa chakrası çalışır, sonra sonuç
static func operate(uid: int, slot: String, kind: String) -> void:
	var pr = Game.profile
	var p = Game.player
	if p == null or not is_instance_valid(p):
		return
	var s: Dictionary = surgeons(pr)[kind]
	if int(pr.get("ryo", 0)) < int(s["price"]):
		Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
		return
	for f in p.get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(p, f) and not f.is_dead() and f.global_position.distance_to(p.global_position) < 35.0:
			Hud.msg("Düşman yakındayken göz nakli yapılmaz — önce güvenli bir yere çekil.", Color(1, 0.6, 0.4))
			return
	if int(s["price"]) > 0:
		Progress.add_ryo(-int(s["price"]))
	var g = Gear.find(pr, uid)
	if g.is_empty():
		return
	# olay: otur, yeşil şifa chakrası gözünde (kendi ameliyatında senin ellerin, diğerlerinde cerrahın)
	p.velocity = Vector3.ZERO
	p.model.play("idle", 0.3)
	p.input_locked = OP_TIME + 0.5
	Hud.msg("Göz nakli başladı... kıpırdama." if kind != "self" else "Bir eline ayna, öbürüne şifa chakrası... kendi gözünü açıyorsun.", Color(0.6, 1.0, 0.65))
	var head = p.global_position + Vector3.UP * 1.0
	# sahada nakil: takımdaki tıbbi ninja yanına gelir, karşına diz çöküp şifa chakralı ellerini gözüne tutar
	if kind == "medic":
		var best: Node3D = null
		for f in p.get_tree().get_nodes_in_group("fighters"):
			if f.has_meta("teammate") and not f.is_dead() and (best == null or f.global_position.distance_to(p.global_position) < best.global_position.distance_to(p.global_position)):
				best = f
		if best:
			var at = p.global_position + p.face_dir() * 0.9
			at.y = Game.ground_height(at.x, at.z)
			best.global_position = at
			best.velocity = Vector3.ZERO
			var dv = p.global_position - at
			best.facing = atan2(-dv.x, -dv.z)
			best.set_physics_process(false)   # ameliyat boyunca yerinden kıpırdamaz
			if best.get("model"):
				best.model.rotation.y = best.facing
				best.model.play("idle", 0.3)
			CastAnim.play(best, "shousen", OP_TIME)   # şifa elleri öne, gözüne
			var ma = FX.aura(best, Color(0.4, 1.0, 0.5), 0.5, Vector3(0, 1.0, 0), 0.0)
			best.get_tree().create_timer(OP_TIME).timeout.connect(func():
				if is_instance_valid(best):
					best.set_physics_process(true)
				if is_instance_valid(ma):
					ma.emitting = false
					ma.get_tree().create_timer(1.0).timeout.connect(ma.queue_free))
	var aura = FX.aura(p, Color(0.4, 1.0, 0.5), 0.6, Vector3(0, 1.0, 0), 0.0)
	Sfx.play("heal", head)
	if kind == "self":
		CastAnim.play(p, "shousen", OP_TIME)   # kendi elleri kendi gözünde
	var tw = p.create_tween()
	for i in int(OP_TIME / 0.5):
		tw.tween_callback(func():
			if is_instance_valid(p):
				FX.hit_spark(_eye_pos(p), Color(0.45, 1.0, 0.55), 0.12))
		tw.tween_interval(0.5)
	tw.tween_callback(func():
		if is_instance_valid(aura):
			aura.emitting = false
			aura.get_tree().create_timer(1.0).timeout.connect(aura.queue_free)
		_finish(uid, slot, kind))


static func _finish(uid: int, slot: String, kind: String) -> void:
	var pr = Game.profile
	var p = Game.player
	var s: Dictionary = surgeons(pr)[kind]
	var g = Gear.find(pr, uid)
	if g.is_empty() or p == null:
		return
	p.hp = maxf(1.0, p.hp - p.max_hp * float(s["hp"]))
	if randf() > float(s["chance"]):
		# beden reddetti: göz bozuldu (kavanozdan da gider)
		pr["gear"].erase(g)
		Buffs.add("nakil", float(s["recover"]) * 0.5, {"speed": 0.85, "melee": 0.85})
		Hud.banner("NAKİL TUTMADI", "Beden gözü reddetti — göz kullanılamaz hale geldi", Color(0.8, 0.3, 0.3))
		return
	Eyes.transplant(pr, uid, slot)
	Buffs.add("nakil", float(s["recover"]), {"speed": 0.85, "melee": 0.85})
	var txt = String(s["ok"])
	var gid = String(g["id"])
	if gid in ["goz_sharingan", "goz_mangekyo", "goz_ems"] and String(pr.get("clan", "")) != "uchiha":
		txt += "\nUchiha kanın olmadığı için bu Sharingan kapanmaz: açık olmasa da chakranı durmadan emer."
	Hud.dialog("Göz Nakli", txt, [])
	if kind == "self":
		Mastery.gain(pr, "chakra", 0.5)


## Oyuncunun göz hizası (baş kemiğinden; yoksa çömelme yüksekliği)
static func _eye_pos(p: Node3D) -> Vector3:
	var m = p.get("model")
	if m and is_instance_valid(m) and m.get("skel") and m.skel.find_bone("Head") >= 0:
		var t: Transform3D = m.skel.global_transform * m.skel.get_bone_global_pose(m.skel.find_bone("Head"))
		return t.origin + Vector3.UP * 0.08 + p.face_dir() * 0.12
	return p.global_position + Vector3.UP * 0.95 + p.face_dir() * 0.15
