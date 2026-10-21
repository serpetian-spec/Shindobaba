class_name ShadowClone
extends Fighter
## Kage Bunshin: tek darbede kaybolan, en yakın düşmana saldıran klon.

var life = 15.0
var tgt: Node3D = null
var cd = 0.0


func _ready() -> void:
	team = "player"
	max_hp = 1.0
	hp = 1.0
	super._ready()


func take_hit(_info: Dictionary) -> void:
	vanish()


func vanish() -> void:
	if dead:
		return
	dead = true
	FX.smoke_puff(global_position + Vector3.UP, 0.9, 14)
	queue_free()


func _physics_process(dt: float) -> void:
	if Game.paused:
		return
	life -= dt
	cd -= dt
	if life <= 0.0:
		vanish()
		return
	if tgt == null or not is_instance_valid(tgt) or tgt.is_dead():
		tgt = Combat.nearest_enemy(self, 30.0)
	if tgt:
		var v = tgt.global_position - global_position
		v.y = 0
		var d = v.length() - tgt.radius - radius
		facing = atan2(-v.x, -v.z)
		if d > 1.3:
			step_move(v.normalized() * 13.0, dt, false)
			model.play("run", 0.1, 1.3)
			model.overlay.set_pose("ninja_run", 1.0)
		else:
			step_move(Vector3.ZERO, dt, false)
			model.overlay.set_pose("ninja_run", 0.0)
			if cd <= 0.0:
				cd = 0.45
				model.play(["jab", "cross", "hook"].pick_random(), 0.05, 1.5, true)
				var pt = global_position + Vector3.UP * 1.1 + face_dir() * (radius + 0.8)
				if not Combat.hit_sphere(self, pt, 0.8, {"dmg": 5.0 * Stats.melee_mult(Game.profile), "knock": 2.0, "kind": "light"}).is_empty():
					FX.hit_spark(pt, Color(1, 0.85, 0.5), 0.6)
					Sfx.play("punch", pt)
	elif Game.player:
		var v = Game.player.global_position - global_position
		v.y = 0
		if v.length() > 4.0:
			step_move(v.normalized() * 12.0, dt)
			model.play("run", 0.15)
		else:
			step_move(Vector3.ZERO, dt)
			model.play("idle", 0.2)
