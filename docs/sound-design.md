# Pythio — Sound design

_Owner: Marz makes the sounds. Started 2026-10-27 (Phase G, #33). **First pass done
2026-11-02:** every row below has a stand-in sound (Kenney CC0 recordings plus code-made tones,
see "First pass" at the end). Replace any of them with your own, one file at a time._

**How it works:** the game plays a sound by its **file name**. Drop `combo.ogg` into
`assets/audio/sfx/` and it plays every time a combo fires. No code change is needed, and a
missing file is simply silent, so sounds can arrive one at a time. Volume and Mute are in the
Escape menu (saved on each device).

**When you add a sound, mark it "Done" in the table in the same PR.** The code that decides
when each sound plays is `autoload/systems/SoundSystem.gd`; if a row here and the code
disagree, the code is what's live.

---

## The sounds

Make the **Start here** ones first: they cover the moments a player hears most.
"Falls back to" means that if the specific file doesn't exist yet, the more general one plays
instead, so one `cast_land` covers every spell until the per-spell sounds exist.

### Round flow

| Sound | When it plays | File name | Length | Feel | Status |
|---|---|---|---|---|---|
| Round start **(Start here)** | A round begins | `round_start` | 0.5–1s | A short low stinger: a bell or a drawn breath before the work | First pass |
| The Baron arrives | A Baron round begins (falls back to `round_start`) | `baron_arrive` | 1–2s | Heavier: a low brass hit, a door slam | First pass |
| Job finished **(Start here)** | A round is cleared ("Job finished") | `job_finished` | 1–1.5s | Relief: a coin drops, a long exhale, a cash-register *ding* | First pass |
| Final countdown **(Start here)** | Each of the last 5 seconds of a round | `countdown_tick` | under 0.2s | A clock tick or a dry knock; it plays 5 times in a row, so keep it soft | First pass |
| Spell pick | The spell pick screen opens | `pick_screen` | 0.5s | Paper: a card dealt, a page turned | First pass |
| The Baron's bounty | The passive pick after a Baron (falls back to `pick_screen`) | `bounty` | 1s | Richer: a heavy purse of coins set on a table | First pass |
| Game over | A fighter died; the run is over | `game_over` | 2–3s | A slow, low toll; Pythio failed another party | First pass |

### Your spells

| Sound | When it plays | File name | Length | Feel | Status |
|---|---|---|---|---|---|
| Spell lands **(Start here)** | Any spell takes effect (covers the five below until they exist) | `cast_land` | 0.3–0.5s | A soft magical *whump* | First pass |
| Heal | A Direct or Delayed spell lands (Heal, Flash Heal, Lifebloom …) | `cast_heal` | 0.3–0.6s | Warm and green: a gentle chime, a breath of light | First pass |
| Heal-over-time | A heal-over-time spell lands (Renew, Healing Plague …) | `cast_hot` | 0.5s | Organic: leaves rustling, a soft rising shimmer | First pass |
| Shield | A Shield spell lands | `cast_shield` | 0.3–0.5s | Glassy and blue: a ringing glass or metal hum | First pass |
| Mitigation | A Mitigation spell lands (Divine Protection, Time Stop, Guardian Angel) | `cast_mitigate` | 0.5s | Solid: a low gong, armour settling | First pass |
| Other spells | Anything else (Divine Channel, Echo Healing, Overgrowth …) | `cast_other` | 0.3s | Neutral magic | First pass |
| Casting starts | You start a spell with a cast time (Heal, Chain Heal …) | `cast_start` | 0.3s | A short charge-up (keep it short: it plays at the start of a 1–2s cast) | First pass |
| Can't cast | Not enough mana, a spell on cooldown, or out of Cleanse or bandage charges | `cant_cast` | under 0.2s | A dull click or a fizzle; never harsh, it can repeat | First pass |
| Low mana | Mana drops below 20% (once a round, with Pythio's line) | `low_mana` | 0.5s | A hollow, draining sound | First pass |

### Combos and passives

| Sound | When it plays | File name | Length | Feel | Status |
|---|---|---|---|---|---|
| Combo **(Start here)** | A combo fires (the gold flash) | `combo` | 0.4–0.8s | **The most important sound.** Gold and satisfying: a coin, a bright bell, a *cha-ching*. You'll hear it constantly, so make it pleasant | First pass |
| Passive fires | A passive in your tray fires (falls back to `combo`) | `passive_proc` | 0.3s | A smaller, quieter cousin of `combo` | First pass |

### Danger

| Sound | When it plays | File name | Length | Feel | Status |
|---|---|---|---|---|---|
| Burst warning **(Start here)** | The red "INCOMING" ring appears on a fighter | `burst_warning` | 0.5–1s | A rising threat: a blade drawn, a sharp intake, a low drum. It's a cue to act | First pass |
| Burst hit **(Start here)** | The warned hit lands on health | `burst_hit` | 0.3s | Heavy and wet: a blade striking, a grunt | First pass |
| Shield absorbs | The warned hit lands on a shield instead | `shield_absorb` | 0.3s | A satisfying *clang*: you saved him | First pass |
| Shield breaks | A shield is used up | `shield_break` | 0.4s | Glass shattering | First pass |
| Baron's phase | The Baron fight moves to its next phase | `baron_phase` | 1s | An ominous sting | First pass |
| A fighter dies **(Start here)** | Any fighter dies | `fighter_death` | 1–1.5s | A body falling, armour hitting stone | First pass |

### Debuffs and Cleanse

| Sound | When it plays | File name | Length | Feel | Status |
|---|---|---|---|---|---|
| Debuff lands **(Start here)** | Any debuff goes on a fighter (covers the four below until they exist) | `debuff` | 0.4s | Something wrong: a hiss, a whisper | First pass |
| Poison | Poison goes on, or stacks | `debuff_poison` | 0.4s | A bubbling, sickly hiss | First pass |
| Bleed | Bleed opens a wound | `debuff_bleed` | 0.4s | A cut, then dripping | First pass |
| Hex | Hex goes on | `debuff_hex` | 0.5s | A dark whispered word | First pass |
| Dread | Dread goes on | `debuff_dread` | 0.8s | A heartbeat, a low drone: the scariest of the four | First pass |
| Dread kills | A fighter falls to Dread's line (falls back to `fighter_death`) | `dread_kill` | 1s | A heartbeat that stops | First pass |
| Cleanse **(Start here)** | Cleanse (F) removes a debuff | `cleanse` | 0.4s | Clean and airy: a quick violet *whoosh*, a breath out | First pass |
| Bandage | You start bandaging (Space) | `bandage` | 0.5s | Cloth tearing and wrapping | First pass |

---

## Making a sound: what the game needs

- **Format:** OGG (best for the web build) or WAV. MP3 also works. Name it exactly as in the
  table, all lower case: `combo.ogg`.
- **Mono**, 44.1 or 48 kHz.
- **No silence at the start**, or the sound feels late. A short fade at the end.
- **Short:** most game sounds are well under a second. The Length column is a guide.
- **Even loudness:** normalise every sound to the same level (peaks about −1 dB, around
  −16 LUFS if your tool shows it). Make `combo`, `fighter_death` and `game_over` a little
  louder, and `countdown_tick`, `cant_cast` and `passive_proc` a little quieter: they repeat.
- **Style:** grounded and noir, not arcade. Leather, cloth, metal, glass, coins, breath, low
  brass and strings. Magic is a soft shimmer, not a laser. The colour language carries over:
  healing is warm, shields glassy, combos golden (coins and bells), danger low and heavy,
  debuffs hissing or whispering.
- **Licence:** use sounds you made, AI sounds you're allowed to use commercially, or CC0.
  Anything that needs credit (CC-BY), note its source when you send it and Claude adds a
  credits line.

## Workflow

1. Make or find the sound, trim it and export it with the file name from the table.
2. **Send it to Claude in chat** (several at once is fine). Claude puts it in
   `assets/audio/sfx/`, checks it plays at the right moment, marks the row Done and opens a PR.
3. Or upload it yourself on GitHub into `assets/audio/sfx/` on a new branch and open a PR.

## Tools that help

- **Make sounds from a description (AI):** ElevenLabs Sound Effects and Stable Audio turn a
  line like "a single gold coin dropping on a wooden table, close up, dry" into a sound. Check
  each tool's terms for commercial use.
- **Free sound libraries:** Freesound.org (filter by the CC0 licence), Kenney.nl's audio packs
  (all CC0), and the free Sonniss GDC Game Audio bundles (royalty-free).
- **Record it yourself:** a phone voice memo of real things (a coin, tearing cloth, a glass,
  your own breath) often sounds more "noir" than anything synthetic.
- **Edit and export:** Audacity (free). Trim the start, fade the end, *Effect → Normalize*,
  *Tracks → Mix → Mix Stereo Down to Mono*, then *File → Export → Export as OGG*.
- **Quick placeholders:** jsfxr (in the browser) makes retro bleeps. They're the wrong
  style for the final game, but fine to test timing.

## Later (not yet decided)

- **Music:** a low ambient loop during rounds and a heavier track for the Baron. **[Proposed]**
  after the sound effects are in; not part of #33.
- Separate volume for sound effects and music, once there's music.

---

## First pass (2026-11-02): what each sound is made of

Every file in `assets/audio/sfx/` is built by `tools/audio/build_sfx.sh` from recordings in the
CC0 library on Marz's PC (`GameDev/_audio/kenney/`) plus tones made in code with ffmpeg.
Spells get **one sound per category** (heal, heal-over-time, shield, mitigation, other), not one
per spell. Each play is pitched up or down by up to 4% (`PITCH_VARIATION` in `SoundSystem.gd`)
so a sound heard 50 times a round doesn't sound mechanical.

| Sound | Made of |
|---|---|
| `cast_heal` | Code: warm two-note chime (C then G) + a faint glass tap (Interface `glass_002`) |
| `cast_hot` | Code: rising shimmer + cloth rustle (RPG `cloth1`) |
| `cast_shield` | Glass tap (Impact `impactGlass_light_002`) + code glass ring |
| `cast_mitigate` | Heavy plate, lowered (Impact `impactPlate_heavy_001`) + code low gong |
| `cast_other`, `cast_land` | Code: soft low thump + breath of filtered noise + faint shimmer |
| `cast_start` | Code: short soft charge-up (quiet) |
| `cant_cast` | Wood knock, lowered and muffled (Impact `impactWood_light_001`) |
| `low_mana` | Code: hollow tone sliding down an octave |
| `combo` | Coin clink (Impact `impactMetal_light_001`) + coins (RPG `handleCoins`) + code two-note bell |
| `passive_proc` | Small clink (Impact `impactMetal_light_004`) + code small bell |
| `burst_warning` | Code low drum + blade drawn (RPG `drawKnife2`) |
| `burst_hit` | Heavy punch (Impact `impactPunch_heavy_002`) + short blade (RPG `knifeSlice2`) |
| `shield_absorb` | Plate clang (Impact `impactPlate_light_000` + `impactMetal_medium_000`) |
| `shield_break` | Glass breaking (Impact `impactGlass_heavy_001` + `impactGlass_light_001`) |
| `baron_phase` | Bell, lowered (Impact `impactBell_heavy_002`) + code deep drum |
| `fighter_death` | Body fall (Impact `impactSoft_heavy_000`) + armour plate, lowered (`impactPlate_heavy_004`) |
| `debuff` | Code: short hiss |
| `debuff_poison` | Code: rising bubbles over a sickly hiss |
| `debuff_bleed` | Blade cut (RPG `knifeSlice2`) + two code drips |
| `debuff_hex` | Code: breathy whisper (filtered noise) over a low drone |
| `debuff_dread` | Code: heartbeat over a low beating drone |
| `dread_kill` | Code: heartbeat that slows, weakens and stops |
| `cleanse` | Code: airy whoosh + faint high chime |
| `bandage` | Code cloth tear + cloth rustle (RPG `cloth1`) |
| `round_start` | Bell, lowered (Impact `impactBell_heavy_002`) |
| `baron_arrive` | Door slam (RPG `doorClose_3`) + deep bell (Impact `impactBell_heavy_000`, lowered) |
| `job_finished` | Coins (RPG `handleCoins`) + code bell ding |
| `countdown_tick` | Dry wood knock (Impact `impactWood_light_003`), quiet |
| `pick_screen` | Page flick + book set down (RPG `bookFlip3`, `bookPlace3`) |
| `bounty` | Book set down + soft thud + coins (RPG `bookPlace1`, `handleCoins`; Impact `impactSoft_heavy_002`) |
| `game_over` | Bell, slowed to a long low toll (Impact `impactBell_heavy_001`) |

**Credits and licence:** recordings from Kenney's *Impact Sounds*, *Interface Sounds* and *RPG
Audio* packs (www.kenney.nl), all CC0 (public domain, free for commercial use). The code-made
tones are original. Nothing here needs a credit line, but Kenney is credited anyway.

**Swap a sound:** put your own file in `assets/audio/sfx/` with the same name (e.g.
`combo.ogg`); it replaces the stand-in. To tweak a stand-in instead (louder, shorter, a different
recording), change its recipe in `tools/audio/build_sfx.sh` and run
`bash tools/audio/build_sfx.sh combo` (needs ffmpeg and the library folder).
