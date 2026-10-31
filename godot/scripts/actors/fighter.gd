class_name Fighter
extends CharacterBody3D
## NPC savaşçılarının tabanı (düşmanlar, klonlar, çağrılar): kapsül hitbox (boyuta göre), arazi takibi,
## hasar/sersemleme/savrulma, durum etkileri, animasyon.

var team = "enemy"
var radius = 0.38
var height = 1.8
var size = 1.0
var max_hp = 100.0
var hp = 100.0
var element = ""
var power = 1.0
var model: CharacterModel
var look = {}
var facing = 0.0
var grounded = true
var state = "idle"
var state_t = 0.0
var statuses = {}  # ad -> kalan süre
var dead = false
var poise = 0.0  # süper zırh (boss)
## Sersemletme kilidi kırıcı: kısa sürede üst üste sersemletilen savaşçı bir süre sersemlemez ve çevresini iterek kurtulur
## (klonlar ya da sonsuz hafif kombo ile kilitlenmesin)
var stun_meter := 0.0
var stun_last_ms := 0
var stun_armor_ms := 0


func _ready() -> void:
	add_to_group("fighters")
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	_build_body()


func _build_body() -> void:
	var cs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = radius * size
	cap.height = maxf(height * size, cap.radius * 2.0 + 0.01)
	cs.shape = cap
	cs.position.y = height * size * 0.5
	add_child(cs)
	radius *= size
	height *= size
	if model == null and look != null:
		model = CharacterModel.new()
		add_child(model)
		model.setup(look)
		model.scale = Vector3.ONE * size * float(model.age_scale)   # çocuk klon çocuk boyunda (ölçek yaşı eziyordu)


func is_dead() -> bool:
	return dead


func face_dir() -> Vector3:
	return Vector3(-sin(facing), 0, -cos(facing))


func apply_status(name: String, dur: float) -> void:
	dur = Combat.cc_dur(self, name, dur)
	if dur <= 0.0:
		return
	statuses[name] = maxf(statuses.get(name, 0.0), dur)


func has_status(name: String) -> bool:
	return statuses.get(name, 0.0) > 0.0


func take_hit(info: Dictionary) -> void:
	if dead:
		return
	var em = Combat.element_mult(info.get("element", ""), element)
	var react = Elements.on_hit(self, info)
	var dmg: float = info.get("dmg", 5.0) * em * react * Combat.jutsu_factor(info)
	if has_status("marked"):
		dmg *= 1.25   # Dinamik İşaretleme / algılama: işaretli hedef fazla hasar alır
	var atk = info.get("attacker")
	if atk is Player:
		var bs = Stats.skill(Game.profile, "backstab")
		if bs > 0.0:
			var from_atk = (atk.global_position - global_position)
			from_atk.y = 0
			var unaware = get("target") == null
			if unaware or face_dir().dot(from_atk.normalized()) < -0.3:
				dmg *= 1.0 + bs * 2.0
				Combat.popup_text(global_position + Vector3.UP * (height + 0.8), "ARKADAN!", Color(1, 0.4, 0.8))
	hp -= dmg
	# Shintenshin: ele geçirilmiş bedene gelen acı, bedenin dışındaki Yamanaka ruhuna da yansır (anime)
	if has_meta("possessed_by"):
		var owner_p = get_meta("possessed_by")
		if is_instance_valid(owner_p) and owner_p is Player and owner_p.hp > 0.0:
			owner_p.hp = maxf(1.0, owner_p.hp - dmg * 0.35)
			Combat.damage_number(owner_p.global_position + Vector3.UP * 2.0, dmg * 0.35, Color(0.8, 0.6, 1.0))
	model.flash(0.9)
	_hit_feedback(info, dmg)
	var col = Color(1, 0.9, 0.3) if info.get("kind", "light") == "light" else Color(1, 0.55, 0.2)
	# element etkinliği: renk + yazı
	var eff = em * react
	if info.get("element", "") != "" and info.get("attacker") is Player and dmg >= 3.0 and absf(react - 1.0) < 0.01:
		if eff >= 1.25:
			col = Color(1, 0.35, 0.15)
			Combat.popup_text(global_position + Vector3.UP * (height + 0.9), "Etkili!", Color(1, 0.6, 0.2))
		elif eff <= 0.8:
			col = Color(0.65, 0.68, 0.75)
			Combat.popup_text(global_position + Vector3.UP * (height + 0.9), "Zayıf...", Color(0.7, 0.72, 0.8))
	Combat.damage_number(global_position + Vector3.UP * (height + 0.3), dmg, col, info.get("kind", "") == "heavy" or eff >= 1.25)
	if info.get("burn", 0.0) > 0.0:
		apply_status("burn", info["burn"])
	if info.get("stun", 0.0) > 0.0:
		apply_status("stun", info["stun"])
	if info.get("slow", 0.0) > 0.0:
		apply_status("slow", info["slow"])
	on_damaged(info)
	if hp <= 0.0:
		hp = 0.0
		die(info)
		return
	var dir: Vector3 = info.get("dir", Vector3.ZERO)
	var heavy: bool = info.get("kind", "light") == "heavy" or info.get("launch", 0.0) > 0.0
	if poise > 0.0 and not heavy:
		return
	if info.get("flinch", false):   # klon gibi zayıf vuruş: sadece irkilme, sersemletmez
		model.flash(0.5)
		velocity += dir * 1.5
		return
	var now = Time.get_ticks_msec()
	if now < stun_armor_ms:
		return   # kilit kırıldı: kısa süre sersemlemez (hasar yine alınır)
	# oyuncunun kendi kombosu (5 vuruş + bitiriş) tam oynansın; klon/çoklu saldırı yağmuru kilidi kırar
	var w = 0.55 if info.get("attacker") is Player else 1.0
	stun_meter = maxf(0.0, stun_meter - (now - stun_last_ms) / 1000.0 * 0.7) + (2.0 if heavy else 1.0) * w
	stun_last_ms = now
	if stun_meter >= 3.5 and size < 2.5:
		_break_stun()
		return
	state_t = 0.0
	if model and model.get("overlay"):
		# darbe: mühür / sıçrama / blok pozunda kalmasın (o pozda donuyordu)
		for pz in ["seal", "leap", "guard", "cast", "charge"]:
			model.overlay.set_pose(pz, 0.0)
	if heavy and size < 2.5:
		state = "knockdown"
		velocity = dir * info.get("knock", 8.0) / size + Vector3.UP * (info.get("launch", 0.0) + 3.0)
		model.play("knock", 0.05, 1.2, true)
	else:
		state = "hitstun"
		velocity = dir * info.get("knock", 2.0) / size
		model.play("hit" if randf() < 0.5 else "hit_head", 0.04, 1.4, true)


