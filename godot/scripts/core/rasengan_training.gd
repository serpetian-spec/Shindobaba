extends Node
## Rasengan eğitimi (autoload "RasenganTraining"): 3 aşama, chakra'yı [C] ile kesintisiz dönüştür, kımıldama.

const STAGES := [
	["1. Aşama: Su Balonu", "Chakrayı döndürerek balonu patlat. [C] basılı tut, kıpırdama.", 5.0, Color(0.4, 0.7, 1.0)],
	["2. Aşama: Lastik Top", "Gücü artır: lastik topu patlat. [C] basılı tut.", 7.0, Color(0.9, 0.5, 0.3)],
	["3. Aşama: Balon", "Şimdi şekli koru: balon patlamadan içinde dönen küre oluştur!", 9.0, Color(1, 1, 1)],
]

var stage = -1
var progress = 0.0
var ball: MeshInstance3D


func start() -> void:
	stage = 0
	_begin()


func _begin() -> void:
	progress = 0.0
	var s: Array = STAGES[stage]
	Hud.banner(s[0], s[1], s[3])
	if ball:
		ball.queue_free()
	ball = Projectile.energy_mesh(s[3], s[3].darkened(0.3), 0.4, 2.0, 0.0, 1.2)
	Game.player.model.add_child(ball)
	ball.position = Vector3(0.35, 1.15, -0.55)


func _process(dt: float) -> void:
	if stage < 0 or Game.player == null:
		return
	var pl = Game.player
	var s: Array = STAGES[stage]
	var charging = Input.is_action_pressed("charge") and pl.velocity.length() < 0.5
	if charging:
		progress += dt
		ball.scale = Vector3.ONE * (0.4 + progress / s[2] * 0.5) * (1.0 + sin(Time.get_ticks_msec() * 0.03) * 0.05)
		var m: ShaderMaterial = ball.mesh.material
		m.set_shader_parameter("swirl", 2.0 + progress * 3.0)
	else:
		progress = maxf(0.0, progress - dt * 2.0)
	Hud.objective_progress("%s: %d%%" % [s[0], int(progress / s[2] * 100.0)])
	if progress >= s[2]:
		FX.burst(ball.global_position, {"amount": 40, "life": 0.6, "size": 0.6, "vmin": 4, "vmax": 10, "gravity": Vector3(0, -10, 0),
			"colors": [Color(1, 1, 1, 1), s[3], Color(s[3].r, s[3].g, s[3].b, 0)]})
		Sfx.play("poof", ball.global_position, 1.5)
		stage += 1
		if stage >= STAGES.size():
			stage = -1
			ball.queue_free()
			ball = null
			Progress.learn("rasengan")
			Hud.dialog("Yaşlı Kurbağa Bilge", "Dönüş, güç ve şekil... Üçünü birleştirdin. Rasengan artık senin!", [])
		else:
			_begin()
