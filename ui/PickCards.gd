# ui/PickCards.gd
# What the pick screens show: card data for spells, starters, Skip and "a spell instead",
# the gold "Combos with …" hints, pick titles, and every spell's icon (also used by the
# spell bar and the passive tray). Pure functions: they read the systems, change nothing.
class_name PickCards
extends RefCounted

const ART := "res://assets/art/"

## Spell icon by spell id; other spells use the icon for their main tag (stand-in art).
const SPELL_ICONS := {
	"flash_heal": "ui/icons/spell_flash_heal.png",
	"renew": "ui/icons/spell_hot.png",
	"shield": "ui/icons/spell_shield.png",
	"heal": "ui/icons/spell_instant_heal.png",
}
const TAG_ICONS := {
	"SHIELD": "ui/icons/spell_shield.png",
	"HOT": "ui/icons/spell_hot.png",
	"DIRECT": "ui/icons/spell_instant_heal.png",
	"DELAYED": "ui/icons/status_buff_2.png",
}
const FALLBACK_ICON := "ui/icons/status_buff_4.png"
## Which tag picks a spell's icon when it has several (first match wins).
const TAG_ORDER := ["SHIELD", "PROTECT", "HOT", "DELAYED", "MULTI", "DIRECT", "CLEANSE"]


## A spell's icon, first match wins (owner, 2026-10-27: new art needs no code change):
##   1. ui/icons/spell_<id>.png (a rank can share its family's: spell_heal.png for Heal II)
##   2. the four hand-wired stand-ins (SPELL_ICONS)
##   3. ui/icons/tag_<tag>.png for the spell's main tag (passives: the tag they react to)
##   4. the old shared tag icons (TAG_ICONS), then the fallback
static func spell_icon(spell: SpellData) -> Texture2D:
	for id in [spell.id, spell.family()]:
		var own := ART + "ui/icons/spell_%s.png" % id
		if ResourceLoader.exists(own):
			return load(own)
	var rel: String = SPELL_ICONS.get(spell.id, "")
	if rel == "":
		var look: Array = spell.tags + spell.reacts_to_tags
		for tag in TAG_ORDER:
			if look.has(tag):
				var tag_art := ART + "ui/icons/tag_%s.png" % tag.to_lower()
				if ResourceLoader.exists(tag_art):
					return load(tag_art)
				if TAG_ICONS.has(tag):
					rel = TAG_ICONS[tag]
					break
	if rel == "" and spell.icon:
		return spell.icon
	if rel == "":
		rel = FALLBACK_ICON
	return load(ART + rel) if ResourceLoader.exists(ART + rel) else spell.icon


## Card data for a spell on the pick screen.
static func spell_card(spell: SpellData) -> Dictionary:
	var school_color: Color = SpellTags.SCHOOL_COLORS.get(spell.school, Color.WHITE)
	var owned := SpellSystem.owned_rank(spell.family())
	var badge := ""
	var header := ""   # no school names on screen (owner, 2026-10-24)
	if owned > 0:
		badge = "RANK UP"
		var old := SpellSystem.all_owned().filter(func(s): return s.family() == spell.family())
		if not old.is_empty():
			header = "UPGRADES %s" % old[0].display_name.to_upper()
	elif DraftSystem.needs_swap(spell):
		badge = "SWAP"
	var hint := synergy_hint_bb(spell)
	if badge == "SWAP":
		hint += ("\n" if hint != "" else "") + "[color=#c9c2b6][i]Your %s are full: you'll choose one to replace.[/i][/color]" % ("passives" if spell.is_passive() else "spells")
	return {
		"header": header, "header_color": school_color, "accent": school_color,
		"badge": badge,
		"badge_color": SpellTags.COMBO_COLOR if badge == "RANK UP" else Color(0.7, 0.66, 0.6),
		"icon": spell_icon(spell),
		"title": spell.display_name,
		"cast": spell.cast_badge(),
		"stats": spell.cost_line(),
		"stats_color": SpellTags.COMBO_COLOR if spell.is_passive() else (DebuffStatus.VIOLET if spell.utility else SpellTags.MANA_COLOR),
		"tags": spell.tags,
		"body_bb": spell.description_bb(),
		"hint_bb": hint,
		"flavor": spell.flavor,
	}


## Card data for a starter spell on the first pick ("Choose your spell"). It reads like
## any spell card: name, cast time, cost, one sentence.
static func spec_card(spec: SpecData) -> Dictionary:
	var color: Color = SpellTags.SCHOOL_COLORS.get(spec.school, Color.WHITE)
	var starter := spec.starter
	if not starter:
		return {"title": spec.display_name, "accent": color}
	return {
		"accent": color,
		"icon": spell_icon(starter),
		"title": starter.display_name,
		"cast": starter.cast_badge(),
		"stats": starter.cost_line(),
		"tags": starter.tags,
		"body_bb": starter.description_bb(),
	}


## The Skip card: pass on this pick for a little extra max mana.
static func skip_card() -> Dictionary:
	var grey := Color(0.7, 0.66, 0.6)
	return {
		"header": "PASS", "header_color": grey, "accent": grey,
		"title": "Skip",
		"stats": "+%d max mana for the rest of the run" % roundi(DraftSystem.skip_bonus_max_mana),
		"body_bb": "Keep your build as it is. Nothing new to learn, a little more to spend.",
		"flavor": "Sometimes the best trick is the one you already know.",
	}


## The Baron pick's extra card when your passive slots are full.
static func bonus_spell_card() -> Dictionary:
	var grey := Color(0.7, 0.66, 0.6)
	return {
		"header": "INSTEAD", "header_color": grey, "accent": grey,
		"title": "A spell instead",
		"stats": "Keep your passives",
		"stats_color": Color(0.8, 0.76, 0.7),
		"body_bb": "Keep the passives you have and pick a new spell (or a rank-up) instead.",
		"flavor": "Cash, not credit.",
	}


## Gold "★ Combos with Renew" lines for a pick card (empty if it doesn't connect).
static func synergy_hint_bb(spell: SpellData) -> String:
	var syn := DraftSystem.synergy(spell)
	var gold := SpellTags.COMBO_COLOR.to_html(false)
	var tag_words := ", ".join(syn.tags.map(func(t): return SpellTags.label(t)))
	var lines: Array[String] = []
	if not syn.with.is_empty():
		lines.append("★ Combos with [b]%s[/b]" % ", ".join(syn.with.map(func(s): return s.display_name)))
	if not syn.from.is_empty():
		lines.append("★ Your [b]%s[/b] combos with this" % ", ".join(syn.from.map(func(s): return s.display_name)))
	if lines.is_empty():
		return ""
	return "[color=#%s]%s[/color]\n[color=#%s][i]via %s[/i][/color]" % [gold, "\n".join(lines), Color(gold, 0.7).to_html(false), tag_words]


## "Add a spell", "Add a passive" or "Add a spell or passive", depending on what's offered.
static func pick_title(offers: Array) -> String:
	var passives := offers.filter(func(s): return s.is_passive()).size()
	if passives == 0:
		return "Add a spell"
	if passives == offers.size():
		return "Add a passive"
	return "Add a spell or passive"


## "Next: a spell after round 7." / "Next: the Baron's passive after round 10."
static func next_pick_text(after: int) -> String:
	var r := after + 1
	while DraftSystem.pick_kind(r) == "" and r < after + 1000:
		r += 1
	if DraftSystem.pick_kind(r) == "passive":
		return "Next: the Baron's passive after round %d." % r
	return "Next pick after round %d." % r
