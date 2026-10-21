"""Godot projesini Windows exe olarak dışa aktarır.
  python build.py test   -> Test\\ShinobiYolu_TEST.exe  (her değişiklikten sonra)
  python build.py main   -> Oyun\\ShinobiYolu.exe       ("güncelle" denince, sürüm artar)
"""
import os
import sys
import json
import shutil
import subprocess

ROOT = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.join(ROOT, 'tools', 'Godot_v4.7.2-stable_win64_console.exe')
PROJ = os.path.join(ROOT, 'godot')
mode = sys.argv[1] if len(sys.argv) > 1 else 'test'
assert mode in ('test', 'main')

ver_file = os.path.join(ROOT, 'VERSION')
version = open(ver_file).read().strip() if os.path.exists(ver_file) else '0.2.0'
if mode == 'main' and '--no-bump' not in sys.argv:
    a, b, c = map(int, version.split('.'))
    version = f'{a}.{b + 1}.0'
    open(ver_file, 'w').write(version)

build_json = os.path.join(PROJ, 'data', 'build.json')
json.dump({'build': mode, 'version': version}, open(build_json, 'w'))

name = 'ShinobiYolu_TEST' if mode == 'test' else 'ShinobiYolu'
out_dir = os.path.join(ROOT, 'Test' if mode == 'test' else 'Oyun')
os.makedirs(out_dir, exist_ok=True)
for f in os.listdir(out_dir):  # eski (Python sürümü) exe'leri temizle
    if f.endswith('.exe') or f.endswith('.pck'):
        os.remove(os.path.join(out_dir, f))
exe = os.path.join(out_dir, name + '.exe')
subprocess.run([GODOT, '--headless', '--path', PROJ, '--import'], capture_output=True)
r = subprocess.run([GODOT, '--headless', '--path', PROJ, '--export-release', 'Windows', exe], capture_output=True, text=True)
json.dump({'build': 'dev', 'version': version}, open(build_json, 'w'))
errors = [l for l in (r.stdout + r.stderr).splitlines() if 'ERROR' in l and 'leaked' not in l and 'still in use' not in l]
if not os.path.exists(exe):
    print('\n'.join(errors[-30:]))
    sys.exit('EXPORT BASARISIZ')
print(f'OK -> {exe}  (v{version}, {os.path.getsize(exe) // 1048576} MB)')
