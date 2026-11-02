extends RefCounted
## ELLE YAPILMIŞ SİLAH KOMBOLARI — TEK KAYIT. Oyuncu (PlayerCombat) ve yapay zekâ (Enemy) ikisi de buradan okur:
## yeni bir silah animasyonu (X_anim.gd, steps() -> 5-6 adım) yalnız buraya eklenir, düşmanlar da otomatik kullanır.
## [adım betiği, hız çarpanı]
const TABLE := {
	"samehada": [preload("res://scripts/combat/samehada_kombo.gd"), 1.05],   # yeni ağır kombo (eski video kombosu samehada_anim.gd)
	"gunbai": [preload("res://scripts/combat/gunbai_anim.gd"), 1.05],   # ağır silah ritmi
	"kunai": [preload("res://scripts/combat/kunai_anim.gd"), 1.0],
	"raijin": [preload("res://scripts/combat/raijin_anim.gd"), 1.0],
	"uc_tirpan": [preload("res://scripts/combat/tirpan_anim.gd"), 1.0],
	"shibuki": [preload("res://scripts/combat/shibuki_anim.gd"), 1.0],
	"kabutowari": [preload("res://scripts/combat/kabuto_anim.gd"), 1.0],
	"chakra_bicak": [preload("res://scripts/combat/asuma_anim.gd"), 1.0],
	"ruzgar_bicak": [preload("res://scripts/combat/ruzgar_anim.gd"), 1.0],
	"sai": [preload("res://scripts/combat/sai_anim.gd"), 1.0],
}
## iki elli adımlarda sol elin sağ yumruktan sap boyunca uzaklığı
const TWO_OFF := {"uc_tirpan": 0.42, "shibuki": 0.2, "samehada": 0.3}   # shibuki: sağ el sapın arka ucunda, sol el önde (ruloya yakın)


static func has(id: String) -> bool:
	return TABLE.has(id)


static func steps(id: String) -> Array:
	return TABLE[id][0].steps()


static func speed(id: String) -> float:
	return float(TABLE[id][1])


static func two_off(id: String) -> float:
	return float(TWO_OFF.get(id, 0.32))


