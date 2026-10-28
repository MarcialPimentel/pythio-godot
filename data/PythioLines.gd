# data/PythioLines.gd
# Everything Pythio says, by moment. Edit the lines freely (keep the quotes and commas);
# each moment picks one line at random. The moment names are used by scenes/game.gd.
class_name PythioLines
extends RefCounted

const QUIPS := {
	"round_start": ["Hold still. This stings less than dying.", "Everyone breathing? Keep it that way.",
		"I charge by the hour. Try not to bleed by the minute.", "Another job. Same blood."],
	"boss": ["The Baron. Of course it's the Baron.", "Big man, big wounds, big invoice."],
	"low_mana": ["Running on fumes.", "Pace yourselves. I'm not a fountain."],
	"death": ["Well. That's a refund I won't be getting.", "Should've ducked."],
	"victory": ["Contract fulfilled. Nobody died. Mostly.", "Pay up. I take coin, not thanks."],
	"spec": ["Every healer starts somewhere. Pick your first spell.", "Choose how you'll keep them breathing."],
	"pick": ["New trick. Try not to waste it.", "The job pays in spells. Pick one."],
	"bounty": ["The Baron pays well. Spend it wisely.", "He lived. Now I get paid properly.", "Hazard pay. Make it count."],
	"combo": ["Now that's teamwork.", "Two spells, one invoice.", "Elegant. Expensive, but elegant.",
		"Put that on the bill.", "That's how it's done."],
	"practice_start": ["One knight, one spell. Let's warm up."],
	"practice_done": ["That's the trade. Now let's get paid."],
	"cleared": ["Paid in full. Mostly.", "Everyone's still breathing. Invoice sent.",
		"Another job done. Another ache.", "Nobody died. I'll take it."],
	# First time each debuff shows up in a run (Phase F): Pythio says what to do.
	"debuff_POISON": ["Poison. Press F to Cleanse it before it stacks."],
	"debuff_BLEED": ["A bleeder. Cleanse won't help: heal him above 80%, or bandage."],
	"debuff_HEX": ["Hexed. Heals do half on him. Cleanse it (F), or shield him."],
	"debuff_DREAD": ["Dread. If he drops to that line, he's gone. Cleanse it (F)."],
	"skip": ["Saving it for later. Bold.", "Fine. More mana, fewer surprises."],
	"build_complete": ["That's a full kit. From here, every new trick costs an old one.", "Bag's full. Now let's see how far it goes."],
}