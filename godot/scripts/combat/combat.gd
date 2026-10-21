extends Node
## Dövüş çekirdeği (autoload "Combat"): kapsül hitbox testleri, hasar, hit-stop, hasar sayıları, element tablosu.
## Her savaşçı "fighters" grubundadır ve şunları sağlar: team, radius, height, take_hit(info), is_dead()

const BEATS := {"katon": "fuuton", "fuuton": "raiton", "raiton": "doton", "doton": "suiton", "suiton": "katon"}



func element_mult(atk: String, dfn: String) -> float:
	if atk == "" or dfn == "":
		return 1.0
	if BEATS.get(atk, "") == dfn:
		return 1.5
	if BEATS.get(dfn, "") == atk:
		return 0.75
	return 1.0


## Bir noktanın savaşçının kapsülüne (boyutuna göre) değip değmediği
func capsule_hit(point: Vector3, f: Node3D, extra: float) -> bool:
	var base = f.global_position
	var h: float = f.height
	var y = clampf(point.y, base.y + f.radius, base.y + h - f.radius)
	var c = Vector3(base.x, y, base.z)
	return point.distance_to(c) <= f.radius + extra


func hostile(a: Node, b: Node) -> bool:
	if a == b or b == null or a == null:
		return false
	var ta = a.get("team"); var tb = b.get("team")
	if ta == null or tb == null:
		return false
	if tb == "dummy" or ta == "dummy":
		return ta != tb
	return ta != tb and ta != "neutral" and tb != "neutral"


## Küre içinde kalan düşman savaşçılara vurur. Vurulanları döndürür.
func hit_sphere(attacker: Node3D, center: Vector3, radius: float, info: Dictionary, exclude: Array = []) -> Array:
	var hits: Array = []
	for f in get_tree().get_nodes_in_group("fighters"):
		if f in exclude or not hostile(attacker, f) or f.is_dead():
			continue
		if capsule_hit(center, f, radius):
			var inf = info.duplicate()
			inf["attacker"] = attacker
			if not inf.has("dir"):
				var d: Vector3 = f.global_position - attacker.global_position
				d.y = 0
				inf["dir"] = d.normalized() if d.length() > 0.01 else -attacker.global_transform.basis.z
			f.take_hit(inf)
			hits.append(f)
	if not hits.is_empty() and info.get("hitstop", 0.0) > 0.0:
		hitstop(info["hitstop"])
	return hits


func nearest_enemy(from: Node3D, max_d: float, dir := Vector3.ZERO, cone := -1.0) -> Node3D:
	var best: Node3D = null
	var bd = max_d
	for f in get_tree().get_nodes_in_group("fighters"):
		if not hostile(from, f) or f.is_dead():
			continue
		var v: Vector3 = f.global_position - from.global_position
		var d = v.length()
		if d > bd:
			continue
		if dir != Vector3.ZERO and cone > -1.0:
			var vf = Vector3(v.x, 0, v.z).normalized()
			if vf.dot(dir) < cone:
				continue
		bd = d
		best = f
	return best


## Vuruş anında oyunu kısa süre yavaşlat (Storm hissi). Gerçek zamanla ölçülür.
var hitstop_until = 0
var base_time_scale = 1.0  # Sharingan vb. yavaş çekim için


func hitstop(t: float) -> void:
	hitstop_until = maxi(hitstop_until, Time.get_ticks_msec() + int(t * 1000.0))
	Engine.time_scale = 0.05


func _process(_dt: float) -> void:
	if hitstop_until > 0 and Time.get_ticks_msec() >= hitstop_until:
		hitstop_until = 0
		Engine.time_scale = base_time_scale
	elif hitstop_until == 0 and absf(Engine.time_scale - base_time_scale) > 0.001:
		Engine.time_scale = base_time_scale


func damage_number(pos: Vector3, amount: float, col := Color(1, 0.9, 0.3), crit := false) -> void:
	var l = Label3D.new()
	l.text = str(int(round(amount)))
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0018 if not crit else 0.0026
	l.font_size = 48
	l.outline_size = 12
	l.modulate = col
	l.outline_modulate = Color(0.1, 0.05, 0.05)
	get_tree().current_scene.add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
	var tw = l.create_tween().set_parallel(true)
	tw.tween_property(l, "global_position", l.global_position + Vector3(0, 1.4, 0), 0.7).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.45)
	tw.chain().tween_callback(l.queue_free)


func popup_text(pos: Vector3, text: String, col := Color(1, 1, 1)) -> void:
	var l = Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0016
	l.font_size = 40
	l.outline_size = 10
	l.modulate = col
	get_tree().current_scene.add_child(l)
	l.global_position = pos
	var tw = l.create_tween().set_parallel(true)
	tw.tween_property(l, "global_position", pos + Vector3(0, 1.0, 0), 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)