## Adım değiştiricileri — oyuncu ve düşman AYNI: heavy (yere serer), knock, launch, stun, pull (kanca çekişi), reach_add,
## lunge_mul (kurulurken kayma), special (silah özelliğini ez: "" = yok). Görsel/alan etkileri on_strike'ta.
static func mods(id: String, i: int) -> Dictionary:
	match id:
		"uc_tirpan":
			var m = {"lunge_mul": 0.5}
			match i:
				1: m.merge({"heavy": true, "knock": 3.0})
				2: m.merge({"pull": true, "knock": 0.5})
				3: m.merge({"stun": 0.6, "knock": 2.0})
				4: m.merge({"launch": 12.0, "knock": 2.0})
				5: m.merge({"reach_add": 0.6, "knock": 18.0, "heavy": true})
			return m
		"samehada":
			# rendeler + chakra emer (silahın "drain" özelliği kalır); ağır: kurulurken kaymaz
			var m = {"lunge_mul": 0.55, "eat": true, "special": ""}   # emme _samehada_eat'te (genel "drain" iki kez emmesin)   # her isabet: chakra yer, jutsuyu yutar, buff/pelerin söker, doyup büyür
			match i:
				0: m.merge({"knock": 2.0})
				1: m.merge({"heavy": true, "knock": 14.0})
				2: m.merge({"knock": 6.0, "reach_add": 1.4})                    # canlı atılış: menzil uzar
				3: m.merge({"launch": 11.0, "knock": 2.0})
				4: m.merge({"heavy": true, "launch": 9.0, "knock": 7.0, "reach_add": 0.4, "lunge_mul": 0.0})   # havadan yere çakar
				5: m.merge({"heavy": true, "knock": 16.0, "launch": 8.5})   # öne yere çarpılıp savrulur (yakın dövüşte launch >= 8 olmazsa yere sermez, sadece iter)
			return m
		"sai":
			# çevik çift sai: kilitleme (sersemletir), topuz darbesi, çift saplama
			var m = {"lunge_mul": 1.0}
			match i:
				2: m.merge({"stun": 0.8, "knock": 0.5, "pull": true})   # yan dişlerle kilitleyip çeker
				3: m.merge({"heavy": true, "knock": 9.0})                 # topuz darbesi
				4: m.merge({"launch": 8.5, "knock": 2.0})
				5: m.merge({"heavy": true, "knock": 13.0, "reach_add": 0.4})
			return m
		"chakra_bicak":
			# Asuma muştaları: hızlı; bitiriş Hien (chakra akışı: menzil uzar, sert)
			var m = {"lunge_mul": 1.0}
			match i:
				2: m.merge({"launch": 9.0, "knock": 2.0})
				4: m.merge({"knock": 8.0})
				5: m.merge({"heavy": true, "knock": 14.0, "reach_add": 1.6})
			return m
		"ruzgar_bicak":
			# her vuruş fuuton: rüzgar kesiği on_strike'ta ileri uçar
			var m = {"lunge_mul": 0.8, "element": "fuuton"}
			match i:
				2: m.merge({"launch": 9.0, "knock": 2.0})
				3: m.merge({"knock": 9.0, "reach_add": 0.6})
				5: m.merge({"heavy": true, "knock": 16.0})
			return m
		"kabutowari":
			# zırh kırıcı (silahın armor_break özelliği her vuruşta); ağır: kurulurken kaymaz
			var m = {"lunge_mul": 0.5}
			match i:
				0: m.merge({"heavy": true, "knock": 3.0})
				1: m.merge({"heavy": true, "knock": 12.0})
				2: m.merge({"pull": true, "knock": 1.0})
				3: m.merge({"heavy": true, "stun": 0.9, "knock": 6.0, "shatter": true})
				4: m.merge({"heavy": true, "knock": 3.0})
				5: m.merge({"heavy": true, "launch": 10.0, "knock": 5.0, "shatter": true, "reach_add": 0.4})
			return m
		"shibuki":
			# patlamalar on_strike'ta (her vuruşta kendi biçimi): silahın genel "explode" özelliği iki kez patlamasın
			var m = {"lunge_mul": 0.6, "special": ""}
			match i:
				0: m.merge({"knock": 6.0})
				1: m.merge({"heavy": true, "stun": 0.4, "knock": 3.0})
				2: m.merge({"knock": 2.0})
				3: m.merge({"heavy": true, "knock": 12.0})
				4: m.merge({"knock": 14.0, "reach_add": 0.3})
				5: m.merge({"heavy": true, "launch": 6.0, "knock": 4.0})
			return m
	return {}


## İsabet eden hedefe adım etkisi (kanca çekişi)
static func on_target(id: String, i: int, who: Node3D, h: Node3D) -> void:
	var m = mods(id, i)
	if bool(m.get("pull", false)) and h is CharacterBody3D:
		h.velocity = (who.global_position - h.global_position).normalized() * 9.0 + Vector3.UP * 2.0
	if bool(m.get("eat", false)):
		_samehada_eat(who, h, i == 5)
	if bool(m.get("shatter", false)):
		_shatter(who, h)
	if bool(m.get("throw_back", false)) and h is CharacterBody3D:
		# Samehada bitiriş: saplı rakip başın üstünden arkaya savrulup yere çarpar
		var f: Vector3 = who.face_dir() if who.has_method("face_dir") else -who.global_transform.basis.z
		f.y = 0
		h.velocity = -f.normalized() * 9.0 + Vector3.UP * 11.0


