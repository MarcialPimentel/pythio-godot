# resources/spells/effects/SpellEffect.gd
# One thing a spell does. Spells list their effects; each effect knows how to apply
# itself and how to describe itself (the card text is built from these descriptions).
class_name SpellEffect
extends Resource

## Applies the effect for `spell`, cast on `target` (a fighter).
func apply(_spell: SpellData, _target: Node) -> void:
	pass

## One sentence for the card. Write tags as {HOT}, {SHIELD}, … to colour them.
func describe() -> String:
	return ""


static func n(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v
