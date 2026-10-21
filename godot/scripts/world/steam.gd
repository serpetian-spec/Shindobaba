extends Node
## Kaplıca buharı


func add(p: Vector3) -> void:
	var e = GPUParticles3D.new()
	e.amount = 24
	e.lifetime = 4.0
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 6.0
	pm.direction = Vector3.UP
	pm.spread = 15.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.5
	pm.gravity = Vector3(0, 0.3, 0)
	pm.scale_min = 3.0; pm.scale_max = 6.0
	pm.color_ramp = FX._gradient([Color(1, 1, 1, 0), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	e.process_material = pm
	var q = QuadMesh.new()
	q.material = FX._draw_mat(FX.tex_smoke, false)
	e.draw_pass_1 = q
	add_child(e)
	e.global_position = p
	e.emitting = true