## Vuruş anı etkileri (isabet olsun olmasın): zemin, patlama, uçan kâğıt; alan hasarı who adına (oyuncu ve düşman aynı)
static func on_strike(id: String, i: int, who: Node3D, dmg: float) -> void:
	if who == null or not is_instance_valid(who):
		return
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else -who.global_transform.basis.z
	f.y = 0
	f = f.normalized()
	var side = Vector3.UP.cross(f).normalized()
	var gp = func(d: float, s := 0.0) -> Vector3:
		var q = who.global_position + f * d + side * s
		q.y = Game.ground_height(q.x, q.z) + 0.05
		return q
	match id:
		"chakra_bicak":
			if i == 5:   # Hien: bıçaklara chakra akar — mavi-beyaz uzayan ağız izi
				var q = gp.call(1.6) + Vector3.UP * 1.2
				for k in 2:
					var sx = -0.35 + k * 0.7
					WindFX.streak(func(t: float) -> Vector3: return q + side * sx + f * t * 2.6, 0.18, 0.09, Color(0.75, 0.9, 1.0, 0.9), k * 0.04, 12)
				VFX.star(q + f * 1.8, Color(0.8, 0.92, 1.0), 2.4, 0.16)
				_shake(who, 0.4)
		"ruzgar_bicak":
			_wind_slash(who, i, f, side, dmg)
		"kabutowari":
			match i:
				2:   # çift darbe: kancadan sonra çekiç önde yere iner
					who.get_tree().create_timer(0.24).timeout.connect(func():
						if is_instance_valid(who):
							var q = gp.call(1.7, 0.3)
							VFX.cracks(q, 1.8)
							VFX.debris(q, Color(0.5, 0.45, 0.4), 8, 5.0, 0.3)
							_shake(who, 0.35))
				3:   # kama çakma: çekiç baltanın sırtına çarpar — metal kıvılcım + beyaz flaş
					var q = gp.call(1.6) + Vector3.UP * 1.2
					VFX.star(q, Color(1, 1, 1), 3.6, 0.2)
					FX.burst(q, {"amount": 22, "life": 0.4, "tex": FX.tex_spark, "size": 0.5, "vmin": 5, "vmax": 11, "colors": [Color(1, 0.95, 0.7, 1), Color(1, 0.6, 0.2, 0)]})
					_shake(who, 0.6)
				5:   # Kabuto Wari: balta yere çakılır, çekiç sırtına iner — önde uzun yarık
					for k in 5:
						who.get_tree().create_timer(k * 0.05).timeout.connect(func():
							if is_instance_valid(who):
								var q = gp.call(1.8 + k * 1.2)
								VFX.cracks(q, 2.4 - k * 0.2)
								VFX.debris(q, Color(0.5, 0.45, 0.4), 6, 6.0, 0.35))
					VFX.star(gp.call(1.8) + Vector3.UP * 0.6, Color(1, 1, 1), 3.2, 0.2)
					_shake(who, 0.8)
		"samehada":
			var blue = Color(0.45, 0.75, 1.0)
			match i:
				0:   # rende: temas boyunca mavi chakra kıvılcımları
					for k in 3:
						who.get_tree().create_timer(0.12 * (k + 1)).timeout.connect(func():
							if is_instance_valid(who):
								FX.hit_spark(gp.call(1.8, 0.3 - k * 0.3) + Vector3.UP * 0.7, blue, 1.0))
				1:
					VFX.star(gp.call(1.8) + Vector3.UP * 1.2, Color(1, 1, 1), 2.6, 0.18)
					_shake(who, 0.5)
				2:   # canlı atılış: Samehada kendi kabarıp ileri atılır (kısa süre büyür), uçta mavi ısırık
					_swell(who, 1.25, 0.1, 0.15)
					VFX.star(gp.call(3.2) + Vector3.UP * 1.0, blue, 2.8, 0.18)
				3:   # ısırık: pullar dikene döner (dikenli mavi patlama)
					var q = gp.call(1.6) + Vector3.UP * 2.0
					VFX.star(q, blue, 3.4, 0.22)
					FX.burst(q, {"amount": 18, "life": 0.45, "tex": FX.tex_spark, "size": 0.6, "vmin": 4, "vmax": 9, "colors": [Color(0.85, 0.95, 1, 1), Color(0.35, 0.6, 1, 0)]})
					_shake(who, 0.35)
				4:   # havadan iniş: önde çatlak + şok
					var q = gp.call(2.0)
					VFX.cracks(q, 2.6)
					VFX.shockwave(q + Vector3.UP * 0.1, blue, 4.5, 0.35)
					VFX.debris(q, Color(0.5, 0.45, 0.4), 10, 6.0, 0.3)
					_shake(who, 0.55)
				5:   # Ziyafet: öndeki yere çarpış
					var q = gp.call(2.2)
					VFX.cracks(q, 2.8)
					VFX.shockwave(q + Vector3.UP * 0.1, blue, 5.0, 0.4)
					VFX.debris(q, Color(0.5, 0.45, 0.4), 12, 7.0, 0.35)
					_shake(who, 0.6)
		"uc_tirpan":
			if i == 3:
				var q = gp.call(2.3)
				VFX.cracks(q, 3.2)
				VFX.debris(q, Color(0.45, 0.38, 0.3), 12, 7.0, 0.35)
				FX.impact(q, Color(0.75, 0.65, 0.5), 0.9)
				_shake(who, 0.45)
		"shibuki":
			match i:
				0:   # yay boyunca üç küçük patlama (sağdan sola)
					for k in 3:
						_boom(who, gp.call(1.9, -1.1 + k * 1.1) + Vector3.UP * 0.9, 0.5, dmg * 0.4, 1.4, k * 0.05)
				1:   # rulo yere: patlama + çatlak
					var q = gp.call(1.8, -0.5)
					VFX.cracks(q, 2.6)
					_boom(who, q + Vector3.UP * 0.3, 0.8, dmg * 0.6, 2.0, 0.0, 5.0)
					_shake(who, 0.4)
				2:   # beş kâğıt yelpaze gibi uçar, düşer, sırayla patlar
					for k in 5:
						var a = deg_to_rad(-36.0 + k * 18.0)
						var dir = (f * cos(a) + side * sin(a)).normalized()
						var land = who.global_position + dir * randf_range(3.2, 5.8)
						land.y = Game.ground_height(land.x, land.z) + 0.05
						_fly_tag(who, who.global_position + Vector3.UP * 2.0 + f * 0.8, land, 0.35 + k * 0.05, dmg * 0.45)
				3:   # ters savuruş: tek büyük patlama baş hizasında
					_boom(who, gp.call(1.8) + Vector3.UP * 1.4, 0.95, dmg * 0.7, 2.2, 0.0)
					_shake(who, 0.35)
				4:   # rulo ucunda patlama; itişi kullanıcıyı da geri iter
					_boom(who, gp.call(2.3) + Vector3.UP * 1.0, 0.75, dmg * 0.6, 1.8, 0.0)
					if who is CharacterBody3D:
						who.velocity += -f * 7.0 + Vector3.UP * 1.5
				5:   # kâğıt yere damga: ileri doğru büyüyen beş patlamalık zincir
					VFX.cracks(gp.call(1.6), 2.4)
					for k in 5:
						_boom(who, gp.call(1.6 + k * 1.3) + Vector3.UP * 0.4, 0.55 + k * 0.12, dmg * 0.6, 1.6 + k * 0.15, 0.08 + k * 0.11, 3.0 if k == 4 else 1.5)
					_shake(who, 0.6)


