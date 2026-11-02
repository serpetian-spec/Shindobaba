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
	"hiraishin_kunai": [preload("res://scripts/combat/hiraishin_anim.gd"), 1.0],
	"homatsu_kiseru": [preload("res://scripts/combat/kiseru_anim.gd"), 1.0],
}
## silah ağırlığı (0 hafif .. 1 ağır): kol/silah yaylanması (PoseOverlay.key_mass) — ağır silah gecikip taşar
const MASS := {"uc_tirpan": 1.0, "samehada": 0.9, "kabutowari": 0.9, "shibuki": 0.85, "gunbai": 0.8, "raijin": 0.35, "kunai": 0.1,
	"sai": 0.2, "chakra_bicak": 0.25, "ruzgar_bicak": 0.1, "hiraishin_kunai": 0.15, "homatsu_kiseru": 0.3}


static func mass(id: String) -> float:
	return float(MASS.get(id, 0.5))


## iki elli adımlarda sol elin sağ yumruktan sap boyunca uzaklığı
const TWO_OFF := {"uc_tirpan": 0.42, "shibuki": 0.2, "samehada": 0.3, "homatsu_kiseru": 0.3}   # shibuki: sağ el sapın arka ucunda, sol el önde (ruloya yakın)


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
		"homatsu_kiseru":
			# kabarcıklar asıl hasarı verir (on_strike); yakın vuruş yalnız boru darbesi
			var m = {"lunge_mul": 0.0}
			match i:
				2: m.merge({"lunge_mul": 0.8, "knock": 6.0, "heavy": true})
			return m
		"hiraishin_kunai":
			# her isabet işaret koyar (on_target); 3 ve 5. adım ışınlanır (on_start); bitiriş flaşlı çoklu kesik (on_strike)
			var m = {"lunge_mul": 1.0, "mark": true}
			match i:
				2: m.merge({"knock": 5.0, "lunge_mul": 0.0})
				3: m.merge({"launch": 9.0, "knock": 2.0})
				4: m.merge({"lunge_mul": 0.0})
				5: m.merge({"heavy": true, "knock": 14.0, "lunge_mul": 0.0})
			return m
		"sai":
			# saplama silahı: kilitleme, yükselen saplama, çift delik
			var m = {"lunge_mul": 1.0}
			match i:
				3: m.merge({"stun": 0.8, "knock": 1.0})                   # yakala ve sapla
				4: m.merge({"launch": 9.0, "knock": 2.0})                 # yükselen saplama: havaya
				5: m.merge({"heavy": true, "knock": 12.0, "reach_add": 0.4})   # çift delik
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
	if bool(m.get("mark", false)) and h.has_method("apply_status"):
		h.apply_status("marked", 12.0)   # Hiraishin işareti (shiki): işaretli hedef fazla hasar alır, ışınlanma ona gider
		h.set_meta("hiraishin_by", who.get_instance_id())
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
		"homatsu_kiseru":
			_kiseru_strike(who, i, dmg)
		"hiraishin_kunai":
			if i == 5:   # Hiraishin Giri: hedefin çevresinde art arda üç flaşla belirip keser
				var tg = _hira_target(who)
				if tg != null:
					for k in 3:
						who.get_tree().create_timer(0.04 + k * 0.09).timeout.connect(func():
							if is_instance_valid(who) and is_instance_valid(tg):
								var a = TAU * k / 3.0 + 0.6
								_blink(who, tg, Vector3(cos(a), 0, sin(a)) * 1.4)
								Combat.hit_sphere(who, tg.global_position + Vector3.UP, 1.2, {"dmg": dmg * 0.4, "knock": 2.0, "kind": "light", "hitstop": 0.03, "melee": true}))
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
		"hiraishin_kunai":
			if i == 2 or i == 4:   # Hiraishin: hedefin (işaretli olanı önce) arkasında / yanında sarı flaşla belir
				var tg = _hira_target(who)
				if tg != null:
					var back = tg.global_position - who.global_position
					back.y = 0
					back = back.normalized() if back.length() > 0.01 else Vector3.FORWARD
					var side = Vector3.UP.cross(back)
					_blink(who, tg, back * 1.3 if i == 2 else side * 1.3)
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


