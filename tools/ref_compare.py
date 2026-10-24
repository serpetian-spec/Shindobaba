"""Referans görüntü ile model ekran görüntüsünü yan yana koyar.

Kullanım: python tools/ref_compare.py cikti.png ref1.png shot1.png [ref2.png shot2.png ...]
Her satır: solda referans, sağda model (aynı yüksekliğe ölçeklenir).
"""
import sys

from PIL import Image, ImageDraw

H = 420


def fit(p):
    im = Image.open(p).convert("RGB")
    return im.resize((int(im.width * H / im.height), H))


def main(out, pairs):
    rows = []
    for ref, shot in zip(pairs[0::2], pairs[1::2]):
        a, b = fit(ref), fit(shot)
        row = Image.new("RGB", (a.width + b.width + 8, H), (20, 20, 20))
        row.paste(a, (0, 0))
        row.paste(b, (a.width + 8, 0))
        d = ImageDraw.Draw(row)
        d.rectangle((0, 0, 70, 16), fill=(0, 0, 0))
        d.text((4, 2), "REFERANS", fill=(255, 255, 0))
        d.rectangle((a.width + 8, 0, a.width + 70, 16), fill=(0, 0, 0))
        d.text((a.width + 12, 2), "MODEL", fill=(0, 255, 255))
        rows.append(row)
    w = max(r.width for r in rows)
    sheet = Image.new("RGB", (w, H * len(rows) + 6 * (len(rows) - 1)), (20, 20, 20))
    for i, r in enumerate(rows):
        sheet.paste(r, (0, i * (H + 6)))
    sheet.save(out)
    print(out)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
