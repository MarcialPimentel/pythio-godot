# Pythio: art asset list

_Every image in the game, its file name, and when you see it. Last checked against the code
on 2026-10-24 (after the high-res Pythio and fighters, #74 and #76)._

**How to use this list**
- **Replacing art:** drop a new PNG with **exactly the same name and folder** over the old
  one. The game loads art by file name, so no code change is needed. Style rules and the
  prompt pack are in `docs/art.md`. AI art on a white background can be cut out with
  `tools/art/cutout_white_bg.py`.
- **Status column:** *High-res* = new art. *Stand-in* = cut from the original concept
  sheet (small, rough edges). *Spare* = in the folder but the game doesn't show it today
  (kept for later; safe to replace or ignore).
- **Target size:** what a high-res replacement should be. Transparent background,
  no text in the image.
- All paths are under `assets/art/` unless noted.
- **When you add, rename or start using an image, update this list in the same PR.**

---

## Pythio (the player's healer, seen from behind, bottom left)

Shown in the bottom-left corner during a run. One pose at a time; he returns to idle
after each one.

| File | When you see it | Status | Target |
|---|---|---|---|
| `characters/pythio/pythio_idle.png` | Standing still: whenever he isn't casting or reacting. | High-res | 512 tall |
| `characters/pythio/pythio_cast_heal.png` | Casting a spell that isn't a Shield or Heal-over-Time spell (Heal, Flash Heal, Divine Protection, Time Stop…), and while bandaging. | High-res | 512 tall |
| `characters/pythio/pythio_cast_hot.png` | Casting a spell with the **Heal-over-Time** tag (Renew, Healing Plague, Mend Wounds, Tranquility). | High-res | 512 tall |
| `characters/pythio/pythio_cast_shield.png` | Casting a spell with the **Shield** tag (Shield, Guardian Ward, Aegis of Light). | High-res | 512 tall |
| `characters/pythio/pythio_low_mana.png` | For 2 seconds the first time your mana drops below 20% in a round. Kneeling, staff raised. | High-res | 512 tall |
| `characters/pythio/pythio_hurt.png` | When a fighter dies (the end of the run). Head bowed, staff ring dark. | High-res | 512 tall |
| `characters/pythio/pythio_title.png` | The **title screen** (left of the logo). For now a copy of the hurt pose: head bowed, down on his luck. Marz plans new art here: Pythio as a beggar by the side of the road. Only the title screen uses this file, so replacing it changes nothing in a run. | High-res (placeholder) | 512 tall |
| `characters/pythio/pythio_victory.png` | Winning a fixed-length run. **Never shown in endless mode** (there's no win). | Stand-in (effectively spare) | 512 tall |

High-res poses must share one framing (same canvas, camera and foot position) so he
doesn't jump between poses. Use the idle as the reference image.

## Fighters (the party you heal, middle of the screen)

Each fighter's look comes from their armour type. The game shows **variant `_1`** of each
character; `_2`–`_5` are spare variants from the concept sheet.

| File | When you see it | Status | Target |
|---|---|---|---|
| `characters/knight/knight_1.png` | **Heavy Knight**, every heavy-armour fighter (and the Baron's two guards). | High-res | 512 tall |
| `characters/knight/knight_2.png` | Not shown since 2026-10-24 (the title screen shows Pythio now). Same image as `knight_1`. | Spare | — |
| `characters/knight/knight_3.png` … `knight_5.png` | Not shown. | Spare | — |
| `characters/mercenary/mercenary_1.png` | **Desperate Mercenary**, every medium-armour fighter. | High-res | 512 tall |
| `characters/mercenary/mercenary_2.png` … `_5.png` | Not shown. | Spare | — |
| `characters/rogue/rogue_1.png` | **Cursed Rogue**, half of the light-armour fighters (purple wisps). | High-res | 512 tall |
| `characters/rogue/rogue_down.png` | A Cursed Rogue who has **died** (lying face down, daggers dropped). | High-res | 512 wide |
| `characters/rogue/rogue_2.png` … `_5.png` | Not shown. | Spare | — |
| `characters/adventurer/adventurer_1.png` | **Injured Adventurer**, the other half of the light-armour fighters. | High-res | 512 tall |
| `characters/adventurer/adventurer_2.png` … `_5.png` | Not shown. | Spare | — |
| `characters/adventurer/adventurer_down.png` | An Injured Adventurer who has **died** (lying down). | High-res | 512 wide |
| `characters/baron/baron_1.png` | **The Crimson Baron**, every 5th round. | High-res | 768 tall |
| `characters/baron/baron_2.png` … `_4.png` | Not shown. | Spare | — |
| `characters/baron/baron_down.png` | The Crimson Baron when he **dies** (fallen, cape spread, sword dropped). | High-res | 512 wide |
| `characters/baron/baron_5.png` | Bloodied Baron. Not shown yet (could be his phase 3 look). | Spare | 768 tall |

**Still missing:** fallen poses for the **knight** and the **mercenary**
(`knight_down.png`, `mercenary_down.png`). The game already looks for them; until they
exist, those two stay standing when they die.

## Health, shield and mana bars

| File | When you see it | Status | Target |
|---|---|---|---|
| `ui/bars/health_bar_under.png` | The frame of every fighter's health bar (heart on the left). | Stand-in | 1024 wide |
| `ui/bars/health_bar_fill.png` | The red fill inside a fighter's health bar. | Stand-in | match the frame |
| `ui/bars/shield_bar_fill.png` | The blue strip over a fighter's health bar while they have a shield. | Stand-in | match the frame |
| `ui/bars/mana_bar_under.png` | The frame of your mana bar (bottom centre). | Stand-in | 1024 wide |
| `ui/bars/mana_bar_fill.png` | The fill of your mana bar. Gold today; moving off gold in Phase G (#63). | Stand-in | match the frame |
| `ui/bars/mana_orb_1.png` | The orb left of the mana bar when mana is **25% or less**. | Stand-in | 256 |
| `ui/bars/mana_orb_2.png` | Mana **26–50%**. | Stand-in | 256 |
| `ui/bars/mana_orb_3.png` | Mana **51–75%**. | Stand-in | 256 |
| `ui/bars/mana_orb_4.png` | Mana **above 75%** (also the starting look). | Stand-in | 256 |

## Frames and panels

| File | When you see it | Status | Target |
|---|---|---|---|
| `ui/frames/portrait.png` | Pythio's face, bottom-right corner, during a run. Bareheaded, which the new back-view art matches. | Stand-in | 512 |
| `ui/frames/dialogue_box.png` | Pythio's speech bubble for his quips, next to him. | Stand-in | 512 wide |
| `ui/frames/wanted_poster.png` | The "WANTED" poster: top-left during a round (the party you're on), and on the Next party screen. | Stand-in | 512 tall |
| `ui/frames/tooltip_frame.png` | Not shown (tooltips use the default style). | Spare | 512 wide |

## Spell icons (the spell buttons on Q–R, pick cards, the passive tray)

Only 4 spells have their own icon. Every other spell borrows the icon of its main tag
(checked in this order: Shield, Heal-over-Time, Direct, Delayed), and a spell with none of
those uses the Protection icon. That's why many spells look alike today.

| File | When you see it | Status | Target |
|---|---|---|---|
| `ui/icons/spell_instant_heal.png` | **Heal** (I–III), and any other spell or passive whose main tag is **Direct** (Flash Heal excepted). | Stand-in | 256 |
| `ui/icons/spell_flash_heal.png` | **Flash Heal**. | Stand-in | 256 |
| `ui/icons/spell_hot.png` | **Renew / Rejuvenation**, and any spell or passive whose main tag is **Heal-over-Time**. | Stand-in | 256 |
| `ui/icons/spell_shield.png` | **Shield** (I–II), and any spell or passive whose main tag is **Shield**. | Stand-in | 256 |
| `ui/icons/status_buff_2.png` | Also the button icon for **Delayed** spells (Lifebloom, Promise of Light, Hasten, Ripening). | Stand-in | 256 |
| `ui/icons/status_buff_4.png` | Also the fallback button icon for spells with none of the tags above (Divine Protection, Time Stop, Guardian Angel, Divine Channel, Mana Conduit, Second Wind, Sanctuary, Watchful Eye…). | Stand-in | 256 |

**Worth adding:** one icon per spell (`ui/icons/spell_<spell id>.png`, for example
`spell_lifebloom.png`) would make every button distinct. The spell's id is in its file name
in `resources/spells/`. Ask Claude to wire each new icon in; it's a one-line change per icon.

## Status icons (small icons above a fighter)

| File | When you see it | Status | Target |
|---|---|---|---|
| `ui/icons/status_buff_1.png` | The fighter has a **heal-over-time** on them. | Stand-in | 128 |
| `ui/icons/status_buff_2.png` | The fighter has a **Delayed** heal waiting to land, or an Echo Healing mark. | Stand-in | 128 |
| `ui/icons/status_buff_3.png` | The fighter has a **shield**. | Stand-in | 128 |
| `ui/icons/status_buff_4.png` | The fighter is **protected** (Divine Protection, Time Stop) or saved from death (Guardian Angel). | Stand-in | 128 |
| `ui/icons/status_debuff_1.png` | A **burst is incoming** on this fighter (with the red ring). | Stand-in | 128 |
| `ui/icons/status_debuff_2.png` | The fighter is **Saturated** (the next heal on them is weaker). | Stand-in | 128 |
| `ui/icons/status_debuff_3.png` … `status_debuff_5.png` | Not shown yet. Natural fits for Phase F's **Poison**, **Hex** and **Bleed**. | Spare | 128 |

## Effects on fighters (VFX)

Most effects show **one frame**. The numbered sets are animation frames, but today only
the frames listed below appear.

| File | When you see it | Status | Target |
|---|---|---|---|
| `vfx/heal/heal_burst_4.png` | A quick green flash on a fighter **when a heal lands**. | Stand-in | 256 |
| `vfx/heal/heal_burst_6.png` | The **gold combo flash** on a fighter when a combo fires (tinted gold). | Stand-in | 256 |
| `vfx/heal/hot_circle_1.png` | The green ring at a fighter's feet **while a heal-over-time is on them**. | Stand-in | 256 |
| `vfx/shield/shield_loop_1.png` | The blue bubble around a fighter **while they have a shield**. | Stand-in | 256 |
| `vfx/shield/shield_impact_2.png` | A blue flash when a **shield or protection goes on**, or a shield **absorbs a hit**. | Stand-in | 256 |
| `vfx/danger/danger_telegraph_1.png` | The pulsing red ring at a fighter's feet **before a burst lands** ("INCOMING"). | Stand-in | 256 |
| `vfx/danger/blood_burst_1.png` | A red splash when a **burst hits** a fighter's health. | Stand-in | 256 |
| `vfx/danger/blood_burst_3.png` | A bigger red splash when a fighter **dies**. | Stand-in | 256 |
| `vfx/heal/heal_burst_1.png`, `_2`, `_3`, `_5` · `vfx/heal/hot_circle_2.png` … `_5` · `vfx/heal/healing_particles.png` | Not shown (unused animation frames). | Spare | 256 per frame |
| `vfx/shield/shield_loop_2.png` … `_5` · `shield_impact_1`, `_3`, `_4` · `shield_break_1.png` … `_5` | Not shown. `shield_break` would suit a shield **breaking**. | Spare | 256 per frame |
| `vfx/danger/danger_telegraph_2.png` … `_5` · `blood_burst_2`, `_4` · `danger_spikes_1.png` … `_5` | Not shown. | Spare | 256 per frame |
| `vfx/mana/mana_orb_flow_1.png` … `_6` · `vfx/mana/mana_sparkles_1.png` … `_5` | Not shown (no mana effects yet; they're gold, so they'd need recolouring for #63). | Spare | 256 per frame |

## Props

| File | When you see it | Status | Target |
|---|---|---|---|
| `props/barrel.png`, `blood_splat.png`, `broken_bottle.png`, `crates.png`, `healing_elixir.png`, `medic_bag.png`, `torch.png`, `wall_poster.png` | Not shown. Background dressing for later (or item art if a shop arrives). | Spare | 256 |

## Other image files

| File | What it is |
|---|---|
| `assets/art/_source/pythio_concept_sheet_2x.png` | The original concept sheet every stand-in was cut from. Not loaded by the game; `.gdignore` keeps Godot from importing it. |
| `assets/icons/flashheal.png`, `renew.png`, `shield.png` (outside `assets/art/`) | Old 64px icons from the first version, still attached to a few spell files. Only used if the matching `ui/icons/` art went missing. Effectively spare. |
| `icon.svg` (repo root) | The project's icon (browser tab / app icon). |

## Fonts (`assets/fonts/`, not art, listed for completeness)

| File | Where it's used |
|---|---|
| `pirata-one-latin-400-normal.woff2` | Big titles: round number, "Choose your school", pick screens, pause menu. |
| `oswald-latin-500-normal.woff2`, `oswald-latin-700-normal.woff2` | Everything else on screen: labels, numbers, buttons, card text. |
| `special-elite-latin-400-normal.woff2` | Pythio's speech bubble, flavour lines on cards, pause-menu quip (typewriter look). |
| `symbols-dejavu-bold.ttf` | Symbols the other fonts lack (◀ ▶ ★ ·), so they don't show as boxes. |

Font choices may change in Phase H (#61).

---

## Quick priorities for new art

What changes the screen most, in order:

Done (2026-10-24): all of Pythio's poses in use, the four fighters, the Baron, and fallen
poses for the rogue, adventurer and Baron.

1. **Fallen poses for the knight and mercenary** (`knight_down.png`, `mercenary_down.png`).
2. **The health bar frame and fill**: there's one on every fighter.
3. **Distinct spell icons**: many spells share an icon today.
4. **The bloodied Baron** (`baron_5`), for a phase-3 look later.