## Hiraishin hedefi: bu ninjanın işaretlediği (öncelikli) ya da 14 m içindeki en yakın düşman
static func _hira_target(who: Node3D) -> Node3D:
	var best: Node3D = null
	var bd = 14.0
	var my = who.get_instance_id()
	for f in who.get_tree().get_nodes_in_group("fighters"):
		if f == who or not Combat.hostile(who, f) or f.is_dead():
			continue
		var d = f.global_position.distance_to(who.global_position)
		if f.has_meta("hiraishin_by") and int(f.get_meta("hiraishin_by")) == my and f.has_method("has_status") and f.has_status("marked"):
			d *= 0.3   # işaretli hedef öncelikli
		if d < bd:
			bd = d
			best = f
	return best


## Sarı flaş ışınlanma: eski yerde ve yeni yerde sarı parlama + kıvılcım, hedefin yanına (off) ışınlan, ona dön
static func _blink(who: Node3D, tg: Node3D, off: Vector3) -> void:
	var yel = Color(1.0, 0.88, 0.3)
	var from = who.global_position + Vector3.UP
	VFX.star(from, yel, 2.4, 0.12)
	FX.burst(from, {"amount": 14, "life": 0.3, "tex": FX.tex_spark, "size": 0.5, "vmin": 3, "vmax": 8, "colors": [Color(1, 1, 0.8, 1), Color(1, 0.8, 0.2, 0)]})
	var to = tg.global_position + off
	to.y = Game.ground_height(to.x, to.z)
	who.global_position = to
	if who is CharacterBody3D:
		who.velocity = Vector3.ZERO
	var d = tg.global_position - to
	d.y = 0
	if d.length() > 0.01:
		var yaw = atan2(-d.x, -d.z)
		if who is Player:
			who.facing = yaw
		elif "facing" in who:
			who.facing = yaw
	VFX.star(to + Vector3.UP, yel, 2.8, 0.14)
	FX.burst(to + Vector3.UP, {"amount": 18, "life": 0.35, "tex": FX.tex_spark, "size": 0.55, "vmin": 2, "vmax": 7, "colors": [Color(1, 1, 0.85, 1), Color(1, 0.75, 0.15, 0)]})
	Sfx.play("whoosh", to, 1.6, 0.6)


# ------------------------------------------------------------------ Hōmatsu Kiseru (kabarcık borusu)
## Kabarcıklar borunun çanından çıkar ve hedefe süzülür. Oyuncu ve düşman aynı (suiton).
static func _kiseru_bell(who: Node3D) -> Vector3:
	var n = _weapon_node(who)
	if n == null:
		return who.global_position + Vector3.UP * 1.3
	return n.to_global(Vector3(0, 0, 0.74))


## Tek kabarcık uçuşu: çandan, hafif yükselip dalgalanarak hedef noktaya (fn: anlık hedef) süzülür; varınca arrive(pos) çağrılır
static func _bub_fly(who: Node3D, size: float, dur: float, fn: Callable, arrive: Callable, delay := 0.0, arc := 0.6) -> void:
	var go = func():
		if not is_instance_valid(who):
			return
		var from = _kiseru_bell(who)
		var b = VFX.soap_bubble(size)
		who.get_tree().current_scene.add_child(b)
		b.global_position = from
		var ph = randf() * TAU
		var tw = b.create_tween()
		tw.tween_method(func(k: float):
			if not is_instance_valid(b):
				return
			var to: Vector3 = fn.call()
			var p = from.lerp(to, k) + Vector3.UP * sin(k * PI) * arc + Vector3(sin(k * 9.0 + ph), cos(k * 7.0 + ph) * 0.5, cos(k * 8.0 + ph)) * 0.08 * size
			b.global_position = p
			b.scale = Vector3.ONE * size * (0.35 + 0.65 * minf(1.0, k * 4.0)), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func():
			if is_instance_valid(b):
				var p = b.global_position
				b.queue_free()
				arrive.call(p))
	if delay <= 0.0:
		go.call()
	else:
		who.get_tree().create_timer(delay).timeout.connect(go)


