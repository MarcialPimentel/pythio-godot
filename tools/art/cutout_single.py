# Cuts one AI-generated image on a plain white background into a game-ready PNG:
# transparent background (enclosed white gaps, e.g. between legs, removed too), cropped
# to the figure, scaled to a target height. For single images (fighters, the Baron).
# For a character with several poses that must line up, use cutout_white_bg.py instead.
# Usage: python3 tools/art/cutout_single.py <input.png> <output.png> [height, default 512]
import sys
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

src, dst = sys.argv[1], sys.argv[2]
height = int(sys.argv[3]) if len(sys.argv) > 3 else 512
a = np.array(Image.open(src).convert("RGB"))
whiteness = a.astype(int).min(axis=2)
white = whiteness >= 225
lab, n = ndimage.label(white)
sizes = ndimage.sum(white, lab, range(1, n + 1))
border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
keep = np.array([0] + [1 if (i in border or s >= 5000) else 0 for i, s in enumerate(sizes, 1)])
bg = keep[lab].astype(bool)
alpha = np.where(bg, 0, 255).astype(float)
fringe = (~bg) & (whiteness > 200)        # soft edge instead of a hard cut
alpha[fringe] = np.clip((255 - whiteness[fringe]) * 255 / 55, 60, 255)
img = Image.fromarray(a).convert("RGBA")
img.putalpha(Image.fromarray(alpha.astype("uint8")).filter(ImageFilter.GaussianBlur(0.7)))
x0, y0, x1, y1 = img.getbbox()
pad = 6
img = img.crop((max(0, x0 - pad), max(0, y0 - pad), min(a.shape[1], x1 + pad), min(a.shape[0], y1 + pad)))
img = img.resize((round(img.width * height / img.height), height), Image.LANCZOS)
img.save(dst)
print(dst, img.size)
