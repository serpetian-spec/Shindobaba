class_name Amaterasu
extends RefCounted
## Amaterasu'nun TEK ortak sistemi (jutsu, Mangekyō göz tuşu, düşman, Tensha Fūin): kanon kuralları burada.
## - Bakılan odak noktasında ANINDA tutuşur (uçan bir şey yok); hedefi sarar ya da yerde yanar.
## - Su / Suiton söndürmez (Elements._black_flame); hedef kül olana dek yanar (oyunda: süre).
## - Kaçış yalnız yeterli hızla: yer değiştirme / shunshin / ani atılma alevi yerinde bırakır (Sasuke'nin deri değiştirmesi).
## - Hedef ölünce alev yerde yanmaya devam eder; yerdeki alevin içine giren tutuşur.
## - Yalnız sahibi söndürebilir / şekil verebilir: Enton: Kagutsuchi bu kayıttaki alevleri kullanır (spots_of).

const TICK := 0.2
const SHED_DIST := 4.5    # bir tikte (0.2 sn) bu kadar yer değiştiren alevden sıyrılır (~22 m/sn: yürümek/koşmak yetmez)
static var spots: Array = []   # her kayıt: {owner, target, pos, until, node, last, info}


static func _tree() -> SceneTree:
	return Engine.get_main_loop()


static func _alive(n) -> bool:
	return n != null and is_instance_valid(n) and n is Node3D and not n.is_dead()


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Tutuştur: target varsa onu sarar, yoksa pos'ta yerde yanar. info: her tikteki hasar (attacker dahil).
static func ignite(owner: Node3D, target: Node3D, pos: Vector3, dur: float, info: Dictionary) -> Dictionary:
	var spot = {"owner": owner, "target": null, "pos": pos, "until": _now() + dur, "node": null, "last": pos, "info": info}
	if _alive(target):
		# zaten Amaterasu ile yanıyorsa süresini uzat (ikinci alev üst üste binmez)
		for s in spots:
			if s["target"] == target:
				s["until"] = maxf(s["until"], _now() + dur)
				target.apply_status("burn", dur)
				return s
		spot["target"] = target
		spot["last"] = target.global_position
		var fl = VFX.black_flames(maxf(1.2, float(target.get("height")) * 0.75) if target.get("height") != null else 1.3)
		target.add_child(fl)
		fl.position = Vector3(0, 0.1, 0)
		spot["node"] = fl
		target.apply_status("burn", dur)
		target.set_meta("black_flame", true)
	else:
		var fl = VFX.black_flames(1.6)
		_tree().current_scene.add_child(fl)
		fl.global_position = pos
		spot["node"] = fl
	VFX.black_smolder(pos, 1.8, minf(dur, 8.0))
	# tutuşma anı: odakta kara alev patlar (mor konturlu kor)
	VFX.puffs(pos + Vector3.UP, {"amount": 26, "life": 0.7, "size": 1.3, "vmin": 1, "vmax": 4, "gravity": Vector3(0, 3, 0), "glow": 1.0,
		"outline_col": Color(0.4, 0.05, 0.45), "colors": [Color(0.12, 0.02, 0.15, 1), Color(0.05, 0.0, 0.08, 1), Color(0.02, 0.0, 0.03, 0)]})
	spots.append(spot)
	_schedule(spot)
	return spot


static func _schedule(spot: Dictionary) -> void:
	_tree().create_timer(TICK).timeout.connect(func(): _tick(spot))


static func _tick(spot: Dictionary) -> void:
	if not spot in spots:
		return
	var owner = spot["owner"]
	var tg = spot["target"]
	if _now() >= spot["until"]:
		extinguish(spot)
		return
	if tg != null:
		if not is_instance_valid(tg) or tg.is_dead():
			# hedef öldü: alev yerde birkaç saniye daha yanar
			_drop(spot, 4.0)
		else:
			var p: Vector3 = tg.global_position
			if p.distance_to(spot["last"]) > SHED_DIST:
				# yeterli hızla sıyrıldı (yer değiştirme / shunshin): alev eski yerinde kalır
				Combat.popup_text(p + Vector3.UP * 2.4, "Kara alevden sıyrıldı!", Color(0.8, 0.6, 0.95))
				if tg.has_method("apply_status"):
					tg.apply_status("burn", 0.01)
				tg.set_meta("black_flame", false)
				_drop(spot, 3.0)
			else:
				spot["last"] = p
				spot["pos"] = p
				if _alive(owner):
					var inf: Dictionary = spot["info"].duplicate()
					inf["dir"] = Vector3.UP
					tg.take_hit(inf)
				if randf() < 0.3:
					VFX.embers(p + Vector3.UP, Color(0.5, 0.12, 0.6), 2, 2.5, 0.7)
	else:
		# yerdeki alev: içine giren tutuşur (yayılır)
		if _alive(owner):
			for h in Combat.hit_sphere(owner, spot["pos"] + Vector3.UP, 1.6, spot["info"]):
				if _alive(h) and not _burning(h):
					ignite(owner, h, h.global_position, 5.0, spot["info"])
	_schedule(spot)


static func _burning(h: Node) -> bool:
	for s in spots:
		if s["target"] == h:
			return true
	return false


## Hedefin üstündeki alevi yere bırak (hedef öldü ya da sıyrıldı)
static func _drop(spot: Dictionary, dur: float) -> void:
	var fl = spot["node"]
	var at: Vector3 = spot["last"]
	at.y = Game.jutsu_floor(at.x, at.z)
	if fl != null and is_instance_valid(fl):
		fl.reparent(_tree().current_scene)
		fl.global_position = at
	spot["target"] = null
	spot["pos"] = at
	spot["until"] = minf(spot["until"], _now() + dur)


## Söndür (süre bitti ya da sahibi Kagutsuchi ile şekil verdi)
static func extinguish(spot: Dictionary) -> void:
	spots.erase(spot)
	var fl = spot["node"]
	if fl != null and is_instance_valid(fl):
		var tw = fl.create_tween()
		tw.tween_property(fl, "scale", fl.scale * Vector3(1.0, 0.05, 1.0), 0.35)
		tw.tween_callback(fl.queue_free)
	var tg = spot["target"]
	if tg != null and is_instance_valid(tg):
		tg.set_meta("black_flame", false)


## Sahibinin yanan alevleri (Kagutsuchi bunları şekillendirir)
static func spots_of(owner: Node3D, center: Vector3, radius: float) -> Array:
	var out = []
	for s in spots.duplicate():
		if s["owner"] == owner and (s["pos"] as Vector3).distance_to(center) < radius:
			if s["target"] != null and not is_instance_valid(s["target"]):
				continue
			out.append(s)
	return out


## Odak anı: kullanıcının sağ gözünden kan, ekran bir an kızıla döner (oyuncu)
static func focus_flash(c: Node3D) -> void:
	Sfx.play("genjutsu", c.global_position, 0.6)
	if c == Game.player and Game.world:
		Game.world.env.set_tint(Color(0.6, 0.0, 0.05, 0.25))
		_tree().create_timer(0.35).timeout.connect(func(): if Game.world: Game.world.env.set_tint(Color(0, 0, 0, 0)))
