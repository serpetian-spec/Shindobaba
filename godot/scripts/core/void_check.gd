extends RefCounted
## F8: siyah leke teşhisi (oyuncu raporu). Ekrandaki som siyah kare blokları sayar; sonra ekran efektlerini ve nesne
## türlerini tek tek kapatıp yeniden sayar -> lekeyi hangi efekt büyütüyor / hangi nesne üretiyor belli olur.
## Lekenin altına düşen nesneler (yol, tür, malzeme) de listelenir. Çıktı: Masaüstü/ShinobiYolu_teshis/<zaman>/ (rapor.txt + görüntüler).


## Görüntüde som siyah blokları bulur (4 piksel adım, 7x7 blok). Döner: [{c: Vector2 merkez, s: Vector2 boyut, n: hücre}], en büyük önce
static func blocks(img: Image) -> Array:
	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)
	var w = img.get_width()
	var h = img.get_height()
	var d: PackedByteArray = img.get_data()
	var cells = {}
	var offs = [0, 6 * 3, 6 * w * 3, (6 * w + 6) * 3, (3 * w + 3) * 3]
	for y in range(0, h - 8, 4):
		var row = y * w * 3
		for x in range(0, w - 8, 4):
			var i = row + x * 3
			if d[i] > 0 or d[i + 1] > 0 or d[i + 2] > 0:
				continue
			var ok = true
			for o in offs:
				if d[i + o] > 0 or d[i + o + 1] > 0 or d[i + o + 2] > 0:
					ok = false
					break
			if ok:
				cells[Vector2i(x / 4, y / 4)] = true
	var out = []
	var seen = {}
	for c0 in cells:
		if seen.has(c0):
			continue
		var stack = [c0]
		seen[c0] = true
		var lo = Vector2(c0)
		var hi = Vector2(c0)
		var n = 0
		while not stack.is_empty():
			var c: Vector2i = stack.pop_back()
			n += 1
			lo = lo.min(Vector2(c))
			hi = hi.max(Vector2(c))
			for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
				var q = c + dv
				if cells.has(q) and not seen.has(q):
					seen[q] = true
					stack.append(q)
		out.append({"c": (lo + hi) * 2.0 + Vector2(4, 4), "s": (hi - lo) * 4.0 + Vector2(8, 8), "n": n})
	out.sort_custom(func(a, b): return a["n"] > b["n"])
	return out


static func _mat_name(gi: GeometryInstance3D) -> String:
	var m: Material = gi.material_override
	if m == null and gi is MeshInstance3D and gi.mesh != null and gi.mesh.get_surface_count() > 0:
		m = gi.get_active_material(0)
	if m == null and gi is MultiMeshInstance3D and gi.multimesh != null and gi.multimesh.mesh != null and gi.multimesh.mesh.get_surface_count() > 0:
		m = gi.multimesh.mesh.surface_get_material(0)
	if m == null and gi is GPUParticles3D and gi.draw_pass_1 != null and gi.draw_pass_1.get_surface_count() > 0:
		m = gi.draw_pass_1.surface_get_material(0)
	if m == null:
		return "malzeme yok"
	if m is ShaderMaterial:
		return "shader " + (m.shader.resource_path.get_file() if m.shader != null and m.shader.resource_path != "" else "(gömülü)")
	return m.get_class()


static func _short(n: Node) -> String:
	var parts = String(n.get_path()).split("/")
	return "/".join(parts.slice(maxi(0, parts.size() - 5)))


