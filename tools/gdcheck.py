"""Tüm GDScript dosyalarını derleyip hata var mı bakar (oyunu başlatmaz, pencere açmaz).
  python tools/gdcheck.py        -> oyun betikleri; hata yoksa 0, varsa hataları yazar ve 1 döner
  python tools/gdcheck.py tests  -> test betikleri de (eskimiş testler hata verebilir)
Her .gd değişikliğinden sonra, test / ölçüm koşusundan ÖNCE çalıştır."""
import os, re, subprocess, sys, time
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
exe = os.path.join(ROOT, "tools", "Godot_v4.7.2-stable_win64_console.exe")
t0 = time.time()
try:
    r = subprocess.run([exe, "--log-file", os.path.join(ROOT, "_tmp", "test_godot.log"), "--headless", "--path", os.path.join(ROOT, "godot"), "--", "--test=res://tests/test_gdcheck.gd"] + (["--gdc-tests"] if "tests" in sys.argv else []),
                       capture_output=True, timeout=180)
    out = (r.stdout + r.stderr).decode("utf-8", "replace")
except subprocess.TimeoutExpired as e:
    out = ((e.stdout or b"") + (e.stderr or b"")).decode("utf-8", "replace") + "\nGDCHECK HATA zaman aşımı"
lines = out.splitlines()
bad = []
for i, l in enumerate(lines):
    if re.search(r"Parse Error|Compile Error|Failed to load script|GDCHECK HATA", l):
        nxt = lines[i + 1].strip() if i + 1 < len(lines) else ""
        bad.append(l.strip() + ("  " + nxt if nxt.startswith("at:") else ""))
done = any(l.startswith("GDCHECK betik=") for l in lines)
seen = []
for b in bad:
    if b not in seen:
        seen.append(b)
for b in seen[:40]:
    print(b)
if not done:
    print("GDCHECK tamamlanmadı (test betiği çalışmadı)")
print("gdcheck: %s, %d hata, %.0f sn" % ("TEMİZ" if not seen and done else "HATA VAR", len(seen), time.time() - t0))
sys.exit(0 if (not seen and done) else 1)
