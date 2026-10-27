# Pythio art: stand-ins, file names, and the high-res prompt pack

## Where the art comes from today
**High-res so far (2026-10-24):** all of Pythio's poses in use (idle, three casting, low mana,
hurt), the four fighters, the Crimson Baron, and fallen poses for the rogue, adventurer and Baron, made by the owner in ChatGPT from the prompt pack below. Pythio's
poses were cut out with `tools/art/cutout_white_bg.py` (one shared crop so he stands in the
same spot in every pose); single images with `tools/art/cutout_single.py`. Everything else
is still a stand-in; `docs/art-assets.md` has the full list and what to make next.

Everything in `assets/art/` was cut from the owner's AI-generated concept sheet
(`assets/art/_source/pythio_concept_sheet_2x.png`) by `tools/art/slice_concept_sheet.py`.
These are **stand-ins**. They have the right style, but they're small (characters are about
120–300 px tall) and have rough edges where the background was removed.

**File names are the contract.** The game loads art by these paths. To upgrade a piece,
drop a better PNG with **the same name** over the old one. No code change is needed.

## Style guide (for any new art)
- **Look:** gritty inked comic noir. Heavy black linework, crosshatching, grey/sepia
  figures, splashes of colour only where they mean something.
- **Colour meaning:**
  - emerald green = healing
  - electric blue = shields
  - blood red = danger, bursts, wounds
  - gold = combos and powerful effects (a gold flash always means a combo)
  - icy cyan = mana (the bar, the orb, costs; since 2026-10-27, #63)
  - The full colour language is in `docs/game-design.md` (section 2).
- **Camera:** characters full-body, front three-quarter view. Pythio is seen **from behind**
  (the player looks over his shoulder at the party).
- **Background:** transparent PNG. If the tool can't do transparency, use a **flat solid
  colour** (pure white `#FFFFFF` or green `#00FF00`). Never a checkerboard pattern; that
  was the main problem with the concept sheet.
- **No text** baked into images.

## Asset list
Every image, its file name, when it appears in the game, whether it's high-res yet and its
target size: **`docs/art-assets.md`**. That list, including what to make next, replaces the
table that used to be here.

## Prompt pack for regenerating at high resolution
Generate **one asset per image**, and attach the concept sheet as a style/image reference
(e.g. Midjourney `--sref`, or "use this image as style reference" in ChatGPT/Leonardo).

**Base style (put this in every prompt):**
> gritty inked comic noir illustration, heavy black linework, crosshatching, desaturated grey
> and sepia tones with a single accent colour, dark fantasy, single subject centered,
> full body, isolated on a plain solid white background, no text, no checkerboard, high detail

**Per asset (append to the base):**
- **Pythio idle (back view):** "a weary healer-for-hire in a long tattered grey coat with a
  satchel, holding a wooden staff topped with a small green-glowing ring, seen from behind,
  standing"
- **Pythio casting (back view):** same, "raising the staff, emerald green sparks" (heal), or
  "a ring of electric blue light around him" (shield), or "green vines and leaves swirling at
  his feet" (heal-over-time)
- **Heavy Knight:** "battered plate-armored knight with a kite shield and longsword, red cross
  on the tabard, front three-quarter view"
- **Desperate Mercenary:** "scarred mercenary in patched leather and mail, axe and short
  sword, hunched, front three-quarter view"
- **Cursed Rogue:** "hooded rogue in dark leathers with twin daggers, faint purple cursed wisps
  rising from the body, front three-quarter view"
- **Injured Adventurer:** "young wounded adventurer in light armor with a red cross, limping,
  blood on the leg, front three-quarter view" (and "collapsed face-down on the ground" for the
  fallen pose)
- **Crimson Baron:** "imposing noble warlord in ornate dark armor, white fur collar, long
  blood-red cape, greatsword, front view" (and "bloodied, cape torn" for phase 2)
- **Spell icons (square, 1:1):** "square spell icon with a rough sketchy black-and-white frame,
  [a glowing green cross / a blue shield / a green sprouting leaf inside a ring / a bright
  green cross with rays]"
- **Bars (wide, 8:1):** "a horizontal comic-style health bar frame with a heart in a circle on
  the left, empty black interior, rough inked white outline", and the same with "gold" and no
  heart for mana
- **VFX (1:1, ideally on black background instead of white):** "[green starburst of healing
  light / ring of green leaves / electric blue circular shield bubble / shattering blue
  shield shards / pulsing red concentric danger ring / red blood burst / gold sparkle]"

**Tip:** if a tool only outputs on white, keep it that way; the slicing script removes a
plain white background much more cleanly than a checkerboard.
