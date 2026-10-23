"""Ekran görüntülerinden etiketli kontak sayfası: python tools/montage.py <dizin> <önek> <çıktı.png> [sütun] [kenar=0|1]"""
import os, sys
from PIL import Image, ImageDraw

d, prefix, out = sys.argv[1], sys.argv[2], sys.argv[3]
cols = int(sys.argv[4]) if len(sys.argv) > 4 else 5
side = sys.argv[5] if len(sys.argv) > 5 else "0"
files = sorted(f for f in os.listdir(d) if f.startswith(prefix) and (f.endswith(".png") if side == "*" else f.endswith("_%s.png" % side)))
W, H = 400, 225
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (cols * W, max(1, rows) * H), (20, 20, 20))
dr = ImageDraw.Draw(sheet)
for i, f in enumerate(files):
    im = Image.open(os.path.join(d, f)).convert("RGB").resize((W, H))
    x, y = (i % cols) * W, (i // cols) * H
    sheet.paste(im, (x, y))
    name = f[len(prefix):-4] if side == "*" else f[len(prefix):-6]
    dr.rectangle([x, y, x + 8 * len(name) + 8, y + 16], fill=(0, 0, 0))
    dr.text((x + 4, y + 2), name, fill=(255, 255, 0))
sheet.save(out)
print(out, len(files))
