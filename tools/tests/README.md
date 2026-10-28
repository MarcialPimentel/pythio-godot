# Automated checks (no screen needed)

Run from the repo root with Godot 4.3. Each script plays part of the game (picking the first
card on any pick screen), prints `TEST:` lines for people to read, and checks the results with
`check.gd` (`C.ok`, `C.eq`, `C.near` print `PASS:` / `FAIL:`; `C.done(self)` exits with 1 if
anything failed).

**Run them all** (CI does this on every PR and merge; nothing deploys if one fails):

```bash
tools/tests/run_all.sh path/to/godot          # all tests
tools/tests/run_all.sh path/to/godot picks    # only tests whose name contains "picks"
```

A test fails if it prints a `FAIL:` line, an `ERROR` / `SCRIPT ERROR`, crashes, hangs past
5 minutes, or never reaches `C.done()`. When you add a test, end it with `C.done(self)` and
turn the values you'd eyeball into `C.ok` / `C.eq` / `C.near` checks.

| Script | What it checks |
|---|---|
| `test_casting.gd` | click and hover+key casting, cast bar, mana costs, out-of-mana, round end cancels a cast |
| `test_fighters.gd` | armor roll mix, HP by armor, damage by armor, death ends the run, Play Again |
| `test_full_run.gd` | endless: round lengths, Baron every 5th round, mana top-up, rounds 1–12, death ends the run, Play Again |
| `test_bursts.gd` | bursts land after their warning for the right damage, shields absorb them, nothing lands between rounds |
| `test_debug_panel.gd` | F1 toggles the panel; jump to round, +mana, take any spell and reset the build (#69), god mode, hit/heal, skip round; debug runs can't be posted; Play Again starts clean |
| `test_effects.gd` | every effect and status (heal, neighbours, most injured, heal-over-time, shields incl. heal-on-end, protection, death save, delayed heal, Overgrowth, Echo, Spirit Surge, mana), passive hooks, tag text |
| `test_picks.gd` | school pick, pick schedule (spells after 1, 3, 7 …; the Baron's passive after 5, 10 …), offer rules (no owned/duplicate spells, one other-school card), rank-ups replace in place, cap → rank-ups only → build complete once, the real school → round → pick → contracts flow |
| `test_swap.gd` | full spell bar (#67): new spells still offered, "Replace which spell?" screen with Back, the new spell takes the old one's slot and key, rank-ups skip the swap screen, Skip gives +10 max mana that lasts the run, build complete still fires once |
| `test_combos.gd` | real casts of Renew → Overgrowth, Echo Healing → Heal, Shield → Spirit Surge; gold combo text, Pythio's quip, combo spells only offered once you own the tag they react to |
| `test_passives.gd` | Seraphic Blessing, Aura of Mending, Vital Bond (incl. no chaining), Mana Conduit; Binding Heal, Healing Plague, Guardian Angel, Time Stop, Divine Channel with real casts |
| `test_synergy.gd` | "Combos with …" hints on pick cards, at least one offer combos with your spellbook when possible, offers lean toward tags you own (#68); the old build summary above the spell bar is gone (2026-10-24) |
| `test_bandages.gd` | Space on a hovered fighter channels 40 healing over 2.5s, no casting meanwhile, Space between rounds doesn't spend one, death cancels, +1 charge every 2 rounds (max 3) |
| `test_triggers.gd` | passives as data (#65): the generic tag trigger's events (heal lands, heal-over-time tick, overheal, shield breaks, cast, mana empty), actions (heal, shield, mana, heal-over-time, extend, boost), who it hits, every-Nth and cooldown limits, glow, and the card text it writes |
| `test_batch2.gd` | spell batch 2 (#70) with real casts: Promise of Light, Hasten, Ripening, Tranquility, Aegis of Light, Lingering Light, Rising Tide, Sanctuary, Watchful Eye; their glows; offer gating; the tag census (every tag: 2+ spells have it, 2+ react to it) |
| `test_rules.gd` | battlefield rules and mirrors: Diminishing shields ↔ Bulwark, Exhaustion ↔ Second Wind, Saturation ↔ Overflow (HoT ticks never saturate), rules panel shows what's cancelled |
| `test_glow.gd` | spell buttons glow gold only when casting on the hovered fighter would fire a combo (Overgrowth on a HoT, Spirit Surge on a Shield, Echo-marked or low fighters for Direct heals) and you can cast it; pass a path to also save a screenshot |
| `test_stats.gd` | effective healing = restored (no overheal) + shield absorbs + prevented damage; overheal %, combos, bandages; game-over summary, leaderboard payload and rows, local best |
| `test_baron.gd` | Crimson Baron fight: arrives at 55% with 2 guards, phase banners at 0/40/75% of the round, assassin strikes only in phase 2, one execution in phase 3, no random bursts on him, visit 2 is 15% harder; pass a path for a phase-2 screenshot |
| `test_pause.gd` | Escape menu: ignored on the title screen; pauses mid-round (timer and damage stop); Escape resumes; Quit to title and Restart (even mid-Baron) end the run cleanly with no game over; pass a path for a screenshot |
| `test_practice.gd` | first-time practice: Take the Job asks once per device; Yes → one Heavy Knight with Heal, Renew and Shield (Q/W/E), no timer; prompts advance (Heal lands → mana and cast time → Renew cast → a warned hit, Shield soaks it → free practice with random hits back on); the knight can't die; only Start the real job leaves (spell choice, nothing carried over); No → straight to the run; Quit mid-practice cleans up; uses its own settings file; pass a path for screenshots |
| `test_job_finished.gd` | "Job finished" holds after a cleared round and ignores input; then the pick or Next party screen opens; clicks and keys right as a screen opens do nothing, and work after the guard; quitting to title during the hold leaves nothing behind; pass a path for a screenshot |
| `test_countdown.gd` | Renew + Healing Plague on one fighter: both listed under the health bar and both heal (18 over 2s); the timer flashes and pops on each of the last 5 seconds and resets when the round ends; pass a path for screenshots |
| `test_baron_passives.gd` | Phase E: the schedule (spells after 1, 3, 7, 9 …; a passive after 5, 10, 15 …); spell picks offer only spells and Baron picks only passives, leaning to your tags; the Baron's bounty screen (no Skip; with full passives, swaps and a spell-instead card); Double Down, Wildgrowth, Shatterpoint, Harvest, Chain Reaction and Bastion with real casts; pass a path for a screenshot |
| `test_debuffs.gd` | Phase F: no debuffs before round 6, then on a timer; Poison stacks (3) and hurts; Hex halves heals but not shields; Bleed opens a wound, stops above 80% or with a bandage, can't be cleansed; Dread kills at its line, a death save still works, never on a fighter near the line; Cleanse on F (charges, refill), Mend Wounds removes Poison, Purify blocks new debuffs; Purging Light and Clean Slate fire only on a real cleanse; warnings above fighters; pass a path for a screenshot |
| `test_sound.gd` | sound (#33): which sound each moment asks for (round start, casts by tag with fallback, combo, burst warning, debuff with fallback, cleanse, 5 countdown ticks, Job finished), volume and mute settings, Escape menu controls; works with or without sound files |
| `screenshots.gd` | saves real screenshots of start, contract choice, boss, game over |

```bash
godot --headless --script tools/tests/test_casting.gd
godot --headless --script tools/tests/test_fighters.gd
godot --headless --script tools/tests/test_bursts.gd
godot --headless --script tools/tests/test_effects.gd
godot --headless --script tools/tests/test_picks.gd
godot --headless --script tools/tests/test_swap.gd
godot --headless --script tools/tests/test_combos.gd
godot --headless --script tools/tests/test_passives.gd
godot --headless --script tools/tests/test_synergy.gd
godot --headless --script tools/tests/test_bandages.gd
godot --headless --script tools/tests/test_triggers.gd
godot --headless --script tools/tests/test_batch2.gd
godot --headless --script tools/tests/test_rules.gd
godot --headless --script tools/tests/test_glow.gd
godot --headless --script tools/tests/test_stats.gd
godot --headless --script tools/tests/test_baron.gd
godot --headless --script tools/tests/test_debug_panel.gd
godot --headless --script tools/tests/test_practice.gd
godot --headless --script tools/tests/test_countdown.gd
godot --headless --script tools/tests/test_baron_passives.gd
godot --headless --script tools/tests/test_debuffs.gd
godot --headless --script tools/tests/test_sound.gd
godot --headless --script tools/tests/test_job_finished.gd
timeout 180 godot --headless --script tools/tests/test_full_run.gd   # fast-forwarded; quits on its own after Play Again
# screenshots need a (virtual) display:
xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 \
  --script tools/tests/screenshots.gd -- /tmp/pythio
```

## Balance bot (not a pass/fail test)

`sim_bot.gd` plays real runs like a simple player (shields incoming bursts, heals the lowest
fighters, keeps heals-over-time rolling, picks rank-ups → healing → combos) and prints, per
round, healing done, burst damage, casts, mana left and how fighters died.

```bash
godot --headless --script tools/tests/sim_bot.gd -- 3 4          # 3 runs per school at 4× speed
godot --headless --script tools/tests/sim_bot.gd -- 3 4 heal,renew,shield   # fixed spellbook
```

