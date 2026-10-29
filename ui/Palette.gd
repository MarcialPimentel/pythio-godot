# ui/Palette.gd
# The game's colours, one value per meaning (docs/game-design.md section 2, docs/art-direction.md).
# Use these instead of typing Color(...) values, so a colour means the same thing on every screen.
class_name Palette
extends RefCounted

# Neutrals: ink and bone instead of default greys.
const INK := Color("0e0c0b")       # screen ground
const PANEL := Color("1a1614")     # every panel
const RAISED := Color("26201b")    # cards, hover
const BONE := Color("ede6d6")      # text and ink lines
const SEPIA := Color("ada290")     # labels, secondary text

# Meanings (each passes 4.5:1 contrast as text on INK, PANEL and RAISED).
const HEAL := Color("3ddc84")      # emerald: healing
const SHIELD := Color("5ab0ff")    # electric blue: shields
const COMBO := Color("f2c14e")     # gold: combos, passives, powerful effects
const DANGER := Color("f25257")    # blood red: danger, bursts, Bleed
const MANA := Color("7fe6f2")      # icy cyan: mana
const CLEANSE := Color("b88aff")   # violet: debuffs you can Cleanse, and Cleanse

## Smallest text on screen at 1080p (Steam Deck readability).
const MIN_FONT := 18
