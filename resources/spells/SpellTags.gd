# resources/spells/SpellTags.gd
# The plain-language tags (Balatro-style) that drive synergies, and the three schools.
# Spell text writes a tag as {HOT}; the game shows it as a coloured, bold word, and the
# same tag decides which spells combo with which.
class_name SpellTags
extends RefCounted

const DIRECT := "DIRECT"
const HOT := "HOT"
const SHIELD := "SHIELD"
const DELAYED := "DELAYED"
const MULTI := "MULTI"

const ALL: Array[String] = [DIRECT, HOT, SHIELD, DELAYED, MULTI]

const LABELS := {
	DIRECT: "Direct",
	HOT: "Heal-over-Time",
	SHIELD: "Shield",
	DELAYED: "Delayed",
	MULTI: "Multi-target",
}

const COLORS := {
	DIRECT: Color(0.49, 0.95, 0.35),   # emerald: heals
	HOT: Color(0.37, 0.88, 0.63),
	SHIELD: Color(0.45, 0.7, 1.0),     # electric blue: shields
	DELAYED: Color(0.78, 0.66, 1.0),
	MULTI: Color(0.92, 0.86, 0.75),
}

# ── Schools (the three specializations) ──
const MENDING := "MENDING"
const BLOOM := "BLOOM"
const WARD := "WARD"
const ANY := "ANY"

const SCHOOL_LABELS := {MENDING: "Mending", BLOOM: "Bloom", WARD: "Ward", ANY: "Any school"}
const SCHOOL_COLORS := {
	MENDING: Color(0.49, 0.95, 0.35),
	BLOOM: Color(0.37, 0.88, 0.63),
	WARD: Color(0.45, 0.7, 1.0),
	ANY: Color(0.85, 0.8, 0.72),
}

## Gold = combos and powerful effects (the game's colour language).
const COMBO_COLOR := Color(1.0, 0.82, 0.3)


static func label(tag: String) -> String:
	return LABELS.get(tag, tag.capitalize())


static func bb(tag: String) -> String:
	var c: Color = COLORS.get(tag, Color.WHITE)
	return "[color=#%s][b]%s[/b][/color]" % [c.to_html(false), label(tag)]


## Replaces {TAG} markers with coloured BBCode tag words.
static func fill_bb(text: String) -> String:
	for tag in ALL:
		text = text.replace("{%s}" % tag, bb(tag))
	return text


## Replaces {TAG} markers with plain tag words (for tooltips).
static func fill_plain(text: String) -> String:
	for tag in ALL:
		text = text.replace("{%s}" % tag, label(tag))
	return text
