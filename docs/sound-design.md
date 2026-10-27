# Pythio: sound design

_Owner: Marz makes the sounds. Started 2026-10-27 (Phase G, #33). The game has no sound files
yet; every row below is waiting for one._

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
| Round start **(Start here)** | A round begins | `round_start` | 0.5–1s | A short low stinger: a bell or a drawn breath before the work | Missing |
| The Baron arrives | A Baron round begins (falls back to `round_start`) | `baron_arrive` | 1–2s | Heavier: a low brass hit, a door slam | Missing |
| Job finished **(Start here)** | A round is cleared ("Job finished") | `job_finished` | 1–1.5s | Relief: a coin drops, a long exhale, a cash-register *ding* | Missing |
| Final countdown **(Start here)** | Each of the last 5 seconds of a round | `countdown_tick` | under 0.2s | A clock tick or a dry knock; it plays 5 times in a row, so keep it soft | Missing |
| Spell pick | The spell pick screen opens | `pick_screen` | 0.5s | Paper: a card dealt, a page turned | Missing |
| The Baron's bounty | The passive pick after a Baron (falls back to `pick_screen`) | `bounty` | 1s | Richer: a heavy purse of coins set on a table | Missing |
| Game over | A fighter died; the run is over | `game_over` | 2–3s | A slow, low toll; Pythio failed another party | Missing |

### Your spells

| Sound | When it plays | File name | Length | Feel | Status |
|---|---|---|---|---|---|
| Spell lands **(Start here)** | Any spell takes effect (covers the five below until they exist) | `cast_land` | 0.3–0.5s | A soft magical *whump* | Missing |
| Heal | A Direct or Delayed spell lands (Heal, Flash Heal, Lifebloom …) | `cast_heal` | 0.3–0.6s | Warm and green: a gentle chime, a breath of light | Missing |
| Heal-over-time | A heal-over-time spell lands (Renew, Healing Plague …) | `cast_hot` | 0.5s | Organic: leaves rustling, a soft rising shimmer | Missing |
| Shield | A Shield spell lands | `cast_shield` | 0.3–0.5s | Glassy and blue: a ringing glass or metal hum | Missing |
| Mitigation | A Mitigation spell lands (Divine Protection, Time Stop, Guardian Angel) | `cast_mitigate` | 0.5s | Solid: a low gong, armour settling | Missing |
| Other spells | Anything else (Divine Channel, Echo Healing, Overgrowth …) | `cast_other` | 0.3s | Neutral magic | Missing |
| Casting starts | You start a spell with a cast time (Heal, Chain Heal …) | `cast_start` | 0.3s | A short charge-up (keep it short: it plays at the start of a 1–2s cast) | Missing |
| Can't cast | Not enough mana, a spell on cooldown, or out of Cleanse or bandage charges | `cant_cast` | under 0.2s | A dull click or a fizzle; never harsh, it can repeat | Missing |
| Low mana | Mana drops below 20% (once a round, with Pythio's line) | `low_mana` | 0.5s | A hollow, draining sound | Missing |

### Combos and passives

| Sound | When it plays | File name | Length | Feel | Status |
|---|---|---|---|---|---|
| Combo **(Start here)** | A combo fires (the gold flash) | `combo` | 0.4–0.8s | **The most important sound.** Gold and satisfying: a coin, a bright bell, a *cha-ching*. You'll hear it constantly, so make it pleasant | Missing |
| Passive fires | A passive in your tray fires (falls back to `combo`) | `passive_proc` | 0.3s | A smaller, quieter cousin of `combo` | Missing |

### Danger

| Sound | When it plays | File name | Length | Feel | Status |
|---|---|---|---|---|---|
| Burst warning **(Start here)** | The red "INCOMING" ring appears on a fighter | `burst_warning` | 0.5–1s | A rising threat: a blade drawn, a sharp intake, a low drum. It's a cue to act | Missing |
| Burst hit **(Start here)** | The warned hit lands on health | `burst_hit` | 0.3s | Heavy and wet: a blade striking, a grunt | Missing |
| Shield absorbs | The warned hit lands on a shield instead | `shield_absorb` | 0.3s | A satisfying *clang*: you saved him | Missing |
| Shield breaks | A shield is used up | `shield_break` | 0.4s | Glass shattering | Missing |
| Baron's phase | The Baron fight moves to its next phase | `baron_phase` | 1s | An ominous sting | Missing |
| A fighter dies **(Start here)** | Any fighter dies | `fighter_death` | 1–1.5s | A body falling, armour hitting stone | Missing |

### Debuffs and Cleanse

| Sound | When it plays | File name | Length | Feel | Status |
|---|---|---|---|---|---|
| Debuff lands **(Start here)** | Any debuff goes on a fighter (covers the four below until they exist) | `debuff` | 0.4s | Something wrong: a hiss, a whisper | Missing |
| Poison | Poison goes on, or stacks | `debuff_poison` | 0.4s | A bubbling, sickly hiss | Missing |
| Bleed | Bleed opens a wound | `debuff_bleed` | 0.4s | A cut, then dripping | Missing |
| Hex | Hex goes on | `debuff_hex` | 0.5s | A dark whispered word | Missing |
| Dread | Dread goes on | `debuff_dread` | 0.8s | A heartbeat, a low drone: the scariest of the four | Missing |
| Dread kills | A fighter falls to Dread's line (falls back to `fighter_death`) | `dread_kill` | 1s | A heartbeat that stops | Missing |
| Cleanse **(Start here)** | Cleanse (F) removes a debuff | `cleanse` | 0.4s | Clean and airy: a quick violet *whoosh*, a breath out | Missing |
| Bandage | You start bandaging (Space) | `bandage` | 0.5s | Cloth tearing and wrapping | Missing |

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
