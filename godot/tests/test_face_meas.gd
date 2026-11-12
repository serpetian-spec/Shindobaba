extends Node
var main: Node
func _ready():
	var CM = CharacterModel
	for d in ["masc_vroid", "AvatarSample_C", "HairSample_Male", "fem_vroid", "AvatarSample_A", "Sendagaya_Shibu"]:
		var fd: Dictionary = CM._donor_part(d, "Face")
		var m: ArrayMesh = fd["mesh"]
		var ic = fd["iris_c"]
		var c: Vector3 = (ic[0] + ic[1]) * 0.5
		var dd = (ic[1] - ic[0]).length()
		var names = []
		for si in m.get_surface_count():
			var mn = String(fd["mats"][si].resource_name)
			names.append("%s:%d" % [mn.right(18), (m.surface_get_arrays(si)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()])
			if not mn.contains("SKIN"):
				continue
			var a = m.surface_get_arrays(si)
			var vv: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var ii: PackedInt32Array = a[Mesh.ARRAY_INDEX]
			var wid = {}
			var w = PackedInt32Array()
			for v in vv:
				var k = Vector3i(roundi(v.x * 20000.0), roundi(v.y * 20000.0), roundi(v.z * 20000.0))
				if not wid.has(k):
					wid[k] = wid.size()
				w.append(wid[k])
			var ec = {}
			for t in range(0, ii.size(), 3):
				for e in 3:
					var p = w[ii[t + e]]; var q = w[ii[t + (e + 1) % 3]]
					var key = Vector2i(mini(p, q), maxi(p, q))
					ec[key] = int(ec.get(key, 0)) + 1
			var bset = {}
			for t in range(0, ii.size(), 3):
				for e in 3:
					var i0 = ii[t + e]; var i1 = ii[t + (e + 1) % 3]
					var key = Vector2i(mini(w[i0], w[i1]), maxi(w[i0], w[i1]))
					if ec[key] == 1:
						bset[i0] = true; bset[i1] = true
			for side in 2:
				var e0: Vector3 = ic[side]
				var n = 0; var zmin = 9.0; var zmax = -9.0; var xmin = 9.0; var xmax = -9.0; var ymin = 9.0; var ymax = -9.0
				for bi in bset:
					var v: Vector3 = vv[bi]
					if Vector2(v.x - e0.x, v.y - e0.y).length() < dd * 0.5 and v.z > c.z - 0.06:
						n += 1; zmin = minf(zmin, v.z); zmax = maxf(zmax, v.z)
						xmin = minf(xmin, v.x - e0.x); xmax = maxf(xmax, v.x - e0.x); ymin = minf(ymin, v.y - e0.y); ymax = maxf(ymax, v.y - e0.y)
				var rz = 0.0; var rn = 0
				for v in vv:
					var r = Vector2(v.x - e0.x, v.y - e0.y).length() / dd
					if r > 0.3 and r < 0.42 and v.z > c.z - 0.03:
						rz += v.z; rn += 1
				print("FH %s goz%d kenar_kose=%d z=[%.4f..%.4f] iris_z=%.4f cevre_z=%.4f x=[%.3f..%.3f] y=[%.3f..%.3f] (d=%.3f)" % [d, side, n, zmin, zmax, e0.z, rz / maxf(1, rn), xmin / dd, xmax / dd, ymin / dd, ymax / dd, dd])
		print("FH   yuzeyler ", names)
	get_tree().quit()