## Kilit kırma: chakra patlamasıyla çevresini iter, 1.6 sn sersemlemez
func _break_stun() -> void:
	stun_meter = 0.0
	stun_armor_ms = Time.get_ticks_msec() + 1600
	state = "chase" if "target" in self else state
	state_t = 0.0
	Combat.popup_text(global_position + Vector3.UP * (height + 0.9), "Kurtuldu!", Color(0.7, 0.9, 1.0))
	FX.ring(global_position + Vector3.UP * 0.9, Color(0.7, 0.9, 1.0), 4.0, 0.35)
	for f in get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(self, f) and not f.is_dead() and f.global_position.distance_to(global_position) < 3.2:
			if f is ShadowClone:
				f.vanish()
			else:
				f.take_hit({"dmg": 4.0, "knock": 12.0, "kind": "light", "dir": (f.global_position - global_position).normalized(), "attacker": self})


## Her darbede: gövde savrulması (zırhlı/zayıf vuruşta da hafif) + kan (kesici silahta daha çok, ateş/şimşek jutsusunda yok)
func _hit_feedback(info: Dictionary, dmg: float) -> void:
	var dir: Vector3 = info.get("dir", Vector3.ZERO)
	var heavy: bool = info.get("kind", "light") == "heavy" or info.get("launch", 0.0) > 0.0
	var amp = clampf(dmg / maxf(1.0, max_hp) * 6.0, 0.55, 1.0) * (1.3 if heavy else 1.0) / maxf(1.0, size * 0.7)
	if model and model.has_method("react"):
		model.react(dir, amp, randf() < 0.35)
	if dmg >= 1.0 and not info.get("no_blood", false) and String(info.get("element", "")) not in ["katon", "raiton"] and not is_in_group("no_blood"):
		var cut = String(info.get("weapon_style", "")) in ["blade", "sword", "heavy", "sickle", "claw", "dual", "chain"] or info.get("blade", false)
		FX.blood(global_position + Vector3.UP * height * 0.62, dir, clampf(dmg / maxf(1.0, max_hp) * 5.0, 0.3, 1.0) * (1.4 if cut else 0.8))


func on_damaged(_info: Dictionary) -> void:
	pass


