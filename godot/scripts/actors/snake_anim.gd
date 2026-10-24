class_name SnakeAnim
extends Node
## Yılan çağrılarının canlandırması (beast.gdshader deformasyonu):
##   mode 1 — çöreklenmiş dev yılan (hayran modeli, Manda benzeri): halkalar dalgalanır, boyun/baş salınır, hedefe döner, ısırırken atılır
##   mode 2 — sürünen toon yılan (prosedürel): gövde boyunca yanal sinüs dalgası, baş sallanır, ısırma atılışı
## Her iki modda çatal dil ağızdan aralıklarla çıkıp titrer. Durumu üst Summon'dan okur (hız, hedef, ısırma zamanı).

var mode := 2
var holder: Node3D            # canavar-yerel uzay (taban y=0, ön -Z)
var mats: Array = []
var dims := Vector4(1, -1, 1, 0.5)
var pivot := Vector3.ZERO
var mouth_local := Vector3.ZERO
var tongue: Node3D
var t := 0.0
var phase := 0.0
var walk := 0.0
var strike := 0.0
var head := Vector2.ZERO
var tongue_t := 0.0


func setup(m: int, h: Node3D, materials: Array, size: Vector3, piv := Vector3.ZERO, mouth := Vector3.ZERO, tongue_len := 1.0) -> void:
	mode = m
	holder = h
	mats = materials
	dims = Vector4(size.y, -size.z * 0.5, size.z * 0.5, size.x * 0.5)
	pivot = piv
	mouth_local = mouth
	phase = randf() * TAU
	for mi in holder.find_children("*", "MeshInstance3D", true, false):
		mi.extra_cull_margin = maxf(size.y, size.z) * 0.4
	for mt in mats:
		mt.set_shader_parameter("deform", true)
		mt.set_shader_parameter("deform_mode", mode)
		mt.set_shader_parameter("dims", dims)
		mt.set_shader_parameter("pivot", pivot)
	# çatal dil
	tongue = Node3D.new()
	holder.add_child(tongue)
	var mb = MB.new()
	var red = Color(0.9, 0.15, 0.25)
	Loft.tube(mb, [Vector3.ZERO, Vector3(0, 0, -0.6)], [0.06, 0.05], red, 6, 1, true, false)
	for sx in [-1.0, 1.0]:
		Loft.tube(mb, [Vector3(0, 0, -0.55), Vector3(0.12 * sx, -0.02, -0.95)], [0.045, 0.01], red, 6, 1, false, true)
	var mi2 = MeshInstance3D.new()
	mi2.mesh = mb.build(Props.toon())
	mi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tongue.add_child(mi2)
	tongue.scale = Vector3.ONE * tongue_len
	tongue.visible = false


## Isırma atılışı (Summon saldırısında çağrılır)
func bite() -> void:
	strike = maxf(strike, 0.01)
	set_meta("bite_t", 0.0)


func _process(dt: float) -> void:
	if not is_instance_valid(holder) or not holder.is_inside_tree():
		return
	t += dt
	var sm = holder.get_parent()
	while sm and not sm is Summon and sm != get_tree().root:
		sm = sm.get_parent()
	var moving := false
	var tg: Node3D = null
	if sm is Summon:
		moving = Vector2(sm.velocity.x, sm.velocity.z).length() > 0.5
		tg = sm.tgt
	walk = move_toward(walk, 1.0 if moving else 0.0, dt * 2.0)
	# ısırma: hızlı atılış, yavaş dönüş
	if has_meta("bite_t"):
		var bt = float(get_meta("bite_t")) + dt
		set_meta("bite_t", bt)
		strike = sin(clampf(bt / 0.22, 0.0, 1.0) * PI * 0.5) if bt < 0.22 else maxf(0.0, 1.0 - (bt - 0.22) / 0.45)
		if bt > 0.7:
			remove_meta("bite_t")
			strike = 0.0
	var hy := sin(t * 0.6 + phase) * 0.15
	var hx := sin(t * 0.9 + phase) * 0.06
	if tg and is_instance_valid(tg):
		var lv = holder.global_transform.affine_inverse() * tg.global_position
		hy = clampf(atan2(-lv.x, -lv.z), -0.7, 0.7)
	head = head.lerp(Vector2(hx, hy), minf(1.0, dt * 4.0))
	var to_b = Projection(holder.global_transform.affine_inverse())
	var from_b = Projection(holder.global_transform)
	var ws = 1.6 + walk * 5.0
	for m in mats:
		m.set_shader_parameter("to_beast", to_b)
		m.set_shader_parameter("from_beast", from_b)
		m.set_shader_parameter("anim_t", t + phase)
		m.set_shader_parameter("walk", walk)
		m.set_shader_parameter("wave_speed", ws)
		m.set_shader_parameter("tail_amp", 0.05 + walk * 0.01)
		m.set_shader_parameter("head_rot", head)
		m.set_shader_parameter("strike", strike)
		m.set_shader_parameter("coil", 0.0)   # çörek kapalı: kullanıcı uzun gövdeyi görmek istiyor (çörek yılanı kafadan ibaret gösteriyordu)
	_tongue(dt)


## Dil: birkaç saniyede bir ağızdan çıkar, hızlı titrer, geri çekilir (ağız noktası gövdeyle aynı formülle izlenir)
func _tongue(dt: float) -> void:
	tongue_t -= dt
	if tongue_t < -0.5:
		tongue_t = randf_range(1.2, 3.0)
	var out_k = clampf(minf(tongue_t + 0.5, -tongue_t) / 0.08, 0.0, 1.0) if tongue_t < 0.0 else 0.0
	tongue.visible = out_k > 0.05
	if not tongue.visible:
		return
	var tt = t + phase
	var p = mouth_local
	if mode == 1:
		var H = dims.x
		var hm = smoothstep(0.32, 0.62, p.y / H)
		var r = (p - pivot)
		r = r.rotated(Vector3.UP, head.y * hm)
		r = r.rotated(Vector3.RIGHT, (head.x - strike * 0.55) * hm)
		p = pivot + r + Vector3(sin(tt * 1.1) * 0.03 * H * hm * hm, 0, -strike * 0.22 * H * hm * hm)
	else:
		var L = dims.z - dims.y
		p.x += sin(tt * 1.3) * 0.05 * L + head.y * 0.25 * L
		p.z -= strike * 0.22 * L
		p.y += strike * 0.08 * L + sin(tt * 1.7) * 0.02 * L
	tongue.position = p
	tongue.rotation = Vector3(head.x - strike * 0.4, head.y, sin(t * 60.0) * 0.25)
	tongue.scale.z = tongue.scale.x * out_k
