extends RefCounted
## ELLE YAPILMIŞ SİLAH KOMBOLARI — TEK KAYIT. Oyuncu (PlayerCombat) ve yapay zekâ (Enemy) ikisi de buradan okur:
## yeni bir silah animasyonu (X_anim.gd, steps() -> 5-6 adım) yalnız buraya eklenir, düşmanlar da otomatik kullanır.
## [adım betiği, hız çarpanı]
const TABLE := {
	"samehada": [preload("res://scripts/combat/samehada_anim.gd"), 1.3],
	"gunbai": [preload("res://scripts/combat/gunbai_anim.gd"), 1.05],   # ağır silah ritmi
	"kunai": [preload("res://scripts/combat/kunai_anim.gd"), 1.0],
	"raijin": [preload("res://scripts/combat/raijin_anim.gd"), 1.0],
	"uc_tirpan": [preload("res://scripts/combat/tirpan_anim.gd"), 1.0],
	"shibuki": [preload("res://scripts/combat/shibuki_anim.gd"), 1.0],
}
## iki elli adımlarda sol elin sağ yumruktan sap boyunca uzaklığı
const TWO_OFF := {"uc_tirpan": 0.42, "shibuki": 0.2}   # shibuki: sağ el sapın arka ucunda, sol el önde (ruloya yakın)


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
	if bool(mods(id, i).get("pull", false)) and h is CharacterBody3D:
		h.velocity = (who.global_position - h.global_position).normalized() * 9.0 + Vector3.UP * 2.0


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