static func _bub_pop(p: Vector3, s: float) -> void:
	VFX.bubble_pop(p, clampf(s * 0.4, 0.12, 2.4))   # doğal köpük patlaması (duman/toz yok)


static func _kiseru_strike(who: Node3D, i: int, dmg: float) -> void:
	var tg = _hira_target(who)
	var f: Vector3 = who.face_dir() if who.has_method("face_dir") else -who.global_transform.basis.z
	var aim_fn = _kiseru_aim.bind(who, tg, f)
	match i:
		0:   # Köpük Akışı: 10 küçük kabarcık art arda; her biri hedefte patlar (küçük hasar)
			for k in 10:
				var sz = randf_range(0.12, 0.3)
				var jit = Vector3(randf_range(-0.6, 0.6), randf_range(-0.3, 0.5), randf_range(-0.6, 0.6))
				_bub_fly(who, sz, randf_range(0.55, 0.8), _kiseru_aim_off.bind(who, tg, f, jit), _arrive_small.bind(who, sz, dmg), k * 0.04, 0.3)
		1:   # Patlayan Köpük: kocaman kabarcık yavaş süzülür, hedefte patlar (sert)
			_bub_fly(who, 0.85, 1.1, aim_fn, _arrive_big.bind(who, dmg), 0.0, 0.4)
		2:   # Boru Darbesi: çan çarpınca kabarcık püskürür
			var bp = _kiseru_bell(who)
			for k in 6:
				var b = VFX.soap_bubble(randf_range(0.1, 0.25))
				who.get_tree().current_scene.add_child(b)
				b.global_position = bp
				var to = bp + Vector3(randf_range(-1, 1), randf_range(0.2, 1.2), randf_range(-1, 1))
				var tw = b.create_tween()
				tw.tween_property(b, "global_position", to, randf_range(0.5, 0.9)).set_ease(Tween.EASE_OUT)
				tw.tween_callback(_pop_free.bind(b, 0.5))
		3:   # Köpük Kafesi: dev kabarcık hedefe süzülür, içine alır ve hapseder (sersemletme), sonra patlar
			_bub_fly(who, 0.6, 0.8, aim_fn, _arrive_cage.bind(who, tg, dmg), 0.0, 0.3)
		4:   # Asit Yağmuru: kabarcıklar yukarı yay çizip hedefin çevresine düşer, aşındırır (yavaşlatma + hasar)
			for k in 8:
				var off = Vector3(randf_range(-1.6, 1.6), -0.6, randf_range(-1.6, 1.6))
				var sz = randf_range(0.25, 0.5)
				_bub_fly(who, sz, randf_range(0.9, 1.2), _kiseru_aim_off.bind(who, tg, f, off), _arrive_acid.bind(who, sz, dmg), k * 0.06, 2.2)
		5:   # Köpük Seli: 22 kabarcık hedefin çevresine dolar, sonra zincirleme patlar
			var bubs: Array = []
			for k in 22:
				var sz = [0.15, 0.25, 0.35, 0.5, 0.7][k % 5]
				var a = TAU * k / 22.0
				var ring = Vector3(cos(a), randf_range(-0.3, 0.9), sin(a)) * randf_range(0.8, 1.8)
				_bub_fly(who, sz, randf_range(0.7, 1.0), _kiseru_aim_off.bind(who, tg, f, ring), _arrive_park.bind(who, sz, bubs), k * 0.035, 0.4)
			who.get_tree().create_timer(1.75).timeout.connect(_chain_pop.bind(who, bubs, dmg))


static func _kiseru_aim(who: Node3D, tg: Node3D, f: Vector3) -> Vector3:
	if tg != null and is_instance_valid(tg):
		return tg.global_position + Vector3.UP * 1.0
	if is_instance_valid(who):
		return who.global_position + f * 8.0 + Vector3.UP * 1.2
	return Vector3.ZERO


static func _kiseru_aim_off(who: Node3D, tg: Node3D, f: Vector3, off: Vector3) -> Vector3:
	return _kiseru_aim(who, tg, f) + off


