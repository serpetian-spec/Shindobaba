"""Jutsu efekt meshleri (Blender, komut satırı) -> godot/assets/vfx/*.glb
  tools/ext/blender-4.2.9-windows-x64/blender.exe -b --python tools/blender/vfx_meshes.py
Meshler tek renk (malzemeyi oyun gölgelendiricisi verir); gölgelendiriciler yerel konum kullanır, UV gerekmez.
Ölçek: yaklaşık birim (oyunda ölçeklenir). Kafalar -Z'ye bakar (oyunun ileri yönü).
"""
import math
import os

import bmesh
import bpy
from mathutils import Vector

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 'godot', 'assets', 'vfx')
os.makedirs(OUT, exist_ok=True)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def export(name):
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = bpy.context.selected_objects[0]
    bpy.ops.object.join() if len(bpy.context.selected_objects) > 1 else None
    ob = bpy.context.selected_objects[0]
    bpy.context.view_layer.objects.active = ob
    # modelleme Godot ekseninde yapıldı (y yukarı, -z ileri); glTF dışa aktarımı Blender z-yukarı varsayar -> geri çevir
    for v in ob.data.vertices:
        x, y, z = v.co
        v.co = Vector((x, -z, y))
    bpy.ops.object.shade_smooth()
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, name + '.glb'), export_format='GLB', use_selection=True, export_materials='NONE', export_yup=True)
    print('VFX_OK', name, len(ob.data.polygons))


def sculpt_cube(sub=3):
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    ob = bpy.context.active_object
    m = ob.modifiers.new('s', 'SUBSURF')
    m.levels = sub
    bpy.ops.object.modifier_apply(modifier='s')
    return ob


def deform(ob, fn):
    for v in ob.data.vertices:
        v.co = fn(v.co.copy())


def horn(base, tip_dir, length, r0, bend, segs=8):
    """Kıvrık boynuz / yele dikeni: halkalardan konik tüp"""
    bm = bmesh.new()
    prev = None
    d = Vector(tip_dir).normalized()
    up = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((1, 0, 0))
    side = d.cross(up).normalized()
    for i in range(segs + 1):
        t = i / segs
        c = Vector(base) + d * length * t + Vector(bend) * (t * t) * length
        r = r0 * (1.0 - t) + 0.004
        ring = []
        for k in range(8):
            a = k / 8 * math.tau
            ring.append(bm.verts.new(c + (side * math.cos(a) + d.cross(side) * math.sin(a)) * r))
        if prev:
            for k in range(8):
                bm.faces.new((prev[k], prev[(k + 1) % 8], ring[(k + 1) % 8], ring[k]))
        prev = ring
    me = bpy.data.meshes.new('h')
    bm.to_mesh(me)
    ob = bpy.data.objects.new('h', me)
    bpy.context.collection.objects.link(ob)
    return ob


# ---------------------------------------------------------------- ejderha kafası
def dragon_head():
    reset()
    # kafatası + uzun burun: alt bölünmeli küpü biçimlendir (yuvarlak hatlı, uzun, önde sivrilen)
    skull = sculpt_cube(3)
    def f(p):
        z = p.z  # -0.5 (ön) .. 0.5 (arka)
        fwd = max(0.0, -z) * 2.0          # öne doğru 0..1
        sx = 0.55 * (1.0 - 0.45 * fwd)
        sy = 0.45 * (1.0 - 0.35 * fwd) + (0.08 if p.y > 0 and z > 0.1 else 0.0)
        q = Vector((p.x * sx * 2.0, p.y * sy * 2.0, z * 2.2))
        if q.y > 0.05 and -0.3 < q.z < 0.4:      # kaş çıkıntısı
            q.y += 0.06 * (1.0 - abs(q.x) * 1.5)
        if abs(q.x) > 0.3 and q.y < 0.0:         # yanak
            q.x *= 1.08
        return q
    deform(skull, f)
    # alt çene (açık ağız): ince, öne uzun, aşağı eğik
    jaw = sculpt_cube(2)
    def fj(p):
        q = Vector((p.x * 0.75, p.y * 0.22, p.z * 1.9))
        q.y -= 0.32 + max(0.0, -q.z) * 0.35       # ağız açıklığı öne doğru artar
        q.z -= 0.25
        return q
    deform(jaw, fj)
    parts = [skull, jaw]
    # boynuzlar: geriye ve yukarı kıvrık
    for sx in (-1, 1):
        parts.append(horn((0.22 * sx, 0.3, 0.45), (0.15 * sx, 0.35, 1.0), 1.1, 0.09, (0.1 * sx, 0.5, 0.0)))
        parts.append(horn((0.38 * sx, -0.05, 0.25), (0.7 * sx, -0.1, 0.8), 0.55, 0.05, (0.0, 0.25, 0.0)))   # yanak dikeni
        for k in range(4):   # yele: başın arkasından geriye savrulan dikenler
            parts.append(horn((0.18 * sx * (1 - k * 0.2), 0.25 - k * 0.12, 0.7), (0.4 * sx, 0.2 - k * 0.15, 1.0), 0.7 + k * 0.1, 0.06, (0.0, 0.2, 0.0)))
        parts.append(horn((0.18 * sx, -0.05, -0.95), (0.4 * sx, -0.1, -0.2), 0.9, 0.025, (0.0, -0.3, 0.6)))   # bıyık
    # dişler
    for k in range(5):
        x = -0.2 + k * 0.1
        parts.append(horn((x, -0.12, -0.95 + abs(x) * 0.8), (0, -1, 0), 0.16, 0.03, (0, 0, 0), 4))
        parts.append(horn((x * 0.9, -0.42, -0.85 + abs(x) * 0.8), (0, 1, 0), 0.13, 0.025, (0, 0, 0), 4))
    export('dragon_head')


