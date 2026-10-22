# Pythio: original game design document

> Copied from the wiki of the original web version (github.com/MarcialPimentel/Pythio/wiki).
> It describes the **web game** (endless rounds, 27 spells, talents every 5 rounds).
> The Godot version deliberately differs in places: `docs/game-design.md` describes the
> game as it is now and wins wherever the two disagree. Use this document for intent, spell ideas,
> synergy ideas and reference numbers.

---

1. Game Overview
Pythio is a web-based strategy and resource management game where players take on the role of a healer, tasked with keeping a group of adventurers (referred to as "targets") alive through increasingly challenging combat rounds. Players manage a limited mana pool, cast a variety of healing spells, and adapt to dynamic damage patterns to survive as many rounds as possible. A competitive leaderboard tracks the highest round achieved, encouraging replayability and skill mastery. Recent updates include a refined mana system with dynamic scaling, an expanded spell list with 27 spells, a synergy system for spell combos, and improved target generation with role-specific damage patterns.
Genre: Strategy / Resource Management / Simulation

Platform: Web-based (HTML, CSS, JavaScript), hosted at https://marz.gg/games/pythio/

Target Audience: Casual gamers, strategy enthusiasts, and players who enjoy competitive, skill-based challenges with a focus on resource management and quick decision-making.

Core Concept: Players act as a healer, using a mana pool and a variety of spells to sustain adventurers through timed rounds. The primary goal is to prevent any target’s death, with success measured by rounds completed and leaderboard ranking.

2. Gameplay Mechanics
Gameplay revolves around resource management (mana), spell timing, and strategic adaptation to keep multiple targets alive.
2.1 Round Structure
Round Duration:
Round 1: 10 seconds.

Rounds 2–3: 20 seconds.

Rounds 4+: Scales up to a maximum of 30 seconds, calculated as Math.min(30, 20 + Math.floor((round - 1) / 3)).

Completion: Rounds end when the timer reaches zero or the player skips via the debug panel. Success advances players to the next round; failure (any target at 0 HP) ends the game.

Casting Reset: Casting stops when a round ends to prevent persistence into the next round, ensuring stability during transitions.

2.2 Targets Management
Players heal adventurers, with numbers, health, and damage patterns varying by round:
Target Generation:
Round 1: 1 target (75/100 HP, heavy armor, sustained damage).

Rounds 2+: Procedurally generated:
Number of Targets: Starts at 2 in Round 2, scales up to a maximum of 10. Formula: Math.min(10 - 1, Math.floor((round - 1) / (20 / (10 - 1)))) + 1.

Starting HP: Scales with a health multiplier of 1 + Math.floor((round - 1) / 10) * 0.1. Heavy armor: 100 HP, medium armor: 75 HP, light armor: 50 HP (adjusted by multiplier).

Armor Types:
Heavy: 100 HP, sustained damage (2 HP/s base).

Medium: 75 HP, burst (10 HP every 5 seconds) or DoT (3 HP/s for 5 seconds).

Light: 50 HP, sustained (2 HP/s) or escalating DoT (1 HP/s initial, +1 HP/s every 3 seconds for 10 seconds).

Target Composition:
Always includes 1 heavy armor target.

Additional targets (if any) are medium or light armor, with a 50% chance of either type.

33% chance for an "All Light Armor Round" (all targets except the heavy are light armor).

33% chance for an "All Medium Armor Round" (all targets except the heavy are medium armor).

Otherwise, one random target may have high damage (2x damage multiplier).

Damage Patterns:
Sustained Damage: 2 HP/s base, scaled by round (1 + Math.floor((round - 1) / 10) * 0.05).

Burst Damage: 10 HP every 5 seconds with a 1-second warning (visualized as a red border pulse).

DoT (Damage over Time): 3 HP/s for 5 seconds.

Escalating DoT: 1 HP/s initial, increases by 1 HP/s every 3 seconds for 10 seconds.

Modifiers (50% chance per round):
Double Damage: Doubles damage rate for all targets.

Fast Attacks: Halves the interval between burst damage ticks.

Displayed via event message (e.g., "Double Damage Incoming!").

Target Roles:
Heavy Armor (Tanks): High HP, sustained damage.

Medium Armor (DPS): Moderate HP, burst or DoT damage.

Light Armor (Support): Low HP, sustained or escalating DoT damage.

