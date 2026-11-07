class_name Thumbs
extends RefCounted
## Eşya küçük resimleri: silahlar gerçek 3B modelden bir kez çizilir (küçük SubViewport, UPDATE_ONCE),
## kıyafet/göz gibi eşyalar yuva simgesi + eşya rengiyle gösterilir.

const SLOT_ICONS := {"kafa": "headband", "sag_goz": "eye", "sol_goz": "eye", "yuz": "mask", "set": "shirt", "govde": "shirt", "bacak": "pants", "ayak": "sandal",
	"zirh": "vest", "dis": "cloak", "kol": "glove", "sirt": "back", "sag": "sword", "sol": "kunai", "sac": "hair", "susanoo": "susanoo",
	"goz": "eye", "el": "kunai"}
const ITEM_ICONS := {"kunai": "kunai", "shuriken": "shuriken", "tag": "seal", "smoke": "bomb", "salve": "potion", "pill": "pill"}

static var _holder: Node
static var _cache := {}


static func ensure(parent: Node) -> void:
	if _holder != null:
		return
	_holder = Node.new()
	_holder.name = "Thumbs"
	parent.add_child(_holder)


## Silah 3B küçük resmi (ViewportTexture), değilse null
static func weapon(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	if _holder == null or not Gear.item(id).has("weapon"):
		return null
	var vp = SubViewport.new()
	vp.size = Vector2i(160, 160)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.82, 0.9)
	env.environment.ambient_light_energy = 0.7
	vp.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 1.4
	vp.add_child(sun)
	var mi = MeshInstance3D.new()
	var sk = Gear.skin_id(id)
	mi.mesh = CharacterModel.weapon_mesh(sk if sk != "" else Gear.visual_id(id))   # benzersiz eşya: taban modeli; özel silah: kendi modeli
	vp.add_child(mi)
	var ab: AABB = mi.mesh.get_aabb() if mi.mesh else AABB(Vector3(-0.1, -0.1, -0.1), Vector3(0.2, 0.2, 0.2))
	# en uzun ekseni çapraz yerleştir
	mi.basis = Basis(Vector3(0, 0, 1), deg_to_rad(-45)) * Basis(Vector3(1, 0, 0), deg_to_rad(-90)) * Basis(Vector3(0, 0, 1), deg_to_rad(20))
	mi.position = -(mi.basis * ab.get_center())
	var ext = ab.size.length()
	var cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = ext * 0.82
	cam.position = Vector3(0, 0, 3)
	vp.add_child(cam)
	_holder.add_child(vp)
	var t = vp.get_texture()
	_cache[id] = t
	return t


## Eşya karosu içeriği: silahsa 3B görsel, değilse renkli simge
static func gear_view(id: String, size := 64, col = null) -> Control:
	var it = Gear.item(id)
	var t = weapon(id)
	if t != null:
		var tr = TextureRect.new()
		tr.texture = t
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(size, size)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return tr
	var kind = SLOT_ICONS.get(it.get("slot", ""), "info")
	var c: Color = col if col != null else it.get("c1", Color(0.85, 0.85, 0.9))
	# çok koyu renkler koyu zeminde kaybolmasın
	if c.get_luminance() < 0.25:
		c = c.lightened(0.35)
	return Icons.view(kind, size, c)


static func item_view(id: String, size := 64) -> Control:
	var it: Dictionary = Data.items.get(id, {})
	var kind = ITEM_ICONS.get(id, "scroll" if it.get("kind", "") == "scroll" else "chest")
	return Icons.view(kind, size, UI.CREAM)