static func _shake(who: Node3D, a: float) -> void:
	if who is Player and Game.world:
		Game.world.env.add_shake(a)


## Patlama (gecikmeli olabilir): ateşli patlama görseli + alan hasarı (sahibini ve dostlarını vurmaz: Combat.hit_sphere)
static func _boom(who: Node3D, pos: Vector3, s: float, dmg: float, r: float, delay: float, launch := 2.0) -> void:
	var fire = func():
		if not is_instance_valid(who):
			return
		FX.explosion(pos, s)
		Combat.hit_sphere(who, pos, r, {"dmg": dmg, "knock": 7.0, "launch": launch, "kind": "heavy", "burn": 1.5, "hitstop": 0.03})
	if delay <= 0.0:
		fire.call()
	else:
		who.get_tree().create_timer(delay).timeout.connect(fire)


static var _tag_fly_mat: StandardMaterial3D
## Uçan mühür kâğıdı: kavisle düşer, yere yapışır, kısa bekleyip patlar
static func _fly_tag(who: Node3D, from: Vector3, to: Vector3, dur: float, dmg: float) -> void:
	if _tag_fly_mat == null:
		_tag_fly_mat = StandardMaterial3D.new()
		_tag_fly_mat.albedo_texture = load("res://assets/weapons/shibuki_tag.png")
		_tag_fly_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		_tag_fly_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_tag_fly_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var q = MeshInstance3D.new()
	var qm = QuadMesh.new()
	qm.size = Vector2(0.16, 0.4)
	q.mesh = qm
	q.material_override = _tag_fly_mat
	who.get_tree().current_scene.add_child(q)
	q.global_position = from
	var spin = randf_range(6.0, 11.0)
	var tw = q.create_tween()
	tw.tween_method(func(t: float):
		if is_instance_valid(q):
			q.global_position = from.lerp(to, t) + Vector3.UP * sin(t * PI) * 1.4
			q.rotation = Vector3(t * spin, t * spin * 0.6, 0.0) if t < 0.95 else Vector3(-PI * 0.5, 0, 0), 0.0, 1.0, dur)
	tw.tween_interval(0.35)   # yere yapışık bekler
	tw.tween_callback(func():
		if is_instance_valid(q):
			q.queue_free()
		_boom(who, to + Vector3.UP * 0.3, 0.6, dmg, 1.6, 0.0))