Clones (via spells like Decoy): Temporary targets with full HP, expire after a duration.

Target Persistence: Targets are regenerated each round to prevent state carryover.

2.3 Mana System
Initial Pool: 100/100 mana.

Regeneration: 3.0 mana/s, increases by 0.2 every 5 rounds after Round 5 (e.g., 3.2 mana/s at Round 10, 3.4 mana/s at Round 15).

Scaling:
Max mana: 100 + 10 * Math.floor((round - 1) / 3) (e.g., 110 at Round 4, 120 at Round 7).

At round start: Mana resets to Math.min(maxMana, currentMana + 0.5 * maxMana), rewarding efficiency while preventing overaccumulation.

Usage: Spells consume mana, requiring strategic prioritization.

Debugging: Debug panel allows adding +50 mana for testing.

2.4 Spells
Spells are cast on targets to heal, shield, or apply buffs. Spells are unlocked via the talent system.
Lesser Heal:
Heal: 20 HP | Cost: 15 Mana | Cast Time: 1.5 seconds | Control: Left-click.

Heal (Talent Unlock):
Heal: 30 HP | Cost: 20 Mana | Cast Time: 2.5 seconds | Replaces Lesser Heal | Control: Left-click.

Flash Heal (Talent Unlock):
Heal: 40 HP | Cost: 20 Mana | Cast Time: 1 second | Control: Right-click.

Renew (Talent Unlock):
Heal: 5 HP/s for 10 seconds | Cost: 20 Mana | Cast Time: 1.5 seconds | Control: Shift + Left-click.

Greater Heal (Talent Unlock):
Heal: 50 HP | Cost: 30 Mana | Cast Time: 3 seconds | Replaces Heal | Control: Left-click.

Chain Heal (Talent Unlock):
Heal: 30 HP to primary target, 15 HP to one adjacent target | Cost: 35 Mana | Cast Time: 2 seconds | Control: Ctrl + Left-click.

Shield (Talent Unlock):
Effect: Absorbs 20 HP damage for 5 seconds | Cost: 20 Mana | Cast Time: Instant | Control: Alt + Left-click.

Rejuvenation (Talent Unlock):
Heal: 10 HP/s for 10 seconds | Cost: 25 Mana | Cast Time: Instant | Control: Shift + Left-click.

Divine Protection (Talent Unlock):
Effect: Reduces damage by 50% for 5 seconds | Cost: 25 Mana | Cast Time: Instant | Control: Alt + Right-click.

Harmonize (Talent Unlock):
Effect: Spreads 50% of healing to nearby targets | Cost: 35 Mana | Cast Time: 2 seconds | Control: Ctrl + Left-click.

Mend Wounds (Talent Unlock):
Heal: 25 HP + 5 HP/s for 5 seconds, cleanses DoTs | Cost: 20 Mana | Cast Time: 1.5 seconds | Control: Shift + Right-click.

Guardian Ward (Talent Unlock):
Effect: Absorbs 20 HP damage for 6 seconds, heals 10 HP on end | Cost: 20 Mana | Cast Time: Instant | Control: Alt + Right-click.

Purify (Talent Unlock):
Effect: Cleanses DoTs, prevents new debuffs for 3 seconds | Cost: 20 Mana | Cast Time: 1 second | Control: Ctrl + Right-click.

Lifebloom (Talent Unlock):
Heal: 50 HP after 10 seconds | Cost: 10 Mana | Cast Time: Instant | Control: Shift + Right-click.

Divine Channel (Talent Unlock):
Effect: Restores 100 mana over 5 seconds | Cost: 0 Mana | Cast Time: 5 seconds | Control: Ctrl + Right-click.

Decoy (Talent Unlock):
Effect: Spawns a clone for 5 seconds | Cost: 30 Mana | Cast Time: 1 second | Control: Alt + Right-click.

Binding Heal (Talent Unlock):
Heal: 30 HP to primary target, 15 HP to lowest health target | Cost: 25 Mana | Cast Time: 2 seconds | Control: Left-click.

Healing Plague (Talent Unlock):
Heal: 15 HP/s for 8 seconds, spreads to 2 targets | Cost: 30 Mana | Cast Time: 2.5 seconds | Control: Shift + Left-click.

Time Stop (Talent Unlock):
Effect: Prevents all damage for 2 seconds | Cost: 40 Mana | Cast Time: 3 seconds | Control: Ctrl + Left-click.

