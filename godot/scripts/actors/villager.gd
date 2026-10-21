class_name Villager
extends Fighter
## Köylü: sokaklarda yürür, bekler, sohbet eder. Dövüşe girmez.

var home = Vector3.ZERO
var goal = Vector3.ZERO
var wait = 0.0


func _ready() -> void:
	team = "neutral"
	var tops = [Color(0.5, 0.6, 0.45), Color(0.6, 0.35, 0.3), Color(0.8, 0.75, 0.55), Color(0.4, 0.45, 0.6), Color(0.7, 0.55, 0.65), Color(0.85, 0.85, 0.85)]
	var t: Color = tops.pick_random()
	look = {"gender": ["m", "f"].pick_random(), "top": t, "top2": t.darkened(0.1), "pants": Color(0.35, 0.3, 0.28), "band": null,
		"hair_style": ["kısa", "uzun", "atkuyruğu", "kase", "dağınık"].pick_random(), "hair": [Color(0.1, 0.08, 0.06), Color(0.35, 0.22, 0.12), Color(0.6, 0.6, 0.62)].pick_random(),
		"sleeves": randf() < 0.5}
	size = randf_range(0.92, 1.04)
	super._ready()
	remove_from_group("fighters")
	collision_layer = 4
	goal = global_position


func _physics_process(dt: float) -> void:
	if Game.paused or Game.player == null:
		return
	if global_position.distance_to(Game.player.global_position) > 140.0:
		return
	if wait > 0.0:
		wait -= dt
		step_move(Vector3.ZERO, dt)
		model.play("talk" if fmod(wait, 7.0) < 3.0 else "idle", 0.3)
		return
	var v = goal - global_position
	v.y = 0
	if v.length() < 1.5:
		goal = home + Vector3(randf_range(-60, 60), 0, randf_range(-60, 60))
		wait = randf_range(1.0, 8.0)
		return
	step_move(v.normalized() * 2.6, dt)
	model.play("walk", 0.25)
	if is_on_wall():
		goal = home + Vector3(randf_range(-60, 60), 0, randf_range(-60, 60))
