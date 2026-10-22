# Pythio art: stand-ins, file names, and the high-res prompt pack

## Where the art comes from today
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
  - mana: not gold (moving to another colour in Phase G, #63)
  - The full colour language is in `docs/game-design.md` (section 2).
- **Camera:** characters full-body, front three-quarter view. Pythio is seen **from behind**
  (the player looks over his shoulder at the party).
- **Background:** transparent PNG. If the tool can't do transparency, use a **flat solid
  colour** (pure white `#FFFFFF` or green `#00FF00`). Never a checkerboard pattern; that
  was the main problem with the concept sheet.
- **No text** baked into images.

## MVP asset list
Sizes are what the high-res versions should be (2–4× the stand-ins). ★ = used by the
combat screen right now.

| File (under `assets/art/`) | What it is | Stand-in | Target |
|---|---|---|---|
| ★ `characters/pythio/pythio_idle.png` | Pythio, back view, idle | ~110×160 | 512 tall |
| `characters/pythio/pythio_cast_heal.png` / `_cast_shield` / `_cast_hot` | Back view, casting (green / blue / green swirl) | ~120×170 | 512 tall |
| `characters/pythio/pythio_hurt.png` / `_low_mana` / `_victory` | Back view reactions | ~110×150 | 512 tall |
| ★ `characters/knight/knight_1.png` (…`_5`) | Heavy Knight (HEAVY armor) | ~130×200 | 512 tall |
| ★ `characters/mercenary/mercenary_1.png` (…`_5`) | Desperate Mercenary (MEDIUM) | ~125×170 | 512 tall |
| ★ `characters/rogue/rogue_1.png` (…`_5`) | Cursed Rogue (LIGHT), purple wisps | ~130×180 | 512 tall |
| ★ `characters/adventurer/adventurer_1.png` (…`_5`) | Injured Adventurer (LIGHT) | ~120×155 | 512 tall |
| `characters/adventurer/adventurer_down.png` | Fallen pose | ~190×85 | 512 wide |
| ★ `characters/baron/baron_1.png` (…`_5`, `_5` = bloodied) | Crimson Baron, boss | ~150×300 | 768 tall |
| ★ `ui/bars/health_bar_under.png` + `health_bar_fill.png` | Comic health bar frame (heart, empty interior) + red fill strip | 375×59 | 1024 wide |
| ★ `ui/bars/shield_bar_fill.png` | Blue fill strip for shields | 290×22 | match health fill |
| ★ `ui/bars/mana_bar_under.png` + `mana_bar_fill.png` | Gold mana bar frame + fill strip | 360×51 | 1024 wide |
| ★ `ui/bars/mana_orb_1.png` (…`_4`, empty → full) | Mana orb | ~90×95 | 256 |
| ★ `ui/icons/spell_flash_heal.png`, `spell_hot.png`, `spell_shield.png`, `spell_instant_heal.png` | Spell icons, framed | ~130×140 | 256 |
| `ui/icons/status_buff_1..4.png`, `status_debuff_1..5.png` | Small buff/debuff icons | ~60×80 | 128 |
| ★ `ui/frames/portrait.png` | Pythio portrait in sketch frame | ~250×235 | 512 |
| ★ `ui/frames/dialogue_box.png` | Speech bubble for quips | ~250×150 | 512 wide |
| `ui/frames/tooltip_frame.png` | Dark tooltip frame | ~210×140 | 512 wide |
| ★ `ui/frames/wanted_poster.png` | Contract card | ~175×220 | 512 tall |
| `vfx/heal/heal_burst_1..6.png`, `hot_circle_1..5.png`, `healing_particles.png` | Heal effects (green) | ~90–120 | 256 per frame |
| `vfx/shield/shield_impact_1..4.png`, `shield_loop_1..5.png`, `shield_break_1..5.png` | Shield effects (blue) | ~90–120 | 256 per frame |
| `vfx/danger/danger_telegraph_1..5.png`, `danger_spikes_1..5.png`, `blood_burst_1..4.png` | Burst warning and hits (red) | ~100–130 | 256 per frame |
| `vfx/mana/mana_sparkles_1..5.png`, `mana_orb_flow_1..6.png` | Mana effects (gold) | ~60–100 | 256 per frame |
| `props/*.png` | Medic bag, elixir, bottle, torch, blood splat, crates, barrel, wall poster | ~70–170 | 256 |

**Doing the ★ items first** covers everything currently on the combat screen: about 20 images.

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
