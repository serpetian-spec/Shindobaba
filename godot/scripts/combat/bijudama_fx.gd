class_name BijudamaFX
extends RefCounted
## Kuyruklu Canavar Topu (Bijūdama) — TEK görsel kaynak. Ref: refs/bijudama (anime: Kurama/Gyūki/Ten-Tails).
## 1) Toplanış: ağız önünde çevreden mavi (pozitif) ve kırmızı-siyah (negatif) küçük chakra küreleri sarmal çizerek içe akar,
##    sıkışır; altında zemin basınçla çatlar, moloz kalkar (duman yok).
## 2) Top: koyu mor-siyah, içinde dönen menekşe girdaplar, kenarında ince parlak hale (vfx_bijudama.gdshader).
## 3) Atış: ağız önünde iç içe şok halkaları, topun ardında parlak mor-beyaz iz.
## 4) Patlama: önce kör edici beyaz-lavanta parlama, sonra genişleyen yarı saydam canavar chakrası kubbesi, dev zemin halkası,
##    çatlaklar ve moloz; ekran parlar, sarsar. Kullananlar: TailedBeasts.fire_ball (pelerin + tam dönüşüm), PathJutsu.p_bijudama,
##    _bijuball, BijuuArts._bijudama_rasengan, dövüş tarzları.

const BLUE := Color(0.35, 0.6, 1.0)
const RED := Color(0.75, 0.08, 0.12)


static func _mat(light := false, alpha := 1.0, hot := false) -> ShaderMaterial:
	var key = "bijudama_%s_%.2f_%s" % [light, alpha, hot]
	if VFX._cache.has(key):
		return VFX._cache[key]
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/vfx_bijudama.gdshader")
	if light:   # patlama kubbesi: açık lavanta, saydam
		m.set_shader_parameter("deep", Color(0.55, 0.38, 0.78))
		m.set_shader_parameter("swirl_col", Color(0.92, 0.82, 1.0))
		m.set_shader_parameter("rim_col", Color(1.0, 0.97, 1.0))
		m.set_shader_parameter("speed", 2.6)
	if hot:
		# derinlik yazan kopya: ekran çizgisi (outline) içindeki kaya/kaktüs kenarlarını beyaz ışığın üstüne çizmesin
		var sh = Shader.new()
		sh.code = m.shader.code.replace("depth_draw_opaque", "depth_draw_always")
		m.shader = sh
	if hot:   # patlamanın ilk anı: kör edici beyaz-altın ışık (ref: Naruto vs Kurama — ekranı kaplayan beyaz patlama)
		m.set_shader_parameter("deep", Color(1.0, 0.98, 0.9))
		m.set_shader_parameter("swirl_col", Color(1.0, 1.0, 0.95))
		m.set_shader_parameter("rim_col", Color(1.0, 0.9, 0.6))
		m.set_shader_parameter("speed", 4.0)
	m.set_shader_parameter("alpha", alpha)
	if alpha < 0.999:
		m.render_priority = 1
	VFX._cache[key] = m
	return m


## Top görseli (çap = s metre): koyu girdaplı küre + çevresinde dönen küçük koyu kıvılcımlar
static func ball(s: float) -> Node3D:
	var root = Node3D.new()
	var core = MeshInstance3D.new()
	core.mesh = VFX._sphere(0.5, 32, 16)
	core.material_override = _mat()
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core.scale = Vector3.ONE * s
	root.add_child(core)
	FX.burst(Vector3.ZERO, {"amount": 24, "life": 0.5, "explosive": 0.0, "local": true, "parent": root, "tex": FX.tex_spark, "add": false, "size": 0.08 * s + 0.05,
		"radius": s * 0.6, "vmin": 0.2, "vmax": 0.8, "spread": 180.0, "orbit": 2.0, "colors": [Color(0.55, 0.3, 0.8, 0.9), Color(0.1, 0.02, 0.15, 0.0)]}).one_shot = false
	return root


