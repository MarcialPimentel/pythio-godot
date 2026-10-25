# components/statuses/DebuffStatus.gd
# Something bad living on a fighter (Phase F, owner 2026-10-25). One script, four kinds,
# each asking for a different answer:
#   POISON  damage over time; a new dose adds a stack (up to max_stacks)   → Cleanse
#   BLEED   damage over time until the fighter is healed above end_above   → heal or bandage
#   HEX     heals on the fighter are weaker (heal_taken)                   → Cleanse, or shields
#   DREAD   if health falls to the threshold, the fighter dies             → Cleanse, or keep them up
# Violet debuffs can be cleansed; Bleed (blood red) can't. DebuffSystem puts these on.
class_name DebuffStatus
extends Status

const VIOLET := Color(0.72, 0.45, 1.0)
const BLOOD := Color(0.95, 0.22, 0.16)

## POISON, BLEED, HEX or DREAD.
var debuff: String = "POISON"
var cleansable: bool = true
## Damage per second (per stack for Poison), before armour.
var dps: float = 0.0
var stacks: int = 1
var max_stacks: int = 1
## Bleed ends once health is at or above this share of max health (0 = never).
var end_above: float = 0.0
## Heals on the fighter are multiplied by this (Hex: 0.5).
var heal_taken: float = 1.0
## Dread: dying line, as health (set when it goes on).
var threshold: float = 0.0


func _init(p_debuff: String = "POISON", p_duration: float = 10.0) -> void:
	kind = "DEBUFF"
	debuff = p_debuff
	label = p_debuff.capitalize()
	cleansable = p_debuff != "BLEED"
	duration = p_duration
	time_left = p_duration


## One of each kind per fighter; a second Poison adds a stack instead (see stack_from).
func key() -> String:
	return "DEBUFF:" + debuff


func color() -> Color:
	return VIOLET if cleansable else BLOOD


## Shown above the fighter, like "! INCOMING": "☠ POISON ×2", "DREAD".
func warning_text() -> String:
	var t := debuff
	if max_stacks > 1 and stacks > 1:
		t += " ×%d" % stacks
	return "☠ " + t


## A new dose of the same debuff: Poison stacks; anything else just refreshes.
func stack_from(other: DebuffStatus) -> void:
	stacks = mini(max_stacks, stacks + other.stacks) if max_stacks > 1 else stacks
	duration = maxf(duration, other.duration)
	time_left = maxf(time_left, other.time_left)
	dps = maxf(dps, other.dps)


func tick(hc: HealthComponent, delta: float) -> void:
	time_left -= delta
	if hc.is_dead:
		return
	if end_above > 0.0 and hc.current_health >= hc.max_health * end_above:
		time_left = 0.0   # Bleed: healed back up, it stops
		return
	if dps > 0.0:
		var armor_mult: float = DifficultySystem.armor_dps_multipliers.get(target.armor_type, 1.0) if target else 1.0
		hc.take_damage(dps * stacks * armor_mult * delta)