## Adım başlarken (oyuncu _start_step / düşman _swing_keyed): sıçrama, Samehada'nın sargısını açıp büyümesi vb.
static func on_start(id: String, i: int, who: Node3D) -> void:
	if who == null or not is_instance_valid(who):
		return
	match id:
		"samehada":
			if i == 4 and who is CharacterBody3D:   # Havada Ezme: fırlayan rakibin peşinden sıçra
				who.velocity.y = 8.5
				var f: Vector3 = who.face_dir() if who.has_method("face_dir") else Vector3.ZERO
				who.velocity.x += f.x * 2.5
				who.velocity.z += f.z * 2.5
			if i == 5:   # Ziyafet: sargı açılır (pullu canlı hali), kılıç büyür; bitince sarılıp küçülür
				_unwrap(who, 1.6)
				_swell(who, 1.3, 0.25, 1.2)


static func _weapon_node(who: Node3D) -> Node3D:
	var m = who.get("model")
	if m == null or m.get("weapons") == null or (m.weapons as Array).is_empty():
		return null
	var n = m.weapons[0]["node"]
	return n if is_instance_valid(n) else null


## Samehada'nın boyu: doyma (6 sn) × anlık kabarma
static func _apply_size(who: Node3D) -> void:
	var n = _weapon_node(who)
	if n == null:
		return
	var sat = int(who.get_meta("same_sat", 0))
	var sw = float(who.get_meta("same_swell", 1.0))
	n.scale = Vector3.ONE * (1.0 + 0.06 * sat) * sw


## Anlık kabarma: rise sn'de s katına, hold sn tutar, geri iner
static func _swell(who: Node3D, s: float, rise: float, hold: float) -> void:
	var tw = who.create_tween()
	tw.tween_method(func(v: float):
		if is_instance_valid(who):
			who.set_meta("same_swell", v)
			_apply_size(who), 1.0, s, rise)
	tw.tween_interval(hold)
	tw.tween_method(func(v: float):
		if is_instance_valid(who):
			who.set_meta("same_swell", v)
			_apply_size(who), s, 1.0, 0.35)