Shadow Strike (Talent Unlock):
Heal: 30% of missing HP | Cost: 25 Mana | Cast Time: 1.5 seconds | Control: Alt + Left-click.

Seraphic Blessing (Talent Unlock):
Effect: Passive, increases healing by 10% | Cost: 0 Mana | Cast Time: N/A | Control: Passive.

Vital Bond (Talent Unlock):
Heal: 15 HP to a random target | Cost: 20 Mana | Cast Time: Instant | Control: Right-click.

Echo Healing (Talent Unlock):
Effect: Echoes 50% of healing after 3 seconds | Cost: 15 Mana | Cast Time: Instant | Control: Shift + Right-click.

Guardian Angel (Talent Unlock):
Effect: Prevents death for 5 seconds | Cost: 35 Mana | Cast Time: Instant | Control: Alt + Right-click.

Overgrowth (Talent Unlock):
Effect: Extends HoT durations by 5 seconds | Cost: 20 Mana | Cast Time: Instant | Control: Ctrl + Right-click.

Mana Conduit (Talent Unlock):
Effect: Restores 20 mana for the next 5 casts | Cost: 0 Mana | Cast Time: N/A | Control: Passive.

Soulbond (Talent Unlock):
Effect: Links to a target, healing them for 50% of healing done | Cost: 25 Mana | Cast Time: Instant | Control: Right-click.

Healing Spirit (Talent Unlock):
Effect: Spawns a healer that heals 5 HP/s for 10 seconds | Cost: 40 Mana | Cast Time: 2 seconds | Control: Shift + Right-click.

Spell Bar Display:
Displays available spells with icons and tooltips (e.g., "Lesser Heal: Heals 20 HP, Mana Cost: 15, Cast Time: 1.5s, Binding: Left-click").

Spells are uncastable (grayscale filter) if there’s insufficient mana or a cast is in progress.

Primary heal spell (Lesser Heal, Heal, or Greater Heal) is always displayed first.

Synergies:
Renew + Healing Plague: Extends Renew’s duration by 3 seconds.

Lesser Heal + Binding Heal: Next heal on the target is boosted by 20% for 5 seconds.

Shield + Time Stop: Extends Shield duration by 2 seconds.

Decoy + Healing Spirit: Clones heal nearby targets for 2 HP/s.

2.5 Health System
Targets: Max HP varies by armor type (100 for heavy, 75 for medium, 50 for light), scaled by round.

Damage: Applied via sustained, burst, DoT, or escalating DoT, scaled by round and role.

Visuals:
Health: Green fill.

Shield: Grey bar overlay.

HoT (e.g., Renew): Green text with duration (e.g., "80/100 (+8.0s)").

High Damage: Red pulsing border.

Loss Condition: Game ends if any target’s HP reaches 0.

2.6 Objectives
Primary: Keep all targets’ HP > 0 until the timer ends.

Secondary (Planned): Bonus talent points or mana for keeping targets above 50% HP.

2.7 Progression
Scaling:
Targets: 1 to 10, based on round progression.

Damage: Role-specific scaling:
Heavy: Sustained (2 HP/s base, scaled by round).

Medium: Burst (10 HP every 5 seconds) or DoT (3 HP/s for 5 seconds).

Light: Sustained (2 HP/s) or escalating DoT (1 HP/s initial, +1 HP/s every 3 seconds for 10 seconds).

Overall damage multiplier: 1 + Math.floor((round - 1) / 10) * 0.05.

Duration: Caps at 30 seconds.

Modifiers (50% chance per round):
Double Damage: Doubles damage rates.

Fast Attacks: Halves burst damage intervals.

Talent System:
Unlocks a spell choice on Rounds 5, 10, 15, and 20.

Offers 3 random spells from the pool of unenabled spells (e.g., Flash Heal, Renew, Chain Heal).

Greater Heal requires Heal to be unlocked first.

Planned: Branching paths, prerequisites, passive bonuses (e.g., +0.5 mana regen).

2.8 Leaderboard
Tracks highest round reached.

Stored via JSON using a PHP API (leaderboard.php).

Displays top 10 scores (e.g., "Fish: Round 20").

Planned: Optional stats (total healing, spells cast).