func die(_info: Dictionary) -> void:
	dead = true
	state = "dead"
	model.play("death", 0.1)
	collision_layer = 0
	# cesedin altında kan gölü yayılır (ceset kalkınca söner); dev yaratıklar/klonlar hariç
	if size < 2.5 and not self is ShadowClone:
		get_tree().create_timer(0.8).timeout.connect(func():
			if is_instance_valid(self):
				FX.blood_pool(self, 1.1 + randf() * 0.4))
	remove_from_group("fighters")
	var tw = create_tween()
	# dōjutsu sahibi (göz alınabilsin) ve üstü aranabilir ceset (ganimet) bir süre yerde kalır
	tw.tween_interval(90.0 if has_meta("loot") else (45.0 if has_meta("eyes") else 3.0))
	tw.tween_callback(func(): FX.smoke_puff(global_position + Vector3.UP * 0.5, 0.8, 10))
	tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(queue_free)


func stagger(t: float) -> void:
	state = "hitstun"
	state_t = -t
	model.play("hit", 0.05, 0.8, true)


## Hareket + arazi; wish: istenen yatay hız
func step_move(wish: Vector3, dt: float, turn := true) -> void:
	var slow = 0.45 if has_status("slow") else 1.0
	var hv = Vector3(velocity.x, 0, velocity.z)
	if state in ["hitstun", "knockdown", "dead"]:
		hv = hv.move_toward(Vector3.ZERO, dt * (8.0 if state == "knockdown" else 25.0))
	else:
		hv = hv.lerp(wish * slow, minf(1.0, dt * 10.0))
	velocity.x = hv.x; velocity.z = hv.z
	velocity.y -= 32.0 * dt
	var pre = global_position
	move_and_slide()
	var g = Game.ground_height(global_position.x, global_position.z)
	# uçuruma ışınlanma yok: adımda aşılamayacak dik arazi yatay hareketi durdurur
	var horiz = Vector2(global_position.x - pre.x, global_position.z - pre.z).length()
	if horiz > 0.0005 and g - minf(pre.y, global_position.y) > maxf(0.45, horiz * 1.4):
		global_position = Vector3(pre.x, global_position.y, pre.z)
		velocity.x = 0.0; velocity.z = 0.0
		g = Game.ground_height(global_position.x, global_position.z)
	var snap = maxf(0.3, hv.length() * dt * 1.6)
	if grounded and velocity.y <= 0 and global_position.y > g and global_position.y - g < snap:
		global_position.y = g
	if global_position.y <= g and velocity.y <= 0:
		global_position.y = g
		velocity.y = 0
		grounded = true
	else:
		grounded = is_on_floor()
	if turn and hv.length() > 0.5 and state not in ["hitstun", "knockdown", "dead"]:
		facing = lerp_angle(facing, atan2(-hv.x, -hv.z), minf(1.0, dt * 10.0))
	model.rotation.y = facing


var _env_t = 0.0


func tick_status(dt: float) -> void:
	_env_t -= dt
	if _env_t <= 0.0:
		_env_t = 0.5
		Elements.env_tick(self, 0.5)
	if randf() < dt * 3.0:
		var hp_ = global_position + Vector3.UP * randf_range(0.4, height)
		if has_status("wet"):
			FX.burst(hp_, {"amount": 2, "life": 0.5, "size": 0.25, "vmin": 0.2, "vmax": 0.6, "gravity": Vector3(0, -9, 0),
				"colors": [Color(0.7, 0.85, 1, 0.9), Color(0.5, 0.7, 1, 0)]})
		if has_status("frozen") or has_status("chill"):
			FX.burst(hp_, {"amount": 3, "life": 0.7, "tex": FX.tex_spark, "size": 0.4, "vmin": 0.3, "vmax": 1.0,
				"colors": [Color(0.9, 0.98, 1, 1), Color(0.7, 0.9, 1, 0)]})
		if has_status("shock"):
			FX.hit_spark(hp_, Color(0.7, 0.85, 1.0), 0.4)
		if has_status("mud"):
			FX.burst(global_position + Vector3.UP * 0.3, {"amount": 2, "life": 0.6, "add": false, "size": 0.3, "vmin": 0.2, "vmax": 0.5,
				"gravity": Vector3(0, -6, 0), "colors": [Color(0.4, 0.3, 0.2, 1), Color(0.35, 0.25, 0.18, 0)]})
	for k in statuses.keys():
		statuses[k] -= dt
		if statuses[k] <= 0.0:
			statuses.erase(k)
	if has_status("burn"):
		hp -= 4.0 * dt
		if randf() < dt * 8.0:
			FX.burst(global_position + Vector3.UP * randf_range(0.3, height), {"amount": 3, "life": 0.5, "size": 0.6, "vmin": 1, "vmax": 2, "gravity": Vector3(0, 3, 0),
				"colors": [Color(1, 0.8, 0.3, 1), Color(1, 0.3, 0.05, 0)]})
		if hp <= 0.0 and not dead:
			die({})
