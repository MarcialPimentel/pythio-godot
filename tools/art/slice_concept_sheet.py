"""Slice the Pythio concept sheet into stand-in sprites for the game.

Usage (from the repo root):
    pip install numpy opencv-python
    python tools/art/slice_concept_sheet.py assets/art/_source/pythio_concept_sheet_2x.png assets/art

The rectangles below are measured on the 2x (3548x1774) sheet. Output file names are the
contract the game code relies on; replace any PNG with a high-res version of the same name
and the game picks it up with no code change.
"""
import os, sys
import numpy as np, cv2

SHEET, OUT = sys.argv[1], sys.argv[2]
IM = cv2.imread(SHEET)
_hsv = cv2.cvtColor(IM, cv2.COLOR_BGR2HSV)
FG = ((IM.min(axis=2) < 205) | (_hsv[..., 1] > 45)).astype(np.uint8)


def segs(x0, x1, y0, y1, gap=8, minw=25, thr=2):
    col = FG[y0:y1, x0:x1].sum(axis=0) > thr
    out, start, last = [], None, None
    for i, v in enumerate(col):
        if v:
            start = i if start is None else start
            last = i
        elif start is not None and i - last > gap:
            if last - start >= minw:
                out.append((x0 + start, x0 + last + 1))
            start = None
    if start is not None and last - start >= minw:
        out.append((x0 + start, x0 + last + 1))
    res = []
    for a, b in out:
        rows = np.where(FG[y0:y1, a:b].sum(axis=1) > thr)[0]
        res.append((a, y0 + rows[0], b, y0 + rows[-1] + 1))
    return res


def bglike(c):
    mn = c.min(axis=2).astype(int); mx = c.max(axis=2).astype(int)
    return (mn > 192) & ((mx - mn) < 24)


def save(name, rgba):
    path = os.path.join(OUT, name + '.png')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    cv2.imwrite(path, rgba)


def cut(name, rect, core=None, keep_all=False, pad=6, pocket=320):
    """Remove the light checkerboard background around a sprite."""
    x0, y0, x1, y1 = [int(v) for v in rect]
    c = IM[y0:y1, x0:x1].copy(); h, w = c.shape[:2]
    _, lab = cv2.connectedComponents(bglike(c).astype(np.uint8), connectivity=4)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bg = np.isin(lab, list(border))
    vw = ((c.min(axis=2) > 226) & ((c.max(axis=2).astype(int) - c.min(axis=2)) < 16) & (~bg)).astype(np.uint8)
    n3, lab3, st3, _ = cv2.connectedComponentsWithStats(vw, 4)
    for i in range(1, n3):
        if st3[i][4] > pocket:
            bg |= (lab3 == i)
    fgm = (~bg).astype(np.uint8)
    n4, lab4, st4, _ = cv2.connectedComponentsWithStats(fgm, 8)
    for i in range(1, n4):
        if st4[i][2] > 8 * max(1, st4[i][3]) and st4[i][2] > 60:
            fgm[lab4 == i] = 0
    if not keep_all:
        d = cv2.dilate(fgm, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (9, 9)))
        n2, lab2, st, _ = cv2.connectedComponentsWithStats(d, 8)
        core = (w * .25, h * .15, w * .75, h * .85) if core is None else (core[0] - x0, core[1] - y0, core[2] - x0, core[3] - y0)
        cx0, cy0, cx1, cy1 = [int(v) for v in core]
        keep = np.zeros(n2, bool)
        for i in range(1, n2):
            if (lab2[max(0, cy0):cy1, max(0, cx0):cx1] == i).any() and st[i][4] > 40:
                keep[i] = True
        fgm = fgm * keep[lab2]
    alpha = (fgm * 255).astype(np.float32)
    dist = cv2.distanceTransform(fgm, cv2.DIST_L2, 3)
    edge = (dist > 0) & (dist <= 2.5)
    soft = np.clip((235 - c.mean(axis=2)) / 70.0, 0, 1) * 255
    alpha[edge] = np.minimum(alpha[edge], soft[edge])
    rgba = np.dstack([c, alpha.astype(np.uint8)])
    ys, xs = np.where(alpha > 10)
    a, b = max(0, xs.min() - pad), min(w, xs.max() + 1 + pad)
    t, u = max(0, ys.min() - pad), min(h, ys.max() + 1 + pad)
    save(name, rgba[t:u, a:b])