# ---------------------------------------------------------------- kesik yayı (kılıç / rüzgâr bıçağı): hilal, uçlarda incelen, kalınlığı az
def slash_arc():
    reset()
    bm = bmesh.new()
    n = 40
    prev = None
    for i in range(n + 1):
        t = i / n
        a = math.radians(-70 + 140 * t)
        w = math.sin(t * math.pi) ** 0.7          # ortada geniş, uçlarda sivri
        r_out = 1.0
        r_in = 1.0 - 0.28 * w
        th = 0.03 * w + 0.002
        pts = [Vector((math.sin(a) * r_out, th, -math.cos(a) * r_out)), Vector((math.sin(a) * r_in, 0, -math.cos(a) * r_in)),
               Vector((math.sin(a) * r_out, -th, -math.cos(a) * r_out))]
        ring = [bm.verts.new(p) for p in pts]
        if prev:
            for k in range(3):
                bm.faces.new((prev[k], prev[(k + 1) % 3], ring[(k + 1) % 3], ring[k]))
        prev = ring
    me = bpy.data.meshes.new('s')
    bm.to_mesh(me)
    ob = bpy.data.objects.new('s', me)
    bpy.context.collection.objects.link(ob)
    export('slash_arc')


# ---------------------------------------------------------------- sarmal girdap (Rasengan / hortum): 3 kollu bükümlü şerit koni
def vortex():
    reset()
    bm = bmesh.new()
    arms, n, w = 3, 60, 6
    for arm in range(arms):
        prev = None
        for i in range(n + 1):
            t = i / n
            a = arm / arms * math.tau + t * math.tau * 1.6
            r = 0.15 + 0.85 * t
            y = t * 1.0
            ring = []
            for k in range(w):
                s = (k / (w - 1) - 0.5) * 0.25 * (0.4 + t)
                ring.append(bm.verts.new(Vector((math.cos(a + s) * r, y + s * 0.3, math.sin(a + s) * r))))
            if prev:
                for k in range(w - 1):
                    bm.faces.new((prev[k], prev[k + 1], ring[k + 1], ring[k]))
            prev = ring
    me = bpy.data.meshes.new('v')
    bm.to_mesh(me)
    ob = bpy.data.objects.new('v', me)
    bpy.context.collection.objects.link(ob)
    export('vortex')


# ---------------------------------------------------------------- şok dalgası halkası: dışa doğru incelen, kıvrık kenarlı halka
def shock_ring():
    reset()
    bm = bmesh.new()
    n, prof = 64, [(0.7, 0.0), (0.85, 0.08), (0.95, 0.1), (1.0, 0.04), (1.02, 0.0)]
    rings = []
    for i in range(n):
        a = i / n * math.tau
        wob = 1.0 + 0.04 * math.sin(a * 7)
        rings.append([bm.verts.new(Vector((math.cos(a) * r * wob, h, math.sin(a) * r * wob))) for r, h in prof])
    for i in range(n):
        a, b = rings[i], rings[(i + 1) % n]
        for k in range(len(prof) - 1):
            bm.faces.new((a[k], b[k], b[k + 1], a[k + 1]))
    me = bpy.data.meshes.new('r')
    bm.to_mesh(me)
    ob = bpy.data.objects.new('r', me)
    bpy.context.collection.objects.link(ob)
    export('shock_ring')


dragon_head()
slash_arc()
vortex()
shock_ring()