## Sargıyı aç: pullu canlı Samehada modeline geç, dur sn sonra sargılıya dön
static func _unwrap(who: Node3D, dur: float) -> void:
	var n = _weapon_node(who)
	if not (n is MeshInstance3D):
		return
	(n as MeshInstance3D).mesh = CharacterModel.weapon_mesh("samehada_acik")
	FX.burst(n.global_position, {"amount": 14, "life": 0.5, "size": 0.5, "vmin": 2, "vmax": 5, "colors": [Color(0.95, 0.95, 0.9, 1), Color(0.8, 0.8, 0.75, 0)]})   # sargı parçaları
	who.get_tree().create_timer(dur).timeout.connect(func():
		if is_instance_valid(n):
			(n as MeshInstance3D).mesh = CharacterModel.weapon_mesh("samehada"))


## Samehada yer (kanon): rakibin chakrasını emer (sahibine geçer), mühür yapıyorsa jutsusunu yutar (iptal), buff / chakra
## pelerinlerini söker; her isabette doyar ve büyür (6 sn yemezse eski boyu). Ziyafet'te çok daha fazla emer.
static func _samehada_eat(who: Node3D, h: Node3D, feast: bool) -> void:
	if not is_instance_valid(who) or not is_instance_valid(h):
		return
	var blue = Color(0.45, 0.75, 1.0)
	var take = 18.0 if feast else 6.0
	var got = 0.0
	if h is Player:
		got = minf(take, h.chakra)
		h.chakra = maxf(0.0, h.chakra - take)
		if h.combat and String(h.combat.get("action")) == "cast":   # mühür yaparken: jutsu yutuldu
			h.combat.action = ""
			h.model.overlay.set_pose("seal", 0.0)
			Combat.popup_text(h.global_position + Vector3.UP * 2.2, "Jutsu yutuldu!", blue)
		if Buffs.active.keys().any(func(k): return k in Buffs.MODE_GROUP or k == "beast"):
			Buffs.clear_modes()
			Buffs.remove("beast")
			Combat.popup_text(h.global_position + Vector3.UP * 2.5, "Chakra pelerini yenildi!", blue)
	else:
		if "chakra" in h:
			got = minf(take, float(h.chakra))
			h.chakra = maxf(0.0, float(h.chakra) - take)
		else:
			got = take * 0.5
		if String(h.get("state")) == "cast":
			h.state = "hitstun"
			h.state_t = 0.0
			if h.get("model"):
				h.model.overlay.set_pose("seal", 0.0)
			Combat.popup_text(h.global_position + Vector3.UP * 2.2, "Jutsu yutuldu!", blue)
		if h.get("buffs") is Dictionary and not (h.buffs as Dictionary).is_empty():
			h.buffs.clear()
			Combat.popup_text(h.global_position + Vector3.UP * 2.5, "Güçlendirme yenildi!", blue)
	# sahibine geçer
	if who is Player:
		who.chakra = minf(who.max_chakra, who.chakra + maxf(got, 2.0))
	elif "chakra" in who:
		who.chakra = float(who.chakra) + maxf(got, 2.0)
	# doyma: büyür (en fazla 5 kademe), 6 sn yemezse küçülür
	var sat = mini(5, int(who.get_meta("same_sat", 0)) + (2 if feast else 1))
	who.set_meta("same_sat", sat)
	who.set_meta("same_sat_until", Time.get_ticks_msec() + 6000)
	_apply_size(who)
	who.get_tree().create_timer(6.05).timeout.connect(func():
		if is_instance_valid(who) and Time.get_ticks_msec() >= int(who.get_meta("same_sat_until", 0)):
			who.set_meta("same_sat", 0)
			_apply_size(who))
	# rakipten sahibine akan mavi chakra (Ziyafet'te uzun akış)
	var n = 6 if feast else 2
	for k in n:
		who.get_tree().create_timer(k * 0.06).timeout.connect(func():
			if is_instance_valid(who) and is_instance_valid(h):
				var a = h.global_position + Vector3.UP * 1.2
				var b = who.global_position + Vector3.UP * 1.2
				for j in 4:
					FX.hit_spark(a.lerp(b, (j + 1) / 5.0), blue, 0.5))


