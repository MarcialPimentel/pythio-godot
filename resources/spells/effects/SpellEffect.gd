# resources/spells/effects/SpellEffect.gd
# One thing a spell does. Spells list their effects; each effect knows how to apply
# itself and how to describe itself (the card text is built from these descriptions).
class_name SpellEffect
extends Resource

## Applies the effect for `spell`, cast on `target` (a fighter).
func apply(_spell: SpellData, _target: Node) -> void:
	pass

## True if casting `spell` on `target` right now would make this effect fire a combo
## (used to make the spell button glow gold).
func would_combo(_spell: SpellData, _target: Node) -> bool:
	return false

## True if this effect would restore health on `target` if cast now.
func would_heal(_spell: SpellData, _target: Node) -> bool:
	return false

## One sentence for the card. Write tags as {HOT}, {SHIELD}, … to colour them.
func describe() -> String:
	return ""


static func n(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v
