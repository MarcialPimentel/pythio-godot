# Pythio — Art direction for Steam (proposal)

_Planned (proposal), as of Build 119 (2026-10-30): steps 1 and 2 are built and live (#106); the rest waits on
decisions 1, 2 and 6 below. The current style guide is `docs/art.md`._

_Draft for Marz, 2026-10-29. **[Proposed]** throughout except the steps marked done: nothing else here is decided until Marz answers
the decisions at the end. The playable mock-up is `docs/art/steam-polish-mockup.html` (open it in
a browser from this folder; it uses the real character art) and the published page:
https://claude.ai/artifact/8HzobvKiemQCnjPbzj6bVY_

**The goal:** move the game from "prototype with great characters" to a Steam-quality look,
without changing the noir style, the colour language or any rules.

## What the live build looked like before Steam polish (Build 116)
- The characters are strong. Everything around them isn't yet.
- **No place:** a dark red gradient, fighters floating with no ground or shadow, every round
  looks the same.
- **Two UI styles:** inked frames (bars, poster, portrait) next to flat Godot boxes (cards,
  panels, leaderboard, empty spell slots).
- **Small text:** spell names (14 px), passive names (12 px), the battlefield rules (15–17 px)
  and the armour line (17 px) at 1080p; on a Steam Deck that becomes 8–11 px. (The first draft
  of this doc said 10–12 px at 1080p; that was measured on a smaller browser window.)
- **Overlapping titles:** the spell-pick and Next party screens show an old title behind the
  new one ("A new job / Choose your spell", "Round 1 / Get ready / Next party").
- **Letterboxing:** the window is fixed 1920 × 1080 (`viewport` stretch), so a Steam Deck
  (16:10) and ultrawide monitors get black bars.
- **Static:** fighters don't breathe, flinch or fall (except the three fallen poses).

## 1. The short version
1. **Place:** the Contract Road. Each act between Barons has its own backdrop.
2. **UI kit:** every panel, bar, slot, card and button in one hand-inked style.
3. **Type:** keep the three fonts; nothing under 18 px at 1080p; five sizes in total.
4. **Life:** fighters breathe, flinch, stand on the ground and fall; heals burst, combos punch,
   bursts shake the screen. Shaders and particles, no new drawings.
5. **Steam store kit:** key art, logo, capsules, screenshots, trailer, icons.

## 2. Setting
**A. Recommended: the Contract Road, in acts.** Pythio follows the work down one road. The
backdrop changes when a new kind of threat arrives, so escalation is visible.

| Rounds | Place | On screen | Why then |
|---|---|---|---|
| 1–4 | Act I · The Mudroad | Rutted road, dead trees, gallows signpost, far town with a few lit windows, light fog | Calm, readable opening |
| 5, 10, 15 … | The Crimson Keep | Stone arches, torn crimson banners, braziers, embers | The Baron; red already means danger |
| 6–9 | Act II · The Drowned Marsh | Reeds, drowned trunks, black water, rain, low fog | Debuffs start at round 6 |
| 11–14 | Act III · The Plague Chapel | Broken chapel yard, gravestones, falling ash | Hex and Dread |
| 16+ | The road loops | Heavier weather, less light each lap | Endless mode keeps feeling worse with no new art |

**B. Low-change: one road at night** plus a hall for the Baron. Two backdrops; no visual
escalation. Easy to upgrade to A later.

**Tone rule:** the place is mood, never information. Backdrops stay grey, dim and low-contrast
behind a vignette, never use the meaning colours (only the Keep uses a muted red). If a backdrop
competes with a health bar, the backdrop loses. Nothing is renamed; spell, fighter and file
names stay as they are (Phase H is Marz's).

## 3. Palette
The colour language is unchanged. Each meaning gets one exact value, and ink/bone/sepia replace
the default Godot greys. Every text colour passes WCAG AA (4.5:1) on Ink, Panel and Raised.

| Token | Hex | Role | Contrast on Ink |
|---|---|---|---|
| Ink | `#0E0C0B` | Screen ground | — |
| Panel | `#1A1614` | Every panel | — |
| Raised | `#26201B` | Cards, hover | — |
| Bone | `#EDE6D6` | Text, ink lines | 15.7 |
| Sepia | `#ADA290` | Labels | 7.8 |
| Emerald | `#3DDC84` | Healing | 10.9 |
| Electric blue | `#5AB0FF` | Shields | 8.5 |
| Gold | `#F2C14E` | Combos, passives | 11.6 |
| Blood red | `#F25257` | Danger, Bleed | 5.7 (lowest pair: on Raised, 4.69) |
| Icy cyan | `#7FE6F2` | Mana | 13.5 |
| Violet | `#B88AFF` | Cleansable, Cleanse | 7.5 |

World-only colours (never UI text): mud browns `#221B16`–`#4A3B2E`, marsh olive-greys
`#232822`–`#6B725A`, keep crimson `#3A1416`, ember orange `#D0663A` (braziers only). Gold never
appears on a backdrop, so a gold flash is always a combo.

## 4. Type, icons and the UI kit
Keep Pirata One (titles), Oswald (interface), Special Elite (Pythio). Valve's Steam Deck
checklist wants text at least 9 px tall at 1280 × 800; an 18 px floor at 1080p gives 12 px.

| Use | Face | Size at 1080p |
|---|---|---|
| Round number, screen titles | Pirata One | 84 |
| Contract name, card titles, combo pop | Pirata One | 44–64 |
| Fighter names, numbers on bars | Oswald 500/700 | 22–25 |
| Rules, chips, timers, costs | Oswald 500 | 19–21 |
| Smallest labels | Oswald 500, spaced caps | 18 minimum |
| Pythio's lines, flavour | Special Elite | 23 |

**Icon rules:** square dark tile, rough double inked frame in bone, faint crosshatch, one
symbol glowing in its meaning colour with a black outline, readable at 64 px, no text. Five
vector starters in `docs/art/icons/` (Heal, Renew, Shield, Spirit Surge, Cleanse) to use as
ChatGPT references.

**UI kit (9-slice images, drawn in bone on transparent so the game can tint them):**

| Piece | Used for | File | Size |
|---|---|---|---|
| Panel | Pick cards, Next party, Job finished, pause, leaderboard, tooltips | `ui/kit/panel.png` | 256 × 256 |
| Button ×3 | Every button (normal, hover, pressed) | `ui/kit/button_*.png` | 384 × 96 |
| Bar frame | Health, mana, cast bar | `ui/kit/bar_frame.png` | 512 × 64 |
| Slot frame | Spell slots, passive tray (gold) | `ui/kit/slot.png`, `slot_gold.png` | 256 × 256 |
| Paper | Speech bubble, wanted poster, title leaderboard | `ui/kit/paper.png` | 512 × 512 |
| Chip | HoT timers, debuff warnings, rule tags | `ui/kit/chip.png` | 128 × 48 |

## 5. Feedback map
Rule: everything that happens to a fighter shows on that fighter, in its meaning colour, within
a tenth of a second, with a sound from `docs/sound-design.md`. All of these are already
announced on EventBus, so this is visual work only.

| Moment | What you see | Signal |
|---|---|---|
| Heal lands | Green burst, rising sparks, bar fills with a white trail, green number | `healed` |
| Heal-over-time | Pulsing green ring at the feet, small tick numbers, timer chip | `hot_ticked` |
| Shield on / absorbs / breaks | Blue bubble, blue strip on the bar, flash on absorb, shards on break | `shield_absorbed`, `shield_ended` |
| Combo | Gold flash, gold "COMBO", 2% screen punch, gold sparkles | `combo_fired` |
| Passive fires | Tray slot flares gold | `passive_triggered` |
| Burst warned | Red ring pulsing faster as it nears, "! INCOMING" | `burst_warned` |
| Burst lands | Hit flash, red splash, shake scaled by damage | `burst_landed` |
| Debuff | Violet or red chip; Dread line on the bar | `debuff_applied`, `dread_struck` |
| Cleanse | Violet upward wipe, chip shatters | `cleansed` |
| Low mana | Orb rim red and pulsing; Pythio kneels (exists) | GameManager mana |
| Fighter dies | Greys out, fallen pose, slow zoom and desaturate | `target_died` |
| Baron phase | Braziers flare, "Phase 2" card, screen darkens a step | `boss_phase` |
| Round start / cleared | Act title fades in; a paper "PAID" stamp | `round_started`, `round_cleared` |

A **reduce effects** option in the pause menu turns off shake and flashes.

## 6. Technology
Stay in Godot 4.3 2D; the web build keeps working.
- **New:** theme rebuilt on the UI kit (`pythio_theme.tres`); a feel layer (canvas shaders for
  breathing, hit flash and ink-dissolve death; CPUParticles2D; screen shake) driven by EventBus;
  one backdrop scene per place using Parallax2D with fog and rain particles.
- **Unchanged:** every game system.
- **Display:** stretch `canvas_items` + aspect `expand` (no black bars on Deck or ultrawide;
  the HUD pins to the edges).
- **Sharpness:** characters at 1024 px tall (today 512), backdrop layers at 3840 × 2160; the
  web build can ship half-size copies.
- **Budgets:** 60 fps on a Steam Deck with 8 fighters and a Baron; under 300 particles; under
  512 MB of textures; under 500 MB download.

| Bringing fighters to life | Verdict |
|---|---|
| Shaders and tweens on the existing images | Recommended: works with every image already made |
| Cut-out rigs (Skeleton2D) | Later, maybe Pythio only; needs characters redrawn in parts |
| Frame-by-frame AI animation | No: frames don't match, it flickers |
| 3D | No: throws away the inked look |

## 7. Making the art
Same workflow as the characters (Marz makes images in ChatGPT, Claude cuts them out, places
them and opens a PR). ChatGPT tops out around 1536 px, so upscale with a free local upscaler
such as Upscayl. Recommend hiring an illustrator for the key art and capsule.

**One backdrop:** attach `characters/knight/knight_1.png` and the concept sheet as style
references; generate the far layer (prompt below), the mid layer (props on plain white) and the
ground strip; upscale 2.5×; send as `backdrops/mudroad/far.png`, `mid.png`, `ground.png`.

> **Backdrop, far layer:** Gritty inked comic noir illustration in the style of the attached
> images: heavy black linework, crosshatching, desaturated grey and sepia tones only, no saturated
> colour. A wide empty landscape at dusk: a muddy rutted road leading away between low bare
> hills, a distant small town on a ridge with two or three faint lit windows, a leaning gallows
> signpost, dead trees, thin fog in the low ground, an overcast sky with a dim moon. The lower
> third of the image is empty ground where characters will stand. No people, no text, no
> border. Wide landscape framing, 3:2.

> **UI kit, panel frame:** Game UI element in gritty inked comic noir style, matching the
> attached image: a rectangular empty panel frame drawn with a rough double inked line in
> off-white bone colour, small ink splatters at the corners, slightly uneven hand-drawn edges,
> completely empty flat black interior. Only the frame, no decoration in the middle, no text.
> Isolated on a plain solid black background, 1:1.

> **Key art:** Gritty inked comic noir illustration in the style of the attached images: heavy
> black linework, crosshatching, grey and sepia figures. A weary healer in a long tattered grey
> coat seen from behind in the foreground, raising a staff with a glowing emerald ring, facing
> four battered fighters (a plate knight with a red cross, a scarred mercenary, a hooded rogue,
> a wounded young adventurer) who stand on a muddy road at night. Behind them, far away, the
> silhouette of a towering warlord in a blood-red cape. Colour only from the healer's green light
> and the warlord's red cape. Leave clear empty space at the top for a logo. No text. Wide 16:9.

**Steam and AI images:** allowed, but Steam's content survey asks you to disclose them and the
answer shows on the store page. Check the tool's terms give commercial rights.

## 8. Steam store kit
Sizes as of late 2026; re-check Steamworks before export. Capsules may show only game art and
the logo (no review quotes, awards or "Wishlist now").

| Image | Size | Content |
|---|---|---|
| Header capsule | 920 × 430 | Key art crop with logo |
| Small capsule | 462 × 174 | Logo and the green ring; must read as a thumbnail |
| Main capsule | 1232 × 706 | Full key art with logo |
| Vertical capsule | 748 × 896 | Pythio from behind, party above |
| Page background | 1438 × 810 | Dim Mudroad |
| Library capsule | 600 × 900 | Taller vertical crop |
| Library hero + logo | 3840 × 1240; logo on transparent | Wide Mudroad; logo alone |
| Screenshots | 1920 × 1080, 5+ | Combo, Baron phase, pick screen, marsh with debuffs, near-death save |
| Trailer | 1080p, 30–60 s | Gameplay in the first 5 seconds |
| Icons | 32 × 32 .ico, 184 × 184 | Green ring on black |

## 9. Conflicts with the design docs
Steps 1 and 2 (#106) already updated `game-design.md` §2 and §11 (18 px floor, exact palette, portrait removed, any screen shape) and `project.godot` (`canvas_items` + `expand`). The rows about places, the UI kit, backdrops and the store kit wait on approval.

| Where | Says today | Would say |
|---|---|---|
| `game-design.md` §2 | Inked noir, colour for meaning; no place | Adds the Contract Road, the backdrop tone rule, exact hex values |
| `game-design.md` §11 | Portrait bottom-right; small labels; rules top-right | Portrait removed; 18 px floor; counters beside the spell bar; act name under the round |
| `game-design.md` §12 Phase G | Sound, high-res art, mana colour | Adds UI kit, feel layer, backdrops, store kit |
| `art.md` prompt pack | Mana bar prompt says "gold" | Icy cyan (stale since #63); adds backdrop and UI kit prompts |
| `art-assets.md` | Characters 512 tall; no backdrops | Characters 1024; Backdrops, UI kit and Steam store sections |
| `project.godot` | ✅ done (#106): `canvas_items` + `expand` | — |

## 10. Plan
1. ✅ **Fix and resize (no new art, done in #106):** 18 px floor and type scale, ink/bone colours, the overlapping
   titles, any screen shape, portrait removed.
2. ✅ **Feel layer (no new art, done in #106):** ground shadows, breathing, hit flash, shake, heal bursts, combo
   punch, death fade, reduce-effects option.
3. **UI kit:** Marz makes six pieces; Claude swaps the theme.
4. **Act I backdrop and the Keep.**
5. **Icons:** 7 tag icons, then one per spell.
6. **Marsh, Chapel, characters at 1024 px.**
7. **Store kit:** key art, capsules, screenshots, trailer, icons.

## Done so far
- **2026-10-29, steps 1 and 2 built** (Marz: "start 1 and 2"; Claude's recommendations taken for
  decisions 3, 4 and 5: portrait removed, fonts kept with an 18 px floor, window fills any screen
  shape). Merged 2026-10-29 in [#106](https://github.com/MarcialPimentel/pythio-godot/pull/106), live in Build 119.

## Decisions for Marz
1. Setting: the Contract Road in acts (A, recommended) or one road at night (B)?
2. Act names: Mudroad, Drowned Marsh, Plague Chapel, Crimson Keep. Keep, or name them in Phase H?
3. ✅ Can the bottom-right portrait go? (Taken: removed, #106.)
4. ✅ Fonts: keep the three with an 18 px floor (recommended), or reopen fonts now? (Taken: kept, #106.)
5. ✅ Switch the window to fill any screen shape (fixes Deck and ultrawide black bars)? (Taken, #106.)
6. Capsule and key art: ChatGPT, or an illustrator (recommended)?
7. ✅ Start steps 1 and 2 now? They need no art. (Marz: yes; built in #106.)
