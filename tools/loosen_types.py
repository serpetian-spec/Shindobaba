"""GDScript: 'var x := expr' -> 'var x = expr' (Variant tip çıkarım hatalarını önler). Sıcak döngü dosyaları hariç."""
import os
import re
import sys

root = sys.argv[1]
keep = {'core/game.gd', 'world/mesh_builder.gd', 'world/terrain.gd'}
n = 0
for dp, _, files in os.walk(root):
    for fn in files:
        if not fn.endswith('.gd'):
            continue
        full = os.path.join(dp, fn)
        rel = os.path.relpath(full, root).replace(os.sep, '/')
        if rel in keep:
            continue
        s = open(full, encoding='utf8').read()
        s2, k = re.subn(r'\b(var\s+\w+)\s*:=', r'\1 =', s)
        if k:
            open(full, 'w', encoding='utf8').write(s2)
            n += k
print('degisti', n)