def cut_hull(name, rect, pad=3, min_area=200):
    """Framed UI pieces: keep everything inside the outline's convex hull."""
    x0, y0, x1, y1 = rect
    c = IM[y0:y1, x0:x1].copy(); h, w = c.shape[:2]
    d = cv2.dilate((~bglike(c)).astype(np.uint8), cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5)))
    n, lab, st, _ = cv2.connectedComponentsWithStats(d, 8)
    pts = [np.stack(np.where(lab == i)[::-1], 1) for i in range(1, n)
           if st[i][4] >= min_area and not (st[i][2] > 8 * max(1, st[i][3]) and st[i][3] < 8)]
    hull = cv2.convexHull(np.concatenate(pts).astype(np.int32))
    alpha = np.zeros((h, w), np.uint8); cv2.fillConvexPoly(alpha, hull, 255)
    alpha = cv2.GaussianBlur(alpha, (3, 3), 0)
    xs, ys = hull[:, 0, 0], hull[:, 0, 1]
    save(name, np.dstack([c, alpha])[max(0, ys.min() - pad):ys.max() + pad + 1, max(0, xs.min() - pad):xs.max() + pad + 1])


def row_cells(x0, x1, y0, y1, thr=10, ext=40):
    s = segs(x0, x1, y0, y1, gap=4, thr=thr)
    return [(((s[i - 1][2] + a) // 2 if i else a - ext, y0, (b + s[i + 1][0]) // 2 if i < len(s) - 1 else b + ext, y1), (a, t, b, u))
            for i, (a, t, b, u) in enumerate(s)]


# ── Pythio (back view column) ──
for k, (y0, y1) in {'idle': (185, 348), 'cast_heal': (350, 522), 'cast_shield': (522, 694), 'cast_hot': (694, 860),
                    'hurt': (862, 1006), 'low_mana': (1006, 1136), 'victory': (1136, 1300)}.items():
    cut(f'characters/pythio/pythio_{k}', (110, y0, 282, y1), core=(140, y0 + 20, 255, y1 - 15))

# ── Fighters ──
for k, (y0, y1) in {'adventurer': (203, 375), 'knight': (376, 582), 'rogue': (584, 798),
                    'mercenary': (802, 998), 'baron': (1000, 1302)}.items():
    cells = row_cells(1490, 2420, y0, y1)
    for i, (rect, core) in enumerate(cells):
        nm = 'adventurer_down' if (k == 'adventurer' and i == len(cells) - 1) else f'{k}_{i + 1}'
        r = list(rect); r[0] = max(1470, r[0]) if i == 0 else r[0]
        cut(f'characters/{k}/{nm}', r, core=core)

# ── VFX strips ──
for name, (x0, x1, y0, y1, n, thr, pk) in {
        'vfx/heal/heal_burst': (110, 660, 1375, 1500, 6, 8, 10**9), 'vfx/heal/hot_circle': (105, 665, 1655, 1772, 5, 2, 150),
        'vfx/shield/shield_impact': (780, 1300, 1385, 1500, 4, 3, 10**9), 'vfx/shield/shield_loop': (790, 1300, 1540, 1650, 5, 2, 10**9),
        'vfx/shield/shield_break': (785, 1300, 1655, 1772, 5, 2, 10**9), 'vfx/danger/danger_telegraph': (1345, 1990, 1408, 1500, 5, 6, 10**9),
        'vfx/danger/danger_spikes': (1345, 1990, 1545, 1650, 5, 4, 10**9), 'vfx/danger/blood_burst': (1345, 1990, 1674, 1772, 4, 4, 10**9),
        'vfx/mana/mana_sparkles': (2130, 2620, 1385, 1500, 5, 3, 10**9), 'vfx/mana/mana_orb_flow': (2100, 2600, 1545, 1640, 6, 3, 10**9)}.items():
    ss = segs(x0, x1, y0, y1, gap=8, thr=thr, minw=15)
    if len(ss) != n:
        lo, hi = ss[0][0], ss[-1][2]; step = (hi - lo) / n
        cells = [(int(lo + i * step) - 4, int(lo + (i + 1) * step) + 4) for i in range(n)]
    else:
        cells = [((ss[i - 1][2] + a) // 2 if i else a - 6, (c + ss[i + 1][0]) // 2 if i < len(ss) - 1 else c + 6) for i, (a, t, c, d) in enumerate(ss)]
    for i, (L, R) in enumerate(cells):
        cut(f'{name}_{i + 1}', (L, y0, R, y1), keep_all=True, pocket=pk, pad=4)
cut('vfx/heal/healing_particles', (110, 1535, 660, 1650), keep_all=True, pocket=10**9)

# ── UI ──
for k, r in {'ui/frames/portrait': (3262, 266, 3512, 502), 'ui/frames/wanted_poster': (2966, 874, 3142, 1096),
             'ui/frames/dialogue_box': (2438, 908, 2692, 1058), 'ui/frames/tooltip_frame': (2690, 908, 2902, 1048),
             'ui/icons/spell_instant_heal': (2444, 650, 2577, 792), 'ui/icons/spell_shield': (2577, 650, 2707, 792),
             'ui/icons/spell_hot': (2707, 650, 2832, 792), 'ui/icons/spell_flash_heal': (2832, 650, 2966, 792),
             '_tmp/health_bar_full': (2436, 270, 2814, 330), '_tmp/mana_bar': (2856, 384, 3218, 440)}.items():
    cut_hull(k, r)
for i, r in enumerate([(2853, 266, 2946, 366), (2946, 266, 3038, 366), (3036, 266, 3132, 366), (3132, 266, 3228, 366)]):
    cut_hull(f'ui/bars/mana_orb_{i + 1}', r)
cols = [(3018, 3080), (3080, 3142), (3142, 3206), (3206, 3268), (3266, 3330)]
for i, (a, b) in enumerate(cols[:4]):
    cut_hull(f'ui/icons/status_buff_{i + 1}', (a, 612, b, 692))
for i, (a, b) in enumerate(cols):
    cut_hull(f'ui/icons/status_debuff_{i + 1}', (a, 698, b, 780))


def bar(src, is_fill, ix0, ix1, outbase, clean):
    im = cv2.imread(os.path.join(OUT, src), cv2.IMREAD_UNCHANGED)
    b, g, r, a = [im[..., i].astype(int) for i in range(4)]
    fill = is_fill(r, g, b) & (a > 200); fill[:, :ix0] = False; fill[:, ix1:] = False
    ys, xs = np.where(fill)
    iy0, iy1 = [int(v) for v in np.percentile(ys, [4, 96])]; iy1 += 1
    fx0, fx1 = int(np.percentile(xs, 2)), int(np.percentile(xs, 98))
    strip = cv2.resize(im[iy0:iy1, fx0:fx1].copy(), (ix1 - ix0, iy1 - iy0), interpolation=cv2.INTER_CUBIC); strip[..., 3] = 255
    under = im.copy(); reg = under[iy0 - 3:iy1 + 3, ix0:ix1]
    rb, rg, rr = [reg[..., i].astype(int) for i in range(3)]
    reg[clean(rr, rg, rb), :3] = (12, 10, 12)
    under[iy0:iy1, ix0:ix1, :3] = (12, 10, 12)
    cv2.imwrite(os.path.join(OUT, outbase + '_under.png'), under)
    cv2.imwrite(os.path.join(OUT, outbase + '_fill.png'), strip)
    return strip


fill = bar('_tmp/health_bar_full.png', lambda r, g, b: (r > 140) & (g < 90) & (b < 90), 56, 346, 'ui/bars/health_bar',
           lambda r, g, b: (r > 110) & (r - g > 50))
bar('_tmp/mana_bar.png', lambda r, g, b: (r > 150) & (g > 90) & (b < 90) & (r - b > 70), 16, 352, 'ui/bars/mana_bar',
    lambda r, g, b: (r > 110) & (r - b > 50))
hsv = cv2.cvtColor(fill[..., :3], cv2.COLOR_BGR2HSV); hsv[..., 0] = 105
cv2.imwrite(os.path.join(OUT, 'ui/bars/shield_bar_fill.png'), np.dstack([cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR), fill[..., 3]]))
for f in os.listdir(os.path.join(OUT, '_tmp')):
    os.remove(os.path.join(OUT, '_tmp', f))
os.rmdir(os.path.join(OUT, '_tmp'))

# ── Props ──
for k, r in {'medic_bag': (2628, 1430, 2802, 1606), 'healing_elixir': (2802, 1430, 2872, 1606), 'broken_bottle': (2872, 1430, 2988, 1606),
             'torch': (2988, 1430, 3072, 1606), 'blood_splat': (3072, 1430, 3196, 1606), 'crates': (3196, 1430, 3302, 1606),
             'barrel': (3302, 1430, 3392, 1606), 'wall_poster': (3392, 1430, 3505, 1606)}.items():
    cut(f'props/{k}', r, keep_all=True, pocket=10**9)
print('done')
