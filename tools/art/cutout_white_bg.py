# Cuts AI-generated art on a plain white background into game-ready PNGs (transparent
# background, same crop for every pose so the character never jumps, 512 tall).
# Used for Pythio's high-res poses (2026-10-23). Edit `src` and `A` for new images.
# Usage: python3 tools/art/cutout_white_bg.py <output folder>
import sys, numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage
A="/mnt/user-data/attachments/509c1316-aafa-55b0-a4af-a6fea7c3d593/"
src={"idle":"0dedf9f1","cast_shield":"cc676e6a","cast_heal":"4fb1b94c","cast_hot":"7ba4ad21",
     "low_mana":"47c4c061","hurt":"e523ab84"}
out=sys.argv[1]
CANVAS=(1101,1428); FEET_Y=1393   # every pose is fitted to this canvas with the feet on this line

def load(path):
    """Scale to the canvas width and shift so the lowest ink (the feet) sits on FEET_Y."""
    im=Image.open(path).convert("RGB")
    im=im.resize((CANVAS[0],round(im.height*CANVAS[0]/im.width)),Image.LANCZOS)
    ink=np.where(np.array(im).astype(int).max(axis=2)<90)[0].max()
    out=Image.new("RGB",CANVAS,(255,255,255)); out.paste(im,(0,FEET_Y-ink))
    return np.array(out)

imgs={k:load(A+v+"-image.png") for k,v in src.items()}
# one shared crop window for every pose, so Pythio stands in the same spot in all of them
x0=y0=10**9; x1=y1=0
for a in imgs.values():
    ys,xs=np.where(a.astype(int).min(axis=2)<225)
    x0=min(x0,xs.min()); x1=max(x1,xs.max()); y0=min(y0,ys.min()); y1=max(y1,ys.max())
pad=8; x0=max(0,x0-pad); y0=max(0,y0-pad); x1=min(1100,x1+pad); y1=min(1427,y1+pad)
print("shared crop", x0,y0,x1,y1)
for k,a in imgs.items():
    ai=a.astype(int)
    whiteness=ai.min(axis=2)
    white=whiteness>=225
    lab,n=ndimage.label(white)
    sizes=ndimage.sum(white,lab,range(1,n+1))
    border=set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]])))-{0}
    keep=np.array([0]+[1 if (i in border or s>=5000) else 0 for i,s in enumerate(sizes,1)])
    bg=keep[lab].astype(bool)
    # soft edge: near-white fringe pixels fade instead of cutting hard (helps glows)
    alpha=np.where(bg,0,255).astype(float)
    fringe=(~bg)&(whiteness>200)
    alpha[fringe]=np.clip((255-whiteness[fringe])*255/55,60,255)
    al=Image.fromarray(alpha.astype("uint8")).filter(ImageFilter.GaussianBlur(0.7))
    rgba=Image.fromarray(a).convert("RGBA"); rgba.putalpha(al)
    rgba=rgba.crop((x0,y0,x1+1,y1+1))
    rgba=rgba.resize((round(rgba.width*512/rgba.height),512),Image.LANCZOS)
    rgba.save(f"{out}/pythio_{k}.png")
sheet=Image.new("RGBA",(6*rgba.width+70,532),(35,22,24,255))
for i,k in enumerate(["idle","cast_heal","cast_hot","cast_shield","low_mana","hurt"]):
    sheet.alpha_composite(Image.open(f"{out}/pythio_{k}.png"),(10+i*(rgba.width+10),10))
sheet.save(f"{out}/sheet.png"); print(rgba.size)