static func run(main: Node) -> void:
	var tree = main.get_tree()
	var vp: Viewport = main.get_viewport()
	var cam: Camera3D = vp.get_camera_3d()
	var wenv = Game.world.get("env") if Game.world != null else null
	if cam == null or wenv == null:
		return
	var env: Environment = wenv.get("env")
	var stamp = Time.get_datetime_string_from_system().replace(":", ".").replace("T", "_")
	var dir = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP).path_join("ShinobiYolu_teshis").path_join(stamp)
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		dir = ProjectSettings.globalize_path("user://teshis").path_join(stamp)
		DirAccess.make_dir_recursive_absolute(dir)
	var was_paused = tree.paused
	tree.paused = true   # sahne dursun: bütün denemeler aynı kareye baksın
	var hud_vis = Hud.visible
	Hud.visible = false

	# her deneme: [ad, kapat, geri aç]
	var st = {"msaa": vp.msaa_3d, "ssao": env.ssao_enabled, "glow": env.glow_enabled, "post": wenv.post.visible if wenv.post else false,
		"dof": wenv.cam_attr.dof_blur_far_enabled if wenv.cam_attr else false, "shadow": wenv.sun.shadow_enabled}
	var off_msaa = func():
		vp.msaa_3d = Viewport.MSAA_DISABLED
	var off_ssao = func():
		env.ssao_enabled = false
	var off_glow = func():
		env.glow_enabled = false
	var off_dof = func():
		if wenv.cam_attr:
			wenv.cam_attr.dof_blur_far_enabled = false
	var off_post = func():
		if wenv.post:
			wenv.post.visible = false
	var off_shadow = func():
		wenv.sun.shadow_enabled = false
	var off_all = func():
		for cb in [off_msaa, off_ssao, off_glow, off_dof, off_post, off_shadow]:
			cb.call()
	var fx_on = func():
		vp.msaa_3d = st["msaa"]
		env.ssao_enabled = st["ssao"]
		env.glow_enabled = st["glow"]
		if wenv.cam_attr:
			wenv.cam_attr.dof_blur_far_enabled = st["dof"]
		if wenv.post:
			wenv.post.visible = st["post"]
		wenv.sun.shadow_enabled = st["shadow"]
	var hidden = []
	var hide_class = func(cls: String):
		for n in tree.root.find_children("*", cls, true, false):
			if n.visible and n != cam:
				n.visible = false
				hidden.append(n)
	var unhide = func():
		for n in hidden:
			if is_instance_valid(n):
				n.visible = true
		hidden.clear()
	var hide_chars = func():
		hide_class.call("CharacterBody3D")
	var hide_parts = func():
		hide_class.call("GPUParticles3D")
		hide_class.call("CPUParticles3D")
	var hide_labels = func():
		hide_class.call("Label3D")
		hide_class.call("Sprite3D")
	var hide_multi = func():
		hide_class.call("MultiMeshInstance3D")
	var hide_single = func():
		hide_class.call("MeshInstance3D")
	var nothing = func():
		pass
	var tests = [
		["0 olduğu gibi", nothing],
		["1 kenar yumuşatma kapalı", off_msaa],
		["2 ortam gölgesi kapalı", off_ssao],
		["3 parlama kapalı", off_glow],
		["4 uzak bulanıklık kapalı", off_dof],
		["5 anime çizgileri kapalı", off_post],
		["6 gölgeler kapalı", off_shadow],
		["7 bütün efektler kapalı", off_all],
		["8 karakterler gizli", hide_chars],
		["9 parçacıklar gizli", hide_parts],
		["10 yazılar ve işaretler gizli", hide_labels],
		["11 çoğaltılmış nesneler gizli (çimen, ağaç, ev parçaları)", hide_multi],
		["12 tek nesneler gizli (yapı, eşya, zemin)", hide_single],
	]
	var lines = []
	lines.append("Shinobi Yolu siyah leke teşhisi  %s" % Time.get_datetime_string_from_system())
	lines.append("Sürüm %s (%s)" % [Game.version, Game.build_tag])
	lines.append("Ekran kartı: %s | sürücü: %s | Vulkan %s" % [RenderingServer.get_video_adapter_name(), str(OS.get_video_adapter_driver_info()), RenderingServer.get_video_adapter_api_version()])
	lines.append("Pencere %s | tuval %s | ölçek %.2f" % [str(DisplayServer.window_get_size()), str(vp.get_visible_rect().size), vp.scaling_3d_scale])
	lines.append("Ayarlar: %s" % str(Game.settings))
	lines.append("Açık efektler: kenar yumuşatma %d, ortam gölgesi %s, parlama %s, uzak bulanıklık %s, çizgiler %s, gölge %s" % [st["msaa"], st["ssao"], st["glow"], st["dof"], st["post"], st["shadow"]])
	lines.append("Kamera %s | bakış %s | saat %.2f" % [str(cam.global_position.snapped(Vector3(0.1, 0.1, 0.1))), str((-cam.global_transform.basis.z).snapped(Vector3(0.01, 0.01, 0.01))), float(wenv.get("time_of_day"))])
	lines.append("")
	lines.append("DENEME -> som siyah blok sayısı (toplam hücre)")
	var base = []
	var isz = Vector2.ONE   # yakalanan görüntünün gerçek piksel boyutu (doku boyutu pencere ölçeğinde farklı dönebiliyor)
	for i in tests.size():
		tests[i][1].call()
		for _k in 5:
			await tree.process_frame
		await RenderingServer.frame_post_draw
		var img: Image = vp.get_texture().get_image()
		fx_on.call()
		unhide.call()
		var bl = blocks(img)
		var tot = 0
		for b in bl:
			tot += int(b["n"])
		lines.append("  %-58s %3d blok (%d)" % [tests[i][0], bl.size(), tot])
		if i == 0:
			base = bl
			isz = Vector2(img.get_width(), img.get_height())
			img.save_png(dir.path_join("0_oldugu_gibi.png"))
		else:
			img.save_jpg(dir.path_join("%d.jpg" % i), 0.82)
	for _k in 2:
		await tree.process_frame

	# lekelerin altındaki nesneler: ekrana izdüşümü lekeye düşen görünür nesneler (kameraya yakından uzağa)
	lines.append("")
	if base.is_empty():
		lines.append("Bu karede som siyah blok bulunmadı (leke görünürken bas).")
	else:
		var k = isz / vp.get_visible_rect().size
		var gis = tree.root.find_children("*", "GeometryInstance3D", true, false)
		for bi in mini(base.size(), 8):
			var b = base[bi]
			var c: Vector2 = b["c"]
			var rad = maxf(float(b["s"].x), float(b["s"].y)) * 0.5 + 14.0
			lines.append("LEKE %d: merkez %s piksel, boyut %s" % [bi + 1, str(c.round()), str(b["s"])])
			var ro = cam.project_ray_origin(c / k)
			var rd = cam.project_ray_normal(c / k)
			var hit = cam.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ro, ro + rd * 3000.0, 0xFFFFFFFF))
			if hit:
				lines.append("  ışın çarptı: %.0f m, %s, konum %s" % [ro.distance_to(hit["position"]), _short(hit["collider"]), str(Vector3(hit["position"]).snapped(Vector3(0.1, 0.1, 0.1)))])
			var found = []
			for gi in gis:
				if not gi.is_visible_in_tree():
					continue
				var ab: AABB = gi.global_transform * gi.get_aabb()
				if ab.size.length() > 15.0 or gi is MultiMeshInstance3D or gi.get_parent() is Camera3D:
					continue   # büyük / çoğaltılmış parçalar her lekenin altına düşer (onları 11. ve 12. deneme ayırır); kameraya bağlı çizgi katmanı
				var wc = ab.get_center()
				if cam.is_position_behind(wc):
					continue
				var sp = cam.unproject_position(wc) * k
				var pr = ab.size.length() * 0.5 / maxf(0.1, cam.global_position.distance_to(wc)) * isz.y * 0.9   # nesnenin kaba ekran yarıçapı
				if sp.distance_to(c) < rad + minf(pr, 30.0):
					found.append([cam.global_position.distance_to(wc), gi, pr])
			found.sort_custom(func(a, b2): return a[0] < b2[0])
			for fi in mini(found.size(), 18):
				var gi: GeometryInstance3D = found[fi][1]
				lines.append("  %5.0f m  %-20s %-28s boy %.1f m  ekranda %.0f px  %s" % [found[fi][0], gi.get_class(), _mat_name(gi), (gi.global_transform * gi.get_aabb()).size.length(), found[fi][2] * 2.0, _short(gi)])
			if found.size() > 18:
				lines.append("  ... %d nesne daha" % (found.size() - 18))
	var f = FileAccess.open(dir.path_join("rapor.txt"), FileAccess.WRITE)
	if f:
		f.store_string("\r\n".join(lines) + "\r\n")
		f.close()
	Hud.visible = hud_vis
	tree.paused = was_paused
	Hud.msg("Leke teşhisi bitti: %d leke. Masaüstündeki ShinobiYolu_teshis klasörünü gönder." % base.size(), Color(1, 0.8, 0.4) if base.size() > 0 else Color(0.6, 1, 0.6), 8.0)