## Toplanış (dur sn): at noktasına mavi + kırmızı chakra küreleri sarmal akar; s = son top çapı. Zemin basıncı.
static func gather(at: Vector3, s: float, dur: float) -> void:
	var tree = VFX.tree()
	var n = 26
	for k in n:
		var col = BLUE if k % 2 == 0 else RED
		var a0 = randf() * TAU
		var r0 = s * randf_range(2.2, 4.0) + 1.0
		var y0 = randf_range(-0.6, 1.0) * s
		var orb = Projectile.energy_mesh(col.lightened(0.35), col, s * randf_range(0.12, 0.22) + 0.08, 4.0, 0.0, 2.0)
		VFX.scene().add_child(orb)
		var st = randf() * dur * 0.5
		orb.global_position = at + Vector3(cos(a0) * r0, y0, sin(a0) * r0)
		orb.scale = Vector3.ONE * 0.01
		var tw = orb.create_tween()
		tw.tween_interval(st)
		tw.tween_property(orb, "scale", Vector3.ONE * (s * randf_range(0.12, 0.22) + 0.08), 0.08)
		var spin = randf_range(1.5, 3.0) * (1.0 if k % 3 else -1.0)
		tw.tween_method(func(u: float):
			if is_instance_valid(orb):
				var a = a0 + u * spin
				var rr = r0 * (1.0 - u)
				orb.global_position = at + Vector3(cos(a) * rr, y0 * (1.0 - u), sin(a) * rr), 0.0, 1.0, maxf(0.15, dur - st - 0.05)).set_ease(Tween.EASE_IN)
		tw.tween_callback(orb.queue_free)
	# zemin basıncı: altındaki toprak çöker, moloz yukarı çekilir
	var g = Vector3(at.x, Game.ground_height(at.x, at.z), at.z)
	if at.y - g.y < s * 4.0 + 3.0:
		VFX.cracks(g, s * 2.5 + 2.0, Color(0.1, 0.06, 0.12, 0.9), 4.0)
		for k in 3:
			tree.create_timer(dur * k / 3.0).timeout.connect(func():
				VFX.shockwave(g + Vector3.UP * 0.1, Color(0.6, 0.45, 0.8), s * 3.0 + 3.0, 0.4, true)
				VFX.debris(g + Vector3.UP * 0.2, Color(0.4, 0.34, 0.3), 6, 5.0, 0.15 * s + 0.12))
	Sfx.play("rasengan", at, 0.45)


## Atış anı: ağız önünde iç içe şok halkaları (yön boyunca) + kısa parlama; topa parlak iz bağlar
static func launch(at: Vector3, dir: Vector3, s: float, proj: Node3D = null) -> void:
	# ref (Kurama atışı): ağız önünde sert basınç patlaması — iç içe parlak halkalar, koyu menekşe flaş, altta toz/moloz savrulması
	for k in 4:
		VFX.tree().create_timer(k * 0.06).timeout.connect(func():
			VFX.shockwave(at + dir * (k * s * 0.9), Color(1.0, 0.95, 1.0) if k % 2 == 0 else Color(0.62, 0.4, 0.95), s * (3.0 + k * 1.1) + 2.0, 0.5, false, dir))
	VFX.star(at, Color(0.55, 0.3, 0.9), s * 3.2 + 1.5, 0.28)
	VFX.star(at, Color(1.0, 0.97, 1.0), s * 2.0 + 1.0, 0.18)
	FX.light(at, Color(0.75, 0.6, 1.0), 10.0, s * 8.0 + 6.0, 0.35)
	var g = Vector3(at.x, Game.ground_height(at.x, at.z), at.z)
	if at.y - g.y < s * 5.0 + 4.0:
		# geri tepme: zeminde savrulan halka + yukarı fırlayan moloz
		VFX.shockwave(g + Vector3.UP * 0.15, Color(0.8, 0.7, 0.95), s * 5.0 + 4.0, 0.55, true)
		VFX.debris(g + Vector3.UP * 0.3, Color(0.42, 0.36, 0.3), 12, 8.0 + s * 2.0, 0.12 * s + 0.15)
	if Game.world:
		Game.world.env.add_shake(clampf(0.3 + s * 0.1, 0.3, 1.2))
	if proj and is_instance_valid(proj):
		VFX.trail(proj, s * 0.45 + 0.15, Color(1, 0.95, 1, 1), Color(0.6, 0.35, 0.9), Color(0.3, 0.1, 0.5, 0), 14, 0.5)