## Kabutowari "miğfer kıran": savunmayı ve zırh buff'larını parçalar (oyuncu: zırh/kalkan jutsuları; AI: kendi buff'ları + blok)
static func _shatter(who: Node3D, h: Node3D) -> void:
	if not is_instance_valid(h):
		return
	var broke = false
	if h is Player:
		for k in Buffs.active.keys():
			if float((Buffs.active[k]["mods"] as Dictionary).get("armor", 1.0)) < 1.0:
				Buffs.remove(k)
				broke = true
		if h.combat and String(h.combat.get("action")) == "guard":
			h.combat.action = ""
			broke = true
	else:
		if h.get("buffs") is Dictionary:
			for k in (h.buffs as Dictionary).keys():
				if float((h.buffs[k]["mods"] as Dictionary).get("armor", 1.0)) < 1.0:
					h.buffs.erase(k)
					broke = true
		if h.get("guarding"):
			h.guarding = false
			broke = true
		if h.has_method("apply_status"):
			h.apply_status("armor_broken", 5.0)
	if broke:
		Combat.popup_text(h.global_position + Vector3.UP * 2.4, "Zırh Kırıldı!", Color(1, 0.8, 0.4))


## Rüzgar Chakra Bıçağı: her savuruşta ileri uçan rüzgar kesiği — görsel (perde + akım çizgileri) ve yol boyunca fuuton hasarı
## (oyuncu da düşman da). i: adım (1 hilal çapraz, 2 yatay, 3 yükselen, 4 mızrak, 5 çift hilal, 6 dev dikey)
static func _wind_slash(who: Node3D, i: int, f: Vector3, side: Vector3, dmg: float) -> void:
	var from = who.global_position + Vector3.UP * 1.2 + f * 0.8
	var length = [7.0, 7.0, 6.0, 10.0, 7.0, 13.0][clampi(i, 0, 5)]
	var width = [3.0, 4.0, 2.6, 1.2, 3.0, 5.5][clampi(i, 0, 5)]
	var lift = [0.0, 0.0, 1.2, 0.0, 0.0, 0.0][clampi(i, 0, 5)]
	var fire = func(delay: float):
		var go = func():
			if not is_instance_valid(who):
				return
			WindFX.gust(from, f, length, width, {"n": 10, "sheets": 3 if i < 5 else 6, "speed": 38.0, "lift": lift, "leaves": i == 5, "dust": i == 5})
			# yol boyunca isabet (yakın vuruşun ötesindeki düşmanlar da kesilir)
			var info = {"dmg": dmg * (0.45 if i < 5 else 0.9), "element": "fuuton", "knock": 6.0 if i < 5 else 14.0, "launch": 4.0 if i == 2 else 0.0,
				"kind": "heavy" if i == 5 else "light", "hitstop": 0.02}
			var hit_once: Array = []
			for k in 4:
				var c = from + f * (2.0 + k * (length - 2.0) / 3.0)
				for h in Combat.hit_sphere(who, c, width * 0.4 + 0.6, info, hit_once):
					hit_once.append(h)
					FX.hit_spark(h.global_position + Vector3.UP, Color(0.7, 1.0, 0.85), 1.0)
			if i == 5:
				_shake(who, 0.55)
		if delay <= 0.0:
			go.call()
		else:
			who.get_tree().create_timer(delay).timeout.connect(go)
	fire.call(0.0)
	if i == 4:   # çift hilal: ikinci kesik
		fire.call(0.16)
