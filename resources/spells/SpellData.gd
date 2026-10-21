# resources/spells/SpellData.gd
# One spell (or one rank of a spell). A spell is: cost + cast time + cooldown + tags + a
# list of effects. A passive spell has a rule instead of effects: it takes a spellbook
# slot but has no key. Descriptions are generated from the effects, so the card text
# always matches the real numbers.
class_name SpellData
extends Resource

@export var id: String = "heal"
@export var display_name: String = "Heal"
@export var icon: Texture2D
@export_enum("MENDING", "BLOOM", "WARD", "ANY") var school: String = "ANY"
## Plain-language tags (see SpellTags): DIRECT, HOT, SHIELD, DELAYED, MULTI.
@export var tags: Array[String] = []

@export_group("Casting")
@export var mana_cost: float = 10.0
@export var cast_time: float = 0.0      # seconds; 0 = instant
@export var cooldown: float = 0.0       # seconds before it can be cast again; 0 = none

@export_group("What it does")
@export var effects: Array[SpellEffect] = []
## If set, this is a passive: it takes a spellbook slot but is never cast.
@export var passive: PassiveRule

@export_group("Spell picks")
## Spells in the same family are ranks of one spell (Heal → Heal II → Heal III).
## Picking a higher rank replaces the lower one in the same slot.
@export var rank_family: String = ""
@export var rank: int = 1
## Only offered once you own a spell with at least one of these tags.
@export var requires_tags: Array[String] = []
## Tags this spell combos with (used for "Combos with your …" hints on pick cards).
@export var reacts_to_tags: Array[String] = []
## Relative chance to be offered (1 = normal).
@export var offer_weight: float = 1.0

@export_multiline var flavor: String = ""


func is_passive() -> bool:
	return passive != null


func family() -> String:
	return rank_family if rank_family != "" else id


## Description with {TAG} markers (not yet coloured).
func description_raw() -> String:
	if is_passive():
		return passive.describe()
	var parts: Array[String] = []
	for e in effects:
		if e:
			var d: String = e.describe()
			if d != "" and not parts.is_empty() and d.begins_with("Heals "):
				d = "Then heals " + d.substr(6)
			if d != "":
				parts.append(d)
	return " ".join(parts)


func description_bb() -> String:
	return SpellTags.fill_bb(description_raw())


func description_plain() -> String:
	return SpellTags.fill_plain(description_raw())


## "12 mana · Instant · 6s cooldown", or "Passive".
func stats_line() -> String:
	if is_passive():
		return "Passive · no key needed"
	var cast_txt := "Instant" if cast_time <= 0.0 else "%ss cast" % _num(cast_time)
	var s := "%d mana · %s" % [int(mana_cost), cast_txt]
	if cooldown > 0.0:
		s += " · %ss cooldown" % _num(cooldown)
	return s


func tag_labels() -> Array[String]:
	var out: Array[String] = []
	for t in tags:
		out.append(SpellTags.label(t))
	return out


## Pythio's casting pose for this spell.
func pose() -> String:
	if tags.has(SpellTags.SHIELD):
		return "cast_shield"
	if tags.has(SpellTags.HOT):
		return "cast_hot"
	return "cast_heal"


static func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v