## Patlama (R = etki yarıçapı): beyaz-lavanta parlama -> genişleyen canavar chakrası kubbesi -> zemin halkası, çatlak, moloz
static func explode(pos: Vector3, R: float) -> void:
	var tree = VFX.tree()
	VFX.star(pos, Color(1, 0.95, 0.75), R * 2.2, 0.3)
	VFX.star(pos, Color(1, 1, 1), R * 1.4, 0.2)
	FX.light(pos, Color(1.0, 0.92, 0.75), 24.0, R * 6.0, 0.9)
	# ilk an: beyaz-altın sıcak küre hızla büyür ve söner (lavanta kubbe ardından gelir)
	var hot = MeshInstance3D.new()
	hot.mesh = VFX._sphere(0.5, 28, 14)
	hot.material_override = _mat(false, 1.0, true)
	hot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	VFX.scene().add_child(hot)
	hot.global_position = pos
	hot.scale = Vector3.ONE * R * 0.3
	var th = hot.create_tween()
	th.tween_property(hot, "scale", Vector3.ONE * R * 1.7, 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	th.tween_property(hot, "transparency", 1.0, 0.22)
	th.tween_callback(hot.queue_free)
	var flash = MeshInstance3D.new()
	flash.mesh = VFX._sphere(0.5, 28, 14)
	flash.material_override = _mat(true, 0.92)
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	VFX.scene().add_child(flash)
	flash.global_position = pos
	flash.scale = Vector3.ONE * R * 1.2
	flash.visible = false   # beyaz flaş önce: kubbe onun ardından açılır (yoksa beyaz küre kubbenin içinde kalıyordu)
	var tw = flash.create_tween()
	tw.tween_interval(0.14)
	tw.tween_callback(func(): flash.visible = true)
	tw.tween_property(flash, "scale", Vector3.ONE * R * 2.0, 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.6)   # kubbe bir an asılı kalır (anime: patlama küresi büyüyüp durur)
	tw.tween_property(flash, "scale", Vector3.ONE * R * 2.3, 0.45)
	tw.parallel().tween_property(flash, "transparency", 1.0, 0.45)
	tw.tween_callback(flash.queue_free)
	# içte koyu çekirdek bir an kalır (topun kendisi patlamanın ortasında çöker)
	var core = MeshInstance3D.new()
	core.mesh = VFX._sphere(0.5, 20, 10)
	core.material_override = _mat()
	VFX.scene().add_child(core)
	core.global_position = pos
	core.scale = Vector3.ONE * R * 0.35
	var tc = core.create_tween()
	tc.tween_property(core, "scale", Vector3.ONE * R * 0.05, 0.3).set_ease(Tween.EASE_IN)
	tc.tween_callback(core.queue_free)
	var g = Vector3(pos.x, Game.ground_height(pos.x, pos.z), pos.z)
	var near_ground = pos.y - g.y < R * 1.2
	VFX.shockwave(pos, Color(1, 1, 1), R * 1.6, 0.3, false)
	if near_ground:
		VFX.shockwave(g + Vector3.UP * 0.2, Color(0.75, 0.6, 0.95), R * 3.2, 0.7, true)
		tree.create_timer(0.12).timeout.connect(func(): VFX.shockwave(g + Vector3.UP * 0.15, Color(0.55, 0.45, 0.6), R * 4.2, 0.9, true))
		VFX.cracks(g, R * 1.3, Color(0.08, 0.03, 0.08, 0.95), 10.0)
		VFX.debris(g + Vector3.UP * 0.5, Color(0.42, 0.36, 0.3), 26, R * 1.6, maxf(0.3, R * 0.08))
		VFX.debris(g + Vector3.UP * 0.5, Color(0.25, 0.22, 0.2), 14, R * 2.4, maxf(0.2, R * 0.05))   # hızlı küçük kıymıklar (ref: dağılan keskin parçalar)
	# ref (anime): patlamadan göğe yükselen ışık sütunu + gecikmeli ikinci/üçüncü basınç dalgası
	var pil = MeshInstance3D.new()
	pil.mesh = VFX._sphere(0.5, 20, 10)
	pil.material_override = _mat(true, 0.8)
	pil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	VFX.scene().add_child(pil)
	pil.global_position = pos + Vector3.UP * R * 1.5
	pil.scale = Vector3(R * 0.5, R * 0.6, R * 0.5)
	var tp = pil.create_tween()
	tp.tween_property(pil, "scale", Vector3(R * 0.9, R * 7.0, R * 0.9), 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tp.tween_interval(0.4)
	tp.tween_property(pil, "scale", Vector3(R * 0.1, R * 9.0, R * 0.1), 0.6)
	tp.parallel().tween_property(pil, "transparency", 1.0, 0.6)
	tp.tween_callback(pil.queue_free)
	if near_ground:
		for k2 in 2:
			tree.create_timer(0.4 + k2 * 0.3).timeout.connect(func():
				VFX.shockwave(g + Vector3.UP * 0.2, Color(0.9, 0.85, 1.0), R * (4.8 + k2 * 1.6), 1.0, true)
				VFX.debris(g + Vector3.UP * 0.5, Color(0.36, 0.3, 0.27), 12, R * (2.0 + k2), maxf(0.25, R * 0.06)))
	Sfx.play("boom", pos, 0.4)
	if Game.world:
		Game.world.env.screen_flash(0.35)
		Game.world.env.add_shake(clampf(R * 0.15, 0.6, 2.5))


## Ağız önü: topun toplandığı / fırladığı nokta (çap kadar önde, hafif yukarıda)
static func muzzle(mouth: Node3D, diam: float) -> Vector3:
	var b = mouth.global_transform.basis
	return mouth.global_position - b.z.normalized() * diam * 0.6 + Vector3.UP * diam * 0.1


## Epik şarj (anime): ağız önünde koyu top büyür (mavi + kırmızı chakra küreleri dalga dalga akar, zemin çöker), sonda
## canavar topu YUTAR (top küçülüp ağza çekilir) — ardından fire_ball ile fırlatılır. diam = tam boy çap, dur = toplam süre.
static func charge(mouth: Node3D, diam: float, dur: float) -> void:
	if not is_instance_valid(mouth):
		return
	var root = Node3D.new()
	VFX.scene().add_child(root)
	root.add_child(ball(1.0))
	root.global_position = muzzle(mouth, diam)
	root.scale = Vector3.ONE * diam * 0.05
	var tw = root.create_tween()
	tw.tween_method(func(u: float):
		if not is_instance_valid(mouth) or not is_instance_valid(root):
			return
		var grow = pow(clampf(u / 0.82, 0.0, 1.0), 0.7)
		var gulp = smoothstep(0.86, 1.0, u)
		root.scale = Vector3.ONE * diam * lerpf(0.05, 1.0, grow) * lerpf(1.0, 0.4, gulp) * (1.0 + sin(u * 60.0) * 0.03)
		root.global_position = muzzle(mouth, diam * lerpf(1.0, 0.35, gulp)), 0.0, 1.0, dur)
	tw.tween_callback(root.queue_free)
	var tree = VFX.tree()
	for w in 3:
		tree.create_timer(dur * 0.22 * w).timeout.connect(func():
			if is_instance_valid(mouth):
				gather(muzzle(mouth, diam), diam, dur * 0.4))
	FX.light(muzzle(mouth, diam), Color(0.6, 0.4, 0.95), 8.0, diam * 5.0, dur)
