"""Kullanım:
  python build.py test   -> Test\ShinobiYolu_TEST.exe  (her değişiklikten sonra)
  python build.py main   -> Oyun\ShinobiYolu.exe       ("güncelle" denince)
"""
import os, sys, shutil, subprocess, datetime

ROOT = os.path.dirname(os.path.abspath(__file__))
mode = sys.argv[1] if len(sys.argv) > 1 else 'test'
assert mode in ('test', 'main')
ver_file = os.path.join(ROOT, 'VERSION')
version = open(ver_file).read().strip() if os.path.exists(ver_file) else '0.1.0'
if mode == 'main' and '--no-bump' not in sys.argv:
    a, b, c = map(int, version.split('.'))
    version = f'{a}.{b + 1}.0'
    open(ver_file, 'w').write(version)

with open(os.path.join(ROOT, 'src', 'naruto', 'build_info.py'), 'w', encoding='utf8') as f:
    f.write(f"BUILD = '{mode}'\nVERSION = '{version}'\nBUILT = '{datetime.datetime.now():%Y-%m-%d %H:%M}'\n")

name = 'ShinobiYolu_TEST' if mode == 'test' else 'ShinobiYolu'
out = os.path.join(ROOT, 'Test' if mode == 'test' else 'Oyun')
work = os.path.join(ROOT, '.build', mode)
cmd = [sys.executable, '-m', 'PyInstaller', '--noconfirm', '--onefile', '--windowed', '--name', name,
       '--distpath', out, '--workpath', work, '--specpath', work,
       '--paths', os.path.join(ROOT, 'src'),
       '--collect-data', 'ursina', '--collect-submodules', 'ursina',
       '--collect-binaries', 'panda3d', '--collect-data', 'panda3d',
       '--hidden-import', 'panda3d.core', '--hidden-import', 'direct',
       os.path.join(ROOT, 'src', 'main.py')]
subprocess.check_call(cmd)
with open(os.path.join(ROOT, 'src', 'naruto', 'build_info.py'), 'w', encoding='utf8') as f:
    f.write(f"BUILD = 'dev'\nVERSION = '{version}'\n")
print(f'\nOK -> {os.path.join(out, name + ".exe")}  (v{version})')