static func _kinfo(dmg: float, mul: float, extra := {}) -> Dictionary:
	var d = {"dmg": dmg * mul, "element": "suiton", "knock": 3.0, "kind": "light", "hitstop": 0.02}
	d.merge(extra, true)
	return d


static func _pop_free(b: Node3D, s: float) -> void:
	if is_instance_valid(b):
		_bub_pop(b.global_position, s)
		b.queue_free()


static func _arrive_small(p: Vector3, who: Node3D, sz: float, dmg: float) -> void:
	_bub_pop(p, sz * 2.0)
	if is_instance_valid(who):
		Combat.hit_sphere(who, p, 0.7, _kinfo(dmg, 0.4, {"knock": 1.0}))


static func _arrive_big(p: Vector3, who: Node3D, dmg: float) -> void:
	_bub_pop(p, 2.2)
	if is_instance_valid(who):
		Combat.hit_sphere(who, p, 2.0, _kinfo(dmg, 2.4, {"knock": 9.0, "launch": 3.0, "kind": "heavy"}))
		_shake(who, 0.4)


static func _arrive_cage(p: Vector3, who: Node3D, tg: Node3D, dmg: float) -> void:
	if not is_instance_valid(who):
		return
	if tg == null or not is_instance_valid(tg):
		_bub_pop(p, 1.5)
		return
	var cage = VFX.soap_bubble(2.4)
	who.get_tree().current_scene.add_child(cage)
	cage.global_position = tg.global_position + Vector3.UP * 0.95
	if tg.has_method("apply_status"):
		tg.apply_status("stun", 1.6)
		tg.apply_status("wet", 6.0)
	Combat.hit_sphere(who, cage.global_position, 1.0, _kinfo(dmg, 1.0, {"knock": 0.0, "stun": 1.6}))
	var tw = cage.create_tween()
	tw.tween_method(_cage_follow.bind(cage, tg), 0.0, 1.0, 1.6)
	tw.tween_callback(_pop_free.bind(cage, 3.0))


static func _cage_follow(k: float, cage: Node3D, tg: Node3D) -> void:
	if is_instance_valid(cage) and is_instance_valid(tg):
		cage.global_position = tg.global_position + Vector3.UP * 0.95
		cage.scale = Vector3.ONE * 2.4 * (1.0 + sin(k * 18.0) * 0.02)


static func _arrive_acid(p: Vector3, who: Node3D, sz: float, dmg: float) -> void:
	_bub_pop(p, sz * 2.5)
	FX.burst(p, {"amount": 6, "life": 0.5, "tex": FX.tex_spark, "add": false, "size": 0.06, "vmin": 0.5, "vmax": 1.5, "gravity": Vector3(0, -9, 0),
		"colors": [Color(0.8, 1.0, 0.55, 0.9), Color(0.65, 0.9, 0.4, 0)]})   # aşındırıcı damlacıklar
	if is_instance_valid(who):
		for h in Combat.hit_sphere(who, p, 1.1, _kinfo(dmg, 0.6, {"knock": 0.5})):
			if h.has_method("apply_status"):
				h.apply_status("slow", 3.0)


static func _arrive_park(p: Vector3, who: Node3D, sz: float, bubs: Array) -> void:
	if not is_instance_valid(who):
		return
	var b = VFX.soap_bubble(sz)
	who.get_tree().current_scene.add_child(b)
	b.global_position = p
	bubs.append(b)


static func _chain_pop(who: Node3D, bubs: Array, dmg: float) -> void:
	if not is_instance_valid(who):
		for b in bubs:
			if is_instance_valid(b):
				b.queue_free()
		return
	var idx = 0
	for b in bubs:
		who.get_tree().create_timer(idx * 0.04).timeout.connect(_chain_one.bind(who, b, dmg))
		idx += 1
	_shake(who, 0.6)


static func _chain_one(who: Node3D, b: Node3D, dmg: float) -> void:
	if not is_instance_valid(b):
		return
	var p = b.global_position
	b.queue_free()
	_bub_pop(p, 1.6)
	if is_instance_valid(who):
		Combat.hit_sphere(who, p, 1.0, _kinfo(dmg, 0.45, {"knock": 4.0}))
