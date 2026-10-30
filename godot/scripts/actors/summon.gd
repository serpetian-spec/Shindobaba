class_name Summon
extends Fighter
## Kuchiyose ile çağrılan hayvan. Sözleşme + kademe + tanım (Contracts.DEFS) ile kurulur.
## Roller: scout (düşmanları işaretler), tracker (hedefe iz), healer (oyuncuyu iyileştirir), binder (bağlar),
## fighter / pack / wind / staff / tank / genjutsu / giant / giant_healer. Dev olanlara [F] ile binilir.

var contract = "kurbağa"
var tier = 1
var def := {}
var owner_f: Node3D = null
var scale_m = 1.0
var life = 60.0
var cd = 1.0
var special_cd = 1.0   # imza tekniği çağrılır çağrılmaz (hedef menzildeyse)
var combo_cd = 0.0
var tgt: Node3D = null
var parts := {}
var anim_t = 0.0
var hop_t = -1.0
var mounted = false
var bubble: Label3D
var bubble_t = 0.0
var trail: Array = []          # yılan: baş izi (gövde segmentleri takip eder)
var markers := {}
var mount_prompt = false


func _ready() -> void:
	look = null
	var h: float = def.get("h", 2.0) * scale_m
	var length: float = def.get("len", 0.0) * scale_m
	var long_body = length > h * 1.5
	radius = clampf((length * 0.22 if long_body else h * 0.45), 0.25, 18.0)
	height = h
	if owner_f is Player:
		max_hp = def.get("hp", 200.0) * (1.0 + float(Game.profile.get("level", 1)) * 0.03) * (1.0 + Stats.skill(Game.profile, "summon_power"))
	else:
		# düşman çağrısı: oyuncunun hasarıyla ölçeklenir (eskiden tanım canının tamamı + sahibin seviyesi: öldürülemiyordu)
		var plv = float(Game.profile.get("level", 1))
		max_hp = def.get("hp", 200.0) * 0.25 * (1.0 + plv * 0.03)
	hp = max_hp
	life = Contracts.TIER_LIFE[tier] * (1.0 + clampf(Contracts.mastery(contract) / 300.0, 0.0, 0.5))
	add_to_group("fighters")
	add_to_group("summons")
	collision_layer = 4
	collision_mask = 1 | 4
	if h >= 1.0:
		var cs = CollisionShape3D.new()
		var cap = CapsuleShape3D.new()
		cap.radius = radius
		cap.height = maxf(h, radius * 2.0 + 0.1)
		cs.shape = cap
		cs.position.y = cap.height * 0.5
		add_child(cs)
	parts = SummonModels.build(def.get("model", ""), h, length)
	add_child(parts["root"])
	parts["root"].scale = Vector3.ONE * 0.05
	parts["root"].create_tween().tween_property(parts["root"], "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	if def.get("role", "") == "staff" and owner_f is Player:
		_become_staff()
	# ortak jutsu: sahibi element jutsusu atınca katıl
	if owner_f is Player and Jutsu.has_signal("jutsu_cast"):
		Jutsu.jutsu_cast.connect(_on_owner_cast)


func _on_owner_cast(caster: Node, jid: String) -> void:
	if caster != owner_f or dead or global_position.distance_to(caster.global_position) > 60.0:
		return
	var j: Dictionary = Data.jutsu.get(jid, {})
	var el = String(j.get("element", ""))
	if el == "":
		var els: Array = j.get("elements", [])
		el = String(els[0]) if not els.is_empty() else ""
	if el != "":
		get_tree().create_timer(0.25).timeout.connect(combo.bind(el))


func is_dead() -> bool:
	return dead


func say(text: String, dur := 3.0) -> void:
	if bubble == null:
		bubble = Label3D.new()
		bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bubble.font_size = 56
		bubble.pixel_size = 0.0075 * clampf(height * 0.6, 1.0, 6.0)
		bubble.outline_size = 12
		bubble.modulate = Color(1, 0.97, 0.88)
		bubble.outline_modulate = Color(0.08, 0.06, 0.06)
		bubble.no_depth_test = true
		add_child(bubble)
	bubble.position = Vector3(0, height * 1.15 + 0.6, 0)
	bubble.text = "%s: %s" % [String(def.get("name", "")).split(" ")[-1], text]
	bubble.visible = true
	bubble_t = dur


## Uzun gövdeli dev çağrılar (yılan hükümdarı: 70 m, çöreklenir): isabet yalnız merkez kapsülde sayılıyordu,
## gövdeye/kafaya vuruşlar ıskalıyordu ("yılan ölmüyor"). Gövdenin kapladığı silindir + kafa (ağız) bölgesi
func hit_test(point: Vector3, extra: float) -> bool:
	var base = global_position
	var length: float = float(def.get("len", 0.0)) * scale_m
	var reach = maxf(radius, length * 0.32)
	if point.y >= base.y - 2.0 and point.y <= base.y + height * 1.3:
		if Vector2(point.x - base.x, point.z - base.z).length() <= reach + extra:
			return true
	if parts.has("mouth") and parts.has("root"):
		var mp: Vector3 = (parts["root"] as Node3D).global_transform * (parts["mouth"] as Vector3)
		if point.distance_to(mp) <= height * 0.5 + extra:
			return true
	return false


func take_hit(info: Dictionary) -> void:
	if dead:
		return
	var dmg: float = info.get("dmg", 5.0)
	if def.get("role", "") == "tank":
		dmg *= 0.5
	hp -= dmg
	Combat.damage_number(global_position + Vector3.UP * (height + 0.5), dmg, Color(1, 0.8, 0.5))
	if parts.has("root"):
		var r: Node3D = parts["root"]
		var tw = r.create_tween()
		tw.tween_property(r, "position:y", 0.15 * clampf(height, 0.5, 4.0), 0.06)
		tw.tween_property(r, "position:y", 0.0, 0.12)
	if hp <= 0.0:
		dismiss()


## Geri gönder (duman), oyuncu biniyorsa indir
func dismiss() -> void:
	if dead:
		return
	dead = true
	_dismount()
	for k in markers:
		if is_instance_valid(markers[k]):
			markers[k].queue_free()
	FX.smoke_puff(global_position + Vector3.UP * height * 0.5, maxf(1.2, height * 0.35), 20 + int(height * 2))
	Sfx.play("poof", global_position, clampf(1.5 - height * 0.04, 0.6, 1.5))
	if owner_f is Player and def.get("role", "") == "staff":
		Game.profile["equip"].erase("_staff_tmp")
	queue_free()


func _physics_process(dt: float) -> void:
	if Game.paused or dead:
		return
	if owner_f != null and not is_instance_valid(owner_f):
		owner_f = null   # çağıran öldü/silindi: silinmiş nesneye erişme (release'te çökme), çağrılan da gider
		dismiss()
		return
	life -= dt
	cd -= dt
	special_cd -= dt
	combo_cd -= dt
	bubble_t -= dt
	if bubble and bubble_t <= 0.0:
		bubble.visible = false
	if owner_f is Player:
		var up = Contracts.TIER_UPKEEP[tier] * dt * maxf(0.2, 1.0 + Stats.skill(Game.profile, "summon_cost"))
		owner_f.chakra = maxf(0.0, owner_f.chakra - up)
		var cs: Dictionary = Game.profile.get("contracts", {}).get(contract, {})
		cs["mastery"] = float(cs.get("mastery", 0.0)) + dt
		if owner_f.chakra <= 0.0 and up > 0.0:
			say("Chakran bitti, gidiyorum!", 2.0)
			life = minf(life, 0.5)
	# çağıran ölünce sözleşme hayvanı da duman olup gider
	if life <= 0.0 or (owner_f != null and (not is_instance_valid(owner_f) or (owner_f.has_method("is_dead") and owner_f.is_dead()))):
		dismiss()
		return
	if mounted:
		_ride(dt)
	else:
		_ai(dt)
	_animate(dt)
	_mount_check()


# ------------------------------------------------------------------ yapay zekâ
func _ai(dt: float) -> void:
	var role: String = def.get("role", "fighter")
	var fly: bool = def.get("fly", false)
	if not fly:
		velocity.y -= 32.0 * dt
	if tgt == null or not is_instance_valid(tgt) or tgt.is_dead():
		tgt = Combat.nearest_enemy(self, 30.0 + height * 2.0)
	var wish = Vector3.ZERO
	var spd: float = def.get("speed", 9.0)
	var keep = 5.0 + height * 0.5
	if role in ["scout", "tracker", "healer", "genjutsu", "tank"] and owner_f:
		# yanında dur, görevini yap
		var v = owner_f.global_position + owner_f.face_dir() * -2.0 + Vector3(2, 0, 0) - global_position
		v.y = 0
		if v.length() > 2.5:
			wish = v.normalized() * spd * minf(1.0, v.length() / 4.0)
		_support(role, dt)
	elif tgt:
		var v = tgt.global_position - global_position
		v.y = 0
		facing = atan2(-v.x, -v.z)
		if v.length() > radius + tgt.radius + 1.5 + height * 0.25:
			wish = v.normalized() * spd
		elif cd <= 0.0:
			cd = clampf(1.2 + height * 0.08, 1.2, 3.0)
			_attack()
		if special_cd <= 0.0 and v.length() < 30.0 + height:
			special_cd = 7.0 + height * 0.2
			_special()
	elif owner_f:
		var v = owner_f.global_position - global_position
		v.y = 0
		if v.length() > keep:
			wish = v.normalized() * spd
	if wish.length() > 0.1:
		facing = lerp_angle(facing, atan2(-wish.x, -wish.z), minf(1.0, dt * 6.0))
	velocity.x = wish.x
	velocity.z = wish.z
	if fly:
		var gh = Game.jutsu_floor(global_position.x, global_position.z)
		var want = gh + (2.0 + height * 0.6 if tgt == null else 1.0 + height * 0.3)
		velocity.y = clampf((want - global_position.y) * 2.0, -10.0, 10.0)
	move_and_slide()
	_ground()


func _ground() -> void:
	if def.get("fly", false) and not mounted:
		return
	var g = Game.jutsu_floor(global_position.x, global_position.z)
	if global_position.y < g or (is_on_floor() == false and global_position.y - g < 0.3):
		global_position.y = g
		velocity.y = 0


## Destek rolleri: işaretle, iyileştir, iz sür, genjutsu
func _support(role: String, dt: float) -> void:
	match role:
		"scout":
			if cd <= 0.0:
				cd = 1.0
				for f in get_tree().get_nodes_in_group("fighters"):
					if Combat.hostile(owner_f, f) and not f.is_dead() and f.global_position.distance_to(global_position) < 70.0:
						_mark(f, Color(1.0, 0.85, 0.3))
				if tgt and special_cd <= 0.0 and tgt.global_position.distance_to(global_position) < 18.0:
					special_cd = 4.0
					_water_gun(tgt)
		"tracker":
			if cd <= 0.0:
				cd = 2.0
				var far = Combat.nearest_enemy(self, 160.0)
				if far:
					_mark(far, Color(1.0, 0.6, 0.3))
					if special_cd <= 0.0:
						special_cd = 6.0
						say("Kokusu buradan geliyor!", 2.0)
				elif Missions.has_marker and special_cd <= 0.0:
					special_cd = 10.0
					say("Hedefin izi pusulanın gösterdiği yönde!", 2.5)
		"healer":
			if owner_f and owner_f.hp < owner_f.max_hp:
				owner_f.hp = minf(owner_f.max_hp, owner_f.hp + 6.0 * dt * (1.0 + tier))
				if cd <= 0.0:
					cd = 1.5
					FX.aura(owner_f, Color(0.5, 1.0, 0.6), 0.6, Vector3(0, 0.9, 0), 0.8)
		"genjutsu":
			if cd <= 0.0 and tgt and tgt.global_position.distance_to(global_position) < 20.0:
				cd = 6.0
				_special()
		"tank":
			if owner_f:
				Buffs.add("summon_tank", 1.5, {"armor": 0.75})
	# destek çağrıları da imza tekniğini kullanır (iz sürücü, tank, şifacı değil)
	if role in ["tracker", "tank"] and special_cd <= 0.0 and tgt and is_instance_valid(tgt) and not tgt.is_dead() and tgt.global_position.distance_to(global_position) < 25.0:
		special_cd = 8.0
		_special()


func _mark(f: Node3D, col: Color) -> void:
	var id = f.get_instance_id()
	if markers.has(id) and is_instance_valid(markers[id]):
		return
	var l = Label3D.new()
	l.text = "▼"
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.002
	l.font_size = 52
	l.modulate = col
	l.outline_size = 8
	f.add_child(l)
	l.position = Vector3(0, f.height + 0.8, 0)
	markers[id] = l


func _front(d := 0.0) -> Vector3:
	return global_position + face_dir() * (radius + 1.0 + d) + Vector3.UP * height * 0.4


## Temel saldırı: türe göre
var attack_anim_t = 0.0


func _attack() -> void:
	attack_anim_t = 0.7   # prosedürel modeller de saldırı pozunu kullanır (şahin pençeleri vb.)
	if parts.get("player") and parts["player"].has_animation(parts["anims"]["attack"]):
		parts["player"].play(parts["anims"]["attack"], 0.1)
	for sa in parts["root"].find_children("SnakeAnim*", "", true, false):   # yılan: ısırma atılışı
		sa.bite()
	# denge: çağrılar tek başına kuyruklu canavar kesiyordu — seviye çarpanı ve taban düşürüldü, dev hedeflere yarı hasar
	# çağrılan, oyuncunun jutsu gücüyle yarı oranda büyür (yüksek seviyede işe yaramaz kalmasın, tek başına da savaşı bitirmesin)
	var dmg: float = def.get("dmg", 20.0) * 0.5 * (1.0 + float(Game.profile.get("level", 1)) * 0.025) * (1.0 + Stats.skill(Game.profile, "summon_power") + Stats.skill(Game.profile, "squad"))
	if tgt != null and is_instance_valid(tgt) and (tgt.has_method("hit_test") or tgt.get("arch") is Dictionary and (tgt.arch as Dictionary).has("style")):
		dmg *= 0.5
	var model: String = def.get("model", "")
	var pt = _front(height * 0.15)
	if model.begins_with("toad"):
		hop_t = 0.0  # zıpla ve ez
		get_tree().create_timer(0.45).timeout.connect(func():
			if dead:
				return
			var at = _front(height * 0.1)
			FX.impact(at, Color(1, 0.8, 0.5), clampf(height * 0.25, 0.6, 4.0))
			var inf = {"dmg": dmg, "knock": 8.0 + height, "launch": 3.0 + height * 0.3, "kind": "heavy", "hitstop": 0.06, "dir": face_dir()}
			if height > 4.0:   # dev kurbağa: iniş önündeki bütün alanı ezer
				Combat.hit_zone(self, global_position, face_dir(), radius + height * 0.9, 70.0, height, inf)
			else:
				Combat.hit_sphere(self, at, 1.5 + height * 0.35, inf)
			Sfx.play("boom" if height > 5.0 else "punch", at, clampf(1.3 - height * 0.03, 0.5, 1.3))
			if Game.world and height > 5.0:
				Game.world.env.add_shake(clampf(height * 0.05, 0.2, 1.5)))
	elif model.begins_with("snake") or model == "salamander":
		var inf = {"dmg": dmg, "knock": 6.0, "kind": "heavy", "stun": 0.6, "dir": face_dir()}
		if height > 4.0:
			Combat.hit_zone(self, global_position, face_dir(), radius + height * 0.9, 40.0, height, inf)
		else:
			Combat.hit_sphere(self, pt, 1.2 + height * 0.3, inf)
		FX.hit_spark(pt, Color(0.75, 0.5, 1.0), clampf(height * 0.2, 0.6, 3.0))
		if tgt:
			tgt.apply_status("slow", 3.0)
		Sfx.play("whoosh", pt, 0.7)
	elif model.begins_with("slug"):
		_acid(pt, dmg)
	else:
		var inf = {"dmg": dmg, "knock": 4.0 + height * 0.5, "kind": "light" if height < 2.0 else "heavy", "dir": face_dir()}
		if height > 4.0:
			Combat.hit_zone(self, global_position, face_dir(), radius + height * 0.8, 60.0, height, inf)
		else:
			Combat.hit_sphere(self, pt, 1.0 + height * 0.3, inf)
		FX.hit_spark(pt, Color(1, 0.9, 0.7), clampf(height * 0.2, 0.5, 3.0))
		Sfx.play("punch", pt)


## İmza teknikleri: her çağrı kendi tekniğini çağrıldıktan hemen sonra (ilk özel bekleme ~1 sn) ve aralıklarla kullanır.
## Tekniğin adı ekrana yazılır (oyuncu ne olduğunu görsün)
const SIG_NAME := {"toad_small": "Suiton: Kurbağa Tükürüğü", "toad_mid": "Dil Kamçısı", "toad_boss": "Suiton: Teppōdama", "snake_swarm": "Sen'ei Jashu",
	"snake_giant": "Yılan Sarması", "snake_boss": "Hükümdarın Sarması", "slug_acid": "Zesshi Nensan (Asit Püskürtme)", "slug_queen": "Bölünme: Şifa Dalgası",
	"hawk_small": "Keskin Göz", "hawk_mount": "Kanat Fırtınası", "hawk_giant": "Gök Kasırgası", "dog_small": "Ninken Takibi", "dog_pack": "Doton: Ninken Tuzağı",
	"wolf_giant": "Çift Çene Saldırısı", "monkey_small": "Maymun Atlayışı", "crow_flock": "Karga Yanılsaması", "salamander": "Zehir Sisi",
	"turtle_small": "Kabuk Kalkanı", "turtle_giant": "Ada Kabuğu: Dönen Kale", "weasel_trio": "Kamaitachi no Jutsu", "cat_small": "Kedi Pençesi",
	"cat_giant": "Kedi Ruhu Alevi", "spider": "Kumo Shibari (Örümcek Ağı)"}


func _special() -> void:
	var model: String = def.get("model", "")
	var role: String = def.get("role", "")
	var nm = String(SIG_NAME.get(model, ""))
	if nm != "":
		Combat.popup_text(global_position + Vector3.UP * (height + 1.2), nm + "!", Contracts.DEFS[contract]["color"].lightened(0.35))
	var dmg: float = def.get("dmg", 20.0) * 0.6
	match model:
		"toad_mid":
			if tgt:  # dil ile yakala ve çek
				var from = global_position + Vector3.UP * height * 0.5
				VFX.bolt(from, tgt.global_position + Vector3.UP, Color(0.95, 0.45, 0.55), 0.18, 0.3, 0)
				var v = global_position - tgt.global_position
				tgt.velocity = v.normalized() * minf(25.0, v.length() * 2.0) + Vector3.UP * 3.0
				tgt.apply_status("stun", 1.0)
		"toad_small":
			if tgt:   # küçük su mermisi: hasarı az, hedefi kısa süre sersemletir
				_water_gun(tgt, 0.7)
				tgt.apply_status("slow", 1.5)
		"toad_boss":
			_boss_toad_n += 1
			match _boss_toad_n % 3:
				1:
					_water_gun(tgt, 3.0)
				2:
					_toad_oil(tgt)
				0:
					_toad_blade(tgt)
		"snake_swarm":
			if tgt:   # yılanlar kollardan fırlayıp bağlar
				for k in 4:
					var a = TAU * k / 4.0
					VFX.bolt(global_position + Vector3(cos(a), 0.3, sin(a)), tgt.global_position + Vector3.UP, Color(0.55, 0.35, 0.75), 0.12, 0.4, 0)
				tgt.apply_status("bind", 2.0)
				Combat.hit_sphere(self, tgt.global_position + Vector3.UP, 1.2, {"dmg": dmg * 0.5, "knock": 0.0, "kind": "light"})
		"snake_giant", "snake_boss":
			if tgt:  # sarma: uzun bağlama, çevresinde dönen halkalar
				tgt.apply_status("bind", 2.5 + tier)
				Combat.hit_sphere(self, tgt.global_position + Vector3.UP, 2.0 + height * 0.2, {"dmg": dmg * 0.6, "knock": 0.0, "kind": "light"})
				for k in 3:
					FX.ring(tgt.global_position + Vector3.UP * (0.5 + k * 0.6), Color(0.6, 0.4, 0.8), 1.6 + height * 0.1, 0.8, false)
		"slug_acid":
			if tgt:   # dilinden yere asit püskürtür, değdiği yer erir
				var at = tgt.global_position
				for k in 5:
					_acid(at + Vector3(randf_range(-2, 2), 0.3, randf_range(-2, 2)), dmg * 0.4)
		"slug_queen":
			_split_heal()
		"hawk_small":
			if tgt:
				_mark(tgt, Color(1.0, 0.85, 0.3))
				tgt.apply_status("slow", 2.0)
		"hawk_mount", "hawk_giant":
			_gust()
		"dog_small":
			if tgt:   # izini sürüp topuğundan ısırır
				_mark(tgt, Color(1.0, 0.6, 0.3))
				tgt.apply_status("slow", 2.5)
				Combat.hit_sphere(self, tgt.global_position + Vector3.UP * 0.4, 1.2, {"dmg": dmg * 0.6, "knock": 2.0, "kind": "light"})
		"wolf_giant", "dog_pack":
			if tgt:   # köpekler yerden fırlayıp ısırır ve tutar
				var at = tgt.global_position
				for k in 6:
					var q = at + Vector3(cos(k * 1.05), 0, sin(k * 1.05)) * 1.4
					VFX.debris(q, Color(0.5, 0.42, 0.32), 6, 6.0)
				FX.ring(at + Vector3.UP * 0.2, Color(0.55, 0.45, 0.35), 3.0, 0.4)
				tgt.apply_status("bind", 2.0)
				Combat.hit_sphere(self, at + Vector3.UP, 1.8, {"dmg": dmg * 0.7, "knock": 0.0, "kind": "heavy"})
		"monkey_small":
			if tgt:   # havaya sıçrayıp tepeden tekme
				var land = tgt.global_position
				var from = global_position
				var tw = create_tween()
				tw.tween_method(func(x: float):
					if is_instance_valid(self):
						global_position = from.lerp(land, x) + Vector3.UP * sin(x * PI) * 4.0, 0.0, 1.0, 0.5)
				tw.tween_callback(func():
					Combat.hit_sphere(self, land + Vector3.UP, 1.8, {"dmg": dmg * 1.2, "knock": 10.0, "launch": 5.0, "kind": "heavy"})
					FX.impact(land + Vector3.UP * 0.5, Color(1, 0.85, 0.5), 1.0))
		"crow_flock":
			_crow_genjutsu()
		"salamander":
			_poison_mist(global_position + face_dir() * 6.0, 10.0 + height)
		"turtle_small", "turtle_giant":
			_shell(model == "turtle_giant")
		"weasel_trio":
			for i in 3:
				var d = face_dir().rotated(Vector3.UP, (i - 1) * 0.3)
				for k in 5:
					Combat.hit_sphere(self, global_position + Vector3.UP + d * (2.0 + k * 2.5), 1.4, {"dmg": dmg * 0.6, "knock": 6.0, "kind": "light", "element": "fuuton", "dir": d})
				FX.ring(global_position + Vector3.UP + d * 7.0, Color(0.85, 1.0, 0.9), 3.0, 0.3, false, d)
			FX.speed_lines(global_position + Vector3.UP, face_dir())
			Sfx.play("wind", global_position, 1.3)
		"cat_small":
			if tgt:   # üç pençe izi
				for k in 3:
					get_tree().create_timer(k * 0.12).timeout.connect(func():
						if is_instance_valid(tgt) and is_instance_valid(self):
							Combat.hit_sphere(self, tgt.global_position + Vector3.UP, 1.2, {"dmg": dmg * 0.45, "knock": 2.0, "kind": "light"})
							FX.hit_spark(tgt.global_position + Vector3.UP, Color(1, 0.9, 0.7), 0.8))
		"cat_giant":
			if tgt:
				Combat.hit_sphere(self, tgt.global_position + Vector3.UP, 4.0, {"dmg": dmg * 0.8, "knock": 10.0, "kind": "heavy", "element": "katon"})
				FX.impact(tgt.global_position + Vector3.UP, Color(0.35, 0.6, 1.0), 2.5)
				VFX.embers(tgt.global_position + Vector3.UP, Color(0.4, 0.65, 1.0), 20, 6.0, 1.0)
		"spider":
			if tgt:
				tgt.apply_status("bind", 3.0)
				for k in 6:
					var a = TAU * k / 6.0
					VFX.bolt(tgt.global_position + Vector3(cos(a) * 2.2, 0.2, sin(a) * 2.2), tgt.global_position + Vector3.UP * 1.2, Color(0.95, 0.95, 0.9), 0.06, 0.8, 0)
				FX.ring(tgt.global_position + Vector3.UP * 0.5, Color(0.95, 0.95, 0.9), 2.5, 0.6)
		_:
			if role == "fighter" and tgt:
				_attack()


## Karga sürüsü: hedefin çevresinde kargalar dağılır, göz göze gelen sersemler (genjutsu)
func _crow_genjutsu() -> void:
	var c = tgt.global_position if tgt else global_position + face_dir() * 6.0
	for f in get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(self, f) and not f.is_dead() and f.global_position.distance_to(c) < 8.0:
			f.apply_status("stun", 2.0)
	FX.burst(c + Vector3.UP * 1.5, {"amount": 40, "life": 1.2, "add": false, "size": 0.45, "vmin": 3, "vmax": 8,
		"colors": [Color(0.06, 0.06, 0.08, 1), Color(0.1, 0.1, 0.12, 0)]})
	FX.ring(c + Vector3.UP * 1.6, Color(0.75, 0.1, 0.15), 3.5, 0.5, false)


## Kaplumbağa: sahibinin önünde kabuk kalkanı (hasar azaltma); dev olanı kabuğuna çekilip dönerek çarpar
func _shell(giant: bool) -> void:
	if owner_f:
		Buffs.add("summon_tank", 5.0, {"armor": 0.5})
		FX.ring(owner_f.global_position + Vector3.UP * 1.0, Color(0.4, 0.7, 0.5), 2.4, 0.6, false)
	if giant:
		var o = global_position
		var tw = create_tween()
		tw.tween_property(parts["root"], "rotation:y", parts["root"].rotation.y + TAU * 2.0, 1.2)
		for k in 5:
			get_tree().create_timer(k * 0.24).timeout.connect(func():
				if is_instance_valid(self):
					Combat.hit_sphere(self, global_position + Vector3.UP * height * 0.4, radius + height * 0.3, {"dmg": def.get("dmg", 40.0) * 0.5, "knock": 16.0, "launch": 4.0, "kind": "heavy"})
					FX.ring(o + Vector3.UP * 0.4, Color(0.4, 0.6, 0.45), radius + height * 0.6, 0.3))


var _boss_toad_n := 0


## Dev kurbağa: Gamayudan — ağızdan kalın yağ seli; yere yağ gölü (içindekiler yavaşlar, ateşle tutuşur)
func _toad_oil(t: Node3D) -> void:
	if t == null:
		return
	Combat.popup_text(global_position + Vector3.UP * (height + 0.6), "Gamayudan!", Color(1, 0.8, 0.35))
	var from = global_position + (parts["root"].transform.basis * parts.get("mouth", Vector3.UP)) if parts.has("root") else global_position
	var dir = (t.global_position + Vector3.UP - from).normalized()
	for k in 10:
		Combat.hit_sphere(self, from + dir * (1.5 + k * 2.5), 1.6 + height * 0.06, {"dmg": 14.0, "knock": 9.0, "kind": "heavy", "dir": dir})
	FX.burst(from, {"amount": 60, "life": 0.9, "add": false, "size": 1.0 + height * 0.05, "vmin": 14, "vmax": 24, "dir": dir, "spread": 9.0,
		"colors": [Color(0.95, 0.78, 0.3, 0.95), Color(0.75, 0.55, 0.18, 0)]})
	Sfx.play("water", from, 0.6)
	var at = t.global_position
	var pool = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 5.0; cm.bottom_radius = 5.0; cm.height = 0.05
	pool.mesh = cm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.58, 0.18, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pool.material_override = mat
	get_tree().current_scene.add_child(pool)
	pool.global_position = Vector3(at.x, Game.jutsu_floor(at.x, at.z) + 0.04, at.z)
	var tw = pool.create_tween()
	for k in 12:
		tw.tween_callback(func():
			for f in get_tree().get_nodes_in_group("fighters"):
				if Combat.hostile(self, f) and not f.is_dead() and f.global_position.distance_to(pool.global_position) < 5.0:
					f.apply_status("slow", 1.0))
		tw.tween_interval(0.5)
	tw.tween_callback(pool.queue_free)


## Dev kurbağa: belindeki dev kılıçla geniş yatay savuruş
func _toad_blade(t: Node3D) -> void:
	Combat.popup_text(global_position + Vector3.UP * (height + 0.6), "Kurbağa Kılıcı!", Color(0.85, 0.9, 1.0))
	var dir = face_dir() if t == null else (t.global_position - global_position).normalized()
	attack_anim_t = 0.7
	get_tree().create_timer(0.3).timeout.connect(func():
		if dead:
			return
		Combat.hit_zone(self, global_position, dir, radius + height * 1.4, 80.0, height * 0.6, {"dmg": def.get("dmg", 20.0) * 0.9, "knock": 18.0, "launch": 5.0, "kind": "heavy", "dir": dir})
		var c = global_position + Vector3.UP * height * 0.4
		for k in 9:   # beyaz yay izi
			var a = deg_to_rad(-80.0 + k * 20.0)
			var q = c + dir.rotated(Vector3.UP, a) * (radius + height * 1.1)
			FX.burst(q, {"amount": 6, "life": 0.3, "add": true, "size": 0.8 + height * 0.04, "vmin": 1, "vmax": 3, "dir": Vector3.UP, "spread": 30.0,
				"colors": [Color(0.95, 0.97, 1.0, 0.9), Color(0.7, 0.8, 1.0, 0)]})
		Sfx.play("whoosh", c, 0.5)
		if Game.world:
			Game.world.env.add_shake(clampf(height * 0.04, 0.2, 1.0)))


func _water_gun(t: Node3D, scale := 1.0) -> void:
	if t == null:
		return
	var from = global_position + (parts["root"].transform.basis * parts.get("mouth", Vector3.UP)) if parts.has("root") else global_position
	var dir = (t.global_position + Vector3.UP - from).normalized()
	for k in 8:
		Combat.hit_sphere(self, from + dir * (1.0 + k * 2.0 * scale), 0.8 * scale, {"dmg": 10.0 * scale, "knock": 5.0 * scale, "kind": "light", "element": "suiton", "dir": dir})
	FX.burst(from, {"amount": 18, "life": 0.5, "add": false, "size": 0.4 * scale, "vmin": 10, "vmax": 18, "dir": dir, "spread": 6.0,
		"colors": [Color(0.6, 0.85, 1.0, 0.9), Color(0.5, 0.75, 1.0, 0)]})
	Sfx.play("water", from, 1.2)


func _acid(at: Vector3, dmg: float) -> void:
	Combat.hit_sphere(self, at, 1.5 + height * 0.3, {"dmg": dmg, "knock": 3.0, "kind": "light", "element": "suiton"})
	for f in get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(self, f) and not f.is_dead() and f.global_position.distance_to(at) < 2.0 + height * 0.3:
			f.apply_status("slow", 3.0)
	FX.burst(at, {"amount": 26, "life": 0.7, "add": false, "size": 0.5, "vmin": 2, "vmax": 6, "gravity": Vector3(0, -8, 0),
		"colors": [Color(0.6, 0.95, 0.3, 1), Color(0.4, 0.8, 0.2, 0)]})
	Sfx.play("water", at, 0.7)


func _split_heal() -> void:
	# kraliçe: küçük parçalara bölünüp herkesi iyileştirir
	if owner_f == null:
		return
	say("Bölünüyorum! Herkes iyileşsin!", 2.5)
	for i in 6:
		var s = Summon.new()
		s.contract = contract
		s.tier = 0
		s.def = Contracts.DEFS[contract]["tiers"][0]
		s.owner_f = owner_f
		s.team = team
		get_tree().current_scene.add_child(s)
		s.life = 12.0
		s.global_position = global_position + Vector3(cos(i * TAU / 6.0), 0, sin(i * TAU / 6.0)) * (radius + 2.0)
	if owner_f:
		owner_f.hp = minf(owner_f.max_hp, owner_f.hp + owner_f.max_hp * 0.25)
		FX.aura(owner_f, Color(0.5, 1, 0.6), 1.2, Vector3(0, 0.9, 0), 1.5)


func _gust() -> void:
	var c = global_position + face_dir() * (6.0 + height)
	for f in get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(self, f) and not f.is_dead() and f.global_position.distance_to(c) < 6.0 + height * 0.8:
			var d = (f.global_position - global_position).normalized()
			f.take_hit({"dmg": def.get("dmg", 30.0) * 0.7, "knock": 18.0, "launch": 6.0, "kind": "heavy", "element": "fuuton", "dir": d})
	FX.ring(c, Color(0.85, 0.95, 1.0), 6.0 + height * 0.6, 0.5)
	Sfx.play("wind", c, 0.8)


func _poison_mist(at: Vector3, r: float) -> void:
	FX.burst(at + Vector3.UP * 2.0, {"amount": 60, "life": 4.0, "add": false, "size": 3.0, "vmin": 0.5, "vmax": 2.0, "gravity": Vector3(0, 0.3, 0),
		"colors": [Color(0.55, 0.35, 0.65, 0.6), Color(0.4, 0.25, 0.5, 0)]})
	var hits = func():
		for f in get_tree().get_nodes_in_group("fighters"):
			if Combat.hostile(self, f) and not f.is_dead() and f.global_position.distance_to(at) < r:
				f.apply_status("slow", 2.0)
				f.take_hit({"dmg": 6.0, "knock": 0.0, "kind": "light"})
	for k in 4:
		get_tree().create_timer(0.5 + k).timeout.connect(hits)


# ------------------------------------------------------------------ ortak jutsu (oyuncunun elementiyle)
func combo(el: String) -> void:
	if combo_cd > 0.0 or dead:
		return
	var model: String = def.get("model", "")
	var t = tgt if tgt else Combat.nearest_enemy(self, 60.0)
	var from = global_position + parts["root"].transform.basis * parts.get("mouth", Vector3.UP * height * 0.5)
	var dir = owner_f.cam_forward() if (t == null and owner_f is Player) else ((t.global_position + Vector3.UP - from).normalized() if t else face_dir())
	var name = ""
	if model.begins_with("toad") and tier >= 1 and el == "katon":
		name = "Gamayu Endan (Kurbağa Yağı Ateş Mermisi)"
		for k in 14:
			Combat.hit_sphere(self, from + dir * (2.0 + k * 3.0), 2.0 + height * 0.12, {"dmg": 30.0 + height * 4.0, "knock": 10.0, "kind": "heavy", "element": "katon", "dir": dir})
		FX.burst(from + dir * 2.0, {"amount": 80, "life": 1.0, "size": 2.0 + height * 0.1, "vmin": 20, "vmax": 34, "dir": dir, "spread": 8.0,
			"colors": [Color(1.0, 0.85, 0.3, 1), Color(1.0, 0.35, 0.05, 0.9), Color(0.3, 0.1, 0.05, 0)]})
		Sfx.play("fire", from, 0.6)
	elif model.begins_with("slug") and el == "suiton":
		name = "Zesshi Nensan Dalgası (Asit + Su)"
		for k in 10:
			_acid(from + dir * (3.0 + k * 3.0), 25.0 + height * 2.0)
	elif model.begins_with("hawk") and el == "fuuton":
		name = "Şahin Kasırgası (Rüzgar)"
		_gust()
		for k in 10:
			Combat.hit_sphere(self, from + dir * (3.0 + k * 3.0), 3.0, {"dmg": 25.0, "knock": 16.0, "launch": 8.0, "kind": "heavy", "element": "fuuton", "dir": dir})
		FX.speed_lines(from, dir)
	elif (model.begins_with("dog") or model == "wolf_giant") and el == "doton":
		name = "Doton: Tsuiga (Toprak İz Dişleri)"
		var at = t.global_position if t else from + dir * 10.0
		for f in get_tree().get_nodes_in_group("fighters"):
			if Combat.hostile(self, f) and not f.is_dead() and f.global_position.distance_to(at) < 6.0:
				f.apply_status("bind", 3.5)
				f.take_hit({"dmg": 30.0, "knock": 2.0, "kind": "heavy", "element": "doton"})
		FX.ring(at, Color(0.6, 0.45, 0.3), 6.0, 0.6)
	elif model == "salamander" and el == "fuuton":
		name = "Zehirli Sis Fırtınası (Rüzgar + Sis)"
		_poison_mist(from + dir * 12.0, 22.0)
	elif model.begins_with("snake") and el in ["katon", "raiton"]:
		name = "Yılan Ateş Saldırısı" if el == "katon" else "Yılan Şimşek Isırığı"
		if t:
			t.take_hit({"dmg": 45.0 + height * 3.0, "knock": 12.0, "kind": "heavy", "element": el, "stun": 1.0})
	if name != "":
		combo_cd = 8.0
		Combat.popup_text(global_position + Vector3.UP * (height + 1.5), "ORTAK JUTSU: " + name, Color(1.0, 0.85, 0.4))
		Hud.msg("Ortak jutsu: %s" % name, Color(1.0, 0.85, 0.4))


# ------------------------------------------------------------------ maymun kral: elmas asa
func _become_staff() -> void:
	# önce Maymun Kral görünür, sahibine döner ve konuşur; sonra dumanla elmas asaya dönüşüp ele geçer
	say(String(def.get("lines", ["Elmas asaya dönüşüyorum!"]).pick_random()), 2.2)
	await get_tree().create_timer(1.8).timeout
	if dead or not is_instance_valid(owner_f):
		return
	FX.smoke_puff(global_position + Vector3.UP * height * 0.5, 1.4, 22)
	Sfx.play("poof", global_position, 1.0)
	if is_instance_valid(owner_f):
		FX.smoke_puff(owner_f.global_position + Vector3.UP * 1.1, 0.8, 12)
	var pr = Game.profile
	Gear.ensure(pr)
	var prev_r = pr["equip"].get("sag", -1)
	var uid = Gear.grant(pr, "kongo_asa", "", null, null, {"_tmp": true})
	pr["equip"]["sag"] = uid
	Gear.apply_look(pr)
	if Game.player:
		Game.player.rebuild_model()
		await get_tree().process_frame
		if Game.player and Game.player.model:
			Game.player.model.set_drawn(true, false)   # asa elde (kınında/sırtta değil)
	Hud.msg("Maymun Kral elmas asaya dönüştü: asa vuruşta uzar.", Color(0.95, 0.8, 0.35))
	visible = false
	collision_layer = 0
	get_tree().create_timer(minf(life, 45.0)).timeout.connect(func():
		# süre bitti: asa yeniden maymuna döner, sahibinin silahı geri gelir
		if is_instance_valid(owner_f):
			FX.smoke_puff(owner_f.global_position + Vector3.UP * 1.1, 1.0, 14)
		var g = Gear.find(pr, uid)
		if not g.is_empty():
			pr["gear"].erase(g)
		pr["equip"].erase("sag")
		if prev_r != null and int(prev_r) >= 0 and not Gear.find(pr, int(prev_r)).is_empty():
			pr["equip"]["sag"] = int(prev_r)
		Gear.apply_look(pr)
		if Game.player:
			Game.player.rebuild_model()
		dismiss())


# ------------------------------------------------------------------ binme
func _mount_check() -> void:
	if not def.get("mount", false) or not owner_f is Player or dead:
		return
	var pl: Player = owner_f
	var near = pl.global_position.distance_to(global_position) < radius + 3.0 + height * 0.2
	if near and not mounted and not mount_prompt:
		mount_prompt = true
		Combat.popup_text(global_position + Vector3.UP * (height + 1.0), "[F] Bin", Color(1, 0.9, 0.6))
	if not near:
		mount_prompt = false


func _unhandled_input(e: InputEvent) -> void:
	if dead or not def.get("mount", false) or not owner_f is Player:
		return
	if e.is_action_pressed("interact"):
		var pl: Player = owner_f
		if mounted:
			_dismount()
			get_viewport().set_input_as_handled()
		elif pl.global_position.distance_to(global_position) < radius + 3.0 + height * 0.2:
			mounted = true
			_seat = Vector3.INF
			pl.set_meta("riding", self)
			_ride_cam(pl, true)
			say(def["lines"].pick_random(), 2.5)
			get_viewport().set_input_as_handled()
	elif mounted and e.is_action_pressed("attack"):
		cd = 0.0
		tgt = Combat.nearest_enemy(self, 30.0 + height * 2.0, owner_f.cam_forward(), 0.3)
		_attack()
		get_viewport().set_input_as_handled()
	elif mounted and e.is_action_pressed("guard"):
		tgt = Combat.nearest_enemy(self, 40.0 + height * 2.0, owner_f.cam_forward(), 0.3)
		_special()
		get_viewport().set_input_as_handled()


func _dismount() -> void:
	if not mounted:
		return
	mounted = false
	if owner_f is Player and is_instance_valid(owner_f):
		_ride_cam(owner_f, false)
		owner_f.remove_meta("riding")
		owner_f.global_position = global_position + face_dir().rotated(Vector3.UP, PI * 0.5) * (radius + 1.5)
		owner_f.velocity = Vector3.UP * 6.0


## Binekte kamera: hayvanın boyuna göre uzak ve yüksek, tekerle boyuna göre yakınlaştırma; inince eski haline döner
func _ride_cam(pl: Player, on: bool) -> void:
	if on:
		pl.set_meta("ride_cam", [pl.cam_dist, pl.cam_lift, pl.cam_range, pl.cam_giant])
		var hh = maxf(2.0, height)
		pl.cam_range = Vector2(maxf(2.2, hh * 0.8), maxf(14.0, hh * 3.0))
		pl.cam_dist = clampf(hh * 1.7 + 4.0, 6.0, pl.cam_range.y)
		pl.cam_lift = hh * 0.35
		pl.cam_giant = hh > 6.0
	elif pl.has_meta("ride_cam"):
		var sv: Array = pl.get_meta("ride_cam")
		pl.cam_dist = sv[0]
		pl.cam_lift = sv[1]
		pl.cam_range = sv[2]
		pl.cam_giant = sv[3]
		pl.remove_meta("ride_cam")


## Binildiğinde oyuncu yön verir; uçanlar Space ile yükselir, Ctrl ile alçalır
var _seat := Vector3.INF


## Binme noktası (kök uzayında): görsel mesh köşelerinden en üst %12'lik bandın ortası, yüzeyin hemen üstü
func _seat_local() -> Vector3:
	var head_only = def.get("seat") is String and def["seat"] == "head"   # kabuğu bitkili kaplumbağa: kafanın üstü
	if def.has("seat") and not head_only:   # tepede bacak eklemi olanlar: elle verilen nokta (boy oranı)
		var sv: Vector3 = def["seat"]
		return Vector3(sv.x * height, sv.y * height, sv.z * height)
	var root: Node3D = parts["root"]
	var inv = root.global_transform.affine_inverse()
	var pts := PackedVector3Array()
	var top = -1e9
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or not mi.visible:
			continue
		var xf = inv * mi.global_transform
		for si in mi.mesh.get_surface_count():
			var arr = mi.mesh.surface_get_arrays(si)
			var vv = arr[Mesh.ARRAY_VERTEX]
			if vv == null:
				continue
			var step = maxi(1, (vv as PackedVector3Array).size() / 4000)
			for k in range(0, vv.size(), step):
				var q = xf * vv[k]
				pts.append(q)
				top = maxf(top, q.y)
	if pts.is_empty():
		return Vector3(0, height * 0.95, 0)
	if head_only:
		# modelin ön ucu (-Z) bandındaki noktalar
		var zmin = 1e9
		for q in pts:
			zmin = minf(zmin, q.z)
		var front := PackedVector3Array()
		top = -1e9
		for q in pts:
			if q.z < zmin + height * 0.22:
				front.append(q)
				top = maxf(top, q.y)
		pts = front
	var band = maxf(0.15, height * 0.12)
	var sum = Vector3.ZERO
	var n = 0
	for q in pts:
		if q.y >= top - band:
			sum += q
			n += 1
	var c = sum / maxi(n, 1)
	return Vector3(c.x, lerpf(c.y, top, 0.35), c.z)   # boynuz/diken uçları değil, kafa/sırt yüzeyi


func _ride(dt: float) -> void:
	var pl: Player = owner_f
	var wish = pl.wish_dir()
	var spd: float = def.get("speed", 10.0) * 1.3
	if wish.length() > 0.1:
		facing = lerp_angle(facing, atan2(-wish.x, -wish.z), minf(1.0, dt * 4.0))
	velocity.x = wish.x * spd
	velocity.z = wish.z * spd
	if def.get("fly", false):
		var vy = 0.0
		if Input.is_action_pressed("jump"):
			vy = 9.0
		elif Input.is_action_pressed("leap"):
			vy = -9.0
		velocity.y = vy
		var gh = Game.jutsu_floor(global_position.x, global_position.z)
		if global_position.y < gh + 1.0:
			global_position.y = gh + 1.0
	else:
		velocity.y -= 32.0 * dt
		if wish.length() > 0.1 and def.get("model", "").begins_with("toad") and hop_t < 0.0:
			hop_t = 0.0
	move_and_slide()
	_ground()
	# oyuncu sırtta / başta: modelin gerçek tepe yüzeyine oturur (eskiden sabit yükseklik gövdenin içine düşüyor, karakter kayboluyordu)
	if _seat == Vector3.INF:
		_seat = _seat_local()
	var root: Node3D = parts["root"]
	pl.global_position = root.global_transform * _seat
	pl.velocity = Vector3.ZERO
	pl.facing = facing


# ------------------------------------------------------------------ prosedürel animasyon
func _animate(dt: float) -> void:
	anim_t += dt
	var root: Node3D = parts["root"]
	root.rotation.y = facing
	var moving = Vector2(velocity.x, velocity.z).length() > 0.5
	if parts["anim"] != "model":
		attack_anim_t = maxf(0.0, attack_anim_t - dt)
	match parts["anim"]:
		"model":  # hazır modelin kendi animasyonları
			var ap: AnimationPlayer = parts.get("player")
			if ap and attack_anim_t <= 0.0:
				var want = parts["anims"]["move"] if moving else parts["anims"]["idle"]
				if ap.current_animation != want and ap.has_animation(want):
					ap.play(want, 0.25)
			attack_anim_t -= dt
		"static":  # animasyonsuz hayran modeli: nefes + yürürken sallanma
			var sfn: Node3D = parts.get("sf")
			if sfn:
				var br = 1.0 + sin(anim_t * 1.6) * 0.015
				sfn.scale = Vector3(1.0, br, 1.0)
				sfn.rotation.z = sin(anim_t * 8.0) * 0.05 if moving else lerpf(sfn.rotation.z, 0.0, dt * 4.0)
				sfn.position.y = absf(sin(anim_t * 8.0)) * height * 0.04 if moving else 0.0
		"hop":
			if hop_t >= 0.0:
				hop_t += dt / clampf(0.4 + height * 0.03, 0.4, 0.9)
				var k = clampf(hop_t, 0.0, 1.0)
				root.position.y = sin(k * PI) * height * 0.35
				for l in parts["legs"]:
					l.rotation.x = -sin(k * PI) * 0.8
				if hop_t >= 1.0:
					hop_t = -1.0
			elif moving and not mounted:
				hop_t = 0.0
			else:
				root.position.y = sin(anim_t * 2.0) * height * 0.01  # nefes
		"slither":
			var segs: Array = parts["segments"]
			var amp = clampf(height * 0.35, 0.3, 4.0)
			for i in segs.size():
				var s: Node3D = segs[i]
				s.position.x = sin(anim_t * (6.0 if moving else 1.5) - i * 0.55) * amp * (float(i) / segs.size() + 0.15)
			if parts["head"]:
				parts["head"].position.y = height * 1.1 + sin(anim_t * 1.3) * height * 0.08
		"crawl":
			var b: Node3D = parts["segments"][0]
			var sq = sin(anim_t * (5.0 if moving else 1.2))
			b.scale = Vector3(1.0 - sq * 0.04, 1.0 + sq * 0.05, 1.0 + sq * 0.06)
			if parts["head"]:
				parts["head"].rotation.x = sin(anim_t * 1.7) * 0.15
		"fly":
			var flap = sin(anim_t * (9.0 if height < 2.0 else 4.0))
			for i in parts["wings"].size():
				var w: Node3D = parts["wings"][i]
				w.rotation.z = flap * 0.6 * (1.0 if i == 0 else -1.0)
			root.position.y = flap * height * 0.05
			# ayaklar: uçarken geriye toplanır; saldırıda pençeler öne uzanıp açılır, dururken hafif salınır
			var grab = clampf(attack_anim_t * 2.0, 0.0, 1.0) if "attack_anim_t" in self else 0.0
			for i in parts["legs"].size():
				var lg: Node3D = parts["legs"][i]
				var tuck = 0.9 if moving else 0.25
				lg.rotation.x = lerpf(tuck, -0.9, grab) + sin(anim_t * 3.0 + i) * 0.08
		"walk":
			var sw = sin(anim_t * (9.0 if moving else 0.0))
			for i in parts["legs"].size():
				parts["legs"][i].rotation.x = sw * 0.5 * (1.0 if i % 2 == 0 else -1.0) * (1.0 if i < 2 else -1.0)
			if parts["tail"]:
				parts["tail"].rotation.y = sin(anim_t * 3.0) * 0.3
		"biped":
			var sw = sin(anim_t * (8.0 if moving else 1.0))
			for i in parts["legs"].size():
				parts["legs"][i].rotation.x = sw * 0.6 * (1.0 if i == 0 else -1.0)
			root.position.y = absf(sw) * height * 0.04 if moving else 0.0
		"flock":
			for i in parts["segments"].size():
				var n: Node3D = parts["segments"][i]
				n.position.y = (1.5 + sin(anim_t * 2.0 + i) * 0.6) if def.get("fly", false) else 0.0
				n.rotation.y = sin(anim_t * 1.5 + i * 1.3) * 0.8
		"spider":
			for i in parts["legs"].size():
				parts["legs"][i].rotation.x = sin(anim_t * (12.0 if moving else 1.0) + i * 0.8) * 0.25