3. User Interface
The UI prioritizes clarity and feedback, with integrated debugging tools.
3.1 Start/Leaderboard Screen
Title: "Pythio" (bold, dark font).

Tagline: "Heal adventurers through endless combat rounds!" (updated to reflect endless rounds).

Start Button: Beige, centered, triggers Game.start().

Leaderboard: Top 10 scores (e.g., "Fish: Round 20").

3.2 In-Game Interface
Round Info: "Round X - Time: Ys" (e.g., "Round 11 - Time: 16s").

Health Bars:
Green fill for health, grey fill for shield.

Text with HP and HoT duration (e.g., "80/100 (+8.0s)").

Armor icon (heavy, medium, light) on the left.

Red pulsing border for high-damage targets.

Mana Bar: Blue fill, grey background (e.g., "28/130").

Cast Bar: Shows spell name and time (e.g., "Casting Lesser Heal (1.2s)...").

Event Message: Modifiers in red (e.g., "Double Damage Incoming!").

Spell Bar: Displays spell icons with tooltips, applies grayscale filter to uncastable spells.

Debug Panel (F1 toggle): Top-right, with "+50 Mana" and "Skip Round" buttons.

3.3 Post-Round Screen
Status: "Round X Complete!"

Talent Selection: On Rounds 5, 10, 15, and 20, pick from 3 spells (e.g., "Flash Heal (20 Mana, +40 HP)").

Next Round: Button to proceed.

3.4 Game Over Screen
Status: "Game Over! You reached Round X."

Pop-Up: Name entry for leaderboard.

Play Again: Reset button.

3.5 Debug Panel
Toggle: F1.

Controls: +50 Mana, Skip Round.

Planned: Custom mana, modifier toggles, unlock all spells.

4. Technical Implementation
Built with web technologies for modularity and scalability.
4.1 Platform
Hosted at https://marz.gg/games/pythio/.

4.2 Code Structure
Game Class: Manages core logic, rounds, mana regen, and game loop.

SpellManager: Handles spells, casting, and resets between rounds.

TargetManager: Generates targets, applies damage and modifiers.

UIManager: Updates UI (health bars, spell bar, debug panel).

SynergyManager: Manages spell synergies (e.g., Renew + Healing Plague).

LeaderboardManager: Manages leaderboard via PHP API.

4.3 Game Loop
Logic: setInterval (100ms) for Game.update().

UI: DOM updates via UIManager.update().

Casting Reset: SpellManager resets on round transitions.

4.4 State Management
Screens: Start, In-Game, Post-Round, Game Over.

Flags: inRound, postRound, gameEnded, spellSelected, etc.

Scope: Global window.game instance, created asynchronously via createGame().

4.5 Data Handling
Leaderboard: JSON via PHP API (leaderboard.php).

Spells: Loaded from spells.json, with a fallback to hardcoded defaults.

Debugging: Console logs for state, casts, and errors.

4.6 Debugging Features
Console Logging: Tracks game state (e.g., "Casting Lesser Heal on target 0").

Debug Panel: +50 Mana, Skip Round, toggleable via F1.

5. Development Roadmap
5.1 Current State
Core mechanics implemented with optimized mana scaling, refined damage patterns, and round stability.

Spells (27 total, including Lesser Heal, Greater Heal, Chain Heal, Shield, etc.) and talent system active.

Synergy system implemented (e.g., Renew + Healing Plague extends duration).

Casting persistence fixed, debugging enhanced with F1 panel.

Target generation improved with role-specific damage patterns and modifiers.

5.2 Next Steps
Talent System: Add branching paths, prerequisites (e.g., Heal before Greater Heal), and passive bonuses (e.g., +0.5 mana regen).

Damage Patterns: Fully integrate burst, sustained, DoT, and escalating DoT with visual feedback (e.g., warning indicators for burst).

New Spells: Add Area Heal, Purify, Barrier.

Combo Mechanics: Expand spell synergies (e.g., Chain Heal + Harmonize for increased spread).

New Mechanics: Buffs/debuffs, hazards, secondary resource (e.g., Focus).

5.3 Future Features
Difficulty modes (e.g., Easy, Hard, Endless).

Specializations (e.g., focus on HoTs, shields, or burst healing).

Progression stats (total healing, spells cast).

Achievements (e.g., "Survive 10 rounds without a target below 50% HP").

Visual enhancements (e.g., animations for spell casts, damage effects).

