extends Node
## Sokak fenerleri: binlerce fener konumu tutulur, gece oyuncuya en yakın 16 tanesine gerçek ışık verilir.

var points: PackedVector3Array = PackedVector3Array()
var pool: Array[OmniLight3D] = []
var t = 0.0


func add(p: Vector3) -> void:
	points.append(p)


func _ready() -> void:
	for i in 16:
		var l = OmniLight3D.new()
		l.light_color = Color(1.0, 0.68, 0.38)
		l.light_energy = 0.0
		l.omni_range = 11.0
		l.omni_attenuation = 1.6  # yumuşak, küçük sıcak ışık havuzu
		l.shadow_enabled = false
		# toon.gdshader'daki taban gölge payı nokta ışıklarda küme hücrelerini kare kare boyar;
		# fenerler yalnızca katman 1'i (arazi, çimen, karakterler) aydınlatır, yapılar katman 2'de.
		l.light_cull_mask = 1
		add_child(l)
		pool.append(l)


func _process(dt: float) -> void:
	t -= dt
	if t > 0.0 or Game.player == null or Game.world == null:
		return
	t = 0.5
	var tod: float = Game.world.env.time_of_day
	var night = 1.0 - smoothstep(0.24, 0.32, tod) + smoothstep(0.7, 0.78, tod)
	night = clampf(night, 0.0, 1.0)
	var p = Game.player.global_position
	var near: Array = []
	for q in points:
		var d = q.distance_squared_to(p)
		if d < 120.0 * 120.0:
			near.append([d, q])
	near.sort_custom(func(a, b): return a[0] < b[0])
	for i in pool.size():
		if i < near.size() and night > 0.05:
			pool[i].global_position = near[i][1]
			pool[i].light_energy = 1.8 * night   # fener ışık havuzu belirgin (sarı, güçlü)
		else:
			pool[i].light_energy = 0.0
